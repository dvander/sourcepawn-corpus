#pragma semicolon 1

#define PLUGIN_AUTHOR "Addicted"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Self Respawn",
	author = PLUGIN_AUTHOR,
	description = "Allows players to respawn",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_respawn", Command_Respawn);
}

public Action:Command_Respawn(client, args)
{
	if(IsPlayerAlive(client) || GetClientTeam(client) == 1 || !IsClientConnected(client))
		return Plugin_Handled;
	
	CS_RespawnPlayer(client);
	PrintToChatAll("%N has been respawned", client);
	
	return Plugin_Handled;
}