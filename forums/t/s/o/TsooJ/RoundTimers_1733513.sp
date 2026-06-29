#include <sourcemod> 
#include <sdktools> 

public OnPluginStart() 
{ 
    HookEventEx("teamplay_setup_finished", teamplay_event); 
    HookEventEx("teamplay_point_captured", teamplay_event); 
} 

public teamplay_event(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    new ent = FindEntityByClassname(MaxClients+1, "team_round_timer"); 
    if(ent == -1) 
    { 
        return; 
    } 

    if(StrEqual(name, "teamplay_point_captured")) 
    { 
        if( GetEventInt(event, "cp") == 0 ) // When they have first capture point 
        { 
            CreateTimer(1.0, Timer_AddTime, ent, TIMER_FLAG_NO_MAPCHANGE); 
        } 
        return; 
    } 
    // "teamplay_setup_finished" 
    CreateTimer(1.0, Timer_SetTime, ent, TIMER_FLAG_NO_MAPCHANGE); 
} 

public Action:Timer_AddTime(Handle:timer, any:ent) 
{ 
    SetVariantInt(300); // 300 sec ~ 5min 
    AcceptEntityInput(ent, "AddTime"); 
} 

public Action:Timer_SetTime(Handle:timer, any:ent)
{
	SetVariantInt(3600); // 3600 sec ~ 60min
	AcceptEntityInput(ent, "SetMaxTime");
	SetVariantInt(600); // 600 sec ~ 10min
	AcceptEntityInput(ent, "SetTime");
}