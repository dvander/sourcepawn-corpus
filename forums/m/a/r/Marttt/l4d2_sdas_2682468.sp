// ====================================================================================================
// File
// ====================================================================================================
#file "l4d2_sdas.sp"

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                  "[L4D2] Spitter Dies After Spit (SDAS)"
#define PLUGIN_AUTHOR                "Mart"
#define PLUGIN_DESCRIPTION           "Creates a timer that triggers when the Spitter spits. At the end of the countdown, if the Spitter is alive, it will be killed."
#define PLUGIN_VERSION               "1.1.6"
#define PLUGIN_URL                   "https://forums.alliedmods.net/showthread.php?t=314715"

/*
// ====================================================================================================
Change Log:
1.1.6 (13-July-2019)
    - Created a constant var to hold the flags for the repeating timers.

1.1.5 (8-June-2019)
    - Fixed the client translation (thanks to "Crasher_3637").

1.1.4 (23-April-2019)
    - Added implicit {white} color before the plugin tag and the plugin phrase.
    - Improved client parameter check on timers through "userid".


1.1.3 (15-April-2019)
    - Added console/log error in case of a wrong flag set in the alternative display modes cvars (chat, hint and instructor hint).
    - Improved the plugin behavior in different versions of L4D (L4D1 and L4D2).
    - Removed the "INSTRUCTOR" flag in cvars for the L4D1 version.

1.1.2 (14-April-2019)
    - Fixed the alternative display messages.
    - Added a new configuration through cvar.
        • Alternative display mode for when the hint HUD is hidden.

1.1.1 (10-April-2019)
    - Fixed the plugin name on compile warnings/errors (thanks to "404UNF").

1.1.0 (04-April-2019)
    - Added support to color tags in the translations file: {white}/{lightgreen}/{gold}/{green} (thanks to "Dragokas").
    - Added function to replace color tags from phrases.
    - Added more info on how to color chat tag through the translation file.

1.0.9 (31-March-2019)
    - Fixed a bug where the client dies after respawn when it spits again before the kill timer fires.
    - Fixed a bug preventing to kill a Spitter marked to die when a player goes idle or takes control over a Spitter bot.
    - Fixed a bug in the first read check for the client console vars.
    - Added a better control over hook events (thanks to "Silvers").
    - Added validations in the round start/round end events.
    - Unified "Spit Countdown" and "Dead by Spit" timers into a single one.
    - Decreased the time to kill instructor hint entities (time set to 2 seconds).
    - Removed alpha transparency from instructor hint.
    - Simplified instructor hint display caller.
    - Optimized client indexes checks.
    - Optimized client reset state.
    - Added a new configuration through cvar.
        • Alternative display mode for when the chat HUD is hidden.

1.0.8 (28-March-2019)
    - Fixed a bug in the instructor hint display.
    - Added checks to "gameinstructor_enable" client var to validate if instructor hints are enabled in the client.
    - Added validation to the sound file, if validation fails it will prompt to console and use the default value.
    - Added plugin tag to the translations file.
    - Added information to the translations file relative to the max length that a phrase can have.
    - Highlighted the keywords in phrases with colors.
    - Added function to remove colors from phrases, since colors only work on the chat display mode.
    - Added new configurations through cvars:
        • Enables/disables the plugin tag display based on the display mode.
        • Alternative display mode for the instructor hint, in case the client has it turned off.
        • Customizable sound file name for the spit countdown.

1.0.7 (07-March-2019)
    - Fixed a bug where the client dies after respawn when the previous spit hits the ground.
    - Changed the hook event "spit_burst" to "ability_use" (more accurate) to remove the delay to trigger the plugin when the Spitter spits.
    - Added "console" to the messages as a new display mode.
    - Added "instructor hint" to the messages as a new display mode (thanks to "Lux").
    - Added 5 stages to the countdown message on the instructor hint mode.
    - Added admin command "sm_l4d2_sdas_print_cvars".

1.0.6 (06-March-2019)
    - Fixed immunity flag check (thanks to "Crasher_3637").
    - Added "center text" to the messages as a new display mode.

1.0.5 (05-March-2019)
    - Optimized checks to stop the timer.

1.0.4 (04-March-2019)
    - Fixed a bug where the client dies while in ghost mode.
    - Added checks for when the player is in ghost mode.

1.0.3 (03-March-2019)
    ○ Plugin Improvements.
        - Renamed from "Spitter Auto Kill" to "Spitter Dies After Spit (SDAS)".
        - Renamed the plugin tag to "[SDAS]".
        - Fixed a bug where the client dies after respawn when is killed before the timer triggers.
        - Fixed a bug where the client dies when takes over a Tank.
        - Fixed a bug where the client dies during scrambles/auto-balance/team changes.
        - Fixed a bug where the client dies when a map changes.
        - Added L4D2 engine game check.
        - Added countdown and death messages.
        - Added a sound for the countdown.
        - Changed the chat color to default.
        - Added translation file (en/es/pt) for the messages.
        - Added new configurations through cvars:
            • Enables/disables the plugin.
            • Enables/disables the plugin on bots.
            • Enables/disables the plugin on players by flags.
            • Enables/disables the plugin on game modes (thanks to "Silvers").
            • Enables/disables sound on the countdown.
            • Customizable bitwise message display mode (off/chat/hint) by event (spit/countdown/death).
            • Customizable time that the Spitter will be alive after spitting.

1.0.2 (20-January-2019)
    - Small changes and fixes.

1.0.1 (08-May-2017)
    - Fixed Spitter auto-kill through a timer (thanks to "xines").

1.0.0 (08-May-2017)
    - Initial release (thanks to "diorfo").
        • https://forums.alliedmods.net/showthread.php?t=297227

// ====================================================================================================
*/

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>

// ====================================================================================================
// Defines
// ====================================================================================================
#define FOR_EACH_CLIENT(%1) for (int %1 = 1; %1 <= MaxClients; %1++)

#define MAX_MESSAGE_LENGTH           250

#define DEFAULT_TIMER_REPEAT_FLAGS   TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

#define CVAR_FLAGS                   FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION    FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define TEXTDISPLAY_NONE             (0 << 0) // 0   | 00000
#define TEXTDISPLAY_CHAT             (1 << 0) // 1   | 00001
#define TEXTDISPLAY_HINT             (1 << 1) // 2   | 00010
#define TEXTDISPLAY_CENTER           (1 << 2) // 4   | 00100
#define TEXTDISPLAY_CONSOLE          (1 << 3) // 8   | 01000
#define TEXTDISPLAY_INSTRUCTOR       (1 << 4) // 16  | 10000

#define HIDEHUD_ALL                  (1 << 2) // 4   | 00000100
#define HIDEHUD_MISC                 (1 << 6) // 64  | 01000000
#define HIDEHUD_CHAT                 (1 << 7) // 128 | 10000000

#define TEAM_INFECTED                3
#define L4D2_ZOMBIECLASS_SPITTER     4
#define L4D2_ZOMBIEABILITY_SPITTER    "ability_spit"

#define BLIPSOUND                    "buttons/blip1.wav"

#define CONFIG_FILENAME              "l4d2_sdas"
#define TRANSLATION_FILENAME         "l4d2_sdas.phrases"

// Translations
#define T_PLUGIN_TAG                 "Plugin Tag"
#define T_SPIT                       "Spit"
#define T_SPIT_COUNTDOWN             "Spit Countdown"
#define T_DEAD_BY_SPIT               "Dead By Spit"

// ====================================================================================================
// Native Cvar Handles
// ====================================================================================================
static Handle hCvar_MPGameMode = INVALID_HANDLE;

// ====================================================================================================
// Plugin Cvar Handles
// ====================================================================================================
static Handle hCvar_Enabled = INVALID_HANDLE;
static Handle hCvar_Bots = INVALID_HANDLE;
static Handle hCvar_Flags = INVALID_HANDLE;
static Handle hCvar_AliveTime = INVALID_HANDLE;
static Handle hCvar_SpitCountdown_Sound = INVALID_HANDLE;
static Handle hCvar_SpitCountdown_SoundPath = INVALID_HANDLE;
static Handle hCvar_MsgDisplay_Spit = INVALID_HANDLE;
static Handle hCvar_MsgDisplay_SpitCountdown = INVALID_HANDLE;
static Handle hCvar_MsgDisplay_Death = INVALID_HANDLE;
static Handle hCvar_TagDisplay = INVALID_HANDLE;
static Handle hCvar_AltDisplay_HiddenChatHUD = INVALID_HANDLE;
static Handle hCvar_AltDisplay_HiddenHintHUD = INVALID_HANDLE;
static Handle hCvar_AltDisplay_InstructorHintDisabled = INVALID_HANDLE;
static Handle hCvar_GameModesOn = INVALID_HANDLE;
static Handle hCvar_GameModesOff = INVALID_HANDLE;
static Handle hCvar_GameModesToggle = INVALID_HANDLE;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
static bool   g_bL4D2Version;
static bool   g_bLateLoad;
static bool   g_bHooked;
static bool   bCvar_Enabled;
static bool   bCvar_Bots;
static bool   bCvar_Flags;
static bool   bCvar_SpitCountdown_Sound;

// ====================================================================================================
// int - Plugin Cvar Variables
// ====================================================================================================
static int    iCvar_Flags;
static int    iCvar_AliveTime;
static int    iCvar_MsgDisplay_Spit;
static int    iCvar_MsgDisplay_SpitCountdown;
static int    iCvar_MsgDisplay_Death;
static int    iCvar_TagDisplay;
static int    iCvar_AltDisplay_HiddenChatHUD;
static int    iCvar_AltDisplay_HiddenHintHUD;
static int    iCvar_AltDisplay_InstructorHintDisabled;
static int    iCvar_GameModesToggle;
static int    iCvar_CurrentMode;

// ====================================================================================================
// float - Plugin Cvar Variables
// ====================================================================================================
static float  fCvar_AliveTime;

// ====================================================================================================
// string - Native Cvar Variables
// ====================================================================================================
static char   sCvar_MPGameMode[16];

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
static char   sCvar_Flags[27];
static char   sCvar_AliveTime[12];
static char   sCvar_SpitCountdown_SoundPath[PLATFORM_MAX_PATH] ;
static char   sCvar_GameModesOn[512];
static char   sCvar_GameModesOff[512];

// ====================================================================================================
// Client - Plugin Variables
// ====================================================================================================
static bool   bClient_StopTimer[MAXPLAYERS+1];
static int    iClient_SpitCountdown[MAXPLAYERS+1];

// ====================================================================================================
// Client - Variables
// ====================================================================================================
static bool   bClient_VarGameInstructor[MAXPLAYERS+1];
static int    iClient_VarHideHUD[MAXPLAYERS+1];

// ====================================================================================================
// OnClientPutInServer / OnClientDisconnect / ResetClientState
// ====================================================================================================
public void OnClientPutInServer(int client)
{
    ResetClientState(client);

    GetClientCvars(client);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    ResetClientState(client);
}

/****************************************************************************************************/

void ResetClientState(int client)
{
    bClient_StopTimer[client] = true;
    iClient_SpitCountdown[client] = 0;
    bClient_VarGameInstructor[client] = false;
    iClient_VarHideHUD[client] = 0;
}

// ====================================================================================================
// GetClientCvars
// ====================================================================================================
void GetClientCvars(int client)
{
    if (QueryClientConVar(client, "hidehud", ClientCvarHideHud) == QUERYCOOKIE_FAILED)
        iClient_VarHideHUD[client] = 0;

    if (g_bL4D2Version)
    {
        if (QueryClientConVar(client, "gameinstructor_enable", ClientCvarGameInstructor) == QUERYCOOKIE_FAILED)
            bClient_VarGameInstructor[client] = false;
    }
}

/****************************************************************************************************/

public void ClientCvarGameInstructor(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    bool bCvarValue = StrEqual(cvarValue, "0", false) ? false : true;
    bClient_VarGameInstructor[client] = bCvarValue;
}

/****************************************************************************************************/

public void ClientCvarHideHud(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    int iCvarValue = StringToInt(cvarValue);
    iClient_VarHideHUD[client] = iCvarValue;
}

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
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead 2\" game."); // Spitter class is only available in L4D2
        return APLRes_SilentFailure;
    }

    g_bL4D2Version = (engine == Engine_Left4Dead2);

    g_bLateLoad = late;

    return APLRes_Success;
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    LoadTranslations("common.phrases"); // SourceMod native

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(sPath))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

public void OnPluginStart()
{
    LoadPluginTranslations();

    // Register Plugin ConVars
    hCvar_MPGameMode = FindConVar("mp_gamemode"); // Native Game Mode ConVar
    CreateConVar("l4d2_sdas_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    hCvar_Enabled                               = CreateConVar("l4d2_sdas_enabled",                           "1",  "Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    hCvar_Bots                                  = CreateConVar("l4d2_sdas_bots",                              "1",  "Enables/Disables the plugin behavior on Spitter bots. 0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    hCvar_Flags                                 = CreateConVar("l4d2_sdas_flags",                             "",   "Players with these flags are immune to the plugin behavior. Empty = none.\nKnown values at \"\\addons\\sourcemod\\configs\\admin_levels.cfg\".\nExample: \"az\", will apply immunity to players with \"a\" (reservation) or \"z\" (root) flag.", CVAR_FLAGS);
    hCvar_AliveTime                             = CreateConVar("l4d2_sdas_alive_time",                        "10", "How long (in seconds) will Spitter have after spitting before being killed by the plugin.", CVAR_FLAGS, true, 1.0);
    hCvar_SpitCountdown_Sound                   = CreateConVar("l4d2_sdas_spitcountdown_sound",               "1",  "Enables/Disables a sound during the spit countdown. 0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    hCvar_SpitCountdown_SoundPath               = CreateConVar("l4d2_sdas_spitcountdown_soundpath",           "buttons/blip1.wav", "Sound file name relative to the \"sound\" folder that plays during the spit countdown. Empty = default.", CVAR_FLAGS);
    if (g_bL4D2Version)
    {
        hCvar_MsgDisplay_Spit                   = CreateConVar("l4d2_sdas_msgdisplay_spit",                   "17", "Displays a message to the client when the Spitter spits (1st event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE, 16 = INSTRUCTOR.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 31.0);
        hCvar_MsgDisplay_SpitCountdown          = CreateConVar("l4d2_sdas_msgdisplay_spitcountdown",          "24", "Displays a message to the client during the spit countdown (2nd event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE, 16 = INSTRUCTOR.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 31.0);
        hCvar_MsgDisplay_Death                  = CreateConVar("l4d2_sdas_msgdisplay_death",                  "10", "Displays a message to the client when the Spitter dies by the plugin (3rd event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays as \"CHAT\" (1) and \"HINT\" (2).", CVAR_FLAGS, true, 0.0, true, 15.0);
        hCvar_TagDisplay                        = CreateConVar("l4d2_sdas_tagdisplay",                        "0",  "Adds the plugin tag to the displayed messages.\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE, 16 = INSTRUCTOR.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 31.0);
        hCvar_AltDisplay_HiddenChatHUD          = CreateConVar("l4d2_sdas_altdisplay_hiddenchathud",          "16", "Alternative display mode for the chat, in case the client has the chat HUD hidden.\nKnown values: 0 = OFF, 2 = HINT, 4 = CENTER, 8 = CONSOLE, 16 = INSTRUCTOR.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 30.0);
        hCvar_AltDisplay_HiddenHintHUD          = CreateConVar("l4d2_sdas_altdisplay_hiddenhinthud",          "4",  "Alternative display mode for the hint, in case the client has the hint HUD hidden.\nKnown values: 0 = OFF, 1 = CHAT, 4 = CENTER, 8 = CONSOLE, 16 = INSTRUCTOR.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 29.0);
        hCvar_AltDisplay_InstructorHintDisabled = CreateConVar("l4d2_sdas_altdisplay_instructorhintdisabled", "2",  "Alternative display mode for the instructor hint (L4D2 only), in case the client has it disabled or applied it to the Spitter's death (3rd event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 15.0);
    }
    else
    {
        hCvar_MsgDisplay_Spit                   = CreateConVar("l4d2_sdas_msgdisplay_spit",                   "3",  "Displays a message to the client when the Spitter spits (1st event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 15.0);
        hCvar_MsgDisplay_SpitCountdown          = CreateConVar("l4d2_sdas_msgdisplay_spitcountdown",          "10", "Displays a message to the client during the spit countdown (2nd event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 15.0);
        hCvar_MsgDisplay_Death                  = CreateConVar("l4d2_sdas_msgdisplay_death",                  "10", "Displays a message to the client when the Spitter dies by the plugin (3rd event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays as \"CHAT\" (1) and \"HINT\" (2).", CVAR_FLAGS, true, 0.0, true, 15.0);
        hCvar_TagDisplay                        = CreateConVar("l4d2_sdas_tagdisplay",                        "0",  "Adds the plugin tag to the displayed messages.\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 15.0);
        hCvar_AltDisplay_HiddenChatHUD          = CreateConVar("l4d2_sdas_altdisplay_hiddenchathud",          "2",  "Alternative display mode for the chat, in case the client has the chat HUD hidden.\nKnown values: 0 = OFF, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 14.0);
        hCvar_AltDisplay_HiddenHintHUD          = CreateConVar("l4d2_sdas_altdisplay_hiddenhinthud",          "4",  "Alternative display mode for the hint, in case the client has the hint HUD hidden.\nKnown values: 0 = OFF, 1 = CHAT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 13.0);
        hCvar_AltDisplay_InstructorHintDisabled = CreateConVar("l4d2_sdas_altdisplay_instructorhintdisabled", "2",  "Alternative display mode for the instructor hint (L4D2 only), in case the client has it disabled or applied it to the Spitter's death (3rd event).\nKnown values: 0 = OFF, 1 = CHAT, 2 = HINT, 4 = CENTER, 8 = CONSOLE.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 15.0);
    }
    hCvar_GameModesOn                           = CreateConVar("l4d2_sdas_gamemodes_on",                       "",   "Turn on the plugin in these game modes, separate by commas (no spaces). Empty = all.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
    hCvar_GameModesOff                          = CreateConVar("l4d2_sdas_gamemodes_off",                      "",   "Turn off the plugin in these game modes, separate by commas (no spaces). Empty = none.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
    hCvar_GameModesToggle                       = CreateConVar("l4d2_sdas_gamemodes_toggle",                   "0",  "Turn on the plugin in these game modes.\nKnown values: 0 = all, 1 = coop, 2 = survival, 4 = versus, 8 = scavenge.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for \"coop\" (1) and \"survival\" (2).", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook Plugin ConVars Change
    HookConVarChange(hCvar_MPGameMode, Event_ConVarChanged);
    HookConVarChange(hCvar_Enabled, Event_ConVarChanged);
    HookConVarChange(hCvar_Bots, Event_ConVarChanged);
    HookConVarChange(hCvar_Flags, Event_ConVarChanged);
    HookConVarChange(hCvar_AliveTime, Event_ConVarChanged);
    HookConVarChange(hCvar_SpitCountdown_Sound, Event_ConVarChanged);
    HookConVarChange(hCvar_SpitCountdown_SoundPath, Event_ConVarChanged);
    HookConVarChange(hCvar_MsgDisplay_Spit, Event_ConVarChanged);
    HookConVarChange(hCvar_MsgDisplay_SpitCountdown, Event_ConVarChanged);
    HookConVarChange(hCvar_MsgDisplay_Death, Event_ConVarChanged);
    HookConVarChange(hCvar_TagDisplay, Event_ConVarChanged);
    HookConVarChange(hCvar_AltDisplay_HiddenChatHUD, Event_ConVarChanged);
    HookConVarChange(hCvar_AltDisplay_HiddenHintHUD, Event_ConVarChanged);
    HookConVarChange(hCvar_AltDisplay_InstructorHintDisabled, Event_ConVarChanged);
    HookConVarChange(hCvar_GameModesOn, Event_ConVarChanged);
    HookConVarChange(hCvar_GameModesOff, Event_ConVarChanged);
    HookConVarChange(hCvar_GameModesToggle, Event_ConVarChanged);

    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_l4d2_sdas_print_cvars", AdmCmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    if (g_bLateLoad)
    {
        FOR_EACH_CLIENT(client)
        {
            bClient_StopTimer[client] = true;
        }

        g_bLateLoad = false;
    }
}

// ====================================================================================================
// OnMapStart / Precache
// ====================================================================================================
public void OnMapStart()
{
    PrecacheSounds();
}

/****************************************************************************************************/

void PrecacheSounds()
{
    if (!StrEqual(sCvar_SpitCountdown_SoundPath, "", false))
        PrecacheSound(sCvar_SpitCountdown_SoundPath, true);
}

// ====================================================================================================
// ConVars
// ====================================================================================================
void Event_ConVarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();

    HookEvents();

    FOR_EACH_CLIENT(client)
    {
        bClient_StopTimer[client] = true;
    }
}

/****************************************************************************************************/

void GetCvars()
{
    GetConVarString(hCvar_MPGameMode, sCvar_MPGameMode, sizeof(sCvar_MPGameMode));
    TrimString(sCvar_MPGameMode);
    bCvar_Enabled = GetConVarBool(hCvar_Enabled);
    bCvar_Bots = GetConVarBool(hCvar_Bots);
    GetConVarString(hCvar_Flags, sCvar_Flags, sizeof(sCvar_Flags));
    TrimString(sCvar_Flags);
    iCvar_Flags = ReadFlagString(sCvar_Flags);
    bCvar_Flags = iCvar_Flags > 0;
    iCvar_AliveTime = GetConVarInt(hCvar_AliveTime);
    fCvar_AliveTime = float(iCvar_AliveTime);
    Format(sCvar_AliveTime, sizeof(sCvar_AliveTime), "%i", iCvar_AliveTime);
    bCvar_SpitCountdown_Sound = GetConVarBool(hCvar_SpitCountdown_Sound);
    GetConVarString(hCvar_SpitCountdown_SoundPath, sCvar_SpitCountdown_SoundPath, sizeof(sCvar_SpitCountdown_SoundPath));
    TrimString(sCvar_SpitCountdown_SoundPath);
    if (StrEqual(sCvar_SpitCountdown_SoundPath, "", false))
        sCvar_SpitCountdown_SoundPath = BLIPSOUND;
    char soundPath[PLATFORM_MAX_PATH];
    Format(soundPath, sizeof(soundPath), "sound/%s", sCvar_SpitCountdown_SoundPath);
    if(!FileExists(soundPath, true, NULL_STRING))
    {
        PrintToServer("Error. File \"%s\" not found in \"sound\" folder. The plugin will use the default value \"%s\".", sCvar_SpitCountdown_SoundPath, BLIPSOUND);
        LogError("Error. File \"%s\" not found in \"sound\" folder. The plugin will use the default value \"%s\".", sCvar_SpitCountdown_SoundPath, BLIPSOUND);
        sCvar_SpitCountdown_SoundPath = BLIPSOUND;
        SetConVarString(hCvar_SpitCountdown_SoundPath, sCvar_SpitCountdown_SoundPath);
    }
    PrecacheSounds();
    iCvar_MsgDisplay_Spit = GetConVarInt(hCvar_MsgDisplay_Spit);
    iCvar_MsgDisplay_SpitCountdown = GetConVarInt(hCvar_MsgDisplay_SpitCountdown);
    iCvar_MsgDisplay_Death = GetConVarInt(hCvar_MsgDisplay_Death);
    iCvar_TagDisplay = GetConVarInt(hCvar_TagDisplay);
    iCvar_AltDisplay_HiddenChatHUD = GetConVarInt(hCvar_AltDisplay_HiddenChatHUD);
    if (iCvar_AltDisplay_HiddenChatHUD & TEXTDISPLAY_CHAT)
    {
        PrintToServer("Error. Alternative display to the CHAT, in case the chat hud is hidden, can't be  the \"CHAT\" flag. The plugin will remove this flag from the \"l4d2_sdas_altdisplay_hiddenchathud\" convar, please check if this flag is in your cfg file.");
        LogError("Error. Alternative display to the CHAT, in case the chat hud is hidden, can't be  the \"CHAT\" flag. The plugin will remove this flag from the \"l4d2_sdas_altdisplay_hiddenchathud\" convar, please check if this flag is in your cfg file.");
        iCvar_AltDisplay_HiddenChatHUD &= ~TEXTDISPLAY_CHAT;
        SetConVarInt(hCvar_AltDisplay_HiddenChatHUD, iCvar_AltDisplay_HiddenChatHUD);
    }
    iCvar_AltDisplay_HiddenHintHUD = GetConVarInt(hCvar_AltDisplay_HiddenHintHUD);
    if (iCvar_AltDisplay_HiddenHintHUD & TEXTDISPLAY_HINT)
    {
        PrintToServer("Error. Alternative display to the HINT, in case the hint hud is hidden, can't be the \"HINT\" flag. The plugin will remove this flag from the \"l4d2_sdas_altdisplay_hiddenhinthud\" convar, please check if this flag is in your cfg file.");
        LogError("Error. Alternative display to the HINT, in case the hint hud is hidden, can't be  the \"HINT\" flag. The plugin will remove this flag from the \"l4d2_sdas_altdisplay_hiddenhinthud\" convar, please check if this flag is in your cfg file.");
        iCvar_AltDisplay_HiddenHintHUD &= ~TEXTDISPLAY_HINT;
        SetConVarInt(hCvar_AltDisplay_HiddenHintHUD, iCvar_AltDisplay_HiddenHintHUD);
    }
    iCvar_AltDisplay_InstructorHintDisabled = GetConVarInt(hCvar_AltDisplay_InstructorHintDisabled);
    if (iCvar_AltDisplay_InstructorHintDisabled & TEXTDISPLAY_INSTRUCTOR)
    {
        PrintToServer("Error. Alternative display to the INSTRUCTOR, in case the instructor hint is disabled, can't be the \"INSTRUCTOR\" flag. The plugin will remove this flag from the \"l4d2_sdas_altdisplay_instructorhintdisabled\" convar, please check if this flag is in your cfg file.");
        LogError("Error. Alternative display to the INSTRUCTOR, in case the instructor hint is disabled, can't be the \"INSTRUCTOR\" flag. The plugin will remove this flag from the \"l4d2_sdas_altdisplay_instructorhintdisabled\" convar, please check if this flag is in your cfg file.");
        iCvar_AltDisplay_InstructorHintDisabled &= ~TEXTDISPLAY_INSTRUCTOR;
        SetConVarInt(hCvar_AltDisplay_InstructorHintDisabled, iCvar_AltDisplay_InstructorHintDisabled);
    }
    GetConVarString(hCvar_GameModesOn, sCvar_GameModesOn, sizeof(sCvar_GameModesOn));
    TrimString(sCvar_GameModesOn);
    GetConVarString(hCvar_GameModesOff, sCvar_GameModesOff, sizeof(sCvar_GameModesOff));
    TrimString(sCvar_GameModesOff);
    iCvar_GameModesToggle = GetConVarInt(hCvar_GameModesToggle);
}

// ====================================================================================================
// Hook Events
// ====================================================================================================
void HookEvents()
{
    if (g_bHooked)
    {
        UnhookEvent("round_start", Event_RoundStart);
        UnhookEvent("round_end", Event_RoundEnd);
        UnhookEvent("player_team", Event_PlayerTeam);
        UnhookEvent("spitter_killed", Event_SpitterKilled);
        UnhookEvent("player_bot_replace", Event_BotReplace);
        UnhookEvent("bot_player_replace", Event_PlayerReplace);
        UnhookEvent("ability_use", Event_AbilityUse);

        g_bHooked = false;
    }

    if (bCvar_Enabled && IsAllowedGameMode())
    {
        HookEvent("round_start", Event_RoundStart);
        HookEvent("round_end", Event_RoundEnd);
        HookEvent("player_team", Event_PlayerTeam);
        HookEvent("spitter_killed", Event_SpitterKilled);
        HookEvent("player_bot_replace", Event_BotReplace);
        HookEvent("bot_player_replace", Event_PlayerReplace);
        HookEvent("ability_use", Event_AbilityUse);

        g_bHooked = true;
    }
}

/****************************************************************************************************/

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    FOR_EACH_CLIENT(client)
    {
        ResetClientState(client);
    }
}

/****************************************************************************************************/

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    FOR_EACH_CLIENT(client)
    {
        bClient_StopTimer[client] = true;
    }
}

/****************************************************************************************************/

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsValidClientIndex(client))
        return;

    bClient_StopTimer[client] = true;
}

/****************************************************************************************************/

public Action Event_SpitterKilled(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!IsValidClientIndex(client))
        return;

    bClient_StopTimer[client] = true;
}

/****************************************************************************************************/

public void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    if (!IsValidClientIndex(client))
        return;

    if (!IsValidClientIndex(bot))
        return;

    if (!bClient_StopTimer[client])
    {
        iClient_SpitCountdown[bot] = iClient_SpitCountdown[client];
        bClient_StopTimer[bot] =  bClient_StopTimer[client];
        bClient_StopTimer[client] = true;

        CreateTimer(1.0, tmrKillSpitter, GetClientUserId(bot), DEFAULT_TIMER_REPEAT_FLAGS);
    }
}

/****************************************************************************************************/

public void Event_PlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    if (!IsValidClientIndex(client))
        return;

    if (!IsValidClientIndex(bot))
        return;

    if (!bClient_StopTimer[bot])
    {
        iClient_SpitCountdown[client] = iClient_SpitCountdown[bot];
        bClient_StopTimer[client] =  bClient_StopTimer[bot];
        bClient_StopTimer[bot] = true;
    }

    CreateTimer(1.0, tmrKillSpitter, GetClientUserId(client), DEFAULT_TIMER_REPEAT_FLAGS);
}

/****************************************************************************************************/

public Action Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!bCvar_Enabled)
        return;

    if (!IsAllowedGameMode())
        return;

    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client) && !bCvar_Bots)
        return;

    if (!IsPlayerAlive(client))
        return;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return;

    if (IsPlayerGhost(client))
        return;

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_SPITTER)
        return;

    if (bCvar_Flags && (GetUserFlagBits(client) & iCvar_Flags))
        return;

    char sAbility[16];
    GetEventString(event, "ability", sAbility, sizeof(sAbility));

    if (!StrEqual(sAbility, L4D2_ZOMBIEABILITY_SPITTER, false))
        return;

    bClient_StopTimer[client] = false;

    iClient_SpitCountdown[client] = iCvar_AliveTime;

    CreateTimer(1.0, tmrKillSpitter, GetClientUserId(client), DEFAULT_TIMER_REPEAT_FLAGS);

    if (!IsFakeClient(client))
    {
        GetClientCvars(client);

        if (bCvar_SpitCountdown_Sound)
            EmitSoundToClient(client, sCvar_SpitCountdown_SoundPath);

        int iMsgDisplay = iCvar_MsgDisplay_Spit;

        // Must run thrice to check all combinations
        iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);
        iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);
        iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);

        if (iMsgDisplay != TEXTDISPLAY_NONE)
        {
            char sMessage[MAX_MESSAGE_LENGTH];
            Format(sMessage, sizeof(sMessage), "%t", T_SPIT, iClient_SpitCountdown[client]);

            char sPluginTag[MAX_MESSAGE_LENGTH];
            if (iCvar_TagDisplay != TEXTDISPLAY_NONE)
                Format(sPluginTag, sizeof(sPluginTag), "%t", T_PLUGIN_TAG);

            ReplaceColorTags(sMessage, sizeof(sMessage));
            ReplaceColorTags(sPluginTag, sizeof(sPluginTag));

            if (iMsgDisplay & TEXTDISPLAY_CHAT)
                PrintToChat(client, "\x01%s\x01%s", iCvar_TagDisplay & TEXTDISPLAY_CHAT ? sPluginTag : "", sMessage);

            RemoveColorCodes(sMessage, sizeof(sMessage));
            RemoveColorCodes(sPluginTag, sizeof(sPluginTag));

            if (iMsgDisplay & TEXTDISPLAY_HINT)
                PrintHintText(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_HINT ? sPluginTag : "", sMessage);

            if (iMsgDisplay & TEXTDISPLAY_CENTER)
                PrintCenterText(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_CENTER ? sPluginTag : "", sMessage);

            if (iMsgDisplay & TEXTDISPLAY_CONSOLE)
                PrintToConsole(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_CONSOLE ? sPluginTag : "", sMessage);

            if (g_bL4D2Version)
            {
                if (iMsgDisplay & TEXTDISPLAY_INSTRUCTOR)
                    ShowInstructorHint(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_INSTRUCTOR ? sPluginTag : "", sMessage);
            }
        }
    }
}

// ====================================================================================================
// CheckAltMsgDisplay
// ====================================================================================================
int CheckAltMsgDisplay(int client, int iMsgDisplay)
{
        if (iMsgDisplay & TEXTDISPLAY_CHAT && iCvar_AltDisplay_HiddenChatHUD != TEXTDISPLAY_NONE && IsPlayerChatHUDHidden(client))
            iMsgDisplay |= iCvar_AltDisplay_HiddenChatHUD;

        if (iMsgDisplay & TEXTDISPLAY_HINT && iCvar_AltDisplay_HiddenHintHUD != TEXTDISPLAY_NONE && IsPlayerHintHUDHidden(client))
            iMsgDisplay |= iCvar_AltDisplay_HiddenHintHUD;

        if (g_bL4D2Version)
        {
            if (iMsgDisplay & TEXTDISPLAY_INSTRUCTOR && iCvar_AltDisplay_InstructorHintDisabled != TEXTDISPLAY_NONE && !bClient_VarGameInstructor[client])
                iMsgDisplay |= iCvar_AltDisplay_InstructorHintDisabled;
        }

        return iMsgDisplay;
}

// ====================================================================================================
// ShowInstructorHint
// ====================================================================================================
void ShowInstructorHint(int client, const char[] format, any ...)
{
    char sHintTarget[16];
    Format(sHintTarget, sizeof(sHintTarget), "sdas_hint_%d", client);

    char sHintCaption[100];
    VFormat(sHintCaption, sizeof(sHintCaption), format, 3);

    float fCountdownHeat = float(iClient_SpitCountdown[client]) / fCvar_AliveTime;
    int iCountdownStage;

    if (fCountdownHeat > 0.8)
        iCountdownStage = 0;
    else if (fCountdownHeat > 0.6)
        iCountdownStage = 1;
    else if (fCountdownHeat > 0.4)
        iCountdownStage = 2;
    else if (fCountdownHeat > 0.2)
        iCountdownStage = 3;
    else
        iCountdownStage = 4;

    // Creates a new entity every call because when we use the same entity
    // if another instructor hint appears, the entity stops to display.
    int ent_instructor_hint = CreateEntityByName("env_instructor_hint");

    if (ent_instructor_hint == -1)
    {
        return;
    }
    DispatchKeyValue(client, "targetname", sHintTarget);
    DispatchKeyValue(ent_instructor_hint, "hint_target", sHintTarget);
    DispatchKeyValue(ent_instructor_hint, "hint_caption", sHintCaption);

    switch (iCountdownStage)
    {
        case 0:
        {
            DispatchKeyValue(ent_instructor_hint, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(ent_instructor_hint, "hint_color", "255 255 0"); // #FFFF00 | 255,255,0
            DispatchKeyValue(ent_instructor_hint, "hint_pulseoption", "0");
            DispatchKeyValue(ent_instructor_hint, "hint_shakeoption", "0");
        }
        case 1:
        {
            DispatchKeyValue(ent_instructor_hint, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(ent_instructor_hint, "hint_color", "255 192 0"); // #FFC000 | 255,192,0
            DispatchKeyValue(ent_instructor_hint, "hint_pulseoption", "0");
            DispatchKeyValue(ent_instructor_hint, "hint_shakeoption", "0");
        }
        case 2:
        {
            DispatchKeyValue(ent_instructor_hint, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(ent_instructor_hint, "hint_color", "255 128 0"); // #FF8000 | 255,128,0
            DispatchKeyValue(ent_instructor_hint, "hint_pulseoption", "1");
            DispatchKeyValue(ent_instructor_hint, "hint_shakeoption", "0");
        }
        case 3:
        {
            DispatchKeyValue(ent_instructor_hint, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(ent_instructor_hint, "hint_color", "255 64 0"); // #FF4000 | 255,64,0
            DispatchKeyValue(ent_instructor_hint, "hint_pulseoption", "2");
            DispatchKeyValue(ent_instructor_hint, "hint_shakeoption", "1");
        }
        case 4:
        {
            DispatchKeyValue(ent_instructor_hint, "hint_icon_onscreen", "icon_skull");
            DispatchKeyValue(ent_instructor_hint, "hint_color", "255 0 0"); // #FF0000 | 255,0,0
            DispatchKeyValue(ent_instructor_hint, "hint_pulseoption", "3");
            DispatchKeyValue(ent_instructor_hint, "hint_shakeoption", "2");
        }
    }

    DispatchSpawn(ent_instructor_hint);
    AcceptEntityInput(ent_instructor_hint, "ShowHint");

    SetVariantString("OnUser1 !self:Kill::2:1");
    AcceptEntityInput(ent_instructor_hint, "AddOutput");
    AcceptEntityInput(ent_instructor_hint, "FireUser1");
}

// ====================================================================================================
// Timer Events
// ====================================================================================================
public Action tmrKillSpitter(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (!bCvar_Enabled)
        return Plugin_Stop;

    if (!IsAllowedGameMode())
        return Plugin_Stop;

    if (!IsValidClient(client))
        return Plugin_Stop;

    if (IsFakeClient(client) && !bCvar_Bots)
        return Plugin_Stop;

    if (!IsPlayerAlive(client))
        return Plugin_Stop;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return Plugin_Stop;

    if (IsPlayerGhost(client))
        return Plugin_Stop;

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_SPITTER)
        return Plugin_Stop;

    if (bCvar_Flags && (GetUserFlagBits(client) & iCvar_Flags))
        return Plugin_Stop;

    if (bClient_StopTimer[client])
        return Plugin_Stop;

    iClient_SpitCountdown[client]--;

    if (iClient_SpitCountdown[client] <= 0)
    {
        bClient_StopTimer[client] = true;

        ForcePlayerSuicide(client);

        if (!IsFakeClient(client))
        {
            GetClientCvars(client);

            int iMsgDisplay = iCvar_MsgDisplay_Death;

            // Must run thrice to check all variations
            iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);
            iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);
            iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);

            if (iMsgDisplay != TEXTDISPLAY_NONE)
            {
                char sMessage[192];
                Format(sMessage, sizeof(sMessage), "%t", T_DEAD_BY_SPIT);

                char sPluginTag[192];
                if (iCvar_TagDisplay != TEXTDISPLAY_NONE)
                    Format(sPluginTag, sizeof(sPluginTag), "%t", T_PLUGIN_TAG);

                ReplaceColorTags(sMessage, sizeof(sMessage));
                ReplaceColorTags(sPluginTag, sizeof(sPluginTag));

                if (iMsgDisplay & TEXTDISPLAY_CHAT)
                    PrintToChat(client, "\x01%s\x01%s", iCvar_TagDisplay & TEXTDISPLAY_CHAT ? sPluginTag : "", sMessage);

                RemoveColorCodes(sMessage, sizeof(sMessage));
                RemoveColorCodes(sPluginTag, sizeof(sPluginTag));

                if (iMsgDisplay & TEXTDISPLAY_HINT)
                    PrintHintText(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_HINT ? sPluginTag : "", sMessage);

                if (iMsgDisplay & TEXTDISPLAY_CENTER)
                    PrintCenterText(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_CENTER ? sPluginTag : "", sMessage);

                if (iMsgDisplay & TEXTDISPLAY_CONSOLE)
                    PrintToConsole(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_CONSOLE ? sPluginTag : "", sMessage);
            }

            return Plugin_Stop;
        }
    }
    else
    {
        if (!IsFakeClient(client))
        {
            GetClientCvars(client);

            if (bCvar_SpitCountdown_Sound)
                EmitSoundToClient(client, sCvar_SpitCountdown_SoundPath);

            int iMsgDisplay = iCvar_MsgDisplay_SpitCountdown;

            // Must run thrice to check all variations
            iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);
            iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);
            iMsgDisplay = CheckAltMsgDisplay(client, iMsgDisplay);

            if (iMsgDisplay != TEXTDISPLAY_NONE)
            {
                char sMessage[192];
                Format(sMessage, sizeof(sMessage), "%t", T_SPIT_COUNTDOWN, iClient_SpitCountdown[client]);

                char sPluginTag[192];
                if (iCvar_TagDisplay != TEXTDISPLAY_NONE)
                    Format(sPluginTag, sizeof(sPluginTag), "%t", T_PLUGIN_TAG);

                ReplaceColorTags(sMessage, sizeof(sMessage));
                ReplaceColorTags(sPluginTag, sizeof(sPluginTag));

                if (iMsgDisplay & TEXTDISPLAY_CHAT)
                    PrintToChat(client, "\x01%s\x01%s", iCvar_TagDisplay & TEXTDISPLAY_CHAT ? sPluginTag : "", sMessage);

                RemoveColorCodes(sMessage, sizeof(sMessage));
                RemoveColorCodes(sPluginTag, sizeof(sPluginTag));

                if (iMsgDisplay & TEXTDISPLAY_HINT)
                    PrintHintText(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_HINT ? sPluginTag : "", sMessage);

                if (iMsgDisplay & TEXTDISPLAY_CENTER)
                    PrintCenterText(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_CENTER ? sPluginTag : "", sMessage);

                if (iMsgDisplay & TEXTDISPLAY_CONSOLE)
                    PrintToConsole(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_CONSOLE ? sPluginTag : "", sMessage);

                if (g_bL4D2Version)
                {
                    if (iMsgDisplay & TEXTDISPLAY_INSTRUCTOR)
                        ShowInstructorHint(client, "%s%s", iCvar_TagDisplay & TEXTDISPLAY_INSTRUCTOR ? sPluginTag : "", sMessage);
                }
            }
        }
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands - Print to Console
// ====================================================================================================
Action AdmCmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------- Plugin Cvars (l4d2_sdas) ----------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_sdas_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_sdas_enabled : %b (%s)", bCvar_Enabled, bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_bots : %b (%s)", bCvar_Bots, bCvar_Bots ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_flags : %s (%d)", sCvar_Flags, iCvar_Flags);
    PrintToConsole(client, "l4d2_sdas_alive_time : %i (seconds)", iCvar_AliveTime);
    PrintToConsole(client, "l4d2_sdas_spitcountdown_sound : %b (%s)", bCvar_SpitCountdown_Sound, bCvar_SpitCountdown_Sound ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_spitcountdown_soundpath : %s (sound/)", sCvar_SpitCountdown_SoundPath);
    PrintToConsole(client, "l4d2_sdas_msgdisplay_spit : %i", iCvar_MsgDisplay_Spit);
    PrintToConsole(client, "l4d2_sdas_msgdisplay_spitcountdown : %i", iCvar_MsgDisplay_SpitCountdown);
    PrintToConsole(client, "l4d2_sdas_msgdisplay_death : %i", iCvar_MsgDisplay_Death);
    PrintToConsole(client, "l4d2_sdas_tagdisplay : %i", iCvar_TagDisplay);
    PrintToConsole(client, "l4d2_sdas_altdisplay_hiddenchathud : %i", iCvar_AltDisplay_HiddenChatHUD);
    PrintToConsole(client, "l4d2_sdas_altdisplay_hiddenhinthud : %i", iCvar_AltDisplay_HiddenHintHUD);
    PrintToConsole(client, "l4d2_sdas_altdisplay_instructorhintdisabled : %i", iCvar_AltDisplay_InstructorHintDisabled);
    PrintToConsole(client, "----------------------------------------------------------------------");
    PrintToConsole(client, "mp_gamemode : %s", sCvar_MPGameMode);
    PrintToConsole(client, "l4d2_sdas_gamemodes_on : %s", sCvar_GameModesOn);
    PrintToConsole(client, "l4d2_sdas_gamemodes_off : %s", sCvar_GameModesOff);
    PrintToConsole(client, "l4d2_sdas_gamemodes_toggle : %d", iCvar_GameModesToggle);
    PrintToConsole(client, "IsAllowedGameMode : %b (%s)", IsAllowedGameMode(), IsAllowedGameMode() ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if the current game mode is valid to run the plugin.
 *
 * @return              True if game mode is valid, false otherwise.
 */
bool IsAllowedGameMode()
{
    if (hCvar_MPGameMode == null || hCvar_MPGameMode == INVALID_HANDLE)
        return false;

    if (iCvar_GameModesToggle != 0)
    {
        int entity = CreateEntityByName("info_gamemode");
        DispatchSpawn(entity);
        HookSingleEntityOutput(entity, "OnCoop", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnSurvival", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnVersus", OnGameMode, true);
        HookSingleEntityOutput(entity, "OnScavenge", OnGameMode, true);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "PostSpawnActivate");
        AcceptEntityInput(entity, "Kill");

        if (iCvar_CurrentMode == 0)
            return false;

        if (!(iCvar_GameModesToggle & iCvar_CurrentMode))
            return false;
    }

    char sGameModes[512], sGameMode[512];
    strcopy(sGameMode, sizeof(sCvar_MPGameMode), sCvar_MPGameMode);
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    strcopy(sGameModes, sizeof(sCvar_GameModesOn), sCvar_GameModesOn);
    if (!StrEqual(sGameModes, "", false))
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) == -1)
            return false;
    }

    strcopy(sGameModes, sizeof(sCvar_GameModesOff), sCvar_GameModesOff);
    if (!StrEqual(sGameModes, "", false))
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if (StrContains(sGameModes, sGameMode, false) != -1)
            return false;
    }

    return true;
}

/****************************************************************************************************/

/**
 * Sets the running game mode int value.
 *
 * @param output        output.
 * @param caller        caller.
 * @param activator     activator.
 * @param delay         delay.
 * @noreturn
 */
int OnGameMode(const char[] output, int caller, int activator, float delay)
{
    if (StrEqual(output, "OnCoop", false))
        iCvar_CurrentMode = 1;
    else if (StrEqual(output, "OnSurvival", false))
        iCvar_CurrentMode = 2;
    else if (StrEqual(output, "OnVersus", false))
        iCvar_CurrentMode = 4;
    else if (StrEqual(output, "OnScavenge", false))
        iCvar_CurrentMode = 8;
    else
        iCvar_CurrentMode = 0;
}

/****************************************************************************************************/

/**
 * Get the specific L4D2 zombie class id from the client.
 *
 * @return L4D          1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2         1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED

 */
int GetZombieClass(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass");
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
    return (1 <= client <= MaxClients && IsClientInGame(client));
}

/****************************************************************************************************/

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
 * Validates if the client is a ghost.
 *
 * @param client        Client index.
 * @return              True if client is a ghost, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1;
}

/****************************************************************************************************/

/**
 * Validates if the client has the chat HUD hidden.
 *
 * @param client        Client index.
 * @return              True if client has the chat HUD hidden, false otherwise.
 */
bool IsPlayerChatHUDHidden(int client)
{
    if (iClient_VarHideHUD[client] != 0)
    {
        if (iClient_VarHideHUD[client] & HIDEHUD_ALL || iClient_VarHideHUD[client] & HIDEHUD_CHAT)
            return true;
    }

    return GetEntProp(client, Prop_Send, "m_iHideHUD") & HIDEHUD_ALL || GetEntProp(client, Prop_Send, "m_iHideHUD") & HIDEHUD_CHAT;
}

/****************************************************************************************************/

/**
 * Validates if the client has the hint HUD hidden.
 *
 * @param client        Client index.
 * @return              True if client has the hint HUD hidden, false otherwise.
 */
bool IsPlayerHintHUDHidden(int client)
{
    if (iClient_VarHideHUD[client] != 0)
    {
        if (iClient_VarHideHUD[client] & HIDEHUD_ALL || iClient_VarHideHUD[client] & HIDEHUD_MISC)
            return true;
    }

    return GetEntProp(client, Prop_Send, "m_iHideHUD") & HIDEHUD_ALL || GetEntProp(client, Prop_Send, "m_iHideHUD") & HIDEHUD_MISC;
}

/****************************************************************************************************/

/**
 * Replaces tag colors with color codes from a text.
 *
 * @param text          Text.
 * @param maxLength     Max text length.
 * @noreturn
 */
void ReplaceColorTags(char[] text, int maxLength)
{
    ReplaceString(text, maxLength, "{white}", "\x01", false);
    ReplaceString(text, maxLength, "{lightgreen}", "\x03", false);
    ReplaceString(text, maxLength, "{gold}", "\x04", false);
    ReplaceString(text, maxLength, "{green}", "\x05", false);
}

/****************************************************************************************************/

/**
 * Removes color codes from a text.
 *
 * @param text          Text.
 * @param maxLength     Max text length.
 * @noreturn
 */
void RemoveColorCodes(char[] text, int maxLength)
{
    ReplaceString(text, maxLength, "\x01", "", false); // Default/White
    ReplaceString(text, maxLength, "\x03", "", false); // Light Green
    ReplaceString(text, maxLength, "\x04", "", false); // Gold
    ReplaceString(text, maxLength, "\x05", "", false); // Green
}