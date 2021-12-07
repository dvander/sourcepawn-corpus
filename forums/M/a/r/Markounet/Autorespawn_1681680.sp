#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

new Handle:g_hTimerRespawn[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new g_iDecompte[MAXPLAYERS+1];

public Plugin:myinfo = 
{
name = "Autorespawn",
author = "Markounet",
description = "The player respawn shortly after his death with a countdown",
version = "1.0",
url = ""
}

public OnPluginStart()
{
HookEvent("player_death", CallBack_Death);
}

public Action:CallBack_Death(Handle:event, const String:name[], bool:dontBroadcast) 
{
new client = GetClientOfUserId(GetEventInt(event, "userid"));
if (GetClientTeam(client) > 1)
{
g_iDecompte[client] = 10;
g_hTimerRespawn[client] = CreateTimer(1.0, fTimerDecompte, client, TIMER_REPEAT);
PrintCenterText(client, "You go respawn in %d seconds", g_iDecompte[client]);
}
}
public Action:fTimerDecompte(Handle:timer, any:client)
{
if (IsClientInGame(client) && !IsPlayerAlive(client) && g_iDecompte[client] > 0)
{
g_iDecompte[client]--;
PrintCenterText(client, "You go respawn in %d second%s", g_iDecompte[client], (g_iDecompte[client] > 1 ? "s" : ""));
}
else if (g_iDecompte[client] == 0)
{
CS_RespawnPlayer(client);
fTrashTimer(client);
}
else
{
fTrashTimer(client);
}
}
public OnClientDisconnect(client)
{
if (IsClientInGame(client))
{
fTrashTimer(client);
}
}

fTrashTimer(client)
{
if (g_hTimerRespawn[client] != INVALID_HANDLE)
{
KillTimer(g_hTimerRespawn[client]);
g_hTimerRespawn[client] = INVALID_HANDLE;
}
}
