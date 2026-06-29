/**
// ====================================================================================================
Change Log:

1.0.5 (10-March-2022)
    - Added missing model precache to prevent server crash when a Boomette die. (thanks "Mr. Man" for reporting)

1.0.4 (28-February-2022)
    - Added custom SI model variant support to all zombie classes. (thanks "TrevorSoldier" for requesting)

1.0.3 (18-January-2020)
    - Added cvar to configure the chance to apply a random model. (thanks "Tonblader" for requesting)

1.0.2 (11-January-2020)
    - Added cvar to enable custom SI models variant.

1.0.1 (02-December-2020)
    - Added cvar to control which type of player (human/bot) should apply the random model.

1.0.0 (01-December-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Random SI Models"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Turn the special infected models more random"
#define PLUGIN_VERSION                "1.0.5"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328929"

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
#define CONFIG_FILENAME               "l4d2_random_si_model"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_INFECTED                 3

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_WITCH        7
#define L4D2_ZOMBIECLASS_TANK         8

#define MODEL_SMOKER_L4D2             "models/infected/smoker.mdl"
#define MODEL_SMOKER_L4D1             "models/infected/smoker_l4d1.mdl"
#define MODEL_BOOMER_L4D2             "models/infected/boomer.mdl"
#define MODEL_BOOMETTE                "models/infected/boomette.mdl"
#define MODEL_BOOMER_L4D1             "models/infected/boomer_l4d1.mdl"
#define MODEL_HUNTER_L4D2             "models/infected/hunter.mdl"
#define MODEL_HUNTER_L4D1             "models/infected/hunter_l4d1.mdl"
#define MODEL_WITCH                   "models/infected/witch.mdl"
#define MODEL_WITCH_BRIDE             "models/infected/witch_bride.mdl"
#define MODEL_TANK_L4D2               "models/infected/hulk.mdl"
#define MODEL_TANK_DLC                "models/infected/hulk_dlc3.mdl"
#define MODEL_TANK_L4D1               "models/infected/hulk_l4d1.mdl"
#define MODEL_SPITTER_L4D2            "models/infected/spitter.mdl"
#define MODEL_JOCKEY_L4D2             "models/infected/jockey.mdl"
#define MODEL_CHARGER_L4D2            "models/infected/charger.mdl"

#define MODEL_EXPLODED_BOOMETTE       "models/infected/limbs/exploded_boomette.mdl"

#define CLIENT_HUMAN                  1
#define CLIENT_BOT                    2

#define TYPE_SMOKER_L4D2              1
#define TYPE_SMOKER_L4D1              2
#define TYPE_BOOMER_L4D2              1
#define TYPE_BOOMETTE                 2
#define TYPE_BOOMER_L4D1              4
#define TYPE_HUNTER_L4D2              1
#define TYPE_HUNTER_L4D1              2
#define TYPE_SPITTER_L4D2             1
#define TYPE_JOCKEY_L4D2              1
#define TYPE_CHARGER_L4D2             1
#define TYPE_WITCH                    1
#define TYPE_WITCH_BRIDE              2
#define TYPE_TANK_L4D2                1
#define TYPE_TANK_DLC                 2
#define TYPE_TANK_L4D1                4

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_ClientType;
ConVar g_hCvar_CustomChance;
ConVar g_hCvar_Smoker;
ConVar g_hCvar_SmokerChance;
ConVar g_hCvar_Boomer;
ConVar g_hCvar_BoomerChance;
ConVar g_hCvar_Hunter;
ConVar g_hCvar_HunterChance;
ConVar g_hCvar_Spitter;
ConVar g_hCvar_SpitterChance;
ConVar g_hCvar_Jockey;
ConVar g_hCvar_JockeyChance;
ConVar g_hCvar_Charger;
ConVar g_hCvar_ChargerChance;
ConVar g_hCvar_Witch;
ConVar g_hCvar_WitchChance;
ConVar g_hCvar_Tank;
ConVar g_hCvar_TankChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_ClientBot;
bool g_bCvar_ClientHuman;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_ClientType;
int g_iCvar_CustomChance;
int g_iCvar_Smoker;
int g_iCvar_SmokerChance;
int g_iCvar_Boomer;
int g_iCvar_BoomerChance;
int g_iCvar_Hunter;
int g_iCvar_HunterChance;
int g_iCvar_Spitter;
int g_iCvar_SpitterChance;
int g_iCvar_Jockey;
int g_iCvar_JockeyChance;
int g_iCvar_Charger;
int g_iCvar_ChargerChance;
int g_iCvar_Witch;
int g_iCvar_WitchChance;
int g_iCvar_Tank;
int g_iCvar_TankChance;
int g_iModel_Smoker_L4D2 = -1;
int g_iModel_Smoker_L4D1 = -1;
int g_iModel_Boomer_L4D2 = -1;
int g_iModel_Boomette = -1;
int g_iModel_Boomer_L4D1 = -1;
int g_iModel_Hunter_L4D2 = -1;
int g_iModel_Hunter_L4D1 = -1;
int g_iModel_Spitter_L4D2 = -1;
int g_iModel_Jockey_L4D2 = -1;
int g_iModel_Charger_L4D2 = -1;
int g_iModel_Witch = -1;
int g_iModel_Witch_Bride = -1;
int g_iModel_Tank_L4D2 = -1;
int g_iModel_Tank_DLC = -1;
int g_iModel_Tank_L4D1 = -1;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alModels;
ArrayList g_alSmoker;
ArrayList g_alBoomer;
ArrayList g_alHunter;
ArrayList g_alSpitter;
ArrayList g_alJockey;
ArrayList g_alCharger;
ArrayList g_alWitch;
ArrayList g_alTank;

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
    g_alModels = new ArrayList();
    g_alSmoker = new ArrayList();
    g_alBoomer = new ArrayList();
    g_alHunter = new ArrayList();
    g_alSpitter = new ArrayList();
    g_alJockey = new ArrayList();
    g_alCharger = new ArrayList();
    g_alWitch = new ArrayList();
    g_alTank = new ArrayList();

    CreateConVar("l4d2_random_si_model_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d2_random_si_model_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ClientType    = CreateConVar("l4d2_random_si_model_client_type", "3", "Which type of client (human/bot) should apply the random model.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_CustomChance  = CreateConVar("l4d2_random_si_model_custom_chance", "50", "Chance to keep the custom model (map variant).\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Smoker        = CreateConVar("l4d2_random_si_model_smoker", "3", "Random model for Smoker.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SmokerChance  = CreateConVar("l4d2_random_si_model_smoker_chance", "100", "Chance to apply a random model for Smoker.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Boomer        = CreateConVar("l4d2_random_si_model_boomer", "7", "Random model for Boomer.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable Boomette model. 4 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and Boomette model.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_BoomerChance  = CreateConVar("l4d2_random_si_model_boomer_chance", "100", "Chance to apply a random model for Boomer.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Hunter        = CreateConVar("l4d2_random_si_model_hunter", "3", "Random model for Hunter.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_HunterChance  = CreateConVar("l4d2_random_si_model_hunter_chance", "100", "Chance to apply a random model for Hunter.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Spitter       = CreateConVar("l4d2_random_si_model_spitter", "1", "Random model for Spitter.\n0 = Disable. 1 = Enable L4D2 model.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SpitterChance = CreateConVar("l4d2_random_si_model_spitter_chance", "100", "Chance to apply a random model for Spitter.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Jockey        = CreateConVar("l4d2_random_si_model_jockey", "1", "Random model for Jockey.\n0 = Disable. 1 = Enable L4D2 model.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_JockeyChance  = CreateConVar("l4d2_random_si_model_jockey_chance", "100", "Chance to apply a random model for Jockey.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Charger       = CreateConVar("l4d2_random_si_model_charger", "1", "Random model for Charger.\n0 = Disable. 1 = Enable L4D2 model.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ChargerChance = CreateConVar("l4d2_random_si_model_charger_chance", "100", "Chance to apply a random model for Charger.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Witch         = CreateConVar("l4d2_random_si_model_witch", "3", "Random model for Witch.\n0 = Disable. 1 = Enable Witch model. 2 = Enable Witch Bride model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables the Witch and Witch Bride model.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_WitchChance   = CreateConVar("l4d2_random_si_model_witch_chance", "100", "Chance to apply a random model for Witch.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Tank          = CreateConVar("l4d2_random_si_model_tank", "7", "Random model for Tank.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D2 DLC model. 4 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"5\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_TankChance    = CreateConVar("l4d2_random_si_model_tank_chance", "100", "Chance to apply a random model for Tank.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ClientType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CustomChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Smoker.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Boomer.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BoomerChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Hunter.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HunterChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Spitter.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpitterChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Jockey.AddChangeHook(Event_ConVarChanged);
    g_hCvar_JockeyChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Charger.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ChargerChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Witch.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WitchChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Tank.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TankChance.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_random_si_model", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    PrecacheModel(MODEL_EXPLODED_BOOMETTE, true); // Prevents server crash when a Boomette dies.

    g_iModel_Smoker_L4D2 = PrecacheModel(MODEL_SMOKER_L4D2, true);
    g_iModel_Smoker_L4D1 = PrecacheModel(MODEL_SMOKER_L4D1, true);
    g_iModel_Boomer_L4D2 = PrecacheModel(MODEL_BOOMER_L4D2, true);
    g_iModel_Boomette = PrecacheModel(MODEL_BOOMETTE, true);
    g_iModel_Boomer_L4D1 = PrecacheModel(MODEL_BOOMER_L4D1, true);
    g_iModel_Hunter_L4D2 = PrecacheModel(MODEL_HUNTER_L4D2, true);
    g_iModel_Hunter_L4D1 = PrecacheModel(MODEL_HUNTER_L4D1, true);
    g_iModel_Spitter_L4D2 = PrecacheModel(MODEL_SPITTER_L4D2, true);
    g_iModel_Jockey_L4D2 = PrecacheModel(MODEL_JOCKEY_L4D2, true);
    g_iModel_Charger_L4D2 = PrecacheModel(MODEL_CHARGER_L4D2, true);
    g_iModel_Witch = PrecacheModel(MODEL_WITCH, true);
    g_iModel_Witch_Bride = PrecacheModel(MODEL_WITCH_BRIDE, true);
    g_iModel_Tank_L4D2 = PrecacheModel(MODEL_TANK_L4D2, true);
    g_iModel_Tank_DLC = PrecacheModel(MODEL_TANK_DLC, true);
    g_iModel_Tank_L4D1 = PrecacheModel(MODEL_TANK_L4D1, true);

    g_alModels.Clear();
    g_alModels.Push(g_iModel_Smoker_L4D2);
    g_alModels.Push(g_iModel_Smoker_L4D1);
    g_alModels.Push(g_iModel_Boomer_L4D2);
    g_alModels.Push(g_iModel_Boomette);
    g_alModels.Push(g_iModel_Boomer_L4D1);
    g_alModels.Push(g_iModel_Hunter_L4D2);
    g_alModels.Push(g_iModel_Hunter_L4D1);
    g_alModels.Push(g_iModel_Spitter_L4D2);
    g_alModels.Push(g_iModel_Jockey_L4D2);
    g_alModels.Push(g_iModel_Charger_L4D2);
    g_alModels.Push(g_iModel_Witch);
    g_alModels.Push(g_iModel_Witch_Bride);
    g_alModels.Push(g_iModel_Tank_L4D2);
    g_alModels.Push(g_iModel_Tank_DLC);
    g_alModels.Push(g_iModel_Tank_L4D1);
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
    g_iCvar_ClientType = g_hCvar_ClientType.IntValue;
    g_bCvar_ClientBot = (g_iCvar_ClientType & CLIENT_BOT ? true : false);
    g_bCvar_ClientHuman = (g_iCvar_ClientType & CLIENT_HUMAN ? true : false);
    g_iCvar_CustomChance = g_hCvar_CustomChance.IntValue;
    g_iCvar_Smoker = g_hCvar_Smoker.IntValue;
    g_iCvar_SmokerChance = g_hCvar_SmokerChance.IntValue;
    g_iCvar_Boomer = g_hCvar_Boomer.IntValue;
    g_iCvar_BoomerChance = g_hCvar_BoomerChance.IntValue;
    g_iCvar_Hunter = g_hCvar_Hunter.IntValue;
    g_iCvar_HunterChance = g_hCvar_HunterChance.IntValue;
    g_iCvar_Spitter = g_hCvar_Spitter.IntValue;
    g_iCvar_SpitterChance = g_hCvar_SpitterChance.IntValue;
    g_iCvar_Jockey = g_hCvar_Jockey.IntValue;
    g_iCvar_JockeyChance = g_hCvar_JockeyChance.IntValue;
    g_iCvar_Charger = g_hCvar_Charger.IntValue;
    g_iCvar_ChargerChance = g_hCvar_ChargerChance.IntValue;
    g_iCvar_Witch = g_hCvar_Witch.IntValue;
    g_iCvar_WitchChance = g_hCvar_WitchChance.IntValue;
    g_iCvar_Tank = g_hCvar_Tank.IntValue;
    g_iCvar_TankChance = g_hCvar_TankChance.IntValue;

    BuildStringMaps();
}

/****************************************************************************************************/

void BuildStringMaps()
{
    g_alSmoker.Clear();
    if (g_iCvar_Smoker & TYPE_SMOKER_L4D2)
        g_alSmoker.Push(TYPE_SMOKER_L4D2);
    if (g_iCvar_Smoker & TYPE_SMOKER_L4D1)
        g_alSmoker.Push(TYPE_SMOKER_L4D1);

    g_alBoomer.Clear();
    if (g_iCvar_Boomer & TYPE_BOOMER_L4D2)
        g_alBoomer.Push(TYPE_BOOMER_L4D2);
    if (g_iCvar_Boomer & TYPE_BOOMETTE)
        g_alBoomer.Push(TYPE_BOOMETTE);
    if (g_iCvar_Boomer & TYPE_BOOMER_L4D1)
        g_alBoomer.Push(TYPE_BOOMER_L4D1);

    g_alHunter.Clear();
    if (g_iCvar_Hunter & TYPE_HUNTER_L4D2)
        g_alHunter.Push(TYPE_HUNTER_L4D2);
    if (g_iCvar_Hunter & TYPE_HUNTER_L4D1)
        g_alHunter.Push(TYPE_HUNTER_L4D1);

    g_alSpitter.Clear();
    g_alSpitter.Push(TYPE_SPITTER_L4D2);

    g_alJockey.Clear();
    g_alJockey.Push(TYPE_JOCKEY_L4D2);

    g_alCharger.Clear();
    g_alCharger.Push(TYPE_CHARGER_L4D2);

    g_alWitch.Clear();
    if (g_iCvar_Witch & TYPE_WITCH)
        g_alWitch.Push(TYPE_WITCH);
    if (g_iCvar_Witch & TYPE_WITCH_BRIDE)
        g_alWitch.Push(TYPE_WITCH_BRIDE);

    g_alTank.Clear();
    if (g_iCvar_Tank & TYPE_TANK_L4D2)
        g_alTank.Push(TYPE_TANK_L4D2);
    if (g_iCvar_Tank & TYPE_TANK_DLC)
        g_alTank.Push(TYPE_TANK_DLC);
    if (g_iCvar_Tank & TYPE_TANK_L4D1)
        g_alTank.Push(TYPE_TANK_L4D1);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (GetClientTeam(client) != TEAM_INFECTED)
            continue;

        if (!IsPlayerAlive(client))
            continue;

        if (IsPlayerGhost(client))
            continue;

        int zombieclass = GetZombieClass(client);

        switch (zombieclass)
        {
            case L4D2_ZOMBIECLASS_SMOKER: SetSpecialInfectedModel(client, zombieclass);
            case L4D2_ZOMBIECLASS_BOOMER: SetSpecialInfectedModel(client, zombieclass);
            case L4D2_ZOMBIECLASS_HUNTER: SetSpecialInfectedModel(client, zombieclass);
            case L4D2_ZOMBIECLASS_SPITTER: SetSpecialInfectedModel(client, zombieclass);
            case L4D2_ZOMBIECLASS_JOCKEY: SetSpecialInfectedModel(client, zombieclass);
            case L4D2_ZOMBIECLASS_CHARGER: SetSpecialInfectedModel(client, zombieclass);
            case L4D2_ZOMBIECLASS_TANK: SetSpecialInfectedModel(client, zombieclass);
        }
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
    {
       SetSpecialInfectedModel(entity, L4D2_ZOMBIECLASS_WITCH);
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("witch_spawn", Event_WitchSpawn);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("witch_spawn", Event_WitchSpawn);

        return;
    }
}

/****************************************************************************************************/

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
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
    }

    int zombieclass = GetZombieClass(client);

    switch (zombieclass)
    {
        case L4D2_ZOMBIECLASS_SMOKER: SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_BOOMER: SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_HUNTER: SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_SPITTER: SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_JOCKEY: SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_CHARGER: SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_TANK: SetSpecialInfectedModel(client, zombieclass);
    }
}

/****************************************************************************************************/

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("witchid");
    SetSpecialInfectedModel(entity, L4D2_ZOMBIECLASS_WITCH);
}

/****************************************************************************************************/

void SetSpecialInfectedModel(int entity, int zombieclass)
{
    bool customModel = (g_alModels.FindValue(GetEntProp(entity, Prop_Send, "m_nModelIndex")) == -1);

    if (customModel)
    {
        if (g_iCvar_CustomChance < GetRandomInt(1, 100))
            return;
    }

    switch (zombieclass)
    {
        case L4D2_ZOMBIECLASS_SMOKER:
        {
            if (g_iCvar_SmokerChance < GetRandomInt(1, 100))
                return;

            if (g_alSmoker.Length == 0)
                return;

            switch (g_alSmoker.Get(GetRandomInt(0, g_alSmoker.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_SMOKER_L4D2);
                case 2: SetEntityModel(entity, MODEL_SMOKER_L4D1);
            }
        }
        case L4D2_ZOMBIECLASS_BOOMER:
        {
            if (g_iCvar_BoomerChance < GetRandomInt(1, 100))
                return;

            if (g_alBoomer.Length == 0)
                return;

            switch (g_alBoomer.Get(GetRandomInt(0, g_alBoomer.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_BOOMER_L4D2);
                case 2: SetEntityModel(entity, MODEL_BOOMETTE);
                case 4: SetEntityModel(entity, MODEL_BOOMER_L4D1);
            }
        }
        case L4D2_ZOMBIECLASS_HUNTER:
        {
            if (g_iCvar_HunterChance < GetRandomInt(1, 100))
                return;

            if (g_alHunter.Length == 0)
                return;

            switch (g_alHunter.Get(GetRandomInt(0, g_alHunter.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_HUNTER_L4D2);
                case 2: SetEntityModel(entity, MODEL_HUNTER_L4D1);
            }
        }
        case L4D2_ZOMBIECLASS_SPITTER:
        {
            if (g_iCvar_SpitterChance < GetRandomInt(1, 100))
                return;

            if (g_alSpitter.Length == 0)
                return;

            switch (g_alSpitter.Get(GetRandomInt(0, g_alSpitter.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_SPITTER_L4D2);
            }
        }
        case L4D2_ZOMBIECLASS_JOCKEY:
        {
            if (g_iCvar_JockeyChance < GetRandomInt(1, 100))
                return;

            if (g_alJockey.Length == 0)
                return;

            switch (g_alJockey.Get(GetRandomInt(0, g_alJockey.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_JOCKEY_L4D2);
            }
        }
        case L4D2_ZOMBIECLASS_CHARGER:
        {
            if (g_iCvar_ChargerChance < GetRandomInt(1, 100))
                return;

            if (g_alCharger.Length == 0)
                return;

            switch (g_alCharger.Get(GetRandomInt(0, g_alCharger.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_CHARGER_L4D2);
            }
        }
        case L4D2_ZOMBIECLASS_WITCH:
        {
            if (g_iCvar_WitchChance < GetRandomInt(1, 100))
                return;

            if (g_alWitch.Length == 0)
                return;

            switch (g_alWitch.Get(GetRandomInt(0, g_alWitch.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_WITCH);
                case 2: SetEntityModel(entity, MODEL_WITCH_BRIDE);
            }
        }
        case L4D2_ZOMBIECLASS_TANK:
        {
            if (g_iCvar_TankChance < GetRandomInt(1, 100))
                return;

            if (g_alTank.Length == 0)
                return;

            switch (g_alTank.Get(GetRandomInt(0, g_alTank.Length-1)))
            {
                case 1: SetEntityModel(entity, MODEL_TANK_L4D2);
                case 2: SetEntityModel(entity, MODEL_TANK_DLC);
                case 4: SetEntityModel(entity, MODEL_TANK_L4D1);
            }
        }
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
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_random_si_model) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_random_si_model_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_random_si_model_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_client_type : %i (HUMAN = %s | BOT = %s)", g_iCvar_ClientType, g_iCvar_ClientType & CLIENT_HUMAN ? "true" : "false", g_iCvar_ClientType & CLIENT_BOT ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_custom_chance : %i%%", g_iCvar_CustomChance);
    PrintToConsole(client, "l4d2_random_si_model_smoker : %i (SMOKER_L4D2 = %s | SMOKER_L4D1 = %s)", g_iCvar_Smoker, g_iCvar_Smoker & TYPE_SMOKER_L4D2 ? "true" : "false", g_iCvar_Smoker & TYPE_SMOKER_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_smoker_chance : %i%%", g_iCvar_SmokerChance);
    PrintToConsole(client, "l4d2_random_si_model_boomer : %i (BOOMER_L4D2 = %s | BOOMETTE = %s | BOOMER_L4D1 = %s)", g_iCvar_Boomer, g_iCvar_Boomer & TYPE_BOOMER_L4D2 ? "true" : "false", g_iCvar_Boomer & TYPE_BOOMETTE ? "true" : "false", g_iCvar_Boomer & TYPE_BOOMER_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_boomer_chance : %i%%", g_iCvar_BoomerChance);
    PrintToConsole(client, "l4d2_random_si_model_hunter : %i (HUNTER_L4D2 = %s | HUNTER_L4D1 = %s)", g_iCvar_Hunter, g_iCvar_Hunter & TYPE_HUNTER_L4D2 ? "true" : "false", g_iCvar_Hunter & TYPE_HUNTER_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_hunter_chance : %i%%", g_iCvar_HunterChance);
    PrintToConsole(client, "l4d2_random_si_model_spitter : %i (SPITTER_L4D2 = %s)", g_iCvar_Spitter, g_iCvar_Spitter & TYPE_SPITTER_L4D2 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_spitter_chance : %i%%", g_iCvar_SpitterChance);
    PrintToConsole(client, "l4d2_random_si_model_jockey : %i (JOCKEY_L4D2 = %s)", g_iCvar_Jockey, g_iCvar_Jockey & TYPE_JOCKEY_L4D2 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_jockey_chance : %i%%", g_iCvar_JockeyChance);
    PrintToConsole(client, "l4d2_random_si_model_charger : %i (CHARGER_L4D2 = %s)", g_iCvar_Charger, g_iCvar_Charger & TYPE_CHARGER_L4D2 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_charger_chance : %i%%", g_iCvar_ChargerChance);
    PrintToConsole(client, "l4d2_random_si_model_witch : %i (WITCH = %s | WITCH_BRIDE = %s)", g_iCvar_Witch, g_iCvar_Witch & TYPE_WITCH ? "true" : "false", g_iCvar_Witch & TYPE_WITCH_BRIDE ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_witch_chance : %i%%", g_iCvar_WitchChance);
    PrintToConsole(client, "l4d2_random_si_model_tank : %i (TANK_L4D2 = %s | TANK_DLC = %s | TANK_L4D1 = %s)", g_iCvar_Tank, g_iCvar_Tank & TYPE_TANK_L4D2 ? "true" : "false", g_iCvar_Tank & TYPE_TANK_DLC ? "true" : "false", g_iCvar_Tank & TYPE_TANK_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_tank_chance : %i%%", g_iCvar_TankChance);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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
 * Returns if the client is in ghost state.
 *
 * @param client     Client index.
 * @return           True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}