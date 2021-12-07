#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.1"
#define CHAT_TAG "[\x05hMenus\x01]"

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required
ConVar sm_hMenus_enabled;
ConVar sm_hMenus_joinmenu;

Handle g_hCookie;

char g_szConfig[PLATFORM_MAX_PATH];


public Plugin myinfo = 
{
	name = "hConfigMenus", 
	author = PLUGIN_AUTHOR, 
	description = "This plugin allows you to make your own menu from a config file. This plugin also allows you to put commands in as well.", 
	version = PLUGIN_VERSION, 
	url = "NUN"
};

public void OnPluginStart()
{
	g_hCookie = RegClientCookie("Joinmenu", "This is for when a player joins it will not keep showing on map changes", CookieAccess_Private);
	
	sm_hMenus_enabled = CreateConVar("sm_hMenus_enabled", "1", "Enables or disables the hMenus");
	sm_hMenus_joinmenu = CreateConVar("sm_hMenus_joinmenu", "1", "(1) The join menu will only show once (0) The join menu will show on every map change");
	
	BuildPath(Path_SM, g_szConfig, sizeof(g_szConfig), "configs/hMenus.cfg");
	
	AddCommandListener(Say_Hook, "say");
	AddCommandListener(Say_Hook, "say_team");
}

public void OnClientCookiesCached(int client)
{
	char cookieValue[32];
	GetClientCookie(client, g_hCookie, cookieValue, 32);
	int value = StringToInt(cookieValue);
	
	if(value == 1 && sm_hMenus_joinmenu.BoolValue)
		return;
		
	CreateTimer(5.0, showMenu, client);
	return;
}

public Action showMenu(Handle timer, int client)
{
	createJoinMenu(client);
	SetClientCookie(client, g_hCookie, "1");
}

public void createJoinMenu(int client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		Handle g_hKVV = CreateKeyValues("Menus");
		FileToKeyValues(g_hKVV, g_szConfig);
		Menu menu = new Menu(ConfigMenu_callback);
		if (KvJumpToKey(g_hKVV, "join", false))
		{
			char title[64], flag[3];
			KvGetString(g_hKVV, "flag", flag, 3);
			if (!StrEqual(flag, "") && !(GetUserFlagBits(client) & ReadFlagString(flag)))
			{
				PrintToChat(client, CHAT_TAG..." You do not have access to this menu");
				return;
			}
			
			KvGetString(g_hKVV, "title", title, 64);
			menu.SetTitle(title);
			for (int i = 0; i < 16; i++)
			{
				char checkFor[32], splitCommand[2][64], items[128];
				Format(checkFor, 32, "item%i", i);
				
				KvGetString(g_hKVV, checkFor, items, 128);
				if (!StrEqual(items, "end", false))
				{
					ExplodeString(items, "||", splitCommand, 2, 64);
					menu.AddItem(items, splitCommand[0]);
				} else {
					menu.Display(client, 0);
					KvRewind(g_hKVV);
					CloseHandle(g_hKVV);
					return;
				}
			}
			menu.Display(client, 0);
			KvRewind(g_hKVV);
			CloseHandle(g_hKVV);
		}
	}
	return;
}

public Action Say_Hook(int client, const char[] command, int argc)
{
	char sText[512];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	if (sm_hMenus_enabled.BoolValue && sText[0] == '|')
		checkCommand(client, sText);
	return Plugin_Continue;
}

public void checkCommand(int client, const char[] sText)
{
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		Handle g_hKVV = CreateKeyValues("Menus");
		FileToKeyValues(g_hKVV, g_szConfig);
		Menu menu = new Menu(ConfigMenu_callback);
		
		if (KvJumpToKey(g_hKVV, sText, false))
		{
			char title[64], flag[3];
			KvGetString(g_hKVV, "flag", flag, 3);
			if (!StrEqual(flag, "") && !(GetUserFlagBits(client) & ReadFlagString(flag)))
			{
				PrintToChat(client, CHAT_TAG..." You do not have access to this menu");
				return;
			}
			
			KvGetString(g_hKVV, "title", title, 64);
			menu.SetTitle(title);
			for (int i = 0; i < 16; i++)
			{
				char checkFor[32], splitCommand[2][64], items[128];
				Format(checkFor, 32, "item%i", i);
				
				KvGetString(g_hKVV, checkFor, items, 128);
				if (!StrEqual(items, "end", false))
				{
					ExplodeString(items, "||", splitCommand, 2, 64);
					menu.AddItem(items, splitCommand[0]);
				} else {
					menu.Display(client, 0);
					KvRewind(g_hKVV);
					CloseHandle(g_hKVV);
					return;
				}
			}
			menu.Display(client, 0);
			KvRewind(g_hKVV);
			CloseHandle(g_hKVV);
			return;
		}
	}
}

public int ConfigMenu_callback(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char szItem[128], splitCommand[2][64];
			GetMenuItem(menu, param2, szItem, 128);
			ExplodeString(szItem, "||", splitCommand, 2, 64);
			if (StrEqual(splitCommand[1], "reopen menu"))
				menu.Display(client, 0);
			else if (StrContains(splitCommand[1], "submenu", false) == 0)
				createSubMenu(client, splitCommand[1]);
			else if (StrContains(splitCommand[1], "targetmenu", false) == 0)
				createTargetMenu(client, splitCommand[1]);
			else if (!StrEqual(splitCommand[1], "none", false))
			{
				ClientCommand(client, splitCommand[1]);
				PrintToChat(client, CHAT_TAG..." hMenus has executed the command %s", splitCommand[1]);
			}
		}
	}
}

public void createSubMenu(int client, char[] subMenu)
{
	char getMenuName[2][64];
	ExplodeString(subMenu, "::", getMenuName, 2, 64);
	
	Handle g_hKVV = CreateKeyValues("Menus");
	FileToKeyValues(g_hKVV, g_szConfig);
	Menu menu = new Menu(ConfigMenu_callback);
	if (KvJumpToKey(g_hKVV, getMenuName[1], false))
	{
		char title[64], flag[3];
		KvGetString(g_hKVV, "flag", flag, 3);
		if (!StrEqual(flag, "") && !(GetUserFlagBits(client) & ReadFlagString(flag)))
		{
			PrintToChat(client, CHAT_TAG..." You do not have access to this menu");
			return;
		}
		
		KvGetString(g_hKVV, "title", title, 64);
		menu.SetTitle(title);
		for (int i = 0; i < 16; i++)
		{
			char checkFor[32], splitCommand[2][64], items[128];
			Format(checkFor, 32, "item%i", i);
			
			KvGetString(g_hKVV, checkFor, items, 128);
			if (!StrEqual(items, "end", false))
			{
				ExplodeString(items, "||", splitCommand, 2, 64);
				menu.AddItem(items, splitCommand[0]);
			} else {
				menu.Display(client, 0);
				KvRewind(g_hKVV);
				CloseHandle(g_hKVV);
				return;
			}
		}
		menu.Display(client, 0);
		KvRewind(g_hKVV);
		CloseHandle(g_hKVV);
	}
}

public void createTargetMenu(int client, char[] command)
{
	char getCommand[2][32];
	ExplodeString(command, "::", getCommand, 2, 32);
	
	Menu targets = new Menu(ConfigMenu_callback);
	targets.SetTitle("Choose a client");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			char commandExecute[64], name[MAX_NAME_LENGTH];
			GetClientName(i, name, MAX_NAME_LENGTH);
			Format(commandExecute, 64, "||%s #%s", getCommand[1], name);
			targets.AddItem(commandExecute, name);
		}
	}
	targets.Display(client, 0);
} 