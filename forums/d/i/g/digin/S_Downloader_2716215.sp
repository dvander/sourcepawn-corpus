#pragma semicolon 1
#include <sourcemod>
#include <sdktools_stringtables>

#define PLUGIN_PREFIX_NAME "S-Downloader"
#define PLUGIN_VERSION "1.1.2.23 - Dev"

public Plugin:myinfo = 
{
    name = PLUGIN_PREFIX_NAME,
    author = "Starbish",
    description = "Add files to download table, and precache them automatically.",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

ConVar g_ConVarExclusionListPath;
ConVar g_ConVarPluginSwitch;
ConVar g_ConVarMaterialPrecache;
File g_FileExclusionList[3];

// why these should be set as normal variable not a constant?
// compiler shows error when i try compiling these as a constant.
char g_cRootDirectoryName[][] = { "models", "materials", "sound" };
int g_iFileExtCount[] = { 5, 2, 4 };
char g_cFileExtension[][][] = { {"mdl", "vvd", "vtx", "phy", "ani"}, {"vmt", "vtf", "", "", ""}, {"mp3", "wav", "wmv", "wma", ""} };
int g_iCacheFileExtCount[] = { 1, 1, 4 };
char g_cCacheFileExtension[][][] = { {"mdl", "", "", "", ""}, {"vmt", "", "", "", ""}, {"mp3", "wav", "wmv", "wma", ""} };

public void OnPluginStart(){

	CreateConVar("sm_SDownloader_Version", PLUGIN_VERSION, "Made by Starbish", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_ConVarPluginSwitch = CreateConVar("sm_SDownloader_Enable", "1", "1 = Plugin Enable \n 0 = Plugin Disable");
	g_ConVarExclusionListPath = CreateConVar("sm_SDownloader_ExclusionListPath", "configs/SDownloader/ExclusionList", "write a file's path excluding addons/sourcemod or something.");
	g_ConVarMaterialPrecache = CreateConVar("sm_SDownloader_material_precache", "1", "1 = Enable Material(vmt) Precaching \n 0 = Disable");

	AutoExecConfig();
}

public void OnMapStart(){

	Process_GetExclusionList();

	// if the plugin is enabled.
	if(g_ConVarPluginSwitch.IntValue == 1){

		// add files to download table, and precache them.
		for(int x = 0; x < sizeof(g_cRootDirectoryName); x++)
			Process_RegisterResource(x, DirectoryListing:INVALID_HANDLE, g_cRootDirectoryName[x]);

	}

	for(int y = 0; y < sizeof(g_cRootDirectoryName); y++)
		delete g_FileExclusionList[y];
}

void Process_RegisterResource(int index, DirectoryListing dirList = DirectoryListing:INVALID_HANDLE, const char[] cDirectory){

	// if materials precaching is disabled
	if(index == 1 && g_ConVarMaterialPrecache.BoolValue == false)
		return;

	FileType iType;
	char cFileName[PLATFORM_MAX_PATH];
	char cBuffer[PLATFORM_MAX_PATH];
	char cExtensionName[PLATFORM_MAX_PATH];

	if(dirList == INVALID_HANDLE) dirList = OpenDirectory(g_cRootDirectoryName[index], false);

	if(dirList == INVALID_HANDLE) return;

	while(ReadDirEntry(dirList, cFileName, PLATFORM_MAX_PATH, iType)){

		if(iType == FileType_File){

			GetFileExtension(cExtensionName, cFileName, PLATFORM_MAX_PATH);

			// check if file's extension is what i'm finding
			for(int i = 0; i < g_iFileExtCount[index]; i++){

				// found.
				if(StrEqual(cExtensionName, g_cFileExtension[index][i])){

					Format(cBuffer, sizeof(cBuffer), "%s/%s", cDirectory, cFileName);
					AddFileToDownloadsTable(cBuffer);

					// check whether this file needs to be precached. 
					for(int x = 0; x < g_iCacheFileExtCount[index]; x++){

						if(StrEqual(cExtensionName, g_cCacheFileExtension[index][x])){

							if(index == 0 || index == 1)
								PrecacheModel(cBuffer);

							else if(index == 2){

								ReplaceStringEx(cBuffer, sizeof(cBuffer), "sound/", "");
								PrecacheSound(cBuffer);

							}

							PrintToServer("[%s] %s Precached / Uploaded", PLUGIN_PREFIX_NAME, cBuffer);

							break;
						}

						else PrintToServer("[%s] %s Uploaded", PLUGIN_PREFIX_NAME, cBuffer);
					}

					break;
				}
			}
		}

		// dir
		else if(iType == FileType_Directory && IsStringNotFuckingIdiotDot(cFileName)){

			Format(cBuffer, sizeof(cBuffer), "%s/%s", cDirectory, cFileName);

			if(!Process_IsDirectoryExcluded(cBuffer, index))
				Process_RegisterResource(index, OpenDirectory(cBuffer, false), cBuffer);

			else PrintToServer("[%s] Directory Excluded : %s", PLUGIN_PREFIX_NAME, cBuffer);

//			PrintToServer("[%s] Moved to %s", PLUGIN_PREFIX_NAME, cBuffer);
		}
	}

	CloseHandle(dirList);
//	PrintToServer("[%s] %s file precaching / uploading is completed.", PLUGIN_PREFIX_NAME, g_cRootDirectoryName[index]);
}

void Process_GetExclusionList(){

	char cPath[PLATFORM_MAX_PATH];
	char cBuffer[PLATFORM_MAX_PATH];

	g_ConVarExclusionListPath.GetString(cPath, sizeof(cPath));

	for(int x = 0; x < sizeof(g_cRootDirectoryName); x++){

		BuildPath(Path_SM, cBuffer, sizeof(cBuffer), "%s_%s.cfg", cPath, g_cRootDirectoryName[x]);
		g_FileExclusionList[x] = OpenFile(cBuffer, "r");

	}
}

bool Process_IsDirectoryExcluded(const char[] cDirectory, int index){

	char cLine[PLATFORM_MAX_PATH];

	g_FileExclusionList[index].Seek(0, SEEK_SET);

	while(ReadFileLine(g_FileExclusionList[index], cLine, sizeof(cLine))){

		TrimString(cLine);

		if(cLine[0] != '0' && StrEqual(cLine, cDirectory)){

			return true;
		}
	}

	return false;
}

stock void GetFileExtension(char[] cExtensionName, const char[] cFileName, int maxlength){

	Format(cExtensionName, maxlength, "%s", cFileName[FindCharInString(cFileName, '.', true) + 1]);
}

stock IsStringNotFuckingIdiotDot(const char[] cString){

	if(StrEqual(cString, ".") || StrEqual(cString, ".."))
		return false;
	return true;
}