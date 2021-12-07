#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Admin Custom Votes",
	author = "Tylerst",
	description = "Create a custom vote and execute the result",
	version = PLUGIN_VERSION,
	url = "none"
}

new Handle:hLog = INVALID_HANDLE;

new String:g_command[32];
new g_admin;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_acvote_version", PLUGIN_VERSION, "Create custom votes and execute result", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hLog = CreateConVar("sm_acvote_log", "1", "Enable/Disable Logging custom admin votes");

	RegAdminCmd("sm_acvote", Command_ACVote, ADMFLAG_VOTE, "Create a custom vote and execute the result, Usage: sm_acvote \"command\" \"title\" \"choice1\" \"choice1title\" \"choice2\" \"choice2title\" \"choice3\" \"choice3title\" \"choice4\" \"choice4title\" \"choice5\" \"choice5title\"");
}

public Action:Command_ACVote(client, args)
{
	if(args < 6 || args > 12)
	{
		ReplyToCommand(client, "[SM] Usage: sm_acvote \"command\" \"title\" \"choice1\" \"choice1title\" \"choice2\" \"choice2title\" (Optional)\"choice3\" \"choice3title\" \"choice4\" \"choice4title\" \"choice5\" \"choice5title\"");
		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}

	new String:title[32], String:choices[5][32], String:choicetitles[5][32], choicecount;
	GetCmdArg(1, g_command, sizeof(g_command));
	GetCmdArg(2, title, sizeof(title));
	GetCmdArg(3, choices[0], sizeof(choices[]));
	GetCmdArg(4, choicetitles[0], sizeof(choicetitles[]));
	GetCmdArg(5, choices[1], sizeof(choices[]));
	GetCmdArg(6, choicetitles[1], sizeof(choicetitles[]));
	choicecount = 2;
	if(args >= 8)
	{
		GetCmdArg(7, choices[2], sizeof(choices[]));
		GetCmdArg(8, choicetitles[2], sizeof(choicetitles[]));
		choicecount++;
	}
	if(args >= 10)
	{
		GetCmdArg(9, choices[3], sizeof(choices[]));
		GetCmdArg(10, choicetitles[3], sizeof(choicetitles[]));
		choicecount++;
	}
	if(args == 12)
	{
		GetCmdArg(11, choices[4], sizeof(choices[]));
		GetCmdArg(12, choicetitles[4], sizeof(choicetitles[]));
		choicecount++;
	}
	
	new Handle:ACVote = CreateMenu(MenuHandle_ACVote);

	SetMenuTitle(ACVote, title);
	for(new i = 0; i < choicecount; i++)
	{
		AddMenuItem(ACVote, choices[i], choicetitles[i]);
	}
	SetMenuExitButton(ACVote, false);
	g_admin = client;
	VoteMenuToAll(ACVote, 20);


	if(GetConVarBool(hLog)) LogMessage("\"%L\" created admin custom vote \"%s\" to run \"%s\"", client, title, g_command);
	ShowActivity2(client, "\x01[SM] ","\x04Created Vote:\x01 \"%s\"", title);

	return Plugin_Handled;
}



public MenuHandle_ACVote(Handle:votemenu, MenuAction:action, voteresult, votecountinfo)
{
	if (action == MenuAction_End) CloseHandle(votemenu);
	else if (action == MenuAction_VoteEnd) 
	{
		new String:commandparam[32], String:resultname[32], winvotecount, totalvotecount;
		GetMenuItem(votemenu, voteresult, commandparam, sizeof(commandparam),_,resultname, sizeof(resultname));
		GetMenuVoteInfo(votecountinfo, winvotecount, totalvotecount);
		if(g_admin == 0) ServerCommand("%s %s", g_command, commandparam);
		else FakeClientCommand(g_admin, "%s %s", g_command, commandparam);
		
		if(GetConVarBool(hLog)) LogMessage("Vote Result: \"%L\" ran \"%s %s\", Received %i of %i votes", g_admin, g_command, commandparam, winvotecount, totalvotecount);
		PrintToChatAll("\x01[SM] \x04Winning choice: \"%s\" \x01- Received %i of %i votes", resultname, winvotecount, totalvotecount);
	}
}