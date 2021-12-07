#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <geoip>
#define PL_VERSION "1.0"

public Plugin myinfo =
{
	name = "Player List",
	author = "urus and Psyk0tik (Crasher_3637)",
	description = "Provides commands to show a list of players on a server.",
	version = PL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=61013"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_plist", cmdPlayerList, ADMFLAG_GENERIC, "Show a list of players on a server.");
	CreateConVar("pl_version", PL_VERSION, "Plugin Version");
}

public Action cmdPlayerList(int client, int args)
{
	char sName[MAX_NAME_LENGTH + 1];
	char sSteamId[32];
	char sIPAddress[32];
	char sCountry[32];
	char sCode[4];
	Format(sName, sizeof(sName), "Name");
	Format(sSteamId, sizeof(sSteamId), "Steam ID");
	Format(sIPAddress, sizeof(sIPAddress), "IP");
	Format(sCountry, sizeof(sCountry), "Country");
	PrintToConsole(client, "+------------------------------------------------------------------------+");
	PrintToConsole(client, "#  %-21s %-16s %-10s %s", sSteamId, sIPAddress, sCountry, sName);
	PrintToConsole(client, "+------------------------------------------------------------------------+");
	int iCount;
	bool bFind;
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (IsClientInGame(iPlayer) && !IsFakeClient(iPlayer))
		{
			iCount++;
			GetClientIP(iPlayer, sIPAddress, sizeof(sIPAddress));
			GetClientAuthId(iPlayer, AuthId_Steam2, sSteamId, sizeof(sSteamId));
			bFind = GeoipCode3(sIPAddress, sCode);
			if (!bFind)
			{
				Format(sCountry, sizeof(sCountry), "Not found");
				PrintToConsole(client, "%d. %-21s %-16s %-10s %N", iCount, sSteamId, sIPAddress, sCountry, iPlayer);
			}
			else
			{
				PrintToConsole(client, "%d. %-21s %-16s %-10s %N", iCount, sSteamId, sIPAddress, sCode, iPlayer);
			}
		}
	}
	PrintToConsole(client, "+------------------------------------------------------------------------+");
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		PrintToChat(client, "[SM] See console for output");
	}
	return Plugin_Handled;
}