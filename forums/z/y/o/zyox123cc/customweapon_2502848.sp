#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <tf2items_giveweapon>
#pragma tabsize 0

new TF2ItemSlot = 8;
 
public Plugin:myinfo =
{
	name = "[TF2] Custom war",
	author = "Zyox123cc",
	description = "kiss me.",
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
	
		
	TF2_RemoveWeaponSlot(iClient, 1);
	TF2_RemoveWeaponSlot(iClient, 2);
	
	if (TF2_GetPlayerClass(iClient) == TFClass_Medic)
    {
        TF2Items_GiveWeapon(iClient, 305);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_Sniper)
    {
        TF2Items_GiveWeapon(iClient, 56);
		TF2Items_GiveWeapon(iClient, 642);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_Engineer)
    {
        TF2Items_GiveWeapon(iClient, 7005);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_Soldier)
    {
        TF2Items_GiveWeapon(iClient, 7006);
		TF2Items_GiveWeapon(iClient, 416);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_Scout)
    {
        TF2Items_GiveWeapon(iClient, 812);
		TF2Items_GiveWeapon(iClient, 44);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_Heavy)
    {
        TF2Items_GiveWeapon(iClient, 42);
		TF2Items_GiveWeapon(iClient, 656);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_Pyro)
    {
        TF2Items_GiveWeapon(iClient, 7000);
		TF2Items_GiveWeapon(iClient, 7004);
    } 
	if (TF2_GetPlayerClass(iClient) == TFClass_DemoMan)
	{
	    TF2Items_GiveWeapon(iClient, 131);
		TF2Items_GiveWeapon(iClient, 132);
	}
	if (TF2_GetPlayerClass(iClient) == TFClass_Spy)
    {
        TF2Items_GiveWeapon(iClient, 7003);
    }
}