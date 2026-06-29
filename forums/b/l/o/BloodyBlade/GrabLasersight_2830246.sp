#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1.1"
#define L4D2_WEPUPGFLAG_LASER     (1 << 2)

public Plugin myinfo =
{
    name = "Auto grab laser sight",
    author = "WolfGang",
    description = "Laser Sight on weapon pickup",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
	ConVar cvar = CreateConVar("autograblasersight_version", PLUGIN_VERSION, "AutoGrabLaserSight Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar.SetString(PLUGIN_VERSION);
}

public void OnAllPluginsLoaded()
{
	/* For plugin reloading in mid game */
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsClientAuthorized(client))
		{
			SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
			SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (client > 0)
	{
		SDKHook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKHook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
	}
}

public void OnClientDisconnect(int client)
{
	if (client > 0)
	{
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnClientWeaponEquip);
		SDKUnhook(client, SDKHook_WeaponDropPost, OnClientWeaponDrop);
	}
}

void OnClientWeaponEquip(int client, int weapon)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int priWeapon = GetPlayerWeaponSlot(client, 0); // Get primary weapon
		if (priWeapon > 0 && IsValidEntity(priWeapon))
		{
			char netclass[128];
			GetEntityNetClass(priWeapon, netclass, 128);
			if (FindSendPropInfo(netclass, "m_upgradeBitVec") > 0)
			{
				int upgrades = L4D2_GetWeaponUpgrades(priWeapon); // Get upgrades of primary weapon
				if (!(upgrades & L4D2_WEPUPGFLAG_LASER))
				{
					L4D2_SetWeaponUpgrades(priWeapon, upgrades | L4D2_WEPUPGFLAG_LASER); // Add laser sight to primary weapon
				}
			}
		}
	}
}

void OnClientWeaponDrop(int client, int weapon)
{
	if (IsValidClient(client))
	{
		if (weapon > 0 && IsValidEntity(weapon))
		{
			char netclass[128];
			GetEntityNetClass(weapon, netclass, 128);
			if (FindSendPropInfo(netclass, "m_upgradeBitVec") > 0)
			{
				int upgrades = L4D2_GetWeaponUpgrades(weapon); // Get upgrades of dropped weapon
				if (upgrades & L4D2_WEPUPGFLAG_LASER)
				{
					L4D2_SetWeaponUpgrades(weapon, upgrades ^ L4D2_WEPUPGFLAG_LASER); // Remove laser sight from weapon
				}
			}
		}
	}
}

stock int L4D2_GetWeaponUpgrades(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

stock void L4D2_SetWeaponUpgrades(int weapon, int upgrades)
{
	SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrades);
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}
