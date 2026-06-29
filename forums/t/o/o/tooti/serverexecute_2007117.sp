#include <sourcemod>
#include <tf2_stocks>

public OnPluginStart()
{
    HookEvent("player_spawn", Event_Spawn);
    HookEvent("player_death", Event_Death);
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients) return;
	new teamid = GetClientTeam(client)
	if(teamid == 2)
	{
		ServerCommand("sm_forcertd @red 23")
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) return;
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if (attacker <= 0 || attacker > MaxClients) return;
	new teamid = GetClientTeam(attacker)
	if(teamid == 2)
	{
		ServerCommand("sm_forcertd @red 23")
	}
}  