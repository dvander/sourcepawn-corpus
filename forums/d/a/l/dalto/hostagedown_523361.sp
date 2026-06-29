/*
hostagedown.sp

Description:
	Displays a message letting you who killed a hostage

Versions:
	1.0
		* Initial Release


*/


#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define MAX_FILE_LEN 80

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Hostage Down!",
	author = "dalto",
	description = "Displays a message letting you who killed a hostage",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	// Before we do anything else lets make sure that the plugin is not disabled
	CreateConVar("sm_hostage_down_version", PLUGIN_VERSION, "Hostage Down Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("hostage_killed", EventHostageKilled, EventHookMode_Post);
}

public Action:EventHostageKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientConnected(client))
	{
		return Plugin_Continue;
	}
	
	decl String:clientName[40];
	GetClientName(client, clientName, sizeof(clientName));
	PrintToChatAll("\x04%s killed a hostage!!!", clientName);
	
	return Plugin_Continue;
}

