#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new Handle:timerStart = INVALID_HANDLE;

// Functions
public Plugin:myinfo =
{
	name = "5-Minute Timer",
	author = "bl4nk",
	description = "Use '!start' and '!stop' to control a 5-minute timer",
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

	if (strcmp(text[startidx], "!start") == 0)
	{
		if (timerStart != INVALID_HANDLE)
		{
			PrintToChat(client, "[SM] The timer has already started. Use '!stop' to stop it.");
		}
		else
		{
			timerStart = CreateTimer(300.0, timer_Time, _, TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("[SM] 5-Minute timer started!");
		}

		return Plugin_Handled;
	}
	else if (strcmp(text[startidx], "!stop") == 0)
	{
		if (timerStart != INVALID_HANDLE)
		{
			KillTimer(timerStart);
			timerStart = INVALID_HANDLE;

			PrintToChatAll("[SM] Timer stopped!");
		}
		else
		{
			PrintToChat(client, "[SM] There is no active timer. Use '!start' to start one.");
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:timer_Time(Handle:timer)
{
	PrintToChatAll("[SM] Time has run out!");
	timerStart = INVALID_HANDLE;
}