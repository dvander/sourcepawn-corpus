#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo = {
	name = "Respawn On Death Place",
	author = "The Count",
	description = "",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new Float:deathPoint[MAXPLAYERS + 1][3];

public OnPluginStart(){
	CreateConVar("mp_respawn_on_death_t", "0", "Sets respawn at death point.", _, true, 0.0, true, 1.0);
	CreateConVar("mp_respawn_on_death_ct", "0", "Sets respawn at death point.", _, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", Evt_Spawn, EventHookMode_Pre);
	HookEvent("player_death", Evt_Death, EventHookMode_Pre);
}

public OnClientPutInServer(client){
	deathPoint[client][0] = 0.0;
	deathPoint[client][1] = 0.0;
	deathPoint[client][2] = 0.0;
}

public Action:Evt_Death(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client >= 1 && client <= MaxClients){
		if(getVal(GetClientTeam(client))){
			new Float:absOri[3];
			GetClientAbsOrigin(client, absOri);
			deathPoint[client] = absOri;
		}
	}
	return Plugin_Continue;
}

public Action:Evt_Spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client >= 1 && client <= MaxClients){
		if(getVal(GetClientTeam(client))){
			if(deathPoint[client][0] == 0.0){
				return Plugin_Continue;
			}
			TeleportEntity(client, deathPoint[client], NULL_VECTOR, NULL_VECTOR);
		}
	}
	return Plugin_Continue;
}

stock bool:getVal(any:team){
	new Handle:canvor = INVALID_HANDLE;
	if(team == 2){//Terrorists
		canvor = FindConVar("mp_respawn_on_death_t");
		if(GetConVarInt(canvor) == 1){
			return true;
		}else{
			return false;
		}
	}
	if(team == 3){//Counter-Terrorists
		canvor = FindConVar("mp_respawn_on_death_ct");
		if(GetConVarInt(canvor) == 1){
			return true;
		}else{
			return false;
		}
	}
	return false;
}