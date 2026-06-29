#include <sourcemod>
#include <sdkhooks>
#pragma semicolon 1



#define PLUGIN_VERSION "0.3"



// Lateload
new bool:g_bLateLoaded;


// Enabled Cvar
new Handle:g_hEnabled;
new bool:g_bEnabled;


// Version
new Handle:g_hVersion;


// Teamfilter
new Handle:g_hTeamFilter;
new g_iTeamFilter;


// ClientFilter
new Handle:g_hClientFilter;
new g_iClientFilter;


public Plugin:myinfo = 
{
	name = "No Fall Damage v2",
	author = "Impact",
	description = "Prevents players from taking damage by falling too far",
	version = PLUGIN_VERSION,
	url = "http://gugyclan.eu"
}





public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}





public OnPluginStart()
{
	g_hVersion      = CreateConVar("sm_nofalldamage_version", PLUGIN_VERSION, "Version of this plugin (Not changeable)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	g_hEnabled      = CreateConVar("sm_nofalldamage_enabled", "1", "Whether or not this plugin is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hTeamFilter   = CreateConVar("sm_nofalldamage_teamfilter", "0", "Team that should have noblock enabled, 0 = any, 2 = RED, 3 = BLUE", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hClientFilter = CreateConVar("sm_nofalldamage_clientfilter", "0", "0 = any, 1 = No Bots", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_bEnabled      = GetConVarBool(g_hEnabled);
	g_iTeamFilter   = GetConVarInt(g_hTeamFilter);
	g_iClientFilter = GetConVarInt(g_hClientFilter);
	
	HookConVarChange(g_hEnabled, OnCvarChanged);
	HookConVarChange(g_hVersion, OnCvarChanged);
	HookConVarChange(g_hTeamFilter, OnCvarChanged);
	HookConVarChange(g_hClientFilter, OnCvarChanged);
	
	
	// LateLoad;
	if(g_bLateLoaded)
	{
		for(new i; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}






public OnCvarChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == g_hEnabled)
	{
		g_bEnabled = GetConVarBool(g_hEnabled);
	}
	if(convar == g_hTeamFilter)
	{
		g_iTeamFilter = GetConVarInt(g_hTeamFilter);
	}
	if(convar == g_hClientFilter)
	{
		g_iClientFilter = GetConVarInt(g_hClientFilter);
	}
	else if(convar == g_hVersion)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	}
}






public OnClientPostAdminCheck(client)
{
	if(IsClientValid(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}





public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(g_bEnabled)
	{
		// We could cache this maybe, for now the overhead should be small enough to skip it
		if(g_iTeamFilter < 1 || g_iTeamFilter > 1 && GetClientTeam(client) == g_iTeamFilter)
		{
			// Clientfilter, could also be cached
			if(g_iClientFilter == 0 || g_iClientFilter == 1 && !IsFakeClient(client))
			{
				if(damagetype & DMG_FALL)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}





stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MAXPLAYERS && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}

