#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <colors>
#define REQUIRE_EXTENSIONS

#define PREFIX "[{green}Respawn{default}] %t"
#define PLUGIN_VERSION "1.0"

new Handle:sm_respawn_enabled = INVALID_HANDLE;

public Plugin:myinfo = {
  name = "Respawn Redux",
  author = "brownzilla",
  description = "Allows yourself to respawn on certain maps.",
  version = PLUGIN_VERSION,
  url = "http://sourcemod.net"
};

public OnPluginStart() {
  LoadTranslations("respawn_redux.phrases");
  sm_respawn_enabled = CreateConVar("sm_respawn_enabled", "1", "Enable or disable the plugin: 0 = Disabled | 1 = Enabled");
  RegConsoleCmd("sm_respawn", Command_Respawn, "Respawns a client");
}

public OnConfigsExecuted() {
  decl String:mapname[128];
  GetCurrentMap(mapname, sizeof(mapname));
  if(strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0)) {
    SetConVarInt(sm_respawn_enabled, 0);
  } else {
    SetConVarInt(sm_respawn_enabled, 1);
  }
}

public Action:Command_Respawn(client, args) {
  if (GetConVarInt(sm_respawn_enabled) == 1) {
    if (!IsPlayerAlive(client)) {
      CS_RespawnPlayer(client);
      CPrintToChat(client, PREFIX, "dead");
    } else {
      CPrintToChat(client, PREFIX, "alive");
    }
  } else {
    CPrintToChat(client, PREFIX, "unable");
  }
}
