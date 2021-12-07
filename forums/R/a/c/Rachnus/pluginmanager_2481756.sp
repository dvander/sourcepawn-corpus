#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.00"

#include <adminmenu>
#include <sourcemod>
#include <sdktools>


#pragma newdecls required

KeyValues g_kvPluginManager;
Menu g_menuMain;

public Plugin myinfo = 
{
	name = "Plugin Manager",
	author = PLUGIN_AUTHOR,
	description = "Load, Unload, Reload plugins through menu or by commands, edit access",
	version = PLUGIN_VERSION,
	url = "http://rachnus.blogspot.fi/"
};

public void OnPluginStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/pluginmanager.txt");
	g_kvPluginManager = new KeyValues("pluginmanager");
	
	if(!g_kvPluginManager.ImportFromFile(path))
		SetFailState("Could not open %s", path);
	g_kvPluginManager.SetEscapeSequences(true);
	
	RegAdminCmd("sm_plugins", Command_Plugins, ADMFLAG_GENERIC, "Open plugin menu. Usage: sm_plugins");
	
	RegAdminCmd("sm_load", Command_Load, ADMFLAG_GENERIC, "Load a plugin. Usage: sm_load <pluginname>");
	RegAdminCmd("sm_unload", Command_Unload, ADMFLAG_GENERIC, "Unload a plugin. Usage: sm_unload <pluginname>");
	RegAdminCmd("sm_reload", Command_Reload, ADMFLAG_GENERIC, "Reload a plugin. Usage: sm_reload <pluginname>");
	
	RegAdminCmd("sm_pmrefresh", Command_Refresh, ADMFLAG_ROOT, "Refresh pluginmanager config file. Usage: sm_pmrefresh");
}

public void OnAdminMenuReady(Handle topmenu)
{
	TopMenuObject test = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS);
	if(test == INVALID_TOPMENUOBJECT)
	{
		LogError("Error: Invalid topmenuobject");
		return;
	}
	char storage[PLATFORM_MAX_PATH];
	AddToTopMenu(topmenu, "Plugins", TopMenuObject_Item, AdminMenu, test, "sm_plugins", ADMFLAG_CONFIG, storage);
}

public int AdminMenu(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Plugins");
	else if (action == TopMenuAction_SelectOption)
		Command_Plugins(param, 0);
}

public Action Command_Plugins(int client, int args)
{
	//AdminFlag flag;
	//FindFlagByChar(98, flag);
	
	//if(GetUserFlagBits(client) & FlagToBit(flag))
	//	PrintToChatAll("my plate of rice is empty");
	
	g_menuMain = new Menu(PluginMenuHandler);
	g_menuMain.SetTitle("Plugins:");
	
	char prefix[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, prefix, sizeof(prefix), "plugins/");

	Handle dir = OpenDirectory(prefix);
	char PluginFile[PLATFORM_MAX_PATH];
	FileType fileType;
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/pluginmanager.txt");
	
	while(ReadDirEntry(dir, PluginFile, sizeof(PluginFile), fileType))
	{
		if(fileType == FileType_File)
		{
			if(CheckCommandAccess(client, "", ADMFLAG_ROOT, true))
			{
				g_menuMain.AddItem(PluginFile, PluginFile);
			}
			else
			{
				g_kvPluginManager.Rewind();
				if(g_kvPluginManager.JumpToKey(PluginFile, true))
				{
					char flags[32];
					int flagbits;
					g_kvPluginManager.GetString("flags", flags, sizeof(flags));
					
					if(StrEqual(flags, "", false))
						g_kvPluginManager.SetString("flags", "z");
					
					flagbits = ReadFlagString(flags);
					
					
					if (GetUserFlagBits(client) & flagbits)
						g_menuMain.AddItem(PluginFile, PluginFile);
				}
				g_kvPluginManager.Rewind();
				g_kvPluginManager.ExportToFile(path);
			}
		}
	}
	
	delete dir;
	g_menuMain.ExitBackButton = true;
	g_menuMain.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int PluginMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char info[32];
	GetMenuItem(menu, param2, info, sizeof(info));
	
	if(action == MenuAction_Select)
	{
		Menu menu2 = new Menu(OptionMenuHandler);
		menu2.SetTitle("Option");
		menu2.AddItem(info, "Load");
		menu2.AddItem(info, "Unload");
		menu2.AddItem(info, "Reload");
		menu2.ExitBackButton = true;
		menu2.Display(param1, MENU_TIME_FOREVER);
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		DisplayTopMenuCategory(GetAdminTopMenu(), FindTopMenuCategory(GetAdminTopMenu(), ADMINMENU_SERVERCOMMANDS), param1);
	}
}

public int OptionMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char info[32];
	char display[32];
	GetMenuItem(menu, param2, info, sizeof(info), _, display, sizeof(display));
	
	if(action == MenuAction_Select)
	{
		if(StrEqual(display, "Load", false))
			LoadPlugin(info, param1);
		else if(StrEqual(display, "Unload", false))
			UnloadPlugin(info, param1);
		else if(StrEqual(display, "Reload", false))
			ReloadPlugin(info, param1);
		
		Menu menu3 = new Menu(OptionMenuHandler);
		menu3.SetTitle("Option");
		menu3.AddItem(info, "Load");
		menu3.AddItem(info, "Unload");
		menu3.AddItem(info, "Reload");
		menu3.ExitBackButton = true;
		menu3.Display(param1, MENU_TIME_FOREVER);
	}
	else if(param2 == MenuCancel_ExitBack)
	{
		g_menuMain.Display(param1, MENU_TIME_FOREVER);
	}
}

public Action Command_Load(int client, int args)
{
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(args != 1)
	{
		ReplyToCommand(client, " \x04[PluginManager] \x01Usage: sm_load <pluginname>");
		return Plugin_Handled;
	}
	
	if(StrContains(arg, ".smx", false) == -1)
	{
		Format(arg, sizeof(arg), "%s.smx", arg);
	}
	
	if(!CheckCommandAccess(client, "", ADMFLAG_ROOT, true))
	{
		g_kvPluginManager.Rewind();
		if(g_kvPluginManager.JumpToKey(arg, false))
		{
			char flags[32];
			int flagbits;
			g_kvPluginManager.GetString("flags", flags, sizeof(flags));
			flagbits = ReadFlagString(flags);
			
			if (!(GetUserFlagBits(client) & flagbits))
			{
				ReplyToCommand(client, " \x04[PluginManager] \x01You do not have permission to manage '\x05%s\x01'", arg);
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' does not exist!", arg);
			return Plugin_Handled;
		}
	}

	LoadPlugin(arg, client);
	return Plugin_Handled;
}

void LoadPlugin(char[] name, int client)
{
	char namebuffer[PLATFORM_MAX_PATH];
	strcopy(namebuffer, sizeof(namebuffer), name);
	if(StrContains(namebuffer, ".smx", false) == -1)
	{
		Format(namebuffer, sizeof(namebuffer), "%s.smx", namebuffer);
	}
	
	if(FindPluginByFile(namebuffer) != null)
	{
		PrintToChat(client," \x04[PluginManager] \x01Plugin '\x05%s\x01' is already loaded!", namebuffer);
	}
	else
	{
		ServerCommand("sm plugins load %s", namebuffer);
		
		DataPack pack = new DataPack();
		CreateDataTimer(0.1, Timer_PluginCheckLoad, pack);
		pack.WriteCell(client);
		pack.WriteString(namebuffer);
	}	
}

public Action Timer_PluginCheckLoad(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	char arg[65];  
	pack.ReadString(arg, sizeof(arg));

	if(FindPluginByFile(arg) != null)
		PrintToChat(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' loaded \x04successfully\x01!", arg);
	else
		PrintToChat(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' \x02failed \x01to load!", arg);
	
}

public Action Command_Unload(int client, int args)
{
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(args != 1)
	{
		ReplyToCommand(client, " \x04[PluginManager] Usage: sm_unload <pluginname>");
		return Plugin_Handled;
	}
	
	if(StrContains(arg, ".smx", false) == -1)
	{
		Format(arg, sizeof(arg), "%s.smx", arg);
	}
	
	if(!CheckCommandAccess(client, "", ADMFLAG_ROOT, true))
	{
		g_kvPluginManager.Rewind();
		if(g_kvPluginManager.JumpToKey(arg, false))
		{
			char flags[32];
			int flagbits;
			g_kvPluginManager.GetString("flags", flags, sizeof(flags));
			flagbits = ReadFlagString(flags);
			
			if (!(GetUserFlagBits(client) & flagbits))
			{
				ReplyToCommand(client, " \x04[PluginManager] \x01You do not have permission to manage '\x05%s\x01'", arg);
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' does not exist!", arg);
			return Plugin_Handled;
		}
	}
	
	UnloadPlugin(arg, client);

	return Plugin_Handled;
}

void UnloadPlugin(char[] name, int client)
{
	char namebuffer[PLATFORM_MAX_PATH];
	strcopy(namebuffer, sizeof(namebuffer), name);
	if(StrContains(namebuffer, ".smx", false) == -1)
	{
		Format(namebuffer, sizeof(namebuffer), "%s.smx", namebuffer);
	}

	if(FindPluginByFile(namebuffer) == null)
	{
		PrintToChat(client," \x04[PluginManager] \x01Plugin '\x05%s\x01' is not loaded!", namebuffer);
	}
	else
	{
		ServerCommand("sm plugins unload %s", namebuffer);
		
		DataPack pack = new DataPack();
		CreateDataTimer(0.1, Timer_PluginCheckUnload, pack);
		pack.WriteCell(client);
		pack.WriteString(namebuffer);
	}	
}

public Action Timer_PluginCheckUnload(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	char arg[65];  
	pack.ReadString(arg, sizeof(arg));

	if(FindPluginByFile(arg) == null)
		PrintToChat(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' unloaded \x04successfully\x01!", arg);
	else
		PrintToChat(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' \x02failed \x01to unload!", arg);
	
}

public Action Command_Reload(int client, int args)
{
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(args != 1)
	{
		ReplyToCommand(client, " \x04[PluginManager] \x01Usage: sm_reload <pluginname>");
		return Plugin_Handled;
	}
	
	if(StrContains(arg, ".smx", false) == -1)
	{
		Format(arg, sizeof(arg), "%s.smx", arg);
	}
	
	if(!CheckCommandAccess(client, "", ADMFLAG_ROOT, true))
	{
		g_kvPluginManager.Rewind();
		if(g_kvPluginManager.JumpToKey(arg, false))
		{
			char flags[32];
			int flagbits;
			g_kvPluginManager.GetString("flags", flags, sizeof(flags));
			flagbits = ReadFlagString(flags);
			
			if (!(GetUserFlagBits(client) & flagbits))
			{
				ReplyToCommand(client, " \x04[PluginManager] \x01You do not have permission to manage '\x05%s\x01'", arg);
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' does not exist!", arg);
			return Plugin_Handled;
		}
	}
	
	ReloadPlugin(arg, client);
	return Plugin_Handled;
}

void ReloadPlugin(char[] name, int client)
{
	char namebuffer[PLATFORM_MAX_PATH];
	strcopy(namebuffer, sizeof(namebuffer), name);
	if(StrContains(namebuffer, ".smx", false) == -1)
	{
		Format(namebuffer, sizeof(namebuffer), "%s.smx", namebuffer);
	}
	
	if(FindPluginByFile(namebuffer) == null)
	{
		PrintToChat(client," \x04[PluginManager] \x01Plugin '\x05%s\x01' is not loaded!", namebuffer);
	}
	else
	{
		ServerCommand("sm plugins reload %s", namebuffer);
		
		DataPack pack = new DataPack();
		CreateDataTimer(0.1, Timer_PluginCheckReload, pack);
		pack.WriteCell(client);
		pack.WriteString(namebuffer);
	}
}

public Action Timer_PluginCheckReload(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	char arg[65];  
	pack.ReadString(arg, sizeof(arg));

	if(FindPluginByFile(arg) != null)
		PrintToChat(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' reloaded \x04successfully\x01!", arg);
	else
		PrintToChat(client, " \x04[PluginManager] \x01Plugin '\x05%s\x01' \x02failed \x01to reload!", arg);
	
}

public Action Command_Refresh(int client, int args)
{
	delete g_kvPluginManager;
	
	g_kvPluginManager = new KeyValues("pluginmanager"); 
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/pluginmanager.txt");
	if(!g_kvPluginManager.ImportFromFile(path))
		SetFailState("Could not open %s", path);
		
	g_kvPluginManager.SetEscapeSequences(true);
	ReplyToCommand(client, " \x04[PluginManager] \x01Pluginmanager configs have been refreshed.");
	return Plugin_Handled;
}