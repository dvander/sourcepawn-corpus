/* [ANY] Map History
 *
 *  Copyright (C) 2017 Michael Flaherty // michaelwflaherty.com // michaelwflaherty@me.com
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>

ConVar displayAmount;

public Plugin myinfo =
{
	name = "[ANY] Map History",
	author = "Headline",
	description = "A menu interface to view map history",
	version = "1.0",
	url = "http://michaelwflaherty.com"
};

public void OnPluginStart()
{
	displayAmount = CreateConVar("maphistory_display_amount", "5", "Change the display amount for sm_maphistory (default 5)");
	
	RegConsoleCmd("sm_maphist", Command_MapHistory, "Opens a menu to display map history");
	RegConsoleCmd("sm_maps", Command_MapHistory, "Opens a menu to display map history");
}

public Action Command_MapHistory(int client, int args)
{
	if (!IsValidClient(client))
	{
		PrintToChat(client, "[SM] You must be in game to use this command!");
		return Plugin_Handled;
	}
	if (args != 0)
	{
		PrintToChat(client, "[SM] Usage: sm_maphistory");
		return Plugin_Handled;
	}
	
	OpenMapHistoryMenu(client);
	return Plugin_Handled;
}

// DESCRIPTION: Creates and sends map history menu using SourceMod's GetMapHistory()
void OpenMapHistoryMenu(int client)
{
	Menu menu = new Menu(Menu_Callback, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	menu.SetTitle("Map History: ");
	
	AddCurrentMapToMenu(menu, "", ITEMDRAW_DISABLED);
	for (int i = 0; i < GetMapHistorySize() && i < displayAmount.IntValue; i++)
	{
		AddMapHistoryMapToMenu(menu, i);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

void AddMapHistoryMapToMenu(Menu menu, int index)
{
	char mapName[64], reason[64], intValue[8];
	int startTime;

	IntToString(index, intValue, sizeof(intValue));
	GetMapHistory(index, mapName, sizeof(mapName), reason, sizeof(reason), startTime);
	menu.AddItem(intValue, mapName);
}

void AddCurrentMapToMenu(Menu menu, const char[] info, int flags)
{
	char displayBuffer[128];
	char currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	Format(displayBuffer, sizeof(displayBuffer), "%s (Current Map)", currentMap);
	menu.AddItem(info, displayBuffer, flags);
}

public int Menu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (!IsValidClient(param1))
	{
		return;
	}
	
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			int index;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			index = StringToInt(sInfo);
			
			OpenMapSelectionMenu(param1, index);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

void OpenMapSelectionMenu(int client, int index)
{
	Menu menu = new Menu(VoidMenu_Callback, MenuAction_Display|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	menu.SetTitle("Map History: ");
	
	char displayBuffer[128], mapName[64], reason[64];
	int startTime;
	
	GetMapHistory(index, mapName, sizeof(mapName), reason, sizeof(reason), startTime);
	
	char formattedTime[128];
	FormatTime(formattedTime, sizeof(formattedTime), "%I:%M %p", startTime);

	
	Format(displayBuffer, sizeof(displayBuffer), "Map Name: %s", mapName);
	menu.AddItem("", displayBuffer, ITEMDRAW_DISABLED);
	
	Format(displayBuffer, sizeof(displayBuffer), "Reason: %s", reason);
	menu.AddItem("", displayBuffer, ITEMDRAW_DISABLED);
	
	Format(displayBuffer, sizeof(displayBuffer), "Start Time: %s", formattedTime);
	menu.AddItem("", displayBuffer, ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int VoidMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (!IsValidClient(param1))
	{
		return;
	}
	
	switch (action)
	{
		case MenuAction_Select:
		{
			// do nothing
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			OpenMapHistoryMenu(param1);
		}
	}
	return;
}

bool IsValidClient(client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}