#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar convar_Enabled;
ConVar cvIncapCount;
int g_Total[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "[L4D2] Incap Messages",
	author = "KeithGDR",
	description = "Shows Incapacitated messages in chat to players.",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=350375"
};

public void OnPluginStart() {
	CreateConVar("sm_l4d2_incap_msg_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_l4d2_incap_msg_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();

	cvIncapCount = FindConVar("survivor_max_incapacitated_count");

	HookEvent("player_spawn", Event_OnPlayerSpawnOrDeath);
	HookEvent("player_death", Event_OnPlayerSpawnOrDeath);
	HookEvent("player_incapacitated", Event_OnPlayerIncapacitated);
	HookEvent("revive_success", Event_OnPlayerReviveSuccess);
	HookEvent("heal_success", Event_OnPlayerHealSuccess);
}

public void Event_OnPlayerSpawnOrDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0) {
		g_Total[client] = 0;
	}
}

public void Event_OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client > 0) {
		g_Total[client]++;
	}
}

public void Event_OnPlayerReviveSuccess(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("subject"));

	if (client > 0 && !event.GetBool("ledge_hang") && convar_Enabled.BoolValue) {
		PrintToChat(client, "[SM] Incap %i/%i", g_Total[client], cvIncapCount.IntValue);
	}
}

public void Event_OnPlayerHealSuccess(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("subject"));

	if (client > 0) {
		g_Total[client] = 0;
	}
}

public void OnClientDisconnect_Post(int client) {
	g_Total[client] = 0;
}