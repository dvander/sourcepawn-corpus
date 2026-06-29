/**
// ====================================================================================================
Change Log:

1.0.1 (13-December-2021)
    - Added cvar to delete items from water.
    - Added cvar to teleport dead bodies to the rescue point.

1.0.0 (06-December-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Tank Challenge Ladder"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds extra ladders to the Tank Challenge map"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=335462"

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
#define CONFIG_FILENAME               "l4d2_tank_challenge_ladder"

// ====================================================================================================
// Defines
// ====================================================================================================
#define WATER_ZPOS                    -585.0

#define MODEL_METALLADDERBARGE        "models/props_unique/metalladderbarge.mdl"

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_RemoveFromWater;
ConVar g_hCvar_TeleportDead;
ConVar g_hCvar_BlockGlitchSpot;
ConVar g_hCvar_MinigunElevator;
ConVar g_hCvar_LadderVisualFix;
ConVar g_hCvar_Ladder_5796;
ConVar g_hCvar_Ladder_7033;
ConVar g_hCvar_Ladder_7039;
ConVar g_hCvar_Ladder_7045;
ConVar g_hCvar_Ladder_7051;
ConVar g_hCvar_Ladder_7057;
ConVar g_hCvar_Ladder_7065;
ConVar g_hCvar_Ladder_7075;
ConVar g_hCvar_Ladder_7635;
ConVar g_hCvar_Ladder_17198;
ConVar g_hCvar_Ladder_17218;
ConVar g_hCvar_Ladder_27714;
ConVar g_hCvar_Ladder_27784;
ConVar g_hCvar_Ladder_27791;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bIsTankChallengeMap;
bool g_bMapStarted;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_RemoveFromWater;
bool g_bCvar_BlockGlitchSpot;
bool g_bCvar_MinigunElevator;
bool g_bCvar_LadderVisualFix;
bool g_bCvar_TeleportDead;
bool g_bTimerRemoveFromWater;
bool g_bTimerTeleportDead;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCurrentRescue = 1;
int g_iCvar_Ladder_5796;
int g_iCvar_Ladder_7033;
int g_iCvar_Ladder_7039;
int g_iCvar_Ladder_7045;
int g_iCvar_Ladder_7051;
int g_iCvar_Ladder_7057;
int g_iCvar_Ladder_7065;
int g_iCvar_Ladder_7075;
int g_iCvar_Ladder_7635;
int g_iCvar_Ladder_17198;
int g_iCvar_Ladder_17218;
int g_iCvar_Ladder_27714;
int g_iCvar_Ladder_27784;
int g_iCvar_Ladder_27791;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fvPosSurvivorRescue1[3] = { -898.0, -262.0, 80.0 };
float g_fvPosSurvivorRescue2[3] = { -990.0, -170.0, 80.0 };
float g_fvPosSurvivorRescue3[3] = { -898.0, -170.0, 80.0 };
float g_fCvar_TeleportDead;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iTeamNum[MAXENTITIES+1];
int ge_iGlowType[MAXENTITIES+1];
int ge_iGlowColorOverride[MAXENTITIES+1];
float ge_fCreatedTime[MAXENTITIES+1];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alClip;
ArrayList g_alLadder;
ArrayList g_alDummyLadder;
ArrayList g_alSurvivorDeathModel;

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tRemoveWaterEntities;
Handle g_tTeleportDead;

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
    g_alClip = new ArrayList();
    g_alLadder = new ArrayList();
    g_alDummyLadder = new ArrayList();
    g_alSurvivorDeathModel = new ArrayList();

    CreateConVar("l4d2_tank_challenge_ladder_ver", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled         = CreateConVar("l4d2_tank_challenge_ladder_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RemoveFromWater = CreateConVar("l4d2_tank_challenge_ladder_remove_from_water", "1", "Remove entities that fall into water.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_TeleportDead    = CreateConVar("l4d2_tank_challenge_ladder_teleport_dead", "1.0", "Teleport dead bodies that fall into water to the rescue point after X seconds.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_BlockGlitchSpot = CreateConVar("l4d2_tank_challenge_ladder_block_glitch_spot", "1", "Creates a blocker preventing survivors to go to an unreachable spot. (on top of the taller buildings)\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MinigunElevator = CreateConVar("l4d2_tank_challenge_ladder_minigun_elevator", "1", "Starts the round with the miniguns elevator already enabled.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_LadderVisualFix = CreateConVar("l4d2_tank_challenge_ladder_visual_fix", "1", "Adds another model to the bottom of the ladder near the starting area to make it look better.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Ladder_5796     = CreateConVar("l4d2_tank_challenge_ladder_5796", "100", "Chance (%) to spawn a ladder of hammerid 5796 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7033     = CreateConVar("l4d2_tank_challenge_ladder_7033", "100", "Chance (%) to spawn a ladder of hammerid 7033 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7039     = CreateConVar("l4d2_tank_challenge_ladder_7039", "100", "Chance (%) to spawn a ladder of hammerid 7039 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7045     = CreateConVar("l4d2_tank_challenge_ladder_7045", "100", "Chance (%) to spawn a ladder of hammerid 7045 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7051     = CreateConVar("l4d2_tank_challenge_ladder_7051", "100", "Chance (%) to spawn a ladder of hammerid 7051 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7057     = CreateConVar("l4d2_tank_challenge_ladder_7057", "100", "Chance (%) to spawn a ladder of hammerid 7057 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7065     = CreateConVar("l4d2_tank_challenge_ladder_7065", "100", "Chance (%) to spawn a ladder of hammerid 7065 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7075     = CreateConVar("l4d2_tank_challenge_ladder_7075", "100", "Chance (%) to spawn a ladder of hammerid 7075 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_7635     = CreateConVar("l4d2_tank_challenge_ladder_7635", "100", "Chance (%) to spawn a ladder of hammerid 7635 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_17198    = CreateConVar("l4d2_tank_challenge_ladder_17198", "100", "Chance (%) to spawn a ladder of hammerid 17198 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_17218    = CreateConVar("l4d2_tank_challenge_ladder_17218", "100", "Chance (%) to spawn a ladder of hammerid 17218 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_27714    = CreateConVar("l4d2_tank_challenge_ladder_27714", "100", "Chance (%) to spawn a ladder of hammerid 27714 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_27784    = CreateConVar("l4d2_tank_challenge_ladder_27784", "100", "Chance (%) to spawn a ladder of hammerid 27784 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_Ladder_27791    = CreateConVar("l4d2_tank_challenge_ladder_27791", "100", "Chance (%) to spawn a ladder of hammerid 27791 for the survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RemoveFromWater.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TeleportDead.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BlockGlitchSpot.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinigunElevator.AddChangeHook(Event_ConVarChanged);
    g_hCvar_LadderVisualFix.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_5796.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7033.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7039.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7045.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7051.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7057.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7065.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7075.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_7635.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_17198.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_17218.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_27714.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_27784.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Ladder_27791.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_glow_tank_challenge_ladder", CmdGlowOutline, ADMFLAG_ROOT, "Temporary adds an outline glow to the extra ladders.");
    RegAdminCmd("sm_print_cvars_l4d2_tank_challenge", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    char mapName[20];
    GetCurrentMap(mapName, sizeof(mapName));

    g_bIsTankChallengeMap = (StrEqual(mapName, "l4d2_tank_challenge", false));

    if (g_bIsTankChallengeMap)
        PrecacheModel(MODEL_METALLADDERBARGE, true);

    g_bMapStarted = true;

    LoadFakeLadders();
}

/****************************************************************************************************/

public void OnMapEnd()
{
    g_bMapStarted = false;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    LateLoad();

    LoadFakeLadders();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    LateLoad();

    LoadFakeLadders();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_RemoveFromWater = g_hCvar_RemoveFromWater.BoolValue;
    g_fCvar_TeleportDead = g_hCvar_TeleportDead.FloatValue;
    g_bCvar_TeleportDead = (g_fCvar_TeleportDead > 0.0);
    g_bCvar_BlockGlitchSpot = g_hCvar_BlockGlitchSpot.BoolValue;
    g_bCvar_MinigunElevator = g_hCvar_MinigunElevator.BoolValue;
    g_bCvar_LadderVisualFix = g_hCvar_LadderVisualFix.BoolValue;
    g_iCvar_Ladder_5796 = g_hCvar_Ladder_5796.IntValue;
    g_iCvar_Ladder_7033 = g_hCvar_Ladder_7033.IntValue;
    g_iCvar_Ladder_7039 = g_hCvar_Ladder_7039.IntValue;
    g_iCvar_Ladder_7045 = g_hCvar_Ladder_7045.IntValue;
    g_iCvar_Ladder_7051 = g_hCvar_Ladder_7051.IntValue;
    g_iCvar_Ladder_7057 = g_hCvar_Ladder_7057.IntValue;
    g_iCvar_Ladder_7065 = g_hCvar_Ladder_7065.IntValue;
    g_iCvar_Ladder_7075 = g_hCvar_Ladder_7075.IntValue;
    g_iCvar_Ladder_7635 = g_hCvar_Ladder_7635.IntValue;
    g_iCvar_Ladder_17198 = g_hCvar_Ladder_17198.IntValue;
    g_iCvar_Ladder_17218 = g_hCvar_Ladder_17218.IntValue;
    g_iCvar_Ladder_27714 = g_hCvar_Ladder_27714.IntValue;
    g_iCvar_Ladder_27784 = g_hCvar_Ladder_27784.IntValue;
    g_iCvar_Ladder_27791 = g_hCvar_Ladder_27791.IntValue;

    g_bTimerRemoveFromWater = (g_bIsTankChallengeMap && g_bCvar_Enabled && g_bCvar_RemoveFromWater);
    g_bTimerTeleportDead = (g_bIsTankChallengeMap && g_bCvar_Enabled && g_bCvar_TeleportDead);

    delete g_tRemoveWaterEntities;
    if (g_bTimerRemoveFromWater)
        g_tRemoveWaterEntities = CreateTimer(1.0, TimerRemoveWaterEntities, _, TIMER_REPEAT);

    delete g_tTeleportDead;
    if (g_bTimerTeleportDead)
        g_tTeleportDead = CreateTimer(1.0, TimerTeleportDead, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
    {
        if (g_alSurvivorDeathModel.FindValue(EntIndexToEntRef(entity)) == -1)
        {
            ge_fCreatedTime[entity] = GetGameTime();
            g_alSurvivorDeathModel.Push(EntIndexToEntRef(entity));
        }
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("round_start", Event_RoundStart);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("round_start", Event_RoundStart);

        return;
    }
}

/****************************************************************************************************/

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bMapStarted)
        LoadFakeLadders();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (!g_bIsTankChallengeMap)
        return;

    if (StrEqual(classname, "weapon_first_aid_kit_spawn"))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);

    if (StrEqual(classname, "survivor_death_model"))
    {
        if (g_alSurvivorDeathModel.FindValue(EntIndexToEntRef(entity)) == -1)
        {
            ge_fCreatedTime[entity] = GetGameTime();
            g_alSurvivorDeathModel.Push(EntIndexToEntRef(entity));
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iTeamNum[entity] = 0;
    ge_iGlowType[entity] = 0;
    ge_iGlowColorOverride[entity] = 0;
    ge_fCreatedTime[entity] = 0.0;

    int find = g_alSurvivorDeathModel.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alSurvivorDeathModel.Erase(find);
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    SetEntProp(entity, Prop_Send, "movetype", 0); // Fixes: "Updating physics on object in hierarchy weapon_first_aid_kit_spawn!"
}

/****************************************************************************************************/

void LoadFakeLadders()
{
    if (!g_bIsTankChallengeMap)
        return;

    OnPluginEnd();

    if (!g_bCvar_Enabled)
        return;

    ApplyConfigs();
}

/****************************************************************************************************/

void ApplyConfigs()
{
    if (g_bCvar_BlockGlitchSpot)
    {
        CreateBlocker("anv_mapfixes_blocker_1", view_as<float>({ -864.0, -936.0, 576.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
        CreateBlocker("anv_mapfixes_blocker_2", view_as<float>({ -864.0, 24.0, 576.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
    }

    if (g_bCvar_LadderVisualFix)
    {
        CreateDummyLadder("ladder_visual_fix", view_as<float>({ 1104.0, -940.0, 96.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
    }

    int entity;
    char targetname[22];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "logic_relay")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

        if (g_bCvar_MinigunElevator && StrEqual(targetname, "relay_miniguns_open"))
            AcceptEntityInput(entity, "Trigger");

        if (StrEqual(targetname, "relay_miniguns_close"))
            AcceptEntityInput(entity, g_bCvar_MinigunElevator ? "Disable" : "Enable");
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "func_simpleladder")) != INVALID_ENT_REFERENCE)
    {
        switch (GetEntProp(entity, Prop_Data, "m_iHammerID"))
        {
            case 5796:
            {
                if (g_iCvar_Ladder_5796 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_5796_1", view_as<float>({ 1084.0, 500.0, 32.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_5796_2", view_as<float>({ 1084.0, 500.0, -96.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_5796_3", view_as<float>({ 1084.0, 500.0, -224.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
            }
            case 7033:
            {
                if (g_iCvar_Ladder_7033 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7033_1", view_as<float>({ 1220.0, 397.0, 224.0 }), view_as<float>({ 0.0, 180.0, 0.0 }));
                CreateDummyLadder("ladder_7033_2", view_as<float>({ 1220.0, 397.0, 96.0 }), view_as<float>({ 0.0, 180.0, 0.0 }));
            }
            case 7039:
            {
                if (g_iCvar_Ladder_7039 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7039_1", view_as<float>({ -228.0, 209.0, 224.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7039_2", view_as<float>({ -228.0, 209.0, 96.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
            case 7045:
            {
                if (g_iCvar_Ladder_7045 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7045_1", view_as<float>({ -228.0, -689.0, 224.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7045_2", view_as<float>({ -228.0, -689.0, 96.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
            case 7051:
            {
                if (g_iCvar_Ladder_7051 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7051_1", view_as<float>({ -684.0, 500.0, -32.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_7051_2", view_as<float>({ -684.0, 500.0, -160.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
            }
            case 7057:
            {
                if (g_iCvar_Ladder_7057 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7057_1", view_as<float>({ 108.0, 500.0, 32.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_7057_2", view_as<float>({ 108.0, 500.0, -96.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_7057_3", view_as<float>({ 108.0, 500.0, -224.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
            }
            case 7065:
            {
                if (g_iCvar_Ladder_7065 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7065_1", view_as<float>({ 732.0, 908.0, 32.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7065_2", view_as<float>({ 732.0, 908.0, -96.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7065_3", view_as<float>({ 732.0, 908.0, -224.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
            case 7075:
            {
                if (g_iCvar_Ladder_7075 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7075_1", view_as<float>({ 1212.0, -596.0, 32.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7075_2", view_as<float>({ 1212.0, -596.0, -96.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7075_3", view_as<float>({ 1212.0, -596.0, -224.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
            case 7635:
            {
                if (g_iCvar_Ladder_7635 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_7635_1", view_as<float>({ 1212.0, 60.0, 32.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7635_2", view_as<float>({ 1212.0, 60.0, -96.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_7635_3", view_as<float>({ 1212.0, 60.0, -224.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
            case 17198:
            {
                if (g_iCvar_Ladder_17198 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_17198_1", view_as<float>({ -962.0, -1055.0, 88.0 }), view_as<float>({ 0.0, 230.0, 0.0 }));
                CreateDummyLadder("ladder_17198_2", view_as<float>({ -962.0, -1055.0, -40.0 }), view_as<float>({ 0.0, 230.0, 0.0 }));
                CreateDummyLadder("ladder_17198_3", view_as<float>({ -962.0, -1055.0, -168.0 }), view_as<float>({ 0.0, 230.0, 0.0 }));
            }
            case 17218:
            {
                if (g_iCvar_Ladder_17218 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_17218_1", view_as<float>({ 1140.0, -1092.0, 224.0 }), view_as<float>({ 0.0, 270.0, 0.0 }));
                CreateDummyLadder("ladder_17218_2", view_as<float>({ 1140.0, -1092.0, 96.0 }), view_as<float>({ 0.0, 270.0, 0.0 }));
                CreateDummyLadder("ladder_17218_3", view_as<float>({ 1140.0, -1092.0, -32.0 }), view_as<float>({ 0.0, 270.0, 0.0 }));
                CreateDummyLadder("ladder_17218_4", view_as<float>({ 1140.0, -1092.0, -160.0 }), view_as<float>({ 0.0, 270.0, 0.0 }));
            }
            case 27714:
            {
                if (g_iCvar_Ladder_27714 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_27714_1", view_as<float>({ 1296.0, 660.0, 224.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_27714_2", view_as<float>({ 1296.0, 660.0, 96.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_27714_3", view_as<float>({ 1296.0, 660.0, -32.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
                CreateDummyLadder("ladder_27714_4", view_as<float>({ 1296.0, 660.0, -160.0 }), view_as<float>({ 0.0, 90.0, 0.0 }));
            }
            case 27784:
            {
                if (g_iCvar_Ladder_27784 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_27784_1", view_as<float>({ -1500.0, -488.0, -48.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_27784_2", view_as<float>({ -1500.0, -488.0, -176.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
            case 27791:
            {
                if (g_iCvar_Ladder_27791 < GetRandomInt(0, 100))
                    continue;

                EnableLadderForEveryone(entity);
                CreateDummyLadder("ladder_27791_1", view_as<float>({ -1500.0, -0.0, -48.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
                CreateDummyLadder("ladder_27791_2", view_as<float>({ -1500.0, -0.0, -176.0 }), view_as<float>({ 0.0, 0.0, 0.0 }));
            }
        }
    }
}

/****************************************************************************************************/

void CreateBlocker(char[] targetname, float origin[3], float angles[3])
{
    int entity = CreateEntityByName("env_physics_blocker");
    DispatchKeyValue(entity, "targetname", targetname);
    DispatchKeyValue(entity, "mins", "0 0 0");
    DispatchKeyValue(entity, "maxs", "480 480 340");
    DispatchKeyValue(entity, "initialstate", "1");
    DispatchKeyValue(entity, "BlockType", "1");
    DispatchKeyValueVector(entity, "origin", origin);
    DispatchKeyValueVector(entity, "angles", angles);
    DispatchSpawn(entity);

    if (g_alClip.FindValue(EntIndexToEntRef(entity)) == -1)
        g_alClip.Push(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void EnableLadderForEveryone(int entity)
{
    ge_iTeamNum[entity] = GetEntProp(entity, Prop_Send, "m_iTeamNum");
    SetEntProp(entity, Prop_Send, "m_iTeamNum", 0);

    if (g_alLadder.FindValue(EntIndexToEntRef(entity)) == -1)
        g_alLadder.Push(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void CreateDummyLadder(char[] targetname, float origin[3], float angles[3])
{
    int entity = CreateEntityByName("prop_dynamic");
    DispatchKeyValue(entity, "targetname", targetname);
    DispatchKeyValue(entity, "model", MODEL_METALLADDERBARGE);
    DispatchKeyValue(entity, "disableshadows", "1");
    DispatchKeyValueVector(entity, "origin", origin);
    DispatchKeyValueVector(entity, "angles", angles);
    DispatchSpawn(entity);

    if (g_alDummyLadder.FindValue(EntIndexToEntRef(entity)) == -1)
        g_alDummyLadder.Push(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;

    // Remove clips
    for (int i = 0; i < g_alClip.Length; i++)
    {
        entity = EntRefToEntIndex(g_alClip.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        AcceptEntityInput(entity, "Kill");
    }

    g_alClip.Clear();

    // Remove dummy ladders
    for (int i = 0; i < g_alDummyLadder.Length; i++)
    {
        entity = EntRefToEntIndex(g_alDummyLadder.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        AcceptEntityInput(entity, "Kill");
    }

    g_alDummyLadder.Clear();

    // Restores the default team for the ladders
    for (int i = 0; i < g_alLadder.Length; i++)
    {
        entity = EntRefToEntIndex(g_alLadder.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        SetEntProp(entity, Prop_Send, "m_iTeamNum", ge_iTeamNum[entity]);
    }

    g_alLadder.Clear();
}

/****************************************************************************************************/

Action TimerRemoveWaterEntities(Handle timer)
{
    int entity;
    float vPos[3];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "weapon_*")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

        if (vPos[2] > WATER_ZPOS)
            continue;

        AcceptEntityInput(entity, "Kill");
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

Action TimerTeleportDead(Handle timer)
{
    int entity;
    float vPos[3];

    for (int i = 0; i < g_alSurvivorDeathModel.Length; i++)
    {
        entity = EntRefToEntIndex(g_alSurvivorDeathModel.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

        if (vPos[2] > WATER_ZPOS)
            continue;

        if (GetGameTime() - ge_fCreatedTime[entity] < g_fCvar_TeleportDead)
            continue;

        ge_fCreatedTime[entity] = 0.0;
        g_alSurvivorDeathModel.Erase(i);
        i--;

        switch (g_iCurrentRescue)
        {
            case 1:
            {
                TeleportEntity(entity, g_fvPosSurvivorRescue1, NULL_VECTOR, NULL_VECTOR);
                g_iCurrentRescue = 2;
            }
            case 2:
            {
                TeleportEntity(entity, g_fvPosSurvivorRescue2, NULL_VECTOR, NULL_VECTOR);
                g_iCurrentRescue = 3;
            }
            case 3:
            {
                TeleportEntity(entity, g_fvPosSurvivorRescue3, NULL_VECTOR, NULL_VECTOR);
                g_iCurrentRescue = 1;
            }
            default:
            {
                TeleportEntity(entity, g_fvPosSurvivorRescue1, NULL_VECTOR, NULL_VECTOR);
                g_iCurrentRescue = 1;
            }
        }
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdGlowOutline(int client, int args)
{
    int color[3] = {255, 255, 0};

    int entity;

    for (int i = 0; i < g_alDummyLadder.Length; i++)
    {
        entity = EntRefToEntIndex(g_alDummyLadder.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        ge_iGlowType[entity] = GetEntProp(entity, Prop_Send, "m_iGlowType");
        ge_iGlowColorOverride[entity] = GetEntProp(entity, Prop_Send, "m_glowColorOverride");

        SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
    }

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x05Custom survivor ladders \x04glow\x05 turned \x03ON\x04]");

    CreateTimer(10.0, TimerRemoveGlow, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Handled;
}

/****************************************************************************************************/

Action TimerRemoveGlow(Handle timer, int userid)
{
    int entity;

    for (int i = 0; i < g_alDummyLadder.Length; i++)
    {
        entity = EntRefToEntIndex(g_alDummyLadder.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        SetEntProp(entity, Prop_Send, "m_iGlowType", ge_iGlowType[entity]);
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", ge_iGlowColorOverride[entity]);
    }

    int client = GetClientOfUserId(userid);

    if (client == 0)
        return Plugin_Stop;

    PrintToChat(client, "\x04[\x05Custom survivor ladders \x04glow\x05 turned \x01OFF\x04]");

    return Plugin_Stop;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------- Plugin Cvars (l4d2_tank_challenge_ladder) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_ver : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_remove_from_water : %b (%s)", g_bCvar_RemoveFromWater, g_bCvar_RemoveFromWater ? "true" : "false");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_teleport_dead : %.1f (%s)", g_fCvar_TeleportDead, g_bCvar_TeleportDead ? "true" : "false");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_block_glitch_spot : %b (%s)", g_bCvar_BlockGlitchSpot, g_bCvar_BlockGlitchSpot ? "true" : "false");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_minigun_elevator : %b (%s)", g_bCvar_MinigunElevator, g_bCvar_MinigunElevator ? "true" : "false");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_visual_fix : %b (%s)", g_bCvar_LadderVisualFix, g_bCvar_LadderVisualFix ? "true" : "false");
    PrintToConsole(client, "l4d2_tank_challenge_ladder_5796: %i%%", g_iCvar_Ladder_5796);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7033: %i%%", g_iCvar_Ladder_7033);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7039: %i%%", g_iCvar_Ladder_7039);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7045: %i%%", g_iCvar_Ladder_7045);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7051: %i%%", g_iCvar_Ladder_7051);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7057: %i%%", g_iCvar_Ladder_7057);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7065: %i%%", g_iCvar_Ladder_7065);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7075: %i%%", g_iCvar_Ladder_7075);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_7635: %i%%", g_iCvar_Ladder_7635);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_17198: %i%%", g_iCvar_Ladder_17198);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_17218: %i%%", g_iCvar_Ladder_17218);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_27714: %i%%", g_iCvar_Ladder_27714);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_27784: %i%%", g_iCvar_Ladder_27784);
    PrintToConsole(client, "l4d2_tank_challenge_ladder_27791: %i%%", g_iCvar_Ladder_27791);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    PrintToConsole(client, "Map : %s", mapName);
    PrintToConsole(client, "Is \"Tank Challenge\" map? : %b (%s)", g_bIsTankChallengeMap, g_bIsTankChallengeMap ? "true" : "false");
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