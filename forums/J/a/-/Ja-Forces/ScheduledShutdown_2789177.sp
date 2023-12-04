/* 
* 	Scheduled Shutdown/Restart
* 	By [BR5DY]
* 
*	This plugin could not have been made without the help of MikeJS's plugin and darklord1474's plugin.
* 
* 	Automatically shuts down the server at the specified time, warning all players ahead of time.
*	Will restart automatically if you run some type of server checker or batch script :-)
* 
* 	Very basic commands - it issues the "_restart" command to SRCDS at the specified time
* 
*   Cvars:
*	sm_scheduledshutdown_hintsay 1		// Sets whether messages are shown in the hint area
*	sm_scheduledshutdown_chatsay  1		// Sets whether messages are shown in chat
*	sm_scheduledshutdown_centersay 1	// Sets whether messages are shown in the center of the screen
*	sm_scheduledshutdown_time 05:00		// Sets the time to shutdown the server
*/

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS	FCVAR_NOTIFY

ConVar g_hEnabledHint = null;
ConVar g_hEnabledChat = null;
ConVar g_hEnabledCenter = null;
ConVar g_hEnabled = null;
ConVar g_hTime = null;

bool g_bEnabledHint;
bool g_bEnabledChat;
bool g_bEnabledCenter;
bool g_bEnabled;
int g_iTime;

Handle h_ShutdownTimer;

public Plugin myinfo = 
{
	name = "ScheduledShutdown",
	author = "BR5DY, Dosergen",
	description = "Shutsdown SRCDS (with options). Special thanks to MikeJS and darklord1474.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=161932"
};

public void OnPluginStart() 
{
	PrintToServer("ScheduledShutdown loaded successfully.");
	
	CreateConVar("sm_scheduledshutdown_version", PLUGIN_VERSION, "ScheduledShutdown version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabledHint = CreateConVar("sm_scheduledshutdown_hintsay", "1", "Sets whether messages are shown in the hint area", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hEnabledChat = CreateConVar("sm_scheduledshutdown_chatsay", "1", "Sets whether messages are shown in chat", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hEnabledCenter = CreateConVar("sm_scheduledshutdown_centersay", "1", "Sets whether messages are shown in the center of the screen", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hEnabled = CreateConVar("sm_scheduledshutdown", "1", "Enable ScheduledShutdown.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hTime = CreateConVar("sm_scheduledshutdown_time", "05:00", "Time to shutdown server.", CVAR_FLAGS);
	
	AutoExecConfig(true, "ScheduledShutdown");
	
	GetCvars();
	
	g_hEnabledHint.AddChangeHook(ConVarChanged_Cvars);
	g_hEnabledChat.AddChangeHook(ConVarChanged_Cvars);
	g_hEnabledCenter.AddChangeHook(ConVarChanged_Cvars);
	g_hEnabled.AddChangeHook(ConVarChanged_Cvars);
	g_hTime.AddChangeHook(ConVarChanged_Cvars);
}

public void OnConfigsExecuted()
{
	GetCvars();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	char iTime[8];
	GetConVarString(g_hTime, iTime, sizeof(iTime));
	g_iTime = StringToInt(iTime);
	
	g_bEnabledHint = g_hEnabledHint.BoolValue;
	g_bEnabledChat = g_hEnabledChat.BoolValue;
	g_bEnabledCenter = g_hEnabledCenter.BoolValue;
	g_bEnabled = g_hEnabled.BoolValue;
}

public void OnMapStart()
{
	CreateTimer(60.0, CheckTime, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckTime(Handle timer, any useless)
{
	if (g_bEnabled)
	{
		int gettime = GetTime();

		char strtime[8];
		FormatTime(strtime, sizeof(strtime), "%H:%M", gettime);
		gettime -= (StringToInt(strtime) / 100) * 3600;
		
		int time = StringToInt(strtime);
		if (time >= g_iTime && time <= g_iTime)
		{
			if (g_bEnabledHint)
			{
				PrintHintTextToAll("Restarting server in 15 seconds ...");
			}
			
			if (g_bEnabledChat)
			{
				PrintToChatAll("Restarting server in 15 seconds ...");
			}
			
			if (g_bEnabledCenter)
			{
				PrintCenterTextAll("Restarting server in 15 seconds ...");
			}

			LogAction(0, -1, "Server shutdown warning.");
			h_ShutdownTimer = CreateTimer(15.0, ShutItDown, _, TIMER_REPEAT);
		}
	}
	
	return Plugin_Stop;
}

public Action ShutItDown(Handle timer)
{
	LogAction(0, -1, "Server shutdown.");
	ServerCommand("_restart");
	
	KillTimer(h_ShutdownTimer);
	h_ShutdownTimer = null;
	return Plugin_Stop;
}