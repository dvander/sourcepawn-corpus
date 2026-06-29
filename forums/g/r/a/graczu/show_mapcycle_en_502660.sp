/*
 * Name: Mapcycle Show in menu
 * By: graczu, i use some code from MaTTe script
 *
 * Notes: My first SM plugin! (graczu: just like me)
*/

#include <sourcemod>

#define VERSION "1.0"

public Plugin:myinfo =
{
	name = "Mapcycle Show",
	author = "graczu, i used MaTTe terms script",
	description = "When player say: /mapcycle its showing him a menu with mapcycle!",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("mapcycleshow_version", VERSION, "MapCycle Shower Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public Action:Command_Say(client, args)
{
	decl String:text[192];
	new startidx = 0;
	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}	

	if (strcmp(text[startidx], "/mapcycle", false) == 0)
	{
		Menu_Build(client);
	}
		
	
	return Plugin_Continue;
}
 

public Menu_Build(client)
{
	new Handle:hFile = OpenFile("mapcycle.txt", "rt");

	if(hFile == INVALID_HANDLE)
	{
		return;
	}

	new String:szReadData[128];

	new Handle:hMenu = CreatePanel();

	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		DrawPanelText(hMenu, szReadData);
	}

	SetPanelTitle(hMenu, "MapCycle:");

	DrawPanelItem(hMenu, "Close Menu");

	SendPanelToClient(hMenu, client, Menu_Handler, 60);

	CloseHandle(hMenu);
}

public Menu_Handler(Handle:hMenu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			PrintToChat(param1, "\x04[SM] Mapcycle Menu Closed!");
		}
	}
}