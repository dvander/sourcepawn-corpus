/**
// ====================================================================================================
Change Log:

1.0.9 (23-January-2021)
    - Fixed a rare error right after using PostSpawnActivate (thanks "Froxcan" for reporting)

1.0.8 (22-January-2021)
    - Fixed invalid weapon index on SDKHook_WeaponSwitchPost (thanks "jeremyvillanueva" for reporting)

1.0.7 (04-January-2021)
    - Added Simplified Chinese (chi) and Traditional Chinese (zho) translations. (thanks to "HarryPotter")

1.0.6 (25-October-2020)
    - Fixed a bug while detecting the minimum penalty OnMapStart and on mp_gamemode cvar change.
    - Added cvar option to throw both gnome and cola with RELOAD / ZOOM button.

1.0.5 (18-October-2020)
    - Fixed OnPlayerRunCmd being executed when player is dead (player_death not fires SDKHook_WeaponSwitchPost).

1.0.4 (16-October-2020)
    - Performance tweaks on OnPlayerRunCmd.

1.0.3 (15-October-2020)
    - Added a chat message when pickup the gnome/cola. (thanks "Alex Alcalá" for requesting)
    - Added translation with color support.

1.0.2 (09-October-2020)
    - Better no shove penalty handling to prevent exploits.
    - Added game mode check to detect the minimum penalty. (coop and non-coop have different default values)

1.0.1 (06-October-2020)
    - Changed "...shove_dmg_ff" cvars to "...shove_dmg_ffdamage".
    - Now it does specific friendly fire damage.

1.0.0 (01-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Gnome and Cola Shove Damage"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allows both gnome and cola to do some damage when shoving"
#define PLUGIN_VERSION                "1.0.9"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327647"

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
#define CONFIG_FILENAME               "l4d2_gnome_n_cola_shove_dmg"
#define TRANSLATION_FILENAME          "l4d2_gnome_n_cola_shove_dmg.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_GNOME                   "models/weapons/melee/v_gnome.mdl"
#define MODEL_COLA                    "models/v_models/v_cola.mdl"

#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

#define ENTITY_WORLDSPAWN             0

#define TYPE_NONE                     0
#define TYPE_GNOME                    1
#define TYPE_COLA                     2

#define ALT_BUTTON_RELOAD             1
#define ALT_BUTTON_ZOOM               2

// ====================================================================================================
// Native Cvars
// ====================================================================================================
static ConVar g_hCvar_MPGameMode;
static ConVar g_hCvar_ShoveMinPenaltyCoop;
static ConVar g_hCvar_ShoveMinPenaltyNonCoop;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_SpamProtection;
static ConVar g_hCvar_GnomeAllow;
static ConVar g_hCvar_GnomeDamage;
static ConVar g_hCvar_GnomeDamageType;
static ConVar g_hCvar_GnomeShoveOnAttack;
static ConVar g_hCvar_GnomeAltThrowButton;
static ConVar g_hCvar_GnomeNoShovePenalty;
static ConVar g_hCvar_GnomeFriendlyFireDamage;
static ConVar g_hCvar_GnomeAnnounceTeam;
static ConVar g_hCvar_GnomeAnnounceSelf;
static ConVar g_hCvar_ColaAllow;
static ConVar g_hCvar_ColaDamage;
static ConVar g_hCvar_ColaDamageType;
static ConVar g_hCvar_ColaShoveOnAttack;
static ConVar g_hCvar_ColaAltThrowButton;
static ConVar g_hCvar_ColaNoShovePenalty;
static ConVar g_hCvar_ColaFriendlyFireDamage;
static ConVar g_hCvar_ColaAnnounceTeam;
static ConVar g_hCvar_ColaAnnounceSelf;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_SpamProtection;
static bool   g_bCvar_GnomeAllow;
static bool   g_bCvar_GnomeShoveOnAttack;
static bool   g_bCvar_GnomeNoShovePenalty;
static bool   g_bCvar_GnomeFriendlyFireDamage;
static bool   g_bCvar_GnomeAnnounceTeam;
static bool   g_bCvar_GnomeAnnounceSelf;
static bool   g_bCvar_ColaAllow;
static bool   g_bCvar_ColaShoveOnAttack;
static bool   g_bCvar_ColaNoShovePenalty;
static bool   g_bCvar_ColaFriendlyFireDamage;
static bool   g_bCvar_ColaAnnounceTeam;
static bool   g_bCvar_ColaAnnounceSelf;
static bool   g_bShoveMinPenaltyCoop;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iModel_Gnome = -1;
static int    g_iModel_Cola = -1;
static int    g_iCvar_ShoveMinPenaltyCoop;
static int    g_iCvar_ShoveMinPenaltyNonCoop;
static int    g_iCvar_GnomeDamage;
static int    g_iCvar_GnomeFriendlyFireDamage;
static int    g_iCvar_GnomeDamageType;
static int    g_iCvar_GnomeAltThrowButton;
static int    g_iCvar_GnomeAnnounceTeam;
static int    g_iCvar_ColaDamage;
static int    g_iCvar_ColaFriendlyFireDamage;
static int    g_iCvar_ColaDamageType;
static int    g_iCvar_ColaAltThrowButton;
static int    g_iCvar_ColaAnnounceTeam;
static int    g_iShoveMinPenalty;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_SpamProtection;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_MPGameMode[16];

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static int    gc_iWeaponType[MAXPLAYERS+1];
static float  gc_fLastChatOccurrence[MAXPLAYERS+1];

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

    g_hCvar_MPGameMode = FindConVar("mp_gamemode");
    g_hCvar_ShoveMinPenaltyCoop = FindConVar("z_gun_swing_coop_min_penalty");
    g_hCvar_ShoveMinPenaltyNonCoop = FindConVar("z_gun_swing_vs_min_penalty");

    CreateConVar("l4d2_gnome_n_cola_shove_dmg_ver", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled                 = CreateConVar("l4d2_gnome_n_cola_shove_dmg_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_SpamProtection          = CreateConVar("l4d2_gnome_n_cola_shove_dmg_spam_protection", "3.0", "Delay in seconds to output to the chat the message from the same client again.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GnomeAllow              = CreateConVar("l4d2_gnome_shove_dmg_allow", "1", "Allow the gnome to do shove damage.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GnomeDamage             = CreateConVar("l4d2_gnome_shove_dmg_damage", "50", "How much damage the gnome does.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GnomeDamageType         = CreateConVar("l4d2_gnome_shove_dmg_damage_type", "128", "Which kind of damage type the gnome does.\nKnown values can be found here: https://developer.valvesoftware.com/wiki/Damage_types#Damage_type_table\nAdd numbers greater than 0 for multiple options.\nExample: \"136\", enables DMG_CLUB (128) and DMG_BURN (8).", CVAR_FLAGS, true, 0.0);
    g_hCvar_GnomeShoveOnAttack      = CreateConVar("l4d2_gnome_shove_dmg_shove_on_attack", "1", "Force the client to shove the gnome when pressing the attack button.\nNote: This prevents the gnome from being thrown.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GnomeAltThrowButton     = CreateConVar("l4d2_gnome_shove_dmg_alt_throw_button", "3", "Alternate button for throwing the gnome.\n0 = OFF, 1 = RELOAD (R), 2 = ZOOM (M3), 3 = RELOAD (R) or ZOOM (M3).", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_GnomeNoShovePenalty     = CreateConVar("l4d2_gnome_shove_dmg_no_shove_penalty", "1", "Remove the shove penalty while holding the gnome.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GnomeFriendlyFireDamage = CreateConVar("l4d2_gnome_shove_dmg_ff_damage", "0", "How much friendly fire the gnome does.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GnomeAnnounceTeam       = CreateConVar("l4d2_gnome_shove_dmg_announce_team", "1", "Which teams should the message be transmitted to on gnome equip.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_GnomeAnnounceSelf       = CreateConVar("l4d2_gnome_shove_dmg_announce_self", "1", "Should the message be transmitted to those who picked up the gnome.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ColaAllow               = CreateConVar("l4d2_cola_shove_dmg_allow", "1", "Allow the cola to do shove damage.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ColaDamage              = CreateConVar("l4d2_cola_shove_dmg_damage", "50", "How much damage the cola does.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ColaDamageType          = CreateConVar("l4d2_cola_shove_dmg_damage_type", "128", "Which kind of damage type the cola does.\nKnown values can be found here: https://developer.valvesoftware.com/wiki/Damage_types#Damage_type_table\nAdd numbers greater than 0 for multiple options.\nExample: \"136\", enables DMG_CLUB and DMG_BURN.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ColaShoveOnAttack       = CreateConVar("l4d2_cola_shove_dmg_shove_on_attack", "1", "Force the client to shove the cola when pressing the attack button.\nNote: This prevents the cola from being thrown.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ColaAltThrowButton      = CreateConVar("l4d2_cola_shove_dmg_alt_throw_button", "3", "Alternate button for throwing the cola.\n0 = OFF, 1 = RELOAD (R), 2 = ZOOM (M3), 3 = RELOAD (R) or ZOOM (M3).", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_ColaNoShovePenalty      = CreateConVar("l4d2_cola_shove_dmg_no_shove_penalty", "1", "Remove the shove penalty while holding the cola.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ColaFriendlyFireDamage  = CreateConVar("l4d2_cola_shove_dmg_ff_damage", "0", "How much friendly fire the cola does.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    g_hCvar_ColaAnnounceTeam        = CreateConVar("l4d2_cola_shove_dmg_announce_team", "1", "Which teams should the message be transmitted to on cola equip.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_ColaAnnounceSelf        = CreateConVar("l4d2_cola_shove_dmg_announce_self", "1", "Should the message be transmitted to those who picked up the cola.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_MPGameMode.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShoveMinPenaltyCoop.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShoveMinPenaltyNonCoop.AddChangeHook(Event_ConVarChanged);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SpamProtection.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeAllow.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeDamageType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeShoveOnAttack.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeAltThrowButton.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeNoShovePenalty.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeAnnounceTeam.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeAnnounceSelf.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GnomeFriendlyFireDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaAllow.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaDamageType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaShoveOnAttack.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaAltThrowButton.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaNoShovePenalty.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaFriendlyFireDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaAnnounceTeam.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ColaAnnounceSelf.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_gnome_n_cola_shove_dmg", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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

public void OnMapStart()
{
    g_iModel_Gnome = PrecacheModel(MODEL_GNOME, true);
    g_iModel_Cola = PrecacheModel(MODEL_COLA, true);

    GetShoveMinPenalty();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

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
    g_hCvar_MPGameMode.GetString(g_sCvar_MPGameMode, sizeof(g_sCvar_MPGameMode));
    g_iCvar_ShoveMinPenaltyCoop = g_hCvar_ShoveMinPenaltyCoop.IntValue;
    g_iCvar_ShoveMinPenaltyNonCoop = g_hCvar_ShoveMinPenaltyNonCoop.IntValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_SpamProtection = g_hCvar_SpamProtection.FloatValue;
    g_bCvar_SpamProtection = (g_fCvar_SpamProtection > 0.0);
    g_bCvar_GnomeAllow = g_hCvar_GnomeAllow.BoolValue;
    g_iCvar_GnomeDamage = g_hCvar_GnomeDamage.IntValue;
    g_iCvar_GnomeFriendlyFireDamage = g_hCvar_GnomeFriendlyFireDamage.IntValue;
    g_bCvar_GnomeFriendlyFireDamage = (g_iCvar_GnomeFriendlyFireDamage > 0);
    g_iCvar_GnomeDamageType = g_hCvar_GnomeDamageType.IntValue;
    g_bCvar_GnomeShoveOnAttack = g_hCvar_GnomeShoveOnAttack.BoolValue;
    g_iCvar_GnomeAltThrowButton = g_hCvar_GnomeAltThrowButton.IntValue;
    g_bCvar_GnomeNoShovePenalty = g_hCvar_GnomeNoShovePenalty.BoolValue;
    g_iCvar_GnomeAnnounceTeam = g_hCvar_GnomeAnnounceTeam.IntValue;
    g_bCvar_GnomeAnnounceTeam = (g_iCvar_GnomeAnnounceTeam > 0);
    g_bCvar_GnomeAnnounceSelf = g_hCvar_GnomeAnnounceSelf.BoolValue;
    g_bCvar_ColaAllow = g_hCvar_ColaAllow.BoolValue;
    g_iCvar_ColaDamage = g_hCvar_ColaDamage.IntValue;
    g_iCvar_ColaFriendlyFireDamage = g_hCvar_ColaFriendlyFireDamage.IntValue;
    g_bCvar_ColaFriendlyFireDamage = (g_iCvar_ColaFriendlyFireDamage > 0);
    g_iCvar_ColaDamageType = g_hCvar_ColaDamageType.IntValue;
    g_bCvar_ColaShoveOnAttack = g_hCvar_ColaShoveOnAttack.BoolValue;
    g_iCvar_ColaAltThrowButton = g_hCvar_ColaAltThrowButton.IntValue;
    g_bCvar_ColaNoShovePenalty = g_hCvar_ColaNoShovePenalty.BoolValue;
    g_iCvar_ColaAnnounceTeam = g_hCvar_ColaAnnounceTeam.IntValue;
    g_bCvar_ColaAnnounceTeam = (g_iCvar_ColaAnnounceTeam > 0);
    g_bCvar_ColaAnnounceSelf = g_hCvar_ColaAnnounceSelf.BoolValue;

    GetShoveMinPenalty();
}

/****************************************************************************************************/

public void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);

        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        OnWeaponSwitchPost(client, weapon);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bConfigLoaded)
        return;

    if (IsFakeClient(client))
        return;

    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_iWeaponType[client] = TYPE_NONE;
    gc_fLastChatOccurrence[client] = 0.0;
}

/****************************************************************************************************/

public void OnWeaponSwitchPost(int client, int weapon)
{
    gc_iWeaponType[client] = TYPE_NONE;

    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntity(weapon))
        return;

    int team = GetClientTeam(client);

    if (team != TEAM_SURVIVOR && team != TEAM_HOLDOUT)
        return;

    int modelIndex = GetEntProp(weapon, Prop_Send, "m_nModelIndex");

    if (modelIndex == g_iModel_Gnome)
    {
        if (!g_bCvar_GnomeAllow)
            return;

        gc_iWeaponType[client] = TYPE_GNOME;

        if (!g_bCvar_GnomeAnnounceTeam)
            return;

        if (g_bCvar_SpamProtection)
        {
            if (GetGameTime() - gc_fLastChatOccurrence[client] < g_fCvar_SpamProtection)
                return;

            gc_fLastChatOccurrence[client] = GetGameTime();
        }

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i))
                continue;

            if (IsFakeClient(i))
                continue;

            if (client == i)
            {
                if (!g_bCvar_GnomeAnnounceSelf)
                    continue;
            }
            else
            {
                if (!(GetTeamFlag(GetClientTeam(i)) & g_iCvar_GnomeAnnounceTeam))
                    continue;
            }

            CPrintToChat(i, "%t", "Equipped a gnome", client);
        }

        return;
    }

    if (modelIndex == g_iModel_Cola)
    {
        if (!g_bCvar_ColaAllow)
            return;

        gc_iWeaponType[client] = TYPE_COLA;

        if (!g_bCvar_ColaAnnounceTeam)
            return;

        if (g_bCvar_SpamProtection)
        {
            if (GetGameTime() - gc_fLastChatOccurrence[client] < g_fCvar_SpamProtection)
                return;

            gc_fLastChatOccurrence[client] = GetGameTime();
        }

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i))
                continue;

            if (IsFakeClient(i))
                continue;

            if (client == i)
            {
                if (!g_bCvar_ColaAnnounceSelf)
                    continue;
            }
            else
            {
                if (!(GetTeamFlag(GetClientTeam(i)) & g_iCvar_ColaAnnounceTeam))
                    continue;
            }

            CPrintToChat(i, "%t", "Equipped a cola", client);
        }

        return;
    }
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("entity_shoved", Event_EntityShoved);
        HookEvent("player_shoved", Event_PlayerShoved);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("player_team", Event_PlayerTeam);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("entity_shoved", Event_EntityShoved);
        UnhookEvent("player_shoved", Event_PlayerShoved);
        UnhookEvent("player_death", Event_PlayerDeath);
        UnhookEvent("player_team", Event_PlayerTeam);

        return;
    }
}

/****************************************************************************************************/

public void Event_EntityShoved(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClient(client))
        return;

    if (gc_iWeaponType[client] == TYPE_NONE)
        return;

    int target = event.GetInt("entityid");

    if (target == ENTITY_WORLDSPAWN)
        return;

    if (!IsValidEntity(target))
        return;

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    switch (gc_iWeaponType[client])
    {
        case TYPE_GNOME:
        {
            SDKHooks_TakeDamage(target, client, client, float(g_iCvar_GnomeDamage), g_iCvar_GnomeDamageType, activeWeapon);
        }
        case TYPE_COLA:
        {
            SDKHooks_TakeDamage(target, client, client, float(g_iCvar_ColaDamage), g_iCvar_ColaDamageType, activeWeapon);
        }
    }
}

/****************************************************************************************************/

public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClient(client))
        return;

    if (gc_iWeaponType[client] == TYPE_NONE)
        return;

    int target = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(target))
        return;

    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

    switch (gc_iWeaponType[client])
    {
        case TYPE_GNOME:
        {
            if (GetClientTeam(client) == GetClientTeam(target))
            {
                if (!g_bCvar_GnomeFriendlyFireDamage)
                    return;

                SDKHooks_TakeDamage(target, client, client, float(g_iCvar_GnomeFriendlyFireDamage), g_iCvar_GnomeDamageType, activeWeapon);
                return;
            }

            SDKHooks_TakeDamage(target, client, client, float(g_iCvar_GnomeDamage), g_iCvar_GnomeDamageType, activeWeapon);
        }
        case TYPE_COLA:
        {
            if (GetClientTeam(client) == GetClientTeam(target))
            {
                if (!g_bCvar_ColaFriendlyFireDamage)
                    return;

                SDKHooks_TakeDamage(target, client, client, float(g_iCvar_ColaFriendlyFireDamage), g_iCvar_ColaDamageType, activeWeapon);
                return;
            }

            SDKHooks_TakeDamage(target, client, client, float(g_iCvar_ColaDamage), g_iCvar_ColaDamageType, activeWeapon);
        }
    }
}

/****************************************************************************************************/

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClientIndex(client))
        return;

    gc_iWeaponType[client] = TYPE_NONE;
}

/****************************************************************************************************/

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClientIndex(client))
        return;

    gc_iWeaponType[client] = TYPE_NONE;
}

/****************************************************************************************************/

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!IsValidClientIndex(client))
        return Plugin_Continue;

    if (gc_iWeaponType[client] == TYPE_NONE)
        return Plugin_Continue;

    if (buttons & IN_RELOAD)
    {
        switch (gc_iWeaponType[client])
        {
            case TYPE_GNOME:
            {
                if (g_iCvar_GnomeAltThrowButton & ALT_BUTTON_RELOAD)
                {
                    buttons |= IN_ATTACK;

                    return Plugin_Changed;
                }
            }
            case TYPE_COLA:
            {
                if (g_iCvar_ColaAltThrowButton & ALT_BUTTON_RELOAD)
                {
                    buttons |= IN_ATTACK;

                    return Plugin_Changed;
                }
            }
        }
    }

    if (buttons & IN_ZOOM)
    {
        switch (gc_iWeaponType[client])
        {
            case TYPE_GNOME:
            {
                if (g_iCvar_GnomeAltThrowButton & ALT_BUTTON_ZOOM)
                {
                    buttons |= IN_ATTACK;

                    return Plugin_Changed;
                }
            }
            case TYPE_COLA:
            {
                if (g_iCvar_ColaAltThrowButton & ALT_BUTTON_ZOOM)
                {
                    buttons |= IN_ATTACK;

                    return Plugin_Changed;
                }
            }
        }
    }

    if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
    {
        switch (gc_iWeaponType[client])
        {
            case TYPE_GNOME:
            {
                if (g_bCvar_GnomeNoShovePenalty)
                {
                    int shovePenalty = GetEntProp(client, Prop_Send, "m_iShovePenalty");

                    if (shovePenalty > g_iShoveMinPenalty)
                        SetEntProp(client, Prop_Send, "m_iShovePenalty", g_iShoveMinPenalty);
                }

                if (buttons & IN_ATTACK)
                {
                    if (g_bCvar_GnomeShoveOnAttack)
                    {
                        buttons &= ~IN_ATTACK;
                        buttons |= IN_ATTACK2;

                        return Plugin_Changed;
                    }
                }
            }
            case TYPE_COLA:
            {
                if (g_bCvar_ColaNoShovePenalty)
                {
                    int shovePenalty = GetEntProp(client, Prop_Send, "m_iShovePenalty");

                    if (shovePenalty > g_iShoveMinPenalty)
                        SetEntProp(client, Prop_Send, "m_iShovePenalty", g_iShoveMinPenalty);
                }

                if (buttons & IN_ATTACK)
                {
                    if (g_bCvar_ColaShoveOnAttack)
                    {
                        buttons &= ~IN_ATTACK;
                        buttons |= IN_ATTACK2;

                        return Plugin_Changed;
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

/****************************************************************************************************/

public void GetShoveMinPenalty()
{
    g_bShoveMinPenaltyCoop = false;
    g_iShoveMinPenalty = g_iCvar_ShoveMinPenaltyNonCoop - 1;
    if (g_iShoveMinPenalty < 0)
        g_iShoveMinPenalty = 0;

    int entity = CreateEntityByName("info_gamemode");
    DispatchKeyValue(entity, "targetname", "l4d2_gnome_n_cola_shove_dmg");

    DispatchSpawn(entity);
    ActivateEntity(entity);

    HookSingleEntityOutput(entity, "OnCoop", OnCoop, true);
    ActivateEntity(entity);
    AcceptEntityInput(entity, "PostSpawnActivate");
    if (IsValidEntity(entity)) // Because sometimes "PostSpawnActivate" seems to kill the ent.
        RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
}

/****************************************************************************************************/

public void OnCoop(const char[] output, int caller, int activator, float delay)
{
    g_bShoveMinPenaltyCoop = true;
    g_iShoveMinPenalty = (g_iCvar_ShoveMinPenaltyCoop - 1);
    if (g_iShoveMinPenalty < 0)
        g_iShoveMinPenalty = 0;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------- Plugin Cvars (l4d2_gnome_n_cola_shove_dmg) -------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_gnome_n_cola_shove_dmg_ver : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_gnome_n_cola_shove_dmg_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_n_cola_shove_dmg_spam_protection : %.2f (%s)", g_fCvar_SpamProtection, g_bCvar_SpamProtection ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_shove_dmg_allow : %b (%s)", g_bCvar_GnomeAllow, g_bCvar_GnomeAllow ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_shove_dmg_damage : %i", g_iCvar_GnomeDamage);
    PrintToConsole(client, "l4d2_gnome_shove_dmg_ff_damage : %i (%s)", g_iCvar_GnomeFriendlyFireDamage, g_bCvar_GnomeFriendlyFireDamage ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_shove_dmg_damage_type : %i", g_iCvar_GnomeDamageType);
    PrintToConsole(client, "l4d2_gnome_shove_dmg_shove_on_attack : %b (%s)", g_bCvar_GnomeShoveOnAttack, g_bCvar_GnomeShoveOnAttack ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_shove_dmg_alt_throw_button : %i", g_iCvar_GnomeAltThrowButton);
    PrintToConsole(client, "l4d2_gnome_shove_dmg_no_shove_penalty : %b (%s)", g_bCvar_GnomeNoShovePenalty, g_bCvar_GnomeNoShovePenalty ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_shove_dmg_announce_team : %i (%s)", g_iCvar_GnomeAnnounceTeam, g_bCvar_GnomeAnnounceTeam ? "true" : "false");
    PrintToConsole(client, "l4d2_gnome_shove_dmg_announce_self : %i (%s)", g_bCvar_GnomeAnnounceSelf, g_bCvar_GnomeAnnounceSelf ? "true" : "false");
    PrintToConsole(client, "l4d2_cola_shove_dmg_allow : %b (%s)", g_bCvar_ColaAllow, g_bCvar_ColaAllow ? "true" : "false");
    PrintToConsole(client, "l4d2_cola_shove_dmg_damage : %i", g_iCvar_ColaDamage);
    PrintToConsole(client, "l4d2_cola_shove_dmg_ff_damage : %i (%s)", g_iCvar_ColaFriendlyFireDamage, g_bCvar_ColaFriendlyFireDamage ? "true" : "false");
    PrintToConsole(client, "l4d2_cola_shove_dmg_damage_type : %i", g_iCvar_ColaDamageType);
    PrintToConsole(client, "l4d2_cola_shove_dmg_shove_on_attack : %b (%s)", g_bCvar_ColaShoveOnAttack, g_bCvar_ColaShoveOnAttack ? "true" : "false");
    PrintToConsole(client, "l4d2_cola_shove_dmg_alt_throw_button : %i", g_iCvar_ColaAltThrowButton);
    PrintToConsole(client, "l4d2_cola_shove_dmg_no_shove_penalty : %b (%s)", g_bCvar_ColaNoShovePenalty, g_bCvar_ColaNoShovePenalty ? "true" : "false");
    PrintToConsole(client, "l4d2_cola_shove_dmg_announce_team : %i (%s)", g_iCvar_ColaAnnounceTeam, g_bCvar_ColaAnnounceTeam ? "true" : "false");
    PrintToConsole(client, "l4d2_cola_shove_dmg_announce_self : %i (%s)", g_bCvar_ColaAnnounceSelf, g_bCvar_ColaAnnounceSelf ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "mp_gamemode : %s", g_sCvar_MPGameMode);
    PrintToConsole(client, "z_gun_swing_coop_min_penalty : %i (%s)", g_iCvar_ShoveMinPenaltyCoop, g_bShoveMinPenaltyCoop ? "true" : "false");
    PrintToConsole(client, "z_gun_swing_vs_min_penalty : %i (%s)", g_iCvar_ShoveMinPenaltyNonCoop, !g_bShoveMinPenaltyCoop ? "true" : "false");
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
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
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