/*
 * Retakes - FailToPlant Plugin.
 * by: shanapu
 * https://github.com/shanapu/retake-FailToPlant
 * 
 * to use with https://github.com/splewis/csgo-retakes/
 * 
 * Copyright (C) 2017 Thomas Schmidt (shanapu)
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#define PLUGIN_VERSION "1.2"

// Includes
#include <sourcemod>
#include <sdktools>
#include <retakes>

// Optional Plugins
#undef REQUIRE_PLUGIN
#include <sourcebans>
#include <sourcebanspp>
#define REQUIRE_PLUGIN

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

// Console Variables
ConVar gc_bPlugin;
ConVar gc_iFailNumber;
ConVar gc_bAction;
ConVar gc_iBanTime;
ConVar gc_sBanReason;

// Intergers
int g_iFailedToPlant[MAXPLAYERS + 1];

// Strings
char g_sBanReason[128];

// Info
public Plugin myinfo =
{
	name = "FailedToPlant",
	author = "shanapu",
	description = "Kick/Ban players who failed to plant the bomb in retakes",
	version = PLUGIN_VERSION,
	url = "https://github.com/shanapu/retakes-FailToPlant"
};

// Start
public void OnPluginStart()
{
	// Config
	CreateConVar("sm_retakes_fail_plant_version", PLUGIN_VERSION, "The version of this SourceMod plugin", FCVAR_DONTRECORD);

	gc_bPlugin = CreateConVar("sm_retakes_fail_plant_enable", "1", "0 - disabled, 1 - enable this plugin", _, true, 0.0, true, 1.0);
	gc_iFailNumber = CreateConVar("sm_retakes_fail_plant_times", "3", "How many times to fail to plant bomb before take action", _, true, 1.0);
	gc_bAction = CreateConVar("sm_retakes_fail_plant_action", "0", "What action after a player reach sm_retakes_fail_plant_times? 0 - Kick / 1 - Ban", _, true, 0.0, true, 1.0);
	gc_iBanTime = CreateConVar("sm_retakes_fail_plant_ban_time", "15", "How long should the player banned on 'sm_retakes_fail_plant_times' '2'? In Minutes / 0 = permanent", _, true, 0.0);
	gc_sBanReason = CreateConVar("sm_retakes_fail_plant_reason", "You failed to often to plant the bomb", "The kick/ban reason for a player", _, true, 0.0);

	AutoExecConfig(true, "FailedToPlant", "sourcemod/retakes");

	HookConVarChange(gc_sBanReason, OnSettingChanged);

	gc_sBanReason.GetString(g_sBanReason, sizeof(g_sBanReason));
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sBanReason)
	{
		strcopy(g_sBanReason, sizeof(g_sBanReason), newValue);
	}
}

public void OnClientConnected(int client)
{
	g_iFailedToPlant[client] = 0;
}

public void Retakes_OnFailToPlant(int client)
{
	if (!gc_bPlugin.BoolValue)
		return;

	g_iFailedToPlant[client]++;

	if (g_iFailedToPlant[client] >= gc_iFailNumber.IntValue)
	{
		if (!gc_bAction.BoolValue) // kick player
		{
			LogMessage("Autokicked client %L for fail to plant.", client);
			Retakes_MessageToAll("%N was kicked for fail to plant %i times.", client, gc_iFailNumber.IntValue);

			KickClient(client, g_sBanReason);
		}
		else // ban player
		{
			if (GetFeatureStatus(FeatureType_Native, "SBPP_BanPlayer") == FeatureStatus_Available)
			{
				LogMessage("Autobanned client %L for fail to plant via SourceBans.", client);

				SBPP_BanPlayer(0, client, gc_iBanTime.IntValue, g_sBanReason);
			}
			else if (GetFeatureStatus(FeatureType_Native, "SBBanPlayer") == FeatureStatus_Available)
			{
				LogMessage("Autobanned client %L for fail to plant via SourceBans.", client);

				SBBanPlayer(0, client, gc_iBanTime.IntValue, g_sBanReason);
			}
			else
			{
				LogMessage("Autobanned client %L for fail to plant.", client);

				BanClient(client, gc_iBanTime.IntValue, BANFLAG_AUTHID, g_sBanReason, g_sBanReason, "Retakes - FailToPlant");
			}

			Retakes_MessageToAll("%N was banned for fail to plant %i times.", client, gc_iFailNumber.IntValue);
		}
	}
	else
	{
		if (!gc_bAction.BoolValue) // kick msg
		{
			Retakes_Message(client, "You failed to plant {PURPLE}%i time(s){NORMAL}! You will be kicked on {PURPLE}%i fails{NORMAL}.", g_iFailedToPlant[client], gc_iFailNumber.IntValue);
		}
		else // ban msg
		{
			Retakes_Message(client, "You failed to plant {PURPLE}%i time(s){NORMAL}! You will be banned on {PURPLE}%i fails{NORMAL}.", g_iFailedToPlant[client], gc_iFailNumber.IntValue);
		}
	}
}