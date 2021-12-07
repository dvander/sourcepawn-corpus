#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Plugin Unloader",
	author = "Zephyrus",
	description = "Privately coded plugin.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegServerCmd("sm_unloadall", Command_Unloadall);
}

public Action:Command_Unloadall(args)
{
	ReadDir("disabled");	
	return Plugin_Handled;
}

public ReadDir(String:dir[])
{
	new String:fdir[256];
	BuildPath(Path_SM, fdir, sizeof(fdir), "plugins/%s", dir);
	new Handle:hdir = OpenDirectory(fdir);
	
	new String:buffer[256];
	new String:temp[256];
	new FileType:filetype;
	
	while(ReadDirEntry(hdir, buffer, sizeof(buffer), filetype))
	{
		if(strcmp(".", buffer)!=0 && strcmp("..", buffer)!=0)
		{
			if(filetype == FileType_Directory)
			{
				Format(temp, sizeof(temp), "%s/%s", dir, buffer);
				ReadDir(temp);
			}
			else
			{
				ServerCommand("sm plugins unload %s/%s", dir, buffer);
			}
		}
	}
}