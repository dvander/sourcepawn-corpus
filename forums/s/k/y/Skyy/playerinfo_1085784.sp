//Buttsex and monkeys
//...Ignore that.
//This happens when I'm tired.
//And it goes on and on my friends...

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Player/Server Notification",
	author = "Sky",
	description = "prints vital join/team/leave information to server.",
	version = "1.1",
	url = "http://steamcommunity.com/groups/skyservers"
};

public OnPluginStart()
{
	HookEvent("player_team", JoinTeam);
}
// I can't believe I forgot this.
// I am such a fucking idiot.
// /Wrist

/*
public OnClientConnected(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	PrintToChatAll("%N has connected to the server.", client)
}
*/
// Not Needed as Valve already automatically provides this functionality.

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	PrintToChatAll("%N has disconnected from the server.", client)
}

public JoinTeam(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new clientTeam = GetEventInt(event, "team");
	if (IsFakeClient(playerClient))
	{
		return;
	}

	switch (clientTeam)
	{
		case 1:
		{
			PrintToChatAll("%N has joined the Spectators.", playerClient)
		}
		case 2:
		{
			PrintToChatAll("%N has joined the Survivors.", playerClient)
		}
		case 3:
		{
			PrintToChatAll("%N has joined the Infected.", playerClient)
		}
	}
}