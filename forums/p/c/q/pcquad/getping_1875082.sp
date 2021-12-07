


#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1"

// Plugin info
public Plugin:myinfo = 
{
	name = "Get average Ping",
	author = "pcquad",
	description = "Simple average ping collect",
	version = PLUGIN_VERSION,
	url = "http://pcquad.de"
};

// Here we go!
public OnPluginStart()
{
 RegConsoleCmd("getpings", getpings);
}

// Check the ping!
public Action:getpings(client, args)
{



	new Float:Ping;
	new Float:Pinga;


	// First, let's get a count of the players in-game.
	new Players = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			Players++;
	}

	// Perform the actual ping checking and warn issuing.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{


			//GetClientAuthString(i, SteamID, sizeof(SteamID));
			//GetClientName(i, Name, sizeof(Name));

			Ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
			Pinga = Pinga + Ping;


		}

	}
     Pingaverage = Pinga / Players;

PrintToChatAll("the average Server ping is: %f", Pingaverage);
        Pingaverage = 0;
        Ping = 0;
        Pinga = 0;
return Plugin_Handled;
}
