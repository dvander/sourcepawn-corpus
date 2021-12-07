/**
* InfiniteHealth plugin by bl4nk.
*
* Description:
*   Allows players to have infinite health, but still appear to take damage.
*   This is useful for TF2 jumping maps, but since there is a chance that this
*   plugin could be used for other multiplayer mods, I added additional support
*   for 'Counter-Strike: Source' and 'Day of Defeat: Source'.
*
* Version 1.0.0
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new HealthOffset;
new maxHealthOffset;

new Handle:cvarAmount;

new bool:isHooked = false;

enum Mod { undefined, cstrike, tf2, dod, other };
stock Mod:GameType = undefined;

public Plugin:myinfo =
{
	name = "InfiniteHealth",
	author = "bl4nk",
	description = "Allows all players to have infinite health, but still appear to take damage.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_infinitehealth_version", PLUGIN_VERSION, "InfiniteHealth Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarAmount = CreateConVar("sm_infinitehealth_enable", "1", "Enables/Disables the InfiniteHealth plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarAmount) == 1)
	{
		isHooked = true;
		HookEvent("player_hurt", event_PlayerHurt);

		LogMessage("[InfiniteHealth] - Loaded");
	}

	HookConVarChange(cvarAmount, CvarChange_Amount);
}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);

	if (victim)
	{
		HealthOffset = FindDataMapOffs(victim, "m_iHealth");
		maxHealthOffset = FindDataMapOffs(victim, "m_iMaxHealth");
			
		new maxHealth = GetPlayerMaxHealth(victim);
		if (maxHealth != -1)
		{
			SetPlayerHealth(victim, maxHealth);
		}
	}
}

public CvarChange_Amount(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(cvarAmount) != 1)
	{
		if (isHooked)
		{
			isHooked = false;
			UnhookEvent("player_hurt", event_PlayerHurt);
		}
	}
	else if (!isHooked)
	{
		isHooked = true;
		HookEvent("player_hurt", event_PlayerHurt);
	}
}

GetPlayerMaxHealth(entity)
{
	new maxHealth = -1;

	if (GameType == undefined)
	{
		new String:modName[32];
		GetGameFolderName(modName, sizeof(modName));
		
		GetGameType();
		switch(GameType)
		{
			case cstrike:
				maxHealth = 100;
			case tf2:
				maxHealth = GetEntData(entity, maxHealthOffset, 1);
			case dod:
				maxHealth = 100;
		}

	}

	return maxHealth;

}

SetPlayerHealth(entity, any:amount)
{
	SetEntData(entity, HealthOffset, amount, 4, true);
}

stock GetGameType()
{
	new String:modName[30];
	GetGameFolderName(modName, sizeof(modName));

	if (strcmp(modName, "cstrike") == 0)
		GameType = cstrike;
	else if (strcmp(modName, "tf") == 0)
		GameType = tf2;
	else if (strcmp(modName, "dod") == 0)
		GameType = dod;
	else
		GameType = other;
}