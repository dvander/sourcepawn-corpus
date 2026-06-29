#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Rock Paper Sciccors",
	author = "Tylerst",
	description = "Play Rock Paper Sciccors when you die",
	version = "1.0.0",
	url = "None"
}

#define ROCK 0
#define PAPER 1
#define SCICCORS 2

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	HookEvent("player_spawn", Event_Spawn);
	LoadTranslations("common.phrases");
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Handle:menu = CreateMenu(HandleRPS);
	SetMenuTitle(menu, "Rock, Paper, or Sciccors?");
	AddMenuItem(menu, "rock", "Rock");
	AddMenuItem(menu, "paper", "Paper");
	AddMenuItem(menu, "sciccors", "Sciccors");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CancelClientMenu(client); 
}

public HandleRPS(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:strchoice[32], choice;
		GetMenuItem(menu, param2, strchoice, sizeof(strchoice));
		if(StrEqual(strchoice, "rock")) choice = ROCK;
		else if(StrEqual(strchoice, "paper")) choice = PAPER;
		else choice = SCICCORS;
		new bool:PlayerWon = PlayGame(param1, choice);
		if(PlayerWon) PrintToChat(param1, "[SM] You won Rock Paper Sciccors!");
		else PrintToChat(param1, "[SM] You didn't win Rock Paper Sciccors.");
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public bool:PlayGame(client, choice)
{
	new opponentchoice = GetRandomInt(0, 2);
	if(choice == ROCK && opponentchoice == SCICCORS) return true;
	else if(choice == PAPER && opponentchoice == ROCK) return true;
	else if(choice == SCICCORS && opponentchoice == PAPER) return true;
	else return false;
}


