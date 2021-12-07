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
 *	-	sm_spawnmachinegun or sm_smg - Spawn Machine Gun
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
 * rifle_desert, rifle_sg552, shotgun_chrome, shotgun_spas, smg, 
 * smg_mp5, smg_silenced, sniper_awp, sniper_military, sniper_scout, 
 * vomitjar, ammo_spawn, upgradepack_explosive, upgradepack_incendiary, 
 * cola_bottles
 *
 * ####
 * Melee Weapons List:
 * baseball_bat, cricket_bat, crowbar, electric_guitar, fireaxe, frying_pan, 
 * katana, machete, tonfa, knife
 *
 * #### 
 * Special Zombie List: 
 * boomer, hunter, smoker, tank, spitter, jockey, charger, zombie, witch
 *
 * ####
 * Changelog:
 * v0.8
 *	o Added new weapons from DLC
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
 * Zuko / #hlds.pl @ Qnet #sourcemod @ GameSurge / zuko.isports.pl / hlds.pl /
 *
 * ####
 * Credits:
 * pheadxdll for [TF2] Pumpkins code
 * antihacker for [L4D] Spawn Minigun code
 */
 
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "0.8"

/* TopMenu Handle */
new Handle:hAdminMenu = INVALID_HANDLE;

/* ConVar Handle */
new Handle:AssaultMaxAmmo = INVALID_HANDLE;
new Handle:SMGMaxAmmo = INVALID_HANDLE;
new Handle:ShotgunMaxAmmo = INVALID_HANDLE;
new Handle:AutoShotgunMaxAmmo = INVALID_HANDLE;
new Handle:HRMaxAmmo = INVALID_HANDLE;
new Handle:SniperRifleMaxAmmo = INVALID_HANDLE;
new Handle:GrenadeLauncherMaxAmmo = INVALID_HANDLE;
new Handle:AllowAllMeleeWeapons = INVALID_HANDLE;
new Handle:DebugInformations = INVALID_HANDLE;

new String:ChoosedWeapon[MAXPLAYERS+1][56];
new String:ChoosedMenuSpawn[MAXPLAYERS+1][56];
new String:ChoosedMenuGive[MAXPLAYERS+1][56];
new String:MapName[128];
new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[L4D2] Weapon/Zombie Spawner",
	author = "Zuko",
	description = "Spawns weapons/zombies where your looking or give weapons to players.",
	version = VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	/* ConVars */
	CreateConVar("sm_weaponspawner_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

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

	RegAdminCmd("sm_guncontroldebug", Cmd_ReadGunData, ADMFLAG_ROOT, "Reads your current weapons data");
	RegAdminCmd("sm_getpropclassname", Cmd_ReadPropData, ADMFLAG_ROOT, "Reads prop classname");

	/* Max Ammo ConVars */
	AssaultMaxAmmo = CreateConVar("sm_spawnweapon_assaultammo", "360", "How much Ammo for AK74, M4A1, SG552 and Desert Rifle.", FCVAR_PLUGIN, true, 0.0, true, 360.0);
	SMGMaxAmmo = CreateConVar("sm_spawnweapon_smgammo", "650", "How much Ammo for SMG, Silenced SMG and MP5", FCVAR_PLUGIN, true, 0.0, true, 650.0);
	ShotgunMaxAmmo = CreateConVar("sm_spawnweapon_shotgunammo", "56", "How much Ammo for Shotgun and Chrome Shotgun.", FCVAR_PLUGIN, true, 0.0, true, 56.0);
	AutoShotgunMaxAmmo = CreateConVar("sm_spawnweapon_autoshotgunammo", "90", "How much Ammo for Autoshotgun and SPAS.", FCVAR_PLUGIN, true, 0.0, true, 90.0);
	HRMaxAmmo = CreateConVar("sm_spawnweapon_huntingrifleammo", "150", "How much Ammo for the Hunting Rifle.", FCVAR_PLUGIN, true, 0.0, true, 150.0);
	SniperRifleMaxAmmo = CreateConVar("sm_spawnweapon_sniperrifleammo", "180", "How much Ammo for the Military Sniper Rifle, AWP and Scout.", FCVAR_PLUGIN, true, 0.0, true, 180.0);
	GrenadeLauncherMaxAmmo = CreateConVar("sm_spawnweapon_grenadelauncherammo", "30", "How much Ammo for the Grenade Launcher.", FCVAR_PLUGIN, true, 0.0, true, 30.0);

	AllowAllMeleeWeapons = CreateConVar("sm_spawnweapon_allowallmeleeweapons", "0", "Allow or Disallow all melee weapons on all campaigns.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	DebugInformations = CreateConVar("sm_spawnweapon_debug", "0", "Enable or Disable Debug Informations.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	/* Config File */
	AutoExecConfig(true, "l4d2_weaponspawner");
	
	/*Menu Handler */
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}

	/* Load translations */
	LoadTranslations("common.phrases");
	LoadTranslations("weaponspawner.phrases");
}

public OnMapStart()
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

	GetCurrentMap(MapName, sizeof(MapName));
}

/* Spawn Weapon */
public Action:Command_SpawnWeapon(client, args)
{
	new amount
	
	decl String:weapon[40], String:arg1[40], String:arg2[5];
	decl maxammo;
	
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
		amount = 1
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

	if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false) || StrEqual(weapon, "weapon_rifle_sg552", false))
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
	
	new i=0
	while (++i <= amount)
	{
		new iWeapon = CreateEntityByName(weapon);

		if(IsValidEntity(iWeapon))
		{		
			DispatchSpawn(iWeapon); //Spawn weapon (entity)
			if (!StrEqual(weapon, "weapon_ammo_spawn", false))
			{
				//SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo, 4); //Adds max ammo for weapon
				//SetEntProp(iWeapon, Prop_Send, "m_iClip1", 250, 1);
				//AcceptEntityInput(iWeapon, "RemoveHealth");
			}
			g_pos[2] -= 10.0-(i*2);
			TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "You spawned: %s", weapon)
			}
		}
	}
	return Plugin_Handled;
}
/* >>> end of Spawn Weapon */

/* Give Weapon */
public Action:Command_GiveWeapon(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "%t", "GiveWeaponUsage", LANG_SERVER)
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:weapon[65];
	GetCmdArg(2, weapon, sizeof(weapon));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

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

	for (new i = 0; i < target_count; i++)
	{
		if ((strcmp(weapon, "laser_sight") == 0) || (strcmp(weapon, "explosive_ammo") == 0) || (strcmp(weapon, "incendiary_ammo") == 0))
		{
			new flagsupgrade_add = GetCommandFlags("upgrade_add");
			SetCommandFlags("upgrade_add", flagsupgrade_add & ~FCVAR_CHEAT);
			if (IsClientInGame(target_list[i])) FakeClientCommand(target_list[i], "upgrade_add %s", weapon);
			SetCommandFlags("upgrade_add", flagsupgrade_add|FCVAR_CHEAT);
		}
		else
		{
			new flagsgive = GetCommandFlags("give");
			SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
			if (IsClientInGame(target_list[i])) FakeClientCommand(target_list[i], "give %s", weapon);
			SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
		}
	}
	return Plugin_Handled;
}
/* >>> end of Give Weapon */

/* Spawn Zombie */
public Action:Command_SpawnZombie(client, args)
{
	new amount
	decl String:zombie[56], String:arg2[5];

	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER)
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
		amount = 1
	}
	else
	{
		ReplyToCommand(client, "%t", "SpawnZombieUsage", LANG_SERVER)
		return Plugin_Handled;
	}

	new i=0
	while (++i <= amount)
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			new flags = GetCommandFlags("z_spawn");
			SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "z_spawn %s", zombie);
			SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
		}
	}
	return Plugin_Handled;
}
/* >>> end of Spawn Zombie */

/* Minigun */
public Action:Command_SpawnMinigun(client, args)
{
	if( !client )
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;	
	}

	SpawnMiniGun(client);
	return Plugin_Handled;
}

public SpawnMiniGun(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];

	new minigun = CreateEntityByName("prop_minigun");

	if (minigun == -1)
	{
		ReplyToCommand(client, "[SM] %t", "MinigunFailed", LANG_SERVER);
	}

	DispatchKeyValue(minigun, "model", "Minigun_1");
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

public Action:Command_RemoveMinigun(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;	
	}

	RemoveMiniGun(client);
	return Plugin_Handled;
}

public RemoveMiniGun(client)
{
	decl String:Classname[128];
	new minigun = GetClientAimTarget(client, false);

	if ((minigun == -1) || (!IsValidEntity (minigun)))
	{
		ReplyToCommand (client, "[SM] %t","RemoveMinigunError_01");
	}

	GetEdictClassname(minigun, Classname, sizeof(Classname));
	if(!StrEqual(Classname, "prop_minigun"))
	{
		ReplyToCommand (client, "[SM] %t", "RemoveMinigunError_02");
	}

	RemoveEdict(minigun);
}
/* >>> end of Minigun */

/* Menu */
public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}

	hAdminMenu = topmenu

	new TopMenuObject:menu_category = AddToTopMenu(hAdminMenu, "sm_ws_topmenu", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT);

	if (menu_category != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu, "sm_sw_menu", TopMenuObject_Item, AdminMenu_WeaponSpawner, menu_category, "sm_sw_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "sm_gw_menu", TopMenuObject_Item, AdminMenu_WeaponGive, menu_category, "sm_gw_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "sm_spawn_menu", TopMenuObject_Item, AdminMenu_ZombieSpawnMenu, menu_category, "sm_spawn_menu", ADMFLAG_SLAY);
		AddToTopMenu(hAdminMenu, "sm_smg_menu", TopMenuObject_Item, AdminMenu_MachineGunSpawnMenu, menu_category, "sm_smg_menu", ADMFLAG_SLAY);
	}
}

public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "What do you want?");
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "%T", "WeaponSpawner", LANG_SERVER)
	}
}

/* Weapon Spawn Menu */
public AdminMenu_WeaponSpawner(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "SpawnWeapon", LANG_SERVER)
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayWeaponMenu(param)
	}
}

DisplayWeaponMenu(client)
{
	decl String:bulletbased[40], String:shellbased[40], String:explosivebased[40], String:healthrelated[40], String:misc[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_Weapons)

	SetMenuExitBackButton(menu, true)
	Format(bulletbased, sizeof(bulletbased),"%T", "BulletBased", LANG_SERVER)
	AddMenuItem(menu, "g_BulletBasedMenu", bulletbased)
	Format(shellbased, sizeof(shellbased),"%T", "ShellBased", LANG_SERVER)
	AddMenuItem(menu, "g_ShellBasedMenu", shellbased)
	Format(explosivebased, sizeof(explosivebased),"%T", "ExplosiveBased", LANG_SERVER)
	AddMenuItem(menu, "g_ExplosiveBasedMenu", explosivebased)
	Format(healthrelated, sizeof(healthrelated),"%T", "HealthRelated", LANG_SERVER)
	AddMenuItem(menu, "g_HealthMenu", healthrelated)
	Format(misc, sizeof(misc),"%T", "Misc", LANG_SERVER)
	AddMenuItem(menu, "g_MiscMenu", misc)
	Format(title, sizeof(title),"%T", "DisplayWeaponMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Weapons(Handle:menu, MenuAction:action, param1, param2)
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
					BuildBulletBasedMenu(param1);
				case 1:
					BuildShellBasedMenu(param1);
				case 2:
					BuildExplosiveBasedMenu(param1);
				case 3:
					BuildHealthMenu(param1);
				case 4:
					BuildMiscMenu(param1);
			}
		}
	}
}

BuildBulletBasedMenu(client)
{
	decl String:hunting_rifle[40], String:pistol[40], String:pistol_magnum[40], String:rifle[40], String:title[40];
	decl String:rifle_desert[40], String:smg[40], String:smg_silenced[40], String:sniper_military[40], String:rifle_ak47[40];
	decl String:rifle_sg552[40], String:smg_mp5[40], String:sniper_awp[40], String:sniper_scout[40], String:rifle_m60[40];

	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	Format(rifle_m60, sizeof(rifle_m60),"%T", "RifleM60", LANG_SERVER)
	AddMenuItem(menu, "weapon_rifle_m60", rifle_m60)
	Format(hunting_rifle, sizeof(hunting_rifle),"%T", "HuntingRifle", LANG_SERVER)
	AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle)
	Format(pistol, sizeof(pistol),"%T", "Pistol", LANG_SERVER)
	AddMenuItem(menu, "weapon_pistol", pistol)
	Format(pistol_magnum, sizeof(pistol_magnum),"%T", "DesertEagle", LANG_SERVER)
	AddMenuItem(menu, "weapon_pistol_magnum", pistol_magnum)
	Format(rifle, sizeof(rifle),"%T", "Rifle", LANG_SERVER)
	AddMenuItem(menu, "weapon_rifle", rifle)
	Format(rifle_desert, sizeof(rifle_desert),"%T", "DesertRifle", LANG_SERVER)
	AddMenuItem(menu, "weapon_rifle_desert", rifle_desert)
	Format(smg, sizeof(smg),"%T", "SubmachineGun", LANG_SERVER)
	AddMenuItem(menu, "weapon_smg", smg)
	Format(smg_silenced, sizeof(smg_silenced),"%T", "SilencedSubmachineGun", LANG_SERVER)
	AddMenuItem(menu, "weapon_smg_silenced", smg_silenced)
	Format(sniper_military, sizeof(sniper_military),"%T", "MilitarySniper", LANG_SERVER)
	AddMenuItem(menu, "weapon_sniper_military", sniper_military)
	Format(rifle_ak47, sizeof(rifle_ak47),"%T", "AvtomatKalashnikova", LANG_SERVER)
	AddMenuItem(menu, "weapon_rifle_ak47", rifle_ak47)
	Format(rifle_sg552, sizeof(rifle_sg552),"%T", "SIGSG550", LANG_SERVER)
	AddMenuItem(menu, "weapon_rifle_sg552", rifle_sg552)
	Format(smg_mp5, sizeof(smg_mp5),"%T", "SubmachineGunMP5", LANG_SERVER)
	AddMenuItem(menu, "weapon_smg_mp5", smg_mp5)
	Format(sniper_awp, sizeof(sniper_awp),"%T", "AWP", LANG_SERVER)
	AddMenuItem(menu, "weapon_sniper_awp", sniper_awp)
	Format(sniper_scout, sizeof(sniper_scout),"%T", "ScoutSniper", LANG_SERVER)
	AddMenuItem(menu, "weapon_sniper_scout", sniper_scout)
	Format(title, sizeof(title),"%T", "BulletBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuSpawn[client] = "BulletBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildShellBasedMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40]; 
	
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(autoshotgun, sizeof(autoshotgun),"%T", "AutoShotgun", LANG_SERVER)
	AddMenuItem(menu, "weapon_autoshotgun", autoshotgun)
	Format(shotgun_chrome, sizeof(shotgun_chrome),"%T", "ChromeShotgun", LANG_SERVER)
	AddMenuItem(menu, "weapon_shotgun_chrome", shotgun_chrome)
	Format(shotgun_spas, sizeof(shotgun_spas),"%T", "SpasShotgun", LANG_SERVER)
	AddMenuItem(menu, "weapon_shotgun_spas", shotgun_spas)
	Format(pumpshotgun, sizeof(pumpshotgun),"%T", "PumpShotgun", LANG_SERVER)
	AddMenuItem(menu, "weapon_pumpshotgun", pumpshotgun)
	Format(title, sizeof(title),"%T", "ShellBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuSpawn[client] = "ShellBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildExplosiveBasedMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:molotov[40], String:oxygentank[40], String:pipe_bomb[40], String:propanetank[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(grenade_launcher, sizeof(grenade_launcher),"%T", "GrenadeLauncher", LANG_SERVER)
	AddMenuItem(menu, "weapon_grenade_launcher", grenade_launcher)
	Format(fireworkcrate, sizeof(fireworkcrate),"%T", "FireworksCrate", LANG_SERVER)
	AddMenuItem(menu, "weapon_fireworkcrate", fireworkcrate)
	Format(gascan, sizeof(gascan),"%T", "Gascan", LANG_SERVER)
	AddMenuItem(menu, "weapon_gascan", gascan)
	Format(molotov, sizeof(molotov),"%T", "Molotov", LANG_SERVER)
	AddMenuItem(menu, "weapon_molotov", molotov)
	Format(oxygentank, sizeof(oxygentank),"%T", "OxygenTank", LANG_SERVER)
	AddMenuItem(menu, "weapon_oxygentank", oxygentank)
	Format(pipe_bomb, sizeof(pipe_bomb),"%T", "PipeBomb", LANG_SERVER)
	AddMenuItem(menu, "weapon_pipe_bomb", pipe_bomb)
	Format(propanetank, sizeof(propanetank),"%T", "PropaneTank", LANG_SERVER)
	AddMenuItem(menu, "weapon_propanetank", propanetank)
	Format(title, sizeof(title),"%T", "ExplosiveBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuSpawn[client] = "ExplosiveBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildHealthMenu(client)
{
	decl String:adrenaline[40], String:defibrillator[40], String:first_aid_kit[40], String:pain_pills[40], String:title[40]; 

	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(adrenaline, sizeof(adrenaline),"%T", "Adrenaline", LANG_SERVER)
	AddMenuItem(menu, "weapon_adrenaline", adrenaline)
	Format(defibrillator, sizeof(defibrillator),"%T", "Defibrillator", LANG_SERVER)
	AddMenuItem(menu, "weapon_defibrillator", defibrillator)
	Format(first_aid_kit, sizeof(first_aid_kit),"%T", "FirstAidKit", LANG_SERVER)
	AddMenuItem(menu, "weapon_first_aid_kit", first_aid_kit)
	Format(pain_pills, sizeof(pain_pills),"%T", "PainPills", LANG_SERVER)
	AddMenuItem(menu, "weapon_pain_pills", "Pain Pills")
	Format(title, sizeof(title),"%T", "HealthMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuSpawn[client] = "HealthSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildMiscMenu(client)
{
	decl String:chainsaw[40], String:ammo_spawn[40], String:upgradepack_explosive[40], String:upgradepack_incendiary[40], String:vomitjar[40], String:gnome[40], String:cola[40], String:title[40];
	
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(chainsaw, sizeof(chainsaw),"%T", "ChainSaw", LANG_SERVER)
	AddMenuItem(menu, "weapon_chainsaw", chainsaw)
	Format(ammo_spawn, sizeof(ammo_spawn),"%T", "AmmoStack", LANG_SERVER)
	AddMenuItem(menu, "weapon_ammo_spawn", ammo_spawn)
	Format(upgradepack_explosive, sizeof(upgradepack_explosive),"%T", "ExplosiveAmmoPack", LANG_SERVER)
	AddMenuItem(menu, "weapon_upgradepack_explosive", upgradepack_explosive)
	Format(upgradepack_incendiary, sizeof(upgradepack_incendiary),"%T", "IncendiaryAmmoPack", LANG_SERVER)
	AddMenuItem(menu, "weapon_upgradepack_incendiary", upgradepack_incendiary)
	Format(vomitjar, sizeof(vomitjar),"%T", "VomitJar", LANG_SERVER)
	AddMenuItem(menu, "weapon_vomitjar", vomitjar)
	Format(gnome, sizeof(gnome),"%T", "Gnome", LANG_SERVER)
	AddMenuItem(menu, "weapon_gnome", gnome)
	Format(cola, sizeof(cola),"%T", "Cola", LANG_SERVER)
	AddMenuItem(menu, "weapon_cola_bottles", cola)	
	Format(title, sizeof(title),"%T", "MiscMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuSpawn[client] = "MiscSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_SpawnWeapon(Handle:menu, MenuAction:action, param1, param2)
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
				DisplayWeaponMenu(param1)
			}
		}
		case MenuAction_Select:
		{
			new String:weapon[32];
			decl maxammo;

			GetMenuItem(menu, param2, weapon, sizeof(weapon));

			if(!SetTeleportEndPoint(param1))
			{
				PrintToChat(param1, "[SM] %T", "SpawnError", LANG_SERVER);
			}
			
			if (StrEqual(weapon, "weapon_rifle", false) || StrEqual(weapon, "weapon_rifle_ak47", false) || StrEqual(weapon, "weapon_rifle_desert", false))
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
			else if (StrEqual(weapon, "weapon_sniper_military", false))
			{
				maxammo = GetConVarInt(SniperRifleMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher", false))
			{
				maxammo = GetConVarInt(GrenadeLauncherMaxAmmo);
			}

			new iWeapon = CreateEntityByName(weapon);

			if(IsValidEntity(iWeapon))
			{
				DispatchSpawn(iWeapon); //Spawn weapon (entity)
				if (!StrEqual(weapon, "weapon_ammo_spawn", false))
				{
					SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4); //Adds max ammo for weapon
					SetEntProp(iWeapon, Prop_Send, "m_iClip1", 250, 1);
				}
				g_pos[2] -= 10.0;
				TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR); //Teleport spawned weapon
				if (GetConVarInt(DebugInformations))
				{
					PrintToChat(param1, "You spawned: %s", weapon)
				}
			}
			ChoosedSpawnMenuHistory(param1); //Redraw menu after item selection
		}
	}
}

stock ChoosedSpawnMenuHistory(param1)
{
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
public AdminMenu_WeaponGive(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
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

DisplayWeaponGiveMenu(client)
{
	decl String:MeleeGiveMenu[40], String:BulletBasedGiveMenu[40], String:ShellBasedGiveMenu[40];
	decl String:ExplosiveBasedGiveMenu[40], String:HealthGiveMenu[40], String:MiscGiveMenu[40], String:title[40]; 
	
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapons)
	
	Format(MeleeGiveMenu, sizeof(MeleeGiveMenu),"%T", "MeleeWeapons", LANG_SERVER)
	AddMenuItem(menu, "g_MeleeGiveMenu", MeleeGiveMenu)
	Format(BulletBasedGiveMenu, sizeof(BulletBasedGiveMenu),"%T", "BulletBased", LANG_SERVER)
	AddMenuItem(menu, "g_BulletBasedGiveMenu", BulletBasedGiveMenu)
	Format(ShellBasedGiveMenu, sizeof(ShellBasedGiveMenu),"%T", "ShellBased", LANG_SERVER)
	AddMenuItem(menu, "g_ShellBasedGiveMenu", ShellBasedGiveMenu)
	Format(ExplosiveBasedGiveMenu, sizeof(ExplosiveBasedGiveMenu),"%T", "ExplosiveBased", LANG_SERVER)
	AddMenuItem(menu, "g_ExplosiveBasedGiveMenu", ExplosiveBasedGiveMenu)
	Format(HealthGiveMenu, sizeof(HealthGiveMenu),"%T", "HealthRelated", LANG_SERVER)
	AddMenuItem(menu, "g_HealthGiveMenu", HealthGiveMenu)
	Format(MiscGiveMenu, sizeof(MiscGiveMenu),"%T", "Misc", LANG_SERVER)
	AddMenuItem(menu, "g_MiscGiveMenu", MiscGiveMenu)
	Format(title, sizeof(title),"%T", "WeaponGiveMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_GiveWeapons(Handle:menu, MenuAction:action, param1, param2)
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

BuildMeleeGiveMenu(client)
{
	decl String:baseball_bat[40], String:cricket_bat[40], String:crowbar[40], String:electric_guitar[40], String:fireaxe[40];
	decl String:frying_pan[40], String:katana[40], String:machete[40], String:tonfa[40], String:knife[40], String:title[40], String:golfclub[40];

	if (GetConVarInt(DebugInformations))
	{
		PrintToChat(client, "Map Name: %s", MapName)
	}

	if (GetConVarInt(AllowAllMeleeWeapons) == 0)
	{
		if ((StrEqual(MapName, "c1m1_hotel", false)) || (StrEqual(MapName, "c1m2_streets", false)) || (StrEqual(MapName, "c1m3_mall", false)) || (StrEqual(MapName, "c1m4_atrium", false)))
		{
			new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER)
			AddMenuItem(menu, "cricket_bat", "Cricket Bat")
			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER)
			AddMenuItem(menu, "crowbar", crowbar)
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER)
			AddMenuItem(menu, "fireaxe", fireaxe)
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER)
			AddMenuItem(menu, "katana", katana)
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
			AddMenuItem(menu, "baseball_bat", baseball_bat)
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
			AddMenuItem(menu, "knife", knife)
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
			SetMenuTitle(menu, title)
			SetMenuExitBackButton(menu, true)

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER)
				
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Dead Center")
			}
		}
		else if ((StrEqual(MapName, "c2m1_highway", false)) || (StrEqual(MapName, "c2m2_fairgrounds", false)) || (StrEqual(MapName, "c2m3_coaster", false)) || (StrEqual(MapName, "c2m4_barns", false)) || (StrEqual(MapName, "c2m5_concert", false)))
		{
			new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER)
			AddMenuItem(menu, "crowbar", crowbar)
			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER)
			AddMenuItem(menu, "electric_guitar", electric_guitar)
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER)
			AddMenuItem(menu, "fireaxe", fireaxe)
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER)
			AddMenuItem(menu, "katana", katana)
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
			AddMenuItem(menu, "baseball_bat", baseball_bat)
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
			AddMenuItem(menu, "knife", knife)
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
			SetMenuTitle(menu, title)
			SetMenuExitBackButton(menu, true)

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER)
				
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Dark Carnival")
			}
		}
		else if ((StrEqual(MapName, "c3m1_plankcountry", false)) || (StrEqual(MapName, "c3m2_swamp", false)) || (StrEqual(MapName, "c3m3_shantytown", false)) || (StrEqual(MapName, "c3m4_plantation", false)))
		{
			new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER)
			AddMenuItem(menu, "cricket_bat", "Cricket Bat")
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER)
			AddMenuItem(menu, "fireaxe", fireaxe)
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER)
			AddMenuItem(menu, "frying_pan", frying_pan)
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER)
			AddMenuItem(menu, "machete", machete)
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
			AddMenuItem(menu, "baseball_bat", baseball_bat)
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
			AddMenuItem(menu, "knife", knife)
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
			SetMenuTitle(menu, title)
			SetMenuExitBackButton(menu, true)

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER)
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Swamp Fever")
			}
		}
		else if ((StrEqual(MapName, "c4m1_milltown_a", false)) || (StrEqual(MapName, "c4m2_sugarmill_a", false)) || (StrEqual(MapName, "c4m3_sugarmill_b", false)) || (StrEqual(MapName, "c4m4_milltown_b", false)) || (StrEqual(MapName, "c4m5_milltown_escape", false)))
		{
			new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER)
			AddMenuItem(menu, "crowbar", crowbar)
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER)
			AddMenuItem(menu, "fireaxe", fireaxe)
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER)
			AddMenuItem(menu, "frying_pan", frying_pan)
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER)
			AddMenuItem(menu, "katana", katana)
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
			AddMenuItem(menu, "baseball_bat", baseball_bat)
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
			AddMenuItem(menu, "knife", knife)
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
			SetMenuTitle(menu, title)
			SetMenuExitBackButton(menu, true)

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER)
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Hard Rain")
			}
		}
		else if ((StrEqual(MapName, "c5m1_waterfront", false)) || (StrEqual(MapName, "c5m1_waterfront_sndscape", false)) || (StrEqual(MapName, "c5m2_park", false)) || (StrEqual(MapName, "c5m3_cemetery", false)) || (StrEqual(MapName, "c5m4_quarter", false)) || (StrEqual(MapName, "c5m5_bridge", false)))
		{
			new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER)
			AddMenuItem(menu, "electric_guitar", electric_guitar)
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER)
			AddMenuItem(menu, "frying_pan", frying_pan)
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER)
			AddMenuItem(menu, "machete", machete)
			Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER)
			AddMenuItem(menu, "tonfa", tonfa)
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
			AddMenuItem(menu, "baseball_bat", baseball_bat)
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
			AddMenuItem(menu, "knife", knife)
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
			SetMenuTitle(menu, title)
			SetMenuExitBackButton(menu, true)

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER)
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: The Parish")
			}
		}
		else
		{
			new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

			Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER)
			AddMenuItem(menu, "cricket_bat", "Cricket Bat")
			Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER)
			AddMenuItem(menu, "crowbar", crowbar)
			Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER)
			AddMenuItem(menu, "electric_guitar", electric_guitar)
			Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER)
			AddMenuItem(menu, "fireaxe", fireaxe)
			Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER)
			AddMenuItem(menu, "frying_pan", frying_pan)
			Format(golfclub, sizeof(golfclub),"%T", "GolfClub", LANG_SERVER)
			AddMenuItem(menu, "golfclub", golfclub)
			Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER)
			AddMenuItem(menu, "katana", katana)
			Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER)
			AddMenuItem(menu, "machete", machete)
			Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER)
			AddMenuItem(menu, "tonfa", tonfa)
			Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
			AddMenuItem(menu, "baseball_bat", baseball_bat)
			Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
			AddMenuItem(menu, "knife", knife)
			Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
			SetMenuTitle(menu, title)
			SetMenuExitBackButton(menu, true)

			ChoosedMenuGive[client] = "MeleeGiveMenu";
			DisplayMenu(menu, client, MENU_TIME_FOREVER)
			
			if (GetConVarInt(DebugInformations))
			{
				PrintToChat(client, "Campaign: Custom")
			}
		}
	}
	else
	{
		new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);

		Format(cricket_bat, sizeof(cricket_bat),"%T", "CricketBat", LANG_SERVER)
		AddMenuItem(menu, "cricket_bat", "Cricket Bat")
		Format(crowbar, sizeof(crowbar),"%T", "Crowbar", LANG_SERVER)
		AddMenuItem(menu, "crowbar", crowbar)
		Format(electric_guitar, sizeof(electric_guitar),"%T", "ElectricGuitar", LANG_SERVER)
		AddMenuItem(menu, "electric_guitar", electric_guitar)
		Format(fireaxe, sizeof(fireaxe),"%T", "FireAxe", LANG_SERVER)
		AddMenuItem(menu, "fireaxe", fireaxe)
		Format(frying_pan, sizeof(frying_pan),"%T", "FryingPan", LANG_SERVER)
		AddMenuItem(menu, "frying_pan", frying_pan)
		Format(golfclub, sizeof(golfclub),"%T", "GolfClub", LANG_SERVER)
		AddMenuItem(menu, "golfclub", golfclub)
		Format(katana, sizeof(katana),"%T", "Katana", LANG_SERVER)
		AddMenuItem(menu, "katana", katana)
		Format(machete, sizeof(machete),"%T", "Machete", LANG_SERVER)
		AddMenuItem(menu, "machete", machete)
		Format(tonfa, sizeof(tonfa),"%T", "Tonfa", LANG_SERVER)
		AddMenuItem(menu, "tonfa", tonfa)
		Format(baseball_bat, sizeof(baseball_bat),"%T", "BaseballBat", LANG_SERVER)
		AddMenuItem(menu, "baseball_bat", baseball_bat)
		Format(knife, sizeof(knife),"%T", "Knife", LANG_SERVER)
		AddMenuItem(menu, "knife", knife)
		Format(title, sizeof(title),"%T", "MeleeMenuTitle", LANG_SERVER)
		SetMenuTitle(menu, title)
		SetMenuExitBackButton(menu, true)

		ChoosedMenuGive[client] = "MeleeGiveMenu";
		DisplayMenu(menu, client, MENU_TIME_FOREVER)
	}
}

BuildBulletBasedGiveMenu(client)
{
	decl String:hunting_rifle[40], String:pistol[40], String:pistol_magnum[40], String:rifle[40], String:rifle_desert[40];
	decl String:smg[40], String:smg_silenced[40], String:sniper_military[40], String:rifle_ak47[40], String:rifle_sg552[40];
	decl String:smg_mp5[40], String:sniper_awp[40], String:sniper_scout[40], String:title[40], String:rifle_m60[40];

	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(rifle_m60, sizeof(rifle_m60),"%T", "RifleM60", LANG_SERVER)
	AddMenuItem(menu, "rifle_m60", rifle_m60)
	Format(hunting_rifle, sizeof(hunting_rifle),"%T", "HuntingRifle", LANG_SERVER)
	AddMenuItem(menu, "hunting_rifle", hunting_rifle)
	Format(pistol, sizeof(pistol),"%T", "Pistol", LANG_SERVER)
	AddMenuItem(menu, "pistol", pistol)
	Format(pistol_magnum, sizeof(pistol_magnum),"%T", "DesertEagle", LANG_SERVER)
	AddMenuItem(menu, "pistol_magnum", pistol_magnum)
	Format(rifle, sizeof(rifle),"%T", "Rifle", LANG_SERVER)
	AddMenuItem(menu, "rifle", rifle)
	Format(rifle_desert, sizeof(rifle_desert),"%T", "DesertRifle", LANG_SERVER)
	AddMenuItem(menu, "rifle_desert", rifle_desert)
	Format(smg, sizeof(smg),"%T", "SubmachineGun", LANG_SERVER)
	AddMenuItem(menu, "smg", smg)
	Format(smg_silenced, sizeof(smg_silenced),"%T", "SilencedSubmachineGun", LANG_SERVER)
	AddMenuItem(menu, "smg_silenced", smg_silenced)
	Format(sniper_military, sizeof(sniper_military),"%T", "MilitarySniper", LANG_SERVER)
	AddMenuItem(menu, "sniper_military", sniper_military)
	Format(rifle_ak47, sizeof(rifle_ak47),"%T", "AvtomatKalashnikova", LANG_SERVER)
	AddMenuItem(menu, "rifle_ak47", rifle_ak47)
	Format(rifle_sg552, sizeof(rifle_sg552),"%T", "SIGSG550", LANG_SERVER)
	AddMenuItem(menu, "rifle_sg552", rifle_sg552)
	Format(smg_mp5, sizeof(smg_mp5),"%T", "SubmachineGunMP5", LANG_SERVER)
	AddMenuItem(menu, "smg_mp5", smg_mp5)
	Format(sniper_awp, sizeof(sniper_awp),"%T", "AWP", LANG_SERVER)
	AddMenuItem(menu, "sniper_awp", sniper_awp)
	Format(sniper_scout, sizeof(sniper_scout),"%T", "ScoutSniper", LANG_SERVER)
	AddMenuItem(menu, "sniper_scout", sniper_scout)
	Format(title, sizeof(title),"%T", "BulletBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuGive[client] = "BulletBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildShellBasedGiveMenu(client)
{
	decl String:autoshotgun[40], String:shotgun_chrome[40], String:shotgun_spas[40], String:pumpshotgun[40], String:title[40]; 
	
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(autoshotgun, sizeof(autoshotgun),"%T", "AutoShotgun", LANG_SERVER)
	AddMenuItem(menu, "autoshotgun", autoshotgun)
	Format(shotgun_chrome, sizeof(shotgun_chrome),"%T", "ChromeShotgun", LANG_SERVER)
	AddMenuItem(menu, "shotgun_chrome", shotgun_chrome)
	Format(shotgun_spas, sizeof(shotgun_spas),"%T", "SpasShotgun", LANG_SERVER)
	AddMenuItem(menu, "shotgun_spas", shotgun_spas)
	Format(pumpshotgun, sizeof(pumpshotgun),"%T", "PumpShotgun", LANG_SERVER)
	AddMenuItem(menu, "pumpshotgun", pumpshotgun)
	Format(title, sizeof(title),"%T", "ShellBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "ShellBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildExplosiveBasedGiveMenu(client)
{
	decl String:grenade_launcher[40], String:fireworkcrate[40], String:gascan[40], String:molotov[40], String:oxygentank[40];
	decl String:pipe_bomb[40], String:propanetank[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(grenade_launcher, sizeof(grenade_launcher),"%T", "GrenadeLauncher", LANG_SERVER)
	AddMenuItem(menu, "grenade_launcher", grenade_launcher)
	Format(fireworkcrate, sizeof(fireworkcrate),"%T", "FireworksCrate", LANG_SERVER)
	AddMenuItem(menu, "fireworkcrate", fireworkcrate)
	Format(gascan, sizeof(gascan),"%T", "Gascan", LANG_SERVER)
	AddMenuItem(menu, "gascan", gascan)
	Format(molotov, sizeof(molotov),"%T", "Molotov", LANG_SERVER)
	AddMenuItem(menu, "molotov", molotov)
	Format(oxygentank, sizeof(oxygentank),"%T", "OxygenTank", LANG_SERVER)
	AddMenuItem(menu, "oxygentank", oxygentank)
	Format(pipe_bomb, sizeof(pipe_bomb),"%T", "PipeBomb", LANG_SERVER)
	AddMenuItem(menu, "pipe_bomb", pipe_bomb)
	Format(propanetank, sizeof(propanetank),"%T", "PropaneTank", LANG_SERVER)
	AddMenuItem(menu, "propanetank", propanetank)
	Format(title, sizeof(title),"%T", "ExplosiveBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "ExplosiveBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildHealthGiveMenu(client)
{
	decl String:adrenaline[40], String:defibrillator[40], String:first_aid_kit[40], String:pain_pills[40], String:health[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(health, sizeof(health),"%T", "FullHealth", LANG_SERVER)
	AddMenuItem(menu, "health", health)	
	Format(adrenaline, sizeof(adrenaline),"%T", "Adrenaline", LANG_SERVER)
	AddMenuItem(menu, "adrenaline", adrenaline)
	Format(defibrillator, sizeof(defibrillator),"%T", "Defibrillator", LANG_SERVER)
	AddMenuItem(menu, "defibrillator", defibrillator)
	Format(first_aid_kit, sizeof(first_aid_kit),"%T", "FirstAidKit", LANG_SERVER)
	AddMenuItem(menu, "first_aid_kit", first_aid_kit)
	Format(pain_pills, sizeof(pain_pills),"%T", "PainPills", LANG_SERVER)
	AddMenuItem(menu, "pain_pills", "Pain Pills")
	Format(title, sizeof(title),"%T", "HealthMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "HealthGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildMiscGiveMenu(client)
{
	decl String:chainsaw[40], String:ammo[40], String:upgradepack_explosive[40], String:upgradepack_incendiary[40];
	decl String:vomitjar[40], String:gnome[40], String:cola[40], String:title[40];
	decl String:laser_sight[40], String:explosive_ammo[40], String:incendiary_ammo[40];
	
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(chainsaw, sizeof(chainsaw),"%T", "ChainSaw", LANG_SERVER)
	AddMenuItem(menu, "chainsaw", chainsaw)
	Format(ammo, sizeof(ammo),"%T", "Ammo", LANG_SERVER)
	AddMenuItem(menu, "ammo", ammo)
	Format(laser_sight, sizeof(laser_sight),"%T", "LaserSight", LANG_SERVER)
	AddMenuItem(menu, "laser_sight", laser_sight)
	Format(explosive_ammo, sizeof(explosive_ammo),"%T", "ExplosiveAmmo", LANG_SERVER)
	AddMenuItem(menu, "explosive_ammo", explosive_ammo)
	Format(incendiary_ammo, sizeof(incendiary_ammo),"%T", "IncendiaryAmmo", LANG_SERVER)
	AddMenuItem(menu, "incendiary_ammo", incendiary_ammo)
	Format(upgradepack_explosive, sizeof(upgradepack_explosive),"%T", "ExplosiveAmmoPack", LANG_SERVER)
	AddMenuItem(menu, "upgradepack_explosive", upgradepack_explosive)
	Format(upgradepack_incendiary, sizeof(upgradepack_incendiary),"%T", "IncendiaryAmmoPack", LANG_SERVER)
	AddMenuItem(menu, "upgradepack_incendiary", upgradepack_incendiary)
	Format(vomitjar, sizeof(vomitjar),"%T", "VomitJar", LANG_SERVER)
	AddMenuItem(menu, "vomitjar", vomitjar)
	Format(gnome, sizeof(gnome),"%T", "Gnome", LANG_SERVER)
	AddMenuItem(menu, "gnome", gnome)
	Format(cola, sizeof(cola),"%T", "Cola", LANG_SERVER)
	AddMenuItem(menu, "weapon_cola_bottles", cola)	
	Format(title, sizeof(title),"%T", "MiscMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuGive[client] = "MiscGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_GiveWeapon(Handle:menu, MenuAction:action, param1, param2)
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
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			/* Save choosed weapon */
			ChoosedWeapon[param1] = info;
			DisplaySelectPlayerMenu(param1);
		}
	}
}

DisplaySelectPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PlayerSelect)

	SetMenuTitle(menu, "Select Player")
	SetMenuExitBackButton(menu, true)

	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS)

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_PlayerSelect(Handle:menu, MenuAction:action, param1, param2)
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
			new String:info[56];
			GetMenuItem(menu, param2, info, sizeof(info));

			new target = GetClientOfUserId(StringToInt(info));

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
				new flagsupgrade_add = GetCommandFlags("upgrade_add");
				SetCommandFlags("upgrade_add", flagsupgrade_add & ~FCVAR_CHEAT);
				if (IsClientInGame(target)) FakeClientCommand(target, "upgrade_add %s", ChoosedWeapon[param1]);
				SetCommandFlags("upgrade_add", flagsupgrade_add|FCVAR_CHEAT);
				ChoosedGiveMenuHistory(param1);
			}
			else
			{
				new flagsgive = GetCommandFlags("give");
				SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
				if (IsClientInGame(target)) FakeClientCommand(target, "give %s", ChoosedWeapon[param1]);
				SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
				ChoosedGiveMenuHistory(param1);
			}
		}
	}
}

stock ChoosedGiveMenuHistory(param1)
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
public AdminMenu_ZombieSpawnMenu(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Special Zombie")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplaySpecialZombieMenu(param)
	}
}

DisplaySpecialZombieMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpecialZombie)
	
	SetMenuExitBackButton(menu, true)
	AddMenuItem(menu, "boomer", "Boomer")
	AddMenuItem(menu, "charger", "Charger")
	AddMenuItem(menu, "hunter", "Hunter")
	AddMenuItem(menu, "smoker", "Smoker")
	AddMenuItem(menu, "spitter", "Spitter")
	AddMenuItem(menu, "tank", "Tank")
	AddMenuItem(menu, "jockey", "Jockey")
	AddMenuItem(menu, "witch", "Witch")
	AddMenuItem(menu, "zombie", "One Zombie ;-)")
	SetMenuTitle(menu, "Spawn Special Zombie")
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_SpecialZombie(Handle:menu, MenuAction:action, param1, param2)
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
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (IsClientConnected(param1) && IsClientInGame(param1))
			{
				new flagszspawn = GetCommandFlags("z_spawn");	
				SetCommandFlags("z_spawn", flagszspawn & ~FCVAR_CHEAT);	
				FakeClientCommand(param1, "z_spawn %s", info);
				SetCommandFlags("z_spawn", flagszspawn|FCVAR_CHEAT);
				
				DisplaySpecialZombieMenu(param1)
			}
		}
	}
}
/* >>> end of Spawn Special Zombie Menu */

/* Minigun Menu */

public AdminMenu_MachineGunSpawnMenu (Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "MiniGun Menu")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayMinigunMenu(param)
	}
}

DisplayMinigunMenu(client)
{
	decl String:spawnminigun[40], String:removeminigun[40];

	new Handle:menu = CreateMenu(MenuHandler_MiniGun)

	Format(spawnminigun, sizeof(spawnminigun),"%T", "SpawnMiniGun", LANG_SERVER)
	AddMenuItem(menu, "spawnminigun", spawnminigun)
	Format(removeminigun, sizeof(removeminigun),"%T", "RemoveMiniGun", LANG_SERVER)
	AddMenuItem(menu, "removeminigun", removeminigun)

	SetMenuExitBackButton(menu, true)
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_MiniGun(Handle:menu, MenuAction:action, param1, param2)
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
			new String:selected_option[32]
			GetMenuItem(menu, param2, selected_option, sizeof(selected_option));
			
			if (StrEqual(selected_option, "spawnminigun", false))
			{
				SpawnMiniGun(param1)
				DisplayMinigunMenu(param1)
			}
			else if (StrEqual(selected_option, "removeminigun", false))
			{
				RemoveMiniGun(param1)
				DisplayMinigunMenu(param1)
			}
		}
	}
}
/* >>> end of Minigun */

public Action:Command_DisplayMenu(client, args)
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
SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

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

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}
/* >>> end of Teleport Entity */


public Action:Cmd_ReadGunData(client, args) //Code from L4D2 Gun Control by AtomicStryker
{
	if (!client || !IsClientInGame(client))
	{
		ReplyToCommand(client, "Can only use this command ingame");
		return Plugin_Handled;
	}
	
	new targetgun = GetPlayerWeaponSlot(client, 0); //get the players primary weapon
	if (!IsValidEdict(targetgun)) return Plugin_Handled; //check for validity
	
	decl String:name[256];
	GetEdictClassname(targetgun, name, sizeof(name));
	PrintToChat(client, "Gun Class: %s", name);
	
	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo"); //get the iAmmo Offset
	PrintToChat(client, "m_iAmmo Offset: %i", iAmmoOffset);
	
	for (new offset = 0; offset <= 128 ; offset += 4)
	{
		PrintToChat(client, "Offset %i Value: %i", offset, GetEntData(client, (iAmmoOffset + offset)));
	}
	
	PrintToChat(client, "m_iClip1 Value in gun: %i", GetEntProp(targetgun, Prop_Data, "m_iClip1", 1));
	PrintToChat(client, "m_iClip2 Value in gun: %i", GetEntProp(targetgun, Prop_Data, "m_iClip2", 1));
	PrintToChat(client, "m_iExtraPrimaryAmmo Value in gun: %i", GetEntProp(targetgun, Prop_Data, "m_iExtraPrimaryAmmo", 4));
	return Plugin_Handled;
}

public Action:Cmd_ReadPropData(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "%t", "Command is in-game only", LANG_SERVER);
		return Plugin_Handled;	
	}

	ReadInfo(client);
	return Plugin_Handled;
}

public ReadInfo(client)
{
	decl String:Classname[256];
	decl String:NetClassname[256];
	decl String:ModelName[256];
	new prop = GetClientAimTarget(client, false);

	if ((prop == -1) || (!IsValidEntity (prop)))
	{
		ReplyToCommand(client, "Error!");
		return Plugin_Handled;
	}

	GetEdictClassname(prop, Classname, sizeof(Classname));
	PrintToChat(client, "EntClass: %s", Classname);
	GetEntityNetClass(prop, NetClassname, sizeof(NetClassname));
	PrintToChat(client, "NetEntClass: %s", NetClassname);
	GetEntPropString(prop, Prop_Data, "m_ModelName", ModelName, 128)
	PrintToChat(client, "m_ModelName: %s", ModelName);
	//weapon_pain_pills_spawn
	//weapon_molotov_spawn
	//weapon_pipe_bomb_spawn
	//weapon_adrenaline_spawn
	//weapon_first_aid_kit_spawn
	
	//m_itemCount
	//m_spawnflags
	return Plugin_Handled;
}