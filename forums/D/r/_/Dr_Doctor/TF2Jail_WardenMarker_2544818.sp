/*
 * MyJailbreak - Warden - Marker Module.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 * 
 * Copyright (C) 2016-2017 Thomas Schmidt (shanapu)
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <mystocks>
//edit
#include <tf2jail>
#include <smlib>

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

//Info
#define PLUGIN_AUTHOR "shanapu, modify by Battlefield Duck"
#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "[TF2] Jailbreak - Marker",
	author = PLUGIN_AUTHOR,
	description = "Marker Plugin, Draw a circle on the ground!",
	version = PLUGIN_VERSION,
	url = ""
};

// Console Variables
ConVar gc_bMarker;

// Booleans
bool g_bCanMarker[MAXPLAYERS + 1];
bool g_bMarkerSetup[MAXPLAYERS + 1];
//edit
//From warden.sp
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iColors[8][4] = 
{
	{255, 255, 255, 255}, // white
	{255, 0, 0, 255}, // red
	{20, 255, 20, 255}, // green
	{0, 65, 255, 255}, // blue
	{255, 255, 0, 255}, // yellow
	{0, 255, 255, 255}, // cyan
	{255, 0, 255, 255}, // magenta
	{255, 80, 0, 255}  // orange
};

// Strings
char g_sColorNamesRed[64];
char g_sColorNamesBlue[64];
char g_sColorNamesGreen[64];
char g_sColorNamesOrange[64];
char g_sColorNamesMagenta[64];
char g_sColorNamesRainbow[64];
char g_sColorNamesYellow[64];
char g_sColorNamesCyan[64];
char g_sColorNamesWhite[64];
char g_sColorNames[8][64] ={{""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}};

// float
float g_fMarkerRadiusMin = 100.0;
float g_fMarkerRadiusMax = 500.0;
float g_fMarkerRangeMax = 1500.0;
float g_fMarkerArrowHeight = 90.0;
float g_fMarkerArrowLength = 20.0;
float g_fMarkerSetupStartOrigin[3];
float g_fMarkerSetupEndOrigin[3];
float g_fMarkerOrigin[8][3];
float g_fMarkerRadius[8];

// Start
public void OnPluginStart()
{
	// Cvar
	CreateConVar("sm_tf2jail_marker_version", PLUGIN_VERSION, "Version of [TF2] Jailbreak - Marker", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	gc_bMarker = CreateConVar("sm_tf2jail_warden_marker", "1", "0 - disabled, 1 - enable Warden advanced markers ", _, true, 0.0, true, 1.0);
	
	//Commands
	RegConsoleCmd("+beacons", Command_Beacons);
	RegConsoleCmd("-beacons", Command_Beacons);
	
	CreateTimer(1.0, Timer_DrawMakers, _, TIMER_REPEAT);

	PrepareMarkerNames();
}

public void PrepareMarkerNames()
{
	//edit
	Format(g_sColorNamesRed, sizeof(g_sColorNamesRed), "{darkred}Red{default}", LANG_SERVER);
	Format(g_sColorNamesBlue, sizeof(g_sColorNamesBlue), "{blue}Blue{default}", LANG_SERVER);
	Format(g_sColorNamesGreen, sizeof(g_sColorNamesGreen), "{green}Green{default}", LANG_SERVER);
	Format(g_sColorNamesOrange, sizeof(g_sColorNamesOrange), "{lightred}Orange{default}", LANG_SERVER);
	Format(g_sColorNamesMagenta, sizeof(g_sColorNamesMagenta), "{purple}Magenta{default}", LANG_SERVER);
	Format(g_sColorNamesYellow, sizeof(g_sColorNamesYellow), "{orange}Yellow{default}", LANG_SERVER);
	Format(g_sColorNamesWhite, sizeof(g_sColorNamesWhite), "{default}White{default}", LANG_SERVER);
	Format(g_sColorNamesCyan, sizeof(g_sColorNamesCyan), "{blue}Cyan{default}", LANG_SERVER);
	Format(g_sColorNamesRainbow, sizeof(g_sColorNamesRainbow), "{lightgreen}Rainbow{default}", LANG_SERVER);


	g_sColorNames[0] = g_sColorNamesWhite;
	g_sColorNames[1] = g_sColorNamesRed;
	g_sColorNames[3] = g_sColorNamesBlue;
	g_sColorNames[2] = g_sColorNamesGreen;
	g_sColorNames[7] = g_sColorNamesOrange;
	g_sColorNames[6] = g_sColorNamesMagenta;
	g_sColorNames[4] = g_sColorNamesYellow;
	g_sColorNames[5] = g_sColorNamesCyan;
}

/******************************************************************************
                   COMMANDS
******************************************************************************/

public Action Command_Beacons(int client, int args)
{
	//edit
	if(!TF2Jail_IsWarden(client)) 	return Plugin_Handled;
	
	char sCommand[32];
	GetCmdArg(0, sCommand, sizeof(sCommand));
	
	if (client > 0)
	{
		g_bCanMarker[client] = StrContains(sCommand, "+") != -1;
	}

	
	return Plugin_Handled;
}

/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_ATTACK2 || g_bCanMarker[client])
	{
		if (gc_bMarker.BoolValue && TF2Jail_IsWarden(client)) 
		{
			if (!g_bMarkerSetup[client])
				GetClientAimTargetPos(client, g_fMarkerSetupStartOrigin);
			
			GetClientAimTargetPos(client, g_fMarkerSetupEndOrigin);
			
			float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
			
			if (radius > g_fMarkerRadiusMax)
				radius = g_fMarkerRadiusMax;
			else if (radius < g_fMarkerRadiusMin)
				radius = g_fMarkerRadiusMin;
			
			if (radius > 0)
			{
				TE_SetupBeamRingPoint(g_fMarkerSetupStartOrigin, radius, radius+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.1, 2.0, 0.0, {255, 255, 255, 255}, 10, 0);
				TE_SendToClient(client);
			}
			
			g_bMarkerSetup[client] = true;
		}
	}
	else if (g_bMarkerSetup[client])
	{
		MarkerMenu(client);
		g_bMarkerSetup[client] = false;
	}
}

public void OnMapEnd()
{
	RemoveAllMarkers();
}

public void OnMapStart()
{
	//From warden.sp
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	
	RemoveAllMarkers();
}

/******************************************************************************
                   MENUS
******************************************************************************/

stock void MarkerMenu(int client)
{
	if (!IsValidClient(client, false, false) || !TF2Jail_IsWarden(client))
	{
		//CPrintToChat(client, "%t %t", "warden_tag", "warden_notwarden");
		return;
	}

	int marker = IsMarkerInRange(g_fMarkerSetupStartOrigin);
	if (marker != -1)
	{
		RemoveMarker(marker);
		//CPrintToChatAll("%t %t", "warden_tag", "warden_marker_remove", g_sColorNames[marker]);
		return;
	}

	float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
	if (radius <= 0.0)
	{
		RemoveMarker(marker);
		//CPrintToChat(client, "%t %t", "warden_tag", "warden_wrong");
		return;
	}

	float g_fPos[3];
	Entity_GetAbsOrigin(client, g_fPos);

	float range = GetVectorDistance(g_fPos, g_fMarkerSetupStartOrigin);
	if (range > g_fMarkerRangeMax)
	{
		//CPrintToChat(client, "%t %t", "warden_tag", "warden_range");
		return;
	}

	if (0 < client < MaxClients)
	{
		Menu menu = CreateMenu(Handle_MarkerMenu);
		char menuinfo[255];

		Format(menuinfo, sizeof(menuinfo), "Select a color", client);
		SetMenuTitle(menu, menuinfo);

		Format(menuinfo, sizeof(menuinfo), "Red", client);
		AddMenuItem(menu, "1", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "Blue", client);
		AddMenuItem(menu, "3", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "Green", client);
		AddMenuItem(menu, "2", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "Orange", client);
		AddMenuItem(menu, "7", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "White", client);
		AddMenuItem(menu, "0", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "Cyan", client);
		AddMenuItem(menu, "5", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "Magenta", client);
		AddMenuItem(menu, "6", menuinfo);
		
		Format(menuinfo, sizeof(menuinfo), "Yellow", client);
		AddMenuItem(menu, "4", menuinfo);

		menu.Display(client, 20);
	}
}

public int Handle_MarkerMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (!IsValidClient(client, false, false))
		return;

	if (!TF2Jail_IsWarden(client))
	{
		//CPrintToChat(client, "%t %t", "warden_tag", "warden_notwarden");
		return;
	}

	if (action == MenuAction_Select)
	{
		char info[32];char info2[32];
		bool found = menu.GetItem(itemNum, info, sizeof(info), _, info2, sizeof(info2));
		int marker = StringToInt(info);

		if (found)
		{
			SetupMarker(marker);
			//CPrintToChatAll("%t %t", "warden_tag", "warden_marker_set", g_sColorNames[marker]);
			FakeClientCommand(client, "sm_wmenu");
		}
	}
}

/******************************************************************************
                   TIMER
******************************************************************************/

public Action Timer_DrawMakers(Handle timer, any data)
{
	Draw_Markers();

	return Plugin_Continue;
}

/******************************************************************************
                   STOCKS
******************************************************************************/

void Draw_Markers()
{
	//edit Detect any warden 
	int g_iWarden = -1;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsValidClient(iClient))
    	{
    		if(TF2Jail_IsWarden(iClient)) 	g_iWarden = iClient;
    	}
    }
    
	if (g_iWarden == -1)
		return;

	for (int j = 0; j<8; j++)
	{
		if (g_fMarkerRadius[j] <= 0.0)
			continue;

		// FIX OR FEATURE    TODO ASK ZIPCORE
		float fWardenOrigin[3];
		Entity_GetAbsOrigin(g_iWarden, fWardenOrigin);

		if (GetVectorDistance(fWardenOrigin, g_fMarkerOrigin[j]) > g_fMarkerRangeMax)
		{
			//CPrintToChat(g_iWarden, "%t %t", "warden_tag", "warden_marker_faraway", g_sColorNames[j]);
			RemoveMarker(j);
			continue;
		}

		// FIX OR FEATURE    TODO ASK ZIPCORE
		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, false, false))
		{
			// Show the ring
			TE_SetupBeamRingPoint(g_fMarkerOrigin[j], g_fMarkerRadius[j], g_fMarkerRadius[j]+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 0.0, g_iColors[j], 10, 0);
			TE_SendToAll();

			// Show the arrow
			float fStart[3];
			AddVectors(fStart, g_fMarkerOrigin[j], fStart);
			fStart[2] += g_fMarkerArrowHeight;

			float fEnd[3];
			AddVectors(fEnd, fStart, fEnd);
			fEnd[2] += g_fMarkerArrowLength;

			TE_SetupBeamPoints(fStart, fEnd, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 16.0, 1, 0.0, g_iColors[j], 5);
			TE_SendToAll();
		}
	}
}

void SetupMarker(int marker)
{
	g_fMarkerOrigin[marker][0] = g_fMarkerSetupStartOrigin[0];
	g_fMarkerOrigin[marker][1] = g_fMarkerSetupStartOrigin[1];
	g_fMarkerOrigin[marker][2] = g_fMarkerSetupStartOrigin[2];

	float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
	if (radius > g_fMarkerRadiusMax)
		radius = g_fMarkerRadiusMax;
	else if (radius < g_fMarkerRadiusMin)
		radius = g_fMarkerRadiusMin;
	g_fMarkerRadius[marker] = radius;
}

int GetClientAimTargetPos(int client, float g_fPos[3]) 
{
	if (client < 1)
		return -1;

	float vAngles[3];float vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);

	TR_GetEndPosition(g_fPos, trace);
	g_fPos[2] += 5.0;

	int entity = TR_GetEntityIndex(trace);

	CloseHandle(trace);

	return entity;
}

void RemoveMarker(int marker)
{
	if (marker != -1)
	{
		g_fMarkerRadius[marker] = 0.0;
	}
}

void RemoveAllMarkers()
{
	for (int i = 0; i < 8; i++)
		RemoveMarker(i);
}

int IsMarkerInRange(float g_fPos[3])
{
	for (int i = 0; i < 8; i++)
	{
		if (g_fMarkerRadius[i] <= 0.0)
			continue;

		if (GetVectorDistance(g_fMarkerOrigin[i], g_fPos) < g_fMarkerRadius[i])
			return i;
	}
	return -1;
}

public bool TraceFilterAllEntities(int entity, int contentsMask, any client)
{
	if (entity == client)
		return false;

	if (entity > MaxClients)
		return false;

	if (!IsClientInGame(entity))
		return false;

	if (!IsPlayerAlive(entity))
		return false;

	return true;
}