#include <sourcemod>
#include <cstrike>

#define NAME "CSS Late Spawn"
#define VERSION "0.7"

new Handle:g_CVarEnable;
new bool:g_bCanLateSpawn[MAXPLAYERS+1];

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	version = VERSION,
	description = "Spawns late joining players in CSS.",
	url = "http://www.sourcemod.net"
};

public OnPluginStart() {

	CreateConVar("sm_csslatespawn", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_latespawn_enable", "1", "Enable/disable plugin.", _, true, 0.0, true, 1.0);
	AddCommandListener(CmdJoinClass, "joinclass");
	//HookEvent("player_team", EventPlayerTeam);
}

public OnClientConnected(client) {

	g_bCanLateSpawn[client] = true;
}

public Action:CmdJoinClass(client, const String:command[], argc) {

	if (GetConVarBool(g_CVarEnable) && g_bCanLateSpawn[client]) {
		g_bCanLateSpawn[client] = false;
		CreateTimer(1.0, LateSpawnClient, client);
	}
}

public Action:LateSpawnClient(Handle:timer, any:client) {

	if (IsClientInGame(client) && !IsPlayerAlive(client))
		CS_RespawnPlayer(client);
}
/*
public EventPlayerTeam(Handle:event,const String:name[],bool:dontBroadcast) {

	// allow players that have been in spec for a while to late spawn?
}
*/