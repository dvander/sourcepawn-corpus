#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define L4D2_ZOMBIECLASS_TANK	8

#define PLUGIN_VERSION	"1.2"

ConVar l4d2_molotov_damage_tank_enable;
ConVar l4d2_molotov_damage_tank_announce;

int g_iDamage[MAXPLAYERS+1][MAXPLAYERS+1];
int g_iEmptyArray[MAXPLAYERS+1];

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
	l4d2_molotov_damage_tank_announce = CreateConVar("l4d2_molotov_damage_tank_announce", "0", "Notify real damage done to Tank when he dies. 0=Dont notify, 1=notify to chat, 2=notify to hint box", 0, true, 0.0, true, 2.0);
	l4d2_molotov_damage_tank_enable = CreateConVar("l4d2_molotov_damage_tank_enable", "1", "Enable/Disable this plugin.", FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d2_molotov_damage_tank");
	HookEvent("player_death", event_player_death, EventHookMode_Pre); //hook special infected deaths
	HookEvent("round_end", event_round_);
	HookEvent("round_start", event_round_);
}

public void OnClientPutInServer(int client)
{
	//SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_iDamage[client] = g_iEmptyArray;
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnClientDisconnect(int client)
{
	g_iDamage[client] = g_iEmptyArray;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if ( !GetConVarBool(l4d2_molotov_damage_tank_enable) )
		return Plugin_Continue;
	if ( !IsValidClientInGame(victim) )
	{
		if ( IsValidClientIndex(victim) )
			g_iDamage[victim] = g_iEmptyArray;
		return Plugin_Continue;
	}
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
	if ( GetEntProp(victim, Prop_Send, "m_isIncapacitated") )
		return Plugin_Continue;
	
	//collect damage done to tank:
	if ( GetConVarInt(l4d2_molotov_damage_tank_announce) > 0 )
		g_iDamage[victim][attacker] += RoundFloat(damage);
	
	return Plugin_Continue;
}

public Action event_player_death(Handle event, char[] event_name, bool dontBroadcast)
{
	if ( GetConVarInt(l4d2_molotov_damage_tank_announce) == 0 )
		return Plugin_Continue;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsValidClientInGame(client) )
	{
		if ( IsValidClientIndex(client) )
			g_iDamage[client] = g_iEmptyArray;
		return Plugin_Continue;
	}
		
	if ( GetZombieClass(client)!=L4D2_ZOMBIECLASS_TANK )
		return Plugin_Continue;
		
	char statistics[128];
	int totalDamage;
	
	//Add prefix to chat announce only:
	if ( GetConVarInt(l4d2_molotov_damage_tank_announce) == 1 )
		FormatEx(statistics, sizeof(statistics), "[MoloTankDmg] %N: ", client);
		
	//lets check damage done by every survivor:
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		if ( !IsValidClientInGame(i) )
			continue;
		if ( GetClientTeam(i)!=TEAM_SURVIVOR )
			continue;
		//dont include people who didn't cause damage to tank:
		if ( g_iDamage[client][i]<=0 )
			continue;
			
		totalDamage += g_iDamage[client][i];
			
		//chat announce:
		if ( GetConVarInt(l4d2_molotov_damage_tank_announce) == 1 )
		{
			FormatEx(statistics, sizeof(statistics), "%s %N(%i), ", statistics, i, g_iDamage[client][i]);
		}
		//hint announce:
		else
		{
			FormatEx(statistics, sizeof(statistics), "%s %N(%i)\n", statistics, i, g_iDamage[client][i]);
		}
	}
	
	if ( totalDamage<=0 )
	{
		return Plugin_Continue;
	}
	
	//finally show damage done:
	int len = strlen(statistics);
	if ( GetConVarInt(l4d2_molotov_damage_tank_announce) == 1 )
	{
		//let's remove last comma and blank space at the ending of string:
		statistics[len-1] = '\0';
		statistics[len-2] = '\0';
		PrintToChatAll(statistics);
	}
	else
	{
		//let's remove last blank line at the ending of string:
		statistics[len-1] = '\0';
		PrintHintTextToAll(statistics);
	}
	return Plugin_Continue;
}

public Action event_round_(Handle event, char[] event_name, bool dontBroadcast)
{
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		g_iDamage[i] = g_iEmptyArray;
	}
	return Plugin_Continue;
}
public int SortByDamageDesc(int[] x, int[] y, int[][] array, Handle data)
{
	if (x[0] > y[0]) 
        return -1;
    /*else if (x[1] < y[1]) 
        return 1;    
    return 0;*/
	return  x[0] < y[0];
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