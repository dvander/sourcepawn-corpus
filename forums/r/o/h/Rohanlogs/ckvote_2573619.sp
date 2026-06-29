#include <sourcemod>
#include <colors>

#pragma newdecls required
#pragma semicolon 1

ConVar g_hVoteExtendTime; 										// Extend time CVar
ConVar g_hMaxVoteExtends; 										// Extend max count CVar

int g_VoteExtends = 0; 											// How many extends have happened in current map
char g_szSteamID[MAXPLAYERS + 1][32];							// Client's steamID
char g_szUsedVoteExtend[MAXPLAYERS+1][32]; 						// SteamID's which triggered extend vote

public Plugin myinfo = 
{
	name = "New Plugin",
	author = "Unknown",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_ve", Command_VoteExtend, ADMFLAG_RESERVATION, "[ckSurf] Vote to extend the map");
	g_hMaxVoteExtends = CreateConVar("ck_max_vote_extends", "3", "The max number of VIP vote extends", FCVAR_NOTIFY, true, 0.0);
	g_hVoteExtendTime = CreateConVar("ck_vote_extend_time", "10.0", "The time in minutes that is added to the remaining map time if a vote extend is successful.", FCVAR_NOTIFY, true, 0.0);
}

public void OnMapStart()
{
	g_VoteExtends = 0;
	
	for (int i = 0; i < MAXPLAYERS+1; i++)
		g_szUsedVoteExtend[i][0] = '\0';
}

public void OnClientPostAdminCheck(int client)
{
	GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true);
}

public Action Command_VoteExtend(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[CK] Please wait until the current vote has finished.");
		return Plugin_Handled;
	}

	if (g_VoteExtends >= GetConVarInt(g_hMaxVoteExtends))
	{
		ReplyToCommand(client, "[CK] There have been too many extends this map.");
		return Plugin_Handled;
	}

	// Here we go through and make sure this user has not already voted. This persists throughout map.
	for (int i = 0; i < g_VoteExtends; i++)
	{
		if (StrEqual(g_szUsedVoteExtend[i], g_szSteamID[client], false))
		{
			ReplyToCommand(client, "[CK] You have already used your vote to extend this map.");
			return Plugin_Handled;
		}
	}
	StartVoteExtend(client);
	return Plugin_Handled;
}


public void StartVoteExtend(int client)
{
	char szPlayerName[MAX_NAME_LENGTH];	
	GetClientName(client, szPlayerName, MAX_NAME_LENGTH);
	CPrintToChatAll("[{olive}CK{default}] Vote to Extend started by {green}%s{default}", szPlayerName);

	g_szUsedVoteExtend[g_VoteExtends] = g_szSteamID[client];	// Add the user's steam ID to the list
	g_VoteExtends++;	// Increment the total number of vote extends so far

	Menu voteExtend = CreateMenu(H_VoteExtend);
	SetVoteResultCallback(voteExtend, H_VoteExtendCallback);
	char szMenuTitle[128];

	char buffer[8];
	IntToString(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)), buffer, sizeof(buffer));

	Format(szMenuTitle, sizeof(szMenuTitle), "Extend map for %s minutes?", buffer);
	SetMenuTitle(voteExtend, szMenuTitle);
	
	AddMenuItem(voteExtend, "", "Yes");
	AddMenuItem(voteExtend, "", "No");
	SetMenuExitButton(voteExtend, false);
	VoteMenuToAll(voteExtend, 20);
}

public void H_VoteExtendCallback(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	int votesYes = 0;
	int votesNo = 0;

	if (item_info[0][VOTEINFO_ITEM_INDEX] == 0) {	// If the winner is Yes
		votesYes = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1) {
			votesNo = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}
	else {	// If the winner is No
		votesNo = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1) {
			votesYes = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}

	if (votesYes > votesNo) // A tie is a failure
	{
		CPrintToChatAll("[{olive}CK{default}] Vote to Extend succeeded - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
		ExtendMapTimeLimit(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)*60));
	} 
	else
	{
		CPrintToChatAll("[{olive}CK{default}] Vote to Extend failed - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
	}
}

public int H_VoteExtend(Menu tMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tMenu);
	}
}

stock bool IsValidClient(int client) 
{ 
    if (client <= 0) 
        return false; 
	
    if (client > MaxClients) 
        return false; 
	
    if ( !IsClientConnected(client) ) 
        return false; 
	
    return IsClientInGame(client); 
} 