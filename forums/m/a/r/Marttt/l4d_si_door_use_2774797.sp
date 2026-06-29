/**
// ====================================================================================================
Change Log:

1.0.2 (16-July-2022)
    - Fixed doors not opening/closing in the AJAR state.
    - Fixed (workaround) doors not opening/closing to the right side for infected.

1.0.1 (21-March-2022)
    - Split cvar to control allowed door states in client/bot/tongue.
    - Bot behavior is now controlled by a timer for performance improvement.
    - Fixed an attachment issue with duplicated targetnames.

1.0.0 (20-March-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] SI Doors Use"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow special infecteds to open/close doors"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=336984"

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
#define CONFIG_FILENAME               "l4d_si_door_use"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3

#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define L4D2_FLAG_ZOMBIECLASS_NONE    0
#define L4D2_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D2_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D2_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D2_FLAG_ZOMBIECLASS_SPITTER 8
#define L4D2_FLAG_ZOMBIECLASS_JOCKEY  16
#define L4D2_FLAG_ZOMBIECLASS_CHARGER 32
#define L4D2_FLAG_ZOMBIECLASS_TANK    64

#define L4D1_FLAG_ZOMBIECLASS_NONE    0
#define L4D1_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D1_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D1_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D1_FLAG_ZOMBIECLASS_TANK    8

#define DOOR_LOCKED                   1

#define DOOR_TYPE_NORMAL              1
#define DOOR_TYPE_SAFEROOM            2
#define DOOR_TYPE_BOTH                3

#define DOOR_STATE_CLOSED             0
#define DOOR_STATE_OPENING            1
#define DOOR_STATE_OPEN               2
#define DOOR_STATE_CLOSING            3
#define DOOR_STATE_AJAR               4

#define DOOR_CLOSE_ONLY               1
#define DOOR_OPEN_ONLY                2
#define DOOR_OPEN_CLOSE               3

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Bots;
ConVar g_hCvar_BotsInterval;
ConVar g_hCvar_Cooldown;
ConVar g_hCvar_Distance;
ConVar g_hCvar_DoorType;
ConVar g_hCvar_DoorState;
ConVar g_hCvar_DoorStateBots;
ConVar g_hCvar_DoorStateTongue;
ConVar g_hCvar_SmokerAbility;
ConVar g_hCvar_SmokerDistance;
ConVar g_hCvar_TongueParticle;
ConVar g_hCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Bots;
bool g_bCvar_SmokerAbility;
bool g_bCvar_SmokerDistance;
bool g_bCvar_TongueParticle;
bool g_bTimer;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_SI;
int g_iCvar_DoorType;
int g_iCvar_DoorState;
int g_iCvar_DoorStateBots;
int g_iCvar_DoorStateTongue;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fParticleKillPos[3] = {-9999.9, -9999.9, -9999.9};
float g_fCvar_BotsInterval;
float g_fCvar_Cooldown;
float g_fCvar_Distance;
float g_fCvar_SmokerDistance;
float g_fCvar_TongueParticle;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sKillInput[50];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
float gc_fLastUse[MAXPLAYERS+1][MAXENTITIES+1];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alPluginEntities;

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tCheckBots;

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

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    g_alPluginEntities = new ArrayList();

    CreateConVar("l4d_si_door_use_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled         = CreateConVar("l4d_si_door_use_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Bots            = CreateConVar("l4d_si_door_use_bots", "1", "Allow SI bots to open/close doors when in range.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_BotsInterval    = CreateConVar("l4d_si_door_use_bots_interval", "0.5", "Interval in seconds to check bots to open/close doors.", CVAR_FLAGS, true, 0.1);
    g_hCvar_Cooldown        = CreateConVar("l4d_si_door_use_cooldown", "2.0", "Cooldown to open/close the same door again.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Distance        = CreateConVar("l4d_si_door_use_distance", "100.0", "How far a special infected can be to open/close a door.", CVAR_FLAGS, true, 0.0);
    g_hCvar_DoorType        = CreateConVar("l4d_si_door_use_door_type", "3", "Which type of door should SI be allowed to interact (open/close).\n1 = Normal Door (prop_door_rotating), 2 = Saferoom Door (prop_door_rotating_checkpoint), 3 = Both.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_DoorState       = CreateConVar("l4d_si_door_use_door_state", "3", "Which state of the door should be allowed to clients.\n1 = Only close doors, 2 = Only open doors, 3 = Both.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_DoorStateBots   = CreateConVar("l4d_si_door_use_door_state_bots", "2", "Which state of the door should be allowed to bots.\n1 = Only close doors, 2 = Only open doors, 3 = Both.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_DoorStateTongue = CreateConVar("l4d_si_door_use_door_state_tongue", "3", "Which state of the door should be allowed with tongue.\n1 = Only close doors, 2 = Only open doors, 3 = Both.", CVAR_FLAGS, true, 1.0, true, 3.0);
    g_hCvar_SmokerAbility   = CreateConVar("l4d_si_door_use_smoker_ability", "1", "Allow the Smoker to open/close the door using its tongue ability.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SmokerDistance  = CreateConVar("l4d_si_door_use_smoker_distance", "750.0", "How far a Smoker can be to open/close a door with a tongue.\n0 = No distance check.", CVAR_FLAGS, true, 0.0);
    g_hCvar_TongueParticle  = CreateConVar("l4d_si_door_use_tongue_particle", "1.0", "How long (in seconds) the tongue particle should be visible.\n0 = OFF.", CVAR_FLAGS, true, 0.0);

    if (g_bL4D2)
        g_hCvar_SI          = CreateConVar("l4d_si_door_use_si", "127", "Which special infected should be able to open/close doors.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", enables command chase for all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);
    else
        g_hCvar_SI          = CreateConVar("l4d_si_door_use_si", "15", "Which special infected should be able to open/close doors.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", enables command chase for all SI.", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Bots.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BotsInterval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cooldown.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Distance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DoorType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DoorState.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DoorStateBots.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DoorStateTongue.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerAbility.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SmokerDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TongueParticle.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_si_door_use", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;
    char classname[36];

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        GetEntityClassname(entity, classname, sizeof(classname));

        AcceptEntityInput(entity, "ClearParent");

        if (StrEqual(classname, "info_particle_system"))
            AcceptEntityInput(entity, "Stop");

        TeleportEntity(entity, g_fParticleKillPos, NULL_VECTOR, NULL_VECTOR);
    }

    g_alPluginEntities.Clear();
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
    GetCvars();

    HookEvents();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Bots = g_hCvar_Bots.BoolValue;
    g_fCvar_BotsInterval = g_hCvar_BotsInterval.FloatValue;
    g_fCvar_Cooldown = g_hCvar_Cooldown.FloatValue;
    g_fCvar_Distance = g_hCvar_Distance.FloatValue;
    g_iCvar_DoorType = g_hCvar_DoorType.IntValue;
    g_iCvar_DoorState = g_hCvar_DoorState.IntValue;
    g_iCvar_DoorStateBots = g_hCvar_DoorStateBots.IntValue;
    g_iCvar_DoorStateTongue = g_hCvar_DoorStateTongue.IntValue;
    g_bCvar_SmokerAbility = g_hCvar_SmokerAbility.BoolValue;
    g_fCvar_SmokerDistance = g_hCvar_SmokerDistance.FloatValue;
    g_bCvar_SmokerDistance = (g_fCvar_SmokerDistance > 0.0);
    g_fCvar_TongueParticle = g_hCvar_TongueParticle.FloatValue;
    g_bCvar_TongueParticle = (g_fCvar_TongueParticle > 0.0);
    g_iCvar_SI = g_hCvar_SI.IntValue;

    FormatEx(g_sKillInput, sizeof(g_sKillInput), "OnUser1 !self:Kill::%.1f:-1", g_fCvar_TongueParticle + 0.1);

    g_bTimer = (g_bCvar_Enabled && g_bCvar_Bots);
    delete g_tCheckBots;
    if (g_bTimer)
        g_tCheckBots = CreateTimer(g_fCvar_BotsInterval, TimerCheckBots, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    for (int entity = 0; entity < MAXENTITIES+1; entity++)
    {
        gc_fLastUse[client][entity] = 0.0;
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("ability_use", Event_AbilityUse);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("ability_use", Event_AbilityUse);

        return;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    for (int client = 1; client <= MaxClients; client++)
    {
        gc_fLastUse[client][entity] = 0.0;
    }

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

Action TimerCheckBots(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsFakeClient(client))
            continue;

        if (GetClientTeam(client) != TEAM_INFECTED)
            continue;

        if (!IsPlayerAlive(client))
            continue;

        if (IsPlayerGhost(client))
            continue;

        if (!(GetZombieClassFlag(client) & g_iCvar_SI))
            continue;

        int target = GetClientAimDoor(client);

        if (target == -1)
            continue;

        if (gc_fLastUse[client][target] != 0.0 && GetGameTime() - gc_fLastUse[client][target] < g_fCvar_Cooldown)
            continue;

        if (GetEntProp(target, Prop_Send, "m_bLocked") == DOOR_LOCKED)
            continue;

        bool doorIsClosed;
        switch (GetEntProp(target, Prop_Send, "m_eDoorState"))
        {
            case DOOR_STATE_CLOSED: doorIsClosed = true;
            case DOOR_STATE_OPEN: doorIsClosed = false;
            case DOOR_STATE_AJAR: doorIsClosed = true;
            default: continue;
        }

        switch (g_iCvar_DoorStateBots)
        {
            case DOOR_CLOSE_ONLY:
            {
                if (doorIsClosed)
                    continue;
            }
            case DOOR_OPEN_ONLY:
            {
                if (!doorIsClosed)
                    continue;
            }
        }

        float vPosClient[3];
        GetClientAbsOrigin(client, vPosClient);

        float vPosTarget[3];
        GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPosTarget);

        float distance = GetVectorDistance(vPosClient, vPosTarget);

        if (distance > g_fCvar_Distance)
            continue;

        SetEntProp(client, Prop_Data, "m_iTeamNum", TEAM_SURVIVOR); // BEGIN: workaround to fix door not opening/closing to the right side for infecteds
        AcceptEntityInput(target, doorIsClosed ? "PlayerOpen" : "PlayerClose", client);
        SetEntProp(client, Prop_Data, "m_iTeamNum", TEAM_INFECTED); // END: workaround to fix door not opening/closing to the right side for infecteds

        gc_fLastUse[client][target] = GetGameTime();
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons)
{
    if (!g_bCvar_Enabled)
        return;

    if (!(buttons & IN_USE))
        return;

    if (client < 1)
        return;

    if (IsFakeClient(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    if (!IsPlayerAlive(client))
        return;

    if (IsPlayerGhost(client))
        return;

    if (!(GetZombieClassFlag(client) & g_iCvar_SI))
        return;

    int target = GetClientAimDoor(client);

    if (target == -1)
        return;

    if (gc_fLastUse[client][target] != 0.0 && GetGameTime() - gc_fLastUse[client][target] < g_fCvar_Cooldown)
        return;

    if (GetEntProp(target, Prop_Send, "m_bLocked") == DOOR_LOCKED)
        return;

    bool doorIsClosed;
    switch (GetEntProp(target, Prop_Send, "m_eDoorState"))
    {
        case DOOR_STATE_CLOSED: doorIsClosed = true;
        case DOOR_STATE_OPEN: doorIsClosed = false;
        case DOOR_STATE_AJAR: doorIsClosed = true;
        default: return;
    }

    switch (g_iCvar_DoorState)
    {
        case DOOR_CLOSE_ONLY:
        {
            if (doorIsClosed)
                return;
        }
        case DOOR_OPEN_ONLY:
        {
            if (!doorIsClosed)
                return;
        }
    }

    float vPosClient[3];
    GetClientAbsOrigin(client, vPosClient);

    float vPosTarget[3];
    GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPosTarget);

    float distance = GetVectorDistance(vPosClient, vPosTarget);

    if (distance > g_fCvar_Distance)
        return;

    SetEntProp(client, Prop_Data, "m_iTeamNum", TEAM_SURVIVOR); // BEGIN: workaround to fix door not opening/closing to the right side for infecteds
    AcceptEntityInput(target, doorIsClosed ? "PlayerOpen" : "PlayerClose", client);
    SetEntProp(client, Prop_Data, "m_iTeamNum", TEAM_INFECTED); // END: workaround to fix door not opening/closing to the right side for infecteds

    gc_fLastUse[client][target] = GetGameTime();
}

/****************************************************************************************************/

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_SmokerAbility)
        return;

    int context = event.GetInt("context");
    int client = GetClientOfUserId(event.GetInt("userid"));
    char ability[16];
    event.GetString("ability", ability, sizeof(ability));

    if (context == 1)  // client grabbed
        return;

    if (!StrEqual(ability, "ability_tongue"))
        return;

    if (client == 0)
        return;

    int target = GetClientAimDoor(client);

    if (target == -1)
        return;

    if (GetEntProp(target, Prop_Send, "m_bLocked") == DOOR_LOCKED)
        return;

    bool doorIsClosed;
    switch (GetEntProp(target, Prop_Send, "m_eDoorState"))
    {
        case DOOR_STATE_CLOSED: doorIsClosed = true;
        case DOOR_STATE_OPEN: doorIsClosed = false;
        case DOOR_STATE_AJAR: doorIsClosed = true;
        default: return;
    }

    switch (g_iCvar_DoorStateTongue)
    {
        case DOOR_CLOSE_ONLY:
        {
            if (doorIsClosed)
                return;
        }
        case DOOR_OPEN_ONLY:
        {
            if (!doorIsClosed)
                return;
        }
    }

    if (g_bCvar_SmokerDistance)
    {
        float vPosClient[3];
        GetClientAbsOrigin(client, vPosClient);

        float vPosTarget[3];
        GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPosTarget);

        float distance = GetVectorDistance(vPosClient, vPosTarget);

        if (distance > g_fCvar_SmokerDistance)
            return;
    }

    SetEntProp(client, Prop_Data, "m_iTeamNum", TEAM_SURVIVOR); // BEGIN: workaround to fix door not opening/closing to the right side for infecteds
    AcceptEntityInput(target, doorIsClosed ? "PlayerOpen" : "PlayerClose", client);
    SetEntProp(client, Prop_Data, "m_iTeamNum", TEAM_INFECTED); // END: workaround to fix door not opening/closing to the right side for infecteds

    if (g_bCvar_TongueParticle)
        CreateSmokerTongue(client, target);
}

/****************************************************************************************************/

void CreateSmokerTongue(int client, int target)
{
    float vPos[3];
    GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);

    float vMaxs[3];
    GetEntPropVector(target, Prop_Send, "m_vecMaxs", vMaxs);

    float vOffset[3];
    vOffset[0] = vMaxs[0] / 2;
    vOffset[1] = vMaxs[1] / 2;
    vOffset[2] = vMaxs[2] / 2;

    int infoTarget = CreateEntityByName("info_target");

    char targetname[39];
    FormatEx(targetname, sizeof(targetname), "l4d_si_door_use-info_target%i", EntIndexToEntRef(infoTarget));

    DispatchKeyValue(infoTarget, "targetname", targetname);
    DispatchKeyValue(infoTarget, "spawnflags", "1");
    DispatchKeyValueVector(infoTarget, "origin", vPos);
    DispatchSpawn(infoTarget);

    if (g_alPluginEntities.FindValue(EntIndexToEntRef(infoTarget)) == -1)
        g_alPluginEntities.Push(EntIndexToEntRef(infoTarget));

    SetVariantString("!activator");
    AcceptEntityInput(infoTarget, "SetParent", target);

    TeleportEntity(infoTarget, vOffset, NULL_VECTOR, NULL_VECTOR);

    SetVariantString(g_sKillInput);
    AcceptEntityInput(infoTarget, "AddOutput");
    AcceptEntityInput(infoTarget, "FireUser1");

    int particle = CreateEntityByName("info_particle_system");
    DispatchKeyValue(particle, "targetname", "l4d_si_door_use");
    DispatchKeyValue(particle, "effect_name", "smoker_tongue");
    DispatchKeyValue(particle, "cpoint1", targetname);
    DispatchKeyValueVector(particle, "origin", vPos);
    DispatchSpawn(particle);
    ActivateEntity(particle); // Don't work without it

    if (g_alPluginEntities.FindValue(EntIndexToEntRef(particle)) == -1)
        g_alPluginEntities.Push(EntIndexToEntRef(particle));

    SetVariantString("!activator");
    AcceptEntityInput(particle, "SetParent", client);

    SetVariantString("smoker_mouth");
    AcceptEntityInput(particle, "SetParentAttachment");

    AcceptEntityInput(particle, "Start");

    SetVariantString(g_sKillInput);
    AcceptEntityInput(particle, "AddOutput");
    AcceptEntityInput(particle, "FireUser1");

    DataPack pack;
    CreateDataTimer(g_fCvar_TongueParticle, TimerKillTongue, pack, TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(EntIndexToEntRef(infoTarget));
    pack.WriteCell(EntIndexToEntRef(particle));
}

/****************************************************************************************************/

Action TimerKillTongue(Handle timer, DataPack pack)
{
    pack.Reset();
    int infoTarget = EntRefToEntIndex(pack.ReadCell());
    int particle = EntRefToEntIndex(pack.ReadCell());

    if (infoTarget != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(infoTarget, "ClearParent");
        TeleportEntity(infoTarget, g_fParticleKillPos, NULL_VECTOR, NULL_VECTOR);
    }

    if (particle != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(particle, "ClearParent");
        AcceptEntityInput(particle, "Stop");
        TeleportEntity(particle, g_fParticleKillPos, NULL_VECTOR, NULL_VECTOR);
    }

    return Plugin_Stop;
}

/****************************************************************************************************/

int GetClientAimDoor(int client)
{
    int entity = GetClientAimTarget(client, false);

    if (entity == -1)
        return -1;

    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    switch (g_iCvar_DoorType)
    {
        case DOOR_TYPE_NORMAL:
        {
            if (StrEqual(classname, "prop_door_rotating"))
                return entity;
        }
        case DOOR_TYPE_SAFEROOM:
        {
            if (StrEqual(classname, "prop_door_rotating_checkpoint"))
                return entity;
        }
        case DOOR_TYPE_BOTH:
        {
            if (StrContains(classname, "prop_door_rotating") != -1)
                return entity;
        }
    }

    return -1;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_si_door_use) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_si_door_use_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_si_door_use_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_bots : %b (%s)", g_bCvar_Bots, g_bCvar_Bots ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_bots_interval : %.1f", g_fCvar_BotsInterval);
    PrintToConsole(client, "l4d_si_door_use_cooldown : %.1f", g_fCvar_Cooldown);
    PrintToConsole(client, "l4d_si_door_use_distance : %.1f", g_fCvar_Distance);
    PrintToConsole(client, "l4d_si_door_use_door_type : %i (NORMAL = %s | SAFEROOM = %s)", g_iCvar_DoorType, g_iCvar_DoorType & DOOR_TYPE_NORMAL ? "true" : "false", g_iCvar_DoorType & DOOR_TYPE_SAFEROOM ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_door_state : %i (CLOSE = %s | OPEN = %s)", g_iCvar_DoorState, g_iCvar_DoorState & DOOR_CLOSE_ONLY ? "true" : "false", g_iCvar_DoorState & DOOR_OPEN_ONLY ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_door_state_bots : %i (CLOSE = %s | OPEN = %s)", g_iCvar_DoorStateBots, g_iCvar_DoorStateBots & DOOR_CLOSE_ONLY ? "true" : "false", g_iCvar_DoorStateBots & DOOR_OPEN_ONLY ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_door_state_tongue : %i (CLOSE = %s | OPEN = %s)", g_iCvar_DoorStateTongue, g_iCvar_DoorStateTongue & DOOR_CLOSE_ONLY ? "true" : "false", g_iCvar_DoorStateTongue & DOOR_OPEN_ONLY ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_smoker_ability : %b (%s)", g_bCvar_SmokerAbility, g_bCvar_SmokerAbility ? "true" : "false");
    PrintToConsole(client, "l4d_si_door_use_smoker_distance : %.1f", g_fCvar_SmokerDistance);
    PrintToConsole(client, "l4d_si_door_use_tongue_particle : %.1f", g_fCvar_TongueParticle);
    if (g_bL4D2)
    {
        PrintToConsole(client, "l4d_si_door_use_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | SPITTER = %s | JOCKEY = %s | CHARGER = %s | TANK = %s)", g_iCvar_SI,
        g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_SPITTER ? "true" : "false",
        g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_JOCKEY ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_CHARGER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    else
    {
        PrintToConsole(client, "l4d_si_door_use_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | TANK = %s)", g_iCvar_SI,
        g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
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
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client        Client index.
 * @return L4D1         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Returns the zombie class flag from a zombie class.
 *
 * @param client        Client index.
 * @return              Client zombie class flag.
 */
int GetZombieClassFlag(int client)
{
    int zombieClass = GetZombieClass(client);

    if (g_bL4D2)
    {
        switch (zombieClass)
        {
            case L4D2_ZOMBIECLASS_SMOKER:
                return L4D2_FLAG_ZOMBIECLASS_SMOKER;
            case L4D2_ZOMBIECLASS_BOOMER:
                return L4D2_FLAG_ZOMBIECLASS_BOOMER;
            case L4D2_ZOMBIECLASS_HUNTER:
                return L4D2_FLAG_ZOMBIECLASS_HUNTER;
            case L4D2_ZOMBIECLASS_SPITTER:
                return L4D2_FLAG_ZOMBIECLASS_SPITTER;
            case L4D2_ZOMBIECLASS_JOCKEY:
                return L4D2_FLAG_ZOMBIECLASS_JOCKEY;
            case L4D2_ZOMBIECLASS_CHARGER:
                return L4D2_FLAG_ZOMBIECLASS_CHARGER;
            case L4D2_ZOMBIECLASS_TANK:
                return L4D2_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D2_FLAG_ZOMBIECLASS_NONE;
        }
    }
    else
    {
        switch (zombieClass)
        {
            case L4D1_ZOMBIECLASS_SMOKER:
                return L4D1_FLAG_ZOMBIECLASS_SMOKER;
            case L4D1_ZOMBIECLASS_BOOMER:
                return L4D1_FLAG_ZOMBIECLASS_BOOMER;
            case L4D1_ZOMBIECLASS_HUNTER:
                return L4D1_FLAG_ZOMBIECLASS_HUNTER;
            case L4D1_ZOMBIECLASS_TANK:
                return L4D1_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D1_FLAG_ZOMBIECLASS_NONE;
        }
    }
}

/****************************************************************************************************/

/**
 * Returns if the client is in ghost state.
 *
 * @param client        Client index.
 * @return              True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}