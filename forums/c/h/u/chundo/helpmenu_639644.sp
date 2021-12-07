/*
 * In-game Help Menu
 * Written by chundo (chundo@mefightclub.com)
 *
 * Licensed under the GPL version 2 or above
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.1"

enum ChatCommand {
	String:command[32],
	String:description[255]
}

enum ClanInfo {
	String:name[32],
	String:tag[32],
	String:description[255],
	String:url[128],
	String:email[128]
}

// CVars
new Handle:g_cvarWelcome = INVALID_HANDLE;
new Handle:g_cvarAdmins = INVALID_HANDLE;

// Help data
new String:g_rules[32][255];
new g_ruleCt;
new g_clanInfo[ClanInfo];
new bool:g_hasClanInfo = false;
new g_chatCommands[64][ChatCommand];
new g_chatCommandCt = 0;

// Map cache
new Handle:g_mapArray = INVALID_HANDLE;
new g_mapSerial = -1;

// Config parsing
new String:g_configSection[32];

public Plugin:myinfo =
{
	name = "In-game Help Menu",
	author = "chundo",
	description = "Display a help menu to users",
	version = PLUGIN_VERSION,
	url = "http://www.mefightclub.com"
};

public OnPluginStart() {
	CreateConVar("sm_helpmenu_version", PLUGIN_VERSION, "Help menu version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarWelcome = CreateConVar("sm_helpmenu_welcome", "1", "Show welcome message to newly connected users.", FCVAR_PLUGIN);
	g_cvarAdmins = CreateConVar("sm_helpmenu_admins", "1", "Show a list of online admins in the menu.", FCVAR_PLUGIN);
	RegConsoleCmd("sm_helpmenu", Command_HelpMenu, "Display the help menu.", FCVAR_PLUGIN);

	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/helpmenu.cfg");
	g_mapArray = CreateArray(32);
	ParseConfigFile(hc);

	AutoExecConfig(false);
}

public OnMapStart() {
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/helpmenu.cfg");
	ParseConfigFile(hc);
}

public OnClientAuthorized(client, const String:auth[]) {
	if (GetConVarBool(g_cvarWelcome))
		CreateTimer(30.0, Timer_WelcomeMessage, client);
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) {
	if (GetConVarBool(g_cvarWelcome) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "\x01[SM] For help, type \x04!helpmenu\x01 in chat");
}

bool:ParseConfigFile(const String:file[]) {
	g_ruleCt = 0;
	g_chatCommandCt = 0;
	g_hasClanInfo = false;
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
	strcopy(g_configSection, sizeof(g_configSection), section);
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes) {
	if(strcmp(g_configSection, "Rules", false) == 0) {
		if (g_ruleCt < 32)
			strcopy(g_rules[g_ruleCt++], 255, value);
	} else if(strcmp(g_configSection, "Clan", false) == 0) {
			g_hasClanInfo = true;
			if(strcmp(key, "name", false) == 0)
				strcopy(g_clanInfo[name], sizeof(g_clanInfo[name]), value);
			else if(strcmp(key, "tag", false) == 0)
				strcopy(g_clanInfo[tag], sizeof(g_clanInfo[tag]), value);
			else if(strcmp(key, "description", false) == 0)
				strcopy(g_clanInfo[description], sizeof(g_clanInfo[description]), value);
			else if(strcmp(key, "url", false) == 0)
				strcopy(g_clanInfo[url], sizeof(g_clanInfo[url]), value);
			else if(strcmp(key, "email", false) == 0)
				strcopy(g_clanInfo[email], sizeof(g_clanInfo[email]), value);
	} else if(strcmp(g_configSection, "Commands", false) == 0) {
		if (g_chatCommandCt < 64) {
			new cc[ChatCommand];
			strcopy(cc[command], sizeof(cc[command]), key);
			strcopy(cc[description], sizeof(cc[description]), value);
			g_chatCommands[g_chatCommandCt++] = cc;
		}
	}
	return SMCParse_Continue;
}
public SMCResult:Config_EndSection(Handle:parser) {
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) {
	if (failed)
		SetFailState("Plugin configuration error");
}

public Action:Command_HelpMenu(client, args) {
	Help_ShowMainMenu(client);
	return Plugin_Handled;
}

Help_ShowMainMenu(client) {
	new Handle:menu = CreateMenu(Help_MainMenuHandler);
	SetMenuExitBackButton(menu, false);
	SetMenuTitle(menu, "Help Menu\n ");
	if (g_ruleCt > 0)
		AddMenuItem(menu, "rules", "Server Rules");
	if (g_hasClanInfo)
		AddMenuItem(menu, "clan", "Clan Info");
	if (g_chatCommandCt > 0)
		AddMenuItem(menu, "commands", "Chat Commands");
	AddMenuItem(menu, "maplist", "Map Rotation");
	if (GetConVarBool(g_cvarAdmins))
		AddMenuItem(menu, "admins", "List Online Admins");
	DisplayMenu(menu, client, 30);
}

public Help_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:buf[64];
		switch(param2) {
			case 0: { // Rules
				new Handle:rulesMenu = CreateMenu(Help_MenuHandler);
				SetMenuExitBackButton(rulesMenu, true);
				SetMenuTitle(rulesMenu, "Server Rules\n ");
				for (new i = 0; i < g_ruleCt; ++i) {
					IntToString(i, buf, sizeof(buf));
					AddMenuItem(rulesMenu, buf, g_rules[i], ITEMDRAW_DISABLED);
				}
				DisplayMenu(rulesMenu, param1, 30);
			}
			case 1: { // Clan
				new Handle:clanMenu = CreateMenu(Help_MenuHandler);
				SetMenuExitBackButton(clanMenu, true);
				Format(buf, sizeof(buf), "%s\n%s\n ", g_clanInfo[name], g_clanInfo[description]);
				SetMenuTitle(clanMenu, buf);
				Format(buf, sizeof(buf), "Tag: %s", g_clanInfo[tag]);
				AddMenuItem(clanMenu, "1", buf, ITEMDRAW_DISABLED);
				Format(buf, sizeof(buf), "Web: %s", g_clanInfo[url]);
				AddMenuItem(clanMenu, "2", buf, ITEMDRAW_DISABLED);
				Format(buf, sizeof(buf), "Email: %s", g_clanInfo[email]);
				AddMenuItem(clanMenu, "3", buf, ITEMDRAW_DISABLED);
				DisplayMenu(clanMenu, param1, 30);
			} 
			case 2: { // Commands
				new Handle:commandMenu = CreateMenu(Help_CommandMenuHandler);
				SetMenuExitBackButton(commandMenu, true);
				SetMenuTitle(commandMenu, "Chat Commands\n ");
				for (new i = 0; i < g_chatCommandCt; ++i) {
					Format(buf, sizeof(buf), "%s - %s", g_chatCommands[i][command], g_chatCommands[i][description]);
					AddMenuItem(commandMenu, g_chatCommands[i][command], buf);
				}
				DisplayMenu(commandMenu, param1, 30);
			}
			case 3: { // Maps
				new Handle:mapMenu = CreateMenu(Help_MenuHandler);
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
			}
			case 4: { // Admins
				new Handle:adminMenu = CreateMenu(Help_MenuHandler);
				SetMenuExitBackButton(adminMenu, true);
				SetMenuTitle(adminMenu, "Online Admins\n ");
				new maxc = GetMaxClients();
				new String:aname[64];
				for (new i = 1; i < maxc; ++i) {
					if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
						new AdminId:aid = GetUserAdmin(i);
						if (aid != INVALID_ADMIN_ID) {
							GetClientName(i, aname, sizeof(aname));
							AddMenuItem(adminMenu, aname, aname, ITEMDRAW_DISABLED);
						}
					}
				}
				DisplayMenu(adminMenu, param1, 30);
			} 
		}
	}
}

public Help_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			Help_ShowMainMenu(param1);
	}
}

public Help_CommandMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Select) {
		new String:itemval[32];
		GetMenuItem(menu, param2, itemval, sizeof(itemval));
		FakeClientCommand(param1, "say \"%s\"", itemval);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack)
			Help_ShowMainMenu(param1);
	}
}
