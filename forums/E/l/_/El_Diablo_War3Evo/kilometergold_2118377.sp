// *************************************************************************
// ata_kilometergold.sp (Abandoned by owner)
//
// Copyright (c) 2014  El Diablo <diablo@war3evo.info>
//  
//  Antihack is free software: you may copy, redistribute
//  and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//  
//  This file is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// This file incorporates work covered by the following copyright and
// permission notice:

/**
 * =============================================================================
 * SourceMod Kilometergold plugin
 * Fun plugin: players get money for walking around
 *
 * (C)2009 ata-clan.de
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define CSS_TEAM_NONE				0
#define CSS_TEAM_SPECTATOR	1
#define CSS_TEAM_T					2
#define CSS_TEAM_CT					3

new Float:fClientTimerCounter[MAXPLAYERS + 1];
new Float:fClientBonusCounter[MAXPLAYERS + 1];

new Float:g_pfClientPositions[MAXPLAYERS + 1][3];
new Handle:g_phClientTimers[MAXPLAYERS + 1];

new Handle:g_hEnabled					= INVALID_HANDLE;
new Handle:g_hTimer					= INVALID_HANDLE;
new Handle:g_hNegativeTimer			= INVALID_HANDLE;
new Handle:g_hMoneyPerMeterPostive	= INVALID_HANDLE;
new Handle:g_hMoneyPerMeterNegative	= INVALID_HANDLE;
new Handle:g_hMeterDistance			= INVALID_HANDLE;
new Handle:g_hAllowNegative			= INVALID_HANDLE;
new Handle:g_hAllowPositive			= INVALID_HANDLE;
new Handle:g_hAllowBonus			= INVALID_HANDLE;
new Handle:g_hBonusDistance			= INVALID_HANDLE;
new Handle:g_hBonusAmount			= INVALID_HANDLE;
new Handle:g_hDebugInChat			= INVALID_HANDLE;
new Handle:g_hNegativeReasonEnabled	= INVALID_HANDLE;
new Handle:g_hNegativeReasonAnswer	= INVALID_HANDLE;

new	g_iAccount							= -1;

// ----------------------------------------------------------------------------
public Plugin:myinfo =
// ----------------------------------------------------------------------------
{
	name					= "Kilometergold",
	author				= "El Diablo",
	description		= "players get money for walking around",
	version				= "0.2",
	url						= "http://www.war3evo.info/"
};


stock bool:kValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}


// ----------------------------------------------------------------------------
public OnPluginStart()
// ----------------------------------------------------------------------------
{
	g_hEnabled					= CreateConVar("sm_kilometergold_enabled",						"1",	"set to 0 to disable the plugin");
	g_hTimer					= CreateConVar("sm_kilometergold_positive_timer",				"1.0",	"how much time in seconds to get to distance to get money ; use floats only / do not touch if you do not understand");
	g_hNegativeTimer			= CreateConVar("sm_kilometergold_negative_timer",				"15.0",	"how much time in seconds before negative money is applied ; use floats only / only works if sm_kilometergold_allow_negative is 1");
	g_hMoneyPerMeterPostive		= CreateConVar("sm_kilometergold_moneypermeter_postive",		"2",	"how much money should a player get per walked meter ; set to 0 to disable this feature");
	g_hMoneyPerMeterNegative	= CreateConVar("sm_kilometergold_moneypermeter_negative",		"4",	"how much money should a player lose per negative timer ; set to 0 to disable this feature");
	g_hMeterDistance			= CreateConVar("sm_kilometergold_meter_distance",				"100.0",	"how far a player must walk to get money ; default 100");
	g_hAllowNegative			= CreateConVar("sm_kilometergold_allow_negative",				"1",	"allows players money to go negative if they do not meet the meter distance ; set to 0 to disable this feature");
	g_hAllowPositive			= CreateConVar("sm_kilometergold_allow_positive",				"1",	"allows players money to go positive if they meet the meter distance ; set to 0 to disable this feature");
	g_hAllowBonus				= CreateConVar("sm_kilometergold_allow_bonus",					"1",	"allows players money to gain bonuses ; set to 0 to disable this feature - must allow positive");
	g_hBonusDistance			= CreateConVar("sm_kilometergold_bonus_distance_total",			"1000",	"gain bonus after walking this far without stopping ; only works if sm_kilometergold_allow_bonus is 1");
	g_hBonusAmount				= CreateConVar("sm_kilometergold_bonus_amount",					"10",	"the amount of bonus ; only works if sm_kilometergold_allow_bonus is 1");
	g_hDebugInChat				= CreateConVar("sm_kilometergold_debug",						"0",	"debug messages in chat ; set to 0 to disable this feature");

	g_hNegativeReasonEnabled	= CreateConVar("sm_kilometergold_negative_reason_enabled",		"1",	"gives the player reason for negative money ; set to 0 to disable this feature");
	g_hNegativeReasonAnswer		= CreateConVar("sm_kilometergold_negative_reason_answer",		"You losing money for not moving around from your current spot.", "set sm_kilometergold_negative_reason_enabled to 0 to disable this feature");
	AutoExecConfig(true, "kilometergold");

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if(g_iAccount >= 0)
	{
		for(new i=0; i<MAXPLAYERS; i++)
		{
			g_phClientTimers[i] = INVALID_HANDLE;
			ResetVariables(i);
			if(kValidPlayer(i,true))
			{
				g_phClientTimers[i] = CreateTimer(GetConVarFloat(g_hTimer), ClientTimer, i);
			}
		}

		HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	}
}

/**
 * Prints Message to server and all chat
 * For debugging prints
 */
DP(const String:szMessage[], any:...)
{
	if(!GetConVarBool(g_hDebugInChat))
		return;

	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
}

// ----------------------------------------------------------------------------
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	if(!GetConVarBool(g_hEnabled))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) <= CSS_TEAM_SPECTATOR)
		return Plugin_Continue;

	ResetVariables(client);

	KillClientTimer(client);

	GetClientAbsOrigin(client, g_pfClientPositions[client]);
	g_phClientTimers[client] = CreateTimer(GetConVarFloat(g_hTimer), ClientTimer, client);

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:ClientTimer(Handle:timer, any:client)
// ----------------------------------------------------------------------------
{
	if(kValidPlayer(client,true))
	{
		new Float:pfCurrentPosition[3];
		GetClientAbsOrigin(client, pfCurrentPosition);

		new String:TmpStr[128];
		GetClientName(client,TmpStr,sizeof(TmpStr));

		new Float:Distance = GetVectorDistance(g_pfClientPositions[client], pfCurrentPosition);
		new CurrentMoney= GetEntData(client, g_iAccount);

		DP("%s walked %.2f distance",TmpStr,Distance);

		if(GetConVarBool(g_hAllowPositive) && Distance>GetConVarFloat(g_hMeterDistance))
		{
			fClientTimerCounter[client]=0.0;
			fClientBonusCounter[client]+=Distance;
			new nAmount	= CurrentMoney + GetConVarInt(g_hMoneyPerMeterPostive);
			// Not sure about this variable?  Maybe increase max.. I haven't really checked what max really is..
			if(nAmount > 65000)
				nAmount = 65000;
			if(GetConVarBool(g_hAllowBonus) && fClientBonusCounter[client]>=GetConVarFloat(g_hBonusDistance))
			{
				DP("sm_kilometergold_allow_bonus -- %s Gained Bonus! Total distance of %.2f",TmpStr,fClientBonusCounter[client]);
				nAmount += GetConVarInt(g_hBonusAmount);
				fClientBonusCounter[client]=0.0;
				DP("%s bonus counter reset");
			}
			SetEntData(client, g_iAccount, nAmount);
			g_pfClientPositions[client] = pfCurrentPosition;
			g_phClientTimers[client] = CreateTimer(GetConVarFloat(g_hTimer), ClientTimer, client);
			DP("sm_kilometergold_allow_positive -- %s walked %.2f distance",TmpStr,Distance);
			return Plugin_Handled;
		}
		else
		{
			fClientBonusCounter[client]=0.0;
			DP("%s bonus counter reset");
		}

		if(GetConVarBool(g_hAllowNegative) && Distance<=GetConVarFloat(g_hMeterDistance))
		{
			if(fClientTimerCounter[client]>=GetConVarFloat(g_hNegativeTimer))
			{
				new nAmount	= CurrentMoney - GetConVarInt(g_hMoneyPerMeterNegative);
				if(nAmount < 0)
					nAmount = 0;
				SetEntData(client, g_iAccount, nAmount);
				g_pfClientPositions[client] = pfCurrentPosition;
				g_phClientTimers[client] = CreateTimer(GetConVarFloat(g_hTimer), ClientTimer, client);
				fClientTimerCounter[client]=0.0;
				DP("sm_kilometergold_allow_negative -- %s walked %.2f distance",TmpStr,Distance);
				if(GetConVarBool(g_hNegativeReasonEnabled))
				{
					decl String:ReasonStr[256];
					GetConVarString(g_hNegativeReasonAnswer,ReasonStr,sizeof(ReasonStr));
					PrintToChat(client,ReasonStr);
				}
				return Plugin_Handled;
			}
			fClientTimerCounter[client]+=1.0;
		}

		g_pfClientPositions[client] = pfCurrentPosition;
		g_phClientTimers[client] = CreateTimer(GetConVarFloat(g_hTimer), ClientTimer, client);
	}
	else
	{
		ResetVariables(client);
		g_phClientTimers[client] = CreateTimer(GetConVarFloat(g_hTimer), ClientTimer, client);
	}

	return Plugin_Handled;
}

// ----------------------------------------------------------------------------
KillClientTimer(client)
// ----------------------------------------------------------------------------
{
	if(g_phClientTimers[client] != INVALID_HANDLE)
	{
		fClientTimerCounter[client]=0.0;
		KillTimer(g_phClientTimers[client]);
		g_phClientTimers[client] = INVALID_HANDLE;
	}
}
// ----------------------------------------------------------------------------
ResetVariables(client)
// ----------------------------------------------------------------------------
{
	fClientTimerCounter[client]=0.0;
	fClientBonusCounter[client]=0.0;
}
