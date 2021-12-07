#include <sourcemod>
#include <cstrike>
#include <colors>  
#define NAME "CSS Late Spawn"
#define VERSION "0.8"

new Handle:g_CVarEnable;
new bool:g_bReadySpawn[MAXPLAYERS+1];
new bool:g_bSpawned[MAXPLAYERS+1];
new g_userids[MAXPLAYERS+1];
new Handle:g_adtTree;

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	version = VERSION,
	description = "Spawns late joining players in CSS.",
	url = "http://www.sourcemod.net"
};

public OnMapStart() {
	ClearTrie(g_adtTree);
}

public OnPluginStart() {
	g_adtTree = CreateTrie();
	LoadTranslations("latespawn.phrases");
	CreateConVar("sm_latespawn", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_latespawn_enable", "1", "Enable/disable plugin.", _, true, 0.0, true, 1.0);
	AddCommandListener(CmdJoinClass, "joinclass");
	//HookEvent("player_team", EventPlayerTeam);
}

public OnPluginEnd() {
	CloseHandle(g_adtTree);
}

public OnClientPostAdminCheck(client) {
	g_bSpawned[client] = false;
	new String:authid[64];
	GetClientAuthString(client, authid, sizeof(authid));
	new lastspawntime;
	if (!GetTrieValue(g_adtTree, authid, lastspawntime)) {
		SetTrieValue(g_adtTree, authid, 0, true);
		g_bReadySpawn[client] = true;
	} else {
		g_bReadySpawn[client] = false;
	}
	g_userids[client] = GetClientUserId(client);
}

public Action:CmdJoinClass(client, const String:command[], argc) {
	if (GetConVarBool(g_CVarEnable) && (!g_bSpawned[client]) && (GetClientUserId(client) == g_userids[client])) {
		new String:authid[64];
		GetClientAuthString(client, authid, sizeof(authid));
		new lastspawntime;
		new now = GetTime();
		GetTrieValue(g_adtTree, authid, lastspawntime);
		new diff = now - lastspawntime;
		if (diff >= 300) {
			g_bSpawned[client] = true;
			now = now + 1;
			SetTrieValue(g_adtTree, authid, now, true);
			CreateTimer(1.0, LateSpawnClient, client);
		} else {
			new String:msg[256];
			new remained = 300 - diff;
			Format(msg, sizeof(msg), "%T", "[VIP] You Must Wait {number} seconds till next Late Spawn", client, remained);
			CPrintToChat(client, msg);
		}
	}
}

public OnClientDisconnect(client) {
	g_bSpawned[client] = false;
}

public Action:LateSpawnClient(Handle:timer, any:client) {
	if (IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientUserId(client) == g_userids[client])) {
		new String:name[256];
		new String:msg[256];
		GetClientName(client, name, sizeof(name));
		Format(msg, sizeof(msg), "%T", "[VIP] {player} used Late Spawn", LANG_SERVER, name);
		CPrintToChatAll(msg);
		CS_RespawnPlayer(client);
	}
}