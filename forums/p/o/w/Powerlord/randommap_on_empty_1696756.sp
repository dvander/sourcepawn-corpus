#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Randommap On Server Empty",
	author = "Powerlord",
	description = "Run the randommap command when the last non-bot player disconnects",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=183573"
}

public OnPluginStart()
{
	CreateConVar("rose_version", VERSION, "Randommap On Server Empty version.", FCVAR_DONTRECORD | FCVAR_NOTIFY);
}

public OnClientDisconnect_Post(client)
{
	new bool:playersPresent = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			playersPresent = true;
			break;
		}
	}
	
	if (playersPresent)
		ServerCommand("randommap");
}