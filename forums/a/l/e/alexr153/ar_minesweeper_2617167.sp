#pragma semicolon 1

#define DEBUG

#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "hAlexr"
#define CHAT_PREFIX "[\x04MINESWEEPER\x01]"

#include <sourcemod>
#include <sdktools>
#include <store>

#pragma newdecls required

ConVar sm_mines_max_bet;
ConVar sm_one_mine_game;
ConVar sm_three_mine_game;
ConVar sm_five_mine_game;
ConVar sm_twenty_four_mine_game;

//Clients Rows
char row1[MAXPLAYERS + 1][64];
char row2[MAXPLAYERS + 1][64];
char row3[MAXPLAYERS + 1][64];
char row4[MAXPLAYERS + 1][64];
char row5[MAXPLAYERS + 1][64];


//TIMERS
Handle g_hTimer[MAXPLAYERS + 1];

//Clients Booleans
bool g_bPlayerJoined[MAXPLAYERS + 1];
bool g_bInstructions[MAXPLAYERS + 1];
bool g_bCloseMenu[MAXPLAYERS + 1];
bool g_bCloseMine[MAXPLAYERS + 1];
bool g_bCloseGame[MAXPLAYERS + 1];
bool g_bInGame[MAXPLAYERS + 1];
bool g_bPlayerCashed[MAXPLAYERS + 1];


//Cliens Integers
int g_iMines[MAXPLAYERS + 1];
int g_iBet[MAXPLAYERS + 1];
int g_iMine[MAXPLAYERS + 1];
int g_iWinnings[MAXPLAYERS + 1];
int g_iNextProfit[MAXPLAYERS + 1];
int g_iSelected[MAXPLAYERS + 1];

//Clients Floats
float g_fProfit[MAXPLAYERS + 1];

//Array list
ArrayList g_aMines[MAXPLAYERS + 1];

//Row checker
int g_iMineCheck[MAXPLAYERS + 1][25];
bool g_iMineSelected[MAXPLAYERS + 1][25];

bool g_bLateLoaded;

public Plugin myinfo = 
{
	name = "[STORE] MineSweeper", 
	author = PLUGIN_AUTHOR, 
	description = "A gamemode of gambling for Zephyrus store", 
	version = PLUGIN_VERSION, 
	url = "www.trugamingcs.tk"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	sm_mines_max_bet = CreateConVar("sm_mines_max_bet", "5000", "The max amount a player can bet", FCVAR_HIDDEN, true, 1.0, true, 999999.9);
	sm_one_mine_game = CreateConVar("sm_one_mine_game", "1", "Enables 1 mine to be a choice for the game", FCVAR_HIDDEN, true, 0.0, true, 1.0);
	sm_three_mine_game = CreateConVar("sm_three_mine_game", "1", "Enables 3 mines to be a choice for the game", FCVAR_HIDDEN, true, 0.0, true, 1.0);
	sm_five_mine_game = CreateConVar("sm_five_mine_game", "1", "Enables 5 mines to be a choice for the game", FCVAR_HIDDEN, true, 0.0, true, 1.0);
	sm_twenty_four_mine_game = CreateConVar("sm_twenty_four_mine_game", "1", "Enables 24 mines to be a choice for the game", FCVAR_HIDDEN, true, 0.0, true, 1.0);
	
	
	RegConsoleCmd("sm_mines", CMD_Minesweeper, "Opens the minesweeper menu");
	RegConsoleCmd("sm_minesweeper", CMD_Minesweeper, "Opens the minesweeper menu");
	RegConsoleCmd("sm_sweeper", CMD_Minesweeper, "Opens the minesweeper menu");
	
	if (g_bLateLoaded)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_aMines[client] = new ArrayList(1024);
}

public void OnClientDisconnect(int client)
{
	resetPlayer(client);
	g_bPlayerJoined[client] = false;
}

public Action CMD_Minesweeper(int client, int args)
{
	if (!g_bPlayerJoined[client] && !g_bInGame[client])
	{
		g_iBet[client] = 100;
		g_bPlayerJoined[client] = true;
		PrintToChat(client, CHAT_PREFIX..." Minesweeper lobby menu \x06opened!");
	}
	else if (g_bPlayerJoined[client] && !g_bInGame[client])
	{
		g_bPlayerJoined[client] = false;
		PrintToChat(client, CHAT_PREFIX..." Minesweeper lobby menu \x05closed!");
		g_hTimer[client] = INVALID_HANDLE;
	} else if (g_bInGame[client])
	{
		PrintToChat(client, CHAT_PREFIX..." You can not leave when you're currently in a game!");
	}
	if (g_hTimer[client] == INVALID_HANDLE)
		g_hTimer[client] = CreateTimer(0.1, mineMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action mineMenu(Handle timer, int client)
{
	if (!g_bPlayerJoined[client])
		return Plugin_Stop;
	
	if (g_bCloseMenu[client])
		return Plugin_Handled;
	
	if (g_bCloseGame[client])
		resetPlayer(client);
	
	Panel lobby = new Panel();
	
	char title[64];
	
	Format(title, 64, "Minesweeper! Bet: [ %i ] Credits: [ %i ]", g_iBet[client], Store_GetClientCredits(client));
	
	lobby.SetTitle(title);
	
	lobby.DrawItem("Instructions", ITEMDRAW_CONTROL);
	
	if (g_bInstructions[client])
	{
		lobby.DrawText("- You're giving a 5x5 bored with mines randomly placed in one of the boxes.");
		lobby.DrawText("- Clicking a square without any mines inside of it will give you profit,");
		lobby.DrawText("- but clicking a square with a mine will result in a lost, as well as loosing your credits you have bet.");
		lobby.DrawText("- To open a square click on the number corresponding with the text SELECT on it.");
		lobby.DrawText("- Controls are simple UP, DOWN, LEFT, and RIGHT.");
		lobby.DrawText("- Hope this helped, Good luck!");
	}
	
	if (g_iBet[client] != GetConVarInt(sm_mines_max_bet) && (g_iBet[client] + 1) <= GetConVarInt(sm_mines_max_bet))
		lobby.DrawItem("+1", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("+1", ITEMDRAW_DISABLED);
	
	if (g_iBet[client] != 0 && (g_iBet[client] - 1) >= 100)
		lobby.DrawItem("-1", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("-1", ITEMDRAW_DISABLED);
	
	if (g_iBet[client] != GetConVarInt(sm_mines_max_bet) && (g_iBet[client] + 10) <= GetConVarInt(sm_mines_max_bet))
		lobby.DrawItem("+10", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("+10", ITEMDRAW_DISABLED);
	
	if (g_iBet[client] != 0 && (g_iBet[client] - 10) >= 100)
		lobby.DrawItem("-10", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("-10", ITEMDRAW_DISABLED);
	
	if (g_iBet[client] != GetConVarInt(sm_mines_max_bet) && (g_iBet[client] + 10) <= GetConVarInt(sm_mines_max_bet))
		lobby.DrawItem("+100", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("+100", ITEMDRAW_DISABLED);
	
	if (g_iBet[client] != 0 && (g_iBet[client] - 100) >= 100)
		lobby.DrawItem("-100", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("-100", ITEMDRAW_DISABLED);
	
	if (g_iBet[client] != 0 && Store_GetClientCredits(client) >= g_iBet[client] && g_iBet[client] <= GetConVarInt(sm_mines_max_bet))
		lobby.DrawItem("Start", ITEMDRAW_CONTROL);
	else
		lobby.DrawItem("Start", ITEMDRAW_DISABLED);
	
	lobby.DrawItem("Leave", ITEMDRAW_CONTROL);
	
	lobby.Send(client, lobbyMenu_Callback, 1);
	
	return Plugin_Continue;
}

public int lobbyMenu_Callback(Handle menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 1:
				{
					if (!g_bInstructions[client])
						g_bInstructions[client] = true;
					else
						g_bInstructions[client] = false;
				}
				case 2:
				{
					g_iBet[client] += 1;
				}
				case 3:
				{
					g_iBet[client] -= 1;
				}
				case 4:
				{
					g_iBet[client] += 10;
				}
				case 5:
				{
					g_iBet[client] -= 10;
				}
				case 6:
				{
					g_iBet[client] += 100;
				}
				case 7:
				{
					g_iBet[client] -= 100;
				}
				case 8:
				{
					if (g_bCloseMine[client])
						g_bCloseMine[client] = false;
					
					int clientCredits = Store_GetClientCredits(client);
					if (clientCredits >= g_iBet[client])
					{
						CreateTimer(0.1, minesMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
						Store_SetClientCredits(client, clientCredits - g_iBet[client]);
						g_bCloseMenu[client] = true;
					} else {
						PrintToChat(client, CHAT_PREFIX..." You don't have enough credits to gamble. YOUR CREDITS: [ %i ]", clientCredits);
					}
				}
				case 9:
				{
					leftGame(client);
					PrintToChat(client, CHAT_PREFIX..." You have left Minesweeper");
				}
			}
		}
	}
}

public Action minesMenu(Handle timer, int client)
{
	if (!g_bPlayerJoined[client])
	{
		resetPlayer(client);
		return Plugin_Handled;
	}
	
	if (g_bCloseMine[client])
		return Plugin_Stop;
	
	Panel menuMines = new Panel();
	
	char title[64];
	
	Format(title, 64, "Amount of mines. BET: [ %i ]", g_iBet[client]);
	
	menuMines.SetTitle(title);
	
	menuMines.DrawText("This menu is for amount of mines to put in the game");
	menuMines.DrawText("Note: The higher amount of bombs, the higher the profit will be.");
	
	if(sm_one_mine_game.BoolValue)
	menuMines.DrawItem("1 Mine", ITEMDRAW_CONTROL);
	
	if(sm_three_mine_game.BoolValue)
	menuMines.DrawItem("3 Mines", ITEMDRAW_CONTROL);
	
	if(sm_five_mine_game.BoolValue)
	menuMines.DrawItem("5 Mines", ITEMDRAW_CONTROL);
	
	if(sm_twenty_four_mine_game.BoolValue)
	menuMines.DrawItem("24 Mines", ITEMDRAW_CONTROL);
	
	menuMines.DrawItem("BACK", ITEMDRAW_CONTROL);
	
	menuMines.Send(client, mineMenuCallback, 1);
	return Plugin_Continue;
}

public int mineMenuCallback(Handle menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 1:
				{
					char bet[32];
					IntToString(g_iBet[client], bet, 32);
					float multiplier = StringToFloat(bet) / 35.71428571428571;
					FloatToString(multiplier, bet, 32);
					g_iMines[client] = 1;
					g_iMine[client] = 1;
					g_bCloseMine[client] = true;
					g_iNextProfit[client] = StringToInt(bet);
					getGame(client);
					g_bInGame[client] = true;
					g_iWinnings[client] = g_iBet[client];
					CreateTimer(0.1, gameMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
				}
				case 2:
				{
					char bet[32];
					IntToString(g_iBet[client], bet, 32);
					float multiplier = StringToFloat(bet) / 9.009009009009009;
					FloatToString(multiplier, bet, 32);
					g_iMines[client] = 3;
					g_iMine[client] = 1;
					g_bCloseMine[client] = true;
					g_iNextProfit[client] = StringToInt(bet);
					getGame(client);
					g_bInGame[client] = true;
					g_iWinnings[client] = g_iBet[client];
					CreateTimer(0.1, gameMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
				}
				case 3:
				{
					char bet[32];
					IntToString(g_iBet[client], bet, 32);
					float multiplier = StringToFloat(bet) / 3.484320557491289;
					FloatToString(multiplier, bet, 32);
					g_iMines[client] = 5;
					g_iMine[client] = 1;
					g_bCloseMine[client] = true;
					g_iNextProfit[client] = StringToInt(bet);
					getGame(client);
					g_bInGame[client] = true;
					g_iWinnings[client] = g_iBet[client];
					CreateTimer(0.1, gameMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
				}
				case 4:
				{
					char bet[32];
					IntToString(g_iBet[client], bet, 32);
					float multiplier = StringToFloat(bet) / 0.05;
					FloatToString(multiplier, bet, 32);
					g_iMines[client] = 24;
					g_iMine[client] = 1;
					g_bCloseMine[client] = true;
					g_iNextProfit[client] = StringToInt(bet);
					getGame(client);
					g_bInGame[client] = true;
					g_iWinnings[client] = g_iBet[client];
					CreateTimer(0.1, gameMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
				}
				case 5:
				{
					g_bCloseMine[client] = true;
					g_bCloseMenu[client] = false;
					int clientCredits = Store_GetClientCredits(client);
					Store_SetClientCredits(client, clientCredits + g_iBet[client]);
				}
			}
		}
	}
}

public Action gameMenu(Handle menu, int client)
{
	if (g_bCloseGame[client])
	{
		g_bCloseMenu[client] = false;
		return Plugin_Stop;
	}
	
	getRows(client);
	
	Panel game = new Panel();
	
	char title[64];
	
	Format(title, 64, "Next: [ %i ] Bet [ %i ] Stake: [ %i ]", g_iNextProfit[client], g_iBet[client], g_iWinnings[client]);
	
	game.SetTitle(title);
	
	game.DrawText(row1[client]);
	game.DrawText(row2[client]);
	game.DrawText(row3[client]);
	game.DrawText(row4[client]);
	game.DrawText(row5[client]);
	
	game.DrawItem("⇡", ITEMDRAW_CONTROL);
	game.DrawItem("⇣", ITEMDRAW_CONTROL);
	game.DrawItem("⇠", ITEMDRAW_CONTROL);
	game.DrawItem("⇢", ITEMDRAW_CONTROL);
	
	game.DrawItem("SELECT", ITEMDRAW_CONTROL);
	
	game.DrawItem("CASH OUT", ITEMDRAW_CONTROL);
	
	game.Send(client, gameMenu_Callback, 1);
	return Plugin_Continue;
}

public int gameMenu_Callback(Handle menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (g_bPlayerCashed[client])
				return;
			switch (param2)
			{
				case 1:
				{
					if (g_iMine[client] > 5 || (g_iMine[client] - 5) >= 1)
						g_iMine[client] -= 5;
				}
				case 2:
				{
					if (g_iMine[client] < 21 || (g_iMine[client] + 5) <= 25)
						g_iMine[client] += 5;
				}
				case 3:
				{
					if (g_iMine[client] != 1 || (g_iMine[client] - 1) >= 1)
						g_iMine[client] -= 1;
				}
				case 4:
				{
					if (g_iMine[client] != 25 || (g_iMine[client] + 1) <= 25)
						g_iMine[client] += 1;
				}
				case 5:
				{
					if (g_iMineSelected[client][(g_iMine[client] - 1)] == true)
						return;
					
					g_iSelected[client] += 1;
					if (g_iMineCheck[client][(g_iMine[client] - 1)] == 2)
					{
						gameOver(client);
					} else {
						char bet[32];
						IntToString(g_iNextProfit[client], bet, 32);
						g_iMineSelected[client][(g_iMine[client] - 1)] = true;
						g_iWinnings[client] = g_iBet[client] + g_iNextProfit[client];
						if (g_iMines[client] == 1)
						{
							if (g_iSelected[client] != 24)
							{
								if (g_iSelected[client] == 1)
									g_fProfit[client] = StringToFloat(bet) / 0.875;
								else
									g_fProfit[client] /= 0.875;
								FloatToString(g_fProfit[client], bet, 32);
								g_iNextProfit[client] = StringToInt(bet);
							} else if (g_iSelected[client] == 24)
							{
								cashOut(client);
							}
						}
						else if (g_iMines[client] == 3)
						{
							if (g_iSelected[client] != 22)
							{
								if (g_iSelected[client] == 1)
									g_fProfit[client] = StringToFloat(bet) / 0.8283582089552239;
								else
									g_fProfit[client] /= 0.8283582089552239;
								FloatToString(g_fProfit[client], bet, 32);
								g_iNextProfit[client] = StringToInt(bet);
							} else if (g_iSelected[client] == 22) {
								cashOut(client);
							}
						}
						else if (g_iMines[client] == 5)
						{
							if (g_iSelected[client] != 20)
							{
								if (g_iSelected[client] == 1)
									g_fProfit[client] = StringToFloat(bet) / 0.7526132404181185;
								else
									g_fProfit[client] /= 0.7526132404181185;
								FloatToString(g_fProfit[client], bet, 32);
								g_iNextProfit[client] = StringToInt(bet);
							} else if (g_iSelected[client] == 20)
							{
								cashOut(client);
							}
						} else if (g_iMines[client] == 24)
						{
							if (g_iSelected[client] >= 1)
								cashOut(client);
						}
					}
				}
				case 6:
				{
					if (g_iSelected[client] >= 1)
						cashOut(client);
				}
			}
		}
	}
}

void cashOut(int client)
{
	g_bPlayerCashed[client] = true;
	PrintToChat(client, CHAT_PREFIX..." \x05GAME OVER! \x01 You have cashed out at %i mines selected. WON: (%i)", g_iSelected[client], g_iWinnings[client]);
	for (int i = 0; i <= 24; i++)
	{
		if (g_iMineCheck[client][i] == 2)
			g_iMineSelected[client][i] = true;
	}
	CreateTimer(3.0, resetClient, client);
	int clientCredits = Store_GetClientCredits(client);
	Store_SetClientCredits(client, clientCredits + g_iWinnings[client]);
	resetGame(client);
}

void gameOver(int client)
{
	g_bPlayerCashed[client] = true;
	PrintToChat(client, CHAT_PREFIX..." \x05GAME OVER! \x01There was a mine on the block, better luck next time. LOST: (%i)", g_iBet[client]);
	for (int i = 0; i <= 24; i++)
	{
		if (g_iMineCheck[client][i] == 2)
			g_iMineSelected[client][i] = true;
	}
	CreateTimer(3.0, resetClient, client);
	resetGame(client);
}

public Action resetClient(Handle menu, int client)
{
	g_bInGame[client] = false;
	g_bCloseGame[client] = true;
	return Plugin_Stop;
}

void resetPlayer(int client)
{
	g_bPlayerJoined[client] = true;
	g_bInstructions[client] = false;
	g_bCloseMenu[client] = false;
	g_bCloseMine[client] = false;
	g_bCloseGame[client] = false;
	g_bInGame[client] = false;
	g_bPlayerCashed[client] = false;
	
	
	//INTS
	g_iMine[client] = 1;
	g_iBet[client] = 100;
	g_iMines[client] = 0;
	g_iWinnings[client] = 0;
	g_iNextProfit[client] = 0;
	g_iSelected[client] = 0;
	
	//Floats
	g_fProfit[client] = 0.0;
	
	for (int i = 0; i <= 24; i++)
	{
		g_iMineCheck[client][i] = 1;
		g_iMineSelected[client][i] = false;
	}
}

void getGame(int client)
{
	if (g_iMines[client] == 1)
	{
		char mine[64];
		int random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
	} else if (g_iMines[client] == 3)
	{
		char mine[64];
		int random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
	} else if (g_iMines[client] == 5)
	{
		char mine[64];
		int random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
		random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
		
	} else if (g_iMines[client] == 24)
	{
		char mine[64];
		int random = GetRandomInt(0, 24);
		IntToString(random, mine, 64);
		g_aMines[client].PushString(mine);
	}
	
	int didOnce;
	for (int i = 0; i < g_aMines[client].Length; i++)
	{
		if (g_iMines[client] != 24)
		{
			char mines[64];
			g_aMines[client].GetString(i, mines, 64);
			
			didOnce++;
			
			if (didOnce <= g_iMines[client])
			{
				g_iMineCheck[client][(StringToInt(mines) - 1)] = 2;
			}
		} else if (g_iMines[client] == 24) {
			char mines[64];
			g_aMines[client].GetString(i, mines, 64);
			
			for (int j = 0; j <= 24; j++)
			{
				if (j != StringToInt(mines))
				{
					g_iMineCheck[client][j] = 2;
				} else {
					g_iMineCheck[client][j] = 1;
				}
			}
		}
	}
}

void getRows(int client)
{
	char block1[64], block2[64], block3[64], block4[64], block5[64];
	
	//Row 1
	if (!g_iMineSelected[client][0] && g_iMine[client] == 1)
		Format(block1, 64, "(☐)");
	else if (g_iMineCheck[client][0] == 2 && g_iMineSelected[client][0] && g_iMine[client] == 1)
		Format(block1, 64, "(X)");
	else if (g_iMineCheck[client][0] == 2 && g_iMineSelected[client][0] && g_iMine[client] != 1)
		Format(block1, 64, "X");
	else if (g_iMineSelected[client][0] && g_iMine[client] == 1)
		Format(block1, 64, "(✓)");
	else if (g_iMineSelected[client][0] && g_iMine[client] != 1)
		Format(block1, 64, "✓");
	else if (!g_iMineSelected[client][0] && g_iMine[client] != 1)
		Format(block1, 64, "☐");
	
	
	if (!g_iMineSelected[client][1] && g_iMine[client] == 2)
		Format(block2, 64, "(☐)");
	else if (g_iMineCheck[client][1] == 2 && g_iMineSelected[client][1] && g_iMine[client] == 2)
		Format(block2, 64, "(X)");
	else if (g_iMineCheck[client][1] == 2 && g_iMineSelected[client][1] && g_iMine[client] != 2)
		Format(block2, 64, "X");
	else if (g_iMineSelected[client][1] && g_iMine[client] == 2)
		Format(block2, 64, "(✓)");
	else if (g_iMineSelected[client][1] && g_iMine[client] != 2)
		Format(block2, 64, "✓");
	else if (!g_iMineSelected[client][1] && g_iMine[client] != 2)
		Format(block2, 64, "☐");
	
	if (!g_iMineSelected[client][2] && g_iMine[client] == 3)
		Format(block3, 64, "(☐)");
	else if (g_iMineCheck[client][2] == 2 && g_iMineSelected[client][2] && g_iMine[client] == 3)
		Format(block3, 64, "(X)");
	else if (g_iMineCheck[client][2] == 2 && g_iMineSelected[client][2] && g_iMine[client] != 3)
		Format(block3, 64, "X");
	else if (g_iMineSelected[client][2] && g_iMine[client] == 3)
		Format(block3, 64, "(✓)");
	else if (g_iMineSelected[client][2] && g_iMine[client] != 3)
		Format(block3, 64, "✓");
	else if (!g_iMineSelected[client][2] && g_iMine[client] != 3)
		Format(block3, 64, "☐");
	
	if (!g_iMineSelected[client][3] && g_iMine[client] == 4)
		Format(block4, 64, "(☐)");
	else if (g_iMineCheck[client][3] == 2 && g_iMineSelected[client][3] && g_iMine[client] == 4)
		Format(block4, 64, "(X)");
	else if (g_iMineCheck[client][3] == 2 && g_iMineSelected[client][3] && g_iMine[client] != 4)
		Format(block4, 64, "X");
	else if (g_iMineSelected[client][3] && g_iMine[client] == 4)
		Format(block4, 64, "(✓)");
	else if (g_iMineSelected[client][3] && g_iMine[client] != 4)
		Format(block4, 64, "✓");
	else if (!g_iMineSelected[client][3] && g_iMine[client] != 4)
		Format(block4, 64, "☐");
	
	if (!g_iMineSelected[client][4] && g_iMine[client] == 5)
		Format(block5, 64, "(☐)");
	else if (g_iMineCheck[client][4] == 2 && g_iMineSelected[client][4] && g_iMine[client] == 5)
		Format(block5, 64, "(X)");
	else if (g_iMineCheck[client][4] == 2 && g_iMineSelected[client][4] && g_iMine[client] != 5)
		Format(block5, 64, "X");
	else if (g_iMineSelected[client][4] && g_iMine[client] == 5)
		Format(block5, 64, "(✓)");
	else if (g_iMineSelected[client][4] && g_iMine[client] != 5)
		Format(block5, 64, "✓");
	else if (!g_iMineSelected[client][4] && g_iMine[client] != 5)
		Format(block5, 64, "☐");
	
	Format(row1[client], 64, "%s %s %s %s %s", block1, block2, block3, block4, block5);
	
	if (!g_iMineSelected[client][5] && g_iMine[client] == 6)
		Format(block1, 64, "(☐)");
	else if (g_iMineCheck[client][5] == 2 && g_iMineSelected[client][5] && g_iMine[client] == 6)
		Format(block1, 64, "(X)");
	else if (g_iMineCheck[client][5] == 2 && g_iMineSelected[client][5] && g_iMine[client] != 6)
		Format(block1, 64, "X");
	else if (g_iMineSelected[client][5] && g_iMine[client] == 6)
		Format(block1, 64, "(✓)");
	else if (g_iMineSelected[client][5] && g_iMine[client] != 6)
		Format(block1, 64, "✓");
	else if (!g_iMineSelected[client][5] && g_iMine[client] != 6)
		Format(block1, 64, "☐");
	
	if (!g_iMineSelected[client][6] && g_iMine[client] == 7)
		Format(block2, 64, "(☐)");
	else if (g_iMineCheck[client][6] == 2 && g_iMineSelected[client][6] && g_iMine[client] == 7)
		Format(block2, 64, "(X)");
	else if (g_iMineCheck[client][6] == 2 && g_iMineSelected[client][6] && g_iMine[client] != 7)
		Format(block2, 64, "X");
	else if (g_iMineSelected[client][6] && g_iMine[client] == 7)
		Format(block2, 64, "(✓)");
	else if (g_iMineSelected[client][6] && g_iMine[client] != 7)
		Format(block2, 64, "✓");
	else if (!g_iMineSelected[client][6] && g_iMine[client] != 7)
		Format(block2, 64, "☐");
	
	if (!g_iMineSelected[client][7] && g_iMine[client] == 8)
		Format(block3, 64, "(☐)");
	else if (g_iMineCheck[client][7] == 2 && g_iMineSelected[client][7] && g_iMine[client] == 8)
		Format(block3, 64, "(X)");
	else if (g_iMineCheck[client][7] == 2 && g_iMineSelected[client][7] && g_iMine[client] != 8)
		Format(block3, 64, "X");
	else if (g_iMineSelected[client][7] && g_iMine[client] == 8)
		Format(block3, 64, "(✓)");
	else if (g_iMineSelected[client][7] && g_iMine[client] != 8)
		Format(block3, 64, "✓");
	else if (!g_iMineSelected[client][7] && g_iMine[client] != 8)
		Format(block3, 64, "☐");
	
	if (!g_iMineSelected[client][8] && g_iMine[client] == 9)
		Format(block4, 64, "(☐)");
	else if (g_iMineCheck[client][8] == 2 && g_iMineSelected[client][8] && g_iMine[client] == 9)
		Format(block4, 64, "(X)");
	else if (g_iMineCheck[client][8] == 2 && g_iMineSelected[client][8] && g_iMine[client] != 9)
		Format(block4, 64, "X");
	else if (g_iMineSelected[client][8] && g_iMine[client] == 9)
		Format(block4, 64, "(✓)");
	else if (g_iMineSelected[client][8] && g_iMine[client] != 9)
		Format(block4, 64, "✓");
	else if (!g_iMineSelected[client][8] && g_iMine[client] != 9)
		Format(block4, 64, "☐");
	
	if (!g_iMineSelected[client][9] && g_iMine[client] == 10)
		Format(block5, 64, "(☐)");
	else if (g_iMineCheck[client][9] == 2 && g_iMineSelected[client][9] && g_iMine[client] == 10)
		Format(block5, 64, "(X)");
	else if (g_iMineCheck[client][9] == 2 && g_iMineSelected[client][9] && g_iMine[client] != 10)
		Format(block5, 64, "X");
	else if (g_iMineSelected[client][9] && g_iMine[client] == 10)
		Format(block5, 64, "(✓)");
	else if (g_iMineSelected[client][9] && g_iMine[client] != 10)
		Format(block5, 64, "✓");
	else if (!g_iMineSelected[client][9] && g_iMine[client] != 10)
		Format(block5, 64, "☐");
	
	Format(row2[client], 64, "%s %s %s %s %s", block1, block2, block3, block4, block5);
	
	if (!g_iMineSelected[client][10] && g_iMine[client] == 11)
		Format(block1, 64, "(☐)");
	else if (g_iMineCheck[client][10] == 2 && g_iMineSelected[client][10] && g_iMine[client] == 11)
		Format(block1, 64, "(X)");
	else if (g_iMineCheck[client][10] == 2 && g_iMineSelected[client][10] && g_iMine[client] != 11)
		Format(block1, 64, "X");
	else if (g_iMineSelected[client][10] && g_iMine[client] == 11)
		Format(block1, 64, "(✓)");
	else if (g_iMineSelected[client][10] && g_iMine[client] != 11)
		Format(block1, 64, "✓");
	else if (!g_iMineSelected[client][10] && g_iMine[client] != 11)
		Format(block1, 64, "☐");
	
	if (!g_iMineSelected[client][11] && g_iMine[client] == 12)
		Format(block2, 64, "(☐)");
	else if (g_iMineCheck[client][11] == 2 && g_iMineSelected[client][11] && g_iMine[client] == 12)
		Format(block2, 64, "(X)");
	else if (g_iMineCheck[client][11] == 2 && g_iMineSelected[client][11] && g_iMine[client] != 12)
		Format(block2, 64, "X");
	else if (g_iMineSelected[client][11] && g_iMine[client] == 12)
		Format(block2, 64, "(✓)");
	else if (g_iMineSelected[client][11] && g_iMine[client] != 12)
		Format(block2, 64, "✓");
	else if (!g_iMineSelected[client][11] && g_iMine[client] != 12)
		Format(block2, 64, "☐");
	
	if (!g_iMineSelected[client][12] && g_iMine[client] == 13)
		Format(block3, 64, "(☐)");
	else if (g_iMineCheck[client][12] == 2 && g_iMineSelected[client][12] && g_iMine[client] == 13)
		Format(block3, 64, "(X)");
	else if (g_iMineCheck[client][12] == 2 && g_iMineSelected[client][12] && g_iMine[client] != 13)
		Format(block3, 64, "X");
	else if (g_iMineSelected[client][12] && g_iMine[client] == 13)
		Format(block3, 64, "(✓)");
	else if (g_iMineSelected[client][12] && g_iMine[client] != 13)
		Format(block3, 64, "✓");
	else if (!g_iMineSelected[client][12] && g_iMine[client] != 13)
		Format(block3, 64, "☐");
	
	if (!g_iMineSelected[client][13] && g_iMine[client] == 14)
		Format(block4, 64, "(☐)");
	else if (g_iMineCheck[client][13] == 2 && g_iMineSelected[client][13] && g_iMine[client] == 14)
		Format(block4, 64, "(X)");
	else if (g_iMineCheck[client][13] == 2 && g_iMineSelected[client][13] && g_iMine[client] != 14)
		Format(block4, 64, "X");
	else if (g_iMineSelected[client][13] && g_iMine[client] == 14)
		Format(block4, 64, "(✓)");
	else if (g_iMineSelected[client][13] && g_iMine[client] != 14)
		Format(block4, 64, "✓");
	else if (!g_iMineSelected[client][13] && g_iMine[client] != 14)
		Format(block4, 64, "☐");
	
	if (!g_iMineSelected[client][14] && g_iMine[client] == 15)
		Format(block5, 64, "(☐)");
	else if (g_iMineCheck[client][14] == 2 && g_iMineSelected[client][14] && g_iMine[client] == 15)
		Format(block5, 64, "(X)");
	else if (g_iMineCheck[client][14] == 2 && g_iMineSelected[client][14] && g_iMine[client] != 15)
		Format(block5, 64, "X");
	else if (g_iMineSelected[client][14] && g_iMine[client] == 15)
		Format(block5, 64, "(✓)");
	else if (g_iMineSelected[client][14] && g_iMine[client] != 15)
		Format(block5, 64, "✓");
	else if (!g_iMineSelected[client][14] && g_iMine[client] != 15)
		Format(block5, 64, "☐");
	
	Format(row3[client], 64, "%s %s %s %s %s", block1, block2, block3, block4, block5);
	
	if (!g_iMineSelected[client][15] && g_iMine[client] == 16)
		Format(block1, 64, "(☐)");
	else if (g_iMineCheck[client][15] == 2 && g_iMineSelected[client][15] && g_iMine[client] == 16)
		Format(block1, 64, "(X)");
	else if (g_iMineCheck[client][15] == 2 && g_iMineSelected[client][15] && g_iMine[client] != 16)
		Format(block1, 64, "X");
	else if (g_iMineSelected[client][15] && g_iMine[client] == 16)
		Format(block1, 64, "(✓)");
	else if (g_iMineSelected[client][15] && g_iMine[client] != 16)
		Format(block1, 64, "✓");
	else if (!g_iMineSelected[client][15] && g_iMine[client] != 16)
		Format(block1, 64, "☐");
	
	if (!g_iMineSelected[client][16] && g_iMine[client] == 17)
		Format(block2, 64, "(☐)");
	else if (g_iMineCheck[client][16] == 2 && g_iMineSelected[client][16] && g_iMine[client] == 17)
		Format(block2, 64, "(X)");
	else if (g_iMineCheck[client][16] == 2 && g_iMineSelected[client][16] && g_iMine[client] != 17)
		Format(block2, 64, "X");
	else if (g_iMineSelected[client][16] && g_iMine[client] == 17)
		Format(block2, 64, "(✓)");
	else if (g_iMineSelected[client][16] && g_iMine[client] != 17)
		Format(block2, 64, "✓");
	else if (!g_iMineSelected[client][16] && g_iMine[client] != 17)
		Format(block2, 64, "☐");
	
	if (!g_iMineSelected[client][17] && g_iMine[client] == 18)
		Format(block3, 64, "(☐)");
	else if (g_iMineCheck[client][17] == 2 && g_iMineSelected[client][17] && g_iMine[client] == 18)
		Format(block3, 64, "(X)");
	else if (g_iMineCheck[client][17] == 2 && g_iMineSelected[client][17] && g_iMine[client] != 18)
		Format(block3, 64, "X");
	else if (g_iMineSelected[client][17] && g_iMine[client] == 18)
		Format(block3, 64, "(✓)");
	else if (g_iMineSelected[client][17] && g_iMine[client] != 18)
		Format(block3, 64, "✓");
	else if (!g_iMineSelected[client][17] && g_iMine[client] != 18)
		Format(block3, 64, "☐");
	
	if (!g_iMineSelected[client][18] && g_iMine[client] == 19)
		Format(block4, 64, "(☐)");
	else if (g_iMineCheck[client][18] == 2 && g_iMineSelected[client][18] && g_iMine[client] == 19)
		Format(block4, 64, "(X)");
	else if (g_iMineCheck[client][18] == 2 && g_iMineSelected[client][18] && g_iMine[client] != 19)
		Format(block4, 64, "X");
	else if (g_iMineSelected[client][18] && g_iMine[client] == 19)
		Format(block4, 64, "(✓)");
	else if (g_iMineSelected[client][18] && g_iMine[client] != 19)
		Format(block4, 64, "✓");
	else if (!g_iMineSelected[client][18] && g_iMine[client] != 19)
		Format(block4, 64, "☐");
	
	if (!g_iMineSelected[client][19] && g_iMine[client] == 20)
		Format(block5, 64, "(☐)");
	else if (g_iMineCheck[client][19] == 2 && g_iMineSelected[client][19] && g_iMine[client] == 20)
		Format(block5, 64, "(X)");
	else if (g_iMineCheck[client][19] == 2 && g_iMineSelected[client][19] && g_iMine[client] != 20)
		Format(block5, 64, "X");
	else if (g_iMineSelected[client][19] && g_iMine[client] == 20)
		Format(block5, 64, "(✓)");
	else if (g_iMineSelected[client][19] && g_iMine[client] != 20)
		Format(block5, 64, "✓");
	else if (!g_iMineSelected[client][19] && g_iMine[client] != 20)
		Format(block5, 64, "☐");
	
	Format(row4[client], 64, "%s %s %s %s %s", block1, block2, block3, block4, block5);
	
	if (!g_iMineSelected[client][20] && g_iMine[client] == 21)
		Format(block1, 64, "(☐)");
	else if (g_iMineCheck[client][20] == 2 && g_iMineSelected[client][20] && g_iMine[client] == 21)
		Format(block1, 64, "(X)");
	else if (g_iMineCheck[client][20] == 2 && g_iMineSelected[client][20] && g_iMine[client] != 21)
		Format(block1, 64, "X");
	else if (g_iMineSelected[client][20] && g_iMine[client] == 21)
		Format(block1, 64, "(✓)");
	else if (g_iMineSelected[client][20] && g_iMine[client] != 21)
		Format(block1, 64, "✓");
	else if (!g_iMineSelected[client][20] && g_iMine[client] != 21)
		Format(block1, 64, "☐");
	
	if (!g_iMineSelected[client][21] && g_iMine[client] == 22)
		Format(block2, 64, "(☐)");
	else if (g_iMineCheck[client][21] == 2 && g_iMineSelected[client][21] && g_iMine[client] == 22)
		Format(block2, 64, "(X)");
	else if (g_iMineCheck[client][21] == 2 && g_iMineSelected[client][21] && g_iMine[client] != 22)
		Format(block2, 64, "X");
	else if (g_iMineSelected[client][21] && g_iMine[client] == 22)
		Format(block2, 64, "(✓)");
	else if (g_iMineSelected[client][21] && g_iMine[client] != 22)
		Format(block2, 64, "✓");
	else if (!g_iMineSelected[client][21] && g_iMine[client] != 22)
		Format(block2, 64, "☐");
	
	if (!g_iMineSelected[client][22] && g_iMine[client] == 23)
		Format(block3, 64, "(☐)");
	else if (g_iMineCheck[client][22] == 2 && g_iMineSelected[client][22] && g_iMine[client] == 23)
		Format(block3, 64, "(X)");
	else if (g_iMineCheck[client][22] == 2 && g_iMineSelected[client][22] && g_iMine[client] != 23)
		Format(block3, 64, "X");
	else if (g_iMineSelected[client][22] && g_iMine[client] == 23)
		Format(block3, 64, "(✓)");
	else if (g_iMineSelected[client][22] && g_iMine[client] != 23)
		Format(block3, 64, "✓");
	else if (!g_iMineSelected[client][22] && g_iMine[client] != 23)
		Format(block3, 64, "☐");
	
	if (!g_iMineSelected[client][23] && g_iMine[client] == 24)
		Format(block4, 64, "(☐)");
	else if (g_iMineCheck[client][23] == 2 && g_iMineSelected[client][23] && g_iMine[client] == 24)
		Format(block4, 64, "(X)");
	else if (g_iMineCheck[client][23] == 2 && g_iMineSelected[client][23] && g_iMine[client] != 24)
		Format(block4, 64, "X");
	else if (g_iMineSelected[client][23] && g_iMine[client] == 24)
		Format(block4, 64, "(✓)");
	else if (g_iMineSelected[client][23] && g_iMine[client] != 24)
		Format(block4, 64, "✓");
	else if (!g_iMineSelected[client][23] && g_iMine[client] != 24)
		Format(block4, 64, "☐");
	
	if (!g_iMineSelected[client][24] && g_iMine[client] == 25)
		Format(block5, 64, "(☐)");
	else if (g_iMineCheck[client][24] == 2 && g_iMineSelected[client][24] && g_iMine[client] == 25)
		Format(block5, 64, "(X)");
	else if (g_iMineCheck[client][24] == 2 && g_iMineSelected[client][24] && g_iMine[client] != 25)
		Format(block5, 64, "X");
	else if (g_iMineSelected[client][24] && g_iMine[client] == 25)
		Format(block5, 64, "(✓)");
	else if (g_iMineSelected[client][24] && g_iMine[client] != 25)
		Format(block5, 64, "✓");
	else if (!g_iMineSelected[client][24] && g_iMine[client] != 25)
		Format(block5, 64, "☐");
	
	Format(row5[client], 64, "%s %s %s %s %s", block1, block2, block3, block4, block5);
}

void resetGame(int client)
{
	g_aMines[client].Clear();
}

public void leftGame(int client)
{
	if (g_hTimer[client] != INVALID_HANDLE)
		g_hTimer[client] = INVALID_HANDLE;
	
	g_bPlayerJoined[client] = false;
	g_bInstructions[client] = false;
	g_iMines[client] = 0;
	g_iBet[client] = 100;
} 