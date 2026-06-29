#define PLUGIN_VERSION "1.2.0"

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#pragma semicolon 1

//Building codes:
//0 0: dispenser
//2 0: sentry
//1 0: tele entrance
//1 1: tele exit

public Plugin:myinfo = 
{
	name = "TF2 Build Exploit Autobanner",
	author = "msleeper",
	description = "Autobans people who use the multi-building and spy dispenser exploits.",
	version = PLUGIN_VERSION,
	url = "http://www.msleeper.com/"
}

public OnPluginStart()
{
	// Plugin version public Cvar
	CreateConVar("sm_buildingban_version", PLUGIN_VERSION, "Autobans people who use the building exploits", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegConsoleCmd("build", Cmd_Build, "Hurf durf");
}

public Action:Cmd_Build(client, args)
{
	new String:arg1[16];
	new String:arg2[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	PrintToConsole(client, "Received build request (%s %s)", arg1, arg2);
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy) {
		if(strcmp(arg1, "0", false) == 0 && strcmp(arg2, "0", false) == 0) {
			PrintToConsole(client, "Invalid building request (%s %s)", arg1, arg2);
			ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), 0, "Building Exploit");
			return Plugin_Handled;
		}
	} else if(TF2_GetPlayerClass(client) == TFClass_Engineer) {
		if(strcmp(arg1, "1", false) == 0) { //Teleporter
			if(strcmp(arg2, "0", false) != 0 && strcmp(arg2, "1", false) != 0) {
				PrintToConsole(client, "Invalid building request (%s %s)", arg1, arg2);
				ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), 0, "Building Exploit");
				return Plugin_Handled;
			}
		} else { //Not a teleporter
			if(strcmp(arg2, "0", false) != 0) {
				PrintToConsole(client, "Invalid building request (%s %s)", arg1, arg2);
				ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), 0, "Building Exploit");
				return Plugin_Handled;
			}
		}
	} else {
		PrintToConsole(client, "Invalid building request (%s %s)", arg1, arg2);
		ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), 0, "Building Exploit");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}