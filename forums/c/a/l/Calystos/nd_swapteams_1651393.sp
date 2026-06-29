/*
---------------------------------------------------------------------------------------------
-File:

nd_swapteams.sp

---------------------------------------------------------------------------------------------
-License:

Nuclear Dawn: Team Swapping/Balancing/Scrambling System
Copyright (C) 2011 Calystos

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License, version 3.0, as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

As a special exception, AlliedModders LLC gives you permission to link the
code of this program (as well as its derivative works) to "Half-Life 2," the
"Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
by the Valve Corporation.  You must obey the GNU General Public License in
all respects for all other code used.  Additionally, AlliedModders LLC grants
this exception to all derivative works.  AlliedModders LLC defines further
exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
or <http://www.sourcemod.net/license.php>.

---------------------------------------------------------------------------------------------
-Console Variables:

---------------------------------------------------------------------------------------------
-Admin Commands (default admin flag: 'b'):

---------------------------------------------------------------------------------------------
-Player Commands:

---------------------------------------------------------------------------------------------
-Command Overrides:

---------------------------------------------------------------------------------------------
-Admin Menu (default admin flag: 'b'):

---------------------------------------------------------------------------------------------
-ToDo:
	Would be good to also check & reset players other info when swapping too.
	Add voting options.
	Add menu options.
	Find way to NOT swap at map end, only between rounds.
	Possibly use temp boolean value check, count total #rounds, when round over && counter reached then do NOT swap as map is over, etc.
	Add ability to remember & reassign teams (Alpha, Bravo, Charlie, Delta)

---------------------------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <nucleardawn>

#define AUTOUPDATE_DEV		0
#define AUTOUPDATE_ENABLE	1

//Auto update
#include <updater>
#if AUTOUPDATE_DEV
	#define UPDATE_URL "http://pnx.jrnetwork.net/source_plugins/dev/nd_swapteams.txt"
#else
	#define UPDATE_URL "http://pnx.jrnetwork.net/source_plugins/nd_swapteams.txt"
#endif

#define PLUGIN_VERSION "1.0.11"

public Plugin:myinfo = {
	name		= "[ND] SwapTeams",
	author		= "Calystos (Based on Senseless' nd_round_teamswap)",
	description	= "Swap teams at round end or on admin/vote command.",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net"
};

new map_end;

#if AUTOUPDATE_ENABLE
// Called when a new API library is loaded. Used to register BC auto-updating.
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
#endif

public OnPluginStart()
{
	// Initialise the round/map end check, dirty hack but will do for now
	map_end = 0;

	// Hook the required round end/win
	HookEvent("round_win", event_RoundEnd, EventHookMode_PostNoCopy);

	// Set a console command for admin usage
	RegAdminCmd("sm_swapteams", Command_ForceTeamSwitch, ADMFLAG_CHANGEMAP, "sm_swapteams - Swap Teams for all players.");

	// Log that we're loaded
	LogMessage("[ND SwapTeams] - Loaded");
}

public OnMapStart()
{
	// Initialise the round/map end check, dirty hack but will do for now
	map_end = 0;
}

public event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If map ended, no point swapping again since next map will be starting soon so just exit the function
	if (map_end == 1)
	{
		map_end = 0;
		return;
	}

	PrintToChatAll("\x01\x04[SM]\x01 Round Ended: Swapping Teams");
	LogMessage("[ND SwapTeams] Round Ended Swapping teams");

	// Check against team balancer plugin
	if (FindConVar("sm_nd_balancer_enable")) { SetConVarInt(FindConVar("sm_nd_balancer_enable"), 0, false, false); }

	// Swap the teams
	for (new i = 1; i <= MaxClients; i++)
	{
		// Only swap real players (also not spectators!), not bots as bots get stuck & confused otherwise
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			// time delayed team swap goes here to hopefully stop death counters
			PerformTimedSwitch(i);
	}

	// Swap the scores
	new ts = GetTeamScore(TEAM_ONE);
	SetTeamScore(TEAM_ONE, GetTeamScore(TEAM_TWO));
	SetTeamScore(TEAM_TWO, ts);

	// Check against team balancer plugin
	if (FindConVar("sm_nd_balancer_enable")) { SetConVarInt(FindConVar("sm_nd_balancer_enable"), 1, false, false); }

	map_end = 1;
	LogMessage("[ND SwapTeams] Round Ended Swapped teams");
}

void:PerformTimedSwitch(client)
{
	CreateTimer(0.5, Timer_TeamSwitch, client);
}

public Action:Timer_TeamSwitch(Handle:timer, any:client)
{
	// Only perform switch if client is playing (eg not spectator)
	if (IsClientInGame(client))
		Perform_TeamSwitch(client);
	return Plugin_Stop;
}

public Action:Command_ForceTeamSwitch(client, args)
{
	PrintToChatAll("\x01\x04[SM]\x01 Swapping Teams");
	LogMessage("[ND SwapTeams] Swapping teams");
	new team_one_cmdr, team_two_cmdr;
	new iscmdr_one = 0, iscmdr_two = 0;
	new ND_Squad:squad;

	// Safety check to swap commanders too since this is not an end-of-round teamswap
	team_one_cmdr = ND_GetCommander(TEAM_ONE);
	team_two_cmdr = ND_GetCommander(TEAM_TWO);

	for (new i = 1; i <= MaxClients; i++)
	{
		// Check if valid client
		if (IsClientConnected(i) && IsClientInGame(i)) // && !IsFakeClient(i))
		{
			// Temp demote Commanders (if any)
			if (team_one_cmdr == i) { ND_DemoteCommander(TEAM_ONE); iscmdr_one = 1; }
			if (team_two_cmdr == i) { ND_DemoteCommander(TEAM_TWO); iscmdr_two = 1; }
		}
	}

	// Loop through the clients list & swap valid players (those ingame & faction selected, not spectators/etc)
	for (new i = 1; i <= MaxClients; i++)
	{
		// Check if valid client
		if (IsClientConnected(i) && IsClientInGame(i)) // && !IsFakeClient(i))
		{
			// Backup client squad
			squad = ND_GetPlayerSquad(i);

			// Swap the player to the other faction/team
			Perform_TeamSwitch(i);

			// Restore client squad	#
			ND_SetPlayerSquad(i, squad);
		}
	}

	// Repromote Commanders (if any)
	if (iscmdr_one) { ND_PromoteToCommander(team_one_cmdr); }
	if (iscmdr_two) { ND_PromoteToCommander(team_two_cmdr); }
}
