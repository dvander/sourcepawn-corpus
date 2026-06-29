#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "1.0";

new Handle:hcv_DefaultMap = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Auto Map Deleter",
	author = "Eyal282",
	description = "Deletes maps based on a config file.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{	
	hcv_DefaultMap = CreateConVar("map_deleter_default_map", "jb_eyal282_v1", "Default map if current map is a deleted map");
	
	ReadConfigFile();
}

ReadConfigFile()
{
	new String:Path[250];
	
	BuildPath(Path_SM, Path, sizeof(Path), "configs/mapdeleter.cfg");
	
	new Handle:fileHandle = OpenFile(Path, "rt");
	
	new String:LineInfo[PLATFORM_MAX_PATH];
	
	if(fileHandle == INVALID_HANDLE)
	{
		fileHandle = OpenFile(Path, "a+");
		
		WriteFileLine(fileHandle, "cs_*");
		WriteFileLine(fileHandle, "de_*");
		
		CloseHandle(fileHandle);
		
		ReadConfigFile();
		return;
	}	
	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, LineInfo, sizeof(LineInfo)))
	{
		if(LineInfo[0] == EOS)
			continue;
			
		new pos;
		if((pos = StrContains(LineInfo, "*", false)) != -1)
		{
			LineInfo[pos] = EOS;
			new String:MapsPath[PLATFORM_MAX_PATH];
			
			Format(MapsPath, sizeof(MapsPath), "maps", MapsPath);
			
			new Handle:hDir = OpenDirectory(MapsPath);
			
			new String:MapToTest[PLATFORM_MAX_PATH], FileType:Type;
			
			while(ReadDirEntry(hDir, MapToTest, sizeof(MapToTest), Type))
			{
				if(Type != FileType_File)
					continue;
					
				else if(MapToTest[0] == '.')
					continue;
					
				// Reusing variables.
				RemoveFilePrefix(MapToTest);
				
				if(strncmp(MapToTest, LineInfo, strlen(LineInfo)) == 0)
					DeleteMap(MapToTest);
			}
		}
		else
		{
			DeleteMap(LineInfo);
		}
	}
	CloseHandle(fileHandle);
}

public OnMapStart()
{
	new String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));
	
	new String:Path[PLATFORM_MAX_PATH];
	
	Format(Path, sizeof(Path), "maps/%s.bsp", MapName);
	
	if(!FileExists(Path))
	{
		new String:DefaultMapPath[PLATFORM_MAX_PATH]
		
		GetConVarString(hcv_DefaultMap, MapName, sizeof(MapName));
		Format(DefaultMapPath, sizeof(DefaultMapPath), "maps/%s.bsp", MapName);
		
		if(!FileExists(DefaultMapPath))
		{	
			SetFailState("Default map \"%s\" not found!", MapName);
			return;
		}
		
		ForceChangeLevel(MapName, "Current map deleted by Eyal282's Map Deleter");
	}
}

DeleteMap(String:MapName[PLATFORM_MAX_PATH])
{
	new String:Path[PLATFORM_MAX_PATH];
	
	Format(Path, sizeof(Path), "maps/%s.bsp", MapName);
	DeleteFile(Path);
	
	Format(Path, sizeof(Path), "maps/%s.nav", MapName);
	DeleteFile(Path);
	
	Format(Path, sizeof(Path), "maps/%s.jpg", MapName);
	DeleteFile(Path);
	
	Format(Path, sizeof(Path), "maps/%s.txt", MapName);
	DeleteFile(Path);
}

RemoveFilePrefix(String:FileName[PLATFORM_MAX_PATH])
{
	new len = strlen(FileName);
	
	for(new i=len;i >= 0;i--)
	{
		if(FileName[i] == '.')
		{
			FileName[i] = EOS;
			return true;
		}
	}
	
	return false;
}