#include <sourcemod>
#include <sdktools>
 
public Plugin:myinfo =
{
	name = "Suicide",
	author = "BlackWidow",
	description = "A simple plugin to kill yourself",
	version = "1",
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	RegConsoleCmd("killme", Command_killme) 
}

public Action:Command_killme(client, args)
{
	ForcePlayerSuicide(client);
}