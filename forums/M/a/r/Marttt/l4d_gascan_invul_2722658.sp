/**
// ====================================================================================================
Change Log:

1.0.7 (11-April-2021)
    - Fixed gascans not applying damage forces on shove. (thanks "Forgetest" for reporting)

1.0.6 (26-January-2021)
    - Fixed incompatibility with other plugins that use OnTakeDamage. (thanks "Tonblader" for reporting)
    - Added invulnerability cvar to the chainsaw.

1.0.5 (12-January-2021)
    - Added cvar to control distance invulnerability. (thanks "cravenge" for requesting)

1.0.4 (03-January-2021)
    - Fixed "Invalid memory access" error. (thanks "ur5efj" for reporting)

1.0.3 (31-December-2020)
    - Added cvar to control both normal and scavenge gascan health. (thanks "Tonblader" for requesting)
    - Added cvar to block shove damage.

1.0.2 (29-November-2020)
    - Added support to physics_prop, prop_physics_override and prop_physics_multiplayer.

1.0.1 (26-October-2020)
    - Added cvar to block bullet damage. (thanks to "Crasher_3637")
    - Added cvar to block melee damage.
    - Added support to prop_physics / physics_prop gascans.
    - Added L4D1 support.
    - Improved the damage type check.

1.0.0 (26-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Gascan Invulnerable"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Turns gascan invulnerable to certain damages types"
#define PLUGIN_VERSION                "1.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328100"

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
#define CONFIG_FILENAME               "l4d_gascan_invul"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_WEAPON_GASCAN       "weapon_gascan"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Health;
static ConVar g_hCvar_Distance;
static ConVar g_hCvar_ShoveDamage;
static ConVar g_hCvar_MeleeDamage;
static ConVar g_hCvar_BulletDamage;
static ConVar g_hCvar_FireDamage;
static ConVar g_hCvar_BlastDamage;
static ConVar g_hCvar_ChainsawDamage;
static ConVar g_hCvar_SpitDamage;
static ConVar g_hCvar_ScavengeGascan;
static ConVar g_hCvar_ScavengeHealth;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Distance;
static bool   g_bCvar_Health;
static bool   g_bCvar_ShoveDamage;
static bool   g_bCvar_MeleeDamage;
static bool   g_bCvar_BulletDamage;
static bool   g_bCvar_FireDamage;
static bool   g_bCvar_BlastDamage;
static bool   g_bCvar_ChainsawDamage;
static bool   g_bCvar_SpitDamage;
static bool   g_bCvar_ScavengeGascan;
static bool   g_bCvar_ScavengeHealth;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iModel_Gascan = -1;
static int    g_iCvar_Health;
static int    g_iCvar_ScavengeHealth;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_Distance;

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
    CreateConVar("l4d_gascan_invul_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled            = CreateConVar("l4d_gascan_invul_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Health             = CreateConVar("l4d_gascan_invul_health", "0", "Override normal gascan health.\n0 = OFF.\nDefault game value = 20.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Distance           = CreateConVar("l4d_gascan_invul_distance", "0.0", "How far the gascan should be to be invulnerable.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ShoveDamage        = CreateConVar("l4d_gascan_invul_shove_damage", "1", "Turn gascans invulnerable to shove damage. (DMG_CLUB and INFLICTOR = valid client)\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MeleeDamage        = CreateConVar("l4d_gascan_invul_melee_damage", "1", "Turn gascans invulnerable to melee damage. (DMG_SLASH or DMG_CLUB)\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BulletDamage       = CreateConVar("l4d_gascan_invul_bullet_damage", "1", "Turn gascans invulnerable to bullet damage. (DMG_BULLET)\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_FireDamage         = CreateConVar("l4d_gascan_invul_fire_damage", "1", "Turn gascans invulnerable to fire damage. (DMG_BURN)\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BlastDamage        = CreateConVar("l4d_gascan_invul_blast_damage", "1", "Turn gascans invulnerable to blast damage. (DMG_BLAST)\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
    {
        g_hCvar_ChainsawDamage = CreateConVar("l4d_gascan_invul_chainsaw_damage", "1", "Turn gascans invulnerable to chainsaw damage. (DMG_DISSOLVE)\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_SpitDamage     = CreateConVar("l4d_gascan_invul_spit_damage", "1", "Turn gascans invulnerable to spit damage. (DMG_ENERGYBEAM)\nL4D2 and scavenge gascan only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_ScavengeGascan = CreateConVar("l4d_gascan_invul_scavenge_only", "1", "Apply invulnerability only to scavenge gascans.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_ScavengeHealth = CreateConVar("l4d_gascan_invul_scavenge_health", "0", "Override scavenge gascan health.\nL4D2 only.\n0 = OFF.\nDefault game value = 20", CVAR_FLAGS, true, 0.0);
    }

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Health.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShoveDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MeleeDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BulletDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FireDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BlastDamage.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_ChainsawDamage.AddChangeHook(Event_ConVarChanged);
        g_hCvar_SpitDamage.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ScavengeGascan.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ScavengeHealth.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_gascan_invul", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
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
    g_iCvar_Health = g_hCvar_Health.IntValue;
    g_bCvar_Health = (g_iCvar_Health > 0);
    g_fCvar_Distance = g_hCvar_Distance.FloatValue;
    g_bCvar_Distance = (g_fCvar_Distance > 0.0);
    g_bCvar_ShoveDamage = g_hCvar_ShoveDamage.BoolValue;
    g_bCvar_MeleeDamage = g_hCvar_MeleeDamage.BoolValue;
    g_bCvar_BulletDamage = g_hCvar_BulletDamage.BoolValue;
    g_bCvar_FireDamage = g_hCvar_FireDamage.BoolValue;
    g_bCvar_BlastDamage = g_hCvar_BlastDamage.BoolValue;
    if (g_bL4D2)
    {
        g_bCvar_ChainsawDamage = g_hCvar_ChainsawDamage.BoolValue;
        g_bCvar_SpitDamage = g_hCvar_SpitDamage.BoolValue;
        g_bCvar_ScavengeGascan = g_hCvar_ScavengeGascan.BoolValue;
        g_iCvar_ScavengeHealth = g_hCvar_ScavengeHealth.IntValue;
        g_bCvar_ScavengeHealth = (g_iCvar_ScavengeHealth > 0);
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    if (g_bL4D2)
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, CLASSNAME_WEAPON_GASCAN)) != INVALID_ENT_REFERENCE)
        {
            OnSpawnPost(entity);
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            OnSpawnPost(entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
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

    switch (classname[0])
    {
        case 'w':
        {
            if (!g_bL4D2)
                return;

            if (classname[1] != 'e') // weapon_*
                return;

            if (StrEqual(classname, CLASSNAME_WEAPON_GASCAN))
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        }
    }
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex != g_iModel_Gascan)
        return;

    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);

    if (!g_bCvar_Enabled)
        return;

    if (g_bL4D2 && IsScavengeGascan(entity))
    {
        if (!g_bCvar_ScavengeHealth)
            return;

        SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvar_ScavengeHealth);
    }
    else
    {
        if (!g_bCvar_Health)
            return;

        SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvar_Health);
    }
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (g_bCvar_ScavengeGascan && !IsScavengeGascan(victim))
        return Plugin_Continue;

    if (g_bCvar_Distance)
    {
        if (IsValidClient(inflictor))
        {
            float vPosVictim[3];
            GetEntPropVector(victim, Prop_Send, "m_vecOrigin", vPosVictim);

            float vPosInflictor[3];
            GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", vPosInflictor);

            if (GetVectorDistance(vPosVictim, vPosInflictor) <= g_fCvar_Distance)
                return Plugin_Continue;
        }
    }

    if ((damagetype & DMG_CLUB) && IsValidClientIndex(inflictor)) // Shove
    {
        if (g_bCvar_ShoveDamage)
        {
            // Removing the damagetype DMG_CLUB prevents the gascan from moving while being shoved
            damage = 0.0;
            return Plugin_Changed;
        }
    }
    else
    {
        int damagetypeOld = damagetype;

        if (g_bCvar_MeleeDamage && (damagetype & DMG_SLASH || damagetype & DMG_CLUB))
        {
            if (HasEntProp(inflictor, Prop_Data, "m_strMapSetScriptName")) // CTerrorMeleeWeapon
                damagetype &= ~(DMG_SLASH | DMG_CLUB);
        }

        if (g_bCvar_BulletDamage && (damagetype & DMG_BULLET))
            damagetype &= ~DMG_BULLET;

        if (g_bCvar_FireDamage && (damagetype & DMG_BURN))
            damagetype &= ~DMG_BURN;

        if (g_bCvar_BlastDamage && (damagetype & DMG_BLAST))
            damagetype &= ~DMG_BLAST;

        if (g_bL4D2)
        {
            if (g_bCvar_ChainsawDamage && (damagetype & DMG_DISSOLVE))
            {
                if (HasEntProp(inflictor, Prop_Send, "m_bHitting")) // CChainsaw
                    damagetype &= ~DMG_DISSOLVE;
            }

            if (g_bCvar_SpitDamage && (damagetype & DMG_ENERGYBEAM))
                damagetype &= ~DMG_ENERGYBEAM;
        }

        if (damagetype != damagetypeOld)
        {
            damage = 0.0;
            return Plugin_Changed;
        }
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
    PrintToConsole(client, "------------------ Plugin Cvars (l4d_gascan_invul) -------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_gascan_invul_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_gascan_invul_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_health : %i (%s)", g_iCvar_Health, g_bCvar_Health ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_distance : %.2f (%s)", g_fCvar_Distance, g_bCvar_Distance ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_shove_damage : %b (%s)", g_bCvar_ShoveDamage, g_bCvar_ShoveDamage ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_melee_damage : %b (%s)", g_bCvar_MeleeDamage, g_bCvar_MeleeDamage ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_bullet_damage : %b (%s)", g_bCvar_BulletDamage, g_bCvar_BulletDamage ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_fire_damage : %b (%s)", g_bCvar_FireDamage, g_bCvar_FireDamage ? "true" : "false");
    PrintToConsole(client, "l4d_gascan_invul_blast_damage : %b (%s)", g_bCvar_BlastDamage, g_bCvar_BlastDamage ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_gascan_invul_chainsaw_damage : %b (%s)", g_bCvar_ChainsawDamage, g_bCvar_ChainsawDamage ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_gascan_invul_spit_damage : %b (%s)", g_bCvar_SpitDamage, g_bCvar_SpitDamage ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_gascan_invul_scavenge_only : %b (%s)", g_bCvar_ScavengeGascan, g_bCvar_ScavengeGascan ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_gascan_invul_scavenge_health : %i (%s)", g_iCvar_ScavengeHealth, g_bCvar_ScavengeHealth ? "true" : "false");
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