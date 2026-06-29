#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
	name = "[L4D2] Block Idle",
	author = "KeithGDR",
	description = "Blocks the idle command.",
	version = "1.0.0",
	url = "https://KeithGDR.dev/"
};

public void OnPluginStart() {
	AddCommandListener(Command_Idle, "go_away_from_keyboard");
}

public Action Command_Idle(int client, const char[] command, int argc) {
	return Plugin_Stop;
}