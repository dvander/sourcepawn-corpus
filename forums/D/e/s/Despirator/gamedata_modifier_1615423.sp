#include <sourcemod>
#include <smlib>

new bool:b_modified = false;

public Plugin:myinfo =
{
	name = "CS:S Beta gamedata modifier",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Modifies gamedata for CS:S Beta",
	version = "1.0",
	url = "http://www.hlmod.ru/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_gamefolder[32];
	GetGameFolderName(s_gamefolder, sizeof(s_gamefolder));
	if (strcmp(s_gamefolder, "cstrike_beta") != 0)
	{
		strcopy(error, err_max, "The game is not Counter-Strike: Source Beta");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "gamedata");
	File_ReplaceString(path, "cstrike", "cstrike_beta", true);
}

public OnConfigsExecuted()
{
	if (b_modified)
	{
		b_modified = false;
		ServerCommand("_restart");
	}
}

stock File_ReplaceString(const String:path[], const String:search[], const String:replace[], bool:caseSensitive = true)
{
	if (path[0] == '\0') {
		return;
	}

	if (FileExists(path)) {
		
		decl String:fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));
		
		if (!StrEqual(fileExtension, "txt", false)){
			return;
		}

		decl String:path_new[PLATFORM_MAX_PATH];
		strcopy(path_new, sizeof(path_new), path);
		ReplaceString(path_new, sizeof(path_new), "//", "/");
		
		decl String:buf[PLATFORM_MAX_PATH];
		Format(buf, sizeof(buf), "%s.cache", path_new);

		new Handle:filehandle, Handle:filehandle2;
		
		filehandle = OpenFile(path_new, "r");
		filehandle2 = OpenFile(buf, "w");
		decl String:Line[PLATFORM_MAX_PATH];
		while (!IsEndOfFile(filehandle))
		{
			Line[0] = '\0';
			if (!ReadFileLine(filehandle, Line, sizeof(Line)))
				continue;
			
			if (StrContains(Line, replace, caseSensitive) == -1 && StrContains(Line, search, caseSensitive) != -1)
			{
				ReplaceString(Line, sizeof(Line) + 5, search, replace, caseSensitive);
				b_modified = true;
			}
			WriteFileString(filehandle2, Line, false);
		}
		CloseHandle(filehandle);
		CloseHandle(filehandle2);
		DeleteFile(path_new);
		RenameFile(path_new, buf);
	}
	else if (DirExists(path)) {

		decl String:dirEntry[PLATFORM_MAX_PATH];
		new Handle:__dir = OpenDirectory(path);

		while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

			if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
				continue;
			}
			
			Format(dirEntry, sizeof(dirEntry), "%s/%s", path, dirEntry);
			File_ReplaceString(dirEntry, search, replace, caseSensitive);
		}
		
		CloseHandle(__dir);
	}
	else if (FindCharInString(path, '*', true)) {
		
		new String:fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));

		if (StrEqual(fileExtension, "*")) {

			decl
				String:dirName[PLATFORM_MAX_PATH],
				String:fileName[PLATFORM_MAX_PATH],
				String:dirEntry[PLATFORM_MAX_PATH];

			File_GetDirName(path, dirName, sizeof(dirName));
			File_GetFileName(path, fileName, sizeof(fileName));
			StrCat(fileName, sizeof(fileName), ".");

			new Handle:__dir = OpenDirectory(dirName);
			while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

				if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
					continue;
				}

				if (strncmp(dirEntry, fileName, strlen(fileName)) == 0) {
					Format(dirEntry, sizeof(dirEntry), "%s/%s", dirName, dirEntry);
					File_ReplaceString(dirEntry, search, replace, caseSensitive);
				}
			}

			CloseHandle(__dir);
		}
	}

	return;
}