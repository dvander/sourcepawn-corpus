#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <adminmenu>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "SM /me Support",
	author = "Mad_Dugan",
	description = "Allows players to type '/me <text>' and it show up in chat as '<player name> <text>'",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_me_version", PLUGIN_VERSION, "Version for Source Engine '/me' plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	
	RegConsoleCmd("sm_me", Handle_Me, "Usage: /me <text>");
}

public Action:Handle_Me(client, args)
{
	decl String:name[64];
	decl String:string[1024];
	
	// Get client name
	GetClientName(client, name, sizeof(name));
	
	//Get command string
	GetCmdArgString(string, sizeof(string));
	
	// Print to all
	PrintToChatAll("* %s %s", name, string);
	
	return Plugin_Handled;
}
