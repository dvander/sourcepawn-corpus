/*	Copyright (C) 2021 Oylsister
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#define UNLIMITED 0
#define PER_ROUND 1
#define PER_MAP 2

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <zombiereloaded>

// This is for Shop Hlmod.ru
//#define SHOP_HLMOD
#if defined SHOP_HLMOD
#include <shop>
#endif

// Default for Zephyrus Store
#define STORE_ZEPHYRUS
#if defined STORE_ZEPHYRUS
#include <store>
#endif

//#define LR_RANK
#if defined LR_RANK
#include <lvl_ranks>
#endif

#pragma semicolon 1
#pragma newdecls required

Handle g_hCvarRequireDamage;
Handle g_hCvarCreditReward;
Handle g_hCvarEnabled;
Handle g_hCvarPrefix;
Handle g_hCvarMaxType;
Handle g_hCvarMaximum;

#if defined LR_RANK
Handle g_hCvarExpReward;
#endif

int g_iRequireDamage;
int g_iCreditReward;
bool g_bEnablePlugin;
char g_sPrefix[32];
int g_iMaxType;
int g_iMaxTime;

#if defined LR_RANK
int g_iExpReward;
#endif

bool g_bTempDisabled;

int g_iClientDamage[MAXPLAYERS+1] = 0;
int g_iClientTime[MAXPLAYERS+1] = 0;
bool g_iClientCanEarn[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[Shop] Defend Credits for Zombie:Reloaded", 
	author = "Oylsister", 
	description = "Give Credit to player after do damage to zombie for a while", 
	version = "1.3", 
	url = "https://github.com/oylsister"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_defcredits", Command_CheckStatus);

	g_hCvarEnabled = CreateConVar("sm_shop_defendcredit_enable", "1.0", "Enable Plugin or not?", _, true, 0.0, true, 1.0);
	g_hCvarRequireDamage = CreateConVar("sm_shop_defendcredit_damage", "5000", "How much damage that player need to get the credit", _, true, 0.0, false);
	g_hCvarCreditReward = CreateConVar("sm_shop_defendcredit_amount", "10", "How much credits player will received after reach specific damage", _, true, 0.0, false);
	g_hCvarPrefix = CreateConVar("sm_shop_defendcredit_prefix", "{green}[Defend]", "What prefix you would like to use?");
	g_hCvarMaxType = CreateConVar("sm_shop_defendcredit_maxtype", "0.0", "Maximum type that you want [0 = Disabled, 1 = Round, 2 = Map]", _, true, 0.0, true, 2.0);
	g_hCvarMaximum = CreateConVar("sm_shop_defendcredit_maximum", "5.0", "Maximum time that player will receive credits", _, true, 1.0, false);
	
	#if defined LR_RANK
	g_hCvarExpReward = CreateConVar("sm_shop_defendcredit_exp", "10", "How many EXP point that player will received after reach specific damage", _, true, 0.0, false);
	#endif
	
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", OnPlayerTakeDamage, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", OnPlayerChangeTeam, EventHookMode_PostNoCopy);
	
	HookConVarChange(g_hCvarCreditReward, OnConVarChange);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);
	HookConVarChange(g_hCvarRequireDamage, OnConVarChange);
	HookConVarChange(g_hCvarPrefix, OnConVarChange);
	
	#if defined LR_RANK
	HookConVarChange(g_hCvarExpReward, OnConVarChange);
	#endif

	AutoExecConfig();
}

public void OnMapStart()
{
	g_iCreditReward = GetConVarInt(g_hCvarCreditReward);
	g_bEnablePlugin = view_as<bool>(GetConVarInt(g_hCvarEnabled));
	g_iRequireDamage = GetConVarInt(g_hCvarRequireDamage);
	GetConVarString(g_hCvarPrefix, g_sPrefix, sizeof(g_sPrefix));
	g_iMaxType = GetConVarInt(g_hCvarMaxType);
	g_iMaxTime = GetConVarInt(g_hCvarMaximum);
	
	#if defined LR_RANK
	g_iExpReward = GetConVarInt(g_hCvarExpReward);
	#endif
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
			g_iClientTime[i] = 0;
			g_iClientCanEarn[i] = true;
		}
	}
}

public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
			g_iClientTime[i] = 0;
			g_iClientCanEarn[i] = true;
		}
	}
}

public void OnConVarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_hCvarCreditReward)
		g_iCreditReward = GetConVarInt(g_hCvarCreditReward);
		
	else if (cvar == g_hCvarEnabled)
		g_bEnablePlugin = view_as<bool>(GetConVarInt(g_hCvarEnabled));
		
	else if (cvar == g_hCvarRequireDamage)
		g_iRequireDamage = GetConVarInt(g_hCvarRequireDamage);
		
	else if (cvar == g_hCvarPrefix)
		GetConVarString(g_hCvarPrefix, g_sPrefix, sizeof(g_sPrefix));
		
	else if (cvar == g_hCvarMaxType)
		g_iMaxType = GetConVarInt(g_hCvarMaxType);
		
	else if (cvar == g_hCvarMaximum)
		g_iMaxTime = GetConVarInt(g_hCvarMaximum);
	
	#if defined LR_RANK
	else if (cvar == g_hCvarExpReward)
		g_iExpReward = GetConVarInt(g_hCvarExpReward);
	#endif
}

public Action Command_CheckStatus(int client, int args)
{
	if(!client)
	{
		return Plugin_Handled;
	}
	
	if(g_iMaxType == UNLIMITED)
	{
		CReplyToCommand(client, "%s{default} {orange}The current settings has no limited.", g_sPrefix);
		return Plugin_Handled;
	}
	
	if(g_iMaxType == PER_ROUND)
	{
		if(g_iClientTime[client] > g_iMaxTime)
		{
			CReplyToCommand(client, "%s{default} You can earn more {lightgreen}%d times {default}in this round.", g_sPrefix, g_iMaxTime - g_iClientTime[client]);
			return Plugin_Handled;
		}
		else
		{
			CReplyToCommand(client, "%s{default} {red}You are no longer allowed to earn defend credits in this round.", g_sPrefix);
			return Plugin_Handled;
		}
	}
	
	if(g_iMaxType == PER_MAP)
	{
		if(g_iClientTime[client] > g_iMaxTime)
		{
			CReplyToCommand(client, "%s{default} You can earn more {lightgreen}%d times {default}in this map.", g_sPrefix, g_iMaxTime - g_iClientTime[client]);
			return Plugin_Handled;
		}
		else
		{
			CReplyToCommand(client, "%s{default} {red}You are no longer allowed to earn defend credits in this map.", g_sPrefix);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
		
	g_bTempDisabled = false;
	
	// set damage check back to 0 this is to ensure that none of any player will cheat or get credits ahead of it.
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
				
			if(g_iMaxType == PER_ROUND)
			{
				g_iClientTime[i] = 0;
				g_iClientCanEarn[i] = true;
			}
			
			if(g_iMaxType > PER_MAP)
				CPrintToChat(i, "%s{default} The current round is enabled {orange}Defending Credit Reward, {red}Damaging Zombie {default}for a while will reward you with {lightgreen}Credit", g_sPrefix);
			
			else if(g_iMaxType <= PER_MAP)
				CPrintToChat(i, "%s{default} The current map is enabled {orange}Defending Credit Reward, {red}Damaging Zombie {default}for a while will reward you with {lightgreen}Credit", g_sPrefix);
		}
	}
}

public void OnPlayerTakeDamage(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;

	// warmup round? don't count the damage yet
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return;
	
	// if player making damage on round end, stop it.
	if(g_bTempDisabled)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!client || !attacker) 
		return;
		
	if(!g_iClientCanEarn[attacker] || g_iClientCanEarn[attacker] == false)
		return;
		
	int damage = GetEventInt(event, "dmg_health");
	
	// only for human!
	if (GetClientTeam(attacker) == 3 || ZR_IsClientHuman(attacker))
		g_iClientDamage[attacker] += damage;
	
	if (g_iClientDamage[attacker] >= g_iRequireDamage && g_iClientTime[attacker] < g_iMaxTime)
	{
		// Get client credits first
		#if defined SHOP_HLMOD
		int credits = Shop_GetClientCredits(attacker);
		#endif
		
		#if defined STORE_ZEPHYRUS
		int credits = Store_GetClientCredits(attacker);
		#endif
		
		// Then calculate the amount 
		int new_credits = credits + g_iCreditReward;
		
		// Set their credits to value from above.
		#if defined SHOP_HLMOD
		Shop_SetClientCredits(attacker, new_credits);
		#endif
		
		#if defined STORE_ZEPHYRUS
		Store_SetClientCredits(attacker, new_credits);
		#endif
		
		// Addition LR_Rank stuff
		#if defined LR_RANK
		LR_ChangeClientValue(attacker, g_iExpReward);
		CPrintToChat(attacker, "%s{default} You have received {lightgreen}%d {default}exp for damaging zombie!", g_sPrefix, g_iExpReward);
		#endif
		
		// show client a message that you get some credits!
		CPrintToChat(attacker, "%s{default} You have received {lightgreen}%d {default}credits for damaging zombie!", g_sPrefix, g_iCreditReward);
		
		// after received credits, roll back and start count damage again.
		g_iClientDamage[attacker] = 0;
		
		if(g_iMaxType < UNLIMITED)
			g_iClientTime[attacker]++;
		
		if(g_iClientTime[attacker] >= g_iMaxTime)
		{
			if(g_iMaxType == PER_ROUND)
			{
				CPrintToChat(attacker, "%s{default} You can no longer earn more {red}EXP {default}and {orange}Credits in this round.", g_sPrefix);
				g_iClientCanEarn[attacker] = false;
			}
				
			else if(g_iMaxType == PER_MAP)
			{
				CPrintToChat(attacker, "%s{default} You can no longer earn more {red}EXP {default}and {orange}Credits until next map.", g_sPrefix);
				g_iClientCanEarn[attacker] = false;
			}
		}
		
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
	
	// die? reset damage then.
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iClientDamage[client] = 0;
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
	
	// round end? stop count until new round start
	g_bTempDisabled = true;
	
	// reset back to 0 on round end
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iClientDamage[i] = 0;
			
			if(g_iMaxType == PER_ROUND)
			{
				g_iClientTime[i] = 0;
				g_iClientCanEarn[i] = true;
			}
		}
	}
}

public void OnPlayerChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnablePlugin) 
		return;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// reset them in case player go spectate
	g_iClientDamage[client] = 0;
}

public void ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	// become zombie only infect people, they don't do damage.
	g_iClientDamage[client] = 0;
}

public void OnClientConnected(int client)
{
	g_iClientDamage[client] = 0;
}

public void OnClientDisconnect(int client)
{
	g_iClientDamage[client] = 0;
}