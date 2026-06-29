/**
 * =============================================================================
 * SourceMod "sell our souls"
 * Fun plugin: change some of your HP to cash
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

#pragma semicolon 1

#include <ata_tools>

#define PLUGIN_CFGNAME						"ata_sos"
#define COMMAND_SOS								"sos"

#define CSS_TEAM_NONE							0
#define CSS_TEAM_SPECTATOR				1
#define CSS_TEAM_T								2
#define CSS_TEAM_CT								3

new Handle:g_hPluginEnable				= INVALID_HANDLE;
new Handle:g_hMoneyPerHP					= INVALID_HANDLE;

new Handle:g_hCVarFreezeTime			= INVALID_HANDLE;
new Handle:g_hCVarBuyTime					= INVALID_HANDLE;

new	g_iAccount										= -1;
new	g_bInBuyZone									= -1;

new Float:g_fBuyTimeEnd						= 0.0;

// ----------------------------------------------------------------------------
public Plugin:myinfo = 
// ----------------------------------------------------------------------------
{
	name					= "Sell Our Souls",
	author				= "ata-clan.de",
	description		= "change some of your HP to cash",
	version				= "0.1",
	url						= "http://www.ata-clan.de/"
};

// ----------------------------------------------------------------------------
public OnPluginStart()
// ----------------------------------------------------------------------------
{
	g_iAccount				= FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_bInBuyZone			= FindSendPropInfo("CCSPlayer", "m_bInBuyZone");

	g_hPluginEnable		= CreateConVar("sm_sos_enable",				"1",		"enable the plugin", _, true, 0.0, true, 1.0);
	g_hMoneyPerHP			= CreateConVar("sm_sos_money_per_hp",	"100",	"Amount of money players get for one HP", _, true, 0.0, true, 16000.0);

	AutoExecConfig(true, PLUGIN_CFGNAME);

	if(GetConVarBool(g_hPluginEnable))
	{
		RegConsoleCmd(COMMAND_SOS, SellOurSouls, "Sell Our Souls!");
		HookEvent("player_spawn", EventPlayerSpawn);
	}
}

// ----------------------------------------------------------------------------
public OnMapStart()
// ----------------------------------------------------------------------------
{
	g_hCVarFreezeTime	= FindConVar("mp_freezetime");
	g_hCVarBuyTime		= FindConVar("mp_buytime");
}

// ----------------------------------------------------------------------------
public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
// ----------------------------------------------------------------------------
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) <= CSS_TEAM_SPECTATOR)
		return Plugin_Continue;

	g_fBuyTimeEnd = GetEngineTime() + GetConVarFloat(g_hCVarFreezeTime) + GetConVarFloat(g_hCVarBuyTime) * 60;

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
public Action:SellOurSouls(client, args)
// ----------------------------------------------------------------------------
{
	if(!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	new bool:bInBuyZone = bool:GetEntData(client, g_bInBuyZone, 1);
	if(!bInBuyZone || GetEngineTime() > g_fBuyTimeEnd)
		return Plugin_Handled;

	new nHP = 0;
	new String:sArg[32];
	if(args >= 1 && GetCmdArg(1, sArg, sizeof(sArg)))
		nHP = StringToInt(sArg);
	if(nHP >= GetClientHealth(client))
		nHP = GetClientHealth(client)-1;

	new nMoney = nHP * GetConVarInt(g_hMoneyPerHP);
	if((GetEntData(client, g_iAccount) + nMoney) > 16000)
		nMoney = 16000 - GetEntData(client, g_iAccount);

	new String:sClientName[64];
	GetClientName(client, sClientName, sizeof(sClientName));
//	PrintToChatAll("%t", "sos_player_sells", sClientName, nMoney, nHP);
	PrintToChatAll("%s sells his soul and gets %d$ for %d HP.", sClientName, nMoney, nHP);

	// take health
	SlapPlayer(client, nHP);

	// give money
	SetEntData(client, g_iAccount, GetEntData(client, g_iAccount) + nMoney);

	return Plugin_Handled;
}
