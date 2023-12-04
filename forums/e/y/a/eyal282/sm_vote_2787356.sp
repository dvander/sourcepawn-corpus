/* put the line below after all of the includes!
#pragma newdecls required
*/

#include <sourcemod>

#pragma semicolon 1

Handle hVoteTime     = INVALID_HANDLE;
Handle hFinVote      = INVALID_HANDLE;
Handle hCoolDown     = INVALID_HANDLE;
Handle CurrentPlugin = INVALID_HANDLE;
Handle pCaller       = INVALID_HANDLE;

Handle fw_VoteFinished     = INVALID_HANDLE;
Handle fw_VoteFinishedPost = INVALID_HANDLE;

int  VoteInit, VotesFor, VotesAgainst, MaxVotes;
bool VoteStarted, bCountedMaxVotes[MAXPLAYERS];
char VoteSubject[100];

bool bCanVote[MAXPLAYERS];
bool GameVoteRunning;           // true if one of L4D2's votes are running, to prevent collisions.
int  VoteTeam, VotePercents;    // VoteTeam: -1 = All, 2 = Survivor, 3 = Infected.

int VoteController;

bool InternalVote, CoolDown;

public Plugin myinfo =
{
	name        = "sm_vote",
	author      = "Eyal282",
	description = "Voting system for Left 4 Dead 2.",
	version     = "1.0",
	url         = "None."


}

public OnPluginStart()
{
	hVoteTime = FindConVar("sv_vote_timer_duration");

	RegAdminCmd("sm_startvote", Command_StartVote, ADMFLAG_VOTE, "sm_vote <@infected/@survivors/@all> <percents needed to pass> <subject>");
	RegAdminCmd("sm_pass", Command_Pass, ADMFLAG_VOTE);
	RegAdminCmd("sm_veto", Command_Veto, ADMFLAG_VOTE);
	RegConsoleCmd("sm_f1", Command_VoteYes);
	RegConsoleCmd("sm_f2", Command_VoteNo);

	HookUserMessage(GetUserMessageId("VoteStart"), Event_VoteStart);
	HookUserMessage(GetUserMessageId("VotePass"), Event_VoteEnd);
	HookUserMessage(GetUserMessageId("VoteFail"), Event_VoteEnd);

	RegConsoleCmd("Vote", OnClientVoteCast);

	// public sm_vote_OnVoteFinished(&client, &VotesFor, &VotesAgainst, &PercentsToPass, bCanVote[MAXPLAYERS], String:&VoteSubject[], bInternalVote, Handle:pCaller)
	fw_VoteFinished     = CreateGlobalForward("sm_vote_OnVoteFinished", ET_Event, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_String, Param_CellByRef, Param_Any);
	fw_VoteFinishedPost = CreateGlobalForward("sm_vote_OnVoteFinished_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_String, Param_Cell, Param_Any);
}

public OnEntityCreated(entity, const char[] Classname)
{
	if (StrEqual(Classname, "vote_controller"))
		VoteController = EntIndexToEntRef(entity);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CurrentPlugin = myself;
	CreateNative("StartCustomVote", StartCustomVote);

	return APLRes_Success;
}

// native StartCustomVote(client, String:strTeam[], Percents, String:VoteSubject[]);
// Note: strTeam is either @all, @infected, @survivors. @all means the vote is for all, @infected means vote only for infected team, @survivors same but only for survivors team.
// Note: Percents must be between 1 and 100 or an error will be thrown to the client through ReplyToCommand.
// @return: 0 on success, 1 if percents are invalid ( not between 1 to 100 ), 2 if the vote is on the 6.0 seconds cooldown, 3 if the team is not valid
// @return:
public StartCustomVote(Handle plugin, int numParams)
{
	int  client, Percents;
	char strTeam[13], Subject[100], strPercents[5];

	client = GetNativeCell(1);
	GetNativeString(2, strTeam, sizeof(strTeam));

	Percents = GetNativeCell(3);
	IntToString(Percents, strPercents, sizeof(strPercents));

	GetNativeString(4, Subject, sizeof(Subject));

	int ReturnValue = BeginVote(client, strTeam, strPercents, Subject, plugin);

	if (ReturnValue == 0)
	{
		InternalVote = false;
	}

	return ReturnValue;
}

public void OnClientDisconnect(int client)
{
	if (bCountedMaxVotes[client])
	{
		MaxVotes--;
		UpdateVotes();
	}
}

public void OnMapStart()
{
	CoolDown    = false;
	VoteStarted = false;
	hCoolDown   = INVALID_HANDLE;
	hFinVote    = INVALID_HANDLE;
}

public Action Event_VoteStart(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	GameVoteRunning = true;
	if (hCoolDown != INVALID_HANDLE)
	{
		CloseHandle(hCoolDown);
		hCoolDown = INVALID_HANDLE;
	}

	CoolDown = false;

	return Plugin_Continue;
}

public Action Event_VoteEnd(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	GameVoteRunning = false;
	VoteStarted     = false;
	CoolDown        = true;

	if (hCoolDown != INVALID_HANDLE)
	{
		CloseHandle(hCoolDown);
		hCoolDown = INVALID_HANDLE;
	}

	hCoolDown = CreateTimer(6.0, FinishCoolDown, _, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action FinishCoolDown(Handle hTimer)
{
	CoolDown = false;

	hCoolDown = INVALID_HANDLE;

	return Plugin_Continue;
}

public Action OnClientVoteCast(int client, int args)
{
	if (!VoteStarted)
		return Plugin_Continue;

	else if (!bCanVote[client])
		return Plugin_Continue;

	else if (VoteTeam != -1 && GetClientTeam(client) != VoteTeam)
		return Plugin_Continue;

	char Arg1[5];
	int  ClientArray[1];

	GetCmdArg(1, Arg1, sizeof(Arg1));

	ClientArray[0] = client;

	if (StrEqual(Arg1, "Yes", true))
	{
		VotesFor++;

		Handle bf = StartMessage("VoteRegistered", ClientArray, 1, USERMSG_RELIABLE);

		BfWriteByte(bf, 1);    // 1 = Yes ( F1 )

		EndMessage();
	}
	else if (StrEqual(Arg1, "No", true))
	{
		VotesAgainst++;

		Handle bf = StartMessage("VoteRegistered", ClientArray, 1, USERMSG_RELIABLE);

		BfWriteByte(bf, 0);    // 2 = No ( F2 )

		EndMessage();
	}

	else
		return Plugin_Continue;

	bCanVote[client] = false;

	UpdateVotes();

	return Plugin_Continue;
}

public void OnClientConnected(int client)
{
	bCanVote[client]         = false;
	bCountedMaxVotes[client] = false;
}

public Action Command_StartVote(int client, int args)
{
	if (GameVoteRunning)
	{
		ReplyToCommand(client, "[SM] Error: a vote is already running! Use sm_veto to stop the current vote.");
		return Plugin_Handled;
	}
	else if (CoolDown)
	{
		ReplyToCommand(client, "[SM] Error: You must wait at least 6 seconds between every vote.");
		return Plugin_Handled;
	}
	else if (args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_startvote <@infected/@survivors/@all> <percents needed to pass> <subject>");
		return Plugin_Handled;
	}

	char Temp[30];    // At first, subject will be all arguments but I'll remove all arguments from it.
	char Arg1[13], Arg2[5];

	GetCmdArg(1, Arg1, sizeof(Arg1));
	GetCmdArg(2, Arg2, sizeof(Arg2));

	GetCmdArgString(VoteSubject, sizeof(VoteSubject));

	Format(Temp, sizeof(Temp), "%s %s ", Arg1, Arg2);

	ReplaceStringEx(VoteSubject, sizeof(VoteSubject), Temp, "");

	int percents = StringToInt(Arg2);

	if (percents > 100 || percents <= 0 || !IsStringNumber(Arg2))
	{
		ReplyToCommand(client, "[SM] Error: The percents must be a value between 1 and 100");
		return Plugin_Handled;
	}

	InternalVote = true;
	BeginVote(client, Arg1, Arg2, VoteSubject, CurrentPlugin);

	PrintToChatAll("\x01Admin\x3 %N\x01 has\x04 started\x01 a\x04 vote for\x03 %s! To pass: %i%% ", client, Arg1, percents);

	return Plugin_Handled;
}

int BeginVote(int client, char[] Arg1, char[] Arg2, char[] Subject, Handle Call)
{
	int percents = StringToInt(Arg2);
	if (percents > 100 || percents <= 0 || !IsStringNumber(Arg2))
	{
		ReplyToCommand(client, "[SM] Error: The percents must be a value between 1 and 100");
		return 1;
	}
	else if (CoolDown)
	{
		return 2;
	}

	else if (GameVoteRunning)
	{
		return 4;
	}

	if (StrEqual(Arg1, "@all", false) || StrEqual(Arg1, "all", false))
		VoteTeam = -1;

	else if (StrEqual(Arg1, "@survivors", false) || StrEqual(Arg1, "survivors", false))
		VoteTeam = 2;

	else if (StrEqual(Arg1, "@infected", false) || StrEqual(Arg1, "infected", false))
		VoteTeam = 3;

	else
	{
		ReplyToCommand(client, "[SM] Error: Valid teams: @all / @survivors / @infected");
		return 3;
	}

	Format(VoteSubject, sizeof(VoteSubject), Subject);

	// VoteTeam is already set above here, let's set the other variables.

	VotePercents = percents;

	VoteInit = client;

	pCaller = Call;
	StartVGUIVote(client, VoteTeam, VoteSubject);

	return 0;
}

public Action Command_Pass(int client, int args)
{
	if (!VoteStarted)
	{
		if (GameVoteRunning)
		{
			int controller = EntRefToEntIndex(VoteController);

			if (controller != INVALID_ENT_REFERENCE)
			{
				SetEntProp(controller, Prop_Send, "m_votesNo", 0);
				SetEntProp(controller, Prop_Send, "m_votesYes", 64);
				SetEntProp(controller, Prop_Send, "m_potentialVotes", 0);
			}
		}

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			FakeClientCommand(i, "Vote Yes");
		}

		return Plugin_Handled;
	}
	VotesAgainst = 0;
	VotesFor     = MaxVotes;

	UpdateVotes();

	return Plugin_Handled;
}

public Action Command_Veto(int client, int args)
{
	if (!VoteStarted)
	{
		if (GameVoteRunning)
		{
			int controller = EntRefToEntIndex(VoteController);

			if (controller != INVALID_ENT_REFERENCE)
			{
				SetEntProp(controller, Prop_Send, "m_votesNo", 64);
				SetEntProp(controller, Prop_Send, "m_votesYes", 0);
				SetEntProp(controller, Prop_Send, "m_potentialVotes", 0);
			}
		}

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			FakeClientCommand(i, "Vote No");
		}

		return Plugin_Handled;
	}

	VotesAgainst = MaxVotes;
	VotesFor     = 0;

	UpdateVotes();

	return Plugin_Handled;
}

void StartVGUIVote(int client, int Team, char[] Issue)
{
	Handle bf = StartMessageAll("VoteStart", USERMSG_RELIABLE);

	BfWriteByte(bf, Team);                        // Team.
	BfWriteByte(bf, 0);                           // Player who started the vote ( use client index ( i.e client ) instead of userid )
	BfWriteString(bf, "#L4D_TargetID_Player");    // Issue translation string
	BfWriteString(bf, Issue);                     // The issue
	char Name[32];
	GetClientName(client, Name, sizeof(Name));

	BfWriteString(bf, Name);    // The name of the person who started the vote.
	EndMessage();

	VoteStarted  = true;
	VotesFor     = 0;
	VotesAgainst = 0;
	MaxVotes     = 0;

	if (hFinVote != INVALID_HANDLE)
	{
		CloseHandle(hFinVote);
		hFinVote = INVALID_HANDLE;
	}

	hFinVote = CreateTimer(float(GetConVarInt(hVoteTime)), FinishVote, _, TIMER_FLAG_NO_MAPCHANGE);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (IsFakeClient(i))
			continue;

		if (VoteTeam == -1 || GetClientTeam(i) == Team)    // -1 = Vote for all teams
		{
			MaxVotes++;
			bCanVote[i]         = true;
			bCountedMaxVotes[i] = true;
		}
	}

	UpdateVotes();
}

public Action FinishVote(Handle hTimer)
{
	hFinVote = INVALID_HANDLE;

	if (!VoteStarted)
		return Plugin_Continue;

	VotesAgainst = MaxVotes - VotesFor;

	UpdateVotes();

	return Plugin_Continue;
}

void UpdateVotes()
{
	if (!VoteStarted)
		return;

	Handle msg = CreateEvent("vote_changed");
	SetEventInt(msg, "yesVotes", VotesFor);
	SetEventInt(msg, "noVotes", VotesAgainst);
	SetEventInt(msg, "potentialVotes", MaxVotes);
	FireEvent(msg);

	if (VotesFor + VotesAgainst >= MaxVotes)
	{
		// client = Vote innitiator, &VotesFor = Amount of votes that are F1, &VotesAgainst = Amount of votes that are F2, &PercentsToPass = the percents of the players needed to pass,
		// bCanVote[MAXPLAYERS] = Array of every player's vote status ( if you wanna make non-voters removed from percents to pass etc... ),
		// public sm_vote_OnVoteFinished(client, &VotesFor, &VotesAgainst, &PercentsToPass, bCanVote[MAXPLAYERS], String:&VoteSubject[], &InternalVote)

		// Note: bCanVote[MAXPLAYERS] is broken for now.
		// Note: new Float:ForPercents = ( float(VotesFor) / ( float(VotesFor) + float(VotesAgainst) ) ) * 100.0;
		// Note: new Float:AgainstPercents = 100 - ForPercents;

		int ReturnValue;
		Call_StartForward(fw_VoteFinished);

		Call_PushCellRef(VoteInit);
		Call_PushCellRef(VotesFor);
		Call_PushCellRef(VotesAgainst);
		Call_PushCellRef(VotePercents);
		Call_PushArray(bCanVote, sizeof(bCanVote));
		Call_PushStringEx(VoteSubject, sizeof(VoteSubject), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(InternalVote);
		Call_PushCell(pCaller);

		Call_Finish(ReturnValue);

		if (hFinVote != INVALID_HANDLE)
		{
			CloseHandle(hFinVote);
			hFinVote = INVALID_HANDLE;
		}

		for (int i = 1; i <= MaxClients; i++)
		{
			bCanVote[i] = false;
		}

		float ForPercents = (float(VotesFor) / (float(VotesFor) + float(VotesAgainst))) * 100.0;

		if (ForPercents >= VotePercents)
		{
			Handle bf = StartMessageAll("VotePass");

			BfWriteByte(bf, -1);    // Vote team all

			BfWriteString(bf, "#L4D_TargetID_Player");

			char PassedMessage[100];

			Format(PassedMessage, sizeof(PassedMessage), "%.1f%% of the Players Voted Yes\nIssue: %s", ForPercents, VoteSubject);
			BfWriteString(bf, PassedMessage);

			EndMessage();
		}
		else
		{
			Handle bf = StartMessageAll("VoteFail");
			BfWriteByte(bf, -1);    // Vote Team All
			EndMessage();

			if (InternalVote)
			{
				PrintToChatAll("The vote failed with only %.1f%% Votes Yes. Votes Needed: %i%%", ForPercents, VotePercents);
			}
		}

		Call_StartForward(fw_VoteFinishedPost);

		Call_PushCell(VoteInit);
		Call_PushCell(VotesFor);
		Call_PushCell(VotesAgainst);
		Call_PushCell(VotePercents);
		Call_PushArray(bCanVote, sizeof(bCanVote));
		Call_PushString(VoteSubject);
		Call_PushCell(InternalVote);
		Call_PushCell(pCaller);

		Call_Finish();
		VoteStarted = false;
	}
}

public Action Command_VoteYes(int client, int args)
{
	FakeClientCommand(client, "Vote Yes");

	return Plugin_Handled;
}

public Action Command_VoteNo(int client, int args)
{
	FakeClientCommand(client, "Vote No");

	return Plugin_Handled;
}

stock bool IsStringNumber(char[] Str)
{
	int Length = strlen(Str);
	for (int i; i < Length; i++)
	{
		if (!IsCharNumeric(Str[i]))
			return false;
	}

	return true;
}

stock PrintToChatEyal(const char[] format, any...)
{
	char buffer[291];
	VFormat(buffer, sizeof(buffer), format, 2);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (IsFakeClient(i))
			continue;

		char steamid[64];
		GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));

		if (StrEqual(steamid, "STEAM_1:0:49508144"))
			PrintToChat(i, buffer);
	}
}
