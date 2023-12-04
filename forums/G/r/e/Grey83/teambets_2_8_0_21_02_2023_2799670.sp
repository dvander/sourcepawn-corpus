#pragma semicolon 1
#pragma newdecls required

#include <sdktools_gamerules>

static const char
	PL_NAME[]	= "Team Bets",
	PL_VER[]	= "2.8.0_21.02.2023 (rewritten by Grey83)",

	PREFIX[]	= " \x04[TeamBets] ";	// For CS:GO, the first character must be a space

enum
{
	B_Amount,
	B_Win,
	B_Team,

	B_Total
};

bool
	bCSGO,
	bEnable,
	bDead,
	bDuel,
	bAds,
	bPlanted,

	bBet[MAXPLAYERS+1],
	bBombPlanted,
	bOneVsMany;
int
	m_iAccount,
	iMaxMoney = 16000,
	iOneVsMany,
	iBets[MAXPLAYERS+1][B_Total],

	iOneVsManyPot,
	iOneVsManyTeam,
	iWinnerLastRnd;

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= "VieuxGnome fork GrimReaper - ferret",
	description	= "Adds team betting. After dying, a player can bet on which team will win.",
	version		= PL_VER,
	url			= "http://forums.alliedmods.net/showthread.php?t=85914"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if((m_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CCSPlayer::m_iAccount'!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	bCSGO = GetEngineVersion() == Engine_CSGO;

	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambets");

	ConVar cvar;
	if((cvar = FindConVar("mp_maxmoney")))
	{
		cvar.AddChangeHook(CVarChange_Money);
		iMaxMoney = cvar.IntValue;
	}

	CreateConVar("sm_teambets_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	cvar = CreateConVar("sm_bet", "1", "Enable team betting? (0 off, 1 on)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Enable);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_bet_deadonly", "1", "Only dead players can bet. (0 off, 1 on)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Dead);
	bDead = cvar.BoolValue;

	cvar = CreateConVar("sm_bet_onevsmany", "0", "The winner of a 1 vs X fight gets the losing pot", _, true);
	cvar.AddChangeHook(CVarChange_OneVSMany);
	iOneVsMany = cvar.IntValue;

	cvar = CreateConVar("sm_bet_announce", "0", "Announce 1 vs 1 situations (0 off, 1 on)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Duel);
	bDuel = cvar.BoolValue;

	cvar = CreateConVar("sm_bet_advert", "1", "Advertise plugin instructions on client connect? (0 off, 1 on)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Ads);
	bAds = cvar.BoolValue;

	cvar = CreateConVar("sm_bet_planted", "0", "Prevent betting if the bomb has been planted. (0 off, 1 on)", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Planted);
	bPlanted = cvar.BoolValue;

	AutoExecConfig(true, "teambets");

	RegConsoleCmd("say", Cmd_Say);
	RegConsoleCmd("say_team", Cmd_Say);
}

public void CVarChange_Money(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMaxMoney = cvar.IntValue;
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	static bool hooked;
	if((bEnable = cvar.BoolValue) == hooked)
		return;

	if((hooked ^= true))
	{
		HookEvent("round_start",	Event_Start, EventHookMode_PostNoCopy);
		HookEvent("player_death",	Event_Death, EventHookMode_PostNoCopy);
		HookEvent("bomb_planted",	Event_Planted, EventHookMode_PostNoCopy);
		HookEvent("round_end",		Event_End);
	}
	else
	{
		UnhookEvent("round_start",	Event_Start, EventHookMode_PostNoCopy);
		UnhookEvent("player_death",	Event_Death, EventHookMode_PostNoCopy);
		UnhookEvent("bomb_planted",	Event_Planted, EventHookMode_PostNoCopy);
		UnhookEvent("round_end",	Event_End);
	}
}

public void CVarChange_Dead(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bDead = cvar.BoolValue;
}

public void CVarChange_OneVSMany(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iOneVsMany = cvar.IntValue;
}

public void CVarChange_Duel(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bDuel = cvar.BoolValue;
}

public void CVarChange_Ads(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bAds = cvar.BoolValue;
}

public void CVarChange_Planted(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bPlanted = cvar.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if(bAds && !IsFakeClient(client)) CreateTimer(15.0, Timer_Advertise, GetClientUserId(client));
}

public Action Timer_Advertise(Handle timer, any client)
{
	if((client = GetClientOfUserId(client))) PrintToChat(client, "%s\x01%t", PREFIX, "Advertise Bets");
	return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
	iBets[client][B_Amount] = iBets[client][B_Team] = iBets[client][B_Win] = 0;
	bBet[client] = false;
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable)
		return;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(bBet[i] && IsClientInGame(i))
		{
			if(iWinnerLastRnd == iBets[i][B_Team])
			{
				SetMoney(i, GetMoney(i) + iBets[i][B_Amount] + iBets[i][B_Win]);
				PrintToChat(i, "%s\x05%t", PREFIX, "Bet Won", iBets[i][B_Win], iBets[i][B_Amount]);
			}
			else PrintToChat(i, "%s\x02%t", PREFIX, "Bet Lost", iBets[i][B_Amount]);
		}
		bBet[i] = false;
	}
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	if(!bDuel && iOneVsMany < 2) // We don't care about player deaths
		return;

	int iTeams[2], iTPlayer, iCTPlayer;
	for(int i = 1, t; i <= MaxClients; i++) if(IsClientInGame(i) && (t = GetClientTeam(i)) > 1 && IsPlayerAlive(i))
	{
		if(t == 2)
		{
			iTeams[0]++;
			if(!iTPlayer) iTPlayer = i;
		}
		else
		{
			iTeams[1]++;
			if(!iCTPlayer) iCTPlayer = i;
		}
	}

	if(bDuel && !bOneVsMany && iTeams[0] == 1 && iTeams[1] == 1)
	{
		PrintToChatAll("%s\x01%t", PREFIX, "One Vs One");
		return;
	}

	if(iOneVsMany > 1)
	{
		char pname[MAX_NAME_LENGTH];
		if((iTeams[0] == 1 && iTeams[1] > iOneVsMany || iTeams[1] == 1 && iTeams[0] > iOneVsMany) && !bOneVsMany)
		{
			bOneVsMany = true;
			iOneVsManyPot = 0;

			if(iTeams[0] == 1)
			{
				GetClientName(iTPlayer, pname, sizeof(pname));
				iOneVsManyTeam = 2;
			}
			else
			{
				GetClientName(iCTPlayer, pname, sizeof(pname));
				iOneVsManyTeam = 3;
			}

			PrintToChatAll("%s\x01%t", PREFIX, "One Vs Many Start", pname, (iTeams[1] == 1 ? "Terrorist" : "Counter-Terrorist"));
		}
		else if(iTeams[0] == 1 && iTeams[1] == 0 && bOneVsMany && iOneVsManyTeam == 2)
		{
			GetClientName(iTPlayer, pname, sizeof(pname));
			PrintToChatAll("%s\x01%t", PREFIX, "One Vs Many Winner", pname, iOneVsManyPot);
			SetMoney(iTPlayer, GetMoney(iTPlayer) + iOneVsManyPot);
		}
		else if(iTeams[1] == 1 && iTeams[0] == 0 && bOneVsMany && iOneVsManyTeam == 3)
		{
			GetClientName(iCTPlayer, pname, sizeof(pname));
			PrintToChatAll("%s\x01%t", PREFIX, "One Vs Many Winner", pname, iOneVsManyPot);
			SetMoney(iCTPlayer, GetMoney(iCTPlayer) + iOneVsManyPot);
		}
	}
}

public void Event_Planted(Event event, const char[] name, bool dontBroadcast)
{
	if(bPlanted) bBombPlanted = true;
}

public void Event_End(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnable)
		return ;

	iWinnerLastRnd = event.GetInt("winner");
	bOneVsMany = bBombPlanted = false;
	iOneVsManyPot = 0;
}

public Action Cmd_Say(int client, int args)
{
	if(!bEnable)
		return Plugin_Continue;

	char szText[20];
	GetCmdArgString(szText, sizeof(szText));	// bet "ct" "65536" or bet "ct" "third" = 16

	char szParts[3][16];
	ExplodeString(szText, " ", szParts, sizeof(szParts), sizeof(szParts[]));

	StripQuotes(szParts[0]);
	TrimString(szParts[0]);
	if(strcmp(szParts[0], "bet", false))
		return Plugin_Continue;

	if(bCSGO && GameRules_GetProp("m_bWarmupPeriod"))
		return Plugin_Handled;

	if(bBombPlanted)
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "No bets after bomb planted");
		return Plugin_Handled;
	}

	if(GetClientTeam(client) < 2)
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Must Be On A Team To Vote");
		return Plugin_Handled;
	}

	if(bBet[client])
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Already Betted");
		return Plugin_Handled;
	}

	if(bDead && IsPlayerAlive(client))
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Must Be Dead To Vote");
		return Plugin_Handled;
	}

	StripQuotes(szParts[1]);
	TrimString(szParts[1]);
	if(strcmp(szParts[1],"ct", false) && strcmp(szParts[1],"t", false))
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Invalid Team for Bet");
		return Plugin_Handled;
	}

	StripQuotes(szParts[2]);
	TrimString(szParts[2]);
	int iAmount, iBank = GetMoney(client);
	if(IsCharNumeric(szParts[2][0]))
	{
		iAmount = StringToInt(szParts[2]);
	}
	else if(!strcmp(szParts[2],"all",false))
	{
		iAmount = iBank;
	}
	else if(!strcmp(szParts[2],"half", false))
	{
		iAmount = (iBank / 2) + 1;
	}
	else if(!strcmp(szParts[2],"third", false))
	{
		iAmount = (iBank / 3) + 1;
	}

	if(iAmount < 1)
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Invalid Bet Amount");
		return Plugin_Handled;
	}

	if(iBank < 1)
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Not Enough Money");
		return Plugin_Handled;
	}

	int iOdds[2];
	for(int i = 1, t; i <= MaxClients; i++) if(IsClientInGame(i) && (t = GetClientTeam(i)) > 1 && IsPlayerAlive(i))
		iOdds[view_as<int>(t == 3)]++;

	if(iOdds[0] < 1 || iOdds[1] < 1)
	{
		PrintToChat(client, "%s\x01%t", PREFIX, "Players Are Dead");
		return Plugin_Continue;
	}

	if(iAmount > iBank) iAmount = iBank;
	iBets[client][B_Amount] = iAmount;

	int numerator, divider;
	if((iBets[client][B_Team] = !strcmp(szParts[1], "t", false) ? 2 : 3) == 2)
	{
		numerator = iOdds[1];
		divider = iOdds[0];
	}
	else
	{
		numerator = iOdds[0];
		divider = iOdds[1];
	}
	iBets[client][B_Win] = RoundToNearest((numerator * iAmount) / (divider + 0.0));
	PrintToChat(client, "%s\x01%t", PREFIX, "Bet Made", numerator, divider, iBets[client][B_Win], iBets[client][B_Amount]);
	bBet[client] = true;

	if(bOneVsMany && iOneVsManyTeam != iBets[client][B_Team]) iOneVsManyPot += iAmount;

	SetMoney(client, iBank - iAmount);

	return Plugin_Handled;
}

stock void SetMoney(int client, int amount)
{
	if(amount > iMaxMoney) amount = iMaxMoney;
	SetEntData(client, m_iAccount, amount);
}

stock int GetMoney(int client)
{
	return GetEntData(client, m_iAccount);
}