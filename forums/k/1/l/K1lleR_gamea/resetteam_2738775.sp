/*
    Copyright (C) 2021 $uicidE.
    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.3
    or any later version published by the Free Software Foundation;
    with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
    A copy of the license is included in the section entitled "GNU
    Free Documentation License".
*/

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "KilleR_gamea"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION ""

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name = "[CS:GO] Teleport-Fix",
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://suicidee.cf/"
};

public void OnPluginStart(){
	AddCommandListener(Cmd_ResetTeam, "resetteam");
}

public Action Cmd_ResetTeam(int client, const char[] szCommand, int args){
	if (IsValidClient(client) && IsPlayerAlive(client)){
		PrintToChatAll("[SM] %N tried to teleport.", client);
		ForcePlayerSuicide(client);
		
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client){
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client)){
		return true;
	}
	return false;
}