/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Dynamic Map Rotations
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define DMR_VERSION	    "0.7"

#define CVAR_CONFIG	    0
#define CVAR_VERSION	    1
#define CVAR_MAP_KEY	    2
#define CVAR_CHAT_TIME	    3
#define CVAR_FORCE_NEXTMAP  4
#define CVAR_NEXTMAP	    5
#define CVAR_LOCK	    6
#define CVAR_NUM_CVARS	    7

#define MAX_CONDITIONS	    8
#define MAX_KEY_LENGTH	    32
#define MAX_VAL_LENGTH	    32

new Handle:g_cvars[CVAR_NUM_CVARS];
new Handle:g_rotation = INVALID_HANDLE;
new UserMsg:g_VGUIMenu;
new bool:g_IntermissionCalled = false;
new bool:g_ForceNextMap = false;
new day_array[] = {'\0', 'm', 't', 'w', 'r', 'f', 's', 'u'};
new Handle:g_updateNextMapTimer = INVALID_HANDLE;

enum CompareTimeType {
    NOW_LTE_TIME = 0,
    NOW_GTE_TIME
};

enum CompareTimeResult {
    NOW_LT_TIME = 0,
    NOW_EQ_TIME,
    NOW_GT_TIME
};

public Plugin:myinfo = {
    name = "Dynamic Map Rotations",
    author = "Ryan \"FLOOR_MASTER\" Mannion",
    description = "Dynamically alters the map rotation based on server conditions.",
    version = DMR_VERSION,
    url = "http://www.2fort2furious.com"
};

public OnPluginStart() {

    /* TODO Translations */
    LoadTranslations("common.phrases");

    if (FindPluginByFile("nextmap.smx") != INVALID_HANDLE) {
        LogError("FATAL: This plugin replaces nextmap. You must remove nextmap.smx to load this plugin.");
        SetFailState("This plugin replaces nextmap. You must remove nextmap.smx to load this plugin.");
    }

    g_VGUIMenu = GetUserMessageId("VGUIMenu");
    if (g_VGUIMenu == INVALID_MESSAGE_ID) {
        LogError("FATAL: Cannot find VGUIMenu user message id. Dynamic Map Rotations not loaded.");
        SetFailState("VGUIMenu Not Found.");
    }
    HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);

    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
    RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "sm_setnextmap <map>");
    RegAdminCmd("sm_unsetnextmap", Command_UnSetNextmap, ADMFLAG_CHANGEMAP, "sm_unsetnextmap");
    RegAdminCmd("sm_reloaddmr", Command_ReloadDMR, ADMFLAG_CHANGEMAP, "sm_reloaddmr");

    /* TODO: debug command... remove eventually */
    RegAdminCmd("dmr", Command_DMR, ADMFLAG_ROOT);
    RegAdminCmd("dmr2", Command_DMR2, ADMFLAG_ROOT);

    g_cvars[CVAR_VERSION] = CreateConVar(
	"dmr_version",
	DMR_VERSION,
	"Dynamic Map Rotations Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_CONFIG] = CreateConVar(
	"dmr_file",
	"dmr.txt",
	"Location of the rotation keyvalues file",
	FCVAR_PLUGIN);

    g_cvars[CVAR_MAP_KEY] = CreateConVar(
	"dmr_map_key",
	"",
	"The key used to base nextmap decisions on",
	FCVAR_PLUGIN);

    g_cvars[CVAR_FORCE_NEXTMAP] = CreateConVar(
	"dmr_force_nextmap",
	"",
	"Override the nextmap",
	FCVAR_PLUGIN);

    g_cvars[CVAR_NEXTMAP] = CreateConVar(
	"sm_nextmap",
	"",
	"The current nextmap",
	FCVAR_PLUGIN);

    g_cvars[CVAR_LOCK] = CreateConVar(
	"dmr_lock_intermission",
	"0",
	"DESCRIPTION",
	FCVAR_PLUGIN);

    g_cvars[CVAR_CHAT_TIME] = FindConVar("mp_chattime");

    LoadRotation(true);

    g_updateNextMapTimer = CreateTimer(60.0, Timer_UpdateNextMap, _, TIMER_REPEAT);

    PrintToServer("Dynamic Map Rotations Loaded");
}

stock PrintIndent(const String:text[], prefix) {
    decl String:text2[256];

    for (new i = 0; i < prefix; i++) {
	text2[i] = ' ';
    }
    strcopy(text2[prefix], sizeof(text2) - prefix, text);
    PrintToServer(text2);
}

/* LoadRotation {{{ */
stock LoadRotation(bool:reset_map_key=false) {
    decl String:config[64];
    decl String:key[MAX_KEY_LENGTH];
    decl String:val[MAX_VAL_LENGTH];
    GetConVarString(g_cvars[CVAR_CONFIG], config, sizeof(config));

    if (g_rotation != INVALID_HANDLE) {
	CloseHandle(g_rotation);
    }

    g_rotation = CreateKeyValues("rotation");

    if (!FileToKeyValues(g_rotation, config)) {
        LogError("FATAL: Could not read rotation file \"%s\"", config);
        SetFailState("Could not read rotation file \"%s\"", config);
    }

    /* reset_map_key should only be true if the plugin was just loaded.
     * Set the dmr_map_key cvar properly if it's not already set to a valid
     * section key. */
    if (reset_map_key) {
	GetConVarString(g_cvars[CVAR_MAP_KEY], key, sizeof(key));
	if (!strlen(key) || !KvJumpToKey(g_rotation, key)) {
	    KvGetString(g_rotation, "start", val, sizeof(val));
	    if (strlen(val) && KvJumpToKey(g_rotation, val)) {
		LogMessage("Reset dmr_map_key to \"%s\"", val);
		SetConVarString(g_cvars[CVAR_MAP_KEY], val);
	    }
	    else {
		LogError("FATAL: a valid \"start\" key was not defined in \"%s\"", config);
		SetFailState("A valid \"start\" key was not defined in \"%s\"", config);
	    }
	}
    }

    KvRewind(g_rotation);
}
/* }}} LoadRotation */

/* GetAdminsCount {{{ */
stock GetAdminsCount() {
    new count = 0;

    for (new i = 1; i <= GetMaxClients(); i++) {
	if (IsClientInGame(i) && !IsFakeClient(i) && GetUserAdmin(i) != INVALID_ADMIN_ID) {
	    count++;
	}
    }

    return count;
}
/* }}} GetAdminsCount */

/* GetPlayersCount {{{ */
stock GetPlayersCount() {
    new count = 0;

    for (new i = 1; i <= GetMaxClients(); i++) {
	if (IsClientInGame(i) && !IsFakeClient(i)) {
	    count++;
	}
    }

    return count;
}
/* }}} GetPlayersCount */

/* CustomConditionsMet {{{ */
/**
 * @return		True if all the custom conditions specified evaluate to
 *			true, false otherwise.
 */
stock bool:CustomConditionsMet(Handle:kv) {
    decl String:val[MAX_VAL_LENGTH];

    if (KvGetDataType(kv, "players_lte") != KvData_None) {
	new count = KvGetNum(kv, "players_lte");
	if (!(GetPlayersCount() <= count)) {
	    return false;
	}
    }

    if (KvGetDataType(kv, "players_gte") != KvData_None) {
	new count = KvGetNum(kv, "players_gte");
	if (!(GetPlayersCount() >= count)) {
	    return false;
	}
    }

    if (KvGetDataType(kv, "admins_lte") != KvData_None) {
	new count = KvGetNum(kv, "admins_lte");
	if (!(GetAdminsCount() <= count)) {
	    return false;
	}
    }

    if (KvGetDataType(kv, "admins_gte") != KvData_None) {
	new count = KvGetNum(kv, "admins_gte");
	if (!(GetAdminsCount() >= count)) {
	    return false;
	}
    }

    if (KvGetDataType(kv, "time_gte") != KvData_None && 
	KvGetDataType(kv, "time_lte") != KvData_None
    ) {
	decl String:val2[MAX_VAL_LENGTH];
	KvGetString(kv, "time_gte", val, sizeof(val));
	KvGetString(kv, "time_lte", val2, sizeof(val2));

	if (!CompareTimeRange(val, val2)) {
	    return false;
	}
    }
    else if (KvGetDataType(kv, "time_gte") != KvData_None) {
	KvGetString(kv, "time_gte", val, sizeof(val));
	if (!CompareTimeFromString(val, NOW_GTE_TIME)) {
	    return false;
	}
    }
    else if (KvGetDataType(kv, "time_lte") != KvData_None) {
	KvGetString(kv, "time_lte", val, sizeof(val));
	if (!CompareTimeFromString(val, NOW_LTE_TIME)) {
	    return false;
	}
    }

    if (KvGetDataType(kv, "day_eq") != KvData_None) {
	KvGetString(kv, "day_eq", val, sizeof(val));
	if (!CompareDayOfWeek(val)) {
	    return false;
	}
    }

    if (KvGetDataType(kv, "day_neq") != KvData_None) {
	KvGetString(kv, "day_neq", val, sizeof(val));
	if (CompareDayOfWeek(val)) {
	    return false;
	}
    }

    return true;
}
/* }}} CustomConditionsMet */

/* Command_ReloadDMR {{{ */
public Action:Command_ReloadDMR(client, args) {
    decl String:response[256];
    decl String:config[64];
    decl String:nextmap[MAX_VAL_LENGTH];
    decl String:nextmap_key[MAX_VAL_LENGTH];
    decl String:dmr_map_key[MAX_VAL_LENGTH];

    GetConVarString(g_cvars[CVAR_CONFIG], config, sizeof(config));
    GetConVarString(g_cvars[CVAR_MAP_KEY], dmr_map_key, sizeof(dmr_map_key));

    LoadRotation();

    if (DetermineNextMap(dmr_map_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap))) {
	Format(response, sizeof(response), "Reloaded DMR: %s. dmr_map_key is %s, nextmap_key is %s, nextmap is: %s%s.",
	    config, dmr_map_key, nextmap_key, nextmap, (g_ForceNextMap ? " (forced via sm_setnextmap)" : ""));
    }
    else {
	Format(response, sizeof(response), "Reloaded DMR: %s.", config);
    }

    ReplyToCommand(client, "[DMR] %s", response);

    return Plugin_Continue;
}
/* }}} Command_ReloadDMR */

/* Command_UnSetNextMap {{{ */
public Action:Command_UnSetNextmap(client, args) {
    LogMessage("\"%L\" executed sm_unsetnextmap", client);

    if (g_ForceNextMap) {
	g_ForceNextMap = false;
	ReplyToCommand(client, "[DMR] Forced nextmap unset");
    }
    else {
	ReplyToCommand(client, "[DMR] There was no forced nextmap to unset");
    }

    return Plugin_Handled;
}
/* }}} Command_UnSetNextMap */

/* Command_SetNextMap {{{ */
/* Lifted from nextmap.sp */
public Action:Command_SetNextmap(client, args) {
    if (args < 1) {
	ReplyToCommand(client, "[DMR] Usage: sm_setnextmap <map>");
	SetConVarString(g_cvars[CVAR_FORCE_NEXTMAP], "");
	g_ForceNextMap = false;
	return Plugin_Handled;
    }

    decl String:map[64];
    GetCmdArg(1, map, sizeof(map));

    if (!IsMapValid(map)) {
	ReplyToCommand(client, "[DMR] %t", "Map was not found", map);
	SetConVarString(g_cvars[CVAR_FORCE_NEXTMAP], "");
	g_ForceNextMap = false;
	return Plugin_Handled;
    }

    ShowActivity(client, "%t", "Cvar changed", "sm_nextmap", map);
    LogMessage("\"%L\" changed sm_nextmap to \"%s\"", client, map);

    g_ForceNextMap = true;
    SetConVarString(g_cvars[CVAR_FORCE_NEXTMAP], map);

    return Plugin_Handled;
}
/* }}} Command_SetNextMap */

stock bool:CompareDayOfWeek(const String:days[]) {
    decl String:day_str[3];
    FormatTime(day_str, sizeof(day_str), "%u");
    new day = StringToInt(day_str);

    Format(day_str, sizeof(day_str), "%s", day_array[day]);

    if (day > 0 && day < sizeof(day_array)
	&& StrContains(days, day_str) >= 0) {
	return true;
    }

    return false;
}

/* TODO: debug command... remove eventually */
public Action:Command_DMR2(client, args) {
    CreateTimer(0.0, Timer_SayNextMaps, client);
}

/* TODO: debug command... remove eventually */
public Action:Command_DMR(client, args) {
    Command_ReloadDMR(client, args);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) {
    CreateNative("GetNextMaps", Native_GetNextMaps);
    return true;
}

public Native_GetNextMaps(Handle:plugin, numParams) {
    new Handle:dp = GetNextMaps(GetNativeCell(2));
    new Handle:dpCloned = CloneHandle(dp, plugin);
    CloseHandle(dp);
    SetNativeCellRef(1, dpCloned);
    return;
}

/* GetNextMaps {{{ */
stock Handle:GetNextMaps(count=0) {
    decl String:start_key[MAX_KEY_LENGTH];
    decl String:current_key[MAX_KEY_LENGTH];
    decl String:nextmap_key[MAX_KEY_LENGTH];
    decl String:nextmap[MAX_VAL_LENGTH];

    GetConVarString(g_cvars[CVAR_MAP_KEY], start_key, sizeof(start_key));
    strcopy(current_key, sizeof(current_key), start_key);

    new Handle:dp = CreateDataPack();
    new i = 0;
    new Handle:nextmaps = CreateArray(MAX_VAL_LENGTH);

    /* This is an ugly two-step process since we store the number of maps first
     * in the datapack, and the number of maps returned isn't necessarily the
     * same as the count parameter due to cycles in the rotation */
    while (i < count) {
    // while (i < count || count == 0) {
	if (DetermineNextMapKey(current_key, nextmap_key, sizeof(nextmap_key))) {
	    GetMapFromKey(nextmap_key, nextmap, sizeof(nextmap));
	    PushArrayString(nextmaps, nextmap);
	    strcopy(current_key, sizeof(current_key), nextmap_key);

	    /* Stop if we cycle back to the key we started from */
	    if (!strcmp(start_key, nextmap_key)) {
		break;
	    }
	}
	else {
	    return INVALID_HANDLE;
	}
	i++;
    }

    /* Fill in the datapack */
    new nextmaps_size = GetArraySize(nextmaps);
    WritePackCell(dp, nextmaps_size);

    /* Special exception for the first map, which might be overriden */
    if (g_ForceNextMap && nextmaps_size) {
	DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap));
	WritePackString(dp, nextmap);
	nextmaps_size--;
    }

    for (i = 0; i < nextmaps_size; i++) {
	GetArrayString(nextmaps, i, nextmap, sizeof(nextmap));
	WritePackString(dp, nextmap);
    }

    CloseHandle(nextmaps);
    ResetPack(dp);
    return dp;
}
/* }}} GetNextMaps */

/* DetermineNextMap {{{ */
/** Find the name of the nextmap based on the current server conditions. Also
 * take into consideration if a forced nextmap has been requested.
 *
 * @param start_key		Which key's conditions to evaluate.
 * @param nextmap_key		Nextmap key
 * @param nextmap_key_length	Nextmap key length
 * @param nextmap		String to store the nextmap.
 * @param nextmap_length	Maximum size of nextmap buffer.
 * @param map_end		If true, reset g_ForceNextMap if applicable and
 *				advance cvar "dmr_map_key" to the nextmap key.
 * 
 * @return	    True if a nextmap was found, false otherwise.
 */
stock bool:DetermineNextMap(String:start_key[], String:nextmap_key[], nextmap_key_length, String:nextmap[], nextmap_length, bool:map_end=false) {
    if (g_ForceNextMap) {
	strcopy(nextmap_key, nextmap_key_length, start_key);
	GetConVarString(g_cvars[CVAR_FORCE_NEXTMAP], nextmap, nextmap_length);
    	SetConVarString(g_cvars[CVAR_NEXTMAP], nextmap);
	return true;
    }

    if (DetermineNextMapKey(start_key, nextmap_key, nextmap_key_length)) {
	GetMapFromKey(nextmap_key, nextmap, nextmap_length);
    	SetConVarString(g_cvars[CVAR_NEXTMAP], nextmap);
	return true;
    }

    return false;
}
/* }}} DetermineNextMap */

/* DetermineNextMapKey {{{ */
/** Find the key of the nextmap based on current server conditions.
 *
 * @param start_key	Which key's conditions to evaluate.
 * @param nextmap	String to store the nextmap key.
 * @param length	Maximum size of nextmap buffer.
 *
 * @return		True if a nextmap was found, false otherwise.
 */
stock bool:DetermineNextMapKey(String:start_key[], String:nextmap[], length) {
    decl String:section[MAX_KEY_LENGTH];
    decl String:val[MAX_VAL_LENGTH];
    new bool:found_nextmap = false;
    new Handle:kv = g_rotation;

    if (kv == INVALID_HANDLE) {
	LoadRotation(true);
	LogError("In DetermineNextMapKey, g_rotation was invalid. THIS SHOULD NEVER HAPPEN!");
    }

    KvRewind(kv);

    if (!KvJumpToKey(kv, start_key)) {
	LogError("In DetermineNextMapKey, start_key \"%s\" could not be found. THIS SHOULD NEVER HAPPEN!", start_key);
	return false;
    }

    /* First look for the default map */
    KvGetString(kv, "default_nextmap", val, sizeof(val));
    KvRewind(kv);
    if (strlen(val) && KvJumpToKey(kv, val)) {
	strcopy(nextmap, length, val);
	found_nextmap = true;
    }
    KvRewind(kv);
    KvJumpToKey(kv, start_key);

    /* Any subkeys will be sections containing custom nextmap rules, with the
     * section name being the nextmap key and the key-value pairs defining the
     * custom rules */
    new Handle:keys_to_check = CreateArray(MAX_KEY_LENGTH);
    if (KvGotoFirstSubKey(kv)) {
	do {
	    KvGetSectionName(kv, section, sizeof(section));
	    if (CustomConditionsMet(kv)) {
		PushArrayString(keys_to_check, section);
	    }
	} while (KvGotoNextKey(kv));
    }

    /* Check the keys with valid conditions and accept the FIRST one that
     * points to a valid key at the root level */
    KvRewind(kv);
    for (new i = 0; i < GetArraySize(keys_to_check); i++) {
	GetArrayString(keys_to_check, i, section, sizeof(section));
	if (KvJumpToKey(kv, section)) {
	    strcopy(nextmap, length, section);
	    found_nextmap = true;
	    break;
	}
    }

    CloseHandle(keys_to_check);
    KvRewind(kv);
    return found_nextmap;
}
/* }}} DetermineNextMapKey */

/* GetMapFromKey {{{ */
stock GetMapFromKey(const String:key[], String:map[], length) {
    new Handle:kv = g_rotation;
    if (kv != INVALID_HANDLE) {
	KvRewind(kv); 
	if (KvJumpToKey(kv, key)) {
	    KvGetString(kv, "map", map, length);
	    if (!IsMapValid(map)) {
		LogError("FATAL: map \"%s\" in key \"%s\" is invalid.", map, key);
		SetFailState("Map \"%s\" in key \"%s\" is invalid.", map, key);
	    }
	    KvRewind(kv); 
	    return true;
	}
    }
    KvRewind(kv); 
    return false;
}
/* }}} GetMapFromKey */


/* CompareTimeRange {{{ */
stock bool:CompareTimeRange(const String:gte_time[], const String:lte_time[]) {
    new gte_hour, gte_min, lte_hour, lte_min;
    decl String:hm[2][9];

    if (ExplodeString(gte_time, ":", hm, 2, 8) == 2) {
	gte_hour = StringToInt(hm[0]);
	gte_min = StringToInt(hm[1]);
    }
    else {
	return false;
    }

    if (ExplodeString(lte_time, ":", hm, 2, 8) == 2) {
	lte_hour = StringToInt(hm[0]);
	lte_min = StringToInt(hm[1]);
    }
    else {
	return false;
    }

    new CompareTimeResult:gte_result = CompareTime(gte_hour, gte_min);
    new CompareTimeResult:lte_result = CompareTime(lte_hour, lte_min);

    /* 0 <----time_lte        time_gte -----> 23 */
    if (gte_hour > lte_hour ||
	(gte_hour == lte_hour && gte_min > lte_min)) {
	if (gte_result != NOW_LT_TIME || lte_result != NOW_GT_TIME) {
	    return true;
	}
    }

    /* 0   time_gte-----><----time_lte        23 */
    else if (gte_hour < lte_hour ||
	(gte_hour == lte_hour && gte_min < lte_min)) {
	if (gte_result != NOW_LT_TIME && lte_result != NOW_GT_TIME) {
	    return true;
	}
    }

    return false;
}
/* }}} CompareTimeRange */

/* CompareTimeFromString {{{ */
stock CompareTimeFromString(const String:time[], CompareTimeType:type) {
    decl String:hm[2][8];
    if (ExplodeString(time, ":", hm, 2, 8) == 2) {
	new hour = StringToInt(hm[0]);
	new min = StringToInt(hm[1]);
	new CompareTimeResult:result = CompareTime(hour, min);

	if (type == NOW_LTE_TIME && (result == NOW_LT_TIME || result == NOW_EQ_TIME)) {
	    return true;
	}
	else if (type == NOW_GTE_TIME && (result == NOW_GT_TIME || result == NOW_EQ_TIME)) {
	    return true;
	}
    }
    return false;
}
/* }}} CompareTimeFromString */

/* CompareTime {{{ */
/**
 * Compare the specified hour:min with the current server time.
 *
 * @return	-1 if the current time is before the specified time
 *		0 if the current time is the same as the specified time
 *		1 if the current time is after the specified time
 */
stock CompareTimeResult:CompareTime(hour, min) {
    decl String:time[16];
    FormatTime(time, sizeof(time), "%H");
    new hour_now = StringToInt(time);
    FormatTime(time, sizeof(time), "%M");
    new min_now = StringToInt(time);

    if (hour_now < hour) {
	return NOW_LT_TIME;
    }
    else if (hour_now > hour) {
	return NOW_GT_TIME;
    }
    else {
	if (min_now < min) {
	    return NOW_LT_TIME;
	}
	else if (min_now > min) {
	    return NOW_GT_TIME;
	}
    }
    return NOW_EQ_TIME;
}
/* }}} CompareTime */

/* UserMsg_VGUIMenu {{{ */
/**
 * Intercept the "scores" event sent to clients indicating the map is over and
 * schedule a map change if we can successfuly determine a nextmap.
 *
 * Mostly copied from nextmap.sp
 */
public Action:UserMsg_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {
    if (g_IntermissionCalled) {
        return Plugin_Handled;
    }

    decl String:type[15];

    if (BfReadString(bf, type, sizeof(type)) < 0) {
	return Plugin_Handled;
    }

    if (BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && 
	((strcmp(type, "scores", false) == 0) ||(strcmp(type, "scoreboard", false) == 0))
    ) {
	g_IntermissionCalled = true;

	decl String:nextmap[MAX_VAL_LENGTH];
	decl String:start_key[MAX_KEY_LENGTH];
	decl String:nextmap_key[MAX_KEY_LENGTH];
	GetConVarString(g_cvars[CVAR_MAP_KEY], start_key, sizeof(start_key));
	if (DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap), true)) {

	    new Float:fChatTime = GetConVarFloat(g_cvars[CVAR_CHAT_TIME]);

	    if (fChatTime < 3.0) {
	    	SetConVarFloat(g_cvars[CVAR_CHAT_TIME], 3.0);
	    }

	    new Handle:dp;
	    CreateDataTimer(fChatTime - 2.0, Timer_ChangeMap, dp);
	    WritePackString(dp, nextmap);
	    WritePackString(dp, nextmap_key);
	}
	else {
	    LogError("An error occurred while trying to determine the next map.");
	}
    }

    return Plugin_Handled;
}
/* }}} UserMSG_VGUIMenu */

/* Timer_ChangeMap {{{ */
public Action:Timer_ChangeMap(Handle:timer, Handle:dp) {
    new String:nextmap[MAX_VAL_LENGTH];
    new String:nextmap_key[MAX_KEY_LENGTH];

    ResetPack(dp);
    ReadPackString(dp, nextmap, sizeof(nextmap));
    ReadPackString(dp, nextmap_key, sizeof(nextmap_key));

    g_ForceNextMap = false;

    SetConVarString(g_cvars[CVAR_MAP_KEY], nextmap_key);

    InsertServerCommand("changelevel \"%s\"", nextmap);
    ServerExecute();

    LogMessage("Dynamic Map Rotations changed map to \"%s\"", nextmap);
    
    return Plugin_Stop;
}
/* }}} Timer_ChangeMap */

/* Command_Say {{{ */
public Action:Command_Say(client, args) {
    decl String:text[192];
    if (GetCmdArgString(text, sizeof(text)) < 1) {
	return Plugin_Continue;
    }

    new startidx = 0;
    if (text[strlen(text) - 1] == '"') {
	text[strlen(text) - 1] = '\0';
	startidx = 1;
    }

    decl String:message[9];
    BreakString(text[startidx], message, sizeof(message));

    if (strcmp(message, "nextmaps", false) == 0) {
	CreateTimer(0.0, Timer_SayNextMaps, client);
    }
    else if (strcmp(message, "nextmap", false) == 0) {
	/* Seeing the next map before the command invoking it bugs me */
	CreateTimer(0.0, Timer_SayNextMap);
    }
    return Plugin_Continue;
}
/* }}} Command_Say */

public Action:Timer_SayNextMaps(Handle:timer, any:client) {
    decl String:nextmaps[256];
    decl String:map[MAX_KEY_LENGTH];

    new Handle:dp = GetNextMaps(5);
    Format(nextmaps, sizeof(nextmaps), "Next Maps:");
    ResetPack(dp);
    new count = ReadPackCell(dp);
    for (new i = 0; i < count; i++) {
	ReadPackString(dp, map, sizeof(map));
	if (i > 0) {
	    Format(nextmaps, sizeof(nextmaps), "%s, %s", nextmaps, map);
	}
	else {
	    Format(nextmaps, sizeof(nextmaps), "%s %s", nextmaps, map);
	}
    }
    CloseHandle(dp);

    if (client) {
	PrintToChatAll(nextmaps);
    }
    else {
	PrintToServer(nextmaps);
    }
}

public Action:Timer_SayNextMap(Handle:timer) {
    decl String:nextmap[MAX_KEY_LENGTH];
    decl String:start_key[MAX_KEY_LENGTH];
    decl String:nextmap_key[MAX_KEY_LENGTH];

    GetConVarString(g_cvars[CVAR_MAP_KEY], start_key, sizeof(start_key));
    if (DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap))) {
	PrintToChatAll("Next Map: %s", nextmap);
    }
}

public Action:Timer_UpdateNextMap(Handle:timer) {
    decl String:nextmap[MAX_KEY_LENGTH];
    decl String:start_key[MAX_KEY_LENGTH];
    decl String:nextmap_key[MAX_KEY_LENGTH];

    GetConVarString(g_cvars[CVAR_MAP_KEY], start_key, sizeof(start_key));
    DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap));
    return Plugin_Continue;
}

public OnMapEnd() {
    g_IntermissionCalled = false;
}

public OnPluginEnd() {
    CloseHandle(g_updateNextMapTimer);
    PrintToServer("Dynamic Map Rotations Unloaded");
}

