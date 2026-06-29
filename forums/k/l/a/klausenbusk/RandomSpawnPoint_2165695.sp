#include <sourcemod>
#include <sdktools>
#define PLUGIN_NAME "[CSS] Random SpawnPoint"
#define PLUGIN_VERSION "1.0.0"
#pragma semicolon 1

new Handle:Spawn;
new bool:LateLoad = false;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "KK",
	description = "Random select spawnpoint!",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/i_like_denmark/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	LateLoad = late;
	return APLRes_Success;
}

public OnPluginStart() 
{
	CreateConVar("sm_randomspawnpoint_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	Spawn = CreateArray(1);
	if (LateLoad)
	{
		Event_RoundStart(INVALID_HANDLE, "round_start", false);
	}

}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearArray(Spawn);
	new entity;
	while ((entity = FindEntityByClassname(entity, "info_player_terrorist")) != -1) 
	{
		PushArrayCell(Spawn, EntIndexToEntRef(entity));
	}

	while ((entity = FindEntityByClassname(entity, "info_player_counterterrorist")) != -1) 
	{
		PushArrayCell(Spawn, EntIndexToEntRef(entity));
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client != 0 && 0 < GetArraySize(Spawn))
	{
		new index = GetRandomInt(0, GetArraySize(Spawn)-1);
		new ref = GetArrayCell(Spawn, index, 0);
		if (ref != INVALID_ENT_REFERENCE)
		{
			decl Float:Pos[3], Float:Ang[3];
			GetEntPropVector(ref, Prop_Send, "m_vecOrigin", Pos);
			GetEntPropVector(ref, Prop_Send, "m_angRotation", Ang);
			TeleportEntity(client, Pos, Ang, NULL_VECTOR);
		}
	}
}

