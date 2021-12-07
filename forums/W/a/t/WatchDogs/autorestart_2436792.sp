#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "Autorestart",
	author = "[FG] Silent , [W]atch[D]ogs",
	description = "Restarts server at 5:00 am everyday with countdown from 60s",
	version = "1.1.0",
	url = "",
}

public OnPluginStart()
{
	CreateTimer(60.0, CheckTime, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:CheckTime(Handle:timer)
{
	decl String:sTime[16];
	new gettime = GetTime();
	
	FormatTime(sTime, sizeof(sTime), "%H%M", gettime);
	new time = StringToInt(sTime);	
    
	//The time of restart
	if(time == 0500)
	{
	    PrintCenterTextAll("Server Restarts in 60s");
	    PrintHintTextToAll("Server Restarts in 60s");
	    CreateTimer(30.0, C30);
	}
	else
	{
		return;
	}
}

public Action:C30(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 30s");
	PrintHintTextToAll("Server Restarts in 30s");
	CreateTimer(10.0, C20);
}

public Action:C20(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 20s");
	PrintHintTextToAll("Server Restarts in 20s");
	CreateTimer(10.0, C10);
}

public Action:C10(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 10s");
	PrintHintTextToAll("Server Restarts in 10s");
	CreateTimer(1.0, C9);
}

public Action:C9(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 9s");
	PrintHintTextToAll("Server Restarts in 9s");
	CreateTimer(1.0, C8);
}

public Action:C8(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 8s");
	PrintHintTextToAll("Server Restarts in 8s");
	CreateTimer(1.0, C7);
}

public Action:C7(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 7s");
	PrintHintTextToAll("Server Restarts in 7s");
	CreateTimer(1.0, C6);
}

public Action:C6(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 6s");
	PrintHintTextToAll("Server Restarts in 6s");
	CreateTimer(1.0, C5);
}

public Action:C5(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 5s");
	PrintHintTextToAll("Server Restarts in 5s");
	CreateTimer(1.0, C4);
}

public Action:C4(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 4s");
	PrintHintTextToAll("Server Restarts in 4s");
	CreateTimer(1.0, C3);
}

public Action:C3(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 3s");
	PrintHintTextToAll("Server Restarts in 3s");
	CreateTimer(1.0, C2);
}

public Action:C2(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 2s");
	PrintHintTextToAll("Server Restarts in 2s");
	CreateTimer(1.0, C1);
}

public Action:C1(Handle:timer)
{
    PrintCenterTextAll("Server Restarts in 1s");
	PrintHintTextToAll("Server Restarts in 1s");
	Restart();
}

public Restart()
{
	ServerCommand("_restart"),
	LogAction(0, -1, "Gameserver was restarted successfully.");
}