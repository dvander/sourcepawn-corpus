#include <sourcemod>

public Plugin:myinfo = {
	name = "Quick Map Change",
	author = "The Count",
	description = "Allows items to drop then changes map.",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
};

new bool:matchEnd, Handle:itemTimer, Float:interv = 3.5;

public OnPluginStart(){
	matchEnd = false;
	itemTimer = INVALID_HANDLE;
	HookEvent("item_found", Evt_Found);
	HookEvent("cs_win_panel_match", Evt_Match);
}

public OnMapStart(){
	matchEnd = false;
	itemTimer = INVALID_HANDLE;
}

public Evt_Match(Handle:event, const String:name[], bool:dontB){
	matchEnd = true;
	CreateTimer(interv, Timer_MapChange);
}

public Evt_Found(Handle:event, const String:name[], bool:dontB){
	if(matchEnd && itemTimer != INVALID_HANDLE){
		KillTimer(itemTimer);
		CreateTimer(interv, Timer_MapChange);
	}
}

public Action:Timer_MapChange(Handle:timer){
	new String:next[120];GetNextMap(next, sizeof(next));
	ServerCommand("changelevel %s", next);
	return Plugin_Stop;
}