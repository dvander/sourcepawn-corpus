#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Command Menu Handler",
	author = "static2601",
	description = "Commands in menu",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_knife", KnifeMenu);
}

public Action:KnifeMenu(client, args)
{	
	new Handle:menu = CreateMenu(MenuHandler1);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	SetMenuTitle(menu, "Select A Knife");
	AddMenuItem(menu, "Bayonet", "Bayonet Knife");
	AddMenuItem(menu, "Gut", "Gut Knife");
	AddMenuItem(menu, "Flip", "Flip Knife");
	AddMenuItem(menu, "M9", "M9 Bayonet");
	AddMenuItem(menu, "Karambit", "Karambit");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;

}

public MenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (param1 == 1 && StrEqual(info, "Bayonet"))
		{
			ClientCommand(param1, "sm_bayonet");
			PrintToChat(param1, "Bayonet Knife Selected");
			
		}
		if (param1 == 1 && StrEqual(info, "Gut"))
		{
			ClientCommand(param1, "sm_gut");
			PrintToChat(param1, "Gut Knife Selected");
		}
		if (param1 == 1 && StrEqual(info, "Flip"))
		{
			ClientCommand(param1, "sm_m9");
			PrintToChat(param1, "Flip Knife Selected");
		}
		if (param1 == 1 && StrEqual(info, "M9"))
		{
			ClientCommand(param1, "sm_flip");
			PrintToChat(param1, "M9 Bayonet Selected");
		}
		if (param1 == 1 && StrEqual(info, "Karambit"))
		{
			ClientCommand(param1, "sm_karambit");
			PrintToChat(param1, "Karambit Selected");
		}
	}
	else if (action == MenuAction_Cancel)
	{
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}