/**
// ====================================================================================================
Change Log:

1.0.8 (04-March-2022)
    - Fixed compability with other plugins. (thanks "ddd123" for reporting)

1.0.7 (26-February-2021)
    - Added support for explosive oil drum (custom model - can be found on GoldenEye 4 Dead custom map)

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
#define PLUGIN_VERSION                "1.0.8"
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

#define FLAG_NONE                     (0 << 0) // 0 | 0000
#define FLAG_GASCAN                   (1 << 0) // 1 | 0001
#define FLAG_FUEL_BARREL              (1 << 1) // 2 | 0010
#define FLAG_PROPANECANISTER          (1 << 2) // 4 | 0100
#define FLAG_FIREWORKS_CRATE          (1 << 3) // 8 | 1000

#define OFFSET_Z                      15.0

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Gascan;
ConVar g_hCvar_GascanChance;
ConVar g_hCvar_FuelBarrel;
ConVar g_hCvar_FuelBarrelChance;
ConVar g_hCvar_PropaneCanister;
ConVar g_hCvar_PropaneCanisterChance;
ConVar g_hCvar_OxygenTank;
ConVar g_hCvar_OxygenTankChance;
ConVar g_hCvar_BarricadeGascan;
ConVar g_hCvar_BarricadeGascanChance;
ConVar g_hCvar_GasPump;
ConVar g_hCvar_GasPumpChance;
ConVar g_hCvar_FireworksCrate;
ConVar g_hCvar_FireworksCrateChance;
ConVar g_hCvar_OilDrumExplosive;
ConVar g_hCvar_OilDrumExplosiveChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iModel_Gascan = -1;
int g_iModel_FuelBarrel = -1;
int g_iModel_PropaneCanister = -1;
int g_iModel_OxygenTank = -1;
int g_iModel_BarricadeGascan = -1;
int g_iModel_GasPump = -1;
int g_iModel_FireworksCrate = -1;
int g_iModel_OilDrumExplosive = -1;
int g_iCvar_Gascan;
int g_iCvar_GascanChance;
int g_iCvar_FuelBarrel;
int g_iCvar_FuelBarrelChance;
int g_iCvar_PropaneCanister;
int g_iCvar_PropaneCanisterChance;
int g_iCvar_OxygenTank;
int g_iCvar_OxygenTankChance;
int g_iCvar_BarricadeGascan;
int g_iCvar_BarricadeGascanChance;
int g_iCvar_GasPump;
int g_iCvar_GasPumpChance;
int g_iCvar_FireworksCrate;
int g_iCvar_FireworksCrateChance;
int g_iCvar_OilDrumExplosive;
int g_iCvar_OilDrumExplosiveChance;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iType[MAXENTITIES+1];
int ge_iLastAttacker[MAXENTITIES+1];

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
    g_hCvar_GascanChance             = CreateConVar("l4d_add_prop_explosion_gascan_chance", "100", "Chance to add a prop explosion when a gascan explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_FuelBarrel               = CreateConVar("l4d_add_prop_explosion_fuelbarrel", "1", "Additional prop explosion every time a fuel barrel explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_FuelBarrelChance         = CreateConVar("l4d_add_prop_explosion_fuelbarrel_chance", "100", "Chance to add a prop explosion when a fuel barrel explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_PropaneCanister          = CreateConVar("l4d_add_prop_explosion_propanecanister", "2", "Additional prop explosion every time a propane canister explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_PropaneCanisterChance    = CreateConVar("l4d_add_prop_explosion_propanecanister_chance", "100", "Chance to add a prop explosion when a propane canister.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_OxygenTank               = CreateConVar("l4d_add_prop_explosion_oxygentank", "2", "Additional prop explosion every time a oxygen tank explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_OxygenTankChance         = CreateConVar("l4d_add_prop_explosion_oxygentank_chance", "100", "Chance to add a prop explosion when an oxygen tank explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_BarricadeGascan          = CreateConVar("l4d_add_prop_explosion_barricadegascan", "4", "Additional prop explosion every time a barricade with gascans explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_BarricadeGascanChance    = CreateConVar("l4d_add_prop_explosion_barricadegascan_chance", "100", "Chance to add a prop explosion when a barricade with gascans explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_GasPump                  = CreateConVar("l4d_add_prop_explosion_gaspump", "1", "Additional prop explosion every time a gas pump explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_GasPumpChance            = CreateConVar("l4d_add_prop_explosion_gaspump_chance", "100", "Chance to add a prop explosion when a gas pump explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_OilDrumExplosive         = CreateConVar("l4d_add_prop_explosion_oildrumexplosive", "1", "Additional prop explosion every time an oil drum explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
    g_hCvar_OilDrumExplosiveChance   = CreateConVar("l4d_add_prop_explosion_oildrumexplosive_chance", "100", "Chance to add a prop explosion when an oil drum explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    if (g_bL4D2)
    {
        g_hCvar_FireworksCrate       = CreateConVar("l4d_add_prop_explosion_fireworkscrate", "5", "Additional prop explosion every time a fireworks crate explodes.\n0 = OFF, 1 = GASCAN, 2 = FUEL BARREL, 4 = PROPANE CANISTER, 8 = FIREWORKS (L4D2 only).\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, g_bL4D2 ? 15.0 : 7.0);
        g_hCvar_FireworksCrateChance = CreateConVar("l4d_add_prop_explosion_fireworkscrate_chance", "100", "Chance to add a prop explosion when a fireworks crate explodes.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
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
    else
        g_iModel_OilDrumExplosive = -1;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

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
    g_iCvar_Gascan = g_hCvar_Gascan.IntValue;
    g_iCvar_GascanChance = g_hCvar_GascanChance.IntValue;
    g_iCvar_FuelBarrel = g_hCvar_FuelBarrel.IntValue;
    g_iCvar_FuelBarrelChance = g_hCvar_FuelBarrelChance.IntValue;
    g_iCvar_PropaneCanister = g_hCvar_PropaneCanister.IntValue;
    g_iCvar_PropaneCanisterChance = g_hCvar_PropaneCanisterChance.IntValue;
    g_iCvar_OxygenTank = g_hCvar_OxygenTank.IntValue;
    g_iCvar_OxygenTankChance = g_hCvar_OxygenTankChance.IntValue;
    g_iCvar_BarricadeGascan = g_hCvar_BarricadeGascan.IntValue;
    g_iCvar_BarricadeGascanChance = g_hCvar_BarricadeGascanChance.IntValue;
    g_iCvar_GasPump = g_hCvar_GasPump.IntValue;
    g_iCvar_GasPumpChance = g_hCvar_GasPumpChance.IntValue;
    g_iCvar_OilDrumExplosive = g_hCvar_OilDrumExplosive.IntValue;
    g_iCvar_OilDrumExplosiveChance = g_hCvar_OilDrumExplosiveChance.IntValue;
    if (g_bL4D2)
    {
        g_iCvar_FireworksCrate = g_hCvar_FireworksCrate.IntValue;
        g_iCvar_FireworksCrateChance = g_hCvar_FireworksCrateChance.IntValue;
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("break_prop", Event_BreakProp);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("break_prop", Event_BreakProp);

        return;
    }
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    if (g_bL4D2)
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "weapon_gascan")) != INVALID_ENT_REFERENCE)
        {
            RequestFrame(OnNextFrameWeaponGascan, EntIndexToEntRef(entity));
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_fuel_barrel")) != INVALID_ENT_REFERENCE)
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

public void OnEntityCreated(int entity, const char[] classname)
{
    switch (classname[0])
    {
        case 'w':
        {
            if (!g_bL4D2)
                return;

            if (classname[1] != 'e') // weapon_*
                return;

            if (StrEqual(classname, "weapon_gascan"))
            {
                RequestFrame(OnNextFrameWeaponGascan, EntIndexToEntRef(entity));
            }
        }
        case 'p':
        {
            if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
                RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iType[entity] = TYPE_NONE;
    ge_iLastAttacker[entity] = 0;
}

/****************************************************************************************************/

// Extra frame to get netprops updated
void OnNextFrameWeaponGascan(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (ge_iType[entity] != TYPE_NONE)
        return;

    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    RenderMode rendermode = GetEntityRenderMode(entity);
    int rgba[4];
    GetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);

    if (rendermode == RENDER_NONE || (rendermode == RENDER_TRANSCOLOR && rgba[3] == 0)) // Other plugins support, ignore invisible entities
        return;

    ge_iType[entity] = TYPE_GASCAN;
    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    HookSingleEntityOutput(entity, "OnKilled", OnKilled, true);
}

/****************************************************************************************************/

// Extra frame to get netprops updated
void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    RenderMode rendermode = GetEntityRenderMode(entity);
    int rgba[4];
    GetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);

    if (rendermode == RENDER_NONE || (rendermode == RENDER_TRANSCOLOR && rgba[3] == 0)) // Other plugins support, ignore invisible entities
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

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (IsValidClient(attacker))
        ge_iLastAttacker[victim] = GetClientUserId(attacker);

    return Plugin_Continue;
}

/****************************************************************************************************/

void OnKilled(const char[] output, int caller, int activator, float delay)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = caller;

    int type = ge_iType[entity];

    if (type == TYPE_NONE)
        return;

    float vPos[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
    vPos[2] += OFFSET_Z;

    if (IsValidClient(activator))
        ge_iLastAttacker[entity] = GetClientUserId(activator);

    int client = GetClientOfUserId(ge_iLastAttacker[entity]);

    CheckPropCreation(type, vPos, client);
}

/****************************************************************************************************/

void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");
    int client = GetClientOfUserId(event.GetInt("userid"));

    int type = ge_iType[entity];

    if (type == TYPE_NONE)
        return;

    float vPos[3];
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
    vPos[2] += OFFSET_Z;

    if (client == 0)
        client = GetClientOfUserId(ge_iLastAttacker[entity]);

    CheckPropCreation(type, vPos, client);
}

/****************************************************************************************************/

void CheckPropCreation(int type, float vPos[3], int client)
{
    switch (type)
    {
        case TYPE_GASCAN:
        {
            if (g_iCvar_Gascan == FLAG_NONE)
                return;

            if (g_iCvar_GascanChance < GetRandomInt(1, 100))
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
            if (g_iCvar_FuelBarrel == FLAG_NONE)
                return;

            if (g_iCvar_FuelBarrelChance < GetRandomInt(1, 100))
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
            if (g_iCvar_PropaneCanister == FLAG_NONE)
                return;

            if (g_iCvar_PropaneCanisterChance < GetRandomInt(1, 100))
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
            if (g_iCvar_OxygenTank == FLAG_NONE)
                return;

            if (g_iCvar_OxygenTankChance < GetRandomInt(1, 100))
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
            if (g_iCvar_BarricadeGascan == FLAG_NONE)
                return;

            if (g_iCvar_BarricadeGascanChance < GetRandomInt(1, 100))
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
            if (g_iCvar_GasPump == FLAG_NONE)
                return;

            if (g_iCvar_GasPumpChance < GetRandomInt(1, 100))
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
            if (g_iCvar_FireworksCrate == FLAG_NONE)
                return;

            if (g_iCvar_FireworksCrateChance < GetRandomInt(1, 100))
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
            if (g_iCvar_OilDrumExplosive == FLAG_NONE)
                return;

            if (g_iCvar_OilDrumExplosiveChance < GetRandomInt(1, 100))
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

void CreateProp(int client, int type, float vPos[3])
{
    char modelname[PLATFORM_MAX_PATH];
    char classname[36];

    switch (type)
    {
        case TYPE_GASCAN:
        {
            classname = "prop_physics";
            modelname = MODEL_GASCAN;
        }

        case TYPE_FUEL_BARREL:
        {
            classname = "prop_fuel_barrel";
            modelname = MODEL_FUEL_BARREL;
        }

        case TYPE_PROPANECANISTER:
        {
            classname = "prop_physics";
            modelname = MODEL_PROPANECANISTER;
        }

        case TYPE_FIREWORKS_CRATE:
        {
            classname = "prop_physics";
            modelname = MODEL_FIREWORKS_CRATE;
        }

        default: return;
    }

    int entity = CreateEntityByName(classname);
    DispatchKeyValue(entity, "targetname", "l4d_add_prop_explosion");
    DispatchKeyValue(entity, "hammerid", "-1"); // Set hammerid to prevent logic loop
    DispatchKeyValue(entity, "disableshadows", "1");
    DispatchKeyValue(entity, "spawnflags", "12"); // 4: Debris - Don't collide with the player or other debris. | 8: Motion Disabled.
    if (type != TYPE_FUEL_BARREL) // prop_fuel_barrel doesn't have rendermode
        DispatchKeyValue(entity, "rendermode", "10"); // 10: Don't Render
    DispatchKeyValue(entity, "model", modelname);
    DispatchKeyValueVector(entity, "origin", vPos);
    DispatchSpawn(entity);

    if (type == TYPE_FUEL_BARREL) //prop_fuel_barrel rendermode workaround
    {
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 0, 0, 0, 0);
    }

    if (IsValidClient(client))
        ge_iLastAttacker[entity] = GetClientUserId(client);

    RequestFrame(OnNextFrameBreak, EntIndexToEntRef(entity)); // Next frame to prevent a weird damage behaviour
}

/****************************************************************************************************/

void OnNextFrameBreak(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int client = GetClientOfUserId(ge_iLastAttacker[entity]);

    AcceptEntityInput(entity, "Break", client == 0 ? -1 : client);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_add_prop_explosion) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_add_prop_explosion_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_add_prop_explosion_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_add_prop_explosion_gascan : %i", g_iCvar_Gascan);
    PrintToConsole(client, "l4d_add_prop_explosion_gascan_chance : %i%%", g_iCvar_GascanChance);
    PrintToConsole(client, "l4d_add_prop_explosion_fuelbarrel : %i", g_iCvar_FuelBarrel);
    PrintToConsole(client, "l4d_add_prop_explosion_fuelbarrel_chance : %i%%", g_iCvar_FuelBarrelChance);
    PrintToConsole(client, "l4d_add_prop_explosion_propanecanister : %i", g_iCvar_PropaneCanister);
    PrintToConsole(client, "l4d_add_prop_explosion_propanecanister_chance : %i%%", g_iCvar_PropaneCanisterChance);
    PrintToConsole(client, "l4d_add_prop_explosion_oxygentank : %i", g_iCvar_OxygenTank);
    PrintToConsole(client, "l4d_add_prop_explosion_oxygentank_chance : %i%%", g_iCvar_OxygenTankChance);
    PrintToConsole(client, "l4d_add_prop_explosion_barricadegascan : %i", g_iCvar_BarricadeGascan);
    PrintToConsole(client, "l4d_add_prop_explosion_barricadegascan_chance : %i%%", g_iCvar_BarricadeGascanChance);
    PrintToConsole(client, "l4d_add_prop_explosion_gaspump : %i", g_iCvar_GasPump);
    PrintToConsole(client, "l4d_add_prop_explosion_gaspump_chance : %i%%", g_iCvar_GasPumpChance);
    PrintToConsole(client, "l4d_add_prop_explosion_oildrumexplosive : %i", g_iCvar_OilDrumExplosive);
    PrintToConsole(client, "l4d_add_prop_explosion_oildrumexplosive_chance : %i%%", g_iCvar_OilDrumExplosiveChance);
    if (g_bL4D2) PrintToConsole(client, "l4d_add_prop_explosion_fireworkscrate : %i", g_iCvar_FireworksCrate);
    if (g_bL4D2) PrintToConsole(client, "l4d_add_prop_explosion_fireworkscrate_chance : %i%%", g_iCvar_FireworksCrateChance);
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