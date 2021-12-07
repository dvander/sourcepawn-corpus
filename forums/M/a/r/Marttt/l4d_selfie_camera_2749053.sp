/**
// ====================================================================================================
Change Log:

1.0.0 (06-June-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Selfie Camera"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Turns the camera into selfie mode"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=332884"

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
#define CONFIG_FILENAME               "l4d_selfie_camera"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_POINT_VIEWCONTROL   "point_viewcontrol"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Distance;
static ConVar g_hCvar_DistanceMax;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bCvar_Enabled;
static bool   g_bCvar_DistanceMax;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Distance;
static int    g_iCvar_DistanceMax;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static int    gc_iCameraDistance[MAXPLAYERS+1];
static int    gc_iCameraEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE , ... };

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
    CreateConVar("l4d_selfie_camera_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled     = CreateConVar("l4d_selfie_camera_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Distance    = CreateConVar("l4d_selfie_camera_distance", "50", "Default distance from client when enable the selfie camera.", CVAR_FLAGS, true, 0.0);
    g_hCvar_DistanceMax = CreateConVar("l4d_selfie_camera_distance_max", "0", "Max distance from client when enable the selfie camera.\n0 = Unlimited.", CVAR_FLAGS, true, 0.0);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Distance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DistanceMax.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Public Commands
    RegConsoleCmd("sm_selfie", CmdSelfie, "Change the camera to the selfie mode. Usage: sm_selfie [distance]");

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_selfie_camera", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_Distance = g_hCvar_Distance.IntValue;
    g_iCvar_DistanceMax = g_hCvar_DistanceMax.IntValue;
    g_bCvar_DistanceMax = (g_iCvar_DistanceMax > 0);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iCameraDistance[client] = 0;
    gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_iCameraEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
            {
                AcceptEntityInput(entity, "Disable");
                AcceptEntityInput(entity, "Kill");
            }

            gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
        }
    }
}

/****************************************************************************************************/

public void CreateCamera(int client)
{
    int entity;
    if (gc_iCameraEntRef[client] != INVALID_ENT_REFERENCE)
    {
        entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
        {
            AcceptEntityInput(entity, "Disable");
            AcceptEntityInput(entity, "Kill");
        }

        gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
    }
    else
    {
        float vAng[3];
        GetClientEyeAngles(client, vAng);
        vAng[0] = 0.0;
        vAng[2] = 0.0;

        TeleportEntity(client, NULL_VECTOR, vAng, NULL_VECTOR);
    }

    entity = CreateEntityByName(CLASSNAME_POINT_VIEWCONTROL);
    gc_iCameraEntRef[client] = EntIndexToEntRef(entity);
    DispatchKeyValue(entity, "targetname", "l4d_selfie_camera");

    DispatchSpawn(entity);
    ActivateEntity(entity);

    AcceptEntityInput(entity, "Enable", client);
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if (!IsValidClient(client))
        return;

    if (gc_iCameraEntRef[client] == INVALID_ENT_REFERENCE)
        return;

    if (buttons == 0)
    {
        int entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
        {
            float vPos[3];
            GetClientEyePosition(client, vPos);

            float vDir[3];
            GetClientEyeAngles(client, vDir);

            float vAng[3];
            GetAngleVectors(vDir, vAng, NULL_VECTOR, NULL_VECTOR);
            NormalizeVector(vAng, vAng);

            vPos[0] += (vAng[0] * gc_iCameraDistance[client]);
            vPos[1] += (vAng[1] * gc_iCameraDistance[client]);
            vPos[2] += (vAng[2] * gc_iCameraDistance[client]);

            vDir[0] *= -1.0;
            vDir[1] += 180.0;
            vDir[2] = 0.0;

            TeleportEntity(entity, vPos, vDir, NULL_VECTOR);
        }
        else
        {
            gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
        }
    }
    else
    {
        int entity = EntRefToEntIndex(gc_iCameraEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
        {
            AcceptEntityInput(entity, "Disable");
            AcceptEntityInput(entity, "Kill");
        }

        gc_iCameraEntRef[client] = INVALID_ENT_REFERENCE;
    }
}

// ====================================================================================================
// Public Commands
// ====================================================================================================
public Action CmdSelfie(int client, int args)
{
    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    int distance;
    if (args > 0)
    {
        char sArg[10];
        GetCmdArg(1, sArg, sizeof(sArg));

        distance = StringToInt(sArg);

        if (g_bCvar_DistanceMax &&  distance > g_iCvar_DistanceMax)
            distance = g_iCvar_DistanceMax;
    }

    if (distance == 0)
        distance = g_iCvar_Distance;

    gc_iCameraDistance[client] = distance;

    CreateCamera(client);

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------ Plugin Cvars (l4d_selfie_camera) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_selfie_camera_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_selfie_camera_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_selfie_camera_distance : %i", g_iCvar_Distance);
    PrintToConsole(client, "l4d_selfie_camera_distance_max : %i (%s)", g_iCvar_DistanceMax, g_bCvar_DistanceMax ? "true" : "false");
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