#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);

public Action:Event_PlayerDisconnect(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	CreateTimer(1.0, Timer_LittleDelay);
	return Plugin_Continue;
}

public Action:Timer_LittleDelay(Handle:hTimer, any:data)
{
	for(new iClient=1; iClient<=MaxClients; iClient++)
		if(IsClientConnected(iClient) && !IsFakeClient(iClient))
			return Plugin_Handled;
	
	ForceChangeLevel("cp_dustbowl", "Nobody here");
	return Plugin_Handled;
}