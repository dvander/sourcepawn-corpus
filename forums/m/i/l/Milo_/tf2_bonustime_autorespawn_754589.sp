/**
 * Application:      tf2_bonustime_autorespawn.smx
 * Author:           Milo <milo@corks.nl>
 * Target platform:  Sourcemod 1.1.0 + Metamod 1.7.0 + Team Fortress 2 (20090215)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define VERSION               "1.4"

#define TEAM_RED              2
#define TEAM_BLU              3

new const bool:respawnWinners = false;

new bool:pluginActive         = false;
new Handle:cvarSpawn          = INVALID_HANDLE;
new Handle:cvarDelay          = INVALID_HANDLE;
new respawnMethod             = 0;
new losingTeam                = 0;
new Float:spawnTimerDelay     = 0.0;

new bool:playerOnline[MAXPLAYERS+1];

public Plugin:myinfo = {
	name               = "TF2 Bonustime Autorespawn plugin",
	author             = "Milo",
	description        = "Allows you to control spawning during the humiliation time (mp_bonusroundtime).",
	version            = VERSION,
	url                = "http://sourcemod.corks.nl/"
};

/**********************************************************
	Plugin API
**********************************************************/

public OnPluginStart() {
	new bool:hookSuccess = true;
	// Create CVars
	cvarSpawn = CreateConVar("sm_bonustime_autorespawn", "2",     "Auto-respawn members of the losing team during humiliation round. 0 = no (default), 1 = yes, 2 = keep respawning", 0, true, 0.0, true, 2.0);
	cvarDelay = CreateConVar("sm_bonustime_spawndelay",  "1.0",   "Delay for respawning people (in seconds). Minimum: 1 (default), Maximum: 10", 0, true, 1.0, true, 10.0);
	CreateConVar(            "bonustimerespawn_version", VERSION, "Current version of the bonustime autorespawn plugin", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// Load pluginconfig
	AutoExecConfig(true, "tf2_bonustime_autorespawn");  
	// Hook a bunch of TF2 events
	hookSuccess = HookEventEx("player_death",            Event_PlayerDeath)           ? hookSuccess : false;
	hookSuccess = HookEventEx("teamplay_win_panel",      Event_HumiliationRoundStart) ? hookSuccess : false;
	hookSuccess = HookEventEx("teamplay_round_start",    Event_HumiliationRoundEnd)   ? hookSuccess : false;
	// Make sure all hooks succeeded
	if (!hookSuccess) SetFailState("Failed to create required hooks.");
}

/**********************************************************
	When the bonustime starts, read the cvar and activate
	the autorespawner. Also respawn any dead losers.
**********************************************************/

public Event_HumiliationRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	new respawnDelay;
	new winningTeam = GetEventInt(event, "winning_team");
	if      (winningTeam == TEAM_RED) losingTeam = TEAM_BLU;
	else if (winningTeam == TEAM_BLU) losingTeam = TEAM_RED;
	else                              losingTeam = 0;
	// Check the sm_bonustime_autorespawn setting to see how we should handle deaths
	respawnMethod   = GetConVarInt(cvarSpawn);
	respawnMethod   = (respawnMethod > 2 || respawnMethod < 1) ? 0 : respawnMethod;
	// Get the delay from the sm_bonustime_spawndelay, make sure it is in a valid range
	respawnDelay    = GetConVarInt(cvarDelay);
	respawnDelay    = (respawnDelay > 10) ? 10 : respawnDelay;
	respawnDelay    = (respawnDelay < 1)  ?  1 : respawnDelay;
	spawnTimerDelay = float(respawnDelay);
	// Search all players for "dead losers"
	if (respawnMethod >= 1) {
		for (new i = 1; i<=MAXPLAYERS; i++) {
			// Check if the player is ingame, a loser, and dead
			// Ifso: Create a timer to force the respawn.
			if (playerOnline[i] == true)
			if (IsClientConnected(i))
			if (IsClientInGame(i))
			if (!IsPlayerAlive(i))
			if (respawnWinners || GetClientTeam(i) == losingTeam)
			CreateTimer(spawnTimerDelay, timerReSpawn, i);
		}
		pluginActive = true;
	}
}

/**********************************************************
	When the round or map ends, Stop the autorespawner
**********************************************************/

public Event_HumiliationRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	pluginActive = false;
}

public OnMapEnd() {
	pluginActive = false;
}

/**********************************************************
	Keep track of the amount of players currently online
**********************************************************/

public OnClientDisconnect(client) {
	playerOnline[client] = false;
}

public OnClientConnected(client) {
	playerOnline[client] = true;
}

/**********************************************************
	Autorespawner: Handling people who die.
**********************************************************/

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	// Ignore event if we arent in bonustime or cvar isnt set to 2.
	if (!pluginActive)     return;
	if (respawnMethod < 2) return;
	// Check if the client should be respawned
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (respawnWinners || GetClientTeam(client) == losingTeam) {
		// Ifso, create a timer to force the respawn.
		CreateTimer(spawnTimerDelay, timerReSpawn, client);
	}
}

// Timer to respawn a specific client
public Action:timerReSpawn(Handle:timer, any:client) {
	if (IsClientConnected(client)) TF2_RespawnPlayer(client);
}