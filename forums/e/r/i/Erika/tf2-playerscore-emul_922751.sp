/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod TF2 "player_score" event emulation Plugin
 * Provides "player_score" event for SourceMod and Source engine.
 *
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
 * Author: ErikaDH <r.i.k@free.fr>
 * Release on: 2009-09-04
 * Version: 1.0.0.0
 * License: GPL-v3
 */


#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

public Plugin:myinfo =
{
	name = "TF2 \"player_score\" Emul",
	author = "ErikaDH",
	description = "TF2 \"player_score\" event emulation",
	version = "1.0.0.0",
	url = ""
}

new bool:plugin_is_loaded = false ;
 
public OnPluginStart()
{
	// Perform one-time startup tasks ...
	plugin_is_loaded = true ;

	HookEvent("player_death", Event_PlayerScore) ;					// When a player dies
	HookEvent("player_escort_score", Event_PlayerScore) ;			// When a player escorts the payload
//	HookEvent("entity_killed", Event_PlayerScore) ;					// Redundant with "player_death"
//	HookEvent("break_breakable", Event_PlayerScore) ;
//	HookEvent("break_prop", Event_PlayerScore) ;
	HookEvent("teamplay_point_captured", Event_PlayerScore) ;		// When a player captures a point
	HookEvent("teamplay_capture_blocked", Event_PlayerScore) ;		// When a player blocks a capture
	HookEvent("object_destroyed", Event_PlayerScore) ;				// When a player destroys an object (ie, afaik in TF2, engineer's buildings) 
}

public OnConfigsExecuted()
{
	if (plugin_is_loaded)
	{
		// We log this string now, because on server start, 
		// the plugin is loaded before the activation of the server logs, thus not appearing in it
		LogToGame("[tf2-playerscore-emul.smx] plugin loaded") ;
	}
}

public OnPluginEnd()
{
	// Perform one-time unload tasks ...
	LogToGame("[tf2-playerscore-emul.smx] plugin unloaded") ;

	plugin_is_loaded = false ;
}

public Event_PlayerScore(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(name, "player_death"))
	{
		new attacker = GetEventInt(event, "attacker") ;
		new assister = GetEventInt(event, "assister") ;

		LogPlayerScore(attacker) ;
		LogPlayerScore(assister) ;

		return ;
	}
	else if (StrEqual(name, "player_escort_score"))
	{
		LogPlayerScore(GetClientUserId(GetEventInt(event, "player"))) ;

		return ;
	}

	else if (StrEqual(name, "teamplay_point_captured"))
	{
		decl String:cappers[MAXPLAYERS+1] ;
		GetEventString(event, "cappers", cappers, sizeof(cappers)) ;

		new num_cappers = strlen(cappers) ;

		for (new i=0; i<num_cappers; i++)
		{
			new capper = GetClientUserId(cappers{i}) ;

			LogPlayerScore(capper) ;
		}

		return ;
	}

	else if (StrEqual(name, "teamplay_capture_blocked"))
	{
		new blocker = GetClientUserId(GetEventInt(event, "blocker")) ;

		LogPlayerScore(blocker) ;

		return ;
	}

	// Redundant with "player_death", but present in case of use in special cases
	else if (StrEqual(name, "entity_killed"))
	{
		new attacker = GetClientUserId(GetEventInt(event, "entindex_attacker")) ;

		LogPlayerScore(attacker) ;

		return ;
	}

	else if (StrEqual(name, "object_destroyed"))
	{
		new attacker = GetEventInt(event, "attacker") ;
		new assister = GetEventInt(event, "assister") ;

		// When there's no assister, Source engine returns 0 instead of -1 !!!
		if (assister == 0)
		{
			assister = -1 ;
		}

		LogPlayerScore(attacker) ;
		LogPlayerScore(assister) ;

		return ;
	}
	
	else
	{
		LogToGame("[tf2-playerscore-emul.smx] unmanaged event fired : %s", name) ;
		return ;
	}
}

public Action:_LogPlayerScore(Handle:timer, any:userid)
{
	// Invalid UserID
	if (userid == -1)
	{
		return ;
	}

	new client = GetClientOfUserId(userid) ;

	decl String:user_name[255] ;
	GetClientName(client, user_name, sizeof(user_name)) ;

	new user_slot = userid ; // the "slot" (as shown in the logs after the player name) is the "userid", not the "client" !

	decl String:user_auth[32] ;
	GetClientAuthString(client, user_auth, sizeof(user_auth)) ;

	decl String:user_team[16] ;
	GetTeamName(GetClientTeam(client), user_team, sizeof(user_team)) ;

	new user_score = GetPlayerScore(client) ;

	LogToGame("\"%s<%d><%s><%s>\" current score \"%d\"", user_name, user_slot, user_auth, user_team, user_score) ; 

	// Create a "player_score" event
	// (force the creation even if the event is not hooked by Sourcemod, in order to have it available by Source plugins)
	new Handle:event = CreateEvent("player_score", true) ;

	if (event == INVALID_HANDLE)
	{
		LogToGame("Cannot create a \"player_score\" event") ;
		return ;
	}
 
	SetEventInt(event, "userid", userid) ;
	SetEventInt(event, "kills",  GetClientFrags(client)) ;
	SetEventInt(event, "deaths", GetClientDeaths(client)) ;
	SetEventInt(event, "score",  user_score) ;					// **Total** player score as shown in the client scoreboard

	// Fires the "player_score" event
	FireEvent(event) ;

	return ;	
}

public LogPlayerScore(userid)
{
	// Waits 1 seconds in order to get the "real" total score, and not the predicted one...
	CreateTimer(1.0, _LogPlayerScore, userid) ;
}

public GetPlayerScore(client)
{
	// All the difficult in getting the **total** player score in Source plugins is resolved by this (Sourcemod) function ;-)
	return TF2_GetPlayerResourceData(client, TFResource_TotalScore) ;
}

