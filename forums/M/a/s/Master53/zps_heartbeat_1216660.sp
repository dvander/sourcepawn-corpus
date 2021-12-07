#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.1.0"
#undef REQUIRE_EXTENSIONS
new Handle:CV_HEARTBEATENABLE = INVALID_HANDLE;
new Handle:CV_HEARTBEATVERSION = INVALID_HANDLE;
public Plugin:myinfo = {
	name = "ZP:S Heart Beat Sound Emiter",
	author = "Master(D)",
	description = "Plays a heart beat sound when player has low hp.",
	version = PLUGIN_VERSION,
	url = "http://"
}
public OnPluginStart() {
	CV_HEARTBEATENABLE = CreateConVar("sm_heartbeat","1", "enable = 1, disable = 0");
	CV_HEARTBEATVERSION = CreateConVar("sm_heartbeatVersion","1", "Version = 1, Version = 2, use Version 1 if your not using ZPS");
}
public OnMapStart() {
	AddFileToDownloadsTable("sound/heart_normal.wav")
}
public OnAllPluginsLoaded() {

	if (GetExtensionFileStatus("sdkhooks.ext") != 1) {

		SetFailState("SDK Hooks v1.3 or higher is required for ZPS Medic");

	}
	for (new X = 1; X <= MaxClients; X++)
 {

		if (IsClientInGame(X)) {

			SDKHook(X, SDKHook_OnTakeDamage, OnTakeDamage);
		}

	}

}

public OnClientPutInServer(Client) {
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damageType) {
	if(GetClientTeam(Client) == 2) {
		if(GetConVarInt(CV_HEARTBEATENABLE) == 1) {
			if(GetConVarInt(CV_HEARTBEATVERSION) == 1) {
				CreateTimer(1.0, HeartBeatversion1, Client);
			} else 	if(GetConVarInt(CV_HEARTBEATVERSION) == 1) {
				CreateTimer(1.0, HeartBeatversion2, Client);
			}
		}
	}
}
public Action:HeartBeatversion1(Handle:timer, any:Client) {
	if(IsClientConnected(Client) && IsClientInGame(Client)) {
		if(GetClientTeam(Client) == 2) {
			new String:Sound[256] = "heart_normal.wav";
			if(IsPlayerAlive(Client)) {
				if(GetClientHealth(Client) <= 10) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(1.0, HeartBeatversion1, Client);
				} else if(GetClientHealth(Client) <= 20) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(1.4, HeartBeatversion1, Client);
				} else if(GetClientHealth(Client) <= 30) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(1.7, HeartBeatversion1, Client);
				} else if(GetClientHealth(Client) <= 40) {
					ClientCommand(Client, "play \"%s\"", Sound);
					CreateTimer(2.0, HeartBeatversion1, Client);
				} else {
					KillTimer(timer);
				}
			} else {
				KillTimer(timer);
			}
		} else {
			KillTimer(timer);
		}
	} else {
		KillTimer(timer);
	}
}
public Action:HeartBeatversion2(Handle:timer, any:Client) {
	if(IsClientConnected(Client) && IsClientInGame(Client)) {
		if(GetClientTeam(Client) == 2) {
			if(IsPlayerAlive(Client)) {
				if(GetClientHealth(Client) <= 20) {
					new Switch = GetRandomInt(1, 4);
					new String:Sound[256];
					if(Switch == 1) Sound = "infection/jolt-01.wav";
					if(Switch == 2) Sound = "infection/jolt-02.wav";
					if(Switch == 3) Sound = "infection/jolt-03.wav";
					if(Switch == 4) Sound = "infection/jolt-04.wav";
					CreateTimer(3.7, HeartBeatversion2, Client);
				} else {
					KillTimer(timer);
				}
			} else {
				KillTimer(timer);
			}
		} else {
			KillTimer(timer);
		}
	} else {
		KillTimer(timer);
	}
}