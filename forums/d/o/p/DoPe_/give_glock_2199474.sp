#include <sourcemod>
#include <sdktools>

#define NAME "Give Glock"
#define AUTHOR "DoPe^"
#define DESCRIPTION "Gives a glock."
#define VERSION "1.0"
#define URL "https://forums.alliedmods.net/showthread.php?t=248145"

public OnPluginStart()
{
	CreateConVar("sm_give_glock", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_glock", Give_Glock, "Gives a glock.");
}

DropPlayerWeaponOnSlot(client,slot)
{
	new weapon_index=-1;
	new String:weapon_string[20];
	// if client has a weapon on slot and string is available
	if(((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		&& GetEdictClassname(weapon_index, weapon_string, 20))
	{
		// give the same weapon to client (gets dropped)
		//GivePlayerItem(client,weapon_string);
		// remove weapon from client
		RemovePlayerItem(client, weapon_index);
	}
}

public Action:Give_Glock(client, args)
{
	if(IsPlayerAlive(client) && IsClientInGame(client))
	{
		DropPlayerWeaponOnSlot(client,1);
		GivePlayerItem(client, "weapon_glock");
	}

	return Plugin_Handled;
}