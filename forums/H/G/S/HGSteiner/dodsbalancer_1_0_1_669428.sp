/*
dodsBalancer.sp

Description:
	Keeps DOD:S teams the same size

Versions:
	1.0.1	* add max team difference by [BzzB]HGSteiner
	1.0	* Initial Release
		
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

#define TEAM_1 2
#define TEAM_2 3

// Plugin definitions
public Plugin:myinfo = 
{
	name = "DOD:S Balancer",
	author = "AMP",
	description = "Keeps DOD:S teams the same size",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:maxteamdiff = INVALID_HANDLE;

public OnPluginStart()
{
	cvarEnabled = CreateConVar("sm_dods_balancer_enable", "1", "Enables the DOD:S Balancer plugin");
	
	// create max team difference cvar
	maxteamdiff = CreateConVar("sm_dods_balancer_maxteamdiff", "1", "Max team player difference 1-5");

	// Create the rest of the cvar's
	CreateConVar("sm_dods_balancer_version", PLUGIN_VERSION, "DOD:S Balancer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
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

	// Admins are immune
	if(GetUserAdmin(victimClient) != INVALID_ADMIN_ID)
		return;
	
	// Count the size of each team
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


	// check if maxteamdiff (maximum team player difference) is in the limits, if not we set default value 1
	// just be aware that some servers run 32 to 64 slots, so 5 sounds still ok
	if((GetConVarInt(maxteamdiff) < 1) || (GetConVarInt(maxteamdiff) > 5))
		SetConVarInt(maxteamdiff, 1);	
	 
	
	// Decide if we need to switch and take switch if needed
	if((GetClientTeam(victimClient) == TEAM_1 && (team1 - team2) > GetConVarInt(maxteamdiff)) || (GetClientTeam(victimClient) == TEAM_2 && (team2 - team1) > GetConVarInt(maxteamdiff)))
		CreateTimer(0.2, TimerSwitchTeam, victimClient);
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
	ChangeClientTeam(client, GetOtherTeam(GetClientTeam(client)));
		
	return Plugin_Handled;
}