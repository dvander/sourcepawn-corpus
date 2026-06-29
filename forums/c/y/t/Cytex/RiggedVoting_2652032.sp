#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Cysex"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Rigged Voting", 
	author = PLUGIN_AUTHOR, 
	description = "Let's users' choose which vote option wins",
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/cyt3xx/"
};

Menu g_hVoteMenu = null;	// Vote Menu
char g_voteArg[256];		// Used to hold vote questions

int g_iWinner;				// Winning Option Integer
char g_sWinnerString[256];	// Winning Option String

public void OnPluginStart()
{
	RegAdminCmd("sm_rvote", Command_Vote, ADMFLAG_KICK, "[SM] Usage: sm_rvote <Question> [Ans1] [Ans2]...[Ans5] <Winning option>");
	
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("plugin.basecommands");
	
	AutoExecConfig(true, "basevotes");
}

public Action Command_Vote(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rvote <Question> [Ans1] [Ans2]...[Ans5] <Winning option>");
		return Plugin_Handled;
	}
	if (args > 7)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rvote <Question> [Ans1] [Ans2]...[Ans5] <Winning option>");
		return Plugin_Handled;
	}	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
	if (!TestVoteDelay(client))
	{
		return Plugin_Handled;
	}
	
	char winnerNum[2];		// Convert winning option to int from string
	GetCmdArg(args, winnerNum, sizeof(winnerNum));
	g_iWinner = StringToInt(winnerNum);
	
	char question[256];		// Save question string to g_voteArg
	GetCmdArg(1, question, sizeof(question));
	g_voteArg = question;
	
	g_hVoteMenu = new Menu(Handler_VoteCallback, MENU_ACTIONS_ALL);		// Set title for the vote menu
	g_hVoteMenu.SetTitle("%s?", g_voteArg);	
	
	char answers[5][64];
	int answerCount = args - 2;
	
	if (g_iWinner > answerCount)	// Check if winning option's number is too large
	{
		ReplyToCommand(client, "[SM] Usage: sm_rvote <Question> [Ans1] [Ans2]...[Ans5] <Winning option>");
		return Plugin_Handled;	
	}
	
	for (int i = 2; i < args; i++) 		// Store options into answers array
	{
		GetCmdArg(i, answers[i - 2], 64);
	}
	for (int i = 0; i < answerCount; i++)		// Adds options to voting menu
	{
		g_hVoteMenu.AddItem(answers[i], answers[i]);
	}	

	g_hVoteMenu.ExitButton = false;		// Hide the exit vote button and start the vote with 15 seconds until vote ends
	g_hVoteMenu.DisplayVoteToAll(15);		
	
	g_sWinnerString = answers[g_iWinner - 1];		// Store winning option into g_sWinnerString
	
	return Plugin_Handled;	
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
		char title[64];
		menu.GetTitle(title, sizeof(title));
	}
	else if (action == MenuAction_DisplayItem)
	{
		char display[64];
		menu.GetItem(param2, "", 0, _, display, sizeof(display));
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %t", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		char item[64], display[64];
		float percent;
		int votes, totalVotes;

		GetMenuVoteInfo(param2, votes, totalVotes);
		menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
		
		percent = GetVotePercent(votes, totalVotes);

		PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
		PrintToChatAll("[SM] %t", "Vote End", g_voteArg, g_sWinnerString);		
	}
	
	return 0;
}

float GetVotePercent(int votes, int totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

void VoteMenuClose()
{
	delete g_hVoteMenu;
}

bool TestVoteDelay(int client)
{
 	int delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			ReplyToCommand(client, "[SM] %t", "Vote Delay Minutes", delay % 60);
 		}
 		else
 		{
 			ReplyToCommand(client, "[SM] %t", "Vote Delay Seconds", delay);
 		}
 		
 		return false;
 	}
 	
	return true;
}
