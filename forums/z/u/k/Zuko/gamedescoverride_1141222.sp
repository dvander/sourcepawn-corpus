#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define NAME "Game Description Override"
#define VERSION "1.3"
#define DEBUG "0"

new String:g_szGameDesc[64] = "";
new Handle:g_hCvarGameDesc = INVALID_HANDLE;
new Handle:g_hCvarTimerTime = INVALID_HANDLE;
new Handle:g_hTimerAutoChange = INVALID_HANDLE;
new bool:g_bChangeGameDesc = false;
new currLine = 0;

public Plugin:myinfo = {
	name = NAME,
	author = "psychonic (modified by Zuko and Luki)",
	description = "Allows changing of displayed game type in server browser",
	version = VERSION,
	url = "http://www.nicholashastings.com | http://HLDS.pl | www.strefagier.com.pl"
};

public OnPluginStart()
{
	CreateConVar("gamedesc_override_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hCvarGameDesc = CreateConVar("gamedesc_override", "", "Game Description Override (set blank \"\" for default no override)", FCVAR_PLUGIN);
	g_hCvarTimerTime = CreateConVar("gamedesc_auto_change_time", "240.0", "How often description has to be changed. (in seconds, 0 - to disable)", FCVAR_PLUGIN);
	
	AutoExecConfig();

	HookConVarChange(g_hCvarGameDesc, CvarChange_GameDesc);
	HookConVarChange(g_hCvarTimerTime, CvarChange_TimerTime);
}

public OnMapStart()
{
	if (GetConVarInt(g_hCvarTimerTime) > 0)
	{
		g_hTimerAutoChange = CreateTimer(GetConVarFloat(g_hCvarTimerTime), timerProc, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		currLine = 0;
	}
}

public OnAllPluginsLoaded()
{
	if (GetExtensionFileStatus("sdkhooks.ext") != 1)
	{
		SDKHooksFail();
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "sdkhooks.ext") == 0)
	{
		SDKHooksFail();
	}
}

SDKHooksFail()
{
	SetFailState("SDKHooks is required for Game Description Override");
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (g_bChangeGameDesc)
	{
		strcopy(gameDesc, sizeof(gameDesc), g_szGameDesc);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:timerProc(Handle:timer)
{
	#if defined DEBUG
		PrintToServer("Timer Executed");
	#endif
	new String:sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "configs/gamedesc.txt");
	new Handle:Descs = CreateArray(255, 0);
	new Handle:File = OpenFile(sFilePath, "r");
	while (!IsEndOfFile(File))
	{
		new String:buffer[255];
		ReadFileLine(File, buffer, sizeof(buffer));
		ResizeArray(Descs, GetArraySize(Descs));
		PushArrayString(Descs, buffer);
	}
	
	new String:buff[255];
	GetArrayString(Descs, currLine, buff, sizeof(buff));
	currLine++;
	if (currLine >= GetArraySize(Descs))
	{
		currLine = 0;
	}
	SetConVarString(g_hCvarGameDesc, buff, true);
	strcopy(g_szGameDesc, sizeof(g_szGameDesc), buff);
	CloseHandle(Descs);
	CloseHandle(File);
}

public CvarChange_GameDesc(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_szGameDesc, sizeof(g_szGameDesc), newVal);
	if (newVal[0] > 0)
	{
		g_bChangeGameDesc = true;
	}
	else
	{
		g_bChangeGameDesc = false;
	}
}

public CvarChange_TimerTime(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	#if defined DEBUG
		PrintToServer("CvarChange_TimerTime Change Hook");
	#endif
	
	if (g_hTimerAutoChange != INVALID_HANDLE)
	{
		KillTimer(g_hTimerAutoChange);
		g_hTimerAutoChange = INVALID_HANDLE;
	}

	g_hTimerAutoChange = CreateTimer(GetConVarFloat(g_hCvarTimerTime), timerProc, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	currLine = 0;
}
