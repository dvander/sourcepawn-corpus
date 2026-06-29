#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define WEEKS_TO_DELETE 1

ArrayList filesToDelete;

public Plugin myinfo =
{
	name = "[ANY] Sourcemod Log Deleter",
	author = "Headline, SWAT_88",
	description = "Deletes logs when they reach a certain age",
	version = "1.0.1",
	url = "colosseum-gaming.com"
}

public void OnMapStart()
{
	char path[PLATFORM_MAX_PATH], sTempString[128];
	int count;
	
	filesToDelete = new ArrayList(128);
	
	BuildPath(Path_SM, path, sizeof(path), "logs");
	ReadFileFolder(path);
	PrintToServer(path);
	ReadFileFolder("logs");

	for (int i = 0; i < filesToDelete.Length; i++)
	{
		filesToDelete.GetString(i, sTempString, sizeof(sTempString));
		if (FileExists(sTempString))
		{
			PrintToServer("[Log Cleaner] Deleting file \"%s\"", sTempString);
			DeleteFile(sTempString);
			count++;
		}
	}
	
	delete filesToDelete;
	PrintToServer("[Log Cleaner] %i log files deleted!", count);
}

/* Snippet from SWAT_88 */
public void ReadFileFolder(char[] path)
{
	Handle dirh = null;
	char buffer[256];
	char tmp_path[256];
	FileType type = FileType_Unknown;
	int len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';

	TrimString(path);
	
	if(DirExists(path))
	{
		dirh = OpenDirectory(path);
		
		while(ReadDirEntry(dirh, buffer, sizeof(buffer), type))
		{
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';

			TrimString(buffer);

			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false))
			{
				strcopy(tmp_path,255,path);
				StrCat(tmp_path,255, "/");
				StrCat(tmp_path,255, buffer);
				if(type == FileType_File)
				{
					int lastEdited = GetFileTime(tmp_path, FileTime_LastChange);
					if (lastEdited <= GetTime() - (WEEKS_TO_DELETE * 604800)) // 604800 is a week in seconds
					{
						filesToDelete.PushString(tmp_path);
					}
				}
			}
		}
	}
	else
	{
		SetFailState("[Log Cleaner] No log folder found!");
	}
	
	if(dirh != null)
	{
		CloseHandle(dirh);
	}
}

/* Changelog
	1.0 - Initial Release
	1.0.1 - Forgot to delete array (probably better)
*/