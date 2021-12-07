#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D2] Join Announcer",
	author = "McFlurry",
	description = "Announces joins",
	version = PLUGIN_VERSION,
	url = "origamigus.magix.net"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
}

public OnClientConnected(client)
{
	if(!IsFakeClient(client)) PrintToChatAll("Player %N has joined the game.", client);
}	