#pragma semicolon 1
#define PLUGIN_AUTHOR "Armin"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <adminmenu>
#include <smlib>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Nerp.CF! - FFA", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "http://nerp.cf/"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	RegConsoleCmd("sm_guns", Cmd_Guns);
	RegConsoleCmd("sm_gun", Cmd_Guns);
}

public OnMapStart()
{
	ServerCommand("mp_randomspawn 1");
	ServerCommand("mp_teammates_are_enemies 1");
	ServerCommand("mp_maxmoney 0");
	ServerCommand("mp_roundtime 30");
	ServerCommand("mp_buytime 0");
	ServerCommand("mp_respawn_on_death_ct 1");
	ServerCommand("mp_respawn_on_death_t 1");
	ServerCommand("mp_ignore_round_win_conditions 1");
	ServerCommand("bot_quota 0");
	ServerCommand("mp_spawnprotectiontime 3");
	ServerCommand("mp_respawn_immunitytime 3");
	ServerCommand("mp_maxrounds 0");
	ServerCommand("sv_infinite_ammo 2");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_limitteams 0");
	ServerCommand("mp_give_player_c4 0");
	ServerCommand("sv_alltalk 1");
	ServerCommand("sv_full_alltalk 1");
	ServerCommand("sv_deadtalk 1");
	ServerCommand("mp_free_armor 1");
	ServerCommand("mp_weapons_allow_map_placed 0");
}

public Action Cmd_Guns(client, args)
{
	GunsMenu(client);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public Action OnWeaponCanUse(int client, int weapon) 
{
    if(GetClientButtons(client) & IN_USE)
        return Plugin_Handled; 
    
    return Plugin_Continue; 
}

public Action OnWeaponDrop(int client, int weapon) 
{
    if(GetClientButtons(client) & IN_USE)
        return Plugin_Handled; 
    
    return Plugin_Continue; 
}  

public Action Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || IsFakeClient(client))
	{
		return;
	}
	
	GunsMenu(client);
	
	Client_RemoveAllWeapons(client);
	
	GivePlayerItem(client, "weapon_knife");
}

public void GunsMenu(client)
{
	new Handle:menu = CreateMenu(Handler_GunsMenu);
	SetMenuTitle(menu, "Weapons Menu");

	AddMenuItem(menu, "primary", "Select Your Primary");
	AddMenuItem(menu, "secondary", "Select Your Secondary");

	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Handler_GunsMenu(Handle:menu, MenuAction:action, client, param) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	}

	if(action != MenuAction_Select) 
	{
		return;
	}

	decl String:selection[16];
	GetMenuItem(menu, param, selection, sizeof(selection));

	if(StrEqual(selection, "primary")) 
	{
		Primary(client);
	}

	if(StrEqual(selection, "secondary")) 
	{
		Secondary(client);
	}
}

public void Primary(client)
{
	new Handle:menu = CreateMenu(Handler_Primary);
	SetMenuTitle(menu, "Rifle");

	AddMenuItem(menu, "1", "FAMAS");
	AddMenuItem(menu, "2", "Galil AR");
	AddMenuItem(menu, "3", "M4A4");
	AddMenuItem(menu, "4", "M4A1-S");
	AddMenuItem(menu, "5", "AK-47");
	AddMenuItem(menu, "6", "SSG 08");
	AddMenuItem(menu, "7", "AUG");
	AddMenuItem(menu, "8", "AWP");
	AddMenuItem(menu, "9", "SCAR-20");
	AddMenuItem(menu, "10", "G3SG1");

	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, 60);
}

public Handler_Primary(Handle:menu, MenuAction:action, client, param) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	}

	if(action != MenuAction_Select) 
	{
		return;
	}

	decl String:selection[16];
	GetMenuItem(menu, param, selection, sizeof(selection));

	if(StrEqual(selection, "1")) 
	{
		GivePlayerItem(client, "weapon_famas");
		Secondary(client);
	}

	if(StrEqual(selection, "2")) 
	{
		GivePlayerItem(client, "weapon_galilar");
		Secondary(client);
	}
	
	if(StrEqual(selection, "3")) 
	{
		GivePlayerItem(client, "weapon_m4a1");
		Secondary(client);
	}
	
	if(StrEqual(selection, "4")) 
	{
		GivePlayerItem(client, "weapon_m4a1_silencer");
		Secondary(client);
	}
	
	if(StrEqual(selection, "5")) 
	{
		GivePlayerItem(client, "weapon_ak47");
		Secondary(client);
	}
	
	if(StrEqual(selection, "6")) 
	{
		GivePlayerItem(client, "weapon_ssg08");
		Secondary(client);
	}
	
	if(StrEqual(selection, "7")) 
	{
		GivePlayerItem(client, "weapon_aug");
		Secondary(client);
	}
	
	if(StrEqual(selection, "8")) 
	{
		GivePlayerItem(client, "weapon_awp");
		Secondary(client);
	}
	
	if(StrEqual(selection, "9")) 
	{
		GivePlayerItem(client, "weapon_scar20");
		Secondary(client);
	}
	
	if(StrEqual(selection, "10")) 
	{
		GivePlayerItem(client, "weapon_g3sg1");
		Secondary(client);
	}
}

public void Secondary(client)
{
	new Handle:menu = CreateMenu(Handler_Secondary);
	SetMenuTitle(menu, "Pistlos");

	AddMenuItem(menu, "1", "Glock-18");
	AddMenuItem(menu, "2", "Dual Berettas");
	AddMenuItem(menu, "3", "P250");
	AddMenuItem(menu, "4", "Tec-9");
	AddMenuItem(menu, "5", "CZ75-Auto");
	AddMenuItem(menu, "6", "Desert Eagle");
	AddMenuItem(menu, "7", "R8 Revolver");
	AddMenuItem(menu, "8", "USP-S");
	AddMenuItem(menu, "9", "P2000");
	AddMenuItem(menu, "10", "Five-Seven");

	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, 60);
}

public Handler_Secondary(Handle:menu, MenuAction:action, client, param) 
{
	if(action == MenuAction_End) 
	{
		CloseHandle(menu);
	}

	if(action != MenuAction_Select) 
	{
		return;
	}

	decl String:selection[16];
	GetMenuItem(menu, param, selection, sizeof(selection));

	if(StrEqual(selection, "1")) 
	{
		GivePlayerItem(client, "weapon_glock");
	}

	if(StrEqual(selection, "2")) 
	{
		GivePlayerItem(client, "weapon_elite");
	}
	
	if(StrEqual(selection, "3")) 
	{
		GivePlayerItem(client, "weapon_p250");
	}
	
	if(StrEqual(selection, "4")) 
	{
		GivePlayerItem(client, "weapon_tec9");
	}
	
	if(StrEqual(selection, "5")) 
	{
		GivePlayerItem(client, "weapon_cz75a");
	}
	
	if(StrEqual(selection, "6")) 
	{
		GivePlayerItem(client, "weapon_deagle");
	}
	
	if(StrEqual(selection, "7")) 
	{
		GivePlayerItem(client, "weapon_revolver");
	}
	
	if(StrEqual(selection, "8")) 
	{
		GivePlayerItem(client, "weapon_usp_silencer");
	}
	
	if(StrEqual(selection, "9")) 
	{
		GivePlayerItem(client, "weapon_hkp2000");
	}
	
	if(StrEqual(selection, "10")) 
	{
		GivePlayerItem(client, "weapon_fiveseven");
	}
}