#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define TEAM_INFECTED 3
#define ZC_TANK 8
#define QMAX 64

public Plugin myinfo =
{
    name = "L4D2 Versus Tank Offer",
    author = "Tighty-Whitey",
    description = "Assign spawned Tank bots to different human Infected.",
    version = "1.0",
    url = ""
};

bool g_QueuedThisLife[MAXPLAYERS + 1];
int g_Queue[QMAX];
int g_QHead;
int g_QCount;
Handle g_hProcess;
int g_LastPick;

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; i++) g_QueuedThisLife[i] = false;
    g_QHead = 0;
    g_QCount = 0;
    g_hProcess = null;
    g_LastPick = 0;
}

public void OnClientDisconnect(int client)
{
    if (client >= 1 && client <= MaxClients) g_QueuedThisLife[client] = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients) g_QueuedThisLife[client] = false;
}

static bool IsHumanInfected(int client)
{
    return client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED && !IsFakeClient(client);
}

static bool IsHumanTankAlive(int client)
{
    if (!IsHumanInfected(client)) return false;
    if (!IsPlayerAlive(client)) return false;
    return GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK;
}

static int ChooseNextEligible()
{
    int start = g_LastPick;
    for (int step = 1; step <= MaxClients; step++)
    {
        int i = ((start + step - 1) % MaxClients) + 1;
        if (!IsHumanInfected(i)) continue;
        if (IsHumanTankAlive(i)) continue;
        g_LastPick = i;
        return i;
    }
    return 0;
}

static void QueuePush(int userid)
{
    if (g_QCount >= QMAX) return;
    int idx = (g_QHead + g_QCount) % QMAX;
    g_Queue[idx] = userid;
    g_QCount++;
}

static int QueuePop()
{
    if (g_QCount <= 0) return 0;
    int userid = g_Queue[g_QHead];
    g_QHead = (g_QHead + 1) % QMAX;
    g_QCount--;
    return userid;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!L4D_IsVersusMode()) return;

    int tank = GetClientOfUserId(event.GetInt("userid"));
    if (tank <= 0 || tank > MaxClients) return;
    if (!IsClientInGame(tank)) return;
    if (GetClientTeam(tank) != TEAM_INFECTED) return;
    if (!IsFakeClient(tank)) return;
    if (GetEntProp(tank, Prop_Send, "m_zombieClass") != ZC_TANK) return;
    if (g_QueuedThisLife[tank]) return;

    g_QueuedThisLife[tank] = true;
    QueuePush(GetClientUserId(tank));

    if (g_hProcess == null)
        g_hProcess = CreateTimer(0.1, Timer_ProcessQueue, 0, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ProcessQueue(Handle timer, any data)
{
    g_hProcess = null;

    if (!L4D_IsVersusMode()) return Plugin_Stop;

    int tank = 0;
    while (g_QCount > 0)
    {
        int userid = QueuePop();
        int cl = GetClientOfUserId(userid);
        if (cl <= 0 || cl > MaxClients) continue;
        if (!IsClientInGame(cl)) continue;
        if (GetClientTeam(cl) != TEAM_INFECTED) continue;
        if (!IsFakeClient(cl)) continue;
        if (GetEntProp(cl, Prop_Send, "m_zombieClass") != ZC_TANK) continue;
        tank = cl;
        break;
    }

    if (tank == 0) return Plugin_Stop;

    int pick = ChooseNextEligible();
    if (pick != 0)
        L4D_TakeOverZombieBot(pick, tank);

    if (g_QCount > 0)
        g_hProcess = CreateTimer(0.2, Timer_ProcessQueue, 0, TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}
