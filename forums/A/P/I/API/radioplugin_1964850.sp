#include <sourcemod>
#include <cURL>

#define RADIOPLUGIN_TIMER 30.0 // Time between updates in seconds
#define RADIOPLUGIN_MAXLENGTH 256 // Max length for station name / URL / artist + song name length
#define RADIOPLUGIN_LOADING_MESSAGE "Loading song data" // Hardly will ever get seen, text shown when song data is still loading

new Handle:g_StationList = INVALID_HANDLE;
new Handle:g_SongList = INVALID_HANDLE;
new g_LoadedStationCount = 0;
new g_StationCount = 0;
new Handle:g_ResponseBuffer = INVALID_HANDLE;

new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,30},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

LoadStationList() {
	if(g_StationList != INVALID_HANDLE) {
		ClearArray(g_StationList);
		CloseHandle(g_StationList);
	}

	if(g_SongList != INVALID_HANDLE) {
		ClearArray(g_SongList);
		CloseHandle(g_SongList);
	}

	if(g_ResponseBuffer != INVALID_HANDLE) {
		ClearArray(g_ResponseBuffer);
		CloseHandle(g_ResponseBuffer);
	}

	g_StationList = CreateArray(RADIOPLUGIN_MAXLENGTH);
	g_SongList = CreateArray(RADIOPLUGIN_MAXLENGTH);
	g_ResponseBuffer = CreateArray(RADIOPLUGIN_MAXLENGTH);

	new String:stationCfgPath[1024];
	BuildPath(Path_SM, stationCfgPath, sizeof(stationCfgPath), "configs/stations.cfg");

	new Handle:kv = CreateKeyValues("Stations");
	FileToKeyValues(kv, stationCfgPath);
 
	if (!KvGotoFirstSubKey(kv)) {
		return;
	}

	decl String:stationName[RADIOPLUGIN_MAXLENGTH];
	decl String:stationURL[RADIOPLUGIN_MAXLENGTH];

	do {
		KvGetString(kv, "name", stationName, sizeof(stationName));
		KvGetString(kv, "song_url", stationURL, sizeof(stationURL));

		PushArrayString(g_StationList, stationName);
		PushArrayString(g_StationList, stationURL);

		PushArrayString(g_SongList, RADIOPLUGIN_LOADING_MESSAGE);

		PushArrayString(g_ResponseBuffer, "");

		g_StationCount++;
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv);
}

DownloadStationData() {
	g_LoadedStationCount = 0;

	for(new stationIndex = 0; stationIndex < g_StationCount; stationIndex++) {
		GetStationDetails(stationIndex);
	}
}

public Action:TimerCallback(Handle:timer, any:data) {
	DownloadStationData();

	return Plugin_Continue;
}

public OnPluginStart() {
	LoadStationList();

	CreateTimer(RADIOPLUGIN_TIMER, TimerCallback, _, TIMER_REPEAT);

	DownloadStationData();
}

PrintStationInfo() {
	for(new stationIndex = 0; stationIndex < g_StationCount; stationIndex++) {
		new String:stationName[RADIOPLUGIN_MAXLENGTH];
		new String:stationSong[RADIOPLUGIN_MAXLENGTH];

		GetStationName(stationIndex, stationName, sizeof(stationName));
		GetArrayString(g_SongList, stationIndex, stationSong, sizeof(stationSong));

		PrintToChatAll("[RADIO] %s: %s", stationName, stationSong);
		PrintToServer("[RADIO] %s: %s", stationName, stationSong);
	}
}

public OnStationDetailsRequestComplete(Handle:hndl, CURLcode: code, any:stationIndex) {
	CloseHandle(hndl);

	new String:songBuffer[RADIOPLUGIN_MAXLENGTH];
	GetArrayString(g_ResponseBuffer, stationIndex, songBuffer, sizeof(songBuffer));
	
	SetArrayString(g_SongList, stationIndex, songBuffer);

	g_LoadedStationCount++;

	new String:name[RADIOPLUGIN_MAXLENGTH];
	GetStationName(stationIndex, name, sizeof(name));

	if(g_LoadedStationCount == g_StationCount) {
		PrintStationInfo();
	}
}

public StationDetailsWriteFunc(Handle:hndl, const String:buffer[], const bytes, const nmemb, any:stationIndex) {
	new String:songBuffer[RADIOPLUGIN_MAXLENGTH];
	GetArrayString(g_ResponseBuffer, stationIndex, songBuffer, sizeof(songBuffer));

	Format(songBuffer, sizeof(songBuffer), "%s%s", songBuffer, buffer);

	SetArrayString(g_ResponseBuffer, stationIndex, songBuffer);

	return bytes*nmemb;
}

GetStationName(stationIndex, String:output[], maxlen) {
	new nameIndex = (stationIndex * 2) + 0;

	GetArrayString(g_StationList, nameIndex, output, maxlen);
}

GetStationURL(stationIndex, String:output[], maxlen) {
	new urlIndex = (stationIndex * 2) + 1;

	GetArrayString(g_StationList, urlIndex, output, maxlen);
}

GetStationDetails(stationIndex) {
	new Handle:curl = curl_easy_init();
	
	if(curl == INVALID_HANDLE) {
		return;
	}

	CURL_DEFAULT_OPT(curl);

	SetArrayString(g_ResponseBuffer, stationIndex, "");

	new String:url[RADIOPLUGIN_MAXLENGTH];

	GetStationURL(stationIndex, url, sizeof(url));

	curl_easy_setopt_function(curl, CURLOPT_WRITEFUNCTION, StationDetailsWriteFunc, stationIndex);
	curl_easy_setopt_string(curl, CURLOPT_URL, url);

	curl_easy_perform_thread(curl, OnStationDetailsRequestComplete, stationIndex);
}