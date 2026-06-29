/**
 * Hooks the say, and say_team commands, so that the Dystopia callvoting commands can be called with normal chat triggers.
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Callvote Chat Triggers",
	author = "emjay",
	description = "Hooks say and say_team to provide chat triggers for callvote.",
	version = "3.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2385072"
};

public void OnPluginStart()
{
	/* Hook the say and say_team commands. */
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public Action Command_Say(int client, const char[] command, int argc)
{
	/* Create a buffer for the submitted text, and a variable to contain the index to begin comparing from. */
	char text[192];
	int startidx = 0;

	/* If no text was submitted to chat, then allow the command to continue normally. */
	if(GetCmdArgString( text, sizeof(text) ) < 1)
	{
		return Plugin_Continue;
	}

	/* if the final character of the submitted text is " then change it to a NUL, and change the start index to 1. 
	 * (So as to skip the quotation mark at the beginning of the string.)
	 */ 
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if(text[startidx] == '/')
	{
		if(strncmp(text[startidx + 1], "callvote", 8) == 0)
		{
			FakeClientCommandEx(client, text[startidx + 1]);
			return Plugin_Handled;
		}
	}
	else if(text[startidx] == '!' && strncmp(text[startidx + 1], "callvote", 8) == 0)
	{
		FakeClientCommandEx(client, text[startidx + 1]);
	}
	
	return Plugin_Continue;
}