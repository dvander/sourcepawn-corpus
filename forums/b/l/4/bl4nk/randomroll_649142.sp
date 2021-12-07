#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

// Functions
public Plugin:myinfo =
{
	name = "RandomRoll",
	author = "bl4nk",
	description = "Gives a random number 0-100",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:Command_Say(client, args)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;

		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}

	if(strcmp(text[startidx], "!roll") == 0)
	{
		SetRandomSeed(RoundFloat(GetEngineTime()));
		PrintToChatAll("[SM] %N rolled a %i.", client, GetRandomInt(0, 100));
	}

	return Plugin_Continue;
}