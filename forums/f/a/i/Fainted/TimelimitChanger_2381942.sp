/*
	Last update 04/11/2015
	
	by Fainted
*/


#include <sourcemod>

/*

	Plugin Public Information
	
*/

public Plugin Info =

{
	name = "Timelimit Changer",
	author = "Fainted",
	description = "Changes the timelimit based on the shortmaplist file.",
	version = "1.0",
	url = ""

};

public void OnPluginStart()
{	
	OnMapStart();
}

public void OnMapStart() {
		decl String:path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "shortmaplist.txt");

		if(FileExists(path, 0) == 0) 
		{
			new Handle:FileHandle = OpenFile(path,"w");
			CloseHandle(FileHandle);
		}
		decl String:CurMap[64];
		GetCurrentMap(CurMap, sizeof(CurMap));
	
		decl String:line[128];
		new Handle:fileHandle = OpenFile(path, "rt"); 
		while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
		{
			if(strcmp(CurMap, line, 0) == 0)
			{
				ServerCommand("mp_timelimit 20");
			}
		}
		CloseHandle(fileHandle);
	return Plugin_Handled;
}