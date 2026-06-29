#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define LOOP_MAPSCATEGORY(%1,%2) for(int %1; %1 < %2; %1++)

TopMenu g_hTopMenu;
ArrayList g_arrMaps;
ArrayList g_arrGameModes[2];
int g_iLastPosition[MAXPLAYERS];

public Plugin myinfo =
{
	name = "Maps Category",
	author = "Yaser2007",
	description = "Categorizes maps based on their gamemode.",
	version = "1.2.9"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_maps", Cmd_MapsCategory, ADMFLAG_CHANGEMAP);

	TopMenu topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}

	g_arrMaps = CreateArray(64);
	LOOP_MAPSCATEGORY(i, 2)
	{
		g_arrGameModes[i] = CreateArray(32);
	}
}

public void OnPluginEnd()
{
	LOOP_MAPSCATEGORY(i, 2)
	{
		if(GetArraySize(g_arrGameModes[i]) > 0)
		{
			delete g_arrGameModes[i];
		}
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = null;
	}
}

public void OnAdminMenuReady(Handle topmenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(topmenu);
	if(hTopMenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu = view_as<TopMenu>(topmenu);

	TopMenuObject server_commands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	if(server_commands != INVALID_TOPMENUOBJECT)
	{
		g_hTopMenu.AddItem("Maps Category", AdminMenu_MapsCategory, server_commands, "sm_maps", ADMFLAG_CHANGEMAP);
	}
}

public void AdminMenu_MapsCategory(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int client, char[] buffer, int maxlength)
{
	switch(action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "Maps Category");
		}
		case TopMenuAction_SelectOption:
		{
			Cmd_MapsCategory(client, 0);
		}
	}
}

public void OnMapStart()
{
	LOOP_MAPSCATEGORY(i, 2)
	{
		if(GetArraySize(g_arrGameModes[i]) > 0)
		{
			ClearArray(g_arrGameModes[i]);
		}
	}

	int serial = -1;
	ReadMapList(g_arrMaps, serial, "default", MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/maps_category.cfg");

	if(!FileExists(path))
	{
		SetFailState("Config file '%s' doesn't exist!", path);
	}

	SMCParser parser = SMC_CreateParser();
	SMC_SetReaders(parser, null, SMCKeyValues, null);
	SMC_ParseFile(parser, path);
}

public SMCResult SMCKeyValues(SMCParser parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	PushArrayString(g_arrGameModes[0], key);
	PushArrayString(g_arrGameModes[1], value);
	return SMCParse_Continue;
}

public Action Cmd_MapsCategory(int client, int args)
{
	DisplayMenu(MainMenu(), client, 30);
	return Plugin_Handled;
}

public Menu MainMenu()
{
	Menu menu = CreateMenu(Menu_Category);
	SetMenuTitle(menu, "Maps Category");

	int size = GetArraySize(g_arrGameModes[0]);
	if(size > 0)
	{		
		char buffer[2][32];
		LOOP_MAPSCATEGORY(i, size)
		{
			LOOP_MAPSCATEGORY(j, 2)
			{
				GetArrayString(g_arrGameModes[j], i, buffer[j], sizeof(buffer[]));
			}
			AddMenuItem(menu, buffer[0], buffer[1]);
		}
	}
	else
	{
		AddMenuItem(menu, NULL_STRING, "Config file is empty or no correctly configured", ITEMDRAW_DISABLED);
	}

	SetMenuExitBackButton(menu, true);

	return menu;
}

public void Menu_Category(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			char display[32];
			GetMenuItem(menu, item, info, sizeof(info), _, display, sizeof(display));

			Menu menu2 = CreateMenu(Menu_Maps);

			char split[3][32];
			char buffer[64];
			int count;
			int sep = ExplodeString(info, ", ", split, sizeof(split), sizeof(split[]));
			int size = GetArraySize(g_arrMaps);
			LOOP_MAPSCATEGORY(i, size)
			{
				GetArrayString(g_arrMaps, i, buffer, sizeof(buffer));
				LOOP_MAPSCATEGORY(j, sep)
				{
					if(StrStartsWith(buffer, split[j]))
					{
						AddMenuItem(menu2, buffer, buffer);
						count++;
					}
				}
			}

			if(count < 1)
			{
				AddMenuItem(menu2, NULL_STRING, "There are no maps available for this gamemode.", ITEMDRAW_DISABLED);
			}

			SetMenuTitle(menu2, "%s (%d Maps)", display, count);
			SetMenuExitBackButton(menu2, true);
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
			g_iLastPosition[client] = GetMenuSelectionPosition();
		}
		case MenuAction_Cancel:
		{
			if(item == MenuCancel_ExitBack && g_hTopMenu)
			{
				DisplayTopMenu(g_hTopMenu, client, TopMenuPosition_LastCategory);
			}
		}
	}
}

public void Menu_Maps(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[64];
			GetMenuItem(menu, item, info, sizeof(info));
			FakeClientCommand(client, "sm_map %s", info);
		}
		case MenuAction_Cancel:
		{
			if(item == MenuCancel_ExitBack)
			{
				DisplayMenuAtItem(MainMenu(), client, g_iLastPosition[client], MENU_TIME_FOREVER);
			}
		}
	}
}

stock bool StrStartsWith(const char[] str, const char[] subString)
{
	int n;
	while(subString[n] != '\0')
	{
		if(str[n] == '\0' || str[n] != subString[n])
		{
			return false;
		}
		n++;
	}

	return true;
}