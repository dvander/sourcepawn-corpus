#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.1"

new ammoOffset;
new ammotype;

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] Bot Sniper Rifle AI Fix",
	author = "sereky",
	description = "Survivor bots will not prefer pistols if they have sniper rifle.",
	version = PLUGIN_VERSION,
	url = "URL"
}

public OnPluginStart()
{
	ammotype = 8;

	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead2", false))
	{
		ammotype = 36;
	}

	ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	CreateConVar("l4d_bot_sniper_aifix_ver", PLUGIN_VERSION, "Version of the plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponSwitch(client, weapon)
{
	if (IsClientConnected(client))
	{
		if (IsFakeClient(client))
		{
			if (!IsIncapacitated(client))
			{
				decl String:sClassname[32];
				GetEdictClassname(weapon, sClassname, sizeof(sClassname));
				if (StrEqual(sClassname, "weapon_pistol"))
				{
					new i_Weapon = GetPlayerWeaponSlot(client, 0);

					if (i_Weapon != -1)
					{
						new String:sniper[32];
						GetEdictClassname(GetPlayerWeaponSlot(client, 0), sniper, 32);
						if (StrEqual(sniper, "weapon_hunting_rifle"))
						{
							new ammohunr = GetEntData(client, ammoOffset+(ammotype));
							if (ammohunr != 0)
							{
								return Plugin_Handled;
							}
						}
						else if (StrEqual(sniper, "weapon_sniper_scout"))
						{
							new ammosnip = GetEntData(client, ammoOffset+(40));
							if (ammosnip != 0)
							{
								return Plugin_Handled;
							}
						}
						else if (StrEqual(sniper, "weapon_sniper_military"))
						{
							new ammosnip = GetEntData(client, ammoOffset+(40));
							if (ammosnip != 0)
							{
								return Plugin_Handled;
							}
						}
						else if (StrEqual(sniper, "weapon_sniper_awp"))
						{
							new ammosnip = GetEntData(client, ammoOffset+(40));
							if (ammosnip != 0)
							{
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsIncapacitated(client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0 )
		return true;
	return false;
}
