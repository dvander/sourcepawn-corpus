/**
// ====================================================================================================
Change Log:

1.0.5 (11-April-2021)
    - Added cvar to enable motion on shove.

1.0.4 (31-December-2020)
    - Added cvar to control motion OnTakeDamage [damageForce]. (thanks "Tonblader" for requesting)

1.0.3 (24-December-2020)
    - Fixed missing L4D1 check. (thanks "Dragokas" for reporting)

1.0.2 (29-November-2020)
    - Added support to physics_prop, prop_physics_override and prop_physics_multiplayer.
    - Added extra frame to apply no collision properly for prop_physics entities.

1.0.1 (15-November-2020)
    - Changed collision type from 1 [COLLISION_GROUP_DEBRIS] to 2 [COLLISION_GROUP_DEBRIS_TRIGGER].
    - Fixed bug preventing prop_physics entities to be picked up. (thanks "moekai" for reporting)

1.0.0 (04-November-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Remove Weapons/Carryables Collision"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Changes the collision from all weapons or carryables to collide only with the world and static stuff"
#define PLUGIN_VERSION                "1.0.5"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328327"

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
#define CONFIG_FILENAME               "l4d_remove_item_collision"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_GASCAN                       "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANECANISTER              "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK                   "models/props_equipment/oxygentank01.mdl"
#define MODEL_FIREWORKS_CRATE              "models/props_junk/explosive_box001.mdl"

#define COLLISION_GROUP_DEBRIS_TRIGGER     2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Motion;
static ConVar g_hCvar_ShoveMotion;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Motion;
static bool   g_bCvar_ShoveMotion;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iModel_Gascan = -1;
static int    g_iModel_PropaneCanister = -1;
static int    g_iModel_OxygenTank = -1;
static int    g_iModel_FireworksCrate = -1;

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
    CreateConVar("l4d_remove_item_collision_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled     = CreateConVar("l4d_remove_item_collision_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Motion      = CreateConVar("l4d_remove_item_collision_motion", "0", "Allow motion when the item is hit.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ShoveMotion = CreateConVar("l4d_remove_item_collision_shove_motion", "1", "Allow motion when the item is shoved.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Motion.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShoveMotion.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_remove_item_collision", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
    g_iModel_PropaneCanister = PrecacheModel(MODEL_PROPANECANISTER, true);
    g_iModel_OxygenTank = PrecacheModel(MODEL_OXYGENTANK, true);
    if (g_bL4D2)
        g_iModel_FireworksCrate = PrecacheModel(MODEL_FIREWORKS_CRATE, true);
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
    g_bCvar_Motion = g_hCvar_Motion.BoolValue;
    g_bCvar_ShoveMotion = g_hCvar_ShoveMotion.BoolValue;
}

/****************************************************************************************************/

public void LateLoad()
{
    if (!g_bCvar_Enabled)
        return;

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "weapon_*")) != INVALID_ENT_REFERENCE)
    {
       RequestFrame(OnNextFrameWeapons, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            RequestFrame(OnNextFramePhysics, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFramePhysics, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 'w':
        {
            if (classname[1] != 'e') // weapon_*
                return;

            RequestFrame(OnNextFrameWeapons, EntIndexToEntRef(entity)); // 1 frame later required to apply the collision properly
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                RequestFrame(OnNextFramePhysics, EntIndexToEntRef(entity)); // 1 frame later required to apply the collision properly
        }
    }
}

/****************************************************************************************************/

public void OnNextFrameWeapons(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    RemoveColision(entity);
}

/****************************************************************************************************/

public void OnNextFramePhysics(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex == g_iModel_Gascan)
    {
        RemoveColision(entity);
        return;
    }

    if (modelIndex == g_iModel_PropaneCanister)
    {
        RemoveColision(entity);
        return;
    }

    if (modelIndex == g_iModel_OxygenTank)
    {
        RemoveColision(entity);
        return;
    }

    if (!g_bL4D2)
        return;

    if (modelIndex == g_iModel_FireworksCrate)
    {
        RemoveColision(entity);
        return;
    }
}

/****************************************************************************************************/

public void RemoveColision(int entity)
{
    SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);

    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if ((damagetype & DMG_CLUB) && IsValidClientIndex(inflictor)) // Shove
    {
        if (g_bCvar_ShoveMotion)
            return Plugin_Continue;
    }
    else
    {
        if (g_bCvar_Motion)
            return Plugin_Continue;
    }

    damageForce[0] = 0.0;
    damageForce[1] = 0.0;
    damageForce[2] = 0.0;

    return Plugin_Changed;
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

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_remove_item_collision) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_remove_item_collision_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_remove_item_collision_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_remove_item_collision_motion : %b (%s)", g_bCvar_Motion, g_bCvar_Motion ? "true" : "false");
    PrintToConsole(client, "l4d_remove_item_collision_shove_motion : %b (%s)", g_bCvar_ShoveMotion, g_bCvar_ShoveMotion ? "true" : "false");
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