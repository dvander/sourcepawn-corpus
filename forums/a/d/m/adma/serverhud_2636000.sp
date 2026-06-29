#include <sourcemod>

Handle g_serverHud;
char hostname[64];
int playerCount = 0;

public Plugin myinfo = {
  name = "Server Hud",
  author = "adma",
  description = "",
  version = "1.0",
  url = ""
};

public void OnPluginStart() {
  g_serverHud = CreateHudSynchronizer();
  CreateTimer(1.0, RefreshHudTimer, _, TIMER_REPEAT);
  GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
  for (int i = 1; i <= MaxClients; ++i) if (IsClientInGame(i)) playerCount++;
}

public void OnClientPostAdminCheck(int client) {
  ++playerCount;
}

public void OnClientDisconnect(int client) {
  --playerCount;
}

public Action RefreshHudTimer(Handle timer) {
  RefreshHud();
  return Plugin_Continue;
}

void RefreshHud() {
  char hudMessage[128], dateTime[24];
  FormatTime(dateTime, sizeof(dateTime), "%H:%M - %d/%m/%y");
  Format(hudMessage, sizeof(hudMessage), "%s\n%s\nOnline Players: %i/%i", hostname, dateTime, playerCount, MaxClients);
  SetHudTextParams(-1.0, 0.0, 1.0, 255, 255, 255, 255);
  for (int i = 1; i <= MaxClients; ++i) {
    if (!IsClientInGame(i)) continue;
    ShowSyncHudText(i, g_serverHud, hudMessage);
  }
}