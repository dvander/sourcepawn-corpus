/*
 * In-game Help Menu
 * Written by chundo (chundo@mefightclub.com)
 * v0.4 Edit by emsit -> Transitional Syntax, added command sm_commands, added command sm_helpmenu_reload, added cvar sm_helpmenu_autoreload, added cvar sm_helpmenu_config_path, added panel/PrintToChat when command does not exist or item value is text
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "0.4"

enum HelpMenuType {
	HelpMenuType_List,
	HelpMenuType_Text
}

enum HelpMenu {
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
ConVar g_cvarReload;
ConVar g_cvarConfigPath;

// Help menus
Handle g_helpMenus = INVALID_HANDLE;

// Map cache
Handle g_mapArray = INVALID_HANDLE;
int g_mapSerial = -1;

// Config parsing
int g_configLevel = -1;

public Plugin myinfo = {
	name = "In-game Help Menu",
	author = "chundo, emsit",
	description = "Display a help menu to users",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=637467"
};

public void OnPluginStart() {
	CreateConVar("sm_helpmenu_version", PLUGIN_VERSION, "Help menu version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarWelcome = CreateConVar("sm_helpmenu_welcome", "1", "Show welcome message to newly connected users.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarAdmins = CreateConVar("sm_helpmenu_admins", "1", "Show a list of online admins in the menu.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarRotation = CreateConVar("sm_helpmenu_rotation", "1", "Shows the map rotation in the menu.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarReload = CreateConVar("sm_helpmenu_autoreload", "0", "Automatically reload the configuration file when changing the map.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarConfigPath = CreateConVar("sm_helpmenu_config_path", "config/helpmenu.cfg", "Path to configuration file.");

	RegConsoleCmd("sm_helpmenu", Command_HelpMenu, "Display the help menu.");
	RegConsoleCmd("sm_commands", Command_HelpMenu, "Display the help menu.");
	RegAdminCmd("sm_helpmenu_reload", Command_HelpMenuReload, ADMFLAG_ROOT, "Reload the configuration file");

	char hc[PLATFORM_MAX_PATH];
	char buffer[PLATFORM_MAX_PATH];
	g_mapArray = CreateArray(32);

	g_cvarConfigPath.GetString(buffer, sizeof(buffer));
	BuildPath(Path_SM, hc, sizeof(hc), "%s", buffer);
	ParseConfigFile(hc);

	AutoExecConfig(false);
}

public void OnMapStart() {
	if (g_cvarReload.BoolValue) {
		char hc[PLATFORM_MAX_PATH];
		char buffer[PLATFORM_MAX_PATH];

		g_cvarConfigPath.GetString(buffer, sizeof(buffer));
		BuildPath(Path_SM, hc, sizeof(hc), "%s", buffer);
		ParseConfigFile(hc);
	}
}

public void OnClientPostAdminCheck(int client) {
	if (g_cvarWelcome.BoolValue) {
		CreateTimer(15.0, Timer_WelcomeMessage, client);
	}
}

public Action Timer_WelcomeMessage(Handle timer, any client) {
	if (g_cvarWelcome.BoolValue && Client_IsValidHuman(client, true, false, true)) {
		PrintToChat(client, "\x05[SM] \x01For help, type \x04!helpmenu\x01 in chat");
	}
}

bool ParseConfigFile(const char[] file) {
	if (g_helpMenus != INVALID_HANDLE) {
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

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

public SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes) {
	g_configLevel++;
	if (g_configLevel == 1) {
		int hmenu[HelpMenu];
		strcopy(hmenu[name], sizeof(hmenu[name]), section);
		hmenu[items] = CreateDataPack();
		hmenu[itemct] = 0;
		if (g_helpMenus == INVALID_HANDLE) {
			g_helpMenus = CreateArray(sizeof(hmenu));
		}
		PushArrayArray(g_helpMenus, hmenu[0]);
	}

	return SMCParse_Continue;
}

public SMCResult Config_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes) {
	int msize = GetArraySize(g_helpMenus);
	int hmenu[HelpMenu];
	GetArrayArray(g_helpMenus, msize-1, hmenu[0]);
	switch (g_configLevel) {
		case 1: {
			if (strcmp(key, "title", false) == 0)
				strcopy(hmenu[title], sizeof(hmenu[title]), value);
			if (strcmp(key, "type", false) == 0) {
				if (strcmp(value, "text", false) == 0) {
					hmenu[type] = HelpMenuType_Text;
				} else {
					hmenu[type] = HelpMenuType_List;
				}
			}
		}
		case 2: {
			WritePackString(hmenu[items], key);
			WritePackString(hmenu[items], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(g_helpMenus, msize-1, hmenu[0]);

	return SMCParse_Continue;
}
public SMCResult Config_EndSection(Handle parser) {
	g_configLevel--;
	if (g_configLevel == 1) {
		int hmenu[HelpMenu];
		int msize = GetArraySize(g_helpMenus);
		GetArrayArray(g_helpMenus, msize-1, hmenu[0]);
		ResetPack(hmenu[items]);
	}

	return SMCParse_Continue;
}

public void Config_End(Handle parser, bool halted, bool failed) {
	if (failed) {
		SetFailState("Plugin configuration error");
	}
}

public Action Command_HelpMenu(int client, int args) {
	Help_ShowMainMenu(client);

	return Plugin_Handled;
}

public Action Command_HelpMenuReload(int client, int args) {
	char hc[PLATFORM_MAX_PATH];
	char buffer[PLATFORM_MAX_PATH];

	g_cvarConfigPath.GetString(buffer, sizeof(buffer));
	BuildPath(Path_SM, hc, sizeof(hc), "%s", buffer);
	ParseConfigFile(hc);

	PrintToChat(client, "\x05[SM] \x01Configuration file has been reloaded");

	return Plugin_Handled;
}

void Help_ShowMainMenu(int client) {
	Menu menu = CreateMenu(Help_MainMenuHandler);
	menu.SetTitle("Help Menu");

	int msize = GetArraySize(g_helpMenus);
	int hmenu[HelpMenu];
	char menuid[10];

	for (int i = 0; i < msize; ++i) {
		Format(menuid, sizeof(menuid), "helpmenu_%d", i);
		GetArrayArray(g_helpMenus, i, hmenu[0]);
		menu.AddItem(menuid, hmenu[name]);
	}

	if (g_cvarRotation.BoolValue) {
		menu.AddItem("maplist", "Map Rotation");
	}
	if (g_cvarAdmins.BoolValue) {
		menu.AddItem("admins", "List Online Admins");
	}

	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Help_MainMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			char buf[64];
			int msize = GetArraySize(g_helpMenus);
			if (param2 == msize) { // Maps
				Menu mapMenu = CreateMenu(Help_MenuHandler);
				mapMenu.ExitBackButton = true;
				ReadMapList(g_mapArray, g_mapSerial, "default");
				Format(buf, sizeof(buf), "Current Rotation (%d maps)\n ", GetArraySize(g_mapArray));
				mapMenu.SetTitle(buf);

				if (g_mapArray != INVALID_HANDLE) {
					int mapct = GetArraySize(g_mapArray);
					char mapname[64];
					for (int i = 0; i < mapct; ++i) {
						GetArrayString(g_mapArray, i, mapname, sizeof(mapname));
						mapMenu.AddItem(mapname, mapname, ITEMDRAW_DISABLED);
					}
				}
				mapMenu.Display(param1, MENU_TIME_FOREVER);
			} else if (param2 == msize+1) { // Admins
				Menu adminMenu = CreateMenu(Help_MenuHandler);
				adminMenu.ExitBackButton = true;
				adminMenu.SetTitle("Online Admins");
				int maxc = GetMaxClients();
				char aname[64];

				for (int i = 1; i < maxc; ++i) {
					if (Client_IsValidHuman(i, true, false, true) && (GetUserFlagBits(i)) == ADMFLAG_ROOT){
						GetClientName(i, aname, sizeof(aname));
						adminMenu.AddItem(aname, aname, ITEMDRAW_DISABLED);
					}
				}
				adminMenu.Display(param1, MENU_TIME_FOREVER);
			} else { // Menu from config file
				if (param2 <= msize) {
					int hmenu[HelpMenu];
					GetArrayArray(g_helpMenus, param2, hmenu[0]);
					char mtitle[512];
					Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[title]);
					if (hmenu[type] == HelpMenuType_Text) {
						Panel cpanel = CreatePanel();
						cpanel.SetTitle(mtitle);
						char text[128];
						char junk[128];

						for (int i = 0; i < hmenu[itemct]; ++i) {
							ReadPackString(hmenu[items], junk, sizeof(junk));
							ReadPackString(hmenu[items], text, sizeof(text));
							cpanel.DrawText(text);
						}
						for (int j = 0; j < 7; ++j) {
							cpanel.DrawItem(" ", ITEMDRAW_NOTEXT);
						}

						cpanel.DrawText(" ");
						cpanel.DrawItem("Back", ITEMDRAW_CONTROL);
						cpanel.DrawItem(" ", ITEMDRAW_NOTEXT);
						cpanel.DrawText(" ");
						cpanel.DrawItem("Exit", ITEMDRAW_CONTROL);
						ResetPack(hmenu[items]);
						cpanel.Send(param1, Help_MenuHandler, MENU_TIME_FOREVER);
						delete cpanel;
					} else {
						Menu cmenu = CreateMenu(Help_CustomMenuHandler);
						cmenu.ExitBackButton = true;
						cmenu.SetTitle(mtitle);
						char cmd[128];
						char desc[128];

						for (int i = 0; i < hmenu[itemct]; ++i) {
							ReadPackString(hmenu[items], cmd, sizeof(cmd));
							ReadPackString(hmenu[items], desc, sizeof(desc));
							int drawstyle = ITEMDRAW_DEFAULT;
							if (strlen(cmd) == 0) {
								drawstyle = ITEMDRAW_DISABLED;
							}
							cmenu.AddItem(cmd, desc, drawstyle);
						}

						ResetPack(hmenu[items]);
						cmenu.Display(param1, MENU_TIME_FOREVER);
					}
				}
			}
		}
		//case MenuAction_Cancel: {
		//	if (param2 == MenuCancel_ExitBack) {
		//		Help_ShowMainMenu(param1);
		//	}
		//}
		case MenuAction_End: {
			delete menu;
		}
	}
}

public int Help_MenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			if (menu == null && param2 == 8) {
				Help_ShowMainMenu(param1);
			}
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) {
				Help_ShowMainMenu(param1);
			}
		}
		case MenuAction_End: {
			delete menu;
		}
	}
}

public int Help_CustomMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			char itemval[128];
			menu.GetItem(param2, itemval, sizeof(itemval));
			if (strlen(itemval) > 0) {
				char command[64];
				SplitString(itemval, " ", command, sizeof(command));

				if (CommandExist(command, sizeof(command))) {
					FakeClientCommand(param1, itemval);
				} else {
					Panel panel = CreatePanel();
					panel.SetTitle("Description\n ");

					panel.DrawText(itemval);

					for (int j = 0; j < 7; ++j) {
						panel.DrawItem(" ", ITEMDRAW_NOTEXT);
					}

					panel.DrawText(" ");
					panel.DrawItem("Back", ITEMDRAW_CONTROL);
					panel.DrawItem(" ", ITEMDRAW_NOTEXT);
					panel.DrawText(" ");
					panel.DrawItem("Exit", ITEMDRAW_CONTROL);
					panel.Send(param1, Help_MenuHandler, MENU_TIME_FOREVER);
					delete panel;

					PrintToChat(param1, "\x05[SM] \x01%s", itemval);
				}
			}
		}
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) {
				Help_ShowMainMenu(param1);
			}
		}
		case MenuAction_End: {
			delete menu;
		}
	}
}


stock bool Client_IsValidHuman(int client, bool connected = true, bool nobots = true, bool InGame = false) {
	if (!Client_IsValid(client, connected)) {
		return false;
	}

	if (nobots && IsFakeClient(client)) {
		return false;
	}

	if (InGame) {
		return IsClientInGame(client);
	}

	return true;
}

stock bool Client_IsValid(int client, bool checkConnected = true) {
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) {
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}

	return true;
}

stock bool CommandExist(char[] command, int commandLen) {
	//remove the character '!' from the beginning of the command
	if (command[0] == '!') {
		strcopy(command, commandLen, command[1]);
	}

	if (CommandExists(command)) {
		return true;
	}

	//if the command does not exist and has a prefix 'sm_'
	if (!strncmp(command, "sm_", 3)) {
		return false;
	}

	//add the prefix 'sm_' to the beginning of the command
	Format(command, commandLen, "sm_%s", command);
	if (CommandExists(command)) {
		return true;
	}

	return false;
}