/*******************************************************************************

  SM File/Folder Downloader and Precacher

  Version: 1.2
  Author: SWAT_88

  1.0 	First version, should work on basically any mod
 
  1.1	Added new features:	
		Added security checks.
		Added map specific downloads.
		Added simple downloads.
  1.2	Added Folder Download Feature.
		
   
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

  Cvars:

	sm_downloader_enabled 	"1"		- 0: disables the plugin - 1: enables the plugin
	
	sm_downloader_normal	"1"		- 0: dont use downloads.ini - 1: Use downloads.ini
	
	sm_downloader_simple	"1"		- 0: dont use downloads_simple.ini	- 1: Use downloads_simple.ini

  Setup (SourceMod):

	Install the smx file to addons\sourcemod\plugins.
	Install the downloads.ini to addons\sourcemod\configs.
	Install the downloads_simple.ini to addons\sourcemod\configs.
	(Re)Load Plugin or change Map.
	
  TO DO:
  
	Nothing make a request.
	
  Copyright:
  
	Everybody can edit this plugin and copy this plugin.
	
  Thanks to:
	pRED*
	sfPlayer
	
  HAVE FUN!!!

*******************************************************************************/

#include <sourcemod>
#include <sdktools>

#define SM_DOWNLOADER_VERSION		"1.3"

new Handle:g_version=INVALID_HANDLE;
new Handle:g_enabled=INVALID_HANDLE;
new Handle:g_simple=INVALID_HANDLE;
new Handle:g_normal=INVALID_HANDLE;

new String:map[256];
new bool:downloadfiles=true;
new String:mediatype[256];
new downloadtype;

new String:logfile[256];
new Handle:logfileh

public Plugin:myinfo = 
{
	name = "SM File/Folder Downloader and Precacher",
	author = "SWAT_88",
	description = "Downloads and Precaches Files",
	version = SM_DOWNLOADER_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	g_simple = CreateConVar("sm_downloader_simple","1");
	g_normal = CreateConVar("sm_downloader_normal","1");
	g_enabled = CreateConVar("sm_downloader_enabled","1");
	g_version = CreateConVar("sm_downloader_version",SM_DOWNLOADER_VERSION,"SM File Downloader and Precacher Version",FCVAR_NOTIFY);
	SetConVarString(g_version,SM_DOWNLOADER_VERSION);

	BuildPath(Path_SM, logfile, 255, "configs/downloads.log");
	logfileh = OpenFile(logfile, "w");
}

public OnPluginEnd(){
	CloseHandle(g_version);
	CloseHandle(g_enabled);
	CloseHandle(g_simple);
	CloseHandle(g_normal);
	CloseHandle(logfileh);
}

public OnMapStart(){	
	if(GetConVarInt(g_enabled) == 1){
		if(GetConVarInt(g_normal) == 1) ReadDownloads();
		if(GetConVarInt(g_simple) == 1) ReadDownloadsSimple();
	}
}

public ReadFileFolder(String:path[]){
	new Handle:dirh = INVALID_HANDLE;
	new String:buffer[256];
	new String:tmp_path[256];
	new FileType:type = FileType_Unknown;
	new len;
	
	len = strlen(path);
	if (path[len-1] == '\n')
		path[--len] = '\0';

	TrimString(path);
	
	WriteFileLine(logfileh,"Start ReadFileFolder");
	
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
						WriteFileLine(logfileh,"ReadItem");
					}
					else{
						ReadItemSimple(tmp_path);
						WriteFileLine(logfileh,"ReadItem Simple");
					}
				}
				else{
					WriteFileLine(logfileh,"ReadFileFolder");
					ReadFileFolder(tmp_path);
				}
			}
		}
	}
	else{
		if(downloadtype == 1){
			ReadItem(path);
			WriteFileLine(logfileh,"ReadItem");
		}
		else{
			ReadItemSimple(path);
			WriteFileLine(logfileh,"ReadItem Simple");
		}
	}
	if(dirh != INVALID_HANDLE){
		WriteFileLine(logfileh,"Close Dir");
		CloseHandle(dirh);
	}
}

public ReadDownloads(){
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/downloads.ini");
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	downloadtype = 1;
	
	GetCurrentMap(map,255);
	WriteFileLine(logfileh,"Open downloads.ini");
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{	
		WriteFileLine(logfileh,buffer);
		ReadFileFolder(buffer);
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		WriteFileLine(logfileh,"Close File");
		CloseHandle(fileh);
	}
}

public ReadItem(String:buffer[]){
	new len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	
	WriteFileLine(logfileh,"Start ReadItem");
	
	if(StrContains(buffer,"//Files (Download Only No Precache)",true) >= 0){
		strcopy(mediatype,255,"File");
		WriteFileLine(logfileh,"Files Category");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Decal Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Decal");
		WriteFileLine(logfileh,"Decal Category");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Sound Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Sound");
		WriteFileLine(logfileh,"Sound Category");
		downloadfiles=true;
	}
	else if(StrContains(buffer,"//Model Files (Download and Precache)",true) >= 0){
		strcopy(mediatype,255,"Model");
		WriteFileLine(logfileh,"Model Category");
		downloadfiles=true;
	}
	else if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
		WriteFileLine(logfileh,"Comment");
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
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		WriteFileLine(logfileh,"In Download ",buffer);
		if(downloadfiles){
			WriteFileLine(logfileh,"downloadfile == true",buffer);
		}
		else{
			WriteFileLine(logfileh,"dwonloadfiles == false",buffer);
		}
		if(downloadfiles){
			if(StrContains(mediatype,"Decal",true) >= 0){
				PrecacheDecal(buffer,true);
				WriteFileLine(logfileh,"Precache Decal: %s",buffer);
			}
			else if(StrContains(mediatype,"Sound",true) >= 0){
				PrecacheSound(buffer,true);
				WriteFileLine(logfileh,"Precache Sound: %s",buffer);
			}
			else if(StrContains(mediatype,"Model",true) >= 0){
				PrecacheModel(buffer,true);
				WriteFileLine(logfileh,"Precache Model: %s",buffer);
			}
			AddFileToDownloadsTable(buffer);
			WriteFileLine(logfileh,"Add File: %s",buffer);
			WriteFileLine(logfileh,"Add File:");
		}
	}
}

public ReadDownloadsSimple(){
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/downloads_simple.ini");
	new Handle:fileh = OpenFile(file, "r");
	new String:buffer[256];
	downloadtype = 2;
	
	WriteFileLine(logfileh,"Open downloads_simple.ini");
	if(fileh == INVALID_HANDLE) return;
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		WriteFileLine(logfileh,buffer);
		ReadFileFolder(buffer);
		
		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		WriteFileLine(logfileh,"Close File");
		CloseHandle(fileh);
	}
}

public ReadItemSimple(String:buffer[]){
	new len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	WriteFileLine(logfileh,"Start ReadItemSimple");
	
	TrimString(buffer);
	if(len >= 2 && buffer[0] == '/' && buffer[1] == '/'){
		//Comment
	}
	else if (!StrEqual(buffer,"",false) && FileExists(buffer))
	{
		AddFileToDownloadsTable(buffer);
		WriteFileLine(logfileh,"Add File Simple: %s",buffer);
	}
}
