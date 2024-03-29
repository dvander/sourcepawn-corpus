/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include "sodstats\include\sodstats.inc"

#define SODSTATS_VERSION "1.0.11"

#define MAX_STEAMID_LENGTH     128
#define MAX_WEAPON_NAME_LENGTH 32

new String:g_sql_saveplayer[]   = 
	"UPDATE players SET score = %i, kills = %i, deaths = %i, shots = %i, hits = %i, name = '%s', time_played = time_played + %i, headshots = %i, last_connect = current_timestamp WHERE steamid = '%s'";

new String:g_sql_createplayer[] = 
	"INSERT INTO players (score, kills, deaths, shots, hits, steamid, name, time_played, headshots, last_connect) VALUES (0, 0, 0, 0, 0, '%s', '%s', 0, 0, current_timestamp)";

new String:g_sqlite_createtable_players[] = 
	"CREATE TABLE IF NOT EXISTS players (rank INTEGER PRIMARY KEY AUTOINCREMENT,score int(12) NOT NULL default 0,steamid varchar(255) NOT NULL default '',kills int(12) NOT NULL default 0,deaths int(12) NOT NULL default 0,shots int(12) NOT NULL default 0,hits int(12) NOT NULL default 0,name varchar(255) NOT NULL default '',time_played int(11) NOT NULL default 0, headshots int(12) NOT NULL default 0, last_connect timestamp NOT NULL default CURRENT_TIMESTAMP);";
	
new String:g_mysql_createtable_players[] = 
	"CREATE TABLE IF NOT EXISTS players (rank INTEGER PRIMARY KEY AUTO_INCREMENT,score int(12) NOT NULL default 0,steamid varchar(255) NOT NULL default '',kills int(12) NOT NULL default 0,deaths int(12) NOT NULL default 0,shots int(12) NOT NULL default 0,hits int(12) NOT NULL default 0,name varchar(255) NOT NULL default '',time_played int(11) NOT NULL default 0, headshots int(12) NOT NULL default 0, last_connect timestamp NOT NULL default CURRENT_TIMESTAMP);";

new String:g_sql_droptable_players[] = 
	"DROP TABLE IF EXISTS 'players'; VACUUM;";

new String:g_sql_playercount[] = 
	"SELECT * FROM players";
	
new String:g_sql_addheadshots[] = 
	"ALTER TABLE players ADD COLUMN headshots int(12) NOT NULL default 0";

new String:g_sql_addtimestamp[] = 
	"ALTER TABLE players ADD COLUMN last_connect timestamp DEFAULT NULL;";

	
new String:g_name[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:g_steamid[MAXPLAYERS+1][MAX_STEAMID_LENGTH];

new g_start_points = 1000;

#define IDENT_SIZE 16
new String:g_ident[IDENT_SIZE];

#define DBTYPE_MYSQL 1
#define DBTYPE_SQLITE 2
new g_dbtype;

new g_kills[MAXPLAYERS+1];
new g_deaths[MAXPLAYERS+1];
new g_shots[MAXPLAYERS+1];
new g_hits[MAXPLAYERS+1];
new g_score[MAXPLAYERS+1];
new g_time_joined[MAXPLAYERS+1];
new g_time_played[MAXPLAYERS+1];
new g_last_saved_time[MAXPLAYERS+1];
new g_headshots[MAXPLAYERS+1];

new g_session_kills[MAXPLAYERS+1];
new g_session_deaths[MAXPLAYERS+1];
new g_session_shots[MAXPLAYERS+1];
new g_session_hits[MAXPLAYERS+1];
new g_session_score[MAXPLAYERS+1];
new g_session_headshots[MAXPLAYERS+1];

new bool:g_initialized[MAXPLAYERS+1];

new g_player_count;
new g_gameid;

#define DISPLAYMODE_PUBLIC  0
#define DISPLAYMODE_PRIVATE 1
#define DISPLAYMODE_CHAT    2
new g_displaymode = DISPLAYMODE_PUBLIC;

new Handle:g_henabled;
new Handle:g_hversion;
new Handle:g_hstartpoints;
new Handle:g_hdisplaymode;
new g_enabled;

#include "sodstats\natives.sp"
#include "sodstats\css.sp"
#include "sodstats\tf2.sp"
#include "sodstats\dod.sp"
#include "sodstats\empires.sp"
#include "sodstats\defaultgame.sp"

#include "sodstats\commands\rank.sp"
#include "sodstats\commands\session.sp"
#include "sodstats\commands\statsme.sp"
#include "sodstats\commands\top.sp"

public Plugin:myinfo = 
{
	name = "SoDStats",
	author = "]SoD[ Frostbyte",
	description = "A simple stats and ranking system.",
	version = SODSTATS_VERSION,
	url = "http://www.sonsofdavid.net"
}

public OnPluginStart()
{
	decl String:error[256];
	stats_db = SQL_Connect("storage-local", false, error, sizeof(error));
	
	if(stats_db == INVALID_HANDLE)
	{
		LogError("[SoD-Rank] Unable to connect to database (%s)", error);
		return;
	}
	
	SQL_ReadDriver(stats_db, g_ident, IDENT_SIZE);
	if(strcmp(g_ident, "mysql", false) == 0)
	{
		g_dbtype = DBTYPE_MYSQL;
	}
	else if(strcmp(g_ident, "sqlite", false) == 0)
	{
		g_dbtype = DBTYPE_SQLITE;
	}
	else
	{
		LogError("[SoD-Rank] Invalid DB-Type");
		return;
	}
	
	SQL_LockDatabase(stats_db);
	
	if((g_dbtype == DBTYPE_MYSQL && !SQL_FastQuery(stats_db, g_mysql_createtable_players)) ||
	   (g_dbtype == DBTYPE_SQLITE && !SQL_FastQuery(stats_db, g_sqlite_createtable_players)))
	{
		LogError("[SoD-Rank] Could not create players table.");
		return;
	}
	
	if(!SQL_FastQuery(stats_db, g_sql_addheadshots))
	{
		//LogError("[SoD-Rank] Could not add headshots column.");
		//return;
	}
	
	if(!SQL_FastQuery(stats_db, g_sql_addtimestamp))
	{
		//LogError("[SoD-Rank] Could not add headshots column.");
		//return;
	}
	
	g_player_count = GetPlayerCount();
	SQL_UnlockDatabase(stats_db);
	
	g_gameid = GetGameId();
	
	if(!HookEvents(g_gameid))
	{
		LogError("[SoD-Rank] Unable to hook events.");
		return;
	}
	
	g_henabled = CreateConVar("sm_stats_enabled", "1", "Sets whether or not to record stats",FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hstartpoints = CreateConVar("sm_stats_startpoints", "1000", "Sets the starting points for a new player",FCVAR_NOTIFY, true, 0.0, true, 10000.0);
	g_hdisplaymode = CreateConVar("sm_stats_displaymode", "0", "Sets the stats output mode. (Public = 0, Private = 1, Chat = 2)",FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hversion = CreateConVar("sm_stats_version", SODSTATS_VERSION,"SoD Stats version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(g_henabled, EnabledCallback);
	HookConVarChange(g_hstartpoints, StartPointsCallback);
	HookConVarChange(g_hdisplaymode, DisplayModeCallback);
	g_enabled = GetConVarInt(g_henabled);
	g_start_points = GetConVarInt(g_hstartpoints);
	
	if(g_henabled == INVALID_HANDLE || g_hversion == INVALID_HANDLE)
	{
		LogError("[SoD-Rank] Could not create stats_enabled cvar.");
		return;
	}
	
	RegAdminCmd("sm_stats_reset", AdminCmd_ResetStats, ADMFLAG_CONFIG, "Resets player stats.");
	RegAdminCmd("sm_stats_purge", AdminCmd_Purge, ADMFLAG_CONFIG, "sm_stats_purge [days] - Purge players who haven't connected for [days] days.");
	RegConsoleCmd("say",      ConCmd_Say);
	RegConsoleCmd("say_team", ConCmd_Say);
	
	RegPluginLibrary("sodstats");
}

public OnClientDisconnect(userid)
{
	// Ignore bot disconnects
	if(g_initialized[userid] == true)
	{
		// Save the player stats
		SavePlayer(userid);
		// and uninitialize them
		g_initialized[userid] = false;
	}
}

public OnClientAuthorized(client, const String:steamid[])
{
	//new client = GetClientOfUserId(userid);
	// Don't load bot stats or initialize them
	if(!IsFakeClient(client))
	{
		Format(g_steamid[client], MAX_STEAMID_LENGTH, steamid);
		GetClientName(client, g_name[client], MAX_NAME_LENGTH);
		GetPlayerBySteamId(steamid, LoadPlayerCallback, client);
	}
}

public EnabledCallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(strcmp(newValue, "0") == 0)
		g_enabled = 0;
	else
		g_enabled = 1;
}

public StartPointsCallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_start_points = StringToInt(newValue);
}

public DisplayModeCallback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_displaymode = StringToInt(newValue);
}

public Action:ConCmd_Say(userid, args)
{
	if(!userid || g_enabled == 0)
		return Plugin_Continue;
	
	decl String:text[192];		// from rockthevote.sp
	if(!GetCmdArgString(text, sizeof(text)))
		return Plugin_Continue;
	
	new startidx = 0;
	
	// Strip quotes from argument
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if(strcmp(text[startidx], "resetrank", false) == 0 || strcmp(text[startidx], "!resetrank", false) == 0)
	{
	Reset_Rank(userid);
	}
		
	if(strcmp(text[startidx], "rank", false) == 0)
	{
		PrintRankToAll(userid);
	}
	else if(strcmp(text[startidx], "top", false) == 0 || 
			strcmp(text[startidx], "top10", false) == 0)
	{
		PrintTop(userid);
	}
	
	if(g_gameid != ID_EMPIRES)
	{
		if(strcmp(text[startidx], "statsme", false) == 0)
		{
			PrintStats(userid);
		}
		else if(strcmp(text[startidx], "session", false) == 0)
		{
			PrintSession(userid);
		}
	}
	
	return Plugin_Continue;
}

public LoadPlayerCallback(const String:name[], const String:steamid[], any:stats[], any:data, error)
{
	new client = data;
	
	g_session_deaths[client]    = 0;
	g_session_kills[client]     = 0;
	g_session_hits[client]      = 0;
	g_session_shots[client]     = 0;
	g_session_score[client]     = 0;
	g_session_headshots[client] = 0;
	
	g_time_joined[client] = GetTime();
	g_last_saved_time[client] = g_time_joined[client];
	
	if(error == ERROR_PLAYER_NOT_FOUND)
	{
		CreatePlayer(client, g_steamid[client]);
		return;
	}
	
	Format(g_name[client], MAX_NAME_LENGTH, name);
	g_kills[client]       = stats[STAT_KILLS];
	g_deaths[client]      = stats[STAT_DEATHS];
	g_shots[client]       = stats[STAT_SHOTS];
	g_hits[client]        = stats[STAT_HITS];
	g_score[client]       = stats[STAT_SCORE];
	g_time_played[client] = stats[STAT_TIME_PLAYED];
	g_headshots[client]   = stats[STAT_HEADSHOTS];
	
	g_initialized[client] = true;
}

public Action:AdminCmd_ResetStats(client, args)
{
	ResetStats();
	
	return Plugin_Handled;
}
public Action:AdminCmd_Purge(client, args)
{
	new argCount = GetCmdArgs();
	
	if(argCount != 1)
	{
		PrintToConsole(client, "SoD-Stats: Invalid number of arguments for command 'sm_stats_purge'");
		return Plugin_Handled;
	}
	
	decl String:svDays[192];
	if(!GetCmdArg(1, svDays, 192))
	{
		PrintToConsole(client, "SoD-Stats: Invalid arguments for sm_stats_purge.");
		return Plugin_Handled;
	}
	
	new days = StringToInt(svDays);
	if(days <= 0)
	{
		PrintToConsole(client, "SoD-Stats: Invalid number of days.");
		return Plugin_Handled;
	}

	decl String:query[128];
	
	
	switch(g_dbtype)
	{
		case DBTYPE_MYSQL: 
			Format(query, 128, "DELETE FROM players WHERE last_connect < current_timestamp - interval %i day;", days);
		case DBTYPE_SQLITE: 
			Format(query, 128, "DELETE FROM players WHERE last_connect < datetime('now', '-%i days');", days);
	}
	
	SQL_TQuery(stats_db, SQL_PurgeCallback, query, client);
	
	return Plugin_Handled;
}

public SQL_PurgeCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL_PurgeCallback: Invalid query (%s).", error);
	}
	else
	{
		PrintToConsole(data, "SoD-Stats: Purge successful");
	}
}

GetPlayerCount()
{
	new Handle:hquery = SQL_Query(stats_db, g_sql_playercount);
	if(hquery == INVALID_HANDLE)
	{
		LogError("[SoD-Stats] Error getting player count.");
		return 0;
	}
	new rows = SQL_GetRowCount(hquery);
	CloseHandle(hquery);
	
	return rows;
}

GetGameId()
{
	new String:fldr[64];
	
	GetGameFolderName(fldr, sizeof(fldr));
	
	if(strcmp(fldr, "tf") == 0)
	{
		return ID_TF2;
	}
	else if(strcmp(fldr, "cstrike") == 0)
	{
		return ID_CSS;
	}
	else if(strcmp(fldr, "dod") == 0)
	{
		return ID_DODS;
	}
	else if(strcmp(fldr, "FortressForever") == 0)
	{
		return ID_FORTRESSFOREVER;
	}
	else if(strcmp(fldr, DIR_EMPIRES) == 0)
	{
		return ID_EMPIRES;
	}
	return ID_DEFAULTGAME;
}

bool:HookEvents(gameid)
{
	switch(gameid)
	{
		case ID_CSS:
			HookEventsCSS();
		case ID_TF2: 
			HookEventsTF2();
		case ID_DODS: 
			HookEventsDOD();
		case ID_FORTRESSFOREVER: 
			HookEventsTF2();
		case ID_EMPIRES: 
			HookEventsEmpires();
		case ID_DEFAULTGAME: 
			HookEventsDefault();
		default: 
		{
			LogError("[SoD-Rank] Invalid gameid (%i).", g_gameid);
			return false;
		}
	}
	return true;
}

SavePlayer(const userid)
{
	if(stats_db == INVALID_HANDLE || g_enabled == 0)
		return false;
	
	new String:name[256];
	GetClientName(userid, name, sizeof(name));
	
	// Make SQL-safe
	ReplaceString(name, sizeof(name), "'", "");
	
	// save player here
	decl String:query[255];
	new time = GetTime();
	Format(query, sizeof(query), g_sql_saveplayer, g_score[userid], 
												   g_kills[userid],
												   g_deaths[userid], 
												   g_shots[userid], 
												   g_hits[userid], 
												   name, 
												   time - g_last_saved_time[userid], 
												   g_headshots[userid], 
												   g_steamid[userid]);
	g_last_saved_time[userid] = time;
	SQL_TQuery(stats_db, SQL_SavePlayerCallback, query);
	return 0;
}

Reset_Rank(const userid)
{
	new String:name[255];
	GetClientName(userid, name, sizeof(name));
	
	// Make SQL-safe
	ReplaceString(name, sizeof(name), "'", "");
	
	// resetrank
	g_kills[userid]       = 0;
	g_deaths[userid]      = 0;
	g_shots[userid]       = 0;
	g_hits[userid]        = 0;
	g_score[userid]       = 0;
	g_time_played[userid] = 0;
	g_headshots[userid]   = 0;

	PrintToChat(userid, "Votre rank a été réinitialisé %s", name);
	
	SavePlayer(userid);
	return 0;
}

public SQL_SavePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("[SoD-Rank] Error saving player (%s)", error);
}

CreatePlayer(const userid, const String:steamid[])
{
	decl String:query[255];
	new String:name[MAX_NAME_LENGTH];
	new String:safe_name[MAX_NAME_LENGTH];
	
	GetClientName(userid, name, sizeof(name));
	SQL_QuoteString(stats_db, name, safe_name, sizeof(safe_name));
	Format(query, sizeof(query), g_sql_createplayer, steamid, safe_name);

	SQL_TQuery(stats_db, SQL_CreatePlayerCallback, query, userid);
}

public SQL_CreatePlayerCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;
	
	if(hndl != INVALID_HANDLE)
	{
		if(IsClientConnected(client))  // fix
			GetClientName(client, g_name[client], MAX_NAME_LENGTH);
		
		g_kills[client]       = 0;
		g_deaths[client]      = 0;
		g_shots[client]       = 0;
		g_hits[client]        = 0;
		g_score[client]       = 0;
		g_time_played[client] = 0;
		g_headshots[client]   = 0;
	
		g_session_deaths[client]    = 0;
		g_session_kills[client]     = 0;
		g_session_hits[client]      = 0;
		g_session_shots[client]     = 0;
		g_session_score[client]     = 0;
		g_session_headshots[client] = 0;
		
		g_time_joined[client] = GetTime();
		g_initialized[client] = true;
		g_player_count++;
	}
	else
		LogError("[SoD-Stats] SQL_CreatePlayerCallback failure: %s", error);
}
