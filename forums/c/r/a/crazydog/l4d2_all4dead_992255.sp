/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* All4Dead - A modification for the game Left4Dead */
/* Copyright 2009 James Richardson */

/*
* Version 1.0
* 		- Initial release.
* Version 1.1
* 		- Added support for console and chat commands instead of using the menu
* Version 1.2
* 		- Changed name from "Overseer" to "All4Dead"
*			- Added "a4d_spawn" to spawn infected without sv_cheats 1
*			-	Added support for automatically resetting relevant game ConVars to defaults on a map change. 
*     - Added "FCVAR_CHEAT" to all the CVARs. 
* Version 1.2.1
* 		- Fixed a bug where manually spawned infected would spawn with little or no health.
* Version 1.3
* 		- Changed "a4d_spawn" to "a4d_spawn_infected"
* 		- Added "a4d_spawn_weapon"
* 		- Added "a4d_spawn_item"
*			- Added commands to toggle all bot survivor teams.
* 		- Added support for randomising boss locations in versus.
* 		- Added support to ensure consistency of boss spawns between teams.
* 		- Moved the automatic reset function to OnMapEnd instead of OnMapStart. Should resolve double tank bug.
* Version 1.3.1
* 		- Fixed bug with the arg string array being slightly too small for "a4d_spawn_item" and "a4d_spawn_weapon".
* Version 1.4.0
*			- Added feature which enforces versus mode across a series maps until the server hibernates.
*			- Changed "toggle" commands to "enable" commands. More descriptive of what they actually do.
*			- Cleaned up menus so they are easier to understand.
*			- Fixed bug where we were not enforcing consistent boss types if the old versus logic was not enabled.
*			- General code clean up.
*			- Replaced "a4d_director_is_enabled" ConVar with an internal variable.
*			- Replaced "a4d_vs_force_versus_mode" ConVar with an internal variable.
*			- Removed "a4d_force_old_versus_logic" ConVar.
*			- Removed feature for automatic reset of game settings. Instead settings are reverted when the server hibernates.
*			- Seperated All4Dead configuation into cfg/sourcemod/plugin.all4dead
* Version 1.4.1
*			- Fixed issue where players would get stuck in limbo if you disable versus mode.	
* Version 1.4.2
*			- Changed PlayerSpawn to give health to all infected players when spawned. This should fix a rare bug.
* Version 1.4.3
*			- All4Dead will now actually take notice of what you put in plugin.all4dead.cfg.
*			- Added "a4d_vs_randomise_boss_locations" ConVar.
*			- Added warning if plugin.all4dead.cfg version does not match plugin version.
*			- Fixed bug where ResetToDefaults would force coop mode on versus maps.
*			- Removed hibernation timer. It was causing errors and was unnecessary after all.
*			- Reverted change to PlayerSpawn made in 1.4.2. The old behavior was correct.	
* Version 1.4.4
*     - Automatically change "z_spawn_safety_range" to match the game mode in play.
*     - Changed behaviour so versus mode is now continuously forced and safe from tampering.
*     - Fixed a bug where Event_BossSpawnsSet would not reset its own changes to ForceTank and ForceWitch on map changes.
*     - Fixed a bug with EnableOldVersusLogic reporting incorrect state changes.
*     - Fixed a bug where boss spawn tracking was sometimes not being reset correctly between maps.
*     - Fixed a bug where EnableOldVersusLogic would display a misleading notification.       
*     - Worked around RoundEnd being called twice! (once at the end of a round and again just before a new round starts) 
* Version 1.4.5
*			- Removed force versus feature (it was an ugly hack and is no longer necessary now all maps are playable on versus)
*/

/* Define constants */
#define PLUGIN_VERSION    "1.4.5"
#define PLUGIN_NAME       "All4Dead"
#define PLUGIN_TAG  	  	"[A4D] "
#define MAX_PLAYERS				14		

/* Include necessary files */
#include <sourcemod>
/* Make the admin menu optional */
#undef REQUIRE_PLUGIN
#include <adminmenu>

/* Create ConVar Handles */
new Handle:NotifyPlayers = INVALID_HANDLE;
new Handle:AutomaticPlacement = INVALID_HANDLE;
new Handle:IdenticalBosses = INVALID_HANDLE;
new Handle:UseOldLogic = INVALID_HANDLE;

/* Create handle for the admin menu */
new Handle:AdminMenu = INVALID_HANDLE;
new TopMenuObject:dc = INVALID_TOPMENUOBJECT;
new TopMenuObject:cc = INVALID_TOPMENUOBJECT;
new TopMenuObject:vs = INVALID_TOPMENUOBJECT;
new TopMenuObject:si = INVALID_TOPMENUOBJECT;
new TopMenuObject:so = INVALID_TOPMENUOBJECT;
new TopMenuObject:sw = INVALID_TOPMENUOBJECT;
new TopMenuObject:sm = INVALID_TOPMENUOBJECT;
new TopMenuObject:mi = INVALID_TOPMENUOBJECT;

/* Globals */
new bool:TankHasSpawned = false
new bool:WitchHasSpawned = false
new bool:CurrentlySpawning = false
new bool:DirectorIsEnabled = true
new bool:BossSpawnsSet = false	


/* Metadata for the mod */
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Enables admins to have control over the AI Director",
	version = PLUGIN_VERSION,
	url = "www.grandwazir.com"
};

/* Create and set all the necessary for All4Dead and register all our commands */ 
public OnPluginStart() {
	/* Create all the necessary ConVars and execute auto-configuation */
	/* We add cheat flags to our ConVars to stop other admins with lesser flags altering our plugin */
	AutomaticPlacement = CreateConVar("a4d_automatic_placement", "1", "Whether or not we ask the director to place things we spawn.", FCVAR_PLUGIN);	
	NotifyPlayers = CreateConVar("a4d_notify_players", "1", "Whether or not we announce changes in game.", FCVAR_PLUGIN);	
	CreateConVar("a4d_version", PLUGIN_VERSION, "The version of All4Dead plugin.", FCVAR_PLUGIN);
	UseOldLogic = CreateConVar("a4d_vs_randomise_boss_locations", "0", "Whether or not we randomise boss locations in versus mode (old versus logic)", FCVAR_PLUGIN);		
	IdenticalBosses = CreateConVar("a4d_vs_ensure_identical_bosses", "0", "When using the old versus logic do we ensure that both teams get the same type of bosses.", FCVAR_PLUGIN); 			
	CreateConVar("a4d_zombies_to_add", "10", "The amount of zombies to add when an admin requests more zombies.", FCVAR_PLUGIN);
	/* We make sure that only admins that are permitted to cheat are allow to run these commands */
	/* Register all the director commands */
	RegAdminCmd("a4d_add_zombies", Command_AddZombies, ADMFLAG_CHEATS);	
	RegAdminCmd("a4d_delay_rescue", Command_DelayRescue, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_enable_all_bot_teams", Command_EnableAllBotTeam, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_enable_auto_placement", Command_EnableAutoPlacement, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_enable_identical_versus_bosses", Command_EnableIdenticalBosses, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_enable_notifications", Command_EnableNotifications, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_enable_old_versus_logic", Command_EnableOldVersusLogic, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_force_panic", Command_ForcePanic, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_force_tank", Command_ForceTank, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_force_witch", Command_ForceWitch, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_panic_forever", Command_PanicForever, ADMFLAG_CHEATS);	
	RegAdminCmd("a4d_reset_to_defaults", Command_ResetToDefaults, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_spawn_infected", Command_SpawnInfected, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_spawn_weapon", Command_SpawnWeapon, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_spawn_item", Command_SpawnItem, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_toggle_director", Command_ToggleDirector, ADMFLAG_CHEATS);
	/* Hook this event so we can give things we spawn max health */
	HookEvent("player_spawn", Event_PlayerSpawn)
	HookEvent("tank_spawn", Event_BossSpawn, EventHookMode_PostNoCopy)
	HookEvent("witch_spawn", Event_BossSpawn, EventHookMode_PostNoCopy)
	HookEvent("round_end", Event_BossSpawnsSet, EventHookMode_PostNoCopy)
	/* Execute the configuation file (create if it doesn't exist */
	AutoExecConfig(true)	
	/* If the Admin menu has been loaded start adding stuff to it */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
	LogAction(0, -1, "%s %s has been loaded.", PLUGIN_NAME, PLUGIN_VERSION)
}


/* When a map is loaded refresh spawn tracking variables and force versus if required. */
public OnMapStart() {
	TankHasSpawned = false
	WitchHasSpawned = false
	BossSpawnsSet = false
} 

public OnMapEnd() {
	if (GetConVarBool(IdenticalBosses)) {
		ForceTank(0, false)
		ForceWitch(0, false)
		LogAction(0, -1, "Reset director behavior in preperation for the next map.")
	}
}

/* If the plugin is unloaded for any reason make sure to clean up after ourselves */
public OnPluginEnd() {
	ResetToDefaults(0)
	LogAction(0, -1, "%s %s has been unloaded.", PLUGIN_NAME, PLUGIN_VERSION)
}

/* When we have executed our auto config file enforce the old versus logic if required. */
public OnConfigsExecuted() {
	/* If we are enabling the old versus logic from start up enable it now */
	if (GetConVarBool(UseOldLogic)) {
		EnableOldVersusLogic(0, true)
	}
	/* Check to see if the configuation file is out of date. */
	new String:version[16]
	GetConVarString(FindConVar("a4d_version"), version, sizeof(version))	
	if (!StrEqual(version, PLUGIN_VERSION)) {
		LogAction(0, -1, "WARNING: Your plugin.all4dead.cfg is out of date. Please delete it and restart your server.")
	}
	LogAction(0, -1, "plugin.all4dead.cfg has been loaded.")
}

/* If the admin menu is unloaded, stop trying to use it */
public OnLibraryRemoved(const String:name[]) {
	if (StrEqual(name, "adminmenu")) {
		AdminMenu = INVALID_HANDLE;
	}
}
/* Event Handlers */

/* If a boss has spawned make sure we make a note of it so we can spawn it for the other team as well */
public Action:Event_BossSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarBool(IdenticalBosses)) {
		if (StrEqual(name, "tank_spawn")) {
			TankHasSpawned = true;
		} else if (StrEqual(name, "witch_spawn")) {
			WitchHasSpawned = true;
		}
	}
}

/* When the round ends force boss spawns for the next team if appropriate. */
public Action:Event_BossSpawnsSet(Handle:event, const String:name[], bool:dontBroadcast) {
	/* If we are enforcing identical bosses and versus mode is on (phew!) ensure consistency */
	new String:GameMode[16]
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode))	
	if (GetConVarBool(IdenticalBosses) && StrEqual(GameMode, "versus") && !GetConVarBool(FindConVar("versus_boss_spawning")) && !BossSpawnsSet) {
		ForceTank(0,TankHasSpawned)
		ForceWitch(0,WitchHasSpawned)
		LogAction(0, -1, "Ensured consistency of boss spawns for the next round.");
		BossSpawnsSet = true
	}
}

/* If we have just spawned something, make sure it has max health */
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	/* If something spawns and we have just requested something to spawn - assume it is the same thing and make sure it has max health */
	if (GetClientTeam(client) == 3 && CurrentlySpawning) {
		StripAndExecuteClientCommand(client, "give", "health", "", "")
		/* We have added health to the thing we have spawned so turn ourselves off */	
		CurrentlySpawning = false	
	}
}


/* Commands */

/* This enables the AI Director to spawn more zombies in the mobs and mega mobs */
/* Make sure to not put silly values in for this as it may cause severe performance problems. */
/* You can reset all settings back to their defaults by calling a4d_reset_to_defaults */
public Action:Command_AddZombies(client, args) {
	if (args < 1) { PrintToConsole(client, "Usage: a4d_add_zombies <0..99>"); return Plugin_Handled; }	
	
	new String:value[3]
	GetCmdArg(1, value, sizeof(value))
	new zombies = StringToInt(value)
	AddZombies(client, zombies)
	return Plugin_Handled;
}

AddZombies(client, zombies_to_add) {
	new new_zombie_total	
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mega_mob_size"))
	StripAndChangeServerConVarInt("z_mega_mob_size", new_zombie_total)
	LogAction(client, -1, "(%L) set %s to %i", client, "z_mega_mob_size", new_zombie_total);
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mob_spawn_max_size"))
	StripAndChangeServerConVarInt("z_mob_spawn_max_size", new_zombie_total)
	LogAction(client, -1, "(%L) set %s to %i", client, "z_mob_spawn_max_size", new_zombie_total);
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mob_spawn_min_size"))
	StripAndChangeServerConVarInt("z_mob_spawn_min_size", new_zombie_total)
	LogAction(client, -1, "(%L) set %s to %i", client, "z_mob_spawn_min_size", new_zombie_total);
	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "More zombies will now be spawned."); }
}

/* Force the AI Director to delay the rescue vehicle indefinitely */
/* This means that the end wave essentially never stops. The director makes sure that one tank is always alive at all times during the last wave. */ 
/* Disabling this once the survivors have reached the last wave of the finale seems to have no effect (can anyone test this to be sure?) */
public Action:Command_DelayRescue(client, args) {
	if (args < 1) { PrintToConsole(client, "Usage: a4d_delay_rescue <0|1>"); return Plugin_Handled; }	
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		DelayRescue(client, false)		
	} else if (StrEqual(value, "1")) {
		DelayRescue(client, true)
	} else {
		PrintToConsole(client, "Usage: a4d_delay_rescue <0|1>")
	}
	return Plugin_Handled;
}

DelayRescue(client, bool:value) {
	new String:command[] = "director_finale_infinite";
	StripAndChangeServerConVarBool(command, value)
	if (GetConVarBool(NotifyPlayers) == true) { 	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "The rescue vehicle has been delayed indefinitely.");
		} else {
			ShowActivity2(client, PLUGIN_TAG, "The rescue vehicle is on its way.");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, command, value);	
}

/* Enable all bot survivor team */
public Action:Command_EnableAllBotTeam(client, args) {
	
	if (args < 1) { PrintToConsole(client, "Usage: a4d_enable_all_bot_team <0|1>"); return Plugin_Handled; }	

	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		EnableAllBotTeam(client, false)		
	} else if (StrEqual(value, "1")) {
		EnableAllBotTeam(client, true)
	} else {
		PrintToConsole(client, "Usage: a4d_enable_all_bot_team <0|1>")
	}
	return Plugin_Handled;
}

EnableAllBotTeam(client, bool:value) {
	new String:command[] = "sb_all_bot_team";
	StripAndChangeServerConVarBool(command, value)
	if (GetConVarBool(NotifyPlayers) == true) {	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "Allowing an all bot survivor team.");	
		} else {
			ShowActivity2(client, PLUGIN_TAG, "We now require at least one human survivor before the game can start.");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, command, value);	
}


/* Force the AI director to trigger a panic event */
/* There does seem to be a cooldown on this command and it is very noisy. If you just want to spawn more zombies, use spawn mob instead */
public Action:Command_ForcePanic(client, args) {
	ForcePanic(client)
	return Plugin_Handled;
}

ForcePanic(client) {
	new String:command[] = "director_force_panic_event";
	StripAndExecuteClientCommand(client, command, "","","")
	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "A panic event has been started."); }
	LogAction(client, -1, "(%L) executed %s", client, command);
}

/* Force the AI Director to start panic events constantly, one after each another, until asked politely to stop. */
/* It won't start working until a panic event has been triggered. If you want it to start doing this straight away trigger a panic event. */
public Action:Command_PanicForever(client, args) {
	
	if (args < 1) { PrintToConsole(client, "Usage: a4d_panic_forever <0|1>"); return Plugin_Handled; }
	
	new String:command[] = "director_panic_forever";
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		StripAndChangeServerConVarBool(command, false)
		if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "Endless panic events have ended."); }
		LogAction(client, -1, "(%L) set %s to %i", client, command, value);
	} else if (StrEqual(value, "1")) {
		StripAndChangeServerConVarBool(command, true)
		if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "Endless panic events have started."); }
		LogAction(client, -1, "(%L) set %s to %i", client, command, value);
	} else {
		PrintToConsole(client, "Usage: a4d_panic_forever <0|1>")
	}
	return Plugin_Handled;
}

PanicForever(client, bool:value) {
	new String:command[] = "director_panic_forever";
	StripAndChangeServerConVarBool(command, value)
	if (GetConVarBool(NotifyPlayers) == true) {	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "Endless panic events have started.");
		} else {
			ShowActivity2(client, PLUGIN_TAG, "Endless panic events have ended.");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, command, value);	
}

/* This command forces the AI Director to spawn a tank this round. The admin doesn't have control over where it spawns or when. */
/* I am not certain but pretty confident that if a tank has already been spawned this won't force the director to spawn another. */
public Action:Command_ForceTank(client, args) {
	
	if (args < 1) { PrintToConsole(client, "Usage: a4d_force_tank <0|1>"); return Plugin_Handled; }
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		ForceTank(client, false)		
	} else if (StrEqual(value, "1")) {
		ForceTank(client, true)
	} else {
		PrintToConsole(client, "Usage: a4d_force_tank <0|1>")
	}
	return Plugin_Handled;
}

ForceTank(client, bool:value) {
	new String:command[] = "director_force_tank";
	StripAndChangeServerConVarBool(command, value)
	if (GetConVarBool(NotifyPlayers) == true) {	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "A tank is guaranteed to spawn this round");
		} else {
			ShowActivity2(client, PLUGIN_TAG, "A tank is no longer guaranteed to spawn this round");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, command, value);	
}

/* Force the AI Director to spawn a witch somewhere in the players path this round. The admin doesn't have control over where it spawns or when. */
/* I am not certain but pretty confident that if a witch has already been spawned this won't force the director to spawn another. */
public Action:Command_ForceWitch(client, args) {
	
	if (args < 1) { PrintToConsole(client, "Usage: a4d_force_witch <0|1>"); return Plugin_Handled; }	

	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		ForceWitch(client, false)		
	} else if (StrEqual(value, "1")) {
		ForceWitch(client, true)
	} else {
		PrintToConsole(client, "Usage: a4d_force_witch <0|1>")
	}
	return Plugin_Handled;
}

ForceWitch(client, bool:value) {
	new String:command[] = "director_force_witch";
	StripAndChangeServerConVarBool(command, value)
	if (GetConVarBool(NotifyPlayers) == true) {	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "A witch is guaranteed to spawn this round");	
		} else {
			ShowActivity2(client, PLUGIN_TAG, "A witch is no longer guaranteed to spawn this round");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, command, value);	
}

/* This toggles the AI Director on or off */
/* Since there is no way to query the directors state in-game, we keep track of this infomation ourself in a4d_director_enabled */
/* The mod assumes that the director is enabled at the start of each map */
public Action:Command_ToggleDirector(client, args) {
	
	if (args < 1) { PrintToConsole(client, "Usage: a4d_toggle_director <0|1>"); return Plugin_Handled; }	
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		StopDirector(client)		
	} else if (StrEqual(value, "1")) {
		StartDirector(client)
	} else {
		PrintToConsole(client, "Usage: a4d_toggle_director <0|1>")
	}
	return Plugin_Handled;
}

StartDirector(client) {
	new String:command[] = "director_start";	
	StripAndExecuteClientCommand(client, command, "","","")
	DirectorIsEnabled = true
	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "The director has been enabled."); }
	LogAction(client, -1, "(%L) executed %s", client, command);
}

StopDirector(client) {
	new String:command[] = "director_stop";	
	StripAndExecuteClientCommand(client, command, "","","")
	DirectorIsEnabled = false
	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "The director has been disabled."); }
	LogAction(client, -1, "(%L) executed %s", client, command);
}

/* This spawns an infected of your choice either at your crosshair if a4d_automatic_placement is false or automatically */
/* Currently you can only spawn one thing at once. */
public Action:Command_SpawnInfected(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_spawn_infected <tank|witch|boomer|hunter|smoker|common|mob>"); return Plugin_Handled; }	
		
	new String:type[7]	
	GetCmdArg(1, type, sizeof(type))
	SpawnInfected(client, type)
	return Plugin_Handled;
}

SpawnInfected(client, String:type[]) {
	new String:command[] = "z_spawn";
	CurrentlySpawning = true
	if (GetConVarBool(AutomaticPlacement) == true) {
		StripAndExecuteClientCommand(client, command, type, "auto", "")
	} else {
		StripAndExecuteClientCommand(client, command, type, "", "")
	}

	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "A %s has been spawned", type); }
	LogAction(client, -1, "(%L) has spawned a %s", client, type);
}

/* This spawns a weapon of your choice in your inventory or on the floor if it is full */
/* Currently you can only spawn one thing at once. */
public Action:Command_SpawnWeapon(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_spawn_weapon <autoshotgun|pistol|hunting_rifle|rifle|pumpshotgun|smg>"); return Plugin_Handled; }	
		
	new String:type[16]	
	GetCmdArg(1, type, sizeof(type))
	SpawnItem(client, type)
	return Plugin_Handled;
}

public Action:Command_SpawnItem(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_spawn_item <first_aid_kit|gastank|molotov|pain_pills|pipe_bomb|propanetank>"); return Plugin_Handled; }	
		
	new String:type[16]	
	GetCmdArg(1, type, sizeof(type))
	SpawnItem(client, type)
	return Plugin_Handled;
}

SpawnItem(client, String:type[]) {
	new String:command[] = "give";
	StripAndExecuteClientCommand(client, command, type, "", "")

	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "A %s has been spawned", type); }
	LogAction(client, -1, "(%L) has spawned a %s", client, type);
}

AddUpgrade(client, String:type[]) {
	new String:command[] = "upgrade_add";
	StripAndExecuteClientCommand(client, command, type, "", "")

	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "A %s has been given", type); }
	LogAction(client, -1, "(%L) has been given a %s", client, type);
}

/* This toggles whether or not we want the director to automatically place the things we spawn */
/* The director will place mobs outside the players sight so it will not look like they are magically appearing */
public Action:Command_EnableAutoPlacement(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_enable_auto_placement <0|1>"); return Plugin_Handled; }	
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		EnableAutoPlacement(client, false)		
	} else if (StrEqual(value, "1")) {
		EnableAutoPlacement(client, true)	
	} else {
		PrintToConsole(client, "Usage: a4d_enable_auto_placement <0|1>")
	}
	return Plugin_Handled;
}

EnableAutoPlacement(client, bool:value) {
	SetConVarBool(AutomaticPlacement, value)
	if (GetConVarBool(NotifyPlayers) == true) { 	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "Automatic placement of spawned infected has been enabled.");
		} else {
			ShowActivity2(client, PLUGIN_TAG, "Automatic placement of spawned infected has been disabled.");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_automatic_placement", value);	
}

/* Set if we should notify players based on the sm_activity ConVar or not */
public Action:Command_EnableNotifications(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_enable_notifications <0|1>"); return Plugin_Handled; }	
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		EnableNotifications(client, false)		
	} else if (StrEqual(value, "1")) {
		EnableNotifications(client, true)	
	} else {
		PrintToConsole(client, "Usage: a4d_enable_notifications <0|1>")
	}
	return Plugin_Handled;
}

EnableNotifications(client, bool:value) {
	SetConVarBool(NotifyPlayers, value)
	if (GetConVarBool(NotifyPlayers) == true) { 	
		ShowActivity2(client, PLUGIN_TAG, "Player notifications have now been enabled.");
	}
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_notify_players", value);	
}
 /* Resets all ConVars to their default settings. */
/* Should be used if you screwed something up or at the beginning of every map to have a normal game */
public Action:Command_ResetToDefaults(client, args) {
	ResetToDefaults(client)
	return Plugin_Handled;
}

ResetToDefaults(client) {
	ForceTank(client, false)
	ForceWitch(client, false)
	PanicForever(client, false)
	DelayRescue(client, false)
	EnableOldVersusLogic(client, false)
	EnableIdenticalBosses(client, false)
	StripAndChangeServerConVarInt("z_mega_mob_size", 50);
	LogAction(client, -1, "%L) set %s to %i", client, "z_mob_spawn_max_size", 50);
	StripAndChangeServerConVarInt("z_mob_spawn_max_size", 30)
	LogAction(client, -1, "(%L) set %s to %i", client, "z_mob_spawn_max_size", 30);
	StripAndChangeServerConVarInt("z_mob_spawn_min_size", 10)
	LogAction(client, -1, "(%L) set %s to %i", client, "z_mob_spawn_max_size", 10);
	if (GetConVarBool(NotifyPlayers) == true) { ShowActivity2(client, PLUGIN_TAG, "Restored the default settings."); }
	LogAction(client, -1, "(%L) executed %s", client, "a4d_reset_to_defaults");
}

/* This toggles if we are using the old versus logic or the new one */
public Action:Command_EnableOldVersusLogic(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_enable_old_versus_logic <0|1>"); return Plugin_Handled; }	
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		EnableOldVersusLogic(client, false)		
	} else if (StrEqual(value, "1")) {
		EnableOldVersusLogic(client, true)	
	} else {
		PrintToConsole(client, "Usage: a4d_enable_old_versus_logic <0|1>")
	}
	return Plugin_Handled;
}

EnableOldVersusLogic(client, bool:value) {
	new String:command[] = "versus_boss_spawning";
	if (value == true) { 
		StripAndChangeServerConVarBool(command, false);
		LogAction(client, -1, "(%L) set %s to %i", client, command, false);
	} else { 
		StripAndChangeServerConVarBool(command, true);
		LogAction(client, -1, "(%L) set %s to %i", client, command, true);   
	}
	if (GetConVarBool(NotifyPlayers) == true) { 	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "Randomising the location of boss spawns.");
		} else {
			ShowActivity2(client, PLUGIN_TAG, "No longer randomising boss spawns.");
		}
	}
	
}

/* This toggles if we are ensuring that both teams get the same number of bosses */
/* So for example if the director spawns a tank for team 1, team 2 will get one as well */
/* We let the director place the tank where he wants */
public Action:Command_EnableIdenticalBosses(client, args) {

	if (args < 1) { PrintToConsole(client, "Usage: a4d_enable_identical_versus_bosses <0|1>"); return Plugin_Handled; }	
	
	new String:value[2]
	GetCmdArg(1, value, sizeof(value))

	if (StrEqual(value, "0")) {
		EnableIdenticalBosses(client, false)		
	} else if (StrEqual(value, "1")) {
		EnableIdenticalBosses(client, true)	
	} else {
		PrintToConsole(client, "Usage: a4d_enable_identical_versus_bosses <0|1>")
	}
	return Plugin_Handled;
}

EnableIdenticalBosses(client, bool:value) {
	SetConVarBool(IdenticalBosses, value)
	if (GetConVarBool(NotifyPlayers) == true) { 	
		if (value == true) {
			ShowActivity2(client, PLUGIN_TAG, "Now ensuring consistency in boss spawns.");
		} else {
			ShowActivity2(client, PLUGIN_TAG, "Disabling consistency for boss spawns.");
		}
	}
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_vs_ensure_identical_bosses", value);	
}

/* Menu Functions */

/* Load our categories and menus */
public OnAdminMenuReady(Handle:TopMenu) {
	/* Block us from being called twice */
	if (TopMenu == AdminMenu) { return; }
	
	AdminMenu = TopMenu;
 
	/* Add a category to the SourceMod menu called "Director Commands" */
	AddToTopMenu(AdminMenu, "All4Dead Commands", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT)
	/* Get a handle for the catagory we just added so we can add items to it */
	new TopMenuObject:afd_commands = FindTopMenuCategory(AdminMenu, "All4Dead Commands");
	
	/* Don't attempt to add items to the catagory if for some reason the catagory doesn't exist */
	if (afd_commands == INVALID_TOPMENUOBJECT) { return; }
	
	/* The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically */
	/* Assign the menus to global values so we can easily check what a menu is when it is chosen */
	//dc = AddToTopMenu(AdminMenu, "a4d_show_director_commands", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_director_commands", ADMFLAG_CHEATS);
	cc = AddToTopMenu(AdminMenu, "a4d_show_config_commands", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_config_commands", ADMFLAG_CHEATS);
	//vs = AddToTopMenu(AdminMenu, "a4d_show_versus_settings", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_versus_settings", ADMFLAG_CHEATS);
	si = AddToTopMenu(AdminMenu, "a4d_show_spawn_infected", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_spawn_infected", ADMFLAG_CHEATS);	
	sw = AddToTopMenu(AdminMenu, "a4d_show_spawn_weapons", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_spawn_weapons", ADMFLAG_CHEATS);
	sm = AddToTopMenu(AdminMenu, "a4d_show_melee_weapons", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_spawn_melee", ADMFLAG_CHEATS);
	so = AddToTopMenu(AdminMenu, "a4d_show_spawn_items", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_spawn_items", ADMFLAG_CHEATS);
	mi = AddToTopMenu(AdminMenu, "a4d_show_misc_items", TopMenuObject_Item, Menu_TopItemHandler, afd_commands, "a4d_show_misc_items", ADMFLAG_CHEATS);
}

/* This handles the top level "All4Dead" category and how it is displayed on the core admin menu */
public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "All4Dead Commands:");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "All4Dead Commands");
	}
}

/* This deals with what happens someone opens the "All4Dead" category from the menu */ 
public Menu_TopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	/* When an item is displayed to a player tell the menu to format the item */
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == dc) {
			Format(buffer, maxlength, "Director Commands");
		} else if (object_id == si) {
			Format(buffer, maxlength, "Spawn Infected");
		} else if (object_id == sw) {
			Format(buffer, maxlength, "Spawn Weapons");
		} else if (object_id == sm) {
			Format(buffer, maxlength, "Spawn Melee Weapons");
		} else if (object_id == so) {
			Format(buffer, maxlength, "Spawn Items");
		} else if (object_id == mi) {
			Format(buffer, maxlength, "Spawn Misc Items");
		} else if (object_id == cc) {
			Format(buffer, maxlength, "Configuration Commands");
		} else if (object_id == vs) {
			Format(buffer, maxlength, "Versus Settings");
		} 
	}
	
	/* When an item is selected do the following */
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == dc) {
			Menu_Director(client, false)
		} else if (object_id == si) {
			Menu_SpawnInfected(client, false)
		} else if (object_id == cc) {
			Menu_Config(client, false)
		} else if (object_id == sw) {
			Menu_SpawnWeapons(client, false)
		} else if (object_id == sm) {
			Menu_SpawnMelee(client, false)
		} else if (object_id == so) {
			Menu_SpawnItems(client, false)
		} else if (object_id == mi){
			Menu_SpawnMisc(client, false)
		} else if (object_id == vs) {
			Menu_Versus(client, false)
		}
	}
}

/* This menu deals with all the commands related to the director */
public Action:Menu_Director(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_Director)
	SetMenuTitle(menu, "Director Commands")
	
	AddMenuItem(menu, "fp", "Force a panic event to start")
	if (GetConVarBool(FindConVar("director_panic_forever"))) { AddMenuItem(menu, "pf", "End non-stop panic events"); } else { AddMenuItem(menu, "pf", "Force non-stop panic events"); }
	if (GetConVarBool(FindConVar("director_force_tank"))) { AddMenuItem(menu, "ft", "Director controls if a tank spawns this round"); } else { AddMenuItem(menu, "ft", "Force a tank to spawn this round"); }
	if (GetConVarBool(FindConVar("director_force_witch"))) { AddMenuItem(menu, "fw", "Director controls if a witch spawns this round"); } else { AddMenuItem(menu, "fw", "Force a witch to spawn this round"); }
	if (GetConVarBool(FindConVar("director_finale_infinite"))) { AddMenuItem(menu, "fi", "Allow the survivors to be rescued"); } else { AddMenuItem(menu, "fw", "Force an endless finale"); }	
	AddMenuItem(menu, "mz", "Add more zombies to the mobs")
	if (DirectorIsEnabled) { AddMenuItem(menu, "td", "Disable the director"); } else { AddMenuItem(menu, "td", "Enable the director"); }	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_Director(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				ForcePanic(cindex)
			} case 1: {
				if (GetConVarBool(FindConVar("director_panic_forever"))) { 
					PanicForever(cindex, false) 
				} else {
					PanicForever(cindex, true)
				} 
			} case 2: {
				if (GetConVarBool(FindConVar("director_force_tank"))) { 
					ForceTank(cindex, false) 
				} else {
					ForceTank(cindex, true)
				}
			} case 3: {
				if (GetConVarBool(FindConVar("director_force_witch"))) { 
					ForceWitch(cindex, false) 
				} else {
					ForceWitch(cindex, true)
				}
			} case 4: {
				if (GetConVarBool(FindConVar("director_finale_infinite"))) { 
					DelayRescue(cindex, false) 
				} else {
					DelayRescue(cindex, true)
				}
			} case 5: {
				AddZombies(cindex, GetConVarInt(FindConVar("a4d_zombies_to_add")))
			} case 6: { 
				if (DirectorIsEnabled) { 
					StopDirector(cindex) 
				} else {
					StartDirector(cindex)
				}
			}
		}
		
		Menu_Director(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}


/* This menu deals with all commands related to spawning items/creatures */
public Action:Menu_SpawnInfected(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_SpawnInfected)
	SetMenuTitle(menu, "Spawn Infected")
	AddMenuItem(menu, "st", "Spawn a tank")
	AddMenuItem(menu, "sw", "Spawn a witch")
	AddMenuItem(menu, "sb", "Spawn a boomer")
	AddMenuItem(menu, "sh", "Spawn a hunter")
	AddMenuItem(menu, "ss", "Spawn a smoker")
	AddMenuItem(menu, "sp", "Spawn a spitter")
	AddMenuItem(menu, "sj", "Spawn a jockey")
	AddMenuItem(menu, "sc", "Spawn a charger")
	AddMenuItem(menu, "sm", "Spawn a mob")
	if (GetConVarBool(AutomaticPlacement)) { AddMenuItem(menu, "ap", "Disable automatic placement"); } else { AddMenuItem(menu, "ap", "Enable automatic placement"); }
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_SpawnInfected(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnInfected(cindex, "tank")
			} case 1: {
				SpawnInfected(cindex, "witch")
			} case 2: {
				SpawnInfected(cindex, "boomer")
			} case 3: {
				SpawnInfected(cindex, "hunter")
			} case 4: {
				SpawnInfected(cindex, "smoker")
			} case 5: {
				SpawnInfected(cindex, "spitter")
			} case 6: {
				SpawnInfected(cindex, "jockey")
			} case 7: {
				SpawnInfected(cindex, "charger")
			} case 8: {
				SpawnInfected(cindex, "mob")
			} case 9: { 
				if (GetConVarBool(AutomaticPlacement)) { 
					EnableAutoPlacement(cindex, false) 
				} else {
					EnableAutoPlacement(cindex, true) 
				}
			}
		}
		
		Menu_SpawnInfected(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with spawning weapons */
public Action:Menu_SpawnWeapons(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnWeapons)
	SetMenuTitle(menu, "Spawn Weapons")
	AddMenuItem(menu, "sa", "Spawn an auto shotgun")
	AddMenuItem(menu, "sh", "Spawn a hunting rifle")
	AddMenuItem(menu, "mi", "Spawn a military sniper")
	AddMenuItem(menu, "aw", "Spawn an AWP")
	AddMenuItem(menu, "sc", "Spawn a scout")
	AddMenuItem(menu, "sp", "Spawn a pistol")	
	AddMenuItem(menu, "pm", "Spawn a magnum")
	AddMenuItem(menu, "sr", "Spawn a rifle")
	AddMenuItem(menu, "ak", "Spawn an AK-47")
	AddMenuItem(menu, "sg", "Spawn an SG-552")
	AddMenuItem(menu, "dr", "Spawn a desert rifle")
	AddMenuItem(menu, "ss", "Spawn a shotgun")
	AddMenuItem(menu, "cs", "Spawn a chrome shotgun")
	AddMenuItem(menu, "cb", "Spawn a combat shotgun")
	AddMenuItem(menu, "sm", "Spawn an SMG")
	AddMenuItem(menu, "si", "Spawn a silenced SMG")
	AddMenuItem(menu, "mp", "Spawn an MP5")
	AddMenuItem(menu, "gn", "Spawn a grenade launcher")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_SpawnWeapons(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "autoshotgun")
			} case 1: {
				SpawnItem(cindex, "hunting_rifle")
			} case 2: {
				SpawnItem(cindex, "sniper_military")
			} case 3: {
				SpawnItem(cindex, "sniper_awp")
			} case 4: {
				SpawnItem(cindex, "sniper_scout")
			} case 5: {
				SpawnItem(cindex, "pistol")
			} case 6: {
				SpawnItem(cindex, "pistol_magnum")
			} case 7: {
				SpawnItem(cindex, "rifle")
			} case 8: {
				SpawnItem(cindex, "rifle_ak47")
			} case 9: {
				SpawnItem(cindex, "rifle_sg552")
			} case 10: {
				SpawnItem(cindex, "rifle_desert")
			} case 11: {
				SpawnItem(cindex, "pumpshotgun")
			} case 12: {
				SpawnItem(cindex, "shotgun_chrome")
			} case 13: {
				SpawnItem(cindex, "shotgun_spas")
			} case 14: {
				SpawnItem(cindex, "smg")
			} case 15: {
				SpawnItem(cindex, "smg_silenced")
			} case 16: {
				SpawnItem(cindex, "smg_mp5")
			} case 17: {
				SpawnItem(cindex, "grenade_launcher")
			}
		}
		
		Menu_SpawnWeapons(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with spawning melee weapons */
public Action:Menu_SpawnMelee(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnMelee)
	SetMenuTitle(menu, "Spawn Melee Weapons")
	AddMenuItem(menu, "ba", "Spawn a baton")
	AddMenuItem(menu, "ch", "Spawn a chainsaw")
	AddMenuItem(menu, "cr", "Spawn a cricket bat")
	AddMenuItem(menu, "cb", "Spawn a crowbar")	
	AddMenuItem(menu, "gt", "Spawn an electric guitar")
	AddMenuItem(menu, "fa", "Spawn a fireaxe")
	AddMenuItem(menu, "fr", "Spawn a frying pan")
	AddMenuItem(menu, "ka", "Spawn a katana")
	AddMenuItem(menu, "ma", "Spawn a machete")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_SpawnMelee(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "tonfa")
			} case 1: {
				SpawnItem(cindex, "chainsaw")
			} case 2: {
				SpawnItem(cindex, "cricket_bat")
			} case 3: {
				SpawnItem(cindex, "crowbar")
			} case 4: {
				SpawnItem(cindex, "electric_guitar")
			} case 5: {
				SpawnItem(cindex, "fireaxe")
			} case 6: {
				SpawnItem(cindex, "frying_pan")
			} case 7: {
				SpawnItem(cindex, "katana")
			} case 8: {
				SpawnItem(cindex, "machete")
			}
			
		}
		
		Menu_SpawnMelee(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with spawning misc items */
public Action:Menu_SpawnMisc(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnMisc)
	SetMenuTitle(menu, "Spawn Misc Items")
	AddMenuItem(menu, "cb", "Spawn cola bottles")
	AddMenuItem(menu, "fw", "Spawn a fireworks crate")
	AddMenuItem(menu, "gn", "Spawn a gnome")
	AddMenuItem(menu, "ia", "Spawn an incindiary ammo pack")	
	AddMenuItem(menu, "ea", "Spawn an explosive ammo pack")
	AddMenuItem(menu, "iag", "Get incindiary ammo")
	AddMenuItem(menu, "eg", "Get explosive ammo")
	AddMenuItem(menu, "la", "Get a laser sight")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_SpawnMisc(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "cola_bottles")
			} case 1: {
				SpawnItem(cindex, "fireworkcrate")
			} case 2: {
				SpawnItem(cindex, "gnome")
			} case 3: {
				SpawnItem(cindex, "upgradepack_incendiary")
			} case 4: {
				SpawnItem(cindex, "upgradepack_explosive")
			} case 5: {
				AddUpgrade(cindex, "INCENDIARYAMMO")
			} case 6: {
				AddUpgrade(cindex, "EXPLOSIVE_AMMO")
			} case 7: {
				AddUpgrade(cindex, "LASER_SIGHT")
			}
			
		}
		
		Menu_SpawnMisc(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with spawning items */
public Action:Menu_SpawnItems(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_SpawnItems)
	SetMenuTitle(menu, "Spawn Items")
	AddMenuItem(menu, "sg", "Spawn a gas tank")
	AddMenuItem(menu, "sm", "Spawn a medkit")
	AddMenuItem(menu, "df", "Spawn a defibrillator")
	AddMenuItem(menu, "sv", "Spawn a molotov")
	AddMenuItem(menu, "sp", "Spawn some pills")
	AddMenuItem(menu, "adrl", "Spawn an adernaline shot")
	AddMenuItem(menu, "sb", "Spawn a pipe bomb")	
	AddMenuItem(menu, "vj", "Spawn a bile jar");
	AddMenuItem(menu, "st", "Spawn a propane tank")
	AddMenuItem(menu, "so", "Spawn an oxygen tank");
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_SpawnItems(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				SpawnItem(cindex, "gascan")
			} case 1: {
				SpawnItem(cindex, "first_aid_kit")
			} case 2: {
				SpawnItem(cindex, "defibrillator")
			} case 3: {
				SpawnItem(cindex, "molotov")
			} case 4: {
				SpawnItem(cindex, "pain_pills")
			} case 5: {
				SpawnItem(cindex, "adrenaline")
			} case 6: {
				SpawnItem(cindex, "pipe_bomb")
			} case 7: {
				SpawnItem(cindex, "vomitjar");
			} case 8: {
				SpawnItem(cindex, "propanetank")
			} case 9: {
				SpawnItem(cindex, "oxygentank");
			}
		}
		
		Menu_SpawnItems(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* This menu deals with all Configuration commands that don't fit into another category */
public Action:Menu_Config(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_Config)
	SetMenuTitle(menu, "Configuration Commands")
	if (GetConVarBool(NotifyPlayers)) { AddMenuItem(menu, "pn", "Disable player notifications"); } else { AddMenuItem(menu, "pn", "Enable player notifications"); }
	AddMenuItem(menu, "rs", "Restore all settings to game defaults now")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_Config(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				if (GetConVarBool(NotifyPlayers)) { 
					EnableNotifications(cindex, false) 
				} else {
					EnableNotifications(cindex, true) 
				} 
			} case 1: {
				ResetToDefaults(cindex)
			}
		}
		
		Menu_Config(cindex, false)
		
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}


/* This menu deals with game play commands */
public Action:Menu_Versus(client, args) {
	new Handle:menu = CreateMenu(MenuHandler_Versus)
	SetMenuTitle(menu, "Versus Settings")
	if (GetConVarBool(FindConVar("sb_all_bot_team"))) { AddMenuItem(menu, "bc", "Require at least one human survivor"); } else { AddMenuItem(menu, "bc", "Allow the game to start with no human survivors"); }		
	if (GetConVarBool(FindConVar("versus_boss_spawning"))) { AddMenuItem(menu, "ol", "Randomise the location of boss spawns"); } else { AddMenuItem(menu, "ol", "Disable randomising of boss spawns"); }
	if (!GetConVarBool(FindConVar("versus_boss_spawning"))) {	
		if (GetConVarBool(IdenticalBosses)) { AddMenuItem(menu, "bc", "Do not ensure consistency of boss spawns between teams"); } else { AddMenuItem(menu, "bc", "Ensure consistency of boss spawns between teams"); }	
	}	
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, client, 20)
	return Plugin_Handled
}

public MenuHandler_Versus(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				if (GetConVarBool(FindConVar("sb_all_bot_team"))) { 
					EnableAllBotTeam(cindex, false) 
				} else {
					EnableAllBotTeam(cindex, true) 
				} 
			} case 1: {
				if (GetConVarBool(FindConVar("versus_boss_spawning"))) { 
					EnableOldVersusLogic(cindex, true) 
				} else {
					EnableOldVersusLogic(cindex, false) 
				} 
			} case 2: {
				if (GetConVarBool(IdenticalBosses)) { 
					EnableIdenticalBosses(cindex, false) 
				} else {
					EnableIdenticalBosses(cindex, true) 
				} 
			}
		}

		Menu_Versus(cindex, false)

	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/* Helper Functions */
/* This function strips the cheat flags from a command, executes it and then restores it to its former glory. */

/* This isn't used yet. It seems that most commands are called from the client and StripAndExecuteClientCommand should be used instead

StripAndExecuteServerCommand(String:command[], String:arg[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand(command);
	SetCommandFlags(command, flags);
}
*/

/* Strip and change a ConVar to the value specified */
StripAndChangeServerConVarBool(String:command[], bool:value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarBool(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
}

/* Strip and change a ConVar to the value sppcified */
/* This doesn't do any maths. If you want to add 10 to an existing ConVar you need to work out the value before you call this */
StripAndChangeServerConVarInt(String:command[], value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
}

/* Does the same as the above but for client commands */
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3)
	SetCommandFlags(command, flags);
}
