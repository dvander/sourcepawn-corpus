/*
-----------------------------------------------------------------------------
LEFT 4 DEAD STATS - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2009
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
Customization to Support Multiple Gamemodes And L4D2 By muukis
-----------------------------------------------------------------------------
This is a ranking/stat tracking system for Left 4 Dead Co-op. It will track
certain actions, such as giving a teammate Pills or rescuing them from a
Hunter, as well as tracking kills of the types of Infected. The goal of the
stats is both to rank players against one another, but also to promote
teamwork by awarding more points for completing team-specific goals rather
than simply basing on kills.

You can access your basic rank information by typing "rank" or "/rank" in
the chat area. You can access the Top 10 Players by typing "top10" or
"/top10" in the chat area.

The plugin ONLY works in Co-op mode, in every difficulty but Easy. Stats
will automatically stop tracking if any of these conditions are met:
 . Game is in Easy difficulty
 . sv_cheats is set to "1"
 . There are not enough Human players, as determined by a Cvar
 . The Database connection has failed

The webstats portion provides more in-depth stat information, both for
individual players as well as the server as a whole, with full campaign and
map stat info. More information about webstats can be found in the webstats
ZIP file.

Special thanks to DopeFish, Icettiflow, jasonfrog, and liv3d for helping me
beta test prior to full public release.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
A little notice on my behalf as well:

I'd like to send my special thanks to Harm and Titan for the testing done
when adding support to L4D2. This would not have been possible to accomplish
in this timeframe, if it wasn't for them! Planetsize thanks guys!

- muukis
-----------------------------------------------------------------------------
To Do List (Minor)
 . Fix minor bug with Campaign tracking
 . Add multilingual support

To Do List (Major)
 . Add "Squad" system
 . Add grace period and cooldown to Friendly Fire
 . Add achievement system
 . Add Survival support
 . Versus statistics
   . Smoker pull award (length)
   . Tank incapacitated or killed all players
-----------------------------------------------------------------------------
Version History

-- 0.1.0 (1/8/09)
 . Initial closed beta release!

-- 0.1.1 (1/9/09)
 . Silenced plugin disable alerts, except "not enough Human players" alert.
 . Removed misc debug message.
 . Fixed misc error log messages.

-- 0.1.2 (1/12/09)
 . Testing new interstitial SQL method for Common Infected kill tracking.
   Instead of sending a SQL transaction after each kill, only send SQL during
   the update period when Common Infected points are displayed. The high
   amount of SQL traffic causes noticible lag during high combat periods,
   such as when a mob attacks.

-- 0.1.6 (1/13/09)
 . Fully implimented interstitial SQL update for Common Infected. Added
   check to send update when a player disconnects, so no points are lost if
   they disconnect between interstitial updates.
 . Cleaned up code a bit.
 . Improved player name sanitation.
 . Changed new players playtime to init at 1 instead of 0.
 . Changed point amounts from static values to Cvar values.
 . Added Cvar to control how stats messages are displayed to players:
    0 = Stats messages are off
    1 = Messages sent to the player who earned them only
    2 = Same as 1, but Headshots on Special Infected are globally anounced
    3 = All messages are global. Warning: This is VERY annoying!
 . Added Cvar to control whether Medkit points are given based on the amount
   healed, or a static amount set by Cvar. Amount healed is 0.5x in Normal,
   1x in Advanced, and 2x in Expert.
 . Added check to disable stats if the Database connection has failed.

-- 0.1.8 (1/15/09)
 . Further cleaned up code.
 . Optimized UTF8 character support.
 . Removed log message on successful database connection.
 . Added threaded query to player inserting, to check if the player already
   exists and if so, don't attempt to INSERT IGNORE them.
 . Reformatted rank panels.
 . Added Cvar to list community site for more information in "rank" panel.
 . Removed table generation from the plugin. This will be handled by a
   setup script provided with webstats.

-- 0.1.9 (1/16/09)
 . Changed all updates to threaded queries, to fix lag caused by updates and
   server timeouts in rare cases.

-- 1.0.0 (1/18/09)
 . Initial public release!

-- 1.1.0 (1/25/09)
 . Fixed change in update/Common Infected announcement timer not obeying
   changes to the cvar, except when in the config file and the plugin/server
   is restarted.
 . Fixed team chat not picking up chat triggers.
 . Added invalid database connection checking to rank/top10 panel display.
 . Fixed bug where players would be inserted into the database, but their
   user data would not get updated and they would appear blank.
 . Removed plugin version from showing up in the config file.
 . Removed "Not enough Humans" message when in Versus.
 . Made rank panel display after client connect at the start of each map,
   and added cvar to enable/disable this.
 . Made "Playtime" display hours if the playtime is longer than 60 minutes.
 . Added cvar to hide the display of public chat triggers.
-- 1.1.1 (4/22/09)
 . Changed "IsVersus()" function to "InvalidGameMode()" to fix deadstop bug
   with the Survival update. This is part of paving the way to Survival
   and Versus stats in a future release.
 . Fixed various error messages in error logs.
 . Fixed stats panel to now work properly for people with certain characters
   in their name not making it display.
 . Fixed (again) a certain case where blank users would be inserted.
 . Added cvar to enable/disable showing of the rank panel when not in a valid
   gamemode, showing of disabled messages, and letting players use the chat
   commands.
 . Added some stat whoring checks to the plugin:
    . A maximum amount of points can be earned in a single map
    . Only 3 Tanks may be awarded during a single map
 . Fixed minor bug with Healthpack point award not giving full amount.
 . Added a few currently unused cvars for future features:
   . sm_l4dstats_dbprefix -- Prefix to be used for database tables
   . sm_l4dstats_enablecoop -- Enable stats for Coop mode
   . sm_l4dstats_enablesv -- Enable stats for Survival mode
   . sm_l4dstats_enableversus -- Enable stats for Versus mode
   . sm_l4dstats_leaderboardtime -- Duration in days to show players top
     times on the Survival leaderboards

-- 1.1.1C (8/19/09) Customized by muukis
 . Added support for custom maps.

-- 1.2AXXX (9/23/09) Alpha versions from Versus support
 . Started implementing the Versus support. (IT COMPILES!!!1)

-- 1.2BXXX (10/16/09) Beta versions from Versus support
 . All new major features that I could come up with are now implemeted:
   . Survivor friendly fire cooldown mode.
   . Survivor medkit use penalty (score reduction.)
   . Spam protection allowing team gain and loss information to be shown
     for the team only.
   . Infected score:
     . General: Damage done to the survivors.
     . General: Damage done by normal infected is forwarded to the specials
       that have influence over the victim (blinded, lunged or paralyzed.)
     . General: Incapacitate and kill a survivor.
     . Hunter pounces.
     . Boomer blindings.
     . Tank rock sniper.

-- 1.2B90 (12/07/09) "Conversion" to Left 4 Dead 2

-- 1.3AXXX (12/11/09) Alpha versions from L4D2 support

-- 1.3BXXX (12/11/09) Beta versions from L4D2 support
 . Support for L4D2:
   . Support for Realism and Team Versus gamemodes.
   . Adrenalines given.
   . Defibrillators used.
   . New stats for every new Special Infected (in addition to spawned counter and damage counter):
     . Jockey:
       . Ride length (time)
 . Survivor damage based friendly fire mode.
 . "Player Stats" object in Admin Menu.
 . New console command "sm_rank_clear" to clear database.

-- 1.4AXXX (12/11/09) Alpha versions from Survival and Scavenge support

-- 1.4BXXX (X/X/10) Beta versions from Survival and Scavenge support
 . Support for all gamemodes!
 . Support for L4D2:
   . Gas canister poured.
   . Ammo upgrade deployed.
 . New console commands:
   . sm_rank_shuffle -- Shuffle teams (Versus / Scavenge) with player PPM (Points Per Minute).
   . sm_rankvote -- Initiate team shuffle vote ("rankvote").
   . sm_top10ppm -- Show Top10 players with highest PPM (Points Per Minute).
   . sm_showrank -- Show currently playing players stats.
   . sm_showppm -- Show currently playing players PPM (Points Per Minute).

-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.4B46"
#define MAX_LINE_WIDTH 64
#define MAX_MESSAGE_WIDTH 256
#define MAX_QUERY_COUNTER 256
#define DB_CONF_NAME "l4dstats"

#define GAMEMODE_UNKNOWN -1
#define GAMEMODE_COOP 0
#define GAMEMODE_VERSUS 1
#define GAMEMODE_REALISM 2
#define GAMEMODE_SURVIVAL 3
#define GAMEMODE_SCAVENGE 4
#define GAMEMODES 5

#define INF_ID_SMOKER 1
#define INF_ID_BOOMER 2
#define INF_ID_HUNTER 3
#define INF_ID_SPITTER_L4D2 4
#define INF_ID_JOCKEY_L4D2 5
#define INF_ID_CHARGER_L4D2 6
#define INF_ID_WITCH_L4D1 4
#define INF_ID_WITCH_L4D2 7
#define INF_ID_TANK_L4D1 5
#define INF_ID_TANK_L4D2 8

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define INF_WEAROFF_TIME 0.5

#define SERVER_VERSION_L4D1 40
#define SERVER_VERSION_L4D2 50

#define CLEAR_DATABASE_CONFIRMTIME 10.0

#define CM_UNKNOWN -1
#define CM_RANK 0
#define CM_TOP10 1
#define CM_NEXTRANK 2
#define CM_NEXTRANKFULL 3

#define DB_PLAYERS_TOTALPOINTS "points + points_survivors + points_infected + points_realism + points_survival + points_scavenge_survivors + points_scavenge_infected"
#define DB_PLAYERS_TOTALPLAYTIME "playtime + playtime_versus + playtime_realism + playtime_survival + playtime_scavenge"

#define RANKVOTE_QUESTION "Do you want to shuffle teams by player PPM?"
#define RANKVOTE_NOVOTE -1
#define RANKVOTE_NO 0
#define RANKVOTE_YES 1

// Set to false when stats seem to work properly
new bool:DEBUG = true;

// Server version
new ServerVersion = SERVER_VERSION_L4D1;

// Database handle
new Handle:db = INVALID_HANDLE;

// Update Timer handle
new Handle:UpdateTimer = INVALID_HANDLE;

// Gamemode
new String:CurrentGamemode[MAX_LINE_WIDTH];
new String:CurrentGamemodeLabel[MAX_LINE_WIDTH];
new CurrentGamemodeID = GAMEMODE_UNKNOWN;

// Disable check Cvar handles
new Handle:cvar_Difficulty = INVALID_HANDLE;
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:cvar_Cheats = INVALID_HANDLE;

new Handle:cvar_SurvivorLimit = INVALID_HANDLE;
new Handle:cvar_InfectedLimit = INVALID_HANDLE;

// Game event booleans
new bool:PlayerVomited = false;
new bool:PlayerVomitedIncap = false;
new bool:PanicEvent = false;
new bool:PanicEventIncap = false;
new bool:CampaignOver = false;
new bool:WitchExists = false;
new bool:WitchDisturb = false;

// Anti-Stat Whoring vars
new CurrentPoints[MAXPLAYERS + 1];
new TankCount = 0;

// Cvar handles
new Handle:cvar_EnableRankVote = INVALID_HANDLE;
new Handle:cvar_HumansNeeded = INVALID_HANDLE;
new Handle:cvar_UpdateRate = INVALID_HANDLE;
//new Handle:cvar_AnnounceRankMinChange = INVALID_HANDLE;
new Handle:cvar_AnnounceRankChange = INVALID_HANDLE;
new Handle:cvar_AnnounceMode = INVALID_HANDLE;
new Handle:cvar_AnnounceRankChangeIVal = INVALID_HANDLE;
new Handle:cvar_AnnounceToTeam = INVALID_HANDLE;
new Handle:cvar_MedkitMode = INVALID_HANDLE;
new Handle:cvar_SiteURL = INVALID_HANDLE;
new Handle:cvar_RankOnJoin = INVALID_HANDLE;
new Handle:cvar_SilenceChat = INVALID_HANDLE;
new Handle:cvar_DisabledMessages = INVALID_HANDLE;
new Handle:cvar_MaxPoints = INVALID_HANDLE;
new Handle:cvar_DbPrefix = INVALID_HANDLE;
new Handle:cvar_LeaderboardTime = INVALID_HANDLE;
new Handle:cvar_EnableNegativeScore = INVALID_HANDLE;
new Handle:cvar_FriendlyFireMode = INVALID_HANDLE;
new Handle:cvar_FriendlyFireMultiplier = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldown = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldownMode = INVALID_HANDLE;
new Handle:FriendlyFireTimer[MAXPLAYERS + 1][MAXPLAYERS + 1];
new bool:FriendlyFireCooldown[MAXPLAYERS + 1][MAXPLAYERS + 1];
new FriendlyFirePrm[MAXPLAYERS][2];
new Handle:FriendlyFireDamageTrie = INVALID_HANDLE;
new FriendlyFirePrmCounter = 0;

new Handle:cvar_EnableCoop = INVALID_HANDLE;
new Handle:cvar_EnableSv = INVALID_HANDLE;
new Handle:cvar_EnableVersus = INVALID_HANDLE;
new Handle:cvar_EnableTeamVersus = INVALID_HANDLE;
new Handle:cvar_EnableRealism = INVALID_HANDLE;
new Handle:cvar_EnableScavenge = INVALID_HANDLE;
new Handle:cvar_EnableTeamScavenge = INVALID_HANDLE;

new Handle:cvar_RealismMultiplier = INVALID_HANDLE;
new Handle:cvar_EnableSvMedicPoints = INVALID_HANDLE;

new Handle:cvar_Infected = INVALID_HANDLE;
new Handle:cvar_Hunter = INVALID_HANDLE;
new Handle:cvar_Smoker = INVALID_HANDLE;
new Handle:cvar_Boomer = INVALID_HANDLE;
new Handle:cvar_Spitter = INVALID_HANDLE;
new Handle:cvar_Jockey = INVALID_HANDLE;
new Handle:cvar_Charger = INVALID_HANDLE;

new Handle:cvar_Pills = INVALID_HANDLE;
new Handle:cvar_Adrenaline = INVALID_HANDLE;
new Handle:cvar_Medkit = INVALID_HANDLE;
new Handle:cvar_Defib = INVALID_HANDLE;
new Handle:cvar_SmokerDrag = INVALID_HANDLE;
new Handle:cvar_ChokePounce = INVALID_HANDLE;
new Handle:cvar_JockeyRide = INVALID_HANDLE;
new Handle:cvar_ChargerPlummel = INVALID_HANDLE;
new Handle:cvar_ChargerCarry = INVALID_HANDLE;
new Handle:cvar_Revive = INVALID_HANDLE;
new Handle:cvar_Rescue = INVALID_HANDLE;
new Handle:cvar_Protect = INVALID_HANDLE;

new Handle:cvar_Tank = INVALID_HANDLE;
new Handle:cvar_Panic = INVALID_HANDLE;
new Handle:cvar_BoomerMob = INVALID_HANDLE;
new Handle:cvar_SafeHouse = INVALID_HANDLE;
new Handle:cvar_Witch = INVALID_HANDLE;
new Handle:cvar_WitchCrowned = INVALID_HANDLE;
new Handle:cvar_VictorySurvivors = INVALID_HANDLE;
new Handle:cvar_VictoryInfected = INVALID_HANDLE;

new Handle:cvar_FFire = INVALID_HANDLE;
new Handle:cvar_FIncap = INVALID_HANDLE;
new Handle:cvar_FKill = INVALID_HANDLE;
new Handle:cvar_InSafeRoom = INVALID_HANDLE;
new Handle:cvar_Restart = INVALID_HANDLE;
new Handle:cvar_CarAlarm = INVALID_HANDLE;
new Handle:cvar_BotScoreMultiplier = INVALID_HANDLE;

new Handle:cvar_SurvivorDeath = INVALID_HANDLE;
new Handle:cvar_SurvivorIncap = INVALID_HANDLE;

// L4D2 misc
new Handle:cvar_AmmoUpgradeAdded = INVALID_HANDLE;
new Handle:cvar_GascanPoured = INVALID_HANDLE;

new MaxPounceDistance;
new MinPounceDistance;
new MaxPounceDamage;
new Handle:cvar_HunterDamageCap = INVALID_HANDLE;
new Float:HunterPosition[MAXPLAYERS + 1][3];
new Handle:cvar_HunterPerfectPounceDamage = INVALID_HANDLE;
new Handle:cvar_HunterPerfectPounceSuccess = INVALID_HANDLE;
new Handle:cvar_HunterNicePounceDamage = INVALID_HANDLE;
new Handle:cvar_HunterNicePounceSuccess = INVALID_HANDLE;

new BoomerHitCounter[MAXPLAYERS + 1];
new bool:BoomerVomitUpdated[MAXPLAYERS + 1];
new Handle:cvar_BoomerSuccess = INVALID_HANDLE;
new Handle:cvar_BoomerPerfectHits = INVALID_HANDLE;
new Handle:cvar_BoomerPerfectSuccess = INVALID_HANDLE;
new Handle:TimerBoomerPerfectCheck[MAXPLAYERS + 1];

new InfectedDamageCounter[MAXPLAYERS + 1];
new Handle:cvar_InfectedDamage = INVALID_HANDLE;
new Handle:TimerInfectedDamageCheck[MAXPLAYERS + 1];

new Handle:cvar_TankDamageCap = INVALID_HANDLE;
new Handle:cvar_TankDamageTotal = INVALID_HANDLE;
new Handle:cvar_TankDamageTotalSuccess = INVALID_HANDLE;

new ChargerCarryVictim[MAXPLAYERS + 1];
new ChargerPlummelVictim[MAXPLAYERS + 1];
new JockeyVictim[MAXPLAYERS + 1];
new JockeyRideStartTime[MAXPLAYERS + 1];

new SmokerDamageCounter[MAXPLAYERS + 1];
new SpitterDamageCounter[MAXPLAYERS + 1];
new JockeyDamageCounter[MAXPLAYERS + 1];
new ChargerDamageCounter[MAXPLAYERS + 1];
new TankDamageCounter[MAXPLAYERS + 1];
new TankDamageTotalCounter[MAXPLAYERS + 1];
new TankPointsCounter[MAXPLAYERS + 1];
new TankSurvivorKillCounter[MAXPLAYERS + 1];
new Handle:cvar_TankThrowRockSuccess = INVALID_HANDLE;

new Handle:cvar_PlayerLedgeSuccess = INVALID_HANDLE;
new Handle:cvar_Matador = INVALID_HANDLE;

new ClientInfectedType[MAXPLAYERS + 1];

new PlayerBlinded[MAXPLAYERS + 1][2];
new PlayerParalyzed[MAXPLAYERS + 1][2];
new PlayerLunged[MAXPLAYERS + 1][2];
new PlayerPlummeled[MAXPLAYERS + 1][2];
new PlayerCarried[MAXPLAYERS + 1][2];
new PlayerJockied[MAXPLAYERS + 1][2];

// Rank panel vars
new RankTotal = 0;
new ClientRank[MAXPLAYERS + 1];
new ClientNextRank[MAXPLAYERS + 1];
new ClientPoints[MAXPLAYERS + 1];
new GameModeRankTotal = 0;
new ClientGameModeRank[MAXPLAYERS + 1];
new ClientGameModePoints[MAXPLAYERS + 1][GAMEMODES];

// Misc arrays
new TimerPoints[MAXPLAYERS + 1];
new TimerKills[MAXPLAYERS + 1];
new TimerHeadshots[MAXPLAYERS + 1];
new Pills[4096];
new Adrenaline[4096];

new String:QueryBuffer[MAX_QUERY_COUNTER][MAX_QUERY_COUNTER];
new QueryCounter = 0;

// For every medkit used the points earned by the Survivor team is calculated with this formula:
// NormalPointsEarned * (1 - MedkitsUsedCounter * cvar_MedkitUsedPointPenalty)
// Minimum formula result = 0 (Cannot be negative)
new MedkitsUsedCounter = 0;
new Handle:cvar_MedkitUsedPointPenalty = INVALID_HANDLE;
new Handle:cvar_MedkitUsedPointPenaltyMax = INVALID_HANDLE;
new Handle:cvar_MedkitUsedFree = INVALID_HANDLE;
new Handle:cvar_MedkitBotMode = INVALID_HANDLE;

new ProtectedFriendlyCounter[MAXPLAYERS + 1];
new Handle:TimerProtectedFriendly[MAXPLAYERS + 1];

// Announce rank
new Handle:TimerRankChangeCheck[MAXPLAYERS + 1];
new RankChangeLastRank[MAXPLAYERS + 1];
new bool:RankChangeFirstCheck[MAXPLAYERS + 1];

// MapTiming
new Float:MapTimingStartTime = -1.0;
new Handle:MapTimingSurvivors = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:MapTimingInfected = INVALID_HANDLE; // Survivors at the beginning of the map

// When an admin calls for clear database, the client id is stored here for a period of time.
// The admin must then call the clear command again to confirm the call. After the second call
// the database is cleared. The confirm must be done in the time set by CLEAR_DATABASE_CONFIRMTIME.
new ClearDatabaseCaller = -1;
new Handle:ClearDatabaseTimer = INVALID_HANDLE;
//new Handle:ClearPlayerMenu = INVALID_HANDLE;

// Create handle for the admin menu
new Handle:RankAdminMenu = INVALID_HANDLE;
new TopMenuObject:MenuClear = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearPlayers = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearMaps = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearAll = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuRemoveCustomMaps = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuCleanPlayers = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearTimedMaps = INVALID_TOPMENUOBJECT;

// Administrative Cvars
new Handle:cvar_AdminPlayerCleanLastOnTime = INVALID_HANDLE;
new Handle:cvar_AdminPlayerCleanPlatime = INVALID_HANDLE;

// Players can request a vote for team shuffle based on the player ranks ONCE PER MAP
new PlayerRankVote[MAXPLAYERS + 1];
new Handle:RankVoteTimer = INVALID_HANDLE;
new Handle:PlayerRankVoteTrie = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:cvar_RankVoteTime = INVALID_HANDLE;

new bool:SurvivalStarted = false;

new Handle:L4DStatsConf = INVALID_HANDLE;
new Handle:L4DStatsSHS = INVALID_HANDLE;
new Handle:L4DStatsTOB = INVALID_HANDLE;

// Plugin Info
public Plugin:myinfo =
{
	name = "Custom Player Stats",
	author = "Mikko Andersson (muukis)",
	description = "Player Stats and Ranking for Left 4 Dead and Left 4 Dead 2. This plugin is derivated from msleeper L4D Player Stats plugin.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com/"
};

// Here we go!
public OnPluginStart()
{
	// Require Left 4 Dead (2)
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead", false) &&
			!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return;
	}

	// Init MySQL connections
	if (!ConnectDB())
	{
		SetFailState("Connecting to database failed. Read error log for further details.");
		return;
	}

	ServerVersion = GuessSDKVersion();

	// Plugin version public Cvar
	CreateConVar("l4d_stats_version", PLUGIN_VERSION, "Custom Player Stats Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Disable setting Cvars
	cvar_Difficulty = FindConVar("z_difficulty");
	cvar_Gamemode = FindConVar("mp_gamemode");
	cvar_Cheats = FindConVar("sv_cheats");

	cvar_SurvivorLimit = FindConVar("survivor_limit");
	cvar_InfectedLimit = FindConVar("z_max_player_zombies");

	// Administrative Cvars
	cvar_AdminPlayerCleanLastOnTime = CreateConVar("l4d_stats_adm_cleanoldplayers", "2", "How many months old players (last online time) will be cleaned. 0 = Disabled", FCVAR_PLUGIN, true, 0.0);
	cvar_AdminPlayerCleanPlatime = CreateConVar("l4d_stats_adm_cleanplaytime", "30", "How many minutes of playtime to not get cleaned from stats. 0 = Disabled", FCVAR_PLUGIN, true, 0.0);

	// Config/control Cvars
	cvar_EnableRankVote = CreateConVar("l4d_stats_enablerankvote", "1", "Enable voting of team shuffle by player PPM (Points Per Minute)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_HumansNeeded = CreateConVar("l4d_stats_minhumans", "2", "Minimum Human players before stats will be enabled", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	cvar_UpdateRate = CreateConVar("l4d_stats_updaterate", "90", "Number of seconds between Common Infected point earn announcement/update", FCVAR_PLUGIN, true, 30.0);
	//cvar_AnnounceRankMinChange = CreateConVar("l4d_stats_announcerankminpoint", "500", "Minimum change to points before rank change announcement", FCVAR_PLUGIN, true, 0.0);
	cvar_AnnounceRankChange = CreateConVar("l4d_stats_announcerank", "1", "Chat announcment for rank change", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AnnounceRankChangeIVal = CreateConVar("l4d_stats_announcerankinterval", "60", "Rank change check interval", FCVAR_PLUGIN, true, 10.0);
	cvar_AnnounceMode = CreateConVar("l4d_stats_announcemode", "1", "Chat announcment mode. 0 = Off, 1 = Player Only, 2 = Player Only w/ Public Headshots, 3 = All Public", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_AnnounceToTeam = CreateConVar("l4d_stats_announceteam", "2", "Chat announcment team messages to the team only mode. 0 = Print messages to all teams, 1 = Print messages to own team only, 2 = Print messages to own team and spectators only", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_MedkitMode = CreateConVar("l4d_stats_medkitmode", "0", "Medkit point award mode. 0 = Based on amount healed, 1 = Static amount", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SiteURL = CreateConVar("l4d_stats_siteurl", "", "Community site URL, for rank panel display", FCVAR_PLUGIN);
	cvar_RankOnJoin = CreateConVar("l4d_stats_rankonjoin", "1", "Display player's rank when they connect. 0 = Disable, 1 = Enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SilenceChat = CreateConVar("l4d_stats_silencechat", "0", "Silence chat triggers. 0 = Show chat triggers, 1 = Silence chat triggers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_DisabledMessages = CreateConVar("l4d_stats_disabledmessages", "1", "Show 'Stats Disabled' messages, allow chat commands to work when stats disabled. 0 = Hide messages/disable chat, 1 = Show messages/allow chat", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MaxPoints = CreateConVar("l4d_stats_maxpoints", "500", "Maximum number of points that can be earned in a single map. Normal = x1, Adv = x2, Expert = x3", FCVAR_PLUGIN, true, 500.0);
	cvar_DbPrefix = CreateConVar("l4d_stats_dbprefix", "", "Prefix for your stats tables", FCVAR_PLUGIN);
	cvar_LeaderboardTime = CreateConVar("l4d_stats_leaderboardtime", "14", "Time in days to show Survival Leaderboard times", FCVAR_PLUGIN, true, 1.0);
	cvar_EnableNegativeScore = CreateConVar("l4d_stats_enablenegativescore", "1", "Enable point losses (negative score)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FriendlyFireMode = CreateConVar("l4d_stats_ffire_mode", "2", "Friendly fire mode. 0 = Normal, 1 = Cooldown, 2 = Damage based", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_FriendlyFireMultiplier = CreateConVar("l4d_stats_ffire_multiplier", "1.5", "Friendly fire damage multiplier (Formula: Score = Damage * Multiplier)", FCVAR_PLUGIN, true, 0.0);
	cvar_FriendlyFireCooldown = CreateConVar("l4d_stats_ffire_cooldown", "10.0", "Time in seconds for friendly fire cooldown", FCVAR_PLUGIN, true, 1.0);
	cvar_FriendlyFireCooldownMode = CreateConVar("l4d_stats_ffire_cooldownmode", "1", "Friendly fire cooldown mode. 0 = Disable, 1 = Player specific, 2 = General", FCVAR_PLUGIN, true, 0.0, true, 2.0);

	// Game mode Cvars
	cvar_EnableCoop = CreateConVar("l4d_stats_enablecoop", "1", "Enable/Disable coop stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableSv = CreateConVar("l4d_stats_enablesv", "1", "Enable/Disable survival stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableVersus = CreateConVar("l4d_stats_enableversus", "1", "Enable/Disable versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableTeamVersus = CreateConVar("l4d_stats_enableteamversus", "1", "[L4D2] Enable/Disable team versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableRealism = CreateConVar("l4d_stats_enablerealism", "1", "[L4D2] Enable/Disable realism stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableScavenge = CreateConVar("l4d_stats_enablescavenge", "1", "[L4D2] Enable/Disable scavenge stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableTeamScavenge = CreateConVar("l4d_stats_enableteamscavenge", "1", "[L4D2] Enable/Disable team scavenge stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Game mode depended Cvars
	cvar_RealismMultiplier = CreateConVar("l4d_stats_realismmultiplier", "1.5", "[L4D2] Realism score multiplier for coop score", FCVAR_PLUGIN, true, 1.0);
	cvar_EnableSvMedicPoints = CreateConVar("l4d_stats_medicpointssv", "0", "Survival medic points enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Infected point Cvars
	cvar_Infected = CreateConVar("l4d_stats_infected", "1", "Base score for killing a Common Infected", FCVAR_PLUGIN, true, 1.0);
	cvar_Hunter = CreateConVar("l4d_stats_hunter", "2", "Base score for killing a Hunter", FCVAR_PLUGIN, true, 1.0);
	cvar_Smoker = CreateConVar("l4d_stats_smoker", "3", "Base score for killing a Smoker", FCVAR_PLUGIN, true, 1.0);
	cvar_Boomer = CreateConVar("l4d_stats_boomer", "5", "Base score for killing a Boomer", FCVAR_PLUGIN, true, 1.0);
	cvar_Spitter = CreateConVar("l4d_stats_spitter", "5", "[L4D2] Base score for killing a Spitter", FCVAR_PLUGIN, true, 1.0);
	cvar_Jockey = CreateConVar("l4d_stats_jockey", "5", "[L4D2] Base score for killing a Jockey", FCVAR_PLUGIN, true, 1.0);
	cvar_Charger = CreateConVar("l4d_stats_charger", "5", "[L4D2] Base score for killing a Charger", FCVAR_PLUGIN, true, 1.0);
	cvar_InfectedDamage = CreateConVar("l4d_stats_infected_damage", "2", "The amount of damage inflicted to Survivors to earn 1 point", FCVAR_PLUGIN, true, 1.0);

	// Misc personal gain Cvars
	cvar_Pills = CreateConVar("l4d_stats_pills", "15", "Base score for giving Pills to a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Adrenaline = CreateConVar("l4d_stats_adrenaline", "15", "[L4D2] Base score for giving Adrenaline to a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Medkit = CreateConVar("l4d_stats_medkit", "20", "Base score for using a Medkit on a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Defib = CreateConVar("l4d_stats_defib", "20", "[L4D2] Base score for using a Defibrillator on a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_SmokerDrag = CreateConVar("l4d_stats_smokerdrag", "5", "Base score for saving a friendly from a Smoker Tongue Drag", FCVAR_PLUGIN, true, 1.0);
	cvar_JockeyRide = CreateConVar("l4d_stats_jockeyride", "10", "[L4D2] Base score for saving a friendly from a Jockey Ride", FCVAR_PLUGIN, true, 1.0);
	cvar_ChargerPlummel = CreateConVar("l4d_stats_chargerplummel", "10", "[L4D2] Base score for saving a friendly from a Charger Plummel", FCVAR_PLUGIN, true, 1.0);
	cvar_ChargerCarry = CreateConVar("l4d_stats_chargercarry", "15", "[L4D2] Base score for saving a friendly from a Charger Carry", FCVAR_PLUGIN, true, 1.0);
	cvar_ChokePounce = CreateConVar("l4d_stats_chokepounce", "10", "Base score for saving a friendly from a Hunter Pounce / Smoker Choke", FCVAR_PLUGIN, true, 1.0);
	cvar_Revive = CreateConVar("l4d_stats_revive", "15", "Base score for Revive a friendly from Incapacitated state", FCVAR_PLUGIN, true, 1.0);
	cvar_Rescue = CreateConVar("l4d_stats_rescue", "10", "Base score for Rescue a friendly from a closet", FCVAR_PLUGIN, true, 1.0);
	cvar_Protect = CreateConVar("l4d_stats_protect", "3", "Base score for Protect a friendly in combat", FCVAR_PLUGIN, true, 1.0);
	cvar_PlayerLedgeSuccess = CreateConVar("l4d_stats_ledgegrap", "15", "Base score for causing a survivor to grap a ledge", FCVAR_PLUGIN, true, 1.0);
	cvar_Matador = CreateConVar("l4d_stats_matador", "30", "[L4D2] Base score for killing a charging Charger with a melee weapon", FCVAR_PLUGIN, true, 1.0);
	cvar_WitchCrowned = CreateConVar("l4d_stats_witchcrowned", "30", "Base score for Crowning a Witch", FCVAR_PLUGIN, true, 1.0);

	// Team gain Cvars
	cvar_Tank = CreateConVar("l4d_stats_tank", "25", "Base team score for killing a Tank", FCVAR_PLUGIN, true, 1.0);
	cvar_Panic = CreateConVar("l4d_stats_panic", "25", "Base team score for surviving a Panic Event with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
	cvar_BoomerMob = CreateConVar("l4d_stats_boomermob", "10", "Base team score for surviving a Boomer Mob with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
	cvar_SafeHouse = CreateConVar("l4d_stats_safehouse", "10", "Base score for reaching a Safe House", FCVAR_PLUGIN, true, 1.0);
	cvar_Witch = CreateConVar("l4d_stats_witch", "10", "Base score for Not Disturbing a Witch", FCVAR_PLUGIN, true, 1.0);
	cvar_VictorySurvivors = CreateConVar("l4d_stats_campaign", "5", "Base score for Completing a Campaign", FCVAR_PLUGIN, true, 1.0);
	cvar_VictoryInfected = CreateConVar("l4d_stats_infected_win", "30", "Base victory score for Infected Team", FCVAR_PLUGIN, true, 1.0);

	// Point loss Cvars
	cvar_FFire = CreateConVar("l4d_stats_ffire", "25", "Base score for Friendly Fire", FCVAR_PLUGIN, true, 1.0);
	cvar_FIncap = CreateConVar("l4d_stats_fincap", "75", "Base score for a Friendly Incap", FCVAR_PLUGIN, true, 1.0);
	cvar_FKill = CreateConVar("l4d_stats_fkill", "250", "Base score for a Friendly Kill", FCVAR_PLUGIN, true, 1.0);
	cvar_InSafeRoom = CreateConVar("l4d_stats_insaferoom", "5", "Base score for letting Infected in the Safe Room", FCVAR_PLUGIN, true, 1.0);
	cvar_Restart = CreateConVar("l4d_stats_restart", "100", "Base score for a Round Restart", FCVAR_PLUGIN, true, 1.0);
	cvar_MedkitUsedPointPenalty = CreateConVar("l4d_stats_medkitpenalty", "0.1", "Score reduction for all Survivor earned points for each used Medkit (Formula: Score = NormalPoints * (1 - MedkitsUsed * MedkitPenalty))", FCVAR_PLUGIN, true, 0.0, true, 0.5);
	cvar_MedkitUsedPointPenaltyMax = CreateConVar("l4d_stats_medkitpenaltymax", "1.0", "Maximum score reduction (the score reduction will not go over this value when a Medkit is used)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MedkitUsedFree = CreateConVar("l4d_stats_medkitpenaltyfree", "0", "The reduction to Survivors score will start after this many Medkits have been used", FCVAR_PLUGIN, true, 0.0);
	cvar_MedkitBotMode = CreateConVar("l4d_stats_medkitbotmode", "1", "Add score reduction when bot uses a medkit. 0 = No, 1 = Bot uses a Medkit to a human player, 2 = Bot uses a Medkit to other than itself, 3 = Yes", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_CarAlarm = CreateConVar("l4d_stats_caralarm", "50", "[L4D2] Base score for a Triggering Car Alarm", FCVAR_PLUGIN, true, 1.0);
	cvar_BotScoreMultiplier = CreateConVar("l4d_stats_botscoremultiplier", "1.0", "Multiplier to use when receiving bot related score penalty. 0 = Disable", FCVAR_PLUGIN, true, 0.0);

	// Survivor point Cvars
	cvar_SurvivorDeath = CreateConVar("l4d_stats_survivor_death", "40", "Base score for killing a Survivor", FCVAR_PLUGIN, true, 1.0);
	cvar_SurvivorIncap = CreateConVar("l4d_stats_survivor_incap", "15", "Base score for incapacitating a Survivor", FCVAR_PLUGIN, true, 1.0);

	// Hunter point Cvars
	cvar_HunterPerfectPounceDamage = CreateConVar("l4d_stats_perfectpouncedamage", "25", "The amount of damage from a pounce to earn Perfect Pounce (Death From Above) success points", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterPerfectPounceSuccess = CreateConVar("l4d_stats_perfectpouncesuccess", "25", "Base score for a successful Perfect Pounce", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterNicePounceDamage = CreateConVar("l4d_stats_nicepouncedamage", "15", "The amount of damage from a pounce to earn Nice Pounce (Pain From Above) success points", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterNicePounceSuccess = CreateConVar("l4d_stats_nicepouncesuccess", "10", "Base score for a successful Nice Pounce", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterDamageCap = CreateConVar("l4d_stats_hunterdamagecap", "25", "Hunter stored damage cap", FCVAR_PLUGIN, true, 25.0);

	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		MaxPounceDistance = GetConVarInt(FindConVar("z_pounce_damage_range_max"));
		MinPounceDistance = GetConVarInt(FindConVar("z_pounce_damage_range_min"));
	}
	else
	{
		MaxPounceDistance = 1024;
		MinPounceDistance = 300;
	}
	MaxPounceDamage = GetConVarInt(FindConVar("z_hunter_max_pounce_bonus_damage"));


	// Boomer point Cvars
	cvar_BoomerSuccess = CreateConVar("l4d_stats_boomersuccess", "5", "Base score for a successfully vomiting on a survivor", FCVAR_PLUGIN, true, 1.0);
	cvar_BoomerPerfectHits = CreateConVar("l4d_stats_boomerperfecthits", "4", "The number of survivors that needs to get blinded to earn Boomer Perfect Vomit Award and success points", FCVAR_PLUGIN, true, 4.0);
	cvar_BoomerPerfectSuccess = CreateConVar("l4d_stats_boomerperfectsuccess", "30", "Base score for a successful Boomer Perfect Vomit", FCVAR_PLUGIN, true, 1.0);

	// Tank point Cvars
	cvar_TankDamageCap = CreateConVar("l4d_stats_tankdmgcap", "500", "Maximum inflicted damage done by Tank to earn Infected damagepoints", FCVAR_PLUGIN, true, 150.0);
	cvar_TankDamageTotal = CreateConVar("l4d_stats_bulldozer", "200", "Damage inflicted by Tank to earn Bulldozer Award and success points", FCVAR_PLUGIN, true, 200.0);
	cvar_TankDamageTotalSuccess = CreateConVar("l4d_stats_bulldozersuccess", "50", "Base score for Bulldozer Award", FCVAR_PLUGIN, true, 1.0);
	cvar_TankThrowRockSuccess = CreateConVar("l4d_stats_tankthrowrocksuccess", "5", "Base score for a Tank thrown rock hit", FCVAR_PLUGIN, true, 0.0);

	// Misc L4D2 Cvars
	cvar_AmmoUpgradeAdded = CreateConVar("l4d_stats_deployammoupgrade", "10", "[L4D2] Base score for deploying ammo upgrade pack", FCVAR_PLUGIN, true, 0.0);
	cvar_GascanPoured = CreateConVar("l4d_stats_gascanpoured", "5", "[L4D2] Base score for successfully pouring a gascan", FCVAR_PLUGIN, true, 0.0);

	cvar_RankVoteTime = CreateConVar("l4d_stats_rankvotetime", "20", "Time to wait people to vote", FCVAR_PLUGIN, true, 10.0);

	// Make that config!
	AutoExecConfig(true, "l4d_stats");

	// Personal Gain Events
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("infected_death", event_InfectedDeath);
	HookEvent("tank_killed", event_TankKilled);
	if (ServerVersion == SERVER_VERSION_L4D1)
		HookEvent("weapon_given", event_GivePills);
	else
		HookEvent("defibrillator_used", event_DefibPlayer);
	HookEvent("heal_success", event_HealPlayer);
	HookEvent("revive_success", event_RevivePlayer);
	HookEvent("tongue_pull_stopped", event_TongueSave);
	HookEvent("choke_stopped", event_ChokeSave);
	HookEvent("pounce_stopped", event_PounceSave);
	HookEvent("lunge_pounce", event_PlayerPounced);
	HookEvent("player_ledge_grab", event_PlayerLedge);
	HookEvent("player_falldamage", event_PlayerFallDamage);

	// Personal Loss Events
	HookEvent("friendly_fire", event_FriendlyFire);
	HookEvent("player_incapacitated", event_PlayerIncap);

	// Team Gain Events
	HookEvent("finale_vehicle_leaving", event_CampaignWin);
	HookEvent("map_transition", event_MapTransition);
	HookEvent("create_panic_event", event_PanicEvent);
	HookEvent("player_now_it", event_PlayerBlind);
	HookEvent("player_no_longer_it", event_PlayerBlindEnd);

	// Team Loss Events / Misc. Events
	if (ServerVersion == SERVER_VERSION_L4D1)
		HookEvent("award_earned", event_Award_L4D1);
	else
		HookEvent("award_earned", event_Award_L4D2);
	HookEvent("witch_spawn", event_WitchSpawn);
	HookEvent("witch_killed", event_WitchCrowned);
	HookEvent("witch_harasser_set", event_WitchDisturb);
	HookEvent("round_start", event_RoundStart);

	// Record player positions when an ability is used
	HookEvent("ability_use", event_AbilityUse);

	// Set player specific counters (BoomerHitCounter etc)
	HookEvent("player_spawn", event_PlayerSpawn);

	// Set player specific counters (BoomerHitCounter etc)
	HookEvent("player_hurt", event_PlayerHurt);

	// Smoker stats
	HookEvent("tongue_grab", event_SmokerGrap);
	HookEvent("tongue_release", event_SmokerRelease);
	if (ServerVersion == SERVER_VERSION_L4D1)
		HookEvent("tongue_broke_victim_died", event_SmokerRelease);
	HookEvent("choke_end", event_SmokerRelease);
	HookEvent("tongue_broke_bent", event_SmokerRelease);
	// Hooked previously ^
	//HookEvent("choke_stopped", event_SmokerRelease);
	//HookEvent("tongue_pull_stopped", event_SmokerRelease);

	// Hunter stats
	HookEvent("pounce_end", event_HunterRelease);

	if (ServerVersion != SERVER_VERSION_L4D1)
	{
		// Spitter stats
		//HookEvent("spitter_killed", event_SpitterKilled);

		// Jockey stats
		HookEvent("jockey_ride", event_JockeyStart);
		HookEvent("jockey_ride_end", event_JockeyRelease);
		HookEvent("jockey_killed", event_JockeyKilled);

		// Charger stats
		//HookEvent("charger_impact", event_ChargerImpact);
		HookEvent("charger_killed", event_ChargerKilled);
		HookEvent("charger_carry_start", event_ChargerCarryStart);
		HookEvent("charger_carry_end", event_ChargerCarryRelease);
		HookEvent("charger_pummel_start", event_ChargerPummelStart);
		HookEvent("charger_pummel_end", event_ChargerPummelRelease);

		// Misc L4D2 events
		HookEvent("upgrade_pack_used", event_UpgradePackAdded);
		HookEvent("gascan_pour_completed", event_GascanPoured);
		HookEvent("triggered_car_alarm", event_CarAlarm);
		HookEvent("survival_round_start", event_SurvivalStart); // Timed Maps event
		HookEvent("scavenge_round_halftime", event_ScavengeHalftime);
		HookEvent("scavenge_round_start", event_ScavengeRoundStart);
	}

	// Achievements
	HookEvent("achievement_earned", event_Achievement);

	// Timed Maps events
	HookEvent("door_open", event_DoorOpen, EventHookMode_Post); // When the saferoom door opens...
	HookEvent("player_left_start_area", event_StartArea, EventHookMode_Post); // When a survivor leaves the start area...
	HookEvent("player_team", event_PlayerTeam, EventHookMode_Post); // When a survivor changes team...

	// Startup the plugin's timers
	//CreateTimer(1.0, InitPlayers); // Called in OnMapStart
	CreateTimer(60.0, timer_UpdatePlayers, INVALID_HANDLE, TIMER_REPEAT);
	UpdateTimer = CreateTimer(GetConVarFloat(cvar_UpdateRate), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	HookConVarChange(cvar_UpdateRate, action_TimerChanged);

	// Register chat commands for rank panels
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);

	// Register console commands for rank panels
	RegConsoleCmd("sm_rank", cmd_ShowRank);
	RegConsoleCmd("sm_top10", cmd_ShowTop10);
	RegConsoleCmd("sm_top10ppm", cmd_ShowTop10PPM);
	RegConsoleCmd("sm_nextrank", cmd_ShowNextRank);
	RegConsoleCmd("sm_showtimer", cmd_ShowTimedMapsTimer);
	RegConsoleCmd("sm_showrank", cmd_ShowRanks);
	RegConsoleCmd("sm_showppm", cmd_ShowPPMs);
	RegConsoleCmd("sm_rankvote", cmd_RankVote);

	// Register administrator command for clearing all stats (BE CAREFUL)
	//RegAdminCmd("sm_rank_admin", cmd_RankAdmin, ADMFLAG_ROOT, "Display admin panel for Rank");
	RegAdminCmd("sm_rank_clear", cmd_ClearRank, ADMFLAG_ROOT, "Clear all stats from database (asks a confirmation before clearing the database)");
	RegAdminCmd("sm_rank_shuffle", cmd_ShuffleTeams, ADMFLAG_KICK, "Shuffle teams by player PPM (Points Per Minute)");

	// Gamemode
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
	HookConVarChange(cvar_Gamemode, action_GamemodeChanged);
	HookConVarChange(cvar_Difficulty, action_DifficultyChanged);

	//RegConsoleCmd("l4d_stats_test", cmd_StatsTest);

	MapTimingSurvivors = CreateTrie();
	MapTimingInfected = CreateTrie();
	FriendlyFireDamageTrie = CreateTrie();
	PlayerRankVoteTrie = CreateTrie();

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);

	if (FileExists("addons/sourcemod/gamedata/l4d_stats.txt"))
	{
		// SDK handles for team shuffle
		L4DStatsConf = LoadGameConfigFile("l4d_stats");
		if (L4DStatsConf == INVALID_HANDLE)
			LogError("Could not load gamedata/l4d_stats.txt");
		else
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DStatsConf, SDKConf_Signature, "SetHumanSpec");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			L4DStatsSHS = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DStatsConf, SDKConf_Signature, "TakeOverBot");
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			L4DStatsTOB = EndPrepSDKCall();
		}
	}
	else
		LogMessage("Rank Vote is disabled because could not load gamedata/l4d_stats.txt");

	ResetInfVars();
}

// Load our categories and menus

public OnAdminMenuReady(Handle:TopMenu)
{
	// Block us from being called twice
	if (TopMenu == RankAdminMenu)
		return;

	RankAdminMenu = TopMenu;

	// Add a category to the SourceMod menu called "Player Stats"
	AddToTopMenu(RankAdminMenu, "Player Stats", TopMenuObject_Category, ClearRankCategoryHandler, INVALID_TOPMENUOBJECT);

	// Get a handle for the catagory we just added so we can add items to it
	new TopMenuObject:statscommands = FindTopMenuCategory(RankAdminMenu, "Player Stats");

	// Don't attempt to add items to the catagory if for some reason the catagory doesn't exist
	if (statscommands == INVALID_TOPMENUOBJECT)
		return;

	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically
	// Assign the menus to global values so we can easily check what a menu is when it is chosen
	MenuClearPlayers = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clearplayers", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearplayers", ADMFLAG_ROOT);
	MenuClearMaps = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clearallmaps", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearallmaps", ADMFLAG_ROOT);
	MenuClearAll = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clearall", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearall", ADMFLAG_ROOT);
	MenuClearTimedMaps = AddToTopMenu(RankAdminMenu, "sm_rank_admin_cleartimedmaps", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_cleartimedmaps", ADMFLAG_ROOT);
	MenuRemoveCustomMaps = AddToTopMenu(RankAdminMenu, "sm_rank_admin_removecustom", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_removecustom", ADMFLAG_ROOT);
	MenuCleanPlayers = AddToTopMenu(RankAdminMenu, "sm_rank_admin_removeplayers", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_removeplayers", ADMFLAG_ROOT);
	MenuClear = AddToTopMenu(RankAdminMenu, "sm_rank_admin_clear", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clear", ADMFLAG_ROOT);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		RankAdminMenu = INVALID_HANDLE;
}

// This handles the top level "Player Stats" category and how it is displayed on the core admin menu

public ClearRankCategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Player Stats");
	else if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "Player Stats:");
}

public Action:Menu_CreateClearMenu(client, args)
{
	new Handle:menu = CreateMenu(Menu_CreateClearMenuHandler);

	SetMenuTitle(menu, "Clear:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "cps", "Clear stats from currently playing player...");
	AddMenuItem(menu, "ctm", "Clear timed maps...");

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Menu_CreateClearMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					DisplayClearPanel(param1);
				}
				case 1:
				{
					Menu_CreateClearTMMenu(param1, 0);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && RankAdminMenu != INVALID_HANDLE)
				DisplayTopMenu(RankAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
}

public Action:Menu_CreateClearTMMenu(client, args)
{
	new Handle:menu = CreateMenu(Menu_CreateClearTMMenuHandler);

	SetMenuTitle(menu, "Clear Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "ctma",  "All");
	AddMenuItem(menu, "ctmc",  "Coop");
	AddMenuItem(menu, "ctmsu", "Survival");
	AddMenuItem(menu, "ctmr",  "Realism");

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Menu_CreateClearTMMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all map timings?", ClearTMAllPanelHandler);
				}
				case 1:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all map Coop timings?", ClearTMCoopPanelHandler);
				}
				case 2:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all map Survival timings?", ClearTMSurvivalPanelHandler);
				}
				case 3:
				{
					DisplayYesNoPanel(param1, "Do you really want to clear all map Realism timings?", ClearTMRealismPanelHandler);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && RankAdminMenu != INVALID_HANDLE)
				DisplayTopMenu(RankAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
}

// This deals with what happens someone opens the "Player Stats" category from the menu
public ClearRankTopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	// When an item is displayed to a player tell the menu to format the item
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == MenuClearPlayers)
			Format(buffer, maxlength, "Clear players");
		else if (object_id == MenuClearMaps)
			Format(buffer, maxlength, "Clear maps");
		else if (object_id == MenuClearAll)
			Format(buffer, maxlength, "Clear all");
		else if (object_id == MenuClearTimedMaps)
			Format(buffer, maxlength, "Clear timed maps");
		else if (object_id == MenuRemoveCustomMaps)
			Format(buffer, maxlength, "Remove custom maps");
		else if (object_id == MenuCleanPlayers)
			Format(buffer, maxlength, "Clean players");
		else if (object_id == MenuClear)
			Format(buffer, maxlength, "Clear...");
	}

	// When an item is selected do the following
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == MenuClearPlayers)
			DisplayYesNoPanel(client, "Do you really want to clear the player stats?", ClearPlayersPanelHandler);
		else if (object_id == MenuClearMaps)
			DisplayYesNoPanel(client, "Do you really want to clear the map stats?", ClearMapsPanelHandler);
		else if (object_id == MenuClearAll)
			DisplayYesNoPanel(client, "Do you really want to clear all stats?", ClearAllPanelHandler);
		else if (object_id == MenuClearTimedMaps)
			DisplayYesNoPanel(client, "Do you really want to clear all map timings?", ClearTMAllPanelHandler);
		else if (object_id == MenuRemoveCustomMaps)
			DisplayYesNoPanel(client, "Do you really want to remove the custom maps?", RemoveCustomMapsPanelHandler);
		else if (object_id == MenuCleanPlayers)
			DisplayYesNoPanel(client, "Do you really want to clean the player stats?", CleanPlayersPanelHandler);
		else if (object_id == MenuClear)
			Menu_CreateClearMenu(client, 0);
	}
}

// Reset all boolean variables when a map changes.

public OnMapStart()
{
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
	ResetVars();

	ClearTrie(PlayerRankVoteTrie);
}

// Init player on connect, and update total rank and client rank.

public OnClientPostAdminCheck(client)
{
	if (db == INVALID_HANDLE)
		return;

	InitializeClientInf(client);

	if (IsClientBot(client))
		return;

	StartRankChangeCheck(client);

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	CheckPlayerDB(client);

	TimerPoints[client] = 0;
	TimerKills[client] = 0;
	TimerHeadshots[client] = 0;

	CreateTimer(10.0, RankConnect, client);
}

public OnPluginEnd()
{
	if (db == INVALID_HANDLE)
		return;

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}

	CloseHandle(db);

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}
}

// Show rank on connect.

public Action:RankConnect(Handle:timer, any:value)
{
	if (GetConVarBool(cvar_RankOnJoin) && !InvalidGameMode())
		cmd_ShowRank(value, 0);
}

// Update the player's interstitial stats, since they may have
// gotten points between the last update and when they disconnect.

public OnClientDisconnect(client)
{
	InitializeClientInf(client);
	PlayerRankVote[client] = RANKVOTE_NOVOTE;

	if (TimerRankChangeCheck[client] != INVALID_HANDLE)
		CloseHandle(TimerRankChangeCheck[client]);

	TimerRankChangeCheck[client] = INVALID_HANDLE;

	if (IsClientBot(client))
		return;

	if (MapTimingStartTime >= 0.0)
	{
		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientName(client, ClientID, sizeof(ClientID));

		RemoveFromTrie(MapTimingSurvivors, ClientID);
		RemoveFromTrie(MapTimingInfected, ClientID);
	}

	if (IsClientInGame(client))
	{
		switch (GetClientTeam(client))
		{
			case TEAM_SURVIVORS:
				InterstitialPlayerUpdate(client);
			case TEAM_INFECTED:
				DoInfectedFinalChecks(client);
		}
	}

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			return;
	}

	// If we get this far, ALL HUMAN PLAYERS LEFT THE SERVER
	CampaignOver = true;

	if (RankVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(RankVoteTimer);
		RankVoteTimer = INVALID_HANDLE;
	}
}

// Update the Update Timer when the Cvar is changed.

public action_TimerChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_UpdateRate)
	{
		CloseHandle(UpdateTimer);

		new NewTime = StringToInt(newValue);
		UpdateTimer = CreateTimer(float(NewTime), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	}
}

// Update the CurrentGamemode when the Cvar is changed.

public action_DifficultyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PrintToChatAll("action_DifficultyChanged");
	if (convar == cvar_Difficulty)
		MapTimingStartTime = -1.0;
}

// Update the CurrentGamemode when the Cvar is changed.

public action_GamemodeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_Gamemode)
	{
		GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
		CurrentGamemodeID = GetCurrentGamemodeID();
		SetCurrentGamemodeName();
	}
}

public SetCurrentGamemodeName()
{
	switch (CurrentGamemodeID)
	{
		case GAMEMODE_COOP:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Coop");
		}
		case GAMEMODE_VERSUS:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Versus");
		}
		case GAMEMODE_REALISM:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Scavenge");
		}
		default:
		{
			Format(CurrentGamemodeLabel, sizeof(CurrentGamemodeLabel), "Unknown");
		}
	}
}

// Scavenge round start event (occurs when door opens or players leave the start area)

public Action:event_ScavengeRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	event_RoundStart(event, name, dontBroadcast);

	StartMapTiming();
}

// Called after the connection to the database is established

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetVars();
	CheckCurrentMapDB();

	MapTimingStartTime = 0.0;

	ResetRankChangeCheck();
}

// Make connection to database.

bool:ConnectDB()
{
	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		new String:Error[256];
		db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
		{
			LogError("Failed to connect to database: %s", Error);
			return false;
		}
		else if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
		{
			if (SQL_GetError(db, Error, sizeof(Error)))
				LogError("Failed to update encoding to UTF8: %s", Error);
			else
				LogError("Failed to update encoding to UTF8: unknown");
		}
	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		return false;
	}

	return true;
}

public Action:timer_ProtectedFriendly(Handle:timer, any:data)
{
	TimerProtectedFriendly[data] = INVALID_HANDLE;
	new ProtectedFriendlies = ProtectedFriendlyCounter[data];
	ProtectedFriendlyCounter[data] = 0;

	if (data == 0 || !IsClientConnected(data) || !IsClientInGame(data) || IsClientBot(data))
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Protect) * ProtectedFriendlies, 2, 3);
	AddScore(data, Score);

	UpdateMapStat("points", Score);

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientName(data, UserID, sizeof(UserID));
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(data, UserName, sizeof(UserName));

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_protect = award_protect + %i WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, ProtectedFriendlies, UserID);
	SendSQLUpdate(query);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			PrintToChat(data, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Protecting \x05%i friendlies\x01!", Score, ProtectedFriendlies);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Protecting \x05%i friendlies\x01!", UserName, Score, ProtectedFriendlies);
	}
}
// Team infected damage score

public Action:timer_InfectedDamageCheck(Handle:timer, any:data)
{
	TimerInfectedDamageCheck[data] = INVALID_HANDLE;

	if (data == 0 || IsClientBot(data))
		return;

	new InfectedDamage = GetConVarInt(cvar_InfectedDamage);

	new Score = 0;
	new DamageCounter = 0;

	if (InfectedDamage > 1)
	{
		if (InfectedDamageCounter[data] < InfectedDamage)
			return;

		new TotalDamage = InfectedDamageCounter[data];

		while (TotalDamage >= InfectedDamage)
		{
			DamageCounter += InfectedDamage;
			TotalDamage -= InfectedDamage;
			Score++;
		}
	}
	else
	{
		DamageCounter = InfectedDamageCounter[data];
		Score = InfectedDamageCounter[data];
	}

	Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5);

	if (Score > 0)
	{
		InfectedDamageCounter[data] -= DamageCounter;

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];

		GetClientName(data, iID, sizeof(iID));

		new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;
		if (IsVersus)
			Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i WHERE steamid = '%s'", Score, iID);
		else
			Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i WHERE steamid = '%s'", Score, iID);

		SendSQLUpdate(query);

		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
		{
			if (InfectedDamage > 1)
				PrintToChat(data, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for doing \x04%i \x01points of damage to the Survivors!", Score, DamageCounter);
			else
				PrintToChat(data, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for doing damage to the Survivors!", Score, DamageCounter);
		}
		else if (Mode == 3)
		{
			decl String:Name[MAX_LINE_WIDTH];
			GetClientName(data, Name, sizeof(Name));
			if (InfectedDamage > 1)
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for doing \x04%i \x01points of damage to the Survivors!", Name, Score, DamageCounter);
			else
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for doing damage to the Survivors!", Name, Score, DamageCounter);
		}
	}
}

// Get Boomer points

GetBoomerPoints(VictimCount)
{
	if (VictimCount <= 0)
		return 0;

	return GetConVarInt(cvar_BoomerSuccess) * VictimCount;
}

// Calculate Boomer vomit hits and check Boomer Perfect Blindness award

public Action:timer_BoomerBlindnessCheck(Handle:timer, any:data)
{
	TimerBoomerPerfectCheck[data] = INVALID_HANDLE;

	if (data > 0 && !IsClientBot(data) && BoomerHitCounter[data] > 0)
	{
		new HitCounter = BoomerHitCounter[data];
		BoomerHitCounter[data] = 0;
		new OriginalHitCounter = HitCounter;
		new BoomerPerfectHits = GetConVarInt(cvar_BoomerPerfectHits);
		new BoomerPerfectSuccess = GetConVarInt(cvar_BoomerPerfectSuccess);
		new Score = 0;
		new AwardCounter = 0;

		//PrintToConsole(0, "timer_BoomerBlindnessCheck -> HitCounter = %i / BoomerPerfectHits = %i", HitCounter, BoomerPerfectHits);

		while (HitCounter >= BoomerPerfectHits)
		{
			HitCounter -= BoomerPerfectHits;
			Score += BoomerPerfectSuccess;
			AwardCounter++;
			//PrintToConsole(0, "timer_BoomerBlindnessCheck -> Score = %i", Score);
		}

		Score += GetBoomerPoints(HitCounter);
		//PrintToConsole(0, "timer_BoomerBlindnessCheck -> Total Score = %i", Score);
		Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5);

		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];
		GetClientName(data, iID, sizeof(iID));

		new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;
		if (IsVersus)
			Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
		else
			Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);

		SendSQLUpdate(query);

		if (!BoomerVomitUpdated[data])
			UpdateMapStat("infected_boomer_vomits", 1);
		UpdateMapStat("infected_boomer_blinded", HitCounter);

		BoomerVomitUpdated[data] = false;

		if (Score > 0)
		{
			UpdateMapStat("points_infected", Score);

			new Mode = GetConVarInt(cvar_AnnounceMode);

			if (Mode == 1 || Mode == 2)
			{
				if (AwardCounter > 0)
					PrintToChat(data, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points from \x05Perfect Blindness\x01!", Score);
				else
					PrintToChat(data, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for blinding \x05%i Survivors\x01!", Score, OriginalHitCounter);
			}
			else if (Mode == 3)
			{
				decl String:Name[MAX_LINE_WIDTH];
				GetClientName(data, Name, sizeof(Name));
				if (AwardCounter > 0)
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points from \x05Perfect Blindness\x01!", Name, Score);
				else
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for blinding \x05%i Survivors\x01!", Name, Score, OriginalHitCounter);
			}
		}
	}
}


// Perform player init.

public Action:InitPlayers(Handle:timer)
{
	if (db == INVALID_HANDLE)
		return;

	SQL_TQuery(db, GetRankTotal, "SELECT COUNT(*) FROM players");

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			CheckPlayerDB(i);

			QueryClientPoints(i);

			TimerPoints[i] = 0;
			TimerKills[i] = 0;
		}
	}
}

QueryClientPoints(Client, SQLTCallback:callback=INVALID_HANDLE)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientName(Client, SteamID, sizeof(SteamID));
	QueryClientPointsSteamID(Client, SteamID, callback);
}

QueryClientPointsSteamID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_HANDLE)
{
	if (callback == INVALID_HANDLE)
		callback = GetClientPoints;

	decl String:query[256];

	Format(query, sizeof(query), "SELECT %s FROM players WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, SteamID);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientPointsDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[1024], String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));

	Format(query, sizeof(query), "SELECT %s FROM players WHERE steamid = '%s'", DB_PLAYERS_TOTALPOINTS, SteamID);

	SQL_TQuery(db, callback, query, dp);
}

QueryClientRank(Client, SQLTCallback:callback=INVALID_HANDLE)
{
	if (callback == INVALID_HANDLE)
		callback = GetClientRank;

	decl String:query[256];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE points + points_survival + points_realism + points_survivors + points_infected + points_scavenge_survivors + points_scavenge_infected >= %i", ClientPoints[Client]);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientRankDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[256];

	ResetPack(dp);

	new Client = ReadPackCell(dp);

	Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE points + points_survival + points_realism + points_survivors + points_infected + points_scavenge_survivors + points_scavenge_infected >= %i", ClientPoints[Client]);

	SQL_TQuery(db, callback, query, dp);
}

QueryClientGameModeRank(Client, SQLTCallback:callback=INVALID_HANDLE)
{
	if (!InvalidGameMode())
	{
		if (callback == INVALID_HANDLE)
			callback = GetClientGameModeRank;

		decl String:query[256];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", ClientGameModePoints[Client][1]);
			}
			case GAMEMODE_REALISM:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_realism > 0 AND points_realism >= %i", ClientGameModePoints[Client][2]);
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_survival > 0 AND points_survival >= %i", ClientGameModePoints[Client][3]);
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", ClientGameModePoints[Client][4]);
			}
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime > 0 AND points >= %i", ClientGameModePoints[Client][0]);
			}
		}

		SQL_TQuery(db, callback, query, Client);
	}
}

QueryClientGameModeRankDP(Handle:dp, SQLTCallback:callback)
{
	if (!InvalidGameMode())
	{
		decl String:query[1024];

		ResetPack(dp);

		new Client = ReadPackCell(dp);

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_versus > 0 AND points_survivors + points_infected >= %i", ClientGameModePoints[Client][1]);
			}
			case GAMEMODE_REALISM:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_realism > 0 AND points_realism >= %i", ClientGameModePoints[Client][2]);
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_survival > 0 AND points_survival >= %i", ClientGameModePoints[Client][3]);
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_scavenge > 0 AND points_scavenge_survivors + points_scavenge_infected >= %i", ClientGameModePoints[Client][4]);
			}
			default:
			{
				Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime > 0 AND points >= %i", ClientGameModePoints[Client][0]);
			}
		}

		SQL_TQuery(db, callback, query, dp);
	}
}

QueryClientGameModePoints(Client, SQLTCallback:callback=INVALID_HANDLE)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientName(Client, SteamID, sizeof(SteamID));
	QueryClientGameModePointsStmID(Client, SteamID, callback);
}

QueryClientGameModePointsStmID(Client, const String:SteamID[], SQLTCallback:callback=INVALID_HANDLE)
{
	if (cbGetRankTotal == INVALID_HANDLE)
		callback = GetClientGameModePoints;

	decl String:query[1024];

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected FROM players WHERE steamid = '%s'", SteamID);

	SQL_TQuery(db, callback, query, Client);
}

QueryClientGameModePointsDP(Handle:dp, SQLTCallback:callback)
{
	decl String:query[1024], String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected, points_realism, points_survival, points_scavenge_survivors + points_scavenge_infected FROM players WHERE steamid = '%s'", SteamID);

	SQL_TQuery(db, callback, query, dp);
}

QueryRanks()
{
	QueryRank_1();
	QueryRank_2();
}

QueryRank_1(Handle:dp=INVALID_HANDLE, SQLTCallback:callback=INVALID_HANDLE)
{
	if (callback == INVALID_HANDLE)
		callback = GetRankTotal;

	decl String:query[1024];

	Format(query, sizeof(query), "SELECT COUNT(*) FROM players");

	SQL_TQuery(db, callback, query, dp);
}

QueryRank_2(Handle:dp=INVALID_HANDLE, SQLTCallback:callback=INVALID_HANDLE)
{
	if (callback == INVALID_HANDLE)
		callback = GetGameModeRankTotal;

	decl String:query[1024];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_versus > 0");
		}
		case GAMEMODE_REALISM:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_realism > 0");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_survival > 0");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_scavenge > 0");
		}
		default:
		{
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime > 0");
		}
	}

	SQL_TQuery(db, callback, query, dp);
}

QueryClientStats(Client, CallingMethod=CM_UNKNOWN)
{
	decl String:SteamID[MAX_LINE_WIDTH];

	GetClientName(Client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(Client, SteamID, CallingMethod);
}

QueryClientStatsSteamID(Client, const String:SteamID[], CallingMethod=CM_UNKNOWN)
{
	new Handle:dp = CreateDataPack();

	WritePackCell(dp, Client);
	WritePackString(dp, SteamID);
	WritePackCell(dp, CallingMethod);

	QueryClientStatsDP(dp);
}

QueryClientStatsDP(Handle:dp)
{
	QueryClientGameModePointsDP(dp, QueryClientStatsDP_1);
}

public QueryClientStatsDP_1(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_1 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientGameModePoints(owner, hndl, error, ReadPackCell(dp));

	QueryClientPointsDP(dp, QueryClientStatsDP_2);
}

public QueryClientStatsDP_2(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_2 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientPoints(owner, hndl, error, ReadPackCell(dp));

	QueryClientGameModeRankDP(dp, QueryClientStatsDP_3);
}

public QueryClientStatsDP_3(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_3 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientGameModeRank(owner, hndl, error, ReadPackCell(dp));

	QueryClientRankDP(dp, QueryClientStatsDP_4);
}

public QueryClientStatsDP_4(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_4 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetClientRank(owner, hndl, error, ReadPackCell(dp));

	QueryRank_1(dp, QueryClientStatsDP_5);
}

public QueryClientStatsDP_5(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_5 Query failed: %s", error);
		return;
	}

	ResetPack(dp);
	GetRankTotal(owner, hndl, error, ReadPackCell(dp));

	QueryRank_2(dp, QueryClientStatsDP_6);
}

public QueryClientStatsDP_6(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("QueryClientStatsDP_6 Query failed: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];

	ResetPack(dp);

	new Client = ReadPackCell(dp);
	ReadPackString(dp, SteamID, sizeof(SteamID));
	new CallingMethod = ReadPackCell(dp);

	GetGameModeRankTotal(owner, hndl, error, Client);

	// Callback
	if (CallingMethod == CM_RANK)
		QueryClientStatsDP_Rank(Client, SteamID);
	else if (CallingMethod == CM_TOP10)
		QueryClientStatsDP_Top10(Client, SteamID);
	else if (CallingMethod == CM_NEXTRANK)
		QueryClientStatsDP_NextRank(Client, SteamID);
	else if (CallingMethod == CM_NEXTRANKFULL)
		QueryClientStatsDP_NextRankFull(Client, SteamID);

	// Clean your mess up
	CloseHandle(dp);
	dp = INVALID_HANDLE;
}

QueryClientStatsDP_Rank(Client, const String:SteamID[])
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors, headshots FROM players WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

QueryClientStatsDP_Top10(Client, const String:SteamID[])
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT name, %s, %s, kills, versus_kills_survivors + scavenge_kills_survivors, headshots FROM players WHERE steamid = '%s'", DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPOINTS, SteamID);
	SQL_TQuery(db, DisplayRank, query, Client);
}

QueryClientStatsDP_NextRank(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM players WHERE %s >= %i AND steamid <> '%s' ORDER BY %s ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayClientNextRank, query, Client);

	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		TriggerTimer(TimerRankChangeCheck[Client], true);
}

QueryClientStatsDP_NextRankFull(Client, const String:SteamID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT (%s + 1) - %i FROM players WHERE %s >= %i AND steamid <> '%s' ORDER BY %s ASC LIMIT 1", DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, GetClientNextRank, query, Client);

	Format(query, sizeof(query), "(SELECT name, %s AS totalpoints FROM players WHERE %s >= %i AND steamid <> '%s' ORDER BY totalpoints ASC LIMIT 3) UNION (SELECT name, %i FROM players WHERE steamid = '%s') UNION (SELECT name, %s as totalpoints2 FROM players WHERE %s < %i ORDER BY totalpoints2 DESC LIMIT 3) ORDER BY totalpoints DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client], SteamID, ClientPoints[Client], SteamID, DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPOINTS, ClientPoints[Client]);
	SQL_TQuery(db, DisplayNextRankFull, query, Client);

	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		TriggerTimer(TimerRankChangeCheck[Client], true);
}

// Check if a map is already in the DB.

CheckCurrentMapDB()
{
	if (StatsDisabled(true))
		return;

	decl String:MapName[MAX_LINE_WIDTH];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT name FROM maps WHERE name = '%s' and gamemode = %i", MapName, GetCurrentGamemodeID());

	SQL_TQuery(db, InsertMapDB, query);
}

// Insert a map into the database if they do not already exist.

public InsertMapDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (db == INVALID_HANDLE)
		return;

	if (StatsDisabled(true))
		return;

	if (!SQL_GetRowCount(hndl))
	{
			decl String:MapName[MAX_LINE_WIDTH];
			GetCurrentMap(MapName, sizeof(MapName));

		decl String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO maps SET name = '%s', custom = 1, gamemode = %i", MapName, GetCurrentGamemodeID());

		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
}

// Check if a player is already in the DB, and update their timestamp and playtime.

CheckPlayerDB(client)
{
	if (StatsDisabled())
		return;

	if (IsClientBot(client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT steamid FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, InsertPlayerDB, query, client);
}

// Insert a player into the database if they do not already exist.

public InsertPlayerDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (db == INVALID_HANDLE)
		return;

	new client = data;

	if (!client || hndl == INVALID_HANDLE)
		return;

	if (StatsDisabled())
		return;

	if (!SQL_GetRowCount(hndl))
	{
		new String:SteamID[MAX_LINE_WIDTH];
		GetClientName(client, SteamID, sizeof(SteamID));

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO players SET steamid = '%s'", SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}

	UpdatePlayer(client);
}

// Run a SQL query, used for UPDATE's only.

SendSQLUpdate(const String:query[], SQLTCallback:callback=INVALID_HANDLE)
{
	if (db == INVALID_HANDLE)
		return;

	if (callback == INVALID_HANDLE)
		callback = SQLErrorCheckCallback;

	if (DEBUG)
	{
		if (QueryCounter >= 256)
			QueryCounter = 0;

		new queryid = QueryCounter++;

		Format(QueryBuffer[queryid], MAX_QUERY_COUNTER, query);

		SQL_TQuery(db, callback, query, queryid);
	}
	else
		SQL_TQuery(db, callback, query);
}

// Report error on sql query;

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:queryid)
{
	if (db == INVALID_HANDLE)
		return;

	if(!StrEqual("", error))
	{
		if (DEBUG)
			LogError("SQL Error: %s (Query: \"%s\")", error, QueryBuffer[queryid]);
		else
			LogError("SQL Error: %s", error);
	}
}

// Perform player update of name, playtime, and timestamp.

public UpdatePlayer(client)
{
	if (!IsClientConnected(client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	ReplaceString(SteamID, sizeof(SteamID), "<?php", "");
	ReplaceString(SteamID, sizeof(SteamID), "<?PHP", "");
	ReplaceString(SteamID, sizeof(SteamID), "?>", "");
	ReplaceString(SteamID, sizeof(SteamID), "\\", "");
	ReplaceString(SteamID, sizeof(SteamID), "\"", "");
	ReplaceString(SteamID, sizeof(SteamID), "'", "");
	ReplaceString(SteamID, sizeof(SteamID), "'", "");
	ReplaceString(SteamID, sizeof(SteamID), "'", "");
	ReplaceString(SteamID, sizeof(SteamID), ";", "");
	ReplaceString(SteamID, sizeof(SteamID), "´", "");
	ReplaceString(SteamID, sizeof(SteamID), "`", "");
	ReplaceString(SteamID, sizeof(SteamID), "`", "");
	ReplaceString(SteamID, sizeof(SteamID), "`", "");

	decl String:Name[MAX_LINE_WIDTH];
	GetClientName(client, Name, sizeof(Name));

	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "´", "");
	ReplaceString(Name, sizeof(Name), "`", "");
	ReplaceString(Name, sizeof(Name), "`", "");
	ReplaceString(Name, sizeof(Name), "`", "");

	UpdatePlayerFull(client, SteamID, Name);
}

// Perform player update of name, playtime, and timestamp.

public UpdatePlayerFull(Client, const String:SteamID[], const String:Name[])
{
	// Client can be ZERO! Look at UpdatePlayerCallback.

	decl String:Playtime[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(Playtime, sizeof(Playtime), "playtime_versus");
		}
		case GAMEMODE_REALISM:
		{
			Format(Playtime, sizeof(Playtime), "playtime_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(Playtime, sizeof(Playtime), "playtime_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(Playtime, sizeof(Playtime), "playtime_scavenge");
		}
		default:
		{
			Format(Playtime, sizeof(Playtime), "playtime");
		}
	}

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE players SET lastontime = UNIX_TIMESTAMP(), %s = %s + 1, lastgamemode = %i, name = '%s' WHERE steamid = '%s'", Playtime, Playtime, CurrentGamemodeID, Name, SteamID);
	SQL_TQuery(db, UpdatePlayerCallback, query, Client);
}

// Report error on sql query;

public UpdatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (db == INVALID_HANDLE)
		return;

	if (!StrEqual("", error))
	{
		if (client > 0)
		{
			decl String:SteamID[MAX_LINE_WIDTH];
			GetClientName(client, SteamID, sizeof(SteamID));

			UpdatePlayerFull(0, SteamID, "INVALID_CHARACTERS");

			return;
		}

		LogError("SQL Error: %s", error);
	}
}

// Perform a map stat update.
public UpdateMapStat(const String:Field[], Score)
{
	if (Score <= 0)
		return;

	decl String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:DiffSQL[MAX_LINE_WIDTH];
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	decl String:FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE maps SET %s = %s + %i WHERE name = '%s' and gamemode = %i", FieldSQL, FieldSQL, Score, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

// Perform a map stat update.
public UpdateMapStatFloat(const String:Field[], Float:Value)
{
	if (Value <= 0)
		return;

	decl String:MapName[64];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:DiffSQL[MAX_LINE_WIDTH];
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) Format(DiffSQL, sizeof(DiffSQL), "nor");
	else if (StrEqual(Difficulty, "hard", false)) Format(DiffSQL, sizeof(DiffSQL), "adv");
	else if (StrEqual(Difficulty, "impossible", false)) Format(DiffSQL, sizeof(DiffSQL), "exp");
	else return;

	decl String:FieldSQL[MAX_LINE_WIDTH];
	Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE maps SET %s = %s + %f WHERE name = '%s' and gamemode = %i", FieldSQL, FieldSQL, Value, MapName, GetCurrentGamemodeID());
	SendSQLUpdate(query);
}

// End blinded state.

public Action:timer_EndBoomerBlinded(Handle:timer, any:data)
{
	PlayerBlinded[data][0] = 0;
	PlayerBlinded[data][1] = 0;
}

// End blinded state.

public Action:timer_EndSmokerParalyzed(Handle:timer, any:data)
{
	PlayerParalyzed[data][0] = 0;
	PlayerParalyzed[data][1] = 0;
}

// End lunging state.

public Action:timer_EndHunterLunged(Handle:timer, any:data)
{
	PlayerLunged[data][0] = 0;
	PlayerLunged[data][1] = 0;
}

// End plummel state.

public Action:timer_EndChargerPlummel(Handle:timer, any:data)
{
	ChargerPlummelVictim[PlayerPlummeled[data][1]] = 0;
	PlayerPlummeled[data][0] = 0;
	PlayerPlummeled[data][1] = 0;
}

// End carried state.

public Action:timer_EndChargerCarry(Handle:timer, any:data)
{
	ChargerCarryVictim[PlayerCarried[data][1]] = 0;
	PlayerCarried[data][0] = 0;
	PlayerCarried[data][1] = 0;
}

// End jockey ride state.

public Action:timer_EndJockeyRide(Handle:timer, any:data)
{
	JockeyVictim[PlayerCarried[data][1]] = 0;
	PlayerJockied[data][0] = 0;
	PlayerJockied[data][1] = 0;
}

// End friendly fire damage counter.

public Action:timer_FriendlyFireDamageEnd(Handle:timer, any:dp)
{
	ResetPack(dp);

	new HumanDamage = ReadPackCell(dp);
	new BotDamage = ReadPackCell(dp);
	new Attacker = ReadPackCell(dp);

	// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
	FriendlyFireTimer[Attacker][0] = INVALID_HANDLE;

	decl String:AttackerID[MAX_LINE_WIDTH];
	ReadPackString(dp, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	ReadPackString(dp, AttackerName, sizeof(AttackerName));

	// The damage is read and turned into lost points...
	ResetPack(dp);
	WritePackCell(dp, 0); // Human damage
	WritePackCell(dp, 0); // Bot damage

	if (HumanDamage <= 0 && BotDamage <= 0)
		return;

	new Score = 0;
	
	if (GetConVarBool(cvar_EnableNegativeScore))
	{
		if (HumanDamage > 0)
			Score += ModifyScoreDifficultyNR(RoundToNearest(GetConVarFloat(cvar_FriendlyFireMultiplier) * HumanDamage), 2, 4);

		if (BotDamage > 0)
		{
			new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

			if (BotScoreMultiplier > 0.0)
				Score += ModifyScoreDifficultyNR(RoundToNearest(GetConVarFloat(cvar_FriendlyFireMultiplier) * BotDamage), 2, 4);
		}
	}

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if ((Mode == 1 || Mode == 2) && IsClientConnected(Attacker) && IsClientInGame(Attacker))
		PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for inflicting \x03Friendly Fire Damage \x05(%i HP)\x01!", Score, HumanDamage + BotDamage);
	else if (Mode == 3)
		PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for inflicting \x03Friendly Fire Damage \x05(%i HP)\x01!", AttackerName, Score, HumanDamage + BotDamage);
}

// Start team shuffle.

public Action:timer_ShuffleTeams(Handle:timer, any:data)
{
	if (CheckHumans())
		return;

	decl String:query[1024];
	Format(query, sizeof(query), "SELECT steamid FROM players WHERE ");

	new maxplayers = GetMaxClients();
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0, team;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		team = GetClientTeam(i);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientName(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter <= 1)
	{
		PrintToChatAll("\x04[\x03RANK\x04] \x01Team shuffle by player PPM failed because there was \x03not enough players\x01!");
		return;
	}

	Format(where, sizeof(where), "ORDER BY (%s) / (%s) DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME);
	StrCat(query, sizeof(query), where);

	SQL_TQuery(db, ExecuteTeamShuffle, query);
}

// End of RANKVOTE.

public Action:timer_RankVote(Handle:timer, any:data)
{
	RankVoteTimer = INVALID_HANDLE;

	if (!CheckHumans())
	{
		new humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;

		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		PrintToChatAll("\x04[\x03RANK\x04] \x01Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes >= WinningVoteCount ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

		if (yesvotes > novotes)
			CreateTimer(3.0, timer_ShuffleTeams);
	}
}

// End friendly fire cooldown.

public Action:timer_FriendlyFireCooldownEnd(Handle:timer, any:data)
{
	FriendlyFireCooldown[FriendlyFirePrm[data][0]][FriendlyFirePrm[data][1]] = false;
	FriendlyFireTimer[FriendlyFirePrm[data][0]][FriendlyFirePrm[data][1]] = INVALID_HANDLE;
}

// Perform minutely updates of player database.
// Reports Disabled message if in Versus, Easy mode, not enough Human players, and if cheats are active.

public Action:timer_UpdatePlayers(Handle:timer, Handle:hndl)
{
	if (CheckHumans() && GetConVarBool(cvar_DisabledMessages))
		PrintToChatAll("\x04[\x03RANK\x04] \x01Left 4 Dead Stats are \x04DISABLED\x01, not enough Human players!");

	if (StatsDisabled())
		return;

	UpdateMapStat("playtime", 1);

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			CheckPlayerDB(i);
	}
}

// Display rank change.

public Action:timer_ShowRankChange(Handle:timer, any:client)
{
	DoShowRankChange(client);
}

public DoShowRankChange(Client)
{
	if (StatsDisabled())
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientName(Client, ClientID, sizeof(ClientID));

	QueryClientPointsSteamID(Client, ClientID, GetClientPointsRankChange);
}

// Display common Infected scores to each player.

public Action:timer_ShowTimerScore(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:Name[MAX_LINE_WIDTH];

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			// if (CurrentPoints[i] > GetConVarInt(cvar_MaxPoints))
			//     continue;

			TimerPoints[i] = GetMedkitPointReductionScore(TimerPoints[i]);

			if (TimerPoints[i] > 0 && TimerKills[i] > 0)
			{
				if (Mode == 1 || Mode == 2)
				{
					PrintToChat(i, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for killing \x05%i \x01Infected!", TimerPoints[i], TimerKills[i]);
				}
				else if (Mode == 3)
				{
					GetClientName(i, Name, sizeof(Name));
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for killing \x05%i \x01Infected!", Name, TimerPoints[i], TimerKills[i]);
				}
			}

			InterstitialPlayerUpdate(i);
		}

		TimerPoints[i] = 0;
		TimerKills[i] = 0;
		TimerHeadshots[i] = 0;
	}

}

// Update a player's stats, used for interstitial updating.

public InterstitialPlayerUpdate(client)
{
	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientName(client, ClientID, sizeof(ClientID));

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	new len = 0;
	decl String:query[1024];
	len += Format(query[len], sizeof(query)-len, "UPDATE players SET %s = %s + %i, ", UpdatePoints, UpdatePoints, TimerPoints[client]);
	len += Format(query[len], sizeof(query)-len, "kills = kills + %i, kill_infected = kill_infected + %i, ", TimerKills[client], TimerKills[client]);
	len += Format(query[len], sizeof(query)-len, "headshots = headshots + %i ", TimerHeadshots[client]);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("kills", TimerKills[client]);
	UpdateMapStat("points", TimerPoints[client]);

	AddScore(client, TimerPoints[client]);
}

// Player Death event. Used for killing AI Infected. +2 on headshot, and global announcement.
// Team Kill code is in the awards section. Tank Kill code is in Tank section.

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:AttackerIsBot = GetEventBool(event, "attackerisbot");
	new bool:VictimIsBot = GetEventBool(event, "victimisbot");
	new VictimTeam = -1;

	if (!VictimIsBot)
		DoInfectedFinalChecks(Victim, ClientInfectedType[Victim]);

	if (Victim > 0)
		VictimTeam = GetClientTeam(Victim);

	if (Attacker == 0 || AttackerIsBot)
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& VictimTeam == TEAM_SURVIVORS
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			PlayerDeathExternal(Victim);

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && Victim > 0 && VictimTeam == TEAM_SURVIVORS)
			CheckSurvivorsAllDown();

		return;
	}

	new Mode = GetConVarInt(cvar_AnnounceMode);
	new AttackerTeam = GetClientTeam(Attacker);
	decl String:AttackerName[MAX_LINE_WIDTH];
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerID, sizeof(AttackerID));
	decl String:VictimName[MAX_LINE_WIDTH];
	new VictimInfType = -1;

	if (Victim > 0)
	{
		GetClientName(Victim, VictimName, sizeof(VictimName));

		if (VictimTeam == TEAM_INFECTED)
			VictimInfType = GetInfType(Victim);
	}
	else
	{
		GetEventString(event, "victimname", VictimName, sizeof(VictimName));

		if (StrEqual(VictimName, "hunter", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_HUNTER;
		}
		else if (StrEqual(VictimName, "smoker", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SMOKER;
		}
		else if (StrEqual(VictimName, "boomer", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_BOOMER;
		}
		if (StrEqual(VictimName, "spitter", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SPITTER_L4D2;
		}
		else if (StrEqual(VictimName, "jockey", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_JOCKEY_L4D2;
		}
		else if (StrEqual(VictimName, "charger", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_CHARGER_L4D2;
		}
		else if (StrEqual(VictimName, "tank", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_TANK_L4D2;
		}
		else
			return;
	}

	// The wearoff should now work properly! Don't initialize
	//if (Victim > 0 && (VictimInfType == INF_ID_HUNTER || VictimInfType == INF_ID_SMOKER))
	//	InitializeClientInf(Victim);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	// Team Kill: Attacker is a Survivor and Victim is Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_SURVIVORS)
	{
		new Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
		{
			if (!IsClientBot(Victim))
				Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4);
			else
			{
				new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

				if (BotScoreMultiplier > 0.0)
					Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4) * BotScoreMultiplier);
			}
		}
		else
			Mode = 0;

		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE players SET %s = %s - %i, award_teamkill = award_teamkill + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AttackerID);

		SendSQLUpdate(query);

		if (Mode == 1 || Mode == 2)
			PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Team Killing \x05%s\x01!", Score, VictimName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing \x05%s\x01!", AttackerName, Score, VictimName);
	}

	// Attacker is a Survivor
	else if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_INFECTED)
	{
		new Score = 0;
		decl String:InfectedType[8];

		if (VictimInfType == INF_ID_HUNTER)
		{
			Format(InfectedType, sizeof(InfectedType), "hunter");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Hunter), 2, 3);
		}
		else if (VictimInfType == INF_ID_SMOKER)
		{
			Format(InfectedType, sizeof(InfectedType), "smoker");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Smoker), 2, 3);
		}
		else if (VictimInfType == INF_ID_BOOMER)
		{
			Format(InfectedType, sizeof(InfectedType), "boomer");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Boomer), 2, 3);
		}
		else if (VictimInfType == INF_ID_SPITTER_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "spitter");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Spitter), 2, 3);
		}
		else if (VictimInfType == INF_ID_JOCKEY_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "jockey");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Jockey), 2, 3);
		}
		else if (VictimInfType == INF_ID_CHARGER_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "charger");
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Charger), 2, 3);
		}
		else
			return;

		new String:Headshot[32];
		if (GetEventBool(event, "headshot"))
		{
			Format(Headshot, sizeof(Headshot), ", headshots = headshots + 1");
			Score = Score + 2;
		}

		Score = GetMedkitPointReductionScore(Score);

		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		new len = 0;
		decl String:query[1024];
		len += Format(query[len], sizeof(query)-len, "UPDATE players SET %s = %s + %i, ", UpdatePoints, UpdatePoints, Score);
		len += Format(query[len], sizeof(query)-len, "kills = kills + 1, kill_%s = kill_%s + 1", InfectedType, InfectedType);
		len += Format(query[len], sizeof(query)-len, "%s WHERE steamid = '%s'", Headshot, AttackerID);
		SendSQLUpdate(query);

		if (Mode && Score > 0)
		{
			if (GetEventBool(event, "headshot"))
			{
				if (Mode > 1)
				{
					GetClientName(Attacker, AttackerName, sizeof(AttackerName));
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for killing%s \x05%s \x01with a \x04HEAD SHOT\x01!", AttackerName, Score, (VictimIsBot ? " a" : ""), VictimName);
				}
				else
					PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for killing%s \x05%s \x01with a \x04HEAD SHOT\x01!", Score, (VictimIsBot ? " a" : ""), VictimName);
			}
			else
			{
				if (Mode > 2)
				{
					GetClientName(Attacker, AttackerName, sizeof(AttackerName));
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for killing%s \x05%s\x01!", AttackerName, Score, (VictimIsBot ? " a" : ""), VictimName);
				}
				else
					PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for killing%s \x05%s\x01!", Score, (VictimIsBot ? " a" : ""), VictimName);
			}
		}

		UpdateMapStat("kills", 1);
		UpdateMapStat("points", Score);
		AddScore(Attacker, Score);
	}

	// Attacker is an Infected
	else if (AttackerTeam == TEAM_INFECTED && VictimTeam == TEAM_SURVIVORS)
		SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, -1, Mode);

	if (VictimTeam == TEAM_SURVIVORS)
	{
		if (PanicEvent)
			PanicEventIncap = true;

		if (PlayerVomited)
			PlayerVomitedIncap = true;
	}
}

// Common Infected death code. +1 on headshot.

public Action:event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!Attacker || IsClientBot(Attacker) || GetClientTeam(Attacker) == TEAM_INFECTED)
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Infected), 2, 3);

	if (GetEventBool(event, "headshot"))
	{
		Score = Score + 1;
		TimerHeadshots[Attacker] = TimerHeadshots[Attacker] + 1;
	}

	TimerPoints[Attacker] = TimerPoints[Attacker] + Score;
	TimerKills[Attacker] = TimerKills[Attacker] + 1;
}

// Tank death code. Points are given to all players.

public Action:event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (TankCount >= 3)
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Tank), 2, 4);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	new Deaths = 0;
	new Modifier = 0;

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			if (IsPlayerAlive(i))
				Modifier++;
			else
				Deaths++;
		}
	}

	Score = Score * Modifier;

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[512];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientName(i, iID, sizeof(iID));
			Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_tankkill = award_tankkill + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);

			AddScore(i, Score);
		}
	}

	if (Mode && Score > 0)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for killing a Tank with \x05%i Deaths\x01!", Score, Deaths);

	UpdateMapStat("kills", 1);
	UpdateMapStat("points", Score);
	TankCount = TankCount + 1;
}

// Adrenaline give code. Special note, Adrenalines can only be given once. (Even if it's initially given by a bot!)

GiveAdrenaline(Giver, Recipient, AdrenalineID = -1)
{
	// Stats enabled is checked by the caller

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (AdrenalineID < 0)
		AdrenalineID = GetPlayerWeaponSlot(Recipient, 4);

	if (AdrenalineID < 0 || Adrenaline[AdrenalineID] == 1)
		return;
	else
		Adrenaline[AdrenalineID] = 1;

	if (IsClientBot(Giver))
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverID, sizeof(GiverID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Adrenaline), 2, 4);
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_adrenaline = award_adrenaline + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for giving adrenaline to \x05%s\x01!", Score, RecipientName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for giving adrenaline to \x05%s\x01!", GiverName, Score, RecipientName);
	}
}

// Pill give event. (From give a weapon)

public Action:event_GivePills(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	// If given weapon != 12 (Pain Pills) then return
	if (GetEventInt(event, "weapon") != 12)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
		return;

	new Recipient = GetClientOfUserId(GetEventInt(event, "userid"));
	new Giver = GetClientOfUserId(GetEventInt(event, "giver"));
	new PillsID = GetEventInt(event, "weaponentid");

	GivePills(Giver, Recipient, PillsID);
}

// Pill give code. Special note, Pills can only be given once. (Even if it's initially given by a bot!)

GivePills(Giver, Recipient, PillsID = -1)
{
	// Stats enabled is checked by the caller

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (PillsID < 0)
		PillsID = GetPlayerWeaponSlot(Recipient, 4);

	if (PillsID < 0 || Pills[PillsID] == 1)
		return;
	else
		Pills[PillsID] = 1;

	if (IsClientBot(Giver))
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverID, sizeof(GiverID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Pills), 2, 4);
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_pills = award_pills + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for giving pills to \x05%s\x01!", Score, RecipientName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for giving pills to \x05%s\x01!", GiverName, Score, RecipientName);
	}
}

// Defibrillator used code.

public Action:event_DefibPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && (!SurvivalStarted || !GetConVarBool(cvar_EnableSvMedicPoints)))
		return;

	new Recipient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));

	new bool:GiverIsBot = IsClientBot(Giver);
	new bool:RecipientIsBot = IsClientBot(Recipient);

	if (CurrentGamemodeID != GAMEMODE_SURVIVAL && (!GiverIsBot || (GiverIsBot && (GetConVarInt(cvar_MedkitBotMode) >= 2 || (!RecipientIsBot && GetConVarInt(cvar_MedkitBotMode) >= 1)))))
	{
		MedkitsUsedCounter++;
		AnnounceMedkitPenalty();
	}

	if (IsClientBot(Giver))
		return;

	// How is this possible?
	if (Recipient == Giver)
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverID, sizeof(GiverID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Defib), 2, 4);

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_defib = award_defib + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);
		if (Mode == 1 || Mode == 2)
			PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Reviving \x05%s\x01 using a Defibrillator!", Score, RecipientName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Reviving \x05%s\x01 using a Defibrillator!", GiverName, Score, RecipientName);
	}
}

// Medkit give code.

public Action:event_HealPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && (!SurvivalStarted || !GetConVarBool(cvar_EnableSvMedicPoints)))
		return;

	new Recipient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));
	new Amount = GetEventInt(event, "health_restored");

	new bool:GiverIsBot = IsClientBot(Giver);
	new bool:RecipientIsBot = IsClientBot(Recipient);

	if (CurrentGamemodeID != GAMEMODE_SURVIVAL && (!GiverIsBot || (GiverIsBot && (GetConVarInt(cvar_MedkitBotMode) >= 2 || (!RecipientIsBot && GetConVarInt(cvar_MedkitBotMode) >= 1)))))
	{
		MedkitsUsedCounter++;
		AnnounceMedkitPenalty();
	}

	if (GiverIsBot)
		return;

	if (Recipient == Giver)
		return;

	decl String:RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	decl String:RecipientID[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientID, sizeof(RecipientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverID, sizeof(GiverID));

	new Score = (Amount + 1) / 2;
	if (GetConVarInt(cvar_MedkitMode))
		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Medkit), 2, 4);
	else
		Score = ModifyScoreDifficulty(Score, 2, 3);

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_medkit = award_medkit + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);
		if (Mode == 1 || Mode == 2)
			PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for healing \x05%s\x01!", Score, RecipientName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for healing \x05%s\x01!", GiverName, Score, RecipientName);
	}
}

// Friendly fire code.

public Action:event_FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!Attacker || !Victim)
		return;

//	if (IsClientBot(Victim))
//		return;

	new FFMode = GetConVarInt(cvar_FriendlyFireMode);

	if (FFMode == 1)
	{
		new CooldownMode = GetConVarInt(cvar_FriendlyFireCooldownMode);

		if (CooldownMode == 1 || CooldownMode == 2)
		{
			new Target = 0;

			// Player specific : CooldownMode = 1
			// General : CooldownMode = 2
			if (CooldownMode == 1)
				Target = Victim;

			if (FriendlyFireCooldown[Attacker][Target])
				return;

			FriendlyFireCooldown[Attacker][Target] = true;

			if (FriendlyFirePrmCounter >= MAXPLAYERS)
				FriendlyFirePrmCounter = 0;

			FriendlyFirePrm[FriendlyFirePrmCounter][0] = Attacker;
			FriendlyFirePrm[FriendlyFirePrmCounter][1] = Target;
			FriendlyFireTimer[Attacker][Target] = CreateTimer(GetConVarFloat(cvar_FriendlyFireCooldown), timer_FriendlyFireCooldownEnd, FriendlyFirePrmCounter++);
		}
	}
	else if (FFMode == 2)
	{
		// Friendly fire is calculated in player_hurt event (Damage based)
		return;
	}

	UpdateFriendlyFire(Attacker, Victim);
}

// Campaign win code.

public Action:event_CampaignWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CampaignOver || StatsDisabled())
		return;

	CampaignOver = true;

	StopMapTiming();

	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_VictorySurvivors), 4, 12);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	new SurvivorCount = GetEventInt(event, "survivorcount");
	new ClientTeam, bool:NegativeScore = GetConVarBool(cvar_EnableNegativeScore);

	Score *= SurvivorCount;

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	decl String:UpdatePoints[32], String:UpdatePointsPenalty[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_infected");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientName(i, iID, sizeof(iID));

				Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_campaigns = award_campaigns + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);

				if (Score > 0)
				{
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				GetClientName(i, iID, sizeof(iID));

				Format(query, sizeof(query), "UPDATE players SET %s = %s - %i WHERE steamid = '%s'", UpdatePointsPenalty, UpdatePointsPenalty, Score, iID);
				SendSQLUpdate(query);

				if (Score < 0)
					AddScore(i, Score * (-1));
			}
		}
	}

	if (Mode && Score > 0)
	{
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for winning the \x04Campaign Finale \x01with \x05%i survivors\x01!", Score, SurvivorCount);

		if (NegativeScore)
			PrintToChatTeam(TEAM_INFECTED, "\x04[\x03RANK\x04] \x03ALL INFECTED \x01have \x03LOST \x04%i \x01points for loosing the \x04Campaign Finale \x01to \x05%i survivors\x01!", Score, SurvivorCount);
	}
}

// Safe House reached code. Points are given to all players.
// Also, Witch Not Disturbed code, points also given to all players.

public Action:event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	CheckSurvivorsWin();
}

// Begin panic event.

public Action:event_PanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (CampaignOver || PanicEvent)
		return;

	PanicEvent = true;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStart();
		return;
	}

	CreateTimer(75.0, timer_PanicEventEnd);
}

// Panic Event with no Incaps code. Points given to all players.

public Action:timer_PanicEventEnd(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	if (CampaignOver || CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PanicEvent && !PanicEventIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Panic), 2, 4);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			decl String:UpdatePoints[32];

			switch (CurrentGamemodeID)
			{
				case GAMEMODE_VERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
				}
				case GAMEMODE_REALISM:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
				}
				case GAMEMODE_SCAVENGE:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
				}
				default:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points");
				}
			}

			new maxplayers = GetMaxClients();
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientName(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s' ", UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}

			if (Mode)
				PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05No Incapicitates Or Deaths After Panic Event\x01!", Score);
		}
	}

	PanicEvent = false;
	PanicEventIncap = false;
}

// Begin Boomer blind.

public Action:event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	PlayerVomited = true;

//	new bool:Infected = GetEventBool(event, "infected");
//
//	if (!Infected)
//		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientBot(Attacker))
		return;

	PlayerBlinded[Victim][0] = 1;
	PlayerBlinded[Victim][1] = Attacker;

	BoomerHitCounter[Attacker]++;

	if (TimerBoomerPerfectCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(TimerBoomerPerfectCheck[Attacker]);
		TimerBoomerPerfectCheck[Attacker] = INVALID_HANDLE;
	}

	TimerBoomerPerfectCheck[Attacker] = CreateTimer(6.0, timer_BoomerBlindnessCheck, Attacker);
}

// Boomer Mob Survival with no Incaps code. Points are given to all players.

public Action:event_PlayerBlindEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndBoomerBlinded, Player);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PlayerVomited && !PlayerVomitedIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_BoomerMob), 2, 5);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			decl String:UpdatePoints[32];

			switch (CurrentGamemodeID)
			{
				case GAMEMODE_VERSUS:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
				}
				case GAMEMODE_REALISM:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
				}
				case GAMEMODE_SURVIVAL:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
				}
				case GAMEMODE_SCAVENGE:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
				}
				default:
				{
					Format(UpdatePoints, sizeof(UpdatePoints), "points");
				}
			}

			new maxplayers = GetMaxClients();
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientName(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s' ", UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}

			if (Mode)
				PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05No Incapicitates Or Deaths After Boomer Mob\x01!", Score);
		}
	}

	PlayerVomited = false;
	PlayerVomitedIncap = false;
}

// Friendly Incapicitate code. Also handles if players should be awarded
// points for surviving a Panic Event or Boomer Mob without incaps.

PlayerIncap(Attacker, Victim)
{
	// Stats enabled and CampaignOver is checked by the caller

	if (PanicEvent)
		PanicEventIncap = true;

	if (PlayerVomited)
		PlayerVomitedIncap = true;

	if (Victim <= 0)
		return;

	if (!Attacker || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& Victim > 0
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			PlayerIncapExternal(Victim);

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && Victim > 0)
			CheckSurvivorsAllDown();

		return;
	}

	new AttackerTeam = GetClientTeam(Attacker);
	new VictimTeam = GetClientTeam(Victim);
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	// Attacker is a Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_SURVIVORS)
	{
		decl String:AttackerID[MAX_LINE_WIDTH];
		GetClientName(Attacker, AttackerID, sizeof(AttackerID));
		decl String:AttackerName[MAX_LINE_WIDTH];
		GetClientName(Attacker, AttackerName, sizeof(AttackerName));

		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
		{
			if (!IsClientBot(Victim))
				Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4);
			else
			{
				new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

				if (BotScoreMultiplier > 0.0)
					Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4) * BotScoreMultiplier);
			}
		}
		else
			Mode = 0;

		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		decl String:query[512];
		Format(query, sizeof(query), "UPDATE players SET %s = %s - %i, award_fincap = award_fincap + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AttackerID);
		SendSQLUpdate(query);

		if (Mode == 1 || Mode == 2)
			PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Incapicitating \x05%s\x01!", Score, VictimName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Incapicitating \x05%s\x01!", AttackerName, Score, VictimName);
	}

	// Attacker is an Infected
	else if (AttackerTeam == TEAM_INFECTED && VictimTeam == TEAM_SURVIVORS)
	{
		SurvivorIncappedByInfected(Attacker, Victim, Mode);
	}
}

// Friendly Incapacitate event.

public Action:event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	PlayerIncap(Attacker, Victim);
}

// Save friendly from being dragged by Smoker.

public Action:event_TongueSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	HunterSmokerSave(GetEventInt(event, "userid"), GetEventInt(event, "victim"), GetConVarInt(cvar_SmokerDrag), 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being choked by Smoker.

public Action:event_ChokeSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	HunterSmokerSave(GetEventInt(event, "userid"), GetEventInt(event, "victim"), GetConVarInt(cvar_ChokePounce), 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being pounced by Hunter.

public Action:event_PounceSave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "Victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged, Victim);

	HunterSmokerSave(GetEventInt(event, "userid"), Victim, GetConVarInt(cvar_ChokePounce), 2, 3, "Hunter", "award_hunter");
}

// Player is hanging from a ledge.

public Action:event_PlayerFallDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver || !IsGamemodeVersus())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Damage = RoundToNearest(GetEventFloat(event, "damage"));

	if (Attacker == 0 && PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		Attacker = PlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED || GetClientTeam(Victim) != TEAM_SURVIVORS || Damage <= 0)
		return;

	new VictimHealth = GetClientHealth(Victim);
	new VictimIsIncap = GetEntProp(Victim, Prop_Send, "m_isIncapacitated");

	// If the victim health is zero or below zero or is incapacitated don't count the damage from the fall
	if (VictimHealth <= 0 || VictimIsIncap != 0)
		return;

	// Damage should never exceed the amount of healt the fallen survivor had before falling down.
	if (VictimHealth < Damage)
		Damage = VictimHealth;

	if (Damage <= 0)
		return;

	SurvivorHurt(Attacker, Victim, Damage);
}

// Player is hanging from a ledge.

public Action:event_PlayerLedge(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 && PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
		Attacker = PlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_PlayerLedgeSuccess), 0.9, 0.8);

	if (Score > 0)
	{
		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientName(Attacker, ClientID, sizeof(ClientID));

		decl String:query[1024];
		new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;
		if (IsVersus)
			Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", Score, ClientID);

		SendSQLUpdate(query);

		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
			PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for causing player \x05%s\x01 to grab a ledge!", Score, VictimName);
		else if (Mode == 3)
		{
			decl String:AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for causing player \x05%s\x01 to grab a ledge!", AttackerName, Score, VictimName);
		}
	}
}

// Player spawned in game.

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0)
		return;

	InitializeClientInf(Player);

	ClientInfectedType[Player] = 0;
	BoomerHitCounter[Player] = 0;
	BoomerVomitUpdated[Player] = false;
	SmokerDamageCounter[Player] = 0;
	SpitterDamageCounter[Player] = 0;
	JockeyDamageCounter[Player] = 0;
	ChargerDamageCounter[Player] = 0;
	TankPointsCounter[Player] = 0;
	TankDamageCounter[Player] = 0;
	TankDamageTotalCounter[Player] = 0;
	TankSurvivorKillCounter[Player] = 0;
	ChargerCarryVictim[Player] = 0;
	ChargerPlummelVictim[Player] = 0;
	JockeyVictim[Player] = 0;
	JockeyRideStartTime[Player] = 0;

	PlayerBlinded[Player][0] = 0;
	PlayerBlinded[Player][1] = 0;
	PlayerParalyzed[Player][0] = 0;
	PlayerParalyzed[Player][1] = 0;
	PlayerLunged[Player][0] = 0;
	PlayerLunged[Player][1] = 0;
	PlayerPlummeled[Player][0] = 0;
	PlayerPlummeled[Player][1] = 0;
	PlayerCarried[Player][0] = 0;
	PlayerCarried[Player][1] = 0;
	PlayerJockied[Player][0] = 0;
	PlayerJockied[Player][1] = 0;

	if (!IsClientBot(Player))
		SetClientInfectedType(Player);
}

// Player hurt. Used for calculating damage points for the Infected players and also
// the friendly fire damage when Friendly Fire Mode is set to Damage Based.

public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& Victim > 0
				&& (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1]
					|| PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]
					|| PlayerLunged[Victim][0] && PlayerLunged[Victim][1]
					|| PlayerCarried[Victim][0] && PlayerCarried[Victim][1]
					|| PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1]
					|| PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			SurvivorHurtExternal(event, Victim);

		return;
	}

	new Damage = GetEventInt(event, "dmg_health");
	new AttackerTeam = GetClientTeam(Attacker);
	new AttackerInfType = -1;

	if (Attacker > 0)
	{
		if (AttackerTeam == TEAM_INFECTED)
			AttackerInfType = ClientInfectedType[Attacker];
		else if (AttackerTeam == TEAM_SURVIVORS && GetConVarInt(cvar_FriendlyFireMode) == 2)
		{
			new VictimTeam = GetClientTeam(Victim);

			if (VictimTeam == TEAM_SURVIVORS)
			{
				if (FriendlyFireTimer[Attacker][0] != INVALID_HANDLE)
				{
					CloseHandle(FriendlyFireTimer[Attacker][0]);
					FriendlyFireTimer[Attacker][0] = INVALID_HANDLE;
				}

				decl String:AttackerID[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerID, sizeof(AttackerID));
				decl String:AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));

				// Using datapack to deliver the needed info so that the attacker can't escape the penalty by disconnecting

				new Handle:dp = INVALID_HANDLE;
				new OldHumanDamage = 0;
				new OldBotDamage = 0;

				if (!GetTrieValue(FriendlyFireDamageTrie, AttackerID, dp))
				{
					dp = CreateDataPack();
					SetTrieValue(FriendlyFireDamageTrie, AttackerID, dp);
				}
				else
				{
					// Read old damage value
					ResetPack(dp);
					OldHumanDamage = ReadPackCell(dp);
					OldBotDamage = ReadPackCell(dp);
				}

				if (IsClientBot(Victim))
					OldBotDamage += Damage;
				else
					OldHumanDamage += Damage;

				ResetPack(dp, true);

				WritePackCell(dp, OldHumanDamage);
				WritePackCell(dp, OldBotDamage);
				WritePackCell(dp, Attacker);
				WritePackString(dp, AttackerID);
				WritePackString(dp, AttackerName);

				// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
				FriendlyFireTimer[Attacker][0] = CreateTimer(5.0, timer_FriendlyFireDamageEnd, dp);

				return;
			}
		}
	}
	if (AttackerInfType < 0)
		return;

//	decl String:AttackerID[MAX_LINE_WIDTH];
//	GetClientName(Attacker, AttackerID, sizeof(AttackerID));

//	new Mode;
//	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
//	decl String:VictimName[MAX_LINE_WIDTH];
//	new VictimTeam = 0;
//	new Score = 0;

//	if (Victim > 0)
//	{
//		GetClientName(Victim, VictimName, sizeof(VictimName));
//		VictimTeam = GetClientTeam(Victim);
//	}
//	else
//		Format(VictimName, sizeof(VictimName), "UNKNOWN");

//	if (VictimTeam == TEAM_INFECTED)
//	{
//		decl String:query[1024];
//
//		Score = GetConVarInt(cvar_FFire);
//		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected - %i WHERE steamid = '%s'", Score, AttackerID);
//		SendSQLUpdate(query);
//
//		UpdateMapStat("points_infected", Score * -1);
//		Mode = GetConVarInt(cvar_AnnounceMode);
//
//		if (Mode == 1 || Mode == 2)
//			PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", Score, VictimName);
//		else if (Mode == 3)
//		{
//			decl String:AttackerName[MAX_LINE_WIDTH];
//			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
//			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", AttackerName, Score, VictimName);
//		}
//
//		return;
//	}

	SurvivorHurt(Attacker, Victim, Damage, AttackerInfType, event);
}

// Smoker events.

public Action:event_SmokerGrap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerParalyzed[Victim][0] = 1;
	PlayerParalyzed[Victim][1] = Attacker;
}

// Jockey events.

public Action:event_JockeyStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerJockied[Victim][0] = 1;
	PlayerJockied[Victim][1] = Attacker;

	JockeyVictim[Attacker] = Victim;
	JockeyRideStartTime[Attacker] = 0;

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	JockeyRideStartTime[Attacker] = GetTime();

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	GetClientName(Attacker, iID, sizeof(iID));
	Format(query, sizeof(query), "UPDATE players SET jockey_rides = jockey_rides + 1 WHERE steamid = '%s'", iID);
	SendSQLUpdate(query);
	UpdateMapStat("jockey_rides", 1);
}

public Action:event_JockeyRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new Rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
	new Float:RideLength = GetEventFloat(event, "ride_length");

	if (Rescuer > 0 && !IsClientBot(Rescuer) && IsClientInGame(Rescuer))
	{
		decl String:query[1024], String:JockeyName[MAX_LINE_WIDTH], String:VictimName[MAX_LINE_WIDTH], String:RescuerName[MAX_LINE_WIDTH], String:RescuerID[MAX_LINE_WIDTH], String:UpdatePoints[32];
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_JockeyRide), 2, 3);

		GetClientName(Rescuer, RescuerID, sizeof(RescuerID));

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_jockey = award_jockey + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, RescuerID);
		SendSQLUpdate(query);

		if (Score > 0)
		{
			UpdateMapStat("points", Score);
			AddScore(Rescuer, Score);
		}

		GetClientName(Jockey, JockeyName, sizeof(JockeyName));
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				PrintToChat(Rescuer, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for saving \x05%s \x01from \x04%s\x01!", Score, VictimName, JockeyName);
			else if (Mode == 3)
			{
				GetClientName(Rescuer, RescuerName, sizeof(RescuerName));
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for saving \x05%s \x01from \x04%s\x01!", RescuerName, Score, VictimName, JockeyName);
			}
		}
	}

	JockeyVictim[Jockey] = 0;

	if (Jockey == 0 || IsClientBot(Jockey) || !IsClientInGame(Jockey))
	{
		PlayerJockied[Victim][0] = 0;
		PlayerJockied[Victim][1] = 0;
		JockeyRideStartTime[Victim] = 0;
		return;
	}

	UpdateJockeyRideLength(Jockey, RideLength);

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndJockeyRide, Victim);
}

public Action:event_JockeyKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndJockeyRide, Victim);
}

// Charger events.

public Action:event_ChargerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (Killer == 0 || IsClientBot(Killer) || !IsClientInGame(Killer))
		return;

	new Charger = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:query[1024], String:KillerName[MAX_LINE_WIDTH], String:KillerID[MAX_LINE_WIDTH], String:UpdatePoints[32];
	new Score = 0;
	new bool:IsMatador = GetEventBool(event, "melee") && GetEventBool(event, "charging");

	GetClientName(Killer, KillerID, sizeof(KillerID));

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	if (ChargerCarryVictim[Charger])
	{
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_ChargerCarry), 2, 3);
	}
	else if (ChargerPlummelVictim[Charger])
	{
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_ChargerPlummel), 2, 3);
	}

	if (IsMatador)
	{
		// Give a Matador award
		Score += ModifyScoreDifficulty(GetConVarInt(cvar_Matador), 2, 3);
	}

	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_charger = award_charger + 1%s WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, (IsMatador ? ", award_matador = award_matador + 1" : ""), KillerID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	UpdateMapStat("points", Score);
	AddScore(Killer, Score);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
	{
		GetClientName(Killer, KillerName, sizeof(KillerName));

		if (IsMatador)
		{
			if (Mode == 1 || Mode == 2)
				PrintToChat(Killer, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for \x04Leveling a Charge\x01!", Score);
			else if (Mode == 3)
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for \x04Leveling a Charge\x01!", KillerName, Score);
		}
		else
		{
			decl String:VictimName[MAX_LINE_WIDTH], String:ChargerName[MAX_LINE_WIDTH];

			GetClientName(Charger, ChargerName, sizeof(ChargerName));

			if (ChargerCarryVictim[Charger] > 0 && (IsClientBot(ChargerCarryVictim[Charger]) || (IsClientConnected(ChargerCarryVictim[Charger]) && IsClientInGame(ChargerCarryVictim[Charger]))))
			{
				GetClientName(ChargerCarryVictim[Charger], VictimName, sizeof(VictimName));
				Format(VictimName, sizeof(VictimName), "\x05%s\x01", VictimName);
			}
			else
				Format(VictimName, sizeof(VictimName), "a survivor");

			if (Mode == 1 || Mode == 2)
				PrintToChat(Killer, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for saving %s from \x04%s\x01!", Score, VictimName, ChargerName);
			else if (Mode == 3)
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for saving %s from \x04%s\x01!", KillerName, Score, VictimName, ChargerName);
		}
	}
}

public Action:event_ChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerCarried[Victim][0] = 1;
	PlayerCarried[Victim][1] = Attacker;

	ChargerCarryVictim[Attacker] = Victim;

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//	return;
}

public Action:event_ChargerCarryRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	//new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//{
	//	ChargerCarryVictim[Attacker] = 0;
	//	PlayerCarried[Victim][0] = 0;
	//	PlayerCarried[Victim][1] = 0;
	//	return;
	//}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndChargerCarry, Victim);
}

public Action:event_ChargerImpact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	//new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//	return;

	//new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
}

public Action:event_ChargerPummelStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	// There is no delay on charger carry once the plummel starts
	ChargerCarryVictim[Attacker] = 0;

	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerPlummeled[Victim][0] = 1;
	PlayerPlummeled[Victim][1] = Attacker;

	ChargerPlummelVictim[Attacker] = Victim;

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//	return;
}

public Action:event_ChargerPummelRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	{
		PlayerPlummeled[Victim][0] = 0;
		PlayerPlummeled[Victim][1] = 0;
		ChargerPlummelVictim[Attacker] = 0;
		return;
	}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndChargerPlummel, Victim);
}

// Hunter events.

public Action:event_HunterRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged, Player);
}

// Smoker events.

public Action:event_SmokerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndSmokerParalyzed, Player);
}

// L4D2 ammo upgrade deployed event.

public Action:event_UpgradePackAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	new Score = GetConVarInt(cvar_AmmoUpgradeAdded);

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3);

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientName(Player, PlayerID, sizeof(PlayerID));

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_upgrades_added = award_upgrades_added + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (!Mode)
			return;

		new EntityID = GetEventInt(event, "upgradeid");
		decl String:ModelName[128];
		GetEntPropString(EntityID, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));

		if (StrContains(ModelName, "incendiary_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Incendiary Ammo");
		else if (StrContains(ModelName, "exploding_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Exploding Ammo");
		else
			strcopy(ModelName, sizeof(ModelName), "UNKNOWN");

		if (Mode == 1 || Mode == 2)
			PrintToChat(Player, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for deploying \x99%s\x01!", Score, ModelName);
		else if (Mode == 3)
		{
			decl String:PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for deploying \x99%s\x01!", PlayerName, Score, ModelName);
		}
	}
}

// L4D2 gascan pour completed event.

public Action:event_GascanPoured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	new Score = GetConVarInt(cvar_GascanPoured);

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3);

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientName(Player, PlayerID, sizeof(PlayerID));

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_gascans_poured = award_gascans_poured + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);

	if (Score > 0)
	{
		new Mode = GetConVarInt(cvar_AnnounceMode);

		if (Mode == 1 || Mode == 2)
			PrintToChat(Player, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for successfully \x99Pouring a Gascan\x01!", Score);
		else if (Mode == 3)
		{
			decl String:PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for successfully \x99Pouring a Gascan\x01!", PlayerName, Score);
		}
	}
}

// Achievement earned.

/*
56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

public Action:event_Achievement(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "player"));
	new Achievement = GetEventInt(event, "achievement");

	if (IsClientBot(Player))
		return;

	if (DEBUG)
		LogMessage("Achievement earned: %i", Achievement);
}

// Saferoom door opens.

public Action:event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingStartTime != 0.0 || !GetEventBool(event, "checkpoint") || !GetEventBool(event, "closed") || CurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
		return Plugin_Continue;

	StartMapTiming();

	return Plugin_Continue;
}

public Action:event_StartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingStartTime != 0.0 || CurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
		return Plugin_Continue;

	StartMapTiming();

	return Plugin_Continue;
}

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MapTimingStartTime != 0.0 || GetEventBool(event, "isbot"))
		return Plugin_Continue;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	//new NewTeam = GetEventInt(event, "team");
	//new OldTeam = GetEventInt(event, "oldteam");

	if (Player <= 0)
		return Plugin_Continue;

	decl String:PlayerID[MAX_LINE_WIDTH];
	GetClientName(Player, PlayerID, sizeof(PlayerID));

	RemoveFromTrie(MapTimingSurvivors, PlayerID);
	RemoveFromTrie(MapTimingInfected, PlayerID);

	return Plugin_Continue;
}

// AbilityUse.

public Action:event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(Player, HunterPosition[Player]);

	if (!IsClientBot(Player) && GetClientInfectedType(Player) == INF_ID_BOOMER)
	{
		decl String:query[1024];
		decl String:iID[MAX_LINE_WIDTH];
		GetClientName(Player, iID, sizeof(iID));
		Format(query, sizeof(query), "UPDATE players SET infected_boomer_vomits = infected_boomer_vomits + 1 WHERE steamid = '%s'", iID);
		SendSQLUpdate(query);
		UpdateMapStat("infected_boomer_vomits", 1);
		BoomerVomitUpdated[Player] = true;
	}
}

// Player got pounced.

public Action:event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerLunged[Victim][0] = 1;
	PlayerLunged[Victim][1] = Attacker;

	if (IsClientBot(Attacker))
		return;

	new Float:PouncePosition[3];

	GetClientAbsOrigin(Attacker, PouncePosition);
	new PounceDistance = RoundToNearest(GetVectorDistance(HunterPosition[Attacker], PouncePosition));

	if (PounceDistance < MinPounceDistance)
		return;

	new Dmg = RoundToNearest((((PounceDistance - float(MinPounceDistance)) / float(MaxPounceDistance - MinPounceDistance)) * float(MaxPounceDamage)) + 1);
	new DmgCap = GetConVarInt(cvar_HunterDamageCap);

	if (Dmg > DmgCap)
		Dmg = DmgCap;

	new PerfectDmgLimit = GetConVarInt(cvar_HunterPerfectPounceDamage);
	new NiceDmgLimit = GetConVarInt(cvar_HunterNicePounceDamage);

	UpdateHunterDamage(Attacker, Dmg);

	if (Dmg < NiceDmgLimit && Dmg < PerfectDmgLimit)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerID, sizeof(AttackerID));
	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	decl String:Label[32];
	decl String:query[1024];
	new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;

	if (Dmg >= PerfectDmgLimit)
	{
		Score = GetConVarInt(cvar_HunterPerfectPounceSuccess);
		if (IsVersus)
			Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", Score, AttackerID);
		else
			Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", Score, AttackerID);
		Format(Label, sizeof(Label), "Death From Above");
	}
	else
	{
		Score = GetConVarInt(cvar_HunterNicePounceSuccess);
		if (IsVersus)
			Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", Score, AttackerID);
		else
			Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", Score, AttackerID);
		Format(Label, sizeof(Label), "Pain From Above");
	}

	SendSQLUpdate(query);
	UpdateMapStat("points_infected", Score);

	if (Mode == 1 || Mode == 2)
		PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for landing a \x99%s \x01Pounce on \x05%s\x01!", Score, Label, VictimName);
	else if (Mode == 3)
		PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for landing a \x99%s \x01Pounce on \x05%s\x01!", AttackerName, Score, Label, VictimName);
}

// Revive friendly code.

public Action:event_RevivePlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !SurvivalStarted)
		return;

	if (GetEventBool(event, "ledge_hang"))
		return;

	new Savior = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "subject"));
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	decl String:SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	decl String:SaviorID[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VictimID[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimID, sizeof(VictimID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Revive), 2, 3);

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_revive = award_revive + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, SaviorID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Savior, Score);

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			PrintToChat(Savior, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Reviving \x05%s\x01!", Score, VictimName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Reviving \x05%s\x01!", SaviorName, Score, VictimName);
	}
}

/*
L4D1:

56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award_L4D1(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new PlayerID = GetEventInt(event, "userid");

	if (!PlayerID)
		return;

	new User = GetClientOfUserId(PlayerID);

	if (IsClientBot(User))
		return;

	new SubjectID = GetEventInt(event, "subjectentid");
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	new Recipient;
	decl String:RecipientName[MAX_LINE_WIDTH];

	new Score = 0;
	new String:AwardSQL[128];
	new AwardID = GetEventInt(event, "award");

	if (AwardID == 67) // Protect friendly
	{
		if (!SubjectID)
			return;

		ProtectedFriendlyCounter[User]++;

		if (TimerProtectedFriendly[User] != INVALID_HANDLE)
		{
			CloseHandle(TimerProtectedFriendly[User]);
			TimerProtectedFriendly[User] = INVALID_HANDLE;
		}

		TimerProtectedFriendly[User] = CreateTimer(3.0, timer_ProtectedFriendly, User);

		return;
	}
	else if (AwardID == 79) // Respawn friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recipient))
			return;

		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		AddScore(User, Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				PrintToChat(User, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Rescuing \x05%s\x01!", Score, RecipientName);
			else if (Mode == 3)
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Rescuing \x05%s\x01!", UserName, Score, RecipientName);
		}
	}
	else if (AwardID == 80) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to event_PlayerDeath
//	else if (AwardID == 83 && !CampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Team Killing!", Score);
//		else if (Mode == 3)
//			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing!", UserName, Score);
//	}
	else if (AwardID == 85) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1);
	}
	else if (AwardID == 94) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_InSafeRoom), 2, 4);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2)
			PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", Score);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 98) // Round restart
	{
		UpdateMapStat("restarts", 1);

		if (!GetConVarBool(cvar_EnableNegativeScore))
			return;

		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3);
		Score = 400 - Score;

		if (Mode)
			PrintToChat(User, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying!", Score);

		Score = Score * -1;
	}
	else
	{
//		if (DEBUG)
//			LogError("event_Award => %i", AwardID);
		return;
	}

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientName(User, UserID, sizeof(UserID));

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i%s WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
}

/*
L4D2:
0 - End of Campaign (Not 100% Sure)
7 - End of Level (Not 100% Sure)
8 - End of Level (Not 100% Sure)
17 - Kill Tank
22 - Random Director Mob
23 - End of Level (Not 100% Sure)
40 - End of Campaign (Not 100% Sure)
67 - Protect Friendly
68 - Give Pain Pills
69 - Give Adrenaline
70 - Give Heatlh (Heal using Med Pack)
71 - End of Level (Not 100% Sure)
72 - End of Campaign (Not 100% Sure)
75 - Save Friendly from Ledge Grasp
76 - Save Friendly from Special Infected
80 - Hero Closet Rescue Survivor
81 - Kill Tank with no deaths
84 - Team Kill
85 - Incap Friendly
86 - Left Friendly for Dead
87 - Friendly Fire
89 - Incap Friendly
95 - Let infected in safe room
99 - Round Restart (All Dead)
*/

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award_L4D2(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new PlayerID = GetEventInt(event, "userid");

	if (!PlayerID)
		return;

	new User = GetClientOfUserId(PlayerID);

	if (IsClientBot(User))
		return;

	new SubjectID = GetEventInt(event, "subjectentid");
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	new Recipient;
	decl String:RecipientName[MAX_LINE_WIDTH];

	new Score = 0;
	new String:AwardSQL[128];
	new AwardID = GetEventInt(event, "award");

	//PrintToChat(User, "[TEST] Your actions gave you award (ID = %i)", AwardID);

	if (AwardID == 67) // Protect friendly
	{
		if (!SubjectID)
			return;

		ProtectedFriendlyCounter[User]++;

		if (TimerProtectedFriendly[User] != INVALID_HANDLE)
		{
			CloseHandle(TimerProtectedFriendly[User]);
			TimerProtectedFriendly[User] = INVALID_HANDLE;
		}

		TimerProtectedFriendly[User] = CreateTimer(3.0, timer_ProtectedFriendly, User);

		return;
	}

	if (AwardID == 68) // Pills given
	{
		if (!SubjectID)
			return;

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		GivePills(User, Recipient);

		return;
	}

	if (AwardID == 69) // Adrenaline given
	{
		if (!SubjectID)
			return;

		if (CurrentGamemodeID == GAMEMODE_SURVIVAL && !GetConVarBool(cvar_EnableSvMedicPoints))
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		GiveAdrenaline(User, Recipient);

		return;
	}

	if (AwardID == 85) // Incap friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		PlayerIncap(User, Recipient);

		return;
	}

	if (AwardID == 80) // Respawn friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recipient))
			return;

		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		AddScore(User, Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				PrintToChat(User, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Rescuing \x05%s\x01!", Score, RecipientName);
			else if (Mode == 3)
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Rescuing \x05%s\x01!", UserName, Score, RecipientName);
		}
	}
	else if (AwardID == 81) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to event_PlayerDeath
//	else if (AwardID == 84 && !CampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Team Killing!", Score);
//		else if (Mode == 3)
//			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing!", UserName, Score);
//	}
	else if (AwardID == 86) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1);
	}
	else if (AwardID == 95) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (GetConVarBool(cvar_EnableNegativeScore))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_InSafeRoom), 2, 4);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2)
			PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", Score);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 99) // Round restart
	{
		UpdateMapStat("restarts", 1);

		if (!GetConVarBool(cvar_EnableNegativeScore))
			return;

		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3);
		Score = 400 - Score;

		if (Mode)
			PrintToChat(User, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying!", Score);

		Score = Score * -1;
	}
	else
		return;

	decl String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientName(User, UserID, sizeof(UserID));

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i%s WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
}

// Scavenge halftime code.

public Action:event_ScavengeHalftime(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	CampaignOver = true;

	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}
}

// Survival started code.

public Action:event_SurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	SurvivalStart();
}

public SurvivalStart()
{
	UpdateMapStat("restarts", 1);
	SurvivalStarted = true;
	MapTimingStartTime = 0.0;
	StartMapTiming();
}

// Car alarm triggered code.

public Action:event_CarAlarm(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CurrentGamemodeID == GAMEMODE_SURVIVAL || !GetConVarBool(cvar_EnableNegativeScore))
		return;

	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_CarAlarm), 2, 3);
	UpdateMapStat("caralarm", 1);

	if (Score <= 0)
		return;

	decl String:UpdatePoints[32];
	decl String:query[1024];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	new maxplayers = GetMaxClients();
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:iID[MAX_LINE_WIDTH];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientName(i, iID, sizeof(iID));
			Format(query, sizeof(query), "UPDATE players SET %s = %s - %i WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);

			if (Mode)
				PrintToChat(i, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03Triggering the Car Alarm\x01!", Score);
		}
	}
}

// Reset Witch existence in the world when a new one is created.

public Action:event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	WitchExists = true;
}

// Witch was crowned!

public Action:event_WitchCrowned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Killer = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:Crowned = GetEventBool(event, "oneshot");

	if (Crowned && Killer > 0 && !IsClientBot(Killer) && IsClientConnected(Killer) && IsClientInGame(Killer))
	{
		decl String:SteamID[MAX_LINE_WIDTH];
		GetClientName(Killer, SteamID, sizeof(SteamID));

		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_WitchCrowned), 2, 3);
		decl String:UpdatePoints[32];

		switch (CurrentGamemodeID)
		{
			case GAMEMODE_VERSUS:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			}
			case GAMEMODE_REALISM:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
			}
			case GAMEMODE_SURVIVAL:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
			}
			case GAMEMODE_SCAVENGE:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
			}
			default:
			{
				Format(UpdatePoints, sizeof(UpdatePoints), "points");
			}
		}

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_witchcrowned = award_witchcrowned + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, SteamID);
		SendSQLUpdate(query);

		if (Score > 0 && GetConVarInt(cvar_AnnounceMode))
		{
			decl String:Name[MAX_LINE_WIDTH];
			GetClientName(Killer, Name, sizeof(Name));

			PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for \x04Crowning the Witch\x01!", Name, Score);
		}
	}
}

// Witch was disturbed!

public Action:event_WitchDisturb(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (WitchExists)
	{
		WitchDisturb = true;

		if (!GetEventInt(event, "userid"))
			return;

		new User = GetClientOfUserId(GetEventInt(event, "userid"));

		if (IsClientBot(User))
			return;

		decl String:UserID[MAX_LINE_WIDTH];
		GetClientName(User, UserID, sizeof(UserID));

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE players SET award_witchdisturb = award_witchdisturb + 1 WHERE steamid = '%s'", UserID);
		SendSQLUpdate(query);
	}
}

// DEBUG
//public Action:cmd_StatsTest(client, args)
//{
//	new String:CurrentMode[16];
//	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));
//	PrintToConsole(0, "Gamemode: %s", CurrentMode);
//	UpdateMapStat("playtime", 10);
//	PrintToConsole(0, "Added 10 seconds to maps table current map.");
//	new Float:ReductionFactor = GetMedkitPointReductionFactor();
//
//	PrintToChat(client, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter, (MedkitsUsedCounter == 1 ? "st" : (MedkitsUsedCounter == 2 ? "nd" : (MedkitsUsedCounter == 3 ? "rd" : "th"))), GetClientTeam(client));
//}

/*
-----------------------------------------------------------------------------
Chat/command handling and panels for Rank and Top10
-----------------------------------------------------------------------------
*/

// Parse chat for RANK and TOP10 triggers.
public Action:cmd_Say(client, args)
{
	decl String:Text[192];
	new String:Command[64];
	new Start = 0;

	GetCmdArgString(Text, sizeof(Text));

	if (Text[strlen(Text)-1] == '"')
	{
		Text[strlen(Text)-1] = '\0';
		Start = 1;
	}

	if (strcmp(Command, "say2", false) == 0)
		Start += 4;

	if (strcmp(Text[Start], "rank", false) == 0)
	{
		cmd_ShowRank(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "showrank", false) == 0)
	{
		cmd_ShowRanks(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "showppm", false) == 0)
	{
		cmd_ShowPPMs(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "top10", false) == 0)
	{
		cmd_ShowTop10(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "top10ppm", false) == 0)
	{
		cmd_ShowTop10PPM(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "nextrank", false) == 0)
	{
		cmd_ShowNextRank(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "showtimer", false) == 0)
	{
		cmd_ShowTimedMapsTimer(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	else if (strcmp(Text[Start], "rankvote", false) == 0)
	{
		cmd_RankVote(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Show current Timed Maps timer.
public Action:cmd_ShowTimedMapsTimer(client, args)
{
	if (client != 0 && !IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (client != 0 && IsClientBot(client))
		return Plugin_Handled;

	if (MapTimingStartTime <= 0.0)
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] Map timer has not started");
		else
			PrintToChat(client, "\x04[\x03RANK\x04] \x01Map timer has not started");

		return Plugin_Handled;
	}

	new Float:CurrentMapTimer = GetEngineTime() - MapTimingStartTime;

	if (client == 0)
		PrintToConsole(0, "[RANK] Current map timer: %.2f seconds", CurrentMapTimer);
	else
		PrintToChat(client, "\x04[\x03RANK\x04] \x01Current map timer: \x04%.2f seconds", CurrentMapTimer);

	return Plugin_Handled;
}

// Begin generating the NEXTRANK display panel.
public Action:cmd_ShowNextRank(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	QueryClientStatsSteamID(client, SteamID, CM_NEXTRANK);

	return Plugin_Handled;
}

// Clear database.
//public Action:cmd_RankAdmin(client, args)
//{
//	if (!client)
//		return Plugin_Handled;
//
//	new Handle:RankAdminPanel = CreatePanel();
//
//	SetPanelTitle(RankAdminPanel, "Rank Admin:");
//
//	DrawPanelItem(RankAdminPanel, "Clear...");
//	DrawPanelItem(RankAdminPanel, "Clear Players");
//	DrawPanelItem(RankAdminPanel, "Clear Maps");
//	DrawPanelItem(RankAdminPanel, "Clear All");
//
//	SendPanelToClient(RankAdminPanel, client, RankAdminPanelHandler, 30);
//	CloseHandle(RankAdminPanel);
//
//	return Plugin_Handled;
//}

DisplayYesNoPanel(client, const String:title[], MenuHandler:handler, delay=30)
{
	if (!client)
		return;

	new Handle:panel = CreatePanel();

	SetPanelTitle(panel, title);

	DrawPanelItem(panel, "Yes");
	DrawPanelItem(panel, "No");

	SendPanelToClient(panel, client, handler, delay);
	CloseHandle(panel);
}

// Run Team Shuffle.
public Action:cmd_ShuffleTeams(client, args)
{
	if (!IsGamemode("versus") && !IsGamemode("scavenge"))
	{
		PrintToConsole(client, "[RANK] Team shuffle is not enabled in this gamemode!");
		return Plugin_Handled;
	}

	if (RankVoteTimer != INVALID_HANDLE)
	{
		CloseHandle(RankVoteTimer);
		RankVoteTimer = INVALID_HANDLE;

		PrintToChatAll("\x04[\x03RANK\x04] \x01Team shuffle executed by administrator.");
	}

	PrintToConsole(client, "[RANK] Executing team shuffle...");
	CreateTimer(1.0, timer_ShuffleTeams);

	return Plugin_Handled;
}

// Clear database.
public Action:cmd_ClearRank(client, args)
{
	if (ClearDatabaseTimer != INVALID_HANDLE)
		CloseHandle(ClearDatabaseTimer);

	ClearDatabaseTimer = INVALID_HANDLE;

	if (ClearDatabaseCaller == client)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Started clearing the database!");
		ClearDatabaseCaller = -1;

		ClearStatsAll(client);

		return Plugin_Handled;
	}

	PrintToConsole(client, "[RANK] Clear Stats: To clear the database, execute this command again in %.2f seconds!", CLEAR_DATABASE_CONFIRMTIME);
	ClearDatabaseCaller = client;

	ClearDatabaseTimer = CreateTimer(CLEAR_DATABASE_CONFIRMTIME, timer_ClearDatabase);

	return Plugin_Handled;
}

public ClearStatsMaps(client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	SQL_TQuery(db, ClearStatsMapsHandler, "SELECT * FROM maps WHERE 1 = 2", client);
}

public ClearStatsAll(client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	if (!DoFastQuery(client, "DELETE FROM timedmaps"))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing timedmaps table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");

		return;
	}

	if (!DoFastQuery(client, "DELETE FROM players"))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing players table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");

		return;
	}

	SQL_TQuery(db, ClearStatsMapsHandler, "SELECT * FROM maps WHERE 1 = 2", client);
}

public ClearStatsPlayers(client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	if (!DoFastQuery(client, "DELETE FROM players"))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing players table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
	}
	else
	{
		DoFastQuery(client, "COMMIT");
		PrintToConsole(client, "[RANK] Clear Stats: Ranks succesfully cleared!");
	}
}

public ClearStatsMapsHandler(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Query failed! (%s)", error);
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
		return;
	}

	new FieldCount = SQL_GetFieldCount(hndl);
	decl String:FieldName[MAX_LINE_WIDTH];
	decl String:FieldSet[MAX_LINE_WIDTH];

	new Counter = 0;
	decl String:query[4096];
	Format(query, sizeof(query), "UPDATE maps SET");

	for (new i = 0; i < FieldCount; i++)
	{
		SQL_FieldNumToName(hndl, i, FieldName, sizeof(FieldName));

		if (StrEqual(FieldName, "name", false) ||
				StrEqual(FieldName, "gamemode", false) ||
				StrEqual(FieldName, "custom", false))
			continue;

		if (Counter++ > 0)
			StrCat(query, sizeof(query), ",");

		Format(FieldSet, sizeof(FieldSet), " %s = 0", FieldName);
		StrCat(query, sizeof(query), FieldSet);
	}

	if (!DoFastQuery(client, query))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing maps table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
	}
	else
	{
		DoFastQuery(client, "COMMIT");
		PrintToConsole(client, "[RANK] Clear Stats: Stats succesfully cleared!", query);
	}
}

DoFastQuery(Client, const String:Query[], any:...)
{
	new String:FormattedQuery[4096];
	VFormat(FormattedQuery, sizeof(FormattedQuery), Query, 3);

	new String:Error[1024];

	if (!SQL_FastQuery(db, FormattedQuery))
	{
		if (SQL_GetError(db, Error, sizeof(Error)))
		{
			PrintToConsole(Client, "[RANK] Clear Stats: Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
			LogError("Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
		}
		else
		{
			PrintToConsole(Client, "[RANK] Clear Stats: Fast query failed! Query = \"%s\"", FormattedQuery);
			LogError("Fast query failed! Query = \"%s\"", FormattedQuery);
		}

		return false;
	}

	return true;
}

public Action:timer_ClearDatabase(Handle:timer, any:data)
{
	ClearDatabaseTimer = INVALID_HANDLE;
	ClearDatabaseCaller = -1;
}

// Begin generating the RANK display panel.
public Action:cmd_ShowRank(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	QueryClientStatsSteamID(client, SteamID, CM_RANK);

	return Plugin_Handled;
}

// Generate client's point total.
public GetClientPointsRankChange(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientPointsRankChange Query failed: %s", error);
		return;
	}

	GetClientPoints(owner, hndl, error, client);
	QueryClientRank(client, GetClientRankRankChange);
}

// Generate client's point total.
public GetClientPoints(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientPoints Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
		ClientPoints[client] = SQL_FetchInt(hndl, 0);
}

// Generate client's gamemode point total.
public GetClientGameModePoints(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientGameModePoints Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
	{
		ClientGameModePoints[client][GAMEMODE_COOP] = SQL_FetchInt(hndl, GAMEMODE_COOP);
		ClientGameModePoints[client][GAMEMODE_VERSUS] = SQL_FetchInt(hndl, GAMEMODE_VERSUS);
		ClientGameModePoints[client][GAMEMODE_REALISM] = SQL_FetchInt(hndl, GAMEMODE_REALISM);
		ClientGameModePoints[client][GAMEMODE_SURVIVAL] = SQL_FetchInt(hndl, GAMEMODE_SURVIVAL);
		ClientGameModePoints[client][GAMEMODE_SCAVENGE] = SQL_FetchInt(hndl, GAMEMODE_SCAVENGE);
	}
}

// Generate client's next rank.
public DisplayClientNextRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	GetClientNextRank(owner, hndl, error, client);

	DisplayNextRank(client);
}

// Generate client's next rank.
public GetClientNextRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	if (SQL_FetchRow(hndl))
		ClientNextRank[client] = SQL_FetchInt(hndl, 0);
	else
		ClientNextRank[client] = 0;
}

// Generate client's rank.
public GetClientRankRankChange(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRankRankChange Query failed: %s", error);
		return;
	}

	GetClientRank(owner, hndl, error, client);

	if (RankChangeLastRank[client] != ClientRank[client])
	{
		new RankChange = RankChangeLastRank[client] - ClientRank[client];

		if (!RankChangeFirstCheck[client] && RankChange == 0)
			return;

		RankChangeLastRank[client] = ClientRank[client];

		if (RankChangeFirstCheck[client])
		{
			RankChangeFirstCheck[client] = false;
			return;
		}

		if (!GetConVarInt(cvar_AnnounceMode) || !GetConVarBool(cvar_AnnounceRankChange))
			return;

		decl String:Label[16];
		if (RankChange > 0)
			Format(Label, sizeof(Label), "GAINED");
		else
		{
			RankChange *= -1;
			Format(Label, sizeof(Label), "DROPPED");
		}

		if (!IsClientBot(client) && IsClientConnected(client) && IsClientInGame(client))
			PrintToChat(client, "\x04[\x03RANK\x04] \x01You've \x04%s \x01rank for \x04%i position%s\x01! \x05(Rank: %i)", Label, RankChange, (RankChange > 1 ? "s" : ""), RankChangeLastRank[client]);
	}
}

// Generate client's rank.
public GetClientRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientRank Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
		ClientRank[client] = SQL_FetchInt(hndl, 0);
}

// Generate client's rank.
public GetClientGameModeRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientGameModeRank Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
		ClientGameModeRank[client] = SQL_FetchInt(hndl, 0);
}

// Generate total rank amount.
public GetRankTotal(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("GetRankTotal Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
		RankTotal = SQL_FetchInt(hndl, 0);
}

// Generate total gamemode rank amount.
public GetGameModeRankTotal(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("GetGameModeRankTotal Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
		GameModeRankTotal = SQL_FetchInt(hndl, 0);
}

// Send the NEXTRANK panel to the client's display.
public DisplayNextRank(client)
{
	if (!client)
		return;

	new Handle:NextRankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];

	SetPanelTitle(NextRankPanel, "Next Rank:");

	if (ClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", ClientNextRank[client]);
		DrawPanelText(NextRankPanel, Value);

		Format(Value, sizeof(Value), "Current rank: %i", ClientRank[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	else
		DrawPanelText(NextRankPanel, "You are 1st");

	DrawPanelItem(NextRankPanel, "More...");
	DrawPanelItem(NextRankPanel, "Close");
	SendPanelToClient(NextRankPanel, client, NextRankPanelHandler, 30);
	CloseHandle(NextRankPanel);
}

// Send the NEXTRANK panel to the client's display.
public DisplayNextRankFull(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayNextRankFull Query failed: %s", error);
		return;
	}

	if(SQL_GetRowCount(hndl) <= 1)
		return;

	new Points;
	decl String:Name[32];

	new Handle:NextRankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];

	SetPanelTitle(NextRankPanel, "Next Rank:");

	if (ClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", ClientNextRank[client]);
		DrawPanelText(NextRankPanel, Value);

		Format(Value, sizeof(Value), "Current rank: %i", ClientRank[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	else
		DrawPanelText(NextRankPanel, "You are 1st");

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		Points = SQL_FetchInt(hndl, 1);

		Format(Value, sizeof(Value), "%i points: %s", Points, Name);
		DrawPanelText(NextRankPanel, Value);
	}

	DrawPanelItem(NextRankPanel, "Close");
	SendPanelToClient(NextRankPanel, client, NextRankFullPanelHandler, 30);
	CloseHandle(NextRankPanel);
}

// Send the RANK panel to the client's display.
public DisplayRank(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayRank Query failed: %s", error);
		return;
	}

	new Float:PPM;
	new Playtime, Points, InfectedKilled, SurvivorsKilled, Headshots;
	new String:Name[32];

	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		Playtime = SQL_FetchInt(hndl, 1);
		Points = SQL_FetchInt(hndl, 2);
		InfectedKilled = SQL_FetchInt(hndl, 3);
		SurvivorsKilled = SQL_FetchInt(hndl, 4);
		Headshots = SQL_FetchInt(hndl, 5);
		PPM = float(Points) / float(Playtime);
	}
	else
	{
		GetClientName(client, Name, sizeof(Name));
		Playtime = 0;
		Points = 0;
		InfectedKilled = 0;
		SurvivorsKilled = 0;
		Headshots = 0;
		PPM = 0.0;
	}

	new Handle:RankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];
	new String:URL[MAX_LINE_WIDTH];

	GetConVarString(cvar_SiteURL, URL, sizeof(URL));
	new Float:HeadshotRatio = Headshots == 0 ? 0.00 : FloatDiv(float(Headshots), float(InfectedKilled))*100;

	Format(Value, sizeof(Value), "Ranking of %s" , Name);
	SetPanelTitle(RankPanel, Value);

	Format(Value, sizeof(Value), "Rank: %i of %i" , ClientRank[client], RankTotal);
	DrawPanelText(RankPanel, Value);

	if (!InvalidGameMode())
	{
		Format(Value, sizeof(Value), "%s Rank: %i of %i" ,CurrentGamemodeLabel , ClientGameModeRank[client], GameModeRankTotal);
		DrawPanelText(RankPanel, Value);
	}

	if (Playtime > 60)
	{
		Format(Value, sizeof(Value), "Playtime: %.2f hours" , FloatDiv(float(Playtime), 60.0));
		DrawPanelText(RankPanel, Value);
	}
	else
	{
		Format(Value, sizeof(Value), "Playtime: %i min" , Playtime);
		DrawPanelText(RankPanel, Value);
	}

	Format(Value, sizeof(Value), "Points: %i" , Points);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "PPM: %.2f" , PPM);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Infected Killed: %i" , InfectedKilled);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Survivors Killed: %i" , SurvivorsKilled);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Headshots: %i" , Headshots);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Headshot Ratio: %.2f \%" , HeadshotRatio);
	DrawPanelText(RankPanel, Value);

	if (!StrEqual(URL, "", false))
	{
		Format(Value, sizeof(Value), "For full stats visit %s", URL);
		DrawPanelText(RankPanel, Value);
	}

	//DrawPanelItem(RankPanel, "Next Rank");
	DrawPanelItem(RankPanel, "Close");
	SendPanelToClient(RankPanel, client, RankPanelHandler, 30);
	CloseHandle(RankPanel);
}

public StartRankVote(client)
{
	if (L4DStatsConf == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToChat(client, "\x04[\x03RANK\x04] \x01The \x04Rank Vote \x01is \x03DISABLED\x01. \x05Plugin configurations failed.");
		else
			PrintToConsole(0, "[RANK] The Rank Vote is DISABLED! Could not load gamedata/l4d_stats.txt.");
	}

	else if (!GetConVarBool(cvar_EnableRankVote))
	{
		if (client > 0)
			PrintToChat(client, "\x04[\x03RANK\x04] \x01The \x04Rank Vote \x01is \x03DISABLED\x01.");
		else
			PrintToConsole(0, "[RANK] The Rank Vote is DISABLED.");
	}

	else
		InitializeRankVote(client);
}

// Start RANKVOTE.
public Action:cmd_RankVote(client, args)
{
	if (client == 0)
	{
		StartRankVote(client);
		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	new ClientFlags = GetUserFlagBits(client);
	new bool:IsAdmin = ((ClientFlags & ADMFLAG_GENERIC) == ADMFLAG_GENERIC);

	new ClientTeam = GetClientTeam(client);

	if (!IsAdmin && ClientTeam != TEAM_SURVIVORS && ClientTeam != TEAM_INFECTED)
	{
		PrintToChat(client, "\x04[\x03RANK\x04] \x01The spectators cannot initiate the \x04Rank Vote\x01.");
		return Plugin_Handled;
	}

	StartRankVote(client);

	return Plugin_Handled;
}

// Generate the SHOWPPM display menu.
public Action:cmd_ShowPPMs(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[1024];
	//Format(query, sizeof(query), "SELECT COUNT(*) FROM players");
	//SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, (%s) / (%s) AS ppm FROM players WHERE ", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME);

	new maxplayers = GetMaxClients();
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientName(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter == 0)
		return Plugin_Handled;

	if (counter == 1)
	{
		cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY ppm DESC");

	SQL_TQuery(db, CreatePPMsMenu, query, client);

	return Plugin_Handled;
}

// Generate the SHOWRANK display menu.
public Action:cmd_ShowRanks(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[1024];
	//Format(query, sizeof(query), "SELECT COUNT(*) FROM players");
	//SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, %s AS totalpoints FROM players WHERE ", DB_PLAYERS_TOTALPOINTS);

	new maxplayers = GetMaxClients();
	decl String:SteamID[MAX_LINE_WIDTH], String:where[512];
	new counter = 0;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientName(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter == 0)
		return Plugin_Handled;

	if (counter == 1)
	{
		cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY totalpoints DESC");

	SQL_TQuery(db, CreateRanksMenu, query, client);

	return Plugin_Handled;
}

// Generate the TOPPPM display panel.
public Action:cmd_ShowTop10PPM(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[1024];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM players");
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name, (%s) / (%s) AS ppm FROM players ORDER BY ppm DESC, (%s) DESC LIMIT 10", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, DB_PLAYERS_TOTALPLAYTIME);
	SQL_TQuery(db, DisplayTop10PPM, query, client);

	return Plugin_Handled;
}

// Generate the TOP10 display panel.
public Action:cmd_ShowTop10(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM players");
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name FROM players ORDER BY %s DESC LIMIT 10", DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayTop10, query, client);

	return Plugin_Handled;
}

// Find a player from Top 10 ranking.
public GetClientFromTop10(client, rank)
{
	decl String:query[256];
	Format(query, sizeof(query), "SELECT %s as totalpoints, steamid FROM players ORDER BY totalpoints DESC LIMIT %i,1", DB_PLAYERS_TOTALPOINTS, rank);
	SQL_TQuery(db, GetClientTop10, query, client);
}

// Send the Top 10 player's info to the client.
public GetClientTop10(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
		return;

	decl String:SteamID[MAX_LINE_WIDTH];

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, SteamID, sizeof(SteamID));

		QueryClientStatsSteamID(client, SteamID, CM_TOP10);
	}
}

public ExecuteTeamShuffle(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("ExecuteTeamShuffle failed! Reason: %s", error);
		return;
	}

	decl String:SteamID[MAX_LINE_WIDTH];
	new i, team, maxplayers = GetMaxClients(), client, topteam;
	new SurvivorsLimit = GetConVarInt(cvar_SurvivorLimit), InfectedLimit = GetConVarInt(cvar_InfectedLimit);
	new Handle:PlayersTrie = CreateTrie();
	new Handle:InfectedArray = CreateArray();
	new Handle:SurvivorArray = CreateArray();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			GetClientName(i, SteamID, sizeof(SteamID));

			if (!SetTrieValue(PlayersTrie, SteamID, i, false))
			{
				LogError("ExecuteTeamShuffle failed! Reason: Duplicate SteamID while generating shuffled teams.");
				PrintToChatAll("\x04[\x03RANK\x04] \x01Team shuffle failed in an error.");

				SetConVarBool(cvar_EnableRankVote, false);

				ClearTrie(PlayersTrie);
				CloseHandle(PlayersTrie);

				CloseHandle(hndl);

				return;
			}

			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					PushArrayCell(SurvivorArray, i);
				case TEAM_INFECTED:
					PushArrayCell(InfectedArray, i);
			}
		}
	}

	new SurvivorCounter = GetArraySize(SurvivorArray);
	new InfectedCounter = GetArraySize(InfectedArray);

	i = 0;
	topteam = 0;

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));

		if (GetTrieValue(PlayersTrie, SteamID, client))
		{
			team = GetClientTeam(client);

			if (i == 0)
			{
				if (team == TEAM_SURVIVORS)
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				else
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));

				topteam = team;
				i++;

				continue;
			}

			if (i++ % 2)
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_INFECTED)
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
				else if (topteam == TEAM_INFECTED && team == TEAM_SURVIVORS)
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
			}
			else
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_SURVIVORS)
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				else if (topteam == TEAM_INFECTED && team == TEAM_INFECTED)
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
			}
		}
	}

	if (GetArraySize(SurvivorArray) > 0 || GetArraySize(InfectedArray) > 0)
	{
		new NewSurvivorCounter = SurvivorCounter - GetArraySize(SurvivorArray) + GetArraySize(InfectedArray);
		new NewInfectedCounter = InfectedCounter - GetArraySize(InfectedArray) + GetArraySize(SurvivorArray);

		if (NewSurvivorCounter > SurvivorsLimit || NewInfectedCounter > InfectedLimit)
		{
			LogError("ExecuteTeamShuffle failed! Reason: Team size limits block Rank Vote functionality. (Survivors Limit = %i [%i] / Infected Limit = %i [%i])", SurvivorsLimit, NewSurvivorCounter, InfectedLimit, NewInfectedCounter);
			PrintToChatAll("\x04[\x03RANK\x04] \x01Team shuffle failed in an error.");

			SetConVarBool(cvar_EnableRankVote, false);
		}
		else
		{
			CampaignOver = true;

			decl String:Name[32];

			// Change Survivors team to Spectators (TEMPORARILY)
			for (i = 0; i < GetArraySize(SurvivorArray); i++)
				ChangePlayerTeam(GetArrayCell(SurvivorArray, i), TEAM_SPECTATORS);

			// Change Infected team to Survivors
			for (i = 0; i < GetArraySize(InfectedArray); i++)
			{
				client = GetArrayCell(InfectedArray, i);
				GetClientName(client, Name, sizeof(Name));

				ChangePlayerTeam(client, TEAM_SURVIVORS);

				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01was swapped to team \x03Survivors\x01!", Name);
			}

			// Change Spectators (TEMPORARILY) team to Infected
			for (i = 0; i < GetArraySize(SurvivorArray); i++)
			{
				client = GetArrayCell(SurvivorArray, i);
				GetClientName(client, Name, sizeof(Name));

				ChangePlayerTeam(client, TEAM_INFECTED);

				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01was swapped to team \x03Infected\x01!", Name);
			}

			PrintToChatAll("\x04[\x03RANK\x04] \x01Team shuffle by player PPM \x03DONE\x01.");
		}
	}
	else
	{
		PrintToChatAll("\x04[\x03RANK\x04] \x01Teams are already even by player PPM.");
	}

	ClearArray(SurvivorArray);
	ClearArray(InfectedArray);
	ClearTrie(PlayersTrie);

	CloseHandle(SurvivorArray);
	CloseHandle(InfectedArray);
	CloseHandle(PlayersTrie);

	CloseHandle(hndl);
}

public CreateRanksMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	new Handle:menu = CreateMenu(Menu_CreateRanksMenuHandler);

	decl String:Name[32], String:DisplayName[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Player Ranks:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (%i points)", Name, SQL_FetchInt(hndl, 2));

		AddMenuItem(menu, SteamID, DisplayName);
	}

	DisplayMenu(menu, client, 30);
}

public CreatePPMsMenu(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	new Handle:menu = CreateMenu(Menu_CreateRanksMenuHandler);

	decl String:Name[32], String:DisplayName[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Player PPM:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (PPM: %.2f)", Name, SQL_FetchFloat(hndl, 2));

		AddMenuItem(menu, SteamID, DisplayName);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateRanksMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	new bool:found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID));

	if (!found)
	{
		CloseHandle(menu);
		return;
	}

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);
}

// Send the TOP10 panel to the client's display.
public DisplayTop10(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
		return;

	new String:Name[32];

	new Handle:Top10Panel = CreatePanel();
	SetPanelTitle(Top10Panel, "Top 10 Players");

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		DrawPanelItem(Top10Panel, Name);
	}

	SendPanelToClient(Top10Panel, client, Top10PanelHandler, 30);
	CloseHandle(Top10Panel);
}

// Send the TOP10PPM panel to the client's display.
public DisplayTop10PPM(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!client || hndl == INVALID_HANDLE)
		return;

	decl String:Name[32], String:Disp[MAX_LINE_WIDTH];

	new Handle:TopPPMPanel = CreatePanel();
	SetPanelTitle(TopPPMPanel, "Top 10 PPM Players");

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(Disp, sizeof(Disp), "%s (PPM: %.2f)", Name, SQL_FetchFloat(hndl, 1));

		DrawPanelItem(TopPPMPanel, Disp);
	}

	SendPanelToClient(TopPPMPanel, client, Top10PanelHandler, 30);
	CloseHandle(TopPPMPanel);
}

// Handler for RANK panel.
public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

// Handler for NEXTRANK panel.
public NextRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (param2 == 1)
		QueryClientStats(param1, CM_NEXTRANKFULL);
}

// Handler for NEXTRANK panel.
public NextRankFullPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

// Handler for RANKADMIN panel.
//public RankAdminPanelHandler(Handle:menu, MenuAction:action, param1, param2)
//{
//	if (action != MenuAction_Select)
//		return;
//
//	if (param2 == 1)
//		DisplayClearPanel(param1);
//	else if (param2 == 2)
//		DisplayYesNoPanel(param1, "Do you really want to clear the player stats?", ClearPlayersPanelHandler);
//	else if (param2 == 3)
//		DisplayYesNoPanel(param1, "Do you really want to clear the map stats?", ClearMapsPanelHandler);
//	else if (param2 == 4)
//		DisplayYesNoPanel(param1, "Do you really want to clear all stats?", ClearAllPanelHandler);
//}

// Handler for RANKADMIN panel.
public ClearPlayersPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		ClearStatsPlayers(param1);
		PrintToChat(param1, "\x04[\x03RANK\x04] \x01All player stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearMapsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		ClearStatsMaps(param1);
		PrintToChat(param1, "\x04[\x03RANK\x04] \x01All map stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearAllPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		ClearStatsAll(param1);
		PrintToChat(param1, "\x04[\x03RANK\x04] \x01All stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public CleanPlayersPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		new LastOnTimeMonths = GetConVarInt(cvar_AdminPlayerCleanLastOnTime);
		new PlaytimeMinutes = GetConVarInt(cvar_AdminPlayerCleanPlatime);

		if (LastOnTimeMonths || PlaytimeMinutes)
		{
			new bool:Success = true;

			if (LastOnTimeMonths)
				Success &= DoFastQuery(param1, "DELETE FROM players WHERE lastontime < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL %i MONTH))", LastOnTimeMonths);

			if (PlaytimeMinutes)
				Success &= DoFastQuery(param1, "DELETE FROM players WHERE %s < %i", DB_PLAYERS_TOTALPLAYTIME, PlaytimeMinutes);

			if (Success)
				PrintToChat(param1, "\x04[\x03RANK\x04] \x01Player cleaning successful!");
			else
				PrintToChat(param1, "\x04[\x03RANK\x04] \x01Player cleaning failed!");
		}
		else
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Player cleaning is disabled by configurations!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public RemoveCustomMapsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM maps WHERE custom = 1"))
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01All custom maps removed!");
		else
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Removing custom maps failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMAllPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM timedmaps"))
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01All map timings removed!");
		else
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Removing map timings failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMCoopPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM timedmaps WHERE gamemode = %i", GAMEMODE_COOP))
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing map timings for Coop successful!");
		else
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing map timings for Coop failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMSurvivalPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM timedmaps WHERE gamemode = %i", GAMEMODE_SURVIVAL))
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing map timings for Survival successful!");
		else
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing map timings for Survival failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMRealismPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM timedmaps WHERE gamemode = %i", GAMEMODE_REALISM))
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing map timings for Realism successful!");
		else
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing map timings for Realism failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKVOTE panel.
public RankVotePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select || RankVoteTimer == INVALID_HANDLE || param1 <= 0 || IsClientBot(param1))
		return;

	if (param2 == 1 || param2 == 2)
	{
		new team = GetClientTeam(param1);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			return;

		new OldPlayerRankVote = PlayerRankVote[param1];

		if (param2 == 1)
			PlayerRankVote[param1] = RANKVOTE_YES;
		else if (param2 == 2)
			PlayerRankVote[param1] = RANKVOTE_NO;

		new humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;

		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		if (yesvotes >= WinningVoteCount || novotes >= WinningVoteCount)
		{
			if (RankVoteTimer != INVALID_HANDLE)
			{
				CloseHandle(RankVoteTimer);
				RankVoteTimer = INVALID_HANDLE;
			}

			PrintToChatAll("\x04[\x03RANK\x04] \x01Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes >= WinningVoteCount ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

			if (yesvotes >= WinningVoteCount)
				CreateTimer(2.0, timer_ShuffleTeams);
		}

		if (OldPlayerRankVote != RANKVOTE_NOVOTE)
			return;

		decl String:Name[32];
		GetClientName(param1, Name, sizeof(Name));

		PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01voted. \x04%i/%i \x01players have voted.", Name, votes, humans);
	}
}

CheckRankVotes(&Humans, &Votes, &YesVotes, &NoVotes, &WinningVoteCount)
{
	Humans = 0;
	Votes = 0;
	YesVotes = 0;
	NoVotes = 0;
	WinningVoteCount = 0;

	new i, team, maxplayers = GetMaxClients();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
			{
				Humans++;

				if (PlayerRankVote[i] != RANKVOTE_NOVOTE)
				{
					Votes++;

					if (PlayerRankVote[i] == RANKVOTE_YES)
						YesVotes++;
				}
			}
		}
	}

	// More than half of the players are needed to vot YES for rankvote pass
	WinningVoteCount = RoundToNearest(float(Humans) / 2) + 1 - (Humans % 2);
	NoVotes = Votes - YesVotes;
}

DisplayClearPanel(client, delay=30)
{
	if (!client)
		return;

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}

	new Handle:ClearPlayerMenu = CreateMenu(DisplayClearPanelHandler);
	new maxplayers = GetMaxClients();
	decl String:id[3], String:Name[32];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		GetClientName(i, Name, sizeof(Name));
		IntToString(i, id, sizeof(id));

		AddMenuItem(ClearPlayerMenu, id, Name);
	}

	SetMenuTitle(ClearPlayerMenu, "Clear player stats:");
	DisplayMenu(ClearPlayerMenu, client, delay);
}

// Handler for RANKADMIN panel.
public DisplayClearPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	decl String:id[3];
	new bool:found = GetMenuItem(menu, param2, id, sizeof(id));

	if (!found)
		return;

	new client = StringToInt(id);

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	if (DoFastQuery(param1, "DELETE FROM players WHERE steamid = '%s'", SteamID))
	{
		ClientPoints[client] = 0;
		ClientRank[client] = 0;

		decl String:Name[32];
		GetClientName(client, Name, sizeof(Name));

		PrintToChat(client, "\x04[\x03RANK\x04] \x01Your player stats were cleared!");
		if (client != param1)
			PrintToChat(param1, "\x04[\x03RANK\x04] \x01Player \x05%s \x01stats cleared!", Name);
	}
	else
		PrintToChat(param1, "\x04[\x03RANK\x04] \x01Clearing player stats failed!");
}

// Handler for TOP10 panel.
public Top10PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10(param1, param2 - 1);
	}
}

/*
-----------------------------------------------------------------------------
Private functions
-----------------------------------------------------------------------------
*/

HunterSmokerSave(Savior, Victim, BasePoints, AdvMult, ExpertMult, String:SaveFrom[], String:SQLField[])
{
	if (StatsDisabled())
		return;

	Savior = GetClientOfUserId(Savior);
	Victim = GetClientOfUserId(Victim);

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	decl String:SaviorID[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VictimID[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimID, sizeof(VictimID));

	if (StrEqual(SaviorID, VictimID))
		return;

	new Score = ModifyScoreDifficulty(BasePoints, AdvMult, ExpertMult);
	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, %s = %s + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, SQLField, SQLField, SaviorID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	if (Mode)
		PrintToChat(Savior, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for saving \x05%s\x01 from \x04%s\x01!", Score, VictimName, SaveFrom);

	UpdateMapStat("points", Score);
	AddScore(Savior, Score);
}

IsClientBot(client)
{
	if (client == 0 || !IsClientConnected(client))
		return true;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientName(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

ModifyScoreRealism(BaseScore, bool:ToCeil=true)
{
	if (ServerVersion != SERVER_VERSION_L4D1 && IsGamemodeRealism())
	{
		if (ToCeil)
			BaseScore = RoundToCeil(GetConVarFloat(cvar_RealismMultiplier) * BaseScore);
		else
			BaseScore = RoundToFloor(GetConVarFloat(cvar_RealismMultiplier) * BaseScore);
	}

	return BaseScore;
}

ModifyScoreDifficultyFloatNR(BaseScore, Float:AdvMult, Float:ExpMult, bool:ToCeil=true, bool:IsSurvivorScore=false)
{
	return ModifyScoreDifficultyFloat(BaseScore, AdvMult, ExpMult, ToCeil, IsSurvivorScore, false);
}

ModifyScoreDifficultyFloat(BaseScore, Float:AdvMult, Float:ExpMult, bool:ToCeil=true, bool:IsSurvivorScore=false, bool:Reduction = true)
{
	if (BaseScore <= 0)
		return 0;

	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	new Float:ModifiedScore;

	if (StrEqual(Difficulty, "Hard", false)) ModifiedScore = BaseScore * AdvMult;
	else if (StrEqual(Difficulty, "Impossible", false)) ModifiedScore = BaseScore * ExpMult;
	else return ModifyScoreRealism(BaseScore);

	new Score = 0;
	if (ToCeil)
		Score = RoundToCeil(ModifiedScore);
	else
		Score = RoundToFloor(ModifiedScore);

	if (IsSurvivorScore && Reduction)
		Score = GetMedkitPointReductionScore(Score );

	return ModifyScoreRealism(Score, ToCeil);
}

// Score modifier without point reduction. Usable for minus points.

ModifyScoreDifficultyNR(BaseScore, AdvMult, ExpMult, bool:IsSurvivorScore=true)
{
	return ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, IsSurvivorScore, false);
}

ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, bool:IsSurvivorScore=true, bool:Reduction = true)
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "hard", false)) BaseScore = BaseScore * AdvMult;
	if (StrEqual(Difficulty, "impossible", false)) BaseScore = BaseScore * ExpMult;

	if (IsSurvivorScore && Reduction)
		BaseScore = GetMedkitPointReductionScore(BaseScore);

	return ModifyScoreRealism(BaseScore);
}

IsDifficultyEasy()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "easy", false))
		return true;

	return false;
}

InvalidGameMode()
{
	// Currently will always return False in Survival and Versus gamemodes.
	// This will be removed in a future version when stats for those versions work.

	if (CurrentGamemodeID == GAMEMODE_COOP && GetConVarBool(cvar_EnableCoop))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_SURVIVAL && GetConVarBool(cvar_EnableSv))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_VERSUS && GetConVarBool(cvar_EnableVersus))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_SCAVENGE && GetConVarBool(cvar_EnableScavenge))
		return false;
	else if (CurrentGamemodeID == GAMEMODE_REALISM && GetConVarBool(cvar_EnableRealism))
		return false;

	return true;
}

bool:CheckHumans()
{
	new MinHumans = GetConVarInt(cvar_HumansNeeded);
	new Humans = 0;
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			Humans++;
	}

	if (Humans < MinHumans)
		return true;
	else
		return false;
}

ResetInfVars()
{
	new i, j;

	ClearTrie(FriendlyFireDamageTrie);

	// Reset all Infected variables
	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		BoomerHitCounter[i] = 0;
		BoomerVomitUpdated[i] = false;
		InfectedDamageCounter[i] = 0;
		SmokerDamageCounter[i] = 0;
		SpitterDamageCounter[i] = 0;
		JockeyDamageCounter[i] = 0;
		ChargerDamageCounter[i] = 0;
		TankPointsCounter[i] = 0;
		TankDamageCounter[i] = 0;
		ClientInfectedType[i] = 0;
		TankSurvivorKillCounter[i] = 0;
		TankDamageTotalCounter[i] = 0;
		ChargerCarryVictim[i] = 0;
		ChargerPlummelVictim[i] = 0;
		JockeyVictim[i] = 0;
		JockeyRideStartTime[i] = 0;

		PlayerBlinded[i][0] = 0;
		PlayerBlinded[i][1] = 0;
		PlayerParalyzed[i][0] = 0;
		PlayerParalyzed[i][1] = 0;
		PlayerLunged[i][0] = 0;
		PlayerLunged[i][1] = 0;
		PlayerPlummeled[i][0] = 0;
		PlayerPlummeled[i][1] = 0;
		PlayerCarried[i][0] = 0;
		PlayerCarried[i][1] = 0;
		PlayerJockied[i][0] = 0;
		PlayerJockied[i][1] = 0;

		for (j = 0; j < MAXPLAYERS + 1; j++)
		{
			FriendlyFireCooldown[i][j] = false;
			FriendlyFireTimer[i][j] = INVALID_HANDLE;
		}

		TimerBoomerPerfectCheck[i] = INVALID_HANDLE;
		TimerInfectedDamageCheck[i] = INVALID_HANDLE;

		TimerProtectedFriendly[i] = INVALID_HANDLE;
		ProtectedFriendlyCounter[i] = 0;
	}
}

ResetVars()
{
	PlayerVomited = false;
	PlayerVomitedIncap = false;
	PanicEvent = false;
	PanicEventIncap = false;
	CampaignOver = false;
	WitchExists = false;
	WitchDisturb = false;
	MedkitsUsedCounter = 0;

	// Reset kill/point score timer amount
	CreateTimer(1.0, InitPlayers);

	TankCount = 0;

	new i, maxplayers = GetMaxClients();
	for (i = 1; i <= maxplayers; i++)
	{
		CurrentPoints[i] = 0;
	}

	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (TimerRankChangeCheck[i] != INVALID_HANDLE)
			CloseHandle(TimerRankChangeCheck[i]);

		TimerRankChangeCheck[i] = INVALID_HANDLE;
	}

	ResetInfVars();
}

public ResetRankChangeCheck()
{
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
		StartRankChangeCheck(i);
}

public StartRankChangeCheck(Client)
{
	if (TimerRankChangeCheck[Client] != INVALID_HANDLE)
		CloseHandle(TimerRankChangeCheck[Client]);

	TimerRankChangeCheck[Client] = INVALID_HANDLE;

	if (Client == 0 || IsClientBot(Client))
		return;

	RankChangeFirstCheck[Client] = true;
	DoShowRankChange(Client);
	TimerRankChangeCheck[Client] = CreateTimer(GetConVarFloat(cvar_AnnounceRankChangeIVal), timer_ShowRankChange, Client, TIMER_REPEAT);
}

StatsDisabled(bool:MapCheck = false)
{
	if (InvalidGameMode())
		return true;

	if (!MapCheck && IsDifficultyEasy())
		return true;

	if (!MapCheck && CheckHumans())
		return true;

	if (!MapCheck && GetConVarBool(cvar_Cheats))
		return true;

	if (db == INVALID_HANDLE)
		return true;

	return false;
}

// Check that player the score is in the map score limits and return the value that is addable.

public AddScore(Client, Score)
{
	// ToDo: use cvar_MaxPoints to check if the score is within the map limits
	CurrentPoints[Client] += Score;

	//if (GetConVarBool(cvar_AnnounceRankChange))
	//{
	//}

	return Score;
}

public UpdateSmokerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientName(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_smoker_damage = infected_smoker_damage + %i WHERE steamid = '%s'", Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_smoker_damage", Damage);
}

public UpdateSpitterDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientName(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_spitter_damage = infected_spitter_damage + %i WHERE steamid = '%s'", Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_spitter_damage", Damage);
}

public UpdateJockeyDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientName(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_jockey_damage = infected_jockey_damage + %i WHERE steamid = '%s'", Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_jockey_damage", Damage);
}

UpdateJockeyRideLength(Client, Float:RideLength=-1.0)
{
	if (Client <= 0 || RideLength == 0 || IsClientBot(Client) || (RideLength < 0 && JockeyRideStartTime[Client] <= 0))
		return;

	if (RideLength < 0)
		RideLength = float(GetTime() - JockeyRideStartTime[Client]);

	decl String:iID[MAX_LINE_WIDTH];
	GetClientName(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_jockey_ridetime = infected_jockey_ridetime + %f WHERE steamid = '%s'", RideLength, iID);
	SendSQLUpdate(query);

	UpdateMapStatFloat("infected_jockey_ridetime", RideLength);
}

public UpdateChargerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientName(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_charger_damage = infected_charger_damage + %i WHERE steamid = '%s'", Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_charger_damage", Damage);
}

public CheckSurvivorsWin()
{
	if (CampaignOver)
		return;

	CampaignOver = true;

	StopMapTiming();

	// Return if gamemode is Scavenge or Survival
	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Witch), 5, 10);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[1024];
	new maxplayers = GetMaxClients();
	decl String:UpdatePoints[32], String:UpdatePointsPenalty[32];
	new ClientTeam, bool:NegativeScore = GetConVarBool(cvar_EnableNegativeScore);

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_infected");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	if (Score > 0 && WitchExists && !WitchDisturb)
	{
		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				GetClientName(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				AddScore(i, Score);
			}
		}

		if (Mode)
			PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05Not Disturbing A Witch!", Score);
	}

	Score = 0;
	new Deaths = 0;
	new BaseScore = ModifyScoreDifficulty(GetConVarInt(cvar_SafeHouse), 2, 5);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			if (IsPlayerAlive(i))
				Score = Score + BaseScore;
			else
				Deaths++;
		}
	}

	new String:All4Safe[64] = "";
	if (Deaths == 0)
		Format(All4Safe, sizeof(All4Safe), ", award_allinsafehouse = award_allinsafehouse + 1");

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				InterstitialPlayerUpdate(i);

				GetClientName(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE players SET %s = %s + %i%s WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, All4Safe, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				AddScore(i, Score);
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				DoInfectedFinalChecks(i);

				GetClientName(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE players SET %s = %s - %i WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				AddScore(i, Score * (-1));
			}

			if (TimerRankChangeCheck[i] != INVALID_HANDLE)
				TriggerTimer(TimerRankChangeCheck[i], true);
		}
	}

	if (Mode && Score > 0)
	{
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for reaching a Safe House with \x05%i Deaths!", Score, Deaths);

		if (NegativeScore)
			PrintToChatTeam(TEAM_INFECTED, "\x04[\x03RANK\x04] \x03ALL INFECTED \x01have \x03LOST \x04%i \x01points for letting the survivors reach a Safe House!", Score);
	}

	PlayerVomited = false;
	PanicEvent = false;
}

IsSingleTeamGamemode()
{
	if (CurrentGamemodeID == GAMEMODE_SCAVENGE ||
			CurrentGamemodeID == GAMEMODE_SURVIVAL ||
			CurrentGamemodeID == GAMEMODE_VERSUS)
		return false;

	return true;
}

CheckSurvivorsAllDown()
{
	if (CampaignOver ||
				CurrentGamemodeID == GAMEMODE_COOP ||
				CurrentGamemodeID == GAMEMODE_REALISM)
		return;

	new maxplayers = GetMaxClients();
	new ClientTeam, ClientIsIncap;
	new bool:ClientIsAlive,  bool:ClientIsBot;
	new KilledSurvivor[MaxClients];
	new AliveInfected[MaxClients];
	new Infected[MaxClients];
	new InfectedCounter = 0, AliveInfectedCounter = 0;
	new i;

	// Add to killing score on all incapacitated surviviors
	new IncapCounter = 0;

	for (i = 1; i <= maxplayers; i++)
	{
		if (!IsClientInGame(i))
			continue;

		ClientTeam = GetClientTeam(i);
		ClientIsAlive = IsPlayerAlive(i);
		ClientIsBot = IsClientBot(i);
		ClientIsIncap = GetEntProp(i, Prop_Send, "m_isIncapacitated");

		// Client is not dead and not incapped -> game continues!
		if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive && ClientIsIncap == 0)
			return;

		if (ClientTeam == TEAM_INFECTED && !ClientIsBot)
		{
			if (ClientIsAlive)
				AliveInfected[AliveInfectedCounter++] = i;

			Infected[InfectedCounter++] = i;
		}
		else if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive)
			KilledSurvivor[IncapCounter++] = i;
	}

	// If we ever get this far it means the surviviors are all down or dead!

	CampaignOver = true;

	// Stop the timer and return if gamemode is Survival
	if (CurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStarted = false;
		StopMapTiming();
		return;
	}

	// If we ever get this far it means the current gamemode is NOT Survival

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				InterstitialPlayerUpdate(i);

			if (TimerRankChangeCheck[i] != INVALID_HANDLE)
				TriggerTimer(TimerRankChangeCheck[i], true);
		}
	}

	decl String:query[1024];
	decl String:ClientID[MAX_LINE_WIDTH];
	new Mode = GetConVarInt(cvar_AnnounceMode);

	for (i = 0; i < AliveInfectedCounter; i++)
		DoInfectedFinalChecks(AliveInfected[i]);

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_VictoryInfected), 0.75, 0.5) * IncapCounter;
	new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;

	if (Score > 0)
		for (i = 0; i < InfectedCounter; i++)
		{
			GetClientName(Infected[i], ClientID, sizeof(ClientID));

			if (IsVersus)
				Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", Score, ClientID);
			else
				Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", Score, ClientID);

			SendSQLUpdate(query);
		}

	UpdateMapStat("infected_win", 1);
	if (IncapCounter > 0)
		UpdateMapStat("survivor_kills", IncapCounter);
	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Score > 0 && Mode)
		PrintToChatTeam(TEAM_INFECTED, "\x04[\x03RANK\x04] \x03ALL INFECTED \x01have earned \x04%i \x01points for killing all survivors!", Score);

	if (!GetConVarBool(cvar_EnableNegativeScore))
		return;

	if (CurrentGamemodeID == GAMEMODE_VERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(cvar_Restart), 0.75, 0.5);
	}
	else
	{
		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3);
		Score = 400 - Score;
	}

	for (i = 0; i < IncapCounter; i++)
	{
		GetClientName(KilledSurvivor[i], ClientID, sizeof(ClientID));

		if (IsVersus)
			Format(query, sizeof(query), "UPDATE players SET points_survivors = points_survivors - %i WHERE steamid = '%s'", Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE players SET points_scavenge_survivors = points_scavenge_survivors - %i WHERE steamid = '%s'", Score, ClientID);

		SendSQLUpdate(query);
	}

	if (Mode)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying\x01!", Score);
}

bool:IsGamemode(const String:Gamemode[])
{
	if (StrContains(CurrentGamemode, Gamemode, false) != -1)
		return true;

	return false;
}

GetGamemodeID(const String:Gamemode[])
{
	if (StrEqual(Gamemode, "coop", false))
		return GAMEMODE_COOP;
	else if (StrEqual(Gamemode, "survival", false))
		return GAMEMODE_SURVIVAL;
	else if (StrEqual(Gamemode, "versus", false))
		return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "teamversus", false) && GetConVarInt(cvar_EnableTeamVersus))
		return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "scavenge", false))
		return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "teamscavenge", false) && GetConVarInt(cvar_EnableTeamScavenge))
		return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "realism", false))
		return GAMEMODE_REALISM;

	return GAMEMODE_UNKNOWN;
}

GetCurrentGamemodeID()
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));

	return GetGamemodeID(CurrentMode);
}

IsGamemodeRealism()
{
	return IsGamemode("realism");
}

IsGamemodeVersus()
{
	return IsGamemode("versus") || (IsGamemode("teamversus") && GetConVarBool(cvar_EnableTeamVersus));
}

IsGamemodeScavenge()
{
	return IsGamemode("scavege") || (IsGamemode("teamscavege") && GetConVarBool(cvar_EnableTeamScavenge));
}

IsGamemodeCoop()
{
	return IsGamemode("coop");
}

GetSurvivorKillScore()
{
	return ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorDeath), 0.75, 0.5);
}

DoInfectedFinalChecks(Client, ClientInfType = -1)
{
	if (Client == 0)
		return;

	if (ClientInfType < 0)
		ClientInfType = ClientInfectedType[Client];

	if (ClientInfType == INF_ID_SMOKER)
	{
		new Damage = SmokerDamageCounter[Client];
		SmokerDamageCounter[Client] = 0;
		UpdateSmokerDamage(Client, Damage);
	}
	else if (ServerVersion != SERVER_VERSION_L4D1 && ClientInfType == INF_ID_SPITTER_L4D2)
	{
		new Damage = SpitterDamageCounter[Client];
		SpitterDamageCounter[Client] = 0;
		UpdateSpitterDamage(Client, Damage);
	}
	else if (ServerVersion != SERVER_VERSION_L4D1 && ClientInfType == INF_ID_JOCKEY_L4D2)
	{
		new Damage = JockeyDamageCounter[Client];
		JockeyDamageCounter[Client] = 0;
		UpdateJockeyDamage(Client, Damage);
		UpdateJockeyRideLength(Client);
	}
	else if (ServerVersion != SERVER_VERSION_L4D1 && ClientInfType == INF_ID_CHARGER_L4D2)
	{
		new Damage = ChargerDamageCounter[Client];
		ChargerDamageCounter[Client] = 0;
		UpdateChargerDamage(Client, Damage);
	}
}

GetInfType(Client)
{
	// Client > 0 && ClientTeam == TEAM_INFECTED checks are done by the caller

	new InfType = GetEntProp(Client, Prop_Send, "m_zombieClass");

	// Make the conversion so that everything gets stored in the correct fields
	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		if (InfType == INF_ID_WITCH_L4D1)
			return INF_ID_WITCH_L4D2;

		if (InfType == INF_ID_TANK_L4D1)
			return INF_ID_TANK_L4D2;
	}

	return InfType;
}

SetClientInfectedType(Client)
{
	// Bot check is done by the caller

	if (Client <= 0)
		return;

	new ClientTeam = GetClientTeam(Client);

	if (ClientTeam == TEAM_INFECTED)
	{
		ClientInfectedType[Client] = GetInfType(Client);

		if (ClientInfectedType[Client] != INF_ID_SMOKER
				&& ClientInfectedType[Client] != INF_ID_BOOMER
				&& ClientInfectedType[Client] != INF_ID_HUNTER
				&& ClientInfectedType[Client] != INF_ID_SPITTER_L4D2
				&& ClientInfectedType[Client] != INF_ID_JOCKEY_L4D2
				&& ClientInfectedType[Client] != INF_ID_CHARGER_L4D2
				&& ClientInfectedType[Client] != INF_ID_TANK_L4D2)
			return;

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientName(Client, ClientID, sizeof(ClientID));

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE players SET infected_spawn_%i = infected_spawn_%i + 1 WHERE steamid = '%s'", ClientInfectedType[Client], ClientInfectedType[Client], ClientID);
		SendSQLUpdate(query);

		new String:Spawn[32];
		Format(Spawn, sizeof(Spawn), "infected_spawn_%i", ClientInfectedType[Client]);
		UpdateMapStat(Spawn, 1);
	}
	else
		ClientInfectedType[Client] = 0;
}

TankDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0)
		return 0;

	// Update only the Tank inflicted damage related statistics
	UpdateTankDamage(Client, Damage);

	// If value is negative then client has already received the Bulldozer Award
	if (TankDamageTotalCounter[Client] >= 0)
	{
		TankDamageTotalCounter[Client] += Damage;
		new TankDamageTotal = GetConVarInt(cvar_TankDamageTotal);

		if (TankDamageTotalCounter[Client] >= TankDamageTotal)
		{
			TankDamageTotalCounter[Client] = -1; // Just one award per Tank
			new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_TankDamageTotalSuccess), 0.75, 0.5);

			if (Score > 0)
			{
				new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;
				decl String:ClientID[MAX_LINE_WIDTH];
				GetClientName(Client, ClientID, sizeof(ClientID));

				decl String:query[1024];

				if (IsVersus)
					Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", Score, ClientID);
				else
					Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", Score, ClientID);

				SendSQLUpdate(query);

				UpdateMapStat("points_infected", Score);

				new Mode = GetConVarInt(cvar_AnnounceMode);

				if (Mode == 1 || Mode == 2)
					PrintToChat(Client, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Score, TankDamageTotal);
				else if (Mode == 3)
				{
					decl String:Name[MAX_LINE_WIDTH];
					GetClientName(Client, Name, sizeof(Name));
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Name, Score, TankDamageTotal);
				}
			}
		}
	}

	new DamageLimit = GetConVarInt(cvar_TankDamageCap);

	if (TankDamageCounter[Client] >= DamageLimit)
		return 0;

	TankDamageCounter[Client] += Damage;

	if (TankDamageCounter[Client] > DamageLimit)
		Damage -= TankDamageCounter[Client] - DamageLimit;

	return Damage;
}

UpdateFriendlyFire(Attacker, Victim)
{
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	if (GetConVarBool(cvar_EnableNegativeScore))
	{
		if (!IsClientBot(Victim))
			Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4);
		else
		{
			new Float:BotScoreMultiplier = GetConVarFloat(cvar_BotScoreMultiplier);

			if (BotScoreMultiplier > 0.0)
				Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4) * BotScoreMultiplier);
		}
	}

	decl String:UpdatePoints[32];

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);

	new Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", AttackerName, Score, VictimName);
}

UpdateHunterDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientName(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_hunter_pounce_dmg = infected_hunter_pounce_dmg + %i, infected_hunter_pounce_counter = infected_hunter_pounce_counter + 1 WHERE steamid = '%s'", Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_hunter_pounce_counter", 1);
	UpdateMapStat("infected_hunter_pounce_damage", Damage);
}

UpdateTankDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientName(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_tank_damage = infected_tank_damage + %i WHERE steamid = '%s'", Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tank_damage", Damage);
}

UpdatePlayerScore(Client, Score)
{
	if (Score == 0)
		return;

	switch (CurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			UpdatePlayerScoreVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_REALISM:
		{
			UpdatePlayerScore2(Client, Score, "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			UpdatePlayerScore2(Client, Score, "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			UpdatePlayerScoreScavenge(Client, GetClientTeam(Client), Score);
		}
		default:
		{
			UpdatePlayerScore2(Client, Score, "points");
		}
	}
}

UpdatePlayerScoreVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_infected");
}

UpdatePlayerScoreScavenge(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_scavenge_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_scavenge_infected");
}

UpdatePlayerScore2(Client, Score, const String:Points[])
{
	if (Score == 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientName(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s'", Points, Points, Score, ClientID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points", Score);

	AddScore(Client, Score);
}

UpdateTankSniper(Client)
{
	if (Client <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientName(Client, ClientID, sizeof(ClientID));

	UpdateTankSniperSteamID(ClientID);
}

UpdateTankSniperSteamID(const String:ClientID[])
{
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_tanksniper = infected_tanksniper + 1 WHERE steamid = '%s'", ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tanksniper", 1);
}

// Survivor died.

SurvivorDied(Attacker, Victim, AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim)
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, AttackerInfType, Mode);
}

// An Infected player killed a Survivor.

SurvivorDiedNamed(Attacker, Victim, const String:VictimName[], const String:AttackerID[], AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim)
		return;

//LogError("SurvivorDiedNamed - VictimName = %s", VictimName);

	if (AttackerInfType < 0)
	{
		if (ClientInfectedType[Attacker] == 0)
			SetClientInfectedType(Attacker);

		AttackerInfType = ClientInfectedType[Attacker];
	}

	if (ServerVersion == SERVER_VERSION_L4D1)
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_TANK_L4D2) // SetClientInfectedType sets tank id to L4D2
			return;
	}
	else
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_SPITTER_L4D2
				&& AttackerInfType != INF_ID_JOCKEY_L4D2
				&& AttackerInfType != INF_ID_CHARGER_L4D2
				&& AttackerInfType != INF_ID_TANK_L4D2)
			return;
	}

	new Score = GetSurvivorKillScore();
	new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;

	new len = 0;
	decl String:query[1024];

	if (IsVersus)
		len += Format(query[len], sizeof(query)-len, "UPDATE players SET points_infected = points_infected + %i, versus_kills_survivors = versus_kills_survivors + 1 ", Score);
	else
		len += Format(query[len], sizeof(query)-len, "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, scavenge_kills_survivors = scavenge_kills_survivors + 1 ", Score);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", AttackerID);
	SendSQLUpdate(query);

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
	{
		if (Mode > 2)
		{
			decl String:AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for killing \x05%s\x01!", AttackerName, Score, VictimName);
		}
		else
			PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for killing \x05%s\x01!", Score, VictimName);
	}

	UpdateMapStat("survivor_kills", 1);
	UpdateMapStat("points_infected", Score);
	AddScore(Attacker, Score);
}

// Survivor got hurt.

SurvivorHurt(Attacker, Victim, Damage, AttackerInfType = -1, Handle:event = INVALID_HANDLE)
{
	if (!Attacker || !Victim || Damage <= 0)
		return;

	if (AttackerInfType < 0)
	{
		new AttackerTeam = GetClientTeam(Attacker);

		if (Attacker > 0 && AttackerTeam == TEAM_INFECTED)
			AttackerInfType = GetInfType(Attacker);
	}

	if (AttackerInfType != INF_ID_SMOKER
			&& AttackerInfType != INF_ID_BOOMER
			&& AttackerInfType != INF_ID_HUNTER
			&& AttackerInfType != INF_ID_SPITTER_L4D2
			&& AttackerInfType != INF_ID_JOCKEY_L4D2
			&& AttackerInfType != INF_ID_CHARGER_L4D2
			&& AttackerInfType != INF_ID_TANK_L4D2)
		return;

	if (TimerInfectedDamageCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(TimerInfectedDamageCheck[Attacker]);
		TimerInfectedDamageCheck[Attacker] = INVALID_HANDLE;
	}

	new VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	if (AttackerInfType == INF_ID_TANK_L4D2 && event != INVALID_HANDLE)
	{
		InfectedDamageCounter[Attacker] += TankDamage(Attacker, Damage);

		decl String:Weapon[16];
		GetEventString(event, "weapon", Weapon, sizeof(Weapon));

		new RockHit = GetConVarInt(cvar_TankThrowRockSuccess);

		if (RockHit > 0 && strcmp(Weapon, "tank_rock", false) == 0)
		{
			new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;

			if (IsVersus)
				UpdatePlayerScore2(Attacker, RockHit, "points_infected");
			else
				UpdatePlayerScore2(Attacker, RockHit, "points_scavenge_infected");
			UpdateTankSniper(Attacker);

			decl String:VictimName[MAX_LINE_WIDTH];

			if (Victim > 0)
				GetClientName(Victim, VictimName, sizeof(VictimName));
			else
				Format(VictimName, sizeof(VictimName), "UNKNOWN");

			new Mode = GetConVarInt(cvar_AnnounceMode);

			if (Mode == 1 || Mode == 2)
				PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for throwing a rock at \x05%s\x01!", RockHit, VictimName);
			else if (Mode == 3)
			{
				decl String:AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for throwing a rock at \x05%s\x01!", AttackerName, RockHit, VictimName);
			}
		}
	}
	else
		InfectedDamageCounter[Attacker] += Damage;

	if (AttackerInfType == INF_ID_SMOKER)
		SmokerDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_SPITTER_L4D2)
		SpitterDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_JOCKEY_L4D2)
		JockeyDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_CHARGER_L4D2)
		ChargerDamageCounter[Attacker] += Damage;

	TimerInfectedDamageCheck[Attacker] = CreateTimer(5.0, timer_InfectedDamageCheck, Attacker);
}

// Survivor was hurt by normal infected while being blinded and/or paralyzed.

SurvivorHurtExternal(Handle:event, Victim)
{
	if (event == INVALID_HANDLE || !Victim)
		return;

	new Damage = GetEventInt(event, "dmg_health");

	new VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	new Attacker;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
}

PlayerDeathExternal(Victim)
{
	if (!Victim)
		return;

	CheckSurvivorsAllDown();

	new Attacker = 0;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_BOOMER);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_SMOKER);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
}

PlayerIncapExternal(Victim)
{
	if (!Victim)
		return;

	CheckSurvivorsAllDown();

	new Attacker = 0;

	if (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1])
	{
		Attacker = PlayerBlinded[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}

	if (PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1])
	{
		Attacker = PlayerParalyzed[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerLunged[Victim][0] && PlayerLunged[Victim][1])
	{
		Attacker = PlayerLunged[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerPlummeled[Victim][0] && PlayerPlummeled[Victim][1])
	{
		Attacker = PlayerPlummeled[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerCarried[Victim][0] && PlayerCarried[Victim][1])
	{
		Attacker = PlayerCarried[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (PlayerJockied[Victim][0] && PlayerJockied[Victim][1])
	{
		Attacker = PlayerJockied[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
}

SurvivorIncappedByInfected(Attacker, Victim, Mode = -1)
{
	if (Attacker > 0 && !IsClientConnected(Attacker) || Attacker > 0 && IsClientBot(Attacker))
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorIncap), 0.75, 0.5);

	if (Score <= 0)
		return;

	new bool:IsVersus = CurrentGamemodeID == GAMEMODE_VERSUS;
	decl String:query[512];

	if (IsVersus)
		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", Score, AttackerID);
	else
		Format(query, sizeof(query), "UPDATE players SET points_scavenge_infected = points_scavenge_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", Score, AttackerID);
	SendSQLUpdate(query);

	UpdateMapStat("points_infected", Score);

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Incapacitating \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Incapacitating \x05%s\x01!", AttackerName, Score, VictimName);
}

Float:GetMedkitPointReductionFactor()
{
	if (MedkitsUsedCounter <= 0)
		return 1.0;

	new Float:Penalty = GetConVarFloat(cvar_MedkitUsedPointPenalty);

	// If Penalty is set to ZERO: There is no reduction.
	if (Penalty <= 0.0)
		return 1.0;

	new PenaltyFree = GetConVarInt(cvar_MedkitUsedFree);

	if (PenaltyFree >= MedkitsUsedCounter)
		return 1.0;

	Penalty *= MedkitsUsedCounter - PenaltyFree;

	new Float:PenaltyMax = GetConVarFloat(cvar_MedkitUsedPointPenaltyMax);

	if (Penalty > PenaltyMax)
		return 1.0 - PenaltyMax;

	return 1.0 - Penalty;
}

// Calculate the score with the medkit point reduction

GetMedkitPointReductionScore(Score, bool:ToCeil = false)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return Score;

	if (ToCeil)
		return RoundToCeil(Score * ReductionFactor);
	else
		return RoundToFloor(Score * ReductionFactor);
}

AnnounceMedkitPenalty(Mode = -1)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return;

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit%s\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter, (MedkitsUsedCounter == 1 ? "st" : (MedkitsUsedCounter == 2 ? "nd" : (MedkitsUsedCounter == 3 ? "rd" : "th"))), (ServerVersion == SERVER_VERSION_L4D1 ? "" : " or Defibrillator"));
}

GetClientInfectedType(Client)
{
	if (Client > 0 && GetClientTeam(Client) == TEAM_INFECTED)
		return GetInfType(Client);

	return 0;
}

InitializeClientInf(Client)
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (PlayerParalyzed[i][1] == Client)
		{
			PlayerParalyzed[i][0] = 0;
			PlayerParalyzed[i][1] = 0;
		}
		if (PlayerLunged[i][1] == Client)
		{
			PlayerLunged[i][0] = 0;
			PlayerLunged[i][1] = 0;
		}
		if (PlayerCarried[i][1] == Client)
		{
			PlayerCarried[i][0] = 0;
			PlayerCarried[i][1] = 0;
		}
		if (PlayerPlummeled[i][1] == Client)
		{
			PlayerPlummeled[i][0] = 0;
			PlayerPlummeled[i][1] = 0;
		}
		if (PlayerJockied[i][1] == Client)
		{
			PlayerJockied[i][0] = 0;
			PlayerJockied[i][1] = 0;
		}
	}
}

// Print a chat message to a specific team instead of all players

public PrintToChatTeam(Team, const String:Message[], any:...)
{
	new String:FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	new AnnounceToTeam = GetConVarInt(cvar_AnnounceToTeam);

	if (Team > 0 && AnnounceToTeam)
	{
		new maxplayers = GetMaxClients();
		new ClientTeam;

		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			{
				ClientTeam = GetClientTeam(i);
				if (ClientTeam == Team || (ClientTeam == TEAM_SPECTATORS && AnnounceToTeam == 2))
				{
					PrintToChat(i, FormattedMessage);
				}
			}
		}
	}
	else
		PrintToChatAll(FormattedMessage);
}

// Disable map timings when opposing team has human players. The time is too much depending on opposing team that is is comparable.

MapTimingEnabled()
{
	return CurrentGamemodeID == GAMEMODE_COOP || CurrentGamemodeID == GAMEMODE_SURVIVAL || CurrentGamemodeID == GAMEMODE_REALISM;
}

public StartMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime != 0.0 || StatsDisabled())
		return;

	MapTimingStartTime = GetEngineTime();

	new ClientTeam, maxplayers = GetMaxClients();
	decl String:ClientID[MAX_LINE_WIDTH];

	ClearTrie(MapTimingSurvivors);
	ClearTrie(MapTimingInfected);

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientName(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingSurvivors, ClientID, 1, true);
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				GetClientName(i, ClientID, sizeof(ClientID));
				SetTrieValue(MapTimingInfected, ClientID, 1, true);
			}
		}
	}
}

GetCurrentDifficulty()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) return 1;
	else if (StrEqual(Difficulty, "hard", false)) return 2;
	else if (StrEqual(Difficulty, "impossible", false)) return 3;
	else return 0;
}

public StopMapTiming()
{
	if (!MapTimingEnabled() || MapTimingStartTime <= 0.0 || StatsDisabled())
		return;

	new Float:TotalTime = GetEngineTime() - MapTimingStartTime;
	MapTimingStartTime = -1.0;

	new Handle:dp = INVALID_HANDLE;
	new ClientTeam, enabled, maxplayers = GetMaxClients();
	decl String:ClientID[MAX_LINE_WIDTH], String:MapName[MAX_LINE_WIDTH], String:query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	new i, PlayerCounter = 0, InfectedCounter = (CurrentGamemodeID == GAMEMODE_VERSUS || CurrentGamemodeID == GAMEMODE_SCAVENGE ? 0 : 1);

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			GetClientName(i, ClientID, sizeof(ClientID));

			if (ClientTeam == TEAM_SURVIVORS && GetTrieValue(MapTimingSurvivors, ClientID, enabled))
			{
				if (enabled)
					PlayerCounter++;
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				InfectedCounter++;
				if (GetTrieValue(MapTimingInfected, ClientID, enabled))
				{
					if (enabled)
						PlayerCounter++;
				}
			}
		}
	}

	// Game ended because all of the infected team left the server... don't record the time!
	if (InfectedCounter <= 0)
		return;

	new GameDifficulty = GetCurrentDifficulty();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientName(i, ClientID, sizeof(ClientID));

				if (GetTrieValue(MapTimingSurvivors, ClientID, enabled))
				{
					if (enabled)
					{
						dp = CreateDataPack();

						WritePackString(dp, MapName);
						WritePackCell(dp, CurrentGamemodeID);
						WritePackString(dp, ClientID);
						WritePackFloat(dp, TotalTime);
						WritePackCell(dp, i);
						WritePackCell(dp, PlayerCounter);
						WritePackCell(dp, GameDifficulty);

						Format(query, sizeof(query), "SELECT time FROM timedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND steamid = '%s'", MapName, CurrentGamemodeID, GameDifficulty, ClientID);

						SQL_TQuery(db, UpdateMapTimingStat, query, dp);

						// Not supported by my version of MySQL (5.0 something) - damned!
						//Format(query, sizeof(query), "DELETE FROM timedmaps WHERE steamid = '%s' AND id NOT IN (SELECT id FROM maprun WHERE steamid = '%s' LIMIT 5)", ClientID, ClientID);
						//SendSQLUpdate(query);
					}
				}
 			}
		}
	}

	ClearTrie(MapTimingSurvivors);
}

public UpdateMapTimingStat(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("UpdateMapTimingStat Query failed: %s", error);
		return;
	}

	ResetPack(dp);

	decl String:MapName[MAX_LINE_WIDTH], String:ClientID[MAX_LINE_WIDTH], String:query[512];
	new GamemodeID, Float:TotalTime, OldTime, Client, PlayerCounter, GameDifficulty;

	ReadPackString(dp, MapName, sizeof(MapName));
	GamemodeID = ReadPackCell(dp);
	ReadPackString(dp, ClientID, sizeof(ClientID));
	TotalTime = ReadPackFloat(dp);
	Client = ReadPackCell(dp);
	PlayerCounter = ReadPackCell(dp);
	GameDifficulty = ReadPackCell(dp);

	CloseHandle(dp);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (SQL_GetRowCount(hndl) > 0)
	{
		SQL_FetchRow(hndl);
		OldTime = SQL_FetchInt(hndl, 0);

		if ((CurrentGamemodeID != GAMEMODE_SURVIVAL && OldTime <= TotalTime) || (CurrentGamemodeID == GAMEMODE_SURVIVAL && OldTime >= TotalTime))
		{
			if (Mode)
				PrintToChat(Client, "\x04[\x03RANK\x04] \x01You did not improve your best time \x04%.1f seconds \x01to finish this map!", OldTime);

			Format(query, sizeof(query), "UPDATE timedmaps SET plays = plays + 1, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND steamid = '%s'", MapName, GamemodeID, GameDifficulty, ClientID);
		}
		else
		{
			if (Mode)
				PrintToChat(Client, "\x04[\x03RANK\x04] \x01Your new best time to finish this map is \x04%.1f seconds\x01!", TotalTime);

			Format(query, sizeof(query), "UPDATE timedmaps SET plays = plays + 1, time = %f, players = %i, modified = NOW() WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND steamid = '%s'", TotalTime, PlayerCounter, MapName, GamemodeID, GameDifficulty, ClientID);
		}
	}
	else
	{
		if (Mode)
			PrintToChat(Client, "\x04[\x03RANK\x04] \x01It took \x04%.1f seconds \x01to finish this map!", TotalTime);

		Format(query, sizeof(query), "INSERT INTO timedmaps (map, gamemode, difficulty, steamid, plays, time, players, modified, created) VALUES ('%s', %i, %i, '%s', 1, %f, %i, NOW(), NOW())", MapName, GamemodeID, GameDifficulty, ClientID, TotalTime, PlayerCounter);
	}

	SendSQLUpdate(query);
}

public SetTimeLabel(String:TimeLabel[], maxsize, Float:TheSeconds)
{
	new FlooredSeconds = RoundToFloor(TheSeconds);
	new FlooredSecondsMod = FlooredSeconds % 60;
	new Float:Seconds = TheSeconds - float(FlooredSeconds) + float(FlooredSecondsMod);
	new Minutes = (TheSeconds < 60.0 ? 0 : RoundToNearest(float(FlooredSeconds - FlooredSecondsMod) / 60));
	new MinutesMod = Minutes % 60;
	new Hours = (Minutes < 60 ? 0 : RoundToNearest(float(Minutes - MinutesMod) / 60));
	Minutes = MinutesMod;

	if (Hours > 0)
		Format(TimeLabel, maxsize, "%ih %im %.1fs", Hours, Minutes, Seconds);
	else if (Minutes > 0)
		Format(TimeLabel, maxsize, "%i min %.1f sec", Minutes, Seconds);
	else
		Format(TimeLabel, maxsize, "%.1f seconds", Seconds);
}

public DisplayRankVote(client)
{
	DisplayYesNoPanel(client, RANKVOTE_QUESTION, RankVotePanelHandler, RoundToNearest(GetConVarFloat(cvar_RankVoteTime)));
}

// Initialize RANKVOTE
public InitializeRankVote(client)
{
	if (StatsDisabled())
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] Cannot initiate vote when the plugin is disabled!");
		else
			PrintToChat(client, "\x04[\x03RANK\x04] \x01Cannot initiate vote when the plugin is disabled!");

		return;
	}

	// No TEAM gamemodes are allowed
	if (!IsGamemode("versus") && !IsGamemode("scavenge"))
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] The Rank Vote is not enabled in this gamemode!");
		else
		{
			if (ServerVersion == SERVER_VERSION_L4D1)
				PrintToChat(client, "\x04[\x03RANK\x04] \x01The \x04Rank Vote \x01is enabled in \x03Versus \x01gamemode!");
			else
				PrintToChat(client, "\x04[\x03RANK\x04] \x01The \x04Rank Vote \x01is enabled in \x03Versus \x01and \x03Scavenge \x01gamemodes!");
		}

		return;
	}

	if (RankVoteTimer != INVALID_HANDLE)
	{
		if (client > 0)
			DisplayRankVote(client);
		else
			PrintToConsole(client, "[RANK] The Rank Vote is already initiated!");

		return;
	}

	new bool:IsAdmin = (client > 0 ? ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) : true);

	new team;
	decl String:ClientID[MAX_LINE_WIDTH];

	if (!IsAdmin && client > 0 && GetTrieValue(PlayerRankVoteTrie, ClientID, team))
	{
		PrintToChat(client, "\x04[\x03RANK\x04] \x01You can initiate a \x04Rank Vote \x01only once per map!");
		return;
	}

	if (!IsAdmin && client > 0)
	{
		GetClientName(client, ClientID, sizeof(ClientID));
		SetTrieValue(PlayerRankVoteTrie, ClientID, 1, true);
	}

	RankVoteTimer = CreateTimer(GetConVarFloat(cvar_RankVoteTime), timer_RankVote);

	new i;

	for (i = 0; i <= MAXPLAYERS; i++)
		PlayerRankVote[i] = RANKVOTE_NOVOTE;

	new maxplayers = GetMaxClients();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
				DisplayRankVote(i);
		}
	}

	if (client > 0)
	{
		decl String:UserName[MAX_LINE_WIDTH];
		GetClientName(client, UserName, sizeof(UserName));

		PrintToChatAll("\x04[\x03RANK\x04] The \x04Rank Vote \x01was initiated by \x05%s\x01!", UserName);
	}
	else
		PrintToChatAll("\x04[\x03RANK\x04] The \x04Rank Vote \x01was initiated from Server Console!");
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:ChangePlayerTeam(client, team)
{
	if(GetClientTeam(client) == team) return true;

	if(team != TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}

	if(GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	new bot;
	//for survivors its more tricky
	for (bot = 1; bot < MaxClients + 1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != TEAM_SURVIVORS)); bot++) {}

	if (bot == MaxClients + 1)
	{
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);

		ServerCommand("sb_add");

		SetCommandFlags(command, flags);

		return false;
	}

	//have to do this to give control of a survivor bot
	SDKCall(L4DStatsSHS, bot, client);
	SDKCall(L4DStatsTOB, client, true);

	return true;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock bool:IsClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

/*
	From plugin:
		name = "L4D2 Score/Team Manager",
		author = "Downtown1 & AtomicStryker",
		description = "Manage teams and scores in L4D2",
		version = 1.1.2,
		url = "http://forums.alliedmods.net/showthread.php?p=1029519"
*/

stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < MaxClients + 1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) == team)
			humans++;
	}
	
	return humans;
}

stock GetTeamMaxHumans(team)
{
	switch (team)
	{
		case TEAM_SURVIVORS:
			return GetConVarInt(cvar_SurvivorLimit);
		case TEAM_INFECTED:
			return GetConVarInt(cvar_InfectedLimit);
		case TEAM_SPECTATORS:
			return MaxClients;
	}
	
	return -1;
}
