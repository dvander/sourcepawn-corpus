/**
// ====================================================================================================
Change Log:

1.0.1 (15-July-2021)
    - Added Traditional Chinese (zho) translations. (thanks to "yabi")

1.0.0 (13-July-2024)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Dead Center Mall - Alarm Announce"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Outputs to the chat who triggered/deactivated the alarm at Dead Center Mall (c1m3_mall)"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=348587"

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
#define CONFIG_FILENAME              "l4d_c1m3_alarm_announce"
#define TRANSLATION_FILENAME         "l4d_c1m3_alarm_announce.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define MESSAGE_ALARM_ON_GLASS_BREAK  0
#define MESSAGE_ALARM_ON_DOOR_OPEN    1
#define MESSAGE_ALARM_OFF             2

#define DOOR_LOCKED                   1

#define MAXENTITIES                   2048

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_c1m3_alarm_announce_version;
    ConVar l4d_c1m3_alarm_announce_enable;
    ConVar l4d_c1m3_alarm_announce_glass_break;
    ConVar l4d_c1m3_alarm_announce_door_open;
    ConVar l4d_c1m3_alarm_announce_deactivation;
    ConVar l4d_c1m3_alarm_announce_team_read;
    ConVar l4d_c1m3_alarm_announce_team_trigger;

    void Init()
    {
        this.l4d_c1m3_alarm_announce_version      = CreateConVar("l4d_c1m3_alarm_announce_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_c1m3_alarm_announce_enable       = CreateConVar("l4d_c1m3_alarm_announce_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_c1m3_alarm_announce_glass_break  = CreateConVar("l4d_c1m3_alarm_announce_glass_break", "1", "Announce when the alarm glass breaks.\n0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_c1m3_alarm_announce_door_open    = CreateConVar("l4d_c1m3_alarm_announce_door_open", "1", "Announce when the alarm door opens.\n0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_c1m3_alarm_announce_deactivation = CreateConVar("l4d_c1m3_alarm_announce_deactivation", "1", "Announce when the alarm is deactivated.\n0 = No, 1 = Yes.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d_c1m3_alarm_announce_team_read    = CreateConVar("l4d_c1m3_alarm_announce_team_read", "7", "Which teams should read the message.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
        this.l4d_c1m3_alarm_announce_team_trigger = CreateConVar("l4d_c1m3_alarm_announce_team_trigger", "3", "Which teams should trigger the message.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);

        this.l4d_c1m3_alarm_announce_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d_c1m3_alarm_announce_glass_break.AddChangeHook(Event_ConVarChanged);
        this.l4d_c1m3_alarm_announce_door_open.AddChangeHook(Event_ConVarChanged);
        this.l4d_c1m3_alarm_announce_deactivation.AddChangeHook(Event_ConVarChanged);
        this.l4d_c1m3_alarm_announce_team_read.AddChangeHook(Event_ConVarChanged);
        this.l4d_c1m3_alarm_announce_team_trigger.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool hooked[MAXENTITIES+1];

    bool isMap_c1m3_mall;
    bool enable;
    bool announceGlassBreak;
    bool announceDoorOpen;
    bool announceDeactivation;
    int teamRead;
    int teamTrigger;

    void Init()
    {
        this.LoadPluginTranslations();
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d_c1m3_alarm_announce_enable.BoolValue;
        this.announceGlassBreak = this.cvars.l4d_c1m3_alarm_announce_glass_break.BoolValue;
        this.announceDoorOpen = this.cvars.l4d_c1m3_alarm_announce_door_open.BoolValue;
        this.announceDeactivation = this.cvars.l4d_c1m3_alarm_announce_deactivation.BoolValue;
        this.teamRead = this.cvars.l4d_c1m3_alarm_announce_team_read.IntValue;
        this.teamTrigger = this.cvars.l4d_c1m3_alarm_announce_team_trigger.IntValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d_c1m3_alarm_announce", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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

    void HookEntityOnBreak(int entity)
    {
        if (this.hooked[entity])
            return;

        if (!this.enable)
            return;

        if (!this.announceGlassBreak)
            return;

        this.hooked[entity] = true;
        HookSingleEntityOutput(entity, "OnBreak", OnBreak, true);
    }

    void HookEntityOnOpen(int entity)
    {
        if (this.hooked[entity])
            return;

        if (!this.enable)
            return;

        if (!this.announceDoorOpen)
            return;

        this.hooked[entity] = true;
        SDKHook(entity, SDKHook_UsePost, PropFuncRotating_OnUsePost); // WORKAROUND: OnOpen output returns the door entity itself as the activator (Valve bug)
    }

    void HookEntityOnPressed(int entity)
    {
        if (this.hooked[entity])
            return;

        if (!this.enable)
            return;

        if (!this.announceDeactivation)
            return;

        this.hooked[entity] = true;
        HookSingleEntityOutput(entity, "OnPressed", OnPressed, true);
    }

    void UnhookEntityOnBreak(int entity)
    {
        if (!this.hooked[entity])
            return;

        this.hooked[entity] = false;
        UnhookSingleEntityOutput(entity, "OnBreak", OnBreak);
    }

    void UnhookEntityOnOpen(int entity)
    {
        if (!this.hooked[entity])
            return;

        this.hooked[entity] = false;
        SDKUnhook(entity, SDKHook_UsePost, PropFuncRotating_OnUsePost);
    }

    void UnhookEntityOnPressed(int entity)
    {
        if (!this.hooked[entity])
            return;

        this.hooked[entity] = false;
        UnhookSingleEntityOutput(entity, "OnPressed", OnPressed);
    }

    void UnhookAllEntitiesOnBreak()
    {
        int entity;
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "func_breakable")) != INVALID_ENT_REFERENCE)
        {
            this.UnhookEntityOnBreak(entity);
        }
    }

    void UnhookAllEntitiesOnOpen()
    {
        int entity;
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE)
        {
            this.UnhookEntityOnOpen(entity);
        }
    }

    void UnhookAllEntitiesOnPressed()
    {
        int entity;
        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "func_button")) != INVALID_ENT_REFERENCE)
        {
            this.UnhookEntityOnPressed(entity);
        }
    }

    void LateLoad()
    {
        if (!this.isMap_c1m3_mall)
            return;

        int entity;

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "func_breakable")) != INVALID_ENT_REFERENCE)
        {
            char targetname[64];
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "breakble_glass_minifinale"))
            {
                this.UnhookEntityOnBreak(entity);
                this.HookEntityOnBreak(entity);
            }
        }

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE)
        {
            char targetname[64];
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if (StrEqual(targetname, "door_hallway_lower4") || StrEqual(targetname, "door_hallway_lower4a"))
            {
                this.UnhookEntityOnOpen(entity);
                this.HookEntityOnOpen(entity);
            }
        }

        entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "func_button")) != INVALID_ENT_REFERENCE)
        {
            char glow[64];
            GetEntPropString(entity, Prop_Data, "m_sGlowEntity", glow, sizeof(glow));

            if (StrEqual(glow, "prop_alarm_controls"))
            {
                this.UnhookEntityOnPressed(entity);
                this.HookEntityOnPressed(entity);
            }
        }
    }

    void OutputMessage(int client, int message)
    {
        for (int target = 1; target <= MaxClients; target++)
        {
            if (!this.IsValidPrintTarget(target))
                continue;

            switch (message)
            {
                case MESSAGE_ALARM_ON_GLASS_BREAK:
                    CPrintToChat(target, "%t", "c1m3_mall_alarm_on_glass_break", client);
                case MESSAGE_ALARM_ON_DOOR_OPEN:
                    CPrintToChat(target, "%t", "c1m3_mall_alarm_on_door_open", client);
                case MESSAGE_ALARM_OFF:
                    CPrintToChat(target, "%t", "c1m3_mall_alarm_on_deactivation", client);
            }
        }
    }

    bool IsValidPrintTarget(int target)
    {
        if (!IsClientInGame(target))
            return false;

        if (IsFakeClient(target))
            return false;

        if (!(GetTeamFlag(GetClientTeam(target)) & plugin.teamRead))
            return false;

        return true;
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
    plugin.isMap_c1m3_mall = (StrEqual(mapName, "c1m3_mall", false));
}

/****************************************************************************************************/

public void OnMapEnd()
{
    plugin.isMap_c1m3_mall = false;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
    plugin.LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!plugin.isMap_c1m3_mall)
        return;

    if (!plugin.enable)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "func_breakable"))
    {
        if (!plugin.announceGlassBreak)
            return;

        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostFuncBreakable); // targetname only available on SpawnPost
        return;
    }

    if (StrEqual(classname, "prop_door_rotating"))
    {
        if (!plugin.announceDoorOpen)
            return;

        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostPropDoorRotating); // targetname only available on SpawnPost
        return;
    }

    if (StrEqual(classname, "func_button"))
    {
        if (!plugin.announceDeactivation)
            return;

        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostFuncButton); // glow only available on SpawnPost
        return;
    }
}

/****************************************************************************************************/

void OnSpawnPostFuncBreakable(int entity)
{
    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "breakble_glass_minifinale"))
        plugin.HookEntityOnBreak(entity);
}

/****************************************************************************************************/

void OnSpawnPostPropDoorRotating(int entity)
{
    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "door_hallway_lower4") || StrEqual(targetname, "door_hallway_lower4a"))
        plugin.HookEntityOnOpen(entity);
}

/****************************************************************************************************/

void OnSpawnPostFuncButton(int entity)
{
    char glow[64];
    GetEntPropString(entity, Prop_Data, "m_sGlowEntity", glow, sizeof(glow));

    if (StrEqual(glow, "prop_alarm_controls"))
        plugin.HookEntityOnPressed(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!plugin.isMap_c1m3_mall)
        return;

    if (!plugin.enable)
        return;

    if (entity < 0)
        return;

    plugin.hooked[entity] = false;
}

/****************************************************************************************************/

void OnBreak(const char[] output, int caller, int activator, float delay)
{
    plugin.UnhookEntityOnBreak(caller);
    plugin.UnhookAllEntitiesOnBreak();
    plugin.UnhookAllEntitiesOnOpen();

    if (!IsValidClient(activator))
        return;

    if (!(GetTeamFlag(GetClientTeam(activator)) & plugin.teamTrigger))
        return;

    plugin.OutputMessage(activator, MESSAGE_ALARM_ON_GLASS_BREAK);
}


/****************************************************************************************************/

void PropFuncRotating_OnUsePost(int entity, int activator, int caller, UseType type, float value)
{
    if (GetEntProp(entity, Prop_Send, "m_bLocked") == DOOR_LOCKED)
        return;

    plugin.UnhookEntityOnOpen(caller);
    plugin.UnhookAllEntitiesOnOpen();
    plugin.UnhookAllEntitiesOnBreak();

    if (!IsValidClient(activator))
        return;

    if (!(GetTeamFlag(GetClientTeam(activator)) & plugin.teamTrigger))
        return;

    plugin.OutputMessage(activator, MESSAGE_ALARM_ON_DOOR_OPEN);
}

/****************************************************************************************************/

void OnPressed(const char[] output, int caller, int activator, float delay)
{
    plugin.UnhookEntityOnPressed(caller);
    plugin.UnhookAllEntitiesOnPressed();
    plugin.UnhookAllEntitiesOnBreak();
    plugin.UnhookAllEntitiesOnOpen();

    if (!IsValidClient(activator))
        return;

    if (!(GetTeamFlag(GetClientTeam(activator)) & plugin.teamTrigger))
        return;

    plugin.OutputMessage(activator, MESSAGE_ALARM_OFF);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_c1m3_alarm_announce) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_c1m3_alarm_announce_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_c1m3_alarm_announce_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d_c1m3_alarm_announce_glass_break : %b (%s)", plugin.announceGlassBreak, plugin.announceGlassBreak ? "true" : "false");
    PrintToConsole(client, "l4d_c1m3_alarm_announce_door_open : %b (%s)", plugin.announceDoorOpen, plugin.announceDoorOpen ? "true" : "false");
    PrintToConsole(client, "l4d_c1m3_alarm_announce_deactivation : %b (%s)", plugin.announceDeactivation, plugin.announceDeactivation ? "true" : "false");
    PrintToConsole(client, "l4d_c1m3_alarm_announce_team_read : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", plugin.teamRead,
    plugin.teamRead & FLAG_TEAM_SPECTATOR ? "true" : "false", plugin.teamRead & FLAG_TEAM_SURVIVOR ? "true" : "false", plugin.teamRead & FLAG_TEAM_INFECTED ? "true" : "false", plugin.teamRead & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d_c1m3_alarm_announce_team_trigger : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", plugin.teamTrigger,
    plugin.teamTrigger & FLAG_TEAM_SPECTATOR ? "true" : "false", plugin.teamTrigger & FLAG_TEAM_SURVIVOR ? "true" : "false", plugin.teamTrigger & FLAG_TEAM_INFECTED ? "true" : "false", plugin.teamTrigger & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------------------- Hooked Entities ---------------------------");
    PrintToConsole(client, "");
    int count;
    for (int entity = 0; entity <= MAXENTITIES; entity++)
    {
        if (!plugin.hooked[entity])
            continue;

        PrintToConsole(client, "[%i] entity: %i", ++count, entity);
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
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
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