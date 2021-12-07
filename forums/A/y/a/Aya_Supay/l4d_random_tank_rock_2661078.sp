// ====================================================================================================
// File
// ====================================================================================================
#file "l4d_random_tank_rock.sp"

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                  "[L4D & L4D2] Random Tank Rock"
#define PLUGIN_AUTHOR                "Mart"
#define PLUGIN_DESCRIPTION           "Randomize the rock model thrown by the Tank."
#define PLUGIN_VERSION               "1.0.0"
#define PLUGIN_URL                   "https://forums.alliedmods.net/showthread.php?t=315775"

/*
// ====================================================================================================
Change Log:

1.0.0 (23-April-2019)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>

// ====================================================================================================
// Defines
// ====================================================================================================
#define CVAR_FLAGS                   FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION    FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define TEAM_INFECTED                3
#define L4D1_ZOMBIECLASS_TANK        5
#define L4D2_ZOMBIECLASS_TANK        8

#define MODEL_CONCRETE_CHUNK         "models/props_debris/concrete_chunk01a.mdl"
#define MODEL_TREE_TRUNK             "models/props_foliage/tree_trunk.mdl"

#define MODEL_BALL "models/props_unique/airport/atlas_break_ball.mdl"
#define MODEL_RACECAR "models/props_vehicles/racecar_damaged.mdl"
#define MODEL_CAR "models/props_vehicles/car_white.mdl"
#define MODEL_TRAIN "models/props_vehicles/train_engine_military.mdl"
#define MODEL_FLOWER "models/props_foliage/flower_barrel.mdl"
#define MODEL_TEDDY "models/props_interiors/teddy_bear.mdl"
#define MODEL_COFEE "models/props/cs_militia/caseofbeer01.mdl"

                                     
#define TYPE_CONCRETE_CHUNK          (1 << 0) // 1 | 01
#define TYPE_TREE_TRUNK              (1 << 1) // 2 | 10

#define CONFIG_FILENAME              "l4d_random_tank_rock"

// ====================================================================================================
// Native Cvar Handles
// ====================================================================================================
static Handle hCvar_MPGameMode = INVALID_HANDLE;

// ====================================================================================================
// Plugin Cvar Handles
// ====================================================================================================
static Handle hCvar_Enabled = INVALID_HANDLE;
static Handle hCvar_ModelType = INVALID_HANDLE;
static Handle hCvar_GameModesOn = INVALID_HANDLE;
static Handle hCvar_GameModesOff = INVALID_HANDLE;
static Handle hCvar_GameModesToggle = INVALID_HANDLE;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
static bool   g_bL4D2Version;
static bool   bCvar_Enabled;

// ====================================================================================================
// int - Plugin Cvar Variables
// ====================================================================================================
static int    iCvar_ModelType;
static int    iCvar_GameModesToggle;
static int    iCvar_CurrentMode;

// ====================================================================================================
// string - Native Cvar Variables
// ====================================================================================================
static char   sCvar_MPGameMode[16];

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
static char   sCvar_GameModesOn[512];
static char   sCvar_GameModesOff[512];

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
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
        return APLRes_SilentFailure;
    }
    
    g_bL4D2Version = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    // Register Plugin ConVars
    hCvar_MPGameMode = FindConVar("mp_gamemode"); // Native Game Mode ConVar
    CreateConVar("l4d_random_tank_rock_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    hCvar_Enabled         = CreateConVar("l4d_random_tank_rock_enabled",          "1", "Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    hCvar_ModelType       = CreateConVar("l4d_random_tank_rock_model_type",       "3", "Which models should be applied to the rock thrown by the Tank.\nKnown values: 1 = Only Rock, 2 = Only Trunk, 3 = Rock [50% chance] or Trunk [50% chance].", CVAR_FLAGS, true, 1.0, true, 3.0);
    hCvar_GameModesOn     = CreateConVar("l4d_random_tank_rock_gamemodes_on",     "",  "Turn on the plugin in these game modes, separate by commas (no spaces). Empty = all.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
    hCvar_GameModesOff    = CreateConVar("l4d_random_tank_rock_gamemodes_off",    "",  "Turn off the plugin in these game modes, separate by commas (no spaces). Empty = none.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
    hCvar_GameModesToggle = CreateConVar("l4d_random_tank_rock_gamemodes_toggle", "0", "Turn on the plugin in these game modes.\nKnown values: 0 = all, 1 = coop, 2 = survival, 4 = versus, 8 = scavenge.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for \"coop\" (1) and \"survival\" (2).", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook Plugin ConVars Change
    HookConVarChange(hCvar_MPGameMode, Event_ConVarChanged);
    HookConVarChange(hCvar_Enabled, Event_ConVarChanged);
    HookConVarChange(hCvar_ModelType, Event_ConVarChanged);
    HookConVarChange(hCvar_GameModesOn, Event_ConVarChanged);
    HookConVarChange(hCvar_GameModesOff, Event_ConVarChanged);
    HookConVarChange(hCvar_GameModesToggle, Event_ConVarChanged);

    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_l4d_random_tank_rock_print_cvars", AdmCmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    Precaches();
}

/****************************************************************************************************/

void Precaches()
{
	PrecacheModel(MODEL_CONCRETE_CHUNK, true);
	PrecacheModel(MODEL_TREE_TRUNK, true);
	PrecacheModel(MODEL_BALL, true);
	PrecacheModel(MODEL_RACECAR, true);
	PrecacheModel(MODEL_CAR, true);
	PrecacheModel(MODEL_TRAIN, true);
	PrecacheModel(MODEL_FLOWER, true);
	PrecacheModel(MODEL_TEDDY, true);
	PrecacheModel(MODEL_COFEE, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tank_rock", false))
        RequestFrame(OnTankRockNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void OnTankRockNextFrame(int iEntRef)
{
    if (!bCvar_Enabled)
        return;

    if (!IsAllowedGameMode())
        return;
    
    if (!IsValidEntRef(iEntRef))
        return;
    
    int entity = EntRefToEntIndex(iEntRef);
    
    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    
    if (!IsValidClient(client))
        return;
    
    if (!IsPlayerAlive(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    if (IsPlayerGhost(client))
        return;

    if (GetZombieClass(client) != (g_bL4D2Version ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK))
        return;
    
    int iCase;
    if (iCvar_ModelType & TYPE_CONCRETE_CHUNK && iCvar_ModelType & TYPE_TREE_TRUNK)
        iCase = GetRandomInt(0, 8);
    else if (iCvar_ModelType & TYPE_CONCRETE_CHUNK)
        iCase = 1;
    else if (iCvar_ModelType & TYPE_TREE_TRUNK)
        iCase = 2;
    
    switch (iCase)
    {
        case 0: SetEntityModel(entity, MODEL_BALL);
        case 1: SetEntityModel(entity, MODEL_CONCRETE_CHUNK);
        case 2: SetEntityModel(entity, MODEL_TREE_TRUNK);
        case 3: SetEntityModel(entity, MODEL_RACECAR);
        case 4: SetEntityModel(entity, MODEL_CAR);
        case 5: SetEntityModel(entity, MODEL_TRAIN);
        case 6: SetEntityModel(entity, MODEL_FLOWER);
        case 7: SetEntityModel(entity, MODEL_TEDDY);
        case 8: SetEntityModel(entity, MODEL_COFEE);
    }
}

// ====================================================================================================
// ConVars
// ====================================================================================================
void Event_ConVarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    GetConVarString(hCvar_MPGameMode, sCvar_MPGameMode, sizeof(sCvar_MPGameMode));
    TrimString(sCvar_MPGameMode);
    bCvar_Enabled = GetConVarBool(hCvar_Enabled);
    iCvar_ModelType = GetConVarInt(hCvar_ModelType);
    GetConVarString(hCvar_GameModesOn, sCvar_GameModesOn, sizeof(sCvar_GameModesOn));
    TrimString(sCvar_GameModesOn);
    GetConVarString(hCvar_GameModesOff, sCvar_GameModesOff, sizeof(sCvar_GameModesOff));
    TrimString(sCvar_GameModesOff);
    iCvar_GameModesToggle = GetConVarInt(hCvar_GameModesToggle);
}

// ====================================================================================================
// Admin Commands - Print to Console
// ====================================================================================================
Action AdmCmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_random_tank_rock) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_random_tank_rock_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_random_tank_rock_enabled : %b (%s)", bCvar_Enabled, bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_random_tank_rock_model_type : %i", iCvar_ModelType);
    PrintToConsole(client, "----------------------------------------------------------------------");
    PrintToConsole(client, "mp_gamemode : %s", sCvar_MPGameMode);
    PrintToConsole(client, "l4d_random_tank_rock_gamemodes_on : %s", sCvar_GameModesOn);
    PrintToConsole(client, "l4d_random_tank_rock_gamemodes_off : %s", sCvar_GameModesOff);
    PrintToConsole(client, "l4d_random_tank_rock_gamemodes_toggle : %d", iCvar_GameModesToggle);
    PrintToConsole(client, "IsAllowedGameMode : %b (%s)", IsAllowedGameMode(), IsAllowedGameMode() ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if the current game mode is valid to run the plugin.
 *
 * @return              True if game mode is valid, false otherwise.
 */
bool IsAllowedGameMode()
{
    if (hCvar_MPGameMode == null || hCvar_MPGameMode == INVALID_HANDLE)
        return false;

    if (iCvar_GameModesToggle != 0)
    {
        int entity = CreateEntityByName("info_gamemode");
        DispatchSpawn(entity);
        HookSingleEntityOutput(entity, "OnCoop", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnSurvival", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnVersus", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnScavenge", OnGameMode, true);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "PostSpawnActivate");
        AcceptEntityInput(entity, "Kill");

        if (iCvar_CurrentMode == 0)
            return false;

        if (!(iCvar_GameModesToggle & iCvar_CurrentMode))
            return false;
    }

    char sGameModes[512], sGameMode[512];
    strcopy(sGameMode, sizeof(sCvar_MPGameMode), sCvar_MPGameMode);
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    strcopy(sGameModes, sizeof(sCvar_GameModesOn), sCvar_GameModesOn);
    if (!StrEqual(sGameModes, "", false))
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    strcopy(sGameModes, sizeof(sCvar_GameModesOff), sCvar_GameModesOff);
    if (!StrEqual(sGameModes, "", false))
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

/****************************************************************************************************/

/**
 * Sets the running game mode int value.
 *
 * @param output        output.
 * @param caller        caller.
 * @param activator     activator.
 * @param delay         delay.
 * @noreturn
 */
int OnGameMode(const char[] output, int caller, int activator, float delay)
{
    if (StrEqual(output, "OnCoop", false))
        iCvar_CurrentMode = 1;
    else if (StrEqual(output, "OnSurvival", false))
        iCvar_CurrentMode = 2;
    else if (StrEqual(output, "OnVersus", false))
        iCvar_CurrentMode = 4;
    else if (StrEqual(output, "OnScavenge", false))
        iCvar_CurrentMode = 8;
    else
        iCvar_CurrentMode = 0;
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
    return (1 <= client <= MaxClients && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Validates if the client is a ghost.
 *
 * @param client        Client index.
 * @return              True if client is a ghost, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1;
}

/****************************************************************************************************/

/**
 * Get the specific L4D2 zombie class id from the client.
 *
 * @return L4D          1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED

 */
int GetZombieClass(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

/****************************************************************************************************/

/**
 * Validates if is a valid entity reference.
 *
 * @param client        Entity reference.
 * @return              True if entity reference is valid, false otherwise.
 */
bool IsValidEntRef(int iEntRef)
{
    return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}
