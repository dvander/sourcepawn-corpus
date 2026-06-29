#pragma semicolon 1

#define ADMIN_FLAG		ADMFLAG_GENERIC //Change this to anything you want for admin flag


#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Team Scramble with score saving",
	author = PLUGIN_AUTHOR,
	description = "Scramble teams without lose score.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=298915"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_scramble", Command_Scramble, ADMIN_FLAG);
}

public Action Command_Scramble(int client, int args)
{
	int iTotalPlayers = GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT);
	
	if (iTotalPlayers < 2 || GetTeamClientCount(CS_TEAM_T) == 0 || GetTeamClientCount(CS_TEAM_CT) == 0) 
	{
		ReplyToCommand(client, "[SM] Not enough players on teams to scramble.");
		return Plugin_Handled;
	}
	
	int iPlayersToMove = GetRandomInt(RoundToCeil(float(iTotalPlayers / 2)), iTotalPlayers - 1);
	
	if (iTotalPlayers == 2) 
		iPlayersToMove = 2;
	
	for (int i = 1; i <= iPlayersToMove; i++)
	{
		if(i % 2 == 0)
		{
			int iTarget = GetRandomPlayer(CS_TEAM_CT);
			if(iTarget != -1) CS_SwitchTeam(iTarget, CS_TEAM_T);
		}
		else
		{
			int iTarget = GetRandomPlayer(CS_TEAM_T);
			if(iTarget != -1) CS_SwitchTeam(iTarget, CS_TEAM_CT);
		}
	}
	ReplyToCommand(client, "[SM] Teams have been scrambled successfully. Ending round...");
	CS_TerminateRound(0.0, CSRoundEnd_Draw);
	return Plugin_Handled;
}

stock int GetRandomPlayer(int team) 
{ 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i) && GetClientTeam(i) == team)
        { 
            clients[clientCount++] = i; 
        } 
    } 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; 
}
