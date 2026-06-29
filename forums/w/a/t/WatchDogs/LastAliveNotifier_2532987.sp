#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <cstrike>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Last Player Alive Notifier",
	author = PLUGIN_AUTHOR,
	description = "Prints a chat message that shows information about last alive player.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=298911"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int iTAlive = GetAliveClientsCount(CS_TEAM_T);
	int iCTAlive = GetAliveClientsCount(CS_TEAM_CT);
	
	if(iTAlive == 1)
	{
		int client = GetAliveClient(CS_TEAM_T);
		char sName[64];
		GetClientName(client, sName, sizeof(sName));
		CPrintToChatAll("{green}Player {purple}%s {default}[{green}%i HP{default}] against {blue}%i CT", sName, GetClientHealth(client), iCTAlive);
	}
	if(iCTAlive == 1)
	{
		int client = GetAliveClient(CS_TEAM_CT);
		char sName[64];
		GetClientName(client, sName, sizeof(sName));
		CPrintToChatAll("{green}Player {purple}%s {default}[{green}%i HP{default}] against {red}%i T", sName, GetClientHealth(client), iTAlive);
	}
}

stock int GetAliveClientsCount(int team)
{
	int j = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			j++;
		}
	}
	return j;
}

stock int GetAliveClient(int team)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return 0;
}