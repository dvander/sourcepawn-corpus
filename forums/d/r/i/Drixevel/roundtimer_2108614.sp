#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <roundtimer>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.0.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:ConVars[8] = {INVALID_HANDLE, ...};

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
	ConVars[0] = CreateConVar("sm_roundtimer_version", PLUGIN_VERSION, "Round Timer Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	ConVars[1] = CreateConVar("sm_roundtimer_enabled", "1", "Enable Round Timer\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	ConVars[2] = CreateConVar("sm_roundtimer_time", "300", "Round timer time", _, true, 30.0);
	ConVars[3] = CreateConVar("sm_roundtimer_commands", "sm_say The round time has ended!;sm_slay @red", "Commands to run once the timer ends");
	ConVars[4] = CreateConVar("sm_roundtimer_hud", "1", "Enable displaying timer in hud\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	ConVars[5] = CreateConVar("sm_roundtimer_center", "0", "Enable displaying timer in center text\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	ConVars[6] = CreateConVar("sm_roundtimer_xhud", "-1", "X hud position\n-1 = Center", _, true, -1.0, true, 1.0);
	ConVars[7] = CreateConVar("sm_roundtimer_yhud", "0.15", "Y hud position\n-1 = Center", _, true, -1.0, true, 1.0);
	
	for (new i = 0; i < sizeof(ConVars); i++)
	{
		HookConVarChange(ConVars[i], HandleCvars);
	}
	
	AutoExecConfig(true, "plugin.roundtimer");

	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	
	HookEventEx("teamplay_round_start", OnRoundStart);
	HookEventEx("arena_round_start", OnArenaStart);
	HookEventEx("teamplay_round_win", OnRoundEnd);

	g_hHud = CreateHudSynchronizer();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("RoundTimer_Stop", Native_StopTimer);
	CreateNative("RoundTimer_TimeLeft", Native_TimeLeft);
	RegPluginLibrary("roundtimer");
	
	return APLRes_Success;
}

public OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(ConVars[1]);
	g_iTime = GetConVarInt(ConVars[2]);
	GetConVarString(ConVars[3], g_strCommands, sizeof(g_strCommands));
	g_bHud = GetConVarBool(ConVars[4]);
	g_bCenter = GetConVarBool(ConVars[5]);
	g_iHudX = GetConVarFloat(ConVars[6]);
	g_iHudY = GetConVarFloat(ConVars[7]);
}

public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true)) return;

	new iNewValue = StringToInt(newValue);

	if (cvar == ConVars[0])
	{
		SetConVarString(ConVars[0], PLUGIN_VERSION);
	}
	
	else if(cvar == ConVars[1])
	{
		g_bEnabled = bool:iNewValue;
		
		if (iNewValue == 0)
		{
			ClearTimer(g_hTimer);
		}
	}
	else if(cvar == ConVars[2])
	{
		g_iTime = iNewValue;
		if(g_hTimer != INVALID_HANDLE && g_iTime > 0)
		{
			g_iRemaining = g_iTime;
		}
	}
	if(cvar == ConVars[3])
	{
		GetConVarString(ConVars[3], g_strCommands, sizeof(g_strCommands));
	}
	else if(cvar == ConVars[4])
	{
		g_bHud = bool:iNewValue;
	}
	else if(cvar == ConVars[5])
	{
		g_bCenter = bool:iNewValue;
	}
	else if(cvar == ConVars[6])
	{
		g_iHudX = StringToFloat(newValue);
	}
	else if(cvar == ConVars[7])
	{
		g_iHudY = StringToFloat(newValue);
	}
}

public OnMapStart()
{
	ClearTimer(g_hTimer);
	g_bArena = false;
	if(FindEntityByClassname(-1, "tf_logic_arena") != -1)
	{
		g_bArena = true;
	}
}

public Action:OnRoundStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled || g_bArena)
	{
		return Plugin_Continue;
	}

	ClearTimer(g_hTimer);
	
	if(g_iTime > 0)
	{
		g_iRemaining = g_iTime;
		g_hTimer = CreateTimer(1.0, Timer_Round, INVALID_HANDLE, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

public Action:OnArenaStart(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	if(!g_bEnabled || !g_bArena)
	{
		return Plugin_Continue;
	}

	ClearTimer(g_hTimer);
	
	if(g_iTime > 0)
	{
		g_iRemaining = g_iTime;
		g_hTimer = CreateTimer(1.0, Timer_Round, INVALID_HANDLE, TIMER_REPEAT);
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
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				ShowSyncHudText(i, g_hHud, "%02d:%02d", g_iRemaining / 60, g_iRemaining % 60);
			}
		}
	}
	
	if(g_bCenter)
	{
		PrintCenterTextAll("%02d:%02d", g_iRemaining / 60, g_iRemaining % 60);
	}

	if(g_iRemaining <= 0)
	{
		ServerCommand("%s", g_strCommands);
		ClearTimer(g_hTimer);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return false;
	return true;
}

stock ClearTimer(&Handle:timer)
{
    if(timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}

// ====[ NATIVES ]==============================================================
public Native_StopTimer(Handle:plugin, numParams)
{
	if (!g_bEnabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin 'Round Timers' is currently disabled.");
	}
	ClearTimer(g_hTimer);
}

public Native_TimeLeft(Handle:plugin, numParams)
{
	if (!g_bEnabled)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Plugin 'Round Timers' is currently disabled.");
	}
	return g_iRemaining;
}