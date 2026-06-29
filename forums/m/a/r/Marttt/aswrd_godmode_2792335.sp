/**
// ====================================================================================================
Change Log:

1.0.0 (07-November-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ASWRD] Godmode"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Turns marines into immortals/mortals"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=340274"

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
#define CONFIG_FILENAME               "aswrd_godmode"

// ====================================================================================================
// Defines
// ====================================================================================================
#define PROFILE_UNKNOWN               -1
#define PROFILE_SARGE                 0
#define PROFILE_WILDCAT               1
#define PROFILE_FAITH                 2
#define PROFILE_CRASH                 3
#define PROFILE_JAEGER                4
#define PROFILE_WOLFE                 5
#define PROFILE_BASTILLE              6
#define PROFILE_VEGAS                 7

#define MAXPROFILES                   8

#define MAXENTITIES                   2048

// ====================================================================================================
// Profile Names
// ====================================================================================================
char g_profileName[MAXPROFILES][MAX_TARGET_LENGTH] =
{
    "Sarge",
    "Wildcat",
    "Faith",
    "Crash",
    "Jaeger",
    "Wolfe",
    "Bastille",
    "Vegas"
};

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bOnTakeDamageHooked[MAXENTITIES+1];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bGod[MAXPLAYERS+1];

// ====================================================================================================
// profile - Plugin Variables
// ====================================================================================================
bool gp_bGod[MAXPROFILES];

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar aswrd_godmode_version;
    ConVar aswrd_godmode_enable;
    ConVar aswrd_godmode_default_mode;
    ConVar aswrd_godmode_bots;

    void Init()
    {
        this.aswrd_godmode_version      = CreateConVar("aswrd_godmode_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.aswrd_godmode_enable       = CreateConVar("aswrd_godmode_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_godmode_default_mode = CreateConVar("aswrd_godmode_default_mode", "1", "Default godmode for everyone.\n0 = Starts mortal, 1 = Starts immortal.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_godmode_bots         = CreateConVar("aswrd_godmode_bots", "1", "Allow bots to have godmode.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.aswrd_godmode_enable.AddChangeHook(Event_ConVarChanged);
        this.aswrd_godmode_default_mode.AddChangeHook(Event_ConVarChanged);
        this.aswrd_godmode_bots.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool eventsHooked;
    bool enabled;
    bool default_mode;
    bool bots;

    void Init()
    {
        this.LoadTranslations();
        this.cvars.Init();
        this.RegisterCommands();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.aswrd_godmode_enable.BoolValue;
        this.default_mode = this.cvars.aswrd_godmode_default_mode.BoolValue;
        this.bots = this.cvars.aswrd_godmode_bots.BoolValue;
    }

    void LoadTranslations()
    {
        LoadTranslations("common.phrases");
    }

    void RegisterCommands()
    {
        RegAdminCmd("sm_print_cvars_aswrd_godmode", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
        RegAdminCmd("sm_god", Cmd_God, ADMFLAG_ROOT, "sm_god <#userid|name> - Enables godmode (becomes immortal) on the target(s), or in yourself if no target is mentioned.");
        RegAdminCmd("sm_mortal", Cmd_Mortal, ADMFLAG_ROOT, "sm_mortal <#userid|name> - Disables godmode (becomes mortal) on the target(s), or in yourself if no target is mentioned.");
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_AlienSwarm)
    {
        strcopy(error, err_max, "This plugin only runs in \"Alien Swarm: Reactive Drop\" game");
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
    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();

    HookEvents();

    LateLoad();
}


/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void HookEvents()
{
    if (plugin.enabled && !plugin.eventsHooked)
    {
        plugin.eventsHooked = true;

        HookEvent("marine_infested", Event_MarineInfested);

        return;
    }

    if (!plugin.enabled && plugin.eventsHooked)
    {
        plugin.eventsHooked = false;

        UnhookEvent("marine_infested", Event_MarineInfested);

        return;
    }
}

/****************************************************************************************************/

void Event_MarineInfested(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("entindex");

    if (!IsGodModeOn(entity))
        return;

    SetEntPropFloat(entity, Prop_Send, "m_fInfestedStartTime", 0.0);
    SetEntPropFloat(entity, Prop_Send, "m_fInfestedTime", 0.0);

    int resource = GetMarineResource(entity);

    if (resource != -1)
        SetEntProp(resource, Prop_Send, "m_bInfested", 0);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int i = 0; i < MAXPROFILES; i++)
    {
        gp_bGod[i] = plugin.default_mode;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "asw_marine")) != INVALID_ENT_REFERENCE)
    {
        HookEntity(entity);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    gc_bGod[client] = plugin.default_mode;
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bGod[client] = false;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (StrEqual(classname, "asw_marine"))
        HookEntity(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bOnTakeDamageHooked[entity] = false;
}

/****************************************************************************************************/

void HookEntity(int entity)
{
    if (ge_bOnTakeDamageHooked[entity])
        return;

    ge_bOnTakeDamageHooked[entity] = true;
    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

/****************************************************************************************************/

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!plugin.enabled)
        return Plugin_Continue;

    if (!IsGodModeOn(victim))
        return Plugin_Continue;

    damage = 0.0;
    return Plugin_Changed;
}

/****************************************************************************************************/

bool IsGodModeOn(int marine)
{
    int resource = GetMarineResource(marine);

    if (resource == -1)
        return false;

    if (IsMarineResourceBot(resource))
    {
        if (!plugin.bots)
           return false;

        int profile = GetEntProp(resource, Prop_Data, "m_MarineProfileIndex");

        if (profile == PROFILE_UNKNOWN)
            return false;

        if (!gp_bGod[profile])
            return false;
    }
    else
    {
        int client = GetEntPropEnt(marine, Prop_Send, "m_Commander");

        if (!gc_bGod[client])
            return false;
    }

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
    PrintToConsole(client, "----------------- Plugin Cvars (aswrd_godmode) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "aswrd_godmode_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "aswrd_godmode_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "aswrd_godmode_default_mode : %b (%s)", plugin.default_mode, plugin.default_mode ? "true" : "false");
    PrintToConsole(client, "aswrd_godmode_bots : %b (%s)", plugin.bots, plugin.bots ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action Cmd_God(int client, int args)
{
    SetGod(client, args, true);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action Cmd_Mortal(int client, int args)
{
    SetGod(client, args, false);

    return Plugin_Handled;
}

/****************************************************************************************************/

void SetGod(int client, int args, bool enable)
{
    if (!plugin.enabled)
        return;

    int target_count;
    int target_list[MAXPLAYERS];

    if (args == 0) // self
    {
        if (IsValidClient(client))
        {
            target_count = 1;
            target_list[0] = client;
        }
    }
    else
    {
        char arg1[MAX_TARGET_LENGTH];
        GetCmdArg(1, arg1, sizeof(arg1));

        char target_name[MAX_TARGET_LENGTH];
        bool tn_is_ml;

        if ((target_count = ProcessTargetString(
            arg1,
            client,
            target_list,
            MAXPLAYERS,
            0,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            // If no target is found, try searching by profile name
            int profile = GetProfileByName(arg1);
            if (profile != PROFILE_UNKNOWN)
            {
                gp_bGod[profile] = enable;
                strcopy(target_name, sizeof(target_name), g_profileName[profile]);

                if (enable)
                {
                    LogAction(client, -1, "%L enabled godmode on %s<BOT>", client, target_name);
                    ShowActivity2(client, "", "\x01%N \x04enabled \x03godmode on \x01%s", client, target_name);
                }
                else
                {
                    LogAction(client, -1, "%L disabled godmode on %s<BOT>", client, target_name);
                    ShowActivity2(client, "", "\x01%N \x07disabled \x03godmode on \x01%s", client, target_name);
                }
            }
            else
            {
                ReplyToTargetError(client, target_count);
            }
        }
    }

    int target;
    for (int i = 0; i < target_count; i++)
    {
        target = target_list[i];
        gc_bGod[target] = enable;

        if (enable)
        {
            LogAction(client, target, "%L disabled godmode on %L", client, target);
            ShowActivity2(client, "", "\x01%N \x04enabled \x03godmode on \x01%N", client, target);
        }
        else
        {
            LogAction(client, target, "%L enabled godmode on %L", client, target);
            ShowActivity2(client, "", "\x01%N \x07disabled \x03godmode on \x01%N", client, target);
        }
    }
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
 * Returns the marine resource entity related to a marine entity.
 *
 * @param marine          Marine entity index.
 * @return                Marine resource entity index, -1 is not found.
 */
int GetMarineResource(int marine)
{
    int resource;

    resource = INVALID_ENT_REFERENCE;
    while ((resource = FindEntityByClassname(resource, "asw_marine_resource")) != INVALID_ENT_REFERENCE)
    {
        if (GetEntPropEnt(resource, Prop_Send, "m_MarineEntity") == marine)
            return resource;
    }

    return -1;
}

/****************************************************************************************************/

/**
 * Returns the if the marine resource is a bot.
 *
 * @param resource        Marine resource entity index.
 * @return                True if is a bot, false otherwise. (based on m_bInhabited)
 */
bool IsMarineResourceBot(int resource)
{
    return (GetEntProp(resource, Prop_Data, "m_bInhabited") == 0);
}

/****************************************************************************************************/

/**
 * Returns the profile index based on a given profile name.
 *
 * @param profileName     Profile name.
 * @return                Profile index. -1=Unknown, 0=Sarge, 1=Wildcat, 2=Faith, 3=Crash, 4=Jaeger, 5=Wolfer, 6=Bastille, 7=Vegas.
 */
int GetProfileByName(char[] profileName)
{
    if (StrEqual(profileName, "Sarge", false)) return PROFILE_SARGE;
    if (StrEqual(profileName, "Wildcat", false)) return PROFILE_WILDCAT;
    if (StrEqual(profileName, "Faith", false)) return PROFILE_FAITH;
    if (StrEqual(profileName, "Crash", false)) return PROFILE_CRASH;
    if (StrEqual(profileName, "Jaeger", false)) return PROFILE_JAEGER;
    if (StrEqual(profileName, "Wolfe", false)) return PROFILE_WOLFE;
    if (StrEqual(profileName, "Bastille", false)) return PROFILE_BASTILLE;
    if (StrEqual(profileName, "Vegas", false)) return PROFILE_VEGAS;

    return PROFILE_UNKNOWN;
}