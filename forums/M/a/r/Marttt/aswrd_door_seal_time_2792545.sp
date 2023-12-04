/**
// ====================================================================================================
Change Log:

1.0.0 (10-November-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ASWRD] Door Seal Time Duration"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Manage the duration to seal doors"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=340328"

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
#define CONFIG_FILENAME               "aswrd_door_seal_time"

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bDoorFound[MAXPLAYERS+1];
float gc_fSealDuration[MAXPLAYERS+1];

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar aswrd_door_seal_time_version;
    ConVar aswrd_door_seal_time_enable;
    ConVar aswrd_door_seal_time_duration;

    void Init()
    {
        this.aswrd_door_seal_time_version  = CreateConVar("aswrd_door_seal_time_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.aswrd_door_seal_time_enable   = CreateConVar("aswrd_door_seal_time_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.aswrd_door_seal_time_duration = CreateConVar("aswrd_door_seal_time_duration", "10.0", "Time it takes to seal a door.", CVAR_FLAGS, true, 0.1);

        this.aswrd_door_seal_time_enable.AddChangeHook(Event_ConVarChanged);
        this.aswrd_door_seal_time_duration.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool enabled;
    float duration;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.aswrd_door_seal_time_enable.BoolValue;
        this.duration = this.cvars.aswrd_door_seal_time_duration.FloatValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_aswrd_door_seal_time", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
        RegAdminCmd("sm_sealtime", Cmd_SealTime, ADMFLAG_ROOT, "Set the seal time from the door at crosshair. Usage: sm_sealtime <value>.");
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

    LateLoad();
}


/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "asw_door")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bDoorFound[client] = false;
    gc_fSealDuration[client] = 0.0;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (StrEqual(classname, "asw_door"))
    {
        RequestFrame(Frame_Spawn, EntIndexToEntRef(entity));
        return;
    }
}

/****************************************************************************************************/

void Frame_Spawn(int entityRef)
{
    if (!plugin.enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    SetTotalSealTime(entity, plugin.duration);
}

/****************************************************************************************************/

void SetTotalSealTime(int entity, float duration)
{
    SetEntPropFloat(entity, Prop_Data, "m_flTotalSealTime", duration); // Warning: 0.0 makes the seal never end
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (aswrd_door_seal_time) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "aswrd_door_seal_time_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "aswrd_door_seal_time_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "aswrd_door_seal_time_duration : %.1f", plugin.duration);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action Cmd_SealTime(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args == 0)
        return Plugin_Handled;

    float duration = GetCmdArgFloat(1);

    if (duration <= 0.0)
        return Plugin_Handled;

    float vCrosshairPos[3];
    GetEntPropVector(client, Prop_Data, "m_vecCrosshairTracePos", vCrosshairPos);

    gc_fSealDuration[client] = duration;
    gc_bDoorFound[client] = false;

    TR_EnumerateEntitiesPoint(vCrosshairPos, MASK_SOLID, TraceDoors, client);

    if (!gc_bDoorFound[client])
        PrintToChat(client, "\x07Unable to find a door at crosshair");

    return Plugin_Handled;
}

/****************************************************************************************************/

bool TraceDoors(int entity, int client)
{
    if (entity < 0)
        return false;

    if (!IsValidEntity(entity))
        return false;

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (!StrEqual(classname, "asw_door"))
        return false;

    float oldDuration = GetEntPropFloat(entity, Prop_Data, "m_flTotalSealTime");
    float newDuration = gc_fSealDuration[client];

    SetTotalSealTime(entity, newDuration);
    PrintToChat(client, "\x06%i (%s)\x03 changed \x05\"m_flTotalSealTime\"\x03 from \x07%.2f\x03 to \x04%.2f", entity, classname, oldDuration, newDuration);

    gc_bDoorFound[client] = true;

    return true;
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