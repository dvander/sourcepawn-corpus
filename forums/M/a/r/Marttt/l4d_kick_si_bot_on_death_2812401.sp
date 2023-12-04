/**
// ====================================================================================================
Change Log:

1.0.1 (03-November-2023)
    - Public release.

1.0.0 (03-October-2023)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Kick Special Infected Bots After Death"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Automatically kicks special infected bots right after death"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=344407"

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
#define CONFIG_FILENAME               "l4d_kick_si_bot_on_death"

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
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define L4D2_FLAG_ZOMBIECLASS_NONE    0
#define L4D2_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D2_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D2_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D2_FLAG_ZOMBIECLASS_SPITTER 8
#define L4D2_FLAG_ZOMBIECLASS_JOCKEY  16
#define L4D2_FLAG_ZOMBIECLASS_CHARGER 32
#define L4D2_FLAG_ZOMBIECLASS_TANK    64

#define L4D1_FLAG_ZOMBIECLASS_NONE    0
#define L4D1_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D1_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D1_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D1_FLAG_ZOMBIECLASS_TANK    8

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_kick_si_bot_on_death_version;
    ConVar l4d_kick_si_bot_on_death_enable;
    ConVar l4d_kick_si_bot_on_death_si;
    ConVar l4d_kick_si_bot_on_death_tank_incapacitated;

    void Init()
    {
        this.l4d_kick_si_bot_on_death_version = CreateConVar("l4d_kick_si_bot_on_death_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_kick_si_bot_on_death_enable  = CreateConVar("l4d_kick_si_bot_on_death_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_kick_si_bot_on_death_tank_incapacitated = CreateConVar("l4d_kick_si_bot_on_death_tank_incapacitated", "1", "Kicks the Tank bot when it becomes incapacitated.\n0 = Disable, 1 = Enable.\nNote: must have TANK flag enabled on \"l4d_kick_si_bot_on_death_si\".", CVAR_FLAGS, true, 0.0, true, 1.0);

        if (plugin.isLeft4Dead2)
            this.l4d_kick_si_bot_on_death_si  = CreateConVar("l4d_kick_si_bot_on_death_si", "127", "Which special infected should be kicked right after being killed.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", enables for all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);
        else
            this.l4d_kick_si_bot_on_death_si  = CreateConVar("l4d_kick_si_bot_on_death_si", "15", "Which special infected should be kicked right after being killed.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", enables for all SI.", CVAR_FLAGS, true, 0.0, true, 15.0);

        this.l4d_kick_si_bot_on_death_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d_kick_si_bot_on_death_tank_incapacitated.AddChangeHook(Event_ConVarChanged);
        this.l4d_kick_si_bot_on_death_si.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool isLeft4Dead2;
    int tankZombieClass;
    int tankZombieClassFlag;
    bool eventsHooked;
    bool enabled;
    bool tank_incapacitated;
    int si;
    bool siCheck;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.l4d_kick_si_bot_on_death_enable.BoolValue;
        this.tank_incapacitated = this.cvars.l4d_kick_si_bot_on_death_tank_incapacitated.BoolValue;
        this.si = this.cvars.l4d_kick_si_bot_on_death_si.IntValue;

        if (this.isLeft4Dead2)
            this.siCheck = (this.si != L4D2_FLAG_ZOMBIECLASS_SMOKER|L4D2_FLAG_ZOMBIECLASS_BOOMER|L4D2_FLAG_ZOMBIECLASS_HUNTER|L4D2_FLAG_ZOMBIECLASS_SPITTER|L4D2_FLAG_ZOMBIECLASS_JOCKEY|L4D2_FLAG_ZOMBIECLASS_CHARGER|L4D2_FLAG_ZOMBIECLASS_TANK);
        else
            this.siCheck = (this.si != L4D1_FLAG_ZOMBIECLASS_SMOKER|L4D1_FLAG_ZOMBIECLASS_BOOMER|L4D1_FLAG_ZOMBIECLASS_HUNTER|L4D1_FLAG_ZOMBIECLASS_TANK);
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d_kick_si_bot_on_death", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
    }

    void HookEvents()
    {
        if (this.enabled && !this.eventsHooked)
        {
            this.eventsHooked = true;

            HookEvent("player_death", Event_PlayerDeath);
            HookEvent("player_incapacitated", Event_PlayerIncapacitated);

            return;
        }

        if (!this.enabled && this.eventsHooked)
        {
            this.eventsHooked = false;

            UnhookEvent("player_death", Event_PlayerDeath);
            UnhookEvent("player_incapacitated", Event_PlayerIncapacitated);

            return;
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
    plugin.tankZombieClass = (plugin.isLeft4Dead2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);
    plugin.tankZombieClassFlag = (plugin.isLeft4Dead2 ? L4D2_FLAG_ZOMBIECLASS_TANK : L4D1_FLAG_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
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
    plugin.HookEvents();
}

/****************************************************************************************************/

public void Event_PlayerDeath(Event event, char[] error, bool dontBroadcast)
{
    if (plugin.si == 0)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    if (!IsFakeClient(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    if (plugin.siCheck && !(GetZombieClassFlag(client) & plugin.si))
        return;

    KickClient(client);
}

/****************************************************************************************************/

public void Event_PlayerIncapacitated(Event event, char[] error, bool dontBroadcast)
{
    if (!plugin.tank_incapacitated)
        return;

    if (plugin.si == 0)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    if (!IsFakeClient(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    if (plugin.siCheck && !(plugin.tankZombieClassFlag & plugin.si))
        return;

    if (GetZombieClass(client) != plugin.tankZombieClass)
        return;

    SetEntProp(client, Prop_Data, "m_iHealth", 0);

    RequestFrame(Frame_TankBurning, GetClientUserId(client)); // WORKAROUND: When the Tank dies burning by "inferno" entities (e.g: Molotov), kick will only work in the next frame
}

/****************************************************************************************************/

void Frame_TankBurning(int userid)
{
    int client = GetClientOfUserId(userid);

    if (client == 0)
        return;

    SetEntProp(client, Prop_Data, "m_iHealth", 0);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_kick_si_bot_on_death) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_kick_si_bot_on_death_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_kick_si_bot_on_death_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "l4d_kick_si_bot_on_death_tank_incapacitated : %b (%s)", plugin.tank_incapacitated, plugin.tank_incapacitated ? "true" : "false");
    if (plugin.isLeft4Dead2)
    {
        PrintToConsole(client, "l4d_kick_si_bot_on_death_si : %i (CHECK = %s) (SMOKER = %s | BOOMER = %s | HUNTER = %s | SPITTER = %s | JOCKEY = %s | CHARGER = %s | TANK = %s)", plugin.si, plugin.siCheck ? "true" : "false",
        plugin.si & L4D2_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_SPITTER ? "true" : "false",
        plugin.si & L4D2_FLAG_ZOMBIECLASS_JOCKEY ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_CHARGER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    else
    {
        PrintToConsole(client, "l4d_kick_si_bot_on_death_si : %i (CHECK = %s) (SMOKER = %s | BOOMER = %s | HUNTER = %s | TANK = %s)", plugin.si, plugin.siCheck ? "true" : "false",
        plugin.si & L4D1_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", plugin.si & L4D1_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", plugin.si & L4D1_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", plugin.si & L4D1_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

/****************************************************************************************************/

// ====================================================================================================
// Helpers
// ====================================================================================================
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

/****************************************************************************************************/

/**
 * Returns the zombie class flag from a zombie class.
 *
 * @param client        Client index.
 * @return              Client zombie class flag.
 */
int GetZombieClassFlag(int client)
{
    int zombieClass = GetZombieClass(client);

    if (plugin.isLeft4Dead2)
    {
        switch (zombieClass)
        {
            case L4D2_ZOMBIECLASS_SMOKER:
                return L4D2_FLAG_ZOMBIECLASS_SMOKER;
            case L4D2_ZOMBIECLASS_BOOMER:
                return L4D2_FLAG_ZOMBIECLASS_BOOMER;
            case L4D2_ZOMBIECLASS_HUNTER:
                return L4D2_FLAG_ZOMBIECLASS_HUNTER;
            case L4D2_ZOMBIECLASS_SPITTER:
                return L4D2_FLAG_ZOMBIECLASS_SPITTER;
            case L4D2_ZOMBIECLASS_JOCKEY:
                return L4D2_FLAG_ZOMBIECLASS_JOCKEY;
            case L4D2_ZOMBIECLASS_CHARGER:
                return L4D2_FLAG_ZOMBIECLASS_CHARGER;
            case L4D2_ZOMBIECLASS_TANK:
                return L4D2_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D2_FLAG_ZOMBIECLASS_NONE;
        }
    }
    else
    {
        switch (zombieClass)
        {
            case L4D1_ZOMBIECLASS_SMOKER:
                return L4D1_FLAG_ZOMBIECLASS_SMOKER;
            case L4D1_ZOMBIECLASS_BOOMER:
                return L4D1_FLAG_ZOMBIECLASS_BOOMER;
            case L4D1_ZOMBIECLASS_HUNTER:
                return L4D1_FLAG_ZOMBIECLASS_HUNTER;
            case L4D1_ZOMBIECLASS_TANK:
                return L4D1_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D1_FLAG_ZOMBIECLASS_NONE;
        }
    }
}