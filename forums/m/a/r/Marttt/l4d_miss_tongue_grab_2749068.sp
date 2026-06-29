/**
// ====================================================================================================
Change Log:

1.0.0 (06-June-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Miss Shot/Shove On Tongue Grab"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Survivors can miss shots/shove while grabbed by a tongue"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=332885"

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
#define CONFIG_FILENAME               "l4d_miss_tongue_grab"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_ShotMissChance;
ConVar g_hCvar_ShoveMissChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_ShotMissChance;
int g_iCvar_ShoveMissChance;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bTakeDamageHooked[MAXPLAYERS+1];
bool gc_bInTongue[MAXPLAYERS+1];

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
    CreateConVar("l4d_miss_tongue_grab_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled         = CreateConVar("l4d_miss_tongue_grab_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ShotMissChance  = CreateConVar("l4d_miss_tongue_grab_shot_miss_chance", "100", "Chance (%) to miss hits when the survivor is grabbed by tongue.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);
    g_hCvar_ShoveMissChance = CreateConVar("l4d_miss_tongue_grab_shove_miss_chance", "100", "Chance (%) to miss the shove when the survivor is grabbed by tongue.\n0 = OFF.", CVAR_FLAGS, true, 0.0, true, 100.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShotMissChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ShoveMissChance.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_miss_tongue_grab", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_ShotMissChance = g_hCvar_ShotMissChance.IntValue;
    g_iCvar_ShoveMissChance = g_hCvar_ShoveMissChance.IntValue;
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (gc_bTakeDamageHooked[client])
        return;

    gc_bTakeDamageHooked[client] = true;
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bTakeDamageHooked[client] = false;
    gc_bInTongue[client] = false;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (StrEqual(classname, "infected"))
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }

    if (StrEqual(classname, "witch"))
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        return;
    }
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("tongue_grab", Event_TongueGrab);
        HookEvent("tongue_release", Event_TongueRelease);
        HookEvent("player_bot_replace", Event_PlayerBotReplace);
        HookEvent("bot_player_replace", Event_BotPlayerReplace);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("tongue_grab", Event_TongueGrab);
        UnhookEvent("tongue_release", Event_TongueRelease);
        UnhookEvent("player_bot_replace", Event_PlayerBotReplace);
        UnhookEvent("bot_player_replace", Event_BotPlayerReplace);

        return;
    }
}

/****************************************************************************************************/

void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));
	PrintToChatAll("Event_TongueGrab %i (%i)", client, event.GetInt("victim"));

    if (client == 0)
        return;

    gc_bInTongue[client] = true;
}

/****************************************************************************************************/

void Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("victim"));
	PrintToChatAll("Event_TongueRelease %i (%i)", client, event.GetInt("victim"));

    if (client == 0)
        return;

    gc_bInTongue[client] = false;
}

/****************************************************************************************************/

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    if (player == 0 || bot == 0)
        return;

	PrintToChatAll("Event_PlayerBotReplace %i -> %i", player, bot);

    gc_bInTongue[bot] = gc_bInTongue[player];
}

/****************************************************************************************************/

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    if (player == 0 || bot == 0)
        return;

	PrintToChatAll("Event_BotPlayerReplace %i -> %i", bot, player);

    gc_bInTongue[player] = gc_bInTongue[bot];
}

/****************************************************************************************************/

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetZombieClass(victim) != 1)
		return Plugin_Continue;


    char aclassname[64];
    GetEntityClassname(attacker, aclassname, sizeof(aclassname));
    char iclassname[64];
    GetEntityClassname(inflictor, iclassname, sizeof(iclassname));

    PrintToChatAll("victim %i, attacker %i %s, inflictor %i %s, damage %f, damagetype %i", victim, attacker, aclassname, inflictor, iclassname, damage, damagetype);

    PrintToChatAll("damagetypes: (%i)", damagetype);
    if (damagetype == DMG_GENERIC) PrintToChatAll("DMG_GENERIC");
    if (damagetype & DMG_CRUSH) PrintToChatAll("DMG_CRUSH");
    if (damagetype & DMG_BULLET) PrintToChatAll("DMG_BULLET");
    if (damagetype & DMG_SLASH) PrintToChatAll("DMG_SLASH");
    if (damagetype & DMG_BURN) PrintToChatAll("DMG_BURN");
    if (damagetype & DMG_VEHICLE) PrintToChatAll("DMG_VEHICLE");
    if (damagetype & DMG_FALL) PrintToChatAll("DMG_FALL");
    if (damagetype & DMG_BLAST) PrintToChatAll("DMG_BLAST");
    if (damagetype & DMG_CLUB) PrintToChatAll("DMG_CLUB");
    if (damagetype & DMG_SHOCK) PrintToChatAll("DMG_SHOCK");
    if (damagetype & DMG_SONIC) PrintToChatAll("DMG_SONIC");
    if (damagetype & DMG_ENERGYBEAM) PrintToChatAll("DMG_ENERGYBEAM");
    if (damagetype & DMG_PREVENT_PHYSICS_FORCE) PrintToChatAll("DMG_PREVENT_PHYSICS_FORCE");
    if (damagetype & DMG_NEVERGIB) PrintToChatAll("DMG_NEVERGIB");
    if (damagetype & DMG_ALWAYSGIB) PrintToChatAll("DMG_ALWAYSGIB");
    if (damagetype & DMG_DROWN) PrintToChatAll("DMG_DROWN");
    if (damagetype & DMG_PARALYZE) PrintToChatAll("DMG_PARALYZE");
    if (damagetype & DMG_NERVEGAS) PrintToChatAll("DMG_NERVEGAS");
    if (damagetype & DMG_POISON) PrintToChatAll("DMG_POISON");
    if (damagetype & DMG_RADIATION) PrintToChatAll("DMG_RADIATION");
    if (damagetype & DMG_DROWNRECOVER) PrintToChatAll("DMG_DROWNRECOVER");
    if (damagetype & DMG_ACID) PrintToChatAll("DMG_ACID");
    if (damagetype & DMG_SLOWBURN) PrintToChatAll("DMG_SLOWBURN");
    if (damagetype & DMG_REMOVENORAGDOLL) PrintToChatAll("DMG_REMOVENORAGDOLL");
    if (damagetype & DMG_PHYSGUN) PrintToChatAll("DMG_PHYSGUN");
    if (damagetype & DMG_PLASMA) PrintToChatAll("DMG_PLASMA");
    if (damagetype & DMG_AIRBOAT) PrintToChatAll("DMG_AIRBOAT");
    if (damagetype & DMG_DISSOLVE) PrintToChatAll("DMG_DISSOLVE");
    if (damagetype & DMG_BLAST_SURFACE) PrintToChatAll("DMG_BLAST_SURFACE");
    if (damagetype & DMG_DIRECT) PrintToChatAll("DMG_DIRECT");
    if (damagetype & DMG_BUCKSHOT) PrintToChatAll("DMG_BUCKSHOT");
    if (damagetype & 1073741824) PrintToChatAll("DMG_HEADSHOT 2");
    if (damagetype & 2147483648) PrintToChatAll("DMG_HEADSHOT");


    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!IsValidClientIndex(attacker))
        return Plugin_Continue;

    if (!gc_bInTongue[attacker])
        return Plugin_Continue;

    if (GetEntPropEnt(attacker, Prop_Send, "m_tongueOwner") == -1)
    {
        gc_bInTongue[attacker] = false;
        return Plugin_Continue;
    }

    if (attacker != inflictor)
       return Plugin_Continue;

    if (g_iCvar_ShotMissChance < GetRandomInt(1, 100))
        return Plugin_Continue;

    return Plugin_Stop;
}

/****************************************************************************************************/

public Action OnPlayerRunCmd(int client, int &buttons)
{
	// if (client == 1)
	// PrintToChatAll("OnPlayerRunCmd %f", GetGameTime());
	return Plugin_Continue;

    if (!(buttons & IN_ATTACK2))
        return Plugin_Continue;

    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!IsValidClientIndex(client))
        return Plugin_Continue;

    if (!gc_bInTongue[client])
        return Plugin_Continue;

    if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") == -1)
    {
        gc_bInTongue[client] = false;
        return Plugin_Continue;
    }

    if (g_iCvar_ShoveMissChance < GetRandomInt(1, 100))
        return Plugin_Continue;

    buttons &= ~IN_ATTACK2;

    return Plugin_Changed;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_miss_tongue_grab) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_miss_tongue_grab_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_miss_tongue_grab_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_miss_tongue_grab_miss_chance : %i%%", g_iCvar_ShotMissChance);
    PrintToConsole(client, "l4d_miss_tongue_grab_miss_shove_chance : %i%%", g_iCvar_ShoveMissChance);
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