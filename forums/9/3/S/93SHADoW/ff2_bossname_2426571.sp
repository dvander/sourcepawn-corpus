#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <events>
#include <freak_fortress_2>

#pragma newdecls required

#define FF2BOSSPREFS_VERSION "1.00"

public Plugin myinfo = {
	name = "Freak Fortress 2: Who's that current boss!",
	description = "Displays the current boss's name on server",
	author = "Koishi",
	version = FF2BOSSPREFS_VERSION,
};

ConVar hName;
char hName2[2][256];

public void OnPluginStart()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_Post);
	hName=FindConVar("hostname");
}

public void OnConfigsExecuted()
{
	GetConVarString(hName, hName2[0], sizeof(hName2[]));
}


public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
	{
		return;
	}

	char hUpdatedName[512];
	FF2_GetBossSpecial(0, hName2[1], sizeof(hName2[]));
	Format(hUpdatedName, sizeof(hUpdatedName), "%s | %s", hName2[0], hName2[1]);
	SetConVarString(hName, hUpdatedName);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
	{
		return;
	}
	SetConVarString(hName, hName2[0]);
}

public void OnPluginEnd()
{
	SetConVarString(hName, hName2[0]);
}

public void OnMapEnd()
{
	SetConVarString(hName, hName2[0]);
}