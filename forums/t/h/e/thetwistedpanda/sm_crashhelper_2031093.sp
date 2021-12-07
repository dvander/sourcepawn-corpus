/*
Version 1.0.1
-------------
- Added a noticible block of text (7 lines) that gets logged when plugin loads to help narrow down crashes.
- Changed hook mode to Pre (prior to clients being notified).

Version 1.0.2
-------------
- Expanded sm_crashhelper_detect; Requires server restart due to upper bounds being raised.
-- Using the flag 16 results in Entity Logging (hooks OnEntityCreated/OnEntityDestroyed)
--- Displays classname, current entity index, total entity count, maximum entities allowed
-- Using the flag 32 results in Command Logging (hooks AddCommandListener)
--- Displays client name, client steam, and any command arguments.
- Reduced block of text in v1.0.1 to 3 lines... (Booze wanted 7)
- Cleaned up logging phrases.
- Cvar Changes:
-- sm_crashhelper_ignore has been renamed to sm_crashhelper_ignore_events.
-- sm_crashhelper_path_logging has been depreciated and 6 sub-cvars have been created:
--- sm_crashhelper_path_logging_connect
--- sm_crashhelper_path_logging_events
--- sm_crashhelper_path_logging_population
--- sm_crashhelper_path_logging_map
--- sm_crashhelper_path_logging_entity
--- sm_crashhelper_path_logging_commands
-- Added sm_crashhelper_ignore_entities, which ignores entities for entity logging similar to sm_crashhelper_ignore_events.
-- Added sm_crashhelper_ignore_commands, which ignores commands for command logging similar to sm_crashhelper_ignore_events.
-- sm_crashhelper_path_logging_* cvars are no longer hooked for changes; reload plugin if you modify.
- Revision 1.0.2a
-- Added a IsClientInGame check to prevent errors.
*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.2a"

#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig

//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Defines
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//- Total detecting.
#define cLogTotal				6
//- Indexes for detecting.
#define cLogIndexConnections	0
#define cLogIndexEvent			1
#define cLogIndexPopulation		2
#define cLogIndexMap			3
#define cLogIndexEntity			4
#define cLogIndexCommands		5
//- States for detecting.
#define cLogConnections			1
#define cLogEvent				2
#define cLogPopulation			4
#define cLogMap					8
#define cLogEntity				16
#define cLogCommands			32
//- Required for parsing events.res.
enum EventKeys
{
	Key_Null,
	Key_Bool,
	Key_Byte,
	Key_Float,
	Key_Long,
	Key_Short,
	Key_String
};
new String:g_sEventKeys[7][] =
{
	"",
	"bool",
	"byte",
	"float",
	"long",
	"short",
	"string"
};
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Handles
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hStamp = INVALID_HANDLE;
new Handle:g_hModPath = INVALID_HANDLE;
new Handle:g_hServerPath = INVALID_HANDLE;
new Handle:g_hLogPath[cLogTotal] = { INVALID_HANDLE, ... };
new Handle:g_hDetect = INVALID_HANDLE;
new Handle:g_hIgnoredEntities = INVALID_HANDLE;
new Handle:g_hIgnoredEvents = INVALID_HANDLE;
new Handle:g_hIgnoredCommands = INVALID_HANDLE;
new Handle:g_hTimer_Monitor = INVALID_HANDLE;
new Handle:g_hArray_DefinedEvents = INVALID_HANDLE;
new Handle:g_hArray_DefinedEventKeys = INVALID_HANDLE;
new Handle:g_hTrie_DefinedEvents = INVALID_HANDLE;
new Handle:g_hArray_IgnoredEvents = INVALID_HANDLE;
new Handle:g_hArray_IgnoredEntities = INVALID_HANDLE;
new Handle:g_hArray_IgnoredCommands = INVALID_HANDLE;
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Variables
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new g_iEnabled;
new g_iDetect;
new g_iEvents;
new g_iEntityCount;
new g_iEntityMax;
new g_iTotalIgnoredEvents;
new g_iTotalIgnoredEntities;
new g_iTotalIgnoredCommands;
new g_iIgnoreLog[cLogTotal] = { -1, ... };
new bool:g_bConfigsExecuted;
new bool:g_bMonitor[cLogTotal];
new bool:g_bLateLoad;
new bool:g_bClassname[4096];
new String:g_sCurrentMap[PLATFORM_MAX_PATH];
new String:g_sGame[32];
new String:g_sStamp[32];
new String:g_sLastStamp[cLogTotal][64];
new String:g_sModPath[PLATFORM_MAX_PATH];
new String:g_sServerPath[PLATFORM_MAX_PATH];
new String:g_sLogPath[cLogTotal][PLATFORM_MAX_PATH];
new String:g_sClassname[4096][64];
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Clients
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new bool:g_bAuthed[MAXPLAYERS + 1];
new String:g_sAuth[MAXPLAYERS + 1][24];
new String:g_sAddress[MAXPLAYERS + 1][20];

public Plugin:myinfo =
{
	name = "[SM] Crash Helper",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "Provides functionality for logging massive amounts of information for tracing crashes.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmodders.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	GetGameFolderName(g_sGame, sizeof(g_sGame));
	LogMessage("[SM] Crash Helper: Detected Game '%s'", g_sGame);

	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	strcopy(g_sAuth[0], sizeof(g_sAuth[]), "Server");

	new iPos;
	decl String:sBuffer[PLATFORM_MAX_PATH], String:sLogging[cLogTotal][PLATFORM_MAX_PATH];
	AutoExecConfig_SetFile("sm_crashhelper");
	AutoExecConfig_CreateConVar("sm_crashhelper_version", PLUGIN_VERSION, "[SM] Crash Helper: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = AutoExecConfig_CreateConVar("sm_crashhelper_enabled", "1", "Enables/disables all features of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarInt(g_hEnabled);

	g_hDetect = AutoExecConfig_CreateConVar("sm_crashhelper_detect", "63", "Determines what information is logged; add values together for totals) (1 = Connections, 2 = Events, 4 = Population (Every 60.0 Seconds), 8 = Map Changes, 16 = Entity Create/Destroy", FCVAR_NONE, true, 0.0, true, 63.0);
	HookConVarChange(g_hDetect, OnCVarChange);
	g_iDetect = GetConVarInt(g_hDetect);

	g_hStamp = AutoExecConfig_CreateConVar("sm_crashhelper_stamp", "*d.*m", "Used for determining the format of optional <stamp> within sm_crashhelper_path_logging. For more informaiton, see http://www.cplusplus.com/reference/ctime/strftime/. (Note: Replace the percent sign with *, to prevent errors parsing. The plugin will correct it. In addition, the results will have all spaces replaced with periods)", FCVAR_NONE);
	HookConVarChange(g_hStamp, OnCVarChange);
	GetConVarString(g_hStamp, g_sStamp, sizeof(g_sStamp));
	while((iPos = FindCharInString(g_sStamp, '*')) != -1)
		g_sStamp[iPos] = '%';

	g_hIgnoredEvents = AutoExecConfig_CreateConVar("sm_crashhelper_ignore_events", "player_footstep,weapon_fire,bullet_impact,server_cvar,player_jump", "Events that will be ignored if logging events. Separate multiple events with a comma.", FCVAR_NONE);
	HookConVarChange(g_hIgnoredEvents, OnCVarChange);

	g_hIgnoredEntities = AutoExecConfig_CreateConVar("sm_crashhelper_ignore_entities", "light,infodecal", "Entities that will be ignored if logging entities. Separate multiple classnames with a comma.", FCVAR_NONE);
	HookConVarChange(g_hIgnoredEntities, OnCVarChange);
	
	g_hIgnoredCommands = AutoExecConfig_CreateConVar("sm_crashhelper_ignore_commands", "vmodenable,vban", "Commands that will be ignored if logging commands. Separate multiple commands with a comma.", FCVAR_NONE);
	HookConVarChange(g_hIgnoredCommands, OnCVarChange);

	g_hModPath = AutoExecConfig_CreateConVar("sm_crashhelper_path_modevents", "configs/crashhelper/<game>/modevents.res", "The path to the modevents.res file, which is required for logging events. <game> is optional and will be replaced with the result of GetGameFolderName.", FCVAR_NONE);
	GetConVarString(g_hModPath, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), "<game>", g_sGame);
	BuildPath(Path_SM, g_sModPath, sizeof(g_sModPath), sBuffer);

	g_hServerPath = AutoExecConfig_CreateConVar("sm_crashhelper_path_serverevents", "configs/crashhelper/<game>/serverevents.res", "The path to the serverevents.res file, which is required for logging events. <game> is optional and will be replaced with the result of GetGameFolderName.", FCVAR_NONE);
	GetConVarString(g_hServerPath, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), "<game>", g_sGame);
	BuildPath(Path_SM, g_sServerPath, sizeof(g_sServerPath), sBuffer);

	g_hLogPath[cLogIndexConnections] = AutoExecConfig_CreateConVar("sm_crashhelper_path_logging_connect", "logs/crashhelper/general.<stamp>.log", "Determines which file the plugin will print connect/disconnects to. <stamp> is optional and will be replaced with the result of sm_crashhelper_stamp.", FCVAR_NONE);
	GetConVarString(g_hLogPath[cLogIndexConnections], sLogging[cLogIndexConnections], sizeof(sLogging[]));
	g_bMonitor[cLogIndexConnections] = (StrContains(sLogging[cLogIndexConnections], "<stamp>", false) != -1) ? true : false;

	g_hLogPath[cLogIndexEvent] = AutoExecConfig_CreateConVar("sm_crashhelper_path_logging_events", "logs/crashhelper/events.<stamp>.log", "Determines which file the plugin will print events to. <stamp> is optional and will be replaced with the result of sm_crashhelper_stamp.", FCVAR_NONE);
	GetConVarString(g_hLogPath[cLogIndexEvent], sLogging[cLogIndexEvent], sizeof(sLogging[]));
	g_bMonitor[cLogIndexEvent] = (StrContains(sLogging[cLogIndexEvent], "<stamp>", false) != -1) ? true : false;

	g_hLogPath[cLogIndexPopulation] = AutoExecConfig_CreateConVar("sm_crashhelper_path_logging_population", "logs/crashhelper/general.<stamp>.log", "Determines which file the plugin will print population updates to. <stamp> is optional and will be replaced with the result of sm_crashhelper_stamp.", FCVAR_NONE);
	GetConVarString(g_hLogPath[cLogIndexPopulation], sLogging[cLogIndexPopulation], sizeof(sLogging[]));
	g_bMonitor[cLogIndexPopulation] = (StrContains(sLogging[cLogIndexPopulation], "<stamp>", false) != -1) ? true : false;

	g_hLogPath[cLogIndexMap] = AutoExecConfig_CreateConVar("sm_crashhelper_path_logging_map", "logs/crashhelper/general.<stamp>.log", "Determines which file the plugin will print map changes to. <stamp> is optional and will be replaced with the result of sm_crashhelper_stamp.", FCVAR_NONE);
	GetConVarString(g_hLogPath[cLogIndexMap], sLogging[cLogIndexMap], sizeof(sLogging[]));
	g_bMonitor[cLogIndexMap] = (StrContains(sLogging[cLogIndexMap], "<stamp>", false) != -1) ? true : false;

	g_hLogPath[cLogIndexEntity] = AutoExecConfig_CreateConVar("sm_crashhelper_path_logging_entity", "logs/crashhelper/entities.<stamp>.log", "Determines which file the plugin will print to entity create/destroy to. <stamp> is optional and will be replaced with the result of sm_crashhelper_stamp.", FCVAR_NONE);
	GetConVarString(g_hLogPath[cLogIndexEntity], sLogging[cLogIndexEntity], sizeof(sLogging[]));
	g_bMonitor[cLogIndexEntity] = (StrContains(sLogging[cLogIndexEntity], "<stamp>", false) != -1) ? true : false;

	g_hLogPath[cLogIndexCommands] = AutoExecConfig_CreateConVar("sm_crashhelper_path_logging_commands", "logs/crashhelper/commands.<stamp>.log", "Determines which file the plugin will print client commands to. <stamp> is optional and will be replaced with the result of sm_crashhelper_stamp.", FCVAR_NONE);
	GetConVarString(g_hLogPath[cLogIndexCommands], sLogging[cLogIndexCommands], sizeof(sLogging[]));
	g_bMonitor[cLogIndexCommands] = (StrContains(sLogging[cLogIndexCommands], "<stamp>", false) != -1) ? true : false;

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	g_hArray_DefinedEvents = CreateArray(16);
	g_hArray_DefinedEventKeys = CreateArray();
	g_hTrie_DefinedEvents = CreateTrie();

	DefineIgnoredEvents();
	DefineIgnoredEntities();
	DefineIgnoredCommands();
	DefineEvents(g_sModPath);
	DefineEvents(g_sServerPath);

	g_iEntityMax = GetMaxEntities();
	g_hTimer_Monitor = CreateTimer(60.0, Timer_Monitor, _, TIMER_REPEAT);
	for(new i = 0; i < cLogTotal; i++)
	{
		for(new j = i + 1; j < cLogTotal; j++)
		{
			if(StrEqual(sLogging[i], sLogging[j]))
			{
				g_iIgnoreLog[j] = i;
			}
		}
	}

	MonitorFileStamps();
	for(new i = 0; i < cLogTotal; i++)
	{
		if(g_iIgnoreLog[i] != -1 || !FileExists(g_sLogPath[i]))
			continue;

		LogToFileEx(g_sLogPath[i], "================================================================================");
		LogToFileEx(g_sLogPath[i], ">>> Plugin Loaded <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
		LogToFileEx(g_sLogPath[i], "================================================================================");
	}
	
	AddCommandListener(LogClientCommand);
}

public OnPluginEnd()
{
	//Unnecessary, but removes the warning incase I need the handle.
	if(g_hTimer_Monitor != INVALID_HANDLE && CloseHandle(g_hTimer_Monitor))
		g_hTimer_Monitor = INVALID_HANDLE;
}

public Action:LogClientCommand(client, const String:command[], argc)
{
	if(!g_iEnabled || !(g_iDetect & cLogCommands))
		return Plugin_Continue;
		
	if(g_iTotalIgnoredCommands && FindStringInArray(g_hArray_IgnoredCommands, command) != -1)
		return Plugin_Continue;

	decl String:sText[256];
	GetCmdArgString(sText, sizeof(sText));

	LogToFileEx(g_sLogPath[cLogIndexCommands], "Command: Steam:%s, Command:%s, Arguments:%s", g_sAuth[client], command, sText);
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	if(!g_iEnabled)
		return;

	if(g_bLateLoad || !g_bConfigsExecuted)
	{
		g_iEntityCount = 0;

		for(new i = 1; i <= g_iEntityMax; i++)
		{
			if(!IsValidEdict(i) || !IsValidEntity(i))
				continue;

			g_iEntityCount++;
			if(g_iDetect & cLogMap)
			{
				g_bClassname[i] = true;
				GetEntityClassname(i, g_sClassname[i], sizeof(g_sClassname[]));

				LogToFileEx(g_sLogPath[cLogIndexEntity], "Entity: (EXISTS) Classname:%s, Entity:%d, Total:%d/%d", g_sClassname[i], i, g_iEntityCount, g_iEntityMax);
			}
		}

		if(!g_bConfigsExecuted)
			g_bConfigsExecuted = true;
		if(g_bLateLoad)
			g_bLateLoad = false;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(entity < 0 || !g_bConfigsExecuted)
		return;

	g_iEntityCount++;
	if(!g_iEnabled || !(g_iDetect & cLogEntity))
		return;

	if(g_iTotalIgnoredEntities && FindStringInArray(g_hArray_IgnoredEntities, classname) != -1)
		return;

	g_bClassname[entity] = true;
	strcopy(g_sClassname[entity], sizeof(g_sClassname[]), classname);
	LogToFileEx(g_sLogPath[cLogIndexEntity], "Entity: (CREATE) Classname:%s, Entity:%d, Total:%d/%d", classname, entity, g_iEntityCount, g_iEntityMax);
}

public OnEntityDestroyed(entity)
{
	if(entity < 0 || !g_bConfigsExecuted)
		return;

	g_iEntityCount--;
	if(!g_iEnabled || !(g_iDetect & cLogEntity) || !g_bClassname[entity])
		return;

	g_bClassname[entity] = false;
	LogToFileEx(g_sLogPath[cLogIndexEntity], "Entity: (DELETE) Classname:%s, Entity:%d, Total:%d/%d", g_sClassname[entity], entity, g_iEntityCount, g_iEntityMax);
}

public OnMapStart()
{
	if(!g_iEnabled || !(g_iDetect & cLogMap))
		return;

	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(sBuffer, sizeof(sBuffer));

	LogToFileEx(g_sLogPath[cLogIndexMap], "Map: (START) Map:%s, Previous:%s", sBuffer, g_sCurrentMap);
	strcopy(g_sCurrentMap, sizeof(g_sCurrentMap), sBuffer);
}

public OnMapEnd()
{
	if(!g_iEnabled || !(g_iDetect & cLogMap))
		return;

	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(sBuffer, sizeof(sBuffer));

	LogToFileEx(g_sLogPath[cLogIndexMap], "Map: (FINISH) Map:%s", sBuffer);
}

public OnClientAuthorized(client, const String:steamid[])
{
	if(!g_iEnabled)
		return;

	g_bAuthed[client] = true;
	strcopy(g_sAuth[client], sizeof(g_sAuth[]), steamid);
	if(IsClientInGame(client))
		GetClientIP(client, g_sAddress[client], sizeof(g_sAddress[]));

	if(g_iDetect & cLogConnections)
	{
		LogToFileEx(g_sLogPath[cLogIndexConnections], "Connect: (JOIN) Steam:%s, IP: %s, Name:%N", g_sAuth[client], g_sAddress[client], client);
	}
}

public OnClientDisconnect(client)
{
	if(!g_iEnabled || !IsClientInGame(client))
		return;

	if(g_bAuthed[client])
	{
		if(g_iDetect & cLogConnections)
		{
			LogToFileEx(g_sLogPath[cLogIndexConnections], "Connect: (LEAVE) Steam:%s, IP: %s, Name:%N", g_sAuth[client], g_sAddress[client], client);
		}

		g_sAuth[client][0] = '\0';
		g_sAddress[client][0] = '\0';
	}
}

DefineIgnoredEvents()
{
	g_iTotalIgnoredEvents = 0;
	if(g_hArray_IgnoredEvents == INVALID_HANDLE)
		g_hArray_IgnoredEvents = CreateArray(16);
	else
		ClearArray(g_hArray_IgnoredEvents);

	decl String:sBuffer[8192];
	decl String:sExplode[128][64];
	GetConVarString(g_hIgnoredEvents, sBuffer, sizeof(sBuffer));
	g_iTotalIgnoredEvents = ExplodeString(sBuffer, ",", sExplode, sizeof(sExplode), sizeof(sExplode[]));
	for(new i = 0; i < g_iTotalIgnoredEvents; i++)
		PushArrayString(g_hArray_IgnoredEvents, sExplode[i]);
}

DefineIgnoredEntities()
{
	g_iTotalIgnoredEntities = 0;
	if(g_hArray_IgnoredEntities == INVALID_HANDLE)
		g_hArray_IgnoredEntities = CreateArray(16);
	else
		ClearArray(g_hArray_IgnoredEntities);

	decl String:sBuffer[8192];
	decl String:sExplode[128][64];
	GetConVarString(g_hIgnoredEntities, sBuffer, sizeof(sBuffer));
	g_iTotalIgnoredEntities = ExplodeString(sBuffer, ",", sExplode, sizeof(sExplode), sizeof(sExplode[]));
	for(new i = 0; i < g_iTotalIgnoredEntities; i++)
		PushArrayString(g_hArray_IgnoredEntities, sExplode[i]);
}

DefineIgnoredCommands()
{
	g_iTotalIgnoredCommands = 0;
	if(g_hArray_IgnoredCommands == INVALID_HANDLE)
		g_hArray_IgnoredCommands = CreateArray(16);
	else
		ClearArray(g_hArray_IgnoredCommands);

	decl String:sBuffer[8192];
	decl String:sExplode[128][64];
	GetConVarString(g_hIgnoredCommands, sBuffer, sizeof(sBuffer));
	g_iTotalIgnoredCommands = ExplodeString(sBuffer, ",", sExplode, sizeof(sExplode), sizeof(sExplode[]));
	for(new i = 0; i < g_iTotalIgnoredCommands; i++)
		PushArrayString(g_hArray_IgnoredCommands, sExplode[i]);
}

DefineEvents(const String:sPath[])
{
	new Handle:hKeyValues = CreateKeyValues("Crash.Events");
	if(FileToKeyValues(hKeyValues, sPath) && KvGotoFirstSubKey(hKeyValues))
	{
		decl String:sBuffer[64];
		do
		{
			KvGetSectionName(hKeyValues, sBuffer, sizeof(sBuffer));
			if(g_iTotalIgnoredEvents && FindStringInArray(g_hArray_IgnoredEvents, sBuffer) != -1)
				continue;

			ResizeArray(g_hArray_DefinedEvents, g_iEvents + 1);
			ResizeArray(g_hArray_DefinedEventKeys, g_iEvents + 1);
			SetArrayString(g_hArray_DefinedEvents, g_iEvents, sBuffer);
			SetTrieValue(g_hTrie_DefinedEvents, sBuffer, g_iEvents);
			HookEvent(sBuffer, Event_OnEventFire, EventHookMode_Pre);

			if(KvGotoFirstSubKey(hKeyValues, false))
			{
				new Handle:hTemp = CreateArray(10);
				do
				{
					new iSize = GetArraySize(hTemp);
					ResizeArray(hTemp, iSize + 1);

					KvGetSectionName(hKeyValues, sBuffer, sizeof(sBuffer));
					SetArrayString(hTemp, iSize, sBuffer);

					KvGetString(hKeyValues, NULL_STRING, sBuffer, sizeof(sBuffer));
					for(new i = 1; i <= 6; i++)
					{
						if(StrEqual(sBuffer, g_sEventKeys[i], false))
						{
							SetArrayCell(hTemp, iSize, EventKeys:i, 9);
							break;
						}
					}

				}
				while(KvGotoNextKey(hKeyValues, false));

				SetArrayCell(g_hArray_DefinedEventKeys, g_iEvents, hTemp);
				KvGoBack(hKeyValues);
			}
			else
			{
				SetArrayCell(g_hArray_DefinedEventKeys, g_iEvents, INVALID_HANDLE);
			}

			g_iEvents++;
		}
		while (KvGotoNextKey(hKeyValues));
	}

	CloseHandle(hKeyValues);
}

public Event_OnEventFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_iEnabled || !(g_iDetect & cLogEvent))
		return;

	new iEvent;
	if(GetTrieValue(g_hTrie_DefinedEvents, name, iEvent))
	{
		new Handle:hTemp = GetArrayCell(g_hArray_DefinedEventKeys, iEvent);
		if(hTemp == INVALID_HANDLE)
			LogToFileEx(g_sLogPath[cLogIndexEvent], "Event:%s Fired!", name);
		else
		{
			new String:sFormat[256];
			new iSize = GetArraySize(hTemp);
			for(new i = 0; i < iSize; i++)
			{
				decl String:sType[36];
				GetArrayString(hTemp, i, sType, sizeof(sType));
				new EventKeys:iType = EventKeys:GetArrayCell(hTemp, i, 9);
				switch(iType)
				{
					case Key_Bool:
					{
						Format(sFormat, sizeof(sFormat), "%s %s:%b", sFormat, sType, GetEventBool(event, sType));
					}
					case Key_Byte, Key_Long, Key_Short:
					{
						Format(sFormat, sizeof(sFormat), "%s %s:%d", sFormat, sType, GetEventInt(event, sType));
					}
					case Key_Float:
					{
						Format(sFormat, sizeof(sFormat), "%s %s:%f", sFormat, sType, GetEventFloat(event, sType));
					}
					case Key_String:
					{
						decl String:sBuffer[256];
						GetEventString(event, sType, sBuffer, sizeof(sBuffer));
						Format(sFormat, sizeof(sFormat), "%s %s:%s", sFormat, sType, sBuffer);
					}
				}
			}

			LogToFileEx(g_sLogPath[cLogIndexEvent], "Event:%s Fired!%s", name, sFormat);
		}
	}
}

public Action:Timer_Monitor(Handle:timer)
{
	if(!g_iEnabled)
	{
		g_hTimer_Monitor = INVALID_HANDLE;
		return Plugin_Stop;
	}

	MonitorFileStamps();
	if(g_iDetect & cLogPopulation)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i))
				continue;

			LogToFileEx(g_sLogPath[cLogIndexPopulation], "Population: Steam:%s, IP:%s, Name:%N", g_sAuth[i], g_sAddress[i], i);
		}
	}

	return Plugin_Continue;
}

MonitorFileStamps()
{
	decl String:sBuffer[64], String:sPath[PLATFORM_MAX_PATH];
	for(new i = 0; i < cLogTotal; i++)
	{
		if(g_iIgnoreLog[i] != -1)
		{
			strcopy(g_sLogPath[i], sizeof(g_sLogPath[]), g_sLogPath[g_iIgnoreLog[i]]);
			continue;
		}

		GetConVarString(g_hLogPath[i], sPath, sizeof(sPath));
		if(StrContains(sPath, "<stamp>") == -1)
		{
			BuildPath(Path_SM, g_sLogPath[i], sizeof(g_sLogPath[]), sPath);
			continue;
		}

		new iPos;
		FormatTime(sBuffer, sizeof(sBuffer), g_sStamp, GetTime());
		while((iPos = FindCharInString(sBuffer, ' ')) != -1)
			sBuffer[iPos] = '.';

		if(!StrEqual(sBuffer, g_sLastStamp[i], false))
		{
			strcopy(g_sLastStamp[i], sizeof(g_sLastStamp[]), sBuffer);

			ReplaceString(sPath, sizeof(sPath), "<stamp>", g_sLastStamp[i]);
			BuildPath(Path_SM, g_sLogPath[i], sizeof(g_sLogPath[]), sPath);
		}
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = StringToInt(newvalue);
	}
	else if(cvar == g_hDetect)
	{
		g_iDetect = StringToInt(newvalue);
	}
	else if(cvar == g_hStamp)
	{
		new iPos;
		strcopy(g_sStamp, sizeof(g_sStamp), newvalue);
		while((iPos = FindCharInString(g_sStamp, '*')) != -1)
			g_sStamp[iPos] = '%';
	}
	else if(cvar == g_hIgnoredEvents)
	{
		DefineIgnoredEvents();
	}
	else if(cvar == g_hIgnoredEntities)
	{
		DefineIgnoredEntities();
	}
	else if(cvar == g_hIgnoredCommands)
	{
		DefineIgnoredCommands();
	}
}