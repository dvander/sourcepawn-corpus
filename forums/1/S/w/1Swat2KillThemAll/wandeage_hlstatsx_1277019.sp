/**
 * @file	wandeage_hlstatsx.inc
 * @author	1Swat2KillThemAll
 *
 * @brief	WanDeage CS:S(OB) ServerSide Plugin - HLSTATSX
 * @version	1.000.000
 *
 * @todo	test log input parsing, retest plugin, did some code refactoring =) (code readability ftw? ^^)
 *
 * WanDeage CS:S(OB) ServerSide Plugin - HLSTATSX
 * Copyright (C)/© 2010 B.D.A.K. Koch
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>

#include "wandeage.inc"

new Handle:h_CvEnabled, CvEnabled,
	Handle:h_CvDebug, CvDebug = 0,
	String:TeamName[2][64];

#define PLUGIN_NAME "WanDeage HlStatsX"
#define PLUGIN_NAME_NOSPACE "WanDeage_HlStatsX"
#define PLUGIN_AUTHOR "1Swat2KillThemAll"
#define PLUGIN_DESCRIPTION "WanDeage Stats (HlStatsX)"
#define PLUGIN_VERSION "1.000.000"
#define PLUGIN_URL "http://web.ccc-clan.com/wandeage/"
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};
public OnPluginStart()
{
	h_CvEnabled = CreateConVar("sm_wandeage_hlstatsx", "1", "Sets whether WanDeage HlStatsX should be enabled.", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(h_CvEnabled, OnConVarChanged);
	CvEnabled = GetConVarInt(h_CvEnabled);
	h_CvDebug = FindConVar("sm_wandeage_debug");
	HookConVarChange(h_CvDebug, OnConVarChanged);
	CvDebug = GetConVarInt(h_CvDebug);

	if ((wandeage_loaded = LibraryExists("wandeage")) == true)
	{
		WanDeageLoaded();
	}

	AutoExecConfig(true, PLUGIN_NAME_NOSPACE);
	LoadTranslations("wandeage.phrases");
}
public OnMapStart()
{
	GetTeamName(2, TeamName[0], 64);
	GetTeamName(3, TeamName[1], 64);
}

WanDeageLoaded()
{
	HookWanDeage(OnWanDeage);
	AddWanDeageModules("HlStatsX", false);
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == h_CvEnabled)
	{
		CvEnabled = StringToInt(newVal);
	}
	else if (cvar == h_CvDebug)
	{
		CvDebug = StringToInt(newVal);
	}
}

public Action:OnWanDeage(uid_client, uid_victim)
{
	new client = GetClientOfUserId(uid_client),
		victim = GetClientOfUserId(uid_victim);
	if (!CvEnabled || !client || !victim || !IsClientConnected(client) || !IsClientConnected(victim) || !IsClientInGame(client) || !IsClientInGame(victim))
	{
		return;
	}

	new c_team = GetClientTeam(client), v_team = GetClientTeam(victim);
	if ((c_team != 2 && c_team != 3) || (v_team != 2 && v_team != 3))
	{
		return;
	}

	decl String:c_auth[32], String:v_auth[32],
		String:c_name[MAX_NAME_LENGTH], String:v_name[MAX_NAME_LENGTH];

	GetClientAuthString(client, c_auth, sizeof(c_auth));
	GetClientName(client, c_name, sizeof(c_name));
	GetClientAuthString(victim, v_auth, sizeof(v_auth));
	GetClientName(victim, v_name, sizeof(v_name));

	LogToGame("\"%s<%i><%s><%s>\" triggered \"wandeage\" against \"%s<%i><%s><%s>\"", c_name, uid_client, c_auth, TeamName[c_team-2], v_name, uid_victim, v_auth, TeamName[v_team-2]);
}
public WdInfoMenuHandler(client)
{
	InformationMenu(client);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "wandeage"))
	{
		wandeage_loaded = false;
	}
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "wandeage"))
	{
		wandeage_loaded = true;
		WanDeageLoaded();
	}
}

InformationMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandlerEmpty1);
	SetMenuTitle(menu, "%T", "CodedBy", client, "1Swat2KillThemAll");
	AddMenuItem(menu, "0", "Adds HL Log output for WanDeage.");
	AddMenuItem(menu, "1", "\"Name<uid><wonid><team>\" triggered \"wandeage\" against \"Name<uid><wonid><team>\"");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
