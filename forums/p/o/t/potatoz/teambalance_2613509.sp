#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

#define VERSION "1.0" 

ConVar g_cvRatio,
	g_cvPrefix;

public Plugin:myinfo =
{
	name = "teambalance",
	author = "potatoz",
	description = "jailbreak teambalance plugin",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{	
	g_cvRatio = CreateConVar("sm_teambalance_ratio", "3", "How many T's that are required per CT");
	g_cvPrefix = CreateConVar("sm_teambalance_prefix", "[\x06teambalance\x01]", "Will be used as chat prefix for the teambalance plugin");
	AutoExecConfig(true, "teambalance");
	
	HookEvent("round_start", Event_RoundStart);
	AddCommandListener(Command_JoinTeam, "jointeam");	
}

public Action Command_JoinTeam(int client, const char[] command, int args)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	char PREFIX[64];
	g_cvPrefix.GetString(PREFIX, sizeof(PREFIX));
	
	char teamstring[3];
	GetCmdArg(1, teamstring, sizeof(teamstring));
	int target_team = StringToInt(teamstring);
	int current_team = GetClientTeam(client);

	int CTs = 0, 
		Ts = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == CS_TEAM_CT) 
				CTs++;
			else if (GetClientTeam(i) == CS_TEAM_T)
				Ts++;	
		}
	}
	
	CTs++;
	
	if(target_team == current_team)
		return Plugin_Handled;
	else if(target_team == 0)
		return Plugin_Handled;
	else if(target_team == CS_TEAM_CT)
	{
		if(CTs <= 1) return Plugin_Continue;
	
		float fNumPrisonersPerGuard = float(Ts) / float(CTs);
		if(fNumPrisonersPerGuard < (g_cvRatio.IntValue * 1.0))
		{
			PrintToChat(client, " %s There is too many CTs at the moment, running 1:3 ratio", PREFIX);
			return Plugin_Handled;
		}
	
		int i_guardsneeded = RoundToCeil(fNumPrisonersPerGuard - 3.0);
		if(i_guardsneeded < 1)
			i_guardsneeded = 1;

		if(i_guardsneeded > 0)
			return Plugin_Continue;
			
		PrintToChat(client, " %s There is too many CTs at the moment, running 1:3 ratio", PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	int CTs = 0, 
		Ts = 0;	
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == CS_TEAM_CT) 	
				CTs++;
			else if(GetClientTeam(i) == CS_TEAM_T)
				Ts++;
		}
	}
	
	Ts++;
	
	if(CTs <= 1)
	{} else if(CTs <= RoundToFloor(float(Ts) / (g_cvRatio.IntValue * 1.0)))
	{} else SwitchRandomCT();
}

public Action RespawnPlayer(Handle timer, int client)
{
	if(!IsPlayerAlive(client))
		CS_RespawnPlayer(client);
}

public void SwitchRandomCT()
{	
	char PREFIX[64];
	g_cvPrefix.GetString(PREFIX, sizeof(PREFIX));

	int i_numclients,
		i_clients[MAXPLAYERS+1];
	
	for(int i=1; i<=MaxClients; i++)
		if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT)
			i_clients[i_numclients++] = i;
		
	if(i_numclients != 0)
	{
		int randomclient = i_clients[GetRandomInt(0, i_numclients-1)];
		if(IsValidClient(randomclient) && GetClientTeam(randomclient) == CS_TEAM_CT)
		{
			CreateTimer(0.2, RespawnPlayer, randomclient);
			PrintToChatAll(" %s %N has been randomly switched to balance out the teams", PREFIX, randomclient);
			ChangeClientTeam(randomclient, CS_TEAM_T);
		}
	}
	
	int CTs = 0, 
		Ts = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == CS_TEAM_CT) 
				CTs++;
			else if (GetClientTeam(i) == CS_TEAM_T)
				Ts++;	
		}
	}
	
	Ts++;
	
	if(CTs <= 1)
	{} else if(CTs <= RoundToFloor(float(Ts) / (g_cvRatio.IntValue * 1.0)))
	{} else SwitchRandomCT();
}

bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsClientInGame(client));
}
