#include <sourcemod>
#include <cstrike>
Handle hTimer = null;

public void OnPluginStart(){
	HookEvent("player_team",Event_PlayerTeam);
	MoveGOTVSpec();
}
public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast){
	if(hTimer == null)
		hTimer = CreateTimer(2.0, Timer_GOTVFIX);
}

public Action Timer_GOTVFIX(Handle timer){
	hTimer = null;
	MoveGOTVSpec();
}

void MoveGOTVSpec(){
	for (int client = 1; client <= MaxClients; client++){
		if(IsClientInGame(client) && IsFakeClient(client) && IsClientSourceTV(client) && GetClientTeam(client) != CS_TEAM_SPECTATOR){
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		}	
	}
}