/*******************************************************************************

  SM File/Folder Downloader and Precacher

  Version: 1.4
  Author: SWAT_88

  1.0 	First version, should work on basically any mod

  1.1	Added features
		Added security checks.
		Added g_sMapName specific downloads.
		Added simple downloads.
  1.2	Added Folder Download Feature.
  1.3	Version for testing.
  1.4	Fixed some bugs.
		Closed all open Handles.
		Added more security checks.

  Description:

	This Plugin downloads and precaches the Files in downloads.ini.
	There are several categories for Download and Precache in downloads.ini.
	The downloads_simple.ini contains simple downloads (no precache), like the original.
	Folder Download usage:
	Write your folder name in the downloads.ini or downloads_simple.ini.
	Example
	Correct  sound/misc
	Incorrect  sound/misc/

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
	(Re)Load Plugin or change g_sMapName.

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
#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.5"

ConVar g_cvarEnabled;
ConVar g_cvarSimple;
ConVar g_cvarNormal;

char g_sMapName[256];
bool g_bDownloadFiles = true;
char g_sMediaType[256];
int g_iDownloadType;

public Plugin myinfo = {
	name = "SM File/Folder Downloader and Precacher",
	author = "SWAT_88",
	description = "Downloads and Precaches Files",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public void OnPluginStart() {
	g_cvarSimple = CreateConVar("sm_downloader_simple", "1", "", FCVAR_NONE);
	g_cvarNormal = CreateConVar("sm_downloader_normal", "1", "", FCVAR_NONE);
	g_cvarEnabled = CreateConVar("sm_downloader_enabled", "1", "", FCVAR_NONE);
	CreateConVar("sm_downloader_version", PLUGIN_VERSION, "SM File Downloader and Precacher Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD).SetString(PLUGIN_VERSION);
}

public void OnMapStart() {
	if (g_cvarEnabled.BoolValue) {
		if (g_cvarNormal.BoolValue) {
			ReadDownloads();
		}
		if (g_cvarSimple.BoolValue) {
			ReadDownloadsSimple();
		}
	}
}

public void ReadFileFolder(char[] path) {
	DirectoryListing dirh = null;
	char buffer[256];
	char tmp_path[256];
	FileType type = FileType_Unknown;
	int len;

	len = strlen(path);
	if (path[len-1] == '\n') {
		path[--len] = '\0';
	}

	TrimString(path);

	if (DirExists(path)) {
		dirh = OpenDirectory(path);
		while (dirh.GetNext(buffer, sizeof(buffer), type)) {
			len = strlen(buffer);
			if (buffer[len-1] == '\n') {
				buffer[--len] = '\0';
			}

			TrimString(buffer);

			if ((buffer[0] != '\0') && !StrEqual(buffer, ".", false) && !StrEqual(buffer, "..", false)) {
				strcopy(tmp_path, 255, path);
				StrCat(tmp_path, 255, "/");
				StrCat(tmp_path, 255, buffer);
				if (type == FileType_File) {
					if (g_iDownloadType == 1) {
						ReadItem(tmp_path);
					}
					else {
						ReadItemSimple(tmp_path);
					}
				}
				else {
					ReadFileFolder(tmp_path);
				}
			}
		}
	}
	else {
		if (g_iDownloadType == 1) {
			ReadItem(path);
		}
		else {
			ReadItemSimple(path);
		}
	}
	delete dirh;
}

public void ReadDownloads() {
	char file[256];
	BuildPath(Path_SM, file, 255, "configs/downloads.ini");
	File fileh = OpenFile(file, "r");
	char buffer[256];
	g_iDownloadType = 1;
	int len;

	GetCurrentMap(g_sMapName, 255);

	if (fileh == null) {
		return;
	}
	while (fileh.ReadLine(buffer, sizeof(buffer))) {
		len = strlen(buffer);
		if (buffer[len-1] == '\n') {
			buffer[--len] = '\0';
		}

		TrimString(buffer);

		if (buffer[0] != '\0') {
			ReadFileFolder(buffer);
		}

		if (fileh.EndOfFile()) {
			break;
		}
	}
	if (fileh != null) {
		delete fileh;
	}
}

public void ReadItem(char[] buffer) {
	int len = strlen(buffer);
	if (buffer[len-1] == '\n')
		buffer[--len] = '\0';
	
	TrimString(buffer);
	
	if (StrContains(buffer, "//Files (Download Only No Precache)", true) >= 0) {
		strcopy(g_sMediaType, 255, "File");
		g_bDownloadFiles=true;
	}
	else if (StrContains(buffer, "//Decal Files (Download and Precache)", true) >= 0) {
		strcopy(g_sMediaType, 255, "Decal");
		g_bDownloadFiles=true;
	}
	else if (StrContains(buffer, "//Sound Files (Download and Precache)", true) >= 0) {
		strcopy(g_sMediaType, 255, "Sound");
		g_bDownloadFiles=true;
	}
	else if (StrContains(buffer, "//Model Files (Download and Precache)", true) >= 0) {
		strcopy(g_sMediaType, 255, "Model");
		g_bDownloadFiles=true;
	}
	else if (len >= 2 && buffer[0] == '/' && buffer[1] == '/') {
		//Comment
		if (StrContains(buffer, "//") >= 0) {
			ReplaceString(buffer, 255, "//", "");
		}
		if (StrEqual(buffer, g_sMapName, true)) {
			g_bDownloadFiles=true;
		}
		else if (StrEqual(buffer, "Any", false)) {
			g_bDownloadFiles=true;
		}
		else {
			g_bDownloadFiles=false;
		}
	}
	else if ((buffer[0] != '\0') && (FileExists(buffer, true, NULL_STRING)))
	{
		if (g_bDownloadFiles) {
			if (StrContains(g_sMediaType, "Decal", true) >= 0) {
				PrecacheDecal(buffer, true);
			}
			else if (StrContains(g_sMediaType, "Sound", true) >= 0) {
				PrecacheSound(buffer, true);
			}
			else if (StrContains(g_sMediaType, "Model", true) >= 0) {
				PrecacheModel(buffer, true);
			}
			AddFileToDownloadsTable(buffer);
		}
	}
}

public void ReadDownloadsSimple() {
	char path[256];
	BuildPath(Path_SM, path, 255, "configs/downloads_simple.ini");
	File file = OpenFile(path, "r");
	char buffer[256];
	g_iDownloadType = 2;
	int len;

	if (file == null) {
		return;
	}
	while (!file.EndOfFile() && file.ReadLine(buffer, sizeof(buffer))) {
		len = strlen(buffer);
		if (buffer[len-1] == '\n') {
			buffer[--len] = '\0';
		}

		TrimString(buffer);

		if (buffer[0] != '\0') {
			ReadFileFolder(buffer);
		}
	}
	delete file;
}

public void ReadItemSimple(char[] buffer) {
	int len = strlen(buffer);
	if (buffer[len-1] == '\n') {
		buffer[--len] = '\0';
	}

	TrimString(buffer);
	if (len >= 2 && buffer[0] == '/' && buffer[1] == '/') {
		//Comment
	}
	else if ((buffer[0] != '\0') && FileExists(buffer, true, NULL_STRING)) {
		AddFileToDownloadsTable(buffer);
	}
}
