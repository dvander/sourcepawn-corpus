#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo = {
    name = "Ban IP on ID ban hit",
    author = "Adam Nowack <nowak@xpam.de>",
    description = "Adds a temporary IP ban every time a SteamID banned player tries to connect",
    version = "2",
    url = ""
};

public OnPluginStart() {
    HookEvent("player_disconnect", evPlayerDisconnect, EventHookMode_Pre);
}

public evPlayerDisconnect(Handle:ev, const String:name[], bool:dontBroadcast) {
    decl String:ev_reason[64];
    GetEventString(ev, "reason", ev_reason, sizeof(ev_reason));
    if (StrContains(ev_reason, " is banned", true) != -1) {
	new cid = GetClientOfUserId(GetEventInt(ev, "userid"));
	if (cid > 0) {
	    BanClient(cid, 5, BANFLAG_IP | BANFLAG_NOKICK, "temporary ban for id hit");
	}
    }
}
