#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.1.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;
new Handle:cvarTime;
new Handle:cvarCommand;
new Handle:cvarX;
new Handle:cvarY;

new Handle:g_hTimer;
new Handle:g_hHud;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;
new g_iRemaining;
new g_iPassed;
new g_iTime;
new Float:iX;
new Float:iY;
new String:strCommands[255];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Round Countdown",
	author = "ReFlexPoison",
	description = "Creates a new HUD text timer on round start. (Executes cmd on end)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net",
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_countdown_version", PLUGIN_VERSION, "Round Countdown Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD);

	cvarEnabled = CreateConVar("sm_countdown_enabled", "2", "Enable Round Countdown\n0 = Disabled\n1 = Enabled (teamplay_round_start)\n2 = Enabled (arena_round_start)", FCVAR_NONE, true, 0.0, true, 2.0);
	cvarTime = CreateConVar("sm_countdown_time", "450", "Seconds in Round Countdown", FCVAR_NONE, true, 30.0);
	cvarX = CreateConVar("sm_countdown_xloc", "-1", "X Position Value\n-1 = Center", FCVAR_NONE, true, -1.0, true, 1.0);
	cvarY = CreateConVar("sm_countdown_yloc", "0.9", "Y Position Value\n-1 = Center", FCVAR_NONE, true, -1.0, true, 1.0);
	cvarCommand = CreateConVar("sm_countdown_commands", "sm_say The round time has ended!;sm_slay @red", "Commands to run via server once countdown reaches 0.", FCVAR_NONE);

	g_iEnabled = GetConVarInt(cvarEnabled);
	g_iTime = GetConVarInt(cvarTime);
	iX = GetConVarFloat(cvarX);
	iY = GetConVarFloat(cvarY);
	GetConVarString(cvarCommand, strCommands, sizeof(strCommands));

	HookConVarChange(cvarEnabled, CVarChange);
	HookConVarChange(cvarTime, CVarChange);
	HookConVarChange(cvarCommand, CVarChange);
	HookConVarChange(cvarX, CVarChange);
	HookConVarChange(cvarY, CVarChange);

	AutoExecConfig(true, "plugin.countdown");

	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("arena_round_start", OnArenaStart);
	HookEvent("teamplay_round_win", OnRoundEnd);

	g_hHud = CreateHudSynchronizer();
	if(g_hHud == INVALID_HANDLE)
	SetFailState("HUD synchronisation is not supported by this mod.");
}

public CVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cvarEnabled)
	{
		g_iEnabled = GetConVarInt(cvarEnabled);
		if(g_iEnabled < 1)
		ClearTimer(g_hTimer);
	}
	if(hConvar == cvarTime)
	g_iTime = GetConVarInt(cvarTime);
	if(hConvar == cvarCommand)
	GetConVarString(cvarCommand, strCommands, sizeof(strCommands));
	if(hConvar == cvarX)
	iX = GetConVarFloat(hConvar);
	if(hConvar == cvarY)
	iY = GetConVarFloat(hConvar);
}

public Action:OnRoundStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(g_iEnabled != 1)
	return Plugin_Continue;

	//ClearTimer(g_hTimer);
	if(g_iTime > 0)
	{
		g_iRemaining = 0;
		g_iPassed = 0;
		g_hTimer = CreateTimer(1.0, Timer_Countdown, g_iTime, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:OnArenaStart(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(g_iEnabled != 2)
	return Plugin_Continue;

	//ClearTimer(g_hTimer);
	if(g_iTime > 0)
	{
		g_iRemaining = 0;
		g_iPassed = 0;
		g_hTimer = CreateTimer(1.0, Timer_Countdown, g_iTime, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	ClearTimer(g_hTimer);
	return Plugin_Continue;
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Countdown(Handle:timer, any:iMaxTime)
{
	if(GetConVarInt(cvarEnabled) < 1)
	return Plugin_Continue;

	g_iPassed++;

	g_iRemaining = iMaxTime - g_iPassed;
	if(g_iRemaining >= 60)
	SetHudTextParams(iX, iY, 1.1, 0, 255, 0, 255);
	if(g_iRemaining >= 10 && g_iRemaining < 60)
	SetHudTextParams(iX, iY, 1.1, 255, 255, 0, 255);
	if(g_iRemaining < 10)
	SetHudTextParams(iX, iY, 1.1, 255, 0, 0, 255);

	for(new iClient = 1; iClient <= MaxClients; iClient++) if(IsValidClient(iClient))
	{
		if(!IsFakeClient(iClient))
		ShowSyncHudText(iClient, g_hHud, "Time Remaining: %02d:%02d", g_iRemaining / 60, g_iRemaining % 60);
	}

	if(g_iRemaining <= 0)
	{
		ClearTimer(g_hTimer);
		ServerCommand("%s", strCommands);
	}
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
	return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
	return false;
	return true;
}

stock ClearTimer(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}