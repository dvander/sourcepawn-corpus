#pragma semicolon 1
#include <sourcemod>
#include <l4d2_vote>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D2] Voteapi Test",
	author = "McFlurry",
	description = "It's been too long, my old friend and acquaintance",
	version = PLUGIN_VERSION,
	url = "mcflurrysource.netne.net"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("l4d2_vote"))
	{
		SetFailState("l4d2_vote library not found!");
	}
}	

public Action:L4D2_OnClientVote(client, &L4D2Vote:vote)
{
	LogMessage("OnClientVote %N %d", client, vote);
}

public L4D2_OnClientVote_Post(client, L4D2Vote:vote)
{
	LogMessage("OnClientVote_Post %N %d", client, vote);
}

public Action:L4D2_OnClientAddedToVote(client)
{
	LogMessage("OnClientAddedToVote: (client, '%N')", client);
}

public L4D2_OnClientAddedToVote_Post(client)
{
	LogMessage("OnClientAddedToVote_Post: (client, '%N')", client);
}

public Action:L4D2_OnVoteStart(client, String:issue[], issue_size, String:argument[], argument_size)
{
	LogMessage("OnVoteStart: (client, '%N') (issue, '%s') (argument, '%s')", client, issue, argument);
}

public L4D2_OnVoteStart_Post(client, const String:issue[], const String:argument[])
{
	LogMessage("OnVoteStart_Post: (client, '%N') (issue, '%s') (argument, '%s')", client, issue, argument);
}

public Action:L4D2_OnVoteStart_UsrMsg(client, &votingteam, String:issue[], issue_size, String:voteargument[], argument_size)
{
	LogMessage("OnVoteStart_UsrMsg: (client, '%N') (team, %d) (issue, '%s') (voteargument, '%s')", client, votingteam, issue, voteargument);
}

public L4D2_OnVoteStart_UsrMsg_Post(client, votingteam, const String:issue[], const String:voteargument[])
{
	LogMessage("OnVoteStart_UsrMsg_Post: (client, '%N') (team, %d) (issue, '%s') (voteargument, '%s')", client, votingteam, issue, voteargument);
}

public Action:L4D2_OnVoteDisplay(client, String:votestarter[], votestarter_size, String:voteissue[], voteissue_size, String:voteparam[], voteparam_size)
{
	LogMessage("OnVoteDisplay: (client, '%N') (votestarter, '%s') (voteissue, '%s') (voteparam, '%s')", client, votestarter, voteissue, voteparam);
}

public L4D2_OnVoteDisplay_Post(client, const String:votestarter[], const String:voteissue[], const String:voteparam[])
{
	LogMessage("OnVoteDisplay_Post: (client, '%N') (votestarter, '%s') (voteissue, '%s') (voteparam, '%s')", client, votestarter, voteissue, voteparam);
}

public Action:L4D2_OnVotePass(client, String:voteissue[], voteissue_size, String:voteparam[], voteparam_size)
{
	LogMessage("OnVotePass: (client, '%N') (voteissue, '%s') (voteparam, '%s')", client, voteissue, voteparam);
}

public L4D2_OnVotePass_Post(client, const String:voteissue[], const String:voteparam[])
{
	LogMessage("OnVotePass_Post: (client, '%N') (voteissue, '%s') (voteparam, '%s')", client, voteissue, voteparam);
}

public L4D2_OnVoteEnd(bool:votepassed, const voters[], numVoters)
{
	LogMessage("OnVoteEnd_Post: (passed, %b)", votepassed);
	new String:sVoters[numVoters][2];
	for(new i; i<numVoters; i++)
	{
		Format(sVoters[i], sizeof(sVoters[]), "%d", voters[i]); 
	}
	new String:sVoterList[64];
	ImplodeStrings(sVoters, numVoters, ",", sVoterList, sizeof(sVoterList));
	LogMessage("Voters: %s", sVoterList);
}