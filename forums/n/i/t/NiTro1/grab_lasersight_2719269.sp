#include <sourcemod>
#include <l4d_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
    name = "Auto grab laser sight",
    author = "NiTro & WolfGang",
    description = "Laser Sight on weapon pickup",
    version = PLUGIN_VERSION,
    url = "play-alliance.com"
}

public OnPluginStart()
{
	CreateConVar("autograblasersight_version", PLUGIN_VERSION, "AutoGrabLaserSight Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnAllPluginsLoaded()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsClientAuthorized(client)) continue;
		SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
	}
}

public OnClientPostAdminCheck(client)
{
	if (client <= 0) return;

	SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
	SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
}

public OnClientDisconnect(client)
{
	if (client <= 0) return;

	SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
}

public OnClientWeaponEquip(client, weapon)
{
	if (client <= 0 || !IsClientInGame(client) || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor || !IsPlayerAlive(client)) return;

	new priWeapon = GetPlayerWeaponSlot(client, _:L4DWeaponSlot_Primary);
	if (priWeapon <= 0 || !IsValidEntity(priWeapon)) return;

	decl String:netclass[128];
	GetEntityNetClass(priWeapon, netclass, 128);
	if (FindSendPropInfo(netclass, "m_upgradeBitVec") < 1) return;

	new upgrades = L4D2_GetWeaponUpgrades(priWeapon);
	if (upgrades & L4D2_WEPUPGFLAG_LASER) return;

	L4D2_SetWeaponUpgrades(priWeapon, upgrades | L4D2_WEPUPGFLAG_LASER);
}

public OnClientWeaponDrop(client, weapon)
{
	if (client <= 0 || !IsClientInGame(client) || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor) return;
	if (weapon <= 0 || !IsValidEntity(weapon)) return;

	decl String:netclass[128];
	GetEntityNetClass(weapon, netclass, 128);
	if (FindSendPropInfo(netclass, "m_upgradeBitVec") < 1) return;

	new upgrades = L4D2_GetWeaponUpgrades(weapon);
	if (!(upgrades & L4D2_WEPUPGFLAG_LASER)) return;

	L4D2_SetWeaponUpgrades(weapon, upgrades ^ L4D2_WEPUPGFLAG_LASER);
}