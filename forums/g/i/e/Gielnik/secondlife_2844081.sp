#pragma semicolon 1
#pragma newdecls required 

#include <sourcemod>
#include <tf2>

#define PLUGIN_VERSION "1.8"

ConVar g_hBlockTime;
ConVar g_hEnabled;
ConVar g_hRespawns;

bool g_bTimeUp = true; 
int g_iRespawnCount[MAXPLAYERS + 1];

public Plugin myinfo = 
{
    name = "Second Life (TF2 Deathrun)",
    author = "tooti, Gielnik",
    description = "Allows RED team players a second chance to respawn early in Arena rounds",
    version = PLUGIN_VERSION,
    url = "http://fractial-gaming.de"
}

public void OnPluginStart()
{
    CreateConVar("sm_secondlife_version", PLUGIN_VERSION, "Secondlife Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    g_hEnabled = CreateConVar("sm_secondlife_enabled", "1", "Enable Second Life?", FCVAR_NOTIFY);
    g_hBlockTime = CreateConVar("sm_secondlife_blocktime", "15.0", "Seconds after Arena starts that respawn is allowed");
    g_hRespawns = CreateConVar("sm_secondlife_respawns", "1", "How many times a RED player can use Second Life per round");
    
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("teamplay_round_win", Event_RoundWin);
    HookEvent("teamplay_round_start", Event_RoundStartReset); 
    HookEvent("arena_round_start", Event_ArenaActive);       
    
    g_bTimeUp = true;
}

public void OnClientConnected(int client)
{
    g_iRespawnCount[client] = 0;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_hEnabled.BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        int maxRespawns = g_hRespawns.IntValue;

        if (!g_bTimeUp && g_iRespawnCount[client] < maxRespawns)
        {
            g_iRespawnCount[client]++;
            PrintToChat(client, "\x03[Second-Life] \x04You've got a Second Life! Respawning...");
            CreateTimer(0.5, Timer_Respawn, GetClientUserId(client));
        }
    }
}

public void Event_RoundStartReset(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++) 
    {
        g_iRespawnCount[i] = 0;
    }
    g_bTimeUp = true; 
}

public void Event_ArenaActive(Event event, const char[] name, bool dontBroadcast)
{
    g_bTimeUp = false; 
    CreateTimer(g_hBlockTime.FloatValue, Timer_SetTimeUp);
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{
    g_bTimeUp = true; 
}

public Action Timer_SetTimeUp(Handle timer)
{
    g_bTimeUp = true;
    PrintToChatAll("\x03[Second-Life] \x04The Second-Life grace period has ended!");
    return Plugin_Stop;
}

public Action Timer_Respawn(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if (client > 0 && IsClientInGame(client) && !IsPlayerAlive(client))
    {
        TF2_RespawnPlayer(client);
    }
    return Plugin_Stop;
}