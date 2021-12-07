#include <sourcemod>
new Handle:g_hCvarMinimum;
public Plugin:myinfo = 
{
	name = "RCBot thingy",
	author = "Afronanny",
	description = "By request",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=124857"
}

public OnPluginStart()
{
	g_hCvarMinimum = CreateConVar("sm_rcbots_minimum", "16", "Minimum number of players before RCBots stop joining.", FCVAR_SPONLY);
	
}
public OnClientDisconnect(client)
{
	if (GetNumClients() < GetConVarInt(g_hCvarMinimum))
		ServerCommand("rcbotd addbot");
}
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (GetClientCount() == MaxClients)
	{
		ServerCommand("rcbotd kickbot");
	}
	return true;
}

public GetNumClients()
{
	new count;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			count++;
	} 
	return count;
}
public OnMapStart()
{
	if (GetConVarInt(g_hCvarMinimum) > GetNumClients())
	{
		new minimum = GetConVarInt(g_hCvarMinimum);
		while (GetNumClients() < minimum)
		{
			ServerCommand("rcbotd addbot");
		}
	}
}

