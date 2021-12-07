#include <sourcemod>
#include <sdktools>
#include "left4downtown.inc"

#define SCORE_VERSION "1.1.1"

#define SCORE_DEBUG 0
#define SCORE_DEBUG_LOG 0

#define SCORE_TEAM_A 1
#define SCORE_TEAM_B 2
#define SCORE_TYPE_ROUND 0
#define SCORE_TYPE_CAMPAIGN 1

#define SCORE_DELAY_PLACEMENT 0.1
#define SCORE_DELAY_TEAM_SWITCH 0.1
#define SCORE_DELAY_SWITCH_MAP 1.0
#define SCORE_DELAY_EMPTY_SERVER 5.0
#define SCORE_DELAY_SCORE_SWAPPED 0.1

#define SCORE_LIST_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_REFRESH 0.5

#define SCORE_VERSION_REQUIRED_LEFT4DOWNTOWN "0.3.1"

#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define L4D_TEAM_SURVIVORS 2
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SPECTATE 1
#define L4D_TEAM_MAX_CLIENTS 4

#define L4D_TEAM_NAME(%1) (%1 == 2 ? "Survivors" : (%1 == 3 ? "Infected" : (%1 == 1 ? "Spectators" : "Unknown")))

/*
TODO:
0. Check if campaign score reset detection works well. MANUAL? :(

2. Fix people being stuck in spectator when swap fails
  - add overrides for jointeam 2/3 command?
  - sm_swap on spectator put person on the smallest non-full team?
  (DONE: needs testing)
 
3. Detect a restarted round  (finalize old scores//don't overwrite old scores with new?)
   - treat first vs second round separately
   - first round is over when scores is not (X,-1).. if it is when round_start then round was restarted?
    - only write first round once when its finalized, dont overwrite
   - doesnt matter when 2nd round is over, just keep overwriting second round score
   
4. Add sm_swapto <names> <1/2/3> command 
  (DONE: needs testing)
*/

/*
* For testing?
*/
#define SCORE_CAMPAIGN_OVERRIDE 1
#define SCORE_TEAM_PLACEMENT_OVERRIDE 0

/*
* TODO:
* - with RUP and after a !reready the first team's scores 
*   get overriden with default 200*multiplier scores
*/
forward OnReadyRoundRestarted();

public Plugin:myinfo = 
{
	name = "L4D Score/Team Manager",
	author = "Downtown1",
	description = "Manage teams and scores in L4D",
	version = SCORE_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=87759"
}

new Handle:gConf = INVALID_HANDLE;
new Handle:fGetTeamScore = INVALID_HANDLE;
new Handle:fClearTeamScores = INVALID_HANDLE;
new Handle:fSetCampaignScores = INVALID_HANDLE;

new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

new Handle:cvarTeamSwapping = INVALID_HANDLE;

new bool:bGetTeamScore;
new bool:bClearTeamScores;

new campaignScores[3]; //store the total campaign score, ignore index 0
new roundScores[3];    //store the round score, ignore index 0
new Handle:mapScores = INVALID_HANDLE;

new mapCounter;
new bool:skippingLevel;
new bool:swapScoreBeginningLevel;

new bool:roundCounterReset = false;

new bool:clearedScores = false;
new bool:roundRestarting = false;

new bool:campaignScoresSwapped;

/* Current Mission */
new bool:pendingNewMission;
new String:nextMap[128];

/* Team Placement */
new Handle:teamPlacementTrie = INVALID_HANDLE; //remember what teams to place after map change
new teamPlacementArray[256];  //after client connects, try to place him to this team
new teamPlacementAttempts[256]; //how many times we attempt and fail to place a person

enum TeamSwappingType
{
	HighestScoreSurvivorFirst, /* same as 1.0.1.0+, default */
	HighestScoreInfectedFirst, /* reverse of the above */
	SwapNever,                 /* classic, never swap teams */
	SwapEveryMap,              /* swap teams every map */
	SwapOnThirdMap,	           /* swap teams on 3, CAL style */
	HighestScoreSurvivorFirstButFin /* valve swap, on finale highest score goes infected first */
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
	RegConsoleCmd("sm_scores", Command_Scores, "sm_scores - bring up a list of round/campaign scores");
	
	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_BAN, "sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", Command_SwapTo, ADMFLAG_BAN, "sm_swapto <player1> [player2] ... [playerN] <teamnum> - swap all listed players to <teamnum> (1,2, or 3)");
	RegAdminCmd("sm_swapteams", Command_SwapTeams, ADMFLAG_BAN, "sm_swapteams2 - swap the players between both teams");
	RegAdminCmd("sm_swapscores", Command_SwapScores, ADMFLAG_BAN, "sm_swapscores - swap the score between the first and second team");
	RegAdminCmd("sm_resetscores", Command_ResetScores, ADMFLAG_BAN, "sm_resetscores - reset the currently tracked campaign/map scores");
	
	RegAdminCmd("sm_swapmenu", Command_SwapMenu, ADMFLAG_BAN, "sm_swapmenu - bring up a swap players menu");
	
	/*
	* Cvars
	*/
	CreateConVar("l4d_team_manager_ver", SCORE_VERSION, "Version of the score/team manager plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvarTeamSwapping = CreateConVar("l4d_team_order", "0", 
			"0 - highest score goes survivor first, 1 - highest score goes infected first, 2 - never swap teams, 3 - swap teams every map, 4 - swap teams on the 3rd map, 5 - same as 0 except on finale highest score goes infected first", 
			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	
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
}


public OnAllPluginsLoaded()
{	
	CheckDependencyVersions(/*throw*/true);
}


PrepareAllSDKCalls()
{
	gConf = LoadGameConfigFile("left4downtown");
	if(gConf == INVALID_HANDLE)
	{
		LogError("Could not load gamedata/left4downtown.txt");
		DebugPrintToAll("Could not load gamedata/left4downtown.txt");
	}
	
	// GetTeamScores
	StartPrepSDKCall(SDKCall_GameRules);
	bGetTeamScore = PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "GetTeamScore");
	if(bGetTeamScore)
	{
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		fGetTeamScore = EndPrepSDKCall();
		
		if(fGetTeamScore == INVALID_HANDLE) {
			DebugPrintToAll("[TEST] Function 'GetTeamScore' found, but something went wrong.");
		} else {
			DebugPrintToAll("[TEST] Function 'GetTeamScore' initialized.");
		}
	}
	else {
		DebugPrintToAll("[TEST] Function 'GetTeamScore' not found.");
	}

	// ClearTeamScores
	StartPrepSDKCall(SDKCall_GameRules);
	bClearTeamScores = PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "ClearTeamScores");
	if(bClearTeamScores)
	{
		fClearTeamScores = EndPrepSDKCall();
	
		if(fClearTeamScores == INVALID_HANDLE) {
			DebugPrintToAll("[TEST] Function 'ClearTeamScores' found, but something went wrong.");
		} else {
			DebugPrintToAll("[TEST] Function 'ClearTeamScores' initialized.");
		}
	}
	else
	{
		DebugPrintToAll("[TEST] Function 'ClearTeamScores' not found.");
	}
	
	// SetCampaignScores
	StartPrepSDKCall(SDKCall_GameRules);
	if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetCampaignScores")) {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		fSetCampaignScores = EndPrepSDKCall();
		if(fSetCampaignScores == INVALID_HANDLE) {
			DebugPrintToAll("[TEST] Function 'SetCampaignScores' found, but something went wrong.");
		} else {
			DebugPrintToAll("[TEST] Function 'SetCampaignScores' initialized.");
		}
	} else {
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
}

public OnPluginEnd()
{
	CloseHandle(teamPlacementTrie);
	CloseHandle(mapScores);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* sometimes round_start is invoked before OnMapStart */
	if(!roundCounterReset)
	{
		GetRoundCounter(/*increment*/false, /*reset*/true);
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
		roundCounter = GetRoundCounter(/*increment*/true);
	}
	
	DebugPrintToAll("Round %d started, scores: A: %d, B: %d", roundCounter, GetTeamRoundScore(SCORE_TEAM_A), GetTeamRoundScore(SCORE_TEAM_B));	
	
	DetectScoresSwappedDelayed();
}
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new roundCounter = GetRoundCounter();
	DebugPrintToAll("Round %d end, scores: A: %d, B: %d", roundCounter, GetTeamRoundScore(SCORE_TEAM_A), GetTeamRoundScore(SCORE_TEAM_B));	

	if(roundRestarting)
		return;
	
	//roundCounter++;
	
	//first round or pre-game dont do anything, no point...
	//if(IsFirstRound())
	//	return;
	
	/*
	* Update Round + Campaign Scores
	*/
	
	new logical_team = CurrentToLogicalTeam(L4D_TEAM_SURVIVORS);
	new score = GetTeamRoundScore(logical_team);
	new oldScore = roundScores[logical_team];
	
	//round_end gets called twice, so its ok if its set already
	if(oldScore != -1)
	{
		DebugPrintToAll("Tried to set team score at the end of round %d to %d, but it was already set", roundCounter, score);
	}
	else
	{
		DebugPrintToAll("Updated team campaign/round scores");
		campaignScores[logical_team] += score;
		roundScores[logical_team] = score;
	}
	
	/*
	* when we get 'newer' team scores
	* then update our campaign scores with the newer scores
	*/
	/*
	new scoreA = GetTeamRoundScore(SCORE_TEAM_A);
	new scoreB = GetTeamRoundScore(SCORE_TEAM_B);
	
	new oldScoreA = roundScores[SCORE_TEAM_A];
	new oldScoreB = roundScores[SCORE_TEAM_B];
	* 
	if(scoreA != -1)
	{
		if(oldScoreA != -1)
		{
			campaignScores[SCORE_TEAM_A] -= oldScoreA;
		}
		campaignScores[SCORE_TEAM_A] += scoreA;
		roundScores[SCORE_TEAM_A] = scoreA;
	}
	
	if(scoreB != -1)
	{
		if(oldScoreB != -1)
		{
			campaignScores[SCORE_TEAM_B] -= oldScoreB;
		}
		campaignScores[SCORE_TEAM_B] += scoreB;
		roundScores[SCORE_TEAM_B] = scoreB;
	}*/
	

	
	//figure out what to put the next map teams with
	//before all the clients are actually disconnected
	
	if(!IsFirstRound())
	{
#if !SCORE_DEBUG || SCORE_CAMPAIGN_OVERRIDE
		SDKCall(fSetCampaignScores, campaignScores[SCORE_TEAM_A], campaignScores[SCORE_TEAM_B]);
		
		DebugPrintToAll("Updated campaign scores, A:%d, B:%d", campaignScores[SCORE_TEAM_A], campaignScores[SCORE_TEAM_B]);
#endif
		
#if SCORE_DEBUG
		if(!swapTeamsOverride && !SCORE_TEAM_PLACEMENT_OVERRIDE)
#endif
		CalculateNextMapTeamPlacement();
#if SCORE_DEBUG
		else
		{
			DebugPrintToAll("Skipping next map team placement, as its overridden");
		}
#endif
	}
}

public Action:Command_ResetScores(client, args)
{
	ResetCampaignScores();
	ResetRoundScores();
	
	PrintToChatAll("[SM] The scores have been reset.");	
	return Plugin_Handled;
}

public Action:Command_SwapTeams(client, args)
{
	PrintToChatAll("[SM] Survivor and Infected teams have been swapped.");
	
	new i;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			teamPlacementArray[i] = GetOppositeClientTeam(i);
		}
	}
	
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
	
	new player_id;

	new String:player[64];
	
	for(new i = 0; i < args; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		player_id = FindTarget(client, player, true /*nobots*/, false /*immunity*/);
		
		if(player_id == -1)
			continue;
		
		new team = GetOppositeClientTeam(player_id);
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
	
	new team;
	new String:teamStr[64];
	GetCmdArg(args, teamStr, sizeof(teamStr))
	team = StringToInt(teamStr);
	if(!team)
	{
		ReplyToCommand(client, "[SM] Invalid team %s specified, needs to be 1, 2, or 3", teamStr);
		return Plugin_Handled;
	}
	
	new player_id;

	new String:player[64];
	
	for(new i = 0; i < args - 1; i++)
	{
		GetCmdArg(i+1, player, sizeof(player));
		player_id = FindTarget(client, player, true /*nobots*/, false /*immunity*/);
		
		if(player_id == -1)
			continue;
		
		teamPlacementArray[player_id] = team;
		PrintToChatAll("[SM] %N has been swapped to the %s team.", player_id, L4D_TEAM_NAME(team));
	}
	
	TryTeamPlacement();
	
	return Plugin_Handled;
}

public Action:Command_SwapScores(client, args)
{
	SwapScores();
	
	PrintToChatAll("[SM] The scores have been swapped.");
	return Plugin_Handled;
}

public Action:Command_NextMap(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] The next map in the mission is %s", nextMap);
		
		return Plugin_Handled;
	}
	
	new String:arg1[128];
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
	
	//game treats the scores as unswapped once again
	if(!DetectScoresSwapped())
		campaignScoresSwapped = false;
	
	pendingNewMission = false;
}

public Action:L4D_OnSetCampaignScores(&scoreA, &scoreB)
{
	DebugPrintToAll("FORWARD: OnSetCampaignScores(%d,%d)", scoreA, scoreB);
	
	return Plugin_Continue;
}

public Action:L4D_OnClearTeamScores()
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
		
		DebugPrintToAll("OnClearTeamScores()"); 
		
		CreateTimer(0.1, Timer_GetCampaignScores, _);
		
		ResetRoundScores();
	}
	
	return Plugin_Continue;
}


public Action:Timer_GetCampaignScores(Handle:timer)
{
	new scoreA, scoreB;
	
	L4D_GetCampaignScores(scoreA, scoreB);
	DebugPrintToAll("Campaign scores are A=%d, B=%d", scoreA, scoreB);
	
	//a mutual score of 0 can only mean one thing.. the campaign scores got reset
	if(scoreA == 0 && scoreB == 0)
	{
		OnNewMission();
	}
}

public OnReadyRoundRestarted()
{
	DebugPrintToAll("FORWARD: OnReadyRoundRestarted triggered");
	roundRestarting = true;
}

public OnMapStart()
{		
	DebugPrintToAll("ON MAP START");
	
	if(!roundCounterReset)
		GetRoundCounter(/*increment*/false, /*reset*/true);
	
	#if SCORE_DEBUG
	swapTeamsOverride = false;
	#endif
	
	new String:mapname[64];
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
	}
	else
	{
		mapCounter++;
	}
	
	skippingLevel = false;
	nextMap[0] = 0;
	
	ResetRoundScores();
	
	if(swapScoreBeginningLevel)
	{
		SwapScores();
	}
}

public Action:Timer_SwitchToNextMap(Handle:timer)
{
	ServerCommand("changelevel %s", nextMap);
}


public OnMapEnd()
{
	roundCounterReset = false;
	
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
	if(GetTeamCampaignScore(L4D_TEAM_SURVIVORS) > GetTeamCampaignScore(L4D_TEAM_INFECTED))
	{
		pendingSwapScores = true;
	}
	
	/*
	* Try to figure out if we should swap scores 
	* at the beginning of the next map
	*/
	new TeamSwappingType:swapKind = TeamSwappingType:GetConVarInt(cvarTeamSwapping);
	switch(swapKind)
	{
		case SwapEveryMap:
		{
			swapScoreBeginningLevel = true;
		}
		case SwapOnThirdMap:
		{
			swapScoreBeginningLevel = mapCounter == 3;
		}
		case HighestScoreSurvivorFirst:
		{
			swapScoreBeginningLevel = pendingSwapScores;
		}
		case HighestScoreInfectedFirst:
		{
			swapScoreBeginningLevel = !pendingSwapScores;
		}
		case HighestScoreSurvivorFirstButFin:
		{
			//last level: highest score goes infected first
			//all previous levels: highest score goes survivor first
			swapScoreBeginningLevel = (mapCounter == 5) ? !pendingSwapScores : pendingSwapScores;
		}
		default:
		{
			swapScoreBeginningLevel = false;
		}
	}

	/*
	* Lastly we make it look internally like we're in classic mode
	* => This makes it so Team A is always Survivors first
	* 		and Team B is always infected first
	*/
	
	if(pendingSwapScores)
	{
		SwapScores();
	}

	campaignScoresSwapped = pendingSwapScores;
	
	//schedule a pending skip level to the next map
	if(strlen(nextMap) > 0 && IsMapValid(nextMap))
	{
		skippingLevel = true;
	}
}

CalculateNextMapTeamPlacement()
{
	/*
	* Is the game about to automatically swap teams on us?
	*/
	new bool:pendingSwapScores = false;
	if(GetTeamCampaignScore(L4D_TEAM_SURVIVORS) > GetTeamCampaignScore(L4D_TEAM_INFECTED))
	{
		pendingSwapScores = true;
	}

	/*
	* We place everyone on whatever team they should be on
	* according to the set swapping type
	*/
	ClearTeamPlacement();
	
	new String:authid[128];
	new i;
	
	new team;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
	{
		if(IsClientInGameHuman(i)) 
		{
			GetClientAuthString(i, authid, sizeof(authid));
			team = GetClientTeamForNextMap(i, pendingSwapScores);
			
			DebugPrintToAll("Next map will place %N to %d", i, team);
			SetTrieValue(teamPlacementTrie, authid, team);
		}
	}	
}

/* 
* **************
* TEAM PLACEMENT (beginning of map)
* **************
*/

public OnClientAuthorized(client, const String:authid[])
{
	//DebugPrintToAll("Client %s authorized", authid);
	
	if(skippingLevel)
		return;
	
	new team;
	
	if(GetTrieValue(teamPlacementTrie, authid, team))
	{
		teamPlacementArray[client] = team;
		RemoveFromTrie(teamPlacementTrie, authid);
		
		DebugPrintToAll("Will place %d/%s to team %d", client, authid, team);
		
		TryTeamPlacementDelayed();
	}
}

public OnClientDisconnect(client)
{
	//DebugPrintToAll("Client %d disconnected", client);

	if(skippingLevel)
		return;
	
	TryTeamPlacementDelayed();
	
	/*
	* See if the server is now empty?
	*/
	//DetectEmptyServerDelayed();
}

public OnClientConnected(client)
{
	/*
	 * Clearly the server is not so empty anymore
	 * So cancel the detection
	 */
	//DetectEmptyServerCancel();	
}

/*
* Detect empty server
* 
* In this case we "reset" the score tracking
*/
/*
new Handle:hDetectEmptyServer = INVALID_HANDLE;
DetectEmptyServerDelayed()
{
	if(hDetectEmptyServer == INVALID_HANDLE)
	{
		hDetectEmptyServer = CreateTimer(SCORE_DELAY_EMPTY_SERVER, Timer_DetectEmptyServer, _, _);
	}
}

DetectEmptyServerCancel()
{
	if(hDetectEmptyServer != INVALID_HANDLE)
	{
		KillTimer(hDetectEmptyServer);
		hDetectEmptyServer = INVALID_HANDLE;
	}
}

public Action:Timer_DetectEmptyServer(Handle:timer)
{
	DetectEmptyServer();	
	hDetectEmptyServer = INVALID_HANDLE;
}

DetectEmptyServer()
{	
	if(GetClientCount(false) == 0)
	{
		//reset the score tracking when the map restarts
		pendingNewMission = true;
		
		DebugPrintToAll("EMPTY server detected!");
		
		//treat it like the map restarted
		OnMapStart();
	}
}
*/
/*
* End of empty server detection functions
*/

/*
* Try to detect if the campaign scores have been swapped
* by the game itself.
*/
DetectScoresSwappedDelayed()
{
	CreateTimer(SCORE_DELAY_SCORE_SWAPPED, Timer_DetectScoresSwapped);
}

public Action:Timer_DetectScoresSwapped(Handle:timer)
{
	DetectScoresSwapped();
}
/*
* Try to detect if the campaign scores have been swapped
* by the game itself.
*/
bool:DetectScoresSwapped()
{
	if(IsFirstRound())
	{
		new scoreA = GetTeamRoundScore(SCORE_TEAM_A);
		new scoreB = GetTeamRoundScore(SCORE_TEAM_B);
		
		if(scoreA == -1 || scoreB == -1)
		{
			campaignScoresSwapped = (scoreA == -1);
			
			DebugPrintToAll("DetectCampaignScoresSwapped : success, swap = %d", campaignScoresSwapped);
			return true;
		}		
	}
	
	DebugPrintToAll("DetectCampaignScoresSwapped : failure, not could detect");
	return false;
}

/*
* End of Campaign Scores Swapped? Detection
*/


public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*new userid = GetEventInt(event, "userid");
	new team = GetEventInt(event, "team");
	
	new client = GetClientOfUserId(userid);
	
	if(!client)
		DebugPrintToAll("------Player #%d changed team to %d.", userid, team);
	else
		DebugPrintToAll("------ %N (%d) changed team to %d", client, client, team);
	*/

	TryTeamPlacementDelayed();
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
	new i;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
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
	new i;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
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
GetClientTeamForNextMap(client, bool:pendingSwapScores = false)
{
	new bool:isThirdMap = mapCounter == 3;
	
	new TeamSwappingType:swapKind = TeamSwappingType:GetConVarInt(cvarTeamSwapping);
	new team;
	
	//same type of logic except on the finale, in which we flip it
	if(swapKind == HighestScoreSurvivorFirstButFin)
	{
		swapKind = HighestScoreInfectedFirst;
		
		if(mapCounter == 5)
		{
			pendingSwapScores = !pendingSwapScores;
		}
	}
	
	switch(GetClientTeam(client))
	{
		case L4D_TEAM_INFECTED:
		{
			//default, dont swap teams
			team = L4D_TEAM_SURVIVORS;
			
			switch(swapKind)
			{
				/*case SwapNever:
				{
					break;
				}*/
				case SwapEveryMap:
				{
					team = L4D_TEAM_INFECTED;
				}
				case SwapOnThirdMap:
				{
					team = isThirdMap ? L4D_TEAM_INFECTED : L4D_TEAM_SURVIVORS;
				}
				case HighestScoreSurvivorFirst:
				{
					team = pendingSwapScores ? L4D_TEAM_INFECTED : L4D_TEAM_SURVIVORS;
				}
				case HighestScoreInfectedFirst:
				{
					team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
			}
		}
		
		case L4D_TEAM_SURVIVORS:
		{
			//default, dont swap teams
			team = L4D_TEAM_INFECTED;
			
			switch(swapKind)
			{
				case SwapNever:
				{
				}
				case SwapEveryMap:
				{
					team = L4D_TEAM_SURVIVORS;
				}
				case SwapOnThirdMap:
				{
					team = isThirdMap ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
				case HighestScoreSurvivorFirst:
				{
					team = pendingSwapScores ? L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
				}
				case HighestScoreInfectedFirst:
				{
					team = pendingSwapScores ? L4D_TEAM_INFECTED : L4D_TEAM_SURVIVORS;
				}
			}
		}
		
		default:
		{
			team = L4D_TEAM_SPECTATE;
		}
	}
	
	return team;
}

SwapScores()
{
	new tmp;
	
	tmp = campaignScores[SCORE_TEAM_A];
	campaignScores[SCORE_TEAM_A] = campaignScores[SCORE_TEAM_B];
	campaignScores[SCORE_TEAM_B] = tmp;
	
	tmp = roundScores[SCORE_TEAM_A];
	roundScores[SCORE_TEAM_A] = roundScores[SCORE_TEAM_B];
	roundScores[SCORE_TEAM_B] = tmp;
	
	new i, size = GetArraySize(mapScores);
	for(i = 0; i < size; i++)
	{
		new scores[2];
		GetArrayArray(mapScores, i, scores);
		
		tmp = scores[0];
		scores[0] = scores[1];
		scores[1] = tmp;
		
		SetArrayArray(mapScores, i, scores);
	}
	
	DebugPrintToAll("Swapped campaign scores, now A:%d, B:%d", campaignScores[SCORE_TEAM_A], campaignScores[SCORE_TEAM_B]);
}

ResetCampaignScores()
{
	campaignScores[SCORE_TEAM_A] = 0;
	campaignScores[SCORE_TEAM_B] = 0;

	mapCounter = 1;
	ClearArray(mapScores);
	
	DebugPrintToAll("Campaign scores have been reset.");
}

ResetRoundScores()
{
	roundScores[SCORE_TEAM_A] = -1;
	roundScores[SCORE_TEAM_B] = -1;
}

GetTeamCampaignScore(team)
{
	return campaignScores[CurrentToLogicalTeam(team)];
}

//convert SCORE_TEAM_* 
//to team infected or team survivors
stock LogicalToCurrentTeam(logical_team)
{
	if(logical_team != SCORE_TEAM_A && logical_team != SCORE_TEAM_B)
	{
		return 0;
	}
	
	new team;
	
	//first round survivors are "always" team A
	if(IsFirstRound())
	{
		team = logical_team == SCORE_TEAM_A ? 
			L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
	}
	//second round infected are always "team" A
	else
	{
		team = logical_team == SCORE_TEAM_B ? 
			L4D_TEAM_SURVIVORS : L4D_TEAM_INFECTED;
	}
	
	return campaignScoresSwapped ? OppositeCurrentTeam(team) : team;

}

//convert 2 (sur), or 3 (inf)
//to SCORE_TEAM_* necessary to be able to read the scores
CurrentToLogicalTeam(team)
{
	if(team != L4D_TEAM_INFECTED && team != L4D_TEAM_SURVIVORS)
	{
		return 0;
	}
	
	new l;
	
	//first round survivors are "always" team A
	if(IsFirstRound())
	{
		l = team == L4D_TEAM_SURVIVORS ? 
			SCORE_TEAM_A : SCORE_TEAM_B;
	}
	//second round infected are always "team" A
	else
	{
		l = team == L4D_TEAM_INFECTED ? 
			SCORE_TEAM_A : SCORE_TEAM_B;
	}
	
	return campaignScoresSwapped ? OppositeLogicalTeam(l) : l;
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
		DebugPrintToAll("ChangePlayerTeam() : Cannot switch %N to team %d, as team is full");
		return false;
	}
	
	//for survivors its more tricky
	new bot;
	
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
	return IsClientInGame(client) && !IsFakeClient(client);
}

stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	new i;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
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
			DebugPrintToAll("Changelevel detected");
			
			//PrintToServer("If you are using changelevel via RCON, you should be using sm_changemap instead to change maps!");
		}		
	}
	return Plugin_Continue;
}

public Action:Command_PrintScores(client, args)
{
	DebugPrintToAll("Command_PrintScores, mapCounter = %d", mapCounter);
	
	new i, scores[2], curscore, scoresSize = GetArraySize(mapScores);
	PrintToChatAll("[SM] Printing map scores:");
	
	PrintToChatAll("Survivors: ");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[CurrentToLogicalTeam(L4D_TEAM_SURVIVORS)-1];
		
		PrintToChatAll("%d. %d", i+1, curscore);
	}
	PrintToChatAll("- Campaign: %d", GetTeamCampaignScore(L4D_TEAM_SURVIVORS));
	
	PrintToChatAll("Infected: ");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[CurrentToLogicalTeam(L4D_TEAM_INFECTED)-1];
		
		PrintToChatAll("%d. %d", i+1, curscore);
	}
	PrintToChatAll("- Campaign: %d", GetTeamCampaignScore(L4D_TEAM_INFECTED));
	
	
	DebugPrintToAll("Campaign scores - A:%d, B:%d", campaignScores[SCORE_TEAM_A], campaignScores[SCORE_TEAM_B]);

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
	//SetPanelTitle(panel, "Team Scores");
	
	Format(panelLine, sizeof(panelLine), "SURVIVORS (%d)", GetTeamCampaignScore(L4D_TEAM_SURVIVORS));
	DrawPanelText(panel, panelLine);
	//DrawPanelText(panel, "SURVIVORS");
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[CurrentToLogicalTeam(L4D_TEAM_SURVIVORS)-1];
		
		Format(panelLine, sizeof(panelLine), "->%d. %d", i+1, curscore);
		DrawPanelText(panel, panelLine);
	}
	/*Format(panelLine, sizeof(panelLine), "-- Campaign: %d", GetTeamCampaignScore(L4D_TEAM_SURVIVORS));
	DrawPanelText(panel, panelLine);*/
	
	DrawPanelText(panel, " ");
	//DrawPanelText(panel, "INFECTED");
	Format(panelLine, sizeof(panelLine), "INFECTED (%d)", GetTeamCampaignScore(L4D_TEAM_INFECTED));
	DrawPanelText(panel, panelLine);
	for(i = 0; i < scoresSize; i++)
	{
		GetArrayArray(mapScores, i, scores);
		
		curscore = scores[CurrentToLogicalTeam(L4D_TEAM_INFECTED)-1];
		
		Format(panelLine, sizeof(panelLine), "->%d. %d", i+1, curscore);
		DrawPanelText(panel, panelLine);
	}
	/*Format(panelLine, sizeof(panelLine), "-- Campaign: %d", GetTeamCampaignScore(L4D_TEAM_INFECTED));
	DrawPanelText(panel, panelLine);*/
	
	DebugPrintToAll("Campaign scores - A:%d, B:%d", campaignScores[SCORE_TEAM_A], campaignScores[SCORE_TEAM_B]);

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
	
	/*
	for(new j = 0; j < sizeof(teamIdx); j++)
	{
		new team = teamIdx[j];
		DebugPrintToAll("Iterating team %d", team);
		
		if(GetTeamHumanCount(team) > 0)
		{
			DrawPanelText(panel, teamNames[j]);
			for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
			{
				if(IsClientInGameHuman(i) && GetClientTeam(i) == team) 
				{					
					numPlayers++;
					//Format(panelLine, 1024, "->%d. %N", numPlayers, i);
					Format(panelLine, 1024, "%N", i);
					//DrawPanelText(panel, panelLine);
					DrawPanelItem(panel, panelLine);
					
					#if SCORE_DEBUG
					//DrawPanelItem(panel, panelLine);
					#endif
					
					swapClients[numPlayers] = i;
				}
			}
		}
	}
	
	SendPanelToClient(panel, client, Menu_SwapPanel, SCORE_LIST_PANEL_LIFETIME);	
	
	CloseHandle(panel);*/
	
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
	
	/*
	* b1 = 0 then get the round score
	* b1 = 1 then get the campaign score
	* 
	* 
	* 2 0 returns -1 when score is not set for round?
	* 
	* 
	* your team 52 , enemy team 2
	* 
	* sm_getscore 3 1 seems to return survivor completition percentage <:D>
	* sm_getscore 4 1 seems to read the health bonus
	* 
	* sm_getscore 5 0 - completition %?
	* sm_getscore 6 0 - health bonus?
	* 
	* --------------------------------
	* 
	* sm_getscore 1 0 gets the map score (end of round was 1540)
	* sm_getscore 1 1 gets the campaign score 
	* 	(might might be valid only after end of 2nd round?)
	* 
	* sm_getscore 0 1 gets the score for the map ithink
	* sm_getscore 0 0 probably campaign too, crazy values when not end of map
	* 
	* score of -1 mean the team hasnt played yet
	* 
	* -------
	* TEAM ORDER? 0 or 1 for the team # but is it constant or not across map changes
	* 
	* FIRST MAP (team A = survivors first, B = survivors second)
	* sm_getscore 1 0 gets you the map score for team A
	*   - you can keep doing this after the round is over during that map 
	* 
	* SECOND MAP (teams swapped due to team B having higher score)
	* 
	* sm_getscore 0 1 gets you the map score for team B
	* 
	* ****************************************w
	* 
	* 
	* FIRST MAP
	* (first round)
	* sm_getscore 1 0 - team A 199
	* sm_getscore 1 1 - 0
	* sm_getscore 2 0 - team B -1
	* sm_getscore 2 1 - 0
	* (second round)
	* sm_getscore 1 0 - team A 9
	* sm_getscore 1 1 - 0
	* sm_getscore 2 0 - team B - 1100
	* sm_getscore 2 1 - 0
	* (end of map)
	* sm_getscore 1 1 - 9
	* sm_getscore 2 1 - 1100
	* 
	* SECOND MAP (AB swapped due to scoreB > scoreA)
	* (first round)
	* - campaign scores are "0"
	* sm_getscore 1 0 - team A -1
	* sm_getscore 2 0 - team B 16
	* 
	* (second round)
	* - same as first round except
	* sm_getscore 1 0 - team A 0
	* 
	* (end of map)
	* - campaign scores are set to what they shuld be
	* 
	* THIRD MAP (B first, A second)
	* sm_getscore 1 0 - team A -1
	* sm_getscore 2 0 - team B 0 (in safe room)
	* 
	* VERDICT:
	* 
	* the "first" team is the one that starts survivor on 1st map
	* the "second" team is the one that starts infected on 1st map
	* 
	* if teams are swapped then it doesnt matter
	* 
	* AUTO SWAP DETECTION:
	* if 1 was -1 last map and now team 2 is -1 then teams were swapped
	* 
	* **********************************
	* 
	* FOURTH MAP: sm_setscore 1337 0
	* - Team A magically is winning the campaign now
	* - Team B is magically losing
	* 
	* Team A starts first (could SetCampaignScore update the real campaign score?)
	* Team B starts second
	* 
	* FIFTH MAP
	* campaign scores are back to 1118 (B) - 9 A 
	* so SetCampaignScore does NOT update real score
	* 
	* --- Maybe SetCampaignScore does determine who goes first however?
	* YES IT DOES
	* made team A win, team B lose, then setcampaignscores(0,1337)
	* 
	* Team B then went first with sm_getscore 2 0 returning the real score
	* Team A had sm_getscore 1 0 like it should have
	* ---
	* 
	* 
	* TEAMS TIED ? THEN TEAMS ARE NOT SWITCHED
	*/
	
	new score = SDKCall(fGetTeamScore, team, b1);
	
	DebugPrintToAll("Team score is %d", score);
	
	return Plugin_Handled;
}


public Action:Command_SetCampaignScores(client, args)
{
		/*
	* 
	* calling this it seems its very picky when we can call it
	* 
	* arguments are probably team: 0 or team :1 similar to getscore
	* 
	* but calling it at the wrong time maybe it recalculates it?
	* 
	* ---------
	* wtf its gotta be stored somewhere else
	* maybe there's an array of scores for each map?
	* 
	*/
	
	
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
	
	DebugPrintToAll("Set campaign score for team %d to %d", team, score);
	
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