#include <sourcemod>

ConVar g_Enabled;
ConVar g_ClientLimit;

public Plugin myinfo = 
{
	name = "Votekick Limit",
	author = "Frederik",
	description = "Automatically disable votekick if there are X or less players on the server",
	version = "1.0.1",
	url = "<- URL ->"
}

public void OnPluginStart() {
	g_Enabled = CreateConVar("sm_votekicklimit_enabled", "1", "Enable/disable Votekick Limit (0/1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_ClientLimit = CreateConVar("sm_votekicklimit_limit", "3", "Minimum amount of clients needed to disable vote kick", FCVAR_PLUGIN);
}

public void OnClientPutInServer(int client) {
	UpdateKick();
}

public void OnClientDisconnect_Post(int client) {
	UpdateKick();
}

public void UpdateKick() {
	if (GetConVarInt(g_Enabled)) {
		if (GetClientCount() <= GetConVarInt(g_ClientLimit)) {
			ServerCommand("sv_vote_issue_kick_allowed 0");
		} else if (GetClientCount() > GetConVarInt(g_ClientLimit)) {
			ServerCommand("sv_vote_issue_kick_allowed 1");
		}
	}
}