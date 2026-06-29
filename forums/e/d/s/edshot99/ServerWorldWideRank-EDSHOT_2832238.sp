#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2"

Handle g_Cvar_Rank;
int PlayersServed;
char currentday[12];
char thetime[12];

public Plugin:myinfo =
{
	name = "L4D Server World Wide Rank",
	author = ".Rain",
	description = "Changes server rank and number of players served.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/KadabraZz/"
};

public void OnPluginStart()
{
	g_Cvar_Rank		= CreateConVar("l4d_serverranking", "0", "This will change the world ranking of the server", FCVAR_NOTIFY);
	FormatTime(currentday, sizeof(currentday), "%Y-%m-%d");
	FormatTime(thetime, sizeof(thetime), "%Y-%m-%d");
}

public void OnPluginEnd()
{
	CloseHandle(g_Cvar_Rank);
}

public void OnClientConnected(client)
{
	FormatTime(thetime, sizeof(thetime), "%Y-%m-%d");
	if (!StrEqual(currentday, thetime, false))
	{
		PlayersServed = 0;
		FormatTime(currentday, sizeof(currentday), "%Y-%m-%d");
	}
	
	if (IsFakeClient(client))
	{
		ServerRanking();
	}
	else
	{
		PlayersServed++;
		ServerRanking();
	}
}

public void OnClientDisconnect()
{
	ServerRanking();
}

public Action:ServerRanking()
{
	GameRules_SetProp("m_iServerRank", any:(GetConVarInt(g_Cvar_Rank)), 4, 0, false);
	GameRules_SetProp("m_iServerPlayerCount", any:(PlayersServed), 4, 0, false);
	return Plugin_Continue;
}
