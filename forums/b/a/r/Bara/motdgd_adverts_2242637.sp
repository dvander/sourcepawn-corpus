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

#include <EasyHTTP2>
#include <json>

#define PLUGIN_VERSION "2.2.6"

// ====[ HANDLES | CVARS | VARIABLES ]===================================================
new Handle:g_motdID;
new Handle:g_OnConnect;
new Handle:g_immunity;
new Handle:g_OnOther;
new Handle:g_Review;
new Handle:g_Preload;

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
	"fof"
};
new const String:g_GamesPreloadSupported[][] = {
	"tf"
};
new String:gameDir[255];
new String:g_serverIP[16];

new g_serverPort;
new g_timepending[MAXPLAYERS+1];
new g_preloadCheckTime[MAXPLAYERS+1] = { 0, ... };
new g_shownTeamVGUI[MAXPLAYERS+1] = { false, ... };

new bool:VGUICaught[MAXPLAYERS+1];
new bool:CanView[MAXPLAYERS+1];
new bool:HTTPCommSupported;

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

	g_motdID = CreateConVar("sm_motdgd_userid", "0", "MOTDgd User ID. This number can be found at: http://motdgd.com/portal/");
	g_immunity = CreateConVar("sm_motdgd_immunity", "0", "Enable/Disable advert immunity");
	g_OnConnect = CreateConVar("sm_motdgd_onconnect", "1", "Enable/Disable advert on connect");
	g_Preload = CreateConVar("sm_motdgd_preload", "15", "Maximum seconds allowed for preloading the advertisement (if supported), a setting of 0 disables preloading");
	// Global Server Variables //
	
	if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
	{
		g_OnOther = CreateConVar("sm_motdgd_onother", "2", "Set 0 to disable, 1 to show on round end, 2 to show on player death, 3 to show on both");
		g_Review = CreateConVar("sm_motdgd_review", "15.0", "Set time (in minutes) to re-display the ad. ConVar sm_motdgd_onother must be configured", _, true, 15.0);
	}
	
	for (new i = 0; i < sizeof(g_GamesPreloadSupported); i++)
	{
		if (StrEqual(g_GamesPreloadSupported[i], gameDir))
		{
			exists = true;
			break;
		}
	}
	if (!exists)
	{
		HTTPCommSupported = false;
	}
	else
	{
		// Check connection can be made to motd.gd for ability to preload advertisement
		new String:requestURL[PLATFORM_MAX_PATH];
		Format(requestURL, sizeof(requestURL), "http://motd.gd", GetConVarInt(g_motdID), gameDir);
		if (EasyHTTP(requestURL, GetSteamData_Null_Completed, 0))
			HTTPCommSupported = true;
		else
			HTTPCommSupported = false;
	}
	
	if (!HTTPCommSupported)
	{
		LogMessage("Advertisement preload isn't possible as either the cURL or Socket extension isn't installed or this server is running an unsupported game");
	}
	// Plugin ConVars //

	// MOTDgd MOTD Stuff //
	new UserMsg:datVGUIMenu = GetUserMessageId("VGUIMenu");
	if (datVGUIMenu == INVALID_MESSAGE_ID)
		SetFailState("The game '%s' doesn't support VGUI menus.", gameDir);
	HookUserMessage(datVGUIMenu, OnVGUIMenu, true);
	AddCommandListener(ClosedMOTD, "closed_htmlpage");

	HookEventEx("player_transitioned", Event_PlayerTransitioned);
	HookEventEx("player_death", Event_Death);
	HookEventEx("cs_win_panel_round", Event_End);
	HookEventEx("round_win", Event_End);
	HookEventEx("dod_round_win", Event_End);
	HookEventEx("teamplay_win_panel", Event_End);
	HookEventEx("arena_win_panel", Event_End);
	
	CreateTimer(90.0, ChatAdTimer);
	// MOTDgd MOTD Stuff //
	
	AutoExecConfig(true);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	// Set the expected defaults for the client
	VGUICaught[client] = false;
	g_preloadCheckTime[client] = 0;
	g_shownTeamVGUI[client] = false;
	
	if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
		CanView[client] = true;
	
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
	
	// Re-view minutes must be 15 or higher, re-view mode (onother) must be either 0 or 2 for this event
	if (GetConVarFloat(g_Review) < 15.0 || GetConVarInt(g_OnOther) == 0 || GetConVarInt(g_OnOther) == 2)
		return Plugin_Continue;
	
	// Only process the re-view event if the client is valid and is eligible to view another advertisement
	if (IsValidClient(client) && CanView[client])
	{
		CanView[client] = false;
		if (HTTPCommSupported && GetConVarInt(g_Preload) > 0)
		{
			// Preload the advertisement
			CreateTimer(0.1, PreloadMotdTimer, GetClientUserId(client));
			
			CreateTimer(3.0, PreloadCheckTimer, GetClientUserId(client));
		}
		else
		{
			// Load the advertisement via conventional means
			if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
			{
				CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
			}
		}
		CreateTimer((GetConVarFloat(g_Review) * 60), ReviewMotdTimer, GetClientUserId(client));
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
	
	// L4D1 and L4D2 are unsupported
	if (StrEqual(gameDir, "left4dead2") || StrEqual(gameDir, "left4dead"))
		return Plugin_Stop;
	
	// Re-view event won't work if the minutes is less than 15 or the review (onother) mode is not 2 or higher
	if (GetConVarFloat(g_Review) < 15.0 || GetConVarInt(g_OnOther) < 2)
		return Plugin_Stop;
	
	// Only process the re-view event if the client is valid and is eligible to view another advertisement
	if (CanView[client])
	{
		CanView[client] = false;
		if (HTTPCommSupported && GetConVarInt(g_Preload) > 0)
		{
			CreateTimer(0.1, PreloadMotdTimer, GetClientUserId(client));
			
			CreateTimer(3.0, PreloadCheckTimer, GetClientUserId(client));
		}
		else
		{
			if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
			{
				CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
			}
		}
		CreateTimer((GetConVarFloat(g_Review) * 60), ReviewMotdTimer, GetClientUserId(client));
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
	
	g_timepending[client] = 0;
	
	if (HTTPCommSupported && GetConVarInt(g_Preload) > 0)
	{
		CanView[client] = false;
		CreateTimer((GetConVarFloat(g_Review) * 60), ReviewMotdTimer, GetClientUserId(client));
		
		CreateTimer(0.1, PreloadMotdTimer, GetClientUserId(client));
		
		CreateTimer(2.0, PreloadCheckTimer, GetClientUserId(client));
	}
	else
	{
		if (!StrEqual(gameDir, "left4dead2") && !StrEqual(gameDir, "left4dead"))
		{
			CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
		}
	}
	
	return Plugin_Handled;
}

public Action:PreloadMotdTimer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;

	if (!IsValidClient(client))
		return Plugin_Stop;
	
	// Preload the advertisement and only show it once it begins playing...
	new String:IP[16]; 
	GetClientIP(client, IP, sizeof(IP));
	
	new String:requestURL[PLATFORM_MAX_PATH];
	Format(requestURL, sizeof(requestURL), "http://video.u%d.motd.gd/motd?ip=%s&action=reset", GetConVarInt(g_motdID), IP);
	
	EasyHTTP(requestURL, GetSteamData_Null_Completed, 0);
	
	g_preloadCheckTime[client] = GetTime();
	
	decl String:steamid[255], String:url[255];
	if (GetClientAuthString(client, steamid, sizeof(steamid)))
		Format(url, sizeof(url), "http://motdgd.com/motd/?user=%d&ip=%s&pt=%d&v=%s&st=%s&gm=%s", GetConVarInt(g_motdID), g_serverIP, g_serverPort, PLUGIN_VERSION, steamid, gameDir);
	else
		Format(url, sizeof(url), "http://motdgd.com/motd/?user=%d&ip=%s&pt=%d&v=%s&st=NULL&gm=%s", GetConVarInt(g_motdID), g_serverIP, g_serverPort, PLUGIN_VERSION, gameDir);
	
	ShowMOTDScreen(client, url, true);
	
	if (!g_shownTeamVGUI[client] && GetClientTeam(client) < 1)
	{
		g_shownTeamVGUI[client] = true;
		ShowVGUIPanel(client, "team");
	}
	
	return Plugin_Stop;
}

public Action:PreloadCheckTimer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;

	if (!IsValidClient(client))
		return Plugin_Stop;
	
	new String:IP[16]; 
	GetClientIP(client, IP, sizeof(IP));
	
	new String:requestURL[PLATFORM_MAX_PATH];
	Format(requestURL, sizeof(requestURL), "http://video.u%d.motd.gd/motd?ip=%s", GetConVarInt(g_motdID), IP);
	
	EasyHTTP(requestURL, GetSteamData_PreloadCheck_Completed, client);
	
	return Plugin_Stop;
}

public GetSteamData_PreloadCheck_Completed(any:client, const String:sQueryData[], bool:success, error)
{
	if (!IsValidClient(client))
		return;
	
	if (g_preloadCheckTime[client] == 0)
		return;
	
	// Allow at least 'sm_motdgd_preload' seconds before discontinuing any further attempts
	if ((GetTime() - g_preloadCheckTime[client]) < GetConVarInt(g_Preload))
	{
		if (success)
		{
			new String:searchFor[1] = "Y";
			
			if (StrEqual(sQueryData, searchFor))
			{
				g_preloadCheckTime[client] = 0;
				
				CreateTimer(0.1, PreMotdTimer, GetClientUserId(client));
			}
			else
			{
				CreateTimer(2.0, PreloadCheckTimer, GetClientUserId(client));
			}
		}
	}
	else
	{
		g_preloadCheckTime[client] = 0;
		
		new String:url[255];
		Format(url, sizeof(url), "http://");
		
		ShowMOTDScreen(client, url, false);
	}
}

public Action:ClosedMOTD(client, const String:command[], argc)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (GetConVarInt(g_Preload) == 0)
	{
		if (StrEqual(gameDir, "cstrike") || StrEqual(gameDir, "csgo"))
			FakeClientCommand(client, "joingame");
		else if (StrEqual(gameDir, "nucleardawn") || StrEqual(gameDir, "dod"))
			ClientCommand(client, "changeteam");
	}
	
	return Plugin_Handled;
}

public Action:ReviewMotdTimer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;
	CanView[client] = true;
	return Plugin_Stop;
}

public Action:PreMotdTimer(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(!client)
		return Plugin_Stop;

	if (!IsValidClient(client))
		return Plugin_Stop;
	
	g_preloadCheckTime[client] = 0;
	
	decl String:url[255];
	
	if (HTTPCommSupported && GetConVarInt(g_Preload) > 0)
		Format(url, sizeof(url), "http://");
	else
	{
		decl String:steamid[255];
		if (GetClientAuthString(client, steamid, sizeof(steamid)))
			Format(url, sizeof(url), "http://motdgd.com/motd/?user=%d&ip=%s&pt=%d&v=%s&st=%s&gm=%s", GetConVarInt(g_motdID), g_serverIP, g_serverPort, PLUGIN_VERSION, steamid, gameDir);
		else
			Format(url, sizeof(url), "http://motdgd.com/motd/?user=%d&ip=%s&pt=%d&v=%s&st=NULL&gm=%s", GetConVarInt(g_motdID), g_serverIP, g_serverPort, PLUGIN_VERSION, gameDir);
	}
	
	ShowMOTDScreen(client, url, false); // False means show, true means hide
	g_timepending[client] = 0;
	
	return Plugin_Stop;
}

public Action:ChatAdTimer(Handle:timer)
{
	CreateTimer(600.0, ChatAdTimer);
	
	new String:requestURL[PLATFORM_MAX_PATH];
	
	if (GetRealPlayerCount() > 0)
	{
		Format(requestURL, sizeof(requestURL), "http://chat.motd.gd/chat?uid=%d&gm=%s", GetConVarInt(g_motdID), gameDir);
		
		EasyHTTP(requestURL, GetSteamData_Completed, 0);
	}
}

public GetSteamData_Completed(any:unused, const String:sQueryData[], bool:success, error)
{
	if (success)
	{
		new JSON:js = json_decode(sQueryData);
		
		if (js == JSON_INVALID)
		{
			return;
		}
		
		new String:message[255];
		json_get_string(js, "message", message, sizeof(message));
		
		new String:impressionURL[PLATFORM_MAX_PATH];
		json_get_string(js, "impression", impressionURL, sizeof(impressionURL));
		
		EasyHTTP(impressionURL, GetSteamData_Null_Completed, 0);
		
		PrintToChatAll("\x01\x0B\x04[AD] %s", message);
	}
}

public GetSteamData_Null_Completed(any:unused, const String:sQueryData[], bool:success, error)
{
	return;
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
	if (!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i) || IsFakeClient(i) || !i || !IsClientConnected(i))
		return false;
	if (!GetConVarBool(g_immunity))
		return true;
	if (CheckCommandAccess(i, "MOTDGD_Immunity", ADMFLAG_RESERVATION))
		return false;

	return true;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Mark Socket natives as optional
	MarkNativeAsOptional("SocketIsConnected");
	MarkNativeAsOptional("SocketCreate");
	MarkNativeAsOptional("SocketBind");
	MarkNativeAsOptional("SocketConnect");
	MarkNativeAsOptional("SocketDisconnect");
	MarkNativeAsOptional("SocketListen");
	MarkNativeAsOptional("SocketSend");
	MarkNativeAsOptional("SocketSendTo");
	MarkNativeAsOptional("SocketSetOption");
	MarkNativeAsOptional("SocketSetReceiveCallback");
	MarkNativeAsOptional("SocketSetSendqueueEmptyCallback");
	MarkNativeAsOptional("SocketSetDisconnectCallback");
	MarkNativeAsOptional("SocketSetErrorCallback");
	MarkNativeAsOptional("SocketSetArg");
	MarkNativeAsOptional("SocketGetHostName");

	// Mark cURL natives as optional
	MarkNativeAsOptional("curl_easy_init");
	MarkNativeAsOptional("curl_easy_setopt_string");
	MarkNativeAsOptional("curl_easy_setopt_int");
	MarkNativeAsOptional("curl_easy_setopt_int_array");
	MarkNativeAsOptional("curl_easy_setopt_int64");
	MarkNativeAsOptional("curl_OpenFile");
	MarkNativeAsOptional("curl_httppost");
	MarkNativeAsOptional("curl_slist");
	MarkNativeAsOptional("curl_easy_setopt_handle");
	MarkNativeAsOptional("curl_easy_setopt_function");
	MarkNativeAsOptional("curl_load_opt");
	MarkNativeAsOptional("curl_easy_perform");
	MarkNativeAsOptional("curl_easy_perform_thread");
	MarkNativeAsOptional("curl_easy_send_recv");
	MarkNativeAsOptional("curl_send_recv_Signal");
	MarkNativeAsOptional("curl_send_recv_IsWaiting");
	MarkNativeAsOptional("curl_set_send_buffer");
	MarkNativeAsOptional("curl_set_receive_size");
	MarkNativeAsOptional("curl_set_send_timeout");
	MarkNativeAsOptional("curl_set_recv_timeout");
	MarkNativeAsOptional("curl_get_error_buffer");
	MarkNativeAsOptional("curl_easy_getinfo_string");
	MarkNativeAsOptional("curl_easy_getinfo_int");
	MarkNativeAsOptional("curl_easy_escape");
	MarkNativeAsOptional("curl_easy_unescape");
	MarkNativeAsOptional("curl_easy_strerror");
	MarkNativeAsOptional("curl_version");
	MarkNativeAsOptional("curl_protocols");
	MarkNativeAsOptional("curl_features");
	MarkNativeAsOptional("curl_OpenFile");
	MarkNativeAsOptional("curl_httppost");
	MarkNativeAsOptional("curl_formadd");
	MarkNativeAsOptional("curl_slist");
	MarkNativeAsOptional("curl_slist_append");
	MarkNativeAsOptional("curl_hash_file");
	MarkNativeAsOptional("curl_hash_string");
}
