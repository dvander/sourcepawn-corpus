#include <sourcemod>

public Plugin:myinfo = 
{
	name = "No Kick",
	author = "Frederik",
	description = "Disable votekick if there are 3 or less players on the server",
	version = "1.0",
	url = "<- URL ->"
}

#define VOTELIMIT 3

public OnClientPutInServer(client) {
	if (GetClientCount() <= VOTELIMIT) {
		ServerCommand("sv_vote_issue_kick_allowed 0");
	} else if (GetClientCount() > VOTELIMIT) {
		ServerCommand("sv_vote_issue_kick_allowed 1");
	}
}

public OnClientDisconnect_Post(client) {
	if (GetClientCount() <= VOTELIMIT) {
		ServerCommand("sv_vote_issue_kick_allowed 0");
	} else if (GetClientCount() > VOTELIMIT) {
		ServerCommand("sv_vote_issue_kick_allowed 1");
	}
}