#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SZOKOZ/EXE_KL"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

ArrayList steamIDs;
ArrayList teamOfClients;

ConVar adminImmunity;
ConVar rememberTeams;


public Plugin myinfo = 
{
	name = "Reconnectors",
	author = PLUGIN_AUTHOR,
	description = "Remembers players who reconnect to the game. Upon reconnect, moves them to their previous team and keeps their previous score.",
	version = PLUGIN_VERSION,
	url = "szokoz.eu"
};


public void OnPluginStart()
{
	adminImmunity = CreateConVar("Admins Immunity", "0", "0 to disable admin immunity from plugin. 1 to enable.");
	rememberTeams = CreateConVar("Remember Player Team", "0", "0 to disable remembering player team. 1 to enable.");
	
	AddCommandListener(TeamSwitch, "jointeam");
	
	steamIDs = CreateArray();
	teamOfClients = CreateArray();
}


public void OnClientPostAdminCheck(int client)
{
	if(GetConVarInt(rememberTeams) == 0)
	{
		return;
	}
	
	if (GetConVarInt(adminImmunity) == 1 && CheckCommandAccess(client,"", ADMFLAG_GENERIC, true))
	{
		return;
	}
	
	int index = FindValueInArray(steamIDs, GetSteamAccountID(client));
	
	if (index != -1)
	{
		char nameOfClient[MAX_NAME_LENGTH];
		char team[24];
		int teamValue;
		
		teamValue = GetArrayCell(teamOfClients, index);
		
		if (teamValue == 2)
		{
			team = "Terrorists";
		}
		else if (teamValue == 3)
		{
			team = "Counter-Terrorists";
		}
		
		ChangeClientTeam(client, teamValue);
		GetClientName(client, nameOfClient, MAX_NAME_LENGTH);
		PrintToServer("%s was auto moved to %s team.", nameOfClient, team);
	}
	
}


public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	PushArrayCell(steamIDs, GetSteamAccountID(client));
	PushArrayCell(teamOfClients, GetClientTeam(client));
	PrintToServer("%d,%d", GetClientFrags(client), GetClientDeaths(client));
	
}


public Action TeamSwitch(int client, const char[] command, int args)
{
	if (client > 0 && !IsFakeClient(client))
	{
		char arg[128];
		GetCmdArg(1, arg, 128);
		
		if (StrEqual(arg, "2") || StrEqual(arg,"3"))
		{
			int index = FindValueInArray(steamIDs, GetSteamAccountID(client));
			if (index == -1)
			{
				return Plugin_Continue;
			}
			
			int team = GetArrayCell(teamOfClients, index);
			
			if (team > 1)
			{
				ChangeClientTeam(client, team);
				
				return Plugin_Stop;
			}
			
		}
		
	}
	
	return Plugin_Continue;
}