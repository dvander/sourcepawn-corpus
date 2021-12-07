#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.02"

#define TEAM_1 2
#define TEAM_2 3

public Plugin:myinfo = 
{
	name = "ND Balancer",
	author = "AMP",
	description = "Keeps ND teams the same size",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:cvarEnabled = INVALID_HANDLE;
new con_comm_id;
new emp_comm_id;
	
public OnPluginStart()
{
	cvarEnabled = CreateConVar("sm_nd_balancer_enable", "1", "Enables the ND Balancer plugin");
	CreateConVar("sm_nd_balancer_version", PLUGIN_VERSION, "ND Balancer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("promoted_to_commander", EventCatchCommander);
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarEnabled))
		return;

	new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetUserAdmin(victimClient) != INVALID_ADMIN_ID)
		return;
	
	new team1;
	new team2;
	for (new i = 1; i < GetMaxClients(); i++) {
		if(IsClientInGame(i)){
			if(GetClientTeam(i) == TEAM_1)
				team1++;
			else if(GetClientTeam(i) == TEAM_2)
				team2++;
		}
	}

	if((GetClientTeam(victimClient) == TEAM_1 && (team1 - team2) > 1) || (GetClientTeam(victimClient) == TEAM_2 && (team2 - team1) > 1) && victimClient != con_comm_id && victimClient != emp_comm_id)
		CreateTimer(0.2, TimerSwitchTeam, victimClient);
}

public GetOtherTeam(team)
{
	if(team == TEAM_2)
		return TEAM_1;
	else
		return TEAM_2;
}

public Action:TimerSwitchTeam(Handle:timer, any:client)
{
	ChangeClientTeam(client, GetOtherTeam(GetClientTeam(client)));
		
	return Plugin_Handled;
}

public EventCatchCommander(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "teamid");
	if (team == 2) {
		con_comm_id = client;
	} else {
		emp_comm_id = client;
	}
}

