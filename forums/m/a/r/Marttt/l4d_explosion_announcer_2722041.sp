/**
// ====================================================================================================
Change Log:

1.0.8 (09-February-2025)
    - Added support for gas tank. (custom model - can be found on Glubtastic 5 custom map)

1.0.7 (04-March-2022)
    - Fixed compability with other plugins. (thanks "ddd123" for reporting)

1.0.6 (26-February-2021)
    - Added support for explosive oil drum. (custom model - can be found on GoldenEye 4 Dead custom map)

1.0.5 (04-January-2021)
    - Added support for gas pump. (found on No Mercy, 3rd map)

1.0.4 (29-November-2020)
    - Added support to physics_prop, prop_physics_override and prop_physics_multiplayer.

1.0.3 (28-November-2020)
    - Changed the detection method of explosion, from OnEntityDestroyed to break_prop/OnKilled.
    - Fixed message being sent when pick up a breakable prop item while on ignition.
    - Fixed message being sent from fuel barrel parts explosion.
    - Added Hungarian (hu) translations. (thanks to "KasperH")

1.0.2 (21-October-2020)
    - Fixed a bug while printing to chat for multiple clients. (thanks to "KRUTIK" for reporting)
    - Added Russian (ru) translations. (thanks to "KRUTIK")
    - Fixed some Russian (ru) lines. (thanks to " Angerfist2188")

1.0.1 (20-October-2020)
    - Added Simplified Chinese (chi) and Traditional Chinese (zho) translations. (thanks to "HarryPotter")
    - Fixed some Simplified Chinese (chi) lines. (thanks to "viaxiamu")

1.0.0 (20-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Explosion Announcer"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Outputs to the chat who exploded some props"
#define PLUGIN_VERSION                "1.0.8"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328006"

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
#define CONFIG_FILENAME               "l4d_explosion_announcer"
#define TRANSLATION_FILENAME          "l4d_explosion_announcer.phrases"

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
#define MODEL_GAS_TANK                "models/props_glub_re5/gastank01.mdl" // Custom Model - can be found on Glubtastic 5 custom map

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define TYPE_NONE                     0
#define TYPE_GASCAN                   1
#define TYPE_FUEL_BARREL              2
#define TYPE_PROPANECANISTER          3
#define TYPE_OXYGENTANK               4
#define TYPE_BARRICADE_GASCAN         5
#define TYPE_GAS_PUMP                 6
#define TYPE_FIREWORKS_CRATE          7
#define TYPE_OIL_DRUM_EXPLOSIVE       8
#define TYPE_GAS_TANK                 9

#define MAX_TYPES                     9

#define MAXENTITIES                   2048

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
float lastChatOccurrence[MAXPLAYERS+1][MAX_TYPES+1];

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_explosion_announcer_version;
    ConVar l4d_explosion_announcer_enable;
    ConVar l4d_explosion_announcer_spam_protection;
    ConVar l4d_explosion_announcer_spam_type_check;
    ConVar l4d_explosion_announcer_team;
    ConVar l4d_explosion_announcer_self;
    ConVar l4d_explosion_announcer_gascan;
    ConVar l4d_explosion_announcer_fuelbarrel;
    ConVar l4d_explosion_announcer_propanecanister;
    ConVar l4d_explosion_announcer_oxygentank;
    ConVar l4d_explosion_announcer_barricadegascan;
    ConVar l4d_explosion_announcer_gaspump;
    ConVar l4d_explosion_announcer_oildrumexplosive;
    ConVar l4d_explosion_announcer_gastank;
    ConVar l4d_explosion_announcer_fireworkscrate;

    void Init()
    {
        this.l4d_explosion_announcer_version            = CreateConVar("l4d_explosion_announcer_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_explosion_announcer_enable             = CreateConVar("l4d_explosion_announcer_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_spam_protection    = CreateConVar("l4d_explosion_announcer_spam_protection", "3.0", "Delay in seconds to output to the chat the message from the same client again.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
        this.l4d_explosion_announcer_spam_type_check    = CreateConVar("l4d_explosion_announcer_spam_type_check", "1", "Whether the plugin should apply chat spam protection by entity type.\nExample: \"gascans\" and \"propane canisters\" are of different types.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_team               = CreateConVar("l4d_explosion_announcer_team", "1", "Which teams should the message be transmitted to.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
        this.l4d_explosion_announcer_self               = CreateConVar("l4d_explosion_announcer_self", "1", "Should the message be transmitted to those who exploded it.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_gascan             = CreateConVar("l4d_explosion_announcer_gascan", "1", "Output to the chat every time someone explodes (last hit) a gascan.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_fuelbarrel         = CreateConVar("l4d_explosion_announcer_fuelbarrel", "1", "Output to the chat every time someone explodes (last hit) a fuel barrel.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_propanecanister    = CreateConVar("l4d_explosion_announcer_propanecanister", "1", "Output to the chat every time someone explodes (last hit) a propane canister.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_oxygentank         = CreateConVar("l4d_explosion_announcer_oxygentank", "1", "Output to the chat every time someone explodes (last hit) a oxygen tank.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_barricadegascan    = CreateConVar("l4d_explosion_announcer_barricadegascan", "1", "Output to the chat every time someone explodes (last hit) a barricade with gascans.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_gaspump            = CreateConVar("l4d_explosion_announcer_gaspump", "1", "Output to the chat every time someone explodes (last hit) a gas pump.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_oildrumexplosive   = CreateConVar("l4d_explosion_announcer_oildrumexplosive", "1", "Output to the chat every time someone explodes (last hit) an oil drum explosive (GoldenEye 4 Dead custom map).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_explosion_announcer_gastank            = CreateConVar("l4d_explosion_announcer_gastank", "1", "Output to the chat every time someone explodes (last hit) a gas tank (Glubtastic 5 custom map).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        if (plugin.isLeft4Dead2)
            this.l4d_explosion_announcer_fireworkscrate = CreateConVar("l4d_explosion_announcer_fireworkscrate", "1", "Output to the chat every time someone explodes (last hit) a fireworks crate.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.l4d_explosion_announcer_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_spam_protection.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_spam_type_check.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_team.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_self.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_gascan.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_fuelbarrel.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_propanecanister.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_oxygentank.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_barricadegascan.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_gaspump.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_oildrumexplosive.AddChangeHook(Event_ConVarChanged);
        this.l4d_explosion_announcer_gastank.AddChangeHook(Event_ConVarChanged);
        if (plugin.isLeft4Dead2)
            this.l4d_explosion_announcer_fireworkscrate.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

// ====================================================================================================
// enum structs
// ====================================================================================================
enum struct PluginData
{
    PluginCvars cvars;

    int type[MAXENTITIES+1];
    int lastAttacker[MAXENTITIES+1];

    bool isLeft4Dead2;
    bool left4dhooks;
    bool eventsHooked;
    int modelGascan;
    int modelFuelBarrel;
    int modelPropaneCanister;
    int modelOxygenTank;
    int modelBarricadeGascan;
    int modelGasPump;
    int modelFireworksCrate;
    int modelOilDrumExplosive;
    int modelGasTank;
    bool enable;
    float spamProtection;
    bool spamTypeCheck;
    int team;
    bool self;
    bool gascan;
    bool fuelBarrel;
    bool propaneCanister;
    bool oxygenTank;
    bool barricadeGascan;
    bool gasPump;
    bool oilDrumExplosive;
    bool gasTank;
    bool fireworksCrate;

    void Init()
    {
        this.LoadPluginTranslations();
        this.modelGascan = -1;
        this.modelFuelBarrel = -1;
        this.modelPropaneCanister = -1;
        this.modelOxygenTank = -1;
        this.modelBarricadeGascan = -1;
        this.modelGasPump = -1;
        this.modelFireworksCrate = -1;
        this.modelOilDrumExplosive = -1;
        this.modelGasTank = -1;
        this.cvars.Init();
        this.RegisterCmds();
    }

    void LoadPluginTranslations()
    {
        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
        if (FileExists(path))
            LoadTranslations(TRANSLATION_FILENAME);
        else
            SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d_explosion_announcer_enable.BoolValue;
        this.spamProtection = this.cvars.l4d_explosion_announcer_spam_protection.FloatValue;
        this.spamTypeCheck = this.cvars.l4d_explosion_announcer_spam_type_check.BoolValue;
        this.team = this.cvars.l4d_explosion_announcer_team.IntValue;
        this.self = this.cvars.l4d_explosion_announcer_self.BoolValue;
        this.gascan = this.cvars.l4d_explosion_announcer_gascan.BoolValue;
        this.fuelBarrel = this.cvars.l4d_explosion_announcer_fuelbarrel.BoolValue;
        this.propaneCanister = this.cvars.l4d_explosion_announcer_propanecanister.BoolValue;
        this.oxygenTank = this.cvars.l4d_explosion_announcer_oxygentank.BoolValue;
        this.barricadeGascan = this.cvars.l4d_explosion_announcer_barricadegascan.BoolValue;
        this.gasPump = this.cvars.l4d_explosion_announcer_gaspump.BoolValue;
        this.oilDrumExplosive = this.cvars.l4d_explosion_announcer_oildrumexplosive.BoolValue;
        this.gasTank = this.cvars.l4d_explosion_announcer_gastank.BoolValue;
        if (plugin.isLeft4Dead2)
            this.fireworksCrate = this.cvars.l4d_explosion_announcer_fireworkscrate.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d_explosion_announcer", Cmd_PrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
    }

    void HookEvents()
    {
        if (this.enable && !this.eventsHooked)
        {
            this.eventsHooked = true;

            HookEvent("break_prop", Event_BreakProp);

            return;
        }

        if (!this.enable && this.eventsHooked)
        {
            this.eventsHooked = false;

            UnhookEvent("break_prop", Event_BreakProp);

            return;
        }
    }

    void LateLoad()
    {
        int entity;

        if (plugin.isLeft4Dead2)
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
}

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

    plugin.isLeft4Dead2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnLibraryAdded(const char[] name)
{
    if (!plugin.left4dhooks && StrEqual(name, "left4dhooks"))
        plugin.left4dhooks = true;
}

/****************************************************************************************************/

public void OnLibraryRemoved(const char[] name)
{
    if (plugin.left4dhooks && StrEqual(name, "left4dhooks"))
        plugin.left4dhooks = false;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
}

/****************************************************************************************************/

public void OnMapStart()
{
    plugin.modelGascan = PrecacheModel(MODEL_GASCAN, true);
    plugin.modelFuelBarrel = PrecacheModel(MODEL_FUEL_BARREL, true);
    plugin.modelPropaneCanister = PrecacheModel(MODEL_PROPANECANISTER, true);
    plugin.modelOxygenTank = PrecacheModel(MODEL_OXYGENTANK, true);
    plugin.modelBarricadeGascan = PrecacheModel(MODEL_BARRICADE_GASCAN, true);
    plugin.modelGasPump = PrecacheModel(MODEL_GAS_PUMP, true);
    if (plugin.isLeft4Dead2)
        plugin.modelFireworksCrate = PrecacheModel(MODEL_FIREWORKS_CRATE, true);

    if (IsModelPrecached(MODEL_OILDRUM_EXPLOSIVE))
        plugin.modelOilDrumExplosive = PrecacheModel(MODEL_OILDRUM_EXPLOSIVE, true);
    else
        plugin.modelOilDrumExplosive = -1;

    if (IsModelPrecached(MODEL_GAS_TANK))
        plugin.modelGasTank = PrecacheModel(MODEL_GAS_TANK, true);
    else
        plugin.modelGasTank = -1;
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
    plugin.LateLoad();
    plugin.HookEvents();
}

/****************************************************************************************************/

void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");
    int client = GetClientOfUserId(event.GetInt("userid"));

    int type = plugin.type[entity];

    if (type == TYPE_NONE)
        return;

    if (client == 0)
        client = GetClientOfUserId(plugin.lastAttacker[entity]);

    if (client == 0)
        return;

    OutputMessage(client, type);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    for (int type = TYPE_NONE; type <= MAX_TYPES; type++)
    {
        lastChatOccurrence[client][type] = 0.0;
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    switch (classname[0])
    {
        case 'w':
        {
            if (!plugin.isLeft4Dead2)
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

    plugin.type[entity] = TYPE_NONE;
    plugin.lastAttacker[entity] = 0;
}

/****************************************************************************************************/

// Extra frame to get netprops updated
void OnNextFrameWeaponGascan(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (plugin.type[entity] != TYPE_NONE)
        return;

    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    RenderMode rendermode = GetEntityRenderMode(entity);
    int rgba[4];
    GetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);

    if (rendermode == RENDER_NONE || (rendermode == RENDER_TRANSCOLOR && rgba[3] == 0)) // Other plugins support, ignore invisible entities
        return;

    plugin.type[entity] = TYPE_GASCAN;
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

    if (plugin.type[entity] != TYPE_NONE)
        return;

    if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1) // Ignore entities with hammerid -1
        return;

    RenderMode rendermode = GetEntityRenderMode(entity);
    int rgba[4];
    GetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);

    if (rendermode == RENDER_NONE || (rendermode == RENDER_TRANSCOLOR && rgba[3] == 0)) // Other plugins support, ignore invisible entities
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex == plugin.modelGascan)
    {
        plugin.type[entity] = TYPE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelFuelBarrel)
    {
        plugin.type[entity] = TYPE_FUEL_BARREL;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelPropaneCanister)
    {
        plugin.type[entity] = TYPE_PROPANECANISTER;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelOxygenTank)
    {
        plugin.type[entity] = TYPE_OXYGENTANK;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelBarricadeGascan)
    {
        plugin.type[entity] = TYPE_BARRICADE_GASCAN;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelGasPump)
    {
        plugin.type[entity] = TYPE_GAS_PUMP;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelOilDrumExplosive && plugin.modelOilDrumExplosive != -1)
    {
        plugin.type[entity] = TYPE_OIL_DRUM_EXPLOSIVE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (modelIndex == plugin.modelGasTank && plugin.modelGasTank != -1)
    {
        plugin.type[entity] = TYPE_GAS_TANK;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (!plugin.isLeft4Dead2)
        return;

    if (modelIndex == plugin.modelFireworksCrate)
    {
        plugin.type[entity] = TYPE_FIREWORKS_CRATE;
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }
}

/****************************************************************************************************/

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!plugin.enable)
        return Plugin_Continue;

    if (IsValidClient(attacker))
        plugin.lastAttacker[victim] = GetClientUserId(attacker);

    return Plugin_Continue;
}

/****************************************************************************************************/

void OnKilled(const char[] output, int caller, int activator, float delay)
{
    if (!plugin.enable)
        return;

    int type = plugin.type[caller];

    if (type == TYPE_NONE)
        return;

    if (IsValidClient(activator))
        plugin.lastAttacker[caller] = GetClientUserId(activator);

    if (plugin.lastAttacker[caller] == 0)
        return;

    int client = GetClientOfUserId(plugin.lastAttacker[caller]);

    if (client == 0)
        return;

    OutputMessage(client, type);
}

/****************************************************************************************************/

void OutputMessage(int client, int type)
{
    if (plugin.team == FLAG_TEAM_NONE)
        return;

    if (plugin.spamProtection > 0.0)
    {
        if (plugin.spamTypeCheck)
        {
            if (lastChatOccurrence[client][type] != 0.0 && GetGameTime() - lastChatOccurrence[client][type] < plugin.spamProtection)
                return;

            lastChatOccurrence[client][type] = GetGameTime();
        }
        else
        {
            if (lastChatOccurrence[client][TYPE_NONE] != 0.0 && GetGameTime() - lastChatOccurrence[client][TYPE_NONE] < plugin.spamProtection)
                return;

            lastChatOccurrence[client][TYPE_NONE] = GetGameTime();
        }
    }

    switch (type)
    {
        case TYPE_GASCAN:
        {
            if (!plugin.gascan)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a gascan", client);
            }
        }

        case TYPE_FUEL_BARREL:
        {
            if (!plugin.fuelBarrel)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a fuel barrel", client);
            }
        }

        case TYPE_PROPANECANISTER:
        {
            if (!plugin.propaneCanister)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a propane canister", client);
            }
        }

        case TYPE_OXYGENTANK:
        {
            if (!plugin.oxygenTank)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded an oxygen tank", client);
            }
        }

        case TYPE_BARRICADE_GASCAN:
        {
            if (!plugin.barricadeGascan)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a barricade with gascans", client);
            }
        }

        case TYPE_GAS_PUMP:
        {
            if (!plugin.gasPump)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a gas pump", client);
            }
        }

        case TYPE_FIREWORKS_CRATE:
        {
            if (!plugin.fireworksCrate)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a fireworks crate", client);
            }
        }

        case TYPE_OIL_DRUM_EXPLOSIVE:
        {
            if (!plugin.oilDrumExplosive)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded an oil drum", client);
            }
        }

        case TYPE_GAS_TANK:
        {
            if (!plugin.gasTank)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Exploded a gas tank", client);
            }
        }
    }
}

/****************************************************************************************************/

bool IsValidPrintTarget(int target, int client)
{
    if (!IsClientInGame(target))
        return false;

    if (IsFakeClient(target))
        return false;

    if (target == client && !plugin.self)
       return false;

    if (!(GetTeamFlag(GetClientTeam(target)) & plugin.team))
        return false;

    return true;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_explosion_announcer) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_explosion_announcer_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_explosion_announcer_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_spam_protection : %.1f", plugin.spamProtection);
    PrintToConsole(client, "l4d_explosion_announcer_spam_type_check : %b (%s)", plugin.spamTypeCheck, plugin.spamTypeCheck ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", plugin.team,
    plugin.team & FLAG_TEAM_SPECTATOR ? "true" : "false", plugin.team & FLAG_TEAM_SURVIVOR ? "true" : "false", plugin.team & FLAG_TEAM_INFECTED ? "true" : "false", plugin.team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_self : %b (%s)", plugin.self, plugin.self ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gascan : %b (%s)", plugin.gascan, plugin.gascan ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_fuelbarrel : %b (%s)", plugin.fuelBarrel, plugin.fuelBarrel ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_propanecanister : %b (%s)", plugin.propaneCanister, plugin.propaneCanister ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_oxygentank : %b (%s)", plugin.oxygenTank, plugin.oxygenTank ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_barricadegascan : %b (%s)", plugin.barricadeGascan, plugin.barricadeGascan ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gaspump : %b (%s)", plugin.gasPump, plugin.gasPump ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_oildrumexplosive : %b (%s)", plugin.oilDrumExplosive, plugin.oilDrumExplosive ? "true" : "false");
    PrintToConsole(client, "l4d_explosion_announcer_gastank : %b (%s)", plugin.gasTank, plugin.gasTank ? "true" : "false");
    if (plugin.isLeft4Dead2) {
        PrintToConsole(client, "l4d_explosion_announcer_fireworkscrate : %b (%s)", plugin.fireworksCrate, plugin.fireworksCrate ? "true" : "false");
    }
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
 * Returns the team flag from a team.
 *
 * @param team          Team index.
 * @return              Team flag.
 */
int GetTeamFlag(int team)
{
    switch (team)
    {
        case TEAM_SURVIVOR:
            return FLAG_TEAM_SURVIVOR;
        case TEAM_INFECTED:
            return FLAG_TEAM_INFECTED;
        case TEAM_SPECTATOR:
            return FLAG_TEAM_SPECTATOR;
        case TEAM_HOLDOUT:
            return FLAG_TEAM_HOLDOUT;
        default:
            return FLAG_TEAM_NONE;
    }
}

// ====================================================================================================
// colors.inc replacement (Thanks to Silvers)
// ====================================================================================================
/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
void CPrintToChat(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{green}", "\x04"); // Actually orange in L4D1/L4D2, but replicating colors.inc behaviour
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}