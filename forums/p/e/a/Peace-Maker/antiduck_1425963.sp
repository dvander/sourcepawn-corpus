#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Handle:g_hCVTeam = INVALID_HANDLE;
new Handle:g_hCVTime = INVALID_HANDLE;
new g_iRestrictTeam = 0;
new Float:g_fRestrictTime = 0.0;

new Handle:g_hAllowDuckTimer[MAXPLAYERS+2] = {INVALID_HANDLE,...};
new bool:g_bIsDucking[MAXPLAYERS+2] = {false,...};

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
	g_hCVTime = CreateConVar("sm_antiduck_time", "0", "How long in seconds should a player be disallowed to duck after standing up?", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCVTeam, ConVar_Team);
	HookConVarChange(g_hCVTime, ConVar_Time);
}

public OnConfigsExecuted()
{
	g_iRestrictTeam = GetConVarInt(g_hCVTeam);
	g_fRestrictTime = GetConVarFloat(g_hCVTime);
}

public OnClientDisconnect(client)
{
	g_bIsDucking[client] = false;
	if(g_hAllowDuckTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hAllowDuckTimer[client]);
		g_hAllowDuckTimer[client] = INVALID_HANDLE;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_iRestrictTeam == 0)
		return Plugin_Continue;
	
	// Disallow ducking, if player is in restricted team
	if(buttons & IN_DUCK)
	{
		g_bIsDucking[client] = true;
		
		// player ducked before and isn't allowed now?
		if((g_fRestrictTime == 0.0 
		|| g_hAllowDuckTimer[client] != INVALID_HANDLE)
		// player is in restricted team
		&& (g_iRestrictTeam == 1 
		|| g_iRestrictTeam == GetClientTeam(client)))
		{
			buttons &= ~IN_DUCK;
			return Plugin_Changed;
		}
	}
	else if(g_bIsDucking[client])
	{
		g_bIsDucking[client] = false;
		g_hAllowDuckTimer[client] = CreateTimer(g_fRestrictTime, Timer_AllowDucking, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:Timer_AllowDucking(Handle:timer, any:client)
{
	g_hAllowDuckTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public ConVar_Team(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	g_iRestrictTeam = StringToInt(newValue);
}

public ConVar_Time(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// don't execute if it's unchanged
	if(StrEqual(oldValue, newValue))
		return;
	
	g_fRestrictTime = StringToFloat(newValue);
}