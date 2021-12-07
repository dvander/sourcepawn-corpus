#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <tf2items_giveweapon>

new TF2ItemSlot = 8;
 
public Plugin:myinfo =
{
	name = "SmootheBrainBan",
	author = "Jerem",
	description = "Accessable TF2",
	version = "0.1",
	url = ""
};
 
public OnPluginStart()
{
	HookEvent( "post_inventory_application", OnPostInventoryApplicationAndPlayerSpawn );
}

public OnPostInventoryApplication( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) )
	
	for( new iSlot = 0; iSlot < _:TF2ItemSlot; iSlot++ )
		TF2_RemoveWeaponSlot( iClient, iSlot );
	
    if (TF2_GetPlayerClass(iClient) == TFClass_Scout)
    {
        TF2Items_GiveWeapon(iClient, 17);
        TF2Items_GiveWeapon(iClient, 29);
    } 
	
}