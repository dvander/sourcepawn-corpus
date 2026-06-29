#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new bool:IsRoundEnd = false;
new bool:IsInSpawn[MAXPLAYERS+1] = false;

new Float:g_fDamageInSpawn = 0.25;
new Float:g_fDamageOutsideSpawn = 0.50;
new Handle:v_DamageInSpawn = INVALID_HANDLE;
new Handle:v_DamageOutsideSpawn = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Smarter Spawns",
	author = "DarthNinja",
	description = "Damage controls for players in spawn rooms",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("smarter_spawns", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);	// Lateload support
	}
	
	//If we load after the map has started, the OnEntityCreated check wont be called
	new iSpawn = -1;
	while ((iSpawn = FindEntityByClassname(iSpawn, "func_respawnroom")) != -1)
	{
		// If plugin is loaded early, these won't be called because the func_respawnroom wont exist yet
		SDKHook(iSpawn, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(iSpawn, SDKHook_EndTouch, SpawnEndTouch);
	}
	
	//RegAdminCmd("smarter_spawns_debug", Test, 0);
	
	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_round_active", OnRoundStart);
	//HookEvent("arena_round_start", OnRoundStart);	This plugin really doesn't need to do anything in arena since arena maps have no spawn rooms so to speak

	v_DamageInSpawn = CreateConVar("smarter_spawns_damage_inspawn", "0.25", "Damage will be multiplied by this value for players inside spawn being attacked by players outside of spawn", 0, true, 0.0, true, 2.0);
	v_DamageOutsideSpawn = CreateConVar("smarter_spawns_damage_outsidespawn", "0.50", "Damage will be multiplied by this value for players outside of spawn being attacked by players inside spawn", 0, true, 0.0, true, 2.0);

	HookConVarChange(v_DamageInSpawn, OnConVarChanged);
	HookConVarChange(v_DamageOutsideSpawn, OnConVarChanged);
}

/*
public Action:Test(client, args)
{
	if (IsInSpawn[client])
		PrintToChatAll("%N is in the spawn", client);
	else
		PrintToChatAll("%N isnt in the spawn", client);
}
*/

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == v_DamageInSpawn)
		g_fDamageInSpawn = StringToFloat(newVal);
	else //if (cvar == v_DamageOutsideSpawn)
		g_fDamageOutsideSpawn = StringToFloat(newVal);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsRoundEnd)
		return Plugin_Continue;	// End up the round, so we dont care

	if (victim > MaxClients || victim < 1 || attacker > MaxClients || attacker < 1)
		return Plugin_Continue;	// That ain't valid for our array.

	if (IsInSpawn[victim] && !IsInSpawn[attacker])	// Someone is shooting into the spawn room.
	{
		if (g_fDamageInSpawn == 0.0)
			damage = 0.0;
		else
			damage = damage * g_fDamageInSpawn;	// Reduce the damage done to players in the spawn
		return Plugin_Changed;
	}

	if (!IsInSpawn[victim] && IsInSpawn[attacker])	// Someone is shooting *out of* the spawn room.
	{
		if (g_fDamageOutsideSpawn == 0.0)
			damage = 0.0;
		else
		damage = damage * g_fDamageOutsideSpawn;	// Reduce the damage done to players outside the spawn.... but maybe not as much.
		return Plugin_Changed;
	}

	// Any other combo we'll ignore for now (like outsider attacking outsider, player in spawn attacking a player in the spawn - not really possible)
	return Plugin_Continue;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsRoundEnd = false;
}
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsRoundEnd = true;
}

public Action:OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IsInSpawn[client] = true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "func_respawnroom", false))	// This is the earliest we can catch this
	{
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public SpawnStartTouch(spawn, client)
{
	// Make sure it is a client and not something random
	if (client > MaxClients || client < 1)
		return;	// Not a client

	if (IsClientConnected(client) && IsClientInGame(client))
		IsInSpawn[client] = true;
}

public SpawnEndTouch(spawn, client)
{
	if (client > MaxClients || client < 1)
		return;

	if (IsClientConnected(client) && IsClientInGame(client))
		IsInSpawn[client] = false;
}

public OnClientDisconnect(client)
{
	IsInSpawn[client] = false;
}
