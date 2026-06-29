/**
// ====================================================================================================
Change Log:

1.0.0 (09-April-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[PVK2] More Target Filters"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds more target filters ready to use"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=337226"

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
#define CONFIG_FILENAME               "pvk2_more_target_filters"

// ====================================================================================================
// Enums
// ====================================================================================================
enum ClientType
{
    ClientType_All,
    ClientType_Human,
    ClientType_Bot
}

/****************************************************************************************************/

enum ClientState
{
    ClientState_All,
    ClientState_Alive,
    ClientState_Dead
}

/****************************************************************************************************/

enum ClientTeam
{
    ClientTeam_All = -1,
    ClientTeam_Spectators = 1,
    ClientTeam_Pirates = 2,
    ClientTeam_Vikings = 3,
    ClientTeam_Knights = 4
}

/****************************************************************************************************/

enum PickRandom
{
    PickRandom_No,
    PickRandom_Yes
}

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar pvkii_more_target_filters_version;
    ConVar pvkii_more_target_filters_enable;
    ConVar pvkii_more_target_filters_debug;

    void Init()
    {
        this.pvkii_more_target_filters_version = CreateConVar("pvkii_more_target_filters_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.pvkii_more_target_filters_enable  = CreateConVar("pvkii_more_target_filters_enable", "1", "enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.pvkii_more_target_filters_debug   = CreateConVar("pvkii_more_target_filters_debug", "0", "Output to chat info about clients found by the target filter.\n0 = Debug OFF, 1 = Debug ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.pvkii_more_target_filters_enable.AddChangeHook(Event_ConVarChanged);
        this.pvkii_more_target_filters_debug.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool multiTargetFilters;
    bool enable;
    bool debug;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.pvkii_more_target_filters_enable.BoolValue;
        this.debug = this.cvars.pvkii_more_target_filters_debug.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_pvkii_more_target_filters", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void SetTargetFilters()
    {
        if (this.enable && !this.multiTargetFilters)
        {
            this.multiTargetFilters = true;

            AddMultiTargetFilters();

            return;
        }

        if (!this.enable && this.multiTargetFilters)
        {
            this.multiTargetFilters = false;

            RemoveMultiTargetFilters();

            return;
        }
    }

    void DebugArray(ArrayList clients)
    {
        PrintToChatAll("\x03[\x05clients found: \x04%i\x03]", clients.Length);
        for (int i = 0; i < clients.Length; i++)
        {
            int client = clients.Get(i);
            PrintToChatAll("\x03[\x05client: \x04%i \x03| \x05Name: \x04%N \x03| \x05State: \x04%s \x03| \x05Team: \x04%s\x03]",
            client,
            client,
            IsPlayerAlive(client) ? "Alive" : "Dead",
            GetClientTeamEnum(client) == ClientTeam_Spectators ? "Spectators" : GetClientTeamEnum(client) == ClientTeam_Pirates ? "Pirates" : GetClientTeamEnum(client) == ClientTeam_Vikings ? "Vikings" : GetClientTeamEnum(client) == ClientTeam_Knights ? "Knights" : "Unknown");
        }
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    char game[8];
    GetGameFolderName(game, sizeof(game));

    if (!StrEqual(game, "pvkii"))
    {
        strcopy(error, err_max, "This plugin only runs in \"Pirates, Vikings, and Knights II\" game");
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

public void OnPluginEnd()
{
    RemoveMultiTargetFilters();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
    plugin.SetTargetFilters();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void AddMultiTargetFilters()
{
    MultiTargetFilters(true);
}

/****************************************************************************************************/

void RemoveMultiTargetFilters()
{
    MultiTargetFilters(false);
}

/****************************************************************************************************/

void MultiTargetFilters(bool add)
{
    MultiTargetFilter(add, "@a",                FilterAll, "all players", true);
    // MultiTargetFilter(add, "@all",              FilterAll, "all players", true); // SM already has it by default

    MultiTargetFilter(add, "@h",                FilterHumans, "all humans", true);
    MultiTargetFilter(add, "@human",            FilterHumans, "all humans", true);
    // MultiTargetFilter(add, "@humans",           FilterHumans, "all humans", true); // SM already has it by default

    MultiTargetFilter(add, "@b",                FilterBots, "all bots", true);
    MultiTargetFilter(add, "@bot",              FilterBots, "all bots", true);
    // MultiTargetFilter(add, "@bots",             FilterBots, "all bots", true); // SM already has it by default

    // MultiTargetFilter(add, "@a",                FilterAlive, "all alive players", true); // Conflicts with @all
    MultiTargetFilter(add, "@aliv",             FilterAlive, "all alive players", true);
    // MultiTargetFilter(add, "@alive",            FilterAlive, "all alive players", true); // SM already has it by default

    MultiTargetFilter(add, "@d",                FilterDead, "all dead players", true);
    // MultiTargetFilter(add, "@dead",             FilterDead, "all dead players", true); // SM already has it by default

    MultiTargetFilter(add, "@s",                FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@spec",             FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@specs",            FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@spectator",        FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@spectators",       FilterSpectators, "all spectators", true);

    MultiTargetFilter(add, "@p",                FilterPirates, "Pirates", false);
    MultiTargetFilter(add, "@pirate",           FilterPirates, "Pirates", false);
    MultiTargetFilter(add, "@pirates",          FilterPirates, "Pirates", false);

    MultiTargetFilter(add, "@ph",               FilterPiratesHumans, "Pirates (humans)", false);
    MultiTargetFilter(add, "@phumans",          FilterPiratesHumans, "Pirates (humans)", false);

    MultiTargetFilter(add, "@pb",               FilterPiratesBots, "Pirates (bots)", false);
    MultiTargetFilter(add, "@pbots",            FilterPiratesBots, "Pirates (bots)", false);

    MultiTargetFilter(add, "@pa",               FilterPiratesAlive, "Pirates (alive)", false);
    MultiTargetFilter(add, "@palive",           FilterPiratesAlive, "Pirates (alive)", false);

    MultiTargetFilter(add, "@pd",               FilterPiratesDead, "Pirates (dead)", false);
    MultiTargetFilter(add, "@pdead",            FilterPiratesDead, "Pirates (dead)", false);

    MultiTargetFilter(add, "@pha",              FilterPiratesHumansAlive, "Pirates (humans & alive)", false);
    MultiTargetFilter(add, "@phalive",          FilterPiratesHumansAlive, "Pirates (humans & alive)", false);

    MultiTargetFilter(add, "@phd",              FilterPiratesHumansDead, "Pirates (humans & dead)", false);
    MultiTargetFilter(add, "@phdead",           FilterPiratesHumansDead, "Pirates (humans & dead)", false);

    MultiTargetFilter(add, "@pba",              FilterPiratesBotsAlive, "Pirates (bots & alive)", false);
    MultiTargetFilter(add, "@pbalive",          FilterPiratesBotsAlive, "Pirates (bots & alive)", false);

    MultiTargetFilter(add, "@pbd",              FilterPiratesBotsDead, "Pirates (bots & dead)", false);
    MultiTargetFilter(add, "@pbdead",           FilterPiratesBotsDead, "Pirates (bots & dead)", false);

    MultiTargetFilter(add, "@v",                FilterVikings, "Vikings", false);
    MultiTargetFilter(add, "@viking",           FilterVikings, "Vikings", false);
    MultiTargetFilter(add, "@vikings",          FilterVikings, "Vikings", false);

    MultiTargetFilter(add, "@vh",               FilterVikingsHumans, "Vikings (humans)", false);
    MultiTargetFilter(add, "@vhumans",          FilterVikingsHumans, "Vikings (humans)", false);

    MultiTargetFilter(add, "@vb",               FilterVikingsBots, "Vikings (bots)", false);
    MultiTargetFilter(add, "@vbots",            FilterVikingsBots, "Vikings (bots)", false);

    MultiTargetFilter(add, "@va",               FilterVikingsAlive, "Vikings (alive)", false);
    MultiTargetFilter(add, "@valive",           FilterVikingsAlive, "Vikings (alive)", false);

    MultiTargetFilter(add, "@vd",               FilterVikingsDead, "Vikings (dead)", false);
    MultiTargetFilter(add, "@vdead",            FilterVikingsDead, "Vikings (dead)", false);

    MultiTargetFilter(add, "@vha",              FilterVikingsHumansAlive, "Vikings (humans & alive)", false);
    MultiTargetFilter(add, "@vhalive",          FilterVikingsHumansAlive, "Vikings (humans & alive)", false);

    MultiTargetFilter(add, "@vhd",              FilterVikingsHumansDead, "Vikings (humans & dead)", false);
    MultiTargetFilter(add, "@vhdead",           FilterVikingsHumansDead, "Vikings (humans & dead)", false);

    MultiTargetFilter(add, "@vba",              FilterVikingsBotsAlive, "Vikings (bots & alive)", false);
    MultiTargetFilter(add, "@vbalive",          FilterVikingsBotsAlive, "Vikings (bots & alive)", false);

    MultiTargetFilter(add, "@vbd",              FilterVikingsBotsDead, "Vikings (bots & dead)", false);
    MultiTargetFilter(add, "@vbdead",           FilterVikingsBotsDead, "Vikings (bots & dead)", false);

    MultiTargetFilter(add, "@k",                FilterKnights, "Knights", false);
    MultiTargetFilter(add, "@knight",           FilterKnights, "Knights", false);
    MultiTargetFilter(add, "@knights",          FilterKnights, "Knights", false);

    MultiTargetFilter(add, "@kh",               FilterKnightsHumans, "Knights (humans)", false);
    MultiTargetFilter(add, "@khumans",          FilterKnightsHumans, "Knights (humans)", false);

    MultiTargetFilter(add, "@kb",               FilterKnightsBots, "Knights (bots)", false);
    MultiTargetFilter(add, "@kbots",            FilterKnightsBots, "Knights (bots)", false);

    MultiTargetFilter(add, "@ka",               FilterKnightsAlive, "Knights (alive)", false);
    MultiTargetFilter(add, "@kalive",           FilterKnightsAlive, "Knights (alive)", false);

    MultiTargetFilter(add, "@kd",               FilterKnightsDead, "Knights (dead)", false);
    MultiTargetFilter(add, "@kdead",            FilterKnightsDead, "Knights (dead)", false);

    MultiTargetFilter(add, "@kha",              FilterKnightsHumansAlive, "Knights (humans & alive)", false);
    MultiTargetFilter(add, "@khalive",          FilterKnightsHumansAlive, "Knights (humans & alive)", false);

    MultiTargetFilter(add, "@khd",              FilterKnightsHumansDead, "Knights (humans & dead)", false);
    MultiTargetFilter(add, "@khdead",           FilterKnightsHumansDead, "Knights (humans & dead)", false);

    MultiTargetFilter(add, "@kba",              FilterKnightsBotsAlive, "Knights (bots & alive)", false);
    MultiTargetFilter(add, "@kbalive",          FilterKnightsBotsAlive, "Knights (bots & alive)", false);

    MultiTargetFilter(add, "@kbd",              FilterKnightsBotsDead, "Knights (bots & dead)", false);
    MultiTargetFilter(add, "@kbdead",           FilterKnightsBotsDead, "Knights (bots & dead)", false);

    MultiTargetFilter(add, "@r",                FilterRandomAll, "random player", false);
    MultiTargetFilter(add, "@random",           FilterRandomAll, "random player", false);

    MultiTargetFilter(add, "@rh",               FilterRandomHumans, "random player (humans)", false);
    MultiTargetFilter(add, "@rhumans",          FilterRandomHumans, "random player (humans)", false);

    MultiTargetFilter(add, "@rb",               FilterRandomBots, "random player (bots)", false);
    MultiTargetFilter(add, "@rbots",            FilterRandomBots, "random player (bots)", false);

    MultiTargetFilter(add, "@ra",               FilterRandomAlive, "random player (alive)", false);
    MultiTargetFilter(add, "@ralive",           FilterRandomAlive, "random player (alive)", false);

    MultiTargetFilter(add, "@rd",               FilterRandomDead, "random player (dead)", false);
    MultiTargetFilter(add, "@rdead",            FilterRandomDead, "random player (dead)", false);

    MultiTargetFilter(add, "@rs",         FilterRandomSpectators, "random Spectator", false);
    MultiTargetFilter(add, "@rspectator", FilterRandomSpectators, "random Spectator", false);

    MultiTargetFilter(add, "@rp",         FilterRandomPirates, "random Pirate", false);
    MultiTargetFilter(add, "@rpirates",   FilterRandomPirates, "random Pirate", false);

    MultiTargetFilter(add, "@rv",         FilterRandomVikings, "random Viking", false);
    MultiTargetFilter(add, "@rvikings",   FilterRandomVikings, "random Viking", false);

    MultiTargetFilter(add, "@rk",         FilterRandomKnights, "random Knight", false);
    MultiTargetFilter(add, "@rknights",   FilterRandomKnights, "random Knight", false);

    MultiTargetFilter(add, "@rph",        FilterRandomPiratesHumans, "random Pirate (humans)", false);
    MultiTargetFilter(add, "@rphumans",   FilterRandomPiratesHumans, "random Pirate (humans)", false);

    MultiTargetFilter(add, "@rpb",        FilterRandomPiratesBots, "random Pirate (bots)", false);
    MultiTargetFilter(add, "@rpbots",     FilterRandomPiratesBots, "random Pirate (bots)", false);

    MultiTargetFilter(add, "@rpa",        FilterRandomPiratesAlive, "random Pirate (alive)", false);
    MultiTargetFilter(add, "@rpalive",    FilterRandomPiratesAlive, "random Pirate (alive)", false);

    MultiTargetFilter(add, "@rpd",        FilterRandomPiratesDead, "random Pirate (dead)", false);
    MultiTargetFilter(add, "@rpdead",     FilterRandomPiratesDead, "random Pirate (dead)", false);

    MultiTargetFilter(add, "@rpha",       FilterRandomPiratesHumansAlive, "random Pirate (humans & alive)", false);
    MultiTargetFilter(add, "@rphalive",   FilterRandomPiratesHumansAlive, "random Pirate (humans & alive)", false);

    MultiTargetFilter(add, "@rphd",       FilterRandomPiratesHumansDead, "random Pirate (humans & dead)", false);
    MultiTargetFilter(add, "@rphdead",    FilterRandomPiratesHumansDead, "random Pirate (humans & dead)", false);

    MultiTargetFilter(add, "@rpba",       FilterRandomPiratesBotsAlive, "random Pirate (bots & alive)", false);
    MultiTargetFilter(add, "@rpbalive",   FilterRandomPiratesBotsAlive, "random Pirate (bots & alive)", false);

    MultiTargetFilter(add, "@rpbd",       FilterRandomPiratesBotsDead, "random Pirate (bots & dead)", false);
    MultiTargetFilter(add, "@rpbdead",    FilterRandomPiratesBotsDead, "random Pirate (bots & dead)", false);

    MultiTargetFilter(add, "@rvh",        FilterRandomVikingsHumans, "random Viking (humans)", false);
    MultiTargetFilter(add, "@rvhumans",   FilterRandomVikingsHumans, "random Viking (humans)", false);

    MultiTargetFilter(add, "@rvb",        FilterRandomVikingsBots, "random Viking (bots)", false);
    MultiTargetFilter(add, "@rvbots",     FilterRandomVikingsBots, "random Viking (bots)", false);

    MultiTargetFilter(add, "@rva",        FilterRandomVikingsAlive, "random Viking (alive)", false);
    MultiTargetFilter(add, "@rvalive",    FilterRandomVikingsAlive, "random Viking (alive)", false);

    MultiTargetFilter(add, "@rvd",        FilterRandomVikingsDead, "random Viking (dead)", false);
    MultiTargetFilter(add, "@rvdead",     FilterRandomVikingsDead, "random Viking (dead)", false);

    MultiTargetFilter(add, "@rvha",       FilterRandomVikingsHumansAlive, "random Viking (humans & alive)", false);
    MultiTargetFilter(add, "@rvhalive",   FilterRandomVikingsHumansAlive, "random Viking (humans & alive)", false);

    MultiTargetFilter(add, "@rvhd",       FilterRandomVikingsHumansDead, "random Viking (humans & dead)", false);
    MultiTargetFilter(add, "@rvhdead",    FilterRandomVikingsHumansDead, "random Viking (humans & dead)", false);

    MultiTargetFilter(add, "@rvba",       FilterRandomVikingsBotsAlive, "random Viking (bots & alive)", false);
    MultiTargetFilter(add, "@rvbalive",   FilterRandomVikingsBotsAlive, "random Viking (bots & alive)", false);

    MultiTargetFilter(add, "@rvbd",       FilterRandomVikingsBotsDead, "random Viking (bots & dead)", false);
    MultiTargetFilter(add, "@rvbdead",    FilterRandomVikingsBotsDead, "random Viking (bots & dead)", false);

    MultiTargetFilter(add, "@rkh",        FilterRandomKnightsHumans, "random Knight (humans)", false);
    MultiTargetFilter(add, "@rkhumans",   FilterRandomKnightsHumans, "random Knight (humans)", false);

    MultiTargetFilter(add, "@rkb",        FilterRandomKnightsBots, "random Knight (bots)", false);
    MultiTargetFilter(add, "@rkbots",     FilterRandomKnightsBots, "random Knight (bots)", false);

    MultiTargetFilter(add, "@rka",              FilterRandomKnightsAlive, "random Knight (alive)", false);
    MultiTargetFilter(add, "@rkalive",          FilterRandomKnightsAlive, "random Knight (alive)", false);

    MultiTargetFilter(add, "@rkd",              FilterRandomKnightsDead, "random Knight (dead)", false);
    MultiTargetFilter(add, "@rkdead",           FilterRandomKnightsDead, "random Knight (dead)", false);

    MultiTargetFilter(add, "@rkha",             FilterRandomKnightsHumansAlive, "random Knight (humans & alive)", false);
    MultiTargetFilter(add, "@rkhalive",         FilterRandomKnightsHumansAlive, "random Knight (humans & alive)", false);

    MultiTargetFilter(add, "@rkhd",             FilterRandomKnightsHumansDead, "random Knight (humans & dead)", false);
    MultiTargetFilter(add, "@rkhdead",          FilterRandomKnightsHumansDead, "random Knight (humans & dead)", false);

    MultiTargetFilter(add, "@rkba",             FilterRandomKnightsBotsAlive, "random Knight (bots & alive)", false);
    MultiTargetFilter(add, "@rkbalive",         FilterRandomKnightsBotsAlive, "random Knight (bots & alive)", false);

    MultiTargetFilter(add, "@rkbd",             FilterRandomKnightsBotsDead, "random Knight (bots & dead)", false);
    MultiTargetFilter(add, "@rkbdead",          FilterRandomKnightsBotsDead, "random Knight (bots & dead)", false);
}

/****************************************************************************************************/

void MultiTargetFilter(bool add, const char[] pattern, MultiTargetFilter filter, const char[] phrase, bool phraseIsML)
{
    if (add)
        AddMultiTargetFilter(pattern, filter, phrase, phraseIsML);
    else
        RemoveMultiTargetFilter(pattern, filter);
}

// ====================================================================================================
// Target Filters
// ====================================================================================================
bool FilterAll(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients);
}

/****************************************************************************************************/

bool FilterHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human);
}

/****************************************************************************************************/

bool FilterBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot);
}

/****************************************************************************************************/

bool FilterAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive);
}

/****************************************************************************************************/

bool FilterDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead);
}

/****************************************************************************************************/

bool FilterSpectators(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Spectators);
}

/****************************************************************************************************/

bool FilterPirates(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesHumansAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesHumansDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesBotsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterPiratesBotsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Pirates);
}

/****************************************************************************************************/

bool FilterVikings(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsHumansAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsHumansDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsBotsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterVikingsBotsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Vikings);
}

/****************************************************************************************************/

bool FilterKnights(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsHumansAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsHumansDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsBotsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterKnightsBotsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Knights);
}

/****************************************************************************************************/

bool FilterRandomAll(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomSpectators(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Spectators, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPirates(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikings(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnights(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesHumansAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesHumansDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesBotsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomPiratesBotsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsHumansAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsHumansDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsBotsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomVikingsBotsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsHumansAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsHumansDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsBotsAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomKnightsBotsDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool TargetFilter(ArrayList clients, ClientType type = ClientType_All, ClientState state = ClientState_All, ClientTeam team = ClientTeam_All, PickRandom random = PickRandom_No)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        switch (type)
        {
            case ClientType_Human: if (IsFakeClient(client)) continue;
            case ClientType_Bot: if (!IsFakeClient(client)) continue;
        }

        switch (state)
        {
            case ClientState_Dead: if (IsPlayerAlive(client)) continue;
            case ClientState_Alive: if (!IsPlayerAlive(client)) continue;
        }

        switch (team)
        {
            case ClientTeam_Pirates: if (GetClientTeamEnum(client) != ClientTeam_Pirates) continue;
            case ClientTeam_Vikings: if (GetClientTeamEnum(client) != ClientTeam_Vikings) continue;
            case ClientTeam_Knights: if (GetClientTeamEnum(client) != ClientTeam_Knights) continue;
        }

        clients.Push(client);
    }

    switch(random)
    {
        case PickRandom_Yes:
        {
            if (clients.Length > 0)
            {
                int client = clients.Get(GetRandomInt(0, clients.Length - 1));
                clients.Clear();
                clients.Push(client);
            }
        }
    }

    if (plugin.debug)
        plugin.DebugArray(clients);

    return true;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (pvk2_more_target_filters) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pvk2_more_target_filters_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "pvk2_more_target_filters_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "pvk2_more_target_filters_debug : %b (%s)", plugin.debug, plugin.debug ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Returns the ClientTeam enum.
 *
 * @param client        Client index.
 * @return              1=SPECTATORS, 2=PIRATES, 3=VIKINGS, 4=KNIGHTS
 */
ClientTeam GetClientTeamEnum(int client)
{
    return view_as<ClientTeam>(GetClientTeam(client));
}

