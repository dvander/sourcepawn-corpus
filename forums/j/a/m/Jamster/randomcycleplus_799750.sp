/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Random Map Cycle Plugin
 * Randomly picks a map from the mapcycle.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 * RandomCycle+
 * Randomly picks a map from tiered maplists based on player counts.
 *
 * Special thanks to Sven Stryker for grammar correction in this plugin!
 *
 * Base code from SourceMod Random Map Cycle Plugin, additional code by Jamster.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 *
 * =============================================================================
 *
 * Changelog:
 *
 * 1.0
 * - Initial release
 *
 * 1.0.1
 * - Added code to detect duplicate maps
 *
 * 1.0.2
 * - Fixed parsing errors on reading the config file with comments in
 *
 * 1.0.3
 * - Spelling fixes
 * - Slightly more optimised when checking player counts
 *
 * 1.0.4
 * - Added cvar to instantly change the nextmap on mapstart
 *
 * 1.0.5
 * - Added cvar to enable/disable checking for duplicate maps for the whole 
 *   cycle
 * - Added a further check to check for duplicates in the tier itself (this is
 *   always enabled due to the nature of the plugin)
 *
 * 1.0.6
 * - Added rtv code to plugin to simply skip to nextmap, other commands added
 * - Increased string sizes for map names for safety
 * - Other very small fixes, code optimisation/organisation
 *
 * 1.0.7
 * - Fixed disconnect player bug for rtv
 * - Fixed some handles
 * =============================================================================
 */
 
#define RTV 1
#define LOWLOAD 1
#define GLOBALS 1

#if GLOBALS

/////////////
// Globals //
///////////// 

#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0.7a"

public Plugin:myinfo =
{
	name = "RandomCycle+",
	author = "Jamster",
	description = "Randomly chooses the nextmap based on current player counts from tiered maplists",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

// cvars
new Handle:cvar_ExMapsLow = INVALID_HANDLE;
new Handle:cvar_ExMapsMed = INVALID_HANDLE;
new Handle:cvar_ExMapsHigh = INVALID_HANDLE;
new Handle:cvar_LowPlayerCount = INVALID_HANDLE;
new Handle:cvar_HighPlayerCount = INVALID_HANDLE;
new Handle:cvar_PlayerCheckTime = INVALID_HANDLE;
new Handle:cvar_Announce = INVALID_HANDLE;
new Handle:cvar_LogMSG = INVALID_HANDLE;
new Handle:cvar_NextMapHide = INVALID_HANDLE;
new Handle:cvar_MapStartCheck = INVALID_HANDLE;
new Handle:cvar_MapDupeCheck = INVALID_HANDLE;

// handles
new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_OldMapList = INVALID_HANDLE;
new Handle:g_MapListHigh = INVALID_HANDLE;
new Handle:g_MapListMed = INVALID_HANDLE;
new Handle:g_MapListLow = INVALID_HANDLE;
new Handle:g_NextMap = INVALID_HANDLE;
new flags_g_NextMap;
new oldflags_g_NextMap;
new Handle:h_RandomCycleCheck = INVALID_HANDLE;

// bools
new bool:b_NextMapChanged = false;
new bool:b_PickMapHigh = true;
new bool:b_PickMapMed = true;
new bool:b_PickMapLow = true;
new bool:b_MapHistoryLow = false;
new bool:b_BaseTriggersLoaded = false;

// ints/floats
new g_Players = 0;
new g_CycleRun = 0;
new g_ExcludeMaps = 1;

// strings
new String:map[65];
new String:setmap[65];
new String:maplow[65];
new String:mapmed[65];
new String:maphigh[65];
new String:oldnextmap[65];

#if RTV
// rtv globals
new bool:b_RTVLoaded = false;
new bool:b_rtv_ChangingMap = false;
new bool:b_rtv_Enable = false;
new bool:rtv_Counted[MAXPLAYERS+1] = {false, ...};
new rtv_Needed = 0;
new rtv_Count = 0;
new Handle:cvar_RTV = INVALID_HANDLE;
new Handle:cvar_RTVplayers = INVALID_HANDLE;
new Handle:cvar_RTVdelay = INVALID_HANDLE;
#endif

#if LOWLOAD
new HighCount = 0;
new Handle:cvar_DisableHighTier = INVALID_HANDLE;
#endif
#endif

//////////////////////
// Initial Load/End //
//////////////////////

public OnPluginStart()
{
	new arraySize = ByteCountToCells(33);	
	g_MapListHigh = CreateArray(arraySize);
	g_MapListLow = CreateArray(arraySize);
	g_MapListMed = CreateArray(arraySize);
	g_OldMapList = CreateArray(arraySize);
	
	decl String:TransPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TransPath, sizeof(TransPath), "translations/randomcycleplus.phrases.txt");
	if (FileExists(TransPath))
	{
		LoadTranslations("randomcycleplus.phrases");
	} else {
		SetFailState("[RandomCycle+] Unable to locate translation file, please install");
	}
	
	CreateConVar("sm_rcplus_version", PLUGIN_VERSION, "RandomCycle+ version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvar_ExMapsLow = CreateConVar("sm_rcplus_exclude_low", "3", "Number of most recent maps to remove from possible selection when player population is low", FCVAR_PLUGIN, true, 0.0, true, 20.0);
	cvar_ExMapsMed = CreateConVar("sm_rcplus_exclude_med", "4", "Number of most recent maps to remove from possible selection when player population is medium", FCVAR_PLUGIN, true, 0.0, true, 20.0);
	cvar_ExMapsHigh = CreateConVar("sm_rcplus_exclude_high", "5", "Number of most recent maps to remove from possible selection when player population is high", FCVAR_PLUGIN, true, 0.0, true, 20.0);
	cvar_LowPlayerCount = CreateConVar("sm_rcplus_players_low", "8", "Populations less than and equal to this value will trigger lower sized maps (0 to disable)", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_HighPlayerCount = CreateConVar("sm_rcplus_players_high", "14", "Populations greater than and equal to this value will use higher sized maps (0 to disable). Medium sized maps are used when the population is between the high and low values. If there are no numbers between the two values, the medium tier is disabled", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_PlayerCheckTime = CreateConVar("sm_rcplus_check", "60.0", "How often the plugin checks for players (in seconds)", FCVAR_PLUGIN, true, 10.0, true, 300.0);
	cvar_Announce = CreateConVar("sm_rcplus_announce", "0", "If RandomCycle+ changes the nextmap, should it announce that it has?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_LogMSG = CreateConVar("sm_rcplus_logmessage", "0", "If RandomCycle+ changes the nextmap, should it log that it has?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_NextMapHide = CreateConVar("sm_rcplus_hidenextmap", "0", "If RandomCycle+ changes the nextmap, should it hide the \"sm_nextmap\" convar change?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MapStartCheck = CreateConVar("sm_rcplus_checkmapstart", "0", "Should RandomCycle+ check for players and change the nextmap instantly at the start of the map?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MapDupeCheck = CreateConVar("sm_rcplus_duplicates", "0", "Allow duplicate maps in the whole cycle? (1 to allow - 0 to not allow) WARNING: Only enable this if you know what you are doing", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	#if RTV
	cvar_RTV = CreateConVar("sm_rcplus_rtv", "0", "RTV pass rate (0 to disable, also disabled if normal RTV plugin detected)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_RTVplayers = CreateConVar("sm_rcplus_rtv_players", "0", "Minimum player population needed on the server to enable RTV", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_RTVdelay = CreateConVar("sm_rcplus_rtv_delay", "0", "Delay (in seconds) until RTV can start", FCVAR_PLUGIN, true, 0.0);
	#endif
	#if LOWLOAD
	cvar_DisableHighTier = CreateConVar("sm_rcplus_disablehightier", "0", "Disables the high tier after every x maps (0 to disable)", FCVAR_PLUGIN);
	#endif
	
	RegAdminCmd("sm_rcplus_reload", Command_reload, ADMFLAG_CHANGEMAP, "Reloads RandomCycle+ maplists");
	RegAdminCmd("sm_rcplus_resume", Command_resume, ADMFLAG_CHANGEMAP, "Resumes RandomCycle+ if the nextmap has been changed externally");
	RegAdminCmd("sm_rcplus_checkarray", Command_checkarray, ADMFLAG_GENERIC, "Debug - supply an index to check against the old maps array to return its associated map name");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	g_NextMap = FindConVar("sm_nextmap");
	HookConVarChange(g_NextMap, ConVarChanged_NextMap);
	
	flags_g_NextMap = GetConVarFlags(g_NextMap);
	oldflags_g_NextMap = flags_g_NextMap;
	
	AutoExecConfig(true, "plugin.randomcycleplus");
}
	
public OnConfigsExecuted()
{
	new p_High = GetConVarInt(cvar_HighPlayerCount);
	new p_Low = GetConVarInt(cvar_LowPlayerCount);
	if (p_Low == p_High)
	{
		SetFailState("[RandomCycle+] Player count values are the same, look at your configuration again");
	}
	if (p_Low > p_High && p_High != 0)
	{
		SetFailState("[RandomCycle+] Player count values are reversed, look at your configuration again");
	}
	// Triggers a message if RandomCycle hasn't picked a map yet if
	// basetriggers is loaded
	new Handle:g_BaseTriggersLoaded = FindPluginByFile("basetriggers.smx");
	if (g_BaseTriggersLoaded != INVALID_HANDLE)
	{
		b_BaseTriggersLoaded = true;
	} else {
		b_BaseTriggersLoaded = false;
	}
	#if RTV
	// Disables/enables internal RTV if normal RTV detected
	new Handle:g_RTVLoaded = FindPluginByFile("rockthevote.smx");
	if (g_RTVLoaded != INVALID_HANDLE)
	{
		b_RTVLoaded = true;
	} else {
		b_RTVLoaded = false;
	}
	#endif
	LoadMaplist();
	b_PickMapHigh = true;
	b_PickMapMed = true;
	b_PickMapLow = true;
	#if LOWLOAD
	if (GetConVarInt(cvar_DisableHighTier) != 0 && GetConVarInt(cvar_DisableHighTier) == HighCount)
	{
		SetConVarInt(cvar_HighPlayerCount, 0);
		SetConVarInt(cvar_LowPlayerCount, MAXPLAYERS);
		HighCount = 0;
	}
	#endif
	h_RandomCycleCheck = CreateTimer(GetConVarFloat(cvar_PlayerCheckTime), t_RandomCycleCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	// Gets the value of the current nextmap before the plugin
	// takes over control, this is then used if the plugin is set
	// not to be used during low, med or high player counts
	GetNextMap(oldnextmap, sizeof(oldnextmap));
	b_NextMapChanged = false;
	// Optionally instantly check for players and change nextmap
	if (GetConVarInt(cvar_MapStartCheck))
	{
		RandomCycleCheck();
	}
	#if RTV
	if (b_RTVLoaded && GetConVarFloat(cvar_RTV) > 0)
	{
		LogError("%t", "RCP RTV Loaded");
	}
	CreateTimer(GetConVarFloat(cvar_RTVdelay), t_EnableRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	#endif
}

public OnMapStart()
{
	// Reset everything for the plugin to start choosing again
	g_CycleRun = 0;
	g_Players = 0;
	
	// RTV resets
	#if RTV
	b_rtv_ChangingMap = false;
	b_rtv_Enable = false;
	rtv_Count = 0;
	rtv_Needed = 0;
	#endif
	
	// Usual code for delayed load
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public OnMapEnd()
{
	#if LOWLOAD
	if (g_CycleRun == 3)
	{
		HighCount++;
	}
	#endif
	if (h_RandomCycleCheck != INVALID_HANDLE)
	{
		CloseHandle(h_RandomCycleCheck);
	}
}

public Action:t_RandomCycleCheck(Handle:timer_check)
{
	RandomCycleCheck();
	return Plugin_Continue;
}

#if RTV
public Action:t_EnableRTV(Handle:timer_enable_rtv)
{
	b_rtv_Enable = true;
	return Plugin_Stop;
}
#endif

LoadMaplist()
{
	ClearArray(g_MapListHigh);
	ClearArray(g_MapListMed);
	ClearArray(g_MapListLow);
	
	decl String:ConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/randomcycleplus.cfg");
	if (!FileExists(ConfigPath))
	{
		SetFailState("[RandomCycle+] Unable to locate maplist config file, please install and configure");
	}
	
	new Handle:h_configfile = OpenFile(ConfigPath, "r");
	if (h_configfile == INVALID_HANDLE)
	{
		SetFailState("[RandomCycle+] Maplist config file cannot be read, check file.");
	}
	
	new bool:b_LowIsZero = false;
	new bool:b_HighIsZero = false;
	new bool:b_NoMedMaplist = false;
	new p_High = GetConVarInt(cvar_HighPlayerCount);
	new p_Low = GetConVarInt(cvar_LowPlayerCount);
	
	if (p_Low == 0)
	{
		b_LowIsZero = true;
	}
	if (p_High == 0)
	{
		b_HighIsZero = true;
	}
	if (p_High-1 == p_Low)
	{
		b_NoMedMaplist = true;
	}
	
	//----------------------------------------------------------------------------------
	
	decl String:line[255];
	new bool:HighLoaded = false;
	new bool:MedLoaded = false;
	new bool:LowLoaded = false;
	new String:HighMap[65];
	new String:MedMap[65];
	new String:LowMap[65];
	new Handle:g_MapListCheck = CreateArray(33);
	new c_Dupe = GetConVarInt(cvar_MapDupeCheck);
	while(!IsEndOfFile(h_configfile))
	{
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		if ((line[0] != '/') && (line[1] != '/') && (line[0] != '\0') && (line[0] != '*'))
		{
			if (StrContains(line, "High", false) != -1 && !b_HighIsZero)
			{
				while (!HighLoaded) 
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if ((line[0] != '/') && (line[1] != '/') && (line[0] != '\0') && (line[0] != '{') && (line[0] != '*'))
					{
						if(line[0] != '}')
						{
							BreakString(line, HighMap, sizeof(HighMap));
							if (!IsMapValid(HighMap))
							{
								LogError("%s %t", HighMap, "RCP Map Error");
								continue;
							}
							if (!c_Dupe && FindStringInArray(g_MapListCheck, HighMap) != -1)
							{
								LogError("%s %t", HighMap, "RCP Dupe Map");
								continue;
							}
							if (FindStringInArray(g_MapListHigh, HighMap) != -1)
							{
								LogError("%s %t", HighMap, "RCP Dupe Map High");
								continue;
							}
							PushArrayString(g_MapListCheck, HighMap);
							PushArrayString(g_MapListHigh, HighMap);
						} else {
							HighLoaded = true;
						}
					}
				}
			}
			else if (StrContains(line, "Med", false) != -1 && !b_NoMedMaplist && !b_HighIsZero && !b_LowIsZero && (!b_HighIsZero && !b_LowIsZero))
			{
				while (!MedLoaded) 
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if ((line[0] != '/') && (line[1] != '/') && (line[0] != '\0') && (line[0] != '{') && (line[0] != '*'))
					{
						if(line[0] != '}')
						{
							BreakString(line, MedMap, sizeof(MedMap));
							if (!IsMapValid(MedMap))
							{
								LogError("%s %t", MedMap, "RCP Map Error");
								continue;
							}
							if (!c_Dupe && FindStringInArray(g_MapListCheck, MedMap) != -1)
							{
								LogError("%s %t", MedMap, "RCP Dupe Map");
								continue;
							}
							if (FindStringInArray(g_MapListMed, MedMap) != -1)
							{
								LogError("%s %t", MedMap, "RCP Dupe Map Med");
								continue;
							}
							PushArrayString(g_MapListCheck, MedMap);
							PushArrayString(g_MapListMed, MedMap);
						} else {
							MedLoaded = true;
						}
					}
				}
			}
			else if (StrContains(line, "Low", false) != -1 && !b_LowIsZero)
			{
				while (!LowLoaded) 
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if ((line[0] != '/') && (line[1] != '/') && (line[0] != '\0') && (line[0] != '{') && (line[0] != '*'))
					{
						if(line[0] != '}')
						{
							BreakString(line, LowMap, sizeof(LowMap));
							if (!IsMapValid(LowMap))
							{
								LogError("%s %t", LowMap, "RCP Map Error");
								continue;
							}
							if (!c_Dupe && FindStringInArray(g_MapListCheck, LowMap) != -1)
							{
								LogError("%s %t", LowMap, "RCP Dupe Map");
								continue;
							}
							if (FindStringInArray(g_MapListLow, LowMap) != -1)
							{
								LogError("%s %t", LowMap, "RCP Dupe Map Low");
								continue;
							}
							PushArrayString(g_MapListCheck, LowMap);
							PushArrayString(g_MapListLow, LowMap);
						} else {
							LowLoaded = true;
						}
					}
				}
			}
		}
	}
	
	CloseHandle(h_configfile);
	
	// The SetFailState in here is needed otherwise source crashes!
	if (GetArraySize(g_MapListHigh) <= GetConVarInt(cvar_ExMapsHigh) && !b_HighIsZero)
		{
			SetFailState("[RandomCycle+] <High Maplist> Excluded maps value is set too high, reduce value or add more maps to maplist");
		}

	if (GetArraySize(g_MapListMed) <= GetConVarInt(cvar_ExMapsMed) && !b_NoMedMaplist && !b_HighIsZero && !b_LowIsZero && (!b_HighIsZero && !b_LowIsZero))
		{
			SetFailState("[RandomCycle+] <Medium Maplist> Excluded maps value is set too high, reduce value or add more maps to maplist");
		}
	
	if (GetArraySize(g_MapListLow) <= GetConVarInt(cvar_ExMapsLow) && !b_LowIsZero)
		{
			SetFailState("[RandomCycle+] <Low Maplist> Excluded maps value is set too high, reduce value or add more maps to maplist");
		}

}

/////////////
// 'Hooks' //
/////////////

public ConVarChanged_NextMap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If anything happens to change the nextmap externally this
	// will stop the plugin from picking any further changes
	b_NextMapChanged = true;
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	g_Players++;
	#if RTV
	rtv_Counted[client] = false;
	rtv_Needed = RoundToFloor(float(g_Players) * GetConVarFloat(cvar_RTV));
	#endif
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	g_Players--;
	#if RTV
	if (rtv_Counted[client])
	{
		rtv_Count--;
	}
	rtv_Needed = RoundToFloor(float(g_Players) * GetConVarFloat(cvar_RTV));
	if (!b_rtv_Enable || b_RTVLoaded)
	{
		return;
	}
	if (g_Players && rtv_Count >= rtv_Needed)
	{
		RCPRTV();
	}
	#endif
}

public Action:Command_levelchange(args)
{
	b_NextMapChanged = true;
	return Plugin_Continue;
}

public Action:Command_levelchangesm(client, args)
{
	b_NextMapChanged = true;
	return Plugin_Continue;
}

//////////////
// Commands //
//////////////

public Action:Command_reload(client, args)
{	
	// Reloads the maplist during load and changes the nextmap if need be though
	// if a nextmap has been forced externally it won't change it until the
	// plugin has been resumed
	LoadMaplist();
	
	if (!b_PickMapHigh)
		{
			if (FindStringInArray(g_MapListHigh, maphigh) == -1)
			{
				b_PickMapHigh = true;
			}
		}
	if (!b_PickMapMed)
		{
			if (FindStringInArray(g_MapListMed, mapmed) == -1)
			{
				b_PickMapMed = true;
			}
		}
	if (!b_PickMapLow)
		{
			if (FindStringInArray(g_MapListLow, maplow) == -1)
			{
				b_PickMapLow = true;
			}
		}
	g_CycleRun = 0;
	RandomCycleCheck();
	ReplyToCommand(client, "[SM] %t", "RCP Reloaded");
	LogMessage("\"%L\" %t", client, "RCP Reloaded Log");
}

public Action:Command_resume(client, args)
{	
	// Admins can run this to resume the plugin if needed
	b_NextMapChanged = false;
	g_CycleRun = 0;
	RandomCycleCheck();
	ShowActivity(client, "%t", "RCP Resumed");
	LogMessage("\"%L\" %t", client, "RCP Resumed");
}

public Action:Command_checkarray(client, args)
{
	// Checks the given index supplied against the array of old maps
	if (args > 1 || args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "RCP Array");
		return Plugin_Handled;
	}
	if ((g_CycleRun == 0 || g_CycleRun == 4) && !b_NextMapChanged)
	{
		ReplyToCommand(client, "[SM] %t", "RCP Array Wait");
		return Plugin_Handled;
	}
	decl String:arrindex[32];
	GetCmdArg(1, arrindex, sizeof(arrindex));
	new arrindexint = StringToInt(arrindex, 10);
	if (arrindexint > GetArraySize(g_OldMapList)-1)
	{
		ReplyToCommand(client, "[SM] %t", "RCP Array Invalid");
		return Plugin_Handled;
	}
	decl String:mapname[65];
	GetArrayString(g_OldMapList, arrindexint, mapname, sizeof(mapname));
	ReplyToCommand(client, "[SM] %t", "RCP Array Result", arrindexint, mapname);
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	// Grabs the nextmap chat trigger and if the plugin has not
	// picked a map it replies saying so, also rtv triggers if
	// applicable
	decl String:text[192], String:command[64];
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}
	
	decl String:message[8];
	BreakString(text[startidx], message, sizeof(message));
 
	if (strcmp(message, "nextmap", false) == 0 && g_CycleRun == 0 && !b_NextMapChanged && b_BaseTriggersLoaded)
	{
		PrintToChatAll("[SM] %t", "RCP Early Nextmap");
	}
	
	// RTV portion of the chat hooks
	#if RTV
	new ReplySource:rtvreply = SetCmdReplySource(SM_REPLY_TO_CHAT);
	if (strcmp(message, "rtv", false) == 0 || strcmp(message, "rockthevote", false) == 0)
	{
		RCPRTVCheck(client);
	}
	SetCmdReplySource(rtvreply);
	#endif
	return Plugin_Continue;
}

//////////////////
// Internal RTV //
//////////////////

#if RTV
RCPRTVCheck(client)
{
	if (b_RTVLoaded || GetConVarFloat(cvar_RTV) == 0)
	{
		return;
	}
	if (!b_rtv_Enable)
	{
		ReplyToCommand(client, "[SM] %t", "RCP RTV NA");
		return;
	}
	if (g_Players < GetConVarInt(cvar_RTVplayers))
	{
		ReplyToCommand(client, "[SM] %t", "RCP RTV Min", GetConVarInt(cvar_RTVplayers), g_Players);
		return;
	}
	if (rtv_Counted[client])
	{
		ReplyToCommand(client, "[SM] %t", "RCP RTV Voted");
		return;
	}
	rtv_Counted[client] = true;
	rtv_Count++;
	if (rtv_Needed == 0)
	{
		rtv_Needed = 1;
	}
	PrintToChatAll("[SM] %N: %t (%d/%d)", client, "RCP RTV OK", rtv_Count, rtv_Needed);
	if (g_Players && rtv_Count >= rtv_Needed)
	{
		RCPRTV();
	}
}

RCPRTV()
{
	if (b_rtv_ChangingMap)
	{
		return;
	}
	RandomCycleCheck();
	decl String:NextMap[65];
	if (GetNextMap(NextMap, sizeof(NextMap)))
	{
		PrintToChatAll("[SM] %t %s", "RCP RTV Pass", NextMap);
		LogMessage("%t %s", "RCP RTV Pass Log", NextMap);
		new Handle:RTVMap;
		b_rtv_ChangingMap = true;
		CreateDataTimer(5.0, LoadRTVMap, RTVMap, TIMER_FLAG_NO_MAPCHANGE);
		WritePackString(RTVMap, NextMap);
	}
}

public Action:LoadRTVMap(Handle:timer_rtv, Handle:RTVMap)
{
	decl String:NextMap[65];
	ResetPack(RTVMap);
	ReadPackString(RTVMap, NextMap, sizeof(NextMap));
	ForceChangeLevel(NextMap, "RC+ RTV");
	return Plugin_Stop;
}
#endif

//////////////
// RC+ Main //
//////////////

RandomCycleCheck()
{
	// I don't think I could comment on what this all does now but
	// it does its job, various consistancy checks to make sure it
	// should or should not be picking the map!
	if (b_NextMapChanged)
	{
		return;
	}
	#if RTV
	if (b_rtv_ChangingMap)
	{
		return;
	}
	#endif
	new p_High = GetConVarInt(cvar_HighPlayerCount);
	new p_Low = GetConVarInt(cvar_LowPlayerCount);
	if (p_High != 0 && g_Players >= p_High && g_CycleRun != 3)
	{
		g_CycleRun = 3;
		g_ExcludeMaps = GetConVarInt(cvar_ExMapsHigh);
		g_MapList = g_MapListHigh;
		HistoryArray();
		if (b_PickMapHigh)
		{
			NextmapSet();
			maphigh = map;
		}
		setmap = maphigh;
		RandomizeNextmap();
		b_PickMapHigh = false;
		return;
	}
	if ((p_High != 0 || p_Low != 0) && g_Players > p_Low && g_Players < p_High && g_CycleRun != 2)
	{
		g_CycleRun = 2;
		g_ExcludeMaps = GetConVarInt(cvar_ExMapsMed);
		g_MapList = g_MapListMed;
		HistoryArray();
		if (b_PickMapMed)
		{
			NextmapSet();
			mapmed = map;
		}
		setmap = mapmed;
		RandomizeNextmap();
		b_PickMapMed = false;
		return;
	}
	if (p_Low != 0 && g_Players <= p_Low && g_CycleRun != 1)
	{
		g_CycleRun = 1;
		g_ExcludeMaps = GetConVarInt(cvar_ExMapsLow);
		g_MapList = g_MapListLow;
		HistoryArray();
		if (b_PickMapLow)
		{
			NextmapSet();
			maplow = map;
		}
		setmap = maplow;
		RandomizeNextmap();
		b_PickMapLow = false;
		return;
	}
	
	// Checks to see if the plugin needs to disable or not based on the player counts
	// and set the old nextmap (based on default maplist).
	if 	(
			(p_Low == 0 && g_Players < p_High && p_High > p_Low) || 
			(p_High == 0 && g_Players > p_Low && p_Low > p_High) ||
			// And this is here if you're dumb, I mean that in the nicest way
			(p_High == 0 && p_Low == 0)
		)
	{
		if (GetConVarInt(cvar_NextMapHide))
		{
			HideNextMapConVar();
			SetNextMap(oldnextmap);
			ShowNextMapConVar();
		} else {
			SetNextMap(oldnextmap);
		}
		b_NextMapChanged = false;
		g_CycleRun = 4;
		if (GetConVarInt(cvar_Announce))
		{
			PrintToChatAll("[SM] %t %s", "RCP Disable", oldnextmap);
		}
		if (GetConVarInt(cvar_LogMSG))
		{
			LogMessage("%t %s", "RCP Disable", oldnextmap);
		}
		return;
	}
}

HistoryArray()
{
	// We need to work our way BACKWARDS through the maphistory array 
	// so the maps go into the array in the right order
	new String:HistoryMap[65], HistorySize, CurrentIndex = 0;
	ClearArray(g_OldMapList);
	HistorySize = GetMapHistorySize();
	if (HistorySize < g_ExcludeMaps)
	{
		// If there hasn't been enough maps yet to meet the exclude 
		// limit it simply uses the array size of the current MapHistory
		CurrentIndex = HistorySize-1;
		b_MapHistoryLow = true;
		while (HistorySize > GetArraySize(g_OldMapList))
		{
			new String:reason[128], time;
			GetMapHistory(CurrentIndex, HistoryMap, sizeof(HistoryMap), reason, sizeof(reason), time);
			PushArrayString(g_OldMapList, HistoryMap);
			CurrentIndex--;
		}
	} else {
		CurrentIndex = g_ExcludeMaps-1;
		b_MapHistoryLow = false;
		while (g_ExcludeMaps > GetArraySize(g_OldMapList))
		{
			new String:reason[128], time;
			GetMapHistory(CurrentIndex, HistoryMap, sizeof(HistoryMap), reason, sizeof(reason), time);
			PushArrayString(g_OldMapList, HistoryMap);
			CurrentIndex--;
		}
	}
	// Adds the current map to the array so we avoid picking 
	// that too and removes the un-needed last entry, if the
	// array is big enough yet
	new String:CurrentMap[65];
	if (GetCurrentMap(CurrentMap, sizeof(CurrentMap)))
	{
		PushArrayString(g_OldMapList, CurrentMap);
		if (GetArraySize(g_OldMapList) > g_ExcludeMaps-1 && !b_MapHistoryLow)
		{
			RemoveFromArray(g_OldMapList, 0);
		}
	}
}

NextmapSet()
{	
	// Picks and sets what the nextmap will be, checks against
	// the MapHistory array to make sure that it isn't 
	// repeating itself
	new num = GetRandomInt(0, GetArraySize(g_MapList) - 1);
	GetArrayString(g_MapList, num, map, sizeof(map));

	while (FindStringInArray(g_OldMapList, map) != -1)
	{
		num = GetRandomInt(0, GetArraySize(g_MapList) - 1);
		GetArrayString(g_MapList, num, map, sizeof(map));
	}
}

RandomizeNextmap()
{
	// Applies the picked nextmap
	if (GetConVarInt(cvar_NextMapHide))
	{
		HideNextMapConVar();
		SetNextMap(setmap);
		ShowNextMapConVar();
	} else {
		SetNextMap(setmap);
	}
	b_NextMapChanged = false;
	if (GetConVarInt(cvar_Announce))
	{
		PrintToChatAll("[SM] %t %s", "RCP Nextmap", setmap);
	}
	if (GetConVarInt(cvar_LogMSG))
	{
		LogMessage("%t %s", "RCP Nextmap", setmap);
	}
}

HideNextMapConVar()
{
	flags_g_NextMap &= ~FCVAR_NOTIFY;
	SetConVarFlags(g_NextMap, flags_g_NextMap);
}

ShowNextMapConVar()
{
	SetConVarFlags(g_NextMap, oldflags_g_NextMap);
}