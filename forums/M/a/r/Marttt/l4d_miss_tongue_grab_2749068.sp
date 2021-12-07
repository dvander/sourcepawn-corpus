/**
// ====================================================================================================
Change Log:

1.0.0 (06-June-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Miss Shot/Shove On Tongue Grab"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Survivors can miss shots/shove while grabbed by a tongue"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=332885"

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
#define CONFIG_FILENAME               "l4d_miss_tongue_grab"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFECTED            "infected"
#define CLASSNAME_WITCH               "witch"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_ShotMissChance;
static ConVar g_hCvar_ShoveMissChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_ShotMissChance;
static bool   g_bCvar_ShotMissAlways;
static bool   g_bCvar_ShoveMissChance;
static bool   g_bCvar_ShoveMissAlways;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_ShotMissChance;
static float  g_fCvar_ShoveMissChance;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static bool gc_bInTongue[MAXPLAYERS+1];

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

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_miss_tongue_grab_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled         = CreateConVar("l4d_miss_tongue_grab_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ShotMissChance  = CreateConVar("l4d_miss_tongue_grab_shot_miss_chance", "100.0", "Chance to miss hits when the survivor is grabbed by tongue.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_ShoveMissChance = CreateConVar("l4d_miss_tongue_grab_shove_miss_chance", "100.0", "Chance to miss the shove when the survivor is grabbed by tongue.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShotMissChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShoveMissChance.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_miss_tongue_grab", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_ShotMissChance = g_hCvar_ShotMissChance.FloatValue;
    g_bCvar_ShotMissChance = (g_fCvar_ShotMissChance > 0.0);
    g_bCvar_ShotMissAlways = (g_fCvar_ShotMissChance == 100.0);
    g_fCvar_ShoveMissChance = g_hCvar_ShoveMissChance.FloatValue;
    g_bCvar_ShoveMissChance = (g_fCvar_ShoveMissChance > 0.0);
    g_bCvar_ShoveMissAlways = (g_fCvar_ShoveMissChance == 100.0);
}

/****************************************************************************************************/

public void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFECTED)) != INVALID_ENT_REFERENCE)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_WITCH)) != INVALID_ENT_REFERENCE)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bInTongue[client] = false;
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bConfigLoaded)
        return;

    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 'i':
        {
            if (StrEqual(classname, CLASSNAME_INFECTED))
                SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        }
        case 'w':
        {
            if (classname[1] != 'i')
                return;

            if (StrEqual(classname, CLASSNAME_WITCH))
                SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("tongue_grab", Event_TongueGrab);
        HookEvent("tongue_release", Event_TongueRelease);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("tongue_grab", Event_TongueGrab);
        UnhookEvent("tongue_release", Event_TongueRelease);

        return;
    }
}

/****************************************************************************************************/

public void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidClientIndex(client))
        return;

    gc_bInTongue[client] = true;
}

/****************************************************************************************************/

public void Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidClientIndex(client))
        return;

    gc_bInTongue[client] = false;
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!g_bCvar_ShotMissChance)
        return Plugin_Continue;

    if (!IsValidClientIndex(attacker))
        return Plugin_Continue;

    if (!gc_bInTongue[attacker])
        return Plugin_Continue;

    if (attacker != inflictor)
       return Plugin_Continue;

    if (g_bCvar_ShotMissAlways)
        return Plugin_Stop;

    if (g_fCvar_ShotMissChance >= GetRandomFloat(0.0, 100.0))
        return Plugin_Stop;

    return Plugin_Continue;
}

/****************************************************************************************************/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!(buttons & IN_ATTACK2))
        return Plugin_Continue;

    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!g_bCvar_ShoveMissChance)
        return Plugin_Continue;

    if (!IsValidClientIndex(client))
        return Plugin_Continue;

    if (!gc_bInTongue[client])
        return Plugin_Continue;

    if (g_bCvar_ShoveMissAlways)
    {
        buttons &= ~IN_ATTACK2;
        return Plugin_Changed;
    }

    if (g_fCvar_ShoveMissChance >= GetRandomFloat(0.0, 100.0))
    {
        buttons &= ~IN_ATTACK2;
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_miss_tongue_grab) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_miss_tongue_grab_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_miss_tongue_grab_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_miss_tongue_grab_miss_chance : %.2f (%s)", g_fCvar_ShotMissChance, g_bCvar_ShotMissChance ? "true" : "false");
    PrintToConsole(client, "l4d_miss_tongue_grab_miss_shove_chance : %.2f (%s)", g_fCvar_ShoveMissChance, g_bCvar_ShoveMissChance ? "true" : "false");
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
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}