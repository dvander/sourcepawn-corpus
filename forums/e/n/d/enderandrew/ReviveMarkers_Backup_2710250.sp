/* Copyright
 * Category: None
 * 
 * Revive Markers 1.4.2 by Wolvan
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

#include <sdkhooks>
#include <tf2_stocks>

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "Revive Markers"
#define PLUGIN_VERSION "1.4.2"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Drop Revive Markers on death! Let medics revive you!"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=244208"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.revivemarkers.cfg"

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
bool changingClass[MAXPLAYERS+1] = { false, ... };
bool isOptOut[MAXPLAYERS+1] = { false, ... };
bool isOptOutByAdmin[MAXPLAYERS+1] = { false, ... };
Handle decayTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
int reviveCount[MAXPLAYERS+1] = { 0, ... };

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
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta"))
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	CreateNative("CheckMarkerConditions", Native_CheckMarkerConditions);
	CreateNative("ValidMarker", Native_ValidMarker);
	CreateNative("SpawnRMarker", Native_SpawnRMarker);
	CreateNative("DespawnRMarker", Native_DespawnRMarker);
	
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
	
	// hook into the events the Plugin needs to function properly
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_changeclass", Event_OnPlayerChangeClass);
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	
	// create the version and tracking ConVar
	CreateConVar("revivemarkers_version", PLUGIN_VERSION, "Revive Markers Version", 0|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_noMarkersWithoutMedics = CreateConVar("revivemarkers_no_markers_without_medic", "1", "Change if Revive Markers drop when there are no medics in the team.", FCVAR_NOTIFY);
	g_maxReviveMarkerRevives = CreateConVar("revivemarkers_max_revives", "0", "Set maximum Number of Revives. 0 to disable.", FCVAR_NOTIFY);
	g_disablePlugin = CreateConVar("revivemarkers_disable", "0", "Disable Plugin Functionality", FCVAR_NOTIFY);
	g_adminOnly = CreateConVar("revivemarkers_admin_only", "0", "Allow dropping of revive Markers only for admins", FCVAR_NOTIFY);
	g_oneTeamOnly = CreateConVar("revivemarkers_drop_for_one_team", "0", "0 - Both Teams drop Markers. 1 - Only RED. 2 - Only BLU.", FCVAR_NOTIFY);
	g_decayTime = CreateConVar("revivemarkers_decay_time", "0.0", "Set a timer that despawns the Marker before a player respawns, set to 0.0 to disable", FCVAR_NOTIFY);
	g_markerOnlySeenByMedics = CreateConVar("revivemarkers_visible_for_medics", "1", "Set Visibility of Respawn Markers for everyone or Medics only", FCVAR_NOTIFY);
	
	// register console commands
	RegConsoleCmd("revivemarkers_optin", optIn, "Opt yourself into dropping Revive Markers.");
	RegConsoleCmd("revivemarkers_optout", optOut, "Opt yourself out of dropping Revive Markers.");
	
	// register Global Forwards
	forward_markerDecay = CreateGlobalForward("OnReviveMarkerDecay", ET_Event, Param_Cell, Param_Cell);
	forward_markerSpawn = CreateGlobalForward("OnReviveMarkerSpawn", ET_Event, Param_Cell, Param_Cell);
	forward_markerDespawn = CreateGlobalForward("OnReviveMarkerDespawn", ET_Event, Param_Cell, Param_Cell);
	
	// load Config File
	if (FileExists(PLUGIN_CONFIG)) {
		Config_Load();
	} else {
		Config_Create();
	}
	
	// set optOut, class and team variables
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			currentTeam[i] = GetClientTeam(i);
			changingClass[i] = false;
			isOptOut[i] = false;
			isOptOutByAdmin[i] = false;
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
	for (int i = 1; i <= MaxClients; i++) {
		despawnReviveMarker(i);
	}
}

/* Client disconnects
 * Category: Plugin Callback
 *  
 * If a client disconnects, remove their Revive Marker if it exists
 * and reset their values in the storage arrays
 * 
*/
 public void OnClientDisconnect(int client) {
	// remove the marker
	despawnReviveMarker(client);
	
	// reset storage array values
	currentTeam[client] = 0;
	changingClass[client] = false;
	isOptOut[client] = false;
	isOptOutByAdmin[client] = false;
	reviveCount[client] = 0;
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
	isOptOut[client] = true;
	PrintToChat(client, "Opted out of dropping a revive Marker");
	return Plugin_Handled;
}

/* Opt In
 * Category: Console Command
 * 
 * Allows to opt (others) in to the Revive Marker drop
 * 
*/
public Action optIn(int client, int args) {
	if((GetUserAdmin(client) == INVALID_ADMIN_ID) && isOptOutByAdmin[client]) {
		PrintToChat(client, "You have been opted out by an admin. You cannot opt yourself back in");
		return Plugin_Handled;
	}
	isOptOut[client] = false;
	PrintToChat(client, "Opted in to drop a revive Marker");
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
public Action Hook_SetTransmit(int reviveMarker, int client) {
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

public Action Hook_DelayTransmit(int reviveMarker, int client) {
	return Plugin_Handled;
}

/* Drop condition check
 * Category: Self-defined Function
 *  
 * Checks all conditions necessary to determine if a Revive Marker
 * should be dropped for the client in question.
 * 
*/
public bool dropReviveMarker(int client) {
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
	
	// check if only one team is allowed and Player is part of it
	int clientTeam = GetClientTeam(client);
	if (((GetConVarInt(g_oneTeamOnly) == 1) && (clientTeam != view_as<int>(TFTeam_Red))) || ((GetConVarInt(g_oneTeamOnly) == 2) && (clientTeam != view_as<int>(TFTeam_Blue)))) {
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
	if ((GetConVarInt(g_maxReviveMarkerRevives) > 0) && (reviveCount[client] > GetConVarInt(g_maxReviveMarkerRevives) - 1)) {
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
public bool spawnReviveMarker(int client) {
	
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
		SetEntProp(reviveMarker, Prop_Send, "m_nBody", view_as<int>(TF2_GetPlayerClass(client)) - 1); // character hologram that is shown
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
		if ((GetConVarFloat(g_decayTime) >= 0.1) && (decayTimers[client] == INVALID_HANDLE)) {
			decayTimers[client] = CreateTimer(GetConVarFloat(g_decayTime), Timer_DecayMarker, GetClientUserId(client));
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
public bool despawnReviveMarker(int client) {
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

/* Medic Check
 * Category: Self-defined function
 * 
 * Check if there is a medic in the team
 * 
*/
public bool teamHasMedic(int team) {
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
 * Checks if the client has Admin Permissions, currently not
 * implemented, the reason why it returns true for now
 * 
*/
public bool hasAdminPermission(int client) {
	return CheckCommandAccess(client, "revivemarkers_admin", ADMFLAG_GENERIC);
}

/* Validate Marker
 * Category: Self-defined function
 * 
 * Validates a Marker entity
 * 
*/
public bool IsValidMarker(int marker) {
	if (IsValidEntity(marker)) {
		char buffer[128];
		GetEntityClassname(marker, buffer, sizeof(buffer));
		if (strcmp(buffer,"entity_revive_marker",false) == 0) {
			return true;
		}
	}
	return false;
}

public void ReloadMyself() {
	char filename[256];
	GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}

/* Drop condition check Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public int Native_CheckMarkerConditions(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return view_as<int>(dropReviveMarker(client));
}

/* Validate Marker Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public int Native_ValidMarker(Handle plugin, int numParams) {
	int entity = GetNativeCell(1);
	return view_as<int>(IsValidMarker(entity));
}

/* Marker Spawn Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public int Native_SpawnRMarker(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return view_as<int>(spawnReviveMarker(client));
}

/* Marker Despawn Proxy
 * Category: Native Proxy
 * 
 * Serves as proxy between native and function
 * 
*/
public int Native_DespawnRMarker(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return view_as<int>(despawnReviveMarker(client));
}

public void Config_Load() {
	AutoExecConfig(false);
	
}

public void Config_Create() {
	
}