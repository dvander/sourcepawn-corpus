//To Do:
//convert integers into booleans where applicable

#pragma semicolon 1
#define PLUGIN_VERSION "2.5"

#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig
#include <sdktools>

//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Handles
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new Handle:hEnabled = INVALID_HANDLE;
new Handle:hEnableMainLog = INVALID_HANDLE;
new Handle:hEnableConnections = INVALID_HANDLE;
new Handle:hEnableIds = INVALID_HANDLE;
new Handle:hEnableSpawns = INVALID_HANDLE;
new Handle:hEnableRounds = INVALID_HANDLE;
new Handle:hEnableStartLastPop = INVALID_HANDLE;
new Handle:hEnableMidRoundPop = INVALID_HANDLE;
new Handle:hTimer_Monitor = INVALID_HANDLE;
new Handle:hStartTimer_Monitor = INVALID_HANDLE;
new Handle:hSpawnTimer_Monitor = INVALID_HANDLE;
new Handle:hMaxtlimit = INVALID_HANDLE;
new Handle:hMaxctlimit = INVALID_HANDLE;
new Handle:hMidRoundPopTimer = INVALID_HANDLE;
new Handle:hStartPopTimer = INVALID_HANDLE;
new Handle:hSpawnTimer = INVALID_HANDLE;
new Handle:hMainLogDays = INVALID_HANDLE;
new Handle:hSumLogDays = INVALID_HANDLE;
new Handle:hDebug= INVALID_HANDLE;
//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Variables
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new iEnabled;		//enable plugin integer
new iEnableMainLog;		//enable main log integer
new iMainLogDays;
new iEnableConnections;		//enable connection logging integer
new iEnableIds;		//enable loging IDs and names integer
new iEnableSpawns;	//enable logging of spawns available integer
new iEnableRounds;	//enable logging of wins and total rounds integer
new iEnableStartLastPop;	//enable logging map start and end populations integer
new iEnableMidRoundPop;	//enable logging population every interval set by midroundpoptimer integer
new iMaxtlimit;
new iMaxctlimit;
new iSumLogDays;
new iDebug;	//Debug mode integer

new String:g_sCurrentMap[PLATFORM_MAX_PATH];
new maxplayersconnected = -1;
new playersconnected = 0;	//current players connected - used by maxplayersconnected and with connect and disconnects
new maxspawns_t = 0;	//variable for logging t spawns available in map
new maxspawns_ct = 0;	//variable for logging ct spawns available in map
new totalspawns = 0;	//variable for logging total spawns available in map
new playercountstart = 0;	//variable for player count at start of map - set after interval defined by startpoptimer
new playercountlast = 0; //variable for player count at end of map
new playercountchange = 0; //variable for tracking change in amount of players from start to finish

new String:sDebugPath[PLATFORM_MAX_PATH];		//debug file path
new String:sSpawns[PLATFORM_MAX_PATH];		//spawn file path
new String:sMainPath[PLATFORM_MAX_PATH];		//main file path
new String:sumpath[PLATFORM_MAX_PATH];		//popsummary file path
new String:cleanlogs[PLATFORM_MAX_PATH];		//cleanpath file path

//* * * * * * * * * * * * * * * * * * * * * * * * * *
//Clients
//* * * * * * * * * * * * * * * * * * * * * * * * * *
new bool:g_bAuthed[MAXPLAYERS + 1];
new String:g_sAuth[MAXPLAYERS + 1][24];

public Plugin:myinfo =
{
	name = "Population Tracker v2_5",
	author = "That One Guy",
	description = "Tracks player populations, connects/disconnects, player info, spawns, wins, and rounds for each map",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	strcopy(g_sAuth[0], sizeof(g_sAuth[]), "Server");

	AutoExecConfig_SetFile("populationtrackerv2_5");
	AutoExecConfig_CreateConVar("pt_version", PLUGIN_VERSION, "Population Tracker: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	hEnabled = AutoExecConfig_CreateConVar("pt_a_enabled", "1", "Enable plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnabled, OnCVarChange);
	iEnabled = GetConVarInt(hEnabled);
	
	hEnableMainLog = AutoExecConfig_CreateConVar("pt_b_enablemainlog", "1", "Enable the main log.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableMainLog, OnCVarChange);
	iEnableMainLog = GetConVarInt(hEnableMainLog);
	
	hEnableConnections = AutoExecConfig_CreateConVar("pt_c_connections", "0", "Enables logging of connects/disconnects.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableConnections, OnCVarChange);
	iEnableConnections = GetConVarInt(hEnableConnections);
	
	hMainLogDays = AutoExecConfig_CreateConVar("pt_d_mainlogdays", "2", "After how many days old should the main log files be deleted? (0 = disable)", FCVAR_NONE, true, 0.0);
	HookConVarChange(hMainLogDays, OnCVarChange);
	iMainLogDays = GetConVarInt(hMainLogDays);
	
	hEnableIds = AutoExecConfig_CreateConVar("pt_e_enableids", "0", "Enables logging of steam IDs and names during population checks. (0 = Disabled, 1 = Enabled) Note: Requires pt_f_enablepop = 1", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableIds, OnCVarChange);
	iEnableIds = GetConVarInt(hEnableIds);
		
	hEnableMidRoundPop = AutoExecConfig_CreateConVar("pt_f_enablepop", "0", "Enables logging of player population throughout a map every interval set by pt_g_poptimer", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableMidRoundPop, OnCVarChange);
	iEnableMidRoundPop = GetConVarInt(hEnableMidRoundPop);
	
	hMidRoundPopTimer = AutoExecConfig_CreateConVar("pt_g_poptimer", "90", "Interval (in seconds) between each population log if pt_f_enablepop = 1", FCVAR_NONE, true, 0.0);
	HookConVarChange(hMidRoundPopTimer, OnCVarChange);
	
	hEnableSpawns = AutoExecConfig_CreateConVar("pt_h_enablespawns", "1", "Enables logging of total CT/T/Total spawns available and output of file logging maps with less spawns than pt_i_maxtlimit or pt_j_maxctlimit", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableSpawns, OnCVarChange);
	iEnableSpawns = GetConVarInt(hEnableSpawns);
	
	hMaxtlimit = AutoExecConfig_CreateConVar("pt_i_maxtlimit", "18", "Max T Limit to set for logging if a map has too few Terrorist spawn points", FCVAR_NONE, true, 0.0);
	HookConVarChange(hMaxtlimit, OnCVarChange);
	iMaxtlimit = GetConVarInt(hMaxtlimit);
	
	hMaxctlimit = AutoExecConfig_CreateConVar("pt_j_maxctlimit", "18", "Max CT Limit to set for logging if a map has too few Counter-Terrorist spawn points", FCVAR_NONE, true, 0.0);
	HookConVarChange(hMaxctlimit, OnCVarChange);
	iMaxctlimit = GetConVarInt(hMaxctlimit);
	
	hSpawnTimer = AutoExecConfig_CreateConVar("pt_k_spawntimer", "20", "Amount of time after map start until spawn points are recorded (be sure to allow time for applicable plugins to alter spawns)", FCVAR_NONE, true, 0.0);
	HookConVarChange(hSpawnTimer, OnCVarChange);
	
	hEnableStartLastPop = AutoExecConfig_CreateConVar("pt_l_enablestartlastpop", "1", "Enables output of extra log containing map populations at start/end", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableStartLastPop, OnCVarChange);
	iEnableStartLastPop = GetConVarInt(hEnableStartLastPop);
		
	hStartPopTimer = AutoExecConfig_CreateConVar("pt_m_startpoptimer", "30", "Amount of time after map start until map start population is taken (be sure to allow time for players to connect)", FCVAR_NONE, true, 0.0);
	HookConVarChange(hStartPopTimer, OnCVarChange);
	
	hSumLogDays = AutoExecConfig_CreateConVar("pt_n_sumlogdays", "3", "After how many days old should the start/end population log files be deleted? (0 = disable)", FCVAR_NONE, true, 0.0);
	HookConVarChange(hSumLogDays, OnCVarChange);
	iSumLogDays = GetConVarInt(hSumLogDays);
	
	hEnableRounds = AutoExecConfig_CreateConVar("pt_o_enablerounds", "0", "Enables logging of total rounds played each map, and CT/T wins", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableRounds, OnCVarChange);
	iEnableRounds = GetConVarInt(hEnableRounds);
	
	hDebug = AutoExecConfig_CreateConVar("pt_p_debugmode", "0", "Enables debug mode output", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hDebug, OnCVarChange);
	iDebug = GetConVarInt(hDebug);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//path builds
	BuildPath(Path_SM, sDebugPath, sizeof(sDebugPath), "logs/populationtrackerv2/debug.log");
	BuildPath(Path_SM, sSpawns, sizeof(sSpawns), "logs/populationtrackerv2/mapspawns.log");
	FormatTime(sMainPath, sizeof(sMainPath), "pt_%m-%d.log");
	BuildPath(Path_SM, sMainPath, sizeof(sMainPath), "logs/populationtrackerv2/%s", sMainPath);
	BuildPath(Path_SM, sumpath, sizeof(sumpath), "logs/populationtrackerv2/%s", sumpath);
	BuildPath(Path_SM, cleanlogs, sizeof(cleanlogs), "logs/populationtrackerv2/cleanlogs.log");
}

public OnPluginEnd()
{
	//handle mid round population timer
	if(hTimer_Monitor != INVALID_HANDLE && CloseHandle(hTimer_Monitor))
		hTimer_Monitor = INVALID_HANDLE;
		
	//handle spawn timer
	if(hSpawnTimer_Monitor != INVALID_HANDLE && CloseHandle(hSpawnTimer_Monitor))
		hSpawnTimer_Monitor = INVALID_HANDLE;
		
	//handle start population timer
	if(hStartTimer_Monitor != INVALID_HANDLE && CloseHandle(hStartTimer_Monitor))
		hStartTimer_Monitor = INVALID_HANDLE;
}

public OnMapStart()
{
	if(!iEnabled)
		return;

	//rebuild main path with current date
	FormatTime(sMainPath, sizeof(sMainPath), "pt_%m-%d.log"); 
	BuildPath(Path_SM, sMainPath, sizeof(sMainPath), "logs/populationtrackerv2/%s", sMainPath);
	
	//rebuild popsummary path with current date
	FormatTime(sumpath, sizeof(sumpath), "mappopsummary_%m-%d.log");
	BuildPath(Path_SM, sumpath, sizeof(sumpath), "logs/populationtrackerv2/%s", sumpath);
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	
	//mid round population timer
	new Float:Time = float(GetConVarInt(hMidRoundPopTimer));
	hTimer_Monitor = CreateTimer(Time, Timer_Monitor, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	//start population timer
	if(iEnableStartLastPop)
	{
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "startpoptimer triggered");
			LogToFileEx(sDebugPath, "");
		}
		
		new Float:StartTime = float(GetConVarInt(hStartPopTimer));
		hStartTimer_Monitor = CreateTimer(StartTime, StartTimer_Monitor, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	//timer for logging spawns
	if(iEnableSpawns)
	{
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "spawntimer triggered");
			LogToFileEx(sDebugPath, "");
		}
		new Float:SpawnTime = float(GetConVarInt(hSpawnTimer));
		hSpawnTimer_Monitor = CreateTimer(SpawnTime, SpawnTimer_Monitor, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	//reset current population stats
	playersconnected = 0;
	playercountchange = 0;
	maxplayersconnected = 0;
	
	if(iEnableMainLog)
	{
		LogToFileEx(sMainPath, "===============================================================================");
		LogToFileEx(sMainPath, ">>>>>>>> Map Start >>>>>>>>: Map: %s, Previous: %s", sBuffer, g_sCurrentMap);
		LogToFileEx(sMainPath, "===============================================================================");
		LogToFileEx(sMainPath, "");
		strcopy(g_sCurrentMap, sizeof(g_sCurrentMap), sBuffer);
	}
	
	//Delete old main logs
	if (hMainLogDays != INVALID_HANDLE)
	{
		if (iMainLogDays > 0)
		{
			ClearOldMainLogs();
		}
	}
	
	//Delete old start/end pop logs
	if (hSumLogDays != INVALID_HANDLE)
	{
		if (iSumLogDays > 0)
		{
			ClearOldSumLogs();
		}
	}
}

public OnMapEnd()
{
	if(!iEnabled)
		return;
	
	Rounds();
	
	StartLastPop();
	
	Spawns();	
}

Rounds()
{
	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	
	//log rounds
	if(iEnableRounds)
	{
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "Rounds logging triggered");
			LogToFileEx(sDebugPath, "");
		}
		
		new ctscore = GetTeamScore(3);
		new tscore = GetTeamScore(2);
		new totalrounds = (ctscore + tscore);

		LogToFileEx(sMainPath, "");
		LogToFileEx(sMainPath, "___________________________________________________________________________________________________________________________________");
		LogToFileEx(sMainPath, "<<<<<<<<< Map End <<<<<<<< Map: %s, CT Wins: %i, T Wins: %i, Total Rounds: %i, Max players connected: %i, Last Player Count: %i", sBuffer, ctscore, tscore, totalrounds, maxplayersconnected, playercountlast);
	}
	else	//logging if iEnableRounds is disabled
	{
		if(iEnableMainLog)
		{
			LogToFileEx(sMainPath, "");
			LogToFileEx(sMainPath, "___________________________________________________________________________________________________________________________________");
			LogToFileEx(sMainPath, "<<<<<<<<< Map End <<<<<<<< Map: %s, Max players connected: %i, Last player count: %i", sBuffer, maxplayersconnected, playercountlast);
		}
	}
}

StartLastPop()
{
	//map start and end population file output
	if(!iEnableStartLastPop)
		return;
	
	if(iDebug)
	{
		LogToFileEx(sDebugPath, "popsummary triggered");
		LogToFileEx(sDebugPath, "");
	}
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	
	playercountchange = (playercountlast - playercountstart);

	LogToFileEx(sumpath, "-------------------------------------------------------------------------------------------------------------------------------------------------------------");
	LogToFileEx(sumpath, "Map: %s, Start Population: %i, Last Player Count: %i, Max Players Connected: %i, Change in players from start to finish: %i", sBuffer, playercountstart, playercountlast, maxplayersconnected, playercountchange);
	LogToFileEx(sumpath, "");
}

Spawns()
{
	//log if max available spawns was exceeded by player count
	if(iEnableSpawns)
	{
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "Spawn check triggered");
			LogToFileEx(sDebugPath, "");
		}
		
		if(totalspawns > 1)
		{
			if(maxplayersconnected > totalspawns)
			{
				LogToFileEx(sSpawns, "AVAILABLE SPAWNS EXCEEDED! Max players connected: %i", maxplayersconnected);
				LogToFileEx(sSpawns, "");
			
				if(iEnableMainLog)
				{
					LogToFileEx(sMainPath, "AVAILABLE SPAWNS EXCEEDED!");
					LogToFileEx(sMainPath, "___________________________________________________________________________________________________________________________________");
				}
				
				LogToFileEx(sumpath, "AVAILABLE SPAWNS EXCEEDED!");
			}
			else
			{
				if(iEnableMainLog)
				{
					LogToFileEx(sMainPath, "___________________________________________________________________________________________________________________________________");
				}
			}
		}
	
		maxspawns_ct = 0;
		maxspawns_t = 0;
		totalspawns = -1;
	}
	else
	{
		if(iEnableMainLog)
		{
			LogToFileEx(sMainPath, "___________________________________________________________________________________________________________________________________");
		}
	}
}

public OnClientAuthorized(client, const String:steamid[])
{
	if(!iEnabled || IsFakeClient(client))
		return;

	//if enabled, logs client connects
	if(iEnableConnections)
	{
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "Player connect triggered");
			LogToFileEx(sDebugPath, "");
		}
		g_bAuthed[client] = true;
		strcopy(g_sAuth[client], sizeof(g_sAuth[]), steamid);
		LogToFileEx(sMainPath, "Player Connected - Steam: %s, Name: %N", g_sAuth[client], client);
		LogToFileEx(sMainPath, "");
	}
	
	playersconnected++;
	if(playersconnected> maxplayersconnected)
	{
		maxplayersconnected = playersconnected;
	}
}

public OnClientDisconnect(client)
{
	if(!iEnabled || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	//if enabled, logs client disconnects
	if(iEnableConnections)
	{
		if(g_bAuthed[client])
		{
			if(iDebug)
			{
				LogToFileEx(sDebugPath, "Player disconnect triggered");
				LogToFileEx(sDebugPath, "");
			}
			LogToFileEx(sMainPath, "Player Disconnect - Steam: %s, Name: %N", g_sAuth[client], client);
			LogToFileEx(sMainPath, "");
			g_sAuth[client][0] = '\0';
		}
	}
	playersconnected--;
}

public Action:Timer_Monitor(Handle:timer)
{
	if(!iEnabled)
	{
		hTimer_Monitor = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	
	new playercountpop = 0;
	
	if(iEnableMidRoundPop)
	{
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "Repeat population logging triggered");
			LogToFileEx(sDebugPath, "");
		}
		LogToFileEx(sMainPath, "");
		LogToFileEx(sMainPath, "---------------------------------------------------------------------------------------");
		LogToFileEx(sMainPath, ">>>>>>>>>>>>>>> Server Population <<<<<<<<<<<<<<<<< Map: %s", sBuffer);
		LogToFileEx(sMainPath, "---------------------------------------------------------------------------------------");
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			playercountpop++;	
			if(iEnableIds)
			{
				LogToFileEx(sMainPath, "Steam: %s, Name: %N", g_sAuth[i], i);
			}
		}
	}
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			playercountpop++;
		}
	}
	
	playercountlast = playercountpop;
	
	if(iEnableMidRoundPop)
	{
		LogToFileEx(sMainPath, "Total Players: %i", playercountpop);
		LogToFileEx(sMainPath, "---------------------------------------------------------------------------------------");
	}

	return Plugin_Continue;
}

public Action:SpawnTimer_Monitor(Handle:timer)
{
	if(!iEnabled || !iEnableSpawns)
	{
		hEnableSpawns = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	//debug
	if(iDebug)
	{
		LogToFileEx(sDebugPath, "Spawn count triggered");
		LogToFileEx(sDebugPath, "");
	}
	//available spawns count
	if(iEnableSpawns)
	{
		new spawnpoint_ct = -1;
		decl String:sBuffer[PLATFORM_MAX_PATH];
		GetCurrentMap(sBuffer, sizeof(sBuffer));

		while ((spawnpoint_ct = FindEntityByClassname(spawnpoint_ct, "info_player_counterterrorist")) != -1)
		{
			if (IsValidEntity(spawnpoint_ct))
			{
				maxspawns_ct++;
			}
		}

		new spawnpoint_t = -1;
	
		while ((spawnpoint_t = FindEntityByClassname(spawnpoint_t, "info_player_terrorist")) != -1)
		{
			if (IsValidEntity(spawnpoint_t))
				{
				maxspawns_t++;
			}
		}
	
		totalspawns = (maxspawns_t + maxspawns_ct);
	
		new max_t_spawn_limit = iMaxtlimit;
		new max_ct_spawn_limit = iMaxctlimit;
	
		//logging if available spawns is less than values set by hMaxtlimit and hMaxctlimit
		if((maxspawns_t < max_t_spawn_limit) || (maxspawns_ct < max_ct_spawn_limit))
		{
			LogToFileEx(sSpawns, "-------------------------------------------------------------------------------------------------------------------------------------------------------------");
			LogToFileEx(sSpawns, "Map has too few spawn points! Map: %s", sBuffer);
			LogToFileEx(sSpawns, "");
			LogToFileEx(sSpawns, "Set to log if T/CT spawns are less than: %i/%i, T/CT spawns available: %i/%i, Total available spawns: %i", max_t_spawn_limit, max_ct_spawn_limit, maxspawns_t, maxspawns_ct, totalspawns);
			LogToFileEx(sSpawns, "");
		}
		
		if(iEnableMainLog)
		{
			LogToFileEx(sMainPath, "");
			LogToFileEx(sMainPath, "------- Map Spawns ------- Map: %s, T/CT spawns available: %i/%i, Total available spawns: %i", sBuffer, maxspawns_t, maxspawns_ct, totalspawns);
			LogToFileEx(sMainPath, "");
		}
	}
	return Plugin_Continue;
}

public Action:StartTimer_Monitor(Handle:timer)
{
	if(!iEnabled || !iEnableStartLastPop)
	{
		hStartTimer_Monitor = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	//debug
	if(iDebug)
	{
		LogToFileEx(sDebugPath, "Start count triggered");
		LogToFileEx(sDebugPath, "");
	}
	
	playercountstart = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		playercountstart++;
	}
	
	playercountlast = playercountstart;
	
	if(iEnableMainLog)
	{
		LogToFileEx(sMainPath, "Map start population set as %i players.", playercountstart);
	}
	
	return Plugin_Continue;
}

// Purge Old Log Files
ClearOldMainLogs()
{
	new String:sMainDir[PLATFORM_MAX_PATH];
	new String:buffer[256];
	new Handle:hDirectory = INVALID_HANDLE;
	new FileType:type = FileType_Unknown;
	new iDays;
	
	//debug
	if(iDebug)
	{
		LogToFileEx(sDebugPath, "ClearOldMainLogs() triggered");
		LogToFileEx(sDebugPath, "");
	}

	BuildPath(Path_SM, sMainDir, sizeof(sMainDir), "logs/populationtrackerv2");

	if ( DirExists(sMainDir) )
	{
		//debug
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "Main logs directory found for ClearOldMainLogs: %s", sMainDir);
			LogToFileEx(sDebugPath, "");
		}
		
		hDirectory = OpenDirectory(sMainDir);
		if (hDirectory != INVALID_HANDLE)
		{
			while ( ReadDirEntry(hDirectory, buffer, sizeof(buffer), type) )
			{
				if (type == FileType_File)
				{
					if (StrContains(buffer, "pt_", false) != -1)
					{
						decl String:sDelMainFile[PLATFORM_MAX_PATH];
						Format(sDelMainFile, sizeof(sDelMainFile), "%s/%s", sMainDir, buffer);
						iDays = ((GetTime() - GetFileTime(sDelMainFile, FileTime_LastChange))/86400);
						
						//debug
						if(iDebug)
						{
							LogToFileEx(sDebugPath, "Files found for ClearOldMainLogs: %s", sDelMainFile);
							LogToFileEx(sDebugPath, "");
						}
						if ( GetFileTime(sDelMainFile, FileTime_LastChange) < (GetTime() - (60 * 60 * 24 * iMainLogDays) + 30) )
						{
							DeleteFile(sDelMainFile);
							
							//debug
							if(iDebug)
							{
								LogToFileEx(sDebugPath, "Files deleted for ClearOldMainLogs: %s (%i days old)", sDelMainFile, iDays);
								LogToFileEx(sDebugPath, "");
							}
							
							LogToFileEx(cleanlogs, "Old logs cleared: %s (%i days old)", sDelMainFile, iDays);
						}
					}
				}
			}
		}
	}

	if (hDirectory != INVALID_HANDLE)
	{
		CloseHandle(hDirectory);
		hDirectory = INVALID_HANDLE;
	}
}

ClearOldSumLogs()
{
	new String:sSumPath[PLATFORM_MAX_PATH];
	new String:buffer[256];
	new Handle:hDirectory = INVALID_HANDLE;
	new FileType:type = FileType_Unknown;
	new iDays;

	//debug
	if(iDebug)
	{
		LogToFileEx(sDebugPath, "ClearOldSumLogs() triggered");
		LogToFileEx(sDebugPath, "");
	}
	
	BuildPath(Path_SM, sSumPath, sizeof(sSumPath), "logs/populationtrackerv2");

	if ( DirExists(sSumPath) )
	{
		//debug
		if(iDebug)
		{
			LogToFileEx(sDebugPath, "Summary logs directory found for ClearOldSumLogs: %s", sSumPath);
			LogToFileEx(sDebugPath, "");
		}

		hDirectory = OpenDirectory(sSumPath);
		if (hDirectory != INVALID_HANDLE)
		{
			while ( ReadDirEntry(hDirectory, buffer, sizeof(buffer), type) )
			{
				if (type == FileType_File)
				{
					if (StrContains(buffer, "mappopsummary", false) != -1)
					{
						decl String:sDelSumFile[PLATFORM_MAX_PATH];
						Format(sDelSumFile, sizeof(sDelSumFile), "%s/%s", sSumPath, buffer);
						iDays = ((GetTime() - GetFileTime(sDelSumFile, FileTime_LastChange))/86400);
						
						//debug
						if(iDebug)
						{
							LogToFileEx(sDebugPath, "Files found for ClearOldSumLogs: %s", sDelSumFile);
							LogToFileEx(sDebugPath, "");
						}
						
						if ( GetFileTime(sDelSumFile, FileTime_LastChange) < (GetTime() - (60 * 60 * 24 * iSumLogDays) + 30) )
						{
							DeleteFile(sDelSumFile);
							
							//debug
							if(iDebug)
							{
								LogToFileEx(sDebugPath, "Files deleted for ClearOldSumLogs: %s (%i days old)", sDelSumFile, iDays);
								LogToFileEx(sDebugPath, "");
							}
							
							LogToFileEx(cleanlogs, "Old logs cleared: %s (%i days old)", sDelSumFile, iDays);
						}
					}
				}
			}
		}
	}

	if (hDirectory != INVALID_HANDLE)
	{
		CloseHandle(hDirectory);
		hDirectory = INVALID_HANDLE;
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == hEnabled)
	{
		iEnabled = StringToInt(newvalue);
	}
	if(cvar == hEnableMainLog)
	{
		iEnableMainLog = StringToInt(newvalue);
	}
	if(cvar == hEnableConnections)
	{
		iEnableConnections = StringToInt(newvalue);
	}
	if(cvar == hMainLogDays)
	{
		iMainLogDays = StringToInt(newvalue);
	}
	if(cvar == hEnableIds)
	{
		iEnableIds = StringToInt(newvalue);
	}
	if(cvar == hEnableMidRoundPop)
	{
		iEnableMidRoundPop = StringToInt(newvalue);
	}
	if(cvar == hEnableSpawns)
	{
		iEnableSpawns = StringToInt(newvalue);
	}
	if(cvar == hMaxtlimit)
	{
		iMaxtlimit = StringToInt(newvalue);
	}
	if(cvar == hMaxctlimit)
	{
		iMaxctlimit = StringToInt(newvalue);
	}
	if(cvar == hEnableStartLastPop)
	{
		iEnableStartLastPop = StringToInt(newvalue);
	}
	if(cvar == hSumLogDays)
	{
		iSumLogDays = StringToInt(newvalue);
	}
	if(cvar == hEnableRounds)
	{
		iEnableRounds = StringToInt(newvalue);
	}
	if(cvar == hDebug)
	{
		iDebug = StringToInt(newvalue);
	}
}