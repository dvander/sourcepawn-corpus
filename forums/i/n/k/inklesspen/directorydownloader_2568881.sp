#include <sourcemod>
#include <sdktools_stringtables>

bool FakePrecache = false
int SoundTable

public Plugin myinfo = {
	name = "[ANY] Directory Downloader",
	author = "inklesspen",
	version = "1.3"
}

public void OnPluginStart()
{
	char sBuffer[32]
	GetGameFolderName(sBuffer, 32)
	if(!strcmp(sBuffer, "insurgency") || !strcmp(sBuffer, "csgo"))
	{
		FakePrecache = true
		SoundTable = FindStringTable("soundprecache")
	}
}

public void OnMapStart()
{
	//Downloads
	char sPath[192]
	BuildPath(Path_SM, sPath, 192, "configs/dirdownloader.ini")
	if(FileExists(sPath))
	{
		File downloads = OpenFile(sPath, "r")
		int size
		int pos
		while(ReadFileLine(downloads, sPath, 192))
		{
			pos = StrContains(sPath, "//")
			if(pos == 0)
				continue
			else if(pos != -1)
				sPath[pos] = 0
			TrimString(sPath)
			if(!sPath[0])
				continue;
			size = strlen(sPath)
			// LogError(sPath)
			switch(sPath[size-1])
			{
				case '/':{
					sPath[size-1] = 0
					// LogError("2")
					if(DirExists(sPath)){
						// LogError("3")
						Downloads_LoadDirectory(sPath, true)
					}
				}
				case '\\':{
					sPath[size-1] = 0
					if(DirExists(sPath)){
						Downloads_LoadDirectory(sPath, false)
					}
				}
				// default:	if(FileExists(sPath) && !FileExists(sPath, true))	LoadFile(sPath)
				default:{
					// LogError("%i", sPath[size-1])
					// LogError("%i", sPath[size])
					if(FileExists(sPath))	LoadFile(sPath)
				}
			}
		}
		downloads.Close()
	}
}

Downloads_LoadDirectory(const char[] dirpath, bool directories = false)
{
	DirectoryListing dir = OpenDirectory(dirpath)
	char sPath[192]
	FileType type
	while(ReadDirEntry(dir, sPath, 192, type))
	{
		if(sPath[0] == '.')
			continue;
		Format(sPath, 192, "%s/%s", dirpath, sPath)
		// LogError(")%s", sPath)
		
		switch(type)
		{
			case FileType_Directory:	if(directories)	Downloads_LoadDirectory(sPath, true)
			// case FileType_File:			if(FileExists(sPath) && !FileExists(sPath, true))	LoadFile(sPath)
			case FileType_File:			if(FileExists(sPath))	LoadFile(sPath)
		}
	}
	dir.Close()
}

void LoadFile(char[] sPath)
{
	AddFileToDownloadsTable(sPath)
	int size = strlen(sPath)
	if(!strcmp(sPath[size-4], ".mdl")) // Надеемся, что файл в models/
		PrecacheModel(sPath)
	else if(!strcmp(sPath[size-4], ".mp3"))
	{
		// Подразумивается, что файл находится в sound/
		if(FakePrecache)
		{
			sPath[5] = '*'
			AddToStringTable(SoundTable, sPath[5])
		}
		else
			PrecacheSound(sPath[6])
	}
}