#pragma semicolon 1
#define UPD_LIBFUNC
#define CONVAR_PREFIX "sm_pause"
#pragma newdecls required;

public Plugin myinfo = {
	name = "[NMRiH] SM Pause",
	author = "sh0tx",
	description = "Pauses the game when an admin does that.",
	version = "1.0",
	url = "https://cosmoline.at/"
}

ConVar g_cvarPausable;
bool g_bPaused;
bool g_bBypass;

public void OnPluginStart() {
	
	if ((g_cvarPausable = FindConVar("sv_pausable")) != null) {
		if (AddCommandListener(listener_pause, "pause")) {
			AddCommandListener(listener_pause, "setpause");
			AddCommandListener(listener_pause, "unpause");
			RegAdminCmd("sm_pause", Cmd_pause, ADMFLAG_CONFIG);
			RegAdminCmd("sm_unpause", Cmd_unpause, 0);
		}
		else { 
			PrintToServer("Unable to hook sm_pause command. Game is not supported by this plugin.");
			g_cvarPausable.BoolValue = false;
		}
	}
	else {
		PrintToServer("pause.smx: Unable to find cvar sv_pausable");
	}
}

public Action listener_pause(int client, char[] command, int args) {
	if (g_bBypass) {
		g_bBypass = false;
		return Plugin_Continue;
	}
	
	if (!g_cvarPausable.BoolValue) {
		ReplyToCommand(client, "\x01[\x04SM\x01] Pausing the game is currently disabled.");
		return Plugin_Handled;
	}
	
	int direction;
	if (StrEqual(command, "pause", false)) direction = 0;
	else if (StrEqual(command, "setpause", false)) direction = 1;
	else if (StrEqual(command, "unpause", false)) direction = 2;
	
	if ((g_bPaused && direction == 1) || (!g_bPaused && direction == 2)) {
		ReplyToCommand(client, "\x01[\x04SM\x01] The game is already %s.", g_bPaused ? "paused" : "unpaused");
		return Plugin_Handled;
	}

	else if (!CheckCommandAccess(client, "sm_pause", ADMFLAG_CONFIG)) {
		ReplyToCommand(client, "\x01[\x04SM\x01] You do not have access to this command.");
		return Plugin_Handled;
	}

	ShowActivity2(client, "\x01[\x04SM\x01] ", "\x04%s \x01the game", g_bPaused ? "Unpaused" : "Paused");
	g_bPaused = !g_bPaused;
	g_bBypass = true;
	FakeClientCommand(client, "pause");
	return Plugin_Handled;
}


public Action Cmd_pause(int client, int args) {
	if (client == 0) ServerCommand("pause");
	else FakeClientCommand(client, "pause");
	return Plugin_Handled;
}

public Action Cmd_unpause(int client, int args) {
	if (client == 0) ServerCommand("unpause");
	else FakeClientCommand(client, "unpause");
	return Plugin_Handled;
}
