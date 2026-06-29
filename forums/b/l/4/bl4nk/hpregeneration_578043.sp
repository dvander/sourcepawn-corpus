/**
 * HpRegeneration plugin by bl4nk
 *
 * Description:
 *   When a player gets hurt, they regenerate 'x' amount of life every 'y' seconds until they reach 'z' health.
 *
 * Commands and Examples:
 *   sm_hpregeneration_enable - Enables the HpRegeneration plugin.
 *     - 0 = off
 *     - 1 = on (default)
 *   sm_hpregeneration_amount - Amount of life to heal per regeneration tick.
 *     - 10 = 10 health per tick (default)
 *     - 25 = 25 health per tick
 *   sm_hpregeneration_health - Health to regenerate to, based on the control mode.
 *     - 100 = Regenerate to 100 health (default)
 *     - 150 = Regenerate to 150 health
 *   sm_hpregeneration_tickrate - Time, in seconds, between each regeneration tick.
 *     - 5 = Regenerate health every 5 seconds
 *     - 10 = Regenerate health every 10 seconds (default)
 *   sm_hpregeneration_respawn - Enables healing through respawns.
 *     - 0 = When a player respawns, their health will stop regenerating (default)
 *     - 1 = When a player respawns, their health will continue to regenerate
 *   sm_hpregeneration_bots - Enables bots regenerating their life.
 *     - 0 = Bots do not regenerate life (default)
 *     - 1 = Bots do regenerate life
 *   sm_hpregeneration_mode - Controls the regeneration mode.
 *     - 1 = Players heal to the amount of life defined by the health cvar (default)
 *     - 2 = Players heal to their default max life plus the amount of life defined by the health cvar
 *
 * Thanks to:
 *   MaTTe (mateo10) for making the original "HP Regeneration" plugin.
 *
 * Changelog at http://forums.alliedmods.net/showthread.php?t=66154
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.1.1"

new MaxHealth[MAXPLAYERS + 1];

new bool:isHooked = false;
new bool:Respawn = false;
new bool:Mode = false;

new Handle:cvarEnable;
new Handle:cvarAmount;
new Handle:cvarHealth;
new Handle:cvarTickRate;
new Handle:cvarRespawn;
new Handle:cvarBot;
new Handle:cvarMode;
new Handle:clientTimer[MAXPLAYERS + 1];

new String:modName[32];

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
	cvarEnable = CreateConVar("sm_hpregeneration_enable", "1", "Enables the HpRegeneration plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAmount = CreateConVar("sm_hpregeneration_amount", "10", "Amount of life to heal per regeneration tick (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHealth = CreateConVar("sm_hpregeneration_health", "100", "Health to regenerate to, based on the control mode (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarTickRate = CreateConVar("sm_hpregeneration_tickrate", "10", "Time, in seconds, between each regeneration tick (Def 10)", FCVAR_PLUGIN, true, 1.0, false, _);
	cvarRespawn = CreateConVar("sm_hpregeneration_respawn", "0", "Enables healing through respawns.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBot = CreateConVar("sm_hpregeneration_bots", "0", "Enables bots regenerating their life.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarMode = CreateConVar("sm_hpregeneration_mode", "1", "Controls the regeneration mode (Def 1)", FCVAR_PLUGIN, true, 1.0, true, 2.0);

	AutoExecConfig(true, "plugin.hpregeneration");
	CreateTimer(3.0, OnPluginStart_Delayed);
	GetGameFolderName(modName, sizeof(modName));
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		LogMessage("[HpRegeneration] - Loaded");
	}

	if (GetConVarInt(cvarRespawn))
		Respawn = true;

	if (GetConVarInt(cvarMode) == 1)
		Mode = true;

	HookEvent("player_hurt", event_PlayerHurt);
	HookEvent("player_spawn", event_PlayerSpawn);

	HookConVarChange(cvarEnable, CvarChange);
	HookConVarChange(cvarRespawn, CvarChange);
	HookConVarChange(cvarMode, CvarChange);
	HookConVarChange(cvarTickRate, CvarChange);
}


public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isHooked)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsFakeClient(client) && !GetConVarInt(cvarBot))
			return;

		if (clientTimer[client] == INVALID_HANDLE)
			clientTimer[client] = CreateTimer(GetConVarFloat(cvarTickRate), RegenTick, client, TIMER_REPEAT);
	}
}

public Action:RegenTick(Handle:timer, any:client)
{
	new clientHp = GetPlayerHealth(client);

	if (Mode)
	{
		if (clientHp < GetConVarInt(cvarHealth))
		{
			if (clientHp + GetConVarInt(cvarAmount) > GetConVarInt(cvarHealth))
			{
				if (strcmp(modName, "tf") == 0)
					if (clientHp + GetConVarInt(cvarAmount) > MaxHealth[client])
						SetPlayerHealth(client, GetConVarInt(cvarHealth), true);
					else
						SetPlayerHealth(client, GetConVarInt(cvarHealth), true, true);
				else
					SetPlayerHealth(client, GetConVarInt(cvarHealth));

				KillClientTimer(client);
			}
			else
			{
				if (strcmp(modName, "tf") == 0)
					if (clientHp + GetConVarInt(cvarAmount) > MaxHealth[client])
						SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount), true);
					else
						SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount), true, true);
				else
					SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount));
			}
		}
		else
			KillClientTimer(client);
	}
	else
	{
		if (clientHp < MaxHealth[client] + GetConVarInt(cvarHealth))
		{
			if (clientHp + GetConVarInt(cvarAmount) > MaxHealth[client] + GetConVarInt(cvarHealth))
			{
				if (strcmp(modName, "tf") == 0)
					SetPlayerHealth(client, MaxHealth[client] + GetConVarInt(cvarHealth), true);
				else
					SetPlayerHealth(client, MaxHealth[client] + GetConVarInt(cvarHealth));

				KillClientTimer(client);
			}
			else if (strcmp(modName, "tf") == 0)
				if (clientHp + GetConVarInt(cvarAmount) > MaxHealth[client])
					SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount), true);
				else
					SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount), true, true);
			else
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarAmount));
		}
		else
			KillClientTimer(client);
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
		CreateTimer(0.0, getMaxHealth, client);

	if (!Respawn)
	{
		if (clientTimer[client] != INVALID_HANDLE)
			KillClientTimer(client);
	}
}

public Action:getMaxHealth(Handle:timer, any:client)
	MaxHealth[client] = GetPlayerHealth(client, true);

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarEnable)
	{
		if (!GetConVarInt(cvarEnable))
		{
			if (isHooked)
			{
				isHooked = false;
				KillClientTimer(_, true);
				LogMessage("[HpRegeneration] - Plugin disabled.");
			}
		}
		else if (!isHooked)
		{
			isHooked = true;
			LogMessage("[HpRegeneration] - Plugin enabled.");
		}
	}
	else if (convar == cvarRespawn)
	{
		if (!GetConVarInt(cvarRespawn))
		{
			if (Respawn)
			{
				Respawn = false;
				LogMessage("[HpRegeneration] - Regeneration through respawn disabled.");
			}
		}
		else if (!Respawn)
		{
			Respawn = true;
			LogMessage("[HpRegeneration] - Regeneration through respawn enabled.");
		}
	}
	else if (convar == cvarMode)
	{
		if (GetConVarInt(cvarMode) == 2)
		{
			if (Mode)
			{
				Mode = false;
				LogMessage("[HpRegeneration] - Regeneration mode changed to 2.");
			}
		}
		else if (!Mode)
		{
			Mode = true;
			LogMessage("[HpRegeneration] - Regeneration mode changed to 1.");
		}
	}
	else if (convar == cvarTickRate)
		ChangeTickRate();
}

public OnClientDisconnect(client)
	if (clientTimer[client] != INVALID_HANDLE)
		KillClientTimer(client);

public OnMapEnd()
	KillClientTimer(_, true);

GetPlayerHealth(entity, bool:maxHealth=false)
{
	if (maxHealth)
	{
		if (strcmp(modName, "tf") == 0)
			return GetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"));
		else
			return 100;
	}
	return GetEntData(entity, FindDataMapOffs(entity, "m_iHealth"));
}

SetPlayerHealth(entity, amount, bool:maxHealth=false, bool:ResetMax=false)
{
	if (maxHealth)
		if (ResetMax)
			SetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"), MaxHealth[entity], 4, true);
		else
			SetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"), amount, 4, true);

	SetEntityHealth(entity, amount);
}

KillClientTimer(client=0, bool:all=false)
{
	if (all)
	{
		for (new i; i <= MAXPLAYERS; i++)
		{
			if (clientTimer[i] != INVALID_HANDLE)
			{
				KillTimer(clientTimer[client]);
				clientTimer[client] = INVALID_HANDLE;
			}
		}
		return;
	}

	KillTimer(clientTimer[client]);
	clientTimer[client] = INVALID_HANDLE;
}

ChangeTickRate()
{
	for (new i; i <= MAXPLAYERS; i++)
	{
		if (clientTimer[i] != INVALID_HANDLE)
		{
			KillClientTimer(i);
			clientTimer[i] = CreateTimer(GetConVarFloat(cvarTickRate), RegenTick, i, TIMER_REPEAT);
		}
	}
}