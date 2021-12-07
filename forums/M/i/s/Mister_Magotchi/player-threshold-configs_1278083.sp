#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"

new Handle:cvar_threshold = INVALID_HANDLE;

new bool:last_round_met_threshold = false;

public Plugin:myinfo = {
  name = "Player Threshold Configs",
  author = "Mister_Magotchi",
  description = "Executes configs based on player count at round start if non-spectator, non-bot player count has crossed a configurable threshold",
  version = PLUGIN_VERSION,
  url = ""
};

public OnPluginStart() {
  CreateConVar(
    "sm_player_threshold_configs_version",
    PLUGIN_VERSION,
    "Player Threshold Configs Version",
    FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
  );
  cvar_threshold = CreateConVar(
    "sm_player_threshold_configs_threshold",
    "4",
    "Minimum number of players required for plugin to use population-normal.cfg instead of population-low.cfg",
    FCVAR_PLUGIN
  );

  HookEvent("round_start", OnRoundStart);
  AutoExecConfig(true, "player-threshold-configs");
}

public OnConfigsExecuted() {
  ServerCommand("exec population-low");
  last_round_met_threshold = false;
}

public OnRoundStart (Handle:event, const String:name[], bool:dontBroadcast) {
  new client;
  new client_count = 0;
  for (client = MaxClients; 0 < client; client--) {
    if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientObserver(client)) {
      client_count++;
    }
  }
  if (client_count < GetConVarInt(cvar_threshold)) {
    if (last_round_met_threshold) {
      ServerCommand("exec population-low");
    }
    last_round_met_threshold = false;
  }
  else {
    if (!last_round_met_threshold) {
      ServerCommand("exec population-normal");
    }
    last_round_met_threshold = true;
  }
}