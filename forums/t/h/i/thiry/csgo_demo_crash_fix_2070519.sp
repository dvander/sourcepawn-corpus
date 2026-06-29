#include<sourcemod>
#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo =
{
	name = "CS:GO DEMO Crash Fix",
	author = "Thiry",
	description = "This plugin can fix demo crash caused by tv_autorecord 1.",
	version = PLUGIN_VERSION,
	url = "http://blog.five-seven.net/"
};
new Handle:cvar_tv_enable;
new Handle:cvar_tv_autorecord;

public OnPluginStart()
{
    cvar_tv_enable=FindConVar("tv_enable");
    cvar_tv_autorecord=FindConVar("tv_autorecord");
    HookConVarChange(cvar_tv_enable,Force_TV_Enable);
    HookConVarChange(cvar_tv_autorecord,Force_AutoRecord_Disable);
}

public Force_TV_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    PrintToServer("tv_enable is forced to 1");
    SetConVarInt(cvar,1);
}

public Force_AutoRecord_Disable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    PrintToServer("tv_autorecord is forced to 0");
    SetConVarInt(cvar,0);
}

public OnMapStart()
{
    CreateTimer(5.0,StartRecord);
}

public Action:StartRecord(Handle:timer,any:client)
{
    new String:year[16];
    new String:month[16];
    new String:date[16];
    new String:hour[16];
    new String:minute[16];
    new String:map[128];

    //tv_autorecord format
    FormatTime(year, sizeof(year), "%Y");
    FormatTime(month, sizeof(month), "%m");
    FormatTime(date, sizeof(date), "%d");
    FormatTime(hour, sizeof(hour), "%H");
    FormatTime(minute, sizeof(minute), "%M");
    GetCurrentMap(map,sizeof(map));

    ReplaceString(map,sizeof(map),"/","_");//workshop

    ServerCommand("tv_record auto-%s%s%s-%s%s-%s",year,month,date,hour,minute,map);
    PrintToServer("demo record has started.");
}