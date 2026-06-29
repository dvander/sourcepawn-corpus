/**
 * teambets.sp
 * Adds team betting. After dying, a player can bet on which team will win. 
 */

#include <sourcemod>
#include <store>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "2.7.1.xx"

public Plugin myinfo = 
{
	name = "Team Bets - zstore credits",
	author = "VieuxGnome fork GrimReaper - ferret", //edit shanapu
	description = "Bet on Team to Win - Zstore Credits",
	version = PLUGIN_VERSION,
	url = "http //forums.alliedmods.net/showthread.php?t=85914"
};

#define BET_AMOUNT 0
#define BET_WIN 1
#define BET_TEAM 2

int g_bEnabled = false;
int g_bHooked = false;

int g_iPlayerBetData[MAXPLAYERS + 1][3];
bool g_bPlayerBet[MAXPLAYERS + 1] = {false, ...};
bool g_bBombPlanted = false;
bool g_bOneVsMany = false;
int g_iOneVsManyPot;
int g_iOneVsManyTeam;
int g_iWinnerLastRnd;
int g_iInPotTotal;

Handle g_hSmBet = INVALID_HANDLE;
Handle g_hSmBetDeadOnly = INVALID_HANDLE;
Handle g_hSmBetOneVsMany = INVALID_HANDLE;
Handle g_hSmBetAnnounce = INVALID_HANDLE;
Handle g_hSmBetAdvert = INVALID_HANDLE;
Handle g_hSmBetPlanted = INVALID_HANDLE;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambets");

	CreateConVar("sm_teambets_version", PLUGIN_VERSION, "TeamBets Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_pot", Command_Pot);
	
	g_hSmBet = CreateConVar("sm_bet_enable", "1", "Enable team betting? (0 off, 1 on, def. 1)");
	g_hSmBetDeadOnly = CreateConVar("sm_bet_deadonly", "1", "Only dead players can bet. (0 off, 1 on, def. 1)");
	g_hSmBetOneVsMany = CreateConVar("sm_bet_onevsmany", "0", "The winner of a 1 vs X fight gets the losing pot (def. 0)");	
	g_hSmBetAnnounce = CreateConVar("sm_bet_announce", "0", "Announce 1 vs 1 situations (0 off, 1 on, def. 0)");
	g_hSmBetAdvert = CreateConVar("sm_bet_advert", "1", "Advertise plugin instructions on client connect? (0 off, 1 on, def. 1)");
	g_hSmBetPlanted = CreateConVar("sm_bet_planted", "0", "Prevent betting if the bomb has been planted. (0 off, 1 on, def. 0)");
	
	HookConVarChange(g_hSmBet, ConVarChange_SmBet);

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
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
		g_bHooked = true;

		PrintToServer("[TeamBets] - Loaded");
	}
}

public void ConVarChange_SmBet(Handle convar, char [] oldValue, char [] newValue)
{
	int iNewVal = StringToInt(newValue);
	
	if (g_bEnabled && iNewVal != 1)
	{
		if (g_bHooked)
		{
			UnhookEvent("round_end", Event_RoundEnd);
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("bomb_planted", Event_Planted);
			UnhookEvent("round_start", Event_RoundStart);
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
			HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
			g_bHooked = true;
		}
		
		g_bEnabled = true;
	}
}

public void Event_Planted(Handle event, char []name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return ;
	
	if (GetConVarInt(g_hSmBetPlanted) == 1)
	{
		g_bBombPlanted = true;
	}
}

public Action Command_Pot(int client, int args)
{
	if (!g_bEnabled)
		return Plugin_Continue;

	if (IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "In Pot Total", g_iInPotTotal);

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
			PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "No bets after bomb planted");
			return Plugin_Handled;
		}
	
		if (GetClientTeam(client) <= 1)
		{
			PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Must Be On A Team To Vote");
			return Plugin_Handled;
		}
		
		if (g_bPlayerBet[client])
		{
			PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Already Betted");
			return Plugin_Handled;	
		}

		if (GetConVarInt(g_hSmBetDeadOnly) == 1 && IsPlayerAlive(client))
		{
			PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Must Be Dead To Vote");
			return Plugin_Handled;
		}
	
		if (strcmp(szParts[1],"ct",false) != 0 && strcmp(szParts[1],"t", false) != 0)
		{
			PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Invalid Team for Bet");
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
				PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Invalid Bet Amount");
				return Plugin_Handled;
			}		
	
			if (iAmount > iBank || iBank < 1)
			{
				PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Not Enough Money");
				return Plugin_Handled;
			}
	
			int iOdds[2] = {0, 0}, iTeam;
			int iMaxClients = GetMaxClients();

			for (int i = 1; i <= iMaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
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
				PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Players Are Dead");
				return Plugin_Continue;		
			}
	
			g_iPlayerBetData[client][BET_AMOUNT] = iAmount;
			g_iPlayerBetData[client][BET_TEAM] = (strcmp(szParts[1],"t",false) == 0 ? 2 : 3); // 2 = t, 3 = ct
			g_iInPotTotal += iAmount;
	
			int iWin;
	
			if (g_iPlayerBetData[client][BET_TEAM] == 2) // 2 = t, 3 = ct
			{
				iWin = RoundToNearest((float(iOdds[1]) / float(iOdds[0])) * float(iAmount));
				PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Bet Made", iOdds[1], iOdds[0], iWin, g_iPlayerBetData[client][BET_AMOUNT]);
			}
			else
			{
				iWin = RoundToNearest((float(iOdds[0]) / float(iOdds[1])) * float(iAmount));
				PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Bet Made", iOdds[0], iOdds[1], iWin, g_iPlayerBetData[client][BET_AMOUNT]);
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

public bool OnClientConnect(int client, char []rejectmsg, int maxlen)
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

public void Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;	
	
	if (GetConVarInt(g_hSmBetAnnounce) == 0 && GetConVarInt(g_hSmBetOneVsMany) < 2) // We don't care about player deaths
		return;

	int iMaxClients = GetMaxClients();
	int iTeam, iTeams[2] = {0, 0}, iTPlayer, iCTPlayer;
	
	for (int i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
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

	if (iTeams[0] == 1 && iTeams[1] == 1 && !g_bOneVsMany && GetConVarInt(g_hSmBetAnnounce) > 0)
	{
		PrintToChatAll("\x04-\x04[TeamBets]\x01 %T", "One Vs One", LANG_SERVER);
		return;
	}
	
	if (GetConVarInt(g_hSmBetOneVsMany) > 1)
	{
		char pname[64];
		
		if ((iTeams[0] == 1 && iTeams[1] > GetConVarInt(g_hSmBetOneVsMany)) || (iTeams[1] == 1 && iTeams[0] > GetConVarInt(g_hSmBetOneVsMany)) && !g_bOneVsMany)
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
			
			PrintToChatAll("\x04-\x04[TeamBets]\x01 %T", "One Vs Many Start", LANG_SERVER, pname, (iTeams[1] == 1 ? "Terrorist" : "Counter-Terrorist"));
		}
		else if (iTeams[0] == 1 && iTeams[1] == 0 && g_bOneVsMany && g_iOneVsManyTeam == 2)
		{
			GetClientName(iTPlayer, pname, 64);
			PrintToChatAll("\x04-\x04[TeamBets]\x01 %T", "One Vs Many Winner", LANG_SERVER, pname, g_iOneVsManyPot);
			SetMoney(iTPlayer, GetMoney(iTPlayer) + g_iOneVsManyPot);
		}
		else if (iTeams[1] == 1 && iTeams[0] == 0 && g_bOneVsMany && g_iOneVsManyTeam == 3)
		{
			GetClientName(iCTPlayer, pname, 64);
			PrintToChatAll("\x04-\x04[TeamBets]\x01 %T", "One Vs Many Winner", LANG_SERVER, pname, g_iOneVsManyPot);
			SetMoney(iCTPlayer, GetMoney(iCTPlayer) + g_iOneVsManyPot);		
		}
	}
}

public void Event_RoundStart(Handle event, char[]name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return ;	
		
	int iMaxClients = GetMaxClients();
	int iMoney = 0;
	for (int i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i) && g_bPlayerBet[i])
		{
			if (g_iWinnerLastRnd == g_iPlayerBetData[i][BET_TEAM])
			{
				iMoney = GetMoney(i) + g_iPlayerBetData[i][BET_AMOUNT] + g_iPlayerBetData[i][BET_WIN];
				SetMoney(i,iMoney);
				PrintToChat(i, "\x04-\x04[TeamBets]\x05 %t", "Bet Won", g_iPlayerBetData[i][BET_WIN], g_iPlayerBetData[i][BET_AMOUNT]);
			}
			else
			{
				PrintToChat(i, "\x04-\x04[TeamBets]\x02 %t", "Bet Lost", g_iPlayerBetData[i][BET_AMOUNT]);
			}
		}
		g_bPlayerBet[i] = false;
	}
}

public void Event_RoundEnd(Handle event, char []name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return ;

	int iWinner = GetEventInt(event, "winner");
	g_iWinnerLastRnd = iWinner;
	g_bOneVsMany = false;
	g_iOneVsManyPot = 0;
	g_bBombPlanted = false;
	g_iInPotTotal = 0;
}

public Action Timer_Advertise(Handle timer, any client)
{
	if (GetConVarInt(g_hSmBetAdvert) == 1)
		{
			if (IsClientInGame(client))
				PrintToChat(client, "\x04-\x04[TeamBets]\x01 %t", "Advertise Bets");
			else if (IsClientConnected(client))
				CreateTimer(15.0, Timer_Advertise, client);
		}
}

void SetMoney(int client, int amount)
{
	Store_SetClientCredits(client, amount);
}

int GetMoney(int client)
{
	return Store_GetClientCredits(client);
}