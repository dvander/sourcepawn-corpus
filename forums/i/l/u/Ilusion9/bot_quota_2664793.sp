#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo =
{
    name = "Disconnections list",
    author = "Ilusion9",
    description = "Informations about the last disconnected players.",
    version = "2.0",
    url = "https://github.com/Ilusion9/"
};

ConVar g_hBotQuotaCvar;

int g_iBotQuotaValue;

public void OnPluginStart()
{
	g_hBotQuotaCvar = FindConVar("bot_quota");
}

public void OnConfigsExecuted()
{
	g_iBotQuotaValue = g_hBotQuotaCvar.IntValue;
}

public void OnClientPostAdminCheck(int client)
{
	int players = GetRealClientCount();
	
	if (players >= g_iBotQuotaValue)
	{
		g_hBotQuotaCvar.IntValue = 0;
		return;
	}
	
	g_hBotQuotaCvar.IntValue = g_iBotQuotaValue - players;
}

public void OnClientDisconnect(int client)
{
	int players = GetRealClientCount(client);
	
	if (players >= g_iBotQuotaValue)
	{
		g_hBotQuotaCvar.IntValue = 0;
		return;
	}
	
	g_hBotQuotaCvar.IntValue = g_iBotQuotaValue - players;
}

stock int GetRealClientCount(int skip = 0)
{
	int num;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != skip && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			num++;
		}
	}

	return num;
}