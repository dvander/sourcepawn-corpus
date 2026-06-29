/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <serverredirect>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.1"
#define LIB_REDIR "serverredir"

new bool:g_isRedirLibLoaded;			// whether the redirect library has been loaded

public Plugin:myinfo = 
{
	name = "Server Redirect Commands",
	author = "Brainstorm",
	description = "Addition server redirect commands. Used to showcase the native functions provided by the server redirect plugin.",
	version = PLUGIN_VERSION,
	url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_redirect_show", Command_ShowMenu, ADMFLAG_SLAY, "sm_redirect_show <#userid|name> - Shows the redirect menu to a player");
	RegAdminCmd("sm_redirect_list", Command_List, ADMFLAG_SLAY, "sm_redirect_list - Displays a list of servers available for redirection.");
	g_isRedirLibLoaded = LibraryExists(LIB_REDIR);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, LIB_REDIR))
	{
		g_isRedirLibLoaded = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, LIB_REDIR))
	{
		g_isRedirLibLoaded = true;
	}
}

public Action:Command_ShowMenu(client, args)
{
	if (!g_isRedirLibLoaded)
	{
		ReplyToCommand(client, "Server redirect plugin not loaded, unable to perform this function. Please check your server configuration.");
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_redirect_show <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:arguments[256];
	GetCmdArgString(arguments, sizeof(arguments));

	decl String:arg[65];
	new len = BreakString(arguments, arg, sizeof(arg));
	
	if (len == -1)
	{
		len = 0;
		arguments[0] = '\0';
	}

	decl String:targetName[MAX_TARGET_LENGTH];
	decl targetList[MAXPLAYERS], targetCount, bool:tn_is_ml;
	
	targetCount = ProcessTargetString(arg, client, targetList, MAXPLAYERS, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);
	
	for (new i = 0; i < targetCount; i++)
	{
		ShowServerRedirectMenu(targetList[i]);
	}
	
	return Plugin_Handled;
}

public Action:Command_List(client, args)
{
	if (!g_isRedirLibLoaded)
	{
		ReplyToCommand(client, "Server redirect plugin not loaded, unable to perform this function. Please check your server configuration.");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Attempting to load server list...");
	LoadServerRedirectListFiltered(true, true, RedirListLoaded, client);
	return Plugin_Handled;
}

public RedirListLoaded(serverCount, const String:error[], Handle:serverList, any:client)
{
	if (serverCount < 0)
	{
		ReplyToCommand(client, "Failed to load server list due to error: %s", error);
	}
	else if (serverCount == 0)
	{
		ReplyToCommand(client, "No redirect servers found.");
	}
	else
	{
		ReplyToCommand(client, "%d servers found, listing them:", serverCount);
		
		decl String:address[50];
		decl String:display_name[255];
		decl String:offline_name[100];
		decl String:map[64];
		new maxPlayers;
		new currPlayers;
		new timeDiff;
		new bool:isOnline;
		
		KvRewind(serverList);
		KvGotoFirstSubKey(serverList);
		
		do
		{
			KvGetSectionName(serverList, address, sizeof(address));
			KvGetString(serverList, "display_name", display_name, sizeof(display_name));
			KvGetString(serverList, "offline_name", offline_name, sizeof(offline_name));
			maxPlayers = KvGetNum(serverList, "maxplayers");
			currPlayers = KvGetNum(serverList, "currentplayers");
			timeDiff = KvGetNum(serverList, "update_sec");
			KvGetString(serverList, "map", map, sizeof(map));
			isOnline = bool:KvGetNum(serverList, "isonline", 0);
			
			ReplyToCommand(client, "%2d   %30s   %2d/%2d   %10d   %30s   %s", isOnline, address, currPlayers, maxPlayers, timeDiff, map, display_name);
		}
		while (KvGotoNextKey(serverList));
		
		ReplyToCommand(client, "Server list completed.");
	}
	
	// close key values handle
	if (serverList != INVALID_HANDLE)
	{
		CloseHandle(serverList);
	}
}
