/**
// ====================================================================================================
Change Log:

1.0.3 (13-November-2021)
    - Added cvar to stagger only once per charging. (thanks "Tonblader" for requesting)

1.0.2 (12-November-2021)
    - Added team and SI cvar.

1.0.1 (11-November-2021)
    - Added chance cvar.

1.0.0 (10-November-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Charging Charger Stagger"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Stagger clients around the charger while on charging mode"
#define PLUGIN_VERSION                "1.0.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=335142"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks> // Download here: https://forums.alliedmods.net/showthread.php?t=321696

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d2_charge_stagger"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define L4D2_FLAG_ZOMBIECLASS_NONE    0
#define L4D2_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D2_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D2_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D2_FLAG_ZOMBIECLASS_SPITTER 8
#define L4D2_FLAG_ZOMBIECLASS_JOCKEY  16
#define L4D2_FLAG_ZOMBIECLASS_CHARGER 32
#define L4D2_FLAG_ZOMBIECLASS_TANK    64

#define L4D1_FLAG_ZOMBIECLASS_NONE    0
#define L4D1_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D1_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D1_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D1_FLAG_ZOMBIECLASS_TANK    8

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Interval;
ConVar g_hCvar_Distance;
ConVar g_hCvar_Chance;
ConVar g_hCvar_Once;
ConVar g_hCvar_Team;
ConVar g_hCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Once;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Chance;
int g_iCvar_Team;
int g_iCvar_SI;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_Interval;
float g_fCvar_Distance;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bCharging[MAXPLAYERS+1];
bool gc_bStaggered[MAXPLAYERS+1][MAXPLAYERS+1];

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tStagger;

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native void L4D_StaggerPlayer(int target, int source_ent, float vecSource[3]);
#endif

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d2_charge_stagger_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled    = CreateConVar("l4d2_charge_stagger_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Interval   = CreateConVar("l4d2_charge_stagger_interval", "0.5", "Interval in seconds to stagger nearby clients while charging.", CVAR_FLAGS, true, 0.1);
    g_hCvar_Distance   = CreateConVar("l4d2_charge_stagger_distance", "200.0", "How far a client can be from a charging charger to be staggered.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Chance     = CreateConVar("l4d2_charge_stagger_chance", "100", "Chance (%) to stagger nearby clients while charging.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Once       = CreateConVar("l4d2_charge_stagger_once", "1", "Should stagger the client only once per charging.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team       = CreateConVar("l4d2_charge_stagger_team", "1", "Which teams should be affected by the plugin.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_SI         = CreateConVar("l4d2_charge_stagger_si", "127", "Which special infected should be affected by the plugin.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", enables for all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Interval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Distance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Once.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_charge_stagger", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    for (int client = 1; client <= MaxClients; client++)
    {
        gc_bCharging[client] = false;

        for (int target = 1; target <= MaxClients; target++)
        {
            gc_bStaggered[client][target] = false;
        }
    }

    HookEvents();

    delete g_tStagger;
    if (g_bCvar_Enabled)
        g_tStagger = CreateTimer(g_fCvar_Interval, TimerStagger, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    for (int client = 1; client <= MaxClients; client++)
    {
        gc_bCharging[client] = false;

        for (int target = 1; target <= MaxClients; target++)
        {
            gc_bStaggered[client][target] = false;
        }
    }

    HookEvents();

    delete g_tStagger;
    if (g_bCvar_Enabled)
        g_tStagger = CreateTimer(g_fCvar_Interval, TimerStagger, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_Interval = g_hCvar_Interval.FloatValue;
    g_fCvar_Distance = g_hCvar_Distance.FloatValue;
    g_iCvar_Chance = g_hCvar_Chance.IntValue;
    g_bCvar_Once = g_hCvar_Once.BoolValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_iCvar_SI = g_hCvar_SI.IntValue;
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bCharging[client] = false;

    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bStaggered[target][client] = false;
    }

    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bStaggered[client][target] = false;
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("charger_charge_start", Event_ChargeStart);
        HookEvent("charger_charge_end", Event_ChargeEnd);
        HookEvent("player_bot_replace", Event_PlayerBotReplace);
        HookEvent("bot_player_replace", Event_BotPlayerReplace);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("charger_charge_start", Event_ChargeStart);
        UnhookEvent("charger_charge_end", Event_ChargeEnd);
        UnhookEvent("player_bot_replace", Event_PlayerBotReplace);
        UnhookEvent("bot_player_replace", Event_BotPlayerReplace);

        return;
    }
}

/****************************************************************************************************/

void Event_ChargeStart(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    gc_bCharging[client] = true;

    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bStaggered[client][target] = false;
    }
}

/****************************************************************************************************/

void Event_ChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    gc_bCharging[client] = false;

    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bStaggered[client][target] = false;
    }
}

/****************************************************************************************************/

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    if (player == 0 || bot == 0)
        return;

    gc_bCharging[bot] = gc_bCharging[player];
}

/****************************************************************************************************/

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    if (player == 0 || bot == 0)
        return;

    gc_bCharging[player] = gc_bCharging[bot];
}

/****************************************************************************************************/

float clientPosTimer[3];
float targetPosTimer[3];
int targetTeamFlagTimer;
Action TimerStagger(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!gc_bCharging[client])
            continue;

        if (!IsValidCharger(client))
        {
            gc_bCharging[client] = false;

            for (int target = 1; target <= MaxClients; target++)
            {
                gc_bStaggered[client][target] = false;
            }

            continue;
        }

        GetClientAbsOrigin(client, clientPosTimer);

        for (int target = 1; target <= MaxClients; target++)
        {
            if (target == client)
                continue;

            if (g_bCvar_Once && gc_bStaggered[client][target])
                continue;

            if (!IsClientInGame(target))
                continue;

            if (g_iCvar_Chance < GetRandomInt(1, 100))
                continue;

            if (!IsPlayerAlive(target))
                continue;

            targetTeamFlagTimer = GetTeamFlag(GetClientTeam(target));

            if (!(targetTeamFlagTimer & g_iCvar_Team))
                continue;

            switch (targetTeamFlagTimer)
            {
                case FLAG_TEAM_SURVIVOR, FLAG_TEAM_HOLDOUT:
                {
                    if (IsPlayerImmobilized(target))
                        continue;
                }
                case FLAG_TEAM_INFECTED:
                {
                    if (IsPlayerGhost(target))
                        continue;

                    if (!(GetZombieClassFlag(target) & g_iCvar_SI))
                        continue;

                    if (IsPlayerImmobilizing(target))
                        continue;
                }
            }

            GetClientAbsOrigin(target, targetPosTimer);

            if (GetVectorDistance(targetPosTimer, clientPosTimer) > g_fCvar_Distance)
                continue;

            gc_bStaggered[client][target] = true;
            L4D_StaggerPlayer(target, client, clientPosTimer);
        }
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

bool IsValidCharger(int client)
{
    if (!IsClientInGame(client))
        return false;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_CHARGER)
        return false;

    if (IsPlayerGhost(client))
        return false;

    if (!IsPlayerAlive(client))
        return false;

    return true;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d2_charge_stagger) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_charge_stagger_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_charge_stagger_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_charge_stagger_interval : %.1f", g_fCvar_Interval);
    PrintToConsole(client, "l4d2_charge_stagger_distance : %.1f", g_fCvar_Distance);
    PrintToConsole(client, "l4d2_charge_stagger_chance : %i%%", g_iCvar_Chance);
    PrintToConsole(client, "l4d2_charge_stagger_once : %b (%s)", g_bCvar_Once, g_bCvar_Once ? "true" : "false");
    PrintToConsole(client, "l4d2_charge_stagger_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", g_iCvar_Team,
    g_iCvar_Team & FLAG_TEAM_SPECTATOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_SURVIVOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_INFECTED ? "true" : "false", g_iCvar_Team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d2_charge_stagger_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | SPITTER = %s | JOCKEY = %s | CHARGER = %s | TANK = %s)", g_iCvar_SI,
    g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_SPITTER ? "true" : "false",
    g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_JOCKEY ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_CHARGER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client        Client index.
 * @return L4D1         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Returns the zombie class flag from a zombie class.
 *
 * @param client        Client index.
 * @return              Client zombie class flag.
 */
int GetZombieClassFlag(int client)
{
    int zombieClass = GetZombieClass(client);

    if (g_bL4D2)
    {
        switch (zombieClass)
        {
            case L4D2_ZOMBIECLASS_SMOKER:
                return L4D2_FLAG_ZOMBIECLASS_SMOKER;
            case L4D2_ZOMBIECLASS_BOOMER:
                return L4D2_FLAG_ZOMBIECLASS_BOOMER;
            case L4D2_ZOMBIECLASS_HUNTER:
                return L4D2_FLAG_ZOMBIECLASS_HUNTER;
            case L4D2_ZOMBIECLASS_SPITTER:
                return L4D2_FLAG_ZOMBIECLASS_SPITTER;
            case L4D2_ZOMBIECLASS_JOCKEY:
                return L4D2_FLAG_ZOMBIECLASS_JOCKEY;
            case L4D2_ZOMBIECLASS_CHARGER:
                return L4D2_FLAG_ZOMBIECLASS_CHARGER;
            case L4D2_ZOMBIECLASS_TANK:
                return L4D2_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D2_FLAG_ZOMBIECLASS_NONE;
        }
    }
    else
    {
        switch (zombieClass)
        {
            case L4D1_ZOMBIECLASS_SMOKER:
                return L4D1_FLAG_ZOMBIECLASS_SMOKER;
            case L4D1_ZOMBIECLASS_BOOMER:
                return L4D1_FLAG_ZOMBIECLASS_BOOMER;
            case L4D1_ZOMBIECLASS_HUNTER:
                return L4D1_FLAG_ZOMBIECLASS_HUNTER;
            case L4D1_ZOMBIECLASS_TANK:
                return L4D1_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D1_FLAG_ZOMBIECLASS_NONE;
        }
    }
}

/****************************************************************************************************/

/**
 * Returns is a player is in ghost state.
 *
 * @param client        Client index.
 * @return              True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

/****************************************************************************************************/

/**
 * Validates if the client is immobilized by a special infected.
 *
 * @param client        Client index.
 * @return              True if the client is immobilized by a special infected, false otherwise.
 */
bool IsPlayerImmobilized(int client)
{
    if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") != -1) // Hunter
        return true;

    if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") != -1) // Smoker
        return true;

    if (g_bL4D2)
    {
        if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") != -1) // Jockey
            return true;

        if (GetEntPropEnt(client, Prop_Send, "m_carryAttacker") != -1) // Charger
            return true;

        if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") != -1) // Charger
            return true;
    }

    return false;
}

/****************************************************************************************************/

/**
 * Validates if the client is immobilizing a client.
 *
 * @param client        Client index.
 * @return              True if the client is immobilizing a client, false otherwise.
 */
bool IsPlayerImmobilizing(int client)
{
    if (GetEntPropEnt(client, Prop_Send, "m_pounceVictim") != -1) // Hunter
        return true;

    if (GetEntPropEnt(client, Prop_Send, "m_tongueVictim") != -1) // Smoker
        return true;

    if (g_bL4D2)
    {
        if (GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") != -1) // Jockey
            return true;

        if (GetEntPropEnt(client, Prop_Send, "m_carryVictim") != -1) // Charger
            return true;

        if (GetEntPropEnt(client, Prop_Send, "m_pummelVictim") != -1) // Charger
            return true;
    }

    return false;
}

/****************************************************************************************************/

/**
 * Returns the team flag from a team.
 *
 * @param team          Team index.
 * @return              Team flag.
 */
int GetTeamFlag(int team)
{
    switch (team)
    {
        case TEAM_SURVIVOR:
            return FLAG_TEAM_SURVIVOR;
        case TEAM_INFECTED:
            return FLAG_TEAM_INFECTED;
        case TEAM_SPECTATOR:
            return FLAG_TEAM_SPECTATOR;
        case TEAM_HOLDOUT:
            return FLAG_TEAM_HOLDOUT;
        default:
            return FLAG_TEAM_NONE;
    }
}