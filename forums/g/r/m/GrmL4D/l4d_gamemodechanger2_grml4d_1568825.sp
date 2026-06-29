#include <sourcemod>

public Plugin:myinfo =
{
	name = "L4D and L4D2 game mode changer",
	author = "Sharft 6",
	description = "allows players to change the game mode based on votes",
	version = "11",
	url = "http://forums.alliedmods.net/showthread.php?t=109439"
}

new String:g_game[16];
new String:g_cGameMode[32];
new String:g_gameMode[32];
new String:g_campagin[32];
new Handle:g_gameModeMenu = INVALID_HANDLE;
new Handle:g_campaginMenu = INVALID_HANDLE;
new Handle:g_mapMenu = INVALID_HANDLE;
new Handle:g_advertisel4dPlugin = INVALID_HANDLE;
new Handle:g_modeVoteTime = INVALID_HANDLE;
new Handle:g_mapVoteTime = INVALID_HANDLE;
new Handle:g_coopEnabled = INVALID_HANDLE;
new	Handle:g_versusEnabled = INVALID_HANDLE;
new	Handle:g_survivalEnabled = INVALID_HANDLE;
new	Handle:g_teamScavengeEnabled = INVALID_HANDLE;
new	Handle:g_teamVersusEnabled = INVALID_HANDLE;
new	Handle:g_realismEnabled = INVALID_HANDLE;
new	Handle:g_mutationEnabled = INVALID_HANDLE;
 
public OnPluginStart()
{
	GetGameFolderName(g_game, sizeof(g_game));
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegAdminCmd("sm_cancelvote", Command_CancelVote, ADMFLAG_VOTE);
	
	RegAdminCmd("sm_changegamemode", Command_GameMode, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_coop", Command_Coop, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_versus", Command_Versus, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_survival", Command_Survival, ADMFLAG_CHANGEMAP);
	if(strcmp(g_game, "left4dead2", false) == 0)
	{
		RegAdminCmd("sm_teamscavenge", Command_TeamScavenge, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_teamversus", Command_TeamVersus, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_realism", Command_Realism, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_mutation", Command_Mutation, ADMFLAG_CHANGEMAP);
	}
	
	g_advertisel4dPlugin = CreateConVar("sm_advertisel4dplugin", "1", "Specifies whether or not the plugin will advertise itself to players");
	
	g_modeVoteTime = CreateConVar("sm_modevotetime", "20", "Default time to vote on a game mode in seconds");
	g_mapVoteTime = CreateConVar("sm_mapvotetime", "30", "Default time to vote on a game mode in seconds");
	
	g_coopEnabled = CreateConVar("sm_coopenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	g_versusEnabled = CreateConVar("sm_versusenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	g_survivalEnabled = CreateConVar("sm_survivalenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	g_teamScavengeEnabled = CreateConVar("sm_teamscavengeenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	g_teamVersusEnabled = CreateConVar("sm_teamversusenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	g_realismEnabled = CreateConVar("sm_realismenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	g_mutationEnabled = CreateConVar("sm_mutationenabled", "1", "specifies whether or not this game mode will be available in the vote menu");
	
	AutoExecConfig(true, "plugin_gamemodechanger");
}

public OnMapStart()
{
	new Handle:currentGameMode = FindConVar("mp_gamemode");
	GetConVarString(currentGameMode, g_cGameMode, sizeof(g_cGameMode));	
}

public OnClientPutInServer(client)
{
	// Make the announcement in 40 seconds unless announcements are turned off
	if(client && !IsFakeClient(client) && GetConVarBool(g_advertisel4dPlugin))
		CreateTimer(40.0, TimerAnnounce, client);
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	PrintToChat(client, "\x04 !gamemode \x05 shows a menu containing the availables \x03 game modes and maps or missions");
}

public Action:Command_Say(client, args)
{
	if(!client)
	{
		return Plugin_Continue;
	}

	decl String:text[192];
	if(!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if(strcmp(text[startidx], "!gamemode", false) == 0)
	{
		DoGameModeList(client);
	}
	return Plugin_Continue;
}

DoGameModeList(client)
{
	g_gameModeMenu = BuildGameModeMenu(false);
	DisplayMenu(g_gameModeMenu, client, 20);
}

public Handle_GameModeList(Handle:gameModeMenu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if(action == MenuAction_Select)
	{
		decl String:gameMode[32];
		GetMenuItem(gameModeMenu, param2, gameMode, sizeof(gameMode));
		DoVoteMenu(gameMode);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(gameModeMenu);
	}
}

DoVoteMenu(const String:gameMode[])
{
	if(IsVoteInProgress())
	{
		return;
	}
 
	new Handle:voteMenu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(voteMenu, "Change game mode to: %s?", gameMode);
	AddMenuItem(voteMenu, gameMode, "Yes");
	AddMenuItem(voteMenu, "no", "No");
	SetMenuExitButton(voteMenu, false);
	
	new voteTime = GetConVarInt(g_modeVoteTime);
	VoteMenuToAll(voteMenu, voteTime);
	
	PrintToChatAll("Game mode change vote in progress...");
}

public Handle_VoteMenu(Handle:voteMenu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(voteMenu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		/* 0=yes, 1=no */
		if(param1 == 0)
		{
			GetMenuItem(voteMenu, param1, g_gameMode, sizeof(g_gameMode));
			
			DoCampaginVote();
		}
		else
		{
			PrintToChatAll("Keeping current game mode.");
		}
	}
	else if(action == MenuAction_VoteCancel)
	{
		// We were actually cancelled. Guess we do nothing.
	}
}

DoCampaginVote()
{
	if(IsVoteInProgress())
	{
		return;
	}
	
	g_campaginMenu = BuildCampaginMenu(false);

	CreateTimer(1.0, displayCampaginVoteMenu);
}

public Action:displayCampaginVoteMenu(Handle:timer)
{
	new voteTime = GetConVarInt(g_mapVoteTime);
	VoteMenuToAll(g_campaginMenu, voteTime);
	
	PrintToChatAll("Campain vote in progress...");
	
	return Plugin_Handled;
}

public Handle_CampaginVote(Handle:campaginMenu, MenuAction:action, param1, param2)
{	
	if(action == MenuAction_End)
	{
		CloseHandle(campaginMenu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		GetMenuItem(campaginMenu, param1, g_campagin, sizeof(g_campagin));
		
		DoMapVote()
	}
	else if(action == MenuAction_VoteCancel)
	{
		// If we receive 0 votes, pick at random.
		if (param1 == VoteCancel_NoVotes)
			{
				new count = GetMenuItemCount(campaginMenu);
				new item = GetRandomInt(0, count - 1);
				decl String:campagin[32];
				GetMenuItem(campaginMenu, item, campagin, sizeof(campagin));
				
				g_campagin = campagin
			}
			else
			{
				// We were actually cancelled. Guess we do nothing.
			}
	}
}

DoMapVote()
{
	if(IsVoteInProgress())
	{
		return;
	}
	
	g_mapMenu = BuildMapMenu(false);
	
	CreateTimer(1.0, displayMapVoteMenu);
}

public Action:displayMapVoteMenu(Handle:timer)
{
	new voteTime = GetConVarInt(g_mapVoteTime);
	VoteMenuToAll(g_mapMenu, voteTime);
	
	PrintToChatAll("Map vote in progress...");
	
	return Plugin_Handled;
}

public Handle_MapVote(Handle:mapMenu, MenuAction:action, param1, param2)
{	
	if(action == MenuAction_End)
	{
		CloseHandle(mapMenu);
	}
	else if(action == MenuAction_VoteEnd)
	{
		ServerCommand("sm_cvar mp_gamemode %s", g_gameMode);
		
		decl String:map[32];
		GetMenuItem(mapMenu, param1, map, sizeof(map));
		
		ServerCommand("changelevel %s", map);
	}
	else if(action == MenuAction_VoteCancel)
	{
		// If we receive 0 votes, pick at random.
		if (param1 == VoteCancel_NoVotes)
			{
				ServerCommand("sm_cvar mp_gamemode %s", g_gameMode);
				
				new count = GetMenuItemCount(mapMenu);
				new item = GetRandomInt(0, count - 1);
				decl String:map[32];
				GetMenuItem(mapMenu, item, map, sizeof(map));
				
				ServerCommand("changelevel %s", map);
			}
			else
			{
				// We were actually cancelled. Guess we do nothing.
			}
	}
}

public Action:Command_CancelVote(client, args)
{
	CancelVote();
	
	return Plugin_Handled;
}

public Action:Command_Coop(client, args)
{
	g_gameMode = "coop";
	ServerCommand("sm_cvar mp_gamemode coop");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Versus(client, args)
{
	g_gameMode = "versus";
	ServerCommand("sm_cvar mp_gamemode versus");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Survival(client, args)
{
	g_gameMode = "survival";
	ServerCommand("sm_cvar mp_gamemode survival");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_TeamScavenge(client, args)
{
	g_gameMode = "teamscavenge";
	ServerCommand("sm_cvar mp_gamemode teamscavenge");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_TeamVersus(client, args)
{
	g_gameMode = "teamversus";
	ServerCommand("sm_cvar mp_gamemode teamversus");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Realism(client, args)
{
	g_gameMode = "realism";
	ServerCommand("sm_cvar mp_gamemode realism");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_Mutation(client, args)
{
	g_gameMode = "mutation";
	ServerCommand("sm_cvar mp_gamemode mutation");
	DoAdminCampaginMenu(client);
 
	return Plugin_Handled;
}

public Action:Command_GameMode(client, args)
{
	g_gameModeMenu = BuildGameModeMenu(true);
	DisplayMenu(g_gameModeMenu, client, 60);
 
	return Plugin_Handled;
}

public Handle_AdminGameModeMenu(Handle:gameModeMenu, MenuAction:action, param1, param2)
{
	// If an option was selected, tell the client about the item.
	if(action == MenuAction_Select)
	{
		GetMenuItem(gameModeMenu, param2, g_gameMode, sizeof(g_gameMode));
		ServerCommand("sm_cvar mp_gamemode %s", g_gameMode);
		
		DoAdminMapMenu(param1);
	}
	// If the menu was cancelled, print a message to the server about it.
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		CloseHandle(gameModeMenu);
	}
}

DoAdminCampaginMenu(client)
{
	g_campaginMenu = BuildCampaginMenu(true);
	DisplayMenu(g_campaginMenu, client, 60);
}

public Handle_AdminCampaginMenu(Handle:campaginMenu, MenuAction:action, param1, param2)
{
	// Change the campagin to the selected item.
	if(action == MenuAction_Select)
	{
		decl String:campagin[32];
		GetMenuItem(campaginMenu, param2, campagin, sizeof(campagin));
		g_campagin = campagin;
		
		DoAdminMapMenu(param1);
	}
	// If the menu was cancelled, choose a random campagin.
	else if (action == MenuAction_Cancel)
	{
		new count = GetMenuItemCount(campaginMenu);
		new item = GetRandomInt(0, count - 1);
		decl String:campagin[32];
		GetMenuItem(campaginMenu, item, campagin, sizeof(campagin));
		
		DoAdminMapMenu(param1);
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		CloseHandle(campaginMenu);
	}
}

DoAdminMapMenu(client)
{
	g_mapMenu = BuildMapMenu(true);
	DisplayMenu(g_mapMenu, client, 60);
}

public Handle_AdminMapMenu(Handle:mapMenu, MenuAction:action, param1, param2)
{
	// Change the map to the selected item.
	if(action == MenuAction_Select)
	{
		decl String:map[32];
		GetMenuItem(mapMenu, param2, map, sizeof(map));
		ServerCommand("changelevel %s", map);
	}
	// If the menu was cancelled, choose a random map.
	else if (action == MenuAction_Cancel)
	{
		new count = GetMenuItemCount(mapMenu);
		new item = GetRandomInt(0, count - 1);
		decl String:map[32];
		GetMenuItem(mapMenu, item, map, sizeof(map));
		
		ServerCommand("changelevel %s", map);
	}
	// If the menu has ended, destroy it
	else if (action == MenuAction_End)
	{
		CloseHandle(mapMenu);
	}
}

Handle:BuildGameModeMenu(bool:adminMode)
{
	new Handle:gameModeMenu = INVALID_HANDLE;
	
	if(adminMode)
	{
		gameModeMenu = CreateMenu(Handle_AdminGameModeMenu);
	}
	else
	{
		gameModeMenu = CreateMenu(Handle_GameModeList);
	}
		
	SetMenuTitle(gameModeMenu, "Choose Game Mode");
	
	if(strcmp(g_cGameMode, "coop", false) != 0)
	{
		new coopEnabled = GetConVarInt(g_coopEnabled);
		if(adminMode == false && coopEnabled == 0)
		{
			// Don't add the item.
		}
		else
		{
			// Add the item.
			AddMenuItem(gameModeMenu, "coop", "Campaign");
		}
	}
	if(strcmp(g_cGameMode, "versus", false) != 0)
	{
		new versusEnabled = GetConVarInt(g_versusEnabled);
		if(adminMode == false && versusEnabled == 0)
		{
			// Don't add the item.
		}
		else
		{
			// Add the item.
			AddMenuItem(gameModeMenu, "versus", "Versus");
		}
	}
	if(strcmp(g_cGameMode, "survival", false) != 0)
	{
		new survivalEnabled = GetConVarInt(g_survivalEnabled);
		if(adminMode == false && survivalEnabled == 0)
		{
			// Don't add the item.
		}
		else
		{
			// Add the item.
			AddMenuItem(gameModeMenu, "survival", "Survival");
		}
	}
	if(strcmp(g_game, "left4dead2", false) == 0)
	{
		if(strcmp(g_cGameMode, "teamscavenge", false) != 0)
		{
			new teamScavengeEnabled = GetConVarInt(g_teamScavengeEnabled);
			if(adminMode == false && teamScavengeEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "teamscavenge", "Team Scavenge");
			}
		}
		if(strcmp(g_cGameMode, "teamversus", false) != 0)
		{
			new teamVersusEnabled = GetConVarInt(g_teamVersusEnabled);
			if(adminMode == false && teamVersusEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "teamversus", "Team Versus");
			}
		}
		if(strcmp(g_cGameMode, "realism", false) != 0)
		{
			new realismEnabled = GetConVarInt(g_realismEnabled);
			if(adminMode == false && realismEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "realism", "Realism");
			}
		}
		if(strcmp(g_cGameMode, "mutation", false) != 0)
		{
			new mutationEnabled = GetConVarInt(g_mutationEnabled);
			if(adminMode == false && mutationEnabled == 0)
			{
				// Don't add the item.
			}
			else
			{
				// Add the item.
				AddMenuItem(gameModeMenu, "mutation", "Mutation");
			}
		}
	}
	return gameModeMenu;
}

Handle:BuildCampaginMenu(bool:adminMode)
{
	new Handle:campaginMenu = INVALID_HANDLE;

	if(adminMode)
	{
		campaginMenu = CreateMenu(Handle_AdminCampaginMenu);
	}
	else
	{
		campaginMenu = CreateMenu(Handle_CampaginVote);
	}
	
	SetMenuTitle(campaginMenu, "Vote for a Campagin");
	SetMenuExitButton(campaginMenu, false);
	
	if(strcmp(g_game, "left4dead", false) == 0)
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
		AddMenuItem(campaginMenu, "Blood Harvest", "Blood Harvest");
		AddMenuItem(campaginMenu, "Dead Getaway", "Dead Getaway");
		AddMenuItem(campaginMenu, "Vienna Calling", "Vienna Calling");
		AddMenuItem(campaginMenu, "Death Aboard", "Death Aboard");
		AddMenuItem(campaginMenu, "Suicide Blitz", "Suicide Blitz");
		AddMenuItem(campaginMenu, "Mercy Hospital", "Mercy Hospital");
		AddMenuItem(campaginMenu, "Precinct 84", "Precinct 84");
		AddMenuItem(campaginMenu, "Death Toll", "Death Toll");
		AddMenuItem(campaginMenu, "Darkblood", "Darkblood");
		AddMenuItem(campaginMenu, "Crash Course", "Crash Course");
		AddMenuItem(campaginMenu, "I Hate Mountains", "I Hate Mountains");
		AddMenuItem(campaginMenu, "Dead Before Dawn", "Dead Before Dawn");
		AddMenuItem(campaginMenu, "One4Nine", "One4Nine");
		AddMenuItem(campaginMenu, "Dead Air", "Dead Air");
		AddMenuItem(campaginMenu, "City 17", "City 17");
		AddMenuItem(campaginMenu, "The Sacrifice", "The Sacrifice");
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)
		{
		AddMenuItem(campaginMenu, "Blood Harvest", "Blood Harvest");
		AddMenuItem(campaginMenu, "Dead Getaway", "Dead Getaway");
		AddMenuItem(campaginMenu, "Death Aboard", "Death Aboard");
		AddMenuItem(campaginMenu, "Suicide Blitz", "Suicide Blitz");
		AddMenuItem(campaginMenu, "Mercy Hospital", "Mercy Hospital");
		AddMenuItem(campaginMenu, "Precinct 84", "Precinct 84");
		AddMenuItem(campaginMenu, "Death Toll", "Death Toll");
		AddMenuItem(campaginMenu, "Darkblood", "Darkblood");
		AddMenuItem(campaginMenu, "Crash Course", "Crash Course");
		AddMenuItem(campaginMenu, "I Hate Mountains", "I Hate Mountains");
		AddMenuItem(campaginMenu, "Dead Before Dawn", "Dead Before Dawn");
		AddMenuItem(campaginMenu, "One4Nine", "One4Nine");
		AddMenuItem(campaginMenu, "Dead Air", "Dead Air");
		AddMenuItem(campaginMenu, "City 17", "City 17");
		AddMenuItem(campaginMenu, "The Sacrifice", "The Sacrifice");
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)
		{
		AddMenuItem(campaginMenu, "Blood Harvest", "Blood Harvest");
		AddMenuItem(campaginMenu, "Dead Getaway", "Dead Getaway");
		AddMenuItem(campaginMenu, "Death Aboard", "Death Aboard");
		AddMenuItem(campaginMenu, "Mercy Hospital", "Mercy Hospital");
		AddMenuItem(campaginMenu, "Precinct 84", "Precinct 84");
		AddMenuItem(campaginMenu, "Death Toll", "Death Toll");
		AddMenuItem(campaginMenu, "Crash Course", "Crash Course");
		AddMenuItem(campaginMenu, "Dead Before Dawn", "Dead Before Dawn");
		AddMenuItem(campaginMenu, "One4Nine", "One4Nine");
		AddMenuItem(campaginMenu, "Dead Air", "Dead Air");
		AddMenuItem(campaginMenu, "City 17", "City 17");
		AddMenuItem(campaginMenu, "The Sacrifice", "The Sacrifice");
		AddMenuItem(campaginMenu, "Lighthouse", "Lighthouse");
		}
	}
	else if(strcmp(g_game, "left4dead2", false) == 0)
	{
		AddMenuItem(campaginMenu, "Campagin 1", "Campagin 1");
		AddMenuItem(campaginMenu, "Campagin 2", "Campagin 2");
		AddMenuItem(campaginMenu, "Campagin 3", "Campagin 3");
		AddMenuItem(campaginMenu, "Campagin 4", "Campagin 4");
		AddMenuItem(campaginMenu, "Campagin 5", "Campagin 5");
		AddMenuItem(campaginMenu, "The Passing", "The Passing");
		AddMenuItem(campaginMenu, "The Sacrifice", "The Sacrifice");
		AddMenuItem(campaginMenu, "Mercy Hospital", "Mercy Hospital");
		AddMenuItem(campaginMenu, "Death Toll", "Death Toll");
		AddMenuItem(campaginMenu, "Dead Air", "Dead Air");
		AddMenuItem(campaginMenu, "Blood Harvest", "Blood Harvest");
		AddMenuItem(campaginMenu, "Cold Stream", "Cold Stream");		
	}
	return campaginMenu;
}

Handle:BuildMapMenu(bool:adminMode)
{
	new Handle:mapMenu = INVALID_HANDLE;
	
	if(adminMode)
	{
		mapMenu = CreateMenu(Handle_AdminMapMenu);
	}
	else
	{
		mapMenu = CreateMenu(Handle_MapVote);
	}
	
	SetMenuTitle(mapMenu, "Choose a Map");
	SetMenuExitButton(mapMenu, false);
	
	if(strcmp(g_game, "left4dead", false) == 0)
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
			if(strcmp(g_campagin, "Mercy Hospital", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_hospital01_apartment", "Apartment");
				AddMenuItem(mapMenu, "l4d_hospital02_subway", "Generator Room");
				AddMenuItem(mapMenu, "l4d_hospital03_sewers", "Gas Station");
				AddMenuItem(mapMenu, "l4d_hospital04_interior", "Hospital");
				AddMenuItem(mapMenu, "l4d_hospital05_rooftop", "Rooftop");
			}
			else if(strcmp(g_campagin, "Crash Course", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_garage01_alleys", "Alleys");
				AddMenuItem(mapMenu, "l4d_garage02_lots", "Truck Depot");
			}
			else if(strcmp(g_campagin, "Death Toll", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_smalltown01_caves", "Caves");
				AddMenuItem(mapMenu, "l4d_smalltown02_drainage", "Drains");
				AddMenuItem(mapMenu, "l4d_smalltown03_ranchhouse", "Church");
				AddMenuItem(mapMenu, "l4d_smalltown04_mainstreet", "Street");
				AddMenuItem(mapMenu, "l4d_smalltown05_houseboat", "Boathouse");
			}
			else if(strcmp(g_campagin, "Dead Air", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_airport01_greenhouse", "Greenhouse");
				AddMenuItem(mapMenu, "l4d_airport02_offices", "Crane");
				AddMenuItem(mapMenu, "l4d_airport03_garage", "Construction Site");
				AddMenuItem(mapMenu, "l4d_airport04_terminal", "Terminal");
				AddMenuItem(mapMenu, "l4d_airport05_runway", "Runway");
			}
			else if(strcmp(g_campagin, "Blood Harvest", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_farm01_hilltop", "Hilltop");
				AddMenuItem(mapMenu, "l4d_farm02_traintunnel", "Warehouse");
				AddMenuItem(mapMenu, "l4d_farm03_bridge", "Bridge");
				AddMenuItem(mapMenu, "l4d_farm04_barn", "Train Station");
				AddMenuItem(mapMenu, "l4d_farm05_cornfield", "Farmhouse");
			}
			else if(strcmp(g_campagin, "The Sacrifice", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_river01_docks", "Docks");
				AddMenuItem(mapMenu, "l4d_river02_barge", "Barge");
				AddMenuItem(mapMenu, "l4d_river03_port", "Port");
			}
			else if(strcmp(g_campagin, "City 17", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_city17_01", "Tunnels");
				AddMenuItem(mapMenu, "l4d_city17_02", "Surface");
				AddMenuItem(mapMenu, "l4d_city17_03", "Streets");
				AddMenuItem(mapMenu, "l4d_city17_04", "Hospital");
				AddMenuItem(mapMenu, "l4d_city17_05", "Trainstation");
			}
			else if(strcmp(g_campagin, "Darkblood", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_darkblood01_tanker", "Tanker");
				AddMenuItem(mapMenu, "l4d_darkblood02_engine", "Engine");
				AddMenuItem(mapMenu, "l4d_darkblood03_platform", "Platform");
				AddMenuItem(mapMenu, "l4d_darkblood04_extraction", "Extraction");
			}
			else if(strcmp(g_campagin, "Dead Before Dawn", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_dbd_citylights", "Citylights");
				AddMenuItem(mapMenu, "l4d_dbd_anna_is_gone", "Anna");
				AddMenuItem(mapMenu, "l4d_dbd_the_mall", "Mall");
				AddMenuItem(mapMenu, "l4d_dbd_clean_up", "Clean Up");
				AddMenuItem(mapMenu, "l4d_dbd_new_dawn", "New Dawn");
			}
			else if(strcmp(g_campagin, "Death Aboard", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_deathaboard01_prison", "Prison");
				AddMenuItem(mapMenu, "l4d_deathaboard02_yard", "Yard");
				AddMenuItem(mapMenu, "l4d_deathaboard03_docks", "Docks");
				AddMenuItem(mapMenu, "l4d_deathaboard04_ship", "Ship");
				AddMenuItem(mapMenu, "l4d_deathaboard05_light", "Lighthouse");
			}
			else if(strcmp(g_campagin, "I Hate Mountains", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_ihm01_forest", "Woods");
				AddMenuItem(mapMenu, "l4d_ihm02_manor", "Manor");
				AddMenuItem(mapMenu, "l4d_ihm03_underground", "Underground Way");
				AddMenuItem(mapMenu, "l4d_ihm04_lumberyard", "Lumberyard");
				AddMenuItem(mapMenu, "l4d_ihm05_lakeside", "Lakeside");
			}
			else if(strcmp(g_campagin, "One4Nine", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_149_1", "Dawn of Zombies");
				AddMenuItem(mapMenu, "l4d_149_2", "Military Base");
				AddMenuItem(mapMenu, "l4d_149_3", "Bad Moon");
				AddMenuItem(mapMenu, "l4d_149_4", "My God !!");
				AddMenuItem(mapMenu, "l4d_149_5", "Tomb");
			}
			else if(strcmp(g_campagin, "Dead Getaway", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_deadgetaway01_dam", "Dam");
				AddMenuItem(mapMenu, "l4d_deadgetaway02_zone", "Restricted Zone");
				AddMenuItem(mapMenu, "l4d_deadgetaway03_lab", "Facility");
				AddMenuItem(mapMenu, "l4d_deadgetway04_tunnel", "Tunnel");
				AddMenuItem(mapMenu, "l4d_deadgetaway_final", "Final");
			}
			else if(strcmp(g_campagin, "Precinct 84", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_noprecinct01_crash", "Crash");
				AddMenuItem(mapMenu, "l4d_noprecinct02_train", "Slums");
				AddMenuItem(mapMenu, "l4d_noprecinct03_clubd", "NightClub");
				AddMenuItem(mapMenu, "l4d_noprecinct04_precinct", "Gas Station");
			}
			else if(strcmp(g_campagin, "Suicide Blitz", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_stadium1_apartment", "Apartment");
				AddMenuItem(mapMenu, "l4d_stadium2_underground", "Underground");
				AddMenuItem(mapMenu, "l4d_stadium3_city1", "Law");
				AddMenuItem(mapMenu, "l4d_stadium4_city2", "City");
				AddMenuItem(mapMenu, "l4d_stadium5_stadium", "Stadium");
			}
			else if(strcmp(g_campagin, "Vienna Calling", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_viennacalling_city", "Innere Stadt");
				AddMenuItem(mapMenu, "l4d_viennacalling_kaiserfranz", "Bahnhof");
				AddMenuItem(mapMenu, "l4d_viennacalling_gloomy", "Nussdorf");
				AddMenuItem(mapMenu, "l4d_viennacalling_donauinsel", "Donauinsel");
				AddMenuItem(mapMenu, "l4d_viennacalling_donauturm", "Donauturm");
			}
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)
		{
			if(strcmp(g_campagin, "Mercy Hospital", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_vs_hospital01_apartment", "Apartment");
				AddMenuItem(mapMenu, "l4d_vs_hospital02_subway", "Generator Room");
				AddMenuItem(mapMenu, "l4d_vs_hospital03_sewers", "Gas Station");
				AddMenuItem(mapMenu, "l4d_vs_hospital04_interior", "Hospital");
				AddMenuItem(mapMenu, "l4d_vs_hospital05_rooftop", "Rooftop");
			}
			else if(strcmp(g_campagin, "Crash Course", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_garage01_alleys", "Alleys");
				AddMenuItem(mapMenu, "l4d_garage02_lots", "Truck Depot");
			}
			else if(strcmp(g_campagin, "Death Toll", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_vs_smalltown01_caves", "Caves");
				AddMenuItem(mapMenu, "l4d_vs_smalltown02_drainage", "Drains");
				AddMenuItem(mapMenu, "l4d_vs_smalltown03_ranchhouse", "Church");
				AddMenuItem(mapMenu, "l4d_vs_smalltown04_mainstreet", "Street");
				AddMenuItem(mapMenu, "l4d_vs_smalltown05_houseboat", "Boathouse");
			}
			else if(strcmp(g_campagin, "Dead Air", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_vs_airport01_greenhouse", "Greenhouse");
				AddMenuItem(mapMenu, "l4d_vs_airport02_offices", "Crane");
				AddMenuItem(mapMenu, "l4d_vs_airport03_garage", "Construction Site");
				AddMenuItem(mapMenu, "l4d_vs_airport04_terminal", "Terminal");
				AddMenuItem(mapMenu, "l4d_vs_airport05_runway", "Runway");
			}
			else if(strcmp(g_campagin, "Blood Harvest", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_vs_farm01_hilltop", "Hilltop");
				AddMenuItem(mapMenu, "l4d_vs_farm02_traintunnel", "Warehouse");
				AddMenuItem(mapMenu, "l4d_vs_farm03_bridge", "Bridge");
				AddMenuItem(mapMenu, "l4d_vs_farm04_barn", "Train Station");
				AddMenuItem(mapMenu, "l4d_vs_farm05_cornfield", "Farmhouse");
			}
			else if(strcmp(g_campagin, "The Sacrifice", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_river01_docks", "Docks");
				AddMenuItem(mapMenu, "l4d_river02_barge", "Barge");
				AddMenuItem(mapMenu, "l4d_river03_port", "The Port");
			}
			else if(strcmp(g_campagin, "City 17", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_vs_city17_01", "Tunnels");
				AddMenuItem(mapMenu, "l4d_vs_city17_02", "Surface");
				AddMenuItem(mapMenu, "l4d_vs_city17_03", "Streets");
				AddMenuItem(mapMenu, "l4d_vs_city17_04", "Hospital");
				AddMenuItem(mapMenu, "l4d_vs_city17_05", "Trainstation");
			}
			else if(strcmp(g_campagin, "Darkblood", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_darkblood01_tanker", "Tanker");
				AddMenuItem(mapMenu, "l4d_darkblood02_engine", "Engine");
				AddMenuItem(mapMenu, "l4d_darkblood03_platform", "Platform");
				AddMenuItem(mapMenu, "l4d_darkblood04_extraction", "Extraction");
			}
			else if(strcmp(g_campagin, "Dead Before Dawn", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_dbd_citylights", "Citylights");
				AddMenuItem(mapMenu, "l4d_dbd_anna_is_gone", "Anna");
				AddMenuItem(mapMenu, "l4d_dbd_the_mall", "Mall");
				AddMenuItem(mapMenu, "l4d_dbd_clean_up", "Clean Up");
				AddMenuItem(mapMenu, "l4d_dbd_new_dawn", "New Dawn");
			}
			else if(strcmp(g_campagin, "Death Aboard", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_deathaboard01_prison", "Prison");
				AddMenuItem(mapMenu, "l4d_deathaboard02_yard", "Yard");
				AddMenuItem(mapMenu, "l4d_deathaboard03_docks", "Docks");
				AddMenuItem(mapMenu, "l4d_deathaboard04_ship", "Ship");
				AddMenuItem(mapMenu, "l4d_deathaboard05_light", "Lighthouse");
			}
			else if(strcmp(g_campagin, "I Hate Mountains", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_ihm01_forest", "Woods");
				AddMenuItem(mapMenu, "l4d_ihm02_manor", "Manor");
				AddMenuItem(mapMenu, "l4d_ihm03_underground", "Underground Way");
				AddMenuItem(mapMenu, "l4d_ihm04_lumberyard", "Lumberyard");
				AddMenuItem(mapMenu, "l4d_ihm05_lakeside", "Lakeside");
			}
			else if(strcmp(g_campagin, "One4Nine", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_149_1", "Dawn of Zombies");
				AddMenuItem(mapMenu, "l4d_149_2", "Military Base");
				AddMenuItem(mapMenu, "l4d_149_3", "Bad Moon");
				AddMenuItem(mapMenu, "l4d_149_4", "My God !!");
				AddMenuItem(mapMenu, "l4d_149_5", "Tomb");
			}
			else if(strcmp(g_campagin, "Precinct 84", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_noprecinct01_crash", "Crash");
				AddMenuItem(mapMenu, "l4d_noprecinct02_train", "Slums");
				AddMenuItem(mapMenu, "l4d_noprecinct03_clubd", "NightClub");
				AddMenuItem(mapMenu, "l4d_noprecinct04_precinct", "Gas Station");
			}
			else if(strcmp(g_campagin, "Suicide Blitz", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_vs_stadium1_apartment", "Apartment");
				AddMenuItem(mapMenu, "l4d_vs_stadium2_underground", "Underground");
				AddMenuItem(mapMenu, "l4d_vs_stadium3_city1", "Law");
				AddMenuItem(mapMenu, "l4d_vs_stadium4_city2", "City");
				AddMenuItem(mapMenu, "l4d_vs_stadium5_stadium", "Stadium");
			}
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)
		{
			if(strcmp(g_campagin, "Mercy Hospital", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_hospital02_subway", "Generator Room");
				AddMenuItem(mapMenu, "l4d_hospital03_sewers", "Gas Station");
				AddMenuItem(mapMenu, "l4d_hospital04_interior", "Hospital");
				AddMenuItem(mapMenu, "l4d_vs_hospital05_rooftop", "Rooftop");
			}
			else if(strcmp(g_campagin, "Crash Course", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_garage01_alleys", "Bridge");
				AddMenuItem(mapMenu, "l4d_garage02_lots", "Truck Depot");
			}
			else if(strcmp(g_campagin, "Death Toll", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_smalltown02_drainage", "Drains");
				AddMenuItem(mapMenu, "l4d_smalltown03_ranchhouse", "Church");
				AddMenuItem(mapMenu, "l4d_smalltown04_mainstreet", "Street");
				AddMenuItem(mapMenu, "l4d_vs_smalltown05_houseboat", "Boathouse");
			}
			else if(strcmp(g_campagin, "Dead Air", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_airport02_offices", "Crane");
				AddMenuItem(mapMenu, "l4d_airport03_garage", "Construction Site");
				AddMenuItem(mapMenu, "l4d_airport04_terminal", "Terminal");
				AddMenuItem(mapMenu, "l4d_vs_airport05_runway", "Runway");
			}
			else if(strcmp(g_campagin, "Blood Harvest", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_farm02_traintunnel", "Warehouse");
				AddMenuItem(mapMenu, "l4d_farm03_bridge", "Bridge (bloodharvest)");
				AddMenuItem(mapMenu, "l4d_vs_farm05_cornfield", "Farmhouse");
			}
			else if(strcmp(g_campagin, "The Sacrifice", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_river01_docks", "The Traincar");
				AddMenuItem(mapMenu, "l4d_river03_port", "The Port");
			}
			else if(strcmp(g_campagin, "Lighthouse", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_sv_lighthouse", "Lighthouse");
			}
			else if(strcmp(g_campagin, "Dead Before Dawn", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_dbd_undead_center", "Undead center");
			}
			else if(strcmp(g_campagin, "Death Aboard", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_sv_deathaboard_ship", "Ship");
				AddMenuItem(mapMenu, "l4d_deathaboard05_light", "Lighthouse");
			}
			else if(strcmp(g_campagin, "One4Nine", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_149_sv_1", "Residence");
				AddMenuItem(mapMenu, "l4d_149_sv_2", "Barricade");
				AddMenuItem(mapMenu, "l4d_149_sv_3", "Food");
				AddMenuItem(mapMenu, "l4d_149_sv_4", "Scaffolding");
				AddMenuItem(mapMenu, "l4d_149_sv_5", "Monolith");
			}
			else if(strcmp(g_campagin, "Precinct 84", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_noprecinct01_crash", "Twilight Apartment");
				AddMenuItem(mapMenu, "l4d_noprecinct03_clubd", "Chicago Ted Guns");
			}
			else if(strcmp(g_campagin, "Suicide Blitz", false) == 0)
			{
				AddMenuItem(mapMenu, "l4d_sv_stadium2_underground", "Underground");
				AddMenuItem(mapMenu, "l4d_sv_stadium3_city1", "Law");
				AddMenuItem(mapMenu, "l4d_sv_stadium4_city2", "City");
				AddMenuItem(mapMenu, "l4d_stadium5_stadium", "Stadium");
			}
		}
	}
	else if(strcmp(g_game, "left4dead2", false) == 0)
	{
		if(strcmp(g_campagin, "Campagin 1", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "Hotel");
			AddMenuItem(mapMenu, "c1m2_streets", "Streets");
			AddMenuItem(mapMenu, "c1m3_mall", "Mall");
			AddMenuItem(mapMenu, "c1m4_atrium", "Atrium");
		}
		else if(strcmp(g_campagin, "Campagin 2", false) == 0)
		{
			AddMenuItem(mapMenu, "c2m1_highway", "Highway");
			AddMenuItem(mapMenu, "c2m2_fairgrounds", "Fairgrounds");
			AddMenuItem(mapMenu, "c2m3_coaster", "Coaster");
			AddMenuItem(mapMenu, "c2m4_barns", "Barns");
			AddMenuItem(mapMenu, "c2m5_concert", "Concert");
		}
		else if(strcmp(g_campagin, "Campagin 3", false) == 0)
		{
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Plank Country");
			AddMenuItem(mapMenu, "c3m2_swamp", "Swamp");
			AddMenuItem(mapMenu, "c3m3_shantytown", "Shanty Town");
			AddMenuItem(mapMenu, "c3m4_plantation", "Plantation");
		}
		else if(strcmp(g_campagin, "Campagin 4", false) == 0)
		{
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Mill Town 1");
			AddMenuItem(mapMenu, "c4m2_sugarmill_a", "Sugar Mill 1");
			AddMenuItem(mapMenu, "c4m3_sugarmill_b", "Sugar Mill 2");
			AddMenuItem(mapMenu, "c4m4_milltown_b", "Mill Town 2");
			AddMenuItem(mapMenu, "c4m5_milltown_escape", "Mill Town Escape");
		}
		else if(strcmp(g_campagin, "Campagin 5", false) == 0)
		{
			AddMenuItem(mapMenu, "c5m1_waterfront", "Waterfront");
			AddMenuItem(mapMenu, "c5m2_park", "Park");
			AddMenuItem(mapMenu, "c5m3_cemetery", "Cemetery");
			AddMenuItem(mapMenu, "c5m4_quarter", "Quarter");
			AddMenuItem(mapMenu, "c5m5_bridge ", "Bridge");
		}
		else if(strcmp(g_campagin, "The Passing", false) == 0)
		{
			AddMenuItem(mapMenu, "C6m1_riverbank", "River Bank");
			AddMenuItem(mapMenu, "C6m2_bedlam", "Bedlam");
			AddMenuItem(mapMenu, "C6m3_port", "Port");
		}
		else if(strcmp(g_campagin, "The Sacrifice", false) == 0)
		{
			AddMenuItem(mapMenu, "C7m1_docks", "Docks");
			AddMenuItem(mapMenu, "C7m2_barge", "Barge");
			AddMenuItem(mapMenu, "C7m3_port", "Port");
		}
		else if(strcmp(g_campagin, "Mercy Hospital", false) == 0)
		{
			AddMenuItem(mapMenu, "C8m1_apartment", "Apartments");
			AddMenuItem(mapMenu, "C8m2_subway", "Subway");
			AddMenuItem(mapMenu, "C8m3_sewers", "Sewers");
			AddMenuItem(mapMenu, "C8m4_interior", "Interior");
			AddMenuItem(mapMenu, "C8m5_rooftop", "Rooftop");
		}
		else if(strcmp(g_campagin, "Death Toll", false) == 0)
		{		
			AddMenuItem(mapMenu, "C10m1_caves", "Caves");
			AddMenuItem(mapMenu, "C10m2_drainage", "Drainage");
			AddMenuItem(mapMenu, "C10m3_ranchhouse", "Ranch House");
			AddMenuItem(mapMenu, "C10m4_mainstreet", "Main Street");
			AddMenuItem(mapMenu, "C10m5_houseboat", "House Boat");		
		}
		else if(strcmp(g_campagin, "Dead Air", false) == 0)
		{
			AddMenuItem(mapMenu, "C11m1_greenhouse", "Greenhouse");
			AddMenuItem(mapMenu, "C11m2_offices", "Offices");
			AddMenuItem(mapMenu, "C11m3_garage", "Garage");
			AddMenuItem(mapMenu, "11m4_terminal", "Terminal");
			AddMenuItem(mapMenu, "C11m5_runway", "Runway");
		}
		else if(strcmp(g_campagin, "Blood Harvest", false) == 0)
		{
			AddMenuItem(mapMenu, "C12m1_hilltop", "Hilltop");
			AddMenuItem(mapMenu, "C12m2_traintunnel", "Train Tunnel");
			AddMenuItem(mapMenu, "C12m3_bridge", "Bridge");
			AddMenuItem(mapMenu, "C12m4_barn", "Barn");
			AddMenuItem(mapMenu, "C12m5_cornfield", "Cornfield");
		}
		else if(strcmp(g_campagin, "Cold Stream", false) == 0)
		{
			AddMenuItem(mapMenu, "C13m1_alpinecreek", "Alpine Creek");
			AddMenuItem(mapMenu, "C13m2_southpinestream", "South Pine Stream");
			AddMenuItem(mapMenu, "C13m3_memorialbridge", "Memorial Bridge");
			AddMenuItem(mapMenu, "13m4_cutthroatcreek", "Cut Throat Creek");
		}
		else if(strcmp(g_campagin, "The Sacrifice again?", false) == 0)
		{
			AddMenuItem(mapMenu, "l4d_river01_docks", "The Traincar");
			AddMenuItem(mapMenu, "l4d_river03_port", "The Port");
		}
	}
	return mapMenu;
}