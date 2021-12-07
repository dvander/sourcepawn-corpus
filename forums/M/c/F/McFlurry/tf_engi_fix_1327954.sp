#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Engi Exploit Fix",
	author = "McFlurry",
	description = "Blocks the new exploit",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	RegConsoleCmd("build", ExploitBlock);
}

public Action:ExploitBlock(client, args)
{
	if(args > 1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}	