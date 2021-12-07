#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

public Plugin myinfo =
{
	name = "shavit - Zoned Maps",
	author = "SlidyBat",
	description = "Shows admins zoned/unzoned maps",
	version = "1.1",
	url = "",	
};

Database g_hDatabase;
char g_cMySQLPrefix[32];

ArrayList g_aAllMapsList;
ArrayList g_aZonedMapsList;

int g_iMapFileSerial = -1;

bool g_bReadFromMapsFolder = true;

public void OnPluginStart()
{
	g_aAllMapsList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	g_aZonedMapsList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

	RegAdminCmd("sm_zonedmaps", Command_ZonedMaps, ADMFLAG_CHANGEMAP, "sm_zonedmaps - Shows admin zoned maps");
	RegAdminCmd("sm_unzonedmaps", Command_UnzonedMaps, ADMFLAG_CHANGEMAP, "sm_unzonedmaps - Shows admin unzoned maps");
	RegAdminCmd("sm_allmaps", Command_AllMaps, ADMFLAG_CHANGEMAP, "sm_allmaps - Shows admin all maps");
	
	LoadAllMaps();
}

public void OnMapStart()
{
	LoadAllMaps();	
}

public void OnMapEnd()
{
	g_iMapFileSerial = -1;	
}

public Action Command_ZonedMaps(int client, int args)
{
	OpenMapsMenu(client, true);
	return Plugin_Handled;
}

public Action Command_UnzonedMaps(int client, int args)
{
	OpenMapsMenu(client, false);
	return Plugin_Handled;
}

public Action Command_AllMaps(int client, int args)
{
	OpenAllMapsMenu(client);
	return Plugin_Handled;
}

public void OpenMapsMenu(int client, bool zoned)
{
	if (!g_aZonedMapsList.Length)
	{
		PrintToChat(client, "No zoned maps found, possible database connection error ...");
		LogError("No zoned maps found, possible database connection error ...");
		return;	
	}
	else if (!zoned && !g_aAllMapsList.Length)
	{
		PrintToChat(client, "No map list found, possible file loading error ...");
		LogError("No map list found, possible file loading error ...");
		return;
	}
		
	char buffer[512];
	Menu menu = new Menu(MapsMenuHandler);

	Format(buffer, sizeof(buffer), "%s Maps:", zoned ? "Zoned" : "Unzoned");
	Format(buffer, sizeof(buffer), "%s \n", buffer);
	menu.SetTitle(buffer);

	if (zoned)
	{
		for (int i = 0; i < g_aZonedMapsList.Length; i++)
		{	
			g_aZonedMapsList.GetString(i, buffer, sizeof(buffer));
			if (FindMap(buffer, buffer, sizeof(buffer)) != FindMap_NotFound)
			{	
				menu.AddItem(buffer, buffer);	
			}
		}
	}
	else
	{
		for (int i = 0; i < g_aAllMapsList.Length; i++)
		{	
			g_aAllMapsList.GetString(i, buffer, sizeof(buffer));
			if (FindMap(buffer, buffer, sizeof(buffer)) != FindMap_NotFound)
			{	
				if (g_aZonedMapsList.FindString(buffer) < 0)
				{	
					menu.AddItem(buffer, buffer);
				}
			}
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public void OpenAllMapsMenu(int client)
{
	if (!g_aAllMapsList.Length)
	{	
		LogError("Map List Failed");
		return;
	}
	
	char buffer[512];
	Menu menu = new Menu(MapsMenuHandler);

	Format(buffer, sizeof(buffer), "All Maps:");
	Format(buffer, sizeof(buffer), "%s \n", buffer);
	menu.SetTitle(buffer);
	
	for (int i = 0; i < g_aAllMapsList.Length; i++)
	{
		g_aAllMapsList.GetString(i, buffer, sizeof(buffer));
		if (FindMap(buffer, buffer, sizeof(buffer)) != FindMap_NotFound)
		{
			menu.AddItem(buffer, buffer);		
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MapsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char map[PLATFORM_MAX_PATH];
	
		GetMenuItem(menu, param2, map, sizeof(map));
		OpenChangeMapMenu(param1, map);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void OpenChangeMapMenu(int client, char[] map)
{
	char buffer[512];
	Menu menu = new Menu(ChangeMapMenuHandler);

	Format(buffer, sizeof(buffer), "Change map to %s?\n \n", map);
	menu.SetTitle(buffer);

	menu.AddItem(map, "Yes");
	menu.AddItem("no", "No");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ChangeMapMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			char map[PLATFORM_MAX_PATH];
			
			GetMenuItem(menu, param2, map, sizeof(map));
			
			PrintToChatAll("[SM] Changing map to %s ...", map);
			
			DataPack data;
			CreateDataTimer(2.0, Timer_ChangeMap, data);
			data.WriteString(map);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void LoadZonedMapsCallback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[SQL Error] (LoadMapZonesCallback) - %s", error);
		return;	
	}

	while (results.FetchRow())
	{
		char map[PLATFORM_MAX_PATH];
		
		SQL_FetchString(results, 0, map, sizeof(map));
		g_aZonedMapsList.PushString(map);	
	}
}

public void LoadAllMaps()
{
	SQL_SetPrefix();
	
	g_aAllMapsList.Clear();
	g_aZonedMapsList.Clear();

	if (g_bReadFromMapsFolder)
	{
		LoadFromMapsFolder(g_aAllMapsList);
	}
	else if (ReadMapList(g_aAllMapsList, g_iMapFileSerial, "timer-zonedmaps", MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER) != null)
	{
		if (g_iMapFileSerial == -1)
		{	
			LogError("Unable to create a valid map list.");
		}
	}
	
	char error[256];
	g_hDatabase = SQL_Connect("shavit", true, error, sizeof(error));
	
	if (g_hDatabase == INVALID_HANDLE)
	{
		delete g_hDatabase;
		delete g_aAllMapsList;
		delete g_aZonedMapsList;
		SetFailState("[SQL Error] (Failed to connect to database) - %s", error);	
	}
	
	char query[512];

	Format(query, sizeof(query), "SELECT map FROM `%smapzones` WHERE type=1 ORDER BY `map`", g_cMySQLPrefix);
	g_hDatabase.Query(LoadZonedMapsCallback, query, _, DBPrio_High);
}

bool LoadFromMapsFolder(ArrayList array)
{
	//from yakmans maplister plugin
	Handle mapdir = OpenDirectory("maps/");
	char name[PLATFORM_MAX_PATH];
	FileType filetype;
	int namelen;
	
	if (mapdir == INVALID_HANDLE)
		return false;
		
	if (mapdir != INVALID_HANDLE)
	{
		while (ReadDirEntry(mapdir, name, sizeof(name), filetype))
		{
			if (filetype != FileType_File)
				continue;
					
			namelen = strlen(name) - 4;
			if (StrContains(name, ".bsp", false) != namelen)
				continue;
					
			name[namelen] = '\0';
				
			array.PushString(name);
		}

		CloseHandle(mapdir);
		mapdir = INVALID_HANDLE;
	}

	return true;
}

void SQL_SetPrefix()
{
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/shavit-prefix.txt");

	File fFile = OpenFile(sFile, "r");

	if (fFile == null)
	{
		SetFailState("Cannot open \"configs/shavit-prefix.txt\". Make sure this file exists and that the server has read permissions to it.");
	}

	char sLine[PLATFORM_MAX_PATH * 2];

	while (fFile.ReadLine(sLine, sizeof(sLine)))
	{
		TrimString(sLine);
		strcopy(g_cMySQLPrefix, sizeof(g_cMySQLPrefix), sLine);

		break;
	}

	delete fFile;
}

public Action Timer_ChangeMap( Handle timer, DataPack data )
{
	char map[PLATFORM_MAX_PATH];
	data.Reset();
	data.ReadString( map, sizeof(map) );
	
	SetNextMap( map );
	ForceChangeLevel( map, "RTV Mapvote" );
}