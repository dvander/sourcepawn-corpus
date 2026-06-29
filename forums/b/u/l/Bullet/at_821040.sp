/* AllTalk_Notifier
* Author: Bullet (c) 4th May Jan 2009 ALL RIGHTS RESERVED
* 
* Features:
* 	- compiles and loads
* 	- shows version and author in hlsw
*	- Allows Player to type at and tells user if AllTalk is ON or OFF
* 
* Credits:
* 	- Fyren - for help with convar boolean values, and the semi-colon.
* 	- KaOs - m3motd - for help with inputs and outputs.
*	- MatthiasVance - For help with Handles, and the V.
*
* History
* Version 1.0.0
* 	- created compilable plugin
* 	- Added Version
*	- Added Key and Value (view in hlsw)
*	- Working Version.
*
*
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "AllTalk_Notifier",
	author = "Bullet",
	description = "Tells people if alltalk is on or off",
	version = PLUGIN_VERSION,
};

// When plugin starts
public OnPluginStart()
{
// Prepare the "say" command.
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

// Show cvars in hlsw
	CreateConVar("AllTalk_Notifier", PLUGIN_VERSION, "Shows the version", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	PrintToServer( ".------------------------------------------------------." );
	PrintToServer( "|             Bullets ALLTALK_NOTIFIER loaded          |" );
	PrintToServer( "'------------------------------------------------------'" );
}

public Action:Command_Say(client, args) {
	decl String:text[192];
	if (GetCmdArgString(text, sizeof(text)) < 1) {
		return Plugin_Continue;
	}
	new startidx;
	if (text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	decl String:message[8];
	BreakString(text[startidx], message, sizeof(message));
	if (strcmp(message, "at", false) == 0 || strcmp(message, "at", false) == 0) {
	AllTalk_Notifier(client, client);
	}
	return Plugin_Continue;
}

public AllTalk_Notifier(client, target) {
	if (client == target) {
 	new String:clientName[32];
 	new String:targetName[32];
	GetClientName(client, clientName, 31);
	GetClientName(target, targetName, 31);
// Query the alltalk convar, and tell the player that Alltalk is on or off.
	new Handle:alltalk = FindConVar("sv_alltalk");
//	if(alltalk != INVALID_HANDLE); {
	if(alltalk != INVALID_HANDLE) {
	PrintToChat(client, "[AT] Alltalk is %s", GetConVarBool(alltalk) ? "on" : "off");
	}
	}
}