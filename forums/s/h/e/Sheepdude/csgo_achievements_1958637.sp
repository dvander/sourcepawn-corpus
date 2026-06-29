#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public OnPluginStart()
{
	HookEvent("round_freeze_end", OnFreezeEnd);
}

public OnMapStart()
{
	CreateTimer(18.0, JoinTeam);
}

public Action:JoinTeam(Handle:timer, any:data)
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			ChangeClientTeam(i, 2);
}

public Action:OnFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsFakeClient(i))
			ForcePlayerSuicide(i);
}