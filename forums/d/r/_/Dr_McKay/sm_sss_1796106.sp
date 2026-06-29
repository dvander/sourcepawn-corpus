#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define OUCH_SOUND	"ouch.mp3"
#define IDIOT_SOUND	"idiot.mp3"
#define SLAP_SOUND	false			// false to disable the slap sound in addition to idiot/ouch, true to enable

public Plugin:myinfo = {
	name = "[CS:S/CS:GO] Sounds & Slapping",
	author = "Dr. McKay",
	description = "Requested at https://forums.alliedmods.net/showthread.php?t=195654",
	version = "1.0.0",
	url = "http://www.doctormckay.com"
};

public OnPluginStart() {
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("bomb_abortplant", Event_AbortPlant);
	HookEvent("bomb_abortdefuse", Event_AbortDefuse);
}

public OnMapStart() {
	decl String:buffer[256];
	Format(buffer, sizeof(buffer), "sound/%s", OUCH_SOUND);
	AddFileToDownloadsTable(buffer);
	Format(buffer, sizeof(buffer), "sound/%s", IDIOT_SOUND);
	AddFileToDownloadsTable(buffer);
	PrecacheSound(OUCH_SOUND);
	PrecacheSound(IDIOT_SOUND);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(GetClientTeam(victim) == GetClientTeam(attacker)) {
		EmitSoundToClient(attacker, OUCH_SOUND);
		EmitSoundToClient(victim, OUCH_SOUND);
		SlapPlayer(attacker, 0, SLAP_SOUND);
	}
}

public Event_AbortPlant(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	EmitSoundToAll(IDIOT_SOUND);
	PrintToChatAll("%N aborted planting the bomb!", client);
	SlapPlayer(client, 0, SLAP_SOUND);
	CreateTimer(0.5, Timer_Slap, client);
}

public Event_AbortDefuse(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	EmitSoundToAll(IDIOT_SOUND);
	PrintToChatAll("%N aborted defusing the bomb!", client);
	SlapPlayer(client, 0, SLAP_SOUND);
	CreateTimer(0.5, Timer_Slap, client);
}

public Action:Timer_Slap(Handle:timer, any:client) {
	SlapPlayer(client, 0, SLAP_SOUND);
}