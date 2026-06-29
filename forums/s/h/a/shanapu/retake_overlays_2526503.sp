/*
 * Retake - Bombsite overlays
 * by: shanapu
 * https://github.com/shanapu/retake-overlays
 * 
 * Version: 1.0
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
 * this program. If not, see <http:// www.gnu.org/licenses/>.
 */


#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <overlays>
#include <retakes>


#pragma semicolon 1
#pragma newdecls required


ConVar gc_bTeam;
ConVar gc_fTime;
ConVar gc_sPathA;
ConVar gc_sPathB;


char g_sPathA[64];
char g_sPathB[64];


public Plugin myinfo = {
	name = "Retake - Bombsite overlays",
	author = "shanapu",
	description = "Show a overlay with the actual bomsite",
	version = "1.1",
	url = "https://github.com/shanapu/retake-overlays"
};


public void OnPluginStart()
{
	CreateConVar("sm_retakes_overlays_version", "1.0", "The version of this SourceMod plugin", FCVAR_DONTRECORD);
	
	gc_bTeam = CreateConVar("sm_retake_overlays_team", "1", "Show overlays only for counter-terrorists", _, true, 0.0, true, 1.0);
	gc_fTime = CreateConVar("sm_retake_overlays_time", "5.0", "How long show the Bombsite overlays? in seconds", _, true, 1.0);
	gc_sPathA = CreateConVar("sm_retake_overlays_path_a", "overlays/retake/a", "Path to the bombsite A overlay DONT TYPE .vmt or .vft");
	gc_sPathB = CreateConVar("sm_retake_overlays_path_b", "overlays/retake/b", "Path to the bombsite B overlay DONT TYPE .vmt or .vft");

	gc_sPathA.GetString(g_sPathA, sizeof(g_sPathA));
	gc_sPathB.GetString(g_sPathB, sizeof(g_sPathB));

	HookConVarChange(gc_sPathA, OnSettingChanged);
	HookConVarChange(gc_sPathB, OnSettingChanged);

	AutoExecConfig(true, "overlays", "sourcemod/retakes");
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


public void Retakes_OnSitePicked(Bombsite& site)
{
	if (site == BombsiteA)
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
	else if (site == BombsiteB)
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