#include <sourcemod>

Handle g_serverHud;
ConVar g_hostname;
int timeLeft;

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
  g_hostname = FindConVar("hostname");
}

public Action RefreshHudTimer(Handle timer) {
  RefreshHud();
  return Plugin_Continue;
}

void RefreshHud() {
  GetMapTimeLeft(timeLeft);
  char hostname[32], hudMessage[128], dateTime[24];
  g_hostname.GetString(hostname, sizeof(hostname));
  FormatTime(dateTime, sizeof(dateTime), "%H:%M - %d/%m/%y");

  if (timeLeft > 0) Format(hudMessage, sizeof(hudMessage), "%s\n%s\nOnline Players: %i/%i\nTime left: %02i:%02i", hostname, dateTime, GetClientCount(true), MaxClients, timeLeft / 60, timeLeft % 60);
  else Format(hudMessage, sizeof(hudMessage), "%s\n%s\nOnline Players: %i/%i\nTime left: 00:00", hostname, dateTime, GetClientCount(true), MaxClients);
  
  SetHudTextParams(-1.0, 1.0, 1.0, 255, 255, 255, 255);
  for (int i = 1; i <= MaxClients; ++i) {
    if (!IsClientInGame(i) || IsFakeClient(i)) continue;
    ShowSyncHudText(i, g_serverHud, hudMessage);
  }
}