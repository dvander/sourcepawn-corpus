/*
* Player Time Tracker (c) 2009 Jonah Hirsch
* 
* This plugin lets you track how long specific people
* have played on any servers that you have this plugin installed on.
* It uses an SQL database to store the information.
* 
* sm_ptt_add <Client Name>: Adds a client to the database to be tracked
* sm_ptt_remove <Client Name>: Removes a client from the database. Will not be tracked anymore
* sm_ptt_gettime <Client Name>: Prints target's current time played (hh:mm:ss) into console. 
* sm_mytime: Prints your time into chat. (Alternatively, say "!mytime" or "/mytime")
* 
* 
* Installation:
* 1) Run this SQL command on your database:
* 
  CREATE TABLE `TimeTracker` (
  `name` varchar(64) NOT NULL,
  `steamid` varchar(64) NOT NULL,
  `TimePlayed` int(64) NOT NULL,
  `tracking`  tinyint(1) NOT NULL,
  UNIQUE KEY `steamid` (`steamid`)
)
* 
* 2) Download and place ptt.smx into your addons/sourcemod/plugins/ directory
* 
* 3) Download and place ptt.txt into your addons/sourcemod/data/ directory
*  
* 4) (Optional) Download ptt webui.zip, upload contents to webserver, change settings in ptt.mysql.inc.php
* 
* Cvars:
* - sm_ptt_default_action
* 		1=start tracking as soon as client is added (default)
*       0=do not start tracking as soon as client is added (sm_ptt_start needs to be called to begin tracking)
* 
* - sm_ptt_automatic
* 		1=automatically track all players who connect to the server
* 		0=do not track all players
* 
* - sm_ptt_enabled
* 		1=enable tracking server-wide
* 		0=disable tracking server-wide
* 
* - sm_ptt_refresh
* 	 	Time (in seconds) between data updates. (Min and Default: 5)
*
* - sm_ptt_database
* 		Database connection (in databases.cfg) to use. (Default: "default")
* 
* - sm_ptt_version
* 		Shows version number
* 
* - sm_ptt_team
*		Which players to track: 1=all, 2=only those on a team (no spectators/unassigned)
* 
* Changelog								
* ------------
* 2.3.5
*  - Added sm_ptt_team
*  - Fixed bug blocking tracking of bots
*  - Removed some redundant code
* 2.3.4
*  - Fixed error log spam
* 2.3.3
*  - Fixed bug related to Bots
* 2.3.2
*  - Added FCVAR_DONTRECORD to version cvar
* 2.3.1
* - Fixed another bug with sm_ptt_automatic not adding everyone
* 2.3
* - ptt.txt is no longer needed. Feel free to delete!
* - Fixed long standing issue with names with single quotes in them
* - Removed OnClientDisconnect added in 2.2 as it is no longer needed
* 2.2.1
* - Fixed a bug that broke sm_ptt_automatic
* 2.2
* - Times are no longer updated on disconnect
* - sm_ptt_refresh minimum changed to 1.0, maximum changed to 10.0
* - OnClientPostAdminCheck now OnClientAuthorized
* - Steam IDs are checked on map change to prevent SQL errors when sm_ptt_automatic is on.
* - Steam ID stored to a client is cleared when they disconnect to prevent bugs
* 2.1
* - Changed how times are updated using decaprime's suggestion (Occam's razor-esque solution!)
*  - When a player's time is updated, it adds updateinterval to his current time, instead of calulating that same number using too much logic (D'oh!)
* - When a player is added to the tracker, his current gametime is added.
* 2.0.5
* - Bug fixes
* 2.0.4
* - Auto config added
* 2.0.3
* - Added sm_ptt_table
* 2.0.2
* - Added sm_ptt_database
* 2.0.1
* - Fixed a MAJOR bug that I stupidly created
* 2.0
* - Changed how times are updated on intervals. Negative times should be a thing of the past (hopefully)!
* - Attemps to stop recording time for people who are timing out
* 1.7.5
*  - Some special characters in names will show up correctly now
*  - Names are now updated when times are updated
* 1.7.4
*  - Added another check to prevent corrupt times
* 1.7.3
*  - Userids are now stored in a data file, so in-place upgrades will not be a problem anymore.
* 1.7.2
*  - Changed logic for determining if cilent is connecting new, or if they are just changing maps
*  - Bug fixes
* 1.7.1
*  - Added logic to make sure that a client's time won't be updated on the update interval if they disconnected during the interval
* 1.7
*  - Fixed lag when updating times on interval by switching to threaed SQL queries (which took way too long! :P)
*  - Refresh time is now updated as soon as sm_ptt_refresh is changed
*  - Bug fixes
* 1.6.1
*  - Fixed bug where times would be overwritten if clients didn't disconnect gracefully		
* 1.6
*  - Added sm_ptt_refresh
*  - Times are now updated every x seconds, where x is the value of sm_ptt_refresh, as well as on disconnect. 
*  - SQL table updated. Plugin will warn you if you are missing the addition, and will not update times on the sm_ptt_refresh interval
* 1.5.3
*  - Renamed all cvars/commands from sm_track to sm_ptt
* 1.5.2
*  - Added sm_track_version convar
*  - Simple Web UI!
* 1.5.1
*  - Added responses to more admin commands
* 1.5
*  - Removed player_activate event handler, added OnClientAuthorized
*  - Added sm_track_enabled
*  - Added sm_mytime
*  - Bug fixes
*  - Changed plugin file name to ptt
* 1.4.1
*  - More bug fixes! :D		
* 1.4
*  - Added sm_track_automatic
*  - Bug fixes		
* 1.3.2
*  - Misc. bug fixes
* 1.3.1
*  - Fixed invalid client index error spamming error logs
*  - Removed time update on death
*  - Fixed default track action not working
* 1.3
*  - sm_track_add/delete now deals with creating and removing rows in the database ONLY
*  - sm_track_start/stop does not add/remove any rows, just enables or disables tracking on a player without
*    interfering with the recorded time
*  - added Cvar sm_track_default_action  
*  - Time is now updated on death and disconnect
* 1.2
*  - Fixed two errors being thrown too much
*  - Changed sm_track_add to sm_track_start
*  - Changed sm_track_remove to sm_track_delete
* 1.1									
*  - Fixed bug calculating seconds		
*  - Fixed formatting of time display	
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.3.5"
new Handle:sm_ptt_default_action = INVALID_HANDLE
new Handle:sm_ptt_automatic = INVALID_HANDLE
new Handle:sm_ptt_enabled = INVALID_HANDLE
new Handle:sm_ptt_refresh = INVALID_HANDLE
new Handle:sm_ptt_database = INVALID_HANDLE
new Handle:sm_ptt_table = INVALID_HANDLE
new Handle:sm_ptt_team = INVALID_HANDLE
new Handle:hDatabase = INVALID_HANDLE
new Handle:refreshTimer = INVALID_HANDLE

new TotalTime, tracking//, TimeStored
new String:getTimeT[128], String:findActiveT[128], String:queriesID[128], String:pttTable[128], String:pttDatabase[128]
new currClient

public Plugin:myinfo = 
{
	name = "Player Time Tracker",
	author = "Crazydog",
	description = "Tracks how long specefic players have played in any servers you have this installed on.",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}


public OnPluginStart(){
	CreateConVar("sm_ptt_version", PLUGIN_VERSION, "Player Time Tracker Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	RegAdminCmd("sm_ptt_add", Command_AddPlayer, ADMFLAG_BAN, "adds player to tracker")
	RegAdminCmd("sm_ptt_start", Command_StartTrack, ADMFLAG_BAN, "starts tracking player's time")
	RegAdminCmd("sm_ptt_stop", Command_StopTrack, ADMFLAG_BAN, "stops tracking player's time")
	RegAdminCmd("sm_ptt_delete", Command_RemovePlayer, ADMFLAG_BAN , "removes player from tracker")
	RegAdminCmd("sm_ptt_gettime", Command_GetTime, ADMFLAG_BAN, "gets the total time in your servers of the client")
	RegConsoleCmd("sm_mytime", Command_MyTime, "gets your time in the server if you are being tracked")
	sm_ptt_default_action = CreateConVar("sm_ptt_default_action", "1", "Start tracking as soon as client is added to database? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	sm_ptt_automatic = CreateConVar("sm_ptt_automatic", "0", "Track every player that ever connects to your server? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	sm_ptt_enabled = CreateConVar("sm_ptt_enabled", "1", "Enable Tracking? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	sm_ptt_refresh = CreateConVar("sm_ptt_refresh", "5", "Time (in seconds) between data updates", FCVAR_NOTIFY, true, 1.0, true, 10.0)
	sm_ptt_database = CreateConVar("sm_ptt_database", "default", "Database (in databases.cfg) to use. Defaut=\"default\"")
	sm_ptt_table = CreateConVar("sm_ptt_table", "TimeTracker", "Table in your SQL Database to use. Default=\"TimeTracker\"")
	sm_ptt_team = CreateConVar("sm_ptt_team", "1", "Which players to track: 1=all, 2=only those on a team (no spectators/unassigned)")
	GetConVarString(sm_ptt_table, pttTable, sizeof(pttTable))
	HookConVarChange(sm_ptt_refresh, RefreshChanged)
	LoadTranslations("common.phrases");
	new Float:interval = GetConVarFloat(sm_ptt_refresh);
	refreshTimer = CreateTimer(interval, UpdateTimes, _, TIMER_REPEAT)
	currClient = 1
	GetConVarString(sm_ptt_database, pttDatabase, sizeof(pttDatabase))
	SQL_TConnect(DBConnect, pttDatabase)
	AutoExecConfig(true, "plugin.ptt")
}



public Action:Command_AddPlayer(client, args){
	new String:arg1[128], String:name[128], String:steamid[128], String:error[128], String:query[128], String:escapedName[128]
	GetCmdArg(1, arg1, sizeof(arg1))
	new target = FindTarget(client, arg1, true)
	if (target == -1){
		return Plugin_Handled;
	}
	
	GetClientName(target, name, sizeof(name))
	GetClientAuthString(target, steamid, sizeof(steamid))
	
	new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
	if (db == INVALID_HANDLE){
		LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	
	SQL_EscapeString(db, name, escapedName, sizeof(escapedName))
	
	new String:utfquery[] = "SET NAMES 'utf8'"
	new Handle:utf
	if((utf = SQL_Query(db, utfquery)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Can't set encoding to UTF-8")
		return Plugin_Handled
	}
	CloseHandle(utf)
			
	new action = GetConVarInt(sm_ptt_default_action)
	Format(query, sizeof(query), "INSERT INTO %s VALUES ('%s', '%s', '%i', '%i')", pttTable, escapedName, steamid, RoundToFloor(GetClientTime(target)), action);

	
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Problem with the insert SQL query! (%s)", query);
		return Plugin_Handled;
	}
	else
	{
		LogAction(client, -1, "[PTT] Now tracking %s's time in game", name);
		CloseHandle(hQuery);
	}
	
	CloseHandle(db);
	ReplyToCommand(client, "[PTT] %s has been added to the Time Tracker", name)
	
	return Plugin_Handled;
}


public Action:Command_RemovePlayer(client, args){
	new String:arg1[128], String:name[128], String:steamid[128], String:error[128], String:query[128], thisclient
	thisclient = client
	GetCmdArg(1, arg1, sizeof(arg1))
	new target = FindTarget(client, arg1, true)
	if (target == -1){
		return Plugin_Handled;
	}
	
	GetClientName(target, name, sizeof(name))
	GetClientAuthString(target, steamid, sizeof(steamid))
	
	new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
	if (db == INVALID_HANDLE){
		LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
		CloseHandle(db);
		return Plugin_Handled;
	}
	
	Format(query, sizeof(query), "DELETE FROM %s WHERE steamid ='%s'", pttTable, steamid);
	
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Problem with delete the SQL query! (%s)", query);
		return Plugin_Handled;
	}
	else
	{
		LogAction(client, -1, "[PTT] %s is no longer being tracked", name);
		CloseHandle(hQuery);
	}
	
	CloseHandle(db);
	ReplyToCommand(thisclient, "[PTT] %s is no longer being tracked", name)
	
	return Plugin_Handled;
}


public Action:Command_GetTime(client, args){
	new String:arg1[128], String:name[128], String:steamid[128], String:error[128], String:query[128], String:getTime[128], time, bool:exists
	GetCmdArg(1, arg1, sizeof(arg1))
	new target = FindTarget(client, arg1, true)
	if (target == -1){
		return Plugin_Handled;
	}
	
	GetClientName(target, name, sizeof(name))
	GetClientAuthString(target, steamid, sizeof(steamid))
	
	new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
		
	if (db == INVALID_HANDLE){
		LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
		CloseHandle(db);
	}
	
	Format(getTime, sizeof(getTime), "SELECT TimePlayed FROM %s WHERE steamid = '%s'", pttTable, steamid)
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, getTime)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Problem with the SQL query! (%s)", query);
	}
	else
	{
		exists = SQL_FetchRow(hQuery)
		if (exists == true){
			time = SQL_FetchInt(hQuery, 0)
			LogAction(client, -1, "[PTT] Time grabbed for %s", name);
			CloseHandle(hQuery);
		}
	}
	
	new hours = time / 3600
	new remainder = time % 3600
	new minutes = remainder / 60
	new seconds = remainder % 60
	
	new String:hrpre[1], String:minpre[1], String:secpre[1]
	
	if (hours < 10){
		hrpre = "0"
	}else{
		hrpre = ""
	}
	
	if (minutes < 10){
		minpre = "0"
	}else{
		minpre = ""
	}
	
	if (seconds < 10){
		secpre = "0"
	}else{
		secpre = ""
	}
	
	if (exists){
		ReplyToCommand(client, "[PTT] %s has played for %s%d:%s%d:%s%d", name, hrpre, hours, minpre, minutes, secpre, seconds)
	}else{
		ReplyToCommand(client, "[PTT] %s is not being tracked.", name)
	}
	CloseHandle(db);
	return Plugin_Handled;
}

public Action:Command_StopTrack(client, args){
	new String:arg1[128], String:name[128], String:steamid[128], String:error[128], String:query[128], bool:exists, String:checkQuery[128]
	GetCmdArg(1, arg1, sizeof(arg1))
	new target = FindTarget(client, arg1, true)
	if (target == -1){
		return Plugin_Handled;
	}
	GetClientName(target, name, sizeof(name))
	GetClientAuthString(target, steamid, sizeof(steamid))
	
	new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
	if (db == INVALID_HANDLE){
		LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
		CloseHandle(db);
		return Plugin_Handled;
	}
	Format(checkQuery, sizeof(checkQuery), "SELECT * FROM %s WHERE steamid = '%s'", pttTable, steamid);
	Format(query, sizeof(query), "UPDATE %s SET tracking=0 WHERE steamid ='%s'", pttTable, steamid);
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, checkQuery)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Problem with the SQL query! (%s)", checkQuery);
		CloseHandle(hQuery);
		return Plugin_Handled;
	}else{
		exists = SQL_FetchRow(hQuery)
		CloseHandle(hQuery);
	}
	
	if (exists == true){
		new Handle:updateQuery;
		if ((updateQuery = SQL_Query(db, query)) == INVALID_HANDLE){
			LogError("[PTT] ERROR: Problem with the SQL query! (%s)", query);
			CloseHandle(updateQuery);
			return Plugin_Handled;
		}else{
			ReplyToCommand(client, "%s is no longer being tracked", name);
			CloseHandle(updateQuery);
		}
	}
	CloseHandle(db);
	return Plugin_Handled;
}

public Action:Command_StartTrack(client, args){
	new String:arg1[128], String:name[128], String:steamid[128], String:error[128], String:query[128], bool:exists, String:checkQuery[128]
	GetCmdArg(1, arg1, sizeof(arg1))
	new target = FindTarget(client, arg1, true)
	if (target == -1){
		return Plugin_Handled;
	}
	GetClientName(target, name, sizeof(name))
	GetClientAuthString(target, steamid, sizeof(steamid))

	new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
	if (db == INVALID_HANDLE){
		LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
		CloseHandle(db);
		return Plugin_Handled;
	}
	Format(checkQuery, sizeof(checkQuery), "SELECT * FROM %s WHERE steamid = '%s'", pttTable, steamid);
	Format(query, sizeof(query), "UPDATE %s SET tracking=1 WHERE steamid ='%s'", pttTable, steamid);
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, checkQuery)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Problem with the SQL query! (%s)", checkQuery);
		CloseHandle(hQuery);
		return Plugin_Handled;
	}else{
		exists = SQL_FetchRow(hQuery)
		CloseHandle(hQuery);
	}

	if (exists == true){
		new Handle:updateQuery;
		if ((updateQuery = SQL_Query(db, query)) == INVALID_HANDLE){
			LogError("[PTT] ERROR: Problem with the SQL query! (%s)", query);
			CloseHandle(updateQuery);
			return Plugin_Handled;
		}else{
			ReplyToCommand(client, "%s is now being tracked", name);
			CloseHandle(updateQuery);
		}
	}
	CloseHandle(db);
	return Plugin_Handled;
	}

public OnClientPostAdminCheck(client){
	new String:clientName[128], String:auth[128], String:error[128], String:query[128], String:checkQuery[128], String:escapedName[128]
	
	if (IsFakeClient(client)){
		return
	}
						
	new enabled = GetConVarInt(sm_ptt_enabled)
	if (enabled == 1){
		new addAll = GetConVarInt(sm_ptt_automatic)
		if (addAll == 1){
			if (IsFakeClient(client)){
				return;
			}
			GetClientName(client, clientName, sizeof(clientName))
			GetClientAuthString(client, auth, sizeof(auth))
			
			new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
			if (db == INVALID_HANDLE){
				LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
				CloseHandle(db);
			}
			
			SQL_EscapeString(db, clientName, escapedName, sizeof(escapedName))
			
			Format(checkQuery, sizeof(checkQuery), "SELECT * FROM %s WHERE steamid = '%s'", pttTable, auth);
			new Handle:hQuery2;
			if (SQL_GetRowCount((hQuery2 = SQL_Query(db, checkQuery))) != 0){
				CloseHandle(hQuery2);
				return
			}
			new String:utfquery[] = "SET NAMES 'utf8'"
			new Handle:utf
			if((utf = SQL_Query(db, utfquery)) == INVALID_HANDLE){
				LogError("[PTT] ERROR: Can't set encoding to UTF-8")
				return
			}
			CloseHandle(utf)
			
			new action = GetConVarInt(sm_ptt_default_action)
			Format(query, sizeof(query), "INSERT INTO %s VALUES ('%s', '%s', '%i', '%i')", pttTable, escapedName, auth, RoundToFloor(GetClientTime(client)), action);
			
			new Handle:hQuery;
			if ((hQuery = SQL_Query(db, query)) == INVALID_HANDLE){
				LogError("[PTT] ERROR: Problem with the insert SQL query! (%s)", query);
			}
			else
			{
				LogAction(client, -1, "[PTT] Now tracking %s's time in game", clientName);
				CloseHandle(hQuery);
			}		
			CloseHandle(db);
		}
	}
}

public Action:Command_MyTime(client, args){
	new target, String:arg1[128], String:name[128], String:steamid[128], String:error[128], String:query[128], String:getTime[128], time, bool:exists
	if (GetCmdArg(1, arg1, sizeof(arg1)) > 0){
		target = FindTarget(client, arg1, true)
	}else{
		target = client
	}
	if (target == -1){
		return Plugin_Handled;
	}
	
	GetClientName(target, name, sizeof(name))
	GetClientAuthString(target, steamid, sizeof(steamid))
	
	new Handle:db = SQL_Connect(pttDatabase, true, error, sizeof(error));
		
	if (db == INVALID_HANDLE){
		LogError("[PTT] ERROR: Could not connect to SQL database! (%s)", error);
		CloseHandle(db);
	}
	
	Format(getTime, sizeof(getTime), "SELECT TimePlayed FROM %s WHERE steamid = '%s'", pttTable, steamid)
	new Handle:hQuery;
	if ((hQuery = SQL_Query(db, getTime)) == INVALID_HANDLE){
		LogError("[PTT] ERROR: Problem with the SQL query! (%s)", query);
	}
	else
	{
		exists = SQL_FetchRow(hQuery)
		if (exists == true){
			time = SQL_FetchInt(hQuery, 0)
			LogAction(client, -1, "[PTT] Time grabbed for %s", name);
			CloseHandle(hQuery);
		}
	}
	

	new hours = time / 3600
	new remainder = time % 3600
	new minutes = remainder / 60
	new seconds = remainder % 60
	
	new String:hrpre[1], String:minpre[1], String:secpre[1]
	
	if (hours < 10){
		hrpre = "0"
	}else{
		hrpre = ""
	}
	
	if (minutes < 10){
		minpre = "0"
	}else{
		minpre = ""
	}
	
	if (seconds < 10){
		secpre = "0"
	}else{
		secpre = ""
	}
	
	if (exists == true){
		PrintToChat(client, "\x04[PTT]\x01 You have played for %s%d:%s%d:%s%d", hrpre, hours, minpre, minutes, secpre, seconds)
	}else{
		PrintToChat(client, "\x04[PTT]\x01 Your time is not being tracked.")
	}
	CloseHandle(db);
	return Plugin_Handled;
}
public Action:UpdateTimes(Handle:timer){
	currClient = 1
	tracking = 0
	new enabled = GetConVarInt(sm_ptt_enabled)
	if (enabled == 1){				
		Queries()
	}
	return Plugin_Continue;
}


public Queries(){
	tracking = 0
	new String:clientName[64]
	if (currClient > MaxClients || !IsClientInGame(currClient)){
		return
	}
	if (IsFakeClient(currClient)){
		currClient++
		Queries()
		return
	}
	new teamTrack = GetConVarInt(sm_ptt_team)
	if(teamTrack == 2){
		new team = GetClientTeam(currClient)
		if(team == 0 || team == 1){
			currClient++
			Queries()
			return
		}
	}
	if(currClient <= MaxClients && IsClientConnected(currClient) && IsClientInGame(currClient) && !IsClientTimingOut(currClient)){
		new client = currClient
		GetClientName(client, clientName, sizeof(clientName))
		GetClientAuthString(client, queriesID, sizeof(queriesID))
		
		Format(getTimeT, sizeof(getTimeT), "SELECT TimePlayed FROM %s WHERE steamid = '%s'", pttTable, queriesID)
	}else{
		currClient++
		Queries()
	}
}

public GetTheTime(Handle:owner, Handle:hQuery, const String:error[], any:client){
	if (hQuery != INVALID_HANDLE){
		if(SQL_GetRowCount(hQuery) > 0 && IsClientConnected(client)){
			SQL_FetchRow(hQuery)
			TotalTime = SQL_FetchInt(hQuery, 0)
			Format(findActiveT, sizeof(findActiveT), "SELECT tracking FROM %s WHERE steamid = '%s'", pttTable, queriesID)
			SQL_TQuery(hDatabase, FindActive, findActiveT, client)
		}else{
			currClient++
			Queries()
		}
		CloseHandle(hQuery)
	}
}

public FindActive(Handle:owner, Handle:hQuery, const String:error[], any:client){
	new newTime, String:escapedName[128]
	if (hQuery != INVALID_HANDLE){
		if(SQL_GetRowCount(hQuery) > 0 && IsClientConnected(client)){
			SQL_FetchRow(hQuery)
			tracking = SQL_FetchInt(hQuery, 0)
		}else{
			currClient++
			Queries()
		}
		if (tracking == 1){
			new String:query[256]
			newTime = TotalTime + GetConVarInt(sm_ptt_refresh)
			new String:clientName[128]
			GetClientName(client, clientName, sizeof(clientName))
			SQL_EscapeString(hDatabase, clientName, escapedName, sizeof(escapedName))
			Format(query, sizeof(query), "UPDATE %s SET TimePlayed='%i', name='%s' WHERE steamid ='%s'", pttTable, newTime, escapedName, queriesID);
			SQL_TQuery(hDatabase, updateTime, query)
		}
	}
	CloseHandle(hQuery)
}

public updateTime(Handle:owner, Handle:hQuery, const String:error[], any:client){
	if (hQuery != INVALID_HANDLE){
	}
	currClient++
	Queries()
	CloseHandle(hQuery)
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data){
	if (hndl == INVALID_HANDLE){
		LogError("Error! %s", error)
		return
	}
	
	hDatabase = hndl
}

public RefreshChanged(Handle:convar, const String:oldValue[], const String:newValue[]){
		CloseHandle(refreshTimer)
		new Float:newInterval = StringToFloat(newValue)
		refreshTimer = CreateTimer(newInterval, UpdateTimes, _, TIMER_REPEAT)
}