#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "LaFF && Sniper007"
#define PLUGIN_VERSION "2.0"

#include <sourcemod>
#include <sdktools>


#pragma newdecls required

bool g_bIsActiveQuiz = false;
bool g_bPrikladPlus = false;
bool g_bPrikladKrat = false;
bool g_bPrikladMinus = false;

ConVar g_cMinNumberForPlusMinus;
ConVar g_cMaxNumberForPlusMinus;
ConVar g_cMinNumberForK;
ConVar g_cMaxNumberForK;
ConVar g_cAdminsSeeAnswer;
ConVar g_cMoneyForPlusMinus;
ConVar g_cMoneyForK;
ConVar g_cTimeBetweenQ;

public Plugin myinfo = 
{
	name = "automated quiz system for zephyrus store", 
	author = PLUGIN_AUTHOR, 
	description = "Events / quizes for zephyrus store", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	
	g_cTimeBetweenQ = CreateConVar("sm_time_between", "120", "Time between each questions");
	g_cMinNumberForPlusMinus = CreateConVar("sm_min_pm", "1", "Min number of the question + -");
	g_cMaxNumberForPlusMinus = CreateConVar("sm_max_pm", "200", "Max number of the question + -");
	g_cMinNumberForK = CreateConVar("sm_min_k", "1", "Minimum number of the question *");
	g_cMaxNumberForK = CreateConVar("sm_max_k", "20", "Max number of the question *");
	g_cAdminsSeeAnswer = CreateConVar("sm_admin_see_message", "1", "do you want admins to see the message? 0 = off 1 = on", _, true, 0.0, true, 1.0);
	g_cMoneyForPlusMinus = CreateConVar("sm_money_for_plusminus", "100", "Money for plus minus question");
	g_cMoneyForK = CreateConVar("sm_money_for_multiple", "100", "Money for * question");
	
	AutoExecConfig(true, "QuizZephyrus");
	
	CreateTimer(g_cTimeBetweenQ.FloatValue, quiz, _, TIMER_REPEAT);
}

int vysledekk;
int vysledekp;
int vysledekm;
int randomcislok1;
int randomcislok2;
int randomcislop1;
int randomcislop2;
int randomcislom1;
int randomcislom2;

public Action quiz(Handle timer)
{
	CreateTimer(20.00, EndQuiz);
	randomcislok1 = GetRandomInt(g_cMinNumberForK.IntValue, g_cMaxNumberForK.IntValue);
	randomcislok2 = GetRandomInt(g_cMinNumberForK.IntValue, g_cMaxNumberForK.IntValue);
	randomcislop1 = GetRandomInt(g_cMinNumberForPlusMinus.IntValue, g_cMaxNumberForPlusMinus.IntValue);
	randomcislop2 = GetRandomInt(g_cMinNumberForPlusMinus.IntValue, g_cMaxNumberForPlusMinus.IntValue);
	randomcislom1 = GetRandomInt(g_cMinNumberForPlusMinus.IntValue, g_cMaxNumberForPlusMinus.IntValue);
	randomcislom2 = GetRandomInt(g_cMinNumberForPlusMinus.IntValue, g_cMaxNumberForPlusMinus.IntValue);
	vysledekp = randomcislop1 + randomcislop2;
	vysledekk = randomcislok1 * randomcislok2;
	vysledekm = randomcislom1 - randomcislom2;
	int randomznak = GetRandomInt(1, 3);
	
	if (randomznak == 1) // +
	{
		g_bPrikladPlus = true;
		PrintToChatAll("\x01[\x10QUIZ\x01]\x03How much is %i + %i ", randomcislop1, randomcislop2);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsAdmin(i) && g_cAdminsSeeAnswer.IntValue == 1)
			{
				PrintToChat(i, "\x01[\x10QUIZ\x01]\x03The answer is %i", vysledekp);
			}
		}
	}
	
	if (randomznak == 2) // *
	{
		g_bPrikladKrat = true;
		PrintToChatAll("\x01[\x10QUIZ\x01]\x03how much is %i * %i ", randomcislok1, randomcislok2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsAdmin(i) && g_cAdminsSeeAnswer.IntValue == 1)
			{
				PrintToChat(i, "\x01[\x10QUIZ\x01]\x03The answer is %i", vysledekk);
			}
		}
	}
	
	if (randomznak == 3) // -
	{
		g_bPrikladMinus = true;
		PrintToChatAll("\x01[\x10QUIZ\x01]\x03 How much is %i - %i ", randomcislom1, randomcislom2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsAdmin(i) && g_cAdminsSeeAnswer.IntValue == 1)
			{
				PrintToChat(i, "\x01[\x10QUIZ\x01]\x03 The answer is %i", vysledekm);
			}
		}
	}
	
	g_bIsActiveQuiz = true;
}

public Action Command_Say(int client, const char[] command, int args)
{
	
	if (g_bIsActiveQuiz)
	{
		char szNumber[128];
		GetCmdArg(1, szNumber, sizeof(szNumber));
		int iNumber = StringToInt(szNumber);
		if (g_bPrikladPlus)
		{
			if (iNumber == vysledekp)
			{
				PrintToChatAll("\x01[\x10QUIZ\x01]\x03%N won and the answer of %i + %i is %i", client, randomcislop1, randomcislop2, vysledekp);
				ResetAllVariables();
				ServerCommand("sm_givecredits #%i %i", GetClientUserId(client), g_cMoneyForPlusMinus.IntValue);
			}
			else if (iNumber != vysledekp)
			{
				return Plugin_Handled;
			}
		}
		if (g_bPrikladKrat)
		{
			if (iNumber == vysledekk)
			{
				
				PrintToChatAll("\x01[\x10QUIZ\x01]\x03%N won and the answer of %i * %i is %i", client, randomcislok1, randomcislok2, vysledekk);
				ResetAllVariables();
				ServerCommand("sm_givecredits #%i %i", GetClientUserId(client), g_cMoneyForK.IntValue);
			}
		}
		if (g_bPrikladMinus)
		{
			if (iNumber == vysledekm)
			{
				
				PrintToChatAll("\x01[\x10QUIZ\x01]\x03%N won and the answer of %i - %i is %i", client, randomcislom1, randomcislom2, vysledekm);
				ResetAllVariables();
				ServerCommand("sm_givecredits #%i %i", GetClientUserId(client), g_cMoneyForPlusMinus.IntValue);
			}
		}
		
	}
	return Plugin_Continue;
}

public Action EndQuiz(Handle timer)
{
	ResetAllVariables();
}

void ResetAllVariables()
{
	g_bIsActiveQuiz = false;
	g_bPrikladPlus = false;
	g_bPrikladPlus = false;
	g_bPrikladMinus = false;
}

stock bool IsAdmin(int client)
{
	return CheckCommandAccess(client, "", ADMFLAG_BAN);
} 