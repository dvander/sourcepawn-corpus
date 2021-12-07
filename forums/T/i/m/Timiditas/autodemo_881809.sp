
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6.4"

/*
new in v1.6.4
	- removed the need of the file autodemo_changemap.cfg
		plugin will just restart the map that is currently running if sourcetv fakeclient is absent

	- new cvar: sm_autodemo_playercount - default 2
		recording is started only if this amount of REAL players are on the server
*/

new Handle:RenameTimer = INVALID_HANDLE;
new RenameCounts = 0;
new String:rc_OldName[128];
new String:rc_NewName[128];
new String:rc_OldLog[128];
new String:rc_NewLog[128];
new Handle:JoinTimers[64];
new bool:b_JoinTimers[64];

new Handle:CheckTimer = INVALID_HANDLE;
new Float:CheckTick = 120.0;
new CheckMode = 0;
new TimeToLive = 0;
//604800 seconds = 168 hours
new KBToLive = 0; //Whole filesize in kilobytes - max size is 4294967295 KB = 3,9 Therabyte
new Handle:cv_TimeToLive = INVALID_HANDLE;
new Handle:cv_KBToLive = INVALID_HANDLE;

new Handle:Listhandle;
new String:Listpath[256];
new Handle:cv_IgnoreSpecs = INVALID_HANDLE;
new Handle:cv_CheckMode = INVALID_HANDLE;
new Handle:cv_ad_enabled = INVALID_HANDLE;
new Handle:cv_CheckTick = INVALID_HANDLE;
new Handle:cv_MapChange = INVALID_HANDLE;
new Handle:cv_usefakestatus = INVALID_HANDLE;
new Handle:cv_playercount = INVALID_HANDLE;

new ad_enabled = 1;
new mapchange_done = 0;
new isRecording = 0;
new IgnoreSpectators = 1;
new gPlayercount = 2;

new String:Logfile[256];
new String:Statusfile[128];
new String:CurrentDemo[128];
new String:Filename_Format[128] = "%m-%d-%y %H.%M-*H.*M *MAP";
/*
For possible placeholders, refer to:
http://cplusplus.com/reference/clibrary/ctime/strftime/
Note that you cannot use asterisks. I use them as escape char here for map name and ending time.
For the ending time, only *H and *M are supported. They equal %H and %M
I will NOT check if you use invalid filename characters for your target platform
AFAIK, unix supports colons in filenames. Windows does not. Just stick to dots.
Spaces will be converted to underscores!
*/

new Handle:cv_FFormat = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Autodemo",
	author = "Timiditas",
	description = "Starts/stops sourceTV demorecording depending on if clients are connected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=881809#post881809"
};

public OnPluginStart() {

	CreateConVar("sm_autodemo_version", PLUGIN_VERSION, "autodemo Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cv_ad_enabled = CreateConVar("sm_autodemo_enabled", "1", "Enable/Disable the plugin");
	cv_CheckTick = CreateConVar("sm_autodemo_ttl_tick", "120.0", "Interval in seconds, that are checked for old demos that can be deleted");
	cv_CheckMode = CreateConVar("sm_autodemo_ttl_checkmode", "0", "0 = Don't delete old demos, 1 = Check on mapchange only, 2 = Check every x seconds(ttl_tick)");
	cv_IgnoreSpecs = CreateConVar("sm_autodemo_ignore_spectators", "1", "Do not record when there are only spectators");
	cv_TimeToLive = CreateConVar("sm_autodemo_ttl_hours", "0", "Hours to keep demos on disk before deletion. Default unlimited (0). Must be >=1 otherwise its unlimited.");
	cv_FFormat = CreateConVar("sm_autodemo_filename_format", "%m-%d-%y %H.%M-*H.*M *MAP", "Filename format of the demos. See configfile for description!");
	cv_KBToLive = CreateConVar("sm_autodemo_ttl_kilobyte", "0", "Max size in kilobytes of demos before the oldest gets deleted. Default unlimited (0). Must be >=51200 otherwise its unlimited. Max size is 4294967295 KB = 3,9 Therabyte");
	cv_MapChange = CreateConVar("sm_autodemo_mapchange", "1", "Do a mapchange if SourceTV absent. 0 = never, 1 = once, 2 = always");
	cv_usefakestatus = CreateConVar("sm_autodemo_fakestatus_file", "1", "Write faked output of 'status' command to a textfile with same name like demofile");
	cv_playercount = CreateConVar("sm_autodemo_playercount", "2", "Recording is started only if this amount of REAL players are on the server. Must be >0");
	
	HookConVarChange(cv_ad_enabled, SettingEnabled);
	HookConVarChange(cv_CheckTick, SettingTick);
	HookConVarChange(cv_CheckMode, SettingMode);
	HookConVarChange(cv_IgnoreSpecs, SettingSpectators);
	HookConVarChange(cv_playercount, SettingPlayers);
	HookConVarChange(cv_TimeToLive, SettingTTL);
	HookConVarChange(cv_FFormat, SettingFF);
	HookConVarChange(cv_KBToLive, SettingKB);
	HookEvent("player_team", EventPlayerTeam, EventHookMode_Post);
	BuildPath(Path_SM, Logfile, 256, "logs/autodemo_smx.log");
	Listhandle = CreateKeyValues("Demolist");
	BuildPath(Path_SM, Listpath, 256, "data/autodemo_list.txt");
	if(!FileToKeyValues(Listhandle, Listpath))
		KeyValuesToFile(Listhandle, Listpath);
	if(CheckMode == 2)
		CheckTimer = CreateTimer(120.0, TTLCheck, _, TIMER_REPEAT);
	RegConsoleCmd("sm_autodemo_query", ConsoleQuery);
	AutoExecConfig(true, "sm_autodemo");
}

public Action:ConsoleQuery(client, args)
{
	if (isRecording == 1)
		PrintToServer("autodemo.smx: Currently recording to %s", CurrentDemo);
	else
		PrintToServer("autodemo.smx: Currently not recording");
}

public OnEventShutdown()
{
	UnhookEvent("player_team", EventPlayerTeam);
	UnhookConVarChange(cv_ad_enabled, SettingEnabled);
	UnhookConVarChange(cv_CheckTick, SettingTick);
	UnhookConVarChange(cv_CheckMode, SettingMode);
	UnhookConVarChange(cv_IgnoreSpecs, SettingSpectators);
	UnhookConVarChange(cv_TimeToLive, SettingTTL);
	UnhookConVarChange(cv_FFormat, SettingFF);
	UnhookConVarChange(cv_KBToLive, SettingKB);
	if(CheckTimer != INVALID_HANDLE)
	{
		KillTimer(CheckTimer);
		CheckTimer = INVALID_HANDLE;
	}
	KvRewind(Listhandle);
	KeyValuesToFile(Listhandle, Listpath);
	CloseHandle(Listhandle);
}

public SettingKB(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new TheSize = StringToInt(newValue);
	if (TheSize < 51200)
		KBToLive = 0;
	else
		KBToLive = TheSize;
}

public SettingFF(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(strcmp(newValue, Filename_Format, false) == 1)
	{
		strcopy(Filename_Format, 128, newValue);
	}
}

public SettingTTL(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new NewHours = StringToInt(newValue);
	if (NewHours >= 1)
		TimeToLive = (NewHours*3600);
	else
		TimeToLive = 0;
}

public SettingSpectators(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IgnoreSpectators = StringToInt(newValue);
}
public SettingPlayers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	gPlayercount = StringToInt(newValue);
	if(gPlayercount < 1)
		gPlayercount = 1;
}
public SettingMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new NewMode = StringToInt(newValue);
	if(NewMode == CheckMode)
		return;
	CheckMode = NewMode;
	if(CheckTimer != INVALID_HANDLE)
	{
		KillTimer(CheckTimer);
		CheckTimer = INVALID_HANDLE;
	}
	if(CheckMode == 2)
		CheckTimer = CreateTimer(CheckTick, TTLCheck, _, TIMER_REPEAT);
}

public SettingTick(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:NewTick = StringToFloat(newValue);
	if(NewTick == 0.0)
	{
		PrintToServer("autodemo.smx: sm_autodemo_ttl_tick must be a float. Check your input!");
		LogToFile(Logfile, "autodemo.smx: sm_autodemo_ttl_tick must be a float. Check your input!");
		return;
	}
	else if(NewTick < 60.0)
	{
		PrintToServer("autodemo.smx: sm_autodemo_ttl_tick must be >= 60.0");
		LogToFile(Logfile, "autodemo.smx: sm_autodemo_ttl_tick must be >= 60.0");
		return;
	}
	if(NewTick == CheckTick)
		return;

	if(CheckTimer != INVALID_HANDLE)
	{
		KillTimer(CheckTimer);
		CheckTimer = INVALID_HANDLE;
	}
	CheckTick = NewTick;
	if(CheckMode == 2)
		CheckTimer = CreateTimer(CheckTick, TTLCheck, _, TIMER_REPEAT);
}

public SettingEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ad_enabled = StringToInt(newValue);
}

public Action:TTLCheck(Handle:timer)
{
	DemoTTLCheck();
}

public Action:RenameCheck(Handle:timer)
{
	RenameFile(rc_NewLog, rc_OldLog);
	if(RenameFile(rc_NewName, rc_OldName))
		KillTimer(RenameTimer);
	else
		RenameCounts++;
	
	if(RenameCounts >= 10)
	{
		KillTimer(RenameTimer);
		LogToFile(Logfile, "Failed to rename demofile! Old name: %s New name: %s", rc_OldName, rc_NewName);
	}
}

public OnMapStart()
{
	isRecording = 0;
	if(CheckMode == 1)
		DemoTTLCheck();
	KvRewind(Listhandle);
	KeyValuesToFile(Listhandle, Listpath);
	if (ad_enabled == 0)
		return;
	
	//make sure the sourceTV bot is connected. if the server has just been (re)started, it is absent. change map!
	//We will need a timer though, because SourceTV is not immediately available after a map has been loaded
	new MCMode = GetConVarInt(cv_MapChange);
	if (MCMode == 2 || (MCMode == 1 && mapchange_done == 0))
		CreateTimer(1.0, MapStartCheck, _, TIMER_REPEAT);
}

public Action:MapStartCheck(Handle:timer)
{
	static CheckCounter = 0;
	CheckCounter++;
	new b_TVready = TVready();
	if (b_TVready == 1)
	{
		KillTimer(timer);
		return;
	}
	if (CheckCounter >= 6)
	{
		//SourceTV absent after six seconds. Change map
		mapchange_done = 1;
		KillTimer(timer);
		new String:TheMap[PLATFORM_MAX_PATH];
		GetCurrentMap(TheMap, sizeof(TheMap));
		ServerCommand("changelevel %s", TheMap);
		//ForceChangeLevel(TheMap, "reloading map for sourcetv");
	}
}

public OnMapEnd()
{
	if((isRecording == 0) || (ad_enabled == 0))
		return;
	
	d_FinishRecording();
	//This is a must! Otherwise the demo will just stop, not being renamed properly and won't go into the keyvalues file.
}

public EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (ad_enabled == 0)
		return;
	if (TVready() == 0)
		return;
	new b_Humansleft = Humansleft();
	
	if((b_Humansleft >= gPlayercount) && (isRecording == 0))
		d_SetFileName();
	else if((b_Humansleft < gPlayercount) && (isRecording == 1))
		d_FinishRecording();
}

public OnClientPutInServer(client)
{
	if(ad_enabled == 0 || IsFakeClient(client))
		return;

	JoinTimers[client] = CreateTimer(20.0, AutoSBTimer, client);
	b_JoinTimers[client] = true;
}

public OnClientDisconnect_Post(client)
{
	if(ad_enabled == 0)
		return;

	if (b_JoinTimers[client] == true)
	{
		KillTimer(JoinTimers[client]);
		b_JoinTimers[client] = false;
	}
}

public Action:AutoSBTimer(Handle:timer, any:Player)
{
	b_JoinTimers[Player] = false;
	if(isRecording == 0)
		return;
	new Handle:Checks[3] = {INVALID_HANDLE,...};
	new sb_found = true;
	Checks[0] = FindConVar("sb_action");
	Checks[1] = FindConVar("sb_advert");
	Checks[2] = FindConVar("sb_autoupdate");
	for(new i=0;i<3;i++)
	{
		if(Checks[i] == INVALID_HANDLE)
		{
			sb_found = false;
		}
		else
			CloseHandle(Checks[i]);
	}
	if(sb_found)
	{
		ServerCommand("sb_status");
		//PrintToChatAll("SteamBans plugin detected! Firing sb_status...");
	}
	//The legacy 'status' command does NOT get recorded into the demo. We need a replacement
	if(GetConVarInt(cv_usefakestatus) == 1)
		FakeStatus();
}

d_FinishRecording()
{
	ServerCommand("tv_stoprecord");
	isRecording = 0;
	PrintToServer("autodemo.smx: Stopped demo recording");
	new String:FinishName[128];
	new String:TheName[128];
	new Occurences_H = 0;
	new Occurences_M = 0;
	strcopy(FinishName, 128, CurrentDemo);
	Occurences_H = ReplaceString(FinishName, 128, "-HEND-", "%H", true);
	Occurences_M = ReplaceString(FinishName, 128, "-MEND-", "%M", true);
	if((Occurences_H > 0) || (Occurences_M > 0))
	{
		FormatTime(TheName, 128, FinishName);
		strcopy(rc_OldLog, 128, Statusfile);
		strcopy(rc_NewLog, 128, TheName);
		ReplaceString(rc_NewLog, 128, ".dem", ".log", false);
		RenameFile(rc_NewLog, rc_OldLog);
		if(!RenameFile(TheName, CurrentDemo))
		{
			//wait till file is fully released
			strcopy(rc_OldName, 128, CurrentDemo);
			strcopy(rc_NewName, 128, TheName);
			RenameCounts = 0;
			RenameTimer = CreateTimer(1.0, RenameCheck, _, TIMER_REPEAT);
		}
		strcopy(CurrentDemo, 128, TheName);
	}
	if((TimeToLive == 0 && KBToLive == 0) || CheckMode < 1)
		return;
	
	KvRewind(Listhandle);
	if(KvJumpToKey(Listhandle, CurrentDemo))
	{
		//For any reason, this entry already exists. Update TTL
		KvSetNum(Listhandle, "timestamp", GetTime());
		KvSetNum(Listhandle, "filesize", FileSize(CurrentDemo));
	}
	else
	{
		KvJumpToKey(Listhandle, CurrentDemo, true);
		KvSetNum(Listhandle, "timestamp", GetTime());
		KvSetNum(Listhandle, "filesize", FileSize(CurrentDemo));
	}
	KvRewind(Listhandle);
	KeyValuesToFile(Listhandle, Listpath);
}

d_SetFileName()
{
	new String:MapName[96];
	new String:TimeFormat[128];
	new String:s_Buffer[128];
	strcopy(TimeFormat, 128, Filename_Format);
	GetCurrentMap(MapName, 96);
	ReplaceString(TimeFormat, 128, "*MAP", MapName, false);
	ReplaceString(TimeFormat, 128, "*H", "-HEND-", true);
	ReplaceString(TimeFormat, 128, "*M", "-MEND-", true);
	ReplaceString(TimeFormat, 128, " ", "_", false);
	FormatTime(s_Buffer, 128, TimeFormat);
	Format(CurrentDemo, 128, "%s%s", s_Buffer, ".dem");
	new String:ExecuteRec[142];
	Format(ExecuteRec, 142, "%s %s", "tv_record", CurrentDemo);
	strcopy(Statusfile, 128, CurrentDemo);
	ReplaceString(Statusfile, 128, ".dem", ".log", false);
	ServerCommand(ExecuteRec);
	isRecording = 1;
	PrintToServer("autodemo.smx: Started recording demo to %s", CurrentDemo);
}

TVready()
{
	new Players = GetMaxClients();
	new Handle:TVName = FindConVar("tv_name");
	new String:s_TVName[66];
	GetConVarString(TVName, s_TVName, 66);
	new String:s_Buffer[66];
	new bool:sTVfound = false;
	
	for (new i = 1; ((i <= Players) && (sTVfound == false)); i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i))
		{
			//The sourceTV bot IS a fake client. Now check its name
			GetClientName(i, s_Buffer, 66);
			if(strcmp(s_TVName, s_Buffer, false) == 0)
			{
				//This is the sTV bot
				sTVfound = true;
				break;
			}
		}
	}
	if (sTVfound == true)
		return 1;
	else
		return 0;
}

Humansleft()
{
	new h_ingame = 0;
	new Players = GetMaxClients();
	
	for (new i = 1; i <= Players; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			new cTeam = GetClientTeam(i);
			if((IgnoreSpectators == 1) && ((cTeam < 2) || (cTeam > 3)))
			{
				continue;
			}
			else
			{
				h_ingame = 1;
				break;
			}
		}
	}
	if (h_ingame == 1)
		return 1;
	else
		return 0;
}

DemoTTLCheck()
{
	if(TimeToLive == 0 && KBToLive == 0)
		return;
	KvRewind(Listhandle);
	if(KvGotoFirstSubKey(Listhandle))
	{
		new String:strBuffer[128];
		new String:logBuffer[128];
		new Age; // ;-)
		new f_size;
		new kb_size; //cumulative size of demos
		new String:oldestFile[128];
		new i_oldestFile = 0;
		do
		{
			KvGetSectionName(Listhandle, strBuffer, 128);
			Age = (GetTime() - KvGetNum(Listhandle, "timestamp"));
			f_size = KvGetNum(Listhandle, "filesize");
			if ((Age > TimeToLive) && TimeToLive > 0)
			{
				KvDeleteKey(Listhandle, "timestamp");
				f_size = 0;
				if(FileExists(strBuffer))
				{
					if(DeleteFile(strBuffer))
					{
						PrintToServer("autodemo.smx: TTL expired for %s - file has been deleted", strBuffer);
					}
					else
					{
						PrintToServer("autodemo.smx: Warning! TTL expired for %s - Deletion failed. Propably no access rights", strBuffer);
						LogToFile(Logfile, "autodemo.smx: Warning! TTL expired for %s - Deletion failed. Propably no access rights", strBuffer);
					}
					strcopy(logBuffer, 128, strBuffer);
					ReplaceString(logBuffer, 128, ".dem", ".log", false);
					if(FileExists(logBuffer))
						DeleteFile(logBuffer);
				}
				else
				{
					PrintToServer("autodemo.smx: Warning! TTL expired for %s - FILE NOT FOUND", strBuffer);
					LogToFile(Logfile, "autodemo.smx: Warning! TTL expired for %s - FILE NOT FOUND", strBuffer);
				}
			}
			if (f_size > 0)
			{
				kb_size += (f_size / 1024);
				if (Age > i_oldestFile)
				{
					i_oldestFile = Age;
					strcopy(oldestFile, 128, strBuffer);
				}
			}
		}
		while (KvGotoNextKey(Listhandle));
		if((KBToLive > 0) && (kb_size > KBToLive))
		{
			KvRewind(Listhandle);
			KvJumpToKey(Listhandle, oldestFile);
			KvDeleteKey(Listhandle, "timestamp");
			if(FileExists(oldestFile))
			{
				if(DeleteFile(oldestFile))
				{
					PrintToServer("autodemo.smx: Demosize exceeded for %s - file has been deleted", oldestFile);
				}
				else
				{
					PrintToServer("autodemo.smx: Warning! Demosize exceeded for %s - Deletion failed. Propably no access rights", oldestFile);
					LogToFile(Logfile, "autodemo.smx: Warning! Demosize exceeded for %s - Deletion failed. Propably no access rights", oldestFile);
				}
				strcopy(logBuffer, 128, oldestFile);
				ReplaceString(logBuffer, 128, ".dem", ".log", false);
				if(FileExists(logBuffer))
					DeleteFile(logBuffer);
			}
			else
			{
				PrintToServer("autodemo.smx: Warning! Demosize exceeded for %s - FILE NOT FOUND", strBuffer);
				PrintToServer(Logfile, "autodemo.smx: Warning! Demosize exceeded for %s - FILE NOT FOUND", strBuffer);
			}
		}
	}
	else
	{
		PrintToServer("autodemo.smx: data/autodemo_list.txt contains no or invalid data");
		LogToFile(Logfile, "autodemo.smx: data/autodemo_list.txt contains no or invalid data");
		return;
	}

	KvRewind(Listhandle);
	KvGotoFirstSubKey(Listhandle);
	new String:s_Compare[24];
	for(;;)
	{
		KvGetString(Listhandle, "timestamp", s_Compare, 24, "DELETED");
		if(strcmp(s_Compare, "DELETED", false) == 0)
		{
			if(KvDeleteThis(Listhandle) < 1)
			{
				break;
			}
		}
		else if(!KvGotoNextKey(Listhandle))
		{
			break;
		}
	}
}

FakeStatus()
{
	//The 'status' command does NOT get recorded into the demo. We need a replacement
	new String:s_buffer[256];
	new String:s_buffer2[256];
	new String:s_buffer3[256];
	new Handle:h_buffer;
	
	LogToFile(Statusfile, "STATUS");
	h_buffer = FindConVar("hostname");
	GetConVarString(h_buffer,s_buffer, 256);
	CloseHandle(h_buffer);
	LogToFile(Statusfile, "hostname: %s", s_buffer);
	
	LogToFile(Statusfile, "version : Unavailable");
	
	h_buffer = FindConVar("hostip");
	GetConVarString(h_buffer,s_buffer, 256);
	CloseHandle(h_buffer);
	h_buffer = FindConVar("hostport");
	GetConVarString(h_buffer,s_buffer2, 256);
	CloseHandle(h_buffer);
	LogToFile(Statusfile, "udp/ip  : %s:%s", s_buffer, s_buffer2);
	
	GetCurrentMap(s_buffer, 256);
	LogToFile(Statusfile, "map     : %s", s_buffer);
	
	h_buffer = FindConVar("tv_port");
	GetConVarString(h_buffer,s_buffer,256);
	CloseHandle(h_buffer);
	h_buffer = FindConVar("tv_delay");
	GetConVarString(h_buffer,s_buffer2,256);
	CloseHandle(h_buffer);
	LogToFile(Statusfile, "sourcetv: port %s, delay %ss", s_buffer, s_buffer2);
	LogToFile(Statusfile, " ");
	LogToFile(Statusfile, "# userid name uniqueid connected ping loss");

	new Players = GetMaxClients();
	new UserID;
	new Float:f_Ctime;
	new Ctime;
	new i_seconds;
	new i_minutes;
	new Float:f_ping;
	new Float:f_loss;
	new i_ping;
	new i_loss;
	
	for (new i = 1; i <= Players; i++)
	{
		if(IsClientInGame(i))
		{
			UserID = GetClientUserId(i);
			GetClientName(i, s_buffer, 256);
			GetClientAuthString(i, s_buffer2, 256);
			if(!IsFakeClient(i))
			{
				f_Ctime = GetClientTime(i);
				Ctime = RoundToNearest(f_Ctime);
				i_seconds = Ctime % 60;
				i_minutes = (Ctime - i_seconds) / 60;
				Format(s_buffer3, 256, "%i:%i", i_minutes, i_seconds);
				f_ping = (GetClientAvgLatency(i, NetFlow_Outgoing) * 1000);
				i_ping = RoundToNearest(f_ping);
				f_loss = (GetClientAvgLoss(i, NetFlow_Outgoing) * 100);
				i_loss = RoundToNearest(f_loss);
				LogToFile(Statusfile, "# %i %s %s %s %i %i", UserID, s_buffer, s_buffer2, s_buffer3, i_ping, i_loss);
			}
			else
				LogToFile(Statusfile, "# %i %s %s", UserID, s_buffer, s_buffer2);
		}
	}
}
