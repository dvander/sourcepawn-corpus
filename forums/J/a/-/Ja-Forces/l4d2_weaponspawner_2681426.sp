/*
 * *Simple* plugin which you can spawn any weapon or special zombie where you are looking also you can give weapons to players.
 *
 * ####
 * Commands:
 * 	-	sm_spawnweapon [weapon_name] <amount> or sm_sw [weapon_name] <amount>
 *		(eg. sm_sw chainsaw 2)
 *	-	sm_giveweapon <#userid|name> [weapon_name] or sm_gw <#userid|name> [weapon_name] 
 *		(eg. sm_gw @me chainsaw)
 *		Targeting: http://wiki.alliedmods.net/Admin_Commands_%28SourceMod%29#How_to_Target
 *	-	sm_zspawn [special infeted name] <amount>
 *		(eg. sm_zspawn tank 3)
 *	-	sm_spawnmachinegun or sm_smg - Spawn Machine Gun(Changed in 1.0a)
 *	-	sm_removemachinegun or sm_rmg - Remove Machine Gun
 *
 * ####
 * ConVars:
 *	-	sm_spawnweapon_assaultammo 			- How much Ammo for AK74, M4A1, SG552 and Desert Rifle.
 *	-	sm_spawnweapon_smgammo 				- How much Ammo for SMG, Silenced SMG and MP5
 *	-	sm_spawnweapon_shotgunammo 			- How much Ammo for Shotgun and Chrome Shotgun.
 *	-	sm_spawnweapon_autoshotgunammo 		- How much Ammo for Autoshotgun and SPAS.
 *	-	sm_spawnweapon_sniperrifleammo 		- How much Ammo for the Military Sniper Rifle, AWP and Scout.
 *	-	sm_spawnweapon_grenadelauncherammo 	- How much Ammo for the Grenade Launcher.
 *	-	sm_spawnweapon_allowallmeleeweapons	- Allow or Disallow all melee weapons on all campaigns.
 *
 * ####
 * Weapon List: 
 * adrenaline, autoshotgun, chainsaw, defibrillator, fireworkcrate, 
 * first_aid_kit, gascan, gnome, grenade_launcher, hunting_rifle, 
 * molotov, oxygentank, pain_pills, pipe_bomb, pistol, 
 * pistol_magnum, propanetank, pumpshotgun, rifle, rifle_ak47, 
 * rifle_desert, rifle_sg552, rifle_m60, shotgun_chrome, shotgun_spas, smg, 
 * smg_mp5, smg_silenced, sniper_awp, sniper_military, sniper_scout, 
 * vomitjar, ammo_spawn, upgradepack_explosive, upgradepack_incendiary, 
 * cola_bottles, rifle_m60, upgrade_laser_sight, explosive_barrel, laser_sight
 *
 * ####
 * Melee Weapons List:
 * baseball_bat, cricket_bat, crowbar, electric_guitar, fireaxe, frying_pan, 
 * katana, machete, tonfa, knife, golfclub
 *
 * #### 
 * Special Zombie List: 
 * boomer, hunter, smoker, tank, spitter, jockey, charger, zombie, witch, witch_bride, mob
 *
 * ####
 * Changelog:
 * v1.1a
 *	o - Converted plugin source to the latest syntax. Requires SourceMod 1.8 or newer.
 * v1.0a
 *  o Added L4D1 Minigun
 *  o Changed sm_smg to sm_smg #   sm_smg 1 will spawn the l4d2 minigun and sm_smg 2 will spawn the l4d1 minigun
 * v1.0
 *  o Added Laser Sight Box
 *  o Added The Sacrifice and No Mercy Melee Lists
 *  o Added Explosive Barrel
 * v0.9
 *  o Added ability to spawn melee weapons.
 *	o Added Katana and Fireaxe to The Passing melee list
 * v0.8a
 *  o Added "Zombie Mob"
 * v0.8
 *  o Added "Bride Witch"
 * v0.7f
 *  o Removed Electric Guitar from The Passing Melee weapons list
 * v0.7e
 *  o "Golf Club" is now The Passing exclusive
 *  o Fixed precache model typos 
 * v0.7d
 *  o "Golf Club" support
 * v0.7c
 *  o Full "M60" support, excluding ammo cvar
 * v0.7b
 *  o Added "M60(only as spawn)"
 * v0.7a
 *	o Added missing "Full Health"
 *	o Debug informations now are disabled by default
 * v0.7
 *	o Added missing stuff in "give menu" from v0.5-beta
 *	o Fixed Ammo Stack spawning
 *	o Fixed typos in translation file (thx for bearbear)
 *	o Added second argument to sm_spawnweapon and sm_zspawn - amount of spawned items/zombies
 *	o Fixed campaigns detection
 * v0.6
 *	o Added ammo to spawned weapons (yey!)
 *	o Added ammo cvars
 *	o Automatically adding "weapon_" for sm_sw (eg. sm_sw rifle)
 *	o Added multi-language support
 *	o Added cola and knife (knife works only when you play with germans)
 *	o Added command to remove minigun
 *	o Minor Fixes
 * v0.5 - Beta
 *	o Added MagineGun spawning
 *	o Added missing witch and vomitjar
 * 	o Minor fixes
 * v0.4
 *	o Menu now use own category on Admin Menu
 *	o Added menu for "Give Weapons"
 *	o Added menu for "Spawn Special Zombie"
 *	o Added Laser Sights, Explosive Ammo, Incendiary Ammo, Health, Ammo Stack
 *	o Rewrite menu "Spawn Weapon"
 *	o Fix for: http://forums.alliedmods.net/showpost.php?p=998601&postcount=33 (now you can use your nick in binds)
 *	o Rename sm_spawn to sm_zspawn
 *	o Code optimizations
 * v0.3a
 *	o Fix for: http://forums.alliedmods.net/showpost.php?p=997445&postcount=21
 * v0.3
 *	o Added Menu (in admin menu - Server Commands)
 *	o Added sm_spawn
 * v0.2
 *	o Added sm_gw
 * v0.1
 *	o Initial Release
 *
 * Zuko / #hlds.pl @ Qnet #sourcemod @ GameSurge / zuko.steamunpowered.eu / hlds.pl /
 *
 * ####
 * Credits:
 * pheadxdll for [TF2] Pumpkins code
 * antihacker for [L4D] Spawn Minigun code
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

#define VERSION "1.0a"
#define CVAR_FLAGS	FCVAR_NOTIFY

/* TopMenu Handle */
TopMenu hAdminMenu = null;

/* ConVar Handle */
ConVar AssaultMaxAmmo = null;
ConVar SMGMaxAmmo = null;
ConVar ShotgunMaxAmmo = null;
ConVar AutoShotgunMaxAmmo = null;
ConVar HRMaxAmmo = null;
ConVar SniperRifleMaxAmmo = null;
ConVar GrenadeLauncherMaxAmmo = null;
ConVar AllowAllMeleeWeapons = null;
ConVar DebugInformations = null;

char ChoosedWeapon[MAXPLAYERS+1][56];
char ChoosedMenuSpawn[MAXPLAYERS+1][56];
char ChoosedMenuGive[MAXPLAYERS+1][56];
char MapName[128];
float g_pos[3];

public Plugin myinfo = 
{
	name = "[L4D2] Weapon/Zombie Spawner",
	author = "Zuko & McFlurry",
	description = "Спавн оружия/зомби в точке, куда вы смотрите или выдача оружия игрокам",
	version = VERSION,
	url = "http://zuko.steamunpowered.eu"
}

public void OnPluginStart()
{
	/* ConVars */
	CreateConVar("sm_weaponspawner_version", VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	/* Admin Commands */
	RegAdminCmd("sm_spawnweapon", Command_SpawnWeapon, ADMFLAG_SLAY, "Spawn weapon where you are looking.");
	RegAdminCmd("sm_sw", Command_SpawnWeapon, ADMFLAG_SLAY, "Spawn weapon where you are looking.");
	RegAdminCmd("sm_giveweapon", Command_GiveWeapon, ADMFLAG_SLAY, "Gives weapon to player.");
	RegAdminCmd("sm_gw", Command_GiveWeapon, ADMFLAG_SLAY, "Gives weapon to player.");
	RegAdminCmd("sm_zspawn", Command_SpawnZombie, ADMFLAG_SLAY, "Spawns special zombie where you are looking.");

	/* Minugun Commands */
	RegAdminCmd("sm_spawnmachinegun", Command_SpawnMinigun, ADMFLAG_SLAY, "Spawns Machine Gun.");
	RegAdminCmd("sm_smg", Command_SpawnMinigun, ADMFLAG_SLAY, "Spawns Machine Gun.");
	RegAdminCmd("sm_removemachinegun", Command_RemoveMinigun, ADMFLAG_SLAY, "Remove Machine Gun.");
	RegAdminCmd("sm_rmg", Command_RemoveMinigun, ADMFLAG_SLAY, "Remove Machine Gun.");

	/* Max Ammo ConVars */
	AssaultMaxAmmo = CreateConVar("sm_spawnweapon_assaultammo", "360", "How much Ammo for AK74, M4A1, SG552, M60 and Desert Rifle.", CVAR_FLAGS, true, 0.0, true, 360.0);
	SMGMaxAmmo = CreateConVar("sm_spawnweapon_smgammo", "650", "How much Ammo for SMG, Silenced SMG and MP5", CVAR_FLAGS, true, 0.0, true, 650.0);
	ShotgunMaxAmmo = CreateConVar("sm_spawnweapon_shotgunammo", "56", "How much Ammo for Shotgun and Chrome Shotgun.", CVAR_FLAGS, true, 0.0, true, 56.0);
	AutoShotgunMaxAmmo = CreateConVar("sm_spawnweapon_autoshotgunammo", "90", "How much Ammo for Autoshotgun and SPAS.", CVAR_FLAGS, true, 0.0, true, 90.0);
	HRMaxAmmo = CreateConVar("sm_spawnweapon_huntingrifleammo", "150", "How much Ammo for the Hunting Rifle.", CVAR_FLAGS, true, 0.0, true, 150.0);
	SniperRifleMaxAmmo = CreateConVar("sm_spawnweapon_sniperrifleammo", "180", "How much Ammo for the Military Sniper Rifle, AWP and Scout.", CVAR_FLAGS, true, 0.0, true, 180.0);
	GrenadeLauncherMaxAmmo = CreateConVar("sm_spawnweapon_grenadelauncherammo", "30", "How much Ammo for the Grenade Launcher.", CVAR_FLAGS, true, 0.0, true, 30.0);

	AllowAllMeleeWeapons = CreateConVar("sm_spawnweapon_allowallmeleeweapons", "0", "Allow or Disallow all melee weapons on all campaigns.", CVAR_FLAGS, true, 0.0, true, 1.0);
	DebugInformations = CreateConVar("sm_spawnweapon_debug", "0", "Enable or Disable Debug Informations.", CVAR_FLAGS, true, 0.0, true, 1.0);

	/* Config File */
	AutoExecConfig(true, "l4d2_weaponspawner");
	
	/*Menu Handler */
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}

	/* Load translations */
	LoadTranslations("common.phrases");
	LoadTranslations("weaponspawner.phrases");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = null;
	}
}

public void OnMapStart()
{
	/* Precache Models */
	PrecacheModel("models/v_models/v_rif_sg552.mdl", true);
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_scout.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", true);
	PrecacheModel("models/v_models/v_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/props_industrial/barrel_fuel.mdl", true);
	PrecacheModel("models/props_industrial/barrel_fuel_partb.mdl", true);
	PrecacheModel("models/props_industrial/barrel_fuel_parta.mdl", true);
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	GetCurrentMap(MapName, sizeof(MapName));
}

/* Spawn Weapon */
public Action Command_SpawnWeapon(int client, int args)
{
	int amount;
	
	char weapon[40], arg1[40], arg2[5];
	int maxammo;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;
	}

	if (args == 2)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		Format(weapon, sizeof(weapon), "weapon_%s", arg1);
		amount = StringToInt(arg2);
	}
	else if (args == 1)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		Format(weapon, sizeof(weapon), "weapon_%s", arg1);
		amount = 1;
	}
	else
	{
		ReplyToCommand(client, "%t", "SpawnWeaponUsage", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if(!SetTeleportEndPoint(client))
	{
		ReplyToCommand(client, "[SM] %t", "SpawnError", LANG_SERVER);
		return Plugin_Handled;
	}

	if (StrEqual(weapon, "rifle", false) || StrEqual(weapon, "rifle_ak47", false) || StrEqual(weapon, "rifle_desert", false) || StrEqual(weapon, "rifle_sg552", false) || StrEqual(weapon, "rifle_m60", false))
	{
		maxammo = GetConVarInt(AssaultMaxAmmo);
	}
	else if (StrContains(weapon, "smg", false))
	{
		maxammo = GetConVarInt(SMGMaxAmmo);
	}		
	else if (StrEqual(weapon, "pumpshotgun", false) || StrEqual(weapon, "shotgun_chrome", false))
	{
		maxammo = GetConVarInt(ShotgunMaxAmmo);
	}
	else if (StrEqual(weapon, "autoshotgun", false) || StrEqual(weapon, "shotgun_spas", false))
	{
		maxammo = GetConVarInt(AutoShotgunMaxAmmo);
	}
	else if (StrEqual(weapon, "hunting_rifle", false))
	{
		maxammo = GetConVarInt(HRMaxAmmo);
	}	
	else if (StrContains(weapon, "sniper", false))
	{
		maxammo = GetConVarInt(SniperRifleMaxAmmo);
	}
	else if (StrEqual(weapon, "grenade_launcher", false))
	{
		maxammo = GetConVarInt(GrenadeLauncherMaxAmmo);
	}
	
	int i = 0;
	while (++i <= amount)
	{
		if(StrEqual(weapon, "weapon_explosive_barrel", false))
		{
			int ent = CreateEntityByName("prop_fuel_barrel");
			DispatchKeyValue(ent, "model", "models/props_industrial/barrel_fuel.mdl");
			DispatchKeyValue(ent, "BasePiece", "models/props_industrial/barrel_fuel_partb.mdl");
			DispatchKeyValue(ent, "FlyingPiece01", "models/props_industrial/barrel_fuel_parta.mdl");
			DispatchKeyValue(ent, "DetonateParticles", "weapon_pipebomb");
			DispatchKeyValue(ent, "FlyingParticles", "barrel_fly");
			DispatchKeyValue(ent, "DetonateSound", "BaseGrenade.Explode");
			DispatchSpawn(ent); 
			g_pos[2] -= 10.0-(i*2);
			TeleportEntity(ent, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
		}	
		else if(StrEqual(weapon, "weapon_laser_sight", false))
		{
			char position[64];
			int ent = CreateEntityByName("upgrade_spawn");
			DispatchKeyValue(ent, "count", "1");
			DispatchKeyValue(ent, "laser_sight", "1");
			Format(position, sizeof(position), "%1.1f %1.1f %1.1f", g_pos[0], g_pos[1], g_pos[2] -= 10.0-(i*2));
			DispatchKeyValue(ent, "origin", position);
			DispatchKeyValue(ent, "classname", "upgrade_spawn");
			DispatchSpawn(ent);
		}	
		else
		{
			int iWeapon = CreateEntityByName(weapon);
			if(IsValidEntity(iWeapon))
			{		
				DispatchSpawn(iWeapon); //Spawn weapon (entity)
				if (!StrEqual(weapon, "weapon_ammo_spawn", false))
				{
					SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4); //Adds max ammo for weapon
				}
				if (GetConVarInt(DebugInformations))
				{
					PrintToChat(client, "You spawned: %s", weapon);
				}
				g_pos[2] -= 10.0-(i*2);
				TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
			}
		}
	}
	return Plugin_Handled;
}	
/* >>> end of Spawn Weapon */

/* Give Weapon */
public Action Command_GiveWeapon(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "%t", "GiveWeaponUsage", LANG_SERVER);
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char weapon[65];
	GetCmdArg(2, weapon, sizeof(weapon));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		if ((strcmp(weapon, "laser_sight") == 0) || (strcmp(weapon, "explosive_ammo") == 0) || (strcmp(weapon, "incendiary_ammo") == 0))
		{
			int flagsupgrade_add = GetCommandFlags("upgrade_add");
			SetCommandFlags("upgrade_add", flagsupgrade_add & ~FCVAR_CHEAT);
			if (IsClientInGame(target_list[i])) FakeClientCommand(target_list[i], "upgrade_add %s", weapon);
			SetCommandFlags("upgrade_add", flagsupgrade_add|FCVAR_CHEAT);
		}
		else
		{
			int flagsgive = GetCommandFlags("give");
			SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
			if (IsClientInGame(target_list[i])) FakeClientCommand(target_list[i], "give %s", weapon);
			SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
		}
	}
	return Plugin_Handled;
}
/* >>> end of Give Weapon */

/* Spawn Zombie */
public Action Command_SpawnZombie(int client, int args)
{
	int amount;
	char zombie[56], arg2[5];

	if (client == 0)
	{
		GetCmdArg(1, zombie, sizeof(zombie));
		if(!StrEqual(zombie, "mob", false))
		{
			ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}

	if (args == 2)
	{
		GetCmdArg(1, zombie, sizeof(zombie));
		GetCmdArg(2, arg2, sizeof(arg2));
		amount = StringToInt(arg2);
	}
	else if (args == 1)
	{
		GetCmdArg(1, zombie, sizeof(zombie));
		amount = 1;
	}
	else
	{
		ReplyToCommand(client, "%t", "SpawnZombieUsage", LANG_SERVER);
		return Plugin_Handled;
	}

	int i = 0;
	while (++i <= amount)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			int flags = GetCommandFlags("z_spawn");
			SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "z_spawn %s", zombie);
			SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
		}
	}
	return Plugin_Handled;
}
/* >>> end of Spawn Zombie */

/* Minigun */
public Action Command_SpawnMinigun(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;	
	}
	if(args == 1)
	{
		char arg1[40];
		GetCmdArg(1, arg1, sizeof(arg1));
		if(StringToInt(arg1) == 0) return Plugin_Handled;
		switch(StringToInt(arg1))
		{
			case 1:
				SpawnMiniGun(client, 1);
			case 2:
				SpawnMiniGun(client, 2);
		}	
	}	
	return Plugin_Handled;
}

public void SpawnMiniGun(int client, int type)
{
	float VecOrigin[3], VecAngles[3], VecDirection[3];
	int minigun;
	switch(type)
	{
		case 1:
		{
			minigun = CreateEntityByName("prop_minigun");
			if (minigun == -1)
			{
				ReplyToCommand(client, "[SM] %t", "MinigunFailed", LANG_SERVER);
			}
			DispatchKeyValue(minigun, "model", "models/w_models/weapons/50cal.mdl");
		}	
		case 2:
		{
			minigun = CreateEntityByName("prop_minigun_l4d1");
			if (minigun == -1)
			{
				ReplyToCommand(client, "[SM] %t", "MinigunFailed", LANG_SERVER);
			}
			DispatchKeyValue(minigun, "model", "models/w_models/weapons/w_minigun.mdl");
		}	
	}		
	DispatchKeyValueFloat (minigun, "MaxPitch", 360.00);
	DispatchKeyValueFloat (minigun, "MinPitch", -360.00);
	DispatchKeyValueFloat (minigun, "MaxYaw", 90.00);
	DispatchSpawn(minigun);

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(minigun, "Angles", VecAngles);
	DispatchSpawn(minigun);
	TeleportEntity(minigun, VecOrigin, NULL_VECTOR, NULL_VECTOR);
}

public Action Command_RemoveMinigun(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;	
	}
	RemoveMiniGun(client);
	return Plugin_Handled;
}

public void RemoveMiniGun(int client)
{
	char Classname[128];
	int minigun = GetClientAimTarget(client, false);
	if ((minigun == -1) || (!IsValidEntity (minigun)))
	{
		ReplyToCommand (client, "[SM] %t","RemoveMinigunError_01");
		return;
	}
	GetEdictClassname(minigun, Classname, sizeof(Classname));
	if(StrEqual(Classname, "prop_minigun_l4d1", false) || StrEqual(Classname, "prop_minigun", false))
	{
		RemoveEdict(minigun);
	}
	else
	{
		ReplyToCommand (client, "[SM] %t", "RemoveMinigunError_02");
	}	
}
/* >>> end of Minigun */

/* Menu */
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;
	
	TopMenuObject menu_category = hAdminMenu.AddCategory("sm_ws_topmenu", Handle_Category);

	if (menu_category != INVALID_TOPMENUOBJECT)
	{
		hAdminMenu.AddItem("sm_sw_menu", AdminMenu_WeaponSpawner, menu_category, "sm_sw_menu", ADMFLAG_SLAY);
		hAdminMenu.AddItem("sm_gw_menu", AdminMenu_WeaponGive, menu_category, "sm_gw_menu", ADMFLAG_SLAY);
		hAdminMenu.AddItem("sm_spawn_menu", AdminMenu_ZombieSpawnMenu, menu_category, "sm_spawn_menu", ADMFLAG_SLAY);
		hAdminMenu.AddItem("sm_smg_menu", AdminMenu_MachineGunSpawnMenu, menu_category, "sm_smg_menu", ADMFLAG_SLAY);
	}
}

public void Handle_Category(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "What do you want?");
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "WeaponSpawner", LANG_SERVER);
	}
}

/* Weapon Spawn Menu */
public void AdminMenu_WeaponSpawner(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "SpawnWeapon", LANG_SERVER);
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayWeaponMenu(param);
	}
}

void DisplayWeaponMenu(int client)
{
	char melee[40], bulletbased[40], shellbased[40], explosivebased[40], healthrelated[40], misc[40], title[40];

	Menu menu = CreateMenu(MenuHandler_Weapons);

	SetMenuExitBackButton(menu, true);
	Format(melee, sizeof(melee),"%T", "MeleeWeapons", LANG_SERVER);
	AddMenuItem(menu, "g_MeleeMenu", melee);
	Format(bulletbased, sizeof(bulletbased),"%T", "BulletBased", LANG_SERVER);
	AddMenuItem(menu, "g_BulletBasedMenu", bulletbased);
	Format(shellbased, sizeof(shellbased),"%T", "ShellBased", LANG_SERVER);
	AddMenuItem(menu, "g_ShellBasedMenu", shellbased);
	Format(explosivebased, sizeof(explosivebased),"%T", "ExplosiveBased", LANG_SERVER);
	AddMenuItem(menu, "g_ExplosiveBasedMenu", explosivebased);
	Format(healthrelated, sizeof(healthrelated),"%T", "HealthRelated", LANG_SERVER);
	AddMenuItem(menu, "g_HealthMenu", healthrelated);
	Format(misc, sizeof(misc),"%T", "Misc", LANG_SERVER);
	AddMenuItem(menu, "g_MiscMenu", misc);
	Format(title, sizeof(title),"%T", "DisplayWeaponMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
					BuildMeleeMenu(param1);
				case 1:
					BuildBulletBasedMenu(param1);
				case 2:
					BuildShellBasedMenu(param1);
				case 3:
					BuildExplosiveBasedMenu(param1);
				case 4:
					BuildHealthMenu(param1);
				case 5:
					BuildMiscMenu(param1);
			}
		}
	}
}

void BuildMeleeMenu(int client)
{
	char fireaxe[40], crowbar[40], tonfa[40], baseball_bat[40], cricket_bat[40];
	char electric_guitar[40], golfclub[40], katana[40], frying_pan[40], knife[40];
	char machete[40], title[40];
	
	if (GetConVarInt(DebugInformations))
	{
		PrintToChat(client, "Map Name: %s", MapName);
	}

	if (GetConVarInt(AllowAllMeleeWeapons) == 0)
	{
		if ((StrEqual(MapName, "c1m1_hotel", false)) || (StrEqual(MapName, "c1m2_streets", false)) || (StrEqual(MapName, "c1m3_mall", false)) || (StrEqual(MapName, "c1m4_atrium", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", "Cricket Bat");
			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
				
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Dead Center");
			}
		}
		else if ((StrEqual(MapName, "c2m1_highway", false)) || (StrEqual(MapName, "c2m2_fairgrounds", false)) || (StrEqual(MapName, "c2m3_coaster", false)) || (StrEqual(MapName, "c2m4_barns", false)) || (StrEqual(MapName, "c2m5_concert", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
			AddMenuItem(menu, "electric_guitar", electric_guitar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
				
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Dark Carnival");
			}
		}
		else if ((StrEqual(MapName, "c3m1_plankcountry", false)) || (StrEqual(MapName, "c3m2_swamp", false)) || (StrEqual(MapName, "c3m3_shantytown", false)) || (StrEqual(MapName, "c3m4_plantation", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", cricket_bat);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
			AddMenuItem(menu, "machete", machete);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Swamp Fever");
			}
		}
		else if ((StrEqual(MapName, "c4m1_milltown_a", false)) || (StrEqual(MapName, "c4m2_sugarmill_a", false)) || (StrEqual(MapName, "c4m3_sugarmill_b", false)) || (StrEqual(MapName, "c4m4_milltown_b", false)) || (StrEqual(MapName, "c4m5_milltown_escape", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Hard Rain");
			}
		}
		else if ((StrEqual(MapName, "c5m1_waterfront", false)) || (StrEqual(MapName, "c5m1_waterfront_sndscape", false)) || (StrEqual(MapName, "c5m2_park", false)) || (StrEqual(MapName, "c5m3_cemetery", false)) || (StrEqual(MapName, "c5m4_quarter", false)) || (StrEqual(MapName, "c5m5_bridge", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
			AddMenuItem(menu, "electric_guitar", electric_guitar);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
			AddMenuItem(menu, "machete", machete);
			Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER);
			AddMenuItem(menu, "tonfa", tonfa);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Parish");
			}
		}
		else if ((StrEqual(MapName, "c6m1_riverbank", false)) || (StrEqual(MapName, "c6m2_bedlam", false)) || (StrEqual(MapName, "c6m3_port", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(golfclub, sizeof(golfclub),"%T", "Golfclub", LANG_SERVER);
			AddMenuItem(menu, "golfclub", golfclub);		
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Passing");
			}
		}	
		else if ((StrEqual(MapName, "c7m1_docks", false)) || (StrEqual(MapName, "c7m2_barge", false)) || (StrEqual(MapName, "c7m3_port", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", cricket_bat);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Sacrifice");
			}
		}
		else if ((StrEqual(MapName, "c8m1_apartment", false)) || (StrEqual(MapName, "c8m2_subway", false)) || (StrEqual(MapName, "c8m3_sewers", false)) || (StrEqual(MapName, "c8m4_interior", false)) || (StrEqual(MapName, "c8m5_rooftop", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", cricket_bat);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: No Mercy");
			}
		}
		else
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", "Cricket Bat");
			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
			AddMenuItem(menu, "electric_guitar", electric_guitar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
			AddMenuItem(menu, "machete", machete);
			Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER);
			AddMenuItem(menu, "tonfa", tonfa);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Custom");
			}
		}
	}
}

void BuildBulletBasedMenu(int client)
{
	char hunting_rifle[40], pistol[40], pistol_magnum[40], rifle[40], title[40];
	char rifle_desert[40], smg[40], smg_silenced[40], sniper_military[40], rifle_ak47[40];
	char rifle_sg552[40], smg_mp5[40], sniper_awp[40], sniper_scout[40], rifle_m60[40];

	Menu menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(hunting_rifle, sizeof(hunting_rifle),"%T", "HuntingRifle", LANG_SERVER);
	AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle);
	Format(pistol, sizeof(pistol),"%T", "Pistol", LANG_SERVER);
	AddMenuItem(menu, "weapon_pistol", pistol);
	Format(pistol_magnum, sizeof(pistol_magnum),"%T", "DesertEagle", LANG_SERVER);
	AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum);
	Format(rifle, sizeof(rifle),"%T", "Rifle", LANG_SERVER);
	AddMenuItem(menu, "weapon_rifle", rifle);
	Format(rifle_desert, sizeof(rifle_desert),"%T", "DesertRifle", LANG_SERVER);
	AddMenuItem(menu, "weapon_rifle_desert", rifle_desert);
	Format(smg, sizeof(smg),"%T", "SubmachineGun", LANG_SERVER);
	AddMenuItem(menu, "weapon_smg", smg);
	Format(smg_silenced, sizeof(smg_silenced),"%T", "SilencedSubmachineGun", LANG_SERVER);
	AddMenuItem(menu, "weapon_smg_silenced", smg_silenced);
	Format(sniper_military, sizeof(sniper_military),"%T", "MilitarySniper", LANG_SERVER);
	AddMenuItem(menu, "weapon_sniper_military", sniper_military);
	Format(rifle_ak47, sizeof(rifle_ak47),"%T", "AvtomatKalashnikova", LANG_SERVER);
	AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47);
	Format(rifle_sg552, sizeof(rifle_sg552),"%T", "SIGSG550", LANG_SERVER);
	AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552);
	Format(smg_mp5, sizeof(smg_mp5),"%T", "SubmachineGunMP5", LANG_SERVER);
	AddMenuItem(menu, "weapon_smg_mp5", smg_mp5);
	Format(rifle_m60, sizeof(rifle_m60),"%T", "RifleM60", LANG_SERVER);
	AddMenuItem(menu, "weapon_rifle_m60", rifle_m60);
	Format(sniper_awp, sizeof(sniper_awp),"%T", "AWP", LANG_SERVER);
	AddMenuItem(menu, "weapon_sniper_awp", sniper_awp);
	Format(sniper_scout, sizeof(sniper_scout),"%T", "ScoutSniper", LANG_SERVER);
	AddMenuItem(menu, "weapon_sniper_scout", sniper_scout);
	Format(title, sizeof(title),"%T", "BulletBasedMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuSpawn[client] = "BulletBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildShellBasedMenu(int client)
{
	char autoshotgun[40], shotgun_chrome[40], shotgun_spas[40], pumpshotgun[40], title[40]; 
	
	Menu menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(autoshotgun, sizeof(autoshotgun),"%T", "AutoShotgun", LANG_SERVER);
	AddMenuItem(menu, "weapon_autoshotgun", autoshotgun);
	Format(shotgun_chrome, sizeof(shotgun_chrome),"%T", "ChromeShotgun", LANG_SERVER);
	AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome);
	Format(shotgun_spas, sizeof(shotgun_spas),"%T", "SpasShotgun", LANG_SERVER);
	AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas);
	Format(pumpshotgun, sizeof(pumpshotgun),"%T", "PumpShotgun", LANG_SERVER);
	AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun);
	Format(title, sizeof(title),"%T", "ShellBasedMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuSpawn[client] = "ShellBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildExplosiveBasedMenu(int client)
{
	char grenade_launcher[40], fireworkcrate[40], gascan[40], molotov[40], oxygentank[40], pipe_bomb[40], propanetank[40], explosivebarrel[40], title[40];

	Menu menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(grenade_launcher, sizeof(grenade_launcher),"%T", "GrenadeLauncher", LANG_SERVER);
	AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher);
	Format(explosivebarrel, sizeof(explosivebarrel),"%T", "ExplosiveBarrel", LANG_SERVER);
	AddMenuItem(menu, "weapon_explosive_barrel", explosivebarrel);
	Format(fireworkcrate, sizeof(fireworkcrate),"%T", "FireworksCrate", LANG_SERVER);
	AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate);
	Format(gascan, sizeof(gascan),"%T", "Gascan", LANG_SERVER);
	AddMenuItem(menu, "weapon_gascan", gascan);
	Format(molotov, sizeof(molotov),"%T", "Molotov", LANG_SERVER);
	AddMenuItem(menu, "weapon_molotov", molotov);
	Format(oxygentank, sizeof(oxygentank),"%T", "OxygenTank", LANG_SERVER);
	AddMenuItem(menu, "weapon_oxygentank", oxygentank);
	Format(pipe_bomb, sizeof(pipe_bomb),"%T", "PipeBomb", LANG_SERVER);
	AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb);
	Format(propanetank, sizeof(propanetank),"%T", "PropaneTank", LANG_SERVER);
	AddMenuItem(menu, "weapon_propanetank", propanetank);
	Format(title, sizeof(title),"%T", "ExplosiveBasedMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuSpawn[client] = "ExplosiveBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildHealthMenu(int client)
{
	char adrenaline[40], defibrillator[40], first_aid_kit[40], pain_pills[40], title[40]; 

	Menu menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(adrenaline, sizeof(adrenaline),"%T", "Adrenaline", LANG_SERVER);
	AddMenuItem(menu, "weapon_adrenaline", adrenaline);
	Format(defibrillator, sizeof(defibrillator),"%T", "Defibrillator", LANG_SERVER);
	AddMenuItem(menu, "weapon_defibrillator", defibrillator);
	Format(first_aid_kit, sizeof(first_aid_kit),"%T", "FirstAidKit", LANG_SERVER);
	AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit);
	Format(pain_pills, sizeof(pain_pills),"%T", "PainPills", LANG_SERVER);
	AddMenuItem(menu, "weapon_pain_pills", "Pain Pills");
	Format(title, sizeof(title),"%T", "HealthMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuSpawn[client] = "HealthSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildMiscMenu(int client)
{
	char chainsaw[40], ammo_spawn[40], upgradepack_explosive[40], upgradepack_incendiary[40], vomitjar[40], gnome[40], cola[40], laser_sight_box[40], title[40];
	
	Menu menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(chainsaw, sizeof(chainsaw),"%T", "ChainSaw", LANG_SERVER);
	AddMenuItem(menu, "weapon_chainsaw", chainsaw);
	Format(ammo_spawn, sizeof(ammo_spawn),"%T", "AmmoStack", LANG_SERVER);
	AddMenuItem(menu, "weapon_ammo_spawn", ammo_spawn);
	Format(laser_sight_box, sizeof(laser_sight_box),"%T", "LaserSightBox", LANG_SERVER);
	AddMenuItem(menu, "weapon_laser_sight", laser_sight_box);
	Format(upgradepack_explosive, sizeof(upgradepack_explosive),"%T", "ExplosiveAmmoPack", LANG_SERVER);
	AddMenuItem(menu, "weapon_upgradepack_explosive", upgradepack_explosive);
	Format(upgradepack_incendiary, sizeof(upgradepack_incendiary),"%T", "IncendiaryAmmoPack", LANG_SERVER);
	AddMenuItem(menu, "weapon_upgradepack_incendiary", upgradepack_incendiary);
	Format(vomitjar, sizeof(vomitjar),"%T", "VomitJar", LANG_SERVER);
	AddMenuItem(menu, "weapon_vomitjar", vomitjar);
	Format(gnome, sizeof(gnome),"%T", "Gnome", LANG_SERVER);
	AddMenuItem(menu, "weapon_gnome", gnome);
	Format(cola, sizeof(cola),"%T", "Cola", LANG_SERVER);
	AddMenuItem(menu, "weapon_cola_bottles", cola);
	Format(title, sizeof(title),"%T", "MiscMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuSpawn[client] = "MiscSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SpawnWeapon(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayWeaponMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char weapon[32];
			int maxammo;

			GetMenuItem(menu, param2, weapon, sizeof(weapon));

			if(!SetTeleportEndPoint(param1))
			{
				PrintToChat(param1, "[SM] %T", "SpawnError", LANG_SERVER);
			}
			
			if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_m60", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
			{
				maxammo = GetConVarInt(AssaultMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_smg", false) || StrEqual(weapon, "weapon_smg_silenced", false) || StrEqual(weapon, "weapon_smg_mp5", false))
			{
				maxammo = GetConVarInt(SMGMaxAmmo);
			}		
			else if (StrEqual(weapon, "weapon_pumpshotgun", false) || StrEqual(weapon, "weapon_shotgun_chrome", false))
			{
				maxammo = GetConVarInt(ShotgunMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun", false) || StrEqual(weapon, "weapon_shotgun_spas", false))
			{
				maxammo = GetConVarInt(AutoShotgunMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle", false))
			{
				maxammo = GetConVarInt(HRMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_sniper_military", false) || StrEqual(weapon, "weapon_sniper_awp", false) || StrEqual(weapon, "weapon_sniper_scout", false))
			{
				maxammo = GetConVarInt(SniperRifleMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher", false))
			{
				maxammo = GetConVarInt(GrenadeLauncherMaxAmmo);
			}
			if(StrEqual(weapon, "weapon_explosive_barrel", false))
			{
				int ent = CreateEntityByName("prop_fuel_barrel");
				DispatchKeyValue(ent, "model", "models/props_industrial/barrel_fuel.mdl");
				DispatchKeyValue(ent, "BasePiece", "models/props_industrial/barrel_fuel_partb.mdl");
				DispatchKeyValue(ent, "FlyingPiece01", "models/props_industrial/barrel_fuel_parta.mdl");
				DispatchKeyValue(ent, "DetonateParticles", "weapon_pipebomb");
				DispatchKeyValue(ent, "FlyingParticles", "barrel_fly");
				DispatchKeyValue(ent, "DetonateSound", "BaseGrenade.Explode");
				DispatchSpawn(ent); 
				g_pos[2] -= 10.0;
				TeleportEntity(ent, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
			}	
			else if(StrEqual(weapon, "weapon_laser_sight", false))
			{
				char position[64];
				int ent = CreateEntityByName("upgrade_spawn");
				DispatchKeyValue(ent, "count", "1");
				DispatchKeyValue(ent, "laser_sight", "1");
				Format(position, sizeof(position), "%1.1f %1.1f %1.1f", g_pos[0], g_pos[1], g_pos[2] -= 10.0);
				DispatchKeyValue(ent, "origin", position);
				DispatchKeyValue(ent, "classname", "upgrade_spawn");
				DispatchSpawn(ent);
			}	
			else
			{
				int iWeapon = CreateEntityByName(weapon);
				if(IsValidEntity(iWeapon))
				{		
					DispatchSpawn(iWeapon); //Spawn weapon (entity)
					if (!StrEqual(weapon, "weapon_ammo_spawn", false))
					{
						SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4); //Adds max ammo for weapon
					}
				}
				g_pos[2] -= 10.0;
				TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
			}
			ChoosedSpawnMenuHistory(param1); //Redraw menu after item selection
		}
	}
}

public int MenuHandler_SpawnMelee(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayWeaponMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char weapon[32];

			GetMenuItem(menu, param2, weapon, sizeof(weapon));

			if(!SetTeleportEndPoint(param1))
			{
				PrintToChat(param1, "[SM] %T", "SpawnError", LANG_SERVER);
			}

			int iWeapon = CreateEntityByName("weapon_melee");

			if(IsValidEntity(iWeapon))
			{
				DispatchKeyValue(iWeapon, "melee_script_name", weapon);
				DispatchSpawn(iWeapon); //Spawn weapon (entity)
				g_pos[2] -= 10.0;
				TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
				char ModelName[128];
				GetEntPropString(iWeapon, Prop_Data, "m_ModelName", ModelName, 128); 
				if( StrContains( ModelName, "hunter", false ) != -1)
				{
					RemoveEdict(iWeapon);
				}	
				if (GetConVarInt(DebugInformations))
				{
					PrintToChat(param1, "You spawned: %s", weapon);
				}
			}
			ChoosedSpawnMenuHistory(param1); //Redraw menu after item selection
		}
	}
}

stock void ChoosedSpawnMenuHistory(int param1)
{
	if (strcmp(ChoosedMenuSpawn[param1], "MeleeBasedSpawnMenu") == 0)
	{
		BuildMeleeMenu(param1);
	}
	if (strcmp(ChoosedMenuSpawn[param1], "BulletBasedSpawnMenu") == 0)
	{
		BuildBulletBasedMenu(param1);
	}
	else if (strcmp(ChoosedMenuSpawn[param1], "ShellBasedSpawnMenu") == 0)
	{
		BuildShellBasedMenu(param1);
	}
	else if (strcmp(ChoosedMenuSpawn[param1], "ExplosiveBasedSpawnMenu") == 0)
	{
		BuildExplosiveBasedMenu(param1);
	}
	else if (strcmp(ChoosedMenuSpawn[param1], "HealthSpawnMenu") == 0)
	{
		BuildHealthMenu(param1);
	}
	else if (strcmp(ChoosedMenuSpawn[param1], "MiscSpawnMenu") == 0)
	{
		BuildMiscMenu(param1);
	}
}
/* >>> end of Weapon Spawn Menu */

/* Weapon Give Menu */
public void AdminMenu_WeaponGive(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(topmenu);
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "Give Weapon");
		case TopMenuAction_SelectOption:
			DisplayWeaponGiveMenu(param);
	}
}

void DisplayWeaponGiveMenu(int client)
{
	char MeleeGiveMenu[40], BulletBasedGiveMenu[40], ShellBasedGiveMenu[40];
	char ExplosiveBasedGiveMenu[40], HealthGiveMenu[40], MiscGiveMenu[40], title[40]; 
	
	Menu menu = CreateMenu(MenuHandler_GiveWeapons);
	
	Format(MeleeGiveMenu, sizeof(MeleeGiveMenu),"%T", "MeleeWeapons", LANG_SERVER);
	AddMenuItem(menu, "g_MeleeGiveMenu", MeleeGiveMenu);
	Format(BulletBasedGiveMenu, sizeof(BulletBasedGiveMenu),"%T", "BulletBased", LANG_SERVER);
	AddMenuItem(menu, "g_BulletBasedGiveMenu", BulletBasedGiveMenu);
	Format(ShellBasedGiveMenu, sizeof(ShellBasedGiveMenu),"%T", "ShellBased", LANG_SERVER);
	AddMenuItem(menu, "g_ShellBasedGiveMenu", ShellBasedGiveMenu);
	Format(ExplosiveBasedGiveMenu, sizeof(ExplosiveBasedGiveMenu),"%T", "ExplosiveBased", LANG_SERVER);
	AddMenuItem(menu, "g_ExplosiveBasedGiveMenu", ExplosiveBasedGiveMenu);
	Format(HealthGiveMenu, sizeof(HealthGiveMenu),"%T", "HealthRelated", LANG_SERVER);
	AddMenuItem(menu, "g_HealthGiveMenu", HealthGiveMenu);
	Format(MiscGiveMenu, sizeof(MiscGiveMenu),"%T", "Misc", LANG_SERVER);
	AddMenuItem(menu, "g_MiscGiveMenu", MiscGiveMenu);
	Format(title, sizeof(title),"%T", "WeaponGiveMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GiveWeapons(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
					BuildMeleeGiveMenu(param1);
				case 1:
					BuildBulletBasedGiveMenu(param1);
				case 2:
					BuildShellBasedGiveMenu(param1);
				case 3:
					BuildExplosiveBasedGiveMenu(param1);
				case 4:
					BuildHealthGiveMenu(param1);
				case 5:
					BuildMiscGiveMenu(param1);
			}
		}
	}
}

void BuildMeleeGiveMenu(int client)
{
	char baseball_bat[40], cricket_bat[40], crowbar[40], electric_guitar[40], fireaxe[40];
	char frying_pan[40], katana[40], machete[40], tonfa[40], knife[40], golfclub[40], title[40];

	if (GetConVarInt(DebugInformations))
	{
		PrintToChat(client, "Map Name: %s", MapName);
	}

	if (GetConVarInt(AllowAllMeleeWeapons) == 0)
	{
		if ((StrEqual(MapName, "c1m1_hotel", false)) || (StrEqual(MapName, "c1m2_streets", false)) || (StrEqual(MapName, "c1m3_mall", false)) || (StrEqual(MapName, "c1m4_atrium", false)))
		{
			Menu menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", "Cricket Bat");
			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
				
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Dead Center");
			}
		}
		else if ((StrEqual(MapName, "c2m1_highway", false)) || (StrEqual(MapName, "c2m2_fairgrounds", false)) || (StrEqual(MapName, "c2m3_coaster", false)) || (StrEqual(MapName, "c2m4_barns", false)) || (StrEqual(MapName, "c2m5_concert", false)))
		{
			Menu menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
			AddMenuItem(menu, "electric_guitar", electric_guitar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
				
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Dark Carnival");
			}
		}
		else if ((StrEqual(MapName, "c3m1_plankcountry", false)) || (StrEqual(MapName, "c3m2_swamp", false)) || (StrEqual(MapName, "c3m3_shantytown", false)) || (StrEqual(MapName, "c3m4_plantation", false)))
		{
			Menu menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", "Cricket Bat");
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
			AddMenuItem(menu, "machete", machete);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Swamp Fever");
			}
		}
		else if ((StrEqual(MapName, "c4m1_milltown_a", false)) || (StrEqual(MapName, "c4m2_sugarmill_a", false)) || (StrEqual(MapName, "c4m3_sugarmill_b", false)) || (StrEqual(MapName, "c4m4_milltown_b", false)) || (StrEqual(MapName, "c4m5_milltown_escape", false)))
		{
			Menu menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Hard Rain");
			}
		}
		else if ((StrEqual(MapName, "c5m1_waterfront", false)) || (StrEqual(MapName, "c5m1_waterfront_sndscape", false)) || (StrEqual(MapName, "c5m2_park", false)) || (StrEqual(MapName, "c5m3_cemetery", false)) || (StrEqual(MapName, "c5m4_quarter", false)) || (StrEqual(MapName, "c5m5_bridge", false)))
		{
			Menu menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
			AddMenuItem(menu, "electric_guitar", electric_guitar);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
			AddMenuItem(menu, "machete", machete);
			Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER);
			AddMenuItem(menu, "tonfa", tonfa);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Parish");
			}
		}
		else if ((StrEqual(MapName, "c6m1_riverbank", false)) || (StrEqual(MapName, "c6m2_bedlam", false)) || (StrEqual(MapName, "c6m3_port", false)))
		{
			Menu menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(golfclub, sizeof(golfclub),"%T", "Golfclub", LANG_SERVER);
			AddMenuItem(menu, "golfclub", golfclub);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Passing");
			}
		}	
		else if ((StrEqual(MapName, "c7m1_docks", false)) || (StrEqual(MapName, "c7m2_barge", false)) || (StrEqual(MapName, "c7m3_port", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", cricket_bat);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Sacrifice");
			}
		}
		else if ((StrEqual(MapName, "c8m1_apartment", false)) || (StrEqual(MapName, "c8m2_subway", false)) || (StrEqual(MapName, "c8m3_sewers", false)) || (StrEqual(MapName, "c8m4_interior", false)) || (StrEqual(MapName, "c8m5_rooftop", false)))
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", cricket_bat);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: No Mercy");
			}
		}
		else
		{
			Menu menu = CreateMenu(MenuHandler_SpawnMelee);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
			AddMenuItem(menu, "cricket_bat", "Cricket Bat");
			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
			AddMenuItem(menu, "crowbar", crowbar);
			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
			AddMenuItem(menu, "electric_guitar", electric_guitar);
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
			AddMenuItem(menu, "fireaxe", fireaxe);
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
			AddMenuItem(menu, "frying_pan", frying_pan);
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
			AddMenuItem(menu, "katana", katana);
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
			AddMenuItem(menu, "machete", machete);
			Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER);
			AddMenuItem(menu, "tonfa", tonfa);
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
			AddMenuItem(menu, "baseball_bat", baseball_bat);
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
			AddMenuItem(menu, "knife", knife);
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
			SetMenuTitle(menu, title);
			SetMenuExitBackButton(menu, true);

			ChoosedMenuSpawn[client] = "MeleeBasedSpawnMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Custom");
			}
		}
	}
	else
	{
		Menu menu = CreateMenu(MenuHandler_GiveWeapon);

		Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER);
		AddMenuItem(menu, "cricket_bat", "Cricket Bat");
		Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER);
		AddMenuItem(menu, "crowbar", crowbar);
		Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER);
		AddMenuItem(menu, "electric_guitar", electric_guitar);
		Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER);
		AddMenuItem(menu, "fireaxe", fireaxe);
		Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER);
		AddMenuItem(menu, "frying_pan", frying_pan);
		Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER);
		AddMenuItem(menu, "katana", katana);
		Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER);
		AddMenuItem(menu, "machete", machete);
		Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER);
		AddMenuItem(menu, "tonfa", tonfa);
		Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER);
		AddMenuItem(menu, "baseball_bat", baseball_bat);
		Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER);
		AddMenuItem(menu, "knife", knife);
		Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);

		ChoosedMenuGive[client] = "MeleeGiveMenu";
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

void BuildBulletBasedGiveMenu(int client)
{
	char hunting_rifle[40], pistol[40], pistol_magnum[40], rifle[40], rifle_desert[40];
	char smg[40], smg_silenced[40], sniper_military[40], rifle_ak47[40], rifle_sg552[40], rifle_m60[40];
	char smg_mp5[40], sniper_awp[40], sniper_scout[40], title[40];

	Menu menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(hunting_rifle, sizeof(hunting_rifle),"%T", "HuntingRifle", LANG_SERVER);
	AddMenuItem(menu, "hunting_rifle", hunting_rifle);
	Format(pistol, sizeof(pistol),"%T", "Pistol", LANG_SERVER);
	AddMenuItem(menu, "pistol", pistol);
	Format(pistol_magnum, sizeof(pistol_magnum),"%T", "DesertEagle", LANG_SERVER);
	AddMenuItem(menu, "pistol_magnum", pistol_magnum);
	Format(rifle, sizeof(rifle),"%T", "Rifle", LANG_SERVER);
	AddMenuItem(menu, "rifle", rifle);
	Format(rifle_desert, sizeof(rifle_desert),"%T", "DesertRifle", LANG_SERVER);
	AddMenuItem(menu, "rifle_desert", rifle_desert);
	Format(smg, sizeof(smg),"%T", "SubmachineGun", LANG_SERVER);
	AddMenuItem(menu, "smg", smg);
	Format(smg_silenced, sizeof(smg_silenced),"%T", "SilencedSubmachineGun", LANG_SERVER);
	AddMenuItem(menu, "smg_silenced", smg_silenced);
	Format(sniper_military, sizeof(sniper_military),"%T", "MilitarySniper", LANG_SERVER);
	AddMenuItem(menu, "sniper_military", sniper_military);
	Format(rifle_ak47, sizeof(rifle_ak47),"%T", "AvtomatKalashnikova", LANG_SERVER);
	AddMenuItem(menu, "rifle_ak47", rifle_ak47);
	Format(rifle_sg552, sizeof(rifle_sg552),"%T", "SIGSG550", LANG_SERVER);
	AddMenuItem(menu, "rifle_sg552", rifle_sg552);
	Format(smg_mp5, sizeof(smg_mp5),"%T", "SubmachineGunMP5", LANG_SERVER);
	AddMenuItem(menu, "smg_mp5", smg_mp5);
	Format(rifle_m60, sizeof(rifle_m60),"%T", "RifleM60", LANG_SERVER);
	AddMenuItem(menu, "rifle_m60", rifle_m60);
	Format(sniper_awp, sizeof(sniper_awp),"%T", "AWP", LANG_SERVER);
	AddMenuItem(menu, "sniper_awp", sniper_awp);
	Format(sniper_scout, sizeof(sniper_scout),"%T", "ScoutSniper", LANG_SERVER);
	AddMenuItem(menu, "sniper_scout", sniper_scout);
	Format(title, sizeof(title),"%T", "BulletBasedMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuGive[client] = "BulletBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildShellBasedGiveMenu(int client)
{
	char autoshotgun[40], shotgun_chrome[40], shotgun_spas[40], pumpshotgun[40], title[40]; 
	
	Menu menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(autoshotgun, sizeof(autoshotgun),"%T", "AutoShotgun", LANG_SERVER);
	AddMenuItem(menu, "autoshotgun", autoshotgun);
	Format(shotgun_chrome, sizeof(shotgun_chrome),"%T", "ChromeShotgun", LANG_SERVER);
	AddMenuItem(menu, "shotgun_chrome", shotgun_chrome);
	Format(shotgun_spas, sizeof(shotgun_spas),"%T", "SpasShotgun", LANG_SERVER);
	AddMenuItem(menu, "shotgun_spas", shotgun_spas);
	Format(pumpshotgun, sizeof(pumpshotgun),"%T", "PumpShotgun", LANG_SERVER);
	AddMenuItem(menu, "pumpshotgun", pumpshotgun);
	Format(title, sizeof(title),"%T", "ShellBasedMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	ChoosedMenuGive[client] = "ShellBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildExplosiveBasedGiveMenu(int client)
{
	char grenade_launcher[40], fireworkcrate[40], gascan[40], molotov[40], oxygentank[40];
	char pipe_bomb[40], propanetank[40], title[40];

	Menu menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(grenade_launcher, sizeof(grenade_launcher),"%T", "GrenadeLauncher", LANG_SERVER);
	AddMenuItem(menu, "grenade_launcher", grenade_launcher);
	Format(fireworkcrate, sizeof(fireworkcrate),"%T", "FireworksCrate", LANG_SERVER);
	AddMenuItem(menu, "fireworkcrate", fireworkcrate);
	Format(gascan, sizeof(gascan),"%T", "Gascan", LANG_SERVER);
	AddMenuItem(menu, "gascan", gascan);
	Format(molotov, sizeof(molotov),"%T", "Molotov", LANG_SERVER);
	AddMenuItem(menu, "molotov", molotov);
	Format(oxygentank, sizeof(oxygentank),"%T", "OxygenTank", LANG_SERVER);
	AddMenuItem(menu, "oxygentank", oxygentank);
	Format(pipe_bomb, sizeof(pipe_bomb),"%T", "PipeBomb", LANG_SERVER);
	AddMenuItem(menu, "pipe_bomb", pipe_bomb);
	Format(propanetank, sizeof(propanetank),"%T", "PropaneTank", LANG_SERVER);
	AddMenuItem(menu, "propanetank", propanetank);
	Format(title, sizeof(title),"%T", "ExplosiveBasedMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	ChoosedMenuGive[client] = "ExplosiveBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildHealthGiveMenu(int client)
{
	char adrenaline[40], defibrillator[40], first_aid_kit[40], pain_pills[40], health[40], title[40];

	Menu menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(health, sizeof(health),"%T", "FullHealth", LANG_SERVER);
	AddMenuItem(menu, "health", health);
	Format(adrenaline, sizeof(adrenaline),"%T", "Adrenaline", LANG_SERVER);
	AddMenuItem(menu, "adrenaline", adrenaline);
	Format(defibrillator, sizeof(defibrillator),"%T", "Defibrillator", LANG_SERVER);
	AddMenuItem(menu, "defibrillator", defibrillator);
	Format(first_aid_kit, sizeof(first_aid_kit),"%T", "FirstAidKit", LANG_SERVER);
	AddMenuItem(menu, "first_aid_kit", first_aid_kit);
	Format(pain_pills, sizeof(pain_pills),"%T", "PainPills", LANG_SERVER);
	AddMenuItem(menu, "pain_pills", "Pain Pills");
	Format(title, sizeof(title),"%T", "HealthMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	ChoosedMenuGive[client] = "HealthGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void BuildMiscGiveMenu(int client)
{
	char chainsaw[40], ammo[40], upgradepack_explosive[40], upgradepack_incendiary[40];
	char vomitjar[40], gnome[40], cola[40], title[40];
	char laser_sight[40], explosive_ammo[40], incendiary_ammo[40];
	
	Menu menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(chainsaw, sizeof(chainsaw),"%T", "ChainSaw", LANG_SERVER);
	AddMenuItem(menu, "chainsaw", chainsaw);
	Format(ammo, sizeof(ammo),"%T", "Ammo", LANG_SERVER);
	AddMenuItem(menu, "ammo", ammo);
	Format(laser_sight, sizeof(laser_sight),"%T", "LaserSight", LANG_SERVER);
	AddMenuItem(menu, "laser_sight", laser_sight);
	Format(explosive_ammo, sizeof(explosive_ammo),"%T", "ExplosiveAmmo", LANG_SERVER);
	AddMenuItem(menu, "explosive_ammo", explosive_ammo);
	Format(incendiary_ammo, sizeof(incendiary_ammo),"%T", "IncendiaryAmmo", LANG_SERVER);
	AddMenuItem(menu, "incendiary_ammo", incendiary_ammo);
	Format(upgradepack_explosive, sizeof(upgradepack_explosive),"%T", "ExplosiveAmmoPack", LANG_SERVER);
	AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive);
	Format(upgradepack_incendiary, sizeof(upgradepack_incendiary),"%T", "IncendiaryAmmoPack", LANG_SERVER);
	AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary);
	Format(vomitjar, sizeof(vomitjar),"%T", "VomitJar", LANG_SERVER);
	AddMenuItem(menu, "vomitjar", vomitjar);
	Format(gnome, sizeof(gnome),"%T", "Gnome", LANG_SERVER);
	AddMenuItem(menu, "gnome", gnome);
	Format(cola, sizeof(cola),"%T", "Cola", LANG_SERVER);
	AddMenuItem(menu, "weapon_cola_bottles", cola);
	Format(title, sizeof(title),"%T", "MiscMenuTitle", LANG_SERVER);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	ChoosedMenuGive[client] = "MiscGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_GiveWeapon(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				DisplayWeaponGiveMenu(param1);
			}
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			/* Save choosed weapon */
			ChoosedWeapon[param1] = info;
			DisplaySelectPlayerMenu(param1);
		}
	}
}

void DisplaySelectPlayerMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_PlayerSelect);

	SetMenuTitle(menu, "Select Player");
	SetMenuExitBackButton(menu, true);

	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_PlayerSelect(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{	
				ChoosedGiveMenuHistory(param1);
			}
		}
		case MenuAction_Select:
		{
			char info[56];
			GetMenuItem(menu, param2, info, sizeof(info));

			int target = GetClientOfUserId(StringToInt(info));

			if ((target) == 0)
			{
				PrintToChat(param1, "Player no longer available");
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "Unable to target");
			}

			if ((strcmp(ChoosedWeapon[param1], "laser_sight") == 0) || (strcmp(ChoosedWeapon[param1], "explosive_ammo") == 0) || (strcmp(ChoosedWeapon[param1], "incendiary_ammo") == 0))
			{
				int flagsupgrade_add = GetCommandFlags("upgrade_add");
				SetCommandFlags("upgrade_add", flagsupgrade_add & ~FCVAR_CHEAT);
				if (IsClientInGame(target)) FakeClientCommand(target, "upgrade_add %s", ChoosedWeapon[param1]);
				SetCommandFlags("upgrade_add", flagsupgrade_add|FCVAR_CHEAT);
				ChoosedGiveMenuHistory(param1);
			}
			else
			{
				int flagsgive = GetCommandFlags("give");
				SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
				if (IsClientInGame(target)) FakeClientCommand(target, "give %s", ChoosedWeapon[param1]);
				SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
				ChoosedGiveMenuHistory(param1);
			}
		}
	}
}

stock void ChoosedGiveMenuHistory(int param1)
{
	if (strcmp(ChoosedMenuGive[param1], "MeleeGiveMenu") == 0)
	{
		BuildMeleeGiveMenu(param1);
	}
	else if (strcmp(ChoosedMenuGive[param1], "BulletBasedGiveMenu") == 0)
	{
		BuildBulletBasedGiveMenu(param1);
	}
	else if (strcmp(ChoosedMenuGive[param1], "ShellBasedGiveMenu") == 0)
	{
		BuildShellBasedGiveMenu(param1);
	}
	else if (strcmp(ChoosedMenuGive[param1], "ExplosiveBasedGiveMenu") == 0)
	{
		BuildExplosiveBasedGiveMenu(param1);
	}
	else if (strcmp(ChoosedMenuGive[param1], "HealthGiveMenu") == 0)
	{
		BuildHealthGiveMenu(param1);
	}
	else if (strcmp(ChoosedMenuGive[param1], "MiscGiveMenu") == 0)
	{
		BuildMiscGiveMenu(param1);
	}
}
/* >>> end of Weapon Give Menu */

/* Spawn Special Zombie Menu */
public void AdminMenu_ZombieSpawnMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Special Zombie");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplaySpecialZombieMenu(param);
	}
}

void DisplaySpecialZombieMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_SpecialZombie);
	
	SetMenuExitBackButton(menu, true);
	AddMenuItem(menu, "boomer", "Boomer");
	AddMenuItem(menu, "charger", "Charger");
	AddMenuItem(menu, "hunter", "Hunter");
	AddMenuItem(menu, "smoker", "Smoker");
	AddMenuItem(menu, "spitter", "Spitter");
	AddMenuItem(menu, "tank", "Tank");
	AddMenuItem(menu, "jockey", "Jockey");
	AddMenuItem(menu, "witch", "Witch");
	AddMenuItem(menu, "witch_bride", "Bride Witch");
	AddMenuItem(menu, "zombie", "One Zombie ;-)");
	AddMenuItem(menu, "mob", "Zombie Mob");
	SetMenuTitle(menu, "Spawn Special Zombie");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SpecialZombie(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (IsClientConnected(param1) && IsClientInGame(param1))
			{
				int flagszspawn = GetCommandFlags("z_spawn");	
				SetCommandFlags("z_spawn", flagszspawn & ~FCVAR_CHEAT);	
				FakeClientCommand(param1, "z_spawn %s", info);
				SetCommandFlags("z_spawn", flagszspawn|FCVAR_CHEAT);
				
				DisplaySpecialZombieMenu(param1);
			}
		}
	}
}
/* >>> end of Spawn Special Zombie Menu */

/* Minigun Menu */

public void AdminMenu_MachineGunSpawnMenu (TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "MiniGun Menu");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayMinigunMenu(param);
	}
}

void DisplayMinigunMenu(int client)
{
	char spawnminigun[40], spawnminigun2[40], removeminigun[40];

	Menu menu = CreateMenu(MenuHandler_MiniGun);

	Format(spawnminigun, sizeof(spawnminigun),"%T", "SpawnMiniGun", LANG_SERVER);
	AddMenuItem(menu, "spawnminigun", spawnminigun);
	Format(spawnminigun2, sizeof(spawnminigun2),"%T", "SpawnMiniGun2", LANG_SERVER);
	AddMenuItem(menu, "spawnminigun2", spawnminigun2);
	Format(removeminigun, sizeof(removeminigun),"%T", "RemoveMiniGun", LANG_SERVER);
	AddMenuItem(menu, "removeminigun", removeminigun);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_MiniGun(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			char selected_option[32];
			GetMenuItem(menu, param2, selected_option, sizeof(selected_option));
			
			if (StrEqual(selected_option, "spawnminigun", false))
			{
				SpawnMiniGun(param1, 1);
				DisplayMinigunMenu(param1);
			}
			else if (StrEqual(selected_option, "spawnminigun2", false))
			{
				SpawnMiniGun(param1, 2);
				DisplayMinigunMenu(param1);
			}
			else if (StrEqual(selected_option, "removeminigun", false))
			{
				RemoveMiniGun(param1);
				DisplayMinigunMenu(param1);
			}
		}
	}
}
/* >>> end of Minigun */

public Action Command_DisplayMenu(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	DisplayTopMenu(hAdminMenu, client, TopMenuPosition_Start);
	
	return Plugin_Handled;
}
/* >>> end of Menu */

/* Teleport Entity */
int SetTeleportEndPoint(int client)
{
	float vAngles[3];
	float vOrigin[3];
	float vBuffer[3];
	float vStart[3];
	float Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}
/* >>> end of Teleport Entity */