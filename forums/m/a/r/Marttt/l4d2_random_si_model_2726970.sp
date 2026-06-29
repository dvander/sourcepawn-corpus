/**
// ====================================================================================================
Change Log:

1.0.6 (20-October-2024)
    - Added check to prevent Tank model changes breaking Suicide Blitz 2 finale. (thanks "yabi" for reporting)

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
#define PLUGIN_VERSION                "1.0.6"
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
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{

    ConVar l4d2_random_si_model_version;
    ConVar l4d2_random_si_model_enable;
    ConVar l4d2_random_si_model_client_type;
    ConVar l4d2_random_si_model_custom_change;
    ConVar l4d2_random_si_model_smoker;
    ConVar l4d2_random_si_model_smoker_chance;
    ConVar l4d2_random_si_model_boomer;
    ConVar l4d2_random_si_model_boomer_chance;
    ConVar l4d2_random_si_model_hunter;
    ConVar l4d2_random_si_model_hunter_chance;
    ConVar l4d2_random_si_model_spitter;
    ConVar l4d2_random_si_model_spitter_chance;
    ConVar l4d2_random_si_model_jockey;
    ConVar l4d2_random_si_model_jockey_chance;
    ConVar l4d2_random_si_model_charger;
    ConVar l4d2_random_si_model_charger_chance;
    ConVar l4d2_random_si_model_witch;
    ConVar l4d2_random_si_model_witch_chance;
    ConVar l4d2_random_si_model_tank;
    ConVar l4d2_random_si_model_tank_chance;

    void Init()
    {
        this.l4d2_random_si_model_version        = CreateConVar("l4d2_random_si_model_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d2_random_si_model_enable         = CreateConVar("l4d2_random_si_model_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_random_si_model_client_type    = CreateConVar("l4d2_random_si_model_client_type", "3", "Which type of client (human/bot) should apply the random model.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);
        this.l4d2_random_si_model_custom_change  = CreateConVar("l4d2_random_si_model_custom_chance", "50", "Chance to keep the custom model (map variant).\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_smoker         = CreateConVar("l4d2_random_si_model_smoker", "3", "Random model for Smoker.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 3.0);
        this.l4d2_random_si_model_smoker_chance  = CreateConVar("l4d2_random_si_model_smoker_chance", "100", "Chance to apply a random model for Smoker.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_boomer         = CreateConVar("l4d2_random_si_model_boomer", "7", "Random model for Boomer.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable Boomette model. 4 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and Boomette model.", CVAR_FLAGS, true, 0.0, true, 7.0);
        this.l4d2_random_si_model_boomer_chance  = CreateConVar("l4d2_random_si_model_boomer_chance", "100", "Chance to apply a random model for Boomer.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_hunter         = CreateConVar("l4d2_random_si_model_hunter", "3", "Random model for Hunter.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 3.0);
        this.l4d2_random_si_model_hunter_chance  = CreateConVar("l4d2_random_si_model_hunter_chance", "100", "Chance to apply a random model for Hunter.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_spitter        = CreateConVar("l4d2_random_si_model_spitter", "1", "Random model for Spitter.\n0 = Disable. 1 = Enable L4D2 model.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_random_si_model_spitter_chance = CreateConVar("l4d2_random_si_model_spitter_chance", "100", "Chance to apply a random model for Spitter.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_jockey         = CreateConVar("l4d2_random_si_model_jockey", "1", "Random model for Jockey.\n0 = Disable. 1 = Enable L4D2 model.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_random_si_model_jockey_chance  = CreateConVar("l4d2_random_si_model_jockey_chance", "100", "Chance to apply a random model for Jockey.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_charger        = CreateConVar("l4d2_random_si_model_charger", "1", "Random model for Charger.\n0 = Disable. 1 = Enable L4D2 model.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_random_si_model_charger_chance = CreateConVar("l4d2_random_si_model_charger_chance", "100", "Chance to apply a random model for Charger.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_witch          = CreateConVar("l4d2_random_si_model_witch", "3", "Random model for Witch.\n0 = Disable. 1 = Enable Witch model. 2 = Enable Witch Bride model.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables the Witch and Witch Bride model.", CVAR_FLAGS, true, 0.0, true, 3.0);
        this.l4d2_random_si_model_witch_chance   = CreateConVar("l4d2_random_si_model_witch_chance", "100", "Chance to apply a random model for Witch.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
        this.l4d2_random_si_model_tank           = CreateConVar("l4d2_random_si_model_tank", "7", "Random model for Tank.\n0 = Disable. 1 = Enable L4D2 model. 2 = Enable L4D2 DLC model. 4 = Enable L4D1 model.\nAdd numbers greater than 0 for multiple options.\nExample: \"5\", enables L4D2 and L4D1 model.", CVAR_FLAGS, true, 0.0, true, 7.0);
        this.l4d2_random_si_model_tank_chance    = CreateConVar("l4d2_random_si_model_tank_chance", "100", "Chance to apply a random model for Tank.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

        this.l4d2_random_si_model_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_client_type.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_custom_change.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_smoker.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_smoker_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_boomer.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_boomer_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_hunter.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_hunter_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_spitter.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_spitter_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_jockey.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_jockey_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_charger.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_charger_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_witch.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_witch_chance.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_tank.AddChangeHook(Event_ConVarChanged);
        this.l4d2_random_si_model_tank_chance.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    ArrayList modelIndexes;
    ArrayList smokerVariants;
    ArrayList boomerVariants;
    ArrayList hunterVariants;
    ArrayList spitterVariants;
    ArrayList jockeyVariants;
    ArrayList chargerVariants;
    ArrayList witchVariants;
    ArrayList tankVariants;

    bool isMap_l4d2_stadium5_stadium;
    int modelIndexSmoker_L4D2;
    int modelIndexSmoker_L4D1;
    int modelIndexBoomer_L4D2;
    int modelIndexBoomette;
    int modelIndexBoomer_L4D1;
    int modelIndexHunter_L4D2;
    int modelIndexHunter_L4D1;
    int modelIndexSpitter_L4D2;
    int modelIndexJockey_L4D2;
    int modelIndexCharger_L4D2;
    int modelIndexWitch;
    int modelIndexWitch_Bride;
    int modelIndexTank_L4D2;
    int modelIndexTank_DLC;
    int modelIndexTank_L4D1;
    bool eventsHooked;
    bool enable;
    int clientType;
    bool clientBot;
    bool clientHuman;
    int customChance;
    int smoker;
    int smokerChance;
    int boomer;
    int boomerChance;
    int hunter;
    int hunterChance;
    int spitter;
    int spitterChance;
    int jockey;
    int jockeyChance;
    int charger;
    int chargerChance;
    int witch;
    int witchChance;
    int tank;
    int tankChance;

    void Init()
    {
        this.modelIndexes = new ArrayList();
        this.smokerVariants = new ArrayList();
        this.boomerVariants = new ArrayList();
        this.hunterVariants = new ArrayList();
        this.spitterVariants = new ArrayList();
        this.jockeyVariants = new ArrayList();
        this.chargerVariants = new ArrayList();
        this.witchVariants = new ArrayList();
        this.tankVariants = new ArrayList();
        this.modelIndexSmoker_L4D2 = -1;
        this.modelIndexSmoker_L4D1 = -1;
        this.modelIndexBoomer_L4D2 = -1;
        this.modelIndexBoomette = -1;
        this.modelIndexBoomer_L4D1 = -1;
        this.modelIndexHunter_L4D2 = -1;
        this.modelIndexHunter_L4D1 = -1;
        this.modelIndexSpitter_L4D2 = -1;
        this.modelIndexJockey_L4D2 = -1;
        this.modelIndexCharger_L4D2 = -1;
        this.modelIndexWitch = -1;
        this.modelIndexWitch_Bride = -1;
        this.modelIndexTank_L4D2 = -1;
        this.modelIndexTank_DLC = -1;
        this.modelIndexTank_L4D1 = -1;
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d2_random_si_model_enable.BoolValue;
        this.clientType = this.cvars.l4d2_random_si_model_client_type.IntValue;
        this.clientBot = this.clientType & CLIENT_BOT ? true : false;
        this.clientHuman = this.clientType & CLIENT_HUMAN ? true : false;
        this.customChance = this.cvars.l4d2_random_si_model_custom_change.IntValue;
        this.smoker = this.cvars.l4d2_random_si_model_smoker.IntValue;
        this.smokerChance = this.cvars.l4d2_random_si_model_smoker_chance.IntValue;
        this.boomer = this.cvars.l4d2_random_si_model_boomer.IntValue;
        this.boomerChance = this.cvars.l4d2_random_si_model_boomer_chance.IntValue;
        this.hunter = this.cvars.l4d2_random_si_model_hunter.IntValue;
        this.hunterChance = this.cvars.l4d2_random_si_model_hunter_chance.IntValue;
        this.spitter = this.cvars.l4d2_random_si_model_spitter.IntValue;
        this.spitterChance = this.cvars.l4d2_random_si_model_spitter_chance.IntValue;
        this.jockey = this.cvars.l4d2_random_si_model_jockey.IntValue;
        this.jockeyChance = this.cvars.l4d2_random_si_model_jockey_chance.IntValue;
        this.charger = this.cvars.l4d2_random_si_model_charger.IntValue;
        this.chargerChance = this.cvars.l4d2_random_si_model_charger_chance.IntValue;
        this.witch = this.cvars.l4d2_random_si_model_witch.IntValue;
        this.witchChance = this.cvars.l4d2_random_si_model_witch_chance.IntValue;
        this.tank = this.cvars.l4d2_random_si_model_tank.IntValue;
        this.tankChance = this.cvars.l4d2_random_si_model_tank_chance.IntValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d2_random_si_model", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void BuildArrayLists()
    {
        this.smokerVariants.Clear();
        if (plugin.smoker & TYPE_SMOKER_L4D2)
            this.smokerVariants.Push(TYPE_SMOKER_L4D2);
        if (plugin.smoker & TYPE_SMOKER_L4D1)
            this.smokerVariants.Push(TYPE_SMOKER_L4D1);

        this.boomerVariants.Clear();
        if (plugin.boomer & TYPE_BOOMER_L4D2)
            this.boomerVariants.Push(TYPE_BOOMER_L4D2);
        if (plugin.boomer & TYPE_BOOMETTE)
            this.boomerVariants.Push(TYPE_BOOMETTE);
        if (plugin.boomer & TYPE_BOOMER_L4D1)
            this.boomerVariants.Push(TYPE_BOOMER_L4D1);

        this.hunterVariants.Clear();
        if (plugin.hunter & TYPE_HUNTER_L4D2)
            this.hunterVariants.Push(TYPE_HUNTER_L4D2);
        if (plugin.hunter & TYPE_HUNTER_L4D1)
            this.hunterVariants.Push(TYPE_HUNTER_L4D1);

        this.spitterVariants.Clear();
        this.spitterVariants.Push(TYPE_SPITTER_L4D2);

        this.jockeyVariants.Clear();
        this.jockeyVariants.Push(TYPE_JOCKEY_L4D2);

        this.chargerVariants.Clear();
        this.chargerVariants.Push(TYPE_CHARGER_L4D2);

        this.witchVariants.Clear();
        if (plugin.witch & TYPE_WITCH)
            this.witchVariants.Push(TYPE_WITCH);
        if (plugin.witch & TYPE_WITCH_BRIDE)
            this.witchVariants.Push(TYPE_WITCH_BRIDE);

        this.tankVariants.Clear();
        if (plugin.tank & TYPE_TANK_L4D2)
            this.tankVariants.Push(TYPE_TANK_L4D2);
        if (plugin.tank & TYPE_TANK_DLC)
            this.tankVariants.Push(TYPE_TANK_DLC);
        if (plugin.tank & TYPE_TANK_L4D1)
            this.tankVariants.Push(TYPE_TANK_L4D1);
    }

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
                case L4D2_ZOMBIECLASS_SMOKER: this.SetSpecialInfectedModel(client, zombieclass);
                case L4D2_ZOMBIECLASS_BOOMER: this.SetSpecialInfectedModel(client, zombieclass);
                case L4D2_ZOMBIECLASS_HUNTER: this.SetSpecialInfectedModel(client, zombieclass);
                case L4D2_ZOMBIECLASS_SPITTER: this.SetSpecialInfectedModel(client, zombieclass);
                case L4D2_ZOMBIECLASS_JOCKEY: this.SetSpecialInfectedModel(client, zombieclass);
                case L4D2_ZOMBIECLASS_CHARGER: this.SetSpecialInfectedModel(client, zombieclass);
                case L4D2_ZOMBIECLASS_TANK: this.SetSpecialInfectedModel(client, zombieclass);
            }
        }

        int witch = INVALID_ENT_REFERENCE;
        while ((witch = FindEntityByClassname(witch, "witch")) != INVALID_ENT_REFERENCE)
        {
           this.SetSpecialInfectedModel(witch, L4D2_ZOMBIECLASS_WITCH);
        }
    }

    void HookEvents()
    {
        if (this.enable && !this.eventsHooked)
        {
            this.eventsHooked = true;

            HookEvent("player_spawn", Event_PlayerSpawn);
            HookEvent("witch_spawn", Event_WitchSpawn);

            return;
        }

        if (!this.enable && this.eventsHooked)
        {
            this.eventsHooked = false;

            UnhookEvent("player_spawn", Event_PlayerSpawn);
            UnhookEvent("witch_spawn", Event_WitchSpawn);

            return;
        }
    }

    void SetSpecialInfectedModel(int entity, int zombieclass)
    {
        bool customModel = (this.modelIndexes.FindValue(GetEntProp(entity, Prop_Send, "m_nModelIndex")) == -1);
        if (customModel)
        {
            if (this.customChance < GetRandomInt(1, 100))
                return;
        }

        switch (zombieclass)
        {
            case L4D2_ZOMBIECLASS_SMOKER:
            {
                if (this.smokerChance < GetRandomInt(1, 100))
                    return;

                if (this.smokerVariants.Length == 0)
                    return;

                switch (this.smokerVariants.Get(GetRandomInt(0, this.smokerVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_SMOKER_L4D2);
                    case 2: SetEntityModel(entity, MODEL_SMOKER_L4D1);
                }
            }
            case L4D2_ZOMBIECLASS_BOOMER:
            {
                if (this.boomerChance < GetRandomInt(1, 100))
                    return;

                if (this.boomerVariants.Length == 0)
                    return;

                switch (this.boomerVariants.Get(GetRandomInt(0, this.boomerVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_BOOMER_L4D2);
                    case 2: SetEntityModel(entity, MODEL_BOOMETTE);
                    case 4: SetEntityModel(entity, MODEL_BOOMER_L4D1);
                }
            }
            case L4D2_ZOMBIECLASS_HUNTER:
            {
                if (this.hunterChance < GetRandomInt(1, 100))
                    return;

                if (this.hunterVariants.Length == 0)
                    return;

                switch (this.hunterVariants.Get(GetRandomInt(0, this.hunterVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_HUNTER_L4D2);
                    case 2: SetEntityModel(entity, MODEL_HUNTER_L4D1);
                }
            }
            case L4D2_ZOMBIECLASS_SPITTER:
            {
                if (this.spitterChance < GetRandomInt(1, 100))
                    return;

                if (this.spitterVariants.Length == 0)
                    return;

                switch (this.spitterVariants.Get(GetRandomInt(0, this.spitterVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_SPITTER_L4D2);
                }
            }
            case L4D2_ZOMBIECLASS_JOCKEY:
            {
                if (this.jockeyChance < GetRandomInt(1, 100))
                    return;

                if (this.jockeyVariants.Length == 0)
                    return;

                switch (this.jockeyVariants.Get(GetRandomInt(0, this.jockeyVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_JOCKEY_L4D2);
                }
            }
            case L4D2_ZOMBIECLASS_CHARGER:
            {
                if (this.chargerChance < GetRandomInt(1, 100))
                    return;

                if (this.chargerVariants.Length == 0)
                    return;

                switch (this.chargerVariants.Get(GetRandomInt(0, this.chargerVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_CHARGER_L4D2);
                }
            }
            case L4D2_ZOMBIECLASS_WITCH:
            {
                if (this.witchChance < GetRandomInt(1, 100))
                    return;

                if (this.witchVariants.Length == 0)
                    return;

                switch (this.witchVariants.Get(GetRandomInt(0, this.witchVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_WITCH);
                    case 2: SetEntityModel(entity, MODEL_WITCH_BRIDE);
                }
            }
            case L4D2_ZOMBIECLASS_TANK:
            {
                if (this.isMap_l4d2_stadium5_stadium) // Suicide Blitz 2 finale is hardcoded in vscript based on Tank model
                    return;

                if (this.tankChance < GetRandomInt(1, 100))
                    return;

                if (this.tankVariants.Length == 0)
                    return;

                switch (this.tankVariants.Get(GetRandomInt(0, this.tankVariants.Length-1)))
                {
                    case 1: SetEntityModel(entity, MODEL_TANK_L4D2);
                    case 2: SetEntityModel(entity, MODEL_TANK_DLC);
                    case 4: SetEntityModel(entity, MODEL_TANK_L4D1);
                }
            }
        }
    }
}

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
    plugin.Init();
}

/****************************************************************************************************/

public void OnMapStart()
{
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    plugin.isMap_l4d2_stadium5_stadium = (StrEqual(mapName, "l4d2_stadium5_stadium", false));

    plugin.modelIndexSmoker_L4D2 = PrecacheModel(MODEL_SMOKER_L4D2, true);
    plugin.modelIndexSmoker_L4D1 = PrecacheModel(MODEL_SMOKER_L4D1, true);
    plugin.modelIndexBoomer_L4D2 = PrecacheModel(MODEL_BOOMER_L4D2, true);
    PrecacheModel(MODEL_EXPLODED_BOOMETTE, true); // Prevents server crash when Boomette dies.
    plugin.modelIndexBoomette = PrecacheModel(MODEL_BOOMETTE, true);
    plugin.modelIndexBoomer_L4D1 = PrecacheModel(MODEL_BOOMER_L4D1, true);
    plugin.modelIndexHunter_L4D2 = PrecacheModel(MODEL_HUNTER_L4D2, true);
    plugin.modelIndexHunter_L4D1 = PrecacheModel(MODEL_HUNTER_L4D1, true);
    plugin.modelIndexSpitter_L4D2 = PrecacheModel(MODEL_SPITTER_L4D2, true);
    plugin.modelIndexJockey_L4D2 = PrecacheModel(MODEL_JOCKEY_L4D2, true);
    plugin.modelIndexCharger_L4D2 = PrecacheModel(MODEL_CHARGER_L4D2, true);
    plugin.modelIndexWitch = PrecacheModel(MODEL_WITCH, true);
    plugin.modelIndexWitch_Bride = PrecacheModel(MODEL_WITCH_BRIDE, true);
    plugin.modelIndexTank_L4D2 = PrecacheModel(MODEL_TANK_L4D2, true);
    plugin.modelIndexTank_DLC = PrecacheModel(MODEL_TANK_DLC, true);
    plugin.modelIndexTank_L4D1 = PrecacheModel(MODEL_TANK_L4D1, true);

    plugin.modelIndexes.Clear();
    plugin.modelIndexes.Push(plugin.modelIndexSmoker_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexSmoker_L4D1);
    plugin.modelIndexes.Push(plugin.modelIndexBoomer_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexBoomette);
    plugin.modelIndexes.Push(plugin.modelIndexBoomer_L4D1);
    plugin.modelIndexes.Push(plugin.modelIndexHunter_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexHunter_L4D1);
    plugin.modelIndexes.Push(plugin.modelIndexSpitter_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexJockey_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexCharger_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexWitch);
    plugin.modelIndexes.Push(plugin.modelIndexWitch_Bride);
    plugin.modelIndexes.Push(plugin.modelIndexTank_L4D2);
    plugin.modelIndexes.Push(plugin.modelIndexTank_DLC);
    plugin.modelIndexes.Push(plugin.modelIndexTank_L4D1);
}

/****************************************************************************************************/

public void OnMapEnd()
{
    plugin.isMap_l4d2_stadium5_stadium = false;
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
    plugin.BuildArrayLists();
    plugin.LateLoad();
    plugin.HookEvents();
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
        if (!plugin.clientBot)
            return;
    }
    else
    {
        if (!plugin.clientHuman)
            return;
    }

    int zombieclass = GetZombieClass(client);
    switch (zombieclass)
    {
        case L4D2_ZOMBIECLASS_SMOKER: plugin.SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_BOOMER: plugin.SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_HUNTER: plugin.SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_SPITTER: plugin.SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_JOCKEY: plugin.SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_CHARGER: plugin.SetSpecialInfectedModel(client, zombieclass);
        case L4D2_ZOMBIECLASS_TANK: plugin.SetSpecialInfectedModel(client, zombieclass);
    }
}

/****************************************************************************************************/

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");
    plugin.SetSpecialInfectedModel(witch, L4D2_ZOMBIECLASS_WITCH);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_random_si_model) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_random_si_model_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_random_si_model_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_client_type : %i (HUMAN = %s | BOT = %s)", plugin.clientType, plugin.clientType & CLIENT_HUMAN ? "true" : "false", plugin.clientType & CLIENT_BOT ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_custom_chance : %i%%", plugin.customChance);
    PrintToConsole(client, "l4d2_random_si_model_smoker : %i (SMOKER_L4D2 = %s | SMOKER_L4D1 = %s)", plugin.smoker, plugin.smoker & TYPE_SMOKER_L4D2 ? "true" : "false", plugin.smoker & TYPE_SMOKER_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_smoker_chance : %i%%", plugin.smokerChance);
    PrintToConsole(client, "l4d2_random_si_model_boomer : %i (BOOMER_L4D2 = %s | BOOMETTE = %s | BOOMER_L4D1 = %s)", plugin.boomer, plugin.boomer & TYPE_BOOMER_L4D2 ? "true" : "false", plugin.boomer & TYPE_BOOMETTE ? "true" : "false", plugin.boomer & TYPE_BOOMER_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_boomer_chance : %i%%", plugin.boomerChance);
    PrintToConsole(client, "l4d2_random_si_model_hunter : %i (HUNTER_L4D2 = %s | HUNTER_L4D1 = %s)", plugin.hunter, plugin.hunter & TYPE_HUNTER_L4D2 ? "true" : "false", plugin.hunter & TYPE_HUNTER_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_hunter_chance : %i%%", plugin.hunterChance);
    PrintToConsole(client, "l4d2_random_si_model_spitter : %i (SPITTER_L4D2 = %s)", plugin.spitter, plugin.spitter & TYPE_SPITTER_L4D2 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_spitter_chance : %i%%", plugin.spitterChance);
    PrintToConsole(client, "l4d2_random_si_model_jockey : %i (JOCKEY_L4D2 = %s)", plugin.jockey, plugin.jockey & TYPE_JOCKEY_L4D2 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_jockey_chance : %i%%", plugin.jockeyChance);
    PrintToConsole(client, "l4d2_random_si_model_charger : %i (CHARGER_L4D2 = %s)", plugin.charger, plugin.charger & TYPE_CHARGER_L4D2 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_charger_chance : %i%%", plugin.chargerChance);
    PrintToConsole(client, "l4d2_random_si_model_witch : %i (WITCH = %s | WITCH_BRIDE = %s)", plugin.witch, plugin.witch & TYPE_WITCH ? "true" : "false", plugin.witch & TYPE_WITCH_BRIDE ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_witch_chance : %i%%", plugin.witchChance);
    PrintToConsole(client, "l4d2_random_si_model_tank : %i (TANK_L4D2 = %s | TANK_DLC = %s | TANK_L4D1 = %s)", plugin.tank, plugin.tank & TYPE_TANK_L4D2 ? "true" : "false", plugin.tank & TYPE_TANK_DLC ? "true" : "false", plugin.tank & TYPE_TANK_L4D1 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_si_model_tank_chance : %i%%", plugin.tankChance);
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