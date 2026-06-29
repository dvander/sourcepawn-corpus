#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name		= "CS:GO Custom Map Downloader",
	author		= "SlaneR",
	description	= "Automatically add maps to downloads table.",
	version		= "1.0.0",
	url			= "None"
}

public OnMapStart()
{
	new String:strMap[128];
	GetCurrentMap(strMap, sizeof(strMap));
	Format(strMap, sizeof(strMap), "maps/%s.bsp", strMap);
	AddFileToDownloadsTable(strMap);
}