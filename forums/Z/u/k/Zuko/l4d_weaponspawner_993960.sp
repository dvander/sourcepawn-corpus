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
 * pistol, smg, pumpshotgun, first_aid_kit, molotov, autoshotgun,
 * hunting_rifle, rifle, pain_pills, pipe_bomb
 *
 *
 * #### 
 * Special Zombie List: 
 * boomer, hunter, smoker, tank, zombie, witch
 *
 * ####
 * Changelog:
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

#define VERSION "0.7"

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
	name = "[L4D] Weapon/Zombie Spawner",
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
	AutoExecConfig(true, "l4d_weaponspawner");
	
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
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
	PrecacheModel("models/props/terror/Ammo_Can.mdl", true);
	PrecacheModel("models/props/terror/ammo_stack.mdl", true);

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

	if (StrEqual(weapon, "weapon_rifle", false))
	{
		maxammo = GetConVarInt(AssaultMaxAmmo);
	}
	else if (StrEqual(weapon, "weapon_smg", false))
	{
		maxammo = GetConVarInt(SMGMaxAmmo);
	}		
	else if (StrEqual(weapon, "weapon_pumpshotgun", false))
	{
		maxammo = GetConVarInt(ShotgunMaxAmmo);
	}
	else if (StrEqual(weapon, "weapon_autoshotgun", false))
	{
		maxammo = GetConVarInt(AutoShotgunMaxAmmo);
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle", false))
	{
		maxammo = GetConVarInt(HRMaxAmmo);
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
				SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4); //Adds max ammo for weapon
				AcceptEntityInput(iWeapon, "RemoveHealth");
			}
			else
			{
				SetEntityModel(iWeapon, "models/props/terror/ammo_stack.mdl");
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
		new flagsgive = GetCommandFlags("give");
		SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
		if (IsClientInGame(target_list[i])) FakeClientCommand(target_list[i], "give %s", weapon);
		SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
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

	DispatchKeyValue(minigun, "model", "Minigun_1")
	SetEntityModel(minigun, "models/w_models/weapons/w_minigun.mdl")
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
	decl String:hunting_rifle[40], String:pistol[40], String:rifle[40], String:title[40];
	decl String:smg[40];

	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(hunting_rifle, sizeof(hunting_rifle),"%T", "HuntingRifle", LANG_SERVER)
	AddMenuItem(menu, "weapon_hunting_rifle", hunting_rifle)
	Format(pistol, sizeof(pistol),"%T", "Pistol", LANG_SERVER)
	AddMenuItem(menu, "weapon_pistol", pistol)
	Format(rifle, sizeof(rifle),"%T", "Rifle", LANG_SERVER)
	AddMenuItem(menu, "weapon_rifle", rifle)
	Format(smg, sizeof(smg),"%T", "SubmachineGun", LANG_SERVER)
	AddMenuItem(menu, "weapon_smg", smg)
	Format(title, sizeof(title),"%T", "BulletBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuSpawn[client] = "BulletBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildShellBasedMenu(client)
{
	decl String:autoshotgun[40], String:pumpshotgun[40], String:title[40]; 
	
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(autoshotgun, sizeof(autoshotgun),"%T", "AutoShotgun", LANG_SERVER)
	AddMenuItem(menu, "weapon_autoshotgun", autoshotgun)
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
	decl String:gascan[40], String:molotov[40], String:oxygentank[40], String:pipe_bomb[40], String:propanetank[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
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
	decl String:first_aid_kit[40], String:pain_pills[40], String:title[40]; 

	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
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
	decl String:ammo_spawn[40], String:title[40];
	
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	
	Format(ammo_spawn, sizeof(ammo_spawn),"%T", "AmmoStack", LANG_SERVER)
	AddMenuItem(menu, "weapon_ammo_spawn", ammo_spawn)
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
			
			if (StrEqual(weapon, "weapon_rifle", false))
			{
				maxammo = GetConVarInt(AssaultMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_smg", false))
			{
				maxammo = GetConVarInt(SMGMaxAmmo);
			}		
			else if (StrEqual(weapon, "weapon_pumpshotgun", false))
			{
				maxammo = GetConVarInt(ShotgunMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun", false))
			{
				maxammo = GetConVarInt(AutoShotgunMaxAmmo);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle", false))
			{
				maxammo = GetConVarInt(HRMaxAmmo);
			}

			new iWeapon = CreateEntityByName(weapon);

			if(IsValidEntity(iWeapon))
			{
				DispatchSpawn(iWeapon); //Spawn weapon (entity)
				if (!StrEqual(weapon, "weapon_ammo_spawn", false))
				{
					SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4); //Adds max ammo for weapon
				}
				else
				{
					SetEntityModel(iWeapon, "models/props/terror/ammo_stack.mdl");
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
					BuildBulletBasedGiveMenu(param1);
				case 1:
					BuildShellBasedGiveMenu(param1);
				case 2:
					BuildExplosiveBasedGiveMenu(param1);
				case 3:
					BuildHealthGiveMenu(param1);
				case 4:
					BuildMiscGiveMenu(param1);
			}
		}
	}
}

BuildBulletBasedGiveMenu(client)
{
	decl String:hunting_rifle[40], String:pistol[40], String:rifle[40];
	decl String:smg[40];
	decl String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(hunting_rifle, sizeof(hunting_rifle),"%T", "HuntingRifle", LANG_SERVER)
	AddMenuItem(menu, "hunting_rifle", hunting_rifle)
	Format(pistol, sizeof(pistol),"%T", "Pistol", LANG_SERVER)
	AddMenuItem(menu, "pistol", pistol)
	Format(rifle, sizeof(rifle),"%T", "Rifle", LANG_SERVER)
	AddMenuItem(menu, "rifle", rifle)
	Format(smg, sizeof(smg),"%T", "SubmachineGun", LANG_SERVER)
	AddMenuItem(menu, "smg", smg)
	Format(title, sizeof(title),"%T", "BulletBasedMenuTitle", LANG_SERVER)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	ChoosedMenuGive[client] = "BulletBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildShellBasedGiveMenu(client)
{
	decl String:autoshotgun[40], String:pumpshotgun[40], String:title[40]; 
	
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(autoshotgun, sizeof(autoshotgun),"%T", "AutoShotgun", LANG_SERVER)
	AddMenuItem(menu, "autoshotgun", autoshotgun)
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
	decl String:gascan[40], String:molotov[40], String:oxygentank[40];
	decl String:pipe_bomb[40], String:propanetank[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
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
	decl String:first_aid_kit[40], String:pain_pills[40], String:health[40], String:title[40];

	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(health, sizeof(health),"%T", "FullHealth", LANG_SERVER)
	AddMenuItem(menu, "health", health)	
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
	decl String:ammo[40];
	decl String:title[40];
	
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	Format(ammo, sizeof(ammo),"%T", "Ammo", LANG_SERVER)
	AddMenuItem(menu, "ammo", ammo)
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
	if (strcmp(ChoosedMenuGive[param1], "BulletBasedGiveMenu") == 0)
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
	AddMenuItem(menu, "hunter", "Hunter")
	AddMenuItem(menu, "smoker", "Smoker")
	AddMenuItem(menu, "tank", "Tank")
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