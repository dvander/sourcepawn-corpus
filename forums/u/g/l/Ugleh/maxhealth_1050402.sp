/**
 * MaxHealth Changer by bl4nk
 *
 * Description:
 *   Change the max health of players at spawn.
 *
 */

#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new Handle:cvarAmount;

public Plugin:myinfo =
{
    name = "MaxHealth Changer",
    author = "bl4nk",
    description = "Change the max health of players at spawn",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
    CreateConVar("sm_maxhealthchanger_version", PLUGIN_VERSION, "MaxHealth Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvarAmount = CreateConVar("sm_maxhealth", "200", "Amount of life to change health to upon spawn", FCVAR_PLUGIN, true, 1.0, false, _);

    HookEvent("player_spawn", event_PlayerSpawn);
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (GetClientTeam(client) == 2)
        CreateTimer(0.1, timer_PlayerSpawn, client);
}  

public Action:timer_PlayerSpawn(Handle:timer, any:client)
{
    new MaxHealth = GetConVarInt(cvarAmount);
    SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), MaxHealth, 4, true);
    SetEntData(client, FindDataMapOffs(client, "m_iHealth"), MaxHealth, 4, true);
}