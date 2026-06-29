#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Empty Server Restarter",
	author = "exvel",
	description = "Restarts servers when last player disconnected",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

g_isMapChange = false;

public OnClientDisconnect(client)
{
	// if map is changing do not do anything
	if (g_isMapChange)
		return;
	
	// count for players
	new counter = 0;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			counter++;
		}
	}
		
	// send "quit" command if there are no players
	if (counter == 0)
		ServerCommand("quit");
}

public OnMapEnd()
{
	g_isMapChange = true;
}

public OnMapStart()
{
	g_isMapChange = false;
}

