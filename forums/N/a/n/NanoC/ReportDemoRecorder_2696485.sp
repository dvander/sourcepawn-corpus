#include <sourcemod>
#include <sdktools>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <sourcebanspp>
#include <calladmin>

bool g_bIsTVRecording = false;

char g_szLogFile[PLATFORM_MAX_PATH];

int g_iGetReportedName = -1;

ConVar g_cRDREnable;
ConVar g_cRDRPath;
ConVar g_cRDRSystem;
ConVar g_cRDRDemoName;
ConVar g_cRDRStopRecordTime;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Report Demo Recorder",
	author = "Nano",
	description = "Start recording a demo when someone is reported.",
	version = "2.6",
	url = "https://steamcommunity.com/id/nano2k06/"
};

public void OnPluginStart()
{
	g_cRDREnable = CreateConVar("sm_rdr_enable", "1", "Enable or disable the whole plugin (1 enabled | 0 disabled) - Default = 1");
	g_cRDRPath = CreateConVar("sm_rdr_path", ".", "Path to store recorded demos by CallAdmin (let . to upload demos to the cstrike/csgo folder)");
	g_cRDRSystem = CreateConVar("sm_rdr_system", "1", "Change the system to start recording demos (1 = CallAdmin | 2 = Sourceban Reports) - Default = 1");
	g_cRDRDemoName = CreateConVar("sm_rdr_name", "1", "Change the name of the demo when it's uploaded to the FTP (1 = Date & Hour | 2 = Name of reported | 3 = SteamID64 of reported) - Default = 1");
	g_cRDRStopRecordTime = CreateConVar("sm_rdr_recordtime", "0", "Time in seconds to stop recording automatically (0 = Disable [default])");
	
	AutoExecConfig(true, "ReportDemoRecorder");

	RegAdminCmd("sm_stoprecord", StopRecordCmd, ADMFLAG_BAN);
	RegAdminCmd("sm_record", StartRecordCmd, ADMFLAG_GENERIC);
	
	char sPath[PLATFORM_MAX_PATH];
	g_cRDRPath.GetString(sPath, sizeof(sPath));
	if(!DirExists(sPath))
	{
		InitDirectory(sPath);
	}
	
	g_cRDRPath.AddChangeHook(OnConVarChanged);
	g_cRDRDemoName.AddChangeHook(OnConVarChanged);
	
	BuildPath(Path_SM, g_szLogFile, sizeof(g_szLogFile), "logs/ReportDemoRecorder.log");
}

public void OnMapEnd()
{
	StopRecordDemo();
}

public Action StopRecordCmd(int client, int args)
{
	if(g_bIsTVRecording)
	{
		CPrintToChat(client, "{green}[ReportDemo]{default} You have {darkred}stopped {default}the current demo.");
		StopRecordDemo();
	}
	else
	{
		CPrintToChat(client, "{green}[ReportDemo]{default} STV it's not recording {green}at this moment.");
		EmitSoundToClient(client, "buttons/button11.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
	}
	return Plugin_Handled;
}

public Action StartRecordCmd(int client, int args)
{
	if(g_cRDRDemoName.IntValue >= 2)
	{
		CPrintToChat(client, "{green}[ReportDemo]{default} You can't record a demo using CVar {green}sm_rdr_name '2 or 3'{default}.");
		CPrintToChat(client, "{green}[ReportDemo]{default} Consider changing the {green}CVar value to 1.");
		EmitSoundToClient(client, "buttons/button11.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
		return Plugin_Handled;
	}

	if(!g_bIsTVRecording)
	{
		CPrintToChat(client, "{green}[ReportDemo]{default} STV is now {darkred}recording a demo file.");
		StartRecordingDemo();
	}
	else
	{
		CPrintToChat(client, "{green}[ReportDemo]{default} STV is already recording {green}a demo.");
		EmitSoundToClient(client, "buttons/button11.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0);
	}
	return Plugin_Handled;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char [] newValue)
{
	if(convar == g_cRDRPath)
	{
		if(!DirExists(newValue))
		{
			InitDirectory(newValue);
		}
	}
	else if(convar == g_cRDRDemoName)
	{
		CPrintToChatAll("{green}[ReportDemo]{default} Changed demo name {green}successfully.");
	}
}

public void CallAdmin_OnReportPost(int client, int target, const char[] reason)
{
	if(g_cRDRDemoName.IntValue >= 2)
	{
		g_iGetReportedName = target;
	}

	if(!g_cRDREnable.BoolValue && g_cRDRSystem.IntValue == 2)
	{
		return;
	}

	if(!g_bIsTVRecording)
	{
		StartRecordingDemo();
	}
	else
	{
		CPrintToChatAll("{green}[ReportDemo]{default} STV is {darkred}already recording a demo.");
	}
}

public void SBPP_OnReportPlayer(int iReporter, int iTarget, const char[] sReason)
{
	if(g_cRDRDemoName.IntValue >= 2)
	{
		g_iGetReportedName = iTarget;
	}

	if(!g_cRDREnable.BoolValue && g_cRDRSystem.IntValue == 1)
	{
		return;
	}

	if(!g_bIsTVRecording)
	{
		StartRecordingDemo();
	}
	else
	{
		CPrintToChatAll("{green}[ReportDemo]{default} STV is {darkred}already recording a demo.");
	}
}

void StartRecordingDemo()
{
	if(!g_cRDREnable.BoolValue)
	{
		return;
	}
	
	if(g_cRDRStopRecordTime.IntValue >= 1)
	{
		CreateTimer(g_cRDRStopRecordTime.FloatValue, Timer_Stoprecord);
	}

	char sPath[PLATFORM_MAX_PATH];
	char sAuth[MAXPLAYERS + 1][32];
	char sTime[16];
	char sMap[32];
	char sPlayerName[64];
	
	g_bIsTVRecording = true;
	g_cRDRPath.GetString(sPath, sizeof(sPath));

	GetCurrentMap(sMap, sizeof(sMap));
	ReplaceString(sMap, sizeof(sMap), "/", "-", false);	

	if(g_cRDRDemoName.IntValue == 1)
	{
		FormatTime(sTime, sizeof(sTime), "%d-%m___%H-%M", GetTime());
		ServerCommand("tv_record \"%s/report_%s_%s\"", sPath, sTime, sMap);
	}
	else if(g_cRDRDemoName.IntValue == 2)
	{
		GetClientName(g_iGetReportedName, sPlayerName, sizeof sPlayerName);
		ServerCommand("tv_record \"%s/report_%s_%s\"", sPath, sPlayerName, sMap);
	}
	else if(g_cRDRDemoName.IntValue == 3)
	{
		GetClientAuthId(g_iGetReportedName, AuthId_SteamID64, sAuth[g_iGetReportedName], sizeof(sAuth));
		ServerCommand("tv_record \"%s/report_%s_%s\"", sPath, sAuth[g_iGetReportedName], sMap);
	}
	
	CPrintToChatAll("{green}[ReportDemo]{default} SourceTV started recording due a player's report.");
}

void StopRecordDemo()
{
	if(!g_cRDREnable.BoolValue){
		return;
	}

	if(g_bIsTVRecording){
		ServerCommand("tv_stoprecord");
		g_bIsTVRecording = false;
		if(g_cRDRDemoName.IntValue >= 2){
			g_iGetReportedName = -1;
		}
	}
}

public Action Timer_Stoprecord(Handle timer)
{
	int time = g_cRDRStopRecordTime.IntValue;

	StopRecordDemo();
	CPrintToChatAll("{green}[ReportDemo]{default} Stopped recording demo automatically after {darkred}%d seconds.", time);
}

void InitDirectory(const char[] sDir)
{
	char sPieces[32][PLATFORM_MAX_PATH];
	char sPath[PLATFORM_MAX_PATH];
	int iNumPieces = ExplodeString(sDir, "/", sPieces, sizeof(sPieces), sizeof(sPieces[]));

	for(int i = 0; i < iNumPieces; i++)
	{
		Format(sPath, sizeof(sPath), "%s/%s", sPath, sPieces[i]);
		if(!DirExists(sPath))
		{
			CreateDirectory(sPath, 509);
		}
	}
}