/*

*/

#pragma semicolon 1
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <socket>			//https://forums.alliedmods.net/showthread.php?t=67640
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

ConVar g_cWebPgPass = null;
char g_sWebPgPass[50];
ConVar g_cWebPgLocation = null;
char g_sWebPgLocation[PLATFORM_MAX_PATH];

char g_sPort[7];
char g_sUrl[PLATFORM_MAX_PATH];
char g_sRealUrl[PLATFORM_MAX_PATH];
char g_sRealPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "TOG Create Web Folder",
	author = "That One Guy",
	description = "Simple plugin to call a web script to create a folder if not existing",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/index.php"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togcreatewebfolder");
	AutoExecConfig_CreateConVar("version_togcreatewebfolder", PLUGIN_VERSION, "TOG Create Web Folder - Version number.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cWebPgPass = AutoExecConfig_CreateConVar("tcwf_webpg_pass", "XXXXXXX", "Password to pass to web page.", FCVAR_NONE);
	g_cWebPgPass.GetString(g_sWebPgPass, sizeof(g_sWebPgPass));
	g_cWebPgPass.AddChangeHook(OnCVarChange);
	
	g_cWebPgLocation = AutoExecConfig_CreateConVar("tcwf_webpg_url", "https://www.togcoding.com/demos/", "Location of togcreatewebfolder.php", FCVAR_NONE);
	g_cWebPgLocation.GetString(g_sWebPgLocation, sizeof(g_sWebPgLocation));
	g_cWebPgLocation.AddChangeHook(OnCVarChange);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	Format(g_sPort, sizeof(g_sPort), "%i", GetConVarInt(FindConVar("hostport")));
	URLEncode(g_sPort, sizeof(g_sPort));
	Log("test.log", "g_sPort=%s", g_sPort);
	
	CreatePortFolder();
}

public void OnCVarChange(ConVar hCVar, const char[] sOldValue, const char[] sNewValue)
{
	if(hCVar == g_cWebPgPass)
	{
		g_cWebPgPass.GetString(g_sWebPgPass, sizeof(g_sWebPgPass));
		URLEncode(g_sWebPgPass, sizeof(g_sWebPgPass));
	}
	else if(hCVar == g_cWebPgLocation)
	{
		g_cWebPgLocation.GetString(g_sWebPgLocation, sizeof(g_sWebPgLocation));
	}
}

void CreatePortFolder()
{
	Log("test.log", "1");
	strcopy(g_sUrl, sizeof(g_sUrl), g_sWebPgLocation);
	PreFormatUrl();
	Log("test.log", "g_sUrl=%s", g_sUrl);
	Log("test.log", "g_sRealUrl=%s", g_sRealUrl);
	Log("test.log", "g_sRealPath=%s", g_sRealPath);
	
	Handle hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetOption(hSocket, DebugMode, 1);		//Log("test.log", "
	SocketSetOption(hSocket, ConcatenateCallbacks, 4096);
	SocketSetOption(hSocket, SocketReceiveTimeout, 5);
	SocketSetOption(hSocket, SocketSendTimeout, 5);
	SocketConnect(hSocket, SocketCB_Connected, SocketCB_Recieve, SocketCB_Disconnect, g_sRealUrl, 80);
}

void PreFormatUrl()
{
	strcopy(g_sRealUrl, sizeof(g_sRealUrl), g_sUrl);
	
	if(StrContains(g_sRealUrl, "http://") == 0)
	{
		ReplaceString(g_sRealUrl, sizeof(g_sRealUrl), "http://", "");
	}
	if(StrContains(g_sRealUrl, "https://") == 0)
	{
		ReplaceString(g_sRealUrl, sizeof(g_sRealUrl), "https://", "");
	}
	if(StrContains(g_sRealUrl, "www.") == 0)
	{
		//ReplaceString(g_sRealUrl, sizeof(g_sRealUrl), "www.", "");
	}
	
	int iIndex;
	if((iIndex = StrContains(g_sRealUrl, "/")) != -1 )	// We strip from / of the url to get the path
	{
		strcopy(g_sRealPath, sizeof(g_sRealPath), g_sRealUrl[iIndex]);	// Copy from there
		
		int iLen = strlen(g_sRealPath);	// Strip the slash of the path if there is one
		if(iLen > 0 && g_sRealPath[iLen - 1] == '/')
		{
			g_sRealPath[iLen -1] = '\0';
		}
		
		g_sRealUrl[iIndex] = '\0';	// Strip the url from there the rest
	}
}

public int SocketCB_Connected(Handle hSocket, any hPack)
{
	Log("test.log", "SocketCB_Connected. 1");
	if(SocketIsConnected(hSocket))	// If socket is connected, should be since this is the callback that is called if it is connected
	{
		Log("test.log", "SocketCB_Connected. 2");
		char sRequestString[1000], sRequestParams[500];
		Format(sRequestParams, sizeof(sRequestParams), "togcreatewebfolder.php?serverport=%s&webpgpass=%s", g_sPort, g_sWebPgPass);
		Format(sRequestString, sizeof(sRequestString), "GET %s/%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", g_sRealPath, sRequestParams, g_sRealUrl);	// Request String
		
		Log("test.log", "SocketCB_Connected. sRequestString: %s", sRequestString);
		SocketSend(hSocket, sRequestString);		// Send the request
		Log("test.log", "SocketCB_Connected. 3");
	}
}

public int SocketCB_Recieve(Handle hSocket, char[] sData, const int iSize, any hPack) 
{
	Log("test.log", "SocketCB_Recieve. 1");
	if(hSocket != INVALID_HANDLE)
	{
		LogMessage(sData);
		Log("test.log", "Data2: %s", sData);

		if(SocketIsConnected(hSocket))	// Close the socket
		{
			SocketDisconnect(hSocket);
		}
	}
}

public int SocketCB_Disconnect(Handle hSocket, any hPack)
{
	Log("test.log", "SocketCB_Disconnect. 1");
	if(hSocket != INVALID_HANDLE)
	{
		CloseHandle(hSocket);
	}
}

public int OnSocketError(Handle hSocket, const int iErrorType, const int iErrorNum, any hPack)
{
	Log("test.log", "OnSocketError. 1");
	LogError("Unable to connect to togcreatewebfolder web page. Socket error type %i ; Error number %i.", iErrorType, iErrorNum);
	
	if(hSocket != INVALID_HANDLE)
	{
		CloseHandle(hSocket);
	}
}

void URLEncode(char[] sString, int iMaxLen, char sSafe[] = "/", bool bFormat = false)
{
	char sAlwaysSafe[256];
	Format(sAlwaysSafe, sizeof(sAlwaysSafe), "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-%s", sSafe);
	
	// Need two '%' since sp's Format parses one as a parameter to replace  http://wiki.alliedmods.net/Format_Class_Functions_%28SourceMod_Scripting%29
	if(bFormat)
	{
		ReplaceString(sString, iMaxLen, "%", "%%25");
	}
	else
	{
		ReplaceString(sString, iMaxLen, "%", "%25");
	}
	
	
	char sChar[8], sReplaceChar[8];
	for(int i = 1; i < 256; i++)
	{
		if(i==37)	// Skip the '%' double replace ftw..
		{
			continue;
		}
		
		Format(sChar, sizeof(sChar), "%c", i);
		if(StrContains(sAlwaysSafe, sChar) == -1 && StrContains(sString, sChar) != -1)
		{
			if(bFormat)
			{
				Format(sReplaceChar, sizeof(sReplaceChar), "%%%%%02X", i);
			}
			else
			{
				Format(sReplaceChar, sizeof(sReplaceChar), "%%%02X", i);
			}
			ReplaceString(sString, iMaxLen, sChar, sReplaceChar);
		}
	}
}

stock void Log(char[] sPath, const char[] sMsg, any ...)		//TOG logging function - path is relative to logs folder.
{
	char sLogFilePath[PLATFORM_MAX_PATH], sFormattedMsg[1500];
	BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/%s", sPath);
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	LogToFileEx(sLogFilePath, "%s", sFormattedMsg);
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
		
*/