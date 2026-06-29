#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

native float L4D2Direct_GetFlowDistance(int client);
native void  L4D2_ExecVScriptCode(const char[] code);

#define PLUGIN_VERSION "1.1"

ConVar g_hCvarGap;
ConVar g_hCvarInterval;
ConVar g_hCvarDebug;

float g_fGap;
float g_fInterval;
int   g_iDebug;

bool g_bApplied;
bool g_bFight;

int  g_iOrigMobDir;
bool g_bHaveOrigDir;

ConVar  g_hVSBuf;
Handle  g_hTimer;

char g_sLogPath[PLATFORM_MAX_PATH];

public APLRes AskPluginLoad2(Handle self, bool late, char[] err, int errMax)
{
	RegPluginLibrary("l4d2_front_mob_direction");

	MarkNativeAsOptional("L4D2Direct_GetFlowDistance");
	MarkNativeAsOptional("L4D2_ExecVScriptCode");

	return APLRes_Success;
}

public Plugin myinfo =
{
	name        = "[L4D2] Front Mob Direction",
	author      = "Tighty-Whitey",
	description = "Forces mobs to spawn in front when survivor flow gap between alive players is large.",
	version     = "1.1",
	url         = ""
};

public void OnPluginStart()
{
	g_hCvarGap      = CreateConVar("l4d2_front_mob_gap", "2000", "Flow gap to force front mob direction.", FCVAR_NOTIFY);
	g_hCvarInterval = CreateConVar("l4d2_front_mob_interval", "0.5", "Seconds between flow checks.", FCVAR_NOTIFY);
	g_hCvarDebug    = CreateConVar("l4d2_front_mob_debug", "0", "0=off, 1=state, 2=detailed tick state.", FCVAR_NONE);

	AutoExecConfig(true, "l4d2_front_mob_direction");

	g_hCvarGap.AddChangeHook(OnCvarChanged);
	g_hCvarInterval.AddChangeHook(OnCvarChanged);
	g_hCvarDebug.AddChangeHook(OnCvarChanged);

	RefreshCvars();

	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/l4d2_front_mob_direction_debug.log");

	g_hVSBuf = FindConVar("l4d2_vscript_return");
	if (g_hVSBuf == null)
		g_hVSBuf = CreateConVar("l4d2_vscript_return", "", "VScript return buffer. Do not use.", FCVAR_DONTRECORD);

	HookEvent("player_left_safe_area", E_LeftSafe, EventHookMode_PostNoCopy);
	HookEvent("round_end",            E_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition",       E_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving",E_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("mission_lost",         E_RoundEnd, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	ResetState();

	char map[64];
	GetCurrentMap(map, sizeof(map));
	Dbg("OnMapStart map=%s", map);

	CaptureOriginalDir();
	StartThinkTimer();
}

public void OnMapEnd()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	Dbg("OnMapEnd map=%s", map);

	StopThinkTimer();

	if (g_bApplied)
		RestoreOriginal();

	ResetState();
}

public void OnConfigsExecuted()
{
	RefreshCvars();
	RestartThinkTimer();
}

void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	RefreshCvars();
	RestartThinkTimer();
}

void RefreshCvars()
{
	g_fGap = g_hCvarGap.FloatValue;

	float iv = g_hCvarInterval.FloatValue;
	if (iv < 0.1)
		iv = 0.1;
	g_fInterval = iv;

	g_iDebug = g_hCvarDebug.IntValue;
	if (g_iDebug < 0) g_iDebug = 0;
	if (g_iDebug > 2) g_iDebug = 2;
}

void ResetState()
{
	g_bApplied = false;
	g_bFight = false;

	g_bHaveOrigDir = false;
	g_iOrigMobDir = -1;
}

void StopThinkTimer()
{
	if (g_hTimer != null)
	{
		KillTimer(g_hTimer);
		g_hTimer = null;
	}
}

void StartThinkTimer()
{
	if (g_hTimer != null)
		return;

	g_hTimer = CreateTimer(g_fInterval, T_Think, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void RestartThinkTimer()
{
	StopThinkTimer();
	StartThinkTimer();
}

public Action T_Think(Handle timer)
{
	if (!g_bFight)
		return Plugin_Continue;

	float furthest, slowest;
	int alive = GetAliveSurvivorFlowMinMax(slowest, furthest);
	float gap = furthest - slowest;

	if (g_iDebug >= 2)
	{
		Dbg("Tick alive=%d slowest=%.1f furthest=%.1f gap=%.1f applied=%d",
			alive, slowest, furthest, gap, g_bApplied ? 1 : 0);
		LogAliveSurvivorFlows();
	}

	if (alive < 2)
	{
		if (g_bApplied)
			RestoreOriginal();
		return Plugin_Continue;
	}

	if (gap > g_fGap)
	{
		if (!g_bApplied)
			ApplyFront();
	}
	else
	{
		if (g_bApplied)
			RestoreOriginal();
	}

	return Plugin_Continue;
}

public void E_LeftSafe(Event event, const char[] name, bool dontBroadcast)
{
	g_bFight = true;
	Dbg("E_LeftSafe");

	CaptureOriginalDir();
	StartThinkTimer();
}

public void E_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Dbg("E_RoundEnd");

	g_bFight = false;

	if (g_bApplied)
		RestoreOriginal();

	StopThinkTimer();
}

int GetAliveSurvivorFlowMinMax(float &minf, float &maxf)
{
	minf = 0.0;
	maxf = 0.0;

	bool any = false;
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		float f = GetFlowDistance(i);

		if (!any || f < minf) minf = f;
		if (!any || f > maxf) maxf = f;

		any = true;
		count++;
	}

	if (!any)
	{
		minf = 0.0;
		maxf = 0.0;
		return 0;
	}

	return count;
}

void LogAliveSurvivorFlows()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;

		char name[64];
		GetClientName(i, name, sizeof(name));

		float f = GetFlowDistance(i);
		Dbg("AliveSurvivor client=%d name=%s flow=%.1f", i, name, f);
	}
}

float GetFlowDistance(int client)
{
	if (GetFeatureStatus(FeatureType_Native, "L4D2Direct_GetFlowDistance") == FeatureStatus_Available)
		return L4D2Direct_GetFlowDistance(client);

	return 0.0;
}

void CaptureOriginalDir()
{
	g_bHaveOrigDir = false;
	g_iOrigMobDir = -1;

	int dir = ReadPreferredMobDirection();
	g_iOrigMobDir = dir;
	g_bHaveOrigDir = true;

	if (g_iDebug >= 1)
		Dbg("Original PreferredMobDirection=%d", dir);
}

void ApplyFront()
{
	if (GetFeatureStatus(FeatureType_Native, "L4D2_ExecVScriptCode") != FeatureStatus_Available)
	{
		Dbg("ApplyFront: L4D2_ExecVScriptCode not available");
		return;
	}

	WritePreferredMobDirection(7);
	g_bApplied = true;

	int after = ReadPreferredMobDirection();
	Dbg("Applied front dir=7 readback=%d", after);
}

void RestoreOriginal()
{
	if (GetFeatureStatus(FeatureType_Native, "L4D2_ExecVScriptCode") != FeatureStatus_Available)
	{
		Dbg("RestoreOriginal: L4D2_ExecVScriptCode not available");
		g_bApplied = false;
		return;
	}

	int dir = (g_bHaveOrigDir ? g_iOrigMobDir : -1);

	WritePreferredMobDirection(dir);
	g_bApplied = false;

	int after = ReadPreferredMobDirection();
	Dbg("Restored dir=%d readback=%d", dir, after);
}

int ReadPreferredMobDirection()
{
	if (g_hVSBuf == null)
		return -1;

	if (GetFeatureStatus(FeatureType_Native, "L4D2_ExecVScriptCode") != FeatureStatus_Available)
		return -1;

	static const char code_dir[]  = "try{Convars.SetValue(\"l4d2_vscript_return\",\"\"+::DirectorOptions.PreferredMobDirection);}catch(e){Convars.SetValue(\"l4d2_vscript_return\",\"-999\");}";
	static const char code_sess[] = "try{Convars.SetValue(\"l4d2_vscript_return\",\"\"+::SessionOptions.PreferredMobDirection);}catch(e){Convars.SetValue(\"l4d2_vscript_return\",\"-1\");}";

	if (g_iDebug >= 2)
		Dbg("VScript Read len_dir=%d", strlen(code_dir));

	L4D2_ExecVScriptCode(code_dir);

	char s[32];
	g_hVSBuf.GetString(s, sizeof(s));
	int v = StringToInt(s);

	if (v == -999)
	{
		if (g_iDebug >= 2)
			Dbg("VScript Read: DirectorOptions failed, trying SessionOptions (len=%d)", strlen(code_sess));

		L4D2_ExecVScriptCode(code_sess);

		g_hVSBuf.GetString(s, sizeof(s));
		v = StringToInt(s);
	}

	return v;
}

void WritePreferredMobDirection(int dir)
{
	if (GetFeatureStatus(FeatureType_Native, "L4D2_ExecVScriptCode") != FeatureStatus_Available)
		return;

	char code[192];
	Format(code, sizeof(code),
		"try{::DirectorOptions.PreferredMobDirection=%d;}catch(e){try{::SessionOptions.PreferredMobDirection=%d;}catch(e2){}}",
		dir, dir
	);

	if (g_iDebug >= 2)
		Dbg("VScript Write len=%d dir=%d", strlen(code), dir);

	L4D2_ExecVScriptCode(code);
}

void Dbg(const char[] fmt, any ...)
{
	if (g_iDebug <= 0)
		return;

	char msg[512];
	VFormat(msg, sizeof(msg), fmt, 2);
	LogToFileEx(g_sLogPath, "%s", msg);
}
