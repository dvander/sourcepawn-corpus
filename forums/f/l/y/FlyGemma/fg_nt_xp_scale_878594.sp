/**************************************************************
--------------------------------------------------------------
 NEOTOKYO° XP Scale

 Plugin licensed under the GPLv3
 
 Coded by FlyGemma.
 
 Credits to: 
 	Bot04 - Testing and lack of feedback.
--------------------------------------------------------------

Changelog

	1.0.0
		* Initial release
	1.0.1
		* Fixed client index 0 (server) errors.
**************************************************************/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.0.1"

public Plugin:myinfo =
{
    name = "NEOTOKYO° XP Scale",
    author = "FlyGemma",
    description = "Various options for scaling XP in NEOTOKYO°",
    version = PLUGIN_VERSION,
    url = ""
};

new Handle:convar_ntxs_scale_enabled = INVALID_HANDLE;
new Handle:convar_ntxs_scale_gap = INVALID_HANDLE;
new Handle:convar_ntxs_scale = INVALID_HANDLE;
new Handle:convar_ntxs_minxp = INVALID_HANDLE;
new Handle:convar_ntxs_maxxp = INVALID_HANDLE;
new Handle:convar_ntxs_worthless = INVALID_HANDLE;
new Handle:convar_ntxs_worthless_gap = INVALID_HANDLE;
new Handle:convar_ntxs_version = INVALID_HANDLE;

public OnPluginStart()
{
	convar_ntxs_scale_enabled = CreateConVar("sm_ntxs_scale_enabled", "1", "Enables or Disables XP Scaling System.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ntxs_scale_gap = CreateConVar("sm_ntxs_scale_gap", "4", "The XP scale gap.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	convar_ntxs_scale = CreateConVar("sm_ntxs_scale", "1", "The XP Multiplier scale.", FCVAR_NOTIFY, true, 1.0, true, 20.0);
	convar_ntxs_minxp = CreateConVar("sm_ntxs_minxp", "1", "The minimum amount of bonus XP gained.", FCVAR_NOTIFY, true, 1.0, true, 20.0);
	convar_ntxs_maxxp = CreateConVar("sm_ntxs_maxxp", "3", "The maximum amount of bonus XP gained.", FCVAR_NOTIFY, true, 1.0, true, 20.0);
	convar_ntxs_worthless = CreateConVar("sm_ntxs_worthless", "1", "Enables or Disables the Worthless XP System.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ntxs_worthless_gap = CreateConVar("sm_ntxs_worthless_gap", "8", "The Worthless XP gap.", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	convar_ntxs_version = CreateConVar("sm_ntxs_version", PLUGIN_VERSION, "NEOTOKYO° XP Scale version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true);
	SetConVarString(convar_ntxs_version, PLUGIN_VERSION, true, true);
	
	HookEvent("player_death", Event_Player_Death);
}
public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(convar_ntxs_scale_enabled))
	{
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(userid != 0 && attacker != 0 && IsClientConnected(userid) && IsClientConnected(attacker) && IsClientInGame(userid) && IsClientInGame(userid))
		{
			new userid_team = GetClientTeam(userid);
			new attacker_team = GetClientTeam(attacker);
			if(userid_team != attacker_team)
			{
				new userid_xp = GetXP(userid), attacker_xp = GetXP(attacker);
				if(attacker_xp <= userid_xp)
				{
					new attacker_xp_gain = GetConVarInt(convar_ntxs_scale) * ((userid_xp - attacker_xp) / GetConVarInt(convar_ntxs_scale_gap));
					
					if(attacker_xp_gain < GetConVarInt(convar_ntxs_minxp) && attacker_xp_gain > 0)
						attacker_xp_gain = GetConVarInt(convar_ntxs_minxp);

					else if(attacker_xp_gain > GetConVarInt(convar_ntxs_maxxp))
						attacker_xp_gain = GetConVarInt(convar_ntxs_maxxp);
					
					attacker_xp += attacker_xp_gain;
					SetXP(attacker, attacker_xp);
					SetRank(attacker, attacker_xp);
				}
				if(GetConVarBool(convar_ntxs_worthless) && attacker_xp > userid_xp)
				{
					new attacker_xp_gain = (attacker_xp - userid_xp) / GetConVarInt(convar_ntxs_worthless_gap);
					if(attacker_xp_gain >= 1)
					{
						SetXP(attacker, attacker_xp - 1);
						SetRank(attacker, attacker_xp - 1);
					}
				}
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