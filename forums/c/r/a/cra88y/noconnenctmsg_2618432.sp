#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Block Event Broadcast",
	author = "cra88y",
	version = "1.0"
};

public void OnPluginStart()
{
	//HookEvent("player_team", BlockEvent, EventHookMode_Pre); //Uncomment to block join team messages aswell
	HookEvent("player_disconnect", BlockEvent, EventHookMode_Pre);
	HookEvent("player_connect", BlockEvent, EventHookMode_Pre);
}

public Action BlockEvent(Event event, char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, true);
    return Plugin_Continue;
}  
