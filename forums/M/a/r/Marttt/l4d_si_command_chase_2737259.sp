/**
// ====================================================================================================
Change Log:

1.0.4 (14-April-2021)
    - Added display type cvars for the messages.

1.0.3 (03-April-2021)
    - Added animation to field.

1.0.2 (15-March-2021)
    - Added cvars to animate the sprite moving up/down.

1.0.1 (14-March-2021)
    - Added how-to and cooldown messages. (thanks "Maur0" for requesting)
    - Added chat, hint and instructor hint (L4D2 only) messages.
    - Added support to translation. (en / es / pt / pt_p)
    - Added sound for the activator when the skill is ready to use again.
    - Added sprite and beacon field indicator.

1.0.0 (17-February-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] SI Command Chase Common"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow special infecteds to command common infected to chase at crosshair"
#define PLUGIN_VERSION                "1.0.4"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330708"

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
#define CONFIG_FILENAME               "l4d_si_command_chase"
#define TRANSLATION_FILENAME          "l4d_si_command_chase.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFO_GOAL_INFECTED_CHASE     "info_goal_infected_chase"
#define CLASSNAME_INFO_TARGET                  "info_target"
#define CLASSNAME_ENV_SPRITE                   "env_sprite"
#define CLASSNAME_ENV_INSTRUCTOR_HINT          "env_instructor_hint"

#define ENTITY_WORLDSPAWN             0

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

#define FLAG_BUTTON_RELOAD            1
#define FLAG_BUTTON_ZOOM              2
#define FLAG_BUTTON_USE               4

#define FLAG_MSG_DISPLAY_CHAT         (1 << 0) // 1 | 01
#define FLAG_MSG_DISPLAY_HINT         (1 << 1) // 2 | 10

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Duration;
static ConVar g_hCvar_Cooldown;
static ConVar g_hCvar_SkillReadySound;
static ConVar g_hCvar_Button;
static ConVar g_hCvar_SafeArea;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_Field;
static ConVar g_hCvar_FieldModel;
static ConVar g_hCvar_FieldColor;
static ConVar g_hCvar_FieldAlpha;
static ConVar g_hCvar_FieldDuration;
static ConVar g_hCvar_FieldRepeat;
static ConVar g_hCvar_FieldStartRadius;
static ConVar g_hCvar_FieldEndRadius;
static ConVar g_hCvar_FieldWidth;
static ConVar g_hCvar_FieldAmplitude;
static ConVar g_hCvar_Sprite;
static ConVar g_hCvar_SpriteZAxis;
static ConVar g_hCvar_SpriteModel;
static ConVar g_hCvar_SpriteAlpha;
static ConVar g_hCvar_SpriteScale;
static ConVar g_hCvar_SpriteColor;
static ConVar g_hCvar_SpriteFadeDistance;
static ConVar g_hCvar_SpriteSpeed;
static ConVar g_hCvar_SpriteMinMax;
static ConVar g_hCvar_SyncRandomColor;
static ConVar g_hCvar_PressKeyMsg;
static ConVar g_hCvar_SkillReadyMsg;
static ConVar g_hCvar_SI;
static ConVar g_hCvar_InstructorHint;
static ConVar g_hCvar_InstructorHintColor;
static ConVar g_hCvar_InstructorHintIcon;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_SkillReadySound;
static bool   g_bCvar_SafeArea;
static bool   g_bCvar_Team;
static bool   g_bCvar_Field;
static bool   g_bCvar_RandomFieldColor;
static bool   g_bCvar_Sprite;
static bool   g_bCvar_RandomSpriteColor;
static bool   g_bCvar_SpriteSpeed;
static bool   g_bCvar_SpriteMinMax;
static bool   g_bCvar_SyncRandomColor;
static bool   g_bCvar_InstructorHint;
static bool   g_bCvar_InstructorHintIcon;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Button;
static int    g_iCvar_Team;
static int    g_iCvar_FieldColor[3];
static int    g_iCvar_FieldAlpha;
static int    g_iCvar_SpriteAlpha;
static int    g_iCvar_SpriteFadeDistance;
static int    g_iCvar_PressKeyMsg;
static int    g_iCvar_SkillReadyMsg;
static int    g_iCvar_SI;
static int    g_iFieldModelIndex = -1;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_Duration;
static float  g_fCvar_Cooldown;
static float  g_fCvar_FieldDuration;
static float  g_fCvar_FieldRepeat;
static float  g_fCvar_FieldStartRadius;
static float  g_fCvar_FieldEndRadius;
static float  g_fCvar_FieldWidth;
static float  g_fCvar_FieldAmplitude;
static float  g_fCvar_SpriteZAxis;
static float  g_fCvar_SpriteScale;
static float  g_fCvar_SpriteSpeed;
static float  g_fCvar_SpriteMinMax;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_SkillReadySound[100];
static char   g_sCvar_FieldModel[100];
static char   g_sCvar_FieldColor[12];
static char   g_sCvar_SpriteModel[100];
static char   g_sCvar_SpriteAlpha[4];
static char   g_sCvar_SpriteScale[5];
static char   g_sCvar_SpriteColor[12];
static char   g_sCvar_SpriteFadeDistance[5];
static char   g_sCvar_InstructorHintColor[12];
static char   g_sCvar_InstructorHintIcon[26];
static char   g_sKillDelay[32];
static char   g_sButton[33];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static float  gc_fLastTime[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bMoveUp[MAXENTITIES+1];
static int    ge_iOwner[MAXENTITIES+1];

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
    LoadPluginTranslations();

    CreateConVar("l4d_si_command_chase_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled                 = CreateConVar("l4d_si_command_chase_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Duration                = CreateConVar("l4d_si_command_chase_duration", "10.0", "Duration (seconds) that common zombies will chase.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Cooldown                = CreateConVar("l4d_si_command_chase_cooldown", "60.0", "Cooldown (seconds) to activate the skill again.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SkillReadySound         = CreateConVar("l4d_si_command_chase_skill_ready_sound", "ui/alert_clink.wav", "Skill ready sound.\nEmpty = OFF.", CVAR_FLAGS);
    g_hCvar_Button                  = CreateConVar("l4d_si_command_chase_button", "4", "Button to special infected command common zombies chase.\n0 = OFF, 1 = RELOAD (R), 2 = ZOOM (M3), 4 = USE (E).\nAdd numbers greater than 0 for multiple options.\nExample: \"5\", activates with the RELOAD (R) or USE (E) keys.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_SafeArea                = CreateConVar("l4d_si_command_chase_safe_area", "1", "Allow trigger common zombies while survivors are in the starting safe area.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team                    = CreateConVar("l4d_si_command_chase_team", "2", "Which teams should be able to see the chase effects (beacon / sprite).\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_Field                   = CreateConVar("l4d_si_command_chase_field", "1", "Create a beacon field where the chase has been created.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_FieldModel              = CreateConVar("l4d_si_command_chase_field_model", "materials/sprites/laserbeam.vmt", "Beacon field model.");
    g_hCvar_FieldColor              = CreateConVar("l4d_si_command_chase_field_color", "0 255 0", "Beacon field color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_FieldAlpha              = CreateConVar("l4d_si_command_chase_field_alpha", "255", "Beacon field alpha transparency.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_FieldDuration           = CreateConVar("l4d_si_command_chase_field_duration", "1.0", "Time duration of beacon field.", CVAR_FLAGS, true, 0.1);
    g_hCvar_FieldRepeat             = CreateConVar("l4d_si_command_chase_field_repeat", "1.0", "Repeat interval to create a beacon field.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldStartRadius        = CreateConVar("l4d_si_command_chase_field_start_radius", "75.0", "Beacon field start radius.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldEndRadius          = CreateConVar("l4d_si_command_chase_field_end_radius", "100.0", "Beacon field end radius.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldWidth              = CreateConVar("l4d_si_command_chase_field_width", "2.0", "Beacon field width.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FieldAmplitude          = CreateConVar("l4d_si_command_chase_field_amplitude", "0.0", "Beacon field amplitude.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Sprite                  = CreateConVar("l4d_si_command_chase_sprite", "1", "Create a sprite where the chase has been created.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SpriteZAxis             = CreateConVar("l4d_si_command_chase_sprite_z_axis", "50.0", "Additional Z axis to the sprite.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpriteModel             = CreateConVar("l4d_si_command_chase_sprite_model", "materials/vgui/icon_download.vmt", "Sprite model.");
    g_hCvar_SpriteColor             = CreateConVar("l4d_si_command_chase_sprite_color", "0 255 0", "Sprite color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_SpriteAlpha             = CreateConVar("l4d_si_command_chase_sprite_alpha", "255", "Sprite alpha transparency.\nNote: Some models don't allow to change the alpha.\n0 = Invisible, 255 = Fully Visible", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_SpriteScale             = CreateConVar("l4d_si_command_chase_sprite_scale", "0.25", "Sprite scale (increases both height and width).\nSome range values maintain the size the same.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpriteFadeDistance      = CreateConVar("l4d_si_command_chase_sprite_fade_distance", "-1", "Minimum distance that a client must be before the sprite fades.\n-1 = Always visible.", CVAR_FLAGS, true, -1.0, true, 9999.0);
    g_hCvar_SpriteSpeed             = CreateConVar("l4d_si_command_chase_sprite_speed", "1.0", "Speed that the sprite will move at the Z axis.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SpriteMinMax            = CreateConVar("l4d_si_command_chase_sprite_min_max", "4.0", "Minimum/Maximum distance between the original position that the sprite should reach before inverting the vertical direction.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_SyncRandomColor         = CreateConVar("l4d_si_command_chase_sync_random_color", "1", "Apply the same random color for both field and sprite.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_PressKeyMsg             = CreateConVar("l4d_si_command_chase_press_key_msg", "1", "Display type for the \"Press Key\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_SkillReadyMsg           = CreateConVar("l4d_si_command_chase_skill_ready_msg", "1", "Display type for the \"Skill Ready\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);

    if (g_bL4D2)
        g_hCvar_SI                  = CreateConVar("l4d_si_command_chase_si", "127", "Which special infected should be able to command common zombies.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", enables command chase for all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);
    else
        g_hCvar_SI                  = CreateConVar("l4d_si_command_chase_si", "15", "Which special infected should be able to command common zombies.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", enables command chase for all SI.", CVAR_FLAGS, true, 0.0, true, 15.0);

    if (g_bL4D2)
    {
        g_hCvar_InstructorHint      = CreateConVar("l4d_si_command_chase_instructor_hint", "1", "Show instructor hint message.\nL4D2 only.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_InstructorHintColor = CreateConVar("l4d_si_command_chase_instructor_hint_color", "255 255 255", "Instructor hint color.\nL4D2 only.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
        g_hCvar_InstructorHintIcon  = CreateConVar("l4d_si_command_chase_instructor_hint_icon", "icon_interact", "Instructor hint icon.\nL4D2 only.\nEmpty = OFF.", CVAR_FLAGS);
    }

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Duration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cooldown.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SkillReadySound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Button.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SafeArea.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Field.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldAlpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldDuration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldRepeat.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldStartRadius.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldEndRadius.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldWidth.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FieldAmplitude.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Sprite.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteZAxis.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteModel.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteAlpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteScale.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteFadeDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteSpeed.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpriteMinMax.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SyncRandomColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_PressKeyMsg.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SkillReadyMsg.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_InstructorHint.AddChangeHook(Event_ConVarChanged);
        g_hCvar_InstructorHintColor.AddChangeHook(Event_ConVarChanged);
        g_hCvar_InstructorHintIcon.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_forcechaseaim", CmdForceChaseAim, ADMFLAG_ROOT, "Force common zombies chase on self crosshair (no args) or specified targets crosshair. Example: self -> sm_forcechaseaim / target -> sm_forcechaseaim @bots");
    RegAdminCmd("sm_print_cvars_l4d_si_command_chase", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;
    char targetname[21];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFO_TARGET)) != INVALID_ENT_REFERENCE)
    {
        if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
            if (StrEqual(targetname, "l4d_si_command_chase"))
                AcceptEntityInput(entity, "Kill");
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_ENV_SPRITE)) != INVALID_ENT_REFERENCE)
    {
        if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
            if (StrEqual(targetname, "l4d_si_command_chase"))
                AcceptEntityInput(entity, "Kill");
        }
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFO_GOAL_INFECTED_CHASE)) != INVALID_ENT_REFERENCE)
    {
        if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1)
        {
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
            if (StrEqual(targetname, "l4d_si_command_chase"))
                AcceptEntityInput(entity, "Kill");
        }
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
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_Duration = g_hCvar_Duration.FloatValue;
    g_fCvar_Cooldown = g_hCvar_Cooldown.FloatValue;
    g_hCvar_SkillReadySound.GetString(g_sCvar_SkillReadySound, sizeof(g_sCvar_SkillReadySound));
    TrimString(g_sCvar_SkillReadySound);
    g_bCvar_SkillReadySound = (g_sCvar_SkillReadySound[0] != 0);
    if (g_bCvar_SkillReadySound)
        PrecacheSound(g_sCvar_SkillReadySound, true);
    g_iCvar_Button = g_hCvar_Button.IntValue;
    g_bCvar_SafeArea = g_hCvar_SafeArea.BoolValue;
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Team = (g_iCvar_Team > 0);
    g_hCvar_FieldModel.GetString(g_sCvar_FieldModel, sizeof(g_sCvar_FieldModel));
    TrimString(g_sCvar_FieldModel);
    g_iFieldModelIndex = PrecacheModel(g_sCvar_FieldModel, true);
    g_bCvar_Field = g_hCvar_Field.BoolValue;
    g_hCvar_FieldColor.GetString(g_sCvar_FieldColor, sizeof(g_sCvar_FieldColor));
    TrimString(g_sCvar_FieldColor);
    StringToLowerCase(g_sCvar_FieldColor);
    g_bCvar_RandomFieldColor = StrEqual(g_sCvar_FieldColor, "random");
    g_iCvar_FieldColor = ConvertRGBToIntArray(g_sCvar_FieldColor);
    g_iCvar_FieldAlpha = g_hCvar_FieldAlpha.IntValue;
    g_fCvar_FieldDuration = g_hCvar_FieldDuration.FloatValue;
    g_fCvar_FieldRepeat = g_hCvar_FieldRepeat.FloatValue;
    g_fCvar_FieldStartRadius = g_hCvar_FieldStartRadius.FloatValue;
    g_fCvar_FieldEndRadius = g_hCvar_FieldEndRadius.FloatValue;
    g_fCvar_FieldWidth = g_hCvar_FieldWidth.FloatValue;
    g_fCvar_FieldAmplitude = g_hCvar_FieldAmplitude.FloatValue;
    g_bCvar_Sprite = g_hCvar_Sprite.BoolValue;
    g_fCvar_SpriteZAxis = g_hCvar_SpriteZAxis.FloatValue;
    g_hCvar_SpriteModel.GetString(g_sCvar_SpriteModel, sizeof(g_sCvar_SpriteModel));
    TrimString(g_sCvar_SpriteModel);
    PrecacheModel(g_sCvar_SpriteModel, true);
    g_iCvar_SpriteAlpha = g_hCvar_SpriteAlpha.IntValue;
    FormatEx(g_sCvar_SpriteAlpha, sizeof(g_sCvar_SpriteAlpha), "%i", g_iCvar_SpriteAlpha);
    g_fCvar_SpriteScale = g_hCvar_SpriteScale.FloatValue;
    FormatEx(g_sCvar_SpriteScale, sizeof(g_sCvar_SpriteScale), "%.2f", g_fCvar_SpriteScale);
    g_hCvar_SpriteColor.GetString(g_sCvar_SpriteColor, sizeof(g_sCvar_SpriteColor));
    TrimString(g_sCvar_SpriteColor);
    StringToLowerCase(g_sCvar_SpriteColor);
    g_bCvar_RandomSpriteColor = StrEqual(g_sCvar_SpriteColor, "random");
    g_iCvar_SpriteFadeDistance = g_hCvar_SpriteFadeDistance.IntValue;
    FormatEx(g_sCvar_SpriteFadeDistance, sizeof(g_sCvar_SpriteFadeDistance), "%i", g_iCvar_SpriteFadeDistance);
    g_fCvar_SpriteSpeed = g_hCvar_SpriteSpeed.FloatValue;
    g_bCvar_SpriteSpeed = (g_fCvar_SpriteSpeed > 0.0);
    g_fCvar_SpriteMinMax = g_hCvar_SpriteMinMax.FloatValue;
    g_bCvar_SpriteMinMax = (g_fCvar_SpriteMinMax > 0.0);
    g_bCvar_SyncRandomColor = g_hCvar_SyncRandomColor.BoolValue;
    g_iCvar_PressKeyMsg = g_hCvar_PressKeyMsg.IntValue;
    g_iCvar_SkillReadyMsg = g_hCvar_SkillReadyMsg.IntValue;
    g_iCvar_SI = g_hCvar_SI.IntValue;
    if (g_bL4D2)
    {
        g_bCvar_InstructorHint = g_hCvar_InstructorHint.BoolValue;
        g_hCvar_InstructorHintColor.GetString(g_sCvar_InstructorHintColor, sizeof(g_sCvar_InstructorHintColor));
        TrimString(g_sCvar_InstructorHintColor);
        g_hCvar_InstructorHintIcon.GetString(g_sCvar_InstructorHintIcon, sizeof(g_sCvar_InstructorHintIcon));
        TrimString(g_sCvar_InstructorHintIcon);
        g_bCvar_InstructorHintIcon = (g_sCvar_InstructorHintIcon[0] != 0);
    }

    FormatEx(g_sKillDelay, sizeof(g_sKillDelay), "OnUser1 !self:Kill::%.2f:-1", g_fCvar_Duration);

    char buttons[3][11];
    int buttonsCount;
    if (g_iCvar_Button & FLAG_BUTTON_RELOAD)
        buttons[buttonsCount++] = "RELOAD (R)";
    if (g_iCvar_Button & FLAG_BUTTON_ZOOM)
        buttons[buttonsCount++] = "ZOOM (M3)";
    if (g_iCvar_Button & FLAG_BUTTON_USE)
        buttons[buttonsCount++] = "USE (E)";

    ImplodeStrings(buttons, buttonsCount, " / ", g_sButton, sizeof(g_sButton));
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_fLastTime[client] = 0.0;
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_bMoveUp[entity] = false;
    ge_iOwner[entity] = 0;
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_spawn", Event_PlayerSpawn);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_spawn", Event_PlayerSpawn);

        return;
    }
}

/****************************************************************************************************/

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    RequestFrame(OnNextFrame, event.GetInt("userid")); // We need wait a frame to check ghost state
}

/****************************************************************************************************/

public void OnNextFrame(int userid)
{
    int client = GetClientOfUserId(userid);

    if (!IsValidClient(client))
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

    if (g_iCvar_PressKeyMsg & FLAG_MSG_DISPLAY_CHAT)
        CPrintToChat(client, "%t", "Press Key", g_sButton);

    if (g_iCvar_PressKeyMsg & FLAG_MSG_DISPLAY_HINT)
        CPrintHintText(client, "%t", "Press Key", g_sButton);

    if (g_bCvar_InstructorHint)
        PrintInstructorHintText(client, "%t", "Press Key", g_sButton);
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClientIndex(client))
        return;

    if (IsFakeClient(client))
        return;

    if ((buttons & IN_RELOAD) && (g_iCvar_Button & FLAG_BUTTON_RELOAD) ||
        (buttons & IN_ZOOM) && (g_iCvar_Button & FLAG_BUTTON_ZOOM) ||
        (buttons & IN_USE) && (g_iCvar_Button & FLAG_BUTTON_USE))
    {
        if (GetGameTime() - gc_fLastTime[client] < g_fCvar_Cooldown)
            return;

        if (!g_bCvar_SafeArea && !HasAnySurvivorLeftSafeArea())
            return;

        if (GetClientTeam(client) != TEAM_INFECTED)
            return;

        if (!IsPlayerAlive(client))
            return;

        if (IsPlayerGhost(client))
            return;

        if (!(GetZombieClassFlag(client) & g_iCvar_SI))
            return;

        PerformChaseAim(client);
    }
}

/****************************************************************************************************/

public void PerformChaseAim(int client)
{
    bool hit;
    float vEndPos[3];

    int clientAim = GetClientAimTarget(client, true);

    if (IsValidClientIndex(clientAim))
    {
        hit = true;
        GetClientAbsOrigin(clientAim, vEndPos);
    }
    else
    {
        float vPos[3];
        GetClientEyePosition(client, vPos);

        float vAng[3];
        GetClientEyeAngles(client, vAng);

        Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_ALL, RayType_Infinite, TraceFilter, client);

        if (TR_DidHit(trace))
        {
            hit = true;
            TR_GetEndPosition(vEndPos, trace);
        }

        delete trace;
    }

    if (!hit)
        return;

    gc_fLastTime[client] = GetGameTime();

    CreateTimer(g_fCvar_Cooldown, TimerCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    int entity = CreateEntityByName(CLASSNAME_INFO_GOAL_INFECTED_CHASE);
    DispatchKeyValue(entity, "targetname", "l4d_si_command_chase");
    SetEntProp(entity, Prop_Data, "m_iHammerID", -1);

    TeleportEntity(entity, vEndPos, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(entity);
    ActivateEntity(entity);

    AcceptEntityInput(entity, "Enable");

    SetVariantString(g_sKillDelay);
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    int randomColor[3];
    if (g_bCvar_SyncRandomColor)
    {
        randomColor[0] = GetRandomInt(0, 255);
        randomColor[1] = GetRandomInt(0, 255);
        randomColor[2] = GetRandomInt(0, 255);
    }

    if (g_bCvar_Field)
    {
        float vBeamPos[3];
        vBeamPos = vEndPos;
        vBeamPos[2] += (g_fCvar_FieldWidth + 1.0); // Change the Z pos to go up according with the width for better looking

        int color[4];
        if (g_bCvar_RandomFieldColor)
        {
            if (g_bCvar_SyncRandomColor)
            {
                color[0] = randomColor[0];
                color[1] = randomColor[1];
                color[2] = randomColor[2];
            }
            else
            {
                color[0] = GetRandomInt(0, 255);
                color[1] = GetRandomInt(0, 255);
                color[2] = GetRandomInt(0, 255);
            }
            color[3] = g_iCvar_FieldAlpha;
        }
        else
        {
            color[0] = g_iCvar_FieldColor[0];
            color[1] = g_iCvar_FieldColor[1];
            color[2] = g_iCvar_FieldColor[2];
            color[3] = g_iCvar_FieldAlpha;
        }

        float timeLimit = GetGameTime() + g_fCvar_Duration;

        DataPack pack;
        CreateDataTimer(g_fCvar_FieldRepeat, TimerField, pack, TIMER_FLAG_NO_MAPCHANGE);
        pack.WriteCell(color[0]);
        pack.WriteCell(color[1]);
        pack.WriteCell(color[2]);
        pack.WriteCell(color[3]);
        pack.WriteFloat(timeLimit);
        pack.WriteFloat(vBeamPos[0]);
        pack.WriteFloat(vBeamPos[1]);
        pack.WriteFloat(vBeamPos[2]);

        float fieldDuration = (timeLimit - GetGameTime() < g_fCvar_FieldDuration ? timeLimit - GetGameTime() : g_fCvar_FieldDuration);

        if (fieldDuration < 0.1) // Prevent rounding to 0 which makes the beam don't disappear
            fieldDuration = 0.1;

        int targets[MAXPLAYERS+1];
        int targetCount;

        for (int target = 1; target <= MaxClients; target++)
        {
            if (!IsClientInGame(target))
                continue;

            if (IsFakeClient(target))
                continue;

            if (!(GetTeamFlag(GetClientTeam(target)) & g_iCvar_Team))
                continue;

            targets[targetCount++] = target;
        }

        TE_SetupBeamRingPoint(vBeamPos, g_fCvar_FieldStartRadius, g_fCvar_FieldEndRadius, g_iFieldModelIndex, 0, 0, 0, fieldDuration, g_fCvar_FieldWidth, g_fCvar_FieldAmplitude, color, 0, 0);
        TE_Send(targets, targetCount);
    }

    if (g_bCvar_Sprite)
    {
        float vSpritePos[3];
        vSpritePos = vEndPos;
        vSpritePos[2] += g_fCvar_SpriteZAxis;

        char targetname[24];
        FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_si_command_chase", client);

        char color[12];
        if (g_bCvar_RandomSpriteColor)
        {
            if (g_bCvar_SyncRandomColor)
                FormatEx(color, sizeof(color), "%i %i %i", randomColor[0], randomColor[1], randomColor[2]);
            else
                FormatEx(color, sizeof(color), "%i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
        }
        else
        {
            color = g_sCvar_SpriteColor;
        }

        int infoTarget = CreateEntityByName(CLASSNAME_INFO_TARGET);
        DispatchKeyValue(infoTarget, "targetname", targetname);

        TeleportEntity(infoTarget, vSpritePos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(infoTarget);
        ActivateEntity(infoTarget);

        SetEntPropEnt(infoTarget, Prop_Send, "m_hOwnerEntity", client);

        SetVariantString(g_sKillDelay);
        AcceptEntityInput(infoTarget, "AddOutput");
        AcceptEntityInput(infoTarget, "FireUser1");

        int sprite = CreateEntityByName(CLASSNAME_ENV_SPRITE);
        ge_iOwner[sprite] = client;
        DispatchKeyValue(sprite, "targetname", targetname);
        DispatchKeyValue(sprite, "spawnflags", "1");
        SetEntProp(sprite, Prop_Data, "m_iHammerID", -1);
        SDKHook(sprite, SDKHook_SetTransmit, OnSetTransmitSprite);

        DispatchKeyValue(sprite, "model", g_sCvar_SpriteModel);
        DispatchKeyValue(sprite, "rendercolor", color);
        DispatchKeyValue(sprite, "renderamt", g_sCvar_SpriteAlpha); // If renderamt goes before rendercolor, it doesn't render
        DispatchKeyValue(sprite, "scale", g_sCvar_SpriteScale);
        DispatchKeyValue(sprite, "fademindist", g_sCvar_SpriteFadeDistance);

        TeleportEntity(sprite, vSpritePos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(sprite);
        ActivateEntity(sprite);

        SetVariantString("!activator");
        AcceptEntityInput(sprite, "SetParent", infoTarget); // We need parent the entity to an info_target, otherwise SetTransmit won't work

        SetEntPropEnt(sprite, Prop_Send, "m_hOwnerEntity", client);
        AcceptEntityInput(sprite, "ShowSprite");
        SetVariantString(g_sKillDelay);
        AcceptEntityInput(sprite, "AddOutput");
        AcceptEntityInput(sprite, "FireUser1");

        if (g_bCvar_SpriteSpeed && g_bCvar_SpriteMinMax)
            CreateTimer(0.1, TimerMoveSprite, EntIndexToEntRef(sprite), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

/****************************************************************************************************/

public Action TimerField(Handle timer, DataPack pack)
{
    int color[4];
    float timeLimit;
    float vBeamPos[3];

    pack.Reset();
    color[0] = pack.ReadCell();
    color[1] = pack.ReadCell();
    color[2] = pack.ReadCell();
    color[3] = pack.ReadCell();
    timeLimit = pack.ReadFloat();
    vBeamPos[0] = pack.ReadFloat();
    vBeamPos[1] = pack.ReadFloat();
    vBeamPos[2] = pack.ReadFloat();

    if (timeLimit < GetGameTime())
        return;

    float fieldDuration = (timeLimit - GetGameTime() < g_fCvar_FieldDuration ? timeLimit - GetGameTime() : g_fCvar_FieldDuration);

    if (fieldDuration < 0.1) // Prevent rounding to 0 which makes the beam don't disappear
        fieldDuration = 0.1;

    int targets[MAXPLAYERS+1];
    int targetCount;

    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        if (IsFakeClient(target))
            continue;

        if (!(GetTeamFlag(GetClientTeam(target)) & g_iCvar_Team))
            continue;

        targets[targetCount++] = target;
    }

    TE_SetupBeamRingPoint(vBeamPos, g_fCvar_FieldStartRadius, g_fCvar_FieldEndRadius, g_iFieldModelIndex, 0, 0, 0, fieldDuration, g_fCvar_FieldWidth, g_fCvar_FieldAmplitude, color, 0, 0);
    TE_Send(targets, targetCount);

    DataPack pack2;
    CreateDataTimer(g_fCvar_FieldRepeat, TimerField, pack2, TIMER_FLAG_NO_MAPCHANGE);
    pack2.WriteCell(color[0]);
    pack2.WriteCell(color[1]);
    pack2.WriteCell(color[2]);
    pack2.WriteCell(color[3]);
    pack2.WriteFloat(timeLimit);
    pack2.WriteFloat(vBeamPos[0]);
    pack2.WriteFloat(vBeamPos[1]);
    pack2.WriteFloat(vBeamPos[2]);
}

/****************************************************************************************************/

public Action TimerMoveSprite(Handle timer, int entityRef)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    float vPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

    if (ge_bMoveUp[entity])
    {
        vPos[2] += g_fCvar_SpriteSpeed;

        if (vPos[2] >= g_fCvar_SpriteMinMax)
            ge_bMoveUp[entity] = false;
    }
    else
    {
        vPos[2] -= g_fCvar_SpriteSpeed;

        if (vPos[2] <= -g_fCvar_SpriteMinMax)
            ge_bMoveUp[entity] = true;
    }

    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}

/****************************************************************************************************/

public Action OnSetTransmitSprite(int entity, int client)
{
    if (IsFakeClient(client))
        return Plugin_Handled;

    if (ge_iOwner[entity] == client) // Always visible to the activator
        return Plugin_Continue;

    if (GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team)
        return Plugin_Continue;

    return Plugin_Handled;
}

/****************************************************************************************************/

public bool TraceFilter(int entity, int contentsMask, int client)
{
    if (entity == client)
        return false;

    if (entity == ENTITY_WORLDSPAWN || IsValidClientIndex(entity))
        return true;

    return false;
}

/****************************************************************************************************/

public Action TimerCooldown(Handle timer, int userid)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int client = GetClientOfUserId(userid);

    if (!IsValidClient(client))
        return Plugin_Stop;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return Plugin_Stop;

    if (!IsPlayerAlive(client))
        return Plugin_Stop;

    if (IsPlayerGhost(client))
        return Plugin_Stop;

    if (!(GetZombieClassFlag(client) & g_iCvar_SI))
        return Plugin_Stop;

    if (g_bCvar_SkillReadySound)
        EmitSoundToClient(client, g_sCvar_SkillReadySound);

    if (g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_CHAT)
        CPrintToChat(client, "%t", "Skill Ready");

    if (g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_HINT)
        CPrintHintText(client, "%t", "Skill Ready");

    if (g_bCvar_InstructorHint)
        PrintInstructorHintText(client, "%t", "Skill Ready");

    return Plugin_Stop;
}

/****************************************************************************************************/

void PrintInstructorHintText(int client, const char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "");
    ReplaceString(buffer, sizeof(buffer), "{white}", "");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "");
    ReplaceString(buffer, sizeof(buffer), "{green}", "");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "");

    ReplaceString(buffer, sizeof(buffer), "\x01", ""); // Default
    ReplaceString(buffer, sizeof(buffer), "\x03", ""); // Light Green
    ReplaceString(buffer, sizeof(buffer), "\x04", ""); // Orange
    ReplaceString(buffer, sizeof(buffer), "\x05", ""); // Olive

    char clienttargetname[64];
    GetEntPropString(client, Prop_Data, "m_iName", clienttargetname, sizeof(clienttargetname));

    char hintTarget[7];
    FormatEx(hintTarget, sizeof(hintTarget), "hint%d", client);

    int entity = CreateEntityByName(CLASSNAME_ENV_INSTRUCTOR_HINT);
    DispatchKeyValue(client, "targetname", hintTarget);
    DispatchKeyValue(entity, "hint_target", hintTarget);
    DispatchKeyValue(entity, "targetname", "l4d_si_command_chase");
    DispatchKeyValue(entity, "hint_color", g_sCvar_InstructorHintColor);
    if (g_bCvar_InstructorHintIcon)
        DispatchKeyValue(entity, "hint_icon_onscreen", g_sCvar_InstructorHintIcon);
    DispatchKeyValue(entity, "hint_caption", buffer);

    DispatchSpawn(entity);
    AcceptEntityInput(entity, "ShowHint", client);

    SetVariantString(g_sKillDelay);
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    DispatchKeyValue(client, "targetname", clienttargetname); // rollback the client targetname
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdForceChaseAim(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args == 0) // self
    {
        if (GetGameTime() - gc_fLastTime[client] < g_fCvar_Cooldown)
            return Plugin_Handled;

        PerformChaseAim(client);
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
            if (GetGameTime() - gc_fLastTime[target_list[i]] < g_fCvar_Cooldown)
                continue;

            PerformChaseAim(target_list[i]);
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
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_si_command_chase) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_si_command_chase_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_si_command_chase_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_duration : %.2f", g_fCvar_Duration);
    PrintToConsole(client, "l4d_si_command_chase_cooldown : %.2f", g_fCvar_Cooldown);
    PrintToConsole(client, "l4d_si_command_chase_skill_ready_sound : \"%s\" (%s)", g_sCvar_SkillReadySound, g_bCvar_SkillReadySound ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_button : %i (RELOAD: %s | ZOOM: %s | USE: %s)", g_iCvar_Button, g_iCvar_Button & FLAG_BUTTON_RELOAD ? "ON" : "OFF", g_iCvar_Button & FLAG_BUTTON_ZOOM ? "ON" : "OFF", g_iCvar_Button & FLAG_BUTTON_USE ? "ON" : "OFF");
    PrintToConsole(client, "l4d_si_command_chase_safe_area : %b (%s)", g_bCvar_SafeArea, g_bCvar_SafeArea ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_team : %i (%s)", g_iCvar_Team, g_bCvar_Team ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_field : %b (%s)", g_bCvar_Field, g_bCvar_Field ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_field_model : \"%s\"", g_sCvar_FieldModel);
    PrintToConsole(client, "l4d_si_command_chase_field_color : \"%s\"", g_sCvar_FieldColor);
    PrintToConsole(client, "l4d_si_command_chase_field_alpha : %i", g_iCvar_FieldAlpha);
    PrintToConsole(client, "l4d_si_command_chase_field_duration : %.2f", g_fCvar_FieldDuration);
    PrintToConsole(client, "l4d_si_command_chase_field_repeat : %.2f", g_fCvar_FieldRepeat);
    PrintToConsole(client, "l4d_si_command_chase_field_start_radius : %.2f", g_fCvar_FieldStartRadius);
    PrintToConsole(client, "l4d_si_command_chase_field_end_radius : %.2f", g_fCvar_FieldEndRadius);
    PrintToConsole(client, "l4d_si_command_chase_field_width : %.2f", g_fCvar_FieldWidth);
    PrintToConsole(client, "l4d_si_command_chase_field_amplitude : %.2f", g_fCvar_FieldAmplitude);
    PrintToConsole(client, "l4d_si_command_chase_sprite : %b (%s)", g_bCvar_Sprite, g_bCvar_Sprite ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_sprite_z_axis : %.2f", g_fCvar_SpriteZAxis);
    PrintToConsole(client, "l4d_si_command_chase_sprite_model : \"%s\"", g_sCvar_SpriteModel);
    PrintToConsole(client, "l4d_si_command_chase_sprite_color : \"%s\"", g_sCvar_SpriteColor);
    PrintToConsole(client, "l4d_si_command_chase_sprite_alpha : %i", g_iCvar_SpriteAlpha);
    PrintToConsole(client, "l4d_si_command_chase_sprite_scale : %.2f", g_fCvar_SpriteScale);
    PrintToConsole(client, "l4d_si_command_chase_sprite_fade_distance : %i", g_iCvar_SpriteFadeDistance);
    PrintToConsole(client, "l4d_si_command_chase_sprite_speed : %.2f (%s)", g_fCvar_SpriteSpeed, g_bCvar_SpriteSpeed ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_sprite_min_max : %.2f (%s)", g_fCvar_SpriteMinMax, g_bCvar_SpriteMinMax ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_sync_random_color : %b (%s)", g_bCvar_SyncRandomColor, g_bCvar_SyncRandomColor ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_press_key_msg : %i (CHAT: %s | HINT: %s)", g_iCvar_PressKeyMsg, g_iCvar_PressKeyMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_PressKeyMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
    PrintToConsole(client, "l4d_si_command_chase_skill_ready_msg : %i (CHAT: %s | HINT: %s)", g_iCvar_SkillReadyMsg, g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_SkillReadyMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
    PrintToConsole(client, "l4d_si_command_chase_si : %i", g_iCvar_SI);
    PrintToConsole(client, "l4d_si_command_chase_instructor_hint : %b (%s)", g_bCvar_InstructorHint, g_bCvar_InstructorHint ? "true" : "false");
    PrintToConsole(client, "l4d_si_command_chase_instructor_hint_color : \"%s\"", g_sCvar_InstructorHintColor);
    PrintToConsole(client, "l4d_si_command_chase_instructor_hint_icon : \"%s\" (%s)", g_sCvar_InstructorHintIcon, g_bCvar_InstructorHintIcon ? "true" : "false");
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

/****************************************************************************************************/

/**
 * Returns whether any survivor have left the safe area.
 *
 * @return              True if any survivor have left safe area, false otherwise.
 */
static int g_iEntTerrorPlayerManager = INVALID_ENT_REFERENCE;
bool HasAnySurvivorLeftSafeArea()
{
    int entity = EntRefToEntIndex(g_iEntTerrorPlayerManager);

    if (entity == INVALID_ENT_REFERENCE)
        entity = FindEntityByClassname(-1, "terror_player_manager");

    if (entity == INVALID_ENT_REFERENCE)
    {
        g_iEntTerrorPlayerManager = INVALID_ENT_REFERENCE;
        return false;
    }

    g_iEntTerrorPlayerManager = EntIndexToEntRef(entity);

    return (GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea") == 1);
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
public void CPrintToChat(int client, char[] message, any ...)
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

/****************************************************************************************************/

/**
 * Prints a message to a specific client in the hint area.
 * Remove color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
public void CPrintHintText(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "");
    ReplaceString(buffer, sizeof(buffer), "{white}", "");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "");
    ReplaceString(buffer, sizeof(buffer), "{green}", "");
    ReplaceString(buffer, sizeof(buffer), "{olive}", "");

    ReplaceString(buffer, sizeof(buffer), "\x01", ""); // Default
    ReplaceString(buffer, sizeof(buffer), "\x03", ""); // Light Green
    ReplaceString(buffer, sizeof(buffer), "\x04", ""); // Orange
    ReplaceString(buffer, sizeof(buffer), "\x05", ""); // Olive

    PrintHintText(client, buffer);
}