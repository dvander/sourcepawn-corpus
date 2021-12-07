/**
// ====================================================================================================
Change Log:

1.0.3 (18-January-2020)
    - Added cvar to configure the chance to apply a random model.

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
#define PLUGIN_VERSION                "1.0.3"
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
#define CLASSNAME_WITCH               "witch"

#define TEAM_INFECTED                 3

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_WITCH        7
#define L4D2_ZOMBIECLASS_TANK         8

#define MODEL_SMOKER_L4D2             "models/infected/smoker.mdl"
#define MODEL_SMOKER_L4D1             "models/infected/smoker_l4d1.mdl"
#define MODEL_BOOMER_L4D2             "models/infected/boomer.mdl"
#define MODEL_BOOMETTE                "models/infected/boomette.mdl"
#define MODEL_EXPLODED_BOOMETTE       "models/infected/limbs/exploded_boomette.mdl"
#define MODEL_BOOMER_L4D1             "models/infected/boomer_l4d1.mdl"
#define MODEL_HUNTER_L4D2             "models/infected/hunter.mdl"
#define MODEL_HUNTER_L4D1             "models/infected/hunter_l4d1.mdl"
#define MODEL_WITCH                   "models/infected/witch.mdl"
#define MODEL_WITCH_BRIDE             "models/infected/witch_bride.mdl"
#define MODEL_TANK_L4D2               "models/infected/hulk.mdl"
#define MODEL_TANK_DLC                "models/infected/hulk_dlc3.mdl"
#define MODEL_TANK_L4D1               "models/infected/hulk_l4d1.mdl"

#define CLIENT_HUMAN                  1
#define CLIENT_BOT                    2

#define TYPE_SMOKER_L4D2              1
#define TYPE_SMOKER_L4D1              2
#define TYPE_BOOMER_L4D2              1
#define TYPE_BOOMETTE                 2
#define TYPE_BOOMER_L4D1              4
#define TYPE_HUNTER_L4D2              1
#define TYPE_HUNTER_L4D1              2
#define TYPE_WITCH                    1
#define TYPE_WITCH_BRIDE              2
#define TYPE_TANK_L4D2                1
#define TYPE_TANK_DLC                 2
#define TYPE_TANK_L4D1                4

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Custom;
static ConVar g_hCvar_ClientType;
static ConVar g_hCvar_Smoker;
static ConVar g_hCvar_SmokerChance;
static ConVar g_hCvar_Boomer;
static ConVar g_hCvar_BoomerChance;
static ConVar g_hCvar_Hunter;
static ConVar g_hCvar_HunterChance;
static ConVar g_hCvar_Witch;
static ConVar g_hCvar_WitchChance;
static ConVar g_hCvar_Tank;
static ConVar g_hCvar_TankChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Custom;
static bool   g_bCvar_Smoker;
static bool   g_bCvar_SmokerChance;
static bool   g_bCvar_Boomer;
static bool   g_bCvar_BoomerChance;
static bool   g_bCvar_Hunter;
static bool   g_bCvar_HunterChance;
static bool   g_bCvar_Witch;
static bool   g_bCvar_WitchChance;
static bool   g_bCvar_Tank;
static bool   g_bCvar_TankChance;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int   g_iCvar_ClientType;
static int   g_iCvar_Smoker;
static int   g_iCvar_Boomer;
static int   g_iCvar_Hunter;
static int   g_iCvar_Witch;
static int   g_iCvar_Tank;
static int   g_iModel_Smoker_L4D2 = -1;
static int   g_iModel_Smoker_L4D1 = -1;
static int   g_iModel_Boomer_L4D2 = -1;
static int   g_iModel_Boomette = -1;
static int   g_iModel_Boomer_L4D1 = -1;
static int   g_iModel_Hunter_L4D2 = -1;
static int   g_iModel_Hunter_L4D1 = -1;
static int   g_iModel_Witch = -1;
static int   g_iModel_Witch_Bride = -1;
static int   g_iModel_Tank_L4D2 = -1;
static int   g_iModel_Tank_DLC = -1;
static int   g_iModel_Tank_L4D1 = -1;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float g_fCvar_SmokerChance;
static float g_fCvar_BoomerChance;
static float g_fCvar_HunterChance;
static float g_fCvar_WitchChance;
static float g_fCvar_TankChance;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
static ArrayList g_alModels;
static ArrayList g_alSmoker;
static ArrayList g_alBoomer;
static ArrayList g_alHunter;
static ArrayList g_alWitch;
static ArrayList g_alTank;

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

    g_alModels = new ArrayList();
    g_alSmoker = new ArrayList();
    g_alBoomer = new ArrayList();
    g_alHunter = new ArrayList();
    g_alWitch = new ArrayList();
    g_alTank = new ArrayList();

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d2_random_si_model_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled      = CreateConVar("l4d2_random_si_model_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Custom       = CreateConVar("l4d2_random_si_model_custom", "0", "Apply random models to custom SI models (map variant).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ClientType   = CreateConVar("l4d2_random_si_model_client_type", "3", "Which type of client (human/bot) should apply the random model.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_Smoker       = CreateConVar("l4d2_random_si_model_smoker", "3", "Random model for Smoker.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SmokerChance = CreateConVar("l4d2_random_si_model_smoker_chance", "100.0", "Chance to apply a random model for Smoker.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Boomer       = CreateConVar("l4d2_random_si_model_boomer", "7", "Random model for Boomer.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable Boomette model. 4 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and Boomette model.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_BoomerChance = CreateConVar("l4d2_random_si_model_boomer_chance", "100.0", "Chance to apply a random model for Boomer.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Hunter       = CreateConVar("l4d2_random_si_model_hunter", "3", "Random model for Hunter.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_HunterChance = CreateConVar("l4d2_random_si_model_hunter_chance", "100.0", "Chance to apply a random model for Hunter.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Witch        = CreateConVar("l4d2_random_si_model_witch", "3", "Random model for Witch.\n0 = Disable. 1 = Enable Witch model. 2 = Enable Witch Bride model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables the Witch and Witch Bride model.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_WitchChance  = CreateConVar("l4d2_random_si_model_witch_chance", "100.0", "Chance to apply a random model for Witch.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Tank         = CreateConVar("l4d2_random_si_model_tank", "7", "Random model for Tank.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D2 DLC model. 4 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"5\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_TankChance   = CreateConVar("l4d2_random_si_model_tank_chance", "100.0", "Chance to apply a random model for Tank.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Custom.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ClientType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Smoker.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Boomer.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BoomerChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Hunter.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HunterChance.AddChangeHook(Event_ConVarChanged);
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
    g_iModel_Smoker_L4D2 = PrecacheModel(MODEL_SMOKER_L4D2, true);
    g_iModel_Smoker_L4D1 = PrecacheModel(MODEL_SMOKER_L4D1, true);
    g_iModel_Boomer_L4D2 = PrecacheModel(MODEL_BOOMER_L4D2, true);
    PrecacheModel(MODEL_EXPLODED_BOOMETTE, true); // Prevents server crash when a Boomette dies.
    g_iModel_Boomette = PrecacheModel(MODEL_BOOMETTE, true);
    g_iModel_Boomer_L4D1 = PrecacheModel(MODEL_BOOMER_L4D1, true);
    g_iModel_Hunter_L4D2 = PrecacheModel(MODEL_HUNTER_L4D2, true);
    g_iModel_Hunter_L4D1 = PrecacheModel(MODEL_HUNTER_L4D1, true);
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
    g_bCvar_Custom = g_hCvar_Custom.BoolValue;
    g_iCvar_ClientType = g_hCvar_ClientType.IntValue;
    g_iCvar_Smoker = g_hCvar_Smoker.IntValue;
    g_bCvar_Smoker = (g_iCvar_Smoker > 0);
    g_fCvar_SmokerChance = g_hCvar_SmokerChance.FloatValue;
    g_bCvar_SmokerChance = (g_fCvar_SmokerChance > 0.0);
    g_iCvar_Boomer = g_hCvar_Boomer.IntValue;
    g_bCvar_Boomer = (g_iCvar_Boomer > 0);
    g_fCvar_BoomerChance = g_hCvar_BoomerChance.FloatValue;
    g_bCvar_BoomerChance = (g_fCvar_BoomerChance > 0.0);
    g_iCvar_Hunter = g_hCvar_Hunter.IntValue;
    g_bCvar_Hunter = (g_iCvar_Hunter > 0);
    g_fCvar_HunterChance = g_hCvar_HunterChance.FloatValue;
    g_bCvar_HunterChance = (g_fCvar_HunterChance > 0.0);
    g_iCvar_Witch = g_hCvar_Witch.IntValue;
    g_bCvar_Witch = (g_iCvar_Witch > 0);
    g_fCvar_WitchChance = g_hCvar_WitchChance.FloatValue;
    g_bCvar_WitchChance = (g_fCvar_WitchChance > 0.0);
    g_iCvar_Tank = g_hCvar_Tank.IntValue;
    g_bCvar_Tank = (g_iCvar_Tank > 0);
    g_fCvar_TankChance = g_hCvar_TankChance.FloatValue;
    g_bCvar_TankChance = (g_fCvar_TankChance > 0.0);

    BuildMaps();
}

/****************************************************************************************************/

public void BuildMaps()
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

public void LateLoad()
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
            case L4D2_ZOMBIECLASS_SMOKER: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_SMOKER);
            case L4D2_ZOMBIECLASS_BOOMER: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_BOOMER);
            case L4D2_ZOMBIECLASS_HUNTER: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_HUNTER);
            case L4D2_ZOMBIECLASS_TANK: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_TANK);
        }
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_WITCH)) != INVALID_ENT_REFERENCE)
    {
       SetSpecialInfectedModel(entity, L4D2_ZOMBIECLASS_WITCH);
    }
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("witch_spawn", Event_WitchSpawn);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("witch_spawn", Event_WitchSpawn);

        return;
    }
}

/****************************************************************************************************/

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
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

    int zombieclass = GetZombieClass(client);

    switch (zombieclass)
    {
        case L4D2_ZOMBIECLASS_SMOKER: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_SMOKER);
        case L4D2_ZOMBIECLASS_BOOMER: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_BOOMER);
        case L4D2_ZOMBIECLASS_HUNTER: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_HUNTER);
        case L4D2_ZOMBIECLASS_TANK: SetSpecialInfectedModel(client, L4D2_ZOMBIECLASS_TANK);
    }
}

/****************************************************************************************************/

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = event.GetInt("witchid");
    SetSpecialInfectedModel(entity, L4D2_ZOMBIECLASS_WITCH);
}

/****************************************************************************************************/

public void SetSpecialInfectedModel(int entity, int zombieclass)
{
    bool customModel = (g_alModels.FindValue(GetEntProp(entity, Prop_Send, "m_nModelIndex")) == -1);

    if (customModel)
    {
        if (!g_bCvar_Custom)
            return;

        if (GetRandomInt(0, 1) == 0)
            return;
    }

    switch (zombieclass)
    {
        case L4D2_ZOMBIECLASS_SMOKER:
        {
            if (!g_bCvar_Smoker)
                return;

            if (!g_bCvar_SmokerChance)
                return;

            if (g_fCvar_SmokerChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_alSmoker.Length == 0)
                return;

            switch (g_alSmoker.Get(GetRandomInt(0, g_alSmoker.Length - 1)))
            {
                case 1: SetEntityModel(entity, MODEL_SMOKER_L4D2);
                case 2: SetEntityModel(entity, MODEL_SMOKER_L4D1);
            }
        }
        case L4D2_ZOMBIECLASS_BOOMER:
        {
            if (!g_bCvar_Boomer)
                return;

            if (!g_bCvar_BoomerChance)
                return;

            if (g_fCvar_BoomerChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_alBoomer.Length == 0)
                return;

            switch (g_alBoomer.Get(GetRandomInt(0, g_alBoomer.Length - 1)))
            {
                case 1: SetEntityModel(entity, MODEL_BOOMER_L4D2);
                case 2: SetEntityModel(entity, MODEL_BOOMETTE);
                case 4: SetEntityModel(entity, MODEL_BOOMER_L4D1);
            }
        }
        case L4D2_ZOMBIECLASS_HUNTER:
        {
            if (!g_bCvar_Hunter)
                return;

            if (!g_bCvar_HunterChance)
                return;

            if (g_fCvar_HunterChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_alHunter.Length == 0)
                return;

            switch (g_alHunter.Get(GetRandomInt(0, g_alHunter.Length - 1)))
            {
                case 1: SetEntityModel(entity, MODEL_HUNTER_L4D2);
                case 2: SetEntityModel(entity, MODEL_HUNTER_L4D1);
            }
        }
        case L4D2_ZOMBIECLASS_WITCH:
        {
            if (!g_bCvar_Witch)
                return;

            if (!g_bCvar_WitchChance)
                return;

            if (g_fCvar_WitchChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_alWitch.Length == 0)
                return;

            switch (g_alWitch.Get(GetRandomInt(0, g_alWitch.Length - 1)))
            {
                case 1: SetEntityModel(entity, MODEL_WITCH);
                case 2: SetEntityModel(entity, MODEL_WITCH_BRIDE);
            }
        }
        case L4D2_ZOMBIECLASS_TANK:
        {
            if (!g_bCvar_Tank)
                return;

            if (!g_bCvar_TankChance)
                return;

            if (g_fCvar_TankChance < GetRandomFloat(0.0, 100.0))
                return;

            if (g_alTank.Length == 0)
                return;

            switch (g_alTank.Get(GetRandomInt(0, g_alTank.Length - 1)))
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
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_random_si_model) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_random_si_model_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_random_si_model_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_custom : %b (%s)", g_bCvar_Custom, g_bCvar_Custom ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_client_type : %i (HUMAN = %s | BOT = %s)", g_iCvar_ClientType, g_iCvar_ClientType & CLIENT_HUMAN ? "true" : "false", g_iCvar_ClientType & CLIENT_BOT ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_smoker : %i (%s)", g_iCvar_Smoker, g_bCvar_Smoker ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_smoker_chance : %.2f%% (%s)", g_fCvar_SmokerChance, g_bCvar_SmokerChance ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_boomer : %i (%s)", g_iCvar_Boomer, g_bCvar_Boomer ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_boomer_chance : %.2f%% (%s)", g_fCvar_BoomerChance, g_bCvar_BoomerChance ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_hunter : %i (%s)", g_iCvar_Hunter, g_bCvar_Hunter ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_hunter_chance : %.2f%% (%s)", g_fCvar_HunterChance, g_bCvar_HunterChance ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_witch : %i (%s)", g_iCvar_Witch, g_bCvar_Witch ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_witch_chance : %.2f%% (%s)", g_fCvar_WitchChance, g_bCvar_WitchChance ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_tank : %i (%s)", g_iCvar_Tank, g_bCvar_Tank ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_tank_chance : %.2f%% (%s)", g_fCvar_TankChance, g_bCvar_TankChance ? "true" : "false");
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