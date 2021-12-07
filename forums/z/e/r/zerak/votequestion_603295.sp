#include <sourcemod>
#include <voteManager>

public Plugin:myinfo = 
{
	name = "votequestion",
	author = "Zerak",
	description = "Allows the creation of a user (admin) defined votes, ingame.",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?p=603295"
}

#define CVAR_FILE		"votequestion"

new Handle:g_Cvar_MaxVoteTime

public OnPluginStart()
{
	g_Cvar_MaxVoteTime = CreateConVar("sm_mapvote_maxvotetime", "20", "How long people are allowed to vote.", _,true, 20.0, true, 120.0)
	RegAdminCmd("sm_votequestion", Command_votequestion, ADMFLAG_VOTE, "An admin defined vote that is created based on it command arguments (parameters).")
	InitiateVoteManager() // voteManager
	
	AutoExecConfig(true, CVAR_FILE);
}

public Action:Command_votequestion(client, args)
{
	new nrCmds = GetCmdArgs()
	if(nrCmds < 1)
	{
		PrintToConsole(client, "sm_votequestion  <title> [<option1> <option2> ... <optionN>]")
	}
	else if( IsNewVoteAllowed() )
	{
		decl String:argBuffer[32]
		g_menu = CreateMenu(Handler_VoteMenu)
		SetMenuExitButton(g_menu, false)
		
		GetCmdArg(1, argBuffer, sizeof(argBuffer))
		SetMenuTitle(g_menu, argBuffer)
		
		if( nrCmds >= 3)
		{
			for( new i = 2; i <= nrCmds; i++)
			{
				GetCmdArg(i, argBuffer, sizeof(argBuffer))
				AddMenuItem(g_menu, argBuffer, argBuffer)
			}
		}
		else
		{
			AddMenuItem(g_menu, "Yes", "Yes")
			AddMenuItem(g_menu, "No", "No")
		}
		StartVoteToAll(g_menu, GetConVarInt(g_Cvar_MaxVoteTime)) // voteManager
	}
	else
	{
		PrintToConsole(client, "Please wait %i s and then try again.", CheckVoteDelay())
	}
	
	return Plugin_Handled
}

public Handler_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	VoteAction(action, param1, param2)	// voteManager
	switch (action)
	{
		case MenuAction_VoteStart:
		{
			LogMessage("Voting has started.")
			PrintToChatAll("Voting has started.")
		}
		case MenuAction_VoteEnd:
		{
			decl String:winner[64]
			GetMenuItem(menu, param1, winner, sizeof(winner))
			PrintHintTextToAll("Winner: %s", winner)
		}
		case MenuAction_Cancel:
		{
			PrintHintTextToAll("Vote has been cancelled.")
		}
		case MenuAction_End:
		{
			CloseHandle(g_menu)
			g_menu = INVALID_HANDLE
		}
	}
	
	return 0
}

public OnPluginEnd()
{
	if(g_menu != INVALID_HANDLE) // if plugin is unloaded or reloaded we will close the handle to avoid error messages
	{
		CancelMenu(g_menu)
	}
}