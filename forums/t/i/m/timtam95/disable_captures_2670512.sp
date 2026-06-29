#include <sdktools>

public Plugin:myinfo = {

	name = "disable carts/intel",
	author = "timtam95",
	description = "disable carts/intel",
	version = "1.0",
	url = ""

}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {

	new ent = -1;

	while((ent = FindEntityByClassname(ent, "team_control_point*")) != -1) {
		AcceptEntityInput(ent, "kill");
	}
	while((ent = FindEntityByClassname(ent, "func_capturezone")) != -1) {
		AcceptEntityInput(ent, "kill");
	}

}


public OnPluginStart() {

	HookEvent("teamplay_round_start", RoundStart);

}


