#include <sourcemod>
#include <sdktools>
#include <colors_csgo>
#include <SteamWorks>
#include <sourcebans>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Anti-Cheat (GXAC)",
	author = "The [G]amerX",
	description = "Anti-Cheat for CS:GO servers",
	version = "2.8.5",
	url = "https://steamcommunity.com/id/gamerxcz/"
};
#define IS_CLIENT(%1)							(1 <= %1 <= MaxClients)
#define TIME_TO_TICK(%1)					(RoundToNearest((%1) / GetTickInterval()))
#define AIM_ANGLE_CHANGE					45.0	// Max angle change that a player should snap
#define AIM_MIN_DISTANCE					200.0	// Minimum distance acceptable for a detection.
#define MIN_JUMP_TIME							0.500	// Minimum amount of air-time for a jump to count.
#define METHOD_BUNNYHOP						0
#define METHOD_AUTOFIRE						1
#define METHOD_MAX								2
#define CVAR_REPLICATION_DELAY 		30
#define TIME_REQUERY_FIRST 				20.0
#define TIME_REQUERY_SUBSEQUENT 	10.0
#define MAX_REQUERY_ATTEMPTS 			4
#define MAX_CVAR_NAME_LEN 				PLATFORM_MAX_PATH
#define MAX_CVAR_VALUE_LEN 				PLATFORM_MAX_PATH
#define Cvar_Order 								"1"
#define Cvar_Name 								"2"
#define Cvar_CompType 						"3"
#define Cvar_Action 							"4"
#define Cvar_Value 								"5"
#define Cvar_Value2 							"6"
#define Cvar_ReplicatedTime 			"7"

enum CvarOrder
{
	Order_First = 0,
	Order_Last
}
enum CvarComp
{
	Comp_Invalid = -1,
	Comp_Equal = 0,
	Comp_StrEqual,
	Comp_Replicated,
	Comp_Greater,
	Comp_Less,
	Comp_Between,
	Comp_Outside,
	Comp_NonExist
}
enum CvarAction
{
	Action_Invalid = -1,
	Action_Warn = 0,
	Action_Mute,
	Action_Kick,
	Action_Ban
}

Handle g_hCvarTrie;
Handle g_hCvarADT;
Handle g_hTimer[MAXPLAYERS + 1];
Handle g_hCurDataTrie[MAXPLAYERS + 1];
int g_iADTIndex[MAXPLAYERS + 1] = {-1, ...};
int g_iRequeryCount[MAXPLAYERS + 1];
int g_iADTSize;
bool nonprime[MAXPLAYERS + 1];
int g_iCmdNum[MAXPLAYERS + 1];
int g_iJumpsSent[MAXPLAYERS + 1][30];
int g_iJumpsSentIndex[MAXPLAYERS + 1];
float prev_sidemove[MAXPLAYERS + 1];
int g_iPerfSidemove[MAXPLAYERS + 1];
int prev_buttons[MAXPLAYERS + 1];
bool g_bShootSpam[MAXPLAYERS + 1];
int g_iLastShotTick[MAXPLAYERS + 1];
bool g_bFirstShot[MAXPLAYERS + 1];
int g_iAutoShoot[MAXPLAYERS + 1];
int g_iTriggerBotCount[MAXPLAYERS + 1];
int g_iTicksOnPlayer[MAXPLAYERS + 1];
int g_iPrev_TicksOnPlayer[MAXPLAYERS + 1];
int g_iMacroCount[MAXPLAYERS + 1];
int g_iMacroDetectionCount[MAXPLAYERS + 1];
float g_fJumpStart[MAXPLAYERS + 1];
float g_fDefuseTime[MAXPLAYERS+1];
int g_iWallTrace[MAXPLAYERS + 1];
int g_iWallTraceDetectionCount[MAXPLAYERS + 1];
int g_iStrafeCount[MAXPLAYERS + 1];
bool turnRight[MAXPLAYERS + 1];
int g_iTickCount[MAXPLAYERS + 1];
int prev_mousedx[MAXPLAYERS + 1];
int g_iAHKStrafeDetection[MAXPLAYERS + 1];
int g_iMousedx_Value[MAXPLAYERS + 1];
int g_iMousedxCount[MAXPLAYERS + 1];
float g_fJumpPos[MAXPLAYERS + 1];
bool prev_OnGround[MAXPLAYERS + 1];
char discord[PLATFORM_MAX_PATH];
char f_authid[MAXPLAYERS + 1][99];
float g_fEyeAngles[MAXPLAYERS + 1][64][3];
int g_iEyeIndex[MAXPLAYERS + 1];
bool detectEzFrags[MAXPLAYERS + 1];
int detectEzFrags_count[MAXPLAYERS + 1];
int g_iAimDetections[MAXPLAYERS + 1];
int g_iMaxAngleHistory;
int checking_name;
int g_iDetections[METHOD_MAX][MAXPLAYERS+1];
int g_iAttackMax = 66;

stock bool IsClientNew(int client)
{
	return IsFakeClient(client) || GetGameTime() > GetClientTime(client);
}
stock void ZeroVector(float vec[3])
{
	vec[0] = vec[1] = vec[2] = 0.0;
}
stock bool IsVectorZero(const float vec[3])
{
	return vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0;
}
public void OnPluginStart()
{
	LoadTranslations("smac.phrases");
	for(int i = 1; i <= MaxClients; i++)
		SetDefaults(i);
	if((g_iMaxAngleHistory = TIME_TO_TICK(0.5)) > sizeof(g_fEyeAngles[]))
	{
		g_iMaxAngleHistory = sizeof(g_fEyeAngles[]);
	}
	HookEntityOutput("trigger_teleport", "OnEndTouch", Teleport_OnEndTouch);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	if(!HookEventEx("entity_killed", Event_EntityKilled, EventHookMode_Post))
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath_Pre, EventHookMode_Pre);
	AddCommandListener(Command_Chat, "say");
	g_iAttackMax = RoundToNearest(1.0 / GetTickInterval() / 3.0);
	CreateTimer(4.0, TimerDecreaseCount, _, TIMER_REPEAT);

	g_hCvarTrie = CreateTrie();
	g_hCvarADT = CreateArray();
	// Check for plugins first.
	AddCvar(Order_First, "0penscript",				Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "aim_bot",					Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "aim_fov",					Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "bat_version",				Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "beetlesmod_version",		Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "est_version",				Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "eventscripts_ver",		Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "fm_attackmode",			Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "lua-engine",				Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "lua_open",				Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "mani_admin_plugin_version",Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "maniadminhacker",			Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "maniadmintakeover",		Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "metamod_version",			Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "openscript",				Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "openscript_version",		Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "runnscript",				Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "smadmintakeover",			Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "sourcemod_version",		Comp_NonExist, Action_Kick);
	AddCvar(Order_First, "tb_enabled",				Comp_NonExist, Action_Ban);
	AddCvar(Order_First, "zb_version",				Comp_NonExist, Action_Kick);
	// Check for everything else last.
	AddCvar(Order_Last, "cl_clock_correction",	Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "cl_leveloverview",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "cl_overdraw_test",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "cl_phys_timescale",	Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "cl_showevents",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "fog_enable",		Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "host_timescale",		Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "mat_dxlevel",			Comp_Greater, Action_Kick, "80.0");
	AddCvar(Order_Last, "mat_fillrate",			Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "mat_measurefillrate",	Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "mat_proxy",			Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "mat_showlowresimage",	Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "mat_wireframe",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "mem_force_flush",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "mp_fadetoblack",		Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "r_aspectratio",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_colorstaticprops",	Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_dispwalkable",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_drawbeams",			Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawbrushmodels",	Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawclipbrushes",	Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_drawdecals",			Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawentities",		Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawmodelstatsoverlay", Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_drawopaqueworld",	Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawothermodels", 	Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawparticles",		Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawrenderboxes",	Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_drawskybox",			Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_drawtranslucentworld", Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_shadowwireframe",	Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "r_skybox",				Comp_Equal, Action_Ban, "1.0");
	AddCvar(Order_Last, "r_visocclusion",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "snd_show",				Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "snd_visualize",		Comp_Equal, Action_Ban, "0.0");
	AddCvar(Order_Last, "sv_allowminmodels",	Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "sv_cheats",			Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "sv_competitive_minspec", Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "sv_consistency",		Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "sv_footsteps",			Comp_Replicated, Action_Ban);
	AddCvar(Order_Last, "vcollide_wireframe",	Comp_Equal, Action_Ban, "0.0");
	// scramble ordering.
	if(g_iADTSize) ScrambleCvars();
}
public void OnClientAuthorized(int client, const char[] auth)
{
	GetClientAuthId(client, AuthId_Steam2, f_authid[client], sizeof(f_authid));
}
public void OnClientPutInServer(int client)
{
	SetDefaults(client);
	if(IsClientNew(client))
	{
		g_iAimDetections[client] = 0;
		Aimbot_ClearAngles(client);
	}
}
public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		if(g_hTimer[client] != INVALID_HANDLE) CloseHandle(g_hTimer[client]);
		g_hTimer[client] = CreateTimer(0.1, Timer_QueryNextCvar, client, TIMER_REPEAT);
	}
	/***************************************************/
	if(k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820))
	{
		nonprime[client] = true;
		return;
	}
	else nonprime[client] = false;
	return;
}
public void OnClientDisconnect(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		g_hCurDataTrie[client] = INVALID_HANDLE;
		g_iADTIndex[client] = -1;
		g_iRequeryCount[client] = 0;
		if(g_hTimer[client] != INVALID_HANDLE) CloseHandle(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
	}
}
public void OnClientDisconnect_Post(int client)
{
	for(int i = 0; i < METHOD_MAX; i++)
		g_iDetections[i][client] = 0;
}
bool AddCvar(CvarOrder COrder, char[] sCvar, CvarComp CCompType, CvarAction CAction, const char[] sValue = "", const char[] sValue2 = "")
{
	if(CCompType == Comp_Invalid || CAction == Action_Invalid)
		return false;

	StringToLower(sCvar);

	char sNewValue[MAX_CVAR_VALUE_LEN];
	Handle hCvar;

	if(CCompType == Comp_Replicated)
	{
		hCvar = FindConVar(sCvar);
		if(hCvar == INVALID_HANDLE || !(GetConVarFlags(hCvar) & FCVAR_REPLICATED)) return false;
		GetConVarString(hCvar, sNewValue, sizeof(sNewValue));
	}
	else strcopy(sNewValue, sizeof(sNewValue), sValue);

	Handle hDataTrie;

	if(GetTrieValue(g_hCvarTrie, sCvar, hDataTrie))
	{
		SetTrieString(hDataTrie, Cvar_Name, sCvar);
		SetTrieValue(hDataTrie, Cvar_CompType, CCompType);
		SetTrieValue(hDataTrie, Cvar_Action, CAction);
		SetTrieString(hDataTrie, Cvar_Value, sNewValue);
		SetTrieString(hDataTrie, Cvar_Value2, sValue2);
	}
	else
	{
		hDataTrie = CreateTrie();

		SetTrieValue(hDataTrie, Cvar_Order, COrder);
		SetTrieString(hDataTrie, Cvar_Name, sCvar);
		SetTrieValue(hDataTrie, Cvar_CompType, CCompType);
		SetTrieValue(hDataTrie, Cvar_Action, CAction);
		SetTrieString(hDataTrie, Cvar_Value, sNewValue);
		SetTrieString(hDataTrie, Cvar_Value2, sValue2);
		SetTrieValue(hDataTrie, Cvar_ReplicatedTime, 0);

		SetTrieValue(g_hCvarTrie, sCvar, hDataTrie);
		PushArrayCell(g_hCvarADT, hDataTrie);
		g_iADTSize = GetArraySize(g_hCvarADT);

		if(CCompType == Comp_Replicated)
		{
			HookConVarChange(hCvar, OnConVarChanged);
			ReplicateToAll(hCvar, sNewValue);
		}
	}
	return true;
}
public Action Timer_QueryNextCvar(Handle timer, any client)
{
	if(!IsValidClient(client))
		return Plugin_Stop;

	if(!g_iADTSize)
		return Plugin_Continue;

	if(++g_iADTIndex[client] >= g_iADTSize)
		g_iADTIndex[client] = 0;

	Handle hDataTrie = GetArrayCell(g_hCvarADT, g_iADTIndex[client]);

	if(IsReplicating(hDataTrie))
		return Plugin_Continue;

	char sCvar[MAX_CVAR_NAME_LEN];
	GetTrieString(hDataTrie, Cvar_Name, sCvar, sizeof(sCvar));

	if(QueryClientConVar(client, sCvar, OnConVarQueryFinished, GetClientSerial(client)) == QUERYCOOKIE_FAILED)
		return Plugin_Continue;

	g_hCurDataTrie[client] = hDataTrie;
	g_hTimer[client] = CreateTimer(TIME_REQUERY_FIRST, Timer_RequeryCvar, client);
	return Plugin_Stop;
}
public Action Timer_RequeryCvar(Handle timer, any client)
{
	if(!IsValidClient(client))
		return Plugin_Stop;

	// Have we had enough?
	if(++g_iRequeryCount[client] > MAX_REQUERY_ATTEMPTS)
	{
		g_hTimer[client] = INVALID_HANDLE;
		KickClient(client, "%t", "FailedToReply");
		return Plugin_Stop;
	}
	if(g_hCurDataTrie[client] != INVALID_HANDLE && !IsReplicating(g_hCurDataTrie[client]))
	{
		char sCvar[MAX_CVAR_NAME_LEN];
		GetTrieString(g_hCurDataTrie[client], Cvar_Name, sCvar, sizeof(sCvar));
		if(QueryClientConVar(client, sCvar, OnConVarQueryFinished, GetClientSerial(client)) != QUERYCOOKIE_FAILED)
		{
			g_hTimer[client] = CreateTimer(TIME_REQUERY_SUBSEQUENT, Timer_RequeryCvar, client);
			return Plugin_Stop;
		}
	}
	g_hTimer[client] = CreateTimer(0.1, Timer_QueryNextCvar, client, TIMER_REPEAT);
	return Plugin_Stop;
}
public void OnConVarQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any serial)
{
	if(GetClientFromSerial(serial) != client)
		return;

	char sCvar[MAX_CVAR_NAME_LEN];
	Handle hDataTrie;

	strcopy(sCvar, sizeof(sCvar), cvarName);
	StringToLower(sCvar);

	if(!GetTrieValue(g_hCvarTrie, sCvar, hDataTrie) || hDataTrie != g_hCurDataTrie[client])
		return;

	g_hCurDataTrie[client] = INVALID_HANDLE;
	g_iRequeryCount[client] = 0;
	if(g_hTimer[client] != INVALID_HANDLE) CloseHandle(g_hTimer[client]);
	g_hTimer[client] = CreateTimer(0.1, Timer_QueryNextCvar, client, TIMER_REPEAT);

	CvarComp CCompType;
	char sValue[MAX_CVAR_VALUE_LEN];
	char sValue2[MAX_CVAR_VALUE_LEN];
	char sKickMessage[255];
	GetTrieValue(hDataTrie, Cvar_CompType, CCompType);
	GetTrieString(hDataTrie, Cvar_Value, sValue, sizeof(sValue));
	GetTrieString(hDataTrie, Cvar_Value2, sValue2, sizeof(sValue2));

	if(result == ConVarQuery_Okay)
	{
		if(IsReplicating(hDataTrie)) return;

		switch(CCompType)
		{
			case Comp_Equal:
			{
				if(StringToFloat(cvarValue) == StringToFloat(sValue))
					return;
				FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "ShouldEqual", client, sCvar, sValue, cvarValue);
			}
			case Comp_StrEqual, Comp_Replicated:
			{
				if(StrEqual(cvarValue, sValue))
					return;
				FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "ShouldEqual", client, sCvar, sValue, cvarValue);
			}
			case Comp_Greater:
			{
				if(StringToFloat(cvarValue) >= StringToFloat(sValue))
					return;
				FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "ShouldBeGreater", client, sCvar, sValue, cvarValue);
			}
			case Comp_Less:
			{
				if(StringToFloat(cvarValue) <= StringToFloat(sValue))
					return;
				FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "ShouldBeLess", client, sCvar, sValue, cvarValue);
			}
			case Comp_Between:
			{
				if(StringToFloat(cvarValue) >= StringToFloat(sValue) && StringToFloat(cvarValue) <= StringToFloat(sValue2))
					return;
				FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "ShouldBeBetween", client, sCvar, sValue, sValue2, cvarValue);
			}
			case Comp_Outside:
			{
				if(StringToFloat(cvarValue) < StringToFloat(sValue) || StringToFloat(cvarValue) > StringToFloat(sValue2))
					return;
				FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "ShouldBeOutside", client, sCvar, sValue, sValue2, cvarValue);
			}
			default: FormatEx(sKickMessage, sizeof(sKickMessage), "ConVar %s violation", sCvar);
		}
	}
	else if(CCompType == Comp_NonExist)
	{
		if(result == ConVarQuery_NotFound) return;
		FormatEx(sKickMessage, sizeof(sKickMessage), "ConVar %s violation", sCvar);
	}
	CvarAction CAction;
	GetTrieValue(hDataTrie, Cvar_Action, CAction);

	char sResult[16], sCompType[16];
	GetQueryResultString(result, sResult, sizeof(sResult));
	GetCompTypeString(CCompType, sCompType, sizeof(sCompType));

	switch(CAction)
	{
		case Action_Kick:
		{
			FormatEx(discord, sizeof(discord), "%N %s was detected for failing checks on convar \"%s\". [result \"%s\" | CompType: \"%s\" | cvarValue \"%s\" | value: \"%s\" | value2: \"%s\"] (kicked)", client, nonprime[client]?"[Non-Prime]":"", sCvar, sResult, sCompType, cvarValue, sValue, sValue2);
			SendMessageToAdmins(discord);
			FormatEx(discord, sizeof(discord), "**%N** (%s) %s was detected for failing checks on convar **%s**. [result **%s** | CompType: **%s** | cvarValue **%s** | value: **%s** | value2: **%s**] (kicked)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", sCvar, sResult, sCompType, cvarValue, sValue, sValue2);
			SendMessageToDiscord("anticheat", discord);
			KickClient(client, "\n%s", sKickMessage);
		}
		case Action_Ban:
		{
			FormatEx(discord, sizeof(discord), "%N %s was detected for failing checks on convar \"%s\". [result \"%s\" | CompType: \"%s\" | cvarValue \"%s\" | value: \"%s\" | value2: \"%s\"] (Banned)", client, nonprime[client]?"[Non-Prime]":"", sCvar, sResult, sCompType, cvarValue, sValue, sValue2);
			SendMessageToAdmins(discord);
			FormatEx(discord, sizeof(discord), "**%N** (%s) %s was detected for failing checks on convar **%s**. [result **%s** | CompType: **%s** | cvarValue **%s** | value: **%s** | value2: **%s**] (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", sCvar, sResult, sCompType, cvarValue, sValue, sValue2);
			SendMessageToDiscord("anticheat", discord);
			FormatEx(discord, sizeof(discord), "ConVar %s violation", sCvar);
			SBBanPlayer(0, client, 0, discord);
		}
	}
}
public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	char sCvar[MAX_CVAR_NAME_LEN];
	Handle hDataTrie;

	GetConVarName(convar, sCvar, sizeof(sCvar));
	StringToLower(sCvar);

	if(!GetTrieValue(g_hCvarTrie, sCvar, hDataTrie))
		return;

	SetTrieString(hDataTrie, Cvar_Value, newValue);
	SetTrieValue(hDataTrie, Cvar_ReplicatedTime, GetTime() + CVAR_REPLICATION_DELAY);

	if(StrEqual(sCvar, "sv_cheats") && StringToInt(newValue) != 0)
	{
		SetConVarInt(convar, 0, true, true);
		return;
	}
	ReplicateToAll(convar, newValue);
}
void ScrambleCvars()
{
	Handle[][] hCvarADTs = new Handle[view_as<int>(CvarOrder)][g_iADTSize];
	Handle hDataTrie, iOrder;
	int iADTIndex[view_as<int>(CvarOrder)];

	for(int i = 0; i < g_iADTSize; i++)
	{
		hDataTrie = GetArrayCell(g_hCvarADT, i);
		GetTrieValue(hDataTrie, Cvar_Order, iOrder);
		hCvarADTs[iOrder][iADTIndex[iOrder]++] = hDataTrie;
	}
	ClearArray(g_hCvarADT);
	for(int i = 0; i < view_as<int>(CvarOrder); i++)
	{
		if(iADTIndex[i] > 0)
		{
			SortIntegers(view_as<int>(hCvarADTs[i]), iADTIndex[i], Sort_Random);
			for(int j = 0; j < iADTIndex[i]; j++)
				PushArrayCell(g_hCvarADT, hCvarADTs[i][j]);
		}
	}
}
bool IsReplicating(Handle hDataTrie)
{
	int iReplicatedTime;
	GetTrieValue(hDataTrie, Cvar_ReplicatedTime, iReplicatedTime);
	return (iReplicatedTime > GetTime());
}
public Action TimerDecreaseCount(Handle timer)
{
	for(int i = 0; i < METHOD_MAX; i++)
	{
		for(int j = 1; j <= MaxClients; j++)
		{
			if(g_iDetections[i][j])
			{
				g_iDetections[i][j]--;
			}
		}
	}
	return Plugin_Continue;
}
public Action Teleport_OnEndTouch(const char[] output, int caller, int activator, float delay)
{
	if(IS_CLIENT(activator) && IsClientConnected(activator))
	{
		Aimbot_ClearAngles(activator);
		CreateTimer(0.1 + delay, Timer_ClearAngles, GetClientUserId(activator), TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if(IS_CLIENT(client))
	{
		Aimbot_ClearAngles(client);
		CreateTimer(0.1, Timer_ClearAngles, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	char sWeapon[32];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));

	if(StrContains(sWeapon, "knife", false) != -1 || StrContains(sWeapon, "bayonet", false) != -1 || StrContains(sWeapon, "taser", false) != -1)
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if(IS_CLIENT(victim) && IS_CLIENT(attacker) && victim != attacker && IsClientInGame(victim) && IsClientInGame(attacker))
	{
		float vVictim[3], vAttacker[3];
		GetClientAbsOrigin(victim, vVictim);
		GetClientAbsOrigin(attacker, vAttacker);

		if(GetVectorDistance(vVictim, vAttacker) >= AIM_MIN_DISTANCE)
		{
			Aimbot_AnalyzeAngles(attacker);
		}
	}
}
public Action Event_EntityKilled(Event event, const char[] name, bool dontBroadcast)
{
	int victim = event.GetInt("entindex_killed");
	int attacker = event.GetInt("entindex_attacker");
	int inflictor = event.GetInt("entindex_inflictor");

	if(IS_CLIENT(victim) && IS_CLIENT(attacker) && victim != attacker && attacker == inflictor && IsClientInGame(victim) && IsClientInGame(attacker))
	{
		char sWeapon[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));

		if(StrContains(sWeapon, "knife", false) != -1 || StrContains(sWeapon, "bayonet", false) != -1 || StrContains(sWeapon, "taser", false) != -1)
			return;

		float vVictim[3], vAttacker[3];
		GetClientAbsOrigin(victim, vVictim);
		GetClientAbsOrigin(attacker, vAttacker);

		if(GetVectorDistance(vVictim, vAttacker) >= AIM_MIN_DISTANCE)
		{
			Aimbot_AnalyzeAngles(attacker);
		}
	}
}
public Action Timer_ClearAngles(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(IS_CLIENT(client))
	{
		Aimbot_ClearAngles(client);
	}
	return Plugin_Stop;
}
public Action Timer_DecreaseCount(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(IS_CLIENT(client) && g_iAimDetections[client])
	{
		g_iAimDetections[client]--;
	}
	return Plugin_Stop;
}
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static int iPrevButtons[MAXPLAYERS + 1];
	static int iAttackAmt[MAXPLAYERS+1];
	static bool bResetNext[MAXPLAYERS+1];

	if(((iButtons & IN_ATTACK) && !(iPrevButtons[client] & IN_ATTACK)) || (!(iButtons & IN_ATTACK) && (iPrevButtons[client] & IN_ATTACK)))
	{
		if(++iAttackAmt[client] >= g_iAttackMax)
		{
			AutoTrigger_Detected(client, METHOD_AUTOFIRE);
			iAttackAmt[client] = 0;
		}
		bResetNext[client] = false;
	}
	else if (bResetNext[client])
	{
		iAttackAmt[client] = 0;
		bResetNext[client] = false;
	}
	else bResetNext[client] = true;
	iPrevButtons[client] = iButtons;
	/***************************************************/
	g_fEyeAngles[client][g_iEyeIndex[client]] = fAngles;

	if(++g_iEyeIndex[client] == g_iMaxAngleHistory)
	{
		g_iEyeIndex[client] = 0;
	}
	/***************************************************/
	if(!IsFakeClient(client) && IsValidClient(client) && IsPlayerAlive(client))
	{
		CheckWallTrace(client, fAngles);
		CheckSilentStrafe(client, fVelocity[1]);
		CheckTriggerBot(client, iButtons, fAngles);
		CheckMacro(client, iButtons);
		CheckAutoShoot(client, iButtons);
		CheckPerfectStrafe(client, mouse[0], iButtons);
		CheckAHKStrafe(client, mouse[0]);
		prev_OnGround[client] = (GetEntityFlags(client) & FL_ONGROUND) == FL_ONGROUND;
		prev_buttons[client] = iButtons;
	}
	g_iCmdNum[client]++;
	StopBacktracking(client, tickcount, iButtons);
	return Plugin_Changed;
}
public void CheckSilentStrafe(int client, float sidemove)
{
	if(sidemove > 0 && prev_sidemove[client] < 0)
	{
		g_iPerfSidemove[client]++;
		if(g_iCmdNum[client] % 50 == 1)
			CheckSidemoveCount(client);
	}
	else if(sidemove < 0 && prev_sidemove[client] > 0)
	{
		g_iPerfSidemove[client]++;
		if(g_iCmdNum[client] % 50 == 1)
			CheckSidemoveCount(client);
	}
	else g_iPerfSidemove[client] = 0;
	prev_sidemove[client] = sidemove;
}
public void CheckSidemoveCount(int client)
{
	if(g_iPerfSidemove[client] >= 10)
	{
		FormatEx(discord, sizeof(discord), "%N %s has been detected for Silent-Strafe! (Banned)", client, nonprime[client]?"[Non-Prime]":"");
		SendMessageToAdmins(discord);
		FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **Silent-Strafe**! (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"");
		SendMessageToDiscord("anticheat", discord);
		SBBanPlayer(0, client, 0, "Mutli-Hack");
	}
	g_iPerfSidemove[client] = 0;
}
public void CheckTriggerBot(int client, int buttons, float angles[3])
{
	float vOrigin[3], AnglesVec[3], EndPoint[3];
	float Distance = 999999.0;

	GetClientEyePosition(client,vOrigin);
	GetAngleVectors(angles, AnglesVec, NULL_VECTOR, NULL_VECTOR);

	EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance);
	EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance);
	EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance);

	Handle trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, client);

	if(TR_DidHit(trace))
	{
		int target = TR_GetEntityIndex(trace);
		if(target > 0 && target <= MaxClients && GetClientTeam(target) != GetClientTeam(client) && IsPlayerAlive(target) && IsPlayerAlive(client) && !g_bShootSpam[client])
		{
			g_iTicksOnPlayer[client]++;

			if(buttons & IN_ATTACK && !(prev_buttons[client] & IN_ATTACK) && g_iTicksOnPlayer[client] == g_iPrev_TicksOnPlayer[client])
			{
				g_iTriggerBotCount[client]++;
			}
			else if(buttons & IN_ATTACK && prev_buttons[client] & IN_ATTACK && g_iTicksOnPlayer[client] == 1)
			{
				if(g_iTriggerBotCount[client] >= 3)
				{
					FormatEx(discord, sizeof(discord), "%N %s detected for %i tick perfect shots.", client, nonprime[client]?"[Non-Prime]":"", g_iTriggerBotCount[client]);
					SendMessageToAdmins(discord);
					FormatEx(discord, sizeof(discord), "**%N** (%s) %s detected for **%i** tick perfect shots.", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iTriggerBotCount[client]);
					SendMessageToDiscord("anticheat", discord);
				}
				g_iTriggerBotCount[client] = 0;
			}
			else if(!(buttons & IN_ATTACK) && !(prev_buttons[client] & IN_ATTACK) && g_iTicksOnPlayer[client] >= g_iPrev_TicksOnPlayer[client])
			{
				if(g_iTriggerBotCount[client] >= 3)
				{
					FormatEx(discord, sizeof(discord), "%N %s detected for %i tick perfect shots.", client, nonprime[client]?"[Non-Prime]":"", g_iTriggerBotCount[client]);
					SendMessageToAdmins(discord);
					FormatEx(discord, sizeof(discord), "**%N** (%s) %s detected for **%i** tick perfect shots.", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iTriggerBotCount[client]);
					SendMessageToDiscord("anticheat", discord);
				}
				g_iTriggerBotCount[client] = 0;
			}
		}
		else
		{
			if(g_iTicksOnPlayer[client] > 0)
				g_iPrev_TicksOnPlayer[client] = g_iTicksOnPlayer[client];

			g_iTicksOnPlayer[client] = 0;
		}
	}
	else
	{
		if(g_iTicksOnPlayer[client] > 0)
			g_iPrev_TicksOnPlayer[client] = g_iTicksOnPlayer[client];
		g_iTicksOnPlayer[client] = 0;
	}
	delete trace;

	if(g_iTriggerBotCount[client] >= 5)
	{
		FormatEx(discord, sizeof(discord), "%N %s has been detected for TriggerBot / Smooth Aimbot! (Banned)", client, nonprime[client]?"[Non-Prime]":"");
		SendMessageToAdmins(discord);
		FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **TriggerBot / Smooth Aimbot**! (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"");
		SendMessageToDiscord("anticheat", discord);
		SBBanPlayer(0, client, 0, "TriggerBot / Smooth Aimbot");
		g_iTriggerBotCount[client] = 0;
 	}
}
public void CheckMacro(int client, int buttons)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);

	if(buttons & IN_JUMP && !(prev_buttons[client] & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityFlags(client) & FL_INWATER) && vec[2] > g_fJumpStart[client])
	{
		g_iMacroCount[client]++;
	}
	else if(GetEntityFlags(client) & FL_ONGROUND)
	{
		if(g_iMacroCount[client] >= 20)
		{
			if(g_iMacroCount[client] >= 30)
			{
				FormatEx(discord, sizeof(discord), "%N %s has been detected for Macro / Hyperscroll! (%i)", client, nonprime[client]?"[Non-Prime]":"", g_iMacroCount[client]);
				SendMessageToAdmins(discord);
				FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **Macro / Hyperscroll**! (%i)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iMacroCount[client]);
				SendMessageToDiscord("anticheat", discord);
			}
			g_iMacroDetectionCount[client]++;
			if(g_iMacroDetectionCount[client] >= 10)
			{
				KickClient(client, "Anti-Cheat: Turn off Bhop Assistance!");
				g_iMacroDetectionCount[client] = 0;
			}
		}
		if(g_iMacroCount[client] > 0)
		{
			g_iJumpsSent[client][g_iJumpsSentIndex[client]] = g_iMacroCount[client];
			g_iJumpsSentIndex[client]++;
			if(g_iJumpsSentIndex[client] == 30)
				g_iJumpsSentIndex[client] = 0;
		}
		g_iMacroCount[client] = 0;
		g_fJumpStart[client] = vec[2];
	}
}
public void CheckAutoShoot(int client, int buttons)
{
	if(buttons & IN_ATTACK && !(prev_buttons[client] & IN_ATTACK))
	{
		if(g_bFirstShot[client])
		{
			g_bFirstShot[client] = false;
			g_iLastShotTick[client] = g_iCmdNum[client];
		}
		else if(g_iCmdNum[client] - g_iLastShotTick[client] <= 10 && !g_bFirstShot[client])
		{
			g_bShootSpam[client] = true;
			g_iAutoShoot[client]++;
			g_iLastShotTick[client] = g_iCmdNum[client];
		}
		else
		{
			if(g_iAutoShoot[client] >= 20)
			{
				FormatEx(discord, sizeof(discord), "%N %s has been detected for AutoShoot Script! (%i)", client, nonprime[client]?"[Non-Prime]":"", g_iAutoShoot[client]);
				SendMessageToAdmins(discord);
				FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **AutoShoot Script**! (%i)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iAutoShoot[client]);
				SendMessageToDiscord("anticheat", discord);
			}
			g_iAutoShoot[client] = 0;
			g_bShootSpam[client] = false;
			g_bFirstShot[client] = true;
		}
	}
}
public void CheckWallTrace(int client, float angles[3])
{
	float vOrigin[3], AnglesVec[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, AnglesVec);
	Handle trace = TR_TraceRayFilterEx(vOrigin, AnglesVec, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);

	if(TR_DidHit(trace))
	{
		int target = TR_GetEntityIndex(trace);
		if((target > 0) && (target <= MaxClients) && GetClientTeam(target) != GetClientTeam(client) && IsPlayerAlive(target) && IsPlayerAlive(client))
			g_iWallTrace[client]++;
		else g_iWallTrace[client] = 0;
	}
	else g_iWallTrace[client] = 0;
	delete trace;

	float tickrate = 1.0 / GetTickInterval();
	if(g_iWallTrace[client] >= RoundToZero(tickrate))
	{
		g_iWallTraceDetectionCount[client]++;
		if(g_iWallTraceDetectionCount[client] >= 3)
		{
			FormatEx(discord, sizeof(discord), "%N %s has been detected for **WallTracing**!", client, nonprime[client]?"[Non-Prime]":"");
			SendMessageToAdmins(discord);
			FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **WallTracing**!", client, f_authid[client], nonprime[client]?"[Non-Prime]":"");
			SendMessageToDiscord("anticheat", discord);
			g_iWallTraceDetectionCount[client] = 0;
		}
		g_iWallTrace[client] = 0;
	}
}
public void CheckPerfectStrafe(int client, int mousedx, int buttons)
{
	if(mousedx > 0 && turnRight[client])
	{
		if(!(prev_buttons[client] & IN_MOVERIGHT) && buttons & IN_MOVERIGHT && !(buttons & IN_MOVELEFT))
		{
			g_iStrafeCount[client]++;
			CheckPerfCount(client);
		}
		else
		{
			if(g_iStrafeCount[client] >= 10)
			{
				FormatEx(discord, sizeof(discord), "%N %s detected for %i Consistant Perfect Strafes.", client, nonprime[client]?"[Non-Prime]":"", g_iStrafeCount[client]);
				SendMessageToAdmins(discord);
				FormatEx(discord, sizeof(discord), "**%N** (%s) %s detected for **%i** Consistant Perfect Strafes.", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iStrafeCount[client]);
				SendMessageToDiscord("anticheat", discord);
			}
			g_iStrafeCount[client] = 0;
		}
		turnRight[client] = false;
	}
	else if(mousedx < 0 && !turnRight[client])
	{
		if(!(prev_buttons[client] & IN_MOVELEFT) && buttons & IN_MOVELEFT && !(buttons & IN_MOVERIGHT))
		{
			g_iStrafeCount[client]++;
			CheckPerfCount(client);
		}
		else
		{
			if(g_iStrafeCount[client] >= 10)
			{
				FormatEx(discord, sizeof(discord), "%N %s detected for %i Consistant Perfect Strafes.", client, nonprime[client]?"[Non-Prime]":"", g_iStrafeCount[client]);
				SendMessageToAdmins(discord);
				FormatEx(discord, sizeof(discord), "**%N** (%s) %s detected for **%i** Consistant Perfect Strafes.", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iStrafeCount[client]);
				SendMessageToDiscord("anticheat", discord);
			}
			g_iStrafeCount[client] = 0;
		}
		turnRight[client] = true;
	}
}
public void CheckPerfCount(int client)
{
	if(g_iStrafeCount[client] >= 15)
	{
		FormatEx(discord, sizeof(discord), "%N %s has been detected for Consistant Perfect Strafes! (Banned)", client, nonprime[client]?"[Non-Prime]":"");
		SendMessageToAdmins(discord);
		FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **Consistant Perfect Strafes**! (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"");
		SendMessageToDiscord("anticheat", discord);
		SBBanPlayer(0, client, 0, "Mutli-Hack");
		g_iStrafeCount[client] = 0;
	}
}
public void StopBacktracking(int client, int &tickcount, int buttons)
{
	if(tickcount < g_iTickCount[client] && (buttons & IN_ATTACK) > 0 && IsPlayerAlive(client))
		tickcount = ++g_iTickCount[client];
	g_iTickCount[client] = tickcount;
}
public void CheckAHKStrafe(int client, int mouse)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	if(prev_OnGround[client] && !(GetEntityFlags(client) & FL_ONGROUND))
		g_fJumpPos[client] = vec[2];

	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		if((mouse >= 10 || mouse <= -10) && g_fJumpPos[client] < vec[2])
		{
			if(mouse == g_iMousedx_Value[client] || mouse == g_iMousedx_Value[client] * -1)
			{
				g_iMousedxCount[client]++;
			}
			else
			{
				g_iMousedx_Value[client] = mouse;
				g_iMousedxCount[client] = 0;
			}

			if(g_iMousedxCount[client] >= 25)
			{
				g_iMousedxCount[client] = 0;
				g_iAHKStrafeDetection[client]++;

				if(g_iAHKStrafeDetection[client] >= 10)
				{
					FormatEx(discord, sizeof(discord), "%N %s detected for AHK Strafe! [%i Infractions]", client, nonprime[client]?"[Non-Prime]":"", g_iAHKStrafeDetection[client]);
					SendMessageToAdmins(discord);
					FormatEx(discord, sizeof(discord), "**%N** (%s) %s detected for AHK Strafe! [%i Infractions]", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iAHKStrafeDetection[client]);
					SendMessageToDiscord("anticheat", discord);
					g_iAHKStrafeDetection[client] = 0;
				}
			}
		}
	}
}
public bool TraceEntityFilterPlayer(int entity, int mask, any data)
{
    return data != entity;
}
public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == 0) return false;
	else return entity != data && 0 < entity <= MaxClients;
}
public void SetDefaults(int client)
{
	g_iCmdNum[client] = 0;
	prev_sidemove[client] = 0.0;
	g_iPerfSidemove[client] = 0;
	prev_buttons[client] = 0;
	g_bShootSpam[client] = false;
	g_iLastShotTick[client] = 0;
	g_bFirstShot[client] = true;
	g_iAutoShoot[client] = 0;
	g_iTriggerBotCount[client] = 0;
	g_iTicksOnPlayer[client] = 0;
	g_iPrev_TicksOnPlayer[client] = 1;
	g_iMacroCount[client] = 0;
	g_iMacroDetectionCount[client] = 0;
	g_fJumpStart[client] = 0.0;
	g_fDefuseTime[client] = 0.0;
	g_iWallTrace[client] = 0;
	g_iWallTraceDetectionCount[client] = 0;
	g_iStrafeCount[client] = 0;
	turnRight[client] = true;
	g_iTickCount[client] = 0;
	prev_mousedx[client] = 0;
	g_iAHKStrafeDetection[client] = 0;
	g_iMousedx_Value[client] = 0;
	g_iMousedxCount[client] = 0;
	g_fJumpPos[client] = 0.0;
	prev_OnGround[client] = true;
	detectEzFrags[client] = false;
	detectEzFrags_count[client] = 0;
	for(int i = 0; i < 30; i++)
		g_iJumpsSent[client][i] = 0;
	g_iJumpsSentIndex[client] = 0;
}
bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}
public float NormalizeAngle(float angle)
{
	float newAngle = angle;
	while (newAngle <= -180.0) newAngle += 360.0;
	while (newAngle > 180.0) newAngle -= 360.0;
	return newAngle;
}
public float GetClientVelocity(int client, bool UseX, bool UseY, bool UseZ)
{
	float vVel[3];
	if(UseX) vVel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	if(UseY) vVel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	if(UseZ) vVel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	return GetVectorLength(vVel);
}
public void SendMessageToAdmins(const char[] message)
{
  for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Ban))
    CPrintToChat(i, "\x02[Anti-Cheat] \x07%s", message);
}
public void SendMessageToDiscord(const char[] channel, const char[] message)
{
	char sURL[512];
	if(GetChannelWebHook(channel, sURL, sizeof(sURL)))
	{
		Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sURL);
		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "content", message);
		SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/x-www-form-urlencoded");
		if(request == null || !SteamWorks_SetHTTPCallbacks(request, Callback_SendToDiscord) || !SteamWorks_SendHTTPRequest(request))
		{
			PrintToServer("[SendToDiscord] Failed to fire");
			delete request;
		}
	}
}
public int Callback_SendToDiscord(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if(!bFailure && bRequestSuccessful)
	{
		if(eStatusCode != k_EHTTPStatusCode200OK && eStatusCode != k_EHTTPStatusCode204NoContent)
		{
			LogError("[Callback_SendToDiscord] Failed with code [%i]", eStatusCode);
			SteamWorks_GetHTTPResponseBodyCallback(hRequest, Callback_Response);
		}
	}
	delete hRequest;
}
public int Callback_Response(const char[] sData)
{
	PrintToServer("[Callback_Response] %s", sData);
}
bool GetChannelWebHook(const char[] channel, char[] webhook, int length)
{
	KeyValues kv = new KeyValues("DiscordAPI");
	char sFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/discord.cfg");
	if(!FileExists(sFile)) return false;
	kv.ImportFromFile(sFile);
	if(!kv.GotoFirstSubKey()) return false;
	char sChannel[64];
	do
	{
		kv.GetSectionName(sChannel, sizeof(sChannel));
		if(StrEqual(sChannel, channel, false))
		{
			kv.GetString("url", webhook, length);
			return true;
		}
	}
	while (kv.GotoNextKey());
	delete kv;
	return false;
}
void Aimbot_AnalyzeAngles(int client)
{
	float vLastAngles[3], vAngles[3], fAngleDiff;
	int idx = g_iEyeIndex[client];

	for(int i = 0; i < g_iMaxAngleHistory; i++)
	{
		if(idx == g_iMaxAngleHistory) idx = 0;
		if(IsVectorZero(g_fEyeAngles[client][idx])) break;
		if(i == 0)
		{
			vLastAngles = g_fEyeAngles[client][idx];
			idx++;
			continue;
		}
		vAngles = g_fEyeAngles[client][idx];
		fAngleDiff = GetVectorDistance(vLastAngles, vAngles);
		if(fAngleDiff > 180) fAngleDiff = FloatAbs(fAngleDiff - 360);
		if(fAngleDiff > AIM_ANGLE_CHANGE)
		{
			Aimbot_Detected(client, fAngleDiff);
			break;
		}
		vLastAngles = vAngles;
		idx++;
	}
}
void Aimbot_Detected(int client, const float deviation)
{
	if(IsFakeClient(client) || !IsPlayerAlive(client))
		return;

	char sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));

	if(!IS_CLIENT(client) || !IsClientConnected(client)) return;
	if(IsClientInKickQueue(client)) return;

	CreateTimer(600.0, Timer_DecreaseCount, GetClientUserId(client));

	if(++g_iAimDetections[client] > 1)
	{
		FormatEx(discord, sizeof(discord), "%N %s has been detected for Aimbot! [#%i | %.0f° | %s] (Banned)", client, nonprime[client]?"[Non-Prime]":"", g_iAimDetections[client], deviation, sWeapon);
		SendMessageToAdmins(discord);
		FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **Aimbot**! [**#%i** | **%.0f°** | **%s**] (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iAimDetections[client], deviation, sWeapon);
		SendMessageToDiscord("anticheat", discord);
		SBBanPlayer(0, client, 0, "Aimbot");
	}
}
void Aimbot_ClearAngles(int client)
{
	g_iEyeIndex[client] = 0;
	for(int i = 0; i < g_iMaxAngleHistory; i++)
	{
		ZeroVector(g_fEyeAngles[client][i]);
	}
}
public void CheckClientName(int client)
{
	char steamid64[512];
	GetClientAuthId(client, AuthId_SteamID64, steamid64, sizeof(steamid64));
	char url[PLATFORM_MAX_PATH];
	Format(url, sizeof(url), "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=6723D12183165E70AA8630ED992F01C7&steamids=%s", steamid64);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	if(request == null) return;
	SteamWorks_SendHTTPRequest(request);
	float timeouttime = GetEngineTime() + 5.0;
	int responsesize = 0;
	while(GetEngineTime() < timeouttime)
	{
		SteamWorks_GetHTTPResponseBodySize(request, responsesize);
		if(responsesize > 0)
		{
			OnInfoReceived(request, false, true, k_EHTTPStatusCode200OK);
			checking_name = client;
			return;
		}
	}
	OnInfoReceived(request, true, false, k_EHTTPStatusCode5xxUnknown);
}
public int OnInfoReceived(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode)
{
	if(!failure && requestSuccessful && statusCode == k_EHTTPStatusCode200OK)
		SteamWorks_GetHTTPResponseBodyCallback(request, APIWebResponse);
	delete request;
	return 0;
}
public void APIWebResponse(char[] response)
{
	KeyValues Kv = new KeyValues("response");
	Kv.SetEscapeSequences(true);
	if(Kv.ImportFromString(response))
	{
		if(Kv.JumpToKey("players"))
		{
			if(Kv.JumpToKey("0"))
			{
				char szGameName[MAX_NAME_LENGTH]; GetClientName(checking_name, szGameName, sizeof(szGameName));
				char szSteamName[MAX_NAME_LENGTH]; Kv.GetString("personaname", szSteamName, sizeof(szSteamName));
				if(!StrEqual(szGameName, szSteamName, true))
				{
					FormatEx(discord, sizeof(discord), "%N %s has been detected for Name Stealer/Faker! [Game Name %s | Steam Name: %s]", checking_name, nonprime[checking_name]?"[Non-Prime]":"", szGameName, szSteamName);
					SendMessageToAdmins(discord);
					FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **Name Stealer/Faker**! [Game Name **%s** | Steam Name: **%s**]", checking_name, f_authid[checking_name], nonprime[checking_name]?"[Non-Prime]":"", szGameName, szSteamName);
					SendMessageToDiscord("anticheat", discord);
					checking_name = 0;
					delete Kv;
				}
			}
			else delete Kv;
		}
		else delete Kv;
	}
	else delete Kv;
	checking_name = 0;
}
public void OnClientSettingsChanged(int client)
{
	//if(!IsValidClient(checking_name) && IsValidClient(client, true))
	//	CheckClientName(client);
}
void AutoTrigger_Detected(int client, int method)
{
	if(!IsFakeClient(client) && IsPlayerAlive(client) && ++g_iDetections[method][client] >= 10)
	{
		switch(method)
		{
			case METHOD_AUTOFIRE:
			{
				FormatEx(discord, sizeof(discord), "%N %s has been detected for Auto-Fire! [#%i] (Banned)", client, nonprime[client]?"[Non-Prime]":"", g_iDetections[method][client]);
				SendMessageToAdmins(discord);
				FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **Auto-Fire**! [**#%i**] (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", g_iDetections[method][client]);
				SendMessageToDiscord("anticheat", discord);
				SBBanPlayer(0, client, 0, "Auto-Fire");
			}
		}
		g_iDetections[method][client] = 0;
	}
}
stock void StringToLower(char[] input)
{
	int length = strlen(input);
	for(int i = 0; i < length; i++)
		input[i] = CharToLower(input[i]);
}
stock void ReplicateToAll(Handle convar, const char[] value)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendConVarValue(i, convar, value);
		}
	}
}
stock void GetQueryResultString(ConVarQueryResult CResult, char[] sResult, int iSize)
{
	switch(CResult)
	{
		case ConVarQuery_Okay: strcopy(sResult, iSize, "Okay");
		case ConVarQuery_NotFound: strcopy(sResult, iSize, "Not Found");
		case ConVarQuery_NotValid: strcopy(sResult, iSize, "Not Valid");
		case ConVarQuery_Protected: strcopy(sResult, iSize, "Protected");
		default: FormatEx(sResult, iSize, "Unknown (%d)", CResult);
	}
}
stock void GetCompTypeString(CvarComp CCompType, char[] sCompType, int iSize)
{
	switch(CCompType)
	{
		case Comp_Equal: strcopy(sCompType, iSize, "equal");
		case Comp_StrEqual: strcopy(sCompType, iSize, "strequal");
		case Comp_Replicated: strcopy(sCompType, iSize, "replicated");
		case Comp_Greater: strcopy(sCompType, iSize, "greater");
		case Comp_Less: strcopy(sCompType, iSize, "less");
		case Comp_Between: strcopy(sCompType, iSize, "between");
		case Comp_Outside: strcopy(sCompType, iSize, "outside");
		case Comp_NonExist: strcopy(sCompType, iSize, "nonexist");
		default: strcopy(sCompType, iSize, "");
	}
}
public Action EventPlayerDeath_Pre(Event event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!IsValidClient(attacker)) return Plugin_Continue;
	detectEzFrags[attacker] = true;
	CreateTimer(0.1, detectEzFrags_reset, attacker);
	return Plugin_Continue;
}
public Action detectEzFrags_reset(Handle timer, int client)
{
	if(!IsValidClient(client)) return Plugin_Stop;
	detectEzFrags[client] = false;
	return Plugin_Continue;
}
public Action Command_Chat(int client, const char[] command, int args)
{
	if(IsValidClient(client) && detectEzFrags[client])
	{
		char text[512];
		text[0] = '\0';
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
		if(
		StrEqual(text, "Visit www.EZfrags.co.uk for the finest public & private CS:GO cheats", false) ||
		StrEqual(text, "If I was cheating, I'd use www.EZfrags.co.uk", false) ||
		StrEqual(text, "Stop being a noob! Get good with www.EZfrags.co.uk", false) ||
		StrEqual(text, "Think you could do better? Not without www.EZfrags.co.uk", false) ||
		StrEqual(text, "I'm not using www.EZfrags.co.uk, you're just bad", false))
		{
			detectEzFrags_count[client]++;
			FormatEx(discord, sizeof(discord), "%N %s has been detected for EZfrags cheats! (Check #%i)", client, nonprime[client]?"[Non-Prime]":"", detectEzFrags_count[client]);
			SendMessageToAdmins(discord);
			FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **EZfrags cheats**! (Check #%i)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"", detectEzFrags_count[client]);
			SendMessageToDiscord("anticheat", discord);
			if(detectEzFrags_count[client] > 1)
			{
				FormatEx(discord, sizeof(discord), "%N %s has been detected for EZfrags cheats! (Banned)", client, nonprime[client]?"[Non-Prime]":"");
				SendMessageToAdmins(discord);
				FormatEx(discord, sizeof(discord), "**%N** (%s) %s has been detected for **EZfrags cheats**! (Banned)", client, f_authid[client], nonprime[client]?"[Non-Prime]":"");
				SendMessageToDiscord("anticheat", discord);
				SBBanPlayer(0, client, 0, "Mutli-Hack");
			}
		}
	}
	return Plugin_Continue;
}
