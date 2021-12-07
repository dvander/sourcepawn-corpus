/*  Simple ClanTag Detector
 *
 *  Copyright (C) 2020 Oylsister
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1.0"

char SpecificClanTag[512];

new Handle:g_dtTimerJoin = INVALID_HANDLE;

ConVar g_dtClanTag;

public Plugin:myinfo =
{
	name = "Simple ClanTag Detector",
	author = "Oylsister",
	description = "Detecting Player ClanTag and Print Message To Them",
	version = PLUGIN_VERSION,
	url = "https://github.com/oylsister"
};

public OnPluginStart()
{
	CreateConVar("sm_clantag_detect_version", PLUGIN_VERSION, "ClanTag Detector Version");
	g_dtClanTag = CreateConVar("sm_clantag_detect", "[SM]", "Specific the clantag that you want to print message to them.");
	g_dtTimerJoin = CreateConVar("sm_clantag_join_delay", "3.0", "Specific time to show message when player join into the server", _, true, 0.0, false);
	AutoExecConfig(true, "sm_simple_clantag_detect");
}

public void OnMapStart()
{
	g_dtClanTag.GetString(SpecificClanTag, sizeof(SpecificClanTag));
}

public OnClientPostAdminCheck(client)

{
	CreateTimer(GetConVarFloat(g_dtTimerJoin), JoinGame_Delay, client);
}

public Action JoinGame_Delay(Handle timer, client)
{
	if(IsClientInGame(client))
	{
		char clienttag[16];
		CS_GetClientClanTag(client, clienttag, 16);
		if(StrEqual(clienttag, SpecificClanTag, false))
		{
			CPrintToChat(client, "{lightgreen}You currently using {darkblue}%s {lightgreen}Tag, You will get extra {green}credits {lightgreen}while playing on our server, have fun!.", SpecificClanTag);
		}
		else
		{
			CPrintToChat(client, "{lightgreen}You currently using {darkred}%s {lightgreen}Tag, Change your Clantag to {darkblue}%s {lightgreen}and get extra credits!", clienttag, SpecificClanTag);
		}
	}
}

public OnClientSettingsChanged(client)
{
	if(IsClientInGame(client))
	{
		char clienttag[16];
		CS_GetClientClanTag(client, clienttag, 16);
		if(StrEqual(clienttag, SpecificClanTag, false))
		{
			CPrintToChat(client, "{lightgreen}You currently using {darkblue}%s {lightgreen}Tag, You will get extra {green}credits {lightgreen}while playing on our server, have fun!.", SpecificClanTag);
		}
		else
		{
			CPrintToChat(client, "{lightgreen}You currently using {darkred}%s {lightgreen}Tag, Change your Clantag to {darkblue}%s {lightgreen}and get extra credits!", clienttag, SpecificClanTag);
		}
	}
}
