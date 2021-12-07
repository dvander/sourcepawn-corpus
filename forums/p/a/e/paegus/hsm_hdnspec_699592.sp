/* Hidden:SourceMod - Hidden Spectator
 *
 * Description:
 *  Allows admins to spectate Hidden players.
 *
 * Variables:
 *  hsm_hdnspec_access [char] : Admin access requirement string. c: Kick, d: Ban, etc. Default: c.
 *
 * Commands:
 *  spec_next : Cycles to next observable player, including hiddens if you have access.
 *  spec_prev : Cycles to previous observable player, including hiddens if you have access.
 *
 * Changelog:
 *  v1.1.4
 *   Fixed empty hsm_hdnspec_access variable not allowing anyone to spectate hidden, instead of everyone.
 *  v1.1.3
 *   Fixed IsPlayerAlive() spam in OnGameFrame() updates. Sorry Darkhand.
 *  v1.1.2
 *   Added admin access flag. Follows SourceMod access flags.
 *   Left tracer attached to Hiddens until the round ends. Hopefully avoiding some odd client-crashes?
 *  v1.1.1
 *   Fixed not rendering IRIS sometimes.
 *   Fixed no-tracked on some maps
 *  v1.1.0
 *   Integrated Hidden spectating into normal spec_next/prev cycling.
 *   Added support for multiple hiddens.
 *   Removed external file dependancies.
 *  v1.0.2
 *   View automatically shifts to spec camera style to minimise chances of not seeing 'self'
 *   View now shifts to attackers on hidden's death. spec cam if suicide.
 *  v1.0.1
 *   Is now a functional plugin.
 *  v1.0.0
 *   Initial release
 *
 * Known issues:
 *  v1.0.1
 *   Version cvar is hsm_hsnspec_version instead of hsm_hdnspec_version. Not gonna change it for a while :/
 *
 * Todo:
 *  Add aura view when hidden is +aura-ing
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net
 *  Hidden:Source: http://www.hidden-source.com
 */
#pragma semicolon 1

#define PLUGIN_VERSION		"1.1.4"

#define DEV					0

#define HDN_MAXPLAYERS		10
#define TEAM_TRACKABLE		3

#include <sdktools>

public Plugin:myinfo = {
	name		= "H:SM - Hidden Spectator",
	author		= "Paegus",
	description	= "Allows admins to spectate the hidden player.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=699592"
}

enum {
	ObsNull = 0,
	ObsMap,
	ObsHelmet
};

static const
	String:g_szObsMode[]	= "m_iObserverMode",	// Spectating mode property.
	String:g_szObsTarget[]	= "m_hObserverTarget"	// Spectating target property.
;

new
	AdminFlag:g_afAdminLevel		= Admin_Kick,		// Admin level required to access hidden-spectator commands.
	Handle:cvarAccess				= INVALID_HANDLE
;

new
	g_eTracer[HDN_MAXPLAYERS+1]		= { -1, ... },		// Client's attached tracer entity index.
	g_eSpectating[HDN_MAXPLAYERS+1]	= { -1, ... }		// Who client is spectating. (not the entity)
;

public OnPluginStart () {
	/*
	#if DEV
	decl String:szHostname[MAX_NAME_LENGTH];
	new Handle:cvHostname = FindConVar ("hostname");
	GetConVarString (cvHostname, szHostname, MAX_NAME_LENGTH);
	if (StrContains (szHostname, "testcase", false) == -1) {	// Not the test server, unload the plugin.
		PrintToServer ("* STRT * Not a test server. Disabling command hooks");
		return;
	}
	#endif
	*/
	
	CreateConVar (
		"hsm_hsnspec_version",
		PLUGIN_VERSION,
		"H:SM - Hidden-Spectator version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	
	cvarAccess = CreateConVar (
		"hsm_hdnspec_access",
		"c",
		"SourceMod access flag string required for admin to access Hidden-Spectator. Blank = everyone."
	);
	
	HookConVarChange(cvarAccess, convar_Change);
	
	// Command hooks...
	RegConsoleCmd ("spec_next", cmd_SpecNext);			// Hook into existing command
	RegConsoleCmd ("spec_prev", cmd_SpecPrev);			// Hook into existing command
	//RegConsoleCmd ("spec_mode", cmd_SpecMode);			// Hook into existing command
	
	// Event hooks...
	HookEvent ("game_round_start", event_RoundStart, EventHookMode_Pre);	// Reinitialize if needed.
	HookEvent ("player_death", event_PlayerDeath);		// If a Didden dies switch to the killer's pov
	
	decl String:szString[MAX_NAME_LENGTH];
	GetConVarString(cvarAccess, szString, MAX_NAME_LENGTH);
	convar_Change(cvarAccess, "", szString);
}

/* Configure access level */
public convar_Change(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (convar == cvarAccess) {
		switch (CharToLower(newVal[0])) {
			case 'a': {	//"reservation"	"a"			//Reserved slots
				g_afAdminLevel = Admin_Reservation;
			}
			case 'b': {	//"generic"		"b"			//Generic admin, required for admins
				g_afAdminLevel = Admin_Generic;
			}
			case 'c': {	//"kick"		"c"			//Kick other players
				g_afAdminLevel = Admin_Kick;
			}
			case 'd': {	//"ban"			"d"			//Banning other players
				g_afAdminLevel = Admin_Ban;
			}
			case 'e': {	//"unban"		"e"			//Removing bans
				g_afAdminLevel = Admin_Unban;
			}
			case 'f': {	//"slay"		"f"			//Slaying other players
				g_afAdminLevel = Admin_Slay;
			}
			case 'g': {	//"changemap"	"g"			//Changing the map
				g_afAdminLevel = Admin_Changemap;
			}
			case 'h': {	//"cvars"		"h"			//Changing cvars
				g_afAdminLevel = Admin_Convars;
			}
			case 'i': {	//"config"		"i"			//Changing configs
				g_afAdminLevel = Admin_Config;
			}
			case 'j': {	//"chat"		"j"			//Special chat privileges
				g_afAdminLevel = Admin_Chat;
			}
			case 'k': {	//"vote"		"k"			//Voting
				g_afAdminLevel = Admin_Vote;
			}
			case 'l': {	//"password"	"l"			//Password the server
				g_afAdminLevel = Admin_Password;
			}
			case 'm': {	//"rcon"		"m"			//Remote console
				g_afAdminLevel = Admin_RCON;
			}
			case 'n': {	//"cheats"		"n"			//Change sv_cheats and related commands
				g_afAdminLevel = Admin_Cheats;
			}
			case 'o': {	//"custom1"		"o"
				g_afAdminLevel = Admin_Custom1;
			}
			case 'p': {	//"custom2"		"p"
				g_afAdminLevel = Admin_Custom2;
			}
			case 'q': {	//"custom3"		"q"
				g_afAdminLevel = Admin_Custom3;
			}
			case 'r': {	//"custom4"		"r"
				g_afAdminLevel = Admin_Custom4;
			}
			case 's': {	//"custom5"		"s"
				g_afAdminLevel = Admin_Custom5;
			}
			case 't': {	//"custom6"		"t"
				g_afAdminLevel = Admin_Custom6;
			}
			case 'z': {	//"root"		"z"			// Access to all.
				g_afAdminLevel = Admin_Root;
			}
			default: {	//no level specified. everyone can use it
				g_afAdminLevel = INVALID_ADMIN_ID;
			}
		}
	}
}

/* Could the client have of had a tracer attached? */
stock bool:WasClientTraceable (const any:client) {
	return (
		IsClientInGame (client) &&					// Client is IN-GAME
		GetClientTeam (client) == TEAM_TRACKABLE	// Client is HDN_TEAM_HIDDEN
	);
}

/* Can the client have a tracer attached? */
stock bool:IsClientTraceable (const any:client) {
	return (
		WasClientTraceable (client) &&	// Client is INGAME & on TEAM_TRACKABLE
		IsPlayerAlive (client)			// Client is alive
	);
}

/* Is the client allowed to spectate the hidden through? */
stock bool:CanClientTrace (const any:client) {
	if (g_afAdminLevel == INVALID_ADMIN_ID) {	// No access levels required. Everyone can spectate hidden.
		return true;
	} else {	// Access level specified.
		new AdminId:aiClient = GetUserAdmin (client);
		return (
			aiClient != INVALID_ADMIN_ID &&							// Client is an admin of some kind.
			//GetAdminFlags (aiClient, Access_Real) & ADMFLAG_KICK	// Client has needed access
			GetAdminFlag (aiClient, g_afAdminLevel)					// Client has needed access
		);
	}
}

/* Process player's spec_next commands */
public Action:cmd_SpecNext (client, argc) {
	return SpecShift (client, 1);
}

public Action:cmd_SpecPrev (client, argc) {
	return SpecShift (client, -1);
}

/*
public Action:cmd_SpecMode (client, argc) {
	return SpecShift (client, 0);
}
*/

/* Process player's spec_next/prev commands */
public Action:SpecShift (const any:client, const any:incr) {
	if (!CanClientTrace (client)) return Plugin_Continue;	// Client does not have access to tracing ability. We're done here.
	
	new eTarget = GetClientObsTarget (client);	// Current observation target

	if (eTarget > MaxClients) {		// Is currently observing a map-cam
		return Plugin_Continue;
	}

	#if DEV
	CreateTimer (0.01, tmr_SpecCur, client);
	#endif
	
	// Set next traceable target if valid.
	if (bSetClientViewTracer (client, GetNextTarget (eTarget, incr))) {	// Set the client's view to the target client's tracer
		return Plugin_Handled;
	} else if (g_eSpectating[client] != -1) {
		StopSpec (client);
		SetEntPropEnt (client, Prop_Send, g_szObsTarget, eTarget);
	}
	
	return Plugin_Continue;
}

/* Recursively find the next valid target */
stock GetNextTarget (const any:start, const any:increment, const any:origin=0) {
	decl base;
	new current = start + increment;
	
	if (origin < 1) { 	// External call.
		base = start;
	} else {	// Internal call, use original base.
		base = origin;
	}
	
	if (current > MaxClients) {	// Top of the list.
		current = 1;			// Start from the bottom.
	} else if (current < 1) {	// Bottom of the list.
		current = MaxClients;	// Start from the top.
	}
	
	#if DEV
	PrintToServer("* GNxT * Moving from %d by %d to %d", start, increment, current);
	#endif
	
	if (
		(
			IsClientInGame (current) &&	// Target is In-game.
			IsPlayerAlive (current)		// Target is alive
		) ||
		current == origin	// Cycle complete. No valid targets.
	) {
		return current;
	}
	
	return GetNextTarget (current, increment, base);
}


#if DEV
/* Display the clients current observation point */
public Action:tmr_SpecCur (Handle:timer, const any:client) {
	new String:title[] = "CURR";
	decl String:buffer[256], String:name[MAX_NAME_LENGTH], String:targetname[MAX_NAME_LENGTH], eTarget;
	GetClientName (client, name, MAX_NAME_LENGTH);
	
	eTarget = GetClientObsTarget (client);
	
	Format (buffer, 256, "%d:%s is observing", client, name);
	
	if (eTarget > MaxClients) {				// Observing thru map-cam
		GetEntPropString (eTarget, Prop_Send, "m_Location", targetname, MAX_NAME_LENGTH);
		Format (buffer, 256, "%s map-cam %d:%s", buffer, targetname);
	} else {								// Observing a player.
		GetClientName (eTarget, targetname, MAX_NAME_LENGTH);
		if (g_eSpectating[client] != -1) {		// Observing thru tracer-cam
			Format (buffer, 256, "%s tracer-cam on", buffer);
		} else {								// Observing normally
			Format (buffer, 256, "%s helmet-cam on", buffer);
		}
		Format (buffer, 256, "%s %d:%s", buffer, eTarget, targetname);
	}
	
	PrintToServer ("* %s * %s", title, buffer);
}
#endif

/* Attempts to set client's view to target client's tracer.
 *
 * @param client	Viewing player's index
 * @param target	Target player's index.
 * @return			true is valid tracer found on target.
 * @error			invalid client or target index.
 */
stock bool:bSetClientViewTracer (const any:client, const any:target) {
	if (IsClientTraceable (target)) {		// Target can be have a tracer-cam attached.
		StopSpec (client);
		
		if (bMakeTracer (target)) {			// Valid tracer-cam already exists or was created.
			decl String:szTargetName[MAX_NAME_LENGTH];
			GetClientName (target, szTargetName, MAX_NAME_LENGTH);						// Get target's name
			
			//SetEntProp (client, Prop_Send, g_szObsMode, ObsMap);						// Set client's view to map-cam. Doesn't work!
			SetEntPropEnt (
				client, Prop_Send, g_szObsTarget,
				GetNearestEntityByClass (target, "info_spectator")
			);																			// Set the view target to nearest map-cap.
			
			SetClientViewEntity (client, g_eTracer[target]);							// Set client's view.
			g_eSpectating[client] = target;												// Set client's current tracer-cam to target's
			
			PrintCenterText (client, "[HDNSpec] Tracking %s", szTargetName);			// Inform client via center text
			PrintToChat (client, "[HDNSpec] Tracking %s", szTargetName);				// Inform client's chat-area
			PrintToConsole (client, "[HDNSpec] Tracking %s", szTargetName);				// Inform client's console
			
			return true;
		}
	}
	
	return false;
}

/* Recursively creates a tracer-cam if any traceable targets are found */
stock bool:bMakeTracer (const any:target=0) {
	
	#if DEV > 2
	new String:title[] = "MAKE";
	#endif
	
	if (target == 0) {									// Make any tracer
		for (new i = 1; i <= MaxClients; i++) {			// Cycle through available targets
			if (bMakeTracer (i)) {						// A valid tracer was created.
				return true;
			}
		}
	} else {											// Make a specific target's tracer.
		if (IsClientTraceable (target)) {				// Target can have a tracer attached.
			
			#if DEV > 2
			decl String:name[MAX_NAME_LENGTH];
			GetClientName (target, name, MAX_NAME_LENGTH);
			#endif
			
			if (
				g_eTracer[target] == -1 ||				// This client's tracer does not already exist, create it now.
				!IsValidEntity (g_eTracer[target])		// Tracer exists but it's invalid
			) {
				g_eTracer[target] = CreateEntityByName ("prop_dynamic_override");
				
				if (IsValidEntity (g_eTracer[target])) {	// Valid entity created.
					decl Float:vOrigin[3], Float:vAngle[3];
					GetClientEyePosition (target, vOrigin);
					vOrigin[2] -= 16.0;	// Lower the view point a bit.
					GetClientEyeAngles (target, vAngle);
					
					DispatchKeyValueVector (g_eTracer[target], "origin", vOrigin);
					DispatchKeyValueVector (g_eTracer[target], "angles", vAngle);
					
					DispatchKeyValue (g_eTracer[target], "model", "models/shells/pellet.mdl");
					DispatchKeyValue (g_eTracer[target], "disableshadows", "1");
					DispatchKeyValue (g_eTracer[target], "solid", "0");
					DispatchKeyValue (g_eTracer[target], "rendermode", "10");
					DispatchSpawn (g_eTracer[target]);
					
					AcceptEntityInput (g_eTracer[target], "TurnOn");
					
					SetVariantString ("!activator");
					AcceptEntityInput (g_eTracer[target], "SetParent", target, g_eTracer[target], 0);
					
					#if DEV > 2
					PrintToServer (
						"* %s * Created tracer %d on %d:%s at %.22fx | %.2fy | %.2fz | %.2fºy | %.2fºp, | %.2fºr",
						title,
						g_eTracer[target],
						target,
						name,
						vOrigin[0], vOrigin[1], vOrigin[2],
						vAngle[0], vAngle[1], vAngle[2]
					);
					#endif
					
					return true;
				} else {
					
					#if DEV > 2
					PrintToServer (
						"* %s * Failed to created %s tracer-cam %d",
						title,
						name,
						g_eTracer[target]
					);
					#endif
					
					g_eTracer[target] = -1;		// Reset tracer value.
				}
			} else {	// This client's tracer already exists, return true.
				#if DEV > 2
				PrintToServer (
					"* %s * %d:%s already has tracer-cam %d",
					title,
					target,
					name,
					g_eTracer[target]
				);
				#endif
				
				return true;
			}
		}
	}
	return false;
}

/* Stop client from observing any tracer-cam */
stock StopSpec (const any:client=0) {
	if (client == 0) {	// Process ALL clients
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame (i)) {	// Client is in-game
				StopSpec (i);
			}
		}
	} else {	// Process specific client
		if (g_eSpectating[client] != -1) {	// Client was observing someone's tracer.
			#if DEV
			new String:title[] = "STOP";
			decl String:name[MAX_NAME_LENGTH], String:targetname[MAX_NAME_LENGTH];
			GetClientName (client, name, MAX_NAME_LENGTH);
			GetClientName (g_eSpectating[client], targetname, MAX_NAME_LENGTH);
			PrintToServer (
				"* %s * %d:%s stops observing tracer-cam %d on %d:%s",
				title,
				client,
				name,
				g_eTracer[g_eSpectating[client]],
				g_eSpectating[client],
				targetname
			);
			#endif
			
			//new eOldSpec = g_eSpectating[client];
			g_eSpectating[client] = -1;
			if (IsClientInGame (client)) {
				SetClientViewEntity (client, client);
			}
			//CheckSpecs (eOldSpec);		// Check for other observers.
		}
	}
}

/* Check possible traceable targets and remove any un-watched tracer-cams */
stock CheckSpecs (const any:target=0) {
	if (target == 0) {									// Recurse through ALL clients
		for (new i = 1; i <= MaxClients; i++) {				// Cycle through possible targets
			if (IsClientInGame (i)) {					// Client is ingame.
				CheckSpecs (i);							// Check this target for spectators
			}
		}
	} else {											// Check specific target.
		#if DEV
		new String:title[] = "CHCK";
		decl String:name[MAX_NAME_LENGTH], String:targetname[MAX_NAME_LENGTH];
		#endif
		
		if (g_eTracer[target] != -1 ) {					// Target has a tracer.
			new bool:bWatched = false;
			if (IsClientTraceable (target)) {				// Target can be traced.
				for (new i = 1; i <= MaxClients; i++) {		// Cycle through possible observers
					if (g_eSpectating[i] == target) {	// A client is specatating this target
						#if DEV
						GetClientName (target, targetname, MAX_NAME_LENGTH);
						GetClientName (i, name, MAX_NAME_LENGTH);
						PrintToServer (
							"* %s * %d:%s is observing tracer-cam %d on %d:%s",
							title,
							i,
							name,
							g_eSpectating[i],
							target,
							targetname
						);
						#endif
						
						bWatched = true;
					}
				}
			} else {									// Target should be not traced anymore
				for (new i = 1; i <= MaxClients; i++) {
					if (g_eSpectating[i] == target) {	// Someone is watching this tracer
						#if DEV
						GetClientName (target, targetname, MAX_NAME_LENGTH);
						GetClientName (i, name, MAX_NAME_LENGTH);
						PrintToServer (
							"* %s * %d:%s is observing illegal tracer-cam %d on %d:%s",
							title,
							i,
							name,
							g_eSpectating[i],
							target,
							targetname
						);
						#endif
						
						g_eSpectating[i] = -1;
						if (IsClientInGame (i)) {
							SetClientViewEntity (i, i);
						}
					}
				}
			}
			
			if (!bWatched) {	// No observers found for this target
				#if DEV
				GetClientName (target, targetname, MAX_NAME_LENGTH);
				PrintToServer (
					"* %s * No one is observing tracer-cam %d on %d:%s",
					title,
					g_eTracer[target],
					target,
					targetname
				);
				#endif
				
				if (IsValidEntity (g_eTracer[target])) {	// Entity still exists
					AcceptEntityInput (
						g_eTracer[target],
						"Kill"
					);									// Kill this unwatched tracer entity.
				}
				g_eTracer[target] = -1;			// Reset the tracer entity index.
			}
		}
		#if DEV
		else {
			GetClientName (target, targetname, MAX_NAME_LENGTH);
			PrintToServer (
				"* %s * No tracer-cam on %d:%s",
				title,
				target,
				targetname
			);
		}
		#endif
	}
}

/* Returns the entity the client is observing through */
stock GetClientObsTarget (const any:client) {
	if (g_eSpectating[client] != -1) {	// Viewing a tracer-cam
		return g_eSpectating[client];
	} else {							// Viewing a normally.
		return GetEntPropEnt (client, Prop_Send, g_szObsTarget);
	}
}

/* Returns the nearest entity of classname[] to client. -1 if none found. */
stock GetNearestEntityByClass (const any:client, const String:classname[]) {
	new eIndex = -1, eClosest = -1, Float:flNearestRange = 999999.0;
	decl Float:vClientPos[3], Float:vEntityPos[3], Float:flEntityRange;
	
	GetClientEyePosition (client, vClientPos);
	eIndex = FindEntityByClassname (eIndex, classname);
	
	while (eIndex != -1) {	// A valid entity was found.
		GetEntPropVector (eIndex, Prop_Send, "m_vecOrigin", vEntityPos);
		flEntityRange = GetVectorDistance (vEntityPos, vClientPos);
		if (flEntityRange < flNearestRange) {	// Found a closer one.
			flNearestRange = flEntityRange;
			eClosest = eIndex;
		}
		
		eIndex = FindEntityByClassname (eIndex, classname);
	}
	
	return eClosest;
}

/* Check if the disconnecting player was observing a Hidden and clear if needbe */
public OnClientDisconnect (client) {
	if (g_eSpectating[client] != -1) {				// They were observing a tracer-cam.
		StopSpec (client);							// Stop observing the tracer-cam.
	}
	
	if (g_eTracer[client] != -1) {					// They had a tracer-cam attached.
		for (new i = 1; i <= MaxClients; i++)	{	// Cycle through possible observers and remove any who are watching
			if (g_eSpectating[i] == client) {		// Someone was observing tracer-cam attached to client.
				StopSpec (i);
			}
		}
	}
}

/* Check check for observing players */
public Action:event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast) {
	StopSpec ();
	CheckSpecs ();
	bMakeTracer ();
	
	return Plugin_Continue;
}

/* If the Hidden died, move anyone spectating them to the view of the player that killed them */
public Action:event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast) {
	new eVictim = GetClientOfUserId (GetEventInt (event, "userid"));			// Get deceased client.
	if (WasClientTraceable (eVictim)) {											// Deceased was traceable.
		new eAttacker = GetClientOfUserId (GetEventInt (event, "attacker"));	// Get killing client.
		for (new i = 1; i <= MaxClients; i++ ) {								// Cycle through possible spectators
			if (g_eSpectating[i] == eVictim) {									// client is spectating the victim.
				StopSpec (i);													// Stop spectating deceased.
				if (eAttacker > 0) {											// Killer wasn't world.
					//ClientCommand (i, "spec_mode 2;spec_prev");				// Set observer's mode to helmet-cam and cycle back one.
					SetEntProp (i, Prop_Send, g_szObsMode, ObsHelmet);			// Set observer's mode to helmet-cam.
					SetEntPropEnt (i, Prop_Send, g_szObsTarget, eAttacker);		// Set observer's target to attacker.
				} else {														// Killer was world
					//ClientCommand (i, "spec_mode 1;spec_prev");					// Set observer's mode to map-cam
					SetEntProp (i, Prop_Send, g_szObsMode, ObsMap);				// Set observer's mode to map-cam
					SetEntPropEnt (i, Prop_Send, g_szObsTarget,
						GetNearestEntityByClass(eVictim, "info_spectator"));	// Set observer's target.
					//CreateTimer(0.1, tmr_PlayerDeathByWorld, i);						// Set the client's view target.
				}
			}	// else client was not observing victim.
		}	// Cycle finished.
	}	// else victim wasn't a Hidden
	
	return Plugin_Continue;
}

/* Sets the client's view to the nearest info_spectator entity */ /*
public Action:tmr_PlayerDeathByWorld (Handle:timer, const any:client) {
	SetEntPropEnt (client, Prop_Send, g_szObsTarget, GetNearestEntityByClass(eVictim, "info_spectator"));
	return Plugin_Continue;
}
*/

/* Update all active tracer-cams */
public OnGameFrame () {
	decl Float:vAng[3], i;
	
	for (i = 1; i <= MaxClients; i++) {
		if (
			g_eTracer[i] != -1 &&			// Client should have a tracer-cam attached.
			IsValidEntity (g_eTracer[i]) &&	// Client's tracer-cam is valid.
			IsClientInGame(i) &&			// Client is connected
			IsPlayerAlive (i)				// Player is alive.
		) {
			GetClientEyeAngles (i, vAng);
			TeleportEntity (g_eTracer[i], NULL_VECTOR, vAng, NULL_VECTOR);
			#if DEV > 1
			if (GetRandomInt (1, 20) == 1) {
				PrintToServer (
					"* [GAME] * Updating tracer-cam %d on %d(%d)",
					g_eTracer[i],
					i,
					GetClientUserId (i)
				);
			}
			#endif
		} else if (g_eTracer[i] != -1) {
			g_eTracer[i] = -1;
		}
	}
}

