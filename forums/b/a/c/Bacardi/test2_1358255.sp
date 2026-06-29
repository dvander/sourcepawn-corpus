#include <sourcemod>
#include <adminmenu>

new Handle:hTopMenu = INVALID_HANDLE;
new bool:enabled = false;

public OnPluginStart()
{
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}


public OnLibraryRemoved(const String:name[])
{
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = INVALID_HANDLE;
	}
}



public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"alltalk",
			TopMenuObject_Item,
			AdminMenu_AllTalk,
			server_commands,
			"alltalk",
			ADMFLAG_CONVARS);
	}
}

public AdminMenu_AllTalk(Handle:topmenu, 
							  TopMenuAction:action,
							  TopMenuObject:object_id,
							  param,
							  String:buffer[],
							  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Server All Talk", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new Handle:alltalk = FindConVar("sv_alltalk");
		if(GetConVarInt(alltalk)== 1)
		{
			enabled = true;
		}
		else
		{
			enabled = false;
		}
		
		DisplayAllTalkMenu(param);
	}
}

DisplayAllTalkMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AllTalk);

	decl String:title[100];
	Format(title, sizeof(title), "Server All Talk", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	if(enabled == true)
	{
		AddMenuItem(menu, "alltalk_on", "Alltalk OFF");
		enabled = false;
	}
	else if(enabled == false)
	{
		AddMenuItem(menu, "alltalk_off", "Alltalk ON");
		enabled = true;
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AllTalk(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];

		GetMenuItem(menu, param2, info, sizeof(info));

		if(StrEqual(info,"alltalk_on",true))
		{
			ServerCommand("sv_alltalk 0");
			PrintToChat(param1, "[SM] All Talk Disabled");
		}
		else if(StrEqual(info,"alltalk_off",true))
		{
			ServerCommand("sv_alltalk 1");
			PrintToChat(param1, "[SM] All Talk Enabled");
		}
		DisplayAllTalkMenu(param1);
	}
}