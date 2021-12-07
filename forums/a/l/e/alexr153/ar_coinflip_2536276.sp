#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <colors_csgo>
#undef REQUIRE_PLUGIN
#include <store>


#pragma newdecls required

int randomFlipper[MAXPLAYERS + 1][MAXPLAYERS + 1];
int clientTarget[MAXPLAYERS + 1];
int coinflipPot[MAXPLAYERS + 1];
int headsTails[MAXPLAYERS + 1];
int flippingTime[MAXPLAYERS + 1];
int flipperAnimation[MAXPLAYERS + 1][MAXPLAYERS + 1];
int flipperFix[MAXPLAYERS + 1];
int headsTailsFlipper[MAXPLAYERS + 1][MAXPLAYERS + 1];
int flipDone[MAXPLAYERS + 1][MAXPLAYERS + 1];
int creditsToGamble[MAXPLAYERS + 1];
bool playerIsReady[MAXPLAYERS + 1];
bool playerInGame[MAXPLAYERS + 1];
bool gaveCredits[MAXPLAYERS + 1];
char CHAT_PREFIX[50];
int menuItem[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Coinflip", 
	author = PLUGIN_AUTHOR, 
	description = "Coin flip gambles credits from zephrus store", 
	version = PLUGIN_VERSION, 
	url = "www.crypto-gaming.tk"
};

public void OnPluginStart()
{
	Format(CHAT_PREFIX, 50, "[{red}Coin-flip{default}]");
	RegConsoleCmd("sm_coinflip", CMD_coinflip, "Coin flip command!");
	RegConsoleCmd("sm_coin", CMD_coinflip, "Coin flip command!");
}

public void OnClientDisconnect(int client)
{
	clientTarget[client] = 0;
	headsTails[client] = 0;
	creditsToGamble[client] = 0;
	coinflipPot[client] = 0;
	flippingTime[client] = 0;
	menuItem[client] = 0;
	playerIsReady[client] = false;
	playerInGame[client] = false;
	gaveCredits[client] = false;
}

public Action CMD_coinflip(int client, int args)
{
	if (playerInGame[client])
	{
		CPrintToChat(client, "%s You are already in a game or waiting for the game to start", CHAT_PREFIX);
		return Plugin_Handled;
	}
	Handle menu = CreateMenu(cmd_coinflip_callback);
	SetMenuTitle(menu, "Choose a player!");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i) && i != client && !playerInGame[i])
		{
			char name[60];
			GetClientName(i, name, 60);
			AddMenuItem(menu, name, name);
		}
	}
	DisplayMenu(menu, client, 0);
	return Plugin_Handled;
}

public int cmd_coinflip_callback(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char item[60];
		GetMenuItem(menu, param2, item, 60);
		int target = FindTarget(client, item, true, false);
		char name[60];
		GetClientName(target, name, 60);
		CPrintToChat(client, "%s You have challenged %s to a coinflip.", CHAT_PREFIX, name);
		playerInGame[client] = true;
		playerInGame[target] = true;
		clientTarget[client] = target;
		clientTarget[target] = client;
		buildAcceptmenu(client, target);
	}
}

public void buildAcceptmenu(int client, int target)
{
	char name[60];
	GetClientName(client, name, 60);
	Handle menu1 = CreateMenu(menu1_callback);
	SetMenuTitle(menu1, "Coinflip challenge %s", name);
	AddMenuItem(menu1, "accept", "Accept");
	AddMenuItem(menu1, "decline", "Decline");
	SetMenuExitButton(menu1, false);
	DisplayMenu(menu1, target, 20);
	return;
}

public int menu1_callback(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		int target = clientTarget[client];
		char item[60];
		GetMenuItem(menu, param2, item, 60);
		if (StrEqual(item, "accept"))
		{
			//buildCreditsMenu(client);
			//buildCreditsMenu(target);
			CreateTimer(0.1, buildCreditMenu, client, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, buildCreditMenu, target, TIMER_REPEAT || TIMER_FLAG_NO_MAPCHANGE);
			char name[60], nameTarget[60];
			GetClientName(client, name, 60);
			GetClientName(target, nameTarget, 60);
			CPrintToChatAll("%s A coinflip challenge has started between %s and %s", CHAT_PREFIX, nameTarget, name);
		} else if (StrEqual(item, "decline")) {
			char name[60];
			GetClientName(client, name, 60);
			CPrintToChat(target, "%s Player %s has declined your coinflip challenge", CHAT_PREFIX, name);
			setPlayerReset(client);
			setPlayerReset(target);
		}
	} else if (action == MenuAction_Cancel)
	{
		int target = clientTarget[client];
		char name[60];
		GetClientName(client, name, 60);
		CPrintToChat(target, "%s Player %s did not accept or decline in time.", CHAT_PREFIX, name);
		setPlayerReset(client);
		setPlayerReset(target);
	}
}

public void buildCreditsMenu(int client)
{
	int target = clientTarget[client];
	char name[60];
	GetClientName(target, name, 60);
	int clientCredits = Store_GetClientCredits(client);
	
	Panel menu = new Panel();
	char title[128];
	if(!playerIsReady[client] && !playerIsReady[target])
	Format(title, 128, "%i credits [ ]  |  %s %i credits [ ]", creditsToGamble[client], name, creditsToGamble[target]);
	else if(!playerIsReady[client] && playerIsReady[target])
	Format(title, 128, "%i credits [ ]  |  %s %i credits [X]", creditsToGamble[client], name, creditsToGamble[target]);
	else if(playerIsReady[client] && !playerIsReady[target])
	Format(title, 128, "%i credits [X]  |  %s %i credits []", creditsToGamble[client], name, creditsToGamble[target]);
	menu.SetTitle(title);
	if (!playerIsReady[client])
	{
		if (clientCredits > creditsToGamble[client])
			menu.DrawItem("+ 1 credits");
		else
			menu.DrawItem("+ 1 credits", ITEMDRAW_DISABLED);
		if (creditsToGamble[client] > 0 && clientCredits >= 1)
			menu.DrawItem("- 1 credits");
		else
			menu.DrawItem("- 1 credits", ITEMDRAW_DISABLED);
		
		if (clientCredits > creditsToGamble[client] && clientCredits > 100)
			menu.DrawItem("+ 100 credits");
		else
			menu.DrawItem("+ 100 credits", ITEMDRAW_DISABLED);
		
		if (creditsToGamble[client] >= 100)
			menu.DrawItem("- 100 credits");
		else
			menu.DrawItem("- 100 credits", ITEMDRAW_DISABLED);
		
		if (clientCredits > creditsToGamble[client] && clientCredits > 1000)
			menu.DrawItem("+ 1000 credits");
		else
			menu.DrawItem("+ 1000 credits", ITEMDRAW_DISABLED);
		
		if (creditsToGamble[client] >= 1000 && !playerIsReady[client])
			menu.DrawItem("- 1000 credits");
		else
			menu.DrawItem("- 1000 credits", ITEMDRAW_DISABLED);
	}
	
	if (creditsToGamble[client] <= 0 || creditsToGamble[client] > clientCredits)
		menu.DrawItem("Ready[ ]", ITEMDRAW_DISABLED);
	else if (!playerIsReady[client])
		menu.DrawItem("Ready[ ]");
	else
		menu.DrawItem("Ready[X]");
	
	menu.DrawItem("Leave");
	menu.CanDrawFlags(2);
	menu.Send(client, creditsMenu_Callback, 1);
	return;
}

public Action buildCreditMenu(Handle timer, int client)
{
	int target = clientTarget[client];
	if (playerIsReady[client] && playerIsReady[target] || !playerInGame[client])
		return Plugin_Stop;
		
	buildCreditsMenu(client);
		
	return Plugin_Continue;
}

public int creditsMenu_Callback(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		int target = clientTarget[client];
		if (param2 == 1)
		{
			if(playerIsReady[client])
			{
				playerIsReady[client] = false;
				return;
			}
			creditsToGamble[client] += 1;
		}
		else if (param2 == 2)
		{
			if(playerIsReady[client])
			{
				char name[60];
				GetClientName(client, name, 60);
				CPrintToChat(target, "%s Player %s has left the coinflip challenge", CHAT_PREFIX, name);
				CPrintToChat(client, "%s You have left the coinflip challenge", CHAT_PREFIX);
				OnClientDisconnect(client);
				OnClientDisconnect(target);
				return;
			}
			creditsToGamble[client] -= 1;
		}
		else if (param2 == 3)
			creditsToGamble[client] += 100;
		else if (param2 == 4)
			creditsToGamble[client] -= 100;
		else if(param2 == 5)
			creditsToGamble[client] += 1000;
		else if(param2 == 6)
			creditsToGamble[client] -= 1000;
		else if (param2 == 7)
		{
			if (!playerIsReady[client])
			{
				playerIsReady[client] = true;
			}
			else
				playerIsReady[client] = false;
			
			if (playerIsReady[client] && playerIsReady[target])
			{
				int clientCredits = Store_GetClientCredits(client);
				if (clientCredits < creditsToGamble[client])
				{
					CPrintToChat(client, "%s You don't have enough credits to bet that amount", CHAT_PREFIX);
					playerIsReady[client] = false;
					buildCreditsMenu(client);
					return;
				}
				
				int total = creditsToGamble[client] - creditsToGamble[target];
				int check = total;
				if (check < -5)
				{
					CPrintToChat(client, "%s Please put credits within 5 as opponents credits. Add %i to equal with opponet.", CHAT_PREFIX, check);
					playerIsReady[client] = false;
					buildCreditsMenu(client);
					return;
				} else if (check > 5)
				{
					CPrintToChat(client, "%s Please put credits within 5 as opponents credits. Subtract %i to equal with opponet.", CHAT_PREFIX, check);
					playerIsReady[client] = false;
					buildCreditsMenu(client);
					return;
				}
				doTheRest(client, target);
				return;
			}
		}
		else if (param2 == 8)
		{
			char name[60];
			GetClientName(client, name, 60);
			CPrintToChat(target, "%s Player %s has left the coinflip challenge", CHAT_PREFIX, name);
			CPrintToChat(client, "%s You have left the coinflip challenge", CHAT_PREFIX);
			OnClientDisconnect(client);
			OnClientDisconnect(target);
			return;
		}
	}
}

public void doTheRest(int client, int target)
{
	coinflipPot[client] = creditsToGamble[client] + creditsToGamble[target];
	coinflipPot[target] = creditsToGamble[target] + creditsToGamble[client];
	
	//flipping animations
	flippingTime[client] = 1;
	flippingTime[target] = 1;
	
	//Builds the heads or tails menu
	buildHeadsOrTails(client, target);
}

public void buildHeadsOrTails(int client, int target)
{
	int whichPlayer = GetRandomInt(1, 4);
	
	Handle menu = CreateMenu(headsTails_callback);
	SetMenuTitle(menu, "Heads or Tails?");
	AddMenuItem(menu, "heads", "Heads");
	AddMenuItem(menu, "tails", "Tails");
	if (whichPlayer == 1 || whichPlayer == 3)
	{
		CPrintToChat(client, "%s Choose heads or tails", CHAT_PREFIX);
		CPrintToChat(target, "%s Your opponent is choosing heads or tails", CHAT_PREFIX);
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, client, 0);
	} else if (whichPlayer == 2 || whichPlayer == 4)
	{
		CPrintToChat(target, "%s You are choosing heads or tails", CHAT_PREFIX);
		CPrintToChat(client, "%s Your opponent is choosing heads or tails", CHAT_PREFIX);
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, target, 0);
	}
}

public int headsTails_callback(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		int target = clientTarget[client];
		char item[60];
		GetMenuItem(menu, param2, item, 60);
		if (StrEqual(item, "heads"))
		{
			CPrintToChat(client, "%s You chose heads", CHAT_PREFIX);
			CPrintToChat(target, "%s You are tails", CHAT_PREFIX);
			headsTails[client] = 1;
			headsTails[target] = 2;
		} else if (StrEqual(item, "tails"))
		{
			CPrintToChat(target, "%s You are heads", CHAT_PREFIX);
			CPrintToChat(client, "%s You chose tails", CHAT_PREFIX);
			headsTails[client] = 2;
			headsTails[target] = 1;
		}
		//Random heads or tails when start
		flipperAnimation[client][target] = GetRandomInt(1, 4);
		flipperAnimation[target][client] = flipperAnimation[client][target];
		flipperFix[client] = flipperAnimation[client][target];
		flipperFix[target] = flipperAnimation[target][client];
		randomFlipper[client][target] = GetRandomInt(10, 15);
		randomFlipper[target][client] = randomFlipper[client][target];
		flipDone[client][target] = 0;
		flipDone[target][client] = 0;
		CreateTimer(0.5, buildFlipMenu, client, TIMER_REPEAT);
	}
}

public Action buildFlipMenu(Handle timer, int client)
{
	int target = clientTarget[client];
	if (flipDone[client][target] == randomFlipper[client][target])
	{
		setPlayerReset(client);
		setPlayerReset(target);
		return Plugin_Stop;
	}
	if (flipDone[client][target] != randomFlipper[client][target])
		flipDone[client][target] += 1;
	if (flipDone[client][target] == randomFlipper[client][target])
	{
		int flipForCoin[MAXPLAYERS + 1][MAXPLAYERS + 1];
		flipForCoin[client][target] = GetRandomInt(0, 100);
		flipForCoin[target][client] = flipForCoin[client][target];
		if (flipForCoin[client][target] >= 51)
		{
			headsTailsFlipper[client][target] = 1;
			headsTailsFlipper[target][client] = 1;
		}
		else if (flipForCoin[client][target] <= 50)
		{
			headsTailsFlipper[client][target] = 2;
			headsTailsFlipper[target][client] = 2;
		}
		if (flippingTime[client] != 3)
			flippingTime[client] += 1;
	}
	buildTheMenu(client);
	return Plugin_Continue;
}

public void buildTheMenu(int client)
{
	int target = clientTarget[client];
	
	Handle menu = CreateMenu(flipMenu_callback);
	if (flippingTime[client] == 1 && flipDone[client][target] != randomFlipper[client][target])
	{
		AddMenuItem(menu, "nun", "  FLIPPING.", ITEMDRAW_DISABLED);
		flippingTime[client] = 2;
	}
	else if (flippingTime[client] == 2 && flipDone[client][target] != randomFlipper[client][target])
	{
		AddMenuItem(menu, "nun", "  FLIPPING..", ITEMDRAW_DISABLED);
		flippingTime[client] = 3;
	}
	else if (flippingTime[client] == 3 && flipDone[client][target] != randomFlipper[client][target])
	{
		AddMenuItem(menu, "nun", "  FLIPPING...", ITEMDRAW_DISABLED);
		flippingTime[client] = 1;
	}
	
	if (flipDone[client][target] != randomFlipper[client][target])
		AddMenuItem(menu, "nun1", "", ITEMDRAW_SPACER);
	
	if (flipDone[client][target] != randomFlipper[client][target])
	{
		if (flipperFix[client] == 1 || flipperFix[client] == 3)
		{
			AddMenuItem(menu, "nu1", "  -Heads-", ITEMDRAW_DISABLED);
			flipperFix[client] = 2;
		}
		else if (flipperFix[client] == 2 || flipperFix[client] == 4)
		{
			AddMenuItem(menu, "nu1", "  -Tails-", ITEMDRAW_DISABLED);
			flipperFix[client] = 1;
		}
	}
	else if (flipDone[client][target] == randomFlipper[client][target])
	{
		if (headsTailsFlipper[client][target] == 1 || headsTailsFlipper[client][target] == 3)
		{
			AddMenuItem(menu, "nu1", "  FLIPPED!", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "nun1", "", ITEMDRAW_SPACER);
			AddMenuItem(menu, "nu1", "  Heads(WINS)", ITEMDRAW_DISABLED);
			if (headsTails[client] == 1)
				SetMenuTitle(menu, "POT %i You're Heads", coinflipPot[client]);
			else if (headsTails[client] == 2)
				SetMenuTitle(menu, "POT %i You're Tails", coinflipPot[client]);
			DisplayMenu(menu, client, 5);
			if (headsTails[target] == 1)
				SetMenuTitle(menu, "POT %i You're Heads", coinflipPot[target]);
			else if (headsTails[target] == 2)
				SetMenuTitle(menu, "POT %i You're Tails", coinflipPot[target]);
			DisplayMenu(menu, target, 5);
			checkForWinner(client, target, headsTailsFlipper[client][target]);
		} else if (headsTailsFlipper[client][target] == 2 || headsTailsFlipper[client][target] == 4)
		{
			AddMenuItem(menu, "nu1", "  FLIPPED!", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "nun1", "", ITEMDRAW_SPACER);
			AddMenuItem(menu, "nu1", "  Tails(WINS)", ITEMDRAW_DISABLED);
			if (headsTails[client] == 1)
				SetMenuTitle(menu, "POT %i You're Heads", coinflipPot[client]);
			else if (headsTails[client] == 2)
				SetMenuTitle(menu, "POT %i You're Tails", coinflipPot[client]);
			DisplayMenu(menu, client, 5);
			if (headsTails[target] == 1)
				SetMenuTitle(menu, "POT %i You're Heads", coinflipPot[target]);
			else if (headsTails[target] == 2)
				SetMenuTitle(menu, "POT %i You're Tails", coinflipPot[target]);
			DisplayMenu(menu, target, 5);
			checkForWinner(client, target, headsTailsFlipper[client][target]);
		}
		return;
	}
	if (headsTails[client] == 1)
		SetMenuTitle(menu, "POT %i You're Heads", coinflipPot[client]);
	else if (headsTails[client] == 2)
		SetMenuTitle(menu, "POT %i You're Tails", coinflipPot[client]);
	DisplayMenu(menu, client, 0);
	if (headsTails[target] == 1)
		SetMenuTitle(menu, "POT %i You're Heads", coinflipPot[target]);
	else if (headsTails[target] == 2)
		SetMenuTitle(menu, "POT %i You're Tails", coinflipPot[target]);
	DisplayMenu(menu, target, 0);
	return;
}

public void checkForWinner(int client, int target, int whichFace)
{
	if (whichFace == 1 || whichFace == 3)
	{
		if (headsTails[client] == 1)
		{
			char name[60];
			GetClientName(client, name, 60);
			CPrintToChatAll("%s Player %s has won the coinflip challenge. Winnings: %i", CHAT_PREFIX, name, coinflipPot[client]);
			
			int clientCredits = Store_GetClientCredits(client);
			int targetCredits = Store_GetClientCredits(target);
			Store_SetClientCredits(client, clientCredits -= creditsToGamble[client]);
			Store_SetClientCredits(target, targetCredits -= creditsToGamble[target]);
			Store_SetClientCredits(client, clientCredits += coinflipPot[client]);
		} else if (headsTails[target] == 1)
		{
			char name[60];
			GetClientName(target, name, 60);
			CPrintToChatAll("%s Player %s has won the coinflip challenge. Winnings: %i", CHAT_PREFIX, name, coinflipPot[client]);
			
			int clientCredits = Store_GetClientCredits(client);
			int targetCredits = Store_GetClientCredits(target);
			Store_SetClientCredits(client, clientCredits -= creditsToGamble[client]);
			Store_SetClientCredits(target, targetCredits -= creditsToGamble[target]);
			Store_SetClientCredits(target, targetCredits += coinflipPot[target]);
		}
	} else if (whichFace == 2 || whichFace == 4)
	{
		if (headsTails[client] == 2)
		{
			char name[60];
			GetClientName(client, name, 60);
			CPrintToChatAll("%s Player %s has won the coinflip challenge. Winnings: %i", CHAT_PREFIX, name, coinflipPot[client]);
			
			int clientCredits = Store_GetClientCredits(client);
			int targetCredits = Store_GetClientCredits(target);
			Store_SetClientCredits(client, clientCredits -= creditsToGamble[client]);
			Store_SetClientCredits(target, targetCredits -= creditsToGamble[target]);
			Store_SetClientCredits(client, clientCredits += coinflipPot[client]);
		} else if (headsTails[target] == 2)
		{
			char name[60];
			GetClientName(target, name, 60);
			CPrintToChatAll("%s Player %s has won the coinflip challenge. Winnings: %i", CHAT_PREFIX, name, coinflipPot[client]);
			
			int clientCredits = Store_GetClientCredits(client);
			int targetCredits = Store_GetClientCredits(target);
			Store_SetClientCredits(client, clientCredits -= creditsToGamble[client]);
			Store_SetClientCredits(target, targetCredits -= creditsToGamble[target]);
			Store_SetClientCredits(target, targetCredits += coinflipPot[target]);
		}
	}
}


public void setPlayerReset(int client)
{
	headsTails[client] = 0;
	creditsToGamble[client] = 0;
	playerIsReady[client] = false;
	playerInGame[client] = false;
	coinflipPot[client] = 0;
	flippingTime[client] = 0;
	clientTarget[client] = 0;
	menuItem[client] = 0;
}

public int flipMenu_callback(Handle menu, MenuAction action, int client, int param2)
{
	
}
