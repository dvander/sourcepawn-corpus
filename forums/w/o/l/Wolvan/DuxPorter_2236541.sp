/* Copyright
 * Category: None
 * 
 * Dux Porter 1.0.0 by Wolvan
 * Contact: wolvan1@gmail.com
*/

/* Includes
 * Category: Preprocessor
 *  
 * Includes the necessary SourceMod modules
 * 
*/
#include <sourcemod>
#include <tf2_stocks>

/* Plugin constants definiton
 * Category: Preprocessor
 * 
 * Define Plugin Constants for easier usage and management in the code.
 * 
*/
#define PLUGIN_NAME "Dux Porter"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Wolvan"
#define PLUGIN_DESCRIPTION "Teleport all dem dux to you!"
#define PLUGIN_URL "NULL"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.DuxPorter.cfg"
#define PLUGIN_DATA_STORAGE "DuxPorter"
#define PERMISSIONNODE_BASE "DuxPorter"

/* Variable creation
 * Category: Storage
 *  
 * Store countdowns and opt state of each player
 * 
*/
new bool:isOptOut[MAXPLAYERS+1] = { true, ... };
new bool:isOptOutByAdmin[MAXPLAYERS+1] = { false, ... };
new Handle:duckTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

/* ConVar Handle creation
 * Category: Storage
 * 
 * Create the Variables to store the ConVar Handles in.
 * 
*/
new Handle:g_repeatTime = INVALID_HANDLE;

/* Create plugin instance
 * Category: Plugin Instance
 *  
 * Tell SourceMod about my Plugin
 * 
*/
public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
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
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
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
public OnPluginStart(){
	
	// load translations
	LoadTranslations("common.phrases");
	
	// register console commands
	RegConsoleCmd("sm_duxport", Command_DuxPort, "TELEPORT DEM DUX");
	
	// load Config File
	if (FindConVar("duxporter_version") == INVALID_HANDLE) { AutoExecConfig(true); }
	
	// create Settings ConVars
	g_repeatTime = CreateConVar("duxporter_repeattime", "3.0", "How quickly does the Duck Teleporting repeat", FCVAR_NOTIFY, true, 0.1);
	
	// create Version tracking convar
	CreateConVar("duxporter_version", PLUGIN_VERSION, "Dux Porter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	
}

/* Plugin ends
 * Category: Plugin Callback
 *  
 * When the Plugin gets unloaded, close the storage handle
 * 
*/
public OnPluginEnd() {
	for (new i = 1; i <= MaxClients; i++) {
		if (duckTimers[i] != INVALID_HANDLE) {
			KillTimer(duckTimers[i]);
			duckTimers[i] = INVALID_HANDLE;
		}
	}
}

/* Client disconnects
 * Category: Plugin Callback
 *  
 * If a client disconnects, remove their Revive Marker if it exists
 * and reset their values in the storage arrays
 * 
*/
public OnClientDisconnect(client) {
	isOptOut[client] = true;
	isOptOutByAdmin[client] = false;
 }

 /* Teleport Ducks Timer Callback
 * Category: Timer Callback
 * 
 * Teleport the Ducks to a player every X seconds
 * 
*/
public Action:Timer_TeleportDucks(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if (!isOptOut[client]) {
		TeleportDucksToPlayer(client);
	}
}
 
TeleportDucksToPlayer(client) {
	new ent = -1;
	new Float:position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	while((ent = FindEntityByClassname(ent, "tf_bonus_duck_pickup")) != -1) {
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:Command_DuxPort(client, args) {
	if(args < 1) {
		if((!hasAdminPermission(client)) && isOptOutByAdmin[client]) {
			PrintToChat(client, "[SM] Duck teleportation has been disabled for you by an admin. You cannot enable it.");
			return Plugin_Handled;
		}
		isOptOut[client] = !isOptOut[client];
		if (!isOptOut[client]) {
			TeleportDucksToPlayer(client);
			if (duckTimers[client] == INVALID_HANDLE) {
				duckTimers[client] = CreateTimer(GetConVarFloat(g_repeatTime), Timer_TeleportDucks, GetClientUserId(client), TIMER_REPEAT);
			}
			ReplyToCommand(client, "[SM] Ducks will now teleport to you.");
		} else {
			if (duckTimers[client] != INVALID_HANDLE) {
				KillTimer(duckTimers[client]);
				duckTimers[client] = INVALID_HANDLE;
			}
			ReplyToCommand(client, "[SM] Ducks will no longer teleport to you.");
		}
	} else {
		if(!hasAdminPermission(client)) {
			PrintToChat(client, "[SM] You do not have the Permission to use this command");
			return Plugin_Handled;
		}
		decl String:arg1[128];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count;
		new bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString( arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
			ReplyToTargetError(client, target_count);
			if (client != 0) {
				PrintToChat(client, "[SM] No targets found. Check console for more Information");
			}
			return Plugin_Handled;
		}
		
		new enable = 0; new disable = 0;
		
		for (new i = 0; i < target_count; i++) {
			isOptOut[target_list[i]] = !isOptOut[target_list[i]];
			if (!isOptOut[target_list[i]]) {
				isOptOutByAdmin[target_list[i]] = false;
				enable = enable + 1;
				PrintToChat(target_list[i], "[SM] Ducks will now teleport to you.");
			} else {
				isOptOutByAdmin[target_list[i]] = true;
				disable = disable + 1;
				PrintToChat(target_list[i], "[SM] Ducks will no longer teleport to you.");
			}
		}
		if(client != 0) {
			PrintToChat(client, "[SM] Duck teleport enabled for %i Player(s), disabled for %i Player(s)", enable, disable);
		} else {
			PrintToServer("[SM] Duck teleport enabled for %i Player(s), disabled for %i Player(s)", enable, disable);
		}
	}
	return Plugin_Handled;
}

/* Check Admin Permission
 * Category: Self-defined function
 * 
 * Checks if the client has Admin Permissions
 * 
*/
public bool:hasAdminPermission(client) {
	//if (permissionssm) { return PsmHasPermission(client, "%s.Admin", PERMISSIONNODE_BASE); }
	return CheckCommandAccess(client, "duxporter_admin", ADMFLAG_GENERIC, true);
}