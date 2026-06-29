#include <sourcemod>

public Plugin:myinfo =    
{    
    name = "Wait Command",    
    author = "Headline",    
    description = "Adds Wait Command",    
    version = "1.0",    
    url = "http://michaelwflaherty.com"    
};

public OnPluginStart()
{
	RegConsoleCmd("wait", Command_Wait, "Adds wait command");
}

public Action:Command_Wait(client, args)
{
	return Plugin_Handled;
}