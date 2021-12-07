#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "[CSGO] ChangeMode",
	author = "chinagreenelvis",
	description = "Changes the mode and picks a random map to play.",
	version = "1.0",
	url = "http://www.chinagreenelvis.com/"
};

new Handle:g_Cvar_ExcludeMaps = INVALID_HANDLE;

new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_OldMapList = INVALID_HANDLE;
new g_mapListSerial = -1;

public OnPluginStart()
{
	new arraySize = ByteCountToCells(257);	
	g_MapList = CreateArray(arraySize);
	g_OldMapList = CreateArray(arraySize);

	g_Cvar_ExcludeMaps = CreateConVar("sm_changemap_randomcycle_exclude", "5", "Specifies how many past maps to exclude from the random selection.", _, true, 0.0);
	
	RegAdminCmd("sm_changemode_casual", ChangeModeCasual, ADMFLAG_CHANGEMAP, "Sets the mode to casual.");
	RegAdminCmd("sm_changemode_competetive", ChangeModeCompetetive, ADMFLAG_CHANGEMAP, "Sets the mode to competetive.");
	RegAdminCmd("sm_changemode_armsrace", ChangeModeArmsrace, ADMFLAG_CHANGEMAP, "Sets the mode to armsrace.");
	RegAdminCmd("sm_changemode_demolition", ChangeModeDemolition, ADMFLAG_CHANGEMAP, "Sets the mode to demolition.");
	RegAdminCmd("sm_changemode_deathmatch", ChangeModeDeathmatch, ADMFLAG_CHANGEMAP, "Sets the mode to deathmatch.");
	
	RegAdminCmd("sm_changemap", ChangeMap, ADMFLAG_CHANGEMAP, "Changes the map to a random map in the current or selected game mode.");
	
	AutoExecConfig(true, "changemap");
}

public OnConfigsExecuted()
{
	if (ReadMapList(g_MapList, 
					g_mapListSerial, 
					"randomcycle", 
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== INVALID_HANDLE)
	{
		if (g_mapListSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}
	
	CreateTimer(5.0, Timer_RandomizeNextmap); // Small delay to give Nextmap time to complete OnMapStart()
}

public Action:Timer_RandomizeNextmap(Handle:timer)
{
	decl String:map[256];

	new bool:oldMaps = false;
	if (GetConVarInt(g_Cvar_ExcludeMaps) && GetArraySize(g_MapList) > GetConVarInt(g_Cvar_ExcludeMaps))
	{
		oldMaps = true;
	}
	
	new b = GetRandomInt(0, GetArraySize(g_MapList) - 1);
	GetArrayString(g_MapList, b, map, sizeof(map));

	while (oldMaps && FindStringInArray(g_OldMapList, map) != -1)
	{
		b = GetRandomInt(0, GetArraySize(g_MapList) - 1);
		GetArrayString(g_MapList, b, map, sizeof(map));
	}
	
	PushArrayString(g_OldMapList, map);
	SetNextMap(map);

	if (GetArraySize(g_OldMapList) > GetConVarInt(g_Cvar_ExcludeMaps))
	{
		RemoveFromArray(g_OldMapList, 0);
	}

	LogAction(-1, -1, "RandomCycle has chosen %s for the nextmap.", map);	

	return Plugin_Stop;
}

public Action:ChangeModeCasual(client, args)
{
	SetConVarInt(FindConVar("game_type"), 0);
	SetConVarInt(FindConVar("game_mode"), 0);
	SetConVarString(FindConVar("mapcyclefile"), "mapcycle.txt");
	MapChange();
}

public Action:ChangeModeCompetetive(client, args)
{
	SetConVarInt(FindConVar("game_type"), 0);
	SetConVarInt(FindConVar("game_mode"), 1);
	SetConVarString(FindConVar("mapcyclefile"), "mapcycle_competetive.txt");
	MapChange();
}

public Action:ChangeModeArmsrace(client, args)
{
	SetConVarInt(FindConVar("game_type"), 1);
	SetConVarInt(FindConVar("game_mode"), 0);
	SetConVarString(FindConVar("mapcyclefile"), "mapcycle_armsrace.txt");
	MapChange();
}

public Action:ChangeModeDemolition(client, args)
{
	SetConVarInt(FindConVar("game_type"), 1);
	SetConVarInt(FindConVar("game_mode"), 1);
	SetConVarString(FindConVar("mapcyclefile"), "mapcycle_demolition.txt");
	MapChange();
}

public Action:ChangeModeDeathmatch(client, args)
{
	SetConVarInt(FindConVar("game_type"), 1);
	SetConVarInt(FindConVar("game_mode"), 2);
	SetConVarString(FindConVar("mapcyclefile"), "mapcycle_deathmatch.txt");
	MapChange();
}

public Action:ChangeMap(client, args)
{
	MapChange();
}

MapChange()
{
	if (ReadMapList(g_MapList, 
					g_mapListSerial, 
					"randomcycle", 
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== INVALID_HANDLE)
	{
		if (g_mapListSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}
	
	CreateTimer(1.0, Timer_ChangeMap);
}

public Action:Timer_ChangeMap(Handle:timer)
{
	decl String:map[256];

	new bool:oldMaps = false;
	if (GetConVarInt(g_Cvar_ExcludeMaps) && GetArraySize(g_MapList) > GetConVarInt(g_Cvar_ExcludeMaps))
	{
		oldMaps = true;
	}
	
	new b = GetRandomInt(0, GetArraySize(g_MapList) - 1);
	GetArrayString(g_MapList, b, map, sizeof(map));

	while (oldMaps && FindStringInArray(g_OldMapList, map) != -1)
	{
		b = GetRandomInt(0, GetArraySize(g_MapList) - 1);
		GetArrayString(g_MapList, b, map, sizeof(map));
	}
	
	PushArrayString(g_OldMapList, map);
	ForceChangeLevel(map, "Switching to a new map.");

	if (GetArraySize(g_OldMapList) > GetConVarInt(g_Cvar_ExcludeMaps))
	{
		RemoveFromArray(g_OldMapList, 0);
	}

	LogAction(-1, -1, "ChangeMode has changed the map to %s.", map);	

	return Plugin_Stop;
}