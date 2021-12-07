#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "RTD Roll To Die",
	author = "xDeRpYx",
	description = "Kills players who type rtd, followed by a humorous message",
	version = "1.0",
	url = "http://www.derpygamers.com"
}
public OnPluginStart()
{
    RegConsoleCmd("rtd", Command_YOUMUSTDIE); 
}

public Action:Command_YOUMUSTDIE(client, args)
{   
	if(!client)
    {
        ReplyToCommand(client, "\x04NEIN! Don't do this on the console.");
        return Plugin_Handled;
    }
    if(!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "\x04Lol you're dead silly.");
        return Plugin_Handled;
    }
    
	ForcePlayerSuicide(client);
	PrintToChat(client, "\x04LOL YOU TRIED TO USE RTD, YOU FAIL!");
	PrintToChat(client, "\x04LOL YOU TRIED TO USE RTD, YOU FAIL!");
	PrintToChat(client, "\x04LOL YOU TRIED TO USE RTD, YOU FAIL!");
	PrintToChat(client, "\x04LOL YOU TRIED TO USE RTD, YOU FAIL!");
	return Plugin_Handled;        
}