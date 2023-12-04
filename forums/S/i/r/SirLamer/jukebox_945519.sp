/* Jukebox for Source - Steaming Music System
**
** By SirLamer
**
** Version 0.5.5.0 - 2011-08-14
**
** Designed and written for TEAM CHEESUS (http://www.teamcheesus.com).
**
** For additional information, please consult the Jukebox for Source documentation
**  distributed with this plugin.
*/

#pragma semicolon 1 // Enables support for new lines using semi-colon
#include <sourcemod> // Base SourceMod library

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "0.5.5.0"

#define menu_maxtime 90 // [seconds] The maximum time to display menus before self-cancelling.

#define PLAYLIST_MAX 100 // Maximum allowed tracks in a playlist.
#define SEARCH_MAX 100 // Maximum number of search results to be displayed in the menu at once.

#define title_length 80 // [characters] The maximum allowed track title length.
#define album_length 80 // [characters] The maximum allowed album title length.
#define artist_length 40 // [characters] The maximum allowed artist name length.
#define username_length 60 // [characters] The maximum allowed username length.
#define JB_QUEUE_DELAY 5

#define help_url "http://www.teamcheesus.com/user-manual/jukebox" // The URL to the Jukebox help guide for your server.  If you don't want to operate your own, a manual for the latest version is kept up to date at http://www.teamcheesus.com/user-manual/jukebox

#define result_subfolder "data/" // The folder within the SourceMod folder to store all the necessary Jukebox goodies.
#define result_filename_prefix "music_menu_"
#define data_file "jukebox_data.txt"

// Text colors
#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05

// Settings from jukebox.cfg
new String:db_options[25]; // The MySQL table name for storing user-controlled settings
new String:db_tracks[25]; // The MySQL table name for storing track records and metadata
new String:db_streams[25]; // The MySQL table name for tracking active music streams
new String:db_playlists[25]; // The MySQL table name for storing playlist items for all active stream
// new String:db_log_users[25];
new String:db_log_usernames[25];
new String:db_log_history[25];

new String:result_folder[96]; // The sub-SourceMod folder used to save various Jukebox data.

new Handle:music_db = INVALID_HANDLE; // The handle object for the MySQL database connection
new Handle:input_types = INVALID_HANDLE; // KeyValues handling for managing Jukebox's internal Input Types system
new Handle:settings = INVALID_HANDLE; // Stores system-critical settings from the file specified in config_path.
new Handle:hud_sync = INVALID_HANDLE; // Hud text synchronizer used to avoid track info overlap.
new time_offset = 0; // [seconds] The time correction ( = web server - game server) to syncrhonize the game server's clock with the web server's clock (for MySQL transactions).  Refreshed each map change.
new num_clients; // The maximum number of clients allowed on the server.  Refreshed each map change.
new last_map_change; // The time of the last map change.  Used to decide how to handle statistical data collection on disconnected clients who are still listening to a music stream.

// Used to manage and store user-customizable settings.
new String:options_names[][] = {"playall", "volume", "autoqueue"}; // The name used for the setting within Jukebox's code.
new Handle:cv_options_defaults[sizeof(options_names)]; // The cvar handle objects for The default values to be assigned to new users.  These settings are assigned upon first connect and changes are not retro-active to users who haven't set their own values.
new options[MAXPLAYERS+1][sizeof(options_names)]; // Stores each client's settings.  Array position is associated with options_names.
new bool:first_connect[MAXPLAYERS+1]; // Used to determine if the player has just connected to the server.
new jboff_count[MAXPLAYERS+1]; // Tracks repeated use of !jboff command to eventually suggest that the user disables public stream membership.

new Handle:cv_base_url = INVALID_HANDLE;
new Handle:cv_leech_password = INVALID_HANDLE;
new Handle:cv_db_conn_name = INVALID_HANDLE;
new Handle:cv_db_tracks = INVALID_HANDLE;
new Handle:cv_db_options = INVALID_HANDLE;
new Handle:cv_db_streams = INVALID_HANDLE;
new Handle:cv_db_playlists = INVALID_HANDLE;
 // new Handle:cv_db_log_users = INVALID_HANDLE;
new Handle:cv_db_log_usernames = INVALID_HANDLE;
new Handle:cv_db_log_history = INVALID_HANDLE;
new Handle:cv_admin_flags_playall = INVALID_HANDLE;
new Handle:cv_admin_flags_settings = INVALID_HANDLE;
new Handle:cv_admin_flags_reserved = INVALID_HANDLE;
new Handle:cv_announce_mode = INVALID_HANDLE;

new Handle:admin_menu = INVALID_HANDLE; // The Admin Menu hook handler
new TopMenuObject:admin_menu_object = INVALID_TOPMENUOBJECT;

/* About stream_memberships
This array keeps track of what streams clients are listening to and in what state.
Value = 0: User is not listening to any tracks.
Value >= 2: User is synchronously listening to the track number identified
Value <= 2: User is asynchronously listening to the track number identified by the absolute (non-negative) value.  For multi-track streams, user will be re-synchronized at the start of the next track.
Note: Stream IDs start at 2 and are incremented with each new stream.  Stream ID #1 is never assigned.
*/
new stream_memberships[MAXPLAYERS+1];

new bool:play_lock[MAXPLAYERS+1]; // Boolean array; if true, user cannot hault music playback.

new Handle:results_storage[MAXPLAYERS+1]; // Array of KeyValue handle objects for storing menu data during user's selection for subsequent reference.

new Handle:volume_timers[MAXPLAYERS+1]; // Timer handles used to track delayed volume change timers.
new bool:volume_timer_enabled[sizeof(volume_timers)]; // Tracks if each handle is in use.

new popularity_votes[MAXPLAYERS+1]; // Used to store extra track popularity votes earned through variousactions.

new now_volume[MAXPLAYERS+1]; // Used to store the volume being used by each client for the current stream.

new log_username_entry[MAXPLAYERS+1][2]; // Slot 0 = User number, Slot 1 = Username number

// Map change management
new String:disconnect_steam_ids[MAXPLAYERS+5][25]; // Stores list of the most recently disconnected clients using their steam IDs.
new disconnect_streams[sizeof(disconnect_steam_ids)]; // Stores the stream that disconncted users were subscribed to.  Associated with disconnect_steam_ids by position.
new bool:disconnect_locks[sizeof(disconnect_steam_ids)]; // Stores the play_lock setting of disconnected users.  Associated with disconnect_steam_ids by position.
new disconnect_time[sizeof(disconnect_steam_ids)]; // Stores the time of disconnnect for the most recent players.  Associated with disconnect_steam_ids by position.
new disconnect_popularity[sizeof(disconnect_steam_ids)]; // Used to store extra track popularity votes during disconnects.
new disconnect_volume[sizeof(disconnect_steam_ids)]; // Used to store the present volume/mute setting for the track
new disconnect_log_usernames[sizeof(log_username_entry)][2];

// new admin_flags_playall, admin_flags_reserved;

//Cvar handles
new Handle:cv_enabled = INVALID_HANDLE; // Integer cvar (default = 1).  Controls Jukebox accessibility.  Set to 0 to disable Jukebox, to 1 to enable public operation or 2 to restrict Jukebox operation to Admins.
new Handle:cv_reserved = INVALID_HANDLE;
new Handle:cv_volume_loud = INVALID_HANDLE; // Integer cvar (default = 20).  The amount of the per-user volume increase provided when the Jukebox command "-loud" is used, as a percentage of full volume.
new Handle:cv_volume_soft = INVALID_HANDLE; // Integer cvar (default = 20).  The amount of the per-user volume decrease provided when the Jukebox command "-soft" is used, as a percentage of full volume.
new Handle:cv_popularity_decay_rate = INVALID_HANDLE; // Integer cvar (default = 5).  The percentage amount of popularity decay per interval.
new Handle:cv_popularity_decay_interval = INVALID_HANDLE; // Integer cvar (default = 86400).  The duration of each popularity decay interval, in seconds.
new Handle:cv_advertisement = INVALID_HANDLE; // Float cvar (default = 0.0).  The number of seconds after first spawning to display Jukebox advertisement, or set to 0 to not display the advertisement.
new Handle:cv_monitor_jboff_use = INVALID_HANDLE; // Integer cvar (default = 3).  The number of times the user must cancel a public song to be automatically reminded and invited to adjust personal playback settings. Set to 0 to disable.
new Handle:cv_playall_on_connect = INVALID_HANDLE; // Boolean cvar (default = 1). When enabled, connecting new players will be merged into the active public stream.
new Handle:cv_motd_restart = INVALID_HANDLE;
new Handle:cv_log_use = INVALID_HANDLE;
new Handle:cv_volume_min = INVALID_HANDLE;


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
	cv_enabled = CreateConVar("jb_enabled", "1", "Enables Jukebox operation.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_reserved = CreateConVar("jb_reserved", "0", "Reserves Jukebox operation for admins.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_base_url = CreateConVar("jb_base_url", "", "URL path to Jukebox's base folder.", FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_leech_password = CreateConVar("jb_leech_password", "", "Anti-leech password used to timestamp produced URLs.  Must match the leech password specified on the web server.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PLUGIN);
	cv_db_conn_name = CreateConVar("jb_db_conn_name", "default", "Named SQL connection to be used by Jukebox.  Database must be defined within sourcemod/configs/database.cfg", FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	
	cv_volume_loud = CreateConVar("jb_volume_loud", "20", "Volume boost for 'loud' playback", FCVAR_PLUGIN, true, 0.0, true, 50.0);
	cv_volume_soft = CreateConVar("jb_volume_soft", "-20", "Volume reduction for 'soft' playback", FCVAR_PLUGIN, true, -50.0, true, 0.0);
	cv_volume_min = CreateConVar("jb_volume_min", "10", "The minimum permitted volume setting, as a percentage of maximum volume.", FCVAR_SPONLY|FCVAR_PLUGIN, true, 1.0, true, 100.0);
	cv_popularity_decay_rate = CreateConVar("jb_popularity_decay_rate", "5", "Percentage rate of decay of popularity scores per interval time", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	cv_popularity_decay_interval = CreateConVar("jb_popularity_decay_interval", "86400", "The interval time between popularity decay events, in seconds", FCVAR_PLUGIN, true, 60.0);
	cv_advertisement = CreateConVar("jb_advertisement", "0", "The number of seconds after first spawning to display the Jukebox advertisement, or set to 0 to not display the advertisement.", FCVAR_PLUGIN, true, 0.0, true, 300.0);
	cv_monitor_jboff_use = CreateConVar("jb_monitor_jboff_use", "3", "The number of times the user must cancel a public song to be automatically reminded and invited to adjust personal playback settings. Set to 0 to disable.", FCVAR_PLUGIN, true, 0.0);
	cv_playall_on_connect = CreateConVar("jb_playall_on_connect", "1", "When enabled, connecting new players will be merged into the active public stream.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_motd_restart = CreateConVar("jb_motd_restart", "0", "When enabled, users will be reconnected to their music stream after being interrupted by an HTML-based Message of the Day display.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_log_use = CreateConVar("jb_log_use", "0", "Enables playback logging.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// WARNING - the order of these ConVars must be coordinated with the "options_names" array of strings
	cv_options_defaults[0] = CreateConVar("jb_playall_default", "1", "Default setting for if clients should be subscribed to public streams.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cv_options_defaults[1] = CreateConVar("jb_volume_default", "80", "Default playback volume for new users", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	cv_options_defaults[2] = CreateConVar("jb_queue_default", "0", "Default setting for automatic music queuing.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cv_db_tracks = CreateConVar("jb_db_tracks", "jb_tracks", "SQL table name for the Tracks table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_db_options = CreateConVar("jb_db_options", "jb_options", "SQL table name for the Options table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_db_streams = CreateConVar("jb_db_streams", "jb_streams", "SQL table name for the Streams table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_db_playlists = CreateConVar("jb_db_playlists", "jb_stream_tracks", "SQL table name for the Playlists table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	// cv_db_log_users = CreateConVar("jb_db_log_users", "jb_log_users", "SQL table name for the Log Users table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_db_log_usernames = CreateConVar("jb_db_log_usernames", "jb_log_usernames", "SQL table name for the Log Usernames table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_db_log_history = CreateConVar("jb_db_log_history", "jb_log_history", "SQL table name for the Log History table.", FCVAR_PROTECTED|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_admin_flags_playall = CreateConVar("jb_admin_flags_playall", "jz", "An admin flag string identifying the admin flags that grant Public Stream playback control permissions, or leave blank to grant access to all users.", FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_admin_flags_settings = CreateConVar("jb_admin_flags_settings", "hz", "An admin flag string identifying the admin flags that grant Jukebox Admin Menu access, or leave blank to grant access to all users with general Admin Menu access rights.", FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_admin_flags_reserved = CreateConVar("jb_admin_flags_reserved", "jz", "An admin flag string identifying the admin flags that grant Jukebox operation rights during the 'reserved' state.", FCVAR_PRINTABLEONLY|FCVAR_PLUGIN);
	cv_announce_mode = CreateConVar("jb_announce_mode", "1", "Sets the in-chat playback announcement mode.  0 = no announce, 1 = announce first track of each selection list, 2 = announce every track for Public Stream and only first track for Private Streams, 3 = announce every track for Public and Private Streams.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);

	HookConVarChange(cv_db_tracks, SettingTracks);
	HookConVarChange(cv_db_options, SettingOptions);
	HookConVarChange(cv_db_streams, SettingStreams);
	HookConVarChange(cv_db_playlists, SettingPlaylists);
	// HookConVarChange(cv_db_log_users, SettingLogUsers);
	HookConVarChange(cv_db_log_usernames, SettingLogUsernames);
	HookConVarChange(cv_db_log_history, SettingLogHistory);
	HookConVarChange(cv_log_use, SettingStats);
	// HookConVarChange(cv_admin_flags_playall, SettingAdminPlayall);
	HookConVarChange(cv_admin_flags_settings, SettingAdminMenu);
	// HookConVarChange(cv_admin_flags_reserved, SettingAdminReserved);
	
	AutoExecConfig(true, "jukebox");
	
	// admin_flags_playall = AdminCvarToFlagBits(cv_admin_flags_playall);
	// admin_flags_reserved = AdminCvarToFlagBits(cv_admin_flags_reserved);

	num_clients = MaxClients;
	
	for(new i = 0; i < sizeof(results_storage); i++) {
		results_storage[i] = INVALID_HANDLE;
	}

	// Determine working folder for Jukebox
	BuildPath(Path_SM, result_folder, sizeof(result_folder), "%s", result_subfolder);

	// Prepare the input type KeyValue structure
	new String:queries[][][] = {{"search", "se"}, {"title", "ti"}, {"album", "al"}, {"artist", "ar"}, {"genre", "ge"}};
	new String:params[][][] = {{"volume", "vol"}};
	new String:commands[][][] = {{"all", "playall"}, {"loud", "strong"}, {"soft", "quiet"}, {"force", "force"}, {"queue", "qu"}};
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
		for(new j = 0; j < sizeof(commands[]); j++) {
			if(strlen(commands[i][j]) > 0) {
				KvJumpToKey(input_types, commands[i][j], true);
				KvSetString(input_types, "type", "c");
				KvSetString(input_types, "name", commands[i][0]);
				for(new k = 0; k < sizeof(admin); k++) {
					if(StrEqual(commands[i][0], admin[k])) {
						KvSetString(input_types, "admin", "1");
						break;
					}
				}
				KvGoBack(input_types);
			}
		}
	}
	
	KvRewind(input_types);

	// Create the plugin commands
	RegConsoleCmd ("sm_jukebox", Command_Jukebox, "Invokes the Jukebox music system.");
	RegConsoleCmd ("sm_jb", Command_Jukebox, "Invotes the Jukebox music system.");
	RegConsoleCmd("sm_volume", Command_Volume, "Use: sm_volume <value>.  Stores a playback volume level from 1 to 100%.");
	RegConsoleCmd("sm_jboff", Command_JbOff, "Stop music playback.");
	RegAdminCmd("sm_jballoff", Command_JbAllOff, ADMFLAG_CHAT, "Stop music playback for all players.");
	RegConsoleCmd("sm_eavesdrop", Command_Eavesdrop, "Use: sm_eavesdrop  <username>.  Join the most recently started music stream or a particular player's stream, if named.");

	// Retrieve global settings

	// Below are the default settings and their values, associated by array position.
	new String:settings_names[][] = {"popularity_datetime"};
	new settings_default[] = {0};
	settings_default[0] = GetTime(); // Insert current Unix datetime for 'popularity_datetime'

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
	
	// Prepare HUD syncrhonization item
	hud_sync = CreateHudSynchronizer();

	return;
}






public OnAdminMenuReady(Handle:topmenu) {
	if(admin_menu_object == INVALID_TOPMENUOBJECT && admin_menu == INVALID_HANDLE) {
		admin_menu = topmenu;
	}
	AddJbAdminMenu();
	
	return;
}



AddJbAdminMenu() {
	if(admin_menu != INVALID_HANDLE && admin_menu_object == INVALID_TOPMENUOBJECT) {
		new TopMenuObject:server_commands = FindTopMenuCategory(admin_menu, ADMINMENU_SERVERCOMMANDS);
		
		if(server_commands == INVALID_TOPMENUOBJECT) {
			LogError("Unable to find Admin Menu category '%s%' for Jukebox insertion.", ADMINMENU_SERVERCOMMANDS);
		} else {
			decl String:flag_string[32];
			GetConVarString(cv_admin_flags_settings, flag_string, sizeof(flag_string));
			new flags = ReadFlagString(flag_string);
			
			admin_menu_object = AddToTopMenu(admin_menu, "jukebox_sms", TopMenuObject_Item, JbAdminTop, server_commands, "jukebox_sms", flags);
		}
	}
	
	return;
}



RemoveJbAdminMenu() {
	if(admin_menu != INVALID_HANDLE && admin_menu_object != INVALID_TOPMENUOBJECT) {
		RemoveFromTopMenu(admin_menu, admin_menu_object);
		admin_menu_object = INVALID_TOPMENUOBJECT;
	}
	
	return;
}



public JbAdminTop(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		FormatEx(buffer, maxlength, "Jukebox Administation");
	} else if (action == TopMenuAction_SelectOption) {
		JbAdminMenu(param);
	}
}



JbAdminMenu(client) {
	decl String:display[128];
	new Handle:menu = CreateMenu(JbAdminMenuHandler);
	
	SetMenuTitle(menu, "Jukebox - Administration");
	SetMenuExitBackButton(menu, true);
	
	FormatMenuSettingBool(display, sizeof(display), cv_enabled, "Enable Jukebox");
	AddMenuItem(menu, "1", display); // jb_enabled
	if(GetConVarBool(cv_enabled)) {
		FormatMenuSettingBool(display, sizeof(display), cv_reserved, "Reserved Operation");
		AddMenuItem(menu, "2", display); // jb_reserved
		AddMenuItem(menu, "3", "Stop All Playback"); // sm_jballoff
	} else {
		AddMenuItem(menu, "2", "", ITEMDRAW_SPACER);
		AddMenuItem(menu, "3", "", ITEMDRAW_SPACER);
	}
	AddMenuItem(menu, "4", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "5", "Manage Features");
	/*
	if (allow_access) {
		AddMenuItem(menu, "5", "Manage Features");
	} else {
		AddMenuItem(menu, "5", "", ITEMDRAW_SPACER);
	}
	*/
	
	DisplayMenu(menu, client, menu_maxtime);
	
	return;
}



public JbAdminMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		decl String:item_string[2];
		new item;
		new bool:display_again;
		GetMenuItem(menu, position, item_string, sizeof(item_string));
		item = StringToInt(item_string);
		switch(item) {
			case 1: { // jb_enabled
				SetConVarBool(cv_enabled, !GetConVarBool(cv_enabled));
				display_again = true;
			} case 2: { // jb_reserved
				SetConVarBool(cv_reserved, !GetConVarBool(cv_reserved));
				display_again = true;
			} case 3: { // sm_jballoff
				JbAllOff(client);
				display_again = true;
			} case 5: {
				FeaturesMenu(client);
			}
		}
		if(display_again) {
			JbAdminMenu(client);
		}

	} else if(action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			if(admin_menu != INVALID_HANDLE) {
				RedisplayAdminMenu(admin_menu, client);
			}
		}
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}


FeaturesMenu(client) {
	new Handle:features_menu = CreateMenu(FeaturesMenuHandler);
	decl String:display[128];
	SetMenuTitle(features_menu, "Jukebox - Manage Features");
	SetMenuExitBackButton(features_menu, true);
	FormatMenuSettingInt(display, sizeof(display), cv_monitor_jboff_use, "Public Stream leaves until settings invitation");
	AddMenuItem(features_menu, "1", display); // jb_monitor_jboff_use
	FormatMenuSettingInt(display, sizeof(display), cv_announce_mode, "Playback Announce Mode");
	AddMenuItem(features_menu, "2", display); // jb_announce_mode
	FormatMenuSettingBool(display, sizeof(display), cv_playall_on_connect, "Join Public Stream on Connections");
	AddMenuItem(features_menu, "3", display); // jb_playall_on_connect
	FormatMenuSettingBool(display, sizeof(display), cv_advertisement, "Advertise Plugin on Join");
	AddMenuItem(features_menu, "4", display); // jb_advertisement
	FormatMenuSettingBool(display, sizeof(display), cv_motd_restart, "Restart Playback After MOTD");
	AddMenuItem(features_menu, "5", display); // jb_motd_restart
	FormatMenuSettingBool(display, sizeof(display), cv_log_use, "Log Playback Selections");
	AddMenuItem(features_menu, "6", display); // jb_log_use
	
	DisplayMenu(features_menu, client, menu_maxtime);
	
	return;
}


public FeaturesMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		decl String:item_string[2];
		new item;
		GetMenuItem(menu, position, item_string, sizeof(item_string));
		item = StringToInt(item_string);
		switch(item) {
			case 1: { // jb_monitor_jboff_use
				new value = GetConVarInt(cv_monitor_jboff_use);
				if(value >= 0 && value < 5) {
					value++;
				} else {
					value = 0;
				}
				SetConVarInt(cv_monitor_jboff_use, value);
			} case 2: {
				new value = GetConVarInt(cv_announce_mode);
				if(value >=  0 && value < 3) {
					value++;
				} else {
					value = 0;
				}
				SetConVarInt(cv_announce_mode, value);
			} case 3: { // jb_playall_on_connect
				SetConVarBool(cv_playall_on_connect, !GetConVarBool(cv_playall_on_connect));
			} case 4: { // jb_advertisement
				SetConVarBool(cv_advertisement, !GetConVarBool(cv_advertisement));
			} case 5: { // jb_motd_restart
				SetConVarBool(cv_motd_restart, !GetConVarBool(cv_motd_restart));
			} case 6: { // jb_log_use
				SetConVarBool(cv_log_use, !GetConVarBool(cv_log_use));
			}
		}
		FeaturesMenu(client);
	} else if(action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			JbAdminMenu(client);
		}
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}
	
	return;
}


FormatMenuSettingBool(String:output[], maxlength, Handle:convar, String:message[]) {
	if(GetConVarBool(convar)) {
		FormatEx(output, maxlength, "[X] %s", message);
	} else {
		FormatEx(output, maxlength, "[  ] %s", message);
	}
	
	return;
}


FormatMenuSettingInt(String:output[], maxlength, Handle:convar, String:message[], String:suffix[] = "") {
	new value = GetConVarInt(convar);
	if(value > 0) {
		FormatEx(output, maxlength, "[%d%s] %s", value, suffix, message);
	} else {
		FormatEx(output, maxlength, "[  ] %s", message);
	}
	
	return;
}


FormatMenuOptionBool(String:output[], maxlength, value, String:message[]) {
	if(value) {
		FormatEx(output, maxlength, "[X] %s", message);
	} else {
		FormatEx(output, maxlength, "[  ] %s", message);
	}
	
	return;
}


FormatMenuOptionInt(String:output[], maxlength, value, String:message[], String:suffix[] = "") {
	if(value > 0) {
		FormatEx(output, maxlength, "[%d%s] %s", value, suffix, message);
	} else {
		FormatEx(output, maxlength, "[  ] %s", message);
	}
	
	return;
}



public OnLibraryRemoved(const String:name[]) {
	if(StrEqual(name, "adminmenu")) {
		admin_menu = INVALID_HANDLE;
	}
}



public OnEventShutdown() {
	UnhookConVarChange(cv_db_tracks, SettingTracks);
	UnhookConVarChange(cv_db_options, SettingOptions);
	UnhookConVarChange(cv_db_streams, SettingStreams);
	UnhookConVarChange(cv_db_playlists, SettingPlaylists);
	// UnhookConVarChange(cv_db_log_users, SettingLogUsers);
	UnhookConVarChange(cv_db_log_usernames, SettingLogUsernames);
	UnhookConVarChange(cv_db_log_history, SettingLogHistory);
	UnhookConVarChange(cv_log_use, SettingStats);
	// UnhookConVarChange(cv_admin_flags_playall, SettingAdminPlayall);
	UnhookConVarChange(cv_admin_flags_settings, SettingAdminMenu);
	// UnhookConVarChange(cv_admin_flags_reserved, SettingAdminReserved);
}



public OnPluginEnd() {
	// Hault all music playback
	for(new i = 1; i <= num_clients; i++) {
		if(stream_memberships[i] > 0) {
			RemoveClient(i, true);
		}
	}

	// Clean up memory
	CloseHandle2(music_db);
	CloseHandle2(input_types);
	CloseHandle2(settings);
	CloseHandle2(hud_sync);
	CloseHandle2(cv_enabled);
	CloseHandle2(cv_base_url);
	CloseHandle2(cv_leech_password);
	CloseHandle2(cv_db_tracks);
	CloseHandle2(cv_db_options);
	CloseHandle2(cv_db_streams);
	CloseHandle2(cv_db_playlists);
	CloseHandle2(cv_volume_loud);
	CloseHandle2(cv_volume_soft);
	CloseHandle2(cv_popularity_decay_rate);
	CloseHandle2(cv_popularity_decay_interval);
	CloseHandle2(cv_advertisement);
	CloseHandle2(cv_monitor_jboff_use);
	CloseHandle2(cv_playall_on_connect);
	CloseHandle2(cv_motd_restart);
	CloseHandle2(cv_volume_min);
	for(new i = 0; i < sizeof(cv_options_defaults); i++) {
		CloseHandle2(cv_options_defaults[i]);
	}
	for(new i = 0; i < sizeof(volume_timers); i++) {
		if(volume_timer_enabled[i]) {
			volume_timer_enabled[i] = false;
			KillTimer(volume_timers[i]);
		}
	}
}



public OnConfigsExecuted() {
	num_clients = MaxClients;

	GetConVarString(cv_db_tracks, db_tracks, sizeof(db_tracks));
	GetConVarString(cv_db_options, db_options, sizeof(db_options));
	GetConVarString(cv_db_streams, db_streams, sizeof(db_streams));
	GetConVarString(cv_db_playlists, db_playlists, sizeof(db_playlists));
	// GetConVarString(cv_db_log_users, db_log_users, sizeof(db_log_users));
	GetConVarString(cv_db_log_usernames, db_log_usernames, sizeof(db_log_usernames));
	GetConVarString(cv_db_log_history, db_log_history, sizeof(db_log_history));
	
	// Test base_url and leech_password to remind the server operator to populate their values
	decl String:leech_password_test[32], String:base_url_test[128];
	GetConVarString(cv_leech_password, leech_password_test, sizeof(leech_password_test));
	GetConVarString(cv_base_url, base_url_test, sizeof(base_url_test));
	if(strlen(leech_password_test) == 0) {
		PrintToServer("[JB] WARNING - You must populate 'jb_base_url' in cfg/sourcemod/jukebox.cfg with the URL to Jukebox's base folder on your web server."); 
	}
	if(strlen(base_url_test) == 0) {
		PrintToServer("[JB] WARNING - You must populate 'jb_leech_password' in cfg/sourcemod/jukebox.cfg with the anti-leech password specified in settings.php on your web server.");
	}
	
	// Prepare MySQL database connection
	PrepareConnection();
	
	// If the admin menu is already up, add the Jukebox items
	new Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
	
	// Clean up stored search results
	for(new i = 0; i < sizeof(results_storage); i++) {
		RemoveResults(i);
	}

	return;
}



public OnMapEnd() {
	last_map_change = GetTime();
	
	return;
}



public OnClientPostAdminCheck(client) {
	if(IsFakeClient(client)) {
		return;
	}
	
	// Restore the user's stream data (if it exists)
	decl String:steam_id[25];
	new cell;
	
	// Use to pull user's custom settings
	LookupOptions(client);

	GetClientAuthString(client, steam_id, sizeof(steam_id));
	cell = FindStringInNaturalArray(disconnect_steam_ids, sizeof(disconnect_steam_ids), steam_id);
	if(cell >= 0 && PrepareConnection()) {
		// Check to see if the music stream still exists
		decl String:query[192];
		FormatEx(query, sizeof(query), "SELECT COUNT(*) AS 'count' FROM %s WHERE `stream_id` = %d", db_streams, disconnect_streams[cell]);
		
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, client);
		WritePackCell(datapack, cell);
		SQL_TQuery(music_db, Query_ConfirmStreamMembership, query, datapack);
	} else {
		stream_memberships[client] = 0;
		play_lock[client] = false;
		popularity_votes[client] = 0;
		now_volume[client] = 0;
	}
	
	jboff_count[client] = 0;
	first_connect[client] = true;
	
	if(GetConVarBool(cv_log_use)) {
		log_username_entry[client][0] = 0;
		log_username_entry[client][1] = 0;
		GetStatsUsernameNumber(client);
	}

	return;
}



public Query_ConfirmStreamMembership(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	new cell = ReadPackCell(datapack);
	CloseHandle(datapack);
	
	if(!IsClientInGame(client) || IsFakeClient(client)) {
		return;
	}
	
	if(result == INVALID_HANDLE) {
		LogError("Failed to perform stream check on user connection.  Error: %s", error);
	} else if(SQL_FetchRow(result) && SQL_FetchInt(result, 0) > 0) {
		stream_memberships[client] = disconnect_streams[cell];
		play_lock[client] = disconnect_locks[cell];
		popularity_votes[client] = disconnect_popularity[cell];
		now_volume[client] = disconnect_volume[cell];
	}
	ClearDisconnectData(cell);
	
	return;
}



public OnClientDisconnect(client) {
	if(IsFakeClient(client)) {
		return;
	}
	
	decl String:steam_id[25];

	// Save the user's stream settings in case of drop or map change
	GetClientAuthString(client, steam_id, sizeof(steam_id));
	if(stream_memberships[client] > 0) {
		new cell;
		cell = FindStringInNaturalArray(disconnect_steam_ids, sizeof(disconnect_steam_ids), steam_id);
		if(cell < 0) {
			cell = FindMinInArray(disconnect_time, sizeof(disconnect_time));
		}
		strcopy(disconnect_steam_ids[cell], sizeof(disconnect_steam_ids[]), steam_id);
		disconnect_streams[cell] = stream_memberships[client];
		disconnect_locks[cell] = play_lock[client];
		disconnect_popularity[cell] = popularity_votes[client];
		disconnect_time[cell] = GetTime();
		disconnect_volume[cell] = now_volume[client];
		disconnect_log_usernames[cell][0] = log_username_entry[client][0];
		disconnect_log_usernames[cell][1] = log_username_entry[client][1];
	}
	// Clean up stream data
	stream_memberships[client] = 0;
	play_lock[client] = false;
	popularity_votes[client] = 0;
	now_volume[client] = 0;
	log_username_entry[client][0] = 0;
	log_username_entry[client][1] = 0;
	
	// Delete user's stored results, if they exist
	RemoveResults(client);
	
	if(volume_timer_enabled[client]) {
		volume_timer_enabled[client] = false;
		KillTimer(volume_timers[client]);
	}

	return;
}



public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	
	if (!GetConVarBool(cv_enabled)) {
		return;
	}
	
	new client = GetEventInt(event, "userid");
	client = GetClientOfUserId(client);
	if(client <= 0) {
		return;
	}
	
	new team = GetEventInt(event, "team");
	
	if(PrepareConnection() && first_connect[client] && team >= 1 && team <= 3) {
		first_connect[client] = false;
		
		new Float:ad_delay = GetConVarFloat(cv_advertisement);
		
		if(ad_delay) {
			CreateTimer(ad_delay, DisplayAdvertisement, client);
		}
		
		if((stream_memberships[client] > 0 && GetConVarBool(cv_motd_restart)) || stream_memberships[client] < 0) {
			new clients_list[1];
			clients_list[0] = client;
			AddClients(abs(stream_memberships[client]), clients_list, 1, play_lock[client]);
		} else if (stream_memberships[client] == 0 && GetConVarBool(cv_playall_on_connect)) {
			decl String:query[384];
			// new Handle:result = INVALID_HANDLE;
			new playall;
			if(options[client][FindOption("playall")]) {
				playall = 1;
			} else {
				playall = 2;
			}
			FormatEx(query, sizeof(query), "SELECT st.`stream_id`, tr.`title`, tr.`artist`, tr.`album` FROM %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence` LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` WHERE st.`playall` >= %d ORDER BY st.`start_time` DESC LIMIT 1", db_streams, db_playlists, db_tracks, playall);
			SQL_TQuery(music_db, Query_JoinStreamOnConnect, query, client);
		}
	}
	
	return;
}


public Query_JoinStreamOnConnect(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to perform public stream check on connection.  Error: %s", error);
	} else if(SQL_FetchRow(result) && IsClientInGame(client) && !IsFakeClient(client)) {
		decl String:title[title_length], String:artist[artist_length], String:album[album_length];
		new stream_id;
		new clients_list[1];
		
		stream_id = SQL_FetchInt(result, 0);
		SQL_FetchString(result, 1, title, sizeof(title));
		SQL_FetchString(result, 2, artist, sizeof(artist));
		SQL_FetchString(result, 3, album, sizeof(album));
		
		clients_list[0] = client;
		AddClients(stream_id, clients_list, 1);
		
		if(GetConVarBool(cv_log_use)) {
			CreateLogStats(stream_id, clients_list, 1);
		}
		
		DisplayTrackInfo(clients_list, 1, title, artist, album);
		PrintToChat(client, "%c[JB]%c Joining a music stream already in progress.", cLightGreen, cDefault);
	}
	
	return;
}



public Action:DisplayAdvertisement(Handle:timer, any:client) {
	if(IsClientInGame(client) && !IsFakeClient(client)) {
		PrintToChat(client, "%c[JB]%c This server is running %cJukebox for Source%c, a music streaming system.  Type %c!jb%c to access the library, adjust playback settings and receive additional help.", cLightGreen, cDefault, cGreen, cDefault, cGreen, cDefault);
	}
	
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

/*
public SettingLogUsers(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_log_users, false) != 0)
	{
		strcopy(db_log_users, sizeof(db_log_users), newValue);
	}
}
*/

public SettingLogUsernames(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_log_usernames, false) != 0)
	{
		strcopy(db_log_usernames, sizeof(db_log_usernames), newValue);
	}
}

public SettingLogHistory(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(newValue, db_log_history, false) != 0)
	{
		strcopy(db_log_history, sizeof(db_log_history), newValue);
	}
}


public SettingStats(Handle:convar, const String:oldValue[], const String:newValue[]) {
	new value = StringToInt(newValue);
	if(value) {
		for(new i = 1; i <= num_clients; i++) {
			if(IsClientConnected(i) && !IsFakeClient(i)) {
				GetStatsUsernameNumber(i);
			}
		}
	} else {
		for(new i = 1; i <= num_clients; i++) {
			log_username_entry[i][0] = 0;
			log_username_entry[i][1] = 0;
		}
	}
}



public SettingAdminMenu(Handle:convar, const String:oldValue[], const String:newValue[]) {
	RemoveJbAdminMenu();
	AddJbAdminMenu();
}


/*
public SettingAdminPlayall(Handle:convar, const String:oldValue[], const String:newValue[]) {
	admin_flags_playall = AdminCvarToFlagBits(convar);
}



public SettingAdminReserved(Handle:convar, const String:oldValue[], const String:newValue[]) {
	admin_flags_reserved = AdminCvarToFlagBits(convar);
}
*/

new conn_last_init = 0;
bool:PrepareConnection() {
	if(music_db != INVALID_HANDLE) {
		return true;
	} else {
		if(GetTime() - conn_last_init > 10) {
			conn_last_init = GetTime();
			
			decl String:conn_name[128];
			GetConVarString(cv_db_conn_name, conn_name, sizeof(conn_name));
			if(strlen(conn_name) > 0) {
				SQL_TConnect(Post_Connect, conn_name);
			} else {
				SQL_TConnect(Post_Connect, "default");
			}
		}
		return false;
	}
}



public Post_Connect(Handle:owner, Handle:conn, const String:error[], any:data) {
	if(conn == INVALID_HANDLE) {
		PrintToServer("[JB] Failed to connect to SQL database.  Error: %s", error);
		LogError("Failed to connect to SQL database.  Error: %s", error);
	} else {
		music_db = conn;
		
		decl String:query[128];
		
		// Clean out the "stream" MySQL tables
		FormatEx(query, sizeof(query), "TRUNCATE TABLE %s", db_streams);
		SQL_TQuery(music_db, Query_TruncateStreams, query, _, DBPrio_High);
		
		FormatEx(query, sizeof(query), "TRUNCATE TABLE %s", db_playlists);
		SQL_TQuery(music_db, Query_TruncatePlaylists, query, _, DBPrio_High);
		
		// Determine the difference in the clocks between MySQL and the game server
		SQL_TQuery(music_db, Query_TimeStamp, "SELECT UNIX_TIMESTAMP() AS time", _, DBPrio_Low);
		
		// Apply popularity depreciation, if needed
		new popularity_datetime, decay_interval;
		new now_datetime = GetTime();
		popularity_datetime = KvGetNum(settings, "popularity_datetime");
		decay_interval = GetConVarInt(cv_popularity_decay_interval);
		
		if(now_datetime > (popularity_datetime + decay_interval)) {
			new decay_rate, num_intervals;
			new Float:decay;
			decay_rate = GetConVarInt(cv_popularity_decay_rate);
			num_intervals = (now_datetime - popularity_datetime)/decay_interval; // Integer division, remainder is truncated
			decay = Pow(1.0 - decay_rate/100.0, 1.0*num_intervals);
			FormatEx(query, sizeof(query), "UPDATE %s SET popularity = popularity*%f", db_tracks, decay);
			SQL_TQuery(music_db, Query_UpdatePopularity, query, _, DBPrio_Low);
		}
		
		// Lookup each player's options
		for (new i = 1; i <= num_clients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i)) {
				LookupOptions(i);
			}
		}
		
		// Set up stats tracking
		if(GetConVarBool(cv_log_use)) {
			for(new i = 1; i <= num_clients; i++) {
				GetStatsUsernameNumber(i);
			}
		}
	}
	
	return;
}



public Query_TimeStamp(Handle:owner, Handle:result, const String:error[], any:data) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to get timestamp from SQL server.  Error: %s", error);
		time_offset = 0;
	} else if(!SQL_FetchRow(result)) {
		time_offset = 0;
	} else {
		time_offset = SQL_FetchInt(result, 0) - GetTime();
	}
}



public Query_TruncateStreams(Handle:owner, Handle:result, const String:error[], any:data) {
	if(strlen(error) > 0) {
		LogError("Failed to clear streams database.  Error: %s", error);
	}
	
	decl String:query[96];
	FormatEx(query, sizeof(query), "ALTER TABLE %s AUTO_INCREMENT = 1", db_streams);
	SQL_TQuery(music_db, Query_ResetIncrement, query, _, DBPrio_High);
	
	return;
}



public Query_ResetIncrement(Handle:owner, Handle:result, const String:error[], any:data) {
	if(strlen(error) > 0) {
		LogError("Failed to adjust stream ID incrementer.  Error: %s", error);
	}
}



public Query_TruncatePlaylists(Handle:owner, Handle:result, const String:error[], any:data) {
	if(strlen(error) > 0) {
		LogError("Failed to clear streamed tracks database.  Error: %s", error);
	}
	
	return;
}



public Query_UpdatePopularity(Handle:owner, Handle:result, const String:error[], any:data) {
	if(strlen(error) > 0) {
		LogError("Failed to perform popularity score depretiation.  Error: %s", error);
	} else {
		new popularity_datetime = KvGetNum(settings, "popularity_datetime");
		new decay_interval = GetConVarInt(cv_popularity_decay_interval);
		new num_intervals = (GetTime() - popularity_datetime)/decay_interval;
		popularity_datetime += decay_interval*num_intervals;
		KvSetNum(settings, "popularity_datetime", popularity_datetime);
		UpdateGlobalSettings();		
	}
	
	return;
}



UpdateGlobalSettings() {
	decl String:filepath_settings[192];
	FormatEx(filepath_settings, sizeof(filepath_settings), "%s%s", result_folder, data_file);
	if(!KeyValuesToFile(settings, filepath_settings)) {
		PrintToServer("[JB] WARNING - Failed to apply global configuration update to file '%s'.", filepath_settings);
		LogError("WARNING - Failed to apply global configuration update to file '%s'.", filepath_settings);
		return false;
	} else {
		PrintToServer("[JB] Global configuration file updated with new settings.");
		LogAction(0, -1, "Global configuration file updated with new settings.");
	}

	return true;
}



MultipleTest(&multiple) {
	if(multiple) {
		return true;
	} else {
		multiple = true;
		return false;
	}
}



LookupOptions(client) {
	if(!PrepareConnection()) {
		PrintToConsole(client, "[JB] Database connection is unavailable.  Using default option settings.");
		for(new i = 0; i < sizeof(options_names); i++) {
			options[client][i] = GetConVarInt(cv_options_defaults[i]);
		}
		return false;
	}
	
	decl String:steam_id[25];
	decl String:query[320];
	decl String:query_select[20*sizeof(options_names)];
	// new bool:multiple = false;

	if(!GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		PrintToConsole(client, "[JB] Failed to retrieve your Steam ID.  Custom settings are unavailable.");
		LogError("Failed to retrieve Steam ID for user %N.", client);
		for(new i = 0; i < sizeof(options_names); i++) {
			options[client][i] = GetConVarInt(cv_options_defaults[i]);
		}
		return false;
	}
	ImplodeStrings(options_names, sizeof(options_names), ", ", query_select, sizeof(query_select));
	FormatEx(query, sizeof(query), "SELECT %s FROM %s WHERE steamid = '%s' LIMIT 1", query_select, db_options, steam_id);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, client);
	WritePackString(datapack, steam_id);
	SQL_TQuery(music_db, Query_GetOptions, query, datapack, DBPrio_High);
	
	return true;
}


public Query_GetOptions(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	decl String:steam_id[25];
	ReadPackString(datapack, steam_id, sizeof(steam_id));
	CloseHandle(datapack);
	
	if(!IsClientInGame(client) || IsFakeClient(client)) {
		// End
	}	else if(result == INVALID_HANDLE) {
		if(IsClientInGame(client) && !IsFakeClient(client)) {
			PrintToConsole(client, "[JB] Settings retrieval failed.  Custom settings are unavailable.");
			for(new i = 0; i < sizeof(options_names); i++) {
				options[client][i] = GetConVarInt(cv_options_defaults[i]);
			}
		}
		LogError("SQL query failed during volume settings look-up.  Error: %s", error);
	} else if(SQL_FetchRow(result)) {
		for(new i = 0; i < sizeof(options_names); i++) {
			options[client][i] = SQL_FetchInt(result, i);
		}
	} else {
		decl String:query[256];
		decl String:query_values[96];
		decl String:query_select[160];
		new bool:multiple = false;
		for(new i = 0; i < sizeof(options_names); i++) {
			if(MultipleTest(multiple)) {
				Format(query_values, sizeof(query_values), "%s, %d", query_values, GetConVarInt(cv_options_defaults[i]));
			} else {
				FormatEx(query_values, sizeof(query_values), "%d", GetConVarInt(cv_options_defaults[i]));
			}
		}
		ImplodeStrings(options_names, sizeof(options_names), ", ", query_select, sizeof(query_select));
		FormatEx(query, sizeof(query), "INSERT INTO %s (steamid, %s) VALUES ('%s', %s)", db_options, query_select, steam_id, query_values);
		SQL_TQuery(music_db, Query_NewOptions, query, client, DBPrio_Low);
	}
	
	return;
}



public Query_NewOptions(Handle:owner, Handle:result, const String:error[], any:client) {
	if(strlen(error) > 0) {
		LogError("Failed to add new user to volume setting database.  Error: %s", error);
	}
	
	return;
}



bool:SystemLaunch(client, String:args_line[]) {

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
			MakeSearchMenu(client, arguments);
		}
	}
	CloseHandle2(arguments);
	return true;
}



bool:MakeSearchMenu(const client, Handle:new_arguments = INVALID_HANDLE, selection_page = 0) {
	decl String:query[2048];
	new Handle:arguments = CreateKeyValues("Arguments"), Handle:history = INVALID_HANDLE;
	if(new_arguments == INVALID_HANDLE) {
		history = GetQueryHistory(client);
		decl String:count_string[4];
		KvGetString(history, "count", count_string, sizeof(count_string));
		if(KvJumpToKey(history, count_string)) {
			KvCopySubkeys(history, arguments);
			KvGoBack(history);
		} else {
			CloseHandle2(arguments);
			CloseHandle2(history);
			MainMenu(client);
			return true;
		}
	} else {
		KvCopySubkeys(new_arguments, arguments);
		history = GetQueryHistory(client, arguments, selection_page);
	}

	if(!KvSQL(query, sizeof(query), arguments)) {
		LogError("Jukebox: Failed to build MySQL query from KeyValue data.");
		return false;
	}
	// Store old queries
	new Handle:kv_menu = CreateKeyValues("Menu Items");
	KvJumpToKey(kv_menu, "query", true);
	KvCopySubkeys(history, kv_menu);
	KvGoBack(kv_menu);
	CloseHandle2(history);
	
	SaveResults(client, kv_menu);
	CloseHandle2(kv_menu);

	SQL_TQuery(music_db, Query_MusicDatabaseSearch1, query, client);

	return true;
}



AddQueryString(Handle:queries, const String:key[], const String:value[]) {
	if(!KvJumpToKey(queries, key, true)) {
		LogError("Adding data '%s' for %s failed!", value, key);
		return false;
	}
	KvSetString(queries, "data", "q");
	KvSetString(queries, "type", "string");
	KvSetString(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddQueryNum(Handle:queries, const String:key[], value) {
	if(!KvJumpToKey(queries, key, true)) {
		LogError("Adding data %d for %s failed!", value, key);
		return false;
	}
	KvSetString(queries, "data", "q");
	KvSetString(queries, "type", "int");
	KvSetNum(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddParamString(Handle:queries, const String:key[], const String:value[]) {
	if(!KvJumpToKey(queries, key, true)) {
		LogError("Adding data '%s' for %s failed!", value, key);
		return false;
	}
	KvSetString(queries, "data", "p");
	KvSetString(queries, "type", "string");
	KvSetString(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddParamNum(Handle:queries, const String:key[], value) {
	if(!KvJumpToKey(queries, key, true)) {
		LogError("Adding data %d for %s failed!", value, key);
		return false;
	}
	KvSetString(queries, "data", "p");
	KvSetString(queries, "type", "int");
	KvSetNum(queries, "entry", value);
	KvGoBack(queries);
	return true;
}


AddCommand(Handle:queries, const String:key[]) {
	if(!KvJumpToKey(queries, key, true)) {
		LogError("Adding data for %s failed!", key);
		return false;
	}
	KvSetString(queries, "data", "c");
	KvSetString(queries, "type", "null");
	KvGoBack(queries);
	return true;
}


LookupCommand(Handle:queries, const String:key[]) {
	if(KvJumpToKey(queries, key)) {
		KvGoBack(queries);
		return true;
	} else {
		return false;
	}
}


LookupParamNum(Handle:queries, const String:key[], defvalue=0) {
	if(KvJumpToKey(queries, key)) {
		new value = KvGetNum(queries, "entry", defvalue);
		KvGoBack(queries);
		return value;
	} else {
		return defvalue;
	}
}


LookupParamString(Handle:queries, const String:key[], String:value[], maxlength, const String:defvalue[]="") {
	if(KvJumpToKey(queries, key)) {
		KvGetString(queries, "entry", value, maxlength, defvalue);
		KvGoBack(queries);
		return true;
	} else {
		strcopy(value, maxlength, defvalue);
		return false;
	}
}



GetQueryGroups(Handle:args) {
	new query_groups;

	if(KvJumpToKey(args, "groups")) {
		query_groups = KvGetNum(args, "entry");
		KvGoBack(args);
		if(query_groups > 4) {
			query_groups = 4;
		}
	} else {
		query_groups = 4;
	}

	return query_groups;
}



CopyLastQuery(Handle:source, Handle:destination, const String:item[], remove_search) {
	if(strlen(item) > 0) {
		KvRewind(source);
	}
	if (KvJumpToKey(source, "query")) {
		new count = KvGetNum(source, "count", 0);
		decl String:count_string[4];
		IntToString(count, count_string, sizeof(count_string));
		if(KvJumpToKey(source, count_string)) {
			KvCopySubkeys(source, destination);
			KvGoBack(source);
	
			if(remove_search >= 1) {
				new String:remove_items[][] = {"search", "groups", "start", "selection_page"};
				for(new i = 0; i < sizeof(remove_items); i++) {
					if(KvJumpToKey(destination, remove_items[i])) {
						KvDeleteThis(destination);
						KvRewind(destination);
					}
				}
			}
			if(remove_search == 2) {
				decl String:key_data[2];
				new bool:loop_again = true;
				if(KvGotoFirstSubKey(destination)) {
					while(loop_again) {
						KvGetString(destination, "data", key_data, sizeof(key_data));
						if(StrEqual(key_data, "q")) {
							if(KvDeleteThis(destination) == -1) {
								loop_again = false;
							}
						} else {
							if(!KvGotoNextKey(destination)) {
								KvGoBack(destination);
								loop_again = false;
							}
						}
					}
				}
			}
		} else {
			LogError("Unable to find query #%d in query history.", count);
			return false;
		}
	} else {
		LogError("Failed to retrieve previous query arguments.");
		return false;
	}
	KvRewind(source);
	
	if(strlen(item) > 0) {
		if(!KvJumpToKey(source, item)) {
			LogError("Jukebox: Failed to return to item #%s.", item);
			return false;
		}
	}

	return true;
}



MusicMenuResultParse(client, String:item[], selection_page = 0) {
	new Handle:result = INVALID_HANDLE;
	new Handle:result_queries = CreateKeyValues("New Query");
	new bool:playback = false;

	result = GetResults(client);
	if(result == INVALID_HANDLE) {
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
		CopyLastQuery(result, result_queries, "", 0);
		// AddParamNum(result_queries, "lev", 3);
		// AddParamNum(result_queries, "groups", 4);
		if(StrEqual(item, "rand")) {
			AddCommand(result_queries, "random");
			AddParamNum(result_queries, "limit", 1);
		} else if(StrEqual(item, "rana")) {
			AddCommand(result_queries, "random");
		}
		playback = true;
	} else {
		KvRewind(result);
		if(!KvJumpToKey(result, item)) {
			LogError("Failed to look up menu selection %s from result set.", item);
			CloseHandle2(result);
			CloseHandle2(result_queries);
			return false;
		}
		decl String:type[16];
		KvGetString(result, "type", type, sizeof(type));
		if(StrEqual(type, "next")) {
			new start;
			CopyLastQuery(result, result_queries, item, 0);
			start = LookupParamNum(result_queries, "start");
			start += SEARCH_MAX;
			AddParamNum(result_queries, "start", start);
		} else if (StrEqual(type, "title")) {
			new id = KvGetNum(result, "id");
			CopyLastQuery(result, result_queries, item, 2);
			AddQueryNum(result_queries, "id", id);
			playback = true;
		} else if (StrEqual(type, "album")) {
			decl String:album[album_length];
			CopyLastQuery(result, result_queries, item, 1);
			KvGetString(result, "album", album, album_length);
			AddQueryString(result_queries, "album", album);
			AddParamNum(result_queries, "lev", 3);
			AddParamNum(result_queries, "groups", 4);
		} else if (StrEqual(type, "artist")) {
			decl String:artist[artist_length];
			CopyLastQuery(result, result_queries, item, 1);
			KvGetString(result, "artist", artist, artist_length);
			AddQueryString(result_queries, "artist", artist);
			AddParamNum(result_queries, "lev", 2);
			AddParamNum(result_queries, "groups", 4);
		} else if (StrEqual(type, "genre")) {
			decl String:genre[artist_length];
			CopyLastQuery(result, result_queries, item, 1);
			KvGetString(result, "genre", genre, artist_length);
			AddQueryString(result_queries, "genre", genre);
			AddParamNum(result_queries, "lev", 1);
			AddParamNum(result_queries, "groups", 4);
		} else {
			CloseHandle2(result);
			CloseHandle2(result_queries);
			return false;
		}
	}

	// KvRewind(result_queries);
	
	if(playback) {
		PlayMusic(client, result_queries);
	} else {
		MakeSearchMenu(client, result_queries, selection_page);
	}
	CloseHandle2(result);
	CloseHandle2(result_queries);

	return true;
}


Handle:GetQueryHistory(client, Handle:new_query = INVALID_HANDLE, selection_page = 0) {
	new Handle:source = GetResults(client);
	new Handle:history = CreateKeyValues("History");
	KvRewind(source);
	if(KvJumpToKey(source, "query")) {
		KvCopySubkeys(source, history);
		KvGoBack(source);
	}
	if(new_query != INVALID_HANDLE) {
		AddMenuQuery(history, new_query, selection_page);
	}
	CloseHandle(source);

	return history;
}



AddMenuQuery(Handle:history, Handle:query, selection_page = 0) {
	new count = KvGetNum(history, "count", 0);
	decl String:entry_string[4];
	if(selection_page > 0) {
		IntToString(count, entry_string, sizeof(entry_string));
		if(KvJumpToKey(history, entry_string)) {
			AddParamNum(history, "selection_page", selection_page);
			KvGoBack(history);
		} else {
			LogError("Could not find query entry #%d to add selection item #%d", count, selection_page);
		}
	}
	IntToString(++count, entry_string, sizeof(entry_string));
	KvSetNum(history, "count", count);
	if(!KvJumpToKey(history, entry_string, true)) {
		LogError("Unable to create new query history entry #%d", count);
		return false;
	} else {
		KvCopySubkeys(query, history);
		KvGoBack(history);
		return true;
	}
}



public MusicMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		decl String:info[16];
		new selection_page = GetMenuSelectionPosition();

		if(GetMenuItem(menu, position, info, sizeof(info))) {
			MusicMenuResultParse(client, info, selection_page);
		} else {
			return false;
		}
	} else if (action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			MusicMenuGoBack(client);
		} else {
			RemoveResults(client);
		}
	} else if (action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



MusicMenuGoBack(client) {
	new Handle:history = GetQueryHistory(client);
	new count = KvGetNum(history, "count", 0);
	if(count > 0) {
		decl String:count_string_current[4];
		IntToString(count--, count_string_current, sizeof(count_string_current));
		if(!KvJumpToKey(history, count_string_current) || !KvDeleteThis(history)) {
			LogError("Failed to delete query history entry #%s", count_string_current);
		}
		KvRewind(history);
		KvSetNum(history, "count", count);
		
		new Handle:menu_package = CreateKeyValues("Menu Package");
		KvJumpToKey(menu_package, "query", true);
		KvCopySubkeys(history, menu_package);
		KvGoBack(menu_package);
		SaveResults(client, menu_package);
		CloseHandle2(menu_package);
	}
	if(count > 0) {
		MakeSearchMenu(client);
	} else {
		MainMenu(client);
	}
	CloseHandle(history);
	
	return true;
}



KvSQL(String:query_out[], const maxlength, const Handle:args) {
	new bool:multiple = false;
	new query_value, query_start, query_level, query_limit, query_groups;

	new String:query_types[][] = {"genre", "artist", "album", "title"};
	decl String:query_order[36];

	// Pull the query level
	query_start = LookupParamNum(args, "start");
	query_level = LookupParamNum(args, "lev");

	// Pull the query group
	query_groups = GetQueryGroups(args);

	// Prepare LIMIT clause
	query_limit = LookupParamNum(args, "limit", SEARCH_MAX);

	// Look for a special ORDER case
	if(LookupCommand(args, "random")) {
		strcopy(query_order, sizeof(query_order), "RAND()");
	} else {
		LookupParamString(args, "order", query_order, sizeof(query_order), "match_type, subsort, match_value");
	}

	decl String:query_select_array[query_groups - query_level][512];
	decl String:query_where[512];
	query_where[0] = '\0';

	// Build the WHERE clause
	if(KvGotoFirstSubKey(args)) {
		decl String:query_string[256];
		decl String:query_string_esc[2*sizeof(query_string)+1];
		decl String:query_data[4];
		decl String:query_type[8];
		decl String:name[16];

		do {
			KvGetString(args, "data", query_data, sizeof(query_data));
			if(StrEqual(query_data, "q")) {
				if(!KvGetSectionName(args, name, sizeof(name))) {
					return false;
				}
				if(MultipleTest(multiple)) {
					Format(query_where, sizeof(query_where), "%s AND ", query_where);
				} else {
					strcopy(query_where, sizeof(query_where), " WHERE ");
				}
				if(StrEqual(name, "search")) { // Special case for the "search" command
					KvGetString(args, "entry", query_string, sizeof(query_string));
					ReplaceString(query_string, sizeof(query_string), " ", "%");
					SQL_EscapeString(music_db, query_string, query_string_esc, sizeof(query_string_esc));
					Format(query_where, sizeof(query_where), "%sgroup_replace_target LIKE \"%%%s%%\"", query_where, query_string_esc);
				} else { // Normal case for all other commands
					KvGetString(args, "type", query_type, sizeof(query_type));
					if(StrEqual(query_type, "string")) {
						KvGetString(args, "entry", query_string, sizeof(query_string));
						SQL_EscapeString(music_db, query_string, query_string_esc, sizeof(query_string_esc));
						Format(query_where, sizeof(query_where), "%s%s = \"%s\"", query_where, name, query_string_esc);
					} else if(StrEqual(query_type, "int")) {
						query_value = KvGetNum(args, "entry");
						Format(query_where, sizeof(query_where), "%s%s = %d", query_where, name, query_value);
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

		if (i == sizeof(query_types) - 1) {
			strcopy(select_list_array[sizeof(query_types)], sizeof(select_list_array[]), "id");
		} else {
			strcopy(select_list_array[sizeof(query_types)], sizeof(select_list_array[]), "NULL AS id");
		}
		if(i == sizeof(query_types) - 1 && query_level == sizeof(query_types) - 1) {
			strcopy(select_list_array[sizeof(query_types) + 1], sizeof(select_list_array[]), "track AS subsort");
		} else {
			strcopy(select_list_array[sizeof(query_types) + 1], sizeof(select_list_array[]), "NULL AS subsort");
		}
		ImplodeStrings(select_list_array, sizeof(select_list_array), ", ", select_list, sizeof(select_list));
		FormatEx(query_select_array[i - query_level], 512, "SELECT DISTINCT %d AS match_type, %s AS match_value, %s FROM %s%s", i, query_types[i], select_list, db_tracks, query_where);
		ReplaceString(query_select_array[i - query_level], 512, "group_replace_target", query_types[i]);
	}

	ImplodeStrings(query_select_array, query_groups - query_level, ") UNION (", query_out, maxlength);

	// Write MySQL string
	Format(query_out, maxlength, "(%s) ORDER BY %s LIMIT %d,%d", query_out, query_order, query_start, query_limit);

	return true;
}



public Query_MusicDatabaseSearch1(Handle:owner, Handle:result, const String:error[], any:client) {
	if (result == INVALID_HANDLE) {
		LogError("Main SQL search query failed.   Error: %s", error);
		RemoveResults(client);
	} else if (!IsClientInGame(client) || IsFakeClient(client)) {
		RemoveResults(client);
		// End
	} else if (SQL_GetRowCount(result) == 0) {
		PrintToChat(client, "%c[JB]%c Query returned no results.", cLightGreen, cDefault);
		RemoveResults(client);
	} else {

		// PROCESS RESULTS
		new match_type_column, match_type;
		new id_column;
		new entry_count;
		new bool:seek_more = false;
		decl String:sql_string[256];
		new sql_int;
		decl String:entry_count_string[4];
		new String:query_types[][] = {"genre", "artist", "album", "title"};
	
		entry_count = 0;
	
		new field_ids[sizeof(query_types)];
		for (new j = 0; j < sizeof(query_types); j++) {
			if(!SQL_FieldNameToNum(result, query_types[j], field_ids[j])) {
				field_ids[j] = -1;
			}
			SQL_FieldNameToNum(result, "id", id_column);
			SQL_FieldNameToNum(result, "match_type", match_type_column);
		}
		
		new Handle:kv_menu = GetResults(client);
		while (SQL_FetchRow(result)) {
			IntToString(++entry_count, entry_count_string, sizeof(entry_count_string));
			KvJumpToKey(kv_menu, entry_count_string, true);
			match_type = SQL_FetchInt(result, match_type_column);
			KvSetString(kv_menu, "type", query_types[match_type]);
			if(match_type == sizeof(query_types)-1) {
				sql_int = SQL_FetchInt(result, id_column);
				KvSetNum(kv_menu, "id", sql_int);
			}
	
			for(new j = 0; j <= match_type; j++) {
				if(field_ids[j] >= 0 &&	SQL_FetchString(result, field_ids[j], sql_string, sizeof(sql_string))) {
					KvSetString(kv_menu, query_types[j], sql_string);
				}
			}
			KvGoBack(kv_menu);
		}
		if(entry_count >= SEARCH_MAX) {
			seek_more = true;
		}
	
	
		if(seek_more) {
			IntToString(++entry_count, entry_count_string, sizeof(entry_count_string));
			KvJumpToKey(kv_menu, entry_count_string, true);
			KvSetString(kv_menu, "type", "next");
			KvGoBack(kv_menu);
		}
		KvRewind(kv_menu);
		
		new Handle:menu = CreateMenu(MusicMenuHandler);
		if(KvToMusicMenu(client, kv_menu, menu)) {
			SaveResults(client, kv_menu);
			CloseHandle2(kv_menu);
		} else {
			LogError("Music Menu creation failed!");
			CloseHandle2(kv_menu);
			RemoveResults(client);
		}
	}

	return;
}



KvToMusicMenu(client, Handle:kv_menu, Handle:menu) {
	SetMenuTitle(menu, "Jukebox - Make a Selection");
	SetMenuExitBackButton(menu, true);
	
	// Special functions
	new String:inst_types[][][] = {{"rand", "Play Random Track"}, {"all", "Play All Tracks"}, {"rana", "Play All Tracks in Random Order"}};
	new last_selection = 1;
	
	if(KvJumpToKey(kv_menu, "query")) {
		decl String:count_string[4];
		KvGetString(kv_menu, "count", count_string, sizeof(count_string));
		if(KvJumpToKey(kv_menu, count_string)) {
			last_selection = LookupParamNum(kv_menu, "selection_page", 0);
			new groups = LookupParamNum(kv_menu, "groups");
			if(groups == 0 || groups == 4) {
				for(new i = 0; i < sizeof(inst_types); i++) {
					AddMenuItem(menu, inst_types[i][0], inst_types[i][1]);
				}
			}
			KvGoBack(kv_menu);
		}
		KvGoBack(kv_menu);
	}

	decl String:keyname[16];
	decl String:type[16];
	decl String:title[title_length];
	decl String:album[album_length];
	decl String:artist[artist_length];
	decl String:description[128];
	
	KvRewind(kv_menu);
	if(!KvJumpToKey(kv_menu, "1")) {
		PrintToChat(client, "%c[JB]%c  No results!", cLightGreen, cDefault);
		return false;
	}
	do {
		KvGetSectionName(kv_menu, keyname, sizeof(keyname));
		KvGetString(kv_menu, "type", type, sizeof(type));
		if (StrEqual(type, "title")) {
			KvGetString(kv_menu, "title", title, title_length);
			KvGetString(kv_menu, "artist", artist, artist_length);
			if(strlen(artist) > 0) {
					FormatEx(description, sizeof(description), "\"%s\" by %s", title, artist);
			} else {
				FormatEx(description, sizeof(description), "\"%s\"", title);
			}
		} else if (StrEqual(type, "artist")) {
			KvGetString(kv_menu, "artist", artist, artist_length);
			if(strlen(artist) == 0) {
				strcopy(artist, sizeof(artist), "(blank)");
			}
			FormatEx(description, sizeof(description), "Artist: %s", artist);
		} else if (StrEqual(type, "album")) {
			KvGetString(kv_menu, "album", album, album_length);
			if(strlen(album) == 0) {
				strcopy(album, sizeof(album), "(blank)");
			}
			FormatEx(description, sizeof(description), "Album: %s", album);
		} else if (StrEqual(type, "genre")) {
			KvGetString(kv_menu, "genre", album, album_length);
			if(strlen(album) == 0) {
				strcopy(album, sizeof(album), "(blank)");
			}
			FormatEx(description, sizeof(description), "Genre: %s", album);
		} else if (StrEqual(type, "next")) {
			strcopy(description, sizeof(description), "Continue browsing...");
		} else {
			LogError("Jukebox: Error adding menu item!");
			return false;
		}
		AddMenuItem(menu, keyname, description);
	} while (KvGotoNextKey(kv_menu));
	KvRewind(kv_menu);
	
	return DisplayMenuAtItem(menu, client, last_selection, menu_maxtime);
}



ParseCommandLine(client, String:args_line[], Handle:arguments) {
	#define query_default "search"
	new start_index = 0;
	new bool:multiple = false;
	new bool:query_test = false;
	new index_temp = 0;
	decl String:query_id[16];
	decl String:query_string[256];
	decl String:arg_name[12];
	decl String:arg_type[4];
	decl String:admin_check[2];
	new bool:admin_block;
	new param_num;

	if (args_line[0] == '"') {
		start_index = 1;
		new args_length = strlen(args_line);
		if (args_line[args_length - 1] == '"') {
			args_line[args_length - 1] = '\0';
		}
	}

	KvRewind(arguments);
	KvRewind(input_types);
	while (start_index >= 0) {
		admin_block = false;
		TrimString(args_line[start_index]);

		if (!multiple && StrContains(args_line[start_index], "-") != 0) {
			strcopy(arg_name, sizeof(arg_name), query_default);
			strcopy(arg_type, sizeof(arg_type), "q");
			MultipleTest(multiple);
		} else {
			if (!MultipleTest(multiple)) {
				start_index++;
			}
			index_temp = SplitString(args_line[start_index], " ", query_id, sizeof(query_id));
			if(index_temp < 0) {
				strcopy(query_id, sizeof(query_id), args_line[start_index]);
				start_index = -1;
				query_string[0] = '\0';
			} else {
				start_index += index_temp - 1;
			}
			if(!KvJumpToKey(input_types, query_id)) {
				if (client != 0) {
					PrintToChat(client, "%c[JB]%c '%s' is an invalid command, halting.", cLightGreen, cDefault, query_id);
				}
				PrintToConsole(client, "[JB] '%s' is an invalid command.", query_id);
				return -1;
			}
			KvGetString(input_types, "name", arg_name, sizeof(arg_name));
			KvGetString(input_types, "admin", admin_check, sizeof(admin_check));

			if(!StrEqual(admin_check, "") && !PermissionCheck(client, cv_admin_flags_playall)) {
				admin_block = true;
				PrintToChat(client, "%c[JB]%c Command '%s' is a reserved command.  It has been ignored.", cLightGreen, cDefault, arg_name);
			}

			if(!admin_block) {
				KvGetString(input_types, "type", arg_type, sizeof(arg_type));

				if (StrEqual(arg_name, "") && StrEqual(arg_type, "")) {
					LogError("Error retrieving operation instructions for input argument '%s'.", query_id);
					return -1;
				}
			}
			KvRewind(input_types);
		}
		if(start_index >= 0 && index_temp >= 0) {
			index_temp = SplitString(args_line[start_index], " -", query_string, sizeof(query_string));
			if(index_temp < 0) {
				strcopy(query_string, sizeof(query_string), args_line[start_index]);
				start_index = -1;
			} else {
				start_index += index_temp;
			}
		}

		if(!admin_block) {
			TrimString(query_string);
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
						PrintToChat(client, "%c[JB]%c Input '%s' is not valid for parameter '%s', halting.", cLightGreen, cDefault, query_string, arg_name);
					}
					PrintToConsole(client, "[JB] Input '%s' is not valid for parameter '%s', halting.", query_string, arg_name);
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
	
	ShowVGUIPanel(client, "info", Kv, false);
	
	CloseHandle(Kv);
}



TopMenu (client, Handle:args) {
	SaveResults(client, args);
	
	if(stream_memberships[client] > 0) {
		PlaybackMenu(client);
	} else {
		MainMenu(client);
	}
	
	return;
}


MainMenu(client) {
	if(!PrepareConnection()) {
		return;
	}
	// Look up the date of the most recently added track
	decl String:query[96];
	FormatEx(query, sizeof(query), "SELECT UNIX_TIMESTAMP(added) AS added FROM %s ORDER BY added DESC LIMIT 1", db_tracks);
	SQL_TQuery(music_db, Query_MainMenu2, query, client);
	
	return;
}



public Query_MainMenu2(Handle:owner, Handle:result, const String:error[], any:client) {
	new newest_track_date;
	
	if(!IsClientConnected(client) || IsFakeClient(client)) {
		return;
	}
	
	if (result == INVALID_HANDLE) {
		LogError("Newest Track query failed.  Error: %s", error);
	} else if (SQL_FetchRow(result)) {
		newest_track_date = SQL_FetchInt(result, 0);
	}
	
	new bool:show_all_items;
	
	if(GetConVarBool(cv_reserved)) {
		show_all_items = PermissionCheck(client, cv_admin_flags_reserved);
	} else {
		show_all_items = true;
	}
	
	// Find last update to library for user
	new Handle:top_menu = INVALID_HANDLE;
	new last_update = GetTime() + time_offset - newest_track_date;
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
		FormatTime(newest_title, sizeof(newest_title), "%b %d, %Y", newest_track_date);
	}
	Format(newest_title, sizeof(newest_title), "Newest Tracks (Updated %s)", newest_title);

	new String:top_menu_items[][][] = {{"browse", "Browse Library"}, {"new", "newest_title"}, {"pop", "Most Popular"}, {"rand", "1 Random Song"}, {"rand10", "10 Random Songs"}, {"set", "Settings"}, {"help", "Help"}};
	new admin_access[] = {1, 1, 1, 1, 1, 0, 0};

	top_menu = CreateMenu(MainMenuHandler);
	SetMenuTitle(top_menu, "Jukebox - Please make a selection.");
	for(new i = 0; i < sizeof(top_menu_items); i++) {
		if(show_all_items || !admin_access[i]) {
			if(StrEqual(top_menu_items[i][1], "newest_title")) {
				AddMenuItem(top_menu, top_menu_items[i][0], newest_title);
			} else {
				AddMenuItem(top_menu, top_menu_items[i][0], top_menu_items[i][1]);
			}
		} else {
			AddMenuItem(top_menu, "", "", ITEMDRAW_SPACER);
		}
	}

	DisplayMenu(top_menu, client, menu_maxtime);

	return;
}



public MainMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		decl String:item[8];
		new bool:send_query = false;
		new bool:playback = false;
		new Handle:args = INVALID_HANDLE;

		// Pull arguments from file
		
		args = GetResults(client);

		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			LogError("Failed to retrieve menu position '%d' from handler.", position);
			CloseHandle2(args);
			return false;
		}
		if (StrEqual(item, "browse")) {
			BrowseMenu(client);
		} else if (StrEqual(item, "new")) {
			AddParamNum(args, "lev", 3);
			AddParamNum(args, "groups", 4);
			AddParamNum(args, "limit", 100);
			AddParamString(args, "order", "added DESC");
			send_query = true;
		} else if (StrEqual(item, "pop")) {
			AddParamNum(args, "lev", 3);
			AddParamNum(args, "groups", 4);
			AddParamNum(args, "limit", 50);
			AddParamString(args, "order", "popularity DESC");
			send_query = true;
		} else if (StrEqual(item, "rand")) {
			AddParamNum(args, "limit", 1);
			AddCommand(args, "random");
			playback = true;
		} else if (StrEqual(item, "rand10")) {
			AddParamNum(args, "limit", 10);
			AddCommand(args, "random");
			playback = true;
		} else if (StrEqual(item, "set")) {
			SettingsMenu(client);
		} else if (StrEqual(item, "help")) {
			HelpMenu(client);
		} else {
			LogError("Failed to find instructions for menu item '%s' from handler.", item);
			CloseHandle2(args);
			return false;
		}

		if(send_query) {
			MakeSearchMenu(client, args);
		} else if(playback) {
			PlayMusic(client, args);
		}
		CloseHandle2(args);

	} else if(action == MenuAction_Cancel) {
		RemoveResults(client);
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



PlayMusic(client, Handle:args) {
	new playall = 0, volume_shift = 0;
	decl String:query[256];
	decl String:search_query[2048];

	AddParamNum(args, "lev", 3);

	KvRewind(args);
	
	if(LookupCommand(args, "loud")) {
		volume_shift = GetConVarInt(cv_volume_loud);
	} else if(LookupCommand(args, "soft")) {
		volume_shift = GetConVarInt(cv_volume_soft);
	}
	
	if (LookupCommand(args, "force")) {
		playall = 2;
	}	else if(LookupCommand(args, "all")) {
		playall = 1;
	}
	
	if(!KvSQL(search_query, sizeof(search_query), args)) {
		LogError("Failed to build MySQL query from KeyValue data.");
		return false;
	}

	if (playall == 1) {
		FormatEx(query, sizeof(query), "SELECT `stream_id`, `queue` FROM %s WHERE `playall` > 0 ORDER BY `start_time` LIMIT 1", db_streams);
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, client);
		WritePackCell(datapack, playall);
		WritePackCell(datapack, volume_shift);
		WritePackString(datapack, search_query);
		SQL_TQuery(music_db, Query_QueuePlayall, query, datapack);
	} else if(stream_memberships[client] > 0 && (LookupCommand(args, "queue") || options[client][FindOption("autoqueue")])) {
		FormatEx(query, sizeof(query), "SELECT `creator_steam`, `playall`, `queue` FROM %s WHERE `stream_id` = %d", db_streams, stream_memberships[client]);
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, client);
		WritePackCell(datapack, playall);
		WritePackCell(datapack, volume_shift);
		WritePackString(datapack, search_query);
		SQL_TQuery(music_db, Query_QueueNormal, query, datapack);
	} else {
		PrepareNewStream(client, volume_shift, playall, search_query);
	}
	
	return true;
}



public Query_QueuePlayall(Handle:owner, Handle:result, const String:error[], any:datapack) {
	if(result == INVALID_HANDLE) {
		LogError("Failed check for public streams.  Error: %s", error);
	} else {
		decl String:search_query[2048];
		
		ResetPack(datapack);
		new client = ReadPackCell(datapack);
		new playall = ReadPackCell(datapack);
		new volume_shift = ReadPackCell(datapack);
		ReadPackString(datapack, search_query, sizeof(search_query));
		
		if(IsClientInGame(client) && !IsFakeClient(client)) {
			if(SQL_FetchRow(result)) {
				new stream_id = SQL_FetchInt(result, 0);
				new queue = SQL_FetchInt(result, 1);
				
				ReportQueueTime(client, stream_id);
				if(queue == 0) {
					PrepareQueuedStream(stream_id, client, volume_shift, playall, search_query);
				} else {
					BuildPlaylist(queue, client, -1, search_query);
				}
			} else {
				PrepareNewStream(client, volume_shift, playall, search_query);		
			}
		}
	}
	CloseHandle(datapack);
	
	return;
}



ReportQueueTime(client, stream_id) {
	decl String:query[320];
	FormatEx(query, sizeof(query), "SELECT UNIX_TIMESTAMP(st.`start_time`) + SUM(tr.`playtime`) - UNIX_TIMESTAMP() AS `time_left` FROM %s AS st LEFT JOIN %s AS pl ON (st.`stream_id` = pl.`stream_id` OR st.`queue` = pl.`stream_id`) LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` WHERE st.`stream_id` = %d", db_streams, db_playlists, db_tracks, stream_id);
	SQL_TQuery(music_db, Query_ReportQueueTime, query, client);
	
	return;
}



public Query_ReportQueueTime(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to look up duration until queued music.  Error: %s", error);
	} else if(!SQL_FetchRow(result)) {
		LogError("Looking up duration until queued music returned no results.");
	} else {
		new time_left = SQL_FetchInt(result, 0) + JB_QUEUE_DELAY;
		decl String:time_string[64];
		
		if(time_left < 60) {
			FormatEx(time_string, sizeof(time_string), "%d second", time_left);
			if(time_left > 1) {
				Format(time_string, sizeof(time_string), "%ss", time_string);
			}
		} else if (time_left < 3600) {
			new minutes = RoundToNearest(time_left/60.0);
			FormatEx(time_string, sizeof(time_string), "%d minute", minutes);
			if (minutes > 1) {
				Format(time_string, sizeof(time_string), "%ss", time_string);
			}
		} else {
			new hours = time_left/3600;
			new minutes = RoundToNearest((time_left%3600)/60.0);
			FormatEx(time_string, sizeof(time_string), "%d hour", hours);
			if(hours > 1) {
				Format(time_string, sizeof(time_string), "%ss", time_string);
			}
			Format(time_string, sizeof(time_string), "%s and %d minute", time_string, minutes);
			if (minutes > 1) {
				Format(time_string, sizeof(time_string), "%ss", time_string);
			}
		}
		
		PrintToChat(client, "%c[JB]%c Your music selection has been queued.  It will begin in %s.", cLightGreen, cDefault, time_string);
	}
	
	return;
}



public Query_QueueNormal(Handle:owner, Handle:result, const String:error[], any:datapack) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to look up stream info.  Error: %s", error);
	} else if (!SQL_FetchRow(result)) {
		LogError("Looking up stream info.");
	} else {
		decl String:search_query[2048];
		decl String:creator_steam[25], String:user_steam[25];
		
		ResetPack(datapack);
		new client = ReadPackCell(datapack);
		new playall_new = ReadPackCell(datapack);
		new volume_shift = ReadPackCell(datapack);
		ReadPackString(datapack, search_query, sizeof(search_query));
		
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			SQL_FetchString(result, 0, creator_steam, sizeof(creator_steam));
			GetClientAuthString(client, user_steam, sizeof(user_steam));
			new playall = SQL_FetchInt(result, 1);
			new queue = SQL_FetchInt(result, 2);
			
			if(StrEqual(creator_steam, user_steam) || (playall > 0 && PermissionCheck(client, cv_admin_flags_playall))) {
				ReportQueueTime(client, stream_memberships[client]);
				if(queue == 0) {
					PrepareQueuedStream(stream_memberships[client], client, volume_shift, playall, search_query);
				} else {
					BuildPlaylist(queue, client, -1, search_query);
				}
			} else {
				PrintToChat(client, "%c[JB]%c You are not the owner of this music stream.  Selected tracks will begin immediately.", cLightGreen, cDefault);
				PrepareNewStream(client, volume_shift, playall_new, search_query);
			}
		}
	}
	CloseHandle(datapack);
	
	return;
}



PrepareQueuedStream(stream_id, client, volume_shift, playall, const String:search_query[]) {
	decl String:creator_steam[25];
	decl String:query[256];
	
	if(!GetClientAuthString(client, creator_steam, sizeof(creator_steam))) {
		creator_steam[0] = '\0';
	}
	
	decl String:creator_name[80], String:creator_name_esc[2*sizeof(creator_name)+1];
	GetClientName(client, creator_name, sizeof(creator_name));
	SQL_EscapeString(music_db, creator_name, creator_name_esc, sizeof(creator_name_esc));
	
	FormatEx(query, sizeof(query), "INSERT INTO %s (start_time, creator_steam, creator_name, playall, volume_shift) VALUES (0, '%s', '%s', %d, %d)", db_streams, creator_steam, creator_name_esc, playall, volume_shift);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, stream_id);
	WritePackCell(datapack, client);
	// WritePackCell(datapack, playall);
	WritePackString(datapack, search_query);
	SQL_TQuery(music_db, Query_PrepareQueuedStream1, query, datapack);
	
	return;
}



public Query_PrepareQueuedStream1(Handle:owner, Handle:result, const String:error[], any:datapack) {
	if(strlen(error) > 0) {
		LogError("Failed to create new queued stream.  Error: %s", error);
		CloseHandle(datapack);
	} else {
		new queue = SQL_GetInsertId(music_db);
		ResetPack(datapack);
		new stream_id = ReadPackCell(datapack);
		decl String:query[96];
		FormatEx(query, sizeof(query), "UPDATE %s SET `queue` = %d WHERE `stream_id` = %d", db_streams, queue, stream_id);
		ResetPack(datapack);
		WritePackCell(datapack, queue);
		SQL_TQuery(music_db, Query_PrepareQueuedStream2, query, datapack);
	}
	
	return;
}



public Query_PrepareQueuedStream2(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new queue = ReadPackCell(datapack);
	new client = ReadPackCell(datapack);
	decl String:search_query[2048];
	ReadPackString(datapack, search_query, sizeof(search_query));
	CloseHandle(datapack);
	
	if(strlen(error) > 0) {
		LogError("Failed to update parent stream with new queued Stream ID.  Error: %s", error);
		RemoveStream(queue);
	} else {
		BuildPlaylist(queue, client, -1, search_query);
	}
	
	return;
}



PrepareNewStream(client, volume_shift, playall, const String:search_query[]) {
	decl String:creator_steam[25], String:query[2048];

	if(!GetClientAuthString(client, creator_steam, sizeof(creator_steam))) {
		creator_steam[0] = '\0';
	}
	
	decl String:creator_name[80], String:creator_name_esc[2*sizeof(creator_name)+1];
	FormatEx(creator_name, sizeof(creator_name), "%N", client);
	SQL_EscapeString(music_db, creator_name, creator_name_esc, sizeof(creator_name_esc));
	
	
	FormatEx(query, sizeof(query), "INSERT INTO %s (creator_steam, creator_name, playall, volume_shift) VALUES ('%s', '%s', %d, %d)", db_streams, creator_steam, creator_name_esc, playall, volume_shift);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, client);
	WritePackCell(datapack, playall);
	WritePackString(datapack, search_query);
	SQL_TQuery(music_db, Query_PlayMusic1, query, datapack);
}



public Query_PlayMusic1(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	new playall = ReadPackCell(datapack);
	decl String:query[2048];
	ReadPackString(datapack, query, sizeof(query));
	CloseHandle(datapack);
	
	if(strlen(error) > 0) {
		LogError("Failed to create stream entry in database.  Error: %s", error);
		RemoveStream(client);
	} else if(IsClientInGame(client) && !IsFakeClient(client)) {
		new stream_id = SQL_GetInsertId(music_db);
		
		if(stream_id <= 0) {
				LogError("Failed to determine stream ID of newest entry.");
		} else {			
			BuildPlaylist(stream_id, client, playall, query);
		}
	} else {
		RemoveStream(client);
	}
	
	return;
}



BuildPlaylist(stream_id, client, playall, const String:search_query[]) {
	decl String:query[2048];
	FormatEx(query, sizeof(query), "INSERT INTO %s (stream_id, track_id) SELECT %d AS 'stream_id', `id` AS 'track_id' FROM (%s) AS search_result", db_playlists, stream_id, search_query);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, stream_id);
	WritePackCell(datapack, client);
	WritePackCell(datapack, playall);
	SQL_TQuery(music_db, Query_PlayMusic2, query, datapack);
}



public Query_PlayMusic2(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new stream_id = ReadPackCell(datapack);
	decl String:query[128];
	
	if(strlen(error) > 0) {
		LogError("Failed to copy track info to playlist.  Error: %s", error);
		RemoveStream(stream_id);
		CloseHandle(datapack);
		return;
	}
	
	FormatEx(query, sizeof(query), "SELECT COUNT(*) AS `count` FROM %s WHERE `stream_id` = %d", db_playlists, stream_id);
	
	SQL_TQuery(music_db, Query_PlayMusic3, query, datapack);
	
	return;
}



public Query_PlayMusic3(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new stream_id = ReadPackCell(datapack);
	new client = ReadPackCell(datapack);
	new playall = ReadPackCell(datapack);
	CloseHandle(datapack);
	new entry_count;
	
	if(result == INVALID_HANDLE) {
		LogError("Failed to find first track data.  Error: %s", error);
		return;
	} else if(!SQL_FetchRow(result)) {
		RemoveStream(stream_id);
		LogError("Failed to step into first track data's query result for stream ID %d.", stream_id);
		CloseHandle2(result);
		return;
	} else if (!IsClientInGame(client) || IsFakeClient(client)) {
		// End
		RemoveStream(stream_id);
		CloseHandle2(result);
		return;
	}

	entry_count = SQL_FetchInt(result, 0);
	CloseHandle2(result);
	
	if(entry_count <= 0) {
		PrintToChat(client, "%c[JB]%c Query returned zero results.", cLightGreen, cDefault);
		RemoveStream(stream_id);
		return;
	}
	
	if (playall < 0) { // Queuing tracks only, don't play them
		return;
	}
	
	
	AssignStreamToClient(client, -stream_id);

	if(playall == 1) {
		new playall_target = FindOption("playall");
		for(new i = 1; i <= num_clients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && client != i && stream_memberships[i] == 0 && options[i][playall_target]) {
				AssignStreamToClient(i, -stream_id);
			}
		}
	} else if(playall == 2) {
		for(new i = 1; i <= num_clients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && client != i) {
				AssignStreamToClient(i, -stream_id);
				if(!PermissionCheck(i, cv_admin_flags_playall)) {
					play_lock[i] = true;
				}
			}
		}
	}
	
	NextTrack(stream_id);

	return;
}


AssignStreamToClient(client, stream_id) {
	new current_id = abs(stream_memberships[client]);
	if(current_id > 0 && current_id != abs(stream_id)) {
		RemoveClient(client);
	}
	stream_memberships[client] = stream_id;
}


AnnounceTrack(stream_id, playall, play_count, String:title[], String:artist[], String:album[], String:creator_name[], client = 0) {
	decl String:response_multiple_1[12], String:response_multiple_2[20], String:response_all[15], String:response_artist[artist_length+5], String:announce_string[70 + sizeof(response_artist) + title_length + username_length];
	decl String:playtoall_string[70 + sizeof(response_artist) + title_length + username_length];
	new String:response_off[] = "  Type %c!jb%c to adjust volume, stop playback and more.";
	new String:response_eavesdrop[] = "  Type %c!eavesdrop%c to listen along!";
	new subscribed_clients[MaxClients+1], announce_clients[MaxClients+1];
	new bool:is_reserved = GetConVarBool(cv_reserved);
	new subscribed_count, announce_count;
	
	Format(response_off, sizeof(response_off), response_off, cGreen, cDefault);
	Format(response_eavesdrop, sizeof(response_eavesdrop), response_eavesdrop, cGreen, cDefault);
	
	if(playall > 0) {
		strcopy(response_all, sizeof(response_all), " for everyone");
	} else {
		response_all[0] = 0;
	}

	if(play_count > 1) {
		FormatEx(response_multiple_1, sizeof(response_multiple_1), " %d songs", play_count);
		FormatEx(response_multiple_2, sizeof(response_multiple_2), ", beginning with");
	} else {
		response_multiple_1[0] = 0;
		response_multiple_2[0] = 0;
	}
	
	if(strlen(artist)) {
		FormatEx(response_artist, sizeof(response_artist), " by %s", artist);
	} else if(strlen(album)) {
		FormatEx(response_artist, sizeof(response_artist), " of %s", album);
	} else {
		response_artist[0] = 0;
	}
	
	FormatEx(playtoall_string, sizeof(playtoall_string), "%s is playing for you%s%s '%s'%s.", creator_name, response_multiple_1, response_multiple_2, title, response_artist);
	
	FormatEx(announce_string, sizeof(announce_string), "%s is listening to%s%s '%s'%s.", creator_name, response_multiple_1, response_multiple_2, title, response_artist);
	
	for(new i = 1; i <= MaxClients; i++) {
		if(client != i && IsClientInGame(i) && !IsFakeClient(i)) {
			if(client > 0 && abs(subscribed_clients[i]) == stream_id) {
				subscribed_clients[subscribed_count++] = i;
			} else if(abs(subscribed_clients[i]) != stream_id) {
				announce_clients[announce_count++] = i;
			}
		}
	}
	
	// Display messages
	if(client > 0) {
		PrintToChat(client, "%c[JB]%c Playing%s%s%s '%s'%s.", cLightGreen, cDefault, response_multiple_1, response_all, response_multiple_2, title, response_artist);
	}
	
	for(new i = 0; i < subscribed_count; i++) {
		if(play_lock[i]) {
			PrintToChat(subscribed_clients[i], "%c[JB]%c %s", cLightGreen, cDefault, playtoall_string);
		} else {
			PrintToChat(subscribed_clients[i], "%c[JB]%c %s%s", cLightGreen, cDefault, playtoall_string, response_off);
		}
	}
	
	for(new i =  0; i < announce_count; i++) {
		if(play_lock[i] || (is_reserved && !PermissionCheck(i, cv_admin_flags_reserved))) {
			PrintToChat(announce_clients[i], "%c[JB]%c %s", cLightGreen, cDefault, announce_string);
		} else {
			PrintToChat(announce_clients[i], "%c[JB]%c %s%s", cLightGreen, cDefault, announce_string, response_eavesdrop);
		}
	}
	
	return;
}


BrowseMenu(client) {
	new Handle:browse_menu = INVALID_HANDLE;
	new String:browse_menu_items[][][] = {{"title", "Browse by Title"}, {"album", "Browse by Album or Subject"}, {"artist", "Browse by Artist"}, {"genre", "Browse by Genre"}};

	browse_menu = CreateMenu(BrowseMenuHandler);
	SetMenuTitle(browse_menu, "Jukebox - Browse");
	SetMenuExitBackButton(browse_menu, true);
	for(new i = 0; i < sizeof(browse_menu_items); i++) {
		AddMenuItem(browse_menu, browse_menu_items[i][0], browse_menu_items[i][1]);
	}
	DisplayMenu(browse_menu, client, menu_maxtime);

	return true;
}



public BrowseMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		new Handle:query = INVALID_HANDLE;
		
		query = GetResults(client);
		
		decl String:item[8];
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			LogError("Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		if(StrEqual(item, "title")) {
			AddParamNum(query, "lev", 3);
			AddParamNum(query, "groups", 4);
			AddParamString(query, "order", "title");
		} else if(StrEqual(item, "artist")) {
			AddParamNum(query, "lev", 1);
			AddParamNum(query, "groups", 2);
		} else if(StrEqual(item, "album")) {
			AddParamNum(query, "lev", 2);
			AddParamNum(query, "groups", 3);
		} else if(StrEqual(item, "genre")) {
			AddParamNum(query, "lev", 0);
			AddParamNum(query, "groups", 1);
		} else {
			// BOO
		}

		MakeSearchMenu(client, query);
		CloseHandle2(query);
	} else if(action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			new Handle:args = GetResults(client);
			TopMenu(client, args);
		} else {
			RemoveResults(client);
		}
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



SettingsMenu(client) {
	new Handle:settings_menu = INVALID_HANDLE;
	// new String:settings_menu_items[][][] = {{"volume", "Change Volume ({c}%)"}, {"playall", "{t} Public stream membership"}, {"autoqueue", "{t} automatic queuing"}};
	// new String:toggle_flag[] = "{t}";
	// new String:current_flag[] = "{c}";
	// new option_target;
	decl String:item_description[64];
	// decl String:value_string[4];
	
	settings_menu = CreateMenu(SettingsMenuHandler);
	SetMenuTitle(settings_menu, "Jukebox - Settings");
	SetMenuExitBackButton(settings_menu, true);
	
	FormatMenuOptionInt(item_description, sizeof(item_description), options[client][FindOption("volume")], "Change Volume", "%");
	AddMenuItem(settings_menu, "volume", item_description);
	
	FormatMenuOptionBool(item_description, sizeof(item_description), options[client][FindOption("playall")], "Public stream membership");
	AddMenuItem(settings_menu, "playall", item_description);
	
	FormatMenuOptionBool(item_description, sizeof(item_description), options[client][FindOption("autoqueue")], "Automatic queuing");
	AddMenuItem(settings_menu, "autoqueue", item_description);
	
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
	if(option_target < 0) {
		LogError("Failed to find ID number for '%s'.", target);
		return false;
	}
	if(options[client][option_target]) {
		options[client][option_target] = 0;
	} else {
		options[client][option_target] = 1;
	}

	decl String:steam_id[25];
	decl String:query[128];
	if (!GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		LogError("Could not save new '%s' setting for user '%s'.", target, steam_id);
		return false;
	}
	FormatEx(query, sizeof(query), "UPDATE %s SET %s = %d WHERE steamid = '%s'", db_options, target, options[client][option_target], steam_id);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, client);
	WritePackString(datapack, target);
	SQL_TQuery(music_db, Query_ToggleOption1, query, datapack, DBPrio_Low);
	
	return true;
}



public Query_ToggleOption1(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	decl String:target[12];
	ReadPackString(datapack, target, sizeof(target));
	CloseHandle(datapack);
	if(strlen(error) > 0) {
		if(IsClientInGame(client) && !IsFakeClient(client)) {
			PrintToConsole(client, "[JB] Failed to toggle user option '%s'.", target);
		}
		LogError("Failed to toggle user option '%s' for user %N.  Error: %s", target, client, error);
	} else if (IsClientInGame(client) && !IsFakeClient(client)) {
		PrintToConsole(client, "[JB] User option '%s' toggled.", target);
	}
	
	return;
}



SetOption(client, String:target[], value) {
	new option_target = FindOption(target);
	if(option_target < 0) {
		LogError("Failed to find ID number for '%s'.", target);
		return false;
	}
	options[client][option_target] = value;

	decl String:steam_id[25];
	decl String:query[128];
	if (!GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		LogError("Could not save new '%s' setting for user '%s'.", target, steam_id);
		return false;
	}
	FormatEx(query, sizeof(query), "UPDATE %s SET %s = %d WHERE steamid = '%s'", db_options, target, options[client][option_target], steam_id);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, client);
	WritePackString(datapack, target);
	SQL_TQuery(music_db, Query_SetOption1, query, datapack, DBPrio_Low);
	
	return true;
}



public Query_SetOption1(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	decl String:target[12];
	ReadPackString(datapack, target, sizeof(target));
	CloseHandle(datapack);
	if(strlen(error) > 0) {
		if(IsClientInGame(client) && !IsFakeClient(client)) {
			PrintToConsole(client, "[JB] Failed to set user option '%s'.", target);
		}
		LogError("Failed to set user option '%s' for user %N.  Error: %s", target, client, error);
	} else if(IsClientInGame(client) && !IsFakeClient(client)) {
		PrintToConsole(client, "[JB] User option '%s' set.", target);
	}
	
	return;
}



public SettingsMenuHandler(Handle:menu, MenuAction:action, client, position) {
	decl String:item[12];

	if(action == MenuAction_Select) {
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			LogError("Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}

		if(StrEqual(item, "volume")) {
			VolumeMenu(client);
		} else {
			if(!ToggleOption(client, item)) {
				LogError("Failed to find instructions for menu item '%s' from handler.", item);
				return false;
			}
			SettingsMenu(client);
		}

	} else if(action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			new Handle:args = GetResults(client);
			TopMenu(client, args);
		} else {
			RemoveResults(client);
		}
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



SuggestMenu(client) {
	new Handle:suggest_menu = CreateMenu(SuggestMenuHandler);

	PrintToChat(client, "%c[JB]%c Did you know that you can adjust Jukebox's playback volume, or block songs from playing altogether?", cLightGreen, cDefault);
	SetMenuExitButton(suggest_menu, false);
	SetMenuTitle(suggest_menu, "Would you like to adjust your personal playback settings?");
	AddMenuItem(suggest_menu, "1", "Yes");
	AddMenuItem(suggest_menu, "2", "No");
	DisplayMenu(suggest_menu, client, menu_maxtime);

	return true;
}



public SuggestMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		decl String:item[2];
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			LogError("Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		if(StrEqual(item, "1")) {
			SettingsMenu(client);
		}
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}
	
	return true;
}



HelpMenu(client) {
	if(stream_memberships[client] > 0) {
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
	decl String:item[8];
	
	if(action == MenuAction_Select) {
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			LogError("Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		if(StrEqual(item, "1")) {
			RemoveClient(client);
			ShowHelp(client);
		} else {
			new Handle:args = GetResults(client);
			TopMenu(client, args);
		}
	} else if(action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			new Handle:args = GetResults(client);
			TopMenu(client, args);
		} else {
			RemoveResults(client);
		}
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
	decl String:menu_info_buffer[4];
	decl String:menu_display_buffer[16];
	new Handle:volume_menu = INVALID_HANDLE;
	new volume_current = options[client][FindOption("volume")];
	new volume_min = GetConVarInt(cv_volume_min);

	volume_menu = CreateMenu(VolumeMenuHandler);
	SetMenuTitle(volume_menu, "Jukebox - Set Volume");
	SetMenuExitBackButton(volume_menu, true);
	
	if(volume_current != volume_min) {
		FormatEx(menu_display_buffer, sizeof(menu_display_buffer), "%d%%", volume_min);
		IntToString(volume_min, menu_info_buffer, sizeof(menu_info_buffer));
		AddMenuItem(volume_menu, menu_info_buffer, menu_display_buffer);
	}
	
	for (new i = 0; i < sizeof(volume_settings); i++) {
		if (volume_current >= volume_min && (i == 0 || volume_settings[i-1] < volume_current) && volume_settings[i] >= volume_current) {
			FormatEx(menu_display_buffer, sizeof(menu_display_buffer), "%d%% (current)", volume_current);
			IntToString(volume_current, menu_info_buffer, sizeof(menu_info_buffer));
			AddMenuItem(volume_menu, menu_info_buffer, menu_display_buffer);
		}
		if (volume_settings[i] > volume_min && volume_settings[i] != volume_current) {
			FormatEx(menu_display_buffer, sizeof(menu_display_buffer), "%d%%", volume_settings[i]);
			IntToString(volume_settings[i], menu_info_buffer, sizeof(menu_info_buffer));
			AddMenuItem(volume_menu, menu_info_buffer, menu_display_buffer);
		}
	}
	DisplayMenu(volume_menu, client, menu_maxtime);

	return true;
}



public VolumeMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if(action == MenuAction_Select) {
		decl String:item[8];
		new volume_setting;
		if(!GetMenuItem(menu, position, item, sizeof(item))) {
			LogError("Failed to retrieve menu position '%d' from handler.", position);
			return false;
		}
		volume_setting = StringToInt(item);
		if(!SetVolume(client, volume_setting)) {
			return false;
		}
		SettingsMenu(client);
	} else if(action == MenuAction_Cancel) {
		if(position == MenuCancel_ExitBack) {
			SettingsMenu(client);
		} else {
			RemoveResults(client);
		}
	} else if(action == MenuAction_End) {
		CloseHandle2(menu);
	}

	return true;
}



public Action:Command_Jukebox (client, args) {
	new bool:display_all;
	
	if(!GetConVarBool(cv_enabled)) {
		PrintToChat(client, "%c[JB]%c Jukebox is currently disabled.", cLightGreen, cDefault);
		return Plugin_Handled;
	}
		
	if(GetConVarBool(cv_reserved)) {
		display_all = PermissionCheck(client, cv_admin_flags_reserved);
	} else {
		display_all = true;
	}
	
	if(!PrepareConnection()) {
		return Plugin_Handled;
	}

	if (args >= 1 && display_all) {
		//new num_bytes;
		decl String:args_line[256];
		GetCmdArgString(args_line, sizeof(args_line));
		SystemLaunch(client, args_line);
	} else {
		new Handle:top_args = INVALID_HANDLE;
		top_args = CreateKeyValues("Queries");
		TopMenu(client, top_args);
		CloseHandle2(top_args);
	}

	return Plugin_Handled;
}



public Action:Command_Volume (client, args) {
	if(!PrepareConnection()) {
		return Plugin_Handled;
	}
	
	decl String:volume_string[8];
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
	new current_volume = options[client][FindOption("volume")];
	if(SetOption(client, "volume", volume)) {
		PrintToChat(client, "%c[JB]%c Volume set to %d%%.", cLightGreen, cDefault, volume);
		if(current_volume != volume && stream_memberships[client] > 0) {
			new clients_list[1];
			clients_list[0] = client;
			now_volume[client] = volume;
			AddClients(stream_memberships[client], clients_list, 1, play_lock[client]);
		}
		return true;
	} else {
		PrintToChat(client, "%c[JB]%c An error has occured saving your volume settings.", cLightGreen, cDefault);
		return false;
	}
}



StopMOTD (client) {
	LoadMOTDPanelHidden (client, "Blank", "about:blank", MOTDPANEL_TYPE_URL);
}



public Action:Command_JbOff (client, args) {
	JbOff(client);
	
	return Plugin_Handled;
}



JbOff(client) {
	if(stream_memberships[client] > 0) {
		if(play_lock[client] == false) {
			new jboff_target = GetConVarInt(cv_monitor_jboff_use);
			
			if(jboff_target > 0) {
				decl String:query[128];
				
				FormatEx(query, sizeof(query), "SELECT `creator_steam`, `playall` FROM %s WHERE `stream_id` = %d", db_streams, stream_memberships[client]);
				SQL_TQuery(music_db, Query_JbOff1, query, client, DBPrio_Low);
			}
			
			RemoveClient(client, false);
			PrintToChat(client, "%c[JB]%c Music playback halted.", cLightGreen, cDefault);
		} else {
			PrintToChat(client, "%c[JB]%c Playback of this track cannot be stopped.", cLightGreen, cDefault);
		}
	} else {
		PrintToChat(client, "%c[JB]%c There is no music playing.", cLightGreen, cDefault);
	}

	return;
}



public Query_JbOff1(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to look up playall status for client.  Error: %s", client, error);
		return;
	} else if(!SQL_FetchRow(result)) {
		LogError("Failed to browse to first row of playall status query.");
		return;
	} else if(IsClientInGame(client) && !IsFakeClient(client)) {
		new jboff_target = GetConVarInt(cv_monitor_jboff_use);
		decl String:creator_steam_id[25], String:target_steam_id[25];
		SQL_FetchString(result, 0, creator_steam_id, sizeof(creator_steam_id));
		new playall = SQL_FetchInt(result, 1);
		
		if(playall > 0 && GetClientAuthString(client, target_steam_id, sizeof(target_steam_id)) && StrEqual(creator_steam_id, target_steam_id) && ++jboff_count[client] % jboff_target == 0) {
			SuggestMenu(client);
		}
	}
	
	return;
}



public Action:Command_JbAllOff(client, args) {
	JbAllOff(client);
	
	return Plugin_Handled;
}

JbAllOff(client) {
	for(new i = 1; i <= num_clients; i++) {
		RemoveClient(i, false);
	}
	
	PrintToConsole(client, "[JB] Music playback halted for all users.");
	PrintToChatAll("%c[JB]%c Music playback halted for all users by %N.", cLightGreen, cDefault, client);
	
	return;
}



public Action:NextTrackTimer(Handle:timer, any:id) {
	if(GetConVarBool(cv_log_use)) {
		new update_count;
		new clients_list[num_clients + sizeof(disconnect_streams)];
		for(new i = 0; i < num_clients; i++) {
			if(stream_memberships[i] == id) {
				clients_list[update_count++] = log_username_entry[i][0];
			}
		}
		for(new i = 0; i < sizeof(disconnect_streams); i++) {
			if(disconnect_streams[i] == id) {
				clients_list[update_count++] = disconnect_log_usernames[i][0];
			}
		}
		if(update_count > 0) {
			FinishLogStats(clients_list, update_count);
		}
	}
	
	NextTrack(id);
	
	return;
}



NextTrack(stream_id) {
	decl String:query[128];
	
	FormatEx(query, sizeof(query), "UPDATE %s SET `now_playing` = `now_playing` + 1 WHERE `stream_id` = %d", db_streams, stream_id);
	SQL_TQuery(music_db, Query_NextTrack1, query, stream_id);
	
	return true;
}



public Query_NextTrack1(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(strlen(error) > 0) {
		LogError("Failed to increment now_playing counter for stream %d.  Error: %s", stream_id, error);
		return;
	}
	
	if(SQL_GetAffectedRows(music_db) > 0) {
		decl String:query[1536];
		FormatEx(query, sizeof(query), "SELECT tr.`title`, tr.`artist`, tr.`album`, UNIX_TIMESTAMP(st.`start_time`) + std.`sum_playtime` - UNIX_TIMESTAMP() AS 'playtime', st.`playall`, st.`creator_name`, st.`now_playing`, pl2.`count`, st.`creator_steam` FROM %s AS st JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence` JOIN %s AS tr ON pl.`track_id` = tr.`id` LEFT JOIN (SELECT COALESCE(st2.`stream_id`, 0) AS 'match_id', COUNT(pl2.`sequence`) AS 'count' FROM %s AS st2 LEFT JOIN %s AS pl2 ON st2.`stream_id` = pl2.`stream_id` AND st2.`now_playing` <= pl2.`sequence` GROUP BY st2.`stream_id`) AS pl2 ON st.`stream_id` = pl2.`match_id`", db_streams, db_playlists, db_tracks, db_streams, db_playlists);
		Format(query, sizeof(query), "%s LEFT JOIN (SELECT COALESCE(std.`stream_id`, 0) AS 'match_id', COALESCE(SUM(trd.`playtime`), 0) AS 'sum_playtime' FROM %s AS std LEFT JOIN %s AS pld ON std.`stream_id` = pld.`stream_id` AND std.`now_playing` >= pld.`sequence` LEFT JOIN %s AS trd ON pld.`track_id` = trd.`id` GROUP BY std.`stream_id`) AS std ON st.`stream_id` = std.`match_id` WHERE st.`stream_id` = %d GROUP BY st.`stream_id`", query, db_streams, db_playlists, db_tracks, stream_id);
		
		SQL_TQuery(music_db, Query_NextTrack2, query, stream_id);
	}
	
	return;
}



public Query_NextTrack2(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to retrieve header data.  Error: %s", error);
		return;
	}
	
	if(!SQL_FetchRow(result)) {
		AttemptQueueMigration(stream_id);
		return;
	}
	
	decl String:title[title_length], String:artist[artist_length], String:album[album_length], String:creator_name[username_length], String:creator_steam[25];
	SQL_FetchString(result, 0, title, sizeof(title));
	SQL_FetchString(result, 1, artist, sizeof(artist));
	SQL_FetchString(result, 2, album, sizeof(album));
	new Float:playtime = SQL_FetchFloat(result, 3);
	new playall = SQL_FetchInt(result, 4);
	SQL_FetchString(result, 5, creator_name, sizeof(creator_name));
	new now_playing = SQL_FetchInt(result, 6);
	new play_count = SQL_FetchInt(result, 7);
	SQL_FetchString(result, 8, creator_steam, sizeof(creator_steam));
	CloseHandle(result);
	new update_clients[num_clients+1], subscribed_clients[num_clients+1];
	new update_count = 0, display_count = 0, subscribed_count = 0;
	new playall_target = FindOption("playall");
	
	if(playtime < 0.1) {
		LogError("Unknown error has corrupted reported track playtime.  Aborting...");
		return;
	}

	for(new i = 1; i <= num_clients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && ((playall == 2 || (playall == 1 && stream_memberships[i] == 0 && options[i][playall_target])) || stream_memberships[i] == -stream_id)) {
			update_clients[update_count++] = i;
		}
	}

	if (update_count > 0) {
		AddClients(stream_id, update_clients, update_count, (playall == 2));
	}

	new Float:vote_score = 0.0;
	
	for(new i = 1; i <= num_clients; i++) {
		if(stream_memberships[i] == stream_id) {
			subscribed_clients[display_count++] = i;
			subscribed_count++;
			if(popularity_votes[i] == stream_id) {
				vote_score += 0.5;
				popularity_votes[i] = 0;
			}
		}
	}
	
	if(GetTime() < last_map_change + 120) {
		for(new i = 0; i < sizeof(disconnect_streams); i++) {
			if(disconnect_streams[i] == stream_id) {
				subscribed_count++;
				if(disconnect_popularity[i] == stream_id) {
					vote_score += 0.5;
					disconnect_popularity[i] = 0;
				}
			}
		}
	}
	
	if(subscribed_count == 0) {
		RemoveStream(stream_id);
		return;
	}
	
	CreateTimer(playtime, NextTrackTimer, stream_id);
	
	DisplayTrackInfo(subscribed_clients, subscribed_count, title, artist, album, playtime);
	
	new announce_mode = GetConVarInt(cv_announce_mode);
	if(announce_mode >= 1 && now_playing == 1 || announce_mode >= 1 && playall > 0 || announce_mode >= 3) {
		new announce_client = 0;
		if(now_playing == 1) {
			decl String:client_steam[25];
			for(new i = 1; i <= MaxClients; i++) {
				if(IsClientConnected(i) && !IsFakeClient(i) && GetClientAuthString(i, client_steam, sizeof(client_steam)) && StrEqual(creator_steam, client_steam)) {
					announce_client = i;
					break;
				}
			}
		}
		AnnounceTrack(stream_id, playall, play_count, title, artist, album, creator_name, announce_client);
	}
	
	if(GetConVarBool(cv_log_use)) {
		CreateLogStats(stream_id, subscribed_clients, subscribed_count);
	}
	
	decl String:query[320];
	FormatEx(query, sizeof(query), "UPDATE %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence` LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` SET tr.`popularity` = tr.`popularity` + 1 + %.2f, tr.`playcount` = tr.`playcount` + %d WHERE st.`stream_id` = %d", db_streams, db_playlists, db_tracks, vote_score, subscribed_count, stream_id);
	SQL_TQuery(music_db, Query_NextTrack3, query, stream_id, DBPrio_Low);
	
	return;
}


public Query_NextTrack3(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(strlen(error) > 0) {
		LogError("Failed to update track statistics for stream %d.  Error: %s", stream_id, error);
	}
	
	return;
}



AttemptQueueMigration(stream_id) {
	decl String:query[96];
	FormatEx(query, sizeof(query), "SELECT `queue` FROM %s WHERE `stream_id` = %d", db_streams, stream_id);
	SQL_TQuery(music_db, Query_AttemptQueueMigration1, query, stream_id);
	
	return;
}


public Query_AttemptQueueMigration1(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to look up queued stream on end of Stream ID #%d.  Error: %s", stream_id, error);
		RemoveStream(stream_id);
	} else if (!SQL_FetchRow(result)) {
		LogError("Look up of queued stream on end of Stream ID #%d returned no results.", stream_id);
		RemoveStream(stream_id);
	} else {
		new queue = SQL_FetchInt(result, 0);
		if(queue > 0) {
			for(new i = 0; i < sizeof(stream_memberships); i++) {
				if(abs(stream_memberships[i]) == stream_id) {
					stream_memberships[i] = -queue;
				}
			}
			for(new i = 0; i < sizeof(disconnect_streams); i++) {
				if(abs(disconnect_streams[i]) == stream_id) {
					disconnect_streams[i] = -queue;
				}
			}
			decl String:query[96];
			FormatEx(query, sizeof(query), "UPDATE %s SET `queue` = 0 WHERE `stream_id` = %d", db_streams, stream_id);
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, stream_id);
			WritePackCell(datapack, queue);
			SQL_TQuery(music_db, Query_AttemptQueueMigration2, query, datapack);
		} else {
			RemoveStream(stream_id);
		}
	}
	
	return;
}



public Query_AttemptQueueMigration2(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new stream_id = ReadPackCell(datapack);
	new queue = ReadPackCell(datapack);
	CloseHandle(datapack);
	if(strlen(error) > 0) {
		LogError("Failed to clear queue from Stream #%d.  Error: %s", stream_id, error);
	} else {
		CreateTimer(float(JB_QUEUE_DELAY), DelayedStartStream, queue);
	}
	RemoveStream(stream_id);
	
	return;
}


public Action:DelayedStartStream(Handle:timer, any:stream_id) {
	decl String:query[96];
	FormatEx(query, sizeof(query), "UPDATE %s SET `start_time` = NOW() WHERE `stream_id` = %d", db_streams, stream_id);
	SQL_TQuery(music_db, Query_DelayedStartStream, query, stream_id);
	
	return;
}



public Query_DelayedStartStream(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(strlen(error) > 0) {
		LogError("Failed to update start time of Stream %d prior to migrating to stream.  Error: %s", stream_id, error);
	} else {
		NextTrack(stream_id);
	}
	
	return;
}



DisplayTrackInfo(clients_list[], clients_count, String:title[], String:artist[], String:album[], Float:playtime = 0.0) {
	new Float:display_time = 8.0;

	if(playtime > 0.0 && display_time > playtime - 1.0) {
		display_time = playtime - 1.0;
	}

	if(display_time > 0.0) {
		new Handle:datapack = INVALID_HANDLE;
		decl String:track_info[title_length+artist_length+album_length];
		
		FormatEx(track_info, sizeof(track_info), "%s\n%s\n%s", title, artist, album);
		CreateDataTimer(3.0, DelayedDisplayMessage, datapack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		WritePackFloat(datapack, display_time);
		WritePackCell(datapack, clients_count);
		for(new i = 0; i < clients_count; i++) {
			WritePackCell(datapack, clients_list[i]);
		}
		WritePackString(datapack, track_info);
		
		return true;
	} else {
		return false;
	}
}



RemoveStream(stream_id) {
	new listen_count, users_count;
	new Float:vote_score = 0.0;
	new bool:count_disconnects = (GetTime() < last_map_change + 120);
	new users_list[num_clients + sizeof(disconnect_streams)];

	for(new i = 1; i <= num_clients; i++) {
		if (stream_memberships[i] == stream_id) {
			listen_count++;
			users_list[users_count++] = log_username_entry[i][0];
			if(popularity_votes[i] == stream_id) {
				vote_score += 0.5;
				popularity_votes[i] = 0;
			}
			RemoveClient(i, true);
		}
	}
	for(new i = 0; i < sizeof(disconnect_streams); i++) {
		if(disconnect_streams[i] == stream_id) {
			if(count_disconnects) {
				listen_count++;
			}
			users_list[users_count++] = disconnect_log_usernames[i][0];
			if(disconnect_popularity[i] == stream_id) {
				vote_score += 0.5;
				disconnect_popularity[i] = 0;
			}
			ClearDisconnectData(i);
		}
	}
	
	if(users_count > 0 && GetConVarBool(cv_log_use)) {
		FinishLogStats(users_list, users_count);
	}
	
	if(listen_count > 0) {
		decl String:query[320];
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, stream_id);
		WritePackCell(datapack, listen_count);
		WritePackFloat(datapack, vote_score);
		FormatEx(query, sizeof(query), "SELECT UNIX_TIMESTAMP(st.`start_time`) + SUM(tr.`playtime`) - UNIX_TIMESTAMP() AS `time_left` FROM %s AS st INNER JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` >= pl.`sequence` INNER JOIN %s AS tr ON pl.`track_id` = tr.`id` WHERE st.`stream_id` = %d", db_streams, db_playlists, db_tracks, stream_id);
		SQL_TQuery(music_db, Query_RemoveStream1, query, datapack);
	} else {
		ExecuteStreamRemoval(stream_id);
	}

	return true;
}


public Query_RemoveStream1(Handle:owner, Handle:result, const String:error[], any:datapack) {
	ResetPack(datapack);
	new stream_id = ReadPackCell(datapack);
	new listen_count = ReadPackCell(datapack);
	new Float:vote_score = ReadPackFloat(datapack);
	CloseHandle(datapack);
	
	if(result == INVALID_HANDLE) {
		LogError("Failed while looking up time left in current track of stream %d.  Error: %s", stream_id, error);
		return;
	} else if(!SQL_FetchRow(result)) {
		LogError("Looking up time left in current track of stream %d returned no results.", stream_id);
		return;
	} else {
		new Float:time_left = SQL_FetchFloat(result, 0);
	
		if(time_left <= 10.0) {
			decl String:query[320];
			FormatEx(query, sizeof(query), "UPDATE %s AS st INNER JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence` INNER JOIN %s AS tr ON pl.`track_id` = tr.`id` SET tr.`popularity` = tr.`popularity` + 1 + %.2f, tr.`playcount` = tr.`playcount` + %d WHERE st.`stream_id` = %d", db_streams, db_playlists, db_tracks, vote_score, listen_count, stream_id);
			SQL_TQuery(music_db, Query_RemoveStream2, query, stream_id);
		} else {
			ExecuteStreamRemoval(stream_id);
		}
	}
	
	return;
}



public Query_RemoveStream2(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(strlen(error) > 0) {
		LogError("Did not count track stats for Stream ID %d", stream_id);
	}
	
	ExecuteStreamRemoval(stream_id);
	
	return;
}



ExecuteStreamRemoval(stream_id) {
	decl String:query[320];
	FormatEx(query, sizeof(query), "DELETE st, pl, stq, plq FROM %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` LEFT JOIN %s AS stq ON st.`queue` = stq.`stream_id` LEFT JOIN %s AS plq ON stq.`stream_id` = plq.`stream_id` WHERE st.`stream_id` = %d", db_streams, db_playlists, db_streams, db_playlists, stream_id);
	SQL_TQuery(music_db, Query_ExecuteStreamRemoval, query, stream_id, DBPrio_Low);
	
	return;
}



public Query_ExecuteStreamRemoval(Handle:owner, Handle:result, const String:error[], any:stream_id) {
	if(strlen(error) > 0) {
		LogError("Failed to destroy music stream %d.  Error: %s", stream_id, error);
	}
	
	return;
}



//  Byte 0 = playtime (float), Byte 1 = # of clients "n", bytes 2 to n+1 = client numbers, bytes n+2 to end = display string
public Action:DelayedDisplayMessage(Handle:timer, Handle:datapack) {
	new Float:display_time, client_count;
	decl String:message[300];

	ResetPack(datapack);
	display_time = ReadPackFloat(datapack);
	client_count = ReadPackCell(datapack);

	new client_list[client_count];
	for(new i = 0; i < client_count; i++) {
		client_list[i] = ReadPackCell(datapack);
	}
	ReadPackString(datapack, message, sizeof(message));

	if(hud_sync == INVALID_HANDLE) {
		for(new i = 0; i < client_count; i++) {
			if(IsClientInGame(client_list[i]) && !IsFakeClient(client_list[i])) {
				PrintHintText(client_list[i], message);
			}
		}
	} else {
		SetHudTextParams(-1.0, 0.1, display_time, 254, 254, 254, 195, 1);
		for(new i = 0; i < client_count; i++) {
			if(IsClientInGame(client_list[i]) && !IsFakeClient(client_list[i])) {
				ShowSyncHudText(client_list[i], hud_sync, message);
			}
		}
	}
}



RemoveClient(const client, bool:closeout=false) {
	new stream_id;
	new bool:alive_test;

	if(IsClientInGame(client) && !IsFakeClient(client)) {
		if(!closeout) {
			stream_id = abs(stream_memberships[client]);
			StopMOTD(client);
		}
		stream_memberships[client] = 0;
		play_lock[client] = false;
		popularity_votes[client] = 0;
		now_volume[client] = 0;

		if(!closeout) {
			if(GetConVarBool(cv_log_use)) {
				new clients_list[1];
				clients_list[0] = log_username_entry[client][0];
				FinishLogStats(clients_list, 1);
			}
			
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
	disconnect_popularity[cell] = 0;
	disconnect_time[cell] = 0;
	disconnect_volume[cell] = 0;
	disconnect_log_usernames[cell][0] = 0;
	disconnect_log_usernames[cell][1] = 0;

	return;
}



GenerateKey(String:output[], maxlen) {
	new time, write_length;
	decl String:word[5];
	decl String:hex[9];
	decl String:leech_password[33]; // Used to generate in-URL encryption key; for anti-leech protection
	
	GetConVarString(cv_leech_password, leech_password, sizeof(leech_password));

	time = GetTime() + time_offset;
	FormatEx(word, sizeof(word), "%c%c%c%c", time & 0xff, (time >> 8) & 0xff, (time >> 16) & 0xff, time >> 24);
	write_length = EncodeRC4(word, leech_password, hex, sizeof(hex), 4);
	strcopy(output, maxlen, hex);

	return write_length;
}



public Action:Command_Eavesdrop(client, args) {
	if(!GetConVarBool(cv_enabled)) {
		PrintToChat(client, "%c[JB]%c Jukebox is currently disabled.", cLightGreen, cDefault);
		return Plugin_Handled;
	}
	
	if(GetConVarBool(cv_reserved) && !PermissionCheck(client, cv_admin_flags_reserved)) {
		PrintToChat(client, "%c[JB]%c Jukebox is currently reserved for use by admins.", cLightGreen, cDefault);
		return Plugin_Handled;
	}
	
	if(!PrepareConnection()) {
		return Plugin_Handled;
	}

	decl String:arguments[username_length+6];

	if(args >= 1 && GetCmdArg(1, arguments, sizeof(arguments))) {	
		decl String:name_search[username_length];
		BreakString(arguments, name_search, sizeof(name_search));
		if(StrEqual(name_search, "public")) {
			decl String:query[256];
			FormatEx(query, sizeof(query), "SELECT `stream_id`, `creator_name`, `creator_steam` FROM %s WHERE `playall` > 0 ORDER BY `start_time` DESC LIMIT 1", db_streams);
			
			SQL_TQuery(music_db, Query_Eavesdrop2a, query, client);
		} else {
			decl String:target_name[MAX_TARGET_LENGTH];
			decl String:target_username[username_length];
			decl target_list[num_clients], target_count, bool:tn_is_ml;
			new target_stream, target_client;
			target_count = ProcessTargetString(name_search, 0, target_list, num_clients, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
			if(target_count <= 0) {
				PrintToChat(client, "%c[JB]%c There are no players which match '%s'.", cLightGreen, cDefault, name_search);
				return Plugin_Handled;
			}
	
			for(new i = 0; i < target_count; i++) {
				if(stream_memberships[target_list[i]] > 0) {
					target_client = target_list[i];
					target_stream = stream_memberships[target_list[i]];
					FormatEx(target_username, sizeof(target_username), "%N", target_list[i]);
					break;
				}
			}
			if(target_stream == 0) {
				FormatEx(target_username, sizeof(target_username), "%N", target_list[0]);
				PrintToChat(client, "%c[JB]%c %s is not listening to anything.", cLightGreen, cDefault, target_username);
				return Plugin_Handled;
			}
			
			Eavesdrop2b(client, target_stream, target_client, target_username);
		}
		
	} else {
		decl String:query[384];
		new announce_mode = GetConVarInt(cv_announce_mode);
		if(announce_mode == 2) {
			FormatEx(query, sizeof(query), "SELECT st.`stream_id`, st.`creator_name`, st.`creator_steam`, st.`start_time` + LEAST(1,st.`playall`)*SUM(tr.`playtime`) AS 'sort_time' FROM %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` GROUP BY st.`stream_id` ORDER BY 'sort_time' DESC LIMIT 1", db_streams, db_playlists, db_tracks);
		} else if (announce_mode == 3) {
			FormatEx(query, sizeof(query), "SELECT st.`stream_id`, st.`creator_name`, st.`creator_steam`, st.`start_time` + SUM(tr.`playtime`) AS 'sort_time' FROM %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` GROUP BY st.`stream_id` ORDER BY 'sort_time' DESC LIMIT 1", db_streams, db_playlists, db_tracks);
		} else {
			FormatEx(query, sizeof(query), "SELECT `stream_id`, `creator_name`, `creator_steam` FROM %s ORDER BY `start_time` DESC LIMIT 1", db_streams);
		}
		
		SQL_TQuery(music_db, Query_Eavesdrop2a, query, client);
	}

	return Plugin_Handled;
}



public Query_Eavesdrop2a(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed while looking up latest music stream.  Error: %s", error);
	} else if(!IsClientInGame(client) || IsFakeClient(client)) {
		// End
	} else if(!SQL_FetchRow(result)) {
		PrintToChat(client, "%c[JB]%c No one is listening to any music right now.", cLightGreen, cDefault);
	} else {
		new target_stream, target_client;
		decl String:target_username[username_length], String:target_steam[25], String:steam_temp[25];
		target_stream = SQL_FetchInt(result, 0);
		SQL_FetchString(result, 1, target_username, sizeof(target_username));
		SQL_FetchString(result, 2, target_steam, sizeof(target_steam));
		
		for(new i = 1; i <= num_clients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthString(i, steam_temp, sizeof(steam_temp)) && StrEqual(target_steam, steam_temp)) {
				target_client = i;
				break;
			}
		}
		
		Eavesdrop2b(client, target_stream, target_client, target_username);
	}
	
	return;
}



Eavesdrop2b(client, target_stream, target_client, const String:target_username[]) {
	if(target_stream == stream_memberships[client]) {
		PrintToChat(client, "%c[JB]%c You are already listening to the same music stream.", cLightGreen, cDefault);
		return;
	}

	new clients_list[1];
	clients_list[0] = client;

	AddClients(target_stream, clients_list, 1, false);
	
	if(GetConVarBool(cv_log_use)) {
		CreateLogStats(target_stream, clients_list, 1);
	}
	
	popularity_votes[client] = target_stream;

	PrintToChat(client, "%c[JB]%c Eavesdropping on music being listened to by %s.  Type %c!jb%c to adjust volume, stop playback and more.", cLightGreen, cDefault, target_username, cGreen, cDefault);
	
	if(target_client > 0) {
		PrintToChat(target_client, "%c[JB]%c %N is eavesdropping on your music.", cLightGreen, cDefault, client);
	}
	
	decl String:query[288];
	FormatEx(query, sizeof(query), "SELECT tr.`title`, tr.`artist`, tr.`album`, tr.`playtime` FROM %s AS st INNER JOIN %s AS pl ON (st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence`) INNER JOIN %s AS tr ON pl.`track_id` = tr.`id` WHERE st.`stream_id` = %d", db_streams, db_playlists, db_tracks, target_stream);
	SQL_TQuery(music_db, Query_Eavesdrop3, query, client, DBPrio_Low);
	
	return;
}



public Query_Eavesdrop3(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed while looking up stream data.  Error: %s", error);
	} else if(!IsClientInGame(client) || IsFakeClient(client)) {
		// End
	} else if(!SQL_FetchRow(result)) {
		PrintToConsole(client, "[JB] Stream data query returned no results.");
	} else {
		decl String:title[title_length], String:artist[artist_length], String:album[album_length];
		SQL_FetchString(result, 0, title, sizeof(title));
		SQL_FetchString(result, 1, artist, sizeof(artist));
		SQL_FetchString(result, 2, album, sizeof(album));
		
		new clients_list[1]; clients_list[0] = client;
		DisplayTrackInfo(clients_list, 1, title, artist, album);
	}
	
	return;
}



AddClients(id, clients_list[], update_count, bool:lock=false) {
	decl String:key[9], String:play_url[256];
	new volume_target = FindOption("volume");
	decl String:base_url[128];
	new temp_volume;
	new volume_min = GetConVarInt(cv_volume_min);

	GetConVarString(cv_base_url, base_url, sizeof(base_url));
	if(base_url[strlen(base_url)-1] != '/') {
		Format(base_url, sizeof(base_url), "%s/", base_url);
	}

	for(new i = 0; i < update_count; i++) {
		AssignStreamToClient(clients_list[i], id);
		play_lock[clients_list[i]] = lock;
	}
	
	GenerateKey(key, sizeof(key)); // Encrypts a time stamp into the URL to prevent leeching

	for(new i = 0; i < update_count; i++) {
		if(now_volume[clients_list[i]] < 0) {
			StopMOTD(clients_list[i]);
		} else {
			if(now_volume[clients_list[i]] > 0) {
				temp_volume = now_volume[clients_list[i]];
			} else {
				temp_volume = options[clients_list[i]][volume_target];
				now_volume[clients_list[i]] = temp_volume;
			}
			if(temp_volume > 0) {
				if(temp_volume < volume_min) {
					temp_volume = volume_min;
				}
				FormatEx(play_url, sizeof(play_url), "%squery.php?sid=%d&key=%s&vol=%d", base_url, id, key, temp_volume);
				LoadMOTDPanelHidden(clients_list[i], "Jukebox - Source Engine Streaming Music System", play_url, MOTDPANEL_TYPE_URL);
				// ShowMOTDPanel(clients_list[i], "Jukebox - Source Engine Streaming Music System", play_url, MOTDPANEL_TYPE_URL); // DEBUG
				// PrintToConsole(clients_list[i], "Playing URL: %s", play_url); // DEBUG
			}
		}
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
	new Handle:results_temp = CreateKeyValues("Results");
	
	if(results_storage[client] != INVALID_HANDLE) {
		KvCopySubkeys(results_storage[client], results_temp);
	}
	
	return results_temp;
}



RemoveResults(client) {
	
	return CloseHandle2(results_storage[client]);
	
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



EncodeRC4(const String:input[], const String:pwd[], String:output[], maxlen, str_len = 0) {
	decl pwd_len,i,j,a,k;
	decl key[256];
	decl box[256];
	decl tmp;
	new write_length;
	pwd_len = strlen(pwd);
	if(str_len == 0) {
		str_len = strlen(input);
	}
	if(pwd_len > 0 && str_len > 0) {
		for(i=0;i<256;i++) {
			key[i] = pwd[i%pwd_len];
			box[i]=i;
		}
		i=0;
		j=0;
		for(;i<256;i++) {
			j = (j + box[i] + key[i]) & 0xff;
			tmp = box[i];
			box[i] = box[j];
			box[j] = tmp;
		}
		i=0;
		j=0;
		a=0;
		output[0] = '\0';
		for(;i<str_len;i++)	{
			a = (a + 1) & 0xff;
			j = (j + box[a]) & 0xff;
			tmp = box[a];
			box[a] = box[j];
			box[j] = tmp;
			k = box[((box[a] + box[j]) & 0xff)];
			write_length = Format(output, maxlen, "%s%02x", output, input[i] ^ k);
		}
		return write_length;
	} else {
		return -1;
	}
}



PlaybackMenu(client) {
	if(PrepareConnection()) {	
		decl String:query[1536];

		FormatEx(query, sizeof(query), "SELECT UNIX_TIMESTAMP(st.`start_time`) + sta.`all_playtime` - UNIX_TIMESTAMP() AS 'time_left', st.`creator_steam`, st.`playall`, tr.`title`, UNIX_TIMESTAMP() - UNIX_TIMESTAMP(st.`start_time`) - std.`done_playtime` AS 'duration', CAST(tr.`playtime` AS SIGNED) AS 'playtime' FROM %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence` LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` LEFT JOIN (SELECT COALESCE(pla.`stream_id`, 0) AS 'match_id', CAST(SUM(tra.`playtime`) AS SIGNED) AS 'all_playtime' FROM %s AS pla LEFT JOIN %s AS tra ON pla.`track_id` = tra.`id` GROUP BY pla.`stream_id`) AS sta ON st.`stream_id` = sta.`match_id`", db_streams, db_playlists, db_tracks, db_playlists, db_tracks);
		Format(query, sizeof(query), "%s LEFT JOIN (SELECT COALESCE(std.`stream_id`, 0) AS 'match_id', CAST(COALESCE(SUM(trd.`playtime`), 0) AS SIGNED) AS 'done_playtime' FROM %s AS std LEFT JOIN %s AS pld ON std.`stream_id` = pld.`stream_id` AND std.`now_playing` > pld.`sequence` LEFT JOIN %s AS trd ON pld.`track_id` = trd.`id` GROUP BY std.`stream_id`) AS std ON st.`stream_id` = std.`match_id` WHERE st.`stream_id` = %d GROUP BY st.`stream_id`", query, db_streams, db_playlists, db_tracks, stream_memberships[client]);
		
		SQL_TQuery(music_db, Query_PlaybackMenu, query, client);
	}
	
	return;
}


public Query_PlaybackMenu(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to lookup playback status from stream %d for client %d.  Error: %s", stream_memberships[client], client, error);
	} else if(!IsClientInGame(client) || IsFakeClient(client)) {
		// END
	} else if(!SQL_FetchRow(result)) {
		// LogError("Looking up playback status from stream %d for client %d returned no results.", stream_memberships[client], client);
		MainMenu(client);
	} else {
		decl String:creator_steam[25], String:user_steam[25], String:title[80];
		new display_time = SQL_FetchInt(result, 0);
		new bool:is_owner, bool:is_admin = PermissionCheck(client, cv_admin_flags_reserved);
		SQL_FetchString(result, 1, creator_steam, sizeof(creator_steam));
		new playall = SQL_FetchInt(result, 2);
		if (display_time > menu_maxtime) {
			display_time = menu_maxtime;
		}
		SQL_FetchString(result, 3, title, sizeof(title));
		new duration = SQL_FetchInt(result, 4);
		new playtime = SQL_FetchInt(result, 5);
		GetClientAuthString(client, user_steam, sizeof(user_steam));
		if(StrEqual(creator_steam, user_steam)) {
			is_owner = true;
		}
		
		new String:menu_title[128];
		FormatEx(menu_title, sizeof(menu_title), "Jukebox - Playing \"%s\" (%s%d:%02d of %d:%02d)", title, (duration < 0 ? "-" : ""), abs(duration/60), abs(duration%60), playtime/60, playtime%60);
		
		new Handle:playback_menu = CreateMenu(PlaybackMenuHandler);
		SetMenuPagination(playback_menu, MENU_NO_PAGINATION);
		SetMenuExitButton(playback_menu, true);
		SetMenuTitle(playback_menu, menu_title);
		
		if (!play_lock[client]) {
			if(is_owner || (playall > 0 && is_admin)) {
				AddMenuItem(playback_menu, "1", "Queue additional tracks");
			} else {
				AddMenuItem(playback_menu, "", "", ITEMDRAW_SPACER);
			}
			if(!is_owner || !options[client][FindOption("autoqueue")]) {
				AddMenuItem(playback_menu, "2", "Play new tracks");
			} else {
				AddMenuItem(playback_menu, "", "", ITEMDRAW_SPACER);
			}
			if(now_volume[client] >= 0) {
				AddMenuItem(playback_menu, "3", "Mute");
			} else {
				AddMenuItem(playback_menu, "3", "Unmute");
			}
			AddMenuItem(playback_menu, "4", "Stop Playback");
		} else {
			for(new i = 1; i <= 4; i++) {
				AddMenuItem(playback_menu, "", "", ITEMDRAW_SPACER);
			}
		}
		if(now_volume[client] < 100 && now_volume[client] >= 0) {
			AddMenuItem(playback_menu, "5", "Volume Up");
		} else {
			AddMenuItem(playback_menu, "", "", ITEMDRAW_SPACER);
		}
		if(now_volume[client] > GetConVarInt(cv_volume_min)) {
			AddMenuItem(playback_menu, "6", "Volume Down");
		} else {
			AddMenuItem(playback_menu, "", "", ITEMDRAW_SPACER);
		}
		AddMenuItem(playback_menu, "7", "Settings");
		AddMenuItem(playback_menu, "8", "Help");
		
		DisplayMenu(playback_menu, client, display_time);
	}
	
	return;
}



public PlaybackMenuHandler(Handle:menu, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		if (stream_memberships[client] <= 0) {
			return;
		}
		
		decl String:info_string[2];
		new info;
		GetMenuItem(menu, position, info_string, sizeof(info_string));
		info = StringToInt(info_string);
		new bool:refresh_playback = false, bool:display_again = false, bool:volume_change = false;
		switch (info) {
			case 1: { // Queue additional tracks
				new Handle:args = GetResults(client);
				AddCommand(args, "queue");
				SaveResults(client, args);
				CloseHandle(args);
				MainMenu(client);
			}
			case 2: { // Play new tracks
				MainMenu(client);
			}
			case 3: { // Mute / Unmute
				now_volume[client] = -now_volume[client];
				refresh_playback = true;
				display_again = true;
			}
			case 4: { // Stop Playback
				JbOff(client);
			}
			case 5: { // Volume Up
				new current_volume = now_volume[client];
				now_volume[client] += 10;
				if (now_volume[client] > 100) {
					now_volume[client] = 100;
				}
				if(current_volume != now_volume[client]) {
					volume_change = true;
				}
				display_again = true;
			}
			case 6: { // Volume Down
				new current_volume = now_volume[client];
				new volume_min = GetConVarInt(cv_volume_min);
				now_volume[client] -= 10;
				if (now_volume[client] < volume_min) {
					now_volume[client] = volume_min;
				}
				if(current_volume != now_volume[client]) {
					volume_change = true;
				}
				display_again = true;
			}
			case 7: { // Settings
				SettingsMenu(client);
			}
			case 8: { // Help
				HelpMenu(client);
			}
		}
		
		if(volume_change) {
			if(volume_timer_enabled[client]) {
				KillTimer(volume_timers[client]);
			}
			volume_timers[client] = CreateTimer(1.0, RefreshVolume, client);
			volume_timer_enabled[client] = true;
			PrintToChat(client, "%c[JB]%c Stream Volume set to %d%%.", cLightGreen, cDefault, now_volume[client]);
		}
		if(refresh_playback) {
			new clients_list[1];
			clients_list[0] = client;
			AddClients(stream_memberships[client], clients_list, 1, play_lock[client]);
		}
		if(display_again) {
			PlaybackMenu(client);
		}
		
	} else if (action == MenuAction_Cancel) {
		RemoveResults(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}



public Action:RefreshVolume(Handle:timer, any:client) {
	volume_timer_enabled[client] = false;
	if (stream_memberships[client] <= 0) {
		return;
	}
	
	new clients_list[1];
	clients_list[0] = client;
	AddClients(stream_memberships[client], clients_list, 1, play_lock[client]);
	
	return;
}



abs(value) {
	if(value < 0) {
		return -value;
	} else {
		return value;
	}
}



CreateLogStats(stream_id, clients_list[], length) {
	decl String:query[512];
	
	FormatEx(query, sizeof(query), "SELECT tr.`id`, UNIX_TIMESTAMP(st.`start_time`) + COALESCE(SUM(tr2.`playtime`), 0) AS 'start', UNIX_TIMESTAMP() AS 'now' FROM %s AS st LEFT JOIN %s AS pl ON st.`stream_id` = pl.`stream_id` AND st.`now_playing` = pl.`sequence` LEFT JOIN %s AS tr ON pl.`track_id` = tr.`id` LEFT JOIN %s AS pl2 ON st.`stream_id` = pl2.`stream_id` AND st.`now_playing` > pl2.`sequence` LEFT JOIN %s AS tr2 ON pl2.`track_id` = tr2.`id` WHERE st.`stream_id` = %d", db_streams, db_playlists, db_tracks, db_playlists, db_tracks, stream_id);
	new Handle:datapack = CreateDataPack();
	WritePackCell(datapack, length);
	for(new i = 0; i < length; i++) {
		WritePackCell(datapack, clients_list[i]);
	}
	SQL_TQuery(music_db, Query_CreateLogStats1, query, datapack);
	
	return;
}


public Query_CreateLogStats1(Handle:owner, Handle:result, const String:error[], any:datapack) {
	if(result == INVALID_HANDLE) {
		LogError("Failed to look up track start time info for log.  Error: %s", error);
	} else if(!SQL_FetchRow(result)) {
		LogError("Look up of track start time info returned no results.");
	} else {
		decl String:query[4096];
		new String:separator[2] = "";
		new bool:do_log, multiple_test;
		new length, track_id, joined, start;
		
		ResetPack(datapack);
		length = ReadPackCell(datapack);
		new clients_list[length];
		for(new i = 0; i < length; i++) {
			clients_list[i] = ReadPackCell(datapack);
		}
		
		track_id = SQL_FetchInt(result, 0);
		start = SQL_FetchInt(result, 1);
		joined = SQL_FetchInt(result, 2) - start;
		
		FormatEx(query, sizeof(query), "INSERT INTO %s (`user_id`, `username_id`, `track_id`, `start`, `joined`) VALUES", db_log_history);
		for(new i = 0; i < length; i++) {
			if(log_username_entry[clients_list[i]][0] > 0 && log_username_entry[clients_list[i]][1] > 0) {
				do_log = true;
				Format(query, sizeof(query), "%s%s (%d, %d, %d, FROM_UNIXTIME(%d), %d)", query, separator, log_username_entry[clients_list[i]][0], log_username_entry[clients_list[i]][1], track_id, start, joined);
				if(!MultipleTest(multiple_test)) {
					strcopy(separator, sizeof(separator), ",");
				}
			}
		}
		if(do_log) {
			SQL_TQuery(music_db, Query_CreateLogStats2, query, 0, DBPrio_Low);
		}
	}
	CloseHandle(datapack);
	
	return;
}


public Query_CreateLogStats2(Handle:owner, Handle:result, const String:error[], any:empty) {
	if(strlen(error) > 0) {
		LogError("Failed to create new log entries.  Error: %s", error);
	}
	
	return;
}



FinishLogStats(clients_list[], length) {
	decl String:query[1024];
	new String:separator[2] = "";
	new bool:do_log;
	query[0] = '\0';
	for(new i = 0; i < length; i++) {
		if(clients_list[i] > 0) {
			Format(query, sizeof(query), "%s%s%d", query, separator, clients_list[i]);
			if(!MultipleTest(do_log)) {
				strcopy(separator, sizeof(separator), ",");
			}
		}
	}
	
	if(do_log) {
		Format(query, sizeof(query), "UPDATE %s AS hi INNER JOIN %s AS tr ON hi.`track_id` = tr.`id` SET hi.`finish` = IF(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(hi.`start`) > ROUND(tr.`playtime`), ROUND(tr.`playtime`), UNIX_TIMESTAMP() - UNIX_TIMESTAMP(hi.`start`)) WHERE hi.`finish` = 0 AND `user_id` IN (%s)", db_log_history, db_tracks, query);
		SQL_TQuery(music_db, Query_FinishLogStats, query);
	}
	
	return;
}


public Query_FinishLogStats(Handle:owner, Handle:result, const String:error[], any:empty) {
	if(strlen(error) > 0) {
		LogError("Failed to update log entries.  Error: %s", error);
	}
	
	return;
}



GetStatsUsernameNumber(client) {
	decl String:steam_id[25], String:query[128];
	if(PrepareConnection() && IsClientConnected(client) && !IsFakeClient(client) && GetClientAuthString(client, steam_id, sizeof(steam_id))) {
		FormatEx(query, sizeof(query), "SELECT `id` FROM %s WHERE `steamid` = '%s'", db_options, steam_id);
		SQL_TQuery(music_db, Query_GetStatsUsernameNumber1, query, client, DBPrio_Low);
		
		decl String:username[username_length], String:username_esc[2*sizeof(username)+1];
		GetClientName(client, username, sizeof(username));
		SQL_EscapeString(music_db, username, username_esc, sizeof(username_esc));
		FormatEx(query, sizeof(query), "SELECT `id` FROM %s WHERE `username` = '%s'", db_log_usernames, username_esc);
		SQL_TQuery(music_db, Query_GetStatsUsernameNumber2, query, client, DBPrio_Low);
	}
	
	return;
}


public Query_GetStatsUsernameNumber1(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed check for existing Steam ID.  Error: %s", error);
	} else if(!SQL_FetchRow(result)) {
		LogError("Check for existing Steam ID returned no results.  Error: %s", error);
	} else if(IsClientInGame(client) || !IsFakeClient(client)) {
		log_username_entry[client][0] = SQL_FetchInt(result, 0);
		// GetStatsUsernameNumber2(client, id_user);
	}
	
	return;
}


public Query_GetStatsUsernameNumber2(Handle:owner, Handle:result, const String:error[], any:client) {
	if(result == INVALID_HANDLE) {
		LogError("Failed check for existing Username.  Error: %s", error);
	} else if(!IsClientInGame(client) || IsFakeClient(client)) {
		// End
	} else if(SQL_FetchRow(result)) {
		log_username_entry[client][1] = SQL_FetchInt(result, 0);
	} else {
		decl String:query[192];
		
		decl String:username[username_length], String:username_esc[2*sizeof(username)+1];
		GetClientName(client, username, sizeof(username));
		SQL_EscapeString(music_db, username, username_esc, sizeof(username_esc));
		
		FormatEx(query, sizeof(query), "INSERT INTO %s (`username`) VALUES ('%s')", db_log_usernames, username_esc);
		SQL_TQuery(music_db, Query_GetStatsUsernameNumber2b, query, client, DBPrio_Low);
	}
	
	return;
}


public Query_GetStatsUsernameNumber2b(Handle:owner, Handle:result, const String:error[], any:client) {
	if(strlen(error) > 0) {
		LogError("Failed to create new Username entry.  Error: %s", error);
	} else if(IsClientInGame(client) && !IsFakeClient(client)) {
		log_username_entry[client][1] = SQL_GetInsertId(music_db);
	}
	
	return;
}



bool:PermissionCheck(client, Handle:admin_flags) {
	decl String:flag_string[32];
	GetConVarString(admin_flags, flag_string, sizeof(flag_string));
	new flags = ReadFlagString(flag_string);
	
	return (flags == 0 || (GetUserFlagBits(client) & flags));
}
