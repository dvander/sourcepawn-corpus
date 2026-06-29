#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME			    "l4d2_spitter_elevator_nodmg"
#define PLUGIN_VERSION 			"1.00 2026-05-25"
#define GAMEDATA_FILE           PLUGIN_NAME
#define CONFIG_FILENAME         PLUGIN_NAME

public Plugin myinfo =
{
	name = "[L4D2] Spitter Elevator No Damage",
	author = "gvazdas",
	description = "Prevent spitter goo from damaging players on elevators.",
	version = PLUGIN_VERSION,
	url = "https://github.com/gvazdas/l4d2_zombie_master"
}

public Action L4D2_CInsectSwarm_CanHarm(int acid, int spitter, int entity)
{
    if (!IsValidClient(entity)) return Plugin_Continue;
    int groundEntity = GetEntPropEnt(entity, Prop_Send, "m_hGroundEntity");
    if (groundEntity == 0 || !IsValidEntity(groundEntity) || groundEntity == INVALID_ENT_REFERENCE) return Plugin_Continue;
    static char class[16];
    GetEntityClassname(groundEntity,class,sizeof(class));
    if (strncmp(class,"func_elevator",13,false)==0) return Plugin_Handled;
    if (!HasEntProp(groundEntity,Prop_Send,"m_hGroundEntity")) return Plugin_Continue;
    groundEntity = GetEntPropEnt(groundEntity, Prop_Send, "m_hGroundEntity");
    if (groundEntity == 0 || !IsValidEntity(groundEntity) || groundEntity == INVALID_ENT_REFERENCE) return Plugin_Continue;
    GetEntityClassname(groundEntity,class,sizeof(class));
    if (strncmp(class,"func_elevator",13,false)==0) return Plugin_Handled;
    return Plugin_Continue;
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client<1 || client>MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}