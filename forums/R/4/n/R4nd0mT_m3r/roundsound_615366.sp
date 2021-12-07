// File:   roundsound.sp
// Author: TanaToS
// Copyright (C) by TanaToS
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "4.0 SMX"

public Plugin:myinfo = {
	name = "RoundSound SMX",
	author = "TanaToS",
	description = "RoundSound SMX Plugin",
	version = PLUGIN_VERSION,
	url = "http://addons.eventscripts.com/addons/view/RoundSound--v3--TanaToS"
};

public OnPluginStart() {
	HookEvent("round_end", EventRoundEnd, EventHookMode_Post);
	AddFileToDownloadsTable("sound/misc/ctwinnar2.wav");
	AddFileToDownloadsTable("sound/misc/ctwinnar3.wav");
	AddFileToDownloadsTable("sound/misc/ctwinnar4.wav");
	AddFileToDownloadsTable("sound/misc/twinnar2.wav");
	AddFileToDownloadsTable("sound/misc/twinnar3.wav");
	AddFileToDownloadsTable("sound/misc/twinnar.wav");
}

public OnMapStart() {
	AddFileToDownloadsTable("sound/misc/ctwinnar2.wav");
	AddFileToDownloadsTable("sound/misc/ctwinnar3.wav");
	AddFileToDownloadsTable("sound/misc/ctwinnar4.wav");
	AddFileToDownloadsTable("sound/misc/twinnar2.wav");
	AddFileToDownloadsTable("sound/misc/twinnar3.wav");
	AddFileToDownloadsTable("sound/misc/twinnar.wav");
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new winner = GetEventInt(event, "winner");
	new random = GetRandomInt(1, 3);
	if(winner == 2) {
		for(new userid = 1; userid <= GetMaxClients(); userid++) {
			if(IsClientInGame(userid) && !IsFakeClient(userid)) {
				if(random == 1) {
					ClientCommand(userid, "play misc/twinnar2");
				} if(random == 2) {
					ClientCommand(userid, "play misc/twinnar3");
				} if(random == 3) {
					ClientCommand(userid, "play misc/twinnar"); }
			}
		}
	} else if(winner == 3) {
		for(new userid = 1; userid <= GetMaxClients(); userid++) {
			if(IsClientInGame(userid) && !IsFakeClient(userid)) {
				if(random == 1) {
					ClientCommand(userid, "play misc/ctwinnar2");
				} if(random == 2) {
					ClientCommand(userid, "play misc/ctwinnar3");
				} if(random == 3) {
					ClientCommand(userid, "play misc/ctwinnar4"); }
			}
		}
	}
}