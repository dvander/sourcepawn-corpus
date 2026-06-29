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
 * - For new scripters using RTV as an example, I have heavily commented it.
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

new String:g_MapNames[MAXMAPS][32];				// Array of map names loaded from mapcycle.txt or RTV File cvar.
new g_MapCount = 0;								// Total maps loaded.
new g_NextMapsCount = 0;						// Total non-random maps chosen for next vote.
new g_NextMaps[6];								// Indexes of the non-random maps

new Handle:g_hMapMenu = INVALID_HANDLE;			// Handle for the menu used for nominations

new Handle:g_Cvar_Needed = INVALID_HANDLE;		// Cvar handle for sm_rtv_needed
new Handle:g_Cvar_File = INVALID_HANDLE;		// Cvar handle for sm_rtv_file
new Handle:g_Cvar_Maps = INVALID_HANDLE;		// Cvar handle for sm_rtv_maps
new Handle:g_Cvar_Nominate = INVALID_HANDLE;	// Cvar handle for sm_rtv_nominate
new Handle:g_Cvar_MinPlayers = INVALID_HANDLE;	// Cvar handle for sm_rtv_minplayers

new g_CanRTV = false;							// Boolean used to determine if RTV is enabled. This is false
												// when RTV could not load a map list.
new g_RTVAllowed = false;						// Used to temporarily disable RTV after a map change.
new g_RTVStarted = false;						// Set to true once the RTV Vote has been triggered.
new g_RTVEnded = false;							// Set to true once the RTV Vote has ended.
new g_Voters = 0;								// Number of voters connected. This doesn't count bots.
new g_Votes = 0; 								// Number of votes received
new g_VotesNeeded = 0;							// Amount of votes required to trigger RTV Vote
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};	// Keeps track of whether a player has already voted to trigger RTV
new bool:g_Nominated[MAXPLAYERS+1] = {false, ...}; // Keeps track of who has already nominated a map


public OnPluginStart()
{
	LoadTranslations("common.phrases");			// Load the common.phrases.txt translation file.
	LoadTranslations("plugin.rockthevote");		// Load RTV's plugin.rockthevote.txt translation file.
	
	// Create an unchangable Cvar that has RTV's version number. This can be queried by server lists.
	CreateConVar("sm_rockthevote_version", PLUGIN_VERSION, "RockTheVote Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Create all of the other cvars. These can be set by server admins.
	g_Cvar_Needed = CreateConVar("sm_rtv_needed", "0.60", "Percentage of players needed to rockthevote (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_File = CreateConVar("sm_rtv_file", "configs/maps.ini", "Map file to use. (Def configs/maps.ini)");
	g_Cvar_Maps = CreateConVar("sm_rtv_maps", "4", "Number of maps to be voted on. 1 to 6. (Def 4)", 0, true, 2.0, true, 6.0);
	g_Cvar_Nominate = CreateConVar("sm_rtv_nominate", "1", "Enables nomination system.", 0, true, 0.0, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtv_minplayers", "0", "Number of players required before RTV will be enabled.", 0, true, 0.0, true, 64.0);
	
	// Register the "say" commands so we can respond to 'rtv' and 'nominate'
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	// Register an admin command that allows maps to be forced into RTV.
	RegAdminCmd("sm_rtv_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_rtv_addmap <mapname> - Forces a map to be on the RTV, and lowers the allowed nominations.");
}

public OnMapStart()	// When the map starts...
{
	// Reset our global variables back to 0.
	g_NextMapsCount = 0;
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_RTVStarted = false;
	g_RTVEnded = false;
	
	decl String:MapListPath[256], String:MapListFile[64];	// Declare strings for our map list file path.
	GetConVarString(g_Cvar_File, MapListFile, 64); 			// Get the file name from our sm_rtv_file cvar.
	BuildPath(Path_SM, MapListPath, sizeof(MapListPath), MapListFile); // Build a path from our file name.
	if (!FileExists(MapListPath))	// If we can't find the file...
	{
		new Handle:hMapCycleFile = FindConVar("mapcyclefile");	// Find the mapcycle convar.
		GetConVarString(hMapCycleFile, MapListPath, sizeof(MapListPath)); // Set the map file to mapcycle's value.
	}
	
	LogMessage("[RTV] Map Cycle Path: %s", MapListPath); // Log a message so server admin knows what file we used.
	
	if (LoadSettings(MapListPath))	// Use LoadSetting's to load the file. If successful...
	{
		BuildMapMenu();				// Create the nominate menu
		g_CanRTV = true;			// Enable RTV
		CreateTimer(30.0, Timer_DelayRTV);	// In 30 seconds, call "Timer_DelayRTV", which will Allow RTV
	}
	else // If we did not successfully load the mapfile...
	{
		LogMessage("[RTV] Cannot find map cycle file, RTV not active.");	// Log a message
		g_CanRTV = false;													// Disable RTV.
	}
}

public OnMapEnd()	// When the map ends...
{
	CloseHandle(g_hMapMenu);		// Close the nomination menu handler
	g_hMapMenu = INVALID_HANDLE;	// Set it to 0 (INVALID_HANDLE is 0)
	g_RTVAllowed = false;			// Do not allow RTV anymore.
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) // When a player connects...
{
	if(IsFakeClient(client)) // If its a fake client, don't do anything. Bots or HLTV count as fake.
		return true;
	
	g_Voted[client] = false;		// Reset whether or not this client has voted.
	g_Nominated[client] = false;	// Reset if this client has nominated

	g_Voters++;						// Add 1 to the number of voters.
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed)); // Recalculate the votes needed
	
	// Note on above: First we take the number of voters, and change it to a float.
	// Then we multiple it by the float value of the cvar "sm_rtv_needed". We take
	// the result and round it down (7.4 becomes 7, 8.7 becomes 8, etc).
	
	return true; // If you return false in OnClientConnect, the player will not be allowed to join.
}

public OnClientDisconnect(client) // When a player disconnects
{
	if(IsFakeClient(client)) // Ignore bots and HLTV's.
		return;
	
	if(g_Voted[client]) // If the player had voted...
	{
		g_Votes--;		// Remove their vote
	}
	
	g_Voters--;			// Lower the number of voters.
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed)); // Recalculate votes needed, same as in connect
	
	// If, because of the player leaving, the number of votes is greater than the votes needed,
	// and RTV is allowed, AND the voters aren't equal to 0...
	if (g_Votes >= g_VotesNeeded && g_RTVAllowed && g_Voters != 0) 
	{
		CreateTimer(2.0, Timer_StartRTV); // Start the RTV vote in 2 seconds.
	}	
}

public Action:Command_Addmap(client, args) // When sm_rtv_addmap is used...
{
	if (args < 1) // If the number of arguments is less than 1...
	{
		ReplyToCommand(client, "[SM] Usage: sm_rtv_addmap <mapname>");	// Tell the client how to use the command.
		return Plugin_Handled;	// Plugin_Handled means we've done everything that should be done for this action.
	}
	
	decl String:mapname[64];	// String for the map name.
	GetCmdArg(1, mapname, sizeof(mapname));	// Get the first argument and store it as mapname.
	
	new map = -1;	// We'll use this to store the map index. -1 means we don't have one.
	
	for (new i = 0; i < g_MapCount; i++) // Loop until i equals g_MapCount
	{
		// Compare the MapName to the g_MapNames at index i, case-insensitive. 0 means they are identical.
		if(strcmp(g_MapNames[i], mapname, false) == 0)
		{
			map = i;	// save i as our map index
			break;	// End the loop.
		}		
	}

	if (map == -1) // If we didn't find the map...
	{
		ReplyToCommand(client, "%t", "Map was not found", map);	// Tell the client we didn't find it.
		return Plugin_Handled;
	}
	
	// If we already have non-random maps...
	if (g_NextMapsCount > 0)
	{
		// Make sure the map isn't already set for the next vote.
		for (new i = 0; i < g_NextMapsCount; i++)
		{
			if (map == g_NextMaps[i])
			{
				ReplyToCommand(client, "%t", "Map Already In Vote", g_MapNames[map]);
				return Plugin_Handled;			
			}		
		}
		
		// If NextMapsCount is already at 6 (The maximum), we start at 4.
		// Otherwise, subtract one from NextMapsCount. This is an "inline if"
		new start = (g_NextMapsCount == 6 ? 4 : g_NextMapsCount - 1);
		for (new i = start; i < 0; i--) // Loop backwards from 'start' to 0.
		{
			// Move i+1 to i. This is why we start at 4 if NextMapsCount is 6. If
			// we started at 5, 5+1 = 6. 6 is too large for this array.
			g_NextMaps[i+1] = g_NextMaps[i]; 
		}
		
		if (g_NextMapsCount < 6) // If it isn't 6...
			g_NextMapsCount++; // Add 1.
	}
	else
		g_NextMapsCount = 1;
		
	// Remove the map from the nominations menu.
	decl String:item[64];
	for (new i = 0; i < GetMenuItemCount(g_hMapMenu); i++) // Loop from 0 to the number of items in menu.
	{
		GetMenuItem(g_hMapMenu, i, item, sizeof(item)); // Get the menu item name at i
		if (strcmp(item, g_MapNames[map]) == 0) // Compare i to the name of our map.
		{
			RemoveMenuItem(g_hMapMenu, i);	// If we found our map, remove it from the menu
			break;							// And end the loop.
		}			
	}	
	
	g_NextMaps[0] = map;	// Set the first non-random map to ours.
	
	ReplyToCommand(client, "%t", "Map Inserted", map);	// Tell the client we've added the map

	if (client) // If the client isn't the server
		LogMessage("[RTV] %L inserted map %s.", client, map); // Log this action.
	
	return Plugin_Handled;		
}

public Action:Command_Say(client, args)
{
	if (!g_CanRTV || !client)		// If RTV is enabled, and client isn't the server.
		return Plugin_Continue;		// Return Plugin_Continue. This means the game will finish doing
									// whatever it was doing. In this case, it will display the user's
									// original message to everyone. If we returned Plugin_Handled, it
									// would not.
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text)); // Get the entire message

	new startidx = 0;
	if(text[strlen(text)-1] == '"') // If the last characterr is a quote mark...
	{
		text[strlen(text)-1] = '\0'; // Get rid of it
		startidx = 1; // Move the start forward to 1.
	}
	
	// If player said "rtv" or "rockthevote"
	if (strcmp(text[startidx], "rtv", false) == 0 || strcmp(text[startidx], "rockthevote", false) == 0)
	{
		if (!g_RTVAllowed) // If RTV is not allowed...
		{
			PrintToChat(client, "[RTV] %t", "RTV Not Allowed");
			return Plugin_Continue;
		}
		
		if (g_RTVEnded) // If RTV has ended...
		{
			PrintToChat(client, "[RTV] %t", "RTV Ended");
			return Plugin_Continue;
		}
		
		if (g_RTVStarted) // If RTV has started...
		{
			PrintToChat(client, "[RTV] %t", "RTV Started");
			return Plugin_Continue;
		}
		
		// If the number of players is less than the sm_rtv_minplayers cvar, and there are no votes.
		if (GetClientCount(true) < GetConVarInt(g_Cvar_MinPlayers) && g_Votes == 0)
		{
			PrintToChat(client, "[RTV] %t", "Minimal Players Not Met");
			return Plugin_Continue;			
		}
		
		// If the client has voted
		if (g_Voted[client])
		{
			PrintToChat(client, "[RTV] %t", "Already Voted");
			return Plugin_Continue;
		}	
		
		new String:name[64];
		GetClientName(client, name, sizeof(name));	// Get the client's name
		
		g_Votes++; // Increment votes by 1
		g_Voted[client] = true; // Keep track of the player having voted.
		
		// Let everyone know a vote was made
		PrintToChatAll("[RTV] %t", "RTV Requested", name, g_Votes, g_VotesNeeded);
		
		if (g_Votes >= g_VotesNeeded) // If the votes are greater than what is needed
		{
			CreateTimer(2.0, Timer_StartRTV); // Start the RTV Vote in 2 seconds
		}
	}
	// If we're allowed to nominate, and the player said "nominate"
	else if (GetConVarBool(g_Cvar_Nominate) && strcmp(text[startidx], "nominate", false) == 0)
	{
		if (g_RTVStarted) // If RTV started...
		{
			PrintToChat(client, "[RTV] %t", "RTV Started");
			return Plugin_Continue;
		}
		
		if (g_Nominated[client]) // If the playey already nominated...
		{
			PrintToChat(client, "[RTV] %t", "Already Nominated");
			return Plugin_Continue;
		}
		
		// If we've already used all of the non-random maps allowed...
		if (g_NextMapsCount >= GetConVarInt(g_Cvar_Maps))
		{
			PrintToChat(client, "[RTV] %t", "Max Nominations");
			return Plugin_Continue;			
		}
		
		// Display the nomination menu to the user
		DisplayMenu(g_hMapMenu, client, MENU_TIME_FOREVER);		
	}
	
	// Return plugin continue so other's see what the player said.
	return Plugin_Continue;	
}

public Action:Timer_DelayRTV(Handle:timer)
{
	g_RTVAllowed = true;	// Allow RTV.
}

public Action:Timer_StartRTV(Handle:timer)
{
	if(!g_RTVAllowed)	// If RTV is not allowed.
		return;
	
	// Let everyone know RTV is starting.
	PrintToChatAll("[RTV] %t", "RTV Vote Ready");
	
	g_RTVStarted = true;	// RTV has started.
		
	// Create a new menu
	new Handle:hMapVoteMenu = CreateMenu(Handler_MapVoteMenu);
	SetMenuTitle(hMapVoteMenu, "%t", "Rock The Vote"); // Set the menu title
	
	// Starting at 0 to g_nextMapsCount, add all non-random maps to the menu.
	for (new i = 0; i < g_NextMapsCount; i++)
	{
		AddMenuItem(hMapVoteMenu, g_MapNames[g_NextMaps[i]], g_MapNames[g_NextMaps[i]]);
	}

	new mapIdx;	// Used as a temporary index
	// starting at g_NextMapsCount, until i is equal to g_MapCount or sm_rtv_maps
	for (new i = g_NextMapsCount; i < (g_MapCount < GetConVarInt(g_Cvar_Maps) ? g_MapCount : GetConVarInt(g_Cvar_Maps)); i++)
	{
		mapIdx = GetRandomInt(0, g_MapCount - 1); // Get a random number from 0 to g_mapCount-1
		
		while (IsInMenu(mapIdx))	// While mapIdx is already in the menu...
			if(++mapIdx >= g_MapCount) mapIdx = 0; // Increment mapIdx, and check if it's at g_MapCount. Set to 0 if it is.

		g_NextMaps[i] = mapIdx;	// Add mapIdx to the list of maps we've used
		AddMenuItem(hMapVoteMenu, g_MapNames[mapIdx], g_MapNames[mapIdx]); // Add the map to the menu.
	}
	
	decl String:nochange[64];
	Format(nochange, 64, "%T", "Don't Change", LANG_SERVER);	// Create a string with the "Don't Change" phrase.
	AddMenuItem(hMapVoteMenu, nochange, nochange);	// Add it to the menu
		
	SetMenuExitButton(hMapVoteMenu, false); // Get rid of the 0. Exit choice.
	VoteMenuToAll(hMapVoteMenu, 20);		// Send the menu to the players as a 20 second vote.	
		
	LogMessage("[RTV] Rockthevote was successfully started."); // Make a log entry about RTV starting.
}

public Action:Timer_ChangeMap(Handle:hTimer, Handle:dp)
{
	new String:map[65];
	
	ResetPack(dp); // Reset the databack
	ReadPackString(dp, map, sizeof(map)); // Get the first string from the databack
	
	ServerCommand("changelevel \"%s\"", map); // Issue the changelevel command.
	
	return Plugin_Stop; // Stop doing anything.
}

public Handler_MapVoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) // If its the end of the menu...
	{
		CloseHandle(menu);	// Close the menu
		menu = INVALID_HANDLE;
	}
	else if (action == MenuAction_Select)	// When someone makes a menu choice...
	{
		new String:voter[64], String:choice[64];
		GetClientName(param1, voter, sizeof(voter));	// Get their name
		GetMenuItem(menu, param2, choice, sizeof(choice));	// Get their choice
		PrintToChatAll("[RTV] %t", "Selected Map", voter, choice);	// Display it to everyone
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:map[64];
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);	// Get how many votes were for this map, and the total votes
		
		if (totalVotes < 1) // If we got no votes...
		{
			PrintToChatAll("[RTV] %t", "No Votes");	// Tell everyone then...
			return;									// ... do nothing else
		}
		
		GetMenuItem(menu, param1, map, sizeof(map)); // Get the map name from the menu
		
		if (param1 == GetConVarInt(g_Cvar_Maps))  // If this was the "no change" option...
		{
			PrintToChatAll("[RTV] %t", "Current Map Stays");
			LogMessage("[RTV] Rockthevote has ended, current map kept.");
		}
		else // If it was a map...
		{
			PrintToChatAll("[RTV] %t", "Changing Maps", map);
			LogMessage("[RTV] Rockthevote has ended, changing to map %s.", map);
			new Handle:dp; // New datapack
			CreateDataTimer(5.0, Timer_ChangeMap, dp);	// In 5 seconds, change the map, using the datapack
			WritePackString(dp, map);	// Add the mapname to the datapack
		}
		
		g_RTVEnded = true; // RTV has ended.
	}
}

public Handler_MapSelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) // When a player makes a choice on the nominate menu...
	{
		// If we can't add anymore maps...
		if (g_NextMapsCount >= GetConVarInt(g_Cvar_Maps)) 
		{
			PrintToChat(param1, "[RTV] %t", "Max Nominations");
			return;	
		}
		
		decl String:map[64], String:mapIndex[16], String:name[64];
		GetMenuItem(menu, param2, mapIndex, 16, _, map, 64); // Get the player's choice.
		
		new mapIdx = StringToInt(mapIndex); // Menu items are stings, so convert to an integer.

		// Loop through the already nominated maps...
		for (new i = 0; i < g_NextMapsCount; i++)
		{
			if (g_NextMaps[i] == mapIdx) // If we found the player's choice...
			{
				PrintToChat(param1, "[RTV] %t", "Map Already Nominated");
				return;
			}
		}
		
		GetClientName(param1, name, 64); // Get the user's name
		
		g_NextMaps[g_NextMapsCount] = mapIdx; // Add the map to the list
		g_NextMapsCount++; // Move the counter up.
		
		RemoveMenuItem(menu, param2); // Remove the map from the nominations menu.
		
		g_Nominated[param1] = true; // The player has nominated
		
		PrintToChatAll("[RTV] %t", "Map Nominated", name, map); // Let everyone know.
	}	
}

bool:IsInMenu(mapIdx)
{
	// Check through the used maps for mapIdx. Return true if found, false if not.	
	for (new i = 0; i < GetConVarInt(g_Cvar_Maps); i++)
		if (mapIdx == g_NextMaps[i])
			return true;
	return false;
}

LoadSettings(String:filename[])
{
	if (!FileExists(filename)) // Check if the file exists
		return 0;

	new String:text[32];

	g_MapCount = 0; // Reset the map counter
	new Handle:hMapFile = OpenFile(filename, "r"); // Open the file for reading.
	
	while (g_MapCount < MAXMAPS && !IsEndOfFile(hMapFile)) // Until we hit the maximum maps, or the end of the file
	{
		ReadFileLine(hMapFile, text, sizeof(text)); // Get a line from the file
		TrimString(text); // Trim spaces off the end.

		// This is kinda nasty. If the first character of the line isn't a comment, and the map
		// is valid, and it successfully copied into g_MapNames, increment the map count.
		if (text[0] != ';' && strcopy(g_MapNames[g_MapCount], sizeof(g_MapNames[]), text) &&
			IsMapValid(g_MapNames[g_MapCount]))
		{
			++g_MapCount;
		}
	}

	return g_MapCount; // Return the map count. If it's 0, no maps were loaded and we failed.
}

BuildMapMenu()
{
	if (g_hMapMenu != INVALID_HANDLE) // If the menu isn't closed...
	{
		CancelMenu(g_hMapMenu); // Cancel the menu
		CloseHandle(g_hMapMenu); // Close the menu
		g_hMapMenu = INVALID_HANDLE; // Set it to 0
	}
	
	g_hMapMenu = CreateMenu(Handler_MapSelectMenu); // Create the menu
	SetMenuTitle(g_hMapMenu, "%t", "Nominate Title"); // Set the title.

	decl String:MapIndex[8];
		
	// Loop through all the maps
	for (new i = 0; i < g_MapCount; i++)
	{
		IntToString(i, MapIndex, 8); // Menu items are strings, so change from Integer to String!
		AddMenuItem(g_hMapMenu, MapIndex, g_MapNames[i]); // Add the map to the menu
	}
	
	SetMenuExitButton(g_hMapMenu, false); // Get rid of 0. Exit choice.
}