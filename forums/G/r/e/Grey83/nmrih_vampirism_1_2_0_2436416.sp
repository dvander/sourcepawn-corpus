#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION 	"1.2.0"
#define PLUGIN_NAME		"[NMRiH] Health Vampirism"

ConVar hEnable = null;
bool bEnable;
ConVar hMax = null;
int iMax;
ConVar hKill = null;
int iKill;
ConVar hHS = null;
int iHS;
ConVar hFire = null;
int iFire;

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Undeadsewer (rewrited by Grey83)",
	description	= "Leech health from killed zombies",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=252077"
};

public void OnPluginStart()
{
	CreateConVar("nmrih_vampirism_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnable = CreateConVar("sm_vampirism_enable", "1", "Enables/Disables the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	hMax = CreateConVar("sm_vampirism_max", "100", "The maximum amount of health, which can get a player for killing zombies", FCVAR_NONE, true, 100.0);
	hKill = CreateConVar("sm_vampirism_kill", "5", "Health gained from kill", FCVAR_NONE, true, 0.0);
	hHS = CreateConVar("sm_vampirism_headshot", "10", "Health gained from headshot", FCVAR_NONE, true, 0.0);
	hFire = CreateConVar("sm_vampirism_fire", "5", "Health gained from burning zombie", FCVAR_NONE, true, 0.0);

	bEnable = GetConVarBool(hEnable);
	iMax = GetConVarInt(hMax);
	iKill = GetConVarInt(hKill);
	iHS = GetConVarInt(hHS);
	iFire = GetConVarInt(hFire);

	HookConVarChange(hEnable, OnConVarChanged);
	HookConVarChange(hMax, OnConVarChanged);
	HookConVarChange(hKill, OnConVarChanged);
	HookConVarChange(hHS, OnConVarChanged);
	HookConVarChange(hFire, OnConVarChanged);

	HookEvent("npc_killed", Event_Killed);
	HookEvent("zombie_head_split", Event_Headshot);
	HookEvent("zombie_killed_by_fire", Event_Fire);

	AutoExecConfig(true, "nmrih_vampirism");

	PrintToServer("[NMRiH] Health Vampirism v.%s has been successfully loaded!", PLUGIN_VERSION);	// Indicates that plugin has loaded.
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hEnable) bEnable = view_as<bool>(StringToInt(newValue));
	else if(convar == hMax) iMax = StringToInt(newValue);
	else if(convar == hKill) iKill = StringToInt(newValue);
	else if(convar == hHS) iHS= StringToInt(newValue);
	else if(convar == hFire) iFire = StringToInt(newValue);
}

public void Event_Killed(Event event, const char[] name, bool dontBroadcast)
{
	Heal(GetEventInt(event, "killeridx"), iKill);
}

public void Event_Headshot(Event event, const char[] name, bool dontBroadcast)
{
	Heal(GetEventInt(event, "player_id"), iHS);
}

public void Event_Fire(Event event, const char[] name, bool dontBroadcast)
{
	Heal(GetEventInt(event, "igniter_id"), iFire);
}

void Heal(int client, int heal)
{
	if(bEnable)
	{
		if(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client))
		{
			int health = GetClientHealth(client) + heal;
			SetEntityHealth(client, health >= iMax ? iMax : health);
		}
	}
}