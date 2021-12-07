#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function 
#define FFADE_OUT           0x0002        // Fade out (not in) 
#define FFADE_MODULATE      0x0004        // Modulate (don't blend) 
#define FFADE_STAYOUT       0x0008        // ignores the duration, stays faded out until new ScreenFade message received 
#define FFADE_PURGE         0x0010        // Purges all other fades, replacing them with this one 

new Handle:cvar; 

public OnPluginStart() 
{ 
    cvar = CreateConVar("sm_flashbang_flash_color", "", "Usage: -1 -1 -1 = random colors\n255 0 0 = Red Green Blue colors"); 
    HookEventEx("player_blind", player_blind); 
} 

public player_blind(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 
    new Float:duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration"); 

    PerformFade(client, duration); 
} 

PerformFade(client, &Float:fduration) 
{ 
    new String:value[15]; 
    GetConVarString(cvar, value, sizeof(value)); 
    new String:buffer[3][15]; 

    if(ExplodeString(value, " ", buffer, sizeof(buffer), sizeof(buffer[])) < 3) 
    { 
        return; 
    } 

    new color[4]; 

    color[0] = StringToInt(buffer[0]); 
    color[1] = StringToInt(buffer[1]); 
    color[2] = StringToInt(buffer[2]); 
    color[3] = 255; 

    //Random color 
    if(color[0] == -1 && color[1] == -1 && color[2] == -1) 
    { 
        color[0] = GetRandomInt(0, 255); 
        color[1] = GetRandomInt(0, 255); 
        color[2] = GetRandomInt(0, 255); 
    } 

    // Not fully blind, divide alpha color 
    if(fduration <= 3.0) 
    { 
        color[3] = RoundToNearest((255.0 / 3.0)*fduration); 
    } 

    fduration -= 3.0; 
    fduration *= 1000.0; 
    fduration /= 2.0; // Some reason in fade-usermessage duration has double time. 

    // Final fully blind time 
    fduration = fduration < 0.0 ? 0.0:fduration; 

    new holdtime = RoundToNearest(fduration); 
    new duration = 1500; // 3sec 


    SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0); // remove original flash 

    new Handle:message=StartMessageOne("Fade",client); 

    if (GetUserMessageType() == UM_Protobuf) 
    { 
        PbSetInt(message, "duration", duration); //fade 
        PbSetInt(message, "hold_time", holdtime); //blind 
        PbSetInt(message, "flags", FFADE_IN|FFADE_PURGE); 
        PbSetColor(message, "clr", color); 
    } 
    else 
    { 
        BfWriteShort(message,duration); 
        BfWriteShort(message,holdtime); 
        BfWriteShort(message, FFADE_IN|FFADE_PURGE); 
        BfWriteByte(message,color[0]); 
        BfWriteByte(message,color[1]); 
        BfWriteByte(message,color[2]); 
        BfWriteByte(message,color[3]); 
    } 

    EndMessage(); 
}  