#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2] Play as Team 4",
	author = "Xanaguy/MasterMe",
	description = "Play on the hidden Team 4!",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=311185"
};

public void OnPluginStart()
{
	CreateConVar("team4version", PLUGIN_VERSION, "\"Play as Team 4\" plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_team4", ClientToTeam4, ADMFLAG_ROOT, "Switch to Team 4.");
	RegAdminCmd("sm_team3", ClientToTeam3, ADMFLAG_ROOT, "Switch to Team 3.");
	RegAdminCmd("sm_team2", ClientToTeam2, ADMFLAG_ROOT, "Switch to Team 2.");
}

public Action ClientToTeam4(int client, int args)
{
	if (!bIsValidClient(client))
	{
		ReplyToCommand(client, "[PT4] You must be in-game to use this command.");
		return Plugin_Handled;
	}

	ChangeClientTeam(client, 4);

	return Plugin_Handled;
}

public Action ClientToTeam2(int client, int args)
{
	if (!bIsValidClient(client))
	{
		ReplyToCommand(client, "[PT4] You must be in-game to use this command.");
		return Plugin_Handled;
	}

	FindConVar("vs_max_team_switches").SetInt(9999);
	ClientCommand(client, "jointeam 2");
	FindConVar("vs_max_team_switches").SetInt(1);

	return Plugin_Handled;
}

public Action ClientToTeam3(int client, int args)
{
	if (!bIsValidClient(client))
	{
		ReplyToCommand(client, "[PT4] You must be in-game to use this command.");
		return Plugin_Handled;
	}

	FindConVar("vs_max_team_switches").SetInt(9999);
	ClientCommand(client, "jointeam 3");
	FindConVar("vs_max_team_switches").SetInt(1);

	return Plugin_Handled;
}

stock bool bIsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}

	return true;
}