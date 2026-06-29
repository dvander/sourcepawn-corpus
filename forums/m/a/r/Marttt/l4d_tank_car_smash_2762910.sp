/**
// ====================================================================================================
Change Log:

1.0.2 (16-November-2021)
    - Added cvar to allow smashing with tank claw.
    - Added cvar to allow smashing with tank rock.
    - Added chance cvar.

1.0.1 (09-November-2021)
    - Added cvars to delete childs and to emit glass breaking sounds on car hit.

1.0.0 (08-November-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Tank Car Smash"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Changes the car model for a smashed one on tank hit"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=335105"

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
#define CONFIG_FILENAME               "l4d_tank_car_smash"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_CARA_82HATCHBACK                 "models/props_vehicles/cara_82hatchback.mdl"
#define MODEL_CARA_82HATCHBACK_WRECKED         "models/props_vehicles/cara_82hatchback_wrecked.mdl"

#define MODEL_CARA_95SEDAN                     "models/props_vehicles/cara_95sedan.mdl"
#define MODEL_CARA_95SEDAN_WRECKED             "models/props_vehicles/cara_95sedan_wrecked.mdl"

#define SOUND_GLASS_SHEET_BREAK1      "physics/glass/glass_sheet_break1.wav"
#define SOUND_GLASS_SHEET_BREAK2      "physics/glass/glass_sheet_break2.wav"
#define SOUND_GLASS_SHEET_BREAK3      "physics/glass/glass_sheet_break3.wav"

#define VEHICLE_TYPE_NONE             0
#define VEHICLE_TYPE_82HATCHBACK      1
#define VEHICLE_TYPE_95SEDAN          2

#define TEAM_INFECTED                 3

#define L4D1_ZOMBIECLASS_TANK         5
#define L4D2_ZOMBIECLASS_TANK         8

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_DeleteChilds;
ConVar g_hCvar_GlassSound;
ConVar g_hCvar_TankClaw;
ConVar g_hCvar_TankRock;
ConVar g_hCvar_Chance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bCvar_Enabled;
bool g_bCvar_DeleteChilds;
bool g_bCvar_GlassSound;
bool g_bCvar_TankClaw;
bool g_bCvar_TankRock;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iTankClass;
int g_iCvar_Chance;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bOnTakeDamagePostHooked[MAXENTITIES+1];
int ge_iCarType[MAXENTITIES+1];

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
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_tank_car_smash_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled      = CreateConVar("l4d_tank_car_smash_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DeleteChilds = CreateConVar("l4d_tank_car_smash_delete_childs", "1", "Delete attached entities (child) from the car.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlassSound   = CreateConVar("l4d_tank_car_smash_glass_sound", "1", "Emit a random breaking glass sound on car smash.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_TankClaw     = CreateConVar("l4d_tank_car_smash_tank_claw", "1", "Allow smashing the car with tank claw.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_TankRock     = CreateConVar("l4d_tank_car_smash_tank_rock", "1", "Allow smashing the car with tank rock.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Chance       = CreateConVar("l4d_tank_car_smash_tank_chance", "100", "Chance (%) to smash the car.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeleteChilds.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlassSound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TankClaw.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TankRock.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Chance.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_tank_car_smash", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    PrecacheSounds();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    PrecacheSounds();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_DeleteChilds = g_hCvar_DeleteChilds.BoolValue;
    g_bCvar_GlassSound = g_hCvar_GlassSound.BoolValue;
    g_bCvar_TankClaw = g_hCvar_TankClaw.BoolValue;
    g_bCvar_TankRock = g_hCvar_TankRock.BoolValue;
    g_iCvar_Chance = g_hCvar_Chance.IntValue;
}

/****************************************************************************************************/

void PrecacheSounds()
{
    if (g_bCvar_Enabled && g_bCvar_GlassSound)
    {
        PrecacheSound(SOUND_GLASS_SHEET_BREAK1, true);
        PrecacheSound(SOUND_GLASS_SHEET_BREAK2, true);
        PrecacheSound(SOUND_GLASS_SHEET_BREAK3, true);
    }
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
            HookEntity(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (!HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
        return;

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bOnTakeDamagePostHooked[entity] = false;
    ge_iCarType[entity] = VEHICLE_TYPE_NONE;
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    HookEntity(entity);
}

/****************************************************************************************************/

void HookEntity(int entity)
{
    if (ge_bOnTakeDamagePostHooked[entity])
        return;

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    if (StrEqual(modelname, MODEL_CARA_82HATCHBACK))
    {
        ge_bOnTakeDamagePostHooked[entity] = true;
        ge_iCarType[entity] = VEHICLE_TYPE_82HATCHBACK;
        PrecacheModel(MODEL_CARA_82HATCHBACK_WRECKED, true);
        SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        return;
    }

    if (StrEqual(modelname, MODEL_CARA_95SEDAN))
    {
        ge_bOnTakeDamagePostHooked[entity] = true;
        ge_iCarType[entity] = VEHICLE_TYPE_95SEDAN;
        PrecacheModel(MODEL_CARA_95SEDAN_WRECKED, true);
        SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        return;
    }
}

/****************************************************************************************************/

void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClient(attacker))
        return;

    if (GetClientTeam(attacker) != TEAM_INFECTED)
        return;

    if (GetZombieClass(attacker) != g_iTankClass)
        return;

    if (g_iCvar_Chance < GetRandomInt(1, 100))
        return;

    char inflictorClassname[2];
    GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));

    switch (inflictorClassname[0])
    {
        case 'w': // weapon_tank_claw
        {
            if (!g_bCvar_TankClaw)
                return;
        }
        case 't': // tank_rock
        {
            if (!g_bCvar_TankRock)
                return;
        }
    }

    if (g_bCvar_DeleteChilds)
    {
        int entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
        {
            if (entity < 0)
                continue;

            if (HasEntProp(entity, Prop_Send, "moveparent") && victim == GetEntPropEnt(entity, Prop_Send, "moveparent"))
                AcceptEntityInput(entity, "Kill");
        }
    }

    if (g_bCvar_GlassSound)
    {
        switch (GetRandomInt(1, 3))
        {
            case 1: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK1, victim);
            case 2: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK2, victim);
            case 3: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK3, victim);
        }
    }

    switch (ge_iCarType[victim])
    {
        case VEHICLE_TYPE_82HATCHBACK: SetEntityModel(victim, MODEL_CARA_82HATCHBACK_WRECKED);
        case VEHICLE_TYPE_95SEDAN: SetEntityModel(victim, MODEL_CARA_95SEDAN_WRECKED);
    }

    SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_tank_car_smash) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_tank_car_smash_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_tank_car_smash_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_tank_car_smash_delete_childs : %b (%s)", g_bCvar_DeleteChilds, g_bCvar_DeleteChilds ? "true" : "false");
    PrintToConsole(client, "l4d_tank_car_smash_glass_sound : %b (%s)", g_bCvar_GlassSound, g_bCvar_GlassSound ? "true" : "false");
    PrintToConsole(client, "l4d_tank_car_smash_tank_claw : %b (%s)", g_bCvar_TankClaw, g_bCvar_TankClaw ? "true" : "false");
    PrintToConsole(client, "l4d_tank_car_smash_tank_rock : %b (%s)", g_bCvar_TankRock, g_bCvar_TankRock ? "true" : "false");
    PrintToConsole(client, "l4d_tank_car_smash_tank_chance : %i%%", g_iCvar_Chance);
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
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client     Client index.
 * @return L4D1      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
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