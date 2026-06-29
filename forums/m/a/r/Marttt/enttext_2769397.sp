/**
// ====================================================================================================
Change Log:

1.0.3 (28-August-2022)
    - Added better Alien Swarm support.

1.0.2 (21-April-2022)
    - Fixed new entities tracker for entities created in the same frame with the same index.

1.0.1 (14-March-2022)
    - Added command to enable/disable tracking on new entities created.

1.0.0 (25-January-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ANY] ent_text - More Commands (Listen Server Only)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Apply ent_text with range parameter and add a listener to auto track new entities"
#define PLUGIN_VERSION                "1.0.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=336072"

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
#define CONFIG_FILENAME               "enttext"

// ====================================================================================================
// Game Cvars
// ====================================================================================================
ConVar g_hCvar_sv_cheats;
ConVar g_hCvar_developer;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Range;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bAlienSwarm;
bool g_bConfigsExecuted;
bool g_bListening;
bool g_bCvar_sv_cheats;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_developer;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_Range;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alPluginEntities;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    g_alPluginEntities = new ArrayList();

    EngineVersion engine = GetEngineVersion();
    g_bAlienSwarm = (engine == Engine_AlienSwarm);

    g_hCvar_sv_cheats = FindConVar("sv_cheats");
    g_hCvar_developer = FindConVar("developer");

    CreateConVar("enttext_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("enttext_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Range   = CreateConVar("enttext_range", "300.0", "Default range for \"sm_enttext\" command.", CVAR_FLAGS, true, 0.0);

    // Hook plugin ConVars change
    g_hCvar_sv_cheats.AddChangeHook(Event_ConVarChanged);
    g_hCvar_developer.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Range.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_enttext", CmdEntText, ADMFLAG_ROOT, "Applies ent_text command to entities in this range. Usage: sm_enttext [range].");
    RegAdminCmd("sm_enttextclear", CmdEntTextClear, ADMFLAG_ROOT, "Removes ent_text from entities set by the plugin.");
    RegAdminCmd("sm_enttextlisten", CmdEntTextListen, ADMFLAG_ROOT, "Start tracking all new entities created and auto apply the ent_text command.");
    RegAdminCmd("sm_enttextstart", CmdEntTextListen, ADMFLAG_ROOT, "Start tracking all new entities created and auto apply the ent_text command.");
    RegAdminCmd("sm_enttextstop", CmdEntTextStop, ADMFLAG_ROOT, "Stop tracking all new entities created.");
    RegAdminCmd("sm_print_cvars_enttext", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    RemoveAll();

    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    if (g_bConfigsExecuted)
        return;

    g_bConfigsExecuted = true;

    GetCvars();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_sv_cheats = g_hCvar_sv_cheats.BoolValue;
    g_iCvar_developer = g_hCvar_developer.IntValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_Range = g_hCvar_Range.FloatValue;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bListening)
        return;

    if (entity < 0)
        return;

    int find = g_alPluginEntities.FindValue(entity);
    if (find != -1)
        return;

    g_alPluginEntities.Push(entity);

    CallEntText(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    int find = g_alPluginEntities.FindValue(entity);
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

void SetDeveloperMode()
{
    if (g_iCvar_developer < 1)
    {
        g_iCvar_developer = 1;
        g_hCvar_developer.IntValue = 1;
    }
}

/****************************************************************************************************/

Action CmdEntText(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!g_bCvar_sv_cheats)
    {
        ReplyToCommand(client, "Can't use cheat command ent_text, unless the server has sv_cheats set to 1.");
        return Plugin_Handled;
    }

    RemoveAll();

    SetDeveloperMode();

    float range = g_fCvar_Range;

    if (args > 0)
    {
        char sArg[10];
        GetCmdArg(1, sArg, sizeof(sArg));

        if (StrEqual(sArg, "clear", false))
        {
            CmdEntTextClear(client, args);
            return Plugin_Handled;
        }

        if (StrEqual(sArg, "listen", false))
        {
            CmdEntTextListen(client, args);
            return Plugin_Handled;
        }

        if (StrEqual(sArg, "start", false))
        {
            CmdEntTextListen(client, args);
            return Plugin_Handled;
        }

        if (StrEqual(sArg, "stop", false))
        {
            CmdEntTextStop(client, args);
            return Plugin_Handled;
        }

        range = StringToFloat(sArg);

        if (range < 0.0)
            return Plugin_Handled;
    }

    float vClientPos[3];
    if (IsValidClient(client))
    {
        if (g_bAlienSwarm)
        {
            GetEntPropVector(client, Prop_Data, "m_vecLastMarineOrigin", vClientPos);
        }
        else
        {
            GetClientAbsOrigin(client, vClientPos);
        }
    }

    float vPos[3];
    float distance;

    int entity;
    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        if (entity < 0)
            continue;

        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
        distance = GetVectorDistance(vClientPos, vPos);

        if (distance > range)
            continue;

        g_alPluginEntities.Push(entity);
    }

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = g_alPluginEntities.Get(i);

        CallEntText(entity);
    }

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x01Found \x03%i \x05entities \x01in \x03%.1f\x04 \x05range\x04]", g_alPluginEntities.Length, range);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdEntTextClear(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!g_bCvar_sv_cheats)
    {
        ReplyToCommand(client, "Can't use cheat command ent_text, unless the server has sv_cheats set to 1.");
        return Plugin_Handled;
    }

    RemoveAll();

    SetDeveloperMode();

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x01Removed all \x03ent_text \x01from entities set by the plugin\x04]");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdEntTextListen(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!g_bCvar_sv_cheats)
    {
        ReplyToCommand(client, "Can't use cheat command ent_text, unless the server has sv_cheats set to 1.");
        return Plugin_Handled;
    }

    SetDeveloperMode();

    g_bListening = true;

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x01Tracking new entities created \x03ON\x04]");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdEntTextStop(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!g_bCvar_sv_cheats)
    {
        ReplyToCommand(client, "Can't use cheat command ent_text, unless the server has sv_cheats set to 1.");
        return Plugin_Handled;
    }

    SetDeveloperMode();

    g_bListening = false;

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x01Tracking new entities created \x05OFF\x04]");

    return Plugin_Handled;
}

/****************************************************************************************************/

void CallEntText(int entity)
{
    if (entity == 0)
        ServerCommand("ent_text worldspawn");
    else
        ServerCommand("ent_text %i", entity);
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    RemoveAll();
}

/****************************************************************************************************/

void RemoveAll()
{
    if (g_alPluginEntities.Length > 0)
    {
        int entity;

        ArrayList g_alPluginEntitiesClone = g_alPluginEntities.Clone();

        for (int i = 0; i < g_alPluginEntitiesClone.Length; i++)
        {
            entity = g_alPluginEntitiesClone.Get(i);

            CallEntText(entity);
        }

        delete g_alPluginEntitiesClone;

        g_alPluginEntities.Clear();
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
    PrintToConsole(client, "----------------------- Plugin Cvars (enttext) -----------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "enttext_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "enttext_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "enttext_range : %.1f", g_fCvar_Range);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "sv_cheats : %b (%s)", g_bCvar_sv_cheats, g_bCvar_sv_cheats ? "true" : "false");
    PrintToConsole(client, "developer : %i", g_iCvar_developer);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "IsDedicatedServer : %b (%s)", IsDedicatedServer(), IsDedicatedServer() ? "true" : "false");
    PrintToConsole(client, "Listening? : %s", g_bListening ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------- Array List -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "g_alPluginEntities count : %i", g_alPluginEntities.Length);
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