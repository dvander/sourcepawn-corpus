//SourcePawn

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define OFFSET_RIFLE 12
#define OFFSET_SMG 20
#define OFFSET_SHOTGUN 28
#define OFFSET_AUTOSHOTGUN 32
#define OFFSET_HUNTING_SNIPER 36
#define OFFSET_MILITARY_SNIPER 40
#define OFFSET_GRENADE_LAUNCHER 68

public Plugin:myinfo =
{
	name = "Set Ammo",
	author = "PCI Gaming Team",
	description = "Created for Speedrunner Tools addon to add the desired number of ammo.",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=296777"
}

//============================================================
//============================================================

public OnPluginStart()
{
	RegServerCmd("sm_setammo", Cmd_SetAmmo);
}

public Action:Cmd_SetAmmo(args)
{
	if (args > 2 && args <= 5)
	{
		decl String:sArg[4];
		GetCmdArg(1, sArg, sizeof(sArg));
		new client = StringToInt(sArg);
		if (client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			new iSlot = StringToInt(sArg);
			if (iSlot == 0 || iSlot == 1)
			{
				new entity = GetPlayerWeaponSlot(client, iSlot);
				if (IsValidEntity(entity))
				{
					decl String:sEntName[64];
					GetEntityClassname(entity, sEntName, sizeof(sEntName));
					if (StrEqual(sEntName, "weapon_melee"))
					{
						PrintToChatAll("[SETAMMO] Cannot change ammo for \"%s\".", sEntName);
						return Plugin_Handled;
					}
					GetCmdArg(3, sArg, sizeof(sArg));
					new iClip = StringToInt(sArg);
					SetEntProp(entity, Prop_Send, "m_iClip1", iClip);
					if (args > 3 && iSlot == 0)
					{
						GetCmdArg(4, sArg, sizeof(sArg));
						new iAmmo = StringToInt(sArg);
						new offset;
						if (StrEqual(sEntName, "weapon_rifle") || StrEqual(sEntName, "weapon_rifle_ak47") || StrEqual(sEntName, "weapon_rifle_desert"))
						{
							offset = OFFSET_RIFLE;
						}
						else if (StrEqual(sEntName, "weapon_smg") || StrEqual(sEntName, "weapon_smg_silenced"))
						{
							offset = OFFSET_SMG;
						}
						else if (StrEqual(sEntName, "weapon_pumpshotgun") || StrEqual(sEntName, "weapon_shotgun_chrome"))
						{
							offset = OFFSET_SHOTGUN;
						}
						else if (StrEqual(sEntName, "weapon_autoshotgun") || StrEqual(sEntName, "weapon_shotgun_spas"))
						{
							offset = OFFSET_AUTOSHOTGUN;
						}
						else if (StrEqual(sEntName, "weapon_hunting_rifle"))
						{
							offset = OFFSET_HUNTING_SNIPER;
						}
						else if (StrEqual(sEntName, "weapon_sniper_military"))
						{
							offset = OFFSET_MILITARY_SNIPER;
						}
						else if (StrEqual(sEntName, "weapon_grenade_launcher"))
						{
							offset = OFFSET_GRENADE_LAUNCHER;
						}
						else
						{
							PrintToChatAll("[SETAMMO] Weapon \"%s\" is not in offset table.", sEntName);
							return Plugin_Handled;
						}
						SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + offset, iAmmo);
						if (args > 4)
						{
							GetCmdArg(5, sArg, sizeof(sArg));
							new iUpgrade = StringToInt(sArg);
							if (iUpgrade > 0 && GetEntProp(entity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded") > 0)
							{
								SetEntProp(entity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iUpgrade);
							}
							else
							{
								PrintToChatAll("[SETAMMO] Not found upgrade ammo in clip.");
							}
						}
					}
				}
				else
				{
					PrintToChatAll("[SETAMMO] Weapon not found.");
				}
			}
			else
			{
				PrintToChatAll("[SETAMMO] Invalid slot specified.");
			}
		}
		else
		{
			PrintToChatAll("[SETAMMO] Client %d is invalid.", client);
		}
	}
	else
	{
		PrintToChatAll("[SETAMMO] Wrong number of arguments.");
	}
	return Plugin_Handled;
}