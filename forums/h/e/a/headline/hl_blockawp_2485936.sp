#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "[CS:GO/CSS] Block AWP for non-VIPs",
    author = "Headline",
    description = "Doesn't allow certain clients to use an AWP",
    version = PLUGIN_VERSION,
    url = "michaelwflaherty.com"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); 
}

public Action OnWeaponCanUse(int client, int weapon) 
{ 
	if(!CheckCommandAccess(client, "", ADMFLAG_RESERVATION, true))
	{
		char classname[32];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_awp"))
		{
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		return Plugin_Continue;
	}
}  

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}