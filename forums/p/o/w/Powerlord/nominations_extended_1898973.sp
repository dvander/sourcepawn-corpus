/**
 * vim: set ts=4 :
 * =============================================================================
 * Nominations Extended
 * Allows players to nominate maps for Mapchooser
 *
 * Nominations Extended (C)2012-2013 Powerlord (Ross Bemrose)
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
 * Version: $Id$
 */

#include <sourcemod>
#include <mapchooser>
#include "include/mapchooser_extended"

#pragma semicolon 1

#define MCE_VERSION "1.9.5"

/* Map name size bumped up to support longer map names */
#define MAP_NAME_LENGTH 65

public Plugin:myinfo =
{
	name = "Map Nominations Extended",
	author = "Powerlord and AlliedModders LLC",
	description = "Provides Map Nominations",
	version = MCE_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=156974"
};

new Handle:g_Cvar_ExcludeOld = INVALID_HANDLE;
new Handle:g_Cvar_ExcludeCurrent = INVALID_HANDLE;

new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_MapMenu = INVALID_HANDLE;
new g_mapFileSerial = -1;

#define MAPSTATUS_ENABLED (1<<0)
#define MAPSTATUS_DISABLED (1<<1)
#define MAPSTATUS_EXCLUDE_CURRENT (1<<2)
#define MAPSTATUS_EXCLUDE_PREVIOUS (1<<3)
#define MAPSTATUS_EXCLUDE_NOMINATED (1<<4)

new Handle:g_mapTrie;

// Nominations Extended Convars
new Handle:g_Cvar_MarkCustomMaps = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	LoadTranslations("basetriggers.phrases"); // for Next Map phrase
	LoadTranslations("mapchooser_extended.phrases");
	
	new arraySize = ByteCountToCells(MAP_NAME_LENGTH);	
	g_MapList = CreateArray(arraySize);
	
	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("sm_nominate", Command_Nominate);
	
	RegAdminCmd("sm_nominate_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_nominate_addmap <mapname> - Forces a map to be on the next mapvote.");
	
	// Nominations Extended cvars
	CreateConVar("ne_version", MCE_VERSION, "Nominations Extended Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);


	g_mapTrie = CreateTrie();
}

public OnAllPluginsLoaded()
{
	// This is an MCE cvar... this plugin requires MCE to be loaded.  Granted, this plugin SHOULD have an MCE dependency.
	g_Cvar_MarkCustomMaps = FindConVar("mce_markcustommaps");
}

public OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					g_mapFileSerial,
					"nominations",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== INVALID_HANDLE)
	{
		if (g_mapFileSerial == -1)
		{
			SetFailState("Unable to create a valid map list.");
		}
	}
	
	BuildMapMenu();
}

public OnNominationRemoved(const String:map[], owner)
{
	new status;
	
	/* Is the map in our list? */
	if (!GetTrieValue(g_mapTrie, map, status))
	{
		return;	
	}
	
	/* Was the map disabled due to being nominated */
	if ((status & MAPSTATUS_EXCLUDE_NOMINATED) != MAPSTATUS_EXCLUDE_NOMINATED)
	{
		return;
	}
	
	SetTrieValue(g_mapTrie, map, MAPSTATUS_ENABLED);	
}

public Action:Command_Addmap(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[NE] Usage: sm_nominate_addmap <mapname>");
		return Plugin_Handled;
	}
	
	decl String:mapname[MAP_NAME_LENGTH];
	GetCmdArg(1, mapname, sizeof(mapname));

	
	new status;
	if (!GetTrieValue(g_mapTrie, mapname, status))
	{
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
	}
	
	new NominateResult:result = NominateMap(mapname, true, 0);
	
	if (result > Nominate_Replaced)
	{
		/* We assume already in vote is the casue because the maplist does a Map Validity check and we forced, so it can't be full */
		ReplyToCommand(client, "%t", "Map Already In Vote", mapname);
		
		return Plugin_Handled;	
	}
	
	
	SetTrieValue(g_mapTrie, mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

	
	ReplyToCommand(client, "%t", "Map Inserted", mapname);
	LogAction(client, -1, "\"%L\" inserted map \"%s\".", client, mapname);

	return Plugin_Handled;		
}

public Action:Command_Say(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}

	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	if (strcmp(text[startidx], "nominate", false) == 0)
	{
		if (IsNominateAllowed(client))
		{
			AttemptNominate(client);
		}
	}
	
	SetCmdReplySource(old);
	
	return Plugin_Continue;	
}

public Action:Command_Nominate(client, args)
{
	if (!client || !IsNominateAllowed(client))
	{
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		AttemptNominate(client);
		return Plugin_Handled;
	}
	
	decl String:mapname[MAP_NAME_LENGTH];
	GetCmdArg(1, mapname, sizeof(mapname));
	
	new status;
	if (!GetTrieValue(g_mapTrie, mapname, status))
	{
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;		
	}
	
	if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
	{
		if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
		{
			ReplyToCommand(client, "[NE] %t", "Can't Nominate Current Map");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
		{
			ReplyToCommand(client, "[NE] %t", "Map in Exclude List");
		}
		
		if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			ReplyToCommand(client, "[NE] %t", "Map Already Nominated");
		}
		
		return Plugin_Handled;
	}
	
	new NominateResult:result = NominateMap(mapname, false, client);
	
	if (result > Nominate_Replaced)
	{
		if (result == Nominate_AlreadyInVote)
		{
			ReplyToCommand(client, "%t", "Map Already In Vote", mapname);
		}
		else
		{
			ReplyToCommand(client, "[NE] %t", "Map Already Nominated");
		}
		
		return Plugin_Handled;	
	}
	
	/* Map was nominated! - Disable the menu item and update the trie */
	
	SetTrieValue(g_mapTrie, mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);
	
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("[NE] %t", "Map Nominated", name, mapname);
	
	return Plugin_Continue;
}

AttemptNominate(client)
{
	SetMenuTitle(g_MapMenu, "%t", "Nominate Title", client);
	DisplayMenu(g_MapMenu, client, MENU_TIME_FOREVER);
	
	return;
}

BuildMapMenu()
{
	if (g_MapMenu != INVALID_HANDLE)
	{
		CloseHandle(g_MapMenu);
		g_MapMenu = INVALID_HANDLE;
	}
	
	ClearTrie(g_mapTrie);
	
	g_MapMenu = CreateMenu(Handler_MapSelectMenu, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);

	decl String:map[MAP_NAME_LENGTH];
	
	new Handle:excludeMaps = INVALID_HANDLE;
	decl String:currentMap[32];
	
	if (GetConVarBool(g_Cvar_ExcludeOld))
	{	
		excludeMaps = CreateArray(ByteCountToCells(MAP_NAME_LENGTH));
		GetExcludeMapList(excludeMaps);
	}
	
	if (GetConVarBool(g_Cvar_ExcludeCurrent))
	{
		GetCurrentMap(currentMap, sizeof(currentMap));
	}
	
		
	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{
		new status = MAPSTATUS_ENABLED;
		
		GetArrayString(g_MapList, i, map, sizeof(map));
		
		if (GetConVarBool(g_Cvar_ExcludeCurrent))
		{
			if (StrEqual(map, currentMap))
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_CURRENT;
			}
		}
		
		/* Dont bother with this check if the current map check passed */
		if (GetConVarBool(g_Cvar_ExcludeOld) && status == MAPSTATUS_ENABLED)
		{
			if (FindStringInArray(excludeMaps, map) != -1)
			{
				status = MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_PREVIOUS;
			}
		}
		
		AddMenuItem(g_MapMenu, map, map);
		SetTrieValue(g_mapTrie, map, status);
	}
	
	SetMenuExitButton(g_MapMenu, true);

	if (excludeMaps != INVALID_HANDLE)
	{
		CloseHandle(excludeMaps);
	}
}

public Handler_MapSelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:map[MAP_NAME_LENGTH], String:name[MAX_NAME_LENGTH];
			GetMenuItem(menu, param2, map, sizeof(map));		
			
			GetClientName(param1, name, MAX_NAME_LENGTH);
	
			new NominateResult:result = NominateMap(map, false, param1);
			
			/* Don't need to check for InvalidMap because the menu did that already */
			if (result == Nominate_AlreadyInVote)
			{
				PrintToChat(param1, "[NE] %t", "Map Already Nominated");
				return 0;
			}
			else if (result == Nominate_VoteFull)
			{
				PrintToChat(param1, "[NE] %t", "Max Nominations");
				return 0;
			}
			
			SetTrieValue(g_mapTrie, map, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

			if (result == Nominate_Replaced)
			{
				PrintToChatAll("[NE] %t", "Map Nomination Changed", name, map);
				return 0;	
			}
			
			PrintToChatAll("[NE] %t", "Map Nominated", name, map);
		}
		
		case MenuAction_DrawItem:
		{
			decl String:map[MAP_NAME_LENGTH];
			GetMenuItem(menu, param2, map, sizeof(map));
			
			new status;
			
			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return ITEMDRAW_DEFAULT;
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				return ITEMDRAW_DISABLED;	
			}
			
			return ITEMDRAW_DEFAULT;
						
		}
		
		case MenuAction_DisplayItem:
		{
			decl String:map[MAP_NAME_LENGTH];
			GetMenuItem(menu, param2, map, sizeof(map));
			
			new mark = GetConVarInt(g_Cvar_MarkCustomMaps);
			new bool:official;

			new status;
			
			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return 0;
			}
			
			decl String:buffer[100];
			decl String:display[150];
			
			if (mark)
			{
				official = IsMapOfficial(map);
			}
			
			if (mark && !official)
			{
				switch (mark)
				{
					case 1:
					{
						Format(buffer, sizeof(buffer), "%T", "Custom Marked", param1, map);
					}
					
					case 2:
					{
						Format(buffer, sizeof(buffer), "%T", "Custom", param1, map);
					}
				}
			}
			else
			{
				strcopy(buffer, sizeof(buffer), map);
			}
			
			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
				{
					Format(display, sizeof(display), "%s (%T)", buffer, "Current Map", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
				{
					Format(display, sizeof(display), "%s (%T)", buffer, "Recently Played", param1);
					return RedrawMenuItem(display);
				}
				
				if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
				{
					Format(display, sizeof(display), "%s (%T)", buffer, "Nominated", param1);
					return RedrawMenuItem(display);
				}
			}
			
			if (mark && !official)
				return RedrawMenuItem(buffer);
			
			return 0;
		}
	}
	
	return 0;
}

stock bool:IsNominateAllowed(client)
{
	new CanNominateResult:result = CanNominate();
	
	switch(result)
	{
		case CanNominate_No_VoteInProgress:
		{
			ReplyToCommand(client, "[ME] %t", "Nextmap Voting Started");
			return false;
		}
		
		case CanNominate_No_VoteComplete:
		{
			new String:map[MAP_NAME_LENGTH];
			GetNextMap(map, sizeof(map));
			ReplyToCommand(client, "[NE] %t", "Next Map", map);
			return false;
		}
		
		case CanNominate_No_VoteFull:
		{
			ReplyToCommand(client, "[ME] %t", "Max Nominations");
			return false;
		}
	}
	
	return true;
}