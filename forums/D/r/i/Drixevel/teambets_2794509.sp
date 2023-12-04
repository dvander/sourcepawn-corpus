/**
 * teambets.sp
 * Adds team betting. After dying, a player can bet on which team will win. 
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.6"

public Plugin myinfo = 
{
	name = "Team Bets",
	author = "GrimReaper - Original by ferret",
	description = "Bet on Team to Win",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=85914"
};

#define LIFE_ALIVE 0
int g_iLifeState = -1;
int g_iAccount = -1;

#define BET_AMOUNT 0
#define BET_WIN 1
#define BET_TEAM 2

bool g_bEnabled = false;
bool g_bHooked = false;

int g_iPlayerBetData[MAXPLAYERS + 1][3];
bool g_bPlayerBet[MAXPLAYERS + 1] = {false, ...};
bool g_bBombPlanted = false;
bool g_bOneVsMany = false;
int g_iOneVsManyPot;
int g_iOneVsManyTeam;

ConVar g_hSmBet = null;
ConVar g_hSmBetDeadOnly = null;
ConVar g_hSmBetOneVsMany = null;
ConVar g_hSmBetAnnounce = null;
ConVar g_hSmBetAdvert = null;
ConVar g_hSmBetPlanted = null;

public void OnPluginStart()
{
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	g_iLifeState = FindSendPropInfo("CBasePlayer", "m_lifeState");

	if (g_iAccount == -1 || g_iLifeState == -1)
	{
		g_bEnabled = false;
		PrintToServer("[TeamBets] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}
	
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambets");	

	CreateConVar("sm_teambets_version", PLUGIN_VERSION, "TeamBets Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);		
	
	g_hSmBet = CreateConVar("sm_bet", "1", "Enable team betting? (0 off, 1 on, def. 1)");	
	g_hSmBetDeadOnly = CreateConVar("sm_bet_deadonly", "1", "Only dead players can bet. (0 off, 1 on, def. 1)");	
	g_hSmBetOneVsMany = CreateConVar("sm_bet_onevsmany", "0", "The winner of a 1 vs X fight gets the losing pot (def. 0)");	
	g_hSmBetAnnounce = CreateConVar("sm_bet_announce", "0", "Announce 1 vs 1 situations (0 off, 1 on, def. 0)");
	g_hSmBetAdvert = CreateConVar("sm_bet_advert", "1", "Advertise plugin instructions on client connect? (0 off, 1 on, def. 1)");
	g_hSmBetPlanted = CreateConVar("sm_bet_planted", "0", "Prevent betting if the bomb has been planted. (0 off, 1 on, def. 0)");

	g_hSmBet.AddChangeHook(ConVarChange_SmBet);

	g_bEnabled = true;
	
	CreateTimer(5.0, Timer_DelayedHooks);

	AutoExecConfig(true, "teambets");
}

public Action Timer_DelayedHooks(Handle timer)
{
	if (g_bEnabled)
	{
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		HookEvent("bomb_planted", Event_Planted, EventHookMode_PostNoCopy);
		
		g_bHooked = true;

		PrintToServer("[TeamBets] - Loaded");
	}
	
	return Plugin_Continue;
}

public void ConVarChange_SmBet(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int iNewVal = StringToInt(newValue);
	
	if (g_bEnabled && iNewVal != 1)
	{
		if (g_bHooked)
		{
			UnhookEvent("round_end", Event_RoundEnd);
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("bomb_planted", Event_Planted);
			
			g_bHooked = false;
		}
		
		g_bEnabled = false;
	}
	else if (!g_bEnabled && iNewVal == 1)
	{
		if (!g_bHooked)
		{
			HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
			HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
			HookEvent("bomb_planted", Event_Planted, EventHookMode_PostNoCopy);		
			
			g_bHooked = true;			
		}
		
		g_bEnabled = true;		
	}
}

public Action Event_Planted(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	if (g_hSmBetPlanted.IntValue == 1)
	{
		g_bBombPlanted = true;
	}

	return Plugin_Continue;
}

public Action Command_Say(int client, int args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	char szText[192];
	GetCmdArgString(szText, sizeof(szText));
	
	int startarg = 0;
	if (szText[0] == '"')
	{
		startarg = 1;
		/* Strip the ending quote, if there is one */
		int szTextlen = strlen(szText);
		if (szText[szTextlen-1] == '"')
		{
			szText[szTextlen-1] = '\0';
		}
	}
	
	char szParts[3][16];
  	ExplodeString(szText[startarg], " ", szParts, 3, 16);

 	if (strcmp(szParts[0],"bet",false) == 0)
	{
		if (g_bBombPlanted == true)
		{
			PrintToChat(client, "\x04[TeamBets]\x01 %t", "No bets after bomb planted");
			return Plugin_Handled;
		}
	
		if (GetClientTeam(client) <= 1)
		{
			PrintToChat(client, "\x04[TeamBets]\x01 %t", "Must Be On A Team To Vote");
			return Plugin_Handled;
		}
		
		if (g_bPlayerBet[client])
		{
			PrintToChat(client, "\x04[TeamBets]\x01 %t", "Already Betted");
			return Plugin_Handled;	
		}

		if (g_hSmBetDeadOnly.IntValue == 1 && IsAlive(client))
		{
			PrintToChat(client, "\x04[TeamBets]\x01 %t", "Must Be Dead To Vote");
			return Plugin_Handled;
		}
	
		if (strcmp(szParts[1],"ct",false) != 0 && strcmp(szParts[1],"t", false) != 0)
		{
			PrintToChat(client, "\x04[TeamBets]\x01 %t", "Invalid Team for Bet");
			return Plugin_Handled;
		}

		if (strcmp(szParts[1],"ct",false) == 0 || strcmp(szParts[1],"t", false) == 0)
		{
			int iAmount = 0;
			int iBank = GetMoney(client);
	
			if (IsCharNumeric(szParts[2][0]))
			{
				iAmount = StringToInt(szParts[2]);
			}
			else if (strcmp(szParts[2],"all",false) == 0)
			{
				iAmount = iBank;
			}
			if (strcmp(szParts[2],"half", false) == 0)
			{
				iAmount = (iBank / 2) + 1;
			}
			if (strcmp(szParts[2],"third", false) == 0)
			{
				iAmount = (iBank / 3) + 1;
			}

			if (iAmount < 1)
			{
				PrintToChat(client, "\x04[TeamBets]\x01 %t", "Invalid Bet Amount");
				return Plugin_Handled;
			}		
	
			if (iAmount > iBank || iBank < 1)
			{
				PrintToChat(client, "\x04[TeamBets]\x01 %t", "Not Enough Money");
				return Plugin_Handled;
			}
	
			int iOdds[2] = {0, 0}, iTeam;

			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsAlive(i))
				{
					iTeam = GetClientTeam(i);
					if (iTeam == 2) // 2 = t, 3 = ct
					{
						iOdds[0]++;
					}
					else if (iTeam == 3)
					{
						iOdds[1]++;			
					}
				}
			}
	
			if (iOdds[0] < 1 || iOdds[1] < 1)
			{
				PrintToChat(client, "\x04[TeamBets]\x01 %t", "Players Are Dead");
				return Plugin_Continue;		
			}
	
			g_iPlayerBetData[client][BET_AMOUNT] = iAmount;
			g_iPlayerBetData[client][BET_TEAM] = (strcmp(szParts[1],"t",false) == 0 ? 2 : 3); // 2 = t, 3 = ct
	
			int iWin;
	
			if (g_iPlayerBetData[client][BET_TEAM] == 2) // 2 = t, 3 = ct
			{
				iWin = RoundToNearest((float(iOdds[1]) / float(iOdds[0])) * float(iAmount));
				PrintToChat(client, "\x04[TeamBets]\x01 %t", "Bet Made", iOdds[1], iOdds[0], iWin, g_iPlayerBetData[client][BET_AMOUNT]);		
			}
			else
			{
				iWin = RoundToNearest((float(iOdds[0]) / float(iOdds[1])) * float(iAmount));
				PrintToChat(client, "\x04[TeamBets]\x01 %t", "Bet Made", iOdds[0], iOdds[1], iWin, g_iPlayerBetData[client][BET_AMOUNT]);
			}

			g_iPlayerBetData[client][BET_WIN] = iWin;
			g_bPlayerBet[client] = true;
	
			if (g_bOneVsMany && g_iOneVsManyTeam != g_iPlayerBetData[client][BET_TEAM])
			{ 
				g_iOneVsManyPot += iAmount;
			}

			SetMoney(client, iBank - iAmount);

			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!g_bEnabled)
		return true;	
	
	g_iPlayerBetData[client][BET_AMOUNT] = 0;
	g_iPlayerBetData[client][BET_TEAM] = 0;
	g_iPlayerBetData[client][BET_WIN] = 0;
	g_bPlayerBet[client] = false;
	
	CreateTimer(15.0, Timer_Advertise, client);
	
	return true;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;	
	
	if (g_hSmBetAnnounce.IntValue == 0 && g_hSmBetOneVsMany.IntValue < 2) // We don't care about player deaths
		return;

	int iTeam, iTeams[2] = {0, 0}, iTPlayer, iCTPlayer;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsAlive(i))
		{
			iTeam = GetClientTeam(i);
			if (iTeam == 2)
			{
				iTeams[0]++;
				if (iTPlayer == 0) { iTPlayer = i; }
			}
			else if (iTeam == 3)
			{
				iTeams[1]++;
				if (iCTPlayer == 0) { iCTPlayer = i; }
			}
		}	
	}

	if (iTeams[0] == 1 && iTeams[1] == 1 && !g_bOneVsMany && g_hSmBetAnnounce.IntValue > 0)
	{
		PrintToChatAll("\x04[TeamBets]\x01 %T", "One Vs One", LANG_SERVER);
		return;
	}
	
	if (g_hSmBetOneVsMany.IntValue > 1)
	{
		char pname[64];
		
		if ((iTeams[0] == 1 && iTeams[1] > g_hSmBetOneVsMany.IntValue) || (iTeams[1] == 1 && iTeams[0] > g_hSmBetOneVsMany.IntValue) && !g_bOneVsMany)
		{
			g_bOneVsMany = true;
			g_iOneVsManyPot = 0;
			
			if (iTeams[0] == 1)
			{
				GetClientName(iTPlayer, pname, 64);
				g_iOneVsManyTeam = 2;
			}
			else
			{
				GetClientName(iCTPlayer, pname, 64);
				g_iOneVsManyTeam = 3;
			}
			
			PrintToChatAll("\x04[TeamBets]\x01 %T", "One Vs Many Start", LANG_SERVER, pname, (iTeams[1] == 1 ? "Terrorist" : "Counter-Terrorist"));
		}
		else if (iTeams[0] == 1 && iTeams[1] == 0 && g_bOneVsMany && g_iOneVsManyTeam == 2)
		{
			GetClientName(iTPlayer, pname, 64);
			PrintToChatAll("\x04[TeamBets]\x01 %T", "One Vs Many Winner", LANG_SERVER, pname, g_iOneVsManyPot);
			SetMoney(iTPlayer, GetMoney(iTPlayer) + g_iOneVsManyPot);
		}
		else if (iTeams[1] == 1 && iTeams[0] == 0 && g_bOneVsMany && g_iOneVsManyTeam == 3)
		{
			GetClientName(iCTPlayer, pname, 64);
			PrintToChatAll("\x04[TeamBets]\x01 %T", "One Vs Many Winner", LANG_SERVER, pname, g_iOneVsManyPot);
			SetMoney(iCTPlayer, GetMoney(iCTPlayer) + g_iOneVsManyPot);		
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;		
	
	int iWinner = GetEventInt(event, "winner");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && g_bPlayerBet[i])
		{
			if (iWinner == g_iPlayerBetData[i][BET_TEAM])
			{
				SetMoney(i,GetMoney(i) + g_iPlayerBetData[i][BET_AMOUNT] + g_iPlayerBetData[i][BET_WIN]);
				PrintToChat(i, "\x04[TeamBets]\x01 %t", "Bet Won", g_iPlayerBetData[i][BET_WIN], g_iPlayerBetData[i][BET_AMOUNT]);
			}
			else
			{
				PrintToChat(i, "\x04[TeamBets]\x01 %t", "Bet Lost", g_iPlayerBetData[i][BET_AMOUNT]);
			}
		}
		
		g_bPlayerBet[i] = false;		
	}
	
	g_bOneVsMany = false;
	g_iOneVsManyPot = 0;
	g_bBombPlanted = false;
}

public Action Timer_Advertise(Handle timer, any client)
{
	if (g_hSmBetAdvert.IntValue == 1)
	{
		if (IsClientInGame(client))
			PrintToChat(client, "\x04[TeamBets]\x01 %t", "Advertise Bets");
		else if (IsClientConnected(client))
			CreateTimer(15.0, Timer_Advertise, client);
	}

	return Plugin_Continue;
}
 
bool IsAlive(int client)
{
    if (g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == LIFE_ALIVE)
        return true;
 
    return false;
} 

void SetMoney(int client, int amount)
{
	if (g_iAccount != -1)
		SetEntData(client, g_iAccount, amount);
}

int GetMoney(int client)
{
	if (g_iAccount != -1)
		return GetEntData(client, g_iAccount);

	return 0;
}