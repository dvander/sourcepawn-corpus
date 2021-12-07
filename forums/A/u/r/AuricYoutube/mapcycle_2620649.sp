#include <sourcemod>
#include <regex>
#pragma newdecls required

#define DB_NAME			"db_mapcycle"

Handle gH_dbiStorage = null;
Handle gH_RegexId = null;
Handle gH_RegexMap = null;

ConVar gC_OverWriteMapCycle = null;
ConVar gC_WriteDisplayList = null;
int gI_FolderTime = 1;

public Plugin myinfo =
{
	name = "Generate Mapcycle",
	author = "KiD Fearless",
	description = "Scans the maps folder and builds a maplist from it.",
	version = "1.1",
	url = "sourcemod.net"
}
//Code heavily based off of Workshop Map Loader
//https://github.com/nefarius/WorkshopMapLoader

public void OnPluginStart()
{
	RegAdminCmd("sm_build_maplist", Command_BuildMaplist, ADMFLAG_RCON, "Manually scan the maps folder for new maps and add it to the map list.");

	// *** Internals ***
	// Pre-compile regex to improve performance
	// Extracts ID from workshop path
	gH_RegexId = CompileRegex("\\/(\\d*)\\/");
	// Matches workshop map path
	gH_RegexMap = CompileRegex("[^/]+$");
	
	gC_OverWriteMapCycle = CreateConVar("sm_overwrite_mapcycle", "0", "Overwrite The Default Mapcycle?", _, true, 0.0, true, 1.0);
	gC_WriteDisplayList = CreateConVar("sm_write_displaylist", "1", "Creates a maplist containing only displaynames", _, true, 0.0, true, 1.0);
	char error[256];
	gH_dbiStorage = SQLite_UseDatabase(DB_NAME, error, sizeof(error));
	if (gH_dbiStorage == null)
	{
		SetFailState("Could not open database: %s", error);
	}

	AutoExecConfig();
	//Create maplist database.
	DB_CreateTables();
}

public void OnPluginEnd()
{
	DB_PurgeTables();
}

public void OnConfigsExecuted()
{
	int foldertime = GetFileTime("maps", FileTime_LastChange);
	//create the plugins mapcycle if it doesn't overwrite the servers.
	if(!gC_OverWriteMapCycle.BoolValue)
	{
		if(!FileExists("generated_maps.txt"))
		{
			File file = OpenFile("generated_maps.txt", "a");
			file.Close();
		}
	}

	//if the map folder has been changed recently then rescan it.
	if(gI_FolderTime != foldertime)
	{
		DB_PurgeTables();
		gI_FolderTime = foldertime;
		ReadFolder("maps/");
	}

}

public Action Command_BuildMaplist(int client, int args)
{
	ReplyToCommand(client, "[SM] Building maplist.");

	DB_PurgeTables();

	ReadFolder("maps/");

	return Plugin_Handled;
}

void ReadFolder(char[] path)
{
	//allocate resources
	Handle dir = null;
	char buffer[PLATFORM_MAX_PATH + 1];
	char tmp_path[PLATFORM_MAX_PATH + 1];
	char filename[PLATFORM_MAX_PATH];
	FileType type;

	
	dir = OpenDirectory(path);
	if (dir == null)
	{
		LogError("[SM] Couldn't find the maps folder.");
		return;
	}
	
	// Enumerate directory elements
	while(ReadDirEntry(dir, buffer, sizeof(buffer), type))
	{
		int len = strlen(buffer);
		
		// Null-terminate if last char is newline
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}

		// Remove spaces
		TrimString(buffer);

		// Skip empty, current, parent directory, and non-map directories
		if (!StrEqual(buffer, "", false) && !StrEqual(buffer, ".", false) && !StrEqual(buffer, "..", false) && !StrEqual(buffer, "soundcache", false) && !StrEqual(buffer, "cfg", false) && !StrEqual(buffer, "graphs", false))
		{
			// Match files
			if(type == FileType_File)
			{
				strcopy(tmp_path, PLATFORM_MAX_PATH, path[5]);
				StrCat(tmp_path, PLATFORM_MAX_PATH, "/");
				StrCat(tmp_path, PLATFORM_MAX_PATH, buffer);
				// Adds map path to the end of map list
				AddMapToList(tmp_path);
			}
			else // Dive deeper if it's a directory
			{
				strcopy(tmp_path, PLATFORM_MAX_PATH, path);
				StrCat(tmp_path, PLATFORM_MAX_PATH, "/");
				StrCat(tmp_path, PLATFORM_MAX_PATH, buffer);
				ReadFolder(tmp_path);
			}
		}
	}
	//Once it's done looping through the maps folder check which file to write the list to.
	if(gC_OverWriteMapCycle.BoolValue)
	{
		Format(filename, sizeof(filename), "mapcycle.txt");
	}
	else
	{
		Format(filename, sizeof(filename), "generated_maps.txt");
	}
	CreateMapcycleFile(filename);

	// Clean-up
	dir.Close();
}

void AddMapToList(char[] map)
{
	//only process bsp files.
	if (StrEqual(map[strlen(map) - 3], "bsp", false))
	{
		// Cuts off file extension
		map[strlen(map) - 4] = '\0';
		
		//Allocate resources.
		char id[PLATFORM_MAX_PATH];
		char displayName[PLATFORM_MAX_PATH];

		//Match Workshop ID.
		if(MatchRegex(gH_RegexId, map))
		{
			GetRegexSubString(gH_RegexId, 1, id, sizeof(id));
			Format(id, sizeof(id), "workshop/%s/", id);
		}		
		
		//Match the map name.
		MatchRegex(gH_RegexMap, map);
		GetRegexSubString(gH_RegexMap, 0, displayName, sizeof(displayName));

		DB_AddNewMap(id, displayName);
	
	}
}
void CreateMapcycleFile(const char[] path)
{
	if (gH_dbiStorage == null)
	{
		return;
	}
	
	//allocate resources.
	File file = OpenFile(path, "wt");
	File file2 = OpenFile("displaymaps.txt", "wt");
	
	Handle h_Query = null;
	Handle h_Query2 = null;
	char query2[256];
	char query3[256];
	char map[PLATFORM_MAX_PATH];

	if (file == null)
	{
		LogError("Couldn't create '%s', file unchanged", path);
		return;
	}
	if(file2 == null)
	{
		LogError("Couldn't create displaymaps.txt, file unchanged");
		return;
	}

	// Select all the maps in the db
	Format(query2, sizeof(query2), "SELECT WorkshopID || Map FROM db_maplist ORDER BY Map ASC;");
	
	// Enumerate through results and write to file
	SQL_LockDatabase(gH_dbiStorage);
	h_Query = SQL_Query(gH_dbiStorage, query2);
	if (h_Query != null)
	{
		while (SQL_FetchRow(h_Query))
		{
			SQL_FetchString(h_Query, 0, map, sizeof(map));
			WriteFileLine(file, map);
		}
	}
	SQL_UnlockDatabase(gH_dbiStorage);

	if (gC_WriteDisplayList.BoolValue)
	{
		Format(query3, sizeof(query3), "SELECT Map FROM db_maplist ORDER BY Map ASC;");
		SQL_LockDatabase(gH_dbiStorage);
		h_Query2 = SQL_Query(gH_dbiStorage, query3);
		if (h_Query2 != null)
		{
			while (SQL_FetchRow(h_Query2))
			{
				SQL_FetchString(h_Query2, 0, map, sizeof(map));
				WriteFileLine(file2, map);
			}
		}
		SQL_UnlockDatabase(gH_dbiStorage);
	}


	//clean up
	CloseHandle(h_Query);
	CloseHandle(h_Query2);
	CloseHandle(file);
	CloseHandle(file2);
}

//Creates a database with 2 columns. 1 for a possible workshop id, and the other for the actual map name.
void DB_CreateTables()
{
	if (gH_dbiStorage == null)
	{
		return;
	}

	char error[256];

	if (!SQL_FastQuery(gH_dbiStorage, "CREATE TABLE IF NOT EXISTS db_maplist (WorkshopID TEXT, Map TEXT NOT NULL, UNIQUE(Map));"))
	{
		SQL_GetError(gH_dbiStorage, error, sizeof(error));
		SetFailState("Creating db_maplist failed: %s", error);
	}
}

//Adds the map into the database to be used later.
void DB_AddNewMap(char[]id, char[]file)
{
	if (gH_dbiStorage == null)
	{
		return;
	}
	
	char query3[256];
	Format(query3, sizeof(query3), "INSERT OR REPLACE INTO db_maplist VALUES (\"%s\", \"%s\");", id, file);

	SQL_LockDatabase(gH_dbiStorage);
	if (!SQL_FastQuery(gH_dbiStorage, query3))
	{
		char error[256];
		SQL_GetError(gH_dbiStorage, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}
	SQL_UnlockDatabase(gH_dbiStorage);
}

//deletes everything in the database to prevent overlapping mapnames.
void DB_PurgeTables()
{
	if (gH_dbiStorage == null)
	{
		return;
	}

	char error[256];

	if (!SQL_FastQuery(gH_dbiStorage, "DELETE FROM db_maplist;"))
	{
		SQL_GetError(gH_dbiStorage, error, sizeof(error));
		SetFailState("Deleting db_maplist failed: %s", error);
	}
}

