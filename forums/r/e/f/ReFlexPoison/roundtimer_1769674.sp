#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.3"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled, bool:g_bCvarEnabled;
new Handle:g_hCvarTime, g_iCvarTime;
new Handle:g_hCvarCommands, String:g_strCvarCommands[255];
new Handle:g_hCvarHud, bool:g_bCvarHud;
new Handle:g_hCvarCenter, bool:g_bCvarCenter;
new Handle:g_hCvarHudX, Float:g_iCvarHudX;
new Handle:g_hCvarHudY, Float:g_iCvarHudY;
new Handle:g_hTimerRound;
new Handle:g_hHudSync;

// ====[ VARIABLES ]===========================================================
new g_iRemaining;
new bool:g_bArena;

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Round Timer",
	author = "ReFlexPoison",
	description = "Creates a round timer that executes commands when the round ends.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net",
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_roundtimer_version", PLUGIN_VERSION, "Round Timer Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_roundtimer_enabled", "1", "Enable Round Timer\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarTime = CreateConVar("sm_roundtimer_time", "300", "Round timer time", _, true, 30.0);
	g_iCvarTime = GetConVarInt(g_hCvarTime);
	HookConVarChange(g_hCvarTime, OnConVarChange);

	g_hCvarHud = CreateConVar("sm_roundtimer_hud", "1", "Enable displaying timer in hud\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarHud = GetConVarBool(g_hCvarHud);
	HookConVarChange(g_hCvarHud, OnConVarChange);

	g_hCvarCenter = CreateConVar("sm_roundtimer_center", "0", "Enable displaying timer in center text\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarCenter = GetConVarBool(g_hCvarCenter);
	HookConVarChange(g_hCvarCenter, OnConVarChange);

	g_hCvarHudX = CreateConVar("sm_roundtimer_xhud", "-1", "X hud position\n-1 = Center", _, true, -1.0, true, 1.0);
	g_iCvarHudX = GetConVarFloat(g_hCvarHudX);
	HookConVarChange(g_hCvarHudX, OnConVarChange);

	g_hCvarHudY = CreateConVar("sm_roundtimer_yhud", "0.15", "Y hud position\n-1 = Center", _, true, -1.0, true, 1.0);
	g_iCvarHudY = GetConVarFloat(g_hCvarHudY);
	HookConVarChange(g_hCvarHudY, OnConVarChange);

	g_hCvarCommands = CreateConVar("sm_roundtimer_commands", "sm_say The round time has ended!;sm_slay @red", "Commands to run once the timer ends");
	GetConVarString(g_hCvarCommands, g_strCvarCommands, sizeof(g_strCvarCommands));
	HookConVarChange(g_hCvarCommands, OnConVarChange);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", OnArenaStart);
	HookEvent("teamplay_round_win", Event_RoundEnd);

	g_hHudSync = CreateHudSynchronizer();
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
	{
		g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
		if(!g_bCvarEnabled)
			ClearTimer(g_hTimerRound);
	}
	if(hConvar == g_hCvarTime)
	{
		g_iCvarTime = GetConVarInt(g_hCvarTime);
		if(g_hTimerRound != INVALID_HANDLE && g_iCvarTime > 0)
			g_iRemaining = g_iCvarTime;
	}
	else if(hConvar == g_hCvarCommands)
		GetConVarString(g_hCvarCommands, g_strCvarCommands, sizeof(g_strCvarCommands));
	else if(hConvar == g_hCvarHud)
		g_bCvarHud = GetConVarBool(g_hCvarHud);
	else if(hConvar == g_hCvarCenter)
		g_bCvarCenter = GetConVarBool(g_hCvarCenter);
	else if(hConvar == g_hCvarHudX)
		g_iCvarHudX = GetConVarFloat(hConvar);
	else if(hConvar == g_hCvarHudY)
		g_iCvarHudY = GetConVarFloat(hConvar);
}

public OnMapStart()
{
	ClearTimer(g_hTimerRound);
	g_bArena = false;
	if(FindEntityByClassname(-1, "tf_logic_arena") != -1)
		g_bArena = true;
}

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bCvarEnabled || g_bArena)
		return;

	ClearTimer(g_hTimerRound);
	if(g_iCvarTime > 0)
	{
		g_iRemaining = g_iCvarTime;
		g_hTimerRound = CreateTimer(1.0, Timer_Round, _, TIMER_REPEAT);
	}
}

public Action:OnArenaStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bCvarEnabled || !g_bArena)
		return;

	ClearTimer(g_hTimerRound);
	if(g_iCvarTime > 0)
	{
		g_iRemaining = g_iCvarTime;
		g_hTimerRound = CreateTimer(1.0, Timer_Round, _, TIMER_REPEAT);
	}
}

public Action:Event_RoundEnd(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	ClearTimer(g_hTimerRound);
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Round(Handle:hTimer)
{
	g_iRemaining--;

	if(g_bCvarHud && g_hHudSync != INVALID_HANDLE)
	{
		SetHudTextParams(g_iCvarHudX, g_iCvarHudY, 1.1, 255, 255, 255, 255);
		for(new i = 1; i <= MaxClients; i++) if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
				ShowSyncHudText(i, g_hHudSync, "%02d:%02d", g_iRemaining / 60, g_iRemaining % 60);
		}
	}

	if(g_bCvarCenter)
		PrintCenterTextAll("%02d:%02d", g_iRemaining / 60, g_iRemaining % 60);

	if(g_iRemaining <= 0)
	{
		ServerCommand("%s", g_strCvarCommands);
		hTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock ClearTimer(&Handle:hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}