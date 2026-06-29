#include <sourcemod>
#include <sdktools>

#include <sourcemod> 
#include <sdktools> 

public OnPluginStart() 
{ 
    RegConsoleCmd("sm_test", probar); 
} 

public Action probar (client, args) 
{ 
    DisplayInstructorHint(client, 5.0, 0.1, 0.1, true, false, "icon_run", "icon_run", "", true, {255, 255, 0}, "TESTING INSTRUCTOR HINT. TEST 1."); 
    
    new Handle:event = CreateEvent("instructor_server_hint_create", true);
    SetEventString(event, "hint_name", "RandomHint");
    SetEventString(event, "hint_replace_key", "RandomHint");
    SetEventInt(event, "hint_target", 0);
    SetEventInt(event, "hint_activator_userid", 0);
    SetEventInt(event, "hint_timeout", 20 );
    SetEventString(event, "hint_icon_onscreen", "icon_tip");
    SetEventString(event, "hint_icon_offscreen", "icon_tip");
    SetEventString(event, "hint_caption", "TESTING INSTRUCTOR HINT. TEST 2.");
    SetEventString(event, "hint_activator_caption", "TESTING INSTRUCTOR HINT. TEST 2.");
    SetEventString(event, "hint_color", "255 0 0");
    SetEventFloat(event, "hint_icon_offset", 0.0 );
    SetEventFloat(event, "hint_range", 0.0 );
    SetEventInt(event, "hint_flags", 1);// Change it..
    SetEventString(event, "hint_binding", "");
    SetEventBool(event, "hint_allow_nodraw_target", true);
    SetEventBool(event, "hint_nooffscreen", false);
    SetEventBool(event, "hint_forcecaption", false);
    SetEventBool(event, "hint_local_player_only", false);
    FireEvent(event);

    return Plugin_Handled; 
} 

stock void DisplayInstructorHint(int iTargetEntity, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char sText[100])  
{  
    int iEntity = CreateEntityByName("env_instructor_hint");  
      
    if(iEntity <= 0)  
        return;  
          
    char sBuffer[32];  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", iTargetEntity);  
      
    // Target  
    DispatchKeyValue(iTargetEntity, "targetname", sBuffer);  
    DispatchKeyValue(iEntity, "hint_target", sBuffer);  
      
    // Static  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);  
    DispatchKeyValue(iEntity, "hint_static", sBuffer);  
      
    // Timeout  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fTime));  
    DispatchKeyValue(iEntity, "hint_timeout", sBuffer);  
    if(fTime > 0.0)  
        RemoveEntity2(iEntity, fTime);  
      
    // Height  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));  
    DispatchKeyValue(iEntity, "hint_icon_offset", sBuffer);  
      
    // Range  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));  
    DispatchKeyValue(iEntity, "hint_range", sBuffer);  
      
    // Show off screen  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);  
    DispatchKeyValue(iEntity, "hint_nooffscreen", sBuffer);  
      
    // Icons  
    DispatchKeyValue(iEntity, "hint_icon_onscreen", sIconOnScreen);  
    DispatchKeyValue(iEntity, "hint_icon_onscreen", sIconOffScreen);  
      
    // Command binding  
    DispatchKeyValue(iEntity, "hint_binding", sCmd);  
      
    // Show text behind walls  
    FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);  
    DispatchKeyValue(iEntity, "hint_forcecaption", sBuffer);  
      
    // Text color  
    FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);  
    DispatchKeyValue(iEntity, "hint_color", sBuffer);  
      
    //Text  
    ReplaceString(sText, sizeof(sText), "\n", " ");  
    DispatchKeyValue(iEntity, "hint_caption", sText);  
      
    DispatchSpawn(iEntity);  
    AcceptEntityInput(iEntity, "ShowHint");  
}  

stock void RemoveEntity2(entity, float time = 0.0)  
{  
    if (time == 0.0)  
    {  
        if (IsValidEntity(entity))  
        {  
            char edictname[32];  
            GetEdictClassname(entity, edictname, 32);  

            if (!StrEqual(edictname, "player"))  
                AcceptEntityInput(entity, "kill");  
        }  
    }  
    else if(time > 0.0)  
        CreateTimer(time, RemoveEntity2Timer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);  
}  

public Action RemoveEntity2Timer(Handle Timer, any entityRef)  
{  
    int entity = EntRefToEntIndex(entityRef);  
    if (entity != INVALID_ENT_REFERENCE)  
        RemoveEntity2(entity); // RemoveEntity2(...) is capable of handling references  
      
    return (Plugin_Stop);  
}  



    
// HookEvent("instructor_server_hint_create", Event_HintCreate);
// HookEvent("instructor_server_hint_stop", Event_HintStop);

// public Action:Event_HintStop(Handle:event, const String:name[], bool:dontBroadcast)
// {
    // PrintToServer(">>> Fired instructor_server_hint_stop!!");
    // return Plugin_Continue;
// }

// public Action:Event_HintCreate(Handle:event, const String:name[], bool:dontBroadcast)
// {
    // new hint_target = GetEventInt(event, "hint_target");
    // PrintToServer(">>> Fired instructor_server_hint_create!! hint_target: %d", hint_target);
    // return Plugin_Continue;
// }  