/**
// ====================================================================================================
Change Log:

1.0.2 (19-July-2022)
    - Minor logic changes to fade duration.

1.0.1 (04-September-2021)
    - Added cvar to block other fade effects while plugin fade is active. (thanks "R.A" for requesting)
    - Tweaked timer code.

1.0.0 (31-August-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Vomit Screen Fade"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds a blind fade effect while on vomit"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=334143"

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
#tryinclude <left4dhooks> // Download here: https://forums.alliedmods.net/showthread.php?t=321696

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
#define CONFIG_FILENAME               "l4d_vomit_screen_fade"

// ====================================================================================================
// Defines
// ====================================================================================================
#define FFADE_IN                      0x0001
#define FFADE_OUT                     0x0002
#define FFADE_STAYOUT                 0x0008
#define FFADE_PURGE                   0x0010

#define SCREENFADE_FRACBITS           (1 << 9) // 512

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Color;
ConVar g_hCvar_Alpha;
ConVar g_hCvar_FadeOutDuration;
ConVar g_hCvar_FadeHoldDuration;
ConVar g_hCvar_FadeInDuration;
ConVar g_hCvar_Block;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bLeft4DHooks;
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_RandomColor;
bool g_bCvar_Block;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Color[3];
int g_iCvar_Alpha;
int g_iFadeOutDuration;
int g_iFadeInDuration;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_FadeOutDuration;
float g_fCvar_FadeHoldDuration;
float g_fCvar_FadeInDuration;
float g_fFadeDuration;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sCvar_Color[12];

// ====================================================================================================
// UserMsg - Plugin Variables
// ====================================================================================================
UserMsg g_umFade;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bFade[MAXPLAYERS+1];
int gc_iColor[MAXPLAYERS+1][3];
float gc_fNextFade[MAXPLAYERS+1];

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

public void OnLibraryAdded(const char[] name)
{
    if (!g_bLeft4DHooks && StrEqual(name, "left4dhooks"))
        g_bLeft4DHooks = true;
}

/****************************************************************************************************/

public void OnLibraryRemoved(const char[] name)
{
    if (g_bLeft4DHooks && StrEqual(name, "left4dhooks"))
        g_bLeft4DHooks = false;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    g_umFade = GetUserMessageId("Fade");

    CreateConVar("l4d_vomit_screen_fade_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled          = CreateConVar("l4d_vomit_screen_fade_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Color            = CreateConVar("l4d_vomit_screen_fade_color", "0 20 0", "Fade color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\").", CVAR_FLAGS);
    g_hCvar_Alpha            = CreateConVar("l4d_vomit_screen_fade_alpha", "245", "Fade alpha transparency.\n0 = Invisible, 255 = Fully Visible.", CVAR_FLAGS, true, 0.0, true, 255.0);
    g_hCvar_FadeOutDuration  = CreateConVar("l4d_vomit_screen_fade_out_duration", "6.0", "Fade out (start) duration in seconds.", CVAR_FLAGS, true, 0.0);
    g_hCvar_FadeHoldDuration = CreateConVar("l4d_vomit_screen_fade_hold_duration", "3.0", "Fade hold (between) duration in seconds.\n0 = Disable.", CVAR_FLAGS, true, 0.1);
    g_hCvar_FadeInDuration   = CreateConVar("l4d_vomit_screen_fade_in_duration", "6.0", "Fade in (end) duration in seconds.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Block            = CreateConVar("l4d_vomit_screen_fade_block", "1", "Block other fade effects applied to the client while on plugin fade.\nExample: Red screen when take damage.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Color.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Alpha.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FadeOutDuration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FadeHoldDuration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_FadeInDuration.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Block.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_vomitfade", CmdVomitFade, ADMFLAG_ROOT, "Add a fade effect on self (no args) or specified targets. Example: self -> sm_vomitfade / target -> sm_vomitfade @humans.");
    RegAdminCmd("sm_print_cvars_l4d_vomit_screen_fade", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    g_hCvar_Color.GetString(g_sCvar_Color, sizeof(g_sCvar_Color));
    TrimString(g_sCvar_Color);
    g_bCvar_RandomColor = StrEqual(g_sCvar_Color, "random", false);
    g_iCvar_Color = ConvertRGBToIntArray(g_sCvar_Color);
    g_iCvar_Alpha = g_hCvar_Alpha.IntValue;
    g_fCvar_FadeOutDuration = g_hCvar_FadeOutDuration.FloatValue;
    g_iFadeOutDuration = RoundFloat(g_fCvar_FadeOutDuration * SCREENFADE_FRACBITS);
    g_fCvar_FadeHoldDuration = g_hCvar_FadeHoldDuration.FloatValue;
    g_fCvar_FadeInDuration = g_hCvar_FadeInDuration.FloatValue;
    g_iFadeInDuration = RoundFloat(g_fCvar_FadeInDuration * SCREENFADE_FRACBITS);
    g_fFadeDuration = (g_fCvar_FadeOutDuration + g_fCvar_FadeHoldDuration + g_fCvar_FadeInDuration);
    g_bCvar_Block = g_hCvar_Block.BoolValue;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("player_now_it", Event_PlayerNowIt);
        HookUserMessage(g_umFade, FadeHook, true);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("player_now_it", Event_PlayerNowIt);
        UnhookUserMessage(g_umFade, FadeHook, true);

        return;
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bFade[client] = false;
    gc_iColor[client] = {0, 0, 0};
    gc_fNextFade[client] = 0.0;
}

/****************************************************************************************************/

Action FadeHook(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
    if (!g_bCvar_Block)
        return Plugin_Continue;

    if (playersNum != 1)
        return Plugin_Continue;

    int client = players[0];

    if (!IsValidClient(client))
        return Plugin_Continue;

    if (IsFakeClient(client))
        return Plugin_Continue;

    if (gc_fNextFade[client] == 0.0 || gc_fNextFade[client] < GetGameTime())
        return Plugin_Continue;

    if (gc_bFade[client])
    {
        gc_bFade[client] = false;
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bLeft4DHooks)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    PerformFadeOut(client);
}

/****************************************************************************************************/

public void L4D_OnVomitedUpon_Post(int victim, int attacker, bool boomerExplosion)
{
    if (!g_bCvar_Enabled)
        return;

    PerformFadeOut(victim);
}

/****************************************************************************************************/

void PerformFadeOut(int client)
{
    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
        return;

    if (g_bCvar_RandomColor)
    {
        gc_iColor[client][0] = GetRandomInt(0, 255);
        gc_iColor[client][1] = GetRandomInt(0, 255);
        gc_iColor[client][2] = GetRandomInt(0, 255);
    }
    else
    {
        gc_iColor[client] = g_iCvar_Color;
    }

    gc_bFade[client] = true;
    gc_fNextFade[client] = GetGameTime() + g_fFadeDuration;
    ScreenFade(client, g_iFadeOutDuration, SCREENFADE_FRACBITS, FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT, gc_iColor[client][0], gc_iColor[client][1], gc_iColor[client][2], g_iCvar_Alpha);

    DataPack packOut;
    CreateDataTimer(g_fFadeDuration, TimerFadeIn, packOut, TIMER_FLAG_NO_MAPCHANGE);
    packOut.WriteCell(GetClientUserId(client));
    packOut.WriteFloat(gc_fNextFade[client]);
}

/****************************************************************************************************/

void PerformFadeIn(int client)
{
    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
        return;

    gc_bFade[client] = true;
    ScreenFade(client, g_iFadeInDuration, SCREENFADE_FRACBITS, FFADE_PURGE|FFADE_IN, gc_iColor[client][0], gc_iColor[client][1], gc_iColor[client][2], g_iCvar_Alpha);
}

/****************************************************************************************************/

Action TimerFadeIn(Handle timer, DataPack pack)
{
    int client;
    float nextFade;

    pack.Reset();
    client = GetClientOfUserId(pack.ReadCell());

    if (client == 0)
        return Plugin_Stop;

    nextFade = pack.ReadFloat();

    if (nextFade != gc_fNextFade[client])
        return Plugin_Stop;

    PerformFadeIn(client);

    return Plugin_Stop;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdVomitFade(int client, int args)
{
    int target_count;
    int target_list[MAXPLAYERS];

    if (args == 0) // self
    {
        if (IsValidClient(client))
        {
            target_count = 1;
            target_list[0] = client;
        }
    }
    else // specified target
    {
        char arg1[MAX_TARGET_LENGTH];
        GetCmdArg(1, arg1, sizeof(arg1));

        char target_name[MAX_TARGET_LENGTH];
        bool tn_is_ml;

        if ((target_count = ProcessTargetString(
            arg1,
            client,
            target_list,
            sizeof(target_list),
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            ReplyToTargetError(client, target_count);
        }
    }

    for (int i = 0; i < target_count; i++)
    {
        PerformFadeOut(target_list[i]);
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_vomit_screen_fade) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_vomit_screen_fade_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_vomit_screen_fade_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_vomit_screen_fade_color : \"%s\"", g_sCvar_Color);
    PrintToConsole(client, "l4d_vomit_screen_fade_alpha : %i", g_iCvar_Alpha);
    PrintToConsole(client, "l4d_vomit_screen_fade_out_duration : %.1f", g_fCvar_FadeOutDuration);
    PrintToConsole(client, "l4d_vomit_screen_fade_hold_duration : %.1f", g_fCvar_FadeHoldDuration);
    PrintToConsole(client, "l4d_vomit_screen_fade_in_duration : %.1f", g_fCvar_FadeInDuration);
    PrintToConsole(client, "l4d_vomit_screen_fade_block : %b (%s)", g_bCvar_Block, g_bCvar_Block ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", g_bLeft4DHooks ? "true" : "false");
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

void ScreenFade(int client, int delay, int duration, int type, int red, int green, int blue, int alpha)
{
    Handle message = StartMessageOne("Fade", client);
    BfWrite bf = UserMessageToBfWrite(message);
    bf.WriteShort(delay);
    bf.WriteShort(duration);
    bf.WriteShort(type);
    bf.WriteByte(red);
    bf.WriteByte(green);
    bf.WriteByte(blue);
    bf.WriteByte(alpha);
    EndMessage();
}