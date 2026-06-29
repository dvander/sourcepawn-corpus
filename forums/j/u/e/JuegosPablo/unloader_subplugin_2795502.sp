#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
    name = "Simple Unloader",
    author = "JuegosPablo",
    description = "Just For Unload Subplugins before Start FF2 (Later of Vscript Update)",
    version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	decl String:path[PLATFORM_MAX_PATH], String:filename[PLATFORM_MAX_PATH], String:filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "plugins/freaks");
	new FileType:filetype;
	new Handle:directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			Format(filename_old, sizeof(filename_old), "%s/%s", path, filename);
			ReplaceString(filename, sizeof(filename), ".ff2", ".smx", false);
			Format(filename, sizeof(filename), "%s/%s", path, filename);
			DeleteFile(filename); // Just in case filename.ff2 also exists: delete it and replace it with the new .smx version
			RenameFile(filename, filename_old);
		}
	}

	directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			ServerCommand("sm plugins unload freaks/%s", filename);
			LogMessage("Stopped %s Plugin", filename);
		}
	}
} 