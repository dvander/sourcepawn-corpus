/*
 * In-game Help Menu
 * Written by chundo (chundo@mefightclub.com)
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "0.3 Playa edit"

enum ChatCommand
{
	String:command[32],
	String:description[255]
}

enum HelpMenuType
{
	HelpMenuType_List,
	HelpMenuType_Text
}

enum HelpMenu
{
	String:name[32],
	String:title[128],
	HelpMenuType:type,
	Handle:items,
	itemct
}

// CVars
ConVar g_cvarWelcome;
ConVar g_cvarAdmins;
ConVar g_cvarRotation;

// Help menus
Handle g_helpMenus = INVALID_HANDLE;

// Map cache
Handle g_mapArray = INVALID_HANDLE;
int g_mapSerial = -1;

// Config parsing
int g_configLevel = -1;

public Plugin myinfo =
{
	name = "In-game Help Menu",
	author = "chundo",
	description = "Display a help menu to users",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("sm_helpmenu_version", PLUGIN_VERSION, "Help menu version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarWelcome = CreateConVar("sm_helpmenu_welcome", "1", "Show welcome message to newly connected users.", FCVAR_NONE);
	g_cvarAdmins = CreateConVar("sm_helpmenu_admins", "0", "Show a list of online admins in the menu.", FCVAR_NONE);
	g_cvarRotation = CreateConVar("sm_helpmenu_rotation", "0", "Shows the map rotation in the menu.", FCVAR_NONE);
	RegConsoleCmd("sm_help", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_helpmenu", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_helpcommands", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_helpcomands", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_helpcommand", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_helpcomand", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_commands", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_comands", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_cmds", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);
	RegConsoleCmd("sm_cmd", Command_HelpMenu, "Display the help menu.", FCVAR_NONE);

	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/helpmenu.cfg");
	g_mapArray = CreateArray(32);
	ParseConfigFile(hc);

	AutoExecConfig(false);
}

public void OnMapStart()
{
	char hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/helpmenu.cfg");
	ParseConfigFile(hc);
}

public void OnClientPutInServer(int client)
{
	if (GetConVarBool(g_cvarWelcome))
		CreateTimer(30.0, Timer_WelcomeMessage, client);
}

public Action Timer_WelcomeMessage(Handle timer, any client)
{
	if (GetConVarBool(g_cvarWelcome) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "\x01[SM] For help, type \x04!help\x01 in chat");
}

bool ParseConfigFile(const char[] file)
{
	if (g_helpMenus != INVALID_HANDLE)
	{
		ClearArray(g_helpMenus);
		CloseHandle(g_helpMenus);
		g_helpMenus = INVALID_HANDLE;
	}

	Handle parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	int line = 0;
	int col = 0;
	char error[128];
	SMCError result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay)
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}
	return (result == SMCError_Okay);
}

public SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes)
{
	g_configLevel++;
	if (g_configLevel == 1)
	{
		int hmenu[HelpMenu];
		strcopy(hmenu[name], sizeof(hmenu[name]), section);
		hmenu[items] = CreateDataPack();
		hmenu[itemct] = 0;
		if (g_helpMenus == INVALID_HANDLE)
			g_helpMenus = CreateArray(sizeof(hmenu));
		PushArrayArray(g_helpMenus, hmenu[0]);
	}
	return SMCParse_Continue;
}

public SMCResult Config_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	int msize = GetArraySize(g_helpMenus);
	int hmenu[HelpMenu];
	GetArrayArray(g_helpMenus, msize-1, hmenu[0]);
	switch (g_configLevel)
	{
		case 1:
		{
			if(strcmp(key, "title", false) == 0)
				strcopy(hmenu[title], sizeof(hmenu[title]), value);
			if(strcmp(key, "type", false) == 0)
			{
				if(strcmp(value, "text", false) == 0)
					hmenu[type] = HelpMenuType_Text;
				else
					hmenu[type] = HelpMenuType_List;
			}
		}
		case 2:
		{
			WritePackString(hmenu[items], key);
			WritePackString(hmenu[items], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(g_helpMenus, msize-1, hmenu[0]);
	return SMCParse_Continue;
}

public SMCResult Config_EndSection(Handle parser)
{
	g_configLevel--;
	if (g_configLevel == 1)
	{
		int hmenu[HelpMenu];
		int msize = GetArraySize(g_helpMenus);
		GetArrayArray(g_helpMenus, msize-1, hmenu[0]);
		ResetPack(hmenu[items]);
	}
	return SMCParse_Continue;
}

public void Config_End(Handle parser, bool halted, bool failed)
{
	if (failed)
		SetFailState("Plugin configuration error");
}

public Action Command_HelpMenu(int client, int args)
{
	Help_ShowMainMenu(client);
	return Plugin_Handled;
}

void Help_ShowMainMenu(int client)
{
	Menu menu = CreateMenu(Help_MainMenuHandler);
	SetMenuExitBackButton(menu, false);
	SetMenuTitle(menu, "Help Menu\n ");
	int msize = GetArraySize(g_helpMenus);
	int hmenu[HelpMenu];
	char menuid[10];
	for (int i = 0; i < msize; ++i)
	{
		Format(menuid, sizeof(menuid), "helpmenu_%d", i);
		GetArrayArray(g_helpMenus, i, hmenu[0]);
		AddMenuItem(menu, menuid, hmenu[name]);
	}
	if (GetConVarBool(g_cvarRotation))
	AddMenuItem(menu, "maplist", "Map Rotation");
	if (GetConVarBool(g_cvarAdmins))
		AddMenuItem(menu, "admins", "List Online Admins");
	DisplayMenu(menu, client, 30);
}

public int Help_MainMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char buf[64];
		int msize = GetArraySize(g_helpMenus);
		if (param2 == msize) // Maps
		{
			Menu mapMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(mapMenu, true);
			ReadMapList(g_mapArray, g_mapSerial, "default");
			Format(buf, sizeof(buf), "Current Rotation (%d maps)\n ", GetArraySize(g_mapArray));
			SetMenuTitle(mapMenu, buf);
			if (g_mapArray != INVALID_HANDLE)
			{
				int mapct = GetArraySize(g_mapArray);
				char mapname[64];
				for (int i = 0; i < mapct; ++i)
				{
					GetArrayString(g_mapArray, i, mapname, sizeof(mapname));
					AddMenuItem(mapMenu, mapname, mapname, ITEMDRAW_DISABLED);
				}
			}
			DisplayMenu(mapMenu, param1, 30);
		}
		else if (param2 == msize+1) // Admins
		{
			Menu adminMenu = CreateMenu(Help_MenuHandler);
			SetMenuExitBackButton(adminMenu, true);
			SetMenuTitle(adminMenu, "Online Admins\n ");
			int maxc = GetMaxClients();
			char aname[64];
			for (int i = 1; i < maxc; ++i)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && (GetUserFlagBits(i)) == ADMFLAG_ROOT)
				{
					GetClientName(i, aname, sizeof(aname));
					AddMenuItem(adminMenu, aname, aname, ITEMDRAW_DISABLED);
				}
			}
			DisplayMenu(adminMenu, param1, 30);
		}
		else // Menu from config file
		{
			if (param2 <= msize)
			{
				int hmenu[HelpMenu];
				GetArrayArray(g_helpMenus, param2, hmenu[0]);
				char mtitle[512];
				Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[title]);
				if (hmenu[type] == HelpMenuType_Text)
				{
					Handle cpanel = CreatePanel();
					SetPanelTitle(cpanel, mtitle);
					char text[128];
					char junk[128];
					for (int i = 0; i < hmenu[itemct]; ++i)
					{
						ReadPackString(hmenu[items], junk, sizeof(junk));
						ReadPackString(hmenu[items], text, sizeof(text));
						DrawPanelText(cpanel, text);
					}
					for (int j = 0; j < 7; ++j)
						DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);
					DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Exit", ITEMDRAW_CONTROL);
					ResetPack(hmenu[items]);
					SendPanelToClient(cpanel, param1, Help_MenuHandler, 30);
					CloseHandle(cpanel);
				}
				else
				{
					Menu cmenu = CreateMenu(Help_CustomMenuHandler);
					SetMenuExitBackButton(cmenu, true);
					SetMenuTitle(cmenu, mtitle);
					char cmd[128];
					char desc[128];
					for (int i = 0; i < hmenu[itemct]; ++i)
					{
						ReadPackString(hmenu[items], cmd, sizeof(cmd));
						ReadPackString(hmenu[items], desc, sizeof(desc));
						int drawstyle = ITEMDRAW_DEFAULT;
						if (strlen(cmd) == 0)
							drawstyle = ITEMDRAW_DISABLED;
						AddMenuItem(cmenu, cmd, desc, drawstyle);
					}
					ResetPack(hmenu[items]);
					DisplayMenu(cmenu, param1, 30);
				}
			}
		}
	}
}

public int Help_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8)
	{
		Help_ShowMainMenu(param1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			Help_ShowMainMenu(param1);
	}
}

public int Help_CustomMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char itemval[32];
		GetMenuItem(menu, param2, itemval, sizeof(itemval));
		if (strlen(itemval) > 0)
			FakeClientCommand(param1, itemval);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			Help_ShowMainMenu(param1);
	}
}
