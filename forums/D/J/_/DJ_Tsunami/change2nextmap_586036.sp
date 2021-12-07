#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "0.5"

public Plugin:myinfo = {
	name        = "Change2NextMap",
	author      = "Tsunami",
	description = "Change the map to the next map set.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
};

new Handle:g_hMapList;
new String:g_sConVar[PLATFORM_MAX_PATH];
static String:g_sConVars[] = {"sm_nextmap", "bm_nextmap", "mani_nextmap", "amx_nextmap"};

public OnPluginStart() {
	CreateConVar("sm_change2nextmap_version", PL_VERSION, "Change the map to the next map set.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegServerCmd("sm_change2nextmap", Command_Change2NextMap);
	
	g_hMapList = CreateArray(PLATFORM_MAX_PATH);
	
	for (new i = 0; i < sizeof(g_sConVars); i++) {
		if (FindConVar(g_sConVars[i]) != INVALID_HANDLE) {
			strcopy(g_sConVar, sizeof(g_sConVar), g_sConVars[i]);
			break;
		}
	}
}

public OnMapStart() {
	if (FindConVar(g_sConVar) == INVALID_HANDLE) {
		ReadMapList(g_hMapList, _, _, MAPLIST_FLAG_CLEARARRAY);
		
		if (GetArraySize(g_hMapList) == 0) {
			SetFailState("Mapcycle Not Found");
		}
	}
}

public Action:Command_Change2NextMap(args) {
	new bNextMap = false, Handle:hNextMap = FindConVar(g_sConVar), String:sNextMap[PLATFORM_MAX_PATH];
	
	if (hNextMap == INVALID_HANDLE) {
		new String:sCurrentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
		
		for (new i = 0; i < GetArraySize(g_hMapList); i++) {
			GetArrayString(g_hMapList, i, sNextMap, sizeof(sNextMap));
			
			if (StrEqual(sNextMap, sCurrentMap)) {
				bNextMap = true;
				i        = (i == GetArraySize(g_hMapList) - 1 ? 0 : ++i);
				GetArrayString(g_hMapList, i, sNextMap, sizeof(sNextMap));
				
				while (!IsMapValid(sNextMap)) {
					i      = (i == GetArraySize(g_hMapList) - 1 ? 0 : ++i);
					GetArrayString(g_hMapList, i, sNextMap, sizeof(sNextMap));
				}
				
				break;
			}
		}
		
		if (!bNextMap) {
			GetArrayString(g_hMapList, 0, sNextMap, sizeof(sNextMap));
		}
	} else {
		GetConVarString(hNextMap, sNextMap, sizeof(sNextMap));
	}
	
	if (IsMapValid(sNextMap)) {
		ServerCommand("changelevel %s", sNextMap);
	} else {
		LogError("Map Name \"%s\" Invalid.", sNextMap);
	}
}