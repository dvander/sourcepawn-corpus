#include <sourcemod>

public Plugin:myinfo = {
	name = "Kill Sound",
	author = "The Count",
	description = "",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public OnPluginStart(){ HookEvent("player_death", Evt_Death); }

public Evt_Death(Handle:event, const String:name[], bool:dontB){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(client < 1 || client > MaxClients || attacker < 1 || attacker > MaxClients || attacker == client){ return; }
	ClientCommand(attacker, "play *buttons/bell1.wav");
}