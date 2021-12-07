/*
Server event "weapon_fire", Tick 10649:
- "userid" = "2"
- "weapon" = "smg_mp5"
- "weaponid" = "33"
- "count" = "1"
Bacardi attacked Rochelle
Server event "player_hurt", Tick 10649:
- "userid" = "3"
- "attacker" = "2"
- "attackerentid" = "1"
- "health" = "1"
- "armor" = "0"
- "weapon" = "smg_mp5"
- "dmg_health" = "1"
- "dmg_armor" = "0"
- "hitgroup" = "2"
- "type" = "2"
Server event "player_hurt_concise", Tick 10649:
- "userid" = "3"
- "attackerentid" = "1"
- "type" = "2"
- "dmg_health" = "1"
*/

#include <sdkhooks>

int ff_damages[MAXPLAYERS+1];

ConVar sm_td_dmgtokick;
ConVar sm_td_dmgtowarn;
ConVar sv_vote_kick_ban_duration;
ConVar mp_friendlyfire;

public void OnPluginStart()
{
	sm_td_dmgtowarn = CreateConVar("sm_td_dmgtowarn", "20");
	sm_td_dmgtokick = CreateConVar("sm_td_dmgtokick", "50");
	sv_vote_kick_ban_duration = FindConVar("sv_vote_kick_ban_duration");
	mp_friendlyfire = FindConVar("mp_friendlyfire");

	if(mp_friendlyfire != null)
	{
		float value;
		if(mp_friendlyfire.GetBounds(ConVarBound_Lower, value) && value != 0.0)
		{
			mp_friendlyfire.SetBounds(ConVarBound_Lower, true, 0.0);
		}
	}

	HookEvent("player_hurt", player_hurt);
	HookEvent("player_team", player_team);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void player_team(Event event, const char[] name, bool dontBroadcast)
{
	ff_damages[GetClientOfUserId(event.GetInt("userid"))] = 0;
}

public void player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	static int msgdelay[MAXPLAYERS+1];

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(attacker != 0)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		
		if(GetClientTeam(attacker) == GetClientTeam(victim))
		{
			//PrintToServer("GetClientTeam %d", GetClientTeam(attacker));
			ff_damages[attacker] += event.GetInt("dmg_health");
			int timestamp = GetTime();

			
			if(ff_damages[attacker] >= sm_td_dmgtokick.IntValue)
			{
				
				if(sv_vote_kick_ban_duration.IntValue > 0)
				{
					LogAction(-1, attacker, "%L banned %d minutes. For doing too much team damage", attacker, sv_vote_kick_ban_duration.IntValue);
					BanClient(attacker, sv_vote_kick_ban_duration.IntValue, BANFLAG_AUTHID|BANFLAG_AUTO, "For doing too much team damage\n", "For doing too much team damage\n", "sm_td_dmgtokick", 0);
				}
				else
				{
					LogAction(-1, attacker, "%L kicked. For doing too much team damage", attacker);
					KickClient(attacker, "For doing too much team damage\n");
				}
			}
			else if(ff_damages[attacker] >= sm_td_dmgtowarn.IntValue && msgdelay[attacker] < timestamp)
			{
				msgdelay[attacker] = timestamp + 5;
				PrintToChat(attacker, " WARNING: Doing more team damage will cause you to be kicked!");
			}
		}
	}
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(mp_friendlyfire.IntValue != 0) return Plugin_Continue;

	if(0 < attacker <= MaxClients && GetClientTeam(victim) == GetClientTeam(attacker))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}