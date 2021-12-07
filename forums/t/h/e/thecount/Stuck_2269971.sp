#include <sourcemod>
#include <cstrike>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Stuck",
	author = "The Count",
	description = "Respawn only once.",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new bool:respawned[MAXPLAYERS + 1];

public OnPluginStart(){
	RegConsoleCmd("sm_stuck", Cmd_Stuck, "Get yourself unstuck!");
	HookEvent("round_start", Evt_Start);
}

public Evt_Start(Handle:event, const String:name[], bool:dontB){
	for(new i=1;i<=MaxClients;i++){
		respawned[i] = false;
	}
}

public Action:Cmd_Stuck(client, args){
	if(!IsPlayerAlive(client)){
		PrintToChat(client, "[SM] Must be alive to use that.");
		return Plugin_Handled;
	}
	if(respawned[client]){
		PrintToChat(client, "\x01[SM] This may only be used \x04once\x01 per round.");
		return Plugin_Handled;
	}
	new health = GetClientHealth(client);
	CS_RespawnPlayer(client);
	SetEntityHealth(client, health);
	respawned[client] = true;
	PrintToChat(client, "\x01[SM] \x04Respawned to get unstuck!");
	ClientCommand(client, "playgamesound ui/armsrace_level_up.wav");
	return Plugin_Handled;
}