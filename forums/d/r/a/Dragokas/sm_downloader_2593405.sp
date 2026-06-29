#define SM_DOWNLOADER_VERSION		"1.5"

/*******************************************************************************

  SM File/Folder Downloader and Precacher

  Author: SWAT_88 & Dragokas

  1.0 	First version, should work on basically any mod
 
  1.1	Added new features:	
		Added security checks.
		Added map specific downloads.
		Added simple downloads.
  1.2	Added Folder Download Feature.
  1.3	Version for testing.
  1.4	Fixed some bugs.
		Closed all open Handles.
		Added more security checks.

  Fork by Dragokas:

  1.5	Added "Late Downloader by Backup" extension support.
		Added warning (server msg) if file not exist on the server but listed in downloads(_simple).ini
		Removed ConVars (just because today I hate them ^_^).
		Updated to new syntax.
   
  Description:
  
	This Plugin downloads and precaches the Files in downloads.ini.
	There are several categories for Download and Precache in downloads.ini.
	The downloads_simple.ini contains simple downloads (no precache), like the original.
	Folder Download usage:
	Write your folder name in the downloads.ini or downloads_simple.ini.
	Example:
	Correct: sound/misc
	Incorrect: sound/misc/

  Commands:
  
	None.

  Variables:

	gb_normal	true		- false: dont use downloads.ini - true: Use downloads.ini
	
	gb_simple	true		- false: dont use downloads_simple.ini	- true: Use downloads_simple.ini

  Setup (SourceMod):

	Install the smx file to addons\sourcemod\plugins.
	Install the downloads.ini to addons\sourcemod\configs.
	Install the downloads_simple.ini to addons\sourcemod\configs.
	(Re)Load Plugin or change Map.
    Required: Sourcemod v.1.8 +
	
  TO DO:
  
	Nothing make a request.
	
  Copyright:
  
	Everybody can edit this plugin and copy this plugin.
	
  Thanks to:
	pRED*
	sfPlayer

  Tester:
	J@y-R
	FunTF2Server
	
  HAVE FUN!!!

*******************************************************************************/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <latedl>
#include <clientprefs>

#define DEBUG 1

bool gb_simple;
bool gb_normal;

char map[256];
bool downloadfiles=true;
char mediatype[256];
int downloadtype;

bool DoLateDownload = true;

// Number of files already downloaded and saved as cookie record for client
Handle hCookieNum;

// List of files to download (for everybody)
ArrayList g_aFileList;

// List of already downloaded files by client
ArrayList g_aClientFiles[MAXPLAYERS+1];

// Initial client to UserID binding
int g_aClientUserID[MAXPLAYERS+1];

// Index of currently downloaded file
int g_iCurFile[MAXPLAYERS+1];

float g_Download_Start_Delay = 20.0;
float g_Download_Interval_Delays = 5.0;

public Plugin myinfo = 
{
	name = "SM File/Folder Downloader and Precacher",
	author = "SWAT_88 & Dragokas",
	description = "Downloads and Precaches Files",
	version = SM_DOWNLOADER_VERSION,
	url = "http://www.sourcemod.net"
}

public void OnPluginStart()
{
	// use downloads_simple.ini
	gb_simple = true;

	// use downloads.ini
	gb_normal = true;

	hCookieNum = RegClientCookie("latedl_cookie_num", "", CookieAccess_Protected);

	RegAdminCmd("sm_latedl_clear_cookie", CmdClearCookie, ADMFLAG_ROOT, "Clear cookie of currently connected clients so they can re-download all files / and force re-downloading.");

	g_aFileList = new ArrayList(PLATFORM_MAX_PATH);

	// init all arraylists
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		g_aClientFiles[i] = new ArrayList(PLATFORM_MAX_PATH);
		g_iCurFile[i] = -1;
	}

	if(gb_normal) ReadDownloads();
	if(gb_simple) ReadDownloadsSimple();
}

public void OnClientPostAdminCheck(int client)
{
	char path[PLATFORM_MAX_PATH];
	g_iCurFile[client] = -1;
	
	// get the list of already downloaded files
	GetClientFiles(client);

	// Downloading files one by one using manual queue (using OnDownloadSuccess() forward)
	g_aFileList.GetString(0, path, sizeof(path));
//	DoDownload(client, path);
	DoDownloadDelayed(client, path, g_Download_Start_Delay);
}

public void OnMapStart(){
	if (!DoLateDownload) {
		char path[PLATFORM_MAX_PATH];

		// get full list of files everybody need to download
		for (int i = 0; i < g_aFileList.Length; i++)
		{
			g_aFileList.GetString(i, path, sizeof(path));
			DoDownload(0, path);
		}
	}
}

// to normalize client's bandwidth a little bit
void DoDownloadDelayed(int client, char[] path, float Delay)
{
	DataPack pack = new DataPack();
	CreateDataTimer(Delay, Timer_DownloadDelayed, pack);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(path);
}

public Action Timer_DownloadDelayed(Handle timer, DataPack pack)
{
	int client;
	char path[PLATFORM_MAX_PATH];

	ResetPack(pack);
	client = GetClientOfUserId(pack.ReadCell());
	pack.ReadString(path, sizeof(path));

	if (client != 0)
		DoDownload(client, path);

	// no need KillTimer (TIMER_DATA_HNDL_CLOSE is by default)
}

public void ReadFileFolder(char[] path){
	Handle dirh = INVALID_HANDLE;
	char buffer[256];
	char tmp_path[256];
	FileType type = FileType_Unknown;
	int len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';

	TrimString(path);
	
	if(DirExists(path)){
		dirh = OpenDirectory(path);
		while(ReadDirEntry(dirh,buffer,sizeof(buffer),type)){
			len = strlen(buffer);
			if (buffer[len-1] == '\n')
				buffer[--len] = '\0';

			TrimString(buffer);

			if (!StrEqual(buffer,"",false) && !StrEqual(buffer,".",false) && !StrEqual(buffer,"..",false)){
				strcopy(tmp_path,255,path);
				StrCat(tmp_path,255,"/");
				StrCat(tmp_path,255,buffer);
				if(type == FileType_File){
					if(downloadtype == 1){
						ReadItem(tmp_path);
					}
					else{
						ReadItemSimple(tmp_path);
					}
				}
				else{
					ReadFileFolder(tmp_path);
				}
			}
		}
	}
	else{
		if(downloadtype == 1){
			ReadItem(path);
		}
		else{
			ReadItemSimple(path);
		}
	}
	if(dirh != INVALID_HANDLE){
		CloseHandle(dirh);
	}
}

public void ReadDownloads(){
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/downloads.ini");
	Handle fileh = OpenFile(file, "r");
	char buffer[PLATFORM_MAX_PATH];
	downloadtype = 1;
	int len;
	
	GetCurrentMap(map,255);
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		if(!StrEqual(buffer,"",false)){
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		CloseHandle(fileh);
	}
}

public void ReadItem(char[] buffer){
	int len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	
	if(StrContains(buffer,"//Files (Download Only No Precache)",true) >= 0){
		strcopy(mediatype,255,"File");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Decal Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Decal");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Sound Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Sound");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Model Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Model");
		downloadfiles=true;
	}
	else if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
		if(StrContains(buffer,"//") >= 0){
			ReplaceString(buffer,255,"//","");
		}
		if(StrEqual(buffer,map,true)){
			downloadfiles=true;
		}
		else if(StrEqual(buffer,"Any",false)){
			downloadfiles=true;
		}
		else{
			downloadfiles=false;
		}
	}
	else if (!StrEqual(buffer,"",false))
	{
		if(FileExists(buffer))
		{
			if(downloadfiles){
				if(StrContains(mediatype,"Decal",true) >= 0){
					PrecacheDecal(buffer,true);
					// e.g. PrecacheModel("sprites/l4d_zone_1.vmt", true); if it's located in materials/sprites/l4d_zone_1.vmt
				}
				else if(StrContains(mediatype,"Sound",true) >= 0){
					PrecacheSound(buffer,true);
				}
				else if(StrContains(mediatype,"Model",true) >= 0){
					PrecacheModel(buffer,true);
				}
				AddToList(buffer);
			} else {
				PrintToServer("[SM_DOWNLOADER] Error: File not found on server: %s", buffer);
			}
		}
	}
}

public void ReadItemSimple(char[] buffer){
	int len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
	}
	else if (!StrEqual(buffer,"",false))
	{
		if (FileExists(buffer))
		{
			AddToList(buffer);
		} else {
			PrintToServer("[SM_DOWNLOADER] Error: File not found on server: %s", buffer);
		}
	}
}

// adds file to list for future download
void AddToList(char[] path)
{
	g_aFileList.PushString(path);
}

public void ReadDownloadsSimple(){
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/downloads_simple.ini");
	Handle fileh = OpenFile(file, "r");
	char buffer[PLATFORM_MAX_PATH];
	downloadtype = 2;
	int len;
	
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';

		TrimString(buffer);

		PrintDebug("ReadDownloadsSimple: %s", buffer);

		if(!StrEqual(buffer,"",false)){
			ReadFileFolder(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		CloseHandle(fileh);
	}
}

// download file to client using either "Late downloader", or download table based on "DoLateDownload" constant value
void DoDownload(int client, char[] path)
{
	if (DoLateDownload)
	{
		if (client == 0) {
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i)) {
					PrintDebug("Starting late downloading: client %i, file: %s", i, path);
					AddLateDownload(path, false, i);
				}
		} else {
			if (IsValidClient(client)) {

				/*
				// comment it because sm core think it's infinite recurse if N of calls > 70 (WTF)
				if (ClientFileExist(path, client))
				{
					PrintDebug("Already exists: client %i, file: %s", client, path);
					DoDownloadNextFile(client);
				} else {
					PrintDebug("Starting late downloading: client %i, file: %s", client, path);
					AddLateDownload(path, false, client);
				}
				*/

				// Walkaround
				char newpath[PLATFORM_MAX_PATH];
				strcopy(newpath, sizeof(newpath), path);

				while (ClientFileExist(newpath, client))
				{
					PrintDebug("Already exists: client %i, file: %s", client, newpath);
	
					if (++g_iCurFile[client] < g_aFileList.Length) {
						g_aFileList.GetString(g_iCurFile[client], newpath, sizeof(newpath));
					} else {
						return;
					}
				}
				PrintDebug("Starting late downloading: client %i, file: %s", client, newpath);
				AddLateDownload(newpath, false, client);
			}
		}
	} else {
		PrintDebug("Added to download tables: %s", path);
		AddFileToDownloadsTable(path);
	}
}

// remove number of already downloaded files from client's cookie
public Action CmdClearCookie (int client, int args) 
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsValidClient(i))
		{
			PrintToConsole(i, "[SM_DOWNLOADER] Re-downloading of resources will start in %f seconds.", g_Download_Start_Delay);
			SetClientCookie(i, hCookieNum, "0");
			OnClientPostAdminCheck(i);
		}
	return Plugin_Handled;
}

// add "already downloaded" mark in client's cookie for particular file
void PutFilenameInCookie(char[] path, int client)
{
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
		return;

	char sCookieNum[10];
	char sCookieName[25];
	int iCookieNum = 0;

	GetClientCookie(client, hCookieNum, sCookieNum, sizeof(sCookieNum));
	iCookieNum = StringToInt(sCookieNum);
	iCookieNum++;
	Format(sCookieName, sizeof(sCookieName), "latedl_cookie_%i", iCookieNum);
	Handle hCookie = RegClientCookie(sCookieName, "", CookieAccess_Protected);
	SetClientCookie(client, hCookie, path);
	CloseHandle(hCookie);
	IntToString(iCookieNum, sCookieNum, sizeof(sCookieNum));
	SetClientCookie(client, hCookieNum, sCookieNum);

	PrintDebug("SetClientCookie: client %i, path: %s, num: %s", client, path, sCookieNum);
}

// check file presence. By already downloaded list (ArrayList g_aClientFiles[client])
bool ClientFileExist(char[] path, int client)
{
	if (g_aClientUserID[client] == 0 || (GetClientOfUserId(g_aClientUserID[client]) != client) )
		GetClientFiles(client);

	return (g_aClientFiles[client].FindString(path) != -1);
}

// Send list of already downloaded files (from client's cookie) => to g_aClientFiles[client] ArrayList
void GetClientFiles(int client)
{
	if(AreClientCookiesCached(client))
	{
		delete g_aClientFiles[client];
		g_aClientFiles[client] = new ArrayList(PLATFORM_MAX_PATH);

		char sCookieNum[10];
		char sClientFile[PLATFORM_MAX_PATH+1];
		char sCookieName[25];
		int iCookieNum = 0;

		GetClientCookie(client, hCookieNum, sCookieNum, sizeof(sCookieNum));
		iCookieNum = StringToInt(sCookieNum);

		for (int i = 1; i <= iCookieNum; i++)
		{
			Format(sCookieName, sizeof(sCookieName), "latedl_cookie_%i", i);
			Handle hCookie = RegClientCookie(sCookieName, "", CookieAccess_Protected);
			GetClientCookie(client, hCookie, sClientFile, sizeof(sClientFile));
			CloseHandle(hCookie);
			g_aClientFiles[client].PushString(sClientFile);
		}
		// save binding
		g_aClientUserID[client] = GetClientUserId(client);
	}
}

bool IsValidClient(int client)
{
	return (client != 0 && IsClientInGame(client) && !IsFakeClient(client));
}

public void OnDownloadSuccess(int client, char[] path)
{
	if (client == 0) return;
	
	PutFilenameInCookie(path, client);

	if (g_aClientUserID[client] == 0 || (GetClientOfUserId(g_aClientUserID[client]) != client) )
	{
		GetClientFiles(client);
	} else {
		g_aClientFiles[client].PushString(path);
	}
	PrintDebug("Success with client: %i. File: %s", client, path);

	DoDownloadNextFile(client);
}

//set new file to download
void DoDownloadNextFile(int client)
{
	if (++g_iCurFile[client] < g_aFileList.Length) {
		char newpath[PLATFORM_MAX_PATH];
		g_aFileList.GetString(g_iCurFile[client], newpath, sizeof(newpath));
		// DoDownload(client, newpath);
		DoDownloadDelayed(client, newpath, g_Download_Interval_Delays);
	}	
}

public void OnDownloadFailure(int client, char[] path)
{
	if (client == 0) return;
	PrintDebug("!!! FAILURE !!! with client: %i. File: %s", client, path);

	//try again
	if (IsValidClient(client))
		// DoDownload(client, path);
		DoDownloadDelayed(client, path, g_Download_Interval_Delays);
}

void PrintDebug(const char[] format, any ...)
{
	#if !DEBUG
		return;
	#endif
	char buffer[200];
	VFormat(buffer, sizeof(buffer), format, 2);
	char buf2[250];
	Format(buf2, sizeof(buf2), "[SM_DOWNLOADER] %i: %s", GetSysTickCount(), buffer);
	PrintToServer(buf2);
}
