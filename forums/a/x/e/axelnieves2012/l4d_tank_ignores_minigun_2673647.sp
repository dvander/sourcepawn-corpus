#include <sourcemod>
#include <sdkhooks>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

public Plugin myinfo = 
{
	name = "Tank Ignores Minigun",
	author = "Axel Juan Nieves",
	description = "Tanks will ignore miniguns",
	version = PLUGIN_VERSION,
	url = ""
}

Handle l4d_tank_ignores_minigun_enable

public void OnPluginStart()
{
	
	CreateConVar("l4d_tank_ignores_minigun_ver", PLUGIN_VERSION, "", 0);
	l4d_tank_ignores_minigun_enable = CreateConVar("l4d_tank_ignores_minigun_enable", "1", "Enable/Disable this plugin", 0);

	AutoExecConfig(true, "l4d_tank_ignores_minigun");
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if ( StrEqual("prop_minigun", classname, false) )
		SDKHook(ent, SDKHook_Use, OnEntityUse);
}

public Action OnEntityUse(int ent, int client)
{
	if ( !GetConVarBool(l4d_tank_ignores_minigun_enable) )
		return Plugin_Continue;

	//int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( !IsValidClientInGame(client) )
		return Plugin_Continue;

	if ( !IsPlayerAlive(client) )
		return Plugin_Continue;

	if ( GetClientTeam(client)!=TEAM_SURVIVOR )
		return Plugin_Continue;

	SetEntProp(client, Prop_Send, "m_usingMinigun", 0);
			
	return Plugin_Continue;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}