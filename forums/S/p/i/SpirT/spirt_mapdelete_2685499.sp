#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "SpirT"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>

int enable;

char file[512];
char fileDir[512];

ConVar g_enable;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SpirT] Map Delete",
	author = PLUGIN_AUTHOR,
	description = "Deletes the default CS:GO Maps after a steam update. Plugin will check for that maps when it loads",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_enable = CreateConVar("spirt_mapdel_enable", "1", "Enable / Disable Auto Map Deleter");
	
	BuildPath(Path_SM, file, sizeof(file), "configs/SpirT/maplist.txt");
	BuildPath(Path_SM, fileDir, sizeof(fileDir), "configs/SpirT/");
	
	//Create Config Dir is it not exists
	if(!DirExists(fileDir))
	{
		CreateDirectory(fileDir, 511);
		PrintToServer("[SpirT - MAP DELETER] Config Dir was created because it didn't exist.");
	}
	
	//Create file if not exists
	if(!FileExists(file))
	{
		File create = OpenFile(file, "w");
		CloseHandle(create);
		PrintToServer("[SpirT - MAP DELETER] Config File was created because it didn't exist.");
	}
	
	AutoExecConfig(true, "spirt.mapdelete", "SpirT");
	StartDeletingMaps();
}

void cvars()
{
	enable = GetConVarInt(g_enable);
}

void StartDeletingMaps()
{
	cvars();
	
	if(enable != 1)
	{
		PrintToServer("[SpirT - MAP DELETER] Maps are not being deleted because plugin is disabled.");
		return;
	}
	
	File handle = OpenFile(file, "r+");
	char fileLine[256];
	while(ReadFileLine(handle, fileLine, sizeof(fileLine)))
	{
		TrimString(fileLine);
		char MapFileString[256];
		Format(MapFileString, sizeof(MapFileString), "maps/%s", fileLine);
		
		if(!FileExists(MapFileString))
		{
			PrintToServer("[SpirT - MAP DELETER] File '%s' does not exist. Skipping.", MapFileString);
			continue;
		}
		
		DeleteFile(fileLine);
		PrintToServer("[SpirT - MAP DELETER] File '%s' deleted successfully.", MapFileString);
	}
	
	CloseHandle(handle);
	return;
}