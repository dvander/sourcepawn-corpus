/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basic Commands Plugin
 * Implements basic admin commands.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sm_limit_ban_duration>

public Plugin:myinfo =
{
	name = "(LBD) Basic Ban Commands",
	author = "AlliedModders LLC",
	description = "Basic Banning Commands, with optional Limit Ban Duration support.",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:hTopMenu = INVALID_HANDLE;
new bool:g_bLimitBan;
new g_BanTarget[MAXPLAYERS+1];
new g_BanTargetUserId[MAXPLAYERS+1];
new g_BanTime[MAXPLAYERS+1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basebans.phrases");

	RegAdminCmd("sm_ban", Command_Ban, ADMFLAG_BAN, "sm_ban <#userid|name> <minutes|0> [reason]");
	RegAdminCmd("sm_unban", Command_Unban, ADMFLAG_UNBAN, "sm_unban <steamid|ip>");
	RegAdminCmd("sm_addban", Command_AddBan, ADMFLAG_RCON, "sm_addban <time> <steamid> [reason]");
	RegAdminCmd("sm_banip", Command_BanIp, ADMFLAG_BAN, "sm_banip <ip|#userid|name> <time> [reason]");
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAllPluginsLoaded()
{
	g_bLimitBan = LibraryExists("sm_limit_ban_duration");
}
 
public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "sm_limit_ban_duration"))
		g_bLimitBan = false;
}
 
public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "sm_limit_ban_duration"))
		g_bLimitBan = true;
}

public OnConfigsExecuted()
{
	decl String:_sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, _sPath, sizeof(_sPath), "plugins/basebans.smx");
	if(FileExists(_sPath))
	{
		decl String:_sNewPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, _sNewPath, sizeof(_sNewPath), "plugins/disabled/basebans.smx");
		ServerCommand("sm plugins unload basebans");
		if(FileExists(_sNewPath))
			DeleteFile(_sNewPath);
		RenameFile(_sNewPath, _sPath);
		LogMessage("plugins/basebans.smx was unloaded and moved to plugins/disabled/basebans.smx");
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_ban",
			TopMenuObject_Item,
			AdminMenu_Ban,
			player_commands,
			"sm_ban",
			ADMFLAG_BAN);
			
	}
}

public Action:Command_BanIp(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_banip <ip|#userid|name> <time> [reason]");
		return Plugin_Handled;
	}

	decl len, next_len;
	decl String:Arguments[256];
	decl String:arg[50], String:time[20];
	
	GetCmdArgString(Arguments, sizeof(Arguments));
	len = BreakString(Arguments, arg, sizeof(arg));
	
	if ((next_len = BreakString(Arguments[len], time, sizeof(time))) != -1)
	{
		len += next_len;
	}
	else
	{
		len = 0;
		Arguments[0] = '\0';
	}

	if (StrEqual(arg, "0"))
	{
		ReplyToCommand(client, "[SM] %t", "Cannot ban that IP");
		return Plugin_Handled;
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[1], bool:tn_is_ml;
	new found_client = -1;
	
	if (ProcessTargetString(
			arg,
			client, 
			target_list, 
			1, 
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml) > 0)
	{
		found_client = target_list[0];
	}
	
	new bool:has_rcon;
	
	if (client == 0 || (client == 1 && !IsDedicatedServer()))
	{
		has_rcon = true;
	}
	else
	{
		new AdminId:id = GetUserAdmin(client);
		has_rcon = (id == INVALID_ADMIN_ID) ? false : GetAdminFlag(id, Admin_RCON);
	}
	
	new hit_client = -1;
	if (found_client != -1
		&& !IsFakeClient(found_client)
		&& (has_rcon || CanUserTarget(client, found_client)))
	{
		GetClientIP(found_client, arg, sizeof(arg));
		hit_client = found_client;
	}
	
	if (hit_client == -1 && !has_rcon)
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	new minutes = StringToInt(time);

	LogAction(client, 
			  hit_client, 
			  "\"%L\" added ban (minutes \"%d\") (ip \"%s\") (reason \"%s\")", 
			  client, 
			  minutes, 
			  arg, 
			  Arguments[len]);
				
	ReplyToCommand(client, "[SM] %t", "Ban added");
	
	BanIdentity(arg, 
				minutes, 
				BANFLAG_IP, 
				Arguments[len], 
				"sm_banip", 
				client);
				
	if (hit_client != -1)
	{
		KickClient(hit_client, "Banned: %s", Arguments[len]);
	}

	return Plugin_Handled;
}

public Action:Command_AddBan(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addban <time> <steamid> [reason]");
		return Plugin_Handled;
	}

	decl String:arg_string[256];
	new String:time[50];
	new String:authid[50];

	GetCmdArgString(arg_string, sizeof(arg_string));

	new len, total_len;

	/* Get time */
	if ((len = BreakString(arg_string, time, sizeof(time))) == -1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addban <time> <steamid> [reason]");
		return Plugin_Handled;
	}	
	total_len += len;

	/* Get steamid */
	if ((len = BreakString(arg_string[total_len], authid, sizeof(authid))) != -1)
	{
		total_len += len;
	}
	else
	{
		total_len = 0;
		arg_string[0] = '\0';
	}

	/* Verify steamid */
	if (strncmp(authid, "STEAM_", 6) != 0 || authid[7] != ':')
	{
		ReplyToCommand(client, "[SM] %t", "Invalid SteamID specified");
		return Plugin_Handled;
	}

	new minutes = StringToInt(time);

	LogAction(client, 
			  -1, 
			  "\"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", 
			  client, 
			  minutes, 
			  authid, 
			  arg_string[total_len]);
	BanIdentity(authid, 
				minutes, 
				BANFLAG_AUTHID, 
				arg_string[total_len], 
				"sm_addban", 
				client);

	ReplyToCommand(client, "[SM] %t", "Ban added");

	return Plugin_Handled;
}

public Action:Command_Unban(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unban <steamid|ip>");
		return Plugin_Handled;
	}

	decl String:arg[50];
	GetCmdArgString(arg, sizeof(arg));

	ReplaceString(arg, sizeof(arg), "\"", "");	

	new ban_flags;
	if (strncmp(arg, "STEAM_", 6) == 0 && arg[7] == ':')
	{
		ban_flags |= BANFLAG_AUTHID;
	}
	else
	{
		ban_flags |= BANFLAG_IP;
	}

	LogAction(client, -1, "\"%L\" removed ban (filter \"%s\")", client, arg);
	RemoveBan(arg, ban_flags, "sm_unban", client);

	ReplyToCommand(client, "[SM] %t", "Removed bans matching", arg);

	return Plugin_Handled;
}

/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basecommands
 * Functionality related to banning.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

PrepareBan(client, target, time, const String:reason[])
{
	new originalTarget = GetClientOfUserId(g_BanTargetUserId[client]);

	if (originalTarget != target)
	{
		if (client == 0)
		{
			PrintToServer("[SM] %t", "Player no longer available");
		}
		else
		{
			PrintToChat(client, "[SM] %t", "Player no longer available");
		}

		return;
	}

	decl String:authid[64], String:name[32];
	GetClientAuthString(target, authid, sizeof(authid));
	GetClientName(target, name, sizeof(name));

	if (!time)
	{
		if (reason[0] == '\0')
		{
			ShowActivity(client, "%t", "Permabanned player", name);
		} else {
			ShowActivity(client, "%t", "Permabanned player reason", name, reason);
		}
	} else {
		if (reason[0] == '\0')
		{
			ShowActivity(client, "%t", "Banned player", name, time);
		} else {
			ShowActivity(client, "%t", "Banned player reason", name, time, reason);
		}
	}

	LogAction(client, target, "\"%L\" banned \"%L\" (minutes \"%d\") (reason \"%s\")", client, target, time, reason);

	if (reason[0] == '\0')
	{
		BanClient(target, time, BANFLAG_AUTO, "Banned", "Banned", "sm_ban", client);
	}
	else
	{
		BanClient(target, time, BANFLAG_AUTO, reason, reason, "sm_ban", client);
	}
}

DisplayBanTargetMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_BanPlayerList);

	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Ban player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayBanTimeMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_BanTimeList);

	decl String:title[100];
	Format(title, sizeof(title), "%T: %N", "Ban player", client, g_BanTarget[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	new _iSize = LimitBan_GetSize();
	if(!g_bLimitBan || !_iSize)
	{
		AddMenuItem(menu, "0", "Permanent");
		AddMenuItem(menu, "10", "10 Minutes");
		AddMenuItem(menu, "30", "30 Minutes");
		AddMenuItem(menu, "60", "1 Hour");
		AddMenuItem(menu, "240", "4 Hours");
		AddMenuItem(menu, "1440", "1 Day");
		AddMenuItem(menu, "10080", "1 Week");
	}
	else
	{
		decl String:_sDisplay[64], String:_sLength[32];
		for(new i = 0; i <= _iSize; i++)
		{
			if(LimitBan_GetAccess(i, client))
			{
				new _iLength = LimitBan_GetLength(i);
				IntToString(_iLength, _sLength, sizeof(_sLength));
				LimitBan_GetDisplay(i, _sDisplay);
				AddMenuItem(menu, _sLength, _sDisplay);
			}
		}
		
		if(LimitBan_GetAccess(-1, client))
		{
			LimitBan_GetDisplay(-1, _sDisplay);
			AddMenuItem(menu, "0", _sDisplay);
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

DisplayBanReasonMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_BanReasonList);

	decl String:title[100];
	Format(title, sizeof(title), "%T: %N", "Ban reason", client, g_BanTarget[client]);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	/* :TODO: we should either remove this or make it configurable */

	AddMenuItem(menu, "Abusive", "Abusive");
	AddMenuItem(menu, "Racism", "Racism");
	AddMenuItem(menu, "General cheating/exploits", "General cheating/exploits");
	AddMenuItem(menu, "Wallhack", "Wallhack");
	AddMenuItem(menu, "Aimbot", "Aimbot");
	AddMenuItem(menu, "Speedhacking", "Speedhacking");
	AddMenuItem(menu, "Mic spamming", "Mic spamming");
	AddMenuItem(menu, "Admin disrespect", "Admin disrespect");
	AddMenuItem(menu, "Camping", "Camping");
	AddMenuItem(menu, "Team killing", "Team killing");
	AddMenuItem(menu, "Unacceptable Spray", "Unacceptable Spray");
	AddMenuItem(menu, "Breaking Server Rules", "Breaking Server Rules");
	AddMenuItem(menu, "Other", "Other");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AdminMenu_Ban(Handle:topmenu,
							  TopMenuAction:action,
							  TopMenuObject:object_id,
							  param,
							  String:buffer[],
							  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Ban player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayBanTargetMenu(param);
	}
}

public MenuHandler_BanReasonList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[64];

		GetMenuItem(menu, param2, info, sizeof(info));

		PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info);
	}
}

public MenuHandler_BanPlayerList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:name[32];
		new userid, target;

		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
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
			g_BanTarget[param1] = target;
			g_BanTargetUserId[param1] = userid;
			DisplayBanTimeMenu(param1);
		}
	}
}

public MenuHandler_BanTimeList(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];

		GetMenuItem(menu, param2, info, sizeof(info));
		g_BanTime[param1] = StringToInt(info);

		DisplayBanReasonMenu(param1);
	}
}


public Action:Command_Ban(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ban <#userid|name> <minutes|0> [reason]");
		return Plugin_Handled;
	}

	decl len, next_len;
	decl String:Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	decl String:arg[65];
	len = BreakString(Arguments, arg, sizeof(arg));

	new target = FindTarget(client, arg, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	decl String:s_time[12];
	if ((next_len = BreakString(Arguments[len], s_time, sizeof(s_time))) != -1)
	{
		len += next_len;
	}
	else
	{
		len = 0;
		Arguments[0] = '\0';
	}

	new time = StringToInt(s_time);

	g_BanTargetUserId[client] = GetClientUserId(target);

	PrepareBan(client, target, time, Arguments[len]);

	return Plugin_Handled;
}