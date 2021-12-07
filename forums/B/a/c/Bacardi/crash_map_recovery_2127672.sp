/*
	Change log:

	22.04.2014 version 0.1
	- Added same 24 hour limit in MySQL query, what is in SQLite query
*/
public Plugin:myinfo = 
{
	name = "Crash map recovery",
	author = "Bacardi",
	description = "Try restore map what was before server crash/reboot",
	version = "0.1",
	url = "https://forums.alliedmods.net/showthread.php?t=239087"
};

new Handle:g_hDB;
new Handle:g_hStatement;


public OnPluginStart()
{
	SQL_TConnect(TConnect, "crash_map_recovery");
}

public TConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("error: %s", error);
	}

	g_hDB = hndl;

/*
CREATE TABLE IF NOT EXISTS crash_map_recovery (map VARCHAR(65) PRIMARY KEY  NOT NULL , time DATETIME DEFAULT CURRENT_TIMESTAMP, loaded BOOL)
*/
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS crash_map_recovery (map VARCHAR(65) PRIMARY KEY  NOT NULL , time DATETIME DEFAULT CURRENT_TIMESTAMP, loaded BOOL)");
	SQL_UnlockDatabase(g_hDB);

/*
REPLACE INTO crash_map_recovery (map,loaded) VALUES ('asd' , 1)
*/
	new String:buffer[256];
	g_hStatement = SQL_PrepareQuery(g_hDB, "REPLACE INTO crash_map_recovery (map,loaded) VALUES (? , ?)", buffer, sizeof(buffer));

	if(g_hStatement == INVALID_HANDLE)
	{
		//PrintToServer("g_hStatement error: %s", buffer);
		CloseHandle(g_hDB);
		SetFailState("g_hStatement error: %s", buffer);
		return;
	}

	SQL_ReadDriver(g_hDB, buffer, sizeof(buffer));

	if(StrEqual(buffer, "sqlite", false))
	{
		SQL_TQuery(g_hDB, TQuery, "SELECT map, loaded FROM crash_map_recovery WHERE time > datetime('now','-1 day') ORDER BY time DESC LIMIT 0 , 2");
	}
	else
	{
		//PrintToServer("connect");
		/* SELECT * FROM crash_map_recovery ORDER BY time DESC LIMIT 0 , 2*/
		/* SELECT * FROM crash_map_recovery WHERE time > DATE_SUB(NOW(),INTERVAL 1 DAY) ORDER BY time DESC LIMIT 0 , 2*/
		SQL_TQuery(g_hDB, TQuery, "SELECT map, loaded FROM crash_map_recovery WHERE time > DATE_SUB(NOW(),INTERVAL 1 DAY) ORDER BY time DESC LIMIT 0 , 2");
	}
}

public TQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new String:buffer[MAX_NAME_LENGTH], loaded;
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, buffer, sizeof(buffer));
		loaded = SQL_FetchInt(hndl, 1);
		//PrintToServer("buffer %s %i", buffer, loaded);

		if(loaded)
		{
			//ServerCommand("changelevel %s", buffer);
			LogMessage("Recovery map %s", buffer);
			ForceChangeLevel(buffer, "Crash map recovery");
			break;
		}
	}
}

public OnMapStart()
{
	if(g_hDB == INVALID_HANDLE)
	{
		return;
	}

	new String:query[256];
	GetCurrentMap(query, sizeof(query));
	SQL_BindParamString(g_hStatement, 0, query, false);
	SQL_BindParamInt(g_hStatement, 1, 0);

	SQL_LockDatabase(g_hDB);
	SQL_Execute(g_hStatement);
	SQL_UnlockDatabase(g_hDB);

	CreateTimer(30.0, update, _, TIMER_FLAG_NO_MAPCHANGE);
	//PrintToServer("insert %s", query);
}

public Action:update(Handle:timer)
{
	new String:query[256];
	GetCurrentMap(query, sizeof(query));
	SQL_BindParamString(g_hStatement, 0, query, false);
	SQL_BindParamInt(g_hStatement, 1, 1);

	SQL_LockDatabase(g_hDB);
	SQL_Execute(g_hStatement);
	SQL_UnlockDatabase(g_hDB);
	//PrintToServer("update %s", query);
}