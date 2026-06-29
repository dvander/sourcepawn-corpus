#pragma semicolon 1

//#define DEBUG

#define TEAM_NONE 0
#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3

#include <cstrike>
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "CS:GO Bot Quota Fix DM",
	author = "Otstrel.ru Team, klexen",
	description = "Fixes bot_quota_mode fill on CS:GO server: Klexen Edit",
	version = "1.3",
	url = "otstrel.ru"
}

new Handle:g_Cvar_Enable = INVALID_HANDLE;
new bool:g_enable = false;

new g_Tcount = 0;
new g_CTcount = 0;
new g_BotTcount = 0;
new g_BotCTcount = 0;

new Handle:g_Cvar_BotQuota = INVALID_HANDLE;
new g_botQuota = 0;

public OnPluginStart() {
	g_Cvar_Enable = CreateConVar("sm_csgobotquotafix_enable", "1", "Enable bot quota fix");
	g_enable = GetConVarBool(g_Cvar_Enable);
	HookConVarChange(g_Cvar_Enable, CvarChanged);
	
	g_Cvar_BotQuota = CreateConVar("sm_csgobotquotafix_quota", "0", "Bot quota (bot quota fix)");
	g_botQuota = GetConVarInt(g_Cvar_BotQuota);
	HookConVarChange(g_Cvar_BotQuota, CvarChanged);
	g_botQuota += 1;
	HookEvent("player_team", Event_PlayerTeam);
}

public CvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) {
	if (cvar == g_Cvar_Enable) {
		g_enable = GetConVarBool(g_Cvar_Enable);
		CheckBalance();
		return;
	}
	if (cvar == g_Cvar_BotQuota) {
		g_botQuota = GetConVarInt(g_Cvar_BotQuota);
		CheckBalance();
		return;
	}
}

public OnMapStart() {
	RecalcTeamCount();
	CheckBalance();
}

RecalcTeamCount() {
	g_Tcount = 0;
	g_CTcount = 0;
	g_BotTcount = 0;
	g_BotCTcount = 0;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			ChangeTeamCount(GetClientTeam(i), 1, IsFakeClient(i));
		}
	}
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] Recalc T=%i CT=%i TB=%i CTB=%i", g_Tcount, g_CTcount, g_BotTcount, g_BotCTcount);
	LogError("[DEBUG] Recalc T=%i CT=%i TB=%i CTB=%i", g_Tcount, g_CTcount, g_BotTcount, g_BotCTcount);
	#endif
}

ChangeTeamCount(team, diff, bool:isBot) {
	#if defined DEBUG
	PrintToChatAll("[DEBUG] ChangeTeamCount(team=%i, diff=%i, bool:isBot=%i)", team, diff, isBot);
	LogError("[DEBUG] ChangeTeamCount(team=%i, diff=%i, bool:isBot=%i)", team, diff, isBot);
	#endif
	switch (team) {
		case TEAM_T: {
			if (isBot) {
				g_BotTcount += diff;
			} else {
				g_Tcount += diff;
			}
		}
		case TEAM_CT: {
			if (isBot) {
				g_BotCTcount += diff;
			} else {
				g_CTcount += diff;
			}
		}
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	new client          = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldTeam         = GetEventInt(event, "oldteam");
	new newTeam         = GetEventInt(event, "team");
	new bool:disconnect = GetEventBool(event, "disconnect");
	
	/* Player disconnected and didn't join a new team */
	if (!disconnect) {
		ChangeTeamCount(oldTeam, -1, IsFakeClient(client));
		ChangeTeamCount(newTeam, 1, IsFakeClient(client));
	} else {
		RecalcTeamCount();
	}
	
	CheckBalance();
}

CheckBalance() {
	if (!g_enable || (g_botQuota <=0)) {
		return;
	}
	
	#if defined DEBUG
	PrintToChatAll("[DEBUG] Check T=%i CT=%i TB=%i CTB=%i", g_Tcount, g_CTcount, g_BotTcount, g_BotCTcount);
	LogError("[DEBUG] Check T=%i CT=%i TB=%i CTB=%i", g_Tcount, g_CTcount, g_BotTcount, g_BotCTcount);
	#endif
	
	new bots = g_BotTcount + g_BotCTcount;
	new humans = g_Tcount + g_CTcount;
				
	if (humans >= g_botQuota) {
		if (bots <= 0) {
			//nothing to do
			#if defined DEBUG
			PrintToChatAll("[DEBUG] bots <=0, humans >= quota, nothing too do");
			LogError("[DEBUG] bots 0, humans >= quota, nothing too do");
			#endif
			return;
		} else {
			//kick all bots
			#if defined DEBUG
			PrintToChatAll("[DEBUG] bots >0, humans >= quota, kick all bots");
			LogError("[DEBUG] bots >0, humans >= quota, kick all bots");
			#endif
			ServerCommand("bot_kick");
			return;
		}
	} else {
		new botQuota = g_botQuota - humans;
		if (botQuota == bots) {
			// nothing to do
			#if defined DEBUG
			PrintToChatAll("[DEBUG] botquota = bots+humans, nothing too do");
			LogError("[DEBUG] botquota = bots+humans, nothing too do");
			#endif
			RespawnDeadBots();
			return;
		}
		
		if (bots > botQuota) {
			//kick some bots
			#if defined DEBUG
			PrintToChatAll("[DEBUG] botquota < bots, kick some bots");
			LogError("[DEBUG] botquota < bots, kick some bots");
			#endif
			ServerCommand("bot_kick %s", g_BotCTcount > g_BotTcount? "ct": "t");
			RespawnDeadBots();
			return;
		} else {
			//add bots
			#if defined DEBUG
			PrintToChatAll("[DEBUG] botquota > bots, add some bots");
			LogError("[DEBUG] botquota > bots, add some bots");
			#endif
			ServerCommand("bot_add %s", g_BotCTcount+g_CTcount <= g_BotTcount+g_Tcount? "ct": "t");
			RespawnDeadBots();
			return;
		}
	}
}

RespawnDeadBots()
{
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR && !IsPlayerAlive(i) && IsFakeClient(i)) {
			CS_RespawnPlayer(i);	
		}
	}
}

