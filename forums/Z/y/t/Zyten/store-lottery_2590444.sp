#pragma semicolon 1


#define PLUGIN_AUTHOR "Kasea"
#define PLUGIN_VERSION "1.0.0"
#define MAXJACKPOT 50
#define WHENTOSHOW 999
#define MINIMUMWIN 8
#define MAXIMUMWIN 10

#include <sourcemod>
#include <sdktools>
#include <kasea>
#include <colors_kasea>
#include <store>

public Plugin myinfo = 
{
	name = "Lottery",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "Kaseamg.com"
};

int valueBet[MAXPLAYERS + 1];

public void OnPluginStart()
{
	//CreateTimer(600.0, timer_lottery, _, TIMER_REPEAT);
	RegConsoleCmd("sm_gamble", cmd_gamble);
	RegConsoleCmd("sm_giveaway", cmd_giveaway);
}

public Action cmd_giveaway(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] You need to enter a giveaway value.");
		return Plugin_Handled;
	}
	if(howManyPlayersConnected(false) < 2)
	{
		ReplyToCommand(client, "[SM]There needs to be 3 or more people on to use this command.");
		return Plugin_Handled;
	}
	char cArgs[MAX_MESSAGE_LENGTH];
	GetCmdArgString(cArgs, sizeof(cArgs));
	int creditsOfClient = Store_GetClientCredits(client);
	int valueOfGiveaway = StringToInt(cArgs);
	if(valueOfGiveaway == 0)
	{
		ReplyToCommand(client, "[SM]You need to enter a number.");
		return Plugin_Handled;
	}
	if(valueOfGiveaway > creditsOfClient)
	{
		ReplyToCommand(client, "[SM]You can't giveaway more then you have.");
		return Plugin_Handled;
	}else if(valueOfGiveaway < 29)
	{
		ReplyToCommand(client, "[SM]Your giveaway needs to be more then 29 credits");
		return Plugin_Handled;
	}else if(valueOfGiveaway > 10000)
	{
		ReplyToCommand(client, "[SM]You can't giveaway more then 10000.");
		return Plugin_Handled;
	}else if(valueOfGiveaway < 10000 && valueOfGiveaway > 29)
	{
		CPrintToChatAll("{lightblue}%N{default} Is giving away %i credits too a random person.", client, valueOfGiveaway);
		Store_SetClientCredits(client, creditsOfClient-valueOfGiveaway);
		CreateTimer(3.5, timer_giveaway, valueOfGiveaway);
		return Plugin_Handled;
	}else
	{
		ReplyToCommand(client, "[SM]Unkown error.");
		return Plugin_Handled;
	}
}

public Action timer_giveaway(Handle timer, any credits)
{
	int randomnum = GetRandomInt(1, Connected());
	if(!CanClientWin(randomnum))
	{
		CreateTimer(0.1, timer_giveaway, credits);
		return Plugin_Continue;
	}
	CPrintToChatAll("And the lucky winner of %i credits is... {lightblue}%N", credits, randomnum);
	int creditsOfWinner = Store_GetClientCredits(randomnum);
	Store_SetClientCredits(randomnum, creditsOfWinner + credits);
	return Plugin_Handled;
}

//Gamble option below this
public Action cmd_gamble(int client, int args)
{
	if(args < 1)
	{
		CPrintToChat(client, "Enter a value to gamble.");
		return Plugin_Handled;
	}
	char cArgs[MAX_MESSAGE_LENGTH];
	GetCmdArgString(cArgs, sizeof(cArgs));
	int valueBetted = StringToInt(cArgs);
	int creditsOfClient = Store_GetClientCredits(client);
	if(valueBetted > creditsOfClient)
	{
		CPrintToChat(client, "You can't gamble more then you have.");
		return Plugin_Handled;
	}else if(valueBetted < 19)
	{
		CPrintToChat(client, "You have to gamble 20 or more credits");
		return Plugin_Handled;
	}else if(valueBetted > 9999)
	{
		CPrintToChat(client, "You can't gamble 10000 or more credits");
		return Plugin_Handled;
	}else if(valueBetted < 10000 && valueBetted > 19)
	{
		valueBet[client] = valueBetted;
		if(valueBetted > WHENTOSHOW)
			CPrintToChatAll("{lightblue}%N{default}, just gambled %i credits!", client, valueBetted);
		else
			CPrintToChat(client, "You just gambled %i credits, best of luck.", valueBetted);
		CreateTimer(5.0, timer_gamble, client);
		return Plugin_Handled;
	}else
	{
		CPrintToChat(client, "You should really enter a number...");
		return Plugin_Handled;
	}
}

public Action timer_gamble(Handle timer, any client)
{
	//int client = GetClientOfUserId(data);
	if (!IsClientConnected(client))
		return Plugin_Stop;
	int didHeWin;
	int valueBetted = valueBet[client];
	
	if(valueBetted<100)
	{
		didHeWin = GetRandomInt(1, 18);
	}else if(valueBetted < 251)
	{
		didHeWin = GetRandomInt(1, 16);
	}else if(valueBetted < 501)
	{
		didHeWin = GetRandomInt(1, 15);
	}else if(valueBetted < 751)
	{
		didHeWin = GetRandomInt(1, 14);
	}else if(valueBetted < 1001)
	{
		didHeWin = GetRandomInt(1, 13);
	}else if(valueBetted < 2501)
	{
		didHeWin = GetRandomInt(1, 12);
	}else if(valueBetted < 4001)
	{
		didHeWin = GetRandomInt(1, 11);
	}else if(valueBetted < 5001)
	{
		didHeWin = GetRandomInt(1, 10);
	}else if(valueBetted < 6501)
	{
		didHeWin = GetRandomInt(1, 9);
	}else if(valueBetted < 8001)
	{
		didHeWin = GetRandomInt(1, 8);
	}else if(valueBetted < 10000)
	{
		didHeWin = GetRandomInt(1, 8);
	}
	
	
	int creditsOfClient = Store_GetClientCredits(client);
	int multiplier = GetRandomInt(MINIMUMWIN, MAXIMUMWIN);
	int winnings = valueBetted*multiplier;
	float tempvipWinnings = winnings*1.10;
	char c_winnings[32];
	FloatToString(tempvipWinnings, c_winnings, sizeof(c_winnings));
	int vipWinnings = StringToInt(c_winnings);
	bool winner;
	if(valueBetted>creditsOfClient)
	{
		if(valueBetted > WHENTOSHOW)
			CPrintToChatAll("{lightblue}%N{default}, just tried and trick the system with those credits... shame", client);
		else
			CPrintToChat(client, "You can't fool the system.");
		return Plugin_Stop;
	}
	if(didHeWin == 1)
		winner = true;
	else
		winner = false;
	if(winner)
	{		
		if(valueBetted > WHENTOSHOW)
		{
			if(IsClientVip(client))
				CPrintToChatAll("And {lightblue}%N{default} Just won a whopping %d credits!", client, vipWinnings);
			else
				CPrintToChatAll("And {lightblue}%N{default} Just won a whopping %i credits!", client, winnings);			
		}
		else
		{
			if(IsClientVip(client))
				CPrintToChat(client, "You just won %i credits", vipWinnings);
			else
				CPrintToChat(client, "You just won %i credits", winnings);	
		}
		if(IsClientVip(client))
			Store_SetClientCredits(client, creditsOfClient+vipWinnings);
		else
			Store_SetClientCredits(client, creditsOfClient+winnings);
	}else
	{
		if(valueBetted > WHENTOSHOW)
		{
			CPrintToChatAll("And {lightblue}%N{default} just lost a whopping %i credits", client, valueBetted);
		}else
		{
			CPrintToChat(client, "You just lost %i credits", valueBetted);
		}
		Store_SetClientCredits(client, creditsOfClient-valueBetted);
	}
	
	return Plugin_Stop;
}

//Lottery below this
public Action timer_lottery(Handle timer)
{
	int winningSum = GetRandomInt(1, MAXJACKPOT);
	bool isJackpot = false;
	if(winningSum == MAXJACKPOT)
		isJackpot = true;
	if(howManyPlayersConnected() > 9)
	{
		int randomnum = GetRandomInt(1, Connected());
		if(!CanClientWin(randomnum))
		{
			CreateTimer(0.1, timer_lottery);
			return Plugin_Continue;
		}
		
		if(IsClientVip(randomnum))
		{
			winningSum = winningSum*2;
			if(isJackpot)
				CPrintToChatAll("{lightblue}JACKPOT!!!! {default}The lucky winner is {lightblue}%N{default}. {lightblue}%N{default} gets %i credits in the store!", randomnum, randomnum, winningSum);
			else
				CPrintToChatAll("The lucky winner is {lightblue}%N{default}. {lightblue}%N{default} gets %i credits in the store!", randomnum, randomnum, winningSum);
		}else
		{
			if(isJackpot)
				CPrintToChatAll("{lightblue}JACKPOT!!!! {default}The lucky winner is {lightblue}%N{default}. {lightblue}%N{default} gets %i credits in the store!", randomnum, randomnum, winningSum);
			else
				CPrintToChatAll("The lucky winner is {lightblue}%N{default}. {lightblue}%N{default} gets %i credits in the store!", randomnum, randomnum, winningSum);
		}
		
		Store_SetClientCredits(randomnum, winningSum+Store_GetClientCredits(randomnum));
	}else
	{
		CPrintToChatAll("No lottery will be held. Not enough people connected.");
	}
	return Plugin_Continue;
}

bool CanClientWin(int client)
{
	if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && GetClientTeam(client) > 1)
		return true;
	else
		return false;	
}


//Menu shit

public Action timer_createMenu(Handle timer)
{
	
}

