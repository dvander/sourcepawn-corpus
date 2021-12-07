#include <sourcemod>
#include <sdktools>
#include <cstrike>
#define PLUGIN_VERSION "1.0.0"

#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATE   1
#define TEAM_T          2
#define TEAM_CT         3

#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_THIRDPERSON 5
#define SPECMODE_FREELOOK 6

new bool:g_bSpecJoinPending[MAXPLAYERS + 1] = {false, ...};

public Plugin:myinfo =
{
	name = "Missing ViewModel Fix",
	author = "ch4os",
	description = "Prevents missing viewmodel when being spectated",
	version = PLUGIN_VERSION,
	url = "www.killerspielplatz.com"
}

public OnPluginStart()
{
	AddCommandListener(JoinTeamCmd, "jointeam");
}

public void OnClientSettingsChanged(client)
{
	if (!g_bSpecJoinPending[client])
		return;

	if(!IsClientInGame(client) || GetClientTeam(client) == TEAM_SPECTATE) {
		g_bSpecJoinPending[client] = false;
		return;
	}

	new String:client_specmode[10];
	GetClientInfo(client, "cl_spec_mode", client_specmode, 9);

	if (StringToInt(client_specmode) > SPECMODE_FIRSTPERSON) {
		g_bSpecJoinPending[client] = false;
		ChangeClientTeam(client, TEAM_SPECTATE);
	}
}

public void OnClientDisconnect(client)
{
	if (g_bSpecJoinPending[client])
		g_bSpecJoinPending[client] = false;
}

public Action:JoinTeamCmd(client, const String:command[], argc)
{ 
	if(!IsClientInGame(client) || IsFakeClient(client) || argc < 1)
		return Plugin_Continue;

	decl String:arg[4];
	GetCmdArg(1, arg, sizeof(arg));

	new toteam = StringToInt(arg);
	new fromteam = GetClientTeam(client);

	if(fromteam != toteam && toteam == TEAM_SPECTATE) {
		new String:client_specmode[10];
		GetClientInfo(client, "cl_spec_mode", client_specmode, 9);

		if (StringToInt(client_specmode) > SPECMODE_FIRSTPERSON)
			return Plugin_Continue;

		g_bSpecJoinPending[client] = true;
		ClientCommand(client, "cl_spec_mode 6");

		return Plugin_Handled;
	}

	return Plugin_Continue;
}