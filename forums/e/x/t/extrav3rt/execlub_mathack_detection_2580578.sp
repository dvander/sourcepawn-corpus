#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required;

char path[256];

ConVar g_hPenalty;
int g_iPenalty;


public Plugin myinfo = 
{
	name = "[EXECLUB] MatHack detection",
	author = "NightTime & extrav3rt",
	description = "very gj",
	version = "0.2",
	url = "http://execlub.biz"
};

public void OnPluginStart()
{
	g_hPenalty = CreateConVar("l4d2_penalty", "1", "1 - kick clients, 0 - record players in log file");
	g_iPenalty = g_hPenalty.IntValue;

	BuildPath(Path_SM, path, 256, "logs/cheaters.txt");

	HookEvent("player_connect_full", Event_PlayerConnect);
}

public void Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client)) return;

	QueryClientConVar(client, "mat_queue_mode", ClientQueryCallback_AntiVomit);
	QueryClientConVar(client, "mat_hdr_level", ClientQueryCallback_HDRLevel);
	QueryClientConVar(client, "mat_postprocess_enable", ClientQueryCallback_PostPrecess);
	QueryClientConVar(client, "r_drawothermodels", ClientQueryCallback_DrawModels);
}

public void ClientQueryCallback_DrawModels(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 1)
	{
		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | r_drawothermodels: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			KickClient(client, "ConVar r_drawothermodels violation");
		}
	}
}

public void ClientQueryCallback_PostPrecess(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 1)
	{
		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_postprocess_enable: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			KickClient(client, "ConVar mat_postprocess_enable violation");
		}
	}
}

public void ClientQueryCallback_AntiVomit(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue >= 3)
	{
		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_queue_mode: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			KickClient(client, "ConVar mat_queue_mode violation");
		}
	}
}

public void ClientQueryCallback_HDRLevel(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{	
	int clientCvarValue = StringToInt(cvarValue);

	if (clientCvarValue != 2)
	{
		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
		LogToFile(path, ".:[Name: %N | STEAMID: %s | mat_hdr_level: %d]:.", client, SteamID, clientCvarValue);

		if (g_iPenalty == 1)
		{
			KickClient(client, "ConVar mat_hdr_level violation");
		}
	}
}