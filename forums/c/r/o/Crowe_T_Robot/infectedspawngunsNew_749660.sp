#include <sourcemod>

// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>
 
// Keep track of the top menu 
new Handle:hTopMenu = INVALID_HANDLE;

new TopMenuObject:menuSpawnInfected = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuSpawnWeapons = INVALID_TOPMENUOBJECT;
new TopMenuObject:menuForcePanic = INVALID_TOPMENUOBJECT;

new String:TAG[] = "[L4D] ";

public Plugin:myinfo = 
{
	name = "Left 4 Dead Infected Spawner",
	author = "Fexii",
	description = "Provides commands for spawning infected",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd("sm_spawn_infected",
		Command_Spawn_Infected,
		ADMFLAG_KICK,
		"Spawn an infected where you are aiming.");
	
	RegAdminCmd("sm_force_panic_event",
		Command_Force_Panic,
		ADMFLAG_KICK,
		"Forces a director panic event.");
	
	RegAdminCmd("sm_spawn_weapons",
		Command_Spawn_Weapons,
		ADMFLAG_KICK,
		"Spawn weapons.");

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
		Format(buffer, maxlength, "Left 4 Dead:", param);
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Left 4 Dead", param);
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
			Format(buffer, maxlength, "Spawn Infected", param);
		else if (object_id == menuSpawnWeapons)
			Format(buffer, maxlength, "Spawn Weapons", param);
		else if (object_id == menuForcePanic)
			Format(buffer, maxlength, "Force Panic Event", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == menuSpawnInfected)
			DisplayInfectedMenu(param);
		else if (object_id == menuForcePanic)
			ForcePanicEvent(param);
	}
}

public Action:Command_Spawn_Infected(client, args)
{

	decl String:name[10];

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
		GetCmdArg(1, name, sizeof(name));
		if(strcmp(name, "common") == 0 || strcmp(name, "hunter") == 0 || strcmp(name, "boomer") == 0 || strcmp(name, "smoker") == 0 || strcmp(name, "witch") == 0 || strcmp(name, "tank") == 0)
			SpawnInfected(client, name);
		else
			ShowActivity2(client, TAG, "Invalid zombie name: %s", name);
	}

	return Plugin_Handled;
}

public Action:Command_Spawn_Weapons(client, args)
{
	decl String:name[15];
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
		GetCmdArg(1, name, sizeof(name));
		if(strcmp(name, "pistol") == 0 || strcmp(name, "smg") == 0 || strcmp(name, "pumpshotgun") == 0 || strcmp(name, "rifle") == 0 || strcmp(name, "hunting_rifle") == 0 || strcmp(name, "autoshotgun") == 0 || strcmp(name, "ammo") == 0 || strcmp(name, "molotov") == 0 || strcmp(name, "pipe_bomb") == 0 || strcmp(name, "gascan") == 0 || strcmp(name, "propanetank") == 0 || strcmp(name, "oxygentank") == 0 || strcmp(name, "health") == 0 || strcmp(name, "first_aid_kit") == 0)
		{
			SpawnWeapons(client, name);
		}
		else
			ShowActivity2(client, TAG, "Invalid weapon name: %s", name);
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
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayWeaponsMenu(client)
{
	if (!IsClientInGame(client) || IsClientInKickQueue(client))
		return;
	
	new Handle:menu = CreateMenu(WeaponsSpawnHandler);
	SetMenuTitle(menu, "Spawn Weapons:");	AddMenuItem(menu, "health", "Health");
	AddMenuItem(menu, "pistol", "Pistol");
	AddMenuItem(menu, "smg", "Uzi");
	AddMenuItem(menu, "pumpshotgun", "Shotgun");
	AddMenuItem(menu, "rifle", "M16");
	AddMenuItem(menu, "hunting_rifle", "Hunting Rifle");
	AddMenuItem(menu, "autoshotgun", "Autoshotgun");
	AddMenuItem(menu, "ammo", "Ammo");
	AddMenuItem(menu, "molotov", "Molotov");
	AddMenuItem(menu, "pipe_bomb", "Pipebomb");
	AddMenuItem(menu, "gascan", "Gas Can");
	AddMenuItem(menu, "propanetank", "Propane Tank");
	AddMenuItem(menu, "oxygentank", "Oxygen Tank");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public InfectedSpawnHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SpawnInfected(param1, info);
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
		SpawnWeapons(param1, info);
		DisplayWeaponsMenu(param1);
    }
	else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

SpawnInfected(client, String:name[])
{
	new String:command[] = "z_spawn";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn %s", name);
	SetCommandFlags(command, flags);
	
	ShowActivity2(client, TAG, "Spawned a %s", name);
}

SpawnWeapons(client, String:name[])
{
	new String:command[] = "give";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", name);
	SetCommandFlags(command, flags);
	
	ShowActivity2(client, TAG, "Spawned %s", name);
}

ForcePanicEvent(client)
{
	new String:command[] = "director_force_panic_event";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, command);
	SetCommandFlags(command, flags);
	
	ShowActivity2(client, TAG, "Forced a panic event");
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
		ADMFLAG_KICK
	);
	
	menuForcePanic = AddToTopMenu(
		hTopMenu,
		"L4D_Force_Panic_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_force_panic_event",
		ADMFLAG_KICK
	);

	menuSpawnWeapons = AddToTopMenu(
		hTopMenu,
		"L4D_Weapons_Spawn_Item",
		TopMenuObject_Item,
		InfectedMenuHandler,
		objInfectedMenu,
		"sm_spawn_weapons",
		ADMFLAG_KICK
	);
}