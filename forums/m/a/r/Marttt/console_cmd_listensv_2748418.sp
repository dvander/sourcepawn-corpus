/**
// ====================================================================================================
Change Log:

1.0.4 (08-May-2022)
    - Added cvar to auto set client as admin. (thanks "Tonblader" for requesting)

1.0.3 (27-July-2021)
    - Changed logic to find the host.

1.0.2 (25-July-2021)
    - Added sm_whoishost command.

1.0.1 (31-May-2021)
    - Public release.

1.0.0 (11-May-2021)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ANY] Console Cmd As Host (Listen Server Only)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Executes plugin commands from the console as if it were the host client index"
#define PLUGIN_VERSION                "1.0.4"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=332763"

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
#define CONFIG_FILENAME               "console_cmd_listensv"

// ====================================================================================================
// Defines
// ====================================================================================================
#define FLAG_SETADMIN_OFF             0
#define FLAG_SETADMIN_HOSTONLY        1
#define FLAG_SETADMIN_EVERYONE        2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_SetAdmin;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bConfigsExecuted;
bool g_bEventsHooked;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_SetAdmin;
int g_iClientHost;
int g_iTempValue;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sCommandName[256];
char g_sCommandArgs[256];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bIsHost[MAXPLAYERS+1];

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smSMCommands;
StringMap g_smNonSMCommands;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    g_smSMCommands = new StringMap();
    g_smNonSMCommands = new StringMap();

    CreateConVar("console_cmd_listensv_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled  = CreateConVar("console_cmd_listensv_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SetAdmin = CreateConVar("console_cmd_listensv_setadmin", "1", "Automatically set the client (except bots) with Admin_Root flag and Immunity 99.\n0 = OFF, 1 = HOST ONLY, 2 = EVERYONE.", CVAR_FLAGS, true, 0.0, true, 2.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SetAdmin.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_whoishost", CmdWhoIsHost, ADMFLAG_ROOT, "Print a table displaying the clients and who is the host to the console.");
    RegAdminCmd("sm_print_cvars_console_cmd_listensv", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadCommands()
{
    Handle hCmdIter = GetCommandIterator();
    while (ReadCommandIterator(hCmdIter, g_sCommandName, sizeof(g_sCommandName)))
    {
        g_smSMCommands.SetValue(g_sCommandName, 0);
    }
    delete hCmdIter;
}

/****************************************************************************************************/

public void OnRebuildAdminCache(AdminCachePart part)
{
    if (part != AdminCache_Admins)
        return;

    LateLoad();
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
    if (g_bConfigsExecuted)
        return;

    g_bConfigsExecuted = true;

    LoadCommands();

    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    LateLoad();

    ServerCommand("sm_reloadadmins");
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_SetAdmin = g_hCvar_SetAdmin.IntValue;
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    char ip[4];
    GetClientIP(client, ip, sizeof(ip));

    bool host = (ip[0] == 'l' || StrEqual(ip, "127")); // loopback/localhost or 127.X.X.X
    gc_bIsHost[client] = host;

    if (host)
        g_iClientHost = client;

    SetClientAdmin(client);
}

/****************************************************************************************************/

public void OnClientPostAdminCheck(int client)
{
    if (IsFakeClient(client))
        return;

    SetClientAdmin(client);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    if (g_iClientHost == client)
        g_iClientHost = 0;

    gc_bIsHost[client] = false;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        if (!IsDedicatedServer())
            AddCommandListener(ListenServerCommand, "");

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        if (!IsDedicatedServer())
            RemoveCommandListener(ListenServerCommand, "");

        return;
    }
}

/****************************************************************************************************/

Action ListenServerCommand(int client, const char[] command, int argc)
{
    if (client != 0)
        return Plugin_Continue;

    client = GetHostClient();

    if (!IsValidClient(client))
        return Plugin_Continue;

    if (!CommandExists(command))
        return Plugin_Continue;

    if (g_smNonSMCommands.GetValue(command, g_iTempValue))
        return Plugin_Continue;

    bool g_bFound = g_smSMCommands.GetValue(command, g_iTempValue);

    if (!g_bFound)
    {
        Handle hCmdIter = GetCommandIterator();
        while (ReadCommandIterator(hCmdIter, g_sCommandName, sizeof(g_sCommandName)))
        {
            g_smSMCommands.SetValue(g_sCommandName, 0);

            if (StrEqual(command, g_sCommandName))
            {
                g_bFound = true;
                break;
            }
        }
        delete hCmdIter;
    }

    if (g_bFound)
    {
        if (argc == 0)
        {
            FakeClientCommand(client, "%s", command);
        }
        else
        {
            GetCmdArgString(g_sCommandArgs, sizeof(g_sCommandArgs));
            FakeClientCommand(client, "%s %s", command, g_sCommandArgs);
        }
        return Plugin_Stop;
    }
    else
    {
        g_smNonSMCommands.SetValue(command, 0);
        return Plugin_Continue;
    }
}

/****************************************************************************************************/

void SetClientAdmin(int client)
{
    if (!g_bCvar_Enabled)
        return;

    switch (g_iCvar_SetAdmin)
    {
        case FLAG_SETADMIN_OFF:
        {
            return;
        }
        case FLAG_SETADMIN_HOSTONLY:
        {
            if (!gc_bIsHost[client])
                return;
        }
        case FLAG_SETADMIN_EVERYONE:
        {
        }
    }

    AdminId admin = CreateAdmin("listensv_root_99");
    SetAdminFlag(admin, Admin_Root, true);
    SetAdminImmunityLevel(admin, 99);
    SetUserAdmin(client, admin, true);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdWhoIsHost(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "――――――――――――――――――――――――――――――――――――――――");
    PrintToConsole(client, "|  # | %-31.30s| %-6.5s|", "Name", "Host?");
    PrintToConsole(client, "――――――――――――――――――――――――――――――――――――――――");

    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        PrintToConsole(client, "| %2i | %-31.30N| %-6.5s|", target, target, gc_bIsHost[target] ? "  X  " : "");
    }
    PrintToConsole(client, "――――――――――――――――――――――――――――――――――――――――");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (console_cmd_listensv) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "console_cmd_listensv_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "console_cmd_listensv_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "console_cmd_listensv_setadmin : %i (%s)", g_iCvar_SetAdmin,
    g_iCvar_SetAdmin == FLAG_SETADMIN_OFF ? "OFF" : g_iCvar_SetAdmin == FLAG_SETADMIN_HOSTONLY ? "HOST ONLY" : g_iCvar_SetAdmin == FLAG_SETADMIN_EVERYONE ? "EVERYONE" : "");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "IsDedicatedServer : %b (%s)", IsDedicatedServer(), IsDedicatedServer() ? "true" : "false");
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
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Returns the client index that is hosting the listen server.
 */
int GetHostClient()
{
    if (gc_bIsHost[g_iClientHost])
        return g_iClientHost;
    else
        g_iClientHost = 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_bIsHost[client])
        {
            g_iClientHost = client;
            return g_iClientHost;
        }
    }

    return g_iClientHost;
}