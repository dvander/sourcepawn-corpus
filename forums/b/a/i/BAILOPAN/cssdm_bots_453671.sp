#include <sourcemod>

/* This code is licensed under the GNU General Public License, version 2 or greater */

public Plugin:myinfo = 
{
	name = "CS:S DM Bot Quotas",
	author = "BAILOPAN",
	description = "Bot Quota Correction for CS:S DM",
	version = "1.0.0.0",
	url = "http://www.bailopan.net/cssdm/"
}

/* CS:S ConVars */
new Handle:BotQuota = INVALID_HANDLE

/* Our ConVars */
new Handle:BalanceAmt = INVALID_HANDLE

public OnPluginStart()
{
	/* Find CS:S ConVars */
	BotQuota = FindConVar("bot_quota")
	
	/* Create our ConVars */
	BalanceAmt = CreateConVar("cssdm_bots_balance", "0", "Minimum number of players (bot_quota)")
	HookConVarChange(BalanceAmt, OnBalanceChange)
}

public OnBalanceChange(Handle:convar, const String:oldval[], const String:newval[])
{
	BalanceBots(StringToInt(newval))
}

BalanceBots(quota)
{
	new maxClients = GetMaxClients()
	new humans, bots
	
	/* Get the number of valid humans and bots */
	for (new i=1; i<=maxClients; i++)
	{
		if (!IsPlayerInGame(i))
		{
			continue
		}
		if (!IsFakeClient(i))
		{
			humans++
		} else {
			bots++
		}
	}
	
	/* Get the number of bots needed to fill quota */
	if (quota < humans)
	{
		quota = 0
	} else {
		quota -= humans
	}
	
	/* Now, set the new value */
	SetConVarInt(BotQuota, quota)
}

public OnClientPutInServer(client)
{
	BalanceBots(GetConVarInt(BalanceAmt))
}

public OnClientDisconnect_Post(client)
{
	BalanceBots(GetConVarInt(BalanceAmt))
}
