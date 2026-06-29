/*
 * ============================================================================
 *
 *  File:			NoMercyElevatorFix.sp
 *  Description:	Provides a work around for the current bug with players
 *					falling through the elevator on No Mercy.
 *
 *  Copyright (C) 2010  Mr. Zero <mrzerodk@gmail.com>
 *
 *  No Mercy Elevator Fix is free software: you can redistribute it and/or 
 *  modify it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  No Mercy Elevator Fix is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with No Mercy Elevator Fix.  If not, see 
 *  <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#define PLUGIN_VERSION	"1.0"
#define TEAM_SURVIVOR 2
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

static	const	char	NO_MERCY_MAP4[] = "c8m4_interior";

static	const	char 	ELEVATOR_BUTTON[] = "elevator_button";
static	const	char 	ELEVATOR_DOORS_LOW[] = "door_elevouterlow";
static	const	char	ELEVATOR_DOORS_HIGH[] = "door_elevouterhigh";
static	const	char	ELEVATOR_FLOOR[] = "elevator";
static	const	float	ELEVATOR_FLOOR_Z_OFFSET = 128.0; // Elevator is being reported a bit higher than it really is
static	const	float	ELEVATOR_FLOOR_TELE_Z_OFFSET = 64.0; // How much Z we add to the survivor if falling through

static	const	float	ELEVATOR_ORIGIN_INTERVAL = 1.0; // How often we check survivors and elevator origin and adjust if survivor is falling through

static			bool	g_bIsEventsHooked = false;
static			bool	g_bIsElevatorButtonPushed = false;
static			bool	g_bIsElevatorMoving = false;
static			int		g_iElevatorFloor = -1;

public Plugin myinfo = 
{
	name = "No Mercy Elevator Fix",
	author = "Mr. Zero",
	description = "Provides a work around for the current bug with players falling through the elevator on No Mercy",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=143008"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_nmelevatorfix_version", PLUGIN_VERSION, "No Mercy Elevator Fix Version", FCVAR_NONE | FCVAR_NOTIFY);
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, 32);
	if (StrEqual(map, NO_MERCY_MAP4))
	{
		if (!g_bIsEventsHooked)
		{
			HookEvent("round_start", OnRoundStart_Event, EventHookMode_PostNoCopy);
			HookEvent("door_moving", OnDoorMoving_Event, EventHookMode_Post);
			HookEvent("player_use", OnPlayerUse_Event, EventHookMode_Post);
		}
		g_bIsEventsHooked = true;
	}
	else if (g_bIsEventsHooked)
	{
		UnhookEvent("round_start", OnRoundStart_Event, EventHookMode_PostNoCopy);
		UnhookEvent("door_moving", OnDoorMoving_Event, EventHookMode_Post);
		UnhookEvent("player_use", OnPlayerUse_Event, EventHookMode_Post);
		g_bIsEventsHooked = false;
	}
}

public void OnRoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsElevatorMoving = false;
	g_bIsElevatorButtonPushed = false;
	g_iElevatorFloor = -1;
}

public void OnDoorMoving_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsElevatorButtonPushed) return;

	int entity = GetEventInt(event, "entindex");
	if (entity < 0 || entity > 2048 || !IsValidEntity(entity)) return;

	char buffer[128];
	GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
	if (!g_bIsElevatorMoving)
	{
		if (!StrEqual(buffer, ELEVATOR_DOORS_LOW)) return;
		g_bIsElevatorMoving = true;
		CreateTimer(ELEVATOR_ORIGIN_INTERVAL, Elevator_Timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if (!StrEqual(buffer, ELEVATOR_DOORS_HIGH)) return;
		g_bIsElevatorMoving = false;
	}
}

public void OnPlayerUse_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bIsElevatorButtonPushed) return;

	int entity = GetEventInt(event, "targetid");
	if (entity < 0 || entity > 2048 || !IsValidEntity(entity)) return;

	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client < 1 || 
		client > MaxClients || 
		!IsClientInGame(client) || 
		GetClientTeam(client) != TEAM_SURVIVOR)
		return;

	char buffer[128];
	GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer)); 
	if (!StrEqual(buffer, ELEVATOR_BUTTON)) return;

	g_bIsElevatorButtonPushed = true;
	g_iElevatorFloor = FindElevatorFloor();
}

public Action Elevator_Timer(Handle timer)
{
	if (!g_bIsElevatorMoving || g_iElevatorFloor == -1) return Plugin_Stop;

	float elevatorOrigin[3];
	GetEntityAbsOrigin(g_iElevatorFloor, elevatorOrigin);
	elevatorOrigin[2] -= ELEVATOR_FLOOR_Z_OFFSET;

	float origin[3];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client)) continue;
		GetClientAbsOrigin(client, origin);
		if (origin[2] >= elevatorOrigin[2]) continue;
		origin[2] = elevatorOrigin[2] + ELEVATOR_FLOOR_TELE_Z_OFFSET;
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}

	return Plugin_Continue;
}

static int FindElevatorFloor()
{
	char buffer[128];
	int entity = -1;
	while ((entity = FindEntityByClassnameEx(entity, "func_elevator")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, 128);
		if (StrEqual(buffer, ELEVATOR_FLOOR)) return entity;
	}
	return -1;
}

static int FindEntityByClassnameEx(int startEnt, const char[] classname)
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

static void GetEntityAbsOrigin(int entity, float origin[3])
{
	if (entity < 1 || !IsValidEntity(entity)) return;

	float mins[3], maxs[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);

	for (int i = 0; i < 3; i++)
	{
		origin[i] += (mins[i] + maxs[i]) * 0.5;
	}
}