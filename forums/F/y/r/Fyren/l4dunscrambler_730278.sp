#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define VERSION "1.0.2.2"
#define SIDSIZE 32
#define TEAMSIZE 4
#define DEBUG 0

public Plugin:myinfo =
{
	name = "L4D Unscrambler",
	author = "Fyren",
	description = "Keeps teams unscrambled after map change in versus",
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
new storing; //if we're on a versus map and should be storing teams
new uCount; //number of teams unscramble has repped as a failsafe
new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

#if DEBUG
dumpNames()
{
	decl String:name[MAX_NAME_LENGTH];
	decl String:auth[SIDSIZE];
	new i;
	for (i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i))
		{
			if (IsClientAuthorized(i)) GetClientAuthString(i, auth, sizeof(auth));
			else auth = "noauth";

			GetClientName(i, name, sizeof(name));
			if (IsClientInGame(i)) LogToFileEx(logPath, "%s (%d, %s) is on team %d", name, i, auth, GetClientTeam(i));
			else LogToFileEx(logPath, "%s (%d, %s) isn't in game", name, i, auth);
		}
}

debugNames(String:prefix[], i, j)
{
	decl String:name[2][MAX_NAME_LENGTH];
	GetClientName(i, name[0], sizeof(name[]));
	GetClientName(j, name[1], sizeof(name[]));
	LogToFileEx(logPath, "%s swapped %s and %s", prefix, name[0], name[1]);
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
	new inf, surv, bot;
	if (GetClientTeam(i) == 3)
	{
		inf = i;
		surv = j;
	}
	else
	{
		inf = j;
		surv = i;
	}

	ChangeClientTeam(inf, 1);
	ChangeClientTeam(surv, 3);

	bot = 1;
	while !(IsClientConnected(bot) && IsFakeClient(bot) && (GetClientTeam(bot) == 2)) do bot++;

	//have to do this to give control of a survivor bot
	//setHumanSpec(bot, inf);
	//controlBot(inf, true);
	SDKCall(fSHS, bot, inf);
	SDKCall(fTOB, inf, true);

	//don't think this'll ever happen, but whatever
	if (IsClientConnected(bot) && (GetClientTeam(bot) == 1)) KickClient(bot, "kicking unneeded bot.  Do not be alarmed.");
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

#if DEBUG
	dumpNames();
#endif

	new i, j, k, team;
	
	new String:auth[SIDSIZE];
	new String:clID[MaxClients + 1][SIDSIZE];
	new clStatus[MaxClients + 1];
	new nIncorrect, nCorrect; //total number of correct and incorrect players (see comment below)
	new	curTeam[2]; //count of players currently on each team
	new nICTeam[2]; //count of incorrect players currently on each team
	new nSurvivors; //count of human survivors to make sure the team never empties

	for (i = 1; i <= MaxClients; i++)
		 if (IsClientAuthorized(i)) 
		 {
			 GetClientAuthString(i, auth, sizeof(auth));
			 strcopy(clID[i], SIDSIZE, auth);
		 }

	//decide if a player is 
	//(1) correct: he's from the previous round and on the right team
	//(-2 or -3, based on current team) incorrect: he's from the previous round and on the wrong team
	//(2 or 3, based on current team) someone who wasn't here before, so can be swapped freely
	//(0) not connected/not authed/empty slot
	//TODO make this suck less, should have used a trie
	new found;
	for (k = 1; k <= MaxClients; k++)
	{
		found = 0;
		team = -1;

		//if they're not in game yet move on
		if (IsClientConnected(k) && IsClientInGame(k) && !IsFakeClient(k) && IsClientAuthorized(k))
		{
			team = GetClientTeam(k);
			if ((team != 2) && (team != 3)) continue; //if they're not on a team yet, move on
			if (team == 2) nSurvivors++;
			curTeam[team - 2]++;
		}
		else continue;

		for (i = 0; i < 2; i++)
		{
			for (j = 0; j < nTeam[i]; j++)
			{
#if DEBUG
				LogToFileEx(logPath, "Going to compare teams[%d][%d] = %s to clID[%d] = %s", i, j, teams[i][j], k, clID[k]);
#endif
				if (StrEqual(teams[i][j], clID[k]))
					if (team == (-i + 3)) 	//index 0 = used to be on team 2 = should now be on 3
					{						//index 1 = used to be on team 3 = should now be on 2
						nCorrect++;			//so, -i + 3 maps 0 -> 3 and 0 -> 2
						clStatus[k] = 1;
						found = 1;
						break; //j loop
					}
					else
					{
						nIncorrect++;
						nICTeam[team - 2]++;
						clStatus[k] = -team;
						found = 1;
						break; //j loop
					}
			}

			if (found) break; //i loop
		}
		
		//not in stored list and on a team
		if (!found && ((team == 2) || (team == 3))) clStatus[k] = team;
	}

#if DEBUG
	decl String:name[MAX_NAME_LENGTH];
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			GetClientName(i, name, sizeof(name));
			if (IsClientInGame(i)) LogToFileEx(logPath, "%s: ID=%d, auth=%s, team=%d, status=%d", name, i, clID[i], GetClientTeam(i), clStatus[i]);
			else LogToFileEx(logPath, "%s (%d, %s) isn't in game", name, i, auth);
		}
		//else LogToFileEx(logPath, "%d is not connected", i);
	}

	LogToFileEx(logPath, "Pass starting: nT[0] = %d, nT[1] = %d, nIC = %d, nC = %d, nIC[0] = %d, nIC[1] = %d", nTeam[0], nTeam[1], nIncorrect, nCorrect, nICTeam[0], nICTeam[1]);
#endif

	//for each incorrect player, swap somebody if it won't empty out the survivor team
	//if the survivor team gets emptied out, the server might cycle the round
	for (i = 1; i <= MaxClients; i++)
	{
		//if the player isn't incorrect, move on
		if (clStatus[i] >= 0) continue;

		//if the player is incorrect and there's room on the opposite team, switch him unless
		//he's the only survivor
		//map -2 -> 3 and -3 -> 2 to get the opposite team number
		if ((curTeam[clStatus[i] + 3] < TEAMSIZE) && !((clStatus[i] == -2) && (nSurvivors == 1)))
		{
#if DEBUG
			debugNames("I/0", i, 0);
#endif

			//swap team and update status
			ChangeClientTeam(i, 1);

			if (clStatus[i] == -3)
			{
				new bot = 1;
				while !(IsClientConnected(bot) && IsFakeClient(bot) && (GetClientTeam(bot) == 2)) do bot++;

				//have to do this to make sure they get control of a survivor bot
				//setHumanSpec(bot, i);
				//controlBot(i, true);
				SDKCall(fSHS, bot, i);
				SDKCall(fTOB, i, true);

				if (IsClientConnected(bot) && (GetClientTeam(bot) == 1)) KickClient(bot, "kicking unneeded bot.  Do not be alarmed.");
			}
			else ChangeClientTeam(i, 3);
	
			nIncorrect--; 
			nCorrect++;
			if (clStatus[i] == -2) nSurvivors--;
			nICTeam[-clStatus[i] - 2]--; //map -2 -> 0, -3 -> 1
			clStatus[i] = 1;
		}
		//if there's at least one player on each team that's incorrect, swap them unless
		//there's only one survivor
		else if ((nICTeam[0] > 0) && (nICTeam[1] > 0) && (nSurvivors != 1))
		{
			//start looking from after current index, since we've fixed earlier ones
			for (j = i; j <= MaxClients; j++)
				//map -2 -> -3 and -3 -> -2 to see if they're on opposite teams and incorrect
				if (clStatus[i] == (-clStatus[j] - 5))
				{
#if DEBUG
					debugNames("I/I", i, j);
#endif
					swap(i, j);
					
					//update counts/statuses
					nIncorrect -= 2;
					nCorrect += 2;
					nICTeam[0]--; 
					nICTeam[1]--;
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
			for (j = 0; j <= MaxClients; j++)
				//map -2 -> 3 and -3 -> 2 to see if they're on opposite team but non-incorrect
				if ((clStatus[i] + 5) == clStatus[j])
				{
#if DEBUG
					debugNames("I/X", i, j);
#endif

					//if there's only one survivor we can't just use the generic swap, since it
					//doesn't care if a team gets emptied
					if (nSurvivors != 1) swap(i, j);
					else
					{
						//if we're here, infected is full, there's only one survivor, and we want
						//to swap the one survivor so we have to move the infected straight over first
						//this is ugly since it's swap() C&P'd with some lines reordered to move the inf
						//to surv before moving the surv over since we know there's space
						new inf, surv, bot;
						if (GetClientTeam(i) == 3)
						{
							inf = i;
							surv = j;
						}
						else
						{
							inf = j;
							surv = i;
						}

						ChangeClientTeam(inf, 1);

						bot = 1;
						while !(IsClientConnected(bot) && IsFakeClient(bot) && (GetClientTeam(bot) == 2)) do bot++;

						//have to do this to give control of a survivor bot
						//setHumanSpec(bot, inf);
						//controlBot(inf, true);
						SDKCall(fSHS, bot, inf);
						SDKCall(fTOB, inf, true);

						//don't think this'll ever happen, but whatever
						if (IsClientConnected(bot) && (GetClientTeam(bot) == 1)) KickClient(bot, "kicking unneeded bot.  Do not be alarmed.");

						ChangeClientTeam(surv, 3);
					}
					nIncorrect--; 
					nICTeam[-clStatus[i] - 2]--;
					nCorrect++;
					clStatus[i] = 1;
					clStatus[j] = -clStatus[j] + 5; //swapped his team but he's not correct
					break;
				}
		}
	}	

#if DEBUG
	LogToFileEx(logPath, "Pass done: nIC = %d, nC = %d, nIC[0] = %d, nIC[1] = %d", nIncorrect, nCorrect, nICTeam[0], nICTeam[1]);
#endif

	//so now, everyone connected and authed is correct
	//if all players from the last map are accounted for, we're done
	//blank out the stored teams and stop the timers if so
	if (nCorrect == (nTeam[0] + nTeam[1]))
	{	
#if DEBUG
		LogToFileEx(logPath, "Fixed teams, stopping stopwait");
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

	if (storing)
	{
		storing = 0;
		UnhookEvent("round_end", eventRoundEnd);
	}

	//on non versus maps do nothing, on map 1 don't try to fix teams, on map 5 don't store teams
	if (StrContains(curMap, "_vs_", false) != -1)
	{
		if (StrContains(curMap, "05_") == -1) 
		{
			storing = 1;
			HookEvent("round_end", eventRoundEnd);
		}

		if (StrContains(curMap, "01_") == -1)
		{
			uCount = 0;
			timerUnscramble = CreateTimer(1.0, unscramble, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			timerWait = CreateTimer(GetConVarFloat(cvarWait), stopWait, false, TIMER_FLAG_NO_MAPCHANGE);
		}
	} 
}

#if DEBUG
public OnMapEnd()
{
	new i, j;
	for (i = 0; i < 2; i++)
		for (j = 0; j < nTeam[i]; j++)
			LogToFileEx(logPath, "teams[%d][%d] = %s", i, j, teams[i][j]);
}
#endif

public Action:eventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (storing) storeTeams();
	return Plugin_Continue;
}

//put everyone's SteamIDs into the array
//index 0 is team 2, index 1 is team 3
storeTeams()
{
	new i, team, String:auth[SIDSIZE];
#if DEBUG
	new String:name[MAX_NAME_LENGTH];
#endif
	nTeam[0] = 0; nTeam[1] = 0;
	
	for (i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			team = GetClientTeam(i);

			if ((team != 2) && (team != 3)) continue;

			if (nTeam[team - 2] > 3) 
			{
#if DEBUG
				LogToFileEx(logPath, "PRINTER IS ON FIRE");
#endif
				continue;
			}

#if DEBUG
			GetClientName(i, name, sizeof(name));
			LogToFileEx(logPath, "Found %s on team %d, team - 2 = %d, nT[team - 2] = %d", name, team, team - 2, nTeam[team - 2]);
#endif
			GetClientAuthString(i, auth, sizeof(auth));
			strcopy(teams[team - 2][nTeam[team - 2]], SIDSIZE, auth);
			nTeam[team - 2]++;
		}
#if DEBUG
	LogToFileEx(logPath, "Stored %d, %d", nTeam[0], nTeam[1]);
#endif
}

public OnPluginStart()
{
#if DEBUG
	BuildPath(Path_SM, logPath, sizeof(logPath), "logs/l4dunscramber.log");
#endif

	gConf = LoadGameConfigFile("l4dunscrambler");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();

	cvarWait = CreateConVar("l4du_wait", "15", "Wait this many seconds after a map starts before giving up on fixing teams");
	cvarHoldOn = CreateConVar("l4du_holdon", "15", "If there's a connecting player when we decide to stop waiting, hold on for this many more seconds");
	CreateConVar("l4du_version", VERSION, "L4D Unscrambler version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4du");
}
