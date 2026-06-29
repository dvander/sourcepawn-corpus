#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5.2"

public Plugin:myinfo = 
{
	name = "DoD SpawnProtect Source", 
	author = "FeuerSturm, playboycyberclub", 
	description = "Prevent SpawnKilling", 
	version = PLUGIN_VERSION, 
	url = "http://www.dodsplugins.net"
}

#define ALLIES	2
#define AXIS	3

new Handle:SpawnProtectOn = INVALID_HANDLE
new Handle:SpawnProtectTimeAxis = INVALID_HANDLE
new Handle:SpawnProtectTimeAllies = INVALID_HANDLE
new Handle:SpawnProtectMsg = INVALID_HANDLE
new Handle:SpawnProtectTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new bool:IsProtected[MAXPLAYERS + 1] = { false, ... };

public OnPluginStart()
{
	SpawnProtectOn = CreateConVar("dod_spawnprotect_source", "1", "<1/0> = enable/disable protecting players after spawning")
	SpawnProtectTimeAllies = CreateConVar("dod_spawnprotect_timeallies", "5", "<#> = time in seconds to prevent allied players from taking damage after spawning")
	SpawnProtectTimeAxis = CreateConVar("dod_spawnprotect_timeaxis", "5", "<#> = time in seconds to prevent axis players from taking damage after spawning")
	SpawnProtectMsg = CreateConVar("dod_spawnprotect_message", "1", "<1/0> = enable/disable displaying SpawnProtection messages")
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	HookEventEx("dod_stats_weapon_attack", OnWeaponAttack, EventHookMode_Post)
	AutoExecConfig(true, "dod_spawnprotect_source", "dod_spawnprotect_source")
	LoadTranslations("dod_spawnprotect_source.phrases")
}

public OnClientPostAdminCheck(client)
{
	IsProtected[client] = false
}

public OnClientDisconnect(client)
{
	KillSpawnProtTimer(client)
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (GetConVarInt(SpawnProtectOn) == 1 && IsPlayerValid(client))
	{
		KillSpawnProtTimer(client)
		IsProtected[client] = true
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
		if (GetConVarInt(SpawnProtectMsg) == 1)
		{
			CreateTimer(0.1, DisplayMsgOn, client, TIMER_FLAG_NO_MAPCHANGE)
		}
		new team = GetClientTeam(client)
		if (team == ALLIES)
		{
			SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTimeAllies), SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)
		}
		else if (team == AXIS)
		{
			SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTimeAxis), SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)
		}
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action:OnWeaponAttack(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"))
	new weapon = GetEventInt(event, "weapon")
	if (GetConVarInt(SpawnProtectOn) == 1 && IsPlayerValid(client) && weapon > 0 && IsProtected[client] == true)
	{
		KillSpawnProtTimer(client)
		CreateTimer(0.1, SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	return Plugin_Continue
}

public Action:DisplayMsgOn(Handle:timer, any:client)
{
	if (IsPlayerValid(client))
	{
		PrintToChat(client, "\x04[SpawnProtect]\x01 %t", "ProtectionOn")
	}
	return Plugin_Handled
}

public Action:SpawnProtectOff(Handle:timer, any:client)
{
	SpawnProtectTimer[client] = INVALID_HANDLE
	if (IsPlayerValid(client))
	{
		IsProtected[client] = false
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		if (GetConVarInt(SpawnProtectMsg) == 1)
		{
			PrintToChat(client, "\x04[SpawnProtect] \x01 %t", "ProtectionOff")
		}
		return Plugin_Handled
	}
	return Plugin_Handled
}

KillSpawnProtTimer(client)
{
	IsProtected[client] = false
	if (SpawnProtectTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(SpawnProtectTimer[client])
	}
	SpawnProtectTimer[client] = INVALID_HANDLE
}

bool:IsPlayerValid(client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		return true
	}
	return false
} 