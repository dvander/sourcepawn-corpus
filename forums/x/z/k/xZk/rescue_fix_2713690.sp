#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

//#define DEBUG


public void OnPluginStart()
{
	//HookEvent("finale_vehicle_ready", Event_FinaleVehicleReady);
	HookEvent("finale_win", Event_FinaleWin);
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	FixRescueSurvivors();
}

void FixRescueSurvivors(){
	
	float pos[3];
	int entity = FindEntityByClassname(MaxClients+1, "info_survivor_position");
	if(IsValidEnt(entity)){
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		//PrintToChatAll("posrecue?: %f, %f, %f ",pos[0],pos[1],pos[2]);
	}
	
	for(int i = 1; i <= MaxClients; i++){
		if(IsValidSurvivor(i) && IsPlayerAlive(i) && !IsPlayerIncapped(i)){
			//int entity = CreateEntityByName("info_survivor_position");
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
			//PrintToChatAll("save %N ?", i);
		}
	}
	
}

stock bool IsPlayerHanding(int client){
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1);
}

stock bool IsPlayerIncapped(int client){
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

stock bool IsValidSpect(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 1 );
}

stock bool IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidInfected(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 3 );
}

stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

stock bool IsValidEnt(int entity){
	return (entity > MaxClients && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}