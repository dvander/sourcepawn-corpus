/**
// ====================================================================================================
Change Log:

1.0.1 (03-April-2021)
    - Added animation to field.
    - Added sound and message notifications. (thanks "Benjamin38" for request and snippet code)
    - Added intro, cooldown and team warning messages (chat and hint).
    - Added support to translation. (en / es / pt / pt_p)

1.0.0 (16-March-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Spot Marker"
#define PLUGIN_AUTHOR                 "Mart (Fork by Proaxel)"
#define PLUGIN_DESCRIPTION            "Allow teammates to create spot markers visible only to them"
#define PLUGIN_VERSION                "1.0.2 (Proaxel's Fork - 1.00)"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=331347"

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
#define CONFIG_FILENAME               "l4d_spot_marker"
#define TRANSLATION_FILENAME          "l4d_spot_marker.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFO_TARGET         "info_target"
#define CLASSNAME_ENV_SPRITE          "env_sprite"

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

#define MAXENTITIES                   2048

//By Proaxel:

#define MARKED_SPOT                   1
#define MARKED_ENTITY                 2
#define MARKED_PLAYER                 3

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Duration;
static ConVar g_hCvar_Cooldown;
static ConVar g_hCvar_Cooldown_PlayerEnts;
static ConVar g_hCvar_GlowDropFix;
static ConVar g_hCvar_SkillReadySound;
static ConVar g_hCvar_UseSound;
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
static ConVar g_hCvar_Chat;
static ConVar g_hCvar_Hint;
static ConVar g_hCvar_Intro;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_GlowDropFix;
static bool   g_bCvar_SkillReadySound;
static bool   g_bCvar_UseSound;
static bool   g_bCvar_Team;
static bool   g_bCvar_Field;
static bool   g_bCvar_RandomFieldColor;
static bool   g_bCvar_Sprite;
static bool   g_bCvar_RandomSpriteColor;
static bool   g_bCvar_SpriteSpeed;
static bool   g_bCvar_SpriteMinMax;
static bool   g_bCvar_Chat;
static bool   g_bCvar_Hint;
static bool   g_bCvar_Intro;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Team;
static int    g_iCvar_FieldColor[3];
static int    g_iCvar_FieldAlpha;
static int    g_iCvar_SpriteAlpha;
static int    g_iCvar_SpriteFadeDistance;
static int    g_iFieldModelIndex = -1;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_Duration;
static float  g_fCvar_Cooldown;
static float  g_fCvar_Cooldown_PlayerEnts;
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
static float  g_fCvar_Intro;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_SkillReadySound[100];
static char   g_sCvar_UseSound[100];
static char   g_sCvar_FieldModel[100];
static char   g_sCvar_FieldColor[12];
static char   g_sCvar_SpriteModel[100];
static char   g_sCvar_SpriteAlpha[4];
static char   g_sCvar_SpriteScale[5];
static char   g_sCvar_SpriteColor[12];
static char   g_sCvar_SpriteFadeDistance[5];
static char   g_sKillDelay[32];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static float  gc_fLastTime[MAXPLAYERS+1];
static float  gc_fLastTimePlayerEnts[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bMoveUp[MAXENTITIES+1];
static int    ge_iOwner[MAXENTITIES+1];
static int    ge_iTeam[MAXENTITIES+1];

// ====================================================================================================
// ArrayLists for Timer Handles
// ====================================================================================================
ArrayList g_entityGlowTimerHandles;
ArrayList g_playerGlowTimerHandles;
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
	LoadPluginTranslations();

	CreateConVar("l4d_spot_marker_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
	g_hCvar_Enabled            = CreateConVar("l4d_spot_marker_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_Duration           = CreateConVar("l4d_spot_marker_duration", "10.0", "Duration (seconds) of the spot marker.", CVAR_FLAGS, true, 0.0);
	g_hCvar_Cooldown           = CreateConVar("l4d_spot_marker_cooldown", "10.0", "Cooldown (seconds) to use the spot marker.", CVAR_FLAGS, true, 0.0);
	g_hCvar_Cooldown_PlayerEnts= CreateConVar("l4d_spot_marker_cooldown_playerEnts", "2.0", "Cooldown (seconds) for marking players or entities.", CVAR_FLAGS, true, 0.0);
	g_hCvar_GlowDropFix        = CreateConVar("l4d_spot_marker_glowdropfix", "1", "Enable/Disable explicitly turning off glows of weapons and items dropped by survivors.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_SkillReadySound    = CreateConVar("l4d_spot_marker_skill_ready_sound", "ui/alert_clink.wav", "Skill ready sound.\nEmpty = OFF.", CVAR_FLAGS);
	g_hCvar_UseSound           = CreateConVar("l4d_spot_marker_use_sound", "buttons/blip1.wav", "Use sound.\nEmpty = OFF.", CVAR_FLAGS);
	g_hCvar_Team               = CreateConVar("l4d_spot_marker_team", "3", "Which teams should be able to create spot markers.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
	g_hCvar_Field              = CreateConVar("l4d_spot_marker_field", "1", "Create a beacon field.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_FieldModel         = CreateConVar("l4d_spot_marker_field_model", "materials/sprites/laserbeam.vmt", "Beacon field model.");
	g_hCvar_FieldColor         = CreateConVar("l4d_spot_marker_field_color", "255 255 0", "Beacon field color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
	g_hCvar_FieldAlpha         = CreateConVar("l4d_spot_marker_field_alpha", "255", "Beacon field alpha transparency.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
	g_hCvar_FieldDuration      = CreateConVar("l4d_spot_marker_field_duration", "1.0", "Time duration of beacon field.", CVAR_FLAGS, true, 0.1);
	g_hCvar_FieldRepeat        = CreateConVar("l4d_spot_marker_field_repeat", "1.0", "Repeat interval to create a beacon field.", CVAR_FLAGS, true, 0.0);
	g_hCvar_FieldStartRadius   = CreateConVar("l4d_spot_marker_field_start_radius", "75.0", "Beacon field start radius.", CVAR_FLAGS, true, 0.0);
	g_hCvar_FieldEndRadius     = CreateConVar("l4d_spot_marker_field_end_radius", "100.0", "Beacon field end radius.", CVAR_FLAGS, true, 0.0);
	g_hCvar_FieldWidth         = CreateConVar("l4d_spot_marker_field_width", "2.0", "Beacon field width.", CVAR_FLAGS, true, 0.0);
	g_hCvar_FieldAmplitude     = CreateConVar("l4d_spot_marker_field_amplitude", "0.0", "Beacon field amplitude.", CVAR_FLAGS, true, 0.0);
	g_hCvar_Sprite             = CreateConVar("l4d_spot_marker_sprite", "1", "Create a sprite.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_SpriteZAxis        = CreateConVar("l4d_spot_marker_sprite_z_axis", "50.0", "Additional Z axis to the sprite.", CVAR_FLAGS, true, 0.0);
	g_hCvar_SpriteModel        = CreateConVar("l4d_spot_marker_sprite_model", "materials/vgui/icon_download.vmt", "Sprite model.");
	g_hCvar_SpriteColor        = CreateConVar("l4d_spot_marker_sprite_color", "255 255 0", "Sprite color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
	g_hCvar_SpriteAlpha        = CreateConVar("l4d_spot_marker_sprite_alpha", "255", "Sprite alpha transparency.\nNote: Some models don't allow to change the alpha.\n0 = Invisible, 255 = Fully Visible", CVAR_FLAGS, true, 0.0, true, 255.0);
	g_hCvar_SpriteScale        = CreateConVar("l4d_spot_marker_sprite_scale", "0.25", "Sprite scale (increases both height and width).\nSome range values maintain the size the same.", CVAR_FLAGS, true, 0.0);
	g_hCvar_SpriteFadeDistance = CreateConVar("l4d_spot_marker_sprite_fade_distance", "-1", "Minimum distance that a client must be before the sprite fades.\n-1 = Always visible.", CVAR_FLAGS, true, -1.0, true, 9999.0);
	g_hCvar_SpriteSpeed        = CreateConVar("l4d_spot_marker_sprite_speed", "1.0", "Speed that the sprite will move at the Z axis.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
	g_hCvar_SpriteMinMax       = CreateConVar("l4d_spot_marker_sprite_min_max", "4.0", "Minimum/Maximum distance between the original position that the sprite should reach before inverting the vertical direction.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
	g_hCvar_Chat               = CreateConVar("l4d_spot_marker_chat", "1", "Display chat message.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_Hint               = CreateConVar("l4d_spot_marker_hint", "1", "Display hint message.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvar_Intro              = CreateConVar("l4d_spot_marker_intro", "60.0", "Show intro message in chat this many seconds after a client joins.\n0 = OFF.", CVAR_FLAGS, true, 0.0);

	// Hook plugin ConVars change
	g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
	g_hCvar_Duration.AddChangeHook(Event_ConVarChanged);
	g_hCvar_Cooldown.AddChangeHook(Event_ConVarChanged);
	g_hCvar_Cooldown_PlayerEnts.AddChangeHook(Event_ConVarChanged);
	g_hCvar_GlowDropFix.AddChangeHook(Event_ConVarChanged);
	g_hCvar_SkillReadySound.AddChangeHook(Event_ConVarChanged);
	g_hCvar_UseSound.AddChangeHook(Event_ConVarChanged);
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
	g_hCvar_Chat.AddChangeHook(Event_ConVarChanged);
	g_hCvar_Hint.AddChangeHook(Event_ConVarChanged);
	g_hCvar_Intro.AddChangeHook(Event_ConVarChanged);

	// Load plugin configs from .cfg
	AutoExecConfig(true, CONFIG_FILENAME);

	// Admin Commands
	RegAdminCmd("sm_spotmarker", CmdSpotMarker, ADMFLAG_ROOT, "Create a spot marker on self crosshair (no args) or specified targets crosshair. Example: self -> sm_spotmarker / target -> sm_spotmarker @bots");
	RegAdminCmd("sm_print_cvars_l4d_spot_marker", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");

	//Proaxel: global Arraylists to store timer handles. The timers turn off the glow a certain amount of time after an item has been marked
	g_entityGlowTimerHandles = new ArrayList(2);
	g_playerGlowTimerHandles = new ArrayList(2);

	//Proaxel: Events used for killing mark glows and timers early 
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("weapon_drop", Event_WeaponDrop, EventHookMode_PostNoCopy); 
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_use", Event_PlayerUse, EventHookMode_Pre);
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
	char targetname[16];

	entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, CLASSNAME_INFO_TARGET)) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "l4d_spot_marker"))
				AcceptEntityInput(entity, "Kill");
		}
	}

	entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, CLASSNAME_ENV_SPRITE)) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "l4d_spot_marker"))
				AcceptEntityInput(entity, "Kill");
		}
	}


	StopAllGlows();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();
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
	g_fCvar_Duration = g_hCvar_Duration.FloatValue;
	g_fCvar_Cooldown = g_hCvar_Cooldown.FloatValue;
	g_fCvar_Cooldown_PlayerEnts = g_hCvar_Cooldown_PlayerEnts.FloatValue;
	g_bCvar_GlowDropFix = g_hCvar_GlowDropFix.BoolValue;
	g_hCvar_SkillReadySound.GetString(g_sCvar_SkillReadySound, sizeof(g_sCvar_SkillReadySound));
	TrimString(g_sCvar_SkillReadySound);
	g_bCvar_SkillReadySound = (g_sCvar_SkillReadySound[0] != 0);
	if (g_bCvar_SkillReadySound)
		PrecacheSound(g_sCvar_SkillReadySound, true);
	g_hCvar_UseSound.GetString(g_sCvar_UseSound, sizeof(g_sCvar_UseSound));
	TrimString(g_sCvar_UseSound);
	g_bCvar_UseSound = (g_sCvar_UseSound[0] != 0);
	if (g_bCvar_UseSound)
		PrecacheSound(g_sCvar_UseSound, true);
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
	g_bCvar_SpriteMinMax =  (g_fCvar_SpriteMinMax > 0.0);
	g_bCvar_Chat = g_hCvar_Chat.BoolValue;
	g_bCvar_Hint = g_hCvar_Hint.BoolValue;
	g_fCvar_Intro = g_hCvar_Intro.FloatValue;
	g_bCvar_Intro = (g_fCvar_Intro > 0.0);

	FormatEx(g_sKillDelay, sizeof(g_sKillDelay), "OnUser1 !self:Kill::%.2f:-1", g_fCvar_Duration);
}

/****************************************************************************************************/

public void LateLoad()
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
    if (!g_bConfigLoaded)
        return;

    if (IsFakeClient(client))
        return;

    if (g_bCvar_Intro)
        CreateTimer(g_fCvar_Intro, TimerIntro, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
	gc_fLastTime[client] = 0.0;
	gc_fLastTimePlayerEnts[client] = 0.0;
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_bMoveUp[entity] = false;
    ge_iOwner[entity] = 0;
    ge_iTeam[entity] = 0;
}

/****************************************************************************************************/

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!g_bConfigLoaded)
		return Plugin_Continue;

	if (!g_bCvar_Enabled)
		return Plugin_Continue;
		
	if (!IsValidClientIndex(client))
		return Plugin_Continue;

	if (IsFakeClient(client))
		return Plugin_Continue;

	//Credit: nsoop https://discordapp.com/channels/335290997317697536/335290997317697536/829263918048346142
	if (buttons & (IN_SPEED | IN_USE) == IN_SPEED | IN_USE) // SHIFT + E
	{
		CreateSpotMarker(client);
		
		//If it's just these two buttons, block the use command so if they're trying to mark an item, they don't accidentally pick it up
		if(buttons == (IN_SPEED | IN_USE))
			buttons &= ~IN_USE;
	}
	//If they have anything else pressed, let the commands continue as normal
	return Plugin_Continue;
}

/****************************************************************************************************/

public void CreateSpotMarker(int client)
{
	/*if (GetGameTime() - gc_fLastTime[client] < g_fCvar_Cooldown)
		return;
	*/

	if (!IsPlayerAlive(client))
		return;

	int team = GetClientTeam(client);

	if (!(GetTeamFlag(team) & g_iCvar_Team))
		return;

	if (team == TEAM_INFECTED)
	{
		if (IsPlayerGhost(client))
			return;
	}

	bool hit;
	float vEndPos[3];
	int whatWasMarked = MARKED_SPOT;
	char entityName[100];
	char entityModel[100];
	int entityRef = -1;

	int clientAim = GetClientAimTarget(client, false);
	if(IsValidEntity(clientAim))
		GetEntPropString(clientAim, Prop_Data, "m_ModelName", entityModel, sizeof(entityModel));

	if (IsValidClientIndex(clientAim))
	{
		if (GetGameTime() - gc_fLastTimePlayerEnts[client] < g_fCvar_Cooldown_PlayerEnts)
			return;
			
		hit = true;
		GetClientAbsOrigin(clientAim, vEndPos);
		whatWasMarked = MARKED_PLAYER;
	}
	//Entities can only be marked if they have a model and the model can glow
	else if(IsValidEntity(clientAim) && StrContains(entityModel, "models", false) != -1 && HasEntProp(clientAim, Prop_Send, "m_iGlowType"))
	{
		if (GetGameTime() - gc_fLastTimePlayerEnts[client] < g_fCvar_Cooldown_PlayerEnts)
			return;
		
		hit = true;
		GetEntPropVector(clientAim, Prop_Send, "m_vecOrigin", vEndPos, 0);
		GetEdictClassname(clientAim, entityName, sizeof(entityName));
		//GetEntPropString(clientAim, Prop_Data, "m_ModelName", entityModel, sizeof(entityModel));
		//PrintToChatAll("%s", entityModel);
		whatWasMarked = MARKED_ENTITY;
		entityRef = EntIndexToEntRef(clientAim);
	}
	else
	{
		if (GetGameTime() - gc_fLastTime[client] < g_fCvar_Cooldown)
			return;
		
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

	switch(whatWasMarked)
	{
		case MARKED_PLAYER:
		{
			gc_fLastTimePlayerEnts[client] = GetGameTime();
		}
		case MARKED_ENTITY:
		{
			gc_fLastTimePlayerEnts[client] = GetGameTime();
		}
		default:
		{
			gc_fLastTime[client] = GetGameTime();
			CreateTimer(g_fCvar_Cooldown, TimerCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	for (int target = 1; target <= MaxClients; target++)
	{
		if (!IsClientInGame(target))
			continue;

		if (IsFakeClient(target))
			continue;

		if (team != GetClientTeam(target))
			continue;

		if (g_bCvar_UseSound)
			EmitSoundToClient(target, g_sCvar_UseSound);

		if (g_bCvar_Chat)
		{
			switch(whatWasMarked)
			{
				case MARKED_PLAYER:
				{
					CPrintToChat(target, "%t", "Player Marked", client, clientAim);
				}
				case MARKED_ENTITY:
				{
					CPrintToChat(target, "%t", "Entity Marked", client, entityName);
				}
				default:
				{
					CPrintToChat(target, "%t", "Spot Marked", client);
				}
			}
		}
		
		if (g_bCvar_Hint)
		{
			switch(whatWasMarked)
			{
				case MARKED_PLAYER:
				{
					CPrintHintText(target, "%t", "Player Marked", client, clientAim);
				}
				case MARKED_ENTITY:
				{
					CPrintHintText(target, "%t", "Entity Marked", client, entityName);
				}
				default:
				{
					CPrintHintText(target, "%t", "Spot Marked", client);
				}
			}
		}
	}

	if (g_bCvar_Field)
	{
		float vBeamPos[3];
		vBeamPos = vEndPos;
		vBeamPos[2] += (g_fCvar_FieldWidth + 1.0); // Change the Z pos to go up according with the width for better looking

		int color[4];
		if (g_bCvar_RandomFieldColor)
		{
			color[0] = GetRandomInt(0, 255);
			color[1] = GetRandomInt(0, 255);
			color[2] = GetRandomInt(0, 255);
			color[3] = g_iCvar_FieldAlpha;
		}
		else
		{
			color[0] = g_iCvar_FieldColor[0];
			color[1] = g_iCvar_FieldColor[1];
			color[2] = g_iCvar_FieldColor[2];
			color[3] = g_iCvar_FieldAlpha;
		}
		
		//Glow for entities:
		//Only applies if it is not the infected team that was marking
		if(team != TEAM_INFECTED && whatWasMarked == MARKED_ENTITY)
		{
			if(GetEntProp(entityRef, Prop_Send, "m_iGlowType") != 3) //Does it already have a glow?
			{
				//If it doesn't, turn its glow on
				SetEntProp(entityRef, Prop_Send, "m_iGlowType", 3);
				
				//Set its timer
				g_entityGlowTimerHandles.Set(g_entityGlowTimerHandles.Push(CreateTimer(g_fCvar_Duration, Timer_StopEntityGlow, entityRef)), entityRef, 1);
				
				//Use red color if what was marked is a witch or (un)common infected
				if(StrEqual(entityName, "witch", false) || StrEqual(entityName, "infected", false))
				{
					SetEntProp(entityRef, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
					return; //Stop here, don't go on to make a beacon or sprite
				}
				else //Use yellow color if it's anything else
					SetEntProp(entityRef, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
				
				//Don't go on to make a beacon or sprite if the entity marked wasn't a weapon, upgrade pack or minigun turret
				if(StrContains(entityName, "weapon", false) == -1 && StrContains(entityName, "upgrade", false) == -1 && StrContains(entityName, "prop_minigun", false) == -1)
				{
					//PrintToChatAll("%d, %d, %d", StrContains(entityName, "weapon", false), StrContains(entityName, "upgrade", false), StrContains(entityName, "prop_minigun", false));
					return;
				}
				else
				{
					//PrintToChatAll("%d, %d, %d", StrContains(entityName, "weapon", false), StrContains(entityName, "upgrade", false), StrContains(entityName, "prop_minigun", false));
				}
			}
			else 
			{
				int index = g_entityGlowTimerHandles.FindValue(entityRef, 1);
				if(index != -1) //If it does already have a glow, is this plugin responsible for that? 
				{
					//If it is delete the timer and restart it
					delete view_as<Handle>(g_entityGlowTimerHandles.Get(index));
					g_entityGlowTimerHandles.Erase(index);
					g_entityGlowTimerHandles.Set(g_entityGlowTimerHandles.Push(CreateTimer(g_fCvar_Duration, Timer_StopEntityGlow, entityRef)), entityRef, 1);
				}
				else //If not, then don't do anything with that glow
				{
					//PrintToChat(client, "\x05[SpotMarkerDebug] \x01This entity already has a glow from something else");
				}
			}
		}
		
		//Glow for players (infected only)
		if(team != TEAM_INFECTED && whatWasMarked == MARKED_PLAYER)
		{
			if(GetEntProp(clientAim, Prop_Send, "m_iGlowType") != 3)//Does the player already have a glow?
			{
				if(GetClientTeam(clientAim) == TEAM_INFECTED)//If they're infected, add the glow, if it's a survivor then skip this and put the normal marker at their position
				{
					SetEntProp(clientAim, Prop_Send, "m_iGlowType", 3);
					SetEntProp(clientAim, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
					g_playerGlowTimerHandles.Set(g_playerGlowTimerHandles.Push(CreateTimer(g_fCvar_Duration, Timer_StopPlayerGlow, clientAim)), clientAim, 1);
					return;  //Stop here, don't go on to make a beacon or sprite
				}
			}
			else
			{
				int index = g_playerGlowTimerHandles.FindValue(clientAim, 1);
				if(index != -1) //If it does already have a glow, is this plugin responsible for that? 
				{
					//If so delete the timer and restart it
					delete view_as<Handle>(g_playerGlowTimerHandles.Get(index));
					g_playerGlowTimerHandles.Erase(index);
					g_playerGlowTimerHandles.Set(g_playerGlowTimerHandles.Push(CreateTimer(g_fCvar_Duration, Timer_StopEntityGlow, clientAim)), clientAim, 1);
					return; //Stop here, don't go on to make a beacon or sprite
				}
				else //If not, then don't do anything with that glow
				{
					//PrintToChat(client, "\x05[SpotMarkerDebug] \x01This player already has a glow from something else");
					if(GetClientTeam(clientAim) == TEAM_INFECTED)
						return;
				}
			
			}
		}
		float timeLimit = GetGameTime() + g_fCvar_Duration;

		DataPack pack;
		CreateDataTimer(g_fCvar_FieldRepeat, TimerField, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(team);
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

			if (team != GetClientTeam(target))
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

		char targetname[19];
		FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_spot_marker", client);

		char color[12];
		if (g_bCvar_RandomSpriteColor)
			FormatEx(color, sizeof(color), "%i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
		else
			color = g_sCvar_SpriteColor;

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
		ge_iTeam[sprite] = team;
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
    int team;
    int color[4];
    float timeLimit;
    float vBeamPos[3];

    pack.Reset();
    team = pack.ReadCell();
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

        if (team != GetClientTeam(target))
            continue;

        targets[targetCount++] = target;
    }

    TE_SetupBeamRingPoint(vBeamPos, g_fCvar_FieldStartRadius, g_fCvar_FieldEndRadius, g_iFieldModelIndex, 0, 0, 0, fieldDuration, g_fCvar_FieldWidth, g_fCvar_FieldAmplitude, color, 0, 0);
    TE_Send(targets, targetCount);

    DataPack pack2;
    CreateDataTimer(g_fCvar_FieldRepeat, TimerField, pack2, TIMER_FLAG_NO_MAPCHANGE);
    pack2.WriteCell(team);
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

public Action TimerMoveSprite(Handle hTimer, int entityRef)
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
//When timer expires, stop glow of the entity that was marked and delete the timer from the ArrayList
public Action Timer_StopEntityGlow(Handle hTimer, int entityRef)
{
	if(EntRefToEntIndex(entityRef) != INVALID_ENT_REFERENCE)
		SetEntProp(entityRef, Prop_Send, "m_iGlowType", 0);

	int index = g_entityGlowTimerHandles.FindValue(hTimer);
	if (index != -1)
	{
		g_entityGlowTimerHandles.Set(index, INVALID_HANDLE);
		g_entityGlowTimerHandles.Erase(index);
	}

	return Plugin_Stop;
}

//Stops glows of all entities that were marked
void StopEntityGlowsAll()
{
	for(int i = 0; i < g_entityGlowTimerHandles.Length; i++)
	{
		int subject = g_entityGlowTimerHandles.Get(i, 1);
		if(EntRefToEntIndex(subject) != INVALID_ENT_REFERENCE && IsValidEntity(subject))
			SetEntProp(subject, Prop_Send, "m_iGlowType", 0);
			

		delete view_as<Handle>(g_entityGlowTimerHandles.Get(i)); 
	}
	g_entityGlowTimerHandles.Clear();
}



/****************************************************************************************************/
//When timer expires, stop glow of player that was marked
public Action Timer_StopPlayerGlow(Handle hTimer, int client)
{
	if(IsValidClient(client))
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);

	int index = g_playerGlowTimerHandles.FindValue(hTimer);
	if (index != -1)
	{
		g_playerGlowTimerHandles.Set(index, INVALID_HANDLE);
		g_playerGlowTimerHandles.Erase(index);
	}

	return Plugin_Stop;
}

//Stops glows of all players that were marked
void StopPlayerGlowsAll()
{
	for(int i = 0; i < g_playerGlowTimerHandles.Length; i++)
	{
		int subject = EntRefToEntIndex(g_playerGlowTimerHandles.Get(i, 1));
		if(IsValidClient(subject))
			SetEntProp(subject, Prop_Send, "m_iGlowType", 0);
		
		delete view_as<Handle>(g_playerGlowTimerHandles.Get(i)); 
	}
	g_playerGlowTimerHandles.Clear();
}

/****************************************************************************************************/
//Stops glows of everything that was marked
void StopAllGlows()
{
	StopEntityGlowsAll();
	StopPlayerGlowsAll();
}
//Turns a glow off for the provided entity reference
void TurnEntGlowOff(int entity)
{
	if(EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE && IsValidEntity(entity))
			SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
}
/****************************************************************************************************/

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	StopAllGlows();
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	StopAllGlows();
}

public void OnMapEnd()
{
	StopAllGlows();
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victimClient = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(victimClient))
	{
		SetEntProp(victimClient, Prop_Send, "m_iGlowType", 0);
	}
}


public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int entityRef = EntIndexToEntRef(event.GetInt("targetid"));
	if(!IsValidEntity(entityRef))
		return;
	char entityName[64];
	GetEntityClassname(entityRef, entityName,sizeof(entityName));
	int index = g_entityGlowTimerHandles.FindValue(entityRef, 1);
	if(EntRefToEntIndex(entityRef) != INVALID_ENT_REFERENCE && StrContains(entityName, "weapon_") != -1 && index != -1)
	{
		TurnEntGlowOff(entityRef);
		delete view_as<Handle>(g_entityGlowTimerHandles.Get(index));
		g_entityGlowTimerHandles.Erase(index);
		//PrintToChatAll("Stopped glow for %s", entityName);
	}
}

//Unsolved bug: If a weapon is marked and then rapidly picked up and dropped, its glow turns on and stays on forever
//This is a bandaid: It explicitly turns off the glow any item that is dropped by a survivor
//If this is causing issues turn it off with l4d_spot_marker_glowdropfix cvar
public void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bCvar_GlowDropFix)
		return;

	int entityRef = EntIndexToEntRef(event.GetInt("propid"));
	if(!IsValidEntity(entityRef))
		return;
	char entityName[64];
	GetEntityClassname(entityRef, entityName,sizeof(entityName));
	//PrintToChatAll("%d, %s", entityRef, entityName);
	//int index = g_entityGlowTimerHandles.FindValue(entityRef, 1);
	if(EntRefToEntIndex(entityRef) != INVALID_ENT_REFERENCE && StrContains(entityName, "weapon_") != -1 && StrContains(entityName, "gascan") == -1 && StrContains(entityName, "cola") == -1)
	{
		TurnEntGlowOff(entityRef);
		//delete view_as<Handle>(g_entityGlowTimerHandles.Get(index));
		//g_entityGlowTimerHandles.Erase(index);
		//PrintToChatAll("Stopped glow for %s", entityName);
	}
	else
	{
		//PrintToChatAll("%d, %d", EntRefToEntIndex(entityRef) != INVALID_ENT_REFERENCE, StrContains(entityName, "weapon_") != -1/*, index != -1*/);
	}
}

/****************************************************************************************************/
public Action OnSetTransmitSprite(int entity, int client)
{
    if (IsFakeClient(client))
        return Plugin_Handled;

    if (ge_iTeam[entity] != GetClientTeam(client))
        return Plugin_Handled;

    return Plugin_Continue;
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

    if (g_bCvar_SkillReadySound)
        EmitSoundToClient(client, g_sCvar_SkillReadySound);

    if (g_bCvar_Chat)
        CPrintToChat(client, "%t", "Skill Ready");

    if (g_bCvar_Hint)
        CPrintHintText(client, "%t", "Skill Ready");

    return Plugin_Stop;
}

/****************************************************************************************************/

public Action TimerIntro(Handle timer, int userid)
{
    if (!g_bCvar_Enabled)
        return;

    int client = GetClientOfUserId(userid);

    if (!IsValidClient(client))
        return;

    if (!(GetTeamFlag(GetClientTeam(client)) & g_iCvar_Team))
        return;

    if (g_bCvar_Chat)
        CPrintToChat(client, "%t", "Intro");

    if (g_bCvar_Hint)
        CPrintHintText(client, "%t", "Intro");
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdSpotMarker(int client, int args)
{
    if (client == 0 && !IsDedicatedServer())
        client = GetHostClient();

    if (!IsValidClient(client))
        return Plugin_Handled;

    if (args == 0) // self
    {
        CreateSpotMarker(client);

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
            CreateSpotMarker(target_list[i]);
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
	PrintToConsole(client, "---------------- Plugin Cvars (l4d_spot_marker) ----------------");
	PrintToConsole(client, "");
	PrintToConsole(client, "l4d_spot_marker_version : %s", PLUGIN_VERSION);
	PrintToConsole(client, "l4d_spot_marker_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_duration : %.2f", g_fCvar_Duration);
	PrintToConsole(client, "l4d_spot_marker_cooldown : %.2f", g_fCvar_Cooldown);
	PrintToConsole(client, "l4d_spot_marker_cooldown_playerEnts : %.2f", g_fCvar_Cooldown_PlayerEnts);
	PrintToConsole(client, "l4d_spot_marker_skill_ready_sound : \"%s\" (%s)", g_sCvar_SkillReadySound, g_bCvar_SkillReadySound ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_use_sound : \"%s\" (%s)", g_sCvar_UseSound, g_bCvar_UseSound ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_team : %i (%s)", g_iCvar_Team, g_bCvar_Team ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_field : %b (%s)", g_bCvar_Field, g_bCvar_Field ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_field_model : \"%s\"", g_sCvar_FieldModel);
	PrintToConsole(client, "l4d_spot_marker_field_color : \"%s\"", g_sCvar_FieldColor);
	PrintToConsole(client, "l4d_spot_marker_field_alpha : %i", g_iCvar_FieldAlpha);
	PrintToConsole(client, "l4d_spot_marker_field_duration : %.2f", g_fCvar_FieldDuration);
	PrintToConsole(client, "l4d_spot_marker_field_repeat : %.2f", g_fCvar_FieldRepeat);
	PrintToConsole(client, "l4d_spot_marker_field_start_radius : %.2f", g_fCvar_FieldStartRadius);
	PrintToConsole(client, "l4d_spot_marker_field_end_radius : %.2f", g_fCvar_FieldEndRadius);
	PrintToConsole(client, "l4d_spot_marker_field_width : %.2f", g_fCvar_FieldWidth);
	PrintToConsole(client, "l4d_spot_marker_field_amplitude : %.2f", g_fCvar_FieldAmplitude);
	PrintToConsole(client, "l4d_spot_marker_sprite : %b (%s)", g_bCvar_Sprite, g_bCvar_Sprite ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_sprite_z_axis : %.2f", g_fCvar_SpriteZAxis);
	PrintToConsole(client, "l4d_spot_marker_sprite_model : \"%s\"", g_sCvar_SpriteModel);
	PrintToConsole(client, "l4d_spot_marker_sprite_color : \"%s\"", g_sCvar_SpriteColor);
	PrintToConsole(client, "l4d_spot_marker_sprite_alpha : %i", g_iCvar_SpriteAlpha);
	PrintToConsole(client, "l4d_spot_marker_sprite_scale : %.2f", g_fCvar_SpriteScale);
	PrintToConsole(client, "l4d_spot_marker_sprite_fade_distance : %i", g_iCvar_SpriteFadeDistance);
	PrintToConsole(client, "l4d_spot_marker_sprite_speed : %.2f (%s)", g_fCvar_SpriteSpeed, g_bCvar_SpriteSpeed ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_sprite_min_max : %.2f (%s)", g_fCvar_SpriteMinMax, g_bCvar_SpriteMinMax ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_chat : %b (%s)", g_bCvar_Chat, g_bCvar_Chat ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_hint : %b (%s)", g_bCvar_Hint, g_bCvar_Hint ? "true" : "false");
	PrintToConsole(client, "l4d_spot_marker_intro : %.2f (%s)", g_fCvar_Intro, g_bCvar_Intro ? "true" : "false");
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
 * Returns the client index that is hosting the listen server.
 */
public int GetHostClient()
{
    int entity = FindEntityByClassname(-1, "terror_player_manager");

    if (!IsValidEntity(entity))
        return 0;

    int offset = FindSendPropInfo("CTerrorPlayerResource", "m_listenServerHost");

    if (offset == -1)
        return 0;

    bool isHost[MAXPLAYERS+1];
    GetEntDataArray(entity, offset, isHost, MAXPLAYERS+1, 1);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (isHost[client])
            return client;
    }

    return 0;
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

/****************************************************************************************************/
