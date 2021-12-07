/**
// ====================================================================================================
Change Log:

1.0.1 (26-February-2021)
    - Fixed wrong netprop set on sm_wound. (thanks "Crasher_3637" for reporting)

1.0.0 (26-February-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1] Wounded Commons"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Add wounds to common infected on spawn"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330918"

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
#define CONFIG_FILENAME               "l4d1_wounded_commons"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFECTED            "infected"

#define HITGROUP_HEAD                 1

#define NO_WOUND                      -1
#define FIRST_WOUND                   0

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Headless;
static ConVar g_hCvar_BeheadHeadshot;
static ConVar g_hCvar_WoundArmChance;
static ConVar g_hCvar_WoundHeadChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Headless;
static bool   g_bCvar_HeadlessHeadshot;
static bool   g_bCvar_WoundArmChance;
static bool   g_bCvar_WoundHeadChance;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_WoundArmChance;
static float  g_fCvar_WoundHeadChance;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static int    gc_iLastEntityEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
static int    gc_iBody[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bIsValidCommon[MAXENTITIES+1];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d1_wounded_commons_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled         = CreateConVar("l4d1_wounded_commons_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Headless        = CreateConVar("l4d1_wounded_commons_headless", "0", "Spawn headless common infected.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BeheadHeadshot  = CreateConVar("l4d1_wounded_commons_behead_headshot", "1", "Behead a common infected every time it is hit on the head.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_WoundArmChance  = CreateConVar("l4d1_wounded_commons_wound_arm_chance", "33.0", "Chance to apply an arm (left/right) wound on common infected spawn.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_WoundHeadChance = CreateConVar("l4d1_wounded_commons_wound_head_chance", "5.0", "Chance to apply a head wound (headless) on common infected spawn.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Headless.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BeheadHeadshot.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WoundArmChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_WoundHeadChance.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_wound", CmdWound, ADMFLAG_ROOT, "Set the body value of the target common infected at crosshair. Increment the value by one when no args are specified (starting from 0 on new targets). Example: no args -> sm_wound / with args -> sm_wound 4.");
    RegAdminCmd("sm_woundinfo", CmdWoundInfo, ADMFLAG_ROOT, "Output to the chat the bodt value of the target common infected at crosshair.");
    RegAdminCmd("sm_print_cvars_l4d1_wounded_commons", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Headless = g_hCvar_Headless.BoolValue;
    g_bCvar_HeadlessHeadshot = g_hCvar_BeheadHeadshot.BoolValue;
    g_fCvar_WoundArmChance = g_hCvar_WoundArmChance.FloatValue;
    g_bCvar_WoundArmChance = (g_fCvar_WoundArmChance > 0.0);
    g_fCvar_WoundHeadChance = g_hCvar_WoundHeadChance.FloatValue;
    g_bCvar_WoundHeadChance = (g_fCvar_WoundHeadChance > 0.0);
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFECTED)) != INVALID_ENT_REFERENCE)
    {
        OnSpawnPost(entity);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iLastEntityEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iBody[client] = 0;
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'i')
        return;

    if (StrEqual(classname, CLASSNAME_INFECTED))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("infected_hurt", Event_InfectedHurt);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("infected_hurt", Event_InfectedHurt);

        return;
    }
}

/****************************************************************************************************/

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_HeadlessHeadshot)
        return;

    int hitgroup = event.GetInt("hitgroup");

    if (hitgroup != HITGROUP_HEAD)
        return;

    int entity = event.GetInt("entityid");

    if (!ge_bIsValidCommon[entity])
        return;

    int body_new = GetHeadshot(entity);

    SetEntProp(entity, Prop_Send, "m_nBody", body_new);
    SetEntProp(entity, Prop_Send, "m_gibbedLimbs", 16);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    ge_bIsValidCommon[entity] = true;

    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    GenerateRandomWound(entity);
}

/****************************************************************************************************/

public void GenerateRandomWound(int entity)
{
    int body = GetEntProp(entity, Prop_Send, "m_nBody");
    int body_new = body;
    int divisor;

    char model[128];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    StringToLowerCase(model);

    if (g_bCvar_WoundArmChance && g_fCvar_WoundArmChance >= GetRandomFloat(0.0, 100.0))
    {
        int random = GetRandomInt(1,2);

        switch (random)
        {
            case 1:
            {
                // ====================================================================================================
                // Left Arm
                // ====================================================================================================
                if (StrContains(model, "female") != -1)
                {
                    if (StrContains(model, "nurse") != -1)
                        divisor = 12;
                    else if (StrContains(model, "rural") != -1)
                        divisor = 12;
                    else if (body == 5)
                        divisor = 24;
                    else if (body == 6)
                        divisor = 24;
                    else if (body >= 36)
                        divisor = 24;
                    else
                        divisor = 16;
                }
                else
                {
                    if (StrEqual(model, "models/infected/common_surgeon_male01.mdl"))
                        divisor = 18;
                    else if (StrEqual(model, "models/infected/common_tsaagent_male01.mdl"))
                        divisor = 18;
                    else if (StrEqual(model, "models/infected/common_male_pilot.mdl"))
                        divisor = 18;
                    else if (StrEqual(model, "models/infected/common_police_male01.mdl"))
                        divisor = 15;
                    else if (StrEqual(model, "models/infected/common_military_male01.mdl"))
                        divisor = 15;
                    else if (StrEqual(model, "models/infected/common_patient_male01.mdl"))
                        divisor = 15;
                    else
                        divisor = body >= 5 ? 30 : 20;
                }

                body_new = body + divisor;
            }
            case 2:
            {
                // ====================================================================================================
                // Right Arm
                // ====================================================================================================
                if (StrContains(model, "female") != -1)
                {
                    if (StrContains(model, "nurse") != -1)
                        divisor = 8;
                    else if (StrContains(model, "rural") != -1)
                        divisor = 8;
                    else if (body == 5)
                        divisor = 20;
                    else if (body == 6)
                        divisor = 20;
                    else if (body >= 36)
                        divisor = 20;
                    else
                        divisor = 12;
                }
                else
                {
                    if (StrEqual(model, "models/infected/common_surgeon_male01.mdl"))
                        divisor = 12;
                    else if (StrEqual(model, "models/infected/common_tsaagent_male01.mdl"))
                        divisor = 12;
                    else if (StrEqual(model, "models/infected/common_male_pilot.mdl"))
                        divisor = 12;
                    else if (StrEqual(model, "models/infected/common_police_male01.mdl"))
                        divisor = 10;
                    else if (StrEqual(model, "models/infected/common_military_male01.mdl"))
                        divisor = 10;
                    else if (StrEqual(model, "models/infected/common_patient_male01.mdl"))
                        divisor = 10;
                    else
                        divisor = body >= 5 ? 25 : 15;
                }

                body_new = body + divisor;
            }
        }
    }

    if (g_bCvar_WoundHeadChance && g_fCvar_WoundHeadChance >= GetRandomFloat(0.0, 100.0))
        body_new = GetHeadshot(entity, body_new);

    if (body != body_new)
        SetEntProp(entity, Prop_Send, "m_nBody", body_new);
}

/****************************************************************************************************/

int GetHeadshot(int entity, int body = -1)
{
    if (body == -1)
        body = GetEntProp(entity, Prop_Send, "m_nBody");

    int body_new = body;
    int divisor;
    int remainder;
    int add;

    char model[128];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    StringToLowerCase(model);

    if (StrContains(model, "female") != -1)
        divisor = 4;
    else if (StrEqual(model, "models/infected/common_surgeon_male01.mdl"))
        divisor = 6;
    else if (StrEqual(model, "models/infected/common_tsaagent_male01.mdl"))
        divisor = 6;
    else
        divisor = 5;

    remainder = (body+1) % divisor;
    add = remainder > 0 ? divisor - remainder : 0;

    if (add > 0)
        body_new = body_new + add;

    return body_new;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdWound(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (!IsValidEntityIndex(entity) || !ge_bIsValidCommon[entity])
    {
        PrintToChat(client, "\x05Invalid target. \x03Usable only on entities with \x04infected \x03classname.");
        return Plugin_Handled;
    }

    int entityRef = EntIndexToEntRef(entity);

    if (gc_iLastEntityEntRef[client] != entityRef)
    {
        gc_iLastEntityEntRef[client] = entityRef;
        gc_iBody[client] = NO_WOUND;
    }

    if (args > 0)
    {
        char sArg[3];
        GetCmdArg(1, sArg, sizeof(sArg));

        int body = StringToInt(sArg);
        if (body < 0) // Prevent crash
            body = 0;

        gc_iBody[client] = body;
    }

    SetEntProp(entity, Prop_Send, "m_nBody", gc_iBody[client]);

    PrintToChat(client, "\x05Body \x01(m_nBody\x01) = \x04%i", gc_iBody[client]);

    gc_iBody[client]++;

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdWoundInfo(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (!IsValidEntityIndex(entity) || !ge_bIsValidCommon[entity])
    {
        PrintToChat(client, "\x05Invalid target. \x03Usable only on entities with \x04infected \x03classname.");
        return Plugin_Handled;
    }

    int body = GetEntProp(entity, Prop_Send, "m_nBody");

    PrintToChat(client, "\x05Body \x01(m_nBody\x01) = \x04%i", body);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d1_wounded_commons) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d1_wounded_commons_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d1_wounded_commons_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d1_wounded_commons_behead : %b (%s)", g_bCvar_Headless, g_bCvar_Headless ? "true" : "false");
    PrintToConsole(client, "l4d1_wounded_commons_behead_headshot : %b (%s)", g_bCvar_HeadlessHeadshot, g_bCvar_HeadlessHeadshot ? "true" : "false");
    PrintToConsole(client, "l4d1_wounded_commons_wound_arm_chance : %.2f%% (%s)", g_fCvar_WoundArmChance, g_bCvar_WoundArmChance ? "true" : "false");
    PrintToConsole(client, "l4d1_wounded_commons_wound_head_chance : %.2f%% (%s)", g_fCvar_WoundHeadChance, g_bCvar_WoundHeadChance ? "true" : "false");
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
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}