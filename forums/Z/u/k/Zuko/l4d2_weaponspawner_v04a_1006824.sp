/*
 * Simple plugin which you can spawn any weapon where you are looking or give weapon to player.
 *
 * Zuko / hlds.pl @ Qnet / zuko.isports.pl /
 *
 */
 
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "0.4a"

/* TopMenu Handle */
new Handle:hAdminMenu = INVALID_HANDLE;

//new String:MapName[128];
new String:ChoosedWeapon[MAXPLAYERS+1][56]
new String:ChoosedMenuSpawn[MAXPLAYERS+1][56]
new String:ChoosedMenuGive[MAXPLAYERS+1][56]
new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[L4D2] Weapon Spawner",
	author = "Zuko",
	description = "Spawns weapons where your looking or give weapon to player.",
	version = VERSION,
	url = "http://zuko.isports.pl"
}

public OnPluginStart()
{
	CreateConVar("sm_weaponspawner_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_spawnweapon", Command_SpawnWeapon, ADMFLAG_SLAY, "Spawn weapon where you are looking.");
	RegAdminCmd("sm_sw", Command_SpawnWeapon, ADMFLAG_SLAY, "Spawn weapon where you are looking.");
	
	RegAdminCmd("sm_giveweapon", Command_GiveWeapon, ADMFLAG_SLAY, "Gives weapon to player.");
	RegAdminCmd("sm_gw", Command_GiveWeapon, ADMFLAG_SLAY, "Gives weapon to player.");
	
	RegAdminCmd("sm_zspawn", Command_SpawnZombie, ADMFLAG_SLAY, "Spawns special zombie where you are looking.");
			
	/*Menu Handler */
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
	
	/* Load translations */
	LoadTranslations("common.phrases");
}

/* Spawn Weapon */
public Action:Command_SpawnWeapon(client, args)
{
	decl String:weapon[56]
	
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_spawnweapon [weapon_name]");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, weapon, sizeof(weapon));
	}
	
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}

	new iWeapon = CreateEntityByName(weapon);
	
	if(IsValidEntity(iWeapon))
	{		
		DispatchSpawn(iWeapon);
		g_pos[2] -= 10.0;
		TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Handled;
}
/* >>> end of Spawn Weapon */

/* Give Weapon */
public Action:Command_GiveWeapon(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_giveweapon <#userid|name> [weapon_name]")
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
	decl String:zombie[56];
	
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");
		return Plugin_Handled;
	}	
	
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_zspawn [zombie_name]")
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, zombie, sizeof(zombie));
	}
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		new flags = GetCommandFlags("z_spawn");	
		SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);	
		FakeClientCommand(client, "z_spawn %s", zombie);
		SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
	}
	return Plugin_Handled;
}
/* >>> end of Spawn Zombie */

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
		AddToTopMenu(hAdminMenu, "sm_sw_menu", TopMenuObject_Item, AdminMenu_WeaponSpawner, menu_category, "sm_sw_menu", ADMFLAG_SLAY)
		AddToTopMenu(hAdminMenu, "sm_gw_menu", TopMenuObject_Item, AdminMenu_WeaponGive, menu_category, "sm_gw_menu", ADMFLAG_SLAY)
		AddToTopMenu(hAdminMenu, "sm_spawn_menu", TopMenuObject_Item, AdminMenu_ZombieSpawnMenu, menu_category, "sm_spawn_menu", ADMFLAG_SLAY)
	}
}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	switch( action ){
		case TopMenuAction_DisplayTitle:
			Format(buffer, maxlength, "What do you want?");
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "Weapon Spawner");
		}
	}

/* Weapon Spawn Menu */
public AdminMenu_WeaponSpawner(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn Weapon")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayWeaponMenu(param)
	}
}

DisplayWeaponMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Weapons)
	
	SetMenuExitBackButton(menu, true)
	AddMenuItem(menu, "g_BulletBasedMenu", "Bullet Based")
	AddMenuItem(menu, "g_ShellBasedMenu", "Shell Based")
	AddMenuItem(menu, "g_ExplosiveBasedMenu", "Explosive Based")
	AddMenuItem(menu, "g_HealthMenu", "Health Related")
	AddMenuItem(menu, "g_MiscMenu", "Misc")
	SetMenuTitle(menu, "Spawn Weapon")
	
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
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	AddMenuItem(menu, "weapon_hunting_rifle", "Hunting Rifle")
	AddMenuItem(menu, "weapon_pistol", "Pistol")
	AddMenuItem(menu, "weapon_pistol_magnum", "Desert Eagle (Magnum Pistol)")
	AddMenuItem(menu, "weapon_rifle", "Rifle")
	AddMenuItem(menu, "weapon_rifle_desert", "Desert Rifle")
	AddMenuItem(menu, "weapon_smg", "Submachine Gun")
	AddMenuItem(menu, "weapon_smg_silenced", "Silenced Submachine Gun")
	AddMenuItem(menu, "weapon_sniper_military", "Military Sniper")
	AddMenuItem(menu, "weapon_rifle_ak47", "Avtomat Kalashnikova (AK-47) [from CS:S]")
	AddMenuItem(menu, "weapon_rifle_sg552", "SIG SG 550 [from CS:S]")
	AddMenuItem(menu, "weapon_smg_mp5", "Submachine Gun MP5 [from CS:S]")
	AddMenuItem(menu, "weapon_sniper_awp", "Accuracy International Arctic Warfare [AWP from CS:S]")
	AddMenuItem(menu, "weapon_sniper_scout", "Scout Sniper [from CS:S]")
	SetMenuTitle(menu, "Bullet Based Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuSpawn[client] = "BulletBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildShellBasedMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	AddMenuItem(menu, "weapon_autoshotgun", "Auto Shotgun")
	AddMenuItem(menu, "weapon_shotgun_chrome", "Chrome Shotgun")
	AddMenuItem(menu, "weapon_shotgun_spas", "Spas Shotgun")
	AddMenuItem(menu, "weapon_pumpshotgun", "Pump Shotgun")
	SetMenuTitle(menu, "Shell Based Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuSpawn[client] = "ShellBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildExplosiveBasedMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	AddMenuItem(menu, "weapon_grenade_launcher", "Granade Luncher")
	AddMenuItem(menu, "weapon_fireworkcrate", "Fire Works Crate")
	AddMenuItem(menu, "weapon_gascan", "Gascan")
	AddMenuItem(menu, "weapon_molotov", "Molotov")
	AddMenuItem(menu, "weapon_oxygentank", "Oxygen Tank")
	AddMenuItem(menu, "weapon_pipe_bomb", "Pipe Bomb")
	AddMenuItem(menu, "weapon_propanetank", "Propane Tank")
	SetMenuTitle(menu, "Explosive Based Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuSpawn[client] = "ExplosiveBasedSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildHealthMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	AddMenuItem(menu, "weapon_adrenaline", "Adrenaline")
	AddMenuItem(menu, "weapon_defibrillator", "Defibrillator")
	AddMenuItem(menu, "weapon_first_aid_kit", "First Aid Kit")
	AddMenuItem(menu, "weapon_pain_pills", "Pain Pills")
	SetMenuTitle(menu, "Health Related:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuSpawn[client] = "HealthSpawnMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildMiscMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapon);
	AddMenuItem(menu, "weapon_chainsaw", "Chain Saw")
	AddMenuItem(menu, "weapon_ammo_spawn", "Ammo Stack")
	AddMenuItem(menu, "weapon_upgradepack_explosive", "Explosive Ammo Pack")
	AddMenuItem(menu, "weapon_upgradepack_incendiary", "Incendiary Ammo Pack")
	AddMenuItem(menu, "weapon_vomitjar", "Vomit Jar")
	AddMenuItem(menu, "weapon_gnome", "Gnome")
	SetMenuTitle(menu, "Misc Weapons/Addons:");
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
			new String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));

			if(!SetTeleportEndPoint(param1))
			{
				PrintToChat(param1, "[SM] Could not find spawn point.");
			}
			
			new iWeapon = CreateEntityByName(info);
		
			if(IsValidEntity(iWeapon))
			{		
				DispatchSpawn(iWeapon);
				g_pos[2] -= 10.0;
				TeleportEntity(iWeapon, g_pos, NULL_VECTOR, NULL_VECTOR);
			}
			
			ChoosedSpawnMenuHistory(param1);
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
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapons)
	AddMenuItem(menu, "g_MeleeGiveMenu", "Melee Weapons")
	AddMenuItem(menu, "g_BulletBasedGiveMenu", "Bullet Based")
	AddMenuItem(menu, "g_ShellBasedGiveMenu", "Shell Based")
	AddMenuItem(menu, "g_ExplosiveBasedGiveMenu", "Explosive Based")
	AddMenuItem(menu, "g_HealthGiveMenu", "Health Related")
	AddMenuItem(menu, "g_MiscGiveMenu", "Misc")
	SetMenuTitle(menu, "Give Weapon")
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
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	
	AddMenuItem(menu, "baseball_bat", "Baseball Bat")
	AddMenuItem(menu, "cricket_bat", "Cricket Bat")
	AddMenuItem(menu, "crowbar", "Crowbar")
	AddMenuItem(menu, "electric_guitar", "Electric Guitar")
	AddMenuItem(menu, "fireaxe", "Fire Axe")
	AddMenuItem(menu, "frying_pan", "Frying Pan")
	AddMenuItem(menu, "katana", "Katana")
	AddMenuItem(menu, "machete", "Machete")
	AddMenuItem(menu, "tonfa", "Tonfa")
	SetMenuTitle(menu, "Melee Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "MeleeGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildBulletBasedGiveMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	AddMenuItem(menu, "hunting_rifle", "Hunting Rifle")
	AddMenuItem(menu, "pistol", "Pistol")
	AddMenuItem(menu, "pistol_magnum", "Desert Eagle (Magnum Pistol)")
	AddMenuItem(menu, "rifle", "Rifle")
	AddMenuItem(menu, "rifle_desert", "Desert Rifle")
	AddMenuItem(menu, "smg", "Submachine Gun")
	AddMenuItem(menu, "smg_silenced", "Silenced Submachine Gun")
	AddMenuItem(menu, "sniper_military", "Military Sniper")
	AddMenuItem(menu, "rifle_ak47", "Avtomat Kalashnikova (AK-47) [from CS:S]")
	AddMenuItem(menu, "rifle_sg552", "SIG SG 550 [from CS:S]")
	AddMenuItem(menu, "smg_mp5", "Submachine Gun MP5 [from CS:S]")
	AddMenuItem(menu, "sniper_awp", "Accuracy International Arctic Warfare [AWP from CS:S]")
	AddMenuItem(menu, "sniper_scout", "Scout Sniper [from CS:S]")
	SetMenuTitle(menu, "Bullet Based Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "BulletBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildShellBasedGiveMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	AddMenuItem(menu, "autoshotgun", "Auto Shotgun")
	AddMenuItem(menu, "shotgun_chrome", "Chrome Shotgun")
	AddMenuItem(menu, "shotgun_spas", "Spas Shotgun")
	AddMenuItem(menu, "pumpshotgun", "Pump Shotgun")
	SetMenuTitle(menu, "Shell Based Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "ShellBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildExplosiveBasedGiveMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	AddMenuItem(menu, "grenade_launcher", "Granade Luncher")
	AddMenuItem(menu, "fireworkcrate", "Fire Works Crate")
	AddMenuItem(menu, "gascan", "Gascan")
	AddMenuItem(menu, "molotov", "Molotov")
	AddMenuItem(menu, "oxygentank", "Oxygen Tank")
	AddMenuItem(menu, "pipe_bomb", "Pipe Bomb")
	AddMenuItem(menu, "propanetank", "Propane Tank")
	SetMenuTitle(menu, "Explosive Based Weapons:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "ExplosiveBasedGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildHealthGiveMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	AddMenuItem(menu, "health", "Full Health")
	AddMenuItem(menu, "adrenaline", "Adrenaline")
	AddMenuItem(menu, "defibrillator", "Defibrillator")
	AddMenuItem(menu, "first_aid_kit", "First Aid Kit")
	AddMenuItem(menu, "pain_pills", "Pain Pills")
	SetMenuTitle(menu, "Health Related:");
	SetMenuExitBackButton(menu, true)
	
	ChoosedMenuGive[client] = "HealthGiveMenu";
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

BuildMiscGiveMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_GiveWeapon);
	AddMenuItem(menu, "chainsaw", "Chain Saw")
	AddMenuItem(menu, "ammo", "Refill Ammo")
	AddMenuItem(menu, "laser_sight", "Laser Sight")
	AddMenuItem(menu, "explosive_ammo", "Explosive Ammo")
	AddMenuItem(menu, "incendiary_ammo", "Incendiary Ammo")
	AddMenuItem(menu, "upgradepack_explosive", "ExplosiveFrag Ammo Pack")
	AddMenuItem(menu, "upgradepack_incendiary", "Incendiary Ammo Pack")
	AddMenuItem(menu, "vomitjar", "Vomit Jar")
	AddMenuItem(menu, "gnome", "Gnome")
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
	AddMenuItem(menu, "hunter", "Hunter")
	AddMenuItem(menu, "smoker", "Smoker")
	AddMenuItem(menu, "tank", "Tank")
	AddMenuItem(menu, "spitter", "Spitter")
	AddMenuItem(menu, "jockey", "Jockey")
	AddMenuItem(menu, "charger", "Charger")
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