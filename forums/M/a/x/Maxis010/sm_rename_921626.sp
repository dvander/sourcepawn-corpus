/**
 * =============================================================================
 * SourceMod Communication Plugin Extension
 * Provides fucntionality for controlling communication on the server
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * and <eVa>StrontiumDog http://www.theville.org
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 1
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
 */

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.6.000"

new gametype

new String:GameName[64]
new String:g_OriginalName[MAXPLAYERS+1][64]
new String:g_SetName[MAXPLAYERS+1][64]

new Handle:g_Hostname = INVALID_HANDLE
new Handle:hAdminMenu = INVALID_HANDLE
new Handle:g_Timer[MAXPLAYERS+1]
new Handle:hDatabase = INVALID_HANDLE

new g_Name[MAXPLAYERS+1]

static const String:name_list[][] = {"I'm a Little Teacup", "Fluffy Bunny Feet", "Cutey Pie", "StudMuffin", "My Little Pony", "Cuddles",  
 "I Love My Mouse", "I Need a Better Name",  "I love you guys", "I want to be a supportive player", "Team work rules", "Not a Whiner",
 "I blame Gator", "My brain has gone to mush", "Cabbages Rule", "The Gene Pool Needs Chlorine", "You're Crazy, Man",
 "I'm Outta Control", "What?", "The Bath Thinker", "Cheesylicious", "Mascara", "Banana", "Witchcraft", "Watch the Demo",
 "Uh-oh", "Poodle Pumpkin", "Paris Hilton is my hero", "Epic FacePalm", "Chucklehead", "Respect", "VALVe are cool", "I sinned. I'm sorry",
 "Gabe Newell is Sexy", "ShamWow Guy is awesome", "Look at me - I need attention", "Help me", "I have issues", "You guys rock",
 "LuluLemon Guy", "Not a Normal Human Being", "Twelve years old", "My mom taught me to cuss", "Why do I have to be so annoying?",
 "Gabe Newells BFF", "Just immature", "Gosh darn it", "I surrender", "Zero ePeen", "Failz", "Epic failz", "Not l337",
 "I suck at CSS", "Not smart", "So Unsexy", "Didnt think - sorry", "Got no brain", "Chicken", "No hope"
 }

public Plugin:myinfo = 
{
	name = "Player Rename",
	author = "<eVa>Dog",
	description = "Change the name of a player",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_rename_version", PLUGIN_VERSION, "ReName Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_pname", Command_PermReName, ADMFLAG_CHAT, "sm_pname <#userid|name> <name>")
	
	LoadTranslations("common.phrases")

	g_Hostname = FindConVar("hostname")
	
	GetGameFolderName(GameName, sizeof(GameName))
	
	if (StrEqual(GameName, "dod") || StrEqual(GameName, "zps") || StrEqual(GameName, "tf") || StrEqual(GameName, "ageofchivalry"))
	{
		gametype = 1
		PrintToServer("Game type 1 %s identified", GameName)
	}
	else 
	{
		gametype = 0
		PrintToServer("Game type 0 %s identified", GameName)
	}
	
	SQL_TConnect(DBConnect, "commsdb")
		
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error)
		PrintToServer("Rename - Unable to connect to database")
		return
	}
	
	hDatabase = hndl
	PrintToServer("Rename - Connected Successfully to Database")
	LogAction(0, 0, "Rename - Connected Successfully to Database")
}

public OnClientPostAdminCheck(client)
{
	g_Name[client] = 0
	g_Timer[client] = INVALID_HANDLE
	
	new String:auth[64], String:query[1024]
	GetClientAuthString(client, auth, sizeof(auth))
	
	Format(query, sizeof(query), "SELECT * FROM renameplayer WHERE steam_id REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", auth[8])
	
	if (!IsFakeClient(client))
		SQL_TQuery(hDatabase, CheckPlayer, query, client, DBPrio_High)	
}

public CheckPlayer(Handle:owner, Handle:hQuery, const String:error[], any:client)
{
	if(hQuery != INVALID_HANDLE)
	{
		if(SQL_GetRowCount(hQuery) > 0)
		{
			PrintToServer("[Rename] Client %N found in Database", client)
			LogAction(0, client, "[Rename] Client %N found in Database", client)
			while(SQL_FetchRow(hQuery))
			{
				g_Name[client] = SQL_FetchInt(hQuery, 2)
			}
		}
		CloseHandle(hQuery)
		
		if (g_Name[client] == 1 && g_Timer[client] == INVALID_HANDLE)
		{
			SetName(client)
		}
	}
	else
	{
		LogToGame("[SM] Query failed! %s", error);
	}
}

SetName(target)
{
	new String:name[64]
	
	Format(g_OriginalName[target], 64, "%N", target)
		
	Format(name, sizeof(name), "%s", name_list[target])
	Format(g_SetName[target], 64, "%s", name_list[target])
		
	g_Timer[target] = CreateTimer(0.2, CheckName, target, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
		
	if (gametype == 0)
	{
		ClientCommand(target, "name \"%s\"", name)
	}
	else
	{
		SetClientInfo(target, "name", name)
	}
	
	LogAction(0, target, "Permanently renamed \"%L\"", target)
}

public AddToDatabase(Handle:owner, Handle:hQuery, const String:error[], any:client)
{
	if (hQuery == INVALID_HANDLE)
	{
		LogToGame("[Rename] There was an error writing to the Database, %s",error)
		PrintToServer("[Rename] There was an error writing to the Database")
		
		return
	}
	else
	{
		CloseHandle(hQuery)
	}
}

public Action:Command_PermReName(client, args)
{
	decl String:target[65]
	decl String:name[64]
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS]
	decl target_count
	decl bool:tn_is_ml
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_pname <#userid|name> <name>");
		return Plugin_Handled
	}
	
	GetCmdArg(1, target, sizeof(target))
	GetCmdArg(2, name, sizeof(name))
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
		
	for (new i = 0; i < target_count; i++)
	{
		if (IsClientInGame(target_list[i]))
		{			
			PerformNameChangePerm(client, target_list[i], name)
		}
	}
	return Plugin_Handled
}

PerformNameChangePerm(client, target, String:chosenname[64])
{
	new String:name[64]
	new String:query[1024], String:authid[64]
	GetClientAuthString(target, authid, sizeof(authid))
	
	new thetime = GetTime()
	new String:hostname[128]
	GetConVarString(g_Hostname, hostname, sizeof(hostname))
	ReplaceString(hostname, sizeof(hostname), "'", "")
	
	if (g_Name[target] == 0 && g_Timer[target] == INVALID_HANDLE)
	{
		Format(g_OriginalName[target], 64, "%N", target)
		
		if (StrEqual(chosenname, "PRESET", true))
		{
			Format(name, sizeof(name), "%s", name_list[target])
			Format(g_SetName[target], 64, "%s", name_list[target])
		}
		else
		{
			Format(name, sizeof(name), "%s", chosenname)
			Format(g_SetName[target], 64, "%s", chosenname)
		}
				
		g_Name[target] = 1
		g_Timer[target] = CreateTimer(0.2, CheckName, target, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
		
		new String:clientname[128], String:targetname[128]
		Format(clientname, sizeof(clientname), "%N", client)
		ReplaceString(clientname, sizeof(clientname), "'", "")
		Format(targetname, sizeof(targetname), "%s", g_OriginalName[target])
		ReplaceString(targetname, sizeof(targetname), "'", "")
			
		Format(query, sizeof(query), "INSERT INTO renameplayer (steam_id, originalname, name, hostname, thetime, game, admin) VALUES('%s', '%s', 1, '%s', '%i', '%s', '%s') ON DUPLICATE KEY UPDATE name=1;", authid, targetname, hostname, thetime, GameName, clientname)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_Low)
		
		LogAction(client, target, "\"%L\" permanently changed %N's name to %s", client, target, name)
		ShowActivity(client, "permanently changed %N's name", target) 
	}
	else
	{
		Format(name, 64, "%s", g_OriginalName[target])
				
		g_Name[target] = 0
		KillCheckName(target)
		
		Format(query, sizeof(query), "INSERT INTO renameplayer (steam_id, name) VALUES('%s', 0) ON DUPLICATE KEY UPDATE name=0;", authid)
		
		PrintToServer("Query: %s", query)
		SQL_TQuery(hDatabase, AddToDatabase, query, client, DBPrio_High)
		
		LogAction(client, target, "\"%L\" restored %N's name to %s", client, target, name)
		ShowActivity(client, "restored %N's name", target) 
	}
	
	if (gametype == 0)
	{
		ClientCommand(target, "name \"%s\"", name)
	}
	else
	{
		SetClientInfo(target, "name", name)
	}
}

public Action:CheckName(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || g_Name[client] == 0)
	{
		KillCheckName(client)
		return Plugin_Handled
	}
	
	if (IsClientConnected(client) && g_Name[client] == 1)
	{	
		new String:ClientName[64]
		GetClientName(client, ClientName, sizeof(ClientName))
		
		PrintToServer("%s, %s", ClientName, g_SetName[client])
		
		if (StrEqual(ClientName, g_SetName[client]) == false)
		{
			if (gametype == 0)
			{
				ClientCommand(client, "name \"%s\"", g_SetName[client])
			}
			else
			{
				SetClientInfo(client, "name", g_SetName[client])
			}
		}
	}
	return Plugin_Handled
}

KillCheckName(client)
{
	KillTimer(g_Timer[client])
	g_Timer[client] = INVALID_HANDLE
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_pname",
			TopMenuObject_Item,
			AdminMenu_Rename, 
			player_commands,
			"sm_pname",
			ADMFLAG_SLAY)
	}
}
 
public AdminMenu_Rename( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Change/Restore player's name")
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param)
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players)
	
	new String:title[100]
	Format(title, sizeof(title), "Choose Player:")
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)
	
	AddTargetsToMenu(menu, client, true, true)
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		new String:info[64]
		new userid, target
		
		GetMenuItem(menu, param2, info, sizeof(info))
		userid = StringToInt(info)

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available")
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to target")
		}
		else
		{				
			if (g_Name[target] == 0)
				PerformNameChangePerm(param1, target, "PRESET")
			else
				PerformNameChangePerm(param1, target, "")

		}
	}
}


