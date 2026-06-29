/**
 * 'TeamMoney' by bl4nk
 *
 * Description:
 *   At the beginning of a round the plugin adds up all
 *   of the money that each player on a team has, and
 *   then divides it by the amount of players on a team,
 *   effectively giving each player an equal share.
 *
 * CVars:
 *   sm_teammoney_enable - Enables\Disables the TeamMoney plugin.
 *     - 0 = Disabled
 *     - 1 = Enabled (default)
 */

#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.2a"

#define TEAM_T  2
#define TEAM_CT 3

new cashOffset;
new bool:isHooked = false;
new Handle:cvarEnable;

public Plugin:myinfo =
{
	name = "TeamMoney",
	author = "bl4nk",
	description = "Adds all of a team's money up and shares it equally between the team",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_teammoney_version", PLUGIN_VERSION, "TeamMoney Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_teammoney_enable", "1", "Enables/Disables the TeamMoney plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	cashOffset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (cashOffset == -1)
		SetFailState("Cash Offset Not Found!");

	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		HookEvent("round_start", event_RoundStart);
		LogMessage("[TeamMoney] - Loaded");
	}

	HookConVarChange(cvarEnable, CvarChange_Enable);
}

public CvarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarInt(cvarEnable))
	{
		if (isHooked)
		{
			isHooked = false;
			UnhookEvent("round_start", event_RoundStart);
		}
	}
	else if (!isHooked)
	{
		isHooked = true;
		HookEvent("round_start", event_RoundStart);
	}
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	CreateTimer(0.1, timer_RoundStart);

public Action:timer_RoundStart(Handle:timer)
{
	new iNum = 0, Players[MAXPLAYERS + 1] = 0, TeamMoney, ShareMoney;

	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_T)
		{
			Players[iNum] = i;
			iNum++;
		}
	}

	if (iNum > 0)
	{
		for (new i = 0; i < iNum; i++)
			TeamMoney += GetPlayerMoney(Players[i]);

		ShareMoney = TeamMoney / iNum;

		for (new i = 0; i < iNum; i++)
		{
				SetPlayerMoney(Players[i], ShareMoney);
				PrintToChat(Players[i], "*Team Money: %d | Share: %d", TeamMoney, ShareMoney);
		}
	}

	iNum = 0, TeamMoney = 0, ShareMoney = 0;
	for (new i = 0; i <= MAXPLAYERS; i++)
		Players[i] = 0;

	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_CT)
		{
			Players[iNum] = i;
			iNum++;
		}
	}

	if (iNum > 0)
	{
		for (new i = 0; i < iNum; i++)
			TeamMoney += GetPlayerMoney(Players[i]);

		ShareMoney = TeamMoney / iNum;

		for (new i = 0; i < iNum; i++)
		{
			SetPlayerMoney(Players[i], ShareMoney);
			PrintToChat(Players[i], "*Team Money: %d | Share: %d", TeamMoney, ShareMoney);
		}
	}
}

GetPlayerMoney(client)
{
	return GetEntData(client, cashOffset);
}

SetPlayerMoney(client, amount)
{
	SetEntData(client, cashOffset, amount);
}