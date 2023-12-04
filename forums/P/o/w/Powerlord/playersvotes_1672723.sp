#pragma semicolon 1

#include <sourcemod>
#include <sdktools_voice>
#include <nextmap>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.5.0"

public Plugin:myinfo =
{
	name = "Players Votes",
	author = "The Resident, pZv!",
	description = "Votekick, Voteban, Votemap, & Votemute",
	version = PLUGIN_VERSION,
	url = ""
};

#define KICK       0
#define BAN        1
#define MAP        2
#define MUTE       3
#define LAST_TYPE  MUTE
#define TYPE_COUNT (LAST_TYPE+1)


// ==========================================
// general stuff
// ==========================================
new Handle:g_hVoteRatio  [TYPE_COUNT]              = {INVALID_HANDLE, ...};       // Array [Type] - custom cvar
new Handle:g_hVoteMinimum[TYPE_COUNT]              = {INVALID_HANDLE, ...};       // Array [Type] - custom cvar
new Handle:g_hVoteDelay  [TYPE_COUNT]              = {INVALID_HANDLE, ...};       // Array [Type] - custom cvar
new Handle:g_hVoteLimit  [TYPE_COUNT]              = {INVALID_HANDLE, ...};       // Array [Type] - custom cvar
new Handle:g_hVoteTeam   [TYPE_COUNT]              = {INVALID_HANDLE, ...};       // Array [Type] - custom cvar
new Handle:g_hVotesInterval                        =  INVALID_HANDLE;             // custom cvar
new Handle:g_hVotesTimeout                         =  INVALID_HANDLE;             // Cvar
new Handle:g_hTopMenu                              =  INVALID_HANDLE;             // Handle to top admin menu
new   bool:g_bVoteIsDisabledByAdmin [TYPE_COUNT]   = {false, ...};                // Vote disabled by Admin

new   bool:g_bVoteAction;                                // indicates delayed vote action is scheduled and pending.
new        g_nStartTime;                                 // time of map start
new        g_nVoteCount[TYPE_COUNT][MAXPLAYERS+1];       // [Type] [Voter] - number of times each player registered a vote during this map
new        g_nLastVote[MAXPLAYERS+1];                    // [Voter] - time of last vote.


// ==========================================
// immunity stuff
// ==========================================
new Handle:g_hVoteImmunity                =  INVALID_HANDLE;             // custom cvar
new Handle:g_hAdminGroupsCvar             =  INVALID_HANDLE;             // custom cvar
new Handle:g_hAdminGroups                 =  INVALID_HANDLE;             // Array - immune admin groups
new   bool:g_bImmuneByGroup[MAXPLAYERS+1] = {false, ...};


// ==========================================
// votekick stuff
// ==========================================
new bool:g_bVotedForKick[MAXPLAYERS+1][MAXPLAYERS+1];      // [Voter] [User To Be Kicked]


// ==========================================
// votemap stuff
// ==========================================
new Handle:g_hVotedForMap[MAXPLAYERS+1] = {INVALID_HANDLE, ...};   // Array - [Voter] [Dyn:index into g_hMapList] == 1 if voting for indexed map
new Handle:g_hLastMaps                  = INVALID_HANDLE;          // Array
new Handle:g_hMapList                   = INVALID_HANDLE;          // Array - map names
new Handle:g_hMapExtendTime             = INVALID_HANDLE;          // custom con var
new Handle:g_hMapMaxExtends             = INVALID_HANDLE;	   // custom con var
new Handle:g_hMapTimeLimit              = INVALID_HANDLE;          // source con var
new Handle:g_hMapChangeImmediately      = INVALID_HANDLE;          // source con var
new Handle:g_hVoteMapLast               = INVALID_HANDLE;          // Array - queue of maps last played
new String:g_sMapListConfigSection[]    = "playersvotes";
new        g_nMapListSerial             = -1;
new        g_nMapExtends;                                          // timelimit extensions remaining this map.
new        g_nMapCurrent;                                          // index into g_hMapList of the current map.  -1 if not in list.


// ==========================================
// voteban stuff
// ==========================================
new Handle:g_hVotedForBan   [MAXPLAYERS + 1]   = {INVALID_HANDLE, ...};  // grows as [client] votes to ban people.  maps to below "data struct" dynamic arrays.
new Handle:g_hVotedForReason[MAXPLAYERS + 1]   = {INVALID_HANDLE, ...};  // grows as [client] votes to ban people.  maps to Voteban Reasons.  Index of nested array correlates with above.
new Handle:g_hVoteBanClientUserIds             = INVALID_HANDLE;         // data struct: Unique ID per client w/ votebans against them.  Does not change on target reconnect.
new Handle:g_hVoteBanClientCurrentUserId       = INVALID_HANDLE;         // data struct
new Handle:g_hVoteBanClientIdent               = INVALID_HANDLE;         // data struct: Either an IP or Steam ID
new Handle:g_hVoteBanClientNames               = INVALID_HANDLE;         // data struct
new Handle:g_hVoteBanClientTeam                = INVALID_HANDLE;         // data struct

new        g_nVoteBanClients[MAXPLAYERS + 1]   = {-1, ...};              // maps connected clients to the above dynamic voteban arrays.  Records who is connected AND a ban target.
new Handle:g_hVoteBanTime                      =  INVALID_HANDLE;        // cvar
new Handle:g_hVoteBanSb                        =  INVALID_HANDLE;        // used to detect if SourceBans is present.

new Handle:g_hVoteBanReasons                   = INVALID_HANDLE;         // Array - ban reasons
new Handle:g_hVoteBanReasonsCvar               = INVALID_HANDLE;         // cvar - ban reasons

// ==========================================
// votemute stuff
// ==========================================
new   bool:g_bVotedForMute[MAXPLAYERS+1][MAXPLAYERS+1];                    // [Voter] [User To Be Muted]
new Handle:g_hVoteMuteClientIdent                       = INVALID_HANDLE;  // grows as people are muted.  persistent within a map.
new Handle:g_hBaseComm                                  = INVALID_HANDLE;  // used to detect if basecomm (and therefore sm_mute) is present.
new   bool:g_bMuted [MAXPLAYERS + 1]                    = {false, ...};

new TopMenuObject:g_hPvMenu                 = INVALID_TOPMENUOBJECT;

public OnPluginStart()
{
	LoadTranslations("plugin.playersvotes.txt");

	CreateConVar("sm_playersvotes_version", PLUGIN_VERSION, "Players Votes Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hVoteRatio[KICK] = CreateConVar("sm_votekick_ratio", "0.60", "ratio required for successful votekick.", 0, true, 0.0, true, 1.0);
	g_hVoteRatio[BAN]  = CreateConVar("sm_voteban_ratio",  "0.80", "ratio required for successful voteban.",  0, true, 0.0, true, 1.0);
	g_hVoteRatio[MAP]  = CreateConVar("sm_votemap_ratio",  "0.60", "ratio required for successful votemap.",  0, true, 0.0, true, 1.0);
	g_hVoteRatio[MUTE] = CreateConVar("sm_votemute_ratio", "0.60", "ratio required for successful votemute.", 0, true, 0.0, true, 1.0);

	g_hVoteMinimum[KICK] = CreateConVar("sm_votekick_minimum", "4.0", "minimum votes required for successful votekick. -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[BAN]  = CreateConVar("sm_voteban_minimum",  "4.0", "minimum votes required for successful voteban.  -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[MAP]  = CreateConVar("sm_votemap_minimum",  "4.0", "minimum votes required for successful votemap.  -1 to disable voting", 0, true, -1.0, true, 64.0);
	g_hVoteMinimum[MUTE] = CreateConVar("sm_votemute_minimum", "4.0", "minimum votes required for successful votemute. -1 to disable voting", 0, true, -1.0, true, 64.0);

	g_hVoteDelay[KICK] = CreateConVar("sm_votekick_delay", "60.0", "time in seconds before votekick is allowed after map start", 0, true, 0.0, true, 1000.0);
	g_hVoteDelay[BAN]  = CreateConVar("sm_voteban_delay",  "60.0", "time in seconds before voteban is allowed after map start",  0, true, 0.0, true, 1000.0);
	g_hVoteDelay[MAP]  = CreateConVar("sm_votemap_delay",  "60.0", "time in seconds before votemap is allowed after map start",  0, true, 0.0, true, 1000.0);
	g_hVoteDelay[MUTE] = CreateConVar("sm_votemute_delay", "60.0", "time in seconds before votemute is allowed after map start", 0, true, 0.0, true, 1000.0);

	g_hVoteLimit[KICK] = CreateConVar("sm_votekick_limit", "-1.0", "number of kick votes allowed per player, per map.  0 to disable voting.  -1 for no limit", 0, true, -1.0, true, 1000.0);
	g_hVoteLimit[BAN]  = CreateConVar("sm_voteban_limit",  "-1.0", "number of ban votes allowed per player, per map.  0 to disable voting.  -1 for no limit",  0, true, -1.0, true, 1000.0);
	g_hVoteLimit[MAP]  = CreateConVar("sm_votemap_limit",  "-1.0", "number of map votes allowed per player, per map.  0 to disable voting.  -1 for no limit",  0, true, -1.0, true, 1000.0);
	g_hVoteLimit[MUTE] = CreateConVar("sm_votemute_limit", "-1.0", "number of mute votes allowed per player, per map.  0 to disable voting.  -1 for no limit", 0, true, -1.0, true, 1000.0);

	g_hVoteTeam[KICK]  = CreateConVar("sm_votekick_team_restrict", "0.0", "restrict kick votes to teams.  affects ratios.  1 to enable, 0 to disable.", 0, true, 0.0, true, 1.0);
	g_hVoteTeam[BAN]   = CreateConVar("sm_voteban_team_restrict",  "0.0", "restrict ban votes to teams.  affects ratios.  1 to enable, 0 to disable.", 0, true, 0.0, true, 1.0);
	g_hVoteTeam[MUTE]  = CreateConVar("sm_votemute_team_restrict", "0.0", "restrict mute votes to teams.  affects ratios.  1 to enable, 0 to disable.", 0, true, 0.0, true, 1.0);

	g_hVoteMapLast          = CreateConVar("sm_votemap_lastmaps",     "4.0", "last number of played maps that will not show in votemap list",                           0, true,  0.0, true,  64.0);
	g_hMapExtendTime        = CreateConVar("sm_votemap_extend",      "20.0", "number of minutes to add to the timelimit if the players vote to extend.  -1 to disable", 0, true, -1.0, true, 120.0);
	g_hMapMaxExtends        = CreateConVar("sm_votemap_max_extends",  "1.0", "number of extensions to allow per map.  -1 for no limit",                                 0, true, -1.0, true, 100.0);
	g_hMapChangeImmediately = CreateConVar("sm_votemap_immediate",    "1.0", "1 to change map immediately after a map wins a votemap.  0 for setting nextmap",          0, true,  0.0, true,   1.0);

	g_hMapTimeLimit  = FindConVar ("mp_timelimit");

	g_hVotesInterval = CreateConVar("sm_playersvotes_interval",     "15.0", "interval in seconds between another vote cast", 0, true, 0.0, true, 10000.0);
	g_hVotesTimeout  = CreateConVar("sm_playersvotes_menu_timeout", "0.0",  "number of seconds to display voting menus.  0 for no limit", 0, true, 0.0, true, 10000.0);

	g_hVoteBanTime        = CreateConVar("sm_voteban_time",   "25.0", "ban time in minutes.  0 to ban permanently");
	g_hVoteBanReasonsCvar = CreateConVar("sm_voteban_reasons",    "", "semi-colon delimited list of ban reasons.  (ex: \"Hacking; Spamming; Griefing\")");

	g_hVoteImmunity    = CreateConVar("sm_playersvotes_immunity", "0.0", "admins with equal or higher immunity level will not be affected by votekick, ban, or mute.  0 to immunize all admins.  -1 to ignore", 0, true, -1.0, true, 99.0);
	g_hAdminGroupsCvar = CreateConVar("sm_playersvotes_immunegroups", "", "admins that are members of these groups will not be affected by votekick, ban, or mute.  (ex: \"Full Admins; Clan Members; etc\")");

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
	if (g_hVoteBanClientUserIds == INVALID_HANDLE)
	{
		g_hVoteBanClientUserIds = CreateArray();
	}
	if(g_hVoteBanClientCurrentUserId == INVALID_HANDLE)
	{
		g_hVoteBanClientCurrentUserId = CreateArray();
	}
	if(g_hVoteBanClientTeam == INVALID_HANDLE)
	{
		g_hVoteBanClientTeam = CreateArray();
	}
	if(g_hVoteBanClientIdent == INVALID_HANDLE)
	{
		g_hVoteBanClientIdent = CreateArray(33);
	}
	if(g_hVoteBanClientNames == INVALID_HANDLE)
	{
		g_hVoteBanClientNames = CreateArray(33);
	}
	if(g_hVoteBanReasons == INVALID_HANDLE)
	{
		g_hVoteBanReasons = CreateArray(33);
	}

	if(g_hVoteMuteClientIdent == INVALID_HANDLE)
	{
		g_hVoteMuteClientIdent = CreateArray(33);
	}

	if(g_hAdminGroups == INVALID_HANDLE)
	{
		g_hAdminGroups = CreateArray();
	}
	for (new i = 0; i <= MAXPLAYERS; ++i)
	{
		if (g_hVotedForMap[i] == INVALID_HANDLE)
		{
			g_hVotedForMap[i] = CreateArray();
		}
		if (g_hVotedForBan[i] == INVALID_HANDLE)
		{
			g_hVotedForBan[i] = CreateArray();
		}
		if (g_hVotedForReason[i] == INVALID_HANDLE)
		{
			g_hVotedForReason[i] = CreateArray();
		}
	}

	// Is admin menu already loaded?
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	AutoExecConfig(false);
}


public OnAdminMenuReady(Handle:topmenu)
{
	// Block us from being called twice
	if (topmenu == g_hTopMenu)
	{
		return;
	}

	// Save the Handle
	g_hTopMenu = topmenu;

	BuildAdminPvMenu();
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
		case KICK:
		{
			for (new client = 0; client <= MAXPLAYERS; ++client)
			{
				for (new target = 0; target <= MAXPLAYERS; ++target)
				{
					g_bVotedForKick[client][target] = false;
				}
			}
		}
		case BAN:
		{
			ClearArray (g_hVoteBanClientUserIds);
			ClearArray (g_hVoteBanClientCurrentUserId);
			ClearArray (g_hVoteBanClientTeam);
			ClearArray (g_hVoteBanClientIdent);
			ClearArray (g_hVoteBanClientNames);

			for (new client = 0; client <= MAXPLAYERS; ++client)
			{
				ClearArray (g_hVotedForBan[client]);
				ClearArray (g_hVotedForReason[client]);

				g_nVoteBanClients [client] = -1;
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

		case MUTE:
		{
			for (new client = 0; client <= MAXPLAYERS; ++client)
			{
				for (new target = 0; target <= MAXPLAYERS; ++target)
				{
					g_bVotedForMute[client][target] = false;
				}
			}
		}

		// Invalid type, do nothing.
		default:
		{
		}
	}
}


RemoveBanVotesForTarget (target)
{
	RemoveFromArray (g_hVoteBanClientUserIds,       target);
	RemoveFromArray (g_hVoteBanClientCurrentUserId, target);
	RemoveFromArray (g_hVoteBanClientTeam,          target);
	RemoveFromArray (g_hVoteBanClientIdent,         target);
	RemoveFromArray (g_hVoteBanClientNames,         target);

	for (new i = 1; i <= MAXPLAYERS; ++i)
	{

		// Update the VotedFor mappings.

		new nVoteToRemove = -1;
		new nBanVotes     = GetArraySize (g_hVotedForBan[i]);

		for (new j = 0; j < nBanVotes; ++j)
		{
			new vote = GetArrayCell (g_hVotedForBan[i], j);
			if (vote == target)
			{
				nVoteToRemove = j;
			}
			else if (vote > target)
			{
				SetArrayCell (g_hVotedForBan[i], j, vote - 1);
			}
		}

		if (nVoteToRemove != -1)
		{
			RemoveFromArray (g_hVotedForBan[i],    nVoteToRemove);
			RemoveFromArray (g_hVotedForReason[i], nVoteToRemove);
		}

		// Update the client-to-ban-target mappings.

		if (g_nVoteBanClients[i] == target)
		{
			g_nVoteBanClients[i] = -1;
		}
		else if (g_nVoteBanClients[i] > target)
		{
			--g_nVoteBanClients[i];
		}
	}
}


bool:AuthIsValid (const String:sClientAuth[])
{
	return (strcmp (sClientAuth, "STEAM_ID_LAN",     false) != 0) &&
	       (strcmp (sClientAuth, "STEAM_ID_PENDING", false) != 0);
}


bool:GetIdent (client, String:sClientIdent[], nClientIdentSize)
{
	new bool:bIsAuth = true;

	GetClientAuthString (client, sClientIdent, nClientIdentSize);

	if ((! IsClientAuthorized(client)) ||
	    (! AuthIsValid (sClientIdent))
	   )
	{
		GetClientIP (client, sClientIdent, nClientIdentSize);
		bIsAuth = false;
	}

	return bIsAuth;
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

MatchIdent (const Handle:hIdentArray, const String:sIdent[])
{
	new nIdents = GetArraySize (hIdentArray);
	decl String:sStoredIdent[33];

	for (new i = 0; i < nIdents; ++i)
	{
		GetArrayString (hIdentArray, i, sStoredIdent, sizeof (sStoredIdent));

		if (strcmp (sIdent, sStoredIdent, false) == 0)
		{
			return i;
		}
	}

	return -1;
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

	// Rebuild the list of immune groups.
	ClearArray (g_hAdminGroups);

	decl String:sAdminGroupList[256];
	decl String:sAdminGroupName[33];

	GetConVarString (g_hAdminGroupsCvar, sAdminGroupList, sizeof (sAdminGroupList));
	StrCat (sAdminGroupList, sizeof (sAdminGroupList), ";");

	new nGroupListOffset = 0;
	decl GroupId:immuneGroup;

	for (new i = SplitString (sAdminGroupList, ";", sAdminGroupName, sizeof (sAdminGroupName));
	         i != -1;
	         i = SplitString (sAdminGroupList[nGroupListOffset], ";", sAdminGroupName, sizeof (sAdminGroupName)))
	{
		nGroupListOffset += i;

		TrimString (sAdminGroupName);
		immuneGroup = FindAdmGroup (sAdminGroupName);
		if (immuneGroup != INVALID_GROUP_ID)
		{
			PushArrayCell (g_hAdminGroups, immuneGroup);
		}
	}

	// Rebuild the ban reasons.
	decl String:sBanReasonList[256];
	decl String:sBanReason[33];
	new         nBanReasonOffset = 0;

	GetConVarString (g_hVoteBanReasonsCvar, sBanReasonList, sizeof (sBanReasonList));
	StrCat (sBanReasonList, sizeof (sBanReasonList), ";");

	ClearArray (g_hVoteBanReasons);
	for (new i = SplitString (sBanReasonList, ";", sBanReason, sizeof (sBanReason));
	         i != -1;
	         i = SplitString (sBanReasonList[nBanReasonOffset], ";", sBanReason, sizeof (sBanReason)))
	{
		nBanReasonOffset += i;

		TrimString (sBanReason);
		if (! StrEqual (sBanReason, ""))
		{
			PushArrayString (g_hVoteBanReasons, sBanReason);
		}
	}

}


public OnMapStart()
{
	g_nStartTime = GetTime();

	// Players Votes will take advantage of some other plugins' capabilities if present.  Detect those other plugins here.
	g_hVoteBanSb   = FindConVar("sb_version");            // SourceBans
	g_hBaseComm    = FindPluginByFile ("basecomm.smx");   // BaseComm

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
	ResetVotes (MUTE);

	for (new i = 0; i <= MAXPLAYERS; ++i)
	{
		g_nVoteCount [KICK] [i] = 0;
		g_nVoteCount [BAN]  [i] = 0;
		g_nVoteCount [MAP]  [i] = 0;
		g_nVoteCount [MUTE] [i] = 0;

		g_nVoteBanClients [i] = -1;

		g_bMuted [i] = false;
	}

	// Mutes get reset, too...  otherwise, how do we know when to rescind mutes?
	ClearArray (g_hVoteMuteClientIdent);
}


public OnClientDisconnect(client)
{
	g_bImmuneByGroup[client] = false;
	g_nLastVote[client] = 0;
	g_nVoteCount[KICK] [client] = 0;
	g_nVoteCount[BAN]  [client] = 0;
	g_nVoteCount[MAP]  [client] = 0;
	g_nVoteCount[MUTE] [client] = 0;

	g_nVoteBanClients [client] = -1;

	for(new i = 0; i <= MAXPLAYERS; i++)
	{
		// Get rid of this player's kick votes.
		g_bVotedForKick[client][i] = false;

		// Get rid of any other player's kick votes against this guy.
		g_bVotedForKick[i][client] = false;

		// Get rid of this player's mute votes.
		g_bVotedForMute[client][i] = false;

		// Get rid of any other player's mute votes against this guy.
		g_bVotedForMute[i][client] = false;
	}

	// Clear this player's ban votes.  Make sure that if this player is the only one that voted
	// to ban a particular target, that the target's ban data is cleared.

	new nBanVotes = GetArraySize (g_hVotedForBan[client]);
	new target;

	for (new i = 0; i < nBanVotes; ++i)
	{
		target = GetArrayCell (g_hVotedForBan[client], i);
		if (VotesFor (target, BAN) == 1)
		{
			RemoveBanVotesForTarget (target);

			--i;          // This is a hack...  The above call will definitely result in the
			--nBanVotes;  // VotedFor array being shortened by an element, where element i will then refer to
			              // the vote that followed the vote for "target".  Basically, the vote after
			              // the one for "target" would get skipped when i gets incremented at the top of the loop.
		}
	}

	ClearArray (g_hVotedForBan[client]);
	ClearArray (g_hVotedForReason[client]);

	// Now clear the player's map votes.
	ResetClientMapVotes (client);

	// If a client has been muted by players vote, but they are not actually muted at disconnect, it must be
	// because an admin unmuted them.  In that case, remove the vote mute state.
	// Otherwise, if they reconnect after having been muted, we want to make sure they automatically get remuted.

	if (g_bMuted [client] && ! (GetClientListeningFlags(client) & VOICE_MUTED))
	{

		decl String:sClientAuth[33];

		GetIdent (client, sClientAuth, sizeof (sClientAuth));

		new nRemoveMuteIndex = MatchIdent (g_hVoteMuteClientIdent, sClientAuth);

		if (nRemoveMuteIndex != -1)
		{
			RemoveFromArray (g_hVoteMuteClientIdent, nRemoveMuteIndex);
		}
	}

	g_bMuted [client] = false;
}

public OnClientConnected (client)
{
	decl String:sIp[33];

	// If a client has just connected, but there are active votes against their IP,
	// make sure we correlate their client ID to the dynamic ban arrays.

	GetClientIP (client, sIp, sizeof (sIp));

	g_nVoteBanClients[client] = MatchIdent (g_hVoteBanClientIdent, sIp);

	new nBanTarget = g_nVoteBanClients[client];

	// Is the client a ban target?
	if (nBanTarget != -1)
	{
		decl String:sClientName[33], String:sStoredName[33];

		GetClientName (client, sClientName, sizeof (sClientName));
		GetArrayString (g_hVoteBanClientNames, nBanTarget, sStoredName, sizeof (sStoredName));

		// Update the user's name
		if (strcmp (sClientName, sStoredName) != 0)
		{
			PrintToChatAll ("VoteBan: %s changed name to %s!!", sStoredName, sClientName);
			SetArrayString (g_hVoteBanClientNames, nBanTarget, sClientName);
		}

		// Update the current user ID
		SetArrayCell (g_hVoteBanClientCurrentUserId, nBanTarget, GetClientUserId (client));

	}

	// If this client is muted by IP, re-instate their mutedness.
	if (MatchIdent (g_hVoteMuteClientIdent, sIp) != -1)
	{
		g_bMuted[client] = true;
	}

	return true;
}

public OnClientAuthorized(client, const String:auth[])
{
	new nBanTarget = g_nVoteBanClients[client];

	// If the client already has a ban vote against them, change their IP string to an auth string...
	// as long as the auth string isn't invalid...

	if (nBanTarget != -1)
	{
		if (AuthIsValid (auth))
		{
			SetArrayString (g_hVoteBanClientIdent, nBanTarget, auth);
		}
	}
	else
	{
		// If we already have a ban vote against them based on Auth string, rather than IP, make that correlation
		// here.

		g_nVoteBanClients[client] = MatchIdent (g_hVoteBanClientIdent, auth);

		nBanTarget = g_nVoteBanClients[client];
	}

	// Is the client a ban target?
	if (nBanTarget != -1)
	{
		decl String:sClientName[33], String:sStoredName[33];

		GetClientName (client, sClientName, sizeof (sClientName));
		GetArrayString (g_hVoteBanClientNames, nBanTarget, sStoredName, sizeof (sStoredName));

		// Update the user's name
		if (strcmp (sClientName, sStoredName) != 0)
		{
			PrintToChatAll ("VoteBan: %s changed name to %s!!", sStoredName, sClientName);
			SetArrayString (g_hVoteBanClientNames, nBanTarget, sClientName);
		}

		SetArrayCell (g_hVoteBanClientCurrentUserId, nBanTarget, GetClientUserId (client));
	}

	// If this client is muted by Auth, re-instate their mutedness.
	if (MatchIdent (g_hVoteMuteClientIdent, auth) != -1)
	{
		g_bMuted[client] = true;
	}
}


public OnClientPostAdminCheck (client)
{
	// See if this client is a member of an immune group.
	new AdminId:targetAdmin = GetUserAdmin (client);

	if (targetAdmin != INVALID_ADMIN_ID)
	{
		new groupCount = GetAdminGroupCount (targetAdmin);
		new immuneGroupCount = GetArraySize (g_hAdminGroups);
		new GroupId:targetGroup;
		decl String:throwaway[1];

		for (new i = 0; i < groupCount; ++i)
		{
			targetGroup = GetAdminGroup (targetAdmin, i, throwaway, sizeof(throwaway));
			if (targetGroup != INVALID_GROUP_ID)
			{
				for (new j = 0; j < immuneGroupCount; ++j)
				{
					if (targetGroup == GetArrayCell (g_hAdminGroups, j))
					{
						g_bImmuneByGroup[client] = true;
						break;
					}
				}
			}
			if (g_bImmuneByGroup[client])
			{
				break;
			}
		}
	}

	// If, during the connection process, we determined that this client needs to be muted, apply the mute now.
	if (g_bMuted[client])
	{
		PerformMute (client);
	}
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
	new immunity = GetConVarInt(g_hVoteImmunity);

	// If the target was noted as being in an immune group, that takes precedence over
	// numerical immunity level.
	if (g_bImmuneByGroup[target])
	{
		return true;
	}

	// If we care about admin immunity level, see if this user is an admin and immune.
	// Note, 0 is the lowest immunity level any admin can have.
	if (immunity > -1)
	{
		new AdminId:targetAdmin = GetUserAdmin(target);

		if (targetAdmin != INVALID_ADMIN_ID)
		{
			return GetAdminImmunityLevel(targetAdmin) >= immunity;
		}
	}

	return false;
}


bool:IsVoteDisabledByConVar (type)
{
	return (GetConVarInt(g_hVoteMinimum[type]) <= -1) ||
	       (GetConVarInt(g_hVoteLimit[type]) == 0);
}



PerformMute (client)
{
	// precondition: client is valid.

	if (g_hBaseComm != INVALID_HANDLE)
	{
		ServerCommand ("sm_mute #%d", GetClientUserId (client));
	}
	else
	{
		SetClientListeningFlags(client, VOICE_MUTED);
	}
}


ProcessClientVoteCommand (type, client, const String:sVoteName[])
{
	new nFromStart = GetTime() - g_nStartTime;
	new nFromLast  = GetTime() - g_nLastVote[client];
	new nVoteLimit = GetConVarInt (g_hVoteLimit[type]);

	if((! IsVoteDisabledByConVar (type)) &&
	   (! g_bVoteIsDisabledByAdmin[type])
	  )
	{
		if((nVoteLimit == -1) ||
		   (nVoteLimit > g_nVoteCount[type][client]))
		{
			if(nFromLast >= GetConVarInt(g_hVotesInterval))
			{
				if(nFromStart >= GetConVarInt(g_hVoteDelay[type]))
				{
					g_nLastVote[client] = GetTime();
					DisplayVoteMenu(client, type, sVoteName);
				}
				else
				{
					PrintToChat(client, "%t %t", sVoteName, "voting not allowed", GetConVarInt(g_hVoteDelay[type]) - nFromStart);
				}
			}
			else
			{
				PrintToChat(client, "%t %t", sVoteName, "voting not allowed again", GetConVarInt(g_hVotesInterval) - nFromLast);
			}
		}
		else
		{
			PrintToChat(client, "%t %t", sVoteName, "votes spent", nVoteLimit, sVoteName);
		}
	}
	else
	{
		PrintToChat(client, "%t %t", sVoteName, "is disabled");
	}
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

	if (text[startidx] == '!')
	{
		// Consume the '!' character only if the player is not an admin.
		// the !votekick, etc commands are reserved for admins in stock SM.
		new AdminId:admin = GetUserAdmin (client);
		if (admin == INVALID_ADMIN_ID)
		{
			++startidx;
		}
	}

	if (strcmp(text[startidx], "votekick", false) == 0)
	{
		ProcessClientVoteCommand (KICK, client, "Votekick");
	}

	else if (strcmp(text[startidx], "voteban", false) == 0)
	{
		ProcessClientVoteCommand (BAN, client, "Voteban");
	}

	else if (strcmp(text[startidx], "votemap", false) == 0)
	{
		ProcessClientVoteCommand (MAP, client, "Votemap");
	}

	else if (strcmp(text[startidx], "votemute", false) == 0)
	{
		ProcessClientVoteCommand (MUTE, client, "Votemute");
	}

	return Plugin_Continue;
}

DisplayVoteMenu(client, type, const String:sVoteName[])
{
	new Handle:hVoteMenu;
	hVoteMenu = CreateMenu(Handler_VoteMenu);

	decl String:sPrefix[1], String:sTitle[32];

	new nVoteLimit = GetConVarInt (g_hVoteLimit[type]);

	if (nVoteLimit > 0)
	{
		Format(sTitle, sizeof(sTitle), "%t: %t", sVoteName, "votes remaining", nVoteLimit - g_nVoteCount[type][client]);
	}
	else
	{
		Format(sTitle, sizeof(sTitle), "%t:", sVoteName);
	}
	SetMenuTitle(hVoteMenu, sTitle);

	switch(type)
	{
		case KICK:
		{
			sPrefix[0] = 'k';
		}
		case BAN:
		{
			sPrefix[0] = 'b';
		}
		case MAP:
		{
			sPrefix[0] = 'm';
		}
		case MUTE:
		{
			sPrefix[0] = 'u';
		}
		default:
		{
			CloseHandle(hVoteMenu);
			return;
		}
	}

	if(type == MAP)
	{
		decl String:sMap[65], String:sPos[8];

		new num = GetArraySize(g_hMapList);
		new required, votes;

		new bool:bExtendAdded = false;

		for(new i = 0; i < num; i++)
		{
			GetArrayString(g_hMapList, i, sMap, sizeof(sMap));

			if(IsMapValid(sMap))
			{

				// If map extensions are enabled and not used up, and the current map is in the list,
				// add a map extension vote item.
				if (g_nMapCurrent == i && g_nMapExtends != 0 && GetConVarFloat (g_hMapExtendTime) > 0.0)
				{
					votes = VotesFor(i, type);
					RequiredVotes (client, type, required);

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

					bExtendAdded = true;

				}
				// Otherwise if this is not one of the last-played maps, list it for a map change vote.
				else if (IsLastPlayed(sMap) == false)
				{
					votes = VotesFor(i, type);
					RequiredVotes (client, type, required);

					Format(sPos, sizeof(sPos), "%s%d", sPrefix, i);
					Format(sMap, sizeof(sMap), "%s [%d/%d]", sMap, votes, required);

					if (votes > 0)
					{
						if (bExtendAdded)
						{
							InsertMenuItem (hVoteMenu, 1, sPos, sMap);
						}
						else
						{
							// FIXME:  Again with the Insert bug.
							if (i == 0)
							{
								AddMenuItem(hVoteMenu, sPos, sMap);
							}
							else
							{
								InsertMenuItem (hVoteMenu, 0, sPos, sMap);
							}
						}
					}
					else
					{
						AddMenuItem(hVoteMenu, sPos, sMap);
					}
				}
			}
		}
	}
	else if ((type == KICK) ||
	         (type == MUTE))
	{
		decl String:sName[72], String:sClient[8]; 

		new num = MaxClients, flags = ITEMDRAW_DEFAULT;
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

			// If voting is restricted to teams, make sure we don't list players not on the voter's team.
			if (GetConVarBool (g_hVoteTeam[type]) &&
			   (GetClientTeam (client) != GetClientTeam(i)))
			{
				continue;
			}

			// FIXME:  Disabled doesn't appear to work, at least under HL2DM.
			// Don't let players vote against themselves or immune admins.
			if(i == client || IsImmune(i) || 
                           ((type == MUTE) && (g_bMuted[client]))
			  )
			{
				continue;
				//flags = ITEMDRAW_DISABLED;
			}
			else
			{
				flags = ITEMDRAW_DEFAULT;
			}

			votes = VotesFor(i, type);
			RequiredVotes (client, type, required);

			Format(sClient, sizeof(sClient), "%s%d", sPrefix, i);
			Format(sName, sizeof(sName), "%N [%d/%d]", i, votes, required);

			if (votes > 0)
			{
				// FIXME:  Again with the Insert bug.
				if (i == 1)
				{
					AddMenuItem(hVoteMenu, sClient, sName, flags);
				}
				else
				{
					InsertMenuItem(hVoteMenu, 0, sClient, sName, flags);
				}
			}
			else
			{
				AddMenuItem(hVoteMenu, sClient, sName, flags);
			}
		}

	}
	else if (type == BAN)
	{
		decl String:sName[72], String:sClient[8]; 

		new num = MaxClients, flags = ITEMDRAW_DEFAULT;
		new required, votes;

		RequiredVotes (client, type, required);

		// First, list any players with ban votes latched against them, connected or not.

		new banCandidates = GetArraySize (g_hVoteBanClientNames);
		for (new i = 0; i < banCandidates; ++i)
		{
			// No need to sanity check.  They would not have been pushed onto the ban
			// candidate array if they didn't pass the generic sanity check below.

			// If someone has votebans against them, is connected, and teamplay check is on, show them to the team
			// that started the voteban, as well as the "current" team.
			new target = GetClientOfUserId (GetArrayCell (g_hVoteBanClientCurrentUserId, i));

			new bool:bShowTarget = false;

			if (GetConVarBool (g_hVoteTeam[BAN]))
			{
				if (target != 0)
				{
					if (GetClientTeam(client) == GetClientTeam (target))
					{
						bShowTarget = true;
					}
				}

				if (GetArrayCell (g_hVoteBanClientTeam, i) == GetClientTeam(client))
				{
					bShowTarget = true;
				}
			}
			else
			{
				bShowTarget = true;
			}

			if (bShowTarget)
			{
				decl String:sBanName [33];

				votes = VotesFor(i, type);

				GetArrayString (g_hVoteBanClientNames, i, sBanName, sizeof (sBanName));

				Format(sClient, sizeof(sClient), "%s%d", sPrefix, GetArrayCell (g_hVoteBanClientUserIds, i));
				Format(sName, sizeof(sName), "%s [%d/%d]", sBanName, votes, required);

				AddMenuItem(hVoteMenu, sClient, sName, flags);
			}
		}

		// Now list all other players, provided they pass the gauntlet of sanity checks.

		votes = 0;

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

			// If the player is connected and already has a ban vote against them,
			// make sure we don't list this player twice.

			if (g_nVoteBanClients[i] != -1)
			{
				continue;
			}

			// If voting is restricted to teams, make sure we don't list players not on the voter's team.
			if (GetConVarBool (g_hVoteTeam[type]) &&
			   (GetClientTeam (client) != GetClientTeam(i)))
			{
				continue;
			}

			// FIXME:  Disabled doesn't appear to work, at least under HL2DM.
			// Don't let players vote against themselves or immune admins.
			if(i == client || IsImmune(i))
			{
				//flags = ITEMDRAW_DISABLED;
				continue;
			}
			else
			{
				flags = ITEMDRAW_DEFAULT;
			}

			Format(sClient, sizeof(sClient), "%s%d", sPrefix, GetClientUserId (i));
			Format(sName, sizeof(sName), "%N [%d/%d]", i, votes, required);

			AddMenuItem(hVoteMenu, sClient, sName, flags);
		}
		
	}
	SetMenuExitButton(hVoteMenu, true);
	DisplayMenu(hVoteMenu, client, GetConVarInt (g_hVotesTimeout));
}

public Handler_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:sUserId[8];
		new target, type;
		GetMenuItem(menu, param2, sUserId, sizeof(sUserId), _, "", 0);

		if      (sUserId[0] == 'k')     type = KICK;
		else if (sUserId[0] == 'u')     type = MUTE;
		else if (sUserId[0] == 'm')     type = MAP;
		else if (sUserId[0] == 'b')     type = BAN;

		target = StringToInt(sUserId[1]);

		if(type == MAP)
		{
			// Get rid of any prior map vote this client has.
			ResetClientMapVotes (param1);

			// Set their single vote to the target map.
			SetArrayCell (g_hVotedForMap[param1], target, 1);

			g_nVoteCount[type][param1] += 1;

			CheckVotes(param1, target, type);
		}
		else if (type == KICK)
		{
			if(target > 0)
			{
				if(IsClientInGame(target) && !IsFakeClient(target))
				{
					g_bVotedForKick[param1][target] = true;

					g_nVoteCount[type][param1] += 1;

					CheckVotes(param1, target, type);
				}
			}
		}
		else if (type == MUTE)
		{
			if(target > 0)
			{
				if(IsClientInGame(target) && !IsFakeClient(target))
				{
					g_bVotedForMute[param1][target] = true;

					g_nVoteCount[type][param1] += 1;

					CheckVotes(param1, target, type);
				}
			}
		}
		else if (type == BAN)
		{
			if (GetArraySize (g_hVoteBanReasons) > 0)
			{
				DisplayBanReasonMenu (param1, target);
			}
			else
			{
				ProcessBanVote (param1, target, -1);
			}
		}
	}
}


DisplayBanReasonMenu(client, targetUserId)
{

	new numReasons = GetArraySize (g_hVoteBanReasons);

	if (numReasons <= 0)
	{
		ProcessBanVote (client, targetUserId, -1);
		return;
	}

	new Handle:hReasonMenu;
	hReasonMenu = CreateMenu(Handler_ReasonMenu);

	decl String:sTarget[8], String:sTitle[32], String:sReason[33];

	Format(sTitle, sizeof(sTitle), "%t:", "ban reasons");
	SetMenuTitle(hReasonMenu, sTitle);

	Format(sTarget, sizeof(sTarget), "%d", targetUserId);

	for (new i = 0; i < numReasons; ++i)
	{
		GetArrayString (g_hVoteBanReasons, i, sReason, sizeof(sReason));
		AddMenuItem (hReasonMenu, sTarget, sReason);
	}

	SetMenuExitButton(hReasonMenu, true);
	DisplayMenu(hReasonMenu, client, GetConVarInt (g_hVotesTimeout));
}

public Handler_ReasonMenu (Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle (menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:sUserId[8];
		new target;
		GetMenuItem(menu, param2, sUserId, sizeof(sUserId), _, "", 0);

		target = StringToInt(sUserId[0]);

		ProcessBanVote (param1, target, param2);
	}
}


ProcessBanVote (voter, target, reason)
{
	// For BAN votes, the target is actually the UserId.

	// Store off the user's data if they haven't had a ban vote against them yet.
	new nTargetIndex = FindValueInArray (g_hVoteBanClientUserIds, target);

	if (nTargetIndex == -1)
	{
		new nClientId = GetClientOfUserId (target);

		if((nClientId > 0) && IsClientInGame(nClientId) && !IsFakeClient(nClientId))
		{
			decl String:sClientName[33],
			     String:sClientAuth[33];

			GetClientName (nClientId, sClientName, sizeof (sClientName));

			GetIdent (nClientId, sClientAuth, sizeof (sClientAuth));

			PushArrayCell   (g_hVoteBanClientUserIds,       target);
			PushArrayString (g_hVoteBanClientNames,         sClientName);
			PushArrayString (g_hVoteBanClientIdent,         sClientAuth);
			PushArrayCell   (g_hVoteBanClientCurrentUserId, target);
			PushArrayCell   (g_hVoteBanClientTeam,          GetClientTeam (nClientId));

			g_nVoteBanClients[nClientId] = GetArraySize (g_hVoteBanClientNames) - 1;

			nTargetIndex = g_nVoteBanClients[nClientId];
		}
		else
		{
			// Target disconnected before any vote was registered against them.
		}

	}

	if (nTargetIndex != -1)
	{
		// At this point, targetIndex has been set to the correct dynamic array index.
		// Have we logged any votes by this user against this target?  Prevent duplicate votes.

		new nVoteCount = GetArraySize (g_hVotedForBan[voter]);

		new bool:bDuplicateVote = false;

		for (new i = 0; i < nVoteCount; ++i)
		{
			if (GetArrayCell (g_hVotedForBan[voter], i) == nTargetIndex)
			{
				bDuplicateVote = true;   // The fool wasted a vote...
			}
		}
		if (! bDuplicateVote)
		{
			PushArrayCell (g_hVotedForBan[voter],    nTargetIndex);
			PushArrayCell (g_hVotedForReason[voter], reason);
		}

		g_nVoteCount[BAN][voter] += 1;
		CheckVotes (voter, nTargetIndex, BAN);
	}
		
}


GetBanReason (target)
{
	// Target is the dynamic Ban info index.

	if (GetArraySize (g_hVoteBanReasons) <= 0)
	{
		return -1;
	}

	new Handle:hReasonTally = CreateArray (1, GetArraySize (g_hVoteBanReasons));
	new        nTargetIndex;
	new        finalReason      = -1;
	new        finalReasonCount =  0;

	// Initialize tally.
	for (new i = 0; i < GetArraySize (hReasonTally); ++i)
	{
		SetArrayCell (hReasonTally, i, 0);
	}

	// Record the tally.
	for (new i = 1; i <= MAXPLAYERS; ++i)
	{
		nTargetIndex = FindValueInArray (g_hVotedForBan [i], target);
		if (nTargetIndex >= 0)
		{
			new reason = GetArrayCell (g_hVotedForReason[i], nTargetIndex);
			new count  = GetArrayCell (hReasonTally, reason);
			SetArrayCell (hReasonTally, reason, count + 1);
		}
	}

	// Find the reason most voted for.
	for (new i = 0; i < GetArraySize (hReasonTally); ++i)
	{
		if (finalReasonCount < GetArrayCell (hReasonTally, i))
		{
			finalReasonCount = GetArrayCell (hReasonTally, i);
			finalReason      = i;
		}
	}

	return finalReason;
}

PrintVoteAction (voter, type, const String:sMessage[])
{
	if (type != MAP &&
	    GetConVarBool (g_hVoteTeam[type]))
	{
		for (new i = 1; i <= MaxClients; ++i)
		{
			if(!IsClientInGame(i)) continue;
			if(IsFakeClient(i)) continue;

			if (GetClientTeam(i) == GetClientTeam(voter))
			{
				PrintToChat (i, sMessage);
			}
		}
	}
	else
	{
		PrintToChatAll (sMessage);
	}
}

// +------------------------------------------------------------------------
// | Important note about CheckVotes:
// |
// | When type == BAN, target is the index into the dynamic ban arrays.
// | It is important that CheckVotes not get passed client IDs when type == BAN!
// +---------------------------------------------------------------------------

CheckVotes(voter, target, type)
{
	new nVotesRequired;
	new Votes = VotesFor(target, type);
	RequiredVotes (voter, type, nVotesRequired);

	decl String:sVoterName[65], String:sTargetName[65], String:sMessage[256];

	// Get the voter's name and the target's name.
	GetClientName(voter, sVoterName, sizeof(sVoterName));

	if((type == KICK) ||
           (type == MUTE))
	{		
		GetClientName(target, sTargetName, sizeof(sTargetName));
	}
	else if (type == BAN)
	{
		GetArrayString (g_hVoteBanClientNames, target, sTargetName, sizeof (sTargetName));
	}

	if(type == KICK)
	{
		Format(sMessage, sizeof (sMessage), "%t", "voted to kick", sVoterName, sTargetName);
		PrintVoteAction(voter, type, sMessage);

		if(Votes >= nVotesRequired)
		{
			PrintToChatAll("%t", "kicked by vote", sTargetName);
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
		else
		{
			Format(sMessage, sizeof (sMessage), "%t", "votes required", Votes, nVotesRequired);
			PrintVoteAction(voter, type, sMessage);
		}
	}
	else if(type == MUTE)
	{
		Format(sMessage, sizeof (sMessage), "%t", "voted to mute", sVoterName, sTargetName);
		PrintVoteAction(voter, type, sMessage);

		if(Votes >= nVotesRequired)
		{
			PrintToChatAll("%t", "muted by vote", sTargetName);
			LogAction(-1, target, "Vote mute successful, muted \"%L\" (reason \"voted by players\")", target);

			if(target > 0 && IsClientInGame(target))
			{
				decl String:sClientAuth[33];

				g_bMuted[target] = true;

				GetIdent (target, sClientAuth, sizeof (sClientAuth));
				PushArrayString (g_hVoteMuteClientIdent, sClientAuth);

				PerformMute (target);
			}
		}
		else
		{
			Format(sMessage, sizeof (sMessage), "%t", "votes required", Votes, nVotesRequired);
			PrintVoteAction(voter, type, sMessage);
		}

	}
	else if(type == BAN)
	{
		Format(sMessage, sizeof (sMessage), "%t", "voted to ban", sVoterName, sTargetName);
		PrintVoteAction(voter, type, sMessage);

		if(Votes >= nVotesRequired)
		{
			decl String:sIdent[33];
			decl String:sVoteReason[33];
			decl String:sReason[100];

			new reason = GetBanReason (target);

			new nUserId   = GetArrayCell (g_hVoteBanClientCurrentUserId, target);
			new nClientId = GetClientOfUserId (nUserId);

			new nBanFlags = BANFLAG_AUTHID;

			GetArrayString (g_hVoteBanClientIdent, target, sIdent, sizeof (sIdent));

			if (strncmp (sIdent, "STEAM", 5) != 0)
			{
				nBanFlags = BANFLAG_IP;
			}

			// Format the reason and log messages.
			if (reason > -1)
			{
				// Reason given.

				GetArrayString (g_hVoteBanReasons, reason, sVoteReason, sizeof (sVoteReason));
				PrintToChatAll("%t (%s)", "banned by vote", sTargetName, sVoteReason);

				// If user is connected, no need to add the user name to the reason string.
				// otherwise, make sure the user's name appears in the reason.
				if (nClientId > 0)
				{
					Format(sReason, sizeof(sReason), "%t (%s)", "banned by users", sVoteReason);
				}
				else
				{
					Format(sReason, sizeof(sReason), "(%s) %t (%s)", sTargetName, "banned by users", sVoteReason);
				}
			}
			else
			{
				// No reason given.

				strcopy (sVoteReason, sizeof (sVoteReason), "unspecified");
				PrintToChatAll("%t", "banned by vote", sTargetName);

				// If user is connected, no need to add the user name to the reason string.
				// otherwise, make sure the user's name appears in the reason.
				if (nClientId > 0)
				{
					Format(sReason, sizeof(sReason), "%t", "banned by users");
				}
				else
				{
					Format(sReason, sizeof(sReason), "(%s) %t", sTargetName, "banned by users");
				}
			}

			LogAction(-1, -1, "Vote ban successful, banned \"%s\" (reason \"%s\")", sTargetName, sVoteReason);

			// Now perform the ban itself.
			if (g_hVoteBanSb == INVALID_HANDLE)
			{
				BanIdentity (sIdent, GetConVarInt(g_hVoteBanTime), nBanFlags, sReason, "players vote");
			}
			else
			{
				if (nClientId > 0)
				{
					// User is connected now.
					ServerCommand ("sm_ban #%d %d \"%s\"", nUserId, GetConVarInt(g_hVoteBanTime), sReason);
				}
				else
				{
					if (nBanFlags == BANFLAG_AUTHID)
					{
						// Ident is a steam ID.
						ServerCommand ("sm_addban %d %s \"%s\"", GetConVarInt(g_hVoteBanTime), sIdent, sReason);
					}
					else
					{
						// Ident is an IP.
						ServerCommand ("sm_banip %s %d \"%s\"", sIdent, GetConVarInt(g_hVoteBanTime), sReason);
					}
				}
			}

			// FIXME:  Apparently BanIdentity will kick when IP addresses are given, but not with Steam IDs...?
			if (nBanFlags == BANFLAG_AUTHID)
			{
				new Handle:dp;
				CreateDataTimer(0.25, DelayedVoteAction, dp);
				WritePackCell(dp, BAN);
				WritePackCell(dp, nUserId);
				WritePackString(dp, sReason);
				g_bVoteAction = true;
			}


			// Ban is complete.  Now let's clean our hands of the whole affair and erase him from our voteban buffers.

			RemoveBanVotesForTarget (target);

		}
		else
		{
			Format(sMessage, sizeof (sMessage), "%t", "votes required", Votes, nVotesRequired);
			PrintVoteAction(voter, type, sMessage);
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
				PrintToChatAll("%t", "voted for extend", sVoterName, GetConVarInt (g_hMapExtendTime));

				if (Votes >= nVotesRequired)
				{
					PrintToChatAll("%t", "map extend by vote", GetConVarInt (g_hMapExtendTime));
					LogAction(-1, -1, "Extending map to due to players vote.");

					decl Float:timeLimit;
					timeLimit = GetConVarFloat (g_hMapTimeLimit) + GetConVarFloat (g_hMapExtendTime);
					SetConVarFloat (g_hMapTimeLimit, timeLimit);

					// Decrement remaining map extends.  Make sure that we account for -1 (infinite).
					if (g_nMapExtends > 0)
					{
						g_nMapExtends = g_nMapExtends - 1;
					}

					// If a map is extended, people expect that the other MAP votes will get tossed.
					ResetVotes (MAP);
				}
				else
				{
					PrintToChatAll("%t", "votes required", Votes, nVotesRequired);
				}
			}
			else  // Normal change map vote.
			{
				// Print vote announcement
				if (GetConVarBool(g_hMapChangeImmediately))
				{
					PrintToChatAll("%t", "voted for map", sVoterName, sMap);
				}
				else
				{
					PrintToChatAll("%t", "voted for nextmap", sVoterName, sMap);
				}

				// Check whether vote action needs to be taken.
				if(Votes >= nVotesRequired)
				{
					if (GetConVarBool(g_hMapChangeImmediately))
					{
						PrintToChatAll("%t", "map change by vote", sMap);
						LogAction(-1, -1, "Changing map to %s due to players vote.", sMap);

						new Handle:dp;
						CreateDataTimer(10.0, DelayedVoteAction, dp);
						WritePackCell(dp, type);
						WritePackString(dp, sMap);
						g_bVoteAction = true;

						// No need to reset the MAP votes manually.  All votes will be wiped after the new map starts.
					}
					else
					{
						PrintToChatAll("%t", "nextmap change by vote", sMap);
						if (SetNextMap (sMap))
						{
							LogAction(-1, -1, "Setting nextmap to %s due to players vote.", sMap);
						}
						else
						{
							LogAction(-1, -1, "ERROR: Failed to set nextmap to %s", sMap);
						}

						// Like map extensions, people expect that other MAP votes to get reset once a map wins.
						ResetVotes (MAP);
					}
				}
				else
				{
					PrintToChatAll("%t", "votes required", Votes, nVotesRequired);
				}
			}
		}
	}
}


RequiredVotes (voter, type, &required)
{
	new max = MaxClients, players = 0;
	for(new i = 1; i <= max; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;

		if ((type != MAP) && 
		    GetConVarBool (g_hVoteTeam[type]) && 
		    (GetClientTeam (i) != GetClientTeam(voter)))
		{
			continue;
		}

		players++;
	}

	new minVotes = GetConVarInt(g_hVoteMinimum[type]);

	required = RoundToCeil(float(players) * GetConVarFloat(g_hVoteRatio[type]));

	if(required < minVotes) required = minVotes;

}


// +------------------------------------------------------------------------
// | Important note about VotesFor:
// |
// | When type == BAN, target is the index into the dynamic ban arrays.
// | It is important that VotesFor not get passed client IDs when type == BAN!
// +---------------------------------------------------------------------------

VotesFor(target, type)
{
	new votes = 0;

	if (type == MAP)
	{
		for (new i = 1; i <= MAXPLAYERS; ++i)
		{
			votes = votes + GetArrayCell (g_hVotedForMap[i], target);
		}
	}
	else if (type == KICK)
	{
		for(new i = 1; i <= MAXPLAYERS; i++)
		{
			if(g_bVotedForKick[i][target])
			{
				votes++;
			}		
		}
	}
	else if (type == MUTE)
	{
		for(new i = 1; i <= MAXPLAYERS; i++)
		{
			if(g_bVotedForMute[i][target])
			{
				votes++;
			}		
		}
	}
	else if (type == BAN)
	{
		new nBanVotes;

		// target is the index into the dynamic arrays
		for(new i = 1; i <= MAXPLAYERS; i++)
		{
			nBanVotes = GetArraySize (g_hVotedForBan[i]);

			for (new j = 0; j < nBanVotes; ++j)
			{
				if (GetArrayCell (g_hVotedForBan[i], j) == target)
				{
					votes++;
				}
			}
		}
	}

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
		case BAN:
		{
			decl String:sReason[100];

			// Ban is already performed.  Just need to kick now.
			target = ReadPackCell(dp);
			ReadPackString (dp, sReason, sizeof(sReason));

			ServerCommand("kickid %d %s", target, sReason);

		}
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


// +-------------------------------------------------------------------------
// | Admin menu code starts here.
// +-------------------------------------------------------------------------

BuildAdminPvMenu()
{
	// Build the "Voting Commands" category

	g_hPvMenu = FindTopMenuCategory(g_hTopMenu, ADMINMENU_VOTINGCOMMANDS);
	
	if (g_hPvMenu != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hTopMenu, 
		             "pv_menu",
		             TopMenuObject_Item,
		             AdminMenu_Pv,
		             g_hPvMenu,
		             "pv_menu",
		             ADMFLAG_VOTE);
	}
}

public AdminMenu_Pv (Handle:topmenu,
                         TopMenuAction:action,
                         TopMenuObject:object_id,
                         param,
                         String:buffer[],
                         maxlength)
{
	if ((action == TopMenuAction_DisplayOption) ||
	    (action == TopMenuAction_DisplayTitle)
	   )
	{
		Format(buffer, maxlength, "%s", "PlayersVotes", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayPvMenu(param);
	}
}

DisplayPvMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_PvAdmin);
	
	decl String:title[100];
	decl String:sItemName[33];

	Format(title, sizeof(title), "%s:", "PlayersVotes");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	Format (sItemName, sizeof (sItemName), "%t", "cancel votes", "All");
	AddMenuItem (menu, "Ca", sItemName);

	Format (sItemName, sizeof (sItemName), "%t", "cancel votes", "Votemap");
	AddMenuItem (menu, "Cm", sItemName);

	Format (sItemName, sizeof (sItemName), "%t", "cancel votes", "Voteban");
	AddMenuItem (menu, "Cb", sItemName);

	Format (sItemName, sizeof (sItemName), "%t", "cancel votes", "Votemute");
	AddMenuItem (menu, "Cu", sItemName);

	Format (sItemName, sizeof (sItemName), "%t", "cancel votes", "Votekick");
	AddMenuItem (menu, "Ck", sItemName);

	if (g_bVoteIsDisabledByAdmin[MAP]  ||
	    g_bVoteIsDisabledByAdmin[BAN]  ||
	    g_bVoteIsDisabledByAdmin[MUTE] ||
	    g_bVoteIsDisabledByAdmin[KICK])
	{
		Format (sItemName, sizeof (sItemName), "%t", "enable voting", "All");
		AddMenuItem (menu, "T1", sItemName);
	}
	else
	{
		Format (sItemName, sizeof (sItemName), "%t", "disable voting", "All");
		AddMenuItem (menu, "T0", sItemName);
	}

	AddToggleVoteMenuItem (menu, "Tm", "Votemap",  MAP);
	AddToggleVoteMenuItem (menu, "Tb", "Voteban",  BAN);
	AddToggleVoteMenuItem (menu, "Tu", "Votemute", MUTE);
	AddToggleVoteMenuItem (menu, "Tk", "Votekick", KICK);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


AddToggleVoteMenuItem (Handle:menu, String:info[], String:name[], type)
{
	decl String:sItemName[33];

	// Don't even let the admin toggle the enable/disable state if the ConVars aren't setup.
	if (! IsVoteDisabledByConVar (type))
	{
		if (g_bVoteIsDisabledByAdmin[type])
		{
			Format (sItemName, sizeof (sItemName), "%t", "enable voting", name);
			AddMenuItem (menu, info, sItemName);
		}
		else
		{
			Format (sItemName, sizeof (sItemName), "%t", "disable voting", name);
			AddMenuItem (menu, info, sItemName);
		}
	}
}

ToggleAdminVoteEnable (client, type, String:name[])
{
	g_bVoteIsDisabledByAdmin[type] = ! g_bVoteIsDisabledByAdmin[type];
	if (g_bVoteIsDisabledByAdmin[type])
	{
		ShowActivity2 (client, "[SM] ", "%t", "disabled votes", name);
	}
	else
	{
		ShowActivity2 (client, "[SM] ", "%t", "enabled votes", name);
	}
}

public MenuHandler_PvAdmin (Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(g_hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[3];
		GetMenuItem(menu, param2, info, sizeof(info));

		if (info[0] == 'C')
		{
			switch (info[1])
			{
				case 'a':
				{
					ResetVotes (BAN);
					ResetVotes (MAP);
					ResetVotes (KICK);
					ResetVotes (MUTE);
					ShowActivity2 (param1, "[SM] ", "%t", "canceled votes", "All");
				}
				case 'b':
				{
					ResetVotes (BAN);
					ShowActivity2 (param1, "[SM] ", "%t", "canceled votes", "Voteban");
				}
				case 'm':
				{
					ResetVotes (MAP);
					ShowActivity2 (param1, "[SM] ", "%t", "canceled votes", "Votemap");
				}
				case 'u':
				{
					ResetVotes (MUTE);
					ShowActivity2 (param1, "[SM] ", "%t", "canceled votes", "Votemute");
				}
				case 'k':
				{
					ResetVotes (KICK);
					ShowActivity2 (param1, "[SM] ", "%t", "canceled votes", "Votekick");
				}
				default:
				{
					CloseHandle (menu);
				}
			}
		}
		else if (info[0] == 'T')
		{
			switch (info[1])
			{
				case '0':
				{
					g_bVoteIsDisabledByAdmin[MAP]  = true;
					g_bVoteIsDisabledByAdmin[BAN]  = true;
					g_bVoteIsDisabledByAdmin[MUTE] = true;
					g_bVoteIsDisabledByAdmin[KICK] = true;
					ShowActivity2 (param1, "[SM] ", "%t", "disabled votes", "All");
				}
				case '1':
				{
					g_bVoteIsDisabledByAdmin[MAP]  = false;
					g_bVoteIsDisabledByAdmin[BAN]  = false;
					g_bVoteIsDisabledByAdmin[MUTE] = false;
					g_bVoteIsDisabledByAdmin[KICK] = false;
					ShowActivity2 (param1, "[SM] ", "%t", "enabled votes", "All");
				}
				case 'b':
				{
					ToggleAdminVoteEnable (param1, BAN, "Voteban");
				}
				case 'm':
				{
					ToggleAdminVoteEnable (param1, MAP, "Votemap");
				}
				case 'u':
				{
					ToggleAdminVoteEnable (param1, MUTE, "Votemute");
				}
				case 'k':
				{
					ToggleAdminVoteEnable (param1, KICK, "Votekick");
				}
				default:
				{
					CloseHandle (menu);
				}
			}
		}
	}
}
