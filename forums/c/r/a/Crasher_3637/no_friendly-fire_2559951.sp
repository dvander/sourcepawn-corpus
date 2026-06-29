#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <left4dhooks>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define NFF_VERSION "8.0"

public Plugin myinfo =
{
	name = "No Friendly-fire",
	author = "Psykotik (Crasher_3637)",
	description = "Disables friendly fire.",
	version = NFF_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302822"
};

bool g_bLateLoad, g_bLeft4Dead2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine == Engine_Left4Dead)
	{
		g_bLeft4Dead2 = false;
	}
	else if (evEngine == Engine_Left4Dead2)
	{
		g_bLeft4Dead2 = true;
	}
	else if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "No Friendly-fire only supports Left 4 Dead 1 & 2.");

		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

#define MODEL_FIREWORK "models/props_junk/explosive_box001.mdl"
#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"
#define MODEL_OXYGEN "models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE "models/props_junk/propanecanister001a.mdl"

bool g_bLeft4DHooks, g_bMapStarted;

ConVar g_cvNFFBlockExplosions, g_cvNFFBlockFires, g_cvNFFBlockGuns, g_cvNFFBlockMelee, g_cvNFFDisabledGameModes, g_cvNFFEnable, g_cvNFFEnabledGameModes, g_cvNFFGameModeTypes, g_cvNFFInfected, g_cvNFFMPGameMode, g_cvNFFSaferoomOnly, g_cvNFFSurvivors;

int g_iCurrentMode, g_iTeamID[2048], g_iUserID[MAXPLAYERS + 1];

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "left4dhooks", false))
	{
		g_bLeft4DHooks = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "left4dhooks", false))
	{
		g_bLeft4DHooks = false;
	}
}

public void OnAllPluginsLoaded()
{
	g_bLeft4DHooks = LibraryExists("left4dhooks");
}

public void OnPluginStart()
{
	g_cvNFFBlockExplosions = CreateConVar("nff_blockexplosions", "1", "Block explosive damage?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFBlockFires = CreateConVar("nff_blockfires", "1", "Block fire damage?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFBlockGuns = CreateConVar("nff_blockguns", "1", "Block bullet damage?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFBlockMelee = CreateConVar("nff_blockmelee", "1", "Block melee damage?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFDisabledGameModes = CreateConVar("nff_disabledgamemodes", "", "Disable the No Friendly-Fire in these game modes.\nGame mode limit: 16\nCharacter limit for each game mode: 32\nEmpty: None\nNot empty: Disabled in these game modes.");
	g_cvNFFEnable = CreateConVar("nff_enable", "1", "Enable the plugin?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFEnabledGameModes = CreateConVar("nff_enabledgamemodes", "", "Enable the No Friendly-Fire in these game modes.\nGame mode limit: 16\nCharacter limit for each game mode: 32\nEmpty: None\nNot empty: Enabled in these game modes.");
	g_cvNFFGameModeTypes = CreateConVar("nff_gamemodetypes", "0", "Enable the No Friendly-Fire in these game mode types.\n0 OR 15: ALL\n1: Co-op\n2: Versus\n3: Survival\n4: Scavenge", _, true, 0.0, true, 15.0);
	g_cvNFFInfected = CreateConVar("nff_infected", "1", "Disable Infected team friendly-fire?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFMPGameMode = FindConVar("mp_gamemode");
	g_cvNFFSaferoomOnly = CreateConVar("nff_saferoomonly", "0", "Only block friendly-fire when all survivors are still inside the saferoom.\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvNFFSurvivors = CreateConVar("nff_survivors", "1", "Disable Survivors team friendly-fire?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	CreateConVar("nff_pluginversion", NFF_VERSION, "No Friendly Fire version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	AutoExecConfig(true, "no_friendly-fire");

	if (g_bLateLoad)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (IsClientInGame(iPlayer))
			{
				OnClientPutInServer(iPlayer);
			}
		}

		char sModel[64];
		int iProp = -1;
		while ((iProp = FindEntityByClassname(iProp, "prop_physics") != INVALID_ENT_REFERENCE))
		{
			GetEntPropString(iProp, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			if (StrEqual(sModel, MODEL_OXYGEN) || StrEqual(sModel, MODEL_PROPANE) || StrEqual(sModel, MODEL_GASCAN) || (g_bLeft4Dead2 && StrEqual(sModel, MODEL_FIREWORK)))
			{
				SDKHook(iProp, SDKHook_OnTakeDamage, OnTakePropDamage);
			}
		}

		g_bLateLoad = false;
	}
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnClientPutInServer(int client)
{
	g_iUserID[client] = GetClientUserId(client);

	SDKHook(client, SDKHook_OnTakeDamage, OnTakePlayerDamage);
}

public void OnMapEnded()
{
	g_bMapStarted = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (MaxClients < entity <= 2048)
	{
		g_iTeamID[entity] = 0;

		if (StrEqual(classname, "inferno") || StrEqual(classname, "pipe_bomb_projectile") || (g_bLeft4Dead2 && (StrEqual(classname, "fire_cracker_blast") || StrEqual(classname, "grenade_launcher_projectile"))))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
		}
		else if (StrEqual(classname, "physics_prop") || StrEqual(classname, "prop_physics"))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnSpawnProp);
		}
		else if (StrEqual(classname, "prop_fuel_barrel"))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakePropDamage);
		}
	}
}

static void OnSpawn(int entity)
{
	int iAttacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (bIsValidClient(iAttacker))
	{
		g_iTeamID[entity] = GetClientTeam(iAttacker);
	}
}

static void OnSpawnProp(int entity)
{
	static char sModel[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if (StrEqual(sModel, MODEL_OXYGEN) || StrEqual(sModel, MODEL_PROPANE) || StrEqual(sModel, MODEL_GASCAN) || (g_bLeft4Dead2 && StrEqual(sModel, MODEL_FIREWORK)))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakePropDamage);
	}
}

public Action OnTakePropDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_cvNFFEnable.BoolValue || !bIsPluginEnabled() || (g_bLeft4DHooks && g_cvNFFSaferoomOnly.BoolValue && L4D_HasAnySurvivorLeftSafeArea()))
	{
		return Plugin_Continue;
	}
	else if (g_cvNFFSurvivors.BoolValue && inflictor > MaxClients && attacker == inflictor && g_iTeamID[inflictor] == 2)
	{
		attacker = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
		if (bIsDamageTypeBlocked(inflictor, damagetype) && (attacker == -1 || (0 < attacker <= MaxClients && (!IsClientInGame(attacker) || GetClientUserId(attacker) != g_iUserID[attacker]))))
		{
			return Plugin_Handled;
		}
	}
	else if (g_cvNFFSurvivors.BoolValue && 0 < attacker <= MaxClients)
	{
		if (bIsDamageTypeBlocked(inflictor, damagetype) && g_iTeamID[inflictor] == 2 && (!IsClientInGame(attacker) || GetClientUserId(attacker) != g_iUserID[attacker] || GetClientTeam(attacker) != 2))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action OnTakePlayerDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_cvNFFEnable.BoolValue || !bIsPluginEnabled() || (g_bLeft4DHooks && g_cvNFFSaferoomOnly.BoolValue && L4D_HasAnySurvivorLeftSafeArea()))
	{
		return Plugin_Continue;
	}
	else if (bIsValidClient(victim) && bIsValidClient(attacker) && GetClientTeam(victim) == GetClientTeam(attacker))
	{
		if (bIsDamageTypeBlocked(inflictor, damagetype) && (g_cvNFFSurvivors.BoolValue && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2) || (g_cvNFFInfected.BoolValue && GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 3))
		{
			return Plugin_Handled;
		}
	}
	else if (g_cvNFFSurvivors.BoolValue && 0 < attacker <= MaxClients && inflictor > MaxClients && g_iTeamID[inflictor] == 2)
	{
		if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) != 2)
		{
			char sClassname[5];
			GetEntityClassname(inflictor, sClassname, sizeof(sClassname));
			if (StrEqual(sClassname, "pipe") && damagetype == 134217792 && bIsDamageTypeBlocked(inflictor, damagetype))
			{
				return Plugin_Handled;
			}
			else if (bIsDamageTypeBlocked(inflictor, damagetype))
			{
				return Plugin_Handled;
			}
		}
	}
	else if (g_cvNFFSurvivors.BoolValue && attacker == inflictor && inflictor > MaxClients && g_iTeamID[inflictor] == 2 && GetClientTeam(victim) == 2)
	{
		char sClassname[5];
		GetEntityClassname(inflictor, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "pipe") && damagetype == 134217792 && bIsDamageTypeBlocked(inflictor, damagetype))
		{
			return Plugin_Handled;
		}
		else
		{
			attacker = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
			if (bIsDamageTypeBlocked(inflictor, damagetype) && (attacker == -1 || (0 < attacker <= MaxClients && (!IsClientInGame(attacker) || GetClientUserId(attacker) != g_iUserID[attacker]))))
			{
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public void vGameMode(const char[] output, int caller, int activator, float delay)
{
	if (StrEqual(output, "OnCoop"))
	{
		g_iCurrentMode = 1;
	}
	else if (StrEqual(output, "OnVersus"))
	{
		g_iCurrentMode = 2;
	}
	else if (StrEqual(output, "OnSurvival"))
	{
		g_iCurrentMode = 4;
	}
	else if (StrEqual(output, "OnScavenge"))
	{
		g_iCurrentMode = 8;
	}
}

static bool bIsDamageTypeBlocked(int entity, int damagetype = 0)
{
	static char sModel[64];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if ((!g_cvNFFBlockExplosions.BoolValue && (StrEqual(sModel, MODEL_OXYGEN) || StrEqual(sModel, MODEL_PROPANE))) || (!g_cvNFFBlockFires.BoolValue && (StrEqual(sModel, MODEL_GASCAN) || (g_bLeft4Dead2 && StrEqual(sModel, MODEL_FIREWORK)))))
	{
		return false;
	}

	if ((!g_cvNFFBlockExplosions.BoolValue && ((damagetype & DMG_BLAST) || (damagetype & DMG_BLAST_SURFACE) || (damagetype & DMG_AIRBOAT) || (damagetype & DMG_PLASMA)))
		|| (!g_cvNFFBlockFires.BoolValue && (damagetype & DMG_BURN)) || (!g_cvNFFBlockGuns.BoolValue && (damagetype & DMG_BULLET))
		|| (!g_cvNFFBlockMelee.BoolValue && ((damagetype & DMG_SLASH) || (damagetype & DMG_CLUB))))
	{
		return false;
	}

	return true;
}

static bool bIsPluginEnabled()
{
	if (g_cvNFFMPGameMode == null)
	{
		return false;
	}

	int iMode = g_cvNFFGameModeTypes.IntValue;
	if (iMode != 0)
	{
		if (!g_bMapStarted)
		{
			return false;
		}

		g_iCurrentMode = 0;

		int iGameMode = CreateEntityByName("info_gamemode");
		if (IsValidEntity(iGameMode))
		{
			DispatchSpawn(iGameMode);

			HookSingleEntityOutput(iGameMode, "OnCoop", vGameMode, true);
			HookSingleEntityOutput(iGameMode, "OnSurvival", vGameMode, true);
			HookSingleEntityOutput(iGameMode, "OnVersus", vGameMode, true);
			HookSingleEntityOutput(iGameMode, "OnScavenge", vGameMode, true);

			ActivateEntity(iGameMode);
			AcceptEntityInput(iGameMode, "PostSpawnActivate");

			if (IsValidEntity(iGameMode))
			{
				RemoveEdict(iGameMode);
			}
		}

		if (g_iCurrentMode == 0 || !(iMode & g_iCurrentMode))
		{
			return false;
		}
	}

	char sFixed[32], sGameMode[32], sGameModes[513], sList[513];
	g_cvNFFMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	FormatEx(sFixed, sizeof(sFixed), ",%s,", sGameMode);

	g_cvNFFEnabledGameModes.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0] != '\0')
	{
		FormatEx(sList, sizeof(sList), ",%s,", sGameModes);
		if (StrContains(sList, sFixed, false) == -1)
		{
			return false;
		}
	}

	g_cvNFFDisabledGameModes.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0] != '\0')
	{
		FormatEx(sList, sizeof(sList), ",%s,", sGameModes);
		if (StrContains(sList, sFixed, false) != -1)
		{
			return false;
		}
	}

	return true;
}

static bool bIsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}