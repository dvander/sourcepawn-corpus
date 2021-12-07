#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <sourcebans>

public Plugin:myinfo = {
	name		= "[TF2] Infinite Healing Fix",
	author		= "Dr. McKay",
	description	= "Fixes a glitch that allows people to have infinite healing/ubercharge",
	version		= "1.0.2",
	url			= "http://www.doctormckay.com"
};

new g_NumSpawns[MAXPLAYERS + 1];
new g_LastSpawn[MAXPLAYERS + 1];
new bool:g_Banning[MAXPLAYERS + 1];
new Handle:g_cvarBanLength;
new Handle:g_cvarBanMessage;
new Handle:g_cvarNumDetections;
new Handle:g_cvarSpamTime;

public OnPluginStart() {
	HookEvent("player_spawn", Event_PlayerSpawn);
	g_cvarBanLength = CreateConVar("infinite_uber_ban_length", "43200", "Time in minutes to ban people who abuse the exploit (0 for permanent, -1 for kick)");
	g_cvarBanMessage = CreateConVar("infinite_uber_message", "Healing exploit detected", "Message to kick/ban people with who abuse the exploit");
	g_cvarNumDetections = CreateConVar("infinite_uber_num_detections", "30", "Number of times a player has to spam the respawn/loadout preset command before triggering");
	g_cvarSpamTime = CreateConVar("infinite_uber_spam_time", "2", "Time in seconds between commands to consider it \"spam\" (lower is less sensitive)");
}

public OnClientConnected(client) {
	g_Banning[client] = false;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_Banning[client] || GetClientTeam(client) <= 1) {
		return; // We're banning them, or they're in Spectate or Unassigned
	}
	
	if(TF2_GetPlayerClass(client) != TFClass_Medic) {
		return; // They're not a medic
	}
	
	if(GetTime() - g_LastSpawn[client] > GetConVarInt(g_cvarSpamTime)) {
		g_NumSpawns[client] = 0;
	}
	
	g_NumSpawns[client]++;
	g_LastSpawn[client] = GetTime();
	
	if(g_NumSpawns[client] >= GetConVarInt(g_cvarNumDetections)) {
		// You dun fucked up
		g_Banning[client] = true;
		ForcePlayerSuicide(client);
		CreateTimer(3.0, Timer_KickOrBan, GetClientUserId(client));
	}
}

public Action:Timer_KickOrBan(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}
	
	new length = GetConVarInt(g_cvarBanLength);
	decl String:message[256];
	GetConVarString(g_cvarBanMessage, message, sizeof(message));
	if(length < 0) {
		KickClient(client, "%s", message);
	} else {
		if(LibraryExists("sourcebans")) {
			SBBanPlayer(0, client, length, message);
		} else {
			BanClient(client, length, BANFLAG_AUTO, message, message, "infinite_uber_fix", 0);
		}
	}
}