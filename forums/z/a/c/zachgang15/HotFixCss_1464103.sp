/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.0.0.3";

public Plugin:myinfo = {
	
	name = "Block Console Suicide",
	author = "javalia",
	description = "temp plugin to avoid crash by kill cmd of client",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
//#include <cstrike>
//#include "sdkhooks"
//#include "vphysics"
#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

public OnPluginStart(){

	CreateConVar("BlockConsoleSuicide_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	RegConsoleCmd("kill", cmdFix, "block kill cmd");
	RegConsoleCmd("explode", cmdFix, "block kill cmd");
	RegConsoleCmd("spectate", cmdFix, "block kill cmd");
	RegConsoleCmd("jointeam", cmdFix, "no team change for now");
	
}

public Action:cmdFix(client, Args){
	
	decl Float:clientpos[3];
	GetClientAbsOrigin(client, clientpos);
	makeDamage(client, client, 9999999, DMG_GENERIC, 0.0, clientpos, "world");
	return Plugin_Continue;
	
}