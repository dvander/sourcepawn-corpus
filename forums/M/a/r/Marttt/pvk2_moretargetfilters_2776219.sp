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
#define PLUGIN_DESCRIPTION            "Adds more target filters"
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
#define CONFIG_FILENAME               "pvk2_moretargetfilters"

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
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Debug;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bMultiTargetFilters;
bool g_bCvar_Enabled;
bool g_bCvar_Debug;

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
    CreateConVar("pvk2_moretargetfilters_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("pvk2_moretargetfilters_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Debug   = CreateConVar("pvk2_moretargetfilters_debug", "0", "Output to chat info about clients found by the target filter.\n0 = Debug OFF, 1 = Debug ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Debug.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_pvk2_moretargetfilters", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    RemoveMultiTargetFilters();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    SetTargetFilters();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    SetTargetFilters();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Debug = g_hCvar_Debug.BoolValue;
}

/****************************************************************************************************/

void SetTargetFilters()
{
    if (g_bCvar_Enabled && !g_bMultiTargetFilters)
    {
        g_bMultiTargetFilters = true;

        AddMultiTargetFilters();

        return;
    }

    if (!g_bCvar_Enabled && g_bMultiTargetFilters)
    {
        g_bMultiTargetFilters = false;

        RemoveMultiTargetFilters();

        return;
    }
}

/****************************************************************************************************/

void AddMultiTargetFilters()
{
    AddMultiTargetFilter("@a",              FilterAll, "all players", true);
    AddMultiTargetFilter("@al",             FilterAll, "all players", true);
    // AddMultiTargetFilter("@all",            FilterAll, "all players", true); // SM already has it by default

    AddMultiTargetFilter("@h",              FilterHumans, "all humans", true);
    AddMultiTargetFilter("@hu",             FilterHumans, "all humans", true);
    AddMultiTargetFilter("@hum",            FilterHumans, "all humans", true);
    AddMultiTargetFilter("@huma",           FilterHumans, "all humans", true);
    AddMultiTargetFilter("@human",          FilterHumans, "all humans", true);
    // AddMultiTargetFilter("@humans",         FilterHumans, "all humans", true); // SM already has it by default

    AddMultiTargetFilter("@b",              FilterBots, "all bots", true);
    AddMultiTargetFilter("@bo",             FilterBots, "all bots", true);
    AddMultiTargetFilter("@bot",            FilterBots, "all bots", true);
    // AddMultiTargetFilter("@bots",           FilterBots, "all bots", true); // SM already has it by default

    // AddMultiTargetFilter("@a",              FilterAlive, "all alive players", true); // Conflicts with @all
    // AddMultiTargetFilter("@al",             FilterAlive, "all alive players", true); // Conflicts with @all
    AddMultiTargetFilter("@ali",            FilterAlive, "all alive players", true);
    AddMultiTargetFilter("@aliv",           FilterAlive, "all alive players", true);
    // AddMultiTargetFilter("@alive",          FilterAlive, "all alive players", true); // SM already has it by default

    AddMultiTargetFilter("@d",              FilterDead, "all dead players", true);
    AddMultiTargetFilter("@de",             FilterDead, "all dead players", true);
    AddMultiTargetFilter("@dea",            FilterDead, "all dead players", true);
    // AddMultiTargetFilter("@dead",           FilterDead, "all dead players", true); // SM already has it by default

    AddMultiTargetFilter("@s",              FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@sp",             FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spe",            FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spec",           FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spect",          FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@specta",         FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spectat",        FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spectato",       FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spectator",      FilterSpectators, "all spectators", true);
    AddMultiTargetFilter("@spectators",     FilterSpectators, "all spectators", true);

    AddMultiTargetFilter("@p",              FilterPirates, "Pirates", false);
    AddMultiTargetFilter("@pi",             FilterPirates, "Pirates", false);
    AddMultiTargetFilter("@pir",            FilterPirates, "Pirates", false);
    AddMultiTargetFilter("@pira",           FilterPirates, "Pirates", false);
    AddMultiTargetFilter("@pirat",          FilterPirates, "Pirates", false);
    AddMultiTargetFilter("@pirate",         FilterPirates, "Pirates", false);
    AddMultiTargetFilter("@pirates",        FilterPirates, "Pirates", false);

    AddMultiTargetFilter("@ph",             FilterPiratesHumans, "Pirates (human)", false);
    AddMultiTargetFilter("@phu",            FilterPiratesHumans, "Pirates (human)", false);
    AddMultiTargetFilter("@phum",           FilterPiratesHumans, "Pirates (human)", false);
    AddMultiTargetFilter("@phuma",          FilterPiratesHumans, "Pirates (human)", false);
    AddMultiTargetFilter("@phuman",         FilterPiratesHumans, "Pirates (human)", false);
    AddMultiTargetFilter("@phumans",        FilterPiratesHumans, "Pirates (human)", false);

    AddMultiTargetFilter("@pb",             FilterPiratesBots, "Pirates (bot)", false);
    AddMultiTargetFilter("@pbo",            FilterPiratesBots, "Pirates (bot)", false);
    AddMultiTargetFilter("@pbot",           FilterPiratesBots, "Pirates (bot)", false);
    AddMultiTargetFilter("@pbots",          FilterPiratesBots, "Pirates (bot)", false);

    AddMultiTargetFilter("@pa",             FilterPiratesAlive, "Pirates (alive)", false);
    AddMultiTargetFilter("@pal",            FilterPiratesAlive, "Pirates (alive)", false);
    AddMultiTargetFilter("@pali",           FilterPiratesAlive, "Pirates (alive)", false);
    AddMultiTargetFilter("@paliv",          FilterPiratesAlive, "Pirates (alive)", false);
    AddMultiTargetFilter("@palive",         FilterPiratesAlive, "Pirates (alive)", false);

    AddMultiTargetFilter("@pd",             FilterPiratesDead, "Pirates (dead)", false);
    AddMultiTargetFilter("@pde",            FilterPiratesDead, "Pirates (dead)", false);
    AddMultiTargetFilter("@pdea",           FilterPiratesDead, "Pirates (dead)", false);
    AddMultiTargetFilter("@pdead",          FilterPiratesDead, "Pirates (dead)", false);

    AddMultiTargetFilter("@pha",            FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    AddMultiTargetFilter("@phal",           FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    AddMultiTargetFilter("@phali",          FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    AddMultiTargetFilter("@phaliv",         FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    AddMultiTargetFilter("@phalive",        FilterPiratesHumansAlive, "Pirates (human & alive)", false);

    AddMultiTargetFilter("@phd",            FilterPiratesHumansDead, "Pirates (human & dead)", false);
    AddMultiTargetFilter("@phde",           FilterPiratesHumansDead, "Pirates (human & dead)", false);
    AddMultiTargetFilter("@phdea",          FilterPiratesHumansDead, "Pirates (human & dead)", false);
    AddMultiTargetFilter("@phdead",         FilterPiratesHumansDead, "Pirates (human & dead)", false);

    AddMultiTargetFilter("@pba",            FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    AddMultiTargetFilter("@pbal",           FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    AddMultiTargetFilter("@pbali",          FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    AddMultiTargetFilter("@pbaliv",         FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    AddMultiTargetFilter("@pbalive",        FilterPiratesBotsAlive, "Pirates (bot & alive)", false);

    AddMultiTargetFilter("@pbd",            FilterPiratesBotsDead, "Pirates (bot & dead)", false);
    AddMultiTargetFilter("@pbde",           FilterPiratesBotsDead, "Pirates (bot & dead)", false);
    AddMultiTargetFilter("@pbdea",          FilterPiratesBotsDead, "Pirates (bot & dead)", false);
    AddMultiTargetFilter("@pbdead",         FilterPiratesBotsDead, "Pirates (bot & dead)", false);

    AddMultiTargetFilter("@v",              FilterVikings, "Vikings", false);
    AddMultiTargetFilter("@vi",             FilterVikings, "Vikings", false);
    AddMultiTargetFilter("@vik",            FilterVikings, "Vikings", false);
    AddMultiTargetFilter("@viki",           FilterVikings, "Vikings", false);
    AddMultiTargetFilter("@vikin",          FilterVikings, "Vikings", false);
    AddMultiTargetFilter("@viking",         FilterVikings, "Vikings", false);
    AddMultiTargetFilter("@vikings",        FilterVikings, "Vikings", false);

    AddMultiTargetFilter("@vh",             FilterVikingsHumans, "Vikings (human)", false);
    AddMultiTargetFilter("@vhu",            FilterVikingsHumans, "Vikings (human)", false);
    AddMultiTargetFilter("@vhum",           FilterVikingsHumans, "Vikings (human)", false);
    AddMultiTargetFilter("@vhuma",          FilterVikingsHumans, "Vikings (human)", false);
    AddMultiTargetFilter("@vhuman",         FilterVikingsHumans, "Vikings (human)", false);
    AddMultiTargetFilter("@vhumans",        FilterVikingsHumans, "Vikings (human)", false);

    AddMultiTargetFilter("@vb",             FilterVikingsBots, "Vikings (bot)", false);
    AddMultiTargetFilter("@vbo",            FilterVikingsBots, "Vikings (bot)", false);
    AddMultiTargetFilter("@vbot",           FilterVikingsBots, "Vikings (bot)", false);
    AddMultiTargetFilter("@vbots",          FilterVikingsBots, "Vikings (bot)", false);

    AddMultiTargetFilter("@va",             FilterVikingsAlive, "Vikings (alive)", false);
    AddMultiTargetFilter("@val",            FilterVikingsAlive, "Vikings (alive)", false);
    AddMultiTargetFilter("@vali",           FilterVikingsAlive, "Vikings (alive)", false);
    AddMultiTargetFilter("@valiv",          FilterVikingsAlive, "Vikings (alive)", false);
    AddMultiTargetFilter("@valive",         FilterVikingsAlive, "Vikings (alive)", false);

    AddMultiTargetFilter("@vd",             FilterVikingsDead, "Vikings (dead)", false);
    AddMultiTargetFilter("@vde",            FilterVikingsDead, "Vikings (dead)", false);
    AddMultiTargetFilter("@vdea",           FilterVikingsDead, "Vikings (dead)", false);
    AddMultiTargetFilter("@vdead",          FilterVikingsDead, "Vikings (dead)", false);

    AddMultiTargetFilter("@vha",            FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    AddMultiTargetFilter("@vhal",           FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    AddMultiTargetFilter("@vhali",          FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    AddMultiTargetFilter("@vhaliv",         FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    AddMultiTargetFilter("@vhalive",        FilterVikingsHumansAlive, "Vikings (human & alive)", false);

    AddMultiTargetFilter("@vhd",            FilterVikingsHumansDead, "Vikings (human & dead)", false);
    AddMultiTargetFilter("@vhde",           FilterVikingsHumansDead, "Vikings (human & dead)", false);
    AddMultiTargetFilter("@vhdea",          FilterVikingsHumansDead, "Vikings (human & dead)", false);
    AddMultiTargetFilter("@vhdead",         FilterVikingsHumansDead, "Vikings (human & dead)", false);

    AddMultiTargetFilter("@vba",            FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    AddMultiTargetFilter("@vbal",           FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    AddMultiTargetFilter("@vbali",          FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    AddMultiTargetFilter("@vbaliv",         FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    AddMultiTargetFilter("@vbalive",        FilterVikingsBotsAlive, "Vikings (bot & alive)", false);

    AddMultiTargetFilter("@vbd",            FilterVikingsBotsDead, "Vikings (bot & dead)", false);
    AddMultiTargetFilter("@vbde",           FilterVikingsBotsDead, "Vikings (bot & dead)", false);
    AddMultiTargetFilter("@vbdea",          FilterVikingsBotsDead, "Vikings (bot & dead)", false);
    AddMultiTargetFilter("@vbdead",         FilterVikingsBotsDead, "Vikings (bot & dead)", false);

    AddMultiTargetFilter("@k",              FilterKnights, "Knights", false);
    AddMultiTargetFilter("@kn",             FilterKnights, "Knights", false);
    AddMultiTargetFilter("@kni",            FilterKnights, "Knights", false);
    AddMultiTargetFilter("@knig",           FilterKnights, "Knights", false);
    AddMultiTargetFilter("@knigh",          FilterKnights, "Knights", false);
    AddMultiTargetFilter("@knight",         FilterKnights, "Knights", false);
    AddMultiTargetFilter("@knights",        FilterKnights, "Knights", false);

    AddMultiTargetFilter("@kh",             FilterKnightsHumans, "Knights (human)", false);
    AddMultiTargetFilter("@khu",            FilterKnightsHumans, "Knights (human)", false);
    AddMultiTargetFilter("@khum",           FilterKnightsHumans, "Knights (human)", false);
    AddMultiTargetFilter("@khuma",          FilterKnightsHumans, "Knights (human)", false);
    AddMultiTargetFilter("@khuman",         FilterKnightsHumans, "Knights (human)", false);
    AddMultiTargetFilter("@khumans",        FilterKnightsHumans, "Knights (human)", false);

    AddMultiTargetFilter("@kb",             FilterKnightsBots, "Knights (bot)", false);
    AddMultiTargetFilter("@kbo",            FilterKnightsBots, "Knights (bot)", false);
    AddMultiTargetFilter("@kbot",           FilterKnightsBots, "Knights (bot)", false);
    AddMultiTargetFilter("@kbots",          FilterKnightsBots, "Knights (bot)", false);

    AddMultiTargetFilter("@ka",             FilterKnightsAlive, "Knights (alive)", false);
    AddMultiTargetFilter("@kal",            FilterKnightsAlive, "Knights (alive)", false);
    AddMultiTargetFilter("@kali",           FilterKnightsAlive, "Knights (alive)", false);
    AddMultiTargetFilter("@kaliv",          FilterKnightsAlive, "Knights (alive)", false);
    AddMultiTargetFilter("@kalive",         FilterKnightsAlive, "Knights (alive)", false);

    AddMultiTargetFilter("@kd",             FilterKnightsDead, "Knights (dead)", false);
    AddMultiTargetFilter("@kde",            FilterKnightsDead, "Knights (dead)", false);
    AddMultiTargetFilter("@kdea",           FilterKnightsDead, "Knights (dead)", false);
    AddMultiTargetFilter("@kdead",          FilterKnightsDead, "Knights (dead)", false);

    AddMultiTargetFilter("@kha",            FilterKnightsHumansAlive, "Knights (human & alive)", false);
    AddMultiTargetFilter("@khal",           FilterKnightsHumansAlive, "Knights (human & alive)", false);
    AddMultiTargetFilter("@khali",          FilterKnightsHumansAlive, "Knights (human & alive)", false);
    AddMultiTargetFilter("@khaliv",         FilterKnightsHumansAlive, "Knights (human & alive)", false);
    AddMultiTargetFilter("@khalive",        FilterKnightsHumansAlive, "Knights (human & alive)", false);

    AddMultiTargetFilter("@khd",            FilterKnightsHumansDead, "Knights (human & dead)", false);
    AddMultiTargetFilter("@khde",           FilterKnightsHumansDead, "Knights (human & dead)", false);
    AddMultiTargetFilter("@khdea",          FilterKnightsHumansDead, "Knights (human & dead)", false);
    AddMultiTargetFilter("@khdead",         FilterKnightsHumansDead, "Knights (human & dead)", false);

    AddMultiTargetFilter("@kba",            FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    AddMultiTargetFilter("@kbal",           FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    AddMultiTargetFilter("@kbali",          FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    AddMultiTargetFilter("@kbaliv",         FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    AddMultiTargetFilter("@kbalive",        FilterKnightsBotsAlive, "Knights (bot & alive)", false);

    AddMultiTargetFilter("@kbd",            FilterKnightsBotsDead, "Knights (bot & dead)", false);
    AddMultiTargetFilter("@kbde",           FilterKnightsBotsDead, "Knights (bot & dead)", false);
    AddMultiTargetFilter("@kbdea",          FilterKnightsBotsDead, "Knights (bot & dead)", false);
    AddMultiTargetFilter("@kbdead",         FilterKnightsBotsDead, "Knights (bot & dead)", false);

    AddMultiTargetFilter("@r",              FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@rn",             FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@rng",            FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@ra",             FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@ran",            FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@rand",           FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@rando",          FilterAllRandom, "random player", false);
    AddMultiTargetFilter("@random",         FilterAllRandom, "random player", false);

    AddMultiTargetFilter("@sr",             FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@srn",            FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@srng",           FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@sra",            FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@sran",           FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@srand",          FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@srando",         FilterSpectatorsRandom, "random Spectator", false);
    AddMultiTargetFilter("@srandom",        FilterSpectatorsRandom, "random Spectator", false);

    AddMultiTargetFilter("@pr",             FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@prn",            FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@prng",           FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@pra",            FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@pran",           FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@prand",          FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@prando",         FilterPiratesRandom, "random Pirate", false);
    AddMultiTargetFilter("@prandom",        FilterPiratesRandom, "random Pirate", false);

    AddMultiTargetFilter("@vr",             FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vrn",            FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vrng",           FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vra",            FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vran",           FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vrand",          FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vrando",         FilterVikingsRandom, "random Viking", false);
    AddMultiTargetFilter("@vrandom",        FilterVikingsRandom, "random Viking", false);

    AddMultiTargetFilter("@kr",             FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@krn",            FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@krng",           FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@kra",            FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@kran",           FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@krand",          FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@krando",         FilterKnightsRandom, "random Knight", false);
    AddMultiTargetFilter("@krandom",        FilterKnightsRandom, "random Knight", false);

    AddMultiTargetFilter("@phr",            FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phrn",           FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phrng",          FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phra",           FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phran",          FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phrand",         FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phrando",        FilterPiratesHumansRandom, "random Pirate (human)", false);
    AddMultiTargetFilter("@phrandom",       FilterPiratesHumansRandom, "random Pirate (human)", false);

    AddMultiTargetFilter("@pbr",            FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbrn",           FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbrng",          FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbra",           FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbran",          FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbrand",         FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbrando",        FilterPiratesBotsRandom, "random Pirate (bot)", false);
    AddMultiTargetFilter("@pbrandom",       FilterPiratesBotsRandom, "random Pirate (bot)", false);

    AddMultiTargetFilter("@par",            FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@parn",           FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@parng",          FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@para",           FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@paran",          FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@parand",         FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@parando",        FilterPiratesAliveRandom, "random Pirate (alive)", false);
    AddMultiTargetFilter("@parandom",       FilterPiratesAliveRandom, "random Pirate (alive)", false);

    AddMultiTargetFilter("@pdr",            FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdrn",           FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdrng",          FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdra",           FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdran",          FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdrand",         FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdrando",        FilterPiratesDeadRandom, "random Pirate (dead)", false);
    AddMultiTargetFilter("@pdrandom",       FilterPiratesDeadRandom, "random Pirate (dead)", false);

    AddMultiTargetFilter("@phar",           FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@pharn",          FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@pharng",         FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@phara",          FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@pharan",         FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@pharand",        FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@pharando",       FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    AddMultiTargetFilter("@pharandom",      FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);

    AddMultiTargetFilter("@phdr",           FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdrn",          FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdrng",         FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdra",          FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdran",         FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdrand",        FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdrando",       FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    AddMultiTargetFilter("@phdrandom",      FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);

    AddMultiTargetFilter("@pbar",           FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbarn",          FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbarng",         FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbara",          FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbaran",         FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbarand",        FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbarando",       FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    AddMultiTargetFilter("@pbarandom",      FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);

    AddMultiTargetFilter("@pbdr",           FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdrn",          FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdrng",         FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdra",          FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdran",         FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdrand",        FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdrando",       FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    AddMultiTargetFilter("@pbdrandom",      FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);

    AddMultiTargetFilter("@vhr",            FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhrn",           FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhrng",          FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhra",           FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhran",          FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhrand",         FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhrando",        FilterVikingsHumansRandom, "random Viking (human)", false);
    AddMultiTargetFilter("@vhrandom",       FilterVikingsHumansRandom, "random Viking (human)", false);

    AddMultiTargetFilter("@vbr",            FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbrn",           FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbrng",          FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbra",           FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbran",          FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbrand",         FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbrando",        FilterVikingsBotsRandom, "random Viking (bot)", false);
    AddMultiTargetFilter("@vbrandom",       FilterVikingsBotsRandom, "random Viking (bot)", false);

    AddMultiTargetFilter("@var",            FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@varn",           FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@varng",          FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@vara",           FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@varan",          FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@varand",         FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@varando",        FilterVikingsAliveRandom, "random Viking (alive)", false);
    AddMultiTargetFilter("@varandom",       FilterVikingsAliveRandom, "random Viking (alive)", false);

    AddMultiTargetFilter("@vdr",            FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdrn",           FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdrng",          FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdra",           FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdran",          FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdrand",         FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdrando",        FilterVikingsDeadRandom, "random Viking (dead)", false);
    AddMultiTargetFilter("@vdrandom",       FilterVikingsDeadRandom, "random Viking (dead)", false);

    AddMultiTargetFilter("@vhar",           FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vharn",          FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vharng",         FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vhara",          FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vharan",         FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vharand",        FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vharando",       FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    AddMultiTargetFilter("@vharandom",      FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);

    AddMultiTargetFilter("@vhdr",           FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdrn",          FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdrng",         FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdra",          FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdran",         FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdrand",        FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdrando",       FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    AddMultiTargetFilter("@vhdrandom",      FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);

    AddMultiTargetFilter("@vbar",           FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbarn",          FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbarng",         FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbara",          FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbaran",         FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbarand",        FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbarando",       FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    AddMultiTargetFilter("@vbarandom",      FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);

    AddMultiTargetFilter("@vbdr",           FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdrn",          FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdrng",         FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdra",          FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdran",         FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdrand",        FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdrando",       FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    AddMultiTargetFilter("@vbdrandom",      FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);

    AddMultiTargetFilter("@khr",            FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khrn",           FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khrng",          FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khra",           FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khran",          FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khrand",         FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khrando",        FilterKnightsHumansRandom, "random Knight (human)", false);
    AddMultiTargetFilter("@khrandom",       FilterKnightsHumansRandom, "random Knight (human)", false);

    AddMultiTargetFilter("@kbr",            FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbrn",           FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbrng",          FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbra",           FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbran",          FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbrand",         FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbrando",        FilterKnightsBotsRandom, "random Knight (bot)", false);
    AddMultiTargetFilter("@kbrandom",       FilterKnightsBotsRandom, "random Knight (bot)", false);

    AddMultiTargetFilter("@kar",            FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@karn",           FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@karng",          FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@kara",           FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@karan",          FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@karand",         FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@karando",        FilterKnightsAliveRandom, "random Knight (alive)", false);
    AddMultiTargetFilter("@karandom",       FilterKnightsAliveRandom, "random Knight (alive)", false);

    AddMultiTargetFilter("@kdr",            FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdrn",           FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdrng",          FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdra",           FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdran",          FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdrand",         FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdrando",        FilterKnightsDeadRandom, "random Knight (dead)", false);
    AddMultiTargetFilter("@kdrandom",       FilterKnightsDeadRandom, "random Knight (dead)", false);

    AddMultiTargetFilter("@khar",           FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@kharn",          FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@kharng",         FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@khara",          FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@kharan",         FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@kharand",        FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@kharando",       FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    AddMultiTargetFilter("@kharandom",      FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);

    AddMultiTargetFilter("@khdr",           FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdrn",          FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdrng",         FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdra",          FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdran",         FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdrand",        FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdrando",       FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    AddMultiTargetFilter("@khdrandom",      FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);

    AddMultiTargetFilter("@kbar",           FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbarn",          FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbarng",         FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbara",          FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbaran",         FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbarand",        FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbarando",       FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    AddMultiTargetFilter("@kbarandom",      FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);

    AddMultiTargetFilter("@kbdr",           FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdrn",          FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdrng",         FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdra",          FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdran",         FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdrand",        FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdrando",       FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    AddMultiTargetFilter("@kbdrandom",      FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
}

/****************************************************************************************************/

void RemoveMultiTargetFilters()
{
    RemoveMultiTargetFilter2("@a",              FilterAll, "all players", true);
    RemoveMultiTargetFilter2("@al",             FilterAll, "all players", true);
    // RemoveMultiTargetFilter2("@all",            FilterAll, "all players", true); // SM already has it by default

    RemoveMultiTargetFilter2("@h",              FilterHumans, "all humans", true);
    RemoveMultiTargetFilter2("@hu",             FilterHumans, "all humans", true);
    RemoveMultiTargetFilter2("@hum",            FilterHumans, "all humans", true);
    RemoveMultiTargetFilter2("@huma",           FilterHumans, "all humans", true);
    RemoveMultiTargetFilter2("@human",          FilterHumans, "all humans", true);
    // RemoveMultiTargetFilter2("@humans",         FilterHumans, "all humans", true); // SM already has it by default

    RemoveMultiTargetFilter2("@b",              FilterBots, "all bots", true);
    RemoveMultiTargetFilter2("@bo",             FilterBots, "all bots", true);
    RemoveMultiTargetFilter2("@bot",            FilterBots, "all bots", true);
    // RemoveMultiTargetFilter2("@bots",           FilterBots, "all bots", true); // SM already has it by default

    // RemoveMultiTargetFilter2("@a",              FilterAlive, "all alive players", true); // Conflicts with @all
    // RemoveMultiTargetFilter2("@al",             FilterAlive, "all alive players", true); // Conflicts with @all
    RemoveMultiTargetFilter2("@ali",            FilterAlive, "all alive players", true);
    RemoveMultiTargetFilter2("@aliv",           FilterAlive, "all alive players", true);
    // RemoveMultiTargetFilter2("@alive",          FilterAlive, "all alive players", true); // SM already has it by default

    RemoveMultiTargetFilter2("@d",              FilterDead, "all dead players", true);
    RemoveMultiTargetFilter2("@de",             FilterDead, "all dead players", true);
    RemoveMultiTargetFilter2("@dea",            FilterDead, "all dead players", true);
    // RemoveMultiTargetFilter2("@dead",           FilterDead, "all dead players", true); // SM already has it by default

    RemoveMultiTargetFilter2("@s",              FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@sp",             FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spe",            FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spec",           FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spect",          FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@specta",         FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spectat",        FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spectato",       FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spectator",      FilterSpectators, "all spectators", true);
    RemoveMultiTargetFilter2("@spectators",     FilterSpectators, "all spectators", true);

    RemoveMultiTargetFilter2("@p",              FilterPirates, "Pirates", false);
    RemoveMultiTargetFilter2("@pi",             FilterPirates, "Pirates", false);
    RemoveMultiTargetFilter2("@pir",            FilterPirates, "Pirates", false);
    RemoveMultiTargetFilter2("@pira",           FilterPirates, "Pirates", false);
    RemoveMultiTargetFilter2("@pirat",          FilterPirates, "Pirates", false);
    RemoveMultiTargetFilter2("@pirate",         FilterPirates, "Pirates", false);
    RemoveMultiTargetFilter2("@pirates",        FilterPirates, "Pirates", false);

    RemoveMultiTargetFilter2("@ph",             FilterPiratesHumans, "Pirates (human)", false);
    RemoveMultiTargetFilter2("@phu",            FilterPiratesHumans, "Pirates (human)", false);
    RemoveMultiTargetFilter2("@phum",           FilterPiratesHumans, "Pirates (human)", false);
    RemoveMultiTargetFilter2("@phuma",          FilterPiratesHumans, "Pirates (human)", false);
    RemoveMultiTargetFilter2("@phuman",         FilterPiratesHumans, "Pirates (human)", false);
    RemoveMultiTargetFilter2("@phumans",        FilterPiratesHumans, "Pirates (human)", false);

    RemoveMultiTargetFilter2("@pb",             FilterPiratesBots, "Pirates (bot)", false);
    RemoveMultiTargetFilter2("@pbo",            FilterPiratesBots, "Pirates (bot)", false);
    RemoveMultiTargetFilter2("@pbot",           FilterPiratesBots, "Pirates (bot)", false);
    RemoveMultiTargetFilter2("@pbots",          FilterPiratesBots, "Pirates (bot)", false);

    RemoveMultiTargetFilter2("@pa",             FilterPiratesAlive, "Pirates (alive)", false);
    RemoveMultiTargetFilter2("@pal",            FilterPiratesAlive, "Pirates (alive)", false);
    RemoveMultiTargetFilter2("@pali",           FilterPiratesAlive, "Pirates (alive)", false);
    RemoveMultiTargetFilter2("@paliv",          FilterPiratesAlive, "Pirates (alive)", false);
    RemoveMultiTargetFilter2("@palive",         FilterPiratesAlive, "Pirates (alive)", false);

    RemoveMultiTargetFilter2("@pd",             FilterPiratesDead, "Pirates (dead)", false);
    RemoveMultiTargetFilter2("@pde",            FilterPiratesDead, "Pirates (dead)", false);
    RemoveMultiTargetFilter2("@pdea",           FilterPiratesDead, "Pirates (dead)", false);
    RemoveMultiTargetFilter2("@pdead",          FilterPiratesDead, "Pirates (dead)", false);

    RemoveMultiTargetFilter2("@pha",            FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    RemoveMultiTargetFilter2("@phal",           FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    RemoveMultiTargetFilter2("@phali",          FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    RemoveMultiTargetFilter2("@phaliv",         FilterPiratesHumansAlive, "Pirates (human & alive)", false);
    RemoveMultiTargetFilter2("@phalive",        FilterPiratesHumansAlive, "Pirates (human & alive)", false);

    RemoveMultiTargetFilter2("@phd",            FilterPiratesHumansDead, "Pirates (human & dead)", false);
    RemoveMultiTargetFilter2("@phde",           FilterPiratesHumansDead, "Pirates (human & dead)", false);
    RemoveMultiTargetFilter2("@phdea",          FilterPiratesHumansDead, "Pirates (human & dead)", false);
    RemoveMultiTargetFilter2("@phdead",         FilterPiratesHumansDead, "Pirates (human & dead)", false);

    RemoveMultiTargetFilter2("@pba",            FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbal",           FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbali",          FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbaliv",         FilterPiratesBotsAlive, "Pirates (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbalive",        FilterPiratesBotsAlive, "Pirates (bot & alive)", false);

    RemoveMultiTargetFilter2("@pbd",            FilterPiratesBotsDead, "Pirates (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbde",           FilterPiratesBotsDead, "Pirates (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdea",          FilterPiratesBotsDead, "Pirates (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdead",         FilterPiratesBotsDead, "Pirates (bot & dead)", false);

    RemoveMultiTargetFilter2("@v",              FilterVikings, "Vikings", false);
    RemoveMultiTargetFilter2("@vi",             FilterVikings, "Vikings", false);
    RemoveMultiTargetFilter2("@vik",            FilterVikings, "Vikings", false);
    RemoveMultiTargetFilter2("@viki",           FilterVikings, "Vikings", false);
    RemoveMultiTargetFilter2("@vikin",          FilterVikings, "Vikings", false);
    RemoveMultiTargetFilter2("@viking",         FilterVikings, "Vikings", false);
    RemoveMultiTargetFilter2("@vikings",        FilterVikings, "Vikings", false);

    RemoveMultiTargetFilter2("@vh",             FilterVikingsHumans, "Vikings (human)", false);
    RemoveMultiTargetFilter2("@vhu",            FilterVikingsHumans, "Vikings (human)", false);
    RemoveMultiTargetFilter2("@vhum",           FilterVikingsHumans, "Vikings (human)", false);
    RemoveMultiTargetFilter2("@vhuma",          FilterVikingsHumans, "Vikings (human)", false);
    RemoveMultiTargetFilter2("@vhuman",         FilterVikingsHumans, "Vikings (human)", false);
    RemoveMultiTargetFilter2("@vhumans",        FilterVikingsHumans, "Vikings (human)", false);

    RemoveMultiTargetFilter2("@vb",             FilterVikingsBots, "Vikings (bot)", false);
    RemoveMultiTargetFilter2("@vbo",            FilterVikingsBots, "Vikings (bot)", false);
    RemoveMultiTargetFilter2("@vbot",           FilterVikingsBots, "Vikings (bot)", false);
    RemoveMultiTargetFilter2("@vbots",          FilterVikingsBots, "Vikings (bot)", false);

    RemoveMultiTargetFilter2("@va",             FilterVikingsAlive, "Vikings (alive)", false);
    RemoveMultiTargetFilter2("@val",            FilterVikingsAlive, "Vikings (alive)", false);
    RemoveMultiTargetFilter2("@vali",           FilterVikingsAlive, "Vikings (alive)", false);
    RemoveMultiTargetFilter2("@valiv",          FilterVikingsAlive, "Vikings (alive)", false);
    RemoveMultiTargetFilter2("@valive",         FilterVikingsAlive, "Vikings (alive)", false);

    RemoveMultiTargetFilter2("@vd",             FilterVikingsDead, "Vikings (dead)", false);
    RemoveMultiTargetFilter2("@vde",            FilterVikingsDead, "Vikings (dead)", false);
    RemoveMultiTargetFilter2("@vdea",           FilterVikingsDead, "Vikings (dead)", false);
    RemoveMultiTargetFilter2("@vdead",          FilterVikingsDead, "Vikings (dead)", false);

    RemoveMultiTargetFilter2("@vha",            FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    RemoveMultiTargetFilter2("@vhal",           FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    RemoveMultiTargetFilter2("@vhali",          FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    RemoveMultiTargetFilter2("@vhaliv",         FilterVikingsHumansAlive, "Vikings (human & alive)", false);
    RemoveMultiTargetFilter2("@vhalive",        FilterVikingsHumansAlive, "Vikings (human & alive)", false);

    RemoveMultiTargetFilter2("@vhd",            FilterVikingsHumansDead, "Vikings (human & dead)", false);
    RemoveMultiTargetFilter2("@vhde",           FilterVikingsHumansDead, "Vikings (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdea",          FilterVikingsHumansDead, "Vikings (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdead",         FilterVikingsHumansDead, "Vikings (human & dead)", false);

    RemoveMultiTargetFilter2("@vba",            FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbal",           FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbali",          FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbaliv",         FilterVikingsBotsAlive, "Vikings (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbalive",        FilterVikingsBotsAlive, "Vikings (bot & alive)", false);

    RemoveMultiTargetFilter2("@vbd",            FilterVikingsBotsDead, "Vikings (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbde",           FilterVikingsBotsDead, "Vikings (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdea",          FilterVikingsBotsDead, "Vikings (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdead",         FilterVikingsBotsDead, "Vikings (bot & dead)", false);

    RemoveMultiTargetFilter2("@k",              FilterKnights, "Knights", false);
    RemoveMultiTargetFilter2("@kn",             FilterKnights, "Knights", false);
    RemoveMultiTargetFilter2("@kni",            FilterKnights, "Knights", false);
    RemoveMultiTargetFilter2("@knig",           FilterKnights, "Knights", false);
    RemoveMultiTargetFilter2("@knigh",          FilterKnights, "Knights", false);
    RemoveMultiTargetFilter2("@knight",         FilterKnights, "Knights", false);
    RemoveMultiTargetFilter2("@knights",        FilterKnights, "Knights", false);

    RemoveMultiTargetFilter2("@kh",             FilterKnightsHumans, "Knights (human)", false);
    RemoveMultiTargetFilter2("@khu",            FilterKnightsHumans, "Knights (human)", false);
    RemoveMultiTargetFilter2("@khum",           FilterKnightsHumans, "Knights (human)", false);
    RemoveMultiTargetFilter2("@khuma",          FilterKnightsHumans, "Knights (human)", false);
    RemoveMultiTargetFilter2("@khuman",         FilterKnightsHumans, "Knights (human)", false);
    RemoveMultiTargetFilter2("@khumans",        FilterKnightsHumans, "Knights (human)", false);

    RemoveMultiTargetFilter2("@kb",             FilterKnightsBots, "Knights (bot)", false);
    RemoveMultiTargetFilter2("@kbo",            FilterKnightsBots, "Knights (bot)", false);
    RemoveMultiTargetFilter2("@kbot",           FilterKnightsBots, "Knights (bot)", false);
    RemoveMultiTargetFilter2("@kbots",          FilterKnightsBots, "Knights (bot)", false);

    RemoveMultiTargetFilter2("@ka",             FilterKnightsAlive, "Knights (alive)", false);
    RemoveMultiTargetFilter2("@kal",            FilterKnightsAlive, "Knights (alive)", false);
    RemoveMultiTargetFilter2("@kali",           FilterKnightsAlive, "Knights (alive)", false);
    RemoveMultiTargetFilter2("@kaliv",          FilterKnightsAlive, "Knights (alive)", false);
    RemoveMultiTargetFilter2("@kalive",         FilterKnightsAlive, "Knights (alive)", false);

    RemoveMultiTargetFilter2("@kd",             FilterKnightsDead, "Knights (dead)", false);
    RemoveMultiTargetFilter2("@kde",            FilterKnightsDead, "Knights (dead)", false);
    RemoveMultiTargetFilter2("@kdea",           FilterKnightsDead, "Knights (dead)", false);
    RemoveMultiTargetFilter2("@kdead",          FilterKnightsDead, "Knights (dead)", false);

    RemoveMultiTargetFilter2("@kha",            FilterKnightsHumansAlive, "Knights (human & alive)", false);
    RemoveMultiTargetFilter2("@khal",           FilterKnightsHumansAlive, "Knights (human & alive)", false);
    RemoveMultiTargetFilter2("@khali",          FilterKnightsHumansAlive, "Knights (human & alive)", false);
    RemoveMultiTargetFilter2("@khaliv",         FilterKnightsHumansAlive, "Knights (human & alive)", false);
    RemoveMultiTargetFilter2("@khalive",        FilterKnightsHumansAlive, "Knights (human & alive)", false);

    RemoveMultiTargetFilter2("@khd",            FilterKnightsHumansDead, "Knights (human & dead)", false);
    RemoveMultiTargetFilter2("@khde",           FilterKnightsHumansDead, "Knights (human & dead)", false);
    RemoveMultiTargetFilter2("@khdea",          FilterKnightsHumansDead, "Knights (human & dead)", false);
    RemoveMultiTargetFilter2("@khdead",         FilterKnightsHumansDead, "Knights (human & dead)", false);

    RemoveMultiTargetFilter2("@kba",            FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbal",           FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbali",          FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbaliv",         FilterKnightsBotsAlive, "Knights (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbalive",        FilterKnightsBotsAlive, "Knights (bot & alive)", false);

    RemoveMultiTargetFilter2("@kbd",            FilterKnightsBotsDead, "Knights (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbde",           FilterKnightsBotsDead, "Knights (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdea",          FilterKnightsBotsDead, "Knights (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdead",         FilterKnightsBotsDead, "Knights (bot & dead)", false);

    RemoveMultiTargetFilter2("@r",              FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@rn",             FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@rng",            FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@ra",             FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@ran",            FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@rand",           FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@rando",          FilterAllRandom, "random player", false);
    RemoveMultiTargetFilter2("@random",         FilterAllRandom, "random player", false);

    RemoveMultiTargetFilter2("@sr",             FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@srn",            FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@srng",           FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@sra",            FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@sran",           FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@srand",          FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@srando",         FilterSpectatorsRandom, "random Spectator", false);
    RemoveMultiTargetFilter2("@srandom",        FilterSpectatorsRandom, "random Spectator", false);

    RemoveMultiTargetFilter2("@pr",             FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@prn",            FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@prng",           FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@pra",            FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@pran",           FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@prand",          FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@prando",         FilterPiratesRandom, "random Pirate", false);
    RemoveMultiTargetFilter2("@prandom",        FilterPiratesRandom, "random Pirate", false);

    RemoveMultiTargetFilter2("@vr",             FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vrn",            FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vrng",           FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vra",            FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vran",           FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vrand",          FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vrando",         FilterVikingsRandom, "random Viking", false);
    RemoveMultiTargetFilter2("@vrandom",        FilterVikingsRandom, "random Viking", false);

    RemoveMultiTargetFilter2("@kr",             FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@krn",            FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@krng",           FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@kra",            FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@kran",           FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@krand",          FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@krando",         FilterKnightsRandom, "random Knight", false);
    RemoveMultiTargetFilter2("@krandom",        FilterKnightsRandom, "random Knight", false);

    RemoveMultiTargetFilter2("@phr",            FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phrn",           FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phrng",          FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phra",           FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phran",          FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phrand",         FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phrando",        FilterPiratesHumansRandom, "random Pirate (human)", false);
    RemoveMultiTargetFilter2("@phrandom",       FilterPiratesHumansRandom, "random Pirate (human)", false);

    RemoveMultiTargetFilter2("@pbr",            FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbrn",           FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbrng",          FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbra",           FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbran",          FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbrand",         FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbrando",        FilterPiratesBotsRandom, "random Pirate (bot)", false);
    RemoveMultiTargetFilter2("@pbrandom",       FilterPiratesBotsRandom, "random Pirate (bot)", false);

    RemoveMultiTargetFilter2("@par",            FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@parn",           FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@parng",          FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@para",           FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@paran",          FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@parand",         FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@parando",        FilterPiratesAliveRandom, "random Pirate (alive)", false);
    RemoveMultiTargetFilter2("@parandom",       FilterPiratesAliveRandom, "random Pirate (alive)", false);

    RemoveMultiTargetFilter2("@pdr",            FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdrn",           FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdrng",          FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdra",           FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdran",          FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdrand",         FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdrando",        FilterPiratesDeadRandom, "random Pirate (dead)", false);
    RemoveMultiTargetFilter2("@pdrandom",       FilterPiratesDeadRandom, "random Pirate (dead)", false);

    RemoveMultiTargetFilter2("@phar",           FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@pharn",          FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@pharng",         FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@phara",          FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@pharan",         FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@pharand",        FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@pharando",       FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);
    RemoveMultiTargetFilter2("@pharandom",      FilterPiratesHumansAliveRandom, "random Pirate (human & alive)", false);

    RemoveMultiTargetFilter2("@phdr",           FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdrn",          FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdrng",         FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdra",          FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdran",         FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdrand",        FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdrando",       FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);
    RemoveMultiTargetFilter2("@phdrandom",      FilterPiratesHumansDeadRandom, "random Pirate (human & dead)", false);

    RemoveMultiTargetFilter2("@pbar",           FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbarn",          FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbarng",         FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbara",          FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbaran",         FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbarand",        FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbarando",       FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);
    RemoveMultiTargetFilter2("@pbarandom",      FilterPiratesBotsAliveRandom, "random Pirate (bot & alive)", false);

    RemoveMultiTargetFilter2("@pbdr",           FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdrn",          FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdrng",         FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdra",          FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdran",         FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdrand",        FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdrando",       FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);
    RemoveMultiTargetFilter2("@pbdrandom",      FilterPiratesBotsDeadRandom, "random Pirate (bot & dead)", false);

    RemoveMultiTargetFilter2("@vhr",            FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhrn",           FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhrng",          FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhra",           FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhran",          FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhrand",         FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhrando",        FilterVikingsHumansRandom, "random Viking (human)", false);
    RemoveMultiTargetFilter2("@vhrandom",       FilterVikingsHumansRandom, "random Viking (human)", false);

    RemoveMultiTargetFilter2("@vbr",            FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbrn",           FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbrng",          FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbra",           FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbran",          FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbrand",         FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbrando",        FilterVikingsBotsRandom, "random Viking (bot)", false);
    RemoveMultiTargetFilter2("@vbrandom",       FilterVikingsBotsRandom, "random Viking (bot)", false);

    RemoveMultiTargetFilter2("@var",            FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@varn",           FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@varng",          FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@vara",           FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@varan",          FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@varand",         FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@varando",        FilterVikingsAliveRandom, "random Viking (alive)", false);
    RemoveMultiTargetFilter2("@varandom",       FilterVikingsAliveRandom, "random Viking (alive)", false);

    RemoveMultiTargetFilter2("@vdr",            FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdrn",           FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdrng",          FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdra",           FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdran",          FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdrand",         FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdrando",        FilterVikingsDeadRandom, "random Viking (dead)", false);
    RemoveMultiTargetFilter2("@vdrandom",       FilterVikingsDeadRandom, "random Viking (dead)", false);

    RemoveMultiTargetFilter2("@vhar",           FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vharn",          FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vharng",         FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vhara",          FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vharan",         FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vharand",        FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vharando",       FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);
    RemoveMultiTargetFilter2("@vharandom",      FilterVikingsHumansAliveRandom, "random Viking (human & alive)", false);

    RemoveMultiTargetFilter2("@vhdr",           FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdrn",          FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdrng",         FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdra",          FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdran",         FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdrand",        FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdrando",       FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);
    RemoveMultiTargetFilter2("@vhdrandom",      FilterVikingsHumansDeadRandom, "random Viking (human & dead)", false);

    RemoveMultiTargetFilter2("@vbar",           FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbarn",          FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbarng",         FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbara",          FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbaran",         FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbarand",        FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbarando",       FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);
    RemoveMultiTargetFilter2("@vbarandom",      FilterVikingsBotsAliveRandom, "random Viking (bot & alive)", false);

    RemoveMultiTargetFilter2("@vbdr",           FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdrn",          FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdrng",         FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdra",          FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdran",         FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdrand",        FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdrando",       FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);
    RemoveMultiTargetFilter2("@vbdrandom",      FilterVikingsBotsDeadRandom, "random Viking (bot & dead)", false);

    RemoveMultiTargetFilter2("@khr",            FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khrn",           FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khrng",          FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khra",           FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khran",          FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khrand",         FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khrando",        FilterKnightsHumansRandom, "random Knight (human)", false);
    RemoveMultiTargetFilter2("@khrandom",       FilterKnightsHumansRandom, "random Knight (human)", false);

    RemoveMultiTargetFilter2("@kbr",            FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbrn",           FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbrng",          FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbra",           FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbran",          FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbrand",         FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbrando",        FilterKnightsBotsRandom, "random Knight (bot)", false);
    RemoveMultiTargetFilter2("@kbrandom",       FilterKnightsBotsRandom, "random Knight (bot)", false);

    RemoveMultiTargetFilter2("@kar",            FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@karn",           FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@karng",          FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@kara",           FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@karan",          FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@karand",         FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@karando",        FilterKnightsAliveRandom, "random Knight (alive)", false);
    RemoveMultiTargetFilter2("@karandom",       FilterKnightsAliveRandom, "random Knight (alive)", false);

    RemoveMultiTargetFilter2("@kdr",            FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdrn",           FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdrng",          FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdra",           FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdran",          FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdrand",         FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdrando",        FilterKnightsDeadRandom, "random Knight (dead)", false);
    RemoveMultiTargetFilter2("@kdrandom",       FilterKnightsDeadRandom, "random Knight (dead)", false);

    RemoveMultiTargetFilter2("@khar",           FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@kharn",          FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@kharng",         FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@khara",          FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@kharan",         FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@kharand",        FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@kharando",       FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);
    RemoveMultiTargetFilter2("@kharandom",      FilterKnightsHumansAliveRandom, "random Knight (human & alive)", false);

    RemoveMultiTargetFilter2("@khdr",           FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdrn",          FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdrng",         FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdra",          FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdran",         FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdrand",        FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdrando",       FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);
    RemoveMultiTargetFilter2("@khdrandom",      FilterKnightsHumansDeadRandom, "random Knight (human & dead)", false);

    RemoveMultiTargetFilter2("@kbar",           FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbarn",          FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbarng",         FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbara",          FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbaran",         FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbarand",        FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbarando",       FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);
    RemoveMultiTargetFilter2("@kbarandom",      FilterKnightsBotsAliveRandom, "random Knight (bot & alive)", false);

    RemoveMultiTargetFilter2("@kbdr",           FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdrn",          FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdrng",         FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdra",          FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdran",         FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdrand",        FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdrando",       FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
    RemoveMultiTargetFilter2("@kbdrandom",      FilterKnightsBotsDeadRandom, "random Knight (bot & dead)", false);
}

/****************************************************************************************************/

void RemoveMultiTargetFilter2(const char[] pattern, MultiTargetFilter filter, const char[] phrase, bool phraseIsML)
{
    AddMultiTargetFilter("", filter, phrase, phraseIsML); // Just to remove the compiler warning
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

bool FilterAllRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterSpectatorsRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Spectators, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesHumansRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesBotsRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesHumansAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesHumansDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesBotsAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterPiratesBotsDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Pirates, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsHumansRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsBotsRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsHumansAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsHumansDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsBotsAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterVikingsBotsDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Dead, ClientTeam_Vikings, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsHumansRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsBotsRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsHumansAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Alive, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsHumansDeadRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, ClientState_Dead, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsBotsAliveRandom(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, ClientState_Alive, ClientTeam_Knights, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterKnightsBotsDeadRandom(const char[] pattern, ArrayList clients)
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

    if (g_bCvar_Debug)
        DebugArray(clients);

    return true;
}

/****************************************************************************************************/

void DebugArray(ArrayList clients)
{
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

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (pvk2_moretargetfilters) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pvk2_moretargetfilters_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "pvk2_moretargetfilters_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "pvk2_moretargetfilters_debug : %b (%s)", g_bCvar_Debug, g_bCvar_Debug ? "true" : "false");
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

