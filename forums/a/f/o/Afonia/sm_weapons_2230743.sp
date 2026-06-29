//	Natalya's !weapons Menu
//	Script by Natalya[AF]
//
//	This script will allow players to spawn weapons by typing !weapons in game.
//
//	www.n00bunlimited.net
//	www.s-low.info
//	www.4chan.org

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "01.01"

new Handle:g_Cvar_Enable = INVALID_HANDLE
new Handle:g_Cvar_T = INVALID_HANDLE
new Handle:g_Cvar_CT = INVALID_HANDLE
new Handle:g_WeaponMenu
new Handle:g_PistolMenu
new Handle:g_SMGMenu
new Handle:g_ShotgunMenu
new Handle:g_RifleMenu
new Handle:g_SniperMenu
new Handle:g_MGunMenu
new Handle:g_EquipMenu
new Handle:g_InfoMenu
public Plugin:myinfo =
{
	name = "Weapon Menu",
	author = "Natalya[AF]",
	description = "Natalya's !weapons Menu Plugin",
	version = PLUGIN_VERSION,
	url = "http://www.n00bunlimited.net"
}


public OnPluginStart()
{
	RegConsoleCmd("sm_weapons", Command_Weapons, "Open the !weapons Menu");
	RegConsoleCmd("weapons", Command_Weapons, "Open the !weapons Menu");
	CreateConVar("sm_weapons_version", PLUGIN_VERSION, "Version of Natalya's !weapons Menu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Enable = CreateConVar("sm_weapons_enabled", "1", "Enables or Disables the !weapons Menu", FCVAR_PLUGIN);
	g_Cvar_T = CreateConVar("sm_weapons_t", "1", "Enables or Disables the !weapons Menu for Terrorists.", FCVAR_PLUGIN);
	g_Cvar_CT = CreateConVar("sm_weapons_ct", "1", "Enables or Disables the !weapons Menu for CT's.", FCVAR_PLUGIN);
}
public OnMapStart()
{
	g_WeaponMenu = BuildWeaponMenu();
	g_PistolMenu = BuildPistolMenu();
	g_SMGMenu = BuildSMGMenu();
	g_ShotgunMenu = BuildShotgunMenu();
	g_RifleMenu = BuildRifleMenu();
	g_SniperMenu = BuildSniperMenu();
	g_MGunMenu = BuildMGunMenu();
	g_EquipMenu = BuildEquipMenu();
	g_InfoMenu = BuildInfoMenu();
}
public OnMapEnd()
{
	if (g_WeaponMenu != INVALID_HANDLE)
	{
		CloseHandle(g_WeaponMenu);
		g_WeaponMenu = INVALID_HANDLE;
	}
	if (g_PistolMenu != INVALID_HANDLE)
	{
		CloseHandle(g_PistolMenu);
		g_PistolMenu = INVALID_HANDLE;
	}
	if (g_SMGMenu != INVALID_HANDLE)
	{
		CloseHandle(g_SMGMenu);
		g_SMGMenu = INVALID_HANDLE;
	}
	if (g_ShotgunMenu != INVALID_HANDLE)
	{
		CloseHandle(g_ShotgunMenu);
		g_ShotgunMenu = INVALID_HANDLE;
	}
	if (g_RifleMenu != INVALID_HANDLE)
	{
		CloseHandle(g_RifleMenu);
		g_RifleMenu = INVALID_HANDLE;
	}
	if (g_SniperMenu != INVALID_HANDLE)
	{
		CloseHandle(g_SniperMenu);
		g_SniperMenu = INVALID_HANDLE;
	}
	if (g_MGunMenu != INVALID_HANDLE)
	{
		CloseHandle(g_MGunMenu);
		g_MGunMenu = INVALID_HANDLE;
	}
	if (g_EquipMenu != INVALID_HANDLE)
	{
		CloseHandle(g_EquipMenu);
		g_EquipMenu = INVALID_HANDLE;
	}
	if (g_InfoMenu != INVALID_HANDLE)
	{
		CloseHandle(g_InfoMenu);
		g_InfoMenu = INVALID_HANDLE;
	}
}
Handle:BuildWeaponMenu()
{
	new Handle:weapons = CreateMenu(Menu_Weapons);
	AddMenuItem(weapons, "g_PistolMenu", "Pistols")
	AddMenuItem(weapons, "g_ShotgunMenu", "Shotguns")
	AddMenuItem(weapons, "g_SMGMenu", "SMGs")
	AddMenuItem(weapons, "g_RifleMenu", "Rifles")
	AddMenuItem(weapons, "g_SniperMenu", "Sniper Rifles")
	AddMenuItem(weapons, "g_MGunMenu", "Machine Guns")
	AddMenuItem(weapons, "g_EquipMenu", "Equipment")
	AddMenuItem(weapons, "g_InfoMenu", "Information")
	SetMenuTitle(weapons, "Weapons Menu:");
	return weapons;
}
Handle:BuildPistolMenu()
{
	new Handle:pistols = CreateMenu(Menu_Pistols);
	AddMenuItem(pistols, "weapon_glock", "Glock")
	AddMenuItem(pistols, "weapon_usp", "USP")
	AddMenuItem(pistols, "weapon_p228", "P228")
	AddMenuItem(pistols, "weapon_deagle", "Desert Eagle")
	AddMenuItem(pistols, "weapon_fiveseven", "Five Seven")
	AddMenuItem(pistols, "weapon_elite", "Dual Elites")
	AddMenuItem(pistols, "weapon_tec9", "Tec9")
	AddMenuItem(pistols, "weapon_hkp2000", "HKP2000")
	SetMenuTitle(pistols, "Pistols Menu:");
	return pistols;
}
Handle:BuildSMGMenu()
{
	new Handle:smgs = CreateMenu(Menu_SMGs);
	AddMenuItem(smgs, "weapon_mp9", "MP9")
	AddMenuItem(smgs, "weapon_mac10", "Mac 10")
	AddMenuItem(smgs, "weapon_mp7", "MP7")
	AddMenuItem(smgs, "weapon_ump45", "UMP")
	AddMenuItem(smgs, "weapon_p90", "P90")
	AddMenuItem(smgs, "weapon_bizon", "Bizon")
	SetMenuTitle(smgs, "SMG Menu:");
	return smgs;
}
Handle:BuildShotgunMenu()
{
	new Handle:shotguns = CreateMenu(Menu_Shotguns);
	AddMenuItem(shotguns, "weapon_mag7", "Mag7")
	AddMenuItem(shotguns, "weapon_xm1014", "Auto Shotgun")
	AddMenuItem(shotguns, "weapon_nova", "Nova Shotgun")
	AddMenuItem(shotguns, "weapon_sawedoff", "Sawed Off Shotgun")
	SetMenuTitle(shotguns, "Shotgun Menu:");
	return shotguns;
}
Handle:BuildRifleMenu()
{
	new Handle:rifles = CreateMenu(Menu_Rifles);
	AddMenuItem(rifles, "weapon_ak47", "AK47")
	AddMenuItem(rifles, "weapon_m4a1", "M4A1")
	AddMenuItem(rifles, "weapon_famas", "Famas")
	AddMenuItem(rifles, "weapon_galilar", "Galil")
	AddMenuItem(rifles, "weapon_aug", "Aug")
	AddMenuItem(rifles, "weapon_sg550", "Sg 550")
	SetMenuTitle(rifles, "Rifles Menu:");
	return rifles;
}
Handle:BuildSniperMenu()
{
	new Handle:snipers = CreateMenu(Menu_Snipers);
	AddMenuItem(snipers, "weapon_ssg08", "Scout")
	AddMenuItem(snipers, "weapon_scar20", "Scar20")
	AddMenuItem(snipers, "weapon_g3sg1", "G3/SG1")
	AddMenuItem(snipers, "weapon_awp", "AWP")
	SetMenuTitle(snipers, "Sniper Rifle Menu:");
	return snipers;
}
Handle:BuildMGunMenu()
{
	new Handle:mguns = CreateMenu(Menu_MGuns);
	AddMenuItem(mguns, "weapon_m249", "M249")
	SetMenuTitle(mguns, "Machine Gun Menu:");
	return mguns;
}
Handle:BuildEquipMenu()
{
	new Handle:equip = CreateMenu(Menu_Equip);
	AddMenuItem(equip, "weapon_hegrenade", "Hegrenade")
	AddMenuItem(equip, "weapon_smokegrenade", "Smokegrenade")
	AddMenuItem(equip, "weapon_flashbang", "Flashbang")
	AddMenuItem(equip, "weapon_decoy", "Decoy")
	SetMenuTitle(equip, "Equipment Menu:");
	return equip;
}
Handle:BuildInfoMenu()
{
	new Handle:info = CreateMenu(Menu_Info);
	AddMenuItem(info, "1", "  Type !weapons to spawn a weapon.", ITEMDRAW_DISABLED)
	AddMenuItem(info, "1", "  The menu may be enabled or disabled", ITEMDRAW_DISABLED)
	AddMenuItem(info, "1", "  for a given team.  For more info:", ITEMDRAW_DISABLED)
	AddMenuItem(info, "1", "  ", ITEMDRAW_DISABLED)
	AddMenuItem(info, "1", "  www.n00bunlimited.net", ITEMDRAW_DISABLED)
	SetMenuTitle(info, "<==>  [ЗАРАЖЁННЫЕ]  <==>");
	return info;
}
public Menu_Weapons(Handle:weapons, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(weapons, param2, info, sizeof(info));


		if (StrEqual(info,"g_PistolMenu"))
		{
			DisplayMenu(g_PistolMenu, param1, 20);
		}
		if (StrEqual(info,"g_SMGMenu"))
		{
			DisplayMenu(g_SMGMenu, param1, 20);
		}
		if (StrEqual(info,"g_ShotgunMenu"))
		{
			DisplayMenu(g_ShotgunMenu, param1, 20);
		}
		if (StrEqual(info,"g_RifleMenu"))
		{
			DisplayMenu(g_RifleMenu, param1, 20);
		}
		if (StrEqual(info,"g_SniperMenu"))
		{
			DisplayMenu(g_SniperMenu, param1, 20);
		}
		if (StrEqual(info,"g_MGunMenu"))
		{
			DisplayMenu(g_MGunMenu, param1, 20);
		}
		if (StrEqual(info,"g_EquipMenu"))
		{
			DisplayMenu(g_EquipMenu, param1, 20);
		}
		if (StrEqual(info,"g_InfoMenu"))
		{
			DisplayMenu(g_InfoMenu, param1, 20);
		}
	}
}
public Menu_Pistols(Handle:pistols, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(pistols, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_SMGs(Handle:smgs, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(smgs, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_Shotguns(Handle:shotguns, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(shotguns, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_Rifles(Handle:rifles, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(rifles, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_Snipers(Handle:snipers, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(snipers, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_MGuns(Handle:mguns, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(mguns, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_Equip(Handle:equip, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(equip, param2, info, sizeof(info));

		GivePlayerItem(param1, info, 0);
	}
}
public Menu_Info(Handle:info, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		return
	}
}
public Action:Command_Weapons(client, args)
{
    if (GetConVarInt(g_Cvar_Enable))
    {
        if (client)
        {
            if (IsPlayerAlive(client))
            {
                new team = GetClientTeam(client);

                if (team == 2)
                {
                	if (GetConVarInt(g_Cvar_T))
                	{
                		DisplayMenu(g_WeaponMenu, client, 20);
                	}
                	else PrintToChat(client, "\x03 [NsWM]Terrorists can't use the !weapons menu.");
                }
                if (team == 3)
                {
                	if (GetConVarInt(g_Cvar_CT))
					{
                		DisplayMenu(g_WeaponMenu, client, 20);
                	}
                	else PrintToChat(client, "\x03 [NsWM]Counter-Terrorists can't use the !weapons menu.");
                }
            }
            else PrintToChat(client, "\x03 [NsWM]You can't use the !weapons menu while dead.");
        }
    }
    return Plugin_Handled
}