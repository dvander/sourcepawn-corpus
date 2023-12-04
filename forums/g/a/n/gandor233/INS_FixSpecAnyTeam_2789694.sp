/*
 * @Description: mp_forcecamera设置为0时，存活玩家不能少于2个。
 * @Author: Gandor233
 * @Github: https://github.com/gandor233
 * @Date: 2022-09-26 14:23:42
 * @LastEditTime: 2022-09-26 17:21:16
 * @LastEditors: Gandor233
 */
#pragma semicolon 1

static const char
    PL_NAME[]	= "[INS] FixSpecAnyTeam",
    PL_VER[]	= "1.0.2";

ConVar hCamera;
bool bEnable;

public Plugin myinfo =
{
    name		= PL_NAME,
    version		= PL_VER,
    description	= "Fix any team spectator mode crash server bug for insurgency(2014).",
    author		= "Gandor233 | Grey83",
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

    HookEvent("round_end", Event_RoundEndPre, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
    HookEvent("player_spawn", Event_SpawnPost, EventHookMode_PostNoCopy);
}
public void CVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    bEnable = cvar.BoolValue;
}

public void Event_RoundEndPre(Event event, const char[] name, bool dontBroadcast)
{
    if (!hCamera.IntValue) hCamera.IntValue = 1;
}
public void Event_PlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
    if(!hCamera.IntValue && GetAlivePlayerCount() <= 2) hCamera.IntValue = 1;
}
public void OnClientDisconnect(int client)
{
    if (!hCamera.IntValue && GetAlivePlayerCount() <= 2)  hCamera.IntValue = 1;
}

public void Event_SpawnPost(Event event, const char[] name, bool dontBroadcast)
{
    if(bEnable) RequestFrame(OnPlayerSpawnPost);
}
public void OnPlayerSpawnPost()
{
    if(GetAlivePlayerCount() > 2) hCamera.IntValue = 0;
}

stock int GetAlivePlayerCount()
{
    int num;
    for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i)) num++;
    return num;
}