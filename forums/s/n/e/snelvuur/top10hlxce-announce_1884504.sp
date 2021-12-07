/*
top10hlxce-announce.sp

Plays a announcement when a top10 ranked player of hlstats ce comes into your server and plays it to all.
    
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define MAX_FILE_LEN 256

new g_Rank[MAXPLAYERS+1] = { -1, ... };

new Handle:g_hCvEnabled, bool:g_CvEnabled;
new Handle:g_hCvGameType, String:g_CvGameType[32];
new Handle:g_hCvTextType, g_CvTextType;
new Handle:g_hCvSoundFile, Handle:g_hSoundFile;

new Handle:g_hEnableAnnouncementCookie;
new Handle:g_hPlaySoundCookie;
new Handle:g_hAnnounceMeCookie;
new Handle:g_hMessageTypeCookie, g_MessageType[MAXPLAYERS+1] = { -1, ... };

new bool:g_Connecting = false;
new Handle:g_hDatabase = INVALID_HANDLE;

new bool:g_IsLeft4Dead = false;

#define PLUGIN_NAME "Top 10 hlstats ce announcer"
#define PLUGIN_AUTHOR "Snelvuur"
#define PLUGIN_DESCRIPTION "Plays sound when a player top 10 ranked player of hlstats ce connects."
#define PLUGIN_VERSION "2.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=139703"
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	static String:supported_games[4][] = {
		"tf",
		"cstrike",
		"lef4dead",
		"l4d2"
	};

	decl String:buffer[32];

	GetGameFolderName(buffer, sizeof(buffer));

	new bool:supported = false;
	for (new i = 0; i < 4; i++) {
		if (StrEqual(buffer, supported_games[i], false)) {
			supported = true;

			if (i >= 2) {
				g_IsLeft4Dead = true;
			}
		}
	}

	if (!supported) {
		SetFailState("Unsupported game \"%s\".", buffer);
	}

	InitVersionCvar("top10_hlstatsce", PLUGIN_NAME, PLUGIN_VERSION);
	g_CvEnabled = InitCvar(g_hCvEnabled, OnConVarChanged, "sm_top10_hlstatsce_enabled", "1", "Whether this plugin should be enabled", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	InitCvar(g_hCvGameType, OnConVarChanged, "sm_top10_hlstatsce_game", buffer, "The shortname found after the game settings for particular servers on admin page", FCVAR_DONTRECORD, _, _, _, _, 3);
	g_CvTextType = InitCvar(g_hCvTextType, OnConVarChanged, "sm_top10_hlstatsce_text", "2", "Default message type. 1 = Center, 2 = Hint text, 3 = Regular text. Leave empty for center", FCVAR_DONTRECORD, true, 1.0, true, 3.0);
	g_hCvSoundFile = CreateConVar("sm_top10_hlstatsce_sound", "lethalzone/top10/", "The sound file/folder (random file, non-recursive) to play when a top10 hlstats player joins the game", FCVAR_DONTRECORD);

	g_Connecting = true;
	SQL_TConnect(T_Connect, "top10");

	SetCookieMenuItem(CookieMenuHandler_Top10, 0, "Top10 Player Announcement");

	g_hEnableAnnouncementCookie = RegClientCookie("hlstatsx_top10_joinmsg_enable", "Whether to print a chag message whenever a top10 player enters the server.", CookieAccess_Public);
	g_hPlaySoundCookie = RegClientCookie("hlstatsx_top10_joinmsg_sound", "Whether to play a sound whenever a top10 player enters the server.", CookieAccess_Public);
	g_hAnnounceMeCookie = RegClientCookie("hlstatsx_top10_announceme", "Whether the player's top10 rank should be announced when he enters the server.", CookieAccess_Public);
	g_hMessageTypeCookie = RegClientCookie("hlstatsx_top10_joinmsg_type", "Top10 join message type. 1 = Center, 2 = Hint text, 3 = Regular text. Leave empty for center.", CookieAccess_Public);

	RegConsoleCmd("sm_t14", t14);
}

public Action:t14(client, argc) {
	g_Rank[client] = 1;
	OnClientCookiesCached(client);
	return Plugin_Handled;
}

public OnMapStart() {
	if (!g_IsLeft4Dead && g_hCvSoundFile != INVALID_HANDLE) {
		decl String:path[MAX_FILE_LEN];
		GetConVarString(g_hCvSoundFile, path, sizeof(path));

		PrecacheSounds(path, true, g_hSoundFile);
	}

	if (!g_Connecting && g_hDatabase == INVALID_HANDLE) {
		g_Connecting = true;
		SQL_TConnect(T_Connect, "top10");
	}
}

public OnClientPostAdminCheck(client) {
	if (!g_CvEnabled || IsFakeClient(client)) {
		return;
	}

	decl String:steamid[32];
	GetClientAuthString(client, steamid, sizeof(steamid));
	CheckTop10(client, steamid);
}

public OnClientDisconnect(client) {
	g_Rank[client] = 0;
	g_MessageType[client] = -1;
}

public OnClientCookiesCached(client) {
	decl String:buffer[4];
	if (g_Rank[client] > 0 && g_Rank[client] <= 10) {
		GetClientCookie(client, g_hAnnounceMeCookie, buffer, sizeof(buffer));

		if (StrEqual(buffer, "") || StringToInt(buffer)) {
			decl String:message[128];
			Format(message, sizeof(message), "Top 10 player %N connected, currently rank %i", client, g_Rank[client]);

			for (new i = 1; i <= MaxClients; i++) {
				if (!IsClientValid(i)) {
					continue;
				}

				GetClientCookie(i, g_hEnableAnnouncementCookie, buffer, sizeof(buffer));

				if (StrEqual(buffer, "") || StringToInt(buffer)) {
					PrintMessage(i, message);
				}
			}

			if (g_hSoundFile != INVALID_HANDLE && !g_IsLeft4Dead) {
				new index = GetArraySize(g_hSoundFile);

				if (index) {
					decl String:sound[MAX_FILE_LEN];
					index = GetRandomInt(0, index - 1);

					GetArrayString(g_hSoundFile, index, sound, sizeof(sound));

					for (new i = 1; i <= MaxClients; i++) {
						if (!IsClientValid(i)) {
							continue;
						}

						GetClientCookie(i, g_hPlaySoundCookie, buffer, sizeof(buffer));

						if (StrEqual(buffer, "") || StringToInt(buffer)) {
							EmitSoundToClient(i, sound);
						}
					}
				}
			}
		}

		g_Rank[client] = -1;
	}
}

PrintMessage(client, const String:text[]) {
	switch(g_MessageType[client] != -1 ? g_MessageType[client] : g_CvTextType) {
		case 1:
		{
			PrintCenterText(client, text);
		}
		case 2:
		{
			PrintHintText(client, text);
		}
		case 3:
		{
			PrintToChat(client, text);
		}
		default:
		{
			PrintCenterText(client, text);
		}
	}
}

CheckTop10(userid, const String:auth[])	{
	if (g_hDatabase == INVALID_HANDLE) {
		return;
	}

	decl String:query[512];

	Format(query, sizeof(query),
		"SELECT COUNT(*) AS rank \
		FROM hlstats_Players \
		WHERE \
			hlstats_Players.game = '%s' AND \
			hideranking = 0 \
			AND skill >= ( \
				SELECT skill \
				FROM hlstats_Players \
				JOIN hlstats_PlayerUniqueIds \
				ON hlstats_Players.playerId = hlstats_PlayerUniqueIds.playerId \
				WHERE uniqueID = MID('%s', 9) \
				AND hlstats_PlayerUniqueIds.game = '%s' \
			)\
		;", g_CvGameType, auth, g_CvGameType
	);
	SQL_TQuery(g_hDatabase, T_CheckTop10, query, userid);
}

public T_Connect(Handle:owner, Handle:hndl, const String:error[], any:data) {
	g_Connecting = false;

	if ((g_hDatabase = hndl) == INVALID_HANDLE)    {
		LogError("Database failure: \"%s\"", error);
		return;
    }
}

public T_CheckTop10(Handle:owner, Handle:hndl, const String:error[], any:client) {
 	if (!IsClientValid(client))    {
        return;
    }

	if (hndl == INVALID_HANDLE)	{
		LogError("Query failed: \"%s\"", error);
	}
	else {
		if (SQL_FetchRow(hndl))	{
			g_Rank[client] = SQL_FetchInt(hndl, 0);
			if (AreClientCookiesCached(client)) {
				OnClientCookiesCached(client);
			}
		}
	}
}

public CookieMenuHandler_Top10(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) {
	if (action == CookieMenuAction_SelectOption) {
		ShowPrefMenu(client);
	}
}

ShowPrefMenu(client) {
	decl String:display[128],
		String:cookie[4],
		bool:enable;

	new Handle:menu = CreateMenu(MenuHandler_Top10);

	GetClientCookie(client, g_hEnableAnnouncementCookie, cookie, sizeof(cookie));
	enable = !StrEqual(cookie, "") && !StringToInt(cookie);
	Format(display, sizeof(display), "%sable top10 player join messages", enable ? "En" : "Dis");
	AddMenuItem(menu, enable ? "1" : "0", display);

	GetClientCookie(client, g_hPlaySoundCookie, cookie, sizeof(cookie));
	enable = !StrEqual(cookie, "") && !StringToInt(cookie);
	Format(display, sizeof(display), "%sable playing a sound whenever a top10 player enters the server", enable ? "En" : "Dis");
	AddMenuItem(menu, enable ? "1" : "0", display);

	GetClientCookie(client, g_hAnnounceMeCookie, cookie, sizeof(cookie));
	enable = !StrEqual(cookie, "") && !StringToInt(cookie);
	Format(display, sizeof(display), "%sable broadcasting my top10 join message", enable ? "En" : "Dis");
	AddMenuItem(menu, enable ? "1" : "0", display);

	GetClientCookie(client, g_hMessageTypeCookie, cookie, sizeof(cookie));
	Format(display, sizeof(display), "Alter Top10 join message type (%s)", StrEqual(cookie, "") ? "1" : cookie);
	AddMenuItem(menu, "", display);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Top10(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:buffer[4];

		GetMenuItem(menu, param2, buffer, sizeof(buffer));

		decl Handle:cookie;
		switch (param2) {
			case 0:
			{
				cookie = g_hEnableAnnouncementCookie;
			}
			case 1:
			{
				cookie = g_hPlaySoundCookie;
			}
			case 2:
			{
				cookie = g_hAnnounceMeCookie;
			}
			case 3:
			{
				ShowMsgTypePrefMenu(param1);
				return;
			}
			default:
			{
				ShowPrefMenu(param1);
				return;
			}
		}

		SetClientCookie(param1, cookie, buffer);
		ShowPrefMenu(param1);
	}
	else if (action == MenuAction_Cancel) {
		ShowCookieMenu(param1);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

ShowMsgTypePrefMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_MessageType);
	SetMenuTitle(menu, "Choose an option:");
	AddMenuItem(menu, "1", "Center text");
	AddMenuItem(menu, "2", "Hint text");
	AddMenuItem(menu, "3", "Regular text");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
	
public MenuHandler_MessageType(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		decl String:buffer[4];

		GetMenuItem(menu, param2, buffer, sizeof(buffer));
		SetClientCookie(param1, g_hMessageTypeCookie, buffer);
		g_MessageType[param1] = StringToInt(buffer);
		ShowPrefMenu(param1);
	}
	else if (action == MenuAction_Cancel) {
		ShowPrefMenu(param1);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cvar == g_hCvEnabled) {
		g_CvEnabled = bool:StringToInt(newVal);
	}
	else if (cvar == g_hCvGameType) {
		strcopy(g_CvGameType, sizeof(g_CvGameType), newVal);
	}
	else if (cvar == g_hCvTextType) {
		g_CvTextType = StringToInt(newVal);
	}
}

stock PrecacheSounds(const String:path[], bool:preload = false, &Handle:array) {
	CloseHandle2(array);

	array = CreateArray(MAX_FILE_LEN);

	if (strlen(path) == 0) {
		return 0;
	}

	decl String:path_[MAX_FILE_LEN];
	Format(path_, sizeof(path_), "sound/%s", path);

	new len = strlen(path_);
	if (path_[len-1] == '/') {
		path_[len-1] = '\0';
	}

	if (FileExists(path_)) {
		PrecacheSound(path_, preload);
		AddFileToDownloadsTable(path_);
		PushArrayString(array, path_);
	}
	else if (DirExists(path_)) {
		new Handle:directory = OpenDirectory(path_);

		if (directory != INVALID_HANDLE) {
			decl FileType:type;

			decl String:file[MAX_FILE_LEN];
			while (ReadDirEntry(directory, file, sizeof(file), type)) {
				if (type != FileType_File) {
					continue;
				}

				Format(file, sizeof(file), "%s/%s", path_, file);
				ReplaceStringEx(file, sizeof(file), "sound/", "");
				if (!PrecacheSound(file, preload)) {
					continue;
				}

				PushArrayString(array, file);

				Format(file, sizeof(file), "sound/%s", file);
				AddFileToDownloadsTable(file);
			}
		}
	}

	return GetArraySize(array);
}

/**
 * \brief Creates a plugin version console variable.
 *
 * \return									Whether creating the console variable was successful
 * \error									Convar name is blank or is the same as an existing console command
 */
stock InitVersionCvar(
	const String:cvar_name[],				///<! [in] The console variable's name (sm_<name>_version)
	const String:plugin_name[],				///<! [in] The plugin's name
	const String:plugin_version[],			///<! [in] The plugin's version
	additional_flags = 0					///<! [in] additional FCVAR_* flags  (default: FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD)
) {
	if (StrEqual(cvar_name, "") || StrEqual(plugin_name, "")) {
		return false;
	}

	new cvar_name_len = strlen(cvar_name) + 12,
		descr_len = strlen(cvar_name) + 20;
	decl String:name[cvar_name_len],
		String:descr[descr_len];

	Format(name, cvar_name_len, "sm_%s_version", cvar_name);
	Format(descr, descr_len, "\"%s\" - version number", plugin_name);

	new Handle:cvar = FindConVar(name),
		flags = FCVAR_NOTIFY | FCVAR_DONTRECORD | additional_flags;

	if (cvar != INVALID_HANDLE) {
		SetConVarString(cvar, plugin_version);
		SetConVarFlags(cvar, flags);
	}
	else {
		cvar = CreateConVar(name, plugin_version, descr, flags);
	}

	if (cvar != INVALID_HANDLE) {
		CloseHandle(cvar);
		return true;
	}

	LogError("Couldn't create version console variable \"%s\".", name);
	return false;
}

/**
 * \brief Creates a new console variable and hooks it to the specified OnConVarChanged: callback.
 *
 * This function attempts to deduce from the default value what type of data (int, float)
 * is supposed to be stored in the console variable, and returns its value accordingly.
 * (Its type can also be manually specified.) Alternatively one could opt to let the
 * ConVarChanged: callback do the initialisation. This is however prone to error;
 * should CreateConVar() fail, the callback is never fired.
 *
 * \return									Context sensitive; check detailed description
 * \error									Callback is invalid, or convar name is blank or is the same as an existing console command
 */
stock any:InitCvar(
	&Handle:cvar,							///<! [out] A handle to the newly created convar. If the convar already exists, a handle to it will still be returned.
	ConVarChanged:callback,					///<! [in] Callback function called when the convar's value is modified.
	const String:name[],					///<! [in] Name of new convar
	const String:defaultValue[],			///<! [in] String containing the default value of new convar
	const String:description[] = "",		///<! [in] Optional description of the convar
	flags = 0,								///<! [in] Optional bitstring of flags determining how the convar should be handled. See FCVAR_* constants for more details
	bool:hasMin = false,					///<! [in] Optional boolean that determines if the convar has a minimum value
	Float:min = 0.0,						///<! [in] Minimum floating point value that the convar can have if hasMin is true
	bool:hasMax = false,					///<! [in] Optional boolean that determines if the convar has a maximum value
	Float:max = 0.0,						///<! [in] Maximum floating point value that the convar can have if hasMax is true
	type = -1								///<! [in] Return / initialisation type
) {
	cvar = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	if (cvar != INVALID_HANDLE) {
		HookConVarChange(cvar, callback);
	}
	else {
		LogMessage("Couldn't create console variable \"%s\", using default value \"%s\".", name, defaultValue);
	}

	if (type < 0 || type > 3) {
		type = 1;
		new len = strlen(defaultValue);
		for (new i = 0; i < len; i++) {
			if (defaultValue[i] == '.') {
				type = 2;
			}
			else if (IsCharNumeric(defaultValue[i])) {
				continue;
			}
			else {
				type = 0;
				break;
			}
		}
	}

	if (type == 1) {
		return cvar != INVALID_HANDLE ? GetConVarInt(cvar) : StringToInt(defaultValue);
	}
	else if (type == 2) {
		return cvar != INVALID_HANDLE ? GetConVarFloat(cvar) : StringToFloat(defaultValue);
	}
	else if (cvar != INVALID_HANDLE && type == 3) {
		Call_StartFunction(INVALID_HANDLE, callback);
		Call_PushCell(cvar);
		Call_PushString("");
		Call_PushString(defaultValue);
		Call_Finish();

		return true;
	}

	return 0;
}

/**
 * \brief Returns whether the client is valid.
 *
 * If the client is out of range, this function assumes the input was a client serial.
 *
 * \return									Whether the client is valid
 */
stock IsClientValid(
	&client,								///<! [in, out] The client's index
	bool:in_game = true,					///<! [in] Whether the client has to be ingame
	bool:in_kick_queue = false				///<! [in] Whether the client can be in the kick queue
) {
	if (client <= 0 || client > MaxClients) {
		client = GetClientFromSerial(client);
	}

	return client > 0 && client <= MaxClients && IsClientConnected(client) && (!in_game || IsClientInGame(client)) && (in_kick_queue || !IsClientInKickQueue(client));
}

stock CloseHandle2(&Handle:hndl) {
	if (hndl != INVALID_HANDLE) {
		CloseHandle(hndl);
		hndl = INVALID_HANDLE;
	}
}
