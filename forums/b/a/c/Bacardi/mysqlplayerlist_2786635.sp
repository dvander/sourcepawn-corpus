/*

	(XAMPP) MySQL PHPMyAdmin sql query steps:

1)
DROP TABLE IF EXISTS `playerlist`;

2)
CREATE TABLE `playerlist` ( `clientid` INT NOT NULL AUTO_INCREMENT ,
`name` VARCHAR(128) NULL DEFAULT NULL ,
`steamid` VARCHAR(128) NULL DEFAULT NULL ,
`score` INT NOT NULL DEFAULT '0' ,
`time` VARCHAR(15) NULL DEFAULT NULL , PRIMARY KEY (`clientid`));


3)
DELIMITER $$
DROP PROCEDURE IF EXISTS test$$
CREATE PROCEDURE test()
BEGIN
 DECLARE count INT DEFAULT 1;
 WHILE count <= 65 DO
   INSERT INTO `playerlist` () VALUES ();
   SET count = count + 1;
 END WHILE;
END$$
DELIMITER ;


CALL test();



*/


// Similiar old plugins https://forums.alliedmods.net/showthread.php?p=2786552#post2786552

#include <sdktools>


public Plugin myinfo =
{
	name = "MySQL playerlist",
	author = "Bacardi",
	description = "Updates playerlist table, name, steamid, score, time",
	version = "1.01",
	url = "http://www.sourcemod.net/"
};


int player_manager;	// Find entity "*_player_manager" to get player m_iScore

enum struct PlayerInfo
{
	char name[MAX_NAME_LENGTH];
	char steamid[MAX_NAME_LENGTH];
	int score;
	char time[15];
	bool UpdateThisIndex; // Keep track which client indexs we update (send less queries)

	void Clear()
	{
		if(StrEqual(this.steamid, "NULL", true))
			return;

		this.UpdateThisIndex = true;
		Format(this.name, sizeof(this.name), "NULL");
		Format(this.steamid, sizeof(this.steamid), "NULL");
		this.score = 0;
		Format(this.time, sizeof(this.time), "NULL");
	}

	void Update(int client, bool IsBot)
	{
		this.UpdateThisIndex = true;
		Format(this.name, sizeof(this.name), "%N", client);
		GetClientAuthId(client, AuthId_Engine, this.steamid, sizeof(this.steamid));

		if(player_manager != -1)
			this.score = GetEntProp(player_manager, Prop_Send, "m_iScore", _, client);

		if(IsBot)
		{
			Format(this.time, sizeof(this.time), " ");
			return;
		}

		int a = RoundToNearest(GetClientTime(client));
		Format(this.time, sizeof(this.time), "%im %is", a / 60, a % 60);
	}
}
PlayerInfo playerinfo[MAXPLAYERS+1];

enum struct DatabaseInfo
{
	Database DB;
	bool IsConnecting;
}
DatabaseInfo databaseinfo;

enum
{
	CONNECTION_OFF = 0,
	CONNECTION_ON
}

#define TABLENAME		"playerlist"	// Change table name here. Note! You need use same table name in SQL query codes at top!
#define TIMER_FREQUENCY	10.0			// Delay between updates
#define INCLUDE_BOTS		false			// When true, include SourceTV, Replay, Bots etc. etc. fake clients



public void OnPluginEnd()
{
	if(databaseinfo.DB != null)
		UpdateTable(true);
}

public void OnPluginStart()
{
	HookEventEx("player_connect", player_connect, EventHookMode_PostNoCopy);
	player_connect(null, NULL_STRING, false);
}

public void OnConfigsExecuted()
{
	player_manager = -1;
	char clsname[50];
	bool found = false;

	while((player_manager = FindEntityByClassname(player_manager, "*")) != -1)
	{
		if(!GetEntityClassname(player_manager, clsname, sizeof(clsname)) ||
			StrContains(clsname, "player_manager", true) == -1)
		{
			continue;
		}

		found = true;

		if(!HasEntProp(player_manager, Prop_Send, "m_iScore"))
		{
			player_manager = -1;
		}

		break;
	}

	if(!found)
		player_manager = -1;	
}

public void player_connect(Event event, const char[] name, bool dontBroadcast)
{
	if(databaseinfo.DB == null && !databaseinfo.IsConnecting)
	{
		databaseinfo.IsConnecting = true;

		// When event player_connect happens, client is not connected yet. This why we need delay 1 sec before next code.
		CreateTimer(1.0, TimerDelayConnectDB);
	}
}

public Action TimerDelayConnectDB(Handle timer)
{
	Database.Connect(ConnectDB, TABLENAME);

	return Plugin_Continue;
}

public void ConnectDB(Database db, const char[] error, any data)
{
	databaseinfo.IsConnecting = false;

	if(db == null)
	{
		LogError("playerlist - Couldn't connect to database (databases.cfg configure '%s')", TABLENAME);
		return;
	}

	databaseinfo.DB = db;

	CollectPlayers();
}

void CollectPlayers()
{
	static bool IsHumanConnected = false;

	bool IsBot;

	for(int i = 1; i < sizeof(playerinfo); i++)
	{
		IsBot = false;

		if(i > MaxClients || !IsClientConnected(i) ||
			IsClientInGame(i) && (IsBot = IsFakeClient(i)) && !INCLUDE_BOTS)
		{
			playerinfo[i].Clear();
			continue;
		}

		if(!IsClientInGame(i)) // player connecting
		{
			playerinfo[i].UpdateThisIndex = true;
			playerinfo[i].score = 0;
			IsHumanConnected = true;
			continue;
		}

		playerinfo[i].Update(i, IsBot);
		IsHumanConnected = true;
	}

	if(IsHumanConnected)
	{
		IsHumanConnected = false; // Try in next cycle, stop update if no humans

		UpdateTable();
		return;
	}

	// Do last update
	UpdateTable(true);
}

void UpdateTable(bool SetAllRowsToDEFAULT = false)
{
	if(SetAllRowsToDEFAULT)
	{
		// clear array first
		for(int x = 1; x <= MaxClients; x++)
		{
			playerinfo[x].Clear();
			playerinfo[x].UpdateThisIndex = false;
		}
	}

	if(databaseinfo.DB == null)
	{
		LogError("playerlist - UpdateTable() error, Database handle is null");
		return;
	}


	Transaction Txn = new Transaction();

	char query[1024];

	// Set all rows to DEFAULT values
	if(SetAllRowsToDEFAULT)
	{
		SQL_FormatQuery(databaseinfo.DB, query, sizeof(query),
		"UPDATE %s \
		SET name=DEFAULT, \
		steamid=DEFAULT, \
		score=DEFAULT, \
		time=DEFAULT",
		TABLENAME);

		Txn.AddQuery(query);
		SQL_ExecuteTransaction(databaseinfo.DB, Txn, onSuccess, onError, CONNECTION_OFF);
		return;
	}

	for(int x = 1; x <= MaxClients; x++)
	{
		if(!playerinfo[x].UpdateThisIndex)
		{
			continue;
		}

		playerinfo[x].UpdateThisIndex = false;

		// To able to use NULL or DEFAULT value in query and get it to work in SQL,
		// I got problems with single 'quotes' if I formatted those in strings before hand.
		//	- quick solution is separate those two queries, at this point. Use single quotes in one of those.


		if(!StrEqual(playerinfo[x].steamid, "NULL", true))
		{
			SQL_FormatQuery(databaseinfo.DB, query, sizeof(query),
			"UPDATE %s \
			SET name='%s', \
			steamid='%s', \
			score=%i, \
			time='%s' \
			WHERE clientid=%i;",
			TABLENAME,
			playerinfo[x].name,
			playerinfo[x].steamid,
			playerinfo[x].score,
			playerinfo[x].time,
			x);

		} else {
			SQL_FormatQuery(databaseinfo.DB, query, sizeof(query),
			"UPDATE %s \
			SET name=DEFAULT, \
			steamid=DEFAULT, \
			score=DEFAULT, \
			time=DEFAULT \
			WHERE clientid=%i;",
			TABLENAME,
			x);
		}

		Txn.AddQuery(query, x);
	}

	// ...no harm to execute 0 queries ?
	SQL_ExecuteTransaction(databaseinfo.DB, Txn, onSuccess, onError, CONNECTION_ON);
}

public void onSuccess(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	//PrintToServer("onSuccess %i", numQueries);

	if(data == CONNECTION_OFF)
	{
		delete databaseinfo.DB;
		return;
	}

	CreateTimer(TIMER_FREQUENCY, TimerExecuteCollectPlayers);
}

public void onError(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	//PrintToServer("onError %i, %i %s", numQueries, failIndex, error);
	LogError("playerlist - onError %i, %i %s", numQueries, failIndex, error);

	if(data == CONNECTION_OFF)
	{
		delete databaseinfo.DB;
		return;
	}

	CreateTimer(TIMER_FREQUENCY, TimerExecuteCollectPlayers);
}

public Action TimerExecuteCollectPlayers(Handle timer)
{
	CollectPlayers();
	return Plugin_Continue;
}


