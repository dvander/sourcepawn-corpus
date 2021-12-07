/**
// ====================================================================================================
Change Log:

1.1.0 (25-April-2021)
    - New version released.
    - Replaced gamedata with left4dhooks dependency.

1.0.0 (14-April-2019)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Car Alarm Vomit"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Vomits on the player who triggers a car alarm"
#define PLUGIN_VERSION                "1.1.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=315602"

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
#define CONFIG_FILENAME               "l4d_car_alarm_vomit"
#define TRANSLATION_FILENAME          "l4d_car_alarm_vomit.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_PROP_CAR_ALARM      "prop_car_alarm"
#define CLASSNAME_ENV_INSTRUCTOR_HINT "env_instructor_hint"

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define FLAG_MSG_DISPLAY_CHAT         (1 << 0) // 1 | 001
#define FLAG_MSG_DISPLAY_HINT         (1 << 1) // 2 | 010
#define FLAG_MSG_DISPLAY_INSTRUCTOR   (1 << 2) // 3 | 100

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Bots;
static ConVar g_hCvar_Flags;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_Msg;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bLeft4DHooks;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCarAlarmStarted;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Bots;
static bool   g_bCvar_Flags;

// ====================================================================================================
// int - Plugin Cvar Variables
// ====================================================================================================
static int    g_iCvar_Flags;
static int    g_iCvar_Team;
static int    g_iCvar_Msg;

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
static char   g_sCvar_Flags[27];

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native void L4D_CTerrorPlayer_OnVomitedUpon(int client, int attacker);
#endif

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

    #if !defined _l4dh_included
    MarkNativeAsOptional("L4D_CTerrorPlayer_OnVomitedUpon");
    #endif

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnAllPluginsLoaded()
{
    g_bLeft4DHooks = (GetFeatureStatus(FeatureType_Native, "L4D_CTerrorPlayer_OnVomitedUpon") == FeatureStatus_Available);
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadPluginTranslations();

    // Register Plugin ConVars
    CreateConVar("l4d_car_alarm_vomit_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_car_alarm_vomit_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Bots    = CreateConVar("l4d_car_alarm_vomit_bots", "1", "Enables/Disables the plugin behaviour on Survivor bots.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Flags   = CreateConVar("l4d_car_alarm_vomit_flags", "", "Players with these flags are immune to the plugin behaviour.\nEmpty = none.\nKnown values at \"\\addons\\sourcemod\\configs\\admin_levels.cfg\".\nExample: \"az\", will apply immunity to players with \"a\" (reservation) or \"z\" (root) flag.", CVAR_FLAGS);
    g_hCvar_Team    = CreateConVar("l4d_car_alarm_vomit_team", "1", "Which teams should the message be transmitted to.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    if (g_bL4D2)
        g_hCvar_Msg     = CreateConVar("l4d_car_alarm_vomit_msg", "5", "Display type for the \"Activator\" message.\n0 = OFF, 1 = CHAT, 2 = HINT, 4 = INSTRUCTOR HINT (L4D2 only).\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 7.0);
    else
        g_hCvar_Msg     = CreateConVar("l4d_car_alarm_vomit_msg", "1", "Display type for the \"Activator\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);

    // Hook Plugin ConVars Change
    HookConVarChange(g_hCvar_Enabled, Event_ConVarChanged);
    HookConVarChange(g_hCvar_Bots, Event_ConVarChanged);
    HookConVarChange(g_hCvar_Flags, Event_ConVarChanged);
    HookConVarChange(g_hCvar_Team, Event_ConVarChanged);
    HookConVarChange(g_hCvar_Msg, Event_ConVarChanged);

    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_car_alarm_vomit", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = GetConVarBool(g_hCvar_Enabled);
    g_bCvar_Bots = GetConVarBool(g_hCvar_Bots);
    GetConVarString(g_hCvar_Flags, g_sCvar_Flags, sizeof(g_sCvar_Flags));
    TrimString(g_sCvar_Flags);
    g_iCvar_Flags = ReadFlagString(g_sCvar_Flags);
    g_bCvar_Flags = g_iCvar_Flags > 0;
    g_iCvar_Team = GetConVarInt(g_hCvar_Team);
    g_iCvar_Msg = GetConVarInt(g_hCvar_Msg);
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        if (g_bL4D2)
            HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        if (g_bL4D2)
            UnhookEvent("triggered_car_alarm", Event_TriggeredCarAlarm);

        return;
    }
}

// ====================================================================================================
// Hook Events (L4D2)
// ====================================================================================================
public void Event_TriggeredCarAlarm(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bLeft4DHooks)
        return;

    int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsValidClient(attacker))
        return;

    if (IsFakeClient(attacker) && !g_bCvar_Bots)
        return;

    if (!IsPlayerAlive(attacker))
        return;

    if (GetClientTeam(attacker) != TEAM_SURVIVOR)
        return;

    if (g_bCvar_Flags && (GetUserFlagBits(attacker) & g_iCvar_Flags))
        return;

    L4D_CTerrorPlayer_OnVomitedUpon(attacker, attacker);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
            continue;

        if (g_iCvar_Msg & FLAG_MSG_DISPLAY_CHAT)
            CPrintToChat(client, "%t", client == attacker ? "Activator" : "Others", attacker);

        if (g_iCvar_Msg & FLAG_MSG_DISPLAY_HINT)
            CPrintHintText(client, "%t", client == attacker ? "Activator" : "Others", attacker);

        if (g_iCvar_Msg & FLAG_MSG_DISPLAY_INSTRUCTOR)
            PrintInstructorHintText(client, "%t", client == attacker ? "Activator" : "Others", attacker);
    }
}

// ====================================================================================================
// Hook Events (L4D1)
// ====================================================================================================
public void LateLoad()
{
    if (g_bL4D2)
        return;

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_PROP_CAR_ALARM)) != INVALID_ENT_REFERENCE)
    {
        HookSingleEntityOutput(entity, "OnCarAlarmStart", OnCarAlarmStart, true);
        HookSingleEntityOutput(entity, "OnTakeDamage", OnTakeDamage);
        SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_bL4D2)
        return;

    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'p')
        return;

    if (StrEqual(classname, CLASSNAME_PROP_CAR_ALARM))
    {
        HookSingleEntityOutput(entity, "OnCarAlarmStart", OnCarAlarmStart);
        HookSingleEntityOutput(entity, "OnTakeDamage", OnTakeDamage);
        SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
    }
}

/****************************************************************************************************/

public void OnCarAlarmStart(const char[] output, int caller, int activator, float delay)
{
    g_bCarAlarmStarted = true;
}

/****************************************************************************************************/

public void OnTakeDamage(const char[] output, int caller, int activator, float delay)
{
    CheckAlarm(caller, activator);
}

/****************************************************************************************************/

public void OnStartTouchPost(int entity, int other)
{
    CheckAlarm(entity, other);
}

/****************************************************************************************************/

void CheckAlarm(int entity, int activator)
{
    if (!g_bCarAlarmStarted)
        return;

    g_bCarAlarmStarted = false;

    UnhookSingleEntityOutput(entity, "OnCarAlarmStart", OnCarAlarmStart);
    UnhookSingleEntityOutput(entity, "OnTakeDamage", OnTakeDamage);
    SDKUnhook(entity, SDKHook_StartTouchPost, OnStartTouchPost);

    if (!g_bLeft4DHooks)
        return;

    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClient(activator))
        return;

    if (IsFakeClient(activator) && !g_bCvar_Bots)
        return;

    if (!IsPlayerAlive(activator))
        return;

    if (GetClientTeam(activator) != TEAM_SURVIVOR)
        return;

    if (g_bCvar_Flags && (GetUserFlagBits(activator) & g_iCvar_Flags))
        return;

    L4D_CTerrorPlayer_OnVomitedUpon(activator, activator);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
            continue;

        if (g_iCvar_Msg & FLAG_MSG_DISPLAY_CHAT)
            CPrintToChat(client, "%t", client == activator ? "Activator" : "Others", activator);

        if (g_iCvar_Msg & FLAG_MSG_DISPLAY_HINT)
            CPrintHintText(client, "%t", client == activator ? "Activator" : "Others", activator);

        if (g_iCvar_Msg & FLAG_MSG_DISPLAY_INSTRUCTOR)
            PrintInstructorHintText(client, "%t", client == activator ? "Activator" : "Others", activator);
    }
}

/****************************************************************************************************/

void PrintInstructorHintText(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "");
    ReplaceString(buffer, sizeof(buffer), "{white}", "");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "");
    ReplaceString(buffer, sizeof(buffer), "{green}", "");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "");

    ReplaceString(buffer, sizeof(buffer), "\x01", ""); // Default
    ReplaceString(buffer, sizeof(buffer), "\x03", ""); // Light Green
    ReplaceString(buffer, sizeof(buffer), "\x04", ""); // Orange
    ReplaceString(buffer, sizeof(buffer), "\x05", ""); // Olive

    char clienttargetname[64];
    GetEntPropString(client, Prop_Data, "m_iName", clienttargetname, sizeof(clienttargetname));

    char hintTarget[28];
    Format(hintTarget, sizeof(hintTarget), "l4d_car_alarm_vomit_hint_%d", client);

    int entity = CreateEntityByName(CLASSNAME_ENV_INSTRUCTOR_HINT);
    DispatchKeyValue(client, "targetname", hintTarget);
    DispatchKeyValue(entity, "hint_target", hintTarget);
    DispatchKeyValue(entity, "targetname", "l4d_car_alarm_vomit");
    DispatchKeyValue(entity, "hint_caption", buffer);
    DispatchKeyValue(entity, "hint_icon_onscreen", "icon_alert_red");
    DispatchKeyValue(entity, "hint_color", "255 255 0"); // #FFFF00 | 255,255,0

    DispatchSpawn(entity);
    AcceptEntityInput(entity, "ShowHint", client);

    SetVariantString("OnUser1 !self:Kill::8:-1");
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    DispatchKeyValue(client, "targetname", clienttargetname); // rollback the client targetname
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_car_alarm_vomit) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_car_alarm_vomit_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_car_alarm_vomit_enabled : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_car_alarm_vomit_bots : %b (%s)", g_bCvar_Bots, g_bCvar_Bots ? "true" : "false");
    PrintToConsole(client, "l4d_car_alarm_vomit_flags : %s (%d)", g_sCvar_Flags, g_iCvar_Flags);
    PrintToConsole(client, "l4d_car_alarm_vomit_displayto : %i", g_iCvar_Team);
    PrintToConsole(client, "l4d_car_alarm_vomit_msgdisplay : %i", g_iCvar_Msg);
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------------------------------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", g_bLeft4DHooks ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
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

// ====================================================================================================
// colors.inc replacement (Thanks to Silvers)
// ====================================================================================================
/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
public void CPrintToChat(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{green}", "\x04"); // Actually orange in L4D1/L4D2, but replicating colors.inc behaviour
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}

/****************************************************************************************************/

/**
 * Prints a message to a specific client in the hint area.
 * Remove color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
public void CPrintHintText(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "");
    ReplaceString(buffer, sizeof(buffer), "{white}", "");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "");
    ReplaceString(buffer, sizeof(buffer), "{green}", "");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "");

    ReplaceString(buffer, sizeof(buffer), "\x01", ""); // Default
    ReplaceString(buffer, sizeof(buffer), "\x03", ""); // Light Green
    ReplaceString(buffer, sizeof(buffer), "\x04", ""); // Orange
    ReplaceString(buffer, sizeof(buffer), "\x05", ""); // Olive

    PrintHintText(client, buffer);
}