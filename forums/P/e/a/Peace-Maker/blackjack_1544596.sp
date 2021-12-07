/**
 * This is a sourcemod blackjack implementation
 * It's based off sega74rus' eventscript version
 * http://addons.eventscripts.com/addons/view/blackjack
 * 
 * by Peace-Maker
 * visit http://www.wcfan.de/
 */
#pragma semicolon 1
#include <sourcemod>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <clientprefs>

#define PLUGIN_VERSION "1.0"

#define SUIT_SPADES "♠"
#define SUIT_DIAMONDS "♦"
#define SUIT_HEARTS "♥"
#define SUIT_CLUBS "♣"

enum GameStatus {
	Status_None = 0,
	Status_BlackJack,
	Status_Win,
	Status_Lose,
	Status_Draw
}

new Handle:g_hCVMaxBet;
new Handle:g_hCVAdvertOnDeath;

new Handle:g_hAutoShowCookie = INVALID_HANDLE;
new Handle:g_hAutoHideCookie = INVALID_HANDLE;
new bool:g_bAutoShow[MAXPLAYERS+1] = {false,...};
new bool:g_bAutoHide[MAXPLAYERS+1] = {true,...};

new String:g_sSuits[4][5];
new String:g_sCards[13][3];
new g_iCardValue[13] = {2,3,4,5,6,7,8,9,10,10,10,10,11};

new Handle:g_hPlayerCards[MAXPLAYERS+1];
new Handle:g_hDealerCards[MAXPLAYERS+1];
new Handle:g_hDealerThink[MAXPLAYERS+1];
new g_iPlayerPot[MAXPLAYERS+1];
new g_iPlayerLastPot[MAXPLAYERS+1];
new g_iPlayerCardValue[MAXPLAYERS+1];
new g_iDealerCardValue[MAXPLAYERS+1];
new bool:g_bIsIngame[MAXPLAYERS+1] = {false,...};
new bool:g_bStays[MAXPLAYERS+1] = {false,...};
new bool:g_bDealerEnds[MAXPLAYERS+1] = {false,...};
new GameStatus:g_iGameStatus[MAXPLAYERS+1] = {Status_None,...};
new bool:g_bPlayerIsInMenu[MAXPLAYERS+1] = {false,...};
new bool:g_bMoneyDealt[MAXPLAYERS+1] = {false,...};

// For advert
new bool:g_bPlayedBJ[MAXPLAYERS+1] = {false,...};

public Plugin:myinfo = 
{
	name = "Blackjack",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Blackjack panel game",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_blackjack_version", PLUGIN_VERSION, "Blackjack version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVMaxBet = CreateConVar("sm_blackjack_maxbet", "5000", "Set the maximal amount of money a player is able to bet per game.", FCVAR_PLUGIN, true, 0.0);
	g_hCVAdvertOnDeath = CreateConVar("sm_blackjack_advertondeath", "1", "Show an advert on death, if player didn't play already?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Some basic setup to fill our deck
	// Define all available cards
	Format(g_sSuits[0], sizeof(g_sSuits[]), SUIT_SPADES);
	Format(g_sSuits[1], sizeof(g_sSuits[]), SUIT_DIAMONDS);
	Format(g_sSuits[2], sizeof(g_sSuits[]), SUIT_HEARTS);
	Format(g_sSuits[3], sizeof(g_sSuits[]), SUIT_CLUBS);
	
	Format(g_sCards[0], sizeof(g_sCards[]), "2");
	Format(g_sCards[1], sizeof(g_sCards[]), "3");
	Format(g_sCards[2], sizeof(g_sCards[]), "4");
	Format(g_sCards[3], sizeof(g_sCards[]), "5");
	Format(g_sCards[4], sizeof(g_sCards[]), "6");
	Format(g_sCards[5], sizeof(g_sCards[]), "7");
	Format(g_sCards[6], sizeof(g_sCards[]), "8");
	Format(g_sCards[7], sizeof(g_sCards[]), "9");
	Format(g_sCards[8], sizeof(g_sCards[]), "10");
	Format(g_sCards[9], sizeof(g_sCards[]), "J");
	Format(g_sCards[10], sizeof(g_sCards[]), "Q");
	Format(g_sCards[11], sizeof(g_sCards[]), "K");
	Format(g_sCards[12], sizeof(g_sCards[]), "A");
	
	RegConsoleCmd("sm_bj", Cmd_BlackJack, "Opens the blackjack game.");
	RegConsoleCmd("sm_blackjack", Cmd_BlackJack, "Opens the blackjack game.");
	RegConsoleCmd("sm_bjhelp", Cmd_BlackJackHelp, "Displays the blackjack help and settings.");
	
	if(LibraryExists("clientprefs"))
	{
		g_hAutoShowCookie = RegClientCookie("BlackJack_AutoShow", "Show the blackjack panel on death?", CookieAccess_Public);
		g_hAutoHideCookie = RegClientCookie("BlackJack_AutoHide", "Hide the blackjack panel on spawn?", CookieAccess_Public);
		// For lateloading..
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && AreClientCookiesCached(i))
				OnClientCookiesCached(i);
		}
	}
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
}

public OnClientCookiesCached(client)
{
	decl String:sBuffer[5];
	GetClientCookie(client, g_hAutoShowCookie, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "1"))
		g_bAutoShow[client] = true;
	else
		g_bAutoShow[client] = false;
	
	
	GetClientCookie(client, g_hAutoHideCookie, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "0"))
		g_bAutoHide[client] = false;
	else
		g_bAutoHide[client] = true;
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "clientprefs"))
	{
		g_hAutoShowCookie = RegClientCookie("BlackJack_AutoShow", "Show the blackjack panel on death?", CookieAccess_Public);
		g_hAutoHideCookie = RegClientCookie("BlackJack_AutoHide", "Hide the blackjack panel on spawn?", CookieAccess_Public);
	}
}

public OnClientDisconnect(client)
{
	if(g_hPlayerCards[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerCards[client]);
		g_hPlayerCards[client] = INVALID_HANDLE;
	}
	
	if(g_hDealerCards[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hDealerCards[client]);
		g_hDealerCards[client] = INVALID_HANDLE;
	}
	
	if(g_hDealerThink[client] != INVALID_HANDLE)
	{
		KillTimer(g_hDealerThink[client]);
		g_hDealerThink[client] = INVALID_HANDLE;
	}
	g_iPlayerPot[client] = 0;
	g_iPlayerLastPot[client] = 0;
	g_iPlayerCardValue[client] = 0;
	g_iDealerCardValue[client] = 0;
	g_bIsIngame[client] = false;
	g_bStays[client] = false;
	g_bDealerEnds[client] = false;
	g_bPlayerIsInMenu[client] = false;
	g_bAutoShow[client] = false;
	g_bAutoHide[client] = true;
	g_bMoneyDealt[client] = false;
	g_iGameStatus[client] = Status_None;
	g_bPlayedBJ[client] = false;
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bPlayerIsInMenu[client] && g_bAutoHide[client])
		CancelClientMenu(client);
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bAutoShow[client] && !g_bPlayerIsInMenu[client])
	{
		Cmd_BlackJack(client, 0);
	}
	
	if(GetConVarBool(g_hCVAdvertOnDeath) && !g_bPlayedBJ[client] && !g_bAutoShow[client])
		PrintToChat(client, "\x05Blackjack \x01>\x04 Type \x01!bj\x04 to play blackjack while waiting! Type \x01!bjhelp\x04 for help.");
}

public Action:Cmd_BlackJack(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Blackjack: You have to be ingame to play.");
		return Plugin_Handled;
	}
	
	g_bPlayedBJ[client] = true;
	
	// He's already playing. Show the playing panel
	if(g_bIsIngame[client])
	{
		ShowGamePanel(client);
	}
	else
	{
		ShowBetPanel(client);
	}
	return Plugin_Handled;
}

public Action:Cmd_BlackJackHelp(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Blackjack: You have to be ingame.");
		return Plugin_Handled;
	}
	
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "-=BLACKJACK=-");
	
	DrawPanelItem(hPanel, "Play now");
	decl String:sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "Show on death: %s", (g_bAutoShow[client]?"Yes":"No"));
	DrawPanelItem(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "Hide on spawn: %s", (g_bAutoHide[client]?"Yes":"No"));
	DrawPanelItem(hPanel, sBuffer);
	DrawPanelItem(hPanel, "Display rules");
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	Format(sBuffer, sizeof(sBuffer), "Maximal bet is %d$.", GetConVarInt(g_hCVMaxBet));
	DrawPanelItem(hPanel, sBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	DrawPanelItem(hPanel, "Number-cards count as their natural value; the pictures count as 10;", ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "aces are valued as either 1 or 11 according to the player's best interest.", ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
	
	SetPanelCurrentKey(hPanel, 10);
	DrawPanelItem(hPanel, "Close");
	
	SendPanelToClient(hPanel, client, Menu_Help, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
	
	return Plugin_Handled;
}

ShowBetPanel(client)
{
	new iAccount = Client_GetMoney(client);
	// Restore last bet
	if(g_iPlayerLastPot[client] > 0 && iAccount >= g_iPlayerLastPot[client] && g_iPlayerPot[client] == 0)
	{
		g_iPlayerPot[client] = g_iPlayerLastPot[client];
		g_iPlayerLastPot[client] = 0;
		iAccount -= g_iPlayerPot[client];
		Client_SetMoney(client, iAccount);
	}
	
	new Handle:hPanel = CreatePanel();
	decl String:sBuffer[64];
	SetPanelTitle(hPanel, "-=BLACKJACK=-");
	Format(sBuffer, sizeof(sBuffer), " you : %d$         pot : %d$", iAccount, g_iPlayerPot[client]);
	DrawPanelItem(hPanel, sBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "_______________", ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "             DEAL     +100$     -100$", ITEMDRAW_RAWLINE);
	if(g_iPlayerPot[client] > 0)
		DrawPanelItem(hPanel, "press        1              2            3", ITEMDRAW_RAWLINE);
	else
		DrawPanelItem(hPanel, "press                        2            3", ITEMDRAW_RAWLINE);
	
	Format(sBuffer, sizeof(sBuffer), "Maximal bet is %d$.", GetConVarInt(g_hCVMaxBet));
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, sBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	SetPanelCurrentKey(hPanel, 10);
	DrawPanelItem(hPanel, "Pause ||");
	
	// Accept key presses for 1,2,3 and 0.
	SetPanelKeys(hPanel, ((1<<0)|(1<<1)|(1<<2)|(1<<9)));
	
	if(SendPanelToClient(hPanel, client, Menu_Betting, MENU_TIME_FOREVER))
		g_bPlayerIsInMenu[client] = true;
	CloseHandle(hPanel);
}

ShowGamePanel(client)
{
	new iCountHigh = GetCardCount(client, true);
	new iCountLow = GetCardCount(client, false);
	
	// He busted?
	if(iCountHigh > 21 && iCountLow > 21)
	{
		g_iGameStatus[client] = Status_Lose;
	}
	g_iPlayerCardValue[client] = iCountHigh <= 21?iCountHigh:iCountLow;
	
	
	// Build the game panel
	new Handle:hPanel = CreatePanel();
	decl String:sBuffer[64];
	SetPanelTitle(hPanel, "-=BLACKJACK=-");
	Format(sBuffer, sizeof(sBuffer), " YOU : %d$         POT : %d$", Client_GetMoney(client), g_iPlayerPot[client]);
	DrawPanelItem(hPanel, sBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "_______________", ITEMDRAW_RAWLINE);
	
	// Build dealer card graphics
	Format(sBuffer, sizeof(sBuffer), "");
	new iSize = GetArraySize(g_hDealerCards[client]);
	new cards[2];
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(g_hDealerCards[client], i, cards, 2);
		if(strlen(sBuffer) == 0)
			Format(sBuffer, sizeof(sBuffer), "[%s%s]", g_sCards[cards[1]], g_sSuits[cards[0]]);
		else
			Format(sBuffer, sizeof(sBuffer), "%s [%s%s]", sBuffer, g_sCards[cards[1]], g_sSuits[cards[0]]);
	}
	
	// The player is still able to hit, so we're not showing all dealers cards. He just has one anyways.
	if(!g_bStays[client])
	{
		Format(sBuffer, sizeof(sBuffer), "DEALER  %s", sBuffer);
	}
	// The game ended. Show dealer cards.
	else
	{
		Format(sBuffer, sizeof(sBuffer), "DEALER  %s = ", sBuffer);
		
		// Game ended? Show the final value
		if(g_bDealerEnds[client])
		{
			// He got a black jack?
			if(g_iGameStatus[client] == Status_Lose && GetArraySize(g_hDealerCards[client]) == 2 && g_iDealerCardValue[client] == 21)
				Format(sBuffer, sizeof(sBuffer), "%s21 !!!  BLACKJACK", sBuffer);
			else
				Format(sBuffer, sizeof(sBuffer), "%s%d", sBuffer, g_iDealerCardValue[client]);
		}
		// Game is still running? (Dealer is thinking)
		else
		{
			new iDealerCards1 = GetCardCount(client, false, true);
			new iDealerCards2 = GetCardCount(client, true, true);
			if(iDealerCards1 == iDealerCards2 || iDealerCards1 > 21 || iDealerCards2 > 21)
				Format(sBuffer, sizeof(sBuffer), "%s%d", sBuffer, g_iDealerCardValue[client]);
			else
				Format(sBuffer, sizeof(sBuffer), "%s%d/%d", sBuffer, iDealerCards1, iDealerCards2);
		}
	}
	DrawPanelItem(hPanel, sBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	
	// Build players card graphics
	Format(sBuffer, sizeof(sBuffer), "");
	iSize = GetArraySize(g_hPlayerCards[client]);
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(g_hPlayerCards[client], i, cards, 2);
		if(strlen(sBuffer) == 0)
			Format(sBuffer, sizeof(sBuffer), "[%s%s]", g_sCards[cards[1]], g_sSuits[cards[0]]);
		else
			Format(sBuffer, sizeof(sBuffer), "%s [%s%s]", sBuffer, g_sCards[cards[1]], g_sSuits[cards[0]]);
	}
	
	Format(sBuffer, sizeof(sBuffer), "YOU  %s = ", sBuffer);
	// The player stays and the dealer thinks...
	if(g_bStays[client])
	{
		// Blackjack!
		if(g_iGameStatus[client] == Status_BlackJack)
			Format(sBuffer, sizeof(sBuffer), "%s21 !!!  BLACKJACK", sBuffer);
		// Just show the card value
		else
			Format(sBuffer, sizeof(sBuffer), "%s%d", sBuffer, g_iPlayerCardValue[client]);
	}
	// Player is still able to play
	else
	{
		// Player has no ace or busted. Just show the value
		if(g_iGameStatus[client] != Status_None || iCountHigh == iCountLow || iCountHigh > 21 || iCountLow > 21)
			Format(sBuffer, sizeof(sBuffer), "%s%d", sBuffer, g_iPlayerCardValue[client]);
		else
			Format(sBuffer, sizeof(sBuffer), "%s%d/%d", sBuffer, iCountHigh, iCountLow);
	}
	DrawPanelItem(hPanel, sBuffer, ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	// He's still open to act. (Didn't press stay or double)
	if(g_iGameStatus[client] == Status_None && !g_bStays[client])
	{
		DrawPanelItem(hPanel, "              HIT     STAY   DOUBLE", ITEMDRAW_RAWLINE);
		DrawPanelItem(hPanel, "press        1          2           3", ITEMDRAW_RAWLINE);
		DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		SetPanelKeys(hPanel, ((1<<0)|(1<<1)|(1<<2)|(1<<9)));
	}
	else if(g_iGameStatus[client] != Status_None)
	{
		switch(g_iGameStatus[client])
		{
			case Status_Lose:
			{
				// The dealer is closer to 21.
				if(g_bDealerEnds[client])
					DrawPanelItem(hPanel, "  you lose   :(", ITEMDRAW_RAWLINE);
				// You _overbuyed_ yourself!
				else
					DrawPanelItem(hPanel, "  bust   :(", ITEMDRAW_RAWLINE);
			}
			case Status_BlackJack:
			{
				DrawPanelItem(hPanel, " !!! you win !!!", ITEMDRAW_RAWLINE);
				if(!g_bMoneyDealt[client])
					Client_SetMoney(client, Client_GetMoney(client)+g_iPlayerPot[client]*3);
			}
			case Status_Win:
			{
				DrawPanelItem(hPanel, " you win  :D", ITEMDRAW_RAWLINE);
				if(!g_bMoneyDealt[client])
					Client_SetMoney(client, Client_GetMoney(client)+g_iPlayerPot[client]*2);
			}
			case Status_Draw:
			{
				DrawPanelItem(hPanel, "  dead heat", ITEMDRAW_RAWLINE);
				if(!g_bMoneyDealt[client])
					Client_SetMoney(client, Client_GetMoney(client)+g_iPlayerPot[client]);
			}
		}
		DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		SetPanelCurrentKey(hPanel, 1);
		DrawPanelItem(hPanel, "Try again");
		
		// We dealt with the money. Don't give it again, when he pauses and resumes.
		g_bMoneyDealt[client] = true;
	}
	else
	{
		DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		DrawPanelItem(hPanel, "", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	}
	
	SetPanelCurrentKey(hPanel, 10);
	DrawPanelItem(hPanel, "Pause ||");
	
	if(SendPanelToClient(hPanel, client, Menu_GameHandler, MENU_TIME_FOREVER))
		g_bPlayerIsInMenu[client] = true;
	CloseHandle(hPanel);
}

public Menu_Betting(Handle:menu, MenuAction:action, param1, param2)
{
	// This panel is closed.
	g_bPlayerIsInMenu[param1] = false;
	if(action == MenuAction_Select)
	{
		// DEAL
		if(param2 == 1)
		{
			// Did he bet money?!
			if(g_iPlayerPot[param1] == 0)
			{
				ShowBetPanel(param1);
				return;
			}
			
			if(g_hPlayerCards[param1] == INVALID_HANDLE)
				g_hPlayerCards[param1] = CreateArray(2);
			else
				ClearArray(g_hPlayerCards[param1]);
			if(g_hDealerCards[param1] == INVALID_HANDLE)
				g_hDealerCards[param1] = CreateArray(2);
			else
				ClearArray(g_hDealerCards[param1]);
			
			if(g_hDealerThink[param1] != INVALID_HANDLE)
			{
				KillTimer(g_hDealerThink[param1]);
				g_hDealerThink[param1] = INVALID_HANDLE;
			}
			
			g_iPlayerLastPot[param1] = g_iPlayerPot[param1];
			
			g_bIsIngame[param1] = true;
			g_bDealerEnds[param1] = false;
			g_iGameStatus[param1] = Status_None;
			g_bStays[param1] = false;
			g_bMoneyDealt[param1] = false;
			g_iPlayerCardValue[param1] = 0;
			g_iDealerCardValue[param1] = 0;
			
			PullPlayerCard(param1);
			PullPlayerCard(param1);
			PullDealerCard(param1);
			
			ShowGamePanel(param1);
		}
		else if(param2 == 2)
		{
			new iAccount = Client_GetMoney(param1);
			new iLimit = GetConVarInt(g_hCVMaxBet);
			if(iAccount >= 100 && (iLimit == 0 || (g_iPlayerPot[param1]+100) <= iLimit))
			{
				g_iPlayerPot[param1] += 100;
				Client_SetMoney(param1, iAccount-100);
			}
			ShowBetPanel(param1);
		}
		else if(param2 == 3)
		{
			if((g_iPlayerPot[param1]-100) >= 0)
			{
				new iAccount = Client_GetMoney(param1);
				g_iPlayerPot[param1] -= 100;
				Client_SetMoney(param1, iAccount+100);
			}
			ShowBetPanel(param1);
		}
		else if(param2 == 10)
		{
			PrintToChat(param1, "\x05Blackjack \x01>\x04 Type \x01!bj\x04 to resume!");
		}
	}
}

public Menu_GameHandler(Handle:menu, MenuAction:action, param1, param2)
{
	// This panel is closed.
	g_bPlayerIsInMenu[param1] = false;
	if(action == MenuAction_Select)
	{
		// This game is done, he clicked "try again"
		if(param2 == 1 && g_iGameStatus[param1] != Status_None)
		{
			g_iPlayerPot[param1] = 0;
			g_iGameStatus[param1] = Status_None;
			g_bIsIngame[param1] = false;
			ShowBetPanel(param1);
		}
		// HITME
		else if(param2 == 1 && g_iGameStatus[param1] != Status_Lose)
		{
			PullPlayerCard(param1);
			ShowGamePanel(param1);
		}
		// STAND
		// Let the dealer get his cards. Player won't be able to do anything anymore.
		else if(param2 == 2 && g_iGameStatus[param1] != Status_Lose)
		{
			g_bStays[param1] = true;
			g_hDealerThink[param1] = CreateTimer(0.7, Timer_DealerThink, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			TriggerTimer(g_hDealerThink[param1]);
		}
		// DOUBLE
		else if(param2 == 3 && g_iGameStatus[param1] != Status_Lose)
		{
			new iAccount = Client_GetMoney(param1);
			new iLimit = GetConVarInt(g_hCVMaxBet);
			if(iAccount >= g_iPlayerPot[param1] && (iLimit == 0 || (g_iPlayerPot[param1]*2) <= iLimit))
			{
				Client_SetMoney(param1, iAccount-g_iPlayerPot[param1]);
				g_iPlayerPot[param1] *= 2;
				g_iGameStatus[param1] = Status_None;
				PullPlayerCard(param1);
				
				g_bStays[param1] = true;
				ShowGamePanel(param1);
				if(g_iGameStatus[param1] == Status_None)
				{
					g_hDealerThink[param1] = CreateTimer(0.7, Timer_DealerThink, GetClientUserId(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					g_bDealerEnds[param1] = false;
					
				}
				return;
			}
			
			ShowGamePanel(param1);
		}
		else if(param2 == 10)
		{
			PrintToChat(param1, "\x05Blackjack \x01>\x04 Type \x01!bj\x04 to resume!");
		}
	}
}

public Menu_Help(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		// Play now
		if(param2 == 1)
		{
			Cmd_BlackJack(param1, 0);
		}
		// Set auto play
		else if(param2 == 2)
		{
			g_bAutoShow[param1] = !g_bAutoShow[param1];
			if(LibraryExists("clientprefs"))
			{
				if(g_bAutoShow[param1])
					SetClientCookie(param1, g_hAutoShowCookie, "1");
				else
					SetClientCookie(param1, g_hAutoShowCookie, "0");
			}
			
			// Redraw the panel
			Cmd_BlackJackHelp(param1, 0);
		}
		// Set auto hide
		else if(param2 == 3)
		{
			g_bAutoHide[param1] = !g_bAutoHide[param1];
			if(LibraryExists("clientprefs"))
			{
				if(g_bAutoHide[param1])
					SetClientCookie(param1, g_hAutoHideCookie, "1");
				else
					SetClientCookie(param1, g_hAutoHideCookie, "0");
			}
			
			// Redraw the panel
			Cmd_BlackJackHelp(param1, 0);
		}
		else if(param2 == 4)
		{
			new Handle:hPanel = CreatePanel();
			SetPanelTitle(hPanel, "Blackjack rules");
			DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
			DrawPanelItem(hPanel, "The goal is to bring the total card value to 21 or less without exceeding it.", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "If you exceed 21 you lose, if the dealer does, you win.", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "If both are below 21, the closer one wins.", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "You've a blackjack, if you've got 21 points with only your first 2 cards.", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "You decide to get another card (hit) or stay with your current value (stay)", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "and let the dealer get his cards. You're able to double your bet if you've", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "enough money and get one last more card and stay.", ITEMDRAW_RAWLINE);
			DrawPanelItem(hPanel, "", ITEMDRAW_SPACER);
			
			SetPanelCurrentKey(hPanel, 8);
			DrawPanelItem(hPanel, "Back");
			SetPanelCurrentKey(hPanel, 10);
			DrawPanelItem(hPanel, "Close");
			
			SendPanelToClient(hPanel, param1, Menu_Rules, MENU_TIME_FOREVER);
			CloseHandle(hPanel);
		}
	}
}

public Menu_Rules(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 8)
		{
			Cmd_BlackJackHelp(param1, 0);
		}
	}
}

public Action:Timer_DealerThink(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	
	// Get the dealer another card
	PullDealerCard(client);
	
	new iCountHigh = GetCardCount(client, true, true);
	new iCountLow = GetCardCount(client, false, true);
	
	// Dealer got blackjack.
	if(GetArraySize(g_hDealerCards[client]) == 2 && iCountHigh == 21)
	{
		g_iDealerCardValue[client] = 21;
		g_bDealerEnds[client] = true;
		// Player has blackjack either?
		if(GetArraySize(g_hPlayerCards[client]) == 2 && g_iPlayerCardValue[client] == 21)
			g_iGameStatus[client] = Status_Draw;
		else
			g_iGameStatus[client] = Status_Lose;
	}
	// He lost
	else if(iCountHigh > 21 && iCountLow > 21)
	{
		g_iDealerCardValue[client] = iCountHigh;
		g_bDealerEnds[client] = true;
		// Player has blackjack?
		if(GetArraySize(g_hPlayerCards[client]) == 2 && g_iPlayerCardValue[client] == 21)
			g_iGameStatus[client] = Status_BlackJack;
		else
			g_iGameStatus[client] = Status_Win;
	}
	// He got 21, but with more than 2 cards.
	else if(iCountHigh == 21 || iCountLow == 21)
	{
		g_iDealerCardValue[client] = 21;
		g_bDealerEnds[client] = true;
		// Player got a blackjack?
		if(GetArraySize(g_hPlayerCards[client]) == 2 && g_iPlayerCardValue[client] == 21)
			g_iGameStatus[client] = Status_BlackJack;
		// Player has 21 either?
		else if(g_iPlayerCardValue[client] == 21)
			g_iGameStatus[client] = Status_Draw;
		else
			g_iGameStatus[client] = Status_Lose;
	}
	// Dealer is still under 21, continue pulling cards
	// (We check for < 17 below)
	else
	{
		// Dealer has to count an ace as 11 if he doesn't get more than 21 if he does.
		g_iDealerCardValue[client] = iCountHigh <= 21?iCountHigh:iCountLow;
	}
	
	// Dealer has to stop at >= 17
	if(g_iDealerCardValue[client] >= 17 && !g_bDealerEnds[client])
	{
		g_bDealerEnds[client] = true;
		if(g_iDealerCardValue[client] < g_iPlayerCardValue[client])
		{
			// Player has blackjack?
			if(GetArraySize(g_hPlayerCards[client]) == 2 && g_iPlayerCardValue[client] == 21)
				g_iGameStatus[client] = Status_BlackJack;
			else
				g_iGameStatus[client] = Status_Win;
		}
		else if(g_iDealerCardValue[client] == g_iPlayerCardValue[client])
		{
			g_iGameStatus[client] = Status_Draw;
		}
		else
		{
			g_iGameStatus[client] = Status_Lose;
		}
	}
	
	ShowGamePanel(client);
	
	// Stop the timer, if the game ended.
	if(g_bDealerEnds[client])
	{
		g_hDealerThink[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	else
		return Plugin_Continue;
}

PullPlayerCard(client)
{
	new newCard[2];
	newCard[0] = GetURandomIntRange(0, 3);
	newCard[1] = GetURandomIntRange(0, 12);
	PushArrayArray(g_hPlayerCards[client], newCard, 2);
}

PullDealerCard(client)
{
	new newCard[2];
	newCard[0] = GetURandomIntRange(0, 3);
	newCard[1] = GetURandomIntRange(0, 12);
	PushArrayArray(g_hDealerCards[client], newCard, 2);
}

// Messy function to get the points of the cards
GetCardCount(client, bool:highace=true, bool:dealer=false)
{
	new iSize;
	if(!dealer)
		iSize = GetArraySize(g_hPlayerCards[client]);
	else
		iSize = GetArraySize(g_hDealerCards[client]);
	if(iSize == 0)
		return 0;
	
	new iCount, cards[2];
	new bool:multipleAces = false;
	for(new i=0;i<iSize;i++)
	{
		if(!dealer)
			GetArrayArray(g_hPlayerCards[client], i, cards, 2);
		else
			GetArrayArray(g_hDealerCards[client], i, cards, 2);
		// The ace can be 11 or 1 point
		// Counting 2 aces as 11 is stupid, so only count one.
		if(cards[1] == 12 && (!highace || multipleAces))
		{
			iCount += 1;
		}
		else
		{
			iCount += g_iCardValue[cards[1]];
			if(cards[1] == 12)
				multipleAces = true;
		}
	}
	return iCount;
}

stock GetURandomIntRange(min, max)
{
    return (GetURandomInt() % (max-min+1)) + min;
}

stock Client_GetMoney(client)
{
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

stock Client_SetMoney(client, amount)
{
	SetEntProp(client, Prop_Send, "m_iAccount", amount);
}