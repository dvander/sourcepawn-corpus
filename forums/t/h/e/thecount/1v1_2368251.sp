#include <sourcemod>

public Plugin:myinfo = {
	name = "1v1",
	author = "The Count",
	description = "Announce 1v1 details.",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public OnPluginStart(){ HookEvent("player_death", Evt_Death); }

public Evt_Death(Handle:event, const String:name[], bool:dontB){
	new ct, lastct, tr, lasttr;
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i) && IsPlayerAlive(i)){
			if(GetClientTeam(i) == 3){
				ct++; lastct = i;
			}else if(GetClientTeam(i) == 2){
				tr++; lasttr = i;
			}
		}
	}
	if(ct == 1 && tr == 1){
		PrintToChatAll("\x01\x04%N\x01(%dHP) vs\x04 %N\x01(%dHP)", lastct, GetClientHealth(lastct), lasttr, GetClientHealth(lasttr));
	}
}