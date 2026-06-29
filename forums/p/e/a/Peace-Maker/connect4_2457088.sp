#pragma semicolon 1
#pragma newdecls required

// TODO: Add API 

#define PLUGIN_VERSION "1.0"

// Message prefix colored and uncolored.
#define PREFIX "Connect 4 > "
#define CPREFIX "\x04Connect 4 \x01> \x03"

// Some fixed-width chars for a nice grid
#define SYMBOL_WALL_LEFT "▌"
#define SYMBOL_WALL_RIGHT "▐"
#define SYMBOL_WALL_BOTTOM "▀"
#define SYMBOL_SPACE "░"
#define SYMBOL_CURSOR "▀"
#define SYMBOL_PLAYER1 "█"
#define SYMBOL_PLAYER2 "▓"

// After how many calls to OnPlayerRunCmd should the selector 
// be moved when keeping a button pressed?
#define BUTTON_TICK_INTERVAL 20

// Different states of the single slots on the gamefield.
enum ESlotType {
	Slot_Empty = 0,
	Slot_Red,
	Slot_Blue
};

// Which direction to move the cursor.
enum EDirection {
	Direction_Left = 0,
	Direction_Right
};

// Maximal supported dimensions of the gamefield.
#define MAX_GAMEFIELD_X 8
#define MAX_GAMEFIELD_Y 8

// Options for Connect4Game::C4G_winner
#define WINNER_NONE -1
#define WINNER_DRAW 0

// Container of a Connect 4 game
enum Connect4Game {
	C4G_firstPlayer,  // client index of first player
	C4G_secondPlayer, // client index of second player
	C4G_winner,       // client index of the winner, 0 for draw and -1 when undecided yet.
	
	C4G_fieldSizeX,   // size of the game field in x direction
	C4G_fieldSizeY,   // size of the game field in y direction
	C4G_thinkTimerP1, // Game field display timer for player 1
	C4G_thinkTimerP2  // Game field display timer for player 2
};

// Used to pause games.
enum Connect4GameState {
	GS_index,                // Index of the game.
	GS_player1Id,           // userid of player 1
	GS_player2Id,           // userid of player 2
	GS_turn,                 // 1 if it's player 1's turn, 2 if it's player 2's.
	GS_selectorPositionP1,   // Position of player 1's cursor.
	GS_selectorPositionP2    // Position of player 2's cursor.
};

// TODO: Save last opponent as well maybe?
enum DisconnectedClientReference {
	DC_playerId,            // userid of the player leaving.
	DC_pausedGameArrayList   // Reference to the g_hClientPausedGames ArrayList of the player.
};

// Enough game fields for all players (even if there was a computer AI)
ESlotType g_GameField[MAXPLAYERS*MAXPLAYERS][MAX_GAMEFIELD_Y][MAX_GAMEFIELD_X];
int g_Connect4Game[MAXPLAYERS*MAXPLAYERS][Connect4Game];
ArrayList g_hPausedConnect4Games;

// Client states when playing a game of Connect 4
int g_iClientCurrentGame[MAXPLAYERS+1] = {-1,...};
ArrayList g_hClientPausedGames[MAXPLAYERS+1];
int g_iClientCurrentSelectorPosition[MAXPLAYERS+1] = {0,...};
bool g_bIsClientTurn[MAXPLAYERS+1] = {false,...};


// An array of DisconnectedClientReference enums to keep track of player's paused games on mapchange.
ArrayList g_hDisconnectedClientReference;

// Remember who the players last played against, to easily start a revenge.
int g_iLastOpponent[MAXPLAYERS+1] = {0,...};
bool g_bClientOpenChallenge[MAXPLAYERS+1][MAXPLAYERS+1];

// Ranking and stats
// Refresh the ranks every 30 seconds.
#define RANK_REFRESH_INTERVAL 30
#define PLAYERCOUNT_REFRESH_INTERVAL 300
enum PlayerStats {
	Stat_Loaded,
	Stat_Rank,
	Stat_RankRefreshTime, 
	Stat_Wins,
	Stat_Losses,
	Stat_Draws
};
int g_PlayerStats[MAXPLAYERS+1][PlayerStats];
int g_iRankedPlayersCount;
int g_iNextPlayerCountRefresh;

// SQLite and MySQL differ slightly in query syntax.
enum DatabaseDriver {
	Driver_None,
	Driver_MySQL,
	Driver_SQLite
};

DatabaseDriver g_DriverType;
Database g_hDatabase;

public Plugin myinfo =
{
	name = "Connect 4",
	author = "Peace-Maker",
	description = "Connect 4 game in a menu",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de"
};

public void OnPluginStart()
{
	ConVar hVersion = CreateConVar("sm_connect4_version", PLUGIN_VERSION, "Connect version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if(hVersion != null)
		hVersion.SetString(PLUGIN_VERSION);

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_disconnect", Event_OnPlayerDisconnect);
	
	g_hPausedConnect4Games = new ArrayList(view_as<int>(Connect4GameState));
	g_hDisconnectedClientReference = new ArrayList(view_as<int>(DisconnectedClientReference));
	
	RegConsoleCmd("sm_connect4", Cmd_Connect4, "Open the Connect 4 game's main menu.");
	RegConsoleCmd("sm_playc4", Cmd_Connect4, "Open the Connect 4 game's main menu.");
	
	if (SQL_CheckConfig("connect4"))
		Database.Connect(SQL_OnConnect, "connect4");
	else if (SQL_CheckConfig("storage-local"))
		Database.Connect(SQL_OnConnect, "storage-local");
	else
		LogError("Failed to connect to database. No configs for \"connect4\" or \"storage-local\" in the databases.cfg");
}

public Action Cmd_Connect4(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "Connect 4 > This command is for ingame players only.");
		return Plugin_Handled;
	}
	
	// TODO: Add option to do sm_playc4 <#userid|name|#steamid> to challenge that player right away.
	
	ShowMainMenu(client);
	return Plugin_Handled;
}

public void OnClientConnected(int client)
{
	// No need to do any of that for bots.
	if (IsFakeClient(client))
		return;
	
	// See if there is a paused game list cached for this player.
	ArrayList hPausedGames = PopPausedGameListForClient(GetClientUserId(client));
	g_hClientPausedGames[client] = hPausedGames;
	
	if (g_hClientPausedGames[client] != null)
	{
		// Update the client index in all his paused games now.
		int iSize = g_hClientPausedGames[client].Length;
		int iGameIndex, gameState[Connect4GameState];
		int iUserId = GetClientUserId(client);
		for (int i=0; i<iSize; i++)
		{
			iGameIndex = g_hClientPausedGames[client].Get(i);
			GetGameState(iGameIndex, gameState);
			if (iUserId == gameState[GS_player1Id])
				g_Connect4Game[iGameIndex][C4G_firstPlayer] = client;
			else if (iUserId == gameState[GS_player2Id])
				g_Connect4Game[iGameIndex][C4G_secondPlayer] = client;
		}
	}
}

// Allocate resources for new players
public void OnClientPutInServer(int client)
{
	// No need to do any of that for bots.
	if (IsFakeClient(client))
		return;

	if (!g_hClientPausedGames[client])
	{
		g_hClientPausedGames[client] = new ArrayList();
	}
}

// Load player stats from database.
public void OnClientAuthorized(int client, const char[] auth)
{
	// No need to do any of that for bots.
	if (IsFakeClient(client))
		return;
		
	if (!g_hDatabase)
		return;
	
	LoadPlayerStats(client);
}

/**
 * Stop the game, if one of the players leave the server.
 */
public void OnClientDisconnect(int client)
{
	// No need to do any of that for bots.
	if (IsFakeClient(client))
		return;
	
	// This player is gone. Should have played a revenge earlier.
	for (int i=1; i<=MaxClients; i++)
	{
		if (g_iLastOpponent[i] == client)
			g_iLastOpponent[i] = 0;
		
		g_bClientOpenChallenge[i][client] = false;
		g_bClientOpenChallenge[client][i] = false;
	}
	
	g_iLastOpponent[client] = 0;
	
	if (IsClientInConnect4Game(client))
	{
		// This player is gone now. Pause the game for now, if this is a mapchange.
		int iGameIndex = g_iClientCurrentGame[client];
		PauseConnect4Game(iGameIndex);
	}
	
	// First player disconnected before getting ingame.
	if (!g_hClientPausedGames[client])
		return;
	
	// Remove this client index from all paused games as it might point to someone else soon.
	int iSize = g_hClientPausedGames[client].Length;
	int iGameIndex;
	for (int i=0; i<iSize; i++)
	{
		iGameIndex = g_hClientPausedGames[client].Get(i);
		if (g_Connect4Game[iGameIndex][C4G_firstPlayer] == client)
			g_Connect4Game[iGameIndex][C4G_firstPlayer] = 0;
		if (g_Connect4Game[iGameIndex][C4G_secondPlayer] == client)
			g_Connect4Game[iGameIndex][C4G_secondPlayer] = 0;
	}
	
	// Save away the reference to the paused games.
	int disconnectedRef[DisconnectedClientReference];
	disconnectedRef[DC_playerId] = GetClientUserId(client);
	disconnectedRef[DC_pausedGameArrayList] = view_as<int>(g_hClientPausedGames[client]);
	g_hDisconnectedClientReference.PushArray(disconnectedRef[0], view_as<int>(DisconnectedClientReference));
	
	// The next player on that index might need a new array.
	g_hClientPausedGames[client] = null;
}

// Fires when the player actually disconnected and not on reconnect or mapchanges.
public void Event_OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int iUserId = event.GetInt("userid");
	int client = GetClientOfUserId(iUserId);
	
	// No need to do any of that for bots.
	if (client > 0 && IsFakeClient(client))
		return;
	
	ArrayList hPausedGames = PopPausedGameListForClient(iUserId);
	
	// First player disconnected before getting ingame.
	if (!hPausedGames)
	{
		ResetStatsCache(client);
		return;
	}
	
	// Clear out any paused game the player might have had.
	int iSize;
	while ((iSize = hPausedGames.Length) > 0)
	{
		int iGameIndex = hPausedGames.Get(iSize - 1);
		int iOpponent = GetOpponent(iGameIndex, client);
		RemoveGameState(iGameIndex);
		RemovePausedGameIndex(hPausedGames, iGameIndex);
		
		g_Connect4Game[iGameIndex][C4G_winner] = iOpponent;
		StopConnect4Game(iGameIndex);
		
		if (IsClientInGame(iOpponent))
			PrintToChat(iOpponent, "%s%N disconnected while having a game against you paused. YOU WIN!", CPREFIX, client);
	}
	
	hPausedGames.Close();
	
	ResetStatsCache(client);
}

void ResetStatsCache(int client)
{
	// Reset cached stats
	g_PlayerStats[client][Stat_Loaded] = false;
	g_PlayerStats[client][Stat_Rank] = 0;
	g_PlayerStats[client][Stat_RankRefreshTime] = 0;
	g_PlayerStats[client][Stat_Wins] = 0;
	g_PlayerStats[client][Stat_Losses] = 0;
	g_PlayerStats[client][Stat_Draws] = 0;
}

// Refreeze players on respawn
public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;
	
	if (!IsClientInConnect4Game(client))
		return;
	
	// If this guy is currently playing, freeze him again.
	SetEntityMoveType(client, MOVETYPE_NONE);
}

/**
 * SQL ranking handling
 */
public void SQL_OnConnect(Database db, const char[] error, any data)
{
	if (!db)
	{
		LogError("Error connecting to database. Ranking disabled. Error: %s", error);
		return;
	}
	
	// See which database system is backing us
	char sDriverIdent[32];
	db.Driver.GetIdentifier(sDriverIdent, sizeof(sDriverIdent));
	if (StrEqual(sDriverIdent, "mysql", false))
	{
		g_DriverType = Driver_MySQL;
		db.SetCharset("utf8");
	}
	else if (StrEqual(sDriverIdent, "sqlite", false))
	{
		g_DriverType = Driver_SQLite;
		db.SetCharset("utf8");
	}
	else
	{
		db.Close();
		LogError("Unsupported database driver: %s", sDriverIdent);
		return;
	}
	
	// Save the database handle for later use.
	g_hDatabase = db;
	
	// Make sure the tables are created using the correct charset, if the database was created with something else than utf8 as default.
	char sDefaultCharset[32];
	if(g_DriverType == Driver_MySQL)
	{
		strcopy(sDefaultCharset, sizeof(sDefaultCharset), " DEFAULT CHARSET=utf8");
	}
	
	// Create the table
	char sQuery[512];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS connect4_stats (accountid INT NOT NULL PRIMARY KEY, name VARCHAR(64) NOT NULL, wins INT DEFAULT 0, losses INT DEFAULT 0, draws INT DEFAULT 0)%s", sDefaultCharset);
	db.Query(SQL_DoNothing, sQuery);
	
	// Update any already connected players stats when lateloading.
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !IsClientAuthorized(i))
			continue;
		
		LoadPlayerStats(i);
	}
}

public void SQL_DoNothing(Database db, DBResultSet results, const char[] error, any data)
{
	if (!results)
		LogError("Error executing query: %s", error);
}

void LoadPlayerStats(int client)
{
	// Don't load again.
	if (g_PlayerStats[client][Stat_Loaded])
		return;
	
	int iAccountId = GetSteamAccountID(client);
	if (!iAccountId)
		return;
	
	char sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT wins, losses, draws FROM connect4_stats WHERE accountid = %d", iAccountId);
	g_hDatabase.Query(SQL_LoadStats, sQuery, GetClientUserId(client));
}

public void SQL_LoadStats(Database db, DBResultSet results, const char[] error, any userid)
{
	if (!results)
	{
		LogError("Error fetching player stats: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	// Player disconnected mid-query.
	if (!client)
		return;
	
	// Player not in database yet. He should play a game of Connect 4!
	if (!results.FetchRow())
	{
		g_PlayerStats[client][Stat_Loaded] = true;
		return;
	}
	
	// SELECT wins, losses, draws
	g_PlayerStats[client][Stat_Wins] = results.FetchInt(0);
	g_PlayerStats[client][Stat_Losses] = results.FetchInt(1);
	g_PlayerStats[client][Stat_Draws] = results.FetchInt(2);
	g_PlayerStats[client][Stat_Loaded] = true;
	
	// Fetch the rank.
	FetchPlayerRank(client);
}

void FetchPlayerRank(int client)
{
	// No database - no stats.
	if (!g_hDatabase)
		return;

	// See if we should update the player count as well now
	UpdateRankedPlayerCount();
	
	// We just fetched the rank, don't do it again now.
	if (g_PlayerStats[client][Stat_RankRefreshTime] > 0 && g_PlayerStats[client][Stat_RankRefreshTime] > GetTime())
		return;
	
	// Set the time right away, so we know the query is running and don't send one twice.
	g_PlayerStats[client][Stat_RankRefreshTime] = GetTime() + RANK_REFRESH_INTERVAL;
	
	char sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT COUNT(*) AS rank FROM connect4_stats WHERE wins > %d OR (wins = %d AND (draws > %d OR (draws = %d AND losses < %d)))", g_PlayerStats[client][Stat_Wins], g_PlayerStats[client][Stat_Wins], g_PlayerStats[client][Stat_Draws], g_PlayerStats[client][Stat_Draws], g_PlayerStats[client][Stat_Losses]);
	g_hDatabase.Query(SQL_LoadRank, sQuery, GetClientUserId(client));
}

public void SQL_LoadRank(Database db, DBResultSet results, const char[] error, any userid)
{
	if (!results)
	{
		LogError("Error fetching player rank: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(userid);
	// Player disconnected mid-query.
	if (!client)
		return;

	// Should never happen, since there's at least the player itself in the database.
	if (!results.FetchRow())
		return;
	
	// SELECT COUNT(*) AS rank
	g_PlayerStats[client][Stat_Rank] = results.FetchInt(0) + 1;
	g_PlayerStats[client][Stat_RankRefreshTime] = GetTime() + RANK_REFRESH_INTERVAL;
}

void UpdateRankedPlayerCount()
{
	// Wait until we fetch the count again.
	if (g_iNextPlayerCountRefresh > 0 && g_iNextPlayerCountRefresh > GetTime())
		return;
	
	g_iNextPlayerCountRefresh = GetTime() + PLAYERCOUNT_REFRESH_INTERVAL;
	
	char sQuery[64];
	Format(sQuery, sizeof(sQuery), "SELECT COUNT(*) AS player_num FROM connect4_stats");
	g_hDatabase.Query(SQL_LoadRankedPlayersCount, sQuery);
}

public void SQL_LoadRankedPlayersCount(Database db, DBResultSet results, const char[] error, any userid)
{
	if (!results)
	{
		LogError("Error fetching player rank: %s", error);
		return;
	}

	// Should never happen
	if (!results.FetchRow())
		return;
	
	// SELECT COUNT(*) AS rank
	g_iRankedPlayersCount = results.FetchInt(0);
	g_iNextPlayerCountRefresh = GetTime() + PLAYERCOUNT_REFRESH_INTERVAL;
}

// After a game, save the stats into the database.
void UpdatePlayersStats(int iPlayer1, int iPlayer2)
{
	char sName[MAX_NAME_LENGTH], sEscapedName[MAX_NAME_LENGTH*2 + 1];
	char sPlayerStats[512];
	
	// Add info of first player
	int iAccountId = GetSteamAccountID(iPlayer1);
	if (iAccountId > 0 && g_PlayerStats[iPlayer1][Stat_Loaded])
	{
		GetClientName(iPlayer1, sName, sizeof(sName));
		g_hDatabase.Escape(sName, sEscapedName, sizeof(sEscapedName));
		Format(sPlayerStats, sizeof(sPlayerStats), "(%d, '%s', %d, %d, %d)", iAccountId, sEscapedName, g_PlayerStats[iPlayer1][Stat_Wins], g_PlayerStats[iPlayer1][Stat_Losses], g_PlayerStats[iPlayer1][Stat_Draws]);
	}
	
	// Add info of second player
	iAccountId = GetSteamAccountID(iPlayer2);
	if (iAccountId > 0 && g_PlayerStats[iPlayer2][Stat_Loaded])
	{
		if (strlen(sPlayerStats) > 0)
			StrCat(sPlayerStats, sizeof(sPlayerStats), ", ");
	
		GetClientName(iPlayer2, sName, sizeof(sName));
		g_hDatabase.Escape(sName, sEscapedName, sizeof(sEscapedName));
		Format(sPlayerStats, sizeof(sPlayerStats), "%s(%d, '%s', %d, %d, %d)", sPlayerStats, iAccountId, sEscapedName, g_PlayerStats[iPlayer2][Stat_Wins], g_PlayerStats[iPlayer2][Stat_Losses], g_PlayerStats[iPlayer2][Stat_Draws]);
	}
	
	// Both players aren't loaded or authed yet. No need to query.
	if (strlen(sPlayerStats) == 0)
		return;
	
	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "REPLACE INTO connect4_stats (accountid, name, wins, losses, draws) VALUES %s ON CONFLICT REPLACE", sPlayerStats);
	g_hDatabase.Query(SQL_DoNothing, sQuery);
	
	// Fetch rank right away
	g_PlayerStats[iPlayer1][Stat_RankRefreshTime] = 0;
	g_PlayerStats[iPlayer2][Stat_RankRefreshTime] = 0;
}

/**
 * Handle game input to move the selector and drop a disc.
 */
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Keep track of buttons and how long they've already been pressed.
	static int s_oldButtons[MAXPLAYERS+1];
	static int s_holdTicks[MAXPLAYERS+1];
	
	if (!IsClientInConnect4Game(client))
		return Plugin_Continue;
	
	int iGameIndex = g_iClientCurrentGame[client];
	
	// Player started pressing jump
	if (g_bIsClientTurn[client] && buttons & IN_USE > 0 && s_oldButtons[client] & IN_USE == 0)
	{
		// Drop the disc at the selector's position
		int iDropRow = DropDisc(client);
		if (iDropRow != -1)
		{
			// Player has done his move. It's the opponent's turn.
			int iOpponent = GetOpponent(iGameIndex, client);
			
			// Now it's the other player's turn.
			g_bIsClientTurn[client] = false;
			g_bIsClientTurn[iOpponent] = true;
			
			// There's no more room for any discs. This is a draw.
			if (CheckDrawCondition(iGameIndex))
			{
				g_Connect4Game[iGameIndex][C4G_winner] = WINNER_DRAW;
				PrintToChat(client, "%sDRAW.", CPREFIX);
				PrintToChat(iOpponent, "%sDRAW.", CPREFIX);
			}
			// Someone got four connected!
			else if (CheckWinCondition(client, iDropRow))
			{
				g_Connect4Game[iGameIndex][C4G_winner] = client;
				PrintToChat(client, "%sYOU WON! %N LOSE.", CPREFIX, iOpponent);
				PrintToChat(iOpponent, "%s%N WON! YOU LOSE.", CPREFIX, client);
			}
			
			// Draw the new disc on the field.
			RedrawGameField(iGameIndex);
			
			// Game is over..
			if (g_Connect4Game[iGameIndex][C4G_winner] != WINNER_NONE)
				StopConnect4Game(iGameIndex);
		}
	}
	// Don't know where to go when pressing both buttons at once.
	else if (buttons & (IN_MOVELEFT|IN_MOVERIGHT) == (IN_MOVELEFT|IN_MOVERIGHT))
	{
		buttons &= ~(IN_MOVELEFT|IN_MOVERIGHT);
		s_holdTicks[client] = 0;
	}
	// Pressing left or right
	else if (buttons & (IN_MOVELEFT|IN_MOVERIGHT) > 0)
	{
		EDirection direction = (buttons & IN_MOVELEFT) > 0 ? Direction_Left : Direction_Right;
		int iButtonBit = direction == Direction_Left ? IN_MOVELEFT : IN_MOVERIGHT;
		
		// Just started pressing the button
		if ((s_oldButtons[client] & iButtonBit) == 0
		// or kept holding it long enough.
			|| s_holdTicks[client] > BUTTON_TICK_INTERVAL)
		{
			// Try to move the cursor in the desired direction.
			if (MoveCursor(client, direction))
				RedrawGameField(iGameIndex); // Only redraw, if the cursor wasn't at the edge of the screen.
			
			// Reset the holding ticks to wait for the next interval, in case the player keeps pressing the button.
			s_holdTicks[client] = 0;
		}
		
		// Remember we're holding that button for some time now.
		s_holdTicks[client]++;
	}
	else
	{
		// Not pressing left or right (anymore)
		s_holdTicks[client] = 0;
	}
	
	// Remember the buttons of this frame at the end, so we know what buttons have been pressed
	// when OnPlayerRunCmd is called the next time.
	s_oldButtons[client] = buttons;
	
	return Plugin_Continue;
}

/**
 * Menu handling
 */
void ShowMainMenu(int client)
{
	// Make sure we stop any current game.
	if (IsClientInConnect4Game(client))
	{
		int iGameIndex = g_iClientCurrentGame[client];
		int iOpponent = GetOpponent(iGameIndex, client);
		PauseConnect4Game(iGameIndex);
		
		PrintToChat(iOpponent, "%s%N paused the game.", CPREFIX, client);
		PrintToChat(client, "%sPausing game against %N.", CPREFIX, iOpponent);
	}

	Menu hMenu = new Menu(Menu_HandleMainMenu);
	hMenu.SetTitle("%sMain Menu", PREFIX);
	hMenu.ExitButton = true;
	
	hMenu.AddItem("start", "Start a new game against a player");
	
	// Show an option to challenge the last opponent instantly
	// if the game against him isn't currently paused.
	if (g_iLastOpponent[client] > 0 && GetPlayersPausedGameIndex(client, g_iLastOpponent[client]) == -1)
	{
		char sBuffer[128];
		// Don't interrupt him if he's in a different game currently.
		if (IsClientInConnect4Game(g_iLastOpponent[client]))
		{
			Format(sBuffer, sizeof(sBuffer), "Play again against %N [Already playing]", g_iLastOpponent[client]);
			hMenu.AddItem("playagain", sBuffer, ITEMDRAW_DISABLED);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "Play again against %N", g_iLastOpponent[client]);
			hMenu.AddItem("playagain", sBuffer);
		}
	}
	
	// Only show the stats option, if the player is in the database.
	FetchPlayerRank(client);
	if (g_PlayerStats[client][Stat_Rank] > 0)
		hMenu.AddItem("stats", "Stats\n");
	
	// List paused games
	char sBuffer[128];
	int iPausedGameCount = g_hClientPausedGames[client].Length;
	if (iPausedGameCount > 0)
	{
		char sGameIndex[12];
		sGameIndex[0] = 'R'; // 'R' like Resume
		
		// Leave some space.
		hMenu.AddItem("", "", ITEMDRAW_SPACER);
		
		int iGameIndex, iOpponent, iMenuDrawFlags;
		for (int i=0; i<iPausedGameCount; i++)
		{
			iGameIndex = g_hClientPausedGames[client].Get(i);
			iOpponent = GetOpponent(iGameIndex, client);
			
			// This player is just in the process of reconnecting.
			if (!iOpponent)
				continue;
			
			Format(sBuffer, sizeof(sBuffer), "Resume game against %N", iOpponent);
			// Consider mapchanges and one player is faster than the other.
			if (!IsClientInGame(iOpponent))
			{
				Format(sBuffer, sizeof(sBuffer), "%s [Reconnecting]", sBuffer);
				iMenuDrawFlags = ITEMDRAW_DISABLED;
			}
			else if (IsClientInConnect4Game(iOpponent))
			{
				Format(sBuffer, sizeof(sBuffer), "%s [Already playing]", sBuffer);
				iMenuDrawFlags = ITEMDRAW_DISABLED;
			}
			else
			{
				iMenuDrawFlags = ITEMDRAW_DEFAULT;
			}
			
			IntToString(iGameIndex, sGameIndex[1], sizeof(sGameIndex) - 1);
			hMenu.AddItem(sGameIndex, sBuffer, iMenuDrawFlags);
		}
	}
	else
	{
		// Add some introduction to controls.
		hMenu.AddItem("", "", ITEMDRAW_SPACER);
		hMenu.AddItem("", "Use your walking keys to move the cursor on the top left and right.", ITEMDRAW_DISABLED);
		hMenu.AddItem("", "Press use to put your disc in the selected column.", ITEMDRAW_DISABLED);
	}
	
	// List all open unanswered challenges.
	char sUserId[16];
	sUserId[0] = 'C'; // 'C' like Challenge
	bool bAddedPlayer = false;
	int iMenuDrawFlags;
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		// This player wanted to play with out or the other way around.
		if (g_bClientOpenChallenge[client][i])
		{
			// Just show the "header" once
			if (!bAddedPlayer)
				hMenu.AddItem("", "Open challenges:", ITEMDRAW_DISABLED);
			
			IntToString(GetClientUserId(i), sUserId[1], sizeof(sUserId) - 1);
			Format(sBuffer, sizeof(sBuffer), "Against %N", i);
			
			if (IsClientInConnect4Game(i))
			{
				Format(sBuffer, sizeof(sBuffer), "%s [Already playing]", sBuffer);
				iMenuDrawFlags = ITEMDRAW_DISABLED;
			}
			else
				iMenuDrawFlags = ITEMDRAW_DEFAULT;
			
			hMenu.AddItem(sUserId, sBuffer, iMenuDrawFlags);
			
			bAddedPlayer = true;
		}
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HandleMainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		menu.Close();
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		
		// Begin a new Connect 4 game by first choosing the opponent.
		if (StrEqual(sInfo, "start"))
		{
			// Show a list of possible opponents
			ShowPlayerListMenu(param1);
		}
		// Play against the last opponent again.
		else if (StrEqual(sInfo, "playagain"))
		{
			int iOpponent = g_iLastOpponent[param1];
			if (!iOpponent)
			{
				PrintToChat(param1, "%sYour last opponent left the game.", CPREFIX);
				ShowMainMenu(param1);
				return;
			}
			
			if (IsClientInConnect4Game(iOpponent))
			{
				PrintToChat(param1, "%s%N is already in a Connect 4 game.", CPREFIX, iOpponent);
				ShowMainMenu(param1);
				return;
			}
			
			// Challenge him again
			ShowChallengeMenu(param1, iOpponent);
		}
		// Show current stats.
		else if (StrEqual(sInfo, "stats"))
		{
			ShowStatsMenu(param1);
		}
		// Resume a game
		else if (sInfo[0] == 'R')
		{
			int iGameIndex = StringToInt(sInfo[1]);
			if (!IsValidConnect4Game(iGameIndex))
			{
				PrintToChat(param1, "%sThat game was removed. Your opponent left.");
				ShowMainMenu(param1);
				return;
			}
			
			int iOpponent = GetOpponent(iGameIndex, param1);
			
			if (!IsClientInGame(iOpponent))
			{
				PrintToChat(param1, "%s%N opponent is currently reconnecting.", CPREFIX, iOpponent);
				ShowMainMenu(param1);
				return;
			}
			
			if (IsClientInConnect4Game(iOpponent))
			{
				PrintToChat(param1, "%s%N is already in a Connect 4 game.", CPREFIX, iOpponent);
				ShowMainMenu(param1);
				return;
			}
			
			// Ask the player to resume the game now.
			ShowResumeGameMenu(param1, iOpponent, iGameIndex);
		}
		// Showing the challenge when missed previously.
		else if (sInfo[0] == 'C')
		{
			int iOpponent = GetClientOfUserId(StringToInt(sInfo[1]));
			
			// Opponent left
			if (!iOpponent || !IsClientInGame(iOpponent))
			{
				PrintToChat(param1, "%sYour opponent has left the game.", CPREFIX);
				return;
			}
			
			// Opponent got into a different game
			if (IsClientInConnect4Game(iOpponent))
			{
				PrintToChat(param1, "%s%N already started a game with someone else now.", CPREFIX, iOpponent);
				return;
			}
			
			ShowChallengeMenu(param1, iOpponent);
		}
	}
}

// Show a menu of possible opponents
void ShowPlayerListMenu(int client)
{
	Menu hSubMenu = new Menu(Menu_HandlePlayerList);
	hSubMenu.SetTitle("%sChoose Opponent", PREFIX);
	hSubMenu.ExitBackButton = true;
	
	char sUserId[12], sDisplay[MAX_NAME_LENGTH*2];
	bool bAddedPlayer;
	int iDisplayFlags;
	for (int i=1; i<=MaxClients; i++)
	{
		// Only real players are allowed and you can't play against yourself.
		if(IsClientInGame(i) && !IsFakeClient(i) && i != client)
		{
			IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
			Format(sDisplay, sizeof(sDisplay), "%N (#%s)", i, sUserId);
			
			// Show a notice, that the player already sent a challenge to that guy
			if (g_bClientOpenChallenge[client][i])
			{
				Format(sDisplay, sizeof(sDisplay), "%s [Challenged]", sDisplay);
			}
			
			// Show notice about paused game against this player.
			if (GetPlayersPausedGameIndex(client, i) != -1)
			{
				Format(sDisplay, sizeof(sDisplay), "%s [Resume]", sDisplay);
			}
			
			// If the player is already playing Connect4 with some other player, 
			// still show him in the menu, but greyed out.
			if (IsClientInConnect4Game(i))
			{
				Format(sDisplay, sizeof(sDisplay), "%s [Already playing]", sDisplay);
				iDisplayFlags = ITEMDRAW_DISABLED;
			}
			else
			{
				iDisplayFlags = ITEMDRAW_DEFAULT;
			}
			
			hSubMenu.AddItem(sUserId, sDisplay, iDisplayFlags);
			bAddedPlayer = true;
		}
	}
	
	// No eligible players on the server.
	// Return to the main menu.
	if(!bAddedPlayer)
	{
		PrintToChat(client, "%sNo players available.", CPREFIX);
		hSubMenu.Close();
		ShowMainMenu(client);
	}
	else
		hSubMenu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HandlePlayerList(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		menu.Close();
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			ShowMainMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		
		int iUserId = StringToInt(sInfo);
		int iOpponent = GetClientOfUserId(iUserId);
		
		// Make sure the menu wasn't open too long
		if (!iOpponent || !IsClientInGame(iOpponent))
		{
			PrintToChat(param1, "%sThat player left the server.", CPREFIX);
			ShowPlayerListMenu(param1);
		}
		// And the opponent didn't start a game with someone else.
		else if (IsClientInConnect4Game(iOpponent))
		{
			PrintToChat(param1, "%s%N is already in a Connect 4 game.", CPREFIX, iOpponent);
			ShowPlayerListMenu(param1);
		}
		else
		{
			// Show resume menu, if there is a paused game.
			int iGameIndex = GetPlayersPausedGameIndex(param1, iOpponent);
			if (iGameIndex != -1)
				ShowResumeGameMenu(param1, iOpponent, iGameIndex);
			else
				// Invite the opponent for a game!
				ShowChallengeMenu(param1, iOpponent);
		}
	}
}

// Show a menu to challenge another player for a game of Connect 4
// with options to accept or decline.
void ShowChallengeMenu(int iAsker, int iOpponent)
{
	Menu hSubMenu = new Menu(Menu_HandleInvitation);
	hSubMenu.SetTitle("%N challenged you to play Connect 4 with him!", iAsker);
	hSubMenu.ExitButton = false;
	
	// Creep two infos in there. First if he accepted or not and secondly who challenged him.
	char sInfo[32];
	int iMyUserId = GetClientUserId(iAsker);
	Format(sInfo, sizeof(sInfo), "1%d", iMyUserId);
	hSubMenu.AddItem(sInfo, "Play Connect 4");
	Format(sInfo, sizeof(sInfo), "0%d", iMyUserId);
	hSubMenu.AddItem(sInfo, "Not interested");
	
	// Maybe it doesn't fit now, but keep the challenge open
	Format(sInfo, sizeof(sInfo), "2%d", iMyUserId);
	hSubMenu.AddItem(sInfo, "Not now, I'm busy");
	
	// Add some introduction to controls and rules.
	hSubMenu.AddItem("", "", ITEMDRAW_SPACER);
	hSubMenu.AddItem("", "Use your walking keys to move the cursor on the top left and right.", ITEMDRAW_DISABLED);
	hSubMenu.AddItem("", "Press use to put your disc in the selected column.", ITEMDRAW_DISABLED);
	hSubMenu.AddItem("", "", ITEMDRAW_SPACER);
	hSubMenu.AddItem("", "Try to get four in a row either horizontally, vertically or diagonally.", ITEMDRAW_DISABLED);
	
	// Don't leave that menu open forever.
	hSubMenu.Display(iOpponent, 15);
	
	// Remember this open challenge to show it in the main menu
	g_bClientOpenChallenge[iAsker][iOpponent] = true;
	g_bClientOpenChallenge[iOpponent][iAsker] = true;
	
	PrintToChat(iAsker, "%sYou sent a challenge to %N.", CPREFIX, iOpponent);
	PrintToChat(iOpponent, "%s%N challenged you to play Connect 4!", CPREFIX, iAsker);
}

public int Menu_HandleInvitation(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		// Keep a message in the chat if the player missed it
		PrintToChat(param1, "%sYou missed a challenge.. Type !connect4 to see open challenges.", CPREFIX);
	}
	else if (action == MenuAction_Select)
	{
		// Extract both infos from the menu string.
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		// The first character is either 0 or 1 depending on 
		// if the client accepted the challenge or not.
		// It is 2 when the client delayed the decision.
		bool bAccepted = sInfo[0] == '1';
		bool bDelayed = sInfo[0] == '2';
		// The rest of it is just the userid of the client started the challenge.
		int iAsker = GetClientOfUserId(StringToInt(sInfo[1]));
		
		// Asker left
		if (iAsker == 0 || !IsClientInGame(iAsker))
		{
			if (bAccepted)
				PrintToChat(param1, "%sYour opponent has left the game.", CPREFIX);
			return;
		}
		
		// Player wants to play!
		if (bAccepted)
		{
			// Asker got into a different game
			if (IsClientInConnect4Game(iAsker))
			{
				PrintToChat(param1, "%s%N already started a game with someone else now.", CPREFIX, iAsker);
				PrintToChat(iAsker, "%s%N accepted your challenge, but you're in a different game now.", CPREFIX, param1);
				return;
			}
			
			// START CONNECT 4!!!1
			PrintToChat(iAsker, "%s%N accepted your challenge!", CPREFIX, param1);
			PrintToChat(param1, "%sYou accepted %N's challenge!", CPREFIX, iAsker);
			StartConnect4Game(iAsker, param1);
		}
		// Player doesn't want to play now. Keep the challenge open in the main menu.
		else if (bDelayed)
		{
			PrintToChat(iAsker, "%s%N is busy and might come back to you later.", CPREFIX, param1);
			PrintToChat(param1, "%sYou dismissed %N's challenge. Type !connect4 to see open challenges.", CPREFIX, iAsker);
		}
		// Player denied the request.
		else
		{
			// This challenge is going nowhere.
			g_bClientOpenChallenge[param1][iAsker] = false;
			g_bClientOpenChallenge[iAsker][param1] = false;
		
			PrintToChat(iAsker, "%s%N declined your challenge.", CPREFIX, param1);
			PrintToChat(param1, "%sYou declined %N's challege.", CPREFIX, iAsker);
		}
	}
}

void ShowStatsMenu(int client)
{
	Menu hMenu = new Menu(Menu_HandleStatsMenu);
	hMenu.SetTitle("%sYour statistics", PREFIX);
	hMenu.ExitBackButton = true;
	
	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "Wins: %d", g_PlayerStats[client][Stat_Wins]);
	hMenu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	Format(sBuffer, sizeof(sBuffer), "Losses: %d", g_PlayerStats[client][Stat_Losses]);
	hMenu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	Format(sBuffer, sizeof(sBuffer), "Draws: %d", g_PlayerStats[client][Stat_Draws]);
	hMenu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	
	if (g_PlayerStats[client][Stat_Rank] > 0)
	{
		hMenu.AddItem("", "", ITEMDRAW_SPACER);
		Format(sBuffer, sizeof(sBuffer), "Rank: %d/%d", g_PlayerStats[client][Stat_Rank], g_iRankedPlayersCount);
		hMenu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	// Make sure the database is available.
	if (g_hDatabase != null)
	{	
		hMenu.AddItem("", "", ITEMDRAW_SPACER);
		hMenu.AddItem("top10", "Display Top 10");
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HandleStatsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		menu.Close();
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			ShowMainMenu(param1);
	}
	else if (action == MenuAction_Select)
	{
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		
		if (StrEqual(sInfo, "top10"))
		{
			FetchTop10(param1);
		}
	}
}

void FetchTop10(int client)
{
	char sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT name, wins, losses, draws FROM connect4_stats ORDER BY wins DESC, draws DESC, losses ASC LIMIT 10");
	g_hDatabase.Query(SQL_GetTop10, sQuery, GetClientUserId(client));
}

public void SQL_GetTop10(Database db, DBResultSet results, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client)
		return;
	
	if (!db)
	{
		LogError("Failed to fetch top 10: %s", error);
		if (IsClientInGame(client))
			ShowStatsMenu(client);
		return;
	}
	
	// TODO: Switch to panel with ITEMDRAW_RAWLINE to avoid the display of the menu numbers.
	Menu hMenu = new Menu(Menu_HandleTop10Menu);
	hMenu.SetTitle("%sTop 10\n<name> - (wins / losses / draws)\n", PREFIX);
	hMenu.ExitBackButton = true;
	
	// SELECT name, wins, losses, draws
	int iRank = 1;
	char sBuffer[256], sName[MAX_NAME_LENGTH];
	while (results.MoreRows)
	{
		if (!results.FetchRow())
			continue;
		
		results.FetchString(0, sName, sizeof(sName));
		Format(sBuffer, sizeof(sBuffer), "%d. %s - (%d / %d / %d)", iRank, sName, results.FetchInt(1), results.FetchInt(2), results.FetchInt(3));
		hMenu.AddItem("", sBuffer, ITEMDRAW_DISABLED);
		
		iRank++;
	}
	
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_HandleTop10Menu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		menu.Close();
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			ShowStatsMenu(param1);
	}
}

void ShowResumeGameMenu(int iAsker, int iOpponent, int iGameIndex)
{
	Menu hSubMenu = new Menu(Menu_HandleResumeGame);
	hSubMenu.SetTitle("%N wants to resume your Connect 4 game!", iAsker);
	hSubMenu.ExitButton = false;
	
	// Creep two infos in there. First if he accepted or not and secondly which game to resume.
	char sInfo[32];
	Format(sInfo, sizeof(sInfo), "1%d", iGameIndex);
	hSubMenu.AddItem(sInfo, "Resume previous game");
	Format(sInfo, sizeof(sInfo), "0%d", iGameIndex);
	hSubMenu.AddItem(sInfo, "Not now, I'm busy");
	
	// Add some introduction to controls and rules.
	hSubMenu.AddItem("", "", ITEMDRAW_SPACER);
	hSubMenu.AddItem("", "Use your walking keys to move the cursor on the top left and right.", ITEMDRAW_DISABLED);
	hSubMenu.AddItem("", "Press use to put your disc in the selected column.", ITEMDRAW_DISABLED);
	hSubMenu.AddItem("", "", ITEMDRAW_SPACER);
	hSubMenu.AddItem("", "Try to get four in a row either horizontally, vertically or diagonally.", ITEMDRAW_DISABLED);
	
	// Don't leave that menu open forever.
	hSubMenu.Display(iOpponent, 15);
	
	PrintToChat(iAsker, "%sYou sent a request to %N to resume your paused game.", CPREFIX, iOpponent);
	PrintToChat(iOpponent, "%s%N wants to resume your paused Connect 4 game!", CPREFIX, iAsker);
}

public int Menu_HandleResumeGame(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		// Extract both infos from the menu string.
		char sInfo[32];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		// The first character is either 0 or 1 depending on 
		// if the client wants to resume the game or not.
		bool bAccepted = sInfo[0] == '1';
		// The rest of it is the game index.
		int iGameIndex = StringToInt(sInfo[1]);
		if (!IsValidConnect4Game(iGameIndex))
		{
			PrintToChat(param1, "%sYour opponent left the game.", CPREFIX);
			return;
		}
		
		int iAsker = GetOpponent(iGameIndex, param1);
		
		// Player wants to play!
		if (bAccepted)
		{
			// Asker left
			if (!iAsker || !IsClientInGame(iAsker))
			{
				PrintToChat(param1, "%sYour opponent has left the game.", CPREFIX);
				return;
			}
			
			// Asker got into a different game
			if (IsClientInConnect4Game(iAsker))
			{
				PrintToChat(param1, "%s%N already started a game with someone else now.", CPREFIX, iAsker);
				PrintToChat(iAsker, "%s%N wants to resume your game as well, but you're in a different game now.", CPREFIX, param1);
				return;
			}
			
			// Restart Connect 4
			PrintToChat(iAsker, "%sResuming your game against %N!", CPREFIX, param1);
			PrintToChat(param1, "%sResuming your game against %N!", CPREFIX, iAsker);
			ResumeConnect4Game(iGameIndex);
		}
		// Player doesn't want to play now.
		else if (iAsker && IsClientInGame(iAsker))
		{
			PrintToChat(iAsker, "%s%N is busy and might come back to you later.", CPREFIX, param1);
			PrintToChat(param1, "%sYou delayed the game with %N further.", CPREFIX, iAsker);
		}
	}
}

// Some horrible macros to make the gamefield drawing code in Timer_GameThink easier to read.
#define BUFFER_X_SIZE (MAX_GAMEFIELD_X*20)
#define START_NEW_LINE(%1) %1 = 0
#define INSERT_SYMBOL(%1,%2) InsertMultibyteChar(sGameLine, %1, BUFFER_X_SIZE - %1, %2)
#define FINISH_LINE(%1) sGameLine[%1] = '\0'

// Insert some characters into a string while supporting multi-byte utf8 characters
// while not adding a null-terminator.
// This is all just done to avoid calling Format all over. Don't know if it's worth it, but now it's here.
void InsertMultibyteChar(char[] str, int &index, int maxlen, char[] mbchar)
{
	int len = strlen(mbchar);
	if (len > maxlen)
		len = maxlen;
	
	int bytes;
	for (int i=0; i<len; i+=bytes)
	{
		bytes = GetCharBytes(mbchar[i]);
		for (int b=0; b<bytes; b++)
		{
			str[index++] = mbchar[i+b];
		}
	}
}

// Timer to draw the game field panel.
// There is one running for each player of each Connect 4 game.
public Action Timer_GameThink(Handle timer, any client)
{
	// See which game field we should draw for this client.
	int iGameIndex = g_iClientCurrentGame[client];
	if (iGameIndex == -1)
		return Plugin_Stop;
	
	// Find out who we're playing against!
	int iOpponent = GetOpponent(iGameIndex, client);
	
	// Start drawing the game field in a panel
	char sGameLine[BUFFER_X_SIZE];
	int iIndex;
	Panel panel = new Panel();
	
	char sTitle[128];
	Format(sTitle, sizeof(sTitle), "%sOpponent: %N", PREFIX, iOpponent);
	panel.SetTitle(sTitle);
	panel.DrawText(" "); // Empty line between title and gamefield
	
	// First line is the cursor
	START_NEW_LINE(iIndex);
	INSERT_SYMBOL(iIndex, SYMBOL_SPACE);
	for (int x=0; x<g_Connect4Game[iGameIndex][C4G_fieldSizeX]; x++)
	{
		// Put the cursor where the player wants it to be!
		if (g_iClientCurrentSelectorPosition[client] == x)
			INSERT_SYMBOL(iIndex, SYMBOL_CURSOR ... SYMBOL_CURSOR);
		else
			INSERT_SYMBOL(iIndex, SYMBOL_SPACE ... SYMBOL_SPACE);
	}
	INSERT_SYMBOL(iIndex, SYMBOL_SPACE);
	FINISH_LINE(iIndex);
	panel.DrawText(sGameLine);
	
	// Draw the game field grid itself
	for (int y=0; y<g_Connect4Game[iGameIndex][C4G_fieldSizeY]; y++)
	{
		START_NEW_LINE(iIndex);
		// Draw the left barrier first
		INSERT_SYMBOL(iIndex, SYMBOL_WALL_LEFT);
		for (int x=0; x<g_Connect4Game[iGameIndex][C4G_fieldSizeX]; x++)
		{
			// Add the symbols of the fields depending on who's disc is in the slot.
			// Double up the symbols, so they're wider than high. This helps seeing patterns
			// and distinguishing the different discs.
			switch (g_GameField[iGameIndex][y][x])
			{
				case Slot_Empty:
				{
					INSERT_SYMBOL(iIndex, SYMBOL_SPACE ... SYMBOL_SPACE); // ... just concatenates two string constants.
				}
				case Slot_Red:
				{
					INSERT_SYMBOL(iIndex, SYMBOL_PLAYER1 ... SYMBOL_PLAYER1);
				}
				case Slot_Blue:
				{
					INSERT_SYMBOL(iIndex, SYMBOL_PLAYER2 ... SYMBOL_PLAYER2);
				}
			}
		}
		// Draw the right barrier last
		INSERT_SYMBOL(iIndex, SYMBOL_WALL_RIGHT);
		FINISH_LINE(iIndex);
		panel.DrawText(sGameLine);
	}
	
	// Add bottom wall
	START_NEW_LINE(iIndex);
	INSERT_SYMBOL(iIndex, SYMBOL_WALL_BOTTOM);
	for (int x=0; x<g_Connect4Game[iGameIndex][C4G_fieldSizeX]; x++)
	{
		INSERT_SYMBOL(iIndex, SYMBOL_WALL_BOTTOM ... SYMBOL_WALL_BOTTOM);
	}
	INSERT_SYMBOL(iIndex, SYMBOL_WALL_BOTTOM);
	FINISH_LINE(iIndex);
	panel.DrawText(sGameLine);
	
	// Add an empty line before all the additional stuff below.
	panel.DrawText(" ");
	
	char sBuffer[256];
	// Have the panel open for 6 seconds by default. We're refreshing it earlier every second anyway.
	// Just if the plugin is unloaded or the player has a high latency.
	int iPanelHoldtime = 6;
	
	// No winner yet. Game still going.
	if (g_Connect4Game[iGameIndex][C4G_winner] == WINNER_NONE)
	{
		// Display client's symbol.
		ESlotType slotType = g_Connect4Game[iGameIndex][C4G_firstPlayer] == client ? Slot_Red : Slot_Blue;
		if (slotType == Slot_Red)
			Format(sBuffer, sizeof(sBuffer), "Your symbol is %s", SYMBOL_PLAYER1 ... SYMBOL_PLAYER1);
		else if (slotType == Slot_Blue)
			Format(sBuffer, sizeof(sBuffer), "Your symbol is %s", SYMBOL_PLAYER2 ... SYMBOL_PLAYER2);
		panel.DrawText(sBuffer);
		
		// Inform player who's turn it is.
		if (g_bIsClientTurn[client])
			strcopy(sBuffer, sizeof(sBuffer), "Your turn!");
		else
			Format(sBuffer, sizeof(sBuffer), "Opponent's turn.");
		panel.DrawText(sBuffer);
	
		// Add an option to pause the game
		panel.CurrentKey = 5;
		panel.DrawItem("Pause");
	
		// Add a surrender option to end the game.
		panel.CurrentKey = 9;
		panel.DrawItem("Surrender");
	}
	// Game over. See if there's a winner!
	else
	{
		// There's no winner..
		if (g_Connect4Game[iGameIndex][C4G_winner] == WINNER_DRAW)
		{
			strcopy(sBuffer, sizeof(sBuffer), "~~~ DRAW ~~~");
		}
		else
		{
			// There is a winner, see if the client is the lucky one.
			if (g_Connect4Game[iGameIndex][C4G_winner] == client)
				strcopy(sBuffer, sizeof(sBuffer), "~~~ YOU WIN! ~~~");
			else
				strcopy(sBuffer, sizeof(sBuffer), "~~~ YOU LOSE! ~~~");
		}
		panel.DrawText(sBuffer);
		
		// Add few options to play again!
		panel.DrawItem("Play again");
		panel.DrawItem("New Game");
		panel.DrawItem("Exit");
		
		// Display the winning screen forever.
		iPanelHoldtime = MENU_TIME_FOREVER;
	}
	
	// Display the panel to the client.
	panel.Send(client, Panel_HandleGameThink, iPanelHoldtime);
	panel.Close();
	
	return Plugin_Continue;
}

public int Panel_HandleGameThink(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		// Revenge
		if (param2 == 1)
		{
			// Last opponent is still available?
			if (g_iLastOpponent[param1] > 0)
			{
				ShowChallengeMenu(param1, g_iLastOpponent[param1]);
			}
			else
			{
				// If they're not, just show the player list again to pick a new opponent.
				PrintToChat(param1, "%sYour previous opponent left the game.", CPREFIX);
				ShowPlayerListMenu(param1);
			}
		}
		// Play against another player
		else if (param2 == 2)
		{
			ShowPlayerListMenu(param1);
		}
		// Pause
		else if (param2 == 5)
		{
			int iGameIndex = g_iClientCurrentGame[param1];
			if (iGameIndex == -1)
				return;
			
			int iOpponent = GetOpponent(iGameIndex, param1);
			PauseConnect4Game(iGameIndex);
			
			PrintToChat(param1, "%sPausing game against %N.", CPREFIX, iOpponent);
			PrintToChat(iOpponent, "%s%N paused the game.", CPREFIX, param1);
		}
		// Surrender
		else if(param2 == 9)
		{
			int iGameIndex = g_iClientCurrentGame[param1];
			if (iGameIndex == -1)
				return;
			
			int iOpponent = GetOpponent(iGameIndex, param1);
			g_Connect4Game[iGameIndex][C4G_winner] = iOpponent;
			StopConnect4Game(iGameIndex);
			
			PrintToChat(param1, "%sYou surrendered the game. YOU LOSE.", CPREFIX);
			PrintToChat(iOpponent, "%s%N surrendered. YOU WIN!", CPREFIX, param1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Pause the game, if it is interrupted by another menu.
		// FIXME: Don't count redrawing the game field itself again.
		/*if (param2 == MenuCancel_Interrupted)
		{
			int iGameIndex = g_iClientCurrentGame[param1];
			if (iGameIndex == -1)
				return;
			
			int iOpponent = GetOpponent(iGameIndex, param1);
			PauseConnect4Game(iGameIndex);
			PrintToChat(param1, "%sPausing game against %N, because of a different menu interrupting.", CPREFIX, iOpponent);
			PrintToChat(iOpponent, "%s%N paused the game, because a different menu interrupted.", CPREFIX, param1);
		}*/
	}
}

/**
 * Game logic helpers
 */
void StartConnect4Game(int player1, int player2)
{
	// Find a free game field
	int iGameIndex;
	for (; iGameIndex < MAXPLAYERS; iGameIndex++)
	{
		if (!IsValidConnect4Game(iGameIndex))
			break;
	}
	
	// Remember the players relation.
	g_iLastOpponent[player1] = player2;
	g_iLastOpponent[player2] = player1;
	
	// The challenge got accepted.
	g_bClientOpenChallenge[player1][player2] = false;
	g_bClientOpenChallenge[player2][player1] = false;
	
	// Those players are using this game field now.
	g_iClientCurrentGame[player1] = iGameIndex;
	g_iClientCurrentGame[player2] = iGameIndex;
	
	// Who's playing in this game
	g_Connect4Game[iGameIndex][C4G_firstPlayer] = player1;
	g_Connect4Game[iGameIndex][C4G_secondPlayer] = player2;
	g_Connect4Game[iGameIndex][C4G_winner] = WINNER_NONE;
	
	// Both player's cursors start all to the left.
	g_iClientCurrentSelectorPosition[player1] = 0;
	g_iClientCurrentSelectorPosition[player2] = 0;
	
	// Decide who starts randomly.
	g_bIsClientTurn[player1] = GetURandomFloat() >= 0.5;
	g_bIsClientTurn[player2] = !g_bIsClientTurn[player1];
	
	// TODO: Add option for different field sizes.
	// Specify the size of the field. 
	// Make sure not to exceed the MAX_GAMEFIELD_(X|Y) defines.
	// 7x6 is the normal size of a connect 4 game.
	g_Connect4Game[iGameIndex][C4G_fieldSizeX] = 7;
	g_Connect4Game[iGameIndex][C4G_fieldSizeY] = 6;
	
	// Freeze both players, so they're not moving around 
	// in the real game while moving their cursors.
	SetEntityMoveType(player1, MOVETYPE_NONE);
	SetEntityMoveType(player2, MOVETYPE_NONE);
	
	// Start timers to draw the game field for both players individually.
	// Have to view the Handle as an int, because "enum-structs" are not supported in the transitional syntax :(
	g_Connect4Game[iGameIndex][C4G_thinkTimerP1] = view_as<int>(CreateTimer(1.0, Timer_GameThink, player1, TIMER_REPEAT));
	g_Connect4Game[iGameIndex][C4G_thinkTimerP2] = view_as<int>(CreateTimer(1.0, Timer_GameThink, player2, TIMER_REPEAT));
	
	// Draw the gamefield right away.
	RedrawGameField(iGameIndex);
}

void StopConnect4Game(int iGameIndex)
{
	// That game already was reset.
	if (!IsValidConnect4Game(iGameIndex))
		return;
	
	int iPlayer1 = g_Connect4Game[iGameIndex][C4G_firstPlayer];
	int iPlayer2 = g_Connect4Game[iGameIndex][C4G_secondPlayer];
	
	// If this game wasn't currently active, remove it from the paused game's lists.
	if (g_iClientCurrentGame[iPlayer1] != iGameIndex)
		RemovePausedGameIndex(g_hClientPausedGames[iPlayer1], iGameIndex);
	if (g_iClientCurrentGame[iPlayer2] != iGameIndex)
		RemovePausedGameIndex(g_hClientPausedGames[iPlayer2], iGameIndex);
	RemoveGameState(iGameIndex);
	
	// Save outcome to database first.
	ReportConnect4GameEnd(iGameIndex);
	
	// Reset game state
	g_iClientCurrentGame[iPlayer1] = -1;
	g_iClientCurrentGame[iPlayer2] = -1;
	g_iClientCurrentSelectorPosition[iPlayer1] = 0;
	g_iClientCurrentSelectorPosition[iPlayer2] = 0;
	g_bIsClientTurn[iPlayer1] = false;
	g_bIsClientTurn[iPlayer2] = false;
	
	g_Connect4Game[iGameIndex][C4G_firstPlayer] = 0;
	g_Connect4Game[iGameIndex][C4G_secondPlayer] = 0;
	g_Connect4Game[iGameIndex][C4G_winner] = WINNER_NONE;
	g_Connect4Game[iGameIndex][C4G_fieldSizeX] = 0;
	g_Connect4Game[iGameIndex][C4G_fieldSizeY] = 0;
	
	// Make sure this game is gone from the open challenge list.
	g_bClientOpenChallenge[iPlayer1][iPlayer2] = false;
	g_bClientOpenChallenge[iPlayer2][iPlayer1] = false;
	
	ResetGameField(iGameIndex);
	
	// Stop drawing the gamefield panel
	ClearHandle(view_as<Handle>(g_Connect4Game[iGameIndex][C4G_thinkTimerP1]));
	ClearHandle(view_as<Handle>(g_Connect4Game[iGameIndex][C4G_thinkTimerP2]));
	
	// Let players move again.
	if (IsClientInGame(iPlayer1))
		SetEntityMoveType(iPlayer1, MOVETYPE_WALK);
	if (IsClientInGame(iPlayer2))
		SetEntityMoveType(iPlayer2, MOVETYPE_WALK);
}

// Update the stats correctly and save them into the database.
void ReportConnect4GameEnd(int iGameIndex)
{
	// That game is invalid.
	if (!IsValidConnect4Game(iGameIndex))
		return;
	
	int iPlayer1 = g_Connect4Game[iGameIndex][C4G_firstPlayer];
	int iPlayer2 = g_Connect4Game[iGameIndex][C4G_secondPlayer];
	
	// Draw.
	if (g_Connect4Game[iGameIndex][C4G_winner] == WINNER_DRAW)
	{
		g_PlayerStats[iPlayer1][Stat_Draws]++;
		g_PlayerStats[iPlayer2][Stat_Draws]++;
	}
	else if(g_Connect4Game[iGameIndex][C4G_winner] == iPlayer1)
	{
		g_PlayerStats[iPlayer1][Stat_Wins]++;
		g_PlayerStats[iPlayer2][Stat_Losses]++;
	}
	else
	{
		g_PlayerStats[iPlayer1][Stat_Losses]++;
		g_PlayerStats[iPlayer2][Stat_Wins]++;
	}
	
	// Save stats into the database.
	if (g_hDatabase != null)
		UpdatePlayersStats(iPlayer1, iPlayer2);
}

void PauseConnect4Game(int iGameIndex)
{
	// That game is invalid.
	if (!IsValidConnect4Game(iGameIndex))
		return;
	
	int iPlayer1 = g_Connect4Game[iGameIndex][C4G_firstPlayer];
	int iPlayer2 = g_Connect4Game[iGameIndex][C4G_secondPlayer];
	
	// Save their state away.
	int gameState[Connect4GameState];
	gameState[GS_index] = iGameIndex;
	gameState[GS_player1Id] = GetClientUserId(iPlayer1);
	gameState[GS_player2Id] = GetClientUserId(iPlayer2);
	gameState[GS_turn] = g_bIsClientTurn[iPlayer1] ? 1 : 2;
	gameState[GS_selectorPositionP1] = g_iClientCurrentSelectorPosition[iPlayer1];
	gameState[GS_selectorPositionP2] = g_iClientCurrentSelectorPosition[iPlayer2];
	g_hPausedConnect4Games.PushArray(gameState[0], view_as<int>(Connect4GameState));
	
	// Remember that this game is still waiting for both players.
	g_hClientPausedGames[iPlayer1].Push(iGameIndex);
	g_hClientPausedGames[iPlayer2].Push(iGameIndex);
	
	// These two players aren't playing anymore.
	g_iClientCurrentGame[iPlayer1] = -1;
	g_iClientCurrentGame[iPlayer2] = -1;
	g_iClientCurrentSelectorPosition[iPlayer1] = 0;
	g_iClientCurrentSelectorPosition[iPlayer2] = 0;
	g_bIsClientTurn[iPlayer1] = false;
	g_bIsClientTurn[iPlayer2] = false;
	
	// Stop drawing the gamefield panel
	ClearHandle(view_as<Handle>(g_Connect4Game[iGameIndex][C4G_thinkTimerP1]));
	ClearHandle(view_as<Handle>(g_Connect4Game[iGameIndex][C4G_thinkTimerP2]));
	
	// Let players move again.
	if (IsClientInGame(iPlayer1))
	{
		CancelClientMenu(iPlayer1);
		SetEntityMoveType(iPlayer1, MOVETYPE_WALK);
	}
	if (IsClientInGame(iPlayer2))
	{
		CancelClientMenu(iPlayer2);
		SetEntityMoveType(iPlayer2, MOVETYPE_WALK);
	}
}

void ResumeConnect4Game(int iGameIndex)
{
	// That game is invalid.
	if (!IsValidConnect4Game(iGameIndex))
		return;
	
	int iPlayer1 = g_Connect4Game[iGameIndex][C4G_firstPlayer];
	int iPlayer2 = g_Connect4Game[iGameIndex][C4G_secondPlayer];
	
	// Restore the game state.
	int gameState[Connect4GameState];
	GetGameState(iGameIndex, gameState);
	
	g_iClientCurrentGame[iPlayer1] = iGameIndex;
	g_iClientCurrentGame[iPlayer2] = iGameIndex;
	g_bIsClientTurn[iPlayer1] = gameState[GS_turn] == 1;
	g_bIsClientTurn[iPlayer2] = gameState[GS_turn] == 2;
	g_iClientCurrentSelectorPosition[iPlayer1] = gameState[GS_selectorPositionP1];
	g_iClientCurrentSelectorPosition[iPlayer2] = gameState[GS_selectorPositionP2];
	
	// Remove it from the cache.
	RemovePausedGameIndex(g_hClientPausedGames[iPlayer1], iGameIndex);
	RemovePausedGameIndex(g_hClientPausedGames[iPlayer2], iGameIndex);
	RemoveGameState(iGameIndex);
	
	// Remember the players relation.
	g_iLastOpponent[iPlayer1] = iPlayer2;
	g_iLastOpponent[iPlayer2] = iPlayer1;
	
	// Start drawing the game field again.
	g_Connect4Game[iGameIndex][C4G_thinkTimerP1] = view_as<int>(CreateTimer(1.0, Timer_GameThink, iPlayer1, TIMER_REPEAT));
	g_Connect4Game[iGameIndex][C4G_thinkTimerP2] = view_as<int>(CreateTimer(1.0, Timer_GameThink, iPlayer2, TIMER_REPEAT));
	
	// Freeze both players again, so they're not moving around 
	// in the real game while moving their cursors.
	SetEntityMoveType(iPlayer1, MOVETYPE_NONE);
	SetEntityMoveType(iPlayer2, MOVETYPE_NONE);
}

// Move the cursor of the player in the desired direction, if there is still room.
bool MoveCursor(int client, EDirection direction)
{
	int iGameIndex = g_iClientCurrentGame[client];
	
	// See if there still is enough room in the desired direction
	// Move the selector if there is.
	if (direction == Direction_Left)
	{
		if (g_iClientCurrentSelectorPosition[client] > 0)
		{
			g_iClientCurrentSelectorPosition[client]--;
			return true;
		}
	}
	// Move right
	else
	{
		if (g_iClientCurrentSelectorPosition[client] < g_Connect4Game[iGameIndex][C4G_fieldSizeX] - 1)
		{
			g_iClientCurrentSelectorPosition[client]++;
			return true;
		}
	}
	return false;
}

// Lets a client drop a disc in the selected row.
// They're placed on top of the other discs in that row
// or right at the bottom, if there is none yet.
// Returns the y index of the row where the disk was placed
// or -1 if row is full.
int DropDisc(int client)
{
	int iGameIndex = g_iClientCurrentGame[client];
	int iPosition = g_iClientCurrentSelectorPosition[client];
	
	// Run through the row starting at the bottom going to the top to find the first empty slot.
	int iFirstFreeRow = -1;
	for (int y=g_Connect4Game[iGameIndex][C4G_fieldSizeY]-1; y>=0; y--)
	{
		if (g_GameField[iGameIndex][y][iPosition] == Slot_Empty)
		{
			iFirstFreeRow = y;
			break;
		}
	}
	
	// That row is full, no more free slots left.
	// Can't insert a disc here.
	if (iFirstFreeRow == -1)
		return -1;
	
	// Drop the disc in that row.
	ESlotType slotType = g_Connect4Game[iGameIndex][C4G_firstPlayer] == client ? Slot_Red : Slot_Blue;
	g_GameField[iGameIndex][iFirstFreeRow][iPosition] = slotType;
	return iFirstFreeRow;
}

// See if some given coords are valid inside the game fields bounds.
bool IsCoordInGameGrid(int iGameIndex, int x, int y)
{
	if (x < 0)
		return false;
	if (x > g_Connect4Game[iGameIndex][C4G_fieldSizeX])
		return false;
	if (y < 0)
		return false;
	if (y > g_Connect4Game[iGameIndex][C4G_fieldSizeY])
		return false;
	return true;
}

// See if the game is on a draw and nobody can win.
bool CheckDrawCondition(int iGameIndex)
{
	// See if there is any place left on the field.
	// Only have to check for the top row, 
	// because discs are placed from the bottom to the top.
	for(int x=0; x<g_Connect4Game[iGameIndex][C4G_fieldSizeX]; x++)
	{
		// There is still an empty slot at the top, so the game isn't over yet.
		if (g_GameField[iGameIndex][0][x] == Slot_Empty)
			return false;
	}
	return true;
}

// See if the client has four discs in a row either vertically, horizontally or diagonally.
// This just checks the 4x4 local neighborhood of the newly added disc to check,
// if that new disc finished the game. No need to check the whole gamefield.
bool CheckWinCondition(int client, int iDropRow)
{
	// See if this move resulted in a Connect 4
	int iGameIndex = g_iClientCurrentGame[client];
	int iDropColumn = g_iClientCurrentSelectorPosition[client];
	ESlotType slotType = g_Connect4Game[iGameIndex][C4G_firstPlayer] == client ? Slot_Red : Slot_Blue;
	
	// Check in all directions
	// Keep count of the additional discs of this player in a row in each direction.
	int iSameHorizontal, iSameVertical, iSameDiagonalUpLeftDownRight, iSameDiagonalDownLeftUpRight;
	
	// Remember when we found an empty slot or one filled with the disc of the opponent
	// on the way, so we don't count more discs of this player afterwards.
	bool bHorizontalLeftInvalid, bHorizontalRightInvalid;
	bool bVerticalUpInvalid, bVerticalDownInvalid;
	bool bDiagonalUpLeftDownRightLeftInvalid, bDiagonalUpLeftDownRightRightInvalid;
	bool bDiagonalDownLeftUpRightLeftInvalid, bDiagonalDownLeftUpRightRightInvalid;
	
	// Only run through the 4x4 square once
	for (int diff=1; diff<4; diff++)
	{
		// Horizontal to the right
		if (!bHorizontalRightInvalid // We met an invalid slot in this direction before. Ignore all following even if it's the right color.
			&& IsCoordInGameGrid(iGameIndex, iDropColumn+diff, iDropRow) // Make sure this position is valid at all.
			&& g_GameField[iGameIndex][iDropRow][iDropColumn+diff] == slotType) // See if this slot contains one of the player's discs.
			iSameHorizontal++; // Count all discs.
		else
			bHorizontalRightInvalid = true; // This slot wasn't ours or outside the gamefield
		
		// Horizontal to the left
		if (!bHorizontalLeftInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn-diff, iDropRow)
			&& g_GameField[iGameIndex][iDropRow][iDropColumn-diff] == slotType)
			iSameHorizontal++;
		else
			bHorizontalLeftInvalid = true;
		
		// Vertical up
		if (!bVerticalUpInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn, iDropRow-diff)
			&& g_GameField[iGameIndex][iDropRow-diff][iDropColumn] == slotType)
			iSameVertical++;
		else
			bVerticalUpInvalid = true;
		
		// Vertical down
		if (!bVerticalDownInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn, iDropRow+diff)
			&& g_GameField[iGameIndex][iDropRow+diff][iDropColumn] == slotType)
			iSameVertical++;
		else
			bVerticalDownInvalid = true;
		
		// Diagonally up-left to down-right \ going left
		if (!bDiagonalUpLeftDownRightLeftInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn-diff, iDropRow-diff)
			&& g_GameField[iGameIndex][iDropRow-diff][iDropColumn-diff] == slotType)
			iSameDiagonalUpLeftDownRight++;
		else
			bDiagonalUpLeftDownRightLeftInvalid = true;
		
		// Diagonally up-left to down-right \ going right
		if (!bDiagonalUpLeftDownRightRightInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn+diff, iDropRow+diff)
			&& g_GameField[iGameIndex][iDropRow+diff][iDropColumn+diff] == slotType)
			iSameDiagonalUpLeftDownRight++;
		else
			bDiagonalUpLeftDownRightRightInvalid = true;
		
		// Diagonally down-left to up-right / going left
		if (!bDiagonalDownLeftUpRightLeftInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn-diff, iDropRow+diff)
			&& g_GameField[iGameIndex][iDropRow+diff][iDropColumn-diff] == slotType)
			iSameDiagonalDownLeftUpRight++;
		else
			bDiagonalDownLeftUpRightLeftInvalid = true;
		
		// Diagonally down-left to up-right / going right
		if (!bDiagonalDownLeftUpRightRightInvalid
			&& IsCoordInGameGrid(iGameIndex, iDropColumn+diff, iDropRow-diff)
			&& g_GameField[iGameIndex][iDropRow-diff][iDropColumn+diff] == slotType)
			iSameDiagonalDownLeftUpRight++;
		else
			bDiagonalDownLeftUpRightRightInvalid = true;
	}
	
	// We don't count the disc we just dropped since it's obviously ours.
	// So only need 3 more of our discs connected to that position!
	return iSameHorizontal >= 3 || iSameVertical >= 3 || iSameDiagonalUpLeftDownRight >= 3 || iSameDiagonalDownLeftUpRight >= 3;
}

// Update the game field panel for both players.
void RedrawGameField(int iGameIndex)
{
	Handle timerP1 = view_as<Handle>(g_Connect4Game[iGameIndex][C4G_thinkTimerP1]);
	TriggerTimer(timerP1, true);
	
	Handle timerP2 = view_as<Handle>(g_Connect4Game[iGameIndex][C4G_thinkTimerP2]);
	TriggerTimer(timerP2, true);
}

// Empty out the game field.
void ResetGameField(int iIndex)
{
	for (int y=0; y<MAX_GAMEFIELD_Y; y++)
	{
		for (int x=0; x<MAX_GAMEFIELD_X; x++)
		{
			g_GameField[iIndex][y][x] = Slot_Empty;
		}
	}
}

// Get the client index of the opponent of the game.
int GetOpponent(int iGameIndex, int client)
{
	int iOpponent = g_Connect4Game[iGameIndex][C4G_firstPlayer];
	if (iOpponent == client)
		iOpponent = g_Connect4Game[iGameIndex][C4G_secondPlayer];
	return iOpponent;
}

// See if a client currently is playing Connect 4!
bool IsClientInConnect4Game(int client)
{
	return g_iClientCurrentGame[client] != -1;
}

bool IsValidConnect4Game(int iGameIndex)
{
	// All fields are reset when the game ends and 0 is an invalid dimension.
	return g_Connect4Game[iGameIndex][C4G_fieldSizeX] != 0;
}

void GetGameState(int index, int gameState[Connect4GameState])
{
	g_hPausedConnect4Games.GetArray(index, gameState[0], view_as<int>(Connect4GameState));
}

void RemoveGameState(int iGameIndex)
{
	int iSize = g_hPausedConnect4Games.Length;
	int gameState[Connect4GameState];
	for (int i=0; i<iSize; i++)
	{
		GetGameState(i, gameState);
		if (gameState[GS_index] == iGameIndex)
		{
			g_hPausedConnect4Games.Erase(i);
			return;
		}
	}
}

void RemovePausedGameIndex(ArrayList hPausedGames, int iGameIndex)
{
	if (!hPausedGames)
		return;
	
	int iIndex = hPausedGames.FindValue(iGameIndex);
	if (iIndex == -1)
		return;
	
	hPausedGames.Erase(iIndex);
}

ArrayList PopPausedGameListForClient(int iUserId)
{
	ArrayList hPausedGames;
	int iNumDisconnectedRefs = g_hDisconnectedClientReference.Length;
	int disconnectedRef[DisconnectedClientReference];
	for (int i=0; i<iNumDisconnectedRefs; i++)
	{
		g_hDisconnectedClientReference.GetArray(i, disconnectedRef[0], view_as<int>(DisconnectedClientReference));
		if (disconnectedRef[DC_playerId] == iUserId)
		{
			// Grab the paused game list for this player
			hPausedGames = view_as<ArrayList>(disconnectedRef[DC_pausedGameArrayList]);
			// and remove this entry from the cache.
			g_hDisconnectedClientReference.Erase(i);
			break;
		}
	}
	return hPausedGames;
}

// Finds the game these two players paused previously.
int GetPlayersPausedGameIndex(int iPlayer1, int iPlayer2)
{
	int iSize = g_hClientPausedGames[iPlayer1].Length;
	int iGameIndex;
	for (int i=0; i<iSize; i++)
	{
		iGameIndex = g_hClientPausedGames[iPlayer1].Get(i);
		if (g_Connect4Game[iGameIndex][C4G_firstPlayer] == iPlayer2)
			return i;
		if (g_Connect4Game[iGameIndex][C4G_secondPlayer] == iPlayer2)
			return i;
	}
	return -1;
}

stock void ClearHandle(Handle &hndl)
{
	if (hndl)
	{
		hndl.Close();
		hndl = null;
	}
}