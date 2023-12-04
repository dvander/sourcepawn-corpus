#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar sm_playermodel;

public Plugin:myinfo = {
	name        = "Set PlayerModel",
	author      = "ZMatu",
	description = "Cambia de modelo a uno personalizado sin errores + cfg",
	version     = "1.1",
	url         = "https://github.com/ZMatu"
};
	
public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	sm_playermodel = CreateConVar("sm_playermodel", "models/si/ejemplo.mdl", "Ubicación de tu modelo");
	AutoExecConfig(true, "setmodel_zmatu");
	
    char model_cache[PLATFORM_MAX_PATH];
    GetConVarString(sm_playermodel, model_cache, sizeof(model_cache));
    PrecacheModel(model_cache, true);
}

public Action Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{    
	char model_v3[PLATFORM_MAX_PATH];
    GetConVarString(sm_playermodel, model_v3, sizeof(model_v3));
    
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsPlayerAlive(client))
	{
		SetEntityModel(client, model_v3); 
	}
	return Plugin_Handled;
}