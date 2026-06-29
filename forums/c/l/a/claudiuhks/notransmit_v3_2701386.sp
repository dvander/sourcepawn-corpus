#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name        =   "Any Game Anti-Cheat: Hidden Spectators"                , \
    author      =   "Hattrick HKS (claudiuhks)"                             , \
    description =   "Blocks Any Kind Of Spectators' Resolvers"              , \
    version     =   "1.0"                                                   , \
    url         =   "https://forums.alliedmods.net/showthread.php?t=324601" ,
};

bool g_bAlive[MAXPLAYERS] = { false, ... };

public void OnClientPutInServer(int nClient)
{
    SDKHookEx(nClient, SDKHook_SetTransmit, Hook_SetTransmit);
}

public void OnClientDisconnect(int nClient)
{
    SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bAlive[nClient] = false;
}

public void OnMapEnd()
{
    for (int nClient = 1; nClient < MAXPLAYERS; nClient++)
    {
        SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

public void OnPluginEnd()
{
    for (int nClient = 1; nClient < MAXPLAYERS; nClient++)
    {
        SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);
    }
}

public void OnClientDisconnect_Post(int nClient)
{
    SDKUnhook(nClient, SDKHook_SetTransmit, Hook_SetTransmit);

    g_bAlive[nClient] = false;
}

public void OnPluginStart()
{
    HookEventEx("player_spawn", Event_PlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_death", Event_PlayerStateChanged, EventHookMode_Post);
    HookEventEx("player_team",  Event_PlayerStateChanged, EventHookMode_Post);

    HookEventEx("player_spawn", Event_PlayerStateChanged, EventHookMode_Pre);
    HookEventEx("player_death", Event_PlayerStateChanged, EventHookMode_Pre);
    HookEventEx("player_team",  Event_PlayerStateChanged, EventHookMode_Pre);
}

public Action Event_PlayerStateChanged(Event hEv, const char[] szEvName, bool bEvNoBC)
{
    if (hEv != null)
    {
        CreateTimer(0.001, Timer_PlayerStateChanged, hEv.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_PlayerStateChanged(Handle hTimer, any nUserId)
{
    int nClient = GetClientOfUserId(nUserId);

    if (H_IsValidClient(nClient))
    {
        g_bAlive[nClient] = IsPlayerAlive(nClient);
    }
}

public Action Hook_SetTransmit(int nEntity, int nClient)
{
    if (g_bAlive[nClient] &&    !g_bAlive[nEntity])
        return Plugin_Handled;  // If I'm alive, the game server shouldn't transmit through the Internet any dead players to me!

    return Plugin_Continue;
}

bool H_IsValidClient(int nClient)
{
    if (nClient < 1                             || \
        nClient > (MAXPLAYERS - 1)              || \
        !IsClientConnected(nClient)             || \
        !IsClientInGame(nClient))
    {
        return false;
    }

    return true;
}
