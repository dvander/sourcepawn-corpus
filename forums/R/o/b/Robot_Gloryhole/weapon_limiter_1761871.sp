/***
 *    $$\      $$\                                                   
 *    $$ | $\  $$ |                                                  
 *    $$ |$$$\ $$ | $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\  
 *    $$ $$ $$\$$ |$$  __$$\  \____$$\ $$  __$$\ $$  __$$\ $$  __$$\ 
 *    $$$$  _$$$$ |$$$$$$$$ | $$$$$$$ |$$ /  $$ |$$ /  $$ |$$ |  $$ |
 *    $$$  / \$$$ |$$   ____|$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
 *    $$  /   \$$ |\$$$$$$$\ \$$$$$$$ |$$$$$$$  |\$$$$$$  |$$ |  $$ |
 *    \__/     \__| \_______| \_______|$$  ____/  \______/ \__|  \__|
 *                                     $$ |                          
 *                                     $$ |                          
 *                                     \__|                          
 *    $$\       $$\               $$\   $$\                          
 *    $$ |      \__|              \__|  $$ |                         
 *    $$ |      $$\ $$$$$$\$$$$\  $$\ $$$$$$\    $$$$$$\   $$$$$$\   
 *    $$ |      $$ |$$  _$$  _$$\ $$ |\_$$  _|  $$  __$$\ $$  __$$\  
 *    $$ |      $$ |$$ / $$ / $$ |$$ |  $$ |    $$$$$$$$ |$$ |  \__| 
 *    $$ |      $$ |$$ | $$ | $$ |$$ |  $$ |$$\ $$   ____|$$ |       
 *    $$$$$$$$\ $$ |$$ | $$ | $$ |$$ |  \$$$$  |\$$$$$$$\ $$ |       
 *    \________|\__|\__| \__| \__|\__|   \____/  \_______|\__|  
 * 
 *
 * This plugin limits the number of specific weapons or weapon classes on
 * a per team / per server basis. When a limit is reached, the last player
 * to equip the limited weapon will have that weapon's slot removed until
 * they change weapons. Limits can be specified in a configuration file
 * "weapon_limits.cfg", or using the console.
 *
 * See weapon_limits.cfg for usage.
 *
 *	 Change log:
 * 		0.5.0 - Initial public version, including *some* comments
 *		0.5.1 - Added printing of limits/whitelist on plugin launch, changed a bunch of "new" to "decl"
 *		0.5.2 - Added HUD message informing the client when they equip a limited weapon
 *		0.5.3 - Added commands to mute chat and/or HUD messages
 *		0.6.0 - Added commands to load the configuration and clear limits/whitelist entries
 *
 */

#include <tf2>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>

#pragma semicolon 1

/***
 * Cool giant text from http://patorjk.com/software/taag/
 * Font: 'Big Money-nw'
 */

/***
 *    $$$$$$$\             $$$$$$\  $$\                                                                         
 *    $$  __$$\           $$  __$$\ \__|                                                                        
 *    $$ |  $$ | $$$$$$\  $$ /  \__|$$\ $$$$$$$\   $$$$$$\   $$$$$$$\                                           
 *    $$ |  $$ |$$  __$$\ $$$$\     $$ |$$  __$$\ $$  __$$\ $$  _____|                                          
 *    $$ |  $$ |$$$$$$$$ |$$  _|    $$ |$$ |  $$ |$$$$$$$$ |\$$$$$$\                                            
 *    $$ |  $$ |$$   ____|$$ |      $$ |$$ |  $$ |$$   ____| \____$$\                                           
 *    $$$$$$$  |\$$$$$$$\ $$ |      $$ |$$ |  $$ |\$$$$$$$\ $$$$$$$  |                                          
 *    \_______/  \_______|\__|      \__|\__|  \__| \_______|\_______/
 */

// *********************** //
// *** PLUGIN SETTINGS *** //
// *********************** //
#define PLUGIN_NAME 					"[TF2] Weapon Limiter"
#define PLUGIN_VERSION 					"0.6.0"
#define PLUGIN_BUILDDATE 				"14 Aug 2013"
#define PLUGIN_AUTHOR 					"Robot Gloryhole"
#define PLUGIN_CONTACT					"http://forums.alliedmods.net/"
#define PLUGIN_DESCRIPTION				"Limit the number of weapons that can be equipped by players"
#define PLUGIN_CONFIG 					"weapon_limiter"
// pefixes to use in messages to the server/player
#define PREFIX_COMMAND					"[WL]"
#define PREFIX_CHAT						PREFIX_COMMAND
#define PREFIX_HUD						"[Weapon Limiter]"

// ********************** //
// *** STRING LENGTHS *** //
// ********************** //
#define STRLEN_ItemClass				150
#define STRLEN_ItemName					150
#define STRLEN_AuthString				48
#define STRLEN_PlayerName				MAX_NAME_LENGTH
#define STRLEN_NumberKey				10
#define STRLEN_IPAddress				20
#define STRLEN_TeamName					10
#define STRLEN_PlayerClass				20
#define STRLEN_ItemSlot					20
#define STRLEN_DBError					255

// Handle little define for when we want to specify "no" client
#define UNDEFINED_CLIENT				-1

// ************************ //
// *** DATABASE QUERIES *** //
// ************************ //
// let's define 'undefined' for database fields to avoid confusion
#define UNDEFINED_NUMBER				-1
#define UNDEFINED_STRING				''
// slot queries
#define DBQ_SLOT_DROPTABLE				"DROP TABLE IF EXISTS slots"
#define DBQ_SLOT_CREATETABLE			"CREATE TABLE slots (player_id VARCHAR(48), player_team INTEGER, player_class INTEGER, item_slot INTEGER, item_definition INTEGER, item_class VARCHAR(150), timestamp INTEGER, CONSTRAINT  mkey PRIMARY KEY (player_id, item_slot) ON CONFLICT REPLACE)"
#define DBQ_SLOT_INSERT					"INSERT INTO slots(player_id, player_team, player_class, item_slot, item_definition, item_class, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)"
#define DBQ_SLOT_RETRIEVE_DETAILS		"SELECT * FROM slots WHERE player_id = ? AND item_slot = ?"
#define DBQ_SLOT_DELETE_ROW				"DELETE FROM slots WHERE player_id = ? AND item_slot = ?"
#define DBQ_SLOT_DELETE_PLAYER			"DELETE FROM slots WHERE player_id = ?"
#define DBQ_SLOT_FETCH_ROWS				"SELECT * FROM slots WHERE (item_class = ? OR '' = ?) AND (item_definition = ? OR '-1' = ?) AND (item_slot = ? OR '-1' = ?)"
// limit queries
#define DBQ_LIMITS_DROPTABLE			"DROP TABLE IF EXISTS limits"
#define DBQ_LIMITS_CREATETABLE			"CREATE TABLE limits (key INTEGER PRIMARY KEY AUTOINCREMENT, total_limit INTEGER, red_limit INTEGER, blue_limit INTEGER, player_class INTEGER, item_slot INTEGER, item_definition INTEGER, item_class VARCHAR(150))"
#define DBQ_LIMITS_INSERT				"INSERT INTO limits(total_limit, red_limit, blue_limit, player_class, item_slot, item_definition, item_class) VALUES (?, ?, ?, ?, ?, ?, ?)"
#define DBQ_LIMITS_SELECT				"SELECT * FROM limits WHERE item_slot = ? OR item_definition = ? OR item_class = ?"
#define DBQ_LIMITS_SELECT_ALL			"SELECT * FROM limits"
#define DBQ_LIMITS_REMOVE_BY_KEY		"DELETE FROM limits WHERE key = ?"
#define DBQ_LIMITS_REMOVE_ALL			"DELETE FROM limits"
// player whitelist
#define DBQ_WHITELIST_DROPTABLE			"DROP TABLE IF EXISTS whitelist"
#define DBQ_WHITELIST_CREATETABLE		"CREATE TABLE whitelist (key INTEGER PRIMARY KEY AUTOINCREMENT, player_id VARCHAR(48), item_slot INTEGER, item_definition INTEGER, item_class VARCHAR(150))"
#define DBQ_WHITELIST_INSERT			"INSERT INTO whitelist (player_id, item_slot, item_definition, item_class) VALUES (?, ?, ?, ?)"
#define DBQ_WHITELIST_RETRIEVE			"SELECT * FROM whitelist WHERE player_id = ? AND (item_slot = ? OR item_slot = '-1') AND (item_definition = ? OR item_definition = '-1') AND (item_class = ? OR item_class = '')"
#define DBQ_WHITELIST_SELECT_ALL		"SELECT * FROM whitelist"
#define DBQ_WHITELIST_REMOVE_BY_KEY		"DELETE FROM whitelist WHERE key = ?"
#define DBQ_WHITELIST_REMOVE_ALL		"DELETE FROM whitelist"

// ********************* //
// *** CONFIGURATION *** //
// ********************* //
// configuration directory
#define KV_ConfigurationDirectory		"configs/"
// configuration file
#define KV_ConfigurationFile			"weapon_limits.cfg"
// configuration file keys
#define KV_KeyEnabled					"Enabled"
#define KV_KeyChatEnabled				"ChatEnabled"
#define KV_KeyHUDEnabled				"HUDEnabled"
#define KV_KeyLimits					"Limits"
#define KV_KeyWhitelist					"Whitelist"
#define KV_KeyPlayerID					"player_id"
#define KV_KeyPlayerClass				"player_class"
#define KV_KeyItemSlot					"slot"
#define KV_KeyItemClass					"item_class"
#define KV_KeyItemDefinition			"item_index"
#define KV_KeyLimitBlue					"blue"
#define KV_KeyLimitRed					"red"
#define KV_KeyLimitTeam					"team"
#define KV_KeyLimitTotal				"total"

// ****************** //
// *** ITEMS_GAME *** //
// ****************** //
// path to items_game (holds all the weapons)
#define PATH_ITEMS_GAME					"scripts/items/items_game.txt"
// keys for items_game.txt file
#define KV_KeyItemsGameItems			"items"
#define KV_KeyItemsGameName				"name"

// ********************************** //
// *** CONSOLE USAGE DESCRIPTIONS *** //
// ********************************** //
#define USAGE_Help						"%s Usage: weaplimit_help"
#define USAGE_Enabled					"%s Usage: weaplimit_enabled <1|0>"
#define USAGE_ChatEnabled				"%s Usage: weaplimit_chatenabled <1|0>"
#define USAGE_HUDEnabled				"%s Usage: weaplimit_hudenabled <1|0>"
#define USAGE_AddLimit					"%s Usage: weaplimit_addlimit <total limit> <red limit> <blue limit> <player class> <item slot> <item index|item class>"
#define USAGE_PrintLimits				"%s Usage: weaplimit_printlimits"
#define USAGE_RemoveLimit				"%s Usage: weaplimit_removelimit <limit key>"
#define USAGE_ClearLimits				"%s Usage: weaplimit_clearlimits"
#define USAGE_AddWhitelist				"%s Usage: weaplimit_addwhitelist <userid> <item slot> <item index|item class>"
#define USAGE_PrintWhitelist			"%s Usage: weaplimit_printwhitelist"
#define USAGE_RemoveWhitelist			"%s Usage: weaplimit_removewhitelist <whitelist key>"
#define USAGE_ClearWhitelist			"%s Usage: weaplimit_clearwhitelist"
#define USAGE_LoadConfig				"%s Usage: weaplimit_loadconfig <config file>"

/***
 *     $$$$$$\  $$\           $$\                 $$\                                                           
 *    $$  __$$\ $$ |          $$ |                $$ |                                                          
 *    $$ /  \__|$$ | $$$$$$\  $$$$$$$\   $$$$$$\  $$ | $$$$$$$\                                                 
 *    $$ |$$$$\ $$ |$$  __$$\ $$  __$$\  \____$$\ $$ |$$  _____|                                                
 *    $$ |\_$$ |$$ |$$ /  $$ |$$ |  $$ | $$$$$$$ |$$ |\$$$$$$\                                                  
 *    $$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$  __$$ |$$ | \____$$\                                                 
 *    \$$$$$$  |$$ |\$$$$$$  |$$$$$$$  |\$$$$$$$ |$$ |$$$$$$$  |                                                
 *     \______/ \__| \______/ \_______/  \_______|\__|\_______/
 */
// player classes - used by config
new String:g_PlayerClassStrings[][] = {"unknown", "scout", "sni", "sol", "demo", "medic", "heavy", "pyro", "spy", "engi"};
// item slots - used by config
new String:g_ItemSlotStrings[][] = {"pri", "sec", "mel", "gre", "bui", "pda", "item1", "item2"};
// plugin enabled
new bool:g_PluginEnabled;
// output to chat enabled
new bool:g_OutputChatEnabled;
// output to HUD enabled
new bool:g_OutputHUDEnabled;
// item_games Vault
new Handle:g_VaultItemsGame = INVALID_HANDLE;
// shared database connection
new Handle:g_DatabaseConnection;

// ********************************** //
// *** PPREPARED DATABASE QUERIES *** //
// ********************************** //
// whitelist
new Handle:g_PreparedQueryWhitelistInsert;
new Handle:g_PreparedQueryWhitelistForPlayer;
new Handle:g_PreparedQueryWhitelistAll;
new Handle:g_PreparedQueryWhitelistRemoveByKey;
new Handle:g_PreparedQueryWhitelistRemoveAll;
// limits
new Handle:g_PreparedQueryLimitsInsert;
new Handle:g_PreparedQueryLimitsForItem;
new Handle:g_PreparedQueryLimitsAll;
new Handle:g_PreparedQueryLimitRemoveByKey;
new Handle:g_PreparedQueryLimitRemoveAll;
// slots
new Handle:g_PreparedQuerySlotInsert;
new Handle:g_PreparedQuerySlotSelectDetails;
new Handle:g_PreparedQuerySlotDeleteDetails;
new Handle:g_PreparedQuerySlotDeletePlayer;
new Handle:g_PreparedQuerySlotDetailsComplex;

/***
 *    $$$$$$$\  $$\                     $$\                                                                     
 *    $$  __$$\ $$ |                    \__|                                                                    
 *    $$ |  $$ |$$ |$$\   $$\  $$$$$$\  $$\ $$$$$$$\                                                            
 *    $$$$$$$  |$$ |$$ |  $$ |$$  __$$\ $$ |$$  __$$\                                                           
 *    $$  ____/ $$ |$$ |  $$ |$$ /  $$ |$$ |$$ |  $$ |                                                          
 *    $$ |      $$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |                                                          
 *    $$ |      $$ |\$$$$$$  |\$$$$$$$ |$$ |$$ |  $$ |                                                          
 *    \__|      \__| \______/  \____$$ |\__|\__|  \__|                                                          
 *                            $$\   $$ |                                                                        
 *                            \$$$$$$  |                                                                        
 *                             \______/
 */

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
}

/* OnPluginStart()
 *
 * When the plugin starts up.
 * - Add the console commands
 * - Add event hooks
 * - Load the item_games KV vault
 * - Initialise the database
 * - Load the configuration & parse it
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	CreateConVar("weaplimit_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//
	RegAdminCmd("weaplimit_help", Command_Help, ADMFLAG_GENERIC, USAGE_Help);
	//
	RegAdminCmd("weaplimit_enabled", Command_Enabled, ADMFLAG_GENERIC, USAGE_Enabled);
	RegAdminCmd("weaplimit_chatenabled", Command_ChatEnabled, ADMFLAG_GENERIC, USAGE_ChatEnabled);
	RegAdminCmd("weaplimit_hudenabled", Command_HUDEnabled, ADMFLAG_GENERIC, USAGE_HUDEnabled);
	//
	RegAdminCmd("weaplimit_addlimit", Command_AddLimit, ADMFLAG_GENERIC, USAGE_AddLimit);
	RegAdminCmd("weaplimit_printlimits", Command_PrintLimits, ADMFLAG_GENERIC, USAGE_PrintLimits);
	RegAdminCmd("weaplimit_removelimit", Command_RemoveLimit, ADMFLAG_GENERIC, USAGE_RemoveLimit);
	RegAdminCmd("weaplimit_clearlimits", Command_ClearLimits, ADMFLAG_GENERIC, USAGE_ClearLimits);
	//
	RegAdminCmd("weaplimit_addwhitelist", Command_AddWhitelist, ADMFLAG_GENERIC, USAGE_AddWhitelist);
	RegAdminCmd("weaplimit_printwhitelist", Command_PrintWhitelist, ADMFLAG_GENERIC, USAGE_PrintWhitelist);
	RegAdminCmd("weaplimit_removewhitelist", Command_RemoveWhitelist, ADMFLAG_GENERIC, USAGE_RemoveWhitelist);
	RegAdminCmd("weaplimit_clearwhitelist", Command_ClearWhitelist, ADMFLAG_GENERIC, USAGE_ClearWhitelist);
	//
	RegAdminCmd("weaplimit_loadconfig", Command_LoadConfig, ADMFLAG_GENERIC, USAGE_LoadConfig);
	//
	/*************
	 *   Events  *
	 *************/
	HookEvent("post_inventory_application", Event_PostInventoryApplication, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnected, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerChangedTeams, EventHookMode_Post);
	/***********************
	 *   Items Game Vault  *
	 ***********************/
	if(!FileExists(PATH_ITEMS_GAME, true)) {
		SetFailState("items_game.txt does not exist. Something is seriously wrong!");
		return;
	}
	g_VaultItemsGame = CreateKeyValues("");
	if (!FileToKeyValues(g_VaultItemsGame, PATH_ITEMS_GAME)) {
		SetFailState("Could not parse items_game.txt. Something is seriously wrong!");
		return;
	}
	/*******************
	 *     Database    *
	 *******************/
	InitialiseDataBase();
	/*******************
	 *   Configuration *
	 *******************/
	if (!ParseConfigurationFile(KV_ConfigurationFile)) {
		SetFailState("Failed to load configuration file");
		return;
	}
	/****************
	 *   Finish Up  *
	 ****************/
	ReplyToCommand(0, "\n%s %s loaded luccessfully", PREFIX_COMMAND, PLUGIN_NAME);
	ReplyToCommand(0, "%s Version %s (%s)\n", PREFIX_COMMAND, PLUGIN_VERSION, PLUGIN_BUILDDATE);
	ReplyToCommand(0, "%s Plugin Enabled = %i", PREFIX_COMMAND, g_PluginEnabled);
	ReplyToCommand(0, "%s Chat Enabled = %i", PREFIX_COMMAND, g_OutputChatEnabled);
	ReplyToCommand(0, "%s HUD Enabled = %i\n", PREFIX_COMMAND, g_OutputHUDEnabled);
	ReplyToCommand(0, USAGE_Help, PREFIX_COMMAND);
	ReplyToCommand(0, "");
	Command_PrintWhitelist(UNDEFINED_CLIENT,-1);
	Command_PrintLimits(UNDEFINED_CLIENT,-1);
	AutoExecConfig(true, PLUGIN_CONFIG);
}

/***
 *     $$$$$$\                                                                  $$\                             
 *    $$  __$$\                                                                 $$ |                            
 *    $$ /  \__| $$$$$$\  $$$$$$\$$$$\  $$$$$$\$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$ | $$$$$$$\                   
 *    $$ |      $$  __$$\ $$  _$$  _$$\ $$  _$$  _$$\  \____$$\ $$  __$$\ $$  __$$ |$$  _____|                  
 *    $$ |      $$ /  $$ |$$ / $$ / $$ |$$ / $$ / $$ | $$$$$$$ |$$ |  $$ |$$ /  $$ |\$$$$$$\                    
 *    $$ |  $$\ $$ |  $$ |$$ | $$ | $$ |$$ | $$ | $$ |$$  __$$ |$$ |  $$ |$$ |  $$ | \____$$\                   
 *    \$$$$$$  |\$$$$$$  |$$ | $$ | $$ |$$ | $$ | $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |$$$$$$$  |                  
 *     \______/  \______/ \__| \__| \__|\__| \__| \__| \_______|\__|  \__| \_______|\_______/  
 */

/* Command_Help()
 *
 * Print all available commands
 * -------------------------------------------------------------------------- */
public Action:Command_Help(_client, _args)
{
	ReplyToCommand(_client, "%s Version %s (%s)\n", PREFIX_COMMAND, PLUGIN_VERSION, PLUGIN_BUILDDATE);
	ReplyToCommand(_client, USAGE_Help, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_Enabled, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_ChatEnabled, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_HUDEnabled, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_AddLimit, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_PrintLimits, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_RemoveLimit, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_AddWhitelist, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_PrintWhitelist, PREFIX_COMMAND);
	ReplyToCommand(_client, USAGE_RemoveWhitelist, PREFIX_COMMAND);
	ReplyToCommand(_client, "");
}

/* Command_PrintLimits()
 *
 * Print all the limits to the console
 * -------------------------------------------------------------------------- */
public Action:Command_PrintLimits(_client, _args)
{
	if (g_PreparedQueryLimitsAll == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryLimitsAll = SQL_PrepareQuery(g_DatabaseConnection, DBQ_LIMITS_SELECT_ALL, error, sizeof(error));
		if (g_PreparedQueryLimitsAll == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
		}
	}
	// execute
	if (!SQL_Execute(g_PreparedQueryLimitsAll)) {
		PrintToServer("%s WeaponCanEquip Execute failed.", PREFIX_COMMAND);
		return;
	}
	new bool:clientValid = IsValidClient(_client);
	new count = SQL_GetRowCount(g_PreparedQueryLimitsAll);
	if (clientValid) {
		ReplyToCommand(_client, "");
	}
	if (count > 0) {
		// limit field vars
		decl String:limitItemClass[STRLEN_ItemClass];
		new limitKey, limitTotal, limitRedTeam, limitBlueTeam, limitPlayerClass, limitItemSlot, limitItemDefinition;
		// loop through the rows
		new i = 0;
		while (SQL_FetchRow(g_PreparedQueryLimitsAll))
		{
			i++;
			limitKey = SQL_FetchInt(g_PreparedQueryLimitsAll, 0);
			limitTotal = SQL_FetchInt(g_PreparedQueryLimitsAll, 1);
			limitRedTeam = SQL_FetchInt(g_PreparedQueryLimitsAll, 2);
			limitBlueTeam = SQL_FetchInt(g_PreparedQueryLimitsAll, 3);
			limitPlayerClass = SQL_FetchInt(g_PreparedQueryLimitsAll, 4);
			limitItemSlot = SQL_FetchInt(g_PreparedQueryLimitsAll, 5);
			limitItemDefinition = SQL_FetchInt(g_PreparedQueryLimitsAll, 6);
			SQL_FetchString(g_PreparedQueryLimitsAll, 7, limitItemClass, sizeof(limitItemClass));
			// get the current team's limit
			if (clientValid) {
				ReplyToCommand(_client, "%s Limit %i of %i (key:'%i')", PREFIX_COMMAND, i, count, limitKey);
				ReplyToCommand(_client, " ˪ player class: %i, weapon slot: %i", limitPlayerClass, limitItemSlot);
				ReplyToCommand(_client, " ˪ item index: %i, item class: '%s'", limitItemDefinition, limitItemClass);
				ReplyToCommand(_client, " ˪ total limit: %i, red team: %i, blue team: %i", limitTotal, limitRedTeam, limitBlueTeam);
			} else {
				PrintToServer("%s Limit %i of %i (key:'%i')", PREFIX_COMMAND, i, count, limitKey);
				PrintToServer(" \\ player class: %i, weapon slot: %i", limitPlayerClass, limitItemSlot);
				PrintToServer(" \\ item index: %i, item class: '%s'", limitItemDefinition, limitItemClass);
				PrintToServer(" \\ total limit: %i, red team: %i, blue team: %i", limitTotal, limitRedTeam, limitBlueTeam);
			}
		}
		if (clientValid) {
			ReplyToCommand(_client, "");
		} else {
			PrintToServer("");
		}
	} else {
		if (clientValid) {
			ReplyToCommand(_client, "%s There are currently no limits.",PREFIX_COMMAND);
			ReplyToCommand(_client, "");
		} else {
			PrintToServer("%s There are currently no limits.",PREFIX_COMMAND);
			PrintToServer("");
		}
	}
}

/* Command_PrintWhitelist()
 *
 * Print current whitelist to the console
 * -------------------------------------------------------------------------- */
public Action:Command_PrintWhitelist(_client, _args)
{
	if (g_PreparedQueryWhitelistAll == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryWhitelistAll = SQL_PrepareQuery(g_DatabaseConnection, DBQ_WHITELIST_SELECT_ALL, error, sizeof(error));
		if (g_PreparedQueryWhitelistAll == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
		}
	}
	// execute
	if (!SQL_Execute(g_PreparedQueryWhitelistAll)) {
		PrintToServer("%s WeaponCanEquip Execute failed.", PREFIX_COMMAND);
		return;
	}
	new bool:clientValid = IsValidClient(_client);
	new count = SQL_GetRowCount(g_PreparedQueryWhitelistAll);
	if (clientValid) {
		ReplyToCommand(_client, "");
	}
	if (count > 0) {
		// limit field vars
		decl String:playerID[STRLEN_ItemClass];
		decl String:itemClass[STRLEN_ItemClass];
		new key, itemSlot, itemDefinition;
		// loop through the rows
		new i = 0;
		while (SQL_FetchRow(g_PreparedQueryWhitelistAll))
		{
			i++;
			key = SQL_FetchInt(g_PreparedQueryWhitelistAll, 0);
			SQL_FetchString(g_PreparedQueryWhitelistAll, 1, playerID, sizeof(playerID));
			itemSlot = SQL_FetchInt(g_PreparedQueryWhitelistAll, 2);
			itemDefinition = SQL_FetchInt(g_PreparedQueryWhitelistAll, 3);
			SQL_FetchString(g_PreparedQueryWhitelistAll, 4, itemClass, sizeof(itemClass));
			// get the current team's limit
			if (clientValid) {
				ReplyToCommand(_client, "%s Whitelist item %i of %i (key:'%i')", PREFIX_COMMAND, i, count, key);
				ReplyToCommand(_client, " ˪ player ID: %s, slot: %i", playerID, itemSlot);
				ReplyToCommand(_client, " ˪ item index: %i, item class: '%s'", itemDefinition, itemClass);
			} else {
				PrintToServer("%s Whitelist item %i of %i (key:'%i')", PREFIX_COMMAND, i, count, key);
				PrintToServer(" \\ player ID: %s, slot: %i", playerID, itemSlot);
				PrintToServer(" \\ item index: %i, item class: '%s'", itemDefinition, itemClass);
			}
		}
		if (clientValid) {
			ReplyToCommand(_client, "");
		} else {
			PrintToServer("");
		}
	} else {
		if (clientValid) {
			ReplyToCommand(_client, "%s There are currently no whitelist items.",PREFIX_COMMAND);
			ReplyToCommand(_client, "");
		} else {
			PrintToServer("%s There are currently no whitelist items.",PREFIX_COMMAND);
			PrintToServer("");
		}
	}
}

/* Command_AddLimit()
 *
 * Add a new limit to the plugin
 * -------------------------------------------------------------------------- */
public Action:Command_AddLimit(_client, _args)
{
	if (_args != 6) {
		ReplyToCommand(_client, USAGE_AddLimit, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	//
	decl String:itemClass[STRLEN_ItemClass];
	new itemDefinition, limitBlueTeam, limitRedTeam, limitTotal;
	new playerClass, itemSlot;
	new bool:valid;
	//
	valid = false;
	//
	decl String:buffer[255];
	// total limit
	GetCmdArg(1, buffer, sizeof(buffer));
	limitTotal = StringToInt(buffer);
	// red team limit
	GetCmdArg(2, buffer, sizeof(buffer));
	limitRedTeam = StringToInt(buffer);
	// blue team limit
	GetCmdArg(3, buffer, sizeof(buffer));
	limitBlueTeam = StringToInt(buffer);
	// player class
	GetCmdArg(4, buffer, sizeof(buffer));
	playerClass = GetPlayerClassTypeFromString(buffer);
	// item slot
	GetCmdArg(5, buffer, sizeof(buffer));
	itemSlot = GetItemSlotTypeFromString(buffer);
	// item definition / item class
	GetCmdArg(6, buffer, sizeof(buffer));
	new charsConsumed = StringToIntEx(buffer, itemDefinition);
	if (charsConsumed == 0) {
		itemDefinition = -1;
		strcopy(itemClass, sizeof(itemClass), buffer);
	} else {
		itemClass = "";
	}
	//
	if (strlen(itemClass) > 0) valid = true;
	if (itemDefinition >= 0) valid = true;
	if (itemSlot >= 0) valid = true;
	//
	if (limitTotal < 0 && limitBlueTeam < 0 && limitRedTeam < 0) valid = false;
	//
	if (valid) {
		Query_InsertLimitsRecord(limitTotal, limitRedTeam, limitBlueTeam, playerClass, itemSlot, itemDefinition, itemClass);
		ReplyToCommand(_client, "%s Limit added. type 'weaplimit_printlimits' to view current limits", PREFIX_COMMAND);
	} else {
		ReplyToCommand(_client, USAGE_AddLimit, PREFIX_COMMAND);
	}
	//  weaplimit_addlimit 1 1 2 scout primary 100
	//  weaplimit_addlimit 1 1 2 scout primary tf_weapon_rocketlauncher
	return Plugin_Handled;
}

/* Command_AddWhitelist()
 *
 * Add a new entry to the plugin's whitelist
 * -------------------------------------------------------------------------- */
public Action:Command_AddWhitelist(_client, _args)
{
	if (_args != 3) {
		ReplyToCommand(_client, USAGE_AddWhitelist, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	//
	decl String:playerID[STRLEN_ItemClass];
	decl String:itemClass[STRLEN_ItemClass];
	new itemDefinition, itemSlot;
	new bool:valid;
	//
	valid = false;
	//
	decl String:buffer[255];
	// player id
	GetCmdArg(1, buffer, sizeof(buffer));
	strcopy(playerID, sizeof(playerID), buffer);
	// item slot
	GetCmdArg(2, buffer, sizeof(buffer));
	itemSlot = GetItemSlotTypeFromString(buffer);
	// item definition / item class
	GetCmdArg(3, buffer, sizeof(buffer));
	new charsConsumed = StringToIntEx(buffer, itemDefinition);
	if (charsConsumed == 0) {
		itemDefinition = -1;
		strcopy(itemClass, sizeof(itemClass), buffer);
	} else {
		itemClass = "";
	}
	//
	if (strlen(itemClass) > 0) valid = true;
	if (itemDefinition >= 0) valid = true;
	if (itemSlot >= 0) valid = true;
	//
	valid = valid & (strlen(playerID) > 0);
	//
	if (valid) {
		Query_InsertWhitelistRecord(playerID, itemSlot, itemDefinition, itemClass);
		ReplyToCommand(_client, "%s Whitelist entry added. type 'weaplimit_printwhitelist' to view current whitelist", PREFIX_COMMAND);
	} else {
		ReplyToCommand(_client, USAGE_AddWhitelist, PREFIX_COMMAND);
	}
	//  weaplimit_addlimit 1 1 2 scout primary 100
	//  weaplimit_addlimit 1 1 2 scout primary tf_weapon_rocketlauncher
	return Plugin_Handled;
}

/* Command_RemoveLimit()
 *
 * Remove a limit from the plugin by ID
 * -------------------------------------------------------------------------- */
public Action:Command_RemoveLimit(_client, _args)
{
	if (_args != 1) {
		ReplyToCommand(_client, USAGE_RemoveLimit, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	//
	if (g_PreparedQueryLimitRemoveByKey == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryLimitRemoveByKey = SQL_PrepareQuery(g_DatabaseConnection, DBQ_LIMITS_REMOVE_BY_KEY, error, sizeof(error));
		if (g_PreparedQueryLimitRemoveByKey == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
			return Plugin_Handled;
		}
	}
	decl String:buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	new key;
	new charsConsumed = StringToIntEx(buffer, key);
	if (charsConsumed == 0) {
		ReplyToCommand(_client, USAGE_RemoveLimit, PREFIX_COMMAND);
	} else {
		SQL_BindParamInt(g_PreparedQueryLimitRemoveByKey, 0, key, false);
		// execute
		if (!SQL_Execute(g_PreparedQueryLimitRemoveByKey)) {
			ReplyToCommand(_client, USAGE_RemoveLimit, PREFIX_COMMAND);
		} else {
			ReplyToCommand(_client, "%s Limit removed. type 'weaplimit_printlimits' to view current limits", PREFIX_COMMAND);
		}
	}
	return Plugin_Handled;
}

/* Command_RemoveWhitelist()
 *
 * Remove a whitelist entry from the plugin by ID
 * -------------------------------------------------------------------------- */
public Action:Command_RemoveWhitelist(_client, _args)
{
	if (_args != 1) {
		ReplyToCommand(_client, USAGE_RemoveWhitelist, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	if (g_PreparedQueryWhitelistRemoveByKey == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryWhitelistRemoveByKey = SQL_PrepareQuery(g_DatabaseConnection, DBQ_WHITELIST_REMOVE_BY_KEY, error, sizeof(error));
		if (g_PreparedQueryWhitelistRemoveByKey == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
			return Plugin_Handled;
		}
	}
	decl String:buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	new key;
	new charsConsumed = StringToIntEx(buffer, key);
	if (charsConsumed == 0) {
		ReplyToCommand(_client, USAGE_RemoveWhitelist, PREFIX_COMMAND);
	} else {
		SQL_BindParamInt(g_PreparedQueryWhitelistRemoveByKey, 0, key, false);
		// execute
		if (!SQL_Execute(g_PreparedQueryWhitelistRemoveByKey)) {
			ReplyToCommand(_client, USAGE_RemoveWhitelist, PREFIX_COMMAND);
		} else {
			ReplyToCommand(_client, "%s Whitelist entry removed. type 'weaplimit_printwhitelist' to view current whitelist", PREFIX_COMMAND);
		}
	}
	return Plugin_Handled;
}

/* Command_ClearLimits()
 *
 * Remove all limits from the plugin
 * -------------------------------------------------------------------------- */
public Action:Command_ClearLimits(_client, _args)
{
	if (g_PreparedQueryLimitRemoveAll == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryLimitRemoveAll = SQL_PrepareQuery(g_DatabaseConnection, DBQ_LIMITS_REMOVE_ALL, error, sizeof(error));
		if (g_PreparedQueryLimitRemoveAll == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
			return Plugin_Handled;
		}
	}
	// execute
	if (!SQL_Execute(g_PreparedQueryLimitRemoveAll)) {
		ReplyToCommand(_client, USAGE_ClearLimits, PREFIX_COMMAND);
	} else {
		ReplyToCommand(_client, "%s All limits removed", PREFIX_COMMAND);
	}
	return Plugin_Handled;
}

/* Command_ClearWhitelist()
 *
 * Remove all whitelist entries from the plugin
 * -------------------------------------------------------------------------- */
public Action:Command_ClearWhitelist(_client, _args)
{
	if (g_PreparedQueryWhitelistRemoveAll == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryWhitelistRemoveAll = SQL_PrepareQuery(g_DatabaseConnection, DBQ_WHITELIST_REMOVE_ALL, error, sizeof(error));
		if (g_PreparedQueryWhitelistRemoveAll == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
			return Plugin_Handled;
		}
	}
	// execute
	if (!SQL_Execute(g_PreparedQueryWhitelistRemoveAll)) {
		ReplyToCommand(_client, USAGE_ClearWhitelist, PREFIX_COMMAND);
	} else {
		ReplyToCommand(_client, "%s All whitelist entries removed", PREFIX_COMMAND);
	}
	return Plugin_Handled;
}

/* Command_Enabled()
 *
 * Enable / Disable the plugin
 * -------------------------------------------------------------------------- */
public Action:Command_Enabled(_client, _args)
{
	if (_args != 1) {
		ReplyToCommand(_client, USAGE_Enabled, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	decl String:buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	new enabled;
	new charsConsumed = StringToIntEx(buffer, enabled);
	if (charsConsumed == 0) {
		ReplyToCommand(_client, USAGE_Enabled, PREFIX_COMMAND);
	} else {
		g_PluginEnabled = !(enabled <= 0);
		if (g_PluginEnabled) {
			ReplyToCommand(_client, "%s Plugin Enabled", PREFIX_COMMAND);
		} else {
			ReplyToCommand(_client, "%s Plugin Disabled", PREFIX_COMMAND);
		}
	}
	return Plugin_Handled;
}

/* Command_ChatEnabled()
 *
 * Enable / Disable chat messages to the players
 * -------------------------------------------------------------------------- */
public Action:Command_ChatEnabled(_client, _args)
{
	if (_args != 1) {
		ReplyToCommand(_client, USAGE_ChatEnabled, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	decl String:buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	new enabled;
	new charsConsumed = StringToIntEx(buffer, enabled);
	if (charsConsumed == 0) {
		ReplyToCommand(_client, USAGE_ChatEnabled, PREFIX_COMMAND);
	} else {
		g_OutputChatEnabled = !(enabled <= 0);
		if (g_OutputChatEnabled) {
			ReplyToCommand(_client, "%s Chat Messages Enabled", PREFIX_COMMAND);
		} else {
			ReplyToCommand(_client, "%s Chat Messages Disabled", PREFIX_COMMAND);
		}
	}
	return Plugin_Handled;
}

/* Command_HUDEnabled
 *
 * Enable / Disable HUD messages to the players
 * -------------------------------------------------------------------------- */
public Action:Command_HUDEnabled(_client, _args)
{
	if (_args != 1) {
		ReplyToCommand(_client, USAGE_HUDEnabled, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	decl String:buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	new enabled;
	new charsConsumed = StringToIntEx(buffer, enabled);
	if (charsConsumed == 0) {
		ReplyToCommand(_client, USAGE_HUDEnabled, PREFIX_COMMAND);
	} else {
		g_OutputHUDEnabled = !(enabled <= 0);
		if (g_OutputHUDEnabled) {
			ReplyToCommand(_client, "%s HUD Messages Enabled", PREFIX_COMMAND);
		} else {
			ReplyToCommand(_client, "%s HUD Messages Disabled", PREFIX_COMMAND);
		}
	}
	return Plugin_Handled;
}

/* Command_LoadConfig()
 *
 * Load a configuration file
 * -------------------------------------------------------------------------- */
public Action:Command_LoadConfig(_client, _args)
{
	if (_args != 1) {
		ReplyToCommand(_client, USAGE_LoadConfig, PREFIX_COMMAND);
		return Plugin_Handled;
	}
	decl String:configurationFileString[255];
	GetCmdArg(1, configurationFileString, sizeof(configurationFileString));
	if (strlen(configurationFileString) == 0) {
		ReplyToCommand(_client, USAGE_LoadConfig, PREFIX_COMMAND);
	} else {
		Command_ClearLimits(_client, -1);
		Command_ClearWhitelist(_client, -1);
		new bool:success = ParseConfigurationFile(configurationFileString);
		if (!success) {
			ReplyToCommand(_client, "%s ERROR: Configuration file invalid.", PREFIX_COMMAND);
		} else {
			ReplyToCommand(_client, "%s Plugin Enabled = %i", PREFIX_COMMAND, g_PluginEnabled);
			ReplyToCommand(_client, "%s Chat Enabled = %i", PREFIX_COMMAND, g_OutputChatEnabled);
			ReplyToCommand(_client, "%s HUD Enabled = %i\n", PREFIX_COMMAND, g_OutputHUDEnabled);
			Command_PrintWhitelist(_client,-1);
			Command_PrintLimits(_client,-1);
		}
	}
	return Plugin_Handled;
}

/***
 *    $$$$$$$\             $$\               $$\                                                                
 *    $$  __$$\            $$ |              $$ |                                                               
 *    $$ |  $$ | $$$$$$\ $$$$$$\    $$$$$$\  $$$$$$$\   $$$$$$\   $$$$$$$\  $$$$$$\                             
 *    $$ |  $$ | \____$$\\_$$  _|   \____$$\ $$  __$$\  \____$$\ $$  _____|$$  __$$\                            
 *    $$ |  $$ | $$$$$$$ | $$ |     $$$$$$$ |$$ |  $$ | $$$$$$$ |\$$$$$$\  $$$$$$$$ |                           
 *    $$ |  $$ |$$  __$$ | $$ |$$\ $$  __$$ |$$ |  $$ |$$  __$$ | \____$$\ $$   ____|                           
 *    $$$$$$$  |\$$$$$$$ | \$$$$  |\$$$$$$$ |$$$$$$$  |\$$$$$$$ |$$$$$$$  |\$$$$$$$\                            
 *    \_______/  \_______|  \____/  \_______|\_______/  \_______|\_______/  \_______| 
 */

/* InitialiseDataBase()
 *
 * Initialise the database, including clearing existing tables
 * -------------------------------------------------------------------------- */
InitialiseDataBase()
{
	// initialise database
	decl String:error[STRLEN_DBError];
	g_DatabaseConnection = SQLite_UseDatabase("weapon_limiter", error, sizeof(error));
	if (g_DatabaseConnection == INVALID_HANDLE) {
		SetFailState("Could not initialise DataBase");
	} else {
		// initialise slot table
		if (SQL_FastQuery(g_DatabaseConnection, DBQ_SLOT_DROPTABLE)) {
			if (!SQL_FastQuery(g_DatabaseConnection, DBQ_SLOT_CREATETABLE)) {
				SetFailState("Could not create slots table");
			}
		} else {
			SetFailState("Could not clear existing slots table");
		}
		// initialise limits table
		if (SQL_FastQuery(g_DatabaseConnection, DBQ_LIMITS_DROPTABLE)) {
			if (!SQL_FastQuery(g_DatabaseConnection, DBQ_LIMITS_CREATETABLE)) {
				SetFailState("Could not create limits table");
			}
		} else {
			SetFailState("Could not clear existing limits table");
		}
		// initialise whitelist table
		if (SQL_FastQuery(g_DatabaseConnection, DBQ_WHITELIST_DROPTABLE)) {
			if (!SQL_FastQuery(g_DatabaseConnection, DBQ_WHITELIST_CREATETABLE)) {
				SetFailState("Could not create whitelist table");
			}
		} else {
			SetFailState("Could not clear existing whitelist table");
		}
	}  
}

/* Query_RemovePlayerDetails()
 *
 * Remove all player details from the slot table
 * -------------------------------------------------------------------------- */
bool:Query_RemovePlayerDetails(const String:_playerAuthID[])
{
	if (g_PreparedQuerySlotDeletePlayer == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQuerySlotDeletePlayer = SQL_PrepareQuery(g_DatabaseConnection, DBQ_SLOT_DELETE_PLAYER, error, sizeof(error));
		if (g_PreparedQuerySlotDeletePlayer == INVALID_HANDLE) {
			PrintToServer("%s Query_RemovePlayerDetails Creation failed: %s", PREFIX_COMMAND,error);
			return false;
		}
	}
	SQL_BindParamString(g_PreparedQuerySlotDeletePlayer, 0, _playerAuthID, false);
	if (!SQL_Execute(g_PreparedQuerySlotDeletePlayer)) {
		PrintToServer("%s Query_RemovePlayerDetails Execute failed.", PREFIX_COMMAND);
		return false;
	} else {
		return true;
	}
}

/* Query_RemoveSlotDetails()
 *
 * Remove player's weapon slot details from the slot table
 * -------------------------------------------------------------------------- */
bool:Query_RemoveSlotDetails(const String:_playerAuthID[], _itemSlot)
{
	if (g_PreparedQuerySlotDeleteDetails == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQuerySlotDeleteDetails = SQL_PrepareQuery(g_DatabaseConnection, DBQ_SLOT_DELETE_ROW, error, sizeof(error));
		if (g_PreparedQuerySlotDeleteDetails == INVALID_HANDLE) {
			PrintToServer("%s Query_RemoveSlotDetails Creation failed: %s", PREFIX_COMMAND, error);
			return false;
		}
	}
	SQL_BindParamString(g_PreparedQuerySlotDeleteDetails, 0, _playerAuthID, false);
	SQL_BindParamInt(g_PreparedQuerySlotDeleteDetails, 1, _itemSlot, false);
	if (!SQL_Execute(g_PreparedQuerySlotDeleteDetails)) {
		PrintToServer("%s Query_RemoveSlotDetails Execute failed.", PREFIX_COMMAND);
		return false;
	} else {
		return true;
	}
}

/* Query_RetrieveSlotDetails()
 *
 * Retrieve the details for a player's weapon slot from the slot table
 * -------------------------------------------------------------------------- */
bool:Query_RetrieveSlotDetails(const String:_playerAuthID[], _itemSlot, &_itemDefinition, &_equipTimestamp, String:_itemClass[], _itemClassLength)
{
	if (g_PreparedQuerySlotSelectDetails == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQuerySlotSelectDetails = SQL_PrepareQuery(g_DatabaseConnection, DBQ_SLOT_RETRIEVE_DETAILS, error, sizeof(error));
		if (g_PreparedQuerySlotSelectDetails == INVALID_HANDLE) {
			PrintToServer("%s Query_RetrieveSlotDetails Creation failed: %s", PREFIX_COMMAND,error);
			return false;
		}
	}
	SQL_BindParamString(g_PreparedQuerySlotSelectDetails, 0, _playerAuthID, false);
	SQL_BindParamInt(g_PreparedQuerySlotSelectDetails, 1, _itemSlot, false);
	if (!SQL_Execute(g_PreparedQuerySlotSelectDetails)) {
		PrintToServer("%s Query_RetrieveSlotDetails Execute failed.", PREFIX_COMMAND);
		return false;
	}
	if (SQL_FetchRow(g_PreparedQuerySlotSelectDetails)) {
		decl String:fetchedItemClass[STRLEN_ItemClass];
		SQL_FetchString(g_PreparedQuerySlotSelectDetails, 5, fetchedItemClass, sizeof(fetchedItemClass));
		strcopy(_itemClass, _itemClassLength, fetchedItemClass);
		_itemDefinition = SQL_FetchInt(g_PreparedQuerySlotSelectDetails, 4);
		_equipTimestamp = SQL_FetchInt(g_PreparedQuerySlotSelectDetails, 6);
		return true;
	} else {
		return false;
	}
}

/* Query_InsertSlotDetails()
 *
 * Insert the details for a player's weapon slot into to the slot table
 * -------------------------------------------------------------------------- */
bool:Query_InsertSlotDetails(const String:_playerAuthID[], _playerTeam, _playerClass, _itemSlot, _itemDefinition, const String:_itemClass[], _equipTimestamp)
{
	if (g_PreparedQuerySlotInsert == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQuerySlotInsert = SQL_PrepareQuery(g_DatabaseConnection, DBQ_SLOT_INSERT, error, sizeof(error));
		if (g_PreparedQuerySlotInsert == INVALID_HANDLE) {
			PrintToServer("%s Query_InsertSlotDetails Creation failed: %s", PREFIX_COMMAND,error);
			return false;
		}
	}
	SQL_BindParamString(g_PreparedQuerySlotInsert, 0, _playerAuthID, false);
	SQL_BindParamInt(g_PreparedQuerySlotInsert, 1, _playerTeam, false);
	SQL_BindParamInt(g_PreparedQuerySlotInsert, 2, _playerClass, false);
	SQL_BindParamInt(g_PreparedQuerySlotInsert, 3, _itemSlot, false);
	SQL_BindParamInt(g_PreparedQuerySlotInsert, 4, _itemDefinition, false);
	SQL_BindParamString(g_PreparedQuerySlotInsert, 5, _itemClass, false);
	SQL_BindParamInt(g_PreparedQuerySlotInsert, 6, _equipTimestamp, false);
	// execute
	if (!SQL_Execute(g_PreparedQuerySlotInsert)) {
		PrintToServer("%s Query_InsertSlotDetails Execute failed.", PREFIX_COMMAND);
		return false;
	} else {
		return true;
	}
}

/* Query_InsertLimitsRecord()
 *
 * Insert a new limit into to the limits table
 * -------------------------------------------------------------------------- */
bool:Query_InsertLimitsRecord(_totalLimit, _redLimit, _blueLimit, _playerClass, _itemSlot, _itemDefinition, const String:_itemClass[])
{
	if (g_PreparedQueryLimitsInsert == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryLimitsInsert = SQL_PrepareQuery(g_DatabaseConnection, DBQ_LIMITS_INSERT, error, sizeof(error));
		if (g_PreparedQueryLimitsInsert == INVALID_HANDLE) {
			PrintToServer("%s Query_InsertLimitsRecord Creation failed: %s", PREFIX_COMMAND,error);
			return false;
		}
	}
	SQL_BindParamInt(g_PreparedQueryLimitsInsert, 0, _totalLimit, false);
	SQL_BindParamInt(g_PreparedQueryLimitsInsert, 1, _redLimit, false);
	SQL_BindParamInt(g_PreparedQueryLimitsInsert, 2, _blueLimit, false);
	SQL_BindParamInt(g_PreparedQueryLimitsInsert, 3, _playerClass, false);
	SQL_BindParamInt(g_PreparedQueryLimitsInsert, 4, _itemSlot, false);
	SQL_BindParamInt(g_PreparedQueryLimitsInsert, 5, _itemDefinition, false);
	SQL_BindParamString(g_PreparedQueryLimitsInsert, 6, _itemClass, false);
	// execute
	if (!SQL_Execute(g_PreparedQueryLimitsInsert)) {
		PrintToServer("%s Query_InsertLimitsRecord Execute failed.", PREFIX_COMMAND);
		return false;
	} else {
		return true;
	}
}

/* Query_InsertWhitelistRecord()
 *
 * Insert a new whitelist entry into to the whitelist table
 * -------------------------------------------------------------------------- */
bool:Query_InsertWhitelistRecord(const String:_playerAuthID[], _itemSlot, _itemDefinition, const String:_itemClass[])
{
	if (g_PreparedQueryWhitelistInsert == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryWhitelistInsert = SQL_PrepareQuery(g_DatabaseConnection, DBQ_WHITELIST_INSERT, error, sizeof(error));
		if (g_PreparedQueryWhitelistInsert == INVALID_HANDLE) {
			PrintToServer("%s Query_InsertWhitelistRecord Creation failed: %s", PREFIX_COMMAND,error);
			return false;
		}
	}
	SQL_BindParamString(g_PreparedQueryWhitelistInsert, 0, _playerAuthID, false);
	SQL_BindParamInt(g_PreparedQueryWhitelistInsert, 1, _itemSlot, false);
	SQL_BindParamInt(g_PreparedQueryWhitelistInsert, 2, _itemDefinition, false);
	SQL_BindParamString(g_PreparedQueryWhitelistInsert, 3, _itemClass, false);
	// execute
	if (!SQL_Execute(g_PreparedQueryWhitelistInsert)) {
		PrintToServer("%s Query_InsertWhitelistRecord Execute failed.", PREFIX_COMMAND);
		return false;
	} else {
		return true;
	}
}

/* Query_PlayerHasWhitelistEntry()
 *
 * Checks whether a player has been added to the whitelist table
 * -------------------------------------------------------------------------- */
bool:Query_PlayerHasWhitelistEntry(const String:_playerAuthID[], _itemSlot, _itemDefinition, const String:_itemClass[])
{
	if (g_PreparedQueryWhitelistForPlayer == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryWhitelistForPlayer = SQL_PrepareQuery(g_DatabaseConnection, DBQ_WHITELIST_RETRIEVE, error, sizeof(error));
		if (g_PreparedQueryWhitelistForPlayer == INVALID_HANDLE) {
			PrintToServer("%s Query_InsertWhitelistRecord Creation failed: %s", PREFIX_COMMAND,error);
			return false;
		}
	}
	SQL_BindParamString(g_PreparedQueryWhitelistForPlayer, 0, _playerAuthID, false);
	SQL_BindParamInt(g_PreparedQueryWhitelistForPlayer, 1, _itemSlot, false);
	SQL_BindParamInt(g_PreparedQueryWhitelistForPlayer, 2, _itemDefinition, false);
	SQL_BindParamString(g_PreparedQueryWhitelistForPlayer, 3, _itemClass, false);
	// execute
	if (!SQL_Execute(g_PreparedQueryWhitelistForPlayer)) {
		PrintToServer("%s Query_InsertWhitelistRecord Execute failed.", PREFIX_COMMAND);
		return false;
	} else {
		if (SQL_GetRowCount(g_PreparedQueryWhitelistForPlayer) > 0) {
			PrintToServer("%s Whitelist found for %s", PREFIX_COMMAND, _playerAuthID);
			return true;
		} else {
			return false;
		}
	}
}

/***
 *     $$$$$$\                       $$$$$$\  $$\                                         $$\     $$\                     
 *    $$  __$$\                     $$  __$$\ \__|                                        $$ |    \__|                    
 *    $$ /  \__| $$$$$$\  $$$$$$$\  $$ /  \__|$$\  $$$$$$\  $$\   $$\  $$$$$$\  $$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\  
 *    $$ |      $$  __$$\ $$  __$$\ $$$$\     $$ |$$  __$$\ $$ |  $$ |$$  __$$\ \____$$\\_$$  _|  $$ |$$  __$$\ $$  __$$\ 
 *    $$ |      $$ /  $$ |$$ |  $$ |$$  _|    $$ |$$ /  $$ |$$ |  $$ |$$ |  \__|$$$$$$$ | $$ |    $$ |$$ /  $$ |$$ |  $$ |
 *    $$ |  $$\ $$ |  $$ |$$ |  $$ |$$ |      $$ |$$ |  $$ |$$ |  $$ |$$ |     $$  __$$ | $$ |$$\ $$ |$$ |  $$ |$$ |  $$ |
 *    \$$$$$$  |\$$$$$$  |$$ |  $$ |$$ |      $$ |\$$$$$$$ |\$$$$$$  |$$ |     \$$$$$$$ | \$$$$  |$$ |\$$$$$$  |$$ |  $$ |
 *     \______/  \______/ \__|  \__|\__|      \__| \____$$ | \______/ \__|      \_______|  \____/ \__| \______/ \__|  \__|
 *                                                $$\   $$ |                                                              
 *                                                \$$$$$$  |                                                              
 *                                                 \______/
 */

/* ParseConfigurationLimitsVault()
 *
 * Parse the limits section of the configuration file
 * -------------------------------------------------------------------------- */
ParseConfigurationLimitsVault(Handle:_vaultLimits)
{
	if (KvGotoFirstSubKey(_vaultLimits)) {
		decl String:playerClassString[STRLEN_PlayerClass];
		decl String:itemSlotString[STRLEN_ItemSlot];
		decl String:itemClass[STRLEN_ItemClass];
		new itemDefinition;
		new limitBlueTeam;
		new limitRedTeam;
		new limitPerTeam;
		new limitTotal;
		new playerClass;
		new itemSlot;
		new bool:valid;
		do {
			valid = false;
			// check if the item class or index is defined
			KvGetString(_vaultLimits, KV_KeyItemClass, itemClass, sizeof(itemClass), "");
			if (strlen(itemClass) > 0) valid = true;
			itemDefinition = KvGetNum(_vaultLimits, KV_KeyItemDefinition, UNDEFINED_NUMBER);
			if (itemDefinition >= 0) valid = true;
			// set player class
			KvGetString(_vaultLimits, KV_KeyPlayerClass, playerClassString, sizeof(playerClassString));
			playerClass = GetPlayerClassTypeFromString(playerClassString);
			KvGetString(_vaultLimits, KV_KeyItemSlot, itemSlotString, sizeof(itemSlotString));
			itemSlot = GetItemSlotTypeFromString(itemSlotString);
			if (itemSlot >= 0) valid = true;
			// get limtis
			limitBlueTeam = KvGetNum(_vaultLimits, KV_KeyLimitBlue, UNDEFINED_NUMBER);
			limitRedTeam = KvGetNum(_vaultLimits, KV_KeyLimitRed, UNDEFINED_NUMBER);
			limitPerTeam = KvGetNum(_vaultLimits, KV_KeyLimitTeam, UNDEFINED_NUMBER);
			limitTotal = KvGetNum(_vaultLimits, KV_KeyLimitTotal, UNDEFINED_NUMBER);
			// normalize limits
			if (limitBlueTeam < 0) limitBlueTeam = limitPerTeam;
			if (limitRedTeam < 0) limitRedTeam = limitPerTeam;
			//
			if (limitTotal < 0 && limitBlueTeam < 0 && limitRedTeam < 0) valid = false;
			//
			if (valid) {
				Query_InsertLimitsRecord(limitTotal, limitRedTeam, limitBlueTeam, playerClass, itemSlot, itemDefinition, itemClass);
			}
			// check if more subkeys exist
		} while (KvGotoNextKey(_vaultLimits));
	}
}

/* ParseConfigurationWhitelistVault()
 *
 * Parse the whitelist section of the configuration file
 * -------------------------------------------------------------------------- */
ParseConfigurationWhitelistVault(Handle:_whitelistLimits)
{
	if (KvGotoFirstSubKey(_whitelistLimits)) {
		decl String:playerAuthString[STRLEN_AuthString];
		decl String:itemSlotString[STRLEN_ItemSlot];
		decl String:itemClass[STRLEN_ItemClass];
		new itemDefinition;
		new itemSlot;
		new bool:EntryValid;
		do {
			EntryValid = false;
			// check if the item class or index or slot is defined
			KvGetString(_whitelistLimits, KV_KeyItemClass, itemClass, sizeof(itemClass), "");
			if (strlen(itemClass) > 0) EntryValid = true;
			itemDefinition = KvGetNum(_whitelistLimits, KV_KeyItemDefinition, UNDEFINED_NUMBER);
			if (itemDefinition >= 0) EntryValid = true;
			KvGetString(_whitelistLimits, KV_KeyItemSlot, itemSlotString, sizeof(itemSlotString));
			itemSlot = GetItemSlotTypeFromString(itemSlotString);
			if (itemSlot >= 0) EntryValid = true;
			// get player class
			KvGetString(_whitelistLimits, KV_KeyPlayerID, playerAuthString, sizeof(playerAuthString));
			EntryValid = EntryValid & (strlen(playerAuthString) > 0);
			//
			if (EntryValid) {
				Query_InsertWhitelistRecord(playerAuthString, itemSlot, itemDefinition, itemClass);
			}
			// check if more subkeys exist
		} while (KvGotoNextKey(_whitelistLimits));
	}
}

/* ParseConfigurationFile()
 *
 * Parse the specified configuration file
 * -------------------------------------------------------------------------- */
bool:ParseConfigurationFile(const String:_configurationFileString[])
{
	decl String:configurationFullPath[PLATFORM_MAX_PATH];
	Format(configurationFullPath, sizeof(configurationFullPath), "%s%s", KV_ConfigurationDirectory, _configurationFileString);
	BuildPath(Path_SM, configurationFullPath, sizeof(configurationFullPath), configurationFullPath);
	
	if(!FileExists(configurationFullPath)) {
		PrintToServer("%s Configuration file \"%s\" not found.", PREFIX_COMMAND, _configurationFileString);
		return true;
	}
	//
	new Handle:configurationVault = CreateKeyValues("");
	if (configurationVault == INVALID_HANDLE) {
		return false;
	}
	//
	if (!FileToKeyValues(configurationVault, configurationFullPath)) {
		return false;
	}
	//
	// find out whether the plugin should be enabled
	new enabled = KvGetNum(configurationVault, KV_KeyEnabled, 1);
	g_PluginEnabled = !(enabled <= 0);
	// find out whether chat messages should be enabled
	enabled = KvGetNum(configurationVault, KV_KeyChatEnabled, 0);
	g_OutputChatEnabled = !(enabled <= 0);
	// find out whether HUD messages should be enabled
	enabled = KvGetNum(configurationVault, KV_KeyHUDEnabled, 1);
	g_OutputHUDEnabled = !(enabled <= 0);
	//
	// parse limits into the database
	if (KvJumpToKey(configurationVault, KV_KeyLimits, false)) {
		ParseConfigurationLimitsVault(configurationVault);
		KvRewind(configurationVault);
	}
	// parse whitelist into the database
	if (KvJumpToKey(configurationVault, KV_KeyWhitelist, false)) {
		ParseConfigurationWhitelistVault(configurationVault);
		KvRewind(configurationVault);
	}
	CloseHandle(configurationVault);
	return true;
}

/* GetPlayerClassTypeFromString()
 *
 * Convert a string to the TFClassType enum
 * -------------------------------------------------------------------------- */
GetPlayerClassTypeFromString(const String:_playerClassString[])
{
	if (strlen(_playerClassString) > 0) {
		for (new i = 0; i <= _:TFClass_Engineer; i++) {
			if (StrContains(_playerClassString, g_PlayerClassStrings[i], false) >= 0) return i;
		}
	}
	return UNDEFINED_NUMBER;
}

/* GetItemSlotTypeFromString()
 *
 * Convert a string to the TFWeaponSlot enum
 * -------------------------------------------------------------------------- */
GetItemSlotTypeFromString(const String:_itemSlotString[])
{
	if (strlen(_itemSlotString) > 0) {
		new number;
		new charsConsumed = StringToIntEx(_itemSlotString, number);
		if (charsConsumed == 0 || number < UNDEFINED_NUMBER || number > _:TFWeaponSlot_Item2) {
			for (new i = 0; i <= _:TFWeaponSlot_Item2; i++) {
				if (StrContains(_itemSlotString, g_ItemSlotStrings[i], false) >= 0) return i;
			}
		} else {
			return number;
		}
	}
	return UNDEFINED_NUMBER;
}

/***
 *    $$$$$$$$\                             $$\                                                                 
 *    $$  _____|                            $$ |                                                                
 *    $$ |  $$\    $$\  $$$$$$\  $$$$$$$\ $$$$$$\    $$$$$$$\                                                   
 *    $$$$$\\$$\  $$  |$$  __$$\ $$  __$$\\_$$  _|  $$  _____|                                                  
 *    $$  __|\$$\$$  / $$$$$$$$ |$$ |  $$ | $$ |    \$$$$$$\                                                    
 *    $$ |    \$$$  /  $$   ____|$$ |  $$ | $$ |$$\  \____$$\                                                   
 *    $$$$$$$$\\$  /   \$$$$$$$\ $$ |  $$ | \$$$$  |$$$$$$$  |                                                  
 *    \________|\_/     \_______|\__|  \__|  \____/ \_______/ 
 */

/* Event_PlayerDisconnected()
 *
 * Update weapons upon player disconnect
 * -------------------------------------------------------------------------- */
public Action:Event_PlayerDisconnected(Handle:_event, const String:_name[], bool:_dontBroadast)
{
	new userid = GetEventInt(_event, "userid");
	new client = GetClientOfUserId(userid);
	UpdateClientWeapons(client, true);
	return Plugin_Continue;
}

/* Event_PlayerChangedTeams()
 *
 * Update weapons upon player team change (incl spectator)
 * -------------------------------------------------------------------------- */
public Action:Event_PlayerChangedTeams(Handle:_event, const String:_name[], bool:_dontBroadast)
{
	new userid = GetEventInt(_event, "userid");
	new client = GetClientOfUserId(userid);
	UpdateClientWeapons(client, true);
	return Plugin_Continue;
}

/* Event_PostInventoryApplication()
 *
 * Update weapons upon player using the weapon locker
 * -------------------------------------------------------------------------- */
public Action:Event_PostInventoryApplication(Handle:_event, const String:_name[], bool:_dontBroadast)
{
	new userid = GetEventInt(_event, "userid");
	new client = GetClientOfUserId(userid);
	UpdateClientWeapons(client, false);
	return Plugin_Continue;
}

/***
 *    $$\       $$\               $$\   $$\                                                                                            
 *    $$ |      \__|              \__|  $$ |                                                                                           
 *    $$ |      $$\ $$$$$$\$$$$\  $$\ $$$$$$\    $$$$$$\   $$$$$$\                                                                     
 *    $$ |      $$ |$$  _$$  _$$\ $$ |\_$$  _|  $$  __$$\ $$  __$$\                                                                    
 *    $$ |      $$ |$$ / $$ / $$ |$$ |  $$ |    $$$$$$$$ |$$ |  \__|                                                                   
 *    $$ |      $$ |$$ | $$ | $$ |$$ |  $$ |$$\ $$   ____|$$ |                                                                         
 *    $$$$$$$$\ $$ |$$ | $$ | $$ |$$ |  \$$$$  |\$$$$$$$\ $$ |                                                                         
 *    \________|\__|\__| \__| \__|\__|   \____/  \_______|\__|
 */

/* UpdateClientWeapons()
 *
 * Update client weapons, including recording slot details and applying
 * limits where applicable.
 * -------------------------------------------------------------------------- */
UpdateClientWeapons(_client, bool:_disconnected)
{
	if (!IsValidClient(_client)) {
		return;
	}
	decl String:playerAuthString[STRLEN_AuthString];
	GetClientAuthString(_client, playerAuthString, sizeof(playerAuthString));
	// check if it's a bot - if so give it a unique _name
	if (strcmp(playerAuthString, "bot", false) == 0) {
		Format(playerAuthString, sizeof(playerAuthString), "BOT[%i]", _client);
	}
	decl String:playerName[STRLEN_PlayerName];
	GetClientName(_client, playerName, sizeof(playerName));
	if (_disconnected) {
		Query_RemovePlayerDetails(playerAuthString);
		//PrintToServer("%s Removed weapon information for '%s'", PREFIX_COMMAND, playerAuthString);
	} else {
		// player information
		new playerTeam = GetClientTeam(_client);
		new playerClass = GetEntProp(_client, Prop_Send, "m_iClass");
		decl String:itemClass[STRLEN_ItemClass];
		new itemDefinition;
		decl String:itemName[STRLEN_ItemName];
		new timestamp;
		// existing information
		new existingItemDefinition;
		decl String:existingItemClass[STRLEN_ItemClass];
		new existingTimestamp;
		new slotAlreadyExists;
		//
		decl String:hudMessage[512];
		new bool:hudMessageSet = false;
		//
		for (new slot = 0; slot <= TFWeaponSlot_Item2; slot++)
		{
			slotAlreadyExists = Query_RetrieveSlotDetails(playerAuthString, slot, existingItemDefinition, existingTimestamp, existingItemClass, sizeof(existingItemClass));
			//
			new weapon = GetPlayerWeaponSlot(_client, slot);
			if (weapon >= 0) {
				//
				timestamp = GetSysTickCount();
				GetEntityClassname(weapon, itemClass, sizeof(itemClass));
				itemDefinition = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
				if (slotAlreadyExists && itemDefinition == existingItemDefinition) {
					timestamp = existingTimestamp;
				}
				if (!g_PluginEnabled || (Query_PlayerHasWhitelistEntry(playerAuthString, slot, itemDefinition, itemClass) || WeaponCanEquip(itemClass, itemDefinition, slot, playerAuthString, playerClass, playerTeam))) {
					Query_InsertSlotDetails(playerAuthString, playerTeam, playerClass, slot, itemDefinition, itemClass, timestamp);
				} else {
					GetItemName(itemDefinition, itemName, sizeof(itemName));
					if (g_OutputChatEnabled) {
						PrintToChat(_client, "%s %s limit reached.", PREFIX_CHAT, itemName);
					}
					PrintToServer("%s Removed %s (%i) from %s.", PREFIX_COMMAND, itemName, itemDefinition, playerName);
					TF2_RemoveWeaponSlot(_client, slot);
					Query_RemoveSlotDetails(playerAuthString, slot);
					if (g_OutputHUDEnabled) {
						if (hudMessageSet) {
							Format(hudMessage,sizeof(hudMessage), "%s\nRemoved %s (limit reached).", hudMessage, itemName);
						} else {
							Format(hudMessage,sizeof(hudMessage), "%s\nRemoved %s (limit reached).", PREFIX_HUD, itemName);
						}
						hudMessageSet = true;
					}
				}
			} else {
				Query_RemoveSlotDetails(playerAuthString, slot);	
			}
		}
		if (hudMessageSet) {
			ShowHudMessage(_client, hudMessage);
		}
	}
}

/* WeaponCanEquip()
 *
 * Determines whether a weapon can be equipped based on slots and limits
 * -------------------------------------------------------------------------- */
bool:WeaponCanEquip(const String:_currentItemClass[], _currentItemDefinition, _currentItemSlot, const String:_currentPlayerID[], _currentPlayerClass, _currentPlayerTeam)
{
	if (g_PreparedQueryLimitsForItem == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQueryLimitsForItem = SQL_PrepareQuery(g_DatabaseConnection, DBQ_LIMITS_SELECT, error, sizeof(error));
		if (g_PreparedQueryLimitsForItem == INVALID_HANDLE) {
			PrintToServer("%s WeaponCanEquip Creation failed: %s", PREFIX_COMMAND,error);
			return true;
		}
	}
	SQL_BindParamInt(g_PreparedQueryLimitsForItem, 0, _currentItemSlot, false);
	SQL_BindParamInt(g_PreparedQueryLimitsForItem, 1, _currentItemDefinition, false);
	SQL_BindParamString(g_PreparedQueryLimitsForItem, 2, _currentItemClass, false);
	// execute
	if (!SQL_Execute(g_PreparedQueryLimitsForItem)) {
		PrintToServer("%s WeaponCanEquip Execute failed.", PREFIX_COMMAND);
		return true;
	}
	// check if there are any applicable limits
	if (SQL_GetRowCount(g_PreparedQueryLimitsForItem) > 0) {
		// limit field vars
		decl String:limitItemClass[STRLEN_ItemClass];
		new limitTotal, limitRedTeam, limitBlueTeam, limitCurrentTeam, limitPlayerClass, limitItemSlot, limitItemDefinition;
		//
		new countTeam, countTotal;
		new bool:querySuceeded;
		// loop through the rows
		while (SQL_FetchRow(g_PreparedQueryLimitsForItem))
		{
			limitTotal = SQL_FetchInt(g_PreparedQueryLimitsForItem, 1);
			limitRedTeam = SQL_FetchInt(g_PreparedQueryLimitsForItem, 2);
			limitBlueTeam = SQL_FetchInt(g_PreparedQueryLimitsForItem, 3);
			limitPlayerClass = SQL_FetchInt(g_PreparedQueryLimitsForItem, 4);
			limitItemSlot = SQL_FetchInt(g_PreparedQueryLimitsForItem, 5);
			limitItemDefinition = SQL_FetchInt(g_PreparedQueryLimitsForItem, 6);
			SQL_FetchString(g_PreparedQueryLimitsForItem, 7, limitItemClass, sizeof(limitItemClass));
			// get the current team's limit
			if (_currentPlayerTeam == _:TFTeam_Red) {
				limitCurrentTeam = limitRedTeam;
			} else if (_currentPlayerTeam == _:TFTeam_Blue) {
				limitCurrentTeam = limitBlueTeam;
			} else {
				continue;
			}
			// check if team and/or total limits exist
			if (limitCurrentTeam < 0 && limitTotal < 0) {
				continue;
			}
			// check if player classes don't match
			if (limitPlayerClass >= 0 && limitPlayerClass != _currentPlayerClass) {
				continue;
			}
			// check if item slots don't match
			if (limitItemSlot >= 0 && limitItemSlot != _currentItemSlot) {
				continue;
			}
			// check if item definitions don't match
			if (limitItemDefinition >= 0 && limitItemDefinition != _currentItemDefinition) {
				continue;
			}
			// check if item classes don't match
			if (strlen(limitItemClass) > 0 && strcmp(limitItemClass, _currentItemClass) != 0) {
				continue;
			}
			// check if either limit is zero - if they are then don't bother checking current equip levels
			if (limitCurrentTeam == 0 || limitTotal == 0) {
				//PrintToServer("%s %i removed from '%s' due to limit being 0", PREFIX_COMMAND, _currentItemDefinition, _currentPlayerID);
				return false;
			}
			// well, it looks the limit should apply - let's count the number of already equipped items that match
			querySuceeded = GetMatchingSlotCounts(limitItemClass, limitItemDefinition, limitItemSlot, limitPlayerClass, _currentPlayerID, _currentPlayerTeam, countTeam, countTotal);
			//
			if (querySuceeded) {
				// check the limits
				if (limitCurrentTeam > 0 && limitCurrentTeam <= countTeam) {
					//PrintToServer("%s %i removed from '%s' due to team limit", _currentItemDefinition, _currentPlayerID);
					return false;
				} else if (limitTotal > 0 && limitTotal <= countTotal) {
					//PrintToServer("%s %i removed from '%s' due to total limit", _currentItemDefinition, _currentPlayerID);
					return false;
				}
			}
		}
	}
	return true;
}

/* GetMatchingSlotCounts()
 *
 * Query the database for slots that match the requested details
 * -------------------------------------------------------------------------- */
bool:GetMatchingSlotCounts(const String:_limitItemClass[], _limitItemDefinition, _limitItemSlot, _limitPlayerClass, const String:_currentPlayerID[], _currentPlayerTeam, &_countTeam, &_countTotal)
{
	if (g_PreparedQuerySlotDetailsComplex == INVALID_HANDLE) {
		decl String:error[STRLEN_DBError];
		g_PreparedQuerySlotDetailsComplex = SQL_PrepareQuery(g_DatabaseConnection, DBQ_SLOT_FETCH_ROWS, error, sizeof(error));
		if (g_PreparedQuerySlotDetailsComplex == INVALID_HANDLE) {
			PrintToServer("%s Query Creation failed: %s", PREFIX_COMMAND,error);
			return true;
		}
	}
	decl String:paramString[STRLEN_NumberKey];
	SQL_BindParamString(g_PreparedQuerySlotDetailsComplex, 0, _limitItemClass, false);
	SQL_BindParamString(g_PreparedQuerySlotDetailsComplex, 1, _limitItemClass, false);
	Format(paramString, sizeof(paramString), "%i", _limitItemDefinition);
	SQL_BindParamInt(g_PreparedQuerySlotDetailsComplex, 2, _limitItemDefinition, false);
	SQL_BindParamString(g_PreparedQuerySlotDetailsComplex, 3, paramString, false);
	Format(paramString, sizeof(paramString), "%i", _limitItemSlot);
	SQL_BindParamInt(g_PreparedQuerySlotDetailsComplex, 4, _limitItemSlot, false);
	SQL_BindParamString(g_PreparedQuerySlotDetailsComplex, 5, paramString, false);
	if (!SQL_Execute(g_PreparedQuerySlotDetailsComplex)) {
		PrintToServer("%s Query Execute failed.", PREFIX_COMMAND);
		return true;
	} else {
		return CountSlotQueryResults(g_PreparedQuerySlotDetailsComplex, _limitPlayerClass, _currentPlayerID, _currentPlayerTeam, _countTeam, _countTotal);
	}
}

/* CountSlotQueryResults()
 *
 * Count the query results and return those counts
 * -------------------------------------------------------------------------- */
bool:CountSlotQueryResults(Handle:_queryHandle, _limitPlayerClass, const String:_currentPlayerID[], _currentPlayerTeam, &_countTeam, &_countTotal)
{
	// make sure we ignore the current player from the counts - should we just return a referenced bool? probably not for performance reasons
	//
	_countTeam = 0;
	_countTotal = 0;
	//
	if (_queryHandle == INVALID_HANDLE) {
		return true;
	}
	//
	decl String:slotPlayerID[STRLEN_AuthString];
	new slotPlayerTeam, slotPlayerClass;
	//
	while (SQL_FetchRow(_queryHandle))
	{
		SQL_FetchString(_queryHandle, 0, slotPlayerID, sizeof(slotPlayerID));
		slotPlayerTeam = SQL_FetchInt(_queryHandle, 1);
		if (strcmp(slotPlayerID, _currentPlayerID) != 0) {
			slotPlayerClass = SQL_FetchInt(_queryHandle, 2);
			if (_limitPlayerClass < 0 || slotPlayerClass == _limitPlayerClass) {
				_countTotal++;
				if (_currentPlayerTeam == slotPlayerTeam) {
					_countTeam++;
				}
			}
		}
	}
	return true;
}

/***
 *    $$\   $$\   $$\     $$\ $$\ $$\   $$\     $$\                     
 *    $$ |  $$ |  $$ |    \__|$$ |\__|  $$ |    \__|                    
 *    $$ |  $$ |$$$$$$\   $$\ $$ |$$\ $$$$$$\   $$\  $$$$$$\   $$$$$$$\ 
 *    $$ |  $$ |\_$$  _|  $$ |$$ |$$ |\_$$  _|  $$ |$$  __$$\ $$  _____|
 *    $$ |  $$ |  $$ |    $$ |$$ |$$ |  $$ |    $$ |$$$$$$$$ |\$$$$$$\  
 *    $$ |  $$ |  $$ |$$\ $$ |$$ |$$ |  $$ |$$\ $$ |$$   ____| \____$$\ 
 *    \$$$$$$  |  \$$$$  |$$ |$$ |$$ |  \$$$$  |$$ |\$$$$$$$\ $$$$$$$  |
 *     \______/    \____/ \__|\__|\__|   \____/ \__| \_______|\_______/ 
 */

/* GetItemName()
 *
 * Get the name of a weapon from the items_game key/value handle
 * -------------------------------------------------------------------------- */
GetItemName(_itemDefinitionIndex, String:_value[], _maxlength)
{
	KvRewind(g_VaultItemsGame);
	if (KvJumpToKey(g_VaultItemsGame, KV_KeyItemsGameItems, false)) {
		decl String:itemDefinitionKey[STRLEN_NumberKey];
		Format(itemDefinitionKey, sizeof(itemDefinitionKey), "%i", _itemDefinitionIndex);
		if (KvJumpToKey(g_VaultItemsGame, itemDefinitionKey)) {
			decl String:name[_maxlength];
			KvGetString(g_VaultItemsGame, KV_KeyItemsGameName, name, _maxlength);
			strcopy(_value, _maxlength, name);
		}
	}
	KvRewind(g_VaultItemsGame);
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * -------------------------------------------------------------------------- */
bool:IsValidClient(_client)
{
	if (_client < 1 || _client > MaxClients)
		return false;
	if (!IsClientConnected(_client))
		return false;
	return IsClientInGame(_client);
}


/* ShowHudMessage()
 *
 * Shows a simple HUD message to the client
 * -------------------------------------------------------------------------- */
ShowHudMessage(_client, const String:_message[])
{
	if (IsValidClient(_client)) {
		SetHudTextParams(-1.0, 0.4, 5.0, 255, 225, 255, 255, 0, 0.1, 0.1, 0.2);
		ShowHudText(_client, -1, "%s", _message);
	}
}
