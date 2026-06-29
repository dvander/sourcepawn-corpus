// Atomicstrykers modified version to include L4D2 infected, weaponry, and uncommon hordes :D

#pragma semicolon 1
#pragma tabsize 0

// Define constants
#define PLUGIN_VERSION   "1.5.1"
#define PLUGIN_NAME       "All4Dead2"
#define PLUGIN_TAG  	    "[A4D2] "
#define MAX_PLAYERS				32
#define MENU_DISPLAY_TIME 15		

// Include necessary files
#include <sourcemod>
#include <sdktools>
// Make the admin menu optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

// Create ConVar Handles
new Handle:notify_players = INVALID_HANDLE;
new Handle:automatic_placement  = INVALID_HANDLE;
new Handle:zombies_increment  = INVALID_HANDLE;
new Handle:always_force_bosses = INVALID_HANDLE;

// Menu handlers
new Handle:top_menu;
new Handle:admin_menu;
new TopMenuObject:spawn_infected_menu;
new TopMenuObject:spawn_weapons_menu;
new TopMenuObject:spawn_items_menu;
new TopMenuObject:director_menu;
new TopMenuObject:versus_menu;
new TopMenuObject:config_menu;

// Other stuff

new bool:currently_spawning = false;
new command_client = 0;

// Uncommon Infected Specific Globals
new RemainingZombiesToSpawn;
new Float:spawnpoint[3];
new DefaultMegaMob;
new DefaultMaxHorde;


// Metadata for the mod
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Enables admins to have control over the AI Director",
	version = PLUGIN_VERSION,
	url = "http://code.james.richardson.name"
};

// Create and set all the necessary for All4Dead and register all our commands
public OnPluginStart() {

	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	
	CreateConVar("a4d_version", PLUGIN_VERSION, "The version of All4Dead plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	automatic_placement = CreateConVar("a4d_automatic_placement", "1", "Whether or not we ask the director to place things we spawn.", FCVAR_PLUGIN);	
	notify_players = CreateConVar("a4d_notify_players", "1", "Whether or not we announce changes in game.", FCVAR_PLUGIN);	
	zombies_increment = CreateConVar("a4d_zombies_to_add", "10", "The amount of zombies to add when an admin requests more zombies.", FCVAR_PLUGIN, true, 10.0, true, 100.0);
	always_force_bosses = CreateConVar("a4d_always_force_bosses", "0", "Whether or not bosses will be forced to spawn all the time.", FCVAR_PLUGIN);
	// Register all spawning commands
	RegAdminCmd("a4d_spawn_infected", CommandSpawnInfected, ADMFLAG_CHEATS);
  RegAdminCmd("a4d_spawn_item", CommandSpawnItem, ADMFLAG_CHEATS);
  RegAdminCmd("a4d_spawn_weapon", CommandSpawnWeapon, ADMFLAG_CHEATS);
  // Director commands
  RegAdminCmd("a4d_force_panic", CommandForcePanic, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_panic_forever", CommandPanicForever, ADMFLAG_CHEATS);	
	RegAdminCmd("a4d_force_tank", CommandForceTank, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_force_witch", CommandForceWitch, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_continuous_bosses", CommandSpawnBossesContinuously, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_add_zombies", CommandAddZombies, ADMFLAG_CHEATS);	
	// Versus settings
	RegAdminCmd("a4d_enable_all_bot_teams", CommandEnableAllBotTeams, ADMFLAG_CHEATS);
	// Config settings
	RegAdminCmd("a4d_enable_notifications", CommandEnableNotifications, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_reset_to_defaults", CommandResetToDefaults, ADMFLAG_CHEATS);
	// Hook events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tank_spawn", Event_BossSpawn, EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", Event_BossSpawn, EventHookMode_PostNoCopy);
	// Execute configuation file if it exists
	AutoExecConfig(true);
  // If the Admin menu has been loaded start adding stuff to it
	if (LibraryExists("adminmenu") && ((top_menu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(top_menu);
		
	RegAdminCmd("sm_givelaser", CommandGiveLaser, ADMFLAG_CHEATS);
}

public OnMapStart()
{
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	DefaultMegaMob = GetConVarInt(FindConVar("z_mega_mob_size"));
	DefaultMaxHorde = GetConVarInt(FindConVar("z_mob_spawn_max_size"));	
}

public OnPluginEnd() {
	ResetToDefaults(0);
	LogAction(0, -1, "%s %s has been unloaded.", PLUGIN_NAME, PLUGIN_VERSION);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	/* If something spawns and we have just requested something to spawn - assume it is the same thing and make sure it has max health */
	if (GetClientTeam(client) == 3 && currently_spawning) {
		StripAndExecuteClientCommand(client, "give", "health");
		LogAction(0, -1, "[NOTICE] Given full health to client %L that (hopefully) was spawned by A4D.", client);
		// We have added health to the thing we have spawned so turn ourselves off
		currently_spawning = false;	
	}
}

// If a boss has spawned toggle off force unless requested otherwise
public Action:Event_BossSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarBool(always_force_bosses) == false)
		if (StrEqual(name, "tank_spawn") && GetConVarBool(FindConVar("director_force_tank")))
			ForceTank(0, false);
		else if (StrEqual(name, "witch_spawn") && GetConVarBool(FindConVar("director_force_witch")))
			ForceWitch(0, false);
}

// Register the menu system
public OnAdminMenuReady(Handle:menu) {
  // Stop this method being called twice	
  if (menu == admin_menu)
    return;
	admin_menu = menu;
 
	// Add a category to the SourceMod menu called "Director Commands"
	AddToTopMenu(admin_menu, "All4Dead Commands", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	// Get a handle for the catagory we just added so we can add items to it
	new TopMenuObject:a4d_menu = FindTopMenuCategory(admin_menu, "All4Dead Commands");
	// Don't attempt to add items to the category if for some reason the catagory doesn't exist
	if (a4d_menu == INVALID_TOPMENUOBJECT) 
    return; 	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically.
	// Assign the menus to global values so we can easily check what a menu is when it is chosen.
	director_menu = AddToTopMenu(admin_menu, "a4d_director_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_director_menu", ADMFLAG_CHEATS);	
	config_menu = AddToTopMenu(admin_menu, "a4d_config_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_config_menu", ADMFLAG_CHEATS);
	versus_menu = AddToTopMenu(admin_menu, "a4d_versus_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_versus_menu", ADMFLAG_CHEATS);
	spawn_infected_menu = AddToTopMenu(admin_menu, "a4d_spawn_infected_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_infected_menu", ADMFLAG_CHEATS);	
	spawn_weapons_menu = AddToTopMenu(admin_menu, "a4d_spawn_weapons_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_weapons_menu", ADMFLAG_CHEATS);
	spawn_items_menu = AddToTopMenu(admin_menu, "a4d_spawn_items_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_items_menu", ADMFLAG_CHEATS);
}

/* This handles the top level "All4Dead" category and how it is displayed on the core admin menu */
public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "All4Dead Commands:");
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "All4Dead Commands");
}

// This deals with what happens someone opens the "All4Dead" category from the menu.
public Menu_TopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
/* When an item is displayed to a player tell the menu to Format the item */
  if (action == TopMenuAction_DisplayOption) {
    if (object_id == director_menu)
      Format(buffer, maxlength, "Director Commands");
    else if (object_id == spawn_infected_menu)
    	Format(buffer, maxlength, "Spawn Infected");
    else if (object_id == spawn_weapons_menu)
    	Format(buffer, maxlength, "Spawn Weapons");
    else if (object_id == spawn_items_menu)
    	Format(buffer, maxlength, "Spawn Items");
    else if (object_id == config_menu)
    	Format(buffer, maxlength, "Configuration Options");
    else if (object_id == versus_menu)
    	Format(buffer, maxlength, "Versus Settings");
  } else if (action == TopMenuAction_SelectOption) {
    if (object_id == director_menu)
	DirectorMenu(client, false);
    else if (object_id == spawn_infected_menu)
    	SpawnInfectedMenu(client, false);
    else if (object_id == spawn_weapons_menu)
    	SpawnWeaponsMenu(client, false);
    else if (object_id == spawn_items_menu)
    	SpawnItemsMenu(client, false);
    else if (object_id == config_menu)
    	ConfigMenu(client, false);
    else if (object_id == versus_menu)
    	VersusMenu(client, false);
    }
}

// This spawns an infected of your choice either at your crosshair if a4d_automatic_placement is false or automatically.
// Currently you can only spawn one thing at once.
public Action:CommandSpawnInfected(client, args) { 
  if (args < 1) {
    ReplyToCommand(client, "Usage: a4d_spawn_infected <tank|witch|boomer|hunter|smoker|common|mob|spitter|charger|jockey>"); 
    return Plugin_Handled;
  }	
	new String:type[16];	
	GetCmdArg(1, type, sizeof(type));
  if (IsValidInfectedType(type))
    SpawnInfected(client, type);
  else
    ReplyToCommand(client, "Usage: a4d_spawn_infected <tank|witch|boomer|hunter|smoker|common|mob|spitter|charger|jockey>");
	return Plugin_Handled;
}

// Check to see if the infected provided is a valid type
public IsValidInfectedType(const String:type[]) {
  if (StrEqual(type, "tank") || StrEqual(type, "witch") || StrEqual(type, "boomer") || StrEqual(type, "hunter") || StrEqual(type, "smoker") || StrEqual(type, "common") || StrEqual(type, "mob") || StrEqual(type, "charger") || StrEqual(type, "spitter") || StrEqual(type, "jockey"))
    return true;
  return false;
}

SpawnInfected(client, const String:type[]) {
  new String:arguments[16];
  new String:feedback[64];
  Format(feedback, sizeof(feedback), "A %s has been spawned", type);
	if (GetConVarBool(automatic_placement) == true)
		Format(arguments, sizeof(arguments), "%s %s", type, "auto");
	else
		Format(arguments, sizeof(arguments), "%s", type);
  currently_spawning = true;
	// If we are spawning from the console make sure we force auto placement on	
	if (client == 0) {
		Format(arguments, sizeof(arguments), "%s %s", type, "auto");
  	StripAndExecuteClientCommand(GetFakeClient(), "z_spawn", arguments);
	} else {
		StripAndExecuteClientCommand(client, "z_spawn", arguments);
	}
  NotifyPlayers(client, feedback);
  LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
}

// This toggles whether or not we want the director to automatically place the things we spawn.
// The director will place mobs outside the players sight so it will not look like they are magically appearing.
public Action:CommandEnableAutoPlacement(client, args) {
	if (args < 1) {
    ReplyToCommand(client, "Usage: a4d_enable_auto_placement <0|1>");
    return Plugin_Handled;
  }
	new String:value[16];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		EnableAutoPlacement(client, false);		
	else
		EnableAutoPlacement(client, true);
	return Plugin_Handled;
}

EnableAutoPlacement(client, bool:value) {
	SetConVarBool(automatic_placement, value);
  if (value == true)
	  NotifyPlayers(client, "Automatic placement of spawned infected has been enabled.");
	else
		NotifyPlayers(client, "Automatic placement of spawned infected has been disabled.");
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_automatic_placement", value);	
}

// This menu deals with all commands related to spawning items/creatures
public Action:SpawnInfectedMenu(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnInfected);
	SetMenuTitle(menu, "Spawn Infected");
  SetMenuExitBackButton(menu, true);
  SetMenuExitButton(menu, true);
	AddMenuItem(menu, "sh", "Spawn a hunter");
	AddMenuItem(menu, "sb", "Spawn a boomer");
	AddMenuItem(menu, "ss", "Spawn a smoker");
	AddMenuItem(menu, "sp", "Spawn a spitter");
	AddMenuItem(menu, "sj", "Spawn a jockey");
	AddMenuItem(menu, "sc", "Spawn a charger");	
	AddMenuItem(menu, "st", "Spawn a tank");
	AddMenuItem(menu, "sw", "Spawn a witch");
	AddMenuItem(menu, "sm", "Spawn a default mob");
	if (GetConVarBool(automatic_placement))
    AddMenuItem(menu, "ap", "Disable automatic placement");
  else 
    AddMenuItem(menu, "ap", "Enable automatic placement");
	AddMenuItem(menu, "s1", "Spawn a riot zombie");
	AddMenuItem(menu, "s2", "Spawn a ceda zombie");
	AddMenuItem(menu, "s3", "Spawn a clown zombie");
	AddMenuItem(menu, "s4", "Spawn a mudmen zombie");
	AddMenuItem(menu, "s5", "Spawn a roadworker zombie");
	AddMenuItem(menu, "s6", "Spawn a jimmie gibbs zombie");
	AddMenuItem(menu, "s7", "Spawn a fallen survivor zombie");
	
	AddMenuItem(menu, "s0", "Spawn a randomized uncommon mob");
	AddMenuItem(menu, "s1", "Spawn a riot mob");
	AddMenuItem(menu, "s2", "Spawn a ceda mob");
	AddMenuItem(menu, "s3", "Spawn a clown mob");
	AddMenuItem(menu, "s4", "Spawn a mudmen mob");
	AddMenuItem(menu, "s5", "Spawn a roadworker mob");
	AddMenuItem(menu, "s6", "Spawn a jimmie gibbs mob");
	AddMenuItem(menu, "s7", "Spawn a fallen survivor mob");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

public MenuHandler_SpawnInfected(Handle:menu, MenuAction:action, cindex, itempos) {
  // When a player selects an item do this.  	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0:
				SpawnInfected(cindex, "hunter");
			case 1:
				SpawnInfected(cindex, "boomer");
			case 2:
				SpawnInfected(cindex, "smoker");
			case 3:
				SpawnInfected(cindex, "spitter");
			case 4:
				SpawnInfected(cindex, "jockey");
			case 5:
				SpawnInfected(cindex, "charger");
			case 6:
				SpawnInfected(cindex, "tank");
			case 7:
				SpawnInfected(cindex, "witch");
			case 8:
				SpawnInfected(cindex, "mob");
			case 9:
				if (GetConVarBool(automatic_placement)) 
					EnableAutoPlacement(cindex, false); 
				else
					EnableAutoPlacement(cindex, true);
			case 10:
				SpawnUncommon(cindex, 1);
			case 11:
				SpawnUncommon(cindex, 2);
			case 12:
				SpawnUncommon(cindex, 3);
			case 13:
				SpawnUncommon(cindex, 4);
			case 14:
				SpawnUncommon(cindex, 5);
			case 15:
				SpawnUncommon(cindex, 6);
			case 16:
				SpawnUncommon(cindex, 7);
			case 17:
				SpawnUncommonHorde(8);
			case 18:
				SpawnUncommonHorde(1);
			case 19:
				SpawnUncommonHorde(2);
			case 20:
				SpawnUncommonHorde(3);
			case 21:
				SpawnUncommonHorde(4);
			case 22:
				SpawnUncommonHorde(5);
			case 23:
				SpawnUncommonHorde(6);
			case 24:
				SpawnUncommonHorde(7);
		}
		// If none of the above matches show the menu again
		SpawnInfectedMenu(cindex, false);
  // If someone closes the menu - close the menu	
  } else if (action == MenuAction_End)
		CloseHandle(menu);
  // If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
}

// This spawns a weapon of your choice in your inventory or on the floor if it is full.
// Currently you can only spawn one thing at once.
public Action:CommandSpawnWeapon(client, args) { 
  if (args < 1) {
    ReplyToCommand(client, "Usage: a4d_spawn_weapon <autoshotgun|pistol|hunting_rifle|rifle|pumpshotgun|smg>");
    return Plugin_Handled;
  }
  new String:type[16];	
  GetCmdArg(1, type, sizeof(type));
  if (IsValidItemType(type))
    SpawnItem(client, type);
  else
    ReplyToCommand(client, "Usage: a4d_spawn_infected <tank|witch|boomer|hunter|smoker|common|mob>");
	return Plugin_Handled;
}

// This menu deals with spawning weapons
public Action:SpawnWeaponsMenu(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapons);
	SetMenuTitle(menu, "Spawn Weapons");
	SetMenuExitBackButton(menu, true);
  SetMenuExitButton(menu, true);
	AddMenuItem(menu, "sa", "Spawn an auto shotgun");
	AddMenuItem(menu, "sh", "Spawn a hunting rifle");
	AddMenuItem(menu, "sp", "Spawn a pistol");
	AddMenuItem(menu, "sr", "Spawn a M4A1 rifle");
	AddMenuItem(menu, "ss", "Spawn a shotgun");
	AddMenuItem(menu, "sm", "Spawn a sub machine gun");
	AddMenuItem(menu, "sg", "Spawn a magnum");
	AddMenuItem(menu, "s1", "Spawn an AK74");
	AddMenuItem(menu, "s2", "Spawn a Desert Rifle");
	AddMenuItem(menu, "s3", "Spawn a Silenced SMG");
	AddMenuItem(menu, "s4", "Spawn a military Sniper");
	AddMenuItem(menu, "s5", "Spawn a Grenade Launcher");
	AddMenuItem(menu, "s6", "Spawn Incendiary Ammo");
	AddMenuItem(menu, "s7", "Spawn Explosive Ammo");
	
	AddMenuItem(menu, "m1", "Spawn a Baseball Bat");
	AddMenuItem(menu, "m2", "Spawn a Crowbar");
	AddMenuItem(menu, "m3", "Spawn a Frying Pan");
	AddMenuItem(menu, "m4", "Spawn a Police Baton");
	AddMenuItem(menu, "m5", "Spawn a Kricket Bat");
	AddMenuItem(menu, "m6", "Spawn an Electric Guitar");
	AddMenuItem(menu, "m7", "Spawn a Machete");
	AddMenuItem(menu, "m8", "Spawn a Fire Axe");
	AddMenuItem(menu, "m9", "Spawn a Katana");
	AddMenuItem(menu, "m10", "Spawn a Chainsaw");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

public MenuHandler_SpawnWeapons(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "autoshotgun");
			} case 1: {
				SpawnItem(cindex, "hunting_rifle");
			} case 2: {
				SpawnItem(cindex, "pistol");
			} case 3: {
				SpawnItem(cindex, "rifle");
			} case 4: {
				SpawnItem(cindex, "pumpshotgun");
			} case 5: {
				SpawnItem(cindex, "smg");
			} case 6: {
				SpawnItem(cindex, "pistol_magnum");
			} case 7: {
				SpawnItem(cindex, "rifle_ak47");
			} case 8: {
				SpawnItem(cindex, "rifle_desert");
			} case 9: {
				SpawnItem(cindex, "smg_silenced");
			} case 10: {
				SpawnItem(cindex, "sniper_military");
			} case 11: {
				SpawnItem(cindex, "grenade_launcher");
			} case 12: {
				SpawnItem(cindex, "weapon_upgradepack_incendiary");
			} case 13: {
				SpawnItem(cindex, "weapon_upgradepack_explosive");
			} case 14: {
				SpawnItem(cindex, "baseball_bat");
			} case 15: {
				SpawnItem(cindex, "crowbar");
			} case 16: {
				SpawnItem(cindex, "frying_pan");
			} case 17: {
				SpawnItem(cindex, "tonfa");
			} case 18: {
				SpawnItem(cindex, "cricket_bat");
			} case 19: {
				SpawnItem(cindex, "electric_guitar");
			} case 20: {
				SpawnItem(cindex, "machete");
			} case 21: {
				SpawnItem(cindex, "fireaxe");
			} case 22: {
				SpawnItem(cindex, "katana");
			} case 23: {
				SpawnItem(cindex, "chainsaw");
			}
		}
		SpawnWeaponsMenu(cindex, false);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	/* If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
    if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
}

// This spawns an item of your choice in your inventory or on the floor if you already have one.
// Currently you can only spawn one thing at once.
public Action:CommandSpawnItem(client, args) { 
  if (args < 1) { ReplyToCommand(client, "Usage: a4d_spawn_item <first_aid_kit|gastank|molotov|pain_pills|pipe_bomb|propanetank>"); return Plugin_Handled; }	
	new String:type[16];	
	GetCmdArg(1, type, sizeof(type));
  if (IsValidItemType(type))
    SpawnItem(client, type);
  else
    ReplyToCommand(client, "Usage: a4d_spawn_item <first_aid_kit|gastank|molotov|pain_pills|pipe_bomb|propanetank>");
	return Plugin_Handled;
}

// Check to see if the item is a valid type
public IsValidItemType(const String:type[]) {
  if (StrEqual(type, "autoshotgun") || StrEqual(type, "pistol") || StrEqual(type, "hunting_rifle") || StrEqual(type, "rifle") || StrEqual(type, "pumpshotgun") || StrEqual(type, "smg") || StrEqual(type, "pistol_magnum"))
    return true;
  if (StrEqual(type, "first_aid_kit") || StrEqual(type, "oxygentank") || StrEqual(type, "gascan") || StrEqual(type, "molotov") || StrEqual(type, "pain_pills") || StrEqual(type, "pipe_bomb") || StrEqual(type, "propanetank") || StrEqual(type, "adrenaline") || StrEqual(type, "defibrilator") || StrEqual(type, "vomitjar"))
    return true;  
  return false;
}

/* This menu deals with spawning items */
public Action:SpawnItemsMenu(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnItems);
	SetMenuTitle(menu, "Spawn Items");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "sd", "Spawn a defibrillator");
	AddMenuItem(menu, "sm", "Spawn a medkit");
	AddMenuItem(menu, "sp", "Spawn some pills");
	AddMenuItem(menu, "sa", "Spawn some adrenaline");
	AddMenuItem(menu, "sv", "Spawn a molotov");
	AddMenuItem(menu, "sb", "Spawn a pipe bomb");
	AddMenuItem(menu, "sb", "Spawn a Bile Jar");
	AddMenuItem(menu, "st", "Spawn a propane tank");
	AddMenuItem(menu, "so", "Spawn an oxygen tank");
	AddMenuItem(menu, "sg", "Spawn a gas tank");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

public MenuHandler_SpawnItems(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos)
		{
			case 0:
			{
				SpawnItem(cindex, "defibrillator");
			}
			case 1:
			{
				SpawnItem(cindex, "first_aid_kit");
			}
			case 2:
			{
				SpawnItem(cindex, "pain_pills");
			}
			case 3:
			{
				SpawnItem(cindex, "adrenaline");
			}
			case 4:
			{
				SpawnItem(cindex, "molotov");
			}
			case 5:
			{
				SpawnItem(cindex, "pipe_bomb");
			}
			case 6:
			{
				SpawnItem(cindex, "vomitjar");
			}
			case 7:
			{
				SpawnItem(cindex, "propanetank");
			}
			case 8:
			{
				SpawnItem(cindex, "oxygentank");
			}
			case 9:
			{
				SpawnItem(cindex, "gascan");
			}
		}
		SpawnItemsMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}

SpawnItem(client, const String:item[]) {
  new String:feedback[64]; 
  Format(feedback, sizeof(feedback), "A %s has been spawned", item);
	if (client == 0) {	
		ReplyToCommand(client, "Can not use this command from the console."); 
	} else {
		StripAndExecuteClientCommand(client, "give", item);
		NotifyPlayers(client, feedback);	
  	LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, item);
	}
}

// Force the AI director to trigger a panic event
// There does seem to be a cooldown on this command and it is very noisy. If you just want to spawn more zombies, use spawn mob instead
public Action:CommandForcePanic(client, args) { 
  ForcePanic(client);
	return Plugin_Handled;
}

ForcePanic(client) {
	if (client == 0)
  	StripAndExecuteClientCommand(GetFakeClient(), "director_force_panic_event", "");
	else
		StripAndExecuteClientCommand(client, "director_force_panic_event", "");
  NotifyPlayers(client, "The zombies are coming!");	
  LogAction(client, -1, "[NOTICE]: (%L) executed %s", client, "a4d_force_panic");
}

// Force the AI Director to start panic events constantly, one after each another, until asked politely to stop. 
// It won't start working until a panic event has been triggered. If you want it to start doing this straight away trigger a panic event.
public Action:CommandPanicForever(client, args) {
	if (args < 1) { 
	  ReplyToCommand(client, "Usage: a4d_panic_forever <0|1>"); 
	  return Plugin_Handled;
	}
	
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	
	if (StrEqual(value, "0"))
		PanicForever(client, false);
	else
		PanicForever(client, true);
	return Plugin_Handled;
}

PanicForever(client, bool:value) {
	StripAndChangeServerConVarBool(client, "director_panic_forever", value);
  if (value == true)
    NotifyPlayers(client, "Endless panic events have started.");
	else
		NotifyPlayers(client, "Endless panic events have ended.");
}

// This command forces the AI Director to spawn a tank this round. The admin doesn't have control over where it spawns or when.
// I am not certain but pretty confident that if a tank has already been spawned this won't force the director to spawn another.
public Action:CommandForceTank(client, args) {
	if (args < 1) { 
	  ReplyToCommand(client, "Usage: a4d_force_tank <0|1>"); 
	  return Plugin_Handled; 
	}
	
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));

	if (StrEqual(value, "0"))
		ForceTank(client, false);	
	else 
		ForceTank(client, true);
	return Plugin_Handled;
}

ForceTank(client, bool:value) {
	StripAndChangeServerConVarBool(client, "director_force_tank", value);
	if (value == true)
		NotifyPlayers(client, "A tank is guaranteed to spawn this round");
	else
		NotifyPlayers(client, "A tank is no longer guaranteed to spawn this round");
}

// Force the AI Director to spawn a witch somewhere in the players path this round. The admin doesn't have control over where it spawns or when.
// I am not certain but pretty confident that if a witch has already been spawned this won't force the director to spawn another.
public Action:CommandForceWitch(client, args) {
	if (args < 1) { 
	  ReplyToCommand(client, "Usage: a4d_force_witch <0|1>"); 
	  return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		ForceWitch(client, false);
	else 
		ForceWitch(client, true);
	return Plugin_Handled;
}

ForceWitch(client, bool:value) {
	StripAndChangeServerConVarBool(client, "director_force_witch", value);
  if (value == true)
		NotifyPlayers(client, "A witch is guaranteed to spawn this round");	
	else 
		NotifyPlayers(client, "A witch is no longer guaranteed to spawn this round");
}

// This enables the AI Director to spawn more zombies in the mobs and mega mobs.
// Make sure to not put silly values in for this as it may cause severe performance problems.
// You can reset all settings back to their defaults by calling a4d_reset_to_defaults.

public Action:CommandAddZombies(client, args) {
	if (args < 1) { 
	  ReplyToCommand(client, "Usage: a4d_add_zombies <0..99>"); 
	  return Plugin_Handled;
	}
	new String:value[4];
	GetCmdArg(1, value, sizeof(value));
	new zombies = StringToInt(value);
	AddZombies(client, zombies);
	return Plugin_Handled;
}

AddZombies(client, zombies_to_add) {
	new new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mega_mob_size"));
	StripAndChangeServerConVarInt(client, "z_mega_mob_size", new_zombie_total);
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mob_spawn_max_size"));
	StripAndChangeServerConVarInt(client, "z_mob_spawn_max_size", new_zombie_total);
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mob_spawn_min_size"));
	StripAndChangeServerConVarInt(client, "z_mob_spawn_min_size", new_zombie_total);
	NotifyPlayers(client, "The horde grows larger.");
}

public Action:CommandSpawnBossesContinuously(client, args) {
  if (args < 1) { 
	  ReplyToCommand(client, "Usage: a4d_always_force_bosses <0|1>"); 
	  return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		SpawnBossesContinuously(client, false);		
	else
		SpawnBossesContinuously(client, true);
	return Plugin_Handled;
}

SpawnBossesContinuously(client, bool:value) {
	SetConVarBool(always_force_bosses, value);
	if (value == true)
		NotifyPlayers(client, "Bosses will now spawn continuously.");
	else
		NotifyPlayers(client, "Bosses will now longer spawn continuously.");
}

public Action:DirectorMenu(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_Director);
	SetMenuTitle(menu, "Director Commands");
	SetMenuExitBackButton(menu, true);
      SetMenuExitButton(menu, true);
	AddMenuItem(menu, "fp", "Force a panic event to start");
	if (GetConVarBool(FindConVar("director_panic_forever"))) { AddMenuItem(menu, "pf", "End non-stop panic events"); } else { AddMenuItem(menu, "pf", "Force non-stop panic events"); }
	if (GetConVarBool(FindConVar("director_force_tank"))) { AddMenuItem(menu, "ft", "Director controls if a tank spawns this round"); } else { AddMenuItem(menu, "ft", "Force a tank to spawn this round"); }
	if (GetConVarBool(FindConVar("director_force_witch"))) { AddMenuItem(menu, "fw", "Director controls if a witch spawns this round"); } else { AddMenuItem(menu, "fw", "Force a witch to spawn this round"); }
	AddMenuItem(menu, "mz", "Add more zombies to the horde");	
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

public MenuHandler_Director(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				ForcePanic(cindex);
			} case 1: {
				if (GetConVarBool(FindConVar("director_panic_forever"))) 
					PanicForever(cindex, false); 
				else
					PanicForever(cindex, true);
			} case 2: {
				if (GetConVarBool(FindConVar("director_force_tank")))
					ForceTank(cindex, false); 
				else
					ForceTank(cindex, true);
			} case 3: {
				if (GetConVarBool(FindConVar("director_force_witch"))) 
					ForceWitch(cindex, false);
				else
					ForceWitch(cindex, true);
			} case 4: {
				AddZombies(cindex, GetConVarInt(zombies_increment));
			} 
		}
		DirectorMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}

// Set if we should notify players based on the sm_activity ConVar or not
public Action:CommandEnableNotifications(client, args) {
	if (args < 1) { 
	  ReplyToCommand (client, "Usage: a4d_enable_notifications <0|1>"); 
	  return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0")) 
		EnableNotifications(client, false);		
	else
		EnableNotifications(client, true);
	return Plugin_Handled;
}

EnableNotifications(client, bool:value) {
	SetConVarBool(notify_players, value);
	NotifyPlayers(client, "Player notifications have now been enabled.");
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_notify_players", value);	
}

/* Resets all ConVars to their default settings. */
/* Should be used if you screwed something up or at the beginning of every map to have a normal game */
public Action:CommandResetToDefaults(client, args) {
	ResetToDefaults(client);
	return Plugin_Handled;
}

ResetToDefaults(client) {
	ForceTank(client, false);
	ForceWitch(client, false);
	PanicForever(client, false);
	StripAndChangeServerConVarInt(client, "z_mega_mob_size", 50);
	StripAndChangeServerConVarInt(client, "z_mob_spawn_max_size", 30);
	StripAndChangeServerConVarInt(client, "z_mob_spawn_min_size", 10);
	NotifyPlayers(client, "Restored the default settings.");
	LogAction(client, -1, "(%L) executed %s", client, "a4d_reset_to_defaults");
}

/* This menu deals with all Configuration commands that don't fit into another category */
public Action:ConfigMenu(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_Config);
	SetMenuTitle(menu, "Configuration Commands");
	SetMenuExitBackButton(menu, true);
  SetMenuExitButton(menu, true);
	if (GetConVarBool(notify_players)) { AddMenuItem(menu, "pn", "Disable player notifications"); } else { AddMenuItem(menu, "pn", "Enable player notifications"); }
	AddMenuItem(menu, "rs", "Restore all settings to game defaults now");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

public MenuHandler_Config(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				if (GetConVarBool(notify_players))
					EnableNotifications(cindex, false); 
				else
					EnableNotifications(cindex, true); 
			} case 1: {
				ResetToDefaults(cindex);
			}
		}
		ConfigMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}

// Enable all bot survivor team
public Action:CommandEnableAllBotTeams(client, args) {
	if (args < 1) { 
	  ReplyToCommand(client, "Usage: a4d_enable_all_bot_teams <0|1>"); 
	  return Plugin_Handled;
	}

	new String:value[2];
	GetCmdArg(1, value, sizeof(value));

	if (StrEqual(value, "0"))
		EnableAllBotTeam(client, false);	
	else
		EnableAllBotTeam(client, true);
	return Plugin_Handled;
}

EnableAllBotTeam(client, bool:value) {
	StripAndChangeServerConVarBool(client, "sb_all_bot_team", value);
	if (value == true)
		NotifyPlayers(client, "Allowing an all bot survivor team.");	
	else
		NotifyPlayers(client, "We now require at least one human survivor before the game can start.");
}

// This menu deals with game play commands
public Action:VersusMenu(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_Versus);
	SetMenuTitle(menu, "Versus Settings");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	if (GetConVarBool(FindConVar("sb_all_bot_team"))) { AddMenuItem(menu, "bc", "Require at least one human survivor"); } else { AddMenuItem(menu, "bc", "Allow the game to start with no human survivors"); }		
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}

public MenuHandler_Versus(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				if (GetConVarBool(FindConVar("sb_all_bot_team"))) { 
					EnableAllBotTeam(cindex, false); 
				} else {
					EnableAllBotTeam(cindex, true); 
				} 
			}
		}
		VersusMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}


// Helper functions

NotifyPlayers(client, const String:message[]) {
  if (GetConVarBool(notify_players))
    ShowActivity2(client, PLUGIN_TAG, message);
}

StripAndChangeServerConVarBool(client, String:command[], bool:value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarBool(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
	LogAction(client, -1, "[NOTICE]: (%L) set %s to %i", client, command, value);	
}

StripAndExecuteClientCommand(client, const String:command[], const String:arguments[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

/* Strip and change a ConVar to the value sppcified */
/* This doesn't do any maths. If you want to add 10 to an existing ConVar you need to work out the value before you call this */
StripAndChangeServerConVarInt(client, String:command[], value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
	LogAction(client, -1, "[NOTICE]: (%L) set %s to %i", client, command, value);	
}

// Gets a fake client ID to allow various commands to be called as console
GetFakeClient() {
	// If the old command client is still valid use that otherwise find a new one.
	if (command_client != 0 && IsClientConnected(command_client) && IsClientInGame(command_client) && IsFakeClient(command_client)) {
		return command_client;
	} else {
		for (new i = 1; i <= 18; i++) 
		{ 
		  if (IsClientInGame(i) && IsFakeClient(i))
		  {
		  	command_client = i;    
				break;
		  } 
		}
	return command_client;	
	}
}

SpawnUncommon(client, number)
{
	decl Float:location[3], Float:ang[3], Float:location2[3];
	GetClientAbsOrigin(client, location);
	GetClientEyeAngles(client, ang);
	
	location2[0] = (location[0]+(50*(Cosine(DegToRad(ang[1])))));
	location2[1] = (location[1]+(50*(Sine(DegToRad(ang[1])))));
	location2[2] = location[2] + 30.0;
	
	SpawnUncommonInf(number, location2);
}

SpawnUncommonHorde(number)
{
	decl String:class[256];
	new bool:foundpos;
	
	for (new i = 32; i <= GetMaxEntities(); i++)
	{
		if (!IsValidEntity(i)) continue;
		
		GetEdictClassname(i, class, sizeof(class));

		if (!StrEqual(class, "infected", false)) continue;
		
		GetEntityAbsOrigin(i, spawnpoint);
		if (!NearHumans(spawnpoint)) 
		{
			foundpos = true;
			break;
		}
	}
	
	if (foundpos)
	{
		RemainingZombiesToSpawn = 30;
		CreateTimer(0.2, SpawnMoreUncommons, number, TIMER_REPEAT);
	}
}

public Action:SpawnMoreUncommons(Handle:timer, any:number)
{
	RemainingZombiesToSpawn --;
	if (RemainingZombiesToSpawn <= 0)
	{
		KillTimer(timer);
		CallHorde();
	}
	else
	{
		SpawnUncommonInf(number, spawnpoint);
	}
}

SpawnUncommonInf(number, Float:location[3])
{
	new zombie = CreateEntityByName("infected");
	decl String:model[256];
	
	if (number ==8) number = GetRandomInt(1,5);
	
	switch (number)
	{
		case 1:
		{
			Format(model, sizeof(model), "models/infected/common_male_riot.mdl");
		}
		case 2:
		{
			Format(model, sizeof(model), "models/infected/common_male_ceda.mdl");
		}
		case 3:
		{
			Format(model, sizeof(model), "models/infected/common_male_clown.mdl");
		}
		case 4:
		{
			Format(model, sizeof(model), "models/infected/common_male_mud.mdl");
		}
		case 5:
		{
			Format(model, sizeof(model), "models/infected/common_male_roadcrew.mdl");
		}
		case 6:
		{
			Format(model, sizeof(model), "models/infected/common_male_jimmy.mdl");
		}
		case 7:
		{
			Format(model, sizeof(model), "models/infected/common_male_fallen_survivor.mdl");
		}
	}
	
	SetEntityModel(zombie, model);
	new ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
	SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);

	DispatchSpawn(zombie);
	ActivateEntity(zombie);
	
	location[2] -= 25.0; //reduce the 'drop' effect
	TeleportEntity(zombie, location, NULL_VECTOR, NULL_VECTOR);
}

CallHorde()
{
	SetConVarInt(FindConVar("z_mega_mob_size"), 1);
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), 1);
	CheatCommand(GetAnyClient(), "director_force_panic_event", "");
	CreateTimer(10.0, ResetVars);
}

public Action:ResetVars(Handle:timer)
{
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), DefaultMaxHorde);
	SetConVarInt(FindConVar("z_mega_mob_size"), DefaultMegaMob);
}

bool:NearHumans(Float:position[3])
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (GetClientHealth(target)>1 && GetClientTeam(target) == 2) // make sure target is a Survivor
			{
				decl Float:targetPos[3];
				GetClientAbsOrigin(target, targetPos);
				
				new Float:distance = GetVectorDistance(targetPos, position); // check Survivor Distance from checking point
					
				if (distance < 800.0)
				{
					return true;
				}
				else continue;
			}
		}
	}
	return false;
}

GetEntityAbsOrigin(entity,Float:origin[3])
{
	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			return i;
		}
	}
	return 0;
}

CheatCommand(client, const String:command[], const String:arguments[])
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

public Action:CommandGiveLaser(client, args)
{
	if (args < 1)
	{ 
	  ReplyToCommand(client, "Usage: sm_givelaser <user>"); 
	  return Plugin_Handled;
	}
	
	new String:name[256];
	GetCmdArg(1, name, sizeof(name));
	
	new target = FindTarget(client, name);
	if (target > 0)
	{
		CheatCommand(target, "upgrade_add", "LASER_SIGHT");
	}

	return Plugin_Handled;
}