#include <sourcemod>
#define Version "1.0"
new Handle:LifeTime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Downloads Cleaner",
	author = "NBK - Sammy-ROCK!",
	description = "Auto cleans downloads folder for older files.",
	version = Version,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("downloadscleaner_version", Version, "Version of Downloads Cleaner plugin.", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN);
	LifeTime = CreateConVar("sm_downloads_lifetime", "1440", "How many minutes files in downloads folder should last.", FCVAR_PLUGIN);
	CreateTimer(60.0, Timer_Recheck, _, TIMER_REPEAT);
}

public Action:Timer_Recheck(Handle:timer)
{
	new MaxLastAccess = GetTime() - 60 * GetConVarInt(LifeTime);
	new Handle:Downloads = OpenDirectory("downloads");
	decl String:path[256], FileType:type;
	while(ReadDirEntry(Downloads, path, sizeof(path), type))
		if(type == FileType_File)
			if(GetFileTime(path, FileTime_LastAccess) < MaxLastAccess)
				DeleteFile(path);
	CloseHandle(Downloads);
}