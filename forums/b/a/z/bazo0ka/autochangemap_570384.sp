//AutoChangeMap
//By bazooka
//Based off of AutoChangeLevel plugin by Nicolous
//Map cycle code taken from SourceMod's nextmap plugin
//
//
//...I basically did nothing.

#include <sourcemod>

#define __VERSION__ "1.1"
 
new Handle:acm_client_limit = INVALID_HANDLE
new Handle:acm_include_bots = INVALID_HANDLE
new Handle:acm_time_limit = INVALID_HANDLE
new Handle:acm_mode = INVALID_HANDLE
new Handle:acm_default_map = INVALID_HANDLE
new Handle:acm_config_to_exec = INVALID_HANDLE

new Handle:g_MapList = INVALID_HANDLE

new g_MapPos
new g_MapListSerial
new minutesBelowClientLimit
new bool:autoMapChangeOccured

public Plugin:myinfo = 
{
	name = "autochangemap",
	author = "bazooka",
	description = "Changes the map if 'x' or fewer players are on the server after 'y' consecutive minutes, as defined by the server operator.",
	version = __VERSION__,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("autochangemap_version",__VERSION__,"AutoChangeMap plugin version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	acm_client_limit = CreateConVar("autochangemap_client_limit", "1", "Number of clients that must be connected before automatic map changes are disabled.  Zero disables automatic map changes.", _, true, 0.0, false, 0.0)
	acm_include_bots = CreateConVar("autochangemap_include_bots", "0", "Include bots in the client count (remember, SourceTV counts as a bot).", _, true, 0.0, true, 1.0)
	acm_time_limit = CreateConVar("autochangemap_time_limit", "10", "Consecutive minutes which must pass while the client limit has not been reached for the automatic map change to occur.  Zero disables automatic map changes.", _, true, 0.0, false, 0.0)
	acm_mode = CreateConVar("autochangemap_mode", "0", "Method of choosing the next map in automatic map changes: 0 = custom mapcycle (create new section in sourcemod/configs/maplists.cfg), 1 = sm_nextmap/mapcycle (requires nextmap.smx), 2 = load map in autochangemap_default_map cvar, 3 = reload current map.", _, true, 0.0, true, 3.0)
	acm_default_map = CreateConVar("autochangemap_default_map", "", "Map to load at automatic map changes when autochangemap_mode is set to '2.'")
	acm_config_to_exec = CreateConVar("autochangemap_config_to_exec", "", "Config to exec when an automatic map change occurs, if desired.  Executes after the map loads and server.cfg and SourceMod plugin configs are exec'd.")
	
	g_MapList = CreateArray(32);

	g_MapPos = -1
	g_MapListSerial = -1
	minutesBelowClientLimit = 0
	autoMapChangeOccured = false

	AutoExecConfig(true, "autochangemap")
}

public OnConfigsExecuted()
{
	new String:acmConfigToExecValue[32]
	GetConVarString(acm_config_to_exec, acmConfigToExecValue, sizeof(acmConfigToExecValue))
	if (autoMapChangeOccured && strcmp(acmConfigToExecValue, "") != 0)
	{
		PrintToServer("AutoChangeMap : Exec'ing %s.", acmConfigToExecValue)
		ServerCommand("exec %s", acmConfigToExecValue)
	}

	minutesBelowClientLimit = 0
	autoMapChangeOccured = false

	CreateTimer(60.0, CheckPlayerCount, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
}

public Action:CheckPlayerCount(Handle:timer)
{
	new acmClientLimitValue = GetConVarInt(acm_client_limit)
	if (GetConVarInt(acm_include_bots) == 0)
	{
		new maxClients = GetMaxClients()
		new players = 0
		for (new i = 1; i <= maxClients; i++)
		{
			if (IsClientConnected(i))
			{
				if (!IsFakeClient(i))
				{
					players++
				}
			}
		}
		if (players < acmClientLimitValue)
		{
			minutesBelowClientLimit++
		}
		else
		{
			minutesBelowClientLimit = 0
		}
	}
	else
	{
		if (GetClientCount() < acmClientLimitValue)
		{
			minutesBelowClientLimit++
		}
		else
		{
			minutesBelowClientLimit = 0
		}
	}
	
	if (minutesBelowClientLimit >= GetConVarInt(acm_time_limit))
	{
		SetMap()
	}
	return Plugin_Continue
}

SetMap()
{	
	new acmModeValue = GetConVarInt(acm_mode)
	new String:nextmap[32]
	
	switch(acmModeValue)
	{
		case 0:
		{
			if (ReadMapList(g_MapList, 
					g_MapListSerial, 
					"autochangemap", 
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT)
					== INVALID_HANDLE)
			{
				if (g_MapListSerial == -1)
				{
					LogError("FATAL: Cannot load map cycle.")
					SetFailState("Mapcycle Not Found")
				}
			}
			
			new mapCount = GetArraySize(g_MapList)
			
			if (g_MapPos == -1)
			{
				decl String:current[64]
				GetCurrentMap(current, 64)
				
				for (new i = 0; i < mapCount; i++)
				{
					GetArrayString(g_MapList, i, nextmap, sizeof(nextmap))
					if (strcmp(current, nextmap, false) == 0)
					{
						g_MapPos = i
						break;
					}
				}
				
				if (g_MapPos == -1)
				{
					g_MapPos = 0
				}
			}
			
			g_MapPos++
			if (g_MapPos >= mapCount)
			{
				g_MapPos = 0;
			}
			
			GetArrayString(g_MapList, g_MapPos, nextmap, sizeof(nextmap))
			if (!IsMapValid(nextmap))
			{
				PrintToServer("AutoChangeMap : invalid map name ('%s') found in mapcycle.  Reloading current map...", nextmap)
				GetCurrentMap(nextmap, sizeof(nextmap))
			}
		}
		
		case 1:
		{
			new Handle:h_sm_nextmap = FindConVar("sm_nextmap")
			if (h_sm_nextmap == INVALID_HANDLE)
			{	
				LogError("FATAL: Cannot find sm_nextmap cvar.");
				SetFailState("sm_nextmap not found");
			}
			
			GetConVarString(h_sm_nextmap, nextmap, sizeof(nextmap))
			if (!IsMapValid(nextmap))
			{
				PrintToServer("AutoChangeMap : sm_nextmap ('%s') does not contain valid map name.  Reloading current map...", nextmap)
				GetCurrentMap(nextmap, sizeof(nextmap))
				SetConVarString(h_sm_nextmap, nextmap)
			}
			CloseHandle(h_sm_nextmap)
		}

		case 2:
		{
			GetConVarString(acm_default_map, nextmap, sizeof(nextmap))
			if (!IsMapValid(nextmap))
			{
				PrintToServer("AutoChangeMap : autochangemap_default_map ('%s') does not contain valid map name.  Reloading current map...", nextmap)
				GetCurrentMap(nextmap, sizeof(nextmap))
			}
		}

		default:
		{
			GetCurrentMap(nextmap, sizeof(nextmap))
		}
	}

	new Handle:nextmapPack
	CreateDataTimer(5.0, ChangeMap, nextmapPack, TIMER_FLAG_NO_MAPCHANGE)
	WritePackString(nextmapPack, nextmap)
	PrintToChatAll("AutoChangeMap : Changing map to %s.", nextmap)
}

public Action:ChangeMap(Handle:timer, Handle:mapPack)
{
	new String:map[32]
	ResetPack(mapPack)
	ReadPackString(mapPack, map, sizeof(map))
	autoMapChangeOccured = true
	ServerCommand("changelevel %s", map)
}