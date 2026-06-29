#include <sourcemod>
#include <sdktools>

#define VERSION "1.2.0"
#define L4D2_TANK_CLASS_NUM 8
#define MAX_VOTING_CLIENTS 20
#define NUM_SWITCHES_BEFORE_TIMER 2
#define FAILED_SWITCH_WAIT_TIME 300.0
#define ANNOUNCEMENT_DELAY 50.0
#define VOTE_TESTING 0
#define VERBOSE_ADMIN_MESSAGES 0
#define ADMINS_SKIP_VOTING 1

#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define L4D_TEAM_SURVIVORS 2
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SPECTATE 1

enum TeamType
{
	Spectator = 1,
	Survivor = 2,
	Infected = 3
};

enum VoteStatus
{
	Abstain = 0,
	Allow = 1,
	Deny = 2
};

enum VoteType
{
	Switch = 0,
	Swap = 1
};

public Plugin:myinfo =
{
	name = "L4D2 Team Switch Vote",
	author = "AbyssStaresBack",
	description = "Makes teams vote to allow a player to switch to their team.",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=148361"
};

// CVARS
new Handle:cvarVoteTimeout = INVALID_HANDLE;
new Handle:cvarConnWait = INVALID_HANDLE;
new Handle:cvarDelayedSwitchTimeout = INVALID_HANDLE;
new Handle:cvarAnnounce = INVALID_HANDLE;
new Handle:cvarGamemode = INVALID_HANDLE;

// SDK Call to take over a bot
new Handle:fTOB = INVALID_HANDLE;

// SDK Call to spectate on a bot
new Handle:fSHS = INVALID_HANDLE;

new Handle:gConf = INVALID_HANDLE;

new Handle:votingPanel = INVALID_HANDLE;

// Displayed to admins that are on the voting team
new Handle:adminVotingPanel = INVALID_HANDLE;

// Displayed to admins that are not on the voting team
new Handle:adminNonVotingPanel = INVALID_HANDLE;

// Used to close out the voting panels once a vote is finished
new Handle:voteCompletePanel = INVALID_HANDLE;

new bool:voteInProgress;
new VoteType:currentVoteType;

// Indicate whether or not clientRequestingSwitch should be allowed to switch immediately 
// upon his/her next switch request. Used for when a client's vote is approved while he/she
// is spawned as infected.
new bool:allowDelayedSwitch;
new Handle:delayedSwitchTimer = INVALID_HANDLE;

new bool:clientIsValidVoter[MAX_VOTING_CLIENTS];
new VoteStatus:clientVote[MAX_VOTING_CLIENTS];

#if VOTE_TESTING
new TeamType:fakeClientTeam[MAX_VOTING_CLIENTS];
#endif

new failedSwitches[MAX_VOTING_CLIENTS];
new Handle:failedSwitchTimers[MAX_VOTING_CLIENTS];

new Handle:announcementTimers[MAX_VOTING_CLIENTS];

new PropGhost;

new clientRequestingSwitch;
new clientToSwapWith;
new TeamType:requestedTeam

new Handle:voteTimer = INVALID_HANDLE;
new Handle:waitForConnectionsTimer = INVALID_HANDLE;

new bool:waitingForConnections = true;

public OnMapStart()
{
	waitingForConnections = true;
	waitForConnectionsTimer = CreateTimer(GetConVarFloat(cvarConnWait), handleWaitForConnections);
}

public OnMapEnd()
{
	if (voteInProgress)
	{
		if (voteTimer != INVALID_HANDLE)
		{
			KillTimer(voteTimer);
			voteTimer = INVALID_HANDLE;
		}
		voteInProgress = false;
	}

	// In case the map ends before the connection timer runs out (possible, but unlikely)
	if (waitForConnectionsTimer != INVALID_HANDLE)
	{
		KillTimer(waitForConnectionsTimer);
		waitForConnectionsTimer = INVALID_HANDLE;
	}

	disableDelayedSwitch();
	resetVotingClients();
}

//
// Voting Client Handling
//

bool:addVotingClient(id)
{
	if (id <= 0 || id >= MAX_VOTING_CLIENTS)
	{
		return false;
	}

	clientIsValidVoter[id] = true;
	clientVote[id] = VoteStatus:Abstain;

	return true;
}

removeVotingClient(id)
{
	if (id <= 0 || id >= MAX_VOTING_CLIENTS)
	{
		return;
	}

	clientIsValidVoter[id] = false;
	clientVote[id] = VoteStatus:Abstain;
}

resetVotingClients()
{
	new i;
	for (i = 0; i < MAX_VOTING_CLIENTS; i++)
	{
		clientIsValidVoter[i] = false;
		clientVote[i] = VoteStatus:Abstain;
	}
}

//
// Vote handling
//

notifyAllAboutVote()
{
	decl String:requestingClientName[MAX_NAME_LENGTH];
	new bool:requestingClientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, requestingClientName, MAX_NAME_LENGTH);
	decl String:swapWithClientName[MAX_NAME_LENGTH];
	new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);

	decl String:message[96];
	
	if (requestingClientNameRetrieved)
	{
		if (swapWithClientNameRetrieved)
		{
			Format(message, 96, "%s\nwants to swap teams with\n%s", requestingClientName, swapWithClientName);
		}
		else
		{
			Format(message, 96, "%s\nwants to swap teams", requestingClientName);
		}
	}
	else
	{
		if (swapWithClientNameRetrieved)
		{
			Format(message, 96, "A player wants to swap with\n%s", swapWithClientName);
		}
		else
		{
			message = "A player wants to swap teams";
		}
	}

	SetPanelTitle(votingPanel, message);
	SetPanelTitle(adminVotingPanel, message);

	new i;
	new AdminId:clientAdminId;

	resetVotingClients();
	voteInProgress = true;
	currentVoteType = VoteType:Swap;

	voteTimer = CreateTimer(GetConVarFloat(cvarVoteTimeout), handleVoteTimeout);

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			addVotingClient(i);

			if (i == clientRequestingSwitch)
			{
				// The person requesting the vote automatically votes to allow
				clientVote[i] = VoteStatus:Allow;
				continue;
			}

			clientAdminId = GetUserAdmin(i);

			if (requestingClientNameRetrieved)
			{
				PrintHintText(i, "Player '%s' wants to swap teams.\nVote to allow/deny on the left of your screen.", requestingClientName);
				if (clientAdminId == INVALID_ADMIN_ID)
				{
					SendPanelToClient(votingPanel, i, VotingPanelHandler, GetConVarInt(cvarVoteTimeout));
				}
				else
				{
					SendPanelToClient(adminVotingPanel, i, AdminVotingPanelHandler, GetConVarInt(cvarVoteTimeout));
				}
			}
			else
			{
				PrintHintText(i, "A player wants to swap teams.\nVote to allow/deny on the left of your screen.");

				if (clientAdminId == INVALID_ADMIN_ID)
				{
					SendPanelToClient(votingPanel, i, VotingPanelHandler, GetConVarInt(cvarVoteTimeout));
				}
				else
				{
					SendPanelToClient(adminVotingPanel, i, AdminVotingPanelHandler, GetConVarInt(cvarVoteTimeout));
				}
			}
		}
	}
}

notifyTeamAboutVote()
{
	decl String:clientName[MAX_NAME_LENGTH];
	new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);

	if (clientNameRetrieved)
	{
		decl String:message[64];
		Format(message, 64, "%s\nwants to join your team", clientName);
		SetPanelTitle(votingPanel, message);
		SetPanelTitle(adminVotingPanel, message);
		Format(message, 64, "%s\nwants to switch teams", clientName);
		SetPanelTitle(adminNonVotingPanel, message);
	}
	else
	{
		SetPanelTitle(votingPanel, "A player wants to join your team");
		SetPanelTitle(adminVotingPanel, "A player wants to join your team");
		SetPanelTitle(adminNonVotingPanel, "A player wants to switch teams");
	}

	new i;
	new TeamType:team;
	new AdminId:clientAdminId;

	resetVotingClients();
	voteInProgress = true;
	currentVoteType = VoteType:Switch;

	voteTimer = CreateTimer(GetConVarFloat(cvarVoteTimeout), handleVoteTimeout);

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			team = TeamType:GetClientTeam(i);
			clientAdminId = GetUserAdmin(i);

			if (team == requestedTeam)
			{
				addVotingClient(i);
				if (clientNameRetrieved)
				{
					//PrintToChat(i, "\x01[SM] Player \x04%s\x01 wants to switch to your team. In chat, enter \x04!allowswitch\x01 to vote to allow this, or \x04!denyswitch\x01 to vote to deny. (Deny is selected by default.)", clientName);
					PrintHintText(i, "Player '%s' wants to join your team.\nVote to allow/deny on the left of your screen.", clientName);
					if (clientAdminId == INVALID_ADMIN_ID)
					{
						SendPanelToClient(votingPanel, i, VotingPanelHandler, GetConVarInt(cvarVoteTimeout));
					}
					else
					{
						SendPanelToClient(adminVotingPanel, i, AdminVotingPanelHandler, GetConVarInt(cvarVoteTimeout));
					}
				}
				else
				{
					//PrintToChat(i, "\x01[SM] Player <unnamed> wants to switch to your team. In chat, enter \x04!allowswitch\x01 to vote to allow this, or \x04!denyswitch\x01 to vote to deny. (Deny is selected by default.)");
					PrintHintText(i, "A player wants to join your team.\nVote to allow/deny on the left of your screen.");

					if (clientAdminId == INVALID_ADMIN_ID)
					{
						SendPanelToClient(votingPanel, i, VotingPanelHandler, GetConVarInt(cvarVoteTimeout));
					}
					else
					{
						SendPanelToClient(adminVotingPanel, i, AdminVotingPanelHandler, GetConVarInt(cvarVoteTimeout));
					}
				}
			}
			else
			{
				if (clientAdminId != INVALID_ADMIN_ID)
				{
					SendPanelToClient(adminNonVotingPanel, i, AdminNonVotingPanelHandler, GetConVarInt(cvarVoteTimeout));
				}
			}
		}
	}
}

public Action:handleWaitForConnections(Handle:timer)
{
	waitForConnectionsTimer = INVALID_HANDLE;
	waitingForConnections = false;
}

// Called when a vote times out
public Action:handleVoteTimeout(Handle:timer)
{
	voteTimer = INVALID_HANDLE;

	decl String:clientName[MAX_NAME_LENGTH];
	new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);

	// Get vote status, and count non-voters (abstain) as deny
	new VoteStatus:currentVoteStatus = getVoteStatus(true);
	
	if (currentVoteStatus == VoteStatus:Allow)
	{
		if (currentVoteType == VoteType:Switch)
		{
			handleSwitchAllowed(clientNameRetrieved, clientName);
		}
		else if (currentVoteType == VoteType:Swap)
		{
			decl String:swapWithClientName[MAX_NAME_LENGTH];
			new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);
			handleSwapAllowed(clientNameRetrieved, clientName, swapWithClientNameRetrieved, swapWithClientName);
		}

		voteInProgress = false;
	}
	else
	{
		if (currentVoteType == VoteType:Switch)
		{
			if (clientNameRetrieved)
			{
				PrintToChatAll("\x01[SM] Player \x04%s\x01 was not allowed to switch teams.", clientName);
			}
			else
			{
				PrintToChatAll("\x01[SM] Player <unnamed> was not allowed to switch teams.");
			}
		}
		else if (currentVoteType == VoteType:Swap)
		{
			decl String:swapWithClientName[MAX_NAME_LENGTH];
			new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);
			
			if (clientNameRetrieved)
			{
				if (swapWithClientNameRetrieved)
				{
					PrintToChatAll("\x01[SM] \x04%s\x01 was not allowed to swap teams with \x04%s\x01.", clientName, swapWithClientName);
				}
				else
				{
					PrintToChatAll("\x01[SM] \x04%s\x01 was not allowed to swap teams with <unnamed>.", clientName);
				}
			}
			else
			{
				if (swapWithClientNameRetrieved)
				{
					PrintToChatAll("\x01[SM] <unnamed> was not allowed to swap teams with \x04%s\x01.", swapWithClientName);
				}
				else
				{
					PrintToChatAll("\x01[SM] <unnamed> was not allowed to swap teams with <unnamed>.");
				}
			}
		}
		

		incrementFailedSwitches(clientRequestingSwitch);

		voteInProgress = false;
	}
}

// Called when a vote passes to handle checking if a player is safe to switch (not tank, not spawned as infected, etc)
handleSwitchAllowed(bool:clientNameRetrieved, String:clientName[])
{
	resetFailedSwitches(clientRequestingSwitch);

	if (doesClientHaveTank(clientRequestingSwitch))
	{
		if (!allowDelayedSwitch)
		{
			// Only start the delayed switch timer if it isn't already running
			enableDelayedSwitch();
		}
		//PrintToChat(clientRequestingSwitch, "[SM] You may not switch teams while in control of the tank. Try again once you are waiting to spawn.");
		PrintHintText(clientRequestingSwitch, "Your team cannot be changed while you are in control of the tank.\nTry again once you are waiting to spawn.");
	}
	else if (TeamType:GetClientTeam(clientRequestingSwitch) == TeamType:Infected && !isClientDeadOrGhost(clientRequestingSwitch))
	{
		if (!allowDelayedSwitch)
		{
			// Only start the delayed switch timer if it isn't already running
			enableDelayedSwitch();
		}
		//PrintToChat(clientRequestingSwitch, "[SM] You may not switch teams while spawned. Try again once you are waiting to spawn.");
		PrintHintText(clientRequestingSwitch, "Your team cannot be changed while you are spawned.\nTry again once you are waiting to spawn.");
	}
	else
	{
		if (clientNameRetrieved)
		{
			PrintToChatAll("\x01[SM] Player \x04%s\x01 was allowed to switch teams.", clientName);
		}
		else
		{
			PrintToChatAll("\x01[SM] Player <unnamed> was allowed to switch teams.");
		}

		ChangePlayerTeam(clientRequestingSwitch, _:requestedTeam);

		// The player was allowed to switch, so shut down the delayed switch timer
		disableDelayedSwitch();
	}
}

handleSwapAllowed(bool:requestingClientNameRetrieved, String:requestingClientName[], bool:swapWithClientNameRetrieved, String:swapWithClientName[])
{
	resetFailedSwitches(clientRequestingSwitch);

	new clientOnSurvivorTeam;
	new clientOnInfectedTeam;

	if (TeamType:GetClientTeam(clientRequestingSwitch) == TeamType:Survivor)
	{
		clientOnSurvivorTeam = clientRequestingSwitch;
		if (TeamType:GetClientTeam(clientToSwapWith) == TeamType:Infected)
		{
			clientOnInfectedTeam = clientToSwapWith;
		}
		else
		{
			PrintToChatAll("[SM] Players were unable to be swapped, because they are not on opposing teams (one on Survivor, one on Infected).");
			return;
		}
	}
	else if (TeamType:GetClientTeam(clientRequestingSwitch) == TeamType:Infected)
	{
		clientOnInfectedTeam = clientRequestingSwitch;
		if (TeamType:GetClientTeam(clientToSwapWith) == TeamType:Survivor)
		{
			clientOnSurvivorTeam = clientToSwapWith;
		}
		else
		{
			PrintToChatAll("[SM] Players were unable to be swapped, because they are not on opposing teams (one on Survivor, one on Infected).");
			return;
		}
	}
	else
	{
		PrintToChatAll("[SM] Players were unable to be swapped, because they are not on opposing teams (one on Survivor, one on Infected).");
		return;
	}

	if (doesClientHaveTank(clientOnInfectedTeam))
	{
		if (!allowDelayedSwitch)
		{
			// Only start the delayed switch timer if it isn't already running
			enableDelayedSwitch();
		}
		PrintHintText(clientOnInfectedTeam, "Your team cannot be changed while you are in control of the tank.\nEnter '!voteswap' in chat once you are waiting to spawn.");
		PrintHintText(clientOnSurvivorTeam, "The vote passed, but the infected player is currently spawned.\nHe/she must enter '!voteswap' in chat once he/she is waiting to spawn.");
	}
	else if (!isClientDeadOrGhost(clientOnInfectedTeam))
	{
		if (!allowDelayedSwitch)
		{
			// Only start the delayed switch timer if it isn't already running
			enableDelayedSwitch();
		}
		PrintHintText(clientRequestingSwitch, "Your team cannot be changed while you are spawned.\nEnter '!voteswap' in chat once you are waiting to spawn.");
		PrintHintText(clientOnSurvivorTeam, "The vote passed, but the infected player is currently spawned.\nHe/she must enter '!voteswap' in chat once he/she is waiting to spawn.");
	}
	else
	{
		if (requestingClientNameRetrieved)
		{
			if (swapWithClientNameRetrieved)
			{
				PrintToChatAll("\x01[SM] \x04%s\x01 was allowed to swap teams with \x04%s\x01.", requestingClientName, swapWithClientName);
			}
			else
			{
				PrintToChatAll("\x01[SM] \x04%s\x01 was allowed to swap teams with <unnamed>.", requestingClientName);
			}
		}
		else
		{
			if (swapWithClientNameRetrieved)
			{
				PrintToChatAll("\x01[SM] <unnamed> was allowed to swap teams with \x04%s\x01.", swapWithClientName);
			}
			else
			{
				PrintToChatAll("\x01[SM] <unnamed> was allowed to swap teams with <unnamed>.");
			}
		}

		// Move infected player to spectator
		ChangePlayerTeam(clientOnInfectedTeam, L4D_TEAM_SPECTATE);
		// Move survivor player to infected
		ChangePlayerTeam(clientOnSurvivorTeam, L4D_TEAM_INFECTED);
		// Move infected player (now spectator) to survivors
		ChangePlayerTeam(clientOnInfectedTeam, L4D_TEAM_SURVIVORS);

		// The players was allowed to swap, so shut down the delayed switch timer
		disableDelayedSwitch();
	}
}

incrementFailedSwitches(client)
{
	if (client <= 0 || client >= MAX_VOTING_CLIENTS)
	{
		return;
	}

	failedSwitches[client] += 1;
	if (failedSwitches[client] == NUM_SWITCHES_BEFORE_TIMER)
	{
		failedSwitchTimers[client] = CreateTimer(FAILED_SWITCH_WAIT_TIME, handleFailedSwitchTimeout, client);
	}
}

resetFailedSwitches(client)
{
	if (client <= 0 || client >= MAX_VOTING_CLIENTS)
	{
		return;
	}

	failedSwitches[client] = 0;
	if (failedSwitchTimers[client] != INVALID_HANDLE)
	{
		KillTimer(failedSwitchTimers[client]);
		failedSwitchTimers[client] = INVALID_HANDLE;
	}
}

public Action:handleFailedSwitchTimeout(Handle:timer, any:client)
{
	timer = INVALID_HANDLE;

	if (client > 0 && client < MAX_VOTING_CLIENTS)
	{
		// Normally, a client gets NUM_SWITCHES_BEFORE_TIMER failed votes before having to wait a period of time.
		// Once they have been forced to wait, they only need 1 failed vote to have to wait again.
		failedSwitches[client] = NUM_SWITCHES_BEFORE_TIMER - 1;
		
		// This is probably redundant
		failedSwitchTimers[client] = INVALID_HANDLE;
	}
}

// Check if a player is in control of the tank, because if a player is switched while controlling the tank, the tank dies
// TODO: Fix this issue so that tank control is simply passed on
bool:doesClientHaveTank(id)
{
	// Invalid client
	if (id <= 0 || id > MaxClients)
	{
		return false;
	}

	// Check if client is in game, alive, on the infected team, and playing the tank
	return IsClientInGame(id) && IsPlayerAlive(id) && (TeamType:GetClientTeam(id) == TeamType:Infected) && (GetEntProp(id, Prop_Send, "m_zombieClass") == L4D2_TANK_CLASS_NUM);
}

// Checks if a player is in ghost mode or dead (which is required for switching from the infected side)
bool:isClientDeadOrGhost(id)
{
	if (id == 0) return false;
	return (GetEntData(id, PropGhost, 1) == 1) || !IsPlayerAlive(id);
}

#if VOTE_TESTING
// Used when testing voting (assumes tester is client 1)
TeamType:GetClientTeam_Fake(client)
{
	if (client == 1)
	{
		return TeamType:GetClientTeam(client);
	}
	else
	{
		return fakeClientTeam[client];
	}
}
#endif

// Check the status of the current vote; returning Abstain means that the result is not determined yet
VoteStatus:getVoteStatus(bool:countAbstainAsDeny)
{
	new i, votingClients, votesToAllow, votesToDeny;
	new votingClientsTeamA, votingClientsTeamB, votesToAllowTeamA, votesToAllowTeamB, votesToDenyTeamA, votesToDenyTeamB;
	new TeamType:team;
#if VOTE_TESTING
	for (i = 1; i < MAX_VOTING_CLIENTS; i++)
#else
	for (i = 1; i <= MaxClients; i++)
#endif
	{
		if (clientIsValidVoter[i])
		{
			votingClients++;
#if VOTE_TESTING
			team = TeamType:GetClientTeam_Fake(i);
#else
			team = TeamType:GetClientTeam(i);
#endif

			if (team == TeamType:Survivor)
			{
				votingClientsTeamA++;
			}
			else if (team == TeamType:Infected)
			{
				votingClientsTeamB++;
			}

			if (clientVote[i] == VoteStatus:Allow)
			{
				if (team == TeamType:Survivor)
				{
					votesToAllowTeamA++;
				}
				else if (team == TeamType:Infected)
				{
					votesToAllowTeamB++;
				}
				votesToAllow++;
			}
			else if (clientVote[i] == VoteStatus:Deny)
			{
				if (team == TeamType:Survivor)
				{
					votesToDenyTeamA++;
				}
				else if (team == TeamType:Infected)
				{
					votesToDenyTeamB++;
				}
				votesToDeny++;
			}
			else if (clientVote[i] == VoteStatus:Abstain && countAbstainAsDeny)
			{
				if (team == TeamType:Survivor)
				{
					votesToDenyTeamA++;
				}
				else if (team == TeamType:Infected)
				{
					votesToDenyTeamB++;
				}
				votesToDeny++;
			}
		}
	}

#if VERBOSE_ADMIN_MESSAGES
	decl String:message[128];
#endif

	if (currentVoteType == VoteType:Switch)
	{
		if (votingClients == 0)
		{
			if (countAbstainAsDeny)
			{
#if VERBOSE_ADMIN_MESSAGES
				sendMessageToAdmins("[SM] (Switch) No voting clients at timeout; allowing switch.");
#endif
				return VoteStatus:Allow;
			}
			else
			{
#if VERBOSE_ADMIN_MESSAGES
				sendMessageToAdmins("[SM] (Switch) No voting clients; not at timeout; vote incomplete.");
#endif
				return VoteStatus:Abstain;
			}
		}

		// To pass, a vote must have a majority of clients vote to allow
		if (votesToAllow > (votingClients / 2.0))
		{
#if VERBOSE_ADMIN_MESSAGES
			Format(message, 128, "[SM] (Switch) %i votes to allow of %i voting clients; allowing switch.", votesToAllow, votingClients);
			sendMessageToAdmins(message);
#endif
			return VoteStatus:Allow;
		}
		else if (votesToDeny >= (votingClients / 2.0))
		{
#if VERBOSE_ADMIN_MESSAGES
			Format(message, 128, "[SM] (Switch) %i votes to deny of %i voting clients; denying switch.", votesToDeny, votingClients);
			sendMessageToAdmins(message);
#endif
			return VoteStatus:Deny;
		}
		else
		{
			if (countAbstainAsDeny)
			{
#if VERBOSE_ADMIN_MESSAGES
			Format(message, 128, "[SM] (Switch) %i allow and %i deny of %i voting clients; timeout reached; allowing switch.", votesToAllow, votesToDeny, votingClients);
			sendMessageToAdmins(message);
#endif
				// This should never be reached
				return VoteStatus:Allow;
			}
			else
			{
#if VERBOSE_ADMIN_MESSAGES
			Format(message, 128, "[SM] (Switch) %i allow and %i deny of %i voting clients; vote incomplete.", votesToAllow, votesToDeny, votingClients);
			sendMessageToAdmins(message);
#endif
				return VoteStatus:Abstain;
			}
		}
	}
	else if (currentVoteType == VoteType:Swap)
	{
		if (votingClientsTeamA == 0 || votingClientsTeamB == 0)
		{
			if (countAbstainAsDeny)
			{
#if VERBOSE_ADMIN_MESSAGES
				sendMessageToAdmins("[SM] (Swap) Zero voting clients on one or both teams; timeout reached; denying switch.");
#endif
				return VoteStatus:Deny;
			}
			else
			{
#if VERBOSE_ADMIN_MESSAGES
				sendMessageToAdmins("[SM] (Swap) Zero voting clients on one or both teams; vote incomplete.");
#endif
				return VoteStatus:Abstain;
			}
		}

		if (votesToAllowTeamA > (votingClientsTeamA / 2.0) && votesToAllowTeamB > (votingClientsTeamB / 2.0))
		{
#if VERBOSE_ADMIN_MESSAGES
			Format(message, 128, "[SM] (Swap) Team A: %i allow, %i deny, %i voters. Team B: %i allow, %i deny, %i voters. Allowing swap.", votesToAllowTeamA, votesToDenyTeamA, votingClientsTeamA, votesToAllowTeamB, votesToDenyTeamB, votingClientsTeamB);
			sendMessageToAdmins(message);
#endif
			return VoteStatus:Allow;
		}
		else if (votesToDenyTeamA >= (votingClientsTeamA / 2.0) || votesToDenyTeamB >= (votingClientsTeamB / 2.0))
		{
#if VERBOSE_ADMIN_MESSAGES
			Format(message, 128, "[SM] (Swap) Team A: %i allow, %i deny, %i voters. Team B: %i allow, %i deny, %i voters. Denying swap.", votesToAllowTeamA, votesToDenyTeamA, votingClientsTeamA, votesToAllowTeamB, votesToDenyTeamB, votingClientsTeamB);
			sendMessageToAdmins(message);
#endif
			return VoteStatus:Deny;
		}
		else
		{
			if (countAbstainAsDeny)
			{
#if VERBOSE_ADMIN_MESSAGES
				Format(message, 128, "[SM] (Swap) Team A: %i allow, %i deny, %i voters. Team B: %i allow, %i deny, %i voters. Timeout reached, denying.", votesToAllowTeamA, votesToDenyTeamA, votingClientsTeamA, votesToAllowTeamB, votesToDenyTeamB, votingClientsTeamB);
				sendMessageToAdmins(message);
#endif
				return VoteStatus:Deny;
			}
			else
			{
#if VERBOSE_ADMIN_MESSAGES
				Format(message, 128, "[SM] (Swap) Team A: %i allow, %i deny, %i voters. Team B: %i allow, %i deny, %i voters. Vote incomplete.", votesToAllowTeamA, votesToDenyTeamA, votingClientsTeamA, votesToAllowTeamB, votesToDenyTeamB, votingClientsTeamB);
				sendMessageToAdmins(message);
#endif
				return VoteStatus:Abstain;
			}
		}
	}

#if VERBOSE_ADMIN_MESSAGES
	sendMessageToAdmins("[SM] (Error) Problem with voting; denying by default.");
#endif
	return VoteStatus:Deny;
}

// Tallies the vote of a client, and checks if voting is now complete
handleVoteOf(VoteStatus:vote, client)
{
	if (!voteInProgress)
	{
		PrintToChat(client, "[SM] There is not currently a team switch vote in progress.");
		return;
	}

	if (client <= 0 || client >= MAX_VOTING_CLIENTS)
	{
		return;
	}
	else if (!clientIsValidVoter[client])
	{
		PrintToChat(client, "[SM] You are not a valid voter. Either you are on the wrong team, or you were not connected when the team switch request was made.");
		return;
	}

	if (vote == VoteStatus:Allow)
	{
		PrintToChat(client, "[SM] You have voted to allow the switch.");
	}
	else if (vote == VoteStatus:Deny)
	{
		PrintToChat(client, "[SM] You have voted to deny the switch.");
	}

	clientVote[client] = vote;

	checkIfVerdictReached();
}

checkIfVerdictReached()
{
	new VoteStatus:currentVoteStatus = getVoteStatus(false);
		
	decl String:clientName[MAX_NAME_LENGTH];
	new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);

	if (currentVoteStatus == VoteStatus:Allow)
	{
		if (currentVoteType == VoteType:Switch)
		{
			handleSwitchAllowed(clientNameRetrieved, clientName);
		}
		else if (currentVoteType == VoteType:Swap)
		{
			decl String:swapWithClientName[MAX_NAME_LENGTH];
			new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);

#if VOTE_TESTING
			
#else
			handleSwapAllowed(clientNameRetrieved, clientName, swapWithClientNameRetrieved, swapWithClientName);
#endif
		}

		if (voteTimer != INVALID_HANDLE)
		{
			KillTimer(voteTimer);
			voteTimer = INVALID_HANDLE;
		}
		voteInProgress = false;
	}
	else if (currentVoteStatus == VoteStatus:Deny)
	{
		if (currentVoteType == VoteType:Switch)
		{
			if (clientNameRetrieved)
			{
				PrintToChatAll("\x01[SM] Player \x04%s\x01 was not allowed to switch teams.", clientName);
			}
			else
			{
				PrintToChatAll("\x01[SM] Player <unnamed> was not allowed to switch teams.");
			}
		}
		else if (currentVoteType == VoteType:Swap)
		{
			decl String:swapWithClientName[MAX_NAME_LENGTH];
			new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);
			
			if (clientNameRetrieved)
			{
				if (swapWithClientNameRetrieved)
				{
					PrintToChatAll("\x01[SM] \x04%s\x01 was not allowed to swap teams with \x04%s\x01.", clientName, swapWithClientName);
				}
				else
				{
					PrintToChatAll("\x01[SM] \x04%s\x01 was not allowed to swap teams with <unnamed>.", clientName);
				}
			}
			else
			{
				if (swapWithClientNameRetrieved)
				{
					PrintToChatAll("\x01[SM] <unnamed> was not allowed to swap teams with \x04%s\x01.", swapWithClientName);
				}
				else
				{
					PrintToChatAll("\x01[SM] <unnamed> was not allowed to swap teams with <unnamed>.");
				}
			}
		}

		incrementFailedSwitches(clientRequestingSwitch);
				
		if (voteTimer != INVALID_HANDLE)
		{
			KillTimer(voteTimer);
			voteTimer = INVALID_HANDLE;
		}
		voteInProgress = false;
	}
}

//
// Delayed switch
//

enableDelayedSwitch()
{	
	if (delayedSwitchTimer != INVALID_HANDLE)
	{
		KillTimer(delayedSwitchTimer);
	}
	delayedSwitchTimer = CreateTimer(GetConVarFloat(cvarDelayedSwitchTimeout), handleDelayedSwitchTimeout);
	allowDelayedSwitch = true;
}

disableDelayedSwitch()
{
	allowDelayedSwitch = false;
	if (delayedSwitchTimer != INVALID_HANDLE)
	{
		KillTimer(delayedSwitchTimer);
		delayedSwitchTimer = INVALID_HANDLE;
	}
}

public Action:handleDelayedSwitchTimeout(Handle:timer)
{
	delayedSwitchTimer = INVALID_HANDLE;

	PrintToChat(clientRequestingSwitch, "[SM] Delayed switch timed out. Both teams must vote again if you still want to swap.");
	PrintToChat(clientToSwapWith, "[SM] Delayed switch timed out. Both teams must vote again if you still want to swap.");
	allowDelayedSwitch = false;
}

//
// Send a message to admins
//

sendMessageToAdmins(String:message[], bool:excludeTeam = false, TeamType:teamToExclude = TeamType:Spectator)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientAuthorized(i) && IsClientInGame(i))
		{
			if (!excludeTeam || (excludeTeam && (TeamType:GetClientTeam(i) != teamToExclude)))
			{
				new AdminId:adminId = GetUserAdmin(i);
				if (adminId != INVALID_ADMIN_ID)
				{
					if (GetAdminFlag(adminId, AdminFlag:ADMFLAG_GENERIC))
					{
						PrintToChat(i, message);
					}
				}
			}
		}
	}
}


//
// Team switch handling
//

bool:connectionsInProgress()
{
	return waitingForConnections;
}


// Function to actually change the player's team (taken directly from AtomicStryker's plugin: http://forums.alliedmods.net/showthread.php?t=113188)
stock bool:ChangePlayerTeam(client, team)
{
	if(GetClientTeam(client) == team) return true;
	
	if(team != L4D_TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}
	
	if(GetTeamHumanCount(team) == GetTeamMaxHumans(team))
	{
		//DebugPrintToAll("ChangePlayerTeam() : Cannot switch %N to team %d, as team is full", client, team);
		return false;
	}
	
	new bot;
	//for survivors its more tricky
	for(bot = 1; bot < L4D_MAXCLIENTS_PLUS1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != L4D_TEAM_SURVIVORS)); bot++) {}
	
	if(bot == L4D_MAXCLIENTS_PLUS1)
	{
		//DebugPrintToAll("Could not find a survivor bot, adding a bot ourselves");
		
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		
		ServerCommand("sb_add");
		
		SetCommandFlags(command, flags);
		
		//DebugPrintToAll("Added a survivor bot, trying again...");
		return false;
	}
	
	//have to do this to give control of a survivor bot
	SDKCall(fSHS, bot, client);
	SDKCall(fTOB, client, true);
	
	return true;
}

// Client is in-game and not a bot (taken directly from AtomicStryker's plugin: http://forums.alliedmods.net/showthread.php?t=113188)
stock bool:IsClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

// Taken directly from AtomicStryker's plugin: http://forums.alliedmods.net/showthread.php?t=113188
stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) == team)
		{
			humans++
		}
	}
	
	return humans;
}

// Taken directly from AtomicStryker's plugin: http://forums.alliedmods.net/showthread.php?t=113188
stock GetTeamMaxHumans(team)
{
	if(team == L4D_TEAM_SURVIVORS)
	{
		return GetConVarInt(FindConVar("survivor_limit"));
	}
	else if(team == L4D_TEAM_INFECTED)
	{
		return GetConVarInt(FindConVar("z_max_player_zombies"));
	}
	else if(team == L4D_TEAM_SPECTATE)
	{
		return L4D_MAXCLIENTS;
	}
	
	return -1;
}

bool:GetClientName_Safe(client, String:name[], maxlen)
{
	if (client <= 0 || !IsClientConnected(client))
	{
		return false;
	}

	return GetClientName(client, name, maxlen);
}

//
// Commands
//

public Action:Command_AllowSwitch(client, args)
{
	if (IsClientConnected(client) && !IsFakeClient(client) && IsClientAuthorized(client))
	{
		handleVoteOf(VoteStatus:Allow, client);
	}
}

public Action:Command_DenySwitch(client, args)
{
	if (IsClientConnected(client) && !IsFakeClient(client) && IsClientAuthorized(client))
	{
		handleVoteOf(VoteStatus:Deny, client);
	}
}

public Action:Command_CancelSwitch(client, args)
{
	if (!voteInProgress && !allowDelayedSwitch)
	{
		PrintToChat(client, "[SM] There is not currently a team switch vote in progress.");
		return;
	}

	decl String:clientName[MAX_NAME_LENGTH];
	new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);

	if (currentVoteType == VoteType:Switch)
	{
		if (clientNameRetrieved)
		{
			PrintToChatAll("\x01[SM] Player \x04%s\x01 was not allowed to switch teams.", clientName);
		}
		else
		{
			PrintToChatAll("\x01[SM] Player <unnamed> was not allowed to switch teams.");
		}
	}
	else if (currentVoteType == VoteType:Swap)
	{
		decl String:swapWithClientName[MAX_NAME_LENGTH];
		new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);
		
		if (clientNameRetrieved)
		{
			if (swapWithClientNameRetrieved)
			{
				PrintToChatAll("\x01[SM] \x04%s\x01 was not allowed to swap teams with \x04%s\x01.", clientName, swapWithClientName);
			}
			else
			{
				PrintToChatAll("\x01[SM] \x04%s\x01 was not allowed to swap teams with <unnamed>.", clientName);
			}
		}
		else
		{
			if (swapWithClientNameRetrieved)
			{
				PrintToChatAll("\x01[SM] <unnamed> was not allowed to swap teams with \x04%s\x01.", swapWithClientName);
			}
			else
			{
				PrintToChatAll("\x01[SM] <unnamed> was not allowed to swap teams with <unnamed>.");
			}
		}
	}

	incrementFailedSwitches(clientRequestingSwitch);
				
	if (voteTimer != INVALID_HANDLE)
	{
		KillTimer(voteTimer);
		voteTimer = INVALID_HANDLE;
	}

	if (delayedSwitchTimer != INVALID_HANDLE)
	{
		KillTimer(delayedSwitchTimer);
		delayedSwitchTimer = INVALID_HANDLE;
	}

	voteInProgress = false;
	allowDelayedSwitch = false;
}

// Allows an admin to force a vote to go through
public Action:Command_ForceSwitch(client, args)
{
	if (!voteInProgress && !allowDelayedSwitch)
	{
		PrintToChat(client, "[SM] There is not currently a team switch vote in progress.");
		return;
	}

	decl String:clientName[MAX_NAME_LENGTH];
	new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);

	if (voteTimer != INVALID_HANDLE)
	{
		KillTimer(voteTimer);
		voteTimer = INVALID_HANDLE;
	}

	voteInProgress = false;

	if (currentVoteType == VoteType:Switch)
	{
		handleSwitchAllowed(clientNameRetrieved, clientName);
	}
	else if (currentVoteType == VoteType:Swap)
	{
		decl String:swapWithClientName[MAX_NAME_LENGTH];
		new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);

		handleSwapAllowed(clientNameRetrieved, clientName, swapWithClientNameRetrieved, swapWithClientName);
	}
}

#if VOTE_TESTING

public Action:Command_FakeVotingClient(client, args)
{
	decl String:buffer[8];
	GetCmdArg(1, buffer, 8);
	new fakeClient = StringToInt(buffer);

	GetCmdArg(2, buffer, 8);
	new TeamType:team = TeamType:StringToInt(buffer);

	addVotingClient(fakeClient);
	fakeClientTeam[fakeClient] = team;
}

public Action:Command_FakeAllow(client, args)
{
	decl String:buffer[8];
	GetCmdArg(1, buffer, 8);

	new fakeClient = StringToInt(buffer);
	
	clientVote[fakeClient] = VoteStatus:Allow;

	checkIfVerdictReached();
}

public Action:Command_FakeDeny(client, args)
{
	decl String:buffer[8];
	GetCmdArg(1, buffer, 8);

	new fakeClient = StringToInt(buffer);
	
	clientVote[fakeClient] = VoteStatus:Deny;

	checkIfVerdictReached();
}

public Action:Command_FakeSwap(client, args)
{
	currentVoteType = VoteType:Swap;
}

#endif

// Allows a player to start a vote to be switched with a player on the other team (for when both teams are full)
public Action:Command_VoteSwap(client, args)
{
	if (client != 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientAuthorized(client) && IsClientInGame(client))
	{
		new TeamType:currentTeam = TeamType:GetClientTeam(client);
		new TeamType:opposingTeam = TeamType:Spectator;

		if (currentTeam == TeamType:Survivor)
		{
			opposingTeam = TeamType:Infected;
		}
		else if (currentTeam == TeamType:Infected)
		{
			opposingTeam = TeamType:Survivor;
		}
		else
		{
			ReplyToCommand(client, "[SM] Spectators cannot call swap votes");
			return Plugin_Handled;
		}

		if (connectionsInProgress())
		{
			decl String:clientName[MAX_NAME_LENGTH];
			if (GetClientName_Safe(client, clientName, MAX_NAME_LENGTH))
			{
				decl String:message[192];
				Format(message, 192, "\x01[SM] (Admin Notification) Player \x04%s\x01 is attempting to change teams, but cannot, since the server is waiting for players to connect.", clientName);
				sendMessageToAdmins(message);
			}
			else
			{
				sendMessageToAdmins("\x01[SM] (Admin Notification) Player <unnamed> is attempting to change teams, but cannot, since the server is waiting for players to connect.");
			}

			PrintToChat(client, "[SM] You may not switch teams while players are still connecting");
		}
		else
		{
			if (voteInProgress)
			{
				decl String:clientName[MAX_NAME_LENGTH];
				if (GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH))
				{
					PrintToChat(client, "\x01[SM] Player \x04%s\x01 is attempting to change teams. Please wait until their vote goes through.", clientName);
				}
				else
				{
					PrintToChat(client, "\x01[SM] Player <unnamed> is attempting to change teams. Please wait until their vote goes through.");
				}
			}
			else if (allowDelayedSwitch && currentVoteType == VoteType:Swap)
			{
				new clientOnSurvivorTeam;
				new clientOnInfectedTeam;

				if (TeamType:GetClientTeam(clientRequestingSwitch) == TeamType:Infected)
				{
					clientOnSurvivorTeam = clientToSwapWith;
					clientOnInfectedTeam = clientRequestingSwitch;
				}
				else
				{
					clientOnSurvivorTeam = clientRequestingSwitch;
					clientOnInfectedTeam = clientToSwapWith;
				}

				decl String:clientName[MAX_NAME_LENGTH];
				new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);
				decl String:swapWithClientName[MAX_NAME_LENGTH];
				new bool:swapWithClientNameRetrieved = GetClientName_Safe(clientToSwapWith, swapWithClientName, MAX_NAME_LENGTH);

				if (clientOnInfectedTeam == client)
				{
					handleSwapAllowed(clientNameRetrieved, clientName, swapWithClientNameRetrieved, swapWithClientName);
				}
				else if (clientOnSurvivorTeam == client)
				{
					PrintToChat(client, "\x01[SM] The infected player you are swapping with must enter '!voteswap' in chat once he/she is not longer spawned.");
				}
				else
				{
					if (clientNameRetrieved)
					{
						if (swapWithClientNameRetrieved)
						{
							PrintToChat(client, "\x01[SM] \x04%s\x01 is attempting to swap teams with \x04%s\x01. Please wait until their vote goes through.", clientName, swapWithClientName);
						}
						else
						{
							PrintToChat(client, "\x01[SM] \x04%s\x01 is attempting to swap teams with <unnamed>. Please wait until their vote goes through.", clientName);
						}
					}
					else
					{
						if (swapWithClientNameRetrieved)
						{
							PrintToChat(client, "\x01[SM] <unnamed> is attempting to swap teams with \x04%s\x01. Please wait until their vote goes through.", swapWithClientName);
						}
						else
						{
							PrintToChat(client, "\x01[SM] <unnamed> is attempting to swap teams with <unnamed>. Please wait until their vote goes through.");
						}
					}
				}
			}
			else if (failedSwitches[client] >= NUM_SWITCHES_BEFORE_TIMER)
			{
				PrintToChat(client, "[SM] After two failed switch votes (or after one for repeat offenders), you must wait five minutes before you may request another vote.");
				failedSwitches[client] += 1;
			}
			else
			{
				new Handle:swapMenu = CreateMenu(SwapMenuHandler);
				SetMenuTitle(swapMenu, "Choose a player to swap with:");
				
				decl String:strUserId[8];
				decl String:clientName[MAX_NAME_LENGTH];
				new bool:clientNameRetrieved;
				new bool:opposingTeamHasPlayers;
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i) && TeamType:GetClientTeam(i) == opposingTeam)
					{
						IntToString(GetClientUserId(i), strUserId, 8);
						clientNameRetrieved = GetClientName_Safe(i, clientName, MAX_NAME_LENGTH);

						if (clientNameRetrieved)
						{
							// Confirm that the name hasn't been used before
							new menuItemCount = GetMenuItemCount(swapMenu);
							decl String:infoBuffer[MAX_NAME_LENGTH];
							decl String:displayBuffer[MAX_NAME_LENGTH];
							new style;
							new bool:nameUsedBefore = false;
							for (new j = 0; j < menuItemCount; j++)
							{
								if (GetMenuItem(swapMenu, j, infoBuffer, MAX_NAME_LENGTH, style, displayBuffer, MAX_NAME_LENGTH))
								{
									if (StrEqual(displayBuffer, clientName))
									{
										nameUsedBefore = true;
										break;
									}
								}
							}

							if (nameUsedBefore)
							{
								continue;
							}

							AddMenuItem(swapMenu, strUserId, clientName);
							opposingTeamHasPlayers = true;
						}
					}
				}

				if (!opposingTeamHasPlayers)
				{
					ReplyToCommand(client, "[SM] There is no one on the other team to swap with. Try a normal switch by using the chooseteam menu (default 'm').");
					return Plugin_Handled;
				}

				SetMenuExitButton(swapMenu, true);

				DisplayMenu(swapMenu, client, 60);
			}
		}
	}

	return Plugin_Handled;
}

// TODO: When switching to spec, remember what team each person was on, so they can switch back
public Action:Command_JoinTeam(client, args)
{
	if (client != 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientAuthorized(client) && IsClientInGame(client))
	{
		new String:text[32];
		GetCmdArgString(text, sizeof(text));
		requestedTeam = TeamType:Spectator;
		if (StrEqual(text, "Survivor") || StrEqual(text, "2"))
		{
			requestedTeam = TeamType:Survivor;
		}
		else if (StrEqual(text, "Infected") || StrEqual(text, "3"))
		{
			requestedTeam = TeamType:Infected;
		}
		else
		{
			ReplyToCommand(client, "[SM] Invalid team selection. Please make team selections through the chooseteam menu (default 'm').");
			return Plugin_Handled;
		}

		new TeamType:currentTeam = TeamType:GetClientTeam(client);

		// Check if the client is an admin
		new AdminId:clientAdminId = GetUserAdmin(client);
		
		// Let the client switch without a vote if they're switching to spectators or to their own team
		if (requestedTeam == TeamType:Spectator || currentTeam == requestedTeam)
		{
			return Plugin_Continue;
		}
#if ADMINS_SKIP_VOTING
		else if (clientAdminId != INVALID_ADMIN_ID)
		{
			// Let admins switch, but use the plugin method of switching to bypass the switch limits
			
			if (doesClientHaveTank(client))
			{
				PrintToChat(client, "[SM] You may not switch teams while you are in control of the tank.");
			}
			else if (TeamType:GetClientTeam(client) == TeamType:Infected && !isClientDeadOrGhost(client))
			{
				PrintToChat(client, "[SM] You may only switch from the infected team while in ghost mode.");
			}
			else
			{
				decl String:clientName[MAX_NAME_LENGTH];
				new bool:clientNameRetrieved = GetClientName_Safe(client, clientName, MAX_NAME_LENGTH);

				if (clientNameRetrieved)
				{
					decl String:message[192];
					Format(message, 192, "\x01[SM] (Admin Notification) Admin \x04%s\x01 switched teams.", clientName);
					sendMessageToAdmins(message);
				}
				else
				{
					sendMessageToAdmins("\x01[SM] (Admin Notification) Admin <unnamed> switched teams.");
				}

				ChangePlayerTeam(client, _:requestedTeam);
			}
		}
#endif
		else
		{
			if (connectionsInProgress())
			{
				decl String:clientName[MAX_NAME_LENGTH];
				if (GetClientName_Safe(client, clientName, MAX_NAME_LENGTH))
				{
					decl String:message[192];
					Format(message, 192, "\x01[SM] (Admin Notification) Player \x04%s\x01 is attempting to change teams, but cannot, since the server is waiting for players to connect.", clientName);
					sendMessageToAdmins(message);
				}
				else
				{
					sendMessageToAdmins("\x01[SM] (Admin Notification) Player <unnamed> is attempting to change teams, but cannot, since the server is waiting for players to connect.");
				}

				PrintToChat(client, "[SM] You may not switch teams while players are still connecting");
			}
			else
			{
				if (voteInProgress)
				{
					decl String:clientName[MAX_NAME_LENGTH];
					if (GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH))
					{
						PrintToChat(client, "\x01[SM] Player \x04%s\x01 is attempting to change teams. Please wait until their vote goes through.", clientName);
					}
					else
					{
						PrintToChat(client, "\x01[SM] Player <unnamed> is attempting to change teams. Please wait until their vote goes through.");
					}
				}
				else if (allowDelayedSwitch)
				{
					decl String:clientName[MAX_NAME_LENGTH];
					new bool:clientNameRetrieved = GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH);
					if (clientRequestingSwitch == client)
					{
						// Client was the the one on delayed switch
						handleSwitchAllowed(clientNameRetrieved, clientName);
					}
					else
					{
						if (clientNameRetrieved)
						{
							PrintToChat(client, "\x01[SM] Player \x04%s\x01 is attempting to change teams. Please wait until their vote goes through.", clientName);
						}
						else
						{
							PrintToChat(client, "\x01[SM] Player <unnamed> is attempting to change teams. Please wait until their vote goes through.");
						}
					}
				}
				else if (failedSwitches[client] >= NUM_SWITCHES_BEFORE_TIMER)
				{
					PrintToChat(client, "[SM] After two failed switch votes (or after one for repeat offenders), you must wait five minutes before you may request another vote.");
					failedSwitches[client] += 1;
				}
				else
				{
					// TODO: what should happen if the other team is empty?
					voteInProgress = true;
					clientRequestingSwitch = client;
					
					PrintToChat(client, "[SM] You will switch teams if the opposing team votes to allow it.");
					
					decl String:clientName[MAX_NAME_LENGTH];
					if (GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH))
					{
						decl String:message[192];
						Format(message, 192, "\x01[SM] (Admin Notification) Player \x04%s\x01 is attempting to change teams.", clientName);
						sendMessageToAdmins(message, true, requestedTeam);
					}
					else
					{
						sendMessageToAdmins("[SM] (Admin Notification) Player <unnamed> is attempting to change teams.", true, requestedTeam);
					}
					notifyTeamAboutVote();
				}
			}
		}
	}

	return Plugin_Handled;
}

//
// Events
//

public OnClientDisconnect_Post(client)
{
	if (client > 0 && client < MAX_VOTING_CLIENTS)
	{
		if ((client == clientRequestingSwitch && currentVoteType == VoteType:Switch && (voteInProgress || allowDelayedSwitch)) ||
			((client == clientRequestingSwitch || client == clientToSwapWith) && currentVoteType == VoteType:Swap && (voteInProgress || allowDelayedSwitch)))
		{
			if (voteTimer != INVALID_HANDLE)
			{
				KillTimer(voteTimer);
				voteTimer = INVALID_HANDLE;
			}

			if (delayedSwitchTimer != INVALID_HANDLE)
			{
				KillTimer(delayedSwitchTimer);
				delayedSwitchTimer = INVALID_HANDLE;
			}

			voteInProgress = false;
			allowDelayedSwitch = false;
		}

		resetFailedSwitches(client);

		removeVotingClient(client);

		if (announcementTimers[client] != INVALID_HANDLE)
		{
			KillTimer(announcementTimers[client]);
			announcementTimers[client] = INVALID_HANDLE;
		}

		if (voteInProgress)
		{
			checkIfVerdictReached();
		}
	}
}

public OnClientPutInServer(client)
{
	if (client == 0)
	{
		return;
	}

	if (announcementTimers[client] != INVALID_HANDLE)
	{
		KillTimer(announcementTimers[client]);
	}
	announcementTimers[client] = CreateTimer(ANNOUNCEMENT_DELAY, DisplayAnnouncement, any:client);
}

public Action:DisplayAnnouncement(Handle:timer, any:client)
{
	if (_:client != 0 && IsClientConnected(_:client) && GetConVarInt(cvarAnnounce) == 1 && isCompetitiveGamemode())
	{
		PrintToChat(_:client, "\x01[SM] To swap teams with another player when both teams are full, enter \x04!voteswap\x01 in chat.");
	}

	announcementTimers[_:client] = INVALID_HANDLE;
}

bool:isCompetitiveGamemode()
{
	decl String:gamemode[64];
	GetConVarString(cvarGamemode, gamemode, 64);
	if (StrEqual(gamemode, "versus") || StrEqual(gamemode, "teamversus") || StrEqual(gamemode, "mutation12") || StrEqual(gamemode, "scavenge") || StrEqual(gamemode, "teamscavenge"))
	{
		return true;
	}
	return false;
}

//
// Panel and Menu Handlers
//

public VotingPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param1 > 0 && IsClientConnected(param1) && !IsFakeClient(param1) && IsClientAuthorized(param1))
		{
			if (param2 == 1)
			{
				handleVoteOf(VoteStatus:Allow, param1);
			}
			else if (param2 == 2)
			{
				handleVoteOf(VoteStatus:Deny, param1);
			}
		}
	}
}

public AdminVotingPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param1 > 0 && IsClientConnected(param1) && !IsFakeClient(param1) && IsClientAuthorized(param1))
		{
			new AdminId:clientAdminId = GetUserAdmin(param1);

			if (clientAdminId != INVALID_ADMIN_ID)
			{
				if (param2 == 1)
				{
					handleVoteOf(VoteStatus:Allow, param1);
				}
				else if (param2 == 2)
				{
					handleVoteOf(VoteStatus:Deny, param1);
				}
				else if (param2 == 3)
				{
					// Force allow
					Command_ForceSwitch(param1, 0);
				}
				else if (param2 == 4)
				{
					// Force deny
					Command_CancelSwitch(param1, 0);
				}
			}
		}
	}
}

public AdminNonVotingPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param1 > 0 && IsClientConnected(param1) && !IsFakeClient(param1) && IsClientAuthorized(param1))
		{
			new AdminId:clientAdminId = GetUserAdmin(param1);

			if (clientAdminId != INVALID_ADMIN_ID)
			{
				if (param2 == 1)
				{
					// Force allow
					Command_ForceSwitch(param1, 0);
				}
				else if (param2 == 2)
				{
					// Force deny
					Command_CancelSwitch(param1, 0);
				}
			}
		}
	}
}

public SwapMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:strUserId[8];
		new bool:found = GetMenuItem(menu, param2, strUserId, sizeof(strUserId));

		if (found)
		{
			new clientId = GetClientOfUserId(StringToInt(strUserId));

			if (clientId == 0)
			{
				PrintToChat(param1, "[SM] The player you selected is no longer in-game.");
				return;
			}

			if (voteInProgress || allowDelayedSwitch)
			{
				decl String:clientName[MAX_NAME_LENGTH];
				if (GetClientName_Safe(clientRequestingSwitch, clientName, MAX_NAME_LENGTH))
				{
					PrintToChat(param1, "\x01[SM] Player \x04%s\x01 is attempting to change teams. Please wait until their vote goes through.", clientName);
				}
				else
				{
					PrintToChat(param1, "\x01[SM] Player <unnamed> is attempting to change teams. Please wait until their vote goes through.");
				}
			}
			else if (failedSwitches[param1] >= NUM_SWITCHES_BEFORE_TIMER)
			{
				PrintToChat(param1, "[SM] After two failed switch votes (or after one for repeat offenders), you must wait five minutes before you may request another vote.");
				failedSwitches[param1] += 1;
			}
			else
			{
				voteInProgress = true;
				clientRequestingSwitch = param1;
				clientToSwapWith = clientId;
				requestedTeam = TeamType:GetClientTeam(clientToSwapWith);

				decl String:clientToSwapWithName[MAX_NAME_LENGTH];
				new bool:swapNameRetrieved = GetClientName_Safe(clientToSwapWith, clientToSwapWithName, MAX_NAME_LENGTH);

				if (swapNameRetrieved)
				{				
					PrintToChat(clientRequestingSwitch, "\x01[SM] You will swap with \x04%s\x01 if both teams vote to allow it.", clientToSwapWithName);
				}
				else
				{
					PrintToChat(clientRequestingSwitch, "[SM] You will swap if both teams vote to allow it.");
				}

				notifyAllAboutVote();
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//
// Plugin initialization
//

public OnPluginStart()
{
	PrepareAllSDKCalls();

	cvarVoteTimeout = CreateConVar("l4d2switchvote_timeout", "45.0", "Seconds that a vote is active before results are tallied", FCVAR_PLUGIN | FCVAR_NOTIFY);
	cvarConnWait = CreateConVar("l4d2switchvote_connwait", "60.0", "Seconds after a map begins that switching can occur", FCVAR_PLUGIN | FCVAR_NOTIFY);
	cvarDelayedSwitchTimeout = CreateConVar("l4d2switchvote_delaytimeout", "90.0", "Seconds after a vote is passed that a delayed switch is allowed.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	cvarAnnounce = CreateConVar("l4d2switchvote_announce", "1", "Announce the !voteswitch command to users");

	AutoExecConfig(true, "teamswitchvote");

	CreateConVar("l4d2switchvote_ver", VERSION, "Version of team switch vote plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvarGamemode = FindConVar("mp_gamemode");

	RegConsoleCmd("jointeam", Command_JoinTeam);
	RegConsoleCmd("sm_allowswitch", Command_AllowSwitch);
	RegConsoleCmd("sm_denyswitch", Command_DenySwitch);
	RegConsoleCmd("sm_voteswap", Command_VoteSwap);
#if VOTE_TESTING
	RegAdminCmd("sm_fvc", Command_FakeVotingClient, ADMFLAG_GENERIC);
	RegAdminCmd("sm_fallow", Command_FakeAllow, ADMFLAG_GENERIC);
	RegAdminCmd("sm_fdeny", Command_FakeDeny, ADMFLAG_GENERIC);
	RegAdminCmd("sm_fswap", Command_FakeSwap, ADMFLAG_GENERIC);
#endif
	RegAdminCmd("sm_cancelswitch", Command_CancelSwitch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_forceswitch", Command_ForceSwitch, ADMFLAG_GENERIC);

	PropGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");

	// Prepare voting menu
	votingPanel = CreatePanel();
	SetPanelTitle(votingPanel, "A player would like to switch to your team");
	DrawPanelItem(votingPanel, "Allow");
	DrawPanelItem(votingPanel, "Deny");

	// Prepare admin voting menu
	adminVotingPanel = CreatePanel();
	SetPanelTitle(adminVotingPanel, "A player would like to switch to your team");
	DrawPanelItem(adminVotingPanel, "Allow");
	DrawPanelItem(adminVotingPanel, "Deny");
	DrawPanelItem(adminVotingPanel, "(Admin) Force Allow");
	DrawPanelItem(adminVotingPanel, "(Admin) Force Deny");

	// Prepare admin non-voting menu (for admins not on the voting team)
	adminNonVotingPanel = CreatePanel();
	SetPanelTitle(adminNonVotingPanel, "A player would like to switch teams");
	DrawPanelItem(adminNonVotingPanel, "(Admin) Force Allow");
	DrawPanelItem(adminNonVotingPanel, "(Admin) Force Deny");

	voteCompletePanel = CreatePanel();
	SetPanelTitle(voteCompletePanel, "Vote completed");
}

PrepareAllSDKCalls()
{
	gConf = LoadGameConfigFile("teamswitchvote.l4d2");
	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/teamswitchvote.l4d2.txt");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
}
