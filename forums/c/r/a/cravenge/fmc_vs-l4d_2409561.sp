#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

char sStockCamp[4][] =
{
	"l4d_hospital01_apartment",
	"l4d_smalltown01_caves",
	"l4d_airport01_greenhouse",
	"l4d_farm01_hilltop"
};

char sStockCampVS[4][] =
{
	"l4d_vs_hospital01_apartment",
	"l4d_vs_smalltown01_caves",
	"l4d_vs_airport01_greenhouse",
	"l4d_vs_farm01_hilltop"
};

char sStockCampNames[4][] =
{
	"No Mercy",
	"Death Toll",
	"Dead Air",
	"Blood Harvest"
};

char sDLCCamp[2][] =
{
	"l4d_garage01_alleys",
	"l4d_river01_docks"
};

char sDLCCampNames[2][] =
{
	"Crash Course",
	"The Sacrifice"
};

char sCustomCamp[24][] =
{
	"c1m1_hotel",
	"c6m1_riverbank",
	"c2m1_highway",
	"c3m1_plankcountry",
	"c4m1_milltown_a",
	"c5m1_waterfront",
	"l4d_city17_01",
	"l4d_stadium1_apartment",
	"l4d_149_01",
	"l4d_nt01_mansion",
	"l4d_deathaboard01_prison",
	"l4d_darkblood01_tanker",
	"l4d_dbd_citylights",
	"l4d_coaldblood01",
	"deathcraft_01_town",
	"l4d_viennacalling_city",
	"l4d_ravenholmwar_1",
	"l4d_grave_city",
	"redemption-plantworks",
	"l4d_fallen01_approach",
	"hotel01_market_two",
	"l4d_pbmesa01_surface",
	"l4d_auburn",
	"l4d_prototype_mk2_1"
};

char sCustomCampNames[24][] =
{
	"Dead Center (L4D1)",
	"The Passing (L4D1)",
	"Dark Carnival (L4D1)",
	"Swamp Fever (L4D1)",
	"Hard Rain (L4D1)",
	"The Parish (L4D1)",
	"City 17",
	"Suicide Blitz",
	"One 4 Nine",
	"Night Terror",
	"Death Aboard",
	"Dark Blood",
	"Dead Before Dawn",
	"Coal'd Blood",
	"Deathcraft",
	"Vienna Calling",
	"We Don't Go To Ravenholm",
	"The Grave Outdoors",
	"Redemption",
	"Fallen",
	"Dead Vacation",
	"Pitch Black Mesa",
	"Project Auburn",
	"Prototype Mark 2"
};

char sCustomCampVS[17][] =
{
	"c1m1_hotel",
	"c6m1_riverbank",
	"c2m1_highway",
	"c3m1_plankcountry",
	"c4m1_milltown_a",
	"c5m1_waterfront",
	"l4d_vs_city17_01",
	"l4d_vs_stadium1_apartment",
	"l4d_149_01",
	"l4d_nt01_mansion",
	"l4d_deathaboard01_prison",
	"l4d_darkblood01_tanker",
	"l4d_dbd_citylights",
	"l4d_coaldblood01",
	"l4d_ravenholmwar_1",
	"l4d_fallen01_approach",
	"l4d_pbmesa01_surface"
};

char sCustomCampNamesVS[17][] =
{
	"Dead Center (L4D1)",
	"The Passing (L4D1)",
	"Dark Carnival (L4D1)",
	"Swamp Fever (L4D1)",
	"Hard Rain (L4D1)",
	"The Parish (L4D1)",
	"City 17",
	"Suicide Blitz",
	"One 4 Nine",
	"Night Terror",
	"Death Aboard",
	"Dark Blood",
	"Dead Before Dawn",
	"Coal'd Blood",
	"We Don't Go To Ravenholm",
	"Fallen",
	"Pitch Black Mesa"
};

char sCurrentMap[64], sNextCamp[64], sNextMap[64], sLastVotedCamp[64], sLastVotedMap[64],
	sVotedCamp[64], sVotedMap[64], sFirstMap[64], sGameMode[16];

int iFMCVoteDuration;
bool voteInitiated, bFMCEnabled, bFMCIgnoreFail, bFMCAnnounce, bFMCIncludeCurrent, bFMCIncludeLast;
ConVar hFMCEnabled, hFMCIgnoreFail, hFMCAnnounce, hFMCIncludeCurrent, hFMCIncludeLast,
	hFMCVoteDuration;

public Plugin myinfo = 
{
	name = "[L4D] Force Mission Changer + Voting System",
	author = "cravenge",
	description = "Forcefully Changes To Voted Campaign After Winning Finale.",
	version = "2.07",
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("fmc+vs-l4d_version", "2.07", "Force Mission Changer + Voting System Version", FCVAR_NOTIFY|FCVAR_SPONLY);
	hFMCEnabled = CreateConVar("fmc+vs-l4d_enable", "1", "Enable/Disable Plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	hFMCIgnoreFail = CreateConVar("fmc+vs-l4d_ignore_fail", "1", "Ignore/Mind Fail When Forcing Campaign Changes", FCVAR_NOTIFY|FCVAR_SPONLY);
	hFMCAnnounce = CreateConVar("fmc+vs_announce", "1", "Enable/Disable Announcements", FCVAR_NOTIFY|FCVAR_SPONLY);
	hFMCVoteDuration = CreateConVar("fmc+vs_vote_duration", "60", "Duration Of Campaign Voting", FCVAR_NOTIFY|FCVAR_SPONLY);
	hFMCIncludeCurrent = CreateConVar("fmc+vs_include_current", "0", "Include/Exclude Current Campaign From Being Voted", FCVAR_NOTIFY|FCVAR_SPONLY);
	hFMCIncludeLast = CreateConVar("fmc+vs_include_last", "0", "Include/Exclude Last Campaign From Being Voted", FCVAR_NOTIFY|FCVAR_SPONLY);
	
	bFMCEnabled = hFMCEnabled.BoolValue;
	bFMCIgnoreFail = hFMCIgnoreFail.BoolValue;
	bFMCAnnounce = hFMCAnnounce.BoolValue;
	bFMCIncludeCurrent = hFMCIncludeCurrent.BoolValue;
	bFMCIncludeLast = hFMCIncludeLast.BoolValue;
	
	iFMCVoteDuration = hFMCVoteDuration.IntValue;
	
	HookConVarChange(hFMCEnabled, OnFMCCVarsChanged);
	HookConVarChange(hFMCIgnoreFail, OnFMCCVarsChanged);
	HookConVarChange(hFMCAnnounce, OnFMCCVarsChanged);
	HookConVarChange(hFMCIncludeCurrent, OnFMCCVarsChanged);
	HookConVarChange(hFMCIncludeLast, OnFMCCVarsChanged);
	HookConVarChange(hFMCVoteDuration, OnFMCCVarsChanged);
	
	AutoExecConfig(true, "fmc+vs-l4d");
	
	FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("finale_win", OnFinaleWin);
	HookEvent("mission_lost", OnMissionLost);
	HookEvent("versus_final_score", OnVersusFinalScore);
	
	RegConsoleCmd("sm_fmc+vs_menu", ShowVoteMenu, "Shows Menu Of Available And Vote-able Campaigns");
	RegConsoleCmd("sm_fmc+vs_menu_custom", ShowVoteMenuCustom, "Shows Menu Of Available And Vote-able Custom Campaigns");
}

public void OnFMCCVarsChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bFMCEnabled = hFMCEnabled.BoolValue;
	bFMCIgnoreFail = hFMCIgnoreFail.BoolValue;
	bFMCAnnounce = hFMCAnnounce.BoolValue;
	bFMCIncludeCurrent = hFMCIncludeCurrent.BoolValue;
	bFMCIncludeLast = hFMCIncludeLast.BoolValue;
	
	iFMCVoteDuration = hFMCVoteDuration.IntValue;
}

public Action ShowVoteMenu(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Finales Only!");
		return Plugin_Handled;
	}
	
	if (StrEqual(sGameMode, "versus", false) && !GameRules_GetProp("m_bInSecondHalfOfRound"))
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Second Round Only!");
		return Plugin_Handled;
	}
	
	AdminId clientId = GetUserAdmin(client);
	if (clientId == INVALID_ADMIN_ID)
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Invalid Access!");
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Vote In Progress!");
		return Plugin_Handled;
	}
	
	FMCMenu();
	return Plugin_Handled;
}

public Action ShowVoteMenuCustom(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Finales Only!");
		return Plugin_Handled;
	}
	
	if (StrEqual(sGameMode, "versus", false) && !GameRules_GetProp("m_bInSecondHalfOfRound"))
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Second Round Only!");
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		PrintToChat(client, "\x04[FMC+VS]\x03 Vote In Progress!");
		return Plugin_Handled;
	}
	
	FMCMenu(true);
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if (!bFMCEnabled || !bFMCAnnounce || IsFakeClient(client))
	{
		return;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		return;
	}
	
	CreateTimer(1.0, InformOfCC, client, TIMER_REPEAT);
}

public Action InformOfCC(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	PrintToChat(client, "\x04[FMC+VS]\x03 To Vote For Custom Campaigns, Type \x05!fmc+vs_menu_custom");
	return Plugin_Stop;
}

public void OnMapStart()
{
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	
	voteInitiated = false;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!bFMCEnabled)
	{
		return Plugin_Continue;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		return Plugin_Continue;
	}
	
	if ((StrEqual(sGameMode, "versus", false) && GameRules_GetProp("m_bInSecondHalfOfRound") && !voteInitiated) || (StrEqual(sGameMode, "coop", false) && !voteInitiated))
	{
		sNextCamp[0] = '\0';
		sNextMap[0] = '\0';
		
		CreateTimer(30.0, AnnounceNextCamp);
		CreateTimer(60.0, VoteCampaignDelay);
	}
	
	return Plugin_Continue;
}

public Action AnnounceNextCamp(Handle timer)
{
	PrintToChatAll("\x04[FMC+VS]\x03 This Is The Finale!");
	if (!StrEqual(sVotedMap, "", false))
	{
		PrintToChatAll("\x04[FMC+VS]\x03 Next Map: %s |%s|", sVotedMap, sVotedCamp);
	}
	else
	{
		FMC_GetNextCampaign(sCurrentMap);
		PrintToChatAll("\x04[FMC+VS]\x03 Next Map: %s |%s|", sNextMap, sNextCamp);
	}
	return Plugin_Stop;
}

public Action VoteCampaignDelay(Handle timer)
{
	if (voteInitiated)
	{
		return Plugin_Stop;
	}
	
	voteInitiated = true;
	
	CreateTimer(5.0, ReadyVoteMenu);
	PrintToChatAll("\x04[FMC+VS]\x03 Campaign Vote In 5..");
	
	return Plugin_Stop;
}

public Action ReadyVoteMenu(Handle timer)
{
	PrintToChatAll("\x04[FMC+VS]\x03 Starting Campaign Vote!");
	FMCMenu();
	
	return Plugin_Stop;
}

void FMCMenu(bool bCustom = false)
{
	Menu voteMenu = new Menu(voteMenuHandler);
	voteMenu.SetTitle("Next Campaign Vote:");
	
	if (StrEqual(sVotedMap, "", false))
	{
		voteMenu.AddItem(sNextMap, sNextCamp);
	}
	else
	{
		voteMenu.AddItem(sVotedMap, sVotedCamp);
	}
	
	if (!bCustom)
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			for (int i = 0; i < 4; i++)
			{
				if (StrEqual(sNextMap, sStockCamp[i], false) || (!bFMCIncludeCurrent && StrEqual(sFirstMap, sStockCamp[i], false)) || (!bFMCIncludeLast && StrEqual(sLastVotedMap, sStockCamp[i], false)))
				{
					continue;
				}
				
				voteMenu.AddItem(sStockCamp[i], sStockCampNames[i]);
			}
		}
		else
		{
			for (int i = 0; i < 4; i++)
			{
				if (StrEqual(sNextMap, sStockCampVS[i], false) || (!bFMCIncludeCurrent && StrEqual(sFirstMap, sStockCampVS[i], false)) || (!bFMCIncludeLast && StrEqual(sLastVotedMap, sStockCampVS[i], false)))
				{
					continue;
				}
				
				voteMenu.AddItem(sStockCampVS[i], sStockCampNames[i]);
			}
		}
		
		for (int i = 0; i < 2; i++)
		{
			if (StrEqual(sNextMap, sDLCCamp[i], false) || (!bFMCIncludeCurrent && StrEqual(sFirstMap, sDLCCamp[i], false)) || (!bFMCIncludeLast && StrEqual(sLastVotedMap, sDLCCamp[i], false)))
			{
				continue;
			}
			
			voteMenu.AddItem(sDLCCamp[i], sDLCCampNames[i]);
		}
	}
	else
	{
		if (StrEqual(sGameMode, "versus", false))
		{
			for (int i = 0; i < 17; i++)
			{
				if (!IsMapValid(sCustomCampVS[i]) || StrEqual(sNextMap, sCustomCampVS[i], false) || (!bFMCIncludeCurrent && StrEqual(sFirstMap, sCustomCampVS[i], false)) || (!bFMCIncludeLast && StrEqual(sLastVotedMap, sCustomCampVS[i], false)))
				{
					continue;
				}
				
				voteMenu.AddItem(sCustomCampVS[i], sCustomCampNamesVS[i]);
			}
		}
		else
		{
			for (int i = 0; i < 24; i++)
			{
				if (!IsMapValid(sCustomCamp[i]) || StrEqual(sNextMap, sCustomCamp[i], false) || (!bFMCIncludeCurrent && StrEqual(sFirstMap, sCustomCamp[i], false)) || (!bFMCIncludeLast && StrEqual(sLastVotedMap, sCustomCamp[i], false)))
				{
					continue;
				}
				
				voteMenu.AddItem(sCustomCamp[i], sCustomCampNames[i]);
			}
		}
	}
	
	voteMenu.ExitButton = false;
	voteMenu.VoteResultCallback = voteMenuResult;
	voteMenu.DisplayVoteToAll(iFMCVoteDuration);
}

public int voteMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public void voteMenuResult(
	Menu menu,
	int num_votes,
	int num_clients,
	const int[][] client_info,
	int num_items,
	const int[][] item_info
)
{
	int majorityItem = 0;
	if (num_items >= 2)
	{
		int i = 1;
		while (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[i][VOTEINFO_ITEM_VOTES])
		{
			i += 1;
		}
		
		if (i >= 2)
		{
			majorityItem = GetRandomInt(0, i - 1);
		}
	}
	
	menu.GetItem(item_info[majorityItem][VOTEINFO_ITEM_INDEX], sVotedMap, sizeof(sVotedMap), _, sVotedCamp, sizeof(sVotedCamp));
	PrintToChatAll("\x04[FMC+VS]\x03 Most Voted Campaign: %s (%s) \x05[%d Votes]", sVotedCamp, sVotedMap, item_info[majorityItem][VOTEINFO_ITEM_VOTES]);
	
	strcopy(sLastVotedCamp, sizeof(sLastVotedCamp), sVotedCamp);
	strcopy(sLastVotedMap, sizeof(sLastVotedMap), sVotedMap);
	
	if (bFMCAnnounce)
	{
		CreateTimer(5.0, AnnounceNextCamp);
	}
}

public Action OnFinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	if (!bFMCEnabled || !StrEqual(sGameMode, "coop", false))
	{
		return Plugin_Continue;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		return Plugin_Continue;
	}
	
	CreateTimer(9.0, ForceNextCampaign);
	return Plugin_Continue;
}

public Action OnMissionLost(Event event, const char[] name, bool dontBroadcast)
{
	if (!bFMCEnabled || bFMCIgnoreFail || !StrEqual(sGameMode, "coop", false))
	{
		return Plugin_Continue;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		return Plugin_Continue;
	}
	
	CreateTimer(5.0, ForceNextCampaign);
	return Plugin_Continue;
}

public Action ForceNextCampaign(Handle timer)
{
	if (StrEqual(sVotedMap, "", false))
	{
		FMC_GetNextCampaign(sCurrentMap);
		ServerCommand("changelevel %s", sNextMap);
	}
	else
	{
		ServerCommand("changelevel %s", sVotedMap);
	}
	return Plugin_Stop;
}

public Action OnVersusFinalScore(Event event, const char[] name, bool dontBroadcast)
{
	if (!bFMCEnabled || !StrEqual(sGameMode, "versus", false))
	{
		return Plugin_Continue;
	}
	
	if (!IsFinalMap() && !AreSpecialMaps())
	{
		return Plugin_Continue;
	}
	
	if (GameRules_GetProp("m_bInSecondHalfOfRound"))
	{
		CreateTimer(12.0, ForceNextCampaign);
	}
	return Plugin_Continue;
}

bool IsFinalMap()
{
	if (StrEqual(sCurrentMap, "c5m2_park", false) || StrEqual(sCurrentMap, sCustomCamp[10], false))
	{
		return false;
	}
	
	for (int i = 1; i <= GetMaxEntities(); i++)
	{
		if (!IsValidEntity(i) || !IsValidEdict(i))
		{
			continue;
		}
		
		char entname[50];
		GetEdictClassname(i, entname, sizeof(entname));
		if (StrContains(entname, "trigger_finale") != -1)
		{
			return true;
		}
	}
	
	return false;	
}

bool AreSpecialMaps()
{
	return (StrEqual(sCurrentMap, "c4m5_milltown_escape", false) || StrEqual(sCurrentMap, "c5m5_bridge", false) || StrEqual(sCurrentMap, "l4d_stadium5_stadium", false) || 
		StrEqual(sCurrentMap, "l4d_darkblood04_extraction", false));
}

void FMC_GetNextCampaign(const char[] sMap)
{
	if (StrEqual(sMap, "l4d_hospital05_rooftop", false) || StrEqual(sMap, "l4d_vs_hospital05_rooftop", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sDLCCampNames[0]);
		strcopy(sNextMap, sizeof(sNextMap), sDLCCamp[0]);
		
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sFirstMap, sizeof(sFirstMap), sStockCamp[0]);
		}
		else
		{
			strcopy(sFirstMap, sizeof(sFirstMap), sStockCampVS[0]);
		}
	}
	else if (StrEqual(sMap, "l4d_garage02_lots", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sStockCampNames[1]);
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextMap, sizeof(sNextMap), sStockCamp[1]);
		}
		else
		{
			strcopy(sNextMap, sizeof(sNextMap), sStockCampVS[1]);
		}
		
		strcopy(sFirstMap, sizeof(sFirstMap), sDLCCamp[0]);
	}
	else if (StrEqual(sMap, "l4d_smalltown05_houseboat", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sStockCampNames[2]);
		strcopy(sNextMap, sizeof(sNextMap), sStockCamp[2]);
		
		strcopy(sFirstMap, sizeof(sFirstMap), sStockCamp[1]);
	}
	else if (StrEqual(sMap, "l4d_airport05_runway", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sStockCampNames[3]);
		strcopy(sNextMap, sizeof(sNextMap), sStockCamp[3]);
		
		strcopy(sFirstMap, sizeof(sFirstMap), sStockCamp[2]);
	}
	else if (StrEqual(sMap, "l4d_farm05_cornfield", false) || StrEqual(sMap, "l4d_vs_farm05_cornfield", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sDLCCampNames[1]);
		strcopy(sNextMap, sizeof(sNextMap), sDLCCamp[1]);
		
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sFirstMap, sizeof(sFirstMap), sStockCamp[3]);
		}
		else
		{
			strcopy(sFirstMap, sizeof(sFirstMap), sStockCampVS[3]);
		}
	}
	else if (StrEqual(sMap, "l4d_vs_smalltown05_houseboat", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sStockCampNames[2]);
		strcopy(sNextMap, sizeof(sNextMap), sStockCampVS[2]);
		
		strcopy(sFirstMap, sizeof(sFirstMap), sStockCampVS[1]);
	}
	else if (StrEqual(sMap, "l4d_vs_airport05_runway", false))
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sStockCampNames[3]);
		strcopy(sNextMap, sizeof(sNextMap), sStockCampVS[3]);
		
		strcopy(sFirstMap, sizeof(sFirstMap), sStockCampVS[2]);
	}
	else if (StrEqual(sMap, "c1m4_atrium", false))
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNames[1]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCamp[1]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCamp[0]);
		}
		else
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNamesVS[1]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCampVS[1]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCampVS[0]);
		}
	}
	else if (StrEqual(sMap, "c6m3_port", false))
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNames[2]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCamp[2]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCamp[1]);
		}
		else
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNamesVS[2]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCampVS[2]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCampVS[1]);
		}
	}
	else if (StrEqual(sMap, "c2m5_concert", false))
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNames[3]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCamp[3]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCamp[2]);
		}
		else
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNamesVS[3]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCampVS[3]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCampVS[2]);
		}
	}
	else if (StrEqual(sMap, "c3m4_plantation", false))
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNames[4]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCamp[4]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCamp[3]);
		}
		else
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNamesVS[4]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCampVS[4]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCampVS[3]);
		}
	}
	else if (StrEqual(sMap, "c4m5_milltown_escape", false))
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNames[5]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCamp[5]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCamp[4]);
		}
		else
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNamesVS[5]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCampVS[5]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCampVS[4]);
		}
	}
	else if (StrEqual(sMap, "c5m5_bridge", false))
	{
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNames[0]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCamp[0]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCamp[4]);
		}
		else
		{
			strcopy(sNextCamp, sizeof(sNextCamp), sCustomCampNamesVS[0]);
			strcopy(sNextMap, sizeof(sNextMap), sCustomCampVS[0]);
			
			strcopy(sFirstMap, sizeof(sFirstMap), sCustomCampVS[4]);
		}
	}
	else
	{
		strcopy(sNextCamp, sizeof(sNextCamp), sStockCampNames[0]);
		if (StrEqual(sGameMode, "coop", false))
		{
			strcopy(sNextMap, sizeof(sNextMap), sStockCamp[0]);
		}
		else
		{
			strcopy(sNextMap, sizeof(sNextMap), sStockCampVS[0]);
		}
	}
}

