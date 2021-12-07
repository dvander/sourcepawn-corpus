/* Copyright
 * Category: None
 * 
 * Revive Markers 1.7.2 by Wolvan
 * Contact: wolvan1@gmail.com
 * Big thanks to Mitchell & pheadxdll
*/

/* Includes
 * Category: Preprocessor
 *  
 * Includes the necessary SourceMod modules
 * 
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <freak_fortress_2>
#include <saxtonhale>
#include <permissionssm>
#include <updater>

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "Revive Markers"
#define PLUGIN_VERSION "1.7.2"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Drop Revive Markers on death! Let medics revive you!"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=244208"
#define PLUGIN_UPDATE_FILE "http://wolvan.mooo.com/revivemarkers/raw/bd276b0eebe76c41319fc25eb572b56c05d1afdf/ReviveMarkers/ReviveMarkers_Updater.txt"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.ReviveMarkers.cfg"
#define PLUGIN_DATA_STORAGE "ReviveMarkers"
#define PERMISSIONNODE_BASE "ReviveMarkers"

/* Variable creation
 * Category: Storage
 *  
 * Set storage arrays for the Revive Marker entities,
 * the current Team of the client and wether they are
 * changing their class after respawn, as well as the
 * Array containing all bodyGroup IDs for the holograms.
 * Another array stores the Players that are opted out.
 * 
*/
int respawnMarkers[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
int currentTeam[MAXPLAYERS+1] = {0, ... };
int reviveCount[MAXPLAYERS+1] = { 0, ... };
int maxReviveCountOverride = -1;
float decayTimeOverride = -1.0;
bool changingClass[MAXPLAYERS+1] = { false, ... };
bool isOptOut[MAXPLAYERS+1] = { false, ... };
bool isOptOutByAdmin[MAXPLAYERS+1] = { false, ... };
bool ff2installed = false;
bool vshinstalled = false;
bool permissionssm = false;
Handle decayTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
Handle kv = INVALID_HANDLE;
Handle hAdminMenu = INVALID_HANDLE;
Handle tmpTopMenuHandle = INVALID_HANDLE;
TopMenuObject obj_rmcommands;

/* ConVar Handle creation
 * Category: Storage
 * 
 * Create the Variables to store the ConVar Handles in.
 * 
*/
Handle g_noMarkersWithoutMedics = INVALID_HANDLE;
Handle g_maxReviveMarkerRevives = INVALID_HANDLE;
Handle g_disablePlugin = INVALID_HANDLE;
Handle g_adminOnly = INVALID_HANDLE;
Handle g_oneTeamOnly = INVALID_HANDLE;
Handle g_decayTime = INVALID_HANDLE;
Handle g_markerOnlySeenByMedics = INVALID_HANDLE;
Handle g_vshShowMarkers = INVALID_HANDLE;
Handle g_useOverrideString = INVALID_HANDLE;

/* Forward Handle creation
 * Category: Storage
 * 
 * Create the Handles for the Forward Calls
 * 
*/
Handle forward_markerSpawn = INVALID_HANDLE;
Handle forward_markerDecay = INVALID_HANDLE;
Handle forward_markerDespawn = INVALID_HANDLE;

/* Create plugin instance
 * Category: Plugin Instance
 *  
 * Tell SourceMod about my Plugin
 * 
*/
public Plugin myinfo = {
	name 			= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESCRIPTION,
	version 		= PLUGIN_VERSION,
	url 			= PLUGIN_URL
}

/* Check Game
 * Category: Pre-Init
 *  
 * Check if the game this Plugin is running on is TF2 or TF2beta and register natives
 * 
*/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	CreateNative("CheckMarkerConditions", Native_CheckMarkerConditions);
	CreateNative("ValidMarker", Native_ValidMarker);
	CreateNative("SpawnRMarker", Native_SpawnRMarker);
	CreateNative("DespawnRMarker", Native_DespawnRMarker);
	CreateNative("SetDecayTime", Native_SetDecayTime);
	CreateNative("SetReviveCount", Native_SetReviveCount);
	
	RegPluginLibrary("revivemarkers");
	
	return APLRes_Success;
}

/* Plugin starts
 * Category: Plugin Callback
 * 
 * Hook into the required TF2 Events, create the version ConVar
 * and go through every online Player to assign the current Team
 * and set the changing Class Variable to false. Also load the
 * translation file common.phrases, register the Console Commands
 * and create the Forward Calls
 * 
*/
public void OnPluginStart() {
	// load translations
	LoadTranslations("common.phrases");
	
	// load Data Storage
	kv = CreateKeyValues("OptState");
	char filename[256];  
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s.txt", PLUGIN_DATA_STORAGE);
	
	FileToKeyValues(kv, filename);
	
	
	// hook into the events the Plugin needs to function properly
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_changeclass", Event_OnPlayerChangeClass);
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	
	// create the version and tracking ConVar
	g_noMarkersWithoutMedics = CreateConVar("revivemarkers_no_markers_without_medic", "1", "Change if Revive Markers drop when there are no medics in the team.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_maxReviveMarkerRevives = CreateConVar("revivemarkers_max_revives", "0", "Set maximum Number of Revives. 0 to disable.", FCVAR_NOTIFY, true, 0.0);
	g_disablePlugin = CreateConVar("revivemarkers_disable", "0", "Disable Plugin Functionality", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_adminOnly = CreateConVar("revivemarkers_admin_only", "0", "Allow dropping of revive Markers only for admins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_oneTeamOnly = CreateConVar("revivemarkers_drop_for_one_team", "0", "0 - Both Teams drop Markers. 1 - Only RED. 2 - Only BLU.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_decayTime = CreateConVar("revivemarkers_decay_time", "0.0", "Set a timer that despawns the Marker before a player respawns, set to 0.0 to disable", FCVAR_NOTIFY, true, 0.0);
	g_markerOnlySeenByMedics = CreateConVar("revivemarkers_visible_for_medics", "1", "Set Visibility of Respawn Markers for everyone or Medics only", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_vshShowMarkers = CreateConVar("revivemarkers_show_markers_for_hale", "1", "Let the current Saxton Hale see the Revive Markers", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_useOverrideString = CreateConVar("revivemarkers_use_override_string", "0", "Use Permission Override Strings", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// register console commands
	RegConsoleCmd("revivemarkers_optin", optIn, "Opt yourself into dropping Revive Markers.");
	RegConsoleCmd("revivemarkers_optout", optOut, "Opt yourself out of dropping Revive Markers.");
	
	// register Global Forwards
	forward_markerDecay = CreateGlobalForward("OnReviveMarkerDecay", ET_Event, Param_Cell, Param_Cell);
	forward_markerSpawn = CreateGlobalForward("OnReviveMarkerSpawn", ET_Event, Param_Cell, Param_Cell);
	forward_markerDespawn = CreateGlobalForward("OnReviveMarkerDespawn", ET_Event, Param_Cell, Param_Cell);
	
	// load Config File
	if (FindConVar("revivemarkers_version") == INVALID_HANDLE) { AutoExecConfig(true); }
	
	CreateConVar("revivemarkers_version", PLUGIN_VERSION, "Revive Markers Version", 0|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// check if AdminMenu is already there
	Handle topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
	ff2installed = LibraryExists("freak_fortress_2");
	vshinstalled = LibraryExists("saxtonhale");
	permissionssm = LibraryExists("permissionssm");
	if (LibraryExists("updater")) { Updater_AddPlugin(PLUGIN_UPDATE_FILE); }
	
	// set optOut, class and team variables
	char steamid[256];
	char OptState[256];
	char OptAdmin[256];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			currentTeam[i] = GetClientTeam(i);
			changingClass[i] = false;
			GetClientAuthId(i, AuthId_Engine, steamid, sizeof(steamid));
			if (!KvJumpToKey(kv, steamid) || StrEqual(steamid, "BOT", false)) {
				isOptOut[i] = false;
				isOptOutByAdmin[i] = false;
			} else {
				KvGetString(kv, "OptOut", OptState, sizeof(OptState));
				KvGetString(kv, "OptOutByAdmin", OptAdmin, sizeof(OptAdmin));
				if (StrEqual(OptState, "true", false)) { isOptOut[i] = true; } else { isOptOut[i] = false; }
				if (StrEqual(OptAdmin, "true", false)) { isOptOutByAdmin[i] = true; } else { isOptOutByAdmin[i] = false; }
			}
			KvRewind(kv);
			reviveCount[i] = 0;
		}
	}
}

/* Plugin ends
 * Category: Plugin Callback
 *  
 * When the Plugin gets unloaded, remove every Revive Marker
 * from the world
 * 
*/
public void OnPluginEnd() {
	CloseHandle(kv);
	for (int i = 1; i <= MaxClients; i++) {
		despawnReviveMarker(i);
	}
	UnhookEvent("player_death", Event_OnPlayerDeath);
	UnhookEvent("player_spawn", Event_OnPlayerSpawn);
	UnhookEvent("player_changeclass", Event_OnPlayerChangeClass);
	UnhookEvent("teamplay_round_start", Event_OnRoundStart);
}

/* Client connects
 * Category: Plugin Callback
 *  
 * Load Opt Out State from File
 * 
*/
public OnClientConnected(client) {
	char steamid[256];
	char OptState[256];
	char OptAdmin[256];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	if (!KvJumpToKey(kv, steamid) || StrEqual(steamid, "BOT", false)) {
		isOptOut[client] = false;
		isOptOutByAdmin[client] = false;
	} else {
		KvGetString(kv, "OptOut", OptState, sizeof(OptState));
		KvGetString(kv, "OptOutByAdmin", OptAdmin, sizeof(OptAdmin));
		if (StrEqual(OptState, "true", false)) { isOptOut[client] = true; } else { isOptOut[client] = false; }
		if (StrEqual(OptAdmin, "true", false)) { isOptOutByAdmin[client] = true; } else { isOptOutByAdmin[client] = false; }
	}
	KvRewind(kv);
}

/* Client disconnects
 * Category: Plugin Callback
 *  
 * If a client disconnects, remove their Revive Marker if it exists
 * and reset their values in the storage arrays
 * 
*/
public void OnClientDisconnect(client) {
	// remove the marker
	despawnReviveMarker(client);
	
	// reset storage array values
	currentTeam[client] = 0;
	changingClass[client] = false;
	isOptOut[client] = false;
	isOptOutByAdmin[client] = false;
	reviveCount[client] = 0;
 }

/* Library removed
 * Category: Plugin Callback
 *  
 * This waits for libraries being removed.
 * 
*/
public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "adminmenu")) {
		hAdminMenu = INVALID_HANDLE;
	} else if (StrEqual(name, "saxtonhale")) {
		vshinstalled = false;
	} else if (StrEqual(name, "freak_fortress_2")) {
		ff2installed = false;
	} else if (StrEqual(name, "permissionssm")) {
		permissionssm = false;
	}
}

/* Library added
 * Category: Plugin Callback
 *  
 * If a int Library gets added, check if it's a VSH Plugin and enabled
 * the VSH Functions
 * 
*/
public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "saxtonhale")) {
		vshinstalled = true;
	} else if (StrEqual(name, "freak_fortress_2")) {
		ff2installed = true;
	} else if (StrEqual(name, "permissionssm")) {
		permissionssm = true;
	} else if (StrEqual(name, "updater")) {
		Updater_AddPlugin(PLUGIN_UPDATE_FILE);
	}
}

/* AdminMenu ready for hook
 * Category: Plugin Callback
 *  
 * The AdminMenu is now ready for us to hook into
 * and create our own category and fill it.
 * 
*/
public OnAdminMenuReady(Handle topmenu) {
	if(obj_rmcommands == INVALID_TOPMENUOBJECT) { OnAdminMenuCreated(topmenu); }
	if (topmenu == hAdminMenu) { return; }
	
	hAdminMenu = topmenu;
	AttachAdminMenu();
}

/* Creation of Admin Menu
 * Category: Plugin Callback
 * 
 * The AdminMenu is being created, time to add our own sub-menu
 * 
*/
public OnAdminMenuCreated(Handle topmenu) {
	if (topmenu == hAdminMenu && obj_rmcommands != INVALID_TOPMENUOBJECT) { return; }
	obj_rmcommands = AddToTopMenu(topmenu, "Revive Markers", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
}

/* Round Restart
 * Category: Event Callback
 * 
 * Resets everyone's storage to 0
 * 
*/
public Action Event_OnRoundStart(Handle event, const char[] name, bool dontbroadcast) {
	ReloadMyself();
}

/* Player Death
 * Category: Event Callback
 *  
 * Function gets run on Player Death. Calls the function to check
 * if a Revive Marker should be dropped. If so, run the function
 * that creates the respawn Marker
 * 
*/
public Action Event_OnPlayerDeath(Handle event, const char[] name, bool dontbroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int iFlags = GetEventInt(event, "death_flags");
	if(iFlags & TF_DEATHFLAG_DEADRINGER) { return; }
	if(!dropReviveMarker(client)) {
		return;
	} else {
		spawnReviveMarker(client);
	}
}

/* Player Spawning
 * Category: Event Callback
 *  
 * Function runs when a player (re)spawns. Kills of the Respawn Marker
 * if it exists and sets the current team. Also sets the class change
 * variable back. Also increase the reviveCount if the Marker was used
 * 
*/
public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontbroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	despawnReviveMarker(client);
}

/* Change Class Event
 * Category: Event Callback
 *  
 * Catches the Player Class Change Event. Sets the Class Change
 * Variable so there isn't going to be a Revive Marker being
 * dropped on death.
 * 
*/
public Action Event_OnPlayerChangeClass(Handle event, const char[] name, bool dontbroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	changingClass[client] = true;
}

/* Opt Out
 * Category: Console Command
 * 
 * Allows to opt (others) out of the Revive Marker drop
 * 
*/
public Action optOut(int client, int args) {
	if(args < 1) {
		isOptOut[client] = true;
		PrintToChat(client, "[SM] Opted out of dropping a revive Marker");
		SetOptState(client);
	} else {
		if(!hasAdminPermission(client)) {
			PrintToChat(client, "[SM] You do not have the Permission to use this command");
			return Plugin_Handled;
		}
		char arg1[128];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			if (client != 0) {
				PrintToChat(client, "[SM] No targets found. Check console for more Information");
			}
			return Plugin_Handled;
		}
	 
		for (int i = 0; i < target_count; i++) {
			isOptOut[target_list[i]] = true;
			isOptOutByAdmin[target_list[i]] = true;
			PrintToChat(target_list[i], "[SM] You have been opted out of dropping ReviveMarkers by an Admin");
			SetOptState(target_list[i]);
		}
		ReplyToCommand(client,"[SM] Opted out %i Player(s)", target_count);
	}
	return Plugin_Handled;
}

/* Opt In
 * Category: Console Command
 * 
 * Allows to opt (others) in to the Revive Marker drop
 * 
*/
public Action optIn(int client, int args) {
	if(args < 1) {
		if((!hasAdminPermission(client)) && isOptOutByAdmin[client]) {
			PrintToChat(client, "[SM] You have been opted out by an admin. You cannot opt yourself back in");
			return Plugin_Handled;
		}
		isOptOut[client] = false;
		PrintToChat(client, "[SM] Opted in to drop a Revive Marker");
		SetOptState(client);
	} else {
		if(!hasAdminPermission(client)) {
			PrintToChat(client, "[SM] You do not have the Permission to use this command");
			return Plugin_Handled;
		}
		char arg1[128];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			if (client != 0) {
				PrintToChat(client, "[SM] No targets found. Check console for more Information");
			}
			return Plugin_Handled;
		}
	 
		for (int i = 0; i < target_count; i++) {
			isOptOut[target_list[i]] = false;
			isOptOutByAdmin[target_list[i]] = false;
			PrintToChat(target_list[i], "[SM] You have been opted in to dropping ReviveMarkers by an Admin");
			SetOptState(target_list[i]);
		}
		ReplyToCommand(client,"[SM] Opted in %i Player(s)", target_count);
	}
	return Plugin_Handled;
}

/* Delay Timer Callback
 * Category: Timer Callback
 * 
 * This function is merely there to work around the instant respawn bug
 * by not placing it at the death position asap.
 * 
*/
public Action Timer_TransmitMarker(Handle timer, any userid) {
	int client = GetClientOfUserId(userid);
	if(!IsValidMarker(respawnMarkers[client]) || !IsClientInGame(client)) {
		return;
	}
	// get position to teleport the Marker to
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(respawnMarkers[client], position, NULL_VECTOR, NULL_VECTOR);
	SDKHook(respawnMarkers[client], SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(respawnMarkers[client], SDKHook_SetTransmit, Hook_DelayTransmit);
}

/* Decay Timer Callback
 * Category: Timer Callback
 * 
 * This Function gets called when a timer is started that makes the
 * Revive Marker decay before a player respawned
 * 
*/
public Action Timer_DecayMarker(Handle timer, any userid) {
	
	int client = GetClientOfUserId(userid);
	
	if(!IsValidMarker(respawnMarkers[client]) || !IsClientInGame(client)) {
		return;
	}
	
	// call Forward
	Action result = Plugin_Continue;
	Call_StartForward(forward_markerDecay);
	Call_PushCell(client);
	Call_PushCell(respawnMarkers[client]);
	Call_Finish(result);
	
	if (result == Plugin_Handled || result == Plugin_Stop) {
		return;
	}
	
	despawnReviveMarker(client);
	if(decayTimers[client] != INVALID_HANDLE) {
		KillTimer(decayTimers[client]);
		decayTimers[client] = INVALID_HANDLE;
	}
}

/* SetTransmit
 * Category: SDKHook Action
 * 
 * Blocks all clients except friendly medics from seeing
 * the revive bubbles
 * 
*/
public Action Hook_SetTransmit(reviveMarker, client) {
	if(VSHEnabled()) {
		if(GetConVarBool(g_vshShowMarkers)) {
			if (vshinstalled) {
				if (GetClientOfUserId(VSH_GetSaxtonHaleUserId()) == client) {
					return Plugin_Continue;
				}
			} else if (ff2installed) {
				if (FF2_GetBossIndex(client) != -1) {
					return Plugin_Continue;
				}
			}
		}
	}
	if(GetEntProp(reviveMarker, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) {
		if(GetConVarBool(g_markerOnlySeenByMedics)) {
			if(TF2_GetPlayerClass(client) == TFClass_Medic) {
				return Plugin_Continue;
			} else {
				return Plugin_Handled;
			}
		} else {
			return Plugin_Continue;
		}
	}
	return Plugin_Handled;
}

/* Delay SetTransmit
 * Category: SDKHook Action
 * 
 * Blocks all clients from seeing the markers and
 * revive bubbles for a few seconds. This is part
 * of my instant revive bug fix
 * 
*/
public Action Hook_DelayTransmit(reviveMarker, client) {
	return Plugin_Handled;
}

/* Drop condition check
 * Category: Self-defined Function
 *  
 * Checks all conditions necessary to determine if a Revive Marker
 * should be dropped for the client in question.
 * 
*/
public bool dropReviveMarker(client) {
	// check if Plugin is enabled
	if (GetConVarBool(g_disablePlugin)) {
		//PrintToServer("Plugin disabled");
		return false;
	}
	
	// check if Admin Only mode is enabled
	if (GetConVarBool(g_adminOnly) && !hasAdminPermission(client)) {
		//PrintToServer("Admin only mode");
		return false;
	}
	
	// check if Permissions are given
	if (permissionssm) {
		if (!PsmHasPermission(client, "%s.DropMarker", PERMISSIONNODE_BASE)) {
			//PrintToServer("User doesn't have PSM Permission");
			return false;
		}
	} else if (GetConVarBool(g_useOverrideString)) {
		if (!CheckCommandAccess(client, "revivemarkers_dropmarker", ADMFLAG_GENERIC, true) && !CheckCommandAccess(client, "revivemarkers_admin", ADMFLAG_GENERIC, true)) {
			//PrintToServer("User doesn't have Permission");
			return false;
		}
	}
	
	// check if only one team is allowed and Player is part of it
	int clientTeam = GetClientTeam(client);
	if (((GetConVarInt(g_oneTeamOnly) == 1) && (clientTeam != _:TFTeam_Red)) || ((GetConVarInt(g_oneTeamOnly) == 2) && (clientTeam != _:TFTeam_Blue))) {
		//PrintToServer("Team blocked");
		return false;
	}
	
	// check if death results from changing teams
	if(currentTeam[client] != clientTeam && !IsFakeClient(client)) {
		//PrintToServer("Team changed %i/%i", currentTeam[client], clientTeam);
		return false;
	}
	
	// check if death results from a class change
	if(changingClass[client]) {
		//PrintToServer("Class changed");
		changingClass[client] = false;
		return false;
	}
	
	// check if there already is a marker of that player in world
	if (respawnMarkers[client] != INVALID_ENT_REFERENCE) {
		//PrintToServer("Another Marker exists");
		return false;
	}
	
	// check if the player opted out
	if (isOptOut[client]) {
		//PrintToServer("You are opted out");
		return false;
	}
	
	// check if a Marker should be dropped if no Medics are in the team
	if (GetConVarBool(g_noMarkersWithoutMedics) && !teamHasMedic(clientTeam)) {
		//PrintToServer("No medics in your team");
		return false;
	}
	
	// check if revives are exceeded
	if ((maxReviveCountOverride > -1) && (reviveCount[client] > maxReviveCountOverride - 1)) {
		//PrintToServer("Revives exceeded");
		return false;
	} else if ((GetConVarInt(g_maxReviveMarkerRevives) > 0) && (reviveCount[client] > GetConVarInt(g_maxReviveMarkerRevives) - 1)) {
		//PrintToServer("Revives exceeded");
		return false;
	}
	
	// if non of the checks were true, allow a marker to be dropped
	return true;
}

/* Marker Spawn
 * Category: Self-defined Function
 *  
 * Spawns the Revive Marker and places it to where the player died.
 * 
*/
public bool spawnReviveMarker(client) {
	// spawn the Revive Marker
	int clientTeam = GetClientTeam(client);
	int reviveMarker = CreateEntityByName("entity_revive_marker");
	
	if (reviveMarker != -1) {
		SetEntPropEnt(reviveMarker, Prop_Send, "m_hOwner", client); // client index 
		SetEntProp(reviveMarker, Prop_Send, "m_nSolidType", 2); 
		SetEntProp(reviveMarker, Prop_Send, "m_usSolidFlags", 8); 
		SetEntProp(reviveMarker, Prop_Send, "m_fEffects", 16); 
		SetEntProp(reviveMarker, Prop_Send, "m_iTeamNum", clientTeam); // client team 
		SetEntProp(reviveMarker, Prop_Send, "m_CollisionGroup", 1); 
		SetEntProp(reviveMarker, Prop_Send, "m_bSimulatedEveryTick", 1);
		SetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, reviveMarker);
		SetEntProp(reviveMarker, Prop_Send, "m_nBody", _:TF2_GetPlayerClass(client) - 1); // character hologram that is shown
		SetEntProp(reviveMarker, Prop_Send, "m_nSequence", 1); 
		SetEntPropFloat(reviveMarker, Prop_Send, "m_flPlaybackRate", 1.0);
		SetEntProp(reviveMarker, Prop_Data, "m_iInitialTeamNum", clientTeam);
		SDKHook(reviveMarker, SDKHook_SetTransmit, Hook_DelayTransmit);
		if(GetClientTeam(client) == 3) {
			SetEntityRenderColor(reviveMarker, 0, 0, 255); // make the BLU Revive Marker distinguishable from the red one
		} else {
			SetEntityRenderColor(reviveMarker, 255, 0, 0); // change the RED Revive Marker to be more red, just for good measure
		}
		// call Forward
		Action result = Plugin_Continue;
		Call_StartForward(forward_markerSpawn);
		Call_PushCell(client);
		Call_PushCell(reviveMarker);
		Call_Finish(result);
		
		if (result == Plugin_Handled) {
			return false;
		} else if (result == Plugin_Stop) {
			AcceptEntityInput(reviveMarker, "Kill");
			return false;
		}
		DispatchSpawn(reviveMarker);
		respawnMarkers[client] = EntIndexToEntRef(reviveMarker);
		if ((GetConVarFloat(g_decayTime) >= 0.1 || decayTimeOverride >= 0.0) && (decayTimers[client] == INVALID_HANDLE)) {
			if (decayTimeOverride >= 0.0) {
				decayTimers[client] = CreateTimer(decayTimeOverride + 0.1, Timer_DecayMarker, GetClientUserId(client));
			} else {
				decayTimers[client] = CreateTimer(GetConVarFloat(g_decayTime) + 0.1, Timer_DecayMarker, GetClientUserId(client));
			}
		}
		CreateTimer(0.1, Timer_TransmitMarker, GetClientUserId(client));
		return true;
	} else {
		return false;
	}
}

/* Marker Despawn
 * Category: Self-defined Function
 *  
 * Despawns the Revive Marker and kills the attached Decay Timer.
 * 
*/
public bool despawnReviveMarker(client) {
	// call Forward
	Action result = Plugin_Continue;
	Call_StartForward(forward_markerDespawn);
	Call_PushCell(client);
	Call_PushCell(respawnMarkers[client]);
	Call_Finish(result);
	
	if (result == Plugin_Handled || result == Plugin_Stop) {
		return false;
	}
	
	if(!IsClientInGame(client)) {
		return false;
	}
	
	// set team and class change variable
	currentTeam[client] = GetClientTeam(client);
	changingClass[client] = false;
	
	
	// kill Revive Marker if it exists
	if (IsValidMarker(respawnMarkers[client])) {
		if(GetEntProp(respawnMarkers[client],Prop_Send,"m_iHealth") >= GetEntProp(respawnMarkers[client],Prop_Send,"m_iMaxHealth")) {
			reviveCount[client]++;
		}
		AcceptEntityInput(respawnMarkers[client], "Kill");
		respawnMarkers[client] = INVALID_ENT_REFERENCE;
	} else {
		return false;
	}
	
	// kill Decay Timer when it exists
	if (decayTimers[client] != INVALID_HANDLE) {
		KillTimer(decayTimers[client]);
		decayTimers[client] = INVALID_HANDLE;
	}
	return true;
}

/* Write Opt State
 * Category: Self-defined function
 * 
 * Write current Opt Out State to file to load it later
 * 
*/
public SetOptState(client) {
	char filename[256];  
	BuildPath(Path_SM, filename, sizeof(filename), "gamedata/%s.txt", PLUGIN_DATA_STORAGE);
	
	char AuthString[512];
	GetClientAuthId(client, AuthId_Engine, AuthString, sizeof(AuthString));
	
	KvJumpToKey(kv, AuthString, true);
	
	char OptState[] = "false";
	char OptAdmin[] = "false";
	
	if (isOptOut[client]) { Format(OptState, sizeof(OptState), "true"); } else { Format(OptState, sizeof(OptState), "false"); }
	if (isOptOutByAdmin[client]) { Format(OptAdmin, sizeof(OptAdmin), "true"); } else { Format(OptAdmin, sizeof(OptAdmin), "false"); }
	
	KvSetString(kv, "OptOut", OptState);
	KvSetString(kv, "OptOutByAdmin", OptAdmin);
	KvRewind(kv);
	KeyValuesToFile(kv, filename);
}

/* Medic Check
 * Category: Self-defined function
 * 
 * Check if there is a medic in the team
 * 
*/
public bool teamHasMedic(team) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			if ((GetClientTeam(i) == team) && (TF2_GetPlayerClass(i) == TFClass_Medic)) {
				return true;
			}
		}
	}
	return false;
}

/* Check Admin Permission
 * Category: Self-defined function
 * 
 * Checks if the client has Admin Permissions
 * 
*/
public bool hasAdminPermission(client) {
	if (permissionssm) { return PsmHasPermission(client, "%s.Admin", PERMISSIONNODE_BASE); }
	return CheckCommandAccess(client, "revivemarkers_admin", ADMFLAG_GENERIC, true);
}

/* Validate Marker
 * Category: Self-defined function
 * 
 * Validates a Marker entity
 * 
*/
public bool IsValidMarker(marker) {
	if (IsValidEntity(marker)) {
		char buffer[128];
		GetEntityClassname(marker, buffer, sizeof(buffer));
		if (strcmp(buffer,"entity_revive_marker",false) == 0) {
			return true;
		}
	}
	return false;
}

/* Plugin reload
 * Category: Self-defined function
 * 
 * A simple funtion that reloads this Plugin whenever
 * the function is called
 * 
*/
public ReloadMyself() {
	char filename[256];
	GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}

/* VSHMode Check
 * Category: Self-defined function
 * 
 * Checks if either FF2 or VSH is installed and enabled to
 * make the Markers visible for Saxton Hale
 * 
*/
public bool VSHEnabled() {
	
	if (vshinstalled) {
		if (VSH_IsSaxtonHaleModeEnabled()) {
			if (VSH_GetSaxtonHaleUserId() != -1) {
				return true;
			}
		}
	} else if (ff2installed) {
		if (FF2_IsFF2Enabled()) {	
			if (FF2_GetBossUserId() != -1) {
				return true;
			}
		}
	}
	
	return false;
}

/* Category Display Text
 * Category: Self-defined function
 * 
 * This function returns the correct text for the admin menu
 * to show in both the main menu and the ReviveMarkers Submenu
 * 
*/
public void CategoryHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayTitle) { Format(buffer, maxlength, "Revive Markers:"); }
	else if (action == TopMenuAction_DisplayOption) {	Format(buffer, maxlength, "Revive Markers"); }
}

/* Fill Sub-Menu
 * Category: Self-defined function
 * 
 * Fills the Revive Markers Sub-Menu with the respective entries 
 * 
*/
public AttachAdminMenu() {
	TopMenuObject player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
 
	if (player_commands == INVALID_TOPMENUOBJECT) { return; }
 
	AddToTopMenu(hAdminMenu, "revivemarkers_no_markers_without_medic", TopMenuObject_Item, AdminMenu_NoMarkersWithoutMedic, obj_rmcommands, "revivemarkers_no_markers_without_medic", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_max_revives", TopMenuObject_Item, AdminMenu_MaxRevives, obj_rmcommands, "revivemarkers_max_revives", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_disable", TopMenuObject_Item, AdminMenu_Disable, obj_rmcommands, "revivemarkers_disable", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_admin_only", TopMenuObject_Item, AdminMenu_AdminOnly, obj_rmcommands, "revivemarkers_admin_only", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_drop_for_one_team", TopMenuObject_Item, AdminMenu_DropForOneTeam, obj_rmcommands, "revivemarkers_drop_for_one_team", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_decay_time", TopMenuObject_Item, AdminMenu_DecayTime, obj_rmcommands, "revivemarkers_decay_time", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_visible_for_medics", TopMenuObject_Item, AdminMenu_VisibleForMedics, obj_rmcommands, "revivemarkers_visible_for_medics", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_optout", TopMenuObject_Item, AdminMenu_OptOut, obj_rmcommands, "revivemarkers_optout", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_optin", TopMenuObject_Item, AdminMenu_OptIn, obj_rmcommands, "revivemarkers_optin", ADMFLAG_SLAY);
	AddToTopMenu(hAdminMenu, "revivemarkers_use_override_string", TopMenuObject_Item, AdminMenu_OverrideString, obj_rmcommands, "revivemarkers_use_override_string", ADMFLAG_SLAY);
	if (VSHEnabled()) { AddToTopMenu(hAdminMenu, "revivemarkers_show_markers_for_hale", TopMenuObject_Item, AdminMenu_SaxtonHaleSeesItAll, obj_rmcommands, "revivemarkers_show_markers_for_hale", ADMFLAG_SLAY); }
}

/* Set Decay Time
 * Category: Native Function
 * 
 * Set the Decay Time Override
 * 
*/
public Native_SetDecayTime(Handle plugin, numParams) {
	float time = view_as<float>(GetNativeCell(1));
	if (time < -1.0) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Decay Time Override cannot be less than -1.");
	}
	decayTimeOverride = time;
	return _:true;
}

/* Set Revive Count
 * Category: Native Proxy
 * 
 * Sets the Max Revive Count Override
 * 
*/
public Native_SetReviveCount(Handle plugin, numParams) {
	int maxCount = GetNativeCell(1);
	if (maxCount < -1) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Max Revive Count Override cannot be less than -1.");
	}
	maxReviveCountOverride = maxCount;
	return _:true;
}

/* Drop condition check Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public Native_CheckMarkerConditions(Handle plugin, numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return _:dropReviveMarker(client);
}

/* Validate Marker Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public Native_ValidMarker(Handle plugin, numParams) {
	int entity = GetNativeCell(1);
	return _:IsValidMarker(entity);
}

/* Marker Spawn Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public Native_SpawnRMarker(Handle plugin, numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return _:spawnReviveMarker(client);
}

/* Marker Despawn Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public Native_DespawnRMarker(Handle plugin, numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return _:despawnReviveMarker(client);
}

/* Updater finished
 * Category: Updater Callback
 * 
 * Reload ReviveMarkers once Updater finished it's task
 * 
*/
public Updater_OnPluginUpdated() {
	ReloadMyself();
}

/* No Markers without Medics
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public AdminMenu_NoMarkersWithoutMedic(Handle topmenu, TopMenuAction action, TopMenuObject object_id, param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Markers drop without medics");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_NoMarkersWithoutMedic(param,topmenu);
	}
}
DisplayMenu_NoMarkersWithoutMedic(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_NoMarkersWithoutMedic);
	SetMenuTitle(menu, "Will Markers drop without medics?");
	AddMenuItem(menu, "0", "Yes");
	AddMenuItem(menu, "1", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_NoMarkersWithoutMedic(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_noMarkersWithoutMedics, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Max Revives
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_MaxRevives(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Max number of revives");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_MaxRevives(param,topmenu);
	}
}
DisplayMenu_MaxRevives(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_MaxRevives);
	SetMenuTitle(menu, "Max number of revives per round:");
	AddMenuItem(menu, "0", "Disable");
	AddMenuItem(menu, "1", "1");
	AddMenuItem(menu, "2", "2");
	AddMenuItem(menu, "3", "3");
	AddMenuItem(menu, "4", "4");
	AddMenuItem(menu, "5", "5");
	AddMenuItem(menu, "10", "10");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_MaxRevives(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_maxReviveMarkerRevives, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Disable Plugin
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_Disable(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Plugin enabled");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_Disable(param,topmenu);
	}
}
DisplayMenu_Disable(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_Disable);
	SetMenuTitle(menu, "Is plugin enabled?");
	AddMenuItem(menu, "0", "Yes");
	AddMenuItem(menu, "1", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_Disable(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_disablePlugin, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Admin-Only Mode
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_AdminOnly(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Admin-Only Mode");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_AdminOnly(param,topmenu);
	}
}
DisplayMenu_AdminOnly(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_AdminOnly);
	SetMenuTitle(menu, "Admin-Only Usage:");
	AddMenuItem(menu, "0", "No");
	AddMenuItem(menu, "1", "Yes");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_AdminOnly(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_adminOnly, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Drop for one team only
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_DropForOneTeam(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Drop for one team only");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DropForOneTeam(param,topmenu);
	}
}
DisplayMenu_DropForOneTeam(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_DropForOneTeam);
	SetMenuTitle(menu, "Drop for which team?");
	AddMenuItem(menu, "0", "Both");
	AddMenuItem(menu, "1", "RED");
	AddMenuItem(menu, "2", "BLU");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DropForOneTeam(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_oneTeamOnly, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Marker decay time
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_DecayTime(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Marker decay time");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_DecayTime(param,topmenu);
	}
}
DisplayMenu_DecayTime(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_DecayTime);
	SetMenuTitle(menu, "How long before the Marker despawns?");
	AddMenuItem(menu, "10.0", "10 seconds");
	AddMenuItem(menu, "11.0", "11 seconds");
	AddMenuItem(menu, "12.0", "12 seconds");
	AddMenuItem(menu, "13.0", "13 seconds");
	AddMenuItem(menu, "14.0", "14 seconds");
	AddMenuItem(menu, "15.0", "15 seconds");
	AddMenuItem(menu, "20.0", "20 seconds");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_DecayTime(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarFloat(g_decayTime, StringToFloat(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Only medics can see Markers
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_VisibleForMedics(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Markers only visible for medics");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_VisibleForMedics(param,topmenu);
	}
}
DisplayMenu_VisibleForMedics(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_VisibleForMedics);
	SetMenuTitle(menu, "Who can see Markers?");
	AddMenuItem(menu, "0", "Everyone");
	AddMenuItem(menu, "1", "Only Medics");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_VisibleForMedics(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_markerOnlySeenByMedics, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Markers visible for Saxton Hale
 * Category: AdminMenu Item
 * 
 * Creates a Menu Item for the ReviveMarkers Sub-Menu
 * 
*/
public void AdminMenu_SaxtonHaleSeesItAll(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Saxton Hale can see Markers");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_SaxtonHaleSeesItAll(param,topmenu);
	}
}
DisplayMenu_SaxtonHaleSeesItAll(client, Handle topmenu) {
	tmpTopMenuHandle = topmenu;
	Handle menu = CreateMenu(MenuHandler_SaxtonHaleSeesItAll);
	SetMenuTitle(menu, "Show Markers to current Boss");
	AddMenuItem(menu, "1", "Yes");
	AddMenuItem(menu, "0", "No");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_SaxtonHaleSeesItAll(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_vshShowMarkers, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}

/* Opt Out Admin-Menu
 * Category: AdminMenu Item
 * 
 * Opt Other Players out
 * 
*/
public void AdminMenu_OptOut(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Opt Out");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_OptOut(param);
	}
}
DisplayMenu_OptOut(client) {
	Handle menu = CreateMenu(MenuHandler_OptOut);
	SetMenuTitle(menu, "Opt Players out");
	
	AddMenuItem(menu, "@all", "Everyone");
	AddMenuItem(menu, "@bots", "Bots");
	AddMenuItem(menu, "@alive", "Alive Players");
	AddMenuItem(menu, "@dead", "Dead Players");
	AddMenuItem(menu, "@humans", "Non-Bots (Humans)");
	AddMenuItem(menu, "@aim", "Aim");
	AddMenuItem(menu, "@me", "Me");
	AddMenuItem(menu, "@!me", "Everyone but me");
	AddMenuItem(menu, "@red", "Red Team Members");
	AddMenuItem(menu, "@blue", "Blue Team Members");
	
	char nameBuffer[128];
	for (int i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {			
			GetClientName(i, nameBuffer, sizeof(nameBuffer));
			AddMenuItem(menu, nameBuffer, nameBuffer);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_OptOut(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "revivemarkers_optout %s", info);
		RedisplayAdminMenu(menu, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

/* Opt In Admin-Menu
 * Category: AdminMenu Item
 * 
 * Opt Other Players in
 * 
*/
public int AdminMenu_OptIn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Opt In");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_OptIn(param);
	}
}
void DisplayMenu_OptIn(int client) {
	Handle menu = CreateMenu(MenuHandler_OptIn);
	SetMenuTitle(menu, "Opt Players in");
	
	AddMenuItem(menu, "@all", "Everyone");
	AddMenuItem(menu, "@bots", "Bots");
	AddMenuItem(menu, "@alive", "Alive Players");
	AddMenuItem(menu, "@dead", "Dead Players");
	AddMenuItem(menu, "@humans", "Non-Bots (Humans)");
	AddMenuItem(menu, "@aim", "Aim");
	AddMenuItem(menu, "@me", "Me");
	AddMenuItem(menu, "@!me", "Everyone but me");
	AddMenuItem(menu, "@red", "Red Team Members");
	AddMenuItem(menu, "@blue", "Blue Team Members");
	
	char nameBuffer[128];
	for (int i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {			
			GetClientName(i, nameBuffer, sizeof(nameBuffer));
			AddMenuItem(menu, nameBuffer, nameBuffer);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_OptIn(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, "revivemarkers_optin %s", info);
		RedisplayAdminMenu(menu, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

/* Override Strings Admin-Menu
 * Category: AdminMenu Item
 * 
 * Change Override Strings
 * 
*/
public void AdminMenu_OverrideString(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "Override Strings");
	} else if (action == TopMenuAction_SelectOption) {
		DisplayMenu_OverrideString(param);
	}
}
DisplayMenu_OverrideString(client) {
	Handle menu = CreateMenu(MenuHandler_OverrideString);
	SetMenuTitle(menu, "Activate Override String?");
	
	AddMenuItem(menu, "1", "Yes");
	AddMenuItem(menu, "0", "No");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public MenuHandler_OverrideString(Handle menu, MenuAction action, param1, param2) {
	if (action == MenuAction_Select) {
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		SetConVarInt(g_useOverrideString, StringToInt(info));
		RedisplayAdminMenu(tmpTopMenuHandle, param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
		if(tmpTopMenuHandle != INVALID_HANDLE) {
			CloseHandle(tmpTopMenuHandle);
			tmpTopMenuHandle = INVALID_HANDLE;
		}
	}
}