/*
*	Transition Level Fix
*	Copyright (C) 2024 Silvers
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



#define PLUGIN_VERSION		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Transition Level Fix
*	Author	:	SilverShot
*	Descrp	:	If the round fails to end, teleports Survivors to a clear area inside the saferoom 1.5 seconds after the door closes with all Survivors inside.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=344678
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (25-Mar-2024)
	- More accurate detection of players within the saferoom. Requires Left4DHooks version 1.144 or newer.
	- Now checks on Survivor death if the saferoom door is closed and all Survivors are inside.

1.1 (20-Dec-2023)
	- Fixed teleporting after a mission change. Thanks to "JustMadMan" for reporting.

1.0 (27-Nov-2023)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

// After the saferoom is closed, wait this long before teleporting players. To avoid them being visually being teleported as the screen blurs, 1.5 seconds seems good.
#define DELAY_TELEPORT		1.5

Handle g_hTimer;
bool g_bMapLoaded;
bool g_bRoundStart;
bool g_bLateLoad;
int g_iChangeLevel = -1;
int g_iSaferoomDoor = -1;
float g_vPos[3];



// ====================================================================================================
//					PLUGIN
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Transition Level Fix",
	author = "SilverShot",
	description = "Teleports Survivors to the center of a saferoom 1.5 seconds after the door closes, if the round fails to end.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344678"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
    if( GetFeatureStatus(FeatureType_Native, "Left4DHooks_Version") != FeatureStatus_Available || Left4DHooks_Version() < 1144 )
		SetFailState("\n==========\nThis plugin requires 'Left 4 DHooks' version 1.139 or newer. Please update that plugin.\n==========");
}

public void OnPluginStart()
{
	HookEvent("map_transition",	Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start",	Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death",	Event_PlayerDeath, EventHookMode_PostNoCopy);

	if( g_bLateLoad )
		StartMap();

	CreateConVar("l4d_transition_level_version", PLUGIN_VERSION, "Transition Level Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnMapStart()
{
	if( g_bRoundStart && !g_bMapLoaded ) // Sometimes round_start happens before OnMapStart
		StartMap();

	g_bMapLoaded = true;
	delete g_hTimer;
}

public void OnMapEnd()
{
	g_bMapLoaded = false;
	g_bRoundStart = false;
	delete g_hTimer;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bMapLoaded && !g_bRoundStart )
		StartMap();

	g_bRoundStart = true;
	delete g_hTimer;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStart = false;
	delete g_hTimer;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if( EntRefToEntIndex(g_iSaferoomDoor) != INVALID_ENT_REFERENCE && GetEntProp(g_iSaferoomDoor, Prop_Data, "m_eDoorState") == DOOR_STATE_CLOSED && IsEveryoneInside() )
	{
		delete g_hTimer;
		g_hTimer = CreateTimer(DELAY_TELEPORT, TimerEndMission);
	}
}

void StartMap()
{
	if( L4D_IsMissionFinalMap() ) return;

	// Find end saferoom door
	g_iSaferoomDoor = L4D_GetCheckpointLast();
	if( g_iSaferoomDoor != INVALID_ENT_REFERENCE )
	{
		// Hook door
		HookSingleEntityOutput(g_iSaferoomDoor, "OnFullyClosed", OnFullyClosed);
		g_iSaferoomDoor = EntIndexToEntRef(g_iSaferoomDoor);

		// Get saferoom size
		g_iChangeLevel = FindEntityByClassname(-1, "info_changelevel");
		if( g_iChangeLevel != INVALID_ENT_REFERENCE )
		{
			float vMin[3], vMax[3];
			GetEntPropVector(g_iChangeLevel, Prop_Data, "m_vecMaxs", vMax);
			GetEntPropVector(g_iChangeLevel, Prop_Data, "m_vecMins", vMin);
			g_iChangeLevel = EntIndexToEntRef(g_iChangeLevel);

			// Get center of "info_changelevel"
			SubtractVectors(vMax, vMin, g_vPos);
			g_vPos[0] = vMax[0] - (g_vPos[0] / 2);
			g_vPos[1] = vMax[1] - (g_vPos[1] / 2);
			g_vPos[2] = vMax[2] - (g_vPos[2] / 2);

			/* DEBUG:
			// Get "m_vecMaxs" / "m_vecMins" size
			SubtractVectors(g_vMin, g_vPos, g_vMin);
			SubtractVectors(g_vMax, g_vPos, g_vMax);

			PrintToChatAll("A %f %f %f", g_vPos[0], g_vPos[1], g_vPos[2]);
			PrintToChatAll("B %f %f %f", g_vMax[0], g_vMax[1], g_vMax[2]);
			PrintToChatAll("C %f %f %f", g_vMin[0], g_vMin[1], g_vMin[2]);
			// */
		}
	}
}

void OnFullyClosed(const char[] output, int caller, int activator, float delay)
{
	if( IsEveryoneInside() )
	{
		delete g_hTimer;
		g_hTimer = CreateTimer(DELAY_TELEPORT, TimerEndMission);
	}
}

bool IsEveryoneInside()
{
	if( EntRefToEntIndex(g_iChangeLevel) == INVALID_ENT_REFERENCE )
		return false;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			if( !L4D_IsTouchingTrigger(g_iChangeLevel, i) )
			{
				return false;
			}
		}
	}

	return true;
}

// Round hasn't ended, teleport everyone to center
Action TimerEndMission(Handle timer)
{
	g_hTimer = null;

	int area = L4D_GetNearestNavArea(g_vPos, 50.0);
	if( !area ) area = L4D_GetNearestNavArea(g_vPos, 100.0);
	if( !area ) area = L4D_GetNearestNavArea(g_vPos, 200.0);
	if( !area ) area = L4D_GetNearestNavArea(g_vPos, 300.0);
	if( !area ) area = L4D_GetNearestNavArea(g_vPos, 500.0);

	if( area  )
	{
		L4D_FindRandomSpot(area, g_vPos);
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			TeleportEntity(i, g_vPos, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		}
	}

	return Plugin_Continue;
}