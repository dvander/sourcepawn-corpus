#pragma semicolon 1

#include <sourcemod>
#include <date>

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name		= "Test",
	author		= "FrozDark",
	description	= "Test",
	version		= PLUGIN_VERSION,
	url			= "www.hlmod.ru"
}

public OnPluginStart()
{
	RegServerCmd("date_test", Command_Test);
}

public Action:Command_Test(args)
{
	decl String:buffer[64];
	
	new time = GetTime();
	
	FormatTime(buffer, sizeof(buffer), "%Y", time);
	new year = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%m", time);
	new month = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%d", time);
	new day = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%H", time);
	new hour = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%M", time);
	new minute = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%S", time);
	new seconds = StringToInt(buffer);
	
	new newtime = DateToTimeStamp(day, month, year, hour, minute, seconds);
	FormatTime(buffer, sizeof(buffer), "%d.%m.%Y %H:%M:%S", newtime);
	
	PrintToServer("old - %d.%d.%d %d:%d:%d", day, month, year, hour, minute, seconds);
	
	PrintToServer("new - %s", buffer);
	
	PrintToServer("Current - %d", time);
	PrintToServer("Result - %d", newtime);
	
	if (time == newtime)
	{
		PrintToServer("%d == %d", time, newtime);
	}
}