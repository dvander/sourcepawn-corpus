#pragma semicolon 1

#include <sdktools>
#include <sourcemod>
#include <clientprefs>

#define PL_VERSION "1.2"

#define KARAOKE_OFFSET_MIN -5.0
#define KARAOKE_OFFSET_MAX  5.0

public Plugin:myinfo = {
	name        = "Karaoke",
	author      = "EnigmatiK",
	description = "HAPPY JOY SING-ALONG FUN TIME !!!!",
	version     = PL_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=102670"
}

new String:karaoke_url[192] = "http://your.site/play.php";

new String:song_title[128];
new String:song_url[192];
new Float:song_time;
new Handle:menu_songvote = INVALID_HANDLE;
new Handle:menu_sorttype = INVALID_HANDLE;
new Handle:menu_sort_albums = INVALID_HANDLE;
new Handle:menu_sort_artist = INVALID_HANDLE;
new Handle:menu_sort_titles = INVALID_HANDLE;
new Handle:cookie_offs_l = INVALID_HANDLE;
new Handle:cookie_offs_m = INVALID_HANDLE;
new Handle:cookie_volume = INVALID_HANDLE;
//new Handle:arr_songdata = INVALID_HANDLE;
new Handle:arr_albums = INVALID_HANDLE;
new Handle:arr_lyrics = INVALID_HANDLE;
new Handle:arr_timers = INVALID_HANDLE;
new Handle:kv_songs = INVALID_HANDLE;

ParseLrcFile(const String:filename[], Handle:trie_metadata, Handle:pack_lines) {
	decl String:path[192];
	BuildPath(Path_SM, path, sizeof(path), "data/karaoke/%s.lrc", filename);
	new Handle:file = OpenFile(path, "r");
	decl String:line[256], index, split;
	while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line))) {
		ReplaceString(line, sizeof(line), "\r", "");
		ReplaceString(line, sizeof(line), "\n", "");
		ReplaceString(line, sizeof(line), "\xEF\xBB\xBF", ""); // UTF-8 "BOM"
		if (line[0] == '[') {
			index = FindCharInString(line, ']');
			if (index > 0) {
				line[index] = '\0';
				split = FindCharInString(line, ':');
				if (split > 0) {
					if (IsCharNumeric(line[1])) {
						if (pack_lines != INVALID_HANDLE) {
							WritePackFloat(pack_lines, StringToInt(line[1]) * 60 + StringToFloat(line[split + 1]));
							WritePackString(pack_lines, line[index + 1]);
						}
					} else if (trie_metadata != INVALID_HANDLE) {
						line[split] = '\0';
						StringToLower(line[1]);
						SetTrieString(trie_metadata, line[1], line[split + 1]);
					}
				} else {
					LogError("err: invalid tag in line '%s' of %s", line, filename);
				}
			} else {
				LogError("err: missing ] in line '%s' of %s", line, filename);
			}
		} else if (line[0] != '\0') {
			LogError("err: bad line '%s' in %s", line, filename);
		}
	}
	CloseHandle(file);
}

/*******************
 * OnPluginStart() *
 *******************/
public OnPluginStart() {
	// get karaoke URL
	decl String:path[128];
	BuildPath(Path_SM, path, sizeof(path), "data/karaoke.txt");
	if (!FileExists(path)) SetFailState("Missing file %s", path);
	new Handle:karaoke_file = OpenFile(path, "rt");
	ReadFileLine(karaoke_file, karaoke_url, sizeof(karaoke_url));
	CloseHandle(karaoke_file);

	// load songs
	kv_songs = CreateKeyValues("songs");
	BuildPath(Path_SM, path, sizeof(path), "data/karaoke");
	if (!DirExists(path)) SetFailState("Missing directory %s", path);
	new Handle:dir = OpenDirectory(path);
	decl FileType:filetype, Handle:metadata;
	decl String:fname[128], String:info1[128], String:info2[128], String:info3[128];
	while (ReadDirEntry(dir, fname, sizeof(fname), filetype)) {
		if (filetype == FileType_File && StrContains(fname, ".lrc", false) == strlen(fname) - 4) {
			fname[FindCharInString(fname, '.', true)] = '\0';
			KvJumpToKey(kv_songs, fname, true);
			metadata = CreateTrie();
			ParseLrcFile(fname, metadata, INVALID_HANDLE);
			info1[0] = '\0';
			info2[0] = '\0';
			GetTrieString(metadata, "ar", info1, sizeof(info1));
			GetTrieString(metadata, "ti", info2, sizeof(info2));
			KvSetString(kv_songs, "artist", info1);
			KvSetString(kv_songs, "title", info2);
			Format(info1, sizeof(info1), "%s - %s", info1, info2);
			info2[0] = '\0';
			GetTrieString(metadata, "al", info2, sizeof(info2));
			KvSetString(kv_songs, "name", info1);
			KvSetString(kv_songs, "album", info2);
			PrintToServer("[Karaoke] loaded %s", info1);
			CloseHandle(metadata);
			KvGoBack(kv_songs);
		}
	}
	CloseHandle(dir);

	/***********
	 * SORTING *
	 ***********/
	menu_sorttype = CreateMenu(menu_handler_sorting);
	SetMenuTitle(menu_sorttype, "Choose sorting:");
	AddMenuItem(menu_sorttype, "", "Sort by Artist");
	AddMenuItem(menu_sorttype, "", "Sort by Title");
	AddMenuItem(menu_sorttype, "", "Sort by Album");
	//
	new Handle:songs_array;
	new Handle:songs_trie;
	new i, size, size2;
	// by artist ("artist - title")
	songs_array = CreateArray(ByteCountToCells(sizeof(info1)));
	songs_trie  = CreateTrie();
	KvRewind(kv_songs);
	KvGotoFirstSubKey(kv_songs);
	do {
		KvGetSectionName(kv_songs, info1, sizeof(info1));
		KvGetString(kv_songs, "name", info2, sizeof(info2));
		PushArrayString(songs_array, info2);
		SetTrieString(songs_trie, info2, info1);
	} while (KvGotoNextKey(kv_songs));
	SortADTArray(songs_array, Sort_Ascending, Sort_String);
	size = GetArraySize(songs_array);
	menu_sort_artist = CreateMenu(menu_handler);
	SetMenuTitle(menu_sort_artist, "Choose a song:");
	for (i = 0; i < size; i++) {
		GetArrayString(songs_array, i, info1, sizeof(info1));
		if (GetTrieString(songs_trie, info1, info2, sizeof(info2))) AddMenuItem(menu_sort_artist, info2, info1);
	}
	CloseHandle(songs_array);
	CloseHandle(songs_trie);
	// by title ("title - artist")
	songs_array = CreateArray(ByteCountToCells(sizeof(info1)));
	songs_trie  = CreateTrie();
	KvRewind(kv_songs);
	KvGotoFirstSubKey(kv_songs);
	do {
		KvGetSectionName(kv_songs, info1, sizeof(info1));
		KvGetString(kv_songs, "artist", info2, sizeof(info2));
		KvGetString(kv_songs, "title", info3, sizeof(info3));
		Format(info3, sizeof(info3), "%s - %s", info3, info2);
		PushArrayString(songs_array, info3);
		SetTrieString(songs_trie, info3, info1);
	} while (KvGotoNextKey(kv_songs));
	SortADTArray(songs_array, Sort_Ascending, Sort_String);
	size = GetArraySize(songs_array);
	menu_sort_titles = CreateMenu(menu_handler);
	SetMenuTitle(menu_sort_titles, "Choose a song:");
	for (i = 0; i < size; i++) {
		GetArrayString(songs_array, i, info1, sizeof(info1));
		if (GetTrieString(songs_trie, info1, info2, sizeof(info2))) AddMenuItem(menu_sort_titles, info2, info1);
	}
	CloseHandle(songs_array);
	CloseHandle(songs_trie);
	// by album
	songs_array = CreateArray(ByteCountToCells(sizeof(info1)));
	arr_albums = CreateArray();
	KvRewind(kv_songs);
	KvGotoFirstSubKey(kv_songs);
	do {
		KvGetString(kv_songs, "album", info1, sizeof(info1));
		if (FindStringInArray(songs_array, info1) == -1) PushArrayString(songs_array, info1);
	} while (KvGotoNextKey(kv_songs));
	SortADTArray(songs_array, Sort_Ascending, Sort_String);
	size = GetArraySize(songs_array), size2 = GetMenuItemCount(menu_sort_artist);
	menu_sort_albums = CreateMenu(menu_handler_albums);
	SetMenuTitle(menu_sort_albums, "Choose a song:");
	for (i = 0; i < size; i++) {
		GetArrayString(songs_array, i, info1, sizeof(info1));
		new Handle:menu_album = CreateMenu(menu_handler);
		IntToString(PushArrayCell(arr_albums, menu_album), info2, sizeof(info2));
		for (new j = 0; j < size2; j++) {
			GetMenuItem(menu_sort_artist, j, info2, sizeof(info2));
			KvJumpToKey(kv_songs, info2);
			KvGetString(kv_songs, "album", info2, sizeof(info2));
			if (StrEqual(info1, info2)) {
				KvGetString(kv_songs, "name", info2, sizeof(info2));
				KvGetSectionName(kv_songs, info3, sizeof(info3));
				AddMenuItem(menu_album, info3, info2);
			}
			KvRewind(kv_songs);
		}
		if (info1[0] == '\0') strcopy(info1, sizeof(info1), "[No Album]");
		AddMenuItem(menu_sort_albums, info2, info1);
	}
	CloseHandle(songs_array);

	// precache TF2 sounds
	if (FileExists("vo/announcer_begins_20sec.wav", true)) {
		PrecacheSound("vo/announcer_begins_20sec.wav", true);
		PrecacheSound("vo/announcer_begins_10sec.wav", true);
		PrecacheSound("vo/announcer_begins_5sec.wav", true);
		PrecacheSound("vo/announcer_begins_4sec.wav", true);
		PrecacheSound("vo/announcer_begins_3sec.wav", true);
		PrecacheSound("vo/announcer_begins_2sec.wav", true);
		PrecacheSound("vo/announcer_begins_1sec.wav", true);
	}

	// cvars
	CreateConVar("karaoke_version", PL_VERSION, "Karaoke plugin by EnigmatiK", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED);
	// cmds
	RegAdminCmd("k", cmd_karaoke, ADMFLAG_SLAY);
	RegAdminCmd("karaoke", cmd_karaoke, ADMFLAG_SLAY);
	RegAdminCmd("kstop", cmd_kstop, ADMFLAG_SLAY);
	RegAdminCmd("kvote", cmd_kvote, ADMFLAG_SLAY);
	RegConsoleCmd("offset", cmd_offset);
	RegConsoleCmd("vol", cmd_volume);
	// cookies
	cookie_offs_l = RegClientCookie("karaoke_offset_lyric", "Sets the offset for Karaoke mod.", CookieAccess_Public);
	cookie_offs_m = RegClientCookie("karaoke_offset_music", "Sets the offset for Karaoke mod.", CookieAccess_Public);
	cookie_volume = RegClientCookie("karaoke_volume", "Sets the volume for Karaoke mod.", CookieAccess_Public);

	// initialization
	arr_lyrics = CreateArray(ByteCountToCells(192));
	arr_timers = CreateArray();
}

/*****
 * ! *
 *****/
public Action:cmd_karaoke(client, args) {
	if (song_url[0] != '\0') {
		ReplyToCommand(client, "\x03[Karaoke]\x01 Please wait for the current song to finish.");
	} else {
		DisplayMenu(menu_sorttype, client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public Action:cmd_kstop(client, args) {
	if (song_url[0] != '\0') {
		for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) backgroundMOTD(i, "about:blank");
		ReplyToCommand(client, "\x03[Karaoke]\x01 Stopped \x05%s\x01.", song_title);
		timer_unlock(INVALID_HANDLE);
	} else {
		ReplyToCommand(client, "\x03[Karaoke]\x01 There is no song to stop!");
	}
	return Plugin_Handled;
}

public Action:cmd_kvote(client, args) {
	if (!IsNewVoteAllowed() || IsVoteInProgress()) {
		ReplyToCommand(client, "\x03[Karaoke]\x01 You cannot start a vote at this time.");
	} else if (song_url[0] == '\0') {
		new Handle:arr_songs = CreateArray(), count = GetMenuItemCount(menu_sort_artist);
		for (new i = 0; i < count; i++) PushArrayCell(arr_songs, i);
		while ((count = GetArraySize(arr_songs)) > 6) RemoveFromArray(arr_songs, GetRandomInt(0, count - 1));
		//
		decl String:info[64], String:disp[128];
		menu_songvote = CreateMenu(menu_handler);
		SetMenuTitle(menu_songvote, "Choose a song:");
		for (new i = 0; i < count; i++) {
			GetMenuItem(menu_sort_artist, GetArrayCell(arr_songs, i), info, sizeof(info), _, disp, sizeof(disp));
			AddMenuItem(menu_songvote, info, disp);
		}
		CloseHandle(arr_songs);
		VoteMenuToAll(menu_songvote, 20);
	} else {
		ReplyToCommand(client, "\x03[Karaoke]\x01 Please wait for the current song to finish.");
	}
	return Plugin_Handled;
}

public Action:cmd_offset(client, args) {
	if (GetCmdArgs()) {
		decl String:type[8], String:offset[8];
		new Float:offs = 0.0;
		GetCmdArg(1, type, sizeof(type));
		GetCmdArg(2, offset, sizeof(offset));
		if (offset[0] == '\0') {
			if (StrEqual(type, "music", false)) {
				ReplyToCommand(client, "\x03[Karaoke]\x01 Your music offset is\x05 %.1f\x01 second(s).", getOffset(client, cookie_offs_m));
				return Plugin_Handled;
			}
			if (StrEqual(type, "lyrics", false)) {
				ReplyToCommand(client, "\x03[Karaoke]\x01 Your lyrics offset is\x05 %.1f\x01 second(s).", getOffset(client, cookie_offs_l));
				return Plugin_Handled;
			}
		} else {
			offs = StringToFloat(offset);
			if (offs < KARAOKE_OFFSET_MIN) offs = KARAOKE_OFFSET_MIN;
			if (offs > KARAOKE_OFFSET_MAX) offs = KARAOKE_OFFSET_MAX;
			if (StrEqual(type, "music", false)) {
				FloatToString(offs, offset, sizeof(offset));
				SetClientCookie(client, cookie_offs_m, offset);
				ReplyToCommand(client, "\x03[Karaoke]\x01 Your music offset is now\x05 %.1f\x01 second(s).", offs);
				return Plugin_Handled;
			}
			if (StrEqual(type, "lyrics", false)) {
				offs = FloatAbs(offs);
				FloatToString(offs, offset, sizeof(offset));
				SetClientCookie(client, cookie_offs_l, offset);
				ReplyToCommand(client, "\x03[Karaoke]\x01 Your lyrics offset is now\x05 %.1f\x01 second(s).", offs);
				return Plugin_Handled;
			}
		}
	}
	ReplyToCommand(client, "\x03[Karaoke]\x01 Syntax:\x05 /offset [music|lyrics] [time]");
	ReplyToCommand(client, "\x03[Karaoke]\x01 The music offset is how much later to start");
	ReplyToCommand(client, "\x03[Karaoke]\x01 the music. The lyrics offset is how much earlier");
	ReplyToCommand(client, "\x03[Karaoke]\x01 to display lyrics. You should find your music");
	ReplyToCommand(client, "\x03[Karaoke]\x01 offset first, then set the lyrics offset if you");
	ReplyToCommand(client, "\x03[Karaoke]\x01 want time to read the lyrics before singing.");
	return Plugin_Handled;
}

public Action:cmd_volume(client, args) {
	new current = getVolume(client);
	if (GetCmdArgs() == 1) {
		decl String:vol_[4];
		GetCmdArg(1, vol_, sizeof(vol_));
		new vol = StringToInt(vol_);
		if (vol <= 0) vol = 0;
		if (vol > 100) vol = 100;
		current = vol;
		IntToString(vol, vol_, sizeof(vol_));
		SetClientCookie(client, cookie_volume, vol_);
		//
		if (song_url[0] != '\0') playSong(client);
	}
	ReplyToCommand(client, "\x03[Karaoke]\x01 Your volume is set to\x05 %d\x01.", current);
	return Plugin_Handled;
}

public menu_handler_sorting(Handle:menu, MenuAction:action, client, item) {
	if (action != MenuAction_Select) return;
	switch (item) {
		case 0: DisplayMenu(menu_sort_artist, client, MENU_TIME_FOREVER);
		case 1: DisplayMenu(menu_sort_titles, client, MENU_TIME_FOREVER);
		case 2: DisplayMenu(menu_sort_albums, client, MENU_TIME_FOREVER);
	}
}

public menu_handler(Handle:menu, MenuAction:action, client, item) {
	if (action != MenuAction_Select && action != MenuAction_VoteEnd) {
		if (menu == menu_songvote && action == MenuAction_End) CloseHandle(menu);
		return;
	}
	// get file
	decl String:file[64];
	GetMenuItem(menu, item, file, sizeof(file), _, song_title, sizeof(song_title));
	if (menu == menu_sort_titles) {
		KvJumpToKey(kv_songs, file);
		KvGetString(kv_songs, "name", song_title, sizeof(song_title));
		KvRewind(kv_songs);
	}
	// precache song
	FormatEx(song_url, sizeof(song_url), "%s?s=%s", karaoke_url, file);
	decl String:url[192];
	FormatEx(url, sizeof(url), "%s&v=3", song_url);
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) backgroundMOTD(i, url);
	// parse lyrics
	parse_lrc(file, 21.5);
	// countdown
	CreateTimer(1.0, timer_countdown, GetTime() + 21, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public menu_handler_albums(Handle:menu, MenuAction:action, client, item) {
	if (action != MenuAction_Select) return;
	DisplayMenu(GetArrayCell(arr_albums, item), client, MENU_TIME_FOREVER);
}

public Action:timer_stopmusic(Handle:timer) {
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) backgroundMOTD(i, "about:blank");
}

/*************
 * parse_lrc *
 *************/
parse_lrc(String:fname[], Float:delay) {
	new Handle:data = CreateTrie(), Handle:lyrics = CreateDataPack(), Float:offset;
	ParseLrcFile(fname, data, lyrics);
	decl String:offset_[8];
	if (GetTrieString(data, "offset", offset_, sizeof(offset_))) offset = StringToFloat(offset_) / 1000.0;
	CloseHandle(data);
	ResetPack(lyrics);
	decl Float:time, String:text[192];
	new Float:last = 65535.0;
	text[0] = '\0';
	do {
		time = ReadPackFloat(lyrics);
		if (text[0] != '\0') for (new Float:i = last + 4; i < time; i += 4) startLineTimers(i + delay, PushArrayString(arr_lyrics, text));
		ReadPackString(lyrics, text, sizeof(text));
		ReplaceString(text, sizeof(text), "|", "\n");
		ReplaceString(text, sizeof(text), "\\'", "\"");
		ReplaceString(text, sizeof(text), "\\n", "\n");
		startLineTimers(time + delay - offset, PushArrayString(arr_lyrics, text));
		last = time;
	} while (IsPackReadable(lyrics, 1));
	CloseHandle(lyrics);
	//
	CreateTimer(time + delay + KARAOKE_OFFSET_MAX - offset, timer_unlock);
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i)) CreateTimer(delay + getOffset(i, cookie_offs_m), timer_startmusic, i);
}

public Action:timer_countdown(Handle:timer, any:data) {
	new t = data - GetTime();
	if (t <= 0) {
		song_time = GetEngineTime();
		return Plugin_Stop;
	}
	if (t <= 10 || t == 20) {
		// center text
		PrintCenterTextAll(
			"%s will play in %d second%c\nYou can change the volume with: /vol [0 - 100]",
			song_title, t, (t - 1) ? 's' : ' ');
		// sound file
		if (!(5 < t < 10)) {
			decl String:file[30];
			FormatEx(file, sizeof(file), "vo/announcer_begins_%dsec.wav", t);
			if (FileExists(file, true))
				for (new i = 1; i <= MaxClients; i++)
					if (IsClientInGame(i))
						EmitSoundToClient(i, file);
		}
	}
	return Plugin_Continue;
}

public Action:timer_startmusic(Handle:timer, any:client) {
	if (IsClientInGame(client)) playSong(client);
}

public Action:timer_displayline(Handle:timer, any:data) {
	new index = FindValueInArray(arr_timers, timer);
	if (index != -1) RemoveFromArray(arr_timers, index);
	new client = data >> 10;
	new lineid = data & 0x3FF;
	if (lineid < GetArraySize(arr_lyrics)) {
		decl String:line[192];
		GetArrayString(arr_lyrics, lineid, line, sizeof(line));
		PrintCenterText(client, line);
	}
}

public Action:timer_unlock(Handle:timer) {
	new size = GetArraySize(arr_timers);
	for (new i = 0; i < size; i++) KillTimer(Handle:GetArrayCell(arr_timers, i));
	ClearArray(arr_lyrics);
	ClearArray(arr_timers);
	song_title[0] = '\0';
	song_url[0] = '\0';
}

//

backgroundMOTD(client, String:url[]) {
	new Handle:kv = CreateKeyValues("data");
	KvSetString(kv, "title", "TF2 Karaoke by EnigmatiK");
	KvSetString(kv, "type", "2");
	KvSetString(kv, "msg", url);
	ShowVGUIPanel(client, "info", kv, false);
	CloseHandle(kv);
}

playSong(client) {
	if (song_url[0] != '\0') {
		decl String:url[192];
		FormatEx(url, sizeof(url), "%s&t=%f&v=%d",
			song_url,
			GetEngineTime() - song_time + getOffset(client, cookie_offs_m),
			getVolume(client));
		backgroundMOTD(client, url);
	}
}

Float:getOffset(client, Handle:offset) {
	decl String:offs_[8];
	offs_[0] = '\0';
	GetClientCookie(client, offset, offs_, sizeof(offs_));
	if (offs_[0] != '\0') {
		new Float:offs = StringToFloat(offs_);
		if (offs < KARAOKE_OFFSET_MIN) offs = KARAOKE_OFFSET_MIN;
		if (offs > KARAOKE_OFFSET_MAX) offs = KARAOKE_OFFSET_MAX;
		return offs;
	} else {
		return 0.0;
	}
}

getVolume(client) {
	decl String:vol_[4];
	vol_[0] = '\0';
	GetClientCookie(client, cookie_volume, vol_, sizeof(vol_));
	if (vol_[0] != '\0') {
		new vol = StringToInt(vol_);
		if (vol < 0) vol = 0;
		if (vol > 100) vol = 100;
		return vol;
	} else {
		return 80;
	}
}

startLineTimers(Float:delay, line) {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			PushArrayCell(
				arr_timers,
				CreateTimer(
					delay - getOffset(i, cookie_offs_l),
					timer_displayline,
					(i << 10) | line,
					TIMER_FLAG_NO_MAPCHANGE
				)
			);
		}
	}
}

stock StringToLower(String:str[]) {
	new len = strlen(str);
	for (new i = 0; i < len; i++) CharToLower(str[i]);
	// for (new i = 0; str[i]; i++) CharToLower(str[i]);
}
