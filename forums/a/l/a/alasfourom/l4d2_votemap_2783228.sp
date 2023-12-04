#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION	"2.1"

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

new Handle:g_mapVoteTime = INVALID_HANDLE;

new String:sGameName[12];
new String:sGameMode[32];
new String:g_VoteType[32];
new Second;

ConVar g_Cvar_Limits[2] = {null, ...};

public Plugin:myinfo =
{
	name = "Vote Map",
	author = "satannuts",
	description = "Allows voting by players to change campaign/map",
	version = PLUGIN_VERSION,
	url = "..."
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
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
	HookEvent("round_start", eRound_Start);
	
	CreateConVar("l4d_mapvote_version", PLUGIN_VERSION, "[[L4D2] Campaign/Map Voter Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("votemap", Command_MapVote);
	g_mapVoteTime = CreateConVar("sm_mapvotetime", "30", "Default time to vote on a map in seconds.", FCVAR_PLUGIN);
	g_Cvar_Limits[1] = CreateConVar("sm_vote_map", "0.60", "percent required for successful map vote.", 0, true, 0.05, true, 1.0);
	CreateConVar("l4d_mapvote_announce_mode", "1", "Controls how mapvote announcement is displayed.");
	LoadTranslations("votemap.phrases");
	AutoExecConfig(true, "l4d2_menu");
}

public eRound_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:currentGameMode = FindConVar("mp_gamemode");
	GetConVarString(currentGameMode, sGameMode, sizeof(sGameMode));	
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
	new String:announce[] = "\x03Type \x04!votemap \x03to call a vote to change map.";
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
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:camp[128], String:campaignname[128];
			GetMenuItem(menuMap, param2, camp, sizeof(camp), _,campaignname, sizeof(campaignname));
			DisplayVote(camp, campaignname);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack) 
			{
				MapMenuCreateMenu(param1);
			}
		}
		case MenuAction_End: CloseHandle(menuMap);
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
		decl String:display[64];
		new String:camp[64];
		new Float:percent, Float:limit, votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, camp, sizeof(camp), _, display, sizeof(display));
		
		if (strcmp(camp, VOTE_NO) == 0 && param1 == 1) 
		{
			votes = totalVotes - votes;
			limit = g_Cvar_Limits[1].FloatValue;
		}
	
		percent = GetVotePercent(votes, totalVotes);
		
		if ((strcmp(camp, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(camp, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("%t", "Vote Failed", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
		} 
		
		else
		{
			PrintToChatAll("%t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);

			if (strcmp(camp, VOTE_NO) == 0 || strcmp(camp, VOTE_YES) == 0)
			{
				strcopy(camp, sizeof(camp), display);
			}
			
			if (strcmp(g_VoteType, "map"))
			{
				Second = 10;
				CreateTimer(1.0, TimerCount, _, TIMER_REPEAT);  
				new Handle:dp;
				CreateDataTimer(10.0, Timer_ChangeMap, dp);
				WritePackString(dp, camp);
			}
		}
	}
}

DisplayVote(const String:camp[], const String:campaignname[])
{
	strcopy(g_VoteType, sizeof(g_VoteType), camp);

	new Handle:menu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	
	if (strcmp(camp, "map"))
	{
		SetMenuTitle(menu, "Change campaign/map to: %s?", campaignname);
	
		AddMenuItem(menu, camp, "Yes");
		AddMenuItem(menu, VOTE_NO, "No");
	
		new voteTime = GetConVarInt(g_mapVoteTime);
		SetMenuExitButton(menu, false);
		VoteMenuToAll(menu, voteTime);
		PrintToChatAll("%t", "Initiated Vote Map");
	}	
}

MapMenuCreateMenu(client)
{
	new Handle:menu = CreateMenu(FirstMenu_Handler);
	SetMenuTitle(menu, "Choose a section!");
	AddMenuItem(menu, "0", "L4D Campaigns");
	AddMenuItem(menu, "1", "L4D2 Campaigns");
	AddMenuItem(menu, "2", "Custom Campaigns");
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public FirstMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
					FirstMenu(param1);
				case 1:
					SecondMenu(param1);
				case 2:
					ThirdMenu(param1);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

FirstMenu(client)
{
	new Handle:menu = CreateMenu(Handle_MapVoteList);
	SetMenuTitle(menu, "L4D Campaigns:");

	if(strcmp(sGameName, "left4dead2", false) == 0)
	{
		if(strcmp(sGameMode, "coop", false) == 0)
		{
			AddMenuItem(menu, "c8m1_apartment", "No Mercy");
			AddMenuItem(menu, "c9m1_alleys", "Crash Course");
			AddMenuItem(menu, "c10m1_caves", "Death Toll");
			AddMenuItem(menu, "c11m1_greenhouse", "Dead Air");
			AddMenuItem(menu, "c12m1_hilltop", "Blood Harvest");
			AddMenuItem(menu, "c7m1_docks", "The Sacrifice");
		}
		else if(strcmp(sGameMode, "realism", false) == 0)
		{
			AddMenuItem(menu, "c8m1_apartment", "No Mercy");
			AddMenuItem(menu, "c9m1_alleys", "Crash Course");
			AddMenuItem(menu, "c10m1_caves", "Death Toll");
			AddMenuItem(menu, "c11m1_greenhouse", "Dead Air");
			AddMenuItem(menu, "c12m1_hilltop", "Blood Harvest");
			AddMenuItem(menu, "c7m1_docks", "The Sacrifice");
		}
		else if(strcmp(sGameMode, "versus", false) == 0)
		{
			AddMenuItem(menu, "c8m1_apartment", "No Mercy");
			AddMenuItem(menu, "c9m1_alleys", "Crash Course");
			AddMenuItem(menu, "c10m1_caves", "Death Toll");
			AddMenuItem(menu, "c11m1_greenhouse", "Dead Air");
			AddMenuItem(menu, "c12m1_hilltop", "Blood Harvest");
			AddMenuItem(menu, "c7m1_docks", "The Sacrifice");
		}
		
		else if(strcmp(sGameMode, "survival", false) == 0)
		{
			AddMenuItem(menu, "c7m1_docks ", "Docks");
			AddMenuItem(menu, "c7m3_port ", "Port");
			AddMenuItem(menu, "c8m2_subway ", "Subway");
			AddMenuItem(menu, "c8m5_rooftop ", "Rooftop");
			AddMenuItem(menu, "c9m2_lots ", "Lots");
		}
		else if(strcmp(sGameMode, "scavenge", false) == 0)
		{
			AddMenuItem(menu, "c7m1_docks", "Docks");
			AddMenuItem(menu, "c7m2_barge", "Barge");
			AddMenuItem(menu, "c8m1_apartment", "Apartment");
			AddMenuItem(menu, "c8m5_rooftop", "Rooftop");
			AddMenuItem(menu, "c9m1_alleys", "Alleys");
			AddMenuItem(menu, "c10m3_ranchhouse", "Ranch House");
			AddMenuItem(menu, "c11m4_terminal", "Terminal");
			AddMenuItem(menu, "c12m5_cornfield", "Cornfield");
		}
		else if(strcmp(sGameName, "left4dead", false) == 0)
		{
			if(strcmp(sGameMode, "coop", false) == 0)
			{
				AddMenuItem(menu, "l4d_hospital01_apartment", "Mercy Hospital");
				AddMenuItem(menu, "l4d_garage01_alleys", "Crash Course");
				AddMenuItem(menu, "l4d_smalltown01_caves", "Death Toll");
				AddMenuItem(menu, "l4d_airport01_greenhouse", "Dead Air");
				AddMenuItem(menu, "l4d_farm01_hilltop", "Blood Harvest");
			}
		}
		else if(strcmp(sGameMode, "versus", false) == 0)
		{
			AddMenuItem(menu, "l4d_vs_hospital01_apartment", "Mercy Hospital");
			AddMenuItem(menu, "l4d_garage01_alleys", "Crash Course");
			AddMenuItem(menu, "l4d_vs_smalltown01_caves", "Death Toll");
			AddMenuItem(menu, "l4d_vs_airport01_greenhouse", "Dead Air");
			AddMenuItem(menu, "l4d_vs_farm01_hilltop", "Blood Harvest");
		}
		else if(strcmp(sGameMode, "survival", false) == 0)
		{
			AddMenuItem(menu, "l4d_hospital02_subway", "Generator Room");
			AddMenuItem(menu, "l4d_hospital03_sewers", "Gas Station");
			AddMenuItem(menu, "l4d_hospital04_interior", "Hospital");
			AddMenuItem(menu, "l4d_vs_hospital05_rooftop", "Rooftop");
			AddMenuItem(menu, "l4d_garage01_alleys", "Bridge (crashcourse)");
			AddMenuItem(menu, "l4d_garage02_lots", "Truck Depot");
			AddMenuItem(menu, "l4d_smalltown02_drainage", "Drains");
			AddMenuItem(menu, "l4d_smalltown03_ranchhouse", "Church");
			AddMenuItem(menu, "l4d_smalltown04_mainstreet", "Street");
			AddMenuItem(menu, "l4d_vs_smalltown05_houseboat", "Boathouse");
			AddMenuItem(menu, "l4d_airport02_offices", "Crane");
			AddMenuItem(menu, "l4d_airport03_garage", "Construction Site");
			AddMenuItem(menu, "l4d_airport04_terminal", "Terminal");
			AddMenuItem(menu, "l4d_vs_airport05_runway", "Runway");
			AddMenuItem(menu, "l4d_farm02_traintunnel", "Warehouse");
			AddMenuItem(menu, "l4d_farm03_bridge", "Bridge (bloodharvest)");
			AddMenuItem(menu, "l4d_vs_farm05_cornfield", "Farmhouse");
			AddMenuItem(menu, "l4d_sv_lighthouse", "Lighthouse");
		}
	}	

	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

SecondMenu(client)
{
	new Handle:menu = CreateMenu(Handle_MapVoteList);
	SetMenuTitle(menu, "L4D2 Campaigns:");
	if(strcmp(sGameName, "left4dead2", false) == 0)
	{
		if(strcmp(sGameMode, "coop", false) == 0)
		{
			AddMenuItem(menu, "c1m1_hotel", "Dead Center");
			AddMenuItem(menu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(menu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(menu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(menu, "c5m1_waterfront", "The Parish");
			AddMenuItem(menu, "c6m1_riverbank", "The Passing");
			AddMenuItem(menu, "c13m1_alpinecreek", "Cold Stream");
		}
		else if(strcmp(sGameMode, "realism", false) == 0)
		{
			AddMenuItem(menu, "c1m1_hotel", "Dead Center");
			AddMenuItem(menu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(menu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(menu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(menu, "c5m1_waterfront", "The Parish");
			AddMenuItem(menu, "c6m1_riverbank", "The Passing");
			AddMenuItem(menu, "c13m1_alpinecreek", "Cold Stream");
		}
		else if(strcmp(sGameMode, "versus", false) == 0)
		{
			AddMenuItem(menu, "c1m1_hotel", "Dead Center");
			AddMenuItem(menu, "c2m1_highway", "Dark Carnival");
			AddMenuItem(menu, "c3m1_plankcountry", "Swamp Fever");
			AddMenuItem(menu, "c4m1_milltown_a", "Hard Rain");
			AddMenuItem(menu, "c5m1_waterfront", "The Parish");
			AddMenuItem(menu, "c6m1_riverbank", "The Passing");
			AddMenuItem(menu, "c13m1_alpinecreek", "Cold Stream");
		}
		
		else if(strcmp(sGameMode, "survival", false) == 0)
		{
			AddMenuItem(menu, "c1m4_atrium", "Atrium");
			AddMenuItem(menu, "c2m1_highway", "Highway");
			AddMenuItem(menu, "c2m4_barns", "Barns");
			AddMenuItem(menu, "c2m5_concert", "Concert");
			AddMenuItem(menu, "c3m1_plankcountry", "Plank Country");
			AddMenuItem(menu, "c3m4_plantation", "Plantation");
			AddMenuItem(menu, "c4m1_milltown_a", "Mill Town 1");
			AddMenuItem(menu, "c4m2_sugarmill_a", "Sugar Mill 1");
			AddMenuItem(menu, "c5m2_park", "Park");
			AddMenuItem(menu, "c5m5_bridge ", "Bridge");
			AddMenuItem(menu, "6m1_riverbank ", "Riverbank");
			AddMenuItem(menu, "c6m2_bedlam ", "Bedlam");
			AddMenuItem(menu, "c6m3_port ", "Port");
		}
		else if(strcmp(sGameMode, "scavenge", false) == 0)
		{
			AddMenuItem(menu, "c1m4_atrium", "Atrium");
			AddMenuItem(menu, "c2m1_highway", "Highway");
			AddMenuItem(menu, "c3m1_plankcountry", "Plank Country");
			AddMenuItem(menu, "c4m1_milltown_a", "Mill Town 1");
			AddMenuItem(menu, "c4m2_sugarmill_a", "Sugar Mill 1");
			AddMenuItem(menu, "c5m2_park", "Park");
			AddMenuItem(menu, "c6m1_riverbank", "Riverbank");
			AddMenuItem(menu, "c6m2_bedlam", "Bedlam");
			AddMenuItem(menu, "c6m3_port", "Port");
		}
	}	
	
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

ThirdMenu(client)
{
	new Handle:menu = CreateMenu(Handle_MapVoteList);
	
	SetMenuTitle(menu, "Custom Campaigns:");
	if(strcmp(sGameName, "left4dead2", false) == 0)
	{
		if(strcmp(sGameMode, "coop", false) == 0)
		{
			AddMenuItem(menu, "ADD UR MAP HERE", "ADD UR MAP NAME HERE");
		}
		else if(strcmp(sGameMode, "realism", false) == 0)
		{
			AddMenuItem(menu, "ADD UR MAP HERE", "ADD UR MAP NAME HERE");
		}
	}
	else if(strcmp(sGameName, "left4dead", false) == 0)
	{
		if(strcmp(sGameMode, "coop", false) == 0)
		{
			AddMenuItem(menu, "ADD UR MAP HERE", "ADD UR MAP NAME HERE");
		}
		else if(strcmp(sGameMode, "realism", false) == 0)
		{
			AddMenuItem(menu, "ADD UR MAP HERE", "ADD UR MAP NAME HERE");
		}
	}
	
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
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
	decl String:camp[65];
	
	ResetPack(dp);
	ReadPackString(dp, camp, sizeof(camp));
	
	ServerCommand("changelevel %s", camp);
	
	return Plugin_Stop;
}
