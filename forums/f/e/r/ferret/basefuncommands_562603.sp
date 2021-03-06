/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basic Fun Commands Plugin
 * Implements basic punishment commands.
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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
 * Version: $Id: basefuncommands.sp 1791 2007-12-12 02:16:25Z ferret $
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin:myinfo =
{
	name = "Basic Fun Commands",
	author = "AlliedModders LLC",
	description = "Basic Fun Commands",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:hTopMenu = INVALID_HANDLE;

new g_SlapDamage[MAXPLAYERS+1];

#include "basefuncommands/slay.sp"
#include "basefuncommands/burn.sp"
#include "basefuncommands/slap.sp"
#include "basefuncommands/beacon.sp"

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basefuncommands.phrases");

	RegAdminCmd("sm_burn", Command_Burn, ADMFLAG_SLAY, "sm_burn <#userid|name> [time]");
	RegAdminCmd("sm_slap", Command_Slap, ADMFLAG_SLAY, "sm_slap <#userid|name> [damage]");
	RegAdminCmd("sm_slay", Command_Slay, ADMFLAG_SLAY, "sm_slay <#userid|name>");
	RegAdminCmd("sm_beacon", Command_Beacon, ADMFLAG_SLAY, "sm_beacon <#userid|name>");
	RegAdminCmd("sm_play", Command_Play, ADMFLAG_GENERIC, "sm_play <#userid|name> <filename>");
	
	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	SetupBeacon();	
}

public OnMapEnd()
{
	KillAllBeacons();
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
			"sm_slay",
			TopMenuObject_Item,
			AdminMenu_Slay,
			player_commands,
			"sm_slay",
			ADMFLAG_SLAY);
			
		AddToTopMenu(hTopMenu,
			"sm_burn",
			TopMenuObject_Item,
			AdminMenu_Burn,
			player_commands,
			"sm_burn",
			ADMFLAG_SLAY);
			
		AddToTopMenu(hTopMenu,
			"sm_slap",
			TopMenuObject_Item,
			AdminMenu_Slap,
			player_commands,
			"sm_slap",
			ADMFLAG_SLAY);	
			
		AddToTopMenu(hTopMenu,
			"sm_beacon",
			TopMenuObject_Item,
			AdminMenu_Beacon,
			player_commands,
			"sm_beacon",
			ADMFLAG_SLAY);			
	}
}

public Action:Command_Play(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_play <#userid|name> <filename>");
	}

	new String:Arguments[PLATFORM_MAX_PATH + 65];
	GetCmdArgString(Arguments, sizeof(Arguments));

 	decl String:Arg[65];
	new len = BreakString(Arguments, Arg, sizeof(Arg));

	/* Make sure it does not go out of bound by doing "sm_play user  "*/
	if (len == -1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_play <#userid|name> <filename>");
		return Plugin_Handled;
	}

	/* Incase they put quotes and white spaces after the quotes */
	if (Arguments[len] == '"')
	{
		len++;
		new FileLen = TrimString(Arguments[len]) + len;

		if (Arguments[FileLen - 1] == '"')
		{
			Arguments[FileLen - 1] = '\0';
		}
	}
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			Arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		ClientCommand(target_list[i], "playgamesound \"%s\"", Arguments[len]);
		LogAction(client, target_list[i], "\"%L\" played sound on \"%L\" (file \"%s\")", client, target_list[i], Arguments[len]);	
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Played sound to target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Played sound to target", "_s", target_name);
	}

	return Plugin_Handled;
}
