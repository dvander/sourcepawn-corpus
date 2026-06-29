/**
// ====================================================================================================
Change Log:

1.0.0 (26-February-2021)
    - Initial release.

// ====================================================================================================
*/

/**
// ====================================================================================================
More info about common infected wounds can be found here:
https://steamcdn-a.akamaihd.net/apps/valve/2010/gdc2010_vlachos_l4d2wounds.pdf
// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Wounded Commons"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Add wounds to common infected on spawn"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330902"

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
#define CONFIG_FILENAME               "l4d2_wounded_commons"

// ====================================================================================================
// Defines
// ====================================================================================================
#define HITGROUP_HEAD                 1

#define GENDER_FEMALE_L4D1            22
#define GENDER_FEMALE_L4D2            2
#define GENDER_CEDA                   11
#define GENDER_RIOT                   15
#define GENDER_JIMMY_GIBS             17

#define NO_WOUND                      -1
#define FIRST_WOUND                   0

#define HEADSHOT_FEMALE               41
#define HEADSHOT_MALE                 41
#define HEADSHOT_CEDA                 0
#define HEADSHOT_RIOT                 2

#define MAX_WOUNDS                    47
#define MAX_FEMALE                    46
#define MAX_MALE                      47
#define MAX_CEDA                      9
#define MAX_RIOT                      13

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Headless;
ConVar g_hCvar_BeheadHeadshot;
ConVar g_hCvar_Wound1Chance;
ConVar g_hCvar_Wound2Chance;
ConVar g_hCvar_FemaleInvalid;
ConVar g_hCvar_MaleInvalid;
ConVar g_hCvar_CedaInvalid;
ConVar g_hCvar_RiotInvalid;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Headless;
bool g_bCvar_HeadlessHeadshot;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Wound1Chance;
int g_iCvar_Wound2Chance;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sCvar_FemaleInvalid[134];
char g_sCvar_MaleInvalid[134];
char g_sCvar_CedaInvalid[134];
char g_sCvar_RiotInvalid[134];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
int gc_iLastEntityEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
int gc_iWound1[MAXPLAYERS+1];
int gc_iWound2[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bIsValidCommon[MAXENTITIES+1];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alFemaleInvalid;
ArrayList g_alMaleInvalid;
ArrayList g_alCedaInvalid;
ArrayList g_alRiotInvalid;

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
    g_alFemaleInvalid = new ArrayList();
    g_alMaleInvalid = new ArrayList();
    g_alCedaInvalid = new ArrayList();
    g_alRiotInvalid = new ArrayList();

    CreateConVar("l4d2_wounded_commons_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled        = CreateConVar("l4d2_wounded_commons_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Headless       = CreateConVar("l4d2_wounded_commons_headless", "0", "Spawn headless common infected.\nNote: CEDA and RIOT models can't be beheaded so a head wound is applied instead.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BeheadHeadshot = CreateConVar("l4d2_wounded_commons_behead_headshot", "0", "Behead a common infected every time it is hit on the head.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Wound1Chance   = CreateConVar("l4d2_wounded_commons_wound1_chance", "100", "Chance to apply a random wound on common infected spawn.\nUse the first wound slot.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Wound2Chance   = CreateConVar("l4d2_wounded_commons_wound2_chance", "100", "Chance to apply a random wound on common infected spawn.\nUse the second wound slot.\nDoesn't repeat the first wound slot.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_FemaleInvalid  = CreateConVar("l4d2_wounded_commons_female_invalid", "8,13,14,15,16,19,20,21,22,23,24", "Invalid wounds to apply on common infected spawn for FEMALE models.\nUse values between 0-46 separated by comma.\n\"-1\" = OFF.", CVAR_FLAGS);
    g_hCvar_MaleInvalid    = CreateConVar("l4d2_wounded_commons_male_invalid", "8,14,15,16,17,20,21,22,23,24,25", "Invalid wounds to apply on common infected spawn for MALE models.\nUse values between 0-47 separated by comma.\n\"-1\" = OFF.", CVAR_FLAGS);
    g_hCvar_CedaInvalid    = CreateConVar("l4d2_wounded_commons_ceda_invalid", "4,5,8,9", "Invalid wounds to apply on common infected spawn for CEDa models.\nUse values between 0-9 separated by comma.\n\"-1\" = OFF.", CVAR_FLAGS);
    g_hCvar_RiotInvalid    = CreateConVar("l4d2_wounded_commons_riot_invalid", "3,4,5", "Invalid wounds to apply on common infected spawn for RIOT models.\nUse values between 0-13 separated by comma.\n\"-1\" = OFF.", CVAR_FLAGS);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Headless.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BeheadHeadshot.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Wound1Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Wound2Chance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FemaleInvalid.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MaleInvalid.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CedaInvalid.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RiotInvalid.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_wound1", CmdWound1, ADMFLAG_ROOT, "Set the first wound value of the target common infected at crosshair. Increment the value by one when no args are specified (starting from -1 on new targets). Example: no args -> sm_wound1 / with args -> sm_wound1 8.");
    RegAdminCmd("sm_wound2", CmdWound2, ADMFLAG_ROOT, "Set the second wound value of the target common infected at crosshair. Increment the value by one when no args are specified (starting from -1 on new targets). Example: no args -> sm_wound2 / with args -> sm_wound2 8.");
    RegAdminCmd("sm_woundinfo", CmdWoundInfo, ADMFLAG_ROOT, "Output to the chat the gender and wound values of the target common infected at crosshair.");
    RegAdminCmd("sm_print_cvars_l4d2_wounded_commons", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Headless = g_hCvar_Headless.BoolValue;
    g_bCvar_HeadlessHeadshot = g_hCvar_BeheadHeadshot.BoolValue;
    g_iCvar_Wound1Chance = g_hCvar_Wound1Chance.IntValue;
    g_iCvar_Wound2Chance = g_hCvar_Wound2Chance.IntValue;
    g_hCvar_FemaleInvalid.GetString(g_sCvar_FemaleInvalid, sizeof(g_sCvar_FemaleInvalid));
    g_hCvar_MaleInvalid.GetString(g_sCvar_MaleInvalid, sizeof(g_sCvar_MaleInvalid));
    g_hCvar_CedaInvalid.GetString(g_sCvar_CedaInvalid, sizeof(g_sCvar_CedaInvalid));
    g_hCvar_RiotInvalid.GetString(g_sCvar_RiotInvalid, sizeof(g_sCvar_RiotInvalid));

    char sWounds[MAX_WOUNDS][3];
    int count;

    g_alFemaleInvalid.Clear();
    count = ExplodeString(g_sCvar_FemaleInvalid, ",", sWounds, sizeof(sWounds), sizeof(sWounds[]));
    for (int i = 0; i < count; i++)
        g_alFemaleInvalid.Push(StringToInt(sWounds[i]));

    g_alMaleInvalid.Clear();
    count = ExplodeString(g_sCvar_MaleInvalid, ",", sWounds, sizeof(sWounds), sizeof(sWounds[]));
    for (int i = 0; i < count; i++)
        g_alMaleInvalid.Push(StringToInt(sWounds[i]));

    g_alCedaInvalid.Clear();
    count = ExplodeString(g_sCvar_CedaInvalid, ",", sWounds, sizeof(sWounds), sizeof(sWounds[]));
    for (int i = 0; i < count; i++)
        g_alCedaInvalid.Push(StringToInt(sWounds[i]));

    g_alRiotInvalid.Clear();
    count = ExplodeString(g_sCvar_RiotInvalid, ",", sWounds, sizeof(sWounds), sizeof(sWounds[]));
    for (int i = 0; i < count; i++)
        g_alRiotInvalid.Push(StringToInt(sWounds[i]));
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
    {
        OnSpawnPost(entity);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iLastEntityEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iWound1[client] = NO_WOUND;
    gc_iWound2[client] = NO_WOUND;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (StrEqual(classname, "infected"))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bIsValidCommon[entity] = false;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("infected_hurt", Event_InfectedHurt);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("infected_hurt", Event_InfectedHurt);

        return;
    }
}

/****************************************************************************************************/

void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_HeadlessHeadshot)
        return;

    int hitgroup = event.GetInt("hitgroup");
    int entity = event.GetInt("entityid");

    if (hitgroup != HITGROUP_HEAD)
        return;

    if (!ge_bIsValidCommon[entity])
        return;

    int wound1 = GetEntProp(entity, Prop_Send, "m_iRequestedWound1");
    int wound2 = GetEntProp(entity, Prop_Send, "m_iRequestedWound2");
    int gender = GetEntProp(entity, Prop_Send, "m_Gender");
    bool random = (GetRandomInt(0, 1) == 1);

    if (wound1 == NO_WOUND)
        SetEntProp(entity, Prop_Send, "m_iRequestedWound1", GetHeadshot(gender));
    else if (wound2 == NO_WOUND)
        SetEntProp(entity, Prop_Send, "m_iRequestedWound2", GetHeadshot(gender));
    else
        SetEntProp(entity, Prop_Send, random ? "m_iRequestedWound1" : "m_iRequestedWound2", GetHeadshot(gender));
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    ge_bIsValidCommon[entity] = true;

    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    GenerateRandomWound(entity);
}

/****************************************************************************************************/

void GenerateRandomWound(int entity)
{
    int gender = GetEntProp(entity, Prop_Send, "m_Gender");

    if (gender == GENDER_JIMMY_GIBS) // There are no wounds for Jimmy Gibs
        return;

    int wound1 = NO_WOUND;

    if (g_iCvar_Wound1Chance >= GetRandomInt(1, 100))
    {
        wound1 = GetRandomWound(gender);
        SetEntProp(entity, Prop_Send, "m_iRequestedWound1", wound1);
    }

    if (g_iCvar_Wound2Chance >= GetRandomInt(1, 100))
    {
        SetEntProp(entity, Prop_Send, "m_iRequestedWound2", GetRandomWound(gender, wound1));
    }
}

/****************************************************************************************************/

int GetRandomWound(int gender, int wound1 = NO_WOUND)
{
    switch (gender)
    {
        case GENDER_JIMMY_GIBS: // There are no wounds for Jimmy Gibs
        {
            return NO_WOUND;
        }
        case GENDER_FEMALE_L4D1,
             GENDER_FEMALE_L4D2:
        {
            int headshot = GetHeadshot(gender);

            if (g_bCvar_Headless && wound1 != headshot)
                return headshot;

            int random = GetRandomInt(FIRST_WOUND, MAX_FEMALE);
            while (random == wound1 || g_alFemaleInvalid.FindValue(random) != -1)
            {
                random = GetRandomInt(FIRST_WOUND, MAX_FEMALE);
            }
            return random;
        }
        case GENDER_CEDA:
        {
            int headshot = GetHeadshot(gender);

            if (g_bCvar_Headless && wound1 != headshot)
                return headshot;

            int random = GetRandomInt(FIRST_WOUND, MAX_CEDA);
            while (random == wound1 || g_alCedaInvalid.FindValue(random) != -1)
            {
                random = GetRandomInt(FIRST_WOUND, MAX_CEDA);
            }
            return random;
        }
        case GENDER_RIOT:
        {
            int headshot = GetHeadshot(gender);

            if (g_bCvar_Headless && wound1 != headshot)
                return headshot;

            int random = GetRandomInt(FIRST_WOUND, MAX_RIOT);
            while (random == wound1 || g_alRiotInvalid.FindValue(random) != -1)
            {
                random = GetRandomInt(FIRST_WOUND, MAX_RIOT);
            }
            return random;
        }
        default: // Probably a male model
        {
            int headshot = GetHeadshot(gender);

            if (g_bCvar_Headless && wound1 != headshot)
                return headshot;

            int random = GetRandomInt(FIRST_WOUND, MAX_MALE);
            while (random == wound1 || g_alMaleInvalid.FindValue(random) != -1)
            {
                random = GetRandomInt(FIRST_WOUND, MAX_MALE);
            }
            return random;
        }
    }
}

/****************************************************************************************************/

int GetHeadshot(int gender)
{
    switch (gender)
    {
        case GENDER_JIMMY_GIBS: // There are no wounds for Jimmy Gibs
        {
            return NO_WOUND;
        }
        case GENDER_FEMALE_L4D1,
             GENDER_FEMALE_L4D2:
        {
            return HEADSHOT_FEMALE;
        }
        case GENDER_CEDA:
        {
            return HEADSHOT_CEDA;
        }
        case GENDER_RIOT:
        {
            return HEADSHOT_RIOT;
        }
        default: // Probably a male model
        {
            return HEADSHOT_MALE;
        }
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdWound1(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "\x05Invalid target.");
        return Plugin_Handled;
    }

    if (!ge_bIsValidCommon[entity])
    {
        PrintToChat(client, "\x05Invalid target. \x03Usable only on entities with \x04infected \x03classname.");
        return Plugin_Handled;
    }

    int entityRef = EntIndexToEntRef(entity);

    if (gc_iLastEntityEntRef[client] != entityRef)
    {
        gc_iLastEntityEntRef[client] = entityRef;
        gc_iWound1[client] = NO_WOUND;
        gc_iWound2[client] = NO_WOUND;
    }

    if (args > 0)
    {
        char sArg[3];
        GetCmdArg(1, sArg, sizeof(sArg));
        gc_iWound1[client] = StringToInt(sArg);
    }

    SetEntProp(entity, Prop_Send, "m_iRequestedWound1", gc_iWound1[client]);

    PrintToChat(client, "\x05Wound 1 \x01(\x03m_iRequestedWound1\x01) = \x04%i", gc_iWound1[client]);

    gc_iWound1[client]++;
    if (gc_iWound1[client] < 0) // int.MaxValue fix
        gc_iWound1[client] = 0;

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdWound2(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "\x05Invalid target.");
        return Plugin_Handled;
    }

    if (!ge_bIsValidCommon[entity])
    {
        PrintToChat(client, "\x05Invalid target. \x03Usable only on entities with \x04infected \x03classname.");
        return Plugin_Handled;
    }

    int entityRef = EntIndexToEntRef(entity);

    if (gc_iLastEntityEntRef[client] != entityRef)
    {
        gc_iLastEntityEntRef[client] = entityRef;
        gc_iWound1[client] = NO_WOUND;
        gc_iWound2[client] = NO_WOUND;
    }

    if (args > 0)
    {
        char sArg[3];
        GetCmdArg(1, sArg, sizeof(sArg));
        gc_iWound2[client] = StringToInt(sArg);
    }

    SetEntProp(entity, Prop_Send, "m_iRequestedWound2", gc_iWound2[client]);

    PrintToChat(client, "\x05Wound 2 \x01(\x03m_iRequestedWound2\x01) = \x04%i", gc_iWound2[client]);

    gc_iWound2[client]++;
    if (gc_iWound2[client] < 0) // int.MaxValue fix
        gc_iWound2[client] = 0;

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdWoundInfo(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
    {
        PrintToChat(client, "\x05Invalid target.");
        return Plugin_Handled;
    }

    if (!ge_bIsValidCommon[entity])
    {
        PrintToChat(client, "\x05Invalid target. \x03Usable only on entities with \x04infected \x03classname.");
        return Plugin_Handled;
    }

    int wound1 = GetEntProp(entity, Prop_Send, "m_iRequestedWound1");
    int wound2 = GetEntProp(entity, Prop_Send, "m_iRequestedWound2");
    int gender = GetEntProp(entity, Prop_Send, "m_Gender");

    PrintToChat(client, "\x05Gender \x01(\x03m_Gender\x01) = \x04%i\n\x05Wound 1 \x01(\x03m_iRequestedWound1\x01) = \x04%i\n\x05Wound 2 \x01(\x03m_iRequestedWound2\x01) = \x04%i", gender, wound1, wound2);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d2_wounded_commons) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_wounded_commons_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_wounded_commons_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_wounded_commons_headless : %b (%s)", g_bCvar_Headless, g_bCvar_Headless ? "true" : "false");
    PrintToConsole(client, "l4d2_wounded_commons_behead_headshot : %b (%s)", g_bCvar_HeadlessHeadshot, g_bCvar_HeadlessHeadshot ? "true" : "false");
    PrintToConsole(client, "l4d2_wounded_commons_wound1_chance : %i%%", g_iCvar_Wound1Chance);
    PrintToConsole(client, "l4d2_wounded_commons_wound2_chance : %i%%", g_iCvar_Wound2Chance);
    PrintToConsole(client, "l4d2_wounded_commons_female_invalid : %s", g_sCvar_FemaleInvalid);
    PrintToConsole(client, "l4d2_wounded_commons_male_invalid : %s", g_sCvar_MaleInvalid);
    PrintToConsole(client, "l4d2_wounded_commons_ceda_invalid : %s", g_sCvar_CedaInvalid);
    PrintToConsole(client, "l4d2_wounded_commons_riot_invalid : %s", g_sCvar_RiotInvalid);
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