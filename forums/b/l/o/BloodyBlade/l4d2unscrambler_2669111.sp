#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <adminmenu>

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

public Plugin myinfo =
{
	name = "[L4D2] Unscrambler",
	author = "modified by V10 (original by Fyren)",
	description = "Keeps teams unscrambled after map change in versus\team switch, team change",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=730278"
};

ConVar cvarWait;
ConVar cvarHoldOn;
Handle timerWait = null;
Handle timerUnscramble = null;
ConVar IsAutoBalanceOn;
char teams[2][TEAMSIZE][SIDSIZE]; //two teams, four players, 16 chars for Steam ID
#if DEBUG
char logPath[256];
#endif
int nTeam[2]; //number of players stored in the list
//int storing; //if we're on a versus map and should be storing teams
int uCount; //number of teams unscramble has repped as a failsafe
Handle gConf = INVALID_HANDLE;
Handle fSHS = INVALID_HANDLE;
Handle fTOB = INVALID_HANDLE;
Handle fGTS = INVALID_HANDLE;
bool RoundEndDone;
//new Scores[3];    
int Round = 0;
int LastInfectedTeam;
int FirstSurvivorTeam;
bool isFirstMap = false;
ConVar h_Switch_CheckTeams;
bool FirstSpawn = true;
// top menu
Handle hTopMenu = INVALID_HANDLE;

public void OnPluginStart()
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
	IsAutoBalanceOn = CreateConVar("l4d2u_allowautobalance", "1", "Should we autobalance teams on round end?");
	CreateConVar("l4d2u_version", VERSION, "L4D2 Unscrambler version", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2u");
	
	HookEvent("player_first_spawn", Event_FirstSpawnNotify,EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart,EventHookMode_Post);
	HookEvent("round_end", eventRoundEnd,EventHookMode_Post);
//	RegConsoleCmd("chooseteam", Command_ChooseTeam);	
	// First we check if menu is ready ..
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}	
}

#if DEBUG

void dumpNames()
{
	char name[MAX_NAME_LENGTH];
	char auth[SIDSIZE];
	int i;
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
char TeamNames[3][]={"Spectators","Survivors","Infected"};
void debugNames(char[] prefix, int i, int j, int needteam_index)
{
	char name[2][MAX_NAME_LENGTH];
	GetClientName(i, name[0], sizeof(name[]));
	if (j)
	{
		GetClientName(j, name[1], sizeof(name[]));
		LogToFileEx(logPath, "%s swapped %s and %s", prefix, name[0], name[1]);
	}
	else
	{
		LogToFileEx(logPath, "%s Switched %s to %s", prefix, name[0], TeamNames[needteam_index]);
	}
}
#endif

//if the wait time has elapsed, kill the unscramble timer
//if there's someone still connecting hold on a little longer,
//but only hold on once
//also clear the saved team list
public Action stopWait(Handle timer, any holdingOn)
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
		if (timerUnscramble != null)
		{
			KillTimer(timerUnscramble);
			timerUnscramble = null;
		}
	}
	else timerWait = CreateTimer(GetConVarFloat(cvarHoldOn), stopWait, true, TIMER_FLAG_NO_MAPCHANGE);
}

//swap the two given players
void swap(int i, int j)
{
	int inf, surv;
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


public Action unscramble(Handle timer)
{
	//just to be sure this timer doesn't go forever somehow
	uCount++;
	if (uCount > 30)
	{
		#if DEBUG
		LogToFileEx(logPath, "Forcefully stopped unscrambling.");
		#endif

		timerUnscramble = null;
		if (timerWait != null)
		{
			KillTimer(timerWait);
			timerWait = null;
		}
		return Plugin_Stop;
	}

	int i, j, k, team;

	char auth[SIDSIZE];
	int[] clStatus = new int[L4D_MAXCLIENTS + 1];
	int nIncorrect, nCorrect; //total number of correct and incorrect players (see comment below)
	int	curTeam[3]; //count of players currently on each team
	int nICTeam[3]; //count of incorrect players currently on each team
	//0 - spec, 1 - surv, 2 -inf

	//decide if a player is 
	//(1) correct: he's from the previous round and on the right team
	//(-2 or -3, based on current team) incorrect: he's from the previous round and on the wrong team
	//(2 or 3, based on current team) someone who wasn't here before, so can be swapped freely
	//(0) not connected/not authed/empty slot
	//TODO make this suck less, should have used a trie
	int found;
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

		GetClientIP(k, auth, sizeof(auth), false);
		
		for (i = 0; i < 2; i++)
		{
			for (j = 0; j < nTeam[i]; j++)
			{
				#if DEBUGTEAMS
				LogToFileEx(logPath, "Going to compare teams[%d][%d] = %s to clID[%d] = %s", i, j, teams[i][j], k, clID[k]);
				#endif

				if (StrEqual(teams[i][j], auth))
				{
					if (team == (i + 2))
					{						
						nCorrect++;			
						clStatus[k] = 1;
						found = 1;
						break; //j loop
					}
					else
					{
						nIncorrect++;
						nICTeam[team - 1]++; // 0 -never
						//nICTeam - 0 spec, 1 - surv, 2-inf
						//clStatus - (-2) - survivios, (-3) - infected
						clStatus[k] = -(i + 2); 
						found = 1;
						break; //j loop
					}
				}
			}
			if (found) break; //i loop
		}

		//not in stored list and on a team
		if (!found && ((team == 2) || (team == 3))) clStatus[k] = team; //todo: send to spectators
		else if (!found) clStatus[k] = 1; //todo: kick
	}
	
	#if DEBUGTEAMS
	char name[MAX_NAME_LENGTH];
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
		int needteam =- clStatus[i];
		int needteam_index = needteam - 1;
		//nICTeam,curTeam - 0 spec, 1 - surv, 2-inf
		//clStatus - (-2) - survivios, (-3) - infected
		if (curTeam[needteam_index] < GetTeamMaxHumans(needteam))
		{
			#if DEBUG
			debugNames("I/0", i, 0,needteam_index);
			#endif

			//swap team and update status
			ChangeClientTeam(i, 1);			
			if (!ChangePlayerTeam(i, needteam)) PrintToServer("Unscramble Error: Cannot change team!");

			nIncorrect--; 
			nCorrect++;
			curTeam[needteam_index]++;
			nICTeam[3-needteam_index]--; // 1 => 2, 2 =>1
			clStatus[i] = 1;
		}
		//if there's at least one player on each team that's incorrect, swap them unless
		//there's only one survivor
		else if (nICTeam[1] > 0 && nICTeam[2] > 0)
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
			int found_free = false;
			for (j = 1; j <= L4D_MAXCLIENTS; j++)
			{
				//map -2 -> 3 and -3 -> 2 to see if they're on opposite team but non-incorrect
				if (needteam == clStatus[j])
				{
					#if DEBUG
					debugNames("I/X", i, j, needteam_index);
					#endif
					team = GetClientTeam(i);
					if (team == L4D_TEAM_SPECTATE)
					{
						ChangeClientTeam(j, L4D_TEAM_SPECTATE);
						ChangePlayerTeam(i, needteam);
					}
					else
					{
						swap(i, j);
					}	
					nIncorrect--; 
					nICTeam[needteam_index]--;
					nCorrect++;
					clStatus[i] = 1;
	//				if (team==1) clStatus[j] = 1;
	//				else clStatus[j] = -team; 
					found_free = true;
					break;
				}
			}
			if (!found_free)
			{
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
		
		timerUnscramble = null;
		if (timerWait != null)
		{
			KillTimer(timerWait);
			timerWait = null;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	char curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	#if DEBUG	
	LogToFileEx(logPath, "Got map %s", curMap);
	#endif

	Round = 0;

	//on non versus maps do nothing, on map 1 don't try to fix teams, on map 5 don't store teams
	char gamemode[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, 64);
	if (StrEqual(gamemode, "versus"))
	{
		isFirstMap=GetTeamCompaignScore(SCORE_TEAM_A) == 0;
		if (isFirstMap) InitCompaign();		
		else
		{
			if(GetTeamCompaignScore(LastInfectedTeam) > GetTeamCompaignScore(OppositeLogicalTeam(LastInfectedTeam)))
			{
				#if DEBUG
				LogToFileEx(logPath, "SWAP TEAMS! last infected swaped to surv [%d,%d - %d,%d]",LastInfectedTeam,GetTeamCompaignScore(LastInfectedTeam),OppositeLogicalTeam(LastInfectedTeam),GetTeamCompaignScore(OppositeLogicalTeam(LastInfectedTeam)));
				#endif
				FirstSurvivorTeam=LastInfectedTeam;
				char tmpAuth[SIDSIZE];
				int i;
				for (i = 0; i < TEAMSIZE; i++)
				{
					strcopy(tmpAuth, SIDSIZE, teams[0][i]);
					strcopy(teams[0][i], SIDSIZE, teams[1][i]);
					strcopy(teams[1][i], SIDSIZE, tmpAuth);
				}
				i = nTeam[0];
				nTeam[0] = nTeam[1];
				nTeam[1] = i;				
			}
			else
			{
				FirstSurvivorTeam=OppositeLogicalTeam(LastInfectedTeam);
				#if DEBUG
				LogToFileEx(logPath, "Last infected team loose [%d,%d - %d,%d]", LastInfectedTeam, GetTeamCompaignScore(LastInfectedTeam), OppositeLogicalTeam(LastInfectedTeam), GetTeamCompaignScore(OppositeLogicalTeam(LastInfectedTeam)));
				#endif
			}
		}		
		if (StrContains(curMap, "c1m1") == -1)
		{
			LogToFileEx(logPath, "Map Start scores: %d %d", GetTeamCompaignScore(1), GetTeamCompaignScore(2));	
			uCount = 0;
		}
		else FirstSpawn = false;
	}
}

public void OnMapEnd()
{
	FirstSpawn = true;

	#if DEBUG
	int j;
	for (int i = 0; i < 2; i++)
	{
		for (j = 0; j < nTeam[i]; j++)
		{
			LogToFileEx(logPath, "teams[%d][%d] = %s", i, j, teams[i][j]);
		}
	}
	dumpNames();
	LogToFileEx(logPath, "Map End scores: %d %d",GetTeamCompaignScore(1),GetTeamCompaignScore(2));
	#endif
	LastInfectedTeam = FirstSurvivorTeam;
//	storeTeams();
//	Scores[1]=GetTeamCompaignScore(1);
//	Scores[2]=GetTeamCompaignScore(2);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Round++;
	RoundEndDone = false;
/*	if (BeforeMapStart) 
{
		#if DEBUG
		LogToFileEx(logPath, "WARNING!!! RoundStart befor map start");
		#endif
	}
*/
}

public Action Event_FirstSpawnNotify(Event event, const char[] name, bool dontBroadcast)
{
	if (FirstSpawn)
	{
		timerUnscramble = CreateTimer(5.0, unscramble, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		timerWait = CreateTimer(GetConVarFloat(cvarWait), stopWait, false, TIMER_FLAG_NO_MAPCHANGE);
	}
	FirstSpawn = false;
}


public Action eventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	//for detect double round end (calc scores and team at second pass)
	if(!RoundEndDone)
	{
		RoundEndDone = true;
		return Plugin_Continue;
	}

	RoundEndDone = true;

	if (Round == 0)
	{
		//Scores[0] = GetTeamCompaignScore(1);
		//Scores[1] = GetTeamCompaignScore(2);
	}
	else
	{
//		Scores[0] = GetTeamCompaignScore(1);
//		Scores[1] = GetTeamCompaignScore(2);
	}
	#if DEBUG
	LogToFileEx(logPath, "Round:%d. Campagin scores: A=%d B=%d",Round,GetTeamCompaignScore(1),GetTeamCompaignScore(2));
	#endif
	storeTeams();
	return Plugin_Continue;
}

void InitCompaign()
{
	#if DEBUG
	LogToFileEx(logPath, "InitCompaign()");
	#endif
   
	isFirstMap = true;
	FirstSurvivorTeam=SCORE_TEAM_A;
}

//put everyone's SteamIDs into the array
//index 0 is team 2, index 1 is team 3
void storeTeams()
{
	int i, team;
	char auth[SIDSIZE];
	#if DEBUGTEAMS
	char name[MAX_NAME_LENGTH];
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
	if (GetConVarBool(IsAutoBalanceOn))
	{
		int balanced = RoundToNearest(FloatAbs(float(nTeam[0] - nTeam[1])));
		if (balanced >= 2)
		{
			int balanced2 = balanced / 2;
			PrintToChatAll("Player moved to another team due team balance.");
			if (nTeam[0] > nTeam[1])
			{
				// survivors have disbalans
				for (i = 0; i <= balanced2; i++)
				{
					strcopy(teams[1][nTeam[1]], SIDSIZE, teams[0][nTeam[0]]);
					int client = Ip2Client(teams[1][nTeam[1]]);
					//if (GetClientFrags(client) & ADMFLAG_RESERVATION)
					//continue;
					nTeam[0]--;
					nTeam[1]++;
					if (client) PerformSwitch_fast(client,L4D_TEAM_INFECTED);
				}
				PrintToChatAll("Player moved to another team due team balance.(SURV->INF) (%d,%d)",balanced,balanced2);
			}
			else
			{
				// infected have disbalans
				for (i = 0; i <= balanced2; i++)
				{
					strcopy(teams[0][nTeam[0]], SIDSIZE, teams[1][nTeam[1]]);
					int client = Ip2Client(teams[1][nTeam[1]]);
					nTeam[1]--;
					nTeam[0]++;
					if (client) PerformSwitch_fast(client, L4D_TEAM_SURVIVORS);
				}
				PrintToChatAll("Player moved to another team due team balance.(INF->SURV) (%d, %d)", balanced, balanced2);
			}
		}
	}
	
	#if DEBUG
	LogToFileEx(logPath, "Stored %d, %d", nTeam[0], nTeam[1]);
	#endif
}

int Ip2Client(const char[] ip)
{
	for (int i = 1; i <= L4D_MAXCLIENTS; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			char curip[32];
			GetClientIP(i, curip, 32, false);
			if (StrEqual(curip, ip)) return i;
		}
	}
	return 0;	
}

/********************************************************************************/
/********************** from TeamSWITCH (by SkyDavid (djromero)) ****************/
/********************************************************************************/

bool IsSwapPlayers;
int SwapPlayer1;
int SwapPlayer2;

int g_SwitchTo;
int g_SwitchTarget;

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public void OnAdminMenuReady(Handle topmenu)
{
	// Check ..
	if (topmenu == hTopMenu) return;
	
	// We save the handle
	hTopMenu = topmenu;
	
	// Find player's menu ...
	TopMenuObject players_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	// now we add the function ...
	if (players_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu (hTopMenu, "l4dteamswitch", TopMenuObject_Item, SkyAdmin_SwitchPlayer, players_commands, "l4dteamswitch", ADMFLAG_KICK);
		AddToTopMenu (hTopMenu, "l4dswapplayers", TopMenuObject_Item, SkyAdmin_SwapPlayers, players_commands, "l4dswapplayers", ADMFLAG_KICK);
	}
}

public void SkyAdmin_SwitchPlayer(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	IsSwapPlayers = false;
	SwapPlayer1 = -1;
	SwapPlayer2 = -1;
	
	if (action == TopMenuAction_DisplayOption) Format(buffer, maxlength, "Switch player", "", param);
	else if (action == TopMenuAction_SelectOption) DisplaySwitchPlayerMenu(param);
		//DisplaySwitchPlayerToMenu(param);
}

public void SkyAdmin_SwapPlayers(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	IsSwapPlayers = true;
	SwapPlayer1 = -1;
	SwapPlayer2 = -1;

	if (action == TopMenuAction_DisplayOption) Format(buffer, maxlength, "Swap players", "", param);
	else if (action == TopMenuAction_SelectOption) DisplaySwitchPlayerMenu(param);
		//DisplaySwitchPlayerToMenu(param);
}

void DisplaySwitchPlayerMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_SwitchPlayer);
	
	char title[100];
	if (!IsSwapPlayers) Format(title, sizeof(title), "Switch player", "", client);
	else
	{
		if (SwapPlayer1 == -1) Format(title, sizeof(title), "Player 1", "", client);
		else Format(title, sizeof(title), "Player 2", "", client);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SwitchPlayer(Menu menu, MenuAction action, int param1, int param2)
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
		char info[32];
		int userid, target;
		
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
			if (SwapPlayer1 == -1) SwapPlayer1 = target;
			else SwapPlayer2 = target;

			if ((SwapPlayer1 != -1) && (SwapPlayer2 != -1))
			{
				PerformSwap(param1);
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
			}
			else DisplaySwitchPlayerMenu(param1);
		}
		else
		{
			g_SwitchTarget = target;
			DisplaySwitchPlayerToMenu(param1);
		}
	}
}

void DisplaySwitchPlayerToMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_SwitchPlayerTo);

	char title[100];
	Format(title, sizeof(title), "Choose team", "", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "1", "Spectators");
	AddMenuItem(menu, "2", "Survivors");
	AddMenuItem(menu, "3", "Infected");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MenuHandler_SwitchPlayerTo(Menu menu, MenuAction action, int param1, int param2)
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
		char info[32];

		GetMenuItem(menu, param2, info, sizeof(info));
		g_SwitchTo = StringToInt(info);

		PerformSwitch(param1, g_SwitchTarget, g_SwitchTo, false);

		DisplaySwitchPlayerMenu(param1);
	}
}

/*public Action:Command_ChooseTeam(client, args)
{
	if (client==0) client=1;
	DisplayChooseTeamMenu(client);
	return Plugin_Handled;
}

void DisplayChooseTeamMenu(int client)
{
	Menu menu = CreateMenu(MenuHandler_ChooseTeam);
	SetMenuTitle(menu, "Choose team");
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "option1", "Spectators");
	AddMenuItem(menu, "option2", "Survivors");
	AddMenuItem(menu, "option3", "Infected");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
*/
public int MenuHandler_ChooseTeam(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		param2 += 1;
		PerformSwitch(param1, param1, param2, true);
		CloseHandle(menu);
	}
}

bool IsTeamFull (int team)
{
	// Spectator's team is never full :P
	if (team == 1) return false;
	
	int max = GetTeamMaxHumans(team);
	int count = GetTeamHumanCount(team);
	
	// If full ...
	return (count >= max);
}

void PerformSwap(int client)
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
	int team1 = GetClientTeam(SwapPlayer1);
	int team2 = GetClientTeam(SwapPlayer2);
	
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
	char PlayerName1[200];
	char PlayerName2[200];
	GetClientName(SwapPlayer1, PlayerName1, sizeof(PlayerName1));
	GetClientName(SwapPlayer2, PlayerName2, sizeof(PlayerName2));
	PrintToChatAll("\x01[SM] \x03%s \x01has been swapped with \x03%s", PlayerName1, PlayerName2);
}

void PerformSwitch_fast(int target, int team)
{
	ChangePlayerTeam(target,team);
	// Print switch info ..
	char PlayerName[200];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	if (team == 1) PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
	else if (team == 2) PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Survivors", PlayerName);
	else if (team == 3) PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Infected", PlayerName);
}

void PerformSwitch(int client, int target, int team, bool silent)
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
			if (team == 2) PrintToChat(client, "[SM] The \x03Survivor\x01's team is already full.");
			else PrintToChat(client, "[SM] The \x03Infected\x01's team is already full.");
			return;
		}
	}

	if (!silent) ChangeTeamInList(target, team, false);

	if (!ChangePlayerTeam(target,team)) PrintToChat(client, "[SM] Error due change team.");

	// Print switch info ..
	char PlayerName[200];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	
	if (!silent)
	{
		if (team == 1) PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Spectators", PlayerName);
		else if (team == 2) PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Survivors", PlayerName);
		else if (team == 3) PrintToChatAll("\x01[SM] \x03%s \x01has been moved to \x03Infected", PlayerName);
	}
}

/********************************************************************************/
/******************************** STOKS *****************************************/
/********************************************************************************/

void ChangeTeamInList(int client, int param2 = 0, bool goswap)
{
	char ip1[SIDSIZE];
	char ip2[SIDSIZE];
	int index = -1;
	int index2 = -1;
	int subindex = -1;
	int subindex2 = -1;
	GetClientIP(client,ip1,SIDSIZE,false);
	if (goswap)		
		GetClientIP(param2,ip2,SIDSIZE,false);
	for (int i = 0; i < 2; i++)
	{
		for (int j = 0; j < nTeam[i]; j++)
		{
			if (!strcmp(ip1,teams[i][j]))
			{
				index = i;
				subindex = j;
				if (!goswap) break;
			}
			if (goswap)
			{
				if (!strcmp(ip2,teams[i][j]))
				{
					index2 = i;
					subindex2 = j;
				}
				if (subindex != -1 && subindex2 != -1) break;
			}
		}
	}
	if (goswap)
	{
		if (subindex != -1) strcopy(teams[index][subindex],SIDSIZE,ip2);
		if (subindex2 != -1) strcopy(teams[index2][subindex2],SIDSIZE,ip1);
		return;
	}
	int nindex = param2 - 2;	
	if (index != -1) DeleteFromList(index,subindex);
	if (param2 == L4D_TEAM_SPECTATE) return;
	strcopy(teams[nindex][nTeam[nindex]], SIDSIZE, ip1);
	nTeam[nindex]++;	
}

void DeleteFromList(int index, int subindex)
{
	if (subindex != nTeam[index] - 1) strcopy(teams[index][subindex], SIDSIZE, teams[index][nTeam[index] - 1]);
	nTeam[index]--;
}

stock int OppositeLogicalTeam(int logical_team)
{
	if(logical_team == SCORE_TEAM_A) return SCORE_TEAM_B;

	else if(logical_team == SCORE_TEAM_B) return SCORE_TEAM_A;
	else return -1;
}

stock bool ChangePlayerTeam(int client, int team)
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
	
	int bot;
	//for survivors its more tricky
	for(bot = 1; 
	bot < L4D_MAXCLIENTS_PLUS1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != L4D_TEAM_SURVIVORS));
	bot++) {}
	
	if(bot == L4D_MAXCLIENTS_PLUS1)
	{
		LogToFileEx(logPath, "Could not find a survivor bot, adding a bot ourselves");
		
		char command[] = "sb_add";
		int flags = GetCommandFlags(command);
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

stock int GetTeamHumanCount(int team)
{
	int humans = 0;
	for(int i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) == team) humans++;
	}
	return humans;
}

stock int GetTeamMaxHumans(int team)
{
	if(team == L4D_TEAM_SURVIVORS) return GetConVarInt(FindConVar("survivor_limit"));
	else if(team == L4D_TEAM_INFECTED) return GetConVarInt(FindConVar("z_max_player_zombies"));
	else if(team == L4D_TEAM_SPECTATE) return L4D_MAXCLIENTS;
	return -1;
}

stock int GetTeamRoundScore(int logical_team)
{
	return SDKCall(fGTS, logical_team, SCORE_TYPE_ROUND);	
}

stock int GetTeamCompaignScore(int logical_team)
{
	return SDKCall(fGTS, logical_team, SCORE_TYPE_CAMPAIGN);	
}

//client is in-game and not a bot
stock bool IsClientInGameHuman(int client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}
