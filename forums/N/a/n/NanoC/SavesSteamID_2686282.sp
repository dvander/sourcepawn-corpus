#include <sourcemod>
#include <sdktools>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

char g_sPath[PLATFORM_MAX_PATH];
ConVar g_cvarPluginEnabled;

public Plugin myinfo =
{
	name			= "Saves Steam ID",
	description		= "Prints every player STEAM ID in a log file when they join",
	author			= "Nano",
	version			= "1.0",
	url				= "http://steamcommunity.com/id/marianzet1",
}

public void OnPluginStart() 
{
	g_cvarPluginEnabled = CreateConVar("sm_savesteamid_enabled", "1", _, _, true, 0.0, true, 1.0);
	HookEvent("player_connect_full", Event_FullConnect);
	
	RegAdminCmd("sm_enablesavesteamid", SavesSteamId, ADMFLAG_BAN);
	
	char sDate[12];
	FormatTime(sDate, sizeof(sDate), "%%m-%d");
	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "logs/savesteamdid/id_%s.log", sDate);	
}

public Action Event_FullConnect(Event event, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || IsFakeClient(client))
	{
		return;
	}
	
	char sPlayerAuth[24]; 
	if(g_cvarPluginEnabled.BoolValue && IsClientInGame(client))
	{
		GetClientAuthId(client, AuthId_Steam2, sPlayerAuth, sizeof(sPlayerAuth));
		LogToFile(g_sPath, "%40N %24s", client, sPlayerAuth);
	}
}

public Action SavesSteamId(int client, int args)
{
	if (g_cvarPluginEnabled.BoolValue)
	{
		ServerCommand("sm_savesteamid_enabled 0");
		CPrintToChat(client, "{green}[S.S.I]{lightgreen} This plugin was successfully {darkred}disabled.");
		return Plugin_Handled;
	}
	else
	{
		ServerCommand("sm_savesteamid_enabled 1");
		CPrintToChat(client, "{green}[S.S.I]{lightgreen} This plugin was successfully {lightblue}enabled.");
		return Plugin_Handled;
	}
}
