/***************************************************************************
 *  vog_matrix.sma
 *   version 1.1          Date: 25/03/2008
 *   Author: Frederik     frederik156@hotmail.com
 *   Alias: V0gelz
 *          
 *  I was playing around with menu's and with the voting system.
 *  So i tought why not make an other amx convertion.
 *  Matrix style jumping and voting, can only be enabled by admin.
 *  
 *  Commands:
 *   sm_matrix      -- toggles on and off matrix jumping
 *   sm_votematrix  -- starts a vote for matrix style jumping
 *
 *  To do a matrix jump, jump, and move back -- you will shoot forward in 
 *   a way simialr to the way they jump in the movie, The Matrix.
 *
 *  *5/5/08
 *  *Added support to TF2
 *
 ***************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Handle:Air;

new StartTime;
new LastVote;
new Handle:VoteDelay;
new Handle:VotesInterval;

public Plugin:myinfo =
{
	name = "Matrix Plugin",
	author = "V0gelz",
	description = "Matrix style jumping.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	RegAdminCmd( "sm_votematrix",	Matrix_Voting_Menu, ADMFLAG_VOTE, "Start a vote for the Matrix style juming." );
	RegAdminCmd("sm_matrix", Command_Matrix, ADMFLAG_VOTE, "Set matrix mode 1/0");
	
	RegConsoleCmd("say", Command_OnSay);

	Air = FindConVar("sv_airaccelerate");
	VoteDelay= CreateConVar("sm_matrix_vote_delay","60.0", "Time before the matrix vote is allowed after map start.", 0, true, 0.0, true, 1000.0);
	VotesInterval = CreateConVar("sm_matrix_vote_interval", "15.0", "Interval between vote casts.", 0, true, 0.0, true, 60.0);
	CreateConVar("sm_matrix_version", PLUGIN_VERSION, "", 0, true, 0.0, true, 60.0);
}

public OnMapStart()
{
	StartTime = GetTime();
}

public Action:Command_OnSay( client , args)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx;
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (StrContains(text[startidx], "matrix", false)  != -1)
	{
		new Air_Accelerate = GetConVarInt(Air);
		if(Air_Accelerate == -5)
		{
			PrintToChatAll("Matrix jumping is on!");
		}
		if(Air_Accelerate == 10)
		{
			PrintToChatAll("Boring normal jumping is on now.");
		}
	}

	return Plugin_Continue;
}

public Action:Matrix_Voting_Menu(client , Arguments)
{
	if (IsVoteInProgress())
	{
		PrintToConsole( client ,"[SM]  Voting has started...");
		return;
	}

	new nFromStart = GetTime() - StartTime;
	new nFromLast = GetTime() - LastVote;	

	new Air_Accelerate = GetConVarInt(Air);

	if(nFromLast >= GetConVarInt(VotesInterval))
	{
		if(nFromStart >= GetConVarInt(VoteDelay))
		{
			if(Air_Accelerate == 10)
			{
				new Handle:menu = CreateMenu(Handle_Matrix_VoteMenu);
				SetMenuTitle(menu, "Do you want Matrix style jumping?");
				AddMenuItem(menu, "yes", "Hand me the red pill!");
				AddMenuItem(menu, "no", "No thanks");
				SetMenuExitButton(menu, false);
				VoteMenuToAll(menu, 20);
			}
			if(Air_Accelerate == -5)
			{
				new Handle:menu = CreateMenu(Handle_Matrix_VoteMenu);
				SetMenuTitle(menu, "Do you want Normal style jumping?");
				AddMenuItem(menu, "yes", "Yes please!");
				AddMenuItem(menu, "no", "No thanks");
				SetMenuExitButton(menu, false);
				VoteMenuToAll(menu, 20);
			}
			LastVote = GetTime();
			PrintToConsole( client ,"[SM]  ADMIN !!! Ignore the <Unknown command: sm_votematrix> -- its ok");
			PrintToConsole( client ,"[SM]  Vote started...");
			PrintToChatAll("[SM]  The matrix vote has started!");
		}
		else
		{
			PrintToConsole( client ,"[SM]  Voting not allowed yet.");
		}
	}
	else
	{
		PrintToConsole( client ,"[SM]  Voting not allowed yet.");
	}

	//return Plugin_Continue;
}

public Handle_Matrix_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd)
	{
		new Air_Accelerate = GetConVarInt(Air);

		PrintToChatAll("[SM]  Vote has ended...");

		if(Air_Accelerate == 10)
		{
			/* 0=yes, 1=no */
			if (param1 == 0)
			{
				PrintToChatAll("Voting Results: Welcome to the Matrix !!!");
				SetConVarInt(Air_Accelerate, -5);
			}
			if (param1 == 1)
			{
				PrintToChatAll("Voting Results: Normal jumping will remain !!!");
			}
		}
		if(Air_Accelerate == -5)
		{
			/* 0=yes, 1=no */
			if (param1 == 0)
			{
				PrintToChatAll("Voting Results: Normal jumping is back !!!");
				SetConVarInt(Air_Accelerate, 10);
			}
			if (param1 == 1)
			{
				PrintToChatAll("Voting Results: Matrix will stay !!!");
			}
		}
	}
}

public Action:Command_Matrix(client, Arguments)
{
	//Error Check:
	if(Arguments < 1)
	{

		PrintToConsole(client, "[SM]  Usage: sm_matrix 1/0");
		return Plugin_Handled;
	}

	//Retrieve Arguments:
	new String:Given_Matrix[32], Converted_Matrix;
	GetCmdArg(1, Given_Matrix, sizeof(Given_Matrix));
		
	//Convert:
	StringToIntEx(Given_Matrix, Converted_Matrix);

	//Update:
	new Air_Accelerate = GetConVarInt(Air);
	
	new User[32];
	GetClientName(client,User,31);

	if(Converted_Matrix == 1)
	{
		PrintToConsole(client,"[SM]  MATRIX JUMPING mode is now ON");
		PrintToChatAll("[SM]  Admin %s has turned MATRIX JUMPING mode ON", User);
		SetConVarInt(Air_Accelerate, -5);
	}

	if(Converted_Matrix == 0)
	{
		PrintToConsole(client,"[SM]  MATRIX JUMPING mode is now OFF");
		PrintToChatAll("[SM]  Admin %s has turned MATRIX JUMPING mode OFF", User);
		SetConVarInt(Air_Accelerate, 10);
	}

	return Plugin_Handled;
}