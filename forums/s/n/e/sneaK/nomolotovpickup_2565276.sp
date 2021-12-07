#pragma newdecls required

#define PLUGIN_AUTHOR "CodingCow"
#define PLUGIN_VERSION "1.00"

#include <sdkhooks>

public Plugin myinfo =
{
	name = "Block Molotov",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, EventPickup);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponEquip, EventPickup);
}

public Action EventPickup(int client, int entity)
{
	char weapon[50];
	GetEntPropString(entity, Prop_Data, "m_iName", weapon, sizeof(weapon));
	
	if(StrEqual(weapon, "weapon_molotov"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}