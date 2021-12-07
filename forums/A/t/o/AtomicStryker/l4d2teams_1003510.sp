#include <sourcemod>
#include <sdktools>

#define SCORE_VERSION "0.0.1"

#define SCORE_DEBUG 0
#define SCORE_DEBUG_LOG 0

#define SCORE_DELAY_PLACEMENT 0.1
#define SCORE_DELAY_TEAM_SWITCH 0.1
#define SCORE_SWAPMENU_PANEL_LIFETIME 10
#define SCORE_SWAPMENU_PANEL_REFRESH 0.5

#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)
#define L4D_TEAM_SURVIVORS 2
#define L4D_TEAM_INFECTED 3
#define L4D_TEAM_SPECTATE 1
#define L4D_TEAM_MAX_CLIENTS 4

#define L4D_TEAM_NAME(%1) (%1 == 2 ? "Survivors" : (%1 == 3 ? "Infected" : (%1 == 1 ? "Spectators" : "Unknown")))


forward OnReadyRoundRestarted();

public Plugin:myinfo = 
{
	name = "L4D2 Team Manager",
	author = "Downtown1",
	description = "Manage teams in L4D2",
	version = SCORE_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=87759"
}

new Handle:gConf = INVALID_HANDLE;

new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

/* Team Placement */
new Handle:teamPlacementTrie = INVALID_HANDLE; //remember what teams to place after map change
new teamPlacementArray[256];  //after client connects, try to place him to this team
new teamPlacementAttempts[256]; //how many times we attempt and fail to place a person


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	PrepareAllSDKCalls();

	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_BAN, "sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams");
	RegAdminCmd("sm_swapto", Command_SwapTo, ADMFLAG_BAN, "sm_swapto <player1> [player2] ... [playerN] <teamnum> - swap all listed players to <teamnum> (1,2, or 3)");
	RegAdminCmd("sm_swapteams", Command_SwapTeams, ADMFLAG_BAN, "sm_swapteams - swap the players between both teams");
	
	RegAdminCmd("sm_scrambleteams", Command_ScrambleTeams, ADMFLAG_BAN, "sm_scrambleteams - swap the players randomly between both teams");
	RegConsoleCmd("sm_votescramble", Request_ScrambleTeams, "Allows Clients to call Scramble votes");
	
	RegAdminCmd("sm_swapmenu", Command_SwapMenu, ADMFLAG_BAN, "sm_swapmenu - bring up a swap players menu");
	
	CreateConVar("l4d2_team_manager_ver", SCORE_VERSION, "Version of the team manager plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	/*
	 * ADT Handles
	 */
	teamPlacementTrie = CreateTrie();
	if(teamPlacementTrie == INVALID_HANDLE)
	{
		LogError("Could not create the team placement trie! FATAL ERROR");
	}
	
	HookEvent("player_team", Event_PlayerTeam);
}

PrepareAllSDKCalls()
{
	gConf = LoadGameConfigFile("l4dswitchplayers");
	
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

public Action:Command_ScrambleTeams(client, args)
{
	PrintToChatAll("[SM] Teams are being scrambled.");
	ScrambleTeams();
	
	return Plugin_Handled;
}

new bool:VoteWasDone;

public Action:Request_ScrambleTeams(client, args)
{
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

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	TryTeamPlacementDelayed();
}

ScrambleTeams()
{
	new humanspots = GetTeamMaxHumans(L4D_TEAM_SURVIVORS);
	new infspots = GetTeamMaxHumans(L4D_TEAM_INFECTED);
	decl luck;
	
	for(new i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
	{
		if(IsClientInGameHuman(i) && GetClientTeam(i) != L4D_TEAM_SPECTATE)
		{
			luck = GetRandomInt(2,3);
			
			if (luck == 2)
			{
				if (humanspots < 1) teamPlacementArray[i] = 3;
				else
				{
					teamPlacementArray[i] = 2;
					humanspots--;
				}
			}
			else
			{
				if (infspots < 1) teamPlacementArray[i] = 2;
				else
				{
					teamPlacementArray[i] = 3;
					infspots--;
				}
			}
		}
	}
	
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

/*
* ****************
* STOCK FUNCTIONS
* ****************
*/

stock ClearTeamPlacement()
{
	new i;
	for(i = 1; i < L4D_MAXCLIENTS_PLUS1; i++) 
	{
		teamPlacementArray[i] = 0;
		teamPlacementAttempts[i] = 0;
	}
	
	ClearTrie(teamPlacementTrie);
}

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

/*
* SWAP MENU FUNCTIONALITY
*/

new swapClients[256];
public Action:Command_SwapMenu(client, args)
{
	//new Handle:panel = CreatePanel();
	decl String:panelLine[1024];
	decl String:itemValue[32];
	
	//new i, numPlayers = 0;
	//->%d. %s makes the text yellow
	// otherwise the text is white
	
	new teamIdx[] = {2, 3, 1};
	new String:teamNames[][] = {"SURVIVORS","INFECTED","SPECTATORS"};
	
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