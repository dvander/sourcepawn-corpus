#include <sourcemod>
#include <sdktools>
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
	decl String:weapon_name[32]; 
    GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
	
	if(StrEqual(weapon_name, "weapon_healthshot", false)) {
    RemoveEdict(weapon); 
	GivePlayerItem(client, weapon_name)
	}
	return Plugin_Continue;
}  