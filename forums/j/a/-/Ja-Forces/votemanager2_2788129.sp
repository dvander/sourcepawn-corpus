#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.6"
#define CVAR_FLAGS FCVAR_NOTIFY
#define TEAM_SPECTATOR 1
#define TEAM_INFECTED 3
#define VOTE_DELAY 10.0

// cvar handles

ConVar lobbyAccess, difficultyAccess, levelAccess, restartAccess, kickAccess, 
       kickImmunity, sendToLog, vetoAccess, passVoteAccess, voteTimeout, voteNoTimeoutAccess, 
       customAccess, voteNotify, survivalMap, survivalLobby, survivalRestart, tankKickImmunity;

bool inVoteTimeout[MAXPLAYERS + 1], hasVoted[MAXPLAYERS + 1], playerVoted[MAXPLAYERS + 1];

// custom vote variables

bool customVoteInProgress = false;  
char customVote[128] = "";
int customVotesMax, customYesVotes, customNoVotes;

// exploit fix

bool voteInProgress = false;
bool postVoteDelay = false;

public Plugin myinfo =
{
	name            = "L4D Vote Manager 2",
	author          = "Madcap",
	description     = "Control permissions on voting and make voting respect admin levels.",
	version         = PLUGIN_VERSION,
	url             = "https://forums.alliedmods.net/showthread.php?p=758719"
};

public void OnPluginStart()
{
	RegConsoleCmd("custom_vote", CustomVote_Handler);
	RegConsoleCmd("Vote", Vote_Handler);
	RegConsoleCmd("callvote", Callvote_Handler);
	RegConsoleCmd("veto", Veto_Handler);
	RegConsoleCmd("passvote", PassVote_Handler);

	CreateConVar("l4d_votemanager", PLUGIN_VERSION, "Version number for Vote Manager 2 Plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	lobbyAccess         = CreateConVar("l4d_vote_lobby_access",           "",  "Access level needed to start a return to lobby vote", CVAR_FLAGS);
	difficultyAccess    = CreateConVar("l4d_vote_difficulty_access",      "",  "Access level needed to start a change difficulty vote", CVAR_FLAGS);
	levelAccess         = CreateConVar("l4d_vote_level_access",           "",  "Access level needed to start a change level vote", CVAR_FLAGS);
	restartAccess       = CreateConVar("l4d_vote_restart_access",         "",  "Access level needed to start a restart level vote", CVAR_FLAGS);
	kickAccess          = CreateConVar("l4d_vote_kick_access",            "",  "Access level needed to start a kick vote", CVAR_FLAGS);
	kickImmunity        = CreateConVar("l4d_vote_kick_immunity",          "1", "Make votekick respect admin immunity", CVAR_FLAGS, true, 0.0, true, 1.0);
	vetoAccess          = CreateConVar("l4d_vote_veto_access",            "z", "Access level needed to veto a vote", CVAR_FLAGS);
	passVoteAccess      = CreateConVar("l4d_vote_pass_access",            "z", "Access level needed to pass a vote", CVAR_FLAGS);
	voteTimeout         = CreateConVar("l4d_vote_timeout",                "0", "Players must wait (timeout) this many seconds between votes. 0 = no timeout", CVAR_FLAGS, true, 0.0);
	voteNoTimeoutAccess = CreateConVar("l4d_vote_no_timeout_access",      "",  "Access level needed to not have vote timeout.", CVAR_FLAGS);
	sendToLog           = CreateConVar("l4d_vote_log",                    "0", "Log voting data", CVAR_FLAGS, true, 0.0, true, 1.0);
	customAccess        = CreateConVar("l4d_custom_vote_access",          "z", "Access level needed to call custom votes.", CVAR_FLAGS);
	voteNotify          = CreateConVar("l4d_vote_notify_access",          "",  "Who sees certain vote related notices. If blank everyone sees them.", CVAR_FLAGS);
	survivalMap         = CreateConVar("l4d_vote_surv_map_access",        "",  "Access level needed to switch Survival maps.", CVAR_FLAGS);
	survivalRestart     = CreateConVar("l4d_vote_surv_restart_access",    "",  "Access level needed to restart Survival maps.", CVAR_FLAGS);
	survivalLobby       = CreateConVar("l4d_vote_surv_lobby_access",      "",  "Access level needed to return to lobby on Survival maps.", CVAR_FLAGS);
	tankKickImmunity    = CreateConVar("l4d_vote_tank_kick_immunity",     "1", "Make tanks immune to vote kicking.", CVAR_FLAGS, true, 0.0, true, 1.0);
	
	HookEvent("vote_started", EventVoteStart);
	HookEvent("vote_passed", EventVoteEnd);
	HookEvent("vote_failed", EventVoteEnd);
	
	AutoExecConfig(true, "l4d_votemanager");
}

void Notify(int client, char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 3);

	char notify[16];
	GetConVarString(voteNotify, notify, sizeof(notify)); 

	for(int i = 1; i <= MaxClients; i++)
	{
		if  (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && i != client && (strlen(notify) == 0 || GetUserFlagBits(i) & ReadFlagString(notify) != 0))
		{
			PrintToChat(i, buffer);
		}
	}
	
	if (client > 0 && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		PrintToChat(client, buffer);
	}
}

public void EventVoteStart(Event event, const char[] name, bool dontBroadcast)
{
	voteInProgress = true;
	for(int i = 0; i < sizeof(playerVoted); i++)
	{
		playerVoted[i] = false;
	}
}

public void EventVoteEnd(Event event, const char[] name, bool dontBroadcast)
{
	voteInProgress = false;
	postVoteDelay = true;
	CreateTimer(VOTE_DELAY, VoteDelay);		
}

public Action VoteDelay(Handle timer, any client)
{
	postVoteDelay = false;
	return Plugin_Handled;
}

public void OnMapStart()
{
	for(int i = 0; i < sizeof(inVoteTimeout); i++)
	{
		inVoteTimeout[i] = false;
	}
		
	customVoteInProgress = false;
	voteInProgress = false;
	postVoteDelay = false;
}

public void OnClientConnected(int client)
{
	inVoteTimeout[client] = false;
}

void LogVote(int client, char[] format, any ...)
{
	if (GetConVarBool(sendToLog))
	{
		char buffer[512];
		VFormat(buffer, sizeof(buffer), format, 3);
		char name[MAX_NAME_LENGTH] = "";
		char player_authid[32] = "";
			
		if (client == 0)
		{
			name = "Server";
			player_authid = "ServerID";
		}
		else
		{
			GetClientName(client, name, sizeof(name));
			GetClientAuthId(client, AuthId_Steam2, player_authid, sizeof(player_authid));
		}
	
		LogMessage("<%s><%s> %s", name, player_authid, buffer);
	}
}

int hasVoteAccess(int client, char voteName[32])
{
	if (client == 0)
	{
		return true;
	}

	char acclvl[16];
	char gmode[32];
	
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));

	bool survival = false;
	if (strcmp(gmode, "survival", false) == 0)
	{
		survival = true;
	}
		
	if (strcmp(voteName, "ReturnToLobby", false) == 0)
	{
		if (survival)
		{
			GetConVarString(survivalLobby, acclvl, sizeof(acclvl));
		}
		else
		{
			GetConVarString(lobbyAccess, acclvl, sizeof(acclvl));
		}
	}

	else if (strcmp(voteName, "ChangeDifficulty", false) == 0) 
	{
		GetConVarString(difficultyAccess, acclvl, sizeof(acclvl));
	}

	else if (strcmp(voteName, "ChangeMission", false) == 0) 
	{
		GetConVarString(levelAccess, acclvl, sizeof(acclvl));
	}

	else if (strcmp(voteName, "RestartGame", false) == 0) 
	{
		if (survival)
		{
			GetConVarString(survivalRestart, acclvl, sizeof(acclvl));
		}
		else
		{
			GetConVarString(restartAccess, acclvl, sizeof(acclvl));
		}
	}

	else if (strcmp(voteName, "Kick", false) == 0) 
	{
		GetConVarString(kickAccess, acclvl, sizeof(acclvl));
	}

	else if (strcmp(voteName, "Veto", false) == 0) 
	{
		GetConVarString(vetoAccess, acclvl, sizeof(acclvl));
	}

	else if (strcmp(voteName, "PassVote", false) == 0) 
	{
		GetConVarString(passVoteAccess, acclvl, sizeof(acclvl));
	}

	else if (strcmp(voteName, "Custom", false) == 0) 
	{
		GetConVarString(customAccess, acclvl, sizeof(acclvl));
	}

	else if (strcmp(voteName, "ChangeChapter", false) == 0) 
	{
		GetConVarString(survivalMap, acclvl, sizeof(acclvl));	
	}

	else return false;

	if (strlen(acclvl) == 0)
	{
		return true;
	}

	if (GetUserFlagBits(client) & ReadFlagString(acclvl) == 0)
	{
		return false;
	}

	return true;
}

int isInVoteTimeout(int client)
{
	if (GetConVarBool(voteTimeout))
	{
		char acclvl[16];
		GetConVarString(voteNoTimeoutAccess, acclvl, sizeof(acclvl));
	
		if (GetUserFlagBits(client) & ReadFlagString(acclvl) != 0)
		{
			return false;
		}
			
		return inVoteTimeout[client];	
	}
	
	return false;
}

int isValidVote(char voteName[32])
{
	if	((strcmp(voteName, "Kick", false) == 0) ||
		(strcmp(voteName, "ReturnToLobby", false) == 0) ||
		(strcmp(voteName, "ChangeDifficulty", false) == 0) ||
		(strcmp(voteName, "ChangeMission", false) == 0) ||
		(strcmp(voteName, "RestartGame", false) == 0) ||
		(strcmp(voteName, "Custom", false) == 0) ||
		(strcmp(voteName, "ChangeChapter", false) == 0))
	{	
		return true;
	}
		
	return false;	
}

public Action Callvote_Handler(int client, int args)
{
	char voteName[32];
	char initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));
	GetCmdArg(1, voteName, sizeof(voteName));
	
	if (voteInProgress)
	{
		PrintToChat(client, "\x04[VOTE] \x01You cannot start a vote until the current vote ends.");
		LogVote(client, "tried starting a <%s> vote but a vote is in progress.", voteName);
		return Plugin_Handled;
	}

	if (postVoteDelay)
	{
		PrintToChat(client, "\x04[VOTE] \x01Must wait \x03%f seconds \x01between votes.", VOTE_DELAY);
		LogVote(client, "tried starting a <%s> vote but it is too soon since the last vote.", voteName);
		return Plugin_Handled;
	}
	
	if (!isValidVote(voteName))
	{
		PrintToChat(client,"\x04[VOTE] \x01Invalid vote type: \x03%s", voteName);
		LogVote(client, "tried to start an invalid vote type: <%s>", voteName);
		return Plugin_Handled;
	}

	if (isInVoteTimeout(client))
	{
		LogVote(client, "cannot start a <%s> vote.  Reason: Timeout", voteName);
		PrintToChat(client, "\x04[VOTE] \x01You must wait \x03%.1f seconds \x01between votes.", GetConVarFloat(voteTimeout));
		return Plugin_Handled;		
	}

	if (hasVoteAccess(client, voteName))
	{
		inVoteTimeout[client] = true;
		
		float timeout = GetConVarFloat(voteTimeout);
		if (timeout > 0.0)
		{
			CreateTimer(timeout, TimeOutOver, client);
		}

		if (strcmp(voteName, "Kick", false) == 0)
		{
			return Kick_Vote_Logic(client, args);
		}
		
		if (strcmp(voteName, "Custom", false) == 0)
		{
			return Custom_Vote_Logic(client, args);
		}

		LogVote(client, "started a <%s> vote", voteName);
		Notify(client, "\x04[VOTE] \x03%s \x01initiated a \x03%s \x01vote.", initiatorName, voteName);
		return Plugin_Continue;
	}
	else
	{
		LogVote(client, "was prevented from starting a <%s> vote.  Reason: Access", voteName);
		Notify(client, "\x04[VOTE] \x03%s \x01tried to start a \x03%s \x01vote! Access denied", initiatorName, voteName);
		return Plugin_Handled;
	}
}


public Action TimeOutOver(Handle timer, any client)
{
	inVoteTimeout[client] = false;
	return Plugin_Handled;
}

public Action Kick_Vote_Logic(int client, int args)
{
	char initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));

	char arg2[12];
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = GetClientOfUserId(StringToInt(arg2));

	if (target <= 0 || target > MaxClients || !IsClientInGame(target))
	{
		LogVote(client, "was prevented from starting a Kick vote on client <%s>.  Reason: Invalid Target", arg2);
		Notify(client, "\x04[VOTE] \x03%s \x01tried to start a Kick Vote against \x03%s \x01but that is not a valid target.", initiatorName, arg2);
		PrintToChat(client, "\x04[VOTE] \x01If you are trying to call a manual kick vote the format is: 'callvote kick <user id>'");
		return Plugin_Handled;
	}

	char targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));

	if (GetConVarBool(tankKickImmunity) && GetClientTeam(target) == TEAM_INFECTED && IsPlayerAlive(target))
	{
		char model[128];
		GetClientModel(target, model, sizeof(model));
		if (StrContains(model, "hulk", false) > 0)
		{
			LogVote(client, "was prevented from starting a Kick vote on <%s>.  Reason: Tank", targetName);
			Notify(client,"\x04[VOTE] \x03%s \x01tried to start a Kick Vote against \x03%s \x01but tanks cannot be kicked.", initiatorName, targetName);
			return Plugin_Handled;
		}
	}
	
	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		LogVote(client, "was prevented from starting a Kick vote on <%s>.  Reason: Spectator", targetName);
		Notify(client, "\x04[VOTE] \x03%s \x01tried to start a Kick Vote against \x03%s \x01but spectators are not allowed to kick.", initiatorName, targetName);
		return Plugin_Handled;
	}

	if (GetConVarBool(kickImmunity))
	{
		AdminId clientAdminId = GetUserAdmin(client);
		AdminId targetAdminId = GetUserAdmin(target);
	
		if (isAdmin(targetAdminId))
		{
			if (!CanAdminTarget(clientAdminId, targetAdminId))
			{
				LogVote(client, "was prevented from starting a Kick vote on <%s>.  Reason: Target Immunity", targetName);
				Notify(client, "\x04[VOTE] \x03%s \x01tried to start a Kick Vote against \x03%s \x01but failed.", initiatorName, targetName);
				return Plugin_Handled;
			}
		}
	}
	
	LogVote(client, "started a Kick vote on <%s>.", targetName);
	Notify(client, "\x04[VOTE] \x03%s \x01is starting a Kick Vote against \x03%s", initiatorName, targetName);
	return Plugin_Continue;
}

bool isAdmin(AdminId id)
{ 
	return !(id == INVALID_ADMIN_ID);
}

public Action Veto_Handler(int client, int args)
{
	if (!voteInProgress || postVoteDelay) 
	{
		LogVote(client, "vetoed but there is no current vote.");
		if (client != 0)
		{
			PrintToChat(client, "\x04[VOTE] \x01No current vote to veto."); 
		}
		
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		Veto();
	
		LogVote(client, "has vetoed a vote.");
		Notify(0, "\x04[VOTE] \x01The Server has vetoed this vote.");
		return Plugin_Continue;
	}

	char vetoerName[MAX_NAME_LENGTH];	
	GetClientName(client, vetoerName, sizeof(vetoerName));
	
	if (hasVoteAccess(client, "Veto"))
	{	
		Veto();
		
		LogVote(client, "has vetoed a vote.");
		Notify(client, "\x04[VOTE] \x03%s \x01has vetoed this vote.", vetoerName);
		return Plugin_Continue;
	}

	LogVote(client, "failed to veto vote. Reason: Access");
	Notify(client, "\x04[VOTE] \x03%s \x01tried to veto a vote but does not have access.", vetoerName);
	return Plugin_Handled;
}

void Veto()
{
	int count = MaxClients;
	for(int i = 1; i <= count; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
		{
			FakeClientCommandEx(i, "Vote No");
		}
	}
}

public Action PassVote_Handler(int client, int args)
{
	if (!voteInProgress || postVoteDelay) 
	{
		LogVote(client, "passed the vote but there is no current vote.");
		if (client != 0)
		{
			PrintToChat(client, "\x04[VOTE] \x01No current vote to pass."); 
		}
		return Plugin_Handled;
	}
	
	if (client == 0)
	{
		PassVote();
	
		LogVote(client, "has passed a vote.");
		Notify(0, "\x04[VOTE] \x01The Server has passed this vote.");
		return Plugin_Continue;
	}

	char passerName[MAX_NAME_LENGTH];	
	GetClientName(client, passerName, sizeof(passerName));
	
	if (hasVoteAccess(client, "PassVote"))
	{	
		PassVote();
		
		LogVote(client, "has passed a vote.");
		Notify(client, "\x04[VOTE] \x03%s \x01has passed this vote.", passerName);
		return Plugin_Continue;
	}

	LogVote(client, "failed to veto vote. Reason: Access");
	Notify(client, "\x04[VOTE] \x03%s \x01tried to pass a vote but does not have access.", passerName);
	return Plugin_Handled;
}

void PassVote()
{
	int count = MaxClients;
	for(int i = 1; i <= count; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
		{
			FakeClientCommandEx(i, "Vote Yes");
		}
	}
}

public Action CustomVote_Handler(int client, int args)
{
	char initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));
	
	if (!voteInProgress)
	{
		int leng1 = GetCmdArg(1, customVote, sizeof(customVote));
		
		if (leng1 == 0)
		{
			PrintToConsole(client, "Usage: custom_vote \"<question to vote on>\" ");
			return Plugin_Handled;
		}
		
		int i;
		customVotesMax = 0;
		for(i = 1; i < sizeof(hasVoted); i++)
		{
			hasVoted[i] = true;
			
			if (i <= MaxClients && IsClientConnected(i) && !IsFakeClient(i))
			{
				customVotesMax++;
				hasVoted[i] = false;
			}
		}
		
		customNoVotes = 0;
		customYesVotes = 0;

		LogVote(client, "attempting custom vote. Issue: <%s> ", customVote);
		
		FakeClientCommandEx(client, "callvote Custom"); 
	}
	else
	{
		LogVote(client, "tried to start a Custom vote but one is already in progress.");
		Notify(client, "\x04[VOTE] \x03%s \x01tried starting a Custom vote but one is already in progress.", initiatorName);
	}
	
	return Plugin_Handled;
}

public Action Custom_Vote_Logic(int client, int args)
{

	char initiatorName[MAX_NAME_LENGTH];
	GetClientName(client, initiatorName, sizeof(initiatorName));

	if (!customVoteInProgress)
	{
		Event voteEvent = CreateEvent("vote_started");
		voteEvent.SetString("issue", "#L4D_TargetID_Player");
		voteEvent.SetString("param1", customVote);
		voteEvent.SetInt("team", -1);
		voteEvent.SetInt("initiator", GetClientUserId(client));
		voteEvent.Fire();
		
		Event voteChangeEvent = CreateEvent("vote_changed");
		voteChangeEvent.SetInt("yesVotes", 0);
		voteChangeEvent.SetInt("noVotes", 0);
		voteChangeEvent.SetInt("potentialVotes", customVotesMax);
		voteChangeEvent.Fire();

		FakeClientCommandEx(client, "Vote Yes");
		
		LogVote(client, "started a Custom vote.");
		Notify(client, "\x04[VOTE] \x03%s \x01is starting a Custom vote.", initiatorName);
		
		CreateTimer(30.0, EndCustomVote, client);
		
		customVoteInProgress = true;
	}	
	
	return Plugin_Handled;
}

public Action Vote_Handler(int client, int args)
{

	char voterName[MAX_NAME_LENGTH];
	GetClientName(client, voterName, sizeof(voterName));
	
	char vote[8];
	GetCmdArg(1, vote, sizeof(vote));

	if (customVoteInProgress && !hasVoted[client])
	{
		if (strcmp(vote, "Yes", true) == 0)
		{
			customYesVotes++;
		}
		else if (strcmp(vote, "No", true) == 0)
		{
			customNoVotes++;
		}
		
		hasVoted[client] = true;

		Event voteChangeEvent = CreateEvent("vote_changed");
		voteChangeEvent.SetInt("yesVotes", customYesVotes);
		voteChangeEvent.SetInt("noVotes", customNoVotes);
		voteChangeEvent.SetInt("potentialVotes", customVotesMax);
		voteChangeEvent.Fire();

		if ((customYesVotes + customNoVotes) == customVotesMax)
		{
			CreateTimer(2.0, EndCustomVote, client);
		}
	
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action EndCustomVote(Handle timer, any client)
{
	if (customVoteInProgress)
	{
		Event voteEndEvent = CreateEvent("vote_ended");
		voteEndEvent.Fire();
	
		if (customYesVotes > customNoVotes)
		{
			char param1[128];
			Format(param1, sizeof(param1), "Vote succeeds: %s", customVote);
		
			Event votePassEvent = CreateEvent("vote_passed");
			votePassEvent.SetString("details", "#L4D_TargetID_Player");
			votePassEvent.SetString("param1", param1);
			votePassEvent.SetInt("team", -1);
			votePassEvent.Fire();
		
			LogVote(client, "Custom vote passed. Vote: <%s> ", customVote);
		}
		else
		{				
			Event voteFailEvent = CreateEvent("vote_failed");
			voteFailEvent.SetInt("team", 0);
			voteFailEvent.Fire();
		
			LogVote(client, "Custom vote failed. Vote: <%s> ", customVote);
		}
	}

	customVoteInProgress = false;
	
	return Plugin_Handled;
}