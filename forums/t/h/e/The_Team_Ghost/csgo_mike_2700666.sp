/**
 * Maps I'd use:
 * https://steamcommunity.com/sharedfiles/filedetails/?id=646308893
 * https://steamcommunity.com/sharedfiles/filedetails/?id=464720915
 * https://steamcommunity.com/sharedfiles/filedetails/?id=475916587
 * https://steamcommunity.com/sharedfiles/filedetails/?id=381587877
 * https://steamcommunity.com/sharedfiles/filedetails/?id=449180221
 */

#pragma semicolon 1

#define PLUGIN_AUTHOR "Yimura"
#define PLUGIN_VERSION "0.1.4"

#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3

#define STATE_NONE 0
#define STATE_MAP_LOADED 1
#define STATE_WARMUP 2
#define STATE_PREP 3
#define STATE_ACTIVE 4
#define STATE_1V1 5
#define STATE_END 6

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

#pragma newdecls required

bool
    g_bDebug = false,

    g_bPluginState = false,
    g_bSetCvars = false,

    g_bWarmup = false,
    g_bWasMike[MAXPLAYERS+1] = { false, ... },

    g_bDefaultSolidTeammates = false,

    g_bDefaultDeathDropGun = false,
    g_bDefaultDeathDropDefuser = false,
    g_bDefaultDeathDropGrenade = false,

    g_bDefaultPlayerCashCV = false,
    g_bDefaultTeamCashCV = false;

ConVar
    g_cvPluginState,

    g_cvMMRoundTime,
    g_cvSetupTimer,

    g_cvIgnoreRoundWinCondition,

    g_cvLimitTeams,
    g_cvTeamBalance,

    g_cvMikeSpeed,
    g_cvSurvivorSpeed,

    g_cvSurvivorTeamName,
    g_cvMikeTeamName,

    g_cvTeamNameCT,
    g_cvTeamNameT,

    g_cvRoundEndDelay,
    g_cvFreezeTime,
    g_cvRestartGame,

    g_cvDeathDropGun,
    g_cvDeathDropDefuser,
    g_cvDeathDropGrenade,

    g_cvSolidTeammates,
    g_cvBuyTime,

    g_cvRoundTime,
    g_cvRoundTimeDefuse,
    g_cvRoundTimeHostage,

    g_cvPlayerCashAward,
    g_cvTeamCashAward;

float
    g_fRoundEndDelay,

    g_fMikeSpeed = 400.0,
    g_fSurvivorSpeed = 320.0,

    g_fSurvivorDefSpeed = 320.0,
    g_fMikeDefSpeed = 400.0;

Handle
    g_hSetSpeedTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... },

    g_hPrepareGameTimer = INVALID_HANDLE,
    //g_hEndGameTimer = INVALID_HANDLE,
    g_hSlowDownTimer = INVALID_HANDLE;

int
    g_iGameState = STATE_NONE,
    g_iClientClip[MAXPLAYERS+1] = { 10, ... },

    g_iDefaultLimitTeams,

    g_iDefaultFreezeTime,
    g_iDefaultBuyTime,
    g_iDefaultTeamBalance,

    g_iDefaultRoundTime,
    g_iDefaultRoundDefuseTime,
    g_iDefaultRoundHostageTime,

    g_iMike,
    g_iSetupTimer;

public Plugin myinfo = {
        name = "[CS:GO] Mike Myers",
        author = PLUGIN_AUTHOR,
        description = "",
        version = PLUGIN_VERSION,
        url = ""
};

public void OnPluginStart()
{
    if (GetEngineVersion() != Engine_CSGO)
        SetFailState("[MM] This plugin was made to be ran on CS:GO only!");

    CreateConVar("sm_mikemyers_version", PLUGIN_VERSION, "Mike Myers Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_cvPluginState = CreateConVar("sm_mm_enable", "1", "Enable/Disable Mike Myers gamemode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvMMRoundTime = CreateConVar("sm_mm_roundtime", "5", "Set the round time before the CT's win.", FCVAR_NOTIFY, true, 0.0, true, 25.0);
    g_cvSetupTimer = CreateConVar("sm_mm_preptimer", "30", "Preparation timer before Mike Myers will be chosen.", FCVAR_NOTIFY, true, 0.0, true, 60.0);

    g_cvSurvivorSpeed = CreateConVar("sm_mm_survivorspeed", "320.0", "Change the speed of the survivors.", FCVAR_NOTIFY, true, 220.0, true, 470.0);
    g_cvMikeSpeed = CreateConVar("sm_mm_mikespeed", "400.0", "Change the speed of Mike Myers", FCVAR_NOTIFY, true, 220.0, true, 470.0);

    g_cvSurvivorTeamName = CreateConVar("sm_mm_survivorteamname", "Survivors", "Set the team name of the survivors", FCVAR_NOTIFY);
    g_cvMikeTeamName = CreateConVar("sm_mm_miketeamname", "Mike Myers", "Set the team name of Mike Myers", FCVAR_NOTIFY);

    // Generic Source Events
    HookEvent("player_team", OnPlayerChangeTeam);

    HookEvent("round_start", OnRoundStart);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("round_start", PreRoundStart, EventHookMode_Pre);

    HookEvent("round_announce_warmup", OnWarmupStart, EventHookMode_Post);
    HookEvent("round_announce_match_start", OnWarmupEnd);

    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_spawn", PrePlayerSpawn, EventHookMode_Pre);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_death", PrePlayerDeath, EventHookMode_Pre);

    if (g_bDebug)
        RegConsoleCmd("sm_mm_gamestate", Command_GameState, "Print out the current active gamestate");
    RegAdminCmd("sm_mm_respawn", Command_Respawn, ADMFLAG_ROOT, "Respawn a player that was unfairly killed.");

    int pluginEnabled = g_cvPluginState.IntValue;
    if (pluginEnabled == 1)
        g_bPluginState = true;
    else
        g_bPluginState = false;

    AddCommandListener(OnCommandDropWeapon, "drop");

    g_cvPluginState.AddChangeHook(OnPluginStateToggled);

    g_cvPlayerCashAward = FindConVar("mp_playercashawards");
    g_cvTeamCashAward = FindConVar("mp_teamcashawards");

    g_cvRoundTimeDefuse = FindConVar("mp_roundtime_defuse");
    g_cvRoundTimeHostage = FindConVar("mp_roundtime_hostage");
    g_cvRoundTime = FindConVar("mp_roundtime");

    g_cvBuyTime = FindConVar("mp_buytime");

    g_cvFreezeTime = FindConVar("mp_freezetime");
    g_cvRestartGame = FindConVar("mp_restartgame");
    g_cvRoundEndDelay = FindConVar("mp_round_restart_delay");

    g_cvDeathDropGun = FindConVar("mp_death_drop_gun");
    g_cvDeathDropDefuser = FindConVar("mp_death_drop_defuser");
    g_cvDeathDropGrenade = FindConVar("mp_death_drop_grenade");

    g_cvSolidTeammates = FindConVar("mp_solid_teammates");

    g_cvTeamBalance = FindConVar("mp_autoteambalance");
    g_cvLimitTeams = FindConVar("mp_limitteams");

    g_cvTeamNameCT = FindConVar("mp_teamname_1");
    g_cvTeamNameT = FindConVar("mp_teamname_2");

    g_cvIgnoreRoundWinCondition = FindConVar("mp_ignore_round_win_conditions");

    for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		OnClientPutInServer(i);
	}

    AutoExecConfig(true, "mike_myers");
}

public void OnPluginEnd()
{
    ResetCvars();
}

/**
 * Public Events
 */
public void OnMapStart()
{
    if (!g_bPluginState) return;

    g_iGameState = STATE_MAP_LOADED;
}

public void OnMapEnd()
{
    g_iGameState = STATE_NONE;

    ResetCvars();
}

public void OnClientPutInServer(int client)
{
    if (!g_bPluginState) return;

    g_bWasMike[client] = false;

    SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
    SDKHook(client, SDKHook_WeaponDrop, SDK_OnWeaponDrop);
}
public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
    SDKUnhook(client, SDKHook_WeaponDrop, SDK_OnWeaponDrop);

    // Check if any clients are remaining if not then we cleanup
    for(int i = 0; i < MaxClients; i++)
        if(IsValidClient(i))
            return;

    g_iGameState = STATE_MAP_LOADED;
    g_bWarmup = false;

    if (g_hPrepareGameTimer != INVALID_HANDLE)
    {
        KillTimer(g_hPrepareGameTimer);
        g_hPrepareGameTimer = INVALID_HANDLE;
    }

    ResetCvars();

    g_fMikeSpeed = g_fMikeDefSpeed;
    g_fSurvivorSpeed = g_fSurvivorDefSpeed;
}

public void OnEntityCreated(int iEnt, const char[] cClassName)
{
    if (iEnt != INVALID_ENT_REFERENCE && IsValidEdict(iEnt) && StrContains(cClassName, "Weapon", false) != -1 && StrContains(cClassName, "Weaponworldmodel", false) == -1)
        SDKHook(iEnt, SDKHook_Reload, SDK_OnReload);
}

public void OnEntityDestroyed(int iEnt)
{
    if (iEnt != INVALID_ENT_REFERENCE)
        SDKUnhook(iEnt, SDKHook_Reload, SDK_OnReload);
}

/**
 * CommandListeners
 */
Action OnCommandDropWeapon(int client, const char[] command, int args)
{
    if (!g_bPluginState || g_iGameState != STATE_ACTIVE) return Plugin_Continue;

    return Plugin_Stop;
}

/**
 * SDK Hooks
 */
Action SDK_OnWeaponDrop(int client, int weapon)
{
    if (!g_bPluginState || g_iGameState != STATE_ACTIVE) return Plugin_Continue;

    return Plugin_Continue;
}
Action SDK_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bPluginState || g_iGameState != STATE_ACTIVE) return Plugin_Continue;

    if (IsValidClient(attacker))
    {
        int team = GetClientTeam(attacker);

        if (IsValidClient(victim))
        {
            int otherTeam = GetClientTeam(victim);
            if (otherTeam == TEAM_T && team == TEAM_CT && g_iGameState != STATE_1V1)
            {
                if (g_hSlowDownTimer != INVALID_HANDLE) {
                    KillTimer(g_hSlowDownTimer);
                    g_hSlowDownTimer = INVALID_HANDLE;
                }

                //SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", 0.8);
                g_fMikeSpeed = 260.0;
                g_hSlowDownTimer = CreateTimer(3.0, Timer_RestoreSpeed, victim);
            }
        }

        if (team == TEAM_CT && g_iGameState != STATE_1V1) {
            return Plugin_Stop;
        }
    }

    char cWeapon[32];
    if(inflictor > 0 && inflictor <= MaxClients)
	{
		int weapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
		GetEdictClassname(weapon, cWeapon, 32);
	}

    if(StrContains(cWeapon, "knife") == -1 || !IsValidClient(attacker) || !IsValidClient(victim))
	   return Plugin_Continue;

    damage = float(GetClientHealth(victim) + GetClientArmor(victim));

    return Plugin_Changed;
}
Action SDK_OnPreThink(int client)
{
    if (IsValidClient(client, true))
    {
        int iTeam = GetClientTeam(client);
        if (iTeam == TEAM_T)
            SetSpeed(client, g_fMikeSpeed);
        else if (iTeam == TEAM_CT)
            SetSpeed(client, g_fSurvivorSpeed);
    }

    return Plugin_Continue;
}
Action SDK_OnReload(int iWeapon)
{
    if (iWeapon != INVALID_ENT_REFERENCE && IsValidEdict(iWeapon))
    {
        if (GetEntProp(iWeapon, Prop_Data, "m_iClip1") >= 2)
            return Plugin_Stop;

        int client = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwner");

        if (g_iClientClip[client] == 0)
            return Plugin_Continue;

        if (g_iClientClip[client] > 0)
            SetAmmo(client, CS_SLOT_SECONDARY, 0, 2);
        g_iClientClip[client] -= 2;

        CreateTimer(2.17, Timer_SetClientAmmo, client);
    }

    return Plugin_Continue;
}

/**
 * Match Events
 */
Action OnWarmupStart(Event event, const char[] name, bool dontBroadCast)
{
    if (!g_bPluginState) return Plugin_Continue;

    g_iGameState = STATE_WARMUP;

    return Plugin_Continue;
}
Action OnWarmupEnd(Event event, const char[] name, bool dontBroadCast)
{
    if (!g_bPluginState) return Plugin_Continue;

    g_bWarmup = false;

    return Plugin_Continue;
}

Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadCast)
{
    if (!g_bPluginState || (g_iGameState != STATE_ACTIVE && g_iGameState != STATE_PREP && g_iGameState != STATE_END)) return Plugin_Continue;
    int client = GetClientOfUserId(event.GetInt("userid", -1));
    if (client == -1) return Plugin_Continue;

    if (g_iGameState == STATE_ACTIVE) {
        ForcePlayerSuicide(client);

        return Plugin_Handled;
    }

    SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
    SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
    SetEntProp(client, Prop_Send, "m_iAccount", 0);

    int iTeam = GetClientTeam(client);
    if (iTeam == TEAM_CT)
    {
        Client_RemoveAllWeapons(client);
        GivePlayerItem(client, "weapon_usp_silencer");

        g_iClientClip[client] = 10;

        CreateTimer(0.1, Timer_SetClientAmmo, client);
    }
    else if (iTeam == TEAM_T)
    {
        Client_RemoveAllWeapons(client);
        GivePlayerItem(client, "weapon_knife_t");
    }

    g_hSetSpeedTimer[client] = CreateTimer(0.5, Timer_SetSpeed, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}
Action PrePlayerSpawn(Event event, const char[] name, bool dontBroadCast)
{
    if (!g_bPluginState) return Plugin_Continue;

    if (g_iGameState == STATE_MAP_LOADED)
        g_bWarmup = true;

    return Plugin_Continue;
}
Action OnPlayerDeath(Event event, const char[] name, bool dontBroadCast)
{
    int client = GetClientOfUserId(event.GetInt("userid", -1));
    if (client == -1) return Plugin_Continue;

    if (g_hSetSpeedTimer[client] != INVALID_HANDLE)
    {
        KillTimer(g_hSetSpeedTimer[client]);
        g_hSetSpeedTimer[client] = INVALID_HANDLE;
    }

    Check1v1();

    return Plugin_Continue;
}
Action PrePlayerDeath(Event event, const char[] name, bool dontBroadCast)
{
    if (!g_bPluginState || g_iGameState != STATE_ACTIVE) return Plugin_Continue;

    int
        victim = GetClientOfUserId(event.GetInt("userid")),
        attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (victim != attacker)
        event.BroadcastDisabled = true;

    if (attacker != 0 && IsValidClient(attacker) && !IsFakeClient(attacker))
        event.FireToClient(attacker);
    //if (g_bGameState && victim != g_iMike)
    //    ChangeClientTeam(victim, TEAM_SPEC);
    if (g_iGameState != STATE_ACTIVE && g_iGameState != STATE_END)
        CreateTimer(0.1, Timer_RespawnPlayer, victim);
    return Plugin_Continue;
}

Action PreRoundStart(Event event, const char[] name, bool dontBroadCast)
{
    if (g_bDebug)
        PrintToServer("[MM] Event: PreRoundStart, current gamestate %i", g_iGameState);

    if (!g_bPluginState || (g_iGameState != STATE_WARMUP && g_iGameState != STATE_MAP_LOADED)) return Plugin_Continue;

    if (g_iGameState == STATE_MAP_LOADED)
        g_bWarmup = true;

    if (g_iGameState == STATE_WARMUP)
        SetCvars();

    g_iGameState = STATE_PREP;

    if (g_bWarmup && g_iGameState == STATE_PREP)
    {
        g_bWarmup = false;
        g_iGameState = STATE_WARMUP;

        return Plugin_Continue;
    }

    for(int i = 1; i < MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            int team = GetClientTeam(i);
            if (team == TEAM_T)
            {
                ChangeClientTeam(i, TEAM_CT);
                if (!IsPlayerAlive(i))
                    CS_RespawnPlayer(i);
            }
        }
    }

    g_cvRestartGame.SetInt(1);

    return Plugin_Continue;
}
Action OnRoundStart(Event event, const char[] name, bool dontBroadCast)
{
    if (g_bDebug)
        PrintToServer("[MM] Event: OnRoundStart, current gamestate %i", g_iGameState);

    if (!g_bPluginState || (g_iGameState != STATE_END && g_iGameState != STATE_PREP)) return Plugin_Continue;

    g_iGameState = STATE_PREP;
    if (g_hPrepareGameTimer != INVALID_HANDLE) KillTimer(g_hPrepareGameTimer);
    g_hPrepareGameTimer = CreateTimer(1.0, Timer_PrepareGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Continue;
}
Action OnRoundEnd(Event event, const char[] name, bool dontBroadCast)
{
    if (g_bDebug)
        PrintToServer("[MM] Event: OnRoundEnd, current gamestate %i", g_iGameState);

    if (!g_bPluginState || g_iGameState == STATE_WARMUP || g_iGameState == STATE_MAP_LOADED || g_iGameState == STATE_PREP) return Plugin_Continue;

    g_iGameState = STATE_END;
    g_fMikeSpeed = g_fMikeDefSpeed;
    g_fSurvivorSpeed = g_fSurvivorDefSpeed;

    if (g_hPrepareGameTimer != INVALID_HANDLE)
    {
        KillTimer(g_hPrepareGameTimer);
        g_hPrepareGameTimer = INVALID_HANDLE;
    }

    CreateTimer(g_fRoundEndDelay-0.2, Timer_SwitchAllToSurvivor);

    return Plugin_Continue;
}

Action OnPlayerChangeTeam(Event event, const char[] name, bool dontBroadCast)
{
    if (g_bDebug)
        PrintToServer("[MM] Event: OnPlayerChangeTeam, current gamestate %i", g_iGameState);

    if (!g_bPluginState || g_iGameState != STATE_ACTIVE || g_iGameState != STATE_END) return Plugin_Continue;

    event.BroadcastDisabled = true;

    int client = GetClientOfUserId(event.GetInt("userid", -1));

    CreateTimer(0.1, Timer_CheckTeam, client);

    return Plugin_Continue;
}

/**
 * ConVar Changes
 */
void OnPluginStateToggled(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_bPluginState != convar.BoolValue)
        g_bPluginState = !g_bPluginState;

    if (g_bPluginState)
        SetCvars();
    else
        ResetCvars();
}

void SetCvars()
{
    if (g_bSetCvars) return;
    g_bSetCvars = true;

    g_bDefaultPlayerCashCV = g_cvPlayerCashAward.BoolValue;
    g_cvPlayerCashAward.SetBool(false);

    g_bDefaultTeamCashCV = g_cvTeamCashAward.BoolValue;
    g_cvTeamCashAward.SetBool(false);

    g_iDefaultRoundTime = g_cvRoundTime.IntValue;
    g_cvRoundTime.SetInt(g_cvMMRoundTime.IntValue);
    g_iDefaultRoundDefuseTime = g_cvRoundTimeDefuse.IntValue;
    g_cvRoundTimeDefuse.SetInt(0);
    g_iDefaultRoundHostageTime = g_cvRoundTimeHostage.IntValue;
    g_cvRoundTimeHostage.SetInt(0);

    g_iDefaultTeamBalance = g_cvTeamBalance.IntValue;
    g_cvTeamBalance.SetInt(0);

    g_iDefaultBuyTime = g_cvBuyTime.IntValue;
    g_cvBuyTime.SetInt(0);

    g_iDefaultFreezeTime = g_cvFreezeTime.IntValue;
    g_cvFreezeTime.SetInt(1);

    g_iSetupTimer = g_cvSetupTimer.IntValue;

    g_bDefaultDeathDropGun = g_cvDeathDropGun.BoolValue;
    g_bDefaultDeathDropDefuser = g_cvDeathDropDefuser.BoolValue;
    g_bDefaultDeathDropGrenade = g_cvDeathDropGrenade.BoolValue;
    g_cvDeathDropGun.SetBool(false);
    g_cvDeathDropDefuser.SetBool(false);
    g_cvDeathDropGrenade.SetBool(false);

    g_bDefaultSolidTeammates = g_cvSolidTeammates.BoolValue;
    g_cvSolidTeammates.SetBool(false);

    g_fMikeSpeed = g_cvMikeSpeed.FloatValue;
    g_fMikeDefSpeed = g_cvMikeSpeed.FloatValue;
    g_fSurvivorSpeed = g_cvSurvivorSpeed.FloatValue;
    g_fSurvivorDefSpeed = g_cvSurvivorSpeed.FloatValue;

    g_fRoundEndDelay = g_cvRoundEndDelay.FloatValue;

    g_iDefaultLimitTeams = g_cvLimitTeams.IntValue;
    g_cvLimitTeams.SetInt(0);

    char cTeamName[64];
    g_cvSurvivorTeamName.GetString(cTeamName, sizeof(cTeamName));
    g_cvTeamNameCT.SetString(cTeamName);

    g_cvMikeTeamName.GetString(cTeamName, sizeof(cTeamName));
    g_cvTeamNameT.SetString(cTeamName);
}

void ResetCvars()
{
    if (!g_bPluginState || !g_bSetCvars) return;
    g_bSetCvars = false;

    g_cvPlayerCashAward.SetBool(g_bDefaultPlayerCashCV);
    g_cvTeamCashAward.SetBool(g_bDefaultTeamCashCV);

    g_cvRoundTimeDefuse.SetInt(g_iDefaultRoundDefuseTime);
    g_cvRoundTimeHostage.SetInt(g_iDefaultRoundHostageTime);
    g_cvRoundTime.SetInt(g_iDefaultRoundTime);

    g_cvTeamBalance.SetInt(g_iDefaultTeamBalance);

    g_cvBuyTime.SetInt(g_iDefaultBuyTime);
    g_cvFreezeTime.SetInt(g_iDefaultFreezeTime);

    g_cvDeathDropGun.SetBool(g_bDefaultDeathDropGun);
    g_cvDeathDropDefuser.SetBool(g_bDefaultDeathDropDefuser);
    g_cvDeathDropGrenade.SetBool(g_bDefaultDeathDropGrenade);

    g_cvSolidTeammates.SetBool(g_bDefaultSolidTeammates);

    g_cvLimitTeams.SetInt(g_iDefaultLimitTeams);

    g_cvTeamNameCT.SetString("");
    g_cvTeamNameT.SetString("");
}

/**
 * Functions
 */
bool NeedsReset()
{
    for(int i = 0; i < sizeof(g_bWasMike); i++)
    {
        if (IsValidClient(i, true) && !g_bWasMike[i])
        {
            int iTeam = GetClientTeam(i);
            if (iTeam != TEAM_SPEC)
                return false;
        }
    }

    return true;
}
bool IsValidClient(int client, bool bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (!bAlive || IsPlayerAlive(client)))
	   return true;
	return false;
}

int GetAlivePlayerCount()
{
    int iPlayers = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i, true))
        {
            int team = GetClientTeam(i);
            if (team == TEAM_T || team == TEAM_CT) iPlayers++;
        }
    }
    return iPlayers;
}
int GetAliveInTeam(int iTeam)
{
    int iCTs = 0;
    for (int i = 1; i < MaxClients; i++)
    {
        if (IsValidClient(i, true))
        {
            int team = GetClientTeam(i);
            if (team == iTeam) iCTs++;
        }
    }
    return iCTs;
}
int GetLastSurvivorPlayer()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i, true))
        {
            int team = GetClientTeam(i);
            if (team == TEAM_CT)
                return i;
        }
    }
    return -1;
}
int GetNextMikeMyers()
{
    if (NeedsReset())
        for(int i = 0; i < sizeof(g_bWasMike); i++)
            g_bWasMike[i] = false;

    int count = 0;
    int[] clients = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i, true) && !g_bWasMike[i] && GetClientTeam(i) == TEAM_CT)
            clients[count++] = i;

    if (count == 0) return -1;

    int iRandom = GetRandomInt(0, count-1);
    g_bWasMike[clients[iRandom]] = true;

    return clients[iRandom];
}

void Check1v1()
{
    if (GetAlivePlayerCount() == 2 && GetAliveInTeam(TEAM_CT) == 1 && g_iGameState == STATE_ACTIVE)
    {
        int iLastSurvivor = GetLastSurvivorPlayer();
        if (iLastSurvivor == -1) return;

        g_iGameState = STATE_1V1;
        g_fSurvivorSpeed = g_fMikeDefSpeed;

        Client_RemoveAllWeapons(iLastSurvivor);
        GivePlayerItem(iLastSurvivor, "weapon_knife");
    }
}
void SetAmmo(int client, int wepslot, int clip, int ammo)
{
    int weapon = GetPlayerWeaponSlot(client, wepslot);
    if (IsValidEntity(weapon))
    {
        SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
        SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
        SetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);
    }
}
void SetSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", speed/250.0);
    SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
}

/**
 * Timers
 */
Action Timer_CheckTeam(Handle timer, int client)
{
    int team = GetClientTeam(client);
    if (team == TEAM_T && client != g_iMike)
        ChangeClientTeam(client, TEAM_CT);
    //else if (g_iGameState == 2 && team == TEAM_CT && client != g_iMike)
    //    ChangeClientTeam(client, TEAM_T);

    if (team == TEAM_CT && g_iGameState == STATE_PREP && !IsPlayerAlive(client))
        CS_RespawnPlayer(client);

    return Plugin_Stop;
}

Action Timer_PrepareGame(Handle timer)
{
    if (g_iSetupTimer % 10 == 0 && g_iSetupTimer != 0)
        PrintToChatAll("Mike Myers will be chosen in %i seconds!", g_iSetupTimer);

    if (g_iSetupTimer <= 15 && g_iSetupTimer != 0)
        PrintHintTextToAll("Mike Myers will be chosen in\n%i seconds", g_iSetupTimer);
    else if (g_iSetupTimer == 0)
        PrintHintTextToAll("");

    if (g_iSetupTimer == 0) {
        do
        {
            g_iMike = GetNextMikeMyers();
        }
        while(g_iMike == -1);

        g_cvIgnoreRoundWinCondition.SetBool(true, false, false);
        ChangeClientTeam(g_iMike, TEAM_T);
        CS_RespawnPlayer(g_iMike);
        g_cvIgnoreRoundWinCondition.SetBool(false, false, false);

        //g_hEndGameTimer = CreateTimer(1.0, Timer_EndGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        //g_hAmmoTimer = CreateTimer(60.0, Timer_ReplenishAmmo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        g_hPrepareGameTimer = INVALID_HANDLE;
        g_iGameState = STATE_ACTIVE;
        g_iSetupTimer = g_cvSetupTimer.IntValue;

        for(int i = 0; i < MaxClients; i++)
        {
            if (!IsValidClient(i) || i == g_iMike)
                continue;
            PrintCenterText(i, "%N is the Mike Myers!", g_iMike);
        }

        Check1v1();

        return Plugin_Stop;
    }
    else
        g_iSetupTimer--;
    return Plugin_Continue;
}

Action Timer_RespawnPlayer(Handle timer, int client)
{
    if (IsValidClient(client))
        CS_RespawnPlayer(client);

    return Plugin_Stop;
}

Action Timer_RestoreSpeed(Handle timer, int client)
{
    //SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
    g_fMikeSpeed = g_fMikeDefSpeed;

    g_hSlowDownTimer = INVALID_HANDLE;

    return Plugin_Stop;
}
Action Timer_SetClientAmmo(Handle timer, int client)
{
    SetAmmo(client, CS_SLOT_SECONDARY, 2, g_iClientClip[client]);

    return Plugin_Stop;
}
Action Timer_SetSpeed(Handle timer, int client)
{
    if (IsValidClient(client, true))
        SDKHook(client, SDKHook_PreThink, SDK_OnPreThink);
    else
        return Plugin_Stop;
    return Plugin_Continue;
}
Action Timer_SwitchAllToSurvivor(Handle timer)
{
    for(int i = 1; i < MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            int team = GetClientTeam(i);
            if (team == TEAM_T)
            {
                ChangeClientTeam(i, TEAM_CT);
                if (!IsPlayerAlive(i))
                    CS_RespawnPlayer(i);
            }
        }
    }
}

/**
 * Plugin Commands
 */
Action Command_GameState(int client, int args)
{
    PrintToChat(client, "[MM] Current GameState: %i", g_iGameState);

    return Plugin_Handled;
}

Action Command_Respawn(int client, int args)
{
    if (args > 1) {
        ReplyToCommand(client, "Invalid amount of arguments.");

        return Plugin_Handled;
    }

    char cTarget[64];
    GetCmdArg(1, cTarget, sizeof(cTarget));
    int target = FindTarget(client, cTarget, false, false);

    if (target == -1)
        ReplyToCommand(client, "Unable to find target client.");
    else
        CS_RespawnPlayer(target);

    return Plugin_Handled;
}
