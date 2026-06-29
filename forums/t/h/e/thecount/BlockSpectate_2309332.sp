#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Block Spectate",
	author = "The Count",
	description = "Blocks spectating Blue team.",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public Action:OnPlayerRunCmd(client){
	if(!IsClientObserver(client)){ return Plugin_Continue; }
	new viewing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if(viewing > 0 && viewing <= MaxClients && GetClientTeam(viewing) == 3){
		new targ = -1;
		for(new i=1;i<=MaxClients;i++){
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2){
				targ = i;
				break;
			}
		}
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", targ);
	}
	return Plugin_Continue;
}