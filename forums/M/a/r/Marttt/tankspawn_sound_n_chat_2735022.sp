// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "Tank Spawn Announcement with sound (made to Tank Rush)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "When the tank spawns, it announces itself in chat by making a sound"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330277"

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
// Defines
// ====================================================================================================
#define SOUND                         "ui/pickup_secret01.wav"

#define TEAM_INFECTED                 3

#define L4D1_ZOMBIECLASS_TANK         5
#define L4D2_ZOMBIECLASS_TANK         8

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bAliveTank;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iTankClass;

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
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    HookEvent("tank_spawn", Event_TankSpawn);

    CreateTimer(0.1, tmrAliveTankCheck, _, TIMER_REPEAT);
}

/****************************************************************************************************/

public void OnMapStart()
{
    PrecacheSound(SOUND, true);
}

/****************************************************************************************************/

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bAliveTank)
        return;

    g_bAliveTank = true;

    OnNextFrame();
}

/****************************************************************************************************/

public void OnNextFrame()
{
    int infected = FindRandomPlayerByTeam(TEAM_INFECTED);

    if (infected == 0)
    {
        RequestFrame(OnNextFrame);
        return;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        EmitSoundToClient(client, SOUND, client, SNDCHAN_WEAPON, SNDLEVEL_SCREAMING);
        SayText2(client, infected, "\x03[\x04!\x03]\x04The \x05Tank \x04has been spawned!");
    }
}

/****************************************************************************************************/

public Action tmrAliveTankCheck(Handle timer)
{
    if (!g_bAliveTank)
        return Plugin_Continue;

    g_bAliveTank = HasAnyTankAlive();

    return Plugin_Continue;
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
 * Returns if the client is a valid tank.
 *
 * @param client        Client index.
 * @return              True if client is a tank, false otherwise.
 */
bool IsPlayerTank(int client)
{
    if (!IsValidClient(client))
        return false;

    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (GetZombieClass(client) != g_iTankClass)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    return true;
}

/****************************************************************************************************/

/**
 * Returns if any tank is alive.
 *
 * @return              True if any tank is alive, false otherwise.
 */
bool HasAnyTankAlive()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsPlayerTank(client))
            continue;

        if (IsPlayerIncapacitated(client))
            continue;

        return true;
    }

    return false;
}

/****************************************************************************************************/

void SayText2(int client, int author, const char[] format, any ...)
{
    char message[250];
    VFormat(message, sizeof(message), format, 4);

    Handle hBuffer = StartMessageOne("SayText2", client);
    BfWriteByte(hBuffer, author);
    BfWriteByte(hBuffer, true);
    BfWriteString(hBuffer, message);
    EndMessage();
}

/****************************************************************************************************/

int FindRandomPlayerByTeam(int color_team)
{
    if (!(1 <= color_team <= 4))
        return 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (GetClientTeam(client) == color_team)
            return client;
    }

    return 0;
}