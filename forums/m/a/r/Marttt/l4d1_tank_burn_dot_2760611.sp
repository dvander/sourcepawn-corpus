/**
// ====================================================================================================
Change Log:

1.0.1 (02-April-2022)
    - Fixed timer not using the interval set. (thanks "ReCreator" for reporting)

1.0.0 (14-October-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1] Tank Burn Damage Over Time"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds burn damage over time while the tank is on fire"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=334708"

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
#define CONFIG_FILENAME               "l4d1_tank_burn_dot"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_INFECTED                 3

#define L4D1_ZOMBIECLASS_TANK         5

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_DisableSuicide;
ConVar g_hCvar_Interval;
ConVar g_hCvar_Damage;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_DisableSuicide;
bool g_bCvar_Damage;
bool g_bTimer;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_Interval;
float g_fCvar_Damage;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bTankOnFire[MAXPLAYERS+1];
int gc_iAttackerUserId[MAXPLAYERS+1];

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tBurn;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d1_tank_burn_dot_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled        = CreateConVar("l4d1_tank_burn_dot_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DisableSuicide = CreateConVar("l4d1_tank_burn_dot_disable_suicide", "1", "Disable Tanks dying from fire after a while.\nNote: Usually controlled by \"tank_burn_duration_*\" cvars.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Interval       = CreateConVar("l4d1_tank_burn_dot_interval", "0.5", "Interval in seconds to apply burn damage to the Tank.", CVAR_FLAGS, true, 0.1);
    g_hCvar_Damage         = CreateConVar("l4d1_tank_burn_dot_damage", "5.0", "Burn damage amount applied to the Tank.\n0 = OFF.", CVAR_FLAGS, true, 0.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DisableSuicide.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Interval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Damage.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d1_tank_burn_dot", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    LateLoad();

    delete g_tBurn;
    if (g_bTimer)
        g_tBurn = CreateTimer(g_fCvar_Interval, TimerBurn, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    delete g_tBurn;
    if (g_bTimer)
        g_tBurn = CreateTimer(g_fCvar_Interval, TimerBurn, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_DisableSuicide = g_hCvar_DisableSuicide.BoolValue;
    g_fCvar_Interval = g_hCvar_Interval.FloatValue;
    g_fCvar_Damage = g_hCvar_Damage.FloatValue;
    g_bCvar_Damage = (g_fCvar_Damage > 0.0);
    g_bTimer = (g_bCvar_Enabled && g_bCvar_Damage);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsEntityOnFire(client))
            continue;

        if (GetClientTeam(client) != TEAM_INFECTED)
            continue;

        if (GetZombieClass(client) != L4D1_ZOMBIECLASS_TANK)
            continue;

        gc_bTankOnFire[client] = true;
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bTankOnFire[client] = false;
    gc_iAttackerUserId[client] = 0;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_hurt", Event_PlayerHurt);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_hurt", Event_PlayerHurt);

        return;
    }
}

/****************************************************************************************************/

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int type = event.GetInt("type");
    int client = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!(type & DMG_BURN))
        return;

    if (client == 0 || attacker == 0)
        return;

    if (gc_bTankOnFire[client])
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    if (GetZombieClass(client) != L4D1_ZOMBIECLASS_TANK)
        return;

    if (g_bCvar_DisableSuicide)
    {
        SetEntPropFloat(client, Prop_Send, "m_suicideCountdown", 0.0, 0); // m_suicideCountdown->m_duration
        SetEntPropFloat(client, Prop_Send, "m_suicideCountdown", -1.0, 1); // m_suicideCountdown->m_timestamp
    }

    gc_bTankOnFire[client] = true;
    gc_iAttackerUserId[client] = GetClientUserId(attacker);
}

/****************************************************************************************************/

Action TimerBurn(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!gc_bTankOnFire[client])
            continue;

        gc_bTankOnFire[client] = false;

        if (!IsClientInGame(client))
            continue;

        if (!IsEntityOnFire(client))
            continue;

        if (GetClientTeam(client) != TEAM_INFECTED)
            continue;

        if (GetZombieClass(client) != L4D1_ZOMBIECLASS_TANK)
            continue;

        gc_bTankOnFire[client] = true;

        SDKHooks_TakeDamage(client, GetClientOfUserId(gc_iAttackerUserId[client]), GetClientOfUserId(gc_iAttackerUserId[client]), g_fCvar_Damage, DMG_BURN, -1, NULL_VECTOR, NULL_VECTOR);
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d1_tank_burn_dot) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d1_tank_burn_dot_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d1_tank_burn_dot_enabled : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d1_tank_burn_dot_disable_suicide : %b (%s)", g_bCvar_DisableSuicide, g_bCvar_DisableSuicide ? "true" : "false");
    PrintToConsole(client, "l4d1_tank_burn_dot_interval : %.1f", g_fCvar_Interval);
    PrintToConsole(client, "l4d1_tank_burn_dot_damage : %.1f", g_fCvar_Damage);
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
 * Validates if the entity is on fire.
 *
 * @param entity        Entity index.
 * @return              True if entity is on fire, false otherwise.
 */
bool IsEntityOnFire(int entity)
{
    return (GetEntityFlags(entity) & FL_ONFIRE ? true : false);
}