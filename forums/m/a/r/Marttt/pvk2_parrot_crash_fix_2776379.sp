/**
// ====================================================================================================
Change Log:

1.0.0 (10-April-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[PVK2] Parrot Crash Fix"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Fixes a server crash when a npc_parrot/npc_vulture entity is created without an owner and kills someone"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=337252"

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
#define CONFIG_FILENAME               "pvk2_parrot_crash_fix"

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
    CreateConVar("pvk2_parrot_crash_fix_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("pvk2_parrot_crash_fix_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Debug   = CreateConVar("pvk2_parrot_crash_fix_debug", "0", "Output to chat info about the parrot/vulture owner.\n0 = Debug OFF, 1 = Debug ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Debug.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_setparrotowner", CmdSetParrotOwner, ADMFLAG_ROOT, "Set the parrot owner. Usage: sm_setparrotowner <parrot> <owner>.");
    RegAdminCmd("sm_setvultureowner", CmdSetVultureOwner, ADMFLAG_ROOT, "Set the vulture owner. Usage: sm_setvultureowner <vulture> <owner>.");
    RegAdminCmd("sm_print_cvars_pvk2_parrot_crash_fix", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    while ((entity = FindEntityByClassname(entity, "npc_parrot")) != INVALID_ENT_REFERENCE)
    {
        if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "LateLoad", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

        RequestFrame(Frame_LateLoad, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "npc_vulture")) != INVALID_ENT_REFERENCE)
    {
        if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "LateLoad", entity, "npc_vulture", GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

        RequestFrame(Frame_LateLoad, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

void Frame_LateLoad(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "Frame_LateLoad", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (classname[0] != 'n')
        return;

    if (!StrEqual(classname, "npc_parrot") && !StrEqual(classname, "npc_vulture"))
        return;

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "OnEntityCreated", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "OnSpawnPost", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    RequestFrame(Frame_OnSpawnPost, EntIndexToEntRef(entity)); // Wait until the next frame to get the updated value from m_hOwnerEntity
}

/****************************************************************************************************/

void Frame_OnSpawnPost(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "Frame_OnSpawnPost", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    if (!g_bCvar_Enabled)
        return;

    if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1)
        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", 0);

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "Frame_OnSpawnPost (Fix)", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdSetParrotOwner(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args < 2)
    {
        ReplyToCommand(client, "\x03[\x01Usage: \x03!setparrotowner \x05<\x04parrot\x05> \x05<\x04owner\x05>\x03]");
        return Plugin_Handled;
    }

    char arg1[5];
    GetCmdArg(1, arg1, sizeof(arg1));
    int entity = StringToInt(arg1);

    char arg2[5];
    GetCmdArg(2, arg2, sizeof(arg2));
    int owner = StringToInt(arg2);

    if (!IsValidEntity(entity))
    {
        ReplyToCommand(client, "\x03[\x01Invalid \x03parrot\x05. \x05(invalid entity)\x03]");
        return Plugin_Handled;
    }

    if (owner != 0 && !IsValidClient(owner))
    {
        ReplyToCommand(client, "\x03[\x01Invalid \x03owner\x01.\x03]");
        return Plugin_Handled;
    }

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (!StrEqual(classname, "npc_parrot"))
    {
        ReplyToCommand(client, "\x03[\x01Invalid \x03parrot\x01. \x05(not a \"npc_parrot\" classname entity)\x03]");
        return Plugin_Handled;
    }

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "!setparrotowner (before)", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", owner);

    if (owner == 0)
        ReplyToCommand(client, "\x03[\x05Set parrot \x04%i \x05with owner \x04%i (%s)\x03]", entity, owner, "worldspawn");
    else
        ReplyToCommand(client, "\x03[\x05Set parrot \x04%i \x05with owner \x04%i (%N)\x03]", entity, owner, owner);

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "!setparrotowner (after)", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdSetVultureOwner(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args < 2)
    {
        ReplyToCommand(client, "\x03[\x01Usage: \x03!setvultureowner \x05<\x04vulture\x05> \x05<\x04owner\x05>\x03]");
        return Plugin_Handled;
    }

    char arg1[5];
    GetCmdArg(1, arg1, sizeof(arg1));
    int entity = StringToInt(arg1);

    char arg2[5];
    GetCmdArg(2, arg2, sizeof(arg2));
    int owner = StringToInt(arg2);

    if (!IsValidEntity(entity))
    {
        ReplyToCommand(client, "\x03[\x01Invalid \x03vulture\x05. \x05(invalid entity)\x03]");
        return Plugin_Handled;
    }

    if (owner != 0 && !IsValidClient(owner))
    {
        ReplyToCommand(client, "\x03[\x01Invalid \x03owner\x01.\x03]");
        return Plugin_Handled;
    }

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (!StrEqual(classname, "npc_vulture"))
    {
        ReplyToCommand(client, "\x03[\x01Invalid \x03vulture\x01. \x05(not a \"npc_vulture\" classname entity)\x03]");
        return Plugin_Handled;
    }

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "!setvultureowner (before)", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", owner);

    if (owner == 0)
        ReplyToCommand(client, "\x03[\x05Set vulture \x04%i \x05with owner \x04%i (%s)\x03]", entity, owner, "worldspawn");
    else
        ReplyToCommand(client, "\x03[\x05Set vulture \x04%i \x05with owner \x04%i (%N)\x03]", entity, owner, owner);

    if (g_bCvar_Debug) PrintToChatAll("\x03[\x01%s \x03-> \x05entity: \x04%i \x03| \x05owner: \x04%i\x03]", "!setvultureowner (after)", entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (pvk2_parrot_crash_fix) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pvk2_parrot_crash_fix_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "pvk2_parrot_crash_fix_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "pvk2_parrot_crash_fix_debug : %b (%s)", g_bCvar_Debug, g_bCvar_Debug ? "true" : "false");
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