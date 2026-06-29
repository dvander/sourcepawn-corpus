#pragma semicolon 1
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Hide viewmodel",
	author = "Mitch",
	description = "Simple Script",
	version = "0.1.0",
	url = "SnBx.info"
}

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			SDKHook(i, SDKHook_WeaponCanSwitchToPost, WeaponSwitch);
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchToPost, WeaponSwitch);
}

public Action:WeaponSwitch(client, weapon)
{
	if(IsValidEntity(weapon))
	{
		new wepID = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"); 
		switch(wepID)
		{
			case 1337,52: //Add the item index here (seperate with commas!)
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
			default:
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		}
	}
	return Plugin_Continue;
}