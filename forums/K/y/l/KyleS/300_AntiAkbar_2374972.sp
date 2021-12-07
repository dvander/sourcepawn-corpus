#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo =
{
    name 			=		"Day of Defeat: Anti-Akbar",				/* https://www.youtube.com/watch?v=7xo08OVOKSY&hd=1 */
    author			=		"Kyle Sanderson",
    description		=		"Prevents Clients from pulling a grenade, then quick switching to another weapon.",
    version			=		"1.0",
    url				=		"http://AlliedMods.net"
};

public OnPluginStart()
{
	for (new i = MaxClients; i > 0; --i)
	{
		if (!IsClientInGame(i))
			continue;
		
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{ /* Whatever, man. */
	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, weapon)
{
	if (!IsClientInGame(client) || (GetClientButtons(client) & IN_ATTACK) != IN_ATTACK)
		return Plugin_Continue;

	return Plugin_Handled;
}
