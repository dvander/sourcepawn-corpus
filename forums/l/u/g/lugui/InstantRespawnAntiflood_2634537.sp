#pragma semicolon 1

#include <sourcemod>
#include <tf2>

// Globals Vars
bool respawned[MAXPLAYERS + 1];


public Plugin myinfo =  {
	name = "Instant Antiflood Respawn", 
	author = "lugui", 
	description = "Instant respawn players and prevents them from spamming death", 
	version = "1.0", 
};

public void OnPluginStart() {
	HookEvent("player_death", Event_Player_Death);
	CreateTimer(1.0, Timer_Global, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

// resets any client variable
public OnClientPutInServer(client) 
{ 
	if (IsValidClient(client)){
		respawned[client] = false;
	}
} 

public Action Timer_Global(Handle timer)
{
	for (int i = 1; i <= MAXPLAYERS; i++) {
		if (IsValidClient(i)){
			respawned[i] = false;
		}
	}
}

public void Frame_RespawnPlayer(int client){
	TF2_RespawnPlayer(client);
}

// PLAYER DEATH 
public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int flags = (GetEventInt(event, "death_flags", 0) & 32);
	if(!flags){ // not a fake death
		if(CheckCommandAccess(client, "instant_respawn_flag", ADMFLAG_RESERVATION)){ // VIP
			if(!respawned[client]){
				RequestFrame(Frame_RespawnPlayer, client);
				respawned[client] = true;
			}
		}
	}
	return Plugin_Continue;
}

IsValidClient( client ) 
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsFakeClient(client)){
		return false; 
	}
	return true; 
}