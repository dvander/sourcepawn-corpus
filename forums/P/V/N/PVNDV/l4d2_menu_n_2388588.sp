#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION	"1.0"

new Handle:g_mapVoteTime = INVALID_HANDLE;
new Second;

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

new String:g_VoteType[32];

ConVar g_Cvar_Limits[2] = {null, ...};

public Plugin:myinfo =
{
	name = "[L4D2] Campaign/Map Voter",
	author = "NoBody",
	description = "Allows voting by players to change campaign/map",
	version = PLUGIN_VERSION,
	url = "..."
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if(strcmp(sGameName, "left4dead", false) == 0 && strcmp(sGameName, "left4dead2", false) == 0)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("l4d_mapvote_version", PLUGIN_VERSION, "[[L4D2] Campaign/Map Voter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("menu", Command_MapVote);
	g_mapVoteTime = CreateConVar("sm_mapvotetime", "30", "Default time to vote on a map in seconds.", FCVAR_PLUGIN);
	g_Cvar_Limits[1] = CreateConVar("sm_vote_map", "0.60", "percent required for successful map vote.", 0, true, 0.05, true, 1.0);
	CreateConVar("l4d_mapvote_announce_mode", "1", "Controls how mapvote announcement is displayed.");
	LoadTranslations("l4d2_menu_n.phrases");
	AutoExecConfig(true, "l4d2_menu");
}

public OnMapStart()
{
	decl String:gamemode[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
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
	new String:announce[] = "\x03Type \x04!menu \x03to call a vote to change campaign/map.";
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

public Action:Command_MapVote(client, args)
{
	if (IsVoteInProgress())
	{
		PrintToChat(client, "%t", "Vote in Progress");
		return Plugin_Handled;
	}
	
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	MapMenuCreateMenu(client);
 
	return Plugin_Handled;
}

public Handle_MapVoteList(Handle:menuMap, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:map[128];
		GetMenuItem(menuMap, param2, map, sizeof(map));
		DisplayVote(map);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuMap);
	}
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) 
	{
		PrintToChatAll("%t", "Detected");
	} 
	else if (action == MenuAction_VoteEnd)
	{
		decl String:map[64], String:display[64];
		new Float:percent, Float:limit, votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, map, sizeof(map), _, display, sizeof(display));
		
		if (strcmp(map, VOTE_NO) == 0 && param1 == 1) 
		{
			votes = totalVotes - votes;
			limit = g_Cvar_Limits[1].FloatValue;
		}
	
		percent = GetVotePercent(votes, totalVotes);
		
		if ((strcmp(map, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(map, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} 
		else
		{
			PrintToChatAll("%t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);

			if (strcmp(map, VOTE_NO) == 0 || strcmp(map, VOTE_YES) == 0)
			{
				strcopy(map, sizeof(map), display);
			}
			
			if (strcmp(g_VoteType, "map"))
			{
				PrintToChatAll("%t", "Changing map", map);
				Second = 10;
				CreateTimer(1.0, TimerCount, _, TIMER_REPEAT);  
				new Handle:dp;
				CreateDataTimer(10.0, Timer_ChangeMap, dp);
				WritePackString(dp, map);		
			}
		}
	}
}

DisplayVote(const String:map[])
{
	strcopy(g_VoteType, sizeof(g_VoteType), map);

	new Handle:menu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	if (strcmp(map, "map"))
	{
		SetMenuTitle(menu, "Change Campaign/Map to: %s?", map);
	}
	
	AddMenuItem(menu, map, "Yes");
	AddMenuItem(menu, VOTE_NO, "No");
	
	new voteTime = GetConVarInt(g_mapVoteTime);
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, voteTime);
	PrintToChatAll("%t", "Initiated Vote Map");
}

MapMenuCreateMenu(client)
{
	decl String:gamemode[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	new Handle:mapMenu = CreateMenu(Handle_MapVoteList);
	
	SetMenuTitle(mapMenu, "Choose a Map:");

	if (StrContains(gamemode, "coop", false) != -1)
	{
		AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
		AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
		AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
		AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
		AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
	}
	if (StrContains(gamemode, "realism", false) != -1)
	{
		AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
		AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
		AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
		AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
		AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
	}
	if (StrContains(gamemode, "versus", false) != -1)
	{
		AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
		AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
		AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
		AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
		AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
	}
	if (StrContains(gamemode, "teamversus", false) != -1)
	{
		AddMenuItem(mapMenu, "c1m1_hotel", "Dead Center");
		AddMenuItem(mapMenu, "c2m1_highway", "Dark Carnival");
		AddMenuItem(mapMenu, "c3m1_plankcountry", "Swamp Fever");
		AddMenuItem(mapMenu, "c4m1_milltown_a", "Hard Rain");
		AddMenuItem(mapMenu, "c5m1_waterfront", "The Parish");
	}
	if(StrContains(gamemode, "survival", false) != -1)
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
	if (StrContains(gamemode, "scavenge", false) != -1)
	{
		AddMenuItem(mapMenu, "c1m4_atrium", "Atrium");
		AddMenuItem(mapMenu, "c2m1_highway", "Highway");
		AddMenuItem(mapMenu, "c3m1_plankcountry", "Plank Country");
		AddMenuItem(mapMenu, "c4m1_milltown_a", "Mill Town 1");
		AddMenuItem(mapMenu, "c4m2_sugarmill_a", "Sugar Mill 1");
		AddMenuItem(mapMenu, "c5m2_park", "Park");
	}
	if (StrContains(gamemode, "teamscavenge", false) != -1)
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
		if (StrContains(gamemode, "coop", false) != -1)
		{
			AddMenuItem(mapMenu, "l4d_hospital01_apartment", "Mercy Hospital");
			AddMenuItem(mapMenu, "l4d_garage01_alleys", "Crash Course");
			AddMenuItem(mapMenu, "l4d_smalltown01_caves", "Death Toll");
			AddMenuItem(mapMenu, "l4d_airport01_greenhouse", "Dead Air");
			AddMenuItem(mapMenu, "l4d_farm01_hilltop", "Blood Harvest");
		}
		if (StrContains(gamemode, "versus", false) != -1)
		{
			AddMenuItem(mapMenu, "l4d_vs_hospital01_apartment", "Mercy Hospital");
			AddMenuItem(mapMenu, "l4d_garage01_alleys", "Crash Course");
			AddMenuItem(mapMenu, "l4d_vs_smalltown01_caves", "Death Toll");
			AddMenuItem(mapMenu, "l4d_vs_airport01_greenhouse", "Dead Air");
			AddMenuItem(mapMenu, "l4d_vs_farm01_hilltop", "Blood Harvest");
		}
		if (StrContains(gamemode, "survival", false) != -1)
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
	
	SetMenuExitButton(mapMenu, true);
	DisplayMenu(mapMenu, client, 0);
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes), float(totalVotes));
}

bool:TestVoteDelay(client)
{
 	new delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			PrintToChat(client, "%t", "Vote Delay Minutes", delay % 60);
 		}
 		else
 		{
 			PrintToChat(client, "%t", "Vote Delay Seconds", delay);
 		}
 		
 		return false;
 	}
 	
	return true;
}

public Action:TimerCount(Handle:timer)
{
	if (Second  <= 0)
	{
		return Plugin_Stop;
	}

	Second--;

	PrintToChatAll("%t", "Through", Second);

	return Plugin_Continue;
}

public Action:Timer_ChangeMap(Handle:timer, Handle:dp)
{
	decl String:map[65];
	
	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));
	
	ServerCommand("changelevel %s", map);
	
	return Plugin_Stop;
}
