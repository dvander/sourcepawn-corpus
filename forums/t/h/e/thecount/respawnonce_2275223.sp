#include <sourcemod>
#include <cstrike>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "RespawnOnce",
	author = "The Count",
	description = "Respawn only once.",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new bool:respawned[MAXPLAYERS + 1];

public OnPluginStart(){
	HookEvent("round_start", Evt_Start);
HookEvent("player_death", Evt_Death);
}

public Evt_Death(Handle:event, const String:name[], bool:dontB){
new client = GetClientOfUserId(GetEventInt(event, "userid"));
if(!respawned[client]){
respawned[client] = true;
CS_RespawnPlayer(client);
ClientCommand(client, "playgamesound ui/armsrace_level_up.wav");
}
}

public Evt_Start(Handle:event, const String:name[], bool:dontB){
	for(new i=1;i<=MaxClients;i++){
		respawned[i] = false;
	}
}