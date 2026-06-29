#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new players;

public Plugin:myinfo = 
{
	name = "BotCommander",
	author = "CrazyG0053",
	description = "Maintains bots if not enough human players are on",
	version = PLUGIN_VERSION,
	url = "http://nullpo.cc"
};




public OnPluginStart(){
	CreateConVar("botcommander_version", PLUGIN_VERSION, "Version of BotCommander", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
}

public OnMapStart(){
	players = 0;
	ServerCommand("bot_add");
}

public OnClientConnected(client){
	if (!IsFakeClient(client)){
		players++;
		if (players>1){
			ServerCommand("bot_kick");
		}
	}
}

public OnClientDisconnect(client){
	if (!IsFakeClient(client)){
		players--;
		if (players<2){
			ServerCommand("bot_kick");
			ServerCommand("bot_add");
		}
	}
}

public OnPluginEnd(){
}
