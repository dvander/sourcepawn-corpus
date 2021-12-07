#pragma semicolon 1 

#include <sourcemod>

#define	PLUGIN_AUTHOR	"[W]atch [D]ogs"
#define PLUGIN_VERSION	"1.0"

Handle g_hCvarTime;
Handle g_hCvarExec;

Handle g_hTimer;
Handle g_hRoundTime;


public Plugin myinfo = 
{
	name = "[TF2] RoundEnd Exec", 
	author = PLUGIN_AUTHOR, 
	description = "Executes commands x seconds before round end", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=300191"
};


public void OnPluginStart()
{
	g_hCvarTime = CreateConVar("sm_rexec_time", "120", "The time in seconds before round end that plugin should execute commands", _, true, 1.0);
	g_hCvarExec = CreateConVar("sm_rexec_cmd", "sm_randomslay", "The command(s) that plugin should execute before round end ( separate with semicolon ';' )");
	
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	
	g_hRoundTime = FindConVar("mp_roundtime");
	
	AutoExecConfig(true, "RoundExec");
}

public Action Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	float iRoundTime = GetConVarFloat(g_hRoundTime) * 60;
	iRoundTime -= GetConVarFloat(g_hCvarTime);
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	g_hTimer = CreateTimer(GetConVarFloat(g_hRoundTime) * 60, Timer_ExecuteCommand, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ExecuteCommand(Handle timer)
{
	g_hTimer = INVALID_HANDLE;
	char sCMD[1024];
	GetConVarString(g_hCvarExec, sCMD, sizeof(sCMD));
	ServerCommand(sCMD);
} 