#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

ArrayList gA_Filter;

public Plugin myinfo =
{
	name = "[Any] Plugin Saver",
	author = "LenHard",
	description = "Saves the plugins from dying.",
	version = "1.0",
	url = "http://steamcommunity.com/id/TheOfficalLenHard/"
};

public void OnPluginStart() { 
	gA_Filter = new ArrayList(); 
}

public void OnMapStart() 
{
	gA_Filter.Clear();
	CreateTimer(5.0, Timer_CheckPlugins, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
}

public Action Timer_CheckPlugins(Handle hTimer)
{
	char[] sPlugin = new char[PLATFORM_MAX_PATH];
	char[] sBuffer = new char[PLATFORM_MAX_PATH];
	char[] sFile = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, PLATFORM_MAX_PATH, "plugins/");
	GetPluginFilename(null, sFile, PLATFORM_MAX_PATH);
	
	DirectoryListing dDirectoryListing = OpenDirectory(sBuffer);
   	FileType fFileType;
   	bool bFilter;
	
	while (dDirectoryListing.GetNext(sPlugin, PLATFORM_MAX_PATH, fFileType))
	{
		if (fFileType == FileType_File && StrContains(sPlugin, ".smx") != -1 && FindPluginByFile(sPlugin) == null && !StrEqual(sPlugin, sFile))
		{ 
			for (int i = 0; i < gA_Filter.Length; ++i)
			{
				gA_Filter.GetString(i, sBuffer, PLATFORM_MAX_PATH);
				
				if (StrEqual(sPlugin, sBuffer))
				{
					bFilter = true;
					break;
				}
			}
			
			if (bFilter)
			{
				bFilter = false;
				continue;				
			}
        	
			ServerCommandEx(sBuffer, PLATFORM_MAX_PATH, "sm plugins load %s", sPlugin);
			LogError("Plugin \"%s\" has been found down. Attempting to load...", sPlugin);
			
			if (StrContains(sBuffer, "successfully.") == -1)
			{
				gA_Filter.PushString(sPlugin);
				LogError("Plugin \"%s\" seems to have major internal errors, please manually fix them.", sPlugin);
			}
			else LogError("Plugin \"%s\" has been loaded successfully.", sPlugin);
        }
	}
	delete dDirectoryListing;
}