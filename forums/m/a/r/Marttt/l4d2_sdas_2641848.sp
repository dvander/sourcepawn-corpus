/**
// ====================================================================================================
Change Log:

1.3.0 (09-August-2024)
    - Added cvar to control when to start the countdown message.
    - Renamed and changed the default value of some cvars.

1.2.0 (29-April-2021)
    - Added Hungarian (hu) translation. (thanks to "KasperH")

1.1.0 (30-September-2020)
    - Added Hungarian (hu) translation. (thanks to "KasperH")

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
#define PLUGIN_VERSION                "1.3.0"
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
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d2_sdas_version;
    ConVar l4d2_sdas_enable;
    ConVar l4d2_sdas_bots;
    ConVar l4d2_sdas_flags;
    ConVar l4d2_sdas_alive_time;
    ConVar l4d2_sdas_spit_countdown_sound;
    ConVar l4d2_sdas_spit_msg;
    ConVar l4d2_sdas_spit_countdown_start;
    ConVar l4d2_sdas_spit_countdown_msg;
    ConVar l4d2_sdas_dead_by_spit_msg;

    void Init()
    {
        this.l4d2_sdas_version = CreateConVar("l4d2_sdas_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d2_sdas_enable = CreateConVar("l4d2_sdas_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_sdas_bots = CreateConVar("l4d2_sdas_bots", "1", "Enables/Disables the plugin behaviour on Spitter bots.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_sdas_flags = CreateConVar("l4d2_sdas_flags", "", "Players with these flags are immune to the plugin behaviour.\nEmpty = none.\nKnown values at \"\\addons\\sourcemod\\configs\\admin_levels.cfg\".\nExample: \"az\", will apply immunity to players with \"a\" (reservation) or \"z\" (root) flag.", CVAR_FLAGS);
        this.l4d2_sdas_alive_time = CreateConVar("l4d2_sdas_alive_time", "10", "How long (in seconds) will Spitter have after spitting before being killed by the plugin.", CVAR_FLAGS, true, 1.0);
        this.l4d2_sdas_spit_msg = CreateConVar("l4d2_sdas_spit_msg", "3", "Display type for the \"Spit\" message.\n0 = OFF, 1 = CHAT, 2 = HINT, 4 = INSTRUCTOR HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 7.0);
        this.l4d2_sdas_spit_countdown_msg = CreateConVar("l4d2_sdas_spit_countdown_msg", "2", "Display type for the \"Spit Countdown\" message.\n0 = OFF, 1 = CHAT, 2 = HINT, 4 = INSTRUCTOR HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 7.0);
        this.l4d2_sdas_spit_countdown_start = CreateConVar("l4d2_sdas_spit_countdown_start", "3", "Start displaying the countdown message when the time left reaches this value.", CVAR_FLAGS, true, 1.0);
        this.l4d2_sdas_spit_countdown_sound = CreateConVar("l4d2_sdas_spit_countdown_sound", "", "Spitter countdown sound after spit.\nEmpty = OFF.\nRecommended: buttons/blip1.wav", CVAR_FLAGS);
        this.l4d2_sdas_dead_by_spit_msg = CreateConVar("l4d2_sdas_dead_by_spit_msg", "3", "Display type for the \"Dead By Spit\" message.\n0 = OFF, 1 = CHAT, 2 = HINT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", displays the message in CHAT and as a HINT.", CVAR_FLAGS, true, 0.0, true, 3.0);

        this.l4d2_sdas_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_bots.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_flags.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_alive_time.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_spit_msg.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_spit_countdown_msg.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_spit_countdown_start.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_spit_countdown_sound.AddChangeHook(Event_ConVarChanged);
        this.l4d2_sdas_dead_by_spit_msg.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    Handle timerCountdown[MAXPLAYERS+1];
    int spitCountdown[MAXPLAYERS+1];

    bool eventsHooked;

    bool enable;
    bool bots;
    char sFlags[27];
    int iFlags;
    bool flags;
    int aliveTime;
    int spitMsg;
    int spitCountdownMsg;
    int spitCountdownStart;
    char sSpitCountdownSound[PLATFORM_MAX_PATH];
    bool spitCountdownSound;
    int deadBySpitMsg;

    void Init()
    {
        this.LoadPluginTranslations();
        this.cvars.Init();
        this.RegisterCmds();
    }

    void LoadPluginTranslations()
    {
        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
        if (FileExists(path))
            LoadTranslations(TRANSLATION_FILENAME);
        else
            SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d2_sdas_enable.BoolValue;
        this.bots = this.cvars.l4d2_sdas_bots.BoolValue;
        this.cvars.l4d2_sdas_flags.GetString(this.sFlags, sizeof(this.sFlags));
        TrimString(this.sFlags);
        this.iFlags = ReadFlagString(this.sFlags);
        this.flags = this.iFlags > 0;
        this.aliveTime = this.cvars.l4d2_sdas_alive_time.IntValue;
        this.cvars.l4d2_sdas_spit_countdown_sound.GetString(this.sSpitCountdownSound, sizeof(this.sSpitCountdownSound));
        TrimString(this.sSpitCountdownSound);
        this.spitCountdownSound = (this.sSpitCountdownSound[0] != 0);
        if (this.spitCountdownSound)
            PrecacheSound(this.sSpitCountdownSound, true);
        this.spitMsg = this.cvars.l4d2_sdas_spit_msg.IntValue;
        this.spitCountdownStart = this.cvars.l4d2_sdas_spit_countdown_start.IntValue;
        this.spitCountdownMsg = this.cvars.l4d2_sdas_spit_countdown_msg.IntValue;
        this.deadBySpitMsg = this.cvars.l4d2_sdas_dead_by_spit_msg.IntValue;

        if (!this.enable)
        {
            for (int client = 1; client <= MaxClients; client++)
            {
                this.ResetClient(client);
            }
        }
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d2_sdas", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void HookEvents()
    {
        if (this.enable && !this.eventsHooked)
        {
            this.eventsHooked = true;

            HookEvent("ability_use", Event_AbilityUse);
            HookEvent("player_spawn", Event_PlayerSpawn);
            HookEvent("player_death", Event_PlayerDeath);

            return;
        }

        if (!this.enable && this.eventsHooked)
        {
            this.eventsHooked = false;

            UnhookEvent("ability_use", Event_AbilityUse);
            UnhookEvent("player_spawn", Event_PlayerSpawn);
            UnhookEvent("player_death", Event_PlayerDeath);

            return;
        }
    }

    void ResetClient(int client)
    {
        delete plugin.timerCountdown[client];
        plugin.spitCountdown[client] = 0;
    }
}

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
    plugin.Init();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
    plugin.HookEvents();
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    plugin.ResetClient(client);
}

/****************************************************************************************************/

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    plugin.ResetClient(client);

    char ability[16];
    event.GetString("ability", ability, sizeof(ability));

    if (!StrEqual(ability, "ability_spit"))
        return;

    if (!IsValidSpitter(client))
        return;

    plugin.timerCountdown[client] = CreateTimer(1.0, Timer_KillSpitter, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    plugin.spitCountdown[client] = plugin.aliveTime;

    if (IsFakeClient(client))
        return;

    if (plugin.spitMsg & FLAG_MSG_DISPLAY_CHAT)
        CPrintToChat(client, "%t", "Spit", plugin.spitCountdown[client]);

    if (plugin.spitMsg & FLAG_MSG_DISPLAY_HINT)
        CPrintHintText(client, "%t", "Spit", plugin.spitCountdown[client]);

    if (plugin.spitMsg & FLAG_MSG_DISPLAY_INSTRUCTOR)
        PrintInstructorHintText(client, "%t", "Spit", plugin.spitCountdown[client]);
}

/****************************************************************************************************/

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    plugin.ResetClient(client);
}

/****************************************************************************************************/

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client == 0)
        return;

    plugin.ResetClient(client);
}

/****************************************************************************************************/

Action Timer_KillSpitter(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (client == 0)
        return Plugin_Stop;

    plugin.spitCountdown[client]--;

    if (plugin.spitCountdown[client] > 0)
    {
        if (!IsFakeClient(client) && plugin.spitCountdownStart >= plugin.spitCountdown[client])
        {
            if (plugin.spitCountdownSound)
                EmitSoundToClient(client, plugin.sSpitCountdownSound);

            if (plugin.spitCountdownMsg & FLAG_MSG_DISPLAY_CHAT)
                CPrintToChat(client, "%t", "Spit Countdown", plugin.spitCountdown[client]);

            if (plugin.spitCountdownMsg & FLAG_MSG_DISPLAY_HINT)
                CPrintHintText(client, "%t", "Spit Countdown", plugin.spitCountdown[client]);

            if (plugin.spitCountdownMsg & FLAG_MSG_DISPLAY_INSTRUCTOR)
                PrintInstructorHintText(client, "%t", "Spit Countdown", plugin.spitCountdown[client]);
        }
    }
    else
    {
        plugin.timerCountdown[client] = null; // prevent delete timer errors due to ForcePlayerSuicide + player_death event
        ForcePlayerSuicide(client);

        if (!IsFakeClient(client))
        {
            if (plugin.deadBySpitMsg & FLAG_MSG_DISPLAY_CHAT)
                CPrintToChat(client, "%t", "Dead By Spit");

            if (plugin.deadBySpitMsg & FLAG_MSG_DISPLAY_HINT)
                CPrintHintText(client, "%t", "Dead By Spit");
        }

        return Plugin_Stop;
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

    float fCountdownHeat = float(plugin.spitCountdown[client]) / plugin.aliveTime;
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

    if (IsFakeClient(client) && !plugin.bots)
        return false;

    if (plugin.flags && (GetUserFlagBits(client) & plugin.iFlags))
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
    PrintToConsole(client, "l4d2_sdas_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_bots : %b (%s)", plugin.bots, plugin.bots ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_flags : %s (%i)", plugin.sFlags, plugin.iFlags);
    PrintToConsole(client, "l4d2_sdas_alive_time : %i (seconds)", plugin.aliveTime);
    PrintToConsole(client, "l4d2_sdas_spit_countdown_sound : \"%s\" (%s)", plugin.sSpitCountdownSound, plugin.spitCountdownSound ? "true" : "false");
    PrintToConsole(client, "l4d2_sdas_spit_msg : %i (CHAT: %s | HINT: %s | INSTRUCTOR: %s)", plugin.spitMsg, plugin.spitMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", plugin.spitMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF", plugin.spitMsg & FLAG_MSG_DISPLAY_INSTRUCTOR ? "ON" : "OFF");
    PrintToConsole(client, "l4d2_sdas_spit_countdown_msg : %i (CHAT: %s | HINT: %s | INSTRUCTOR: %s)", plugin.spitCountdownMsg, plugin.spitCountdownMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", plugin.spitCountdownMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF", plugin.spitCountdownMsg & FLAG_MSG_DISPLAY_INSTRUCTOR ? "ON" : "OFF");
    PrintToConsole(client, "l4d2_sdas_spit_countdown_start : %i", plugin.spitCountdownStart);
    PrintToConsole(client, "l4d2_sdas_dead_by_spit_msg : %i (CHAT: %s | HINT: %s)", plugin.deadBySpitMsg, plugin.deadBySpitMsg & FLAG_MSG_DISPLAY_CHAT ? "ON" : "OFF", plugin.deadBySpitMsg & FLAG_MSG_DISPLAY_HINT ? "ON" : "OFF");
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