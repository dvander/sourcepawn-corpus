#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "ND Voting"
#define PLUGIN_VERSION "1.3"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Player 1 (Xander)",
	description = "A more reliable voting system than Nuclear Dawn's surrender and mutiny functions.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1794356"
};

#define VOTETYPE_SURRENDER 1
#define VOTETYPE_MUTINY 2

#define VOTE_INFO_TEAM 0
#define VOTE_INFO_TYPE 1
#define VOTE_INFO_NUMCLIENTS 2

new g_iCurrentVoteInfo[3],
	g_iCommanders[2] = {-1, -1},
	bool:g_bSimpleMajority,
	Handle:g_hVoteHandle = INVALID_HANDLE,
	Handle:g_hCvar_SimpleMajority = INVALID_HANDLE,
	
	//surrender globals
	g_iSurrenderVoteMinPlayers,
	bool:g_bSurrenderVoteAllowed[2],
	bool:g_bSurrenderVoteCommandersOnly,
	Float:g_fSurrenderVoteTimer,
	Float:g_fSurrenderThreshold,
	Handle:g_hCvar_SurrenderVoteTimer = INVALID_HANDLE,
	Handle:g_hCvar_SurrenderVoteCommandersOnly = INVALID_HANDLE,
	Handle:g_hCvar_SurrenderVoteMinPlayers = INVALID_HANDLE,
	Handle:g_hCvar_SurrenderThreshold = INVALID_HANDLE,
	
	//mutiny globals
	Float:g_fMutinyVoteTimer,
	Float:g_fMutinyThreshold,
	g_iMutinyVoteMinPlayers,
	bool:g_bMutinyVoteAllowed[2],
	Handle:g_hCvar_MutinyVoteTimer = INVALID_HANDLE,
	Handle:g_hCvar_MutinyMinPlayers = INVALID_HANDLE,
	Handle:g_hCvar_MutinyThreshold = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("ndvotes.phrases");
	
	CreateConVar("sm_nd_surrender_vote_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("surrendervote", Command_SurrenderVote);
	RegConsoleCmd("surrender", Command_SurrenderVote);
	RegConsoleCmd("startmutiny", Command_StartMutiny);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_win", Event_RoundWin, EventHookMode_Pre);
	HookEvent("promoted_to_commander", Event_CommanderPromoted);
	HookEvent("player_team", Event_ChangeTeam);
	
	//Surrender Cvars
	g_hCvar_SurrenderVoteTimer = CreateConVar("nd_commander_surrender_surpress_time", "1", "Time in minutes that must pass before a team may start a new surrender vote.", FCVAR_NONE);
	g_hCvar_SurrenderVoteCommandersOnly = CreateConVar("nd_commanders_only_surrender_vote", "1", "(0 | 1) - Only commanders can start surrender votes?", FCVAR_NONE);
	g_hCvar_SurrenderVoteMinPlayers = CreateConVar("nd_commander_surrender_min_players", "2", "Number of real players on a team required to start a surrender vote.", FCVAR_NONE, true, 0.0);
	g_hCvar_SurrenderThreshold = FindConVar("nd_commander_surrender_vote_threshold");
	
	SetConVarBounds(g_hCvar_SurrenderThreshold, ConVarBound_Upper, true, 100.0);
	SetConVarBounds(g_hCvar_SurrenderThreshold, ConVarBound_Lower, true, 50.0);
	
	g_fSurrenderVoteTimer = GetConVarFloat(g_hCvar_SurrenderVoteTimer) * 60;
	g_bSurrenderVoteCommandersOnly = GetConVarBool(g_hCvar_SurrenderVoteCommandersOnly);
	g_iSurrenderVoteMinPlayers = GetConVarInt(g_hCvar_SurrenderVoteMinPlayers);
	g_fSurrenderThreshold = GetConVarFloat(g_hCvar_SurrenderThreshold) / 100;
	
	
	//Mutiny Cvars
	g_hCvar_MutinyVoteTimer = FindConVar("nd_commander_mutiny_surpress_time");
	g_hCvar_MutinyMinPlayers = FindConVar("nd_commander_mutiny_min_players");
	g_hCvar_MutinyThreshold = FindConVar("nd_commander_mutiny_vote_threshold");
	
	SetConVarBounds(g_hCvar_MutinyThreshold, ConVarBound_Upper, true, 100.0);
	SetConVarBounds(g_hCvar_MutinyThreshold, ConVarBound_Lower, true, 50.0);
	
	g_fMutinyVoteTimer = GetConVarFloat(g_hCvar_MutinyVoteTimer) * 60;
	g_iMutinyVoteMinPlayers = GetConVarInt(g_hCvar_MutinyMinPlayers);
	g_fMutinyThreshold = GetConVarFloat(g_hCvar_MutinyThreshold) / 100;
	
	
	g_hCvar_SimpleMajority = CreateConVar("nd_voting_simple_majority", "1",
"If 1, a simple majority is all that's needed to pass a surrender or mutiny vote, and no-votes and the threshold Cvars are ignored. If 0, the 'yes' votes / the number of players on the team must be greater than or equal to the above threshold, and no-votes are considered a vote for 'no'.");
	g_bSimpleMajority = GetConVarBool(g_hCvar_SimpleMajority);
	
	
	HookConVarChange(g_hCvar_SurrenderVoteTimer, RefreshConVars);
	HookConVarChange(g_hCvar_SurrenderVoteCommandersOnly, RefreshConVars);
	HookConVarChange(g_hCvar_SurrenderVoteMinPlayers, RefreshConVars);
	HookConVarChange(g_hCvar_SurrenderThreshold, RefreshConVars);
	
	HookConVarChange(g_hCvar_MutinyVoteTimer, RefreshConVars);
	HookConVarChange(g_hCvar_MutinyMinPlayers, RefreshConVars);
	HookConVarChange(g_hCvar_MutinyThreshold, RefreshConVars);
	
	HookConVarChange(g_hCvar_SimpleMajority, RefreshConVars);	
	
	g_bSurrenderVoteAllowed[0] = true;
	g_bSurrenderVoteAllowed[1] = true;
	
	g_bMutinyVoteAllowed[0] = true;
	g_bMutinyVoteAllowed[1] = true;
}

public Action:Command_SurrenderVote(client, args)
{
	if (!client)
		return Plugin_Handled;
	
	new iTeam = GetClientTeam(client);
	
	if (iTeam < 2)
	{}
	
	else if (g_bSurrenderVoteCommandersOnly && client != g_iCommanders[iTeam - 2])
		PrintToChat(client, "\x05[SM] %T", "Commander Only", LANG_SERVER);
	
	else if (IsVoteInProgress())
		PrintToChat(client, "\x05[SM] %T", "Vote In Progress", LANG_SERVER);
	
	else if (!g_bSurrenderVoteAllowed[iTeam - 2])
		PrintToChat(client, "\x05[SM] %T", "Not Enough Time", LANG_SERVER);	
	
	else if (GetNumPlayersOnTeam(iTeam) < g_iSurrenderVoteMinPlayers)
		PrintToChat(client, "\x05[SM] %T", "Too Few Players", LANG_SERVER, g_iSurrenderVoteMinPlayers);
	
	else
	{
		g_bSurrenderVoteAllowed[iTeam - 2] = false;
		
		CreateTimer(g_fSurrenderVoteTimer, EnableSurrenderVote, iTeam);
		
		VoteToTeam(iTeam, VOTETYPE_SURRENDER);
		
		PrintToChatTeam(iTeam, "\x05[SM] %T", "Start Surrender");
	}
	
	return Plugin_Handled;
}

public Action:Command_StartMutiny(client, args)
{
	if (!client)
		return Plugin_Handled;
	
	new iTeam = GetClientTeam(client);
	
	if (iTeam < 2)
	{}
	
	else if (client == g_iCommanders[iTeam - 2])
	{
		FakeClientCommand(g_iCommanders[iTeam - 2], "rtsview");
		
		g_iCommanders[iTeam - 2] = -1;
		
		if (g_hVoteHandle != INVALID_HANDLE && IsVoteInProgress() && g_iCurrentVoteInfo[VOTE_INFO_TEAM] == iTeam && g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_MUTINY)
			CancelVote();
		
		return Plugin_Continue;	//allow "startmutiny" to continue to its usual function because the commander was mutinied | resigned | demoted by admin.
	}
	
	else if (g_iCommanders[iTeam - 2] == -1)
	{}
	
	else if (IsVoteInProgress())
		PrintToChat(client, "\x05[SM] %T", "Vote In Progress", LANG_SERVER);
	
	else if (!g_bMutinyVoteAllowed[iTeam - 2])
		PrintToChat(client, "\x05[SM] %T", "Not Enough Time", LANG_SERVER);
	
	else if (GetNumPlayersOnTeam(iTeam) < g_iMutinyVoteMinPlayers)
	{}
	
	else
	{
		g_bMutinyVoteAllowed[iTeam - 2] = false;
		
		CreateTimer(g_fMutinyVoteTimer, EnableMutinyVote, iTeam);
		
		VoteToTeam(iTeam, VOTETYPE_MUTINY);
		
		PrintToChatTeam(iTeam, "\x05[SM] %T", "Start Mutiny");
	}
	
	return Plugin_Handled;
}

VoteToTeam(iTeam, VoteType)
{
	decl Players[MaxClients+1], String:buffer[32];
	new PlayersCount;
	
	g_hVoteHandle = CreateMenu(Handle_VoteMenu);
	SetMenuExitButton(g_hVoteHandle, false);
	
	switch (VoteType)
	{
		case VOTETYPE_SURRENDER:
		SetMenuTitle(g_hVoteHandle, "%T", "Surrender", LANG_SERVER);
		case VOTETYPE_MUTINY:
		SetMenuTitle(g_hVoteHandle, "%T", "Mutiny", LANG_SERVER);
	}		
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam && i != g_iCommanders[iTeam - 2])
		{
			Players[PlayersCount] = i;
			PlayersCount++
		}
	}
	
	Format(buffer, sizeof(buffer), "%T", "Yes", LANG_SERVER);
	AddMenuItem(g_hVoteHandle, "", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "No", LANG_SERVER);
	AddMenuItem(g_hVoteHandle, "", buffer);
	
	VoteMenu(g_hVoteHandle, Players, PlayersCount, 25);
	
	g_iCurrentVoteInfo[VOTE_INFO_TEAM] = iTeam;
	g_iCurrentVoteInfo[VOTE_INFO_TYPE] = VoteType;
	g_iCurrentVoteInfo[VOTE_INFO_NUMCLIENTS] = PlayersCount;
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{		
	if (action == MenuAction_VoteEnd)
	{		
		if (g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_SURRENDER)
		{
			if (param1 == 0)
			{
				if (g_bSimpleMajority)
				{
					FireSurrenderLoss(g_iCurrentVoteInfo[VOTE_INFO_TEAM])
					return;
				}
				
				new Votes, TotalVotes, Float:Percentage;
				GetMenuVoteInfo(param2, Votes, TotalVotes);
				
				Percentage =  float(Votes / g_iCurrentVoteInfo[VOTE_INFO_NUMCLIENTS]);
				
				if (Percentage >= g_fSurrenderThreshold)
				{
					FireSurrenderLoss(g_iCurrentVoteInfo[VOTE_INFO_TEAM])
					return;
				}
			}
			PrintToChatTeam(g_iCurrentVoteInfo[VOTE_INFO_TEAM], "\x05[SM] %T", "Surrender Failed");
		}
		
		else if (g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_MUTINY)
		{
			if (param1 == 0)
			{
				if (g_bSimpleMajority)
				{
					PrintToChatTeam(g_iCurrentVoteInfo[VOTE_INFO_TEAM], "\x05 [SM] %T", "Mutiny Succeded");
				
					FakeClientCommand(g_iCommanders[g_iCurrentVoteInfo[VOTE_INFO_TEAM] - 2], "startmutiny");
					
					return;
				}
				
				new Votes, TotalVotes, Float:Percentage;
				GetMenuVoteInfo(param2, Votes, TotalVotes);
				
				Percentage =  float(Votes / g_iCurrentVoteInfo[VOTE_INFO_NUMCLIENTS]);
				
				if (Percentage >= g_fMutinyThreshold)
				{
					PrintToChatTeam(g_iCurrentVoteInfo[VOTE_INFO_TEAM], "\x05 [SM] %T", "Mutiny Succeded");
				
					FakeClientCommand(g_iCommanders[g_iCurrentVoteInfo[VOTE_INFO_TEAM] - 2], "startmutiny");
					
					return;
				}
			}
			PrintToChatTeam(g_iCurrentVoteInfo[VOTE_INFO_TEAM], "\x05[SM] %T", "Mutiny Failed");
		}
	}
	
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		if (g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_SURRENDER)
			PrintToChatTeam(g_iCurrentVoteInfo[VOTE_INFO_TEAM], "\x05[SM] %T", "Surrender Failed");
		
		else if (g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_MUTINY)
			PrintToChatTeam(g_iCurrentVoteInfo[VOTE_INFO_TEAM], "\x05[SM] %T", "Mutiny Failed");
	}
	
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
		g_hVoteHandle = INVALID_HANDLE;
	}
}

FireSurrenderLoss(iTeam)
{
	new ent = FindEntityByClassname(-1, "nd_logic_custom"),
		Handle:event = CreateEvent("round_win");
	
	if (ent == -1)
	{
		ent = CreateEntityByName("nd_logic_custom");
		DispatchSpawn(ent);
	}
	
	SetEventInt(event, "type", 3);
	
	switch (iTeam)
	{
		case 2:
		SetEventInt(event, "team", 3);
		case 3:
		SetEventInt(event, "team", 2);
	}
	
	AcceptEntityInput(ent, "EndRoundAuto");
	FireEvent(event);	
}

PrintToChatTeam(iTeam, const String:Message[], const String:Translation[])
{
	for (new client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && GetClientTeam(client) == iTeam)
			PrintToChat(client, Message, Translation, LANG_SERVER);
}

GetNumPlayersOnTeam(iTeam)
{
	new count;
	
	for (new client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && GetClientTeam(client) == iTeam && !IsFakeClient(client))
			count++
	
	return count;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bSurrenderVoteAllowed[0] = true;
	g_bSurrenderVoteAllowed[1] = true;
	
	CreateTimer(g_fMutinyVoteTimer, EnableMutinyVote, -1);
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if round was ended by 'nd_logic_custom'
	if (GetEventInt(event, "type") == 5)
		return Plugin_Handled;
	
	g_bSurrenderVoteAllowed[0] = false;
	g_bSurrenderVoteAllowed[1] = false;
	
	g_bMutinyVoteAllowed[0] = false;
	g_bMutinyVoteAllowed[1] = false;
	
	//Handle will be closed and set invalid in Handle_VoteMenu - MenuAction_End
	if (g_hVoteHandle != INVALID_HANDLE && IsVoteInProgress())
		CancelVote();
	
	return Plugin_Continue;
}

public OnMapEnd()
{
	if (g_hVoteHandle != INVALID_HANDLE && IsVoteInProgress())
		CancelVote();
}


public Action:Event_CommanderPromoted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")),
		team = GetClientTeam(client);
	
	g_iCommanders[team - 2] = client;
}

public Action:Event_ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetEventBool(event, "disconnect"))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid")),
			oldteam = GetEventInt(event, "oldteam");
		
		if (oldteam > 1 && client == g_iCommanders[oldteam - 2])
		{
			g_iCommanders[oldteam - 2] = -1;
			
			if (g_hVoteHandle != INVALID_HANDLE && IsVoteInProgress() && g_iCurrentVoteInfo[VOTE_INFO_TEAM] == oldteam && g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_MUTINY)
				CancelVote();
		}
	}
}

//if the commander disconnects, cancel the mutiny vote if one exists
public OnClientDisconnect(client)
{
  if(!IsClientInGame(client)) return;
	new iTeam = GetClientTeam(client)
	
	if (iTeam > 1 && client == g_iCommanders[iTeam - 2])
	{
		g_iCommanders[iTeam - 2] = -1;
		
		if (g_hVoteHandle != INVALID_HANDLE && IsVoteInProgress() && g_iCurrentVoteInfo[VOTE_INFO_TEAM] == iTeam && g_iCurrentVoteInfo[VOTE_INFO_TYPE] == VOTETYPE_MUTINY)
				CancelVote();
	}
}

public Action:EnableSurrenderVote(Handle:timer, any:iTeam)
{
	g_bSurrenderVoteAllowed[iTeam - 2] = true;
}

public Action:EnableMutinyVote(Handle:timer, any:iTeam)
{
	if (iTeam == -1)
	{
		g_bMutinyVoteAllowed[0] = true;
		g_bMutinyVoteAllowed[1] = true;
	}

	else
		g_bMutinyVoteAllowed[iTeam - 2] = true;
}


public RefreshConVars(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == g_hCvar_SurrenderVoteTimer)
		g_fSurrenderVoteTimer = GetConVarFloat(g_hCvar_SurrenderVoteTimer) * 60;
	
	else if (cvar == g_hCvar_SurrenderVoteCommandersOnly)
		g_bSurrenderVoteCommandersOnly = GetConVarBool(g_hCvar_SurrenderVoteCommandersOnly);
	
	else if (cvar == g_hCvar_SurrenderVoteMinPlayers)
		g_iSurrenderVoteMinPlayers = GetConVarInt(g_hCvar_SurrenderVoteMinPlayers);
	
	else if (cvar == g_hCvar_SurrenderThreshold)
		g_fSurrenderThreshold = GetConVarFloat(g_hCvar_SurrenderThreshold) / 100;
	
	else if (cvar == g_hCvar_MutinyVoteTimer)
		g_fMutinyVoteTimer = GetConVarFloat(g_hCvar_MutinyVoteTimer) * 60;
	
	else if (cvar == g_hCvar_MutinyMinPlayers)
		g_iMutinyVoteMinPlayers = GetConVarInt(g_hCvar_MutinyMinPlayers);
		
	else if (cvar == g_hCvar_MutinyThreshold)
		g_fMutinyThreshold = GetConVarFloat(g_hCvar_MutinyThreshold) / 100;
	
	else if (cvar == g_hCvar_SimpleMajority)
		g_bSimpleMajority = GetConVarBool(g_hCvar_SimpleMajority);
}