#pragma semicolon 1
#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#include <tNoUnlocksPls>
#include <updater>

#define VERSION			"0.4.0"
#define UPDATE_URL    	"http://updates.thrawn.de/tNoUnlocksPls/package.tNoUnlocksPls.announce.cfg"

public Plugin:myinfo = {
	name        = "tNoUnlocksPls - Announce",
	author      = "Thrawn",
	description = "Announces to players when one of their weapons was blocked.",
	version     = VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=140045"
};


public OnPluginStart() {
	CreateConVar("sm_tnounlockspls_announce_version", VERSION, "[TF2] tNoUnlocksPls - Announce", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[]) {
    if (StrEqual(name, "updater"))Updater_AddPlugin(UPDATE_URL);
}

public tNUP_OnAnnounce(iClient, iItemDefinitionIndex, Handle:hTrieItem) {
	new String:sName[255];
	if(tNUP_GetPrettyName(iItemDefinitionIndex, iClient, sName, sizeof(sName))) {
		CPrintToChat(iClient, "Blocked your '{olive}%s{default}'", sName);
	} else {
		CPrintToChat(iClient, "Blocked one of your weapons");
	}


	return;
}