
Handle adt_trie;

public void OnPluginStart()
{
	char error[512];
	Database db = SQL_Connect("storage-local", true, error, sizeof(error));

	if(db == INVALID_HANDLE) SetFailState(error);

	char ident[10];
	SQL_ReadDriver(db, ident, sizeof(ident));

	if(!StrEqual(ident, "sqlite")) SetFailState("Support only SQLite");

	char query[512];
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS store_players_time ( steamid VARCHAR(20) NOT NULL , time FLOAT NOT NULL , PRIMARY KEY (steamid), UNIQUE (steamid) ON CONFLICT IGNORE);");

	if(!SQL_FastQuery(db, query))
	{
		SQL_GetError(db, error, sizeof(error));
		CloseHandle(db);

		SetFailState(error);
	}

	CloseHandle(db);

	adt_trie = CreateTrie();

	HookEventEx("player_disconnect", player_disconnect);
	RegConsoleCmd("sm_playtime", sm_playtime, "Display the time played in the server.");
	RegServerCmd("sm_playtime_empty_table", sm_playtime_empty_table, "Clear players times from database");
}

public Action sm_playtime_empty_table(int args)
{
	char error[512];
	Database db = SQL_Connect("storage-local", false, error, sizeof(error));

	if(db == INVALID_HANDLE)
	{
		return;
	}

	SQL_FastQuery(db, "DELETE FROM store_players_time");
	SQL_FastQuery(db, "VACUUM");
	CloseHandle(db);
	ClearTrie(adt_trie);
}

Transaction txn;
bool IsConnecting;

public Action sm_playtime(client, args)
{
	if(client == 0 || !IsClientInGame(client)) return Plugin_Handled;

	char auth[20];

	if(!GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth))) return Plugin_Handled;

	float time;

	if(!GetTrieValue(adt_trie, auth, time))
	{
		char error[512];
		Database db = SQL_Connect("storage-local", false, error, sizeof(error));

		if(db == INVALID_HANDLE)
		{
			ReplyToCommand(client, "Couldn't connect database");
			return Plugin_Handled;
		}

		char query[512];
		Format(query, sizeof(query), "SELECT time FROM store_players_time WHERE steamid = '%s'", auth);

		DBResultSet results = SQL_Query(db, query);

		if(results != INVALID_HANDLE)
		{
			if(SQL_HasResultSet(results) && SQL_FetchRow(results))
			{
				time = SQL_FetchFloat(results, 0);
			}
			CloseHandle(results);
		}
		CloseHandle(db);

		SetTrieValue(adt_trie, auth, time);
	}


	time += GetClientTime(client);

	char buffer[50];
	int itime = RoundToFloor(time);

	Format(buffer, sizeof(buffer), "%i hours, %i minutes", itime/3600, (itime/60)%60);

	PrintToChatAll("[SM] %N have been online %s", client, buffer);
	return Plugin_Handled;
}

public void player_disconnect(Handle event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client)) return;

	char auth[20];
	float time;

	if(!GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth))) return;

	time = GetClientTime(client);

	if(!IsConnecting)
	{
		//PrintToServer("connect");
		IsConnecting = true;
		SQL_TConnect(tconnect, "storage-local");
	}


	if(txn == INVALID_HANDLE) txn = SQL_CreateTransaction();

	char query[512];
	Format(query, sizeof(query), "UPDATE store_players_time SET time=time+%0.2f WHERE steamid = '%s';", time, auth);
	SQL_AddQuery(txn, query);
	//PrintToServer(query);
	Format(query, sizeof(query), "INSERT INTO store_players_time (steamid, time) VALUES ('%s', '%0.2f');", auth, time);
	SQL_AddQuery(txn, query);
	//PrintToServer(query);
	RemoveFromTrie(adt_trie, auth);
	
}

public void tconnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE) SetFailState(error);

	SQL_ExecuteTransaction(hndl, txn, OnSuccess, OnError, _, DBPrio_Low);
	txn = INVALID_HANDLE;
	CloseHandle(hndl);
	IsConnecting = false;
}

public void OnSuccess(Database db, any data, int numQueries, Handle[] results, any[] queryData)
{
	//PrintToServer("success");
}


public void OnError(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	//PrintToServer(error);
}

