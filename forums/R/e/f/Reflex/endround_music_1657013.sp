#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

#define MUSIC_DISABLED 0
#define MUSIC_ENABLED  1

public Plugin:myinfo =
{
	name = "EndRound Music",
	author = "Reflex",
	description = "Plays random music at round end",
	version = PLUGIN_VERSION
};

new g_Cursor;

new g_ClientCookies[MAXPLAYERS + 1];
new Handle:g_MusicCookie = INVALID_HANDLE;

new Handle:g_Array_AllMusicFiles = INVALID_HANDLE;
new Handle:g_Array_PerMapMusicFiles = INVALID_HANDLE;

new Handle:g_Cvar_MusicDirectory = INVALID_HANDLE;
new Handle:g_Cvar_MusicDownloadLimit = INVALID_HANDLE;

public OnPluginStart()
{
	g_Array_AllMusicFiles = CreateArray(PLATFORM_MAX_PATH);
	g_Array_PerMapMusicFiles = CreateArray(PLATFORM_MAX_PATH);
	
	CreateConVar("sm_endround_music_version", PLUGIN_VERSION, "Endround Music Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Cvar_MusicDirectory = CreateConVar("sm_music_directory", "", "Music directory name relative to the 'sounds' folder");
	g_Cvar_MusicDownloadLimit = CreateConVar("sm_music_download_limit", "5", "Per map download limit", 0, true, 1.00, true, 10.0);
	
	HookEvent("teamplay_round_win", Event_TeamPlayRoundWin);

	// enable music by default
	for (new i = 0; i < MAXPLAYERS; i++) {
		g_ClientCookies[i] = MUSIC_ENABLED;
	}
}

public OnConfigsExecuted()  // fired every map
{
	g_Cursor = 0;
	FetchAllMusicFiles();
	TakeRandomMusicFiles();
}

public OnAllPluginsLoaded()
{
	if (GetExtensionFileStatus("clientprefs.ext") == 1) {
		g_MusicCookie = RegClientCookie("endround_music", "To disable endround music set this to 0", CookieAccess_Public);
		SetCookieMenuItem(Handler_CookieMenu, 0, "");
	}
}

public OnClientCookiesCached(client)
{
	decl String:str[2];
	GetClientCookie(client, g_MusicCookie, str, sizeof(str));
	if (strlen(str) < 1) {
		return;
	}
	new enabled = StringToInt(str);
	if (!enabled) {
		g_ClientCookies[client] = MUSIC_DISABLED;
	}
}

public Handler_CookieMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	if (action == CookieMenuAction_DisplayOption) {
		if (g_ClientCookies[client] == MUSIC_ENABLED) {
			Format(buffer, maxlen, "Disable Endround Music");
		} else {
			Format(buffer, maxlen, "Enable Endround Music");
		}
	} else if (action == CookieMenuAction_SelectOption) {
		if (g_ClientCookies[client] == MUSIC_ENABLED) {
			g_ClientCookies[client] = MUSIC_DISABLED;
			PrintToChat(client, "[SM] Endround Music Disabled");
		} else {
			g_ClientCookies[client] = MUSIC_ENABLED;
			PrintToChat(client, "[SM] Endround Music Enabled");
		}
		decl String:value[2];
		IntToString(g_ClientCookies[client], value, sizeof(value));
		SetClientCookie(client, g_MusicCookie, value);
		ShowCookieMenu(client);
	}
}

public Event_TeamPlayRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetArraySize(g_Array_PerMapMusicFiles) == 0) {
		return;
	}
	// play music
	decl String:musicfile[PLATFORM_MAX_PATH];
	GetArrayString(g_Array_PerMapMusicFiles, g_Cursor, musicfile, sizeof(musicfile));
	decl String:playcmd[PLATFORM_MAX_PATH];
	Format(playcmd, sizeof(playcmd), "play \"%s\"", musicfile);
	for (new i = 1; i < MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) &&
			g_ClientCookies[i] == MUSIC_ENABLED)
		{
			//EmitSoundToClient(i, musicfile);
			ClientCommand(i, playcmd);
		}
	}
	g_Cursor++;
	if (g_Cursor == GetArraySize(g_Array_PerMapMusicFiles)) {
		g_Cursor = 0;
	}
}

public OnClientDisconnect(client)
{
	g_ClientCookies[client] = MUSIC_ENABLED;
}

FetchAllMusicFiles()
{
	ClearArray(g_Array_AllMusicFiles);
	// build path
	decl String:music_dir[PLATFORM_MAX_PATH];
	GetConVarString(g_Cvar_MusicDirectory, music_dir, sizeof(music_dir));
	if (strlen(music_dir) == 0) {
		decl String:cvar_name[64];
		GetConVarName(g_Cvar_MusicDirectory, cvar_name, sizeof(cvar_name));
		LogError("Please specify the music directory via the %s variable.", cvar_name);
		return;
	}
	decl String:path_to_music_dir[PLATFORM_MAX_PATH];
	Format(path_to_music_dir, sizeof(path_to_music_dir), "sound/%s", music_dir);
	if (!DirExists(path_to_music_dir)) {
		LogError("Directory '%s' dosn't exist.", path_to_music_dir);
		return;
	}
	// open path to read dir content
	new Handle:h_dir = OpenDirectory(path_to_music_dir);
	if (h_dir == INVALID_HANDLE) {
		LogError("Error listing '%s' directory, check the permissions.", path_to_music_dir);
		return;
	}
	// loop thru all files in the dir
	new FileType:type = FileType_Unknown;
	new String:filename[PLATFORM_MAX_PATH];
	while (ReadDirEntry(h_dir, filename, sizeof(filename), type))
	{
		// skip other dirs
		if (type != FileType_File) {
			continue;
		}
		// skip non mp3 files
		decl String:file_ext[5];
		strcopy(file_ext, sizeof(file_ext), filename[strlen(filename) - 4]);
		if (strcmp(file_ext, ".mp3", false) != 0) {
			continue;
		}
		// push mp3 file into global array
		Format(filename, sizeof(filename), "%s/%s", music_dir, filename);
		PushArrayString(g_Array_AllMusicFiles, filename);
	}
	if (GetArraySize(g_Array_AllMusicFiles) == 0) {
		LogError("MP3 files not found. Put your music into the '%s' directory.", path_to_music_dir);
	}
}

TakeRandomMusicFiles()
{
	ClearArray(g_Array_PerMapMusicFiles);
	// calc limit
	new limit = GetConVarInt(g_Cvar_MusicDownloadLimit);
	if (limit > GetArraySize(g_Array_AllMusicFiles)) {
		limit = GetArraySize(g_Array_AllMusicFiles);
	}
	if (limit == 0) {
		return;
	}
	// take X random files
	decl String:path[PLATFORM_MAX_PATH];
	for (new i = 0; i < limit; i++)
	{
		// pop random file
		new id = GetRandomInt(0, GetArraySize(g_Array_AllMusicFiles) - 1);
		GetArrayString(g_Array_AllMusicFiles, id, path, sizeof(path));
		RemoveFromArray(g_Array_AllMusicFiles, id);
		// push it into different array
		PushArrayString(g_Array_PerMapMusicFiles, path);
		// precache and add to download table
		PrecacheSound(path, true);
		Format(path, sizeof(path), "sound/%s", path);
		AddFileToDownloadsTable(path);
	}
}
