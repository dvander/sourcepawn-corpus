/*
-----------------------------------------------------------------------------
LEFT 4 DEAD STATS - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2009
Visit http://www.msleeper.com/ for more info!
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
 . Game is in Versus mode
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
 . Support for L4D2.
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
 . Known issues:
   . Sometimes I get messages twice from gained score or friendly fire loss.
     I am not sure if the score is actually also calculated twice, but it is
     most likely.
   . Player gamemode rank in the in-game RANK panel does not show correct
     values.

-- 1.2B90 (12/07/09) "Conversion" to Left 4 Dead 2
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.2B96_TEST"
#define MAX_LINE_WIDTH 64
#define MAX_MESSAGE_WIDTH 256
#define MAX_QUERY_COUNTER 256
#define DB_CONF_NAME "l4dstats"

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

// Set to false when stats seem to work properly
new bool:DEBUG = true;

// Server version
new ServerVersion = SERVER_VERSION_L4D1;

// Database handle
new Handle:db = INVALID_HANDLE;

// Update Timer handle
new Handle:UpdateTimer = INVALID_HANDLE;

// Disable check Cvar handles
new Handle:cvar_Difficulty = INVALID_HANDLE;
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:cvar_Cheats = INVALID_HANDLE;

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
new Handle:cvar_HumansNeeded = INVALID_HANDLE;
new Handle:cvar_UpdateRate = INVALID_HANDLE;
new Handle:cvar_AnnounceMode = INVALID_HANDLE;
new Handle:cvar_AnnounceToTeam = INVALID_HANDLE;
new Handle:cvar_MedkitMode = INVALID_HANDLE;
new Handle:cvar_SiteURL = INVALID_HANDLE;
new Handle:cvar_RankOnJoin = INVALID_HANDLE;
new Handle:cvar_SilenceChat = INVALID_HANDLE;
new Handle:cvar_DisabledMessages = INVALID_HANDLE;
new Handle:cvar_MaxPoints = INVALID_HANDLE;
new Handle:cvar_DbPrefix = INVALID_HANDLE;
new Handle:cvar_LeaderboardTime = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldown = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldownMode = INVALID_HANDLE;
new Handle:FriendlyFireCooldownTimer[MAXPLAYERS + 1][MAXPLAYERS + 1];
new bool:FriendlyFireCooldown[MAXPLAYERS + 1][MAXPLAYERS + 1];
new FriendlyFireCooldownPrm[MAXPLAYERS][2];
new FriendlyFireCooldownPrmCounter = 0;

new Handle:cvar_EnableCoop = INVALID_HANDLE;
new Handle:cvar_EnableSv = INVALID_HANDLE;
new Handle:cvar_EnableVersus = INVALID_HANDLE;

new Handle:cvar_Infected = INVALID_HANDLE;
new Handle:cvar_Hunter = INVALID_HANDLE;
new Handle:cvar_Smoker = INVALID_HANDLE;
new Handle:cvar_Boomer = INVALID_HANDLE;
new Handle:cvar_Spitter = INVALID_HANDLE;
new Handle:cvar_Jockey = INVALID_HANDLE;
new Handle:cvar_Charger = INVALID_HANDLE;

new Handle:cvar_Pills = INVALID_HANDLE;
new Handle:cvar_Medkit = INVALID_HANDLE;
new Handle:cvar_SmokerDrag = INVALID_HANDLE;
new Handle:cvar_ChokePounce = INVALID_HANDLE;
new Handle:cvar_Revive = INVALID_HANDLE;
new Handle:cvar_Rescue = INVALID_HANDLE;
new Handle:cvar_Protect = INVALID_HANDLE;

new Handle:cvar_Tank = INVALID_HANDLE;
new Handle:cvar_Panic = INVALID_HANDLE;
new Handle:cvar_BoomerMob = INVALID_HANDLE;
new Handle:cvar_SafeHouse = INVALID_HANDLE;
new Handle:cvar_Witch = INVALID_HANDLE;
new Handle:cvar_VictorySurvivors = INVALID_HANDLE;
new Handle:cvar_VictoryInfected = INVALID_HANDLE;

new Handle:cvar_FFire = INVALID_HANDLE;
new Handle:cvar_FIncap = INVALID_HANDLE;
new Handle:cvar_FKill = INVALID_HANDLE;
new Handle:cvar_InSafeRoom = INVALID_HANDLE;
new Handle:cvar_Restart = INVALID_HANDLE;

new Handle:cvar_SurvivorDeath = INVALID_HANDLE;
new Handle:cvar_SurvivorIncap = INVALID_HANDLE;

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

new SmokerDamageCounter[MAXPLAYERS + 1];
new TankDamageCounter[MAXPLAYERS + 1];
new TankDamageTotalCounter[MAXPLAYERS + 1];
new TankPointsCounter[MAXPLAYERS + 1];
new TankSurvivorKillCounter[MAXPLAYERS + 1];
new Handle:cvar_TankThrowRockSuccess = INVALID_HANDLE;

new Handle:cvar_PlayerLedgeSuccess = INVALID_HANDLE;

new ClientInfectedType[MAXPLAYERS + 1];

new PlayerBlinded[MAXPLAYERS + 1][2];
new PlayerParalyzed[MAXPLAYERS + 1][2];
new PlayerLunged[MAXPLAYERS + 1][2];

// Clientprefs handles
new Handle:ClientMaps = INVALID_HANDLE;

// Rank panel vars
new RankTotal = 0;
new ClientRank[MAXPLAYERS + 1];
new ClientPoints[MAXPLAYERS + 1];
new GameModeRankTotal = 0;
new ClientGameModeRank[MAXPLAYERS + 1];
new ClientGameModePoints[MAXPLAYERS + 1][2];

// Misc arrays
new TimerPoints[MAXPLAYERS + 1];
new TimerKills[MAXPLAYERS + 1];
new TimerHeadshots[MAXPLAYERS + 1];
new Pills[4096];

new String:QueryBuffer[MAX_QUERY_COUNTER][MAX_QUERY_COUNTER];
new QueryCounter = 0;

// For every medkit used the points earned by the Survivor team is calculated with this formula:
// NormalPointsEarned * (1 - MedkitsUsedCounter * cvar_MedkitUsedPointPenalty)
// Minimum formula result = 0 (Cannot be negative)
new MedkitsUsedCounter = 0;
new Handle:cvar_MedkitUsedPointPenalty = INVALID_HANDLE;
new Handle:cvar_MedkitUsedPointPenaltyMax = INVALID_HANDLE;
new Handle:cvar_MedkitUsedFree = INVALID_HANDLE;

new ProtectedFriendlyCounter[MAXPLAYERS + 1];
new Handle:TimerProtectedFriendly[MAXPLAYERS + 1];

// Plugin Info
public Plugin:myinfo =
{
	name = "Custom L4D & L4D2 Stats",
	author = "muukis (original author msleeper)",
	description = "Player Stats and Ranking in Left 4 Dead and Left 4 Dead 2 Co-op and Versus",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.com/"
};

// Here we go!
public OnPluginStart()
{
	ServerVersion = GuessSDKVersion();

	// Plugin version public Cvar
	CreateConVar("sm_l4dstats_version", PLUGIN_VERSION, "Custom L4D & L4D2 Stats Version (Beta)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Init MySQL connections
	ConnectDB();

	// Disable setting Cvars
	cvar_Difficulty = FindConVar("z_difficulty");
	cvar_Gamemode = FindConVar("mp_gamemode");
	cvar_Cheats = FindConVar("sv_cheats");

	// Config/control Cvars
	cvar_HumansNeeded = CreateConVar("sm_l4dstats_minhumans", "2", "Minimum Human players before stats will be enabled", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	cvar_UpdateRate = CreateConVar("sm_l4dstats_updaterate", "90", "Number of seconds between Common Infected point earn announcement/update", FCVAR_PLUGIN, true, 30.0);
	cvar_AnnounceMode = CreateConVar("sm_l4dstats_announcemode", "1", "Chat announcment mode. 0 = Off, 1 = Player Only, 2 = Player Only w/ Public Headshots, 3 = All Public", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_AnnounceToTeam = CreateConVar("sm_l4dstats_announceteam", "2", "Chat announcment team messages to the team only mode. 0 = Print messages to all teams, 1 = Print messages to own team only, 2 = Print messages to own team and spectators only", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_MedkitMode = CreateConVar("sm_l4dstats_medkitmode", "0", "Medkit point award mode. 0 = Based on amount healed, 1 = Static amount", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SiteURL = CreateConVar("sm_l4dstats_siteurl", "", "Community site URL, for rank panel display", FCVAR_PLUGIN);
	cvar_RankOnJoin = CreateConVar("sm_l4dstats_rankonjoin", "1", "Display player's rank when they connect. 0 = Disable, 1 = Enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SilenceChat = CreateConVar("sm_l4dstats_silencechat", "0", "Silence chat triggers. 0 = Show chat triggers, 1 = Silence chat triggers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_DisabledMessages = CreateConVar("sm_l4dstats_disabledmessages", "1", "Show 'Stats Disabled' messages, allow chat commands to work when stats disabled. 0 = Hide messages/disable chat, 1 = Show messages/allow chat", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MaxPoints = CreateConVar("sm_l4dstats_maxpoints", "500", "Maximum number of points that can be earned in a single map. Normal = x1, Adv = x2, Expert = x3", FCVAR_PLUGIN, true, 500.0);
	cvar_DbPrefix = CreateConVar("sm_l4dstats_dbprefix", "", "Prefix for your stats tables", FCVAR_PLUGIN);
	cvar_LeaderboardTime = CreateConVar("sm_l4dstats_leaderboardtime", "14", "Time in days to show Survival Leaderboard times", true, 1.0);
	cvar_FriendlyFireCooldown = CreateConVar("sm_l4dstats_ffire_cooldown", "10.0", "Time in seconds for friendlyfire cooldown", true, 1.0);
	cvar_FriendlyFireCooldownMode = CreateConVar("sm_l4dstats_ffire_cooldownmode", "1", "Friendlyfire cooldown mode. 0 = Disable, 1 = Player specific, 2 = General", true, 0.0, true, 2.0);

	// Game mode Cvars
	cvar_EnableCoop = CreateConVar("sm_l4dstats_enablecoop", "1", "Enable/Disable coop stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableSv = CreateConVar("sm_l4dstats_enablesv", "1", "Enable/Disable survival stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_EnableVersus = CreateConVar("sm_l4dstats_enableversus", "1", "Enable/Disable versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Infected point Cvars
	cvar_Infected = CreateConVar("sm_l4dstats_infected", "1", "Base score for killing a Common Infected", FCVAR_PLUGIN, true, 1.0);
	cvar_Hunter = CreateConVar("sm_l4dstats_hunter", "2", "Base score for killing a Hunter", FCVAR_PLUGIN, true, 1.0);
	cvar_Smoker = CreateConVar("sm_l4dstats_smoker", "3", "Base score for killing a Smoker", FCVAR_PLUGIN, true, 1.0);
	cvar_Boomer = CreateConVar("sm_l4dstats_boomer", "5", "Base score for killing a Boomer", FCVAR_PLUGIN, true, 1.0);
	cvar_Spitter = CreateConVar("sm_l4dstats_spitter", "5", "Base score for killing a Spitter", FCVAR_PLUGIN, true, 1.0);
	cvar_Jockey = CreateConVar("sm_l4dstats_jockey", "5", "Base score for killing a Jockey", FCVAR_PLUGIN, true, 1.0);
	cvar_Charger = CreateConVar("sm_l4dstats_charger", "5", "Base score for killing a Charger", FCVAR_PLUGIN, true, 1.0);
	cvar_InfectedDamage = CreateConVar("sm_l4dstats_infected_damage", "2", "The amount of damage inflicted to Survivors to earn 1 point", FCVAR_PLUGIN, true, 1.0);

	// Misc personal gain Cvars
	cvar_Pills = CreateConVar("sm_l4dstats_pills", "15", "Base score for giving Pills to a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_Medkit = CreateConVar("sm_l4dstats_medkit", "20", "Base score for using a Medkit on a friendly", FCVAR_PLUGIN, true, 1.0);
	cvar_SmokerDrag = CreateConVar("sm_l4dstats_smokerdrag", "5", "Base score for saving a friendly from a Smoker Tongue Drag", FCVAR_PLUGIN, true, 1.0);
	cvar_ChokePounce = CreateConVar("sm_l4dstats_chokepounce", "10", "Base score for saving a friendly from a Hunter Pounce / Smoker Choke", FCVAR_PLUGIN, true, 1.0);
	cvar_Revive = CreateConVar("sm_l4dstats_revive", "15", "Base score for Revive a friendly from Incapacitated state", FCVAR_PLUGIN, true, 1.0);
	cvar_Rescue = CreateConVar("sm_l4dstats_rescue", "10", "Base score for Rescue a friendly from a closet", FCVAR_PLUGIN, true, 1.0);
	cvar_Protect = CreateConVar("sm_l4dstats_protect", "3", "Base score for Protect a friendly in combat", FCVAR_PLUGIN, true, 1.0);
	cvar_PlayerLedgeSuccess = CreateConVar("sm_l4dstats_ledgegrap", "15", "Base score for causing a survivor to grap a ledge", FCVAR_PLUGIN, true, 1.0);

	// Team gain Cvars
	cvar_Tank = CreateConVar("sm_l4dstats_tank", "25", "Base team score for killing a Tank", FCVAR_PLUGIN, true, 1.0);
	cvar_Panic = CreateConVar("sm_l4dstats_panic", "25", "Base team score for surviving a Panic Event with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
	cvar_BoomerMob = CreateConVar("sm_l4dstats_boomermob", "10", "Base team score for surviving a Boomer Mob with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
	cvar_SafeHouse = CreateConVar("sm_l4dstats_safehouse", "10", "Base score for reaching a Safe House", FCVAR_PLUGIN, true, 1.0);
	cvar_Witch = CreateConVar("sm_l4dstats_witch", "10", "Base score for Not Disturbing a Witch", FCVAR_PLUGIN, true, 1.0);
	cvar_VictorySurvivors = CreateConVar("sm_l4dstats_campaign", "5", "Base score for Completing a Campaign", FCVAR_PLUGIN, true, 1.0);
	cvar_VictoryInfected = CreateConVar("sm_l4dstats_infected_win", "30", "Base victory score for Infected Team", FCVAR_PLUGIN, true, 1.0);

	// Point loss Cvars
	cvar_FFire = CreateConVar("sm_l4dstats_ffire", "25", "Base score for Friendly Fire", FCVAR_PLUGIN, true, 1.0);
	cvar_FIncap = CreateConVar("sm_l4dstats_fincap", "75", "Base score for a Friendly Incap", FCVAR_PLUGIN, true, 1.0);
	cvar_FKill = CreateConVar("sm_l4dstats_fkill", "250", "Base score for a Friendly Kill", FCVAR_PLUGIN, true, 1.0);
	cvar_InSafeRoom = CreateConVar("sm_l4dstats_insaferoom", "5", "Base score for letting Infected in the Safe Room", FCVAR_PLUGIN, true, 1.0);
	cvar_Restart = CreateConVar("sm_l4dstats_restart", "100", "Base score for a Round Restart", FCVAR_PLUGIN, true, 1.0);
	cvar_MedkitUsedPointPenalty = CreateConVar("sm_l4dstats_medkitpenalty", "0.1", "Score reduction for all Survivor earned points for each used MedKit (NormalPoints * (1 - MedKitsUsed * MedKitPenalty))", FCVAR_PLUGIN, true, 0.0, true, 0.5);
	cvar_MedkitUsedPointPenaltyMax = CreateConVar("sm_l4dstats_medkitpenaltymax", "1.0", "Maximum score reduction (the score reduction will not go over this value when a MedKit is used)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MedkitUsedFree = CreateConVar("sm_l4dstats_medkitpenaltyfree", "1", "The reduction to Survivors score will start after this many MedKits have been used (Example: if value is 3, the first two MedKits are free of penalty)", FCVAR_PLUGIN, true, 1.0);

	// Survivor point Cvars
	cvar_SurvivorDeath = CreateConVar("sm_l4dstats_survivor_death", "40", "Base score for killing a Survivor", FCVAR_PLUGIN, true, 1.0);
	cvar_SurvivorIncap = CreateConVar("sm_l4dstats_survivor_incap", "15", "Base score for incapacitating a Survivor", FCVAR_PLUGIN, true, 1.0);

	// Hunter point Cvars
	cvar_HunterPerfectPounceDamage = CreateConVar("sm_l4dstats_perfectpouncedamage", "25", "The amount of damage from a pounce to earn Perfect Pounce (Death From Above) success points", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterPerfectPounceSuccess = CreateConVar("sm_l4dstats_perfectpouncesuccess", "25", "Base score for a successful Perfect Pounce", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterNicePounceDamage = CreateConVar("sm_l4dstats_nicepouncedamage", "15", "The amount of damage from a pounce to earn Nice Pounce (Pain From Above) success points", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterNicePounceSuccess = CreateConVar("sm_l4dstats_nicepouncesuccess", "10", "Base score for a successful Nice Pounce", FCVAR_PLUGIN, true, 1.0);
	cvar_HunterDamageCap = CreateConVar("sm_l4dstats_hunterdamagecap", "25", "Hunter stored damage cap", FCVAR_PLUGIN, true, 25.0);

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
	cvar_BoomerSuccess = CreateConVar("sm_l4dstats_boomersuccess", "5", "Base score for a successfully vomiting on a survivor", FCVAR_PLUGIN, true, 1.0);
	cvar_BoomerPerfectHits = CreateConVar("sm_l4dstats_boomerperfecthits", "4", "The number of survivors that needs to get blinded to earn Boomer Perfect Vomit Award and success points", FCVAR_PLUGIN, true, 4.0);
	cvar_BoomerPerfectSuccess = CreateConVar("sm_l4dstats_boomerperfectsuccess", "30", "Base score for a successful Boomer Perfect Vomit", FCVAR_PLUGIN, true, 1.0);

	// Tank point Cvars
	cvar_TankDamageCap = CreateConVar("sm_l4dstats_tankdmgcap", "500", "Maximum inflicted damage done by Tank to earn Infected damagepoints", FCVAR_PLUGIN, true, 150.0);
	cvar_TankDamageTotal = CreateConVar("sm_l4dstats_bulldozer", "200", "Damage inflicted by Tank to earn Bulldozer Award and success points", FCVAR_PLUGIN, true, 200.0);
	cvar_TankDamageTotalSuccess = CreateConVar("sm_l4dstats_bulldozersuccess", "50", "Base score for Bulldozer Award", FCVAR_PLUGIN, true, 1.0);
	cvar_TankThrowRockSuccess = CreateConVar("sm_l4dstats_tankthrowrocksuccess", "5", "Base score for a Tank thrown rock hit", FCVAR_PLUGIN, true, 0.0);

	// Make that config!
	AutoExecConfig(true, "l4d_stats");

	// Personal Gain Events
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("infected_death", event_InfectedDeath);
	HookEvent("tank_killed", event_TankKilled);
	HookEvent("weapon_given", event_GivePills);
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
	HookEvent("award_earned", event_Award);
	HookEvent("witch_spawn", event_WitchSpawn);
	HookEvent("witch_harasser_set", event_WitchDisturb);
	HookEvent("round_start", event_RoundStart);
	HookEvent("game_start", event_GameStart);

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

	// Car alarm
	//HookEvent("explain_disturbance", event_CarAlarm);
	
	// Achievements
	HookEvent("achievement_earned", event_Achievement);


	// Startup the plugin's timers
	CreateTimer(1.0, InitPlayers);
	CreateTimer(60.0, timer_UpdatePlayers, INVALID_HANDLE, TIMER_REPEAT);
	UpdateTimer = CreateTimer(GetConVarFloat(cvar_UpdateRate), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	HookConVarChange(cvar_UpdateRate, action_TimerChanged);

	// Clientprefs settings
	ClientMaps = RegClientCookie("l4dstats_maps", "Number of maps completed in a campaign", CookieAccess_Private);

	// Register chat commands for rank panels
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);

	// Register console commands for rank panels
	RegConsoleCmd("sm_rank", cmd_ShowRank);
	RegConsoleCmd("sm_top10", cmd_ShowTop10);
	
	//RegConsoleCmd("sm_l4dstats_test", cmd_StatsTest);

	ResetInfVars();
}

// Reset all boolean variables when a map changes.

public OnMapStart()
{
	ResetVars();
}

// Init player on connect, and update total rank and client rank.

public OnClientPostAdminCheck(client)
{
	if (db == INVALID_HANDLE)
		return;

	InitializeClientInf(client);

	if (IsClientBot(client))
		return;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	CheckPlayerDB(client);

	TimerPoints[client] = 0;
	TimerKills[client] = 0;
	TimerHeadshots[client] = 0;

	SQL_TQuery(db, GetRankTotal, "SELECT COUNT(*) FROM players", client);

	if (IsGameModeVersus())
		SQL_TQuery(db, GetGameModeRankTotal, "SELECT COUNT(*) FROM players WHERE playtime_versus > 0", client);
	else
		SQL_TQuery(db, GetGameModeRankTotal, "SELECT COUNT(*) FROM players WHERE playtime > 0", client);

	decl String:query[256];
	Format(query, sizeof(query), "SELECT points + points_survivors + points_infected FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, GetClientPoints, query, client);

	Format(query, sizeof(query), "SELECT points, points_survivors + points_infected FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, GetClientGameModePoints, query, client);

	CreateTimer(10.0, RankConnect, client);
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

	if (IsClientBot(client))
		return;

	if (GetClientTeam(client) == TEAM_SURVIVORS)
		InterstitialPlayerUpdate(client);
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

// Called after the connection to the database is established

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetVars();
	CheckCurrentMapDB();
}

// Game start

public Action:event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
//	LogMessage("GAME STARTS");
//	PrintToConsole(0, "GAME STARTS");
}

// Make connection to database.

public ConnectDB()
{
	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		new String:Error[256];
		db = SQL_Connect(DB_CONF_NAME, true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
			LogError("Failed to connect to database: %s", Error);
		else if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
		{
			if (SQL_GetError(db, Error, sizeof(Error)))
				LogError("Failed to update encoding to UTF8: %s", Error);
			else
				LogError("Failed to update encoding to UTF8: unknown");
		}
	}
	else
		LogError("Database.cfg missing '%s' entry!", DB_CONF_NAME);
}

public Action:timer_ProtectedFriendly(Handle:timer, any:data)
{
	TimerProtectedFriendly[data] = INVALID_HANDLE;
	new ProtectedFriendlies = ProtectedFriendlyCounter[data];
	ProtectedFriendlyCounter[data] = 0;

	if (data == 0 || !IsClientConnected(data) || !IsClientInGame(data) || IsClientBot(data))
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Protect) * ProtectedFriendlies, 2, 3);
	CurrentPoints[data] = CurrentPoints[data] + Score;

	UpdateMapStat("points", Score);

	new String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientAuthString(data, UserID, sizeof(UserID));
	decl String:UserName[MAX_LINE_WIDTH];
	GetClientName(data, UserName, sizeof(UserName));

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

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

		GetClientAuthString(data, iID, sizeof(iID));
		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i WHERE steamid = '%s'", Score, iID);
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
		GetClientAuthString(data, iID, sizeof(iID));
		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", Score, AwardCounter, OriginalHitCounter, (BoomerVomitUpdated[data] ? 0 : 1), iID);
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

	SQL_TQuery(db, GetRankTotal, "SELECT COUNT(*) FROM players", 0);

	decl String:SteamID[MAX_LINE_WIDTH];
	decl String:query[256];
	new maxplayers = GetMaxClients();

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			CheckPlayerDB(i);

			GetClientAuthString(i, SteamID, sizeof(SteamID));
			Format(query, sizeof(query), "SELECT points + points_survivors + points_infected FROM players WHERE steamid = '%s'", SteamID);
			SQL_TQuery(db, GetClientPoints, query, i);

			TimerPoints[i] = 0;
			TimerKills[i] = 0;
		}
	}
}

// Check if a map is already in the DB.

CheckCurrentMapDB()
{
	if (StatsDisabled(true))
		return;

	decl String:MapName[MAX_LINE_WIDTH];
	GetCurrentMap(MapName, sizeof(MapName));

	decl String:query[512];
	Format(query, sizeof(query), "SELECT name FROM maps WHERE name = '%s' and versus = %i", MapName, IsGameModeVersus());

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

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO maps SET name = '%s', custom = 1, versus = %i", MapName, IsGameModeVersus());

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
	GetClientAuthString(client, SteamID, sizeof(SteamID));

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
		GetClientAuthString(client, SteamID, sizeof(SteamID));

		new String:query[512];
		Format(query, sizeof(query), "INSERT IGNORE INTO players SET steamid = '%s'", SteamID);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}

	UpdatePlayer(client);
}

// Run a SQL query, used for UPDATE's only.

public SendSQLUpdate(const String:query[])
{
	if (db == INVALID_HANDLE)
		return;

	if (DEBUG)
	{
		if (QueryCounter >= 256)
			QueryCounter = 0;

		new queryid = QueryCounter++;

		Format(QueryBuffer[queryid], MAX_QUERY_COUNTER, query);

		SQL_TQuery(db, SQLErrorCheckCallback, query, queryid);
	}
	else
		SQL_TQuery(db, SQLErrorCheckCallback, query);
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
	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	decl String:Name[MAX_LINE_WIDTH];
	GetClientName(client, Name, sizeof(Name));

	ReplaceString(Name, sizeof(Name), "<?php", "");
	ReplaceString(Name, sizeof(Name), "<?PHP", "");
	ReplaceString(Name, sizeof(Name), "?>", "");
	ReplaceString(Name, sizeof(Name), "\\", "");
	ReplaceString(Name, sizeof(Name), "\"", "");
	ReplaceString(Name, sizeof(Name), "'", "");
	ReplaceString(Name, sizeof(Name), ";", "");
	ReplaceString(Name, sizeof(Name), "´", "");
	ReplaceString(Name, sizeof(Name), "`", "");

	decl String:Playtime[16];
	if (IsGameModeVersus())
		Format(Playtime, sizeof(Playtime), "playtime_versus");
	else
		Format(Playtime, sizeof(Playtime), "playtime");

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE players SET lastontime = UNIX_TIMESTAMP(), %s = %s + 1, name = '%s' WHERE steamid = '%s'", Playtime, Playtime, Name, SteamID);
	SendSQLUpdate(query);
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
	Format(query, sizeof(query), "UPDATE maps SET %s = %s + %i WHERE name = '%s' and versus = %i", FieldSQL, FieldSQL, Score, MapName, IsGameModeVersus());
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

// End friendly fire cooldown.

public Action:timer_FriendlyFireCooldownEnd(Handle:timer, any:data)
{
	FriendlyFireCooldown[FriendlyFireCooldownPrm[data][0]][FriendlyFireCooldownPrm[data][1]] = false;
	FriendlyFireCooldownTimer[FriendlyFireCooldownPrm[data][0]][FriendlyFireCooldownPrm[data][1]] = INVALID_HANDLE;
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
	GetClientAuthString(client, ClientID, sizeof(ClientID));

	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	new len = 0;
	decl String:query[1024];
	len += Format(query[len], sizeof(query)-len, "UPDATE players SET %s = %s + %i, ", UpdatePoints, UpdatePoints, TimerPoints[client]);
	len += Format(query[len], sizeof(query)-len, "kills = kills + %i, kill_infected = kill_infected + %i, ", TimerKills[client], TimerKills[client]);
	len += Format(query[len], sizeof(query)-len, "headshots = headshots + %i ", TimerHeadshots[client]);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("kills", TimerKills[client]);
	UpdateMapStat("points", TimerPoints[client]);

	CurrentPoints[client] = CurrentPoints[client] + TimerPoints[client];
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

	if (AttackerIsBot)
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0 && VictimTeam == TEAM_SURVIVORS && (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1] || PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1] || PlayerLunged[Victim][0] && PlayerLunged[Victim][1]) && IsGameModeVersus())
			PlayerDeathExternal(Victim);

		return;
	}

	new Mode = GetConVarInt(cvar_AnnounceMode);
	new AttackerTeam = GetClientTeam(Attacker);
	decl String:AttackerName[MAX_LINE_WIDTH];
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
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

		if (StrEqual(VictimName, "Hunter"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_HUNTER;
		}
		else if (StrEqual(VictimName, "Smoker"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SMOKER;
		}
		else if (StrEqual(VictimName, "Boomer"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_BOOMER;
		}
		if (StrEqual(VictimName, "Spitter"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SPITTER_L4D2;
		}
		else if (StrEqual(VictimName, "Jockey"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_JOCKEY_L4D2;
		}
		else if (StrEqual(VictimName, "Charger"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_CHARGER_L4D2;
		}
		else if (StrEqual(VictimName, "Tank"))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_TANK_L4D2;
		}
		else
			return;
	}

	if (Victim > 0 && (VictimInfType == INF_ID_HUNTER || VictimInfType == INF_ID_SMOKER))
		InitializeClientInf(Victim);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	// Attacker is a Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_INFECTED)
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

		new String:UpdatePoints[32];

		if (IsGameModeVersus())
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		else
			Format(UpdatePoints, sizeof(UpdatePoints), "points");

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
		CurrentPoints[Attacker] = CurrentPoints[Attacker] + Score;
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
	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
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

	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[512];

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientAuthString(i, iID, sizeof(iID));
			Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_tankkill = award_tankkill + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);

			CurrentPoints[i] = CurrentPoints[i] + Score;
		}
	}

	if (Mode && Score > 0)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for killing a Tank with \x05%i Deaths\x01!", Score, Deaths);

	UpdateMapStat("kills", 1);
	UpdateMapStat("points", Score);
	TankCount = TankCount + 1;
}

// Pill give code. Special note, Pills can only be given once.

public Action:event_GivePills(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Recepient = GetClientOfUserId(GetEventInt(event, "userid"));
	new Giver = GetClientOfUserId(GetEventInt(event, "giver"));
	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (IsClientBot(Recepient) || IsClientBot(Giver))
		return;

	new PillsID = GetEventInt(event, "weaponentid");

	if (Pills[PillsID] == 1)
		return;
	else
		Pills[PillsID] = 1;

	decl String:RecepientName[MAX_LINE_WIDTH];
	GetClientName(Recepient, RecepientName, sizeof(RecepientName));
	decl String:RecepientID[MAX_LINE_WIDTH];
	GetClientAuthString(Recepient, RecepientID, sizeof(RecepientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientAuthString(Giver, GiverID, sizeof(GiverID));

	decl String:Item[16];

	if (GetEventInt(event, "weapon") == 12)
		Format(Item, sizeof(Item), "Pain Pills");
	else
		return;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Pills), 2, 4);
	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_pills = award_pills + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	CurrentPoints[Giver] = CurrentPoints[Giver] + Score;

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for giving pills to \x05%s\x01!", Score, RecepientName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for giving pills to \x05%s\x01!", GiverName, Score, RecepientName);
	}
}

// Medkit give code.

public Action:event_HealPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Recepient = GetClientOfUserId(GetEventInt(event, "subject"));
	new Giver = GetClientOfUserId(GetEventInt(event, "userid"));
	new Amount = GetEventInt(event, "health_restored");
	new Mode = GetConVarInt(cvar_AnnounceMode);

	MedkitsUsedCounter++;
	AnnounceMedKitPenalty();

	if (IsClientBot(Recepient) || IsClientBot(Giver))
		return;

	if (Recepient == Giver)
		return;

	decl String:RecepientName[MAX_LINE_WIDTH];
	GetClientName(Recepient, RecepientName, sizeof(RecepientName));
	decl String:RecepientID[MAX_LINE_WIDTH];
	GetClientAuthString(Recepient, RecepientID, sizeof(RecepientID));

	decl String:GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	decl String:GiverID[MAX_LINE_WIDTH];
	GetClientAuthString(Giver, GiverID, sizeof(GiverID));

	new Score = (Amount + 1) / 2;
	if (GetConVarInt(cvar_MedkitMode))
		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Medkit), 2, 4);
	else
		Score = ModifyScoreDifficulty(Score, 2, 3);

	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_medkit = award_medkit + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	CurrentPoints[Giver] = CurrentPoints[Giver] + Score;

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for healing \x05%s\x01!", Score, RecepientName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for healing \x05%s\x01!", GiverName, Score, RecepientName);
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

	new CooldownMode = GetConVarInt(cvar_FriendlyFireCooldownMode);

	if (CooldownMode == 1 || CooldownMode == 2)
	{
		new Target = 0;

		if (CooldownMode == 1)
			Target = Victim;

		if (FriendlyFireCooldown[Attacker][Target])
			return;

		FriendlyFireCooldown[Attacker][Target] = true;

		if (FriendlyFireCooldownPrmCounter >= MAXPLAYERS)
			FriendlyFireCooldownPrmCounter = 0;

		FriendlyFireCooldownPrm[FriendlyFireCooldownPrmCounter][0] = Attacker;
		FriendlyFireCooldownPrm[FriendlyFireCooldownPrmCounter][1] = Target;
		FriendlyFireCooldownTimer[Attacker][Target] = CreateTimer(GetConVarFloat(cvar_FriendlyFireCooldown), timer_FriendlyFireCooldownEnd, FriendlyFireCooldownPrmCounter++);
	}

	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FFire), 2, 4);
	Score = Score * -1;

	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", AttackerName, Score, VictimName);
}

// Campaign win code. Points are based on maps completed + survivors.

public Action:event_CampaignWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	CampaignOver = true;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_VictorySurvivors), 4, 12);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	new SurvivorCount = GetEventInt(event, "survivorcount");
	new BaseScore = Score * SurvivorCount;

	decl String:query[1024];
	decl String:iID[MAX_LINE_WIDTH];
	decl String:Name[MAX_LINE_WIDTH];
	decl String:cookie[MAX_LINE_WIDTH];
	new Maps = 0;
	new WinScore = 0;
	new String:UpdatePoints[32];

	// TODO: IT NEVER GETS HERE ON VERSUS! FIND ANOTHER ROUTE?
	new IsVersus = IsGameModeVersus();

	if (IsVersus)
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientAuthString(i, iID, sizeof(iID));

			GetClientCookie(i, Handle:ClientMaps, cookie, 32);
			Maps = StringToInt(cookie) + 1;

			if (IsVersus)
				Maps = RoundToFloor(float(Maps) / 2);

			WinScore = BaseScore * Maps;

			if (Score > 0)
			{
				if (Mode == 1 || Mode == 2)
				{
					PrintToChat(i, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for completing %i Chapters of this %s Campaign with \x05%i %s\x01!", WinScore, Maps, (IsVersus ? "Versus" : "Co-op"), SurvivorCount, (IsVersus ? "players" : "survivors"));
				}
				else if (Mode == 3)
				{
					GetClientName(i, Name, sizeof(Name));
					PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for completing %i Chapters of this %s Campaign with \x05%i %s\x01!", Name, WinScore, Maps, (IsVersus ? "Versus" : "Co-op"), SurvivorCount, (IsVersus ? "players" : "survivors"));
				}

				Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_campaigns = award_campaigns + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, WinScore, iID);
				SendSQLUpdate(query);

				SetClientCookie(i, ClientMaps, "0");
				UpdateMapStat("points", WinScore);
				CurrentPoints[i] = CurrentPoints[i] + WinScore;
			}
		}
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
	CreateTimer(75.0, timer_PanicEventEnd);
}

// Panic Event with no Incaps code. Points given to all players.

public Action:timer_PanicEventEnd(Handle:timer, Handle:hndl)
{
	if (StatsDisabled())
		return;

	if (CampaignOver)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PanicEvent && !PanicEventIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Panic), 2, 4);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			new String:UpdatePoints[32];

			if (IsGameModeVersus())
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			else
				Format(UpdatePoints, sizeof(UpdatePoints), "points");

			new maxplayers = GetMaxClients();
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientAuthString(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s' ", UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					CurrentPoints[i] = CurrentPoints[i] + Score;
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

	PlayerBlinded[Victim][0] = 1;
	PlayerBlinded[Victim][1] = Attacker;

	if (IsClientBot(Attacker))
		return;

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
		CreateTimer(INF_WEAROFF_TIME, timer_EndBoomerBlinded);

	new Mode = GetConVarInt(cvar_AnnounceMode);

	if (PlayerVomited && !PlayerVomitedIncap)
	{
		new Score = ModifyScoreDifficulty(GetConVarInt(cvar_BoomerMob), 2, 5);

		if (Score > 0)
		{
			decl String:query[1024];
			decl String:iID[MAX_LINE_WIDTH];
			new String:UpdatePoints[32];

			if (IsGameModeVersus())
				Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			else
				Format(UpdatePoints, sizeof(UpdatePoints), "points");

			new maxplayers = GetMaxClients();
			for (new i = 1; i <= maxplayers; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientAuthString(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s' ", UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					CurrentPoints[i] = CurrentPoints[i] + Score;
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

public Action:event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (PanicEvent)
		PanicEventIncap = true;

	if (PlayerVomited)
		PlayerVomitedIncap = true;

	if (Victim <= 0)
		return;

	if (!Attacker || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0 && Victim > 0 && (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1] || PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1]) && IsGameModeVersus())
			PlayerIncapExternal(Victim);

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
		GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
		decl String:AttackerName[MAX_LINE_WIDTH];
		GetClientName(Attacker, AttackerName, sizeof(AttackerName));

		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FIncap), 2, 4);
		Score = Score * -1;

		new String:UpdatePoints[32];

		if (IsGameModeVersus())
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		else
			Format(UpdatePoints, sizeof(UpdatePoints), "points");

		decl String:query[512];
		Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AttackerID);
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
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged);

	HunterSmokerSave(GetEventInt(event, "userid"), Victim, GetConVarInt(cvar_ChokePounce), 2, 3, "Hunter", "award_hunter");
}

// BUG: It is possible that the Tank punches a Survivor of the rooftop (example) and gets more than tens of thousand for score!
// Player is hanging from a ledge.

public Action:event_PlayerFallDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver || !IsGameModeVersus())
		return;

	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));
	new Damage = RoundToNearest(GetEventFloat(event, "damage"));

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
	if (StatsDisabled() || !IsGameModeVersus())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "causer"));

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_PlayerLedgeSuccess), 0.9, 0.8);

	if (Score > 0)
	{
		new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
		decl String:VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		new Mode = GetConVarInt(cvar_AnnounceMode);

		decl String:ClientID[MAX_LINE_WIDTH];
		GetClientAuthString(Attacker, ClientID, sizeof(ClientID));

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", Score, ClientID);
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
	TankPointsCounter[Player] = 0;
	TankDamageCounter[Player] = 0;
	TankDamageTotalCounter[Player] = 0;
	TankSurvivorKillCounter[Player] = 0;

	PlayerBlinded[Player][0] = 0;
	PlayerBlinded[Player][1] = 0;
	PlayerParalyzed[Player][0] = 0;
	PlayerParalyzed[Player][1] = 0;
	PlayerLunged[Player][0] = 0;
	PlayerLunged[Player][1] = 0;

	if (!IsClientBot(Player))
		SetClientInfectedType(Player);
}

// Player hurt. Used for calculating damage points for the Infected players.

public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || CampaignOver)
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Attacker == 0 || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0 && Victim > 0 && (PlayerBlinded[Victim][0] && PlayerBlinded[Victim][1] || PlayerParalyzed[Victim][0] && PlayerParalyzed[Victim][1] || PlayerLunged[Victim][0] && PlayerLunged[Victim][1]) && IsGameModeVersus())
			SurvivorHurtExternal(event, Victim);

		return;
	}

	new AttackerTeam = GetClientTeam(Attacker);
	new AttackerInfType = -1;

	if (Attacker > 0 && AttackerTeam == TEAM_INFECTED)
		AttackerInfType = ClientInfectedType[Attacker];

	if (AttackerInfType < 0)
		return;

//	decl String:AttackerID[MAX_LINE_WIDTH];
//	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));

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

	new Damage = GetEventInt(event, "dmg_health");

	SurvivorHurt(Attacker, Victim, Damage, AttackerInfType, event);
}

// Smoker events.

public Action:event_SmokerGrap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled() || !IsGameModeVersus())
		return;

	new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));

	PlayerParalyzed[Victim][0] = 1;
	PlayerParalyzed[Victim][1] = Attacker;
}

// Hunter events.

public Action:event_HunterRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndHunterLunged);
}

// Car alarm started.

//public Action:event_CarAlarm(Handle:event, const String:name[], bool:dontBroadcast)
//{
//	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
//	decl String:ClientName[MAX_LINE_WIDTH];
//	GetClientName(Client, ClientName, sizeof(ClientName));
//
//	LogMessage("Car Alarm! Name = %s", ClientName);
//	PrintToConsole(0, "Car Alarm! Name = %s", ClientName);
//}

// Smoker events.

public Action:event_SmokerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	new Player = GetClientOfUserId(GetEventInt(event, "victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, timer_EndSmokerParalyzed);
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
		LogError("Achievement earned: %i", Achievement);
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
		GetClientAuthString(Player, iID, sizeof(iID));
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

decl String:teststr[1024];

Format(teststr, sizeof(teststr), "[TEST] HunterPosition[Attacker][0] = %f / HunterPosition[Attacker][1] = %f / HunterPosition[Attacker][2] = %f", HunterPosition[Attacker][0], HunterPosition[Attacker][1], HunterPosition[Attacker][2]);
PrintToChat(Attacker, teststr);
LogMessage(teststr);

Format(teststr, sizeof(teststr), "[TEST] PouncePosition[0] = %f / PouncePosition[1] = %f / PouncePosition[2] = %f", PouncePosition[0], PouncePosition[1], PouncePosition[2]);
PrintToChat(Attacker, teststr);
LogMessage(teststr);

Format(teststr, sizeof(teststr), "[TEST] Pounce distance = %i / Pounce minimum distance = %i", PounceDistance, MinPounceDistance);
PrintToChat(Attacker, teststr);
LogMessage(teststr);

	if (PounceDistance < MinPounceDistance)
		return;

	new Dmg = RoundToNearest((((PounceDistance - float(MinPounceDistance)) / float(MaxPounceDistance - MinPounceDistance)) * float(MaxPounceDamage)) + 1);
	new DmgCap = GetConVarInt(cvar_HunterDamageCap);

Format(teststr, sizeof(teststr), "[TEST] Pounce damage = %i / Pounce damagecap = %i", Dmg, DmgCap);
PrintToChat(Attacker, teststr);
LogMessage(teststr);

	if (Dmg > DmgCap)
		Dmg = DmgCap;

	new PerfectDmgLimit = GetConVarInt(cvar_HunterPerfectPounceDamage);
	new NiceDmgLimit = GetConVarInt(cvar_HunterNicePounceDamage);

Format(teststr, sizeof(teststr), "[TEST] Pounce NiceDmgLimit = %i / Pounce PerfectDmgLimit = %i", NiceDmgLimit, PerfectDmgLimit);
PrintToChat(Attacker, teststr);
LogMessage(teststr);

	UpdateHunterDamage(Attacker, Dmg);

	if (Dmg < NiceDmgLimit && Dmg < PerfectDmgLimit)
		return;

	new Mode = GetConVarInt(cvar_AnnounceMode);

	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = 0;
	decl String:Label[32];
	decl String:query[1024];

	if (Dmg >= PerfectDmgLimit)
	{
		Score = GetConVarInt(cvar_HunterPerfectPounceSuccess);
		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", Score, AttackerID);
		Format(Label, sizeof(Label), "Death From Above");
	}
	else
	{
		Score = GetConVarInt(cvar_HunterNicePounceSuccess);
		Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", Score, AttackerID);
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
	GetClientAuthString(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VictimID[MAX_LINE_WIDTH];
	GetClientAuthString(Victim, VictimID, sizeof(VictimID));

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Revive), 2, 3);

	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, award_revive = award_revive + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, SaviorID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	CurrentPoints[Savior] = CurrentPoints[Savior] + Score;

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			PrintToChat(Savior, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Reviving \x05%s\x01!", Score, VictimName);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Reviving \x05%s\x01!", SaviorName, Score, VictimName);
	}
}

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

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award(Handle:event, const String:name[], bool:dontBroadcast)
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

	new Recepient;
	decl String:RecepientName[MAX_LINE_WIDTH];

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

		Recepient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recepient))
			return;

		Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3);
		GetClientName(Recepient, RecepientName, sizeof(RecepientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		CurrentPoints[User] = CurrentPoints[User] + Score;

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				PrintToChat(User, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Rescuing \x05%s\x01!", Score, RecepientName);
			else if (Mode == 3)
				PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Rescuing \x05%s\x01!", UserName, Score, RecepientName);
		}
	}
	else if (AwardID == 80) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
	else if (AwardID == 83 && !CampaignOver) // Team kill
	{
		if (!SubjectID)
			return;

		Recepient = GetClientOfUserId(GetClientUserId(SubjectID));

		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_FKill), 2, 4);
		Score = Score * -1;

		if (Mode == 1 || Mode == 2)
			PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Team Killing!", Score);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Team Killing!", UserName, Score);
	}
	else if (AwardID == 85) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1);
	}
	else if (AwardID == 94) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");
		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_InSafeRoom), 2, 4);
		Score = Score * -1;

		if (Mode == 1 || Mode == 2)
			PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", Score);
		else if (Mode == 3)
			PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", UserName, Score);
	}
	else if (AwardID == 98) // Round restart
	{
		Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3);
		Score = (400 - Score) * -1;
		UpdateMapStat("restarts", 1);

		if (Mode)
			PrintToChat(User, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying!", Score);
	}
	else
	{
//		if (DEBUG)
//			LogError("event_Award => %i", AwardID);
		return;
	}

	new String:UpdatePoints[32];
	decl String:UserID[MAX_LINE_WIDTH];
	GetClientAuthString(User, UserID, sizeof(UserID));

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i%s WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
}

// Reset Witch existence in the world when a new one is created.

public Action:event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StatsDisabled())
		return;

	WitchExists = true;
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
		GetClientAuthString(User, UserID, sizeof(UserID));

		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE players SET award_witchdisturb = award_witchdisturb + 1 WHERE steamid = '%s'", UserID);
		SendSQLUpdate(query);
	}
}

// DEBUG
public Action:cmd_StatsTest(client, args)
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));
	PrintToConsole(0, "Gamemode: %s", CurrentMode);
	UpdateMapStat("playtime", 10);
	PrintToConsole(0, "Added 10 seconds to maps table current map.");
//	new Float:ReductionFactor = GetMedkitPointReductionFactor();
//
//	PrintToChat(client, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01now earns only \x04%i%% \x01of their normal points after using their \x05%i%s MedKit\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter, (MedkitsUsedCounter == 1 ? "st" : (MedkitsUsedCounter == 2 ? "nd" : (MedkitsUsedCounter == 3 ? "rd" : "th"))), GetClientTeam(client));
}

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

	if (strcmp(Text[Start], "top10", false) == 0)
	{
		cmd_ShowTop10(client, 0);
		if (GetConVarBool(cvar_SilenceChat))
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Begin generating the RANK display panel.
public Action:cmd_ShowRank(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	decl String:query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM players");
	SQL_TQuery(db, GetRankTotal, query, client);

	if (!InvalidGameMode())
	{
		if (IsGameModeVersus())
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime_versus > 0 and points_survivors + points_infected >= %i", ClientGameModePoints[client][1]);
		else
			Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE playtime > 0 and points >= %i", ClientGameModePoints[client][0]);
		SQL_TQuery(db, GetClientGameModeRank, query, client);
	}

	Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE points + points_survivors + points_infected >= %i", ClientPoints[client]);
	SQL_TQuery(db, GetClientRank, query, client);

	Format(query, sizeof(query), "SELECT name, playtime + playtime_versus, points + points_survivors + points_infected, kills, versus_kills_survivors, headshots FROM players WHERE steamid = '%s'", SteamID);
	SQL_TQuery(db, DisplayRank, query, client);

	return Plugin_Handled;
}

// Generate client's point total.
public GetClientPoints(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;

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
public GetClientGameModePoints(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;

	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("GetClientGameModePoints Query failed: %s", error);
		return;
	}

	while (SQL_FetchRow(hndl))
	{
		ClientGameModePoints[client][0] = SQL_FetchInt(hndl, 0); // Co-op
		ClientGameModePoints[client][1] = SQL_FetchInt(hndl, 1); // Versus
	}
}

// Generate client's rank.
public GetClientRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;

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
public GetClientGameModeRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;

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

// Send the RANK panel to the client's display.
public DisplayRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;

	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		return;
	}

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
	}
	else
	{
	  GetClientName(data, Name, sizeof(Name));
		Playtime = 0;
		Points = 0;
		InfectedKilled = 0;
		SurvivorsKilled = 0;
		Headshots = 0;
	}

	new Handle:RankPanel = CreatePanel();
	new String:Value[MAX_LINE_WIDTH];
	new String:URL[MAX_LINE_WIDTH];
	new IsVersus = IsGameModeVersus();

	GetConVarString(cvar_SiteURL, URL, sizeof(URL));
	new Float:HeadshotRatio = Headshots == 0 ? 0.00 : FloatDiv(float(Headshots), float(InfectedKilled))*100;

	Format(Value, sizeof(Value), "Ranking of %s" , Name);
	SetPanelTitle(RankPanel, Value);

	Format(Value, sizeof(Value), "Rank: %i of %i" , ClientRank[client], RankTotal);
	DrawPanelText(RankPanel, Value);

	if (!InvalidGameMode())
	{
		Format(Value, sizeof(Value), "%s Rank: %i of %i" ,(IsVersus ? "Versus" : "Coop") , ClientGameModeRank[client], GameModeRankTotal);
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

	DrawPanelItem(RankPanel, "Close");
	SendPanelToClient(RankPanel, client, RankPanelHandler, 30);
	CloseHandle(RankPanel);
}

// Generate the TOP10 display panel.
public Action:cmd_ShowTop10(client, args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	decl String:query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM players");
	SQL_TQuery(db, GetRankTotal, query, client);

	Format(query, sizeof(query), "SELECT name FROM players ORDER BY points + points_survivors + points_infected DESC LIMIT 10");
	SQL_TQuery(db, DisplayTop10, query, client);

	return Plugin_Handled;
}

// Find a player from Top 10 ranking.
public GetClientFromTop10(client, rank)
{
	decl String:query[256];
	Format(query, sizeof(query), "SELECT points + points_survivors + points_infected, steamid FROM players ORDER BY points + points_survivors + points_infected DESC LIMIT %i,1", rank);
	SQL_TQuery(db, GetClientTop10, query, client);
}

// Send the Top 10 player's info to the client.
public GetClientTop10(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = data;

    if (!client || hndl == INVALID_HANDLE)
        return;

    decl String:query[256];
    decl String:SteamID[MAX_LINE_WIDTH];

    while (SQL_FetchRow(hndl))
    {
        Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE points + points_survivors + points_infected >=%i", SQL_FetchInt(hndl, 0));
        SQL_TQuery(db, GetClientRank, query, client);

        SQL_FetchString(hndl, 1, SteamID, sizeof(SteamID));
        Format(query, sizeof(query), "SELECT name, playtime, points + points_survivors + points_infected, kills, versus_kills_survivors, headshots FROM players WHERE steamid = '%s'", SteamID);
        SQL_TQuery(db, DisplayRank, query, client);
    }
}

// Send the TOP10 panel to the client's display.
public DisplayTop10(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;

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

// Handler for RANK panel.
public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
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
	GetClientAuthString(Savior, SaviorID, sizeof(SaviorID));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	decl String:VictimID[MAX_LINE_WIDTH];
	GetClientAuthString(Victim, VictimID, sizeof(VictimID));

	if (StrEqual(SaviorID, VictimID))
		return;

	new Score = ModifyScoreDifficulty(BasePoints, AdvMult, ExpertMult);
	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i, %s = %s + 1 WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, SQLField, SQLField, SaviorID);
	SendSQLUpdate(query);

	if (Mode && Score > 0)
		PrintToChat(Savior, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for saving \x05%s\x01 from a \x04%s\x01!", Score, VictimName, SaveFrom);

	UpdateMapStat("points", Score);
	CurrentPoints[Savior] = CurrentPoints[Savior] + Score;
}

IsClientBot(client)
{
	if (client == 0 || !IsClientConnected(client))
		return true;

	decl String:SteamID[MAX_LINE_WIDTH];
	GetClientAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT"))
		return true;

	return false;
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

	if (StrEqual(Difficulty, "Hard")) ModifiedScore = BaseScore * AdvMult;
	else if (StrEqual(Difficulty, "Impossible")) ModifiedScore = BaseScore * ExpMult;
	else return BaseScore;

	new Score = 0;
	if (ToCeil)
		Score = RoundToCeil(ModifiedScore);
	else
	  Score = RoundToFloor(ModifiedScore);

	if (IsSurvivorScore && Reduction)
		return GetMedkitPointReductionScore(Score);
	else
		return Score;
}

ModifyScoreDifficultyNR(BaseScore, AdvMult, ExpMult, bool:IsSurvivorScore=true)
{
	return ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, IsSurvivorScore, false);
}

ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, bool:IsSurvivorScore=true, bool:Reduction = true)
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "Hard")) BaseScore = BaseScore * AdvMult;
	if (StrEqual(Difficulty, "Impossible")) BaseScore = BaseScore * ExpMult;

	if (IsSurvivorScore && Reduction)
		return GetMedkitPointReductionScore(BaseScore);
	else
		return BaseScore;
}

IsDifficultyEasy()
{
	decl String:Difficulty[MAX_LINE_WIDTH];
	GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "Easy"))
		return true;

	return false;
}

InvalidGameMode()
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));

	// Currently will always return False in Survival and Versus gamemodes.
	// This will be removed in a future version when stats for those versions work.

	if (StrContains(CurrentMode, "coop", false) != -1 && GetConVarBool(cvar_EnableCoop))
		return false;
	else if (StrContains(CurrentMode, "survival", false) != -1)
		return true;
	else if (StrContains(CurrentMode, "versus", false) != -1 && GetConVarBool(cvar_EnableVersus))
		return false;

	return true;
}

CheckHumans()
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

	// Reset all Infected variables
	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		BoomerHitCounter[i] = 0;
		BoomerVomitUpdated[i] = false;
		InfectedDamageCounter[i] = 0;
		SmokerDamageCounter[i] = 0;
		TankPointsCounter[i] = 0;
		TankDamageCounter[i] = 0;
		ClientInfectedType[i] = 0;
		TankSurvivorKillCounter[i] = 0;
		TankDamageTotalCounter[i] = 0;

		PlayerBlinded[i][0] = 0;
		PlayerBlinded[i][1] = 0;
		PlayerParalyzed[i][0] = 0;
		PlayerParalyzed[i][1] = 0;
		PlayerLunged[i][0] = 0;
		PlayerLunged[i][1] = 0;

		for (j = 0; j < MAXPLAYERS + 1; j++)
		{
			FriendlyFireCooldown[i][j] = false;
			FriendlyFireCooldownTimer[i][j] = INVALID_HANDLE;
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

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		CurrentPoints[i] = 0;
	}

	ResetInfVars();
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

AddScore(Client, Score)
{
	// ToDo: use cvar_MaxPoints to check if the score is within the map limits
	CurrentPoints[Client] = CurrentPoints[Client] + Score;

	return Score;
}

UpdateSmokerDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	decl String:iID[MAX_LINE_WIDTH];
	GetClientAuthString(Client, iID, sizeof(iID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_smoker_damage = infected_smoker_damage + %i WHERE steamid = '%s'", Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_smoker_damage", Damage);
}

CheckSurvivorsWin()
{
	if (CampaignOver)
		return;

	CampaignOver = true;

	new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Witch), 5, 10);
	new Mode = GetConVarInt(cvar_AnnounceMode);
	decl String:iID[MAX_LINE_WIDTH];
	decl String:query[1024];
	new maxplayers = GetMaxClients();
	new String:UpdatePoints[32];

	if (IsGameModeVersus())
		Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
	else
		Format(UpdatePoints, sizeof(UpdatePoints), "points");

	if (Score > 0 && WitchExists && !WitchDisturb)
	{
		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				GetClientAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				CurrentPoints[i] = CurrentPoints[i] + Score;
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

	decl String:cookie[MAX_LINE_WIDTH];
	new Maps = 0;

	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
			{
				InterstitialPlayerUpdate(i);

				GetClientAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE players SET %s = %s + %i%s WHERE steamid = '%s'", UpdatePoints, UpdatePoints, Score, All4Safe, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				CurrentPoints[i] = CurrentPoints[i] + Score;
			}

			GetClientCookie(i, Handle:ClientMaps, cookie, 32);
			Maps = StringToInt(cookie) + 1;
			IntToString(Maps, cookie, sizeof(cookie));
			SetClientCookie(i, ClientMaps, cookie);
		}
	}

	if (Mode && Score > 0)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for reaching a Safe House with \x05%i Deaths!", Score, Deaths);

	PlayerVomited = false;
	PanicEvent = false;
}

CheckSurvivorsAllDown()
{
	if (CampaignOver)
		return;

	decl String:cookie[MAX_LINE_WIDTH];
	new Maps = 0;
	new ClientTeam, ClientIsIncap;
	new bool:ClientIsAlive,  bool:ClientIsBot;
	new KilledSurvivor[MaxClients];
	new AliveInfected[MaxClients];
	new Infected[MaxClients];
	new InfectedCounter = 0, AliveInfectedCounter = 0;
	new i;

	// Add to killing score on all incapacitated surviviors
	new IncapCounter = 0;

	for (i = 1; i <= MaxClients; i++)
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

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
			{
				InterstitialPlayerUpdate(i);
			}

			GetClientCookie(i, Handle:ClientMaps, cookie, 32);
			Maps = StringToInt(cookie) + 1;
			IntToString(Maps, cookie, sizeof(cookie));
			SetClientCookie(i, ClientMaps, cookie);
		}
	}

	decl String:query[1024];
	decl String:ClientID[MAX_LINE_WIDTH];
	new Mode = GetConVarInt(cvar_AnnounceMode);

	for (i = 0; i < AliveInfectedCounter; i++)
		DoInfectedFinalChecks(AliveInfected[i]);

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_VictoryInfected), 0.75, 0.5) * IncapCounter;

	if (Score > 0)
		for (i = 0; i < InfectedCounter; i++)
		{
			GetClientAuthString(Infected[i], ClientID, sizeof(ClientID));
			Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i WHERE steamid = '%s'", Score, ClientID);
			SendSQLUpdate(query);
		}

	UpdateMapStat("infected_win", 1);
	if (IncapCounter > 0)
		UpdateMapStat("survivor_kills", IncapCounter);
	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Score > 0 && Mode)
		PrintToChatTeam(TEAM_INFECTED, "\x04[\x03RANK\x04] \x03ALL INFECTED \x01have earned \x04%i \x01points for killing all survivors!", Score);

	Score = ModifyScoreDifficultyNR(GetConVarInt(cvar_Restart), 2, 3);
	Score = (400 - Score) * -1;

	for (i = 0; i < IncapCounter; i++)
	{
		GetClientAuthString(KilledSurvivor[i], ClientID, sizeof(ClientID));
		Format(query, sizeof(query), "UPDATE players SET points_survivors = points_survivors + %i WHERE steamid = '%s'", Score, ClientID);
		SendSQLUpdate(query);
	}

	if (Mode)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying\x01!", Score);
}

IsGameMode(const String:Gamemode[])
{
	new String:CurrentMode[16];
	GetConVarString(cvar_Gamemode, CurrentMode, sizeof(CurrentMode));

	if (StrContains(CurrentMode, Gamemode, false) != -1)
		return 1;

	return 0;
}

IsGameModeVersus()
{
	return IsGameMode("versus");
}

IsGameModeCoop()
{
	return IsGameMode("coop");
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
		GetClientAuthString(Client, ClientID, sizeof(ClientID));

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
				decl String:ClientID[MAX_LINE_WIDTH];
				GetClientAuthString(Client, ClientID, sizeof(ClientID));

				decl String:query[1024];
				Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", Score, ClientID);
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

UpdateHunterDamage(Client, Damage)
{
	if (Damage <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientAuthString(Client, ClientID, sizeof(ClientID));

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
	GetClientAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET infected_tank_damage = infected_tank_damage + %i WHERE steamid = '%s'", Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tank_damage", Damage);
}

UpdatePlayerScore(Client, Score)
{
	if (Score == 0)
		return;

	if (IsGameModeVersus())
	{
		new ClientTeam = GetClientTeam(Client);
		UpdatePlayerScoreVersus(Client, ClientTeam, Score);
	}
	else
		UpdatePlayerScore2(Client, Score, "points");
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

UpdatePlayerScore2(Client, Score, const String:Points[])
{
	if (Score == 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientAuthString(Client, ClientID, sizeof(ClientID));

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE players SET %s = %s + %i WHERE steamid = '%s'", Points, Points, Score, ClientID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points", Score);
}

UpdateTankSniper(Client)
{
	if (Client <= 0)
		return;

	decl String:ClientID[MAX_LINE_WIDTH];
	GetClientAuthString(Client, ClientID, sizeof(ClientID));

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
	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));

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

	new len = 0;
	decl String:query[1024];
	len += Format(query[len], sizeof(query)-len, "UPDATE players SET points_infected = points_infected + %i, versus_kills_survivors = versus_kills_survivors + 1 ", Score);
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
	CurrentPoints[Attacker] = CurrentPoints[Attacker] + Score;
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
			UpdatePlayerScore2(Attacker, RockHit, "points_infected");
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
}

SurvivorIncappedByInfected(Attacker, Victim, Mode = -1)
{
	if (Attacker > 0 && !IsClientConnected(Attacker) || Attacker > 0 && IsClientBot(Attacker))
		return;

	decl String:AttackerID[MAX_LINE_WIDTH];
	GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
	decl String:AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	decl String:VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	new Score = ModifyScoreDifficultyFloat(GetConVarInt(cvar_SurvivorIncap), 0.75, 0.5);

	if (Score <= 0)
		return;

	decl String:query[512];
	Format(query, sizeof(query), "UPDATE players SET points_infected = points_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", Score, AttackerID);
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

	if (PenaltyFree > MedkitsUsedCounter)
		return 1.0;

	Penalty *= MedkitsUsedCounter;

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

AnnounceMedKitPenalty(Mode = -1)
{
	new Float:ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return;

	if (Mode < 0)
		Mode = GetConVarInt(cvar_AnnounceMode);

	if (Mode)
		PrintToChatTeam(TEAM_SURVIVORS, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01now earns only \x04%i%% \x01of their normal points after using their \x05%i%s MedKit\x01!", RoundToNearest(ReductionFactor * 100), MedkitsUsedCounter, (MedkitsUsedCounter == 1 ? "st" : (MedkitsUsedCounter == 2 ? "nd" : (MedkitsUsedCounter == 3 ? "rd" : "th"))));
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
