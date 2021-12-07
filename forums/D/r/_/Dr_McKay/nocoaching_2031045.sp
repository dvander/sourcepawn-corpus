#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name		= "[TF2] No Coaching",
	author		= "Dr. McKay",
	description	= "Disables coaching",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

public OnMapStart() {
	CreateTimer(10.0, Timer_CheckCoaches, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_CheckCoaches(Handle:timer) {
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i)) {
			continue;
		}
		
		if(GetEntProp(i, Prop_Send, "m_bIsCoaching")) {
			KickClient(i, "Sorry, coaching is disabled on this server");
		}
	}
}