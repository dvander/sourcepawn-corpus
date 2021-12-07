#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.8"

#define cGreen 0x04
#define cDefault 0x01

new spawned[MAXPLAYERS + 1];

new bool:isHooked = false;
new bool:Announce = false;

new Handle:cvarEnable;
new Handle:cvarAnnounce;
new Handle:cvarLife;

new String:gameFolder[32];

public Plugin:myinfo =
{
	name = "KnifeSyphon",
	author = "bl4nk",
	description = "Gives players a health boost when they make a knife kill.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("knifesyphon.phrases");

	CreateConVar("sm_knifesyphon_version", PLUGIN_VERSION, "KnifeSyphon Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_knifesyphon_enable", "1", "Enables/Disables the KnifeSyphon plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAnnounce = CreateConVar("sm_knifesyphon_announce", "1", "Enables/Disables the KnifeSyphon announcement at the beginning of the round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarLife = CreateConVar("sm_knifesyphon_life", "25", "Sets the amount of health to give to a player after they kill someone with a knife.", FCVAR_PLUGIN, true, 0.0, true, 100.0);

	GetGameFolderName(gameFolder, sizeof(gameFolder));
	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		HookEvent("player_death", event_PlayerDeath);
		HookEvent("player_spawn", event_PlayerSpawn);

		LogMessage("[KnifeSyphon] - Loaded");
	}

	if (GetConVarInt(cvarAnnounce))
	{
		Announce = true;
	}

	HookConVarChange(cvarEnable, CvarChange_Enable);
	HookConVarChange(cvarAnnounce, CvarChange_Announce);
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weaponName[12];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));

	if (WeaponCheck(weaponName))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (victim && attacker)
		{
			if (GetClientTeam(victim) != GetClientTeam(attacker))
			{
				new AddToHealth = GetConVarInt(cvarLife);
				new attackerHealth = GetPlayerHealth(attacker) + AddToHealth;
				SetPlayerHealth(attacker, attackerHealth);

				decl String:victimName[32];
				GetClientName(victim, victimName, sizeof(victimName));

				PrintToChat(attacker, "%c[KS]%c %t", cGreen, cDefault, "Life Syphoned", AddToHealth, victimName);
			}
		}
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerId = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!playerId || !GetClientTeam(playerId))
	{
		return;
	}

	if (!spawned[playerId])
	{
		spawned[playerId] = true;

		new AddToHealth = GetConVarInt(cvarLife);
		PrintToChat(playerId,"%c[KS]%c %t", cGreen, cDefault, "Announce", AddToHealth);
	}
}

public CvarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarInt(cvarEnable))
	{
		if (isHooked)
		{
			isHooked = false;
			UnhookEvent("player_death", event_PlayerDeath);
			UnhookEvent("player_spawn", event_PlayerSpawn);
		}
	}
	else if (!isHooked)
	{
		isHooked = true;
		HookEvent("player_death", event_PlayerDeath);
		HookEvent("player_spawn", event_PlayerSpawn);
	}
}

public CvarChange_Announce(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarInt(cvarAnnounce))
	{
		if (Announce)
		{
			Announce = false;
			UnhookEvent("player_spawn", event_PlayerSpawn);
		}
	}
	else if (!Announce)
	{
		if (GetConVarInt(cvarEnable))
		{
			Announce = true;
			HookEvent("player_spawn", event_PlayerSpawn);
		}
	}
}

GetPlayerHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

SetPlayerHealth(entity, amount)
{
	SetEntProp(entity, Prop_Send, "m_iHealth", amount);
}

WeaponCheck(const String:weapon[])
{
	if (strcmp(gameFolder, "cstrike") == 0) // Counter-Strike: Source
	{
		if(strcmp(weapon, "knife") == 0)
		{
			return 1;
		}
	}
	else if (strcmp(gameFolder, "dod") == 0) // Day of Defeat: Source
	{
		if(strcmp(weapon, "spade") == 0 || strcmp(weapon, "amerknife") == 0 || strcmp(weapon, "punch") == 0)
		{
			return 1;
		}
	}
	else if (strcmp(gameFolder, "hl2mp") == 0) // Half-Life 2: Deathmatch
	{
		if(strcmp(weapon, "stunstick") == 0 || strcmp(weapon, "crowbar") == 0)
		{
			return 1;
		}
	}
	else if (strcmp(gameFolder, "tf") == 0) // Team Fortress 2
	{
		if(strcmp(weapon, "bat") == 0 || strcmp(weapon, "bonesaw") == 0 || strcmp(weapon, "bottle") == 0 || strcmp(weapon, "fireaxe") == 0 || strcmp(weapon, "fists") == 0 || strcmp(weapon, "shovel") == 0 || strcmp(weapon, "wrench") == 0 || strcmp(weapon, "club") == 0 || strcmp(weapon, "axtinguisher") == 0 || strcmp(weapon, "bat_wood") == 0 || strcmp(weapon, "gloves") == 0 || strcmp(weapon, "ubersaw") == 0)
		{
			return 1;
		}
	}

	return 0;
}