#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = {
    name = "Config Execute On First Join",
}

public void OnPluginStart() {
	HookEvent("player_connect", OnPlayerConnectEvent);
}

public Action OnPlayerConnectEvent(Event event, const char[] name, bool dontBroadcast) {
	if (!event.GetBool("bot")) {
		// GetClientCount(true) does not count the player that is joining in this event
		int nHumansInGame = GetClientCount(true) - GetFakeClientCount();
		
		if (nHumansInGame == 0) {
			ExecuteConfig("first_player_joined");
		}
	}
}

int GetFakeClientCount() {
	int nFakeClients;
	for (int i = 1; i < MaxClients; i++) {
		if (IsClientConnected(i) && IsFakeClient(i)) {
			nFakeClients++;
		}
	}
	return nFakeClients;
}

void ExecuteConfig(const char[] configFile) {
	// too lazy to check if the config actually exists lol
	ServerCommand("exec %s", configFile);
}