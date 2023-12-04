#include <sourcemod>
#include <sdkhooks>
 
public Plugin myinfo =
{
	name = "Block Weapon Drop",
	author = "Potatoz",
	description = "Blocks weapons from being dropped",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponDrop, Event_WeaponDrop);
}

public Action:Event_WeaponDrop(client,weapon)
{
    Plugin_Handled;
}  