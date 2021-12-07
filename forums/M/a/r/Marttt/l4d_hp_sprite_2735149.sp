/**
// ====================================================================================================
Change Log:

1.1.2 (03-May-2021)
    - Added cvar to control the timer interval for the rendering rules.

1.1.1 (23-February-2021)
    - Fixed sprite hiding behind witches and infecteds.
    - Code optimization.

1.1.0 (22-February-2021)
    - Added cvar to change the gradient color to default game colors on survivors. (Green 40HP+, Yellow 39HP~25HP, Red 24HP-)
    - Added menu and commands to hide/show the sprite.
    - Added cvar to remove blur effect behind walls. (thanks "kadabra" for requesting)
    - Added cvar and Fast Wide Pulse FX for survivors when: incapacitated; black and white; low health (24HP-).

1.0.9 (18-February-2021)
    - Added cvar to set the maximum alpha that a client must be to hide the sprite.

1.0.8 (18-February-2021)
    - Added cvar to multiply the sprite alpha based on client render alpha.

1.0.7 (16-February-2021)
    - Plugin renamed.
    - Added support to survivors and to all SI.
    - Fixed a wrong behaviour when attack delay visibility cvar was enabled.

1.0.6 (12-February-2021)
    - Fixed custom model cvar typo. (thanks "weffer" for reporting)

1.0.5 (11-February-2021)
    - Fixed a bug not rendering custom sprites right after turning it on.
    - Added one more custom sprite option with an alpha background filling the bar.

1.0.4 (11-February-2021)
    - Added custom sprite option.

1.0.3 (08-February-2021)
    - Fixed missing client in-game in visibility check. (thanks to "Krufftys Killers" and "Striker black")

1.0.2 (08-February-2021)
    - Fixed wrong value on max health calculation.
    - Fixed sprite hiding behind tank rocks.
    - Fixed sprite hiding while tank throws rocks (ability use).
    - Moved visibility logic to timer handle.

1.0.1 (30-January-2021)
    - Public release.

1.0.0 (21-April-2019)
    - Private version.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] HP Sprite"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Shows a sprite at the client head based on its HP"
#define PLUGIN_VERSION                "1.1.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330370"

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
#include <clientprefs>

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
#define CONFIG_FILENAME               "l4d_hp_sprite"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_ENV_SPRITE          "env_sprite"
#define CLASSNAME_ENV_TEXTURETOGGLE   "env_texturetoggle"
#define CLASSNAME_INFO_TARGET         "info_target"

#define CLASSNAME_TANK_ROCK           "tank_rock"
#define CLASSNAME_INFECTED            "infected"
#define CLASSNAME_WITCH               "witch"

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

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

#define FLAG_PULSE_INCAPACITATED      1
#define FLAG_PULSE_BLACK_AND_WHITE    2
#define FLAG_PULSE_LOW_HEALTH         4

#define MAXENTITIES                   2048

#define LOW_HEALTH                    24

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_survivor_incap_health;
static ConVar g_hCvar_survivor_max_incapacitated_count;
static ConVar g_hCvar_pain_pills_decay_rate;
static ConVar g_hCvar_survivor_limp_health;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Cookies;
static ConVar g_hCvar_RenderInterval;
static ConVar g_hCvar_ZAxis;
static ConVar g_hCvar_FadeDistance;
static ConVar g_hCvar_Sight;
static ConVar g_hCvar_AttackDelay;
static ConVar g_hCvar_GradientColor;
static ConVar g_hCvar_AliveShow;
static ConVar g_hCvar_AliveModel;
static ConVar g_hCvar_AliveAlpha;
static ConVar g_hCvar_AliveScale;
static ConVar g_hCvar_DeadShow;
static ConVar g_hCvar_DeadModel;
static ConVar g_hCvar_DeadAlpha;
static ConVar g_hCvar_DeadScale;
static ConVar g_hCvar_DeadColor;
static ConVar g_hCvar_RemoveBlur;
static ConVar g_hCvar_Pulse;
static ConVar g_hCvar_BlackAndWhite;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_SurvivorTeam;
static ConVar g_hCvar_InfectedTeam;
static ConVar g_hCvar_SpectatorTeam;
static ConVar g_hCvar_MultiplyAlphaTeam;
static ConVar g_hCvar_ClientAlphaMax;
static ConVar g_hCvar_CustomModel;
static ConVar g_hCvar_CustomModelVMT;
static ConVar g_hCvar_CustomModelVTF;
static ConVar g_hCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_survivor_max_incapacitated_count;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Cookies;
static bool   g_bCvar_Sight;
static bool   g_bCvar_AttackDelay;
static bool   g_bCvar_GradientColor;
static bool   g_bCvar_AliveShow;
static bool   g_bCvar_DeadShow;
static bool   g_bCvar_RemoveBlur;
static bool   g_bCvar_BlackAndWhite;
static bool   g_bCvar_ClientAlphaMax;
static bool   g_bCvar_CustomModel;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_survivor_incap_health;
static int    g_iCvar_survivor_max_incapacitated_count;
static int    g_iCvar_survivor_limp_health;
static int    g_iCvar_FadeDistance;
static int    g_iCvar_AliveAlpha;
static int    g_iCvar_DeadAlpha;
static int    g_iCvar_Pulse;
static int    g_iCvar_Team;
static int    g_iCvar_SurvivorTeam;
static int    g_iCvar_InfectedTeam;
static int    g_iCvar_SpectatorTeam;
static int    g_iCvar_MultiplyAlphaTeam;
static int    g_iCvar_ClientAlphaMax;
static int    g_iCvar_SI;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fvPlayerMins[3] = {-16.0, -16.0,  0.0};
static float  g_fvPlayerMaxs[3] = { 16.0,  16.0, 71.0};
static float  g_fCvar_pain_pills_decay_rate;
static float  g_fCvar_RenderInterval;
static float  g_fCvar_ZAxis;
static float  g_fCvar_AttackDelay;
static float  g_fCvar_AliveScale;
static float  g_fCvar_DeadScale;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_AliveModel[100];
static char   g_sCvar_AliveAlpha[4];
static char   g_sCvar_AliveScale[5];
static char   g_sCvar_DeadModel[100];
static char   g_sCvar_DeadAlpha[4];
static char   g_sCvar_DeadScale[5];
static char   g_sCvar_DeadColor[12];
static char   g_sCvar_FadeDistance[5];
static char   g_sCvar_CustomModelVMT[100];
static char   g_sCvar_CustomModelVTF[100];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static bool   gc_bDisable[MAXPLAYERS+1];
static bool   gc_bShouldRender[MAXPLAYERS+1];
static int    gc_iSpriteEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
static int    gc_iSpriteFrameEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
static int    gc_iSpriteInfoTargetEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
static bool   gc_bVisible[MAXPLAYERS+1][MAXPLAYERS+1];
static float  gc_fLastAttack[MAXPLAYERS+1][MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bInvalidTrace[MAXENTITIES+1];
static int    ge_iOwner[MAXENTITIES+1];

// ====================================================================================================
// Cookies - Plugin Variables
// ====================================================================================================
static Cookie g_cbDisable;

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tRenderInterval;

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
    g_hCvar_survivor_incap_health = FindConVar("survivor_incap_health");
    g_hCvar_survivor_max_incapacitated_count = FindConVar("survivor_max_incapacitated_count");
    g_hCvar_pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
    g_hCvar_survivor_limp_health = FindConVar("survivor_limp_health");

    CreateConVar("l4d_hp_sprite_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled           = CreateConVar("l4d_hp_sprite_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Cookies           = CreateConVar("l4d_hp_sprite_cookies", "1", "Allow cookies for storing client preferences.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RenderInterval    = CreateConVar("l4d_hp_sprite_render_interval", "0.1", "Interval in seconds to check the sprite rendering rules. (visibility, color and frame)", CVAR_FLAGS, true, 0.1);
    g_hCvar_ZAxis             = CreateConVar("l4d_hp_sprite_z_axis", "92", "Additional Z axis distance of the sprite based on client position.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FadeDistance      = CreateConVar("l4d_hp_sprite_fade_distance", "-1", "Minimum distance that a client must be from another client to see the sprite.\n-1 = Always visible.", CVAR_FLAGS, true, -1.0, true, 9999.0);
    g_hCvar_Sight             = CreateConVar("l4d_hp_sprite_sight", "1", "Show the sprite to the survivor only if the special infected is on sight.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AttackDelay       = CreateConVar("l4d_hp_sprite_attack_delay", "0.0", "Show the sprite to the survivor attacker, by this amount of time in seconds, after hitting a special infected.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GradientColor     = CreateConVar("l4d_hp_sprite_gradient_color", "0", "Should the sprite on survivors render in gradient color. \n0 = OFF. (Vanilla Colors: Green 100HP->40HP, Yellow 39HP->25HP, Red 25HP-), 1 = Gradient Mode.\nNote: The yellow color is defined by the \"survivor_limp_health\" game cvar.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AliveShow         = CreateConVar("l4d_hp_sprite_alive_show", "1", "Show the alive sprite while client is alive.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_AliveModel        = CreateConVar("l4d_hp_sprite_alive_model", "materials/vgui/healthbar_white.vmt", "Model of alive sprite.");
    g_hCvar_AliveAlpha        = CreateConVar("l4d_hp_sprite_alive_alpha", "200", "Alpha of alive sprite.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_AliveScale        = CreateConVar("l4d_hp_sprite_alive_scale", "0.25", "Scale of alive sprite (increases both height and width).\nNote: Some range values maintain the same size. (e.g. from 0.0 to 0.38 the size doesn't change).", CVAR_FLAGS, true, 0.0);
    g_hCvar_DeadShow          = CreateConVar("l4d_hp_sprite_dead_show", "1", "Show the dead sprite when a client dies.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DeadModel         = CreateConVar("l4d_hp_sprite_dead_model", "materials/sprites/death_icon.vmt", "Model of dead sprite.");
    g_hCvar_DeadAlpha         = CreateConVar("l4d_hp_sprite_dead_alpha", "200", "Alpha of dead sprite.\n0 = Invisible, 255 = Fully Visible", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_DeadScale         = CreateConVar("l4d_hp_sprite_dead_scale", "0.25", "Scale of dead sprite (increases both height and width).\nSome range values maintain the size the same.", CVAR_FLAGS, true, 0.0);
    g_hCvar_DeadColor         = CreateConVar("l4d_hp_sprite_dead_color", "225 0 0", "Color of dead sprite.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_RemoveBlur        = CreateConVar("l4d_hp_sprite_remove_blur", "1", "Removes the blur effect while behind walls.\nNote: This creates an extra entity for each sprite.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Pulse             = CreateConVar("l4d_hp_sprite_pulse", "7", "Which condition should the sprite pulse on survivors.\n0 = OFF, 1 = Incapacitated, 2 = Black and White, 4 = Low health (24HP-).\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for Incapacitated and Black and White survivors.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_BlackAndWhite     = CreateConVar("l4d_hp_sprite_black_and_white", "1", "Show the alive sprite in white on \"black and white\" survivors.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team              = CreateConVar("l4d_hp_sprite_team", "3", "Which teams should the sprite be visible.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_SurvivorTeam      = CreateConVar("l4d_hp_sprite_survivor_team", "3", "Which teams survivors can see the sprite.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_InfectedTeam      = CreateConVar("l4d_hp_sprite_infected_team", "3", "Which teams infected can see the sprite.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_SpectatorTeam     = CreateConVar("l4d_hp_sprite_spectator_team", "3", "Which teams spectators can see the sprite.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_MultiplyAlphaTeam = CreateConVar("l4d_hp_sprite_multiply_alpha_team", "2", "Which teams should multiply the sprite alpha based on the client render alpha.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_ClientAlphaMax    = CreateConVar("l4d_hp_sprite_client_alpha_max", "0", "Maximum render alpha that a client must be to hide the sprite.\nUseful to hide it on invisible/transparent clients.\n-1 = OFF.", CVAR_FLAGS, true, -1.0, true, 255.0);
    g_hCvar_CustomModel       = CreateConVar("l4d_hp_sprite_custom_model", "0", "Use a custom sprite for the alive model\nNote: This creates an extra entity for each sprite.\nNote: This requires the client downloading the custom model (.vmt and .vtf) to work.\nSearch for FastDL for more info.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_CustomModelVMT    = CreateConVar("l4d_hp_sprite_custom_model_vmt", "materials/mart/mart_custombar.vmt", "Custom sprite VMT path.");
    g_hCvar_CustomModelVTF    = CreateConVar("l4d_hp_sprite_custom_model_vtf", "materials/mart/mart_custombar.vtf", "Custom sprite VTF path.");

    if (g_bL4D2)
        g_hCvar_SI            = CreateConVar("l4d_hp_sprite_si", "64", "Which special infected should have a sprite.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", enables sprite for all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);
    else
        g_hCvar_SI            = CreateConVar("l4d_hp_sprite_si", "8", "Which special infected should have a sprite.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", enables sprite for all SI.", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook plugin ConVars change
    g_hCvar_survivor_incap_health.AddChangeHook(Event_ConVarChanged);
    g_hCvar_survivor_max_incapacitated_count.AddChangeHook(Event_ConVarChanged);
    g_hCvar_pain_pills_decay_rate.AddChangeHook(Event_ConVarChanged);
    g_hCvar_survivor_limp_health.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cookies.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RenderInterval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ZAxis.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FadeDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sight.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AttackDelay.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GradientColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AliveShow.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AliveModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AliveAlpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AliveScale.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeadShow.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeadModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeadAlpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeadScale.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeadColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RemoveBlur.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Pulse.AddChangeHook(Event_ConVarChanged);
    g_hCvar_BlackAndWhite.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SurvivorTeam.AddChangeHook(Event_ConVarChanged);
    g_hCvar_InfectedTeam.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpectatorTeam.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MultiplyAlphaTeam.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ClientAlphaMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CustomModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CustomModelVMT.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CustomModelVTF.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Cookies
    g_cbDisable = new Cookie("l4d_hp_sprite_disable", "HP Sprite - Disable sprite HP", CookieAccess_Protected);

    // Public Commands
    RegConsoleCmd("sm_hpsprite", CmdHpMenu, "Open a menu to toogle the sprite HP for the client.");
    RegConsoleCmd("sm_hidehpsprite", CmdHideHp, "Disable sprite HP for the client.");
    RegConsoleCmd("sm_showhpsprite", CmdShowHp, "Enable sprite HP for the client.");

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_hp_sprite", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_iSpriteEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iSpriteEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iSpriteFrameEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iSpriteFrameEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iSpriteFrameEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iSpriteInfoTargetEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iSpriteInfoTargetEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iSpriteInfoTargetEntRef[client] = INVALID_ENT_REFERENCE;
        }
    }
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);

    delete g_tRenderInterval;
    g_tRenderInterval = CreateTimer(g_fCvar_RenderInterval, TimerRender, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);

    delete g_tRenderInterval;
    g_tRenderInterval = CreateTimer(g_fCvar_RenderInterval, TimerRender, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void GetCvars()
{
    g_iCvar_survivor_incap_health = g_hCvar_survivor_incap_health.IntValue;
    g_iCvar_survivor_max_incapacitated_count = g_hCvar_survivor_max_incapacitated_count.IntValue;
    g_bCvar_survivor_max_incapacitated_count = (g_iCvar_survivor_max_incapacitated_count > 0);
    g_iCvar_survivor_limp_health = g_hCvar_survivor_limp_health.IntValue;
    g_fCvar_pain_pills_decay_rate = g_hCvar_pain_pills_decay_rate.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_Cookies = g_hCvar_Cookies.BoolValue;
    g_fCvar_RenderInterval = g_hCvar_RenderInterval.FloatValue;
    g_fCvar_ZAxis = g_hCvar_ZAxis.FloatValue;
    g_iCvar_FadeDistance = g_hCvar_FadeDistance.IntValue;
    FormatEx(g_sCvar_FadeDistance, sizeof(g_sCvar_FadeDistance), "%i", g_iCvar_FadeDistance);
    g_bCvar_Sight = g_hCvar_Sight.BoolValue;
    g_fCvar_AttackDelay = g_hCvar_AttackDelay.FloatValue;
    g_bCvar_AttackDelay = (g_fCvar_AttackDelay > 0.0);
    g_bCvar_GradientColor = g_hCvar_GradientColor.BoolValue;
    g_bCvar_AliveShow = g_hCvar_AliveShow.BoolValue;
    g_hCvar_AliveModel.GetString(g_sCvar_AliveModel, sizeof(g_sCvar_AliveModel));
    TrimString(g_sCvar_AliveModel);
    g_iCvar_AliveAlpha = g_hCvar_AliveAlpha.IntValue;
    FormatEx(g_sCvar_AliveAlpha, sizeof(g_sCvar_AliveAlpha), "%i", g_iCvar_AliveAlpha);
    g_fCvar_AliveScale = g_hCvar_AliveScale.FloatValue;
    FormatEx(g_sCvar_AliveScale, sizeof(g_sCvar_AliveScale), "%.2f", g_fCvar_AliveScale);
    g_bCvar_DeadShow = g_hCvar_DeadShow.BoolValue;
    g_hCvar_DeadModel.GetString(g_sCvar_DeadModel, sizeof(g_sCvar_DeadModel));
    TrimString(g_sCvar_DeadModel);
    g_iCvar_DeadAlpha = g_hCvar_DeadAlpha.IntValue;
    FormatEx(g_sCvar_DeadAlpha, sizeof(g_sCvar_DeadAlpha), "%i", g_iCvar_DeadAlpha);
    g_fCvar_DeadScale = g_hCvar_DeadScale.FloatValue;
    FormatEx(g_sCvar_DeadScale, sizeof(g_sCvar_DeadScale), "%.2f", g_fCvar_DeadScale);
    g_hCvar_DeadColor.GetString(g_sCvar_DeadColor, sizeof(g_sCvar_DeadColor));
    TrimString(g_sCvar_DeadColor);
    g_bCvar_RemoveBlur = g_hCvar_RemoveBlur.BoolValue;
    g_iCvar_Pulse = g_hCvar_Pulse.IntValue;
    g_bCvar_BlackAndWhite = g_hCvar_BlackAndWhite.BoolValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_iCvar_SurvivorTeam = g_hCvar_SurvivorTeam.IntValue;
    g_iCvar_InfectedTeam = g_hCvar_InfectedTeam.IntValue;
    g_iCvar_SpectatorTeam = g_hCvar_SpectatorTeam.IntValue;
    g_iCvar_MultiplyAlphaTeam = g_hCvar_MultiplyAlphaTeam.IntValue;
    g_iCvar_ClientAlphaMax = g_hCvar_ClientAlphaMax.IntValue;
    g_bCvar_ClientAlphaMax = (g_iCvar_ClientAlphaMax > -1);
    g_bCvar_CustomModel = g_hCvar_CustomModel.BoolValue;
    g_hCvar_CustomModelVMT.GetString(g_sCvar_CustomModelVMT, sizeof(g_sCvar_CustomModelVMT));
    TrimString(g_sCvar_CustomModelVMT);
    g_hCvar_CustomModelVTF.GetString(g_sCvar_CustomModelVTF, sizeof(g_sCvar_CustomModelVTF));
    TrimString(g_sCvar_CustomModelVTF);
    g_iCvar_SI = g_hCvar_SI.IntValue;

    if (g_bCvar_AliveShow)
    {
        if (g_bCvar_CustomModel)
        {
            AddFileToDownloadsTable(g_sCvar_CustomModelVMT);
            AddFileToDownloadsTable(g_sCvar_CustomModelVTF);
            PrecacheModel(g_sCvar_CustomModelVMT, true);
        }
        else
        {
            PrecacheModel(g_sCvar_AliveModel, true);
        }
    }

    if (g_bCvar_DeadShow)
        PrecacheModel(g_sCvar_DeadModel, true);
}

/****************************************************************************************************/

public void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        if (AreClientCookiesCached(client))
            OnClientCookiesCached(client);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        char classname[64];
        GetEntityClassname(entity, classname, sizeof(classname));
        OnEntityCreated(entity, classname);
    }
}

/****************************************************************************************************/

public void OnClientCookiesCached(int client)
{
    if (IsFakeClient(client))
        return;

    if (!g_bConfigLoaded)
        return;

    if (!g_bCvar_Cookies)
        return;

    char sValue[2];

    g_cbDisable.Get(client, sValue, sizeof(sValue));
    gc_bDisable[client] = (StringToInt(sValue) == 1 ? true : false);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    if (!g_bConfigLoaded)
        return;

    gc_bDisable[client] = false;
    gc_bShouldRender[client] = false;
    gc_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iSpriteFrameEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iSpriteInfoTargetEntRef[client] = INVALID_ENT_REFERENCE;

    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bVisible[target][client] = false;
        gc_fLastAttack[target][client] = 0.0;
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_bInvalidTrace[entity] = false;
    ge_iOwner[entity] = 0;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    switch (classname[0])
    {
        case 't':
        {
            if (StrEqual(classname, CLASSNAME_TANK_ROCK))
                ge_bInvalidTrace[entity] = true;
        }
        case 'i':
        {
            if (StrEqual(classname, CLASSNAME_INFECTED))
                ge_bInvalidTrace[entity] = true;
        }
        case 'w':
        {
            if (classname[1] != 'i')
                return;

            if (StrEqual(classname, CLASSNAME_WITCH))
                ge_bInvalidTrace[entity] = true;
        }
    }
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_hurt", Event_PlayerHurt);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_hurt", Event_PlayerHurt);

        return;
    }
}

/****************************************************************************************************/

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bCvar_AttackDelay)
        return;

    int target = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClientIndex(target))
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClientIndex(attacker))
        return;

    gc_fLastAttack[target][attacker] = GetGameTime();
}

/****************************************************************************************************/

public Action TimerRender(Handle timer)
{
    RenderHealthBar();

    return Plugin_Continue;
}

/****************************************************************************************************/

public void RenderHealthBar()
{
    for (int target = 1; target <= MaxClients; target++)
    {
        gc_bShouldRender[target] = ShouldRenderHP(target);

        if (!gc_bShouldRender[target])
        {
            KillSprite(target);
            continue;
        }

        CheckVisibility(target);

        char targetname[17];
        FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_hp_sprite", target);

        int infoTarget = INVALID_ENT_REFERENCE;

        if (g_bCvar_RemoveBlur)
        {
            float targetPos[3];
            GetClientAbsOrigin(target, targetPos);
            targetPos[2] += g_fCvar_ZAxis;

            if (gc_iSpriteInfoTargetEntRef[target] != INVALID_ENT_REFERENCE)
                infoTarget = EntRefToEntIndex(gc_iSpriteInfoTargetEntRef[target]);

            if (infoTarget == INVALID_ENT_REFERENCE)
            {
                infoTarget = CreateEntityByName(CLASSNAME_INFO_TARGET);
                gc_iSpriteInfoTargetEntRef[target] = EntIndexToEntRef(infoTarget);
                DispatchKeyValue(infoTarget, "targetname", targetname);

                DispatchSpawn(infoTarget);
                ActivateEntity(infoTarget);

                SetEntPropEnt(infoTarget, Prop_Send, "m_hOwnerEntity", target);
                SetVariantString("!activator");
                AcceptEntityInput(infoTarget, "SetParent", target);
            }
        }

        int entity = INVALID_ENT_REFERENCE;

        if (gc_iSpriteEntRef[target] != INVALID_ENT_REFERENCE)
            entity = EntRefToEntIndex(gc_iSpriteEntRef[target]);

        if (entity == INVALID_ENT_REFERENCE)
        {
            float targetPos[3];
            GetClientAbsOrigin(target, targetPos);
            targetPos[2] += g_fCvar_ZAxis;

            entity = CreateEntityByName(CLASSNAME_ENV_SPRITE);
            gc_iSpriteEntRef[target] = EntIndexToEntRef(entity);
            ge_iOwner[entity] = target;
            DispatchKeyValue(entity, "targetname", targetname);
            DispatchKeyValue(entity, "spawnflags", "1");
            SDKHook(entity, SDKHook_SetTransmit, OnSetTransmit);

            TeleportEntity(entity, targetPos, NULL_VECTOR, NULL_VECTOR);
        }

        bool isIncapacitated = IsPlayerIncapacitated(target);
        bool isBlackAndWhite;

        int targetTeam = GetClientTeam(target);
        int targetTeamFlag = GetTeamFlag(targetTeam);

        if (isIncapacitated && targetTeam == TEAM_INFECTED)
        {
            if (g_bCvar_DeadShow)
            {
                DispatchKeyValue(entity, "model", g_sCvar_DeadModel);
                DispatchKeyValue(entity, "rendercolor", g_sCvar_DeadColor);
                DispatchKeyValue(entity, "renderamt", g_sCvar_DeadAlpha); // If renderamt goes before rendercolor, it doesn't render
                DispatchKeyValue(entity, "scale", g_sCvar_DeadScale);
                DispatchKeyValue(entity, "fademindist", g_sCvar_FadeDistance);

                DispatchSpawn(entity);
                ActivateEntity(entity);

                SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", target);
                SetVariantString("!activator");
                AcceptEntityInput(entity, "SetParent", g_bCvar_RemoveBlur ? infoTarget : target);
                AcceptEntityInput(entity, "ShowSprite");
            }

            continue;
        }

        if (!g_bCvar_AliveShow)
        {
            AcceptEntityInput(entity, "HideSprite");
            continue;
        }

        bool isSurvivor;
        bool pulse;

        int maxHealth = GetEntProp(target, Prop_Data, "m_iMaxHealth");
        int currentHealth = GetClientHealth(target);

        switch (targetTeam)
        {
            case TEAM_SURVIVOR, TEAM_HOLDOUT:
            {
                isSurvivor = true;

                isBlackAndWhite = IsPlayerBlackAndWhite(target);

                if (isIncapacitated)
                    maxHealth = g_iCvar_survivor_incap_health;
                else
                    currentHealth += GetClientTempHealth(target);
            }
            case TEAM_INFECTED:
            {
                if (isIncapacitated)
                    maxHealth = 0;
            }
        }

        float percentageHealth;

        if (maxHealth > 0)
            percentageHealth = (float(currentHealth) / float(maxHealth));

        int colorAlpha[4];
        GetEntityRenderColor(target, colorAlpha[0], colorAlpha[1], colorAlpha[2], colorAlpha[3]);

        char sAlpha[4];
        if (g_bCvar_ClientAlphaMax && colorAlpha[3] <= g_iCvar_ClientAlphaMax)
            sAlpha = "0";
        else if (targetTeamFlag & g_iCvar_MultiplyAlphaTeam)
            FormatEx(sAlpha, sizeof(sAlpha), "%i", RoundFloat(g_iCvar_AliveAlpha * colorAlpha[3] / 255.0));
        else
            sAlpha = g_sCvar_AliveAlpha;

        int color[3];
        if (isIncapacitated)
        {
            color[0] = 255;
            color[1] = 0;
            color[2] = 0;

            if (g_iCvar_Pulse & FLAG_PULSE_INCAPACITATED)
                pulse = true;
        }
        else if (isBlackAndWhite && g_bCvar_BlackAndWhite && g_bCvar_survivor_max_incapacitated_count)
        {
            color[0] = 255;
            color[1] = 255;
            color[2] = 255;

            if (g_iCvar_Pulse & FLAG_PULSE_BLACK_AND_WHITE)
                pulse = true;
        }
        else if (isSurvivor && !g_bCvar_GradientColor)
        {
            if (currentHealth >= g_iCvar_survivor_limp_health) // Green
            {
                color[0] = 0;
                color[1] = 255;
                color[2] = 0;
            }
            else if (currentHealth > LOW_HEALTH) // Yellow
            {
                color[0] = 255;
                color[1] = 255;
                color[2] = 0;
            }
            else // Red
            {
                color[0] = 255;
                color[1] = 0;
                color[2] = 0;

                if (g_iCvar_Pulse & FLAG_PULSE_LOW_HEALTH)
                    pulse = true;
            }
        }
        else
        {
            bool halhealth = (percentageHealth <= 0.5);
            color[0] = halhealth ? 255 : RoundFloat(255.0 * ((1.0 - percentageHealth) * 2));
            color[1] = halhealth ? RoundFloat(255.0 * (percentageHealth) * 2) : 255;
            color[2] = 0;
        }

        char rendercolor[12];
        Format(rendercolor, sizeof(rendercolor), "%i %i %i", color[0], color[1], color[2]);

        DispatchKeyValue(entity, "model", g_bCvar_CustomModel ? g_sCvar_CustomModelVMT : g_sCvar_AliveModel);
        DispatchKeyValue(entity, "rendercolor", rendercolor);
        DispatchKeyValue(entity, "renderamt", sAlpha); // If renderamt goes before rendercolor, it doesn't render
        DispatchKeyValue(entity, "scale", g_sCvar_AliveScale);
        DispatchKeyValue(entity, "fademindist", g_sCvar_FadeDistance);
        DispatchKeyValue(entity, "renderfx", pulse ? "4" : "0");

        DispatchSpawn(entity);
        ActivateEntity(entity);

        SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", target);
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", g_bCvar_RemoveBlur ? infoTarget : target);
        AcceptEntityInput(entity, "ShowSprite");

        if (!g_bCvar_CustomModel)
            continue;

        int entityFrame = INVALID_ENT_REFERENCE;

        if (gc_iSpriteFrameEntRef[target] != INVALID_ENT_REFERENCE)
            entityFrame = EntRefToEntIndex(gc_iSpriteFrameEntRef[target]);

        if (entityFrame == INVALID_ENT_REFERENCE)
        {
            entityFrame = CreateEntityByName(CLASSNAME_ENV_TEXTURETOGGLE);
            gc_iSpriteFrameEntRef[target] = EntIndexToEntRef(entityFrame);
            DispatchKeyValue(entityFrame, "targetname", targetname);
            DispatchKeyValue(entityFrame, "target", targetname);

            DispatchSpawn(entityFrame);
            ActivateEntity(entityFrame);

            SetVariantString("!activator");
            AcceptEntityInput(entityFrame, "SetParent", entity);
        }

        int frame = RoundFloat(percentageHealth * 100);

        char input[38];
        FormatEx(input, sizeof(input), "OnUser1 !self:SetTextureIndex:%i:0:1", frame);
        SetVariantString(input);
        AcceptEntityInput(entityFrame, "AddOutput");
        AcceptEntityInput(entityFrame, "FireUser1");
    }
}

/****************************************************************************************************/

bool ShouldRenderHP(int target)
{
    if (!g_bCvar_Enabled)
        return false;

    if (!IsClientInGame(target))
        return false;

    if (!IsPlayerAlive(target))
        return false;

    int targetTeam = GetClientTeam(target);
    int targetTeamFlag = GetTeamFlag(targetTeam);

    if (!(targetTeamFlag & g_iCvar_Team))
        return false;

    if (targetTeam == TEAM_INFECTED)
    {
        if (IsPlayerGhost(target))
            return false;

        if (!(GetZombieClassFlag(target) & g_iCvar_SI))
            return false;
    }

    return true;
}

/****************************************************************************************************/

public Action OnSetTransmit(int entity, int client)
{
    if (IsFakeClient(client))
        return Plugin_Handled;

    int owner = ge_iOwner[entity];

    if (owner == client)
        return Plugin_Handled;

    if (gc_bVisible[owner][client])
        return Plugin_Continue;

    return Plugin_Handled;
}

/****************************************************************************************************/

void CheckVisibility(int target)
{
    if (gc_iSpriteEntRef[target] == INVALID_ENT_REFERENCE)
        return;

    if (!gc_bShouldRender[target])
        return;

    int targetTeamFlag = GetTeamFlag(GetClientTeam(target));

    for (int client = 1; client <= MaxClients; client++)
    {
        gc_bVisible[target][client] = false;

        if (gc_bDisable[client])
            continue;

        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        int clientTeamFlag = GetTeamFlag(GetClientTeam(client));

        switch (clientTeamFlag)
        {
            case FLAG_TEAM_SURVIVOR, FLAG_TEAM_HOLDOUT:
            {
                if (!(targetTeamFlag & g_iCvar_SurvivorTeam))
                    continue;
            }
            case FLAG_TEAM_INFECTED:
            {
                if (!(targetTeamFlag & g_iCvar_InfectedTeam))
                    continue;
            }
            case FLAG_TEAM_SPECTATOR:
            {
                if (!(targetTeamFlag & g_iCvar_SpectatorTeam))
                    continue;
            }
        }

        if (targetTeamFlag == FLAG_TEAM_INFECTED && clientTeamFlag == FLAG_TEAM_SURVIVOR)
        {
            if (g_bCvar_AttackDelay && (GetGameTime() - gc_fLastAttack[target][client] > g_fCvar_AttackDelay))
                continue;

            if (g_bCvar_Sight && !IsVisibleTo(client, target))
                continue;
        }

        gc_bVisible[target][client] = true;
    }
}

/****************************************************************************************************/

bool IsVisibleTo(int client, int target)
{
    float vClientPos[3];
    float vEntityPos[3];
    float vLookAt[3];
    float vAng[3];

    GetClientEyePosition(client, vClientPos);
    GetClientEyePosition(target, vEntityPos);
    MakeVectorFromPoints(vClientPos, vEntityPos, vLookAt);
    GetVectorAngles(vLookAt, vAng);

    Handle trace = TR_TraceRayFilterEx(vClientPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, target);

    bool isVisible;

    if (TR_DidHit(trace))
    {
        isVisible = (TR_GetEntityIndex(trace) == target);

        if (!isVisible)
        {
            vEntityPos[2] -= 62.0; // results the same as GetClientAbsOrigin

            delete trace;
            trace = TR_TraceHullFilterEx(vClientPos, vEntityPos, g_fvPlayerMins, g_fvPlayerMaxs, MASK_PLAYERSOLID, TraceFilter, target);

            if (TR_DidHit(trace))
                isVisible = (TR_GetEntityIndex(trace) == target);
        }
    }

    delete trace;

    return isVisible;
}

/****************************************************************************************************/

public bool TraceFilter(int entity, int contentsMask, int client)
{
    if (entity == client)
        return true;

    if (IsValidClientIndex(entity))
        return false;

    return ge_bInvalidTrace[entity] ? false : true;
}

/****************************************************************************************************/

void KillSprite(int target)
{
    if (!g_bCvar_RemoveBlur && gc_iSpriteInfoTargetEntRef[target] != INVALID_ENT_REFERENCE)
    {
        int infoTarget = EntRefToEntIndex(gc_iSpriteInfoTargetEntRef[target]);

        if (infoTarget != INVALID_ENT_REFERENCE)
            AcceptEntityInput(infoTarget, "Kill");

        gc_iSpriteInfoTargetEntRef[target] = INVALID_ENT_REFERENCE;
    }

    if (!g_bCvar_CustomModel && gc_iSpriteFrameEntRef[target] != INVALID_ENT_REFERENCE)
    {
        int entityFrame = EntRefToEntIndex(gc_iSpriteFrameEntRef[target]);

        if (entityFrame != INVALID_ENT_REFERENCE)
            AcceptEntityInput(entityFrame, "Kill");

        gc_iSpriteFrameEntRef[target] = INVALID_ENT_REFERENCE;
    }

    if (gc_iSpriteEntRef[target] == INVALID_ENT_REFERENCE)
        return;

    if (gc_bShouldRender[target])
        return;

    int entity = EntRefToEntIndex(gc_iSpriteEntRef[target]);

    if (entity != INVALID_ENT_REFERENCE)
        AcceptEntityInput(entity, "Kill");

    gc_iSpriteEntRef[target] = INVALID_ENT_REFERENCE;
    gc_iSpriteFrameEntRef[target] = INVALID_ENT_REFERENCE;
    gc_iSpriteInfoTargetEntRef[target] = INVALID_ENT_REFERENCE;

    for (int client = 1; client <= MaxClients; client++)
    {
        gc_bVisible[target][client] = false;
        gc_fLastAttack[target][client] = 0.0;
    }
}

// ====================================================================================================
// Menus
// ====================================================================================================
public void CreateToggleMenu(int client)
{
    Menu menu = new Menu(HandleToggleMenu);
    menu.SetTitle("HP Sprite");

    if (gc_bDisable[client])
        menu.AddItem("0", "☐ OFF");
    else
        menu.AddItem("1", "☑ ON");

    menu.Display(client, MENU_TIME_FOREVER);
}

/****************************************************************************************************/

public int HandleToggleMenu(Menu menu, MenuAction action, int client, int args)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sArg[2];
            menu.GetItem(args, sArg, sizeof(sArg));

            bool disable = (StringToInt(sArg) == 1 ? true : false);
            gc_bDisable[client] = disable;

            if (g_bCvar_Cookies)
                g_cbDisable.Set(client, disable ? "1" : "0");

            CreateToggleMenu(client);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

// ====================================================================================================
// Public Commands
// ====================================================================================================
public Action CmdHpMenu(int client, int args)
{
    if (!g_bConfigLoaded)
        return Plugin_Handled;

    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    CreateToggleMenu(client);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdHideHp(int client, int args)
{
    if (!g_bConfigLoaded)
        return Plugin_Handled;

    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    gc_bDisable[client] = true;
    g_cbDisable.Set(client, "1");

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdShowHp(int client, int args)
{
    if (!g_bConfigLoaded)
        return Plugin_Handled;

    if (!g_bCvar_Enabled)
        return Plugin_Handled;

    if (!IsValidClient(client))
        return Plugin_Handled;

    gc_bDisable[client] = false;
    g_cbDisable.Set(client, "0");

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
    PrintToConsole(client, "-------------------- Plugin Cvars (l4d_hp_sprite) --------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_hp_sprite_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_hp_sprite_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_cookies : %b (%s)", g_bCvar_Cookies, g_bCvar_Cookies ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_render_interval : %.2f", g_fCvar_RenderInterval);
    PrintToConsole(client, "l4d_hp_sprite_z_axis : %.2f", g_fCvar_ZAxis);
    PrintToConsole(client, "l4d_hp_sprite_fade_distance : %i", g_iCvar_FadeDistance);
    PrintToConsole(client, "l4d_hp_sprite_sight : %b (%s)", g_bCvar_Sight, g_bCvar_Sight ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_attack_delay : %.2f (%s)", g_fCvar_AttackDelay, g_bCvar_AttackDelay ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_gradient_color : %b (%s)", g_bCvar_GradientColor, g_bCvar_GradientColor ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_alive_show : %b (%s)", g_bCvar_AliveShow, g_bCvar_AliveShow ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_alive_model : \"%s\"", g_sCvar_AliveModel);
    PrintToConsole(client, "l4d_hp_sprite_alive_alpha : %i", g_iCvar_AliveAlpha);
    PrintToConsole(client, "l4d_hp_sprite_alive_scale : %.2f", g_fCvar_AliveScale);
    PrintToConsole(client, "l4d_hp_sprite_dead_show : %b (%s)", g_bCvar_DeadShow, g_bCvar_DeadShow ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_dead_model : \"%s\"", g_sCvar_DeadModel);
    PrintToConsole(client, "l4d_hp_sprite_dead_alpha : %i", g_iCvar_DeadAlpha);
    PrintToConsole(client, "l4d_hp_sprite_dead_scale : %.2f", g_fCvar_DeadScale);
    PrintToConsole(client, "l4d_hp_sprite_dead_color : \"%s\"", g_sCvar_DeadColor);
    PrintToConsole(client, "l4d_hp_sprite_pulse : %i", g_iCvar_Pulse);
    PrintToConsole(client, "l4d_hp_sprite_remove_blur : %b (%s)", g_bCvar_RemoveBlur, g_bCvar_RemoveBlur ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_black_and_white : %b (%s)", g_bCvar_BlackAndWhite, g_bCvar_BlackAndWhite ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_team : %i", g_iCvar_Team);
    PrintToConsole(client, "l4d_hp_sprite_survivor_team : %i", g_iCvar_SurvivorTeam);
    PrintToConsole(client, "l4d_hp_sprite_infected_team : %i", g_iCvar_InfectedTeam);
    PrintToConsole(client, "l4d_hp_sprite_spectator_team : %i", g_iCvar_SpectatorTeam);
    PrintToConsole(client, "l4d_hp_sprite_multiply_alpha_team : %i", g_iCvar_MultiplyAlphaTeam);
    PrintToConsole(client, "l4d_hp_sprite_client_alpha_max : %i (%s)", g_iCvar_ClientAlphaMax, g_bCvar_ClientAlphaMax ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_custom_model : %b (%s)", g_bCvar_CustomModel, g_bCvar_CustomModel ? "true" : "false");
    PrintToConsole(client, "l4d_hp_sprite_custom_model_vmt : \"%s\"", g_sCvar_CustomModelVMT);
    PrintToConsole(client, "l4d_hp_sprite_custom_model_vtf : \"%s\"", g_sCvar_CustomModelVTF);
    PrintToConsole(client, "l4d_hp_sprite_si : %i", g_iCvar_SI);
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "survivor_incap_health : %i", g_iCvar_survivor_incap_health);
    PrintToConsole(client, "survivor_max_incapacitated_count : %i", g_iCvar_survivor_max_incapacitated_count);
    PrintToConsole(client, "pain_pills_decay_rate : %.2f", g_fCvar_pain_pills_decay_rate);
    PrintToConsole(client, "survivor_limp_health : %i", g_iCvar_survivor_limp_health);
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
 * Returns is a player is in ghost state.
 *
 * @param client        Client index.
 * @return              True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

/****************************************************************************************************/

/**
 * Validates if the client is incapacitated.
 *
 * @param client        Client index.
 * @return              True if the client is incapacitated, false otherwise.
 */
bool IsPlayerIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

/****************************************************************************************************/

/**
 * Validates if the client is in black and white.
 *
 * @param client        Client index.
 * @return              True if the client is in black and white, false otherwise.
 */
bool IsPlayerBlackAndWhite(int client)
{
    return (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= g_iCvar_survivor_max_incapacitated_count);
}

/****************************************************************************************************/

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

// ====================================================================================================
// Thanks to Silvers
// ====================================================================================================
/**
 * Returns the client temporary health.
 *
 * @param client        Client index.
 * @return              Client temporary health.
 */
int GetClientTempHealth(int client)
{
    int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fCvar_pain_pills_decay_rate));
    return tempHealth < 0 ? 0 : tempHealth;
}