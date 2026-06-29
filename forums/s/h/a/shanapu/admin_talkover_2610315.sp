/*
 * Admin talkover
 * by: shanapu
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
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

// Includes
#include <sourcemod>
#include <sdktools>
#include <voiceannounce_ex>
#include <colors>

// Optional Plugins
#undef REQUIRE_PLUGIN
#include <basecomm>
#include <sourcecomms>
#define REQUIRE_PLUGIN

// Compiler Options
#pragma semicolon 1
#pragma newdecls required

ConVar gc_bMuteTalkOver;
ConVar gc_bDefault;
ConVar gc_sPrefix;

// Boolean
bool g_bEnable[MAXPLAYERS+1] = {false, ...};
bool g_bTempMuted[MAXPLAYERS+1] = {false, ...};
bool gp_bBasecomm = false;
bool gp_bSourceComms = false;

char g_sPrefix[64];

public Plugin myinfo = {
	name = "Admin talkover",
	author = "shanapu",
	description = "Please be quiet, the Admin speaks",
	version = "1.1",
	url = "https://github.com/shanapu/AdminTalkover"
};

public void OnPluginStart()
{
	LoadTranslations("admin_talkover.phrases");
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_talkover", Command_TalkOver, ADMFLAG_CHAT, "Toggle on/off admin talkover");

	CreateConVar("talkover_version", "1.1", "Version of this SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bMuteTalkOver = CreateConVar("talkover_enable", "1", "0 - disabled, 1 - enable plugin", _, true, 0.0, true, 1.0);
	gc_bDefault = CreateConVar("talkover_default", "1", "0 - disabled by default use command to enable, 1 - enabled by default use command to disable", _, true, 0.0, true, 1.0);
	gc_sPrefix = CreateConVar("talkover_prefix", "[SM]", "Set your chat prefix for this plugin.");

	AutoExecConfig(true, "admin_talkover", "sourcemod");

	HookConVarChange(gc_sPrefix, OnSettingChanged);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sPrefix)
	{
		strcopy(g_sPrefix, sizeof(g_sPrefix), newValue);
	}
}

public void OnConfigsExecuted()
{
	gc_sPrefix.GetString(g_sPrefix, sizeof(g_sPrefix));
}

public void OnAllPluginsLoaded()
{
	gp_bBasecomm = LibraryExists("basecomm");
	gp_bSourceComms = LibraryExists("sourcecomms");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "basecomm"))
	{
		gp_bBasecomm = false;
	}
	else if (StrEqual(name, "sourcecomms"))
	{
		gp_bSourceComms = false;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "basecomm"))
	{
		gp_bBasecomm = true;
	}
	else if (StrEqual(name, "sourcecomms"))
	{
		gp_bSourceComms = true;
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_bEnable[client] = gc_bDefault.BoolValue;
}

public Action Command_TalkOver(int client, int args)
{
	if (client == 0)
	{
		CReplyToCommand(client, "%s %t", g_sPrefix, "Command is in-game only");

		return Plugin_Handled;
	}

	if (!gc_bMuteTalkOver.BoolValue)
	{
		CReplyToCommand(client, "%s %t", g_sPrefix, "Plugin disabled");

		return Plugin_Handled;
	}

	if (g_bEnable[client])
	{
		g_bEnable[client] = false;

		CReplyToCommand(client, "%s %t", g_sPrefix, "Talkover disabled");
	}
	else
	{
		g_bEnable[client] = true;

		CReplyToCommand(client, "%s %t", g_sPrefix, "Talkover enabled");
	}

	return Plugin_Handled;
}

public void OnClientSpeakingEx(int client)
{
	if (!gc_bMuteTalkOver.BoolValue || !g_bEnable[client])
		return;

	if (CheckCommandAccess(client, "sm_talkover", ADMFLAG_CHAT, false))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (client == i)
				continue;

			if (!IsValidClient(i))
				continue;

			if (CheckCommandAccess(i, "talkover_immunity", ADMFLAG_CHAT, false))
				continue;

			if (GetClientListeningFlags(i) == VOICE_MUTED)
				continue;

			g_bTempMuted[i] = true;
			SetClientListeningFlags(i, VOICE_MUTED);
			PrintCenterText(i, "%t", "Please be quiet");
		}
	}
	else if (g_bTempMuted[client])
	{
		PrintCenterText(client, "%t", "Please be quiet");
	}
}

public void OnClientSpeakingEnd(int client)
{
	if (!gc_bMuteTalkOver.BoolValue || !g_bEnable[client])
		return;

	if (!CheckCommandAccess(client, "sm_talkover", ADMFLAG_CHAT, false))
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bTempMuted[i])
			continue;

		if (!IsValidClient(i))
			continue;

		if (gp_bBasecomm)
		{
			if (BaseComm_IsClientMuted(i))
				continue;
		}

		if (gp_bSourceComms)
		{
			if (SourceComms_GetClientMuteType(i) != bNot)
				continue;
		}

		SetClientListeningFlags(i, VOICE_NORMAL);
		g_bTempMuted[i] = false;
	}
}

bool IsValidClient(int client)
{
	if (client <= 0)
		return false;

	if (client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (IsFakeClient(client))
		return false;

	if (IsClientSourceTV(client))
		return false;

	if (IsClientReplay(client))
		return false;

	return true;
}