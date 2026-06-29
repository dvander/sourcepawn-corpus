/**
// ====================================================================================================
Change Log:

1.0.0 (01-February-2024)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ND] More Target Filters"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds more target filters ready to use"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=345869"

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
#define CONFIG_FILENAME               "nd_more_target_filters"

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
    ClientTeam_Consortium = 2,
    ClientTeam_Empire = 3
}

/****************************************************************************************************/

enum PickRandom
{
    PickRandom_No,
    PickRandom_Yes
}

/****************************************************************************************************/

enum ClientMainClass
{
    ClientMainClass_None = -1,
    ClientMainClass_Assault = 0,
    ClientMainClass_Exo = 1,
    ClientMainClass_Stealth = 2,
    ClientMainClass_Support = 3
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
    ConVar nd_more_target_filters_version;
    ConVar nd_more_target_filters_enable;
    ConVar nd_more_target_filters_debug;

    void Init()
    {
        this.nd_more_target_filters_version = CreateConVar("nd_more_target_filters_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.nd_more_target_filters_enable  = CreateConVar("nd_more_target_filters_enable", "1", "enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.nd_more_target_filters_debug   = CreateConVar("nd_more_target_filters_debug", "0", "Output to chat info about clients found by the target filter.\n0 = Debug OFF, 1 = Debug ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.nd_more_target_filters_enable.AddChangeHook(Event_ConVarChanged);
        this.nd_more_target_filters_debug.AddChangeHook(Event_ConVarChanged);

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
        this.enable = this.cvars.nd_more_target_filters_enable.BoolValue;
        this.debug = this.cvars.nd_more_target_filters_debug.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_nd_more_target_filters", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
        PrintToChatAll("\x01[\x05clients found: \x04%i\x01]", clients.Length);
        for (int i = 0; i < clients.Length; i++)
        {
            int client = clients.Get(i);
            PrintToChatAll("\x01[\x05client: \x04%i \x01| \x05Name: \x04%N \x01| \x05State: \x04%s \x01| \x05Team: \x04%s \x01| \x05Main Class: \x04%s\x01]",
            client,
            client,
            IsPlayerAlive(client) ? "Alive" : "Dead",
            GetClientTeamEnum(client) == ClientTeam_Spectators ? "Spectators" : GetClientTeamEnum(client) == ClientTeam_Consortium ? "Consortium" : GetClientTeamEnum(client) == ClientTeam_Empire ? "Empire" : "Unknown",
            GetClientMainClassEnum(client) == ClientMainClass_Assault ? "Assault" : GetClientMainClassEnum(client) == ClientMainClass_Exo ? "Exo" : GetClientMainClassEnum(client) == ClientMainClass_Stealth ? "Stealth" : GetClientMainClassEnum(client) == ClientMainClass_Support ? "Support" : "Unknown");
        }
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_NuclearDawn)
    {
        strcopy(error, err_max, "This plugin only runs in \"Nuclear Dawn\" game");
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
    MultiTargetFilter(add, "@a",           FilterAll, "all players", true);
    // MultiTargetFilter(add, "@all",         FilterAll, "all players", true); // SM already has it by default

    MultiTargetFilter(add, "@h",           FilterHumans, "all humans", true);
    MultiTargetFilter(add, "@human",       FilterHumans, "all humans", true);
    // MultiTargetFilter(add, "@humans",      FilterHumans, "all humans", true); // SM already has it by default

    MultiTargetFilter(add, "@b",           FilterBots, "all bots", true);
    MultiTargetFilter(add, "@bot",         FilterBots, "all bots", true);
    // MultiTargetFilter(add, "@bots",        FilterBots, "all bots", true); // SM already has it by default

    // MultiTargetFilter(add, "@a",           FilterAlive, "all alive players", true); // Conflicts with @all
    MultiTargetFilter(add, "@aliv",        FilterAlive, "all alive players", true);
    // MultiTargetFilter(add, "@alive",       FilterAlive, "all alive players", true); // SM already has it by default

    MultiTargetFilter(add, "@d",           FilterDead, "all dead players", true);
    // MultiTargetFilter(add, "@dead",        FilterDead, "all dead players", true); // SM already has it by default

    MultiTargetFilter(add, "@s",           FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@spec",        FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@specs",       FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@spectator",   FilterSpectators, "all spectators", true);
    MultiTargetFilter(add, "@spectators",  FilterSpectators, "all spectators", true);

    MultiTargetFilter(add, "@c",           FilterConsortium, "Consortium", false);
    MultiTargetFilter(add, "@consort",     FilterConsortium, "Consortium", false);
    MultiTargetFilter(add, "@consorts",    FilterConsortium, "Consortium", false);
    MultiTargetFilter(add, "@consortium",  FilterConsortium, "Consortium", false);
    MultiTargetFilter(add, "@consortiums", FilterConsortium, "Consortium", false);

    MultiTargetFilter(add, "@e",           FilterEmpire, "Empire", false);
    MultiTargetFilter(add, "@empire",      FilterEmpire, "Empire", false);
    MultiTargetFilter(add, "@empires",     FilterEmpire, "Empire", false);

    MultiTargetFilter(add, "@ch",          FilterConsortiumHumans, "Consortium (humans)", false);
    MultiTargetFilter(add, "@chumans",     FilterConsortiumHumans, "Consortium (humans)", false);

    MultiTargetFilter(add, "@cb",          FilterConsortiumBots, "Consortium (bots)", false);
    MultiTargetFilter(add, "@cbots",       FilterConsortiumBots, "Consortium (bots)", false);

    MultiTargetFilter(add, "@ca",          FilterConsortiumAlive, "Consortium (alive)", false);
    MultiTargetFilter(add, "@calive",      FilterConsortiumAlive, "Consortium (alive)", false);

    MultiTargetFilter(add, "@cd",          FilterConsortiumDead, "Consortium (dead)", false);
    MultiTargetFilter(add, "@cdead",       FilterConsortiumDead, "Consortium (dead)", false);

    MultiTargetFilter(add, "@eh",          FilterEmpireHumans, "Empire (humans)", false);
    MultiTargetFilter(add, "@ehumans",     FilterEmpireHumans, "Empire (humans)", false);

    MultiTargetFilter(add, "@eb",          FilterEmpireBots, "Empire (bots)", false);
    MultiTargetFilter(add, "@ebots",       FilterEmpireBots, "Empire (bots)", false);

    MultiTargetFilter(add, "@ea",          FilterEmpireAlive, "Empire (alive)", false);
    MultiTargetFilter(add, "@ealive",      FilterEmpireAlive, "Empire (alive)", false);

    MultiTargetFilter(add, "@ed",          FilterEmpireDead, "Empire (dead)", false);
    MultiTargetFilter(add, "@edead",       FilterEmpireDead, "Empire (dead)", false);

    MultiTargetFilter(add, "@assault",     FilterAssault, "Assault main class", false);
    MultiTargetFilter(add, "@exo",         FilterExo, "Exo main class", false);
    MultiTargetFilter(add, "@stealth",     FilterStealth, "Stealth main class", false);
    MultiTargetFilter(add, "@support",     FilterSupport, "Support main class", false);

    MultiTargetFilter(add, "@hassault",    FilterAssaultHumans, "Assault main class (humans)", false);
    MultiTargetFilter(add, "@hexo",        FilterExoHumans, "Exo main class (humans)", false);
    MultiTargetFilter(add, "@hstealth",    FilterStealthHumans, "Stealth main class (humans)", false);
    MultiTargetFilter(add, "@hsupport",    FilterSupportHumans, "Support main class (humans)", false);

    MultiTargetFilter(add, "@bassault",    FilterAssaultBots, "Assault main class (bots)", false);
    MultiTargetFilter(add, "@bexo",        FilterExoBots, "Exo main class (bots)", false);
    MultiTargetFilter(add, "@bstealth",    FilterStealthBots, "Stealth main class (bots)", false);
    MultiTargetFilter(add, "@bsupport",    FilterSupportBots, "Support main class (bots)", false);

    MultiTargetFilter(add, "@aassault",    FilterAssaultAlive, "Assault main class (alive)", false);
    MultiTargetFilter(add, "@aexo",        FilterExoAlive, "Exo main class (alive)", false);
    MultiTargetFilter(add, "@astealth",    FilterStealthAlive, "Stealth main class (alive)", false);
    MultiTargetFilter(add, "@asupport",    FilterSupportAlive, "Support main class (alive)", false);

    MultiTargetFilter(add, "@dassault",    FilterAssaultDead, "Assault main class (dead)", false);
    MultiTargetFilter(add, "@dexo",        FilterExoDead, "Exo main class (dead)", false);
    MultiTargetFilter(add, "@dstealth",    FilterStealthDead, "Stealth main class (dead)", false);
    MultiTargetFilter(add, "@dsupport",    FilterSupportDead, "Support main class (dead)", false);

    MultiTargetFilter(add, "@cassault",    FilterConsortiumAssault, "Consortium Assault main class", false);
    MultiTargetFilter(add, "@cexo",        FilterConsortiumExo, "Consortium Exo main class", false);
    MultiTargetFilter(add, "@cstealth",    FilterConsortiumStealth, "Consortium Stealth main class", false);
    MultiTargetFilter(add, "@csupport",    FilterConsortiumSupport, "Consortium Support main class", false);

    MultiTargetFilter(add, "@eassault",    FilterEmpireAssault, "Empire Assault main class", false);
    MultiTargetFilter(add, "@eexo",        FilterEmpireExo, "Empire Exo main class", false);
    MultiTargetFilter(add, "@estealth",    FilterEmpireStealth, "Empire Stealth main class", false);
    MultiTargetFilter(add, "@esupport",    FilterEmpireSupport, "Empire Support main class", false);

    MultiTargetFilter(add, "@chassault",   FilterConsortiumAssaultHumans, "Consortium (humans) Assault main class", false);
    MultiTargetFilter(add, "@chexo",       FilterConsortiumExoHumans, "Consortium (humans) Exo main class", false);
    MultiTargetFilter(add, "@chstealth",   FilterConsortiumStealthHumans, "Consortium (humans) Stealth main class", false);
    MultiTargetFilter(add, "@chsupport",   FilterConsortiumSupportHumans, "Consortium (humans) Support main class", false);

    MultiTargetFilter(add, "@cbassault",   FilterConsortiumAssaultBots, "Consortium (bots) Assault main class", false);
    MultiTargetFilter(add, "@cbexo",       FilterConsortiumExoBots, "Consortium Exo (bots) main class", false);
    MultiTargetFilter(add, "@cbstealth",   FilterConsortiumStealthBots, "Consortium (bots) Stealth main class", false);
    MultiTargetFilter(add, "@cbsupport",   FilterConsortiumSupportBots, "Consortium (bots) Support main class", false);

    MultiTargetFilter(add, "@caassault",   FilterConsortiumAssaultAlive, "Consortium (alive) Assault main class", false);
    MultiTargetFilter(add, "@caexo",       FilterConsortiumExoAlive, "Consortium (alive) Exo main class", false);
    MultiTargetFilter(add, "@castealth",   FilterConsortiumStealthAlive, "Consortium (alive) Stealth main class", false);
    MultiTargetFilter(add, "@casupport",   FilterConsortiumSupportAlive, "Consortium (alive) Support main class", false);

    MultiTargetFilter(add, "@cdassault",   FilterConsortiumAssaultDead, "Consortium (dead) Assault main class", false);
    MultiTargetFilter(add, "@cdexo",       FilterConsortiumExoDead, "Consortium (dead) Exo main class", false);
    MultiTargetFilter(add, "@cdstealth",   FilterConsortiumStealthDead, "Consortium (dead) Stealth main class", false);
    MultiTargetFilter(add, "@cdsupport",   FilterConsortiumSupportDead, "Consortium (dead) Support main class", false);

    MultiTargetFilter(add, "@ehassault",   FilterEmpireAssaultHumans, "Empire (humans) Assault main class", false);
    MultiTargetFilter(add, "@ehexo",       FilterEmpireExoHumans, "Empire (humans) Exo main class", false);
    MultiTargetFilter(add, "@ehstealth",   FilterEmpireStealthHumans, "Empire (humans) Stealth main class", false);
    MultiTargetFilter(add, "@ehsupport",   FilterEmpireSupportHumans, "Empire (humans) Support main class", false);

    MultiTargetFilter(add, "@ebassault",   FilterEmpireAssaultBots, "Empire (bots) Assault main class", false);
    MultiTargetFilter(add, "@ebexo",       FilterEmpireExoBots, "Empire (bots) Exo main class", false);
    MultiTargetFilter(add, "@ebstealth",   FilterEmpireStealthBots, "Empire (bots) Stealth main class", false);
    MultiTargetFilter(add, "@ebsupport",   FilterEmpireSupportBots, "Empire (bots) Support main class", false);

    MultiTargetFilter(add, "@eaassault",   FilterEmpireAssaultAlive, "Empire (alive) Assault main class", false);
    MultiTargetFilter(add, "@eaexo",       FilterEmpireExoAlive, "Empire (alive) Exo main class", false);
    MultiTargetFilter(add, "@eastealth",   FilterEmpireStealthAlive, "Empire (alive) Stealth main class", false);
    MultiTargetFilter(add, "@easupport",   FilterEmpireSupportAlive, "Empire (alive) Support main class", false);

    MultiTargetFilter(add, "@edassault",   FilterEmpireAssaultDead, "Empire (dead) Assault main class", false);
    MultiTargetFilter(add, "@edexo",       FilterEmpireExoDead, "Empire (dead) Exo main class", false);
    MultiTargetFilter(add, "@edstealth",   FilterEmpireStealthDead, "Empire (dead) Stealth main class", false);
    MultiTargetFilter(add, "@edsupport",   FilterEmpireSupportDead, "Empire (dead) Support main class", false);

    MultiTargetFilter(add, "@r",           FilterRandomAll, "random player", false);
    MultiTargetFilter(add, "@random",      FilterRandomAll, "random player", false);

    MultiTargetFilter(add, "@rh",          FilterRandomHumans, "random player (humans)", false);
    MultiTargetFilter(add, "@rhumans",     FilterRandomHumans, "random player (humans)", false);

    MultiTargetFilter(add, "@rb",          FilterRandomBots, "random player (bots)", false);
    MultiTargetFilter(add, "@rbots",       FilterRandomBots, "random player (bots)", false);

    MultiTargetFilter(add, "@ra",          FilterRandomAlive, "random player (alive)", false);
    MultiTargetFilter(add, "@ralive",      FilterRandomAlive, "random player (alive)", false);

    MultiTargetFilter(add, "@rd",          FilterRandomDead, "random player (dead)", false);
    MultiTargetFilter(add, "@rdead",       FilterRandomDead, "random player (dead)", false);

    MultiTargetFilter(add, "@rs",          FilterRandomSpectators, "random Spectator", false);
    MultiTargetFilter(add, "@rspectator",  FilterRandomSpectators, "random Spectator", false);

    MultiTargetFilter(add, "@rc",          FilterRandomConsortium, "random Consortium", false);
    MultiTargetFilter(add, "@rconsortium", FilterRandomConsortium, "random Consortium", false);

    MultiTargetFilter(add, "@re",          FilterRandomEmpire, "random Empire", false);
    MultiTargetFilter(add, "@rempire",     FilterRandomEmpire, "random Empire", false);

    MultiTargetFilter(add, "@rca",         FilterRandomConsortiumAlive, "random Consortium (alive)", false);
    MultiTargetFilter(add, "@rcalive",     FilterRandomConsortiumAlive, "random Consortium (alive)", false);

    MultiTargetFilter(add, "@rcd",         FilterRandomConsortiumDead, "random Consortium (dead)", false);
    MultiTargetFilter(add, "@rcdead",      FilterRandomConsortiumDead, "random Consortium (dead)", false);

    MultiTargetFilter(add, "@rea",         FilterRandomEmpireAlive, "random Empire (alive)", false);
    MultiTargetFilter(add, "@realive",     FilterRandomEmpireAlive, "random Empire (alive)", false);

    MultiTargetFilter(add, "@red",         FilterRandomEmpireDead, "random Empire (dead)", false);
    MultiTargetFilter(add, "@redead",      FilterRandomEmpireDead, "random Empire (dead)", false);

    MultiTargetFilter(add, "@rassault",    FilterRandomAssault, "random Assault main class", false);
    MultiTargetFilter(add, "@rexo",        FilterRandomExo, "random Exo main class", false);
    MultiTargetFilter(add, "@rstealth",    FilterRandomStealth, "random Stealth main class", false);
    MultiTargetFilter(add, "@rsupport",    FilterRandomSupport, "random Support main class", false);

    MultiTargetFilter(add, "@rcassault",   FilterRandomConsortiumAssault, "random Consortium Assault main class", false);
    MultiTargetFilter(add, "@rcexo",       FilterRandomConsortiumExo, "random Consortium Exo main class", false);
    MultiTargetFilter(add, "@rcstealth",   FilterRandomConsortiumStealth, "random Consortium Stealth main class", false);
    MultiTargetFilter(add, "@rcsupport",   FilterRandomConsortiumSupport, "random Consortium Support main class", false);

    MultiTargetFilter(add, "@reassault",   FilterRandomEmpireAssault, "random Empire Assault main class", false);
    MultiTargetFilter(add, "@reexo",       FilterRandomEmpireExo, "random Empire Exo main class", false);
    MultiTargetFilter(add, "@restealth",   FilterRandomEmpireStealth, "random Empire Stealth main class", false);
    MultiTargetFilter(add, "@resupport",   FilterRandomEmpireSupport, "random Empire Support main class", false);
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

bool FilterConsortium(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium);
}

/****************************************************************************************************/

bool FilterEmpire(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire);
}

/****************************************************************************************************/

bool FilterConsortiumHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Consortium);
}

/****************************************************************************************************/

bool FilterConsortiumBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Consortium);
}

/****************************************************************************************************/

bool FilterConsortiumAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Consortium);
}

/****************************************************************************************************/

bool FilterConsortiumDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Consortium);
}

/****************************************************************************************************/

bool FilterEmpireHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Empire);
}

/****************************************************************************************************/

bool FilterEmpireBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Empire);
}

/****************************************************************************************************/

bool FilterEmpireAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Empire);
}

/****************************************************************************************************/

bool FilterEmpireDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Empire);
}

/****************************************************************************************************/

bool FilterAssault(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterExo(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterStealth(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterSupport(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterAssaultHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, _, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterExoHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, _, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterStealthHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, _, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterSupportHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, _, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterAssaultBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, _, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterExoBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, _, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterStealthBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, _, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterSupportBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, _, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterAssaultAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, _, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterExoAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, _, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterStealthAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, _, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterSupportAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, _, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterAssaultDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, _, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterExoDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, _, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterStealthDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, _, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterSupportDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, _, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterConsortiumAssault(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterConsortiumExo(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterConsortiumStealth(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterConsortiumSupport(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterEmpireAssault(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterEmpireExo(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterEmpireStealth(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterEmpireSupport(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterConsortiumAssaultHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Consortium, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterConsortiumExoHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Consortium, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterConsortiumStealthHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Consortium, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterConsortiumSupportHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Consortium, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterConsortiumAssaultBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Consortium, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterConsortiumExoBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Consortium, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterConsortiumStealthBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Consortium, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterConsortiumSupportBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Consortium, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterConsortiumAssaultAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Consortium, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterConsortiumExoAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Consortium, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterConsortiumStealthAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Consortium, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterConsortiumSupportAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Consortium, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterConsortiumAssaultDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Consortium, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterConsortiumExoDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Consortium, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterConsortiumStealthDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Consortium, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterConsortiumSupportDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Consortium, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterEmpireAssaultHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Empire, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterEmpireExoHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Empire, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterEmpireStealthHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Empire, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterEmpireSupportHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, ClientTeam_Empire, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterEmpireAssaultBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Empire, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterEmpireExoBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Empire, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterEmpireStealthBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Empire, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterEmpireSupportBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, ClientTeam_Empire, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterEmpireAssaultAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Empire, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterEmpireExoAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Empire, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterEmpireStealthAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Empire, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterEmpireSupportAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Empire, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterEmpireAssaultDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Empire, ClientMainClass_Assault);
}

/****************************************************************************************************/

bool FilterEmpireExoDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Empire, ClientMainClass_Exo);
}

/****************************************************************************************************/

bool FilterEmpireStealthDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Empire, ClientMainClass_Stealth);
}

/****************************************************************************************************/

bool FilterEmpireSupportDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Empire, ClientMainClass_Support);
}

/****************************************************************************************************/

bool FilterRandomAll(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomHumans(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Human, _, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomBots(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, ClientType_Bot, _, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, _, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomSpectators(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Spectators, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortium(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpire(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortiumAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Consortium, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortiumDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Consortium, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpireAlive(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Alive, ClientTeam_Empire, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpireDead(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, ClientState_Dead, ClientTeam_Empire, _, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomAssault(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Assault, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomExo(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Exo, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomStealth(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Stealth, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomSupport(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, _, ClientMainClass_Support, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortiumAssault(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Assault, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortiumExo(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Exo, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortiumStealth(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Stealth, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomConsortiumSupport(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Consortium, ClientMainClass_Support, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpireAssault(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Assault, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpireExo(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Exo, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpireStealth(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Stealth, PickRandom_Yes);
}

/****************************************************************************************************/

bool FilterRandomEmpireSupport(const char[] pattern, ArrayList clients)
{
    return TargetFilter(clients, _, _, ClientTeam_Empire, ClientMainClass_Support, PickRandom_Yes);
}

/****************************************************************************************************/

bool TargetFilter(ArrayList clients, ClientType type = ClientType_All, ClientState state = ClientState_All, ClientTeam team = ClientTeam_All, ClientMainClass mainClass = ClientMainClass_None, PickRandom random = PickRandom_No)
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
            case ClientTeam_Consortium: if (GetClientTeamEnum(client) != ClientTeam_Consortium) continue;
            case ClientTeam_Empire: if (GetClientTeamEnum(client) != ClientTeam_Empire) continue;
        }

        switch (mainClass)
        {
            case ClientMainClass_Assault: if(GetClientMainClassEnum(client) != ClientMainClass_Assault) continue;
            case ClientMainClass_Exo: if(GetClientMainClassEnum(client) != ClientMainClass_Exo) continue;
            case ClientMainClass_Stealth: if(GetClientMainClassEnum(client) != ClientMainClass_Stealth) continue;
            case ClientMainClass_Support: if(GetClientMainClassEnum(client) != ClientMainClass_Support) continue;
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
    PrintToConsole(client, "--------------- Plugin Cvars (nd_more_target_filters) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "nd_more_target_filters_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "nd_more_target_filters_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "nd_more_target_filters_debug : %b (%s)", plugin.debug, plugin.debug ? "true" : "false");
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
 * @caram client        Client index.
 * @return              1=SPECTATORS, 2=CONSORTIUM, 3=EMPIRE
 */
ClientTeam GetClientTeamEnum(int client)
{
    return view_as<ClientTeam>(GetClientTeam(client));
}

/**
 * Returns the ClientMainClass enum.
 *
 * @caram client        Client index.
 * @return              0=ASSAULT, 1=EXO, 2=STEALTH, 3=SUPPORT
 */
ClientMainClass GetClientMainClassEnum(int client)
{
    return view_as<ClientMainClass>(GetEntProp(client, Prop_Send, "m_iPlayerClass"));
}