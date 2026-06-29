#pragma semicolon 1
#pragma newdecls required

ArrayList g_arrWebShortcuts[2];

public Plugin myinfo =
{
	name = "Web Shortcuts",
	author = "Yaser2007",
	description = "Web shortcuts in menu.",
	version = "1.3",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	RegConsoleCmd("web", Cmd_WebShortcuts);
	RegServerCmd("webreload", Cmd_ReloadWebShortcuts);

	for(int i; i < 2; i++)
	{
		g_arrWebShortcuts[i] = CreateArray(64);
	}
}

public void OnMapStart()
{
	for(int i; i < 2; i++)
	{
		if(GetArraySize(g_arrWebShortcuts[i]) > 0)
		{
			ClearArray(g_arrWebShortcuts[i]);
		}
	}

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/webshortcuts.cfg");

	if(!FileExists(path))
	{
		LogError("Web shortcuts config file '%s' not found!", path);
		return;
	}

	SMCParser parser = SMC_CreateParser();
	SMC_SetReaders(parser, null, SMCKeyValues, null);
	SMC_ParseFile(parser, path);

	LogMessage("%d web shortcuts loaded.", GetArraySize(g_arrWebShortcuts[0]));
}

public Action Cmd_WebShortcuts(int client, int args)
{
	if(!client)
	{
		return Plugin_Handled;
	}

	Menu menu = CreateMenu(Menu_Shortcuts);
	SetMenuTitle(menu, "Web Shortcuts");

	int size = GetArraySize(g_arrWebShortcuts[0]);
	if(size > 0)
	{
		char buffer[2][64];
		for(int i; i < size; i++)
		{
			GetArrayString(g_arrWebShortcuts[0], i, buffer[0], sizeof(buffer[]));
			GetArrayString(g_arrWebShortcuts[1], i, buffer[1], sizeof(buffer[]));
			AddMenuItem(menu, buffer[0], buffer[1]);
		}
	}
	else
	{
		AddMenuItem(menu, NULL_STRING, "No shortcuts found in config file.", ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Action Cmd_ReloadWebShortcuts(int args)
{
	OnMapStart();
	return Plugin_Handled;
}

public SMCResult SMCKeyValues(SMCParser parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	PushArrayString(g_arrWebShortcuts[0], key);
	PushArrayString(g_arrWebShortcuts[1], value);
	return SMCParse_Continue;
}

public void Menu_Shortcuts(Menu menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			char display[20];
			GetMenuItem(menu, item, info, sizeof(info), _, display, sizeof(display));
			ShowMOTDPanelEx(client, display, info, true, MOTDPANEL_TYPE_URL);
		}
	}
}

stock void ShowMOTDPanelEx(int client, const char[] title, const char[] msg, bool unload, int type=MOTDPANEL_TYPE_INDEX)
{
	char num[3];
	IntToString(type, num, sizeof(num));

	KeyValues kv = new KeyValues("data");
	kv.SetString("title", title);
	kv.SetString("type", num);
	kv.SetString("msg", msg);
	kv.SetNum("unload", unload);
	ShowVGUIPanel(client, "info", kv);
	delete kv;
}