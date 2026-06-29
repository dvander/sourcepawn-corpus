#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:cvar_threshold = INVALID_HANDLE;

new bool:onHighThreshold = false;

public Plugin:myinfo = {
  name = "Player Threshold Configs",
  author = "Mister_Magotchi",
  description = "Executes configs based on player count at round start if non-spectator, non-bot player count has crossed a configurable threshold",
  version = PLUGIN_VERSION,
  url = ""
};

public OnPluginStart() {
	CreateConVar(
		"sm_player_threshold_configs_version",
		PLUGIN_VERSION,
		"Player Threshold Configs Version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
	);
	cvar_threshold = CreateConVar(
		"sm_player_threshold_configs_threshold",
		"12",
		"Minimum number of players required for plugin to use population-normal.cfg instead of population-low.cfg",
		FCVAR_PLUGIN
	);

	HookEvent("player_spawn", OnRoundStart);
	AutoExecConfig(true, "player-threshold-configs");

	new threshold = GetConVarInt(cvar_threshold);
	if (GetClientCount2() < threshold)
	{
		ServerCommand("exec population-low");
		onHighThreshold = false;
	}
	else
	{
		ServerCommand("exec population-normal");
		onHighThreshold = true;
	}
}

stock GetClientCount2()
{
	new client_count = 0;
	new client;
	
	for (client = MaxClients; 0 < client; client--) 
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client)) 
		{
			client_count++;
		}
	}
	
	return client_count;
}

public OnRoundStart (Handle:event, const String:name[], bool:dontBroadcast) {
	new client_count = GetClientCount2();
	new threshold = GetConVarInt(cvar_threshold);
	
	// We were high (we start on that because of new servers\rounds start with 0 people but now we're below!
	if (onHighThreshold && client_count < threshold)
	{
		ServerCommand("exec population-low");
		// Now on low
		onHighThreshold = false;
	}
	else if (onHighThreshold == false && client_count >= threshold)
	{
		ServerCommand("exec population-normal");
		onHighThreshold = true;
	}
}