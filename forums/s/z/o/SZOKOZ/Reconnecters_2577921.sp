#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SZOKOZ/EXE_KL"
#define PLUGIN_VERSION "1.00"

#include <cstrike>
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

bool connecting[MAXPLAYERS];
bool enable;
bool aImmunity;

int changeType;

ConVar adminImmunity;
ConVar rememberTeams;
ConVar teamChangeType;

StringMap steamIDs;


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
	adminImmunity = CreateConVar("Admins_Immunity", "0", "0 to disable admin immunity from plugin. 1 to enable.");
	rememberTeams = CreateConVar("Remember_Player_Team", "0", "0 to disable remembering player team. 1 to enable.");
	teamChangeType = CreateConVar("Team_Change_Type", "0", "0 for default method of change. 1 if 0 doesn't work for you.(Experimental)");
	
	AddCommandListener(TeamSwitch, "jointeam");
	
	steamIDs = CreateTrie();
	
	AutoExecConfig();
}

public void OnConfigsExecuted()
{
	enable = GetConVarBool(rememberTeams);
	aImmunity = GetConVarBool(adminImmunity);
	changeType = GetConVarInt(teamChangeType);
	
	ClearTrie(steamIDs);
}

public void OnClientPutInServer(int client)
{	
	connecting[client] = true;
}


public void OnClientDisconnect(int client)
{
	if(!enable)
	{
		return;
	}
	
	if(IsFakeClient(client))
	{
		return;
	}
	
	if (!aImmunity && CheckCommandAccess(client,"", ADMFLAG_GENERIC, true))
	{
		return;
	}
	
	char steamID[32];
	GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID));
	
	SetTrieValue(steamIDs, steamID, GetClientTeam(client));
	
	connecting[client] = false;
}


public Action TeamSwitch(int client, const char[] command, int args)
{
	if(!enable)
	{
		return Plugin_Continue;
	}
	
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	if (!aImmunity && CheckCommandAccess(client,"", ADMFLAG_GENERIC, true))
	{
		return Plugin_Continue;
	}
	
	if (client > 0 && !IsFakeClient(client) && connecting[client])
	{
		char arg[128];
		GetCmdArg(1, arg, 128);
		
		if (StrEqual(arg, "2") || StrEqual(arg,"3"))
		{
			bool idFound;
			char steamID[32];
			int team;
			
			GetClientAuthId(client, AuthId_Engine, steamID, sizeof(steamID));
			idFound = GetTrieValue(steamIDs, steamID, team);
			if (!idFound)
			{
				return Plugin_Continue;
			}
			
			if (team > 1)
			{
				if (changeType == 0)
				{
					ChangeClientTeam(client, team);
				}
				else if (changeType == 1)
				{
					CS_SwitchTeam(client, team);
				}
				
				PrintToChat(client, "You were moved to the team you were previously on.");
				connecting[client] = false;
				
				return Plugin_Handled;
			}
			
		}
		
	}
	
	return Plugin_Continue;
}