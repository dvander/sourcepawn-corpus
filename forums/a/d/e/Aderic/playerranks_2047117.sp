#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>

#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

//#define PLUGIN_DEBUG

#define MAX_STEAMID_LENGTH  		32
#define MAX_TEAM_LENGTH				14

#define NO_ISSUER					-1									// Sent in-place of userids in SQL callbacks to identify whether a query was automatic or sent via command by an actual client.
#define WORLD 						0							   		// WORLD is defined as 0 because it looks prettier that way.
#define DATABASE_VERSION			8									// The database version that this plugin should be interacting with.
#define PLUGIN_VERSION 				"3.4.1" 						   	// Plugin version, this value is fed into myinfo and sm_rankingversion CVAR.
#define PLUGIN_PREFIX_PLAIN 		"[Player Ranks 3.4.1]"		   		// Our console friendly prefix.
#define PLUGIN_PREFIX 				"{strange}[Player Ranks]{default}" 	// Our chat friendly prefix.
#define PLUGIN_TAG					"playerranks"		   				// Tags to associate with this plugin.

#define SQL_SAVERECORD				"REPLACE INTO `players` VALUES ('%s','%s',%f,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%f,%i,%i,%i,%i,%i,%i,%i,%i,%i);"
#define SQL_GETTOPPLAYERS			"SELECT * FROM `players` ORDER BY points DESC LIMIT %i;"
#define SQL_CREATETABLE				"CREATE TABLE IF NOT EXISTS `players` (`steamid` TEXT,`nickname` TEXT, `points` FLOAT,`seen` INT);"
#define SQL_CREATESETTINGS			"CREATE TABLE IF NOT EXISTS `settings` (`key` VARCHAR(255) PRIMARY KEY,`value` INT);"
#define SQL_CREATEVERSION			"INSERT INTO `settings` VALUES ('version', 0);"
#define SQL_ENABLEUTF8				"SET NAMES 'UTF8'" 					// Only supported by MySQL, SQLite works with only UTF8 and doesn't need this.

#define SQL_LOADCLIENT				"SELECT points,deaths,kills,assists,backstabs,headshots,feigns,merkills,merlvl,monkills,monlvl,hhhkills,playtime,flagcaptures,flagdefends,capcaptures,capdefends,roundsplayed,dominationsgood,dominationsbad,deflects,streak FROM players WHERE steamid = '%s';"
#define SQL_LOADCLIENTRANK			"SELECT COUNT(*) FROM players WHERE points >= '%f';"
#define SQL_GETRECORDCOUNT			"SELECT COUNT(*) FROM players;"
#define SQL_PURGEOLD				"DELETE FROM `players` WHERE `seen` <= %i;"
#define SQL_DELETERANK				"DELETE FROM `players` WHERE `steamid` = '%s';"

#define SQL_GETCLIENTSLIKEMYSQL		"SELECT nickname, steamid FROM players WHERE LOWER(nickname) LIKE LOWER('%c%s%c') ESCAPE '\\\\' LIMIT %i;"
#define SQL_GETCLIENTSLIKESQLITE	"SELECT nickname, steamid FROM players WHERE LOWER(nickname) LIKE LOWER('%c%s%c') ESCAPE '\\' LIMIT %i;"

#define SQL_FINDCLIENTSTEAM			"SELECT nickname,points,deaths,kills,assists,backstabs,headshots,feigns,merkills,merlvl,monkills,monlvl,hhhkills,playtime,flagcaptures,flagdefends,capcaptures,capdefends,roundsplayed,dominationsgood,dominationsbad,seen,deflects,streak FROM players WHERE steamid = '%s';"

///////////////////////
// RESET QUERIES     //
///////////////////////
#define SQL_RESET_MYSQL		"TRUNCATE TABLE `players`;"
#define SQL_RESET_SQLITE	"DELETE FROM `players`;"

#define SQL_GETRESETDATE	"SELECT `value` FROM `settings` WHERE `key`='resetdate';"
#define SQL_SETRESETDATE	"UPDATE `settings` SET `value`='%s' WHERE `key`='resetdate';"

///////////////////////
// UPDATE QUERIES    //
///////////////////////
#define SQL_GETVERSION		"SELECT `value` FROM `settings` WHERE `key`='version';"
#define SQL_SETVERSION		"UPDATE `settings` SET `value`=%i WHERE `key`='version';"

#define SQL_UPDATE_1		"ALTER TABLE `players` ADD deaths INT DEFAULT 0; ALTER TABLE `players` ADD kills INT DEFAULT 0; ALTER TABLE `players` ADD assists INT DEFAULT 0; ALTER TABLE `players` ADD backstabs INT DEFAULT 0; ALTER TABLE `players` ADD headshots INT DEFAULT 0; ALTER TABLE `players` ADD feigns INT DEFAULT 0;"
#define SQL_UPDATE_2		"ALTER TABLE `players` RENAME TO `players_old`;CREATE TABLE `players` (`steamid` VARCHAR(20) PRIMARY KEY,`nickname` TEXT, `points` FLOAT,`seen` INT, `deaths` INT, `kills` INT, `assists` INT, `backstabs` INT, `headshots` INT, `feigns` INT);REPLACE INTO `players` SELECT * FROM `players_old`; DROP TABLE `players_old`;"
#define SQL_UPDATE_3		"ALTER TABLE `players` CHARSET utf8 COLLATE utf8_bin; ALTER TABLE `players` CHANGE nickname nickname VARBINARY(255); ALTER TABLE `players` CHANGE nickname nickname VARCHAR(255) CHARSET utf8 COLLATE utf8_bin;" //1.8.1
#define SQL_UPDATE_4		"DELETE FROM `players` WHERE `steamid` = ''; DELETE FROM `players` WHERE `steamid` = 'BOT'; ALTER TABLE `players` ADD merkills INT DEFAULT 0; ALTER TABLE `players` ADD merlvl INT DEFAULT 0; ALTER TABLE `players` ADD monkills INT DEFAULT 0; ALTER TABLE `players` ADD monlvl INT DEFAULT 0; ALTER TABLE `players` ADD hhhkills INT DEFAULT 0; ALTER TABLE `players` ADD playtime FLOAT DEFAULT 0.00;" //2.0
#define SQL_UPDATE_5		"ALTER TABLE `players` ADD flagcaptures INT DEFAULT 0; ALTER TABLE `players` ADD flagdefends INT DEFAULT 0; ALTER TABLE `players` ADD capcaptures INT DEFAULT 0; ALTER TABLE `players` ADD capdefends INT DEFAULT 0; ALTER TABLE `players` ADD roundsplayed INT DEFAULT 0; ALTER TABLE `players` ADD dominationsgood INT DEFAULT 0; ALTER TABLE `players` ADD dominationsbad INT DEFAULT 0;" //2.1
#define SQL_UPDATE_6		"INSERT INTO `settings` VALUES ('resetdate','%s'); ALTER TABLE `players` ADD deflects INT DEFAULT 0; ALTER TABLE `players` ADD streak INT DEFAULT 0"
#define SQL_UPDATE_7		"ALTER TABLE `players` CHANGE `points` `points` DECIMAL(65,6)"
#define SQL_UPDATE_8		"DROP TABLE `settings`;CREATE TABLE `settings` (`key` VARCHAR(255) PRIMARY KEY,`value` VARCHAR(16));INSERT INTO `settings` VALUES ('resetdate','%s');INSERT INTO `settings` VALUES ('version','8');"

#define NOTIFICATION_NONE			0
#define NOTIFICATION_OBJECTIVES		1
#define NOTIFICATION_KILLS			2
#define NOTIFICATION_TELEPORTS		3

#define SAVEMODE_REGULAR			0
#define SAVEMODE_LAST				1
#define SAVEMODE_DISCONNECTING		2

#define RESETMODE_DISABLED			0
#define RESETMODE_MONTHLY			1
#define RESETMODE_YEARLY			2

#define MAX_TOP_SCORES				25

#define UPDATE_URL    				"https://bitbucket.org/Aderic/player-ranks/raw/default/playerranks.txt"

// Our CVARs
new Handle:pluginVersion;		 //STRING: Version of the currently running plugin. Reflects PLUGIN_VERSION as defined.
new Handle:pluginThreshold;  	 // FLOAT: Amount of points required to be entered into the ranking database. This is so we don't have an annoyingly large amount of players with a score of 0 floating around.
new Handle:pluginShowCmds;	 	 //  BOOL: If 1, chat commands are show in chat. If 0, chat commands still function, but are not sent to chat.
new Handle:autoUpdate; 	 	 	 //  BOOL: You killed Pumpkin Lord, you get this point reward.
new Handle:suppressRankMsg;	 	 //  BOOL: If 1, this plugin will not display any rank on player connect.
new Handle:allowBotStats; 	 	 //  BOOL: Bots are counted in the kills, deaths, feigns, assists, headshots and backstabs if 1.

// The point reward is calculated with this formula:
// L = Boss Level - The bosses current level, when you kill him.
// R = Base Reward - This is the guaranteed non-scaled reward added to the total.
// M = rewardMultBase - This multiplier will scale the reward up.
// BM = reward<boss>Kill - This multiplier is boss-specific, scales reward by level.
// (L - 1) * (M + ((L - 1) * BM)) + R

new Handle:rewardMerasmusKill; 			// FLOAT: You killed Merasmus, you get this base point reward.
new Handle:rewardMonoculusKill; 	 	// FLOAT: You killed Monoculus, you get this base point reward.
new Handle:rewardHHHKill; 	 			// FLOAT: You killed Pumpkin Lord, you get this point reward.

new Handle:rewardMultBase;				// FLOAT: Overall multiplier.

new Handle:rewardMerasmusMult;  	 	// FLOAT: Adjusts how many points each level is worth.
new Handle:rewardMonoculusMult;  		// FLOAT: Adjusts how many points each level is worth.

new Handle:rewardBossDmgMin;  	 		//   INT: Damage amount required to receive boss reward.

new Handle:rewardRBMin; 	 // FLOAT: Point amount required to receive the round bonus.
new Handle:rewardCapCapture; // FLOAT: You captured a point, and you get.... points!
new Handle:rewardCapDefense; // FLOAT: You defended a point, and you get.... points!
new Handle:rewardRoundBonus; // FLOAT: You were in the game the entire round... guess what, you get this point reward.

new Handle:rewardFlagCapture;// FLOAT: You captured a flag.
new Handle:rewardFlagDefend; // FLOAT: You defended a flag cap.

new Handle:rewardAdminKill;  // FLOAT: You killed an admin, you get this point reward.
new Handle:rewardBotKill; 	 // FLOAT: You killed a bot, you get this point reward.
new Handle:rewardPlayerKill; // FLOAT: You killed a player, you get this point reward.
new Handle:rewardAssistMult; // FLOAT: You assisted a player and were given a fraction of the killer's reward. 0.66 = two thirds of player kill score. Killer gets 1 point, assister gets 0.66 points.
new Handle:rewardHeadshotMult;//FLOAT: A player/bot was killed via a headshot.
new Handle:rewardBackstabMult;//FLOAT: A player/bot was backstabbed.
new Handle:rewardDeflectMult; //FLOAT: A player/bot was killed via a deflected projectile.
new Handle:rewardSentry;	 // FLOAT: You destroyed a sentry, you get this point reward.
new Handle:rewardMiniSentry; // FLOAT: You destroyed a mini sentry, you get this point reward.
new Handle:rewardDispenser;	 // FLOAT: You destroyed a dispenser, you get this point reward.
new Handle:rewardTeleporter; // FLOAT: You destroyed a teleporter, you get this point reward.
new Handle:rewardLevel1Mult; // FLOAT: Level multiplier for destroying a level 1 building.
new Handle:rewardLevel2Mult; // FLOAT: Level multiplier for destroying a level 2 building.
new Handle:rewardLevel3Mult; // FLOAT: Level multiplier for destroying a level 3 building.
new Handle:rewardPlayerTele; // FLOAT: A player used your teleporter, you get this point reward.
new Handle:rewardKS; 	 	 // FLOAT: Point reward bonus for killing people with killstreaks.
new Handle:rewardKSMax;		 // FLOAT: Maximum point reward bonus killstreaks are allowed to give.

new Handle:userNotificationLvl; //INT: If 0, notifications aren't sent to the player when they score.
// If 1, the player is notified when they receive point and flag captures, and defends.
// If 2, All of the above, and that they received points when they kill players and bots.
// If 3, All of the above, and they receive points when they teleport people.

new Handle:FORWARD_OnReward; 
new Handle:FORWARD_OnReward_Post;

new Handle:menuFilterBots;	 //  BOOL: If true, bots will be hidden from the menu.
new Handle:menuDisableRank;	 //  BOOL: If true, !rank command will cease to function.
new Handle:connection; 		 //	  SQL: The handle to the plugin's SQL connection. Should anything go wrong and this not make a connection, the plugin WILL disable itself.

new Handle:updateInterval; 	 //   INT: How often the top ten updates.
new Handle:updateTimer;		 // TIMER: The timer handle we're using to track the top ten.

new Handle:expireTime; 	 	 //   INT: How many days should a rank be kept in the system?
new Handle:cleanupInterval;	 //	FLOAT: How many minutes until we launch a query to clean up the ranking system?
new Handle:cleanupMode;	 	 //   INT: 0: Disables cleanup. 1: Run cleanup only on map start. 2: Run cleanup on an interval.
new Handle:cleanupTimer;	 // TIMER: The timer handle we're using to perform the cleanup query on.

new Handle:maxSearchResults; //   INT: Limits how many search results can be found.
new Handle:useHUD;    	 	 //  BOOL: Draws the HUD on all clients if true.
new Handle:hudOnDeath;    	 //  BOOL: Shows the client their score on death.
new Handle:playerMinimum;    //   INT: Amount of players required for this plugin to track scoring.
new Handle:rankResetMode;	 //   INT: Ranges between 0 and 2, refer to RESETMODE_* declarations. 0 = Disabled, 1 = Monthly, 2 = Yearly
new Handle:rewardDefendCooldown;//INT: Seconds required to elapse before a player can be rewarded for another defend.

new Handle:pointLossMode;	 //   INT: If 0: No points are taken. 1: One point is lost on death. 2: Equal points are stolen by the killer.
new Handle:roundHUD;		 //	  HUD: Draws the point amount to the client's screen.

new totalCount;				 //   INT: Complete count of every player in the database.
new playerCount;			 //   INT: Current player count, not bots.
new bool:isTF2;				 //  BOOL: Is this game TF2? Is it safe to use TF2 detections?
new bool:isSQLite;			 //	 BOOL: If SQLite
new bool:isReady;			 //  BOOL: Is set to true when the connection is established and any update required is ran.
new bool:roundEnded;		 //  BOOL: If true, the round has ended.
new bool:configsExecuted;	 //  BOOL: If true, OnConfigsExecuted() has been called.
new bossIndex;				 //   INT: Stores the current boss's index.
new databaseVersion;		 //	  INT: Database version.

// Our hacked up enum to store player's score-related data.
enum ScoreTracker {
	rank,					// Current ranking number on the server.
	kills,				    // Kills for kill/death ratio.
	deaths,				    // Deaths for kill/death ratio.
	assists,				// Assist count
	headshots,				// Headshot count.
	backstabs,				// Backstab count.
	feigns,					// How many fake deaths have been done.
	bossdmg,				// Amount of damage the player has contributed to killing the boss.
	totaltime,				// Total time played.
	jointime,				// Time joined.
	merKills,				// Merasmus kill count.
	merLvl,					// Merasmus maximum level.
	monKills,				// Monoculus kill count.
	monLvl,					// Monoculus maximum level.
	hhhKills,				// Headless Horsemann kill count
	Float:roundPoints,		// Points the client has earned this round.
	Float:points,			// Points the client currently has.
	bool:validated,			// Did OnClientPutInServer get called for this client?
	bool:loaded,			// Is the client record loaded?
	bool:roundBonus,		// If the client has been here the entire round.
	flagCaptures,			// Flags captured.
	flagDefends,			// Flags defended.
	capCaptures,			// Points captured.
	capDefends,				// Points defended.
	roundsPlayed,			// Full rounds played.
	dominationsGood,		// How many times you've dominated a player.
	dominationsBad,			// How many times you've been dominated by a player.
	deflects,				// Deflected projectile count.
	currentStreak,			// Current killstreak count.
	highestStreak,			// Highest killstreak count.
	lastDefend,				// Last timestamp of known point defend. This is to prevent spamming of point defends.
	bool:exempt,			// If true, this client's rank and all statistics will not be altered until set to false.
}
// Our top ten score object, stores 
enum ScoreStruct {
	String:tNickname[MAX_NAME_LENGTH],    	// Our name on file for this player.
	String:tSteamId[MAX_STEAMID_LENGTH],  	// His Steam ID.
	Float:ttotaltime,					  	// Total time played on server.
	tmerKills,							  	// Merasmus kill count.
	tmerLvl,							  	// Merasmus level.
	tmonKills,							  	// Monoculus kill count.
	tmonLvl,							  	// Monoculus level.
	thhhKills,							  	// Headless Horsemann kill count.
	Float:tPoints,						  	// Total points.
	tSeen,								  	// Last seen.
	tKills,								  	// Player/Bot kill count.
	tDeaths,							  	// Death count.
	tAssists,							  	// Assist count.
	tHeadshots,							    // Headshot count.
	tBackstabs,							    // Backstab count.
	tFeigns,							    // Feigned death count.
	tflagCaptures,							// Flags captured.
	tflagDefends,							// Flags defended.
	tcapCaptures,							// Points captured.
	tcapDefends,							// Points defended.
	troundsPlayed,							// Full rounds played.
	tdominationsGood,						// How many times you've dominated a player.
	tdominationsBad,						// How many times you've been dominated by a player.
	tDeflects,								// How many times you've deflect-killed a player.
	tHighestStreak							// Highest killstreak count.
}

new topScores[MAX_TOP_SCORES][ScoreStruct];
new scores[MAXPLAYERS][ScoreTracker];
// Our plugin info.
public Plugin:myinfo = {
	name = "Player Ranks",
	author = "Aderic",
	description = "Simple lightweight tracking of player scores.",
	version = PLUGIN_VERSION
}

// Our plugin is starting! Shhh!
public OnPluginStart() {
	LoadTranslations("common.phrases");
	LoadTranslations("playerranks.phrases");
	
	userNotificationLvl = 			CreateConVar("pr_notifications",			"3" ,			"Notifies the user when they receive points, 0 = No notifications, 3 = Maximum. Values 0-3 are accepted.",		FCVAR_NONE, true, 0.0, true, 3.0);
	cleanupMode = 					CreateConVar("pr_cleanupmode",				"1" ,			"0: Disables cleanup, 1: Run cleanup only on map start. 2: Run cleanup on an interval and on every map start.",	FCVAR_NONE, true, 0.0, true, 2.0);
	pointLossMode =					CreateConVar("pr_pointLossMode",			"0" ,			"If 0: No points are taken. 1: One point is lost on death. 2: Equal points are stolen by the killer.",			FCVAR_NONE, true, 0.0, true, 2.0);
	rankResetMode =					CreateConVar("pr_resetMode",				"0" ,			"If 0: Database never resets. 1: Database resets every month. 2: Database resets every year.",					FCVAR_NONE, true, 0.0, true, 2.0);
	autoUpdate =					CreateConVar("pr_autoupdate",				"1" ,			"If set to 1, this plugin will check for and update itself.",													FCVAR_NONE, true, 0.0, true, 1.0);
	pluginShowCmds = 				CreateConVar("pr_showcmds",					"1" ,			"If 1: When a player types a chat command such as !rank, it will be shown in chat.", 							FCVAR_NONE, true, 0.0, true, 1.0);
	suppressRankMsg = 				CreateConVar("pr_suppressRankMsg",			"0" ,			"If 1: This plugin will not display any rank on player connect.", 												FCVAR_NONE, true, 0.0, true, 1.0);
	menuFilterBots = 				CreateConVar("pr_menufilterbots",			"0" ,			"If 1: Bots will be hidden from the menu.", 																	FCVAR_NONE, true, 0.0, true, 1.0);
	menuDisableRank = 				CreateConVar("pr_menudisablerank",			"0" ,			"If 1: !rank command will cease to function.", 																	FCVAR_NONE, true, 0.0, true, 1.0);
	useHUD = 						CreateConVar("pr_useHUD",					"1" ,			"If 1: The score text will be drawn when a client earns points.", 												FCVAR_NONE, true, 0.0, true, 1.0);
	hudOnDeath = 					CreateConVar("pr_useHUDDeath",				"1" ,			"If 1: The HUD will be shown when a player dies.",																FCVAR_NONE, true, 0.0, true, 1.0);
	allowBotStats =  				CreateConVar("pr_allowBotStats",			"1" , 			"If 1: Bots are counted in kills, deaths, assists, backstabs, headshots, and feigns.", 							FCVAR_NONE, true, 0.0, true, 1.0);
	expireTime =  					CreateConVar("pr_expiretime", 				"130", 			"Amount of unplayed days before a user record is removed from the ranking system.", 							FCVAR_NONE, true, 1.0);
	cleanupInterval = 				CreateConVar("pr_cleanupinterval", 			"60", 			"Amount of minutes before the expiration cleaner runs a cleanup on the server.", 								FCVAR_NONE, true, 1.0);
	updateInterval =  				CreateConVar("pr_updateinterval",			"30", 			"Amount of seconds before the top player listing updates and all clients have their scores autosaved.", 		FCVAR_NONE, true, 1.0);
	pluginThreshold =  				CreateConVar("pr_threshold",				"10", 			"Points required before the user is actually put in the ranking system, keeps the database nice and tidy.",		FCVAR_NONE, true, 0.0);
	playerMinimum =  				CreateConVar("pr_playerminimum",			"0" , 			"Amount of players required to be connected to the server for this plugin to track scoring.",					FCVAR_NONE, true, 0.0);
	maxSearchResults = 				CreateConVar("pr_maxSearchResults",			"25",			"Limits how many search results can be displayed with !rank, set to 0 to disable searching.",					FCVAR_NONE, true, 0.0);
	rewardKS =						CreateConVar("pr_rewardkillstreak",			"0.1",			"Point reward bonus for each killstreak the player has.",														FCVAR_NONE, true, 0.0);
	rewardKSMax =					CreateConVar("pr_rewardkillstreakmax",		"1.5",			"Point reward maximum that the killstreak bonus is allowed to offer.",											FCVAR_NONE, true, 0.0);
	
	RegAdminCmd("pr_forcesave", 	Command_ForceSave, 		ADMFLAG_ROOT, 	"Forces the plugin to save all clients."							);
	RegAdminCmd("pr_reward", 		Command_Reward, 		ADMFLAG_ROOT, 	"Gives the specified client points."								);
	RegAdminCmd("pr_revoke", 		Command_Revoke, 		ADMFLAG_ROOT, 	"Removes points from the specified client."							);
	RegAdminCmd("pr_forcecleanup", 	Command_ForceCleanup,	ADMFLAG_ROOT, 	"Forces the plugin to clean old records from the system."			);
	RegAdminCmd("pr_dumpinfo",		Command_DumpInfo,		ADMFLAG_ROOT, 	"Dumps debug related information to command issuer's console."		);
	RegAdminCmd("pr_reload",		Command_Reload,			ADMFLAG_ROOT, 	"Renews the database connection if dropped."						);
	RegAdminCmd("pr_reset",			Command_Reset,			ADMFLAG_ROOT,	"Safely clears all ranks out of the system."						);
	
	RegConsoleCmd("pr_exempt",		Command_Exempt,			"Turns off stat tracking for you in Player Ranks.");
	
	HookEvent("player_connect", 	OnPlayerConnect,		EventHookMode_Post	);
	HookEvent("player_disconnect", 	OnPlayerDisconnect,		EventHookMode_Pre	);
	HookEvent("player_death", 		OnPlayerDeath								);
	HookEvent("round_start", 		OnRoundStarted								);
	HookEvent("round_end", 			OnRoundEnd									);
	
	// Basic barebone CVARs.
	rewardAdminKill = 			CreateConVar("pr_rewardadmin",			"1.15",			"Point reward for killing an admin.");
	rewardPlayerKill =  		CreateConVar("pr_rewardplayer", 		"1.00", 		"Point reward for killing a player.");
	rewardBotKill =				CreateConVar("pr_rewardbot", 			"0.80", 		"Point reward for killing a bot.");
	rewardAssistMult = 			CreateConVar("pr_rewardassist",			"0.75",			"Point reward multiplier for assisting a bot/player kill. At 0.75, this would give 75% of the reward to the assister.");
	
	// Variables that apply to TF2 only.	
	if (GetEngineVersion() == Engine_TF2) {
		isTF2 = true;
		rewardRoundBonus =  		CreateConVar("pr_rewardroundbonus",			"7.50", 		"Point reward for being in the game for an entire round.");
		rewardRBMin		 =			CreateConVar("pr_rewardrbmin",				"5.00",			"Point reward requirement for player to receive round bonus.");
		rewardSentry =  			CreateConVar("pr_rewardsentry", 			"3.00", 		"Point reward for destroying a sentry.");
		rewardDispenser =  			CreateConVar("pr_rewarddispenser", 			"0.80", 		"Point reward for destroying a dispenser.");
		rewardTeleporter =  		CreateConVar("pr_rewardteleporter",			"1.20", 		"Point reward for destroying a teleporter.");
		rewardPlayerTele =  		CreateConVar("pr_rewardplayertele", 		"0.10", 		"Point reward for teleporting a player.");
		rewardMiniSentry = 			CreateConVar("pr_rewardminisentry",			"0.60",			"Point reward for destroying a mini sentry.");
		rewardLevel1Mult = 			CreateConVar("pr_rewardlevel1mult",			"0.33",			"Point reward multiplier for destroying a level 1 building.");
		rewardLevel2Mult = 			CreateConVar("pr_rewardlevel2mult",			"0.66",			"Point reward multiplier for destroying a level 2 building.");
		rewardLevel3Mult = 			CreateConVar("pr_rewardlevel3mult",			"1.00",			"Point reward multiplier for destroying a level 3 building.");
		rewardHeadshotMult = 		CreateConVar("pr_rewardheadshot",			"1.33",			"Point reward multiplier for killing a bot/player via a headshot.");
		rewardBackstabMult = 		CreateConVar("pr_rewardbackstab",			"1.33",			"Point reward multiplier for backstabbing a bot/player.");
		rewardDeflectMult = 		CreateConVar("pr_rewarddeflect",			"1.33",			"Point reward multiplier for killing a bot/player via a deflected projectile.");
		rewardCapCapture =  		CreateConVar("pr_rewardcapcapture",			"2.0", 			"Point reward for capturing a point.");
		rewardCapDefense =  		CreateConVar("pr_rewardcapdefense",			"1.25", 		"Point reward for defending a point.");
			
		rewardFlagCapture =			CreateConVar("pr_rewardflagCap",			"2.0",			"Amount of points a player should receive for capturing a flag.");
		rewardFlagDefend =			CreateConVar("pr_rewardflagDefend", 		"1.25",			"Amount of points a player should receive for defending a flag capture.");
		
		// BOSS CVARs
		rewardMerasmusKill = 		CreateConVar("pr_rewardmerasmuskill",		"5.0", 			"Base point amount for killing Merasmus.");
		rewardMonoculusKill =		CreateConVar("pr_rewardmonoculuskill",		"5.0", 			"Base point amount for killing Monoculus.");
		rewardHHHKill =    			CreateConVar("pr_rewardhhhkill",			"5.0", 			"Base point amount for killing Horseless Headless Horsemann.");
		rewardMultBase = 			CreateConVar("pr_rewardmultbase",			"0.09", 		"The level scale multiplier for killing a boss.");
		rewardMerasmusMult =		CreateConVar("pr_rewardmerasmusmult",		"0.04", 		"Base point amount per level for killing Merasmus.");
		rewardMonoculusMult =    	CreateConVar("pr_rewardmonoculusmult",		"0.04", 		"Base point amount per level for killing the eye boss.");
		rewardBossDmgMin = 			CreateConVar("pr_rewardbossdmgmin",			"250", 			"Amount of damage required for a player to receive the boss reward.");
		
		rewardDefendCooldown = 		CreateConVar("pr_rewarddefendcooldown",		"15",			"Time between credited capture point defends. This prevents spamming of defend-rewards.");
		
		HookEvent("npc_hurt",					OnNPCDamaged);
		
		HookEvent("teamplay_flag_event",		OnFlagState);
		
		////// BOSS EVENTS
		// When the boss spawns.
		HookEvent("pumpkin_lord_summoned",		OnHeadlessHorsemannSpawn);
		HookEvent("merasmus_summoned",			OnMerasmusSpawn);
		HookEvent("eyeball_boss_summoned",		OnMonoculusSpawn);
		
		// When the boss is killed.
		HookEvent("pumpkin_lord_killed",		OnHeadlessHorsemannKilled);
		HookEvent("merasmus_killed",			OnMerasmusKilled);
		HookEvent("eyeball_boss_killed",		OnMonoculusKilled);
		
		// When a boss leaves, pumpkin lord never leaves. He is always rdy2fite!!!!!!!!!111111one oen one one eleven
		HookEvent("eyeball_boss_escaped",		OnBossLeave);
		HookEvent("merasmus_escaped",			OnBossLeave);
		
		// Round started events.
		HookEvent("teamplay_round_active", 		OnRoundStarted);
		HookEvent("arena_round_start", 			OnRoundStarted);
		HookEvent("teamplay_round_win", 		OnRoundEnd, EventHookMode_Post);
		
		// Round ended events.
		HookEvent("teamplay_setup_finished", 	OnRoundSetupEnded);
		
		// Object destroyed event.
		HookEvent("object_destroyed", 			OnObjectDestroyed);
		
		// Capture point events.
		HookEvent("teamplay_point_captured", 	OnPointCaptured);
		HookEvent("teamplay_capture_blocked", 	OnPointDefended);
		
		// Player teleported event.
		HookEvent("player_teleported", 			OnPlayerTeleported);
		
		AddCommandListener(Command_Say, "say");
		AddCommandListener(Command_Say, "say2");
		AddCommandListener(Command_Say, "say_team");
	}
	else {
		LogMessage("%s Warning: Server is not running TF2. This plugin has not been tested for other games.", PLUGIN_PREFIX_PLAIN);
		PrintToServer("%s Warning: Server is not running TF2. This plugin has not been tested for other games.", PLUGIN_PREFIX_PLAIN);
	}
	
	roundHUD = CreateHudSynchronizer();
	HUD_SetStyle_Default();
	
	// Execute our config (or create it if it does not exist)
	AutoExecConfig(true, "playerranks");
}
// Register our natives.
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("PR_Reward", 				Native_Reward);
	CreateNative("PR_Revoke", 				Native_Revoke);
	CreateNative("PR_IsClientLoaded", 		Native_IsClientLoaded);
	
	CreateNative("PR_GetAssists", 			Native_GetAssists);
	CreateNative("PR_GetBackstabs", 		Native_GetBackstabs);
	CreateNative("PR_GetBossDamage", 		Native_GetBossDamage);
	CreateNative("PR_GetDeaths", 			Native_GetDeaths);
	CreateNative("PR_GetFeigns", 			Native_GetFeigns);
	CreateNative("PR_GetHeadshots", 		Native_GetHeadshots);
	CreateNative("PR_GetKills", 			Native_GetKills);
	CreateNative("PR_GetMerasmusKills", 	Native_GetMerasmusKills);
	CreateNative("PR_GetMerasmusLevel", 	Native_GetMerasmusLevel);
	CreateNative("PR_GetMonoculusKills", 	Native_GetMonoculusKills);
	CreateNative("PR_GetMonoculusLevel", 	Native_GetMonoculusLevel);
	CreateNative("PR_GetRoundEligibility", 	Native_GetRoundEligible);
	CreateNative("PR_GetTimePlayed", 		Native_GetTimePlayed);
	CreateNative("PR_GetRoundPoints", 		Native_GetRoundPoints);
	CreateNative("PR_GetTotalPoints", 		Native_GetTotalPoints);
	
	CreateNative("PR_SetAssists", 			Native_SetAssists);
	CreateNative("PR_SetBackstabs", 		Native_SetBackstabs);
	CreateNative("PR_SetBossDamage", 		Native_SetBossDamage);
	CreateNative("PR_SetDeaths", 			Native_SetDeaths);
	CreateNative("PR_SetFeigns", 			Native_SetFeigns);
	CreateNative("PR_SetHeadshots", 		Native_SetHeadshots);
	CreateNative("PR_SetKills", 			Native_SetKills);
	CreateNative("PR_SetMerasmusKills", 	Native_SetMerasmusKills);
	CreateNative("PR_SetMerasmusLevel", 	Native_SetMerasmusLevel);
	CreateNative("PR_SetMonoculusKills", 	Native_SetMonoculusKills);
	CreateNative("PR_SetMonoculusLevel", 	Native_SetMonoculusLevel);
	CreateNative("PR_SetRoundEligibility", 	Native_SetRoundEligible);
	CreateNative("PR_SetRoundPoints", 		Native_SetRoundPoints);
	CreateNative("PR_SetTotalPoints", 		Native_SetTotalPoints);
	
	CreateNative("PR_SaveAll", 				Native_SaveAll);
	CreateNative("PR_ShowRankMenu", 		Native_ShowRank);
	CreateNative("PR_ShowRankMe", 			Native_ShowRankMe);
	CreateNative("PR_ShowTopPlayers", 		Native_ShowTop);
	
	if (FORWARD_OnReward == INVALID_HANDLE)
		FORWARD_OnReward = CreateGlobalForward("PR_OnReward", ET_Event, Param_Cell, Param_FloatByRef, Param_Cell);
	
	if (FORWARD_OnReward_Post == INVALID_HANDLE)
		FORWARD_OnReward_Post = CreateGlobalForward("PR_OnReward_Post", ET_Event, Param_Cell, Param_Float, Param_Cell);
	
	RegPluginLibrary("Player Ranks");
	
	return APLRes_Success;
}
// Called when config is loaded or created.
public OnConfigsExecuted() {
	// Create our version CVAR after config is executed. 
	// Seems improper to write this value to the config so that's why we do it after config.
	pluginVersion =  CreateConVar("pr_rankingversion", 	PLUGIN_VERSION, 		"Current version of the plugin. Read Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	SetConVarString(pluginVersion, 		PLUGIN_VERSION);
	
	HookConVarChange(pluginVersion, 	OnPluginVersionChanged);
	
	HookConVarChange(cleanupMode, 		OnCleanupModeChanged);
	HookConVarChange(autoUpdate, 		OnPluginAutoUpdateChanged);
	
	// Creates the SQL connection, checks any player currently on the server, and creates the update timer.
	Initialize();
	configsExecuted = true;
	
	if (GetConVarBool(autoUpdate) == true && LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}
// This may or may not get called when the plugin is loaded.
public OnLibraryAdded(const String:name[]) {
	if (configsExecuted == true && GetConVarBool(autoUpdate) == true && StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}
// Occurs when the plugin is updating.
public Action:Updater_OnPluginDownloading() {
	PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_updateavailable", LANG_SERVER);
}
// Occurs when the plugin has updated.
public Updater_OnPluginUpdated() {
	PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_updatesuccess", LANG_SERVER);
}

//////////////////////////////////////
//  CVAR EVENTS
//////////////////////////////////////
public OnPluginAutoUpdateChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (LibraryExists("updater")) {
		if (GetConVarBool(autoUpdate) == false)
			Updater_RemovePlugin();
		else
			Updater_AddPlugin(UPDATE_URL);
	}
}
public OnResetModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (GetConVarInt(cvar) == RESETMODE_DISABLED) {
		PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_resetmode_disabled", LANG_SERVER);
	}
	else {
		decl String:currentDate[8];
		FormatTime(currentDate, sizeof(currentDate), "%m/%Y", GetTime());
		
		decl String:query[128];
		Format(query, sizeof(query), SQL_SETRESETDATE, currentDate);
		
		// Why are we sending 2 you might ask? Well...
		// That value is labelled "automatic" in the callback.
		// If it is false this means the callback was sent from a client-issued command.
		// If it is true this means an actual automatic server reset happened.
		// If it is 2, this means no reset happened; the reset date was just changed to today.
		// so the plugin doesn't get the idea to reset the database; instead we want the user to be absolutely sure they want to reset.
		SQL_TQuery(connection, Query_ResetDatabase_S3, query, 2, DBPrio_Low);
	}
}
// Kills the timer if topTenInterval is set to 0.0 or invalid, resets the timer with the new interval if interval has changed and is over 0.0.
public OnUpdaterIntervalChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (updateTimer != INVALID_HANDLE)
	{
		CloseHandle(updateTimer);
		#if defined PLUGIN_DEBUG
			PrintToServer("%s Update timer was killed to adjust to the new update interval.", PLUGIN_PREFIX_PLAIN);
		#endif
	}
	
	updateTimer = CreateTimer(float(GetConVarInt(updateInterval)), Updater, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
// Expiration
public OnCleanupIntervalChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cleanupTimer != INVALID_HANDLE)
	{
		CloseHandle(cleanupTimer);
		cleanupTimer = INVALID_HANDLE;
		
		#if defined PLUGIN_DEBUG
			PrintToServer("%s Expiration cleanup timer was killed to adjust to the new interval.", PLUGIN_PREFIX_PLAIN);
		#endif
	}
	
	if (GetConVarInt(cleanupMode) == 2)
		cleanupTimer = CreateTimer(GetConVarFloat(cleanupInterval) * 60, CleanupTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 
	else
		PrintToServer("%s The cleanup interval was changed while cleanup mode was set to %i. This CVAR will have no effect unless cleanup mode is set to 2.", PLUGIN_PREFIX_PLAIN, GetConVarInt(cleanupMode));
}
// Mode for cleanup was altered.
public OnCleanupModeChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {		
	if (cleanupTimer != INVALID_HANDLE)
	{
		KillTimer(cleanupTimer);
		cleanupTimer = INVALID_HANDLE;
		
		#if defined PLUGIN_DEBUG
			PrintToServer("%s Cleanup timer was killed for the mode change.", PLUGIN_PREFIX_PLAIN);
		#endif
	}
	
	if (GetConVarInt(cleanupMode) == 2) {
		cleanupTimer = CreateTimer(GetConVarFloat(cleanupInterval) * 60, CleanupTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 
		#if defined PLUGIN_DEBUG
			PrintToServer("%s Cleanup timer was started for the mode change.", PLUGIN_PREFIX_PLAIN);
		#endif
	}
}

// Blocks changing of the plugin version.
public OnPluginVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	// If the newly set value is different from the actual version number.
	if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
		// Set it back to the way it was supposed to be.
		SetConVarString(pluginVersion, PLUGIN_VERSION);
	}
}
//////////////////////////////////////
//  COMMANDS
//////////////////////////////////////
public Action:Command_Reload(client, args) {
	if (connection != INVALID_HANDLE) {
		ForceSave();
		CloseHandle(connection);
		connection = INVALID_HANDLE;
	}
	Initialize();
	return Plugin_Handled;
}
public Action:Command_Reset(client, args) {
	if (isReady == false) {
		if (client != WORLD) {
			CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_notready", client);
		}
		else {
			PrintToServer("%s %T", PLUGIN_PREFIX, "pr_notready", LANG_SERVER);
		}
		return Plugin_Handled;
	}
	
	// Block all loading and saving to the DB.
	isReady = false;
	
	ResetDatabase(client == WORLD ? WORLD : GetClientUserId(client));
	return Plugin_Handled;
}
public Action:Command_Exempt(client, args) {
	scores[client][exempt] = !scores[client][exempt];
	
	if (scores[client][exempt] == true)
		CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_exempt_enable", client);
	else
		CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_exempt_disable", client);
	
	return Plugin_Handled;
}
// Dumps debug info to console.
public Action:Command_DumpInfo(client, args) {
	if (isSQLite)
		ReplyToCommand(client, "Driver: SQLite");
	else
		ReplyToCommand(client, "Driver: MySQL");
	
	
	ReplyToCommand(client, "Plugin Version: %s", PLUGIN_VERSION);
	ReplyToCommand(client, "DB Version: %i", databaseVersion);
	ReplyToCommand(client, "Boss Index: %i", bossIndex);
	ReplyToCommand(client, "Player Count: %i", playerCount);
	ReplyToCommand(client, "--- Client statistics ---");
	ReplyToCommand(client, "Client ID  |Eligible| Score| Rank | Boss Dmg");
	for (new clientId = 1; clientId <= MaxClients; clientId++) {
		ReplyToCommand(client, "Client %i    |  %i  |  %.2f  |  %i  |  %i", clientId, IsClientEligible(clientId), scores[clientId][points], scores[clientId][rank], scores[clientId][bossdmg]);
	}
	return Plugin_Handled;
}
// Dumps information from the score tracker to the server console.
public Action:Command_ForceSave(client, args) {
	ForceSave();
	CReplyToCommand(client, "%s %T", PLUGIN_PREFIX, "pr_commandsave", client);
}
// Forces the ranking system to delete old client records.
public Action:Command_ForceCleanup(client, args) {
	RunCleanup(client);
}
// Gives the specified client a specified amount of points.
public Action:Command_Reward(client, args) {
	if (args < 2) {
		CReplyToCommand(client, "%s Usage: pr_reward <#userid|name> <amount>.", client);
		return Plugin_Handled;
	}
	new String:searchPattern[MAX_NAME_LENGTH];
	GetCmdArg(1, searchPattern, MAX_NAME_LENGTH);
	
	new String:pointAmountString[8];
	GetCmdArg(2, pointAmountString, sizeof(pointAmountString));
	
	new Float:pointAmount;
	pointAmount = StringToFloat(pointAmountString);
	
	if (pointAmount <= 0.0) {
		CReplyToCommand(client, "%s %T", PLUGIN_PREFIX, "pr_commandpointamountinvalid", client);
		return Plugin_Handled;
	}
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetResults[MAX_TARGET_LENGTH];
	new targetCount;
	new bool:tn_is_ml;
	targetCount = ProcessTargetString(searchPattern, client, targetResults, MAX_TARGET_LENGTH, 0, targetName, MAX_TARGET_LENGTH, tn_is_ml);
	
	if (targetCount < 1) {
		ReplyToTargetError(client, targetCount);
	}
	
	new String:issuerName[MAX_NAME_LENGTH];
	
	if (client != WORLD)
		GetClientName(client, issuerName, MAX_NAME_LENGTH);
		
	new clientID;
	for (new targetIndex = 0; targetIndex < targetCount; targetIndex++) {
		clientID = targetResults[targetIndex];
		Reward(clientID, pointAmount, true);
		
		if (IsClientInGame(clientID) == false) // Skip disconnected clients.
			continue;
		
		if (client != WORLD) {
			CPrintToChat(clientID, "%s %T", PLUGIN_PREFIX, "pr_commandrewardreceive", clientID, issuerName, pointAmount);
		}
		else
			CPrintToChat(clientID, "%s %T", PLUGIN_PREFIX, "pr_commandrewardreceiveanonymous", clientID, pointAmount);
	}
	
	return Plugin_Handled;
}
// Revokes points from the specified client.
public Action:Command_Revoke(client, args) {
	if (args < 2) {
		CReplyToCommand(client, "%s Usage: pr_revoke <#userid|name> <amount>.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	new String:searchPattern[MAX_NAME_LENGTH];
	GetCmdArg(1, searchPattern, MAX_NAME_LENGTH);
	
	new String:pointAmountString[8];
	GetCmdArg(2, pointAmountString, sizeof(pointAmountString));
	
	new Float:pointAmount;
	pointAmount = StringToFloat(pointAmountString);
	
	if (pointAmount <= 0.00) {
		CReplyToCommand(client, "%s %T", PLUGIN_PREFIX, "pr_commandpointamountinvalid", client);
		return Plugin_Handled;
	}
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetResults[MAX_TARGET_LENGTH];
	new targetCount;
	new bool:tn_is_ml;
	targetCount = ProcessTargetString(searchPattern, client, targetResults, MAX_TARGET_LENGTH, 0, targetName, MAX_TARGET_LENGTH, tn_is_ml);
	
	if (targetCount < 1) {
		ReplyToTargetError(client, targetCount);
	}
	
	new String:issuerName[MAX_NAME_LENGTH];
	
	if (client != WORLD)
		GetClientName(client, issuerName, MAX_NAME_LENGTH);
	
	new clientID;
	for (new targetIndex = 0; targetIndex < targetCount; targetIndex++) {
		clientID = targetResults[targetIndex];
		Revoke(clientID, pointAmount, true);
		
		if (IsClientInGame(clientID) == false) // Skip disconnected clients.
			continue;
		
		if (client != WORLD)
			CPrintToChat(clientID, "%s %T", PLUGIN_PREFIX, "pr_commandrevokereceive", clientID, issuerName, pointAmount);
		else
			CPrintToChat(clientID, "%s %T", PLUGIN_PREFIX, "pr_commandrevokereceiveanonymous", clientID, pointAmount);
	}
	
	return Plugin_Handled;
}
// Happens before a message is sent, blocks messages that start with a slash and processes them.
public Action:Command_Say(client, const String:command[], argc) {
	decl String:text[192];
	new bool:silent = false;
	
	new startPos = 0;
	
	if (GetCmdArgString(text, sizeof(text)) < 1)
		return Plugin_Continue;
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startPos = 1;
	}
	
	if (StrEqual(command, "say2", false) == true)
		startPos += 4;
	
	silent = (text[startPos] == 47);
	
	if (silent == false && text[startPos] != 33)
		return Plugin_Continue;
	
	startPos++;
	
	if (StrEqual(text[startPos], "rank", false) == true || StrEqual(text[startPos], "ranks", false) == true) {
		if (GetConVarBool(menuDisableRank) == true)
		{
			CReplyToCommand(client, "%s %T", PLUGIN_PREFIX, "pr_rankmenu_disabled", client);
			return Plugin_Handled;
		}
		
		ShowRankMenu(client);
	}
	else if (StrEqual(text[startPos], "top", false) == true) {
		ShowTopMenu(client);
	}
	else if (StrEqual(text[startPos], "rankme", false)) {
		CreateTimer(0.01, RankMeDelay, GetClientUserId(client));
	}
	else {
		
		new spaceIndex = StrContains(text, " ");
		
		if (spaceIndex == -1) {
			return Plugin_Continue;
		}
		
		decl String:section[5];
		strcopy(section, sizeof(section), text[startPos]);
		
		if (StrEqual(section, "rank", false) == true) {
			new maxResults = GetConVarInt(maxSearchResults);
			
			if (maxResults == 0) {
				CPrintToChat(client, "%s %T", "pr_search_disabled", client);
				return Plugin_Handled;
			}
			
			new String:searchTerm[MAX_NAME_LENGTH * 2 + 1];
			strcopy(searchTerm, sizeof(searchTerm), text[spaceIndex + 1]);
			
			decl String:query[512];
			
			// Checks if STEAM ID was entered.
			if (SimpleRegexMatch(searchTerm, "^(STEAM|steam)_0:[01]:[0-9]{1,9}$") > 0) {
				Format(query, sizeof(query), SQL_FINDCLIENTSTEAM, searchTerm);
				
				SQL_TQuery(connection, Query_FindClientBySteam, query, GetClientUserId(client));
			}
			else {
				SQL_EscapeString(connection, searchTerm, searchTerm, sizeof(searchTerm));
				LikeEscape(searchTerm);
				
				if (isSQLite == false)
					Format(query, sizeof(query), SQL_GETCLIENTSLIKEMYSQL, 0x25, searchTerm, 0x25, maxResults);
				else
					Format(query, sizeof(query), SQL_GETCLIENTSLIKESQLITE, 0x25, searchTerm, 0x25, maxResults);
				
				SQL_TQuery(connection, Query_FindClientByName, query, GetClientUserId(client));
			}
		}
	}
	
	return (GetConVarBool(pluginShowCmds) ? (silent ? Plugin_Handled : Plugin_Continue) : Plugin_Handled); // Forward it.
}


public Action:RankMeDelay(Handle:timer, any:clientUid) {
	new client = GetClientOfUserId(clientUid);
	
	if (client != WORLD && IsClientInGame(client))
		ShowRankMe(client);
	
	return Plugin_Stop;
}
//Treats % and _ as literals (via escaping) in the LIKE query to avoid the funkiness using these two very important identifiers.
public LikeEscape(String:nameString[MAX_NAME_LENGTH * 2 + 1]) {
	ReplaceString(nameString, sizeof(nameString), "\92", "\92\92");
	ReplaceString(nameString, sizeof(nameString), "%", "\92%");
	ReplaceString(nameString, sizeof(nameString), "_", "\92_");
}
// Shows the rank menu, this is called from chat.
public ShowRankMenu(client) {
	if (isReady == false || IsClientInGame(client) == false || client == WORLD) {
		return;
	}
	
	new Handle:rankMenu = CreateMenu(RankMenuHandler);
	
	decl String:rankMenuHeader[32];
	Format(rankMenuHeader, sizeof(rankMenuHeader), "%T", "pr_list_select_option", client);
	SetMenuTitle(rankMenu, rankMenuHeader);
		
	decl String:topPlayersLabel[32];
	Format(topPlayersLabel, sizeof(topPlayersLabel), "%T", "pr_list_button_show_top_players", client);
		
	AddMenuItem(rankMenu, "0", topPlayersLabel);
		
	for (new clientId = 1; clientId <= MaxClients; clientId++) {
		new String:clientName[MAX_NAME_LENGTH];
		new String:menuItem[100];
		new String:clientIdString[3];
			
		if (!IsClientInGame(clientId) || scores[clientId][loaded] == false)
			continue;
			
		IntToString(clientId, clientIdString, sizeof(clientIdString));
		GetClientName(clientId, clientName, sizeof(clientName));
			
		if (IsFakeClient(clientId) == false)
			Format(menuItem, sizeof(menuItem), "%T", "pr_list_player", client, clientName, scores[clientId][points]);
		else if (GetConVarBool(menuFilterBots) == false && IsClientReplay(clientId) == false) {
			Format(menuItem, sizeof(menuItem), "%T %T", "pr_bot_tag", client, "pr_list_player", client, clientName, scores[clientId][points]);
		}
		else
			continue;
			
		AddMenuItem(rankMenu, clientIdString, menuItem);
	}
	
	SetMenuExitButton(rankMenu, true);
	DisplayMenu(rankMenu, client, 0);
}
// Shows the top players menu, this is called from chat.
public ShowTopMenu(client) {
	if (isReady == false || IsClientInGame(client) == false || client == WORLD) {
		return;
	}
	
	new Handle:topTenMenu = CreateMenu(TopTenMenuHandler);
	SetMenuPagination(topTenMenu, 5);
		
	new String:menuItem[100];
	new String:rankNumberString[4];
		
	new String:topLabel[64];
	Format(topLabel, sizeof(topLabel), "%T", "pr_list_top_players_label", client);
	SetMenuTitle(topTenMenu, topLabel);
			
	for (new rankNumber = 0; rankNumber < MAX_TOP_SCORES; rankNumber++) {
		// In the event that a top ten score is equal to zero, stop listing. This happens if there's not enough players to fill the top players.
		if (topScores[rankNumber][tPoints] == 0.00)
		{
			// If the first rank we come across has 0 points, then that means there aren't any players in the database! Otherwise we'd be getting them sorted from highest to lowest.
			if (rankNumber == 0) {
				Format(menuItem, sizeof(menuItem), "%T", "pr_list_zero_top_players", client);
				AddMenuItem(topTenMenu, rankNumberString, menuItem);
			}
			break;
		}
		IntToString(rankNumber, rankNumberString, sizeof(rankNumberString));
		Format(menuItem, sizeof(menuItem), "%T", "pr_list_top_player", client, rankNumber + 1, topScores[rankNumber][tNickname], topScores[rankNumber][tPoints]);
		AddMenuItem(topTenMenu, rankNumberString, menuItem);
	}
	SetMenuExitButton(topTenMenu, true);
	DisplayMenu(topTenMenu, client, 0);
}
// Shows the top players menu, this is called from chat.
public ShowSearchMenu(client, Handle:data) {
	if (isReady == false || IsClientInGame(client) == false || client == WORLD) {
		CloseHandle(data);
		return;
	}
	
	new Handle:searchMenu = CreateMenu(SearchMenuHandler);
	SetMenuPagination(searchMenu, 5);
	SetMenuTitle(searchMenu, "%T", "pr_search_results_menu_label", client);
	
	//Step back 1 cell to read our row count.
	SetPackPosition(data, GetPackPosition(data) - 8);
	
	new resultCount = ReadPackCell(data);
	
	if (resultCount == GetConVarInt(maxSearchResults)) {
		CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_search_refine", client, GetConVarInt(maxSearchResults));
	}
	
	ResetPack(data);
	
	for (new I = 0; I < resultCount; I++) {
		decl String:name[MAX_NAME_LENGTH];
		decl String:steamId[MAX_STEAMID_LENGTH];
		
		ReadPackString(data, name, MAX_NAME_LENGTH);
		ReadPackString(data, steamId, MAX_STEAMID_LENGTH);
		
		AddMenuItem(searchMenu, steamId, name);
	}
	
	CloseHandle(data);
	
	SetMenuExitButton(searchMenu, true);
	DisplayMenu(searchMenu, client, 0);
}
// Shows your rank info, this is called from chat.
public ShowRankMe(client) {
	if (isReady == false || IsClientInGame(client) == false || client == WORLD) {
		return;
	}
	
	HUD_Draw(client);
	
	if (scores[client][rank] == 0) {
		if (scores[client][points] < GetConVarFloat(pluginThreshold)) {
			CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_rankme_belowthreshold", client, scores[client][points], GetConVarFloat(pluginThreshold));
		}
		else {
			CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_rankme_updating", client, scores[client][points], GetConVarInt(updateInterval));		
		}
	}
	else {
		CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_rankme_normal", client, scores[client][rank], totalCount, scores[client][points]);
	}
		
	if (scores[client][kills] > 0.00 && scores[client][deaths] > 0.00)
	{
		new Float:kdRatio = FloatDiv(float(scores[client][kills]), float(scores[client][deaths]));
		CPrintToChat(client, "%s %T %T", PLUGIN_PREFIX, "pr_stats_1", client, scores[client][kills], scores[client][deaths], scores[client][assists], "pr_stats_2", client, kdRatio);
	}
	else
		CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_stats_1", client, scores[client][kills], scores[client][deaths], scores[client][assists]);
		
	if (isTF2)
	{
		CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_stats_3", client, scores[client][headshots], scores[client][backstabs], scores[client][feigns], scores[client][deflects], scores[client][highestStreak]);	
		
		if (scores[client][merKills] > 0)
			CPrintToChat(client, "%s %T %T", PLUGIN_PREFIX, "pr_stats_4", client, scores[client][merKills], "Merasmus", "pr_stats_5", client, scores[client][merLvl]);
		
		if (scores[client][monKills] > 0)
			CPrintToChat(client, "%s %T %T", PLUGIN_PREFIX, "pr_stats_4", client, scores[client][monKills], "Monoculus", "pr_stats_5", client, scores[client][monLvl]);
		
		if (scores[client][hhhKills] > 0)
			CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_stats_4", client, scores[client][hhhKills], "Headless Horsemann");
	}
	
	CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_stats_6", client, GetTimePlayed(client) / 3600);	
	CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_stats_7", client, scores[client][flagCaptures], scores[client][flagDefends], scores[client][capCaptures], scores[client][capDefends], scores[client][roundsPlayed]);
	CPrintToChat(client, "%s %T", PLUGIN_PREFIX, "pr_stats_8", client, scores[client][dominationsGood], scores[client][dominationsBad]);
}

//////////////////////////////////////
//  MENU HANDLERS
//////////////////////////////////////
// When a player says !rank
public RankMenuHandler(Handle:menu, MenuAction:action, param1, param2) {		
	if (action == MenuAction_Select)
	{	
		if (IsClientInGame(param1) == false) {
			CloseHandle(menu);
			return;
		}
	
		new String:selectionString[3];
		GetMenuItem(menu, param2, selectionString, sizeof(selectionString));
	
		if (StrEqual(selectionString, "0")) {
			new Handle:topTenMenu = CreateMenu(TopTenMenuHandler);
			SetMenuPagination(topTenMenu, 5);
			
			new String:menuItem[100];
			new String:rankNumberString[4];
						
		
			new String:topLabel[64];
			Format(topLabel, sizeof(topLabel), "%T", "pr_list_top_players_label", param1);
			
			SetMenuTitle(topTenMenu, topLabel);
			
			for (new rankNumber = 0; rankNumber < MAX_TOP_SCORES; rankNumber++) {
				if (topScores[rankNumber][tPoints] == 0.00)
				{	// If the first rank we come across has 0 points, then that means there aren't any more players in the database! Otherwise we'd be getting them sorted from highest to lowest.
					if (rankNumber == 0) {
						Format(menuItem, sizeof(menuItem), "%T", "pr_list_zero_top_players", param1);
						AddMenuItem(topTenMenu, rankNumberString, menuItem);
					}
					break;
				}
				IntToString(rankNumber, rankNumberString, sizeof(rankNumberString));
				Format(menuItem, sizeof(menuItem), "%T", "pr_list_top_player", param1, rankNumber + 1, topScores[rankNumber][tNickname], topScores[rankNumber][tPoints]);
				AddMenuItem(topTenMenu, rankNumberString, menuItem);
			}
			DisplayMenu(topTenMenu, param1, 0);
		}
		else {		
			new clientId = StringToInt(selectionString);
			if (IsClientInGame(clientId)) {
				new String:clientName[MAX_NAME_LENGTH];
				GetClientName(clientId, clientName, sizeof(clientName));
				
				if (IsFakeClient(clientId) == false) {
					if (scores[clientId][rank] == 0)
						CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_rank_unranked", param1, clientName, scores[clientId][roundPoints], scores[clientId][points]);
					else {
						CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_rank_normal", param1, clientName, scores[clientId][rank], scores[clientId][roundPoints], scores[clientId][points]);
					}
				}
				else {
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_rank_bot", param1, clientName, scores[clientId][roundPoints]);
				}
				
				if (scores[clientId][kills] > 0.00 && scores[clientId][deaths] > 0.00)
					CPrintToChat(param1, "%s %T %T", PLUGIN_PREFIX, "pr_stats_1", param1, scores[clientId][kills], scores[clientId][deaths], scores[clientId][assists], "pr_stats_2", param1, FloatDiv(float(scores[clientId][kills]), float(scores[clientId][deaths])));
				else
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_1", param1, scores[clientId][kills], scores[clientId][deaths], scores[clientId][assists]);
					
				if (isTF2) {
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_3", param1, scores[clientId][headshots], scores[clientId][backstabs], scores[clientId][feigns], scores[clientId][deflects], scores[clientId][highestStreak]);
					
					if (scores[clientId][merKills] > 0)
						CPrintToChat(param1, "%s %T %T", PLUGIN_PREFIX, "pr_stats_4", param1, scores[clientId][merKills], "Merasmus", "pr_stats_5", param1, scores[clientId][merLvl]);
					
					if (scores[clientId][monKills] > 0)
						CPrintToChat(param1, "%s %T %T", PLUGIN_PREFIX, "pr_stats_4", param1, scores[clientId][monKills], "Monoculus", "pr_stats_5", param1, scores[clientId][monLvl]);
					
					if (scores[clientId][hhhKills] > 0)
						CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_4", param1, scores[clientId][hhhKills], "Headless Horsemann");
					
					if (IsFakeClient(clientId) == false)
						CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_6", param1, GetTimePlayed(clientId) / 3600);
					
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_7", param1, scores[clientId][flagCaptures], scores[clientId][flagDefends], scores[clientId][capCaptures], scores[clientId][capDefends], scores[clientId][roundsPlayed]);
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_8", param1, scores[clientId][dominationsGood], scores[clientId][dominationsBad]);
					
				}
			}
			else {
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_invalid_selection", param1);
			}
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

// When a player selects Top Players in the rank menu.
public TopTenMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1) == false) {
			CloseHandle(menu);
			return;
		}
	
		new String:selectionString[3];
		GetMenuItem(menu, param2, selectionString, sizeof(selectionString));
		
		new selectedIndex = StringToInt(selectionString);
		new onlineIndex = 0;
		
		if (topScores[selectedIndex][tSeen] != 0) {
			for (new I = 1; I <= MaxClients; I++) {
				if (IsClientInGame(I) == false)
					continue;
				
				new String:steamId[MAX_STEAMID_LENGTH];
				GetClientAuthId(I, AuthId_Steam2, steamId, MAX_STEAMID_LENGTH, false);
				
				if (StrEqual(topScores[selectedIndex][tSteamId], steamId) == true) {
					onlineIndex = I;
					break;
				}
			}
			
			if (onlineIndex == 0) {
				new String:seenDate[30];
				FormatTime(seenDate, sizeof(seenDate), "%B %d, %Y", topScores[selectedIndex][tSeen]);
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_top_rank_offline", param1, topScores[selectedIndex][tNickname], selectedIndex + 1, totalCount, topScores[selectedIndex][tPoints], seenDate);
				//return;
			}
			else {
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_top_rank_online",  param1, topScores[selectedIndex][tNickname], selectedIndex + 1, totalCount, topScores[selectedIndex][tPoints]);
			}
			
			if (topScores[selectedIndex][tKills] > 0.00 && topScores[selectedIndex][tDeaths] > 0.00) {
				CPrintToChat(param1, "%s %T %T", PLUGIN_PREFIX, "pr_stats_1", param1, topScores[selectedIndex][tKills], topScores[selectedIndex][tDeaths], topScores[selectedIndex][tAssists], "pr_stats_2", param1, FloatDiv(float(topScores[selectedIndex][tKills]), float(topScores[selectedIndex][tDeaths])));
			}
			else {
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_1", param1, topScores[selectedIndex][tKills], topScores[selectedIndex][tDeaths], topScores[selectedIndex][tAssists]);
			}
			
			if (isTF2 == true) {
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_3", param1, topScores[selectedIndex][tHeadshots], topScores[selectedIndex][tBackstabs], topScores[selectedIndex][tFeigns], topScores[selectedIndex][tDeflects], topScores[selectedIndex][tHighestStreak]);
				
				if (topScores[selectedIndex][tmerKills] > 0)
					CPrintToChat(param1, "%s %T %T", PLUGIN_PREFIX, "pr_stats_4", param1, topScores[selectedIndex][tmerKills], "Merasmus", "pr_stats_5", param1, topScores[selectedIndex][tmerLvl]);
					
				if (topScores[selectedIndex][tmonKills] > 0)
					CPrintToChat(param1, "%s %T %T", PLUGIN_PREFIX, "pr_stats_4", param1, topScores[selectedIndex][tmonKills], "Monoculus", "pr_stats_5", param1, topScores[selectedIndex][tmonLvl]);
					
				if (topScores[selectedIndex][thhhKills] > 0)
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_4", param1, topScores[selectedIndex][thhhKills], "Headless Horsemann");
				
				if (onlineIndex != WORLD && IsClientInGame(onlineIndex) && scores[onlineIndex][loaded] == true) {
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_6", param1, GetTimePlayed(onlineIndex) / 3600);
				}
				else {
					CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_6", param1, topScores[selectedIndex][ttotaltime] / 3600);
				}
				
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_7", param1, topScores[selectedIndex][tflagCaptures], topScores[selectedIndex][tflagDefends], topScores[selectedIndex][tcapCaptures], topScores[selectedIndex][tcapDefends], topScores[selectedIndex][troundsPlayed]);
				CPrintToChat(param1, "%s %T", PLUGIN_PREFIX, "pr_stats_8", param1, topScores[selectedIndex][tdominationsGood], topScores[selectedIndex][tdominationsBad]);
			}
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}
// Purges old ranks from the database.
public Action:CleanupTimer(Handle:timer) {
	RunCleanup(-1);
	return Plugin_Continue;
}
// Updates our top players list as specified from toptenInterval.
public Action:Updater(Handle:timer) {
	if (isReady == false || playerCount == 0 || connection == INVALID_HANDLE) {
		return Plugin_Continue;
	}
	
	for(new clientId = 1; clientId <= MaxClients; clientId++) {
		if (IsClientEligible(clientId))
		{	
			// Get the client's name.
			new String:playerName[MAX_NAME_LENGTH];
			new String:playerSteamID[MAX_STEAMID_LENGTH];
			
			GetClientName(clientId, playerName, MAX_NAME_LENGTH);
			GetClientAuthId(clientId, AuthId_Steam2, playerSteamID, MAX_STEAMID_LENGTH);
			
			SaveScore(clientId, playerName, playerSteamID);

			new String:Query[255];
			Format(Query, sizeof(Query), SQL_LOADCLIENTRANK, scores[clientId][points]);	
			new Handle:dataPack = CreateDataPack();
			WritePackCell(dataPack, GetClientUserId(clientId)); // Our client ID.
			WritePackCell(dataPack, false);	   // Is this the first time the client's rank has loaded?
			
			SQL_TQuery(connection, Query_LoadRank, Query, dataPack);
		}
	}
	
	new String:query[255];
	Format(query, sizeof(query), SQL_GETTOPPLAYERS, MAX_TOP_SCORES);
	
	SQL_TQuery(connection, Query_TopPlayers, 				  query);
	SQL_TQuery(connection, Query_GetRecordCount, SQL_GETRECORDCOUNT);
	
	return Plugin_Continue;
}
// When a player selects Top Players in the rank menu.
public SearchMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1) == false) {
			CloseHandle(menu);
			return;
		}
	
		new String:steamId[MAX_STEAMID_LENGTH];
		GetMenuItem(menu, param2, steamId, sizeof(steamId));
		
		new String:Query[512];
		Format(Query, sizeof(Query), SQL_FINDCLIENTSTEAM, steamId);
		SQL_TQuery(connection, Query_FindClientBySteam, Query, GetClientUserId(param1));
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

//////////////////////////////////////
//  EVENTS
//////////////////////////////////////
// When the map ends, kill our update timer.
public OnMapEnd() {
	if (connection != INVALID_HANDLE) {
		isReady = false;
		CloseHandle(connection);
		connection = INVALID_HANDLE;
	}
	
	if (cleanupTimer != INVALID_HANDLE) {
		CloseHandle(cleanupTimer);
		cleanupTimer = INVALID_HANDLE;
		
		#if defined PLUGIN_DEBUG
			PrintToServer("%s Server is shutting down, expiration cleaner was stopped.", PLUGIN_PREFIX_PLAIN);
		#endif
	}
	
	if (updateTimer != INVALID_HANDLE) {
		CloseHandle(updateTimer);
		updateTimer = INVALID_HANDLE;
		
		#if defined PLUGIN_DEBUG
			PrintToServer("%s Server is shutting down, updater was stopped.", PLUGIN_PREFIX_PLAIN);
		#endif
	}
}
// This event fires when the player connects, used to suppress the join message. It happens once, does not fire through map changes.
public Action:OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
	PurgeClient(GetEventInt(event, "index")+1);
	return Plugin_Continue;
}

public OnClientPutInServer(client) {
	if (IsClientAuthorized(client))
		LoadClientRecord(client, false);
}

public OnClientAuthorized(client, const String:auth[]) {
	if (IsClientInGame(client))
		LoadClientRecord(client, false);
}


public LoadClientRecord(client, bool:silent) {
	// Skip clients when the SQL database is being established, after the connection is established we'll come back and grab their info.
	// Prevent score from being reloaded multiple times.
		
	if (isReady == false || scores[client][validated] == true)
		return;
	
	scores[client][validated] = true;
	scores[client][jointime] = GetTime();
	
	if (IsFakeClient(client) == true) {
		scores[client][loaded] = true;
		return;
	}
	
	decl String:clientSteam[MAX_STEAMID_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, clientSteam, MAX_STEAMID_LENGTH);

	//LogError("Loading record for Steam ID %s", clientSteam);
	
	new String:Query[512];
	Format(Query, sizeof(Query), SQL_LOADCLIENT, clientSteam);
	
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, GetClientUserId(client));	// The client we'll be using.
	WritePackCell(dataPack, !silent);					// Is this the first client load for this client?

	SQL_TQuery(connection, Query_LoadClient, Query, dataPack);
}

// Notifies the score tracker of the client leaving, and tosses away the client's info, decrements player count previously added by OnPlayerConnect
public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (isReady == false || clientId == WORLD || GetEventBool(event, "bot") || scores[clientId][validated] == false)
		return Plugin_Continue;
	
	// Get the client's name.
	new String:playerName[MAX_NAME_LENGTH];
	GetEventString(event, "name", playerName, MAX_NAME_LENGTH);
	
	new String:playerSteamID[MAX_STEAMID_LENGTH];
	GetClientAuthId(clientId, AuthId_Steam2, playerSteamID, MAX_STEAMID_LENGTH);
	
	if (playerSteamID[0] != 0 && IsClientEligible(clientId) == true)
		SaveScore(clientId, playerName, playerSteamID, SAVEMODE_DISCONNECTING);
	else
		PurgeClient(clientId);
	
	return Plugin_Continue;
}

public OnClientConnected(client) {
	if (IsFakeClient(client))
		return;
	
	UpdatePlayerCount();
	
	// We're just one player too short of ranking being enabled.
	if (playerCount == GetConVarInt(playerMinimum)) {
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_enabled_true");
	}
}

public OnClientDisconnect(client) {
	if (IsFakeClient(client))
		return;
	
	UpdatePlayerCount();
	
	// We're just one player too short of ranking being enabled.
	if (playerCount == GetConVarInt(playerMinimum)) {
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_enabled_false");
	}
	
	playerCount--; // Decrement player count.
}

UpdatePlayerCount() {
	new newCount;
	
	for (new clientId = 1; clientId <= MaxClients; clientId++) {
		if (IsClientConnected(clientId) && IsFakeClient(clientId) == false)
			newCount++;
	}
	
	playerCount = newCount;
}
// Flags online clients as eligible to receive the round bonus if applicable, called multiple times, which will not matter.
public Action:OnRoundStarted(Handle:event, const String:name[], bool:dontBroadcast) {
	HUD_SetStyle_Default();
	
	roundEnded = false;
	// Less work to do on the server.. I noticed it WILL continue firing these events CONSTANTLY with nobody on the server.
	if (playerCount == 0) 
		return Plugin_Continue;
	
	bossIndex = -1;
	
	for (new clientId = 1; clientId <= MaxClients; clientId++) {
		if (IsClientInGame(clientId) == false)
			continue;
		
		if (scores[clientId][roundBonus] == false) {				
			// Stops us from sending multiple messages to players because of TF2's funky round events.
			scores[clientId][roundBonus] = true;
				
			if (scores[clientId][exempt] == false && playerCount >= GetConVarInt(playerMinimum) && GetConVarFloat(rewardRoundBonus) > 0.0) {
				if (GetConVarFloat(rewardRBMin) > 0.0)
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundbonus_notifyminimum", clientId, GetConVarFloat(rewardRBMin));
				else	
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundbonus_notify", clientId);
			}
		}
		
		scores[clientId][roundPoints] = 0.0;
	}
	
	
	#if defined PLUGIN_DEBUG
		PrintToServer("%s All clients were just notified of the round bonus eligibility.", PLUGIN_PREFIX_PLAIN);
	#endif
	
	return Plugin_Continue;
}

// This is called once when the setup time ends, it'll do the same thing as OnRoundStarted, just with a message telling the connected users that they came just in time.
public Action:OnRoundSetupEnded(Handle:event, const String:name[], bool:dontBroadcast) {
	// Less work to do on the server.. I noticed it WILL continue firing these events CONSTANTLY with nobody on the server.
	if (playerCount == 0) 
		return Plugin_Continue;
	
	bossIndex = -1;
	
	for (new clientId = 1; clientId <= MaxClients; clientId++) {
		if (IsClientInGame(clientId) == false)
			continue;
			
		if (scores[clientId][roundBonus] == false) {
			// Stops us from sending multiple messages to players because of TF2's funky round events.
			scores[clientId][roundBonus] = true;
			
			if (scores[clientId][exempt] == false && playerCount >= GetConVarInt(playerMinimum) && GetConVarFloat(rewardRoundBonus) > 0.0) {
				if (GetConVarFloat(rewardRBMin) > 0.0)
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundbonus_latenotifyminimum", clientId, GetConVarFloat(rewardRBMin));
				else	
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundbonus_latenotify", clientId);
			}
		}
	}
	
	#if defined PLUGIN_DEBUG
		PrintToServer("%s All late clients were just notified of the round bonus eligibility.", PLUGIN_PREFIX_PLAIN);
	#endif
	
	return Plugin_Continue;
}

// Displays scores and hands out round bonuses for those flagged previously by OnRoundStart or OnRoundSetupEnded.
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	HUD_SetStyle_RoundEnd();
	roundEnded = true;
	for(new clientId = 1; clientId <= MaxClients; clientId++) {
		// If client ID points to a non-existent client, or that client isn't eligible for points, do nothing.
		if (IsClientInGame(clientId) == false || scores[clientId][exempt] == true)
			continue;
		
		HUD_Draw(clientId);
		
		// If client is eligible for the round bonus.
		if (scores[clientId][roundBonus] == true) {
			// If round bonus points aren't disabled and the client scored enough points..
			new Float:roundBonusReward = GetConVarFloat(rewardRoundBonus);
			
			if (roundBonusReward > 0.0 && scores[clientId][roundPoints] >= GetConVarFloat(rewardRBMin)) {				
				// Reward those players.
				Reward(clientId, roundBonusReward);
				scores[clientId][roundsPlayed]++;
				if (playerCount >= GetConVarInt(playerMinimum))
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundbonus_received", clientId, roundBonusReward);
			}
		}
		
		if (scores[clientId][roundPoints] > 0.0)
			CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundend_roundpoints", clientId, scores[clientId][roundPoints]);
		
		// The user isn't new to this ranking system.
		if (scores[clientId][rank] != 0) {
			CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_roundend_totalpoints", clientId, scores[clientId][points]);
		}

		// Flag them as not eligible for round bonus, so they can be notified on the next round.
		scores[clientId][roundBonus] = false;
	}
}

// Event fires when a player is teleported via an engineer's teleporter.
public Action:OnPlayerTeleported(Handle:event, const String:name[], bool:dontBroadcast) {
	// Not enough players on the server. No scoring tracked.
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	new builderId = GetClientOfUserId(GetEventInt(event, "builderid"));
	new teleportedId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Stop engineers from earning points for teleporting theirselves.
	if (builderId == WORLD || builderId == teleportedId || scores[builderId][exempt] == true || scores[teleportedId][exempt] == true) {
		return Plugin_Continue;
	}
	
	
	#if defined PLUGIN_DEBUG
		new String:builderName[MAX_NAME_LENGTH];
		GetClientName(builderId, builderName, MAX_NAME_LENGTH);
		
		new String:clientName[MAX_NAME_LENGTH];
		GetClientName(teleportedId, clientName, MAX_NAME_LENGTH);
		
		PrintToServer("%s %s was rewarded %.2f points for teleporting %s.", PLUGIN_PREFIX_PLAIN, builderName, GetConVarFloat(rewardPlayerTele), clientName);
	#endif
	
	new Float:playerTeleReward = GetConVarFloat(rewardPlayerTele);
	
	if (playerTeleReward > 0.0) {
		if (GetConVarInt(userNotificationLvl) >= NOTIFICATION_TELEPORTS) {
			CPrintToChat(builderId, "%s %T", PLUGIN_PREFIX, "pr_notify_teleport", builderId, playerTeleReward);
		}
		
		Reward(builderId, playerTeleReward);
	}
	
	return Plugin_Continue;
}
// Handles scoring of engineer buildables being destroyed, actively not rewarding for sapper destructions because those are just too spammable.
public Action:OnObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast) {
		// Not enough players on the server. No scoring tracked.
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	if (GetEventInt(event, "attacker") == WORLD)
		return Plugin_Continue;
	
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker")); 	  	   // Our attacker.
	
	if (scores[attackerId][exempt] == true)
		return Plugin_Continue;
	
	new buildingId = GetEventInt(event, "index"); 						      	   // Our building's index.
	new buildingType = GetEventInt(event, "objecttype"); 					  	   // Our building type.
	new buildingLevel = GetEntProp(buildingId, Prop_Send, "m_iUpgradeLevel"); 	   // Our building level.
	new bool:IsMini = (GetEntProp(buildingId, Prop_Send, "m_bMiniBuilding") == 1); // True if mini sentry;
	new Float:pointReward;

	if (buildingType == _:TFObject_Dispenser)
		pointReward = GetConVarFloat(rewardDispenser);
	else if (buildingType == _:TFObject_Teleporter)
		pointReward = GetConVarFloat(rewardTeleporter);
	else if (buildingType == _:TFObject_Sentry) {
		if (IsMini)
			pointReward = GetConVarFloat(rewardMiniSentry);
		else
			pointReward = GetConVarFloat(rewardSentry);
	}
	
	if (pointReward == 0.0)
		return Plugin_Continue;
	
	new builder = GetEntPropEnt(buildingId,  Prop_Send, "m_hBuilder");
	
	if ((builder > 0 && builder <= MaxClients) && scores[builder][exempt] == true)
		return Plugin_Continue;
	
	// Mini sentry is exempt from this multiplier check.
	if (IsMini == false) {
		if (buildingLevel == 1)
			pointReward *= GetConVarFloat(rewardLevel1Mult);
		else if (buildingLevel == 2)
			pointReward *= GetConVarFloat(rewardLevel2Mult);
		else if (buildingLevel == 3)
			pointReward *= GetConVarFloat(rewardLevel3Mult);
	}
	
	
	#if defined PLUGIN_DEBUG
		new String:attackerName[MAX_NAME_LENGTH];
		GetClientName(attackerId, attackerName, MAX_NAME_LENGTH);
		
		if (buildingType == _:TFObject_Dispenser)
			PrintToServer("%s %s destroyed a dispenser and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, pointReward);	
		else if (buildingType == _:TFObject_Teleporter)
			PrintToServer("%s %s destroyed a teleporter and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, pointReward);
		else if (buildingType == _:TFObject_Sentry) {
			if (IsMini)
				PrintToServer("%s %s destroyed a mini sentry and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, pointReward);
			else
				PrintToServer("%s %s destroyed a sentry and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, pointReward);
		}
	#endif
	
	if (GetConVarInt(userNotificationLvl) >= NOTIFICATION_KILLS) {
		if (buildingType == _:TFObject_Dispenser) {
			CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_dispenser", attackerId, pointReward, buildingLevel);
		}
		else if (buildingType == _:TFObject_Teleporter)
			CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_teleporter", attackerId, pointReward, buildingLevel);
		else if (buildingType == _:TFObject_Sentry) {
			if (IsMini)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_minisentry", attackerId, pointReward);
			else
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_sentry", attackerId, pointReward, buildingLevel);
		}
	}
	
	Reward(attackerId, pointReward);
	return Plugin_Continue;
}

// Handles scoring of kills and assists, minus dead ringer's feign death. I caught this in testing.
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {	
	// Not enough players on the server. No scoring tracked. OR our detective ruled that the death was only a tragic accident. The victim probably fell off of a building.
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	new bool:allowBots = GetConVarBool(allowBotStats);

	// Our detective is looking into who might have been there at the murder.
	new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (scores[attackerId][exempt] == true || scores[victimId][exempt] == true)
		return Plugin_Continue;
	
	// Our detective has reason to believe the victim may have been a robot.
	new bool:victimIsBot = IsFakeClient(victimId);
	
	// If bots aren't allowed to count for scoring, ignore the event.
	if ((victimIsBot && allowBots == false) || attackerId == WORLD) {
		new bool:victimFeigned = bool:(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER);
		
		if (victimFeigned == false) {
			scores[victimId][currentStreak] = 0;	
		}
		
		return Plugin_Continue;
	}
	
	if (GetConVarBool(hudOnDeath) == true) {
		HUD_Draw(victimId, true);
	}
	
	// Our detective found that the death was from a prominent world figure.
	new bool:victimIsAdmin;
	
	if (GetConVarFloat(rewardAdminKill) > 0.0) {
		victimIsAdmin = (victimIsBot == false ? CheckCommandAccess(victimId, "pr_killadminreward", ADMFLAG_ROOT) : false);	
	}
	
	// Our detective found that the death was feigned, the body dropped was merely a dummy with ketchup.
	new bool:victimFeigned = false;
	
	// Our detective is looking to see if someone assisted in the murder.
	new assisterId = GetClientOfUserId(GetEventInt(event, "assister"));
	
	// Custom kill flags, used for checking death details in TF2
	new customKill;
	
	if (isTF2 == true) {
		customKill = GetEventInt(event, "customkill");
		
		victimFeigned = bool:(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER);
		
		if (victimFeigned == false) {
			new deathFlags = GetEventInt(event, "death_flags");
			
			if (deathFlags & TF_DEATHFLAG_KILLERDOMINATION) {
				scores[victimId][dominationsBad]++;
				scores[attackerId][dominationsGood]++;
			}
			
			if (deathFlags & TF_DEATHFLAG_ASSISTERDOMINATION) {
				scores[victimId][dominationsBad]++;
				scores[assisterId][dominationsGood]++;
			}
		}
	}
	
	// Could it have been a suicide?
	if (victimId == attackerId) {
		if (victimFeigned == false) {
			scores[victimId][currentStreak] = 0;
		}
		return Plugin_Continue; // Suicide gets a person nowhere. No points are given.
	}
	
	// Our reward amount, the killer will receive the whole point amount, if there's an assister they will receive a 
	// fraction of this point amount as defined by CVAR rewardAssistMult.
	new Float:pointReward;
	new bool:deflection = false;
	
	// Our detective states that the murder victim was some sort of AI. A bot.
	if (victimIsBot)
		pointReward = GetConVarFloat(rewardBotKill);
	else if (victimIsAdmin) {
		pointReward = GetConVarFloat(rewardAdminKill);
	}
	else
		pointReward = GetConVarFloat(rewardPlayerKill);
	
	if (isTF2 == true) {
		// If the cause of death was by a headshot then we need to add our headshot multiplier.
		if (customKill == TF_CUSTOM_HEADSHOT || customKill == TF_CUSTOM_HEADSHOT_DECAPITATION)
		{
			pointReward *= GetConVarFloat(rewardHeadshotMult);
			
			if (victimFeigned == false)
				scores[attackerId][headshots]++;
		}
		else if (customKill == TF_CUSTOM_BACKSTAB) // If the cause of death was by a backstab then we need to add our backstab multiplier.
		{
			pointReward *= GetConVarFloat(rewardBackstabMult);
			
			if (victimFeigned == false)
				scores[attackerId][backstabs]++;
		}
		else {
			new String:weapon[9];
			GetEventString(event, "weapon", weapon, 9);
			deflection = StrEqual(weapon, "deflect_");
			
			if (deflection == true) {
				if (victimFeigned == false)
					scores[attackerId][deflects]++;
			
				pointReward *= GetConVarFloat(rewardDeflectMult);
			}
		}
	}
	
	if (victimFeigned == false) {
		scores[attackerId][currentStreak]++;
		
		if (scores[attackerId][currentStreak] > scores[attackerId][highestStreak]) {
			scores[attackerId][highestStreak]++;
		}
		
		new Float:killstreakReward = 		GetConVarFloat(rewardKS);
		new Float:killstreakRewardMax = 	GetConVarFloat(rewardKSMax);
		
		if (scores[victimId][currentStreak] > 0 && killstreakReward > 0.0) {
			if (killstreakRewardMax != 0.0)
				pointReward += scores[victimId][currentStreak] * (killstreakReward > killstreakRewardMax ? killstreakRewardMax : killstreakReward);
			else
				pointReward += scores[victimId][currentStreak] * killstreakReward;
		}
		
		scores[victimId][currentStreak] = 0;
		
		// Reward the murderer.
		new pointLoss = GetConVarInt(pointLossMode);
		
		if (pointLoss == 1)
			Revoke(victimId, 1.0);
		else if (pointLoss == 2)
			Revoke(victimId, pointReward);
		
		scores[victimId][deaths]++; 	// Victim gets a death.
		scores[attackerId][kills]++;	// Attacker gets a kill.
		Reward(attackerId, pointReward);// Reward attacker.
	}
	else {
		scores[victimId][feigns]++;
		
		// Draw the HUD "as if they earned points"
		HUD_Draw(attackerId);
	}
	
	if (IsFakeClient(attackerId) == false && GetConVarInt(userNotificationLvl) >= NOTIFICATION_KILLS && pointReward > 0.0) {
		if (customKill == TF_CUSTOM_HEADSHOT || customKill == TF_CUSTOM_HEADSHOT_DECAPITATION) {
			if (victimIsBot)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_bot_headshot", attackerId, pointReward);
			else if (victimIsAdmin)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_admin_headshot", attackerId, pointReward);
			else
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_player_headshot", attackerId, pointReward);
		}
		else if (customKill == TF_CUSTOM_BACKSTAB) {
			if (victimIsBot)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_bot_backstab", attackerId, pointReward);
			else if (victimIsAdmin)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_admin_backstab", attackerId, pointReward);
			else
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_player_backstab", attackerId, pointReward);
		}
		else if (deflection == true) {
			if (victimIsBot)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_bot_deflect", attackerId, pointReward);
			else if (victimIsAdmin)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_admin_deflect", attackerId, pointReward);
			else
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_player_deflect", attackerId, pointReward);
		}
		else {
			if (victimIsBot)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_bot", attackerId, pointReward);
			else if (victimIsAdmin)
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_admin", attackerId, pointReward);
			else
				CPrintToChat(attackerId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_player", attackerId, pointReward);
		}
	}
	
	// Reward the assistant a fraction if there was one.
	if (assisterId != WORLD) {
		new Float:pointRewardAssist = pointReward * GetConVarFloat(rewardAssistMult);
		
		if (victimFeigned == false) {
			Reward(assisterId, pointRewardAssist);
			scores[assisterId][assists]++;// Assister gets assist.
		}
		else {
			// Draw the HUD "as if they earned points"
			HUD_Draw(assisterId);
		}
		
		if (IsFakeClient(assisterId) == false && GetConVarInt(userNotificationLvl) >= NOTIFICATION_KILLS && pointRewardAssist > 0.0) {
			if (victimIsBot)
				CPrintToChat(assisterId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_assist_bot", assisterId, pointRewardAssist);
			else if (victimIsAdmin)
				CPrintToChat(assisterId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_assist_admin", assisterId, pointRewardAssist);
			else
				CPrintToChat(assisterId, "%s %T", PLUGIN_PREFIX, "pr_notify_kill_assist_player", assisterId, pointRewardAssist);
		}
	}

	#if defined PLUGIN_DEBUG
		new String:victimName[MAX_NAME_LENGTH];
		GetClientName(victimId, victimName, MAX_NAME_LENGTH);
		
		new String:attackerName[MAX_NAME_LENGTH];
		GetClientName(attackerId, attackerName, MAX_NAME_LENGTH);
		
		if (customKill == TF_CUSTOM_HEADSHOT || customKill == TF_CUSTOM_HEADSHOT_DECAPITATION) {
			PrintToServer("%s %s killed %s with a headshot and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, victimName, pointReward);
		}
		else if (customKill == TF_CUSTOM_BACKSTAB) {
			PrintToServer("%s %s killed %s with a backstab and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, victimName, pointReward);
		}
		else if (deflection == true) {
			PrintToServer("%s %s killed %s with a deflection and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, victimName, pointReward);
		}
		else
			PrintToServer("%s %s killed %s and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, attackerName, victimName, pointReward);
		
		if (assisterId != WORLD) {
			new String:assisterName[MAX_NAME_LENGTH];
			GetClientName(assisterId, assisterName, MAX_NAME_LENGTH);
			PrintToServer("%s %s assisted %s in killing %s and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, assisterName, attackerName, victimName, pointReward * GetConVarFloat(rewardAssistMult));
		}
	#endif
	
	return Plugin_Continue;
}
//////////////////////////////////////
//  CP EVENTS
//////////////////////////////////////
// Hands rewards out to those that stood on the point during its time of capture.
public Action:OnPointCaptured(Handle:event, const String:name[], bool:dontBroadcast) {
	// Not enough players on the server. No scoring tracked.
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	new String:cappers[128];
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	new capperLength = strlen(cappers);
	for (new I = 0; I < capperLength; I++)
	{
		new clientId = cappers{I};
		
		if (scores[clientId][exempt] == true)
			continue;
		
		#if defined PLUGIN_DEBUG
			new String:clientName[MAX_NAME_LENGTH];
			GetClientName(clientId, clientName, MAX_NAME_LENGTH);
			PrintToServer("%s %s captured a point and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, clientName, GetConVarFloat(rewardCapCapture));
		#endif
		scores[clientId][capCaptures]++;
		
		new Float:capCaptureReward = GetConVarFloat(rewardCapCapture);
	
		if (capCaptureReward > 0.0) {
			if (GetConVarInt(userNotificationLvl) >= NOTIFICATION_OBJECTIVES) {
				CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_notify_capture_point", clientId, capCaptureReward);
			}
			
			Reward(clientId, capCaptureReward);
		}
	}
	
	return Plugin_Continue;
}
// Hands rewards out to players who defend the cap point.
public Action:OnPointDefended(Handle:event, const String:name[], bool:dontBroadcast) {
	// Not enough players on the server. No scoring tracked.
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	new clientId = GetEventInt(event, "blocker");
	
	if (clientId == WORLD) // No blocker? Somehow this does happen.
		return Plugin_Continue;
	
	if (scores[clientId][exempt] == true)
		return Plugin_Continue;
	
	if (GetTime() - scores[clientId][lastDefend] < GetConVarInt(rewardDefendCooldown))
		return Plugin_Continue;
	
	#if defined PLUGIN_DEBUG
		new String:clientName[MAX_NAME_LENGTH];
		GetClientName(clientId, clientName, MAX_NAME_LENGTH);
		PrintToServer("%s %s defended a point and was rewarded %.2f points.", PLUGIN_PREFIX_PLAIN, clientName, GetConVarFloat(rewardCapDefense));
	#endif
	
	new Float:capDefenseReward = GetConVarFloat(rewardCapDefense);
	
	if (capDefenseReward > 0.0) {
		if (GetConVarInt(userNotificationLvl) >= NOTIFICATION_OBJECTIVES) {
			CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_notify_defend_point", clientId, capDefenseReward);
		}
		Reward(clientId, capDefenseReward);
	}
	
	scores[clientId][lastDefend] = GetTime();
	scores[clientId][capDefends]++;
		
	return Plugin_Continue;
}
//////////////////////////////////////
//  CTF EVENTS
//////////////////////////////////////
// Called when the flag state is changed.
public Action:OnFlagState(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	new clientId = GetEventInt(event, "player");
	
	if (scores[clientId][exempt] == true)
		return Plugin_Continue;
	
	if (GetEventInt(event, "eventtype") == TF_FLAGEVENT_CAPTURED) {
		scores[clientId][flagCaptures]++;
		new Float:flagCaptureReward = GetConVarFloat(rewardFlagCapture);
		
		if (flagCaptureReward > 0.0) {
			if (GetConVarInt(userNotificationLvl) >= NOTIFICATION_OBJECTIVES) {
				CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_notify_capture_flag", clientId, flagCaptureReward);
			}
			Reward(clientId, GetConVarFloat(rewardFlagCapture));
		}
	}
	else if (GetEventInt(event, "eventtype") == TF_FLAGEVENT_DEFENDED) {
		scores[clientId][flagDefends]++;
		new Float:flagDefendReward = GetConVarFloat(rewardFlagDefend);
		
		if (flagDefendReward > 0.0) {
			if (GetConVarInt(userNotificationLvl) >= NOTIFICATION_OBJECTIVES) {
				CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_notify_defend_flag", clientId, flagDefendReward);
			}
			Reward(clientId, GetConVarFloat(rewardFlagDefend));
		}
	}
	
	return Plugin_Continue;
}

//////////////////////////////////////
//  BOSS EVENTS
//////////////////////////////////////
// Happens when an NPC is damaged by a player.
public Action:OnNPCDamaged(Handle:event, const String:name[], bool:dontBroadcast) {
	if (bossIndex == GetEventInt(event, "entindex")) {
		new attackerId = GetClientOfUserId(GetEventInt(event, "attacker_player"));
		scores[attackerId][bossdmg] += GetEventInt(event, "damageamount");
	}
}
// Happens when the boss gets bored of hanging around and decides to leave.
public Action:OnBossLeave(Handle:event, const String:name[], bool:dontBroadcast) {
	bossIndex = -1;
	for (new clientid = 1; clientid <= MaxClients; clientid++) {
		scores[clientid][bossdmg] = 0;
	}
}
// Notifies all clients of the score they *could* receive when the Horsemann spawns.
public Action:OnHeadlessHorsemannSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	bossIndex = FindEntityByClassname(-1, "headless_hatman");
	
	if (IsValidEntity(bossIndex)) {
		new Float:reward = GetConVarFloat(rewardHHHKill);
		
		if (reward == 0.0) {
			bossIndex = -1;
			return Plugin_Continue;
		}
		
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_boss_spawned", "Horseless Headless Horsemann", reward);
	}
	return Plugin_Continue;
}

// Notifies all clients of the score they *could* receive when Merasmus spawns.
public Action:OnMerasmusSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	bossIndex = FindEntityByClassname(-1, "merasmus");
	
	if (IsValidEntity(bossIndex)) {
		new Float:baseReward = GetConVarFloat(rewardMerasmusKill);
		new Float:levelBase = GetConVarFloat(rewardMultBase);
		new Float:levelMult = GetConVarFloat(rewardMerasmusMult);
		new level = GetEventInt(event, "level");
		new Float:calculatedReward = (level - 1) * (levelBase + ((level - 1) * levelMult)) + baseReward;

		if (baseReward == 0.0) {
			bossIndex = -1;
			return Plugin_Continue;
		}
		
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_boss_spawned", "Merasmus", calculatedReward);
	}
	
	return Plugin_Continue;
}

// Notifies all clients of the score they *could* receive when the Monoculus spawns.
public Action:OnMonoculusSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	bossIndex = FindEntityByClassname(-1, "eyeball_boss");
	
	if (IsValidEntity(bossIndex)) {
		new Float:baseReward = GetConVarFloat(rewardMonoculusKill);
		new Float:levelBase = GetConVarFloat(rewardMultBase);
		new Float:levelMult = GetConVarFloat(rewardMonoculusMult);
		new level = GetEventInt(event, "level");
		new Float:calculatedReward = (level - 1) * (levelBase + ((level - 1) * levelMult)) + baseReward;
		
		if (baseReward == 0.0) {
			bossIndex = -1;
			return Plugin_Continue;
		}
		
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_boss_spawned", "Monoculus", calculatedReward);
	}
	return Plugin_Continue;
}
// Rewards score to eligible players when the Headless Horsemann is killed.
public Action:OnHeadlessHorsemannKilled(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	if (bossIndex != -1 && IsValidEntity(bossIndex)) {
		new Float:reward = GetConVarFloat(rewardHHHKill);
		
		if (reward == 0.0) // Rewarding is disabled for this boss.
			return Plugin_Continue;
		
		for (new clientId = 1; clientId <= MaxClients; clientId++) {
			if (IsClientInGame(clientId) == true && scores[clientId][exempt] == false && scores[clientId][bossdmg] >= GetConVarInt(rewardBossDmgMin)) {
				scores[clientId][hhhKills]++;
				
				if (reward > 0.0) {
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_boss_killed", clientId, reward, "Horseless Headless Horsemann");
					Reward(clientId, reward);
				}
			}
			scores[clientId][bossdmg] = 0;
		}
	}
	
	bossIndex = -1;
	return Plugin_Continue;
}
// Rewards score to eligible players when Merasmus is killed.
public Action:OnMerasmusKilled(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	if (bossIndex != -1 && IsValidEntity(bossIndex)) {
		new Float:baseReward = GetConVarFloat(rewardMerasmusKill);
		new Float:levelBase = GetConVarFloat(rewardMultBase);
		new Float:levelMult = GetConVarFloat(rewardMerasmusMult);
		new level = GetEventInt(event, "level");
		new Float:calculatedReward = (level - 1) * (levelBase + ((level - 1) * levelMult)) + baseReward;
		
		if (calculatedReward == 0.0) // Rewarding is disabled for this boss.
			return Plugin_Continue;
		
		for (new clientId = 1; clientId <= MaxClients; clientId++) {
			if (IsClientInGame(clientId) == true && scores[clientId][exempt] == false && scores[clientId][bossdmg] >= GetConVarInt(rewardBossDmgMin)) {
				scores[clientId][merKills]++;
				
				if (level > scores[clientId][merLvl])
					scores[clientId][merLvl] = level;
				
				if (baseReward > 0.0) {
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_boss_killed", clientId, calculatedReward, "Merasmus");
					Reward(clientId, calculatedReward);
				}
			}
			scores[clientId][bossdmg] = 0;
		}
	}
	
	bossIndex = -1;
	return Plugin_Continue;
}
// Rewards score to eligible players when Monoculus is killed.
public Action:OnMonoculusKilled(Handle:event, const String:name[], bool:dontBroadcast) {
	if (playerCount < GetConVarInt(playerMinimum))
		return Plugin_Continue;
	
	if (bossIndex != -1 && IsValidEntity(bossIndex)) {
		new Float:baseReward = GetConVarFloat(rewardMonoculusKill);
		new Float:levelBase = GetConVarFloat(rewardMultBase);
		new Float:levelMult = GetConVarFloat(rewardMonoculusMult);
		new level = GetEventInt(event, "level");
		new Float:calculatedReward = (level - 1) * (levelBase + ((level - 1) * levelMult)) + baseReward;
		
		if (calculatedReward == 0.0) // Rewarding is disabled for this boss.
			return Plugin_Continue;
		
		for (new clientId = 1; clientId <= MaxClients; clientId++) {
			if (IsClientInGame(clientId) == true && scores[clientId][exempt] == false && scores[clientId][bossdmg] >= GetConVarInt(rewardBossDmgMin)) {
				scores[clientId][monKills]++;
				
				if (level > scores[clientId][monLvl])
					scores[clientId][monLvl] = level;
				
				if (baseReward > 0.0) {
					Reward(clientId, calculatedReward);
					CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_boss_killed", clientId, calculatedReward, "Monoculus");
				}
			}
			scores[clientId][bossdmg] = 0;
		}
	}
	
	bossIndex = -1;
	return Plugin_Continue;
}

//////////////////////////////////////
//  METHODS
//////////////////////////////////////
// Makes a connection to the SQL server, creates the database if it doesn't exist and makes a connection. Either way it makes a connection, wanna fight about it?
Initialize() {
	// Check if connection data has been found.
	if (SQL_CheckConfig("playerranks") == true) {
		#if defined PLUGIN_DEBUG
			LogMessage("Database config for Player Ranks detected.");
			LogMessage("Attempting to establish connection with the server.");
			
			PrintToServer("%s Database config for Player Ranks detected.", PLUGIN_PREFIX_PLAIN);
			PrintToServer("%s Attempting to establish connection with the server.", PLUGIN_PREFIX_PLAIN);
		#endif
		GetSQLDriver();
		SQL_TConnect(Query_Connect, "playerranks");
	}
	else {
		#if defined PLUGIN_DEBUG
			LogMessage("Database config for Player Ranks was not detected.");
			LogMessage("Attempting to establish connection through SQLite.");
			
			PrintToServer("%s Database config for Player Ranks was not detected.", PLUGIN_PREFIX_PLAIN);
			PrintToServer("%s Attempting to establish connection through SQLite.", PLUGIN_PREFIX_PLAIN);
		#endif
		new Handle:config = CreateKeyValues("");
		KvSetString(config, "driver", "sqlite");
		KvSetString(config, "database", "playerranks");
		
		isSQLite = true;
		
		new String:error[256];
		connection = SQL_ConnectCustom(config, error, sizeof(error), false);
		CloseHandle(config);
		
		if (connection == INVALID_HANDLE) {
			LogError("Connection to the database failed with error: %s", error);
			PrintToServer("%s Connection to the database failed with error: %s", PLUGIN_PREFIX_PLAIN, error);
			SetFailState("Connection to the database has failed. View the log for more information. %s", PLUGIN_VERSION);
		}
		else {
			// Create the table if it does not exist.
			SQL_TQuery(connection, Query_CreateTable, SQL_CREATETABLE);	
		}
		
		PrintToServer("%s Connection to SQLite was successful.", PLUGIN_PREFIX_PLAIN);
	}
}
// Gets the SQL driver that is in use, mysql or sqlite.
GetSQLDriver() {
	new String:dbConfig[256];
	BuildPath(Path_SM, dbConfig, sizeof(dbConfig), "configs/databases.cfg");
	
	new Handle:configKeys = CreateKeyValues("playerranks");
	FileToKeyValues(configKeys, dbConfig);
	
	if (KvJumpToKey(configKeys, "playerranks") == false) {
		isSQLite = true;
		CloseHandle(configKeys);
	}
	else {
		new String:sqlDriver[16];
		KvGetString(configKeys, "driver", sqlDriver, sizeof(sqlDriver));
		CloseHandle(configKeys);
		
		isSQLite = !StrEqual(sqlDriver, "mysql", false);
	}
}
// Runs a query chain on MySQL/SQLite, breaks the semicolons and runs all queries seperately for compatibility with SQLite.
UpdateDatabase(const String:query[2048], version) {
	new String:Queries[32][512];
	ExplodeString(query, ";", Queries, sizeof(Queries), sizeof(Queries[]));
	
	new I = 0;
	
	while(strlen(Queries[I]) > 0) {
		LogMessage("Executing: %s for update %i.", Queries[I], version);
		SQL_TQuery(connection, Query_Update, Queries[I], version);
		I++;
	}
	
	new String:versionQuery[128];
	Format(versionQuery, sizeof(versionQuery), SQL_SETVERSION, version);
	
	SQL_TQuery(connection, Query_SetVersion, versionQuery, version);
	SQL_TQuery(connection, Query_UpdateCheck, SQL_GETVERSION);
	PrintToServer("%s The database updated to version %i successfully.", PLUGIN_PREFIX_PLAIN, version);
}
// This is similiar to UpdateDatabase except instead of performing any update query it emulates a successful update. Used for skipping certain updates.
ForceDatabaseVersion(version) {
	new String:versionQuery[128];
	Format(versionQuery, sizeof(versionQuery), SQL_SETVERSION, version);
	
	SQL_TQuery(connection, Query_SetVersion, versionQuery, version);
	SQL_TQuery(connection, Query_UpdateCheck, SQL_GETVERSION);
	PrintToServer("%s The database updated to version %i successfully.", PLUGIN_PREFIX_PLAIN, version);
}
// This is fired when the plugin loads, but is really only useful if the plugin was started while the server was running.
FinishInit() {	
	HookConVarChange(rankResetMode,				 OnResetModeChanged);
	// Get record count of the database.
	SQL_TQuery(connection, Query_GetRecordCount, SQL_GETRECORDCOUNT);
	
	// Get top players players on the server.
	new String:query[255];
	Format(query, sizeof(query), SQL_GETTOPPLAYERS, MAX_TOP_SCORES);
	
	SQL_TQuery(connection, Query_TopPlayers, 				  query);
	
	if (GetConVarInt(rankResetMode) == RESETMODE_DISABLED) {
		isReady = true;
		FinishLateInit();
	}
	else {
		PerformAutoReset();
	}
	
	if (GetConVarInt(cleanupMode) == 1) {
		RunCleanup(-1);
	}
		
	new Handle:serverTags = FindConVar("sv_tags");
	
	if (serverTags != INVALID_HANDLE) {
		new String:tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if (StrContains(tags, PLUGIN_TAG, false) == -1)
		{
			new String:newTags[512];
			Format(newTags, sizeof(newTags), "%s,%s", tags, PLUGIN_TAG);
			SetConVarString(serverTags, newTags);
		}
	}
	
	if (isSQLite == true)
		PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_db_connected", LANG_SERVER, "SQLite");
	else
		PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_db_connected", LANG_SERVER, "MySQL");
}

FinishLateInit() {
	if (GetConVarInt(cleanupMode) == 2)
	{
		cleanupTimer = CreateTimer(GetConVarFloat(cleanupInterval) * 60, CleanupTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 
		#if defined PLUGIN_DEBUG
		{
			LogMessage("Cleanup timer is enabled, Timer spawned.");
			PrintToServer("%s Cleanup timer is enabled, Timer spawned.", PLUGIN_PREFIX_PLAIN);
		}
		#endif
	}	
	#if defined PLUGIN_DEBUG
	else {
		LogMessage("Cleanup timer is disabled.");
		PrintToServer("%s Cleanup timer is disabled.", PLUGIN_PREFIX_PLAIN);
	}
	#endif
		
	HookConVarChange(cleanupInterval, OnCleanupIntervalChanged);
	
	updateTimer = CreateTimer(float(GetConVarInt(updateInterval)), Updater, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 
	HookConVarChange(updateInterval, OnUpdaterIntervalChanged);
	
	for (new clientId = 1; clientId <= MaxClients; clientId++) {
		if (IsClientAuthorized(clientId) == false) {
			continue;
		}
		LoadClientRecord(clientId, true);
	}
	
	UpdatePlayerCount();
	
	if (playerCount > 0)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_loaded");
}

// Checks if the client is a bot, or if their score is high enough.
bool:IsClientEligible(clientId) {
	return !(IsClientConnected(clientId) == false || scores[clientId][loaded] == false || clientId == WORLD || IsFakeClient(clientId) || (scores[clientId][rank] == 0 ? (scores[clientId][points] < GetConVarFloat(pluginThreshold)) : false) || scores[clientId][exempt] == true);	
}
// Cleans up old server records. Checks all currently connected players and loads their ranks up appropriately.
RunCleanup(issuerId) {
	new updateTime = GetTime() - (GetConVarInt(expireTime) * 86400);
	new String:Query[256];
	Format(Query, sizeof(Query), SQL_PURGEOLD, updateTime);
	if (connection == INVALID_HANDLE)
		return;
	
	SQL_TQuery(connection, Query_Cleanup, Query, issuerId, DBPrio_Low);	
}
// Clears the client information.
PurgeClient(clientId, bool:resetOnly = false) {
	scores[clientId][roundPoints] =   0.0;
	scores[clientId][totaltime] = 	    0;
	scores[clientId][points] = 		  0.0;
	scores[clientId][rank] = 			0;
	scores[clientId][kills] = 			0;
	scores[clientId][deaths] = 			0;
	scores[clientId][assists] = 		0;
	scores[clientId][backstabs] = 		0;
	scores[clientId][headshots] = 		0;
	scores[clientId][feigns] = 			0;
	scores[clientId][bossdmg] = 		0;
	scores[clientId][merKills] = 		0;
	scores[clientId][merLvl] = 			0;
	scores[clientId][monKills] = 		0;
	scores[clientId][monLvl] = 			0;
	scores[clientId][hhhKills] = 		0;
	scores[clientId][flagCaptures] = 	0;
	scores[clientId][flagDefends] = 	0;
	scores[clientId][capCaptures] = 	0;
	scores[clientId][capDefends] = 		0;
	scores[clientId][roundsPlayed] = 	0;
	scores[clientId][dominationsGood] = 0;
	scores[clientId][dominationsBad] = 	0;
	scores[clientId][deflects] = 		0;
	scores[clientId][currentStreak] = 	0;
	scores[clientId][highestStreak] = 	0;
	scores[clientId][lastDefend] =		0;
	scores[clientId][exempt] =		false;
	
	if (resetOnly == false) {
		scores[clientId][validated] =			false;
		scores[clientId][roundBonus] = 			false;
		scores[clientId][loaded] = 				false;
		scores[clientId][jointime] = 	  		0;
	}
	else {
		scores[clientId][loaded] = 				(clientId != WORLD && IsClientConnected(clientId));
		scores[clientId][jointime] = 	  		GetTime();
	}
}
// Saves all clients.
ForceSave() {
	for(new clientId = 1; clientId <= MaxClients; clientId++) {
		if (IsClientEligible(clientId) == false)
			continue;
		
		// Get the client's name.
		new String:playerName[MAX_NAME_LENGTH];
		GetClientName(clientId, playerName, MAX_NAME_LENGTH);
		
		new String:playerSteamID[MAX_STEAMID_LENGTH];
		GetClientAuthId(clientId, AuthId_Steam2, playerSteamID, MAX_STEAMID_LENGTH);
		
		SaveScore(clientId, playerName, playerSteamID);
	}	
}
// Saves the last client and restarts the server.
SaveScore(clientID, const String:clientName[], const String:playerSteamID[], saveType = SAVEMODE_REGULAR) {
	new String:playerName[MAX_NAME_LENGTH];
	SQL_EscapeString(connection, clientName, playerName, MAX_NAME_LENGTH * 2);

	new String:Query[2048];
	Format(Query, sizeof(Query), 
	SQL_SAVERECORD, 
	playerSteamID,
	playerName,
	scores[clientID][points],
	GetTime(),
	scores[clientID][deaths], 
	scores[clientID][kills], 
	scores[clientID][assists], 
	scores[clientID][backstabs], 
	scores[clientID][headshots],
	scores[clientID][feigns], 
	scores[clientID][merKills], 
	scores[clientID][merLvl], 
	scores[clientID][monKills], 
	scores[clientID][monLvl], 
	scores[clientID][hhhKills], 
	GetTimePlayed(clientID),
	scores[clientID][flagCaptures],
	scores[clientID][flagDefends],
	scores[clientID][capCaptures],
	scores[clientID][capDefends],
	scores[clientID][roundsPlayed],
	scores[clientID][dominationsGood],
	scores[clientID][dominationsBad],
	scores[clientID][deflects],
	scores[clientID][highestStreak]);
	
	new Handle:dataPack = CreateDataPack();
	
	WritePackCell(dataPack, saveType);
	WritePackCell(dataPack, clientID);
	
	SQL_TQuery(connection, Query_SaveUserRecord, Query, dataPack);
}
// Returns a float with the player's TOTAL time online for every game session with playerranks.
Float:GetTimePlayed(clientId) {
	if (scores[clientId][validated] == false)
		return 0.0;
	
	return float((GetTime() - scores[clientId][jointime]) + scores[clientId][totaltime]);
}

// Performs both the checking and resetting of the database if needed, called on each map start.
PerformAutoReset() {
	if (GetConVarInt(rankResetMode) != RESETMODE_DISABLED)
		SQL_TQuery(connection, Query_ResetDatabase_S1, SQL_GETRESETDATE);
}
// Runs the appropriate query to clear the database, nullifies the top player listing and purges all connected clients.
ResetDatabase(issuerUId) {
	if (isSQLite == false)
		SQL_TQuery(connection, Query_ResetDatabase_S2, SQL_RESET_MYSQL, issuerUId, DBPrio_High);
	else
		SQL_TQuery(connection, Query_ResetDatabase_S2, SQL_RESET_SQLITE, issuerUId, DBPrio_High);
}

// Rewards a client the specified amount of points.
Reward(clientId, Float:amount, bool:forced = false) {
	// If an admin rewards points manually, forced is set to true, and player minimum rule and exemption rules are ignored.
	if (forced == false && playerCount < GetConVarInt(playerMinimum) && scores[clientId][exempt] == true)
		return;
	
	Call_StartForward(FORWARD_OnReward);
	Call_PushCell(clientId);
	Call_PushFloatRef(amount);
	Call_PushCell(forced);
	
	new Action:result;
	Call_Finish(result);
	
	if (result == Plugin_Handled)
		return;
	
	scores[clientId][roundPoints] += amount;
	scores[clientId][points] += amount;
	
	
	Call_StartForward(FORWARD_OnReward_Post);
	Call_PushCell(clientId);
	Call_PushFloat(amount);
	Call_PushCell(forced);
	Call_Finish();
	
	HUD_Draw(clientId);
}
// Revokes points from the client.
Revoke(clientId, Float:amount, bool:forced = false) {
	// If an admin rewards points manually, forced is set to true, and player minimum rule is ignored.
	if (forced == false && playerCount < GetConVarInt(playerMinimum) && scores[clientId][exempt] == true)
		return;
	
	scores[clientId][roundPoints] -= amount;
	
	if (scores[clientId][points] - amount < 0.0)
		scores[clientId][points] = 0.0;
	else
		scores[clientId][points] -= amount;
}
// Draws the HUD on the client's screen.
HUD_Draw(clientId, bool:deathHUD = false) {
	// If the client isn't human then how about we don't draw the hud but say we did?
	if (clientId == WORLD || IsFakeClient(clientId) || GetConVarBool(useHUD) == false)
		return;
	
	if (isTF2 == true) {
		if (roundEnded)
			HUD_SetStyle_RoundEnd();
		else if (deathHUD == true || (GetConVarBool(hudOnDeath) == true && IsPlayerAlive(clientId) == false))
			HUD_SetStyle_Dead();
		else {
			new TFClassType:class = TF2_GetPlayerClass(clientId);
			
			if (class == TFClass_Engineer || class == TFClass_Spy)
				HUD_SetStyle_Bumped();
			else
				HUD_SetStyle_Default();
		}
	}
	else {
		if (roundEnded)
			HUD_SetStyle_RoundEnd();
		else if (deathHUD == true || (GetConVarBool(hudOnDeath) == true && IsPlayerAlive(clientId) == false))
			HUD_SetStyle_Dead();
		else
			HUD_SetStyle_Default();
	}
	
	ClearSyncHud(clientId, roundHUD);
	ShowSyncHudText(clientId, roundHUD, "%T", "pr_hud_round_points", clientId, scores[clientId][roundPoints]);
}
// Default top-left drawing.
HUD_SetStyle_Default() {
	SetHudTextParams(0.02, 0.02, 4.0, 180, 180, 180, 255, 1, 8.0, 0.3, 2.5);	
}
// Bumps HUD next to engineer's building statuses, they take up the top left corner.
HUD_SetStyle_Bumped() {
	SetHudTextParams(0.16, 0.02, 4.0, 180, 180, 180, 255, 1, 8.0, 0.3, 2.5);	
}
// Centers HUD to screen.
HUD_SetStyle_RoundEnd() {
	SetHudTextParams(-1.0, 0.3, 4.0, 180, 180, 180, 255, 1, 12.5, 0.3, 2.5);	
}
// Centers HUD to screen.
HUD_SetStyle_Dead() {
	SetHudTextParams(-1.0, 0.2, 4.0, 180, 180, 180, 255, 1, 10.0, 0.3, 2.5);	
}
//////////////////////////////////////
//  CALLBACKS
//////////////////////////////////////
// Handles connection to the SQL database ONLY if the SQL details are configured in configs/databases.cfg, should only be called for MySQL.
public Query_Connect(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	connection = hndl;
	
	if (connection == INVALID_HANDLE) {
		LogError("Connection to the server failed with error %s.", error);
		PrintToServer("%s Connection to database failed with error %s.", PLUGIN_PREFIX_PLAIN, error);	
		SetFailState("Connection to the database failed. Check log for more information. %s", PLUGIN_VERSION);
	} 
	else {
		SQL_TQuery(connection, Query_EnableUTF8, 		SQL_ENABLEUTF8);
		// Create the database if it does not exist.
		SQL_TQuery(connection, Query_CreateTable, 		SQL_CREATETABLE);
		// Get record count of the database.
		SQL_TQuery(connection, Query_GetRecordCount, 	SQL_GETRECORDCOUNT);
		// Get top players on the server.
		new String:query[255];
		Format(query, sizeof(query), SQL_GETTOPPLAYERS, MAX_TOP_SCORES);
		
		SQL_TQuery(connection, Query_TopPlayers, 				  query);
	}
	
	#if defined PLUGIN_DEBUG
		LogMessage("Connection to the server was successful.");
		PrintToServer("%s Connection to the server was successful.", PLUGIN_PREFIX_PLAIN);
	#endif
}
// Called if the driver is MySQL. Sets the plugin to use UTF8 encoding.
public Query_EnableUTF8(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	#if defined PLUGIN_DEBUG
		LogMessage("Set encoding to UTF8 successfully.");
		PrintToServer("%s Set encoding to UTF8 successfully.", PLUGIN_PREFIX_PLAIN);
	#endif
}
// Purges the database of the user record if the client was banned.
public Query_DeleteRank(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	if (hndl == INVALID_HANDLE) {
		LogError("Failed to delete banned player's record.");
		LogError("Error: %s", error);
		
		PrintToServer("Failed to delete banned player's record.");
		PrintToServer("%s Error: %s", PLUGIN_PREFIX_PLAIN, error);
	}
}
// Handles error for cleanup.
public Query_Cleanup(Handle:owner, Handle:hndl, const String:error[], any:issuerId) {
	if (hndl == INVALID_HANDLE) {
		LogError("Cleanup failed.");
		LogError("Error: %s", error);
		
		PrintToServer("Cleanup failed.");	
		PrintToServer("%s Error: %s", PLUGIN_PREFIX_PLAIN, error);
		
		SetFailState("Cleanup failed. Check log for more information. %s", PLUGIN_VERSION);
	}
	
	new rowsDeleted = SQL_GetAffectedRows(hndl);
	
	#if defined PLUGIN_DEBUG
		LogMessage("Cleanup performed, %i record(s) deleted.", rowsDeleted);
		PrintToServer("%s Cleanup performed, %i record(s) deleted.", PLUGIN_PREFIX_PLAIN, rowsDeleted);
	#endif
	
	if (issuerId == WORLD)
		PrintToServer("%s Cleanup performed, %i record(s) deleted.", PLUGIN_PREFIX_PLAIN, rowsDeleted);
	else if (issuerId > WORLD && IsClientInGame(issuerId) == true) {
		CReplyToCommand(issuerId, "%s Cleanup performed, %i record(s) deleted.", PLUGIN_PREFIX, rowsDeleted);
	}
}
// Sets the fail state if the table creation fails.
public Query_CreateTable(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	if (hndl == INVALID_HANDLE) {
		LogError("Table creation failed.");
		PrintToServer("%s Table creation failed.", PLUGIN_PREFIX_PLAIN);	
		SetFailState("Creating the table failed. Check log for more information. %s", PLUGIN_VERSION);
	}
	else { // We made a successful connection to the server! Grats!
		if (cleanupTimer == INVALID_HANDLE && GetConVarInt(cleanupMode) == 2) {
			#if defined PLUGIN_DEBUG
				PrintToServer("%s First time starting cleanup timer.", PLUGIN_PREFIX_PLAIN);
			#endif
			
			cleanupTimer = CreateTimer(GetConVarFloat(cleanupInterval) * 60, CleanupTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		SQL_TQuery(connection, Query_CreateSettings, SQL_CREATESETTINGS);
	}
}
// Creates the table for settings, currently only dedicated to specifying version number.
public Query_CreateSettings(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	if (hndl == INVALID_HANDLE) {
		LogError("Settings table failed to create.");
		PrintToServer("%s Settings table failed to create.", PLUGIN_PREFIX_PLAIN);	
		SetFailState("Settings table failed to create. Check log for more information. %s", PLUGIN_VERSION);
	}
	
	SQL_TQuery(connection, Query_UpdateCheck, SQL_GETVERSION);
}
// Creates the version row.
public Query_CreateVersion(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	if (hndl == INVALID_HANDLE) {
		LogError("Version setting failed.");
		PrintToServer("%s Version setting failed.", PLUGIN_PREFIX_PLAIN);	
		SetFailState("Version setting failed. Check log for more information. %s", PLUGIN_VERSION);
	}
	else {
		PrintToServer("%s SUCCESS! The Player Ranks database was completely initialized!", PLUGIN_PREFIX_PLAIN);
	}
	
	SQL_TQuery(connection, Query_UpdateCheck, SQL_GETVERSION);
}
// Checks the version from settings and updates appropriately
public Query_UpdateCheck(Handle:owner, Handle:hndl, const String:error[], any:unused) {	
	if (hndl == INVALID_HANDLE) {
		LogError("Update to version %s failed!", PLUGIN_VERSION);
		PrintToServer("%s Update to version %s failed!", PLUGIN_PREFIX_PLAIN, PLUGIN_VERSION);	
		SetFailState("Update to version %s failed. Check log for more information.", PLUGIN_VERSION);
	}
	
	if (SQL_GetRowCount(hndl) == 0) {
		LogMessage("Version table is non-existant is being created.");
		PrintToServer("%s Version table is non-existant and is being created.", PLUGIN_PREFIX_PLAIN);
		SQL_TQuery(connection, Query_CreateVersion, SQL_CREATEVERSION);
		return;
	}
	
	SQL_FetchRow(hndl);
	databaseVersion = SQL_FetchInt(hndl, 0);
	
	#if defined PLUGIN_DEBUG
		LogMessage("Database version %i with plugin version %s.", databaseVersion, PLUGIN_VERSION);
		PrintToServer("%s Database version %i with plugin version %s.", PLUGIN_PREFIX_PLAIN, databaseVersion, PLUGIN_VERSION);
	#endif
	
	new bool:updatePerformed = false;
	new String:sqlDriver[64];
	
	SQL_ReadDriver(connection, sqlDriver, sizeof(sqlDriver));
	
	if (databaseVersion == 0) {
		PrintToServer("%s Performing update 1. This adds the following tracking features: kills, deaths, assists, headshots, backstabs, feigns and kill/death ratio.", PLUGIN_PREFIX_PLAIN);
		UpdateDatabase(SQL_UPDATE_1, 1);
	}
	else if (databaseVersion == 1) {
		PrintToServer("%s Performing update 2. This will clean out any duplicate records and ensure that it doesn't happen again.", PLUGIN_PREFIX_PLAIN);
		UpdateDatabase(SQL_UPDATE_2, 2);
	}
	else if (databaseVersion == 2) {
		PrintToServer("%s Performing update 3. This adds UTF8 support.", PLUGIN_PREFIX_PLAIN);
		if (isSQLite == true)
			ForceDatabaseVersion(3); // We skip the update to move convert the table to UTF8 if the driver is SQLite. SQLite only uses UTF8, and the update query will fail on SQLite.
		else
			UpdateDatabase(SQL_UPDATE_3, 3);
	}
	else if (databaseVersion == 3) {
		PrintToServer("%s Performing update 4. This adds boss and playtime tracking.", PLUGIN_PREFIX_PLAIN);
		UpdateDatabase(SQL_UPDATE_4, 4);
	}
	else if (databaseVersion == 4) {
		PrintToServer("%s Performing update 5. This adds rounds played, dominations against you, players you've dominated, objective captures and defends.", PLUGIN_PREFIX_PLAIN);
		UpdateDatabase(SQL_UPDATE_5, 5);
	}
	else if (databaseVersion == 5) {
		PrintToServer("%s Performing update 6. This adds tracking for deflects, kill streaks and automatic monthly or yearly database resets. Don't be alarmed; this feature will NOT be enabled by default!", PLUGIN_PREFIX_PLAIN);
		PrintToServer("%s Compatibility with SQLite is greatly improved and all !rank <search> functionality works.", PLUGIN_PREFIX_PLAIN);
		
		decl String:currentDate[8];
		FormatTime(currentDate, sizeof(currentDate), "%m/%Y", GetTime());
		
		decl String:update6[2048];
		Format(update6, sizeof(update6), SQL_UPDATE_6, currentDate);
		
		UpdateDatabase(update6, 6);
	}
	else if (databaseVersion == 6) {
		PrintToServer("%s Performing update 7. This update should fix the rank 0 issue for MySQL users.", PLUGIN_PREFIX_PLAIN);
		
		if (isSQLite == true)
			ForceDatabaseVersion(7);
		else
			UpdateDatabase(SQL_UPDATE_7, 7);
	}
	else if (databaseVersion == 7) {
		PrintToServer("%s Performing update 8. This update corrects reset code.", PLUGIN_PREFIX_PLAIN);
		
		decl String:currentDate[8];
		FormatTime(currentDate, sizeof(currentDate), "%m/%Y", GetTime());
		
		decl String:update8[2048];
		Format(update8, sizeof(update8), SQL_UPDATE_8, currentDate);
		
		UpdateDatabase(update8, 8);
		
		updatePerformed = true;
	}
	else  if (databaseVersion == DATABASE_VERSION) {
		if (updatePerformed == true)
			PrintToServer("%s The database has been updated to the latest.", PLUGIN_PREFIX_PLAIN);
		
		FinishInit();
	}
	else {
		SetFailState("The database version is unknown, version reported is %i. This verson of Player Ranks requires database version %i.", databaseVersion, DATABASE_VERSION);
	}
}
// Sets the fail state if the table creation fails.
public Query_Update(Handle:owner, Handle:hndl, const String:error[], any:version) {	
	if (hndl == INVALID_HANDLE) {
		LogError("Failed to update ranking database to version %i. Error %s", version, error);
		SetFailState("Failed to update ranking database to version %i, %s.", version, PLUGIN_VERSION);
	}
}
// Writes in the appropriate version number.
public Query_SetVersion(Handle:owner, Handle:hndl, const String:error[], any:version) {
	if (hndl == INVALID_HANDLE) {
		LogError("Update to version %d failed!", version);
		PrintToServer("%s Update to version %s failed!", PLUGIN_PREFIX_PLAIN, version);	
		SetFailState("Update to version %s failed. Check log for more information.", version);
	} 
	else {
		PrintToServer("Successfully updated database to version %i.", version);
	}
}
// Saves a new client record.
public Query_SaveUserRecord(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE)
	{	
		SetFailState("Failed to save user record. %s", PLUGIN_VERSION);
	}
	else {
		#if defined PLUGIN_DEBUG
			LogMessage("Saved record for client %i!", clientID);
			PrintToServer("%s Saved record for client %i!", PLUGIN_PREFIX_PLAIN, clientID);	
		#endif
	}
	
	ResetPack(data);
	
	new saveMode = ReadPackCell(data);
	new clientId = ReadPackCell(data);
	
	CloseHandle(data);
	
	if (saveMode == SAVEMODE_DISCONNECTING)
		PurgeClient(clientId);
	else if (saveMode == SAVEMODE_LAST)
		ReloadPlugin();
}
// Loads the score of the client.
public Query_LoadClient(Handle:owner, Handle:hndl, const String:error[], any:data) {
	ResetPack(data);
	new clientId = GetClientOfUserId(ReadPackCell(data));
	
	if (clientId == WORLD || IsClientInGame(clientId) == false) {
		CloseHandle(data);
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error: %s", error);
		LogError("Could not load client.");
		
		PrintToServer("Error: %s", error);
		PrintToServer("%s Could not load client.", PLUGIN_PREFIX_PLAIN);
		
		CloseHandle(data);	
		SetFailState("A client could not be loaded. Check log for more information. %s", PLUGIN_VERSION);
	}
	
	// If the player has an existing record in the database.
	
	if (SQL_FetchRow(hndl) == true) 
	{
		scores[clientId][points] = 			SQL_FetchFloat(hndl, 0);
		scores[clientId][deaths] = 			SQL_FetchInt(hndl, 	 1);
		scores[clientId][kills] = 			SQL_FetchInt(hndl, 	 2);
		scores[clientId][assists] = 		SQL_FetchInt(hndl, 	 3);
		scores[clientId][backstabs] = 		SQL_FetchInt(hndl, 	 4);
		scores[clientId][headshots] = 		SQL_FetchInt(hndl, 	 5);
		scores[clientId][feigns] = 			SQL_FetchInt(hndl, 	 6);
		scores[clientId][merKills] = 		SQL_FetchInt(hndl, 	 7);
		scores[clientId][merLvl] = 			SQL_FetchInt(hndl, 	 8);
		scores[clientId][monKills] = 		SQL_FetchInt(hndl, 	 9);
		scores[clientId][monLvl] = 			SQL_FetchInt(hndl, 	10);
		scores[clientId][hhhKills] =  		SQL_FetchInt(hndl, 	11);
		scores[clientId][totaltime] =  		RoundFloat(SQL_FetchFloat(hndl,12));
		scores[clientId][flagCaptures] =	SQL_FetchInt(hndl,  13);
		scores[clientId][flagDefends] = 	SQL_FetchInt(hndl,  14);
		scores[clientId][capCaptures] =  	SQL_FetchInt(hndl,  15);
		scores[clientId][capDefends] =  	SQL_FetchInt(hndl,  16);
		scores[clientId][roundsPlayed] =  	SQL_FetchInt(hndl,  17);
		scores[clientId][dominationsGood] = SQL_FetchInt(hndl,  18);
		scores[clientId][dominationsBad] =  SQL_FetchInt(hndl,  19);
		scores[clientId][deflects] =  		SQL_FetchInt(hndl,  20);
		scores[clientId][highestStreak] =  	SQL_FetchInt(hndl,  21);
		
		// If the client has a rank.
		new String:Query[256];
		Format(Query, sizeof(Query), SQL_LOADCLIENTRANK, scores[clientId][points]);
		
		#if defined PLUGIN_DEBUG
			LogMessage("Loaded client's score of %f, executing query %s to get rank.", scores[clientId][points], Query);
		#endif
		
		decl String:clientName[MAX_NAME_LENGTH];
		GetClientName(clientId, clientName, MAX_NAME_LENGTH);
		
		SQL_TQuery(connection, Query_LoadRank, Query, data);
		return;
	}
	
	scores[clientId][loaded] = true;
	CloseHandle(data);
}
// Finds the client by name.
public Query_FindClientByName(Handle:owner, Handle:hndl, const String:error[], any:clientUid) {
	new clientId = GetClientOfUserId(clientUid);
	// Block query if issuer is not online or SQL hasn't initialized.
	if (clientId == 0 || IsClientInGame(clientId) == false) {
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error: %s", error);
		LogError("Client lookup failed.");
		
		PrintToServer("Error: %s", error);
		PrintToServer("%s Client lookup failed.", PLUGIN_PREFIX_PLAIN);
		
		return;
	}
	
	new foundRows = 0;
	new Handle:data = CreateDataPack();
	
	decl String:name[MAX_NAME_LENGTH];
	decl String:steamid[MAX_STEAMID_LENGTH];
		
	while (SQL_FetchRow(hndl) == true) 
	{
		SQL_FetchString(hndl, 0, name, MAX_NAME_LENGTH);
		SQL_FetchString(hndl, 1, steamid, MAX_STEAMID_LENGTH);
		
		WritePackString(data, name);
		WritePackString(data, steamid);
		
		foundRows++;
	}
	
	if (foundRows > 1) {
		// Found multiple records, display the menu.
		WritePackCell(data, foundRows);
		ShowSearchMenu(clientId, data);
	}
	
	else if (foundRows == 1) {
		// Found one record. Go ahead and display the stats.
		CloseHandle(data);
		new String:Query[512];
		Format(Query, sizeof(Query), SQL_FINDCLIENTSTEAM, steamid);
		SQL_TQuery(connection, Query_FindClientBySteam, Query, clientUid);
	}
	else {
		// Nothing found, notify the user.
		CloseHandle(data);
		CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_search_noresults", clientId);
	}
}
// Finds the client by name.
public Query_FindClientBySteam(Handle:owner, Handle:hndl, const String:error[], any:clientUid) {
	new clientId = GetClientOfUserId(clientUid);
	// Block query if issuer is not online or SQL hasn't initialized.
	if (clientId == 0 || IsClientInGame(clientId) == false) {
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error: %s", error);
		LogError("Client lookup failed.");
		
		PrintToServer("Error: %s", error);
		PrintToServer("%s Client lookup failed.", PLUGIN_PREFIX_PLAIN);
		
		return;
	}
	
	if (SQL_FetchRow(hndl) == true) 
	{
		new String:name[MAX_NAME_LENGTH];
		SQL_FetchString(hndl, 0, name, MAX_NAME_LENGTH);
		
		new Handle:data = CreateDataPack();
		WritePackCell(data,						  clientUid);
		WritePackString(data, 					   	   name);
		WritePackFloat(data, 	SQL_FetchFloat(hndl, 	 1)); 	// Points
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 2)); 	// Deaths
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 3)); 	// Kills
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 4)); 	// Assists
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 5)); 	// Backstabs
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 6)); 	// Headshots
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 7)); 	// Feigns
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 8)); 	// Mer Kills
		WritePackCell(data, 	SQL_FetchInt(hndl, 	 	 9)); 	// Mer Level
		WritePackCell(data, 	SQL_FetchInt(hndl, 		10));	// Mon Kills
		WritePackCell(data, 	SQL_FetchInt(hndl, 		11));	// Mon Level
		WritePackCell(data, 	SQL_FetchInt(hndl, 		12));	// HHH Kills
		WritePackFloat(data, 	SQL_FetchFloat(hndl,	13));	// Time Played
		WritePackCell(data, 	SQL_FetchInt(hndl, 		14));	// Flags Captured
		WritePackCell(data, 	SQL_FetchInt(hndl, 		15));	// Flags Defended
		WritePackCell(data, 	SQL_FetchInt(hndl, 		16));	// Points Captured
		WritePackCell(data, 	SQL_FetchInt(hndl, 		17));	// Points Defended
		WritePackCell(data, 	SQL_FetchInt(hndl, 		18));	// Rounds Played
		WritePackCell(data, 	SQL_FetchInt(hndl, 		19));	// Dominations Given
		WritePackCell(data, 	SQL_FetchInt(hndl, 		20));	// Dominations Suffered
		WritePackCell(data, 	SQL_FetchInt(hndl, 		21));	// Last Seen
		WritePackCell(data, 	SQL_FetchInt(hndl, 		22));	// Deflect Count
		WritePackCell(data, 	SQL_FetchInt(hndl, 		23));	// Kill Streak
		
		new String:Query[256];
		Format(Query, sizeof(Query), SQL_LOADCLIENTRANK, SQL_FetchFloat(hndl, 1));
		SQL_TQuery(connection, Query_FindClientRank, Query, data);
	}
	else {
		CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_search_noresults", clientId);
	}
}
// Finds the client and prints their info to chat.
public Query_FindClientRank(Handle:owner, Handle:hndl, const String:error[], any:data) {
	ResetPack(data);
	
	new clientId = GetClientOfUserId(ReadPackCell(data));
	
	// Block query if issuer is not online or SQL hasn't initialized.
	if (clientId == 0 || IsClientInGame(clientId) == false) {
		CloseHandle(data);
		return;
	}
	
	if (hndl == INVALID_HANDLE) {
		LogError("Error: %s", error);
		LogError("Client lookup failed.");
		
		PrintToServer("Error: %s", error);
		PrintToServer("%s Client lookup failed.", PLUGIN_PREFIX_PLAIN);
		CloseHandle(data);
		return;
	}
	
	if (SQL_FetchRow(hndl) == false)  {
		CloseHandle(data);
		CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_search_noresults", clientId);
		return;
	}
	
	decl String:nickNamep[MAX_NAME_LENGTH]; ReadPackString(data, nickNamep, MAX_NAME_LENGTH);
	new Float:pointsp = 	ReadPackFloat(data);
	new deathsp = 			ReadPackCell(data);
	new killsp  = 			ReadPackCell(data);
	new assistsp = 			ReadPackCell(data);
	new backstabsp =	 	ReadPackCell(data);
	new headshotsp = 		ReadPackCell(data);
	new feignsp = 			ReadPackCell(data);
	new merKillsp = 		ReadPackCell(data);
	new merLvlp = 			ReadPackCell(data);
	new monKillsp = 		ReadPackCell(data);
	new monLvlp = 			ReadPackCell(data);
	new hhhKillsp =  		ReadPackCell(data);
	new Float:totaltimep =  ReadPackFloat(data);
	new flagCapturesp =		ReadPackCell(data);
	new flagDefendsp = 		ReadPackCell(data);
	new capCapturesp =  	ReadPackCell(data);
	new capDefendsp =  		ReadPackCell(data);
	new roundsPlayedp =  	ReadPackCell(data);
	new dominationsGoodp = 	ReadPackCell(data);
	new dominationsBadp =  	ReadPackCell(data);
	new seenp =  			ReadPackCell(data);
	new deflectsp =  		ReadPackCell(data);
	new killStreaksp =  	ReadPackCell(data);
	
	new String:seenDate[30];
	FormatTime(seenDate, sizeof(seenDate), "%B %d, %Y", seenp);
	CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_top_rank_offline", clientId, nickNamep, SQL_FetchInt(hndl, 0), totalCount, pointsp, seenDate);
		
	if (killsp > 0.0 && deathsp > 0.0) {
		CPrintToChat(clientId, "%s %T %T", PLUGIN_PREFIX, "pr_stats_1", clientId, killsp, deathsp, assistsp, "pr_stats_2", clientId, FloatDiv(float(killsp), float(deathsp)));
	}
	else {
		CPrintToChat(clientId, "%s %T", PLUGIN_PREFIX, "pr_stats_1", clientId, killsp, deathsp, assistsp);
	}
	
	if (isTF2 == true) {
		CPrintToChat(clientId, "%T", "pr_stats_3", clientId, headshotsp, backstabsp, feignsp, deflectsp, killStreaksp);
		
		if (merKillsp > 0)
			CPrintToChat(clientId, "%T %T", "pr_stats_4", clientId, merKillsp, "Merasmus", "pr_stats_5", clientId, merLvlp);
			
		if (monKillsp > 0)
			CPrintToChat(clientId, "%T %T", "pr_stats_4", clientId, monKillsp, "Monoculus", "pr_stats_5", clientId, monLvlp);
			
		if (hhhKillsp > 0)
			CPrintToChat(clientId, "%T", "pr_stats_4", clientId, hhhKillsp, "Headless Horsemann");
		
		CPrintToChat(clientId, "%T", "pr_stats_6", clientId, totaltimep / 3600);
		
		CPrintToChat(clientId, "%T", "pr_stats_7", clientId, flagCapturesp, flagDefendsp, capCapturesp, capDefendsp, roundsPlayedp);
		CPrintToChat(clientId, "%T", "pr_stats_8", clientId, dominationsGoodp, dominationsBadp);
	}
	CloseHandle(data);
}

// Loads the ranking of the client.
public Query_LoadRank(Handle:owner, Handle:hndl, const String:error[], any:data) {
	ResetPack(data);
	new clientId = GetClientOfUserId(ReadPackCell(data));
	
	if (clientId == WORLD || IsClientInGame(clientId) == false) {
		CloseHandle(data);
		return;
	}
	
	new bool:announceConnect = bool:ReadPackCell(data);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Error: %s", error);
		LogError("Could not load player rank.");
		
		PrintToServer("%s Error: %s", PLUGIN_PREFIX_PLAIN, error);
		PrintToServer("%s Could not load player rank.", PLUGIN_PREFIX_PLAIN);
		
		SetFailState("A client could not be loaded. Check log for more information. %s", PLUGIN_VERSION);
	}
	
	if (SQL_FetchRow(hndl) == true) {
		scores[clientId][rank] = SQL_FetchInt(hndl, 0);
		
		decl String:clientName[MAX_NAME_LENGTH];
		GetClientName(clientId, clientName, MAX_NAME_LENGTH);
		
		#if defined PLUGIN_DEBUG
			LogMessage("--> Client '%s' with score %f is #%i.", clientName, scores[clientId][points], scores[clientId][rank]);
		#endif
		
		scores[clientId][loaded] = true;
	}
	else {
		SetFailState("Fetching a user rank has failed.");
	}
	
	if (announceConnect == true && GetConVarBool(suppressRankMsg) == false) {
		new String:clientName[MAX_NAME_LENGTH];
		GetClientName(clientId, clientName, MAX_NAME_LENGTH);
		
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_msg_join", clientName, scores[clientId][rank], totalCount);
		
		#if defined PLUGIN_DEBUG
			LogMessage("Client %s connected with %.2f points, rank: %i.", clientName, scores[clientId][points], scores[clientId][rank]);
			PrintToServer("Client %s connected with %.2f points, rank: %i.", clientName, scores[clientId][points], scores[clientId][rank]);
		#endif
	}
	
	CloseHandle(data);
}

// Populates the top players score array with the top clients on file.
public Query_TopPlayers(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		PrintToServer("%s Query failed: %s", PLUGIN_PREFIX_PLAIN, error);
		SetFailState("Plugin failed to get top players. Check log for more information. %s", PLUGIN_VERSION);
		return;
	}
	
	new rankPosition = 0;
	
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, topScores[rankPosition][tSteamId], MAX_STEAMID_LENGTH);
		SQL_FetchString(hndl, 1, topScores[rankPosition][tNickname], MAX_NAME_LENGTH);
		topScores[rankPosition][tPoints] = 			SQL_FetchFloat(hndl,  2);
		topScores[rankPosition][tSeen] = 			SQL_FetchInt(hndl, 	  3);
		topScores[rankPosition][tDeaths] = 			SQL_FetchInt(hndl, 	  4);
		topScores[rankPosition][tKills] = 			SQL_FetchInt(hndl, 	  5);
		topScores[rankPosition][tAssists] = 		SQL_FetchInt(hndl, 	  6);
		topScores[rankPosition][tBackstabs] = 		SQL_FetchInt(hndl, 	  7);
		topScores[rankPosition][tHeadshots] = 		SQL_FetchInt(hndl, 	  8);
		topScores[rankPosition][tFeigns] = 			SQL_FetchInt(hndl, 	  9);
		topScores[rankPosition][tmerKills] = 		SQL_FetchInt(hndl, 	 10);
		topScores[rankPosition][tmerLvl] = 			SQL_FetchInt(hndl, 	 11);
		topScores[rankPosition][tmonKills] = 		SQL_FetchInt(hndl, 	 12);
		topScores[rankPosition][tmonLvl] = 			SQL_FetchInt(hndl, 	 13);
		topScores[rankPosition][thhhKills] =  		SQL_FetchInt(hndl, 	 14);
		topScores[rankPosition][ttotaltime] =  		SQL_FetchFloat(hndl, 15);
		topScores[rankPosition][tflagCaptures] =	SQL_FetchInt(hndl,   16);
		topScores[rankPosition][tflagDefends] = 	SQL_FetchInt(hndl,   17);
		topScores[rankPosition][tcapCaptures] =  	SQL_FetchInt(hndl,   18);
		topScores[rankPosition][tcapDefends] =  	SQL_FetchInt(hndl,   19);
		topScores[rankPosition][troundsPlayed] =  	SQL_FetchInt(hndl,   20);
		topScores[rankPosition][tdominationsGood] = SQL_FetchInt(hndl,   21);
		topScores[rankPosition][tdominationsBad] =  SQL_FetchInt(hndl,   22);
		topScores[rankPosition][tDeflects] = 		SQL_FetchInt(hndl,   23);
		topScores[rankPosition][tHighestStreak] =  	SQL_FetchInt(hndl,   24);
		
		rankPosition++;
	}
	
	#if defined PLUGIN_DEBUG
		PrintToServer("%s Top listing updated.", PLUGIN_PREFIX_PLAIN); 
	#endif
}
// Gets the total players in the database. You are ranked #1 out of 9001 players.
public Query_GetRecordCount(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		PrintToServer("%s Query failed: %s", PLUGIN_PREFIX_PLAIN, error);
		SetFailState("Plugin failed to get record count. Check log for more information. %s", PLUGIN_VERSION);
		return;
	}
	
	if (SQL_FetchRow(hndl) == true)
		totalCount = SQL_FetchInt(hndl, 0);
}
// Stage 1: Check the database to see if it needs reset.
public Query_ResetDatabase_S1(Handle:owner, Handle:hndl, const String:error[], any:unused) {
	//Time format: MM/YYYY       05/2014
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("%s Query failed: %s", PLUGIN_PREFIX_PLAIN, error);
		SetFailState("Plugin failed to perform an automatic database reset. Check log for more information. %s", PLUGIN_VERSION);
	}
	else if (SQL_FetchRow(hndl) == true) {
		new resetMode = GetConVarInt(rankResetMode);
		
		if (resetMode == RESETMODE_MONTHLY) {
			decl String:resetDate[16];
			SQL_FetchString(hndl, 0, resetDate, 8);
			
			decl String:currentDate[16];
			FormatTime(currentDate, sizeof(currentDate), "%m/%Y", GetTime());
			
			if (StrEqual(resetDate, currentDate) == false) {
				ResetDatabase(NO_ISSUER);
			}
			else {
				isReady = true;
				FinishLateInit();
			}
		}
		else {
			decl String:resetDate[16];
			SQL_FetchString(hndl, 0, resetDate, sizeof(resetDate));
			
			
			
			decl String:currentDate[16];
			FormatTime(currentDate, sizeof(currentDate), "%Y", GetTime());
			
			if (StrEqual(resetDate[3], currentDate) == false) {
				ResetDatabase(NO_ISSUER);
			}
			else {
				isReady = true;
				FinishLateInit();
			}
		}
	}
	else {
		LogError("FAILURE: Failed to run reset routines.");
	}
}
// Stage 2: Perform the reset.
public Query_ResetDatabase_S2(Handle:owner, Handle:hndl, const String:error[], any:issuerUid) {
	new issuer = (issuerUid <= WORLD ? issuerUid : GetClientOfUserId(issuerUid));
	
	if (hndl == INVALID_HANDLE)
	{
		if (issuer != NO_ISSUER && issuer != WORLD && IsClientInGame(issuer))
			CPrintToChat(issuer, "Query failed: %s", error);
			
		PrintToServer("%s Query failed: %s", PLUGIN_PREFIX_PLAIN, error);
		SetFailState("Plugin failed to get record count. Check log for more information. %s", PLUGIN_VERSION);
	}
	
	isReady = true;
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "pr_reset");
	PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_reset", LANG_SERVER);
	
	decl String:currentDate[16];
	FormatTime(currentDate, sizeof(currentDate), "%m/%Y", GetTime());
	
	decl String:query[128];
	Format(query, sizeof(query), SQL_SETRESETDATE, currentDate);
	
	SQL_TQuery(connection, Query_ResetDatabase_S3, query, (issuer == NO_ISSUER ? true : false));
}
// Stage 3: Update the database's date of reset.
public Query_ResetDatabase_S3(Handle:owner, Handle:hndl, const String:error[], any:automatic) {
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("%s Query failed: %s", PLUGIN_PREFIX_PLAIN, error);
		SetFailState("Plugin failed to reset the rank database. Check log for more information. %s", PLUGIN_VERSION);
	}
	
	if (automatic == true) {
		new resetMode = GetConVarInt(rankResetMode);
		
		if (resetMode == RESETMODE_MONTHLY)
			PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_reset_monthly", LANG_SERVER);
		else
			PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_reset_yearly", LANG_SERVER);
			
		ReloadPlugin();
	}
	else if (automatic == 2) {
		PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_resetmode_changed", LANG_SERVER);
		PrintToServer("%s %T", PLUGIN_PREFIX_PLAIN, "pr_resetmode_changed_2", LANG_SERVER);
	}
}
// NATIVE WORLD!!!! Let's all go to native world!

// Gives a specified client (by client ID) a point amount. If forced, it ignores the rules of minimum player count, this happens if an admin manually rewards a client.
public Native_Reward(Handle:plugin, numParams) {
	new clientId = GetNativeCell(1);
	new Float:amount = Float:GetNativeCell(2);
	new bool:forced = bool:GetNativeCell(3);
	
	Reward(clientId, amount, forced);
}

// Removes a specified client (by client ID) a point amount. If forced, it ignores the rules of minimum player count, this happens if an admin manually revokes points from a client.
public Native_Revoke(Handle:plugin, numParams) {
	new clientId = GetNativeCell(1);
	new Float:amount = Float:GetNativeCell(2);
	new bool:forced = bool:GetNativeCell(3);
	
	Revoke(clientId, amount, forced);
}

// GETTERS
public Native_IsClientLoaded(Handle:plugin, numParams) 		    { return _:scores[GetNativeCell(1)][loaded];   							}
public Native_GetKills(Handle:plugin, numParams) 				{ return _:scores[GetNativeCell(1)][kills];    							}
public Native_GetDeaths(Handle:plugin, numParams) 				{ return _:scores[GetNativeCell(1)][deaths];   							}
public Native_GetAssists(Handle:plugin, numParams) 				{ return _:scores[GetNativeCell(1)][assists];  							}
public Native_GetMerasmusKills(Handle:plugin, numParams) 		{ return _:scores[GetNativeCell(1)][merKills]; 							}
public Native_GetMerasmusLevel(Handle:plugin, numParams) 	    { return _:scores[GetNativeCell(1)][merLvl];   							}
public Native_GetMonoculusKills(Handle:plugin, numParams) 		{ return _:scores[GetNativeCell(1)][monKills]; 							}
public Native_GetMonoculusLevel(Handle:plugin, numParams) 		{ return _:scores[GetNativeCell(1)][monLvl];   							}
public Native_GetRoundPoints(Handle:plugin, numParams) 		 	{ return _:scores[GetNativeCell(1)][roundPoints]; 						}
public Native_GetTotalPoints(Handle:plugin, numParams) 			{ return _:scores[GetNativeCell(1)][points]; 							}
public Native_GetTimePlayed(Handle:plugin, numParams) 			{ return _:scores[GetNativeCell(1)][totaltime];							}
public Native_GetBossDamage(Handle:plugin, numParams) 			{ return _:scores[GetNativeCell(1)][bossdmg]; 							}
public Native_GetHeadshots(Handle:plugin, numParams) 			{ return _:scores[GetNativeCell(1)][headshots];							}
public Native_GetBackstabs(Handle:plugin, numParams) 			{ return _:scores[GetNativeCell(1)][backstabs];   						}
public Native_GetFeigns(Handle:plugin, numParams) 				{ return _:scores[GetNativeCell(1)][feigns]; 							}
public Native_GetRoundEligible(Handle:plugin, numParams) 		{ return _:scores[GetNativeCell(1)][roundBonus];						}

// SETTERS
public Native_SetKills(Handle:plugin, numParams) 				{ scores[GetNativeCell(1)][kills] = 		GetNativeCell(2);    		}
public Native_SetDeaths(Handle:plugin, numParams) 				{ scores[GetNativeCell(1)][deaths] = 		GetNativeCell(2);   		}
public Native_SetAssists(Handle:plugin, numParams) 				{ scores[GetNativeCell(1)][assists] = 		GetNativeCell(2);  			}
public Native_SetMerasmusKills(Handle:plugin, numParams) 		{ scores[GetNativeCell(1)][merKills] = 		GetNativeCell(2); 			}
public Native_SetMerasmusLevel(Handle:plugin, numParams) 	    { scores[GetNativeCell(1)][merLvl] = 		GetNativeCell(2);   		}
public Native_SetMonoculusKills(Handle:plugin, numParams) 		{ scores[GetNativeCell(1)][monKills] = 		GetNativeCell(2); 			}
public Native_SetMonoculusLevel(Handle:plugin, numParams) 		{ scores[GetNativeCell(1)][monLvl] = 		GetNativeCell(2);   		}
public Native_SetRoundPoints(Handle:plugin, numParams) 		 	{ scores[GetNativeCell(1)][roundPoints] = 	Float:GetNativeCell(2); 	}
public Native_SetTotalPoints(Handle:plugin, numParams) 			{ scores[GetNativeCell(1)][points] = 		Float:GetNativeCell(2); 	}
public Native_SetBossDamage(Handle:plugin, numParams) 			{ scores[GetNativeCell(1)][bossdmg] = 		GetNativeCell(2); 			}
public Native_SetHeadshots(Handle:plugin, numParams) 			{ scores[GetNativeCell(1)][headshots] = 	GetNativeCell(2);			}
public Native_SetBackstabs(Handle:plugin, numParams) 			{ scores[GetNativeCell(1)][backstabs] = 	GetNativeCell(2);   		}
public Native_SetFeigns(Handle:plugin, numParams) 				{ scores[GetNativeCell(1)][feigns] = 		GetNativeCell(2); 			}
public Native_SetRoundEligible(Handle:plugin, numParams) 		{ scores[GetNativeCell(1)][roundBonus] = 	bool:GetNativeCell(2);		}

// METHODS
public Native_SaveAll(Handle:plugin, numParams) 				{ ForceSave(); 															}
public Native_ShowRank(Handle:plugin, numParams) 				{ ShowRankMenu(GetNativeCell(1));										}
public Native_ShowRankMe(Handle:plugin, numParams) 				{ ShowRankMe(GetNativeCell(1)); 										}
public Native_ShowTop(Handle:plugin, numParams) 				{ ShowTopMenu(GetNativeCell(1)); 										}