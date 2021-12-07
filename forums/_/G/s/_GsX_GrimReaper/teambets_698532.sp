/**
 * teambets.sp
 * Adds team betting. After dying, a player can bet on which team will win. 
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.6"

public Plugin:myinfo = 
{
	name = "Team Bets",
	author = "ferret",
	description = "Bet on Team to Win",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=56601"
};

#define LIFE_ALIVE 0
new g_iLifeState = -1;
new g_iAccount = -1;

#define BET_AMOUNT 0
#define BET_WIN 1
#define BET_TEAM 2

new g_bEnabled = false;
new g_bHooked = false;

new g_iPlayerBetData[MAXPLAYERS + 1][3];
new bool:g_bPlayerBet[MAXPLAYERS + 1] = {false, ...};

new bool:g_bOneVsMany = false;
new g_iOneVsManyPot;
new g_iOneVsManyTeam;

new Handle:g_hSmBet = INVALID_HANDLE;
new Handle:g_hSmBetDeadOnly = INVALID_HANDLE;
new Handle:g_hSmBetOneVsMany = INVALID_HANDLE;
new Handle:g_hSmBetAnnounce = INVALID_HANDLE;

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");

	if (g_iAccount == -1 || g_iLifeState == -1)
	{
		g_bEnabled = false;
		PrintToServer("[TeamBets] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}
	
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambets");	

	CreateConVar("sm_teambets_version", PLUGIN_VERSION, "TeamBets Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("team_say", Command_Say);		
	
	g_hSmBet = CreateConVar("sm_bet", "1", "Enable team betting? (0 off, 1 on, def. 1)");	
	g_hSmBetDeadOnly = CreateConVar("sm_bet_deadonly", "1", "Only dead players can bet. (0 off, 1 on, def. 1)");	
	g_hSmBetOneVsMany = CreateConVar("sm_bet_onevsmany", "0", "The winner of a 1 vs X fight gets the losing pot (def. 0)");	
	g_hSmBetAnnounce = CreateConVar("sm_bet_announce", "0", "Announce 1 vs 1 situations (0 off, 1 on, def. 0)");	
	
	HookConVarChange(g_hSmBet, ConVarChange_SmBet);

	g_bEnabled = true;
	
	CreateTimer(5.0, Timer_DelayedHooks);

	AutoExecConfig(true, "teambets");
}

public Action:Timer_DelayedHooks(Handle:timer)
{
	if (g_bEnabled)
	{
		HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		
		g_bHooked = true;

		PrintToServer("[TeamBets] - Loaded");
	}
}

public ConVarChange_SmBet(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iNewVal = StringToInt(newValue);
	
	if (g_bEnabled && iNewVal != 1)
	{
		if (g_bHooked)
		{
			UnhookEvent("round_end", Event_RoundEnd);
			UnhookEvent("player_death", Event_PlayerDeath);
			
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
			
			g_bHooked = true;			
		}
		
		g_bEnabled = true;		
	}
}

public Action:Command_Say(client, args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	decl String:szText[192];
	GetCmdArgString(szText, sizeof(szText));
	szText[strlen(szText)-1] = '\0';
	
	new String:szParts[3][16];
  	ExplodeString(szText[1], " ", szParts, 3, 16);

	new String:placebet[20];
	GetCmdArg(1, placebet, sizeof(placebet));

 	if (strcmp(placebet, "bet", false) == 0 || strcmp(szParts[0],"bet",false) == 0)
	{
		if (g_bPlayerBet[client])
		{
			PrintToChat(client, "[Bet] %t", "Already Betted");
			return Plugin_Continue;	
		}

		else if (GetConVarInt(g_hSmBetDeadOnly) == 1 && IsAlive(client))
		{
			PrintToChat(client, "[Bet] %t", "Must Be Dead To Vote");
			return Plugin_Continue;
		}
	
		else if (strcmp(szParts[1],"ct",false) != 0 && strcmp(szParts[1],"t", false) != 0)
		{
			PrintToChat(client, "[Bet] %t", "Invalid Team for Bet");
			return Plugin_Continue;
		}
	
		new iAmount = 0;
		new iBank = GetMoney(client);
	
		if (IsCharNumeric(szParts[2][0]))
		{
			iAmount = StringToInt(szParts[2]);
		}
		else if (strcmp(szParts[2],"all",false) == 0)
		{
			iAmount = iBank;
		}
		else if (strcmp(szParts[2],"half", false) == 0)
		{
			iAmount = (iBank / 2) + 1;
		}
		else if (strcmp(szParts[2],"third", false) == 0)
		{
			iAmount = (iBank / 3) + 1;
		}

		if (iAmount < 1)
		{
			PrintToChat(client, "[Bet] %t", "Invalid Bet Amount");
			return Plugin_Continue;
		}		
	
		if (iAmount > iBank || iBank < 1)
		{
			PrintToChat(client, "[Bet] %t", "Not Enough Money");
			return Plugin_Continue;
		}
	
		new iOdds[2] = {0, 0}, iTeam;
		new iMaxClients = GetMaxClients();

		for (new i = 1; i <= iMaxClients; i++)
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
		PrintToChat(client, "[Bet] %t", "Players Are Dead");
		return Plugin_Continue;		
		}
	
		g_iPlayerBetData[client][BET_AMOUNT] = iAmount;
		g_iPlayerBetData[client][BET_TEAM] = (strcmp(szParts[1],"t",false) == 0 ? 2 : 3); // 2 = t, 3 = ct
	
		new iWin;
	
		if (g_iPlayerBetData[client][BET_TEAM] == 2) // 2 = t, 3 = ct
		{
			iWin = RoundToNearest((float(iOdds[1]) / float(iOdds[0])) * float(iAmount));
			PrintToChat(client, "[Bet] %t", "Bet Made", iOdds[1], iOdds[0], iWin, g_iPlayerBetData[client][BET_AMOUNT]);		
		}
		else
		{
			iWin = RoundToNearest((float(iOdds[0]) / float(iOdds[1])) * float(iAmount));
			PrintToChat(client, "[Bet] %t", "Bet Made", iOdds[0], iOdds[1], iWin, g_iPlayerBetData[client][BET_AMOUNT]);
		}

		g_iPlayerBetData[client][BET_WIN] = iWin;
		g_bPlayerBet[client] = true;
	
		if (g_bOneVsMany && g_iOneVsManyTeam != g_iPlayerBetData[client][BET_TEAM])
		{ 
			g_iOneVsManyPot += iAmount;
		}

		SetMoney(client, iBank - iAmount);

		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
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

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;	
	
	if (GetConVarInt(g_hSmBetAnnounce) == 0 && GetConVarInt(g_hSmBetOneVsMany) < 2) // We don't care about player deaths
		return;

	new iMaxClients = GetMaxClients();
	new iTeam, iTeams[2] = {0, 0}, iTPlayer, iCTPlayer;
	
	for (new i = 1; i <= iMaxClients; i++)
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

	if (iTeams[0] == 1 && iTeams[1] == 1 && !g_bOneVsMany && GetConVarInt(g_hSmBetAnnounce) > 0)
	{
		PrintToChatAll("[Bet] %T", "One Vs One", LANG_SERVER);
		return;
	}
	
	if (GetConVarInt(g_hSmBetOneVsMany) > 1)
	{
		new String:pname[64];
		
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
			
			PrintToChatAll("[Bet] %T", "One Vs Many Start", LANG_SERVER, pname, (iTeams[1] == 1 ? "Terrorist" : "Counter-Terrorist"));
		}
		else if (iTeams[0] == 1 && iTeams[1] == 0 && g_bOneVsMany && g_iOneVsManyTeam == 2)
		{
			GetClientName(iTPlayer, pname, 64);
			PrintToChatAll("[Bet] %T", "One Vs Many Winner", LANG_SERVER, pname, g_iOneVsManyPot);
			SetMoney(iTPlayer, GetMoney(iTPlayer) + g_iOneVsManyPot);
		}
		else if (iTeams[1] == 1 && iTeams[0] == 0 && g_bOneVsMany && g_iOneVsManyTeam == 3)
		{
			GetClientName(iCTPlayer, pname, 64);
			PrintToChatAll("[Bet] %T", "One Vs Many Winner", LANG_SERVER, pname, g_iOneVsManyPot);
			SetMoney(iCTPlayer, GetMoney(iCTPlayer) + g_iOneVsManyPot);		
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;		
	
	new iMaxClients = GetMaxClients();
	new iWinner = GetEventInt(event, "winner");

	for (new i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i) && g_bPlayerBet[i])
		{
			if (iWinner == g_iPlayerBetData[i][BET_TEAM])
			{
				SetMoney(i,GetMoney(i) + g_iPlayerBetData[i][BET_AMOUNT] + g_iPlayerBetData[i][BET_WIN]);
				PrintToChat(i, "[Bet] %t", "Bet Won", g_iPlayerBetData[i][BET_WIN], g_iPlayerBetData[i][BET_AMOUNT]);
			}
			else
			{
				PrintToChat(i, "[Bet] %t", "Bet Lost", g_iPlayerBetData[i][BET_AMOUNT]);
			}
		}
		
		g_bPlayerBet[i] = false;		
	}
	
	g_bOneVsMany = false;
	g_iOneVsManyPot = 0;
}

public Action:Timer_Advertise(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PrintToChat(client, "[Bet] %t", "Advertise Bets");
	else if (IsClientConnected(client))
		CreateTimer(15.0, Timer_Advertise, client);
}
 
public bool:IsAlive(client)
{
    if (g_iLifeState != -1 && GetEntData(client, g_iLifeState, 1) == LIFE_ALIVE)
        return true;
 
    return false;
} 

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
		SetEntData(client, g_iAccount, amount);
}

public GetMoney(client)
{
	if (g_iAccount != -1)
		return GetEntData(client, g_iAccount);

	return 0;
}