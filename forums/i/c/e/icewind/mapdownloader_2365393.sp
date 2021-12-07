#pragma semicolon 1
#include <sourcemod>
#include <cURL>
#include <tf2>

public Plugin:myinfo =
{
	name = "map downloader",
	author = "Icewind",
	description = "Automatically download missing maps",
	version = "0.1",
	url = "https://spire.tf"
};

new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,300},
	{_:CURLOPT_CONNECTTIMEOUT,120},
	{_:CURLOPT_USE_SSL,CURLUSESSL_TRY},
	{_:CURLOPT_SSL_VERIFYPEER,0},
	{_:CURLOPT_SSL_VERIFYHOST,0},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

new Handle:g_hCvarUrl = INVALID_HANDLE;

public OnPluginStart()
{
	g_hCvarUrl = CreateConVar("sm_map_download_base", "http://fakkelbrigade.eu/maps", "map download url", FCVAR_PROTECTED);

	RegServerCmd("changelevel", HandleChangeLevelAction);
}

public Action:HandleChangeLevelAction(args)
{
	new String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:path[128];
	Format(path, sizeof(path), "maps/%s.bsp", arg);

	if (FileExists(path)) {
		return Plugin_Continue;
	} else {
		PrintToChatAll("Map %s not found, trying to download", path);
		DownloadMap(arg, path);
		return Plugin_Handled;
	}
}

public DownloadMap(String:map[128], String:targetPath[128])
{
	decl String:fullUrl[512];
	decl String:BaseUrl[128];
	GetConVarString(g_hCvarUrl, BaseUrl, sizeof(BaseUrl));
	new Handle:curl = curl_easy_init();
	new Handle:output_file = curl_OpenFile(targetPath, "wb");
	CURL_DEFAULT_OPT(curl);

	Format(fullUrl, sizeof(fullUrl), "%s/%s.bsp", BaseUrl, map);

	PrintToChatAll("Trying to download %s from %s", map, fullUrl);

	new Handle:hDLPack = CreateDataPack();
	WritePackCell(hDLPack, _:output_file);
	WritePackString(hDLPack, map);
	WritePackString(hDLPack, targetPath);

	curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, output_file);
	curl_easy_setopt_string(curl, CURLOPT_URL, fullUrl);
	curl_easy_perform_thread(curl, onComplete, hDLPack);
}

public onComplete(Handle:hndl, CURLcode:code, any hDLPack) {
	decl String:map[128];
	decl String:targetPath[128];

	ResetPack(hDLPack);
	CloseHandle(Handle:ReadPackCell(hDLPack)); // output_file
	ReadPackString(hDLPack, map, sizeof(map));
	ReadPackString(hDLPack, targetPath, sizeof(targetPath));
	CloseHandle(hDLPack);
	CloseHandle(hndl);

	if (code != CURLE_OK) {
		PrintToChatAll("Error downloading map %s", map);
		decl String:sError[256];
		curl_easy_strerror(code, sError, sizeof(sError));
		PrintToChatAll("cURL error: %s", sError);
		PrintToChatAll("cURL error code: %d", code);
	} else {
		//PrintToChatAll("map size(%s): %d", targetPath, FileSize(targetPath));
		if (FileSize(targetPath) < 1024) {
			PrintToChatAll("Map file to small, discarding");
			DeleteFile(targetPath);
			return;
		}
		PrintToChatAll("Successfully downloaded map %s", map);
		changeLevel(map);
	}
	return;
}

public changeLevel(String:map[128])
{
	decl String:command[512];
	Format(command, sizeof(command), "changelevel %s", map);
	ServerCommand(command, sizeof(command));
}
