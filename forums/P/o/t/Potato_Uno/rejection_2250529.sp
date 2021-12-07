
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

public ChangeMaxPlayers( Handle:ConVar, const String:StrOldValue[], const String:StrNewValue[] )
	MaxPlayers = GetConVarInt(MaxPlayersCvar);


public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (TotalPlayers == MaxPlayers)
	{
		// How the hell do I fill in the rejection message?
		// rejectmsg = "Server is full.";
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
