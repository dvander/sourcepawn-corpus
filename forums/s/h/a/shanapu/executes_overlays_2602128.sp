/*
 * Executes - Bombsite overlays
 * by: shanapu
 * https://github.com/shanapu/executes-overlays
 * 
 * Version: 1.2
 * 
 * Copyright (C) 2018 Thomas Schmidt (shanapu)
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
 * this program. If not, see <http:// www.gnu.org/licenses/>.
 */


#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <overlays>
#include <executes>


#pragma semicolon 1
#pragma newdecls required


ConVar gc_bTeam;
ConVar gc_fTime;
ConVar gc_sPathA;
ConVar gc_sPathB;


char g_sPathA[64];
char g_sPathB[64];


public Plugin myinfo = {
	name = "Executes - Bombsite overlays",
	author = "shanapu",
	description = "Show a overlay with the actual bomsite",
	version = "1.2",
	url = "https://github.com/shanapu/executes-overlays"
};


public void OnPluginStart()
{
	CreateConVar("sm_executes_overlays_version", "1.2", "The version of this SourceMod plugin", FCVAR_DONTRECORD);
	
	gc_bTeam = CreateConVar("sm_executes_overlays_team", "0", "Show overlays only for terrorists", _, true, 0.0, true, 1.0);
	gc_fTime = CreateConVar("sm_executes_overlays_time", "5.0", "How long show the Bombsite overlays? in seconds", _, true, 1.0);
	gc_sPathA = CreateConVar("sm_executes_overlays_path_a", "overlays/retake/a", "Path to the bombsite A overlay DONT TYPE .vmt or .vft");
	gc_sPathB = CreateConVar("sm_executes_overlays_path_b", "overlays/retake/b", "Path to the bombsite B overlay DONT TYPE .vmt or .vft");

	gc_sPathA.GetString(g_sPathA, sizeof(g_sPathA));
	gc_sPathB.GetString(g_sPathB, sizeof(g_sPathB));

	HookConVarChange(gc_sPathA, OnSettingChanged);
	HookConVarChange(gc_sPathB, OnSettingChanged);

	AutoExecConfig(true, "overlays", "sourcemod/executes");

	HookEvent("round_poststart", Event_PostRoundStart);
}


public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sPathA)
	{
		strcopy(g_sPathA, sizeof(g_sPathA), newValue);
		PrecacheDecalAnyDownload(g_sPathA);
	}
	else if (convar == gc_sPathB)
	{
		strcopy(g_sPathB, sizeof(g_sPathB), newValue);
		PrecacheDecalAnyDownload(g_sPathB);
	}
}


public void OnMapStart()
{
	PrecacheDecalAnyDownload(g_sPathA);
	PrecacheDecalAnyDownload(g_sPathB);
}

public void Event_PostRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (Executes_GetCurrrentBombsite() == BombsiteA)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			if (gc_bTeam.BoolValue && GetClientTeam(i) != CS_TEAM_CT)
				continue;

			ShowOverlay(i, g_sPathA, gc_fTime.FloatValue);
		}
	}
	else if (Executes_GetCurrrentBombsite() == BombsiteB)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			if (gc_bTeam.BoolValue && GetClientTeam(i) != CS_TEAM_CT)
				continue;

			ShowOverlay(i, g_sPathB, gc_fTime.FloatValue);
		}
	}
}