#pragma semicolon 1

#define	PLUGIN_AUTHOR	"[W]atch [D]ogs"
#define PLUGIN_VERSION	"1.0"

#include <sourcemod>

#pragma newdecls required

Handle h_bEnable;
Handle h_iHP;
Handle h_iTime;

public Plugin myinfo = 
{
	name = "Health On Spawn", 
	author = PLUGIN_AUTHOR, 
	description = "Gives x amount of health to client on spawn and take it after x seconds", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=299634"
};

public void OnPluginStart()
{
	h_bEnable = CreateConVar("sm_spawnhp_enable", "1", "Enable / Disable plugin", _, true, 0.0, true, 1.0);
	h_iHP = CreateConVar("sm_spawnhp_hp", "20000", "Amount of hp to set for client on spawn");
	h_iTime = CreateConVar("sm_spawnhp_time", "7", "Time of keeping hp in seconds", _, true, 1.0);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetConVarBool(h_bEnable))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntityHealth(client, GetConVarInt(h_iHP));
		CreateTimer(GetConVarFloat(h_iTime), Timer_RemoveGivenHP, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RemoveGivenHP(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(IsClientInGame(client))
	{
		SetEntityHealth(client, 100);
	}
}
