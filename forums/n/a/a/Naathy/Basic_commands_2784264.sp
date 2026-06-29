#include <sourcemod>
#include <sdktools>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

ConVar BC_WelcomeMessage;
ConVar BC_Discord;
ConVar BC_Site;
ConVar BC_Group;
ConVar BC_Owner;
ConVar BC_Ip;

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "Basic Commands",
	author = "Nathy",
	description = "basic commands about server",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/nathyzinhaa"
};

public void OnPluginStart()
{
	BC_WelcomeMessage = CreateConVar("sm_basiccmds_welcome", "1", "Enable/Disable welcome message");
	BC_Discord = CreateConVar("sm_basiccmds_discord", "1", "Enable/Disable Discord command");
	BC_Site = CreateConVar("sm_basiccmds_site", "1", "Enable/Disable Site command");
	BC_Group = CreateConVar("sm_basiccmds_group", "1", "Enable/Disable Group command");
	BC_Owner = CreateConVar("sm_basiccmds_owner", "1", "Enable/Disable Owner Command");
	BC_Ip = CreateConVar("sm_basiccmds_ip", "1", "Enable/Disable IP command");
	
	RegConsoleCmd("sm_discord", Command_discord);
	RegConsoleCmd("sm_site", Command_site);
	RegConsoleCmd("sm_website", Command_site);
	RegConsoleCmd("sm_group", Command_group);
	RegConsoleCmd("sm_steam", Command_group);
	RegConsoleCmd("sm_steamgroup", Command_group);
	RegConsoleCmd("sm_owner", Command_owner);
	RegConsoleCmd("sm_ip", Command_ip);
	RegConsoleCmd("sm_serverip", Command_ip);
	
	AutoExecConfig(true, "Basic_commands");
	LoadTranslations("Basic_commands");
}

stock bool IsClientValid(int client = -1, bool bAlive = false) 
{
	return MaxClients >= client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)) ? true : false;
}

public void OnClientPutInServer(int client)
{
	if(GetConVarInt(BC_WelcomeMessage) == 1)
	{
		CreateTimer(7.0, msg, client);
	}
}

public Action msg(Handle timer, any client)
{
	if(IsClientValid(client))
		CPrintToChat(client, "%t", "Welcome Message");
	
	return Plugin_Handled;
}

public Action Command_discord(int client, int args){
	if(GetConVarInt(BC_Discord) == 1)
	{
	CPrintToChat(client, "%t", "Discord link");
	}
}

public Action Command_site(int client, int args){
	if(GetConVarInt(BC_Site) == 1)
	{
	CPrintToChat(client, "%t", "Website link");
	}
}

public Action Command_group(int client, int args){
	if (GetConVarInt(BC_Group) == 1)
	{
	CPrintToChat(client, "%t", "Steam Group link");
	}
}

public Action Command_owner(int client, int args){
	if (GetConVarInt(BC_Owner) == 1)
	{
	CPrintToChat(client, "%t", "Owner Profile link");
	}
}

public Action Command_ip(int client, int args){
	if (GetConVarInt(BC_Ip) == 1)
	{
	CPrintToChat(client, "%t", "Server ip");
	}
}