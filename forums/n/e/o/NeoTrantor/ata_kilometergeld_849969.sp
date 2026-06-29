/**
 * =============================================================================
 * SourceMod Kilometergeld plugin
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

new Float:g_pfClientPositions[MAXPLAYERS + 1][3];
new Handle:g_phClientTimers[MAXPLAYERS + 1];
new Handle:g_hMoneyPerMeter	= INVALID_HANDLE;
new	g_iAccount							= -1;

// ----------------------------------------------------------------------------
public Plugin:myinfo =
// ----------------------------------------------------------------------------
{
	name					= "Kilometergeld",
	author				= "ata-clan.de",
	description		= "players get money for walking around",
	version				= "0.1",
	url						= "http://www.ata-clan.de/"
};

// ----------------------------------------------------------------------------
public OnPluginStart()
// ----------------------------------------------------------------------------
{
	g_hMoneyPerMeter = CreateConVar("sm_kilometergeld_moneypermeter",	"3",	"how much money should a player get per walked meter ; set to 0 to disable the plugin", 0, true, 0.0, true, 16000.0);
	AutoExecConfig(true, "ata_kilometergeld");

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if(g_iAccount >= 0)
	{
		for(new i=0; i<MAXPLAYERS; i++)
			g_phClientTimers[i] = INVALID_HANDLE;

		HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	}
}

// ----------------------------------------------------------------------------
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	if(GetConVarFloat(g_hMoneyPerMeter) < 1.0)
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) <= CSS_TEAM_SPECTATOR)
		return Plugin_Continue;

	KillClientTimer(client);

	GetClientAbsOrigin(client, g_pfClientPositions[client]);
	g_phClientTimers[client] = CreateTimer(1.0, ClientTimer, client, TIMER_REPEAT);

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:ClientTimer(Handle:timer, any:client)
// ----------------------------------------------------------------------------
{
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:pfCurrentPosition[3];
		GetClientAbsOrigin(client, pfCurrentPosition);
		new Float:fAmount = GetVectorDistance(g_pfClientPositions[client], pfCurrentPosition) * GetConVarFloat(g_hMoneyPerMeter) / 100.0;

		new nAmount	= GetEntData(client, g_iAccount) + RoundFloat(fAmount);
		if(nAmount > 16000)
			nAmount = 16000;
		SetEntData(client, g_iAccount, nAmount);

		g_pfClientPositions[client] = pfCurrentPosition;
	}
	else
	{
		KillClientTimer(client);
	}

	return Plugin_Handled;
}

// ----------------------------------------------------------------------------
KillClientTimer(client)
// ----------------------------------------------------------------------------
{
	if(g_phClientTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_phClientTimers[client]);
		g_phClientTimers[client] = INVALID_HANDLE;
	}
}
