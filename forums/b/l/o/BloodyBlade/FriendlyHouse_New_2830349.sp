#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION		"0.92"
#define CVAR_FLAGS			FCVAR_NOTIFY|FCVAR_SPONLY

ConVar g_hFH_Enabled, g_hFH_VersusOnly, g_hGameMode;
bool bVersusOnly = false, bHooked = false, SDKHooked[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo = 
{
	name = "Friendly House",
	author = "Mr. Zero(Rewritten cut. ver by BloodyBlade)",
	description = "Disables friendly fire while survivors is still in safehouse.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=101064"
}

public void OnPluginStart()
{
	CreateConVar("l4d_fh_version", PLUGIN_VERSION, "Friendly House Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hFH_Enabled = CreateConVar("l4d_fh_enable", "1", "Sets whether the plugin is active.", CVAR_FLAGS);
	g_hFH_VersusOnly = CreateConVar("l4d_fh_versusonly", "0", "Sets whether its only in Versus the plugin is active. If 0 then it will also be active in other game modes.", CVAR_FLAGS);

	AutoExecConfig(true, "FriendlyHouse");

	g_hFH_Enabled.AddChangeHook(ConvarChanged_Enabled);
	g_hFH_VersusOnly.AddChangeHook(ConVarsChanged);
	g_hGameMode = FindConVar("mp_gamemode");
	g_hGameMode.AddChangeHook(ConvarChanged_Enabled);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !SDKHooked[i])
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHooked[i] = true;
		}
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConvarChanged_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bVersusOnly = g_hFH_VersusOnly.BoolValue;
}

void IsAllowed()
{
    bool bPluginOn = g_hFH_Enabled.BoolValue;
    ConVarsChanged(null, "", "");
    if(bPluginOn && !bHooked && (!bVersusOnly || (bVersusOnly && IsGameMode("versus"))))
    {
    	bHooked = true;
    }
    else if((!bPluginOn && bHooked) || (bVersusOnly && !IsGameMode("versus")))
    {
    	bHooked = false;
    	for(int i = 1; i <= MaxClients; i++)
    	{
    		if(IsClientInGame(i) && SDKHooked[i])
    		{
    			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    			SDKHooked[i] = false;
    		}
    	}
    }
}

stock bool LeftStartArea()
{
	for (int i = MaxClients + 1; i <= GetMaxEntities(); i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			if (StrEqual(netclass, "CTerrorPlayerResource") && GetEntProp(i, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
			{
				return true;
			}
		}
	}
	return false;
}

public void OnClientPutInServer(int client)
{
	if(bHooked && client > 0 && !SDKHooked[client])
	{
	    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	    SDKHooked[client] = true;
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
    if(bHooked && !LeftStartArea())
	{
		if(victim > 0 && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
		{
			return Plugin_Handled;
		}
    }
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
    if(bHooked && client > 0 && SDKHooked[client])
    {
        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKHooked[client] = false;
    }
}

bool IsGameMode(char GameModeName[16])
{
	char GameMode[sizeof(GameModeName)];
	g_hGameMode.GetString(GameMode, sizeof(GameMode));
	return StrContains(GameMode, GameModeName, false) != -1;
}
