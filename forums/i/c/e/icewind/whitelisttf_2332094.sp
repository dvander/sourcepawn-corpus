#pragma semicolon 1
#include <sourcemod>
#include <smjansson>
#include <morecolors>
#include <cURL>
#include <tf2>

public Plugin:myinfo =
{
	name = "whitelist.tf downloader",
	author = "Icewind",
	description = "Download whitelists from whitelist.tf",
	version = "0.1",
	url = "https://whitelist.tf"
};

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

new Handle:g_hCvarUrl = INVALID_HANDLE;
new Handle:output_file = INVALID_HANDLE;

new String:lastId[128] = "";
new bool:execLast = true;

public OnPluginStart()
{
	g_hCvarUrl = CreateConVar("sm_whitelist_tf_base", "http://whitelist.tf/download", "whitelist.tf download endpoint", FCVAR_PROTECTED);

	RegConsoleCmd("sm_whitelist_id", DownloadWhiteListAction, "Download and execute a whitelist");
}

public Action:DownloadWhiteListAction(client, args)
{
	new String:arg[128];
	
	if(args != 1) {
		PrintToServer("Usage: sm_whitelist_tf %whitelistid%");
	}
	
	GetCmdArg(1, arg, sizeof(arg));
 
	new intId = StringToInt(arg);
	if(intId > 0) {
		Format(arg, sizeof(arg), "custom_whitelist_%s", arg);
	}
	PrintToChatAll("Loading whitelist %s", arg);
	DownloadWhiteList(arg, true);
	return Plugin_Handled;
}

public DownloadWhiteList(String:whiteListId[128], bool:exec)
{
	execLast = exec;
	lastId = whiteListId;
	decl String:fullUrl[512];
	decl String:targetPath[128];
	decl String:BaseUrl[128];
	GetConVarString(g_hCvarUrl, BaseUrl, sizeof(BaseUrl));
	new Handle:curl = curl_easy_init();
	CURL_DEFAULT_OPT(curl);

	Format(fullUrl, sizeof(fullUrl), "%s/%s.txt", BaseUrl, whiteListId);
	
	Format(targetPath, sizeof(targetPath), "cfg/%s.txt", whiteListId);

	output_file = curl_OpenFile(targetPath, "w");
	curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, output_file);
	curl_easy_setopt_string(curl, CURLOPT_URL, fullUrl);
	curl_easy_perform_thread(curl, onComplete);
}

public onComplete(Handle:hndl, CURLcode:code)
{
	CloseHandle(hndl);
	if(code != CURLE_OK)
	{
		PrintToChatAll("Error downloading whitelist %s", lastId);
		PrintToChatAll("cURLCode error: %d", code);
	}
	else
	{
		decl String:targetPath[128];
		Format(targetPath, sizeof(targetPath), "cfg/%s.txt", lastId);
		if(execLast) {
			execWhiteList(targetPath);
		}
	}
	return;
}

public execWhiteList(String:whitelist[128])
{
	decl String:command[512];
	PrintToChatAll("Whitelist loaded");
	Format(command, sizeof(command), "mp_tournament_whitelist %s", whitelist);
	ServerCommand(command, sizeof(command));
	command = "mp_tournament_restart";
	ServerCommand(command, sizeof(command));
}
