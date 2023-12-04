#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"


#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATE	1
#define TEAM_T			2
#define TEAM_CT			3

#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_THIRDPERSON 5
#define SPECMODE_FREELOOK 6

bool g_bSpecJoinPending[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =
{
	name = "Missing ViewModel Fix",
	author = "ch4os + SHUFEN from POSSESSION.tokyo",
	description = "Prevents missing viewmodel when being spectated",
	version = PLUGIN_VERSION,
	url = "www.killerspielplatz.com"
}

public void OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public void OnClientSettingsChanged(int client)
{
	if (!g_bSpecJoinPending[client])
		return;

	if(!IsClientInGame(client) || GetClientTeam(client) == TEAM_SPECTATE) {
		g_bSpecJoinPending[client] = false;
		return;
	}

	char client_specmode[10];
	GetClientInfo(client, "cl_spec_mode", client_specmode, 9);

	if (StringToInt(client_specmode) > SPECMODE_FIRSTPERSON) {
		g_bSpecJoinPending[client] = false;
		ChangeClientTeam(client, TEAM_SPECTATE);
	}
}

public void OnClientDisconnect(int client)
{
	if (g_bSpecJoinPending[client])
		g_bSpecJoinPending[client] = false;
}

public Action Event_PlayerTeam(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	int oldteam = GetEventInt(event, "oldteam");

	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if(oldteam != team && team == TEAM_SPECTATE) {
		AttemptState(client, true);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsClientInGame(client))
		return Plugin_Continue;

	AttemptState(client, false);

	return Plugin_Continue;
}

void AttemptState(int client, bool spec)
{
	char client_specmode[10];
	GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
	if (StringToInt(client_specmode) <= SPECMODE_FIRSTPERSON) {
		g_bSpecJoinPending[client] = spec;
		ClientCommand(client, "cl_spec_mode 6");
	}
}