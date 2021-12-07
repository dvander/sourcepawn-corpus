/**
 * HLstatsX Community Edition - SourceMod plugin to provide native access to HLX:CE data.
 * http://www.hlxcommunity.com
 * Copyright (C) 2009 Nicholas Hastings (psychonic)
 * Copyright (C) 2007-2008 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
 
#pragma semicolon 1
 
#include <sourcemod>
 
#define NAME "HLstatsX:CE SQL API for Sourcemod"
#define VERSION "0.5 alpha"
 
#define RANKINGTYPE_SKILL 0
#define RANKINGTYPE_KILLS 1

enum HLXCE_PlayerData
{
	PData_Skill,
	PData_Kills,
	PData_Deaths,
	PData_Headshots,
	PData_Conntime,
	PData_Shots,
	PData_Hits,
	PData_Rank
}

#define DEBUG 0
 
public Plugin:myinfo = {
	name = NAME,
	author = "psychonic // Fix by DoPe^",
	description = "Provides easy access to HLX:CE data via Sourcemod",
	version = VERSION,
	url = "http://www.hlxcommunity.com"
};

new g_iClientHLXPlayerId[MAXPLAYERS+1] = { -1, ... };
new Handle:g_hFwdHLXClientReady;
new Handle:g_hFwdHLXGotPlayerData;
new Handle:g_hHLXDatabase = INVALID_HANDLE;
new Handle:g_hCvarServerIp;
new Handle:g_hCvarServerPort;
new Handle:g_hCvarGameCode;
new String:g_szHLXGameCode[33];
new g_iGameCodeLen;
new String:g_szRankingType[2][] = { "skill", "kills" };
new g_iRankingType;
new g_iPlayerCounts[MAXPLAYERS+1][HLXCE_PlayerData];
 
public OnPluginStart()
{
	#if DEBUG == 1
		LogToGame("[HLX-API] Plugin Started");
	#endif
	
	CreateConVar("hlxce_api_version", VERSION, NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarServerIp = CreateConVar("hlxce_api_serverip", "", "Server IP Override (only needed if IP on commandline doesn't match IP in HLXCE)", FCVAR_PLUGIN);
	g_hCvarServerPort = CreateConVar("hlxce_api_serverport", "0", "Server Port Override (only needed if port on commandline doesn't match port in HLXCE)", FCVAR_PLUGIN);
	g_hCvarGameCode = CreateConVar("hlxce_api_gamecode", "", "Game Code Override (only needed if your game code is not being auto-detected)", FCVAR_PLUGIN);
	
	g_hFwdHLXClientReady = CreateGlobalForward("HLXCE_OnClientReady", ET_Ignore, Param_Cell);
	g_hFwdHLXGotPlayerData = CreateGlobalForward("HLXCE_OnGotPlayerData", ET_Ignore, Param_Cell, Param_Array);

	// Initiate Database
	InitDB();
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	RegPluginLibrary("hlxce-sm-api");
	
	CreateNative("HLXCE_GetPlayerData", Native_HLXCE_GetPlayerData);
	CreateNative("OnGotClientHLXPlayerId", Native_HLXCE_IsClientReady);
	
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	return APLRes_Success;
#else
	return true;
#endif
}

//public OnConfigsExecuted()
//{
//	if (g_hHLXDatabase == INVALID_HANDLE)
//	{
//		SQL_TConnect(OnConnectedToDatabase, "hlxce");
//	}
//}

public InitDB()
{
	if (g_hHLXDatabase == INVALID_HANDLE)
	{
		SQL_TConnect(OnConnectedToDatabase, "hlxce");
	}
}

public OnConnectedToDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{	
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Cannot connect to database");
	}
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Connected to database");
	#endif
	
	g_hHLXDatabase = hndl;
	
	// If gamecode is specified in hlxce_api_gamecode, use it and skip query for it
	decl String:szGameOverride[33];
	GetConVarString(g_hCvarGameCode, szGameOverride, sizeof(szGameOverride));
	
	if (strcmp("", szGameOverride) != 0)
	{
		strcopy(g_szHLXGameCode, sizeof(g_szHLXGameCode), szGameOverride);
		g_iGameCodeLen = strlen(g_szHLXGameCode);
		GetRankingType();
	}
	else
	{
		// If server ip is specified in hlxce_api_serverip, use that instead of attempting to auto-detect
		decl String:szServerIp[16];
		GetConVarString(g_hCvarServerIp, szServerIp, sizeof(szServerIp));
		if (strcmp("", szServerIp) == 0)
		{
			new iIp = GetConVarInt(FindConVar("hostip"));
			//thx Tsunami
			Format(szServerIp, sizeof(szServerIp), "%i.%i.%i.%i",
				(iIp >> 24) & 0x000000FF,
				(iIp >> 16) & 0x000000FF,
				(iIp >>  8) & 0x000000FF,
				(iIp & 0x000000FF));
		}
		
		// If server port is specified in hlxce_api_serverport, use that instead of attempting to auto-detect
		new iPort = GetConVarInt(g_hCvarServerPort);
		if (iPort == 0)
		{
			iPort = GetConVarInt(FindConVar("hostport"));
		}
	
		decl String:szQueryText[80];
		// should return no more than one row because address/port is a unique key
		Format(szQueryText, sizeof(szQueryText), "SELECT game FROM hlstats_Servers WHERE address='%s' AND port=%d", szServerIp, iPort);
		
		#if DEBUG == 1
			LogToGame("[HLX-API] Sending query \"%s\"", szQueryText);
		#endif
		
		SQL_TQuery(g_hHLXDatabase, OnGotGameCode, szQueryText);
	}
}

public OnGotGameCode(Handle:owner, Handle:hndl, const String:error[], any:client)
{	
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Game code query failed (no handle)");
	}
	
	if (SQL_GetRowCount(hndl) < 1)
	{
		SetFailState("Game code query failed (not found)");
	}
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Got game code from lookup");
	#endif
	
	SQL_FetchRow(hndl);
	SQL_FetchString(hndl, 0, g_szHLXGameCode, sizeof(g_szHLXGameCode));
	g_iGameCodeLen = strlen(g_szHLXGameCode);
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Game code is %s, len %d", g_szHLXGameCode, g_iGameCodeLen);
		LogToGame("[HLX-API] Sending query \"SELECT `value` FROM hlstats_Options WHERE `keyname`='rankingtype'\"");
	#endif
	
	// so far, so good. now we have to get/cache ranking type. then we can lookup everyone's id.
	GetRankingType();
}

GetRankingType()
{
	SQL_TQuery(g_hHLXDatabase, OnGotRankingType, "SELECT `value` FROM hlstats_Options WHERE `keyname`='rankingtype'");
}

public OnGotRankingType(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Ranking type lookup failed (no handle)");
	}
	
	if (SQL_GetRowCount(hndl) < 1)
	{
		SetFailState("Ranking type lookup failed (no rows)");
	}
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Got Ranking Type");
	#endif
	
	decl String:szTempRankingType[6];
	SQL_FetchRow(hndl); // should only be one row returned. we don't care if there are more.
	SQL_FetchString(hndl, 0, szTempRankingType, sizeof(szTempRankingType));
	
	if (strcmp(szTempRankingType, g_szRankingType[RANKINGTYPE_KILLS], false) == 0)
	{
		g_iRankingType = RANKINGTYPE_KILLS;
	}
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Ranking type is %d (skill:0;kills:1)", g_iRankingType);
	#endif
	
	// Got all startup info we need, now let's get hlx player ids for everyone in game
	GetAllPlayerIds();
}

public OnClientPostAdminCheck(client)
{
	CreateTimer(2.0, Timer_GetData, client);
}

public Action:Timer_GetData(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
		GetClientHLXPlayerId(client);
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	g_iClientHLXPlayerId[client] = -1;
}

public Native_HLXCE_IsClientReady(Handle:plugin, numParams)
{
	if (g_iClientHLXPlayerId[GetNativeCell(1)] > -1)
	{
		return true;
	}
	
	return false;
}

GetClientHLXPlayerId(client)
{
	if (g_hHLXDatabase == INVALID_HANDLE)
	{
		SetFailState("Lost database connection");
	}
	
	if (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		decl String:szAuthId[32];
		if (GetClientAuthId(client, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
		{
			decl String:szAuthIdEsc[49];
			new iAuthIdLen;
			SQL_EscapeString(g_hHLXDatabase, szAuthId[8], szAuthIdEsc, sizeof(szAuthIdEsc), iAuthIdLen);
			new iQSize = 75+iAuthIdLen+g_iGameCodeLen;
			decl String:szPlayerIdQuery[iQSize];
			// should return no more than 1 row between game/uniqueId is a unique key
			Format(szPlayerIdQuery, iQSize, "SELECT playerId FROM hlstats_PlayerUniqueIds WHERE game='%s' AND uniqueId='%s'", g_szHLXGameCode, szAuthIdEsc);
			#if DEBUG == 1
				LogToGame("[HLX-API] Sending query \"%s\"", szPlayerIdQuery);
			#endif
			SQL_TQuery(g_hHLXDatabase, OnGotClientHLXPlayerId, szPlayerIdQuery, GetClientUserId(client));
		}
	}
	#if DEBUG == 1
	else
	{
		LogToGame("[HLX-API] Player %N not in game, not connected, or is bot", client);
	}
	#endif
}

public OnGotClientHLXPlayerId(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		// player disconnected
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		ThrowError("Error retrieving playerId for %N", client);
	}
	
	if (SQL_GetRowCount(hndl) < 1)
	{
		ThrowError("Player %N not found in HLXCE database", client);
	}
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Got PlayerId");
	#endif
	
	SQL_FetchRow(hndl);
	new pid = SQL_FetchInt(hndl, 0);

	g_iClientHLXPlayerId[client] = pid;
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Firing HLXCE_OnClientReady Forward %N/%d", client, pid);
	#endif
	
	if (g_hFwdHLXClientReady != INVALID_HANDLE)
	{
		Call_StartForward(g_hFwdHLXClientReady);
		Call_PushCell(client);
		Call_Finish();
	}
	else
	{
		ThrowError("Handle to OnClientReady forward is invalid");
	}
}

GetAllPlayerIds()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_iClientHLXPlayerId[i] == -1)
		{
			#if DEBUG == 1
				LogToGame("[HLX-API] Getting PlayerId for client %d", i);
			#endif
			GetClientHLXPlayerId(i);
		}
	}
}

public Native_HLXCE_GetPlayerData(Handle:plugin, numParams)
{
	if (g_hHLXDatabase == INVALID_HANDLE)
	{
		SetFailState("Lost database connection");
	}
	
	new client = GetNativeCell(1);
	
	if (g_iClientHLXPlayerId[client] < 0)
	{
		ThrowNativeError(101, "Client %d \"%N\" is not HLX ready yet!", client, client);
	}
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Get client data for %N", client);
	#endif
	
	decl String:szQueryText[109];
	// should return no more than 1 row between game/uniqueId is a unique key
	Format(szQueryText, sizeof(szQueryText), "SELECT skill,kills,deaths,headshots,connection_time,shots,hits FROM hlstats_Players WHERE playerId=%d", g_iClientHLXPlayerId[client]);
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Sending query \"%s\"", szQueryText);
	#endif
	
	SQL_TQuery(g_hHLXDatabase, OnGotPlayerData, szQueryText, GetClientUserId(client));
}

public OnGotPlayerData(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (hndl == INVALID_HANDLE)
	{
		ThrowError("Error retrieving playerdata for %N (no handle)", client);
	}
	
	if (SQL_GetRowCount(hndl) < 1)
	{
		ThrowError("Error retrieving playerdata for %N (no rows)", client);
	}
	
	if (client == 0 || !IsClientInGame(client))
	{
		// client disconnected
		return;
	}
	
	SQL_FetchRow(hndl); // there will only be one row because playerId is unique
	for (new i = 0; i < 7; i++)
	{
		g_iPlayerCounts[client][i] = SQL_FetchInt(hndl, i);
		
		#if DEBUG == 1
			LogToGame("[HLX-API] %N data %d is %d", client, i, g_iPlayerCounts[client][i]);
		#endif
	}
	
	new iTempDeaths = g_iPlayerCounts[client][PData_Deaths];
	if (iTempDeaths == 0)
	{
		iTempDeaths = 1;
	}
	
	new iQSize = 180+g_iGameCodeLen;
	decl String:szQueryText[iQSize];
	Format(szQueryText, iQSize, "SELECT COUNT(*) FROM hlstats_Players WHERE game='%s' AND hideranking=0 AND kills>=1 AND((%s>%d)OR((%s=%d)AND(kills/IF(deaths=0,1,deaths)>%.3f)))", g_szHLXGameCode, g_szRankingType[g_iRankingType], g_iPlayerCounts[client][g_iRankingType], g_szRankingType[g_iRankingType], g_iPlayerCounts[client][g_iRankingType], FloatDiv(float(g_iPlayerCounts[client][PData_Kills]),float(iTempDeaths)));
	
	#if DEBUG == 1
		LogToGame("[HLX-API] Sending query \"%s\"", szQueryText);
	#endif
	
	SQL_TQuery(g_hHLXDatabase, OnGotPlayerRank, szQueryText, GetClientUserId(client));
}

public OnGotPlayerRank(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	
	if (hndl == INVALID_HANDLE)
	{
		ThrowError("Error retrieving rank for %N (no handle)", client);
	}
	
	if (SQL_GetRowCount(hndl) < 1)
	{
		ThrowError("Error retrieving rank for %N (no rows)", client);
	}
	
	if (client == 0 || !IsClientInGame(client))
	{
		// player disconnected
		return;
	}
	
	SQL_FetchRow(hndl);
	g_iPlayerCounts[client][PData_Rank] = (SQL_FetchInt(hndl, 0) + 1);
	
	#if DEBUG == 1
		LogToGame("[HLX-API] %N rank is %d", client, g_iPlayerCounts[client][PData_Rank]);
		LogToGame("[HLX-API] Firing HLXCE_OnGotPlayerData Forward %N/%d", client, pid);
	#endif
	
	if (g_hFwdHLXGotPlayerData != INVALID_HANDLE)
	{
		Call_StartForward(g_hFwdHLXGotPlayerData);
		Call_PushCell(client);
		Call_PushArray(g_iPlayerCounts[client][0], 8);
		Call_Finish();
	}
	else
	{
		ThrowError("Handle to GotPlayerData forward is invalid");
	}
}

public OnPluginEnd()
{
	if (g_hHLXDatabase != INVALID_HANDLE)
	{
		CloseHandle(g_hHLXDatabase);
		#if DEBUG == 1
			LogToGame("[HLX-API] Connected to the Database - Closing Connection");
		#endif
	}
	else
	{
		#if DEBUG == 1
			LogToGame("[HLX-API] Not Connected to the Database");
		#endif
	}
}
