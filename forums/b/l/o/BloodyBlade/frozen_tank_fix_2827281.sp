#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "2.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Fix frozen tanks",
	version = PL_VERSION,
	author = "sheo",
}

ConVar hPluginOn;
static bool bHooked = false;

public void OnPluginStart()
{
	CreateConVar("l4d2_fix_frozen_tank_version", PL_VERSION, "Frozen tank fix version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("l4d2_fix_frozen_tank_plugin_on", "1", "Plugin On/Off.", CVAR_FLAGS);
	AutoExecConfig(true, "l4d2_fix_frozen_tank");
	hPluginOn.AddChangeHook(OnConVarChanged_Allow);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarChanged_Allow(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("player_incapacitated", Event_PlayerIncap);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_incapacitated", Event_PlayerIncap);
	}
}

void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && IsPlayerTank(client))
	{
		CreateTimer(1.0, KillTank_tCallback);
	}
}

Action KillTank_tCallback(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerTank(i) && IsIncapitated(i))
		{
			ForcePlayerSuicide(i);
		}
	}
	return Plugin_Stop;
}

bool IsIncapitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

bool IsPlayerTank(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}
