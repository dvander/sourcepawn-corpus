#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define L4D2_ZOMBIECLASS_TANK	8

#define PLUGIN_VERSION	"1.1"

ConVar l4d_molotov_damage_tank_enable;

public Plugin myinfo = 
{
	name = "L4D2 Dont show molotov damage to tank", 
	author = "Axel Juan Nieves", 
	description = "This plugin shows only bullets/explosions/melee damage done to tank on stats screen (just like l4d1)", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?p=2732130"
};

public void OnPluginStart()
{
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if ( !StrEqual(GameName, "left4dead2", false) )
		SetFailState("Plugin supports Left 4 Dead 2 only.");
		
	CreateConVar("l4d_molotov_damage_tank_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD);
	l4d_molotov_damage_tank_enable = CreateConVar("l4d_molotov_damage_tank_enable", "1", "Enable/Disable this plugin.", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_molotov_damage_tank");
}

public void OnClientPutInServer(int client)
{
	//this is not a convenient place to check if plugin is enabled...
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if ( !GetConVarBool(l4d_molotov_damage_tank_enable) )
		return Plugin_Continue;
	if ( !IsValidClientInGame(victim) )
		return Plugin_Continue;
	if ( !IsValidClientInGame(attacker) )
		return Plugin_Continue;
	if ( GetClientTeam(victim)!=TEAM_INFECTED )
		return Plugin_Continue;
	if ( GetZombieClass(victim)!=L4D2_ZOMBIECLASS_TANK )
		return Plugin_Continue;
	if ( damagetype==DMG_BURN )
	{
		inflictor = 0;
		attacker = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock int GetZombieClass(int client)
{
	if ( !IsValidClientInGame(client) )
		return 0;
	if ( !HasEntProp(client, Prop_Send, "m_zombieClass") )
		return 0;
	//L4D1->1:smoker, 2:boomer, 3:hunter, 5:tank
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
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