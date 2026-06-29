#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo =
{
	name = "[L4D]Rescuers are armed",
	author = "紫冰",
	description = "Default resupply of weapons by rescued survivors",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("survivor_rescued", srescued);
	RegAdminCmd("sm_fzb", Command_GiveWeapon, ADMFLAG_KICK, "Issuance of weapons to survivors.");
}

public srescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"))
	if(client)
	{	
		StripWeapons(client)
		GiveCommand(client, "give", "pistol")
		GiveWeapon(client)
	}

}

public Action:Command_GiveWeapon(client, args)
{
	GiveWeapon(client)
}

stock StripWeapons(client) // strip all items from client
{
	new itemIdx
	for (new x = 0; x <= 3; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx)
			RemoveEdict(itemIdx)
		}
	}
}



stock GiveCommand(client, String: strCommand[], String: strParam1[])
{
	new flags = GetCommandFlags(strCommand)
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT)
	FakeClientCommand(client, "%s %s", strCommand, strParam1)
	SetCommandFlags(strCommand, flags)
}

stock GiveWeapon(client) // give client random weapon
{
	switch(GetRandomInt(0,2))
	{
		case 0: GiveCommand(client, "give", "smg")
		case 1: GiveCommand(client, "give", "pumpshotgun")
		case 2: GiveCommand(client, "give", "hunting_rifle")
	}	
	GiveCommand(client, "give", "ammo")
}

