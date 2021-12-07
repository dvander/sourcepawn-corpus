
#include <sourcemod>

new TotalPlayers;
new MaxPlayers;
new Handle:MaxPlayersCvar = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Client Rejection Plugin",
	author = "Potato Uno (Hydrogen)",
	description = "Rejects client connections if the server is full to prevent the automatic restart.",
	version = "1.0.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	MaxPlayers = 16;
	MaxPlayersCvar = CreateConVar("sm_rejection_maxplayers", "16", "Maximum number of players allowed on the server.");
	HookConVarChange(MaxPlayersCvar, ChangeMaxPlayers);
}

// This may or may not be needed... I dunno.
public OnMapStart()
	TotalPlayers = 0;

	
public ChangeMaxPlayers( Handle:ConVar, const String:StrOldValue[], const String:StrNewValue[] )
	MaxPlayers = GetConVarInt(MaxPlayersCvar);


public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (TotalPlayers >= MaxPlayers)
	{
		strcopy(rejectmsg, maxlen, "Server is full");
		return false;
	}
	else
	{
		TotalPlayers += 1
		return true;
	}
}

public OnClientDisconnect(client)
	TotalPlayers -= 1;
