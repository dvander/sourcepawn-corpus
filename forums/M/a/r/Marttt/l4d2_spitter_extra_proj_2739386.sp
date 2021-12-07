/**
// ====================================================================================================
Change Log:

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
#define PLUGIN_VERSION                "1.0.1"
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
#define CLASSNAME_SPITTER_PROJECTILE  "spitter_projectile"

#define L4D2_ZOMBIECLASS_SPITTER      4

#define CLIENT_HUMAN                  1
#define CLIENT_BOT                    2

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_z_spit_velocity;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_ClientType;
static ConVar g_hCvar_MinCount;
static ConVar g_hCvar_MaxCount;
static ConVar g_hCvar_Chance;
static ConVar g_hCvar_MinAng;
static ConVar g_hCvar_MaxAng;
static ConVar g_hCvar_DeathChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bLeft4DHooks;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bIgnoreOnEntityCreated;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Chance;
static bool   g_bCvar_DeathChance;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_ClientType;
static int    g_iCvar_MinCount;
static int    g_iCvar_MaxCount;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_z_spit_velocity;
static float  g_fCvar_Chance;
static float  g_fCvar_MinAng;
static float  g_fCvar_MaxAng;
static float  g_fCvar_DeathChance;

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
    g_hCvar_Chance      = CreateConVar("l4d2_spitter_extra_proj_chance", "25.0", "Chance to create extra spit projectile with a value between \"l4d2_spitter_extra_proj_min_count\" and \"l4d2_spitter_extra_proj_max_count\" cvar value.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_MinAng      = CreateConVar("l4d2_spitter_extra_proj_min_ang", "-60.0", "Minimum angles that should be added to the extra spit projectile.", CVAR_FLAGS);
    g_hCvar_MaxAng      = CreateConVar("l4d2_spitter_extra_proj_max_ang", "60.0", "Maximum angles that should be added to the extra spit projectile.", CVAR_FLAGS);
    g_hCvar_DeathChance = CreateConVar("l4d2_spitter_extra_proj_death_chance", "25.0", "Chance to create a projectile inside the spitter when it dies.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_z_spit_velocity.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ClientType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinCount.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MaxCount.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinAng.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MaxAng.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeathChance.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_spitter_extra_proj", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

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
    g_fCvar_z_spit_velocity = g_hCvar_z_spit_velocity.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_ClientType = g_hCvar_ClientType.IntValue;
    g_iCvar_MinCount = g_hCvar_MinCount.IntValue;
    g_iCvar_MaxCount = g_hCvar_MaxCount.IntValue;
    g_fCvar_Chance = g_hCvar_Chance.FloatValue;
    g_bCvar_Chance = (g_fCvar_Chance > 0.0);
    g_fCvar_MinAng = g_hCvar_MinAng.FloatValue;
    g_fCvar_MaxAng = g_hCvar_MaxAng.FloatValue;
    g_fCvar_DeathChance = g_hCvar_DeathChance.FloatValue;
    g_bCvar_DeathChance = (g_fCvar_DeathChance > 0.0);

    g_bConfigLoaded = true;
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("spitter_killed", Event_SpitterKilled);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("spitter_killed", Event_SpitterKilled);

        return;
    }
}

/****************************************************************************************************/

public void Event_SpitterKilled(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bLeft4DHooks)
        return;

    if (!g_bCvar_DeathChance)
        return;

    if (g_fCvar_DeathChance < GetRandomFloat(0.0, 100.0))
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
    {
        if (!(g_iCvar_ClientType & CLIENT_BOT))
            return;
    }
    else
    {
        if (!(g_iCvar_ClientType & CLIENT_HUMAN))
            return;
    }

    float vPos[3];
    GetClientAbsOrigin(client, vPos);

    g_bIgnoreOnEntityCreated = true;
    L4D2_SpitterPrj(client, vPos, NULL_VECTOR);
    g_bIgnoreOnEntityCreated = false;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (g_bIgnoreOnEntityCreated)
        return;

    if (!g_bLeft4DHooks)
        return;

    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 's' && classname[1] != 'p') // spitter_projectile
        return;

    if (StrEqual(classname, CLASSNAME_SPITTER_PROJECTILE))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
    {
        if (!(g_iCvar_ClientType & CLIENT_BOT))
            return;
    }
    else
    {
        if (!(g_iCvar_ClientType & CLIENT_HUMAN))
            return;
    }

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_SPITTER)
        return;

    int count = g_iCvar_MinCount;

    if (g_bCvar_Chance && g_fCvar_Chance >= GetRandomFloat(0.0, 100.0))
        count = GetRandomInt(count, g_iCvar_MaxCount);

    if (count < 1)
        return;

    float vPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

    float vAng[3];
    GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);
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
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d2_spitter_extra_proj) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_spitter_extra_proj_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_spitter_extra_proj_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_spitter_extra_proj_client_type : %i (HUMAN = %s | BOT = %s)", g_iCvar_ClientType, g_iCvar_ClientType & CLIENT_HUMAN ? "true" : "false", g_iCvar_ClientType & CLIENT_BOT ? "true" : "false");
    PrintToConsole(client, "l4d2_spitter_extra_proj_min_count : %i", g_iCvar_MinCount);
    PrintToConsole(client, "l4d2_spitter_extra_proj_max_count : %i", g_iCvar_MaxCount);
    PrintToConsole(client, "l4d2_spitter_extra_proj_chance : %.2f (%s)", g_fCvar_Chance, g_bCvar_Chance ? "true" : "false");
    PrintToConsole(client, "l4d2_spitter_extra_proj_min_ang : %.2f", g_fCvar_MinAng);
    PrintToConsole(client, "l4d2_spitter_extra_proj_max_ang : %.2f", g_fCvar_MaxAng);
    PrintToConsole(client, "l4d2_spitter_extra_proj_death_chance : %.2f (%s)", g_fCvar_DeathChance, g_bCvar_DeathChance ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "z_spit_velocity : %.2f", g_fCvar_z_spit_velocity);
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
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

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