/*
*	Scavenge Score Fix - Gascan Pouring
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"2.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Scavenge Score Fix - Gascan Pouring
*	Author	:	SilverShot
*	Descrp	:	Fixes the score / gascan pour count from increasing when plugins use the 'point_prop_use_target' entity.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=187686
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.1 (25-Feb-2021)
	- Fixed a mistake that would have broken the plugin if multiple 'point_prop_use_target' entities existed on the map.

2.0 (25-Feb-2021)
	- Completely changed the blocking method. Now requires DHooks to properly block the call and prevent score bugs.
	- Thanks to "Lux" for help with this method.

1.3 (10-May-2020)
	- Various changes to tidy up code.

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1 (10-Aug-2013)
	- Fixed a rare bug which could crash the server.

1.0 (16-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define MAX_NOZZLES				16
#define GAMEDATA				"l4d2_scavenge_score_fix"

int g_iCountNozzles, g_iLateLoad, g_iPlayerSpawn, g_iRoundStart, g_iNozzles[MAX_NOZZLES];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Scavenge Score Fix - Gascan Pouring",
	author = "SilverShot",
	description = "Fixes the score / gascan generator pour count from increasing when plugins use the 'point_prop_use_target' entity.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187686"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_iLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================
	// DETOUR
	// ====================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Handle hDetour = DHookCreateFromConf(hGameData, "CGasCan::OnActionComplete");

	if( !hDetour )
		SetFailState("Failed to find \"CGasCan::OnActionComplete\" signature.");

	if( !DHookEnableDetour(hDetour, false, OnActionComplete) )
		SetFailState("Failed to detour \"CGasCan::OnActionComplete\".");

	delete hDetour;
	delete hGameData;

	// ====================
	// CVAR / EVENTS
	// ====================
	CreateConVar("l4d2_scavenge_score_fix",		PLUGIN_VERSION,		"Gascan Pour Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("round_end",						Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",					Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_spawn",					Event_PlayerSpawn,	EventHookMode_PostNoCopy);

	if( g_iLateLoad )
		FindPropUseTarget();
}



// ====================================================================================================
// DETOUR
// ====================================================================================================
public MRESReturn OnActionComplete(int pThis, Handle hReturn, Handle hParams)
{
	int entity = DHookGetParam(hParams, 2);
	entity = EntIndexToEntRef(entity);

	// Do we have to block?
	for( int i = 0; i < MAX_NOZZLES; i++ )
	{
		if( IsValidEntRef(g_iNozzles[i]) )
		{
			// Pouring into scavenge target? Allow
			for( int x = 0; x < MAX_NOZZLES; x++ )
			{
				if( g_iNozzles[x] == entity )
				{
					// PrintToChatAll("GCasCan Scavenge: Allowed");
					return MRES_Ignored;
				}
			}
		}
	}

	// ====================
	// BLOCK
	// ====================
	int client = DHookGetParam(hParams, 1);
	// PrintToChatAll("GCasCan Scavenge: Blocked");

	// Fire event
	Event hEvent = CreateEvent("gascan_pour_completed", true);
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.Fire();
	}

	// Fire output
	FireEntityOutput(entity, "OnUseFinished", client);

	// Block call
	DHookSetReturn(hReturn, 0);
	return MRES_Supercede;
}



// ====================================================================================================
// FIND point_prop_use_target
// ====================================================================================================
public void OnMapEnd()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		FindPropUseTarget();
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		FindPropUseTarget();
	g_iPlayerSpawn = 1;
}

void FindPropUseTarget()
{
	g_iCountNozzles = 0;

	for( int i = 0; i < MAX_NOZZLES; i++ )
		g_iNozzles[i] = 0;

	int entity = -1;
	while( g_iCountNozzles < MAX_NOZZLES && (entity = FindEntityByClassname(entity, "point_prop_use_target")) != INVALID_ENT_REFERENCE )
	{
		g_iNozzles[g_iCountNozzles++] = EntIndexToEntRef(entity);
	}
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}



// ====================================================================================================
// OLD METHOD - LEFT HERE FOR DEMONSTRATION PURPOSES - NO LONGER WORKS
// ====================================================================================================
/*
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MAX_NOZZLES 16

int g_iCountNozzles, g_iLateLoad, g_iPlayerSpawn, g_iPrevented, g_iRoundStart, g_iNozzles[MAX_NOZZLES], g_iPouring[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Scavenge Score Fix - Gascan Pouring",
	author = "SilverShot",
	description = "Fixes the score / gascan generator pour count from increasing when plugins use the 'point_prop_use_target' entity.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=187686"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_iLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_scavenge_score_fix",		PLUGIN_VERSION,		"Gascan Pour Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_spawn",				Event_PlayerSpawn,	EventHookMode_PostNoCopy);
	HookEvent("gascan_pour_completed",		Event_PourGasDone,	EventHookMode_Pre);

	if( g_iLateLoad )
		FindPropUseTarget();
}

public void OnMapEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
		g_iPouring[i] = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		g_iPouring[i] = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		FindPropUseTarget();
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		FindPropUseTarget();
	g_iPlayerSpawn = 1;
}

void FindPropUseTarget()
{
	g_iPrevented = 0;
	g_iCountNozzles = 0;

	for( int i = 1; i <= MaxClients; i++ )
		g_iPouring[i] = 0;

	for( int i = 0; i < MAX_NOZZLES; i++ )
		g_iNozzles[i] = 0;

	int entity = -1;
	while( g_iCountNozzles < MAX_NOZZLES && (entity = FindEntityByClassname(entity, "point_prop_use_target")) != INVALID_ENT_REFERENCE )
	{
		g_iNozzles[g_iCountNozzles++] = EntIndexToEntRef(entity);
		HookSingleEntityOutput(entity, "OnUseStarted", OnUseStarted);
		HookSingleEntityOutput(entity, "OnUseCancelled", OnUseCancelled);
	}
}

public void OnUseStarted(const char[] output, int caller, int activator, float delay)
{
	int weapon = GetEntPropEnt(caller, Prop_Send, "m_useActionOwner");
	if( weapon > 0 && IsValidEntity(weapon) )
	{
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if( client > 0 && client <= MaxClients )
			g_iPouring[client] = EntIndexToEntRef(caller);
	}
}

public void OnUseCancelled(const char[] output, int caller, int activator, float delay)
{
	caller = EntIndexToEntRef(caller);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( g_iPouring[i] == caller )
		{
			g_iPouring[i] = 0;
			break;
		}
	}
}

public Action Event_PourGasDone(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCountNozzles == 0 )
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	// Allow, legit pouring
	if( g_iPouring[client] != 0 )
	{
		if( g_iPrevented )
		{
			int left = GameRules_GetProp("m_nScavengeItemsRemaining");
			GameRules_SetProp("m_nScavengeItemsRemaining", left + g_iPrevented, 0, 0, true);
		}

		g_iPouring[client] = 0;
		return Plugin_Continue;
	}

	// Do we have to block?
	bool valid;
	for( int i = 0; i < MAX_NOZZLES; i++ )
	{
		if( IsValidEntRef(g_iNozzles[i]) )
		{
			valid = true;
			break;
		}
	}

	// No
	if( valid == false )
	{
		return Plugin_Continue;
	}

	// Yes, prevent score bugs.
	int flip = GameRules_GetProp("m_bAreTeamsFlipped");
	int done = GameRules_GetProp("m_iScavengeTeamScore", 4, flip);
	if( done > 0 )
	{
		g_iPrevented++;
		int left = GameRules_GetProp("m_nScavengeItemsRemaining");
		if( left > 0 )
		{
			float time = GameRules_GetPropFloat("m_flAccumulatedTime");
			GameRules_SetProp("m_iScavengeTeamScore", done - 1, 4, flip, false);
			GameRules_SetProp("m_nScavengeItemsRemaining", left + g_iPrevented, 4, 0, true);
			GameRules_SetPropFloat("m_flAccumulatedTime", time - 20.0);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}
// */