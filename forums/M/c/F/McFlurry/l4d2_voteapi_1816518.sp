#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <l4d2_vote>

#define PLUGIN_VERSION "1.0.0 BeeTa"
//#define DEBUG

public Plugin:myinfo = 
{
	name = "L4D2 Voting API",
	author = "McFlurry",
	description = "Voting API for L4D2",
	version = PLUGIN_VERSION,
	url = "mcflurrysource.netne.net"
}

static const String:CONSOLE[] = "Console";

static const String:sIssues[L4D2VoteIssue][17] =
{
	"changealltalk",
	"changechapter",
	"changedifficulty",
	"changemission",
	"kick",
	"restartgame",
	"returntolobby",
	"custom",
	""
};

/*static const String:tsIssuePassPhrase[L4D2VoteIssue][] =
{
	"#L4D_vote_passed_change_alltalk_change",
	"#L4D_vote_passed_chapter_change",
	"#L4D_vote_passed_change_difficulty",
	"#L4D_vote_passed_mission_change",
	"#L4D_vote_passed_kick_player",
	"#L4D_vote_passed_restart_game",
	"#L4D_vote_passed_return_to_lobby",
	"#L4D_TargetID_Player",
	""
};*/

new Handle:hCvar_VoteCreationTimer = INVALID_HANDLE;
new Handle:hCvar_VotePlrFailedLimit = INVALID_HANDLE;
new Handle:hCvar_VoteShowCaller = INVALID_HANDLE;
new Handle:hCvar_VoteTimer = INVALID_HANDLE;

//forwards
new Handle:hOnClientVote = INVALID_HANDLE;
new Handle:hOnClientVote_Post = INVALID_HANDLE;
new Handle:hOnClientAddedToVote = INVALID_HANDLE;
new Handle:hOnClientAddedToVote_Post = INVALID_HANDLE;
new Handle:hOnVoteStart = INVALID_HANDLE;
new Handle:hOnVoteStart_Post = INVALID_HANDLE;
new Handle:hOnVoteStart_UsrMsg = INVALID_HANDLE;
new Handle:hOnVoteStart_UsrMsg_Post = INVALID_HANDLE;
new Handle:hOnVoteDisplay = INVALID_HANDLE;
new Handle:hOnVoteDisplay_Post = INVALID_HANDLE;
new Handle:hOnVotePass = INVALID_HANDLE;
new Handle:hOnVotePass_Post = INVALID_HANDLE;
new Handle:hOnVoteEnd = INVALID_HANDLE;

//private stuff
static L4D2Vote:iVote[MAXPLAYERS];
static iVoteInitiator = -1; //0 reserved for console;
static iVotingTeam = 255;
static iTotalVotes;
static iYesVotes;
static iNoVotes;
static iDefaultVoteTime;
static iVoters[MAXPLAYERS];
static iNumVoters;

static bool:bChangedVote[MAXPLAYERS];
static bool:bClientVoteChanged[MAXPLAYERS];
static bool:bClientVoteStartChanged[MAXPLAYERS];
static bool:bClientVoteEndChanged[MAXPLAYERS];
static bool:bVoteShowingCaller;
static bool:bVoteInProgress;
static bool:bVoteIsCooling;

static Float:flVoteStart;
static Float:flVoteTime;

static String:sVoteIssue[255];
static String:sVoteParam[255];
static String:tsVotePassIssue[255]; //translation string in usermessage
static String:tsVoteIssue[255]; //translation string in usermessage
static String:tsVoteParam[255]; //translation string in usermessage
static String:sInitiatorName[MAX_NAME_LENGTH];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if(!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports the Left 4 Dead 2 only.");
	}
	
	hCvar_VoteCreationTimer = FindConVar("sv_vote_creation_timer");
	if(hCvar_VoteCreationTimer == INVALID_HANDLE)
	{
		SetFailState("Failed to find sv_vote_creation_timer convar");
	}
	
	hCvar_VotePlrFailedLimit = FindConVar("sv_vote_plr_map_limit");
	if(hCvar_VotePlrFailedLimit == INVALID_HANDLE)
	{
		SetFailState("Failed to find sv_vote_plr_map_limit convar");
	}

	hCvar_VoteShowCaller = FindConVar("sv_vote_show_caller");
	if(hCvar_VoteShowCaller == INVALID_HANDLE)
	{
		SetFailState("Failed to find sv_vote_show_caller convar");
	}

	hCvar_VoteTimer = FindConVar("sv_vote_timer_duration");
	if(hCvar_VoteTimer == INVALID_HANDLE)
	{
		SetFailState("Failed to find sv_vote_timer_duration convar");
	}	

	SetConVarInt(hCvar_VoteCreationTimer, 0);
	SetConVarInt(hCvar_VotePlrFailedLimit, 9999); //should be enough
	bVoteShowingCaller = GetConVarBool(hCvar_VoteShowCaller);
	iDefaultVoteTime = GetConVarInt(hCvar_VoteTimer);
	
	HookConVarChange(hCvar_VoteCreationTimer, ConVar_CvarsChanged);
	HookConVarChange(hCvar_VotePlrFailedLimit, ConVar_CvarsChanged);
	HookConVarChange(hCvar_VoteShowCaller, ConVar_CvarsChanged);
	HookConVarChange(hCvar_VoteTimer, ConVar_CvarsChanged);

	hOnClientVote = CreateGlobalForward("L4D2_OnClientVote", ET_Hook, Param_Cell, Param_CellByRef);
	hOnClientVote_Post = CreateGlobalForward("L4D2_OnClientVote_Post", ET_Ignore, Param_Cell, Param_Cell);
	hOnClientAddedToVote = CreateGlobalForward("L4D2_OnClientAddedToVote", ET_Hook, Param_Cell);
	hOnClientAddedToVote_Post = CreateGlobalForward("L4D2_OnClientAddedToVote_Post", ET_Ignore, Param_Cell);
	hOnVoteStart = CreateGlobalForward("L4D2_OnVoteStart", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell);
	hOnVoteStart_Post = CreateGlobalForward("L4D2_OnVoteStart_Post", ET_Ignore, Param_Cell, Param_String, Param_String);
	hOnVoteStart_UsrMsg = CreateGlobalForward("L4D2_OnVoteStart_UsrMsg", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell, Param_String, Param_Cell);
	hOnVoteStart_UsrMsg_Post = CreateGlobalForward("L4D2_OnVoteStart_UsrMsg_Post", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String);
	hOnVoteDisplay = CreateGlobalForward("L4D2_OnVoteDisplay", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell);
	hOnVoteDisplay_Post = CreateGlobalForward("L4D2_OnVoteDisplay_Post", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String);
	hOnVotePass = CreateGlobalForward("L4D2_OnVotePass", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell);
	hOnVotePass_Post = CreateGlobalForward("L4D2_OnVotePass_Post", ET_Ignore, Param_Cell, Param_String, Param_String);
	hOnVoteEnd = CreateGlobalForward("L4D2_OnVoteEnd", ET_Hook, Param_Cell, Param_Array, Param_Cell);
	
	CreateNative("L4D2_FakeClientVote", Native_FakeClientVote);
	CreateNative("L4D2_GetClientVote", Native_GetClientVote);
	CreateNative("L4D2_IsVoteShowingCaller", Native_IsVoteShowingCaller);
	CreateNative("L4D2_GetVoteTimeLeft", Native_GetVoteTimeLeft);
	CreateNative("L4D2_IssueToIssueType", Native_IssueToIssueType);
	CreateNative("L4D2_IssueTypeToIssue", Native_IssueTypeToIssue);
	
	HookUserMessage(GetUserMessageId("VoteStart"), UserMessage_VoteStart, true);
	HookUserMessage(GetUserMessageId("VotePass"), UserMessage_VotePass, true);
	HookUserMessage(GetUserMessageId("VoteFail"), UserMessage_VoteFail);

	AddCommandListener(Listener_OnClientVote, "vote");
	AddCommandListener(Listener_OnVoteStart, "callvote");

	RegPluginLibrary("l4d2_vote");
	return APLRes_Success;
}

public OnMapStart()
{
	ClearVoteStrings();
	ResetVote(false);
}

public OnClientPutInServer(client)
{
	iVote[client] = L4D2Vote_NoVote;
}

public OnClientDisconnect(client)
{
	iVote[client] = L4D2Vote_NoVote;
}	

public Native_FakeClientVote(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(bVoteInProgress && iVote[client] == L4D2Vote_NotSet)
	{
		new L4D2Vote:votetype = GetNativeCell(2);
		decl String:vote[4];
		L4D2_TypeToVoteString(votetype, vote, sizeof(vote));
		FakeClientCommand(client, "vote %s", vote);
		return true;
	}
	else return false;
}	

public Native_GetClientVote(Handle:plugin, numParams)
{
	return _:iVote[GetNativeCell(1)];
}	

public Native_IsVoteShowingCaller(Handle:plugin, numParams)
{
	return bVoteShowingCaller;
}	

public Native_GetVoteTimeLeft(Handle:plugin, numParams)
{
	if(bVoteInProgress)
	{
		return _:(flVoteTime-(GetEngineTime()-flVoteStart));
	}
	else return _:0.0;
}

public Native_GetVoteDuration(Handle:plugin, numParams)
{
	return iDefaultVoteTime;
}

public Native_IssueToIssueType(Handle:plugin, numParams)
{
	decl String:sIssue[sizeof(sIssues[])];
	GetNativeString(1, sIssue, sizeof(sIssue));
	for(new i; i<sizeof(sIssues); i++)
	{
		if(StrEqual(sIssue, sIssues[i], false))
		{
			return i;
		}
	}
	return _:L4D2VoteIssue_Invalid;
}

public Native_IssueTypeToIssue(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	if(0 > type > _:L4D2VoteIssue_Invalid) SetNativeString(2, "", GetNativeCell(3));
	else SetNativeString(2, sIssues[type], GetNativeCell(3));
}

public Action:UserMessage_VoteStart(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(playersNum == 1 && bClientVoteStartChanged[players[0]])
	{
		bClientVoteStartChanged[players[0]] = false;
		return Plugin_Continue;
	}	
	else if(bVoteInProgress)
	{
		return Plugin_Handled;
	}
	
	iVotingTeam = BfReadByte(bf);
	BfReadByte(bf); //initiator, don't store value, we got this back on "callvote"
	BfReadString(bf, tsVoteIssue, sizeof(tsVoteIssue));
	BfReadString(bf, tsVoteParam, sizeof(tsVoteParam));

	decl String:refVoteIssue[255], String:refVoteParam[255];
	strcopy(refVoteIssue, sizeof(refVoteIssue), tsVoteIssue);
	strcopy(refVoteParam, sizeof(refVoteParam), tsVoteParam);

	new Action:result = Plugin_Continue, refVoteInitiator = iVoteInitiator, refVotingTeam = iVotingTeam;
	Call_StartForward(hOnVoteStart_UsrMsg);
	Call_PushCell(refVoteInitiator);
	Call_PushCellRef(refVotingTeam);
	Call_PushStringEx(refVoteIssue, sizeof(refVoteIssue), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(sizeof(refVoteIssue));
	Call_PushStringEx(refVoteParam, sizeof(refVoteParam), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(sizeof(refVoteParam));
	Call_Finish(result);
	
	if(result == Plugin_Changed)
	{
		iVoteInitiator = refVoteInitiator;
		if(iVoteInitiator == 0)
		{
			strcopy(sInitiatorName, sizeof(sInitiatorName), CONSOLE);
		}
		else
		{
			GetClientName(iVoteInitiator, sInitiatorName, sizeof(sInitiatorName));
		}	
		iVotingTeam = refVotingTeam;
		strcopy(tsVoteIssue, sizeof(tsVoteIssue), refVoteIssue);
		strcopy(tsVoteParam, sizeof(tsVoteParam), refVoteParam);
	}
	else if(result != Plugin_Continue)
	{
		iVoteInitiator = 0;
		iVotingTeam = 0; //reset because we're not continuing
		ClearVoteStrings();
		return Plugin_Handled;
	}
	
	Call_StartForward(hOnVoteStart_UsrMsg_Post);
	Call_PushCell(iVoteInitiator);
	Call_PushCell(iVotingTeam);
	Call_PushString(tsVoteIssue);
	Call_PushString(tsVoteParam);
	Call_Finish();
	
	flVoteStart = GetEngineTime();
	flVoteTime = float(iDefaultVoteTime);
	bVoteInProgress = true;
	CreateTimer(0.0, Timer_VoteStart, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}	

public Action:Timer_VoteStart(Handle:Timer)
{
	iTotalVotes = 0;
	iYesVotes = 0;
	iNoVotes = 0;
	
	for(new i=1;i<MAXPLAYERS;i++)
	{
		iVote[i] = L4D2Vote_Unallowed;
	}
	
	for(new i=1;i<=MaxClients;i++)
	{
		if((IsClientInGame(i) && !IsFakeClient(i)) && (iVotingTeam == 255 || (iVotingTeam != 0 && GetClientTeam(i) == iVotingTeam)))
		{
			new Action:result = Plugin_Continue;
			if(i != iVoteInitiator)
			{
				Call_StartForward(hOnClientAddedToVote);
				Call_PushCell(i);
				Call_Finish(result);
			
				if(result != Plugin_Continue)
				{
					continue;
				}
			}
			
			Call_StartForward(hOnClientAddedToVote_Post);
			Call_PushCell(i);
			Call_Finish();
			
			decl String:refVoteIssue[255], String:refVoteParam[255], String:refInitiatorName[MAX_NAME_LENGTH], String:voteIssue[255], String:voteParam[255], String:initiatorName[MAX_NAME_LENGTH];
			strcopy(voteIssue, sizeof(voteIssue), tsVoteIssue);
			strcopy(voteParam, sizeof(voteParam), tsVoteParam);
			strcopy(initiatorName, sizeof(initiatorName), sInitiatorName);
			strcopy(refVoteIssue, sizeof(refVoteIssue), tsVoteIssue);
			strcopy(refVoteParam, sizeof(refVoteParam), tsVoteParam);
			strcopy(refInitiatorName, sizeof(refInitiatorName), sInitiatorName);
			
			result = Plugin_Continue;
			Call_StartForward(hOnVoteDisplay);
			Call_PushCell(i);
			Call_PushStringEx(refInitiatorName, sizeof(refInitiatorName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(refInitiatorName));
			Call_PushStringEx(refVoteIssue, sizeof(refVoteIssue), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(refVoteIssue));
			Call_PushStringEx(refVoteParam, sizeof(refVoteParam), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(refVoteParam));
			Call_Finish(result);
			
			if(result == Plugin_Changed)
			{
				strcopy(initiatorName, sizeof(sInitiatorName), refInitiatorName);
				strcopy(voteIssue, sizeof(tsVoteIssue), refVoteIssue);
				strcopy(voteParam, sizeof(tsVoteParam), refVoteParam);
			}
			else if(result != Plugin_Continue)
			{
				if(i == iVoteInitiator)//initiator cannot be removed from the vote even if they are not given a display to see vote progress
				{
					iVote[i] = L4D2Vote_Yes;
					iVoters[iNumVoters++] = i;
					Call_StartForward(hOnClientVote_Post);
					Call_PushCell(i);
					Call_PushCell(L4D2Vote_Yes);
					Call_Finish();
				}
				continue; //no point in continuing (lol)
			}
			
			iVote[i] = L4D2Vote_NotSet;
			iVoters[iNumVoters++] = i;
			
			Call_StartForward(hOnVoteDisplay_Post);
			Call_PushCell(i);
			Call_PushString(initiatorName);
			Call_PushString(voteIssue);
			Call_PushString(voteParam);
			Call_Finish();
			
			bClientVoteStartChanged[i] = true;
			new Handle:bf = StartMessageOne("VoteStart", i, USERMSG_RELIABLE);
			BfWriteByte(bf, iVotingTeam);
			BfWriteByte(bf, iVoteInitiator);
			BfWriteString(bf, voteIssue);
			BfWriteString(bf, voteParam);
			BfWriteString(bf, initiatorName);
			EndMessage();
			
			if(i == iVoteInitiator)
			{
				iVote[i] = L4D2Vote_Yes;
				Call_StartForward(hOnClientVote_Post);
				Call_PushCell(i);
				Call_PushCell(L4D2Vote_Yes);
				Call_Finish();
			}
		}
	}
}

public Action:UserMessage_VotePass(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(bVoteInProgress && bClientVoteEndChanged[players[0]])
	{
		bClientVoteEndChanged[players[0]] = false;
		return Plugin_Continue;
	}	
	
	BfReadByte(bf); //teams that are voting
	BfReadString(bf, tsVotePassIssue, sizeof(tsVotePassIssue), true);
	BfReadString(bf, tsVoteParam, sizeof(tsVoteParam), true);
	
	Call_StartForward(hOnVoteEnd);
	Call_PushCell(1);
	Call_PushArray(iVoters, iNumVoters);
	Call_PushCell(iNumVoters);
	Call_Finish();

	CreateTimer(0.0, Timer_VotePass, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}	

public Action:Timer_VotePass(Handle:Timer)
{
	decl String:voteIssue[255], String:voteParam[255], String:refVoteIssue[255], String:refVoteParam[255];

	for(new i=1; i <= MaxClients; i++)
	{
		if((IsClientInGame(i) && !IsFakeClient(i)) && (iVotingTeam == 255 || (iVotingTeam != 0 && GetClientTeam(i) == iVotingTeam)))
		{
			strcopy(voteIssue, sizeof(voteIssue), tsVotePassIssue);
			strcopy(voteParam, sizeof(voteParam), tsVoteParam);
			strcopy(refVoteIssue, sizeof(refVoteIssue), tsVotePassIssue);
			strcopy(refVoteParam, sizeof(refVoteParam), tsVoteParam);
			
			new Action:result = Plugin_Continue;
			Call_StartForward(hOnVotePass);
			Call_PushCell(i);
			Call_PushStringEx(refVoteIssue, sizeof(refVoteIssue), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(refVoteIssue));
			Call_PushStringEx(refVoteParam, sizeof(refVoteParam), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(refVoteParam));
			Call_Finish(result);
			
			if(result == Plugin_Changed)
			{
				strcopy(voteIssue, sizeof(voteIssue), refVoteIssue);
				strcopy(voteParam, sizeof(voteParam), refVoteParam);
			}
			else if(result != Plugin_Continue)
			{
				continue;
			}
			
			Call_StartForward(hOnVotePass_Post);
			Call_PushCell(i);
			Call_PushString(voteIssue);
			Call_PushString(voteParam);
			Call_Finish();
			
			bClientVoteEndChanged[i] = true;
			new Handle:bf = StartMessageOne("VotePass", i, USERMSG_RELIABLE);
			BfWriteByte(bf, iVotingTeam);
			BfWriteString(bf, voteIssue);
			BfWriteString(bf, voteParam);
			EndMessage();
		}
	}
	
	ClearVoteStrings();
	ResetVote(true);
	CreateTimer(15.0, Timer_VoteCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:UserMessage_VoteFail(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	Call_StartForward(hOnVoteEnd);
	Call_PushCell(0);
	Call_PushArray(iVoters, iNumVoters);
	Call_PushCell(iNumVoters);
	Call_Finish();
	
	ClearVoteStrings();
	ResetVote(true);
	CreateTimer(15.0, Timer_VoteCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_VoteCooldown(Handle:Timer)
{
	bVoteIsCooling = false;
}

public Action:Listener_OnClientVote(client, const String:command[], argc)
{
	if(argc == 1)
	{		
		if(bChangedVote[client])
		{
			bChangedVote[client] = false;
			return Plugin_Continue;
		}
		else if(iVote[client] == L4D2Vote_NotSet || iVote[client] == L4D2Vote_Invalid)
		{
			decl String:sVote[4];
			GetCmdArg(1, sVote, sizeof(sVote));
			new L4D2Vote:iVoteType = L4D2_VoteStringToType(sVote);
			
			new Action:result = Plugin_Continue, L4D2Vote:refVoteType = iVoteType;
			Call_StartForward(hOnClientVote);
			Call_PushCell(client);
			Call_PushCellRef(refVoteType);
			Call_Finish(result);
			
			L4D2_TypeToVoteString(refVoteType, sVote, sizeof(sVote));
			
			if(result == Plugin_Changed)
			{
				if(refVoteType != L4D2Vote_Invalid)
				{
					iVote[client] = refVoteType;
					iVoteType = refVoteType;
					bChangedVote[client] = true;
					FakeClientCommand(client, "vote %s", sVote);
				}
			}
			else if(result != Plugin_Continue)
			{
				return Plugin_Handled;
			}
			
			iVote[client] = iVoteType;
			
			switch(iVoteType)
			{
				case L4D2Vote_No:
				{
					iNoVotes++;
					iTotalVotes++;
				}
				case L4D2Vote_Yes:
				{
					iYesVotes++;
					iTotalVotes++;
				}
			}
			
			L4D2_ChangeVote(iYesVotes, iNoVotes, (iNumVoters-(iYesVotes+iNoVotes)));

			Call_StartForward(hOnClientVote_Post);
			Call_PushCell(client);
			Call_PushCell(iVoteType);
			Call_Finish();
			
			if(bChangedVote[client]) return Plugin_Handled;
			else return Plugin_Continue;
		}
	}	
	return Plugin_Handled;
}	

public Action:Listener_OnVoteStart(client, const String:command[], argc)
{
	if(0 < argc < 3)
	{
		if(bClientVoteChanged[client])
		{
			bClientVoteChanged[client] = false;
			return Plugin_Handled;
		}
		decl String:refVote[32];
		GetCmdArg(1, refVote, sizeof(refVote));
		TrimString(refVote);
		
		new L4D2VoteIssue:iIssue = L4D2_IssueToIssueType(refVote);
		if((L4D2VoteIssue_ChangeChapter <= iIssue <= L4D2VoteIssue_Kick && argc != 2) || iIssue == L4D2VoteIssue_Invalid)//missing arguments, for vote types that require two arguments
		{
			return Plugin_Handled;
		}	
		else if((client == 0 && iIssue != L4D2VoteIssue_Custom && argc != 3) || bVoteInProgress || bVoteIsCooling)
		{
			return Plugin_Handled;
		}
		
		strcopy(sVoteIssue, sizeof(sVoteIssue), refVote);
		new String:refParam[255];
		if(argc == 2)
		{
			GetCmdArg(2, refParam, sizeof(refParam));
			TrimString(refParam);
			strcopy(sVoteParam, sizeof(sVoteParam), refParam);
		}
		
		if(client != 0)
		{
			iVotingTeam = GetClientTeam(client);
			iVoteInitiator = client;
		}
		else
		{
			decl String:sTeam[3];
			GetCmdArg(3, sTeam, sizeof(sTeam));
			iVotingTeam = StringToInt(sTeam);
			iVoteInitiator = 0;
		}

		new Action:result = Plugin_Continue;
		Call_StartForward(hOnVoteStart);
		Call_PushCell(iVoteInitiator);
		Call_PushStringEx(refVote, sizeof(refVote), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(sizeof(refVote));
		Call_PushStringEx(refParam, sizeof(refParam), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(sizeof(refParam));
		Call_Finish(result);
		
		if(result == Plugin_Changed)
		{
			strcopy(sVoteIssue, sizeof(sVoteIssue), refVote);
			strcopy(sVoteParam, sizeof(sVoteParam), refParam);
			iIssue = L4D2_IssueToIssueType(sVoteIssue);
			bClientVoteChanged[client] = true;
			FakeClientCommand(client, "callvote %s %s", sVoteIssue, sVoteParam);
			return Plugin_Handled;
		}
		else if(result != Plugin_Continue)
		{
			ClearVoteStrings();
			ResetVote(false);
			return Plugin_Handled;
		}
		
		Call_StartForward(hOnVoteStart_Post);
		Call_PushCell(iVoteInitiator);
		Call_PushString(sVoteIssue);
		Call_PushString(sVoteParam);
		Call_Finish();
		
		if(iVoteInitiator == 0)
		{
			strcopy(sInitiatorName, sizeof(sInitiatorName), CONSOLE);
		}
		else
		{
			GetClientName(iVoteInitiator, sInitiatorName, sizeof(sInitiatorName));
		}
		
		if(iIssue == L4D2VoteIssue_Custom)
		{
			//L4D2_StartCustomVote(client, iVotingTeam, sVoteIssue);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public ConVar_CvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:cvarname[48];
	GetConVarName(convar, cvarname, sizeof(cvarname));
	
	if(StrContains(cvarname, "creation_timer", false) != -1)
	{
		SetConVarInt(hCvar_VoteCreationTimer, 0);
	}
	else if(StrContains(cvarname, "plr_map_limit", false) != -1)
	{
		SetConVarInt(hCvar_VotePlrFailedLimit, 9999);
	}
	else if(StrContains(cvarname, "show_caller", false) != -1)
	{
		bVoteShowingCaller = bool:StringToInt(newValue);
	}
	else if(StrContains(cvarname, "timer_duration", false) != -1)
	{
		iDefaultVoteTime = StringToInt(newValue);
	}	
}

static stock L4D2_ChangeVote(yes, no, potential)
{
	new Handle:event = CreateEvent("vote_changed");
	SetEventInt(event, "yesVotes", yes);
	SetEventInt(event, "noVotes", no);
	SetEventInt(event, "potentialVotes", yes+no+potential);
	FireEvent(event);
}

static stock L4D2Vote:L4D2_VoteStringToType(const String:vote[])
{
	if(StrEqual(vote, "yes", false))
	{
		return L4D2Vote_Yes;
	}
	else if(StrEqual(vote, "no", false))
	{
		return L4D2Vote_No;
	}
	else
	{
		return L4D2Vote_Invalid;
	}
}

static stock L4D2_TypeToVoteString(L4D2Vote:vote, String:dest[], dest_size)
{
	if(vote == L4D2Vote_Yes)
	{
		Format(dest, dest_size, "yes");
	}
	else if(vote == L4D2Vote_No)
	{
		Format(dest, dest_size, "no");
	}
	else
	{
		Format(dest, dest_size, "");
	}
}

static stock ClearVoteStrings()
{
	Format(sVoteIssue, sizeof(sVoteIssue), "");
	Format(sVoteParam, sizeof(sVoteParam), "");
	Format(tsVotePassIssue, sizeof(tsVotePassIssue), "");
	Format(tsVoteIssue, sizeof(tsVoteIssue), "");
	Format(tsVoteParam, sizeof(tsVoteParam), "");
	Format(sInitiatorName, sizeof(sInitiatorName), "");
}	

static stock ResetVote(bool:cooling)
{
	flVoteStart = 0.0;
	flVoteTime = 0.0;
	for(new i=1; i<MAXPLAYERS; i++)
	{
		iVoters[i] = 0;
		iVote[i] = L4D2Vote_NoVote;
	}
	bVoteInProgress = false;
	bVoteIsCooling = cooling;
	iVoteInitiator = -1;
	iVotingTeam = 255;
	iTotalVotes = 0;
	iYesVotes = 0;
	iNoVotes = 0;
	iNumVoters = 0;
}