#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define SII_VERSION "1.1"

public Plugin myinfo =
{
	name = "Special Infected Immunities",
	author = "Psyk0tik (Crasher_3637)",
	description = "Grants different kinds of immunities for special infected.",
	version = SII_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=310443"
};

bool g_bLateLoad, g_bPluginEnabled;
ConVar g_cvSIIBulletImmunity, g_cvSIIDisabledGameModes, g_cvSIIEnabledGameModes, g_cvSIIEnablePlugin, g_cvSIIExplosiveImmunity, g_cvSIIFireImmunity, g_cvSIIGameMode, g_cvSIIGameModeTypes, g_cvSIIMeleeImmunity;
int g_iCurrentMode;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Special Infected Immunities only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvSIIBulletImmunity = CreateConVar("sii_bullet_immunity", "35", "Give the following special infected bullet immunity.\nCombine numbers in any order for different results.\n1: Smoker\n2: Boomer\n3: Hunter\n4: Spitter\n5: Jockey\n6: Charger\n7: Tank");
	g_cvSIIDisabledGameModes = CreateConVar("sii_disabled_gamemodes", "", "Disable Special Infected Immunities in these gamemodes.\nSeparate by commas.\nEmpty: None\nNot empty: Disable in these gamemodes.");
	g_cvSIIEnabledGameModes = CreateConVar("sii_enabled_gamemodes", "", "Enable Special Infected Immunities in these gamemodes.\nSeparate by commas.\nEmpty: All\nNot empty: Enable in these gamemodes.");
	g_cvSIIEnablePlugin = CreateConVar("sii_enable_plugin", "1", "Enable Special Infected Immunities?\n0: OFF\n1: ON", _, true, 0.0, true, 1.0);
	g_cvSIIExplosiveImmunity = CreateConVar("sii_explosive_immunity", "16", "Give the following special infected explosive immunity.\nCombine numbers in any order for different results.\n1: Smoker\n2: Boomer\n3: Hunter\n4: Spitter\n5: Jockey\n6: Charger\n7: Tank");
	g_cvSIIFireImmunity = CreateConVar("sii_fire_immunity", "7", "Give the following special infected fire immunity.\nCombine numbers in any order for different results.\n1: Smoker\n2: Boomer\n3: Hunter\n4: Spitter\n5: Jockey\n6: Charger\n7: Tank");
	g_cvSIIGameModeTypes = CreateConVar("sii_gamemode_types", "0", "Enable Special Infected Immunities in these gamemode types.\n0: All\n1: Coop modes only.\n2: Versus modes only.\n4: Survival modes only.\n8: Scavenge modes only.", _, true, 0.0, true, 15.0);
	g_cvSIIMeleeImmunity = CreateConVar("sii_melee_immunity", "24", "Give the following special infected melee immunity.\nCombine numbers in any order for different results.\n1: Smoker\n2: Boomer\n3: Hunter\n4: Spitter\n5: Jockey\n6: Charger\n7: Tank");
	CreateConVar("sii_plugin_version", SII_VERSION, "Special Infected Immunities Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvSIIGameMode = FindConVar("mp_gamemode");
	AutoExecConfig(true, "special_infected_immunities");
}

public void OnMapStart()
{
	if (g_bLateLoad)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				SDKHook(iPlayer, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		g_bLateLoad = false;
	}
}

public void OnConfigsExecuted()
{
	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	if (IsMapValid(sMap))
	{
		vPluginStatus();
		CreateTimer(0.1, tTimerFireBlock, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_cvSIIEnablePlugin.BoolValue && g_bPluginEnabled && bIsValidClient(victim) && damage > 0.0)
	{
		char sBulletTypes[8], sExplosiveTypes[8], sFireTypes[8], sMeleeTypes[8];
		g_cvSIIBulletImmunity.GetString(sBulletTypes, sizeof(sBulletTypes));
		g_cvSIIExplosiveImmunity.GetString(sExplosiveTypes, sizeof(sExplosiveTypes));
		g_cvSIIFireImmunity.GetString(sFireTypes, sizeof(sFireTypes));
		g_cvSIIMeleeImmunity.GetString(sMeleeTypes, sizeof(sMeleeTypes));
		if (damagetype & DMG_BULLET && ((bIsBlocked(sBulletTypes, "1", "1") && bIsSmoker(victim)) || (bIsBlocked(sBulletTypes, "2", "2") && bIsBoomer(victim)) || (bIsBlocked(sBulletTypes, "3", "3") && bIsHunter(victim)) || (bIsBlocked(sBulletTypes, "4", "4") && bIsSpitter(victim)) || (bIsBlocked(sBulletTypes, "5", "7") && bIsJockey(victim)) || (bIsBlocked(sBulletTypes, "6", "6") && bIsCharger(victim)) || (bIsBlocked(sBulletTypes, "7", "7") && bIsTank(victim))))
		{
			damage = 0.0;
			return Plugin_Handled;
		}
		else if ((damagetype & DMG_BLAST || damagetype & DMG_BLAST_SURFACE || damagetype & DMG_AIRBOAT || damagetype & DMG_PLASMA) && ((bIsBlocked(sExplosiveTypes, "1", "1") && bIsSmoker(victim)) || (bIsBlocked(sExplosiveTypes, "2", "2") && bIsBoomer(victim)) || (bIsBlocked(sExplosiveTypes, "3", "3") && bIsHunter(victim)) || (bIsBlocked(sExplosiveTypes, "4", "4") && bIsSpitter(victim)) || (bIsBlocked(sExplosiveTypes, "5", "7") && bIsJockey(victim)) || (bIsBlocked(sExplosiveTypes, "6", "6") && bIsCharger(victim)) || (bIsBlocked(sExplosiveTypes, "7", "7") && bIsTank(victim))))
		{
			damage = 0.0;
			return Plugin_Handled;
		}
		else if (damagetype & DMG_BURN && ((bIsBlocked(sFireTypes, "1", "1") && bIsSmoker(victim)) || (bIsBlocked(sFireTypes, "2", "2") && bIsBoomer(victim)) || (bIsBlocked(sFireTypes, "3", "3") && bIsHunter(victim)) || (bIsBlocked(sFireTypes, "4", "4") && bIsSpitter(victim)) || (bIsBlocked(sFireTypes, "5", "7") && bIsJockey(victim)) || (bIsBlocked(sFireTypes, "6", "6") && bIsCharger(victim)) || (bIsBlocked(sFireTypes, "7", "7") && bIsTank(victim))))
		{
			damage = 0.0;
			return Plugin_Handled;
		}
		else if ((damagetype & DMG_SLASH || damagetype & DMG_CLUB) && ((bIsBlocked(sMeleeTypes, "1", "1") && bIsSmoker(victim)) || (bIsBlocked(sMeleeTypes, "2", "2") && bIsBoomer(victim)) || (bIsBlocked(sMeleeTypes, "3", "3") && bIsHunter(victim)) || (bIsBlocked(sMeleeTypes, "4", "4") && bIsSpitter(victim)) || (bIsBlocked(sMeleeTypes, "5", "7") && bIsJockey(victim)) || (bIsBlocked(sMeleeTypes, "6", "6") && bIsCharger(victim)) || (bIsBlocked(sMeleeTypes, "7", "7") && bIsTank(victim))))
		{
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void vGameMode(const char[] output, int caller, int activator, float delay)
{
	if (strcmp(output, "OnCoop") == 0)
	{
		g_iCurrentMode = 1;
	}
	else if (strcmp(output, "OnVersus") == 0)
	{
		g_iCurrentMode = 2;
	}
	else if (strcmp(output, "OnSurvival") == 0)
	{
		g_iCurrentMode = 4;
	}
	else if (strcmp(output, "OnScavenge") == 0)
	{
		g_iCurrentMode = 8;
	}
}

void vPluginStatus()
{
	bool bIsPluginAllowed = bIsPluginEnabled();
	if (g_cvSIIEnablePlugin.BoolValue && bIsPluginAllowed)
	{
		vLateLoad(true);
		g_bPluginEnabled = true;
	}
	else
	{
		vLateLoad(false);
		g_bPluginEnabled = false;
	}
}

void vLateLoad(bool late)
{
	if (late)
	{
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsValidClient(iPlayer))
			{
				SDKHook(iPlayer, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

stock bool bIsBlocked(char[] type, char[] value, char[] value2)
{
	return bIsL4D2Game() ? StrContains(type, value) != -1 : StrContains(type, value2) != -1;
}

stock bool bIsBoomer(int client)
{
	return bIsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 2;
}

stock bool bIsCharger(int client)
{
	return bIsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 6;
}

stock bool bIsHunter(int client)
{
	return bIsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 3;
}

stock bool bIsInfected(int client)
{
	return bIsValidClient(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client);
}

stock bool bIsJockey(int client)
{
	return bIsInfected(client) && bIsL4D2Game() && GetEntProp(client, Prop_Send, "m_zombieClass") == 5;
}

stock bool bIsL4D2Game()
{
	return GetEngineVersion() == Engine_Left4Dead2;
}

stock bool bIsPlayerBurning(int client)
{
	if (GetEntPropFloat(client, Prop_Send, "m_burnPercent") > 0.0 || GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE)
	{
		return true;
	}
	return false;
}

stock bool bIsPluginEnabled()
{
	if (g_cvSIIGameMode == null)
	{
		return false;
	}
	if (g_cvSIIGameModeTypes.IntValue != 0)
	{
		g_iCurrentMode = 0;
		int iGameMode = CreateEntityByName("info_gamemode");
		DispatchSpawn(iGameMode);
		HookSingleEntityOutput(iGameMode, "OnCoop", vGameMode, true);
		HookSingleEntityOutput(iGameMode, "OnSurvival", vGameMode, true);
		HookSingleEntityOutput(iGameMode, "OnVersus", vGameMode, true);
		HookSingleEntityOutput(iGameMode, "OnScavenge", vGameMode, true);
		ActivateEntity(iGameMode);
		AcceptEntityInput(iGameMode, "PostSpawnActivate");
		AcceptEntityInput(iGameMode, "Kill");
		if (g_iCurrentMode == 0 || !(g_cvSIIGameModeTypes.IntValue & g_iCurrentMode))
		{
			return false;
		}
	}
	char sGameMode[32], sGameModes[513];
	g_cvSIIGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	g_cvSIIEnabledGameModes.GetString(sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
		{
			return false;
		}
	}
	g_cvSIIDisabledGameModes.GetString(sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
		{
			return false;
		}
	}
	return true;
}

stock bool bIsSmoker(int client)
{
	return bIsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 1;
}

stock bool bIsSpecialInfected(int client)
{
	return bIsSmoker(client) || bIsBoomer(client) || bIsHunter(client) || bIsSpitter(client) || bIsJockey(client) || bIsCharger(client) || bIsTank(client);
}

stock bool bIsSpitter(int client)
{
	return bIsInfected(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 4;
}

stock bool bIsTank(int client)
{
	return bIsInfected(client) && (bIsL4D2Game() ? GetEntProp(client, Prop_Send, "m_zombieClass") == 8 : GetEntProp(client, Prop_Send, "m_zombieClass") == 5);
}

stock bool bIsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}

stock void vExtinguishFire(int client, char[] type, char[] value, char[] value2)
{
	if (bIsBlocked(type, value, value2))
	{
		ExtinguishEntity(client);
	}
}

public Action tTimerFireBlock(Handle timer)
{
	if (!g_cvSIIEnablePlugin.BoolValue || !g_bPluginEnabled)
	{
		return Plugin_Continue;
	}
	char sFireTypes[8];
	g_cvSIIFireImmunity.GetString(sFireTypes, sizeof(sFireTypes));
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (bIsSpecialInfected(iPlayer) && bIsPlayerBurning(iPlayer))
		{
			switch (GetEntProp(iPlayer, Prop_Send, "m_zombieClass"))
			{
				case 1: vExtinguishFire(iPlayer, sFireTypes, "1", "1");
				case 2: vExtinguishFire(iPlayer, sFireTypes, "2", "2");
				case 3: vExtinguishFire(iPlayer, sFireTypes, "3", "3");
				case 4: vExtinguishFire(iPlayer, sFireTypes, "4", "4");
				case 5: vExtinguishFire(iPlayer, sFireTypes, "5", "7");
				case 6: vExtinguishFire(iPlayer, sFireTypes, "6", "6");
				case 8: vExtinguishFire(iPlayer, sFireTypes, "7", "7");
			}
		}
	}
	return Plugin_Continue;
}