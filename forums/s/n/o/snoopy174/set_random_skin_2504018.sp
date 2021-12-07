#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Set Random Skin",
	author = "acik_traiks",
	version = "1.70.315"
}; 


#define Parh_Dir "cfg/sourcemod/set_random_skin"
#define Parh_File_T "cfg/sourcemod/set_random_skin/skin_t.txt"
#define Parh_File_CT "cfg/sourcemod/set_random_skin/skin_ct.txt"
#define Parh_File_Downloads "cfg/sourcemod/set_random_skin/downloads.txt"

new Handle:array_SkinT;
new Handle:array_SkinCT;

new iNo_T;
new iNo_CT;

public OnPluginStart()
{
	array_SkinT = CreateArray(255);
	array_SkinCT = CreateArray(255);
	
	HookEvent("player_spawn", PlayerSpawn);
}

public OnMapStart()
{
	CreateDir(Parh_Dir);
	
	CreateFile(Parh_File_T, 2);
	OpenFileSkin(Parh_File_T, 2);
	
	CreateFile(Parh_File_CT, 3);
	OpenFileSkin(Parh_File_CT, 3);
	
	CreateFile(Parh_File_Downloads, 0);
	OpenFileDownloads(Parh_File_Downloads);
	
	ClearArray(array_SkinT);
	ClearArray(array_SkinCT);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	CreateTimer(0.1, SetSkin, client);
}

public Action:SetSkin(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	decl String:skin[255];
	switch(GetClientTeam(client))
	{
		case 2:
		{
			if(GetArraySize(array_SkinT) < 1) return;
			
			GetArrayString(array_SkinT, iNo_T, skin, sizeof(skin));
			SetEntityModel(client, skin);
			if(++iNo_T >= GetArraySize(array_SkinT)) iNo_T = 0;
		}
		case 3:
		{
			if(GetArraySize(array_SkinCT) < 1) return;
			
			GetArrayString(array_SkinCT, iNo_CT, skin, sizeof(skin));
			SetEntityModel(client, skin);
			if(++iNo_CT >= GetArraySize(array_SkinCT)) iNo_CT = 0;
		}
	}
}

stock CreateFile(String:filename[], team)
{
	if(!FileExists(filename))
	{
		new Handle:file = OpenFile(filename, "w+");
		if (file != INVALID_HANDLE) 
		{
			if(team > 1)
			{
				WriteFileLine(file, "//Пути моделей в строчку для %s", team == 2 ? "T": "CT");
				WriteFileLine(file, "//Привет:");
				WriteFileLine(file, "//\tmodel/player/skin1.mdl");
				WriteFileLine(file, "//\tmodel/player/skin2.mdl");
				WriteFileLine(file, "//\tmodel/player/skin3.mdl");
			}
			else
			{
				WriteFileLine(file, "//Загрузчик");
			}
			CloseHandle(file);
		}
	}
}

stock CreateDir(const String:Directory[])
{

	new iSize = strlen(Directory)+1;
	new String:sDirectory[iSize];
	strcopy(sDirectory, iSize, Directory);	
	
	DeleteLastSlash(sDirectory);
	
	new slash = 0;
	new ind = 0;
	
	do
	{
		if(sDirectory[ind] == '/')
		{
			slash++;
		}
		ind++;
	}	
	while(ind < iSize);
	
	new String:sBuffer[slash+1][iSize];
	ExplodeString(sDirectory, "/", sBuffer, slash+1, iSize);
	
	ind = 0;

	new String:buffer[512] = ".";
	for(ind = 0; ind <= slash; ind++)
	{
		Format(buffer, sizeof(buffer), "%s/%s", buffer, sBuffer[ind]);
		if(!DirExists(buffer))
			CreateDirectory(buffer, FPERM_U_READ+FPERM_U_WRITE+FPERM_U_EXEC+
											FPERM_G_READ+FPERM_G_WRITE+FPERM_G_EXEC+
											FPERM_O_READ+FPERM_O_WRITE+FPERM_O_EXEC);
	}
}

stock DeleteLastSlash(String:sDirectory[])
{
	new iSize = strlen(sDirectory);
	if(sDirectory[iSize-1] == '/')
	{
		iSize--;
		sDirectory[iSize] = '\0';
		return iSize;
	}
	return iSize;
}

OpenFileSkin(String:filename[], team)
{
	new Handle:file = OpenFile(filename, "r");
	if (file  == INVALID_HANDLE) return;
	new String:buffer[PLATFORM_MAX_PATH];
	while (!IsEndOfFile(file)) {
		ReadFileLine(file, buffer, sizeof(buffer));
		new pos;
		pos = StrContains(buffer, "//");
		if (pos != -1) buffer[pos] = '\0';
		pos = StrContains(buffer, "#");
		if (pos != -1) buffer[pos] = '\0';
		pos = StrContains(buffer, ";");
		if (pos != -1) buffer[pos] = '\0';
		TrimString(buffer);
		if (buffer[0] == '\0') continue;
		if(buffer[0] != 'm' && strlen(buffer)-4 != StrContains(buffer, ".mdl")) continue;
		if(FindStringInArray(team == 2 ? array_SkinT : array_SkinCT, buffer) > -1) continue;
		PushArrayString(team == 2 ? array_SkinT : array_SkinCT, buffer);
	}
	CloseHandle(file);
}

stock OpenFileDownloads(const String:path[])
{
	new Handle:file = OpenFile(path, "r");
	if (file  == INVALID_HANDLE) return;
	new String:buffer[PLATFORM_MAX_PATH];
	while (!IsEndOfFile(file)) {
		ReadFileLine(file, buffer, sizeof(buffer));
		new pos;
		pos = StrContains(buffer, "//");
		if (pos != -1) buffer[pos] = '\0';
		pos = StrContains(buffer, "#");
		if (pos != -1) buffer[pos] = '\0';
		pos = StrContains(buffer, ";");
		if (pos != -1) buffer[pos] = '\0';
		TrimString(buffer);
		if (buffer[0] == '\0') continue;
		File_AddToDownloadsTable(buffer);
	}
	CloseHandle(file);
}

new String:_smlib_empty_twodimstring_array[][] = { { '\0' } };
stock File_AddToDownloadsTable(const String:path[], bool:recursive=true, const String:ignoreExts[][]=_smlib_empty_twodimstring_array, size=0)
{
	if (path[0] == '\0') return;
	if (FileExists(path)) {
		new String:fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));
		if (StrEqual(fileExtension, "bz2", false) || StrEqual(fileExtension, "ztmp", false)) return;
		if (Array_FindString(ignoreExts, size, fileExtension) != -1) return;
		AddFileToDownloadsTable(path);
	}
	else if (recursive && DirExists(path)) {
		decl String:dirEntry[PLATFORM_MAX_PATH];
		new Handle:__dir = OpenDirectory(path);
		while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {
			if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) continue;
			Format(dirEntry, sizeof(dirEntry), "%s/%s", path, dirEntry);
			File_AddToDownloadsTable(dirEntry, recursive, ignoreExts, size);
		}
		CloseHandle(__dir);
	}
	else if (FindCharInString(path, '*', true)) {
		new String:fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));
		if (StrEqual(fileExtension, "*")) {
			decl String:dirName[PLATFORM_MAX_PATH],String:fileName[PLATFORM_MAX_PATH],String:dirEntry[PLATFORM_MAX_PATH];
			File_GetDirName(path, dirName, sizeof(dirName));
			File_GetFileName(path, fileName, sizeof(fileName));
			StrCat(fileName, sizeof(fileName), ".");
			new Handle:__dir = OpenDirectory(dirName);
			while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {
				if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) continue;
				if (strncmp(dirEntry, fileName, strlen(fileName)) == 0) {
					Format(dirEntry, sizeof(dirEntry), "%s/%s", dirName, dirEntry);
					File_AddToDownloadsTable(dirEntry, recursive, ignoreExts, size);
				}
			}
			CloseHandle(__dir);
		}
	}
	return;
}

stock File_GetExtension(const String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, '.', true);
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}
	strcopy(buffer, size, path[++extpos]);
}

stock Array_FindString(const String:array[][], size, const String:str[], bool:caseSensitive=true, start=0)
{
	if (start < 0) start = 0;
	for (new i=start; i < size; i++) if (StrEqual(array[i], str, caseSensitive)) return i;
	return -1;
}

stock bool:File_GetFileName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	File_GetBaseName(path, buffer, size);
	new pos_ext = FindCharInString(buffer, '.', true);
	if (pos_ext != -1) buffer[pos_ext] = '\0';
}

stock bool:File_GetDirName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	new pos_start = FindCharInString(path, '/', true);
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
		if (pos_start == -1) {
			buffer[0] = '\0';
			return;
		}
	}
	strcopy(buffer, size, path);
	buffer[pos_start] = '\0';
}

stock bool:File_GetBaseName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	new pos_start = FindCharInString(path, '/', true);
	if (pos_start == -1) pos_start = FindCharInString(path, '\\', true);
	pos_start++;
	strcopy(buffer, size, path[pos_start]);
}
