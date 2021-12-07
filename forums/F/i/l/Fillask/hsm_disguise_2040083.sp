/*
 * Hidden:SourceMod - Visibility
 *
 * Description:
 *   Allows the hidden to disguise himself while holding a button
 *
 * Cvars:
 *  hsm_vis         [bool]   Enables or disables visibility toggling. 0: Disable, 1: Enable. Default: 1
 *  hsm_vis_mintime [number] Minimum number of seconds the hidden must be visible for. 0.1 ~ 2.0. Default: 0.2
 *  hsm_vis_model   [string] Model to use as visible hidden. Default: models/player/iris.mdl
 *
 * Commands:
 *  +disguise: Makes you visible
 *  -disguise: Makes you invisible
 *
 * Changelog:
 *  v1.2.4
 *   Fixed forced invisibility running on players who aren't even visible at round end.
 *   Fixed being able to go visible right as new round starts, resulting in a bad-model kick.
 *  v1.2.3
 *   Fixed some for loops through clients not reaching MaxClients thus ignore the last connected player.
 *  v1.2.2
 *   Fixed model exchange bounding boxes expanding below floor level sometimes intersecting with trigger_hurt on hdn_discovery
 *   Added +/-visible command descriptions
 *   Increased minimum visible time to 0.1 seconds to prevent visibile lock
 *  v1.2.1
 *   Fixed random crashing.
 *   Fixed round-end timer mis-firing on hdn_restartround
 *  v1.2.0
 *   Simplified model replacement code
 *   Added convar to define custom visible model.
 *   Added automatic invisibility if damage taken.
 *   Fixed crash on player death
 *   Fixed overlay being stuck on after you die or switch team.
 *  v1.0.1
 *   Remove global sound
 *   Added audio/visual cue to hidden when visible
 *   Added server log output when player toggles visibility
 *   Added dedicated commands for going visible and invisible.
 *  v1.0.0
 *   Initial release. No stamina boosting just yet.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 * 
 * Credits:
 *  Original idea: Alt (http://forum.hidden-source.com/member.php?3215)
 *  Default model: The Hidden:Source Dev team.
 *  
 */

#define PLUGIN_VERSION		"1.2.4"

#include <sdktools>

#define DEV				0

#define HDN_TEAM_IRIS	2
#define HDN_TEAM_HIDDEN	3

#define DEAD_ONLY		-1
#define ANYONE			0
#define ALIVE_ONLY		1
#define TEAM_ALL		-1

// Define default values
new const
	String:cszVisModelFile[]		= "models/player/iris.mdl",	// Default visible model.
	String:cszVisTogEnable[]		= "1.0",										// Default visivility toggling mode.
	String:cszMinVisTime[]			= "0.2",										// Default Minimum visibility time.
	Float:cflHiddenMins[]			= { -16.0, -16.0, 0.0 },
	Float:cflHiddenMaxs[]			= { 16.0, 16.0, 72.0 }

// Globals ftw
new
	Handle:cvarVIS					= INVALID_HANDLE,	// hsm_vis
	Handle:cvarMINTIME				= INVALID_HANDLE,	// hsm_vis_mintime
	Handle:cvarVISMODEL				= INVALID_HANDLE,	// hsm_vis_model
	Handle:cvarCHATTIME				= INVALID_HANDLE,	// mp_chatime
	Handle:gtmrRoundEnd				= INVALID_HANDLE,	// Round end hide-timer
	String:gszHiddenModel[PLATFORM_MAX_PATH],			// Invisible hidden model index
	String:gszVisibleModel[PLATFORM_MAX_PATH],			// Visible model storage.
	Float:gflMinTime				= 0.2,				// Minimum time to be visible
	bool:gbVistog					= false,			// Visual toggling enabled?
	bool:gbVislocked[MAXPLAYERS+1]	= { false, ... },	// Is client locked as visible?
	bool:gbVisPlease[MAXPLAYERS+1]	= { false, ... }	// Does client WANT to be visible?

public Plugin:myinfo = {
	name		= "H:SM - Disguise",
	author		= "Paegus",
	description	= "Allows Hidden to disguise himself",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/showthread.php?9853"
}

public OnPluginStart() {
	CreateConVar(
		"hsm_vis_version",
		PLUGIN_VERSION,
		"H:SM - Visibility Version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	)
	
	cvarVIS = CreateConVar(
		"hsm_vis",
		cszVisTogEnable,
		"Enable or disable Hidden's visibility toggle.",
		_,
		true, 0.0,
		true, 1.0
	)
	
	cvarMINTIME = CreateConVar(
		"hsm_vis_mintime",
		cszMinVisTime,
		"Minimum number of seconds that hidden appears for when toggling visibility.",
		_,
		true, 0.1,
		true, 2.0
	)
	
	cvarVISMODEL = CreateConVar(
		"hsm_vis_model",
		cszVisModelFile,
		"Model file to use for visible hidden player."
	)
	
	cvarCHATTIME = FindConVar("mp_chattime")
	
	RegConsoleCmd ("+disguise", cmd_Disguised, "Makes Hidden player visible using model defined by hsm_vis_model")
	RegConsoleCmd ("-disguise", cmd_Normal, "Makes Hidden player invisible again.")
	
	HookConVarChange(cvarVIS, convar_Change)
	HookConVarChange(cvarMINTIME, convar_Change)
	HookConVarChange(cvarVISMODEL, convar_Change)
	
	if (GetConVarFloat(cvarVIS) > 0) {
		gbVistog = true
		HookEventEx("game_round_start",	event_RoundStart)
		HookEventEx("game_round_end",	event_RoundEnd,		EventHookMode_Pre)
		HookEventEx("player_hurt",		event_PlayerHurt,	EventHookMode_Pre)
	} else {
		gbVistog = false
	}
	
}

// Clear all settings, just in case and add any required downloads.
public OnMapStart() {
	GetConVarString(cvarVISMODEL, gszVisibleModel, PLATFORM_MAX_PATH)
	
	if (!FileExists(gszVisibleModel)) {
		LogError(
			"[VISTOG] Model \"%s\" does not exist in filesystem. Using default: \"%s\"",
			gszVisibleModel,
			cszVisModelFile
		)
		strcopy(gszVisibleModel, PLATFORM_MAX_PATH,cszVisModelFile)
	}
	
	PrecacheModel(gszVisibleModel)			// Fuck you non-precached models
	
	for (new i=1; i <= MaxClients; i++) {
		gbVislocked[i]	= false
		gbVisPlease[i]	= false
		
		if (CanAppear(i)) {
			GetClientModel(i, gszHiddenModel, PLATFORM_MAX_PATH)
		}
	}
}

// Monitor changes to convars
public convar_Change(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (convar == cvarVIS) {
		if (
			StringToInt(oldVal) < 1 &&
			StringToInt(newVal) > 0
		) {
			gbVistog = true
			
			// Hook into events.
			HookEventEx("game_round_start",	event_RoundStart)
			HookEventEx("game_round_end",	event_RoundEnd,		EventHookMode_Pre)
			HookEventEx("player_hurt",		event_PlayerHurt,	EventHookMode_Pre)
		} else {
			gbVistog = false
			
			// Release event hooks
			UnhookEvent("game_round_start",	event_RoundStart)
			UnhookEvent("game_round_end",	event_RoundEnd,		EventHookMode_Pre)
			UnhookEvent("player_hurt",		event_PlayerHurt,	EventHookMode_Pre)
			
			MakeHiddenInvisible()	// Make sure all hiddens are invisible.
		}
	} else if (convar == cvarMINTIME) {
		gflMinTime = StringToFloat(newVal)
	} else if (convar == cvarVISMODEL) {
		if (FileExists(newVal, true)) {
			strcopy(gszVisibleModel, PLATFORM_MAX_PATH, newVal)
		} else {
			LogError(
				"[VISTOG] Model \"%s\" does not exist in filesystem. Using default: \"%s\"",
				gszVisibleModel,
				cszVisModelFile
			)
			strcopy(gszVisibleModel, PLATFORM_MAX_PATH, cszVisModelFile)
		}
		
		PrecacheModel(gszVisibleModel)			// Fuck you non-precached models
	}
}

// Automatically conceal when hit.
public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (CanDisappear(client)) {
		MakeHiddenInvisible(client)		// Process client invisibility
	}
	
	return Plugin_Continue
}

// Get hidden player model.
public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (gtmrRoundEnd != INVALID_HANDLE) {
		KillTimer(gtmrRoundEnd)
	}
	
	if (GetConVarBool(cvarVIS)) {
		gbVistog = true
	}
	
	for (new i=1; i <= MaxClients; i++) {
		if (CanAppear(i)) {
			GetClientModel(i, gszHiddenModel, PLATFORM_MAX_PATH)
			PrecacheModel(gszHiddenModel)			// Fuck you non-precached models
		}
	}
}

// Store player's hidden model index before material_check event fires.
public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	gtmrRoundEnd = CreateTimer((GetConVarFloat(cvarCHATTIME) - 0.5), tmr_HideAll)
}

public Action:tmr_HideAll(Handle:timer) {
	MakeHiddenInvisible()
	gbVistog = false
	gtmrRoundEnd = INVALID_HANDLE	// Timer finished.
}

// Process client's +disguise command
public Action:cmd_Disguised (client,argc) {
	if (CanAppear(client)) {
		MakeHiddenVisible(client)	// Process client visibility request
	}
	
	return Plugin_Handled
}

// Process client's -disguise command
public Action:cmd_Normal (client, argc) {
	if (CanDisappear(client)) {
		MakeHiddenInvisible(client)		// Process client invisibility request
	}
	
	return Plugin_Handled
}

stock bool:IsPlayer(const any:client) {
	return(
		client &&
		IsClientInGame(client) &&
		IsPlayerAlive(client)
	)
}

// Returns true if client is Hidden player.
stock bool:IsHidden(const any:client) {
	return (
		IsPlayer(client) && 
		GetClientTeam(client) == HDN_TEAM_HIDDEN
	)
}

// Returns true if client is IRIS player.
stock bool:IsIRIS(const any:client) {
	return (
		IsPlayer(client) &&
		GetClientTeam(client) == HDN_TEAM_IRIS
	)
}

// Returns true if the hidden can appear.
stock bool:CanAppear(const any:client) {
	return (
		gbVistog &&				// Vistog is enabled
		IsHidden(client) &&			// Calling client is active hidden player
		!gbVisPlease[client]		// Calling client wasn't previously wanting visibility
	)
}

// Returns true if the hidden can disappear.
stock bool:CanDisappear(const any:client) {
	return (
		gbVistog &&					// Vistog is enabled
		IsHidden(client) &&			// Calling client is active hidden player
		gbVisPlease[client]			// Calling client wanted to be visible
	)
}

// Disappearing is prevented for a time, then released.
public Action:tmr_ReleaseVisibleLock (Handle:timer, any:client) {
	gbVislocked[client] = false			// Release client from visibility lock
	if (!(gbVisPlease[client])) {		// Client no longer wants to be invisible
		MakeHiddenInvisible(client)		// Set client invisible again.
	}
}

// Set's clients model to the visible hidden model.
stock MakeHiddenVisible(const any:client=0, const any:mode=0) {
	if (!client) {
		for (new i = 1; i <= MaxClients; i++) {
			if (IsHidden(i)) {
				MakeHiddenVisible(i)
			}
		}
		return
	}
	
	gbVisPlease[client] = true	// Set client now wants to be visible
	
	gbVislocked[client] = true									// Enable visibility lock
	CreateTimer(gflMinTime, tmr_ReleaseVisibleLock, client)	// Start minimum visible timer.
	
	if (mode) SetEntProp(client, Prop_Send, "m_nRenderFX", 16, 4)
	
	PrecacheModel(gszVisibleModel)			// Fuck you non-precached models
	SetEntityModel(client, gszVisibleModel)	// Set new model
	
	SetEntProp(client, Prop_Send, "m_nSkin", 0, 4)
	SetEntProp(client, Prop_Send, "m_nBody", 1, 4)
	
	ClientCommand(client, "playgamesound Hidden.AuraOut;r_screenoverlay vgui/hud/helmetcam")
	
	// Get client details for log output
	decl String:szClientName[MAX_NAME_LENGTH]
	decl String:szClientAuth[MAX_NAME_LENGTH]
	GetClientName(client, szClientName, MAX_NAME_LENGTH)
	GetClientAuthString(client, szClientAuth, MAX_NAME_LENGTH)
	
	LogToGame(
		"\"%s<%i><%s><Hidden>\" Appeared!",
		szClientName,
		GetClientUserId(client),
		szClientAuth
	)
	
	SetEntPropVector(client, Prop_Send, "m_vecMins", cflHiddenMins)
	SetEntPropVector(client, Prop_Send, "m_vecMaxs", cflHiddenMaxs)
}

// Restore hidden's invisibility
stock MakeHiddenInvisible(const any:client=0) {
	if (!client) {
		for (new i = 1; i <= MaxClients; i++) {
			if (CanDisappear(i)) {
				MakeHiddenInvisible(i)
			}
		}
		return
	}
	
	gbVisPlease[client] = false		// Set client to longer wanting to be visible
	
	if (gbVislocked[client]) {
		return	// Too early dawg!
	}
	
	/* Bump player up a bit?
	decl Float:flPos[3]
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", flPos)
	flPos[2] += 10
	TeleportEntity(client, flPos, NULL_VECTOR, NULL_VECTOR)
	*/
	
	PrecacheModel(gszHiddenModel)			// Fuck you non-precached models
	SetEntityModel(client, gszHiddenModel)	// Restore old model
	
	SetEntProp(client, Prop_Send, "m_nSkin", 0, 4)
	SetEntProp(client, Prop_Send, "m_nBody", 1, 4)
	SetEntProp(client, Prop_Send, "m_nRenderFX", 0, 4)
	
	ClientCommand(client, "r_screenoverlay 0;playgamesound Hidden.AuraIn")
	
	// Get client details for log output
	decl String:szClientName[MAX_NAME_LENGTH]
	decl String:szClientAuth[MAX_NAME_LENGTH]
	GetClientName(client, szClientName, MAX_NAME_LENGTH)
	GetClientAuthString(client, szClientAuth, MAX_NAME_LENGTH)
	
	LogToGame(
		"\"%s<%i><%s><Hidden>\" Vanished!",
		szClientName,
		GetClientUserId(client),
		szClientAuth
	)
	
	SetEntPropVector(client, Prop_Send, "m_vecMins", cflHiddenMins)
	SetEntPropVector(client, Prop_Send, "m_vecMaxs", cflHiddenMaxs)
}
