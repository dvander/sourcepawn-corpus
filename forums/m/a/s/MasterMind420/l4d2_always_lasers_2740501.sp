#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define L4D2_WEPUPGFLAG_LASER  (1 << 2)

public Plugin myinfo =
{
    name = "[L4D2] Always Lasers",
    author = "MasterMind420",
    description = "",
    version = "1.0",
    url = ""
};

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

public Action OnWeaponDrop(int client, int weapon)
{
	if (IsValidClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsValidEntity(weapon))
	{
		if (HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
			SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", 0);
	}
}

public Action OnWeaponSwitch(int client, int weapon)
{
	if (IsValidClient(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsValidEntity(weapon))
	{
		if (HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
		{
			if (!(GetEntProp(weapon, Prop_Send, "m_upgradeBitVec") & L4D2_WEPUPGFLAG_LASER))
				SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", L4D2_WEPUPGFLAG_LASER);
		}
	}
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}