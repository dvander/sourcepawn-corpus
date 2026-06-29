#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


new Handle:g_File = INVALID_HANDLE;
new String:sPath[256];
new String:ismap[64];
new change_map;


public Plugin:myinfo = 
{
	name = "[Any]The server is turn on and returns to the last game map.",
	author = "AK978",
	version = "1.1"
}

public OnPluginStart()
{
	g_File = CreateKeyValues("file");
	BuildPath(Path_SM, sPath, 255, "logs/save_map.txt");	
	
	CreateConVar("sm_default_map", "c1m1_hotel", "default map", 0);

	if (FileExists(sPath))
	{
		FileToKeyValues(g_File, sPath);
		
		loadfile();
		//ServerCommand("changelevel %s", ismap);
		ForceChangeLevel(ismap, "save map");
	}
	else
	{
		KeyValuesToFile(g_File, sPath);
	}
	AutoExecConfig(true, "save_map");
}

public OnMapStart()
{	
	char mCurrent[64];
	GetCurrentMap(mCurrent, sizeof(mCurrent));
	
	change_map++;
	if (change_map > 1)
	{
		if (StrEqual(mCurrent, ismap, false))
		{
			char maps[64];
			GetConVarString(FindConVar("sm_default_map"), maps, sizeof(maps));
			strcopy(ismap, 64, maps);
		}
		else
		{
			strcopy(ismap, 64, mCurrent);
		}		
		savefile();
	}
}

loadfile()
{
	KvJumpToKey(g_File, "save_map", true);
	KvGetString(g_File, "map", ismap, sizeof(ismap));
	KvGoBack(g_File);	
}

savefile()
{
	KvJumpToKey(g_File, "save_map", true);
	KvSetString(g_File, "map", ismap);
	KvRewind(g_File);
	KeyValuesToFile(g_File, sPath);
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}