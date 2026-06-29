#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define DEBUG		   0
#define PLUGIN_VERSION "1.0"
#define GAMEDATA	   "l4d2_start_safe_area"

ConVar g_Onff, g_farea;
int	   g_iPlugins;
bool   g_bHaveLeftSafeArea, g_bRoundStart;
float  center_point[3], f_distance;

public Plugin myinfo =
{
	name		= "Start Safe Area",
	author		= "洛琪",
	description = "强制游戏将开局出生点周围区域判定为安全区,以保证玩家安全",
	version		= PLUGIN_VERSION,
	url			= "https://steamcommunity.com/profiles/76561198812009299/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(buffer))
		SetFailState("Missing required file: \"%s\".\n", buffer);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if (hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	DynamicDetour dSafeAreaJudge = DynamicDetour.FromConf(hGameData, "CheckForSurvivorsLeavingSafeArea");
	if (!dSafeAreaJudge)
		SetFailState("Failed to setup detour for CheckForSurvivorsLeavingSafeArea");

	if (!dSafeAreaJudge.Enable(Hook_Pre, Detour_DirectorJudgeSafeArea))
		SetFailState("Failed to detour for CheckForSurvivorsLeavingSafeArea");
	delete hGameData;

	g_Onff	= CreateConVar("safe_override", "1", "0关闭插件,1开启插件", FCVAR_NOTIFY);
	g_farea = CreateConVar("safe_area", "800.0", "起点周围以球体为半径,至少多远的距离内都认为是安全区", FCVAR_NOTIFY, true, 1.0, true, 2000.0);
	g_Onff.AddChangeHook(On_CvarChanged);
	g_farea.AddChangeHook(On_CvarChanged);
	GetCvars();

	g_bHaveLeftSafeArea = false;

#if DEBUG:
	HookEvent("player_left_safe_area", Event_PlayerLeftSafeArea, EventHookMode_PostNoCopy);
#endif
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

#if DEBUG:
void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("现在离开了安全区");
}
#endif

void GetCvars()
{
	g_iPlugins = g_Onff.IntValue;
	f_distance = g_farea.FloatValue;
}

void On_CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bHaveLeftSafeArea = false;
	g_bRoundStart		= true;
	CreateTimer(0.1, CheckAnyOneLeftSafeArea, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bRoundStart)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2)
			return;

		g_bRoundStart = false;
		CreateTimer(0.1, DelayTelepAndGetStartArea, client);
	}
}

Action DelayTelepAndGetStartArea(Handle timer, int client)
{
	AcceptEntityInput(client, "DisableLedgeHang");
	CheatCommand(client, "warp_to_start_area");
	GetClientAbsOrigin(client, center_point);
	return Plugin_Continue;
}

Action CheckAnyOneLeftSafeArea(Handle timer)
{
	if (IsNullVector(center_point))
		return Plugin_Continue;
	for (int i = 1; i < MaxClients + 1; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			int viewEnt = GetEntPropEnt(i, Prop_Send, "m_hViewEntity");
			if (viewEnt != -1)
				return Plugin_Continue;

			float v_pos[3];
			GetClientAbsOrigin(i, v_pos);
			if (GetVectorDistance(v_pos, center_point, true) > f_distance * f_distance)
			{
				g_bHaveLeftSafeArea = true;
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

MRESReturn Detour_DirectorJudgeSafeArea(DHookReturn hReturn, DHookParam hParams)
{
	if (!g_iPlugins) return MRES_Ignored;
	if (!g_bHaveLeftSafeArea)
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

void CheatCommand(int client, const char[] cmd)
{
	int flags = GetCommandFlags(cmd);
	int bits  = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, cmd);
	SetCommandFlags(cmd, flags);
	SetUserFlagBits(client, bits);
}