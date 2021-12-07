/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Dynamic Map Rotations
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * 
 * Modifications made by [SpA]VictorOfSweden
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

#define DMR_VERSION        "0.8.1-SpA"

#define TIMER_UPDATE_INTERVAL 60.0

#define MAX_CONDITIONS        8
#define MAX_KEY_LENGTH        32
#define MAX_VAL_LENGTH        32

#define LOG_FILE_DEBUG "addons/sourcemod/logs/spadmr_debug.log"

//CVARs
new Handle:g_cvar_source_file = INVALID_HANDLE;
new Handle:g_cvar_map_key = INVALID_HANDLE;
new Handle:g_cvar_lock = INVALID_HANDLE;
new Handle:g_cvar_debug = INVALID_HANDLE;

//Others
new Handle:g_rotation = INVALID_HANDLE;
new UserMsg:g_VGUIMenu;
new bool:g_IntermissionCalled = false;
new day_array[] = {'\0', 'm', 't', 'w', 'r', 'f', 's', 'u'};
new Handle:g_timer_updateNextMap = INVALID_HANDLE;
new bool:g_nextmap_forced = false;

enum CompareTimeType
{
	NOW_LTE_TIME = 0,
	NOW_GTE_TIME
};

enum CompareTimeResult
{
	NOW_LT_TIME = 0,
	NOW_EQ_TIME,
	NOW_GT_TIME
};

public Plugin:myinfo = {
	name = "Dynamic Map Rotations",
	author = "Ryan \"FLOOR_MASTER\" Mannion and SpecialAttack",
	description = "Dynamically alters the map rotation based on server conditions.",
	version = DMR_VERSION,
	url = "http://www.2fort2furious.com"
};

//public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
//{
//    CreateNative("GetNextMaps", Native_GetNextMaps);
//    return true;
//}

public OnPluginStart()
{
	//TODO Translations
	LoadTranslations("common.phrases");
	
	//Prevent plugin collition
	if ( FindPluginByFile("nextmap.smx") != INVALID_HANDLE )
	{
	    LogError("FATAL: This plugin replaces nextmap. You must remove nextmap.smx to load this plugin.");
	    SetFailState("This plugin replaces nextmap. You must remove nextmap.smx to load this plugin.");
	}
	
	//Hook VGUI menu
	g_VGUIMenu = GetUserMessageId("VGUIMenu");
	if ( g_VGUIMenu == INVALID_MESSAGE_ID )
	{
	    LogError("FATAL: Cannot find VGUIMenu user message id. Dynamic Map Rotations not loaded.");
	    SetFailState("VGUIMenu Not Found.");
	}
	HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);
	
	//User commands
	//RegConsoleCmd("nextmap", Command_Nextmap, "Nextmap");
	RegConsoleCmd("nextmaps", Command_Nextmaps, "Nextmaps");
	
	//Admin command
	RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "Forces a map to be next");
	RegAdminCmd("sm_unsetnextmap", Command_UnSetNextmap, ADMFLAG_CHANGEMAP, "Unsets a forced next map");
	RegAdminCmd("sm_dmr_reload", Command_Reload, ADMFLAG_CHANGEMAP, "Reloads the DMR plugin");
	
	//CVARs
	CreateConVar(
		"sm_dmr_version",
		DMR_VERSION,
		"Dynamic map rotations version.",
		FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_source_file = CreateConVar(
		"sm_dmr_file",
		"dmr.txt",
		"Location of the rotation keyvalues file.",
		FCVAR_PLUGIN);
	g_cvar_map_key = CreateConVar(
		"sm_dmr_map_key",
		"",
		"The key used to base nextmap decisions on.",
		FCVAR_PLUGIN);
	g_cvar_lock = CreateConVar(
		"sm_dmr_lock",
		"0",
		"Locks the plugin down, ignoring all commands.",
		FCVAR_PLUGIN);
	g_cvar_debug = CreateConVar(
		"sm_dmr_debug",
		"0",
		"Enable/disable debugging of SpA-dmr.",
		0,
		true,
		0.0,
		true,
		1.0);
	
	//Load the rotation!
	LoadRotation(true);
	
	//Start updater timer
	g_timer_updateNextMap = CreateTimer(TIMER_UPDATE_INTERVAL, Timer_UpdateNextMap, _, TIMER_REPEAT);
}

public OnMapEnd()
{
	g_IntermissionCalled = false;
}

public OnPluginEnd()
{
	KillTimer(g_timer_updateNextMap);
}

/*
public Action:Command_Nextmap(client, args)
{
	decl String:nextmap[MAX_KEY_LENGTH];
	decl String:start_key[MAX_KEY_LENGTH];
	decl String:nextmap_key[MAX_KEY_LENGTH];

	GetConVarString(g_cvar_map_key, start_key, sizeof(start_key));

	if ( DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap)) )
	{
	    PrintToChatAll("Next map: %s", nextmap);
	}

	return Plugin_Handled;
}
*/

public Action:Command_Nextmaps(client, args)
{
	decl String:nextmaps[256];
	decl String:map[MAX_KEY_LENGTH];
	new Handle:dp = GetNextMaps(5);
	
	Format(nextmaps, sizeof(nextmaps), "Next Maps:");
	
	ResetPack(dp);
	new count = ReadPackCell(dp);
	for ( new i = 0; i < count; i++ )
	{
	    ReadPackString(dp, map, sizeof(map));
		
	    if ( i > 0 )
		{
	        Format(nextmaps, sizeof(nextmaps), "%s, %s", nextmaps, map);
	    }
	    else
		{
	        Format(nextmaps, sizeof(nextmaps), "%s %s", nextmaps, map);
	    }
	}
	CloseHandle(dp);

	if (client)
	{
	    PrintToChatAll(nextmaps);
	}
	else
	{
	    PrintToServer(nextmaps);
	}
}

//Lifted from nextmap.sp
public Action:Command_SetNextmap(client, args)
{
	if (args < 1)
	{
	    ReplyToCommand(client, "Usage: sm_setnextmap <map>");
	    return Plugin_Handled;
	}
	else if ( g_cvar_lock != INVALID_HANDLE && GetConVarBool(g_cvar_lock) )
	{
		ReplyToCommand(client, "Command locked.");
		return Plugin_Handled;
	}

	decl String:map[64];
	GetCmdArg(1, map, sizeof(map));

	if ( SetNextMap(map) )
	{
		g_nextmap_forced = true;
		ReplyToCommand(client, "Set forced nextmap to \"%s\".", map);
		LogMessage("\"%L\" set the forced nextmap to \"%s\".", client, map);
	}
	else
	{
		ReplyToCommand(client, "%t", "Map was not found", map);
	}
	
	return Plugin_Handled;
}

public Action:Command_UnSetNextmap(client, args)
{
	if ( g_cvar_lock != INVALID_HANDLE && GetConVarBool(g_cvar_lock) )
	{
		ReplyToCommand(client, "Command locked.");
		return Plugin_Handled;
	}
	
	if ( g_nextmap_forced )
	{
		g_nextmap_forced = false;
		ReplyToCommand(client, "Unset forced nextmap.");
		LogMessage("\"%L\" unset the forced nextmap.", client);
	}
	else
	{
	    ReplyToCommand(client, "No forced nextmap to unset!");
	}
	
	return Plugin_Handled;
}

public Action:Command_Reload(client, args)
{
	LogDebugMessage("Reloading dmr.");
	
	decl String:config[64];
	decl String:nextmap[MAX_VAL_LENGTH];
	decl String:nextmap_key[MAX_VAL_LENGTH];
	decl String:dmr_map_key[MAX_VAL_LENGTH];
	
	//Unset forced nextmap
	g_nextmap_forced = false;

	GetConVarString(g_cvar_source_file, config, sizeof(config));
	GetConVarString(g_cvar_map_key, dmr_map_key, sizeof(dmr_map_key));

	//Reload the rotation
	LoadRotation();

	if ( DetermineNextMap(dmr_map_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap)) )
	{
	    ReplyToCommand(client, "Reloaded DMR from \"%s\". Map key is \"%s\", next map key is \"%s\" and nextmap is \"%s\".", config, dmr_map_key, nextmap_key, nextmap);
	}
	else
	{
	    ReplyToCommand(client, "Reloaded DMR from \"%s\".", config);
	}

	return Plugin_Continue;
}

public Action:Timer_UpdateNextMap(Handle:timer)
{
	decl String:start_key[MAX_KEY_LENGTH];
	decl String:nextmap_key[MAX_KEY_LENGTH];
	decl String:nextmap[MAX_KEY_LENGTH];
	
	if( g_nextmap_forced )
	{
		GetNextMap(nextmap, sizeof(nextmap));
		LogDebugMessage("Nextmap is forced (%s).", nextmap);
	}

	GetConVarString(g_cvar_map_key, start_key, sizeof(start_key));
	DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap));
	
	return Plugin_Continue;
}

stock PrintIndent(const String:text[], indent_spaces)
{
	decl String:text2[256];
	
	for (new i = 0; i < indent_spaces; i++)
	{
	    text2[i] = ' ';
	}
	
	strcopy(text2[indent_spaces], sizeof(text2) - indent_spaces, text);
	
	PrintToServer(text2);
}

stock LoadRotation(bool:reset_map_key = false)
{
	LogDebugMessage("Loading map rotation.");
	
	//The config file
	decl String:config[64];
	GetConVarString(g_cvar_source_file, config, sizeof(config));
	
	//Reset the kv handle
	if (g_rotation != INVALID_HANDLE)
	{
	    CloseHandle(g_rotation);
	}
	g_rotation = CreateKeyValues("rotation");
	
	//Load key values
	if ( !FileToKeyValues(g_rotation, config) )
	{
	    LogError("FATAL: Could not read rotation file \"%s\"", config);
	    SetFailState("Could not read rotation file \"%s\"", config);
	}
	
	decl String:key[MAX_KEY_LENGTH];
	decl String:val[MAX_VAL_LENGTH];
	
	//reset_map_key should only be true if the plugin was just loaded. Set the dmr_map_key cvar properly if it's not already set to a valid section key.
	if ( reset_map_key )
	{
	    GetConVarString(g_cvar_map_key, key, sizeof(key));
		
	    if ( !strlen(key) || !KvJumpToKey(g_rotation, key) )
		{
	        KvGetString(g_rotation, "start", val, sizeof(val));
			
	        if ( strlen(val) && KvJumpToKey(g_rotation, val) )
			{
	            LogDebugMessage("Reset dmr_map_key to \"%s\".", val);
	            SetConVarString(g_cvar_map_key, val);
	        }
			else
			{
	            LogError("FATAL: A valid \"start\" key was not defined in \"%s\"", config);
	            SetFailState("A valid \"start\" key was not defined in \"%s\"", config);
	        }
	    }
	}
	
	KvRewind(g_rotation);
}

stock GetAdminsCount()
{
	new count = 0;
	
	for ( new i = 1; i <= GetMaxClients(); i++ )
	{
	    if ( IsClientInGame(i) && !IsFakeClient(i) && GetUserAdmin(i) != INVALID_ADMIN_ID )
		{
	        count++;
	    }
	}
	
	return count;
}

stock GetPlayersCount()
{
	new count = 0;
	
	for ( new i = 1; i <= GetMaxClients(); i++ )
	{
	    if ( IsClientInGame(i) && !IsFakeClient(i) )
		{
	        count++;
	    }
	}
	
	return count;
}

stock bool:CustomConditionsMet(Handle:kv)
{
	decl String:val[MAX_VAL_LENGTH];
	
	if (KvGetDataType(kv, "players_lte") != KvData_None)
	{
	    new count = KvGetNum(kv, "players_lte");
	    if ( !(GetPlayersCount() <= count) )
		{
	        return false;
	    }
	}
	
	if (KvGetDataType(kv, "players_gte") != KvData_None)
	{
	    new count = KvGetNum(kv, "players_gte");
	    if ( !(GetPlayersCount() >= count) )
		{
	        return false;
	    }
	}
	
	if (KvGetDataType(kv, "admins_lte") != KvData_None)
	{
	    new count = KvGetNum(kv, "admins_lte");
	    if ( !(GetAdminsCount() <= count) )
		{
	        return false;
	    }
	}
	
	if (KvGetDataType(kv, "admins_gte") != KvData_None)
	{
	    new count = KvGetNum(kv, "admins_gte");
	    if ( !(GetAdminsCount() >= count) )
		{
	        return false;
	    }
	}
	
	if ( KvGetDataType(kv, "time_gte") != KvData_None && KvGetDataType(kv, "time_lte") != KvData_None )
	{
	    decl String:val2[MAX_VAL_LENGTH];
	    KvGetString(kv, "time_gte", val, sizeof(val));
	    KvGetString(kv, "time_lte", val2, sizeof(val2));

	    if ( !CompareTimeRange(val, val2) )
		{
	        return false;
	    }
	}
	else if ( KvGetDataType(kv, "time_gte") != KvData_None )
	{
	    KvGetString(kv, "time_gte", val, sizeof(val));
	    if ( !CompareTimeFromString(val, NOW_GTE_TIME) )
		{
	        return false;
	    }
	}
	else if ( KvGetDataType(kv, "time_lte") != KvData_None )
	{
	    KvGetString(kv, "time_lte", val, sizeof(val));
	    if ( !CompareTimeFromString(val, NOW_LTE_TIME) )
		{
	        return false;
	    }
	}
	
	if (KvGetDataType(kv, "day_eq") != KvData_None )
	{
	    KvGetString(kv, "day_eq", val, sizeof(val));
	    if ( !CompareDayOfWeek(val) )
		{
	        return false;
	    }
	}
	
	if ( KvGetDataType(kv, "day_neq") != KvData_None )
	{
	    KvGetString(kv, "day_neq", val, sizeof(val));
	    if ( CompareDayOfWeek(val) )
		{
	        return false;
	    }
	}
	
	return true;
}

stock bool:CompareDayOfWeek(const String:days[])
{
	decl String:day_str[3];
	FormatTime(day_str, sizeof(day_str), "%u");
	new day = StringToInt(day_str);

	Format(day_str, sizeof(day_str), "%s", day_array[day]);

	if ( day > 0 && day < sizeof(day_array) && StrContains(days, day_str) >= 0 )
	{
	    return true;
	}

	return false;
}

//public Native_GetNextMaps(Handle:plugin, numParams)
//{
//    new Handle:dp = GetNextMaps(GetNativeCell(2));
//    new Handle:dpCloned = CloneHandle(dp, plugin);
//    CloseHandle(dp);
//    SetNativeCellRef(1, dpCloned);
//    return;
//}

stock Handle:GetNextMaps(count = 0)
{
	decl String:start_key[MAX_KEY_LENGTH];
	decl String:current_key[MAX_KEY_LENGTH];
	decl String:nextmap_key[MAX_KEY_LENGTH];
	decl String:nextmap[MAX_VAL_LENGTH];

	GetConVarString(g_cvar_map_key, start_key, sizeof(start_key));
	strcopy(current_key, sizeof(current_key), start_key);

	new Handle:dp = CreateDataPack();
	new i = 0;
	new Handle:nextmaps = CreateArray(MAX_VAL_LENGTH);

	//This is an ugly two-step process since we store the number of maps first
	// in the datapack, and the number of maps returned isn't necessarily the
	// same as the count parameter due to cycles in the rotation
	while (i < count)
	{
	    // while (i < count || count == 0) {
	    if ( DetermineNextMapKey(current_key, nextmap_key, sizeof(nextmap_key)) )
		{
	        GetMapFromKey(nextmap_key, nextmap, sizeof(nextmap));
	        PushArrayString(nextmaps, nextmap);
	        strcopy(current_key, sizeof(current_key), nextmap_key);

	        /* Stop if we cycle back to the key we started from */
	        if ( !strcmp(start_key, nextmap_key) )
			{
	            break;
	        }
	    }
	    else
		{
	        return INVALID_HANDLE;
	    }
		
	    i++;
	}

	//Fill in the datapack
	new nextmaps_size = GetArraySize(nextmaps);
	WritePackCell(dp, nextmaps_size);

	//Special exception for the first map, which might be overriden
	if ( g_nextmap_forced && nextmaps_size )
	{
	    DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap));
	    WritePackString(dp, nextmap);
	    nextmaps_size--;
	}

	for ( i = 0; i < nextmaps_size; i++ )
	{
	    GetArrayString(nextmaps, i, nextmap, sizeof(nextmap));
	    WritePackString(dp, nextmap);
	}

	CloseHandle(nextmaps);
	ResetPack(dp);
	return dp;
}

/** Find the name of the nextmap based on the current server conditions. Also
 * take into consideration if a forced nextmap has been requested.
 *
 * @param start_key        Which key's conditions to evaluate.
 * @param nextmap_key        Nextmap key
 * @param nextmap_key_length    Nextmap key length
 * @param nextmap        String to store the nextmap.
 * @param nextmap_length    Maximum size of nextmap buffer.
 * @param map_end        If true, reset g_ForceNextMap if applicable and
 *                advance cvar "dmr_map_key" to the nextmap key.
 * 
 * @return        True if a nextmap was found, false otherwise.
 */
stock bool:DetermineNextMap(String:start_key[], String:nextmap_key[], nextmap_key_length, String:nextmap[], nextmap_length, bool:map_end = false)
{
	if ( g_nextmap_forced )
	{
		decl String:set_nextmap[64];
		GetNextMap(set_nextmap, sizeof(set_nextmap));
		
		//Copy the set nextmap (from sm_nextmap) to function variable nextmap
		strcopy(nextmap, nextmap_length, set_nextmap);
		
		//Set nextmap key to start key
		// TODO: Change this
		strcopy(nextmap_key, nextmap_key_length, start_key);
		
		LogDebugMessage("Map key is \"%s\", next map key is \"%s\" and nextmap is \"%s\".", start_key, nextmap_key, nextmap);
		
		if ( map_end )
		{
			//Unset forced
			g_nextmap_forced = false;
		}
		
		return true;
	}

	else if ( DetermineNextMapKey(start_key, nextmap_key, nextmap_key_length) )
	{
		//Set nextmap from nextmap key
		GetMapFromKey(nextmap_key, nextmap, nextmap_length);
		SetNextMap(nextmap);
		
		LogDebugMessage("Map key is \"%s\", next map key is \"%s\" and nextmap is \"%s\".", start_key, nextmap_key, nextmap);
		
		if ( map_end )
		{
			//Move map key forward
			SetConVarString(g_cvar_map_key, nextmap_key);
			
			//Unset forced
			g_nextmap_forced = false;
		}
		
		return true;
	}
	
	else
	{
		return false;
	}
}

/** Find the key of the nextmap based on current server conditions.
 *
 * @param start_key    Which key's conditions to evaluate.
 * @param nextmap    String to store the nextmap key.
 * @param length    Maximum size of nextmap buffer.
 *
 * @return        True if a nextmap was found, false otherwise.
 */
stock bool:DetermineNextMapKey(String:start_key[], String:nextmap[], length)
{
	decl String:section[MAX_KEY_LENGTH];
	decl String:val[MAX_VAL_LENGTH];
	new bool:found_nextmap = false;
	new Handle:kv = g_rotation; //Alias the global

	if ( kv == INVALID_HANDLE )
	{
	    LoadRotation(true);
	    LogError("In DetermineNextMapKey, g_rotation was invalid. THIS SHOULD NEVER HAPPEN!");
	}

	KvRewind(kv);

	if ( !KvJumpToKey(kv, start_key) )
	{
	    LogError("In DetermineNextMapKey, start_key \"%s\" could not be found. THIS SHOULD NEVER HAPPEN!", start_key);
	    return false;
	}

	//First look for the default map
	KvGetString(kv, "default_nextmap", val, sizeof(val));
	KvRewind(kv);
	
	if ( strlen(val) && KvJumpToKey(kv, val) )
	{
	    strcopy(nextmap, length, val);
	    found_nextmap = true;
	}
	
	KvRewind(kv);
	KvJumpToKey(kv, start_key);

	//Any subkeys will be sections containing custom nextmap rules, with the section name being the nextmap key and the key-value pairs defining the custom rules
	new Handle:keys_to_check = CreateArray(MAX_KEY_LENGTH);
	if ( KvGotoFirstSubKey(kv) )
	{
	    do {
	        KvGetSectionName(kv, section, sizeof(section));
			
	        if ( CustomConditionsMet(kv) )
			{
	            PushArrayString(keys_to_check, section);
	        }
	    }
		while( KvGotoNextKey(kv) );
	}
	
	KvRewind(kv);

	//Check the keys with valid conditions and accept the FIRST one that points to a valid key at the root level
	for ( new i = 0; i < GetArraySize(keys_to_check); i++ )
	{
	    GetArrayString(keys_to_check, i, section, sizeof(section));
		
	    if ( KvJumpToKey(kv, section) )
		{
	        strcopy(nextmap, length, section);
	        found_nextmap = true;
			
	        break;
	    }
	}

	CloseHandle(keys_to_check);
	KvRewind(kv);
	
	return found_nextmap;
}

stock GetMapFromKey(const String:key[], String:map[], length)
{
	new Handle:kv = g_rotation; //Alias the global
	
	if ( kv != INVALID_HANDLE )
	{
	    KvRewind(kv);
		
	    if ( KvJumpToKey(kv, key) )
		{
	        KvGetString(kv, "map", map, length);
			
	        if ( !IsMapValid(map) )
			{
	            LogError("FATAL: Map \"%s\" in key \"%s\" is invalid!", map, key);
	            SetFailState("Map \"%s\" in key \"%s\" is invalid!", map, key);
	        }
			
	        KvRewind(kv);
			
	        return true;
	    }
	}
	
	KvRewind(kv); 
	
	return false;
}

stock bool:CompareTimeRange(const String:gte_time[], const String:lte_time[])
{
	new gte_hour, gte_min, lte_hour, lte_min;
	decl String:hm[2][9];

	if ( ExplodeString(gte_time, ":", hm, 2, 8) == 2 )
	{
	    gte_hour = StringToInt(hm[0]);
	    gte_min = StringToInt(hm[1]);
	}
	else
	{
	    return false;
	}

	if ( ExplodeString(lte_time, ":", hm, 2, 8) == 2 )
	{
	    lte_hour = StringToInt(hm[0]);
	    lte_min = StringToInt(hm[1]);
	}
	else
	{
	    return false;
	}

	new CompareTimeResult:gte_result = CompareTime(gte_hour, gte_min);
	new CompareTimeResult:lte_result = CompareTime(lte_hour, lte_min);

	/* 0 <----time_lte        time_gte -----> 23 */
	if ( gte_hour > lte_hour || (gte_hour == lte_hour && gte_min > lte_min) )
	{
	    if ( gte_result != NOW_LT_TIME || lte_result != NOW_GT_TIME )
		{
	        return true;
	    }
	}

	/* 0   time_gte-----><----time_lte        23 */
	else if ( gte_hour < lte_hour || (gte_hour == lte_hour && gte_min < lte_min) )
	{
	    if ( gte_result != NOW_LT_TIME && lte_result != NOW_GT_TIME )
		{
	        return true;
	    }
	}

	return false;
}

stock CompareTimeFromString(const String:time[], CompareTimeType:type)
{
	decl String:hm[2][8];
	
	if (ExplodeString(time, ":", hm, 2, 8) == 2)
	{
	    new hour = StringToInt(hm[0]);
	    new min = StringToInt(hm[1]);
	    new CompareTimeResult:result = CompareTime(hour, min);

	    if ( type == NOW_LTE_TIME && (result == NOW_LT_TIME || result == NOW_EQ_TIME) )
		{
	        return true;
	    }
	    else if ( type == NOW_GTE_TIME && (result == NOW_GT_TIME || result == NOW_EQ_TIME) )
		{
	        return true;
	    }
	}
	
	return false;
}

/**
 * Compare the specified hour:min with the current server time.
 *
 * @return    -1 if the current time is before the specified time
 *        0 if the current time is the same as the specified time
 *        1 if the current time is after the specified time
 */
stock CompareTimeResult:CompareTime(hour, min)
{
	decl String:time[16];
	
	FormatTime(time, sizeof(time), "%H");
	new hour_now = StringToInt(time);
	
	FormatTime(time, sizeof(time), "%M");
	new min_now = StringToInt(time);

	if (hour_now < hour)
	{
	    return NOW_LT_TIME;
	}
	else if ( hour_now > hour )
	{
	    return NOW_GT_TIME;
	}
	else
	{
	    if ( min_now < min )
		{
	        return NOW_LT_TIME;
	    }
	    else if ( min_now > min )
		{
	        return NOW_GT_TIME;
	    }
	}
	
	return NOW_EQ_TIME;
}

/**
 * Intercept the "scores" event sent to clients indicating the map is over and
 * schedule a map change if we can successfuly determine a nextmap.
 *
 * Mostly copied from nextmap.sp
 */
public Action:UserMsg_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {
	if ( g_IntermissionCalled )
	{
	    return Plugin_Handled;
	}

	decl String:type[15];
	if ( BfReadString(bf, type, sizeof(type)) < 0 )
	{
	    return Plugin_Handled;
	}

	if ( BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && ( strcmp(type, "scores", false) == 0 || strcmp(type, "scoreboard", false) == 0 ) )
	{
	    g_IntermissionCalled = true;

	    decl String:nextmap[MAX_VAL_LENGTH];
	    decl String:start_key[MAX_KEY_LENGTH];
	    decl String:nextmap_key[MAX_KEY_LENGTH];
	    GetConVarString(g_cvar_map_key, start_key, sizeof(start_key));
		
	    if ( DetermineNextMap(start_key, nextmap_key, sizeof(nextmap_key), nextmap, sizeof(nextmap), true) )
		{
			new Float:fChatTime = 3.0;
			
			new Handle:mp_chattime = FindConVar("mp_chattime");
			if(mp_chattime != INVALID_HANDLE )
			{
				fChatTime = GetConVarFloat(mp_chattime);
			}
			CloseHandle(mp_chattime);

			if (fChatTime < 3.0) {
				fChatTime = 3.0;
				SetConVarFloat(mp_chattime, fChatTime);
			}

			new Handle:dp = INVALID_HANDLE;
			CreateDataTimer(fChatTime - 2.0, Timer_ChangeMap, dp);
			WritePackString(dp, nextmap);
			WritePackString(dp, nextmap_key);
		}
		else
		{
			LogError("An error occurred while trying to determine the next map.");
		}
	}

	return Plugin_Handled;
}

public Action:Timer_ChangeMap(Handle:timer, Handle:dp) {
	new String:nextmap[MAX_VAL_LENGTH];
	new String:nextmap_key[MAX_KEY_LENGTH];

	ResetPack(dp);
	ReadPackString(dp, nextmap, sizeof(nextmap));
	ReadPackString(dp, nextmap_key, sizeof(nextmap_key));
	
	SetConVarString(g_cvar_map_key, nextmap_key);

	InsertServerCommand("changelevel \"%s\"", nextmap);
	ServerExecute();

	LogDebugMessage("Dynamic Map Rotations changed map to \"%s\".", nextmap);
	
	return Plugin_Stop;
}

//Function to log debug messages
LogDebugMessage(const String:message[], any:...)
{
	if( g_cvar_debug != INVALID_HANDLE && GetConVarBool(g_cvar_debug) )
	{
		decl String:buffer[256];
		VFormat(buffer, sizeof(buffer), message, 2);
		LogToFile(LOG_FILE_DEBUG, buffer);
	}
}
