/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "Info Menu"
#define PLUGIN_DESCRIPTION "Shows the information menu with the /info command."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>

/*****************************/
//ConVars

/*****************************/
//Globals
Menu g_InfoMenu;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	g_InfoMenu = new Menu(MenuHandler_Info);
	g_InfoMenu.SetTitle("----------------------\nInfo Menu(/info)\n----------------------");
	g_InfoMenu.AddItem("sm_menu", "/menu - Main Menu");
	g_InfoMenu.AddItem("sm_setting", "/setting - Settings");
	g_InfoMenu.AddItem("sm_valve", "/valve - Valve Items");
	g_InfoMenu.AddItem("sm_rank", "/rank - Your Stats");
	g_InfoMenu.AddItem("sm_rules", "/rules - Read before you Play!");
	g_InfoMenu.AddItem("sm_vip", "/vip - VIP Menu");
	
	RegConsoleCmd("sm_info", Command_Info, "Shows the information menu.");
}

public Action Command_Info(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;
	
	g_InfoMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler_Info(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sCommand[32];
			menu.GetItem(param2, sCommand, sizeof(sCommand));
			FakeClientCommand(param1, sCommand);
		}
	}
}