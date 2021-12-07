#include <sourcemod>
new Handle:h_passwordLimit;
new hPlayers;

public OnPluginStart()
{
	h_passwordLimit = CreateConVar("sm_deactivate_password_count","3","...");
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		hPlayers = 0;
		CheckPlayerCount();
	}
}

public CheckPlayerCount()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			hPlayers++;
		}
	}
	if (hPlayers < GetConVarInt(h_passwordLimit))
	{
		ServerCommand("sv_password \"\"");	// sets no password on server.
	}
	else if (hPlayers >= GetConVarInt(h_passwordLimit))		// Modified for efficiency, hopefully you can figure out why
	{
		ServerCommand("exec server.cfg");	// execs the server.cfg to set the password
		//ServerCommand("exec setpass.cfg");	// or another file if you want to store just a pw and not be spammy
	}
}