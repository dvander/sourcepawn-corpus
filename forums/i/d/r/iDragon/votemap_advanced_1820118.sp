#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define ACCESS_FLAG ADMFLAG_KICK

// The plugin name that will appear in chat:
#define MODNAME "A-VoteMap"
#define PLUGIN_VERSION "1.6"
// The symbol to use 'prefixed' to the map name during the vote:
#define VOTEMAP_SYMBOL '#'
// Max maps number in the list:
#define MAX_MAPS 10000

// Plugin's cvar handles.
new Handle:g_hPluginVersion = INVALID_HANDLE;
new Handle:g_CvarEnabled = INVALID_HANDLE;
new Handle:g_CvarMapListFrom = INVALID_HANDLE;
new Handle:g_CvarFilter = INVALID_HANDLE;
new Handle:g_CvarFilterType = INVALID_HANDLE;
new Handle:g_CvarTimeToType = INVALID_HANDLE;

// Variables...
new bool:g_AllowMapTyping = false;
new g_PlayerMap[MAXPLAYERS+2];
new g_PlayerList[5] = {-1, ...};
new g_PlayerCount = 0;
new Handle:g_GenerateMapTimer = INVALID_HANDLE;

// Map list settings ...
new bool:isMapListGenerated = false;
new Handle:g_MapListMenu = INVALID_HANDLE;
new g_MapCount;
new String:g_Maps[MAX_MAPS][64];

public Plugin:myinfo =
{
	name = "Vote-Map-Advanced",
	author = "iDragon",
	description = "Adds an admin command to create a vote with maps players choose and then changing to the winning map.",
	version = PLUGIN_VERSION,
    url = " "
};

public OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_votemap_advanced_enable", "1", "Enable or disable votemap-advanced: 0 - Disable, 1 - Enable.");
	g_CvarMapListFrom = CreateConVar("sm_votemap_advanced_maps_from", "0", "Generate maplist from: 0 - maps dir, 1 - mapcycle.txt");
	g_CvarFilter = CreateConVar("sm_votemap_advanced_filter", "4", "Vote filter settings: 0 - Allow only fun maps (any map except de_/cs_ maps), 1 - Only mix maps (include cs_maps), 2 - Only de_ maps, 3 - Only aim maps ,4 - Any map, 5 - Custom map type.");
	g_CvarFilterType = CreateConVar("sm_votemap_advanced_filter_type", "jb_", "If <sm_votemap_advanced_filter> set to 5, then allow only maps that starts with this combination of words.");
	g_CvarTimeToType = CreateConVar("sm_votemap_advanced_time_to_type", "32.0", "The amount of time players could time their map, until the maps vote starts.. (Time must be at least 5.0 seconds!)");
	
	g_hPluginVersion = CreateConVar("sm_votemap_advanced_version", PLUGIN_VERSION, "Votemap Advanced Plugin version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(g_hPluginVersion, PLUGIN_VERSION);
	
	AutoExecConfig(true, "sm_votemap_advanced");
	HookConVarChange(g_hPluginVersion, VersionHasBeenChanged);
		
	RegAdminCmd("sm_vm",
		Command_VoteMap,
		ACCESS_FLAG,
		"Start the vote-map.");
		
	RegAdminCmd("sm_avotemap",
		Command_VoteMap,
		ACCESS_FLAG,
		"Start the vote-map.");
		
	RegAdminCmd("sm_vt",
		Command_VoteMap,
		ACCESS_FLAG,
		"Start the vote-map.");
		
	RegConsoleCmd("sm_vmlist",
		Command_ShowMapList,
		"Show the maplist.");
		
	RegConsoleCmd("say",
		Command_SayChat,
		"Register the chat command");
		
	RegConsoleCmd("say_team",
		Command_SayChat,
		"Register the chat command");

	g_AllowMapTyping = false;
	isMapListGenerated = false;
	g_MapCount = 0;
	CreateMapList();
}

public VersionHasBeenChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public Action:Command_ShowMapList(client, args)
{
	if (GetConVarInt(g_CvarEnabled) == 0)
		return Plugin_Continue;

	if ((client != 0) && IsClientInGame(client))
	{
		if (isMapListGenerated) // Is map list already been generated?
			DisplayMenu(g_MapListMenu, client, 30);
		else // The maplist hasn't been generated yet ... Lets create it now and infrom the player.
		{
			PrintToChatAll("\x04[%s]:\x03 Map list is about to be generated! the server may lag for a few seconds!", MODNAME);
			CreateMapList();
			PrintToChat(client, "\x04[%s]:\x03 Map list is being created right now! please use\x01 sm_vtlist\x03 command again in a few seconds...", MODNAME);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_VoteMap(client, args)
{
	if (GetConVarInt(g_CvarEnabled) == 0)
		return Plugin_Continue;
	
	if (IsVoteInProgress())
	{
		PrintToChat(client, "\x04[%s]: \x03Can not start the vote yet... please try again in a few seconds.", MODNAME);
		return Plugin_Handled;
	}
	
	g_AllowMapTyping = false;
	
	new Handle:chooseVote = CreateMenu(Handle_VoteMenu);

	SetMenuTitle(chooseVote, "Change map?");
	AddMenuItem(chooseVote, "yes", "Yes");
	AddMenuItem(chooseVote, "no", "No");
	SetMenuExitButton(chooseVote, false);
	VoteMenuToAll(chooseVote, 30);
	PrintToChatAll("\x04[%s]:\x03 Change map?", MODNAME);
				
	return Plugin_Handled;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_VoteEnd)
	{
		if (param1 == 0)
		{
			new Handle:mapsInChat = CreatePanel();
			SetPanelTitle(mapsInChat, "Vote map");
			DrawPanelItem(mapsInChat, "", ITEMDRAW_SPACER);
			DrawPanelText(mapsInChat, "Type in chat 5 maps! \nExample: #mapName");
			DrawPanelItem(mapsInChat, "", ITEMDRAW_SPACER);
			SetPanelCurrentKey(mapsInChat, 10);
			DrawPanelItem(mapsInChat, "Close", ITEMDRAW_CONTROL);
			
			new maxClients = GetMaxClients();
			// Send panel and reset players maps.
			for (new i = 0; i <= maxClients; i++)
			{
				g_PlayerMap[i] = -1;
				if (i < 5)
					g_PlayerList[i] = -1;
					
				if (i == 0)
					continue;

				if ((i > 0) && IsClientInGame(i) && !IsFakeClient(i))
					SendPanelToClient(mapsInChat, i, Handler_DoNothing, 30);
			}
			g_PlayerCount = 0;
			
			// Allow typing in chat ...
			g_AllowMapTyping = true;
			
			PrintCenterTextAll("Type in chat 5 maps");
			PrintToChatAll("\x04[%s]:\x03 Type in chat 5 maps!", MODNAME);
			PrintToChatAll("\x04[%s]:\x03 Example:\x01 #mapName", MODNAME);
			
			new Float:time = GetConVarFloat(g_CvarTimeToType);
			if (time < 5.0)
				time = 32.0;
			g_GenerateMapTimer = CreateTimer(time, GenerateMapVote);
		}
	}
}

public Action:Command_SayChat(client, args)
{
	decl String:text[192];
	if (IsChatTrigger() || GetCmdArgString(text, sizeof(text)) < 1)
		return Plugin_Continue;
	
	new msgStart = 1;
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (g_AllowMapTyping)
	{
		if (text[startidx] == VOTEMAP_SYMBOL)
		{
			decl String:messagee[192];
			strcopy(messagee, 192, text[startidx+msgStart]);
			if (messagee[0] == ' ')
				strcopy(messagee, 192, messagee[1]);

			new pos = CheckIfMapExist(messagee);
			
			if (pos != -1) // If the map is -1, then don't continue.
			{
				decl String:mapName2[33];
				GetCurrentMap(mapName2, sizeof(mapName2));
				if (StrEqual(mapName2, g_Maps[pos], false))
				{
					PrintToChat(client, "\x04[%s]:\x03 You can't choose the current map!", MODNAME);
					return Plugin_Handled;
				}
				
				for (new index = 0; index < 5; index++)
				{
					if (client == g_PlayerList[index])
					{
						PrintToChat(client, "\x04[%s]:\x03 Your first map will be in the vote.", MODNAME);
						PrintToChat(client, "\x04[%s]:\x03 Your first map:\x01 %s", MODNAME, g_Maps[g_PlayerMap[client]]);
						return Plugin_Handled;
					}
					
					if (g_PlayerList[index] < 0)
						continue;
						
					if (g_PlayerMap[g_PlayerList[index]] == pos)
					{
						PrintToChat(client, "\x04[%s]:\x03 This map is already in the vote! you may try another map.", MODNAME);
						return Plugin_Handled;
					}
				}
				g_PlayerMap[client] = pos;
				if (g_PlayerCount < 5)
				{
					g_PlayerList[g_PlayerCount] = client;
					g_PlayerCount++;
					PrintToChat(client, "\x04[%s]:\x03Your map number:\x01 %d", MODNAME, g_PlayerCount);
					PrintToChat(client, "\x04[%s]:\x03 Your map:\x01 %s", MODNAME, g_Maps[g_PlayerMap[client]]);
				}
				
				if (g_PlayerCount == 5)
				{
					g_PlayerCount++; // Stop getting players maps!
					
					if (g_GenerateMapTimer != INVALID_HANDLE)
						CloseHandle(g_GenerateMapTimer);
					
					PrintToChatAll("\x04[%s]:\x03 Creating the vote! please wait...", MODNAME);
					PrintToChatAll("\x04[%s]:\x03 Creating the vote! please wait...", MODNAME);
					PrintToChatAll("\x04[%s]:\x03 Creating the vote! please wait...", MODNAME);
					PrintToChatAll("\x04[%s]:\x03 Creating the vote! please wait...", MODNAME);
					g_GenerateMapTimer = CreateTimer(3.0, GenerateMapVote);
					
					return Plugin_Handled;
				}
				
				return Plugin_Handled;
			}
			else
				PrintToChat(client, "\x04[%s]:\x03 Your map %s couldn't be found in the map list!", messagee);
		}
	}
	return Plugin_Continue;
}

public Action:GenerateMapVote(Handle:timer)
{
	g_AllowMapTyping = false;
	
	new found = 0;
	new Handle:chooseVoteMap = CreateMenu(Handle_VoteFinalMenu);
	SetVoteResultCallback(chooseVoteMap, Handle_VoteResults);
	SetMenuTitle(chooseVoteMap, "Choose map: \n");
	
	for (new i=0; i<5; i++)
	{
		if (g_PlayerList[i] == -1)
			continue;
		if (g_PlayerMap[g_PlayerList[i]] == -1)
			continue;
			
		AddMenuItem(chooseVoteMap, g_Maps[g_PlayerMap[g_PlayerList[i]]], g_Maps[g_PlayerMap[g_PlayerList[i]]]);
		found++;
	}

	// Until now there weren't 5 maps in the vote! lets random the last ones...
	new bool:exist[g_MapCount];
	new rnd;
	while (found < 5)
	{
		rnd = GetRandomMapNum(g_MapCount, false);
		if (!exist[rnd])
		{
			exist[rnd] = true;
			AddMenuItem(chooseVoteMap, g_Maps[rnd], g_Maps[rnd]);
			found++;
		}
	}
	
	SetMenuExitButton(chooseVoteMap, false);
	VoteMenuToAll(chooseVoteMap, 30);
	
	if (g_GenerateMapTimer != INVALID_HANDLE)
		CloseHandle(g_GenerateMapTimer);
}

GetRandomMapNum(count, bool:anyMap)
{
	if (anyMap) // if anyMap is true, then any map can be shown.
		return GetRandomInt(0, count);
	
	new arr[count], bool:found, lastPos=0;
	for (new i=0; i<count; i++)
	{
		found = false;
		for (new k=0; k<5; k++)
		{
			if (g_PlayerList[k] < 0)
				continue;
			if (g_PlayerMap[g_PlayerList[k]] == i)
				found = true;
		}
		if (!found)
		{
			arr[lastPos] = i;
			lastPos++;
		}
	}
	
	return arr[GetRandomInt(0, lastPos-1)];
}

public Handle_VoteFinalMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
}

public Handle_VoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	new winner = 0;
	if ((num_items > 1) && (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES]))
		winner = GetRandomInt(0, 1);
 
	new String:map[64];
	GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], map, sizeof(map));
	PrintToChatAll("\x04[%s]:\x03 Changing map to:\x01 %s\x03 in \x045 \x03seconds!", MODNAME, map);
	new Handle:pack;
	CreateDataTimer(5.0, ChangeMap, pack);
	WritePackString(pack, map);
}

public Action:ChangeMap(Handle:timer, Handle:pack)
{
	decl String:map[128];
	ResetPack(pack);
	ReadPackString(pack, map, sizeof(map));
	
	ServerCommand("changelevel %s", map);
}

public OnMapStart()
{
	if (g_GenerateMapTimer != INVALID_HANDLE)
	{
		KillTimer(g_GenerateMapTimer);
		CloseHandle(g_GenerateMapTimer);
	}
	
	g_AllowMapTyping = false;
	g_MapCount = 0;
	isMapListGenerated = false;
	new maxClients = GetMaxClients();
	for (new i=0; i<=maxClients; i++)
	{
		g_PlayerMap[i] = -1;
			
		if (i < 5)
			g_PlayerList[i] = -1;
	}
	CreateMapList();
}

CreateMapList()
{
	if (!isMapListGenerated) // Map list will be generated now!
	{
		decl String:mapName[64];
		decl FileType:type;
		new nameLen;
		
		if (g_MapListMenu != INVALID_HANDLE)
			CloseHandle(g_MapListMenu);

		g_MapListMenu = CreateMenu(MapListMenuHandler);
		SetMenuTitle(g_MapListMenu, "%s: Map List", MODNAME);
		
		switch (GetConVarInt(g_CvarMapListFrom)) // Read from: 0 = Maps dir, 1 = mapcycle.txt
		{
			case 0:
			{
				new Handle:mapsDir = OpenDirectory("maps/");
				new filter = GetConVarInt(g_CvarFilter);
				if ((filter > 5) || (filter < 0))
					filter = 4;
					
				decl String:customType[15];
				GetConVarString(g_CvarFilterType, customType, sizeof(customType));
					
				while (ReadDirEntry(mapsDir, mapName, sizeof(mapName), type))
				{
					if (type == FileType_File)
					{
						nameLen = strlen(mapName) - 4;
						if (StrContains(mapName,".bsp",false) == nameLen)
						{
							if (((filter == 0) && ((StrContains(mapName, "de_") != 0) && (StrContains(mapName, "cs_") != 0)))
								|| ((filter == 1) && ((StrContains(mapName, "de_") == 0) || (StrContains(mapName, "cs_") == 0)))
									|| ((filter == 2) && (StrContains(mapName, "de_") == 0))
										|| ((filter == 3) && (StrContains(mapName, "aim_") == 0))
											|| (filter == 4)
												|| ((filter == 5) && (StrContains(mapName, customType) == 0)))
							{
								strcopy(mapName, (nameLen + 1), mapName);
								AddMenuItem(g_MapListMenu, mapName, mapName);
										
								if (g_MapCount < MAX_MAPS)
								{
									g_Maps[g_MapCount] = mapName;
									g_MapCount++;
								}
							}
						}
					}
				}
				CloseHandle(mapsDir);
			}
			case 1:
			{
				new Handle:mapsFile = OpenFile("mapcycle.txt","r");
				new filter = GetConVarInt(g_CvarFilter);
				if ((filter > 5) || (filter < 0))
					filter = 4;
					
				decl String:customType[15];
				GetConVarString(g_CvarFilterType, customType, sizeof(customType));
					
				while (ReadFileLine(mapsFile, mapName, sizeof(mapName)))
				{
				/*	if (((filter == 0) && ((StrContains(mapName, "de_") == -1) && (StrContains(mapName, "cs_") == -1)))
						|| ((filter == 1) && ((StrContains(mapName, "de_") != -1) || (StrContains(mapName, "cs_") != -1)))
							|| ((filter == 2) && (StrContains(mapName, "de_") != -1))
								|| ((filter == 3) && (StrContains(mapName, "aim_") != -1))
									|| (filter == 4)) */
					if (((filter == 0) && ((StrContains(mapName, "de_") != 0) && (StrContains(mapName, "cs_") != 0)))
								|| ((filter == 1) && ((StrContains(mapName, "de_") == 0) || (StrContains(mapName, "cs_") == 0)))
									|| ((filter == 2) && (StrContains(mapName, "de_") == 0))
										|| ((filter == 3) && (StrContains(mapName, "aim_") == 0))
											|| (filter == 4)
												|| ((filter == 5) && (StrContains(mapName, customType) == 0)))
					{
						AddMenuItem(g_MapListMenu, mapName, mapName);
						
						if (g_MapCount < MAX_MAPS)
						{
							g_Maps[g_MapCount] = mapName;
							g_MapCount++;
						}
					}
				}
				CloseHandle(mapsFile);
			}
		}
	
		SetMenuExitButton(g_MapListMenu, true);
		
		isMapListGenerated = true;
	}
}

public MapListMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:map[64];
		new bool:worked = GetMenuItem(menu, param2, map, sizeof(map));
		if (worked) // The map name has been found in the menu - Will change the map.
			PrintToChat(param1, "\x04[%s]:\x03 Map name:\x01 %s", MODNAME, map);
	}
}

CheckIfMapExist(const String:map[])
{
	// Loop through all the maps in the Arr, and return I when found, else -1.
	new found = -1;
	for (new i=0; i<g_MapCount; i++)
	{
		if (StrEqual(g_Maps[i], map, false))
			return i;
			
		if (StrContains(g_Maps[i], map) != -1)
			found = i;
	}
	
	return found;
}
