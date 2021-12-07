#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <socket>
#include <curl>
#include <steamtools>
#include <system2>

#define PLUGIN_NAME "File Downloads"
#define PLUGIN_VERSION "1.2"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarDownloadEachMap;
new Handle:g_hCvarDownloadMethod;

// ====[ VARIABLES ]===========================================================
new bool:g_bCvarDownloadEachMap;
new g_iCvarDownloadMethod;

// ====[ PLUGIN ]==============================================================
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketSetArg");
	MarkNativeAsOptional("SocketSetOption");
	MarkNativeAsOptional("SocketConnect");
	MarkNativeAsOptional("SocketSend");
	MarkNativeAsOptional("curl_OpenFile");
	MarkNativeAsOptional("curl_slist");
	MarkNativeAsOptional("curl_slist_append");
	MarkNativeAsOptional("curl_easy_init");
	MarkNativeAsOptional("curl_easy_setopt_int_array");
	MarkNativeAsOptional("curl_easy_setopt_handle");
	MarkNativeAsOptional("curl_easy_setopt_string");
	MarkNativeAsOptional("curl_easy_perform_thread");
	MarkNativeAsOptional("curl_easy_strerror");
	MarkNativeAsOptional("Steam_CreateHTTPRequest");
	MarkNativeAsOptional("Steam_SetHTTPRequestHeaderValue");
	MarkNativeAsOptional("Steam_SendHTTPRequest");
	MarkNativeAsOptional("Steam_WriteHTTPResponseBody");
	MarkNativeAsOptional("Steam_ReleaseHTTPRequest");
	MarkNativeAsOptional("System2_DownloadFile");
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "File Downloads",
	author = "ReFlex",
	description = "Download files from the internet",
	version = PLUGIN_VERSION,
	url = "http://www.intoxgaming.com/"
}

// ====[ EVENTS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_filedownloads_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD);

	g_hCvarDownloadEachMap = CreateConVar("sm_filedownloads_eachmap", "1", "Force files to redownload whenever the map changes?\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarDownloadEachMap = GetConVarBool(g_hCvarDownloadEachMap);
	HookConVarChange(g_hCvarDownloadEachMap, OnConVarChange);

	g_hCvarDownloadMethod = CreateConVar("sm_filedownloads_method", "1", "What extension handles downloads?\n0 = None\n1 = Socket\n2 = cURL\n3 = SteamTools\n4 = System2", FCVAR_NONE, true, 0.0, true, 5.0);
	g_iCvarDownloadMethod = GetConVarInt(g_hCvarDownloadMethod);
	HookConVarChange(g_hCvarDownloadMethod, OnConVarChange);

	RegAdminCmd("sm_filedownloads_files", Command_DownloadFiles, ADMFLAG_ROOT, "Redownload all files from filedownloads.cfg");
}

public OnConVarChange(Handle:hConVar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConVar == g_hCvarDownloadEachMap)
		g_bCvarDownloadEachMap = GetConVarBool(g_hCvarDownloadEachMap);
	else if(hConVar == g_hCvarDownloadMethod)
		g_iCvarDownloadMethod = GetConVarInt(g_hCvarDownloadMethod);
}

public OnConfigsExecuted()
{
	if(g_bCvarDownloadEachMap)
		DownloadFiles();
}

public DownloadFiles()
{
	decl String:strConfig[255];
	BuildPath(Path_SM, strConfig, sizeof(strConfig), "configs/filedownloads.cfg");
	if(FileExists(strConfig, true))
	{
		new Handle:hKeyValues = CreateKeyValues("File Downloads");
		if(FileToKeyValues(hKeyValues, strConfig))
		{
			do
			{
				if(KvGotoFirstSubKey(hKeyValues, false))
				{
					decl String:strFileUrl[255];
					decl String:strFile[255];
					decl String:strFilePath[255];

					do
					{
						KvGetString(hKeyValues, "url", strFileUrl, sizeof(strFileUrl));
						KvGetString(hKeyValues, "path", strFile, sizeof(strFile));
						BuildPath(Path_SM, strFilePath, sizeof(strFilePath), strFile);

						switch(g_iCvarDownloadMethod)
						{
							case 1: Download_Socket(strFileUrl, strFilePath);
							case 2: Download_cURL(strFileUrl, strFilePath);
							case 3: Download_SteamTools(strFileUrl, strFilePath);
							case 4: Download_System2(strFileUrl, strFilePath);
						}

						PrintToServer("[SM] Downloading (%s) from (%s)...", strFilePath, strFileUrl);
					}
					while(KvGotoNextKey(hKeyValues, false));
					KvGoBack(hKeyValues);
				}
			}
			while(KvGotoNextKey(hKeyValues, false));
		}
		CloseHandle(hKeyValues);
	}
}

// ====[ COMMANDS ]============================================================
public Action:Command_DownloadFiles(iClient, iArgs)
{
	ReplyToCommand(iClient, "[SM] Downloading files...");
	DownloadFiles();
}

public Download_Socket(const String:strURL[], const String:strPath[])
{
	new Handle:hFile = OpenFile(strPath, "wb");
	if(hFile != INVALID_HANDLE)
	{
		decl String:strHost[64];
		decl String:strLocation[128];
		decl String:strFile[64];
		decl String:strRequest[512];
		ParseURL(strURL, strHost, sizeof(strHost), strLocation, sizeof(strLocation), strFile, sizeof(strFile));
		FormatEx(strRequest, sizeof(strRequest), "GET %s/%s HTTP/1.0\r\nHost: %s\r\nUser-agent: plugin\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", strLocation, strFile, strHost);

		new Handle:hDLPack = CreateDataPack();
		WritePackCell(hDLPack, 0);
		WritePackCell(hDLPack, _:hFile);
		WritePackString(hDLPack, strRequest);

		new Handle:hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketSetArg(hSocket, hDLPack);
		SocketSetOption(hSocket, ConcatenateCallbacks, 4096);
		SocketConnect(hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, strHost, 80);
	}
}

public OnSocketConnected(Handle:hSocket, any:hDLPack)
{
	decl String:strRequest[512];
	SetPackPosition(hDLPack, 16);
	ReadPackString(hDLPack, strRequest, sizeof(strRequest));
	SocketSend(hSocket, strRequest);
}

public OnSocketReceive(Handle:socket, String:strData[], const iSize, any:hDLPack)
{
	new iIndex;
	SetPackPosition(hDLPack, 0);
	new bool:bParsedHeader = bool:ReadPackCell(hDLPack);
	if(!bParsedHeader)
	{
		if((iIndex = StrContains(strData, "\r\n\r\n")) == -1)
			iIndex = 0;
		else
			iIndex += 4;

		SetPackPosition(hDLPack, 0);
		WritePackCell(hDLPack, 1);
	}

	SetPackPosition(hDLPack, 8);
	new Handle:hFile = Handle:ReadPackCell(hDLPack);
	while(iIndex < iSize)
		WriteFileCell(hFile, strData[iIndex++], 1);
}

public OnSocketDisconnected(Handle:hSocket, any:hDLPack)
{
	SetPackPosition(hDLPack, 8);
	CloseHandle(Handle:ReadPackCell(hDLPack));
	CloseHandle(hDLPack);
	CloseHandle(hSocket);
}

public OnSocketError(Handle:hSocket, const iErrorType, const iErrorNum, any:hDLPack)
{
	SetPackPosition(hDLPack, 8);
	CloseHandle(Handle:ReadPackCell(hDLPack));
	CloseHandle(hDLPack);
	CloseHandle(hSocket);
	LogError("Socket: %d (Error code %d)", iErrorType, iErrorNum);
}

public Download_cURL(const String:strUrl[], const String:strFile[])
{
	decl String:strHTTP[256];
	PrefixURL(strHTTP, sizeof(strHTTP), strUrl);

	new Handle:hFile = curl_OpenFile(strFile, "wb");
	if(hFile != INVALID_HANDLE)
	{
		new CURL_Default_opt[][2] =
		{
			{_:CURLOPT_NOSIGNAL, 1},
			{_:CURLOPT_NOPROGRESS, 1},
			{_:CURLOPT_TIMEOUT, 30},
			{_:CURLOPT_CONNECTTIMEOUT, 60},
			{_:CURLOPT_VERBOSE, 0}
		};

		new Handle:hHeaders = curl_slist();
		curl_slist_append(hHeaders, "User-agent: plugin");
		curl_slist_append(hHeaders, "Pragma: no-cache");
		curl_slist_append(hHeaders, "Cache-Control: no-cache");

		new Handle:hDLPack = CreateDataPack();
		WritePackCell(hDLPack, _:hFile);
		WritePackCell(hDLPack, _:hHeaders);

		new Handle:hCurl = curl_easy_init();
		curl_easy_setopt_int_array(hCurl, CURL_Default_opt, sizeof(CURL_Default_opt));
		curl_easy_setopt_handle(hCurl, CURLOPT_WRITEDATA, hFile);
		curl_easy_setopt_string(hCurl, CURLOPT_URL, strHTTP);
		curl_easy_setopt_handle(hCurl, CURLOPT_HTTPHEADER, hHeaders);
		curl_easy_perform_thread(hCurl, OnCurlComplete, hDLPack);
	}
}

public OnCurlComplete(Handle:hCurl, CURLcode:code, any:hDLPack)
{
	ResetPack(hDLPack);
	CloseHandle(Handle:ReadPackCell(hDLPack));
	CloseHandle(Handle:ReadPackCell(hDLPack));
	CloseHandle(hDLPack);
	CloseHandle(hCurl);

	if(code != CURLE_OK)
	{
		decl String:strError[PLATFORM_MAX_PATH];
		curl_easy_strerror(code, strError, sizeof(strError));
		LogError("cURL: %s", strError);
	}
}

public Download_SteamTools(const String:strURL[], const String:strFile[])
{
	new Handle:hFile = OpenFile(strFile, "wb");
	if(hFile != INVALID_HANDLE)
	{
		decl String:strHTTP[256];
		PrefixURL(strHTTP, sizeof(strHTTP), strURL);

		new Handle:hDLPack = CreateDataPack();
		WritePackString(hDLPack, strFile);

		new HTTPRequestHandle:hRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, strHTTP);
		Steam_SetHTTPRequestHeaderValue(hRequest, "User-agent", "plugin");
		Steam_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
		Steam_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");
		Steam_SendHTTPRequest(hRequest, OnSteamHTTPComplete, hDLPack);
	}
}

public OnSteamHTTPComplete(HTTPRequestHandle:HTTPRequest, bool:bRequestSuccessful, HTTPStatusCode:statusCode, any:hDLPack)
{
	decl String:strFile[PLATFORM_MAX_PATH];
	ResetPack(hDLPack);
	ReadPackString(hDLPack, strFile, sizeof(strFile));
	CloseHandle(hDLPack);

	if(bRequestSuccessful && statusCode == HTTPStatusCode_OK)
		Steam_WriteHTTPResponseBody(HTTPRequest, strFile);
	else
		LogError("SteamTools: error (status code %i). Request successful: %s", _:statusCode, bRequestSuccessful ? "Yes" : "No");

	Steam_ReleaseHTTPRequest(HTTPRequest);
}

public Download_System2(const String:strURL[], const String:strPath[])
{
	System2_DownloadFile(OnDownloadStep, strURL, strPath);
}

public OnDownloadStep(bool:bFinished, const String:strError[], Float:dltotal, Float:dlnow, Float:ultotal, Float:ulnow)
{
	if(strError[0])
		LogError("System2: %s", strError);
}

// ====[ STOCKS ]==============================================================
stock ParseURL(const String:strURL[], String:strHost[], iMaxHost, String:strLocation[], iMaxLoc, String:strFile[], iMaxName)
{
	new iIndex = StrContains(strURL, "://");
	iIndex = (iIndex != -1) ? iIndex + 3 : 0;

	decl String:strDirs[16][64];
	new iTotal = ExplodeString(strURL[iIndex], "/", strDirs, sizeof(strDirs), sizeof(strDirs[]));

	FormatEx(strHost, iMaxHost, "%s", strDirs[0]);

	strLocation[0] = '\0';
	for(new i = 1; i < iTotal - 1; i++)
		FormatEx(strLocation, iMaxLoc, "%s/%s", strLocation, strDirs[i]);

	FormatEx(strFile, iMaxName, "%s", strDirs[iTotal - 1]);
}

stock PrefixURL(String:buffer[], maxlength, const String:strURL[])
{
	if(strncmp(strURL, "http://", 7) != 0)
		FormatEx(buffer, maxlength, "http://%s", strURL);
	else
		strcopy(buffer, maxlength, strURL);
}