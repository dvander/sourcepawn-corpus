/**
// ====================================================================================================
Change Log:

1.0.1 (25-November-2021)
    - Added cvar to enable/disable on humans/bots (thanks "azureblue" for requesting).

1.0.0 (16-November-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Voice Pitch"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Changes the characters voice pitch"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=335228"

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
#include <clientprefs>

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
#define CONFIG_FILENAME               "l4d_voice_pitch"
#define TRANSLATION_FILENAME          "l4d_voice_pitch.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLIENT_HUMAN                  1
#define CLIENT_BOT                    2

#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Cookies;
ConVar g_hCvar_CommandMin;
ConVar g_hCvar_CommandMax;
ConVar g_hCvar_SurvivorMin;
ConVar g_hCvar_SurvivorMax;
ConVar g_hCvar_SurvivorClient;
ConVar g_hCvar_InfectedClient;
ConVar g_hCvar_SmokerMin;
ConVar g_hCvar_SmokerMax;
ConVar g_hCvar_BoomerMin;
ConVar g_hCvar_BoomerMax;
ConVar g_hCvar_HunterMin;
ConVar g_hCvar_HunterMax;
ConVar g_hCvar_SpitterMin;
ConVar g_hCvar_SpitterMax;
ConVar g_hCvar_JockeyMin;
ConVar g_hCvar_JockeyMax;
ConVar g_hCvar_ChargerMin;
ConVar g_hCvar_ChargerMax;
ConVar g_hCvar_TankMin;
ConVar g_hCvar_TankMax;
ConVar g_hCvar_CommonMin;
ConVar g_hCvar_CommonMax;
ConVar g_hCvar_WitchMin;
ConVar g_hCvar_WitchMax;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Cookies;
bool g_bCvar_SurvivorHuman;
bool g_bCvar_SurvivorBot;
bool g_bCvar_Survivor;
bool g_bCvar_InfectedHuman;
bool g_bCvar_InfectedBot;
bool g_bCvar_Smoker;
bool g_bCvar_Boomer;
bool g_bCvar_Hunter;
bool g_bCvar_Spitter;
bool g_bCvar_Jockey;
bool g_bCvar_Charger;
bool g_bCvar_Tank;
bool g_bCvar_Common;
bool g_bCvar_Witch;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_CommandMin;
int g_iCvar_CommandMax;
int g_iCvar_SurvivorMin;
int g_iCvar_SurvivorMax;
int g_iCvar_SurvivorClient;
int g_iCvar_InfectedClient;
int g_iCvar_SmokerMin;
int g_iCvar_SmokerMax;
int g_iCvar_BoomerMin;
int g_iCvar_BoomerMax;
int g_iCvar_HunterMin;
int g_iCvar_HunterMax;
int g_iCvar_SpitterMin;
int g_iCvar_SpitterMax;
int g_iCvar_JockeyMin;
int g_iCvar_JockeyMax;
int g_iCvar_ChargerMin;
int g_iCvar_ChargerMax;
int g_iCvar_TankMin;
int g_iCvar_TankMax;
int g_iCvar_CommonMin;
int g_iCvar_CommonMax;
int g_iCvar_WitchMin;
int g_iCvar_WitchMax;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bVoicePitchDisable[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iVoicePitchValue[MAXENTITIES+1];

// ====================================================================================================
// Cookies - Plugin Variables
// ====================================================================================================
Cookie g_cbVoicePitchDisable;
Cookie g_ciVoicePitchValue;

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
    LoadTranslations("common.phrases");
    LoadPluginTranslations();

    CreateConVar("l4d_voice_pitch_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled        = CreateConVar("l4d_voice_pitch_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Cookies        = CreateConVar("l4d_voice_pitch_cookies", "1", "Allow cookies for storing client preferences.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_CommandMin     = CreateConVar("l4d_voice_pitch_command_min", "60", "Minimum voice pitch allowed to set through command.", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_CommandMax     = CreateConVar("l4d_voice_pitch_command_max", "200", "Maximum voice pitch allowed to set through command.", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_SurvivorMin    = CreateConVar("l4d_voice_pitch_survivor_min", "60", "Survivor minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_SurvivorMax    = CreateConVar("l4d_voice_pitch_survivor_max", "200", "Survivor maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_SurvivorClient = CreateConVar("l4d_voice_pitch_survivor_client", "3", "Which type of survivor client (human/bot) should be affected by the plugin.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_InfectedClient = CreateConVar("l4d_voice_pitch_infected_client", "3", "Which type of infected client (human/bot) should be affected by the plugin.\n0 = NONE, 1 = HUMAN, 2 = BOT, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Humans and Bots.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SmokerMin      = CreateConVar("l4d_voice_pitch_smoker_min", "60", "Smoker minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_SmokerMax      = CreateConVar("l4d_voice_pitch_smoker_max", "200", "Smoker maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_BoomerMin      = CreateConVar("l4d_voice_pitch_boomer_min", "60", "Boomer minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_BoomerMax      = CreateConVar("l4d_voice_pitch_boomer_max", "200", "Boomer maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_HunterMin      = CreateConVar("l4d_voice_pitch_hunter_min", "60", "Hunter minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_HunterMax      = CreateConVar("l4d_voice_pitch_hunter_max", "200", "Hunter maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    if (g_bL4D2)
    {
        g_hCvar_SpitterMin = CreateConVar("l4d_voice_pitch_spitter_min", "60", "(L4D2 only) Spitter minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
        g_hCvar_SpitterMax = CreateConVar("l4d_voice_pitch_spitter_max", "200", "(L4D2 only) Spitter maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
        g_hCvar_JockeyMin  = CreateConVar("l4d_voice_pitch_jockey_min", "60", "(L4D2 only) Jockey minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
        g_hCvar_JockeyMax  = CreateConVar("l4d_voice_pitch_jockey_max", "200", "(L4D2 only) Jockey maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
        g_hCvar_ChargerMin = CreateConVar("l4d_voice_pitch_charger_min", "60", "(L4D2 only) Charger minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
        g_hCvar_ChargerMax = CreateConVar("l4d_voice_pitch_charger_max", "200", "(L4D2 only) Charger maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    }
    g_hCvar_TankMin        = CreateConVar("l4d_voice_pitch_tank_min", "60", "Tank minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_TankMax        = CreateConVar("l4d_voice_pitch_tank_max", "200", "Tank maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_CommonMin      = CreateConVar("l4d_voice_pitch_common_min", "60", "Common minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_CommonMax      = CreateConVar("l4d_voice_pitch_common_max", "200", "Common maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_WitchMin       = CreateConVar("l4d_voice_pitch_witch_min", "60", "Witch minimum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_WitchMax       = CreateConVar("l4d_voice_pitch_witch_max", "200", "Witch maximum voice pitch.\n0 = OFF (disables both min/max).", CVAR_FLAGS, true, 0.0, true, 255.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cookies.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommandMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommandMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SurvivorMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SurvivorMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SurvivorClient.AddChangeHook(Event_ConVarChanged);
    g_hCvar_InfectedClient.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BoomerMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BoomerMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HunterMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HunterMax.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_SpitterMin.AddChangeHook(Event_ConVarChanged);
        g_hCvar_SpitterMax.AddChangeHook(Event_ConVarChanged);
        g_hCvar_JockeyMin.AddChangeHook(Event_ConVarChanged);
        g_hCvar_JockeyMax.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ChargerMin.AddChangeHook(Event_ConVarChanged);
        g_hCvar_ChargerMax.AddChangeHook(Event_ConVarChanged);
    }
    g_hCvar_TankMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TankMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommonMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CommonMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WitchMin.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WitchMax.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Cookies
    g_cbVoicePitchDisable = new Cookie("l4d_voice_pitch_disable", "Voice Pitch - Disable", CookieAccess_Protected);
    g_ciVoicePitchValue = new Cookie("l4d_voice_pitch_value", "Voice Pitch - Value", CookieAccess_Protected);

    // Commands
    RegConsoleCmd("sm_voice", CmdVoice, "Change the client voice pitch. Usage: sm_voice <pitch>");
    RegConsoleCmd("sm_voicedisable", CmdVoiceDisable, "Disable the plugin behaviour in the client.");
    RegConsoleCmd("sm_voicereset", CmdVoiceReset, "Reset and enable the plugin behaviour in the client.");

    // Admin Commands
    RegAdminCmd("sm_voiceclient", CmdVoiceClient, ADMFLAG_ROOT, "Set the client voice pitch. Usage: sm_voiceclient <target> <pitch>");
    RegAdminCmd("sm_print_cvars_l4d_voice_pitch", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
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

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Cookies = g_hCvar_Cookies.BoolValue;
    g_iCvar_CommandMin = g_hCvar_CommandMin.IntValue;
    g_iCvar_CommandMax = g_hCvar_CommandMax.IntValue;
    g_iCvar_SurvivorMin = g_hCvar_SurvivorMin.IntValue;
    g_iCvar_SurvivorMax = g_hCvar_SurvivorMax.IntValue;
    g_bCvar_Survivor = (g_iCvar_SurvivorMin != 0 && g_iCvar_SurvivorMax != 0);
    g_iCvar_SurvivorClient = g_hCvar_SurvivorClient.IntValue;
    g_bCvar_SurvivorHuman = (g_iCvar_SurvivorClient & CLIENT_HUMAN ? true : false);
    g_bCvar_SurvivorBot = (g_iCvar_SurvivorClient & CLIENT_BOT ? true : false);
    g_iCvar_InfectedClient = g_hCvar_InfectedClient.IntValue;
    g_bCvar_InfectedHuman = (g_iCvar_InfectedClient & CLIENT_HUMAN ? true : false);
    g_bCvar_InfectedBot = (g_iCvar_InfectedClient & CLIENT_BOT ? true : false);
    g_iCvar_SmokerMin = g_hCvar_SmokerMin.IntValue;
    g_iCvar_SmokerMax = g_hCvar_SmokerMax.IntValue;
    g_bCvar_Smoker = (g_iCvar_SmokerMin != 0 && g_iCvar_SmokerMax != 0);
    g_iCvar_BoomerMin = g_hCvar_BoomerMin.IntValue;
    g_iCvar_BoomerMax = g_hCvar_BoomerMax.IntValue;
    g_bCvar_Boomer = (g_iCvar_BoomerMin != 0 && g_iCvar_BoomerMax != 0);
    g_iCvar_HunterMin = g_hCvar_HunterMin.IntValue;
    g_iCvar_HunterMax = g_hCvar_HunterMax.IntValue;
    g_bCvar_Hunter = (g_iCvar_HunterMin != 0 && g_iCvar_HunterMax != 0);
    if (g_bL4D2)
    {
        g_iCvar_SpitterMin = g_hCvar_SpitterMin.IntValue;
        g_iCvar_SpitterMax = g_hCvar_SpitterMax.IntValue;
        g_bCvar_Spitter = (g_iCvar_SpitterMin != 0 && g_iCvar_SpitterMax != 0);
        g_iCvar_JockeyMin = g_hCvar_JockeyMin.IntValue;
        g_iCvar_JockeyMax = g_hCvar_JockeyMax.IntValue;
        g_bCvar_Jockey = (g_iCvar_JockeyMin != 0 && g_iCvar_JockeyMax != 0);
        g_iCvar_ChargerMin = g_hCvar_ChargerMin.IntValue;
        g_iCvar_ChargerMax = g_hCvar_ChargerMax.IntValue;
        g_bCvar_Charger = (g_iCvar_ChargerMin != 0 && g_iCvar_ChargerMax != 0);
    }
    g_iCvar_TankMin = g_hCvar_TankMin.IntValue;
    g_iCvar_TankMax = g_hCvar_TankMax.IntValue;
    g_bCvar_Tank = (g_iCvar_TankMin != 0 && g_iCvar_TankMax != 0);
    g_iCvar_CommonMin = g_hCvar_CommonMin.IntValue;
    g_iCvar_CommonMax = g_hCvar_CommonMax.IntValue;
    g_bCvar_Common = (g_iCvar_CommonMin != 0 && g_iCvar_CommonMax != 0);
    g_iCvar_WitchMin = g_hCvar_WitchMin.IntValue;
    g_iCvar_WitchMax = g_hCvar_WitchMax.IntValue;
    g_bCvar_Witch = (g_iCvar_WitchMin != 0 && g_iCvar_WitchMax != 0);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (AreClientCookiesCached(client))
            OnClientCookiesCached(client);

        ge_iVoicePitchValue[client] = GetPitch(client);
    }

    int entity;

    if (g_bCvar_Common)
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
        {
            ge_iVoicePitchValue[entity] = GetRandomInt(g_iCvar_CommonMin, g_iCvar_CommonMax);
        }
    }

    if (g_bCvar_Witch)
    {
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
        {
            ge_iVoicePitchValue[entity] = GetRandomInt(g_iCvar_WitchMin, g_iCvar_WitchMax);
        }
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bVoicePitchDisable[client] = false;
    ge_iVoicePitchValue[client] = 0;
}

/****************************************************************************************************/

public void OnClientCookiesCached(int client)
{
    if (!g_bCvar_Cookies)
        return;

    if (IsFakeClient(client))
        return;

    char cookieDisable[2];
    g_cbVoicePitchDisable.Get(client, cookieDisable, sizeof(cookieDisable));

    if (cookieDisable[0] != 0)
        gc_bVoicePitchDisable[client] = StringToInt(cookieDisable) == 1 ? true : false;

    char cookieValue[4];
    g_ciVoicePitchValue.Get(client, cookieValue, sizeof(cookieValue));

    if (cookieValue[0] != 0)
        ge_iVoicePitchValue[client] = StringToInt(cookieValue);
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("player_team", Event_PlayerTeam);
        AddNormalSoundHook(SoundHook);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);
        UnhookEvent("player_death", Event_PlayerDeath);
        UnhookEvent("player_team", Event_PlayerTeam);
        RemoveNormalSoundHook(SoundHook);

        return;
    }
}

/****************************************************************************************************/

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    ge_iVoicePitchValue[client] = GetPitch(client);
}

/****************************************************************************************************/

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    ge_iVoicePitchValue[client] = 0;
}

/****************************************************************************************************/

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    ge_iVoicePitchValue[client] = 0;
}

/****************************************************************************************************/

Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if (channel != SNDCHAN_VOICE)
        return Plugin_Continue;

    if (ge_iVoicePitchValue[entity] == 0)
        return Plugin_Continue;

    if (ge_iVoicePitchValue[entity] == pitch)
        return Plugin_Continue;

    if (IsValidClientIndex(entity) && gc_bVoicePitchDisable[entity])
        return Plugin_Continue;

    pitch = ge_iVoicePitchValue[entity];
    flags |= SND_CHANGEPITCH;
    return Plugin_Changed;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    switch (classname[0])
    {
        case 'i':
        {
            if (g_bCvar_Common && StrEqual(classname, "infected"))
                ge_iVoicePitchValue[entity] = GetRandomInt(g_iCvar_CommonMin, g_iCvar_CommonMax);
        }
        case 'w':
        {
            if (classname[1] != 'i')
                return;

            if (g_bCvar_Witch && StrEqual(classname, "witch"))
                ge_iVoicePitchValue[entity] = GetRandomInt(g_iCvar_WitchMin, g_iCvar_WitchMax);
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iVoicePitchValue[entity] = 0;
}

/****************************************************************************************************/

int GetPitch(int client)
{
    bool disabled;

    int team = GetClientTeam(client);

    switch (team)
    {
        case TEAM_SURVIVOR, TEAM_HOLDOUT:
        {
            if (IsFakeClient(client))
            {
                disabled = !g_bCvar_SurvivorBot;
            }
            else
            {
                disabled = !g_bCvar_SurvivorHuman;
            }
        }
        case TEAM_INFECTED:
        {
            if (IsFakeClient(client))
            {
                disabled = !g_bCvar_InfectedBot;
            }
            else
            {
                disabled = !g_bCvar_InfectedHuman;
            }
        }
        default:
        {
            disabled = true;
        }
    }

    if (disabled)
        return 0;

    if (ge_iVoicePitchValue[client] != 0)
        return ge_iVoicePitchValue[client];

    switch (team)
    {
        case TEAM_SURVIVOR, TEAM_HOLDOUT:
        {
            if (g_bCvar_Survivor)
                return GetRandomInt(g_iCvar_SurvivorMin, g_iCvar_SurvivorMax);
        }
        case TEAM_INFECTED:
        {
            if (g_bL4D2)
            {
                switch (GetZombieClass(client))
                {
                    case L4D2_ZOMBIECLASS_SMOKER:
                    {
                        if (g_bCvar_Smoker)
                            return GetRandomInt(g_iCvar_SmokerMin, g_iCvar_SmokerMax);
                    }
                    case L4D2_ZOMBIECLASS_BOOMER:
                    {
                        return GetRandomInt(g_iCvar_BoomerMin, g_iCvar_BoomerMax);
                    }
                    case L4D2_ZOMBIECLASS_HUNTER:
                    {
                        if (g_bCvar_Hunter)
                            return GetRandomInt(g_iCvar_HunterMin, g_iCvar_HunterMax);
                    }
                    case L4D2_ZOMBIECLASS_SPITTER:
                    {
                        if (g_bCvar_Spitter)
                            return GetRandomInt(g_iCvar_SpitterMin, g_iCvar_SpitterMax);
                    }
                    case L4D2_ZOMBIECLASS_JOCKEY:
                    {
                        if (g_bCvar_Jockey)
                            return GetRandomInt(g_iCvar_JockeyMin, g_iCvar_JockeyMax);
                    }
                    case L4D2_ZOMBIECLASS_CHARGER:
                    {
                        if (g_bCvar_Charger)
                            return GetRandomInt(g_iCvar_ChargerMin, g_iCvar_ChargerMax);
                    }
                    case L4D2_ZOMBIECLASS_TANK:
                    {
                        if (g_bCvar_Tank)
                            return GetRandomInt(g_iCvar_TankMin, g_iCvar_TankMax);
                    }
                }
            }
            else
            {
                switch (GetZombieClass(client))
                {
                    case L4D1_ZOMBIECLASS_SMOKER:
                    {
                        if (g_bCvar_Smoker)
                            return GetRandomInt(g_iCvar_SmokerMin, g_iCvar_SmokerMax);
                    }
                    case L4D1_ZOMBIECLASS_BOOMER:
                    {
                        if (g_bCvar_Boomer)
                            return GetRandomInt(g_iCvar_BoomerMin, g_iCvar_BoomerMax);
                    }
                    case L4D1_ZOMBIECLASS_HUNTER:
                    {
                        if (g_bCvar_Hunter)
                            return GetRandomInt(g_iCvar_HunterMin, g_iCvar_HunterMax);
                    }
                    case L4D1_ZOMBIECLASS_TANK:
                    {
                        if (g_bCvar_Tank)
                            return GetRandomInt(g_iCvar_TankMin, g_iCvar_TankMax);
                    }
                }
            }
        }
    }

    return 0;
}

// ====================================================================================================
// Commands
// ====================================================================================================
Action CmdVoice(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args < 1)
    {
        CPrintToChat(client, "%t", "Voice Usage", g_iCvar_CommandMin, g_iCvar_CommandMax);
        return Plugin_Handled;
    }

    char arg1[4];
    GetCmdArg(1, arg1, sizeof(arg1));

    int pitch = StringToInt(arg1);

    if (pitch < g_iCvar_CommandMin)
        pitch = g_iCvar_CommandMin;

    if (pitch > g_iCvar_CommandMax)
        pitch = g_iCvar_CommandMax;

    gc_bVoicePitchDisable[client] = false;
    ge_iVoicePitchValue[client] = pitch;

    if (g_bCvar_Cookies)
    {
        g_cbVoicePitchDisable.Set(client, "0");

        char sCookie[4];
        IntToString(pitch, sCookie, sizeof(sCookie));
        g_ciVoicePitchValue.Set(client, sCookie);
    }

    CPrintToChat(client, "%t", "Voice Set", pitch, g_iCvar_CommandMin, g_iCvar_CommandMax);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdVoiceDisable(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    gc_bVoicePitchDisable[client] = true;
    ge_iVoicePitchValue[client] = 0;

    if (g_bCvar_Cookies)
    {
        g_cbVoicePitchDisable.Set(client, "1");
        g_ciVoicePitchValue.Set(client, "0");
    }

    CPrintToChat(client, "%t", "Voice Disabled");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdVoiceReset(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    gc_bVoicePitchDisable[client] = false;
    ge_iVoicePitchValue[client] = GetPitch(client);

    if (g_bCvar_Cookies)
    {
        g_cbVoicePitchDisable.Set(client, "0");
        g_ciVoicePitchValue.Set(client, "0");
    }

    CPrintToChat(client, "%t", "Voice Reset");

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdVoiceClient(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "\x04[\x01Usage: \x03!voiceclient \x05<target> <pitch>\x04]");
        return Plugin_Handled;
    }

    char arg1[MAX_TARGET_LENGTH];
    GetCmdArg(1, arg1, sizeof(arg1));

    char arg2[4];
    GetCmdArg(2, arg2, sizeof(arg2));

    int pitch = StringToInt(arg2);

    if (pitch < g_iCvar_CommandMin)
        pitch = g_iCvar_CommandMin;

    if (pitch > g_iCvar_CommandMax)
        pitch = g_iCvar_CommandMax;

    int target_count;
    int target_list[MAXPLAYERS];
    char target_name[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
        arg1,
        client,
        target_list,
        MAXPLAYERS,
        COMMAND_FILTER_ALIVE,
        target_name,
        sizeof(target_name),
        tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
    }

    int target;
    for (int i = 0; i < target_count; i++)
    {
        target = target_list[i];

        gc_bVoicePitchDisable[target] = false;
        ge_iVoicePitchValue[target] = pitch;

        ReplyToCommand(client, "\x04[\x01Voice pitch set to \x03%i \x01for \x05%N\x04]", pitch, target);
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------- Plugin Cvars (l4d_voice_pitch) -------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_voice_pitch_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_voice_pitch_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_cookies : %b (%s)", g_bCvar_Cookies, g_bCvar_Cookies ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_command_min : %i", g_iCvar_CommandMin);
    PrintToConsole(client, "l4d_voice_pitch_command_max : %i", g_iCvar_CommandMax);
    PrintToConsole(client, "l4d_voice_pitch_survivor_min : %i (%s)", g_iCvar_SurvivorMin, g_bCvar_Survivor ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_survivor_max : %i (%s)", g_iCvar_SurvivorMax, g_bCvar_Survivor ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_survivor_client : %i (HUMAN = %s | BOT = %s)", g_iCvar_SurvivorClient, g_bCvar_SurvivorHuman ? "true" : "false", g_bCvar_SurvivorBot ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_infected_client : %i (HUMAN = %s | BOT = %s)", g_iCvar_InfectedClient, g_bCvar_InfectedHuman ? "true" : "false", g_bCvar_InfectedBot ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_smoker_min : %i (%s)", g_iCvar_SmokerMin, g_bCvar_Smoker ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_smoker_max : %i (%s)", g_iCvar_SmokerMax, g_bCvar_Smoker ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_boomer_min : %i (%s)", g_iCvar_BoomerMax, g_bCvar_Boomer ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_smoker_max : %i (%s)", g_iCvar_BoomerMax, g_bCvar_Boomer ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_hunter_min : %i (%s)", g_iCvar_HunterMin, g_bCvar_Hunter ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_hunter_max : %i (%s)", g_iCvar_HunterMax, g_bCvar_Hunter ? "true" : "false");
    if (g_bL4D2)
    {
        PrintToConsole(client, "l4d_voice_pitch_spitter_min : %i (%s)", g_iCvar_SpitterMin, g_bCvar_Spitter ? "true" : "false");
        PrintToConsole(client, "l4d_voice_pitch_spitter_max : %i (%s)", g_iCvar_SpitterMax, g_bCvar_Spitter ? "true" : "false");
        PrintToConsole(client, "l4d_voice_pitch_jockey_min : %i (%s)", g_iCvar_JockeyMin, g_bCvar_Jockey ? "true" : "false");
        PrintToConsole(client, "l4d_voice_pitch_jockey_max : %i (%s)", g_iCvar_JockeyMax, g_bCvar_Jockey ? "true" : "false");
        PrintToConsole(client, "l4d_voice_pitch_charger_min : %i (%s)", g_iCvar_ChargerMin, g_bCvar_Charger ? "true" : "false");
        PrintToConsole(client, "l4d_voice_pitch_charger_max : %i (%s)", g_iCvar_ChargerMax, g_bCvar_Charger ? "true" : "false");
    }
    PrintToConsole(client, "l4d_voice_pitch_tank_min : %i (%s)", g_iCvar_TankMin, g_bCvar_Tank ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_tank_max : %i (%s)", g_iCvar_TankMax, g_bCvar_Tank ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_common_min : %i (%s)", g_iCvar_CommonMin, g_bCvar_Common ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_common_max : %i (%s)", g_iCvar_CommonMax, g_bCvar_Common ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_witch_min : %i (%s)", g_iCvar_WitchMin, g_bCvar_Witch ? "true" : "false");
    PrintToConsole(client, "l4d_voice_pitch_witch_max : %i (%s)", g_iCvar_WitchMax, g_bCvar_Witch ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------------------- Clients Pitch ---------------------------");
    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        PrintToConsole(client, "%N : %i (%s)", target, ge_iVoicePitchValue[target], gc_bVoicePitchDisable[target] ? "disabled" : "enabled");
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
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client        Client index.
 * @return L4D1         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

// ====================================================================================================
// colors.inc replacement (Thanks to Silvers)
// ====================================================================================================
/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client          Client index.
 * @param message         Message (formatting rules).
 *
 * On error/Errors:       If the client is not connected an error will be thrown.
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