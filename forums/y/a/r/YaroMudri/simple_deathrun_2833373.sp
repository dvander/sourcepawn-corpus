#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
    name = "Arena Random Teams",
    author = "Your Name",
    description = "A simple Deathrun plugin for Team Fortress 2.",
    version = PLUGIN_VERSION,
    url = "https://example.com"
};

bool g_bIsArenaMode = false;

public void OnPluginStart() {
    HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("arena_round_start", Event_ArenaRoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart() {
    g_bIsArenaMode = TF2_IsArenaMode();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    if (!g_bIsArenaMode) {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1) {
            ChangeClientTeam(i, view_as<int>(TFTeam_Red));
        }
    }

    int[] players = new int[MaxClients];
    int playerCount = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == view_as<int>(TFTeam_Red)) {
            players[playerCount++] = i;
        }
    }

    if (playerCount > 0) {
        int randomPlayer = players[GetRandomInt(0, playerCount - 1)];
        ChangeClientTeam(randomPlayer, view_as<int>(TFTeam_Blue));
    }
    return Plugin_Continue;
}

public Action Event_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_bIsArenaMode = true;
    return Plugin_Continue;
}

bool TF2_IsArenaMode() {
    ConVar hArenaMode = FindConVar("tf_gamemode_arena");
    if (hArenaMode != null && hArenaMode.BoolValue) {
        return true;
    }
    return false;
}