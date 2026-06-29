#include <sourcemod>

#define CFG_PATH "sourcemod/mapconfig/"
#define PATH "cfg/sourcemod/mapconfig/"

public Plugin:myinfo = {
	name = "MapConfig",
	author = "MagicYan",
	description = "Loading cfg file with a specific map",
	version = "0.1",
	url = "http://www.sourcemod.net/"
};

public OnConfigsExecuted()
{
	new String:MapName[50];
	new String:MapFile[100];
	GetCurrentMap(MapName, sizeof(MapName));
	FormatEx(MapFile, sizeof(MapFile), "%s%s.cfg", PATH, MapName);
	
	if(FileExists(MapFile))
	{
		PrintToServer("[MapConfig] Loading %s config file", MapName)
		ServerCommand("exec %s%s.cfg", CFG_PATH, MapName);
	}
}
