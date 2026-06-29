#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
 
public Plugin myinfo =
{
	name = "[L4D]Rescuers are armed",
	author = "紫冰",
	description = "Default resupply of weapons by rescued survivors",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	HookEvent("survivor_rescued", srescued);
	RegAdminCmd("sm_fzb", Command_GiveWeapon, ADMFLAG_KICK, "Issuance of weapons to survivors.");
}

void srescued(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		StripWeapons(client);
		GiveWeapon(client);
	}
}

Action Command_GiveWeapon(int client, int args)
{
	GiveWeapon(client);
}

stock void StripWeapons(int client) // strip all items from client
{
	int itemIdx;
	for (int x = 0; x <= 3; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{
			RemovePlayerItem(client, itemIdx);
			RemoveEdict(itemIdx);
		}
	}
}

stock void GiveWeapon(int client) // give client random weapon
{
	switch(GetRandomInt(0, 2))
	{
		case 0: GivePlayerItem(client, "weapon_smg");
		case 1: GivePlayerItem(client, "weapon_pumpshotgun");
		case 2: GivePlayerItem(client, "weapon_hunting_rifle");
	}
	GivePlayerItem(client, "ammo");
	GivePlayerItem(client, "weapon_pistol");
}
