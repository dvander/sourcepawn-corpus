/**
 * =============================================================================
 * Slot Expiration Notification (C)2007-2008 DaRk NiGhT.  All rights reserved.
 * =============================================================================
 *
 * General Information:
 * -----------------------------------------
 * Author: DaRk NiGhT
 * Homepage: http://mdvhosting.com
 *
 * About Slot Expiration Notification:
 * -----------------------------------------
 * This plugin allows you to have a message displayed to users when they join
 * your server telling them when their reserved slot expires.
 *
 * License Information:
 * -----------------------------------------
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.83b"

public Plugin:myinfo = 
{
	name = "Slot Expiration Notification",
	author = "DaRk NiGhT",
	description = "Tells people when their reserved slot expires when they join.",
	version = PLUGIN_VERSION,
	url = "http://mdvhosting.com/"
};

//General Variables/Arrays
new Handle:hDatabase = INVALID_HANDLE;
new playerInfo[MAXPLAYERS+1];
new bool:playerStatus[MAXPLAYERS+1] = {false, ...};
new Handle:playerTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new String:LOG_FILE[PLATFORM_MAX_PATH];

//ConVars
new Handle:sm_slotexpiration_sid;

public OnPluginStart()
{
	decl String:buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "logs/slot_expiration.log");
	strcopy(LOG_FILE, sizeof(LOG_FILE), buffer);
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "Initializing");
	CreateConVar("sm_slotexpiration_version", PLUGIN_VERSION, "Slot Expiration Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_slotexpiration_sid = CreateConVar("sm_slotexpiration_sid", "0", "Server ID To Get Expirations For");
	LogToFile(LOG_FILE, "Server ID: %i", GetConVarInt(sm_slotexpiration_sid));
	RegConsoleCmd("sm_expiration", CommandExpiration);
	RequestDatabaseConnection();
}

public OnMapEnd()
{
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "Map End - Cleanup");
	for (new i=1; i <= MAXPLAYERS; i++)
	{
		playerInfo[i] = 0;
	}
}

public OnClientDisconnect(client)
{
	decl String:auth[255];
	GetClientAuthString(client, auth, sizeof(auth));
	playerInfo[client] = 0;
	playerStatus[client] = false;
	if (playerTimers[client] != INVALID_HANDLE)
	{
		KillTimer(playerTimers[client]);
		playerTimers[client] = INVALID_HANDLE;
	}
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "%s Disconnected", auth);
}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hDatabase != INVALID_HANDLE)
	{
		if (hndl != INVALID_HANDLE)
		{
			CloseHandle(hndl);
		}
		return;
	}
	hDatabase = hndl;
	if (hDatabase == INVALID_HANDLE)
	{
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "Failed to Connect to Database - %s", error);
		return;
	}
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "Connected to Database");
}

RequestDatabaseConnection()
{
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "Connecting to Database");
	SQL_TConnect(OnDatabaseConnect, "slots");
}

public Action:Timer_CheckConnection(Handle:timer, any:client)
{
	if (hDatabase != INVALID_HANDLE)
	{
		CheckSteamID(client);
	} else {
		CreateTimer(10.0, Timer_CheckConnection, client);
	}
}

public OnClientPostAdminCheck(client)
{
	new flags = GetUserFlagBits(client);
	decl String:auth[255];
	GetClientAuthString(client, auth, sizeof(auth));
	if (flags & ADMFLAG_RESERVATION)
	{
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "PostAdminCheck - %s", auth);
		playerStatus[client] = false;
		CreateTimer(10.0, Timer_CheckConnection, client);
	} else {
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "PostAdminCheck - No Flag/Skipping - %s", auth);
		playerStatus[client] = true;
	}
}

CheckSteamID(client)
{
	decl String:auth[255];
	decl String:query[255];
	GetClientAuthString(client, auth, sizeof(auth));
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "CheckSteamID - Checking %s", auth);
	Format(query, sizeof(query), "SELECT * FROM `slot_expirations` WHERE steamid='%s' AND serverid='%i'", auth, GetConVarInt(sm_slotexpiration_sid));
	SQL_TQuery(hDatabase, OnReceiveReply, query, client);
}

public OnReceiveReply(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "OnReceiveReply - Error Receiving - %s", error);
		return;
	}
	decl String:auth[255];
	decl String:recvAuth[255];
	decl String:timeStamp[255];
	GetClientAuthString(data, auth, sizeof(auth));
	if(IsPluginDebugging(GetMyHandle()))
		LogToFile(LOG_FILE, "Parsing Reply - %s", auth);
	if (SQL_GetRowCount(hndl) > 0)
	{	
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, recvAuth, sizeof(recvAuth));
			SQL_FetchString(hndl, 2, timeStamp, sizeof(timeStamp));
		}
		if (StrEqual(auth, recvAuth))
		{
			StringToIntEx(timeStamp, playerInfo[data]);
			if(IsPluginDebugging(GetMyHandle()))
				LogToFile(LOG_FILE, "Reply Received - %s - %s", auth, timeStamp);
			playerTimers[data] = CreateTimer(10.0, Timer_ShowExpiration, data);
		} else {
			if(IsPluginDebugging(GetMyHandle()))
				LogToFile(LOG_FILE, "Reply Received - Steam ID Mismatch - %s", auth);
		}
		playerStatus[data] = true;
	} else {
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "No Results - %s", auth);
		playerInfo[data] = -1;
		playerStatus[data] = true;
	}
}

public Action:Timer_ShowExpiration(Handle:timer, any:client)
{
	decl String:auth[255];
	GetClientAuthString(client, auth, sizeof(auth));
	new flags = GetUserFlagBits(client);
	if (IsPlayerAlive(client))
	{
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "Is Alive - %s", auth);
		if (playerInfo[client] != -1 && playerInfo[client] != 0)
		{
			decl String:expiration[255];
			FormatTime(expiration, sizeof(expiration), "%m/%d/%y at %I:%M:%S %p", playerInfo[client]);
			PrintToChat(client, "Your Reserved Slot Expires on %s", expiration);
		} else if (flags & ADMFLAG_RESERVATION) {
			PrintToChat(client, "No Expiration Was Found For Your Slot!");
		}
		playerTimers[client] = INVALID_HANDLE;
	} else if (IsClientConnected(client)) {
		if(IsPluginDebugging(GetMyHandle()))
			LogToFile(LOG_FILE, "Is Not Alive - %s", auth);
		playerTimers[client] = CreateTimer(10.0, Timer_ShowExpiration, client);
	} else {
		playerInfo[client] = 0;
		playerTimers[client] = INVALID_HANDLE;
	}
}

public Action:CommandExpiration(client, args)
{
	new flags = GetUserFlagBits(client);
	if (flags & ADMFLAG_RESERVATION)
	{
		if (playerStatus[client])
		{
			playerTimers[client] = CreateTimer(2.0, Timer_ShowExpiration, client);
		} else {
			PrintToChat(client, "If you haven't been shown your expiration, it has not been found yet.  When it is found, it should be shown automatically. If not, try this command again in a few minutes.");
			if (playerTimers[client] == INVALID_HANDLE)
			{
				CreateTimer(1.0, Timer_CheckConnection, client);
			}
		}
	} else {
		PrintToChat(client, "You do not have a slot on this server!");
	}
	return Plugin_Handled;
}