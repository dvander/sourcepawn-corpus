// Force strict semicolon mode
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION	"0.666"

new String:g_gameMode[64];
new Handle:g_mapMenu = INVALID_HANDLE;
new Handle:g_mapVoteTime = INVALID_HANDLE;

new bool: game_l4d2 = false;

public Plugin:myinfo =
{
	name = "[L4D2] Campaign/Map Voter",
	author = "NoBody",
	description = "Allows voting by players to change campaign/map",
	version = PLUGIN_VERSION,
	url = "..."
}

public OnPluginStart()
{
	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}
	if (StrEqual(game_name, "left4dead2", false))
	{
		game_l4d2 = true;
	}

	CreateConVar("l4d_mapvote_version", PLUGIN_VERSION, "[[L4D2] Campaign/Map Voter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("menu", Command_MapVote);
	g_mapVoteTime = CreateConVar("sm_mapvotetime", "20", "Default time to vote on a map in seconds",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	CreateConVar("l4d_mapvote_announce_mode", "1", "Controls how mapvote announcement is displayed.");
	AutoExecConfig(true, "l4d2_mapvote_beta");
}

public OnMapStart()
{
	new Handle:currentGameMode = FindConVar("mp_gamemode");
	GetConVarString(currentGameMode, g_gameMode, sizeof(g_gameMode));	
}

public OnClientPutInServer(client)
{
	if(GetConVarInt(FindConVar("l4d_mapvote_announce_mode")) != 0)
	{
		CreateTimer(20.0, Timer_WelcomeMessage, client);
	}
}

public Action:Timer_WelcomeMessage(Handle:timer, any:client) 
{
	new String:announce[] = "\x03[SM] To call a vote to change map/campaign votes, Type: \x04!menu\x03 in chat.";
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) 
	{
		switch (GetConVarInt(FindConVar("l4d_mapvote_announce_mode"))) 
		{
			case 1: 
			{
				PrintToChat(client, announce);
			}
			case 2: 
			{
				PrintHintText(client, announce);
			}
			case 3: 
			{
				PrintCenterText(client, announce);
			}
			default: 
			{
				PrintToChat(client, announce);
			}
		}
	}
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
	
	if(strcmp(text[startidx], "!menu", false) == 0)
	{
		DoMapVoteList(client);
	}
	return Plugin_Continue;
}

DoMapVoteList(client)
{
	g_mapMenu = BuildMapMenu(false);
	DisplayMenu(g_mapMenu, client, 60);
}

public Handle_MapVoteList(Handle:mapMenu, MenuAction:action, param1, param2)
{
	// Change the map to the selected item.
	if(action == MenuAction_Select)
	{
		decl String:map[128];
		GetMenuItem(mapMenu, param2, map, sizeof(map));
		DoVoteMenu (map);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(mapMenu);
	}
}

public Handle_VoteMenu(Handle:voteMenu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(voteMenu);
	}
	else if (action == MenuAction_VoteEnd)
	if (param1 == 0)
	{
		decl String:map[128];
		GetMenuItem(voteMenu, param1, map, sizeof(map));
		ServerCommand("changelevel %s", map);
		
		PrintToChatAll("Vote Successful!  Changing to %s");
	}
}

DoVoteMenu(const String:map[])
{
	if(IsVoteInProgress())
	{
		return;
	}
 
	new Handle:voteMenu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(voteMenu, "Change Campaign/Map to: %s?", map);
	AddMenuItem(voteMenu, map, "Yes");
	AddMenuItem(voteMenu, "no", "No");
	SetMenuExitButton(voteMenu, false);
	
	new voteTime = GetConVarInt(g_mapVoteTime);
	VoteMenuToAll(voteMenu, voteTime);
	
	PrintToChatAll("\x05In Progress...");
}

public Action:Command_MapVote(client, args)
{
	g_mapMenu = BuildMapMenu(true);
	DisplayMenu(g_mapMenu, client, 60);
 
	return Plugin_Handled;
}

public OnMapEnd()
{
	if (g_mapMenu != INVALID_HANDLE)
	{
		CloseHandle(g_mapMenu);
		g_mapMenu = INVALID_HANDLE;
	}
}


Handle:BuildMapMenu(bool:client)
{
	new Handle:mapMenu = INVALID_HANDLE;
	
	if(client)
	{
	   mapMenu = CreateMenu(Handle_MapVoteList);
	}
	
	SetMenuTitle(mapMenu, "Choose a Map:");
	SetMenuExitButton(mapMenu, true);
	
	if(game_l4d2)
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
			AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
		}
		else if(strcmp(g_gameMode, "realism", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
			AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
			AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
		}
		else if(strcmp(g_gameMode, "teamversus", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
			AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m4_atrium", "Atrium");
			AddMenuItem(mapMenu, "c2m1_highway", "Highway");
			AddMenuItem(mapMenu, "c2m4_barns", "Barns");
			AddMenuItem(mapMenu, "c2m5_concert", "Concert");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Plank Country");
			AddMenuItem(mapMenu, "c3m4_plantation", "Plantation");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Mill Town 1");
			AddMenuItem(mapMenu, "c4m2_sugarmill_a", "Sugar Mill 1");
			AddMenuItem(mapMenu, "c5m2_park", "Park");
			AddMenuItem(mapMenu, "c5m5_bridge ", "Bridge");
		}		
		else if(strcmp(g_gameMode, "scavenge", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m4_atrium", "Atrium");
			AddMenuItem(mapMenu, "c2m1_highway", "Highway");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Plank Country");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Mill Town 1");
			AddMenuItem(mapMenu, "c4m2_sugarmill_a", "Sugar Mill 1");
			AddMenuItem(mapMenu, "c5m2_park", "Park");
		}
		else if(strcmp(g_gameMode, "teamscavenge", false) == 0)
		{
			AddMenuItem(mapMenu, "c1m4_atrium", "Atrium");
			AddMenuItem(mapMenu, "c2m1_highway", "Highway");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Plank Country");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Mill Town 1");
			AddMenuItem(mapMenu, "c4m2_sugarmill_a", "Sugar Mill 1");
			AddMenuItem(mapMenu, "c5m2_park", "Park");
		}
		else
		{
			AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
			AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
		}
	}
	else
	{
		if(strcmp(g_gameMode, "coop", false) == 0)
		{
			AddMenuItem(mapMenu, "l4d_hospital01_apartment", "Mercy Hospital");
			AddMenuItem(mapMenu, "l4d_garage01_alleys", "Crash Course");
			AddMenuItem(mapMenu, "l4d_smalltown01_caves", "Death Toll");
			AddMenuItem(mapMenu, "l4d_airport01_greenhouse", "Dead Air");
			AddMenuItem(mapMenu, "l4d_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(g_gameMode, "versus", false) == 0)
		{
			AddMenuItem(mapMenu, "l4d_vs_hospital01_apartment", "Mercy Hospital");
			AddMenuItem(mapMenu, "l4d_garage01_alleys", "Crash Course");
			AddMenuItem(mapMenu, "l4d_vs_smalltown01_caves", "Death Toll");
			AddMenuItem(mapMenu, "l4d_vs_airport01_greenhouse", "Dead Air");
			AddMenuItem(mapMenu, "l4d_vs_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(g_gameMode, "survival", false) == 0)
		{
			AddMenuItem(mapMenu, "l4d_hospital02_subway", "Generator Room");
			AddMenuItem(mapMenu, "l4d_hospital03_sewers", "Gas Station");
			AddMenuItem(mapMenu, "l4d_hospital04_interior", "Hospital");
			AddMenuItem(mapMenu, "l4d_vs_hospital05_rooftop", "Rooftop");
			AddMenuItem(mapMenu, "l4d_garage01_alleys", "Bridge (crashcourse)");
			AddMenuItem(mapMenu, "l4d_garage02_lots", "Truck Depot");
			AddMenuItem(mapMenu, "l4d_smalltown02_drainage", "Drains");
			AddMenuItem(mapMenu, "l4d_smalltown03_ranchhouse", "Church");
			AddMenuItem(mapMenu, "l4d_smalltown04_mainstreet", "Street");
			AddMenuItem(mapMenu, "l4d_vs_smalltown05_houseboat", "Boathouse");
			AddMenuItem(mapMenu, "l4d_airport02_offices", "Crane");
			AddMenuItem(mapMenu, "l4d_airport03_garage", "Construction Site");
			AddMenuItem(mapMenu, "l4d_airport04_terminal", "Terminal");
			AddMenuItem(mapMenu, "l4d_vs_airport05_runway", "Runway");
			AddMenuItem(mapMenu, "l4d_farm02_traintunnel", "Warehouse");
			AddMenuItem(mapMenu, "l4d_farm03_bridge", "Bridge (bloodharvest)");
			AddMenuItem(mapMenu, "l4d_vs_farm05_cornfield", "Farmhouse");
			AddMenuItem(mapMenu, "l4d_sv_lighthouse", "Lighthouse");
		}
	}

	return mapMenu;
}