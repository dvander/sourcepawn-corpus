#include <sourcemod>

public Plugin myinfo = 
{
	name = "[SRCDS Manager] Crash Check Update File Mode",
	author = "",
	description = "",
	version = "1.0",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	CreateTimer(10.0, UpdateFile, _, TIMER_REPEAT);
}
public Action UpdateFile(Handle timer)
{
	Handle hFile = OpenFile("xnet_crash_filetime.txt", "w");
	if (hFile != INVALID_HANDLE)
	{
		WriteFileLine(hFile, "x");
		delete(hFile);
	}
}
