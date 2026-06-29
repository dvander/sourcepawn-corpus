/*
 * =============================================================================
 * MOTDgd In-Game Advertisements
 * Displays MOTDgd Related In-Game Advertisements
 *
 * Copyright (C)2013-2015 MOTDgd Ltd. All rights reserved.
 * =============================================================================
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

// ====[ INCLUDES | DEFINES ]============================================================
#pragma semicolon 1
#include <sourcemod>

#define STRING(%1) %1, sizeof(%1)

#define PLUGIN_VERSION "2.3.1"

// ====[ HANDLES | CVARS | VARIABLES ]===================================================
new Handle:g_motdID;
new Handle:g_OnConnect;
new Handle:g_immunity;
new Handle:g_OnOther;
new Handle:g_Review;
new Handle:g_forced;

new const String:g_GamesSupported[][] = {
	"tf",
	"csgo",
	"cstrike",
	"dod",
	"nucleardawn",
	"hl2mp",
	"left4dead",
	"left4dead2",
	"nmrih",
	"insurgency",
	"fof"
};

new String:gameDir[255];
new String:g_serverIP[16];

new g_serverPort;
new g_shownTeamVGUI[MAXPLAYERS+1] = { false, ... };
new g_lastView[MAXPLAYERS+1];

new bool:VGUICaught[MAXPLAYERS+1];
new bool:CanReview;
new bool:LateLoad;

// ====[ PLUGIN | FORWARDS ]========================================================================
public Plugin:myinfo =
{
	name = "MOTDgd Adverts",
	author = "Blackglade and Ixel",
	description = "Displays MOTDgd In-Game Advertisements",
	version = PLUGIN_VERSION,
	url = "http://motdgd.com"
}

public OnPluginStart()
{
	// Global Server Variables //
	new bool:exists = false;
	GetGameFolderName(gameDir, sizeof(gameDir));
	for (new i = 0; i < sizeof(g_GamesSupported); i++)
	{
		if (StrEqual(g_GamesSupported[i], gameDir))
		{
			exists = true;
			break;
		}
	}
	if (!exists)
		SetFailState("The game '%s' isn't currently supported by the MOTDgd plugin!", gameDir);
	exists = false;

	new Handle:serverIP = FindConVar("hostip");
	new Handle:serverPort = FindConVar("hostport");
	if (serverIP == INVALID_HANDLE || serverPort == INVALID_HANDLE)
		SetFailState("Could not determine server ip and port.");

	new IP = GetConVarInt(serverIP);
	g_serverPort = GetConVarInt(serverPort);
	Format(g_serverIP, sizeof(g_serverIP), "%d.%d.%d.%d", IP >>> 24 & 255, IP >>> 16 & 255, IP >>> 8 & 255, IP & 255);
	
	// Plugin ConVars // 
	CreateConVar("sm_motdgd_version", PLUGIN_VERSION, "[SM] MOTDgd Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_motdID = CreateConVar("sm_motdgd_userid", "0", "MOTDgd User ID. This number can be found at: http://motdgd.com/portal/", FCVAR_NOTIFY);
	g_immunity = CreateConVar("sm_motdgd_immunity", "0", "Enable/Disable advert immunity");
	g_OnConnect = CreateConVar("sm_motdgd_onconnect", "1", "Enable/Disable advert on connect");
	g_forced = CreateConVar("sm_motdgd_forced_duration", "5", "Number of seconds to force an ad view to");
	// Global Server Variables //
	
	if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
	{
		HookEventEx("arena_win_panel", Event_End);
		HookEventEx("cs_win_panel_round", Event_End);
		HookEventEx("dod_round_win", Event_End);
		HookEventEx("player_death", Event_Death);
		HookEventEx("round_start", Event_Start);
		HookEventEx("round_win", Event_End);
		HookEventEx("teamplay_win_panel", Event_End);
		
		g_OnOther = CreateConVar("sm_motdgd_onother", "2", "Set 0 to disable, 1 to show on round end, 2 to show on player death, 4 to show on round start, 3=1+2, 5=1+4, 6=2+4, 7=1+2+4");
		g_Review = CreateConVar("sm_motdgd_review", "15.0", "Set time (in minutes) to re-display the ad. ConVar sm_motdgd_onother must be configured", _, true, 15.0);
	}
	// Plugin ConVars //

	// MOTDgd MOTD Stuff //
	new UserMsg:datVGUIMenu = GetUserMessageId("VGUIMenu");
	if (datVGUIMenu == INVALID_MESSAGE_ID)
		SetFailState("The game '%s' doesn't support VGUI menus.", gameDir);
	HookUserMessage(datVGUIMenu, OnVGUIMenu, true);
	AddCommandListener(ClosedMOTD, "closed_htmlpage");
	
	HookEventEx("player_transitioned", Event_PlayerTransitioned);
	// MOTDgd MOTD Stuff //
	
	AutoExecConfig(true);

	if(LateLoad) 
	{
		for(new i=1;i<=MaxClients;i++) 
		{
			if(IsClientInGame(i))
				g_lastView[i] = GetTime();
		}
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	// Set the expected defaults for the client
	VGUICaught[client] = false;
	g_shownTeamVGUI[client] = false;
	g_lastView[client] = 0;
	
	if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
		CanReview = true;
	
	return true;
}

public OnClientPutInServer(client)
{
	// Load the advertisement via conventional means
	if (StrEqual(gameDir, "left4dead2") && GetConVarBool(g_OnConnect))
	{
		CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
	}
}

// ====[ FUNCTIONS ]=====================================================================
public Action:Event_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Re-view minutes must be 15 or higher, re-view mode (onother) for this event
	if (GetConVarFloat(g_Review) < 15.0 || (g_OnOther && GetConVarInt(g_OnOther) != 1 && GetConVarInt(g_OnOther) != 3 && GetConVarInt(g_OnOther) != 5 && GetConVarInt(g_OnOther) != 7))
		return Plugin_Continue;
	
	// Only process the re-view event if the client is valid and is eligible to view another advertisement
	if (IsValidClient(client) && CanReview && GetTime() - g_lastView[client] >= GetConVarFloat(g_Review) * 60)
	{
		g_lastView[client] = GetTime();
		CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
	}

	return Plugin_Continue;
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client)
		return Plugin_Continue;

	CreateTimer(0.5, CheckPlayerDeath, GetClientUserId(client));
	
	return Plugin_Continue;
}

public Action:Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Re-view minutes must be 15 or higher, re-view mode (onother) for this event
	if (GetConVarFloat(g_Review) < 15.0 || (g_OnOther && GetConVarInt(g_OnOther) != 4 && GetConVarInt(g_OnOther) != 5 && GetConVarInt(g_OnOther) != 6 && GetConVarInt(g_OnOther) != 7))
		return Plugin_Continue;
	
	// Only process the re-view event if the client is valid and is eligible to view another advertisement
	if (IsValidClient(client) && CanReview && GetTime() - g_lastView[client] >= GetConVarFloat(g_Review) * 60)
	{
		g_lastView[client] = GetTime();
		CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
	}

	return Plugin_Continue;
}

public Action:CheckPlayerDeath(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;

	// Check if client is valid
	if (!IsValidClient(client))
		return Plugin_Stop;
	
	// We don't want TF2's Dead Ringer triggering a false re-view event
	if (IsPlayerAlive(client))
		return Plugin_Stop;
	
	// Re-view minutes must be 15 or higher, re-view mode (onother) for this event
	if (GetConVarFloat(g_Review) < 15.0 || (g_OnOther && GetConVarInt(g_OnOther) != 2 && GetConVarInt(g_OnOther) != 3 && GetConVarInt(g_OnOther) != 6 && GetConVarInt(g_OnOther) != 7))
		return Plugin_Stop;
	
	// Only process the re-view event if the client is valid and is eligible to view another advertisement
	if (CanReview && GetTime() - g_lastView[client] >= GetConVarFloat(g_Review) * 60)
	{
		g_lastView[client] = GetTime();
		CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
	}
	
	return Plugin_Stop;
}

public Action:Event_PlayerTransitioned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && GetConVarBool(g_OnConnect))
		CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));

	return Plugin_Continue;
}

public Action:OnVGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = players[0];
	
	if (playersNum > 1 || !IsValidClient(client) || VGUICaught[client] || !GetConVarBool(g_OnConnect))
		return Plugin_Continue;

	VGUICaught[client] = true;
	
	g_lastView[client] = GetTime();
	
	CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
	
	return Plugin_Handled;
}

public Action:ClosedMOTD(client, const String:command[], argc)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if(GetConVarInt(g_forced) != 0 && g_lastView[client]+GetConVarInt(g_forced)<=GetTime())
	{
		ShowMOTDScreen(client, "http://", false);
	}
	else
	{
		if (StrEqual(gameDir, "cstrike") || StrEqual(gameDir, "csgo"))
			FakeClientCommand(client, "joingame");
		else if (StrEqual(gameDir, "insurgency"))
			FakeClientCommand(client, "say /motd");
		else if (StrEqual(gameDir, "nucleardawn") || StrEqual(gameDir, "dod"))
			ClientCommand(client, "changeteam");
	}
	
	return Plugin_Handled;
}

public Action:PreMotdTimer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;

	if (!IsValidClient(client))
		return Plugin_Stop;
	
	decl String:url[255];
	decl String:steamid[255];
	if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		Format(url, sizeof(url), "http://motdgd.com/motd/?user=%d&ip=%s&pt=%d&v=%s&st=%s&gm=%s", GetConVarInt(g_motdID), g_serverIP, g_serverPort, PLUGIN_VERSION, steamid, gameDir);
	else
		Format(url, sizeof(url), "http://motdgd.com/motd/?user=%d&ip=%s&pt=%d&v=%s&st=NULL&gm=%s", GetConVarInt(g_motdID), g_serverIP, g_serverPort, PLUGIN_VERSION, gameDir);
	
	CreateTimer(0.2, RefreshMotdTimer, userid);
	ShowMOTDScreen(client, url, false); // False means show, true means hide
	
	return Plugin_Stop;
}

public Action:RefreshMotdTimer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;

	if (!IsValidClient(client))
		return Plugin_Stop;

	if(GetConVarInt(g_forced) != 0 && g_lastView[client]+GetConVarInt(g_forced)<=GetTime())
	{
		CreateTimer(0.2, RefreshMotdTimer, userid);
	}

	ShowMOTDScreen(client, "http://", false);

	return Plugin_Stop;
}

stock ShowMOTDScreen(client, String:url[], bool:hidden)
{
	if (!IsValidClient(client))
		return;
	
	new Handle:kv = CreateKeyValues("data");

	if (StrEqual(gameDir, "left4dead") || StrEqual(gameDir, "left4dead2"))
		KvSetString(kv, "cmd", "closed_htmlpage");
	else
		KvSetNum(kv, "cmd", 5);

	KvSetString(kv, "msg", url);
	KvSetString(kv, "title", "MOTDgd AD");
	KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
	ShowVGUIPanel(client, "info", kv, !hidden);
	CloseHandle(kv);
}

stock GetRealPlayerCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			players++;
	}
	return players;
}

stock bool:IsValidClient(i){
	if (!i || !IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i) || IsFakeClient(i) || !IsClientConnected(i))
		return false;
	if (!GetConVarBool(g_immunity))
		return true;
	if (CheckCommandAccess(i, "MOTDGD_Immunity", ADMFLAG_RESERVATION))
		return false;

	return true;
}
