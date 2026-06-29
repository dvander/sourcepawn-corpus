#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Empty Server Restarter",
	author = "exvel",
	description = "Restarts servers when last player disconnected",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

new bool:g_isMapChange = false;

public OnClientDisconnect(client)
{
	// if map is changing do not do anything
	if (client == 0 || g_isMapChange || IsFakeClient(client))
		return;
	
	// count for players
	new counter = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
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

