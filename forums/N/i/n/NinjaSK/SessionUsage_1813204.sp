#include <sourcemod>
#pragma semicolon 1
#define PL_VERSION "1.1"
 
public Plugin:myinfo =
{
        name = "SessionUsage",
        author = "NinjaSK",
        description= "Will post to player how long he played in the current session.",
        version = "1.0",
        url = "http://www.GameX.co.il"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_usage", Command_Usage);
}
 
public Action:Command_Usage(client, args)
{
	if(IsClientInGame(client))
	{
		new Float:usage = GetClientTime(client);
		new mins = RoundToFloor(usage) / 60;
		new hours = mins / 60;
		for(new i = 0;i < hours; i++)
		{
			mins -= 60;
		}
		if(hours == 0 && mins == 0)
			PrintToChat(client, "\x04SESSION: \x03%d \x01hours \x03%d \x01minutes.", hours, mins);
		else if(hours == 0 && mins < 2)
			PrintToChat(client, "\x04SESSION: \x03%d \x01hours \x03%d \x01minute.", hours, mins);
		else if(hours < 2 && mins == 0)
			PrintToChat(client, "\x04SESSION: \x03%d \x01hour \x03%d \x01minutes.", hours, mins);
		else if(hours < 2 && mins < 2)
			PrintToChat(client, "\x04SESSION: \x03%d \x01hour \x03%d \x01minute.", hours, mins);
		else if(hours < 2 && mins > 1)
			PrintToChat(client, "\x04SESSION: \x03%d \x01hour \x03%d \x01minutes.", hours, mins);
		else if(hours > 1 && mins < 2)
			PrintToChat(client, "\x04SESSION: \x03%d \x01hours \x03%d \x01minute.", hours, mins);
		else
			PrintToChat(client, "\x04SESSION: \x03%d \x01hours \x03%d \x01minutes.", hours, mins);
	}
	return Plugin_Handled;
}