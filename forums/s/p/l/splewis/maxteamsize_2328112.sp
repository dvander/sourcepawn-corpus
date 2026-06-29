#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

ConVar g_hMaxTeamSizeCvar;
ConVar g_hEnabledCvar;

public Plugin myinfo = {
    name = "CS:GO Max team size",
    author = "splewis",
    description = "Sets a maximum number of players per team",
    version = "1.0.0",
    url = "https://github.com/splewis/csgo-pug-setup"
};

public void OnPluginStart() {
    g_hMaxTeamSizeCvar = CreateConVar("sm_max_team_size", "5", "Maximum number of players allowed on a team");
    g_hEnabledCvar = CreateConVar("sm_max_team_size_enabled", "1", "Whether the plugin is enabled");

    AutoExecConfig(true, "maxteamsize");
    AddCommandListener(Command_JoinTeam, "jointeam");
    HookEvent("player_connect_full", Event_PlayerConnectFull);
    HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
}

public Action Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    return Plugin_Continue;
}

/**
 * Full connect event right when a player joins.
 * This sets the auto-pick time to a high value because mp_forcepicktime is broken and
 * if a player does not select a team but leaves their mouse over one, they are
 * put on that team and spawned, so we can't allow that.
 * This may not be needed anymore.
 */
public Action Event_PlayerConnectFull(Handle event, const char[] name, bool dontBroadcast) {
    if (g_hEnabledCvar.IntValue == 0)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 3600.0);
}

public Action Command_JoinTeam(int client, const char[] command, int argc) {
    if (g_hEnabledCvar.IntValue == 0)
        return Plugin_Continue;

    if (!IsValidClient(client))
        return Plugin_Stop;

    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));
    int team_to = StringToInt(arg);

    // don't let someone change to a "none" team (e.g. using auto-select)
    if (team_to == CS_TEAM_NONE)
        return Plugin_Stop;

    int playerCount = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayer(i) && GetClientTeam(i) == team_to) {
            playerCount++;
        }
    }

    if (playerCount >= g_hMaxTeamSizeCvar.IntValue) {
        return Plugin_Stop;
    } else {
        return Plugin_Continue;
    }
}

public bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}

public bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client);
}
