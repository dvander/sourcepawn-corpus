#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar hDefaultMap;
KeyValues g_File;
char sPath[256], ismap[64];
int change_map;

public Plugin myinfo = 
{
	name = "[Any]The server is turn on and returns to the last game map.",
	author = "AK978",
	version = "1.1"
}

public void OnPluginStart()
{
	g_File = new KeyValues("file");
	BuildPath(Path_SM, sPath, 255, "logs/save_map.txt");	

	hDefaultMap = CreateConVar("sm_default_map", "c1m1_hotel", "default map", FCVAR_NOTIFY);

	if (FileExists(sPath))
	{
		FileToKeyValues(g_File, sPath);
		loadfile();
		//ServerCommand("changelevel %s", ismap);
		ForceChangeLevel(ismap, "save map");
	}
	else KeyValuesToFile(g_File, sPath);

	AutoExecConfig(true, "save_map");
}

public void OnMapStart()
{
	char mCurrent[64];
	GetCurrentMap(mCurrent, sizeof(mCurrent));

	change_map++;
	if (change_map > 1)
	{
		if (StrEqual(mCurrent, ismap, false))
		{
			char maps[64];
			hDefaultMap.GetString(maps, sizeof(maps));
			strcopy(ismap, 64, maps);
		}
		else strcopy(ismap, 64, mCurrent);
		savefile();
	}
}

void loadfile()
{
	g_File.JumpToKey("save_map", true);
	g_File.GetString("map", ismap, sizeof(ismap));
	g_File.GoBack();	
}

void savefile()
{
	g_File.JumpToKey("save_map", true);
	g_File.SetString("map", ismap);
	g_File.Rewind();
	KeyValuesToFile(g_File, sPath);
}

stock bool IsValidClient(int client) 
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}
