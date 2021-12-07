#include <sourcemod>
#include <sdkhooks>
#include <sdktools>


public void OnPluginStart()
{
	RegConsoleCmd("sm_games", menu_game);
	RegConsoleCmd("sm_game", menu_game);
}

public Action menu_game(int client, int args)
{
	char info[55];
	Format(info, sizeof(info), "Select a game");
	Menu opengame = new Menu(multigame);
	opengame.SetTitle(info);
	
	opengame.AddItem("pong", "Pong");
	opengame.AddItem("snake", "Snake");
	opengame.AddItem("tetris", "Tetris");
	opengame.ExitButton = true;
	opengame.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

public int multigame(Menu opengame, MenuAction action, int client, int selection)
{
	char info[32];
	opengame.GetItem(selection, info, sizeof(info));
	if(strcmp(info, "pong")==0)
		FakeClientCommand(client, "sm_pong");
	else if(strcmp(info, "snake")==0)
		FakeClientCommand(client, "sm_snake");
	else if(strcmp(info, "tetris")==0)
		FakeClientCommand(client, "sm_tetris");
	else if (action == MenuAction_End)
	{
		delete opengame;
	}	
}