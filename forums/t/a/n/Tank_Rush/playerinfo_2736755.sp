#include <sourcemod>
#include <multicolors>

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

public OnClientConnected(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	CPrintToChatAll("{olive}%N {default}has connected to the server.", client)
}

// Not Needed as Valve already automatically provides this functionality.
/*
public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	PrintToChatAll("%N has left the game.", client)
}
*/
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
			CPrintToChatAll("{olive}%N {default}has joined the Spectators.", playerClient)
		}
		case 2:
		{
			CPrintToChatAll("{olive}%N {default}has joined the {blue}Survivors.", playerClient)
		}
		case 3:
		{
			CPrintToChatAll("{olive}%N {default}has joined the {red}Infected.", playerClient)
		}
	}
}