/**
// ====================================================================================================
Change Log:

1.0.2 (13-March-2021)
    - Added glow team cvar. (L4D1 only)

1.0.1 (11-March-2021)
    - Public release.

1.0.0 (22-April-2019)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Dumb Hat"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds a dumb hat for puked survivors"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=331238"

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
#define CONFIG_FILENAME               "l4d_dumb_hat"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_PROP_DYNAMIC_OVERRIDE        "prop_dynamic_override"

#define TEAM_SURVIVOR                 2
#define TEAM_HOLDOUT                  4

#define L4D1_GLOW_TEAM_EVERYONE       -1
#define L4D1_GLOW_TEAM_NONE           0
#define L4D1_GLOW_TEAM_SURVIVOR       2
#define L4D1_GLOW_TEAM_INFECTED       3

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_survivor_it_duration;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Model;
static ConVar g_hCvar_Pos;
static ConVar g_hCvar_Angles;
static ConVar g_hCvar_Color;
static ConVar g_hCvar_Alpha;
static ConVar g_hCvar_GlowColor;
static ConVar g_hCvar_GlowType;
static ConVar g_hCvar_GlowFlashing;
static ConVar g_hCvar_GlowMinDistance;
static ConVar g_hCvar_GlowMaxDistance;
static ConVar g_hCvar_GlowMinBrightness;
static ConVar g_hCvar_GlowL4D1;
static ConVar g_hCvar_GlowTeamL4D1;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_RandomColor;
static bool   g_bCvar_Alpha;
static bool   g_bCvar_RandomGlowColor;
static bool   g_bCvar_GlowType;
static bool   g_bCvar_GlowFlashing;
static bool   g_bCvar_GlowL4D1;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Color[3];
static int    g_iCvar_Alpha;
static int    g_iCvar_GlowColor[3];
static int    g_iCvar_GlowType;
static int    g_iCvar_GlowMinDistance;
static int    g_iCvar_GlowMaxDistance;
static int    g_iCvar_GlowTeamL4D1;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_survivor_it_duration;
static float  g_fCvar_Pos[3];
static float  g_fCvar_Angles[3];
static float  g_fCvar_MinBrightness;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_Model[100];
static char   g_sCvar_Pos[24];
static char   g_sCvar_Angles[24];
static char   g_sCvar_Color[12];
static char   g_sCvar_GlowColor[12];
static char   g_sCvar_GlowTeamL4D1[3];
static char   g_sKillInput[100];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static int    g_iHatEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE , ... };
static int    g_iHatGlowEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE , ... };

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
    g_hCvar_survivor_it_duration = FindConVar("survivor_it_duration");

    CreateConVar("l4d_dumb_hat_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled               = CreateConVar("l4d_dumb_hat_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Model                 = CreateConVar("l4d_dumb_hat_model", "models/editor/spot_cone.mdl", "Hat model.");
    g_hCvar_Pos                   = CreateConVar("l4d_dumb_hat_pos", g_bL4D2 ? "-8.00 0.00 18.00" : "-5.00 0.00 9.00", "Hat position relative to the eyes attachment.\nUse three values (000.00) separated by spaces (\"<000.00> <000.00> <000.00>\").", CVAR_FLAGS);
    g_hCvar_Angles                = CreateConVar("l4d_dumb_hat_angles", g_bL4D2 ? "-15.00 0.00 -90.00" : "75.00 0.00 0.00", "Hat angles relative to the eyes attachment.\nUse three values (000.00) separated by spaces (\"<000.00> <000.00> <000.00>\").", CVAR_FLAGS);
    g_hCvar_Color                 = CreateConVar("l4d_dumb_hat_color", "255 255 255", "Hat color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_Alpha                 = CreateConVar("l4d_dumb_hat_alpha", "255", "Hat alpha transparency.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
    if (g_bL4D2)
    {
        g_hCvar_GlowColor         = CreateConVar("l4d_dumb_hat_glow_color", "51 255 51", "Hat glow color.\nL4D2 only.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
        g_hCvar_GlowType          = CreateConVar("l4d_dumb_hat_glow_type", "2", "Hat glow type.\nL4D2 only.\n0 = OFF, 1 = OnUse (doesn't works), 2 = OnLookAt (doesn't works well for some entities), 3 = Constant (better results but visible through walls).", CVAR_FLAGS, true, 0.0, true, 3.0);
        g_hCvar_GlowFlashing      = CreateConVar("l4d_dumb_hat_glow_flashing", "1", "Add a flashing effect to the hat.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_GlowMinDistance   = CreateConVar("l4d_dumb_hat_glow_min_distance", "0", "Minimum distance that the client must be from the hat to start glowing.\nL4D2 only.\n0 = No minimum distance.", CVAR_FLAGS, true, 0.0);
        g_hCvar_GlowMaxDistance   = CreateConVar("l4d_dumb_hat_glow_max_distance", "0", "Maximum distance that the client can be away from the hat to start glowing.\nL4D2 only.\n0 = No maximum distance.", CVAR_FLAGS, true, 0.0);
        g_hCvar_GlowMinBrightness = CreateConVar("l4d_dumb_hat_glow_min_brightness", "0.5", "Algorithm value to detect the glow minimum brightness for a random glow (not accurate).\nL4D2 only.", CVAR_FLAGS, true, 0.0, true, 1.0);
    }
    g_hCvar_GlowL4D1              = CreateConVar("l4d_dumb_hat_glow_l4d1", "1", "Enable hat glow (in white).\nL4D1 only.\nNote: Some models aren't able to apply glow.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlowTeamL4D1          = CreateConVar("l4d_dumb_hat_glow_team_l4d1", "3", "Which teams should see the hat glowing.\nL4D1 only.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 3 = BOTH.", CVAR_FLAGS, true, 0.0, true, 3.0);

    // Hook plugin ConVars change
    g_hCvar_survivor_it_duration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Model.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pos.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Angles.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Color.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Alpha.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_GlowColor.AddChangeHook(Event_ConVarChanged);
        g_hCvar_GlowType.AddChangeHook(Event_ConVarChanged);
        g_hCvar_GlowFlashing.AddChangeHook(Event_ConVarChanged);
        g_hCvar_GlowMinDistance.AddChangeHook(Event_ConVarChanged);
        g_hCvar_GlowMaxDistance.AddChangeHook(Event_ConVarChanged);
        g_hCvar_GlowMinBrightness.AddChangeHook(Event_ConVarChanged);
    }
    else
    {
        g_hCvar_GlowL4D1.AddChangeHook(Event_ConVarChanged);
        g_hCvar_GlowTeamL4D1.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_dumbhat", CmdDumbHat, ADMFLAG_ROOT, "Add a temporary dumb hat on self (no args) or specified targets. Survivors only. Example: self -> sm_dumbhat / target -> sm_dumbhat @bots");
    RegAdminCmd("sm_print_cvars_l4d_dumb_hat", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        RemoveHat(client);
    }
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

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
    g_fCvar_survivor_it_duration = g_hCvar_survivor_it_duration.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_hCvar_Model.GetString(g_sCvar_Model, sizeof(g_sCvar_Model));
    TrimString(g_sCvar_Model);
    PrecacheModel(g_sCvar_Model, true);
    g_hCvar_Pos.GetString(g_sCvar_Pos, sizeof(g_sCvar_Pos));
    TrimString(g_sCvar_Pos);
    g_fCvar_Pos = ConvertVectorStringToFloatArray(g_sCvar_Pos);
    g_hCvar_Angles.GetString(g_sCvar_Angles, sizeof(g_sCvar_Angles));
    TrimString(g_sCvar_Angles);
    g_fCvar_Angles = ConvertVectorStringToFloatArray(g_sCvar_Angles);
    g_hCvar_Color.GetString(g_sCvar_Color, sizeof(g_sCvar_Color));
    TrimString(g_sCvar_Color);
    StringToLowerCase(g_sCvar_Color);
    g_bCvar_RandomColor = StrEqual(g_sCvar_Color, "random");
    g_iCvar_Color = ConvertRGBToIntArray(g_sCvar_Color);
    g_iCvar_Alpha = g_hCvar_Alpha.IntValue;
    g_bCvar_Alpha = (g_iCvar_Alpha != 255);
    if (g_bL4D2)
    {
        g_hCvar_GlowColor.GetString(g_sCvar_GlowColor, sizeof(g_sCvar_GlowColor));
        TrimString(g_sCvar_GlowColor);
        StringToLowerCase(g_sCvar_GlowColor);
        g_bCvar_RandomGlowColor = StrEqual(g_sCvar_GlowColor, "random");
        g_iCvar_GlowColor = ConvertRGBToIntArray(g_sCvar_GlowColor);
        g_iCvar_GlowType = g_hCvar_GlowType.IntValue;
        g_bCvar_GlowType = (g_iCvar_GlowType > 0);
        g_bCvar_GlowFlashing = g_hCvar_GlowFlashing.BoolValue;
        g_iCvar_GlowMinDistance = g_hCvar_GlowMinDistance.IntValue;
        g_iCvar_GlowMaxDistance = g_hCvar_GlowMaxDistance.IntValue;
        g_fCvar_MinBrightness = g_hCvar_GlowMinBrightness.FloatValue;
    }
    else
    {
        g_bCvar_GlowL4D1 = g_hCvar_GlowL4D1.BoolValue;
        g_iCvar_GlowTeamL4D1 = g_hCvar_GlowTeamL4D1.IntValue;
        switch (g_iCvar_GlowTeamL4D1)
        {
            case 0: FormatEx(g_sCvar_GlowTeamL4D1, sizeof(g_sCvar_GlowTeamL4D1), "%i", L4D1_GLOW_TEAM_NONE);
            case 1: FormatEx(g_sCvar_GlowTeamL4D1, sizeof(g_sCvar_GlowTeamL4D1), "%i", L4D1_GLOW_TEAM_SURVIVOR);
            case 2: FormatEx(g_sCvar_GlowTeamL4D1, sizeof(g_sCvar_GlowTeamL4D1), "%i", L4D1_GLOW_TEAM_INFECTED);
            case 3: FormatEx(g_sCvar_GlowTeamL4D1, sizeof(g_sCvar_GlowTeamL4D1), "%i", L4D1_GLOW_TEAM_EVERYONE);
        }
    }

    FormatEx(g_sKillInput, sizeof(g_sKillInput), "OnUser1 !self:Kill::%.2f:-1", g_fCvar_survivor_it_duration);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    RemoveHat(client);
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_now_it", Event_PlayerNowIt);
        HookEvent("player_no_longer_it", Event_PlayerNoLongerIt);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("player_team", Event_PlayerTeam);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_now_it", Event_PlayerNowIt);
        UnhookEvent("player_no_longer_it", Event_PlayerNoLongerIt);
        UnhookEvent("player_death", Event_PlayerDeath);
        UnhookEvent("player_team", Event_PlayerTeam);

        return;
    }
}

/****************************************************************************************************/

public void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsValidClient(client))
        return;

    CreateHat(client);
}

/****************************************************************************************************/

public void Event_PlayerNoLongerIt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    RemoveHat(client);
}

/****************************************************************************************************/

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    RemoveHat(client);
}

/****************************************************************************************************/

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client))
        return;

    RemoveHat(client);
}

/****************************************************************************************************/

void RemoveHat(int client)
{
    if (g_iHatEntRef[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iHatEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
            AcceptEntityInput(entity, "Kill");

        g_iHatEntRef[client] = INVALID_ENT_REFERENCE;
    }

    if (g_iHatGlowEntRef[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iHatGlowEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
            AcceptEntityInput(entity, "Kill");

        g_iHatGlowEntRef[client] = INVALID_ENT_REFERENCE;
    }
}

/****************************************************************************************************/

void CreateHat(int client)
{
    if (GetClientTeam(client) != TEAM_SURVIVOR && GetClientTeam(client) != TEAM_HOLDOUT)
        return;

    if (!IsPlayerAlive(client))
        return;

    if (g_iHatEntRef[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iHatEntRef[client]);

        if (entity != INVALID_ENT_REFERENCE)
            RemoveHat(client);
    }

    int entity = CreateEntityByName(CLASSNAME_PROP_DYNAMIC_OVERRIDE);
    g_iHatEntRef[client] = EntIndexToEntRef(entity);
    DispatchKeyValue(entity, "targetname", "l4d_dumb_hat");
    SetEntityModel(entity, g_sCvar_Model);

    DispatchSpawn(entity);

    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", client);
    SetVariantString("eyes");
    AcceptEntityInput(entity, "SetParentAttachment");
    TeleportEntity(entity, g_fCvar_Pos, g_fCvar_Angles, NULL_VECTOR);

    SetVariantString(g_sKillInput);
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    AcceptEntityInput(entity, "DisableCollision");
    SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1);
    SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
    SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
    SetEntPropVector(entity, Prop_Send, "m_vecMins", NULL_VECTOR);
    SetEntPropVector(entity, Prop_Send, "m_vecMaxs", NULL_VECTOR);

    SetEntityRenderMode(entity, g_bCvar_Alpha ? RENDER_TRANSCOLOR : RENDER_NORMAL);

    if (g_bCvar_RandomColor)
        SetEntityRenderColor(entity, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), g_iCvar_Alpha);
    else
        SetEntityRenderColor(entity, g_iCvar_Color[0], g_iCvar_Color[1], g_iCvar_Color[2], g_iCvar_Alpha);

    if (g_bCvar_GlowType)
    {
        int glowColor[3];

        if (g_bCvar_RandomGlowColor)
        {
            do
            {
                glowColor[0] = GetRandomInt(0,255);
                glowColor[1] = GetRandomInt(0,255);
                glowColor[2] = GetRandomInt(0,255);
            }
            while (GetRGB_Brightness(glowColor) < g_fCvar_MinBrightness);
        }
        else
        {
            glowColor[0] = g_iCvar_GlowColor[0];
            glowColor[1] = g_iCvar_GlowColor[1];
            glowColor[2] = g_iCvar_GlowColor[2];
        }

        SetEntProp(entity, Prop_Send, "m_iGlowType", g_iCvar_GlowType);
        SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvar_GlowMaxDistance);
        SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", g_iCvar_GlowMinDistance);
        SetEntProp(entity, Prop_Send, "m_bFlashing", g_bCvar_GlowFlashing);
        SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowColor[0] + (glowColor[1] * 256) + (glowColor[2] * 65536));
    }

    SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitHat);

    if (g_bCvar_GlowL4D1)
        CreatePropGlow(client);
}

/****************************************************************************************************/

void CreatePropGlow(int client)
{
    int entity = CreateEntityByName("prop_glowing_object");
    g_iHatGlowEntRef[client] = EntIndexToEntRef(entity);
    DispatchKeyValue(entity, "model", g_sCvar_Model);
    DispatchKeyValue(entity, "targetname", "l4d_dumb_hat");
    DispatchKeyValue(entity, "GlowForTeam", g_sCvar_GlowTeamL4D1);

    DispatchSpawn(entity);

    SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
    SetEntityRenderColor(entity, 0, 0, 0, 0);

    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", client);
    SetVariantString("eyes");
    AcceptEntityInput(entity, "SetParentAttachment");
    TeleportEntity(entity, g_fCvar_Pos, g_fCvar_Angles, NULL_VECTOR);

    SetVariantString(g_sKillInput);
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitHatGlow);
}

/****************************************************************************************************/

public Action Hook_SetTransmitHat(int entity, int client)
{
    if (EntIndexToEntRef(entity) == g_iHatEntRef[client])
        return Plugin_Handled;

    return Plugin_Continue;
}

/****************************************************************************************************/

public Action Hook_SetTransmitHatGlow(int entity, int client)
{
    if (EntIndexToEntRef(entity) == g_iHatGlowEntRef[client])
        return Plugin_Handled;

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdDumbHat(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args == 0) // self
    {
        CreateHat(client);
        return Plugin_Handled;
    }
    else // specified target
    {
        char sArg[64];
        GetCmdArg(1, sArg, sizeof(sArg));

        char target_name[MAX_TARGET_LENGTH];
        int target_list[MAXPLAYERS];
        int target_count;
        bool tn_is_ml;

        if ((target_count = ProcessTargetString(
            sArg,
            client,
            target_list,
            sizeof(target_list),
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            return Plugin_Handled;
        }

        for (int i = 0; i < target_count; i++)
        {
            CreateHat(target_list[i]);
        }
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_dumb_hat) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_dumb_hat_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_dumb_hat_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_dumb_hat_model : \"%s\"", g_sCvar_Model);
    PrintToConsole(client, "l4d_dumb_hat_pos : %.2f %.2f %.2f", g_fCvar_Pos[0], g_fCvar_Pos[1], g_fCvar_Pos[2]);
    PrintToConsole(client, "l4d_dumb_hat_angles : %.2f %.2f %.2f", g_fCvar_Angles[0], g_fCvar_Angles[1], g_fCvar_Angles[2]);
    PrintToConsole(client, "l4d_dumb_hat_color : \"%s\"", g_sCvar_Color);
    PrintToConsole(client, "l4d_dumb_hat_alpha : %i (%s)", g_iCvar_Alpha, g_bCvar_Alpha ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_color : \"%s\"", g_sCvar_GlowColor);
    if (g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_type : %i (%s)", g_iCvar_GlowType, g_bCvar_GlowType ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_flashing : %b (%s)", g_bCvar_GlowFlashing, g_bCvar_GlowFlashing ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_min_distance : %i", g_iCvar_GlowMinDistance);
    if (g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_max_distance : %i", g_iCvar_GlowMaxDistance);
    if (g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_min_brightness : %.2f", g_fCvar_MinBrightness);
    if (!g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_l4d1 : %b (%s)", g_bCvar_GlowL4D1, g_bCvar_GlowL4D1 ? "true" : "false");
    if (!g_bL4D2) PrintToConsole(client, "l4d_dumb_hat_glow_team_l4d1 : %i (%s)", g_iCvar_GlowTeamL4D1, g_iCvar_GlowTeamL4D1 == 0 ? "NONE" : g_iCvar_GlowTeamL4D1 == 1 ? "SURVIVOR" : g_iCvar_GlowTeamL4D1 == 2 ? "INFECTED" : "EVERYONE");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "survivor_it_duration : %.2f", g_fCvar_survivor_it_duration);
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

/****************************************************************************************************/

/**
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
float[] ConvertVectorStringToFloatArray(char[] sVector)
{
    float vector[3];

    if (sVector[0] == 0)
        return vector;

    char sVectors[3][8];
    int count = ExplodeString(sVector, " ", sVectors, sizeof(sVectors), sizeof(sVectors[]));

    switch (count)
    {
        case 1:
        {
            vector[0] = StringToFloat(sVectors[0]);
        }
        case 2:
        {
            vector[0] = StringToFloat(sVectors[0]);
            vector[1] = StringToFloat(sVectors[1]);
        }
        case 3:
        {
            vector[0] = StringToFloat(sVectors[0]);
            vector[1] = StringToFloat(sVectors[1]);
            vector[2] = StringToFloat(sVectors[2]);
        }
    }

    return vector;
}

/****************************************************************************************************/

/**
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}

/****************************************************************************************************/

/**
 * Source: https://stackoverflow.com/a/12216661
 * Returns the RGB brightness of a RGB integer array value.
 *
 * @param rgb           RGB integer array (int[3]).
 * @return              Brightness float value between 0.0 and 1.0.
 */
public float GetRGB_Brightness(int[] rgb)
{
    int r = rgb[0];
    int g = rgb[1];
    int b = rgb[2];

    int cmax = (r > g) ? r : g;
    if (b > cmax) cmax = b;
    return cmax / 255.0;
}