#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Admin menu set next map",
	author = "Jamster",
	description = "Sets an option in the admin menu to set the next map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_MapList;
new Handle:g_MapMenu;
new Handle:hTopMenu;

public OnPluginStart()
{
	LoadTranslations("mapchooser.phrases");
	g_MapList = CreateArray(ByteCountToCells(64));
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}

public OnConfigsExecuted()
{
	new serial = -1;
	ReadMapList(g_MapList, serial, "default", MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER);
	BuildMenu();
}

BuildMenu()
{
	if (g_MapMenu != INVALID_HANDLE)
	{
		CloseHandle(g_MapMenu);
		g_MapMenu = INVALID_HANDLE;
	}
	
	g_MapMenu = CreateMenu(MenuHandler_SetMap);
	decl String:map[64];	
		
	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{		
		GetArrayString(g_MapList, i, map, sizeof(map));		
		AddMenuItem(g_MapMenu, map, map);
	}
	
	SetMenuExitBackButton(g_MapMenu, true);
	SetMenuExitButton(g_MapMenu, true);
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	hTopMenu = topmenu;
	
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_setnextmap",
			TopMenuObject_Item,
			AdminMenu_SetMap,
			server_commands,
			"sm_setnextmap",
			ADMFLAG_CHANGEMAP);
	}
}

public AdminMenu_SetMap(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Set next map", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		SetMenuTitle(g_MapMenu, "Please select a map", param);
		DisplayMenu(g_MapMenu, param, MENU_TIME_FOREVER);
	}
}

public MenuHandler_SetMap(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case (MenuAction_Select):
		{
			decl String:map[64]
			GetMenuItem(menu, param2, map, sizeof(map));		
			ShowActivity(param1, "%t", "Changed Next Map", map);
			LogMessage("\"%L\" changed nextmap to \"%s\"", param1, map);
			SetNextMap(map);
		}
		case (MenuAction_Cancel):
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
		}
	}
}