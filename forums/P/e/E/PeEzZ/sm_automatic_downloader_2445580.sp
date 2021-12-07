#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin: myinfo = 
{
	name = "Automatic Downloader",
	author = "PeEzZ",
	description = "Automatic downloader.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=286451"
}

new Handle: CVAR_MATERIALS = INVALID_HANDLE,
	Handle: CVAR_MODELS = INVALID_HANDLE,
	Handle: CVAR_SOUNDS = INVALID_HANDLE;

new String: ValidFormats[][] = //VALID, DOWNLOADABLE FILE FORMATS
{
	"mdl", "phy", "vtx", "vvd", //Model files
	"vmt", "vtf", "png", //Texture and material files
	"mp3", "wav" //Sound files
};

public OnPluginStart()
{
	CVAR_MATERIALS	= CreateConVar("sm_downloader_materials",	"1", "Add to downloads the materials folder, 0 - disable, 1 - enable",	_, true, 0.0, true, 1.0);
	CVAR_MODELS		= CreateConVar("sm_downloader_models",		"1", "Add to downloads the models folder, 0 - disable, 1 - enable",		_, true, 0.0, true, 1.0);
	CVAR_SOUNDS		= CreateConVar("sm_downloader_sounds",		"1", "Add to downloads the sound folder, 0 - disable, 1 - enable",		_, true, 0.0, true, 1.0);
}

public OnMapStart()
{
	if(GetConVarBool(CVAR_MATERIALS))
	{
		AddFolderToDownloadsTable("materials");
	}
	if(GetConVarBool(CVAR_MODELS))
	{
		AddFolderToDownloadsTable("models");
	}
	if(GetConVarBool(CVAR_SOUNDS))
	{
		AddFolderToDownloadsTable("sound");
	}
}

//-----STOCKS-----//
AddFolderToDownloadsTable(String: Folder[])
{
	if(DirExists(Folder))
	{
		new Handle: DIR = OpenDirectory(Folder),
			String: BUFFER[PLATFORM_MAX_PATH],
			FileType: FILETYPE = FileType_Unknown;
		
		while(ReadDirEntry(DIR, BUFFER, sizeof(BUFFER), FILETYPE))
		{
			if(!StrEqual(BUFFER, "") && !StrEqual(BUFFER, ".") && !StrEqual(BUFFER, ".."))
			{
				Format(BUFFER, sizeof(BUFFER), "%s/%s", Folder, BUFFER);
				if(FILETYPE == FileType_File)
				{
					if(FileExists(BUFFER, true) && IsFileDownloadable(BUFFER))
					{
						AddFileToDownloadsTable(BUFFER);
					}
				}
				else if(FILETYPE == FileType_Directory)
				{
					AddFolderToDownloadsTable(BUFFER);
				}
			}
		}
		CloseHandle(DIR);
	}
	else
	{
		LogError("Automatic Downloader: Directory not exists - \"%s\"", Folder);
	}
}

bool: IsFileDownloadable(String: string[])
{
	new String: buffer[PLATFORM_MAX_PATH];
	GetFileExtension(string, buffer, sizeof(buffer));
	for(new i = 0; i < sizeof(ValidFormats); i++)
	{
		if(StrEqual(buffer, ValidFormats[i], false))
		{
			return true;
		}
	}
	return false;
}

bool: GetFileExtension(const String: filepath[], String: filetype[], filetypelen)
{
    new loc = FindCharInString(filepath, '.', true);
    if(loc == -1)
    {
        filetype[0] = '\0';
        return false;
    }
    strcopy(filetype, filetypelen, filepath[loc + 1]);
    return true;
}