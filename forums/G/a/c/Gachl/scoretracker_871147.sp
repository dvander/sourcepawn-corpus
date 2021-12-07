#include <sourcemod>

#define PLUGIN_VERSION "0.1.0"
#define DBNAME "default"

public Plugin:myinfo = 
{
	name = "Server score tracker",
	author = "GachL",
	description = "Tracks the approximate server score",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

new iServerScore = 0;
new iPlayerScore[MAXPLAYERS];
new Handle:hDatabase = INVALID_HANDLE;
new Handle:cvTablePrefix = INVALID_HANDLE;
new String:sTablePrefix[128];

public OnPluginStart()
{
	CreateTimer(60.0, cTickScore, _, TIMER_REPEAT);
	HookEvent("player_connect", cPlayerConnect);
	CreateConVar("sm_scoretracker_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_PROTECTED);
	cvTablePrefix = CreateConVar("sm_scoretracker_prefix", "score_", "Table prefix", FCVAR_PLUGIN);
	RegAdminCmd("sm_serverscore", cServerScore, ADMFLAG_GENERIC, "Show server score informations");
}

public OnConfigsExecuted()
{
	GetConVarString(cvTablePrefix, sTablePrefix, sizeof(sTablePrefix));
	if (!OpenDatabase())
		return;
}

public Action:cTickScore(Handle:hTimer)
{
	for (new i = 0; i < MaxClients; i++)
	{
		if (!FullCheckClient(i+1))
			continue;
		if (iPlayerScore[i] >= 45)
			continue;
		iPlayerScore[i]++;
		iServerScore++;
		SavePlayer(i+1);
	}
	SaveScore();
}

public cPlayerConnect(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	LoadPlayer(GetEventInt(hEvent, "index"));
}

public bool:FullCheckClient(client)
{
	if (client < 1)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	return true;
}

/**
 * SQL related functions
 */
public OpenDatabase()
{
	if (hDatabase != INVALID_HANDLE)
		CloseHandle(hDatabase);
	new String:sError[256];
	hDatabase = SQL_Connect(DBNAME, true, sError, sizeof(sError)); // This *may* lag the server
	if (hDatabase == INVALID_HANDLE)
	{
		PrintToServer("Server score: Unable to connect to database: %s", sError);
		return false;
	}
	
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%splayerscore` (`steamid` varchar(32) NOT NULL, `score` int(10) unsigned NOT NULL, `lastloss` int(10) unsigned NOT NULL,  PRIMARY KEY  (`steamid`));", sTablePrefix);
	SQL_Query(hDatabase, sQuery);
	
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `%sserverscore` ( `date` date NOT NULL, `score` int(11) NOT NULL, PRIMARY KEY  (`date`));", sTablePrefix);
	SQL_Query(hDatabase, sQuery);
	
	LoadToday();
	
	return true;
}

public LoadPlayer(hClient)
{
	new String:sSteamId[32], String:sLoadPlayerQuery[256];
	GetClientAuthString(hClient, sSteamId, sizeof(sSteamId));
	Format(sLoadPlayerQuery, sizeof(sLoadPlayerQuery), "SELECT `score`, `lastloss` FROM `%splayerscore` WHERE `steamid` = '%s';", sTablePrefix, sSteamId);
	SQL_TQuery(hDatabase, cSQLLoadPlayer, sLoadPlayerQuery, hClient);
}

public cSQLLoadPlayer(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in LoadPlayer SQL: %s", sError);
		return;
	}
	
	new String:sSteamId[32];
	GetClientAuthString(data, sSteamId, sizeof(sSteamId));
	
	if (SQL_GetRowCount(hQuery) == 1)
	{
		SQL_FetchRow(hQuery);
		new tsLastLoss = SQL_FetchInt(hQuery, 1);
		if (tsLastLoss - GetTime() >= 86400)
		{
			tsLastLoss = GetTime();
			iServerScore = iServerScore - 15;
			new String:sUpdatePlayerQuery[256];
			Format(sUpdatePlayerQuery, sizeof(sUpdatePlayerQuery), "UPDATE `%splayerscore` SET `score` = 0, `lastloss` = %i WHERE `steamid` = '%s';", sTablePrefix, tsLastLoss, sSteamId);
			SQL_TQuery(hDatabase, cSQLIgnore, sUpdatePlayerQuery);
			iPlayerScore[data-1] = 0;
		}
		else
		{
			iPlayerScore[data-1] = SQL_FetchInt(hQuery, 0);
		}
	}
	else
	{
		new String:sCreatePlayerQuery[256];
		Format(sCreatePlayerQuery, sizeof(sCreatePlayerQuery), "INSERT INTO `%splayerscore` (`steamid`, `score`, `lastloss`) VALUES ('%s', 0, %i);", sTablePrefix, sSteamId, GetTime());
		SQL_TQuery(hDatabase, cSQLIgnore, sCreatePlayerQuery);
		iServerScore = iServerScore - 15;
		iPlayerScore[data-1] = 0;
	}
}

public LoadToday()
{
	if (iServerScore != 0)
	{
		SaveScore();
	}
	else
	{
		new String:sGetTodayQuery[256];
		Format(sGetTodayQuery, sizeof(sGetTodayQuery), "SELECT `score` FROM `%sserverscore` WHERE `date` = NOW();", sTablePrefix);
		SQL_TQuery(hDatabase, cSQLGetToday, sGetTodayQuery);
	}
}

public cSQLGetToday(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in LoadToday SQL: %s", sError);
		return;
	}
	
	if (SQL_GetRowCount(hQuery) == 0)
	{
		new String:sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT `score` FROM `%sserverscore` ORDER BY `date` DESC LIMIT 0, 1;", sTablePrefix);
		SQL_TQuery(hDatabase, cSQLGetLastScore, sQuery);
		return;
	}
	else
	{
		SQL_FetchRow(hQuery);
		iServerScore = SQL_FetchInt(hQuery, 0);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!FullCheckClient(i))
				continue;
			LoadPlayer(i);
		}
	}
}

public cSQLGetLastScore(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in GetLastScore SQL: %s", sError);
		return;
	}
	
	if (SQL_GetRowCount(hQuery) == 0)
	{
		iServerScore = 0;
	}
	else
	{
		SQL_FetchRow(hQuery);
		iServerScore = SQL_FetchInt(hQuery, 0);
	}
	
	new String:sNewDayQuery[256];
	Format(sNewDayQuery, sizeof(sNewDayQuery), "INSERT INTO `%sserverscore` (`date`, `score`) VALUES (NOW(), %i);", sTablePrefix, iServerScore);
	SQL_TQuery(hDatabase, cSQLIgnore, sNewDayQuery);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!FullCheckClient(i))
			continue;
		LoadPlayer(i);
	}
}

public SaveScore()
{
	new String:sGetTodayQuery[256];
	Format(sGetTodayQuery, sizeof(sGetTodayQuery), "SELECT `score` FROM `%sserverscore` WHERE `date` = NOW();", sTablePrefix);
	SQL_TQuery(hDatabase, cSQLSaveToday, sGetTodayQuery);
}

public cSQLSaveToday(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in SaveToday SQL: %s", sError);
		return;
	}
	
	if (SQL_GetRowCount(hQuery) == 0)
	{
		new String:sInsertQuery[256];
		Format(sInsertQuery, sizeof(sInsertQuery), "INSERT INTO `%sserverscore` (`date`, `score`) VALUES (NOW(), %i)", sTablePrefix, iServerScore);
		SQL_TQuery(hDatabase, cSQLProcessSave, sInsertQuery);
	}
	else
	{
		new String:sUpdateQuery[256];
		Format(sUpdateQuery, sizeof(sUpdateQuery), "UPDATE `%sserverscore` SET `score` = %i WHERE `date` = NOW();", sTablePrefix, iServerScore);
		SQL_TQuery(hDatabase, cSQLProcessSave, sUpdateQuery);
	}
}

public SavePlayer(hClient)
{
	new String:sSteamId[32];
	GetClientAuthString(hClient, sSteamId, sizeof(sSteamId));
	new String:sSavePlayerQuery[256];
	Format(sSavePlayerQuery, sizeof(sSavePlayerQuery), "UPDATE `%splayerscore` SET `score` = %i WHERE `steamid` = '%s';", sTablePrefix, iPlayerScore[hClient-1], sSteamId);
	SQL_TQuery(hDatabase, cSQLIgnore, sSavePlayerQuery);
}

public Action:cServerScore(hClient, iArgs)
{
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT `score` FROM `%sserverscore` ORDER BY `date` DESC LIMIT 0, 5;", sTablePrefix);
	SQL_TQuery(hDatabase, cSQLServerScore, sQuery, hClient);
	return Plugin_Handled;
}

public cSQLServerScore(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in ServerScore SQL: %s", sError);
		return;
	}
	
	if (SQL_GetRowCount(hQuery) == 0)
	{
		PrintToConsole(data, "No server score yet.");
		return;
	}
	
	PrintToConsole(data, "The score of the last few days:");
	for (new i = 0; i < SQL_GetRowCount(hQuery); i++)
	{
		SQL_FetchRow(hQuery);
		if (i + 1 == SQL_GetRowCount(hQuery))
		{
			PrintToConsole(data, "%i (Today)", SQL_FetchInt(hQuery, 0));
			continue; // could be break; too...
		}
		PrintToConsole(data, "%i (%i day(s) ago)", SQL_FetchInt(hQuery, 0), SQL_GetRowCount(hQuery) - i);
	}
	if (FullCheckClient(data))
		PrintToChat(data, "See console for output");
}

public cSQLProcessSave(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in query SQL: %s", sError);
		return;
	}
	
	new String:sGetTodayQuery[256];
	Format(sGetTodayQuery, sizeof(sGetTodayQuery), "SELECT `score` FROM `%sserverscore` WHERE `date` = NOW();", sTablePrefix);
	SQL_TQuery(hDatabase, cSQLGetToday, sGetTodayQuery);
}

public cSQLIgnore(Handle:hOwner, Handle:hQuery, String:sError[], any:data)
{
	if (hQuery == INVALID_HANDLE)
	{
		PrintToServer("Server score: Error in query SQL: %s", sError);
		return;
	}
}
