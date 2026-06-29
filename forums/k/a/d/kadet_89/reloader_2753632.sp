public Plugin myinfo =
{
	name = "PluginReloader",
	author = "SourceMod",
	description = "Reloads plugins on map change",
	version = "1.1",
	url = ""
}

public void reloadPlugins(char[] path, int pluginDirIndex)
{
	char thisFileName[512];
	GetPluginFilename(INVALID_HANDLE, thisFileName, sizeof(thisFileName));
    
	FileType type;
	DirectoryListing dL = OpenDirectory(path);
	char fileBuffer[512];
	while (dL.GetNext(fileBuffer, sizeof(fileBuffer), type))
	{
		if (type == FileType_Directory)
		{
			if(strcmp(fileBuffer, "disabled") == 0)
				continue;

			if(strcmp(fileBuffer, "mapmanagment") == 0)
				continue;

			if(fileBuffer[0] == '.')
				continue;

			char subPath[512];
			Format(subPath, sizeof(subPath), "%s%s/", path, fileBuffer);
			reloadPlugins(subPath, pluginDirIndex);
			continue;
		}
		if (type != FileType_File)
			continue;

		if (StrEqual(thisFileName, fileBuffer))
			continue;

		LogMessage("Reloading plugin %s%s", path[pluginDirIndex], fileBuffer);
		ServerCommand("sm plugins reload %s%s", path[pluginDirIndex], fileBuffer);
	}

	if(dL != INVALID_HANDLE)
		CloseHandle(dL);

}

public void OnMapStart()
{
	char path[512];
	BuildPath(Path_SM, path, sizeof(path), "plugins/");
	if (DirExists(path))
	{
		LogMessage("Start reloading plugins");
		reloadPlugins(path, strlen(path));
		LogMessage("All plugins reloaded successfully");
	}
}