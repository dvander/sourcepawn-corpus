#pragma semicolon 1
#include <sourcemod>
#include <nativevotes>
#include <colors>

new String:sDifficulty[12];
Handle g_hCurrentDifficulty = INVALID_HANDLE;
new Float:g_fVoteTime, bool:g_bAllowVoteDifficulty;

public Plugin myinfo = 
{
    name = "Difficulty vote", 
    author = "DannyD", 
    description = "Vote for the difficulty", 
    version = "2.0", 
    url = "https://forums.alliedmods.net/showthread.php?p=2574815"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_votedifficulty", Command_VoteDifficulty);
	RegConsoleCmd("sm_diff", Command_VoteDifficulty);
	g_hCurrentDifficulty = FindConVar("z_difficulty");
	g_fVoteTime = GetConVarFloat(FindConVar("sv_vote_timer_duration"));
	
	new Handle:g_hGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hGameMode, ConVarChange_GameMode);
	decl String:sGameMode[12];
	GetConVarString(g_hGameMode, sGameMode, 12);
	g_bAllowVoteDifficulty = true;
	if (StrEqual(sGameMode, "coop", false) || StrEqual(sGameMode, "realism", false))
	{
		g_bAllowVoteDifficulty = false;
	}
	
	LoadTranslations("difficultyvote.phrases");
}

public ConVarChange_GameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		g_bAllowVoteDifficulty = true;
		if (StrEqual(newValue, "coop", false) || StrEqual(newValue, "realism", false))
		{
			g_bAllowVoteDifficulty = false;
		}
	}
}

public Action:Command_VoteDifficulty(client, args)
{
	if (!client)
	{
		PrintToServer("Difficulty vote can only be started from game!");
		return Plugin_Handled;
	}
	
	if (!g_bAllowVoteDifficulty)
	{
		CPrintToChat(client, "%t", "Not_allow");
		return Plugin_Handled;
	}
	
	if (NativeVotes_IsVoteInProgress() || !NativeVotes_IsNewVoteAllowed())
	{
		CPrintToChat(client, "%t", "Vote_in_progress");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sDifficulty, sizeof(sDifficulty));
	if (args == 1 && (StrEqual(sDifficulty, "easy", false) || StrEqual(sDifficulty, "normal", false) || StrEqual(sDifficulty, "hard", false) || StrEqual(sDifficulty, "impossible", false)))
	{
		if (GetClientTeam(client) != 2)
		{
			CPrintToChat(client, "%t", "Not_survivor");
			return Plugin_Handled;
		}
		
		char sCurrentDifficulty[12];
		GetConVarString(g_hCurrentDifficulty, sCurrentDifficulty, sizeof(sCurrentDifficulty));
		if (StrEqual(sDifficulty, sCurrentDifficulty, false))
		{
			CPrintToChat(client, "%t", "Already_enabled", sDifficulty);
			return Plugin_Handled;
		}
		
		Handle vote = NativeVotes_Create(MenuHandler_VoteDifficulty, NativeVotesType_Custom_YesNo);
		NativeVotes_SetInitiator(vote, client);
		
		char sDetails[256];
		FormatEx(sDetails, sizeof(sDetails), "Change difficulty to %s?", sDifficulty);
		NativeVotes_SetDetails(vote, sDetails);
		NativeVotes_DisplayToAll(vote, RoundToNearest(g_fVoteTime)); //or "NativeVotes_DisplayToAllNonSpectators"
	}
	else
	{
		CPrintToChat(client, "%t", "Usage");
	}
	
	return Plugin_Handled;
}

public int MenuHandler_VoteDifficulty(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_YES)
			{
				char sDetails[256];
				FormatEx(sDetails, sizeof(sDetails), "Game difficulty changed to: %s", sDifficulty);
				NativeVotes_DisplayPass(menu, sDetails);
				SetConVarString(g_hCurrentDifficulty, sDifficulty);
				CreateTimer(3.0, ChangedDifficulty, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Loses);
			}
		}
 		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Generic);
			}
		}
 		case MenuAction_End:
		{
			NativeVotes_Close(menu);
		}
	}
}

public Action ChangedDifficulty(Handle timer)
{
	CPrintToChatAll("%t", "Difficulty_changed", sDifficulty);
}