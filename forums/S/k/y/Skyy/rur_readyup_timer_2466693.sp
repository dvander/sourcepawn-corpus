/**
 * =============================================================================
 * Ready Up - Reloaded - Ready Up Period Timer (C)2015 Jessica "jess" Henderson
 * =============================================================================
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
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN
#undef REQUIRE_PLUGIN
#include "readyup.inc"

public Plugin:myinfo = { name = "readyup reloaded - ready up timer", author = "url", description = "readyup reloaded - ready up timer plugin", version = "timer alpha", url = "url", };

new Handle:h_ReadyUpTime;
new Handle:h_ReadyUpVote;
new bool:bIsReadyUp;
new bool:bIsReady[MAXPLAYERS+1];
new i_ReadyUpTime;

public OnPluginStart() {

	CreateConVar("readyup_timer_version", PLUGIN_VERSION, "the version of the plugin.", CVAR_SHOW);

	h_ReadyUpTime	= CreateConVar("sm_readyup_timer_pregame","60","the amount of time the ready up period lasts after all clients have loaded.");
	h_ReadyUpVote	= CreateConVar("sm_readyup_timer_readyup","1","do we let players say !ready to toggle ready on and off.");
	RegConsoleCmd("ready", cmd_ToggleReadyStatus);

	LoadTranslations("readyup_timer.phrases");
}

public OnPluginEnd() {

	OnReadyUpEndAllow();	// This plugin is unloading so I want to make sure the ready up core plugin is allowed to fire OnReadyUpEnd() in order to prevent the ready up period from never-ending.
}

public Action:cmd_ToggleReadyStatus(client, args) {		// This function lets the player toggle their ready status.

	if (bIsReadyUp && GetConVarInt(h_ReadyUpVote) == 1) {

		if (bIsReady[client]) { bIsReady[client]	= false; } else { bIsReady[client]	= true; }
	}
	return Plugin_Handled;
}

public OnRoundStart() {		// All in-game clients will have their ready status reset to not-ready when the round begins, so they're not automatically ready when the next ready up period begins.

	PrintToChatAll("%t", "the game is afoot");

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i)) bIsReady[i]		= false;
	}
}

public OnConfigsExecuted() {

	AutoExecConfig(true, "readyup_timer");	// If we do it OnPluginStart(), it won't update to any changes made in the config after the plugin initializes for the first time.
}

public OnClientDisconnect(client) {	// The client is still in-game when disconnecting; this occurs when a map ends, too. Set their status to not-ready before the next map loads.

	bIsReady[client]	= false;
}

public OnReadyUpStart() {

	/*


				Now that all of the players have loaded into the game, we can begin the readyup timer.
				Note:	Each time the ready up timer counts down, it'll check to see if all players are ready.
						It will not check each time an individual player changes their ready status.
						The ready up period ends when all players are ready or when the timer reaches 0.
	*/
	i_ReadyUpTime	= GetConVarInt(h_ReadyUpTime);
	if (i_ReadyUpTime < 1) {	// It's disabled in the plugin config, I guess.

		// If the time is 0, when all clients load, we allow the players to exit.
		bIsReadyUp	= false;
		OnReadyUpEndEx();

		//SetFailState("Ready Up Time must be a value greater than 0.");
	} else {

		bIsReadyUp	= true;
		OnReadyUpEndBlock();
		CreateTimer(1.0, timer_ReadyUpEnd, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timer_ReadyUpEnd(Handle:timer) {

	if (bIsReadyUp) {	//	Display a hint message to players about ready up time stuffs.

		i_ReadyUpTime--;
		new readyPlayers	= 0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && bIsReady[i]) { readyPlayers++; }
		}
		new totalPlayers	= 0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i)) { totalPlayers++; }
		}
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i)) {

				if (GetConVarInt(h_ReadyUpVote) == 1) {		// Let's use translations.

					if (bIsReady[i]) { PrintHintText(i, "%T", "ready up period - ready", i, i_ReadyUpTime, readyPlayers, totalPlayers); }
					else { PrintHintText(i, "%T", "ready up period - not ready", i, i_ReadyUpTime, readyPlayers, totalPlayers); }
				}
				else { PrintHintTextToAll("%t", "ready up period", i_ReadyUpTime); }
			}
		}
		if (i_ReadyUpTime < 1 || readyPlayers == totalPlayers || totalPlayers < 1) {	// Prevent players from changing their ready status and force the core plugin to fire OnReadyUpEnd.

			bIsReadyUp	= false;
			OnReadyUpEndEx();
		}
		else return Plugin_Continue;
	}
	return Plugin_Stop;
}

public OnReadyUpEnd() {

	PrintToChatAll("%t", "ready up end");
}