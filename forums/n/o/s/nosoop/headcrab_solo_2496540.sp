#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "0.0.0"
public Plugin myinfo = {
	name = "headcrab_solo",
	author = "nosoop",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=294062"
}

public void OnPluginStart() {
	HookEvent("player_team", OnPlayerTeamChange);
}

public void OnPlayerTeamChange(Event event, const char[] name, bool dontBroadcast) {
	// just in case teams aren't switched yet, huzzah blind coding
	RequestFrame(Frame_UpdateHeadcrab);
}

public void Frame_UpdateHeadcrab(any ignored) {
	UpdateHeadcrab();
}

/*
public void OnClientPutInServer(int client) {
	UpdateHeadcrab();
}

public void OnClientDisconnect_Post(int client) {
	UpdateHeadcrab();
}
*/

void UpdateHeadcrab() {
	// int nClients = GetClientCount(false);
	
	// teams 2 and 3, may vary depending on mod
	int nClients = GetTeamClientCount(2) + GetTeamClientCount(3);
	
	if (nClients == 1) {
		int entity = -1;
		
		while ((entity = FindEntityByTargetName(entity, "headcrab_fast7killer")) != -1) {
			AcceptEntityInput(entity, "Enable");
		}
		
		// ServerCommand("ent_fire headcrab_fast7killer enable");
	} else if (nClients > 1) {
		int entity = -1;
		
		while ((entity = FindEntityByTargetName(entity, "headcrab_fast7killer")) != -1) {
			AcceptEntityInput(entity, "Disable");
		}
		
		// ServerCommand("ent_fire headcrab_fast7killer disable");
	}
}

int FindEntityByTargetName(int startEnt = -1, const char[] target,
		const char[] className = "*") {
	char targetbuf[64];
	while ((startEnt = FindEntityByClassname(startEnt, className)) != -1) {
		GetEntPropString(startEnt, Prop_Data, "m_iName", targetbuf, sizeof(targetbuf));
		
		if (StrEqual(target, targetbuf)) {
			return startEnt;
		}
	}
	return startEnt;
}