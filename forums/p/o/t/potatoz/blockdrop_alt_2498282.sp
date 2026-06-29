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

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, Event_WeaponDrop);
}

public Action:Event_WeaponDrop(client,weapon)
{
	new String:weapon_name[30];
    GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));

	if(StrEqual(weapon_name, "weapon_healthshot", false))
	return Plugin_Handled;
	else
	return Plugin_Continue;
}  