/**
 * =============================================================================
 * Ready Up - Reloaded - Core (C)2015 Jessica "jess" Henderson
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

#define INFECTED	3
#define SURVIVOR	2
#define SPECTATOR 	1

#define GAMEMODECOOP 1
#define GAMEMODEVERSUS 2
#define GAMEMODESURVIVAL 3
#define GAMEMODESCAVENGE 4

#define PLUGIN_VERSION "reloaded v1.a.1"
#define PLUGIN_LIBRARY "readyup"
#define CVAR_SHOW			FCVAR_NOTIFY | FCVAR_PLUGIN
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include "left4downtown.inc"

public Plugin:myinfo = { name = "readyup reloaded", author = "url", description = "readyup reloaded base plugin", version = PLUGIN_VERSION, url = "url", };

/*


							We need to create the handles that will handle each forward. And potentially, handle me.
							I need to figure out a way to create these dynamically.


*/
static Handle:hOnRoundStart		= INVALID_HANDLE;
static Handle:hOnRoundEnd		= INVALID_HANDLE;
static Handle:hOnFirstClientLoaded		= INVALID_HANDLE;
static Handle:hOnAllClientsLoaded		= INVALID_HANDLE;
static Handle:hOnReadyUpStart		= INVALID_HANDLE;
static Handle:hOnReadyUpEnd		= INVALID_HANDLE;
static Handle:hOnMapAboutToEnd	= INVALID_HANDLE;

/*


							Here, we create the other variables that are used throughout the plugin
							to keep order in the empire.


*/
new bool:bIsEndOfRound;
new bool:bIsFirstClientLoaded;
new bool:bIsAllClientsLoaded;
new bool:bIsReadyUpStart;
new bool:bIsReadyUpEnd;
new bool:bIsRoundStart;
new bool:bIsTeamsFlipped;
new bool:bIsMapEnd;
new bool:bIsReadyUpEndAllowed;
new bool:bIsWaitingForRoundToStart;
new bool:bIsClientDisconnecting[MAXPLAYERS+1];
new bool:bIsInViolation[MAXPLAYERS+1];
new i_ViolationTime[MAXPLAYERS+1];
new Float:f_pos[MAXPLAYERS+1][3];
new String:cfgSettingsCoop[64];
new String:cfgSettingsVersus[64];
new String:cfgSettingsSurvival[64];
new String:cfgPath[64];

public APLRes:AskPluginLoad2(Handle:g_Me, bool:b_IsLate, String:s_Error[], s_ErrorMaxSize) {

	if (LibraryExists(PLUGIN_LIBRARY)) {

		strcopy(s_Error, s_ErrorMaxSize, "Plugin Already Loaded");
		return APLRes_SilentFailure;
	}
	
	if (!IsDedicatedServer()) {

		strcopy(s_Error, s_ErrorMaxSize, "Listen Server Not Supported");
		return APLRes_Failure;
	}

	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false)) {

		strcopy(s_Error, s_ErrorMaxSize, "Game Not Supported");
		return APLRes_Failure;
	}

	RegPluginLibrary(PLUGIN_LIBRARY);
	hOnRoundStart						= CreateGlobalForward("OnRoundStart", ET_Ignore);
	hOnRoundEnd							= CreateGlobalForward("OnRoundEnd", ET_Ignore);
	hOnFirstClientLoaded				= CreateGlobalForward("OnFirstClientLoaded", ET_Ignore);
	hOnAllClientsLoaded					= CreateGlobalForward("OnAllClientsLoaded", ET_Ignore);
	hOnReadyUpStart						= CreateGlobalForward("OnReadyUpStart", ET_Ignore);
	hOnReadyUpEnd						= CreateGlobalForward("OnReadyUpEnd", ET_Ignore);
	hOnMapAboutToEnd					= CreateGlobalForward("OnMapAboutToEnd", ET_Ignore);

	/*


				I've created natives that allow other plugins to force the global forwards to fire.
				This can be done, repeatedly, but will only trigger this plugins base functionality in that way the first time.
				However, only specific forwards can be forced at this time. Maybe more later, maybe not, but it is self-explanatory
				on how to add them, yourself.
				Note: There are several forwards/natives, such as the OnReadyUpEnd forward & OnReadyUpEndEx native, which do not fire
				in the core plugin. However, they're included because they may be used in other plugins, such as the optional readyup plugin.
				The core plugin simply handles forwards, natives, and their management. All other jobs are now delegated to other plugins.

				Example:

				By default, OnReadyUpStart is called immediately after OnAllClientsLoaded is called. If another plugin forces
				OnReadyUpStart to fire before OnAllClientsLoaded is called, when OnAllClientsLoaded is called, OnReadyUpStart will
				not be called by the plugin, as that would trigger a redundancy.


	*/
	CreateNative("OnReadyUpStartEx", nativeOnReadyUpStart);
	CreateNative("OnReadyUpEndEx", nativeOnReadyUpEnd);
	CreateNative("OnReadyUpEndBlock", nativeOnReadyUpEndBlock);
	CreateNative("OnReadyUpEndAllow", nativeOnReadyUpEndAllow);

	return APLRes_Success;
}

public OnPluginStart() {

	CreateConVar("readyup_version", PLUGIN_VERSION, "the version of the plugin.", CVAR_SHOW);
	/*


				The following variable defaults to true.
				By default, ready up reload only provides natives, so it will not inherently stop players from exiting the safe area.
				If a plugin wishes to control player leaving, etc., it simply needs to call the OnReadyUpEndBlock() native.
				This will prevent players from exiting the saferoom until said plugin calls OnReadyUpEndAllow() native.


	*/
	bIsReadyUpEndAllowed	= true;
	HookEvent("map_transition", eventMapTransition);
	HookEvent("mission_lost", eventRoundEnd);
	HookEvent("round_end", eventRoundEnd);
	HookEvent("finale_win", eventRoundEnd);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("round_start", eventRoundStart);
}

public Action:eventMapTransition(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (RetrieveGamemode() != GAMEMODEVERSUS && !bIsEndOfRound) {

		Call_StartForward(hOnRoundEnd);
		Call_Finish();

		Call_StartForward(hOnMapAboutToEnd);
		Call_Finish();
	}
}

/*


			When a player spawns, we want to make sure they have no violation running, as well as
			grab their current position and start a timer that grabs their position every so often
			as long as OnReadyUpEnd() hasn't been called, so that if they leave the safe area, it
			will teleport them to their last known location within the safe area and not begin the round.
			Note:	This obviously only affects survivors.


*/
public Action:eventPlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast) {

	new client	= GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == SURVIVOR) {

		bIsInViolation[client]	= false;
		i_ViolationTime[client]		= 0;
		if (!bIsReadyUpEnd && !bIsRoundStart) {		// No reason to waste the processing if the ready up period has ended.

			GetClientAbsOrigin(client, f_pos[client]);
			CreateTimer(1.0, timer_GrabPlayerPosition, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// This timer repeats until OnReadyUpEnd() fires.
		}
	}
}

public Action:timer_GrabPlayerPosition(Handle:timer, any:client) {

	if (bIsReadyUpEnd) { return Plugin_Stop; }
	if (IsClientInGame(client) && !bIsInViolation[client]) { GetClientAbsOrigin(client, f_pos[client]); }
	return Plugin_Continue;
}

public OnMapEnd() {

	/*


				There are several variables that are reset during map transition, so that ready up can begin fresh
				when the next map loads. Otherwise, chaos?


	*/
	bIsEndOfRound	= true;
	bIsFirstClientLoaded	= false;
	bIsAllClientsLoaded		= false;
	bIsReadyUpStart		= false;
	bIsRoundStart	= false;
	bIsMapEnd	= true;
}

public OnMapStart() {

	/*


				We use this to let the plugin know that it's OKAY to start checking for
				all clients loaded ONLY when the map isn't over.


	*/
	bIsMapEnd	= false;
	bIsReadyUpEnd = false;
}

/*
			

			The round_start event is only used to track when a coop map restarts.


*/
public Action:eventRoundStart(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (bIsWaitingForRoundToStart && RetrieveGamemode() != GAMEMODEVERSUS) {
	
		bIsReadyUpStart		= true;
		bIsEndOfRound	= false;
		Call_StartForward(hOnReadyUpStart);
		Call_Finish();
	}
}

/*


			The following events handle round ending and starting for different game modes.
			Each one, of course, triggers the OnRoundEnd and OnRoundStart, appropriately.
			This keeps everything similar across game modes.


*/
public Action:eventRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (!bIsEndOfRound) {

		bIsEndOfRound	= true;
		bIsReadyUpStart		= false;
		bIsRoundStart	= false;
		bIsReadyUpEnd	= false;
		bIsWaitingForRoundToStart	= false;
		Call_StartForward(hOnRoundEnd);
		Call_Finish();

		/*


					The following timer is created when the round ends. It's so we know when the teams have
					swapped, and that's when we initiate the OnReadyUpStart forward and reset variables in
					this core plugin. We know it's the first round if the following statement is true. This
					is great, because it'll always be true in survival, and in versus survival, will act as
					intended.

					So, we only create the timer if the teams have actually swapped, which means in versus
					it will only fire at the end of the first half.


		*/
		if (RetrieveGamemode() != GAMEMODECOOP) {
		
			if (bIsTeamsFlipped == !!GameRules_GetProp("m_bAreTeamsFlipped", 4, 0)) {

				CreateTimer(0.1, timerIsTeamsFlipped, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else {

				//		if it's the second round of a versus map, call this forward. I added this one so the map
				//		rotation plugin could change maps early, if necessary.
				Call_StartForward(hOnMapAboutToEnd);
				Call_Finish();
			}
		}
		else {

			//		In coop, the mission_lost event comes here. Because the teams don't swap like in versus, I set a bool
			//		that, when true and round_start fires, will trigger OnReadyUpStart.
			bIsWaitingForRoundToStart	= true;
		}
	}
}

stock bool:IsAnySurvivorsRespawned() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && bIsRespawned[i]) return true;
	}
	return false;
}

public Action:timerIsTeamsFlipped(Handle:timer) {

	if (bIsTeamsFlipped == !!GameRules_GetProp("m_bAreTeamsFlipped", 4, 0)) { return Plugin_Continue; }
	
	bIsReadyUpStart		= true;
	bIsEndOfRound	= false;
	Call_StartForward(hOnReadyUpStart);
	Call_Finish();

	return Plugin_Stop;
}

/*


			I've decided to place this here, as it goes between the two important function calls that it directly
			represents. This forward is important; Thank-you, ProdigySim.
			We don't want the round to start if a player leaves the safe area before AllClientsLoaded() and
			IsReadyUpStart() has fired. We just ignore that the player exited, and teleport them back to the
			previous location where they were prior to leaving the area.


*/
public Action:L4D_OnFirstSurvivorLeftSafeArea(client) {

	if (!bIsReadyUpEnd && !bIsReadyUpEndAllowed) {

		/*
			The player has left the saferoom area, but there are still clients loading into the game!
			Shame on you, player! Teleport the player to their previous, in-saferoom location.
			Note:	No more locking players in place on the first map of campaigns or locking doors.
					This also means no more problems that occurred when locking doors, like the map
					not ending.
		*/
		bIsInViolation[client] = true;	// The players last known location will not be saved when this is true.
		i_ViolationTime[client]++;		// The player will not be removed from violation until this value reaches 0.
		TeleportEntity(client, f_pos[client], NULL_VECTOR, NULL_VECTOR);	// f_pos first obtained during player_spawn event.
		if (i_ViolationTime[client] < 2) {	// Will only fire the first time the player tries to leave the saferoom after their last known (if applicable) violation is cleared.

			CreateTimer(1.0, timer_IsPlayerInViolation, client, TIMER_FLAG_NO_MAPCHANGE);	// To find out if the player is still in violation.
		}

		return Plugin_Handled;	// And the round doesn't start. Sorry, Infected (or survivor troll)
	}
	else if (bIsReadyUpEndAllowed || bIsReadyUpEnd) {

		// A player left the start area, but all clients have loaded and ready up has started. end ready up, start the round.
		// The only reason we check if OnReadyUpEnd() has already fired is in-case an external plugin forced it.

		/*
			My goal with readyup reloaded is to give developers (which in turn gives server operators) more control over
			the ready up process. Therefor, if the desire to not end the ready up period until another plugin says to end
			it exists, it can be done by firing the OnReadyUpEndBlock() native.
			Note:	This only prevents this core plugin from firing OnReadyUpEnd(). It doesn't prevent another plugin from
			calling OnReadyUpEndEx() and forcing the core plugin to fire OnReadyUpEnd(), which is how another plugin must do
			it if the OnReadyUpEndBlock() native is called, otherwise the ready up period will never end and survivors will
			never be able to exit the saferoom.
		*/
		if (!bIsReadyUpEnd) {	// This is to make sure another plugin hasn't already forced OnReadyUpEnd().

			bIsReadyUpEnd	= true;
			Call_StartForward(hOnReadyUpEnd);
			Call_Finish();
		}
		if (!bIsRoundStart) {	// The ONLY TIME THE ROUND STARTS is when the player leaves the safe area AFTER OnReadyUpEnd() is called.

			bIsRoundStart	= true;
			Call_StartForward(hOnRoundStart);
			Call_Finish();
		}
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:timer_IsPlayerInViolation(Handle:timer, any:client) {

	if (bIsReadyUpEnd) { return Plugin_Stop; }
	if (IsClientInGame(client)) {

		i_ViolationTime[client]--;	// we do 1-second increments in case a player spam-runs against the edge of the safe area attempting to leave.
		if (i_ViolationTime[client] < 1) { bIsInViolation[client]	= false; } else { return Plugin_Continue; }
	}
	return Plugin_Stop;
}

public OnClientPostAdminCheck(client) {

	/*


				When the first player is fully in-game, I track it.
				Even if it's the first player, I also check to see if all clients have loaded.


	*/
	bIsClientDisconnecting[client]		= false;
	bIsInViolation[client]	= false;	// I want to make sure a client doesn't get stuck with this turned on. Will reset during player_spawn event as well.
	if (!bIsFirstClientLoaded) {

		bIsFirstClientLoaded	= true;
		Call_StartForward(hOnFirstClientLoaded);
		Call_Finish();
	}
	CheckIfAllClientsLoaded();
}

stock CheckIfAllClientsLoaded() {

	if (!bIsClientsLoading() && !bIsAllClientsLoaded && !bIsMapEnd) {

		bIsAllClientsLoaded		= true;
		Call_StartForward(hOnAllClientsLoaded);
		Call_Finish();

		/*


					This will only fire if another plugin has not previously called the OnReadyUpStart forward
					before the core plugin (this one) has called it, which ALWAYS happens immediately after OnAllClientsLoaded.


		*/
		if (!bIsReadyUpStart) {

			bIsReadyUpStart		= true;
			Call_StartForward(hOnReadyUpStart);
			Call_Finish();
		}
	}
}

/*


			I don't want players who are in the process of disconnecting to ever be considered a client
			that is currently loading into the game, in any kind of situation.


*/
public OnClientDisconnect(client) {

	bIsClientDisconnecting[client] = true;
	CheckIfAllClientsLoaded();
}
public OnClientConnected(client) { bIsClientDisconnecting[client] = false; }
/*


			I want to find out if there are any clients still loading into the game.
			I also want to ignore any players who are currently in the process of disconnecting from the server.


*/
stock bool:bIsClientsLoading() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientConnected(i) && !bIsClientDisconnecting[i] && !IsClientInGame(i)) return true;
	}
	return false;
}

/*


			Depending on the gamemode's accepted by the server in the base config, forwards will be called
			at different times due to different events firing. This is important.


*/

public nativeOnReadyUpStart(Handle:plugin, params) {

	if (!bIsReadyUpStart && !bIsReadyUpEnd) { bIsReadyUpStart		= true; }
	Call_StartForward(hOnReadyUpStart);
	Call_Finish();
}

public nativeOnReadyUpEnd(Handle:plugin, params) {

	if (!bIsReadyUpEnd && bIsReadyUpStart) {

		bIsReadyUpStart		= false;
		bIsReadyUpEnd	= true;

		Call_StartForward(hOnReadyUpEnd);
		Call_Finish();
	}
}

public nativeOnReadyUpEndBlock(Handle:plugin, params) {

	if (bIsReadyUpEndAllowed) { bIsReadyUpEndAllowed	= false; }
}

public nativeOnReadyUpEndAllow(Handle:plugin, params) {

	if (!bIsReadyUpEndAllowed) { bIsReadyUpEndAllowed	= true; }	// plugins that block should call the allow native if they unload for any reason to prevent ready up from never ending.
}

stock RetrieveGamemode() {

	decl String:serverGamemode[32];
	GetConVarString(FindConVar("mp_gamemode"), serverGamemode, sizeof(serverGamemode));

	if (StrContains(cfgSettingsCoop, serverGamemode, false) != -1) return 1;
	if (StrContains(cfgSettingsVersus, serverGamemode, false) != -1) return 2;
	if (StrContains(cfgSettingsSurvival, serverGamemode, false) != -1) return 3;
	SetFailState("Current gamemode cannot be found in %s", cfgPath);
	return 0;
}

/*


			OnConfigsExecuted is used, in this particular case, to parse a config file which details which
			gamemodes should be recognized as which game types. It checks if the config exists, and if it
			doesn't, attempts to create it. If this fails, we SetFailState, otherwise we continue as planned.


*/
public OnConfigsExecuted() {

	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "configs/rur_core.cfg");
	if (!FileExists(cfgPath)) { SetFailState("I cannot find %s and I really need this file...", cfgPath); }

	if (!ParseConfigFile(cfgPath)) { SetFailState("I cannot read %s properly. Please double-check the file formatting.", cfgPath); }

	SetConVarString(FindConVar("readyup_version"), PLUGIN_VERSION);
}

stock bool:ParseConfigFile(const String:file[]) {

	new Handle:hParser = SMC_CreateParser();
	new String:error[128];
	new line = 0;
	new col = 0;

	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);

	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay) {

		SMC_GetErrorString(result, error, sizeof(error));
		SetFailState("Problem reading %s, line %d, col %d - error: %s", file, line, col, error);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) { return SMCParse_Continue; }

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:ley_quotes, bool:value_quotes) {

	if (StrEqual(key, "coop_allowed")) Format(cfgSettingsCoop, sizeof(cfgSettingsCoop), "%s", value);
	else if (StrEqual(key, "versus_allowed")) Format(cfgSettingsVersus, sizeof(cfgSettingsCoop), "%s", value);
	else if (StrEqual(key, "survival_allowed")) Format(cfgSettingsSurvival, sizeof(cfgSettingsCoop), "%s", value);

	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) {

	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {

	if (failed) { SetFailState("Plugin configuration error"); }
}