/**
 * rockthevote.sp
 * Provides RTV Map Voting
 *
 * Changelog:
 *
 * Version 1.4
 * - Abandoned Hungarian notation
 * - Stopped RTV from triggering when last player disconnects.
 * - Removed LANG_SERVER wherever possible.
 * - Added sm_rtv_minplayers cvar
 * - Added sm_rtv_nominate cvar
 * - Added sm_rtv_addmap command.
 * - Fixed crashes due to small mapcycles.
 * - New phrase: "Minimal Players Not Met"
 * - New phrase: "Map Inserted"
 * - New phrase: "Map Already in Vote"
 * - Added INS say2.
 *
 * Version 1.3.1 (July 2nd)
 * - Fixed german translation for new phrase, thanks Isias. 
 * - Fixed issue of rtv becoming permanently "started" 
 *
 * Version 1.3 (July 1st)
 * - Added new cvar, sm_rtv_maps. This lets you control the number of maps in the vote. It also acts as the nomination limit. See above. 
 * - RTV is now delayed by 30 seconds on map start. Players must wait that long until trying to start it (New phrase, get the translation file!) 
 * - Votes needed is now recalculated each time a player connects or disconnects, rather than the first time someone says "RTV". If someone disconnects, causing the votes to be higher than the needed value, RTV will begin. 
 * - RTV is now delayed 2 seconds after the needed votes are reached. I didn't like it immediately appearing, bugged me for some reason. 
 * - You can now use: bind key "say rtv" 
 *
 * Version 1.2 (June 20th)
 * - Fixed nominate command, you can now nominate until the vote is displayed. 
 * - Changed the RTVStarted phrase slightly. 
 *
 * Version 1.1 (June 29th)
 * - Added sm_rtv_file so that you can customize the map file without editing the plugin. 
 * - Conformed to plugin submission rules 
 * - Added version cvar sm_rockthevote_version 
 * - Bots excluded from "vote required" total. 
 *
 * Version 1.0
 * - German Translation 
 * - Added a check for number of nominations after user picks a map, in case multiple people tried to nominate at the same time. 
 * - Forgot to set g_bRTVEnded when it ended. 
 * - Visual fix for when player selects current map 
 *
 * Version 0.7
 * - Uh.. whoops. We now increment the votes when they are cast. 
 * - Close the menu on map end, so it's ready to be rebuilt next map. 
 * - Set g_bNominated when a player successfully nominates.. rofl. 
 * - I shouldn't code at work. 
 *
 * Version 0.6
 * - Fixed translation error in nomination handler 
 * - Fixed checking client 0 for "is in game"  
 *
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.4"

public Plugin:myinfo = 
{
	name = "RockTheVote",
	author = "ferret",
	description = "Provides RTV Map Voting",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MAXMAPS 128

new String:g_MapNames[MAXMAPS][32];
new g_MapCount = 0;
new g_NextMapsCount = 0;
new g_NextMaps[6];

new Handle:g_hMapMenu = INVALID_HANDLE;

new Handle:g_Cvar_Needed = INVALID_HANDLE;
new Handle:g_Cvar_File = INVALID_HANDLE;
new Handle:g_Cvar_Maps = INVALID_HANDLE;
new Handle:g_Cvar_Nominate = INVALID_HANDLE;
new Handle:g_Cvar_MinPlayers = INVALID_HANDLE;

new bool:g_CanRTV = false;
new bool:g_RTVAllowed = false;
new bool:g_RTVStarted = false;
new bool:g_RTVEnded = false;
new g_Voters = 0;
new g_Votes = 0;
new g_VotesNeeded = 0;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};
new bool:g_Nominated[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.rockthevote");
	
	CreateConVar("sm_rockthevote_version", PLUGIN_VERSION, "RockTheVote Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_File = CreateConVar("sm_rtv_file", "configs/maps.ini", "Map file to use. (Def configs/maps.ini)");
	g_Cvar_Maps = CreateConVar("sm_rtv_maps", "4", "Number of maps to be voted on. 1 to 6. (Def 4)", 0, true, 2.0, true, 6.0);
	g_Cvar_Nominate = CreateConVar("sm_rtv_nominate", "1", "Enables nomination system.", 0, true, 0.0, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, 64.0);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);	// INS
	RegConsoleCmd("say_team", Command_Say);
	
	RegAdminCmd("sm_rtv_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_rtv_addmap <mapname> - Forces a map to be on the RTV, and lowers the allowed nominations.");
}

public OnMapStart()
{
	g_NextMapsCount = 0;
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_RTVStarted = false;
	g_RTVEnded = false;
	
	decl String:MapListPath[256], String:MapListFile[64];
	GetConVarString(g_Cvar_File, MapListFile, 64);
	BuildPath(Path_SM, MapListPath, sizeof(MapListPath), MapListFile);
	if (!FileExists(MapListPath))
	{
		new Handle:hMapCycleFile = FindConVar("mapcyclefile");
		GetConVarString(hMapCycleFile, MapListPath, sizeof(MapListPath));
	}
	
	LogMessage("[RTV] Map Cycle Path: %s", MapListPath);
	
	if (LoadSettings(MapListPath))
	{
		BuildMapMenu();
		g_CanRTV = true;
		CreateTimer(30.0, Timer_DelayRTV);
	}
	else
	{
		LogMessage("[RTV] Cannot find map cycle file, RTV not active.");
		g_CanRTV = false;
	}
}

public OnMapEnd()
{
	CloseHandle(g_hMapMenu);
	g_hMapMenu = INVALID_HANDLE;
	g_RTVAllowed = false;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if(IsFakeClient(client))
		return true;
	
	g_Voted[client] = false;
	g_Nominated[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	
	return true;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	
	if (g_Votes >= g_VotesNeeded && g_RTVAllowed && g_Voters != 0) 
	{
		CreateTimer(2.0, Timer_StartRTV);
	}	
}

public Action:Command_Addmap(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rtv_addmap <mapname>");
		return Plugin_Handled;
	}
	
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	
	new map = -1;
	
	for (new i = 0; i < g_MapCount; i++)
	{
		if(strcmp(g_MapNames[i], mapname, false) == 0)
		{
			map = i;
			break;
		}		
	}

	if (map == -1)
	{
		ReplyToCommand(client, "%t", "Map was not found", map);
		return Plugin_Handled;
	}
	
	if (g_NextMapsCount > 0)
	{
		for (new i = 0; i < g_NextMapsCount; i++)
		{
			if (map == g_NextMaps[i])
			{
				ReplyToCommand(client, "%t", "Map Already In Vote", g_MapNames[map]);
				return Plugin_Handled;			
			}		
		}
		
		new start = (g_NextMapsCount == 6 ? 4 : g_NextMapsCount - 1);
		for (new i = start; i < 0; i--)
		{
			g_NextMaps[i+1] = g_NextMaps[i]; 
		}
		
		if (g_NextMapsCount < 6)
			g_NextMapsCount++;
	}
	else
		g_NextMapsCount = 1;
		
	decl String:item[64];
	for (new i = 0; i < GetMenuItemCount(g_hMapMenu); i++)
	{
		GetMenuItem(g_hMapMenu, i, item, sizeof(item));
		if (strcmp(item, g_MapNames[map]) == 0)
		{
			RemoveMenuItem(g_hMapMenu, i);
			break;
		}			
	}	
	
	g_NextMaps[0] = map;
	
	ReplyToCommand(client, "%t", "Map Inserted", g_MapNames[map]);

	if (client)
		LogMessage("[RTV] %L inserted map %s.", client, map);
	
	return Plugin_Handled;		
}

public Action:Command_Say(client, args)
{
	if (!g_CanRTV || !client)
		return Plugin_Continue;

	decl String:text[192], String:command[64];
	GetCmdArgString(text, sizeof(text));
	GetCmdArg(0, command, sizeof(command));

	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;
	
	if (strcmp(text[startidx], "rtv", false) == 0 || strcmp(text[startidx], "rockthevote", false) == 0)
	{
		if (!g_RTVAllowed)
		{
			PrintToChat(client, "[RTV] %t", "RTV Not Allowed");
			return Plugin_Continue;
		}
		
		if (g_RTVEnded)
		{
			PrintToChat(client, "[RTV] %t", "RTV Ended");
			return Plugin_Continue;
		}
		
		if (g_RTVStarted)
		{
			PrintToChat(client, "[RTV] %t", "RTV Started");
			return Plugin_Continue;
		}
		
		if (GetClientCount(true) < GetConVarInt(g_Cvar_MinPlayers) && g_Votes == 0)
		{
			PrintToChat(client, "[RTV] %t", "Minimal Players Not Met");
			return Plugin_Continue;			
		}
		
		if (g_Voted[client])
		{
			PrintToChat(client, "[RTV] %t", "Already Voted");
			return Plugin_Continue;
		}	
		
		new String:name[64];
		GetClientName(client, name, sizeof(name));
		
		g_Votes++;
		g_Voted[client] = true;
		
		PrintToChatAll("[RTV] %t", "RTV Requested", name, g_Votes, g_VotesNeeded);
		
		if (g_Votes >= g_VotesNeeded)
		{
			CreateTimer(2.0, Timer_StartRTV);
		}
	}
	else if (GetConVarBool(g_Cvar_Nominate) && strcmp(text[startidx], "nominate", false) == 0)
	{
		if (g_RTVStarted)
		{
			PrintToChat(client, "[RTV] %t", "RTV Started");
			return Plugin_Continue;
		}
		
		if (g_Nominated[client])
		{
			PrintToChat(client, "[RTV] %t", "Already Nominated");
			return Plugin_Continue;
		}
		
		if (g_NextMapsCount >= GetConVarInt(g_Cvar_Maps))
		{
			PrintToChat(client, "[RTV] %t", "Max Nominations");
			return Plugin_Continue;			
		}
		
		DisplayMenu(g_hMapMenu, client, MENU_TIME_FOREVER);		
	}
	
	return Plugin_Continue;	
}

public Action:Timer_DelayRTV(Handle:timer)
{
	g_RTVAllowed = true;
}

public Action:Timer_StartRTV(Handle:timer)
{
	if(!g_RTVAllowed)
		return;
	
	PrintToChatAll("[RTV] %t", "RTV Vote Ready");
	
	g_RTVStarted = true;
		
	new Handle:hMapVoteMenu = CreateMenu(Handler_MapVoteMenu);
	SetMenuTitle(hMapVoteMenu, "%t", "Rock The Vote");
	
	for (new i = 0; i < g_NextMapsCount; i++)
	{
		AddMenuItem(hMapVoteMenu, g_MapNames[g_NextMaps[i]], g_MapNames[g_NextMaps[i]]);
	}

	new mapIdx;
	for (new i = g_NextMapsCount; i < (g_MapCount < GetConVarInt(g_Cvar_Maps) ? g_MapCount : GetConVarInt(g_Cvar_Maps)); i++)
	{
		mapIdx = GetRandomInt(0, g_MapCount - 1);
		
		while (IsInMenu(mapIdx))
			if(++mapIdx >= g_MapCount) mapIdx = 0;

		g_NextMaps[i] = mapIdx;
		AddMenuItem(hMapVoteMenu, g_MapNames[mapIdx], g_MapNames[mapIdx]);
	}
	
	decl String:nochange[64];
	Format(nochange, 64, "%T", "Don't Change", LANG_SERVER);
	AddMenuItem(hMapVoteMenu, nochange, nochange);
		
	SetMenuExitButton(hMapVoteMenu, false);
	VoteMenuToAll(hMapVoteMenu, 20);
		
	LogMessage("[RTV] Rockthevote was successfully started.");
}

public Action:Timer_ChangeMap(Handle:hTimer, Handle:dp)
{
	new String:map[65];
	
	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));
	
	ServerCommand("changelevel \"%s\"", map);
	
	return Plugin_Stop;
}

public Handler_MapVoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
	}
	else if (action == MenuAction_Select)
	{
		new String:voter[64], String:choice[64];
		GetClientName(param1, voter, sizeof(voter));
		GetMenuItem(menu, param2, choice, sizeof(choice));
		PrintToChatAll("[RTV] %t", "Selected Map", voter, choice);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:map[64];
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if (totalVotes < 1)
		{
			PrintToChatAll("[RTV] %t", "No Votes");
			return;
		}
		
		GetMenuItem(menu, param1, map, sizeof(map));
		
		if (param1 == GetConVarInt(g_Cvar_Maps))
		{
			PrintToChatAll("[RTV] %t", "Current Map Stays");
			LogMessage("[RTV] Rockthevote has ended, current map kept.");
		}
		else
		{
			PrintToChatAll("[RTV] %t", "Changing Maps", map);
			LogMessage("[RTV] Rockthevote has ended, changing to map %s.", map);
			new Handle:dp;
			CreateDataTimer(5.0, Timer_ChangeMap, dp);
			WritePackString(dp, map);
		}
		
		g_RTVEnded = true;
	}
}

public Handler_MapSelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (g_NextMapsCount >= GetConVarInt(g_Cvar_Maps)) 
		{
			PrintToChat(param1, "[RTV] %t", "Max Nominations");
			return;	
		}
		
		decl String:map[64], String:mapIndex[16], String:name[64];
		GetMenuItem(menu, param2, mapIndex, 16, _, map, 64);
		
		new mapIdx = StringToInt(mapIndex);

		for (new i = 0; i < g_NextMapsCount; i++)
		{
			if (g_NextMaps[i] == mapIdx)
			{
				PrintToChat(param1, "[RTV] %t", "Map Already Nominated");
				return;
			}
		}
		
		GetClientName(param1, name, 64);
		
		g_NextMaps[g_NextMapsCount] = mapIdx;
		g_NextMapsCount++;
		
		RemoveMenuItem(menu, param2);
		
		g_Nominated[param1] = true;
		
		PrintToChatAll("[RTV] %t", "Map Nominated", name, map);
	}	
}

bool:IsInMenu(mapIdx)
{
	for (new i = 0; i < GetConVarInt(g_Cvar_Maps); i++)
		if (mapIdx == g_NextMaps[i])
			return true;
	return false;
}

LoadSettings(String:filename[])
{
	if (!FileExists(filename))
		return 0;

	new String:text[32];

	g_MapCount = 0;
	new Handle:hMapFile = OpenFile(filename, "r");
	
	while (g_MapCount < MAXMAPS && !IsEndOfFile(hMapFile))
	{
		ReadFileLine(hMapFile, text, sizeof(text));
		TrimString(text);

		if (text[0] != ';' && strcopy(g_MapNames[g_MapCount], sizeof(g_MapNames[]), text) &&
			IsMapValid(g_MapNames[g_MapCount]))
		{
			++g_MapCount;
		}
	}

	return g_MapCount;
}

BuildMapMenu()
{
	if (g_hMapMenu != INVALID_HANDLE)
	{
		CancelMenu(g_hMapMenu);
		CloseHandle(g_hMapMenu);
		g_hMapMenu = INVALID_HANDLE;
	}
	
	g_hMapMenu = CreateMenu(Handler_MapSelectMenu);
	SetMenuTitle(g_hMapMenu, "%t", "Nominate Title");

	decl String:MapIndex[8];
		
	for (new i = 0; i < g_MapCount; i++)
	{
		IntToString(i, MapIndex, 8);
		AddMenuItem(g_hMapMenu, MapIndex, g_MapNames[i]);
	}
	
	SetMenuExitButton(g_hMapMenu, false);
}