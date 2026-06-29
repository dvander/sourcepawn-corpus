#include <sourcemod>
#include <tf2>

public OnPluginStart(){
	HookEvent("player_team", Evt_Team);
}

public Evt_Team(Handle:event, const String:name[], bool:dontB){
	new client = GetClientOfUserId(GetEventInt(event, "userid")), team = GetEventInt(event, "team");
	if(team == 2 || team == 3){
		TF2_AddCondition(client, 82);
	}
}