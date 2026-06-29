#include <sdkhooks>

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, wep)
{
	if (wep == -1) return Plugin_Continue;
	new String:classname[20];
	GetEdictClassname(wep, classname, sizeof(classname));
	if (!StrContains(classname, "tf_weapon_parachute", false)) return Plugin_Stop;
	return Plugin_Continue;
}