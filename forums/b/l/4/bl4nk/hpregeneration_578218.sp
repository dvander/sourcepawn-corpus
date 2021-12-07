/**
 * HpRegeneration plugin by bl4nk
 *
 * Description:
 *   When a player gets hurt, they regenerate 'x' amount of life every 'y' seconds until they reach 'z' health.
 *
 * CVars:
 *   sm_hpregeneration_enable - Enables\Disables the HpRegeneration plugin.
 *     - 0 = off
 *     - 1 = on (default)
 *   sm_hpregeneration_amount - Amount of life to heal per regeneration tick.
 *     - 10 = 10 health per tick (default)
 *     - 25 = 25 health per tick
 *   sm_hpregeneration_maxhealth - Max health to regenerate to.
 *     - 100 = Regenerate to 100 health (default)
 *     - 150 = Regenerate to 150 health
 *   sm_hpregeneration_tickrate - Time, in seconds, between each regeneration tick.
 *     - 5 = Regenerate health every 5 seconds
 *     - 10 = Regenerate health every 10 seconds (default)
 *   sm_hpregeneration_respawn - Enables/Disables healing through respawns.
 *     - 0 = When a player respawns, their health will stop regenerating (default)
 *     - 1 = When a player respawns, their health will continue to regenerate
 *
 * Thanks to:
 *   MaTTe (mateo10) for making the original "HP Regeneration" plugin.
 *
 * Version 1.0.6
 * Changelog at http://forums.alliedmods.net/showthread.php?t=66154
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.6"

new HealthOffset;

new bool:isHooked = false;
new bool:Respawn = false;
new bool:RespawnCheck = false;

new Handle:cvarEnable;
new Handle:cvarAmount;
new Handle:cvarMaxHealth;
new Handle:cvarTickRate;
new Handle:cvarRespawn;
new Handle:clientTimer[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "HpRegeneration",
	author = "bl4nk",
	description = "After being damaged, regenerate health over time.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_hpregeneration_version", PLUGIN_VERSION, "HpRegeneration Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_hpregeneration_enable", "1", "Enables/Disables the HpRegeneration plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAmount = CreateConVar("sm_hpregeneration_amount", "10", "Amount to heal a player per regeneration tick.", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMaxHealth = CreateConVar("sm_hpregeneration_maxhealth", "100", "Max health to regenerate to.", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTickRate = CreateConVar("sm_hpregeneration_tickrate", "10", "Time, in seconds, between each regeneration tick.", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarRespawn = CreateConVar("sm_hpregeneration_respawn", "0", "Enables/Disables healing through respawns.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		HookEvent("player_hurt", event_PlayerHurt);

		LogMessage("[HpRegeneration] - Loaded");
	}

	if (GetConVarInt(cvarRespawn))
	{
		Respawn = true;
		HookEvent("player_spawn", event_PlayerSpawn);
	}

	HookConVarChange(cvarEnable, CvarChange_Enable);
	HookConVarChange(cvarRespawn, CvarChange_Respawn);
}


public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	HealthOffset = FindDataMapOffs(client, "m_iHealth");

	if (clientTimer[client] == INVALID_HANDLE)
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarTickRate), RegenTick, client, TIMER_REPEAT);

}

public Action:RegenTick(Handle:timer, any:client)
{
	new clientHp = GetPlayerHealth(client);
	if (clientHp < GetConVarInt(cvarMaxHealth))
	{
		if (clientHp + GetConVarInt(cvarAmount) > GetConVarInt(cvarMaxHealth))
		{
			SetPlayerHealth(client, GetConVarInt(cvarMaxHealth));
			KillClientTimer(client);
		}
		else
		{
			SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount));
		}
	}
	else
	{
		KillClientTimer(client);
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (clientTimer[client] != INVALID_HANDLE)
		KillClientTimer(client);
}

public CvarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarInt(cvarEnable))
	{
		if (isHooked)
		{
			isHooked = false;
			UnhookEvent("player_hurt", event_PlayerHurt);

			KillAllTimers();
			CheckRespawn();
		}
	}
	else if (!isHooked)
	{
		isHooked = true;
		HookEvent("player_hurt", event_PlayerHurt);

		CheckRespawn();
	}
}

public CvarChange_Respawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarInt(cvarRespawn))
	{
		if (Respawn && !RespawnCheck)
		{
			Respawn = false;
			UnhookEvent("player_spawn", event_PlayerSpawn);
		}
		else if (Respawn && RespawnCheck)
		{
			Respawn = false;
		}
	}
	else if (!Respawn)
	{
		if (GetConVarInt(cvarEnable))
		{
			Respawn = true;
			HookEvent("player_spawn", event_PlayerSpawn);
		}
		else
		{
			Respawn = true;
		}
	}
}

public OnClientDisconnect(client)
{
	if (clientTimer[client] != INVALID_HANDLE)
		KillClientTimer(client);
}

GetPlayerHealth(entity)
{
	return GetEntData(entity, HealthOffset);
}

SetPlayerHealth(entity, amount)
{
	SetEntData(entity, HealthOffset, amount, 4, true);
}

KillClientTimer(client)
{
	KillTimer(clientTimer[client]);
	clientTimer[client] = INVALID_HANDLE;
}

KillAllTimers()
{
	for (new i; i < MAXPLAYERS + 1; i++)
	{
		if (clientTimer[i] != INVALID_HANDLE)
		{
			KillClientTimer(i);
		}
	}
}

CheckRespawn()
{
	if (isHooked && Respawn)
	{
		HookEvent("player_spawn", event_PlayerSpawn);
		RespawnCheck = false;
	}
	else if (!isHooked && Respawn)
	{
		UnhookEvent("player_spawn", event_PlayerSpawn);
		RespawnCheck = true;
	}
}