#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[TF2] Snipers must zoom before firing",
	author = "PC Gamer",
	description = "Forces Snipers to use zoom/scope before firing sniperrifle",
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
	if (IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(!IsValidEntity(Weapon))
		return;
		
		char sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));
		if (StrContains(sWeapon, "sniperrifle") != -1)
		{
			TF2Attrib_SetByName(Weapon, "sniper only fire zoomed", 1.0);
			//PrintToChatAll("Debug: Found Sniper named %N holding a sniperrifle", client);					
		}
		return;
	}
}

stock bool IsValidClient(int client)
{ 
	if (client <= 0 || client > MaxClients)
	{
		return false; 
	}
	return IsClientInGame(client); 
}