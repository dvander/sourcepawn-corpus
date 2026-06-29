#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#pragma semicolon 1

#define VERSION "1.0.3"
#define SIDSIZE 32
#define TEAMSIZE 16
#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define DEBUG 1
#define DEBUGTEAMS 0
#define L4D_TEAM_SURVIVORS 2
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SPECTATE 1
#define SCORE_TEAM_A 1
#define SCORE_TEAM_B 2
#define SCORE_TYPE_ROUND 0
#define SCORE_TYPE_CAMPAIGN 1

public Plugin:myinfo =
{
	name = "[L4D2] Unscrambler",
	author = "modified by V10 (original by Fyren)",
	description = "Keeps teams unscrambled after map change in versus\team switch, team change",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=730278"
};

new Handle:cvarWait = INVALID_HANDLE;
new Handle:cvarHoldOn = INVALID_HANDLE;
new Handle:timerWait = INVALID_HANDLE;
new Handle:timerUnscramble = INVALID_HANDLE;
new String:teams[2][TEAMSIZE][SIDSIZE]; //two teams, four players, 16 chars for Steam ID
#if DEBUG
new String:logPath[256];
#endif
new nTeam[2]; //number of players stored in the list
//new storing; //if we're on a versus map and should be storing teams
new uCount; //number of teams unscramble has repped as a failsafe
new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;
new Handle:fGTS = INVALID_HANDLE;
new bool:RoundEndDone;
//new Scores[3];    
new Round=0;
new LastInfectedTeam;
new FirstSurvivorTeam;
new bool:isFirstMap=false;
new Handle:h_Switch_CheckTeams;
new bool:FirstSpawn=true;
// top menu
new Handle:hTopMenu = INVALID_HANDLE;

public OnPluginStart()
{
	#if DEBUG
	BuildPath(Path_SM, logPath, sizeof(logPath), "logs/l4d2unscramber.log");
	#endif
	LoadTranslations("common.phrases");
	
	gConf = LoadGameConfigFile("l4dunscrambler");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "GetTeamScore");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	fGTS = EndPrepSDKCall();

	cvarWait = CreateConVar("l4d2u_wait", "15", "Wait this many seconds after a map starts before giving up on fixing teams");
	cvarHoldOn = CreateConVar("l4d2u_holdon", "15", "If there's a connecting player when we decide to stop waiting, hold on for this many more seconds");
	h_Switch_CheckTeams = CreateConVar("l4d2u_checkteams", "1", "Determines if the function should check if target team is full", ADMFLAG_KICK, true, 0.0, true, 1.0);
	CreateConVar("l4d2u_version", VERSION, "L4D2 Unscrambler version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2u");
	
	HookEvent("player_first_spawn", Event_FirstSpawnNotify,EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart,EventHookMode_Post);
	HookEvent("round_end", eventRoundEnd,EventHookMode_Post);
//	RegConsoleCmd("chooseteam",Command_ChooseTeam);	
	// First we check if menu is ready ..
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
	
}



#if DEBUG

dumpNames()
{
	decl String:name[MAX_NAME_LENGTH];
	decl String:auth[SIDSIZE];
	new i;
	for (i = 1; i <= L4D_MAXCLIENTS; i++)
		if (IsClientConnected(i))
	{
		if (IsClientAuthorized(i)) GetClientIP(i, auth, sizeof(auth),false);
		else auth = "noauth";
		
		GetClientName(i, name, sizeof(name));
		if (IsClientInGame(i)) LogToFileEx(logPath, "%s (%d, %s) is on team %d", name, i, auth, GetClientTeam(i));
		else LogToFileEx(logPath, "%s (%d, %s) isn't in game", name, i, auth);
	}
}
#endif
#if DEBUG
new String:TeamNames[3][]={"Spectators","Survivors","Infected"};
debugNames(String:prefix[], i, j,needteam_index)
{
	decl String:name[2][MAX_NAME_LENGTH];
	GetClientName(i, name[0], sizeof(name[]));
	if (j){
		GetClientName(j, name[1], sizeof(name[]));
		LogToFileEx(logPath, "%s swapped %s and %s", prefix, name[0], name[1]);
	}else{
		LogToFileEx(logPath, "%s Switched %s to %s", prefix, name[0], TeamNames[needteam_index]);
	}
}
#endif

//if the wait time has elapsed, kill the unscramble timer
//if there's someone still connecting hold on a little longer,
//but only hold on once
//also clear the saved team list
public Action:stopWait(Handle:timer, any:holdingOn)
{
	#if DEBUG
	LogToFileEx(logPath, "Stop wait?");
	#endif
	if ((GetClientCount() == GetClientCount(false)) || holdingOn)
	{
		#if DEBUG
		LogToFileEx(logPath, "Not holding on");
		dumpNames();
		#endif
		if (timerUnscramble != INVALID_HANDLE)
		{
			KillTimer(timerUnscramble);
			timerUnscramble = INVALID_HANDLE;
		}
	}
	else timerWait = CreateTimer(GetConVarFloat(cvarHoldOn), stopWait, true, TIMER_FLAG_NO_MAPCHANGE);
}

//swap the two given players
swap(i, j)
{
	new inf, surv;
	if (GetClientTeam(i) == L4D_TEAM_INFECTED)
	{
		inf = i;
		surv = j;
	}
	else
	{
		inf = j;
		surv = i;
	}
	
	ChangeClientTeam(inf, L4D_TEAM_SPECTATE);
	ChangeClientTeam(surv, L4D_TEAM_SPECTATE);
	ChangePlayerTeam(surv, L4D_TEAM_INFECTED);
	ChangePlayerTeam(inf,L4D_TEAM_SURVIVORS);
}


public Action:unscramble(Handle:timer)
{
	//just to be sure this timer doesn't go forever somehow
	uCount++;
	if (uCount > 30)
	{
		#if DEBUG
		LogToFileEx(logPath, "Forcefully stopped unscrambling.");
		#endif
		
		timerUnscramble = INVALID_HANDLE;
		if (timerWait != INVALID_HANDLE)
		{
			KillTimer(timerWait);
			timerWait = INVALID_HANDLE;
		}
		
		return Plugin_Stop;
	}
	
	new i, j, k, team;
	
	new String:auth[SIDSIZE];
	new clStatus[L4D_MAXCLIENTS + 1];
	new nIncorrect, nCorrect; //total number of correct and incorrect players (see comment below)
	new	curTeam[3]; //count of players currently on each team
	new nICTeam[3]; //count of incorrect players currently on each team
	//0 - spec, 1 - surv, 2 -inf

	
	//decide if a player is 
	//(1) correct: he's from the previous round and on the right team
	//(-2 or -3, based on current team) incorrect: he's from the previous round and on the wrong team
	//(2 or 3, based on current team) someone who wasn't here before, so can be swapped freely
	//(0) not connected/not authed/empty slot
	//TODO make this suck less, should have used a trie
	new found;
	for (k = 1; k <= L4D_MAXCLIENTS; k++)
	{
		found = 0;
		team = -1;
		
		//if they're not in game yet move on
		if (IsClientConnected(k) && IsClientInGame(k) && !IsFakeClient(k) && IsClientAuthorized(k))
		{
			team = GetClientTeam(k);
			if (team < 1 || team > 3) continue; //if they're not on a team yet, move on
			//0-surv, 1 -inf 2-spec
			curTeam[team - 1]++;
		}
		else continue;
		
		GetClientIP(k, auth, sizeof(auth),false);
		
		for (i = 0; i < 2; i++){
			for (j = 0; j < nTeam[i]; j++){
				#if DEBUGTEAMS
				LogToFileEx(logPath, "Going to compare teams[%d][%d] = %s to clID[%d] = %s", i, j, teams[i][j], k, clID[k]);
				#endif
				
				if (StrEqual(teams[i][j], auth))
					if (team == (i + 2)){						
						nCorrect++;			
						clStatus[k] = 1;
						found = 1;
						break; //j loop
					}else{
						nIncorrect++;
						nICTeam[team - 1]++; // 0 -never
						//nICTeam - 0 spec, 1 - surv, 2-inf
						//clStatus - (-2) - survivios, (-3) - infected
						clStatus[k] = -(i + 2); 
						found = 1;
						break; //j loop
					}
			}
			
			if (found) break; //i loop
		}
		
		//not in stored list and on a team
		if (!found && ((team == 2) || (team == 3))) {
			//todo: send to spectators
			clStatus[k] = team;
		}else if (!found) {
			//todo: kick			
			clStatus[k] = 1;
		}
	}
	
	#if DEBUGTEAMS
	decl String:name[MAX_NAME_LENGTH];
	for (i = 1; i <= L4D_MAXCLIENTS; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientName(i, name, sizeof(name));
			GetClientIP(i, auth, sizeof(auth),false);
			if (IsClientInGame(i)) LogToFileEx(logPath, "%s: ID=%d, auth=%s, team=%d, status=%d", name, i, auth, GetClientTeam(i), clStatus[i]);
			else LogToFileEx(logPath, "%s (%d, %s) isn't in game", name, i, auth);
		}
		//else LogToFileEx(logPath, "%d is not connected", i);
	}
	
	#endif
	
	#if DEBUG
	LogToFileEx(logPath, "Pass starting: nT[0] = %d, nT[1] = %d, nIC = %d, nC = %d, nIC[0] = %d, nIC[1] = %d, nIC[2] = %d", nTeam[0], nTeam[1], nIncorrect, nCorrect, nICTeam[0], nICTeam[1], nICTeam[2]);
	#endif
	
	//for each incorrect player, swap somebody if it won't empty out the survivor team
	//if the survivor team gets emptied out, the server might cycle the round
	for (i = 1; i <= L4D_MAXCLIENTS; i++)
	{
		//if the player isn't incorrect, move on
		if (clStatus[i] >= 0) continue;
		new needteam=-clStatus[i];
		new needteam_index=needteam - 1;
		//nICTeam,curTeam - 0 spec, 1 - surv, 2-inf
		//clStatus - (-2) - survivios, (-3) - infected
		if (curTeam[needteam_index] < GetTeamMaxHumans(needteam))
		{
			#if DEBUG
			debugNames("I/0", i, 0,needteam_index);
			#endif
			
			//swap team and update status
			ChangeClientTeam(i, 1);			
			if (!ChangePlayerTeam(i,needteam)){
				PrintToServer("Unscramble Error: Cannot change team!");
			}
			
			nIncorrect--; 
			nCorrect++;
			curTeam[needteam_index]++;
			nICTeam[3-needteam_index]--; // 1 => 2, 2 =>1
			clStatus[i] = 1;
		}
		//if there's at least one player on each team that's incorrect, swap them unless
		//there's only one survivor
		else if (nICTeam[1]>0 && nICTeam[2]>0)
		{
			//start looking from after current index, since we've fixed earlier ones
			for (j = i; j <= L4D_MAXCLIENTS; j++)
				//map -2 -> -3 and -3 -> -2 to see if they're on opposite teams and incorrect
			if (clStatus[i] == (-clStatus[j] - 5))
			{
				#if DEBUG
				debugNames("I/I", i, j,needteam_index);
				#endif
				swap(i, j);
				
				//update counts/statuses
				nIncorrect -= 2;
				nCorrect += 2;
				nICTeam[1]--; 
				nICTeam[2]--;
				clStatus[i] = 1;
				clStatus[j] = 1;
				break;
			}
		}
		//if there isn't an incorrect player on the other team to swap with,
		//and there isn't room on the other team,
		//then find a new player on the other team and swap
		else
		{
			new found_free=false;
			for (j = 1; j <= L4D_MAXCLIENTS; j++){
				//map -2 -> 3 and -3 -> 2 to see if they're on opposite team but non-incorrect
			if (needteam == clStatus[j])
			{
				#if DEBUG
				debugNames("I/X", i, j,needteam_index);
				#endif
				team = GetClientTeam(i);
				if (team==L4D_TEAM_SPECTATE){
					ChangeClientTeam(j, L4D_TEAM_SPECTATE);
					ChangePlayerTeam(i,needteam);
				}else{
					swap(i,j);
				}	
				nIncorrect--; 
				nICTeam[needteam_index]--;
				nCorrect++;
				clStatus[i] = 1;
//				if (team==1) clStatus[j] = 1;
//				else clStatus[j] = -team; 
				found_free=true;
				break;
			}
			}
			if (!found_free){
				#if DEBUG
				LogToFileEx(logPath, "ERROR: free not found");
				#endif
			}
		}
	}	
	
	#if DEBUG
	LogToFileEx(logPath, "Pass done: nIC = %d, nC = %d, nIC[0] = %d, nIC[1] = %d, nIC[2] = %d", nIncorrect, nCorrect, nICTeam[0], nICTeam[1], nICTeam[2]);
	#endif
	
	//so now, everyone connected and authed is correct
	//if all players from the last map are accounted for, we're done
	//blank out the stored teams and stop the timers if so
	if (nCorrect == (nTeam[0] + nTeam[1]))
	{	
		#if DEBUG
		LogToFileEx(logPath, "Fixed teams, stopping stopwait");
		dumpNames();
		#endif
		
		timerUnscramble = INVALID_HANDLE;
		if (timerWait != INVALID_HANDLE)
		{
			KillTimer(timerWait);
			timerWait = INVALID_HANDLE;
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public OnMapStart()
{
	decl String:curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	#if DEBUG	
	LogToFileEx(logPath, "Got map %s", curMap);
	#endif
	
	Round=0;
	
	//on non versus maps do nothing, on map 1 don't try to fix teams, on map 5 don't store teams
	decl String:gamemode[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, 64);
	if (StrEqual(gamemode, "versus")){
		isFirstMap=GetTeamCompaignScore(SCORE_TEAM_A)==0;
		if (isFirstMap) InitCompaign();		
		else{
			if(GetTeamCompaignScore(LastInfectedTeam)>GetTeamCompaignScore(OppositeLogicalTeam(LastInfectedTeam))){
				#if DEBUG
				LogToFileEx(logPath, "SWAP TEAMS! last infected swaped to surv [%d,%d - %d,%d]",LastInfectedTeam,GetTeamCompaignScore(LastInfectedTeam),OppositeLogicalTeam(LastInfectedTeam),GetTeamCompaignScore(OppositeLogicalTeam(LastInfectedTeam)));
				#endif
				FirstSurvivorTeam=LastInfectedTeam;
				new String:tmpAuth[SIDSIZE];
				new i;
				for (i = 0; i < TEAMSIZE; i++){
					strcopy(tmpAuth, SIDSIZE, teams[0][i]);
					strcopy(teams[0][i], SIDSIZE, teams[1][i]);
					strcopy(teams[1][i], SIDSIZE, tmpAuth);
				}
				i=nTeam[0];
				nTeam[0] = nTeam[1];
				nTeam[1]=i;				
			}else{
				FirstSurvivorTeam=OppositeLogicalTeam(LastInfectedTeam);
				#if DEBUG
				LogToFileEx(logPath, "Last infected team loose [%d,%d - %d,%d]",LastInfectedTeam,GetTeamCompaignScore(LastInfectedTeam),OppositeLogicalTeam(LastInfectedTeam),GetTeamCompaignScore(OppositeLogicalTeam(LastInfectedTeam)));
				#endif
			}
		}		
		if (StrContains(curMap, "c1m1") == -1){
			LogToFileEx(logPath, "Map Start scores: %d %d",GetTeamCompaignScore(1),GetTeamCompaignScore(2));			
			uCount = 0;
		}else{
			FirstSpawn=false;
		}
	} 
}

public OnMapEnd()
{
	FirstSpawn=true;

	#if DEBUG
	new j;
	for (new i = 0; i < 2; i++)
		for (j = 0; j < nTeam[i]; j++)
			LogToFileEx(logPath, "teams[%d][%d] = %s", i, j, teams[i][j]);
	dumpNames();
	LogToFileEx(logPath, "Map End scores: %d %d",GetTeamCompaignScore(1),GetTeamCompaignScore(2));
	#endif
	LastInfectedTeam=FirstSurvivorTeam;
//	storeTeams();
//	Scores[1]=GetTeamCompaignScore(1);
//	Scores[2]=GetTeamCompaignScore(2);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Round++;
	RoundEndDone=false;
/*	if (BeforeMapStart) {
		#if DEBUG
		LogToFileEx(logPath, "WARNING!!! RoundStart befor map start");
		#endif
	}
*/
}

public Action:Event_FirstSpawnNotify(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (FirstSpawn){
		timerUnscramble = CreateTimer(5.0, unscramble, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		timerWait = CreateTimer(GetConVarFloat(cvarWait), stopWait, false, TIMER_FLAG_NO_MAPCHANGE);
	}
	FirstSpawn=false;
}


public Action:eventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//for detect double round end (calc scores and team at second pass)
	if(!RoundEndDone) {
		RoundEndDone=true;
		return Plugin_Continue;
	}
	
	RoundEndDone = true;
	
	if (Round==0){
		//Scores[0]=GetTeamCompaignScore(1);
		//Scores[1]=GetTeamCompaignScore(2);
	}else{
//		Scores[0]=GetTeamCompaignScore(1);
//		Scores[1]=GetTeamCompaignScore(2);
	}
	#if DEBUG
	LogToFileEx(logPath, "Round:%d. Campagin scores: A=%d B=%d",Round,GetTeamCompaignScore(1),GetTeamCompaignScore(2));
	#endif
	storeTeams();
	return Plugin_Continue;
}

InitCompaign()
{
	#if DEBUG
	LogToFileEx(logPath, "InitCompaign()");
	#endif
   
	isFirstMap=true;
	FirstSurvivorTeam=SCORE_TEAM_A;
}



//put everyone's SteamIDs into the array
//index 0 is team 2, index 1 is team 3
storeTeams()
{
	new i, team, String:auth[SIDSIZE];
	#if DEBUGTEAMS
	new String:name[MAX_NAME_LENGTH];
	#endif
	nTeam[0] = 0; nTeam[1] = 0;
	
	for (i = 1; i <= L4D_MAXCLIENTS; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
	{
		team = GetClientTeam(i);
		
		if ((team != 2) && (team != 3)) continue;
		
		if (nTeam[team - 2] > TEAMSIZE) 
		{
			#if DEBUGTEAMS
			LogToFileEx(logPath, "PRINTER IS ON FIRE");
			#endif
			continue;
		}
		
		#if DEBUGTEAMS
		GetClientName(i, name, sizeof(name));
		LogToFileEx(logPath, "Found %s on team %d, team - 2 = %d, nT[team - 2] = %d", name, team, team - 2, nTeam[team - 2]);
		#endif
		GetClientIP(i, auth, sizeof(auth),false);
		strcopy(teams[team - 2][nTeam[team - 2]], SIDSIZE, auth);
		nTeam[team - 2]++;
	}
	new balanced=RoundToNearest(FloatAbs(float(nTeam[0]-nTeam[1])));
	if (balanced>=2){
		new balanced2=balanced / 2;
		PrintToChatAll("Player moved to another team due team balance.");
		if (nTeam[0]>nTeam[1]){
			// survivors have disbalans
			for (i = 0; i <= balanced2; i++){
				strcopy(teams[1][nTeam[1]], SIDSIZE, teams[0][nTeam[0]]);
				new client=Ip2Client(teams[1][nTeam[1]]);
//				if (GetClientFrags(client) & ADMFLAG_RESERVATION)
	//				continue;
				nTeam[0]--;
				nTeam[1]++;
				if (client)
					PerformSwitch_fast(client,L4D_TEAM_INFECTED);
			}
			PrintToChatAll("Player moved to another team due team balance.(SURV->INF) (%d,%d)",balanced,balanced2);
		}else{
			// infected have disbalans
			for (i = 0; i <= balanced2; i++){
				strcopy(teams[0][nTeam[0]], SIDSIZE, teams[1][nTeam[1]]);
				new client=Ip2Client(teams[1][nTeam[1]]);
				nTeam[1]--;
				nTeam[0]++;
				if (client)
					PerformSwitch_fast(client,L4D_TEAM_SURVIVORS);
			}
			PrintToChatAll("Player moved to another team due team balance.(INF->SURV) (%d,%d)",balanced,balanced2);
		}
		
		
		
	}
	
	
	#if DEBUG
	LogToFileEx(logPath, "Stored %d, %d", nTeam[0], nTeam[1]);
	#endif
}

Ip2Client(const String:ip[])
{
	for (new i = 1; i <= L4D_MAXCLIENTS; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i)){
			decl String:curip[32];
			GetClientIP(i,curip,32,false);
			if (StrEqual(curip,ip)){
				return i;
			}
		}
	return 0;	
}

/********************************************************************************/
/********************** from TeamSWITCH (by SkyDavid (djromero)) ****************/
/********************************************************************************/

new bool:IsSwapPlayers;
new SwapPlayer1;
new SwapPlayer2;

new g_SwitchTo;
new g_SwitchTarget;

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	// Check ..
	if (topmenu == hTopMenu) return;
	
	// We save the handle
	hTopMenu = topmenu;
	
	// Find player's menu ...
	new TopMenuObject:players_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	// now we add the function ...
	if (players_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu (hTopMenu, "l4dteamswitch", TopMenuObject_Item, SkyAdmin_SwitchPlayer, players_commands, "l4dteamswitch", ADMFLAG_KICK);
		AddToTopMenu (hTopMenu, "l4dswapplayers", TopMenuObject_Item, SkyAdmin_SwapPlayers, players_commands, "l4dswapplayers", ADMFLAG_KICK);
	}
}

public SkyAdmin_SwitchPlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	IsSwapPlayers = false;
	SwapPlayer1 = -1;
	SwapPlayer2 = -1;
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Switch player", "", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//DisplaySwitchPlayerToMenu(param);
		DisplaySwitchPlayerMenu(param);
	}
}

public SkyAdmin_SwapPlayers(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	IsSwapPlayers = true;
	SwapPlayer1 = -1;
	SwapPlayer2 = -1;
	
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Swap players", "", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		//DisplaySwitchPlayerToMenu(param);
		DisplaySwitchPlayerMenu(param);
	}
}


DisplaySwitchPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SwitchPlayer);
	
	decl String:title[100];
	if (!IsSwapPlayers)
		Format(title, sizeof(title), "Switch player", "", client);
	else
	{
		if (SwapPlayer1 == -1)
			Format(title, sizeof(title), "Player 1", "", client);
		else
		Format(title, sizeof(title), "Player 2", "", client);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SwitchPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		
		if (IsSwapPlayers)
		{
			if (SwapPlayer1 == -1)
				SwapPlayer1 = target;
			else
			SwapPlayer2 = target;
			
			if ((SwapPlayer1 != -1)&&(SwapPlayer2 != -1))
			{
				PerformSwap(param1);
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
			else
			DisplaySwitchPlayerMenu(param1);
			
		}
		else
		{
			g_SwitchTarget = target;
			DisplaySwitchPlayerToMenu(param1);
		}
	}
}

DisplaySwitchPlayerToMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_SwitchPlayerTo);
	
	decl String:title[100];
	Format(title, sizeof(title), "Choose team", "", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "1", "Spectators");
	AddMenuItem(menu, "2", "Survivors");
	AddMenuItem(menu, "3", "Infected");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_SwitchPlayerTo(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		g_SwitchTo = StringToInt(info);
		
		PerformSwitch(param1, g_SwitchTarget, g_SwitchTo, false);
		
		DisplaySwitchPlayerMenu(param1);
	}
}

/*public Action:Command_ChooseTeam(client, args) {
	if (client==0) client=1;
	DisplayChooseTeamMenu(client);
	return Plugin_Handled;
}
*/
DisplayChooseTeamMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ChooseTeam);
	SetMenuTitle(menu, "Choose team");
	SetMenuExitButton(menu, true);
	
	AddMenuItem(menu, "option1", "Spectators");
	AddMenuItem(menu, "option2", "Survivors");
	AddMenuItem(menu, "option3", "Infected");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_ChooseTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		param2+=1;
		PerformSwitch(param1, param1, param2, true);
		CloseHandle(menu);
	}
}


bool:IsTeamFull (team)
{
	// Spectator's team is never full :P
	if (team == 1)
		return false;
	
	new max = GetTeamMaxHumans(team);
	new count = GetTeamHumanCount(team);
	
	// If full ...
	return (count >= max);
}


PerformSwap (client)
{
	// If client 1 and 2 are the same ...
	if (SwapPlayer1 == SwapPlayer2)
	{
		PrintToChat(client, "[SM] Can't swap this player with himself.");
		return;
	}
	
	// Check if 1st player is still valid ...
	if ((!IsClientConnected(SwapPlayer1)) || (!IsClientInGame(SwapPlayer1)))
	{
		PrintToChat(client, "[SM] First player is not available anymore.");
		return;
	}

	// Check if 2nd player is still valid ....
	if ((!IsClientConnected(SwapPlayer2)) || (!IsClientInGame(SwapPlayer2)))
	{
		PrintToChat(client, "[SM] Second player is not available anymore.");
		return;
	}
	
	// get the teams of each player
	new team1 = GetClientTeam(SwapPlayer1);
	new team2 = GetClientTeam(SwapPlayer2);
	
	// If both players are on the same team ...
	if (team1 == team2)
	{
		PrintToChat(client, "[SM] Can't swap players that are on the same team.");
		return;
	}
	ChangeTeamInList(SwapPlayer1,SwapPlayer2,true);
	
	// first we move both clients to spectators
	PerformSwitch(client, SwapPlayer1, 1, true);
	PerformSwitch(client, SwapPlayer2, 1, true);
	
	// Now we move each client to their respective team
	PerformSwitch(client, SwapPlayer1, team2, true);
	PerformSwitch(client, SwapPlayer2, team1, true);
	
	// Print swap info ..
	new String:PlayerName1[200];
	new String:PlayerName2[200];
	GetClientName(SwapPlayer1, PlayerName1, sizeof(PlayerName1));
	GetClientName(SwapPlayer2, PlayerName2, sizeof(PlayerName2));
	PrintToChatAll("\x01[SM] \x03%s \x01has been swapped with \x03%s", PlayerName1, PlayerName2);
}


PerformSwitch_fast (target, team)
{
	ChangePlayerTeam(target,team);
	// Print switch info ..
	new String:PlayerName[200];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	if (team == 1)
		PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
	else if (team == 2)
		PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Survivors", PlayerName);
	else if (team == 3)
		PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Infected", PlayerName);
}

PerformSwitch (client, target, team, bool:silent)
{
	if ((!IsClientConnected(target)) || (!IsClientInGame(target)))
	{
		PrintToChat(client, "[SM] The player is not avilable anymore.");
		return;
	}
	
	// If teams are the same ...
	if (GetClientTeam(target) == team)
	{
		PrintToChat(client, "[SM] That player is already on that team.");
		return;
	}
	
	// If we should check if teams are full ...
	if (GetConVarBool(h_Switch_CheckTeams))
	{
		// We check if target team is full...
		if (IsTeamFull(team))
		{
			if (team == 2)
				PrintToChat(client, "[SM] The \x03Survivor\x01's team is already full.");
			else
			PrintToChat(client, "[SM] The \x03Infected\x01's team is already full.");
			return;
		}
	}

	if (!silent)
		ChangeTeamInList(target,team,false);
		
	
	if (!ChangePlayerTeam(target,team)){
		PrintToChat(client, "[SM] Error due change team.");	
	}
	
	// Print switch info ..
	new String:PlayerName[200];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	
	if (!silent)
	{
		if (team == 1)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
		else if (team == 2)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Survivors", PlayerName);
		else if (team == 3)
			PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Infected", PlayerName);
	}
}


/********************************************************************************/
/******************************** STOKS *****************************************/
/********************************************************************************/

ChangeTeamInList(client,param2=0,bool:goswap)
{
	decl String:ip1[SIDSIZE];
	decl String:ip2[SIDSIZE];
	new index=-1;
	new index2=-1;
	new subindex=-1;
	new subindex2=-1;
	GetClientIP(client,ip1,SIDSIZE,false);
	if (goswap)		
		GetClientIP(param2,ip2,SIDSIZE,false);
	for (new i = 0; i < 2; i++){
		for (new j = 0; j < nTeam[i]; j++){
			if (!strcmp(ip1,teams[i][j])){
					index=i;
					subindex=j;
					if (!goswap) break;
			}
			if (goswap){
				if (!strcmp(ip2,teams[i][j])){
					index2=i;
					subindex2=j;
				}
				if (subindex!=-1 && subindex2!=-1) break;
			}
		}
	}
	if (goswap){
		if (subindex!=-1)
			strcopy(teams[index][subindex],SIDSIZE,ip2);
		if (subindex2!=-1)
			strcopy(teams[index2][subindex2],SIDSIZE,ip1);
		return;
	}
	new nindex = param2 - 2;	
	if (index != -1)
		DeleteFromList(index,subindex);
	if (param2==L4D_TEAM_SPECTATE) 
		return;
	strcopy(teams[nindex][nTeam[nindex]], SIDSIZE, ip1);
	nTeam[nindex]++;	
}

DeleteFromList(index,subindex)
{
	if (subindex!=nTeam[index]-1)
		strcopy(teams[index][subindex],SIDSIZE,teams[index][nTeam[index]-1]);
	nTeam[index]--;
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
		LogToFileEx(logPath, "ChangePlayerTeam() : Cannot switch %N to team %d, as team is full", client, team);
		return false;
	}
	
	new bot;
	//for survivors its more tricky
	for(bot = 1; 
	bot < L4D_MAXCLIENTS_PLUS1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != L4D_TEAM_SURVIVORS));
	bot++) {}
	
	if(bot == L4D_MAXCLIENTS_PLUS1)
	{
		LogToFileEx(logPath, "Could not find a survivor bot, adding a bot ourselves");
		
		new String:command[] = "sb_add";
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		
		ServerCommand("sb_add");
		
		SetCommandFlags(command, flags);
		
		LogToFileEx(logPath, "Added a survivor bot, trying again...");
		return false;
	}
	
	//have to do this to give control of a survivor bot
	SDKCall(fSHS, bot, client);
	SDKCall(fTOB, client, true);
	
	return true;
}

stock GetTeamHumanCount(team)
{
	new humans = 0;
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) == team){
			humans++;
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

stock GetTeamRoundScore(logical_team)
{
	return SDKCall(fGTS, logical_team, SCORE_TYPE_ROUND);	
}

stock GetTeamCompaignScore(logical_team)
{
	return SDKCall(fGTS, logical_team, SCORE_TYPE_CAMPAIGN);	
}


//client is in-game and not a bot
stock bool:IsClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

