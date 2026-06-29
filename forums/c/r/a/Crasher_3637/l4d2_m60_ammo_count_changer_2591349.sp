// M60 Ammo Count Changer
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define M60_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2] M60 Ammo Count Changer",
	author = "Psykotik (Crasher_3637)",
	description = "Changes the ammo count of M60s.",
	version = M60_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=307401"
};

char g_sGameName[64];

ConVar g_cvM60AmmoCount;
ConVar g_cvM60DisabledGameModes;
ConVar g_cvM60EnabledGameModes;
ConVar g_cvM60Enable;
ConVar g_cvM60GameMode;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	GetGameFolderName(g_sGameName, sizeof(g_sGameName));
	if (!StrEqual(g_sGameName, "left4dead2", false))
	{
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvM60AmmoCount = CreateConVar("l4d2_m60_ammocount", "150", "How much ammo should M60s have?");
	g_cvM60DisabledGameModes = CreateConVar("l4d2_m60_disabledgamemodes", "versus,teamversus,scavenge,teamscavenge", "Disable the plugin in these game modes.\n(Empty: None)\n(Not empty: Separate by commas, disabled in these game modes.)");
	g_cvM60EnabledGameModes = CreateConVar("l4d2_m60_enabledgamemodes", "coop,survival", "Enable the plugin in these game modes.\n(Empty: All)\n(Not empty: Separate by commas, enabled in these game modes.)");
	g_cvM60Enable = CreateConVar("l4d2_m60_enable", "1", "Enable the plugin?\n(0: OFF)\n(1: ON)");
	HookEvent("item_pickup", eM60AmmoChange);
	AutoExecConfig(true, "l4d2_m60_ammo_count");
}

public Action eM60AmmoChange(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvM60Enable.BoolValue || !bIsSystemValid())
	{
		return Plugin_Continue;
	}

	char sItemName[128];
	event.GetString("item", sItemName, sizeof(sItemName));
	int iSurvivor = GetClientOfUserId(event.GetInt("userid"));
	if (bIsSurvivor(iSurvivor) && StrEqual(sItemName, "rifle_m60", false) && GetPlayerWeaponSlot(iSurvivor, 0) > 1)
	{
		SetEntProp(GetPlayerWeaponSlot(iSurvivor, 0), Prop_Data, "m_iClip1", g_cvM60AmmoCount.IntValue, 1);
	}

	return Plugin_Continue;
}

stock bool bIsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsClientInKickQueue(client) && IsPlayerAlive(client));
}

stock bool bIsSystemValid()
{
	char sGameModes[64];
	char sModeName[64];
	g_cvM60GameMode.GetString(sModeName, sizeof(sModeName));
	Format(sModeName, sizeof(sModeName), ",%s,", sModeName);
	g_cvM60EnabledGameModes.GetString(sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sModeName, false) == -1)
		{
			return false;
		}
	}

	g_cvM60DisabledGameModes.GetString(sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sModeName, false) != -1)
		{
			return false;
		}
	}

	return true;
}