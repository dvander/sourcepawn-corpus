#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2.5"

public Plugin:myinfo =
{
	name = "Players Votes",
	author = "pZv!, The Resident",
	description = "Votekick, Voteban & Votemap",
	version = PLUGIN_VERSION,
	url = ""
};

#define KICK      0
#define BAN       1
#define MAP       2	//NOTE:  MAP must always be the LAST enumeral for the sake of g_bVotedFor!

// ============================================================
// [KICK] [Voter] [User To Be Kicked]
// [BAN]  [Voter] [User To Be Banned]
// ============================================================
new bool:g_bVotedFor[2][MAXPLAYERS+1][MAXPLAYERS+1];

// ============================================================
// [Voter] Dyn(dynamic map array index) == 1 if voting for indexed map
// ============================================================
new Handle:g_hVotedForMap[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new g_nLastVote[MAXPLAYERS+1];                                   // Last time each client voted.

new Handle:g_hVoteRatio[3]   = {INVALID_HANDLE, ...};
new Handle:g_hVoteMinimum[3] = {INVALID_HANDLE, ...};
new Handle:g_hVoteDelay[3]   = {INVALID_HANDLE, ...};
new Handle:g_hVoteBanTime    = INVALID_HANDLE;
new Handle:g_hVoteImmunity   = INVALID_HANDLE;
new Handle:g_hVotesInterval  = INVALID_HANDLE;

new Handle:g_hLastMaps               = INVALID_HANDLE;    // Array
new Handle:g_hMapList                = INVALID_HANDLE;    // Array
new Handle:g_hMapExtendTime          = INVALID_HANDLE;    // custom con var
new Handle:g_hMapMaxExtends          = INVALID_HANDLE;	  // custom con var
new Handle:g_hMapTimeLimit           = INVALID_HANDLE;    // source con var
new String:g_sMapListConfigSection[] = "playersvotes";
new        g_nMapListSerial          = -1;
new        g_nMapExtends;
new        g_nMapCurrent;                                 // index into g_hMapList of the current map.  -1 if not in list.

new Handle:g_hVoteMapLast = INVALID_HANDLE;

new g_nStartTime;

new bool:g_bVoteAction;

public OnPluginStart()
{
	LoadTranslations("plugin.playersvotes.txt");

	CreateConVar("sm_playersvotes_version", PLUGIN_VERSION, "Players Votes Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hVoteRatio[KICK] = CreateConVar("sm_votekick_ratio", "0.60", "percent required for successful votekick.", 0, true, 0.0, true, 1.0);
	g_hVoteRatio[BAN]  = CreateConVar("sm_voteban_ratio",  "0.80", "percent required for successful voteban.",  0, true, 0.0, true, 1.0);
	g_hVoteRatio[MAP]  = CreateConVar("sm_votemap_ratio",  "0.60", "percent required for successful votemap.",  0, true, 0.0, true, 1.0);

	g_hVoteMinimum[KICK] = CreateConVar("sm_votekick_minimum", "4.0", "minimum votes required for successful votekick. -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[BAN]  = CreateConVar("sm_voteban_minimum",  "4.0", "minimum votes required for successful voteban.  -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[MAP]  = CreateConVar("sm_votemap_minimum",  "4.0", "minimum votes required for successful votemap.  -1 to disable voting", 0, true, -1.0, true, 64.0);

	g_hVoteDelay[KICK] = CreateConVar("sm_votekick_delay", "60.0", "time before votekick is allowed after map start", 0, true, 0.0, true, 1000.0);
	g_hVoteDelay[BAN]  = CreateConVar("sm_voteban_delay",  "60.0", "time before voteban is allowed after map start",  0, true, 0.0, true, 1000.0);
	g_hVoteDelay[MAP]  = CreateConVar("sm_votemap_delay",  "60.0", "time before votemap is allowed after map start",  0, true, 0.0, true, 1000.0);

	g_hVoteMapLast   = CreateConVar("sm_votemap_lastmaps",     "4.0", "last number of played maps that will not show in votemap list",                           0, true,  0.0, true,  64.0);
	g_hMapExtendTime = CreateConVar("sm_votemap_extend",      "20.0", "number of minutes to add to the timelimit if the players vote to extend.  -1 to disable", 0, true, -1.0, true, 120.0);
	g_hMapMaxExtends = CreateConVar("sm_votemap_max_extends",  "1.0", "number of extensions to allow per map.  -1 for no limit",                                 0, true, -1.0, true, 100.0);
	g_hMapTimeLimit  = FindConVar ("mp_timelimit");

	g_hVotesInterval = CreateConVar("sm_playersvotes_interval", "15.0", "interval between another vote cast", 0, true, 0.0, true, 60.0);

	g_hVoteBanTime = CreateConVar("sm_voteban_time", "25.0", "ban time in minutes|0-permanently");

	g_hVoteImmunity = CreateConVar("sm_playersvotes_immunity", "1.0", "admins with equal or higher immunity level will not be affected by votekick and voteban", 0, true, 0.0, true, 99.0);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegConsoleCmd("sm_mapshistory", cmdMapsHistory);

	HookConVarChange (g_hMapMaxExtends, SetMapExtends);
	//HookConVarChange(g_hVoteMapLast, RefreshMapsList);

	if(g_hMapList == INVALID_HANDLE)
	{
		g_hMapList = CreateArray(33);
	}
	if(g_hLastMaps == INVALID_HANDLE)
	{
		g_hLastMaps = CreateArray(33);
	}

	for (new i = 0; i <= MAXPLAYERS; ++i)
	{
		if (g_hVotedForMap[i] == INVALID_HANDLE)
		{
			g_hVotedForMap[i] = CreateArray();
		}
	}

	AutoExecConfig(false);
}


ResetClientMapVotes (client)
{
	new mapCount = GetArraySize (g_hVotedForMap[client]);
	for (new target = 0; target < mapCount; ++target)
	{
		SetArrayCell (g_hVotedForMap[client], target, 0);
	}

}


ResetVotes (type)
{
	switch (type)
	{
		// For valid vote types, reset all clients' votes.
		case KICK, BAN:
		{
			for (new client = 0; client <= MAXPLAYERS; ++client)
			{
				for (new target = 0; target <= MAXPLAYERS; ++target)
				{
					g_bVotedFor[type][client][target] = false;
				}
			}
		}

		case MAP:
		{
			new mapCount = GetArraySize (g_hMapList);

			for (new client = 0; client <= MAXPLAYERS; ++client)
			{
				ResizeArray (g_hVotedForMap[client], mapCount);

				ResetClientMapVotes (client);
			}
		}

		// Invalid type, do nothing.
		default:
		{
		}
	}
}


public SetMapExtends(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_nMapExtends = StringToInt (newValue);
}

public RefreshMapsList()
{
	ReadMapList
		(g_hMapList,
		g_nMapListSerial,
		g_sMapListConfigSection,
		MAPLIST_FLAG_CLEARARRAY | MAPLIST_FLAG_MAPSFOLDER);

	ResetVotes (MAP);

}

public OnConfigsExecuted()
{

	RefreshMapsList();

	new num = GetArraySize(g_hMapList);

	decl String:sMap[64], String:sMapListEntry[65];
	GetCurrentMap(sMap, sizeof(sMap));

	// Record the index of the current map.
	g_nMapCurrent = -1;

	for(new i = 0; i < num; i++)
	{
		GetArrayString(g_hMapList, i, sMapListEntry, sizeof(sMapListEntry));
		if (StrEqual (sMapListEntry, sMap, false) == true)
		{
			g_nMapCurrent = i;
		}
	}

	// Reset the map extends.
	g_nMapExtends = GetConVarInt (g_hMapMaxExtends);
}


public OnMapStart()
{
	g_nStartTime = GetTime();

	// Record this new map into the queue of last-played maps.
	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	PushArrayString(g_hLastMaps, sMap);
	if(GetArraySize(g_hLastMaps) > 64)
	{
		RemoveFromArray(g_hLastMaps, 0);
	}

	// Make sure any old votes don't survive the map change.
	ResetVotes (KICK);
	ResetVotes (BAN);
	ResetVotes (MAP);

}

public OnClientDisconnect(client)
{
	g_nLastVote[client] = 0;

	for(new type = 0; type < 2; type++)
	{
		for(new i = 0; i <= MAXPLAYERS; i++)
		{
			// Get rid of this player's votes.
			g_bVotedFor[type][client][i] = false;

			// Get rid of any other player's votes against this guy.
			// Note that this is okay beacuse this line won't be run for the MAP votes.
			g_bVotedFor[type][i][client] = false;
		}
	}

	// Now clear the player's map votes.
	ResetClientMapVotes (client);

}

bool:IsLastPlayed(const String:sMap[])
{
	decl String:sMap2[64];

	new numberToCheck    = GetConVarInt(g_hVoteMapLast);
	new endOfLastMapList = GetArraySize(g_hLastMaps);
	new oldestMapToCheck = endOfLastMapList - numberToCheck;

	if (oldestMapToCheck < 0)
	{
		oldestMapToCheck = 0;
	}

	for (new i = oldestMapToCheck; i < endOfLastMapList; ++i)
	{
		GetArrayString(g_hLastMaps, i, sMap2, sizeof(sMap2));
		if(StrEqual(sMap2, sMap, false))
			return true;
	}
	return false;
}

bool:IsImmune (target)
{
	return (GetUserAdmin(target) != INVALID_ADMIN_ID);
}

public Action:cmdMapsHistory(client, args)
{
	decl String:sMap[64];
	new size = GetArraySize(g_hLastMaps)-1;

	for(new i = size; i >= 0; i--)
	{
		GetArrayString(g_hLastMaps, i, sMap, sizeof(sMap));
		PrintToConsole(client, "%d. > %s", i+1, sMap);
	}
	return Plugin_Handled;
}


public Action:Command_Say(client, args)
{
	if(g_bVoteAction || client == 0)
	{
		return Plugin_Continue;
	}

	decl String:text[192], String:command[64];
	new startidx = 0;

	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	GetCmdArg(0, command, sizeof(command));
	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	new nFromStart = GetTime() - g_nStartTime;
	new nFromLast = GetTime() - g_nLastVote[client];	

	if (strcmp(text[startidx], "votekick", false) == 0)
	{
		if(nFromLast >= GetConVarInt(g_hVotesInterval))
		{
			if(nFromStart >= GetConVarInt(g_hVoteDelay[KICK]))
			{
				if(GetConVarInt(g_hVoteMinimum[KICK]) > -1)
				{
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, KICK);
				}
				else
				{
					PrintToChat(client, "[%t] %t", "Votekick", "is disabled");
				}
			}
			else
			{
				PrintToChat(client, "[%t] %t", "Votekick", "voting not allowed", GetConVarInt(g_hVoteDelay[KICK]) - nFromStart);
			}
		}
		else
		{
			PrintToChat(client, "[%t] %t", "Votekick", "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
		}
	}
	else if (strcmp(text[startidx], "voteban", false) == 0)
	{
		if(nFromLast >= GetConVarInt(g_hVotesInterval))
		{
			if(nFromStart >= GetConVarInt(g_hVoteDelay[BAN]))
			{
				if(GetConVarInt(g_hVoteMinimum[BAN]) > -1)
				{
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, BAN);
				}
				else
				{
					PrintToChat(client, "[%t] %t", "Voteban", "is disabled");
				}
			}
			else
			{
				PrintToChat(client, "[%t] %t", "Voteban", "voting not allowed", GetConVarInt(g_hVoteDelay[BAN]) - nFromStart);
			}
		}
		else
		{
			PrintToChat(client, "[%t] %t", "Voteban", "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
		}
	}
	else if (strcmp(text[startidx], "votemap", false) == 0)
	{
		if(nFromLast >= GetConVarInt(g_hVotesInterval))
		{
			if(nFromStart >= GetConVarInt(g_hVoteDelay[MAP]))
			{
				if(GetConVarInt(g_hVoteMinimum[MAP]) > -1)
				{
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, MAP);
				}
				else
				{
					PrintToChat(client, "[%t] %t", "Votemap", "is disabled");
				}
			}
			else
			{
				PrintToChat(client, "[%t] %t", "Votemap", "voting not allowed", GetConVarInt(g_hVoteDelay[MAP]) - nFromStart);
			}
		}
		else
		{
			PrintToChat(client, "[%t] %t", "Votemap", "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
		}
	}
	return Plugin_Continue;
}

DisplayVoteMenu(client, type)
{
	new Handle:hVoteMenu;
	hVoteMenu = CreateMenu(Handler_VoteMenu);

	decl String:sPrefix[1], String:sTitle[32];

	switch(type)
	{
		case KICK:
		{
			Format(sTitle, sizeof(sTitle), "%t:", "Votekick");
			SetMenuTitle(hVoteMenu, sTitle);
			sPrefix[0] = 'k';
		}
		case BAN:
		{
			Format(sTitle, sizeof(sTitle), "%t:", "Voteban");
			SetMenuTitle(hVoteMenu, sTitle);
			sPrefix[0] = 'b';
		}
		case MAP:
		{
			Format(sTitle, sizeof(sTitle), "%t:", "Votemap");
			SetMenuTitle(hVoteMenu, sTitle);
			sPrefix[0] = 'm';
		}
		default:
		{
			CloseHandle(hVoteMenu);
			return;
		}
	}

	if(type == MAP)
	{
		decl String:sMap[65], String:sPos[4];

		new num = GetArraySize(g_hMapList);
		new required, votes;

		for(new i = 0; i < num; i++)
		{
			GetArrayString(g_hMapList, i, sMap, sizeof(sMap));

			if(IsMapValid(sMap))
			{

				// If map extensions are enabled and not used up, and the current map is in the list,
				// add a map extension vote item.
				if (g_nMapCurrent == i && g_nMapExtends != 0 && GetConVarFloat (g_hMapExtendTime) > 0.0)
				{
					votes = VotesFor(i, type, required);

					Format(sPos, sizeof(sPos), "%s%d", sPrefix, i);
					Format(sMap, sizeof(sMap), "%t [%d/%d]", "extend map by", GetConVarInt (g_hMapExtendTime), votes, required);

					// FIXME:  SourceMod Bug?  InsertMenuItem doesn't appear to work if there are no other menu items.
					if (g_nMapCurrent == 0)
					{
						AddMenuItem(hVoteMenu, sPos, sMap);
					}
					else
					{
						InsertMenuItem (hVoteMenu, 0, sPos, sMap);
					}

				}
				// Otherwise if this is not one of the last-played maps, list it for a map change vote.
				else if (IsLastPlayed(sMap) == false)
				{
					votes = VotesFor(i, type, required);

					Format(sPos, sizeof(sPos), "%s%d", sPrefix, i);
					Format(sMap, sizeof(sMap), "%s [%d/%d]", sMap, votes, required);

					AddMenuItem(hVoteMenu, sPos, sMap);
				}
			}
		}
	}
	else
	{
		decl String:sName[72], String:sClient[4]; 

		new num = GetMaxClients(), flags;
		new required, votes;

		for(new i = 1; i <= num; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			if(IsFakeClient(i))
			{
				continue;
			}

			// FIXME:  Disabled doesn't appear to work, at least under HL2DM.
			// Don't let players vote against themselves or immune admins.
			if(i == client || IsImmune(i))
			{
				flags = ITEMDRAW_DISABLED;
			}
			else
			{
				flags = ITEMDRAW_DEFAULT;
			}

			votes = VotesFor(i, type, required);

			Format(sClient, sizeof(sClient), "%s%d", sPrefix, i);
			Format(sName, sizeof(sName), "%N [%d/%d]", i, votes, required);

			AddMenuItem(hVoteMenu, sClient, sName, flags);
		}

	}
	SetMenuExitButton(hVoteMenu, true);
	DisplayMenu(hVoteMenu, client, 30);
}

public Handler_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:sUserId[4];
		new target, type;
		GetMenuItem(menu, param2, sUserId, sizeof(sUserId), _, "", 0);

		if     (sUserId[0] == 'k') type = KICK;
		else if(sUserId[0] == 'b') type = BAN;
		else if(sUserId[0] == 'm') type = MAP;

		target = StringToInt(sUserId[1]);

		if(type == MAP)
		{
			// Get rid of any prior map vote this client has.
			ResetClientMapVotes (param1);

			// Set their single vote to the target map.
			SetArrayCell (g_hVotedForMap[param1], target, 1);

			CheckVotes(param1, target, type);
		}
		else
		{
			if(target > 0)
			{
				if(IsClientInGame(target) && !IsFakeClient(target))
				{
					g_bVotedFor[type][param1][target] = true;
					CheckVotes(param1, target, type);
				}
			}
		}
	}
}

CheckVotes(voter, target, type)
{
	new VotesRequired;
	new Votes = VotesFor(target, type, VotesRequired);
	decl String:sVoterName[65], String:sTargetName[65];

	GetClientName(voter, sVoterName, sizeof(sVoterName));

	if(type == KICK || type == BAN)
	{		
		GetClientName(target, sTargetName, sizeof(sTargetName));
	}

	if(type == KICK)
	{
		PrintToChatAll("[%t] %t", "Votekick", "voted to kick", sVoterName, sTargetName);
		PrintToChatAll("[%t] %t", "Votekick", "votes required", Votes, VotesRequired);

		if(Votes >= VotesRequired)
		{
			if (! IsImmune(target))
			{
				PrintToChatAll("[%t] %t", "Votekick", "kicked by vote", sTargetName);
				LogAction(-1, target, "Vote kick successful, kicked \"%L\" (reason \"voted by players\")", target);
						
				if(target > 0 && IsClientInGame(target))
				{
					new Handle:dp;
					CreateDataTimer(5.0, DelayedVoteAction, dp);
					WritePackCell(dp, type);
					WritePackCell(dp, GetClientUserId(target));
					g_bVoteAction = true;
				}
			}
		}
	}
	else if(type == BAN)
	{
		PrintToChatAll("[%t] %t", "Voteban", "voted to ban", sVoterName, sTargetName);
		PrintToChatAll("[%t] %t", "Voteban", "votes required", Votes, VotesRequired);

		if(Votes >= VotesRequired)
		{
			if (! IsImmune(target))
			{
				PrintToChatAll("[%t] %t", "Voteban", "banned by vote", sTargetName);
				LogAction(-1, target, "Vote ban successful, banned \"%L\" (reason \"voted by players\")", target);
	
				decl String:sReason[64];
				Format(sReason, sizeof(sReason), "%t", "banned by users");
				BanClient(target, GetConVarInt(g_hVoteBanTime), BANFLAG_AUTO, "banned by users", sReason);

			}
		}
	}
	else if(type == MAP)
	{
		decl String:sMap[32];
		GetArrayString(g_hMapList, target, sMap, sizeof(sMap));

		if(IsMapValid(sMap))
		{
			// Was this a vote to extend current map?
			if (g_nMapCurrent == target && g_nMapExtends != 0 && GetConVarFloat (g_hMapExtendTime) > 0.0)
			{
				PrintToChatAll("[%t] %t", "Votemap", "voted for extend", sVoterName, GetConVarInt (g_hMapExtendTime));
				PrintToChatAll("[%t] %t", "Votemap", "votes required", Votes, VotesRequired);

				if (Votes >= VotesRequired)
				{
					PrintToChatAll("[%t] %t", "Votemap", "map extend by vote", GetConVarInt (g_hMapExtendTime));
					LogAction(-1, -1, "Extending map to due to players vote.");

					decl Float:timeLimit;
					timeLimit = GetConVarFloat (g_hMapTimeLimit) + GetConVarFloat (g_hMapExtendTime);
					SetConVarFloat (g_hMapTimeLimit, timeLimit);

					// Decrement remaining map extends.  Make sure that we account for -1 (infinite).
					if (g_nMapExtends > 0)
					{
						g_nMapExtends = g_nMapExtends - 1;
					}

					// If a map is extended, people expect that the other votes will get tossed.
					ResetVotes (MAP);
				}
				
			}
			else  // Normal change map vote.
			{
				PrintToChatAll("[%t] %t", "Votemap", "voted for map", sVoterName, sMap);
				PrintToChatAll("[%t] %t", "Votemap", "votes required", Votes, VotesRequired);

				if(Votes >= VotesRequired)
				{
					PrintToChatAll("[%t] %t", "Votemap", "map change by vote", sMap);
					LogAction(-1, -1, "Changing map to %s due to players vote.", sMap);

					new Handle:dp;
					CreateDataTimer(10.0, DelayedVoteAction, dp);
					WritePackCell(dp, type);
					WritePackString(dp, sMap);
					g_bVoteAction = true;

					// No need to reset the MAP votes manually.  All votes will be wiped after the new map starts.
				}
			}
		}
	}
}

VotesFor(target, type, &required)
{
	new votes = 0;

	if (type == MAP)
	{
		for (new i = 1; i <= MAXPLAYERS; ++i)
		{
			votes = votes + GetArrayCell (g_hVotedForMap[i], target);
		}
	}
	else
	{
		for(new i = 1; i <= MAXPLAYERS; i++)
		{
			if(g_bVotedFor[type][i][target])
			{
				votes++;
			}		
		}
	}

	new max = GetMaxClients(), players = 0;
	for(new i = 1; i <= max; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;
		players++;
	}

	new minVotes = GetConVarInt(g_hVoteMinimum[type]);
	required = RoundToCeil(float(players) * GetConVarFloat(g_hVoteRatio[type]));
	if(required < minVotes) required = minVotes;
	return votes;
}

public Action:DelayedVoteAction(Handle:timer, Handle:dp)
{
	decl String:sMap[65];
	new target, type;

	ResetPack(dp);
	type = ReadPackCell(dp);

	switch(type)
	{
		case KICK:
		{
			target = ReadPackCell(dp);
			ServerCommand("kickid %d %t", target, "kicked by users");
		}
		case MAP:
		{
			ReadPackString(dp, sMap, sizeof(sMap));
			ServerCommand("changelevel \"%s\"", sMap);
		}
	}	

	g_bVoteAction = false;
	return Plugin_Stop;
}
