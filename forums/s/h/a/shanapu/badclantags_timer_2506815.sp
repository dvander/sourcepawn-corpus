/*
 * Remove Bad Player Tags Plugin.
 * by: shanapu
 * https://github.com/shanapu/BadClanTags
 * 
 * Copyright (C) 2017 Thomas Schmidt (shanapu)
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

ConVar gc_bPlugin;
ConVar gc_sAlterTag;

char g_sAlterTag[32];
Handle g_aBadTags;

public Plugin myinfo =
{
	name = "Bad Clan Tags",
	description = "Auto remove a bad player tag and set an alternate",
	author = "shanapu",
	version = "1.0.2",
	url = "https://github.com/shanapu/BadClanTags"
}

public void OnPluginStart()
{
	AutoExecConfig(true,"badclantags");
	gc_bPlugin = CreateConVar("sm_badtag_enable", "1", "0 - disabled, 1 - enable", _, true, 0.0, true, 1.0);
	gc_sAlterTag = CreateConVar("sm_badtag_alter", "BAD CLAN TAG", "Set your alternative clan tag");

	HookConVarChange(gc_sAlterTag, OnSettingChanged);
	CreateTimer(1.0, Timer_CheckClanTag);
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_sAlterTag)
	{
		strcopy(g_sAlterTag, sizeof(g_sAlterTag), newValue);
	}
}

public void OnConfigsExecuted()
{
	gc_sAlterTag.GetString(g_sAlterTag, sizeof(g_sAlterTag));

	GetBadTags();
}

public Action Timer_CheckClanTag(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			continue;

		CheckClanTag(i);
	}
}

void GetBadTags()
{
	char g_filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, g_filename, sizeof(g_filename), "configs/badclantags.ini");

	Handle file = OpenFile(g_filename, "rt");

	if (file == INVALID_HANDLE)
	{
		LogMessage("Could not open file!");
		return;
	}

	g_aBadTags = CreateArray(255);

	while (!IsEndOfFile(file))
	{
		char line[255];

		if(!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}

		TrimString(line);

		if (!line[0])
			continue;

		PushArrayString(g_aBadTags, line);
	}

	CloseHandle(file);
}

void CheckClanTag(int client)
{
	if (!gc_bPlugin.BoolValue)
		return;

	if (!IsValidClient(client))
		return;

	char sClanTag[255];
	CS_GetClientClanTag(client, sClanTag, sizeof(sClanTag));

	if (!sClanTag[0])
		return;

	if (StrEqual(sClanTag, g_sAlterTag, false))
		return;

	for (int i = 0; i < GetArraySize(g_aBadTags); i++)
	{
		char sBadTag[255];
		GetArrayString(g_aBadTags, i, sBadTag, sizeof(sBadTag));

		if (!StrContains(sClanTag, sBadTag, false))
		{
			CS_SetClientClanTag(client, g_sAlterTag);
			LogMessage("The ClanTag of %N was %s and was changed to %s", client, sClanTag, g_sAlterTag);

			break;
		}
	}
}

bool IsValidClient(int iClient)
{
	if (iClient > 0 && iClient <= MaxClients && IsValidEntity(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		return true;
	}

	return false;
}