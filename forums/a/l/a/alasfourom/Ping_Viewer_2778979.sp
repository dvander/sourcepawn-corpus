#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = {
    name = "Ping_Viewer",
    author = "",
    description = "Print Your Ping Into Chat",
    version = "1.0",
    url = "https://forums.alliedmods.net/"
};

public void OnPluginStart() {
    RegConsoleCmd("sm_ping", Command_Ping, "Print Ping To Chat");
}

public Action Command_Ping(int client, int args) {
    if (IsClientInGame(client) && !IsFakeClient(client)) {
        char sBuffer[64];
        FormatEx(sBuffer, sizeof(sBuffer), "\x04Your Current Ping:\x05 %.3f ms", GetClientAvgLatency(client, NetFlow_Both));
        ReplaceString(sBuffer, sizeof(sBuffer), "0.00", "", false);
        ReplaceString(sBuffer, sizeof(sBuffer), "0.0", "", false);
        ReplaceString(sBuffer, sizeof(sBuffer), "0.", "", false);
        PrintToChat(client, sBuffer);
    }
    return Plugin_Handled;
} 