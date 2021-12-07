#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MAX_MAPZONES 30

new g_clientDrawingBox = -1;
new bool:g_bWaitingForTelepoint;

new g_clientDeletingBox = -1;
new g_deletingBoxIndex;

new Float:g_fDrawingBoxStart[MAX_MAPZONES][3];
new Float:g_fDrawingBoxEnd[MAX_MAPZONES][3];
new Float:g_fTeleportPoint[MAX_MAPZONES][3];
new g_indexMapzones;

new const g_color[4] = {255,255,255,255};
new g_precachedLaser = -1;

new Handle:g_hDBMapzones = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Badmapzones",
	author = "Bibihotz",
	description = "Create restricted areas (bad mapzones) who players can't enter",
	version = "1.0b",
	url = "<-SuckMyBalls->"
}

public OnPluginStart()
{
	decl String:sqlError[256];
	g_hDBMapzones = SQL_Connect("mapzones", false, sqlError, sizeof(sqlError));
	
	if(g_hDBMapzones == INVALID_HANDLE)
		SetFailState("Error occured while trying to connect to database \"mapzones\": %s", sqlError);
	
	SQL_LockDatabase(g_hDBMapzones);
	
	if(!SQL_FastQuery(g_hDBMapzones, "CREATE TABLE IF NOT EXISTS badmapzones (id INTEGER PRIMARY KEY, map TEXT NOT NULL, startX REAL NOT NULL, startY REAL NOT NULL, startZ REAL NOT NULL, endX REAL NOT NULL, endY REAL NOT NULL, endZ REAL NOT NULL, teleX REAL NOT NULL, teleY REAL NOT NULL, teleZ REAL NOT NULL)"))
		SetFailState("Error occured while trying to create table \"badmapzones\" in database \"mapzones\"!");
	
	SQL_UnlockDatabase(g_hDBMapzones);
	
	RegAdminCmd("sm_addbadarea", Cmd_AddBadArea, ADMFLAG_ROOT, "Create new restricted area");
	RegAdminCmd("sm_delbadarea", Cmd_DelBadArea, ADMFLAG_ROOT, "Delete restricted area");
}

public OnMapStart()
{
	g_precachedLaser = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	g_indexMapzones = 0;
	
	decl String:mapPlaying[64];
	GetCurrentMap(mapPlaying, sizeof(mapPlaying));
	
	decl String:sqlQuery[192]; // size=164
	Format(sqlQuery, sizeof(sqlQuery), "SELECT startX, startY, startZ, endX, endY, endZ, teleX, teleY, teleZ FROM badmapzones WHERE map = '%s'", mapPlaying);
	SQL_TQuery(g_hDBMapzones, SQLT_ReadInMapZones, sqlQuery);
}

public OnClientDisconnect(client)
{
	if(client == g_clientDrawingBox)
		g_clientDrawingBox = -1;
	
	if(client == g_clientDeletingBox)
		g_clientDeletingBox = -1;
}

public Action:Cmd_AddBadArea(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(args != 0)
	{
		PrintToChat(client, "[SM] Usage: sm_addbadarea");
		return Plugin_Handled;
	}
	
	if(client == g_clientDeletingBox)
		return Plugin_Handled;
	
	GetClientAbsOrigin(client, g_fDrawingBoxStart[g_indexMapzones]);
	g_bWaitingForTelepoint	= false;
	g_clientDrawingBox		= client;
	
	ShowBoxInfoMenu(client, "Press ATTACK2 (mouse right) \nto complete drawing box (restricted area).", _, true);
	CreateTimer(0.1, Timer_DrawBoxBorders, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action:Cmd_DelBadArea(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	if(args != 0)
	{
		PrintToChat(client, "[SM] Usage: sm_delbadarea");
		return Plugin_Handled;
	}
	
	if(client == g_clientDrawingBox)
		return Plugin_Handled;
	
	g_deletingBoxIndex	= -1;
	g_clientDeletingBox	= client;
	
	ShowBoxInfoMenu(client, "1. Put you inside a restricted area you want to delete\n2. When delete menu pops up press confirm.", _, true);
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(client == g_clientDrawingBox && !g_bWaitingForTelepoint)
	{
		if(buttons & IN_ATTACK2)
		{
			g_bWaitingForTelepoint = true;
			GetClientEyePosition(client, g_fDrawingBoxEnd[g_indexMapzones]);
			
			ShowBoxInfoMenu(client, "Box complete! \nNext select a location and press confirm \nto specify a teleport point for players \nwho enter restricted area.", true, true);
		}
	}
}

ShowBoxInfoMenu(client, const String:msg[], bool:confirmable=false, bool:cancelable=false, bool:quittable=false, time=MENU_TIME_FOREVER)
{
	new Handle:menu = CreateMenu(Handler_BoxInfoMenu);
	SetMenuTitle(menu, msg);
	
	if(confirmable)
		AddMenuItem(menu, "", "Confirm");
	
	if(cancelable)
		AddMenuItem(menu, "cancel", "Cancel");
	
	SetMenuExitButton(menu, quittable);
	
	DisplayMenu(menu, client, time);
}

public Handler_BoxInfoMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			decl String:menuInfo[8];
			GetMenuItem(menu, 0, menuInfo, sizeof(menuInfo));
			
			if(StrEqual(menuInfo, "cancel"))
			{
				if(param1 == g_clientDrawingBox)
					g_clientDrawingBox = -1;
				else if(param1 == g_clientDeletingBox)
					g_clientDeletingBox = -1;
			}
			else
			{
				if(param1 == g_clientDrawingBox)
				{
					g_clientDrawingBox = -1;
					
					GetClientAbsOrigin(param1, g_fTeleportPoint[g_indexMapzones]);
					SaveNewMapZone(param1);
				}
				else if(param1 == g_clientDeletingBox)
				{
					g_clientDeletingBox = -1;
					DeleteMapZone(param1);
				}
			}
		}
		if(param2 == 1)
		{
			if(param1 == g_clientDrawingBox)
				g_clientDrawingBox = -1;
			else if(param1 == g_clientDeletingBox)
				g_clientDeletingBox = -1;
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

SaveNewMapZone(client)
{
	new Float:temp;
	
	if(g_fDrawingBoxStart[g_indexMapzones][0] > g_fDrawingBoxEnd[g_indexMapzones][0])
	{
		temp = g_fDrawingBoxStart[g_indexMapzones][0];
		g_fDrawingBoxStart[g_indexMapzones][0]	= g_fDrawingBoxEnd[g_indexMapzones][0];
		g_fDrawingBoxEnd[g_indexMapzones][0]	= temp;
	}
	
	if(g_fDrawingBoxStart[g_indexMapzones][1] > g_fDrawingBoxEnd[g_indexMapzones][1])
	{
		temp = g_fDrawingBoxStart[g_indexMapzones][1];
		g_fDrawingBoxStart[g_indexMapzones][1]	= g_fDrawingBoxEnd[g_indexMapzones][1];
		g_fDrawingBoxEnd[g_indexMapzones][1]	= temp;
	}
	
	if(g_fDrawingBoxStart[g_indexMapzones][2] > g_fDrawingBoxEnd[g_indexMapzones][2])
	{
		temp = g_fDrawingBoxStart[g_indexMapzones][2];
		g_fDrawingBoxStart[g_indexMapzones][2]	= g_fDrawingBoxEnd[g_indexMapzones][2] - 5;
		g_fDrawingBoxEnd[g_indexMapzones][2]	= temp;
	}
	else
	{
		g_fDrawingBoxStart[g_indexMapzones][2] -= 5;
	}
	
	decl String:mapPlaying[64];
	GetCurrentMap(mapPlaying, sizeof(mapPlaying));
	
	decl String:sqlQuery[336]; // size=186/9x14=126/312
	Format(sqlQuery, sizeof(sqlQuery), "INSERT INTO badmapzones (map, startX, startY, startZ, endX, endY, endZ, teleX, teleY, teleZ) VALUES ('%s', %f, %f, %f, %f, %f, %f, %f, %f, %f)", mapPlaying, g_fDrawingBoxStart[g_indexMapzones][0], g_fDrawingBoxStart[g_indexMapzones][1], g_fDrawingBoxStart[g_indexMapzones][2], g_fDrawingBoxEnd[g_indexMapzones][0], g_fDrawingBoxEnd[g_indexMapzones][1], g_fDrawingBoxEnd[g_indexMapzones][2], g_fTeleportPoint[g_indexMapzones][0], g_fTeleportPoint[g_indexMapzones][1], g_fTeleportPoint[g_indexMapzones][2]);
	SQL_TQuery(g_hDBMapzones, SQLT_SaveNewMapZone, sqlQuery, client);
	
	g_indexMapzones++;
}

DeleteMapZone(client)
{
	if(g_deletingBoxIndex != g_indexMapzones - 1)
	{
		g_fDrawingBoxStart[g_deletingBoxIndex][0] = g_fDrawingBoxStart[g_indexMapzones-1][0];
		g_fDrawingBoxStart[g_deletingBoxIndex][1] = g_fDrawingBoxStart[g_indexMapzones-1][1];
		g_fDrawingBoxStart[g_deletingBoxIndex][2] = g_fDrawingBoxStart[g_indexMapzones-1][2];
		
		g_fDrawingBoxEnd[g_deletingBoxIndex][0] = g_fDrawingBoxEnd[g_indexMapzones-1][0];
		g_fDrawingBoxEnd[g_deletingBoxIndex][1] = g_fDrawingBoxEnd[g_indexMapzones-1][1];
		g_fDrawingBoxEnd[g_deletingBoxIndex][2] = g_fDrawingBoxEnd[g_indexMapzones-1][2];
		
		g_fTeleportPoint[g_deletingBoxIndex][0] = g_fTeleportPoint[g_indexMapzones-1][0];
		g_fTeleportPoint[g_deletingBoxIndex][1] = g_fTeleportPoint[g_indexMapzones-1][1];
		g_fTeleportPoint[g_deletingBoxIndex][2] = g_fTeleportPoint[g_indexMapzones-1][2];
	}
	
	decl String:mapPlaying[64];
	GetCurrentMap(mapPlaying, sizeof(mapPlaying));
	
	decl String:sqlQuery[304]; // size=187/6*14=84/271
	Format(sqlQuery, sizeof(sqlQuery), "DELETE FROM badmapzones WHERE map = '%s' AND startX = %f AND startY = %f AND startZ = %f AND endX = %f AND endY = %f AND endZ = %f", mapPlaying, g_fDrawingBoxStart[g_indexMapzones][0], g_fDrawingBoxStart[g_indexMapzones][1], g_fDrawingBoxStart[g_indexMapzones][2], g_fDrawingBoxEnd[g_indexMapzones][0], g_fDrawingBoxEnd[g_indexMapzones][1], g_fDrawingBoxEnd[g_indexMapzones][2]); // todo: delete per index
	SQL_TQuery(g_hDBMapzones, SQLT_DeleteMapZone, sqlQuery, client);
	
	g_indexMapzones--;
}

public Action:Timer_CheckForBadLoc(Handle:timer)
{
	new Float:clientLoc[3];
	new zoneIndex;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!(IsClientInGame(i) && IsPlayerAlive(i)))
			continue;
		
		GetClientAbsOrigin(i, clientLoc);
		zoneIndex = IsPlayerInBadLocation(clientLoc);
		
		if(zoneIndex != -1)
		{
			DrawBoxBorders(g_fDrawingBoxStart[zoneIndex], g_fDrawingBoxEnd[zoneIndex]);
			
			if(i == g_clientDeletingBox)
			{
				if(g_deletingBoxIndex != zoneIndex)
				{
					g_deletingBoxIndex = zoneIndex;
					ShowBoxInfoMenu(i, "Do you really want to delete the restricted area \nyou're inside from database?", true, true);
				}
				
				continue;
			}
			
			TeleportEntity(i, g_fTeleportPoint[zoneIndex], NULL_VECTOR, NULL_VECTOR);
			PrintToChat(i, "\x04[BadArea] \x01You're \x05not allowed to enter \x01this area! An Admin marked this area as \x05restricted area.");
		}
	}
}

IsPlayerInBadLocation(Float:clientLoc[3])
{
	for(new i; i < g_indexMapzones; i++)
	{
		if(clientLoc[0] >= g_fDrawingBoxStart[i][0] && clientLoc[0] <= g_fDrawingBoxEnd[i][0])
		{
			if(clientLoc[1] >= g_fDrawingBoxStart[i][1] && clientLoc[1] <= g_fDrawingBoxEnd[i][1])
			{
				if(clientLoc[2] >= g_fDrawingBoxStart[i][2] && clientLoc[2] <= g_fDrawingBoxEnd[i][2])
					return i;
			}
		}
	}
	
	return -1;
}

public Action:Timer_DrawBoxBorders(Handle:timer, any:client)
{
	static Float:clientLoc[3];
	
	if(!(client == g_clientDrawingBox && !g_bWaitingForTelepoint))
		return Plugin_Stop;
	
	GetClientEyePosition(client, clientLoc);
	DrawBoxBorders(g_fDrawingBoxStart[g_indexMapzones], clientLoc);
	
	return Plugin_Continue;
}

DrawBoxBorders(const Float:startLoc[3], const Float:endLoc[3])
{
	new Float:boxOffset[2];
	
	// X-Border
	new Float:X[3];
	boxOffset[0] = endLoc[0] - startLoc[0];
	
	X[0] = startLoc[0] + boxOffset[0];
	X[1] = startLoc[1];
	X[2] = startLoc[2];
	
	// Y-Border
	new Float:Y[3];
	boxOffset[1] = endLoc[1] - startLoc[1];
	
	Y[0] = startLoc[0];
	Y[1] = startLoc[1] + boxOffset[1];
	Y[2] = startLoc[2];
	
	// X-YANDY-X-Border
	new Float:XtoYANDYtoX[3];
	XtoYANDYtoX[0] = endLoc[0];
	XtoYANDYtoX[1] = endLoc[1];
	XtoYANDYtoX[2] = startLoc[2];
	
	// Z-Border
	new Float:Z[3];
	Z[0] = startLoc[0];
	Z[1] = startLoc[1];
	Z[2] = endLoc[2];
	
	// Z1grnd-Border
	new Float:Z1grnd[3];
	Z1grnd[0] = endLoc[0];
	Z1grnd[1] = endLoc[1];
	Z1grnd[2] = startLoc[2];
	
	// XZ-Border
	new Float:XZ[3];
	XZ[0] = X[0];
	XZ[1] = X[1];
	XZ[2] = endLoc[2];
	
	// YZ-Border
	new Float:YZ[3];
	YZ[0] = Y[0];
	YZ[1] = Y[1];
	YZ[2] = endLoc[2];
	
	TE_SetupBeamPoints(startLoc, X, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(startLoc, Y, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(X, XtoYANDYtoX, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(Y, XtoYANDYtoX, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(startLoc, Z, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(Z1grnd, endLoc, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(X, XZ, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(Y, YZ, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(Z, XZ, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(Z, YZ, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(XZ, endLoc, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(YZ, endLoc, g_precachedLaser, -1, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_color, 0);
	TE_SendToAll();
}

public SQLT_SaveNewMapZone(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl != INVALID_HANDLE)
	{
		if(IsClientInGame(client))
		{
			ShowBoxInfoMenu(client, "Success! \nRestricted area and teleport point \nare active now!", _, _, _, 5);
			PrintToChat(client, "\x04[BadArea] \x01Your newly created restricted area and teleport point \x05have been saved to database.");
		}
	}
	else
	{
		LogError("\"SQLT_SaveNewMapZone\" alert: %s", error);
		ShowBoxInfoMenu(client, "Error! Check your logs!", _, _, true);
	}
}

public SQLT_DeleteMapZone(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl != INVALID_HANDLE)
	{
		if(IsClientInGame(client))
		{
			ShowBoxInfoMenu(client, "Success! \nRestricted area and teleport point \nhave been deleted.", _, _, _, 5);
			PrintToChat(client, "\x04[BadArea] \x01You successfully \x05deleted restricted area + related teleport point \x01from database.");
		}
	}
	else
	{
		LogError("\"SQLT_DeleteMapZone\" alert: %s", error);
		ShowBoxInfoMenu(client, "Error! Check your logs!", _, _, true);
	}
}

public SQLT_ReadInMapZones(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl != INVALID_HANDLE)
	{
		while(SQL_FetchRow(hndl))
		{
			g_fDrawingBoxStart[g_indexMapzones][0] = SQL_FetchFloat(hndl, 0);
			g_fDrawingBoxStart[g_indexMapzones][1] = SQL_FetchFloat(hndl, 1);
			g_fDrawingBoxStart[g_indexMapzones][2] = SQL_FetchFloat(hndl, 2);
			
			g_fDrawingBoxEnd[g_indexMapzones][0] = SQL_FetchFloat(hndl, 3);
			g_fDrawingBoxEnd[g_indexMapzones][1] = SQL_FetchFloat(hndl, 4);
			g_fDrawingBoxEnd[g_indexMapzones][2] = SQL_FetchFloat(hndl, 5);
			
			g_fTeleportPoint[g_indexMapzones][0] = SQL_FetchFloat(hndl, 6);
			g_fTeleportPoint[g_indexMapzones][1] = SQL_FetchFloat(hndl, 7);
			g_fTeleportPoint[g_indexMapzones][2] = SQL_FetchFloat(hndl, 8);
			
			g_indexMapzones++;
		}
		
		if(g_indexMapzones > 0)
			CreateTimer(0.2, Timer_CheckForBadLoc, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("\"SQLT_ReadInMapZones\" alert: %s", error);
	}
}
