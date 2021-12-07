/**
// ====================================================================================================
Change Log:

1.0.7 (26-February-2021)
    - Added support for explosive oil drum (custom model - can found on GoldenEye 4 Dead custom map)

1.0.6 (04-January-2021)
    - Added support for gas pump. (found on No Mercy, 3rd map)

1.0.5 (02-December-2020)
    - Fixed crash related to the weapon_gascan. (thanks "Maur0" for reporting)

1.0.4 (30-November-2020)
    - Fixed missing precache for fuel barrel. (thanks "Maur0" for reporting)

1.0.3 (30-November-2020)
    - Fixed some crashes caused by the plugin when combined with other plugins. (thanks "Maur0" for reporting)

1.0.2 (29-November-2020)
    - Fixed a bug preventing weapon_gascan to work. (thanks to "user2000" for reporting)
    - Added support to physics_prop, prop_physics_override and prop_physics_multiplayer.

1.0.1 (28-November-2020)
    - Fixed wrong behaviour when pick up a breakable prop item while on ignition. (thanks to "Tonblader" for reporting)

1.0.0 (28-November-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Add Prop Explosion"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Creates additional explosions on destroyed props"
#define PLUGIN_VERSION                "1.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328846"

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
#define CONFIG_FILENAME               "l4d_add_prop_explosion"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_WEAPON_GASCAN       "weapon_gascan"
#define CLASSNAME_PROP_FUEL_BARREL    "prop_fuel_barrel"
#define CLASSNAME_PROP_PHYSICS        "prop_physics"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_FUEL_BARREL             "models/props_industrial/barrel_fuel.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_BARRICADE_GASCAN        "models/props_unique/wooden_barricade_gascans.mdl"
#define MODEL_GAS_PUMP                "models/props_equipment/gas_pump_nodebris.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"
#define MODEL_OILDRUM_EXPLOSIVE       "models/props_c17/oildrum001_explosive.mdl" // Custom Model - can be found on GoldenEye 4 Dead custom map

#define TYPE_NONE                     0
#define TYPE_GASCAN                   1
#define TYPE_FUEL_BARREL              2
#define TYPE_PROPANECANISTER          3
#define TYPE_OXYGENTANK               4
#define TYPE_BARRICADE_GASCAN         5
#define TYPE_GAS_PUMP                 6
#define TYPE_FIREWORKS_CRATE          7
#define TYPE_OIL_DRUM_EXPLOSIVE       8

#define FLAG_GASCAN                   (1 << 0) // 1 | 0001
#define FLAG_FUEL_BARREL              (1 << 1) // 2 | 0010
#define FLAG_PROPANECANISTER          (1 << 2) // 4 | 0100
#define FLAG_FIREWORKS_CRATE          (1 << 3) // 8 | 1000

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Gascan;
static ConVar g_hCvar_GascanChance;
static ConVar g_hCvar_FuelBarrel;
static ConVar g_hCvar_FuelBarrelChance;
static ConVar g_hCvar_PropaneCanister;
static ConVar g_hCvar_PropaneCanisterChance;
static ConVar g_hCvar_OxygenTank;
static ConVar g_hCvar_OxygenTankChance;
static ConVar g_hCvar_BarricadeGascan;
static ConVar g_hCvar_BarricadeGascanChance;
static ConVar g_hCvar_GasPump;
static ConVar g_hCvar_GasPumpChance;
static ConVar g_hCvar_FireworksCrate;
static ConVar g_hCvar_FireworksCrateChance;
static ConVar g_hCvar_OilDrumExplosive;
static ConVar g_hCvar_OilDrumExplosiveChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Gascan;
static bool   g_bCvar_GascanChance;
static bool   g_bCvar_FuelBarrel;
static bool   g_bCvar_FuelBarrelChance;
static bool   g_bCvar_PropaneCanister;
static bool   g_bCvar_PropaneCanisterChance;
static bool   g_bCvar_OxygenTank;
static bool   g_bCvar_OxygenTankChance;
static bool   g_bCvar_BarricadeGascan;
static bool   g_bCvar_BarricadeGascanChance;
static bool   g_bCvar_GasPump;
static bool   g_bCvar_GasPumpChance;
static bool   g_bCvar_FireworksCrate;
static bool   g_bCvar_FireworksCrateChance;
static bool   g_bCvar_OilDrumExplosive;
static bool   g_bCvar_OilDrumExplosiveChance;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iModel_Gascan = -1;
static int    g_iModel_FuelBarrel = -1;
static int    g_iModel_PropaneCanister = -1;
static int    g_iModel_OxygenTank = -1;
static int    g_iModel_BarricadeGascan = -1;
static int    g_iModel_GasPump = -1;
static int    g_iModel_FireworksCrate = -1;
static int    g_iModel_OilDrumExplosive = -1;
static int    g_iCvar_Gascan;
static int    g_iCvar_FuelBarrel;
static int    g_iCvar_PropaneCanister;
static int    g_iCvar_OxygenTank;
static int    g_iCvar_BarricadeGascan;
static int    g_iCvar_GasPump;
static int    g_iCvar_FireworksCrate;
static int    g_iCvar_OilDrumExplosive;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_GascanChance;
static float  g_fCvar_FuelBarrelChance;
static float  g_fCvar_PropaneCanisterChance;
static float  g_fCvar_OxygenTankChance;
static float  g_fCvar_BarricadeGascanChance;
static float  g_fCvar_GasPumpChance;
static float  g_fCvar_FireworksCrateChance;
static float  g_fCvar_OilDrumExplosiveChance;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static int    ge_iType[MAXENTITIES+1];
static int    ge_iLastAttacker[MAXENTITIES+1];

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
    CreateConVar("l4d_add_prop_explosion_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled                  = CreateConVar("l4d_add_prop_explosion_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Gascan                   = CreateConVar("l4d_add_prop_explosion_gascan", "4", "Additional prop explosion every time a gascan explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_GascanChance             = CreateConVar("l4d_add_prop_explosion_gascan_chance", "100.0", "Chance to add a prop explosion when a gascan explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_FuelBarrel               = CreateConVar("l4d_add_prop_explosion_fuelbarrel", "1", "Additional prop explosion every time a fuel barrel explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_FuelBarrelChance         = CreateConVar("l4d_add_prop_explosion_fuelbarrel_chance", "100.0", "Chance to add a prop explosion when a fuel barrel explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_PropaneCanister          = CreateConVar("l4d_add_prop_explosion_propanecanister", "2", "Additional prop explosion every time a propane canister explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_PropaneCanisterChance    = CreateConVar("l4d_add_prop_explosion_propanecanister_chance", "100.0", "Chance to add a prop explosion when a propane canister.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_OxygenTank               = CreateConVar("l4d_add_prop_explosion_oxygentank", "2", "Additional prop explosion every time a oxygen tank explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_OxygenTankChance         = CreateConVar("l4d_add_prop_explosion_oxygentank_chance", "100.0", "Chance to add a prop explosion when an oxygen tank explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_BarricadeGascan          = CreateConVar("l4d_add_prop_explosion_barricadegascan", "4", "Additional prop explosion every time a barricade with gascans explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_BarricadeGascanChance    = CreateConVar("l4d_add_prop_explosion_barricadegascan_chance", "100.0", "Chance to add a prop explosion when a barricade with gascans explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_GasPump                  = CreateConVar("l4d_add_prop_explosion_gaspump", "1", "Additional prop explosion every time a gas pump explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_GasPumpChance            = CreateConVar("l4d_add_prop_explosion_gaspump_chance", "100.0", "Chance to add a prop explosion when a gas pump explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_OilDrumExplosive         = CreateConVar("l4d_add_prop_explosion_oildrumexplosive", "1", "Additional prop explosion every time an oil drum explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_OilDrumExplosiveChance   = CreateConVar("l4d_add_prop_explosion_oildrumexplosive_chance", "100.0", "Chance to add a prop explosion when an oil drum explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    if (g_bL4D2)
    {
        g_hCvar_FireworksCrate       = CreateConVar("l4d_add_prop_explosion_fireworkscrate", "5", "Additional prop explosion every time a fireworks crate explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
        g_hCvar_FireworksCrateChance = CreateConVar("l4d_add_prop_explosion_fireworkscrate_chance", "100.0", "Chance to add a prop explosion when a fireworks crate explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    }

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Gascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GascanChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FuelBarrel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FuelBarrelChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PropaneCanister.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PropaneCanisterChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OxygenTank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OxygenTankChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BarricadeGascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BarricadeGascanChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GasPump.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GasPumpChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OilDrumExplosive.AddChangeHook(Event_ConVarChanged);
    g_hCvar_OilDrumExplosiveChance.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_FireworksCrate.AddChangeHook(Event_ConVarChanged);
        g_hCvar_FireworksCrateChance.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_add_prop_explosion", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
    g_iModel_FuelBarrel = PrecacheModel(MODEL_FUEL_BARREL, true);
    g_iModel_PropaneCanister = PrecacheModel(MODEL_PROPANECANISTER, true);
    g_iModel_OxygenTank = PrecacheModel(MODEL_OXYGENTANK, true);
    g_iModel_BarricadeGascan = PrecacheModel(MODEL_BARRICADE_GASCAN, true);
    g_iModel_GasPump = PrecacheModel(MODEL_GAS_PUMP, true);
    if (g_bL4D2)
        g_iModel_FireworksCrate = PrecacheModel(MODEL_FIREWORKS_CRATE, true);
    if (IsModelPrecached(MODEL_OILDRUM_EXPLOSIVE))
        g_iModel_OilDrumExplosive = PrecacheModel(MODEL_OILDRUM_EXPLOSIVE, true);

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
    g_iCvar_Gascan = g_hCvar_Gascan.IntValue;
    g_bCvar_Gascan = (g_iCvar_Gascan > 0);
    g_fCvar_GascanChance = g_hCvar_GascanChance.FloatValue;
    g_bCvar_GascanChance = (g_fCvar_GascanChance > 0.0);
    g_iCvar_FuelBarrel = g_hCvar_FuelBarrel.IntValue;
    g_bCvar_FuelBarrel = (g_iCvar_FuelBarrel > 0);
    g_fCvar_FuelBarrelChance = g_hCvar_FuelBarrelChance.FloatValue;
    g_bCvar_FuelBarrelChance = (g_fCvar_FuelBarrelChance > 0.0);
    g_iCvar_PropaneCanister = g_hCvar_PropaneCanister.IntValue;
    g_bCvar_PropaneCanister = (g_iCvar_PropaneCanister > 0);
    g_fCvar_PropaneCanisterChance = g_hCvar_PropaneCanisterChance.FloatValue;
    g_bCvar_PropaneCanisterChance = (g_fCvar_PropaneCanisterChance > 0.0);
    g_iCvar_OxygenTank = g_hCvar_OxygenTank.IntValue;
    g_bCvar_OxygenTank = (g_iCvar_OxygenTank > 0);
    g_fCvar_OxygenTankChance = g_hCvar_OxygenTankChance.FloatValue;
    g_bCvar_OxygenTankChance = (g_fCvar_OxygenTankChance > 0.0);
    g_iCvar_BarricadeGascan = g_hCvar_BarricadeGascan.IntValue;
    g_bCvar_BarricadeGascan = (g_iCvar_BarricadeGascan > 0);
    g_fCvar_BarricadeGascanChance = g_hCvar_BarricadeGascanChance.FloatValue;
    g_bCvar_BarricadeGascanChance = (g_fCvar_BarricadeGascanChance > 0.0);
    g_iCvar_GasPump = g_hCvar_GasPump.IntValue;
    g_bCvar_GasPump = (g_iCvar_GasPump > 0);
    g_fCvar_GasPumpChance = g_hCvar_GasPumpChance.FloatValue;
    g_bCvar_GasPumpChance = (g_fCvar_GasPumpChance > 0.0);
    g_iCvar_OilDrumExplosive = g_hCvar_OilDrumExplosive.IntValue;
    g_bCvar_OilDrumExplosive = (g_iCvar_OilDrumExplosive > 0);
    g_fCvar_OilDrumExplosiveChance = g_hCvar_OilDrumExplosiveChance.FloatValue;
    g_bCvar_OilDrumExplosiveChance = (g_fCvar_OilDrumExplosiveChance > 0.0);
    if (g_bL4D2)
    {
        g_iCvar_FireworksCrate = g_hCvar_FireworksCrate.IntValue;
        g_bCvar_FireworksCrate = (g_iCvar_FireworksCrate > 0);
        g_fCvar_FireworksCrateChance = g_hCvar_FireworksCrateChance.FloatValue;
        g_bCvar_FireworksCrateChance = (g_fCvar_FireworksCrateChance > 0.0);
    }
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("break_prop", Event_BreakProp);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("break_prop", Event_BreakProp);

        return;
    }
}

/****************************************************************************************************/

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = event.GetInt("entindex");

    int type = ge_iType[entity];

    if (type == TYPE_NONE)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        client = GetClientOfUserId(ge_iLastAttacker[entity]);

    float vPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

    CheckPropCreation(vPos, client, type);
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
            ge_iType[entity] = TYPE_GASCAN;
            SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
            HookSingleEntityOutput(entity, "OnKilled", OnKilled, true);
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_PROP_FUEL_BARREL)) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_iType[entity] = TYPE_NONE;
    ge_iLastAttacker[entity] = 0;
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
            {
                ge_iType[entity] = TYPE_GASCAN;
                SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
                HookSingleEntityOutput(entity, "OnKilled", OnKilled, true);
            }
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
    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex == g_iModel_Gascan)
    {
        ge_iType[entity] = TYPE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_FuelBarrel)
    {
        ge_iType[entity] = TYPE_FUEL_BARREL;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_PropaneCanister)
    {
        ge_iType[entity] = TYPE_PROPANECANISTER;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_OxygenTank)
    {
        ge_iType[entity] = TYPE_OXYGENTANK;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_BarricadeGascan)
    {
        ge_iType[entity] = TYPE_BARRICADE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_GasPump)
    {
        ge_iType[entity] = TYPE_GAS_PUMP;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == g_iModel_OilDrumExplosive && g_iModel_OilDrumExplosive != -1)
    {
        ge_iType[entity] = TYPE_OIL_DRUM_EXPLOSIVE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (!g_bL4D2)
        return;

    if (modelIndex == g_iModel_FireworksCrate)
    {
        ge_iType[entity] = TYPE_FIREWORKS_CRATE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (IsValidClient(attacker))
        ge_iLastAttacker[victim] = GetClientUserId(attacker);

    return Plugin_Continue;
}

/****************************************************************************************************/

public void OnKilled(const char[] output, int caller, int activator, float delay)
{
    if (!g_bCvar_Enabled)
        return;

    if (IsValidClient(activator))
        ge_iLastAttacker[caller] = GetClientUserId(activator);

    int type = ge_iType[caller];

    if (type == TYPE_NONE)
        return;

    float vPos[3];
    GetEntPropVector(caller, Prop_Send, "m_vecOrigin", vPos);

    int client = GetClientOfUserId(ge_iLastAttacker[caller]);

    CheckPropCreation(vPos, client, type);
}

/****************************************************************************************************/

public void CheckPropCreation(float vPos[3], int client, int type)
{
    switch (type)
    {
        case TYPE_GASCAN:
        {
            if (!g_bCvar_Gascan)
                return;

            if (!g_bCvar_GascanChance)
                return;

            if (g_fCvar_GascanChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_Gascan & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_Gascan & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_Gascan & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_Gascan & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_FUEL_BARREL:
        {
            if (!g_bCvar_FuelBarrel)
                return;

            if (!g_bCvar_FuelBarrelChance)
                return;

            if (g_fCvar_FuelBarrelChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_FuelBarrel & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_FuelBarrel & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_FuelBarrel & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_FuelBarrel & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_PROPANECANISTER:
        {
            if (!g_bCvar_PropaneCanister)
                return;

            if (!g_bCvar_PropaneCanisterChance)
                return;

            if (g_fCvar_PropaneCanisterChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_PropaneCanister & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_PropaneCanister & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_PropaneCanister & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_PropaneCanister & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_OXYGENTANK:
        {
            if (!g_bCvar_OxygenTank)
                return;

            if (!g_bCvar_OxygenTankChance)
                return;

            if (g_fCvar_OxygenTankChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_OxygenTank & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_OxygenTank & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_OxygenTank & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_OxygenTank & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_BARRICADE_GASCAN:
        {
            if (!g_bCvar_BarricadeGascan)
                return;

            if (!g_bCvar_BarricadeGascanChance)
                return;

            if (g_fCvar_BarricadeGascanChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_BarricadeGascan & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_BarricadeGascan & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_BarricadeGascan & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_BarricadeGascan & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_GAS_PUMP:
        {
            if (!g_bCvar_GasPump)
                return;

            if (!g_bCvar_GasPumpChance)
                return;

            if (g_fCvar_GasPumpChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_GasPump & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_GasPump & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_GasPump & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_GasPump & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_FIREWORKS_CRATE:
        {
            if (!g_bCvar_FireworksCrate)
                return;

            if (!g_bCvar_FireworksCrateChance)
                return;

            if (g_fCvar_FireworksCrateChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_FireworksCrate & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_FireworksCrate & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_FireworksCrate & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_FireworksCrate & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }

        case TYPE_OIL_DRUM_EXPLOSIVE:
        {
            if (!g_bCvar_OilDrumExplosive)
                return;

            if (!g_bCvar_OilDrumExplosiveChance)
                return;

            if (g_fCvar_OilDrumExplosiveChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_iCvar_OilDrumExplosive & FLAG_GASCAN)
                CreateProp(client, TYPE_GASCAN, vPos);

            if (g_iCvar_OilDrumExplosive & FLAG_FUEL_BARREL)
                CreateProp(client, TYPE_FUEL_BARREL, vPos);

            if (g_iCvar_OilDrumExplosive & FLAG_PROPANECANISTER)
                CreateProp(client, TYPE_PROPANECANISTER, vPos);

            if (g_iCvar_OilDrumExplosive & FLAG_FIREWORKS_CRATE)
                CreateProp(client, TYPE_FIREWORKS_CRATE, vPos);
        }
    }
}

/****************************************************************************************************/

public void CreateProp(int client, int type, float vPos[3])
{
    int entity;

    switch (type)
    {
        case TYPE_GASCAN:
        {
            entity = CreateEntityByName(CLASSNAME_PROP_PHYSICS);
            SetEntityModel(entity, MODEL_GASCAN);
        }

        case TYPE_FUEL_BARREL:
        {
            entity = CreateEntityByName(CLASSNAME_PROP_FUEL_BARREL);
            SetEntityModel(entity, MODEL_FUEL_BARREL);
        }

        case TYPE_PROPANECANISTER:
        {
            entity = CreateEntityByName(CLASSNAME_PROP_PHYSICS);
            SetEntityModel(entity, MODEL_PROPANECANISTER);
        }

        case TYPE_FIREWORKS_CRATE:
        {
            entity = CreateEntityByName(CLASSNAME_PROP_PHYSICS);
            SetEntityModel(entity, MODEL_FIREWORKS_CRATE);
        }

        default:
        {
            return;
        }
    }

    DispatchKeyValue(entity, "targetname", "l4d_add_prop_explosion");
    SetEntityRenderMode(entity, RENDER_NONE);
    SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit); // Fix to hide the outline glow
    SetEntProp(entity, Prop_Data, "m_iHammerID", -1); // Set value to check it on SpawnPost/EntitySpawned/NextFrame

    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(entity);
    ActivateEntity(entity);

    SetEntityMoveType(entity, MOVETYPE_NONE);
    if (IsValidClient(client))
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
    RequestFrame(OnNextFrameBreak, EntIndexToEntRef(entity)); // Next frame to prevent crashes
}

/****************************************************************************************************/

public void OnNextFrameBreak(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    AcceptEntityInput(entity, "Break");
    AcceptEntityInput(entity, "Kill");
}

/****************************************************************************************************/

public Action OnSetTransmit(int entity, int client)
{
    // Never transmits
    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_add_prop_explosion) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_add_prop_explosion_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_add_prop_explosion_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_gascan : %i (%s)", g_iCvar_Gascan, g_bCvar_Gascan ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_gascan_chance : %.2f%% (%s)", g_fCvar_GascanChance, g_bCvar_GascanChance ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_fuelbarrel : %i (%s)", g_iCvar_FuelBarrel, g_bCvar_FuelBarrel ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_fuelbarrel_chance : %.2f%% (%s)", g_fCvar_FuelBarrelChance, g_bCvar_FuelBarrelChance ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_propanecanister : %i (%s)", g_iCvar_PropaneCanister, g_bCvar_PropaneCanister ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_propanecanister_chance : %.2f%% (%s)", g_fCvar_PropaneCanisterChance, g_bCvar_PropaneCanisterChance ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_oxygentank : %i (%s)", g_iCvar_OxygenTank, g_bCvar_OxygenTank ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_oxygentank_chance : %.2f%% (%s)", g_fCvar_OxygenTankChance, g_bCvar_OxygenTankChance ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_barricadegascan : %i (%s)", g_iCvar_BarricadeGascan, g_bCvar_BarricadeGascan ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_barricadegascan_chance : %.2f%% (%s)", g_fCvar_BarricadeGascanChance, g_bCvar_BarricadeGascanChance ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_gaspump : %i (%s)", g_iCvar_GasPump, g_bCvar_GasPump ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_gaspump_chance : %.2f%% (%s)", g_fCvar_GasPumpChance, g_bCvar_GasPumpChance ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_oildrumexplosive : %i (%s)", g_iCvar_OilDrumExplosive, g_bCvar_OilDrumExplosive ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_oildrumexplosive_chance : %.2f%% (%s)", g_fCvar_OilDrumExplosiveChance, g_bCvar_OilDrumExplosiveChance ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_add_prop_explosion_fireworkscrate : %i (%s)", g_iCvar_FireworksCrate, g_bCvar_FireworksCrate ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_add_prop_explosion_fireworkscrate_chance : %.2f%% (%s)", g_fCvar_FireworksCrateChance, g_bCvar_FireworksCrateChance ? "true" : "false");
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