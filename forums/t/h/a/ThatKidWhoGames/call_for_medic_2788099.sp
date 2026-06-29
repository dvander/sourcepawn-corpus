#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "[TF2] 'MEDIC!' AddCond",
	author      = "PC Gamer, ThatKidWhoGames",
	description = "Gives a player radius healing for a configurable amount of time after calling for medic.",
	version     = "1.0.0",
	url         = "https://sourcemod.net/"
};

// Variables //
ConVar g_cvarEnable;            // Used for storing ConVar for enabling/disabling plugin functionality
ConVar g_cvarDelay;             // Used for storing ConVar for setting delay before a client can use this again
ConVar g_cvarTime;              // Used for storing ConVar for setting time for condition to last for
ConVar g_cvarCondition;         // Used for storing ConVar for condition to set
Handle g_timer[MAXPLAYERS + 1]; // Used for storing timer handle for client's usage delay

public void OnPluginStart() {
	// Create the ConVars
	g_cvarEnable    = CreateConVar("sm_callformedic_enable",    "1",   "Enable/disable the plugin", 							      				 _, true, 0.0, true, 1.0);
	g_cvarDelay     = CreateConVar("sm_callformedic_delay",     "10",  "Delay (in seconds) before players can use the feature again (0 = No delay)", _, true, 0.0);
	g_cvarTime      = CreateConVar("sm_callformedic_time",      "0.1", "Time (in seconds) for the condition to last for", 						     _, true, 0.1);
	g_cvarCondition = CreateConVar("sm_callformedic_condition", "55",  "Condition to give players");

	// Add the command listener
	AddCommandListener(CommandListener_VoiceMenu, "voicemenu");
}

public void OnClientDisconnect_Post(int client) {
	// Kill timer handle
	delete g_timer[client];
}

public Action CommandListener_VoiceMenu(int client, const char[] command, int argc) {
	// Check if plugin is enabled
	if (g_cvarEnable.BoolValue) {
		// Fetch arguments string
		char argstr[4];
		GetCmdArgString(argstr, sizeof(argstr));

		// Check if client indeed called for medic, is alive, and doesn't currently have the condition active
		if (StrEqual(argstr, "0 0") && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, view_as<TFCond>(g_cvarCondition.IntValue))) {
			// Check if delay is enabled
			if (FloatCompare(0.0, g_cvarDelay.FloatValue) == -1) {
				// Check if client is not on cooldown
				if (g_timer[client] == null) {
					// Create cooldown timer for client
					g_timer[client] = CreateTimer(g_cvarDelay.FloatValue, Timer_Cooldown, client);
				}
				else {
					// Skip execution; continue normally
					return Plugin_Continue;
				}
			}

			// Add the condition to the client
			TF2_AddCondition(client, view_as<TFCond>(g_cvarCondition.IntValue), g_cvarTime.FloatValue);
		}
	}

	// Continue normally
	return Plugin_Continue;
}

public Action Timer_Cooldown(Handle timer, int client) {
	// Set timer handle to null
	g_timer[client] = null;

	// Stop execution (unnecessary, but I prefer explicitly stating it ;-) )
	return Plugin_Stop;
}