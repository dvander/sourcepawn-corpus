#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.27"

ConVar g_hCVarsEnabled;
ConVar g_hCVarsFlag;
ConVar g_hCVarsReason;
ConVar g_hCVarsWarn;

public Plugin myinfo =
{
	name = "Admin Sprays Only",
	description = "Only admins are allowed to spray.",
	author = "luki1412",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public void OnPluginStart()
{
	ConVar g_hCVarsVer = CreateConVar("sm_aso_version", PLUGIN_VERSION, "Admin Sprays Only plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_hCVarsEnabled = CreateConVar("sm_aso_enabled", "1", "Enables/disables Admin Sprays Only", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVarsFlag = CreateConVar("sm_aso_flag", "b", "Admin flag needed to be able to spray", FCVAR_NONE);
	g_hCVarsWarn = CreateConVar("sm_aso_warn", "1", "Enables/disables chat warning messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVarsReason = CreateConVar("sm_aso_warning", "You are not allowed to spray", "Warning displayed when a player without the admin flag tries to spray", FCVAR_NONE);
	EnabledChanged(g_hCVarsEnabled, "", "");
	HookConVarChange(g_hCVarsEnabled, EnabledChanged);
	AutoExecConfig(true, "Admin_Sprays_Only");
	SetConVarString(g_hCVarsVer, PLUGIN_VERSION);
	delete g_hCVarsVer;
}

public void EnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(convar))
	{
		AddTempEntHook("Player Decal", Player_Decal);
	}
	else
	{
		RemoveTempEntHook("Player Decal", Player_Decal);
	}
}

public Action Player_Decal(const char[] name, const int[] clients, int count, float delay)
{
	if (!GetConVarBool(g_hCVarsEnabled))
	{
		return Plugin_Continue;
	}

	int client = TE_ReadNum("m_nPlayer");

	if (IsValidClient(client))
	{
	    char CharAdminFlag[10];
	    GetConVarString(g_hCVarsFlag, CharAdminFlag, sizeof(CharAdminFlag));

	    if (IsValidAdmin(client, CharAdminFlag))
		{
		    return Plugin_Continue;
		}
		else
		{
			if (GetConVarBool(g_hCVarsWarn))
			{
				char CharReason[255];
				GetConVarString(g_hCVarsReason, CharReason, sizeof(CharReason));
				PrintToChat(client, "%s", CharReason);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientReplay(client) && !IsClientSourceTV(client));
}

bool IsValidAdmin(int client, const char[] flags)
{
    int InputFlags = ReadFlagString(flags);
    int CurrentFlags = GetUserFlagBits(client);

    if (((CurrentFlags & InputFlags) == InputFlags) || (CurrentFlags & ADMFLAG_ROOT))
	{
        return true;
    }

    return false;
}