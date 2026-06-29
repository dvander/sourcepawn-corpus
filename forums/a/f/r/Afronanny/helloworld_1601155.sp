#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Hello, World!",
	author = "Afronanny",
	description = "k",
	version = "1.0",
	url = "http://www.com/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_helloworld", Command_HelloWorld);
}

public Action:Command_HelloWorld(client, args)
{
	ReplyToCommand(client, "Hello, World!");
	return Plugin_Handled;
}
