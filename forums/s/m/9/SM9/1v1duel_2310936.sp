/****************************************************************************************************
[CS:GO] MULTI1V1: Duel Addon (Private)
*****************************************************************************************************/

/****************************************************************************************************
CHANGELOG
*****************************************************************************************************
* 
* 0.1	     - 
* 
* 				First Release.
*/

/****************************************************************************************************
TO BE DONE
*****************************************************************************************************
* - Fixes / optimizations / suggestions..
*/

/****************************************************************************************************
INCLUDES
*****************************************************************************************************/
#include <multi1v1>
#include <queue>

/****************************************************************************************************
DEFINES
*****************************************************************************************************/
#define VERSION "0.1"

/****************************************************************************************************
ETIQUETTE.
*****************************************************************************************************/
#pragma newdecls required // To be moved before includes one day.
#pragma semicolon 1

/****************************************************************************************************
PLUGIN INFO.
*****************************************************************************************************/

public Plugin myinfo = {
	name = "Multi 1v1: Duel Addon",
	author = "SM9",
	description = "Allows players to duel with each other",
	version = "0.1",
	url = "https://www.fragdeluxe.ccm"
};

/****************************************************************************************************
CONVAR HANDLES.
*****************************************************************************************************/

/****************************************************************************************************
INTS.
*****************************************************************************************************/
int iDuelOpponent[MAXPLAYERS+1];
int iPotentialOpponent[MAXPLAYERS+1];
int iBestOf[MAXPLAYERS+1];
int iDeaths[MAXPLAYERS+1];

/****************************************************************************************************
STRINGS.
*****************************************************************************************************/
char chMessagePrivate[512][MAXPLAYERS+1];

/****************************************************************************************************
BOOLEANS.
*****************************************************************************************************/
bIsDueling[MAXPLAYERS +1];

/****************************************************************************************************
FLOATS.
*****************************************************************************************************/

public void OnPluginStart()
{	
	AddCommandListener(CommandListener, "say");
	AddCommandListener(CommandListener, "say_team");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode);
}

public void OnMapEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if(IsValidClient(iClient))
		{
			CancelDuel(iClient, iDuelOpponent[iClient]);
		}
	}
}

public void OnMapStart()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if(IsValidClient(iClient))
		{
			CancelDuel(iClient, iDuelOpponent[iClient]);
		}
	}
}

public void Multi1v1_OnPreArenaRankingsSet(Handle rankingQueue)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if(IsValidClient(iClient) && bIsDueling[iClient] && iDuelOpponent[iClient] > 0)
		{
			Queue_Enqueue(rankingQueue, iClient);
			Queue_Enqueue(rankingQueue, iDuelOpponent[iClient]);
		}
	}
}

public int Event_PlayerDeath(Handle hEvent, char[] chName, bool bDontBroadcast)
{
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent,"attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(hEvent,"userid"));
	
	if(iDuelOpponent[iAttacker] == iVictim)
	{
		iDeaths[iVictim]++;
		
		switch(iBestOf[iVictim])
		{
			case 3:
			{
				if(iDeaths[iVictim] >= 2)
				{
					DuelWinner(iAttacker, iVictim);
				}
			}
			
			case 5:
			{
				if(iDeaths[iVictim] >= 3)
				{
					DuelWinner(iAttacker, iVictim);
				}
			}
		}
	}
}

public Action CommandListener(int iClient, const char[] ChCommand, int iArg)
{
	char chText[192];
	GetCmdArgString(chText, sizeof(chText));
	StripQuotes(chText);
	
	if(strcmp(chText, "!duel") == 0 || strcmp(chText, "/duel") == 0 || strcmp(chText, "!challenge") == 0 || strcmp(chText, "/challenge") == 0)
	{
		DuelChecks(iClient);
		return Plugin_Handled;
	}
	
	if(strcmp(chText, "!cancelduel") == 0 || strcmp(chText, "/cancelduel") == 0 || strcmp(chText, "!cduel") == 0 || strcmp(chText, "/cduel") == 0)
	{
		if(bIsDueling[iClient] && iDuelOpponent[iClient] > 0)
		{
			PostPoneDuel(iClient);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void DuelChecks(int iClient)
{
	if(GetActivePlayersCount() < 6)
	{
		Multi1v1_Message(iClient, "A minimum of 6 players is needed.");
	}
	
	else if(GetOpenDuelSlots() < 1)
	{
		Multi1v1_Message(iClient, "There are no duel slots open, please wait for a duel to finish.");
	}
	
	if(iDuelOpponent[iClient] > 0)
	{
		Multi1v1_Message(iClient, "You are already in a duel with {LIGHT_GREEN}%N{NORMAL}!", iDuelOpponent[iClient]);
	}
	
	if(iPotentialOpponent[iClient] > 0)
	{
		Multi1v1_Message(iClient, "Please wait for {LIGHT_GREEN}%N{NORMAL} to decide on your duel request.", iPotentialOpponent[iClient] );
	}
	
	else if(GetOpenDuelSlots() >= 1 && !bIsDueling[iClient] && iPotentialOpponent[iClient] < 1 && GetActivePlayersCount() >= 6)
	{
		OpponentSelection(iClient);
	}
}

public void OpponentSelection(int iClient)
{
	Menu hMenu = CreateMenu(MenuHandler_DuelOpponent);
	
	hMenu.SetTitle("Choose your opponent");
	hMenu.ExitBackButton = true;
	
	char iClientId[16];
	char charName[86];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && i != iClient && !bIsDueling[iClient] && iPotentialOpponent[iClient] < 1 && iDuelOpponent[iClient] < 1)
		{
			IntToString(GetClientUserId(i), iClientId, sizeof(iClientId));
			Format(charName, sizeof(charName), "%N", i);
			hMenu.AddItem(iClientId, charName);
		}
	}
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_DuelOpponent(Menu hMenu, MenuAction maOption, int iClient, int iParam2)
{
	if(maOption == MenuAction_End)
	{
		delete hMenu;
	}
	
	else if(maOption == MenuAction_Select)
	{
		char chOpponentInfo[32];
		hMenu.GetItem(iParam2, chOpponentInfo, sizeof(chOpponentInfo));
		int iOpponent = GetClientOfUserId(StringToInt(chOpponentInfo));
		
		if(IsValidClient(iOpponent))
		{
			if(iPotentialOpponent[iOpponent] > 1 && iPotentialOpponent[iOpponent] != iClient)
			{
				Multi1v1_Message(iClient, "{LIGHT_GREEN}%N{NORMAL} is already deciding on %N's challenge.", iOpponent, iPotentialOpponent[iOpponent]);
			}
			
			if(iDuelOpponent[iOpponent] > 1 && iDuelOpponent[iOpponent] != iClient)
			{
				Multi1v1_Message(iClient, "{LIGHT_GREEN}%N{NORMAL} is already in a duel with %N", iOpponent, iDuelOpponent[iOpponent]);
			}
			
			else if(iPotentialOpponent[iOpponent] < 1 && iDuelOpponent[iOpponent] < 1)
			{
				BestOfMenu(iClient, iOpponent);
			}
		}
		
		else
		{
			Multi1v1_Message(iClient, "Your Opponent is no longer available.");
			CancelDuel(iClient, iPotentialOpponent[iClient]);
		}
	}
}

public void BestOfMenu(int iClient, int iChallenger)
{
	Menu hMenu = CreateMenu(BestOf_Handler);
	SetMenuTitle(hMenu, "Duel Length?");
	
	hMenu.AddItem("0", "Best of 3");
	hMenu.AddItem("1", "Best of 5");
	hMenu.AddItem("2", "Till map end");
	
	iPotentialOpponent[iClient] = iChallenger;
	iPotentialOpponent[iChallenger] = iClient;
	
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int BestOf_Handler(Menu hMenu, MenuAction maOption, int iClient, int iItem)
{
	if(maOption == MenuAction_End)
	{
		CancelDuel(iClient, iPotentialOpponent[iClient]);
		delete hMenu;
	}
	
	else if(maOption == MenuAction_Select)
	{
		char chInfo[64];
		hMenu.GetItem(iItem, chInfo, sizeof(chInfo));
		int iOpponent = iPotentialOpponent[iClient];
		
		if(IsValidClient(iOpponent))
		{
			if(iPotentialOpponent[iOpponent] > 1 && iPotentialOpponent[iOpponent] != iClient)
			{
				Multi1v1_Message(iClient, "{LIGHT_GREEN}%N{NORMAL} is already deciding on %N's challenge.", iOpponent, iPotentialOpponent[iOpponent]);
			}
			
			if(iDuelOpponent[iOpponent] > 1 && iDuelOpponent[iOpponent] != iClient)
			{
				Multi1v1_Message(iClient, "{LIGHT_GREEN}%N{NORMAL} is already in a duel with %N", iOpponent, iDuelOpponent[iOpponent]);
			}
			
			else if(iPotentialOpponent[iOpponent] == iClient && iDuelOpponent[iOpponent] < 1)
			{
				if(strcmp(chInfo, "0") == 0) 
				{
					iBestOf[iClient] = 3;
					Format(chMessagePrivate[iClient], sizeof(chMessagePrivate), "%N has challenged you to to a duel [Best of {LIGHT_GREEN}3{NORMAL}]", iClient);
				}
				
				else if(strcmp(chInfo, "1") == 0)
				{
					iBestOf[iClient] = 5;
					Format(chMessagePrivate[iClient], sizeof(chMessagePrivate), "%N has challenged you to to a duel [Best of {LIGHT_GREEN}5{NORMAL}]", iClient);
				}
				
				else if(strcmp(chInfo, "1") == 0)
				{
					iBestOf[iClient] = 1337;
					Format(chMessagePrivate[iClient], sizeof(chMessagePrivate), "%N has challenged you to to a duel [{LIGHT_GREEN}Till map end{NORMAL}]", iClient);
				}
				
				RequestDuel(iOpponent, iClient);
			}
		}
		
		else
		{
			Multi1v1_Message(iClient, "Your Opponent is no longer available.");
			CancelDuel(iClient, iPotentialOpponent[iClient]);
		}
	}
}

public void RequestDuel(int iClient, int iChallenger)
{
	Menu hMenu = CreateMenu(Decision_Handler);
	SetMenuTitle(hMenu, "Do you Accept %N's Duel?", iChallenger);
	
	hMenu.AddItem("0", "Yes");
	hMenu.AddItem("1", "No");
	
	iPotentialOpponent[iClient] = iChallenger;
	iPotentialOpponent[iChallenger] = iClient;
	
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
	
	Multi1v1_Message(iClient, chMessagePrivate[iChallenger]);
}

public int Decision_Handler(Menu hMenu, MenuAction maOption, int iClient, int iItem)
{
	int iChallenger = iPotentialOpponent[iClient];
	
	if(maOption == MenuAction_End)
	{
		CancelDuel(iClient, iPotentialOpponent[iClient]);
		delete hMenu;
	}
	
	else if(maOption == MenuAction_Select)
	{
		if(IsValidClient(iChallenger))
		{
			char chInfo[64];
			hMenu.GetItem(iItem, chInfo, sizeof(chInfo));
			
			if(strcmp(chInfo, "0") == 0) 
			{
				Multi1v1_Message(iChallenger, "%N has {GREEN}accepted{NORMAL} your duel!", iClient);
				SetupDuel(iChallenger, iBestOf[iChallenger], iClient);
			}
			
			else if(strcmp(chInfo, "1") == 0)
			{
				Multi1v1_Message(iChallenger, "%N has {LIGHT_RED}declined{NORMAL} your duel!", iClient);
				CancelDuel(iClient, iChallenger);
			}
			
			iPotentialOpponent[iClient] = 0;
			iPotentialOpponent[iChallenger] = 0;
		}
		
		else
		{
			Multi1v1_Message(iClient, "Your Opponent is no longer available.");
			CancelDuel(iClient, iPotentialOpponent[iClient]);
		}
	}
}

public int SetupDuel(int iDueler1, int iBest, int iDueler2)
{
	if(IsValidClient(iDueler1) && IsValidClient(iDueler2))
	{
		iBestOf[iDueler1] = iBest;
		iBestOf[iDueler2] = iBest;
		
		iDuelOpponent[iDueler1] = iDueler2;
		iDuelOpponent[iDueler2] = iDueler1;
		
		bIsDueling[iDueler1] = true;
		bIsDueling[iDueler2] = true;
		
		switch(iBest)
		{
			case 3: Multi1v1_MessageToAll("{LIGHT_GREEN}%N{NORMAL} and {LIGHT_GREEN}%N{NORMAL} are now dueling [Best of {LIGHT_GREEN}3{NORMAL}]", iDueler1, iDueler2);
			case 5: Multi1v1_MessageToAll("{LIGHT_GREEN}%N{NORMAL} and {LIGHT_GREEN}%N{NORMAL} are now dueling [Best of {LIGHT_GREEN}5{NORMAL}]", iDueler1, iDueler2);
			case 1337: Multi1v1_MessageToAll("{LIGHT_GREEN}%N{NORMAL} and {LIGHT_GREEN}%N{NORMAL} are now dueling [{LIGHT_GREEN}Till map end{NORMAL}] ", iDueler1, iDueler2);
		}
	}
	
	else
	{
		CancelDuel(iDueler1, iDueler2);
	}
}

public int DuelWinner(int iWinner, int iLoser)
{
	switch(iBestOf[iWinner])
	{
		case 3: Multi1v1_MessageToAll("{LIGHT_GREEN}%N{NORMAL} has won the duel facing {LIGHT_GREEN}%N{NORMAL} [Best of {LIGHT_GREEN}3{NORMAL}]", iWinner, iLoser);
		case 5: Multi1v1_MessageToAll("{LIGHT_GREEN}%N{NORMAL} has won the duel facing {LIGHT_GREEN}%N{NORMAL} [Best of {LIGHT_GREEN}5{NORMAL}]", iWinner, iLoser);
	}
	
	CancelDuel(iWinner, iLoser);
}

public void OnClientDisconnect(int iClient) 
{
	PostPoneDuel(iClient);
}

public int PostPoneDuel(int iClient)
{
	if(bIsDueling[iClient] && iDuelOpponent[iClient] > 0)
	{
		Multi1v1_MessageToAll("{LIGHT_GREEN}%N{NORMAL} is a big chicken, and left his duel. {LIGHT_GREEN}%N{NORMAL} has won.", iClient, iDuelOpponent[iClient]);
		CancelDuel(iClient, iDuelOpponent[iClient]);
	}
	
	ResetVariables(iClient);
}

public int CancelDuel(int iDueler1, int iDueler2)
{
	ResetVariables(iDueler1);
	ResetVariables(iDueler2);
}

stock int ResetVariables(int iClient)
{
	iDuelOpponent[iClient] = 0;
	iPotentialOpponent[iClient] = 0;
	iBestOf[iClient] = 0;
	iDeaths[iClient] = 0;
	bIsDueling[iClient] = false;
}

stock int GetActivePlayersCount()
{
	int iCount = 0;
	
	for(int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if(IsValidClient(iClient) && GetClientTeam(iClient) > 1)
			iCount++;
	}
	
	return iCount;
}

stock int GetMaxDuels()
{
	return GetActivePlayersCount() / 3;
}

stock int GetDuelingPlayerCount()
{
	int iCount = 0;
	
	for(int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		if(IsValidClient(iClient) && bIsDueling[iClient] && iDuelOpponent[iClient] > 0)
			iCount++;
	}
	
	return iCount;
}

stock int GetActiveDuels()
{
	return GetDuelingPlayerCount() / 2;
}

stock int GetOpenDuelSlots()
{
	return GetMaxDuels() - GetActiveDuels();
}

stock bool IsValidClient(int iClient) 
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient) || !IsClientAuthorized(iClient) || IsFakeClient(iClient)) 
		return false; 
	
	return true; 
}