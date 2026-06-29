/**
 * =============================================================================
 * Bot Controller (C)2015 Jessica "jess" Henderson
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
#include <sdktools>

#undef REQUIRE_PLUGIN
#include "botcontrol.inc"

new Handle:hSurvivorLimit;
new Handle:hInfectedLimit;
new Handle:hSurvivorMinimum;
new Handle:hReserveSlots;
new Handle:hPlayerSlots;
new Handle:hReserveDelay;
new Handle:hPreserveTeams;
new Handle:hTankHealthModifier;
new Handle:hTankHealthBase;
new bIsTeamsFlippedLast;
new iClientTeam[MAXPLAYERS+1];
new Handle:hExtraMedkits;
new bool:bIsActiveRound;
new Handle:h_hideSteamgroup;
new Handle:h_AssignTeams;

public OnConfigsExecuted() { SetConVarFlags(h_hideSteamgroup, GetConVarFlags(h_hideSteamgroup) & ~FCVAR_NOTIFY); }

public Plugin:myinfo = { name = "Bot Controller - Config", author = "jess", description = "Adds CVars to the Bot Controller Framework", version = "oregano", url = "forums.alliedmods.net/showthread.php?t=275726", };

public OnPluginStart() {

 	/*


 			This plugin will create cvars for survivor & infected team maximums, total playable
 			server maximum, and reserve slots.
 			What it will NOT do is set your servers actual maximum slots. Please do this in the
 			server.cfg or on the commandline (+maxplayers) and set the value to the combined total
 			of 32 (engine maximum) or hReserveSlots + hPlayerSlots as this combined value is the
 			maximum number of players the plugin itself will ever allow in the server at once and
 			hReserveSlots are only temporary slots, meant to remain open to players who have the
 			flags associated (root & reserve) can always access the server, even when hPlayerSlots
 			have been reached.

 			Feel free to of course edit the cvars - Doing so will NOT affect the plugin
 			functionality.


 	*/
 	CreateConVar("sbc_config_version", "dev-c", "the version of the plugin.");
 	/* Just remove these two lines if you want this variable to show to everyone. */
 	h_hideSteamgroup = FindConVar("sv_steamgroup");
	SetConVarFlags(h_hideSteamgroup, GetConVarFlags(h_hideSteamgroup) & ~FCVAR_NOTIFY);
 	hSurvivorLimit		= CreateConVar("sm_survivor_limit","4","the maximum players that can be on the survivor team.");
 	hInfectedLimit		= CreateConVar("sm_infected_limit","4","the maximum players that can be on the infected team.");
 	hSurvivorMinimum	= CreateConVar("sm_survivor_minimum","4","the minimum number of survivor players (bots make the difference) that have to exist.");
 	hReserveSlots		= CreateConVar("sm_reserveslots","2","the number of reserve slots.");
 	hPlayerSlots		= CreateConVar("sm_playerslots","8","the maximum amount that can actually play - should probably reflect survivor/infected limit settings.");
 	hReserveDelay		= CreateConVar("sm_reserveslots_delay","30","Players selected to be removed for reserve slot players will be given this much notice. 0 is instant-kick.");
 	hTankHealthModifier = CreateConVar("sm_tank_health_modifier","1500","The health (per survivor) to give the tank. Set to 0 to disable.");
 	hTankHealthBase		= CreateConVar("sm_tank_health","6000","The base health for tanks. 0 to Disable.");
 	hPreserveTeams		= CreateConVar("sm_preserve_teams","1","If 1 we will ensure teams do not scramble on map change.");
 	hExtraMedkits		= CreateConVar("sm_extrameds","1","If 1, players who join the survivor team before players leave the safe room receive medkits.");
 	h_AssignTeams		= CreateConVar("sm_assign_teams","1","If 1, teams will be auto-assigned, and even teams will have a player randomly assigned. Can disable if another plugin handles this.")

 	HookConVarChange(hSurvivorLimit, TeamSlotManagement);
 	HookConVarChange(hInfectedLimit, TeamSlotManagement);
 	HookConVarChange(hSurvivorMinimum, TeamSlotManagement);

 	HookConVarChange(hReserveSlots, ReserveSlotManagement);
 	HookConVarChange(hPlayerSlots, ReserveSlotManagement);
 	HookConVarChange(hReserveDelay, ReserveSlotManagement);

 	HookEvent("player_spawn", eventTankSpawn);
 	HookEvent("round_end", eventRoundEnd);
}

public OnAnyClientLoaded(client) {

	if (GetConVarInt(h_AssignTeams) == 0) return;
	if (GetConVarInt(hPreserveTeams) == 1 && iClientTeam[client] > 1) {		// Spectators will always re-assign as Spectators.

		new bIsTeamsFlipped = GameRules_GetProp("m_bAreTeamsFlipped");
		if (bIsTeamsFlipped == bIsTeamsFlippedLast && iClientTeam[client] != GetClientTeam(client)) { iClientTeam[client] = GetClientTeam(client); }
		if (bIsTeamsFlipped != bIsTeamsFlippedLast && iClientTeam[client] == GetClientTeam(client)) { if (iClientTeam[client] == 2) iClientTeam[client] = 3; else iClientTeam[client] = 2; }

		if (GetClientTeam(client) != iClientTeam[client]) {

			if (iClientTeam[client] == 2) OnJoinSurvivorTeam(client);
			else ChangeClientTeam(client, 3);
		}
	}
	else {

		/* Find the client a team when they join. */
		if (GetConVarInt(hInfectedLimit) < 1) OnJoinSurvivorTeam(client);
		else {

			new numSurvivors = ClientSurvivors();
			new numInfected = ClientInfected();

			if (numSurvivors > numInfected) ChangeClientTeam(client, 3);
			else if (numSurvivors < numInfected) OnJoinSurvivorTeam(client);
			else {

				if (GetRandomInt(1,100) > 50) OnJoinSurvivorTeam(client);
				else ChangeClientTeam(client, 3);
			}
		}
	}
}

public Action:L4D_OnFirstSurvivorLeftSafeArea(client) {

	if (!bIsActiveRound) bIsActiveRound = true;
}

public Action:eventRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (bIsActiveRound) bIsActiveRound = false;
}

/*


		The best way to change the tank health is after it spawns - tanks won't
		spawn with incorrect values.


*/
public Action:eventTankSpawn(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (GetConVarInt(hTankHealthModifier) > 0 || GetConVarInt(hTankHealthBase) > 0) {

		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8) {

			SetEntProp(client, Prop_Send, "m_iMaxHealth", GetConVarInt(hTankHealthBase) + TankHealthModifier());
		}
		SetEntityHealth(client, GetEntProp(client, Prop_Send, "m_iMaxHealth"));
	}
}

TankHealthModifier() {

	new health = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == 2) health += GetConVarInt(hTankHealthModifier);
	}
	return health;
}

public OnBotCreatedFwd(client, cNetProp, String:cModel[]) {

	/*


			The only thing we care about is the client, so we know whether to give them
			a medkit or not.


	*/

	if (GetConVarInt(hExtraMedkits) == 1 && !bIsActiveRound) {

		new iFlags = GetCommandFlags("give");
		SetCommandFlags("give", iFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give first_aid_kit");
		SetCommandFlags("give", iFlags);
		SetCommandFlags("give", iFlags|FCVAR_CHEAT);
	}
}

/*


		When the map is over, we store whether the teams are flipped - this way
		when we check a players team, with those two variables we can determine
		which team they should actually be on, if any (spectators)

		Running this check prevents us from having to track the score for each
		team.


*/
public OnMapEnd() {

	bIsTeamsFlippedLast = GameRules_GetProp("m_bAreTeamsFlipped");
}

/*


		Let's see if we can do it this way, instead of having to actually track
		scores.


*/
public OnClientDisconnect(client) {

	if (IsClientInGame(client) && !IsFakeClient(client)) {

		iClientTeam[client] = GetClientTeam(client);
	}
	else if (client > 0) iClientTeam[client] = 0;
}

/*


		The reason we want to call these natives every new map when the first
		client loads is this:

		HookConVarChange will not fire when the plugin loads - because those
		are the initial values. Executing the config won't do it either, unless
		one of the variables inside was changed in each of the Callbacks.

		Instead, to make sure it's always up to date with the settings, we check
		once per map.

		!--NOTE--!
		The OnFirstClientLoadedFwd() is officially added to the v1.4 branch of
		the Bot Controller Framework. That branch or newer is required for the
		Bot Controller Config plugin to work.


*/
public OnFirstClientLoadedFwd() {

	OnReserveSlotManagement(GetConVarInt(hReserveSlots), GetConVarInt(hPlayerSlots), GetConVarInt(hReserveDelay));
 	OnAllowReserveSlots();
 	SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(hPlayerSlots) + GetConVarInt(hReserveSlots));
 	OnSlotManagement(GetConVarInt(hSurvivorLimit), GetConVarInt(hInfectedLimit));
	OnSetSurvivorRequirements(GetConVarInt(hSurvivorMinimum), GetConVarInt(hSurvivorLimit));
}

/*


		This plugin manages reserve slots for the Bot Controller Framework.
		If this plugin is disabled in any way, it's extremely important that the
		OnBlockReserveSlots() native is called. There's potential for issues
		within the framework if it depends on a plugin to be controlling these
		values, but that plugin isn't enabled.


*/
public OnPluginEnd() { OnBlockReserveSlots(); }

/*


		If any of the cvars related to OnReserveSlotManagement() are changed, this
		Callback fires and then uses the OnReserveSlotManagement() native.


*/
public ReserveSlotManagement(Handle:cvar, const String:oldVal[], const String:newVal[]) {

 	OnReserveSlotManagement(GetConVarInt(hReserveSlots), GetConVarInt(hPlayerSlots), GetConVarInt(hReserveDelay));
 	OnAllowReserveSlots();
 	SetConVarInt(FindConVar("sv_visiblemaxplayers"), GetConVarInt(hPlayerSlots) + GetConVarInt(hReserveSlots));
}


/*


		If any of the cvars related to OnSlotManagement() are changed, this Callback
		fires and the OnSlotManagement() native fires.
		Since this information is also pertinent to survivor bots (the framework is in
		early development so I have not directly linked OnSetSurvivorRequirements() with
		OnSlotManagement(), and do not know if I will, for developer (flexibility) reasons)
		so we also send that out, as well.
*/
public TeamSlotManagement(Handle:cvar, const String:oldVal[], const String:newVal[]) {

	OnSlotManagement(GetConVarInt(hSurvivorLimit), GetConVarInt(hInfectedLimit));
	OnSetSurvivorRequirements(GetConVarInt(hSurvivorMinimum), GetConVarInt(hSurvivorLimit));
}

ClientSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) count++;
	}
	return count;
}

ClientInfected() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3) count++;
	}
	return count;
}