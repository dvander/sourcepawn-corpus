#pragma semicolon 1

#define TEAM_NONE 0
#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3

#include <cstrike>
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "CS:GO Bot Quota Fix",
	author = "Otstrel.ru Team, DoPe^, nullb",
	description = "Fixes bot_quota_mode fill, for CS:GO servers",
	version = "2.0",
	url = "otstrel.ru"
};

new Handle:g_Cvar_Enable = INVALID_HANDLE;
new bool:g_enable = false;

new Handle: g_Cvar_BotDelayEnable = INVALID_HANDLE;
new bool:g_delayenable = false;

new g_Tcount = 0;
new g_CTcount = 0;
new g_BotTcount = 0;
new g_BotCTcount = 0;

new Handle:g_Cvar_BotQuota = INVALID_HANDLE;
new g_botQuota = 0;

new Handle:g_Cvar_BotDelay;
new g_botDelay = 1;

new bool:g_hookenabled = false;

new Handle:bot_delay_timer = INVALID_HANDLE;


public OnPluginStart() {
	g_Cvar_Enable = CreateConVar("sm_csgobotquotafix_enable", "1", "Enable bot quota fix");
	g_enable = GetConVarBool(g_Cvar_Enable);
	HookConVarChange(g_Cvar_Enable, CvarChanged);

	g_Cvar_BotQuota = CreateConVar("sm_csgobotquotafix_quota", "0", "Bot quota (bot quota fix)");
	g_botQuota = GetConVarInt(g_Cvar_BotQuota);
	HookConVarChange(g_Cvar_BotQuota, CvarChanged);


	g_Cvar_BotDelayEnable = CreateConVar("sm_csgobotquotafix_delay_enable", "1", "Enable/Disable the Bot Join Delay", FCVAR_PLUGIN, true, 0.00, true, 1.00);
	g_delayenable = GetConVarBool(g_Cvar_BotDelayEnable);
	HookConVarChange(g_Cvar_BotDelayEnable, CvarChanged);

	g_Cvar_BotDelay = CreateConVar("sm_csgobotquotafix_delay", "10", "Delay in seconds for when the bots should join", FCVAR_PLUGIN, true, 1.00, true, 240.00);
	g_botDelay = GetConVarInt(g_Cvar_BotDelay);
	HookConVarChange(g_Cvar_BotDelay, CvarChanged);
	

	if (!g_delayenable && g_hookenabled == false) {
		HookEvent("player_team", Event_PlayerTeam);
		g_hookenabled = true;
	}
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
	if (cvar == g_Cvar_BotDelayEnable) {
		g_delayenable = GetConVarBool(g_Cvar_BotDelayEnable);
		CheckBalance();
		return;
	}
	if (cvar == g_Cvar_BotDelay) {
		g_botDelay = GetConVarInt(g_Cvar_BotDelay);
		CheckBalance();
		return;
	}
}

public OnMapStart() {
	if (g_delayenable && g_hookenabled == false) {
		g_botDelay = GetConVarInt(g_Cvar_BotDelay);
		bot_delay_timer = CreateTimer(g_botDelay * 1.0, Timer_BotDelay);
	}
}

public Action:Timer_BotDelay(Handle:timer) {
	RecalcTeamCount();
	CheckBalance();
	HookEvent("player_team", Event_PlayerTeam);
	g_hookenabled = true;

	bot_delay_timer = INVALID_HANDLE;
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
}

ChangeTeamCount(team, diff, bool:isBot) {
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
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldTeam = GetEventInt(event, "oldteam");
	new newTeam = GetEventInt(event, "team");
	new bool:disconnect = GetEventBool(event, "disconnect");

	if (!disconnect) {
		ChangeTeamCount(oldTeam, -1, IsFakeClient(client));
		ChangeTeamCount(newTeam, 1, IsFakeClient(client));
	} else {
		RecalcTeamCount();
	}

	CheckBalance();
}

CheckBalance() {
	if (!g_enable || (g_botQuota <= 0)) {
		return;
	}

	new bots = g_BotTcount + g_BotCTcount;
	new humans = g_Tcount + g_CTcount;

	if (bots > 0 && humans == 0) {
		ServerCommand("bot_kick all");
	} else if (humans >= g_botQuota && bots > 0) {
		ServerCommand("bot_kick");
	} else if (humans < g_botQuota) {
		new botQuota = g_botQuota - humans;

		if (bots > botQuota) {
			ServerCommand("bot_kick %s", (g_BotCTcount > g_BotTcount) ? "ct" : "t");
		} else if (bots < botQuota) {
			ServerCommand("bot_add %s", (g_BotCTcount + g_CTcount <= g_BotTcount + g_Tcount) ? "ct" : "t");
		}
	}
}

public OnMapEnd() {
	if (g_delayenable && g_hookenabled == true) {
		UnhookEvent("player_team", Event_PlayerTeam);
		g_hookenabled = false;
	}

	if(bot_delay_timer != INVALID_HANDLE) {
		KillTimer(bot_delay_timer);
		bot_delay_timer = INVALID_HANDLE;
	}
}

