#include <sourcemod>
#include <clientprefs>
#include <colors>

#include "savescores/globals.sp"
#include "savescores/cstrike.sp"
#include "savescores/tf.sp"
#include "savescores/hl2mp.sp"

#undef REQUIRE_PLUGIN 
#include <autoupdate>

#define PLUGIN_VERSION "1.3.4"

// Regular plugin information
public Plugin:myinfo = 
{
	name = "Save Scores",
	author = "exvel",
	description = "Plugin saves player scores when they leave a map then restores their scores if they then rejoin on the same map. For Counter-Strike:Source this can also include cash if the option is set. If a map is restarted via mp_restartgame the saved scores are reset",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{	
	// Getting a game name and doing game specific stuff
	decl String:gameName[30];
	GetGameFolderName(gameName, sizeof(gameName));
	
	// CS stuff
	if (StrEqual(gameName, "cstrike", false))
	{
		Game = GAME_CS;
		
		CS_Stuff();
	}
	// TF stuff
	else if (StrEqual(gameName, "tf", false))
	{
		Game = GAME_TF;
		
		TF_Stuff();
	}
	// HL stuff
	else if (StrEqual(gameName, "hl2mp", false))
	{
		Game = GAME_HL;
		
		HL_Stuff();
	}
	// L4D is completely unsupported
	else if (StrEqual(gameName, "left4dead", false) || StrEqual(gameName, "left4dead2", false))
	{
		SetFailState("This game is not supported");
	}
	// For all other games we will do standart stuff
	else
	{
		Game = GAME_ANY;
		
		// Hooking commands for detecting of new game start
		cvar_restartgame = FindConVar("mp_restartgame");
		if (cvar_restartgame != INVALID_HANDLE)
			HookConVarChange(cvar_restartgame, NewGameCommand);
		
		cvar_restartround = FindConVar("mp_restartround");
		if (cvar_restartround != INVALID_HANDLE)
			HookConVarChange(cvar_restartround, NewGameCommand);
		
		// Hooking events for detecting of new game start
		HookEvent("round_start", Event_NewGameStart);
		HookEvent("round_end", Event_RoundEnd);
	}
	
	// Creating cvars
	CreateConVar("sm_save_scores_version", PLUGIN_VERSION, "Save Scores Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_save_scores = CreateConVar("sm_save_scores", "1", "Enabled/Disabled save scores functionality, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_save_scores_tracking_time = CreateConVar("sm_save_scores_tracking_time", "20", "Amount of time in minutes to store a player score for, if set to 0 the score will be tracked for the duration of the map", FCVAR_PLUGIN, true, 0.0, true, 60.0);
	cvar_save_scores_forever = CreateConVar("sm_save_scores_forever", "0", "If set to 1 save scores will not clear scores on map change or round restart. Track players scores until admin will use \"sm_save_scores_reset\"", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_save_scores_allow_reset = CreateConVar("sm_save_scores_allow_reset", "1", "Allow players to reset there scores, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_lan = FindConVar("sv_lan");
	
	// Hooking cvar change
	HookConVarChange(cvar_lan, OnCVarChange);
	HookConVarChange(cvar_save_scores, OnCVarChange);
	HookConVarChange(cvar_save_scores_tracking_time, OnCVarChange);
	HookConVarChange(cvar_save_scores_forever, OnCVarChange);
	HookConVarChange(cvar_save_scores_allow_reset, OnCVarChange);
	
	// Hooking event
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	// Creating commands
	RegConsoleCmd("resetscore", ResetScore, "Resets your deaths and kills back to 0");
	RegAdminCmd("sm_save_scores_reset", Command_Clear, ADMFLAG_GENERIC, "Resets all saved scores");
	
	// Other regular stuff
	LoadTranslations("savescores.phrases");
	AutoExecConfig(true, "plugin.savescores");
	
	// Creating DB...
	InitDB();
	
	// ...and clear it
	ClearDB();
	
	// Creating timer that will save all players' scores each second if option for saving scores forever is enabled
	CreateTimer(1.0, SaveAllScores, _, TIMER_REPEAT);
}

// Here we will mark next round as a new game if needed
public NewGameCommand(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!save_scores || StringToInt(newValue) == 0)
	{
		return;
	}
	
	new Float:fTimer = StringToFloat(newValue);
	
	if (isNewGameTimer)
	{
		CloseHandle(g_hNewGameTimer);
	}
	
	g_hNewGameTimer = CreateTimer(fTimer - 0.1, MarkNextRoundAsNewGame);
	isNewGameTimer = true;
} 

// Delayed action: mark next round as a new game
public Action:MarkNextRoundAsNewGame(Handle:timer)
{
	isNewGameTimer = false;
	g_NextRoundNewGame = true;
}

// If round is a new game we should clear DB or restore players' scores
public Action:Event_NewGameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_NextRoundNewGame)
	{
		return Plugin_Continue;
	}
	
	g_NextRoundNewGame = false;
	
	ClearDB();
	
	if (!save_scores_forever || !save_scores || isLAN)
	{
		return Plugin_Continue;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !justConnected[client])
		{
			SetScore(client, g_iPlayerScore[client]);
			SetDeaths(client, g_iPlayerDeaths[client]);
			SetCash(client, g_iPlayerCash[client]);
		}
	}
	
	return Plugin_Continue;
}

// Here we will also mark next round as a new game if needed
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!save_scores_forever || !save_scores || isLAN)
	{
		return Plugin_Continue;
	}
	
	decl String:szMessage[32];
	GetEventString(event, "message", szMessage, sizeof(szMessage));
	
	if (StrEqual(szMessage, "#Game_Commencing") || StrEqual(szMessage, "#Round_Draw"))
	{
		g_NextRoundNewGame = true;
	}
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	GetCVars();
	
	// Set client settings menu item for resetting scores
	if (save_scores && save_scores_allow_reset && !g_isMenuItemCreated)
	{
		SetCookieMenuItem(ResetScoreInMenu, 0, "Reset Score");
		g_isMenuItemCreated = true;
	}
}

// Action that will be done when menu item will be pressed
public ResetScoreInMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{	
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T", "Reset Score", client);
		return;
	}
	
	if (!save_scores || !save_scores_allow_reset)
	{
		return;
	}
	
	SetDeaths(client, 0);
	SetScore(client, 0);
	RemoveScoreFromDB(client);
	CPrintToChat(client, "{green}%t", "You have just reset your score");
}

// Player's command that resets score
public Action:ResetScore(client, args)
{
	if (!save_scores || !save_scores_allow_reset)
	{
		return Plugin_Handled;
	}
	
	if (client > 0)
	{
		SetDeaths(client, 0);
		SetScore(client, 0);
		RemoveScoreFromDB(client);
		ReplyToCommand(client, "%t", "You have just reset your score");
	}
	else
	{
		ReplyToCommand(client, "This command is only for players");
	}
	
	return Plugin_Handled;
}

// Here we are creating SQL DB
public InitDB()
{
	// SQL DB
	new String:error[255];
	g_hDB = SQLite_UseDatabase("savescores", error, sizeof(error));
	
	if (g_hDB == INVALID_HANDLE)
		SetFailState("SQL error: %s", error);
	
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "VACUUM");
	SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS savescores_scores (steamid TEXT PRIMARY KEY, frags SMALLINT, deaths SMALLINT, money SMALLINT, timestamp INTEGER);");
	SQL_UnlockDatabase(g_hDB);
}

// Admin command that clears all player's scores
public Action:Command_Clear(admin, args)
{
	if (!save_scores)
	{
		ReplyToCommand(admin, "Save Scores is currently disabled");
		return Plugin_Handled;
	}
	
	ClearDB(false);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			SetScore(client, 0);
			SetDeaths(client, 0);
			
			if (Game == GAME_CS)
			{
				SetCash(client, g_CSDefaultCash);
			}
		}
	}
	
	ReplyToCommand(admin, "Players scores has been reset");
	
	return Plugin_Handled;
}

// Just clear DB. Sometimes we need it to be delayed.
ClearDB(bool:Delay = true)
{
	if (Delay)
	{
		CreateTimer(0.1, ClearDBDelayed);
	}
	else
	{
		ClearDBQuery();
	}
}

// ...the same as above but delayed
public Action:ClearDBDelayed(Handle:timer)
{
	if (!save_scores_forever)
	{
		ClearDBQuery();
	}
}

// Doing clearing stuff
ClearDBQuery()
{
	// Clearing SQL DB
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "DELETE FROM savescores_scores;");
	SQL_UnlockDatabase(g_hDB);

	// Clearing TF scores that are into the varibles
	if (Game == GAME_TF)
	{
		for (new client = 1; client <= MAXPLAYERS; client++)
		{
			TFScore[client] = SCORE_NOACTION;
			TFScoreMod[client] = SCOREMOD_NOACTION;
		}
	}
}

public OnAllPluginsLoaded()
{
	// Killing scoremod.smx
	UnloadScoreMod();
	
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_AddPlugin("savescores.googlecode.com", "/svn/version.xml", PLUGIN_VERSION);
	}
	else
	{
		LogMessage("Note: This plugin supports updating via Plugin Autoupdater. Install it if you want to enable auto-update functionality.");
	}
}

// Marking native functions
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("OnCalcPlayerScore");
	MarkNativeAsOptional("TF2_GetResourceEntity");
	MarkNativeAsOptional("AutoUpdate_AddPlugin");
	MarkNativeAsOptional("AutoUpdate_RemovePlugin");
	return APLRes_Success;
}

public OnMapStart()
{
	// ...killing it again ^_^
	UnloadScoreMod();
	
	// Clear DB
	ClearDB();
	
	// Checking again for TF extensions. Just for sure.
	if (Game == GAME_TF)
		CheckTFExtensions();
}



// If options for saving scores forever is set we will save player's score every second
public Action:SaveAllScores(Handle:timer)
{
	if (!save_scores_forever || !save_scores || isLAN)
	{
		return Plugin_Continue;
	}
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client) && !justConnected[client])
		{
			g_iPlayerScore[client] = GetScore(client);
			g_iPlayerDeaths[client] = GetDeaths(client);
			
			if (Game == GAME_CS)
			{
				// If game is CS also save player's cash
				g_iPlayerCash[client] = GetCash(client);
			}
		}
	}
	
	return Plugin_Continue;
}

// Syncronize DB with score varibles
public SyncDB()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client))
		{
			decl String:steamId[30];
			decl String:query[200];
			
			GetClientAuthString(client, steamId, sizeof(steamId));
			new frags = GetScore(client);
			new deaths = GetDeaths(client);
			new cash = GetCash(client);
			
			Format(query, sizeof(query), "INSERT OR REPLACE INTO savescores_scores VALUES ('%s', %d, %d, %d, %d);", steamId, frags, deaths, cash, GetTime());
			SQL_FastQuery(g_hDB, query);
		}
	}
}

// Most of the score manipulations will be done in this event
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client || isLAN || !save_scores)
		return Plugin_Continue;
	
	if (IsFakeClient(client) || !IsClientInGame(client))
		return Plugin_Continue;
	
	// Player joined spectators and he already played so we will save his scores. Actually we need only cash but nevermind.
	if (Game == GAME_CS && GetEventInt(event, "team") == 1 && save_scores_css_spec_cash && !justConnected[client])
	{
		InsertScoreInDB(client);
		return Plugin_Continue;
	}
	// Player returned to the team from spectators. Lets set his cash back.
	else if (Game == GAME_CS && GetEventInt(event, "team") > 1 && GetEventInt(event, "oldteam") < 2 && save_scores_css_spec_cash && !justConnected[client])
	{
		onlyCash[client] = true;
		GetScoreFromDB(client);
	}
	// Player just connected and joined team
	else if (justConnected[client] && GetEventInt(event, "team") != 1)
	{
		justConnected[client] = false;
		GetScoreFromDB(client);
	}
	
	return Plugin_Continue;
}

// Get player's score
public GetScore(client)
{
	if (Game == GAME_TF)
	{
		return TF2_GetPlayerResourceData(client, TFResource_TotalScore);
	}
	else
	{
		return GetClientFrags(client);
	}
}

// Set player's score
public SetScore(client, score)
{
	if (Game == GAME_TF)
	{
		TFScore[client] = score;
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_iFrags", score);
	}
}

// If game is not TF we will set player's death count
public SetDeaths(client, deaths)
{
	if (Game != GAME_TF)
	{
		SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
	}
}

// Get player's death count or return 0 if it is TF
public GetDeaths(client)
{
	if (Game == GAME_TF)
	{
		return 0;
	}
	else
	{
		return GetEntProp(client, Prop_Data, "m_iDeaths");
	}		
}


/*
public OnClientDisconnect(client)
{
	// Clearing temp values...
	justConnected[client] = true;
	onlyCash[client] = false;
	
	if (!client || isLAN || !save_scores || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	InsertScoreInDB(client, true);
	
	// Clearing TF scores
	TFScore[client] = SCORE_NOACTION;
	TFScoreMod[client] = SCOREMOD_NOACTION;
}*/

// Here we will put player's score into DB
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	justConnected[client] = true;
	onlyCash[client] = false;
	
	if (!client || isLAN || !save_scores || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	InsertScoreInDB(client);
	
	// Clearing TF scores
	TFScore[client] = SCORE_NOACTION;
	TFScoreMod[client] = SCOREMOD_NOACTION;
}


InsertScoreInDB(client)
{
	decl String:steamId[30];
	new cash = 0;
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	new frags = GetScore(client);
	new deaths = GetDeaths(client);
	
	if (Game == GAME_CS)
	{
		// If game is CS also save player's cash
		cash = GetCash(client);
		
		// Do not save scores if there are zero scores and default cash
		if (frags == 0 && deaths == 0 && cash == g_CSDefaultCash)
			return;
	}
	else
	{
		// Do not save scores if there are zero scores
		if (frags == 0 && deaths == 0)
			return;
	}

	InsertScoreQuery(steamId, frags, deaths, cash);
}

InsertScoreQuery(const String:steamId[], frags, deaths, cash)
{
	decl String:query[200];
	Format(query, sizeof(query), "INSERT OR REPLACE INTO savescores_scores VALUES ('%s', %d, %d, %d, %d);", steamId, frags, deaths, cash, GetTime());
	SQL_TQuery(g_hDB, EmptySQLCallback, query);
}

/*public Action:Timer_InsertScoreInDB(Handle:timer, any:hDatapack)
{
	ResetPack(hDatapack);
	decl String:steamId[30];
	ReadPackString(hDatapack, steamId, sizeof(steamId));
	new frags = ReadPackCell(hDatapack);
	new deaths = ReadPackCell(hDatapack);
	new cash = ReadPackCell(hDatapack);
	
	InsertScoreQuery(steamId, frags, deaths, cash);
	
	return Plugin_Handled
}*/

// Now we need get this information back...
public GetScoreFromDB(client)
{
	if (!IsClientInGame(client))
	{
		onlyCash[client] = false;
		return;
	}
	
	decl String:steamId[30];
	decl String:query[200];
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	Format(query, sizeof(query), "SELECT * FROM	savescores_scores WHERE steamId = '%s';", steamId);
	SQL_TQuery(g_hDB, SetPlayerScore, query, client);
}

public OnMapEnd()
{
	if (save_scores_forever && save_scores && !isLAN)
		SyncDB();
}

// ...and set player's score and cash if needed
public SetPlayerScore(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error: %s", error);
		onlyCash[client] = false;
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		onlyCash[client] = false;
		return;
	}
	
	if (!IsClientInGame(client))
	{
		onlyCash[client] = false;
		return;
	}
	
	// If tracking time < time from DB and client didn't played after connection then remove score
	if ((save_scores_tracking_time * 60 < (GetTime() - SQL_FetchInt(hndl,4))) && save_scores_tracking_time != 0 && !onlyCash[client])
	{
		if (!save_scores_forever)
		{
			RemoveScoreFromDB(client);
			return;
		}
	}

	new score = SQL_FetchInt(hndl,1);
	new deaths = SQL_FetchInt(hndl,2);
	
	// Restore player's score if client didn't played after connection
	if (save_scores && !onlyCash[client])
	{
		if (score != 0 || deaths != 0)
		{
			SetScore(client, score);
			SetDeaths(client, deaths);
			CPrintToChat(client, "{green}%t", "Score restored");
		}
	}
		
	// Restore client cash if this is CS
	if (Game == GAME_CS && save_scores_css_cash && save_scores)
	{
		new cash = SQL_FetchInt(hndl,3);
		SetCash(client, cash);
		CPrintToChat(client, "{green}%t", "Cash restored", cash);
	}
	
	onlyCash[client] = false;
	
	if (!save_scores_forever)
		RemoveScoreFromDB(client);
}


// Removes player's score from DB
public RemoveScoreFromDB(client)
{
	decl String:query[200];
	decl String:steamId[30];
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	Format(query, sizeof(query), "DELETE FROM savescores_scores WHERE steamId = '%s';", steamId);
	SQL_TQuery(g_hDB, EmptySQLCallback, query);
}

public EmptySQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("SQL Error: %s", error);
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

// Getting data from CVars and putting it into plugin's varibles
GetCVars()
{
	isLAN = GetConVarBool(cvar_lan);
	save_scores = GetConVarBool(cvar_save_scores);
	save_scores_tracking_time = GetConVarInt(cvar_save_scores_tracking_time);
	save_scores_forever = GetConVarBool(cvar_save_scores_forever);
	save_scores_allow_reset = GetConVarBool(cvar_save_scores_allow_reset);
	
	if (Game == GAME_CS)
	{
		save_scores_css_cash = GetConVarBool(cvar_save_scores_css_cash);
		save_scores_css_spec_cash = GetConVarBool(cvar_save_scores_css_spec_cash);
		g_CSDefaultCash = GetConVarInt(cvar_startmoney);
	}
	else if (Game == GAME_HL)
	{
		g_bHLTeamPlay = GetConVarBool(cvar_teamplay);
	}
	else if (Game == GAME_TF)
	{
		g_fBonusRoundTime = GetConVarFloat(cvar_bonusroundtime);
	}
}

public OnPluginEnd()
{
	if (LibraryExists("pluginautoupdate"))
		AutoUpdate_RemovePlugin();
}