/* Sniff TF2 vote events, user messages, and commands */

#pragma semicolon 1

#include <sourcemod>

#define MAX_ARG_SIZE 33
#define TEAM_ALL -1

public Plugin:myinfo = 
{
	name = "L4D2 Vote Sniffer",
	author = "Powerlord",
	description = "Sniff voting events and usermessages",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("vote_started", EventVoteStarted);
	HookEvent("vote_ended", EventVoteEnded);
	HookEvent("vote_changed", EventVoteChanged);
	HookEvent("vote_passed", EventVotePassed);
	HookEvent("vote_failed", EventVoteFailed);
	HookEvent("vote_cast_yes", EventVoteCastYes);
	HookEvent("vote_cast_no", EventVoteCastNo);
	HookUserMessage(GetUserMessageId("VoteStart"), MessageVoteStart);
	HookUserMessage(GetUserMessageId("VotePass"), MessageVotePass);
	HookUserMessage(GetUserMessageId("VoteFail"), MessageVoteFail);
	HookUserMessage(GetUserMessageId("VoteRegistered"), MessageVoteRegistered);
	HookUserMessage(GetUserMessageId("CallVoteFailed"), MessageCallVoteFailed);
//	RegAdminCmd("votefail", CommandVoteFail, ADMFLAG_VOTE, "Force a vote fail with the specified number");
//	RegAdminCmd("callvotefail", CommandCallVoteFail, ADMFLAG_VOTE, "Force a call vote fail with the specified number and other value");
	AddCommandListener(CommandVote, "Vote");
	AddCommandListener(CommandCallVote, "callvote");
}

/*
 "vote_started"
{
	"issue"                 "string"
	"param1"                "string"
	"team"                  "byte"
	"initiator"             "long" // entity id of the player who initiated the vote
}
*/
public EventVoteStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:issue[MAX_ARG_SIZE];
	decl String:param1[256];
	GetEventString(event, "issue", issue, sizeof(issue));
	GetEventString(event, "param1", param1, sizeof(param1));
	new team = GetEventInt(event, "team");
	new initiator = GetEventInt(event, "initiator");
	LogMessage("Vote Start Event: issue: \"%s\", param1: \"%s\", team: %d, initiator: %d", issue, param1, team, initiator);
}

/*
"vote_ended"
{
}
*/
public EventVoteEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogMessage("Vote Ended Event");
}

/*
"vote_changed"
{
	"yesVotes"		"byte"
	"noVotes"		"byte"
	"potentialVotes"	"byte"
}
*/
public EventVoteChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new yesVotes = GetEventInt(event, "yesVotes");
	new noVotes = GetEventInt(event, "noVotes");
	new potentialVotes = GetEventInt(event, "potentialVotes");
	LogMessage("Vote Changed event: yesVotes: %d, noVotes: %d, potentialVotes: %d",
		yesVotes, noVotes, potentialVotes);
	
}

/*
"vote_passed"
{
	"details"               "string"
	"param1"                "string"
	"team"                  "byte"
}
*/
public EventVotePassed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:details[128];
	decl String:param1[128];
	GetEventString(event, "details", details, sizeof(details));
	GetEventString(event, "param1", param1, sizeof(param1));
	new team = GetEventInt(event, "team");
	LogMessage("Vote Passed event: details: %s, param1: %s, team: %d", details, param1, team);
}

/*
"vote_failed"
{
	"team"                  "byte"
}
*/
public EventVoteFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	LogMessage("Vote Failed event: team: %d", team);
}

/*
"vote_cast_yes"
{
	"team"			"byte"
	"entityid"		"long"	// entity id of the voter
}
*/
public EventVoteCastYes(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new entityid = GetEventInt(event, "entityid");
	LogMessage("Vote Cast Yes event: team: %d, entityid: %d", team, entityid);
}

/*
"vote_cast_no"
{
	"team"			"byte"
	"entityid"		"long"	// entity id of the voter
}
*/
public EventVoteCastNo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new entityid = GetEventInt(event, "entityid");
	LogMessage("Vote Cast No event: team: %d, entityid: %d", team, entityid);
}

/*
VoteStart Structure
	- Byte      Team index voting
	- Byte      Unknown, always 1 for Yes/No, always 99 for Multiple Choice
	- String    Vote issue id
	- String    Vote issue text
	- Bool      false for Yes/No, true for Multiple choice
*/
public Action:MessageVoteStart(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:issue[MAX_ARG_SIZE];
	decl String:param1[MAX_ARG_SIZE];
	decl String:initiatorName[MAX_ARG_SIZE];
	new team = BfReadByte(bf);
	new initiator = BfReadByte(bf);
	BfReadString(bf, issue, sizeof(issue));
	BfReadString(bf, param1, sizeof(param1));
	BfReadString(bf, initiatorName, sizeof(initiatorName));
	
	LogMessage("VoteStart Usermessage (sent to %d users): team: %d, initiator: %d, issue: %s, param1: %s, initiatorName: %s", playersNum, team, initiator, issue, param1, initiatorName);
}

/*
VotePass Structure
	- Byte      Team index voting
	- String    Vote issue id
	- String    Vote winner (same as vote issue text for Yes/No?)
*/
public Action:MessageVotePass(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:issue[MAX_ARG_SIZE];
	decl String:param1[MAX_ARG_SIZE];
	
	new team = BfReadByte(bf);
	BfReadString(bf, issue, sizeof(issue));
	BfReadString(bf, param1, sizeof(param1));
	
	LogMessage("VotePass Usermessage (sent to %d users): team: %d, issue: %s, param1: %s", playersNum, team, issue, param1);
}

/*
VoteFailed Structure
	- Byte      Team index voting
	- Byte      Failure reason code (4 for Not Enough Votes, other values need testing)
*/  
public Action:MessageVoteFail(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(bf);
	
	LogMessage("VoteFail Usermessage (sent to %d users): team: %d", playersNum, team);
}

/*
CallVoteFailed
    - Byte		Team index voting
    - Short		Failure reason code
*/
public Action:MessageCallVoteFailed(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	//new reason = BfReadByte(bf);
	//new time = BfReadShort(bf);
	
	LogMessage("CallVoteFailed Usermessage (sent to %d users): bytes: %d", playersNum, BfGetNumBytesLeft(bf));
}

/*
VoteRegistered
    - Byte		Item selected
*/
public Action:MessageVoteRegistered(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new item = BfReadByte(bf);
	
	LogMessage("VoteRegistered Usermessage (sent to %d users): item: %d", playersNum, item);
}

public Action:CommandVote(client, const String:command[], argc)
{
	decl String:vote[MAX_ARG_SIZE];
	GetCmdArg(1, vote, sizeof(vote));
	
	LogMessage("vote command: client: %d, userid: %d, vote: %s", client, GetClientUserId(client), vote);
	return Plugin_Continue;
}

public Action:CommandCallVote(client, const String:command[], argc)
{
	decl String:args[255];
	GetCmdArgString(args, sizeof(args));
	
	LogMessage("callvote command: client: %N, command: %s", client, args);
}

public Action:CommandVoteFailed(client, argc)
{
	decl String:reasonString[2];
	GetCmdArg(1, reasonString, sizeof(reasonString));
	new reason = StringToInt(reasonString);
	
	new Handle:bf = StartMessageOne("VoteFailed", client, USERMSG_RELIABLE);
	BfWriteByte(bf, TEAM_ALL);
	BfWriteByte(bf, reason);
	EndMessage();
	
	return Plugin_Handled;
}

public Action:CommandCallVoteFail(client, argc)
{
	LogMessage("CallVoteFail arg number: %d", argc);
	decl String:reasonString[3];
	new other = -1;
	GetCmdArg(1, reasonString, sizeof(reasonString));
	if (argc > 1)
	{
		decl String:otherString[5];
		GetCmdArg(2, otherString, sizeof(otherString));
		other = StringToInt(otherString);
	}
	new reason = StringToInt(reasonString);
	
	new Handle:bf = StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE);
	BfWriteByte(bf, reason);
	BfWriteShort(bf, other);
	EndMessage();
	
	return Plugin_Handled;
}
