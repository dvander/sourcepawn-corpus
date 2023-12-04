#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define TEAM_1 2
#define TEAM_2 3

// Plugin definitions
public Plugin:myinfo = 
{
	name = "DOD:S Team Balancer",
	author = "AMP, BrutalGoerge, playboycyberclub",
	description = "Keeps DOD:S teams the same size",
	version = PLUGIN_VERSION,
	url = "http://dodsplugins.com/"
};

new Handle:cvarEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	cvarEnabled = CreateConVar("sm_dods_balancer_enable", "1", "Enables the DOD:S Team Balancer plugin");

	// Create the rest of the cvar's
	CreateConVar("sm_dods_balancer_version", PLUGIN_VERSION, "DOD:S Team Balancer Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Finish by setting up iLifeState, hooking player_death and registering the lastman command
	HookEvent("player_death", EventPlayerDeath);
}

// The death event
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If we are disabled - exit
	if(!GetConVarBool(cvarEnabled))
		return;
		
	new victimClient = GetClientOfUserId(GetEventInt(event, "userid"));

	// Admins with A flag are immune
	if(GetUserFlagBits(victimClient) & ADMFLAG_RESERVATION)
		return;
	
	// Count the size of each team
	new team1;
	new team2;
	for (new i = 1; i < MaxClients; i++) {
		if(IsClientInGame(i)){
			if(GetClientTeam(i) == TEAM_1)
				team1++;
			else if(GetClientTeam(i) == TEAM_2)
				team2++;
		}
	}
	
	// Decide if we need to switch and take switch if needed
	if((GetClientTeam(victimClient) == TEAM_1 && (team1 - team2) > 1) || (GetClientTeam(victimClient) == TEAM_2 && (team2 - team1) > 1))
		CreateTimer(1.0, TimerSwitchTeam, victimClient);
}

public GetOtherTeam(team)
{
	if(team == TEAM_2)
		return TEAM_1;
	else
		return TEAM_2;
}

// We switch the teams after the death event 
public Action:TimerSwitchTeam(Handle:timer, any:client)
{
	decl String:clientName[64];
	ChangeClientTeam(client, GetOtherTeam(GetClientTeam(client)));
	GetClientName(client, clientName, sizeof(clientName));
	PrintToChatAll("\x04[TeamBalancer]\x01 %s has been switched to balance the teams.", clientName);		
	return Plugin_Handled;
}