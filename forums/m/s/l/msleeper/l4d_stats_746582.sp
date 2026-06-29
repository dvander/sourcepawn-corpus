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
 . Add Versus support
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
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.1.1"
#define MAX_LINE_WIDTH 64

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
new Handle:cvar_MedkitMode = INVALID_HANDLE;
new Handle:cvar_SiteURL = INVALID_HANDLE;
new Handle:cvar_RankOnJoin = INVALID_HANDLE;
new Handle:cvar_SilenceChat = INVALID_HANDLE;
new Handle:cvar_DisabledMessages = INVALID_HANDLE;
new Handle:cvar_MaxPoints = INVALID_HANDLE;
new Handle:cvar_DbPrefix = INVALID_HANDLE;
new Handle:cvar_LeaderboardTime = INVALID_HANDLE;

new Handle:cvar_EnableCoop = INVALID_HANDLE;
new Handle:cvar_EnableSv = INVALID_HANDLE;
new Handle:cvar_EnableVersus = INVALID_HANDLE;

new Handle:cvar_Infected = INVALID_HANDLE;
new Handle:cvar_Hunter = INVALID_HANDLE;
new Handle:cvar_Smoker = INVALID_HANDLE;
new Handle:cvar_Boomer = INVALID_HANDLE;

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
new Handle:cvar_Campaign = INVALID_HANDLE;

new Handle:cvar_FFire = INVALID_HANDLE;
new Handle:cvar_FIncap = INVALID_HANDLE;
new Handle:cvar_FKill = INVALID_HANDLE;
new Handle:cvar_InSafeRoom = INVALID_HANDLE;
new Handle:cvar_Restart = INVALID_HANDLE;

// Clientprefs handles
new Handle:ClientMaps = INVALID_HANDLE;

// Rank panel vars
new RankTotal = 0;
new ClientRank[MAXPLAYERS + 1];
new ClientPoints[MAXPLAYERS + 1];

// Misc arrays
new TimerPoints[MAXPLAYERS + 1];
new TimerKills[MAXPLAYERS + 1];
new TimerHeadshots[MAXPLAYERS + 1];
new Pills[4096];

// Plugin Info
public Plugin:myinfo =
{
    name = "L4D Stats",
    author = "msleeper",
    description = "Player Stats and Ranking in Left 4 Dead Co-op",
    version = PLUGIN_VERSION,
    url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
    // Plugin version public Cvar
    CreateConVar("sm_l4dstats_version", PLUGIN_VERSION, "L4D Stats Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    // Init MySQL connections
    ConnectDB();

    // Disable setting Cvars
    cvar_Difficulty = FindConVar("z_difficulty");
    cvar_Gamemode = FindConVar("mp_gamemode");
    cvar_Cheats = FindConVar("sv_cheats");

    // Config/control Cvars
    cvar_HumansNeeded = CreateConVar("sm_l4dstats_minhumans", "2", "Minimum Human players before stats will be enabled", FCVAR_PLUGIN, true, 1.0, true, 4.0);
    cvar_UpdateRate = CreateConVar("sm_l4dstats_updaterate", "90", "Number of seconds between Common Infected point earn announcement/update", FCVAR_PLUGIN, true, 30.0);
    cvar_AnnounceMode = CreateConVar("sm_l4dstats_announcemode", "2", "Chat announcment mode. 0 = Off, 1 = Player Only, 2 = Player Only w/ Public Headshots, 3 = All Public", FCVAR_PLUGIN, true, 0.0, true, 3.0);
    cvar_MedkitMode = CreateConVar("sm_l4dstats_medkitmode", "0", "Medkit point award mode. 0 = Based on amount healed, 1 = Static amount", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_SiteURL = CreateConVar("sm_l4dstats_siteurl", "", "Community site URL, for rank panel display", FCVAR_PLUGIN);
    cvar_RankOnJoin = CreateConVar("sm_l4dstats_rankonjoin", "1", "Display player's rank when they connect. 0 = Disable, 1 = Enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_SilenceChat = CreateConVar("sm_l4dstats_silencechat", "0", "Silence chat triggers. 0 = Show chat triggers, 1 = Silence chat triggers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_DisabledMessages = CreateConVar("sm_l4dstats_disabledmessages", "1", "Show 'Stats Disabled' messages, allow chat commands to work when stats disabled. 0 = Hide messages/disable chat, 1 = Show messages/allow chat", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_MaxPoints = CreateConVar("sm_l4dstats_maxpoints", "500", "Maximum number of points that can be earned in a single map. Normal = x1, Adv = x2, Expert = x3", FCVAR_PLUGIN, true, 500.0);
    cvar_DbPrefix = CreateConVar("sm_l4dstats_dbprefix", "", "Prefix for your stats tables", FCVAR_PLUGIN);
    cvar_LeaderboardTime = CreateConVar("sm_l4dstats_leaderboardtime", "14", "Time in days to show Survival Leaderboard times", true, 1.0);

    // Game mode Cvars
    cvar_EnableCoop = CreateConVar("sm_l4dstats_enablecoop", "1", "Enable/Disable coop stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_EnableSv = CreateConVar("sm_l4dstats_enablesv", "1", "Enable/Disable survival stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_EnableVersus = CreateConVar("sm_l4dstats_enableversus", "1", "Enable/Disable versus stat tracking", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    // Infected point Cvars
    cvar_Infected = CreateConVar("sm_l4dstats_infected", "1", "Base score for killing a Common Infected", FCVAR_PLUGIN, true, 1.0);
    cvar_Hunter = CreateConVar("sm_l4dstats_hunter", "2", "Base score for killing a Hunter", FCVAR_PLUGIN, true, 1.0);
    cvar_Smoker = CreateConVar("sm_l4dstats_smoker", "3", "Base score for killing a Smoker", FCVAR_PLUGIN, true, 1.0);
    cvar_Boomer = CreateConVar("sm_l4dstats_boomer", "5", "Base score for killing a Boomer", FCVAR_PLUGIN, true, 1.0);

    // Misc personal gain Cvars
    cvar_Pills = CreateConVar("sm_l4dstats_pills", "15", "Base score for giving Pills to a friendly", FCVAR_PLUGIN, true, 1.0);
    cvar_Medkit = CreateConVar("sm_l4dstats_medkit", "20", "Base score for using a Medkit on a friendly", FCVAR_PLUGIN, true, 1.0);
    cvar_SmokerDrag = CreateConVar("sm_l4dstats_smokerdrag", "5", "Base score for saving a friendly from a Smoker Tongue Drag", FCVAR_PLUGIN, true, 1.0);
    cvar_ChokePounce = CreateConVar("sm_l4dstats_chokepounce", "10", "Base score for saving a friendly from a Hunter Pounce / Smoker Choke", FCVAR_PLUGIN, true, 1.0);
    cvar_Revive = CreateConVar("sm_l4dstats_revive", "15", "Base score for Revive a friendly from Incapacitated state", FCVAR_PLUGIN, true, 1.0);
    cvar_Rescue = CreateConVar("sm_l4dstats_rescue", "10", "Base score for Rescue a friendly from a closet", FCVAR_PLUGIN, true, 1.0);
    cvar_Protect = CreateConVar("sm_l4dstats_protect", "3", "Base score for Protect a friendly in combat", FCVAR_PLUGIN, true, 1.0);

    // Team gain Cvars
    cvar_Tank = CreateConVar("sm_l4dstats_tank", "25", "Base team score for killing a Tank", FCVAR_PLUGIN, true, 1.0);
    cvar_Panic = CreateConVar("sm_l4dstats_panic", "25", "Base team score for surviving a Panic Event with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
    cvar_BoomerMob = CreateConVar("sm_l4dstats_boomermob", "10", "Base team score for surviving a Boomer Mob with no Incapacitations", FCVAR_PLUGIN, true, 1.0);
    cvar_SafeHouse = CreateConVar("sm_l4dstats_safehouse", "10", "Base score for reaching a Safe House", FCVAR_PLUGIN, true, 1.0);
    cvar_Witch = CreateConVar("sm_l4dstats_witch", "10", "Base score for Not Disturbing a Witch", FCVAR_PLUGIN, true, 1.0);
    cvar_Campaign = CreateConVar("sm_l4dstats_campaign", "5", "Base score for Completing a Campaign", FCVAR_PLUGIN, true, 1.0);

    // Point loss Cvars
    cvar_FFire = CreateConVar("sm_l4dstats_ffire", "25", "Base score for Friendly Fire", FCVAR_PLUGIN, true, 1.0);
    cvar_FIncap = CreateConVar("sm_l4dstats_fincap", "75", "Base score for a Friendly Incap", FCVAR_PLUGIN, true, 1.0);
    cvar_FKill = CreateConVar("sm_l4dstats_fkill", "250", "Base score for a Friendly Kill", FCVAR_PLUGIN, true, 1.0);
    cvar_InSafeRoom = CreateConVar("sm_l4dstats_insaferoom", "5", "Base score for letting Infected in the Safe Room", FCVAR_PLUGIN, true, 1.0);
    cvar_Restart = CreateConVar("sm_l4dstats_restart", "100", "Base score for a Round Restart", FCVAR_PLUGIN, true, 1.0);

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

    if (IsClientBot(client))
        return;

    decl String:SteamID[MAX_LINE_WIDTH];
    GetClientAuthString(client, SteamID, sizeof(SteamID));

    CheckPlayerDB(client);

    TimerPoints[client] = 0;
    TimerKills[client] = 0;
    TimerHeadshots[client] = 0;

    SQL_TQuery(db, GetRankTotal, "SELECT COUNT(*) FROM players", client);

    decl String:query[256];
    Format(query, sizeof(query), "SELECT points FROM players WHERE steamid = '%s'", SteamID);
    SQL_TQuery(db, GetClientPoints, query, client);

    CreateTimer(10.0, RankConnect, client);
}

// Show rank on connect.

public Action:RankConnect(Handle:timer, any:value)
{
    if (GetConVarBool(cvar_RankOnJoin))
        cmd_ShowRank(value, 0);
}

// Update the player's interstitial stats, since they may have
// gotten points between the last update and when they disconnect.

public OnClientDisconnect(client)
{
    if (IsClientBot(client))
        return;

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

// Make connection to database.

public ConnectDB()
{
    if (SQL_CheckConfig("l4dstats"))
    {
        new String:Error[256];
        db = SQL_Connect("l4dstats", true, Error, sizeof(Error));

        if (db == INVALID_HANDLE)
            LogError("Failed to connect to database: %s", Error);
        else
            SendSQLUpdate("SET NAMES 'utf8'");
    }
    else
        LogError("Database.cfg missing 'l4dstats' entry!");
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
            Format(query, sizeof(query), "SELECT points FROM players WHERE steamid = '%s'", SteamID);
            SQL_TQuery(db, GetClientPoints, query, i);

            TimerPoints[i] = 0;
            TimerKills[i] = 0;
        }
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

public SendSQLUpdate(String:query[])
{
    if (db == INVALID_HANDLE)
        return;

    SQL_TQuery(db, SQLErrorCheckCallback, query);
}

// Report error on sql query;

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (db == INVALID_HANDLE)
        return;

    if(!StrEqual("", error))
        LogError("SQL Error: %s", error);
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

    decl String:query[512];
    Format(query, sizeof(query), "UPDATE players SET lastontime = UNIX_TIMESTAMP(), playtime = playtime + 1, name = '%s' WHERE steamid = '%s'", Name, SteamID);
    SendSQLUpdate(query);
}

// Perform a map stat update.
public UpdateMapStat(String:Field[MAX_LINE_WIDTH], Score)
{
    if (!Score)
        Score = 1;

    decl String:MapName[64];
    GetCurrentMap(MapName, sizeof(MapName));

    decl String:DiffSQL[MAX_LINE_WIDTH];
    decl String:Difficulty[MAX_LINE_WIDTH];
    GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

    if (StrEqual(Difficulty, "Normal")) Format(DiffSQL, sizeof(DiffSQL), "nor");
    else if (StrEqual(Difficulty, "Hard")) Format(DiffSQL, sizeof(DiffSQL), "adv");
    else if (StrEqual(Difficulty, "Impossible")) Format(DiffSQL, sizeof(DiffSQL), "exp");
    else return;

    decl String:FieldSQL[MAX_LINE_WIDTH];
    Format(FieldSQL, sizeof(FieldSQL), "%s_%s", Field, DiffSQL);

    decl String:query[512];
    Format(query, sizeof(query), "UPDATE maps SET %s = %s + %i WHERE name = '%s'", FieldSQL, FieldSQL, Score, MapName);
    SendSQLUpdate(query);
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

            if (TimerKills[i] > 0)
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

    new len = 0;
    decl String:query[1024];
    len += Format(query[len], sizeof(query)-len, "UPDATE players SET points = points + %i, ", TimerPoints[client]);
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
    if (StatsDisabled())
        return;

    new Mode = GetConVarInt(cvar_AnnounceMode);
    new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (GetEventBool(event, "attackerisbot") || !GetEventBool(event, "victimisbot"))
        return;

    decl String:AttackerID[MAX_LINE_WIDTH];
    GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
    decl String:AttackerName[MAX_LINE_WIDTH];
    GetClientName(Attacker, AttackerName, sizeof(AttackerName));

    decl String:VictimName[MAX_LINE_WIDTH];
    GetEventString(event, "victimname", VictimName, sizeof(VictimName));

    new Score = 0;
    decl String:InfectedType[8];

    if (StrEqual(VictimName, "Hunter"))
    {
        Format(InfectedType, sizeof(InfectedType), "hunter");
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_Hunter), 2, 3);
    }
    else if (StrEqual(VictimName, "Smoker"))
    {
        Format(InfectedType, sizeof(InfectedType), "smoker");
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_Smoker), 2, 3);
    }
    else if (StrEqual(VictimName, "Boomer"))
    {
        Format(InfectedType, sizeof(InfectedType), "boomer");
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_Boomer), 2, 3);
    }
    else
        return;

    new String:Headshot[32];
    if (GetEventBool(event, "headshot"))
    {
        Format(Headshot, sizeof(Headshot), ", headshots = headshots + 1");
        Score = Score + 2;
    }

    new len = 0;
    decl String:query[1024];
    len += Format(query[len], sizeof(query)-len, "UPDATE players SET points = points + %i, ", Score);
    len += Format(query[len], sizeof(query)-len, "kills = kills + 1, kill_%s = kill_%s + 1", InfectedType, InfectedType);
    len += Format(query[len], sizeof(query)-len, "%s WHERE steamid = '%s'", Headshot, AttackerID);
    SendSQLUpdate(query);

    if (Mode)
    {
        if (GetEventBool(event, "headshot"))
        {
            if (Mode > 1)
                PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for killing a \x05%s \x01with a \x04HEAD SHOT!", AttackerName, Score, VictimName);
            else
                PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for killing a \x05%s \x01with a \x04HEAD SHOT!", Score, VictimName);
        }
        else
        {
            if (Mode > 2)
                PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for killing a \x05%s!", AttackerName, Score, VictimName);
            else
                PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for killing a \x05%s!", Score, VictimName);
        }
    }

    UpdateMapStat("kills", 1);
    UpdateMapStat("points", Score);
    CurrentPoints[Attacker] = CurrentPoints[Attacker] + Score;
}

// Common Infected death code. +1 on headshot.

public Action:event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if (!Attacker || IsClientBot(Attacker))
        return;

    decl String:AttackerID[MAX_LINE_WIDTH];
    GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
    decl String:AttackerName[MAX_LINE_WIDTH];
    GetClientName(Attacker, AttackerName, sizeof(AttackerName));

    new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Infected), 2, 3);

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
    if (StatsDisabled())
        return;

    if (CampaignOver)
        return;

    if (TankCount >= 3)
        return;

    new Mode = GetConVarInt(cvar_AnnounceMode);
    new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Tank), 2, 4);

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

    decl String:iID[MAX_LINE_WIDTH];
    decl String:query[512];

    for (new i = 1; i <= maxplayers; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
        {
            GetClientAuthString(i, iID, sizeof(iID));
            Format(query, sizeof(query), "UPDATE players SET points = points + %i, award_tankkill = award_tankkill + 1 WHERE steamid = '%s'", Score, iID);
            SendSQLUpdate(query);

            CurrentPoints[i] = CurrentPoints[i] + Score;
        }
    }

    if (Mode)
        PrintToChatAll("\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for killing a Tank with \x05%i Deaths!", Score, Deaths);

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

    decl String:query[1024];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i, award_pills = award_pills + 1 WHERE steamid = '%s'", Score, GiverID);
    SendSQLUpdate(query);

    UpdateMapStat("points", Score);
    CurrentPoints[Giver] = CurrentPoints[Giver] + Score;

    if (Mode == 1 || Mode == 2)
        PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for giving pills to \x05%s!", Score, RecepientName);
    else if (Mode == 3)
        PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for giving pills to \x05%s!", GiverName, Score, RecepientName);
}

// Medkit give code.

public Action:event_HealPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new Recepient = GetClientOfUserId(GetEventInt(event, "subject"));
    new Giver = GetClientOfUserId(GetEventInt(event, "userid"));
    new Amount = GetEventInt(event, "health_restored");
    new Mode = GetConVarInt(cvar_AnnounceMode);

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

    decl String:query[1024];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i, award_medkit = award_medkit + 1 WHERE steamid = '%s'", Score, GiverID);
    SendSQLUpdate(query);

    UpdateMapStat("points", Score);
    CurrentPoints[Giver] = CurrentPoints[Giver] + Score;

    if (Mode == 1 || Mode == 2)
        PrintToChat(Giver, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for healing \x05%s!", Score, RecepientName);
    else if (Mode == 3)
        PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for healing \x05%s!", GiverName, Score, RecepientName);
}

// Friendly fire code.

public Action:event_FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
    new Mode = GetConVarInt(cvar_AnnounceMode);

    if (!Attacker || !Victim)
        return;

    if (IsClientBot(Victim))
        return;

    decl String:AttackerName[MAX_LINE_WIDTH];
    GetClientName(Attacker, AttackerName, sizeof(AttackerName));
    decl String:AttackerID[MAX_LINE_WIDTH];
    GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
    
    decl String:VictimName[MAX_LINE_WIDTH];
    GetClientName(Victim, VictimName, sizeof(VictimName));

    new Score = ModifyScoreDifficulty(GetConVarInt(cvar_FFire), 2, 4);
    Score = Score * -1;

    decl String:query[1024];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", Score, AttackerID);
    SendSQLUpdate(query);

    if (Mode == 1 || Mode == 2)
        PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s!", Score, VictimName);
    else if (Mode == 3)
        PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s!", AttackerName, Score, VictimName);
}

// Campaign win code. Points are based on maps completed + survivors.

public Action:event_CampaignWin(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    CampaignOver = true;
    new Mode = GetConVarInt(cvar_AnnounceMode);

    new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Campaign), 4, 12);
    new SurvivorCount = GetEventInt(event, "survivorcount");
    new BaseScore = Score * SurvivorCount;
    
    decl String:query[1024];
    decl String:iID[MAX_LINE_WIDTH];
    decl String:Name[MAX_LINE_WIDTH];
    decl String:cookie[MAX_LINE_WIDTH];
    new Maps = 0;
    new WinScore = 0;

    new maxplayers = GetMaxClients();
    for (new i = 1; i <= maxplayers; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
        {
            GetClientAuthString(i, iID, sizeof(iID));

            GetClientCookie(i, Handle:ClientMaps, cookie, 32);
            Maps = StringToInt(cookie) + 1;

            if (Maps > 5)
                Maps = 5;

            WinScore = BaseScore * Maps;

            if (Mode == 1 || Mode == 2)
            {
                PrintToChat(i, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for completing Campaign (%i / 5) with \x05%i survivors!", WinScore, Maps, SurvivorCount);
            }
            else if (Mode == 3)
            {
                GetClientName(i, Name, sizeof(Name));
                PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for completing Campaign (%i / 5) with \x05%i survivors!", Name, WinScore, Maps, SurvivorCount);
            }

            Format(query, sizeof(query), "UPDATE players SET points = points + %i, award_campaigns = award_campaigns + 1 WHERE steamid = '%s'", WinScore, iID);
            SendSQLUpdate(query);

            SetClientCookie(i, ClientMaps, "0");
            UpdateMapStat("points", WinScore);
            CurrentPoints[i] = CurrentPoints[i] + WinScore;
        }
    }
}

// Safe House reached code. Points are given to all players.
// Also, Witch Not Disturbed code, points also given to all players.

public Action:event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new Mode = GetConVarInt(cvar_AnnounceMode);

    decl String:iID[MAX_LINE_WIDTH];
    decl String:query[1024];
    new maxplayers = GetMaxClients();
    new Score = ModifyScoreDifficulty(GetConVarInt(cvar_Witch), 5, 10);

    if (WitchExists && !WitchDisturb)
    {
        for (new i = 1; i <= maxplayers; i++)
        {
            if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
            {
                GetClientAuthString(i, iID, sizeof(iID));
                Format(query, sizeof(query), "UPDATE players SET points = points + %i WHERE steamid = '%s'", Score, iID);
                SendSQLUpdate(query);
                UpdateMapStat("points", Score);
                CurrentPoints[i] = CurrentPoints[i] + Score;
            }
        }

        if (Mode)
            PrintToChatAll("\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05Not Disturbing A Witch!", Score);
    }

    Score = 0;
    new Deaths = 0;
    new BaseScore = ModifyScoreDifficulty(GetConVarInt(cvar_SafeHouse), 2, 5);
    
    for (new i = 1; i <= maxplayers; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
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
        if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
        {
            InterstitialPlayerUpdate(i);

            GetClientCookie(i, Handle:ClientMaps, cookie, 32);
            Maps = StringToInt(cookie) + 1;
            IntToString(Maps, cookie, sizeof(cookie));
            SetClientCookie(i, ClientMaps, cookie);

            GetClientAuthString(i, iID, sizeof(iID));
            Format(query, sizeof(query), "UPDATE players SET points = points + %i%s WHERE steamid = '%s'", Score, All4Safe, iID);
            SendSQLUpdate(query);
            UpdateMapStat("points", Score);
            CurrentPoints[i] = CurrentPoints[i] + Score;
        }
    }

    if (Mode)
        PrintToChatAll("\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for reaching a Safe House with \x05%i Deaths!", Score, Deaths);

    PlayerVomited = false;
    PanicEvent = false;
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

        decl String:query[1024];
        decl String:iID[MAX_LINE_WIDTH];

        new maxplayers = GetMaxClients();
        for (new i = 1; i <= maxplayers; i++)
        {
            if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
            {
                GetClientAuthString(i, iID, sizeof(iID));
                Format(query, sizeof(query), "UPDATE players SET points = points + %i WHERE steamid = '%s' ", Score, iID);
                SendSQLUpdate(query);
                UpdateMapStat("points", Score);
                CurrentPoints[i] = CurrentPoints[i] + Score;
            }
        }

        if (Mode)
            PrintToChatAll("\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05No Incapicitates After Panic Event!", Score);
    }

    PanicEvent = false;
    PanicEventIncap = false;
}

// Begin Boomer blind.

public Action:event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    if (CampaignOver || PlayerVomited)
        return;

    PlayerVomited = true;
}

// Boomer Mob Survival with no Incaps code. Points are given to all players.

public Action:event_PlayerBlindEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new Mode = GetConVarInt(cvar_AnnounceMode);

    if (PlayerVomited && !PlayerVomitedIncap)
    {
        new Score = ModifyScoreDifficulty(GetConVarInt(cvar_BoomerMob), 2, 5);

        decl String:query[1024];
        decl String:iID[MAX_LINE_WIDTH];

        new maxplayers = GetMaxClients();
        for (new i = 1; i <= maxplayers; i++)
        {
            if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
            {
                GetClientAuthString(i, iID, sizeof(iID));
                Format(query, sizeof(query), "UPDATE players SET points = points + %i WHERE steamid = '%s' ", Score, iID);
                SendSQLUpdate(query);
                UpdateMapStat("points", Score);
                CurrentPoints[i] = CurrentPoints[i] + Score;
            }
        }

        if (Mode)
            PrintToChatAll("\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05No Incapicitates After Boomer Mob!", Score);
    }

    PlayerVomited = false;
    PlayerVomitedIncap = false;
}

// Friendly Incapicitate code. Also handles if players should be awarded
// points for surviving a Panic Event or Boomer Mob without incaps.

public Action:event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new Mode = GetConVarInt(cvar_AnnounceMode);

    if (PanicEvent)
        PanicEventIncap = true;

    if (PlayerVomited)
        PlayerVomitedIncap = true;

    if (!Attacker)
        return;

    if (IsClientBot(Attacker) || IsClientBot(Victim))
        return;

    decl String:AttackerID[MAX_LINE_WIDTH];
    GetClientAuthString(Attacker, AttackerID, sizeof(AttackerID));
    decl String:AttackerName[MAX_LINE_WIDTH];
    GetClientName(Attacker, AttackerName, sizeof(AttackerName));

    decl String:VictimName[MAX_LINE_WIDTH];
    GetClientName(Victim, VictimName, sizeof(VictimName));

    new Score = ModifyScoreDifficulty(GetConVarInt(cvar_FIncap), 2, 4);
    Score = Score * -1;

    decl String:query[512];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i WHERE steamid = '%s'", Score, AttackerID);
    SendSQLUpdate(query);

    if (Mode == 1 || Mode == 2)
        PrintToChat(Attacker, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for \x03Incapicitating \x05%s!", Score, VictimName);
    else if (Mode == 3)
        PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for \x03Incapicitating \x05%s!", AttackerName, Score, VictimName);
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

    HunterSmokerSave(GetEventInt(event, "userid"), GetEventInt(event, "victim"), GetConVarInt(cvar_ChokePounce), 2, 3, "Hunter", "award_hunter");
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

    decl String:query[1024];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i, award_revive = award_revive + 1 WHERE steamid = '%s'", Score, SaviorID);
    SendSQLUpdate(query);

    UpdateMapStat("points", Score);
    CurrentPoints[Savior] = CurrentPoints[Savior] + Score;

    if (Mode == 1 || Mode == 2)
        PrintToChat(Savior, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Reviving \x05%s!", Score, VictimName);
    else if (Mode == 3)
        PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Reviving \x05%s!", SaviorName, Score, VictimName);
}

// Miscellaneous events and awards. See specific award for info.

public Action:event_Award(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (StatsDisabled())
        return;

    new PlayerID = GetEventInt(event, "userid");
    new SubjectID = GetEventInt(event, "subjectentid");
    new Mode = GetConVarInt(cvar_AnnounceMode);

    if (!PlayerID)
        return;
        
    new User = GetClientOfUserId(PlayerID);

    decl String:UserID[MAX_LINE_WIDTH];
    GetClientAuthString(User, UserID, sizeof(UserID));
    decl String:UserName[MAX_LINE_WIDTH];
    GetClientName(User, UserName, sizeof(UserName));

    if (IsClientBot(User))
        return;

    new Recepient;
    decl String:RecepientName[MAX_LINE_WIDTH];

    new Score = 0;
    new String:AwardSQL[128];
    new AwardID = GetEventInt(event, "award");

    if (AwardID == 67) // Protect friendly
    {
        if (!SubjectID)
            return;

        Recepient = GetClientOfUserId(GetClientUserId(SubjectID));
        GetClientName(Recepient, RecepientName, sizeof(RecepientName));

        if (IsClientBot(Recepient))
            return;

        Format(AwardSQL, sizeof(AwardSQL), ", award_protect = award_protect + 1");
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_Protect), 2, 3);
        UpdateMapStat("points", Score);
        CurrentPoints[User] = CurrentPoints[User] + Score;

        if (Mode == 1 || Mode == 2)
            PrintToChat(User, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Protecting \x05%s!", Score, RecepientName);
        else if (Mode == 3)
            PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Protecting \x05%s!", UserName, Score, RecepientName);
    }
    else if (AwardID == 79) // Respawn friendly
    {
        if (!SubjectID)
            return;

        Recepient = GetClientOfUserId(GetClientUserId(SubjectID));
        GetClientName(Recepient, RecepientName, sizeof(RecepientName));

        if (IsClientBot(Recepient))
            return;

        Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_Rescue), 2, 3);
        UpdateMapStat("points", Score);
        CurrentPoints[User] = CurrentPoints[User] + Score;

        if (Mode == 1 || Mode == 2)
            PrintToChat(User, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for Rescuing \x05%s!", Score, RecepientName);
        else if (Mode == 3)
            PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has earned \x04%i \x01points for Rescuing \x05%s!", UserName, Score, RecepientName);
    }
    else if (AwardID == 80) // Kill Tank with no deaths
    {
        Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
        Score = ModifyScoreDifficulty(0, 1, 1);
    }
    else if (AwardID == 83) // Team kill
    {
        if (!SubjectID)
            return;

        Recepient = GetClientOfUserId(GetClientUserId(SubjectID));

        if (IsClientBot(Recepient))
            return;

        Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_FKill), 2, 4);
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
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_InSafeRoom), 2, 4);
        Score = Score * -1;

        if (Mode == 1 || Mode == 2)
            PrintToChat(User, "\x04[\x03RANK\x04] \x01You have \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", Score);
        else if (Mode == 3)
            PrintToChatAll("\x04[\x03RANK\x04] \x05%s \x01has \x03LOST \x04%i \x01points for letting \x03Infected In The Safe Room!", UserName, Score);
    }
    else if (AwardID == 98) // Round restart
    {
        Score = ModifyScoreDifficulty(GetConVarInt(cvar_Restart), 2, 3);
        Score = (400 - Score) * -1;
        UpdateMapStat("restarts", 1);

        if (Mode)
            PrintToChat(User, "\x04[\x03RANK\x04] \x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying!", Score);
    }
    else
        return;

    decl String:query[1024];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i%s WHERE steamid = '%s'", Score, AwardSQL, UserID);
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

    Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE points >=%i", ClientPoints[client]);
    SQL_TQuery(db, GetClientRank, query, client);

    Format(query, sizeof(query), "SELECT name, playtime, points, kills, headshots FROM players WHERE steamid = '%s'", SteamID);
    SQL_TQuery(db, DisplayRank, query, client);

    return Plugin_Handled;
}

// Generate client's point total.
public GetClientPoints(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = data;

    if (!client || hndl == INVALID_HANDLE)
        return;

    while (SQL_FetchRow(hndl))
        ClientPoints[client] = SQL_FetchInt(hndl, 0);
}

// Generate client's rank.
public GetClientRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = data;

    if (!client || hndl == INVALID_HANDLE)
        return;

    while (SQL_FetchRow(hndl))
        ClientRank[client] = SQL_FetchInt(hndl, 0);
}

// Generate total rank amount.
public GetRankTotal(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
        return;

    while (SQL_FetchRow(hndl))
        RankTotal = SQL_FetchInt(hndl, 0);
}

// Send the RANK panel to the client's display.
public DisplayRank(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client = data;

    if (!client || hndl == INVALID_HANDLE)
        return;

    new Playtime, Points, Kills, Headshots;
    new String:Name[32];

    while (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, Name, sizeof(Name));
        Playtime = SQL_FetchInt(hndl, 1);
        Points = SQL_FetchInt(hndl, 2);
        Kills = SQL_FetchInt(hndl, 3);
        Headshots = SQL_FetchInt(hndl, 4);
    }

    new Handle:RankPanel = CreatePanel();
    new String:Value[MAX_LINE_WIDTH];
    new String:URL[MAX_LINE_WIDTH];

    GetConVarString(cvar_SiteURL, URL, sizeof(URL));
    new Float:HeadshotRatio = Headshots == 0 ? 0.00 : FloatDiv(float(Headshots), float(Kills))*100;

    Format(Value, sizeof(Value), "Ranking of %s" , Name);
    SetPanelTitle(RankPanel, Value);

    Format(Value, sizeof(Value), "Rank: %i of %i" , ClientRank[client], RankTotal);
    DrawPanelText(RankPanel, Value);

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

    Format(Value, sizeof(Value), "Kills: %i" , Kills);
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

    Format(query, sizeof(query), "SELECT name FROM players ORDER BY points DESC LIMIT 10");
    SQL_TQuery(db, DisplayTop10, query, client);

    return Plugin_Handled;
}

// Find a player from Top 10 ranking.
public GetClientFromTop10(client, rank)
{
    decl String:query[256];
    Format(query, sizeof(query), "SELECT points, steamid FROM players ORDER BY points DESC LIMIT %i,1", rank);
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
        Format(query, sizeof(query), "SELECT COUNT(*) FROM players WHERE points >=%i", SQL_FetchInt(hndl, 0));
        SQL_TQuery(db, GetClientRank, query, client);

        SQL_FetchString(hndl, 1, SteamID, sizeof(SteamID));
        Format(query, sizeof(query), "SELECT name, playtime, points, kills, headshots FROM players WHERE steamid = '%s'", SteamID);
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

    decl String:query[1024];
    Format(query, sizeof(query), "UPDATE players SET points = points + %i, %s = %s + 1 WHERE steamid = '%s'", Score, SQLField, SQLField, SaviorID);
    SendSQLUpdate(query);

    PrintToChat(Savior, "\x04[\x03RANK\x04] \x01You have earned \x04%i \x01points for saving \x05%s\x01 from a \x04%s!", Score, VictimName, SaveFrom);
    UpdateMapStat("points", Score);
    CurrentPoints[Savior] = CurrentPoints[Savior] + Score;
}

IsClientBot(client)
{
    decl String:SteamID[MAX_LINE_WIDTH];
    GetClientAuthString(client, SteamID, sizeof(SteamID));

    if (StrEqual(SteamID, "BOT"))
        return true;

    return false;
}

ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult)
{
    decl String:Difficulty[MAX_LINE_WIDTH];
    GetConVarString(cvar_Difficulty, Difficulty, sizeof(Difficulty));

    if (StrEqual(Difficulty, "Hard")) BaseScore = BaseScore * AdvMult;
    if (StrEqual(Difficulty, "Impossible")) BaseScore = BaseScore * ExpMult;

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
    else if (StrContains(CurrentMode, "versus", false) != -1)
        return true;

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

ResetVars()
{
    PlayerVomited = false;
    PlayerVomitedIncap = false;
    PanicEvent = false;
    PanicEventIncap = false;
    CampaignOver = false;
    WitchExists = false;
    WitchDisturb = false;

    // Reset kill/point score timer amount
    CreateTimer(1.0, InitPlayers);

    TankCount = 0;

    new maxplayers = GetMaxClients();
    for (new i = 1; i <= maxplayers; i++)
    {
        CurrentPoints[i] = 0;
    }
}

StatsDisabled()
{
    if (InvalidGameMode())
        return true;

    if (IsDifficultyEasy())
        return true;

    if (CheckHumans())
        return true;

    if (GetConVarBool(cvar_Cheats))
        return true;

    if (db == INVALID_HANDLE)
        return true;

    return false;
}
