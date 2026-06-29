#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

bool bFirstJoin[MAXPLAYERS + 1] = {true, ...};

#define PLUGIN_NAME        "name"
#define PLUGIN_AUTHOR      "author"
#define PLUGIN_DESCRIPTION "description"
#define PLUGIN_VERSION     "1.0"
#define PLUGIN_URL         "url"

public Plugin myinfo = {
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
}

public void OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnClientDisconnect(int client) {
	bFirstJoin[client] = true;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int userid = event.GetInt("userid");

	CreateTimer(0.1, OnPlayerSpawned, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnPlayerSpawned(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);

	if (client == 0) {
		return;
	}

	if (bFirstJoin[client]) {
		bFirstJoin[client] = false;

		FakeClientCommand(client, "sm_rpg");
	}
}