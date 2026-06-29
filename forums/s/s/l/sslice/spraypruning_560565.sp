#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0.1"
 
public Plugin:myinfo = 
{
	name = "Spray Pruning",
	author = "sslice",
	description = "Keeps old excess spray cache files from building up in the downloads/ folder.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
 
new Handle:g_Cvar_SprayCacheLifetime;

TrimSprayCache()
{
	decl String:path[500];
	decl String:temp[500];
	new expireTime = GetTime() / 3600;
	expireTime -= (GetConVarInt(g_Cvar_SprayCacheLifetime) * 24);
	
	new Handle:dir = OpenDirectory("downloads");
	new numTrimmed = 0;
	new i = 0;
	if (dir != INVALID_HANDLE)
	{
		while (ReadDirEntry(dir, path, 500) == true)
		{
			FormatEx(temp, 500, "downloads/%s", path);
			
			new ftime = GetFileTime(temp, FileTime_LastAccess);
			if (ftime == -1)
			{
				ftime = GetFileTime(temp, FileTime_LastChange);
			}
			
			if (ftime != -1 && !StrEqual(path, ".") && !StrEqual(path, ".."))
			{
				ftime /= 3600;
				if (expireTime > ftime && DeleteFile(temp) == true)
				{
					numTrimmed += 1;
				}
			}
			
			i += 1;
			if (i > 2500) // don't want to do too many at once, as it will freeze the server for some time
			{
				break;
			}
		}
		CloseHandle(dir);
	}
}
 
public OnPluginStart()
{
	CreateConVar("sm_spraypruning_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_Cvar_SprayCacheLifetime = CreateConVar("sm_spraycachelifetime", "7", "Trims sprays cached that have not been accessed after X days", 0);
}

public OnMapStart()
{
	TrimSprayCache();
}
