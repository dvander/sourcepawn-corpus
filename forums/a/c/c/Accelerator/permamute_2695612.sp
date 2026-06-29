/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * PermaMute
 *
 * Copyright 2008 Ryan Mannion, 2020 Accelerator74. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <basecomm>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PERMAMUTE_VERSION   "1.1"
#define USE_COOKIES			false
#define ACCESS_FLAG			ADMFLAG_CHAT

#if USE_COOKIES
#include <clientprefs>

#define COOKIE_PMUTE		0
#define COOKIE_PGAG			1
#define COOKIE_NUM_COOKIES  2

Cookie g_cookies[COOKIE_NUM_COOKIES];
#else
KeyValues g_hKV;
char datafilepath[PLATFORM_MAX_PATH];
#endif

TopMenu g_adminMenu;
int g_PMuteTarget[MAXPLAYERS+1];

char logsfile[PLATFORM_MAX_PATH];

enum PCommType {
	PCommType_PMute = 0,
	PCommType_PUnMute,
	PCommType_PGag,
	PCommType_PUnGag,
	PCommType_PSilence,
	PCommType_PUnSilence,
	PCommType_NumTypes
};

public Plugin myinfo = {
	name = "PermaMute",
	author = "Ryan \"FLOOR_MASTER\" Mannion, Accelerator",
	description = "Enable permanently muting or gagging a player.",
	version = PERMAMUTE_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2695612&postcount=104"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basecomm.phrases");

#if USE_COOKIES
	g_cookies[COOKIE_PMUTE] = new Cookie("permamute-mute", "PermaMute mute status", CookieAccess_Protected);
	g_cookies[COOKIE_PGAG] = new Cookie("permamute-gag", "PermaMute gag status", CookieAccess_Protected);

	SetCookieMenuItem(Menu_Status, 0, "Display PermaMute Status");
#else
	BuildPath(Path_SM, datafilepath, sizeof(datafilepath), "data/permamute.txt");

	g_hKV = new KeyValues("PermaMute");
	g_hKV.ImportFromFile(datafilepath);
#endif

	RegAdminCmd("sm_pmute", Command_PMute, ACCESS_FLAG, "sm_pmute <player> - Permanently removes a player's ability to use voice.");
	RegAdminCmd("sm_punmute", Command_PUnMute, ACCESS_FLAG, "sm_punmute <player> - Permamently restores a player's ability to use voice.");
	RegAdminCmd("sm_pgag", Command_PGag, ACCESS_FLAG, "sm_pgag <player> - Permanently removes a player's ability to use chat.");
	RegAdminCmd("sm_pungag", Command_PUnGag, ACCESS_FLAG, "sm_pungag <player> - Permanently restores a player's ability to use chat.");
	RegAdminCmd("sm_psilence", Command_PSilence, ACCESS_FLAG, "sm_psilence <player> - Permanently removes a player's ability to use voice and chat.");
	RegAdminCmd("sm_punsilence", Command_PUnSilence, ACCESS_FLAG, "sm_punsilence <player> - Permanently restores a player's ability to use voice and chat.");

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	
	BuildPath(Path_SM, logsfile, sizeof(logsfile), "logs/permamute.log");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_adminMenu = null;
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (topmenu == g_adminMenu)
	{
		return;
	}

	g_adminMenu = topmenu;

	TopMenuObject player_commands = g_adminMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		g_adminMenu.AddItem("sm_pmute", AdminMenu_PMute, player_commands, "sm_pmute", ACCESS_FLAG);
	}
}

public void AdminMenu_PMute(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Perma %T", "Gag/Mute player", param);
		}
		case TopMenuAction_SelectOption:
		{
			DisplayPMutePlayerMenu(param);
		}
	}
}

stock void DisplayPMutePlayerMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PMutePlayer);

	char title[100];
	Format(title, sizeof(title), "Perma %T:", "Gag/Mute player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_PMutePlayer(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_adminMenu)
			{
				g_adminMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			char info[32];
			int userid, target;

			menu.GetItem(param2, info, sizeof(info));
			userid = StringToInt(info);

			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else if (!CanUserTarget(param1, target))
			{
				PrintToChat(param1, "[SM] %t", "Unable to target");
			}
			else
			{
				g_PMuteTarget[param1] = userid;
				DisplayPMuteTypesMenu(param1, target);
			}
		}
	}
}

stock void DisplayPMuteTypesMenu(int client, int target)
{
	Menu menu = new Menu(MenuHandler_PMuteTypes);

	char title[100];
	Format(title, sizeof(title), "%T: %N", "Choose Type", client, target);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	bool silenced = true;

#if USE_COOKIES
	char cookie[8];

	g_cookies[COOKIE_PMUTE].Get(target, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
#else
	int bMute, bGag;

	char SteamID[32];
	GetClientAuthId(target, AuthId_Steam2, SteamID, sizeof(SteamID));

	g_hKV.Rewind();

	if (g_hKV.JumpToKey(SteamID))
	{
		bMute = g_hKV.GetNum("mute", 0);
		bGag = g_hKV.GetNum("gag", 0);
	}

	if (bMute)
#endif
	{
		AddTranslatedMenuItem(menu, "1", "UnMute Player", client);
	}
	else
	{
		AddTranslatedMenuItem(menu, "0", "Mute Player", client);
		silenced = false;
	}

#if USE_COOKIES
	g_cookies[COOKIE_PGAG].Get(target, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
#else
	if (bGag)
#endif
	{
		AddTranslatedMenuItem(menu, "3", "UnGag Player", client);
	}
	else
	{
		AddTranslatedMenuItem(menu, "2", "Gag Player", client);
		silenced = false;
	}

	if (silenced)
	{
		AddTranslatedMenuItem(menu, "5", "UnSilence Player", client);
	}
	else
	{
		AddTranslatedMenuItem(menu, "4", "Silence Player", client);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

void AddTranslatedMenuItem(Menu menu, const char[] opt, const char[] phrase, int client)
{
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", phrase, client);
	menu.AddItem(opt, buffer);
}

public int MenuHandler_PMuteTypes(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
		   delete menu;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_adminMenu)
			{
				g_adminMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_Select:
		{
			char info[32];
			int target;

			menu.GetItem(param2, info, sizeof(info));
			PCommType type = view_as<PCommType>(StringToInt(info));

			if ((target = GetClientOfUserId(g_PMuteTarget[param1])) == 0)
			{
				PrintToChat(param1, "[SM] %t", "Player no longer available");
				return;
			}

			PerformPMute(param1, target, type);
		}
	}
}

stock void PerformPMute(int client, int target, PCommType type, bool log = true)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));

	switch (type)
	{
		case PCommType_PSilence:
		{
			PerformPMute(client, target, PCommType_PMute, false);
			PerformPMute(client, target, PCommType_PGag, false);
			ShowActivity2(client, "[PERMAMUTE] ", "%t", "Silenced target", "_s", name);
			LogToFileEx(logsfile, "<%N> Permanently Silenced <%N>", client, target);
			return;
		}
		case PCommType_PUnSilence:
		{
			PerformPMute(client, target, PCommType_PUnMute, false);
			PerformPMute(client, target, PCommType_PUnGag, false);
			ShowActivity2(client, "[PERMAMUTE] ", "%t", "Unsilenced target", "_s", name);
			LogToFileEx(logsfile, "<%N> Permanently Unsilenced <%N>", client, target);
			return;
		}
	}

#if !USE_COOKIES
	int bMute, bGag;

	char SteamID[32];
	GetClientAuthId(target, AuthId_Steam2, SteamID, sizeof(SteamID));

	g_hKV.Rewind();

	if (g_hKV.JumpToKey(SteamID, (type == PCommType_PMute || type == PCommType_PGag ? true : false)))
	{
		bMute = g_hKV.GetNum("mute", 0);
		bGag = g_hKV.GetNum("gag", 0);
	}
	else
		return;
#endif

	switch (type)
	{
		case PCommType_PMute:
		{
			BaseComm_SetClientMute(target, true);

			#if USE_COOKIES
			g_cookies[COOKIE_PMUTE].Set(target, "1");
			#else
			g_hKV.SetNum("mute", 1);
			bMute = 1;
			#endif

			if (log)
			{
				ShowActivity2(client, "[PERMAMUTE] ", "%t", "Muted target", "_s", name);
				LogToFileEx(logsfile, "<%N> Permanently Muted <%N>", client, target);
			}
		}
		case PCommType_PUnMute:
		{
			BaseComm_SetClientMute(target, false);

			#if USE_COOKIES
			g_cookies[COOKIE_PMUTE].Set(target, "0");
			#else
			g_hKV.SetNum("mute", 0);
			bMute = 0;
			#endif

			if (log)
			{
				ShowActivity2(client, "[PERMAMUTE] ", "%t", "Unmuted target", "_s", name);
				LogToFileEx(logsfile, "<%N> Permanently Unmuted <%N>", client, target);
			}
		}
		case PCommType_PGag:
		{
			BaseComm_SetClientGag(target, true);

			#if USE_COOKIES
			g_cookies[COOKIE_PGAG].Set(target, "1");
			#else
			g_hKV.SetNum("gag", 1);
			bGag = 1;
			#endif

			if (log)
			{
				ShowActivity2(client, "[PERMAMUTE] ", "%t", "Gagged target", "_s", name);
				LogToFileEx(logsfile, "<%N> Permanently Gagged <%N>", client, target);
			}
		}
		case PCommType_PUnGag:
		{
			BaseComm_SetClientGag(target, false);

			#if USE_COOKIES
			g_cookies[COOKIE_PGAG].Set(target, "0");
			#else
			g_hKV.SetNum("gag", 0);
			bGag = 0;
			#endif

			if (log)
			{
				ShowActivity2(client, "[PERMAMUTE] ", "%t", "Ungagged target", "_s", name);
				LogToFileEx(logsfile, "<%N> Permanently Ungagged <%N>", client, target);
			}
		}
	}

#if !USE_COOKIES
	if (!bMute && !bGag)
	{
		g_hKV.DeleteThis();
	}
	
	g_hKV.Rewind();
	g_hKV.ExportToFile(datafilepath);
#endif
}

#if USE_COOKIES
public void Menu_Status(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "Display PermaMute Status");
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		CreateMenuStatus(client);
	}
}

stock void CreateMenuStatus(int client)
{
	Menu menu = new Menu(Menu_StatusDisplay);
	char text[128], cookie[8];

	Format(text, sizeof(text), "PermaMute Status");
	menu.SetTitle(text);

	g_cookies[COOKIE_PMUTE].Get(client, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
	{
		FormatTime(text, sizeof(text), "You are permanently muted %Y-%m-%d %H:%M:%S", g_cookies[COOKIE_PMUTE].GetClientTime(client));
		menu.AddItem("permamute-mute", text, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem("permamute-mute", "You are not permanently muted", ITEMDRAW_DISABLED);
	}

	g_cookies[COOKIE_PGAG].Get(client, cookie, sizeof(cookie));
	if (StrEqual(cookie, "1"))
	{
		FormatTime(text, sizeof(text), "You are permanently gagged %Y-%m-%d %H:%M:%S", g_cookies[COOKIE_PGAG].GetClientTime(client));
		menu.AddItem("permamute-gag", text, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem("permamute-gag", "You are not permanently gagged", ITEMDRAW_DISABLED);
	}

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, 15);
}

public int Menu_StatusDisplay(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowCookieMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}
#endif

public void OnClientPostAdminCheck(int client)
{
#if USE_COOKIES
	if (!IsFakeClient(client) && AreClientCookiesCached(client))
#else
	if (!IsFakeClient(client))
#endif
	{
#if USE_COOKIES
		char cookie[8];

		g_cookies[COOKIE_PMUTE].Get(client, cookie, sizeof(cookie));
		if (StrEqual(cookie, "1"))
#else
		int bMute, bGag;

		char SteamID[32];
		GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));

		g_hKV.Rewind();

		if (g_hKV.JumpToKey(SteamID))
		{
			bMute = g_hKV.GetNum("mute", 0);
			bGag = g_hKV.GetNum("gag", 0);
		}

		if (bMute)
#endif
		{
			BaseComm_SetClientMute(client, true);
		}

#if USE_COOKIES
		g_cookies[COOKIE_PGAG].Get(client, cookie, sizeof(cookie));
		if (StrEqual(cookie, "1"))
#else
		if (bGag)
#endif
		{
			BaseComm_SetClientGag(client, true);
		}
	}
}

public Action Command_PMute(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[PERMAMUTE] Usage: sm_pmute <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	TargetedAction(client, PCommType_PMute, arg);
	return Plugin_Handled;
}

public Action Command_PUnMute(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[PERMAMUTE] Usage: sm_punmute <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	TargetedAction(client, PCommType_PUnMute, arg);
	return Plugin_Handled;
}

public Action Command_PGag(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[PERMAMUTE] Usage: sm_pgag <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	TargetedAction(client, PCommType_PGag, arg);
	return Plugin_Handled;
}

public Action Command_PUnGag(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[PERMAMUTE] Usage: sm_pungag <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	TargetedAction(client, PCommType_PUnGag, arg);
	return Plugin_Handled;
}

public Action Command_PSilence(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[PERMAMUTE] Usage: sm_psilence <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	TargetedAction(client, PCommType_PSilence, arg);
	return Plugin_Handled;
}

public Action Command_PUnSilence(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[PERMAMUTE] Usage: sm_punsilence <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	TargetedAction(client, PCommType_PUnSilence, arg);
	return Plugin_Handled;
}

stock void TargetedAction(int client, PCommType type, const char[] target_string)
{
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			target_string,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return;
	}

	for (int i = 0; i < target_count; i++)
	{
		PerformPMute(client, target_list[i], type);
	}
}