#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <mapchooser>

#pragma newdecls required

#define PLUGIN_VERSION "0.1.3"
public Plugin myinfo = {
    name = "[TF2] Map Voting Tweaks",
    author = "nosoop",
    description = "Modifications to TF2's native map vote system.",
    version = PLUGIN_VERSION,
    url = "https://github.com/nosoop"
}

#define TABLE_SERVER_MAP_CYCLE "ServerMapCycle"
#define TABLEENTRY_SERVER_MAP_CYCLE "ServerMapCycle"

#define MAP_SANE_NAME_LENGTH 96

// Returns a full workshop name from a short name.
StringMap g_MapNameReference;

// Contains list of all maps from ServerMapCycle stringtable for restore on unload.
ArrayList g_FullMapList;

ConVar g_ConVarNextLevelAsNominate, g_ConVarEnforceExclusions;

// Allow next callvote from that client to go through
int g_bPassNextCallVote[MAXPLAYERS+1];

int g_iMapCycleStringTable;
bool g_bFinalizedMapCycleTable;

public void OnPluginStart() {
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	
	CreateConVar("sm_tfmapvote_version", PLUGIN_VERSION, "Current version of Map Voting Tweaks.", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_ConVarNextLevelAsNominate = CreateConVar("sm_tfmapvote_nominate", "1", "Specifies if the map vote menu is treated as a SourceMod nomination menu.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_ConVarEnforceExclusions = CreateConVar("sm_tfmapvote_exclude", "1", "Specifies if recent maps should be removed from the vote menu.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AddCommandListener(Command_CallVote, "callvote");
	
	g_FullMapList = new ArrayList(MAP_SANE_NAME_LENGTH);
	g_MapNameReference = new StringMap();
	
	if ((g_iMapCycleStringTable = FindStringTable(TABLE_SERVER_MAP_CYCLE)) == INVALID_STRING_INDEX) {
		SetFailState("Could not find %s stringtable", TABLE_SERVER_MAP_CYCLE);
	}
	
	AutoExecConfig();
}

public void OnMapEnd() {
	g_FullMapList.Clear();
	g_MapNameReference.Clear();
}

public void OnMapStart() {
	g_bFinalizedMapCycleTable = false;
	
	/**
	 * Process the mapcycle for late load.
	 * Doesn't fully resolve workshop maps otherwise.  See OnClientPostAdminCheck().
	 */
	ProcessServerMapCycleStringTable();
}

/**
 * Repopulates the map cycle table with all the maps it has acquired during the current map
 * (except shorthand workshop entries).
 */
public void OnPluginEnd() {
	if (g_FullMapList.Length > 0) {
		char mapName[MAP_SANE_NAME_LENGTH];
		
		StringMapSnapshot shorthandMapNames = g_MapNameReference.Snapshot();
		for (int i = 0; i < shorthandMapNames.Length; i++) {
			shorthandMapNames.GetKey(i, mapName, sizeof(mapName));
			
			int pos = g_FullMapList.FindString(mapName);
			if (pos > -1) {
				g_FullMapList.Erase(pos);
			}
		}
		
		ArrayList exportMapList = new ArrayList(MAP_SANE_NAME_LENGTH);
		
		// TODO remove "workshop/id" entries from written output iff long form exists?
		for (int i = 0; i < g_FullMapList.Length; i++) {
			g_FullMapList.GetString(i, mapName, sizeof(mapName));
			if (!IsWorkshopShortName(mapName)) {
				exportMapList.PushString(mapName);
			}
		}
		
		WriteServerMapCycleToStringTable(exportMapList);
		
		delete exportMapList;
	}
}

public void OnClientPostAdminCheck(int iClient) {
	/**
	 * Processing the table during an actual OnMapStart leaves short map workshop names that
	 * don't resolve to display names, so we're currently just going to process it when the
	 * first actual player is in-game, too.  It *should* be ready by then, riiiiight?
	 */
	if (!IsFakeClient(iClient)) {
		ProcessServerMapCycleStringTable();
		g_bFinalizedMapCycleTable = true;
	}
}

public Action Command_CallVote(int iClient, const char[] cmd, int nArg) {
	if (nArg < 2) {
		return Plugin_Continue;
	}
	
	char voteReason[16];
	GetCmdArg(1, voteReason, sizeof(voteReason));
	
	// Don't handle non-NextLevel / non-ChangeLevel votes.
	if (!StrEqual(voteReason, "NextLevel", false) && !StrEqual(voteReason, "ChangeLevel", false)) {
		return Plugin_Continue;
	}
	
	if (g_bPassNextCallVote[iClient]) {
		g_bPassNextCallVote[iClient] = false;
		return Plugin_Continue;
	}
	
	char nominatedShortMap[PLATFORM_MAX_PATH];
	GetCmdArg(2, nominatedShortMap, sizeof(nominatedShortMap));
	
	char mapFullName[PLATFORM_MAX_PATH];
	if (!g_MapNameReference.GetString(nominatedShortMap, mapFullName, sizeof(mapFullName))) {
		// The potential shorthand name is actually the full name.
		strcopy(mapFullName, sizeof(mapFullName), nominatedShortMap);
	}
	
	// Not using callvote as a nomination map picker.
	if (!g_ConVarNextLevelAsNominate.BoolValue || StrEqual(voteReason, "ChangeLevel", false)) {
		// Call the actual mapvote with the resolved map name.
		g_bPassNextCallVote[iClient] = true;
		
		FakeClientCommandEx(iClient, "callvote %s %s", voteReason, mapFullName);
		return Plugin_Handled;
	}
	
	ProcessMapNomination(iClient, mapFullName);
	
	return Plugin_Handled;
}

/**
 * Performs a map nomination, given a client and a full map name.
 */
void ProcessMapNomination(int iClient, const char[] nominatedMap) {
	ArrayList excludeMapList = new ArrayList(MAP_SANE_NAME_LENGTH);
	GetExcludeMapList(excludeMapList);

	bool bMapIsExcluded = excludeMapList.FindString(nominatedMap) > -1;
	delete excludeMapList;
	
	if (bMapIsExcluded) {
		PrintToChat(iClient, "%t", "Map in Exclude List");
		return;
	}

	// If a workshop map, use the shorthand ID-based version of the map name on nominate.
	// TODO this may change once a proper way to resolve map names is available
	char nominatedMapShorthand[PLATFORM_MAX_PATH];
	GetWorkshopShortName(nominatedMap, nominatedMapShorthand, sizeof(nominatedMapShorthand));
	
	NominateResult result = NominateMap(nominatedMapShorthand, false, iClient);
	
	char name[64];
	GetClientName(iClient, name, sizeof(name));
	
	char nominatedMapDisplay[PLATFORM_MAX_PATH];
	Compat_GetMapDisplayName(nominatedMap, nominatedMapDisplay, sizeof(nominatedMapDisplay));
	
	switch (result) {
		case Nominate_VoteFull: {
			PrintToChat(iClient, "%t", "Max Nominations");
		}
		case Nominate_InvalidMap: {
			PrintToChat(iClient, "%t", "Map was not found", nominatedMapDisplay);
		}
		case Nominate_AlreadyInVote: {
			PrintToChat(iClient, "%t", "Map Already Nominated");
		}
		case Nominate_Replaced: {
			PrintToChatAll("%t", "Map Nomination Changed", name, nominatedMapDisplay);
		}
		case Nominate_Added: {
			PrintToChatAll("%t", "Map Nominated", name, nominatedMapDisplay);
		}
	}
}

ArrayList ReadServerMapCycleFromStringTable() {
	int index = FindStringIndex(g_iMapCycleStringTable, TABLEENTRY_SERVER_MAP_CYCLE);
	
	if (index != INVALID_STRING_INDEX) {
		int dataLength = GetStringTableDataLength(g_iMapCycleStringTable, index);
		char[] mapData = new char[dataLength];
		GetStringTableData(g_iMapCycleStringTable, index, mapData, dataLength);
		
		return ArrayListFromStringLines(mapData);
	} else {
		SetFailState("Could not find %s string index in table.", TABLEENTRY_SERVER_MAP_CYCLE);
		return null;
	}
}

void WriteServerMapCycleToStringTable(ArrayList mapCycle) {
	int index = FindStringIndex(g_iMapCycleStringTable, TABLEENTRY_SERVER_MAP_CYCLE);
	
	if (index != INVALID_STRING_INDEX) {
		int dataLength = mapCycle.Length * MAP_SANE_NAME_LENGTH;
		char[] newMapData = new char[dataLength];
		StringLinesFromArrayList(mapCycle, newMapData, dataLength);
		
		bool bPreviousState = LockStringTables(false);
		SetStringTableData(g_iMapCycleStringTable, index, newMapData, dataLength);
		LockStringTables(bPreviousState);
	} else {
		SetFailState("Could not find %s string index in table.", TABLEENTRY_SERVER_MAP_CYCLE);
	}
}

/**
 * Modifies the ServerMapCycle stringtable.
 */
void ProcessServerMapCycleStringTable() {
	if (g_bFinalizedMapCycleTable) {
		return;
	}
	
	ArrayList maps = ReadServerMapCycleFromStringTable();
	
	ArrayList excludeMapList = new ArrayList(MAP_SANE_NAME_LENGTH);
	GetExcludeMapList(excludeMapList);
	
	/**
	 * Map cycle isn't finalized, and if this is not the first run through some maps might have
	 * been removed.
	 */
	CopyUniqueStringArrayList(maps, g_FullMapList);
	
	ArrayList newMaps = new ArrayList(MAP_SANE_NAME_LENGTH);
	for (int m = 0; m < g_FullMapList.Length; m++) {
		char mapBuffer[MAP_SANE_NAME_LENGTH], shortMapBuffer[MAP_SANE_NAME_LENGTH];
		g_FullMapList.GetString(m, mapBuffer, sizeof(mapBuffer));
		
		if (Compat_GetMapDisplayName(mapBuffer, shortMapBuffer, sizeof(shortMapBuffer))) {
			// Workshop map that we haven't added yet?  Add the display name.
			if (g_MapNameReference.SetString(shortMapBuffer, mapBuffer, false)) {
				newMaps.PushString(shortMapBuffer);
			}
		} else if (!g_ConVarEnforceExclusions.BoolValue || excludeMapList.FindString(mapBuffer) == -1) {
			if (!IsWorkshopShortName(mapBuffer)) {
				newMaps.PushString(mapBuffer);
			}
		}
	}
	WriteServerMapCycleToStringTable(newMaps);
	
	delete newMaps;
	delete maps;
	delete excludeMapList;
}

/**
 * Explodes a string by newlines, returning the individual strings as an ArrayList.
 */
ArrayList ArrayListFromStringLines(const char[] text) {
	int reloc_idx, idx;
	char buffer[PLATFORM_MAX_PATH];
	
	ArrayList result = new ArrayList(PLATFORM_MAX_PATH);
	
	while ((idx = SplitString(text[reloc_idx], "\n", buffer, sizeof(buffer))) != -1) {
		reloc_idx += idx;
		result.PushString(buffer);
	}
	result.PushString(buffer);
	return result;
}

/**
 * Joins strings from an ArrayList with newlines and stores it in buffer `result`.
 */
void StringLinesFromArrayList(ArrayList lines, char[] result, int length) {
	char buffer[PLATFORM_MAX_PATH];
	
	if (lines.Length > 0) {
		for (int i = 0; i < lines.Length; i++) {
			lines.GetString(i, buffer, sizeof(buffer));
			StrCat(result, length, buffer);
			StrCat(result, length, "\n");
		}
	}
}

void CopyUniqueStringArrayList(ArrayList src, ArrayList dest) {
	for (int i = 0; i < src.Length; i++) {
		char str[MAP_SANE_NAME_LENGTH];
		src.GetString(i, str, sizeof(str));
		
		if (dest.FindString(str) == -1) {
			dest.PushString(str);
		}
	}
}

/**
 * Attempts to resolve a TF2 long map workshop name into a display map name.
 * Populates the buffer with mapName if not a workshop map.
 */
bool Compat_GetMapDisplayName(const char[] mapName, char[] buffer, int length) {
	// TODO is there any way to check for the existence of GetMapDisplayName?
	strcopy(buffer, length, mapName);
	if (IsWorkshopLongName(mapName)) {
		// Trim off workshop directory, strip off the map ID onwards
		strcopy(buffer, length, buffer[9]);
		strcopy(buffer, StrContains(buffer, ".ugc") + 1, buffer);
		return true;
	}
	return false;
}

/**
 * Attempts to resolve a TF2 long map workshop name into a "workshop/$ID" map name.
 * Populates the buffer with mapName if not a workshop map.
 */
bool GetWorkshopShortName(const char[] mapName, char[] buffer, int length) {
	// TODO remove when proper workshop support is implemented
	strcopy(buffer, length, mapName);
	if (IsWorkshopLongName(mapName)) {
		// Extract workshop id, format buffer appropriately
		char id[12];
		strcopy(id, sizeof(id), buffer[StrContains(buffer, ".ugc") + 4]);
		Format(buffer, length, "workshop/%s", id);
		return true;
	}
	return false;
}

bool IsWorkshopShortName(const char[] mapName) {
	return StrContains(mapName, "workshop/", true) == 0 && StrContains(mapName, ".ugc") == -1;
}

bool IsWorkshopLongName(const char[] mapName) {
	return StrContains(mapName, "workshop/", true) == 0 && StrContains(mapName, ".ugc") > -1;
}