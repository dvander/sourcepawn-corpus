#pragma semicolon 1

#include <sourcemod>

#define TIMER_INTERVAL 	1800.0 	// You can change: Interval In Seconds To Report Players Count In LogFile (It's Float)


new String:logfile[PLATFORM_MAX_PATH];
new PlayersCount = 0;


public Plugin:myinfo = 
{
	name = "Server Popularity",
	author = "[W]atch [D]ogs",
	description = "",
	version = "1.0"
};

public OnPluginStart()
{
	decl String:date[64], String:sPath[PLATFORM_MAX_PATH];
	FormatTime(date, sizeof(date), "%d-%m-%y", -1);
	Format(sPath, sizeof(sPath), "logs/Players_%s.log", date);
	BuildPath(Path_SM, logfile, sizeof(logfile), sPath);
	
	CreateTimer(TIMER_INTERVAL, ReportOnlinePlayers, _, TIMER_REPEAT);
}

public Action:ReportOnlinePlayers(Handle:timer)
{
	LogToFileEx(logfile, "*** Online Players: %i ***", PlayersCount);
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client))
	{
		PlayersCount++;
		LogToFileEx(logfile, "+++ %L Connected  -  Players: %i +++", client, PlayersCount);
		
		if(PlayersCount == MAXPLAYERS)
		{
			LogToFileEx(logfile, "*** Your Server Is Full ! ***");
		}
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		PlayersCount--;
		LogToFileEx(logfile, "--- %L Disconnected  -  Players: %i ---", client, PlayersCount);
	}
}
