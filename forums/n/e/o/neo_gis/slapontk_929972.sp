#pragma semicolon 1

#include <sourcemod>

#include <sdktools>

#define VERSION "ALPHA 1"

public Plugin:myinfo = 
{
    name = "Slap on TK",
    author = "haN",
    description = "Slap on TK",
    version = VERSION,
    url = "www.teamsas.nl"
};

public OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    new VictimId = GetEventInt(event, "userid");
    new AttackerId = GetEventInt(event, "attacker");
    new VictimClient = GetClientOfUserId(VictimId);
    new AttackerClient = GetClientOfUserId(AttackerId);
    
    if (GetClientTeam(VictimClient) == GetClientTeam(AttackerClient))
    {
        SlapPlayer(AttackerClient, 0, true);
        PrintToChat(AttackerClient, "[SM] You were slapped for team attacking !");
    }
}