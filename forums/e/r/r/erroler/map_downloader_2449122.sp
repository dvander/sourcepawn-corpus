#include <system2>
#include <smlib>
#include <regex>

new String:data_dir[PLATFORM_MAX_PATH + 1];
new String:maps_dir[PLATFORM_MAX_PATH + 1];
new String:GameFolderName[32];
new Handle:regex;

public Plugin:myinfo =
{
	name = "Map Downloader",
	author = "Erroler",
	description = "Download maps hosted on a website directly to your gameservers.",
	version = "1.0"
};

public OnPluginStart()
{
	BuildPaths();
	Check7z();
	regex = CompileRegex("^https?://(?:[a-z0-9\\-]+\\.)+[a-z]{2,6}(?:/[^/#?]+)+\\.(?:zip|7z|gz|tar|bz2|rar|bsp|nav)$");
	RegAdminCmd("sm_downloadmap", DownloadMap, ADMFLAG_ROOT); //Usage: sm_downloadmap "<MAP_URL>"
}

public Action:DownloadMap(client, args)
{
	// Verify if an argument was passed
	if(GetCmdArgs() == 0)
	{
		PrintToConsole(client, "[MapDownloader] ERROR - No url entered. Usage: sm_downloadmap \"<MAP_URL>\"");
		return Plugin_Handled;
	}
	// Get cmd argument
	new String:map_url[512];
	GetCmdArg(1, map_url, sizeof(map_url));
	// URL validation
	if(MatchRegex(regex, map_url) < 1) // Url is not valid
	{
		PrintToConsole(client, "[MapDownloader] ERROR - The URL you entered is not valid.");
		return Plugin_Handled;
	}
	// Get File Name (with and without file extension)
	new String:Mapholder[16][128];
	new num_strings_spliced = ExplodeString(map_url, "/", Mapholder, sizeof(Mapholder), sizeof(Mapholder[]));
	new String:file_name[64], String:file_name_no_ext[64], String:file_extension[5];
	strcopy(file_name, sizeof(file_name), Mapholder[num_strings_spliced - 1]);
	num_strings_spliced = ExplodeString(file_name, ".", Mapholder, sizeof(Mapholder), sizeof(Mapholder[]));
	strcopy(file_extension, sizeof(file_extension), Mapholder[num_strings_spliced - 1]);
	strcopy(file_name_no_ext, sizeof(file_name_no_ext), Mapholder[0]);
	// Get Download Path
	decl String:DownloadPath[PLATFORM_MAX_PATH + 1];
	Format(DownloadPath, sizeof(DownloadPath), "%s/%s/%s", data_dir, file_name_no_ext, file_name);
	// Get Download Dir
	decl String:DownloadDir[PLATFORM_MAX_PATH + 1];
	Format(DownloadDir, sizeof(DownloadDir), "%s/%s", data_dir, file_name_no_ext);
	// Create and write data to trie.
	new Handle:trie = CreateTrie();
	SetTrieValue(trie, "client", client);
	SetTrieString(trie, "file_name", file_name);
	SetTrieString(trie, "file_name_no_ext", file_name_no_ext);
	SetTrieString(trie, "file_extension", file_extension);
	SetTrieString(trie, "DownloadPath", DownloadPath);
	SetTrieString(trie, "DownloadDir", DownloadDir);
	// Delete Download Directory if it exists (plugin might have bugged out or something before)
	if(DirExists(DownloadDir)) Stock_DeleteFullDir(DownloadDir);
	// Create Download Directory
	CreateDirectory(DownloadDir, 511);
	// Start file download
	PrintToConsole(client, "[MapDownloader] Downloading %s.", file_name);
	if(FileExists(DownloadPath))	DeleteFile(DownloadPath); //Delete download file if it exists
	System2_DownloadFile(OnDownloadStep, map_url, DownloadPath, trie);
	return Plugin_Handled;
}

public OnDownloadStep(bool:finished, const String:error[], Float:dltotal, Float:dlnow, Float:ultotal, Float:ulnow, any:trie)
{
	new client;
	GetTrieValue(trie, "client", client);
	new String:file_name[64];
	GetTrieString(trie, "file_name", file_name, sizeof(file_name));
	// Finished?
	if (!finished) //Download is not over yet
	{
		new Float:Percentage = (dlnow/dltotal) / 2;
		PrintToConsole(client, "[MapDownloader] Downloading %s. Progress: %.0f / 100%", file_name, Percentage * 100 * 2 + 1); // Must multiply by 2 or it goes 0-50% only. Also increment 1 so it reaches 100 and not just 99 due to int truncation
	}
	else if (StrEqual(error, "")) // Download is over and no errors ocurred
	{
		new String:file_name_no_ext[64];
		GetTrieString(trie, "file_name_no_ext", file_name_no_ext, sizeof(file_name_no_ext));
		new String:file_extension[5];
		GetTrieString(trie, "file_extension", file_extension, sizeof(file_extension));
		if(strcmp(file_extension, "bsp", false) == 0 || strcmp(file_extension, "nav", false) == 0) //Download was a map file (bsp) or a nav file
		{
			new String:DownloadPath[PLATFORM_MAX_PATH + 1];
			GetTrieString(trie, "DownloadPath", DownloadPath, sizeof(DownloadPath));
			new String:DownloadDir[PLATFORM_MAX_PATH + 1];
			GetTrieString(trie, "DownloadDir", DownloadDir, sizeof(DownloadDir));
			if(MapsDirectoryFileExists(file_name))
			{
				PrintToConsole(client, "[MapDownloader] ERROR - %s already exists on maps directory!", file_name, error);
				CloseHandle(trie);
				Stock_DeleteFullDir(DownloadDir);
				return;
			}
			PrintToConsole(client, "[MapDownloader] Downloaded %s. Moving it to maps directory.", file_name);
			new String:output[128];
			System2_RunCommand(output, sizeof(output), "mv %s -t %s", DownloadPath, maps_dir);
			if(strcmp(file_extension, "bsp", false) == 0)	PrintToConsole(client, "[MapDownloader] %s was sucessfuly installed on your server. Don't forget to add it to the maplist and sync it with your fast downloads server if you must!", file_name_no_ext);
			else	PrintToConsole(client, "[MapDownloader] %s.nav was sucessfuly installed on your server.", file_name_no_ext);
			Stock_DeleteFullDir(DownloadDir);
			CloseHandle(trie);
		}
		else //Download was a compressed archive
		{	
			new String:DownloadPath[PLATFORM_MAX_PATH + 1];
			GetTrieString(trie, "DownloadPath", DownloadPath, sizeof(DownloadPath));
			new String:DownloadDir[PLATFORM_MAX_PATH + 1];
			GetTrieString(trie, "DownloadDir", DownloadDir, sizeof(DownloadDir));
			PrintToConsole(client, "[MapDownloader] Downloaded %s. Extracting...", file_name);
			System2_ExtractArchive(OnExtracted, DownloadPath, DownloadDir, trie);
			
		}
	}
	else
	{
		// Finished with Error
		// Error is a curl error
		new String:DownloadDir[PLATFORM_MAX_PATH + 1];
		GetTrieString(trie, "DownloadDir", DownloadDir, sizeof(DownloadDir));
		PrintToConsole(client, "[MapDownloader] ERROR - Some error ocurred while downloading %s - %s.", file_name, error);
		Stock_DeleteFullDir(DownloadDir);
		CloseHandle(trie);
	}
}

public OnExtracted(const String:output[], const size, CMDReturn:status, any:trie)
{
	new client;
	GetTrieValue(trie, "client", client);
	new String:file_name[64];
	GetTrieString(trie, "file_name", file_name, sizeof(file_name));
	// Are we finished?
	if (status != CMD_PROGRESS)
	{
		new String:DownloadDir[PLATFORM_MAX_PATH + 1];
		GetTrieString(trie, "DownloadDir", DownloadDir, sizeof(DownloadDir));
		new String:Path_To_BSP[PLATFORM_MAX_PATH + 1], String:Path_To_Nav[PLATFORM_MAX_PATH + 1];
		if(FindFileHandler(DownloadDir, Path_To_BSP, sizeof(Path_To_BSP))) // BSP file was found
		{
			new String:MapName[64], String:MapName_with_ext[64];
			GetMapName(Path_To_BSP, MapName, sizeof(MapName));
			SetTrieString(trie, "MapName", MapName);
			Format(MapName_with_ext, sizeof(MapName_with_ext), "%s.bsp", MapName);
			if(MapsDirectoryFileExists(MapName_with_ext))
			{
				PrintToConsole(client, "[MapDownloader] ERROR - %s.bsp already exists!", MapName);
				CloseHandle(trie);
				Stock_DeleteFullDir(DownloadDir);
				return;
			}
			PrintToConsole(client, "[MapDownloader] %s was extracted and %s.bsp was found. Moving it to maps directory...", file_name, MapName);
			//Move .bsp
			Path_To_Nav = Path_To_BSP;
			Format(Path_To_BSP, sizeof(Path_To_BSP), "%s/%s", GameFolderName, Path_To_BSP);
			new String:output2[128];
			System2_RunCommand(output2, sizeof(output2), "mv %s -t %s", Path_To_BSP, maps_dir);
			// ----
			ReplaceString(Path_To_Nav, sizeof(Path_To_Nav), ".bsp", ".nav");
			if(FileExists(Path_To_Nav))
			{
				PrintToConsole(client, "[MapDownloader] A nav file for %s was also found. Moving it to maps directory...", MapName);
				//Move .nav
				Format(Path_To_Nav, sizeof(Path_To_Nav), "%s/%s", GameFolderName, Path_To_Nav);
				System2_RunCommand(output2, sizeof(output2), "mv %s -t %s", Path_To_Nav, maps_dir);
			}
			PrintToConsole(client, "[MapDownloader] %s was sucessfuly installed on your server. Don't forget to add it to the maplist and sync it with your fast downloads server if you must!", MapName);
			Stock_DeleteFullDir(DownloadDir);
			CloseHandle(trie);
		}
		else //BSP File not found
		{
			PrintToConsole(client, "[MapDownloader] ERROR - %s was downloaded and extracted but no bsp file was found.", file_name);
			Stock_DeleteFullDir(DownloadDir);
			CloseHandle(trie);
			return;
		}
	}
	else if(status == CMD_ERROR)
	{
		PrintToConsole(client, "[MapDownloader] ERROR - Some error hapenned while extracting %s!", file_name);
	}
}

// Stock Functions
stock bool:FindFileHandler(const String:PathToSearchIn[], String:Path_To_BSP[], ReturnStringSizeBSP)
{
	FindFile(PathToSearchIn, Path_To_BSP, ReturnStringSizeBSP);
	if(strlen(Path_To_BSP) > 1)	return true;
	else	return false;
}

stock bool:FindFile(const String:PathToSearchIn[], String:Path_To_BSP[], ReturnStringSizeBSP)
{
	new Handle:dirh = INVALID_HANDLE;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type = FileType_Unknown;
	new len;
	dirh = OpenDirectory(PathToSearchIn);
	while(ReadDirEntry(dirh,buffer,sizeof(buffer),type))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		TrimString(buffer);
		if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
		{
			strcopy(tmp_path,255,PathToSearchIn);
			StrCat(tmp_path,255,"/");
			StrCat(tmp_path,255,buffer);
			if(type == FileType_File)
			{
				new String:extension[10];
				File_GetExtension(tmp_path, extension, sizeof(extension));
				if(StrEqual(extension, "bsp", true))
				{
					strcopy(Path_To_BSP, ReturnStringSizeBSP, tmp_path);
					continue;
				}
			}
			else
			{
				FindFile(tmp_path, Path_To_BSP, ReturnStringSizeBSP);
			}
		}
	}
}

stock Stock_DeleteFullDir(const String:Dir[])
{
	new Handle:dirh = INVALID_HANDLE;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type = FileType_Unknown;
	new len;
	dirh = OpenDirectory(Dir);
	while(ReadDirEntry(dirh,buffer,sizeof(buffer),type))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
		{
			buffer[--len] = '\0';
		}
		TrimString(buffer);
		if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
		{
			strcopy(tmp_path,255,Dir);
			StrCat(tmp_path,255,"/");
			StrCat(tmp_path,255,buffer);
			if(type == FileType_File)
			{
				DeleteFile(tmp_path);
			}
			else
			{
				Stock_DeleteFullDir(tmp_path);
			}
		}
	}
	RemoveDir(Dir);
}

stock GetMapName(const String:MapPath[], String:MapName[], ReturnStringSize, bool:remove_ext = true)
{
	new String:Map_Path_Pending_BSP_Removal[64];
	strcopy(Map_Path_Pending_BSP_Removal, sizeof(Map_Path_Pending_BSP_Removal), MapPath);
	if(remove_ext) { ReplaceString(Map_Path_Pending_BSP_Removal, sizeof(Map_Path_Pending_BSP_Removal), ".bsp", ""); ReplaceString(Map_Path_Pending_BSP_Removal, sizeof(Map_Path_Pending_BSP_Removal), ".nav", ""); }
	ReplaceString(Map_Path_Pending_BSP_Removal, sizeof(Map_Path_Pending_BSP_Removal), "\\", "/");
	new String:Mapholder[16][128];
	new num_strings_spliced = ExplodeString(Map_Path_Pending_BSP_Removal, "/", Mapholder, sizeof(Mapholder), sizeof(Mapholder[]));
	strcopy(MapName, ReturnStringSize, Mapholder[num_strings_spliced - 1]);
}

stock MapsDirectoryFileExists(String:FileName[])
{	
	decl String:map_path[PLATFORM_MAX_PATH + 1];
	Format(map_path, sizeof(map_path), "maps/%s.bsp", FileName);
	if(FileExists(map_path))	return true;
	return false;
}

Check7z() //#LINUX ONLY
{
	new String:output[256];
	System2_RunCommand(output, sizeof(output), "ls -l %s/addons/sourcemod/data/system2/7z", GameFolderName);
	if(StrContains(output, "562104") == -1)	//File was uploaded trough ascii ftp mode
	{
		SetFailState("[MapDownloader] ERROR - 7z wasn't uploaded trough binary ftp mode.");
		PrintToChatAll(output);
	}
	//Check and give if needed exec permission
	System2_RunCommand(output, sizeof(output), "%s/addons/sourcemod/data/system2/7z", GameFolderName);
	if(!(StrContains(output, "Permission denied") == -1))
	{
		System2_RunCommand(output, sizeof(output), "chmod +x %s/addons/sourcemod/data/system2/7z", GameFolderName);
	}
	
}

BuildPaths()
{
	BuildPath(Path_SM, data_dir, sizeof(data_dir), "data");
	GetGameFolderName(GameFolderName, sizeof(GameFolderName));
	Format(maps_dir, sizeof(maps_dir), "%s/maps/", GameFolderName);
}