#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVTeam = INVALID_HANDLE;
new g_iRestrictTeam = 0;

public Plugin:myinfo = 
{
	name = "Anti Duck",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Disables players from ducking.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_antiduck_version", PLUGIN_VERSION, "Disable Ducking", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVTeam = CreateConVar("sm_antiduck_team", "2", "Which team should not be allowed to duck? 0: disabled, 1: both, 2: terror, 3: ct?", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_iRestrictTeam = GetConVarInt(g_hCVTeam);
	HookConVarChange(g_hCVTeam, ConVar_Team);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_iRestrictTeam == 0)
		return Plugin_Continue;
	
	// Disallow ducking, if player is in restricted team
	if(buttons & IN_DUCK && (g_iRestrictTeam == 1 || g_iRestrictTeam == GetClientTeam(client)))
	{
		buttons &= ~IN_DUCK;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public ConVar_Team(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	g_iRestrictTeam = StringToInt(newValue);
}