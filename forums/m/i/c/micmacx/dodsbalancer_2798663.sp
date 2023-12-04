#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define PLUGIN_TAG 			"[DoD Balancer]"

#define TEAM_1 2
#define TEAM_2 3
new encours = 0;

// Plugin definitions
public Plugin:myinfo = 
{
	name = "DOD:S Team Balancer",
	author = "AMP, BrutalGoerge, playboycyberclub, Micmacx",
	description = "Keeps DOD:S teams the same size with bot control an human priority",
	version = PLUGIN_VERSION,
	url = "http://dodsplugins.com/"
};

new Handle:cvarEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("dodsbalancer.phrases");
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
	new team1j;
	new team2j;
	new team1b;
	new team2b;
	for (new i = 1; i < MaxClients; i++) {
		if(IsClientInGame(i)){
			if(GetClientTeam(i) == TEAM_1){
				if(IsFakeClient(i)){
					team1b++;
				}else{
					team1j++;
				}
			}else if(GetClientTeam(i) == TEAM_2){
				if(IsFakeClient(i)){
					team2b++;
				}else{
					team2j++;
				}
			}
		}
	}
	// Decide if we need to switch and take switch if needed
	if(IsFakeClient(victimClient)){
		if((encours == 0 && GetClientTeam(victimClient) == TEAM_1 && (team1j+team1b-team2j-team2b) > 1) || (encours == 0 && GetClientTeam(victimClient) == TEAM_2 && (team2j+team2b-team1j-team1b) > 1 )){
			CreateTimer(1.0, TimerSwitchTeam, victimClient);
			encours++;
		}else if((encours == 0 && GetClientTeam(victimClient) == TEAM_1 && (team1j+team1b-team2j-team2b) == 1 && (team1j > team2j)) || (encours == 0 && GetClientTeam(victimClient) == TEAM_2 && (team2j+team2b-team1j-team1b) == 1 && (team2j > team1j))){
			CreateTimer(1.0, TimerSwitchTeam, victimClient);
			encours++;
		}
	}else{
		if ((encours == 0 && GetClientTeam(victimClient) == TEAM_1 && (team1j - team2j) > 1) || (encours == 0 && GetClientTeam(victimClient) == TEAM_2 && (team2j-team1j) > 1 )){
			CreateTimer(1.0, TimerSwitchTeam, victimClient);
			encours++;
		}
	}
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
	if(IsValidClient(client)){
		decl String:clientName[64];
		ChangeClientTeam(client, GetOtherTeam(GetClientTeam(client)));
		GetClientName(client, clientName, sizeof(clientName));
//		PrintToChatAll("\x04[TeamBalancer]\x01 %s has been switched to balance the teams.", clientName);		
		char message[256];
//		Format(Chattext, sizeof(Chattext), "\x04[Equibrage Automatique]\x01 %s a été changé de team pour équilibrer.", clientName);
		Format(message, sizeof(message), "%T", "message_tb", LANG_SERVER, clientName);
		PrintChatAll(message);
	}
	encours = 0;
	return Plugin_Handled;
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client)){
		return true;
	}else{
		return false;
	}
}

public PrintChatAll(const String:message[]) {
	PrintToChatAll("\x04%s \x01%s",PLUGIN_TAG,message);
}
