#pragma semicolon 1

#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[TF2] Give Diamondback Rockets",
	author = "PC Gamer",
	description = "Replace Diamondback bullets with rockets",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public void OnPluginStart()
{
	HookEvent("post_inventory_application", EventInventoryApplication);	
}

public void EventInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (TF2_GetPlayerClass(client) == TFClass_Spy && !IsFakeClient(client))
	{
		int myslot0 = GetIndexOfWeaponSlot(client, 0);
		if(myslot0 == 525)//Diamondback
		{
			CreateTimer(1.0, FixDiamondback, client);			
		}
	}
}

Action FixDiamondback(Handle timer, int client) 
{
	int weapon = GetPlayerWeaponSlot(client, 0); 
	TF2Attrib_SetByName(weapon, "override projectile type", 2.0);	
	TF2Attrib_SetByName(weapon, "damage bonus", 3.0);
		
	return Plugin_Handled;
}

int GetIndexOfWeaponSlot(int iClient, int iSlot)
{
	return GetWeaponIndex(GetPlayerWeaponSlot(iClient, iSlot));
}


int GetWeaponIndex(int iWeapon)
{
	return IsValidEnt(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock bool IsValidEnt(int iEnt)
{
	return iEnt > MaxClients && IsValidEntity(iEnt);
}