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
		if (StrEqual(info, "Bayonet"))
		{
			FakeClientCommand(param1, "say !bayonet");
			PrintToChat(param1, "Bayonet Knife Selected");
			
		}
		if (StrEqual(info, "Gut"))
		{
			FakeClientCommand(param1, "say !gut");
			PrintToChat(param1, "Gut Knife Selected");
		}
		if (StrEqual(info, "Flip"))
		{
			FakeClientCommand(param1, "say !m9");
			PrintToChat(param1, "Flip Knife Selected");
		}
		if (StrEqual(info, "M9"))
		{
			FakeClientCommand(param1, "say !flip");
			PrintToChat(param1, "M9 Bayonet Selected");
		}
		if (StrEqual(info, "Karambit"))
		{
			FakeClientCommand(param1, "say !karambit");
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