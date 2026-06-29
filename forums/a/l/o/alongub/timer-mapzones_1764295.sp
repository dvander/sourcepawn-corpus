#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <adminmenu>
#include <smlib/arrays>
#include <timer>
#include <timer-logging>

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <timer-worldrecord>
#include <updater>

#define UPDATE_URL "http://dl.dropbox.com/u/16304603/timer/updateinfo-timer-mapzones.txt"

/**
 * Global Enums
 */
enum MapZoneEditor
{
	Step,
	Float:Point1[3],
	Float:Point2[3]
}

/**
 * Global Variables
 */
new Handle:g_hSQL;

new Handle:g_startMapZoneColor = INVALID_HANDLE;
new Handle:g_endMapZoneColor = INVALID_HANDLE;
new Handle:g_startStopPrespeed = INVALID_HANDLE;

new g_startColor[4] = { 0, 255, 0, 255 };
new g_endColor[4] = { 0, 0, 255, 255 };
new bool:g_stopPrespeed = false;

new String:g_currentMap[32];
new g_reconnectCounter = 0;

new g_mapZones[64][MapZone];
new g_mapZonesCount = 0;

new Handle:hTopMenu = INVALID_HANDLE;
new TopMenuObject:oMapZoneMenu;

new g_mapZoneEditors[MAXPLAYERS+1][MapZoneEditor];

new precache_laser;

new bool:g_timerPhysics = false;
new bool:g_timerWorldRecord = false;

public Plugin:myinfo =
{
    name        = "[Timer] MapZones",
    author      = "alongub | Glite",
    description = "Map Zones component for [Timer]",
    version     = PL_VERSION,
    url         = "https://github.com/alongubkin/timer"
};

public OnPluginStart()
{
	g_timerPhysics = LibraryExists("timer-physics");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");

	g_startMapZoneColor = CreateConVar("timer_startcolor", "0 255 0 255", "The color of the start map zone.");
	g_endMapZoneColor = CreateConVar("timer_endcolor", "0 0 255 255", "The color of the end map zone.");
	g_startStopPrespeed = CreateConVar("timer_stopprespeeding", "0", "If enabled players won't be able to prespeed in start zone.");
	
	HookConVarChange(g_startMapZoneColor, Action_OnSettingsChange);
	HookConVarChange(g_endMapZoneColor, Action_OnSettingsChange);	
	HookConVarChange(g_startStopPrespeed, Action_OnSettingsChange);
	
	AutoExecConfig(true, "timer-mapzones");
	
	g_stopPrespeed = GetConVarBool(g_startStopPrespeed);
	
	LoadTranslations("timer.phrases");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}	
}

public OnMapStart()
{
	ConnectSQL();
	
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	
	precache_laser = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = true;
	}
	else if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}	
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
	else if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = false;
	}
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_startMapZoneColor)
		ParseColor(newvalue, g_startColor);
	else if (cvar == g_endMapZoneColor)
		ParseColor(newvalue, g_endColor);
	else if (cvar == g_startStopPrespeed)
		g_stopPrespeed = bool:StringToInt(newvalue);
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Block this from being called twice
	if (topmenu == hTopMenu) {
		return;
	}
 
	// Save the Handle
	hTopMenu = topmenu;
	
	if ((oMapZoneMenu = FindTopMenuCategory(topmenu, "Timer Management")) == INVALID_TOPMENUOBJECT)
	{
		oMapZoneMenu = AddToTopMenu(hTopMenu,
			"Timer Management",
			TopMenuObject_Category,
			AdminMenu_CategoryHandler,
			INVALID_TOPMENUOBJECT);
	}
	
	AddToTopMenu(hTopMenu, 
		"timer_mapzones_add",
		TopMenuObject_Item,
		AdminMenu_AddMapZone,
		oMapZoneMenu,
		"timer_mapzones_add",
		ADMFLAG_RCON);

	AddToTopMenu(hTopMenu, 
		"timer_mapzones_remove",
		TopMenuObject_Item,
		AdminMenu_RemoveMapZone,
		oMapZoneMenu,
		"timer_mapzones_remove",
		ADMFLAG_RCON);
	AddToTopMenu(hTopMenu, 
		"timer_mapzones_remove_all",
		TopMenuObject_Item,
		AdminMenu_RemoveAllMapZones,
		oMapZoneMenu,
		"timer_mapzones_remove_all",
		ADMFLAG_RCON);

}

AddMapZone(String:map[], MapZoneType:type, Float:point1[3], Float:point2[3])
{
	decl String:query[512];
	
	if (type == Start || type == End)
	{
		decl String:deleteQuery[128];
		Format(deleteQuery, sizeof(deleteQuery), "DELETE FROM mapzone WHERE map = '%s' AND type = %d;", map, type);

		SQL_TQuery(g_hSQL, AddMapZoneCallback, deleteQuery, _, DBPrio_High);	
	}

	Format(query, sizeof(query), "INSERT INTO mapzone (map, type, point1_x, point1_y, point1_z, point2_x, point2_y, point2_z) VALUES ('%s', '%d', %f, %f, %f, %f, %f, %f);", map, type, point1[0], point1[1], point1[2], point2[0], point2[1], point2[2]);

	SQL_TQuery(g_hSQL, AddMapZoneCallback, query, _, DBPrio_Normal);	
}

public AddMapZoneCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on AddMapZone: %s", error);
		return;
	}
}

LoadMapZones()
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT id, type, point1_x, point1_y, point1_z, point2_x, point2_y, point2_z FROM mapzone WHERE map = '%s'", g_currentMap);
	
	SQL_TQuery(g_hSQL, LoadMapZonesCallback, query, _, DBPrio_Normal);	
}

public LoadMapZonesCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on LoadMapZones: %s", error);
		return;
	}

	g_mapZonesCount = 0;

	while (SQL_FetchRow(hndl))
	{
		strcopy(g_mapZones[g_mapZonesCount][Map], 32, g_currentMap);
		
		g_mapZones[g_mapZonesCount][Id] = SQL_FetchInt(hndl, 0);
		g_mapZones[g_mapZonesCount][Type] = MapZoneType:SQL_FetchInt(hndl, 1);
		
		g_mapZones[g_mapZonesCount][Point1][0] = SQL_FetchFloat(hndl, 2);
		g_mapZones[g_mapZonesCount][Point1][1] = SQL_FetchFloat(hndl, 3);
		g_mapZones[g_mapZonesCount][Point1][2] = SQL_FetchFloat(hndl, 4);
		
		g_mapZones[g_mapZonesCount][Point2][0] = SQL_FetchFloat(hndl, 5);
		g_mapZones[g_mapZonesCount][Point2][1] = SQL_FetchFloat(hndl, 6);
		g_mapZones[g_mapZonesCount][Point2][2] = SQL_FetchFloat(hndl, 7);
		
		g_mapZonesCount++;
	}

	CreateTimer(2.0, DrawZones, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, PlayerTracker, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnTimerRestart(client)
{
	for (new mapZone = 0; mapZone < g_mapZonesCount; mapZone++)
	{
		if (g_mapZones[mapZone][Type] == Start)
		{
			new Float:zero[3];
			
			new Float:center[3];
			center[0] = (g_mapZones[mapZone][Point1][0] + g_mapZones[mapZone][Point2][0]) / 2.0;
			center[1] = (g_mapZones[mapZone][Point1][1] + g_mapZones[mapZone][Point2][1]) / 2.0;
			center[2] = (g_mapZones[mapZone][Point1][2] + g_mapZones[mapZone][Point2][2]) / 2.0;
			
			TeleportEntity(client, center, zero, zero);

			break;
		}
	}
}

ConnectSQL()
{
    if (g_hSQL != INVALID_HANDLE)
        CloseHandle(g_hSQL);
	
    g_hSQL = INVALID_HANDLE;

    if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
    else
	{
		Timer_LogError("PLUGIN STOPPED - Reason: no config entry found for 'timer' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_reconnectCounter >= 5)
	{
		Timer_LogError("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("Connection to SQL database has failed, Reason: %s", error);
		
		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_FastQuery(hndl, "SET NAMES  'utf8'");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `mapzone` (`id` int(11) NOT NULL AUTO_INCREMENT, `type` int(11) NOT NULL, `point1_x` float NOT NULL, `point1_y` float NOT NULL, `point1_z` float NOT NULL, `point2_x` float NOT NULL, `point2_y` float NOT NULL, `point2_z` float NOT NULL, `map` varchar(32) NOT NULL, PRIMARY KEY (`id`));");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `mapzone` (`id` INTEGER PRIMARY KEY, `type` INTEGER NOT NULL, `point1_x` float NOT NULL, `point1_y` float NOT NULL, `point1_z` float NOT NULL, `point2_x` float NOT NULL, `point2_y` float NOT NULL, `point2_z` float NOT NULL, `map` varchar(32) NOT NULL);");
	}
		
	g_reconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);

		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
	
	LoadMapZones();
}

public AdminMenu_CategoryHandler(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "%t", "Timer Management");
	} else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Timer Management");
	}
}

public AdminMenu_AddMapZone(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Add Map Zone");
	} else if (action == TopMenuAction_SelectOption) {
		RestartMapZoneEditor(param);
		g_mapZoneEditors[param][Step] = 1;
		DisplaySelectPointMenu(param, 1);
	}
}

public AdminMenu_RemoveMapZone(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Delete Map Zone");
	} else if (action == TopMenuAction_SelectOption) {
		DeleteMapZone(param);
	}
}

public AdminMenu_RemoveAllMapZones(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%t", "Delete All Map Zones");
	} else if (action == TopMenuAction_SelectOption) {
		DeleteAllMapZones(param);
	}
}

RestartMapZoneEditor(client)
{
	g_mapZoneEditors[client][Step] = 0;

	for (new i = 0; i < 3; i++)
		g_mapZoneEditors[client][Point1][i] = 0.0;

	for (new i = 0; i < 3; i++)
		g_mapZoneEditors[client][Point1][i] = 0.0;		
}

DeleteMapZone(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	for (new zone = 0; zone < g_mapZonesCount; zone++)
	{
		if (IsInsideBox(vec, g_mapZones[zone][Point1][0], g_mapZones[zone][Point1][1], g_mapZones[zone][Point1][2], g_mapZones[zone][Point2][0], g_mapZones[zone][Point2][1], g_mapZones[zone][Point2][2]))
		{
			decl String:query[256];
			Format(query, sizeof(query), "DELETE FROM mapzone WHERE id = %d", g_mapZones[zone][Id]);

			SQL_TQuery(g_hSQL, DeleteMapZoneCallback, query, client, DBPrio_Normal);	
			break;
		}
	}
}

DeleteAllMapZones(client)
{
	decl String:query[256];
	Format(query, sizeof(query), "DELETE FROM mapzone WHERE map = '%s'", g_currentMap);

	SQL_TQuery(g_hSQL, DeleteMapZoneCallback, query, client, DBPrio_Normal);
}

public DeleteMapZoneCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeleteMapZone: %s", error);
		return;
	}

	LoadMapZones();
	
	if (IsClientInGame(data))
		PrintToChat(data, PLUGIN_PREFIX, "Map Zone Delete");
}

DisplaySelectPointMenu(client, n)
{
	new Handle:panel = CreatePanel();

 	decl String:message[255];
	decl String:first[32], String:second[32];
	Format(first, sizeof(first), "%t", "FIRST");
	Format(second, sizeof(second), "%t", "SECOND");
	
 	Format(message, sizeof(message), "%t", "Point Select Panel", (n == 1) ? first : second);

 	DrawPanelItem(panel, message, ITEMDRAW_RAWLINE);

	Format(message, sizeof(message), "%t", "Cancel");
 	DrawPanelItem(panel, message);

	SendPanelToClient(panel, client, PointSelect, 540);
	CloseHandle(panel);
}

DisplayPleaseWaitMenu(client)
{
	new Handle:panel = CreatePanel();
	
	decl String:wait[64];
	Format(wait, sizeof(wait), "%t", "Please wait");
	DrawPanelItem(panel, wait, ITEMDRAW_RAWLINE);

	SendPanelToClient(panel, client, PointSelect, 540);
	CloseHandle(panel);
}

public PointSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_Select) 
	{
		if (param2 == MenuCancel_Exit && hTopMenu != INVALID_HANDLE) 
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}

		RestartMapZoneEditor(param1);
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_ATTACK2)
	{
		if (g_mapZoneEditors[client][Step] == 1)
		{
			new Float:vec[3];			
			GetClientAbsOrigin(client, vec);
			g_mapZoneEditors[client][Point1] = vec;

			DisplayPleaseWaitMenu(client);

			CreateTimer(1.0, ChangeStep, GetClientSerial(client));
			return Plugin_Handled;
		}
		else if (g_mapZoneEditors[client][Step] == 2)
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			g_mapZoneEditors[client][Point2] = vec;

			g_mapZoneEditors[client][Step] = 3;

			DisplaySelectZoneTypeMenu(client);

			return Plugin_Handled;
		}		
	}

	return Plugin_Continue;
}

public Action:ChangeStep(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	g_mapZoneEditors[client][Step] = 2;
	CreateTimer(0.1, DrawAdminBox, GetClientSerial(client), TIMER_REPEAT);

	DisplaySelectPointMenu(client, 2);
}

DisplaySelectZoneTypeMenu(client)
{
	new Handle:menu = CreateMenu(ZoneTypeSelect);
	SetMenuTitle(menu, "%T", "Select zone type", client);
	
	decl String:Startm[64];
	Format(Startm, sizeof(Startm), "%T", "Start", client);
	decl String:Endm[64];
	Format(Endm, sizeof(Endm), "%T", "End", client);
	decl String:Glitch1m[64];
	Format(Glitch1m, sizeof(Glitch1m), "%T", "Glitch1", client);
	decl String:Glitch2m[64];
	Format(Glitch2m, sizeof(Glitch2m), "%T", "Glitch2", client);
	decl String:Glitch3m[64];
	Format(Glitch3m, sizeof(Glitch3m), "%T", "Glitch3", client);

	// This is ugly
	AddMenuItem(menu, "0", Startm);
	AddMenuItem(menu, "1", Endm);
	AddMenuItem(menu, "2", Glitch1m);
	AddMenuItem(menu, "3", Glitch2m);
	AddMenuItem(menu, "4", Glitch3m);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 360);
}

public ZoneTypeSelect(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
		RestartMapZoneEditor(param1);
	} 
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_Exit && hTopMenu != INVALID_HANDLE) 
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			RestartMapZoneEditor(param1);
		}
	}
	else if (action == MenuAction_Select) 
	{
		new Float:point1[3];
		Array_Copy(g_mapZoneEditors[param1][Point1], point1, 3);

		new Float:point2[3];
		Array_Copy(g_mapZoneEditors[param1][Point2], point2, 3);

		point1[2] -= 2;
		point2[2] += 100;

		AddMapZone(g_currentMap, MapZoneType:param2, point1, point2);
		RestartMapZoneEditor(param1);
		LoadMapZones();
	}
}

public Action:DrawAdminBox(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (g_mapZoneEditors[client][Step] == 0)
	{
		return Plugin_Stop;
	}
	
	new Float:a[3], Float:b[3];

	Array_Copy(g_mapZoneEditors[client][Point1], b, 3);

	if (g_mapZoneEditors[client][Step] == 3)
		Array_Copy(g_mapZoneEditors[client][Point2], a, 3);
	else
		GetClientAbsOrigin(client, a);

	// Effect_DrawBeamBoxToClient(client, a, b, precache_laser, 0, 0, 30, 0.1, 3.0, 3.0);
	new color[4] = {255, 255, 255, 255};

	DrawBox(a, b, 0.1, color, false);
	return Plugin_Continue;
}

public Action:DrawZones(Handle:timer)
{
	for (new zone = 0; zone < g_mapZonesCount; zone++)
	{
		if (g_mapZones[zone][Type] == Start || g_mapZones[zone][Type] == End)
		{
			new Float:point1[3];
			Array_Copy(g_mapZones[zone][Point1], point1, 3);

			new Float:point2[3];
			Array_Copy(g_mapZones[zone][Point2], point2, 3);
			
			if (point1[2] < point2[2])
				point2[2] = point1[2];
			else
				point1[2] = point2[2];

			if (g_mapZones[zone][Type] == Start)
				DrawBox(point1, point2, 2.0, g_startColor, true);
			else if (g_mapZones[zone][Type] == End)
				DrawBox(point1, point2, 2.0, g_endColor, true);
		}
	}

	return Plugin_Continue;
}

public Action:PlayerTracker(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsClientObserver(client))
		{
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			
			for (new zone = 0; zone < g_mapZonesCount; zone++)
			{
				if (IsInsideBox(vec, g_mapZones[zone][Point1][0], g_mapZones[zone][Point1][1], g_mapZones[zone][Point1][2], g_mapZones[zone][Point2][0], g_mapZones[zone][Point2][1], g_mapZones[zone][Point2][2]))
				{
					if (g_mapZones[zone][Type] == Start)
					{
						Timer_Stop(client, false);							
						Timer_Start(client);
						if (g_stopPrespeed)
							CheckVelocity(client);
					}
					else if (g_mapZones[zone][Type] == End)
					{
						if (Timer_Stop(client, false))
						{
							new bool:enabled = false;
							new jumps = 0;
							new Float:time;
							new fpsmax;

							if (Timer_GetClientTimer(client, enabled, time, jumps, fpsmax))
							{
								new difficulty = 0;
								if (g_timerPhysics)
									difficulty = Timer_GetClientDifficulty(client);

								Timer_FinishRound(client, g_currentMap, time, jumps, difficulty, fpsmax);
								
								if (g_timerWorldRecord)
									Timer_ForceReloadWorldRecordCache();
							}
						}
					}
					else if (g_mapZones[zone][Type] == Glitch1)
					{
						Timer_Stop(client);
					}
					else if (g_mapZones[zone][Type] == Glitch2)
					{
						Timer_Restart(client);
					}
					else if (g_mapZones[zone][Type] == Glitch3)
					{
						CS_RespawnPlayer(client);
					}

					break;
				}	
			}
		}		
	}

	return Plugin_Continue;
}

IsInsideBox(Float:fPCords[3], Float:fbsx, Float:fbsy, Float:fbsz, Float:fbex, Float:fbey, Float:fbez){
	new Float:fpx = fPCords[0];
	new Float:fpy = fPCords[1];
	new Float:fpz = fPCords[2];
	
	new bool:bX = false;
	new bool:bY = false;
	new bool:bZ = false;

	if (fbsx > fbex && fpx <= fbsx && fpx >= fbex)
		bX = true;
	else if (fbsx < fbex && fpx >= fbsx && fpx <= fbex)
		bX = true;
		
	if (fbsy > fbey && fpy <= fbsy && fpy >= fbey)
		bY = true;
	else if (fbsy < fbey && fpy >= fbsy && fpy <= fbey)
		bY = true;
	
	if (fbsz > fbez && fpz <= fbsz && fpz >= fbez)
		bZ = true;
	else if (fbsz < fbez && fpz >= fbsz && fpz <= fbez)
		bZ = true;
		
	if (bX && bY && bZ)
		return true;
	
	return false;
}

public Native_AddMapZone(Handle:plugin, numParams)
{
	decl String:map[32];
	GetNativeString(1, map, sizeof(map));
	
	new MapZoneType:type = GetNativeCell(2);	
	
	new Float:point1[3];
	GetNativeArray(3, point1, sizeof(point1));
	
	new Float:point2[3];
	GetNativeArray(3, point2, sizeof(point2));	
	
	AddMapZone(map, type, point1, point2);
}

DrawBox(Float:fFrom[3], Float:fTo[3], Float:fLife, color[4], bool:flat)
{
	//initialize tempoary variables bottom front
	decl Float:fLeftBottomFront[3];
	fLeftBottomFront[0] = fFrom[0];
	fLeftBottomFront[1] = fFrom[1];
	if(flat)
		fLeftBottomFront[2] = fTo[2]-2;
	else
		fLeftBottomFront[2] = fTo[2];
	
	decl Float:fRightBottomFront[3];
	fRightBottomFront[0] = fTo[0];
	fRightBottomFront[1] = fFrom[1];
	if(flat)
		fRightBottomFront[2] = fTo[2]-2;
	else
		fRightBottomFront[2] = fTo[2];
	
	//initialize tempoary variables bottom back
	decl Float:fLeftBottomBack[3];
	fLeftBottomBack[0] = fFrom[0];
	fLeftBottomBack[1] = fTo[1];
	if(flat)
		fLeftBottomBack[2] = fTo[2]-2;
	else
		fLeftBottomBack[2] = fTo[2];
	
	decl Float:fRightBottomBack[3];
	fRightBottomBack[0] = fTo[0];
	fRightBottomBack[1] = fTo[1];
	if(flat)
		fRightBottomBack[2] = fTo[2]-2;
	else
		fRightBottomBack[2] = fTo[2];
	
	//initialize tempoary variables top front
	decl Float:lefttopfront[3];
	lefttopfront[0] = fFrom[0];
	lefttopfront[1] = fFrom[1];
	if(flat)
		lefttopfront[2] = fFrom[2]+2;
	else
		lefttopfront[2] = fFrom[2]+100;
	decl Float:righttopfront[3];
	righttopfront[0] = fTo[0];
	righttopfront[1] = fFrom[1];
	if(flat)
		righttopfront[2] = fFrom[2]+2;
	else
		righttopfront[2] = fFrom[2]+100;
	
	//initialize tempoary variables top back
	decl Float:fLeftTopBack[3];
	fLeftTopBack[0] = fFrom[0];
	fLeftTopBack[1] = fTo[1];
	if(flat)
		fLeftTopBack[2] = fFrom[2]+2;
	else
		fLeftTopBack[2] = fFrom[2]+100;
	decl Float:fRightTopBack[3];
	fRightTopBack[0] = fTo[0];
	fRightTopBack[1] = fTo[1];
	if(flat)
		fRightTopBack[2] = fFrom[2]+2;
	else
		fRightTopBack[2] = fFrom[2]+100;
	
	//create the box
	TE_SetupBeamPoints(lefttopfront,righttopfront,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	TE_SetupBeamPoints(lefttopfront,fLeftTopBack,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	TE_SetupBeamPoints(fRightTopBack,fLeftTopBack,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	TE_SetupBeamPoints(fRightTopBack,righttopfront,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);

	if(!flat)
	{
		TE_SetupBeamPoints(fLeftBottomFront,fRightBottomFront,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fLeftBottomFront,fLeftBottomBack,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fLeftBottomFront,lefttopfront,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);

	
		TE_SetupBeamPoints(fRightBottomBack,fLeftBottomBack,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fRightBottomBack,fRightBottomFront,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fRightBottomBack,fRightTopBack,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	
		TE_SetupBeamPoints(fRightBottomFront,righttopfront,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
		TE_SetupBeamPoints(fLeftBottomBack,fLeftTopBack,precache_laser,0,0,0,fLife,3.0,3.0,10,0.0,color,0);TE_SendToAll(0.0);//TE_SendToClient(client, 0.0);
	}
}

ParseColor(const String:color[], result[])
{
	decl String:buffers[4][4];
	ExplodeString(color, " ", buffers, sizeof(buffers), sizeof(buffers[]));
	
	for (new i = 0; i < sizeof(buffers); i++)
		result[i] = StringToInt(buffers[i]);
}

CheckVelocity(client)
{
	new Float:ClientOrigin[3], Float:fVelocity[3];
	
	GetClientAbsOrigin(client, ClientOrigin);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	new speed = RoundToFloor(SquareRoot(Pow(fVelocity[0],2.0)+Pow(fVelocity[1],2.0)));
	if	(speed > 289)
	{
		fVelocity[0] = fVelocity[1] = fVelocity[2] = 0.0;
		TeleportEntity(client, ClientOrigin, NULL_VECTOR, fVelocity);
	}		
}
