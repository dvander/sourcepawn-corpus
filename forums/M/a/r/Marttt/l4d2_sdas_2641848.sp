/**
// ====================================================================================================
Change Log:

1.2.1 (29-April-2021)
    - New version released.
    - Added Hungarian (hu) translation. (thanks to "KasperH")
    - Added Romanian (ro) translation. (thanks to "CryWolf")

1.0.0 (03-March-2019)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Spitter Dies After Spit (SDAS)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Kills the Spitter some seconds later after spitting"
#define PLUGIN_VERSION                "1.2.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=314715"

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
#define CONFIG_FILENAME               "l4d2_sdas"
#define TRANSLATION_FILENAME          "l4d2_sdas.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_INFECTED                 3

#define L4D2_ZOMBIECLASS_SPITTER      4

#define FLAG_MSG_DISPLAY_CHAT         (1 << 0) // 1 | 001
#define FLAG_MSG_DISPLAY_HINT         (1 << 1) // 2 | 010
#define FLAG_MSG_DISPLAY_INSTRUCTOR   (1 << 2) // 3 | 100

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Bots;
ConVar g_hCvar_Flags;
ConVar g_hCvar_AliveTime;
ConVar g_hCvar_CountdownSound;
ConVar g_hCvar_SpitMsg;
ConVar g_hCvar_SpitCountdownMsg;
ConVar g_hCvar_DeadBySpitMsg;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;
bool g_bCvar_Bots;
bool g_bCvar_Flags;
bool g_bCvar_CountdownSound;

// ====================================================================================================
// int - Plugin Cvar Variables
// ====================================================================================================
int g_iCvar_Flags;
int g_iCvar_AliveTime;
int g_iCvar_SpitMsg;
int g_iCvar_SpitCountdownMsg;
int g_iCvar_DeadBySpitMsg;

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
char g_sCvar_Flags[27];
char g_sCvar_CountdownSound[PLATFORM_MAX_PATH];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
int gc_iClient_SpitCountdown[MAXPLAYERS+1];

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
    LoadPluginTranslations();

    CreateConVar("l4d2_sdas_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled          = CreateConVar("l4d2_sdas_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Bots             = CreateConVar("l4d2_sdas_bots", "1", "Enables/Disables the plugin behaviour on Spitter bots.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Flags            = CreateConVar("l4d2_sdas_flags", "", "Players with these flags are immune to the plugin behaviour.\nEmpty = none.\nKnown values at \"\\addons\\sourcemod\\configs\\admin_levels.cfg\".\nExample: \"az\", will apply immunity to players with \"a\" (reservation) or \"z\" (root) flag.", CVAR_FLAGS);
    g_hCvar_AliveTime        = CreateConVar("l4d2_sdas_alive_time", "10", "How long (in seconds) will Spitter have after spitting before being killed by the plugin.", CVAR_FLAGS, true, 1.0);
    g_hCvar_CountdownSound   = CreateConVar("l4d2_sdas_countdown_sound", "buttons/blip1.wav", "Spitter countdown sound after spit.\nEmpty = OFF.", CVAR_FLAGS);
    g_hCvar_SpitMsg          = CreateConVar("l4d2_sdas_spit_msg", "5", "Display type for the \"Spit\" message.\n0 = OFF, 1 = CHAT, 2 = HINT, 4 = INSTRUCTOR HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_SpitCountdownMsg = CreateConVar("l4d2_sdas_spit_countdown_msg", "5", "Display type for the \"Spit Countdown\" message.\n0 = OFF, 1 = CHAT, 2 = HINT, 4 = INSTRUCTOR HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 7.0);
    g_hCvar_DeadBySpitMsg    = CreateConVar("l4d2_sdas_dead_by_spit_msg", "3", "Display type for the \"Dead By Spit\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Bots.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Flags.AddChangeHook(Event_ConVarChanged);
    g_hCvar_AliveTime.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CountdownSound.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpitMsg.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpitCountdownMsg.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeadBySpitMsg.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_sdas", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
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
    g_hCvar_Flags.GetString(g_sCvar_Flags, sizeof(g_sCvar_Flags));
    TrimString(g_sCvar_Flags);
    g_iCvar_Flags = ReadFlagString(g_sCvar_Flags);
    g_bCvar_Flags = g_iCvar_Flags > 0;
    g_iCvar_AliveTime = g_hCvar_AliveTime.IntValue;
    g_hCvar_CountdownSound.GetString(g_sCvar_CountdownSound, sizeof(g_sCvar_CountdownSound));
    TrimString(g_sCvar_CountdownSound);
    g_bCvar_CountdownSound = (g_sCvar_CountdownSound[0] != 0);
    if (g_bCvar_CountdownSound)
        PrecacheSound(g_sCvar_CountdownSound, true);
    g_iCvar_SpitMsg = g_hCvar_SpitMsg.IntValue;
    g_iCvar_SpitCountdownMsg = g_hCvar_SpitCountdownMsg.IntValue;
    g_iCvar_DeadBySpitMsg = g_hCvar_DeadBySpitMsg.IntValue;
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iClient_SpitCountdown[client] = 0;
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

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    char ability[16];
    event.GetString("ability", ability, sizeof(ability));

    if (!StrEqual(ability, "ability_spit"))
        return;

    if (client == 0)
        return;

    if (!IsValidSpitter(client))
        return;

    gc_iClient_SpitCountdown[client] = g_iCvar_AliveTime;

    CreateTimer(1.0, TimerKillSpitter, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

    if (!IsFakeClient(client))
    {
        if (g_bCvar_CountdownSound)
            EmitSoundToClient(client, g_sCvar_CountdownSound);

        if (g_iCvar_SpitMsg & FLAG_MSG_DISPLAY_CHAT)
            CPrintToChat(client, "%t", "Spit", gc_iClient_SpitCountdown[client]);

        if (g_iCvar_SpitMsg & FLAG_MSG_DISPLAY_HINT)
            CPrintHintText(client, "%t", "Spit", gc_iClient_SpitCountdown[client]);

        if (g_iCvar_SpitMsg & FLAG_MSG_DISPLAY_INSTRUCTOR)
            PrintInstructorHintText(client, "%t", "Spit", gc_iClient_SpitCountdown[client]);
    }
}

/****************************************************************************************************/

Action TimerKillSpitter(Handle timer, int userid)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    int client = GetClientOfUserId(userid);

    if (client == 0)
        return Plugin_Stop;

    if (!IsValidSpitter(client))
        return Plugin_Stop;

    gc_iClient_SpitCountdown[client]--;

    if (gc_iClient_SpitCountdown[client] > 0)
    {
        if (!IsFakeClient(client))
        {
            if (g_bCvar_CountdownSound)
                EmitSoundToClient(client, g_sCvar_CountdownSound);

            if (g_iCvar_SpitCountdownMsg & FLAG_MSG_DISPLAY_CHAT)
                CPrintToChat(client, "%t", "Spit Countdown", gc_iClient_SpitCountdown[client]);

            if (g_iCvar_SpitCountdownMsg & FLAG_MSG_DISPLAY_HINT)
                CPrintHintText(client, "%t", "Spit Countdown", gc_iClient_SpitCountdown[client]);

            if (g_iCvar_SpitCountdownMsg & FLAG_MSG_DISPLAY_INSTRUCTOR)
                PrintInstructorHintText(client, "%t", "Spit Countdown", gc_iClient_SpitCountdown[client]);

            return Plugin_Continue;
        }
    }
    else
    {
        ForcePlayerSuicide(client);

        if (!IsFakeClient(client))
        {
            if (g_iCvar_DeadBySpitMsg & FLAG_MSG_DISPLAY_CHAT)
                CPrintToChat(client, "%t", "Dead By Spit");

            if (g_iCvar_DeadBySpitMsg & FLAG_MSG_DISPLAY_HINT)
                CPrintHintText(client, "%t", "Dead By Spit");

            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

void PrintInstructorHintText(int client, char[] message, any ...)
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

    char hintTarget[18];
    Format(hintTarget, sizeof(hintTarget), "l4d2_sdas_hint_%i", client);

    float fCountdownHeat = float(gc_iClient_SpitCountdown[client]) / g_iCvar_AliveTime;
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
    int entity = CreateEntityByName("env_instructor_hint");
    DispatchKeyValue(client, "targetname", hintTarget);
    DispatchKeyValue(entity, "hint_target", hintTarget);
    DispatchKeyValue(entity, "targetname", "l4d2_sdas");
    DispatchKeyValue(entity, "hint_caption", buffer);

    switch (iCountdownStage)
    {
        case 0:
        {
            DispatchKeyValue(entity, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(entity, "hint_color", "255 255 0"); // #FFFF00 | 255,255,0
            DispatchKeyValue(entity, "hint_pulseoption", "0");
            DispatchKeyValue(entity, "hint_shakeoption", "0");
        }
        case 1:
        {
            DispatchKeyValue(entity, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(entity, "hint_color", "255 192 0"); // #FFC000 | 255,192,0
            DispatchKeyValue(entity, "hint_pulseoption", "0");
            DispatchKeyValue(entity, "hint_shakeoption", "0");
        }
        case 2:
        {
            DispatchKeyValue(entity, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(entity, "hint_color", "255 128 0"); // #FF8000 | 255,128,0
            DispatchKeyValue(entity, "hint_pulseoption", "1");
            DispatchKeyValue(entity, "hint_shakeoption", "0");
        }
        case 3:
        {
            DispatchKeyValue(entity, "hint_icon_onscreen", "icon_alert_red");
            DispatchKeyValue(entity, "hint_color", "255 64 0"); // #FF4000 | 255,64,0
            DispatchKeyValue(entity, "hint_pulseoption", "2");
            DispatchKeyValue(entity, "hint_shakeoption", "1");
        }
        case 4:
        {
            DispatchKeyValue(entity, "hint_icon_onscreen", "icon_skull");
            DispatchKeyValue(entity, "hint_color", "255 0 0"); // #FF0000 | 255,0,0
            DispatchKeyValue(entity, "hint_pulseoption", "3");
            DispatchKeyValue(entity, "hint_shakeoption", "2");
        }
    }

    DispatchSpawn(entity);
    AcceptEntityInput(entity, "ShowHint", client);

    SetVariantString("OnUser1 !self:Kill::1:-1");
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser1");

    DispatchKeyValue(client, "targetname", clienttargetname); // Rollback the client targetname
}

/****************************************************************************************************/

bool IsValidSpitter(int client)
{
    if (!IsValidClient(client))
        return false;

    if (IsFakeClient(client) && !g_bCvar_Bots)
        return false;

    if (g_bCvar_Flags && (GetUserFlagBits(client) & g_iCvar_Flags))
        return false;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (GetZombieClass(client) != L4D2_ZOMBIECLASS_SPITTER)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    return true;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------- Plugin Cvars (l4d2_sdas) ----------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_sdas_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_sdas_enabled : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_bots : %b (%s)", g_bCvar_Bots, g_bCvar_Bots ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_flags : %s (%i)", g_sCvar_Flags, g_iCvar_Flags);
    PrintToConsole(client, "l4d2_sdas_alive_time : %i (seconds)", g_iCvar_AliveTime);
    PrintToConsole(client, "l4d2_sdas_countdown_sound : \"%s\"", g_sCvar_CountdownSound);
    PrintToConsole(client, "l4d2_sdas_spit_msg : %i (CHAT: %s | HINT: %s | INSTRUCTOR: %s)", g_iCvar_SpitMsg, g_iCvar_SpitMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_SpitMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF", g_iCvar_SpitMsg & FLAG_MSG_DISPLAY_INSTRUCTOR ? "ON" : "OFF");
    PrintToConsole(client, "l4d2_sdas_spit_countdown_msg : %i (CHAT: %s | HINT: %s | INSTRUCTOR: %s)", g_iCvar_SpitCountdownMsg, g_iCvar_SpitCountdownMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_SpitCountdownMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF", g_iCvar_SpitCountdownMsg & FLAG_MSG_DISPLAY_INSTRUCTOR ? "ON" : "OFF");
    PrintToConsole(client, "l4d2_sdas_dead_by_spit_msg : %i (CHAT: %s | HINT: %s)", g_iCvar_DeadBySpitMsg, g_iCvar_DeadBySpitMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", g_iCvar_DeadBySpitMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
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
 * Returns if the client is in ghost state.
 *
 * @param client        Client index.
 * @return              True if client is in ghost state, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
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
void CPrintToChat(int client, char[] message, any ...)
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
void CPrintHintText(int client, char[] message, any ...)
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