#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma semicolon 1

#include "stamm/globals.sp"
#include "stamm/configlib.sp"
#include "stamm/levellib.sp"
#include "stamm/sqllib.sp"
#include "stamm/pointlib.sp"
#include "stamm/clientlib.sp"
#include "stamm/nativelib.sp"
#include "stamm/panellib.sp"
#include "stamm/eventlib.sp"
#include "stamm/featurelib.sp"
#include "stamm/otherlib.sp"

public Plugin:myinfo =
{
	name = "Stamm",
	author = "Popoklopsi",
	version = g_Plugin_Version,
	description = "A powerful VIP Addon with lot of features",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	nativelib_Start();
	
	return APLRes_Success;
}

public OnPluginStart()
{
	new String:CurrentDate[20];
	FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");
	
	BuildPath(Path_SM, g_StammFolder, sizeof(g_StammFolder), "Stamm");
	CheckStammFolder();
	
	LoadTranslations("stamm.phrases");

	BuildPath(Path_SM, g_LogFile, sizeof(g_LogFile), "Stamm/logs/Stamm_Logs (%s).log", CurrentDate);
	BuildPath(Path_SM, g_DebugFile, sizeof(g_DebugFile), "Stamm/logs/Stamm_Debugs (%s).log", CurrentDate);
	
	g_points = 1;
	g_happyhouron = 0;
	Format(g_StammTag, sizeof(g_StammTag), "");
	
	RegConsoleCmd("say", clientlib_CmdSay);
	RegServerCmd("start_happyhour", otherlib_StartHappy, "Starts happy hour: start_happyhour <time> <factor>");
	RegServerCmd("stop_happyhour", otherlib_StopHappy, "Stops happy hour!");
	
	levellib_LoadLevels();
	configlib_CreateConfig();
	eventlib_Start();
	
	g_Pluginstarted = false;
}

public CheckStammFolder()
{
	new String:LogFolder[PLATFORM_MAX_PATH +1];
	new String:LanguagesFolder[PLATFORM_MAX_PATH +1];
	new String:LevelFolder[PLATFORM_MAX_PATH +1];
	
	Format(LogFolder, sizeof(LogFolder), "%s/logs", g_StammFolder);
	Format(LanguagesFolder, sizeof(LanguagesFolder), "%s/languages", g_StammFolder);
	Format(LevelFolder, sizeof(LevelFolder), "%s/levels", g_StammFolder);
	
	if (DirExists(g_StammFolder))
	{
		if (!DirExists(LogFolder)) CreateDirectory(LogFolder, 511);
		if (!DirExists(LanguagesFolder)) CreateDirectory(LanguagesFolder, 511);
		if (!DirExists(LevelFolder)) CreateDirectory(LevelFolder, 511);
	}
	else
	{
		CreateDirectory(g_StammFolder, 511);
		CreateDirectory(LogFolder, 511);
		CreateDirectory(LanguagesFolder, 511);
		CreateDirectory(LevelFolder, 511);
	}
}

public OnConfigsExecuted()
{
	configlib_LoadConfig();
	
	if (!g_Pluginstarted)
	{
		featurelib_LoadTranslations();
		if (g_createDatabase) otherlib_createDB();
		sqllib_Start();
		pointlib_Start();
		sqllib_LoadDB();
	
		panellib_Start();
		
		sqllib_ModifyTableBackwards();
	}
	
	if (g_vip_type == 3 || g_vip_type == 5 || g_vip_type == 6 ||  g_vip_type == 7) pointlib_timetimer = CreateTimer((60.0*g_time_point), pointlib_PlayerTime, _,TIMER_REPEAT);
	if (g_showpoints) pointlib_showpointer = CreateTimer(float(g_showpoints), pointlib_PointShower, _,TIMER_REPEAT);
	if (g_infotime) otherlib_inftimer = CreateTimer(g_infotime, otherlib_PlayerInfoTimer, _, TIMER_REPEAT);
	
	otherlib_PrepareFiles();
}

public OnMapEnd()
{
	if (pointlib_timetimer != INVALID_HANDLE) KillTimer(pointlib_timetimer);
	if (pointlib_showpointer != INVALID_HANDLE) KillTimer(pointlib_showpointer);
	if (otherlib_inftimer != INVALID_HANDLE) KillTimer(otherlib_inftimer);
}