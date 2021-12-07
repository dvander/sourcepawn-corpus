#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "Sapper Points Fix",
	author = "Afronanny",
	description = "Disallow spies from destroying their own sappers",
	version = "1.0",
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	RegConsoleCmd("destroy", Command_Destroy);
}

public Action:Command_Destroy(client, args)
{
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}