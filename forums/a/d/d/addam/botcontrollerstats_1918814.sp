#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "CS:GO Bot Controller Cash Stats Weapons",
	author = "Sheepdude",
	description = "Gives bot cash, stats, and weapons to its controller.",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

// Plugin convar handles
new Handle:h_cvarBotPlayerKills;
new Handle:h_cvarBotPlayerAssists;
new Handle:h_cvarBotPlayerDeaths;
new Handle:h_cvarBotPlayerScore;
new Handle:h_cvarBotPlayerCash;
new Handle:h_cvarBotPlayerEquipment;

// Plugin convar variables
new bool:g_cvarBotPlayerKills;
new bool:g_cvarBotPlayerAssists;
new bool:g_cvarBotPlayerDeaths;
new bool:g_cvarBotPlayerScore;
new bool:g_cvarBotPlayerCash;
new bool:g_cvarBotPlayerEquipment;

// Cash convar handles
new Handle:h_cvarMaxMoney;
new Handle:h_cvarCashBombCTWin;
new Handle:h_cvarCashBombTWin;
new Handle:h_cvarCashBombTPlantLose;
new Handle:h_cvarCashEliminationWinCSCT;
new Handle:h_cvarCashEliminationWinCST;
new Handle:h_cvarCashEliminationWinDE;
new Handle:h_cvarCashHostageWin;
new Handle:h_cvarCashTimeoutWinH;
new Handle:h_cvarCashTimeoutWinB;
new Handle:h_cvarCashLoser;
new Handle:h_cvarCashLoserConsecutive;

// Cash convar variables
new g_cvarMaxMoney;
new g_cvarCashBombCTWin;
new g_cvarCashBombTWin;
new g_cvarCashBombTPlantLose;
new g_cvarCashEliminationWinCSCT;
new g_cvarCashEliminationWinCST;
new g_cvarCashEliminationWinDE;
new g_cvarCashHostageWin;
new g_cvarCashTimeoutWinB;
new g_cvarCashTimeoutWinH;
new g_cvarCashLoser;
new g_cvarCashLoserConsecutive;

// Bot stat management
new g_BotList[MAXPLAYERS+1];
new g_BotKills[MAXPLAYERS+1];
new g_BotAssists[MAXPLAYERS+1];
new g_BotScore[MAXPLAYERS+1];

// Bot cash management
new g_BotCash[MAXPLAYERS+1];
new g_CashQueue[MAXPLAYERS+1];
new CSRoundEndReason:g_LastTerminateReason;
new bool:g_AfterRound;
new String:g_CurrentMap[4];

// Consecutive loss management
new g_CTWins;
new g_TWins;
new g_LastWinner;
new g_ConsecutiveLossAugment;

// Offsets
new ACCOUNT_OFFSET;
new SCORE_OFFSET;

public OnPluginStart()
{
	// Offsets
	ACCOUNT_OFFSET = FindSendPropOffs("CCSPlayer", "m_iAccount");
	SCORE_OFFSET = FindSendPropInfo("CCSPlayer", "m_bIsControllingBot") - 132;
	
	// Plugin convars
	CreateConVar("sm_bot_controller_version", PLUGIN_VERSION, "Bot controller stats plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	h_cvarBotPlayerKills = CreateConVar("sm_bot_controller_kills", "1", "Award kills to the bot's controller (1 - award to player, 0 - award to bot)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarBotPlayerAssists = CreateConVar("sm_bot_controller_assists", "1", "Award assists to the bot's controller (1 - award to player, 0 - award to bot)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarBotPlayerDeaths = CreateConVar("sm_bot_controller_deaths", "1", "Award deaths to the bot's controller (1 - award to player, 0 - award to bot)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarBotPlayerScore = CreateConVar("sm_bot_controller_score", "1", "Award score to the bot's controller (1 - award to player, 0 - award to bot)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarBotPlayerCash = CreateConVar("sm_bot_controller_cash", "1", "Award cash to the bot's controller (1 - award to player, 0 - award to bot)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarBotPlayerEquipment = CreateConVar("sm_bot_controller_equipment", "1", "Award equipment to the bot's controller (1 - award to player, 0 - award to bot)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// Cash award convars
	h_cvarMaxMoney             = FindConVar("mp_maxmoney");
	h_cvarCashBombCTWin        = FindConVar("cash_team_win_by_defusing_bomb");
	h_cvarCashBombTWin         = FindConVar("cash_team_terrorist_win_bomb");
	h_cvarCashBombTPlantLose   = FindConVar("cash_team_planted_bomb_but_defused");
	h_cvarCashEliminationWinCSCT = FindConVar("cash_team_elimination_hostage_map_ct");
	h_cvarCashEliminationWinCST = FindConVar("cash_team_elimination_hostage_map_t");
	h_cvarCashEliminationWinDE = FindConVar("cash_team_elimination_bomb_map");
	h_cvarCashHostageWin       = FindConVar("cash_team_win_by_hostage_rescue");
	h_cvarCashTimeoutWinB       = FindConVar("cash_team_win_by_time_running_out_bomb");
	h_cvarCashTimeoutWinH       = FindConVar("cash_team_win_by_time_running_out_hostage");
	h_cvarCashLoser            = FindConVar("cash_team_loser_bonus");
	h_cvarCashLoserConsecutive = FindConVar("cash_team_loser_bonus_consecutive_rounds");
	
	// Plugin convar hooks
	HookConVarChange(h_cvarBotPlayerKills, ConvarChanged);
	HookConVarChange(h_cvarBotPlayerAssists, ConvarChanged);
	HookConVarChange(h_cvarBotPlayerDeaths, ConvarChanged);
	HookConVarChange(h_cvarBotPlayerScore, ConvarChanged);
	HookConVarChange(h_cvarBotPlayerCash, ConvarChanged);
	HookConVarChange(h_cvarBotPlayerEquipment, ConvarChanged);
	
	// Cash award convar hooks
	HookConVarChange(h_cvarMaxMoney, ConvarChanged);
	HookConVarChange(h_cvarCashBombCTWin, ConvarChanged);
	HookConVarChange(h_cvarCashBombTWin, ConvarChanged);
	HookConVarChange(h_cvarCashBombTPlantLose, ConvarChanged);
	HookConVarChange(h_cvarCashEliminationWinCSCT, ConvarChanged);
	HookConVarChange(h_cvarCashEliminationWinCST, ConvarChanged);
	HookConVarChange(h_cvarCashEliminationWinDE, ConvarChanged);
	HookConVarChange(h_cvarCashHostageWin, ConvarChanged);
	HookConVarChange(h_cvarCashTimeoutWinB, ConvarChanged);
	HookConVarChange(h_cvarCashTimeoutWinH, ConvarChanged);
	HookConVarChange(h_cvarCashLoser, ConvarChanged);
	HookConVarChange(h_cvarCashLoserConsecutive, ConvarChanged);
	
	// Event hooks
	HookEvent("bot_takeover", OnBotTakeover);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("round_end", OnRoundEnd);
	
	// Execute configuration file
	AutoExecConfig(true, "botcontrollerstats");
}

/**********
 *Forwards*
***********/

public OnMapStart()
{
	UpdateAllConvars();
	GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
	for(new i = 1; i <= MaxClients; i++)
	{
		g_BotList[i] = 0;
		g_CashQueue[i] = 0;
	}
}

public OnClientDisconnect(client)
{
	g_BotList[client] = 0;
}

/********
 *Events*
*********/

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_AfterRound = false;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_BotList[i] > 0 && IsClientInGame(g_BotList[i]) && !IsFakeClient(g_BotList[i]))
		{
			g_CashQueue[g_BotList[i]] = 0;
			g_BotList[i] = 0;
		}
	}
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			// Award bot weapons to player at round start
			if(g_BotList[i] > 0 && g_cvarBotPlayerEquipment && IsClientInGame(g_BotList[i]))
				MigrateWeapons(i);
				
			// Award bot cash to player at round start
			if(g_CashQueue[i] != 0 && g_cvarBotPlayerCash)
				MigrateCash(i);
				
			// Make sure client cash is not out of range
			new ClientCash = GetEntData(i, ACCOUNT_OFFSET, 4);
			if(ClientCash < 0)
				SetEntData(i, ACCOUNT_OFFSET, 0);
			else if(ClientCash > g_cvarMaxMoney)
				SetEntData(i, ACCOUNT_OFFSET, g_cvarMaxMoney);
		}
	}
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	// Reset plugin variables if the game is being restarted
	if(reason == CSRoundEnd_GameStart)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			g_BotList[i] = 0;
			g_CashQueue[i] = 0;
		}
		return Plugin_Continue;
	}
	g_AfterRound = true;
	g_LastTerminateReason = reason;
	UpdateTeamScores();
	if(!g_cvarBotPlayerCash)
		return Plugin_Continue; // Nothing to do here if we aren't managing cash
		
	// Update player cash queue for next round
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || g_BotList[i] < 1)
			continue;
		if(GetClientTeam(i) == g_LastWinner)
			UpdateCashQueue(i, GetAugment(i, reason)); // Take into account money awarded after round end
		else
			UpdateCashQueue(i, GetAugment(i, reason) + g_ConsecutiveLossAugment); // Take into account consecutive loser bonus
	}
	return Plugin_Continue;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_BotList[i] > 0 && IsClientInGame(g_BotList[i]))
		{
			if(IsFakeClient(g_BotList[i]))
				MigrateStats(i); // Adjust stats after round has ended
			else
				g_BotList[i] = 0;
		}
	}
}

public OnBotTakeover(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new botid = GetClientOfUserId(GetEventInt(event, "botid"));
	
	// Get bot stats at time of takeover
	g_BotList[client] = botid;
	g_BotKills[client] = GetEntProp(botid, Prop_Data, "m_iFrags");
	new ASSISTS_OFFSET = FindDataMapOffs(botid, "m_iFrags") + 4;
	g_BotAssists[client] = GetEntData(botid, ASSISTS_OFFSET);
	g_BotScore[client] = GetEntData(botid, SCORE_OFFSET);
	g_BotCash[client] = GetEntData(client, ACCOUNT_OFFSET, 4);
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && g_BotList[client] > 0 && IsClientInGame(g_BotList[client]))
	{
		// Adjust stats and cash if player just died while controlling a bot
		if(IsFakeClient(g_BotList[client]))
		{
			MigrateStats(client);
			if(g_cvarBotPlayerDeaths)
				MigrateDeaths(client);
			if(g_cvarBotPlayerCash)
			{
				if(g_AfterRound)
					UpdateCashQueue(client, GetAugment(client, g_LastTerminateReason));
				else
					UpdateCashQueue(client, 0);
			}
		}
		g_BotList[client] = 0; // Player is no longer controlling a bot
	}
}

/*********
 *Helpers*
**********/

GetAugment(client, &CSRoundEndReason:reason)
{
	// Find how much cash the player won from the end of round
	if(GetClientTeam(client) == 2)
	{
		if(reason == CSRoundEnd_TargetBombed)
			return g_cvarCashBombTWin;
		if(reason == CSRoundEnd_BombDefused)
			return g_cvarCashBombTPlantLose;
		if(reason == CSRoundEnd_TargetSaved)
			return g_cvarCashLoser;
		if(reason == CSRoundEnd_HostagesRescued)
			return g_cvarCashLoser;
		if(reason == CSRoundEnd_HostagesNotRescued)
			return g_cvarCashTimeoutWinH;
		if(reason == CSRoundEnd_CTWin)
			return g_cvarCashLoser;
		if(reason == CSRoundEnd_TerroristWin)
			return (StrEqual(g_CurrentMap, "cs_") ? g_cvarCashEliminationWinCST : g_cvarCashEliminationWinDE);
	}
	else if(GetClientTeam(client) == 3)
	{
		if(reason == CSRoundEnd_TargetBombed)
			return g_cvarCashLoser;
		if(reason == CSRoundEnd_BombDefused)
			return g_cvarCashBombCTWin;
		if(reason == CSRoundEnd_TargetSaved)
			return g_cvarCashTimeoutWinB;
		if(reason == CSRoundEnd_HostagesRescued)
			return g_cvarCashHostageWin;
		if(reason == CSRoundEnd_HostagesNotRescued)
			return g_cvarCashLoser;
		if(reason == CSRoundEnd_CTWin)
			return (StrEqual(g_CurrentMap, "cs_") ? g_cvarCashEliminationWinCSCT : g_cvarCashEliminationWinDE);
		if(reason == CSRoundEnd_TerroristWin)
			return g_cvarCashLoser;
	}
	return 0;
}

MigrateCash(client)
{
	// Adjust client and bot cash according to what is in their cash queue
	new ClientCash = GetEntData(client, ACCOUNT_OFFSET, 4) + g_CashQueue[client];
	SetEntData(client, ACCOUNT_OFFSET, ClientCash);
	
	// Compensate for cash underflow or overflow
	if(g_BotList[client] > 0)
	{
		if(ClientCash < 0) // If client lost more money than they have, deduct underflow from their bot
		{
			new BotCash = GetEntData(g_BotList[client], ACCOUNT_OFFSET, 4) + ClientCash;
			SetEntData(g_BotList[client], ACCOUNT_OFFSET, BotCash);
		}
		else if(ClientCash > g_cvarMaxMoney) // If client gained more money than the maximum allowed, award overflow to their bot
		{
			new BotCash = GetEntData(g_BotList[client], ACCOUNT_OFFSET, 4) + ClientCash - g_cvarMaxMoney;
			SetEntData(g_BotList[client], ACCOUNT_OFFSET, BotCash);
		}
	}
	g_CashQueue[client] = 0;
	g_BotList[client] = 0;
}

MigrateDeaths(client)
{
	new BotDeaths = GetEntProp(g_BotList[client], Prop_Data, "m_iDeaths");
	new ClientDeaths = GetEntProp(client, Prop_Data, "m_iDeaths");
	SetEntProp(client, Prop_Data, "m_iDeaths", ClientDeaths + 1);
	SetEntProp(g_BotList[client], Prop_Data, "m_iDeaths", BotDeaths - 1);
}

MigrateStats(client)
{
	// Get difference in bot stats
	new BotKills = GetEntProp(g_BotList[client], Prop_Data, "m_iFrags") - g_BotKills[client];
	new ASSISTS_OFFSET = FindDataMapOffs(g_BotList[client], "m_iFrags") + 4;
	new BotAssists = GetEntData(g_BotList[client], ASSISTS_OFFSET) - g_BotAssists[client];
	new BotScore = GetEntData(g_BotList[client], SCORE_OFFSET) - g_BotScore[client];
		
	// Get current client stats
	new ClientKills = GetEntProp(client, Prop_Data, "m_iFrags");
	ASSISTS_OFFSET = FindDataMapOffs(client, "m_iFrags") + 4;
	new ClientAssists = GetEntData(client, ASSISTS_OFFSET);
	new ClientScore = GetEntData(client, SCORE_OFFSET);

	// Adjust bot and player stats
	if(g_cvarBotPlayerKills)
	{
		SetEntProp(client, Prop_Data, "m_iFrags", ClientKills + BotKills);
		SetEntProp(g_BotList[client], Prop_Data, "m_iFrags", g_BotKills[client]);
	}
	if(g_cvarBotPlayerAssists)
	{
		SetEntData(client, ASSISTS_OFFSET, ClientAssists + BotAssists);
		ASSISTS_OFFSET = FindDataMapOffs(g_BotList[client], "m_iFrags") + 4;
		SetEntData(g_BotList[client], ASSISTS_OFFSET, g_BotAssists[client]);
	}
	if(g_cvarBotPlayerScore)
	{
		SetEntData(client, SCORE_OFFSET, ClientScore + BotScore);
		SetEntData(g_BotList[client], SCORE_OFFSET, g_BotScore[client]);
	}
}

MigrateWeapons(client)
{
	new weapon;
	decl String:weaponName[64];
	
	// Find weapon in primary slot and give it to the player
	weapon = GetPlayerWeaponSlot(g_BotList[client], 0);
	if(weapon > 0)
	{
		GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		GivePlayerItem(client, weaponName);
		RemovePlayerItem(g_BotList[client], weapon);
	}
	
	// Find weapon in pistol slot and give it to the player
	weapon = GetPlayerWeaponSlot(g_BotList[client], 1);
	new pistol = GetPlayerWeaponSlot(client, 1);
	if(weapon > 0)
	{
		if(weapon != pistol) // Make sure the bot's pistol isn't the default starting pistol
		{
			GetEntityClassname(weapon, weaponName, sizeof(weaponName));
			RemovePlayerItem(client, pistol);
			GivePlayerItem(client, weaponName);
			GetEntityClassname(pistol, weaponName, sizeof(weaponName));
			RemovePlayerItem(g_BotList[client], weapon);
			GivePlayerItem(g_BotList[client], weaponName);
		}
	}
	
	// Find taser in knife slot and give it to the player
	new knife = GetPlayerWeaponSlot(g_BotList[client], 2);
	if(knife > 0)
	{
		RemovePlayerItem(g_BotList[client], knife);
		weapon = GetPlayerWeaponSlot(g_BotList[client], 2);
		if(weapon > 0 && weapon != knife)
		{
			GetEntityClassname(weapon, weaponName, sizeof(weaponName));
			GivePlayerItem(client, weaponName);
			RemovePlayerItem(g_BotList[client], weapon);
		}
		GetEntityClassname(knife, weaponName, sizeof(weaponName));
		GivePlayerItem(g_BotList[client], weaponName);
	}
	
	// Find grenades in projectile slot and give them to the player
	for(new i = 0; i < 5; i++)
	{
		weapon = GetPlayerWeaponSlot(g_BotList[client], 3);
		if(weapon < 1)
			break;
		GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		GivePlayerItem(client, weaponName);
		RemovePlayerItem(g_BotList[client], weapon);
	}
}
			

UpdateCashQueue(client, augment)
{
	// Update cash queue for client and their bot.
	new CashDifference = GetEntData(client, ACCOUNT_OFFSET, 4) - g_BotCash[client] - augment;
	g_CashQueue[client] += CashDifference;
	g_CashQueue[g_BotList[client]] -= CashDifference;
}

UpdateTeamScores()
{
	new CTWins = CS_GetTeamScore(3);
	new TWins = CS_GetTeamScore(2);
	
	// Check for consecutive losses and adjust consecutive loss bonus cash
	if(CTWins > g_CTWins)
	{
		if(g_LastWinner == 3)
			g_ConsecutiveLossAugment += g_cvarCashLoserConsecutive;
		else
		{
			g_ConsecutiveLossAugment = 0;
			g_LastWinner = 3;
		}
	}
	else if(TWins > g_TWins)
	{
		if(g_LastWinner == 2)
			g_ConsecutiveLossAugment += g_cvarCashLoserConsecutive;
		else
		{
			g_ConsecutiveLossAugment = 0;
			g_LastWinner = 2;
		}
	}
	g_CTWins = CTWins;
	g_TWins = TWins;
}
	

/*********
 *Convars*
**********/

public ConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_cvarBotPlayerKills)
		g_cvarBotPlayerKills       = GetConVarBool(h_cvarBotPlayerKills);
	else if(cvar == h_cvarBotPlayerAssists)
		g_cvarBotPlayerAssists     = GetConVarBool(h_cvarBotPlayerAssists);
	else if(cvar == h_cvarBotPlayerDeaths)
		g_cvarBotPlayerDeaths      = GetConVarBool(h_cvarBotPlayerDeaths);
	else if(cvar == h_cvarBotPlayerScore)
		g_cvarBotPlayerScore       = GetConVarBool(h_cvarBotPlayerScore);
	else if(cvar == h_cvarBotPlayerCash)
		g_cvarBotPlayerCash        = GetConVarBool(h_cvarBotPlayerCash);
	else if(cvar == h_cvarBotPlayerEquipment)
		g_cvarBotPlayerEquipment   = GetConVarBool(h_cvarBotPlayerEquipment);
	else if(cvar == h_cvarMaxMoney)
		g_cvarMaxMoney             = GetConVarInt(h_cvarMaxMoney);
	else if(cvar == h_cvarCashBombCTWin)
		g_cvarCashBombCTWin        = GetConVarInt(h_cvarCashBombCTWin);
	else if(cvar == h_cvarCashBombTWin)
		g_cvarCashBombTWin         = GetConVarInt(h_cvarCashBombTWin);
	else if(cvar == h_cvarCashBombTPlantLose)
		g_cvarCashBombTPlantLose   = GetConVarInt(h_cvarCashBombTPlantLose);
	else if(cvar == h_cvarCashEliminationWinCSCT)
		g_cvarCashEliminationWinCSCT = GetConVarInt(h_cvarCashEliminationWinCSCT);
	else if(cvar == h_cvarCashEliminationWinCST)
		g_cvarCashEliminationWinCST = GetConVarInt(h_cvarCashEliminationWinCST);
	else if(cvar == h_cvarCashEliminationWinDE)
		g_cvarCashEliminationWinDE = GetConVarInt(h_cvarCashEliminationWinDE);
	else if(cvar == h_cvarCashHostageWin)
		g_cvarCashHostageWin       = GetConVarInt(h_cvarCashHostageWin);
	else if(cvar == h_cvarCashTimeoutWinH)
		g_cvarCashTimeoutWinH       = GetConVarInt(h_cvarCashTimeoutWinH);
	else if(cvar == h_cvarCashLoser)
		g_cvarCashLoser            = GetConVarInt(h_cvarCashLoser);
	else if(cvar == h_cvarCashLoserConsecutive)
		g_cvarCashLoserConsecutive = GetConVarInt(h_cvarCashLoserConsecutive);
}

UpdateAllConvars()
{
	// Plugin convars
	g_cvarBotPlayerKills       = GetConVarBool(h_cvarBotPlayerKills);
	g_cvarBotPlayerAssists     = GetConVarBool(h_cvarBotPlayerAssists);
	g_cvarBotPlayerDeaths      = GetConVarBool(h_cvarBotPlayerDeaths);
	g_cvarBotPlayerScore       = GetConVarBool(h_cvarBotPlayerScore);
	g_cvarBotPlayerCash        = GetConVarBool(h_cvarBotPlayerCash);
	g_cvarBotPlayerEquipment   = GetConVarBool(h_cvarBotPlayerEquipment);
	
	// Cash award convars
	g_cvarMaxMoney             = GetConVarInt(h_cvarMaxMoney);
	g_cvarCashBombCTWin        = GetConVarInt(h_cvarCashBombCTWin);
	g_cvarCashBombTWin         = GetConVarInt(h_cvarCashBombTWin);
	g_cvarCashBombTPlantLose   = GetConVarInt(h_cvarCashBombTPlantLose);
	g_cvarCashEliminationWinCSCT = GetConVarInt(h_cvarCashEliminationWinCSCT);
	g_cvarCashEliminationWinCST = GetConVarInt(h_cvarCashEliminationWinCST);
	g_cvarCashEliminationWinDE = GetConVarInt(h_cvarCashEliminationWinDE);
	g_cvarCashHostageWin       = GetConVarInt(h_cvarCashHostageWin);
	g_cvarCashTimeoutWinH       = GetConVarInt(h_cvarCashTimeoutWinH);
	g_cvarCashTimeoutWinB      = GetConVarInt(h_cvarCashTimeoutWinB);
	g_cvarCashLoser            = GetConVarInt(h_cvarCashLoser);
	g_cvarCashLoserConsecutive = GetConVarInt(h_cvarCashLoserConsecutive);
	
	// Consecutive loss cash bonus variables
	g_CTWins = 0;
	g_TWins  = 0;
	g_LastWinner = 0;
	g_ConsecutiveLossAugment = 0;
}