#pragma semicolon 1
#pragma dynamic 32767 // Without this line will crash server!!
#include <sourcemod>
#include <curl>
#include <regex>

#define VERSION 		"0.0.1"

#define MAX_LINES 64

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))
new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,90},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled = false;

new Handle:g_hCvarDaysToKeep = INVALID_HANDLE;
new g_iDaysToKeep = 13;


new g_iDeadline;
new String:g_sFtpURL[255];
new bool:g_bDeleting = false;
new g_iCount = 0;
new Handle:g_sListCommands = INVALID_HANDLE;


public Plugin:myinfo =
{
	name 		= "tReplayCleanupCurl",
	author 		= "Thrawn",
	description = "Cleans up the replay folder on your webserver",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_treplaycleanupcurl_version", VERSION, "Cleans up the replay folder on your webserver", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_treplaycleanupcurl_enable", "1", "Automatically cleanup on mapstart", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarDaysToKeep = CreateConVar("sm_treplaycleanupcurl_daystokeep", "13", "Delete replay files older than this (in days)", FCVAR_PLUGIN, true, 2.0, true, 31.0);

	HookConVarChange(g_hCvarDaysToKeep, Cvar_Changed);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	RegAdminCmd("sm_cleanupreplays", Command_CleanupReplays, ADMFLAG_ROOT);
}

public CheckIfNeeded() {
	if(GetConVarValueInt("replay_enable") != 1) {
		SetFailState("Replay System is disabled. You don't need this plugin.");
		return;
	}

	if(GetConVarValueInt("replay_fileserver_offload_enable") != 1) {
		SetFailState("Replay Fileserver Offload is disabled. You don't need this plugin.");
		return;
	}
}

public OnConfigsExecuted() {
	CheckIfNeeded();

	g_iDaysToKeep = GetConVarInt(g_hCvarDaysToKeep);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);

	if(!g_bEnabled)return;

	// No need to configure anything, as it is already.
	new String:sLogin[64];		GetConVarValueString("replay_fileserver_offload_login", sLogin, sizeof(sLogin));
	new String:sPW[64];			GetConVarValueString("replay_fileserver_offload_password", sPW, sizeof(sPW));
	new String:sRemotePath[64];	GetConVarValueString("replay_fileserver_offload_remotepath", sRemotePath, sizeof(sRemotePath));
	new String:sHost[64];		GetConVarValueString("replay_fileserver_offload_hostname", sHost, sizeof(sHost));
	new iPort =					GetConVarValueInt("replay_fileserver_offload_port");
	Format(g_sFtpURL, sizeof(g_sFtpURL), "ftp://%s:%s@%s:%i%s/", sLogin, sPW, sHost, iPort, sRemotePath);

	if(g_bEnabled) {
		GetDirectoryListing();
	}
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iDaysToKeep = GetConVarInt(g_hCvarDaysToKeep);
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
}

public Action:Command_CleanupReplays(client,args) {
	if(g_bDeleting) {
		ReplyToCommand(client, "Already in progress");
		return Plugin_Handled;
	}

	LogMessage("Client %N started a manual replay cleanup", client);
	ReplyToCommand(client, "Cleanup of replay files started.");

	GetDirectoryListing();
	return Plugin_Handled;
}

// This is called every time we get some pieces of data from our directory listing thread
public RetrievePartialList(Handle:hndl, const String:buffer[], const bytes, const nmemb) {
	// This is not guaranteed to give data without cutting it somewhere in the middle of a filename.
	// Actually it's very likely that the first and last filename are truncated, if the list is longer
	// than ~32 files and is therefore split among several packets.
	// But we actually wouldn't care if we would be missing some 100 hundred files when deleting,
	// because we will get them the next time the cleanup process kicks in - on the next mapchange.
	// Even with > 8000 stale files,

	// We've probably got several lines of filenames
	new String:lines[MAX_LINES][80];
	new iLineCount = ExplodeString(buffer, "\n", lines, MAX_LINES, 80);

	// But we are only interested in our replay files, match them with an basic but precise (no \d*) regex.
	new Handle:hRegEx = CompileRegex("(\\d\\d\\d\\d\\d\\d\\d\\d)-(\\d\\d\\d\\d\\d\\d)-(.*)\\.(block|dmx)");
	for(new i = 0; i < iLineCount; i++) {
		if(MatchRegex(hRegEx, lines[i])) {
			// No line breaks, whitespaces pls
			TrimString(lines[i]);

			// We need the date part as integer to compare it to our deadline
			new String:sDate[16];
			GetRegexSubString(hRegEx, 1, sDate, sizeof(sDate));
			new iDate = StringToInt(sDate);

			if(iDate < g_iDeadline) {
				// Create and attach the command to the command slist.
				new String:sCMD[128];
				Format(sCMD, sizeof(sCMD), "DELE %s", lines[i]);

				curl_slist_append(g_sListCommands, sCMD);
				g_iCount++;
			}
		}
	}

	CloseHandle(hRegEx);

	return bytes*nmemb;
}

public GetDirectoryListing() {
	if(g_bDeleting)return;

	ClearHandle(g_sListCommands);
	// An curl_slist can be used to queue commands which curl can send one after the other without us
	// having to do anything.
	// We create this list now, so we can fill it on the fly with DELE <filename> commands.
	g_sListCommands = curl_slist();
	g_iCount = 0;		// And we keep track of how many files we added

	// Some could say it's ugly, some say it nice: we are using the fact that dates in
	// this format YYYYMMDD are comparable, so lets get our deadline as an int with todays
	// date minus the days configured in the cvar.
	new String:sDeadline[16];
	FormatTime(sDeadline, sizeof(sDeadline), "%Y%m%d", GetTime() - g_iDaysToKeep*24*60*60);
	g_iDeadline = StringToInt(sDeadline);

	// Get the directory list of the replay folder on the ftp
	new Handle:hCurl = curl_easy_init();
	if(hCurl != INVALID_HANDLE)	{
		CURL_DEFAULT_OPT(hCurl);

		// We only need the filenames. We are doing this for several reasons:
		//  - It's way less data to transfer
		//  - The filenames contain the date they we're created and therefore all we need
		//  - FTP servers produce different list output - parsing all kinds of ftp servers
		//    is not something we want to do.
		curl_easy_setopt_int(hCurl, CURLOPT_FTPLISTONLY, 1);

		// Provide our own function to deal with the retrieved data
		curl_easy_setopt_function(hCurl, CURLOPT_WRITEFUNCTION, RetrievePartialList);

		// Set the URL to the ftp path
		curl_easy_setopt_string(hCurl, CURLOPT_URL, g_sFtpURL);

		// Do it threaded
		curl_easy_perform_thread(hCurl, onComplete, 0);
	}
}


public onComplete(Handle:hndl, CURLcode: code, any:data) {
	// We've retrieved all data from the directory listing
	if(code != CURLE_OK) {
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogError("Failed retrieving the directory list (%s).", data, error_buffer);
	} else {
		LogMessage("Got directory list, %i files older than %i days.", g_iCount, g_iDaysToKeep);
		if(g_iCount > 0) {
			// We've found at least 1 file we want to delete
			g_bDeleting = true;

			new Handle:hCurl = curl_easy_init();
			if(hCurl != INVALID_HANDLE) {
				CURL_DEFAULT_OPT(hCurl);
				// Again, the same ftp url so we don't have to add the remotepath to the DELE commands
				curl_easy_setopt_string(hCurl, CURLOPT_URL, g_sFtpURL);

				// Queue all commands from the slist we've created while retrieving the directory list
				curl_easy_setopt_handle(hCurl, CURLOPT_POSTQUOTE, g_sListCommands);

				// Again, threaded, this could actually take quite some time if you have a lot of
				// stale files.
				curl_easy_perform_thread(hCurl, onCompleteDelete, 0);
			}
		}
	}

	CloseHandle(hndl);
}

public onCompleteDelete(Handle:hndl, CURLcode: code, any:data) {
	// We've executed all files in the command queue
	if(code != CURLE_OK) {
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogError("Failed deleting files (%s).", error_buffer);
	} else {
		LogMessage("Old replay files deleted.");
	}

	g_bDeleting = false;
	CloseHandle(hndl);
	ClearHandle(g_sListCommands);
}



// ********************
// Helpers
// ********************
public GetConVarValueString(const String:sConVar[], String:sOut[], maxlen) {
	new Handle:hConVar = FindConVar(sConVar);
	GetConVarString(hConVar, sOut, maxlen);
	CloseHandle(hConVar);
}

public GetConVarValueInt(const String:sConVar[]) {
	new Handle:hConVar = FindConVar(sConVar);
	new iResult = GetConVarInt(hConVar);
	CloseHandle(hConVar);
	return iResult;
}

public ClearHandle(&Handle:hndl) {
	if(hndl != INVALID_HANDLE) {
		CloseHandle(hndl);
		hndl = INVALID_HANDLE;
	}
}