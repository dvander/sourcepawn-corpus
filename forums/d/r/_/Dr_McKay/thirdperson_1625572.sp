#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2.0"

public Plugin:myinfo = {
	name        = "[ANY] Thirdperson",
	author      = "Dr. McKay",
	description = "Allows players to go into thirdperson",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

new bool:isInThirdperson[MAXPLAYERS + 1] = false;
new Handle:enabledCvar = INVALID_HANDLE;

new Handle:sv_cheats = INVALID_HANDLE;

public OnPluginStart() {
	RegConsoleCmd("sm_thirdperson", Command_Thirdperson, "Type !thirdperson to go into thirdperson mode");
	RegConsoleCmd("sm_firstperson", Command_Firstperson, "Type !firstperson to exit thirdperson mode");
	enabledCvar = CreateConVar("sm_thirdperson_enabled", "1", "Is thirdperson enabled?");
	sv_cheats = FindConVar("sv_cheats");
	HookConVarChange(enabledCvar, CvarChanged);
	CreateConVar("sm_thirdperson_version", PLUGIN_VERSION, "Thirdperson version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(!GetConVarBool(enabledCvar)) {
		for(new i = 1; i <= MaxClients; i++) {
			if(isInThirdperson[i]) {
				ClientCommand(i, "firstperson");
				SendConVarValue(i, sv_cheats, "0");
				isInThirdperson[i] = false;
				PrintToChat(i, "\x04[\x03SM\x04] \x01Thirdperson mode has been disabled by the administrator");
			}
		}
	}
}

public OnClientConnected(client) {
	isInThirdperson[client] = false;
}

public OnClientDisconnect(client) {
	isInThirdperson[client] = false;
}

public Action:Command_Thirdperson(client, args) {
	if(!GetConVarBool(enabledCvar)) {
		ReplyToCommand(client, "\x04[\x03SM\x04] \x01Thirdperson mode is currently disabled");
		return Plugin_Handled;
	}
	if(isInThirdperson[client]) {
		ReplyToCommand(client, "\x04[\x03SM\x04] \x01You are already in thirdperson mode. To exit, type \x03!firstperson");
		return Plugin_Handled;
	}
	isInThirdperson[client] = true;
	SendConVarValue(client, sv_cheats, "1");
	ClientCommand(client, "thirdperson");
	if(!IsPlayerAlive(client)) {
		ReplyToCommand(client, "\x04[\x03SM\x04] \x01You will be in thirdperson mode when you spawn. To exit, type \x03!firstperson");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "\x04[\x03SM\x04] \x01You are now in thirdperson mode. To exit, type \x03!firstperson");
	return Plugin_Handled;
}

public Action:Command_Firstperson(client, args) {
	if(!GetConVarBool(enabledCvar)) {
		ReplyToCommand(client, "\x04[\x03SM\x04] \x01Thirdperson mode is currently disabled");
		return Plugin_Handled;
	}
	if(!isInThirdperson[client]) {
		ReplyToCommand(client, "\x04[\x03SM\x04] \x01You are not in thirdperson mode. To enter thirdperson mode, type \x03!thirdperson");
		return Plugin_Handled;
	}
	isInThirdperson[client] = false;
	ClientCommand(client, "firstperson");
	SendConVarValue(client, sv_cheats, "0");
	ReplyToCommand(client, "\x04[\x03SM\x04] \x01You are no longer in thirdperson mode. To enter thirdperson mode again, type \x03!thirdperson");
	return Plugin_Handled;
}