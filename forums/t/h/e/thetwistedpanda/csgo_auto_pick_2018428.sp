#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hFactor = INVALID_HANDLE;

new g_iEnabled;
new Float:g_fFactor;

public Plugin:myinfo =
{
	name = "[CS:GO] Auto Pick",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "Simply raises the duration",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmodders.com"
}

public OnPluginStart()
{
	CreateConVar("csgo_auto_pick_version", PLUGIN_VERSION, "[CS:GO] Auto Pick: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("csgo_auto_pick_enabled", "1", "Enables/disables all features of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarInt(g_hEnabled);

	g_hFactor = CreateConVar("csgo_auto_pick_factor", "0.0", "The factor, in seconds, applied to the client's auto pick time remaining. (0.0 = Instant, 60.0 = 1 Minute)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hFactor, OnCVarChange);
	g_fFactor = GetConVarFloat(g_hFactor);
	AutoExecConfig(true, "csgo_auto_pick");
	
	HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Pre);
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = StringToInt(newvalue);
	}	
	else if(cvar == g_hFactor)
	{
		g_fFactor = StringToFloat(newvalue);
	}
}

public Action:Event_OnFullConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_iEnabled)
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	SetEntPropFloat(client, Prop_Send, "m_fForceTeam", g_fFactor);
	return Plugin_Continue;
}