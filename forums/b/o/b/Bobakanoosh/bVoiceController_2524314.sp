#include <sdktools>

#define PLUGIN_AUTHOR "Bobakanoosh"
#define PLUGIN_VERSION "1.0.0"

#define LoopValidPlayers(%1) for(int %1; %1 < MaxClients; %1++)\
								if(IsValidClient(%1))

#pragma newdecls required

public Plugin myinfo = {

	name = "bVoiceController",
	author = PLUGIN_AUTHOR,
	description = "Controls users voices based on whether they're dead or not",
	version = PLUGIN_VERSION,
	url = ""
	
};

public void OnPluginStart() {

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawned", Event_PlayerSpawned);
	
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client))
		return Plugin_Continue;
		
	LoopValidPlayers(i) {	
	
		if(i == client)
			continue;
		
		if(IsPlayerAlive(i)) {
		
			SetListenOverride(i, client, Listen_No);
			SetListenOverride(client, i, Listen_Yes);
		
		} else {
		
			SetListenOverride(i, client, Listen_Yes);
			SetListenOverride(client, i, Listen_Yes);
		
		}
		
		if(CheckCommandAccess(client, "", ADMFLAG_GENERIC))
			SetListenOverride(i, client, Listen_Yes);
		
	}

	return Plugin_Continue;
}

public Action Event_PlayerSpawned(Handle event, const char[] name, bool inrestart) {

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	LoopValidPlayers(i) {
		
		SetListenOverride(i, client, Listen_Yes);
	
	}

	return Plugin_Continue;

}

stock bool IsValidClient(int client, bool noBots=true) {

	if (client < 1 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (!IsClientConnected(client))
		return false;

	if (noBots)
		if (IsFakeClient(client))
			return false;

	if (IsClientSourceTV(client))
		return false;

	return true;

}