/**
// ====================================================================================================
Change Log:

1.0.2 (28-July-2021)
    - Added cvar to allow extra projectiles based on player flag. (thanks "VladimirTk" for requesting)

1.0.1 (05-March-2021)
    - Added cvar to configure plugin behaviour for humans/bots. (thanks "Mr. Man" for mentioning)

1.0.0 (05-March-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Spitter Extra Projectiles"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow spitters to spit more than a single projectile at once"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=331085"

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
#define CONFIG_FILENAME               "l4d2_spitter_extra_proj"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D2_ZOMBIECLASS_SPITTER      4

#define CLIENT_HUMAN                  1
#define CLIENT_BOT                    2

// ====================================================================================================
// Game Cvars
// ====================================================================================================
ConVar g_hCvar_z_spit_velocity;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_ClientType;
ConVar g_hCvar_MinCount;
ConVar g_hCvar_MaxCount;
ConVar g_hCvar_Chance;
ConVar g_hCvar_DeathChance;
ConVar g_hCvar_MinAng;
ConVar g_hCvar_MaxAng;
ConVar g_hCvar_Flags;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bLeft4DHooks;
bool g_bEventsHooked;
bool g_bIgnoreOnEntityCreated;
bool g_bCvar_Enabled;
bool g_bCvar_ClientBot;
bool g_bCvar_ClientHuman;
bool g_bCvar_Flags;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_ClientType;
int g_iCvar_MinCount;
int g_iCvar_MaxCount;
int g_iCvar_Chance;
int g_iCvar_DeathChance;
int g_iCvar_Flags;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_z_spit_velocity;
float g_fCvar_MinAng;
float g_fCvar_MaxAng;

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
char g_sCvar_Flags[27];

// ====================================================================================================
// left4dhooks - Plugin Dependencies
// ====================================================================================================
#if !defined _l4dh_included
native int L4D2_SpitterPrj(int client, const float vecPos[3], const float vecAng[3]);
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

    #if !defined _l4dh_included
    MarkNativeAsOptional("L4D2_SpitterPrj");
    #endif

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnAllPluginsLoaded()
{
    g_bLeft4DHooks = (GetFeatureStatus(FeatureType_Native, "L4D2_SpitterPrj") == FeatureStatus_Available);
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_hCvar_z_spit_velocity = FindConVar("z_spit_velocity");

    CreateConVar("l4d2_spitter_extra_proj_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled     = CreateConVar("l4d2_spitter_extra_proj_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ClientType  = CreateConVar("l4d2_spitter_extra_proj_client_type", "3", "Which type of client (human/bot) should be able to create additional projectiles.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_MinCount    = CreateConVar("l4d2_spitter_extra_proj_min_count", "1", "Minimum extra spit projectiles that should be created when a Spitter spits.\nNote: It will always create this amount with a 100% chance.", CVAR_FLAGS, true, 0.0);
    g_hCvar_MaxCount    = CreateConVar("l4d2_spitter_extra_proj_max_count", "2", "Maximum extra spit projectiles that could be created when a Spitter spits.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Chance      = CreateConVar("l4d2_spitter_extra_proj_chance", "25", "Chance to create extra spit projectile with a value between \"l4d2_spitter_extra_proj_min_count\" and \"l4d2_spitter_extra_proj_max_count\" cvar value.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_DeathChance = CreateConVar("l4d2_spitter_extra_proj_death_chance", "25", "Chance to create a projectile inside the spitter when it dies.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_MinAng      = CreateConVar("l4d2_spitter_extra_proj_min_ang", "-60.0", "Minimum angles that should be added to the extra spit projectile.", CVAR_FLAGS);
    g_hCvar_MaxAng      = CreateConVar("l4d2_spitter_extra_proj_max_ang", "60.0", "Maximum angles that should be added to the extra spit projectile.", CVAR_FLAGS);
    g_hCvar_Flags       = CreateConVar("l4d2_spitter_extra_proj_flags", "", "Players with these flags can create extra projectiles.\nEmpty = no restriction.\nKnown values at \"\\addons\\sourcemod\\configs\\admin_levels.cfg\".\nExample: \"az\", will enable extra projectiles to players with \"a\" (reservation) or \"z\" (root) flag.", CVAR_FLAGS);

    // Hook plugin ConVars change
    g_hCvar_z_spit_velocity.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ClientType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinCount.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MaxCount.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeathChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinAng.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MaxAng.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Flags.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_spitter_extra_proj", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
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
    g_fCvar_z_spit_velocity = g_hCvar_z_spit_velocity.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_ClientType = g_hCvar_ClientType.IntValue;
    g_bCvar_ClientBot = (g_iCvar_ClientType & CLIENT_BOT ? true : false);
    g_bCvar_ClientHuman = (g_iCvar_ClientType & CLIENT_HUMAN ? true : false);
    g_iCvar_MinCount = g_hCvar_MinCount.IntValue;
    g_iCvar_MaxCount = g_hCvar_MaxCount.IntValue;
    g_iCvar_Chance = g_hCvar_Chance.IntValue;
    g_iCvar_DeathChance = g_hCvar_DeathChance.IntValue;
    g_fCvar_MinAng = g_hCvar_MinAng.FloatValue;
    g_fCvar_MaxAng = g_hCvar_MaxAng.FloatValue;
    g_hCvar_Flags.GetString(g_sCvar_Flags, sizeof(g_sCvar_Flags));
    TrimString(g_sCvar_Flags);
    g_iCvar_Flags = ReadFlagString(g_sCvar_Flags);
    g_bCvar_Flags = g_iCvar_Flags > 0;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("spitter_killed", Event_SpitterKilled);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("spitter_killed", Event_SpitterKilled);

        return;
    }
}

/****************************************************************************************************/

void Event_SpitterKilled(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bLeft4DHooks)
        return;

    if (g_iCvar_DeathChance < GetRandomInt(1, 100))
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    if (IsFakeClient(client))
    {
        if (!g_bCvar_ClientBot)
            return;
    }
    else
    {
        if (!g_bCvar_ClientHuman)
            return;

        if (g_bCvar_Flags && !(GetUserFlagBits(client) & g_iCvar_Flags))
            return;
    }

    float vPos[3];
    GetClientEyePosition(client, vPos);

    g_bIgnoreOnEntityCreated = true;
    L4D2_SpitterPrj(client, vPos, NULL_VECTOR);
    g_bIgnoreOnEntityCreated = false;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (entity < 0)
        return;

    if (g_bIgnoreOnEntityCreated)
        return;

    if (!g_bLeft4DHooks)
        return;

    if (StrEqual(classname, "spitter_projectile"))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

    if (!IsValidClientIndex(client))
        return;

    if (IsFakeClient(client))
    {
        if (!g_bCvar_ClientBot)
            return;
    }
    else
    {
        if (!g_bCvar_ClientHuman)
            return;

        if (g_bCvar_Flags && !(GetUserFlagBits(client) & g_iCvar_Flags))
            return;
    }

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_SPITTER)
        return;

    int count = g_iCvar_MinCount;

    if (g_iCvar_Chance >= GetRandomInt(1, 100))
        count = GetRandomInt(count, g_iCvar_MaxCount);

    if (count < 1)
        return;

    float vPos[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

    float vAng[3];
    GetClientEyeAngles(client, vAng);
    GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(vAng, vAng);
    ScaleVector(vAng, g_fCvar_z_spit_velocity);

    float vAngNew[3];

    for (int i = 1; i <= count; i++)
    {
        vAngNew = vAng;
        vAngNew[0] += GetRandomFloat(g_fCvar_MinAng, g_fCvar_MaxAng);
        vAngNew[1] += GetRandomFloat(g_fCvar_MinAng, g_fCvar_MaxAng);
        vAngNew[2] += GetRandomFloat(g_fCvar_MinAng, g_fCvar_MaxAng);

        g_bIgnoreOnEntityCreated = true;
        L4D2_SpitterPrj(client, vPos, vAngNew);
        g_bIgnoreOnEntityCreated = false;
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
    PrintToConsole(client, "--------------- Plugin Cvars (l4d2_spitter_extra_proj) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_spitter_extra_proj_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_spitter_extra_proj_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_spitter_extra_proj_client_type : %i (HUMAN = %s | BOT = %s)", g_iCvar_ClientType, g_bCvar_ClientHuman ? "true" : "false", g_bCvar_ClientBot ? "true" : "false");
    PrintToConsole(client, "l4d2_spitter_extra_proj_min_count : %i", g_iCvar_MinCount);
    PrintToConsole(client, "l4d2_spitter_extra_proj_max_count : %i", g_iCvar_MaxCount);
    PrintToConsole(client, "l4d2_spitter_extra_proj_chance : %i%%", g_iCvar_Chance);
    PrintToConsole(client, "l4d2_spitter_extra_proj_min_ang : %.1f", g_fCvar_MinAng);
    PrintToConsole(client, "l4d2_spitter_extra_proj_max_ang : %.1f", g_fCvar_MaxAng);
    PrintToConsole(client, "l4d2_spitter_extra_proj_death_chance : %i%%", g_iCvar_DeathChance);
    PrintToConsole(client, "l4d2_spitter_extra_proj_flags : %s (%i)", g_sCvar_Flags, g_iCvar_Flags);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "z_spit_velocity : %.1f", g_fCvar_z_spit_velocity);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
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