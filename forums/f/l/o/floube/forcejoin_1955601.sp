#include <sourcemod>

#define PLUGIN_VERSION "1.00"
#define TEAM_BLU 3
#define TEAM_RED 2
#define SPECTATOR 1

public Plugin:myinfo = {
	name = "Force Join",
	author = "floube",
	description = "Forces clients to join a specific team on join/death",
	version = PLUGIN_VERSION,
	url = "http://www.styria-games.eu/"
};

new Handle:cvarForceTeamOnJoin = INVALID_HANDLE;
new String:strForceTeamOnJoin[32];

new Handle:cvarForceTeamOnDeath = INVALID_HANDLE;
new String:strForceTeamOnDeath[32];

new Handle:cvarBlockJoinTeam = INVALID_HANDLE;

new String:forcedTeams[MAXPLAYERS + 1][32];

public OnPluginStart() {
	// Hook jointeam command
	RegConsoleCmd("jointeam", OnJoinTeam);

	// Create console variables
	cvarForceTeamOnJoin = CreateConVar("sm_force_team_on_join", "RED");
	cvarForceTeamOnDeath = CreateConVar("sm_force_team_on_death", "SPEC");
	cvarBlockJoinTeam = CreateConVar("sm_block_join_team", "1");

	// Events
	HookEvent("player_death", eventPlayerDeath);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("teamplay_round_start", eventRoundRestart);
}

public OnMapStart() {
	GetConVarString(cvarForceTeamOnJoin, strForceTeamOnJoin, sizeof(strForceTeamOnJoin));
	GetConVarString(cvarForceTeamOnDeath, strForceTeamOnDeath, sizeof(strForceTeamOnDeath));

	for (new i = 1; i <= MaxClients; i++) {
		Format(forcedTeams[i], sizeof(forcedTeams[i]), "UNDEFINED");
	}
}

public resetClient(client) {
	Format(forcedTeams[client], sizeof(forcedTeams[client]), "UNDEFINED");
}

public Action:OnJoinTeam(client, args) {
	if (GetConVarInt(cvarBlockJoinTeam) == 1) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public OnClientPostAdminCheck(client) {
	if (client != 0 && client != -1) {
		resetClient(client);

		if (StrEqual(strForceTeamOnJoin, "BLU")) {
			ChangeClientTeam(client, TEAM_BLU);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "BLU");
		} else if (StrEqual(strForceTeamOnJoin, "RED")) {
			ChangeClientTeam(client, TEAM_RED);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "RED");
		} else if (StrEqual(strForceTeamOnJoin, "SPEC")) {
			ChangeClientTeam(client, SPECTATOR);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "SPEC");
		}
	}
}

public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client != 0 && client != -1 && GetConVarInt(cvarBlockJoinTeam) == 1) {
		if (StrEqual(strForceTeamOnDeath, "BLU")) {
			ChangeClientTeam(client, TEAM_BLU);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "BLU");
		} else if (StrEqual(strForceTeamOnDeath, "RED")) {
			ChangeClientTeam(client, TEAM_RED);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "RED");
		} else if (StrEqual(strForceTeamOnDeath, "SPEC")) {
			ChangeClientTeam(client, SPECTATOR);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "SPEC");
		}
	}

	if (client != 0 && client != -1) {
		if (StrEqual(strForceTeamOnDeath, "SPEC")) {
			if (GetTeamClientCount(TEAM_RED) <= 0) {
				new Handle:event = CreateEvent("teamplay_round_win");
				 
				SetEventInt(event, "team", TEAM_BLU);
				FireEvent(event);
			}

			if (GetTeamClientCount(TEAM_BLU) <= 0) {
				new Handle:event = CreateEvent("teamplay_round_win");
				 
				SetEventInt(event, "team", TEAM_RED);
				FireEvent(event);
			}
		}
	}

	return Plugin_Continue;
}

public Action:eventPlayerSpawn(Handle:event, const String:name2[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client != 0 && client != -1) {
		if (StrEqual(strForceTeamOnJoin, "BLU")) {
			ChangeClientTeam(client, TEAM_BLU);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "BLU");
		} else if (StrEqual(strForceTeamOnJoin, "RED")) {
			ChangeClientTeam(client, TEAM_RED);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "RED");
		} else if (StrEqual(strForceTeamOnJoin, "SPEC")) {
			ChangeClientTeam(client, SPECTATOR);
			Format(forcedTeams[client], sizeof(forcedTeams[client]), "SPEC");
		}
	}

	return Plugin_Continue;
}

public Action:eventRoundRestart(Handle:event, const String:name2[], bool:dontBroadcast) {	
	for (new i = 1; i <= MaxClients; i++) {
		if (StrEqual(forcedTeams[i], "BLU")) {
			ChangeClientTeam(i, TEAM_BLU);
		} else if (StrEqual(forcedTeams[i], "RED")) {
			ChangeClientTeam(i, TEAM_RED);
		} else if (StrEqual(forcedTeams[i], "SPEC")) {
			ChangeClientTeam(i, SPECTATOR);
		}
	}

	return Plugin_Continue;
}