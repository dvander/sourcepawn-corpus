//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <cstrike>

public Plugin myinfo = 
{
	name = "Drop Weapon On Empty", 
	author = "Keith Warren (Sky Guardian)", 
	description = "Forces bots to drop their weapons whenever they're empty.", 
	version = "1.0.0", 
	url = "https://github.com/SkyGuardian"
};

public void OnPluginStart()
{
	HookEvent("weapon_fire_on_empty", Event_FireOnEmpty);
}

public void Event_FireOnEmpty(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	//bots only
	if (!IsFakeClient(client))
	{
		return;
	}
	
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	//probably don't need this check but better safe than sorry.
	if (!IsValidEntity(active))
	{
		return;
	}
	
	CS_DropWeapon(client, active, true, false);
}