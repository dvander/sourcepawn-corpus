#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <tf2items_giveweapon>

new TF2ItemSlot = 8;
 
public Plugin:myinfo =
{
	name = "[TF2] Pyro Battle",
	author = "Bitl",
	description = "A gamemode where pyros fight eachother.",
	version = "1.0",
	url = ""
};
 
public OnPluginStart()
{
	HookEvent( "post_inventory_application", OnPostInventoryApplicationAndPlayerSpawn );
	HookEvent( "player_spawn", OnPostInventoryApplicationAndPlayerSpawn );
}

public OnPostInventoryApplicationAndPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) )
	
	for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
		TF2_RemoveWeaponSlot( iClient, iSlot );
	
	TF2Items_GiveWeapon(iClient, 9990);
		
	TF2_RemoveWeaponSlot(iClient, 1);
	TF2_RemoveWeaponSlot(iClient, 2);
	
	TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true)
}