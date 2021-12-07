/*
 * SourceMod Radio Playlist Converter
 *
 * Converts your old radiostations_vol.ini to the version 2 KeyValue format
 *
 * Simple Usage:
 *
 * Make sure you have the RCON admin flag and type in the console: sm_plconvert 1 or 2
 * 
 * 1 = Convert and output to "sourcemod\configs\radiovolume.txt"
 * 2 = Convert and output to "sourcemod\configs\shoutcastcustom.txt"
 *
 * Coded by dubbeh - www.dubbeh.net
 *
 * Licensed under the GPLv3
 *
 */


#pragma semicolon 1

#define PLUGIN_AUTHOR "dubbeh"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Radio Playlist Converter",
	author = PLUGIN_AUTHOR,
	description = "Converts old Radio 1 volume playlists to version 2",
	version = PLUGIN_VERSION,
	url = "www.dubbeh.net"
};

int g_iOutType = 2;
char g_szRadioStationsFile[PLATFORM_MAX_PATH + 1] = "cfg/sourcemod/radiostations_vol.ini";
char g_szRadioOffPage[] = "about:blank";
char g_szBrowseFixURL[] = "https://dubbeh.net/sm/rbf.php";
char g_szVolumeWrapperURL[] = "https://dubbeh.net/sm/rvw.html";
Handle g_hArrayStationNames = INVALID_HANDLE;
Handle g_hArrayStationURLs = INVALID_HANDLE;

public void OnPluginStart()
{
	RegAdminCmd("sm_plconvert", Command_ConvertPlaylist, ADMFLAG_RCON, "Convert old Radio version 1 playlists to version 2");
}

public Action Command_ConvertPlaylist(int iClient, int iArgs)
{
	char szOutType[12] = "";
	int iStationCount = 0;
	
	if (iArgs < 1)
	{
		InvalidInput(iClient);
		return Plugin_Handled;
	}
	
	GetCmdArg(1, szOutType, sizeof(szOutType));
	g_iOutType = StringToInt(szOutType);
	
	if (g_iOutType < 1 || g_iOutType > 2)
	{
		InvalidInput(iClient);
		return Plugin_Handled;
	}
	
	g_hArrayStationNames = CreateArray(PLATFORM_MAX_PATH, 0);
	g_hArrayStationURLs = CreateArray(PLATFORM_MAX_PATH, 0);
	iStationCount = LoadOldFormat();
	
	if (iStationCount > 0)
	{
		ReplyToCommand(iClient, "Found %d stations in old format to be converted.", iStationCount);
		ConvertToNewFormat();
		ReplyToCommand(iClient, "Playlist conversion completed.");
	} else {
		ReplyToCommand(iClient, "Error: No stations found in \"%s\" to be converted", g_szRadioStationsFile);
	}
	
	ClearArray(g_hArrayStationNames);
	CloseHandle(g_hArrayStationNames);
	ClearArray(g_hArrayStationURLs);
	CloseHandle(g_hArrayStationURLs);
	return Plugin_Handled;
}

void InvalidInput (int iClient)
{
	ReplyToCommand(iClient, "Radio Playlist Converter - Invalid input.");
	ReplyToCommand(iClient, "Usage: sm_plconvert \"1-2\"");
	ReplyToCommand(iClient, "1 = Output as Volume Control (radiovolume.txt)");
	ReplyToCommand(iClient, "2 = Output as ShoutCast Custom (shoutcastcustom.txt)");
}

void ConvertToNewFormat()
{
	char szStationName[192] = "";
	char szStationURL[192] = "";
	char szOutputFile[PLATFORM_MAX_PATH + 1] = "";
	KeyValues kv;
	int iArraySize = 0;
	int iIndex = 0;
	
	if (g_iOutType == 1) {
		BuildPath(Path_SM, szOutputFile, sizeof(szOutputFile), "configs/%s", "radiovolume.txt");
	} else {
		BuildPath(Path_SM, szOutputFile, sizeof(szOutputFile), "configs/%s", "shoutcastcustom.txt");
	}
	
	kv = new KeyValues("Radio Stations");
	
	kv.SetString("Off Page", g_szRadioOffPage);
	kv.SetString("Volume Wrapper", g_szVolumeWrapperURL);
	kv.SetString("Browse Fix", g_szBrowseFixURL);
	kv.SetString("Use Genres", "0");
	
	iArraySize = GetArraySize(g_hArrayStationNames);
	
	for (iIndex = 0; iIndex < iArraySize; iIndex++)
	{
		GetArrayString (g_hArrayStationNames, iIndex, szStationName, sizeof(szStationName));
		GetArrayString (g_hArrayStationURLs, iIndex, szStationURL, sizeof(szStationURL));
		kv.JumpToKey(szStationName, true);
		kv.SetNum("Station ID", GetURandomInt());
		kv.SetString("Stream URL", szStationURL);
		kv.GoBack();
	}
	
	kv.Rewind();
	kv.ExportToFile(szOutputFile);
	delete kv;
	return;
}

int LoadOldFormat()
{
	char szLineBuffer[256] = "";
	char szTempBuffer[256] = "";
	int iIndex = 0;
	int iPos = -1;
	File hFile = null;
	int iStationCount = 0;
	
	iStationCount = 0;
	
	if ((hFile = OpenFile(g_szRadioStationsFile, "r")) != INVALID_HANDLE)
	{
		while (!hFile.EndOfFile() && hFile.ReadLine(szLineBuffer, sizeof(szLineBuffer)))
		{
			TrimString(szLineBuffer);
			
			if ((szLineBuffer[0] != '\0') && (szLineBuffer[0] != ';') && (szLineBuffer[0] != '/') && (szLineBuffer[1] != '/') && (szLineBuffer[0] == '"') && (szLineBuffer[0] != '\n') && (szLineBuffer[1] != '\n'))
			{
				iIndex = 0;
				if ((iPos = BreakString(szLineBuffer[iIndex], szTempBuffer, sizeof(szTempBuffer))) != -1)
				{
					iIndex += iPos;
					
					if (!strcmp("Off Page", szTempBuffer, false))
					{
						strcopy(g_szRadioOffPage, sizeof(g_szRadioOffPage), szLineBuffer[iIndex]);
					}
					else if (!strcmp("Browse Fix", szTempBuffer, false))
					{
						strcopy(g_szBrowseFixURL, sizeof(g_szBrowseFixURL), szLineBuffer[iIndex]);
					}
					else if (!strcmp("Volume Wrapper", szTempBuffer, false))
					{
						strcopy(g_szVolumeWrapperURL, sizeof(g_szVolumeWrapperURL), szLineBuffer[iIndex]);
					}
					else
					{
						// Fix strings for keyvalues outputting
						StripQuotes(szTempBuffer);
						ReplaceString(szTempBuffer, sizeof(szTempBuffer), "http://", "", true);
						ReplaceString(szTempBuffer, sizeof(szTempBuffer), "\\", "-", true);
						ReplaceString(szTempBuffer, sizeof(szTempBuffer), "/", "-", true);
						PushArrayString(g_hArrayStationNames, szTempBuffer);
						PushArrayString(g_hArrayStationURLs, szLineBuffer[iIndex]);
						iStationCount++;
					}
				}
			}
		}
		
		hFile.Close();
		hFile = null;
		return iStationCount;
	}
	
	return 0;
}