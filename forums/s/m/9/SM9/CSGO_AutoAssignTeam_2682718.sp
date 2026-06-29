#include <cstrike>
#include <sdktools>

ConVar g_ConVar_GraceTime;

bool g_bSpawnAllowed = true;
bool g_bJoinTeamAllowed[MAXPLAYERS +1];

public Plugin myinfo =  {
	name = "[CSGO] Auto Team Assign", 
	author = "SM9();", 
	description = "Assigns a team automatically when player connects and bypasses team menu", 
	version = "1.0.3", 
	url = "https://sm9.dev"
};

public void OnPluginStart() {
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_connect_full", Event_PlayerConnectFull);

	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	
	g_ConVar_GraceTime = FindConVar("mp_join_grace_time");
}

public void OnMapStart() {
	g_bSpawnAllowed = true;
}

Action CommandListener_JoinTeam(int client, const char[] command, int args) {
	return g_bJoinTeamAllowed[client] ? Plugin_Continue : Plugin_Stop;
}

void Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || client > MaxClients || !IsClientConnected(client)) {
		return;
	}

	g_bJoinTeamAllowed[client] = true;

	ClientCommand(client, "jointeam 0 %i", determineTeam());

	int curreantTeam = GetClientTeam(client);
	
	if (!IsPlayerAlive(client) && (curreantTeam == CS_TEAM_T || curreantTeam == CS_TEAM_CT) && (g_bSpawnAllowed || areTeamsEmpty())) {
		CS_RespawnPlayer(client);
	}
}

void Event_RoundStart(Event event, char[] name, bool dontBroadcast) {
	bool warmupActive = isWarmupActive();
	
	if (warmupActive || g_ConVar_GraceTime.BoolValue) {
		g_bSpawnAllowed = true;
	}
	
	if (warmupActive) {
		return;
	}
	
	CreateTimer(g_ConVar_GraceTime.FloatValue, Timer_GraceTimeOver, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundEnd(Event event, char[] name, bool dontBroadcast) {
	g_bSpawnAllowed = false;
}

Action Timer_GraceTimeOver(Handle timer) {
	g_bSpawnAllowed = false;
}

public void OnClientDisconnect(int client) {
	g_bJoinTeamAllowed[client] = false;

	if (!areTeamsEmpty()) {
		return;
	}
	
	g_bSpawnAllowed = true;
}

bool isWarmupActive() {
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

bool areTeamsEmpty() {
	return !(GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT));
}

int determineTeam() {
	int tCount = GetTeamClientCount(CS_TEAM_T);
	int ctCount = GetTeamClientCount(CS_TEAM_CT);
	
	return tCount == ctCount ? GetRandomInt(CS_TEAM_T, CS_TEAM_CT) : tCount < ctCount ? CS_TEAM_T : CS_TEAM_CT;
} 