/**
// ====================================================================================================
Change Log:

1.0.0 (24-April-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[PVK2] Killable Vultures"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Makes vultures (npc_vulture) killables"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=337501"

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
#define CONFIG_FILENAME               "pvk2_killable_vultures"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MAXENTITIES                   2048

#define SPAWNFLAG_CAN_TAKE_DAMAGE     65536

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Debug;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
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
    CreateConVar("pvk2_killable_vultures_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("pvk2_killable_vultures_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Debug   = CreateConVar("pvk2_killable_vultures_debug", "0", "Output to chat info about the vulture spawnflags.\n0 = Debug OFF, 1 = Debug ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Debug.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_slayvultures", CmdSlayVultures, ADMFLAG_ROOT, "Slay all vultures.");
    RegAdminCmd("sm_print_cvars_pvk2_killable_vultures", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Debug = g_hCvar_Debug.BoolValue;
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "npc_vulture")) != INVALID_ENT_REFERENCE)
    {
        if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05spawnflags: \x04%i\x03]", "LateLoad", entity, GetEntProp(entity, Prop_Data, "m_spawnflags"));

        RequestFrame(Frame_LateLoad, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

void Frame_LateLoad(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05spawnflags: \x04%i\x03]", "Frame_LateLoad", entity, GetEntProp(entity, Prop_Data, "m_spawnflags"));

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (classname[0] != 'n')
        return;

    if (!StrEqual(classname, "npc_vulture"))
        return;

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05spawnflags: \x04%i\x03]", "OnEntityCreated", entity, GetEntProp(entity, Prop_Data, "m_spawnflags"));

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05spawnflags: \x04%i\x03]", "OnSpawnPost", entity, GetEntProp(entity, Prop_Data, "m_spawnflags"));

    if (!g_bCvar_Enabled)
        return;

    int spawnflags = GetEntProp(entity, Prop_Data, "m_spawnflags");
    spawnflags |= SPAWNFLAG_CAN_TAKE_DAMAGE;

    SetEntProp(entity, Prop_Data, "m_spawnflags", spawnflags);

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05spawnflags: \x04%i\x03]", "OnSpawnPost (Fix)", entity, GetEntProp(entity, Prop_Data, "m_spawnflags"));
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdSlayVultures(int client, int args)
{
    int entity;
    int count;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "npc_vulture")) != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(entity, "BecomeRagdoll");
        count++;
    }

    if (IsValidClient(client))
    {
        if (count > 0)
            ReplyToCommand(client, "\x03[\x05Slayed \x04%i \x05vulture%s\x03]", count, count > 1 ? "s" : "" );
        else
            ReplyToCommand(client, "\x03[\x05No vultures found\x03]");
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (pvk2_killable_vultures) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pvk2_killable_vultures_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "pvk2_killable_vultures_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "pvk2_killable_vultures_debug : %b (%s)", g_bCvar_Debug, g_bCvar_Debug ? "true" : "false");
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