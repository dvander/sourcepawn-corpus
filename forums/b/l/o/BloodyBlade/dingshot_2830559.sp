//# vim: set filetype=cpp :

/*
Dingshot a SourceMod L4D2 Plugin
Copyright (C) 2016  Victor B. Gonzalez

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar g_cvPluginOn, g_cvHeadShot, g_cvKillShot;
char g_HeadShot[256], g_KillShot[256];
bool bHooked = false;

public Plugin myinfo =
{
	name = "Dingshot",
	author = "Victor BUCKWANGS Gonzalez",
	description = "DING Headshot!",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/vbgunz/Dingshot"
}

public void OnPluginStart()
{
	CreateConVar("dingshot_version", PLUGIN_VERSION, "Dingshot plugin version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_cvPluginOn = CreateConVar("l4d_respawn_time", "1", "PluginOn/Off", CVAR_FLAGS);
	g_cvHeadShot = CreateConVar("ds_headshot", "ui/littlereward.wav", "Sound bite for head shot", CVAR_FLAGS);
	g_cvKillShot = CreateConVar("ds_killshot", "level/bell_normal.wav", "Sound bite for kill shot to the head", CVAR_FLAGS);

	g_cvPluginOn.AddChangeHook(ConVarPluginOnChanged);
	g_cvHeadShot.AddChangeHook(UpdateConVarsHook);
	g_cvKillShot.AddChangeHook(UpdateConVarsHook);

	AutoExecConfig(true, "dingshot");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	IsAllowed();
}

void UpdateConVarsHook(ConVar convar, const char[] oldCv, const char[] newCv)
{
	g_cvHeadShot.GetString(g_HeadShot, sizeof(g_HeadShot));
	PrecacheSound(g_HeadShot, false);
	g_cvKillShot.GetString(g_KillShot, sizeof(g_KillShot));
	PrecacheSound(g_KillShot, false);
}

void IsAllowed()
{
	bool bPluginOn = g_cvPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		UpdateConVarsHook(null, "", "");
		HookEvent("player_hurt", HeadShotHook, EventHookMode_Pre);
		HookEvent("infected_hurt", HeadShotHook, EventHookMode_Pre);
		HookEvent("infected_death", HeadShotHook, EventHookMode_Pre);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("player_hurt", HeadShotHook, EventHookMode_Pre);
		UnhookEvent("infected_hurt", HeadShotHook, EventHookMode_Pre);
		UnhookEvent("infected_death", HeadShotHook, EventHookMode_Pre);
	}
}

void HeadShotHook(Event event, const char[] name, bool dontBroadcast)
{
	int hitgroup = 0, attacker = GetClientOfUserId(event.GetInt("attacker")), type = event.GetInt("type");
	if (strcmp(name, "infected_death") == 0)
	{
		hitgroup = event.GetInt("headshot");
		PlaySoundAll(attacker, g_KillShot, hitgroup, type);
	}
	else
	{
		hitgroup = event.GetInt("hitgroup");
		PlaySoundAll(attacker, g_HeadShot, hitgroup, type);
	}
}

void PlaySoundAll(int client, char g_sB[256], int HitGroup, int Type)
{
	if (IsClientValid(client) && HitGroup == 1 && Type != 8 && Type != 2097152)
	{  // 8 == death by fire... // 2097152 == dead by slow burn
		EmitSoundToClient(client, g_sB, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}

bool IsClientValid(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
