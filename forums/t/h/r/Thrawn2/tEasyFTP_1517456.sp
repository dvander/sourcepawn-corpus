#pragma semicolon 1
#pragma dynamic 32767 // Without this line will crash server!!
#include <sourcemod>
#include <curl>

#define VERSION 		"0.0.2"

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))
new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,90},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};

new Handle:g_hUploadForward = INVALID_HANDLE;

new Handle:g_hKv_FtpTargets = INVALID_HANDLE;
new Handle:g_hTrie_Data = INVALID_HANDLE;

new Handle:g_hFile = INVALID_HANDLE;

new bool:g_bUploading = false;

public Plugin:myinfo =
{
	name 		= "tEasyFTP",
	author 		= "Thrawn",
	description = "Provides natives for easy FTP access",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_teasyftp_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hUploadForward = CreateForward(ET_Event, Param_String, Param_String, Param_String, Param_Cell, Param_Cell);

	ReloadFtpTargetKV();
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
	public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("teftp");

	CreateNative("EasyFTP_UploadFile", NativeUploadFile);

	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
		return true;
	#endif
}

public NativeUploadFile(Handle:hPlugin, iNumParams) {
	decl String:sTarget[128];
	GetNativeString(1, sTarget, sizeof(sTarget));

	decl String:sLocalFile[128];
	GetNativeString(2, sLocalFile, sizeof(sLocalFile));

	decl String:sRemoteFile[128];
	GetNativeString(3, sRemoteFile, sizeof(sRemoteFile));

	new Function:myFunc = GetNativeCell(4);

	new anyData = GetNativeCell(5);

	new Handle:hArray_Queue = INVALID_HANDLE;
	if(GetTrieValue(g_hTrie_Data, sTarget, hArray_Queue)) {
		new Handle:hTrie_UploadEntry = CreateTrie();
		SetTrieString(hTrie_UploadEntry, "local", sLocalFile);
		SetTrieString(hTrie_UploadEntry, "remote", sRemoteFile);
		SetTrieString(hTrie_UploadEntry, "target", sTarget);
		SetTrieValue(hTrie_UploadEntry, "plugin", hPlugin);
		SetTrieValue(hTrie_UploadEntry, "func", myFunc);
		SetTrieValue(hTrie_UploadEntry, "data", anyData);

		PushArrayCell(hArray_Queue, hTrie_UploadEntry);
	} else {
		LogError("Target %s does not exist", sTarget);
	}

	if(!g_bUploading)ProcessQueue();
}

public ReloadFtpTargetKV() {
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/RemoteTargets.cfg");

	if(!FileExists(sPath)) {
		LogError("RemoteTargets.cfg does not exist");
		return;
	}

	// Clear Queue-Array(Trie) for every target
	if(g_hKv_FtpTargets != INVALID_HANDLE && KvGotoFirstSubKey(g_hKv_FtpTargets, false)) {
		do {
			new String:sTarget[64];
			KvGetSectionName(g_hKv_FtpTargets, sTarget, sizeof(sTarget));

			new Handle:hArray_Queue = INVALID_HANDLE;
			GetTrieValue(g_hTrie_Data, sTarget, hArray_Queue);

			while(GetArraySize(hArray_Queue) > 0) {
				new Handle:hTrie_UploadEntry = GetArrayCell(hArray_Queue, 0);
				RemoveFromArray(hArray_Queue, 0);
				CloseHandle(hTrie_UploadEntry);
			}

			ClearHandle(hArray_Queue);
		} while (KvGotoNextKey(g_hKv_FtpTargets, false));
	}

	// Reinitialize Queue.
	ClearHandle(g_hTrie_Data);
	g_hTrie_Data = CreateTrie();

	// Reload KV-File to Handle
	ClearHandle(g_hKv_FtpTargets);
	g_hKv_FtpTargets = CreateKeyValues("RockNRoll");
	FileToKeyValues(g_hKv_FtpTargets, sPath);

	// Rebuild Queue-Array(Trie) for every target
	if(KvGotoFirstSubKey(g_hKv_FtpTargets, false)) {
		do {
			new String:sTarget[64];
			KvGetSectionName(g_hKv_FtpTargets, sTarget, sizeof(sTarget));

			new Handle:hArray_Queue = CreateArray(4);
			SetTrieValue(g_hTrie_Data, sTarget, hArray_Queue);
		} while (KvGotoNextKey(g_hKv_FtpTargets, false));
	}
}

public ProcessQueue() {
	g_bUploading = true;
	KvRewind(g_hKv_FtpTargets);
	if(KvGotoFirstSubKey(g_hKv_FtpTargets, false)) {
		do {
			new String:sTarget[64];
			KvGetSectionName(g_hKv_FtpTargets, sTarget, sizeof(sTarget));

			new Handle:hArray_Queue = INVALID_HANDLE;
			GetTrieValue(g_hTrie_Data, sTarget, hArray_Queue);

			if(GetArraySize(hArray_Queue) > 0) {
				new Handle:hTrie_UploadEntry = GetArrayCell(hArray_Queue, 0);
				RemoveFromArray(hArray_Queue, 0);

				decl String:sLocalFile[PLATFORM_MAX_PATH];
				GetTrieString(hTrie_UploadEntry, "local", sLocalFile, sizeof(sLocalFile));

				if(!FileExists(sLocalFile)) {
					LogError("Upload failed. File does not exists: %s", sLocalFile);
					continue;
				}

				decl String:sLocalFileBasename[PLATFORM_MAX_PATH];
				getFileBasename(sLocalFile, sLocalFileBasename, sizeof(sLocalFileBasename));

				decl String:sRemoteFile[PLATFORM_MAX_PATH];
				GetTrieString(hTrie_UploadEntry, "remote", sRemoteFile, sizeof(sRemoteFile));

				// Prepend missing slash
				if(strncmp(sRemoteFile, "/", 1) != 0) {
					Format(sRemoteFile, sizeof(sRemoteFile), "/%s", sRemoteFile);
				}

				// Prepend missing filename
				if(strncmp(sRemoteFile[strlen(sRemoteFile)-1], "/", 1) == 0) {
					Format(sRemoteFile, sizeof(sRemoteFile), "%s%s", sRemoteFile, sLocalFileBasename);
				}

				// Get the server info from the ftp-targets config file
				decl String:sHost[128];
				KvGetString(g_hKv_FtpTargets, "host", sHost, sizeof(sHost));

				decl String:sUser[32];
				KvGetString(g_hKv_FtpTargets, "user", sUser, sizeof(sUser));

				decl String:sPassword[32];
				KvGetString(g_hKv_FtpTargets, "password", sPassword, sizeof(sPassword));

				decl String:sForcePath[128];
				KvGetString(g_hKv_FtpTargets, "path", sForcePath, sizeof(sForcePath), "");

				decl String:sSSLMode[128];
				KvGetString(g_hKv_FtpTargets, "ssl", sSSLMode, sizeof(sSSLMode), "none");
				new curl_usessl:iSSLMode = SSLModeStringToEnum(sSSLMode);

				new bool:bCreateMissingDirs = bool:KvGetNum(g_hKv_FtpTargets, "CreateMissingDirs", 0);

				// Prepend missing slash
				if(strncmp(sForcePath, "/", 1) != 0) {
					Format(sForcePath, sizeof(sForcePath), "/%s", sForcePath);
				}

				// Remove trailing slash (it's added in remotefile if necessary)
				if(strncmp(sForcePath[strlen(sForcePath)-1], "/", 1) == 0) {
					sForcePath[strlen(sForcePath)-1] = 0;
				}

				new iPort = KvGetNum(g_hKv_FtpTargets, "port", 21);

				decl String:sFtpURL[512];
				Format(sFtpURL, sizeof(sFtpURL), "ftp://%s:%s@%s:%i%s%s", sUser, sPassword, sHost, iPort, sForcePath, sRemoteFile);

				LogMessage("Uploading file %s (%i byte) to target %s", sLocalFileBasename, FileSize(sLocalFile), sTarget);
				new Handle:hCurl = curl_easy_init();
				if(hCurl == INVALID_HANDLE)
					return;

				CURL_DEFAULT_OPT(hCurl);
				g_hFile = OpenFile(sLocalFile, "rb");

				// Tell curl we want to upload something
				curl_easy_setopt_int(hCurl, CURLOPT_UPLOAD, 1);
				curl_easy_setopt_function(hCurl, CURLOPT_READFUNCTION, ReadFunction);

				if(bCreateMissingDirs) {
					curl_easy_setopt_int(hCurl, CURLOPT_FTP_CREATE_MISSING_DIRS, CURLFTP_CREATE_DIR);
				}

				if(iSSLMode != CURLUSESSL_NONE) {
					curl_easy_setopt_int(hCurl, CURLOPT_USE_SSL, iSSLMode);
				}

				// Set the URL to the ftp path
				curl_easy_setopt_string(hCurl, CURLOPT_URL, sFtpURL);

				// Do it threaded
				curl_easy_perform_thread(hCurl, onComplete, hTrie_UploadEntry);

				return;
			}
		} while (KvGotoNextKey(g_hKv_FtpTargets, false));
	}
	g_bUploading = false;
}

public curl_usessl:SSLModeStringToEnum(const String:sSSLMode[]) {
	if(StrEqual(sSSLMode, "none", false))return CURLUSESSL_NONE;
	if(StrEqual(sSSLMode, "try", false))return CURLUSESSL_TRY;
	if(StrEqual(sSSLMode, "control", false))return CURLUSESSL_CONTROL;
	if(StrEqual(sSSLMode, "all", false))return CURLUSESSL_ALL;
	return CURLUSESSL_NONE;
}

public ReadFunction(Handle:hCurl, const bytes, const nmemb)
{
	// We are told to read 0 bytes... return 0.
	if((bytes*nmemb) < 1)
		return 0;

	// We've already read everything... return 0.
	if(IsEndOfFile(g_hFile))
		return 0;

	new iBytesToRead = bytes * nmemb;

	// This is slow as hell, but ReadFile always read 4 byte blocks, even though
	// it was told explicitely to read 'bytes' * 'nmemb' bytes.
	// XXX: Revisit this and try to do it right...
	new String:items[iBytesToRead];
	new iPos = 0;
	new iCell = 0;
	for(; iPos < iBytesToRead && ReadFileCell(g_hFile, iCell, 1) == 1; iPos++) {
		items[iPos] = iCell;
	}

	curl_set_send_buffer(hCurl, items, iPos);

	return iPos;
}

public onComplete(Handle:hndl, CURLcode: code, any:hTrie_UploadEntry) {
	ClearHandle(g_hFile);

	decl String:sLocalFile[PLATFORM_MAX_PATH];
	GetTrieString(hTrie_UploadEntry, "local", sLocalFile, sizeof(sLocalFile));

	decl String:sRemoteFile[PLATFORM_MAX_PATH];
	GetTrieString(hTrie_UploadEntry, "remote", sRemoteFile, sizeof(sRemoteFile));

	decl String:sTarget[128];
	GetTrieString(hTrie_UploadEntry, "target", sTarget, sizeof(sTarget));

	new Handle:hPlugin;
	GetTrieValue(hTrie_UploadEntry, "plugin", hPlugin);

	new anyData;
	GetTrieValue(hTrie_UploadEntry, "data", anyData);

	new Function:hFunc;
	GetTrieValue(hTrie_UploadEntry, "func", hFunc);

	AddToForward(g_hUploadForward, hPlugin, hFunc);

	/* Start function call */
	Call_StartForward(g_hUploadForward);

	/* Push parameters one at a time */
	Call_PushString(sTarget);
	Call_PushString(sLocalFile);
	Call_PushString(sRemoteFile);
	Call_PushCell(code);
	Call_PushCell(anyData);

	/* Finish the call, get the result */
	new iResult;
	Call_Finish(_:iResult);

	RemoveFromForward(g_hUploadForward, hPlugin, hFunc);

	if(code != CURLE_OK) {
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogError("Failed uploading %s (%s).", sLocalFile, error_buffer);
	} else {
		LogMessage("Finished uploading %s to %s", sLocalFile, sTarget);
	}

	CloseHandle(hTrie_UploadEntry);
	CloseHandle(hndl);

	g_bUploading = false;
	ProcessQueue();
}


public ClearHandle(&Handle:hndl) {
	if(hndl != INVALID_HANDLE) {
		CloseHandle(hndl);
		hndl = INVALID_HANDLE;
	}
}

public getFileBasename(const String:sFilename[], String:sOutput[], maxlength) {
	new iPos = FindCharInString(sFilename, '/', true);

	if(iPos != -1) {
		strcopy(sOutput, maxlength, sFilename[iPos+1]);
	} else {
		strcopy(sOutput, maxlength, sFilename);
	}
}