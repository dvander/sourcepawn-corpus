#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <socket>
#include <steamtools>
#include <curl>


#define VERSION 		"0.0.2"

enum HttpLibs {
	lib_socket,
	lib_steamtools,
	lib_curl,
	none
}

new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,30},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_USE_SSL,CURLUSESSL_TRY},
	{_:CURLOPT_SSL_VERIFYPEER,0},
	{_:CURLOPT_SSL_VERIFYHOST,0},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))


new HttpLibs:g_iMode = none;


public Plugin:myinfo = {
	name 		= "tDownloadCache",
	author 		= "Thrawn",
	description = "Abstraction layer for http downloads",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tdownloadcache_version", VERSION, "Abstraction layer for http downloads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_iMode = GetBestAvailableDownloadlib();
}

public OnLibraryAdded() {
	g_iMode = GetBestAvailableDownloadlib();
}

public OnLibraryRemoved() {
	g_iMode = GetBestAvailableDownloadlib();
}

public HttpLibs:GetBestAvailableDownloadlib() {
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "curl_easy_init") == FeatureStatus_Available) {
		LogMessage("Using Curl");
		return lib_curl;
	}

	if(LibraryExists("SteamTools")) {
		LogMessage("Using SteamTools");
		return lib_steamtools;
	}

	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "SocketCreate") == FeatureStatus_Available) {
		LogMessage("Using Socket");
		return lib_socket;
	}

	SetFailState("No library available to handle downloads.");
	return none;
}



public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	RegPluginLibrary("tdownloadcache");

	CreateNative("DC_UpdateFile", Native_UpdateFile);

	return APLRes_Success;
}



public FinishDownload(Handle:hSocketData, bool:bSuccess) {
	new Handle:hPlugin;
	GetTrieValue(hSocketData, "plugin", hPlugin);

	new Function:hFunction;
	if(GetTrieValue(hSocketData, "function", hFunction) && IsValidPlugin(hPlugin)) {
		new data;
		GetTrieValue(hSocketData, "data", data);

		Call_StartFunction(hPlugin, hFunction);
		Call_PushCell(bSuccess);
		Call_PushCell(hSocketData);
		Call_PushCell(data);
		Call_Finish();
	}
}

public Native_UpdateFile(Handle:hPlugin, iNumParams) {
	new String:sPath[PLATFORM_MAX_PATH];
	GetNativeString(1, sPath, sizeof(sPath));

	new String:sHost[255];
	GetNativeString(2, sHost, sizeof(sHost));

	new iPort = GetNativeCell(3);

	new String:sUrl[512];
	GetNativeString(4, sUrl, sizeof(sUrl));

	new iMaxAge = GetNativeCell(5);

	new Function:funcCallback = GetNativeCell(6);

	new data = GetNativeCell(7);

	new String:sProtocol[8];
	GetNativeString(8, sProtocol, sizeof(sProtocol));

	new bool:bForceCurl = false;
	if(!StrEqual(sProtocol, "http")) {
		bForceCurl = true;
	}


	new String:sFullUrl[512];
	if(iPort != 80) {
		Format(sFullUrl, sizeof(sFullUrl), "%s://%s:%i%s", sProtocol, sHost, iPort, sUrl);
	} else {
		Format(sFullUrl, sizeof(sFullUrl), "%s://%s%s", sProtocol, sHost, sUrl);
	}

	new Handle:hSocketData = CreateTrie();

	SetTrieString(hSocketData, "path", sPath);
	SetTrieString(hSocketData, "url", sUrl);
	SetTrieString(hSocketData, "furl", sFullUrl);
	SetTrieString(hSocketData, "host", sHost);
	SetTrieValue(hSocketData, "port", iPort);

	// If the file already exists and is young enough, reply instantly
	if(iMaxAge != 0 && FileExists(sPath)) {
		new iFileTime = GetFileTime(sPath, FileTime_LastChange);
		new iNow = GetTime();

		if(iNow - iFileTime < iMaxAge) {
			Call_StartFunction(hPlugin, funcCallback);
			Call_PushCell(true);
			Call_PushCell(hSocketData);
			Call_PushCell(data);
			Call_Finish();

			CloseHandle(hSocketData);
			return true;
		}
	}

	// We need more information later, e.g. to call the callback :)
	SetTrieValue(hSocketData, "plugin", hPlugin);
	SetTrieValue(hSocketData, "function", funcCallback);
	SetTrieValue(hSocketData, "data", data);

	switch(g_iMode) {
		case lib_socket: {
			if(bForceCurl) {
				LogError("The socket extension can only handle http requests");
				FinishDownload(hSocketData, false);
				return false;
			}

			new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
			SocketSetArg(socket, hSocketData);

			SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, sHost, iPort);
		}

		case lib_steamtools: {
			if(bForceCurl) {
				LogError("The steamtools extension can only handle http requests");
				FinishDownload(hSocketData, false);
				return false;
			}

			new HTTPRequestHandle:hRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, sFullUrl);
			Steam_SendHTTPRequest(hRequest, OnSteamToolsComplete, hSocketData);
		}

		case lib_curl: {
			new Handle:hCurl = curl_easy_init();
			if(hCurl != INVALID_HANDLE) {
				new Handle:hCurlFile = curl_OpenFile(sPath, "w");
				SetTrieValue(hSocketData, "curlfile", hCurlFile);
				CURL_DEFAULT_OPT(hCurl);
				curl_easy_setopt_handle(hCurl, CURLOPT_WRITEDATA, hCurlFile);
				curl_easy_setopt_string(hCurl, CURLOPT_URL, sFullUrl);
				curl_easy_perform_thread(hCurl, OnCurlComplete, hSocketData);
			}
		}

	}

	return false;
}

/*
 * ------------------------------------------
 * SteamTools
 * ------------------------------------------
 */
public OnSteamToolsComplete(HTTPRequestHandle:hHTTPRequest, bool:bRequestSuccessful, HTTPStatusCode:statusCode, any:hSocketData) {
	if(bRequestSuccessful) {
		new String:sPath[PLATFORM_MAX_PATH];
		GetTrieString(hSocketData, "path", sPath, sizeof(sPath));

		Steam_WriteHTTPResponseBody(hHTTPRequest, sPath);

		FinishDownload(hSocketData, true);
	} else {
		FinishDownload(hSocketData, false);
	}

	Steam_ReleaseHTTPRequest(hHTTPRequest);
	CloseHandle(hSocketData);
}


/*
 * ------------------------------------------
 * Curl
 * ------------------------------------------
 */
public OnCurlComplete(Handle:hndl, CURLcode: code, any:hSocketData) {
	if(hndl != INVALID_HANDLE) {
		CloseHandle(hndl);
	}

	new Handle:hCurlFile = INVALID_HANDLE;
	GetTrieValue(hSocketData, "curlfile", hCurlFile);
	if(hCurlFile != INVALID_HANDLE) {
		CloseHandle(hCurlFile);
	}

	RemoveFromTrie(hSocketData, "curlfile");

	if(code != CURLE_OK) {
		FinishDownload(hSocketData, false);
	} else {
		FinishDownload(hSocketData, true);
	}

	CloseHandle(hSocketData);
}

/*
 * ------------------------------------------
 * Socket
 * ------------------------------------------
 */
public OnSocketError(Handle:socket, const errorType, const errorNum, any:hSocketData) {
	LogError("socket error %d (errno %d)", errorType, errorNum);

	new Handle:hFile = INVALID_HANDLE;
	if(!GetTrieValue(hSocketData, "hFile", hFile)) {
		CloseHandle(hFile);
	}

	FinishDownload(hSocketData, false);

	CloseHandle(hSocketData);
	CloseHandle(socket);
}


public OnSocketConnected(Handle:socket, any:hSocketData) {
	// socket is connected, send the http request

	decl String:sUrl[1024];
	GetTrieString(hSocketData, "url", sUrl, sizeof(sUrl));

	decl String:sHost[1024];
	GetTrieString(hSocketData, "host", sHost, sizeof(sHost));

	decl String:sRequest[1024];
	Format(sRequest, sizeof(sRequest), "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", sUrl, sHost);
	SocketSend(socket, sRequest);
}

public OnSocketReceive(Handle:socket, String:receiving[], const dataSize, any:hSocketData) {
	new bool:bPastHeader = false;
	GetTrieValue(hSocketData, "bPastHeader", bPastHeader);

	new Handle:hFile = INVALID_HANDLE;
	if(!GetTrieValue(hSocketData, "hFile", hFile)) {
		new String:sPath[PLATFORM_MAX_PATH];
		GetTrieString(hSocketData, "path", sPath, sizeof(sPath));

		hFile = OpenFile(sPath, "wb");
		SetTrieValue(hSocketData, "hFile", hFile);
	}

	if(!bPastHeader) {
		new String:sHeader[4096];
		new iStartPos = SplitString(receiving, "\r\n\r\n", sHeader, sizeof(sHeader));

		if(iStartPos != -1) {
			WriteFileString(hFile, receiving[iStartPos], false);
			SetTrieValue(hSocketData, "bPastHeader", true);
		}
	} else {
		WriteFileString(hFile, receiving, false);
	}
}

public OnSocketDisconnected(Handle:socket, any:hSocketData) {
	new Handle:hFile = INVALID_HANDLE;
	if(GetTrieValue(hSocketData, "hFile", hFile)) {
		RemoveFromTrie(hSocketData, "hFile");
		RemoveFromTrie(hSocketData, "bPastHeader");
		CloseHandle(hFile);
	}

	FinishDownload(hSocketData, true);

	CloseHandle(hSocketData);
	CloseHandle(socket);
}








// IsValidHandle() is deprecated, let's do a real check then...
stock bool:IsValidPlugin(Handle:hPlugin) {
	if(hPlugin == INVALID_HANDLE)return false;

	new Handle:hIterator = GetPluginIterator();

	new bool:bPluginExists = false;
	while(MorePlugins(hIterator)) {
		new Handle:hLoadedPlugin = ReadPlugin(hIterator);
		if(hLoadedPlugin == hPlugin) {
			bPluginExists = true;
			break;
		}
	}

	CloseHandle(hIterator);

	return bPluginExists;
}









/*
These are here to allow optional loading of the extensions.
*/
public __ext_smsock_SetNTVOptional()
{
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketConnect");
	MarkNativeAsOptional("SocketSetArg");
	MarkNativeAsOptional("SocketSend");
}

public __ext_curl_SetNTVOptional()
{
	MarkNativeAsOptional("curl_easy_init");
	MarkNativeAsOptional("curl_OpenFile");
	MarkNativeAsOptional("curl_easy_setopt_int_array");
	MarkNativeAsOptional("curl_easy_setopt_handle");
	MarkNativeAsOptional("curl_easy_setopt_string");
	MarkNativeAsOptional("curl_easy_perform_thread");
}

public __ext_SteamTools_SetNTVOptional()
{
	MarkNativeAsOptional("Steam_CreateHTTPRequest");
	MarkNativeAsOptional("Steam_SetHTTPRequestNetworkActivityTimeout");
	MarkNativeAsOptional("Steam_SetHTTPRequestHeaderValue");
	MarkNativeAsOptional("Steam_SetHTTPRequestGetOrPostParameter");
	MarkNativeAsOptional("Steam_SendHTTPRequest");
	MarkNativeAsOptional("Steam_DeferHTTPRequest");
	MarkNativeAsOptional("Steam_PrioritizeHTTPRequest");
	MarkNativeAsOptional("Steam_GetHTTPResponseHeaderSize");
	MarkNativeAsOptional("Steam_GetHTTPResponseHeaderValue");
	MarkNativeAsOptional("Steam_GetHTTPResponseBodySize");
	MarkNativeAsOptional("Steam_GetHTTPResponseBodyData");
	MarkNativeAsOptional("Steam_WriteHTTPResponseBody");
	MarkNativeAsOptional("Steam_ReleaseHTTPRequest");
	MarkNativeAsOptional("Steam_GetHTTPDownloadProgressPercent");
}