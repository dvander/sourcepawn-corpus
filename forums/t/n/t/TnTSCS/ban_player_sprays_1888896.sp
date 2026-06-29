/* Ban Player Sprays
* 
* 	DESCRIPTION
* 		Allow you to permanently remove a player's ability to use the in-game spray function
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Beta Release
* 
* 		0.0.2.0	*	Added sm_banspray_list for admins to check if anyone connected to the server is banned
* 					from using sprays
* 
* 	TO DO List
* 		*	Add menu for admins to use and a menu for players to be able to view if they're
* 			on the ban list or not
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
*/

#pragma semicolon 1
#include <sourcemod>
#include <adminmenu>
#include <clientprefs>
#include <sdktools>
#include <colors>

#define VERSION "0.0.2.0"

new bool:PlayerCanSpray[MAXPLAYERS+1] = {false, ...};
new bool:PlayerCachedCookie[MAXPLAYERS+1] = {false, ...};
new Handle:g_cookie;
new Handle:g_adminMenu = INVALID_HANDLE;
new Handle:ClientCookieTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new g_BanSprayTarget[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Banned Sprays",
	author = "TnTSCS aka ClarkKent",
	description = "Permanently remove a player's ability to use sprays",
	version = VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_bannedsprays_version", VERSION, "Banned Sprays version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AddTempEntHook("Player Decal", PlayerSpray);
	
	SetCookieMenuItem(Menu_Status, 0, "Display Banned Spray Status");
	
	g_cookie = RegClientCookie("banned-spray", "Banned spray status", CookieAccess_Protected);
	
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_banspray", Command_BanSpray, ADMFLAG_BAN, "Permanently remove a players ability to use spray");
	RegAdminCmd("sm_unbanspray", Command_UnBanSpray, ADMFLAG_BAN, "Permanently remove a players ability to use spray");
	
	new Handle:topmenu = INVALID_HANDLE;
	
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	RegAdminCmd("sm_banspray_list", Command_BanSprayList, ADMFLAG_GENERIC, "List of player's currently connected who are banned from using sprays");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_adminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_adminMenu)
	{
		return;
	}
	
	g_adminMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(g_adminMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	AddToTopMenu(g_adminMenu, "sm_banspray", TopMenuObject_Item, AdminMenu_BanSpray, player_commands, "sm_banspray", ADMFLAG_BAN);
}

public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "Display Banned Spray Status");
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		CreateMenuStatus(client);
	}
}

public AdminMenu_BanSpray(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "Ban/Unban Player Sprays");
		}
		
		case TopMenuAction_SelectOption:
		{
			DisplayBanSprayPlayerMenu(param);
		}
	}
}

stock DisplayBanSprayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_BanSpray);

	decl String:title[100];
	Format(title, sizeof(title), "Ban Sprays for Player:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	//AddTargetsToMenu(menu, client, true, false);
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanSpray(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_adminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_adminMenu, client, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			decl String:info[32];
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new userid = StringToInt(info);
			new target = GetClientOfUserId(userid);
			
			if (!target)
			{
				PrintToChat(client, "[Banned Spray] %t", "Player no longer available");
			}
			else if (!CanUserTarget(client, target))
			{
				PrintToChat(client, "[Banned Spray] %t", "Unable to target");
			}
			else
			{
				g_BanSprayTarget[client] = target;
				DisplayBanSprayMenu(client, target);
			}
		}
	}
}

stock DisplayBanSprayMenu(client, target)
{
	new Handle:menu = CreateMenu(MenuHandler_BanSprays);

	decl String:title[100];
	Format(title, sizeof(title), "Choose:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	decl String:cookie[8];

	GetClientCookie(target, g_cookie, cookie, sizeof(cookie));
	
	if (!strcmp(cookie, "1"))
	{
		AddMenuItem(menu, "0", "UnBan Player's Spray");
	}
	else 
	{
		AddMenuItem(menu, "1", "Ban Player's Spray");
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanSprays(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Cancel:
		{
			if (param1 == MenuCancel_ExitBack && g_adminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(g_adminMenu, client, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			decl String:info[32];
			
			GetMenuItem(menu, param2, info, sizeof(info));
			new action_info = StringToInt(info);
			
			switch (action_info)
			{
				case 0:
				{
					PerformSprayUnBan(client, g_BanSprayTarget[client]);
				}
				
				case 1:
				{
					PerformSprayBan(client, g_BanSprayTarget[client]);
				}
			}
		}
	}
}

stock CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64];
	decl String:cookie[8];
	
	Format(text, sizeof(text), "Banned Spray Status");
	SetMenuTitle(menu, text);

	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (!strcmp(cookie, "1"))
	{
		AddMenuItem(menu, "banned-spray", "You are banned from using sprays", ITEMDRAW_DISABLED);
	}
	else
	{
		AddMenuItem(menu, "banned-spray", "You are not banned from using sprays", ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}

public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					ShowCookieMenu(client);
				}
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}


public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client) && AreClientCookiesCached(client))
	{
		ProcessCookies(client);
	}
	else
	{
		ClientCookieTimer[client] = CreateTimer(10.0, Timer_Cookies, client, TIMER_REPEAT);
	}
}

public Action:Timer_Cookies(Handle:timer, any:client)
{
	if (AreClientCookiesCached(client))
	{
		ProcessCookies(client);
		ClientCookieTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		ClearTimer(ClientCookieTimer[client]);
		PlayerCachedCookie[client] = false;
		PlayerCanSpray[client] = false;
	}
}

public Action:Command_BanSpray(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Ban Spray] Usage: sm_banspray <player>");
		return Plugin_Handled;
	}

	decl target;
	decl String:target_name[MAX_NAME_LENGTH];
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((target = FindTarget( 
			client,
			target_name,
			true,
			true)) <= 0)
	{
		return Plugin_Handled;
	}
	
	PerformSprayBan(client, target);
	
	return Plugin_Handled;
}

public Action:Command_UnBanSpray(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[Ban Spray] Usage: sm_unbanspray <player>");
		return Plugin_Handled;
	}

	decl target;
	decl String:target_name[MAX_NAME_LENGTH];
	
	GetCmdArg(1, target_name, sizeof(target_name));
	
	if ((target = FindTarget( 
			client,
			target_name,
			false,
			true)) <= 0)
	{
		return Plugin_Handled;
	}
	
	PerformSprayUnBan(client, target);
	
	return Plugin_Handled;
}

public Action:Command_BanSprayList(client, args)
{
	new String:bannedlist[4096], count;
	bannedlist[0] = '\0', count = 0;
	
	Format(bannedlist, sizeof(bannedlist), "\nList of Players With Banned Spray Status:\n");
	Format(bannedlist, sizeof(bannedlist), "%sSTATUS       Player Info\n\n", bannedlist);
	
	decl String:cookie[32];
	cookie[0] = '\0';
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			count ++;
			
			GetClientCookie(i, g_cookie, cookie, sizeof(cookie));
			
			if (StrEqual(cookie, "1"))
			{
				Format(bannedlist, sizeof(bannedlist), "%s*** BANNED : %L\n", bannedlist, i);
			}
			else
			{
				Format(bannedlist, sizeof(bannedlist), "%sNot Banned : %L\n", bannedlist, i);
			}
		}
	}
	
	Format(bannedlist, sizeof(bannedlist), "%s\n============================ end of list =============================\n", bannedlist);
	
	if (count == 0)
	{
		ReplyToCommand(client, "No players found");
		return Plugin_Handled;
	}
	
	PrintToConsole(client, bannedlist);
	return Plugin_Continue;
}

public ProcessCookies(client)
{
	PlayerCachedCookie[client] = true;
	PlayerCanSpray[client] = true;
	
	if (PlayerSprayIsBanned(client))
	{
		PrintToServer("[Banned Sprays] Ban added for %N's sprays.", client);
		
		PerformSprayBan(0, client);
	}
}

public PerformSprayBan(admin, client)
{
	PlayerCanSpray[client] = false;
	
	SetClientCookie(client, g_cookie, "1");
	
	if (IsClientInGame(client))
	{
		ShowActivity2(admin, "[Banned Sprays] ", "Banned %N's sprays.", client);
	}
}

public PerformSprayUnBan(admin, client)
{
	PlayerCanSpray[client] = true;
	
	SetClientCookie(client, g_cookie, "0");
	
	if (IsClientInGame(client))
	{
		ShowActivity2(admin, "[Banned Sprays] ", "Unbanned %N's sprays", client);
	}
}

stock bool:PlayerSprayIsBanned(client)
{
	decl String:cookie[32];
	cookie[0] = '\0';
	
	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (StrEqual(cookie, "1"))
	{
		return true;
	}
	
	return false;
}

public Action:PlayerSpray(const String:te_name[], const clients[], client_count, Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	
	if (IsClientInGame(client))
	{
		if (!PlayerCachedCookie[client])
		{
			//CPrintToChat(client, "{green}[{red}Banned Sprays{green}] Permissions are being checked, until verified you cannot use sprays.  Try again in a few seconds.");
			//return Plugin_Handled;
			return Plugin_Continue;
		}
		
		if (!PlayerCanSpray[client])
		{
			CPrintToChat(client, "{red}[{green}Banned Sprays{red}] You are no longer allowed to use sprays on this server.");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}	 
}