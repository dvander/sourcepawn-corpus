/*
aSpawn.sp

Description:
	This L4D plugin provides an administrative menu and console commands that allow
    admins to force a panic event or spawn infected, weapons, or health while playing
    in co-op or versus mode.

	Use the "aSpawn Commands" administrative menu or the following console commands to
    initiate a panic event or spawn infected, weapons, or health:
		sm_force_panic_event
    	sm_spawn_infected [[common, hunter, boomer, smoker, witch, tank] [#]]
		sm_spawn_weapons [[pistol, smg, pumpshotgun, rifle, hunting_rifle, autoshotgun,
		    			 ammo, molotov, pipe_bomb, gascan, propanetank, oxygentank] [#]]
	    sm_spawn_health [[pain_pills, first_aid_kit, health] [#]]

	Examples:
		sm_force_panic_event
		sm_spawn_infected
		sm_spawn_infected witch
		sm_spawn_infected common 10
		sm_spawn_weapons
		sm_spawn_weapons rifle
		sm_spawn_weapons molotov 4
		sm_spawn_health
		sm_spawn_health pain_pills
		sm_spawn_health first_aid_kit 2


Versions:
2.0 (aSpawn.sp) [@l@n]
	Implemented neurotic's bug fix for the gun and health menus closing immediately.
    Implemented Crowe T. Robot's enhancement to allow the sm_spawn_infected,
        sm_spawn_weapons, and sm_spawn_health commands to take an optional argument
        and bypass the menu system (e.g., sm_spawn_infected witch).
    Allow optional 2nd argument to sm_spawn_infected, sm_spawn_weapons, and
        sm_spawn_health that specifies count of items (e.g., sm_spawn_infected common 10).
    Increased required execution access from ADMFLAG_KICK to ADMFLAG_CHEATS.
    Split Spawn Weapons menu into Spawn Weapons and Spawn Weapons (throwing).
    Added sm_spawn_version console command.
1.2 (infectedspawngunshealth.sp)[DARKness or ddrfreak21]
	Added menu to spawn health.
1.0 (infectedspawnguns.sp) [Keamos]
	Added menu to spawn guns.
1.0 (infectedspawn.sp) [Flexii]
	Initial version that spawned infected.
*/

#include <sourcemod>

#define PLUGIN_NAME "[L4D] aSpawn"
#define PLUGIN_VERSION "2.0.5"
#define DEBUGMODE 0

// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

// Keep track of the top menu
new Handle:hTopMenu = INVALID_HANDLE;

new TopMenuObject:menuSpawnInfected = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuSpawnWeapons = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuSpawnThrowingWeapons = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuSpawnHealth = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuForcePanic = INVALID_TOPMENUOBJECT;

new String:TAG[] = "[L4D] aSpawn: ";

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "@l@n (based on the work of Fexii, Keamos, DARKness, and others)",
	description = "Provides commands for spawning infected, weapons, and health",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	//Register the version cvar
	CreateConVar("sm_spawn_version",
		PLUGIN_VERSION,
		"Version of the [L4D] aSpawn plugin.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Register console commands
	RegAdminCmd("sm_spawn_infected",
		Command_Spawn_Infected,
		ADMFLAG_CHEATS,
		"Spawn an infected where you are aiming.");

	RegAdminCmd("sm_force_panic_event",
		Command_Force_Panic,
		ADMFLAG_CHEATS,
		"Forces a director panic event.");

	RegAdminCmd("sm_spawn_weapons",
		Command_Spawn_Weapons,
		ADMFLAG_CHEATS,
		"Spawn weapons.");

	RegAdminCmd("sm_spawn_health",
		Command_Spawn_Health,
		ADMFLAG_CHEATS,
		"Spawn Health.");

	// See if the menu plugin is already ready
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		// If so, manually fire the callback
		OnAdminMenuReady(topmenu);
	}
}

public AdminMenuHandler(Handle:topmenu,
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "aSpawn Commands:", param);
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "aSpawn Commands", param);
	}
}

public InfectedMenuHandler(Handle:topmenu,
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == menuSpawnInfected)
		{
			Format(buffer, maxlength, "Spawn Infected", param);
		}
		else if (object_id == menuSpawnWeapons)
		{
			Format(buffer, maxlength, "Spawn Weapons", param);
		}
		else if (object_id == menuSpawnThrowingWeapons)
		{
			Format(buffer, maxlength, "Spawn Weapons (throwing)", param);
		}
		else if (object_id == menuSpawnHealth)
		{
			Format(buffer, maxlength, "Spawn Health", param);
		}
		else if (object_id == menuForcePanic)
		{
			Format(buffer, maxlength, "Force Panic Event", param);
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == menuSpawnInfected)
		{
			DisplayInfectedMenu(param);
		}
		else if (object_id == menuSpawnWeapons)
		{
			DisplayWeaponsMenu(param);
		}
		else if (object_id == menuSpawnThrowingWeapons)
		{
			DisplayThrowingWeaponsMenu(param);
		}
		else if (object_id == menuSpawnHealth)
		{
	        DisplayHealthMenu(param);
	    }
		else if (object_id == menuForcePanic)
		{
			ForcePanicEvent(param);
		}
	}
}

public GetQty(args)
{
	new qty = 1;

	if (args == 2)
	{
		decl String:arg2[32];
		GetCmdArg(2, arg2, sizeof(arg2));

		qty = StringToInt(arg2);

		if (qty <= 0)
		{
			qty = 1
		}
	}

	return qty;
}

public Action:Command_Spawn_Infected(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");

		return Plugin_Handled;
	}

	if (args == 0)
	{
	    DisplayInfectedMenu(client);
	}
	else
	{
		decl String:name[10];
		GetCmdArg(1, name, sizeof(name));

		if (strcmp(name, "common") == 0 ||
			strcmp(name, "hunter") == 0 ||
			strcmp(name, "boomer") == 0 ||
			strcmp(name, "smoker") == 0 ||
			strcmp(name, "witch") == 0 ||
                        strcmp(name, "spitter") == 0 ||
                        strcmp(name, "jockey") == 0 ||
                        strcmp(name, "charger") == 0 ||
			strcmp(name, "tank") == 0)
		{
			SpawnInfected(client, name, GetQty(args));
		}
		else
		{
			ShowActivity2(client, TAG, "Invalid infected type: \"%s\"", name);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Spawn_Weapons(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if (args == 0)
	{
	    DisplayWeaponsMenu(client);
    }
	else
    {
		decl String:name[15];
		GetCmdArg(1, name, sizeof(name));

		if (strcmp(name, "pistol") == 0 ||
		        strcmp(name, "smg") == 0 ||
			strcmp(name, "pumpshotgun") == 0 ||
			strcmp(name, "rifle") == 0 ||
			strcmp(name, "hunting_rifle") == 0 ||
			strcmp(name, "autoshotgun") == 0 ||
			strcmp(name, "ammo") == 0 ||
			strcmp(name, "molotov") == 0 ||
			strcmp(name, "pipe_bomb") == 0 ||
			strcmp(name, "gascan") == 0 ||
			strcmp(name, "propanetank") == 0 ||
                        strcmp(name, "autoshotgun") == 0 ||
                        strcmp(name, "grenade_launcher") == 0 ||
                        strcmp(name, "pistol_magnum") == 0 ||
                        strcmp(name, "pistol") == 0 ||
                        strcmp(name, "rifle_ak47") == 0 ||
                        strcmp(name, "pumpshotgun") == 0 ||
                        strcmp(name, "rifle_desert") == 0 ||
                        strcmp(name, "shotgun_chrome") == 0 ||
                        strcmp(name, "shotgun_spas") == 0 ||
                        strcmp(name, "smg_silenced") == 0 ||
                        strcmp(name, "sniper_military") == 0 ||
                        strcmp(name, "rifle_sg552") == 0 ||
                        strcmp(name, "smg_mp5") == 0 ||
                        strcmp(name, "sniper_scout") == 0 ||
                        strcmp(name, "sniper_awp") == 0 ||
			strcmp(name, "oxygentank") == 0)
		{
			SpawnWeaponsOrHealth(client, name, GetQty(args));
		}
		else
		{
			ShowActivity2(client, TAG, "Invalid weapon type: \"%s\"", name);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Spawn_Health(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if (args == 0)
	{
	    DisplayHealthMenu(client);
    }
	else
    {
		decl String:name[15];
		GetCmdArg(1, name, sizeof(name));

		if (strcmp(name, "pain_pills") == 0 ||
			strcmp(name, "first_aid_kit") == 0 ||
                        strcmp(name, "defibrillator") == 0 ||
                        strcmp(name, "adrenaline") == 0 ||
			strcmp(name, "health") == 0)
		{
			SpawnWeaponsOrHealth(client, name, GetQty(args));
		}
		else
		{
			ShowActivity2(client, TAG, "Invalid health type: \"%s\"", name);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Force_Panic(client, args)
{
	ForcePanicEvent(client);

	return Plugin_Handled;
}

DisplayInfectedMenu(client)
{
	if (!IsClientInGame(client) || IsClientInKickQueue(client))
		return;

	new Handle:menu = CreateMenu(InfectedSpawnHandler);
	SetMenuTitle(menu, "Spawn Infected:");
	AddMenuItem(menu, "common", "Common");
	AddMenuItem(menu, "hunter", "Hunter");
	AddMenuItem(menu, "boomer", "Boomer");
	AddMenuItem(menu, "smoker", "Smoker");
	AddMenuItem(menu, "witch", "Witch");
	AddMenuItem(menu, "tank", "Tank");
        AddMenuItem(menu, "jockey", "Jockey");
	AddMenuItem(menu, "spitter", "Spitter");
	AddMenuItem(menu, "charger", "Charger");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayWeaponsMenu(client)
{
	if (!IsClientInGame(client) || IsClientInKickQueue(client))
	{
		return;
	}

	new Handle:menu = CreateMenu(WeaponsSpawnHandler);
	SetMenuTitle(menu, "Spawn Weapons:");
	AddMenuItem(menu, "ammo", "Ammo");
	AddMenuItem(menu, "autoshotgun", "Autoshotgun");
	AddMenuItem(menu, "grenade_launcher", "Grenade Launcher");
	AddMenuItem(menu, "hunting_rifle", "Hunting Rifle");
	AddMenuItem(menu, "pistol_magnum", "Magnum");
	AddMenuItem(menu, "pistol", "Pistol");
	AddMenuItem(menu, "pumpshotgun", "Pumpshotgun");
	AddMenuItem(menu, "rifle_ak47", "Ak47");
	AddMenuItem(menu, "rifle_desert", "Desert Rifle");
	AddMenuItem(menu, "rifle", "Rifle");
	AddMenuItem(menu, "shotgun_chrome", "Chrome Shotgun");
	AddMenuItem(menu, "shotgun_spas", "Combat Shotgun");
	AddMenuItem(menu, "smg_silenced", "Silenced SMG");
	AddMenuItem(menu, "smg", "SMG");
	AddMenuItem(menu, "sniper_military", "Military Sniper");
        AddMenuItem(menu, "rifle_sg552", "SG-552");
        AddMenuItem(menu, "sniper_scout", "Scout");
        AddMenuItem(menu, "sniper_awp", "Awp");
        AddMenuItem(menu, "smg_mp5", "MP5");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayThrowingWeaponsMenu(client)
{
	if (!IsClientInGame(client) || IsClientInKickQueue(client))
	{
		return;
	}

	new Handle:menu = CreateMenu(ThrowingWeaponsSpawnHandler);
	AddMenuItem(menu, "molotov", "Molotov");
	AddMenuItem(menu, "pipe_bomb", "Pipebomb");
	AddMenuItem(menu, "gascan", "Gas Can");
	AddMenuItem(menu, "propanetank", "Propane Tank");
	AddMenuItem(menu, "oxygentank", "Oxygen Tank");
        AddMenuItem(menu, "vomitjar", "Boomer Bile");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayHealthMenu(client)
{
	if (!IsClientInGame(client) || IsClientInKickQueue(client))
	{
		return;
	}

	new Handle:menu = CreateMenu(HealthSpawnHandler);
	SetMenuTitle(menu, "Spawn Health:");
	AddMenuItem(menu, "pain_pills", "Pills");
	AddMenuItem(menu, "first_aid_kit", "First Aid");
	AddMenuItem(menu, "health", "Instant Heal");
        AddMenuItem(menu, "defibrillator", "Defibrillator");
        AddMenuItem(menu, "adrenaline", "Adrenaline");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public InfectedSpawnHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		SpawnInfected(param1, info, 1);
		DisplayInfectedMenu(param1);
    }
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public WeaponsSpawnHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		SpawnWeaponsOrHealth(param1, info, 1);
		DisplayWeaponsMenu(param1);
    }
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public ThrowingWeaponsSpawnHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		SpawnWeaponsOrHealth(param1, info, 1);
		DisplayThrowingWeaponsMenu(param1);
    }
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public HealthSpawnHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));

		SpawnWeaponsOrHealth(param1, info, 1);
		DisplayHealthMenu(param1);
    }
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

SpawnInfected(client, String:name[], qty)
{
	for (new i = 0; i < qty; i++)
	{
		new String:command[] = "z_spawn";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
  		FakeClientCommand(client, "z_spawn %s", name);
		SetCommandFlags(command, flags);
	}

	if (qty > 1)
	{
		
	}
	else
	{
		
	}
}

SpawnWeaponsOrHealth(client, String:name[], qty)
{
	for (new i = 0; i < qty; i++)
	{
		new String:command[] = "give";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give %s", name);
		SetCommandFlags(command, flags);
	}

	if (qty > 1)
	{
	}
	else
	{
		
	}
}

ForcePanicEvent(client)
{
	new String:command[] = "director_force_panic_event";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, command);
	SetCommandFlags(command, flags);

}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Block us from being called twice
	if (topmenu == hTopMenu)
	{
		return;
	}

	hTopMenu = topmenu;

	new TopMenuObject:objInfectedMenu = FindTopMenuCategory(hTopMenu, "Left4Dead");
	if (objInfectedMenu == INVALID_TOPMENUOBJECT)
		objInfectedMenu = AddToTopMenu(
			hTopMenu,
			"Left4Dead",
			TopMenuObject_Category,
			AdminMenuHandler,
			INVALID_TOPMENUOBJECT
		);

	menuSpawnInfected = AddToTopMenu(
		hTopMenu,
		"L4D_Infected_Spawn_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_spawn_infected",
		ADMFLAG_CHEATS
	);

	menuForcePanic = AddToTopMenu(
		hTopMenu,
		"L4D_Force_Panic_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_force_panic_event",
		ADMFLAG_CHEATS
	);

	menuSpawnWeapons = AddToTopMenu(
		hTopMenu,
		"L4D_Weapons_Spawn_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_spawn_weapons",
		ADMFLAG_CHEATS
	);

	menuSpawnThrowingWeapons = AddToTopMenu(
		hTopMenu,
		"L4D_Throwing_Weapons_Spawn_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_spawn_weapons",
		ADMFLAG_CHEATS
	);

	menuSpawnHealth = AddToTopMenu(
		hTopMenu,
		"L4D_Health_Spawn_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_spawn_health",
		ADMFLAG_CHEATS
	);
}