#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

int ammoOffset;
int ammotype;

public Plugin myinfo = 
{
	name = "Sniper Using Bots Fix",
	author = "sereky",
	description = "Fixes Bugs About Bots Using Snipers.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead2", false))
	{
		ammotype = 36;
	}
	else if (StrEqual(game_name, "left4dead", false))
	{
		ammotype = 8;
	}
	else
	{
		SetFailState("[FIX] Plugin Supports L4D and L4D2 Only!");
	}
	
	ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	CreateConVar("sniper_using_bots_version", PLUGIN_VERSION, "Sniper Using Bots Fix Version", FCVAR_SPONLY|FCVAR_NOTIFY);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action OnWeaponSwitch(int client, int weapon)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsFakeClient(client) && !IsIncapacitated(client))
	{
		if (weapon != -1 && IsValidEdict(weapon))
		{
			char sClassname[32];
			GetEdictClassname(weapon, sClassname, sizeof(sClassname));
			if (StrEqual(sClassname, "weapon_pistol"))
			{
				int i_Weapon = GetPlayerWeaponSlot(client, 0);
				if (i_Weapon != -1 && IsValidEdict(i_Weapon))
				{
					char sniper[64];
					GetEdictClassname(i_Weapon, sniper, sizeof(sniper));
					if (StrEqual(sniper, "weapon_hunting_rifle"))
					{
						int ammohunr = GetEntData(client, ammoOffset + (ammotype));
						if (ammohunr != 0)
						{
							return Plugin_Handled;
						}
					}
					else if (StrEqual(sniper, "weapon_sniper_scout"))
					{
						int ammosnip = GetEntData(client, ammoOffset + (40));
						if (ammosnip != 0)
						{
							return Plugin_Handled;
						}
					}
					else if (StrEqual(sniper, "weapon_sniper_military"))
					{
						int ammosnip = GetEntData(client, ammoOffset + (40));
						if (ammosnip != 0)
						{
							return Plugin_Handled;
						}
					}
					else if (StrEqual(sniper, "weapon_sniper_awp"))
					{
						int ammosnip = GetEntData(client, ammoOffset + (40));
						if (ammosnip != 0)
						{
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsIncapacitated(int client)
{
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
	{
		return true;
	}
	return false;
}
