/*======================================================================================
 *
 *    Tank Health Scale
 *    Copyright (C) 2025 JustMe
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 ======================================================================================*/

#define PLUGIN_VERSION "1.0.0"

/*======================================================================================
    Plugin Info:

 *    Name    :    [L4D & L4D2] Tank Health Scale
 *    Author  :    JustMe
 *    Descrp  :    Increases Tank health based on the number of survivors and game difficulty.
 *    Link    :

 ========================================================================================
    Change Log:

 1.0.0
     - Initial release.

 ======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define CVAR_FLAGS FCVAR_NOTIFY

enum
{
    TEAM_SPECTATOR = 1,
    TEAM_SURVIVOR,
    TEAM_INFECTED
}

ConVar
	g_hCvarAllow,
	g_hCvarMPGameMode,
	g_hCvarModes,
	g_hCvarModesOff,
	g_hCvarModesTog,
	g_hCvarPerPlayer,
	g_hCvarMultiEasy,
	g_hCvarMultiNormal,
	g_hCvarMultiHard,
	g_hCvarMultiImpossible,
	g_hCvarExtraFromFour,
	g_hCvarIncludeBots,
	g_hCvarBase,
	g_hCvarAnnounce,
	g_hCvarLimitTank;

int
	g_iCvarPerPlayer,
	g_iCvarBase,
	g_iTankClass,
	g_iCvarLimitTank;

float
	g_fCvarMultiEasy,
	g_fCvarMultiNormal,
	g_fCvarMultiHard,
	g_fCvarMultiImpossible;

bool
	g_bCvarAllow,
	g_bCvarExtraFromFour,
	g_bCvarIncludeBots,
	g_bCvarAnnounce;

public Plugin myinfo =
{
    name        = "[L4D & L4D2] Tank Health Scale and Limit",
    author      = "JustMe",
    description = "Increases Tank health based on the number of survivors and game difficulty.",
    version     = PLUGIN_VERSION,
    url         = "/101/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();
    if (test == Engine_Left4Dead)
    {
        g_iTankClass = 5;
    }
    else if (test == Engine_Left4Dead2)
    {
        g_iTankClass = 8;
    }
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 and 2.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hCvarAllow          = CreateConVar("l4d_tank_health_scale_allow",				"1",    "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
    g_hCvarModes          = CreateConVar("l4d_tank_health_scale_modes",				"",     "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
    g_hCvarModesOff       = CreateConVar("l4d_tank_health_scale_modes_off",			"",     "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
    g_hCvarModesTog       = CreateConVar("l4d_tank_health_scale_modes_tog",			"0",    "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
    g_hCvarBase           = CreateConVar("l4d_tank_health_scale_base",				"8000", "Base Tank health before adding extra from players and difficulty.", CVAR_FLAGS);
    g_hCvarPerPlayer      = CreateConVar("l4d_tank_health_scale_per_player",		"1000", "Additional health per extra survivor.", CVAR_FLAGS);
    g_hCvarMultiEasy      = CreateConVar("l4d_tank_health_scale_multi_easy",		"1.0",	"Multiplier for additional health on Easy difficulty.", CVAR_FLAGS);
    g_hCvarMultiNormal    = CreateConVar("l4d_tank_health_scale_multi_normal",		"1.5",  "Multiplier for additional health on Normal difficulty.", CVAR_FLAGS);
    g_hCvarMultiHard      = CreateConVar("l4d_tank_health_scale_multi_hard",      	"2.0",  "Multiplier for additional health on Advanced difficulty.", CVAR_FLAGS);
    g_hCvarMultiImpossible= CreateConVar("l4d_tank_health_scale_multi_impossible",	"2.5",  "Multiplier for additional health on Expert difficulty.", CVAR_FLAGS);
    g_hCvarExtraFromFour  = CreateConVar("l4d_tank_health_scale_extra_from_four",	"0",    "0=Calculate extra health using all survivors. 1=Calculate extra health only for survivors beyond 4.", CVAR_FLAGS);
    g_hCvarIncludeBots    = CreateConVar("l4d_tank_health_scale_include_bots",		"1",    "0=Do not include bot survivors in the count. 1=Include bot survivors in the count.", CVAR_FLAGS);
    g_hCvarAnnounce       = CreateConVar("l4d_tank_health_scale_announce",        	"1",    "0=Do not announce Tank health calculation. 1=Announce Tank health calculation to all players.", CVAR_FLAGS);
    g_hCvarLimitTank      = CreateConVar("l4d_tank_limit",							"2",    "Maximum of tanks in server. -1=Unlimited.", CVAR_FLAGS);
    CreateConVar(                                 "l4d_tank_health_scale_version", PLUGIN_VERSION, "Tank Health Scale plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    AutoExecConfig(true, "l4d_tank_health_scale");

    g_hCvarMPGameMode     = FindConVar("mp_gamemode");
    g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
    g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
    g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
    g_hCvarPerPlayer.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarMultiEasy.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarMultiNormal.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarMultiHard.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarMultiImpossible.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarExtraFromFour.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarIncludeBots.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarBase.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarAnnounce.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarLimitTank.AddChangeHook(ConVarChanged_Cvars);

    IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

void GetCvars()
{
    g_iCvarPerPlayer       = g_hCvarPerPlayer.IntValue;
    g_fCvarMultiEasy       = g_hCvarMultiEasy.FloatValue;
    g_fCvarMultiNormal     = g_hCvarMultiNormal.FloatValue;
    g_fCvarMultiHard       = g_hCvarMultiHard.FloatValue;
    g_fCvarMultiImpossible = g_hCvarMultiImpossible.FloatValue;
    g_bCvarExtraFromFour   = g_hCvarExtraFromFour.BoolValue;
    g_bCvarIncludeBots     = g_hCvarIncludeBots.BoolValue;
    g_iCvarBase            = g_hCvarBase.IntValue;
    g_bCvarAnnounce        = g_hCvarAnnounce.BoolValue;
    g_iCvarLimitTank       = g_hCvarLimitTank.IntValue;
}

void IsAllowed()
{
    bool bCvarAllow = !!g_hCvarAllow.IntValue;
    bool bAllowMode = IsAllowedGameMode();
    GetCvars();

    if (!g_bCvarAllow && bCvarAllow && bAllowMode)
    {
        g_bCvarAllow = true;
        HookEvent("tank_spawn", Event_TankSpawn);
    }
    else if (g_bCvarAllow && (!bCvarAllow || !bAllowMode))
    {
        g_bCvarAllow = false;
        UnhookEvent("tank_spawn", Event_TankSpawn);
    }
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
    if (g_hCvarMPGameMode == null)
        return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if (iCvarModesTog)
    {
        g_iCurrentMode = 0;

        int entity = CreateEntityByName("info_gamemode");
        if (entity != -1)
        {
            DispatchSpawn(entity);
            HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
            HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
            ActivateEntity(entity);
            AcceptEntityInput(entity, "PostSpawnActivate");
            if (IsValidEntity(entity))
                RemoveEdict(entity);
        }

        if (g_iCurrentMode == 0)
            return false;

        if (!(iCvarModesTog & g_iCurrentMode))
            return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof sGameMode);
    FormatEx(sGameMode, sizeof sGameMode, ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof sGameModes);
    if (sGameModes[0])
    {
        FormatEx(sGameModes, sizeof sGameModes, ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof sGameModes);
    if (sGameModes[0])
    {
        FormatEx(sGameModes, sizeof sGameModes, ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
    if (strcmp(output, "OnCoop") == 0)
        g_iCurrentMode = 1;
    else if (strcmp(output, "OnSurvival") == 0)
        g_iCurrentMode = 2;
    else if (strcmp(output, "OnVersus") == 0)
        g_iCurrentMode = 4;
    else if (strcmp(output, "OnScavenge") == 0)
        g_iCurrentMode = 8;
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client && IsClientInGame(client))
    {
        CreateTimer(0.3, Timer_SetTankHealth, client, TIMER_FLAG_NO_MAPCHANGE);
        if (IsFakeClient(client))
        {
            CreateTimer(1.5, Timer_CheckTank, client, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

Action Timer_SetTankHealth(Handle timer, int client)
{
    if (isAiTank(client))
    {
        SetTankHealth(client);
    }

    return Plugin_Stop;
}

void SetTankHealth(int tank)
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurvivor(i) && IsPlayerAlive(i))
        {
            if (!g_bCvarIncludeBots && IsFakeClient(i)) continue;
            count++;
        }
    }

    int additionalPlayers;
    if (g_bCvarExtraFromFour)
    {
        additionalPlayers = count - 4;
        if (additionalPlayers < 0) additionalPlayers = 0;
    }
    else
    {
        additionalPlayers = count;
    }

    char sDiff[16];
    FindConVar("z_difficulty").GetString(sDiff, sizeof sDiff);

    float difficultyMulti = 1.0;
    switch (sDiff[0])
    {
        case 'E', 'e': difficultyMulti = g_fCvarMultiEasy;
        case 'N', 'n': difficultyMulti = g_fCvarMultiNormal;
        case 'H', 'h': difficultyMulti = g_fCvarMultiHard;
        case 'I', 'i': difficultyMulti = g_fCvarMultiImpossible;
    }

    int baseHP = RoundFloat(float(g_iCvarBase) * difficultyMulti);
    int extraHP = additionalPlayers * g_iCvarPerPlayer;
    int health = baseHP + extraHP;

    SetEntProp(tank, Prop_Send, "m_iHealth", health);
    SetEntProp(tank, Prop_Send, "m_iMaxHealth", health);

    if (g_bCvarAnnounce)
    {
        CPrintToChatAll("{green}Tank Health: {default}(%d × %.2f) + (%d × %d) = {olive}%d",
            g_iCvarBase, difficultyMulti, additionalPlayers, g_iCvarPerPlayer, health);
    }
}

Action Timer_CheckTank(Handle timer, int client)
{
    if (isAiTank(client))
    {
        int tank_count = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidInfected(i) && GetInfectedClass(i) == g_iTankClass && IsPlayerAlive(i))
                tank_count++;
        }

        if (g_iCvarLimitTank >= 0 && tank_count > g_iCvarLimitTank)
        {
            TeleportEntity(client, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
            KickClient(client);
        }
    }

    return Plugin_Stop;
}

bool isAiTank(int client)
{
    return IsValidInfected(client) && GetInfectedClass(client) == g_iTankClass && IsFakeClient(client)
        && IsPlayerAlive(client) && !IsClientIncapped(client) && !IsInGhostState(client);
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool IsValidSurvivor(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

bool IsClientIncapped(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) { return false; }
    return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool IsValidInfected(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}

int GetInfectedClass(int client)
{
    return IsValidInfected(client) ? GetEntProp(client, Prop_Send, "m_zombieClass") : -1;
}

bool IsInGhostState(int client)
{
    return IsValidInfected(client) ? !!GetEntProp(client, Prop_Send, "m_isGhost") : false;
}