/*
 *  0: Disable, 2: Smoker, 4: Boomer, 8: Hunter, 32: Tank, 64: Survivors, 110: All
 *  0: Disable, 2: Smoker, 4: Boomer, 8: Hunter, 32: Tank, 64: Survivors, 110: All
 *  0: Disable, 2: Smoker, 4: Boomer, 8: Hunter, 16: Spitter, 64: Charger, 256: Tank, 512: Survivors, 862: All
 *  0: Disable, 2: Smoker, 4: Boomer, 8: Hunter, 16: Spitter, 32: Jockey, 64: Charger, 256: Tank, 512: Survivors, 894: All
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.3"

ConVar g_hCvarFlags, g_hCvarImmune;
int g_iCvarFlags, g_iCvarImmune;
bool g_bLateLoad, g_bLeft4Dead2;

public Plugin myinfo =
{
	name = "[L4D/L4D2] Ladder Troll Prevention",
	author = "raziEiL [disawar1], Dosergen",
	description = "Prevents players from blocking Special Infected on ladders.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead)
		g_bLeft4Dead2 = false;
	else if (test == Engine_Left4Dead2)
		g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("ladderblock_version", PLUGIN_VERSION, "Ladder Troll Prevention plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvarFlags = CreateConVar("ladderblock_flags", g_bLeft4Dead2 ? "862" : "110", "Who can push trolls when climbs on the ladder (add together)", FCVAR_NOTIFY, true, 0.0, true, g_bLeft4Dead2 ? 862.0 : 110.0);
	g_hCvarImmune = CreateConVar("ladderblock_immune", "0", "What class is immune (add together)", FCVAR_NOTIFY, true, 0.0, true, g_bLeft4Dead2 ? 894.0 : 110.0);

	g_iCvarFlags = g_hCvarFlags.IntValue;
	g_iCvarImmune = g_hCvarImmune.IntValue;

	g_hCvarFlags.AddChangeHook(OnCvarChange_Flags);
	g_hCvarImmune.AddChangeHook(OnCvarChange_Immune);

	if (g_iCvarFlags && g_bLateLoad)
		IsToggleHook(true);

	AutoExecConfig(true, "ladderblock");
}

public void OnPluginEnd()
{
	IsToggleHook(false);
}

void OnCvarChange_Flags(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) == 0)
		return;
	g_iCvarFlags = g_hCvarFlags.IntValue;
	bool wasEnabled = !!StringToInt(oldValue);
	if (!wasEnabled && g_iCvarFlags)
		IsToggleHook(true);
	else if (wasEnabled && !g_iCvarFlags)
		IsToggleHook(false);
}

void OnCvarChange_Immune(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
		g_iCvarImmune = g_hCvarImmune.IntValue;
}

void IsToggleHook(bool enable)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		if (enable)
			SDKHook(i, SDKHook_TouchPost, IsOnTouch);
		else
			SDKUnhook(i, SDKHook_TouchPost, IsOnTouch);
	}
}

public void OnClientPutInServer(int client)
{
	if (g_iCvarFlags)
		SDKHook(client, SDKHook_TouchPost, IsOnTouch);
}

public void OnClientDisconnect(int client)
{
	if (g_iCvarFlags)
		SDKUnhook(client, SDKHook_TouchPost, IsOnTouch);
}

void IsOnTouch(int entity, int other)
{
	if (!IsGuyTroll(entity, other) || IsChargerCharging(other))
		return;
	if (L4D_GetSurvivorVictim(other) > 0)
		return;
	int PushClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
	int ImmuneClass = GetEntProp(other, Prop_Send, "m_zombieClass");
	if (!(g_iCvarFlags & (1 << PushClass)) || (g_iCvarImmune & (1 << ImmuneClass)))
		return;
	float pos1[3], pos2[3];
	if (!GetEntityOrigin(entity, pos1) || !GetEntityOrigin(other, pos2))
		return;
	float vPush[3];
	MakeVectorFromPoints(pos1, pos2, vPush);
	NormalizeVector(vPush, vPush);
	ScaleVector(vPush, 251.0);
	if (IsOnLadder(other))
	{
		pos2[2] += 2.5;
		TeleportEntity(other, pos2, NULL_VECTOR, NULL_VECTOR);
	}
	else
		TeleportEntity(other, NULL_VECTOR, NULL_VECTOR, vPush);
}

bool GetEntityOrigin(int entity, float origin[3])
{
	if (IsValidClient(entity))
	{
		GetClientAbsOrigin(entity, origin);
		return true;
	}
	else if (IsValidEntity(entity))
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		return true;
	}
	return false;
}

bool IsOnLadder(int entity)
{
	return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsChargerCharging(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 6)
		return false;
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	return IsValidEntity(ability) && GetEntProp(ability, Prop_Send, "m_isCharging");
}

bool IsGuyTroll(int victim, int troll)
{
	if (!IsValidClient(victim) || !IsValidClient(troll))
		return false;
	if (!IsOnLadder(victim) || GetClientTeam(victim) == GetEntProp(troll, Prop_Data, "m_iTeamNum"))
		return false;
	float victimZ = GetEntPropFloat(victim, Prop_Send, "m_vecOrigin[2]");
	float trollZ = GetEntPropFloat(troll, Prop_Send, "m_vecOrigin[2]");
	return victimZ < trollZ;
}

int L4D_GetSurvivorVictim(int client)
{
	int victim;
	if (g_bLeft4Dead2)
	{
		victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
		if (victim > 0)
			return victim;
		victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
		if (victim > 0)
			return victim;
		victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
		if (victim > 0)
			return victim;
	}
	victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
	if (victim > 0)
		return victim;
	victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
	if (victim > 0)
		return victim;
	return -1;
}