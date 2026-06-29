#include <sourcemod>
#pragma semicolon 1

new number[MAXPLAYERS+1];
new bool:lotto = false;

public Plugin:myinfo = 
{
	name = "Lottery",
	author = "noodleboy347",
	description = "picks a random winner to win... something...",
	version = "1.0",
	url = "http://www.goldenmachinegun.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_lotto", Command_Lotto, ADMFLAG_ROOT);
}

public Action:Command_Lotto(client, args)
{
	// make sure no lottery going, if not, 
	if(lotto)
	{
		ReplyToCommand(client, "Please wait until the current lottery is over.");
		return Plugin_Handled;
	}
	lotto = true;
	
	// give random numbers
	for(new i=1; i<=GetMaxClients(); i++)
	{
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		number[i] = GetRandomInt(100, 999999);
		PrintToChat(i, "\x01Your number is \x04%i", number[i]);
	}
	
	//timer to win
	CreateTimer(30.0, Timer_Announce);
	
	return Plugin_Handled;
}


public Action:Timer_Announce(Handle:timer)
{
	// get random winner
	new winner = 0;
	while(!IsValidEntity(winner) || !IsFakeClient(winner) || winner == 0)
		winner = GetRandomInt(1, GetMaxClients());
	
	// announce and log
	PrintCenterText(winner, "Congratulations, you won!");
	PrintToChatAll("\x01%N has won with their number, \x04%i\x01!", winner, number[winner]);
	LogToFile("logs/lotto.txt", "%L has won with %i", winner, number[winner]);

	// turn off lotto mode
	lotto = false;
}