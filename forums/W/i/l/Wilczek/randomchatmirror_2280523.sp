#pragma semicolon 1

#define DEBUG
#define CHAT_PREFIX '@'

#define PLUGIN_AUTHOR "Wilk"
#define PLUGIN_VERSION "0.02"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Random Chat Mirror",
	author = PLUGIN_AUTHOR,
	description = "Randomly mirror client chat messages",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
};

public void OnPluginStart()
{
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
}

public Action:Command_Say(client, const char[] command, argc)
{
	if((client != 0) && IsClientInGame(client))
	{
		char message[192];
		GetCmdArg(1, message, sizeof(message));
		
		if(IsChatTrigger() || GetCmdArgString(message, sizeof(message)) < 1)
		{
			return Plugin_Continue;
		}
		
		if(message[1] == CHAT_PREFIX)
			return Plugin_Continue;
				
		char rMessage[192];
		for(new x = strlen(message)-1, y = 0; x+1 ^ 0; --x, ++y)
		{
			rMessage[x] = message[y];
		}
	
		if(GetURandomFloat() < 0.2)
		{
			FakeClientCommand(client,"%s %s", command, rMessage);
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}