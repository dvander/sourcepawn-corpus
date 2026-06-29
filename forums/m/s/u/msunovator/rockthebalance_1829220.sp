/**
 * rockthebalance.sp
 * Provides RTB Balance Voting
 *
 * Based on Ferret RTV plugin
 * http://forums.alliedmods.net/showthread.php?t=57106
 *
 * Changelog:
 *
 * Version 0.1 (Oct 30th)
 * - Fixed translation error in nomination handler 
 * - Fixed checking client 0 for "is in game"  
 * - Uh.. whoops. We now increment the votes when they are cast. 
 * - Close the menu on balance end, so it's ready to be rebuilt next balance. 
 * - Set g_bHated when a player successfully hates.. rofl. 
 * - I shouldn't code at work. 
 * - German Translation 
 * - Added a check for number of nominations after user picks a balance, in case multiple people tried to hate at the same time. 
 * - Forgot to set g_bRTBEnded when it ended. 
 * - Visual fix for when player selects current balance 
 * - Added sm_rtb_file so that you can customize the balance file without editing the plugin. 
 * - Conformed to plugin submission rules 
 * - Added version cvar sm_rockthebalance_version 
 * - Bots excluded from "vote required" total. 
 * - Fixed hate command, you can now hate until the vote is displayed. 
 * - Changed the RTBStarted phrase slightly. 
 * - Added new cvar, sm_rtb_balances. This lets you control the number of balances in the vote. It also acts as the nomination limit. See above. 
 * - RTB is now delayed by 30 seconds on balance start. Players must wait that long until trying to start it (New phrase, get the translation file!) 
 * - Votes needed is now recalculated each time a player connects or disconnects, rather than the first time someone says "RTB". If someone disconnects, causing the votes to be higher than the needed value, RTB will begin. 
 * - RTB is now delayed 2 seconds after the needed votes are reached. I didn't like it immediately appearing, bugged me for some reason. 
 * - You can now use: bind key "say rtb" 
 * - Fixed german translation for new phrase, thanks Isias. 
 * - Fixed issue of rtb becoming permanently "started" 
 * - Stopped RTB from triggering when last player disconnects.
 * - Removed LANG_SERVER wherever possible.
 * - Added sm_rtb_minplayers cvar
 * - Added sm_rtb_hate cvar
 * - Added sm_rtb_addbalance command.
 * - Fixed crashes due to small balancecycles.
 * - New phrase: "Minimal Players Not Met"
 * - New phrase: "Balance Inserted"
 * - New phrase: "Balance Already in Vote"
 * - Added INS say2.
 *
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo = 
{
	name = "RockTheBalance",
	author = "ferret",
	description = "Provides RTB Balance Voting",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MAXANSWERS 128

new String:g_BalanceNames[MAXANSWERS][32];
new g_BalanceCount = 0;
new g_NextBalancesCount = 0;
new g_NextBalances[6];

new Handle:g_hBalanceMenu = INVALID_HANDLE;

new Handle:g_Cvar_Needed = INVALID_HANDLE;
new Handle:g_Cvar_File = INVALID_HANDLE;
new Handle:g_Cvar_Balances = INVALID_HANDLE;
new Handle:g_Cvar_Hate = INVALID_HANDLE;
new Handle:g_Cvar_MinPlayers = INVALID_HANDLE;

new bool:g_CanRTB = false;
new bool:g_RTBAllowed = false;
new bool:g_RTBStarted = false;
new bool:g_RTBEnded = false;
new g_Voters = 0;
new g_Votes = 0;
new g_VotesNeeded = 0;
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};
new bool:g_Hated[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.rockthebalance");
	
	CreateConVar("sm_rockthebalance_version", PLUGIN_VERSION, "RockTheBalance Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_Needed = CreateConVar("sm_rtb_needed", "0.60", "Percentage of players needed to rockthebalance (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_File = CreateConVar("sm_rtb_file", "configs/balances.ini", "Balance file to use. (Def configs/balances.ini)");
	g_Cvar_Balances = CreateConVar("sm_rtb_balances", "1", "Number of balances to be voted on. 1 to 6. (Def 1)", 0, true, 1.0, true, 6.0);
	g_Cvar_Hate = CreateConVar("sm_rtb_hate", "1", "Enables nomination system.", 0, true, 0.0, true, 1.0);
	g_Cvar_MinPlayers = CreateConVar("sm_rtb_minplayers", "0", "Number of players required before RTB will be enabled.", 0, true, 0.0, true, 64.0);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);	// INS
	RegConsoleCmd("say_team", Command_Say);
	
/*
	RegAdminCmd("sm_rtb_addbalance", Command_Addbalance, ADMFLAG_CHANGEBALANCE, "sm_rtb_addbalance <balancename> - Forces a balance to be on the RTB, and lowers the allowed nominations.");
*/
}

public OnBalanceStart()
{
	g_NextBalancesCount = 0;
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_RTBStarted = false;
	g_RTBEnded = false;
	
	decl String:BalanceListPath[256], String:BalanceListFile[64];
	GetConVarString(g_Cvar_File, BalanceListFile, 64);
	BuildPath(Path_SM, BalanceListPath, sizeof(BalanceListPath), BalanceListFile);
	if (!FileExists(BalanceListPath))
	{
		new Handle:hBalanceCycleFile = FindConVar("balancecyclefile");
		GetConVarString(hBalanceCycleFile, BalanceListPath, sizeof(BalanceListPath));
	}
	
	LogMessage("[RTB] Balance Cycle Path: %s", BalanceListPath);
	
	if (LoadSettings(BalanceListPath))
	{
		BuildBalanceMenu();
		g_CanRTB = true;
		CreateTimer(30.0, Timer_DelayRTB);
	}
	else
	{
		LogMessage("[RTB] Cannot find balance cycle file, RTB not active.");
		g_CanRTB = false;
	}
}

public OnBalanceEnd()
{
	CloseHandle(g_hBalanceMenu);
	g_hBalanceMenu = INVALID_HANDLE;
	g_RTBAllowed = false;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if(IsFakeClient(client))
		return true;
	
	g_Voted[client] = false;
	g_Hated[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	
	return true;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	
	if (g_Votes >= g_VotesNeeded && g_RTBAllowed && g_Voters != 0) 
	{
		CreateTimer(2.0, Timer_StartRTB);
	}	
}

public Action:Command_Addbalance(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rtb_addbalance <balancename>");
		return Plugin_Handled;
	}
	
	decl String:balancename[64];
	GetCmdArg(1, balancename, sizeof(balancename));
	
	new balance = -1;
	
	for (new i = 0; i < g_BalanceCount; i++)
	{
		if(strcmp(g_BalanceNames[i], balancename, false) == 0)
		{
			balance = i;
			break;
		}		
	}

	if (balance == -1)
	{
		ReplyToCommand(client, "%t", "Balance was not found", balance);
		return Plugin_Handled;
	}
	
	if (g_NextBalancesCount > 0)
	{
		for (new i = 0; i < g_NextBalancesCount; i++)
		{
			if (balance == g_NextBalances[i])
			{
				ReplyToCommand(client, "%t", "Balance Already In Vote", g_BalanceNames[balance]);
				return Plugin_Handled;			
			}		
		}
		
		new start = (g_NextBalancesCount == 6 ? 4 : g_NextBalancesCount - 1);
		for (new i = start; i < 0; i--)
		{
			g_NextBalances[i+1] = g_NextBalances[i]; 
		}
		
		if (g_NextBalancesCount < 6)
			g_NextBalancesCount++;
	}
	else
		g_NextBalancesCount = 1;
		
	decl String:item[64];
	for (new i = 0; i < GetMenuItemCount(g_hBalanceMenu); i++)
	{
		GetMenuItem(g_hBalanceMenu, i, item, sizeof(item));
		if (strcmp(item, g_BalanceNames[balance]) == 0)
		{
			RemoveMenuItem(g_hBalanceMenu, i);
			break;
		}			
	}	
	
	g_NextBalances[0] = balance;
	
	ReplyToCommand(client, "%t", "Balance Inserted", g_BalanceNames[balance]);

	if (client)
		LogMessage("[RTB] %L inserted balance %s.", client, balance);
	
	return Plugin_Handled;		
}

public Action:Command_Say(client, args)
{
	if (!g_CanRTB || !client)
		return Plugin_Continue;

	decl String:text[192], String:command[64];
	GetCmdArgString(text, sizeof(text));
	GetCmdArg(0, command, sizeof(command));

	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;
	
	if (strcmp(text[startidx], "rtb", false) == 0 || strcmp(text[startidx], "rockthebalance", false) == 0)
	{
		if (!g_RTBAllowed)
		{
			PrintToChat(client, "[RTB] %t", "RTB Not Allowed");
			return Plugin_Continue;
		}
		
		if (g_RTBEnded)
		{
			PrintToChat(client, "[RTB] %t", "RTB Ended");
			return Plugin_Continue;
		}
		
		if (g_RTBStarted)
		{
			PrintToChat(client, "[RTB] %t", "RTB Started");
			return Plugin_Continue;
		}
		
		if (GetClientCount(true) < GetConVarInt(g_Cvar_MinPlayers) && g_Votes == 0)
		{
			PrintToChat(client, "[RTB] %t", "Minimal Players Not Met");
			return Plugin_Continue;			
		}
		
		if (g_Voted[client])
		{
			PrintToChat(client, "[RTB] %t", "Already Voted");
			return Plugin_Continue;
		}	
		
		new String:name[64];
		GetClientName(client, name, sizeof(name));
		
		g_Votes++;
		g_Voted[client] = true;
		
		PrintToChatAll("[RTB] %t", "RTB Requested", name, g_Votes, g_VotesNeeded);
		
		if (g_Votes >= g_VotesNeeded)
		{
			CreateTimer(2.0, Timer_StartRTB);
		}
	}
	else if (GetConVarBool(g_Cvar_Hate) && strcmp(text[startidx], "hate", false) == 0)
	{
		if (g_RTBStarted)
		{
			PrintToChat(client, "[RTB] %t", "RTB Started");
			return Plugin_Continue;
		}
		
		if (g_Hated[client])
		{
			PrintToChat(client, "[RTB] %t", "Already Hated");
			return Plugin_Continue;
		}
		
		if (g_NextBalancesCount >= GetConVarInt(g_Cvar_Balances))
		{
			PrintToChat(client, "[RTB] %t", "Max Nominations");
			return Plugin_Continue;			
		}
		
		DisplayMenu(g_hBalanceMenu, client, MENU_TIME_FOREVER);		
	}
	
	return Plugin_Continue;	
}

public Action:Timer_DelayRTB(Handle:timer)
{
	g_RTBAllowed = true;
}

public Action:Timer_StartRTB(Handle:timer)
{
	if(!g_RTBAllowed)
		return;
	
	PrintToChatAll("[RTB] %t", "RTB Vote Ready");
	
	g_RTBStarted = true;
		
	new Handle:hBalanceVoteMenu = CreateMenu(Handler_BalanceVoteMenu);
	SetMenuTitle(hBalanceVoteMenu, "%t", "Rock The Balance");
	
	for (new i = 0; i < g_NextBalancesCount; i++)
	{
		AddMenuItem(hBalanceVoteMenu, g_BalanceNames[g_NextBalances[i]], g_BalanceNames[g_NextBalances[i]]);
	}

	new balanceIdx;
	for (new i = g_NextBalancesCount; i < (g_BalanceCount < GetConVarInt(g_Cvar_Balances) ? g_BalanceCount : GetConVarInt(g_Cvar_Balances)); i++)
	{
		balanceIdx = GetRandomInt(0, g_BalanceCount - 1);
		
		while (IsInMenu(balanceIdx))
			if(++balanceIdx >= g_BalanceCount) balanceIdx = 0;

		g_NextBalances[i] = balanceIdx;
		AddMenuItem(hBalanceVoteMenu, g_BalanceNames[balanceIdx], g_BalanceNames[balanceIdx]);
	}
	
	decl String:nochange[64];
	Format(nochange, 64, "%T", "Don't Change", LANG_SERVER);
	AddMenuItem(hBalanceVoteMenu, nochange, nochange);
		
	SetMenuExitButton(hBalanceVoteMenu, false);
	VoteMenuToAll(hBalanceVoteMenu, 20);
		
	LogMessage("[RTB] Rockthevote was successfully started.");
}

public Action:Timer_ChangeBalance(Handle:hTimer, Handle:dp)
{
	new String:balance[65];
	
	ResetPack(dp);
	ReadPackString(dp, balance, sizeof(balance));
	ServerCommand("sm_balanceteams");
	
	return Plugin_Stop;
}

public Handler_BalanceVoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
	}
	else if (action == MenuAction_Select)
	{
		new String:voter[64], String:choice[64];
		GetClientName(param1, voter, sizeof(voter));
		GetMenuItem(menu, param2, choice, sizeof(choice));
		PrintToChatAll("[RTB] %t", "Selected Balance", voter, choice);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:balance[64];
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if (totalVotes < 1)
		{
			PrintToChatAll("[RTB] %t", "No Votes");
			return;
		}
		
		GetMenuItem(menu, param1, balance, sizeof(balance));
		
		if (param1 == GetConVarInt(g_Cvar_Balances))
		{
			PrintToChatAll("[RTB] %t", "Current Balance Stays");
			LogMessage("[RTB] Rockthevote has ended, current balance kept.");
		}
		else
		{
			PrintToChatAll("[RTB] %t", "Changing Balance");
			LogMessage("[RTB] Rockthevote has ended, changing balance.");
			new Handle:dp;
			CreateDataTimer(5.0, Timer_ChangeBalance, dp);
			WritePackString(dp, balance);
		}
		
		g_RTBEnded = true;
	}
}

public Handler_BalanceSelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (g_NextBalancesCount >= GetConVarInt(g_Cvar_Balances)) 
		{
			PrintToChat(param1, "[RTB] %t", "Max Nominations");
			return;	
		}
		
		decl String:balance[64], String:balanceIndex[16], String:name[64];
		GetMenuItem(menu, param2, balanceIndex, 16, _, balance, 64);
		
		new balanceIdx = StringToInt(balanceIndex);

		for (new i = 0; i < g_NextBalancesCount; i++)
		{
			if (g_NextBalances[i] == balanceIdx)
			{
				PrintToChat(param1, "[RTB] %t", "Balance Already Hated");
				return;
			}
		}
		
		GetClientName(param1, name, 64);
		
		g_NextBalances[g_NextBalancesCount] = balanceIdx;
		g_NextBalancesCount++;
		
		RemoveMenuItem(menu, param2);
		
		g_Hated[param1] = true;
		
		PrintToChatAll("[RTB] %t", "Balance Hated", name, balance);
	}	
}

bool:IsInMenu(balanceIdx)
{
	for (new i = 0; i < GetConVarInt(g_Cvar_Balances); i++)
		if (balanceIdx == g_NextBalances[i])
			return true;
	return false;
}

LoadSettings(String:filename[])
{
	if (!FileExists(filename))
		return 0;

	new String:text[32];

	g_BalanceCount = 0;
	new Handle:hBalanceFile = OpenFile(filename, "r");
	
	while (g_BalanceCount < MAXANSWERS && !IsEndOfFile(hBalanceFile))
	{
		ReadFileLine(hBalanceFile, text, sizeof(text));
		TrimString(text);

		if (text[0] != ';' && strcopy(g_BalanceNames[g_BalanceCount], sizeof(g_BalanceNames[]), text))
		{
			++g_BalanceCount;
		}
	}

	return g_BalanceCount;
}

BuildBalanceMenu()
{
	if (g_hBalanceMenu != INVALID_HANDLE)
	{
		CancelMenu(g_hBalanceMenu);
		CloseHandle(g_hBalanceMenu);
		g_hBalanceMenu = INVALID_HANDLE;
	}
	
	g_hBalanceMenu = CreateMenu(Handler_BalanceSelectMenu);
	SetMenuTitle(g_hBalanceMenu, "%t", "Hate Title");

	decl String:BalanceIndex[8];
		
	for (new i = 0; i < g_BalanceCount; i++)
	{
		IntToString(i, BalanceIndex, 8);
		AddMenuItem(g_hBalanceMenu, BalanceIndex, g_BalanceNames[i]);
	}
	
	SetMenuExitButton(g_hBalanceMenu, false);
}