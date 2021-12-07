#include <sourcemod>
#include <warden>
#include <emitsoundany>

bool g_bIsWarden[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Warden sounds",
	author = "tommie113 || edit by lingzhidiyu",
	description = "Plays a sound whenever a warden is created or removed.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	RegConsoleCmd("sm_uw", OnRemoveWarden);
	RegConsoleCmd("sm_unwarden", OnRemoveWarden);
}

public Action OnRemoveWarden(int client, int args) {
	if (g_bIsWarden[client]) {
		g_bIsWarden[client] = false;

		warden_RemovedMessage();
	}
}

public OnMapStart() 
{ 
	AddFileToDownloadsTable("sound/sourcemod/warden/warden.mp3");
	AddFileToDownloadsTable("sound/sourcemod/warden/uwarden.mp3");
	PrecacheSoundAny("sourcemod/warden/warden.mp3");
	PrecacheSoundAny("sourcemod/warden/uwarden.mp3");
} 

public void OnClientDisconnect(client) {
	g_bIsWarden[client] = false;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bIsWarden[client] = false;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bIsWarden[client]) {
		g_bIsWarden[client] = false;
		warden_RemovedMessage();
	}
}

public warden_OnWardenCreated(client)
{
	g_bIsWarden[client] = true;
	warden_CreateMessage();
}

// when admin removed warden
public warden_OnWardenRemoved(client)
{
	g_bIsWarden[client] = false;
}

warden_CreateMessage() {
	EmitSoundToAllAny("sourcemod/warden/warden.mp3");
}

warden_RemovedMessage() {
	EmitSoundToAllAny("sourcemod/warden/uwarden.mp3");
	PrintToChatAll(" \x01\x0BVodja zapora je \x02umrl\x01, ce ni izbran nov bo cez 20 sekund freeday");
	PrintToChatAll(" \x01\x0BVodja zapora je \x02umrl\x01, ce ni izbran nov bo cez 20 sekund freeday");
}