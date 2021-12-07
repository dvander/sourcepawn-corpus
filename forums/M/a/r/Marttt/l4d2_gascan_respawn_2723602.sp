/**
// ====================================================================================================
Change Log:

1.0.1 (03-November-2020)
    - Fixed index error OnEntityDestroyed. (thanks to "Krufftys Killers")

1.0.0 (03-November-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Scavenge Gascan Respawn"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Teleports scavenge gascans back to their spawn position after a while"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328297"

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
#define CONFIG_FILENAME               "l4d2_gascan_respawn"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_WEAPON_GASCAN       "weapon_gascan"

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_CheckInterval;
static ConVar g_hCvar_TeleportWaitTime;
static ConVar g_hCvar_MinDistance;
static ConVar g_hCvar_GlowColor;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_GlowColor;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fDefaultVelocity[3] = {0.0, 0.0, 0.01};
static float  g_fCvar_CheckInterval;
static float  g_fCvar_TeleportWaitTime;
static float  g_fCvar_MinDistance;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_GlowColor[12];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static float  ge_fEntityStartPos[MAXENTITIES+1][3];
static float  ge_fEntityStartAng[MAXENTITIES+1][3];

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

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d2_gascan_respawn_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled          = CreateConVar("l4d2_gascan_respawn_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_CheckInterval    = CreateConVar("l4d2_gascan_respawn_check_interval", "1.0", "How often (in seconds) should the plugin check the scavenge gascan position.", CVAR_FLAGS, true, 0.1);
    g_hCvar_TeleportWaitTime = CreateConVar("l4d2_gascan_respawn_teleport_wait_time", "120.0", "How much seconds after meeting the requirements the scavenge gascan should be teleported to its spawn position.", CVAR_FLAGS, true, 0.1);
    g_hCvar_MinDistance      = CreateConVar("l4d2_gascan_respawn_min_distance", "500.0", "How far from the spawn position the scavenge gascan should be to teleport.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GlowColor        = CreateConVar("l4d2_gascan_respawn_glow_color", "255 255 255", "Scavenge gascan glow color after being teleported.\nGame default color: \"255 255 255\". Int value = 16777215.\nGame default color after pick up: \"255 127 0\". Int value = 33023.", CVAR_FLAGS);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CheckInterval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TeleportWaitTime.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowColor.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_gascan_respawn", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_CheckInterval = g_hCvar_CheckInterval.FloatValue;
    g_fCvar_TeleportWaitTime = g_hCvar_TeleportWaitTime.FloatValue;
    g_fCvar_MinDistance = g_hCvar_MinDistance.FloatValue;
    g_hCvar_GlowColor.GetString(g_sCvar_GlowColor, sizeof(g_sCvar_GlowColor));
    TrimString(g_sCvar_GlowColor);
    StringToLowerCase(g_sCvar_GlowColor);
    g_iCvar_GlowColor = ConvertRGBToInt(g_sCvar_GlowColor);
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_WEAPON_GASCAN)) != INVALID_ENT_REFERENCE)
    {
       OnSpawnPost(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'w' && classname[1] != 'e') // weapon_*
        return;

    if (StrEqual(classname, CLASSNAME_WEAPON_GASCAN))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_fEntityStartPos[entity] = NULL_VECTOR;
    ge_fEntityStartAng[entity] = NULL_VECTOR;
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity)); // 1 frame later required to get skin (m_nSkin) updated
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (!IsScavengeGascan(entity))
        return;

    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", ge_fEntityStartPos[entity]);
    GetEntPropVector(entity, Prop_Send, "m_angRotation", ge_fEntityStartAng[entity]);

    CreateTimer(g_fCvar_CheckInterval, TimerCheckInterval, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/****************************************************************************************************/

public Action TimerCheckInterval(Handle timer, int entityRef)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    if (GetEntProp(entity, Prop_Send, "m_hOwner") != -1)
        return Plugin_Continue;

    float vPosNow[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPosNow);

    if (GetVectorDistance(ge_fEntityStartPos[entity], vPosNow) < g_fCvar_MinDistance)
        return Plugin_Continue;

    CreateTimer(g_fCvar_TeleportWaitTime, TimerTeleportWaitTime, entityRef, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

/****************************************************************************************************/

public Action TimerTeleportWaitTime(Handle timer, int entityRef)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    if (GetEntProp(entity, Prop_Send, "m_hOwner") != -1)
    {
        CreateTimer(g_fCvar_CheckInterval, TimerCheckInterval, entityRef, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        return Plugin_Stop;
    }

    float vPosNow[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPosNow);

    if (GetVectorDistance(ge_fEntityStartPos[entity], vPosNow) < g_fCvar_MinDistance)
    {
        CreateTimer(g_fCvar_CheckInterval, TimerCheckInterval, entityRef, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        return Plugin_Stop;
    }

    SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvar_GlowColor);
    SetEntProp(entity, Prop_Send, "movecollide", 0); // Prevents spitter to ignite teleported gascans

    TeleportEntity(entity, ge_fEntityStartPos[entity], ge_fEntityStartAng[entity], g_fDefaultVelocity);

    CreateTimer(g_fCvar_CheckInterval, TimerCheckInterval, entityRef, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d2_gascan_respawn) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_gascan_respawn_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_gascan_respawn_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_gascan_respawn_check_interval : %.2f", g_fCvar_CheckInterval);
    PrintToConsole(client, "l4d2_gascan_respawn_teleport_wait_time : %.2f", g_fCvar_TeleportWaitTime);
    PrintToConsole(client, "l4d2_gascan_respawn_min_distance : %.2f", g_fCvar_MinDistance);
    PrintToConsole(client, "l4d2_gascan_respawn_glow_color : \"%s\" (%i)", g_sCvar_GlowColor, g_iCvar_GlowColor);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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
 * Returns if is a scavenge gascan based on its skin.
 * Works in L4D2 only.
 *
 * @param entity        Entity index.
 * @return              True if gascan skin is greater than 0 (default).
 */
bool IsScavengeGascan(int entity)
{
    int skin = GetEntProp(entity, Prop_Send, "m_nSkin");

    return skin > 0;
}

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/****************************************************************************************************/

/**
 * Returns the integer value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer value of the RGB string or 0 if not in specified format.
 */
int ConvertRGBToInt(char[] sColor)
{
    int color;

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color = StringToInt(sColors[0]);
        }
        case 2:
        {
            color = StringToInt(sColors[0]);
            color += 256 * StringToInt(sColors[1]);
            color += 65536 * StringToInt(sColors[2]);
        }
        case 3:
        {
            color = StringToInt(sColors[0]);
            color += 256 * StringToInt(sColors[1]);
            color += 65536 * StringToInt(sColors[2]);
        }
    }

    return color;
}