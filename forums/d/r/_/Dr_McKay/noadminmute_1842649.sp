#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.0"

public Plugin:myinfo = {
	name		= "[ANY] No Admin Muting",
	author		= "Dr. McKay",
	description	= "Prevents players from muting admins",
	version		= PLUGIN_VERSION,
	url			= "http://www.doctormckay.com"
}

public OnGameFrame() {
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i)) {
			continue;
		}
		// Prevent i from muting admin j
		for(new j = 1; j <= MaxClients; j++) {
			if(!IsClientInGame(j) || IsFakeClient(j) || i == j || !CheckCommandAccess(j, "NoAdminMute", ADMFLAG_CHAT)) {
				continue;
			}
			SetListenOverride(i, j, Listen_Yes);
		}
	}
}