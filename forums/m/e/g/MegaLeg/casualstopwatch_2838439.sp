#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define RED_NAME "RED"
#define BLU_NAME "BLU"
#define FUDGE_WAITING_TIMER_OFFSET 2

ConVar mpTournamentConVar;
ConVar mpRedTeamName;
ConVar mpBluTeamName;
ConVar realWaitingForPlayersTimeConVar;
ConVar ourWaitingForPlayersTimeConVar;

public Plugin myinfo = {
    name = "Casual Style Stopwatch Mode",
    author = "MegaLeg",
    description = "Improve the tournament mode experience with public servers and stopwatch mode in mind",
    version = "1.0",
    url = "https://git.upwardmc.net/UpwardMC/TF2/CasualStopwatch"
};

public void OnPluginStart() {
    realWaitingForPlayersTimeConVar = FindConVar("mp_waitingforplayers_time");
    mpTournamentConVar = FindConVar("mp_tournament");
    mpRedTeamName = FindConVar("mp_tournament_redteamname");
    mpBluTeamName = FindConVar("mp_tournament_blueteamname");
    ourWaitingForPlayersTimeConVar = CreateConVar("cs_waitingforplayers_time", "90", "Time that the \"Waiting for Players\" period should last for.", 0, true, 0.0, false);

    HookEvent("tournament_stateupdate", OnTeamReady, EventHookMode_Pre);
    HookEvent("teamplay_game_over", OnGameOver, EventHookMode_Pre);
    HookEvent("teams_changed", TeamsSwitched, EventHookMode_Post);

    HookConVarChange(ourWaitingForPlayersTimeConVar, updateWaitingForPlayersTime);

    PrintToServer("[CasualStopwatch] Plugin loaded");
}

public void OnMapInit(const char[] mapName) {
    PrintToServer("New Map Loading! Disabling Tournament Mode!");

    int waitingForPlayersTime = GetConVarInt(ourWaitingForPlayersTimeConVar);

    if (waitingForPlayersTime > 0) {
        SetConVarInt(realWaitingForPlayersTimeConVar, waitingForPlayersTime + FUDGE_WAITING_TIMER_OFFSET);
    }

    SetConVarInt(mpTournamentConVar, 0);
}

public void TF2_OnWaitingForPlayersStart() {
    int tournamentModeValue = GetConVarInt(mpTournamentConVar);

    if (tournamentModeValue != 0) {
        SetConVarInt(mpTournamentConVar, 0);
    }
}

public void TF2_OnWaitingForPlayersEnd() {
    PrintToServer("Match Going Live! Enabling Tournament Mode!");

    SetConVarInt(mpTournamentConVar, 1);
}

// Team names switch because of tournament mode, so we must set them to be the same every time a team switch happens
Action TeamsSwitched(Event event, const char[] name, bool dontBroadcast) {
    RunAfterThisServerTick(restoreOriginalTeamNames);

    return Plugin_Continue;
}

Action restoreOriginalTeamNames(Handle timer, any data) {
    SetConVarString(mpBluTeamName, BLU_NAME);
    SetConVarString(mpRedTeamName, RED_NAME);

    return Plugin_Stop;
}

Action OnGameOver(Event event, const char[] name, bool dontBroadcast) {
    PrintToServer("Match Ended! Disabling Tournament Mode!");

    SetConVarInt(mpTournamentConVar, 0);

    return Plugin_Continue;
}

Action OnTeamReady(Event event, const char[] name, bool dontBroadcast)
{
    RunAfterThisServerTick(restoreOriginalTeamNames);

    return Plugin_Stop;
}

void updateWaitingForPlayersTime(ConVar convar, const char[] oldValue, const char[] newValue) {
    int waitingForPlayersTime = GetConVarInt(ourWaitingForPlayersTimeConVar);

    if (waitingForPlayersTime > 0) {
        SetConVarInt(realWaitingForPlayersTimeConVar, waitingForPlayersTime + FUDGE_WAITING_TIMER_OFFSET);
    }
}

void RunAfterThisServerTick(Timer nextTickCallback) {
    CreateTimer(0.0, nextTickCallback);
}