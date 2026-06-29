#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo ={
	name = "List SourceMod Commands",
	author = "denormal, shanapu",
	description = "Lists SourceMod commands accessible to the client in a menu.",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_listcmd", Command_listcmd, "Open this commands menu");
}

public Action Command_listcmd(int client,int args)
{
	char command[64];
	char description[128];
	Handle cvar;
	bool isCommand, flags;
	
	cvar = FindFirstConCommand(command, sizeof(command), isCommand, flags, description, sizeof(description));
	
	if(cvar == INVALID_HANDLE) {
		PrintToConsole(client, "Could not load cvar list");
		return Plugin_Handled;
	}
	Menu menu = CreateMenu(Handler_CMDmenu);
	menu.SetTitle("Commands");
	
	do {
		if(!isCommand) 
			continue;
		
		bool isSmCmd = command[0] == 's' && command[1] == 'm' && command[2] == '_';
		
		if (isSmCmd && CheckCommandAccess(client, command, 0, false)) 
		{
			char display[256];
			Format(display, sizeof(display), "%s\n%s", command ,description);
			menu.AddItem(command, display);
		}
	} while(FindNextConCommand(cvar, command, sizeof(command), isCommand, flags, description, sizeof(description)));
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Handler_CMDmenu(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char command[32];
		
		menu.GetItem(Position, command, sizeof(command));
		
		FakeClientCommand(client, command);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}