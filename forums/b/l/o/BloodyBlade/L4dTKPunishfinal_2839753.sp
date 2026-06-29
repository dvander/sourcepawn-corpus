#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0.0.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Left 4 Dead Teamkill disable",
	author = "Joshua Coffey",
	description = "Kills TKers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

ConVar g_hEnabled;
bool bHooked = false;

public void OnPluginStart()
{
	CreateConVar("l4d_mirror_version", PLUGIN_VERSION, "Left 4 Dead Teamkill disable plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("l4d_mirror_enabled", "1", "Sets whether the Teamkill Punisher plugin is turned on.", CVAR_FLAGS);
	AutoExecConfig(true, "l4d_mirror");
	g_hEnabled.AddChangeHook(OnConVarPluginOnChange);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = g_hEnabled.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("player_hurt", Event_PlayerHurt);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_hurt", Event_PlayerHurt);
	}
}
 
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int dmgminus = GetClientHealth(attacker);
	int dmgdeal = dmgminus - event.GetInt("dmg_health");
	if (IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(victim) == GetClientTeam(attacker) && dmgminus >= 3 && dmgdeal >= 1 && dmgdeal <= 100)
	{
		SetEntityHealth(attacker, dmgdeal);
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
