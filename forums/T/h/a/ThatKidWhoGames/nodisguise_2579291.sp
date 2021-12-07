#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = {
	name 		= "Remove Spy Disguise Kit",
	author 		= "Sgt. Gremulock",
	description = "Look at the title.",
	version 	= "1.0",
	url 		= "sourcemod.net"
};

public void OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsValidClient(client))
	{
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
		}
	}
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}

	return IsClientInGame(client);
}