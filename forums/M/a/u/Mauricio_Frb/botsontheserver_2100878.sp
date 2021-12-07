/*
	Bots on the server.

	Plugin by Mauricio Frb.

	Description: This plugin add bots on the server according a limit of a real players playing the game.

	Cvar:
	sm_bot_mplayers <(Default: 10)>
	// < > - The number of maximum players that bots can enter the game.
	// Like if sm_bot_mplayers is equal 10 and don't have a player, the number of bots is 0.
	// If have one player, the number of bots is 9.
	// ...
	// And if have 5 players, the number of bots is 5.
	// ...
	// And if have 10 players or more, the number of bots is 0.
	
	Changelog:
	1.0 - First release.
*/

#include <sourcemod>
#pragma semicolon 1

new Handle:Mplayers;
new bool:botsOn = false;

public Plugin:myinfo = 
{
	name = "Bots on the server",
	author = "Mauricio Frb",
	description = "This plugin add bots on the server according a limit of a real players playing the game.",
	version = "1.0",
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	Mplayers = CreateConVar("sm_bot_mplayers", "10", "The number of maximum players that bots can enter the game.", FCVAR_PLUGIN);
	
	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clients = 0;
	
	for(new i = 1; i < GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i)) clients++;
	}
	
	if(clients < GetConVarInt(Mplayers))
	{
		ServerCommand("bot_quota %i", (GetConVarInt(Mplayers) - clients));
		botsOn = true;
	}
	else if(clients >= GetConVarInt(Mplayers) || clients == 0)
	{
		if(botsOn == true)
		{
			ServerCommand("bot_quota 0");
			botsOn = false;
		}
	}
}

public OnPluginEnd()
{
	UnhookEvent("round_start", Event_RoundStart);
}