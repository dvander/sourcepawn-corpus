#include <sourcemod>
#include <sdktools>
#include "left4downtown.inc"

#define SCORE_VERSION "1.3.0"

#define SCORE_DEBUG 0
#define SCORE_DEBUG_LOG 1

#define SCORE_TEAM_A 1
#define SCORE_TEAM_B 2
#define SCORE_TYPE_ROUND 0
#define SCORE_TYPE_CAMPAIGN 1

#define SCORE_DELAY_PLACEMENT 0.1
#define SCORE_DELAY_TEAM_SWITCH 0.1
#define SCORE_DELAY_SWITCH_MAP 1.0
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define SCORE_DELAY_SCORE_SWAPPED 0.5

#define SCORE_LIST_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_REFRESH 0.5

#define SCORE_VERSION_REQUIRED_LEFT4DOWNTOWN "0.5.2.3"

#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define L4D_TEAM_SURVIVORS 2
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SPECTATE 1

#define L4D_TEAM_NAME(%1) (%1 == 2 ? "Survivors" : (%1 == 3 ? "Infected" : (%1 == 1 ? "Spectators" : "Unknown")))


#define SCORE_CAMPAIGN_OVERRIDE 1
#define SCORE_TEAM_PLACEMENT_OVERRIDE 0


forward OnReadyRoundRestarted();

public Plugin:myinfo = 
{
	name = "L4D2 Score/Team Manager",
	author = "Downtown1 & AtomicStryker",
	description = "Manage teams and scores in L4D2",
	version = SCORE_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1029519"
}

new Handle:gConf = INVALID_HANDLE;
new Handle:fGetTeamScore = INVALID_HANDLE;
new Handle:fClearTeamScores = INVALID_HANDLE;
new Handle:fSetCampaignScores = INVALID_HANDLE;

new Float:lastDisconnectTime;

new Handle:SpawnTimer    = INVALID_HANDLE;
new Handle:SurvivorLimit = INVALID_HANDLE;
/* Props to:
name        = "L4D Missing Survivors",
author      = "Damizean",
description = "Plugin to use with L4D Downtown to spawn missing survivors.",
url         = "elgigantedeyeso@gmail.com"
*/

new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

new Handle:cvarTeamSwapping = INVALID_HANDLE;
new Handle:cvarVoteScrambling = INVALID_HANDLE;
new Handle:cvarFullResetOnEmpty = INVALID_HANDLE;
new Handle:cvarGameMode = INVALID_HANDLE;
new Handle:cvarGameModeActive = INVALID_HANDLE;

new roundScores[3];    //store the round score, ignore index 0
new Handle:mapScores = INVALID_HANDLE;

new mapCounter;
new bool:skippingLevel;
new bool:BeforeMapStart = true;

new LastKnownScoreTeamA;
new LastKnownScoreTeamB;

new bool:roundCounterReset = false;

new bool:clearedScores = false;
new bool:roundRestarting = false;

/* Current Mission */
new bool:pendingNewMission;
new String:nextMap[128];

/* Team Placement */
new Handle:teamPlacementTrie = INVALID_HANDLE; //remember what teams to place after map change
new teamPlacementArray[256];  //after client connects, try to place him to this team
new teamPlacementAttempts[256]; //how many times we attempt and fail to place a person

new Handle:gConfRaw = INVALID_HANDLE;
new Address:g_pDirector = Address:0;
new Handle:fSwapTeams = INVALID_HANDLE;
new Handle:fAreTeamsFlipped = INVALID_HANDLE;
new Handle:fRestart = INVALID_HANDLE;


enum TeamSwappingType
{
	DefaultL4D2,
	HighestScoreInfectedFirst,
	SwapNever,
	SwapAlways,
	HighestScoreSurvivorFirstButFin,
};

#if SCORE_DEBUG
new bool:swapTeamsOverride;
#endif

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	PrepareAllSDKCalls();
	
	#if SCORE_DEBUG
	RegConsoleCmd("sm_setscore", Command_SetCampaignScores, "sm_setscore <team> <0|1>");
	RegConsoleCmd("sm_getscore", Command_GetTeamScore, "sm_getscore <team> <0|1>");
	RegConsoleCmd("sm_clearscore", Command_ClearTeamScores);
	
	RegConsoleCmd("sm_placement", Command_PrintPlacement);
	RegConsoleCmd("sm_changeteam", Command_ChangeTeam);
	
	RegAdminCmd("sm_swapnext", Command_SwapNext, ADMFLAG_BAN, "sm_swapnext - swap the players between both teams");
	
	RegAdminCmd("sm_changemap", Command_ChangeMap, ADMFLAG_CHANGEMAP, "sm_changemap <mapname> - change the current l4d map to mapname");
	
	RegAdminCmd("sm_setnextmap", Command_NextMap, ADMFLAG_CHANGEMAP, "sm_nextmap [mapname] - gets/sets the next map in the mission");
	#endif
	
	/*
	* Commands
	*/
	RegServerCmd("changelevel", Command_Changelevel);
	RegConsoleCmd("sm_printscores", Command_PrintScores, "sm_printscores");
	RegConsoleCmd("sm_scores", Command_Scores, "sm_scores - bring up a list of round scores");
	
	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_BAN, "sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", Command_SwapTo, ADMFLAG_BAN, "sm_swapto <player1> [player2] ... [playerN] <teamnum> - swap all listed players to <teamnum> (1,2, or 3)");
	RegAdminCmd("sm_swapteams", Command_SwapTeams, ADMFLAG_BAN, "sm_swapteams2 - swap the players between both teams");
	
	RegAdminCmd("sm_antirage", Command_AntiRage, ADMFLAG_BAN, "sm_antirage - swap teams and scores");
	RegAdminCmd("sm_scrambleteams", Command_ScrambleTeams, ADMFLAG_BAN, "sm_scrambleteams - swap the players randomly between both teams");
	RegAdminCmd("sm_lockteams", Command_LockTeams, ADMFLAG_BAN, "sm_lockteams - keep players in their assigned teams");
	RegConsoleCmd("sm_votescramble", Request_ScrambleTeams, "Allows Clients to call Scramble votes");
	
	RegAdminCmd("sm_resetscores", Command_ResetScores, ADMFLAG_BAN, "sm_resetscores - reset the currently tracked map scores");
	
	RegAdminCmd("sm_swapmenu", Command_SwapMenu, ADMFLAG_BAN, "sm_swapmenu - bring up a swap players menu");
	
	/*
	* Cvars
	*/
	CreateConVar("l4d2_team_manager_ver", SCORE_VERSION, "Version of the score/team manager plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarTeamSwapping = CreateConVar("l4d2_team_order", "0", "0 - default L4D2 behaviour; 1 - winning team goes infected first; 2 - teams never get swapped; 3 - ABAB teamswap every map; 4 - on finale winning team goes infected first", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarVoteScrambling = CreateConVar("l4d2_votescramble_allowed", "1", " Is Player Vote Scrambling admitted ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarFullResetOnEmpty = CreateConVar("l4d2_full_reset_on_empty", "0", " does the server load a new map when empty, fully resetting itself ", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cvarGameModeActive = CreateConVar("l4d2_scores_gamemodesactive", "versus,teamversus,mutation12", " Set the game modes for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ");
	cvarGameMode = FindConVar("mp_gamemode");
	
	/*
	* ADT Handles
	*/
	teamPlacementTrie = CreateTrie();
	if(teamPlacementTrie == INVALID_HANDLE)
	{
		LogError("Could not create the team placement trie! FATAL ERROR");
	}
	
	mapScores = CreateArray(2);
	if(mapScores == INVALID_HANDLE)
	{
		LogError("Could not create the map scores array! FATAL ERROR");
	}
	
	/*
	* Events
	*/
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_team", Event_PlayerTeam);
	
	DebugPrintToAll("Map counter = %d", mapCounter);
	
	//fix missing survivors
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn, EventHookMode_PostNoCopy);
	SurvivorLimit = FindConVar("survivor_limit");
	
	//fix no OnClearCampaignScores on Vote Changes
	RegConsoleCmd("callvote", Callvote_Handler);
	HookEvent("vote_passed", EventVoteEndSuccess);
	HookEvent("vote_failed", EventVoteEndFail);
}

public OnAllPluginsLoaded()
{	
	CheckDependencyVersions(/*throw*/true);
	/*
	*/
}

PrepareAllSDKCalls()
{
	gConf = LoadGameConfigFile("left4downtown.l4d2");
	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/left4downtown.l4d2.txt");
	}
	
	// GetTeamScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "GetTeamScore"))
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		fGetTeamScore = EndPrepSDKCall();
		
		if(fGetTeamScore == INVALID_HANDLE) {
			DebugPrintToAll("[TEST] Function 'GetTeamScore' found, but something went wrong.");
		}
		else
		{
			DebugPrintToAll("[TEST] Function 'GetTeamScore' initialized.");
		}
	}
	else
	{
		DebugPrintToAll("[TEST] Function 'GetTeamScore' not found.");
	}
	
	// ClearTeamScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "ClearTeamScores"))
	{
		fClearTeamScores = EndPrepSDKCall();
		
		if(fClearTeamScores == INVALID_HANDLE)
		{
			DebugPrintToAll("[TEST] Function 'ClearTeamScores' found, but something went wrong.");
		}
		else
		{
			DebugPrintToAll("[TEST] Function 'ClearTeamScores' initialized.");
		}
	}
	else
	{
		DebugPrintToAll("[TEST] Function 'ClearTeamScores' not found.");
	}
	
	// SetCampaignScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetCampaignScores"))
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		fSetCampaignScores = EndPrepSDKCall();
		if(fSetCampaignScores == INVALID_HANDLE)
		{
			DebugPrintToAll("[TEST] Function 'SetCampaignScores' found, but something went wrong.");
		}
		else
		{
			DebugPrintToAll("[TEST] Function 'SetCampaignScores' initialized.");
		}
	}
	else
	{
		DebugPrintToAll("[TEST] Function 'SetCampaignScores' not found.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
	
	
	
	/* From here on we use the new awesome SDK Calls */
	
	
	gConfRaw = LoadGameConfigFile("l4d2scores");
	if(gConfRaw == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/l4d2scoresraw.txt");
	}
	
	g_pDirector = GameConfGetAddress(gConfRaw, "CDirector");
	DebugPrintToAll("PTR to Director loaded at 0x%x", g_pDirector);
	if(g_pDirector == Address_Null)
	{
		ThrowError("Could not load the Director pointer");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	DebugPrintToAll("RestartScenarioFromVote Call prepped");
	if(!PrepSDKCall_SetFromConf(gConfRaw, SDKConf_Signature, "RestartScenarioFromVote"))
	{
		LogError("Could not load the RestartScenarioFromVote signature");
	}
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	DebugPrintToAll("RestartScenarioFromVote Signature prepped");
	fRestart = EndPrepSDKCall();
	if(fRestart == INVALID_HANDLE)
	{
		LogError("Could not prep the RestartScenarioFromVote function");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	DebugPrintToAll("SwapTeams Call prepped");
	if(!PrepSDKCall_SetFromConf(gConfRaw, SDKConf_Signature, "SwapTeams"))
	{
		LogError("Could not load the SwapTeams signature");
	}
	DebugPrintToAll("SwapTeams Signature prepped");
	fSwapTeams = EndPrepSDKCall();
	if(fSwapTeams == INVALID_HANDLE)
	{
		ThrowError("Could not prep the SwapTeams function");
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	DebugPrintToAll("AreTeamsFlipped Call prepped");
	if(!PrepSDKCall_SetFromConf(gConfRaw, SDKConf_Signature, "AreTeamsFlipped"))
	{
		LogError("Could not load the AreTeamsFlipped signature");
	}
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	DebugPrintToAll("AreTeamsFlipped Signature prepped");
	fAreTeamsFlipped = EndPrepSDKCall();
	if(fAreTeamsFlipped == INVALID_HANDLE)
	{
		ThrowError("Could not prep the AreTeamsFlipped function");
	}
}

// CDirector::SwapTeams()
stock L4D2_DirectorSwapTeams(bool:HideCorpses = false)
{
	DebugPrintToAll("About to SDKCall SwapTeams. g_pDirector=%x", g_pDirector);
	
	new Float:nullorigin[3];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		
		if (GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			ForcePlayerSuicide(i);
		}
		
		if (GetClientTeam(i) == 2 && HideCorpses)
		{
			TeleportEntity(i, nullorigin, NULL_VECTOR, NULL_VECTOR); // their corpses will be below the map somewhere
		}
	}
	
	SDKCall(fSwapTeams, g_pDirector);
}

// CDirector::RestartScenarioFromVote(const char *)
stock L4D2_RestartScenarioFromVote(const String:mapName[])
{
	DebugPrintToAll("About to SDKCall RestartScenarioFromVote. g_pDirector=%x", g_pDirector);
	SDKCall(fRestart, g_pDirector, mapName);	
}

// CDirector::AreTeamsFlipped(void)const
stock bool:L4D2_AreTeamsFlipped()
{
	DebugPrintToAll("About to SDKCall AreTeamsFlipped. g_pDirector=%x", g_pDirector);
	return bool:SDKCall(fAreTeamsFlipped, g_pDirector);
}

public OnPluginEnd()
{
	CloseHandle(teamPlacementTrie);
	CloseHandle(mapScores);
}

static bool:RoundEndDone;

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEndDone = false;
	
	/* sometimes round_start is invoked before OnMapStart */
	if(BeforeMapStart)
	{
		GetRoundCounter(false, true); //increment false, reset true
	}
	
	new roundCounter;
	//dont increment the round if round was restarted
	if(roundRestarting)
	{
		roundRestarting = false;
		roundCounter = GetRoundCounter();
	}
	else
	{
		roundCounter = GetRoundCounter(true); //increment
	}
	
	DebugPrintToAll("Round %d started, round scores: A: %d, B: %d", roundCounter, GetTeamRoundScore(SCORE_TEAM_A), GetTeamRoundScore(SCORE_TEAM_B));
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CheckZeroIngameBug();

	if(RoundEndDone)
	{
		RoundEndDone = false;
		DebugPrintToAll("Double Round End prevented");
		return;
	}
	
	RoundEndDone = true;
	
	decl String:gamemode[64], String:gamemodeactive[64];
	GetConVarString(cvarGameMode, gamemode, sizeof(gamemode));
	
	if (StrContains(gamemode, "scavenge") != -1)
	{
		DebugPrintToAll("Scavenge Round End, nothing to do here.");
		return;
	}
	
	if (StrEqual(gamemode, "coop"))
	{
		DebugPrintToAll("Coop Round End, nothing to do here.");
		return;
	}
	
	if (StrEqual(gamemode, "survival") && GetTeamHumanCount(3) > 0)
	{
		PrintToChatAll("[SM] Modded Survival Round End detected. Teamswap in 10 seconds.");
		CreateTimer(10.0, SurvivalTeamSwap, 0);
		return;
	}
	
	GetConVarString(cvarGameModeActive, gamemodeactive, sizeof(gamemodeactive));
	if (StrContains(gamemodeactive, gamemode) == -1)
	{
		DebugPrintToAll("Gamemode %s round_end - gamemode not among active gamemodes - aborting", gamemode);
		return;
	}

	new roundCounter = GetRoundCounter();
	if(roundCounter > 2)
		return; // saw round 3 a few times in my logs, and crashes along with it.	

	DebugPrintToAll("Round %d end, round scores: A: %d, B: %d", roundCounter, GetTeamRoundScore(SCORE_TEAM_A), GetTeamRoundScore(SCORE_TEAM_B));
	
	if(roundRestarting)
		return;

	//figure out what to put the next map teams with
	//before all the clients are actually disconnected
	
	if(!IsFirstRound())
	{
		#if SCORE_DEBUG
		if(!swapTeamsOverride && !SCORE_TEAM_PLACEMENT_OVERRIDE)
		#endif

		DebugPrintToAll("Next map Team Placement will be calculated now, Teamswaptype = %i", GetConVarInt(cvarTeamSwapping));			
		CalculateNextMapTeamPlacement();
		
		#if SCORE_DEBUG
		else DebugPrintToAll("Skipping next map team placement, as its overridden");
		#endif
	}
}

CheckZeroIngameBug()
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			return;
	}
	
	OnNewMission();
	GetRoundCounter(false, true); //increment false, reset true
	DebugPrintToAll("Zero-Ingame Bug round end detected, resetting Plugin");
}

public Action:SurvivalTeamSwap(Handle:timer)
{
	ClearTeamPlacement();

	PrintToChatAll("[SM] Survivor and Infected teams have been swapped.");
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}
	
	TryTeamPlacementDelayed();
}

public Action:Command_LockTeams(client, args)
{
	decl String:gamemode[64];
	new Handle:mode = cvarGameMode;
	
	GetConVarString(mode, gamemode, sizeof(gamemode));
	
	if (StrEqual(gamemode, "versus", false))
	{
		SetConVarString(mode, "teamversus");
		PrintToChatAll("[SM] Teams are locked now, you may not change them on your own.");
	}
	else if (StrEqual(gamemode, "teamversus", false))
	{
		SetConVarString(mode, "versus");
		PrintToChatAll("[SM] Teams are unlocked now, you may change them on your own.");
	}
	else if (StrEqual(gamemode, "scavenge", false))
	{
		SetConVarString(mode, "teamscavenge");
		PrintToChatAll("[SM] Teams are locked now, you may not change them on your own.");
	}
	else if (StrEqual(gamemode, "teamscavenge", false))
	{
		SetConVarString(mode, "scavenge");
		PrintToChatAll("[SM] Teams are unlocked now, you may change them on your own.");
	}

	CloseHandle(mode);
	return Plugin_Handled;
}

public Action:Command_ResetScores(client, args)
{
	ResetRoundScores();
	
	PrintToChatAll("[SM] The Round scores have been reset.");	
	return Plugin_Handled;
}

public Action:Command_SwapTeams(client, args)
{
	ClearTeamPlacement();

	PrintToChatAll("[SM] Survivor and Infected teams have been swapped.");
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}
	
	TryTeamPlacementDelayed();
	
	return Plugin_Handled;
}

public Action:Command_AntiRage(client, args)
{
	ClearTeamPlacement();
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}
	
	L4D2_DirectorSwapTeams();

	PrintToChatAll("[SM] Teams and Scores swapped. No post-Infected raging for YOU!!!!");
	
	TryTeamPlacementDelayed();

	return Plugin_Handled;
}


public Action:Command_Swap(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
		return Plugin_Handled;
	}
	
	decl String:player[64];
	
	for(new i = 0; i < args; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		new player_id = FindTarget(client, player, true /*nobots*/, false /*immunity*/);
		
		if(player_id == -1)
			continue;
		
		decl String:authid[128], team;
		GetClientAuthString(player_id, authid, sizeof(authid));
		if(GetTrieValue(teamPlacementTrie, authid, team))
			RemoveFromTrie(teamPlacementTrie, authid);
		
		team = GetOppositeClientTeam(player_id);
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
	}
	
	TryTeamPlacement();
	
	return Plugin_Handled;
}


public Action:Command_SwapTo(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swapto <player1> [player2] ... [playerN] <teamnum> - swap all listed players to team <teamnum> (1,2,or 3)");
		return Plugin_Handled;
	}
	
	decl String:teamStr[64];
	GetCmdArg(args, teamStr, sizeof(teamStr))
	new team = StringToInt(teamStr);
	
	if(!team)
	{
		ReplyToCommand(client, "[SM] Invalid team %s specified, needs to be 1, 2, or 3", teamStr);
		return Plugin_Handled;
	}
	
	decl String:player[64];
	
	for(new i = 0; i < args - 1; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		new player_id = FindTarget(client, player, true /*nobots*/, false /*immunity*/);
		
		if(player_id == -1)
			continue;
		
		decl String:authid[128];
		GetClientAuthString(player_id, authid, sizeof(authid));
		if(GetTrieValue(teamPlacementTrie, authid, team))
			RemoveFromTrie(teamPlacementTrie, authid);
		
		team = StringToInt(teamStr);
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
	}
	
	TryTeamPlacement();
	
	return Plugin_Handled;
}

public Action:Command_NextMap(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] The next map in the mission is %s", nextMap);
		
		return Plugin_Handled;
	}
	
	decl String:arg1[128];
	GetCmdArg(1, arg1, 128);
	
	if(IsMapValid(arg1))
	{
		strcopy(nextMap, sizeof(nextMap), arg1);
		ReplyToCommand(client, "[SM] Set next map to %s", arg1);
	}
	else
	{
		ReplyToCommand(client, "[SM] %s is not a valid map", arg1);
	}
	
	return Plugin_Handled;
}

/*
* This is called when a new "mission" has started
* (by us)
*/
OnNewMission()
{
	DebugPrintToAll("New mission detected.");
	
	ResetCampaignScores();
	
	ClearTeamPlacement();
	
	pendingNewMission = false;
}

public Action:L4D_OnSetCampaignScores(&scoreA, &scoreB)
{
	DebugPrintToAll("FORWARD: OnSetCampaignScores(%d,%d)", scoreA, scoreB);
	
	LastKnownScoreTeamA = scoreA;
	LastKnownScoreTeamB = scoreB;
	
	if (!scoreA && !scoreB && BeforeMapStart)
		OnNewMission();
	
	return Plugin_Continue;
}

public Action:L4D_OnClearTeamScores(bool:newCampaign)
{
	/*
	* this function gets called twice at the beginning of each map
	* skip it the second time
	*/
	if(clearedScores)
	{
		clearedScores = false;
	}
	else
	{
		clearedScores = true;
		
		DebugPrintToAll("FORWARD: OnClearTeamScores(%b)", newCampaign); 
		
		if (newCampaign) OnNewMission();
		
		ResetRoundScores();
	}
	
	return Plugin_Continue;
}

public OnReadyRoundRestarted()
{
	DebugPrintToAll("FORWARD: OnReadyRoundRestarted triggered");
	roundRestarting = true;
}

public OnMapStart()
{		
	DebugPrintToAll("ON MAP START FUNCTION");
	BeforeMapStart = false;
	
	if(!roundCounterReset)
		GetRoundCounter(false, true); //increment false, reset true
	
	#if SCORE_DEBUG
	swapTeamsOverride = false;
	#endif
	
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	//if we are skipping the level
	//do not skip it if we already ended up on it
	if(skippingLevel && !StrEqual(mapname, nextMap, false))
	{
		//we should be skipping to this map lets get to it
		CreateTimer(SCORE_DELAY_SWITCH_MAP, Timer_SwitchToNextMap, _);
		
		return;
	}
	
	if(pendingNewMission)
	{
		OnNewMission();
		mapCounter = 0;
	}
	else
	{
		mapCounter++;
		DebugPrintToAll("Map counter now = %d", mapCounter);
	}
	
	skippingLevel = false;
	nextMap[0] = 0;
	
	ResetRoundScores();
}

public Action:Timer_SwitchToNextMap(Handle:timer)
{
	ServerCommand("changelevel %s", nextMap);
}

public OnMapEnd()
{
	roundCounterReset = false;
	BeforeMapStart = true;
	
	if(skippingLevel)
	{
		skippingLevel = false;
		return;
	}
	
	/* leaving a map early before its completed/started */
	if(IsFirstRound())
	{
		mapCounter--;
		return;
	}
	
	/* leaving a map right after the scores were reset */
	if(mapCounter == 1 
	&& roundScores[SCORE_TEAM_A] == -1 && roundScores[SCORE_TEAM_B] == -1)
	{
		return;
	}
	DebugPrintToAll("Map counter now = %d", mapCounter);
	
	/*
	* Update the map scores
	*/
	new scores[2];
	scores[0] = roundScores[SCORE_TEAM_A];
	scores[1] = roundScores[SCORE_TEAM_B];
	PushArrayArray(mapScores, scores);
	
	/*
	* Is the game about to automatically swap teams on us?
	*/
	new bool:pendingSwapScores = false;
	if (LastKnownScoreTeamA > LastKnownScoreTeamB)
	{
		pendingSwapScores = true;
	}
	
	if (pendingSwapScores)
	{
		DebugPrintToAll("pendingSwapScores = true detected, L4D2 will swap teams and scores next map");
	}
	else
	{
		DebugPrintToAll("pendingSwapScores = false detected, L4D2 will keep teams and scores next map");
	}
	
	/*
	* Try to figure out if we should swap scores 
	* at the beginning of the next map
	*/
	new TeamSwappingType:swapKind = TeamSwappingType:GetConVarInt(cvarTeamSwapping);
	new bool:performSwapNextLevel;
	
	if (swapKind == HighestScoreSurvivorFirstButFin && IsFinaleMapNextUp())
		{
			swapKind = HighestScoreInfectedFirst;
		}
		
	switch(swapKind)
	{
		case HighestScoreInfectedFirst: //if Infected are to begin always, we must check current teamflip status and pending score swap
		{
			performSwapNextLevel = L4D2_AreTeamsFlipped() ? !pendingSwapScores : pendingSwapScores;
		}
		case SwapAlways:
		{
			performSwapNextLevel = true;
		}
		case SwapNever: //if teams are to remain the same, we must swap everytime L4D2 wants to swap internally
		{
			performSwapNextLevel = pendingSwapScores;
		}
		default:
		{
			performSwapNextLevel = false;
		}
	}
		
	//schedule a pending skip level to the next map
	if(strlen(nextMap) > 0 && IsMapValid(nextMap))
	{
		skippingLevel = true;
	}
	
	// Destroy timer if necessary.
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
	
	if(performSwapNextLevel)
	{
		L4D2_DirectorSwapTeams(true);
	}
}

CalculateNextMapTeamPlacement()
{
	/*
	* Is the game about to automatically swap teams on us?
	*/
	
	new bool:pendingSwapScores = false;
	if (LastKnownScoreTeamA > LastKnownScoreTeamB)
	{
		pendingSwapScores = true;
	}
	
	new bool:AreTeamsFlipped = L4D2_AreTeamsFlipped();
	
	if (AreTeamsFlipped)
		DebugPrintToAll("Current Map End AreTeamsFlipped = true detected, aka default Order");
	else
		DebugPrintToAll("Current Map End AreTeamsFlipped = false detected, aka swapped Order");
	
	/*
	* We place everyone on whatever team they should be on
	* according to the set swapping type
	*/
	ClearTeamPlacement();
	
	decl String:authid[128], team;
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
	{
		if(IsClientInGameHuman(i)) 
		{
			GetClientAuthString(i, authid, sizeof(authid));
			team = GetClientTeamForNextMap(i, pendingSwapScores, AreTeamsFlipped);
			
			DebugPrintToAll("Next map will place %N, now %d, to %d", i, GetClientTeam(i), team);
			SetTrieValue(teamPlacementTrie, authid, team);
		}
	}
}

/* 
* **************
* TEAM PLACEMENT (beginning of map)
* **************
*/

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetRoundCounter() != 1) return; // to avoid phantom swapping prior to mapchange on round 2
	
	if (BeforeMapStart) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientInGameHuman(client)) return;

	decl team, String:authid[256];
	GetClientAuthString(client, authid, sizeof(authid));
		
	if(GetTrieValue(teamPlacementTrie, authid, team))
	{
		teamPlacementArray[client] = team;
		RemoveFromTrie(teamPlacementTrie, authid);
		DebugPrintToAll("Team Event: Put %N to team %d as Trie commands", client, team);
	}
	
	TryTeamPlacementDelayed();
}

public OnClientDisconnect(client)
{
	//DebugPrintToAll("Client %d disconnected", client);
	
	if (IsClientInGame(client) && IsFakeClient(client)) return;
	//to reduce testing spam solely.
	
	if(skippingLevel) return;
	
	TryTeamPlacementDelayed();
	
	/*
	* See if the server is now empty?
	*/
	
	new Float:currenttime = GetGameTime();
	
	if (lastDisconnectTime == currenttime) return;
	
	CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
	lastDisconnectTime = currenttime;
}

public Action:IsNobodyConnected(Handle:timer, any:timerDisconnectTime)
{
	if (timerDisconnectTime != lastDisconnectTime) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return  Plugin_Stop;
	}
	
	OnNewMission();
	DebugPrintToAll("Server detected as empty, resetting Plugin");
	
	SetConVarInt(FindConVar("sb_all_bot_game"), 0);
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
	
	if (GetConVarBool(cvarFullResetOnEmpty))
	{
		DebugPrintToAll("Also doing a full reset by mapchange");
		ServerCommand("map c1m1_hotel");
	}
	
	return  Plugin_Stop;
}


/*
* Do a delayed "team placement"
* 
* This way all the pending team changes will go through instantly
* and we don't end up in TryTeamPlacement again before then
*/
new bool:pendingTryTeamPlacement;

TryTeamPlacementDelayed()
{
	if(!pendingTryTeamPlacement)
	{
		CreateTimer(SCORE_DELAY_PLACEMENT, Timer_TryTeamPlacement);	
		pendingTryTeamPlacement = true;
	}
}

public Action:Timer_TryTeamPlacement(Handle:timer)
{
	TryTeamPlacement();
	pendingTryTeamPlacement = false;
}

/*
* Try to place people on the right teams
* after some kind of event happens that allows someone to be moved.
* 
* Should only be called indirectly by TryTeamPlacementDelayed()
*/
TryTeamPlacement()
{
	SetConVarInt(FindConVar("sb_all_bot_game"), 1); // necessary to avoid 0 human Survivor server bugs
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
	
	/*
	* Calculate how many free slots a team has
	*/
	new free_slots[4];
	
	free_slots[L4D_TEAM_SPECTATE] = GetTeamMaxHumans(L4D_TEAM_SPECTATE);
	free_slots[L4D_TEAM_SURVIVORS] = GetTeamMaxHumans(L4D_TEAM_SURVIVORS);
	free_slots[L4D_TEAM_INFECTED] = GetTeamMaxHumans(L4D_TEAM_INFECTED);	
	
	free_slots[L4D_TEAM_SURVIVORS] -= GetTeamHumanCount(L4D_TEAM_SURVIVORS);
	free_slots[L4D_TEAM_INFECTED] -= GetTeamHumanCount(L4D_TEAM_INFECTED);
	
	DebugPrintToAll("TP: Trying to do team placement (free slots %d/%d)...", free_slots[L4D_TEAM_SURVIVORS], free_slots[L4D_TEAM_INFECTED]);
	
	/*
	* Try to place people on the teams they should be on.
	*/
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
	{
		if(IsClientInGameHuman(i)) 
		{
			new team = teamPlacementArray[i];
			
			//client does not need to be placed? then skip
			if(!team)
			{
				continue;
			}
			
			new old_team = GetClientTeam(i);
			
			//client is already on the right team
			if(team == old_team)
			{
				teamPlacementArray[i] = 0;
				teamPlacementAttempts[i] = 0;
				
				DebugPrintToAll("TP: %N is already on correct team (%d)", i, team);
			}
			//there's still room to place him on the right team
			else if (free_slots[team] > 0)
			{
				ChangePlayerTeamDelayed(i, team);
				DebugPrintToAll("TP: Moving %N to %d soon", i, team);
				
				free_slots[team]--;
				free_slots[old_team]++;
			}
			/*
			* no room to place him on the right team,
			* so lets just move this person to spectate
			* in anticipation of being to move him later
			*/
			else
			{
				DebugPrintToAll("TP: %d attempts to move %N to team %d", teamPlacementAttempts[i], i, team);
				
				/*
				* don't keep playing in an infinite join spectator loop,
				* let him join another team if moving him fails
				*/
				if(teamPlacementAttempts[i] > 0)
				{
					DebugPrintToAll("TP: Cannot move %N onto %d, team full", i, team);
					
					//client joined a team after he was moved to spec temporarily
					if(GetClientTeam(i) != L4D_TEAM_SPECTATE)
					{
						DebugPrintToAll("TP: %N has willfully moved onto %d, cancelling placement", i, GetClientTeam(i));
						teamPlacementArray[i] = 0;
						teamPlacementAttempts[i] = 0;
					}
				}
				/*
				* place him to spectator so room on the previous team is available
				*/
				else
				{
					free_slots[L4D_TEAM_SPECTATE]--;
					free_slots[old_team]++;
					
					DebugPrintToAll("TP: Moved %N to spectator, as %d has no room", i, team);
					
					ChangePlayerTeamDelayed(i, L4D_TEAM_SPECTATE);
					
					teamPlacementAttempts[i]++;
				}
			}
		}
		//the player is a bot, or disconnected, etc.
		else 
		{
			if(!IsClientConnected(i) || IsFakeClient(i)) 
			{
				if(teamPlacementArray[i])
					DebugPrintToAll("TP: Defaultly removing %d from placement consideration", i);
				
				teamPlacementArray[i] = 0;
				teamPlacementAttempts[i] = 0;
			}			
		}
	}
	
	/* If somehow all 8 players are connected and on opposite teams
	*  then unfortunately this function will not work.
	*  but of course this should not be called in that case,
	*  instead swapteams can be used
	*/
}

ClearTeamPlacement()
{
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
	{
		teamPlacementArray[i] = 0;
		teamPlacementAttempts[i] = 0;
	}
	
	ClearTrie(teamPlacementTrie);
}


/*
* When we are at the end of a map,
* we will need to swap clients around based on the swapping type
* 
* Figure out which team the client will go on next map.
*/
GetClientTeamForNextMap(client, bool:pendingSwapScores = false, bool:AreTeamsFlipped)
{
	new TeamSwappingType:swapKind = TeamSwappingType:GetConVarInt(cvarTeamSwapping);
	decl team;
	
	//same type of logic except on the finale, in which we flip it
	if(swapKind == HighestScoreSurvivorFirstButFin)
	{
		if (!IsFinaleMapNextUp())
			swapKind = DefaultL4D2;
		else swapKind = HighestScoreInfectedFirst;
	}
	
	switch(GetClientTeam(client))
	{
		case L4D_TEAM_INFECTED:
		{
			//default, dont swap teams
			team = L4D_TEAM_SURVIVORS;
			
			switch(swapKind)
			{
				case HighestScoreInfectedFirst:
				{
					if (AreTeamsFlipped)
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
				case SwapAlways:
				{
					team = L4D_TEAM_INFECTED;
				}
				case SwapNever:
				{
					team = L4D_TEAM_SURVIVORS;
				}
				case DefaultL4D2:
				{
					if (AreTeamsFlipped)
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
			}
		}
		
		case L4D_TEAM_SURVIVORS:
		{
			//default, dont swap teams
			team = L4D_TEAM_INFECTED;
			
			switch(swapKind)
			{
				case HighestScoreInfectedFirst:
				{
					if (AreTeamsFlipped)
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
				case SwapAlways:
				{
					team = L4D_TEAM_SURVIVORS;
				}
				case SwapNever:
				{
					team = L4D_TEAM_INFECTED;
				}
				case DefaultL4D2:
				{
					if (AreTeamsFlipped)
						team = !pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
					else
						team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
			}
		}
		
		default:
		{
			team = L4D_TEAM_SPECTATE;
		}
	}
	
	DebugPrintToAll("Applying final teamswap %d to %N, new team = %i", swapKind, client, team);
	return team;
}

ResetCampaignScores()
{
	mapCounter = 1;
	ClearArray(mapScores);
	
	DebugPrintToAll("Round/Map scores have been reset.");
}

ResetRoundScores()
{
	roundScores[SCORE_TEAM_A] = -1;
	roundScores[SCORE_TEAM_B] = -1;
}

/*
* ****************
* STOCK FUNCTIONS
* ****************
*/

stock GetTeamRoundScore(logical_team)
{
	return SDKCall(fGetTeamScore, logical_team, SCORE_TYPE_ROUND);	
}

stock bool:IsFirstRound()
{
	//when one team has not played yet, their score is N/A (-1)
	/*	return GetTeamRoundScore(SCORE_TEAM_A) == -1
	|| GetTeamRoundScore(SCORE_TEAM_B) == -1; */	
	return (GetRoundCounter() == 1);
}

stock OppositeLogicalTeam(logical_team)
{
	if(logical_team == SCORE_TEAM_A)
		return SCORE_TEAM_B;
	
	else if(logical_team == SCORE_TEAM_B)
		return SCORE_TEAM_A;
	
	else
	return -1;
}

/*
* Return the opposite team of that the client is on
*/
stock GetOppositeClientTeam(client)
{
	return OppositeCurrentTeam(GetClientTeam(client));	
}

stock OppositeCurrentTeam(team)
{
	if(team == L4D_TEAM_INFECTED)
		return L4D_TEAM_SURVIVORS;
	else if(team == L4D_TEAM_SURVIVORS)
		return L4D_TEAM_INFECTED;
	else if(team == L4D_TEAM_SPECTATE)
		return L4D_TEAM_SPECTATE;
	
	else
	return -1;
}

stock ChangePlayerTeamDelayed(client, team)
{
	new Handle:pack;
	
	CreateDataTimer(SCORE_DELAY_TEAM_SWITCH, Timer_ChangePlayerTeam, pack);	
	
	WritePackCell(pack, client);
	WritePackCell(pack, team);
}

public Action:Timer_ChangePlayerTeam(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	
	ChangePlayerTeam(client, team);
}

stock bool:ChangePlayerTeam(client, team)
{
	if(GetClientTeam(client) == team) return true;
	
	if(team != L4D_TEAM_SURVIVORS)
	{
		//we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}
	
	if(GetTeamHumanCount(team) == GetTeamMaxHumans(team))
	{
		DebugPrintToAll("ChangePlayerTeam() : Cannot switch %N to team %d, as team is full", client, team);
		return false;
	}
	
	new bot;
	//for survivors its more tricky
	for(bot = 1; 
	bot < L4D_MAXCLIENTS_PLUS1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != L4D_TEAM_SURVIVORS));
	bot++) {}
	
	if(bot == L4D_MAXCLIENTS_PLUS1)
	{
		DebugPrintToAll("Could not find a survivor bot, adding a bot ourselves");
		
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		
		ServerCommand("sb_add");
		
		SetCommandFlags(command, flags);
		
		DebugPrintToAll("Added a survivor bot, trying again...");
		return false;
	}
	
	//have to do this to give control of a survivor bot
	SDKCall(fSHS, bot, client);
	SDKCall(fTOB, client, true);
	
	return true;
}

//client is in-game and not a bot
stock bool:IsClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) == team)
		{
			humans++
		}
	}
	
	return humans;
}

stock GetTeamMaxHumans(team)
{
	if(team == L4D_TEAM_SURVIVORS)
	{
		return GetConVarInt(FindConVar("survivor_limit"));
	}
	else if(team == L4D_TEAM_INFECTED)
	{
		return GetConVarInt(FindConVar("z_max_player_zombies"));
	}
	else if(team == L4D_TEAM_SPECTATE)
	{
		return L4D_MAXCLIENTS;
	}
	
	return -1;
}

public Action:Command_ChangeMap(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_changemap <mapname>");
	}
	if(args > 0)
	{
		new String:map[128];
		GetCmdArg(1, map, 128);
		
		if(IsMapValid(map))
		{			
			ReplyToCommand(client, "[SM] The map is now changing to %s", map);		
			ServerCommand("changelevel %s", map);
			
			pendingNewMission = true;
		}	
		else
		{
			ReplyToCommand(client, "[SM] The map specified is invalid");
		}
	}
	return Plugin_Handled;
}

//***********************************************************************************************

public Action:Command_ScrambleTeams(client, args)
{
	PrintToChatAll("[SM] Teams are being scrambled now.");
	ScrambleTeams();
	
	return Plugin_Handled;
}

new bool:VoteWasDone;

public Action:Request_ScrambleTeams(client, args)
{
	if (!GetConVarBool(cvarVoteScrambling))
	{
		ReplyToCommand(client, "The server currently does not allow vote scrambling.");
		return Plugin_Handled;
	}

	if (!VoteWasDone)
	{
		DisplayScrambleVote();
		VoteWasDone = true;
		CreateTimer(60.0, ResetVoteDelay, 0);
	}
	else ReplyToCommand(client, "Vote was called already.");
	
	return Plugin_Handled;
}

public Action:ResetVoteDelay(Handle:timer)
{
	VoteWasDone = false;
}

stock ScrambleTeams()
{
	new humanspots = GetTeamMaxHumans(L4D_TEAM_SURVIVORS);
	new infspots = GetTeamMaxHumans(L4D_TEAM_INFECTED);
	new humanplayers, infplayers, players;
	
	// get ingame player count
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
			players++;
	}
	// half of that
	players = players/2;
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			switch(GetRandomInt(2,3))
			{
				case 2:
				{
					if (humanspots < 1 || humanplayers >= players) // if theres no spots or half players are allocated already
					{
						teamPlacementArray[i] = 3;
					}
					else
					{
						teamPlacementArray[i] = 2;
						humanplayers++;
						humanspots--;
					}
				}
				case 3:
				{
					if (infspots < 1 || infplayers >= players) // if theres no spots or half players are allocated already
					{
						teamPlacementArray[i] = 2;
					}
					else
					{
						teamPlacementArray[i] = 3;
						infplayers++;
						infspots--;
					}
				}
			}
		}
	}
	
	TryTeamPlacementDelayed();
}

new Handle:ScrambleVoteMenu = INVALID_HANDLE;

DisplayScrambleVote()
{
	ScrambleVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(ScrambleVoteMenu, "Do you want teams scrambled?");
	
	AddMenuItem(ScrambleVoteMenu, "0", "No");
	AddMenuItem(ScrambleVoteMenu, "1", "Yes");
	
	SetMenuExitButton(ScrambleVoteMenu, false);
	
	VoteMenuToAll(ScrambleVoteMenu, 20);
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes), float(totalVotes));
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(ScrambleVoteMenu);
	}
	
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("No votes detected on the scramble vote.");
	}
	
	else if (action == MenuAction_VoteEnd)
	{
		decl String:item[256], String:display[256], Float:percent;
		new votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
		
		percent = GetVotePercent(votes, totalVotes);
		
		PrintToChatAll("Scramble vote successful: %s (Received %i%% of %i votes)", display, RoundToNearest(100.0*percent), totalVotes);
		
		new winner = StringToInt(item);
		if (winner) ScrambleTeams();
	}
}

/*
* Detect 'rcon changelevel' and print warning messages
*/
public Action:Command_Changelevel(args)
{
	if(args > 0)
	{
		new String:map[128];
		GetCmdArg(1, map, 128);
		
		if(IsMapValid(map) && !skippingLevel)
		{
			DebugPrintToAll("Changelevel execute detected");
		}
	}
	return Plugin_Continue;
}

public Action:Command_PrintScores(client, args)
{
	DebugPrintToAll("Command_PrintScores, mapCounter = %d", mapCounter);
	
	new i, scores[2], curscore, scoresSize = GetArraySize(mapScores);
	PrintToChatAll("[SM] Printing map scores:");
	
	PrintToChatAll("Lobby Survivors: ");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[0];
		
		PrintToChatAll("%d. %d", i+1, curscore);
	}
	PrintToChatAll("- Campaign: %d", LastKnownScoreTeamA);
	
	PrintToChatAll("Lobby Infected: ");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[1];
		
		PrintToChatAll("%d. %d", i+1, curscore);
	}
	PrintToChatAll("- Campaign: %d", LastKnownScoreTeamB);
	
	return Plugin_Handled;
}

//show a menu of round and total scores
public Action:Command_Scores(client, args)
{
	DebugPrintToAll("Command_Scores, mapCounter = %d", mapCounter);
	
	new Handle:panel = CreatePanel();
	decl String:panelLine[1024];
	
	new i, scores[2], curscore, scoresSize = GetArraySize(mapScores);
	
	DrawPanelText(panel, "Team Scores");
	DrawPanelText(panel, " ");
	
	Format(panelLine, sizeof(panelLine), "SURVIVORS (%d)", LastKnownScoreTeamA);
	DrawPanelText(panel, panelLine);
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[0];
		
		Format(panelLine, sizeof(panelLine), "->%d. %d", i+1, curscore);
		DrawPanelText(panel, panelLine);
	}
	
	DrawPanelText(panel, " ");
	Format(panelLine, sizeof(panelLine), "INFECTED (%d)", LastKnownScoreTeamB);
	DrawPanelText(panel, panelLine);
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[1];
		
		Format(panelLine, sizeof(panelLine), "->%d. %d", i+1, curscore);
		DrawPanelText(panel, panelLine);
	}
	
	SendPanelToClient(panel, client, Menu_ScorePanel, SCORE_LIST_PANEL_LIFETIME);	
	
	CloseHandle(panel);
	
	return Plugin_Handled;
}
public Menu_ScorePanel(Handle:menu, MenuAction:action, param1, param2) { return; }


/*
* SWAP MENU FUNCTIONALITY
*/

new swapClients[256];
public Action:Command_SwapMenu(client, args)
{
	DebugPrintToAll("Command_Scores, mapCounter = %d", mapCounter);
	
	//new Handle:panel = CreatePanel();
	decl String:panelLine[1024];
	decl String:itemValue[32];
	
	//new i, numPlayers = 0;
	//->%d. %s makes the text yellow
	// otherwise the text is white
	
	#if SCORE_DEBUG
	new teamIdx[] = {2, 3, 1, 3};
	new String:teamNames[][] = {"SURVIVORS","INFECTED","SPECTATORS","INFECTED"};
	#else
	new teamIdx[] = {2, 3, 1};
	new String:teamNames[][] = {"SURVIVORS","INFECTED","SPECTATORS"};
	#endif
	
	new Handle:menu = CreateMenu(Menu_SwapPanel);
	SetMenuPagination(menu, MENU_NO_PAGINATION);
	
	new i = Helper_GetNonEmptyTeam(teamIdx, sizeof(teamIdx), 0);
	new itemIdx = 0;
	
	if (i != -1)
	{
		SetMenuTitle(menu, teamNames[i]);
	}
	while(i != -1)
	{
		new idxNext = Helper_GetNonEmptyTeam(teamIdx, sizeof(teamIdx), i+1);
		
		new team = teamIdx[i];
		new teamCount = GetTeamHumanCount(team);
		
		new numPlayers = 0;
		for(new j = 1; j < L4D_MAXCLIENTS_PLUS1; j++)
		{
			if(IsClientInGameHuman(j) && GetClientTeam(j) == team)
			{
				numPlayers++;
				
				if(numPlayers != teamCount || idxNext == -1)
				{
					Format(panelLine, 1024, "%N", j);
				}
				else
				{
					Format(panelLine, 1024, "%N\n%s", j, teamNames[idxNext]);
				}
				Format(itemValue, sizeof(itemValue), "%d", j);
				DebugPrintToAll("Added item with value = %s", itemValue);
				
				AddMenuItem(menu, itemValue, panelLine);
				
				swapClients[itemIdx] = j;
				itemIdx++;
			}
		}
		
		i = idxNext;
	}
	
	DisplayMenu(menu, client, SCORE_SWAPMENU_PANEL_LIFETIME);
	
	return Plugin_Handled;
}

//iterate through all teamIdx and find first non-empty team, return that team idx
Helper_GetNonEmptyTeam(const teamIdx[], size, startIdx)
{
	if(startIdx >= size || startIdx < 0)
	{
		return -1;
	}
	
	for(new i = startIdx; i < size; i++)
	{
		new team = teamIdx[i];
		
		new humans = GetTeamHumanCount(team);
		if(humans > 0)
		{
			return i;
		}
	}
	
	return -1;
}

public Menu_SwapPanel(Handle:menu, MenuAction:action, param1, param2) { 
	if (action == MenuAction_Select)
	{
		new client = param1;
		new itemPosition = param2;
		
		DebugPrintToAll("MENUSWAP: Action %d You selected item: %d", action, param2)
		
		new String:infobuf[16];
		GetMenuItem(menu, itemPosition, infobuf, sizeof(infobuf));
		
		DebugPrintToAll("MENUSWAP: Menu item was %s", infobuf);
		
		new player_id = swapClients[itemPosition];
		
		//swap and redraw menu
		new team = GetOppositeClientTeam(player_id);
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
		TryTeamPlacementDelayed();
		
		//redraw in like 0.5 seconds or so
		Delayed_DisplaySwapMenu(client);
		
	} else if (action == MenuAction_Cancel) {
		new reason = param2;
		new client = param1;
		
		DebugPrintToAll("MENUSWAP: Action %d Client %d's menu was cancelled.  Reason: %d", action, client, reason)
		
		//display swap menu till exit is pressed
		if(reason == MenuCancel_Timeout)
		{
			//Command_SwapMenu(client, 0);
		}
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}


Delayed_DisplaySwapMenu(client)
{
	CreateTimer(SCORE_SWAPMENU_PANEL_REFRESH, Timer_DisplaySwapMenu, client, _);
	
	DebugPrintToAll("Delayed display swap menu on %N", client);
}

public Action:Timer_DisplaySwapMenu(Handle:timer, any:client)
{
	Command_SwapMenu(client, 0);
}

/*
* 
* DEBUG TESTING FUNCTIONS
* 
*/


#if SCORE_DEBUG

public Action:Command_PrintPlacement(client, args)
{
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(teamPlacementArray[i])
		{
			DebugPrintToAll("Placement for %N to %d", i, teamPlacementArray[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_SwapNext(client, args)
{
	DebugPrintToAll("Will swap teams on map restart...");
	
	/*
	* We place everyone on whatever team they should be on
	* according to the set swapping type
	*/
	ClearTeamPlacement();
	
	if(args > 0)
	{
		DebugPrintToAll("Will simply override team swapping");
		swapTeamsOverride = true;
		return Plugin_Handled;
	}
	
	new String:authid[128];
	new i;
	
	new team;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
	{
		if(IsClientInGameHuman(i)) 
		{
			GetClientAuthString(i, authid, sizeof(authid));
			team = GetOppositeClientTeam(i);
			
			DebugPrintToAll("Next map will place %N to %d", i, team);
			SetTrieValue(teamPlacementTrie, authid, team);
		}
	}	
	
	swapTeamsOverride = true;
	
	DebugPrintToAll("Overriding built-in swap teams mechanism");
	
	return Plugin_Handled;
}

public Action:Command_ChangeTeam(client, args)
{
	new String:arg1[128];
	
	GetCmdArg(1, arg1, 128);
	
	new team = StringToInt(arg1);
	
	ChangePlayerTeamDelayed(client, team);
	
	return Plugin_Handled;
}

public Action:Command_GetTeamScore(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getscore <team> <0|1>");
		return Plugin_Handled;
	}
	
	if(fGetTeamScore == INVALID_HANDLE)
	{
		DebugPrintToAll("Could not load GetTeamScore function, GetConf = %b", bGetTeamScore);
		return Plugin_Handled;
	}
	
	new String:arg1[64], String:arg2[64];
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 64);
	
	new team = StringToInt(arg1);
	new b1 = StringToInt(arg2);
	
	new score = SDKCall(fGetTeamScore, team, b1);
	
	DebugPrintToAll("Team score is %d", score);
	
	return Plugin_Handled;
}


public Action:Command_SetCampaignScores(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setscore <team> <0|1>");
		return Plugin_Handled;
	}
	
	if(fGetTeamScore == INVALID_HANDLE)
	{
		DebugPrintToAll("Could not load GetTeamScore function, GetConf = %b", bGetTeamScore);
		return Plugin_Handled;
	}
	
	new String:arg1[64], String:arg2[64];
	GetCmdArg(1, arg1, 64);
	GetCmdArg(2, arg2, 64);
	
	new team = StringToInt(arg1);
	new score = StringToInt(arg2);
	
	SDKCall(fSetCampaignScores, team, score);
	
	DebugPrintToAll("Set game campaign score for team %d to %d", team, score);
	
	return Plugin_Handled;
}


public Action:Command_ClearTeamScores(client, args)
{	
	if(fClearTeamScores == INVALID_HANDLE)
	{
		DebugPrintToAll("Could not load ClearTeamScores function, GetConf = %b", bClearTeamScores);
		return Plugin_Handled;
	}
	
	new String:arg1[64];
	GetCmdArg(1, arg1, 64);
	
	SDKCall(fClearTeamScores);
	
	DebugPrintToAll("Team scores have been cleared");
	
	return Plugin_Handled;
}

#endif

DebugPrintToAll(const String:format[], any:...)
{
	#if SCORE_DEBUG	|| SCORE_DEBUG_LOG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if SCORE_DEBUG
	PrintToChatAll("%s", buffer);
	//PrintToConsole(0, "%s", buffer);
	#endif
	
	LogMessage("[SCORE] %s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
	return;
	#endif
}

GetRoundCounter(bool:increment_counter=false, bool:reset_counter=false)
{
	#define DEBUG_ROUND_COUNTER 0
	
	static counter = 0;
	if(reset_counter)
	{
		roundCounterReset = true;
		counter = 0;
		#if DEBUG_ROUND_COUNTER
		DebugPrintToAll("RoundCounter -- reset to 0");
		#endif
	}
	else if(increment_counter)
	{
		counter++;
		#if DEBUG_ROUND_COUNTER
		DebugPrintToAll("RoundCounter -- incremented to %d", counter);
		#endif
	}
	else
	{
		#if DEBUG_ROUND_COUNTER
		DebugPrintToAll("RoundCounter -- returned %d", counter);
		#endif
	}
	
	return counter;
}

/*
* VERSION CHECKING
* 
* Checks left4downtown_version cvar
*/

CheckDependencyVersions(bool:throw=false)
{
	#if !SCORE_DEBUG
	if(!IsLeft4DowntownVersionValid())
	{
		decl String:version[64];
		new Handle:versionCvar = FindConVar("left4downtown_version");
		if(versionCvar == INVALID_HANDLE)
		{
			strcopy(version, sizeof(version), "0.1.0");
		}
		else
		{
			GetConVarString(versionCvar, version, sizeof(version));
		}
		
		PrintToChatAll("[L4D SCORE] Your Left4Downtown Extension (%s) is out of date, please upgrade to %s or later", version, SCORE_VERSION_REQUIRED_LEFT4DOWNTOWN);
		if(throw)
			ThrowError("Your Left4Downtown Extension (%s) is out of date, please upgrade to %s or later", version, SCORE_VERSION_REQUIRED_LEFT4DOWNTOWN);
		return;
	}
	#else
	//suppress warnings
	if(throw && !throw)
	{
		IsLeft4DowntownVersionValid();
	}
	#endif
}

bool:IsLeft4DowntownVersionValid()
{
	new Handle:versionCvar = FindConVar("left4downtown_version");
	if(versionCvar == INVALID_HANDLE)
	{
		DebugPrintToAll("Could not find left4downtown_version, maybe using 0.1.0");
		return false;
	}
	
	decl String:version[64];
	GetConVarString(versionCvar, version, sizeof(version));
	
	new minVersion = ParseVersionNumber(SCORE_VERSION_REQUIRED_LEFT4DOWNTOWN);
	new versionNumber = ParseVersionNumber(version);
	
	DebugPrintToAll("Left4Downtown min version=%x, current=%s (%x)", minVersion, version, versionNumber);
	
	return versionNumber >= minVersion;
}

/* parse a version string such as "1.2.3.4", up to 4 subversions allowed */
ParseVersionNumber(const String:versionText[])
{
	new String:versionNumbers[4][4];
	ExplodeString(versionText, /*split*/".", versionNumbers, 4, 4);
	/*
	*/
	
	new version = 0;
	new shift = 24;
	for(new i = 0; i < 4; i++)
	{
		version = version | (StringToInt(versionNumbers[i]) << shift);
		
		shift -= 8;
	}
	
	//DebugPrintToAll("Parsed version '%s' as %x", versionText, version);
	return version;
}

stock bool:IsFinaleMapNextUp()
{
	decl String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (StrContains(mapname, "c1m3_mall", false) != -1
	|| StrContains(mapname, "c2m4_barns", false) != -1
	|| StrContains(mapname, "c3m3_shantytown", false) != -1
	|| StrContains(mapname, "c4m4_milltown_b", false) != -1
	|| StrContains(mapname, "c5m4_quarter", false) != -1
	|| StrContains(mapname, "c6m2_bedlam", false) != -1
	|| StrContains(mapname, "c7m2_barge", false) != -1
	|| StrContains(mapname, "1_alleys", false) != -1
	|| StrContains(mapname, "4_interior", false) != -1
	|| StrContains(mapname, "4_mainstreet", false) != -1
	|| StrContains(mapname, "4_terminal", false) != -1
	|| StrContains(mapname, "4_barn", false) != -1
	|| StrContains(mapname, "3_memorialbridge", false) != -1)
	return true;
	
	else return false;
}

stock bool:IsFinaleMapNow()
{
	return L4D_IsMissionFinalMap();
	
	/*
	decl String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (StrContains(mapname, "c1m4_atrium", false) != -1
	|| StrContains(mapname, "c2m5_concert", false) != -1
	|| StrContains(mapname, "c3m4_plantation", false) != -1
	|| StrContains(mapname, "c4m5_milltown_escape", false) != -1
	|| StrContains(mapname, "c5m5_bridge", false) != -1
	|| StrContains(mapname, "c6m3_port", false) != -1
	|| StrContains(mapname, "c7m3_port", false) != -1
	|| StrContains(mapname, "5_rooftop", false) != -1
	|| StrContains(mapname, "2_lots", false) != -1
	|| StrContains(mapname, "5_cornfield", false) != -1
	|| StrContains(mapname, "5_houseboat", false) != -1
	|| StrContains(mapname, "5_runway", false) != -
	|| StrContains(mapname, "4_cutthroatcreek", false) != -1)
	return true;
	
	else return false;
	*/
}

public Event_PlayerFirstSpawn(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{    
	if (SpawnTimer != INVALID_HANDLE) return;
	SpawnTimer = CreateTimer(30.0, SpawnTick, _, TIMER_REPEAT);
}

public Action:SpawnTick(Handle:hTimer, any:Junk)
{    
	new NumSurvivors;
	new MaxSurvivors = GetConVarInt(SurvivorLimit);
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (!IsClientInGame(i))    continue;
		if (GetClientTeam(i) != 2) continue;
		
		NumSurvivors++;
	}
	
	// It's impossible to have less than 4 survivors. Set the lower
	// limit to 4 in order to prevent errors with the respawns. Try
	// again later.
	if (NumSurvivors < 4) return Plugin_Continue;
	
	// Create missing bots
	for (;NumSurvivors < MaxSurvivors; NumSurvivors++)
		SpawnFakeClient();
	
	// Once the missing bots are made, dispose of the timer
	SpawnTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

SpawnFakeClient()
{
	// Spawn bot survivor.
	new Bot = CreateFakeClient("SurvivorBot");
	if (!Bot) return;
	
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(2.5, KickFakeClient, Bot);
}

public Action:KickFakeClient(Handle:hTimer, any:Client)
{
	if (IsClientInGame(Client)
	&& IsFakeClient(Client))
		KickClient(Client, "Free slot.");
	
	return Plugin_Handled;
}

new bool:MissionChangerVote;

public Action:Callvote_Handler(client, args)
{
	decl String:voteName[32];
	GetCmdArg(1,voteName,sizeof(voteName));
	
	if ((StrEqual(voteName,"ReturnToLobby", false) || StrEqual(voteName,"ChangeMission", false)))
	{
		DebugPrintToAll("Mission Changing Vote by %N caught", client);
		MissionChangerVote = true;
	}
}

public EventVoteEndSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!MissionChangerVote) return;
	
	decl String:details[256], String:param1[256];
	GetEventString(event, "details", details, sizeof(details));
	GetEventString(event, "param1", param1, sizeof(param1));
	
	DebugPrintToAll("Mission Changing Vote End caught, details: %s ; param1: %s ", details, param1);
	MissionChangerVote = false;
	
	if (strcmp(details, "#L4D_vote_passed_mission_change", false) == 0)
	{
		DebugPrintToAll("New Campaign Vote Success caught, executing OnNewMission()");
		OnNewMission();
	}
	
	if (strcmp(details, "#L4D_vote_passed_return_to_lobby", false) == 0)
	{
		DebugPrintToAll("Return To Lobby Vote Success caught, executing OnNewMission()");
		OnNewMission();
	}
}

public EventVoteEndFail(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (MissionChangerVote) MissionChangerVote = false;
}
/**/