#pragma semicolon 1
#include <sourcemod>

public void OnPluginStart() {
	RegConsoleCmd("status", Command_Status);
}

public Action Command_Status(int client, int args) {
	return Plugin_Handled;
}