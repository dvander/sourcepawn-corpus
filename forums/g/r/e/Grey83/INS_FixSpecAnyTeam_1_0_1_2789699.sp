/*
 * @Description: 修复mp_forcecamera设置为0后导致服务器崩溃的问题。好用的话Github给颗星吧。
 * @Author: Gandor233
 * @Github: https://github.com/gandor233
 * @Date: 2022-09-26 14:23:42
 * @LastEditTime: 2022-09-26 14:51:27
 * @LastEditors: Gandor233
 */
#pragma semicolon 1

static const char
	PL_NAME[]	= "[INS] FixSpecAnyTeam",
	PL_VER[]	= "1.0.1 (rewritten by Grey83)";

ConVar
	hCamera;
bool
	bEnable;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Fix any team spectator mode crash server bug for insurgency(2014).",
	author		= "Gandor233",
	url			= "https://github.com/gandor233/INS_FixSpecAnyTeam"
}

public void OnPluginStart()
{
	if(!(hCamera = FindConVar("mp_forcecamera")))
		SetFailState("Unable to find convar 'mp_forcecamera'!");

	CreateConVar("sm_ins_fsat_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar = CreateConVar("sm_spec_any_team", "0", "(bool) Enable spec any team", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange);
	bEnable = cvar.BoolValue;

	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_spawn", Event_SpawnPost, EventHookMode_PostNoCopy);
}

public void CVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void Event_PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	if(!hCamera.IntValue && GetAlivePlayerCount() <= 1) hCamera.IntValue = 1;
}

public void Event_SpawnPost(Event event, const char[] name, bool dontBroadcast)
{
	if(bEnable) RequestFrame(OnPlayerSpawnPost);
}

public void OnPlayerSpawnPost()
{
	if(GetAlivePlayerCount() > 0) hCamera.IntValue = 0;
}

stock int GetAlivePlayerCount()
{
	int num;
	for(int i = 1; num < 2 && i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i)) num++;
	return num;
}