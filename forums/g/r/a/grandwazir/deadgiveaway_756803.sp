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

/* Dead Giveaway - A modification for the game Left4Dead */
/* Copyright 2009 James Richardson */

/*
* Version 1.0
* 		- Initial release.
* Version 1.0.1
* 		- Fixed ArrayOutOfBounds error.
*			- Seperated Dead Giveaway configuation into cfg/sourcemod/plugin.deadgiveaway
*/

/* Define constants */
#define PLUGIN_VERSION    "1.0.1"
#define PLUGIN_NAME       "Dead Giveaway"
#define PLUGIN_TAG  	  	"[DGA] "
#define MAX_PLAYERS 			14		

/* Include necessary files */
#include <sourcemod>

/* Handles */
new Handle:NotifyAllPlayers = INVALID_HANDLE;
new Handle:LogInitiators = INVALID_HANDLE;
new Handle:CoolDownEnabled = INVALID_HANDLE;
new Handle:CoolDownTime = INVALID_HANDLE;

/* Timer array */
new bool:VoteCoolDown[MAX_PLAYERS+1]

/* Metadata for the mod */
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Helps prevent vote abuse by applying limits to voting.",
	version = PLUGIN_VERSION,
	url = "www.grandwazir.com"
};

/* Create and set all the necessary for All4Dead and register all our commands */ 
public OnPluginStart() {
	/* Create all the necessary ConVars and execute auto-configuation */
	CreateConVar("dga_version", PLUGIN_VERSION, "The version of the Dead Giveaway plugin.", FCVAR_PLUGIN);
	NotifyAllPlayers = CreateConVar("dga_notify_players", "1", "Whether or not we notify players of who calls a vote.", FCVAR_PLUGIN);
	LogInitiators = CreateConVar("dga_log_initiators", "0", "Whether or not we log the names of players who call votes.", FCVAR_PLUGIN);
	CoolDownEnabled = CreateConVar("dga_cooldown_enabled", "1", "Whether or not players have to wait a specified time before they can call another vote.", FCVAR_PLUGIN);
	CoolDownTime = CreateConVar("dga_cooldown_time", "60", "The amount of time (in seconds) a player has to wait before they can call another vote.", FCVAR_PLUGIN); 	
	AutoExecConfig(true)

	HookEvent("vote_started", Event_VoteStarted)
	RegConsoleCmd("callvote", Command_VoteHandler)

}

public OnConfigsExecuted() {
	new String:version[16]
	GetConVarString(FindConVar("dga_version"), version, sizeof(version))	
	if (!StrEqual(version, PLUGIN_VERSION)) {
		LogAction(0, -1, "WARNING: Your plugin.deadgiveaway.cfg is out of date. Please delete it and restart your server.")
	}
	LogAction(0, -1, "plugin.deadgiveaway.cfg has been loaded.")
}


/* Hooking vote_started and blocking it does not block voting. We need to hook callvote instead */
public Action:Command_VoteHandler(client, args) {
	/* If a player is cooling down then stop them from starting a vote */	
	if (GetConVarBool(CoolDownEnabled) && VoteCoolDown[client]) {
		PrintHintText(client, "You must wait a while before calling another vote");		
		return Plugin_Handled;
	}
	return Plugin_Continue
}

/* When a vote is called notify and log approiately */ 
public Action:Event_VoteStarted(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetEventInt(event, "initiator")
	/* Notify players if we are allowed to */	
	if (GetConVarBool(NotifyAllPlayers)) {
		PrintHintTextToAll("%N has called a vote", client);
	}
	/* Log the name of the player if we are allowed to */
	if (GetConVarBool(LogInitiators)) {
		LogMessage("%L has called a vote", client);
	}
	/* If we are enforcing a minimum amount of time between votes start a cooldown */
	if (GetConVarBool(CoolDownEnabled)) {
		VoteCoolDown[client] = true		
		CreateTimer(GetConVarFloat(CoolDownTime), CoolDownOver, client)
	}
	return Plugin_Continue
}

/* Release the lock on the player and allow them to call votes again */
public Action:CoolDownOver(Handle:timer, any:client) {
	VoteCoolDown[client] = false
}
