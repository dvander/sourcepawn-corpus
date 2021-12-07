#define PLUGIN_NAME                   "Tank Spawn Announcement with sound (made to Tank Rush)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "When the tank spawns, it announces itself in chat by making a sound"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=330277"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define SOUND "ui/pickup_secret01.wav"

#define TEAM_INFECTED 3



static bool g_bTankSpawn;

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("tank_killed", Event_TankKilled, EventHookMode_PostNoCopy);
}

/****************************************************************************************************/

public void OnMapStart()
{
    PrecacheSound(SOUND, true);
}

/****************************************************************************************************/

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bTankSpawn = false;
}

/****************************************************************************************************/

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bTankSpawn)
        RequestFrame(OnNextFrame, GetEventInt(event, "userid"));
}

/****************************************************************************************************/

public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
    g_bTankSpawn = false;
}

/****************************************************************************************************/

public void OnNextFrame(int userid)
{
    int tank = GetClientOfUserId(userid);

    if (!IsValidClient(tank))
        return;

    if (GetClientTeam(tank) != TEAM_INFECTED)
    {
        RequestFrame(OnNextFrame, userid);
        return;
    }

    g_bTankSpawn = true;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        EmitSoundToClient(client, SOUND, client, SNDCHAN_WEAPON, SNDLEVEL_SCREAMING);
        SayText2(client, tank, "\x03[\x04!\x03]\x04The \x05Tank \x04has been spawned!");
    }
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