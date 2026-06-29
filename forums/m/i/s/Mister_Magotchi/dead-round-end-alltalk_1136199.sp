#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3.4"

new Handle:cvar_dead_mode = INVALID_HANDLE;
new Handle:cvar_round_end_enabled = INVALID_HANDLE;
new Handle:cvar_bomb_enabled = INVALID_HANDLE;

public Plugin:myinfo = {
  name = "Dead and Round-End Alltalk",
  author = "Mister_Magotchi",
  description = "Dead players hear all, all hear all at round end, and all hear all when Terrorists are dead (CS:S).",
  version = PLUGIN_VERSION,
  url = ""
};

public OnPluginStart() {
  CreateConVar(
    "sm_dead_round_end_alltalk_version",
    PLUGIN_VERSION,
    "Dead and Round-End Alltalk Version",
    FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
  );
  cvar_dead_mode = CreateConVar(
    "sm_dead_round_end_alltalk_dead_mode",
    "3",
    "Who dead hear: 0 = Feature disabled, 1 = Dead players, 2 = Dead players and living teammates, 3 = Everyone",
    FCVAR_PLUGIN
  );
  cvar_round_end_enabled = CreateConVar(
    "sm_dead_round_end_alltalk_round",
    "1",
    "Toggles whether everyone hears everyone at round end",
    FCVAR_PLUGIN
  );
  cvar_bomb_enabled = CreateConVar(
    "sm_dead_round_end_alltalk_bomb",
    "0",
    "Toggles whether everyone hears everyone when all Terrorists are dead",
    FCVAR_PLUGIN
  );
  HookEvent("player_spawn", OnPlayerSpawn);
  HookEvent("player_death", OnPlayerDeath);
  HookEvent("round_end", OnRoundEnd);
  AutoExecConfig(true, "dead-round-end-alltalk");
}

PseudoAlltalk () {
  for (new client = MaxClients; 0 < client; client--) {
    if (IsClientInGame(client) && !(GetClientListeningFlags(client) & VOICE_MUTED)) {
      SetClientListeningFlags(client, VOICE_SPEAKALL);
    }
  }
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  if (!(GetClientListeningFlags(client) & VOICE_MUTED)) {
    SetClientListeningFlags(client, VOICE_NORMAL);
  }
  for (new client_2 = MaxClients; 0 < client_2; client_2--) {
    if (IsClientInGame(client_2) && !(GetClientListeningFlags(client_2) & VOICE_MUTED)) {
      SetListenOverride(client, client_2, Listen_Default);
    }
  }
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
  new dead_mode = GetConVarInt(cvar_dead_mode);
  new client;
  if (dead_mode) {
    client = GetClientOfUserId(GetEventInt(event, "userid"));
    new bool:client_2_not_muted;
    for (new client_2 = MaxClients; 0 < client_2; client_2--) {
      if (IsClientInGame(client_2)) {
        client_2_not_muted = !(GetClientListeningFlags(client_2) & VOICE_MUTED);
        switch (dead_mode) {
          case 1, 2: {
            if (!IsPlayerAlive(client_2)) {
              if (client_2_not_muted) {
                SetListenOverride(client, client_2, Listen_Yes);
              }
              if (!(GetClientListeningFlags(client) & VOICE_MUTED)) {
                SetListenOverride(client_2, client, Listen_Yes);
              }
            }
            else if (GetClientTeam(client) == GetClientTeam(client_2)) {
              switch (dead_mode) {
                case 2: {
                  if (client_2_not_muted) {
                    SetListenOverride(client, client_2, Listen_Yes);
                  }
                }
                case 1: {
                  SetListenOverride(client, client_2, Listen_No);
                }
              }
            }
          }
          case 3: {
            if (client_2_not_muted) {
              SetListenOverride(client, client_2, Listen_Yes);
            }
          }
        }
      }
    }
  }
  if (GetConVarBool(cvar_bomb_enabled)) {
    new bool:terrorists_dead = true;
    for (client = MaxClients; 0 < client; client--) {
      if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2) {
        terrorists_dead = false;
        break;
      }
    }
    if (terrorists_dead) {
      PseudoAlltalk();
    }
  }
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
  if (GetConVarBool(cvar_round_end_enabled)) {
    PseudoAlltalk();
  }
}