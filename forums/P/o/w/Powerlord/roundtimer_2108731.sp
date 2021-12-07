#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.2"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;
new Handle:g_hCvarTime;
new Handle:g_hCvarCommands;
new Handle:g_hCvarHud;
new Handle:g_hCvarCenter;
new Handle:g_hCvarHudX;
new Handle:g_hCvarHudY;
new Handle:g_hTimer;
new Handle:g_hHud;

// ====[ CVAR VARIABLES ]======================================================
new g_iTime;
new bool:g_bEnabled;
new bool:g_bHud;
new bool:g_bCenter;
new Float:g_iHudX;
new Float:g_iHudY;
new String:g_strCommands[255];

// ====[ VARIABLES ]===========================================================
new g_iRemaining;
new bool:g_bArena;

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Round Timer",
	author = "ReFlexPoison",
	description = "Creates a round timer that executes commands on end",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net",
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_roundtimer_version", PLUGIN_VERSION, "Round Timer Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_roundtimer_enabled", "1", "Enable Round Timer\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarTime = CreateConVar("sm_roundtimer_time", "300", "Round timer time", _, true, 30.0);
	g_iTime = GetConVarInt(g_hCvarTime);
	HookConVarChange(g_hCvarTime, OnConVarChange);

	g_hCvarHud = CreateConVar("sm_roundtimer_hud", "1", "Enable displaying timer in hud\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bHud = GetConVarBool(g_hCvarHud);
	HookConVarChange(g_hCvarHud, OnConVarChange);

	g_hCvarCenter = CreateConVar("sm_roundtimer_center", "0", "Enable displaying timer in center text\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCenter = GetConVarBool(g_hCvarCenter);
	HookConVarChange(g_hCvarCenter, OnConVarChange);

	g_hCvarHudX = CreateConVar("sm_roundtimer_xhud", "-1", "X hud position\n-1 = Center", _, true, -1.0, true, 1.0);
	g_iHudX = GetConVarFloat(g_hCvarHudX);
	HookConVarChange(g_hCvarHudX, OnConVarChange);

	g_hCvarHudY = CreateConVar("sm_roundtimer_yhud", "0.15", "Y hud position\n-1 = Center", _, true, -1.0, true, 1.0);
	g_iHudY = GetConVarFloat(g_hCvarHudY);
	HookConVarChange(g_hCvarHudY, OnConVarChange);

	g_hCvarCommands = CreateConVar("sm_roundtimer_commands", "sm_say The round time has ended!;sm_slay @red", "Commands to run once the timer ends");
	GetConVarString(g_hCvarCommands, g_strCommands, sizeof(g_strCommands));
	HookConVarChange(g_hCvarCommands, OnConVarChange);

	AutoExecConfig(true, "plugin.roundtimer");

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	HookEventEx("teamplay_round_start", OnRoundStart);
	HookEventEx("arena_round_start", OnArenaStart);
	HookEventEx("teamplay_round_win", OnRoundEnd);

	g_hHud = CreateHudSynchronizer();
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
	{
		g_bEnabled = GetConVarBool(g_hCvarEnabled);
		if(!g_bEnabled)
			ClearTimer(g_hTimer);
	}
	if(hConvar == g_hCvarTime)
	{
		g_iTime = GetConVarInt(g_hCvarTime);
		if(g_hTimer != INVALID_HANDLE && g_iTime > 0)
			g_iRemaining = g_iTime;
	}
	if(hConvar == g_hCvarCommands)
		GetConVarString(g_hCvarCommands, g_strCommands, sizeof(g_strCommands));
	if(hConvar == g_hCvarHud)
		g_bHud = GetConVarBool(g_hCvarHud);
	if(hConvar == g_hCvarCenter)
		g_bCenter = GetConVarBool(g_hCvarCenter);
	if(hConvar == g_hCvarHudX)
		g_iHudX = GetConVarFloat(hConvar);
	if(hConvar == g_hCvarHudY)
		g_iHudY = GetConVarFloat(hConvar);
}

public OnMapStart()
{
	ClearTimer(g_hTimer);
	g_bArena = false;
	if(FindEntityByClassname(-1, "tf_logic_arena") != -1)
		g_bArena = true;
}

public Action:OnRoundStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled || g_bArena)
		return Plugin_Continue;

	ClearTimer(g_hTimer);
	if(g_iTime > 0)
	{
		g_iRemaining = g_iTime;
		g_hTimer = CreateTimer(1.0, Timer_Round, _, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

public Action:OnArenaStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled || !g_bArena)
		return Plugin_Continue;

	ClearTimer(g_hTimer);
	if(g_iTime > 0)
	{
		g_iRemaining = g_iTime;
		g_hTimer = CreateTimer(1.0, Timer_Round, _, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	ClearTimer(g_hTimer);
}

// ====[ TIMERS ]==============================================================
public Action:Timer_Round(Handle:hTimer)
{
	g_iRemaining--;

	if(g_bHud && g_hHud != INVALID_HANDLE)
	{
		SetHudTextParams(g_iHudX, g_iHudY, 1.1, 255, 255, 255, 255);
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			if(!IsFakeClient(i))
				ShowSyncHudText(i, g_hHud, "%02d:%02d", g_iRemaining / 60, g_iRemaining % 60);
		}
	}
	if(g_bCenter)
		PrintCenterTextAll("%02d:%02d", g_iRemaining / 60, g_iRemaining % 60);

	if(g_iRemaining <= 0)
	{
		ServerCommand("%s", g_strCommands);
		ClearTimer(g_hTimer);
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