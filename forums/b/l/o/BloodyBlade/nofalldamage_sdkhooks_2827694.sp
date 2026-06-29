#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "0.6.3"
#define CVAR_FLAGS FCVAR_NOTIFY

// Lateload
bool g_bLateLoaded;
// Enabled Cvar
ConVar g_hEnabled;
bool g_bEnabled;
// Version
ConVar g_hVersion;
// Teamfilter
ConVar g_hTeamFilter;
int g_iTeamFilter;
// ClientFilter
ConVar g_hClientFilter;
int g_iClientFilter;

public Plugin myinfo = 
{
	name = "No Fall Damage v2",
	author = "Impact",
	description = "Prevents players from taking damage by falling to the ground",
	version = PLUGIN_VERSION,
	url = "http://gugyclan.eu"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hVersion      = CreateConVar("sm_nofalldamage_version", PLUGIN_VERSION, "Version of this plugin (Not changeable)", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hEnabled      = CreateConVar("sm_nofalldamage_enabled", "1", "Whether or not this plugin is enabled", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hTeamFilter   = CreateConVar("sm_nofalldamage_teamfilter", "0", "Team that should be protected from falldamage, 0 = Any, 2 = RED, 3 = BLUE", CVAR_FLAGS, true, 0.0, true, 3.0);
	g_hClientFilter = CreateConVar("sm_nofalldamage_clientfilter", "0", "Clients that should be protected from falldamage, 0 = Any, 1 = Only Admins", CVAR_FLAGS, true, 0.0, true, 1.0);

	g_bEnabled      = g_hEnabled.BoolValue;
	g_iTeamFilter   = g_hTeamFilter.IntValue;
	g_iClientFilter = g_hClientFilter.IntValue;

	g_hVersion.SetString(PLUGIN_VERSION, false, false);

	g_hEnabled.AddChangeHook(OnCvarChanged);
	g_hVersion.AddChangeHook(OnCvarChanged);
	g_hTeamFilter.AddChangeHook(OnCvarChanged);
	g_hClientFilter.AddChangeHook(OnCvarChanged);

	// LateLoad;
	if(g_bLateLoaded)
	{
		for(int i; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeFallDamage);
			}
		}
	}
}

void OnCvarChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if(convar == g_hEnabled)
	{
		g_bEnabled = g_hEnabled.BoolValue;
	}
	else if(convar == g_hTeamFilter)
	{
		g_iTeamFilter = g_hTeamFilter.IntValue;
	}
	else if(convar == g_hClientFilter)
	{
		g_iClientFilter = g_hClientFilter.IntValue;
	}
	else if(convar == g_hVersion)
	{
		g_hVersion.SetString(PLUGIN_VERSION, false, false);
	}
}

public void OnClientPutInServer(int client)
{
	if(client > 0)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeFallDamage);
	}
}

Action OnTakeFallDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(g_bEnabled)
	{
		// We first check if damage is falldamage and then check the others
		if(damagetype & DMG_FALL)
		{
			// Teamfilter
			if(g_iTeamFilter < 1 || (g_iTeamFilter > 1 && GetClientTeam(client) == g_iTeamFilter))
			{
				// Clientfilter
				if(g_iClientFilter == 0 || (g_iClientFilter == 1 && CheckCommandAccess(client, "sm_nofalldamage_immune", ADMFLAG_GENERIC, false)))
				{
					return Plugin_Handled;
				}
			}
		}
	}
	else SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeFallDamage);
	return Plugin_Continue;
}
