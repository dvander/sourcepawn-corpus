#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <smlib>

#define PLUGIN_VERSION "1.0"

// Signs to display
#define SUIT_SPADES "♠"
#define SUIT_DIAMONDS "♦"
#define SUIT_HEARTS "♥"
#define SUIT_CLUBS "♣"

// Card values
#define CARD_SPADES 0
#define CARD_DIAMONDS 1
#define CARD_HEARTS 2
#define CARD_CLUBS 3

// Has to be at least 7..
#define CARD_LINE_NUM 7

// Player selection arrows
#define COORD_X 0
#define COORD_Y 1

#define CARD_COLOR 0
#define CARD_VALUE 1

new g_iPlayerSelection[MAXPLAYERS+1][2];
new g_iPlayerCursor[MAXPLAYERS+1][2];
new bool:g_bCardSelected[MAXPLAYERS+1];
new Handle:g_hCardDeck[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hDrawnCards[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:g_hCardLineDecks[MAXPLAYERS+1][CARD_LINE_NUM];
new Handle:g_hCardLines[MAXPLAYERS+1][CARD_LINE_NUM];
new Handle:g_hAceDecks[MAXPLAYERS+1][4];
new bool:g_bInGame[MAXPLAYERS+1];

new g_iScore[MAXPLAYERS+1];
new g_iPlayedTime[MAXPLAYERS+1];
new g_iSessionTime[MAXPLAYERS+1];
new Handle:g_hCountTime[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new bool:g_bRedrawGamePanel[MAXPLAYERS+1];

new g_iHighScore[MAXPLAYERS+1] = {-1,...};
new g_iHighScoreTime[MAXPLAYERS+1] = {-1,...};
new Handle:g_hDatabase;

new g_iButtons[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Solitaire",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "A solitaire card game simulation",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

/**
 * Forward callbacks
 */
public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_solitaire_version", PLUGIN_VERSION, "Solitaire minigame", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	RegConsoleCmd("sm_solitaire", Cmd_Solitaire, "Start a solitaire game.");
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	// Set the default vars.
	for(new i=1;i<=MaxClients;i++)
		ResetSolitaireGame(i);
	
	SQL_TConnect(SQL_OnDatabaseConnected, (SQL_CheckConfig("solitaire")?"solitaire":"storage-local"));
}

public OnClientAuthorized(client, const String:auth[])
{
	if(g_hDatabase != INVALID_HANDLE)
		SQL_TQueryF(g_hDatabase, SQL_GetClientHighscore, GetClientUserId(client), DBPrio_Normal, "SELECT score, time FROM solitaire_players WHERE steamid = \"%s\";", auth);
}

public OnClientDisconnect(client)
{
	g_iButtons[client] = 0;
	g_bInGame[client] = false;
	g_iHighScore[client] = -1;
	g_iHighScoreTime[client] = -1;
	ResetSolitaireGame(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Don't do anything, if he isn't playing.
	if(!g_bInGame[client] || g_hCardDeck[client] == INVALID_HANDLE)
		return Plugin_Continue;
	
	new bool:bChanged = false;
	new iOldButtons = buttons;
	
	// Move the vertical cursor up
	if(buttons & IN_FORWARD && !(g_iButtons[client] & IN_FORWARD))
	{
		g_iPlayerCursor[client][COORD_Y]--;
		// Jump over the empty line
		if(g_iPlayerCursor[client][COORD_Y] == 2)
			g_iPlayerCursor[client][COORD_Y]--;
		// Or the line showing the amount of cards left on the stack + the empty one.
		else if(g_iPlayerCursor[client][COORD_Y] == 3)
			g_iPlayerCursor[client][COORD_Y] -= 2;
		
		// Circle the cursor!
		if(g_iPlayerCursor[client][COORD_Y] < 1)
		{
			// Get the longest card row..
			new iHeight, iSize;
			for(new i=0;i<CARD_LINE_NUM;i++)
			{
				iSize = GetArraySize(g_hCardLines[client][i]);
				if(iHeight < iSize)
					iHeight = iSize;
			}
			
			// Add one for the cursor, one for the deck line and one for the empty line.
			iHeight += 4;
			
			if(iHeight == 4)
				g_iPlayerCursor[client][COORD_Y] = 1;
			else
				g_iPlayerCursor[client][COORD_Y] = iHeight-1;
		}
		
		buttons &= ~IN_FORWARD;
		
		bChanged = true;
	}
	// Move the vertical cursor down
	else if(buttons & IN_BACK && !(g_iButtons[client] & IN_BACK))
	{
		// Get the longest card row..
		new iHeight, iSize;
		for(new i=0;i<CARD_LINE_NUM;i++)
		{
			iSize = GetArraySize(g_hCardLines[client][i]);
			if(iHeight < iSize)
				iHeight = iSize;
		}
		
		// Add one for the cursor, one for the deck line and one for the empty line.
		iHeight += 4;
		
		g_iPlayerCursor[client][COORD_Y]++;
		if(g_iPlayerCursor[client][COORD_Y] == 2)
			g_iPlayerCursor[client][COORD_Y] += 2;
		else if(g_iPlayerCursor[client][COORD_Y] == 3)
			g_iPlayerCursor[client][COORD_Y]++;
		
		// Circle the cursor!
		if(g_iPlayerCursor[client][COORD_Y] >= iHeight)
			g_iPlayerCursor[client][COORD_Y] = 1;
		
		buttons &= ~IN_BACK;
		
		bChanged = true;
	}
	
	// Move the horizontal cursor to the left
	if(buttons & IN_MOVELEFT && !(g_iButtons[client] & IN_MOVELEFT))
	{
		g_iPlayerCursor[client][COORD_X]--;
		if(g_iPlayerCursor[client][COORD_X] < 1)
			g_iPlayerCursor[client][COORD_X] = CARD_LINE_NUM;
		
		buttons &= ~IN_MOVELEFT;
		
		bChanged = true;
	}
	// Move the horizontal cursor to the right
	else if(buttons & IN_MOVERIGHT && !(g_iButtons[client] & IN_MOVERIGHT))
	{
		g_iPlayerCursor[client][COORD_X]++;
		if(g_iPlayerCursor[client][COORD_X] >= CARD_LINE_NUM+1)
			g_iPlayerCursor[client][COORD_X] = 1;
		
		buttons &= ~IN_MOVERIGHT;
		
		bChanged = true;
	}
	
	// Shortcut to put a card from the deck to the waste.
	if(buttons & IN_JUMP && !(g_iButtons[client] & IN_JUMP))
	{
		PullACard(client);
		
		// We can't have the card selected, if we just changed it.
		if(g_iPlayerSelection[client][COORD_Y] == 1
		&& g_iPlayerSelection[client][COORD_X] == 2)
		{
			g_bCardSelected[client] = false;
			g_iPlayerSelection[client][COORD_X] = -1;
			g_iPlayerSelection[client][COORD_Y] = -1;
		}
		
		buttons &= ~IN_JUMP;
		
		bChanged = true;
	}
	// Interacting with the game!!!
	else if(buttons & IN_USE && !(g_iButtons[client] & IN_USE))
	{
		new iCard[2], bool:bEmptyAcePosition, bool:bEmptyRoot;
		// Draw a new card from the stack
		if(g_iPlayerCursor[client][COORD_X] == 1 && g_iPlayerCursor[client][COORD_Y] == 1)
		{
			g_bCardSelected[client] = false;
			g_iPlayerSelection[client][COORD_X] = -1;
			g_iPlayerSelection[client][COORD_Y] = -1;
			
			PullACard(client);
		}
		// There's a selectable card position there
		// or the player selected an empty ace stack at the top
		// or he selected a cleared normal line ready to put a king there.
		else if((bEmptyAcePosition = IsEmptyAcePosition(client, g_iPlayerCursor[client])) 
		|| (bEmptyRoot = IsEmptyRootPosition(client, g_iPlayerCursor[client])) 
		|| GetCardAtPosition(client, g_iPlayerCursor[client], iCard))
		{
			// Player didn't select a different card before. Just select this one.
			if(!g_bCardSelected[client])
			{
				if(!bEmptyAcePosition && !bEmptyRoot)
				{
					g_bCardSelected[client] = true;
					g_iPlayerSelection[client] = g_iPlayerCursor[client];
				}
			}
			// Player wants to move card(s) on to another stack. IS THAT POSSIBLE?!
			else
			{
				new iCard2[2];
				// We want to put card2 on card(1).
				if(GetCardAtPosition(client, g_iPlayerSelection[client], iCard2))
				{
					// Get this easier and faster.
					new iTempPlayerCursor[2];
					iTempPlayerCursor = g_iPlayerCursor[client];
					// When trying to move a card to another stack, don't require us to select the latest card,
					// but select the lastest in that row automatically.
					if(iTempPlayerCursor[COORD_Y] >= 4
					&& GetArraySize(g_hCardLines[client][iTempPlayerCursor[COORD_X]-1]) > (iTempPlayerCursor[COORD_Y]-3))
					{
						iTempPlayerCursor[COORD_Y] = GetArraySize(g_hCardLines[client][g_iPlayerCursor[client][COORD_X]-1]) + 3;
						GetCardAtPosition(client, iTempPlayerCursor, iCard);
					}
					
					/*decl String:sCard[10], String:sCard2[10];
					FormatCardToString(iCard, sCard, sizeof(sCard));
					FormatCardToString(iCard2, sCard2, sizeof(sCard2));
					PrintToChat(client, "CanPlaceCardOnAnother(%s, %s, %d|%d) = %d", sCard2, sCard, iTempPlayerCursor[COORD_X], iTempPlayerCursor[COORD_Y], CanPlaceCardOnAnother(iCard2, iCard, iTempPlayerCursor));
					*/
					
					// Is this move possible?
					// Make sure we don't put the card on the waste stack
					if((iTempPlayerCursor[COORD_Y] != 1
					|| iTempPlayerCursor[COORD_X] != 2)
					
					// And we're able to put them on each other
					// Or there's no card there.
					&& (bEmptyAcePosition || bEmptyRoot
					|| CanPlaceCardOnAnother(iCard2, iCard, iTempPlayerCursor))
					
					// It's only ok to put an ACE here on an empty foundation place
					&& (!bEmptyAcePosition 
					|| iCard2[CARD_VALUE] == 1)
					
					// It's only ok to put a KING here on an empty tableau place
					&& (!bEmptyRoot
					|| iCard2[CARD_VALUE] == 13)
					
					// Make sure we're able to move the cards.
					// We can't move multiple cards up to the foundation.
					&& MoveCards(client, g_iPlayerSelection[client], iCard2, iTempPlayerCursor))
					{
						// No more cards in that line? Turn another one around, if there are still some left.
						if(g_iPlayerSelection[client][COORD_Y] >= 4
						&& GetArraySize(g_hCardLines[client][g_iPlayerSelection[client][COORD_X]-1]) == 0
						&& GetArraySize(g_hCardLineDecks[client][g_iPlayerSelection[client][COORD_X]-1]) > 0)
						{
							GetArrayArray(g_hCardLineDecks[client][g_iPlayerSelection[client][COORD_X]-1], 0, iCard, 2);
							PushArrayArray(g_hCardLines[client][g_iPlayerSelection[client][COORD_X]-1], iCard, 2);
							RemoveFromArray(g_hCardLineDecks[client][g_iPlayerSelection[client][COORD_X]-1], 0);
							
							// Turn over Tableau card
							g_iScore[client] += 5;
						}
						
						// WIN?!
						new bool:bWon = true;
						for(new i=0;i<4;i++)
						{
							if(GetArraySize(g_hAceDecks[client][i]) > 0)
							{
								GetArrayArray(g_hAceDecks[client][i], 0, iCard, 2);
								if(iCard[CARD_VALUE] != 13)
								{
									bWon = false;
								}
							}
							else
								bWon = false;
						}
						
						if(bWon)
						{
							// Additional bonus points?
							if(g_iPlayedTime[client] > 30)
							{
								g_iScore[client] += 700000 / g_iPlayedTime[client];
							}
							
							new bool:bNewHighscore = false;
							// Save to db
							if(g_hDatabase != INVALID_HANDLE
							&& g_iScore[client] > 0
							&& (g_iHighScore[client] < g_iScore[client] 
							|| (g_iHighScore[client] == g_iScore[client] 
							&& g_iHighScoreTime[client] < g_iPlayedTime[client])))
							{
								decl String:sName[MAX_NAME_LENGTH], String:sEscapedName[MAX_NAME_LENGTH*2+1], String:sAuth[32];
								GetClientName(client, sName, sizeof(sName));
								GetClientAuthString(client, sAuth, sizeof(sAuth));
								SQL_EscapeString(g_hDatabase, sName, sEscapedName, sizeof(sEscapedName));
								
								if(g_iHighScore[client] == -1)
									SQL_TQueryF(g_hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "INSERT INTO solitaire_players (steamid, name, score, time) VALUES (\"%s\", \"%s\", %d, %d);", sAuth, sEscapedName, g_iScore[client], g_iPlayedTime[client]);
								else
									SQL_TQueryF(g_hDatabase, SQL_DoNothing, 0, DBPrio_Normal, "UPDATE solitaire_players SET name = \"%s\", score = %d, time = %d WHERE steamid = \"%s\";", sEscapedName, g_iScore[client], g_iPlayedTime[client], sAuth);
								
								g_iHighScore[client] = g_iScore[client];
								g_iHighScoreTime[client] = g_iPlayedTime[client];
								bNewHighscore = true;
							}
							
							ShowGamePanel(client);
							Client_PrintToChat(client, false, "{G}Solitaire{N} > {L}You won in {OG}%d{L} second%s! Your final score: {RB}%d{L}. Type {OG}!solitaire{L} to play again.", g_iPlayedTime[client], (g_iPlayedTime[client]==1?"":"s"), g_iScore[client]);
							
							if(bNewHighscore)
								Client_PrintToChat(client, false, "{G}Solitaire{N} > {L} New personal {RB}highscore{L}!");
							
							ResetSolitaireGame(client);
							g_bInGame[client] = false;
							g_iButtons[client] = iOldButtons;
							return Plugin_Continue;
						}
					}
				}
				g_bCardSelected[client] = false;
				g_iPlayerSelection[client][COORD_X] = -1;
				g_iPlayerSelection[client][COORD_Y] = -1;
			}
		}
		// Just selected something invalid. Remove the selection.
		else
		{
			g_bCardSelected[client] = false;
			g_iPlayerSelection[client][COORD_X] = -1;
			g_iPlayerSelection[client][COORD_Y] = -1;
		}
		
		buttons &= ~IN_USE;
		
		bChanged = true;
	}
	
	g_iButtons[client] = iOldButtons;
	
	if(bChanged)
	{
		ShowGamePanel(client);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

/**
 * Event hooks
 */
public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return;
	
	// Refreeze after spawn
	if(g_bInGame[client])
		SetEntProp(client, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
}

/**
 * Command callbacks
 */
public Action:Cmd_Solitaire(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "[Solitaire] This command is ingame only.");
		return Plugin_Handled;
	}
	
	ShowMainMenu(client);
	
	return Plugin_Handled;
}

/**
 * SQL callbacks
 */
public SQL_OnDatabaseConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("Error connecting to database: %s", error);
		return;
	}
	
	g_hDatabase = hndl;
	
	decl String:sDriver[16];
	SQL_ReadDriver(hndl, sDriver, sizeof(sDriver));
	if(StrEqual(sDriver, "sqlite", false))
	{
		SQL_TQuery(hndl, SQL_DoNothing, "CREATE TABLE IF NOT EXISTS solitaire_players (steamid VARCHAR(64) PRIMARY KEY, name VARCHAR(64) NOT NULL, score INTEGER DEFAULT '0', time INTEGER DEFAULT '0');");
	}
	else
	{
		SQL_TQuery(hndl, SQL_DoNothing, "SET NAMES 'utf8';");
	}
	
	decl String:sAuth[32];
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsClientAuthorized(i))
		{
			GetClientAuthString(i, sAuth, sizeof(sAuth));
			OnClientAuthorized(i, sAuth);
		}
	}
}

public SQL_GetClientHighscore(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		
		g_iHighScore[client] = SQL_FetchInt(hndl, 0);
		g_iHighScoreTime[client] = SQL_FetchInt(hndl, 1);
	}
}

public SQL_FetchTop10(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
	
	new client = GetClientOfUserId(userid);
	if(!client)
		return;
	
	new Handle:hMenu = CreateMenu(Menu_HandleTop10);
	SetMenuTitle(hMenu, "Solitaire: Top 10");
	SetMenuExitBackButton(hMenu, true);
	
	decl String:sMenu[128];
	new iPlace = 1;
	while(SQL_MoreRows(hndl))
	{
		if(!SQL_FetchRow(hndl))
			continue;
		
		SQL_FetchString(hndl, 0, sMenu, sizeof(sMenu));
		Format(sMenu, sizeof(sMenu), "%d. %s: %d in %d seconds", iPlace, sMenu, SQL_FetchInt(hndl, 1), SQL_FetchInt(hndl, 2));
		AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
		iPlace++;
	}
	
	for(new i=iPlace;i<=10;i++)
	{
		Format(sMenu, sizeof(sMenu), "%d. ", i);
		AddMenuItem(hMenu, "", sMenu, ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public SQL_DoNothing(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL query error: %s", error);
		return;
	}
}

/**
 * Menu creation..
 */
ShowMainMenu(client)
{
	new Handle:hMenu = CreateMenu(Menu_HandleMainManu);
	SetMenuTitle(hMenu, "Solitaire");
	SetMenuExitButton(hMenu, true);
	
	AddMenuItem(hMenu, "new", "Start new game");
	if(g_hCardDeck[client] != INVALID_HANDLE)
		AddMenuItem(hMenu, "resume", "Resume previous game");
	
	AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	if(g_iHighScore[client] != -1)
	{
		decl String:sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "Your highscore: %d in %d seconds!", g_iHighScore[client], g_iHighScoreTime[client]);
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	AddMenuItem(hMenu, "top10", "Show top10");
	AddMenuItem(hMenu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(hMenu, "", "Controls: moving keys to control the cursors, \"e\" to select a card.", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "", "Jump to quickly pull a new card.", ITEMDRAW_DISABLED);
	AddMenuItem(hMenu, "", "Press \"0\" to pause the game.", ITEMDRAW_DISABLED);
	
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

ShowGamePanel(client)
{
	// No game running? Show the mainmenu.
	if(g_hCardDeck[client] == INVALID_HANDLE)
	{
		ShowMainMenu(client);
		return;
	}
	
	new Handle:hPanel = CreatePanel();
	
	new String:sLine[64], String:sCard[8], iCard[2];
	
	Format(sLine, sizeof(sLine), "Solitaire > Score: %d, %d second%s played", g_iScore[client], g_iPlayedTime[client], (g_iPlayedTime[client]==1?"":"s"));
	SetPanelTitle(hPanel, sLine);
	Format(sLine, sizeof(sLine), "");
	
	new iWidth = CARD_LINE_NUM;
	
	// Need one more space for the cursor
	iWidth++;
	
	// Get the longest card row..
	new iHeight, iSize;
	for(new i=0;i<CARD_LINE_NUM;i++)
	{
		iSize = GetArraySize(g_hCardLines[client][i]);
		if(iHeight < iSize)
			iHeight = iSize;
	}
	
	// Add one for the cursor, one for the deck line and one for the empty line.
	iHeight += 4;
	
	// Draw the field
	for(new y=0;y<iHeight;y++)
	{
		for(new x=0;x<iWidth;x++)
		{
			// Where to put the top cursor?
			if(y == 0)
			{
				if(g_iPlayerCursor[client][COORD_X] == x || (g_bCardSelected[client] && g_iPlayerSelection[client][COORD_X] == x))
					Format(sLine, sizeof(sLine), "%s_v_", sLine);
				else
					Format(sLine, sizeof(sLine), "%s___", sLine);
			}
			// Player has his left cursor here?
			if(x == 0)
			{
				if(g_iPlayerCursor[client][COORD_Y] == y || (g_bCardSelected[client] && g_iPlayerSelection[client][COORD_Y] == y))
					Format(sLine, sizeof(sLine), ">");
				else
					Format(sLine, sizeof(sLine), "_");
			}
			
			// First line contains the deck and the ace stacks
			if(y == 1)
			{
				switch(x)
				{
					// Hidden card deck
					case 1:
					{
						iSize = GetArraySize(g_hCardDeck[client]);
						// The deck is all drawn out.
						if(iSize == 0)
							Format(sLine, sizeof(sLine), "%s??_", sLine);
						else
						{
							Format(sLine, sizeof(sLine), "%sXX_", sLine);
						}
					}
					// The currently drawn card from the stack
					case 2:
					{
						iSize = GetArraySize(g_hDrawnCards[client]);
						// Nothing drewn yet :o
						if(iSize == 0)
							Format(sLine, sizeof(sLine), "%s___", sLine);
						else
						{
							// Display the highest card.
							GetArrayArray(g_hDrawnCards[client], 0, iCard, 2);
							FormatCardToString(iCard, sCard, sizeof(sCard));
							
							Format(sLine, sizeof(sLine), "%s%s_", sLine, sCard);
						}
					}
					case 3:
					{
						Format(sLine, sizeof(sLine), "%s___", sLine);
					}
					// The ace stacks
					case 4, 5, 6, 7:
					{
						iSize = GetArraySize(g_hAceDecks[client][x-4]);
						// Nothing drewn yet :o
						if(iSize == 0)
							Format(sLine, sizeof(sLine), "%s___", sLine);
						else
						{
							// Display the highest card.
							GetArrayArray(g_hAceDecks[client][x-4], 0, iCard, 2);
							FormatCardToString(iCard, sCard, sizeof(sCard));
							
							Format(sLine, sizeof(sLine), "%s%s_", sLine, sCard);
						}
					}
				}
			}
			
			if(x != 0)
			{
				// Add an empty line between the upper field and the cards
				if(y == 2)
					Format(sLine, sizeof(sLine), "%s___", sLine);
				
				// Show how many cards are still on the stack
				if(y == 3)
				{
					iSize = GetArraySize(g_hCardLineDecks[client][x-1]);
					Format(sLine, sizeof(sLine), "%s+%d_", sLine, iSize);
				}
				
				// now we start our cards
				if(y > 3)
				{
					iSize = GetArraySize(g_hCardLines[client][x-1]);
					if(iSize > (y-4))
					{
						// Display the highest card.
						GetArrayArray(g_hCardLines[client][x-1], y-4, iCard, 2);
						FormatCardToString(iCard, sCard, sizeof(sCard));
						
						Format(sLine, sizeof(sLine), "%s%s_", sLine, sCard);
					}
					else
					{
						Format(sLine, sizeof(sLine), "%s___", sLine);
					}
				}
			}
		}
		DrawPanelText(hPanel, sLine);
		Format(sLine, sizeof(sLine), "");
	}
	
	SetPanelKeys(hPanel, (1<<9));
	g_bRedrawGamePanel[client] = true;
	SendPanelToClient(hPanel, client, Panel_HandleGame, MENU_TIME_FOREVER);
	g_bRedrawGamePanel[client] = false;
	CloseHandle(hPanel);
}

/**
 * Menu/Panel callbacks
 */
public Menu_HandleMainManu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:sInfo[16];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		
		// Start a new game.
		if(StrEqual(sInfo, "new"))
		{
			ResetSolitaireGame(param1);
			
			// Fill the deck with all available cards.
			// ace - king in 4 colors
			g_hCardDeck[param1] = CreateArray(2);
			g_hDrawnCards[param1] = CreateArray(2);
			new iCard[2];
			for(new c=0;c<4;c++)
			{
				for(new i=1;i<=13;i++)
				{
					iCard[CARD_COLOR] = c;
					iCard[CARD_VALUE] = i;
					PushArrayArray(g_hCardDeck[param1], iCard, 2);
				}
			}
			
			ShuffleCards(g_hCardDeck[param1]);
			
			// Put cards out.
			new iAmount = 1;
			for(new i=0;i<CARD_LINE_NUM;i++)
			{
				g_hCardLineDecks[param1][i] = CreateArray(2);
				g_hCardLines[param1][i] = CreateArray(2);
				// Put all cards except the last one "face-down" on the stack
				for(new c=0;c<(iAmount-1);c++)
				{
					GetArrayArray(g_hCardDeck[param1], 0, iCard, 2);
					PushArrayArray(g_hCardLineDecks[param1][i], iCard, 2);
					RemoveFromArray(g_hCardDeck[param1], 0);
				}
				
				// Put the last card faced up.
				GetArrayArray(g_hCardDeck[param1], 0, iCard, 2);
				PushArrayArray(g_hCardLines[param1][iAmount-1], iCard, 2);
				RemoveFromArray(g_hCardDeck[param1], 0);
				
				// Always put one more card on each line the farer we go to the right
				iAmount++;
			}
			
			for(new i=0;i<4;i++)
			{
				g_hAceDecks[param1][i] = CreateArray(2);
			}
			
			// Reset cursor
			g_iPlayerCursor[param1][COORD_X] = 1;
			g_iPlayerCursor[param1][COORD_Y] = 1;
			g_iPlayerSelection[param1][COORD_X] = 1;
			g_iPlayerSelection[param1][COORD_Y] = 1;
			g_bCardSelected[param1] = false;
			
			g_bInGame[param1] = true;
			
			g_iSessionTime[param1] = GetTime();
			g_hCountTime[param1] = CreateTimer(0.3, Timer_CountPlayedTime, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
			
			ShowGamePanel(param1);
		}
		// Resume old game.
		else if(StrEqual(sInfo, "resume"))
		{
			g_bInGame[param1] = true;
			g_iSessionTime[param1] = GetTime();
			g_hCountTime[param1] = CreateTimer(0.3, Timer_CountPlayedTime, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_CLIENT|FL_ATCONTROLS);
			ShowGamePanel(param1);
		}
		else if(StrEqual(sInfo, "top10"))
		{
			if(g_hDatabase != INVALID_HANDLE)
				SQL_TQueryF(g_hDatabase, SQL_FetchTop10, GetClientUserId(param1), DBPrio_Normal, "SELECT name, score, time FROM solitaire_players ORDER BY score DESC LIMIT 10;");
			else
				ShowMainMenu(param1);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Panel_HandleGame(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 10)
		{
			g_bInGame[param1] = false;
			ClearHandle(g_hCountTime[param1]);
			SetEntProp(param1, Prop_Send, "m_fFlags", FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND);
			Client_PrintToChat(param1, false, "{G}Solitaire{N} > {L}Game paused. Type {OG}!solitaire{L} to resume.");
		}
	}
	else if(action == MenuAction_Cancel && param2 == MenuCancel_Interrupted && !g_bRedrawGamePanel[param1])
	{
		g_bInGame[param1] = false;
		ClearHandle(g_hCountTime[param1]);
		SetEntProp(param1, Prop_Send, "m_fFlags", FL_FAKECLIENT|FL_ONGROUND|FL_PARTIALGROUND);
		Client_PrintToChat(param1, false, "{G}Solitaire{N} > {L}Game paused. Type {OG}!solitaire{L} to resume.");
	}
}

public Menu_HandleTop10(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ShowMainMenu(param1);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/**
 * Timer callbacks
 */
public Action:Timer_CountPlayedTime(Handle:timer, any:data)
{
	new client = GetClientOfUserId(data);
	if(!client)
		return Plugin_Stop;
	
	new iTime = GetTime();
	if(g_iSessionTime[client] != iTime)
	{
		g_iSessionTime[client] = iTime;
		g_iPlayedTime[client]++;
		if(!(g_iPlayedTime[client] % 10))
		{
			g_iScore[client] -= 2;
			if(g_iScore[client] < 0)
				g_iScore[client] = 0;
		}
	}
	
	return Plugin_Continue;
}

/**
 * Game functionality functions
 */
ResetSolitaireGame(client)
{
	if(g_hCardDeck[client] != INVALID_HANDLE)
	{
		ClearHandle(g_hCardDeck[client]);
	}
	
	if(g_hDrawnCards[client] != INVALID_HANDLE)
	{
		ClearHandle(g_hDrawnCards[client]);
	}
	
	for(new i=0;i<CARD_LINE_NUM;i++)
	{
		ClearHandle(g_hCardLines[client][i]);
		ClearHandle(g_hCardLineDecks[client][i]);
	}
	
	for(new i=0;i<4;i++)
	{
		ClearHandle(g_hAceDecks[client][i]);
	}
	
	g_iPlayerCursor[client][COORD_X] = -1;
	g_iPlayerCursor[client][COORD_Y] = -1;
	g_iPlayerSelection[client][COORD_X] = -1;
	g_iPlayerSelection[client][COORD_Y] = -1;
	g_bCardSelected[client] = false;
	
	for(new i=0;i<4;i++)
	{
		ClearHandle(g_hAceDecks[client][i]);
	}
	
	g_iScore[client] = 0;
	g_iPlayedTime[client] = 0;
	g_iSessionTime[client] = 0;
	
	ClearHandle(g_hCountTime[client]);
}

FormatCardToString(const iCard[2], String:sBuffer[], maxlen)
{
	switch(iCard[CARD_COLOR])
	{
		case CARD_SPADES:
			Format(sBuffer, maxlen, "%s", SUIT_SPADES);
		case CARD_DIAMONDS:
			Format(sBuffer, maxlen, "%s", SUIT_DIAMONDS);
		case CARD_HEARTS:
			Format(sBuffer, maxlen, "%s", SUIT_HEARTS);
		case CARD_CLUBS:
			Format(sBuffer, maxlen, "%s", SUIT_CLUBS);
	}
	
	switch(iCard[CARD_VALUE])
	{
		case 1:
			Format(sBuffer, maxlen, "%sA", sBuffer);
		// case 2..9: is disabled in sourcepawn ?! :(
		case 2, 3, 4, 5, 6, 7, 8, 9:
			Format(sBuffer, maxlen, "%s%d", sBuffer, iCard[CARD_VALUE]);
		// Duh.. That looks stupid, but i just got 2 chars available and 10 already got 2 O_o
		case 10:
			Format(sBuffer, maxlen, "%s1", sBuffer);
		case 11:
			Format(sBuffer, maxlen, "%sJ", sBuffer);
		case 12:
			Format(sBuffer, maxlen, "%sQ", sBuffer);
		case 13:
			Format(sBuffer, maxlen, "%sK", sBuffer);
	}
}

// Simply shuffles the array by swaping items 1000x randomly
ShuffleCards(Handle:hDeck)
{
	new iSize = GetArraySize(hDeck), iRandom, iRandom2;
	for(new i=0;i<8000;i++)
	{
		while((iRandom = Math_GetRandomInt(0, iSize-1)) == (iRandom2 = Math_GetRandomInt(0, iSize-1)))
		{ }
		
		SwapArrayItems(hDeck, iRandom, iRandom2);
	}
}

// Turns the newest card around on the deck
PullACard(client)
{
	new iSize = GetArraySize(g_hCardDeck[client]);
	
	new iCard[2];
	
	// No cards left.. rewind!
	if(iSize == 0)
	{
		iSize = GetArraySize(g_hDrawnCards[client]);
		for(new i=iSize-1;i>=0;i--)
		{
			GetArrayArray(g_hDrawnCards[client], i, iCard, 2);
			PushArrayArray(g_hCardDeck[client], iCard, 2);
		}
		ClearArray(g_hDrawnCards[client]);
		
		if(iSize > 0)
		{
			g_iScore[client] -= 100;
			if(g_iScore[client] < 0)
				g_iScore[client] = 0;
		}
	}
	
	if(iSize > 0)
	{
		GetArrayArray(g_hCardDeck[client], 0, iCard, 2);
		if(GetArraySize(g_hDrawnCards[client]) > 0)
		{
			ShiftArrayUp(g_hDrawnCards[client], 0);
			SetArrayArray(g_hDrawnCards[client], 0, iCard, 2);
		}
		else
		{
			PushArrayArray(g_hDrawnCards[client], iCard, 2);
		}
		
		RemoveFromArray(g_hCardDeck[client], 0);
	}
}

bool:GetCardAtPosition(client, iCoords[2], iCard[2])
{
	// Unset card initially
	iCard[CARD_COLOR] = -1;
	iCard[CARD_VALUE] = -1;
	
	new iWidth = CARD_LINE_NUM;
	
	// Need one more space for the cursor
	iWidth++;
	
	// Get the longest card row..
	new iHeight, iSize;
	for(new i=0;i<CARD_LINE_NUM;i++)
	{
		iSize = GetArraySize(g_hCardLines[client][i]);
		if(iHeight < iSize)
			iHeight = iSize;
	}
	
	// Add one for the cursor, one for the deck line, one for the number of cards left in stack line and one for the empty line.
	iHeight += 4;
	
	// Basic bound checks
	if(iCoords[COORD_X] < 1
	|| iCoords[COORD_X] >= iWidth
	|| iCoords[COORD_Y] < 1
	|| iCoords[COORD_Y] >= iHeight)
		return false;
	
	// Bad rows/column
	if((iCoords[COORD_X] == 3
	&& iCoords[COORD_Y] == 1)
	|| iCoords[COORD_Y] == 2
	|| iCoords[COORD_Y] == 3)
		return false;
	

	// First row
	if(iCoords[COORD_Y] == 1)
	{
		switch(iCoords[COORD_X])
		{
			// Drawn cards
			case 2:
			{
				iSize = GetArraySize(g_hDrawnCards[client]);
				if(iSize > 0)
				{
					GetArrayArray(g_hDrawnCards[client], 0, iCard, 2);
					return true;
				}
			}
			// Ace stacks
			case 4, 5, 6, 7:
			{
				iSize = GetArraySize(g_hAceDecks[client][iCoords[COORD_X]-4]);
				if(iSize > 0)
				{
					GetArrayArray(g_hAceDecks[client][iCoords[COORD_X]-4], 0, iCard, 2);
					return true;
				}
			}
		}
	}
	// Normal card lines
	else
	{
		iSize = GetArraySize(g_hCardLines[client][iCoords[COORD_X]-1]);
		if(iSize > 0 && iCoords[COORD_Y]-4 < iSize)
		{
			GetArrayArray(g_hCardLines[client][iCoords[COORD_X]-1], iCoords[COORD_Y]-4, iCard, 2);
			return true;
		}
	}
	
	return false;
}

bool:IsEmptyAcePosition(client, iCoords[2])
{
	if(iCoords[COORD_Y] != 1 || iCoords[COORD_X] < 4)
		return false;
	
	return GetArraySize(g_hAceDecks[client][iCoords[COORD_X]-4]) == 0;
}

bool:IsEmptyRootPosition(client, iCoords[2])
{
	if(iCoords[COORD_Y] != 4 || iCoords[COORD_X] < 1)
		return false;
	
	return GetArraySize(g_hCardLines[client][iCoords[COORD_X]-1]) == 0;
}

bool:MoveCards(client, iCoordsFrom[2], iCardFrom[2], iCoordsTo[2])
{
	// We want to move a card from a line
	if(iCoordsFrom[COORD_Y] >= 4)
	{
		new iSize = GetArraySize(g_hCardLines[client][iCoordsFrom[COORD_X]-1]);
		
		// We want to move more than one card in that row.
		if(iCoordsFrom[COORD_Y]-4 != iSize-1)
		{
			// We can't move more than 1 card at a time to the ace stacks
			if(iCoordsTo[COORD_Y] == 1)
			{
				return false;
			}
			
			new iCard[2];
			for(new i=iCoordsFrom[COORD_Y]-4;i<iSize;i++)
			{
				GetArrayArray(g_hCardLines[client][iCoordsFrom[COORD_X]-1], i, iCard, 2);
				PushArrayArray(g_hCardLines[client][iCoordsTo[COORD_X]-1], iCard, 2);
			}
		}
		// We want to put it on an ace stack at the top
		else if(iCoordsTo[COORD_Y] == 1)
		{
			if(GetArraySize(g_hAceDecks[client][iCoordsTo[COORD_X]-4]) == 0)
			{
				PushArrayArray(g_hAceDecks[client][iCoordsTo[COORD_X]-4], iCardFrom, 2);
			}
			else
			{
				ShiftArrayUp(g_hAceDecks[client][iCoordsTo[COORD_X]-4], 0);
				SetArrayArray(g_hAceDecks[client][iCoordsTo[COORD_X]-4], 0, iCardFrom, 2);
			}
			// Tableau to Foundation
			g_iScore[client] += 10;
		}
		// Moving it to a normal line
		else
		{
			PushArrayArray(g_hCardLines[client][iCoordsTo[COORD_X]-1], iCardFrom, 2);
		}
	}
	// We're moving a drawn card or one from the ace stacks
	else
	{
		// We want to move it to an ace stack
		if(iCoordsTo[COORD_Y] == 1)
		{
			if(GetArraySize(g_hAceDecks[client][iCoordsTo[COORD_X]-4]) == 0)
			{
				PushArrayArray(g_hAceDecks[client][iCoordsTo[COORD_X]-4], iCardFrom, 2);
			}
			else
			{
				ShiftArrayUp(g_hAceDecks[client][iCoordsTo[COORD_X]-4], 0);
				SetArrayArray(g_hAceDecks[client][iCoordsTo[COORD_X]-4], 0, iCardFrom, 2);
			}
			
			// Moving a card from the waste to the foundation
			if(iCoordsFrom[COORD_X] == 2)
				g_iScore[client] += 10;
		}
		// Moving it to a normal line
		else
		{
			PushArrayArray(g_hCardLines[client][iCoordsTo[COORD_X]-1], iCardFrom, 2);
			// Moving a card from the foundation to the tableau
			if(iCoordsFrom[COORD_X] != 2)
			{
				g_iScore[client] -= 15;
				if(g_iScore[client] < 0)
					g_iScore[client] = 0;
			}
			// Moving a card from the wastey to the tableau
			else
				g_iScore[client] += 5;
		}
	}
	
	RemoveCardsFromStack(client, iCoordsFrom);
	
	return true;
}

RemoveCardsFromStack(client, iCoords[2])
{
	// First row
	if(iCoords[COORD_Y] == 1)
	{
		// Drawn card
		if(iCoords[COORD_X] == 2)
		{
			new iSize = GetArraySize(g_hDrawnCards[client]);
			if(iSize > 0)
			{
				// Just remove the card at the top.
				RemoveFromArray(g_hDrawnCards[client], 0);
			}
		}
		// Ace stacks
		else if(iCoords[COORD_X] >= 4)
		{
			new iSize = GetArraySize(g_hAceDecks[client][iCoords[COORD_X]-4]);
			if(iSize > 0)
			{
				// Just remove the card at the top.
				RemoveFromArray(g_hAceDecks[client][iCoords[COORD_X]-4], 0);
			}
		}
	}
	// Normal card lines
	else if(iCoords[COORD_Y] >= 4)
	{
		new iSize = GetArraySize(g_hCardLines[client][iCoords[COORD_X]-1]);
		if(iSize > 0)
		{
			while(iSize - iCoords[COORD_Y]+4 > 0)
			{
				// Remove cards from the end
				RemoveFromArray(g_hCardLines[client][iCoords[COORD_X]-1], iSize-1);
				iSize--;
			}
		}
	}
}

bool:CanPlaceCardOnAnother(iCard1[2], iCard2[2], iCoords2[2])
{
	// Cards have different real color and the first one is lower than the second
	if((((iCard1[CARD_COLOR] == CARD_DIAMONDS || iCard1[CARD_COLOR] == CARD_HEARTS)
	&& (iCard2[CARD_COLOR] == CARD_CLUBS || iCard2[CARD_COLOR] == CARD_SPADES))
	|| ((iCard2[CARD_COLOR] == CARD_DIAMONDS || iCard2[CARD_COLOR] == CARD_HEARTS)
	&& (iCard1[CARD_COLOR] == CARD_CLUBS || iCard1[CARD_COLOR] == CARD_SPADES)))
	&& iCard1[CARD_VALUE] == iCard2[CARD_VALUE]-1)
		return true;
	// You're allowed to put cards of the same color on the ace stack - ascending.
	else if(iCoords2[COORD_Y] == 1 
	&& iCard2[CARD_COLOR] == iCard1[CARD_COLOR]
	&& iCard1[CARD_VALUE] == iCard2[CARD_VALUE]+1)
		return true;
	
	return false;
}

stock ClearHandle(&Handle:data)
{
	if(data != INVALID_HANDLE)
	{
		CloseHandle(data);
		data = INVALID_HANDLE;
	}
}