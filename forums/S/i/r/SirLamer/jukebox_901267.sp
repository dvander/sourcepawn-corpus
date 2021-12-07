// Change tracking
// - Changed the location of Jukebox's data file from "data/jukebox/" to just "data/".

// (COMPLETE) Add popularity decay
// (COMPLETE) Call top menu if no arguments are search strings
// (COMPLETE) Fix playback from top menu to support playall and volume shifting
// (COMPLETE) Change "random" playback to be decided by server (for repeatability and info display)
// (COMPLETE) Add playback comments to chat
// (COMPLETE) Add comments regarding what people are playing
// (COMPLETE) Introduce the "loud" and "soft" volume thing
// (COMPLETE) Add admin controls (ie for command "all")
// (COMPLETE) Add eavesdrop function
// (COMPLETE) Add force ability
// (COMPLETE) Add playback tracking
// (COMPLETE) Add "enable/disable" toggle
// (COMPLETE) Stop playback when Jukebox is disabled
// Disable MOTD on map change
// Prebuffer playback software (during first connection?)
// (COMPLETE) Fix volume shifting to use server settings
// (COMPLETE) Convert KeyValues settings to ConVar
// (COMPLETE) Embed "off" command
// (COMPLETE) Change "volumes" table to "options" table
// (COMPLETE) Add ability for each user to disable playback
// (COMPLETE) Add display of current setting to variable value options in menu
// (COMPLETE) Add "browse by genre" support
// (COMPLETE) Add help system
// (COMPLETE) Add option to restart track after volume change
// Add option to force use of remote file server

//BUGS
// (FIXED) "all" doesn't propogate past first level menu
// (FIXED) some new songs don't seem to work
// (FIXED) The 'search' query is not removed after first use
// (FIXED) the admin lock on commands blocks out admins, too
// (FIXED) Fix folder structures to be built using the internal function (the proper way)
// (CANCELLED) Remove "popularity" counter from random plays
// (FIXED) Search queries for "artists" and "albums" are supressed if any one album title is a positive hit
// The Great Unstability Bug
// Can't search words like "g-man" and "wall-e" because of dash - need to refine command detection
// Spotty behavior across map changes

#pragma semicolon 1 // Enables support for new lines using semi-colon
#include <sourcemod> // Base SourceMod library
#include <base64> // Used to pack long playlists within HTTP GET's 100 character limit
#include <rc4> // Used to encrypt Unix time as key for leech protection
//#include <downloader>

#define PLUGIN_VERSION "0.3.6.0" // 2009-09-20

#define menu_maxtime 90 // [seconds] The maximum time to display menus before self-cancelling.

#define PLAYLIST_MAX 36 // Maximum allowed tracks in a playlist.
#define SEARCH_MAX 100 // Maximum number of search results to be displayed in the menu at once.

#define title_length 80 // [characters] The maximum allowed track title length.
#define album_length 80 // [characters] The maximum allowed album title length.
#define artist_length 40 // [characters] The maximum allowed artist name length.
#define username_length 60 // [characters] The maximum allowed username length.

#define help_url "http://www.teamcheesus.com/user-manual/jukebox" // The URL to the Jukebox help guide for your server.  If you don't want to operate your own, a manual for the latest version is kept up to date at http://www.teamcheesus.com/user-manual/jukebox

#define result_subfolder "data/" // The folder within the SourceMod folder to store all the necessary Jukebox goodies.
#define result_filename_prefix "music_menu_"
#define data_file "jukebox_data.txt"

#define query_groups_max 4 // Used by internal Jukebox functions.  Should not be changed.

// Settings from jukebox.cfg
new String:db_options[25]; // The MySQL table name for storing user-controlled settings
new String:db_tracks[25]; // The MySQL table name for storing track records and metadata
new String:db_streams[25]; // The MySQL table name for tracking active music streams
new String:db_playlists[25]; // The MySQL table name for storing playlist items for all active stream

new String:result_folder[96]; // The sub-SourceMod folder used to save various Jukebox data.

new Handle:music_db = INVALID_HANDLE; // The handle object for the MySQL database connection
new Handle:input_types = INVALID_HANDLE; // KeyValues handling for managing Jukebox's internal Input Types system
new Handle:settings = INVALID_HANDLE; // Stores system-critical settings from the file specified in config_path.
new newest_track_date = 0; // [Unix timestamp] Stores the upload date of the newest track for display in the main menu.  Refreshed every map change.
new time_offset = 0; // [seconds] The time correction ( = web server - game server) to syncrhonize the game server's clock with the web server's clock (for MySQL transactions).  Refreshed each map change.
new num_clients; // The maximum number of clients allowed on the server.  Refreshed each map change.

// Used to manage and store user-customizable settings.
new String:options_names[][] = {"playall", "volume"}; // The name used for the setting within Jukebox's code.
new Handle:cv_options_defaults[sizeof(options_names)]; // The cvar handle objects for The default values to be assigned to new users.  These settings are assigned upon first connect and changes are not retro-active to users who haven't set their own values.
new options[MAXPLAYERS+1][sizeof(options_names)]; // Stores each client's settings.  Array position is associated with options_names.

new Handle:cv_base_url = INVALID_HANDLE, Handle:cv_leech_password = INVALID_HANDLE, Handle:cv_db_conn_name = INVALID_HANDLE, Handle:cv_db_tracks = INVALID_HANDLE, Handle:cv_db_options = INVALID_HANDLE, Handle:cv_db_streams = INVALID_HANDLE, Handle:cv_db_playlists = INVALID_HANDLE;

/* About stream_memberships
This array keeps track of what streams clients are listening to and in what state.
Value = 0: User is not listening to any tracks.
Value = -1: User is not listening to any tracks but has just connected to the server and is waiting to join in on any multi-track play-to-all stream in progress upon start of the next track.
Value >= 2: User is synchronously listening to the track number identified
Value <= 2: User is asynchronously listening to the track number identified by the absolute (non-negative) value.  For multi-track streams, user will be re-synchronized at the start of the next track.
Note: Stream IDs start at 2 and are incremented with each new stream.  Stream ID #1 is never assigned.
*/
new stream_memberships[MAXPLAYERS+1];

new bool:play_lock[MAXPLAYERS+1]; // Boolean array; if true, user cannot hault music playback.

new Handle:results_storage[MAXPLAYERS+1]; // Array of KeyValue handle objects for storing menu data during user's selection for subsequent reference.

// Map change management
new String:disconnect_steam_ids[MAXPLAYERS+5][25]; // Stores list of the most recently disconnected clients using their steam IDs.
new disconnect_streams[sizeof(disconnect_steam_ids)]; // Stores the stream that disconncted users were subscribed to.  Associated with disconnect_steam_ids by position.
new bool:disconnect_locks[sizeof(disconnect_steam_ids)]; // Stores the play_lock setting of disconnected users.  Associated with disconnect_steam_ids by position.
new disconnect_time[sizeof(disconnect_steam_ids)]; // Stores the time of disconnnect for the most recent players.  Associated with disconnect_steam_ids by position.

//Cvar handles
new Handle:cv_enabled = INVALID_HANDLE; // Boolean cvar (default = 1).  Jukebox commands will work only when jb_enabled is TRUE (ie. = 1).
new Handle:cv_volume_loud = INVALID_HANDLE; // Integer cvar (default = 20).  The amount of the per-user volume increase provided when the Jukebox command "-loud" is used, as a percentage of full volume.
new Handle:cv_volume_soft = INVALID_HANDLE; // Integer cvar (default = 20).  The amount of the per-user volume decrease provided when the Jukebox command "-soft" is used, as a percentage of full volume.
new Handle:cv_popularity_decay_rate = INVALID_HANDLE; // Integer cvar (default = 5).  The percentage amount of popularity decay per interval.
new Handle:cv_popularity_decay_interval = INVALID_HANDLE; // Integer cvar (default = 86400).  The duration of each popularity decay interval, in seconds.


// Plugin's information, please do not edit without cause.
public Plugin:myinfo = {
	name = "Jukebox",
	author = "SirLamer",
	description = "Music streaming system",
	version = PLUGIN_VERSION,
	url = "http://www.teamcheesus.com"
};

public OnPluginStart() {
	// Create the ConVars
	CreateConVar("jukebox_sms_version", PLUGIN_VERSION, "Version of Jukebox for Source: Stream Music System", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cv_enabled = CreateConVar("jb_enabled", "1", "Enable or disable Jukebox", _, true, 0.0, true, 1.0);
	cv_base_url = CreateConVar("jb_base_url", "", "URL path to Jukebox's base folder.", FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	cv_leech_password = CreateConVar("jb_leech_password", "", "Anti-leech password used to timestamp produced URLs.  Must match the leech password specified on the web server.", FCVAR_PROTECTED|FCVAR_SPONLY);
	cv_db_conn_name = CreateConVar("jb_db_conn_name", "default", "Named SQL connection to be used by Jukebox.  Database must be defined within sourcemod/configs/database.cfg", FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	
	cv_volume_loud = CreateConVar("jb_volume_loud", "20", "Volume boost for 'loud' playback", _, true, 0.0, true, 50.0);
	cv_volume_soft = CreateConVar("jb_volume_soft", "-20", "Volume reduction for 'soft' playback", _, true, -50.0, true, 0.0);
	cv_popularity_decay_rate = CreateConVar("jb_popularity_decay_rate", "5", "Percentage rate of decay of popularity scores per interval time", _, true, 0.0, true, 100.0);
	cv_popularity_decay_interval = CreateConVar("jb_popularity_decay_interval", "86400", "The interval time between popularity decay events, in seconds", _, true, 60.0);

	// WARNING - the order of these ConVars must be coordinated with the "options_names" array of strings
	cv_options_defaults[0] = CreateConVar("jb_playall_default", "1", "Default setting for if clients should comply with 'play all' command.", _, true, 0.0, true, 1.0);
	cv_options_defaults[1] = CreateConVar("jb_volume_default", "80", "Default playback volume for new users", _, true, 1.0, true, 100.0);
	
	cv_db_tracks = CreateConVar("jb_db_tracks", "jb_tracks", "SQL database name for the Tracks database.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	cv_db_options = CreateConVar("jb_db_options", "jb_options", "SQL Database name for the Options database.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	cv_db_streams = CreateConVar("jb_db_streams", "jb_streams", "SQL Database name for the Streams database.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);
	cv_db_playlists = CreateConVar("jb_db_playlists", "jb_stream_tracks", "SQL Database name for the Playlists database.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY);

	HookConVarChange(cv_db_tracks, SettingTracks);
	HookConVarChange(cv_db_options, SettingOptions);
	HookConVarChange(cv_db_streams, SettingStreams);
	HookConVarChange(cv_db_playlists, SettingPlaylists);

	AutoExecConfig(true, "jukebox");
	
	GetConVarString(cv_db_tracks, db_tracks, sizeof(db_tracks));
	GetConVarString(cv_db_options, db_options, sizeof(db_options));
	GetConVarString(cv_db_streams, db_streams, sizeof(db_streams));
	GetConVarString(cv_db_playlists, db_playlists, sizeof(db_playlists));
	
	// Test base_url and leech_password to remind the server operator to populate their values
	decl String:leech_password_test[32], String:base_url_test[128];
	GetConVarString(cv_leech_password, leech_password_test, sizeof(leech_password_test));
	GetConVarString(cv_base_url, base_url_test, sizeof(base_url_test));
	if(strlen(leech_password_test) == 0) {
		PrintToServer("Jukebox: WARNING - You must populate 'base_url' in cfg/sourcemod/jukebox.cfg with the URL to Jukebox's base folder on your web server."); 
	}
	if(strlen(base_url_test) == 0) {
		PrintToServer("Jukebox: WARNING - You must populate 'leech_password' in cfg/sourcemod/jukebox.cfg with the anti-leech password specified in settings.php on your web server.");
	}

/*
	new Handle:read_settings = CreateKeyValues("Configs");
	decl String:config_fullpath[96];

	BuildPath(Path_SM, config_fullpath, sizeof(config_fullpath), "%s", config_path);
	if(!FileToKeyValues(read_settings, config_fullpath)) {
		PrintToServer("Jukebox: CRITICAL ERROR - Failed to load settings file %s", config_fullpath);
	}

	KvGetString(read_settings, "leech_password", leech_password, sizeof(leech_password));
	KvGetString(read_settings, "base_url", base_url, sizeof(base_url));
	KvGetString(read_settings, "db_options", db_options, sizeof(db_options));
	KvGetString(read_settings, "db_tracks", db_tracks, sizeof(db_tracks));
	KvGetString(read_settings, "db_streams", db_streams, sizeof(db_streams));
	KvGetString(read_settings, "db_playlists", db_playlists, sizeof(db_playlists));
	KvGetString(read_settings, "db_conn_name", db_conn_name, sizeof(db_conn_name));
	CloseHandle2(read_settings);
*/

	num_clients = MaxClients;
	
	for(new i = 0; i < sizeof(results_storage); i++) {
		results_storage[i] = INVALID_HANDLE;
	}

	// Determine working folder for Jukebox
	BuildPath(Path_SM, result_folder, sizeof(result_folder), "%s", result_subfolder);

	// Prepare the input type KeyValue structure
	new String:queries[][][] = {{"search", "se"}, {"title", "ti"}, {"album", "al"}, {"artist", "ar"}, {"genre", "ge"}};
	new String:params[][][] = {{"volume", "vol"}};
	new String:commands[][][] = {{"all", "playall"}, {"loud", "strong"}, {"soft", "quiet"}, {"force", "force"}};
	new String:admin[][] = {"all", "force"};
	input_types = CreateKeyValues("Input Types");
	for(new i = 0; i < sizeof(queries); i++) {
		for(new j = 0; j < sizeof(queries[]); j++) {
			if(strlen(queries[i][j]) > 0) {
				KvJumpToKey(input_types, queries[i][j], true);
				KvSetString(input_types, "type", "q");
				KvSetString(input_types, "name", queries[i][0]);
				for(new k = 0; k < sizeof(admin); k++) {
					if(StrEqual(queries[i][j], admin[k])) {
						KvSetString(input_types, "admin", "1");
						break;
					}
				}
				KvGoBack(input_types);
			}
		}
	}
	for(new i = 0; i < sizeof(params); i++) {
		for(new j = 0; j < sizeof(params[]); j++) {
			if(strlen(params[i][j]) > 0) {
				KvJumpToKey(input_types, params[i][j], true);
				KvSetString(input_types, "type", "p");
				KvSetString(input_types, "name", params[i][0]);
				for(new k = 0; k < sizeof(admin); k++) {
					if(StrEqual(params[i][j], admin[k])) {
						KvSetString(input_types, "admin", "1");
						break;
					}
				}
				KvGoBack(input_types);
			}
		}
	}
	for(new i = 0; i < sizeof(commands); i++) {
		//PrintToServer("In command loop %d", i); // DEBUG
		for(new j = 0; j < sizeof(commands[]); j++) {
			//PrintToServer("In command subloop %d", j); // DEBUG
			//PrintToServer("commands[%d][%d] = '%s'", i, j, commands[i][j]); // DEBUG
			if(strlen(commands[i][j]) > 0) {
				//PrintToServer("Command is not empty."); // DEBUG
				KvJumpToKey(input_types, commands[i][j], true);
				KvSetString(input_types, "type", "c");
				KvSetString(input_types, "name", commands[i][0]);
				//PrintToServer("Assigned name '%s'", commands[i][0]); // DEBUG
				for(new k = 0; k < sizeof(admin); k++) {
					if(StrEqual(commands[i][0], admin[k])) {
						//PrintToServer("Command '%s' is rights protected.", commands[i][0]); // DEBUG
						KvSetString(input_types, "admin", "1");
						break;
					}
				}
				KvGoBack(input_types);
			}
		}
	}
	//PrintToServer("End of commands creation."); // DEBUG
	KvRewind(input_types);

	// Restore options (for if plugin is restarted mid-game)
	for(new i = 1; i <= num_clients; i++) {
		if(IsClientInGame(i)) {
			LookupOptions(i);
		}
	}

	// Create the plugin commands
	RegConsoleCmd ("sm_jukebox", Command_Jukebox, "Invokes the Jukebox music system.");
	RegConsoleCmd ("sm_jb", Command_Jukebox, "Invotes the Jukebox music system.");
	RegConsoleCmd("sm_volume", Command_Volume, "Stores a playback volume level from 10 to 100%.  Usage: !volume <volume>");
	RegConsoleCmd("sm_jboff", Command_JbOff, "Stop music playback.");
	RegAdminCmd("sm_jballoff", Command_JbAllOff, ADMFLAG_CHAT, "Stop music playback for all players.");
	RegConsoleCmd("sm_musicoff", Command_MusicOff, "Alias for sm_jboff.");
	RegConsoleCmd("sm_eavesdrop", Command_Eavesdrop, "Use: sm_eavesdrop  <username>.  Join the most recently started music stream or a particular player's stream, if named.");
	// RegAdminCmd("sm_streamdump", Command_StreamDump, ADMFLAG_CHAT, "Dumps the current stream data to a file for debugging.");
	// RegAdminCmd("sm_streampurge", Command_StreamPurge, ADMFLAG_CHAT, "Temporary fix to deal with stream data corruption by clearing it.");

	// Retrieve global settings

	// Below are the default settings and their values, associated by array position.
	new String:settings_names[][] = {"popularity_datetime"};
	new settings_default[] = {0};
	settings_default[0] = GetTime(); // Insert current Unix datetime for 'popularity_datetime'
	/*
		"popularity_datetime" (No default) - The last time that depreciation has been performed on the popularity stats.
	*/

	decl String:filepath_settings[192];
	new bool:error_hit = false;
	FormatEx(filepath_settings, sizeof(filepath_settings), "%s%s", result_folder, data_file);
	settings = CreateKeyValues("Global Settings");
	if(!FileToKeyValues(settings, filepath_settings)) { // If a settings file does not exist, it will be created
		for(new i = 0; i < sizeof(settings_names); i++) {
			KvSetNum(settings, settings_names[i], settings_default[i]);
		}
		error_hit = true;
	} else { // Check integrity of opened KeyValues config file.  It may have been manually manipulated or may be out of date.
		new get_test;
		for(new i = 0; i < sizeof(settings_names); i++) {
			get_test = KvGetNum(settings, settings_names[i], -99);
			if(get_test == -99) {
				KvSetNum(settings, settings_names[i], settings_default[i]);
				error_hit = true;
			}
		}
	}
	if(error_hit) { // If a change is made, save the file!
		UpdateGlobalSettings();
	}

	/*
	// Create the "stream" keyvalue handle
	streams = CreateKeyValues("Streams");
	KvJumpToKey(streams, "top", true);
	KvSetNum(streams, "latest", 1); // First stream will be "2", to permit use of -1 as a "new client" flag
	KvRewind(streams);
	*/

	// Prepare MySQL database connection
	PrepareConnection();

	return;
}



public OnEventShutdown() {
	UnhookConVarChange(cv_db_tracks, SettingTracks);
	UnhookConVarChange(cv_db_options, SettingOptions);
	UnhookConVarChange(cv_db_streams, SettingStreams);
	UnhookConVarChange(cv_db_playlists, SettingPlaylists);
}



public OnPluginEnd() {
	// Hault all music playback
	for(new i = 1; i <= num_clients; i++) {
		if(stream_memberships[i] < -1 || stream_memberships[1] > 0) {
			RemoveClient(i, true);
		}
	}

	// Clean up memory
	CloseHandle(music_db);
	CloseHandle(input_types);
	CloseHandle(settings);
	CloseHandle(cv_enabled);
	CloseHandle(cv_base_url);
	CloseHandle(cv_leech_password);
	CloseHandle(cv_db_conn_name);
	CloseHandle(cv_db_tracks);
	CloseHandle(cv_db_options);
	CloseHandle(cv_db_streams);
	CloseHandle(cv_db_playlists);
	CloseHandle(cv_volume_loud);
	CloseHandle(cv_volume_soft);
	CloseHandle(cv_popularity_decay_rate);
	CloseHandle(cv_popularity_decay_interval);
	//CloseHandle(streams);
	for(new i = 0; i < sizeof(cv_options_defaults); i++) {
		CloseHandle(cv_options_defaults[i]);
	}
}



public OnConfigsExecuted() {
	num_clients = MaxClients;

	if(PrepareConnection()) {
		
		// Look up the date of the most recently added track
		new String:query_newest[192];
		new Handle:result_newest = INVALID_HANDLE;
		FormatEx(query_newest, sizeof(query_newest), "SELECT UNIX_TIMESTAMP(added) AS added FROM %s ORDER BY added DESC LIMIT 1", db_tracks);
		// SQL_LockDatabase(music_db);
		result_newest = SQL_Query(music_db, query_newest);
		// SQL_UnlockDatabase(music_db);
		if (result_newest == INVALID_HANDLE) {
			newest_track_date = 0;
		} else {
			if (SQL_FetchRow(result_newest)) {
				newest_track_date = SQL_FetchInt(result_newest, 0) + time_offset;
			} else {
				newest_track_date = 0;
			}
		}
		CloseHandle2(result_newest);
		
		// Apply popularity depreciation, if needed
		new popularity_datetime, decay_interval;
		new now_datetime = GetTime();
		popularity_datetime = KvGetNum(settings, "popularity_datetime");
		decay_interval = GetConVarInt(cv_popularity_decay_interval);
		//PrintToConsole(0, "datatime = %d, now = %d, interval = %d, datetime + interval = %d", popularity_datetime, now_datetime, popularity_decay_interval, now_datetime + popularity_decay_interval); // DEBUG
		if(now_datetime > (popularity_datetime + decay_interval)) {
			new decay_rate, num_intervals;
			new String:query_pop[192];
			new Float:decay;
			decay_rate = GetConVarInt(cv_popularity_decay_rate);
			num_intervals = (now_datetime - popularity_datetime)/decay_interval; // Integer division, remainder is truncated
			decay = Pow(1.0 - decay_rate/100.0, 1.0*num_intervals);
			FormatEx(query_pop, sizeof(query_pop), "UPDATE %s SET popularity = popularity*%f", db_tracks, decay);
			// SQL_LockDatabase(music_db);
			if(!SQL_FastQuery(music_db, query_pop)) {
				// SQL_UnlockDatabase(music_db);
				new String:query_error[256];
				SQL_GetError(music_db, query_error, sizeof(query_error));
				PrintToServer("Jukebox: Failed to perform popularity score depretiation.  MySQL error: '%s'.  Query: '%s'.", query_error, query_pop);
				LogError("Jukebox: Failed to perform popularity score depretiation.  MySQL error: '%s'.  Query: '%s'.", query_error, query_pop);
			} else {
				// SQL_UnlockDatabase(music_db);
				popularity_datetime += decay_interval*num_intervals;
				KvSetNum(settings, "popularity_datetime", popularity_datetime);
				UpdateGlobalSettings();
			}
		}
	} else {
		newest_track_date = 0;
	}

	// Regenerate "default" options
	
	// Clean up stored search results
	for(new i = 0; i < sizeof(results_storage); i++) {
		RemoveResults(i);
	}

	return;
}



public OnClientPostAdminCheck(client) {
	// Restore the user's stream data (if it exists)
	// new String:stream_string[11];
	new String:steam_id[25];
	new cell;
	// PrintToChatAll("Jukebox: Testing server console call"); // DEBUG
	// PrintToConsole(client, "Jukebox (DEBUG): Attempting to restore status prior to map change."); // DEBUG

	GetClientAuthString(client, steam_id, sizeof(steam_id));
	cell = FindStringInNaturalArray(disconnect_steam_ids, sizeof(disconnect_steam_ids), steam_id);
	if(cell >= 0 && PrepareConnection(client)) {

		// Check to see if the music stream still exists
		decl String:query[192];
		decl String:error[256];
		new Handle:results = INVALID_HANDLE;
		//IntToString(abs(disconnect_streams[cell]), stream_string, sizeof(stream_string));
		FormatEx(query, sizeof(query), "SELECT COUNT(*) AS 'count' FROM %s WHERE stream_id = %d", db_streams, abs(disconnect_streams[cell]));
		results = SQL_Query(music_db, query);
		//KvRewind(streams);
		if(results == INVALID_HANDLE) {
			SQL_GetError(music_db, error, sizeof(error));
			PrintToServer("Jukebox: Failed to perform stream check on user connection.  Error: \"%s\"  Query: \"%s\"", error, query);
		} else if(SQL_FetchRow(results) && SQL_FetchInt(results, 0) > 0) {
			stream_memberships[client] = disconnect_streams[cell];
			play_lock[client] = disconnect_locks[cell];
		}
		CloseHandle2(results);
		// PrintToConsole(client, "Found past info, copying (stream #%d, lock = %d", disconnect_streams[cell], play_lock[cell]); // DEBUG
		ClearDisconnectData(cell);
	} else {
		stream_memberships[client] = -1;
		play_lock[client] = false;
		// PrintToConsole(client, "Failed to find stream membership for Steam ID %s.", steam_id); // DEBUG
		/*
		for(new i = 0; i <= sizeof(disconnect_steam_ids); i++) {
			PrintToConsole(client, "Disconnected ID #%d = '%s', stream = %d, force_lock = %d, time = %d", i, disconnect_steam_ids[i], disconnect_streams[i], disconnect_locks[i], disconnect_time[i]);
		}
		*/
	}

	// Use to pull user's custom settings
	LookupOptions(client);

	return;
}



public OnClientDisconnect(client) {
	new String:steam_id[25];

	// Save the user's stream settings in case of drop or map change
	// PrintToChatAll("Jukebox: Stream membership of client %d = %d", client, stream_memberships[client]); // DEBUG
	GetClientAuthString(client, steam_id, sizeof(steam_id));
	if(stream_memberships[client] < -1 || stream_memberships[client] > 0) {
		new cell;
		cell = FindStringInNaturalArray(disconnect_steam_ids, sizeof(disconnect_steam_ids), steam_id);
		if(cell < 0) {
			cell = FindMinInArray(disconnect_time, sizeof(disconnect_time));
		}
		strcopy(disconnect_steam_ids[cell], sizeof(disconnect_steam_ids[]), steam_id);
		disconnect_streams[cell] = stream_memberships[client];
		disconnect_locks[cell] = play_lock[client];
		disconnect_time[cell] = GetTime();
		// PrintToChatAll("Jukebox: Client disconnecting... saving Steam ID %s with stream %d for later restore.", disconnect_steam_ids[cell], disconnect_streams[cell]); // DEBUG
	}
	// Clean up stream data
	stream_memberships[client] = 0;
	play_lock[client] = false;

	// Use to clear volume settings - not yet implemented (not required?)
	
	// Delete user's stored results, if they exists
	RemoveResults(client);

	return;
}



public SettingTracks(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_tracks, false) != 0)
	{
		strcopy(db_tracks, sizeof(db_tracks), newValue);
	}
}

public SettingOptions(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_options, false) != 0)
	{
		strcopy(db_options, sizeof(db_options), newValue);
	}
}

public SettingStreams(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_streams, false) != 0)
	{
		strcopy(db_streams, sizeof(db_streams), newValue);
	}
}

public SettingPlaylists(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_playlists, false) != 0)
	{
		strcopy(db_playlists, sizeof(db_playlists), newValue);
	}
}



bool:PrepareConnection(client = -1) {
	if(music_db == INVALID_HANDLE) {
		new String:db_conn_name[32]; // The named MySQL connection to be used by Jukebox
		decl String:error[256];
		
		GetConVarString(cv_db_conn_name, db_conn_name, sizeof(db_conn_name));
		
		if(strlen(db_conn_name) > 0) {
			music_db = SQL_Connect(db_conn_name, true, error, sizeof(error));
		} else {
			music_db = SQL_DefConnect(error, sizeof(error));
		}
		if(music_db == INVALID_HANDLE) {
			if(client >= 0) {
				PrintToConsole(client, "Jukebox: Failed to connect to SQL database.  Error: %s", error);
			} else {
				PrintToServer("Jukebox: Failed to connect to SQL database.  Error: %s", error);
			}
			return false;
		} else {
			// Determine the difference in the clocks between MySQL and the game server
			decl String:query[96];
			new Handle:time_result = INVALID_HANDLE;
			strcopy(query, sizeof(query), "SELECT UNIX_TIMESTAMP() AS time");
			// SQL_LockDatabase(music_db);
			time_result = SQL_Query(music_db, query);
			// SQL_UnlockDatabase(music_db);
			if(time_result != INVALID_HANDLE && SQL_FetchRow(time_result)) {
				new current_time_sql = 0;
				new current_time_pawn = 0;
				current_time_sql = SQL_FetchInt(time_result, 0);
				current_time_pawn = GetTime();
				time_offset = current_time_sql - current_time_pawn;
			} else {
				time_offset = 0;
			}
			CloseHandle(time_result);
		
			// Clean out the "stream" MySQL tables
			FormatEx(query, sizeof(query), "TRUNCATE TABLE %s", db_streams);
			if(!SQL_FastQuery(music_db, query)) {
				SQL_GetError(music_db, error, sizeof(error));
				PrintToServer("Jukebox: Failed to clear streams database.  Error: \"%s\"  Query: \"%s\"", error, query);
			}
		
			FormatEx(query, sizeof(query), "ALTER TABLE %s AUTO_INCREMENT = 2", db_streams);
			if(!SQL_FastQuery(music_db, query)) {
				SQL_GetError(music_db, error, sizeof(error));
				PrintToServer("Jukebox: Failed to adjust stream ID incrementer.  Error: \"%s\"  Query: \"%s\"", error, query);
			}
		
			FormatEx(query, sizeof(query), "TRUNCATE TABLE %s", db_playlists);
			if(!SQL_FastQuery(music_db, query)) {
				SQL_GetError(music_db, error, sizeof(error));
				PrintToServer("Jukebox: Failed to clear streamed tracks database.  Error: \"%s\"  Query: \"%s\"", error, query);
			}
			
			return true;
		}
	} else {
		return true;
	}
}



UpdateGlobalSettings() {
	decl String:filepath_settings[192];
	FormatEx(filepath_settings, sizeof(filepath_settings), "%s%s", result_folder, data_file);
	if(!KeyValuesToFile(settings, filepath_settings)) {
		PrintToServer("Jukebox: WARNING - Failed to apply global configuration update to file '%s'.", filepath_settings);
		LogError("WARNING - Failed to apply global configuration update to file '%s'.", filepath_settings);
		return false;
	} else {
		PrintToServer("Jukebox: Global configuration file updated with new settings.");
		LogAction(0, -1, "Global configuration file updated with new settings.");
	}

	return true;
}



MultipleTest(&multiple) {
	if(multiple) {
		return true;
	} else {
		multiple = true;
		// PrintToConsole(0, "First query, multiple enabled"); // DEBUG
		return false;
	}
}



LookupOptions(client) {
	if(!PrepareConnection()) {
		PrintToConsole(client, "Jukebox: Database connection is unavailable.  Using default option settings.");
		return false;
	}
	
	decl String:steam_id[25];
	decl String:query[320];
	decl String:query_select[160];
	new bool:multiple = false;

	if(!GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		decl String:username[username_length];
		GetClientName(client, username, sizeof(username));
		PrintToConsole(client, "(Jukebox) WARNING: Failed to retrieve your Steam ID.  Custom settings are unavailable.");
		PrintToServer("Jukebox: Failed to retrieve Steam ID for user %s.", username);
		for(new i = 0; i < sizeof(options_names); i++) {
			options[client][i] = GetConVarInt(cv_options_defaults[i]);
		}
		return false;
	}
	for(new i = 0; i < sizeof(options_names); i++) {
		if(MultipleTest(multiple)) {
			Format(query_select, sizeof(query_select), "%s, %s", query_select, options_names[i]);
		} else {
			strcopy(query_select, sizeof(query_select), options_names[i]);
		}
	}
	FormatEx(query, sizeof(query), "SELECT %s FROM %s WHERE steamid = '%s' LIMIT 1", query_select, db_options, steam_id);
	// SQL_LockDatabase(music_db);
	new Handle:results = SQL_Query(music_db, query);
	// SQL_UnlockDatabase(music_db);
	if(results == INVALID_HANDLE) {
		decl String:error[256];
		if(!SQL_GetError(music_db, error, sizeof(error))) {
			error[0] = '\0';
		}
		PrintToConsole(client, "(Jukebox) WARNING: SQL database lookup failed.  Custom settings are unavailable.");
		PrintToServer("Jukebox: SQL query failed during volume settings look-up.  Error: '%s'.  Query: '%s'.", error, query);
		for(new i = 0; i < sizeof(options_names); i++) {
			options[client][i] = GetConVarInt(cv_options_defaults[i]);
		}
		CloseHandle2(results);
		return false;
	}
	if(SQL_FetchRow(results)) {
		for(new i = 0; i < sizeof(options_names); i++) {
			options[client][i] = SQL_FetchInt(results, i);
		}
		CloseHandle2(results);
	} else {
		CloseHandle2(results);
		decl String:query_values[96];
		multiple = false;
		for(new i = 0; i < sizeof(options_names); i++) {
			if(MultipleTest(multiple)) {
				Format(query_values, sizeof(query_values), "%s, %d", query_values, GetConVarInt(cv_options_defaults[i]));
			} else {
				FormatEx(query_values, sizeof(query_values), "%d", GetConVarInt(cv_options_defaults[i]));
			}
		}
		FormatEx(query, sizeof(query), "INSERT INTO %s (steamid, %s) VALUES('%s', %s)", db_options, query_select, steam_id, query_values);
		// SQL_LockDatabase(music_db);
		if(!SQL_FastQuery(music_db, query)) {
			// SQL_UnlockDatabase(music_db);
			decl String:error[256];
			if(!SQL_GetError(music_db, error, sizeof(error))) {
				error[0] = '\0';
			}
			PrintToServer("Jukebox: Failed to add new user '%s' to volume setting database.  Error: '%s'.  Query: '%s'.", steam_id, error, query);
			return false;
		}
		// SQL_UnlockDatabase(music_db);
	}

	return true;
}



SystemLaunch(client, String:args_line[]) {
	#define query_length 2048
	#define query_select_length 128
	#define query_where_length 1536
	#define query_group_length 64
	#define query_order_length 64
	#define cmd_char "-"
	#define break_char " "
	#define query_cmd_length 16
	#define query_type_length 8
	#define word_length 32
	#define word_count_max 8
	#define search_word_min_length 3
	#define sql_string_length 256
	#define count_string_length 4

	new Handle:arguments = CreateKeyValues("MySQL Arguments");
	new parse_test;

	parse_test = ParseCommandLine(client, args_line, arguments);
	switch (parse_test) {
		case -1: {
			// ERROR!
			CloseHandle2(arguments);
			return false;
		}
		case 0: {
			TopMenu(client, arguments);
		}
		case 1: {
			new Handle:menu = CreateMenu(MusicMenuHandler);
			if(!MakeSearchMenu(client, arguments, menu)) {
				// ERROR
				CloseHandle2(arguments);
				CloseHandle2(menu);
				return false;
			}

			DisplayMenu(menu, client, menu_maxtime);
			//PrintToConsole(client, "Jukebox: Progress check - Search function complete - awaiting menu results."); // DEBUG
		}
	}
	CloseHandle2(arguments);
	return true;
}



MakeSearchMenu(const client, Handle:arguments, Handle:menu) {
	//PrintToConsole(client, "Jukebox: Entered function MakeSearchMenu."); // DEBUG
	decl String:query[2048];

	if(!KvSQL(query, sizeof(query), arguments)) {
		PrintToConsole(client, "Jukebox: Failed to build MySQL query from KeyValue data.");
		return false;
	}
	// PrintToConsole(client, "Jukebox: SQL query = %s", query); // DEBUG

	new Handle:kv_menu = CreateKeyValues("Music Search Results");
	if(!MusicDatabaseSearch(client, query, arguments, kv_menu)) {
		PrintToConsole(client, "Jukebox: Database search failed!"); // DEBUG
		CloseHandle2(kv_menu);
		return false;
	}
	//PrintToConsole(client, "Jukebox: Completed music database search."); // DEBUG

	/*
	decl String:filepath[filepath_length];
	FormatEx(filepath, sizeof(filepath), "%s%s%d.txt", result_folder, result_filename_prefix, client);
	KeyValuesToFile(kv_menu, filepath);
	*/
	
	SaveResults(client, kv_menu);
	
	//PrintToConsole(client, "Jukebox: Menu keyfile outputted to network drive."); // DEBUG
	if(!KvToMusicMenu(client, kv_menu, menu)) {
		PrintToConsole(client, "Jukebox: Menu creation failed!"); // DEBUG
		CloseHandle2(kv_menu);
		return false;
	}

	CloseHandle2(kv_menu);

	return true;
}



/*
RemoveQueryItem(Handle:queries, String:key[], bool:announce, client) {
	if(KvJumpToKey(queries, key)) {
		if(KvDeleteThis(queries) != -1) {
			KvGoBack(queries);
		}
		if(announce) {
			PrintToChat(client, "Jukebox: The command '%s' is not permitted with this action.  It has been ignored.", key);
		}
	} else {
		return false;
	}

	return true;
}
*/


AddQueryString(Handle:queries, String:key[], String:value[], client) {
	//PrintToConsole(client, "Adding data '%s' for '%s'...", value, key); // DEBUG
	if(!KvJumpToKey(queries, key, true)) {
		PrintToConsole(client, "Adding data '%s' for %s failed!", value, key); // DEBUG
		return false;
	}
	KvSetString(queries, "data", "q");
	KvSetString(queries, "type", "string");
	KvSetString(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddQueryNum(Handle:queries, String:key[], value, client) {
	if(!KvJumpToKey(queries, key, true)) {
		PrintToConsole(client, "Adding data %d for %s failed!", value, key); // DEBUG
		return false;
	}
	KvSetString(queries, "data", "q");
	KvSetString(queries, "type", "int");
	KvSetNum(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddParamString(Handle:queries, String:key[], String:value[], client) {
	if(!KvJumpToKey(queries, key, true)) {
		PrintToConsole(client, "Adding data '%s' for %s failed!", value, key); // DEBUG
		return false;
	}
	KvSetString(queries, "data", "p");
	KvSetString(queries, "type", "string");
	KvSetString(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddParamNum(Handle:queries, String:key[], value, client) {
	if(!KvJumpToKey(queries, key, true)) {
		PrintToConsole(client, "Adding data %d for %s failed!", value, key); // DEBUG
		return false;
	}
	KvSetString(queries, "data", "p");
	KvSetString(queries, "type", "int");
	KvSetNum(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddCommand(Handle:queries, String:key[], client) {
	if(!KvJumpToKey(queries, key, true)) {
		PrintToConsole(client, "Adding data for %s failed!", key); // DEBUG
		return false;
	}
	KvSetString(queries, "data", "c");
	KvSetString(queries, "type", "null");
	KvGoBack(queries);
	return true;
}



GetQueryGroups(Handle:args) {
	new query_groups;

	if(KvJumpToKey(args, "groups")) {
		query_groups = KvGetNum(args, "entry");
		KvGoBack(args);
		if(query_groups > query_groups_max) {
			query_groups = query_groups_max;
		}
	} else {
		query_groups = query_groups_max;
	}

	return query_groups;
}



CopyLastQuery(const client, Handle:source, Handle:destination, const String:item[], remove_search) {
	//PrintToConsole(client, "In CopyLastQuery function."); // DEBUG
	if(strlen(item) > 0) {
		KvRewind(source);
	}
	if (KvJumpToKey(source, "query")) {
		KvCopySubkeys(source, destination);
		KvGoBack(source);

		if(remove_search == 1) {
			new String:remove_items[][] = {"search", "groups", "next"};
			for(new i = 0; i < sizeof(remove_items); i++) {
				if(KvJumpToKey(destination, remove_items[i])) {
					KvDeleteThis(destination);
				//PrintToConsole(client, "Deleted 'search' from queries."); // DEBUG
					KvRewind(destination);
				}
			}
		} else if (remove_search == 2) {
			// PrintToConsole(client, "Deleting previous search queries..."); // DEBUG
			decl String:key_data[2];
			// decl String:key_name[12]; // DEBUG
			new bool:loop_again = true;
			if(KvGotoFirstSubKey(destination)) {
				while(loop_again) {
					KvGetString(destination, "data", key_data, sizeof(key_data));
					// KvGetSectionName(destination, key_name, sizeof(key_name)); // DEBUG
					if(StrEqual(key_data, "q")) {
						// PrintToConsole(client, "Deleting query %s.", key_name); // DEBUG
						if(KvDeleteThis(destination) == -1) {
							loop_again = false;
						}
					} else {
						// PrintToConsole(client, "Keeping query %s.", key_name); // DEBUG
						if(!KvGotoNextKey(destination)) {
							KvGoBack(destination);
							loop_again = false;
						}
					}
				}
			}
		}
	} else {
		PrintToConsole(client, "Jukebox: Failed to retrieve previous query arguments."); // DEBUG
		return false;
	}
	KvRewind(source);
	if(strlen(item) > 0) {
		if(!KvJumpToKey(source, item)) {
			PrintToConsole(client, "Jukebox: Failed to return to item #%s.", item); // DEBUG
			return false;
		}
	}

	return true;
}



MusicMenuResultParse(client, String:item[]) {

	// PrintToConsole(client, "Jukebox: Entered menu data extraction function 'MusicMenuResultParse', item = %s", item); // DEBUG
	
	// decl String:filepath[filepath_length];
	// FormatEx(filepath, sizeof(filepath), "%s%s%d.txt", result_folder, result_filename_prefix, client);
	
	new Handle:result = INVALID_HANDLE;
	new Handle:result_queries = CreateKeyValues("Queries");
	new bool:playback = false;

	result = GetResults(client);
	if(result == INVALID_HANDLE) {
		// PrintToConsole(client, "Jukebox: KeyValues file failed to open!  Path = %s", filepath); // DEBUG
		// CloseHandle(result);
		CloseHandle2(result_queries);
		return false;
	}

	new String:inst_list[][] = {"rand", "rana", "all"};
	new bool:inst_test = false;
	new inst_count = sizeof(inst_list);
	for(new i = 0; i < inst_count; i++) {
		if(StrEqual(item, inst_list[i])) {
			inst_test = true;
			break;
		}
	}
	if(inst_test) {
		if(StrEqual(item, "rand")) {
			CopyLastQuery(client, result, result_queries, "", 0);
			AddCommand(result_queries, "random", client);
			AddParamNum(result_queries, "limit", 1, client);
		} else if(StrEqual(item, "rana")) {
			CopyLastQuery(client, result, result_queries, "", 0);
			AddCommand(result_queries, "random", client);
		} else {
			CopyLastQuery(client, result, result_queries, "", 0);
		}
		playback = true;
		// PrintToConsole(client, "Jukebox: Playback instruction submitted: %s", item); // DEBUG
	} else {
		// PrintToConsole(client, "Jukebox: Seeking menu data for item #%s", item); // DEBUG
		KvRewind(result);
		if(!KvJumpToKey(result, item)) {
			// PrintToConsole(client, "Jukebox: Failed to retrieve data for selected menu item #%s.", item); // DEBUG
			CloseHandle2(result);
			CloseHandle2(result_queries);
			return false;
		}
		decl String:type[16];
		KvGetString(result, "type", type, sizeof(type));
		// PrintToConsole(client, "Jukebox: Read type: %s", type); // DEBUG
		if(StrEqual(type, "next")) {
			new start = 0;
			CopyLastQuery(client, result, result_queries, item, 0);
			if(KvJumpToKey(result_queries, "start")) {
				start = KvGetNum(result_queries, "entry");
				KvGoBack(result_queries);
			}
			start += SEARCH_MAX;
			AddParamNum(result_queries, "start", start, client);
		} else if (StrEqual(type, "title")) {
			new id = KvGetNum(result, "id");
			CopyLastQuery(client, result, result_queries, item, 2);
			AddQueryNum(result_queries, "id", id, client);
			playback = true;
		} else if (StrEqual(type, "album")) {
			decl String:album[album_length];
			CopyLastQuery(client, result, result_queries, item, 1);
			KvGetString(result, "album", album, album_length);
			AddQueryString(result_queries, "album", album, client);
			AddParamNum(result_queries, "lev", 3, client);
		} else if (StrEqual(type, "artist")) {
			decl String:artist[artist_length];
			CopyLastQuery(client, result, result_queries, item, 1);
			KvGetString(result, "artist", artist, artist_length);
			AddQueryString(result_queries, "artist", artist, client);
			AddParamNum(result_queries, "lev", 2, client);
		} else if (StrEqual(type, "genre")) {
			decl String:genre[artist_length];
			CopyLastQuery(client, result, result_queries, item, 1);
			KvGetString(result, "genre", genre, artist_length);
			AddQueryString(result_queries, "genre", genre, client);
			AddParamNum(result_queries, "lev", 1, client);
		} else {
			// PrintToConsole(client, "Jukebox: Error, failed to find menu item type '%s'!", type); // DEBUG
			CloseHandle2(result);
			CloseHandle2(result_queries);
			return false;
		}
	}
	CloseHandle2(result);

	KvRewind(result_queries);
	if(playback) {
		// PrintToConsole(client, "Jukebox: Attempting to play selection."); // DEBUG
		PlayMusic(client, result_queries);
		CloseHandle2(result_queries);
	} else {
		// PrintToConsole(client, "Jukebox: Attempting to display sub-menu."); // DEBUG
		new Handle:menu = CreateMenu(MusicMenuHandler);
		// PrintToConsole(client, "Jukebox: New menu handle created."); // DEBUG
		if(!MakeSearchMenu(client, result_queries, menu)) {
			// PrintToConsole(client, "Jukebox: Failed to create sub-menu."); // DEBUG
			CloseHandle2(result_queries);
			return false;
		}
		// PrintToConsole(client, "Jukebox: Menu data creation complete."); // DEBUG
		CloseHandle2(result_queries);
		DisplayMenu(menu, client, menu_maxtime);
	}

	return true;
}



public MusicMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	#define info_length 16
	// PrintToConsole(param1, "Jukebox: Menu is being handled."); // DEBUG

	if (action == MenuAction_Select) {
		new String:info[info_length];

		if(GetMenuItem(menu, param2, info, info_length)) {
			// PrintToConsole(param1, "Jukebox: Menu selection received: %s", info); // DEBUG
			MusicMenuResultParse(param1, info);
		} else {
			// PrintToConsole(param1, "Jukebox: Data extraction error following menu selection has occured."); // DEBUG
			return false;
		}
	} else if (action == MenuAction_Cancel) {
		PrintToServer("Client %d's menu was cancelled.  Reason; %d", param1, param2);
		// PrintToConsole(param1, "Client %d's menu was cancelled.  Reason; %d", param1, param2); // DEBUG
	} else if (action == MenuAction_End) {
		RemoveResults(param1);
		CloseHandle2(menu);
		// PrintToConsole(param1, "Jukebox: Menu ended, data has been cleared."); // DEBUG
	}

	return true;
}



KvSQL(String:query_out[], const maxlength, const Handle:args) {
	//PrintToConsole(client, "Jukebox: Entered function KvSQL."); // DEBUG

	// #define query_order_length 64
	// #define query_type_length 8

	new bool:multiple = false;
	// new bool:query_order_defined = false;
	// new bool:playlist_test = false;
	new query_value;
	new query_start;
	new query_level;
	new query_limit;
	new query_groups;

	// new String:query_types[][] = {"genre", "artist", "album", "title", "id", "category", "mood"};
	new String:query_types[][] = {"genre", "artist", "album", "title"};

	// decl String:query_instruction[query_instruction_length];
	// decl String:query_group[query_group_length];
	decl String:query_implode[maxlength];
	decl String:query_order[36];

	// Pull the query level
	if(KvJumpToKey(args, "start")) {
		query_start = KvGetNum(args, "entry");
		KvGoBack(args);
	} else {
		query_start = 0;
	}
	if(KvJumpToKey(args, "lev")) {
		query_level = KvGetNum(args, "entry");
		KvGoBack(args);
		//KvDeleteKey(args, "lev");
	} else {
		query_level = 0;
	}

	// Pull the query group
	query_groups = GetQueryGroups(args);

	/*
	// Set special "playlist" settings if this result set is going to be played back
	if(KvJumpToKey(args, "playlist")) {
		KvGoBack(args);
		playlist_test = true;
	}
	*/

	//PrintToConsole(client, "Jukebox: Beinning LIMIT clause extraction."); // DEBUG

	// Prepare LIMIT clause
	if(KvJumpToKey(args, "limit")) {
		query_limit = KvGetNum(args, "entry");
		//PrintToConsole(client, "Custom limit '%d' is assigned.", query_limit); // DEBUG
		KvGoBack(args);
	//KvDeleteKey(args, "limit");
	} else {
		// query_instruction[0] = '\0';
		query_limit = SEARCH_MAX;
	}

	// Look for a special ORDER case
	if(KvJumpToKey(args, "order")) {
		KvGetString(args, "entry", query_order, sizeof(query_order));
		KvGoBack(args);
		//KvDeleteKey(args, "order");
	} else if(KvJumpToKey(args, "random")) {
		strcopy(query_order, sizeof(query_order), "RAND()");
		KvGoBack(args);
	} else {
		strcopy(query_order, sizeof(query_order), "match_type, subsort, match_value");
	}

	//PrintToConsole(client, "Jukebox: Beginning query-building loop."); // DEBUG

	new query_part_length = maxlength/(query_groups - query_level);
	decl String:query_select_array[query_groups - query_level][query_part_length];
	decl String:query_where[query_part_length];
	query_where[0] = '\0';

	// Build the WHERE clause
	if(KvGotoFirstSubKey(args)) {
		decl String:query_string[256];
		decl String:query_data[4];
		decl String:query_type[8];
		decl String:name[16];
		//PrintToConsole(client, "Entered WHERE loop."); // DEBUG

		do {
			KvGetString(args, "data", query_data, sizeof(query_data));
			//PrintToConsole(client, "Pulled data type '%s'", query_data); // DEBUG
			if(StrEqual(query_data, "q")) {
				if(!KvGetSectionName(args, name, sizeof(name))) {
					return false;
				}
				if(MultipleTest(multiple)) {
					Format(query_where, query_part_length, "%s AND ", query_where);
				} else {
					strcopy(query_where, query_part_length, " WHERE ");
				}
				if(StrEqual(name, "search")) { // Special case for the "search" command
					KvGetString(args, "entry", query_string, sizeof(query_string));
					ReplaceString(query_string, sizeof(query_string), " ", "%%");
					Format(query_where, query_part_length, "%sgroup_replace_target LIKE \"%%%s%%\"", query_where, query_string);
				} else { // Normal case for all other commands
					KvGetString(args, "type", query_type, query_type_length);
					if(StrEqual(query_type, "string")) {
						KvGetString(args, "entry", query_string, sizeof(query_string));
						Format(query_where, query_where_length, "%s%s = \"%s\"", query_where, name, query_string);
					} else if(StrEqual(query_type, "int")) {
						query_value = KvGetNum(args, "entry");
						Format(query_where, query_where_length, "%s%s = %d", query_where, name, query_value);
					} else {
						return false;
					}
				}
			}
		} while(KvGotoNextKey(args));
		KvGoBack(args);
	}
	decl String:select_list[(sizeof(query_types) + 2) * (sizeof(query_types[]) + 11)];
	decl String:select_list_array[sizeof(query_types) + 2][sizeof(query_types[]) + 10];
	for (new i = query_level; i < query_groups; i++) {
		for(new j = 0; j < sizeof(query_types); j++) {
			if(i == sizeof(query_types) - 1 || j == i) {
				strcopy(select_list_array[j], sizeof(select_list_array[]), query_types[j]);
			} else {
				Format(select_list_array[j], sizeof(select_list_array[]), "NULL AS %s", query_types[j]);
			}
		}

		/*
		for(new j = 0; j <= i; j++) {
			strcopy(select_list_array[j], sizeof(select_list_array[]), query_types[j]);
		}
		for(new j = i + 1; j < sizeof(query_types); j++) {
			Format(select_list_array[j], sizeof(select_list_array[]), "NULL AS %s", query_types[j]);
		}
		*/

		if (i == sizeof(query_types) - 1) {
			strcopy(select_list_array[sizeof(query_types)], sizeof(select_list_array[]), "id");
			// if () // Crap... what did I start this for?  PICK IT UP
		} else {
			strcopy(select_list_array[sizeof(query_types)], sizeof(select_list_array[]), "NULL AS id");
		}
		if(i == sizeof(query_types) - 1 && query_level == sizeof(query_types) - 1) {
			strcopy(select_list_array[sizeof(query_types) + 1], sizeof(select_list_array[]), "track AS subsort");
		} else {
			strcopy(select_list_array[sizeof(query_types) + 1], sizeof(select_list_array[]), "NULL AS subsort");
		}
		ImplodeStrings(select_list_array, sizeof(select_list_array), ", ", select_list, sizeof(select_list));
		FormatEx(query_select_array[i - query_level], query_part_length, "SELECT DISTINCT %d AS match_type, %s AS match_value, %s FROM %s%s", i, query_types[i], select_list, db_tracks, query_where);
		ReplaceString(query_select_array[i - query_level], query_part_length, "group_replace_target", query_types[i]);
	}

	ImplodeStrings(query_select_array, query_groups - query_level, ") UNION (", query_implode, maxlength);

	// Write MySQL string
	FormatEx(query_out, maxlength, "(%s) ORDER BY %s LIMIT %d,%d", query_implode, query_order, query_start, query_limit);

	return true;
}

// query: (SELECT DISTINCT 4 AS match_type, title AS match_value, NULL AS genre, NULL AS artist, NULL AS album, id FROM audio_tracks) ORDER BY title LIMIT 0,100



MusicDatabaseSearch(client, String:query[], Handle:arguments, Handle:kv_menu) {
	//PrintToConsole(client, "Jukebox: Entered function MusicDatabaseSearch."); // DEBUG
	#define count_string_length 4

	// Run MySQL queries
	decl String:sql_string[sql_string_length];
	new sql_int;
	// new query_groups = GetQueryGroups(arguments);
	//PrintToConsole(client, "Query Groups = %d", query_groups); // DEBUG
	new Handle:result = INVALID_HANDLE;
	// new bool:playlist_test = false;

	result = SQL_Query(music_db, query);
	// SQL_UnlockDatabase(music_db);
	if (result == INVALID_HANDLE) {
		SQL_GetError(music_db, sql_string, sql_string_length);
		PrintToServer("Jukebox: MySQL query failed, (Error: %s)", sql_string);
		PrintToConsole(client, "Jukebox: MySQL query failed, (Error: %s)", sql_string);
		CloseHandle2(result);
		return false;
	}

	//PrintToConsole(client, "Jukebox: Progress check - MySQL queries complete."); // DEBUG

	// PROCESS RESULTS
	//kv_menu = CreateKeyValues("Music Search Results");
	new match_type_column, match_type;
	new id_column;
	new entry_count;
	new bool:seek_more = false;
	//new group_count;
	decl String:entry_count_string[count_string_length];
	// new String:query_types[][] = {"genre", "artist", "album", "title", "id", "category", "mood"};
	new String:query_types[][] = {"genre", "artist", "album", "title"};

	/*
	// Set special "playlist" settings if this result set is going to be played back
	if(KvJumpToKey(arguments, "playlist")) {
		KvGoBack(arguments);
		playlist_test = true;
	}
	*/

	// Store old queries
	KvJumpToKey(kv_menu, "query", true);
	KvRewind(arguments);
	KvCopySubkeys(arguments, kv_menu);
	KvGoBack(kv_menu);
	//PrintToConsole(client, "Jukebox: Progress check - query args stored to KV."); // DEBUG

	entry_count = 0;


	//PrintToConsole(client, "In query loop %d...", i); // DEBUG
	new field_ids[sizeof(query_types)];
	for (new j = 0; j < sizeof(query_types); j++) {
		//PrintToConsole(client, "  Building field IDs, loop %d...", j); // DEBUG
		if(!SQL_FieldNameToNum(result, query_types[j], field_ids[j])) {
			//PrintToConsole(client, "Jukebox: Failed to find MySQL field ID for %s during loop %d", query_types[j], i); // DEBUG
			field_ids[j] = -1;
		//} else {
			//PrintToConsole(client, "Jukebox: Field ID for %s during loop %d = %d", query_types[j], i, field_ids[j]); // DEBUG
		}
		SQL_FieldNameToNum(result, "id", id_column);
		SQL_FieldNameToNum(result, "match_type", match_type_column);
	}
	//PrintToConsole(client, "Beginning result loop for query %d...", i); // DEBUG
	while (SQL_FetchRow(result)) {
		//PrintToConsole(client, "In result loop %d", i); // DEBUG
		IntToString(++entry_count, entry_count_string, count_string_length);
		KvJumpToKey(kv_menu, entry_count_string, true);
		//PrintToConsole(client, "Progress check 10"); // DEBUG
		match_type = SQL_FetchInt(result, match_type_column);
		KvSetString(kv_menu, "type", query_types[match_type]);
		if(match_type == sizeof(query_types)-1) {
			sql_int = SQL_FetchInt(result, id_column);
			KvSetNum(kv_menu, "id", sql_int);
			//PrintToConsole(client, "Jukebox: Search result #%d entered, id = '%d'.", entry_count, sql_int); // DEBUG
			//group_count++;
		}
		/*
		if(playlist_test) { // Clean this up!
			if(SQL_FieldNameToNum(result[i], "playtime", sql_int)) {
				sql_int = SQL_FetchInt(result[i], sql_int);
				KvSetNum(kv_menu, "playtime", sql_int);
			}
		}
		*/
		//PrintToConsole(client, "Progress check 20"); // DEBUG
		for(new j = 0; j <= match_type; j++) {
			//PrintToConsole(client, "In loop, j = %d", j); // DEBUG
			if(field_ids[j] >= 0 &&	SQL_FetchString(result, field_ids[j], sql_string, sql_string_length)) {
				KvSetString(kv_menu, query_types[j], sql_string);
				//PrintToConsole(client, "Jukebox: Search result #%d entered, %s = '%s'.", entry_count, query_types[j], sql_string); // DEBUG
			}
		}
		KvGoBack(kv_menu);
	}
	if(entry_count >= SEARCH_MAX) {
		seek_more = true;
	}
	CloseHandle2(result);


	if(seek_more) {
		IntToString(++entry_count, entry_count_string, count_string_length);
		KvJumpToKey(kv_menu, entry_count_string, true);
		KvSetString(kv_menu, "type", "next");
		KvGoBack(kv_menu);
	}
	//PrintToConsole(client, "Jukebox: Progress check - search results stored to KV."); // DEBUG
	KvRewind(kv_menu);

	return entry_count;
}



KvToMusicMenu(client, Handle:kv_menu, Handle:menu) {
	//menu = CreateMenu(MusicMenuHandler);
	SetMenuTitle(menu, "Jukebox - Make a Selection");

	// Special functions
	new String:inst_types[][][] = {{"rand", "Play Random Track"}, {"all", "Play All Tracks"}, {"rana", "Play All Tracks in Random Order"}};
	new inst_types_length = sizeof(inst_types);
	for(new i = 0; i < inst_types_length; i++) {
		//PrintToConsole(client, "Jukebox: Add menu custom functions, loop %d", i); // DEBUG
		AddMenuItem(menu, inst_types[i][0], inst_types[i][1]);
	}

	decl String:keyname[16];
	decl String:type[16];
	decl String:title[title_length];
	decl String:album[album_length];
	decl String:artist[artist_length];
	decl String:description[128];

	KvRewind(kv_menu);
	if(!KvJumpToKey(kv_menu, "1")) {
		//PrintToConsole(client, "Jukebox: No results!"); // DEBUG
		PrintToChat(client, "Jukebox: No results!");
		return false;
	}
	do {
		KvGetSectionName(kv_menu, keyname, sizeof(keyname));
		KvGetString(kv_menu, "type", type, sizeof(type));
		if (StrEqual(type, "title")) {
			KvGetString(kv_menu, "title", title, title_length);
			KvGetString(kv_menu, "artist", artist, artist_length);
			//KvGetString(kv_menu, "album", album, album_length);
			if(strlen(artist) > 0) {
				//if(strlen(album) > 0) {
					//FormatEx(description, description_length, "\"%s\" by %s, from %s", title, artist, album);
				//} else {
					FormatEx(description, sizeof(description), "\"%s\" by %s", title, artist);
				//}
			//} else if (strlen(album) > 0) {
			// FormatEx(description, sizeof(description), "\"%s\" from %s", title, album);
			} else {
				FormatEx(description, sizeof(description), "\"%s\"", title);
			}
		} else if (StrEqual(type, "artist")) {
			KvGetString(kv_menu, "artist", artist, artist_length);
			FormatEx(description, sizeof(description), "Artist: %s", artist);
		} else if (StrEqual(type, "album")) {
			KvGetString(kv_menu, "album", album, album_length);
			FormatEx(description, sizeof(description), "Album: %s", album);
		} else if (StrEqual(type, "genre")) {
			KvGetString(kv_menu, "genre", album, album_length);
			FormatEx(description, sizeof(description), "Genre: %s", album);
		} else if (StrEqual(type, "next")) {
			strcopy(description, sizeof(description), "Continue browsing...");
		} else {
			PrintToConsole(client, "Jukebox: Error adding menu item!");
			return false;
		}
		AddMenuItem(menu, keyname, description);
		//PrintToConsole(client, "Jukebox: Add search result to menu, #%s: '%s'", keyname, description); // DEBUG
	} while (KvGotoNextKey(kv_menu));
	//PrintToConsole(client, "Jukebox: Progress check - Menu build complete."); // DEBUG

	return true;
}



ParseCommandLine(client, String:args_line[], Handle:arguments) {
	#define query_default "search"
	new start_index = 0;
	new bool:multiple = false;
	new bool:query_test = false;
	new index_temp = 0;
	decl String:query_id[query_cmd_length];
	decl String:query_string[256];
	decl String:arg_name[12];
	decl String:arg_type[4];
	decl String:admin_check[2];
	new bool:admin_block;
	new AdminId:admin_id = INVALID_ADMIN_ID;
	new param_num;

	/*
	new String:query_names[][][] = {{"search", "se", "s"}, {"title", "ti", "t"}, {"album", "alb", "al"}, {"artist", "art", "ar"}, {"genre", "ge", "g"}};
	new String:params[][][] = {{"volume", "vol"}};
	new String:commands[][][] = {{"all", ""}, {"loud", "strong"}, {"soft", "quiet"}};
	new query_names_count = sizeof(query_names);
	new query_subnames_count = sizeof(query_names[]);
	new param_names_count = sizeof(param_names);
	new param_subnames_count = sizeof(param_names[]);
	new command_names_count = sizeof(command_names);
	new command_subnames_count = sizeof(command_names[]);
	*/

	if (args_line[0] == '"') {
		start_index = 1;
		new args_length = strlen(args_line);
		if (args_line[args_length - 1] == '"') {
			args_line[args_length - 1] = '\0';
		}
	}

	KvRewind(arguments);
	KvRewind(input_types);
	//PrintToConsole(client, "200 URL args line: %s", args_line[start_index]); // DEBUG
	//PrintToConsole(client, "Before loop, start_index = %d", start_index); // DEBUG
	while (start_index >= 0) {
		admin_block = false;
		//PrintToConsole(client, "Remaining argument string: %s", args_line[start_index]); // DEBUG
		TrimString(args_line[start_index]);

		if (!multiple && StrContains(args_line[start_index], cmd_char) != 0) {
			strcopy(arg_name, sizeof(arg_name), query_default);
			strcopy(arg_type, sizeof(arg_type), "q");
			MultipleTest(multiple);
		} else {
			if (!MultipleTest(multiple)) {
				//PrintToConsole(client, "First command increment."); // DEBUG
				start_index++;
			}
			index_temp = SplitString(args_line[start_index], break_char, query_id, query_cmd_length);
			if(index_temp < 0) {
				strcopy(query_id, query_cmd_length, args_line[start_index]);
				start_index = -1;
				query_string[0] = '\0';
			} else {
				start_index += index_temp;
			}
			if(!KvJumpToKey(input_types, query_id)) {
				if (client != 0) {
					PrintToChat(client, "Jukebox: '%s' is an invalid command, halting.", query_id);
				}
				PrintToConsole(client, "Jukebox: '%s' is an invalid command.", query_id);
				return -1;
			}
				/*
				for (new i = 0; i < query_names_count; i++ ) {
					if (!query_test) {
						for (new j = 0; j < query_subnames_count; j++) {
							if (!query_test && StrEqual(query_id, query_names[i][j])) {
								strcopy(query_id, query_cmd_length, query_names[i][0]);
								query_test = true;
							}
						}
					}
				}
				*/
			KvGetString(input_types, "name", arg_name, sizeof(arg_name));
			KvGetString(input_types, "admin", admin_check, sizeof(admin_check));

			if(!StrEqual(admin_check, "")) {
				/*
				if(!(GetUserFlagBits(client) & ADMFLAG_CHAT)) {
					admin_block = true;
					PrintToChat(client, "Jukebox: Command '%s' is a reserved command.  It has been ignored.", arg_name);
				}
				*/
				// Alternate method
				if(admin_id == INVALID_ADMIN_ID) {
					admin_id = GetUserAdmin(client);
				}
				if(admin_id == INVALID_ADMIN_ID || !GetAdminFlag(admin_id, Admin_Chat)) {
					admin_block = true;
					PrintToChat(client, "Jukebox: Command '%s' is a reserved command.  It has been ignored.", arg_name);
				}
			}

			if(!admin_block) {
				KvGetString(input_types, "type", arg_type, sizeof(arg_type));

				if (StrEqual(arg_name, "") && StrEqual(arg_type, "")) {
					PrintToConsole(client, "Jukebox: Error retrieving operation instructions for input argument '%s'.", query_id);
					return -1;
				}
				//PrintToConsole(client, "Using defined query type."); // DEBUG
			}
			KvRewind(input_types);
		}
		if(start_index >= 0 && index_temp >= 0) {
			index_temp = SplitString(args_line[start_index], cmd_char, query_string, sizeof(query_string));
			if(index_temp < 0) {
				strcopy(query_string, sizeof(query_string), args_line[start_index]);
				start_index = -1;
			} else {
				start_index += index_temp;
			}
		}

		if(!admin_block) {
			TrimString(query_string);
			//PrintToConsole(client, "Input type '%s' for value '%s', index_temp = %d", arg_name, query_string, index_temp); // DEBUG
			if(!KvJumpToKey(arguments, arg_name, true)) {
				return -1;
			}
			if(StrEqual(arg_type, "q")) {
				KvSetString(arguments, "type", "string");
				KvSetString(arguments, "entry", query_string);
				query_test = true;
			} else if (StrEqual(arg_type, "p")) {
				param_num = StringToInt(query_string);
				if(param_num == 0) {
					if(client != 0) {
						PrintToChat(client, "Jukebox: Input '%s' is not valid for parameter '%s', halting.", query_string, arg_name);
					}
					PrintToConsole(client, "Jukebox: Input '%s' is not valid for parameter '%s', halting.", query_string, arg_name);
					return -1;
				}
				KvSetString(arguments, "type", "int");
				KvSetNum(arguments, "entry", param_num);
			} else if (StrEqual(arg_type, "c")) {
				KvSetString(arguments, "type", "null");
			}
			KvSetString(arguments, "data", arg_type);
			KvGoBack(arguments);
		}
	}
	KvRewind(arguments);
	if(query_test) {
		return 1;
	} else {
		return 0;
	}
}



LoadMOTDPanelHidden(client, const String:title[], const  String:msg[], type) {
	decl String:num[3];
	new Handle:Kv = CreateKeyValues("data");
	IntToString(type, num, sizeof(num));

	KvSetString(Kv, "title", title);
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", msg);

	// PrintToConsole(client, "Displaying VGUI panel."); // DEBUG

	ShowVGUIPanel(client, "info", Kv, false);
	
	// PrintToConsole(client, "Panel display complete."); // DEBUG
	
	CloseHandle(Kv);
}



TopMenu (client, Handle:args) {
	// Find last update to library for user
	new Handle:top_menu = INVALID_HANDLE;
	new last_update = GetTime() - newest_track_date;
	decl String:newest_title[64];
	
	if(last_update < 3600) { // An hour ago
		FormatEx(newest_title, sizeof(newest_title), "%d min ago", last_update/60);
	} else if (last_update < 86400) { // A day ago
		FormatEx(newest_title, sizeof(newest_title), "%d hr ago", last_update/3600);
	} else if (last_update < 518400) { // 6 days ago
		FormatTime(newest_title, sizeof(newest_title), "%A", newest_track_date);
	} else if (last_update < 28908000) { // 11 months ago
		FormatTime(newest_title, sizeof(newest_title), "%b %d", newest_track_date);
	} else {
		FormatTime(newest_title, sizeof(newest_title), "%b $d, %Y", newest_track_date);
	}
	Format(newest_title, sizeof(newest_title), "Newest Tracks (Updated %s)", newest_title);

	new String:top_menu_items[][][] = {{"browse", "Browse Library"}, {"new", "newest_title"}, {"pop", "Most Popular"}, {"rand", "1 Random Song"}, {"rand10", "10 Random Songs"}, {"set", "Settings"}, {"help", "Help"}};
	// new String:menu_items[][][] = {{"new", "Newest"}, {"pop", "Most Popular"}, {"browse_ar", "Browse By Artist"}, {"browse_al", "Browse By Album"}, {"browse_ge", "Browse By Genre"}, {"browse_ti", "Browse By Title"}, {"rand", "1 Random Song"}, {"rand_ten", "10 Random Songs"}};

	top_menu = CreateMenu(TopMenuHandler);
	SetMenuTitle(top_menu, "Jukebox - Please make a selection.");
	for(new i = 0; i < sizeof(top_menu_items); i++) {
		if(StrEqual(top_menu_items[i][1], "newest_title")) {
			AddMenuItem(top_menu, top_menu_items[i][0], newest_title);
		} else {
			AddMenuItem(top_menu, top_menu_items[i][0], top_menu_items[i][1]);
		}
	}

	// Save arguments for browse menu
	
	/*
	decl String:filepath[filepath_length];
	FormatEx(filepath, sizeof(filepath), "%s%s%d.txt", result_folder, result_filename_prefix, client);
	KeyValuesToFile(args, filepath);
	*/
	
	SaveResults(client, args);

	DisplayMenu(top_menu, client, menu_maxtime);

	return true;
}



public TopMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		new String:item[8];
		new bool:send_query = false;
		new bool:playback = false;
		new Handle:args = INVALID_HANDLE;

		// Pull arguments from file
		
		/*
		args = CreateKeyValues("Queries");
		decl String:filepath[filepath_length];
		FormatEx(filepath, sizeof(filepath), "%s%s%d.txt", result_folder, result_filename_prefix, client);
		FileToKeyValues(args, filepath);
		*/
		
		args = GetResults(client);

		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			PrintToConsole(client, "Failed to retrieve menu position '%d' from handler.", position);
			CloseHandle2(args);
			return false;
		}
		if (StrEqual(item, "browse")) {
			BrowseMenu(client);
		} else if (StrEqual(item, "new")) {
			//args = CreateKeyValues("Queries");
			AddParamNum(args, "lev", query_groups_max-1, client);
			AddParamNum(args, "limit", 20, client);
			AddParamString(args, "order", "added DESC", client);
			send_query = true;
		} else if (StrEqual(item, "pop")) {
			//args = CreateKeyValues("Queries");
			AddParamNum(args, "lev", query_groups_max-1, client);
			AddParamNum(args, "limit", 20, client);
			AddParamString(args, "order", "popularity DESC", client);
			send_query = true;
		} else if (StrEqual(item, "rand")) {
			//args = CreateKeyValues("Queries");
			AddParamNum(args, "limit", 1, client);
			AddCommand(args, "random", client);
			playback = true;
		} else if (StrEqual(item, "rand10")) {
			//args = CreateKeyValues("Queries");
			AddParamNum(args, "limit", 10, client);
			AddCommand(args, "random", client);
			playback = true;
		} else if (StrEqual(item, "set")) {
			SettingsMenu(client);
		} else if (StrEqual(item, "help")) {
			HelpMenu(client);
		} else {
			PrintToConsole(client, "Failed to find instructions for menu item '%s' from handler.", item);
			CloseHandle2(args);
			return false;
		}

		if(send_query) {
			new Handle:browse_menu = CreateMenu(MusicMenuHandler);
			if(!MakeSearchMenu(client, args, browse_menu)) {
				// ERROR
				CloseHandle2(args);
				CloseHandle2(browse_menu);
				return false;
			}
			DisplayMenu(browse_menu, client, menu_maxtime);
		} else if(playback) {
			// PrintToConsole(client, "Jukebox: Calling PlayMusic..."); // DEBUG
			PlayMusic(client, args);
		}
		CloseHandle2(args);

	} else if(action == MenuAction_Cancel) {
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



PlayMusic(client, Handle:args) {
	new playall = 0, volume_shift = 0;
	new entry_count;
	decl String:artist[artist_length];
	decl String:album[album_length];
	decl String:title[title_length];
	decl String:query[2048];
	decl String:error[256];
	new Handle:results = INVALID_HANDLE;
	new stream_id;

	// PrintToConsole(client, "Started PlayMusic"); // DEBUG

	AddParamNum(args, "lev", query_groups_max-1, client);
	// AddCommand(args, "playlist", client);


	// PrintToConsole(client, "Jukebox: Completed music database search."); // DEBUG

	new String:creator_steam[25], String:creator_name[username_length];
	// new String:stream_key[11];

	if(!GetClientAuthString(client, creator_steam, sizeof(creator_steam))) {
		creator_steam[0] = '\0';
	}
	if(!GetClientName(client, creator_name, sizeof(creator_name))) {
		strcopy(creator_name, sizeof(creator_name), "unknown user");
	}

	// PrintToConsole(client, "Echo 400"); // DEBUG

	KvRewind(args);

	/*
	if(!KvJumpToKey(args, "query")) {
		// CloseHandle(playlist);
		PrintToConsole(client, "Failed to retrieve query parameters, aborting...");
		return false;
	}
	*/

	// PrintToConsole(client, "Echo 500"); // DEBUG

	if (KvJumpToKey(args, "force")) {
		KvGoBack(args);
		playall = 2;
	}	else if(KvJumpToKey(args, "all")) {
		KvGoBack(args);
		playall = 1;
	}

	// PrintToConsole(client, "Echo 600"); // DEBUG

	if(KvJumpToKey(args, "loud")) {
		KvGoBack(args);
		volume_shift = GetConVarInt(cv_volume_loud);
	} else if(KvJumpToKey(args, "soft")) {
		KvGoBack(args);
		volume_shift = GetConVarInt(cv_volume_soft);
	}

	// KvRewind(playlist);

	// PrintToConsole(client, "Editing global settings."); // DEBUG

	/*
	KvRewind(streams);
	if(!KvJumpToKey(streams, "top")) {
		CloseHandle(playlist);
		PrintToConsole(client, "Jukebox: Failed to find global header.  Aborting...");
		return false;
	}
	last = KvGetNum(streams, "latest") + 1;
	IntToString(last, stream_key, sizeof(stream_key));
	KvRewind(streams);
	*/

	// PrintToConsole(client, "Creating header");

	FormatEx(query, sizeof(query), "INSERT INTO %s (creator_steam, creator_name, playall, volume_shift) VALUES ('%s', '%s', %d, %d)", db_streams, creator_steam, creator_name, playall, volume_shift);
	if(!SQL_FastQuery(music_db, query)) {
		SQL_GetError(music_db, error, sizeof(error));
		// CloseHandle(playlist);
		PrintToConsole(client, "Jukebox: Failed to create stream entry in database.  Error: \"%s\"  Query: \"%s\"", error, query);
		return false;
	}

	// PrintToConsole(client, "Recovering header ID number.");

	results = SQL_Query(music_db, "SELECT LAST_INSERT_ID()");
	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		// CloseHandle(playlist);
		PrintToConsole(client, "Jukebox: Failed to retrieve stream's ID number.  Error: \"%s\"", error);
		return false;
	}
	if(!SQL_FetchRow(results)) {
		PrintToConsole(client, "Jukebox: Failed to browse first row of last stream ID search result.");
		CloseHandle2(results);
		return false;
	}
	stream_id = SQL_FetchInt(results, 0);
	CloseHandle2(results);

	/*
	if(!KvJumpToKey(playlist, "header", true)) {
		CloseHandle(playlist);
		PrintToConsole(client, "Jukebox: Failed to create stream's header.  Aborting...");
		return false;
	}

	KvSetNum(playlist, "start_time", GetTime());
	KvSetNum(playlist, "count", entry_count);
	KvSetNum(playlist, "volume_shift", volume_shift);
	KvSetString(playlist, "creator_steam", creator_steam);
	KvSetString(playlist, "creator_name", creator_name);
	KvSetNum(playlist, "now_playing", 0);
	KvSetNum(playlist, "latest_time", 0);
	KvSetNum(playlist, "playall", playall);
	*/

	// PrintToConsole(client, "Header created.");

	// PrintToConsole(client, "Copying stream"); // DEBUG

	if(!KvSQL(query, sizeof(query), args)) {
		PrintToConsole(client, "Jukebox: Failed to build MySQL query from KeyValue data.");
		return false;
	}

	Format(query, sizeof(query), "INSERT INTO %s (stream_id, track_id) SELECT %d AS stream_id, id AS track_id FROM (%s) AS search_result", db_playlists, stream_id, query);

	// PrintToConsole(client, "Jukebox: SQL query = %s", query); // DEBUG

	// INSERT INTO jb_stream_tracks (stream_id, track_id) SELECT 3 AS stream_id, id AS track_id FROM ((SELECT DISTINCT 3 AS match_type, title AS match_value, genre, artist, album, title, id FROM audio_tracks) ORDER BY match_type, match_value LIMIT 0,1) AS search_result

	if(!SQL_FastQuery(music_db, query)) {
		SQL_GetError(music_db, error, sizeof(error));
		// CloseHandle(playlist);
		RemoveStream(stream_id);
		PrintToConsole(client, "Jukebox: Failed to copy track info to playlist.  Error: \"%s\"  Query: \"%s\"", error, query);
		return false;
	}

	// PrintToConsole(client, "Done copying stream."); // DEBUG

	// Check to make sure playlist has entries.
	FormatEx(query, sizeof(query), "SELECT COUNT(*) AS count FROM %s WHERE stream_id = %d", db_playlists, stream_id);

	// PrintToConsole(client, "Echo 100 - query = %s", query); // DEBUG

	results = SQL_Query(music_db, query);

	// PrintToConsole(client, "Echo 200"); // DEBUG

	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		// CloseHandle(playlist);
		RemoveStream(stream_id);
		PrintToConsole(client, "Jukebox: Failed to retrieve number of tracks in playlist.  Error: \"%s\"  Query: \"%s\"", error, query);
		return false;
	}
	// PrintToConsole(client, "Echo 300"); // DEBUG
	if(!SQL_FetchRow(results)) {
		PrintToConsole(client, "Jukebox: Could not browse first row of playlist tracks count search result.");
		CloseHandle2(results);
		return false;
	}
	entry_count = SQL_FetchInt(results, 0);
	CloseHandle2(results);

	// PrintToConsole(client, "Echo 400"); // DEBUG

	if(entry_count <= 0) {
		PrintToChat(client, "Jukebox: Query returned zero results.");
		RemoveStream(stream_id);
		return false;
	}

	// PrintToConsole(client, "Echo 500"); // DEBUG

	/*
	new Handle:playlist = CreateKeyValues("Music Search Results");
	entry_count = MusicDatabaseSearch(client, query, args, playlist);
	if(entry_count <= 0) {
		PrintToConsole(client, "Jukebox: Database search failed!"); // DEBUG
		CloseHandle(playlist);
		return false;
	}
	*/

	/*
	new Handle:cached_query = INVALID_HANDLE;
	FormatEx(query, sizeof(query), "INSERT INTO %s (stream_id, track_id, sequence) VALUES (%d, ?, ?)", db_playlists, last);
	cached_query = SQL_PrepareQuery(music_db, query, error, sizeof(error));
	if(cached_query == INVALID_HANDLE) {
		PrintToConsole(client, "Jukebox: Precached track-insertion query is invalid.  Error: \"%s\"  Query: \"%s\"", error, query);
		CloseHandle(playlist);
		return false;
	}

	new track_id; //, playtime;
	decl String:id_string[4];
	// KvRewind(playlist);
	for(new i = 1; i <= entry_count; i++) {
		IntToString(i, id_string, sizeof(id_string));
		if(!KvJumpToKey(playlist, id_string)) {
			PrintToConsole(client, "Jukebox: Playlist item #%d not found.", i);
			CloseHandle(playlist);
			CloseHandle(cached_query);
			return false;
		}
		track_id = KvGetNum(playlist, "id");
		KvGoBack(playlist);

		SQL_BindParamInt(cached_query, 0, track_id, false); // Track_id
		SQL_BindParamInt(cached_query, 1, i, false); // Sequence


		if(!SQL_Execute(cached_query)) {
			SQL_GetError(cached_query, error, sizeof(error));
			PrintToConsole(client, "Saving playlist item #%d failed.  Error: \"%s\"", i, error);
			CloseHandle(cached_query);
			CloseHandle(playlist);
			return false;
		}

	}
	CloseHandle(cached_query);
	*/

	FormatEx(query, sizeof(query), "SELECT tr.title, tr.album, tr.artist FROM %s AS pl LEFT JOIN %s AS tr ON tr.id = pl.track_id WHERE pl.stream_id = %d AND pl.sequence = 1", db_playlists, db_tracks, stream_id);
	results = SQL_Query(music_db, query);



	// PrintToConsole(client, "Echo 600 - query = %s", query); // DEBUG

	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		// CloseHandle(playlist);
		RemoveStream(stream_id);
		PrintToConsole(client, "Jukebox: Failed to find first track data.  Error: \"%s\"  Query: \"%s\"", error, query);
		return false;
	}

	// PrintToConsole(client, "Echo 700"); // DEBUG

	if(!SQL_FetchRow(results)) {
		RemoveStream(stream_id);
		PrintToConsole(client, "Jukebox: Failed to step into first track data's query result.  Query: %s", query); // DEBUG
		CloseHandle2(results);
		return false;
	}

	SQL_FetchString(results, 0, title, sizeof(title)); // stalls on this line
	SQL_FetchString(results, 1, album, sizeof(album));
	SQL_FetchString(results, 2, artist, sizeof(artist));
	CloseHandle2(results);

	/*
	if(!KvJumpToKey(playlist, "1")) {
		PrintToConsole(client, "Jukebox: First track not found in stream.  Aborting...");
		CloseHandle(playlist);
		return false;
	}
	PrintToConsole(client, "Getting first track info."); // DEBUG
	KvGetString(playlist, "title", title, sizeof(title));
	KvGetString(playlist, "artist", artist, sizeof(artist));
	KvGetString(playlist, "album", album, sizeof(album));
	CloseHandle(playlist);
	*/


	/*
	if(!KvJumpToKey(streams, "top")) {
		PrintToConsole(client, "Jukebox: Failed to find global header in KeyValue structure.  Aborting...");
		return false;
	}
	PrintToConsole(client, "Test 100");
	PrintToConsole(client, "Test 150 - last = %d", last);
	KvSetNum(streams, "latest", last);
	PrintToConsole(client, "Test 200");
	KvRewind(streams);
	*/

	// PrintToConsole(client, "Building announcement strings."); // DEBUG

	decl String:response_multiple_1[12], String:response_multiple_2[20];
	decl String:response_all[15], String:response_artist[artist_length+5];
	new String:response_off[] = "  Type !jboff to suspend playback.";
	new String:response_eavesdrop[] = "  Type '!eavesdrop' to listen along!";
	if(playall > 0) {
		strcopy(response_all, sizeof(response_all), " for everyone");
	} else {
		response_all[0] = '\0';
	}

	if(entry_count > 1) {
		FormatEx(response_multiple_1, sizeof(response_multiple_1), " %d songs", entry_count);
		FormatEx(response_multiple_2, sizeof(response_multiple_2), ", beginning with");
	} else {
		response_multiple_1[0] = '\0';
		response_multiple_2[0] = '\0';
	}

	if(strlen(artist)) {
		FormatEx(response_artist, sizeof(response_artist), " by %s", artist);
	} else if(strlen(album)) {
		FormatEx(response_artist, sizeof(response_artist), " of %s", album);
	} else {
		response_artist[0] = '\0';
	}

	// PrintToConsole(client, "Still building announcements..."); // DEBUG

	decl String:announce_string[70 + sizeof(response_artist) + title_length + sizeof(creator_name)];
	decl String:playtoall_string[70 + sizeof(response_artist) + title_length + sizeof(creator_name)];
	// Jukebox: CHEESUS is playing for you( 12 songs, beginning with) 'HAPPY SONG'( by Some Guy).
	FormatEx(playtoall_string, sizeof(playtoall_string), "Jukebox: %s is playing for you%s%s '%s'%s.", creator_name, response_multiple_1, response_multiple_2, title, response_artist);

	// Jukebox: CHEESUS is now listening to( 12 songs, beginning with) 'HAPPY SONG'( by Some Guy).
	FormatEx(announce_string, sizeof(announce_string), "Jukebox: %s is listening to%s%s '%s'%s.", creator_name, response_multiple_1, response_multiple_2, title, response_artist);

	stream_memberships[client] = -1*stream_id;
	// Jukebox: Playing( 12 songs)( for everyone)(, beginning with) 'HAPPY SONG'( by Some Guy).
	PrintToChat(client, "Jukebox: Playing%s%s%s '%s'%s.", response_multiple_1, response_all, response_multiple_2, title, response_artist);

	// PrintToConsole(client, "Assigning users to stream - size of stream_memberships = %d, max players = %d", sizeof(stream_memberships), num_clients); // DEBUG

	if(playall == 1) {
		new playall_target = FindOption("playall");
		// PrintToConsole(client, "Playing to all."); // DEBUG
		for(new i = 1; i <= num_clients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && client != i) {
				if((stream_memberships[i] == 0 || stream_memberships[i] == -1) && options[i][playall_target]) {
					stream_memberships[i] = -stream_id;
					PrintToChat(i, "%s%s", playtoall_string, response_off);
				} else {
					if(play_lock[i]) {
						PrintToChat(i, announce_string);
					} else {
						PrintToChat(i, "%s%s", announce_string, response_eavesdrop);
					}
				}
			}
		}
	} else if(playall == 2) {
		// PrintToConsole(client, "Forcing playback to all."); // DEBUG
		new AdminId:admin_id;
		for(new i = 1; i <= num_clients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && client != i) {
				stream_memberships[i] = -1*stream_id;
				admin_id = GetUserAdmin(client);
				if(admin_id == INVALID_ADMIN_ID || !GetAdminFlag(admin_id, Admin_Chat)) {
					play_lock[i] = true;
					PrintToChat(i, playtoall_string);
				} else {
					PrintToChat(i, "%s%s", playtoall_string, response_off);
				}
			}
		}
	} else {
		// PrintToConsole(client, "Private playback - informing others."); // DEBUG
		for(new i = 1; i <= num_clients; i++) {
			// PrintToConsole(client, "i = %d", i); // DEBUG
			if(IsClientInGame(i) && !IsFakeClient(i) && client != i) {
				// PrintToConsole(client, "i = %d - advising client %N", i, i); // DEBUG
				if(play_lock[i]) {
					PrintToChat(i, announce_string);
				} else {
					PrintToChat(i, "%s%s", announce_string, response_eavesdrop);
				}
			}
			/*
			} else {
				PrintToConsole(client, "i = %d - client not connected", i);
			}
			*/
		}
	}

	// PrintToConsole(client, "Stream subscription complete."); // DEBUG
	
	CreateTimer(0.1, NextTrack, stream_id);

	// PrintToConsole(client, "Jukebox: PlayMusic complete."); // DEBUG

	return stream_id;
}



BrowseMenu(client) {
	new Handle:browse_menu = INVALID_HANDLE;
	new String:browse_menu_items[][][] = {{"title", "Browse by Title"}, {"album", "Browse by Album or Subject"}, {"artist", "Browse by Artist"}, {"genre", "Browse by Genre"}};

	browse_menu = CreateMenu(BrowseMenuHandler);
	SetMenuTitle(browse_menu, "Jukebox - Browse");
	for(new i = 0; i < sizeof(browse_menu_items); i++) {
		AddMenuItem(browse_menu, browse_menu_items[i][0], browse_menu_items[i][1]);
	}
	DisplayMenu(browse_menu, client, menu_maxtime);

	return true;
}



public BrowseMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		new Handle:query = INVALID_HANDLE;
		
		/*
		decl String:filepath[filepath_length];
		FormatEx(filepath, sizeof(filepath), "%s%s%d.txt", result_folder, result_filename_prefix, client);
		FileToKeyValues(query, filepath);
		*/
		
		query = GetResults(client);
		
		new String:item[8];
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			PrintToConsole(client, "Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		if(StrEqual(item, "title")) {
			AddParamNum(query, "lev", query_groups_max-1, client);
			AddParamString(query, "order", "title", client);
		} else if(StrEqual(item, "artist")) {
			AddParamNum(query, "lev", 1, client);
			AddParamNum(query, "groups", 2, client);
		} else if(StrEqual(item, "album")) {
			AddParamNum(query, "lev", 2, client);
			AddParamNum(query, "groups", 3, client);
		} else if(StrEqual(item, "genre")) {
			AddParamNum(query, "groups", 1, client);
		} else {
			// BOO
		}

		new Handle:subbrowse_menu = CreateMenu(MusicMenuHandler);
		if(!MakeSearchMenu(client, query, subbrowse_menu)) {
			// ERROR
			CloseHandle2(query);
			return false;
		}
		CloseHandle2(query);
		DisplayMenu(subbrowse_menu, client, menu_maxtime);

	} else if(action == MenuAction_Cancel) {
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



SettingsMenu(client) {
	new Handle:settings_menu = INVALID_HANDLE;
	new String:settings_menu_items[][][] = {{"volume", "Change Volume ({c}%)"}, {"playall", "{t} 'Play to All' playback"}};
	new String:toggle_flag[] = "{t}";
	new String:current_flag[] = "{c}";
	new option_target;
	decl String:item_description[64];
	decl String:value_string[4];

	settings_menu = CreateMenu(SettingsMenuHandler);
	SetMenuTitle(settings_menu, "Jukebox - Settings");
	for(new i = 0; i < sizeof(settings_menu_items); i++) {
		strcopy(item_description, sizeof(item_description), settings_menu_items[i][1]);
		option_target = FindOption(settings_menu_items[i][0]);
		if(StrContains(item_description, current_flag) >= 0) {
			IntToString(options[client][option_target], value_string, sizeof(value_string));
			ReplaceString(item_description, sizeof(item_description), current_flag, value_string);
		}
		if(StrContains(item_description, toggle_flag) >= 0) {
			if(options[client][option_target]) {
				ReplaceString(item_description, sizeof(item_description), toggle_flag, "Disable");
			} else {
				ReplaceString(item_description, sizeof(item_description), toggle_flag, "Enable");
			}
		}
		AddMenuItem(settings_menu, settings_menu_items[i][0], item_description);
	}
	DisplayMenu(settings_menu, client, menu_maxtime);

	return true;
}



FindOption(String:target[]) {
	new hit = -1;
	for(new i = 0; i < sizeof(options_names); i++) {
		if(StrEqual(target, options_names[i])) {
			hit = i;
			break;
		}
	}

	return hit;
}



ToggleOption(client, String:target[]) {
	new option_target = FindOption(target);
	//PrintToConsole(client, "DEBUG: option_target = %d", option_target); // DEBUG
	if(option_target < 0) {
		PrintToConsole(client, "Jukebox: Failed to find ID number for '%s'.", target);
		return false;
	}
	if(options[client][option_target]) {
		options[client][option_target] = 0;
	} else {
		options[client][option_target] = 1;
	}

	new String:steam_id[25];
	new String:query[128];
	if (!GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		PrintToServer("Jukebox: Could not save new '%s' setting for user '%s'.", target, steam_id);
		return false;
	}
	FormatEx(query, sizeof(query), "UPDATE %s SET %s = %d WHERE steamid = '%s'", db_options, target, options[client][option_target], steam_id);
	if(SQL_FastQuery(music_db, query)) {
		PrintToServer("Jukebox: Option '%s' toggled for Steam ID '%s'.", target, steam_id);
		return true;
	} else {
		new String:query_error[256];
		SQL_GetError(music_db, query_error, sizeof(query_error));
		PrintToConsole(client, "Jukebox: Failed to toggle console option '%s'.  SQL error: '%s'.  Query: '%s'.", target, query_error, query);
		return false;
	}
}



SetOption(client, String:target[], value) {
	new option_target = FindOption(target);
	if(option_target < 0) {
		PrintToConsole(client, "Jukebox: Failed to find ID number for '%s'.", target);
		return false;
	}
	options[client][option_target] = value;

	new String:steam_id[25];
	new String:query[128];
	if (!GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		PrintToServer("Jukebox: Could not save new '%s' setting for user '%s'.", target, steam_id);
		return false;
	}
	FormatEx(query, sizeof(query), "UPDATE %s SET %s = %d WHERE steamid = '%s'", db_options, target, options[client][option_target], steam_id);
	if(SQL_FastQuery(music_db, query)) {
		PrintToServer("Jukebox: Option '%s' set to %d.", target, options[client][option_target]);
		return true;
	} else {
		new String:query_error[256];
		SQL_GetError(music_db, query_error, sizeof(query_error));
		PrintToConsole(client, "Jukebox: Failed to toggle console option '%s'.  SQL error: '%s'.  Query: '%s'.", target, query_error, query);
		return false;
	}
}



public SettingsMenuHandler(Handle:menu, MenuAction:action, client, position) {
	decl String:item[12];

	if(action == MenuAction_Select) {
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			PrintToConsole(client, "Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}

		if(StrEqual(item, "volume")) {
			// PrintToConsole(client, "DEBUG: Running VolumeMenu"); // DEBUG
			VolumeMenu(client);
		} else {
			if(!ToggleOption(client, item)) {
				PrintToConsole(client, "Failed to find instructions for menu item '%s' from handler.", item);
				return false;
			}
			SettingsMenu(client);
		}

	} else if(action == MenuAction_Cancel) {
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



HelpMenu(client) {
	if(abs(stream_memberships[client] >= 2)) {
		new Handle:help_menu = INVALID_HANDLE;
		help_menu = CreateMenu(HelpMenuHandler);
		SetMenuTitle(help_menu, "Interrupt playback and proceed to Help Guide?");
		AddMenuItem(help_menu, "1", "Proceed");
		AddMenuItem(help_menu, "0", "Cancel");
		DisplayMenu(help_menu, client, menu_maxtime);
	} else {
		ShowHelp(client);
	}
}



public HelpMenuHandler(Handle:menu, MenuAction:action, client, position) {
	new String:item[8];
	
	if(action == MenuAction_Select) {
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			PrintToConsole(client, "Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		if(StrEqual(item, "1")) {
			RemoveClient(client);
			ShowHelp(client);
		}
	} else if(action == MenuAction_Cancel) {
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}
	
	return true;
}



ShowHelp(client) {
	ShowMOTDPanel(client, "Jukebox Help", help_url, MOTDPANEL_TYPE_URL);
	return true;
}



VolumeMenu(client) {
	new volume_settings[] = {10, 20, 40, 60, 80, 100};
	new String:menu_info_buffer[4];
	new String:menu_display_buffer[16];
	new Handle:volume_menu = INVALID_HANDLE;
	new volume_target = FindOption("volume");
	new volume_current = options[client][volume_target];

	volume_menu = CreateMenu(VolumeMenuHandler);
	SetMenuTitle(volume_menu, "Jukebox - Set Volume");
	// PrintToConsole(client, "DEBUG: Starting menu creation loop."); // DEBUG
	for(new i = 0; i < sizeof(volume_settings); i++) {
		// PrintToConsole(client, "Loop, i = %d", i); // DEBUG
		if((i == 0 || volume_settings[i-1] < volume_current) && volume_settings[i] >= volume_current) {
			// PrintToConsole(client, "Adding 'current' menu item, vol = %d%%.", volume_current); // DEBUG
			FormatEx(menu_display_buffer, sizeof(menu_display_buffer), "%d%% (current)", volume_current);
			IntToString(volume_current, menu_info_buffer, sizeof(menu_info_buffer));
			AddMenuItem(volume_menu, menu_info_buffer, menu_display_buffer);
		}
		if (volume_settings[i] != volume_current) {
			// PrintToConsole(client, "Adding item #%d, quant = %d%%", i, volume_settings[i]); // DEBUG
			FormatEx(menu_display_buffer, sizeof(menu_display_buffer), "%d%%", volume_settings[i]);
			IntToString(volume_settings[i], menu_info_buffer, sizeof(menu_info_buffer));
			AddMenuItem(volume_menu, menu_info_buffer, menu_display_buffer);
		}
	}
	// PrintToConsole(client, "End menu loop."); // DEBUG
	DisplayMenu(volume_menu, client, menu_maxtime);

	return true;
}



public VolumeMenuHandler(Handle:menu, MenuAction:action, client, position) {
	new String:item[8];
	new volume_setting;

	if(action == MenuAction_Select) {
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			PrintToConsole(client, "Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		volume_setting = StringToInt(item);
		if(!SetVolume(client, volume_setting)) {
			return false;
		}
		if(abs(stream_memberships[client]) > 0) {
			RestartMenu(client);
		} else {
			SettingsMenu(client);
		}
	} else if(action == MenuAction_Cancel) {
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}


RestartMenu(client) {
	new Handle:restart_menu = INVALID_HANDLE;

	restart_menu = CreateMenu(RestartMenuHandler);
	SetMenuTitle(restart_menu, "Jukebox - Restart Playback?");
	AddMenuItem(restart_menu, "1", "Yes");
	AddMenuItem(restart_menu, "0", "No");
	DisplayMenu(restart_menu, client, 10);

	return true;
}

public RestartMenuHandler(Handle:menu, MenuAction:action, client, position) {
	new String:item[2];

	if(action == MenuAction_Select) {
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			PrintToConsole(client, "Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		if(StrEqual(item, "1") && abs(stream_memberships[client]) > 1) {
			new clients_list[1];
			clients_list[0] = client;
			AddClients(abs(stream_memberships[client]), clients_list, 1, false, play_lock[client]);
		}
		SettingsMenu(client);
	} else if(action == MenuAction_Cancel) {
		SettingsMenu(client);
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}


public Action:Command_Jukebox (client, args) {
	if(!GetConVarInt(cv_enabled)) {
		PrintToChat(client, "Jukebox is currently disabled.");
		return Plugin_Handled;
	}
	
	if(!PrepareConnection(client)) {
		return Plugin_Handled;
	}

	if (args >= 1) {
		//new num_bytes;
		decl String:args_line[256];
		GetCmdArgString(args_line, sizeof(args_line));

		if (client) {
			decl String:name[username_length];
			GetClientName(client, name, sizeof(name));
			PrintToServer("Jukebox command from client: %s", name);
		} else {
			PrintToServer("Jukebox command from server.");
		}
		// PrintToServer("Argument string: %s", args_line); // DEBUG

		SystemLaunch(client, args_line);
	} else {
		new Handle:top_args = INVALID_HANDLE;
		top_args = CreateKeyValues("Queries");
		// Display top menu
		TopMenu(client, top_args);
		CloseHandle2(top_args);
	}

	return Plugin_Handled;
}



public Action:Command_Volume (client, args) {
	if(!PrepareConnection(client)) {
		return Plugin_Handled;
	}
	
	new String:volume_string[8];
	if(args == 1 && GetCmdArg(1, volume_string, sizeof(volume_string))) {
		new volume;
		volume = StringToInt(volume_string);
		SetVolume(client, volume);
	} else {
		VolumeMenu(client);
	}

	return Plugin_Handled;
}



SetVolume(client, volume) {
	if(volume < 1) {
		volume = 1;
	} else if (volume > 100) {
		volume = 100;
	}
	if(SetOption(client, "volume", volume)) {
		PrintToChat(client, "Jukebox: Volume set to %d%%.  This has been saved and will be restored when you return.", volume);
		return true;
	} else {
		PrintToChat(client, "An error has occured saving your volume settings.");
		return false;
	}
}



StopMOTD (client) {
	LoadMOTDPanelHidden (client, "Blank", "about:blank", MOTDPANEL_TYPE_URL);
}

/*
StopMOTDAll() {
	LoadMOTDPanelHiddenAll("Blank", "about:blank", MOTDPANEL_TYPE_URL);
}
*/


public Action:Command_JbOff (client, args) {
	if(stream_memberships[client] < 1 || stream_memberships[client] > 0) {
		if(play_lock[client] == false) {
			RemoveClient(client, false);
			PrintToChat(client, "Jukebox: Music playback halted.");
			PrintToConsole(client, "Jukebox: Music playback halted.");
			decl String:username[username_length];
			if(!GetClientName(client, username, sizeof(username))) {
				username = "Unknown user";
			}
			PrintToServer("Jukebox: Music playback halted by %s.", username);
		} else {
			PrintToChat(client, "Jukebox: Playback of this track cannot be halted.");
		}
	} else {
		PrintToChat(client, "Jukebox: There is no music playing.");
	}

	return Plugin_Handled;
}



public Action:Command_MusicOff(client, args)
{
	PrintToChat(client, "Jukebox: The command '!musicoff' has been replaced with '!jboff'.  Please use '!jboff' in the future.  '!musicoff' may be removed in future builds.");
	Command_JbOff(client, args);

	return Plugin_Handled;
}



public Action:Command_JbAllOff(client, args) {
	decl String:username[username_length];

	for(new i = 1; i <= num_clients; i++) {
		RemoveClient(i, false);
	}
	PrintToConsole(client, "Jukebox: Music playback halted for all users.");
	if(!GetClientName(client, username, sizeof(username))) {
		strcopy(username, username_length, "unknown user");
	}
	PrintToChatAll("Jukebox: Music playback halted for all users by %s.", username);
	PrintToServer("Jukebox: Music playback halted for all users by %s.", username);

	return Plugin_Handled;
}



WordsToChars(String:dest[], destlen, source[], sourcelen) {
	#define source_max 65535 // 2^16 = 65536, but including the value 0, 65535 is the max unsigned value

	new dest_count = 0;
	new bool:skip_test;

	//  PrintToConsole(client, "In WordsToChars, source length = %d, dest length = %d", sourcelen, destlen);

	for (new i = 0; i < sourcelen && dest_count + 1 < destlen; i++) {
		if(source[i] <= source_max) {
			//  PrintToConsole(client, "Loop %d, value = %d, bit 1 = %d, bit 2 = %d", i, source[i], source[i] / 256, source[i] % 256); // DEBUG
			dest[dest_count++] = source[i] / 256;
			dest[dest_count++] = source[i] % 256;
		} else {
			//  PrintToConsole(client, "Loop %d, value = %d, SKIPPED!", i, source[i]); // DEBUG
			skip_test = true;
		}
	}

	if(skip_test) {
		dest_count *= -1;
	}

	return dest_count;
}



PlaylistToBase64(String:dest[], maxlen, id_array[], sourcelen, client) {

	new String:binary_array[sourcelen*2+1];
	new binary_length;

	//  PrintToConsole(client, "Running WordsToChars..."); // DEBUG
	binary_length = WordsToChars(binary_array, sourcelen*2, id_array, sourcelen);

	if (binary_length > 0) {
		// PrintToConsole(client, "Running base64 encode..."); // DEBUG
		new String:base64mime[maxlen+1];
		new String:base64url[maxlen+1];
		new output_length;
		output_length = EncodeBase64(base64mime, maxlen, binary_array, binary_length);
		// PrintToConsole(client, "Base 64 MIME = '%s'", base64mime);
		Base64MimeToUrl(base64url, maxlen, base64mime);
		PrintToConsole(client, "Base 64 URL = '%s'", base64url);
		strcopy(dest, maxlen, base64url);
		return output_length;
	} else {
		PrintToConsole(client, "WordsToChars failed!"); // DEBUG
		return false;
	}
}




public Action:NextTrack(Handle:timer, any:id) {

	// PrintToChatAll("Jukebox: Debugging, please forgive chat spam..."); // DEBUG

	decl String:id_string[11]; // , String:track_string[4];
	new count, now_playing, latest_time, playall;
	new update_clients[num_clients+1];
	new playtime;
	new subscribed_clients[num_clients+1];
	new update_count = 0, subscribed_count = 0;
	new playall_target = FindOption("playall");
	decl String:query[512], String:error[256];

	IntToString(id, id_string, sizeof(id_string));

	// Debugging info
	decl String:creator_steam[25], String:steam_temp[25];
	new Handle:results = INVALID_HANDLE;
	new client = -1;
	FormatEx(query, sizeof(query), "SELECT creator_steam FROM %s WHERE stream_id = %d", db_streams, id);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		PrintToChatAll("Jukebox: Failed to retrieve stream creator's Steam ID for debugging.  Error: \"%s\"  Query: \"%s\"", error, query);
	} else {
		if(!SQL_FetchRow(results)) {
			PrintToChatAll("Jukebox: Search for creator's Stream ID returned no results.  Query: \"%s\"", query);
		} else {
			SQL_FetchString(results, 0, creator_steam, sizeof(creator_steam));

			// PrintToChatAll("Jukebox: Echo 50 - num_clients = %d", num_clients); // DEBUG

			for(new i = 1; i <= num_clients; i++) {
				// PrintToChatAll("Jukebox: Find client loop %d of %d", i, num_clients); // DEBUG
				if(IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthString(i, steam_temp, sizeof(steam_temp)) && StrEqual(creator_steam, steam_temp)) {
					// PrintToConsole(i, "Jukebox: NextTrack has found creator's client."); // DEBUG
					client = i;
					break;
				}
			}
			if(client < 0) {
				PrintToChatAll("Jukebox: Cannot identify Stream's creator.");
			}
		}
	}
	CloseHandle2(results);

	// End debug setup

	// PrintToConsole(client, "Jukebox: Starting NextTrack..."); // DEBUG

	FormatEx(query, sizeof(query), "SELECT st.now_playing, UNIX_TIMESTAMP(st.latest_time) AS latest_time, st.playall, COUNT(pl.track_id) AS track_count FROM %s AS st LEFT JOIN %s AS pl USING (stream_id) WHERE stream_id = %d GROUP BY stream_id", db_streams, db_playlists, id);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		PrintToConsole(client, "Jukebox: Failed to retrieve header data.  Error: \"%s\"  Query: \"%s\"", error, query);
		return Plugin_Continue;
	}

	if(!SQL_FetchRow(results)) {
		PrintToConsole(client, "Jukebox: Search for stream's header data returned no results.  Query: \"%s\"", query);
		CloseHandle2(results);
		return Plugin_Continue;
	}
	now_playing = SQL_FetchInt(results, 0);
	latest_time = SQL_FetchInt(results, 1);
	playall = SQL_FetchInt(results, 2);
	count = SQL_FetchInt(results, 3);
	CloseHandle2(results);

	if (++now_playing > count) {
		CreateTimer(5.0, DelayedRemoveStream, id);
		// KvRewind(streams);
		return Plugin_Continue;
	}

	FormatEx(query, sizeof(query), "SELECT `playtime` FROM %s LEFT JOIN %s ON id = track_id WHERE stream_id = %d AND sequence = %d", db_tracks, db_playlists, id, now_playing);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		PrintToConsole(client, "Jukebox: Failed to retrieve song duration data.  Error: \"%s\"  Query: \"%s\"", error, query);
		return Plugin_Continue;
	}
	if(!SQL_FetchRow(results)) {
		PrintToConsole(client, "Jukebox: Search for song duration data returned no results.  Query: \"%s\"", query);
		CloseHandle2(results);
		return Plugin_Continue;
	}
	playtime = SQL_FetchInt(results, 0);
	CloseHandle2(results);

	if(now_playing == 1) {
		latest_time = GetTime();
	} else {
		latest_time = latest_time + playtime;
	}

	FormatEx(query, sizeof(query), "UPDATE %s SET `now_playing` = `now_playing` + 1, latest_time = FROM_UNIXTIME(%d) WHERE `stream_id` = %d", db_streams, latest_time, id);
	if(!SQL_FastQuery(music_db, query)) {
		SQL_GetError(music_db, error, sizeof(error));
		PrintToConsole(client, "Jukebox: Failed to update stream header data.  Error: \"%s\"  Query: \"%s\"", error, query);
		return Plugin_Continue;
	}

	// PrintToConsole(client, "Subscribing new clients."); // DEBUG

	for(new i = 1; i <= num_clients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && (((playall == 2 || (playall == 1 && options[i][playall_target])) && stream_memberships[i] == -1) || stream_memberships[i] == -1*id)) {
			// PrintToConsole(client, "Added client %d.", i); // DEBUG
			update_clients[update_count++] = i;
		}
	}

	// PrintToConsole(client, "Subscriptions complete."); // DEBUG

	if (update_count > 0) {
		// PrintToConsole(client, "Building hash and connecting new users."); // DEBUG
		AddClients(id, update_clients, update_count, true, (playall == 2));
	}

	for(new i = 1; i <= num_clients; i++) {
		if(stream_memberships[i] == id) {
			subscribed_clients[subscribed_count++] = i;
		}
	}
	
	// PrintToConsole(client, "Subscribed count = %d", subscribed_count); // DEBUG
	
	if(subscribed_count == 0) {
		RemoveStream(id);
	}

	// PrintToConsole(client, "Running DisplayTrackInfo..."); // DEBUG

	DisplayTrackInfo(id, subscribed_clients, subscribed_count);

	// PrintToConsole(client, "Running UpdatePlaybackStats..."); // DEBUG

	UpdatePlaybackStats(id, subscribed_count);

	CreateTimer(float(playtime), NextTrack, id);

	// PrintToConsole(client, "Jukebox: NextTrack complete!"); // DEBUG

	return Plugin_Continue;
}



UpdatePlaybackStats(stream_id, play_count) {
	decl String:query[512];
	// new id, String:stream_string[11];

	FormatEx(query, sizeof(query), "UPDATE %s SET `popularity` = `popularity` + 1, `playcount` = `playcount` + %d WHERE `id` = (SELECT `track_id` FROM %s INNER JOIN %s ON %s.`stream_id` = %s.`stream_id` AND `sequence` = `now_playing` WHERE %s.`stream_id` = %d)", db_tracks, play_count, db_playlists, db_streams, db_playlists, db_streams, db_playlists, stream_id);

	// Format(query, sizeof(query), "UPDATE %s SET popularity = popularity + 1, playcount = playcount + %d WHERE id = %d", db_tracks, play_count, id);
	if(!SQL_FastQuery(music_db, query)) {
		PrintToChatAll("Jukebox: WARNING - Playback stats not updated."); // DEBUG
		return false;
	} else {
		return true;
	}
}



DisplayTrackInfo(id, clients_list[], clients_count) {
	new String:track_info_targets[][] = {"title", "artist", "album"};
	decl String:track_info_results[sizeof(track_info_targets)][title_length];
	decl String:track_info[sizeof(track_info_targets)*(title_length+3)];
	// decl String:id_string[11];
	new playtime;
	new Float:display_time = 8.0;
	new Handle:datapack = INVALID_HANDLE, Handle:results = INVALID_HANDLE;
	decl String:query[384];
	
	ImplodeStrings(track_info_targets, sizeof(track_info_targets), ", ", track_info, sizeof(track_info));
	FormatEx(query, sizeof(query), "SELECT %s, playtime FROM %s INNER JOIN %s ON track_id = id INNER JOIN %s ON %s.stream_id = %s.stream_id AND now_playing = sequence WHERE %s.stream_id = %d", track_info, db_tracks, db_playlists, db_streams, db_playlists, db_streams, db_streams, id);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		decl String:error[512]; // DEBUG
		SQL_GetError(music_db, error, sizeof(error)); // DEBUG
		Format(error, sizeof(error), "Failed to retrieve track info for display.  SQL error: %s", error);
		ReportErrorToAuthor(id, error);
		return false;
	}
	
	if(!SQL_FetchRow(results)) {
		ReportErrorToAuthor(id, "Jukebox: WARNING - Search for track info returned zero results.");
		CloseHandle2(results);
		return false;
	}
	for(new i = 0; i < sizeof(track_info_targets); i++) {
		SQL_FetchString(results, i, track_info_results[i], sizeof(track_info_results[]));
	}
	playtime = SQL_FetchInt(results, sizeof(track_info_targets));
	CloseHandle2(results);

	ImplodeStrings(track_info_results, sizeof(track_info_targets), "\n", track_info, sizeof(track_info));

	if(display_time > playtime - 1) {
		display_time = float(playtime - 1);
	}

	CreateDataTimer(3.0, DelayedDisplayMessage, datapack);
	WritePackFloat(datapack, display_time);
	WritePackCell(datapack, clients_count);
	for(new i = 0; i < clients_count; i++) {
		WritePackCell(datapack, clients_list[i]);
	}
	WritePackString(datapack, track_info);

	return true;
}



RemoveStream(const id) {
	// new String:id_string[11];
	decl String:query[256];

	// IntToString(id, id_string, sizeof(id_string));

	for(new i = 1; i <= num_clients; i++) {
		if (abs(stream_memberships[i]) == id) {
			RemoveClient(i, true);
		}
	}
	for(new i = 0; i < sizeof(disconnect_streams); i++) {
		if(abs(disconnect_streams[i]) == id) {
			ClearDisconnectData(id);
		}
	}

	FormatEx(query, sizeof(query), "DELETE %s, %s FROM %s LEFT JOIN %s USING (stream_id) WHERE %s.stream_id = %d", db_streams, db_playlists, db_streams, db_playlists, db_streams, id);
	if(!SQL_Query(music_db, query)) {
		PrintToChatAll("Jukebox: WARNING - Failed to destroy music stream."); // DEBUG
		return false;
	}

	// PrintToChatAll("Jukebox DEBUG: Removed stream %d", id);

	return true;
}


public Action:DelayedRemoveStream(Handle:timer, any:id) {
	RemoveStream(id);

	return Plugin_Continue;
}


public Action:DelayedRemoveClient(Handle:timer, any:client) {
	RemoveClient(client, false);

	return Plugin_Continue;
}



//  Byte 0 = playtime, Byte 1 = # of clients "n", bytes 2 to n+1 = client numbers, bytes n+2 to end = display string
public Action:DelayedDisplayMessage(Handle:timer, Handle:datapack) {
	new Float:display_time, client_count;
	new String:message[300];
	new Handle:hud_sync = INVALID_HANDLE;

	ResetPack(datapack);
	display_time = ReadPackFloat(datapack);
	client_count = ReadPackCell(datapack);

	new client_list[client_count];
	for(new i = 0; i < client_count; i++) {
		client_list[i] = ReadPackCell(datapack);
	}
	ReadPackString(datapack, message, sizeof(message));

	hud_sync = CreateHudSynchronizer();
	if(hud_sync == INVALID_HANDLE) {
		for(new i = 1; i <= client_count; i++) {
			PrintHintText(client_list[i], message);
		}
	} else {
		SetHudTextParams(-1.0, 0.1, display_time, 254, 254, 254, 195, 1);
		for(new i = 0; i < client_count; i++) {
			ShowSyncHudText(client_list[i], hud_sync, message);
		}
	}
	CloseHandle2(hud_sync);
}



RemoveClient(const client, bool:closeout=false) {
	new stream_id;
	new bool:alive_test;

	// PrintToChatAll("Jukebox DEBUG: Removing client %d (%N) from stream %d", client, client, stream_memberships[client]); // DEBUG

	if(IsClientInGame(client) && !IsFakeClient(client)) {
		if(!closeout) {
			stream_id = stream_memberships[client];
		}
		if(!(closeout && stream_memberships[client] < -1)) {
			StopMOTD(client);
		}
		stream_memberships[client] = 0;
		play_lock[client] = false;

		if(!closeout) {
			for(new i = 1; i < num_clients; i++) {
				if (abs(stream_memberships[i]) == stream_id) {
					alive_test = true;
					break;
				}
			}
			if(!alive_test) {
				for(new i = 0; i < sizeof(disconnect_streams); i++) {
					if(abs(disconnect_streams[i]) == stream_id) {
						alive_test = true;
						break;
					}
				}
				if(!alive_test) {
					RemoveStream(stream_id);
				}
			}
		}
	}
}



FindMinInArray(array[], length) {
	new minimum, cell, i;

	if(length == 0) {
		return -1;
	}
	minimum = array[0];
	cell = 0;
	for(i = 1; i < length; i++) {
		if(array[i] < minimum) {
			minimum = array[i];
			cell = i;
		}
	}

	return cell;
}



FindStringInNaturalArray(String:array[][], length, String:target[]) {
	new cell, i;

	cell = -1;

	for(i = 0; i < length; i++) {
		if(StrEqual(array[i], target)) {
			cell = i;
			break;
		}
	}

	return cell;
}


public ClearDisconnectData(const cell) {
	disconnect_steam_ids[cell][0] = '\0';
	disconnect_streams[cell] = 0;
	disconnect_locks[cell] = false;
	disconnect_time[cell] = 0;

	return;
}


public abs(const source) {
	if (source < 0) {
		return -1*source;
	} else {
		return source;
	}
}



GenerateKey(String:output[], maxlen) {
	new time, write_length;
	decl String:word[5];
	decl String:crypt[5];
	decl String:key[9];
	decl String:key_url[sizeof(key)];
	new String:leech_password[33]; // Used to generate in-URL encryption key; for anti-leech protection
	
	GetConVarString(cv_leech_password, leech_password, sizeof(leech_password));

	time = GetTime() + time_offset;
	// PrintToChatAll("DEBUG: Current time = %d, time offset = %d, total = %d", GetTime(), time_offset, time);
	word[0] = time / 16777216;
	word[1] = (time % 16777216) / 65536;
	word[2] = (time % 65536) / 256;
	word[3] = time % 256;
	word[4] = '\0'; // Just to prevent crashes, but shouldn't be used/read
	write_length = EncodeRC4Binary(word, 4, leech_password, crypt, sizeof(crypt));
	EncodeBase64(key, sizeof(key), crypt, write_length);
	Base64MimeToUrl(key_url, sizeof(key_url), key);
	strcopy(output, maxlen, key_url);

	return write_length;
}



public Action:Command_Eavesdrop(client, args) {
	if(!GetConVarInt(cv_enabled)) {
		PrintToChat(client, "Jukebox is currently disabled.");
		return Plugin_Handled;
	}
	
	if(!PrepareConnection(client)) {
		return Plugin_Handled;
	}

	decl String:arguments[username_length+6];
	new String:target_username[username_length];
	new target_stream;
	decl String:query[512], String:error[256];
	new Handle:results = INVALID_HANDLE;

	// PrintToConsole(client, "Jukebox: Running eavesdrop..."); // DEBUG

	if(args >= 1 && GetCmdArg(1, arguments, sizeof(arguments))) {
		// PrintToConsole(client, "Looking for stream being listened to by specified user."); // DEBUG
		
		decl String:name_search[username_length];
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[num_clients], target_count, bool:tn_is_ml;
		BreakString(arguments, name_search, sizeof(name_search));
		target_count = ProcessTargetString(name_search, 0, target_list, num_clients, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
		if(target_count <= 0) {
			PrintToChat(client, "Jukebox: There are no players which match '%s'.", name_search);
			// No matching names
			return Plugin_Handled;
		}

		FormatEx(target_username, sizeof(target_username), "%N", target_list[0]);
		target_stream = abs(stream_memberships[target_list[0]]);
		if(target_stream >= -1 && target_stream <= 1) {
			PrintToChat(client, "Jukebox: %s is not listening to anything.", target_username);
			// Target is not listening to anything
			return Plugin_Handled;
		}
	} else {
		// PrintToConsole(client, "Looking for most recent stream."); // DEBUG

		FormatEx(query, sizeof(query), "SELECT `stream_id`, `creator_name` FROM %s ORDER BY `start_time` DESC LIMIT 1", db_streams);
		results = SQL_Query(music_db, query);
		if(results == INVALID_HANDLE) {
			SQL_GetError(music_db, error, sizeof(error));
			PrintToConsole(client, "Jukebox: Failed while looking up latest music stream.  Error: \"%s\"  Query: \"%s\"", error, query);
			return Plugin_Handled;
		}

		if(!SQL_FetchRow(results)) {
				PrintToChat(client, "Jukebox: No one is listening to any music right now.");
				// No streams have been created yet
				CloseHandle2(results);
				return Plugin_Handled;
		}
		target_stream = SQL_FetchInt(results, 0);
		SQL_FetchString(results, 1, target_username, sizeof(target_username));
		CloseHandle2(results);
	}
	
	// PrintToConsole(client, "Determined target stream."); // DEBUG
	
	if(target_stream == abs(stream_memberships[client])) {
		PrintToChat(client, "Jukebox: You are already listening to the same music stream.");
		return Plugin_Handled;
	}

	new now_playing, total_count;
	// new String:id_string[11];
	new clients_list[1];
	clients_list[0] = client;

	new playtime, latest_time;

	// PrintToConsole(client, "Beginning main Eavesdrop SQL query."); // DEBUG

	FormatEx(query, sizeof(query), "SELECT tr.`playtime`, UNIX_TIMESTAMP(st.`latest_time`) AS 'latest_time', st.`now_playing`, COUNT(pl2.`track_id`) AS 'track_count' FROM %s AS st INNER JOIN %s AS pl ON (st.stream_id = pl.stream_id AND st.now_playing = pl.sequence) INNER JOIN %s AS tr ON pl.track_id = tr.id LEFT JOIN %s AS pl2 ON st.stream_id = pl2.stream_id WHERE st.stream_id = %d GROUP BY st.stream_id", db_streams, db_playlists, db_tracks, db_playlists, target_stream);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		SQL_GetError(music_db, error, sizeof(error));
		PrintToConsole(client, "Jukebox: Failed while looking up stream data.  Error: \"%s\"  Query: \"%s\"", error, query);
		return Plugin_Handled;
	}
	if(!SQL_FetchRow(results)) {
		PrintToConsole(client, "Jukebox: Stream data query returned no results.  Query: %s", query);
		return Plugin_Handled;
	}
	playtime = SQL_FetchInt(results, 0);
	latest_time = SQL_FetchInt(results, 1);
	now_playing = SQL_FetchInt(results, 2);
	total_count = SQL_FetchInt(results, 3);
	CloseHandle2(results);

	// PrintToConsole(client, "Obtained data for next track."); // DEBUG

	new test_time = latest_time - GetTime() + playtime;
	// KvRewind(streams);
	if(now_playing == total_count || test_time > 10) {
		AddClients(target_stream, clients_list, 1, false, false);

		DisplayTrackInfo(target_stream, clients_list, 1);

		UpdatePlaybackStats(target_stream, 1);

		PrintToChat(client, "Jukebox: Eavesdropping on music being listened to by %s.  Type '!jboff' to stop playback.", target_username);

	} else {
		// This has not been tested - confirm it works!
		PrintToChat(client, "Jukebox: Eavesdropping on %s will begin shortly with the next track.  Type '!jboff' to stop playback.", target_username);
	}

	// PrintToConsole(client, "Eavesdrop complete."); // DEBUG

	return Plugin_Handled;
}



AddClients(id, clients_list[], update_count, bool:is_synced=false, bool:lock=false) {
	// decl String:id_string[11];
	decl String:hash[128], String:key[9], String:play_url[256];
	new volume_shift, track_count;
	new volume_target = FindOption("volume");
	new sync_modifier;
	decl String:query[256], String:base_url[128];
	new Handle:results = INVALID_HANDLE;

	GetConVarString(cv_base_url, base_url, sizeof(base_url));
	if(base_url[strlen(base_url)-1] != '/') {
		Format(base_url, sizeof(base_url), "%s/", base_url);
	}

	if(is_synced) {
		sync_modifier = 1;
	} else {
		sync_modifier = -1;
	}

	// PrintToConsole(1, "Building id array."); // DEBUG

	for(new i = 0; i < update_count; i++) {
		if(abs(stream_memberships[clients_list[i]]) > 1 && abs(stream_memberships[clients_list[i]]) != id) {
			RemoveClient(clients_list[i]);
		}
		stream_memberships[clients_list[i]] = sync_modifier*id;
		play_lock[clients_list[i]] = lock;
	}

	FormatEx(query, sizeof(query), "SELECT track_id FROM %s INNER JOIN %s USING (stream_id) WHERE stream_id = %d AND sequence >= now_playing", db_playlists, db_streams, id);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		PrintToChatAll("Jukebox: WARNING - Failed to add clients."); // DEBUG
		return false;
	}
	track_count = SQL_GetRowCount(results);
	decl track_array[track_count];
	for(new i = 0; i < track_count; i++) {
		SQL_FetchRow(results);
		track_array[i] = SQL_FetchInt(results, 0);
	}
	CloseHandle2(results);

	// PrintToConsole(1, "Creating hash."); // DEBUG

	if(PlaylistToBase64(hash, sizeof(hash), track_array, track_count, 0) <= 0) {
		// if (client > 0) PrintToConsole(client, "Failed creating Base 64 hash."); // DEBUG
		RemoveStream(id);
		return false;
	}
	GenerateKey(key, sizeof(key)); // Encrypts a time stamp into the URL to prevent leeching

	// PrintToConsole(1, "Connecting new users."); // DEBUG

	FormatEx(query, sizeof(query), "SELECT volume_shift FROM %s WHERE stream_id = %d", db_streams, id);
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		PrintToChatAll("Jukebox: WARNING - Failed to add clients."); // Clean this up with private error message
		return false;
	}
	if(!SQL_FetchRow(results)) {
		PrintToChatAll("Jukebox: WARNING - Failed to add clients."); // Clean this up with private error message
		CloseHandle2(results);
		return false;
	}
	volume_shift = SQL_FetchInt(results, 0);
	CloseHandle2(results);

	for(new i = 0; i < update_count; i++) {
		FormatEx(play_url, sizeof(play_url), "%squery.php?id_b64=%s&key=%s&vol=%d", base_url, hash, key, options[clients_list[i]][volume_target]+volume_shift);
		// PrintToConsole(1, "Loop %d, playing music for client %d, URL = %s.", i, update_clients[i], play_url); // DEBUG
		// PrintToConsole(clients_list[i], "Playing URL: %s", play_url); // DEBUG
		LoadMOTDPanelHidden(clients_list[i], "Jukebox - Source Engine Streaming Music System", play_url, MOTDPANEL_TYPE_URL);
	}

	return true;
}



SaveResults(client, Handle:results) {
	if (results == INVALID_HANDLE) {
		return false;
	}
	
	RemoveResults(client);
	
	results_storage[client] = CreateKeyValues("Results");
	
	KvCopySubkeys(results, results_storage[client]);
	
	return true;
}



Handle:GetResults(client) {
	
	// PrintToChatAll("Running GetResults."); // DEBUG
	
	if(results_storage[client] == INVALID_HANDLE) {
		return INVALID_HANDLE;
	}
	new Handle:results_temp = CreateKeyValues("Results");
	KvCopySubkeys(results_storage[client], results_temp);
	
	// CloseHandle(results_storage[client]);
	return results_temp;
}



RemoveResults(client) {
	
	return CloseHandle2(results_storage[client]);
	
}



ReportErrorToAdmin(id, String:error[]) {
	new AdminId:admin_id = INVALID_ADMIN_ID;
	
	for(new i = 0; i <= MaxClients; i++) {
		if(IsClientInGame(i) && abs(stream_memberships[i]) == id) {
			admin_id = GetUserAdmin(i);
			if(admin_id != INVALID_ADMIN_ID && GetAdminFlag(admin_id, Admin_Chat)) {
				PrintToConsole(i, error);
			}
		}
	}
	
	return true;
}



ReportErrorToAuthor(id, String:error[]) {
	new String:query[128], String:creator_steam[25], String:target_steam[25];
	new Handle:results = INVALID_HANDLE;
	FormatEx(query, sizeof(query), "SELECT creator_steam FROM %d WHERE id = %s", db_streams, id);
	
	results = SQL_Query(music_db, query);
	if(results == INVALID_HANDLE) {
		new String:sub_error[256];
		SQL_GetError(music_db, sub_error, sizeof(sub_error));
		ReportErrorToAdmin(id, sub_error);
		return false;
	}
	if(!SQL_FetchRow(results) || !SQL_FetchString(results, 0, creator_steam, sizeof(creator_steam))) {
		ReportErrorToAdmin(id, "Failed to retrieve Steam ID of stream's author.");
		return false;
	}
	
	for(new i = 0; i <= MaxClients; i++) {
		if(IsClientInGame(i) && GetClientAuthString(i, target_steam, sizeof(target_steam)) && StrEqual(creator_steam, target_steam)) {
			PrintToConsole(i, error);
		}
	}
	
	return true;
}



CloseHandle2(&Handle:target) {
	new bool:close_test = false;
	
	if(target != INVALID_HANDLE) {
		close_test = CloseHandle(target);
		if(close_test) {
			target = INVALID_HANDLE;
		}
	}
	
	return close_test;
}
