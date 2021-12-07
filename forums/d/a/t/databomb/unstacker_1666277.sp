/*
 *		[NuclearDawn] Team Balancer
 *		original compile date: 10 March 2012
 *		by databomb
 *		
 *		This plugin overrides the in-game team balancer
 *		and provides a new balancer which looks at the 
 *		rank of each player and makes sure the teams are
 *		both even in number and skill.
 *
 */

#include <sourcemod>
#include <sdktools>

#define VERSION			"1.0.7"
#define MAX_RANK		80
#define TEAM_EMPIRE		3
#define TEAM_CONSORT	2
#define TEAM_SPEC		1

public Plugin:myinfo =
{
        name = "[ND] Team Balancer",
        author = "databomb",
        description = "Provides even teams by analyzing player ranks.",
        version = VERSION,
        url = "vintagejailbreak.org"
};

// Global variables
new g_iPlayerManager = -1;
new g_iRankOffset = -1;
new bool:g_bWarmupExpired = false;
new bool:g_bFiveMinExpired = false;
new g_iScoreOffset = -1;
new g_iNumberOfSwaps[MAXPLAYERS+1];
new g_iTimestampThisMap[MAXPLAYERS+1];
new Handle:g_pAutoBalanceCvar = INVALID_HANDLE;
new MAX_SKILL;

new g_entBunkerConsort = INVALID_ENT_REFERENCE;
new g_entBunkerEmpire = INVALID_ENT_REFERENCE;

new Handle:gH_Cvar_SoundName = INVALID_HANDLE;
new String:gShadow_Cvar_SoundName[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	g_iRankOffset = FindSendPropInfo("CNDPlayerResource", "m_iPlayerRank");
	if (g_iRankOffset == -1)
	{
		SetFailState("Unable to find player rank offset. Are you running Nuclear Dawn?");
	}
	g_iScoreOffset = FindSendPropInfo("CNDPlayerResource", "m_iScore");
	if (g_iScoreOffset == -1)
	{
		SetFailState("Unable to find score offset. Are you running Nuclear Dawn?");
	}
	g_pAutoBalanceCvar = FindConVar("mp_autoteambalance");
	MAX_SKILL = FindMaxSkill();
	
	CreateConVar("nd_team_balancer_version", VERSION, "Team Balancer Version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gH_Cvar_SoundName = CreateConVar("nd_balance_denyfile", "buttons/button7.wav", "The name of the sound to play when an action is denied",FCVAR_PLUGIN);
	strcopy(gShadow_Cvar_SoundName, PLATFORM_MAX_PATH, "buttons/button7.wav");
	
	LoadTranslations("common.phrases");
	
	AddCommandListener(ChangeTeamListen, "jointeam");
	
	HookEvent("player_team", Player_Team);
	
	RegConsoleCmd("sm_stacked", Command_Stacked, "Returns the skill level of each team.");
	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_SLAY, "Swaps the team of targeted player.");
	RegAdminCmd("sm_spec", Command_Spec, ADMFLAG_SLAY, "Swaps the targeted player to spectator team.");
	RegAdminCmd("sm_unstack", Command_Unstack, ADMFLAG_SLAY, "Manually forces unstacking.");
	
	g_bFiveMinExpired = false;
	g_bWarmupExpired = false;
}

public Player_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	if (team > 1)
	{
		g_iTimestampThisMap[client] = GetTime();
	}
	
}

public OnClientPostAdminCheck(client)
{
	if (g_bWarmupExpired)
	{
		CreateTimer(5.0, Timer_SendMessage, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_SendMessage(Handle:Timer, any:client)
{
	if (client && IsClientInGame(client))
	{
		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.4, 20.0, 255, 160, 0, 255);
		new CSkill, ESkill;
		FindTeamTotalSkill(CSkill, ESkill);
		new difference = CSkill - ESkill;
		if (difference >= 0)
		{
			ShowSyncHudText(client, hHudText, "Joining Empire Will Help Balance Teams");
		}
		else
		{
			ShowSyncHudText(client, hHudText, "Joining Consortium Will Help Balance Teams");
		}
		CloseHandle(hHudText);
	}
}

public OnClientConnected(client)
{
	g_iNumberOfSwaps[client] = 0;
}

public Action:ChangeTeamListen(client, const String:command[], argc)
{
	/*
	decl String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new Target_Team = StringToInt(teamString);
	new Current_Team = GetClientTeam(client);
	
	if (Current_Team == Target_Team)
	{
		return Plugin_Continue;
	}
	*/
	
	// check if user has been balanced this round
	if (g_iNumberOfSwaps[client])
	{
		PrintToChat(client, "The server is restricting your switch due to stacking.");
		
		if(strcmp(gShadow_Cvar_SoundName, ""))
		{
			decl String:buffer[PLATFORM_MAX_PATH + 5];
			Format(buffer, sizeof(buffer), "play %s", gShadow_Cvar_SoundName);
			ClientCommand(client, buffer);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Timer_FirstFive(Handle:Timer)
{
	g_bFiveMinExpired = true;
	return Plugin_Stop;
}

public Action:Command_Swap(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_swap [player name]");
		return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	new target = FindTarget(client, targetArg);
	if (target != -1)
	{
		if (GetClientTeam(target) > TEAM_SPEC)
		{
			PerformSwap(target);
			LogAction(client, target, "\"%L\" swapped \"%L\"", client, target);
		}
		else
		{
			ReplyToCommand(client, "Target is not on a playable team.");
		}
	}
	else
	{
		ReplyToCommand(client, "Unable to locate target.");
	}

	return Plugin_Handled;
}

public Action:Command_Unstack(client, args)
{
	new Consortium, Empire;
	FindTeamTotalSkill(Consortium, Empire);
	
	if (TeamsAreStacked(Consortium, Empire))
	{
		ReplyToCommand(client, "Balancing teams...");
		new StackedTeam = (Consortium > Empire) ? TEAM_CONSORT : TEAM_EMPIRE;
		UnstackTeams(StackedTeam);
	}
	else
	{
		ReplyToCommand(client, "Teams were not stacked.");
	}
	return Plugin_Handled;
}

public Action:Command_Spec(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "Usage: sm_spec [player name]");
		return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg(1, targetArg, sizeof(targetArg));
	
	new target = FindTarget(client, targetArg);
	if (target != -1)
	{
		if (GetClientTeam(target) > TEAM_SPEC)
		{
			ChangeClientTeam(target, TEAM_SPEC);
			LogAction(client, target, "\"%L\" switched \"%L\" to spectator", client, target);
		}
		else
		{
			ReplyToCommand(client, "Target is not on a playable team.");
		}
	}
	else
	{
		ReplyToCommand(client, "Unable to locate target.");
	}

	return Plugin_Handled;
}

PerformSwap(client)
{
	new CurrentTeam = GetClientTeam(client);
	
	new TargetTeam = (CurrentTeam == TEAM_CONSORT ? TEAM_EMPIRE : TEAM_CONSORT);
	
	// First change to spectator team to avoid loss of stats points
	ChangeClientTeam(client, TEAM_SPEC);
	
	ChangeClientTeam(client, TargetTeam);
	g_iNumberOfSwaps[client]++;
	
	// Provide some visual feedback
	if (TargetTeam == TEAM_CONSORT)
	{
		ScreenFade(client, 2000, 2000, 0x0001, 0, 20, 170, 200);
	}
	else
	{
		ScreenFade(client, 2000, 2000, 0x0001, 170, 20, 0, 200);
	}
	
	// Bring up the menu to spawn
	CreateTimer(1.0, Timer_DisplayTeamMenu, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DisplayTeamMenu(Handle:pTimer, any:client)
{
	if (IsClientInGame(client))
	{
		ShowTeamMenu(client);
	}
	return Plugin_Handled;
}

public Action:Command_Stacked(client, args)
{
	new CSkill, ESkill;
	FindTeamTotalSkill(CSkill, ESkill);
	ReplyToCommand(client, "Consortium has %d total skill and the Empire has %d total skill", CSkill, ESkill);
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx))
		{
			PrintToConsole(client, "%N has %d rank with %d swaps and %d minutes", idx, GetPlayerRank(idx), g_iNumberOfSwaps[idx], MinutesSpentOnMap(idx));
		}
	}
	return Plugin_Handled;
}

public OnMapStart()
{
	g_iPlayerManager = FindEntityByClassname(-1, "nd_player_manager");
	if (g_iPlayerManager == -1)
	{
		SetFailState("Unable to find the nd_player_manager entity. Are you running Nuclear Dawn?");
	}
	
	// Clear swap information
	for (new client = 1; client <= MaxClients; client++)
	{
		g_iNumberOfSwaps[client] = 0;
		g_iTimestampThisMap[client] = GetTime();
	}
	
	CreateTimer(30.0, Timer_CheckTeams, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_bWarmupExpired = false;
	g_bFiveMinExpired = false;
	CreateTimer(80.0, Timer_WarmupExpired, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(300.0, Timer_FirstFive, _, TIMER_FLAG_NO_MAPCHANGE);
	
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "struct_command_bunker")) != INVALID_ENT_REFERENCE)
	{
		new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		if (team == TEAM_EMPIRE)
		{
			g_entBunkerEmpire = EntIndexToEntRef(entity);
		}
		else if (team == TEAM_CONSORT)
		{
			g_entBunkerConsort = EntIndexToEntRef(entity);
		}
	}
	
	// pre-cache deny sound
	if(strcmp(gShadow_Cvar_SoundName, ""))
	{
		decl String:sBuffer[PLATFORM_MAX_PATH];
		PrecacheSound(gShadow_Cvar_SoundName, true);
		Format(sBuffer, sizeof(sBuffer), "sound/%s", gShadow_Cvar_SoundName);
		AddFileToDownloadsTable(sBuffer);
	}
}

public Action:Timer_WarmupExpired(Handle:pTimer)
{
	g_bWarmupExpired = true;
	return Plugin_Stop;
}

public Action:Timer_TellPlayer(Handle:timer, any:player)
{
	if (IsClientInGame(player) && g_bWarmupExpired)
	{
		LogMessage("displaying message to %N player", player);
		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 5.0, 255, 160, 0, 255);
		new CSkill, ESkill;
		FindTeamTotalSkill(CSkill, ESkill);
		new difference = CSkill - ESkill;
		if (difference >= 0)
		{
			ShowSyncHudText(player, hHudText, "Joining Empire Will Help Balance Teams");
		}
		else
		{
			ShowSyncHudText(player, hHudText, "Joining Consortium Will Help Balance Teams");
		}
		
		CloseHandle(hHudText);
	}
}

public Action:Timer_ForceBalance(Handle:pTimer)
{
	new Consortium, Empire;
	FindTeamTotalSkill(Consortium, Empire);
	if (TeamsAreStacked(Consortium, Empire))
	{
		new StackedTeam = (Consortium > Empire) ? TEAM_CONSORT : TEAM_EMPIRE;
		UnstackTeams(StackedTeam);
		
		// create loop
		CreateTimer(2.0, Timer_ForceBalance, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action:Timer_CheckTeams(Handle:pTimer)
{
	if (!g_bWarmupExpired)
	{
		return Plugin_Continue;
	}

	static CyclesStacked = 0;
	static SpotlightPlayer = 0;
	
	new Consortium, Empire;
	FindTeamTotalSkill(Consortium, Empire);
	
	// check for low bunker HP
	if (AreBunkersLowHealth())
	{
		PrintToChatAll("/x04Low Bunker Health - Team Balancing Suspended");
	}
	else if (!g_bFiveMinExpired && TeamsAreStacked(Consortium, Empire, true))
	{
		new StackedTeam = (Consortium > Empire) ? TEAM_CONSORT : TEAM_EMPIRE;
		UnstackTeams(StackedTeam);
		
		// create loop
		CreateTimer(2.0, Timer_ForceBalance, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (TeamsAreStacked(Consortium, Empire))
	{
		CyclesStacked++;
		new StackedTeam = (Consortium > Empire) ? TEAM_CONSORT : TEAM_EMPIRE;
		if (CyclesStacked > 10)
		{
			UnstackTeams(StackedTeam, SpotlightPlayer);
			CyclesStacked = 0;
			return Plugin_Continue;
		}
		else if (CyclesStacked > 9)
		{
			SpotlightPlayer = FindSkilledNewcomer(StackedTeam);
			PrintToChatAll("Teams are stacked, %N (%d) is in the spotlight..", SpotlightPlayer, GetPlayerRank(SpotlightPlayer));
			ScreenFade(SpotlightPlayer, 700, 700, 0x0001, 200, 130, 10, 200);
		}
		
		if ((CyclesStacked+1)%2)
		{
			decl String:teamname[25];
			if (StackedTeam == TEAM_CONSORT)
			{
				Format(teamname, sizeof(teamname), "Consortium");
			}
			else
			{
				Format(teamname, sizeof(teamname), "Empire");
			}
			new difference = Consortium - Empire;
			if (difference < 0)
			{
				difference *= -1;
			}
			
			new minutes = (10-CyclesStacked)/2;
			if (minutes > 1)
			{
				PrintToChatAll("%s has a skill advantage of %d. Balancing will occur in %d minutes.", teamname, difference, minutes);
			}
			else if (minutes == 1)
			{
				PrintToChatAll("%s has a skill advantage of %d. Balancing will occur in %d minute.", teamname, difference, minutes);
			}
		}
	}
	else if (TeamsAreUnbalanced())
	{
		BalanceTeams();
	}
	else
	{
		if (CyclesStacked > 1)
		{
			PrintToChatAll("Congratulations.. Teams are balanced again.");
			CyclesStacked = 0;
		}
	}
	
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	// Make sure the in-game balancer is disabled
	SetConVarInt(g_pAutoBalanceCvar, 0);
	GetConVarString(gH_Cvar_SoundName, gShadow_Cvar_SoundName, sizeof(gShadow_Cvar_SoundName));
}

BalanceTeams()
{
	new ConsortPlayers = GetTeamClientCount(TEAM_CONSORT);
	new EmpirePlayers = GetTeamClientCount(TEAM_EMPIRE);
	
	new LargeTeam = (ConsortPlayers > EmpirePlayers ? TEAM_CONSORT : TEAM_EMPIRE);
	
	new Swapee = FindNewestPlayer(LargeTeam);
	
	PrintToChatAll("Swapping %N due to team player unbalance.", Swapee);
	
	PerformSwap(Swapee);
}

UnstackTeams(StackedTeam, SpotlightPlayer = 0)
{
	new UnstackedTeam = (StackedTeam == TEAM_CONSORT) ? TEAM_EMPIRE : TEAM_CONSORT;
	new StackedPlayer = FindSkilledNewcomer(StackedTeam);
	
	if (SpotlightPlayer != 0)
	{
		StackedPlayer = SpotlightPlayer;
	}
	
	// Check if we should swap bi-directionally or not
	new ConsortiumPlayers = GetTeamClientCount(TEAM_CONSORT);
	new EmpirePlayers = GetTeamClientCount(TEAM_EMPIRE);
	if (ConsortiumPlayers != EmpirePlayers)
	{
		// Swap one way
		PrintToChatAll("Swapping %N due to team stack", StackedPlayer);
	}
	else
	{
		// Swap both ways
		new NewestPlayer = FindNewbiePlayer(UnstackedTeam);
		
		PrintToChatAll("Swapping %N with %N due to team stack", StackedPlayer, NewestPlayer);
		
		PerformSwap(NewestPlayer);
	}
	
	PerformSwap(StackedPlayer);
}

// Find the player with the shortest connection time
stock FindNewestPlayer(Team)
{
	new Float:ShortestTime = 987650000.0;
	new Swapee = -1;
	new Commander = (Team == TEAM_CONSORT) ? GameRules_GetPropEnt("m_hCommanders", 0) : GameRules_GetPropEnt("m_hCommanders", 1);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == Team)
			{
				if (client != Commander)
				{
					decl Float:TimePlayed;

					if (IsFakeClient(client))
					{
						TimePlayed = 0.0;
					}
					else
					{
						TimePlayed = GetClientTime(client);
					}

					if (FloatCompare(ShortestTime, TimePlayed) == 1)
					{
						ShortestTime = TimePlayed;
						Swapee = client;
					}
				}
			}
		}
	}
	return Swapee;
}

// Looks at the scoreboard to find the best newbie player on the unstacked team to swap over
stock FindNewbiePlayer(Team)
{
	new WorstScore = 987654321;
	new Swapee = -1;
	new Commander = (Team == TEAM_CONSORT) ? GameRules_GetPropEnt("m_hCommanders", 0) : GameRules_GetPropEnt("m_hCommanders", 1);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == Team)
			{
				if (client != Commander)
				{
					new PlayerScore = GetPlayerScore(client) + 500*g_iNumberOfSwaps[client];

					if (PlayerScore < WorstScore)
					{
						WorstScore = PlayerScore;
						Swapee = client;
					}
				}
			}
		}
	}
	return Swapee;
}

// three variables, skill, time, and previous swaps
stock FindSkilledNewcomer(Team)
{
	new BestRank = -999999;
	new Swapee = -1;
	
	new Commander = (Team == TEAM_CONSORT) ? GameRules_GetPropEnt("m_hCommanders", 0) : GameRules_GetPropEnt("m_hCommanders", 1);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			//PrintToConsole(client, "%N has %d rank with %d swaps and %d minutes and squad status is %d", client, GetPlayerRank(client), g_iNumberOfSwaps[client], MinutesSpentOnMap(client), IsClientInSquad(client));
			
			if (GetClientTeam(client) == Team)
			{
				if (client != Commander)
				{
					// Make the algorithm less likely to keep picking the same players for evening the teams
					new PlayerRank = GetPlayerRank(client) - 80*g_iNumberOfSwaps[client] - 2*MinutesSpentOnMap(client) - 40*IsClientInSquad(client);
					if (PlayerRank > BestRank)
					{
						BestRank = PlayerRank;
						Swapee = client;
					}
				}
			}
		}
	}
	return Swapee;
}

// Finds the highest ranked player on a team who is not commanding
stock FindSkilledStacker(Team)
{
	new BestRank = -4;
	new Swapee = -1;
	
	new Commander = (Team == TEAM_CONSORT) ? GameRules_GetPropEnt("m_hCommanders", 0) : GameRules_GetPropEnt("m_hCommanders", 1);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == Team)
			{
				if (client != Commander)
				{
					// Make the algorithm less likely to keep picking the same players for evening the teams
					new PlayerRank = GetPlayerRank(client) - 80*g_iNumberOfSwaps[client];
					if (PlayerRank > BestRank)
					{
						BestRank = PlayerRank;
						Swapee = client;
					}
				}
			}
		}
	}
	return Swapee;
}

FindTeamTotalSkill(&Consortium, &Empire)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			switch (GetClientTeam(client))
			{
				case TEAM_CONSORT:
				{
					Consortium += GetPlayerSkill(client);
				}
				case TEAM_EMPIRE:
				{
					Empire += GetPlayerSkill(client);
				}
				default:
				{
					// Spectator, un-assigned fall here
				}
			}
		}
	}
}

stock bool:TeamsAreUnbalanced()
{
	new ConsortPlayers = GetTeamClientCount(TEAM_CONSORT);
	new EmpirePlayers = GetTeamClientCount(TEAM_EMPIRE);
	
	new difference = ConsortPlayers - EmpirePlayers;
	if (difference < 0)
	{
		difference *= -1;
	}
	
	if (difference > 2)
	{
		return true;
	}
	
	return false;
}

stock bool:TeamsAreStacked(Consortium, Empire, bool:MapStart=false)
{
	new difference = Consortium - Empire;
	// Integer abs
	if (difference < 0)
	{
		difference *= -1;
	}
	
	// Make +1 an adjustable cvar
	if (MapStart)
	{
		if (difference > MAX_SKILL+1)
		{
			return true;
		}
	}
	else
	{
		if (difference > MAX_SKILL*1.67)
		{
			return true;
		}
	}
	return false;
}

stock FindMaxSkill()
{
	return RankToSkill(MAX_RANK);
}

// Provide simple algorithm to make a rank 60 and a rank 1 equivalent to 2 rank 15s instead of rank 30s
stock RankToSkill(rank)
{
	// Avoid errors with bots at 0 rank
	rank++;
	// Could make either the 200 factor or the root (squared, cubed, etc.) an adjustable cvar
	rank *= 200;
	// the +60 offset is to account for number of players
	return RoundToFloor(SquareRoot(float(rank)))+60;
}

stock GetPlayerSkill(client)
{
	if (IsFakeClient(client))
	{
		return -50;
	}
	else
	{
		return RankToSkill(GetPlayerRank(client));
	}
}

stock GetPlayerRank(client)
{
	return GetEntData(g_iPlayerManager, g_iRankOffset + 4*client);
}

stock GetPlayerScore(client)
{
	return GetEntData(g_iPlayerManager, g_iScoreOffset + 4*client);
}

// Shamelessly stolen from BAILOPAN
stock ScreenFade(client, duration, time, flags, r, g, b, a)
{
        new clients[1];
        new Handle:bf;
        clients[0] = client;

        bf = StartMessage("Fade", clients, 1);
        BfWriteShort(bf, duration);
        BfWriteShort(bf, time);
        BfWriteShort(bf, flags);
        BfWriteByte(bf, r);
        BfWriteByte(bf, g);
        BfWriteByte(bf, b);
        BfWriteByte(bf, a);
        EndMessage();
}

stock IsClientInSquad(client)
{
	new i_Squad = GetEntProp(client, Prop_Send, "m_iSquad");
	
	if (i_Squad == -1)
	{
		return 0;
	}
	return 1;
}

// My own creation borrowed from the Jailbreak team balancer
stock ShowTeamMenu(client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	
	bf = StartMessage("VGUIMenu", clients, 1);
	BfWriteString(bf, "team"); // panel name
	BfWriteByte(bf, 1); // bShow
	BfWriteByte(bf, 0); // count
	EndMessage();
}

stock MinutesSpentOnMap(client)
{
	return ((GetTime()-g_iTimestampThisMap[client])/60);
}

stock bool:AreBunkersLowHealth()
{
	if (!IsValidEntity(EntRefToEntIndex(g_entBunkerConsort)) || !IsValidEntity(EntRefToEntIndex(g_entBunkerEmpire)))
	{
		return false;
	}
	
	new Consort_HP = GetEntProp(EntRefToEntIndex(g_entBunkerConsort), Prop_Send, "m_iHealth");
	new Empire_HP = GetEntProp(EntRefToEntIndex(g_entBunkerEmpire), Prop_Send, "m_iHealth");
	
	if (Empire_HP < 10000 || Consort_HP < 10000)
	{
		return true;
	}
	return false;
}
