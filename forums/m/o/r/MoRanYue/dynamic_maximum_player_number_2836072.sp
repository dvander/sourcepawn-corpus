#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define DEBUG false

#define SPECTATOR_TEAM_ID 1

ConVar is_enabled;
ConVar auto_initial_max_player_number;
ConVar initial_max_player_number;
ConVar allowed_max_player_number;

ConVar max_players;

public Plugin myinfo = {
    name = "[ANY?] Dynamic Maximum Player Number",
    author = "MoRanYue",
    description = "Adjust maximum player number according to spectator number.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net"
};

public void OnPluginStart() {
    int max_clients = MaxClients;

    // EngineVersion engine_version = GetEngineVersion();
    // if (engine_version == Engine_Left4Dead || engine_version == Engine_Left4Dead2) {
    //     PluginIterator plugin_iterator = PluginIterator();
    //     while (plugin_iterator.Next()) {
    //         char name[32];
    //         GetPluginInfo(plugin_iterator.Plugin, PlInfo_Name, name, sizeof(name));
    //         if (StrEqual(name, "[L4D & L4D2] Left 4 Dead Slots")) {
    //             max_clients = 18;
    //             break;
    //         }
    //     }
    // }

    // char cur_max_player_number[4];
    char cur_max_clients[4];
    // IntToString(GetMaxHumanPlayers(), cur_max_player_number, sizeof(cur_max_player_number));
    IntToString(max_clients, cur_max_clients, sizeof(cur_max_clients));

    is_enabled = CreateConVar("dmpn_is_enabled", "1", "0 will disable the plugin, other number will enable it", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    auto_initial_max_player_number = CreateConVar("dmpn_auto_initial_max_player_number", "0", "Automatically set initial maximum number of player to the value of MaxHumanPlayers()", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    initial_max_player_number = CreateConVar("dmpn_initial_max_player_number", "8", "Initial maximum number of player, must be lower than dmpn_allowed_max_player_number", FCVAR_NOTIFY, true, 1.0, true, float(MAXPLAYERS));
    allowed_max_player_number = CreateConVar("dmpn_allowed_max_player_number", cur_max_clients, "The maximum number of player which possibly be lift", FCVAR_NOTIFY, true, 1.0, true, float(MAXPLAYERS));
    CreateConVar("dynamic_maximum_player_number_version", PLUGIN_VERSION, "Dynamic Maximum Player Number version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "dynamic_maximum_player_number");

    is_enabled.AddChangeHook(OnIsEnabledChange);
    initial_max_player_number.AddChangeHook(OnMaxPlayerNumberCvarsChange);
    allowed_max_player_number.AddChangeHook(OnMaxPlayerNumberCvarsChange);

    if (initial_max_player_number.IntValue > allowed_max_player_number.IntValue) {
        RestrictMaxPlayerNumberCvars();
    }

    RegConsoleCmd("sm_spectator", SwitchPlayerTeamToSpectatorCommand, "Switch your team to spectator");
    RegConsoleCmd("sm_spec", SwitchPlayerTeamToSpectatorCommand, "Switch your team to spectator, an alias for sm_spectator");
    RegConsoleCmd("sm_s", SwitchPlayerTeamToSpectatorCommand, "Switch your team to spectator, an alias for sm_spectator");
}

public void OnAllPluginsLoaded() {
    max_players = FindConVar("sv_maxplayers");
    if (!max_players) {
        EngineVersion engine_version = GetEngineVersion();
        if (engine_version == Engine_Left4Dead || engine_version == Engine_Left4Dead2) {
            SetFailState("CVar sv_maxplayers is not found, you have to install L4DToolz or Left 4 Slots");
        }
        else {
            SetFailState("CVar sv_maxplayers is not found, this game may need an addon to change maximum player number");
        }
        return;
    }

    if (is_enabled.BoolValue) {
        HookEvent("player_team", OnPlayerTeamChange);
        ChangeMaxPlayerNumber();
    }
}

public void OnIsEnabledChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (convar.BoolValue) {
        HookEvent("player_team", OnPlayerTeamChange);
        ChangeMaxPlayerNumber();
    }
    else {
        UnhookEvent("player_team", OnPlayerTeamChange);
    }
}
public void OnMaxPlayerNumberCvarsChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (initial_max_player_number.IntValue > allowed_max_player_number.IntValue) {
        RestrictMaxPlayerNumberCvars();
    }
    ChangeMaxPlayerNumber();
}
public void OnMapStart() {
    if (auto_initial_max_player_number.BoolValue) {
        initial_max_player_number.SetInt(GetMaxHumanPlayers(), false, false);
    }
}

public void OnPlayerTeamChange(Event event, const char[] name, bool dontBroadcast) {
    if (
        GetEventInt(event, "team") == SPECTATOR_TEAM_ID ||
        GetEventInt(event, "oldteam") == SPECTATOR_TEAM_ID
    ) {
        ChangeMaxPlayerNumber();
    }
}

public Action SwitchPlayerTeamToSpectatorCommand(int client, int args) {
    if (client == 0 || !IsClientInGame(client) || IsFakeClient(client) || !is_enabled.BoolValue) {
        return Plugin_Handled;
    }

    ChangeClientTeam(client, SPECTATOR_TEAM_ID);
    return Plugin_Handled;
}

void RestrictMaxPlayerNumberCvars() {
    PrintToServer("[DMPN] dmpn_initial_max_player_number is greater than dmpn_allowed_max_player_number, the former will be restricted to the latter's value");
    initial_max_player_number.SetInt(allowed_max_player_number.IntValue, false, false);
}

void ChangeMaxPlayerNumber() {
    if (is_enabled.BoolValue && GetClientCount()) {
        CreateTimer(1.0, ChangeMaxPlayerNumberCallback);
    }
}
public Action ChangeMaxPlayerNumberCallback(Handle timer) {
    int spectator_number = GetTeamClientCount(SPECTATOR_TEAM_ID);
    int max_player_number = initial_max_player_number.IntValue + spectator_number;
    if (max_player_number > allowed_max_player_number.IntValue) {
        return Plugin_Stop;
    }
    if (DEBUG) {
        PrintToServer("spectator_number = %d", spectator_number);
        PrintToServer("max_player_number = %d", max_player_number);
    }

    max_players.SetInt(
        max_player_number < initial_max_player_number.IntValue ?
        initial_max_player_number.IntValue : max_player_number,
        false, false
    );
    return Plugin_Stop;
}