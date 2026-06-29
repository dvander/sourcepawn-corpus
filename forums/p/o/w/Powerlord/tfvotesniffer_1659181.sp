/* Sniff TF2 vote events, user messages, and commands */

#pragma semicolon 1

#include <sourcemod>

#define MAX_ARG_SIZE 33

public Plugin:myinfo = 
{
	name = "TF Vote Sniffer",
	author = "Powerlord",
	description = "Sniff voting events and usermessages",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	/*
	HookEvent("vote_started", EventVoteStarted);
	HookEvent("vote_ended", EventVoteEnded);
	HookEvent("vote_changed", EventVoteChanged);
	HookEvent("vote_passed", EventVotePassed);
	HookEvent("vote_failed", EventVoteFailed);
	HookEvent("vote_cast", EventVoteCast);
	HookEvent("vote_options", EventVoteOptions);
	HookUserMessage(GetUserMessageId("VoteSetup"), MessageVoteSetup);
	HookUserMessage(GetUserMessageId("VoteStart"), MessageVoteStart);
	HookUserMessage(GetUserMessageId("VotePass"), MessageVotePass);
	HookUserMessage(GetUserMessageId("VoteFail"), MessageVoteFail);
	HookUserMessage(GetUserMessageId("CallVoteFailed"), MessageCallVoteFailed);
	*/
	AddCommandListener(CommandVote, "vote");
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
		"vote_option1"          "byte"
		"vote_option2"          "byte"
		"vote_option3"          "byte"
		"vote_option4"          "byte"
		"vote_option5"          "byte"
		"potentialVotes"        "byte"
}
*/
public EventVoteChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new vote_option1 = GetEventInt(event, "vote_option1");
	new vote_option2 = GetEventInt(event, "vote_option2");
	new vote_option3 = GetEventInt(event, "vote_option3");
	new vote_option4 = GetEventInt(event, "vote_option4");
	new vote_option5 = GetEventInt(event, "vote_option5");
	new potentialVotes = GetEventInt(event, "potentialVotes");
	LogMessage("Vote Changed event: vote_option1: %d, vote_option2: %d, vote_option3: %d, vote_option4: %d, vote_option5: %d, potentialVotes: %d",
		vote_option1, vote_option2, vote_option3, vote_option4, vote_option5, potentialVotes);
	
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
"vote_cast"
{
		"vote_option"   "byte"  // which option the player voted on
		"team"                  "short"
		"entityid"              "long"  // entity id of the voter
}
*/
public EventVoteCast(Handle:event, const String:name[], bool:dontBroadcast)
{
	new vote_option = GetEventInt(event, "vote_option");
	new team = GetEventInt(event, "team");
	new entityid = GetEventInt(event, "entityid");
	LogMessage("Vote Cast event: vote_options: %d, team: %d, entityid: %d", vote_option, team, entityid);
}

/*
"vote_options"
{
		"count"                 "byte"  // Number of options - up to MAX_VOTE_OPTIONS
		"option1"               "string"
		"option2"               "string"
		"option3"               "string"
		"option4"               "string"
		"option5"               "string"
}
*/
public EventVoteOptions(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:option1[33];
	decl String:option2[33];
	decl String:option3[33];
	decl String:option4[33];
	decl String:option5[33];
	
	new count = GetEventInt(event, "count");
	GetEventString(event, "option1", option1, sizeof(option1));
	GetEventString(event, "option2", option2, sizeof(option2));
	GetEventString(event, "option3", option3, sizeof(option3));
	GetEventString(event, "option4", option4, sizeof(option4));
	GetEventString(event, "option5", option5, sizeof(option5));
	LogMessage("Vote Options event: count: %s, option1: %s, option2: %s, option3: %s, option4: %s, option5: %s", 
		count, option1, option2, option3, option4, option5);
}

/*
VoteSetup
	- Byte		Option count
	* String 	(multiple strings, presumably the vote options. put "  (Disabled)" without the quotes after the option text to disable one of  the options?)
*/

public Action:MessageVoteSetup(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new count = BfReadByte(bf);
	new String:options[1024];
	for (new i = 0; i < count; i++)
	{
		decl String:option[MAX_ARG_SIZE];
		BfReadString(bf, option, sizeof(option));
		StrCat(options, sizeof(options), option);
	}
	
	LogMessage("VoteSetup Usermessage: count: %d, options: %s", count, options);
	return Plugin_Continue;
}

/*
VoteStart Structure
	- Byte      Team index or -1 for all
	- Byte      Initiator client index or 99 for Server
	- String    Vote issue phrase
	- String    Vote issue phrase argument
	- Bool      false for Yes/No, true for Multiple choice
*/
public Action:MessageVoteStart(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:issue[MAX_ARG_SIZE];
	decl String:param1[MAX_ARG_SIZE];
	new team = BfReadByte(bf);
	new initiator = BfReadByte(bf);
	BfReadString(bf, issue, sizeof(issue));
	BfReadString(bf, param1, sizeof(param1));
	new multipleChoice = BfReadBool(bf);
	
	LogMessage("VoteStart Usermessage: team: %d, initiator: %d, issue: %s, param1: %s, multipleChoice: %d, player count: %d", team, initiator, issue, param1, multipleChoice, playersNum);
	return Plugin_Continue;
}

/*
VotePass Structure
	- Byte      Team index or -1 for all
	- String    Vote issue pass phrase
	- String    Vote issue pass phrase argument
*/
public Action:MessageVotePass(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:issue[MAX_ARG_SIZE];
	decl String:param1[MAX_ARG_SIZE];
	
	new team = BfReadBool(bf);
	BfReadString(bf, issue, sizeof(issue));
	BfReadString(bf, param1, sizeof(param1));
	
	LogMessage("VotePass Usermessage: team: %d, issue: %s, param1: %s", team, issue, param1);
	return Plugin_Continue;
}

/*
VoteFail Structure
	- Byte      Team index or -1 for all
	- Byte      Failure reason code (0, 3, or 4)
*/  
public Action:MessageVoteFail(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(bf);
	new reason = BfReadByte(bf);
	
	LogMessage("VoteFail Usermessage: team: %d, reason: %d", team, reason);
	return Plugin_Continue;
}

/*
CallVoteFailed
    - Byte		Failure reason code (1, 2, 5-15)
    - Short		Time until new vote allowed for code 2
*/
public Action:MessageCallVoteFailed(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new reason = BfReadByte(bf);
	new time = BfReadShort(bf);
	
	LogMessage("CallVoteFailed Usermessage: reason: %d, time: %d", reason, time);
	return Plugin_Continue;
}

/*
Vote command
    - String		option1 through option5
 */
public Action:CommandVote(client, const String:command[], argc)
{
	decl String:vote[MAX_ARG_SIZE];
	GetCmdArg(1, vote, sizeof(vote));
	
	LogMessage("%N used vote command: %s %s", client, command, vote);
	return Plugin_Continue;
}
