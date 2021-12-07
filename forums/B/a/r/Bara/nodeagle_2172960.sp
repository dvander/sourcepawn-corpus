#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "No Deagle",
	author = "Bara",
	description = "",
	version = "1.0",
	url = "www.bara.in"
};

public OnClientPutInServer(i)
{
	SDKHook(i, SDKHook_WeaponCanUse, OnWeapon);
	SDKHook(i, SDKHook_WeaponCanSwitchTo, OnWeapon);
	SDKHook(i, SDKHook_WeaponSwitch, OnWeapon);
	SDKHook(i, SDKHook_WeaponEquip, OnWeapon);
}

public Action:OnWeapon(client, weapon)
{
	decl String:sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));

	if(StrEqual(sWeapon, "deagle"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}