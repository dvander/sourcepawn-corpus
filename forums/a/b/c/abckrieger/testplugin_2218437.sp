#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <KZTimer>

public Plugin:myinfo = 
{
        name = "TEST_PLUGIN",
        author = "1NutWunDeR",
        description = "private",
        version = "1.0",
        url = ""
}

public OnPluginStart()
{
 RegConsoleCmd("sm_testmenu", Client_Test);
}

public Action:Client_Test(client, args)
{
	new Handle:menu = CreateMenu(testhandler);
	SetMenuTitle(menu, "Main Menu");
	AddMenuItem(menu, "submenu1", "submenu1");
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	KZTimer_StopUpdatingOfClimbersMenu(client); // <--- KZTIMER
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
	return Plugin_Handled;
}

public testhandler(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		new Handle:menu2 = CreateMenu(testhandler2);
		SetMenuTitle(menu2, "Sub menu");
		AddMenuItem(menu2, "0", "bla");
		SetMenuOptionFlags(menu2, MENUFLAG_BUTTON_EXIT);
		KZTimer_StopUpdatingOfClimbersMenu(client); // <--- KZTIMER
		DisplayMenu(menu2, client, MENU_TIME_FOREVER);	
	}
}

public testhandler2(Handle:menu, MenuAction:action, client, select)
{
}