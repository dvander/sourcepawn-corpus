#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#define PLUGIN_VERSION "0.00"

EngineVersion g_Game;
ConVar isEnable;
ConVar adminFlag;
ConVar reserveFlag;
ConVar baseFlag;

public Plugin myinfo = 
{
	name = "Custom Clan Tag",
	author = "Munoon",
	description = "Plugin switch player clan tag Ddepending on his role",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	else
	{
		HookEvent("player_team", change_clantag);
		isEnable = CreateConVar("custom_clantag_enable", "1", "Is plugin enabled");
		adminFlag = CreateConVar("custom_clantag_admin", "ADMIN", "Clan tag to be set for admin");
		reserveFlag = CreateConVar("custom_clantag_reserve", "RESERVE", "Clan tag to be set for player with reserve slot");
		baseFlag = CreateConVar("custom_clantag_base", "PLAYER", "Clan tag to be set for other players");
		AutoExecConfig(true, "clantag");
	}
}

public Action change_clantag(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(isEnable)) return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char tag[128];
	
	if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
		GetConVarString(adminFlag, tag, sizeof(tag));
	else if (GetUserFlagBits(client) & ADMFLAG_RESERVATION) 
		GetConVarString(reserveFlag, tag, sizeof(tag));
	else
		GetConVarString(baseFlag, tag, sizeof(tag));
		
	CS_SetClientClanTag(client, tag);
}  