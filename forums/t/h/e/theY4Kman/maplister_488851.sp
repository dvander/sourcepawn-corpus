// 1.6.2 --- This is modified to save to mapall.txt instead of maplist.txt
// 1.6.3 --- This is modified to add in the current list of stock maps
// 1.6.4 --- Added support for downloads/maps dir.
// 1.6.5 --- Tabs cleanup, reorganization of MapLister func.
// 1.6.6 --- Seperate output by stock/custom.
// 1.6.7 --- use defines for files, change default back to maplist.txt for compatibility, add cvar sm_maplist_file to allow changing the def file we output to.
// 1.6.8 --- use cfg file for setting default map file


#include <sourcemod>

#pragma semicolon 1


#define PLUGIN_VERSION "1.6.8"
#define DEFAULT_MAP_FILE "maplist.txt"
#define DEFAULT_EXCLUDES_FILE "configs/maplister_excludes.cfg"
#define DEFAULT_CONFIG_FILE "configs/maplister.cfg"


new String:LEFT4DEAD_DIR[] = "left4dead";
new bool:g_writeOnMapChange;
new Handle:g_hExcludeMaps = INVALID_HANDLE;
new bool:g_bIsL4D = false;
//new Handle:g_hCvarDefaultMapFile = INVALID_HANDLE;
new String:g_sDefaultMapFile[PLATFORM_MAX_PATH];



enum OutputType
{
	Output_Console = 0,
	Output_File = 1,
};


public Plugin:myinfo = {
	name = "Maplister",
	author = "theY4Kman",
	description = "Reads the /maps and /download/maps (or /addons for L4D) folders to write/display a maplist.",
	version = PLUGIN_VERSION,
	url = "http://y4kstudios.com/sourcemod/"
};


public OnPluginStart()
{
	new String:gamedir[32];
	GetGameFolderName(gamedir, sizeof(gamedir));
	
	if (strncmp(gamedir, LEFT4DEAD_DIR, sizeof(LEFT4DEAD_DIR), false) == 0)
		g_bIsL4D = true;
	
	
	// Everyone is allowed to use sm_maplist
	// But only Admins can use sm_writemaplist
	RegConsoleCmd("sm_maplist", MapListCmd);
	RegAdminCmd("sm_writemaplist", WriteMapListCmd, ADMFLAG_GENERIC);

	
	// Should this handle be global instead?
	new Handle:writeOnMapChange = CreateConVar("sm_auto_maplist", "1",
		"If set to 1 will write a new maplist whenever the map changes.");

	if (writeOnMapChange == INVALID_HANDLE)
		writeOnMapChange = FindConVar("sm_auto_maplist");
	
	HookConVarChange(writeOnMapChange, auto_maplistChanged);
	g_writeOnMapChange = GetConVarBool(writeOnMapChange);


	CreateConVar("sm_maplister_version", PLUGIN_VERSION, 
		"The version of the SourceMod plugin MapLister, by theY4Kman",
		FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN);
		
	
	// Open excludes file
	decl String:excludeMaps[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, excludeMaps, sizeof(excludeMaps), DEFAULT_EXCLUDES_FILE);
	g_hExcludeMaps = OpenFile(excludeMaps, "r");

	
	// Open cfg file
	decl String:sConfigFile[PLATFORM_MAX_PATH];
	new Handle:hConfigFile = INVALID_HANDLE;
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), DEFAULT_CONFIG_FILE);
	hConfigFile = OpenFile(sConfigFile, "r");

	// Read first line
	if (hConfigFile != INVALID_HANDLE)
	{
		FileSeek(hConfigFile, SEEK_SET, 0);
		ReadFileLine(hConfigFile, g_sDefaultMapFile, sizeof(g_sDefaultMapFile));
		
		if (strlen(g_sDefaultMapFile) > 1)
		{
			PrintToServer("[MapLister] File read from config is %s", g_sDefaultMapFile);
		}
		else
		{
			strcopy(g_sDefaultMapFile, sizeof(g_sDefaultMapFile), DEFAULT_MAP_FILE);
			PrintToServer("[MapLister] Error reading from config file");
		}
	
		CloseHandle(hConfigFile);
	}
	else
	{
		strcopy(g_sDefaultMapFile, sizeof(g_sDefaultMapFile), DEFAULT_MAP_FILE);
		PrintToServer("[MapLister] Error finding config file");
	}

	
	PrintToServer("[Maplister] Loaded");
}

public OnPluginEnd()
{
	if (g_hExcludeMaps != INVALID_HANDLE)
		CloseHandle(g_hExcludeMaps);
}

public OnMapStart()
{
	if (g_writeOnMapChange)
	{
		
		MapLister(Output_File, g_sDefaultMapFile, 0, "");
	}
}

public auto_maplistChanged(Handle:convar, const String:oldValue[],
						   const String:newValue[])
{
	g_writeOnMapChange = GetConVarBool(convar);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ListMapsToClient", native_MapList);
	CreateNative("WriteNewMapList", native_WriteMapList);
	
	return APLRes_Success;
}

public native_MapList(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client > GetMaxClients() || client < 0)
		return ThrowError("Client index %d is invalid", client);
	else if(!IsClientConnected(client))
		return ThrowError("Client %d is not connected", client);
	
	decl String:filter[PLATFORM_MAX_PATH];
	filter[0] = '\0';
	
	if (numParams > 1)
		GetNativeString(2, filter, sizeof(filter));
	
	MapLister(Output_Console, "", client, filter);
	
	return true;
}

public native_WriteMapList(Handle:plugin, numParams)
{
	decl String:filter[PLATFORM_MAX_PATH];
	filter[0] = '\0';
	
	if (numParams > 1)
		GetNativeString(2, filter, sizeof(filter));
	
	decl String:path[PLATFORM_MAX_PATH];
	GetNativeString(1, path, sizeof(path));
	
	return MapLister(Output_File, path, 0, filter);
}

public Action:MapListCmd(client, args)
{
	decl String:filter[PLATFORM_MAX_PATH];
	filter[0] = '\0';
	
	if (args >= 1)
		GetCmdArg(1, filter, sizeof(filter));
	
	MapLister(Output_Console, "", client, filter);
	
	return Plugin_Handled;
}

public Action:WriteMapListCmd(client, args)
{
	if (args > 2)
	{
		ReplyToCommand(client, "Too many arguments.");
		ReplyToCommand(client, "Usage: sm_writemaplist <output file> [filter]");
		
		return Plugin_Handled;
	}
	
	decl String:filename[PLATFORM_MAX_PATH];
	decl String:filter[PLATFORM_MAX_PATH];
	filter[0] = '\0';
	
	if (args >= 1)
	{
		GetCmdArg(1, filename, sizeof(filename));
	}
	else
	{
		strcopy(filename, sizeof(filename), g_sDefaultMapFile);
//		GetConVarString(g_hCvarDefaultMapFile, filename, sizeof(filename));
	}
	
	if (args >= 2)
		GetCmdArg(2, filter, sizeof(filter));
	
	MapLister(Output_File, filename, client, filter);
	
	ReplyToCommand(client, "[Maplister] Generated a fresh maplist!");
	LogMessage("%L generated a fresh maplist in %s", client,
		filename);
	
	return Plugin_Handled;
}

MapLister(OutputType:type, const String:path[], client, const String:filter[])
{
	new Handle:maplist;
	if (type == Output_File)
	{
		maplist = OpenFile(path, "w");
		if (maplist == INVALID_HANDLE)
			return false;
	}
	
	decl String:name[PLATFORM_MAX_PATH];
	new Handle:array = CreateArray(PLATFORM_MAX_PATH/4);
	new FileType:filetype;
	new namelen;
	
	new filterlen = strlen(filter);
	new bool:exclude = false;
	
	decl String:fileMap[PLATFORM_MAX_PATH];
 

	//	Handle the maps directory
	new Handle:mapdir = OpenDirectory("maps/");
	if (mapdir == INVALID_HANDLE)
		return false;

	// Loop through each directory, storing all map names in "array"
	for (new i=0; i<3; i++)
	{
		if (mapdir != INVALID_HANDLE)
		{
			while (ReadDirEntry(mapdir, name, sizeof(name), filetype))
			{
				if (filetype != FileType_File)
					continue;
				
				namelen = strlen(name) - 4;
				if (StrContains(name, ".bsp", false) != namelen ||
					(g_bIsL4D && StrContains(name, ".vpk", false) != namelen))
					continue;
				
				name[namelen] = '\0';
				
				if (strncmp(filter, name, filterlen) != 0)
				{
					exclude = true;
				}
				else 
				{
					if (g_hExcludeMaps != INVALID_HANDLE)
					{
						FileSeek(g_hExcludeMaps, SEEK_SET, 0);
						while (ReadFileLine(g_hExcludeMaps, fileMap, sizeof(fileMap)))
						{
							if (strncmp(fileMap, name, strlen(name)) == 0)
							{
								exclude = true;
								break;
							}
						}
					}
				}
				
				if (!exclude)
					PushArrayString(array, name);
				
				exclude = false;
			}

			CloseHandle(mapdir);
			mapdir = INVALID_HANDLE;

		}

		
		// Change map directories for steampipe update, L4D1
		switch (i)
		{
			case 0:
			{
				// This is where we sort the entire array
				SortADTArray(array, Sort_Ascending, Sort_String);
				
				// Output the sorted map list from the array to console/file
				for (new j=0; j < GetArraySize(array); j++)
				{
					GetArrayString(array, j, name, sizeof(name));
					
					if (type == Output_Console)
						PrintToConsole(client, "%s", name);
					else
						WriteFileLine(maplist, "%s", name);
				}
				
				ClearArray(array);

				mapdir = OpenDirectory("download/maps/");
			}
			case 1:
			{
				if (g_bIsL4D)
				{
					mapdir = OpenDirectory("addons/");
				}
			}
			case 2:
			{
				// This is where we sort the entire array
				SortADTArray(array, Sort_Ascending, Sort_String);
				
				// Output the sorted map list from the array to console/file
				for (new j=0; j < GetArraySize(array); j++)
				{
					GetArrayString(array, j, name, sizeof(name));
					
					if (type == Output_Console)
						PrintToConsole(client, "%s", name);
					else
						WriteFileLine(maplist, "%s", name);
				}
				
//				ClearArray(array);

			}
			default:
			{
				/* will run if no case matched */
				/* we should never get here... */
//				CloseHandle(mapdir);
			}
		}				
	}
	
	
	// Cleanup
	if (type == Output_File)
	{
		CloseHandle(maplist);
	}
	else
	{
		if (GetArraySize(array) > 0)
		{
			ReplyToCommand(client, "[Maplister] Map list printed to console.");
		}
		else
		{
			ReplyToCommand(client, "[Maplister] No maps found.");
		}
	}
	
	return true;
}
