/**
 * Copyright (C) 2023  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

bool g_bIsEnabled;
int g_nPrevGameType;
DynamicDetour g_hDetour;
ConVar sm_arena_waitingforplayers_enabled;

public Plugin myinfo =
{
	name = "Arena Waiting For Players",
	author = "Mikusch",
	description = "Enables Waiting For Players in arena mode.",
	version = "1.0.0",
	url = "https://github.com/Mikusch/arenawfp"
}

public void OnPluginStart()
{
	sm_arena_waitingforplayers_enabled = CreateConVar("sm_arena_waitingforplayers_enabled", "1", "Whether to enable Waiting For Players in arena mode.");
	sm_arena_waitingforplayers_enabled.AddChangeHook(OnEnableConVarChanged);
	
	GameData hGameConf = new GameData("arenawfp");
	if (!hGameConf)
		SetFailState("Failed to load arenawfp gamedata");
	
	g_hDetour = DynamicDetour.FromConf(hGameConf, "CTeamplayRoundBasedRules::SetInWaitingForPlayers");
	if (!g_hDetour)
		SetFailState("Failed to create detour setup handle for CTeamplayRoundBasedRules::SetInWaitingForPlayers");
}

public void OnPluginEnd()
{
	if (!g_bIsEnabled)
		return;
	
	TogglePlugin(false);
}

public void OnConfigsExecuted()
{
	if (g_bIsEnabled != sm_arena_waitingforplayers_enabled.BoolValue)
	{
		TogglePlugin(sm_arena_waitingforplayers_enabled.BoolValue);
	}
}

void TogglePlugin(bool enable)
{
	g_bIsEnabled = enable;
	
	if (enable)
	{
		g_hDetour.Enable(Hook_Pre, CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre);
		g_hDetour.Enable(Hook_Post, CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post);
	}
	else
	{
		g_hDetour.Disable(Hook_Pre, CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre);
		g_hDetour.Disable(Hook_Post, CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post);
	}
}

void OnEnableConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bIsEnabled != convar.BoolValue)
	{
		TogglePlugin(convar.BoolValue);
	}
}

MRESReturn CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre(DHookParam params)
{
	g_nPrevGameType = GameRules_GetProp("m_nGameType");
	GameRules_SetProp("m_nGameType", 0);
	
	bool bWaitingForPlayers = params.Get(1);
	
	if (bWaitingForPlayers)
		GameRules_SetPropFloat("m_flRestartRoundTime", -1.0);
	
	return MRES_Handled;
}

MRESReturn CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post(DHookParam params)
{
	GameRules_SetProp("m_nGameType", g_nPrevGameType);
	
	return MRES_Handled;
}
