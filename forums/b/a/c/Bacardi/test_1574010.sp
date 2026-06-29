new Handle:db = INVALID_HANDLE;
new bool:loaded[MAXPLAYERS+1] = {false, ...};
new bool:roundstart = false;

new Handle:game_start_timer = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_spawn", player_spawn);
	HookEvent("round_end", round_end);
	HookEvent("cs_win_panel_match", round_end);

	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, false);

	RegAdminCmd("sm_scores_x_clear", admcmd_clear, ADMFLAG_CONVARS, "Clear scores_x database");

	SQL_TConnect(GotDatabase, "scores_x");
}

public OnMapStart()
{
	roundstart = false;
}

public Action:admcmd_clear(client, args)
{
	if(db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "Database scores_x INVALID !!!")
		return Plugin_Handled;
	}

	ShowActivity(client, "clear scores_x database");
	LogAction(client, -1, "%L clear scores_x database", client);


	SQL_LockDatabase(db);

	if(!SQL_FastQuery(db, "DELETE FROM `scores_x`"))
	{
		decl String:error[256];
		SQL_GetError(db, error, sizeof(error));
		LogError(" Query DELETE FROM `scores_x` failed! %s", error);
		SQL_UnlockDatabase(db);
		return Plugin_Handled;
	}

	SQL_UnlockDatabase(db);

	ReplyToCommand(client, "DELETE FROM `scores_x` was successful");

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetEntProp(i, Prop_Data, "m_iFrags", 0);
			SetEntProp(i, Prop_Data, "m_iDeaths", 0);
			DoLoadScores(i);
		}
	}
	return Plugin_Handled;
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Can't connect database
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Database failure: %s", error);
		return;
	}

	db = hndl;

	if(!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS `scores_x` (`steamid` VARCHAR( 20 ) NOT NULL , `m_iScore` INT NOT NULL , `m_iDeaths` INT NOT NULL, PRIMARY KEY ( `steamid` ))"))
	{
		decl String:err[300]; err[0] = '\0';
		SQL_GetError(db, err, sizeof(err));
		SetFailState("Query CREATE TABLE failed! %s", err);
	}
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(roundstart) // We had game start ??
	{
		decl String:buffer[15];
		buffer[0] = '\0';
		BfReadString(bf, buffer, sizeof(buffer), false);

		if(StrContains(buffer, "Game_scoring") == 2) // "Scoring will not start until both teams have players", there one player left on field
		{
			if(game_start_timer != INVALID_HANDLE) // Dam, timer game_start have started. Destroy
			{
				KillTimer(game_start_timer);
				game_start_timer = INVALID_HANDLE;
			}

			for(new i = 1; i <= MaxClients; i++) // Save current player(s) score now and set all loaded[x] = false;
			{
				if(IsClientInGame(i))
				{
					OnClientDisconnect(i); // Using public OnClientDisconnect(client) below
				}
				loaded[i] = false;
			}
			roundstart = false; // Stop scores collection
		}
	}
}

public round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(StrContains(name, "cs_win_panel_match", false) != -1) // Map end
	{
		if(game_start_timer != INVALID_HANDLE)
		{
			KillTimer(game_start_timer);
			game_start_timer = INVALID_HANDLE;
		}
	}
	else
	{
		decl reason;
		reason = GetEventInt(event, "reason");

		if(reason == 9 || reason == 15) // one player or game start
		{
			if(game_start_timer != INVALID_HANDLE)
			{
				KillTimer(game_start_timer);
				game_start_timer = INVALID_HANDLE;
			}

			if(reason == 15)
			{
				game_start_timer = CreateTimer(2.6, game_start); // Start soon save/load scores
			}

			roundstart = false;
		}
	}
}

public Action:game_start(Handle:timer)
{
	game_start_timer = INVALID_HANDLE;
	roundstart = true;
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!roundstart)
	{
		return;
	}

	decl client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!loaded[client] && !IsFakeClient(client) && GetClientTeam(client) >= 2)
	{
		DoLoadScores(client);
	}
}

DoLoadScores(client)
{
	decl String:auth[20], String:query[256];
	GetClientAuthString(client, auth, sizeof(auth));
	Format(query, sizeof(query), "SELECT `m_iScore` , `m_iDeaths` FROM `scores_x` WHERE `steamid` = '%s'", auth);
	SQL_TQuery(db, load_scores, query, GetClientUserId(client));
}

public load_scores(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	decl client;

	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}

	loaded[client] = true;

	if (hndl == INVALID_HANDLE)
	{
		LogError(" Query load_scores failed! %s", error);
		return;
	}

	decl String:buffer[256];

	if(SQL_GetRowCount(hndl) > 0) // There are player score in database
	{
		// Set player score
		SQL_FetchString(hndl, 0, buffer, sizeof(buffer));
		SetEntProp(client, Prop_Data, "m_iFrags", StringToInt(buffer));
		SQL_FetchString(hndl, 1, buffer, sizeof(buffer));
		SetEntProp(client, Prop_Data, "m_iDeaths", StringToInt(buffer));
	}
	else // Nothing found, make new
	{
		decl String:auth[20];
		GetClientAuthString(client, auth, sizeof(auth));
		Format(buffer, sizeof(buffer), "INSERT INTO `scores_x` VALUES ('%s', '%i', '%i')", auth, GetClientFrags(client), GetClientDeaths(client));

		SQL_LockDatabase(db);

		if(!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, buffer, sizeof(buffer));
			LogError(" Query INSERT INTO `scores_x` in db failed! %s", buffer);
			SQL_UnlockDatabase(db);
			return;
		}

		SQL_UnlockDatabase(db);
	}
}

public OnClientDisconnect(client)
{
	if(roundstart && loaded[client] && !IsFakeClient(client))
	{
		decl String:auth[20], String:query[256];
		GetClientAuthString(client, auth, sizeof(auth));
		Format(query, sizeof(query), "UPDATE `scores_x` SET `m_iScore` = '%i', `m_iDeaths` = '%i' WHERE `steamid` = '%s'", GetClientFrags(client), GetClientDeaths(client), auth);

		SQL_LockDatabase(db);

		if(!SQL_FastQuery(db, query))
		{
			SQL_GetError(db, query, sizeof(query));
			LogError(" Query UPDATE `scores_x` in db failed! %s", query);
		}

		SQL_UnlockDatabase(db);
	}
	loaded[client] = false;
}