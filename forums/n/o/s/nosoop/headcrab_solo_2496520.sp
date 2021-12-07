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

public void OnClientPutInServer(int client) {
	UpdateHeadcrab();
}

public void OnClientDisconnect_Post(int client) {
	UpdateHeadcrab();
}

void UpdateHeadcrab() {
	int nClients = GetClientCount(false);
	
	if (nClients == 1) {
		/*int entity = -1;
		
		while ((entity = FindEntityByTargetName(entity, "headcrab_fast7killer")) != -1) {
			AcceptEntityInput(entity, "Enable");
		}*/
		
		ServerCommand("ent_fire headcrab_fast7killer enable");
	} else if (nClients > 1) {
		/*int entity = -1;
		
		while ((entity = FindEntityByTargetName(entity, "headcrab_fast7killer")) != -1) {
			AcceptEntityInput(entity, "Disable");
		}*/
		
		ServerCommand("ent_fire headcrab_fast7killer disable");
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