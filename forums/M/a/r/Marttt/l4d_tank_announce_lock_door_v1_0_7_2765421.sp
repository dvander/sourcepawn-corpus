/****************************************************************************************************
* Plugin     : L4D Tank announce and lock door
* Version    : 1.0.7
* Game       : Left 4 Dead
* Author     : Finishlast
* Based on code  from:
* [L4D / L4D2] Lockdown System | 1.7 [Final] : Jan. 30, 2019 |
* https://forums.alliedmods.net/showthread.php?t=281305
* Aya Supay for making the code look great again
* MasterMind420 for providing a fix to check for all kinds of ending checkpoint doors
*
* Testers    : Myself
* Website    : www.l4d.com
* Purpose    : This plugin announces tank spawns and locks the safehouse door until the tank is dead.
****************************************************************************************************/
public Plugin myinfo =
{
    name = "L4D1 - Tank Announce with automatic door locking",
    author = "finishlast",
    description = "Announce when a Tank has spawned and lock the door until Tank is dead",
    version = "1.0.7",
    url = ""
}

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define UNLOCK 0
#define LOCK 1

#define TEAM_INFECTED 3
#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

static bool g_bL4D2;
static bool g_bAliveTank;
static int g_iTankClass;

int g_iCheckpointDoor = -1;
// bool g_bIsTankAlive;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    g_bL4D2 = (engine == Engine_Left4Dead2);
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("tank_spawn", Event_TankSpawn);
    // HookEvent("player_death", Event_PlayerDeath);

    g_bAliveTank = HasAnyTankAlive();

    CreateTimer(1.0, TimerAliveTankCheck, _, TIMER_REPEAT);
}

public void OnMapStart()
{
    PrecacheSound("ui\\pickup_secret01.wav");
    PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_4.wav");
}

public Action TimerAliveTankCheck(Handle timer)
{
    if (g_bAliveTank)
    {
        g_bAliveTank = HasAnyTankAlive();

        if (!g_bAliveTank)
            OnAllTanksDead();
    }

    return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (IsFinaleMap())
        return;

    // g_bIsTankAlive = false;
    CreateTimer(1.5, CheckDelay);
}

public Action CheckDelay(Handle timer)
{
    if (!IsFinaleMap())
        InitDoor();

    return Plugin_Continue;
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    g_bAliveTank = true;

    Command_Play("ui\\pickup_secret01.wav");
    Command_Play("player\\tank\\voice\\yell\\hulk_yell_4.wav");

    if (IsFinaleMap())
    {
        PrintToChatAll("[SM] A Tank spawned!");
    }
    else
    {
        ControlDoor(LOCK);
        PrintToChatAll("[SM] A Tank spawned. The safehouse is locked!");
    }

    // int UserId = event.GetInt("userid");
    // if (UserId != 0) {
        // int client = GetClientOfUserId(UserId);
        // if (client != 0) {
            // if (IsTank(client) && !g_bIsTankAlive) {
                // g_bIsTankAlive = true;
                // Command_Play("ui\\pickup_secret01.wav");
                // Command_Play("player\\tank\\voice\\yell\\hulk_yell_4.wav");
                // if (!IsFinaleMap()) {
                    // ControlDoor(LOCK);
                    // PrintToChatAll("[SM] A Tank spawned. The safehouse is locked!");
                // }
                // else {
                    // PrintToChatAll("[SM] A Tank spawned!");
                // }
            // }
        // }
    // }
}

// public void Event_PlayerDeath(Event hEvent, const char[] name, bool DontBroadcast)
// {
    // int client = GetClientOfUserId(hEvent.GetInt("userid"));
    // if (client && IsClientInGame(client)) {
        // if (IsTank(client)) {
            // int Tankcount = 0;
               // for (int i = 1; i <= MaxClients; i++)
                // if (IsClientConnected(i) && IsClientInGame(i) &&  IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 5) Tankcount++;
            // if (Tankcount==0){
                // if (!IsFinaleMap()) {
                    // PrintToChatAll("[SM] The Tank is dead! The safehouse is open!");
                    // ControlDoor(UNLOCK);
                // }
                // else {
                // PrintToChatAll("[SM] The Tank is dead!");
                // }
                // g_bIsTankAlive = false;
            // }
        // }
    // }
// }

void OnAllTanksDead()
{
    if (IsFinaleMap())
    {
        PrintToChatAll("[SM] The Tank is dead!");
    }
    else
    {
        ControlDoor(UNLOCK);
        PrintToChatAll("[SM] The Tank is dead! The safehouse is open!");
    }
}

void ControlDoor(int iOperation)
{
    int entity = EntRefToEntIndex(g_iCheckpointDoor);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    switch (iOperation)
    {
        case LOCK:
        {
                AcceptEntityInput(entity, "Close");
                AcceptEntityInput(entity, "Lock");
                AcceptEntityInput(entity, "ForceClosed");

                if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
                    SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
        }
        case UNLOCK:
        {
                if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
                    SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);

                AcceptEntityInput(entity, "Unlock");
                AcceptEntityInput(entity, "ForceClosed");
                AcceptEntityInput(entity, "Open");
        }
    }
}

void InitDoor()
{
    char sModel[PLATFORM_MAX_PATH];

    int target = -1;
    while ((target = FindEntityByClassname(target, "prop_door_rotating_checkpoint")) != -1)
    {
        GetEntPropString(target, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

        if (StrContains(sModel, "checkpoint_door") > -1 && StrContains(sModel, "02") > -1)
        {
            g_iCheckpointDoor = EntIndexToEntRef(target);
            break;
        }
    }
}

bool IsFinaleMap()
{
    char sMap[64];
    GetCurrentMap(sMap, sizeof(sMap));
    if (StrEqual(sMap, "l4d_vs_airport05_runway", false)
     || StrEqual(sMap, "l4d_river03_port", false)
     || StrEqual(sMap, "l4d_vs_smalltown03_ranchhouse", false) //churchguy door fix
     || StrEqual(sMap, "l4d_vs_smalltown05_houseboat", false)
     || StrEqual(sMap, "l4d_garage02_lots", false)
     || StrEqual(sMap, "l4d_vs_farm05_cornfield", false)
     || StrEqual(sMap, "l4d_vs_hospital05_rooftop", false))
        return true;

    return false;
}

public void Command_Play(const char[] arguments)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        ClientCommand(client, "playgamesound %s", arguments);
    }
}

// bool IsTank(int client)
// {
    // if ( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
    // {
        // int class = GetEntProp(client, Prop_Send, "m_zombieClass");
        // if ( class == 5)
            // return true;
    // }
    // return false;
// }

bool HasAnyTankAlive()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsPlayerTank(client))
            continue;

        if (IsPlayerIncapacitated(client))
            continue;

        return true;
    }

    return false;
}

bool IsPlayerTank(int client)
{
    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    if (GetZombieClass(client) != g_iTankClass)
        return false;

    return true;
}

int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

bool IsPlayerIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}