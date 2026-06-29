#include <sourcemod>
//#include <sdktools>
#include <left4dhooks>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

Handle l4d1_tank_release_enable;

public Plugin myinfo = 
{
	name = "Tank Release",
	author = "Axel Juan Nieves",
	description = "Tanks will release their victim after incapacitating them, just like L4D2's Tanks",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	
	CreateConVar("l4d1_tank_release_ver", PLUGIN_VERSION, "Version of the tank release plugin.", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	l4d1_tank_release_enable = CreateConVar("l4d1_tank_release_enable", "1", "Enable/Disable this plugin", 0);

	AutoExecConfig(true, "l4d1_tank_release");
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{	
	if ( !GetConVarBool(l4d1_tank_release_enable) )
		return Plugin_Continue;
	if ( !IsPlayerTank(specialInfected) )
		return Plugin_Continue;
	if ( !IsValidClientAlive(curTarget) )
		return Plugin_Continue;
	if ( !IsSurvivorIncapacitated(curTarget) )
		return Plugin_Continue;
	
	int iClosestSurvivor;
	
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		if ( !IsValidClientInGame(i) ) continue;
		if ( GetClientTeam(i)!=TEAM_SURVIVOR ) continue;
		if ( !IsPlayerAlive(i) ) continue;
		if ( i==curTarget ) continue;
		if ( IsSurvivorIncapacitated(i) ) continue;
			
		//set new victim first time...
		if ( iClosestSurvivor==0 )
			iClosestSurvivor = i;
		
		//check for a closest new victim...
		if ( ClientsDistance(specialInfected, i) < ClientsDistance(specialInfected, iClosestSurvivor) )
		{
			iClosestSurvivor = i;
		}
	}
	
	//let's ensure everything above was right...
	if ( !IsValidClientAlive(iClosestSurvivor) )
		return Plugin_Continue;
	if ( IsSurvivorIncapacitated(iClosestSurvivor) )
		return Plugin_Continue;
	
	//PrintToChatAll("New Target should be: %N", iClosestSurvivor);
	//PrintToServer("New Target should be: %N", iClosestSurvivor);
	
	curTarget = iClosestSurvivor;
	return Plugin_Changed;
}

stock float ClientsDistance(int client1, int client2)
{
	if ( !IsValidClientAlive(client1) )
		return -1.0
	if ( !IsValidClientAlive(client2) )
		return -1.0
	
	float fPos1[3], fPos2[3];
	GetClientAbsOrigin(client1, fPos1);
	GetClientAbsOrigin(client2, fPos2);
	
	return GetVectorDistance(fPos1, fPos2);
}

stock int IsSurvivorIncapacitated(int client)
{
	if ( !IsValidClientAlive(client) )
		return 0;
	if ( GetClientTeam(client)!=TEAM_SURVIVOR )
		return 0;
	
	return GetEntProp(client, Prop_Send, "m_isIncapacitated");
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

stock bool IsValidClientAlive(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
	
	if ( !IsPlayerAlive(client) )
		return false;
	
	return true;
}

stock int IsPlayerTank(int client)
{
	if ( GetEntProp(client, Prop_Send, "m_zombieClass") >= 5 )
		return 1;
	
	return 0;
}