/*
 * In-game VIP MENU
 * Written by chundo (chundo@mefightclub.com)
 * Edited by Snowie (http://steamcommunity.com/id/TheSnowieMaster/)
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.9"

enum ChatCommand {
	String:command[32],
	String:description[255]
}

enum VipMenuType {
	VipMenuType_List,
	VipMenuType_Text
}

enum VipMenu {
	String:name[32],
	String:title[128],
	VipMenuType:type,
	Handle:items,
	itemct
}

// CVars
new Handle:g_cvarWelcome = INVALID_HANDLE;
new Handle:g_cvarAdmins = INVALID_HANDLE;

// Vip menus
new Handle:g_vipMenus = INVALID_HANDLE;

// Map cache
new Handle:g_mapArray = INVALID_HANDLE;
new g_mapSerial = -1;

// Config parsing
new g_configLevel = -1;

public Plugin:myinfo =
{
	name = "In-game vip Menu",
	author = "chundo",
	description = "Display a vip menu to users",
	version = PLUGIN_VERSION,
	url = "http://www.mefightclub.com"
};

public OnPluginStart() {
	CreateConVar("sm_vipmenu_version", PLUGIN_VERSION, "Vip menu version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarWelcome = CreateConVar("sm_vipmenu_welcome", "1", "Show welcome message to newly connected users.", FCVAR_PLUGIN);
	g_cvarAdmins = CreateConVar("sm_vipmenu_admins", "1", "Show a list of online admins in the menu.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_vip", Command_VipMenu, "Display the vip menu.", FCVAR_PLUGIN);

	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/vipmenu.cfg");
	g_mapArray = CreateArray(32);
	ParseConfigFile(hc);

	AutoExecConfig(false);
}

public OnMapStart() {
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/vipmenu.cfg");
	ParseConfigFile(hc);
}

public OnClientPutInServer(client) {
	if (GetConVarBool(g_cvarWelcome))
		CreateTimer(30.0, Timer_WelcomeMessage, client);
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (GetConVarBool(g_cvarWelcome) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "\x01[SM] For vip, type \x04!vip\x01 in chat");
}

bool:ParseConfigFile(const String:file[]) {
	if (g_vipMenus != INVALID_HANDLE) {
		ClearArray(g_vipMenus);
		CloseHandle(g_vipMenus);
		g_vipMenus = INVALID_HANDLE;
	}

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if (result != SMCError_Okay) {
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) {
	g_configLevel++;
	if (g_configLevel == 1) {
		new hmenu[VipMenu];
		strcopy(hmenu[name], sizeof(hmenu[name]), section);
		hmenu[items] = CreateDataPack();
		hmenu[itemct] = 0;
		if (g_vipMenus == INVALID_HANDLE)
			g_vipMenus = CreateArray(sizeof(hmenu));
		PushArrayArray(g_vipMenus, hmenu[0]);
	}
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	new msize = GetArraySize(g_vipMenus);
	new hmenu[VipMenu];
	GetArrayArray(g_vipMenus, msize-1, hmenu[0]);
	switch (g_configLevel) {
		case 1: {
			if(strcmp(key, "title", false) == 0)
				strcopy(hmenu[title], sizeof(hmenu[title]), value);
			if(strcmp(key, "type", false) == 0) {
				if(strcmp(value, "text", false) == 0)
					hmenu[type] = VipMenuType_Text;
				else
					hmenu[type] = VipMenuType_List;
			}
		}
		case 2: {
			WritePackString(hmenu[items], key);
			WritePackString(hmenu[items], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(g_vipMenus, msize-1, hmenu[0]);
	return SMCParse_Continue;
}
public SMCResult:Config_EndSection(Handle:parser) {
	g_configLevel--;
	if (g_configLevel == 1) {
		new hmenu[VipMenu];
		new msize = GetArraySize(g_vipMenus);
		GetArrayArray(g_vipMenus, msize-1, hmenu[0]);
		ResetPack(hmenu[items]);
	}
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (failed)
		SetFailState("Plugin configuration error");
}

public Action:Command_VipMenu(client, args) {
	Vip_ShowMainMenu(client);
	return Plugin_Handled;
}

Vip_ShowMainMenu(client) {
	new Handle:menu = CreateMenu(Vip_MainMenuHandler);
	SetMenuExitBackButton(menu, false);
	SetMenuTitle(menu, "Vip Menu\n ");
	new msize = GetArraySize(g_vipMenus);
	new hmenu[VipMenu];
	new String:menuid[10];
	for (new i = 0; i < msize; ++i) {
		Format(menuid, sizeof(menuid), "vip_%d", i);
		GetArrayArray(g_vipMenus, i, hmenu[0]);
		AddMenuItem(menu, menuid, hmenu[name]);
	}
	if (GetConVarBool(g_cvarAdmins))
		AddMenuItem(menu, "admins", "List Online Admins");
	DisplayMenu(menu, client, 30);
}

public Vip_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:buf[64];
		new msize = GetArraySize(g_vipMenus);
		if (param2 == msize) { // Maps
			new Handle:mapMenu = CreateMenu(Vip_MenuHandler);
			SetMenuExitBackButton(mapMenu, true);
			ReadMapList(g_mapArray, g_mapSerial, "default");
			Format(buf, sizeof(buf), "Current Rotation (%d maps)\n ", GetArraySize(g_mapArray));
			SetMenuTitle(mapMenu, buf);
			if (g_mapArray != INVALID_HANDLE) {
				new mapct = GetArraySize(g_mapArray);
				new String:mapname[64];
				for (new i = 0; i < mapct; ++i) {
					GetArrayString(g_mapArray, i, mapname, sizeof(mapname));
					AddMenuItem(mapMenu, mapname, mapname, ITEMDRAW_DISABLED);
				}
			}
			DisplayMenu(mapMenu, param1, 30);
		} else if (param2 == msize+1) { // Admins
			new Handle:adminMenu = CreateMenu(Vip_MenuHandler);
			SetMenuExitBackButton(adminMenu, true);
			SetMenuTitle(adminMenu, "Online Admins\n ");
			new maxc = GetMaxClients();
			new String:aname[64];
			for (new i = 1; i < maxc; ++i) {
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) {
					GetClientName(i, aname, sizeof(aname));
					AddMenuItem(adminMenu, aname, aname, ITEMDRAW_DISABLED);
				}
			}
			DisplayMenu(adminMenu, param1, 30);
		} else { // Menu from config file
			if (param2 <= msize) {
				new hmenu[VipMenu];
				GetArrayArray(g_vipMenus, param2, hmenu[0]);
				new String:mtitle[512];
				Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[title]);
				if (hmenu[type] == VipMenuType_Text) {
					new Handle:cpanel = CreatePanel();
					SetPanelTitle(cpanel, mtitle);
					new String:text[128];
					new String:junk[128];
					for (new i = 0; i < hmenu[itemct]; ++i) {
						ReadPackString(hmenu[items], junk, sizeof(junk));
						ReadPackString(hmenu[items], text, sizeof(text));
						DrawPanelText(cpanel, text);
					}
					for (new j = 0; j < 7; ++j)
						DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);
					DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
					DrawPanelText(cpanel, " ");
					DrawPanelItem(cpanel, "Exit", ITEMDRAW_CONTROL);
					ResetPack(hmenu[items]);
					SendPanelToClient(cpanel, param1, Vip_MenuHandler, 30);
					CloseHandle(cpanel);
				} else {
					new Handle:cmenu = CreateMenu(Vip_CustomMenuHandler);
					SetMenuExitBackButton(cmenu, true);
					SetMenuTitle(cmenu, mtitle);
					new String:cmd[128];
					new String:desc[128];
					for (new i = 0; i < hmenu[itemct]; ++i) {
						ReadPackString(hmenu[items], cmd, sizeof(cmd));
						ReadPackString(hmenu[items], desc, sizeof(desc));
						new drawstyle = ITEMDRAW_DEFAULT;
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

public Vip_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8) {
		Vip_ShowMainMenu(param1);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			Vip_ShowMainMenu(param1);
	}
}

public Vip_CustomMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:itemval[32];
		GetMenuItem(menu, param2, itemval, sizeof(itemval));
		if (strlen(itemval) > 0)
			FakeClientCommand(param1, itemval);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			Vip_ShowMainMenu(param1);
	}
}
