/* Request by GrO (http://forums.alliedmods.net/member.php?u=79557)
*  URL - http://forums.alliedmods.net/showthread.php?t=175973
* 
* DESCRIPTION:
* 	Allow players (non-admins) to be able to type !respawn and they will be respawned.
* 
* 	Only allow them to use the command for XX number of seconds after round_start
* 	and only allow them to use the command once per round and ONLY if they're alive.
* 
* 	Print chat messages to the player when they respawn themselves (or when they're 
* 	not allowed to because of time expiring or they already used the command already).
* 	Also, type a command to all players when a player respawns as a result of using the
* 	command.
* 
* 	VERSION LOG:
* 		Version 0.0.1.0
* 			-	Initial release
* 
* 		Version 0.0.1.1
* 			-	Adjusted plugin to only allow alive players to have the ability to use the !respawn command
* 
*/
#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "0.0.1.1"

new bool:Respawned[MAXPLAYERS+1] = false;

new Handle:g_hTimer = INVALID_HANDLE;
new Float:RespawnTimer;

new bool:AllowRespawn = false;

public Plugin:myinfo = 
{
	name = "Non-Admin Respawn",
	author = "TnTSCS aka ClarkKent",
	description = "Allow non-admins to use !respawn to respawn themselves",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}


/**
 * Called when the plugin is fully initialized and all known external references 
 * are resolved. This is only called once in the lifetime of the plugin, and is 
 * paired with OnPluginEnd().
 *
 * If any run-time error is thrown during this callback, the plugin will be marked 
 * as failed.
 *
 * It is not necessary to close any handles or remove hooks in this function.  
 * SourceMod guarantees that plugin shutdown automatically and correctly releases 
 * all resources.
 *
 * @noreturn
 */
public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_nonadminrespawn_version", PLUGIN_VERSION, 
	"Version of 'Non-Admin Respawn'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_nonadminrespawn_timer", "30.0", 
	"Amount of time (in seconds) to allow a player to use !respawn\nMax set to 14 minutes (840.0 seconds)", _, true, 1.0, true, 840.0)), OnTimerChanged);
	RespawnTimer = GetConVarFloat(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	LoadTranslations("non_admin_respawn.phrases"); // Load the translation file for this plugin
	
	HookEvent("round_start", Event_RoundStart); // Hook round_start so we can start the timer which dis/allows the use of the !respawn command
	HookEvent("round_end", Event_RoundEnd); // Hook round_end so we can reset things back to default.
	
	// Create the !respawn command, will restrict admins from being able to use it in the command callback
	RegConsoleCmd("respawn", Command_Respawn, "Allows a non-admin to respawn themselves");
}

/**
 * Called once a client successfully connects.  This callback is paired with OnClientDisconnect.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientConnected(client)
{
	Respawned[client] = false;
}


/**
 * Called when a client is disconnecting from the server.
 *
 * @param client		Client index.
 * @noreturn
 */
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		Respawned[client] = false;
	}
}

/**
 * Callback for !respawn command
 * 
 * @param client		Client index.
 * @param args		arguments of the command (should be none)
 * @noreturn
 */
public Action:Command_Respawn(client, args)
{
	if(client == 0) // If client is console (or non in-game player)
	{
		ReplyToCommand(client, "%t", "In Game");		
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client)) // If player is dead (since we only want them using this when they're alive)
	{
		ReplyToCommand(client, "%t", "Dead");
		return Plugin_Handled;
	}
	
	if(args > 0) // If there are any arguments after !respawn
	{
		ReplyToCommand(client, "%t", "args");		
		return Plugin_Handled;
	}
	
	if(CheckCommandAccess(client, "non-admin-respawn", ADMFLAG_GENERIC)) // If player is an admin
	{
		ReplyToCommand(client, "%t", "Admins Only");		
		return Plugin_Handled;
	}
	
	if(!AllowRespawn) // If AllowRespawn is set to false/disallow
	{		
		ReplyToCommand(client, "%t", "Expired Time", RespawnTimer);
		return Plugin_Handled;
	}
	
	if(Respawned[client]) // If the player already used respawn this round
	{
		ReplyToCommand(client, "%t", "Once");		
		return Plugin_Handled;
	}
	
	// Respawn the player, set to player CVar to respawned, respond to the player, and announce to the server.
	CS_RespawnPlayer(client);
	Respawned[client] = true;
	
	ReplyToCommand(client, "%t", "Respawned Self");
	
	PrintToChatAll("%t", "Respawned", client);
	
	return Plugin_Continue;
}

/**
 * 	"round_start"
 *	{
 *		"timelimit"	"long"		// round time limit in seconds
 *		"fraglimit"	"long"		// frag limit in seconds
 *		"objective"	"string"	// round objective
 *	}
 *
 */
public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	AllowRespawn = true; // Set respawn bool to true/allow
	
	// Kill the timer if it's still running for some reason, then restart it
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	// Set a timer with the CVar defined number of seconds to change the respawn bool to false/disallow
	g_hTimer = CreateTimer(RespawnTimer, Timer_Respawn);
}


/**
 * 	"round_end"
 *	{
 *		"winner"	"byte"		// winner team/user i
 *		"reason"	"byte"		// reson why team won
 *		"message"	"string"	// end round message 
 *	}
 *
 */
public Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	// Kill the Timer_Respawn timer just in case the round ended before the timer did
	if(g_hTimer != INVALID_HANDLE)
	{
		AllowRespawn = false;
		
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	// Reset everyone's player variable Respawned to false
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Respawned[i] = false;
		}
	}
}

/**
 * Timer callback to reset the allow respawn bool to disallow/false
 * 
 * @param timer		Handle for the timer
 * @noreturn
 */
public Action:Timer_Respawn(Handle:timer)
{
	g_hTimer = INVALID_HANDLE;
	AllowRespawn = false;
}

// ===================================================================================================================================
// CVar Change Functions
// ===================================================================================================================================
public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnTimerChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RespawnTimer = GetConVarFloat(cvar);
}