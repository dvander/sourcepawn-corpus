#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name		= "[ANY] Instant Auto-Assign",
	author		= "Dr. McKay",
	description	= "Automatically assigns someone to a team as soon as they enter the server",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

public OnClientPutInServer(client) {
	if(GetTeamClientCount(2) <= GetTeamClientCount(3)) {
		ChangeClientTeam(client, 2);
	} else {
		ChangeClientTeam(client, 3);
	}
}