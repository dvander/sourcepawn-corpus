#include <sourcemod>

#define PLUGIN_VERSION "1.1.1"

new Handle:enabled = INVALID_HANDLE;
new Handle:g_donateMenus = INVALID_HANDLE;
new Handle:triggerenabled = INVALID_HANDLE;
new Handle:c_trigger = INVALID_HANDLE;

new String:trigger[128]
new g_configLevel = -1;

//////////////////
enum ChatCommand
{
	String:command[32],
	String:description[255]
}

enum DonateMenuType
{
	DonateMenuType_List,
	DonateMenuType_Text
}

enum DonateMenu
{
	String:name[32],
	String:title[128],
	DonateMenuType:type,
	Handle:items,
	itemct
}
//////////////////

public Plugin:myinfo =
{
	name = "Server Donation Info",
	author = "ReFlexPoison",
	description = "Show Information About Server Donations in Menu",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_donateinfo_version", PLUGIN_VERSION, "Server Donation Info Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	enabled = CreateConVar("sm_donateinfo_enabled", "1", "Enabled Server Donation Info\n0=Disabled\n1=Enabled", _, true, 0.0, true, 1.0);
	triggerenabled = CreateConVar("sm_donateinfo_triggerenabled", "2", "Opens Info Menu if Chat Message Conatins Chat Trigger\n0=Disabled\n1=Enabled\n2=Enabled (Hides Chat Trigger)", _, true, 0.0, true, 2.0);

	c_trigger = CreateConVar("sm_donateinfo_trigger", "!donate", "Chat Trigger for Server Donation Info");
	GetConVarString(c_trigger, trigger, sizeof(trigger));
	HookConVarChange(c_trigger, CVarChanged);

	RegConsoleCmd("sm_donateinfo", Command_DonateMenu);
	RegServerCmd("sm_donateinfo_reload", Command_DonateMenuReload);

	AddCommandListener(Command_say, "say");
	AddCommandListener(Command_say, "say_team");

	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/donateinfo.cfg");
	ParseConfigFile(hc);
	
	AutoExecConfig(true, "plugin.donateinfo")
}

public Action:Command_DonateMenu(client, args)
{
	if(GetConVarInt(enabled))
	{
		if(FileExists("addons/sourcemod/configs/donateinfo.cfg"))
		{
			Donate_ShowMainMenu(client);
		}
		else
		{
			PrintToServer("Necessary configuration file not found. *donateinfo.cfg*")
		}
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

Donate_ShowMainMenu(client)
{
	new Handle:menu = CreateMenu(Donate_MainMenuHandler);
	SetMenuExitBackButton(menu, false);
	SetMenuTitle(menu, "Donate Menu");
	new msize = GetArraySize(g_donateMenus);
	new hmenu[DonateMenu];
	new String:menuid[10];
	for(new i = 0; i < msize; ++i)
	{
		Format(menuid, sizeof(menuid), "donatemenu_%d", i);
		GetArrayArray(g_donateMenus, i, hmenu[0]);
		AddMenuItem(menu, menuid, hmenu[name]);
	}
	DisplayMenu(menu, client, 30);
}

public Action:Command_say(client, const String:cmd[], args)
{
	if(GetConVarInt(triggerenabled) && GetConVarInt(enabled))
	{
		new String:text[192];
		GetCmdArgString(text, sizeof(text));

		new startidx = 0;
		if(text[0] == '"')
		{
			startidx = 1;
			new len = strlen(text);

			if(text[len-1] == '"') text[len-1] = '\0';
		}
		GetConVarString(c_trigger, trigger, sizeof(trigger));
		{
			if(StrEqual(text[startidx], trigger, true))
			{
				FakeClientCommand(client, "sm_donateinfo");
				if(GetConVarInt(triggerenabled) == 1)
				{
					return Plugin_Continue;
				}
				if(GetConVarInt(triggerenabled) == 2)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_DonateMenuReload(client)
{
	new String:hc[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, hc, sizeof(hc), "configs/donateinfo.cfg");
	ParseConfigFile(hc);
	PrintToServer("Config file: *donateinfo.cfg* reloaded");
}

bool:ParseConfigFile(const String:file[])
{
	if(g_donateMenus != INVALID_HANDLE)
	{
		ClearArray(g_donateMenus);
		CloseHandle(g_donateMenus);
		g_donateMenus = INVALID_HANDLE;
	}

	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	new line = 0;
	new col = 0;
	new String:error[128];
	new SMCError:result = SMC_ParseFile(parser, file, line, col);
	CloseHandle(parser);

	if(result != SMCError_Okay)
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}

	return(result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	g_configLevel++;
	if(g_configLevel == 1)
	{
		new hmenu[DonateMenu];
		strcopy(hmenu[name], sizeof(hmenu[name]), section);
		hmenu[items] = CreateDataPack();
		hmenu[itemct] = 0;
		if(g_donateMenus == INVALID_HANDLE)
		{
			g_donateMenus = CreateArray(sizeof(hmenu));
		}
		PushArrayArray(g_donateMenus, hmenu[0]);
	}
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	new msize = GetArraySize(g_donateMenus);
	new hmenu[DonateMenu];
	GetArrayArray(g_donateMenus, msize-1, hmenu[0]);
	switch(g_configLevel)
	{
		case 1:
		{
			if(strcmp(key, "title", false) == 0)
			{
				strcopy(hmenu[title], sizeof(hmenu[title]), value);
			}
			if(strcmp(key, "type", false) == 0)
			{
				if(strcmp(value, "text", false) == 0)
				{
					hmenu[type] = DonateMenuType_Text;
				}
				else
				{
					hmenu[type] = DonateMenuType_List;
				}
			}
		}
		case 2:
		{
			WritePackString(hmenu[items], key);
			WritePackString(hmenu[items], value);
			hmenu[itemct]++;
		}
	}
	SetArrayArray(g_donateMenus, msize-1, hmenu[0]);
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser)
{
	g_configLevel--;
	if(g_configLevel == 1)
	{
		new hmenu[DonateMenu];
		new msize = GetArraySize(g_donateMenus);
		GetArrayArray(g_donateMenus, msize-1, hmenu[0]);
		ResetPack(hmenu[items]);
	}
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed)
{
	if(failed)
	{
		SetFailState("Plugin configuration error");
	}
}

public Donate_MainMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else
	{
		if(action == MenuAction_Select)
		{
			new msize = GetArraySize(g_donateMenus);
			if(param2 == msize)
			{
				new Handle:mapMenu = CreateMenu(Donate_MenuHandler);
				SetMenuExitBackButton(mapMenu, true);
				DisplayMenu(mapMenu, param1, 30);
			}
			else
			{
				if(param2 == msize+1) // Admins
				{
					new Handle:adminMenu = CreateMenu(Donate_MenuHandler);
					SetMenuExitBackButton(adminMenu, true);
					SetMenuTitle(adminMenu, "Online Admins\n ");
					new maxc = GetMaxClients();
					new String:aname[64];
					for(new i = 1; i < maxc; ++i) {
						if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) &&(GetUserFlagBits(i) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC)
						{
							GetClientName(i, aname, sizeof(aname));
							AddMenuItem(adminMenu, aname, aname, ITEMDRAW_DISABLED);
						}
					}
					DisplayMenu(adminMenu, param1, 30);
				}
				else
				{
					if(param2 <= msize)
					{
						new hmenu[DonateMenu];
						GetArrayArray(g_donateMenus, param2, hmenu[0]);
						new String:mtitle[512];
						Format(mtitle, sizeof(mtitle), "%s\n ", hmenu[title]);
						if(hmenu[type] == DonateMenuType_Text)
						{
							new Handle:cpanel = CreatePanel();
							SetPanelTitle(cpanel, mtitle);
							new String:text[128];
							new String:junk[128];
							for(new i = 0; i < hmenu[itemct]; ++i)
							{
								ReadPackString(hmenu[items], junk, sizeof(junk));
								ReadPackString(hmenu[items], text, sizeof(text));
								DrawPanelText(cpanel, text);
							}
							for(new j = 0; j < 7; ++j)
							{
								DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
							}
							DrawPanelText(cpanel, " ");
							DrawPanelItem(cpanel, "Back", ITEMDRAW_CONTROL);
							DrawPanelItem(cpanel, " ", ITEMDRAW_NOTEXT);
							DrawPanelText(cpanel, " ");
							DrawPanelItem(cpanel, "Exit", ITEMDRAW_CONTROL);
							ResetPack(hmenu[items]);
							SendPanelToClient(cpanel, param1, Donate_MenuHandler, 30);
							CloseHandle(cpanel);
						}
						else
						{
							new Handle:cmenu = CreateMenu(Donate_CustomMenuHandler);
							SetMenuExitBackButton(cmenu, true);
							SetMenuTitle(cmenu, mtitle);
							new String:cmd[128];
							new String:desc[128];
							for(new i = 0; i < hmenu[itemct]; ++i)
							{
								ReadPackString(hmenu[items], cmd, sizeof(cmd));
								ReadPackString(hmenu[items], desc, sizeof(desc));
								new drawstyle = ITEMDRAW_DEFAULT;
								if(strlen(cmd) == 0)
								{
									drawstyle = ITEMDRAW_DISABLED;
								}
								AddMenuItem(cmenu, cmd, desc, drawstyle);
							}
							ResetPack(hmenu[items]);
							DisplayMenu(cmenu, param1, 30);
						}
					}
				}
			}
		}
	}
}

public Donate_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else
	{
		if(menu == INVALID_HANDLE && action == MenuAction_Select && param2 == 8)
		{
			Donate_ShowMainMenu(param1);
		}
		else
		{
			if(action == MenuAction_Cancel)
			{
				if(param2 == MenuCancel_ExitBack)
				{
					Donate_ShowMainMenu(param1);
				}
			}
		}
	}
}

public Donate_CustomMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else
	{
		if(action == MenuAction_Select)
		{
			new String:itemval[32];
			GetMenuItem(menu, param2, itemval, sizeof(itemval));
			if(strlen(itemval) > 0)
			{
				FakeClientCommand(param1, itemval);
			}
		}
		else
		{
			if(action == MenuAction_Cancel)
			{
				if(param2 == MenuCancel_ExitBack)
				{
					Donate_ShowMainMenu(param1);
				}
			}
		}
	}
}

public CVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, trigger, sizeof(trigger));
}