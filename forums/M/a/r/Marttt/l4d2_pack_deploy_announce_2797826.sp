/**
// ====================================================================================================
Change Log:

1.0.0 (23-January-2023)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Upgrade Ammo Pack Deploy Announce"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Outputs to the chat who deployed an upgrade ammo pack and what type of upgrade it is"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341472"

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
#define CONFIG_FILENAME               "l4d2_pack_deploy_announce"
#define TRANSLATION_FILENAME          "l4d2_pack_deploy_announce.phrases"

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

#define TYPE_NONE                     0
#define TYPE_UPGRADE_AMMO_INCENDIARY  1
#define TYPE_UPGRADE_AMMO_EXPLOSIVE   2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Team;
ConVar g_hCvar_Self;
ConVar g_hCvar_Incendiary;
ConVar g_hCvar_Explosive;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Self;
bool g_bCvar_Incendiary;
bool g_bCvar_Explosive;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Team;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadPluginTranslations();

    CreateConVar("l4d2_pack_deploy_announce_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled    = CreateConVar("l4d2_pack_deploy_announce_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team       = CreateConVar("l4d2_pack_deploy_announce_team", "1", "Which teams should the message be transmitted to.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_Self       = CreateConVar("l4d2_pack_deploy_announce_self", "1", "Should the message be transmitted to those who deployed it.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Incendiary = CreateConVar("l4d2_pack_deploy_announce_incendiary", "1", "Output to the chat every time someone deploys an incendiary ammo pack.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Explosive  = CreateConVar("l4d2_pack_deploy_announce_explosive", "1", "Output to the chat every time someone deploys an explosive ammo pack.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Self.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Incendiary.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Explosive.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_pack_deploy_announce", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Self = g_hCvar_Self.BoolValue;
    g_bCvar_Incendiary = g_hCvar_Incendiary.BoolValue;
    g_bCvar_Explosive = g_hCvar_Explosive.BoolValue;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("upgrade_pack_used", Event_UpgradePackUsed);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("upgrade_pack_used", Event_UpgradePackUsed);

        return;
    }
}

/****************************************************************************************************/

void Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int entity = event.GetInt("upgradeid");
    int type = GetUpgradeType(entity);

    OutputMessage(client, type);
}

/****************************************************************************************************/

void OutputMessage(int client, int type)
{
    switch (type)
    {
        case TYPE_UPGRADE_AMMO_INCENDIARY:
        {
            if (!g_bCvar_Incendiary)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Deployed an incendiary ammo pack", client);
            }
        }

        case TYPE_UPGRADE_AMMO_EXPLOSIVE:
        {
            if (!g_bCvar_Explosive)
                return;

            for (int target = 1; target <= MaxClients; target++)
            {
                if (!IsValidPrintTarget(target, client))
                    continue;

                CPrintToChat(target, "%t", "Deployed an explosive ammo pack", client);
            }
        }
    }
}

/****************************************************************************************************/

bool IsValidPrintTarget(int target, int client)
{
    if (!IsClientInGame(target))
        return false;

    if (IsFakeClient(target))
        return false;

    if (target == client && !g_bCvar_Self)
       return false;

    if (!(GetTeamFlag(GetClientTeam(target)) & g_iCvar_Team))
        return false;

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
    PrintToConsole(client, "-------------- Plugin Cvars (l4d2_pack_deploy_announce) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_pack_deploy_announce_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_pack_deploy_announce_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_pack_deploy_announce_team : %i (SPECTATOR = %s | SURVIVOR = %s | INFECTED = %s | HOLDOUT = %s)", g_iCvar_Team,
    g_iCvar_Team & FLAG_TEAM_SPECTATOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_SURVIVOR ? "true" : "false", g_iCvar_Team & FLAG_TEAM_INFECTED ? "true" : "false", g_iCvar_Team & FLAG_TEAM_HOLDOUT ? "true" : "false");
    PrintToConsole(client, "l4d2_pack_deploy_announce_self : %b (%s)", g_bCvar_Self, g_bCvar_Self ? "true" : "false");
    PrintToConsole(client, "l4d2_pack_deploy_announce_incendiary : %b (%s)", g_bCvar_Incendiary, g_bCvar_Incendiary ? "true" : "false");
    PrintToConsole(client, "l4d2_pack_deploy_announce_explosive : %b (%s)", g_bCvar_Explosive, g_bCvar_Explosive ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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

/****************************************************************************************************/

/**
 * Returns the upgrade type.
 *
 * @param entity        Entity index.
 * @return              Entity upgrade type.
 */
int GetUpgradeType(int entity)
{
    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (StrEqual("upgrade_ammo_incendiary", classname))
        return TYPE_UPGRADE_AMMO_INCENDIARY;

    if (StrEqual("upgrade_ammo_explosive", classname))
        return TYPE_UPGRADE_AMMO_EXPLOSIVE;

    return TYPE_NONE;
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