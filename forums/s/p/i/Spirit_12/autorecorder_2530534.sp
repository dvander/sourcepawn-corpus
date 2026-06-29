/*
* 
* Auto Recorder
* http://forums.alliedmods.net/showthread.php?t=92072
* 
* Description:
* Automates SourceTV recording based on player count
* and time of day. Also allows admins to manually record.
* 
* Changelog
* May 09, 2009 - v.1.0.0:
* 				[*] Initial Release
* May 11, 2009 - v.1.1.0:
* 				[+] Added path cvar to control where demos are stored
* 				[*] Changed manual recording to override automatic recording
* 				[+] Added seconds to demo names
* May 04, 2016 - v.1.1.1:
*               [*] Changed demo file names to replace slashes with hyphens [ajmadsen]
* Aug 26, 2016 - v.1.2.0:
* 				[*] Now ignores bots in the player count by default
* 				[*] The SourceTV client is now always ignored in the player count
* 				[+] Added sm_autorecord_ignorebots to control whether to ignore bots
* 				[*] Now checks the status of the server immediately when a setting is changed
* 
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.2.0"

new Handle:g_hTvEnabled = INVALID_HANDLE;
new Handle:g_hAutoRecord = INVALID_HANDLE;
new Handle:g_hMinPlayersStart = INVALID_HANDLE;
new Handle:g_hIgnoreBots = INVALID_HANDLE;
new Handle:g_hTimeStart = INVALID_HANDLE;
new Handle:g_hTimeStop = INVALID_HANDLE;
new Handle:g_hFinishMap = INVALID_HANDLE;
new Handle:g_hDemoPath = INVALID_HANDLE;

new bool:g_bIsRecording = false;
new bool:g_bIsManual = false;

public Plugin:myinfo = 
{
	name = "Auto Recorder",
	author = "Stevo.TVR",
	description = "Automates SourceTV recording based on player count and time of day.",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_autorecord_version", PLUGIN_VERSION, "Auto Recorder plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAutoRecord = CreateConVar("sm_autorecord_enable", "1", "Enable automatic recording", _, true, 0.0, true, 1.0);
	g_hMinPlayersStart = CreateConVar("sm_autorecord_minplayers", "4", "Minimum players on server to start recording", _, true, 0.0);
	g_hIgnoreBots = CreateConVar("sm_autorecord_ignorebots", "1", "Ignore bots in the player count", _, true, 0.0, true, 1.0);
	g_hTimeStart = CreateConVar("sm_autorecord_timestart", "-1", "Hour in the day to start recording (0-23, -1 disables)");
	g_hTimeStop = CreateConVar("sm_autorecord_timestop", "-1", "Hour in the day to stop recording (0-23, -1 disables)");
	g_hFinishMap = CreateConVar("sm_autorecord_finishmap", "1", "If 1, continue recording until the map ends", _, true, 0.0, true, 1.0);
	g_hDemoPath = CreateConVar("sm_autorecord_path", ".", "Path to store recorded demos");
	
	AutoExecConfig(true, "autorecorder");
	
	RegAdminCmd("sm_record", Command_Record, ADMFLAG_KICK, "Starts a SourceTV demo");
	RegAdminCmd("sm_stoprecord", Command_StopRecord, ADMFLAG_KICK, "Stops the current SourceTV demo");
	
	g_hTvEnabled = FindConVar("tv_enable");
	
	decl String:sPath[PLATFORM_MAX_PATH];
	GetConVarString(g_hDemoPath, sPath, sizeof(sPath));
	if(!DirExists(sPath))
	{
		InitDirectory(sPath);
	}
	
	HookConVarChange(g_hMinPlayersStart, OnConVarChanged);
	HookConVarChange(g_hIgnoreBots, OnConVarChanged);
	HookConVarChange(g_hTimeStart, OnConVarChanged);
	HookConVarChange(g_hTimeStop, OnConVarChanged);
	HookConVarChange(g_hDemoPath, OnConVarChanged);
	
	CreateTimer(300.0, Timer_CheckStatus, _, TIMER_REPEAT);
	
	StopRecord();
	CheckStatus();
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hDemoPath)
	{
		if(!DirExists(newValue))
		{
			InitDirectory(newValue);
		}
	}
	else
	{
		CheckStatus();
	}
}

public OnMapEnd()
{
	if(g_bIsRecording)
	{
		StopRecord();
		g_bIsManual = false;
	}
}

public OnClientPutInServer(client)
{
	CheckStatus();
}

public OnClientDisconnect_Post(client)
{
	CheckStatus();
}

public Action:Timer_CheckStatus(Handle:Timer)
{
	CheckStatus();
}

public Action:Command_Record(client, args)
{
	if(g_bIsRecording)
	{
		ReplyToCommand(client, "[SM] SourceTV is already recording!");
		return Plugin_Handled;
	}
	
	StartRecord();
	g_bIsManual = true;
	
	ReplyToCommand(client, "[SM] SourceTV is now recording...");
	
	return Plugin_Handled;
}

public Action:Command_StopRecord(client, args)
{
	if(!g_bIsRecording)
	{
		ReplyToCommand(client, "[SM] SourceTV is not recording!");
		return Plugin_Handled;
	}
	
	StopRecord();
	
	if(g_bIsManual)
	{
		g_bIsManual = false;
		CheckStatus();
	}
	
	ReplyToCommand(client, "[SM] Stopped recording.");
	
	return Plugin_Handled;
}

public CheckStatus()
{
	if(GetConVarBool(g_hAutoRecord) && !g_bIsManual)
	{
		new iMinClients = GetConVarInt(g_hMinPlayersStart);
		
		new iTimeStart = GetConVarInt(g_hTimeStart);
		new iTimeStop = GetConVarInt(g_hTimeStop);
		new bool:bReverseTimes = (iTimeStart > iTimeStop);
		
		decl String:sCurrentTime[4];
		FormatTime(sCurrentTime, sizeof(sCurrentTime), "%H", GetTime());
		new iCurrentTime = StringToInt(sCurrentTime);
		
		if(GetPlayerCount() >= iMinClients+1 && (iTimeStart < 0 || (iCurrentTime >= iTimeStart && (bReverseTimes || iCurrentTime < iTimeStop))))
		{
			StartRecord();
		}
		else if(g_bIsRecording && !GetConVarBool(g_hFinishMap) && (iTimeStop < 0 || iCurrentTime >= iTimeStop))
		{
			StopRecord();
		}
	}
}

public GetPlayerCount()
{
	if(!GetConVarBool(g_hIgnoreBots))
	{
		return GetClientCount(false)-1;
	}

	new iNumPlayers = 0;
	for(new i = i; i < MaxClients; i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			iNumPlayers++;
		}
	}

	return iNumPlayers;
}

public StartRecord()
{
	if(GetConVarBool(g_hTvEnabled) && !g_bIsRecording)
	{
		decl String:sPath[PLATFORM_MAX_PATH], String:sTime[16], String:sMap[32];
		
		GetConVarString(g_hDemoPath, sPath, sizeof(sPath));
		FormatTime(sTime, sizeof(sTime), "%Y%m%d-%H%M%S", GetTime());
		GetCurrentMap(sMap, sizeof(sMap));
		
		// replace slashes in map path name with dashes, to prevent fail on workshop maps
		ReplaceString(sMap, sizeof(sMap), "/", "-", false);		
		
		ServerCommand("tv_record \"%s/auto-%s-%s\"", sPath, sTime, sMap);
		g_bIsRecording = true;
		
		LogMessage("Recording to auto-%s-%s.dem", sTime, sMap);
	}
}

public StopRecord()
{
	if(GetConVarBool(g_hTvEnabled))
	{
		ServerCommand("tv_stoprecord");
		g_bIsRecording = false;
	}
}

public InitDirectory(const String:sDir[])
{
	decl String:sPieces[32][PLATFORM_MAX_PATH];
	new String:sPath[PLATFORM_MAX_PATH];
	new iNumPieces = ExplodeString(sDir, "/", sPieces, sizeof(sPieces), sizeof(sPieces[]));
	
	for(new i = 0; i < iNumPieces; i++)
	{
		Format(sPath, sizeof(sPath), "%s/%s", sPath, sPieces[i]);
		if(!DirExists(sPath))
		{
			CreateDirectory(sPath, 509);
		}
	}
}