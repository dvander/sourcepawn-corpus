// Ammunition Variation
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define AV_VERSION "2.5"

public Plugin myinfo =
{
	name = "Ammunition Variation",
	author = "Psykotik (Crasher_3637)",
	description = "Varies the ammunition count of guns periodically.",
	version = AV_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=308211"
};

ConVar g_cvAVAssaultRifle;
ConVar g_cvAVAssaultRifleAmmoMin;
ConVar g_cvAVAssaultRifleAmmoMax;
ConVar g_cvAVAutoshotgun;
ConVar g_cvAVAutoshotgunAmmoMin;
ConVar g_cvAVAutoshotgunAmmoMax;
ConVar g_cvAVChangeDelay;
ConVar g_cvAVChromeshotgun;
ConVar g_cvAVDisabledGameModes;
ConVar g_cvAVEnabledGameModes;
ConVar g_cvAVEnable;
ConVar g_cvAVGameMode;
ConVar g_cvAVGrenadeLauncher;
ConVar g_cvAVGrenadeLauncherAmmoMin;
ConVar g_cvAVGrenadeLauncherAmmoMax;
ConVar g_cvAVHuntingRifle;
ConVar g_cvAVHuntingRifleAmmoMin;
ConVar g_cvAVHuntingRifleAmmoMax;
ConVar g_cvAVM60AmmoMin;
ConVar g_cvAVM60AmmoMax;
ConVar g_cvAVPumpshotgun;
ConVar g_cvAVShotgunAmmoMin;
ConVar g_cvAVShotgunAmmoMax;
ConVar g_cvAVSMG;
ConVar g_cvAVSMGAmmoMin;
ConVar g_cvAVSMGAmmoMax;
ConVar g_cvAVSniperRifle;
ConVar g_cvAVSniperRifleAmmoMin;
ConVar g_cvAVSniperRifleAmmoMax;
int g_iM60;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Ammunition Variation only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (bIsL4D2Game())
	{
		g_cvAVAutoshotgun = FindConVar("ammo_autoshotgun_max");
		g_cvAVChromeshotgun = FindConVar("ammo_shotgun_max");
		g_cvAVGrenadeLauncher = FindConVar("ammo_grenadelauncher_max");
		g_cvAVGrenadeLauncherAmmoMin = CreateConVar("av_grenadelauncher_min", "5", "Minimum ammo count for Grenade launchers.");
		g_cvAVGrenadeLauncherAmmoMax = CreateConVar("av_grenadelauncher_max", "10", "Maximum ammo count for Grenade launchers.");
		g_cvAVM60AmmoMin = CreateConVar("av_m60_min", "80", "Minimum ammo count for M60s.");
		g_cvAVM60AmmoMax = CreateConVar("av_m60_max", "150", "Maximum ammo count for M60s.");
		g_cvAVSniperRifle = FindConVar("ammo_sniperrifle_max");
		g_cvAVSniperRifleAmmoMin = CreateConVar("av_sniperrifle_min", "90", "Minimum ammo count for Sniper rifles.");
		g_cvAVSniperRifleAmmoMax = CreateConVar("av_sniperrifle_max", "180", "Maximum ammo count for Sniper rifles.");
	}
	g_cvAVAssaultRifle = FindConVar("ammo_assaultrifle_max");
	g_cvAVAssaultRifleAmmoMin = CreateConVar("av_assaultrifle_min", "180", "Minimum ammo count for Assault rifles.");
	g_cvAVAssaultRifleAmmoMax = CreateConVar("av_assaultrifle_max", "360", "Maximum ammo count for Assault rifles.");
	g_cvAVAutoshotgunAmmoMin = CreateConVar("av_autoshotgun_min", "45", "Minimum ammo count for Automatic shotguns.");
	g_cvAVAutoshotgunAmmoMax = CreateConVar("av_autoshotgun_max", "90", "Maximum ammo count for Automatic shotguns.");
	g_cvAVChangeDelay = CreateConVar("av_changedelay", "60.0", "The ammunition count for guns change every time this many seconds passes.");
	g_cvAVDisabledGameModes = CreateConVar("av_disabledgamemodes", "", "Disable the plugin in these game modes.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Disabled in these game modes.)");
	g_cvAVEnabledGameModes = CreateConVar("av_enabledgamemodes", "", "Enable the plugin in these game modes.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Enabled in these game modes.)");
	g_cvAVEnable = CreateConVar("av_enable", "1", "Enable the plugin?\n(0: OFF)\n(1: ON)");
	g_cvAVGameMode = FindConVar("mp_gamemode");
	g_cvAVHuntingRifle = FindConVar("ammo_huntingrifle_max");
	g_cvAVHuntingRifleAmmoMin = CreateConVar("av_huntingrifle_min", "80", "Minimum ammo count for Hunting rifles.");
	g_cvAVHuntingRifleAmmoMax = CreateConVar("av_huntingrifle_max", "150", "Maximum ammo count for Hunting rifles.");
	CreateConVar("av_pluginversion", AV_VERSION, "Ammunition Variation Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvAVPumpshotgun = FindConVar("ammo_buckshot_max");
	g_cvAVShotgunAmmoMin = CreateConVar("av_shotgun_min", "28", "Minimum ammo count for Shotguns.");
	g_cvAVShotgunAmmoMax = CreateConVar("av_shotgun_max", "56", "Maximum ammo count for Shotguns.");
	g_cvAVSMG = FindConVar("ammo_smg_max");
	g_cvAVSMGAmmoMin = CreateConVar("av_smg_min", "240", "Minimum ammo count for SMGs.");
	g_cvAVSMGAmmoMax = CreateConVar("av_smg_max", "480", "Maximum ammo count for SMGs.");
	g_cvAVEnable.AddChangeHook(vAVEnableCvars);
	g_cvAVEnabledGameModes.AddChangeHook(vAVEnableCvars);
	g_cvAVDisabledGameModes.AddChangeHook(vAVEnableCvars);
	HookEvent("item_pickup", eItemPickup);
	AutoExecConfig(true, "ammunition_variation");
}

public void OnMapStart()
{
	CreateTimer(g_cvAVChangeDelay.FloatValue, tTimerAmmoChange, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action eItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvAVEnable.BoolValue || !bIsSystemValid())
	{
		return Plugin_Continue;
	}
	char sItemName[128];
	event.GetString("item", sItemName, sizeof(sItemName));
	int iSurvivor = GetClientOfUserId(event.GetInt("userid"));
	if (bIsSurvivor(iSurvivor) && StrEqual(sItemName, "rifle_m60", false) && GetPlayerWeaponSlot(iSurvivor, 0) > 1)
	{
		SetEntProp(GetPlayerWeaponSlot(iSurvivor, 0), Prop_Data, "m_iClip1", g_iM60, 1);
	}
	return Plugin_Continue;
}

public void vAVEnableCvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!g_cvAVEnable.BoolValue || !bIsSystemValid())
	{
		g_cvAVAssaultRifle.SetInt(360);
		g_cvAVHuntingRifle.SetInt(150);
		bIsL4D2Game() ? g_cvAVChromeshotgun.SetInt(56) : g_cvAVPumpshotgun.SetInt(128);
		g_cvAVSMG.SetInt(480);
		if (bIsL4D2Game())
		{
			g_iM60 = 150;
			g_cvAVAutoshotgun.SetInt(90);
			g_cvAVGrenadeLauncher.SetInt(30);
			g_cvAVSniperRifle.SetInt(180);
		}
	}
}

public Action tTimerAmmoChange(Handle timer)
{
	if (!g_cvAVEnable.BoolValue || !bIsSystemValid())
	{
		return Plugin_Continue;
	}
	int iAssaultRifle = GetRandomInt(g_cvAVAssaultRifleAmmoMin.IntValue, g_cvAVAssaultRifleAmmoMax.IntValue);
	int iHuntingRifle = GetRandomInt(g_cvAVHuntingRifleAmmoMin.IntValue, g_cvAVHuntingRifleAmmoMax.IntValue);
	int iShotgun = GetRandomInt(g_cvAVShotgunAmmoMin.IntValue, g_cvAVShotgunAmmoMax.IntValue);
	int iSMG = GetRandomInt(g_cvAVSMGAmmoMin.IntValue, g_cvAVSMGAmmoMax.IntValue);
	g_cvAVAssaultRifle.SetInt(iAssaultRifle);
	g_cvAVHuntingRifle.SetInt(iHuntingRifle);
	bIsL4D2Game() ? g_cvAVChromeshotgun.SetInt(iShotgun) : g_cvAVPumpshotgun.SetInt(iShotgun);
	g_cvAVSMG.SetInt(iSMG);
	if (bIsL4D2Game())
	{
		int iAutoshotgun = GetRandomInt(g_cvAVAutoshotgunAmmoMin.IntValue, g_cvAVAutoshotgunAmmoMax.IntValue);
		int iGrenadeLauncher = GetRandomInt(g_cvAVGrenadeLauncherAmmoMin.IntValue, g_cvAVGrenadeLauncherAmmoMax.IntValue);
		g_iM60 = GetRandomInt(g_cvAVM60AmmoMin.IntValue, g_cvAVM60AmmoMax.IntValue);
		int iSniperRifle = GetRandomInt(g_cvAVSniperRifleAmmoMin.IntValue, g_cvAVSniperRifleAmmoMax.IntValue);
		g_cvAVAutoshotgun.SetInt(iAutoshotgun);
		g_cvAVGrenadeLauncher.SetInt(iGrenadeLauncher);
		g_cvAVSniperRifle.SetInt(iSniperRifle);
	}
	return Plugin_Continue;
}

stock bool bIsL4D2Game()
{
	EngineVersion evEngine = GetEngineVersion();
	return evEngine == Engine_Left4Dead2;
}

stock bool bIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && IsPlayerAlive(client);
}

stock bool bIsSystemValid()
{
	char sGameMode[32];
	char sConVarModes[32];
	g_cvAVGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	g_cvAVEnabledGameModes.GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) == -1)
		{
			return false;
		}
	}
	g_cvAVDisabledGameModes.GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) != -1)
		{
			return false;
		}
	}
	return true;
}