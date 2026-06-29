#include <sourcemod>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <zombiereloaded>

Handle g_hQuickMenu;
char sTitle[128];

enum struct MenuCommand
{
	char sDisplay[128];
	char sCommand[64];
}

MenuCommand g_Menu[32];

int iTotalChoice; 
bool g_zombiereloaded = false;

bool g_bToggle[MAXPLAYERS+1];
int iLastButton[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[ANY] Quick Menu",
	author = "Oylsister",
	description = "Open your quick menu on the server",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_shortcut", Command_Toggle);
	RegConsoleCmd("sm_shortcuts", Command_Toggle);
	RegConsoleCmd("sm_sc", Command_Toggle);
	RegAdminCmd("sm_reloadsc", Command_Reload, ADMFLAG_CONFIG);
	
	g_hQuickMenu = RegClientCookie("quickmenu_cookies", "Quick Menu Cookies", CookieAccess_Protected);
	SetCookiePrefabMenu(g_hQuickMenu, CookieMenu_OnOff_Int, "Quick Shortcut Menu", ToggleCookiesHandler);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!AreClientCookiesCached(i))
			continue;
			
		OnClientCookiesCached(i);
	}
}

public void OnAllPluginsLoaded()
{
	if(LibraryExists("zombiereloaded"))
		g_zombiereloaded = true;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "zombiereloaded", false))
		g_zombiereloaded = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "zombiereloaded", false))
		g_zombiereloaded = false;
}

public Action Command_Reload(int client, int args)
{
	LoadConfig();
	PrintToChat(client, " \x04[Shortcuts]\x01 Successfully reloaded the config file.");
	return Plugin_Handled;
}

public Action Command_Toggle(int client, int args)
{
	g_bToggle[client] = !g_bToggle[client];
	if(g_bToggle[client] == true)
	{
		PrintToChat(client, " \x04[Shortcuts]\x01 You have \x05enabled \x10!shorcut \x01menu.");
	}
	else
	{
		PrintToChat(client, " \x04[Shortcuts]\x01 You have \x07disabled \x10!shorcut \x01menu.");
	}
	SaveClientCookies(client);
	return Plugin_Handled;
}

public void OnMapStart()
{
	LoadConfig();
}

void LoadConfig()
{
	KeyValues kv;
	char sConfig[PLATFORM_MAX_PATH];
	char sTemp[16];
	
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/quickmenu.txt");
	kv = CreateKeyValues("quickmenu");
	FileToKeyValues(kv, sConfig);
	
	if(KvGotoFirstSubKey(kv))
	{
		iTotalChoice = 0;
		do
		{
			KvGetSectionName(kv, sTemp, 16);
			if(StrEqual(sTemp, "title", false))
			{
				KvGetString(kv, "text", sTitle, sizeof(sTitle));
			}
			else
			{
				KvGetString(kv, "display", g_Menu[iTotalChoice].sDisplay, 128);
				KvGetString(kv, "command", g_Menu[iTotalChoice].sCommand, 64);
				iTotalChoice++;
			}
		}
		while (KvGotoNextKey(kv));
	}
	delete kv;
}

public void OnClientCookiesCached(int client)
{
	char sValue[16];
	GetClientCookie(client, g_hQuickMenu, sValue, sizeof(sValue));
	
	if(sValue[0] != '\0')
		g_bToggle[client] = view_as<bool>(StringToInt(sValue));
		
	else
	{
		g_bToggle[client] = true;
		FormatEx(sValue, sizeof(sValue), "%b", g_bToggle[client]);
		SetClientCookie(client, g_hQuickMenu, sValue);
	}
}

public void SaveClientCookies(int client)
{
	char sValue[16];
	FormatEx(sValue, sizeof(sValue), "%b", g_bToggle[client]);
	SetClientCookie(client, g_hQuickMenu, sValue);
}

public ToggleCookiesHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_DisplayOption:
		{
			if(g_bToggle[client])
			{
				Format(buffer, maxlen, "Shortcut Menu : On");
			}
			else
			{
				Format(buffer, maxlen, "Shortcut Menu : Off");
			}
		}
		
		case CookieMenuAction_SelectOption:
		{
			g_bToggle[client] = !g_bToggle[client];
			SaveClientCookies(client);
			ShowCookieMenu(client);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!g_bToggle[client])
		return Plugin_Continue;
		
	else
	{
		if((buttons & IN_SPEED) && !(iLastButton[client] & IN_SPEED))
		{
			if(!g_zombiereloaded)
			{
				ShowQuickMenu(client);
			}
			else
			{
				if(!ZR_IsClientZombie(client))
					ShowQuickMenu(client);
				
				else
					return Plugin_Continue;
			}
		}
		iLastButton[client] = buttons;
		return Plugin_Continue;
	}
}

public void ShowQuickMenu(int client)
{
	Menu menu = new Menu(ShowQuickMenuHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("%s", sTitle);
	char sTemp[128]; 
	for (int i = 0; i < iTotalChoice; i++)
	{
		Format(sTemp, sizeof(sTemp), "%s", g_Menu[i].sDisplay);
		char info[32];
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, sTemp);
	}
	menu.ExitButton = true;
	menu.Display(client, 12);
}

public int ShowQuickMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			for (int i = 0; i < iTotalChoice; i++)
			{
				if(param2 == i)
				{
					ClientCommand(param1, "%s", g_Menu[i].sCommand);
				}
			}
		}
		case MenuAction_End:
			delete menu;
	}
}