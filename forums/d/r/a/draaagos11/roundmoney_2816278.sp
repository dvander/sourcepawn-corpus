#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define VERSION "1.0.0"

public Plugin myinfo =
{
	name		= "Money Fix",
	author		= "dragos112",
	description = "",
	version		= VERSION,
	url			= "https://alyx.ro"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool broadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	ConVar startMoney = FindConVar("mp_startmoney");
	ConVar maxMoney = FindConVar("mp_maxmoney");
	ConVar maxRounds = FindConVar("mp_maxrounds");

	int	currentRounds = GameRules_GetProp("m_totalRoundsPlayed");
	if (currentRounds == 0 || currentRounds == maxRounds.IntValue / 2)
		SetEntProp(client, Prop_Send, "m_iAccount", startMoney.IntValue);
	else 
		SetEntProp(client, Prop_Send, "m_iAccount", maxMoney.IntValue);

	return Plugin_Continue;
}