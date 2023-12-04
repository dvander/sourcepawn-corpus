/**
// ====================================================================================================
Change Log:

1.0.0 (08-August-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Prevent Survivor Action On Damage"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Prevent survivors from helping themselves and teammates while taking damage"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=333835"

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
#define CONFIG_FILENAME               "l4d_prevent_action_damage"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SURVIVOR                 2

#define CLIENT_HUMAN                  1
#define CLIENT_BOT                    2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_ClientType;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_ClientBot;
bool g_bCvar_ClientHuman;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_ClientType;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_prevent_action_damage_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled    = CreateConVar("l4d_prevent_action_damage_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ClientType = CreateConVar("l4d_prevent_action_damage_client_type", "3", "Which type of client (human/bot) should the plugin affect.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ClientType.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_prevent_action_damage", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_ClientType = g_hCvar_ClientType.IntValue;
    g_bCvar_ClientBot = (g_iCvar_ClientType & CLIENT_BOT ? true : false);
    g_bCvar_ClientHuman = (g_iCvar_ClientType & CLIENT_HUMAN ? true : false);
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
    int dmg_health = event.GetInt("dmg_health");
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (dmg_health < 1)
        return;

    if (victim == 0)
        return;

    if (GetClientTeam(victim) != TEAM_SURVIVOR)
        return;

    if (IsFakeClient(victim))
    {
        if (!g_bCvar_ClientBot)
            return;
    }
    else
    {
        if (!g_bCvar_ClientHuman)
            return;
    }

    int buttons;
    buttons = GetClientButtons(victim);
    buttons &= ~IN_USE;
    buttons &= ~IN_ATTACK;
    buttons &= ~IN_ATTACK2;
    SetEntProp(victim, Prop_Data, "m_nButtons", buttons);

    if (g_bL4D2)
    {
        SetEntProp(victim, Prop_Send, "m_iCurrentUseAction", 0);
        SetEntProp(victim, Prop_Send, "m_useActionOwner", 0);
        SetEntProp(victim, Prop_Send, "m_useActionTarget", 0);
        SetEntProp(victim, Prop_Send, "m_reviveOwner", 0);
        SetEntProp(victim, Prop_Send, "m_reviveTarget", 0);
        SetEntPropFloat(victim, Prop_Send, "m_flProgressBarDuration", 0.0);
        SetEntPropFloat(victim, Prop_Send, "m_flProgressBarStartTime", 0.0);
    }
    else
    {
        SetEntProp(victim, Prop_Send, "m_healOwner", 0);
        SetEntProp(victim, Prop_Send, "m_healTarget", 0);
        SetEntProp(victim, Prop_Send, "m_reviveOwner", 0);
        SetEntProp(victim, Prop_Send, "m_reviveTarget", 0);
        SetEntProp(victim, Prop_Send, "m_iProgressBarDuration", 0);
        SetEntPropFloat(victim, Prop_Send, "m_flProgressBarStartTime", 0.0);
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (client == victim)
            continue;

        if (!IsClientInGame(client))
            continue;

        if (GetClientTeam(client) != TEAM_SURVIVOR)
            continue;

        buttons = GetClientButtons(client);
        buttons &= ~IN_USE;
        buttons &= ~IN_ATTACK;
        buttons &= ~IN_ATTACK2;
        SetEntProp(client, Prop_Data, "m_nButtons", buttons);

        if (g_bL4D2)
        {
            if (victim == GetEntPropEnt(client, Prop_Send, "m_useActionTarget") || victim == GetEntPropEnt(client, Prop_Send, "m_reviveTarget"))
            {
                SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
                SetEntProp(client, Prop_Send, "m_useActionOwner", 0);
                SetEntProp(client, Prop_Send, "m_useActionTarget", 0);
                SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
                SetEntProp(client, Prop_Send, "m_reviveTarget", 0);
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
            }
        }
        else
        {
            if (victim == GetEntPropEnt(client, Prop_Send, "m_healTarget") || victim == GetEntPropEnt(client, Prop_Send, "m_reviveTarget"))
            {
                SetEntProp(client, Prop_Send, "m_healOwner", 0);
                SetEntProp(client, Prop_Send, "m_healTarget", 0);
                SetEntProp(client, Prop_Send, "m_reviveOwner", 0);
                SetEntProp(client, Prop_Send, "m_reviveTarget", 0);
                SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
                SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
            }
        }
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_prevent_action_damage) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_prevent_action_damage_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_prevent_action_damage_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_prevent_action_damage_client_type : %i (HUMAN = %s | BOT = %s)", g_iCvar_ClientType, g_bCvar_ClientHuman ? "true" : "false", g_bCvar_ClientBot ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}