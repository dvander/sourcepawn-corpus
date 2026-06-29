/**************************************************************
--------------------------------------------------------------
 NEOTOKYO° Teamkill Penalty Fix

 Plugin licensed under the GPLv3
 
 Coded by Agiel.
--------------------------------------------------------------

Changelog

	1.0.0
		* Initial release
	1.0.1
		* Forgot to make sure that attacker != victim, duh...
**************************************************************/
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION	"1.0.1"

public Plugin:myinfo =
{
    name = "NEOTOKYO° Teamkill Penalty Fix",
    author = "Agiel",
    description = "Subtracts 1 XP when a player kills a teammate.",
    version = PLUGIN_VERSION,
    url = ""
};

new Handle:convar_nt_tkpenalty_version = INVALID_HANDLE;
new Handle:convar_neo_teamkill_punish = INVALID_HANDLE;

public OnPluginStart()
{
	convar_nt_tkpenalty_version = CreateConVar("sm_nt_tkpenalty_version", PLUGIN_VERSION, "NEOTOKYO° Teamkill Penalty Fix.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true);
	SetConVarString(convar_nt_tkpenalty_version, PLUGIN_VERSION, true, true);
	convar_neo_teamkill_punish = FindConVar("neo_teamkill_punish");
	
	HookEvent("player_death", Event_Player_Death);
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(convar_neo_teamkill_punish) == 0)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if(IsValidClient(attacker) && (victim != attacker))
		{
			new team_victim = GetClientTeam(victim);
			new team_attacker = GetClientTeam(attacker);
			
			if (team_victim == team_attacker)
			{
				// Subtract one point from attacker's XP (-2 to compensate for the point originally given for the kill)
				new attacker_xp = GetXP(attacker) - 2;
				SetXP(attacker, attacker_xp);
				SetRank(attacker, attacker_xp);
			}
		}
	}
}

stock SetXP(client, xp)
{
	SetEntProp(client, Prop_Data, "m_iFrags", xp);
	return 1;
}

stock SetRank(client, xp)
{
	new rank;
	if(xp <= -1)
		rank = 0;
	else if(xp >= 0 && xp <= 3)
		rank = 1;
	else if(xp >= 4 && xp <= 9)
		rank = 2;
	else if(xp >= 10 && xp <= 19)
		rank = 3;
	else if(xp >= 20)
		rank = 4;

	SetEntProp(client, Prop_Send, "m_iRank", rank);
	return 1;
}

stock GetXP(client)
{
	return GetClientFrags(client);
}

bool:IsValidClient(client){
	
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	/*
	if (IsFakeClient(client))
		return false;
	*/
	if (!IsClientInGame(client))
		return false;
	
	return true;
}