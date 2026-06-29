#include <sourcemod>
#include <cstrike>
#include <timers>
#include <sdktools>

#define VERSION "0.1.0 Alpha"

ConVar g_cvMaxMoney;

public Plugin:myinfo =
{
	name = "Bomb Assault",
	author = "Ris",
	description = "Bomb defusal mode with player respawns",
	version = VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_bombassault_version", VERSION, "Bomb Assault Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("round_poststart", Event_RoundPostStart, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	g_cvMaxMoney = FindConVar("mp_maxmoney");
}

public Action:Event_RoundPostStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	ServerCommand("mp_buytime 0");
	ServerCommand("mp_buy_anywhere 1");
	ServerCommand("mp_buy_during_immunity 1");
	ServerCommand("mp_respawn_immunitytime 10");
	ServerCommand("mp_respawn_on_death_t 1");
	ServerCommand("mp_respawn_on_death_ct 1");
	ServerCommand("mp_respawnwavetime_t 2");
	ServerCommand("mp_respawnwavetime_ct 2");


	PrintToChatAll("You are playing Bomb Assault mode.");
	PrintToChatAll("You will respawn instantly after dying,");
	PrintToChatAll("and will earn cash for your team by getting kills.");

	return Plugin_Continue;
}

public void GiveCashToPlayer(cash, player_id)
{
	new max_cash = g_cvMaxMoney.IntValue;
	new new_cash = GetEntProp(player_id, Prop_Send, "m_iAccount") + cash;
	if(new_cash > max_cash)
	{
		new_cash = max_cash;
	}
	SetEntProp(player_id, Prop_Send, "m_iAccount", new_cash);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim_id = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker_id = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	GiveCashToPlayer(500, victim_id);

	if(attacker_id > 0 && attacker_id <= MaxClients)
	{
		new victim_team = GetClientTeam(victim_id);
		new attacker_team = GetClientTeam(attacker_id);

		if(victim_team != attacker_team && (attacker_team == CS_TEAM_T || attacker_team == CS_TEAM_CT))
		{
			for(new i=1;i<=MaxClients;i++)
			{ 
				if(IsClientInGame(i) && GetClientTeam(i) == attacker_team)
				{
					GiveCashToPlayer(1000, i);
				}
			}
		}
	}
	return Plugin_Continue;
}