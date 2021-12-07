/*
 * =============================================================================
 * SourceMod Extended ChatLog v1.3.2 [L4D] Plugin (modified by muukis)
 * Logs chat to SQL in a very thready manner.
 *
 * SourceMod (C)2004-2009 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
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
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
*/

#pragma semicolon 1

#include <sourcemod>

new bool:g_TeamFilter[MAXPLAYERS + 1] = { false, ... };
new String:m_mode[12];
new m_lastplayercount = 0;
new m_lastmaxplayercount = 0;

public Plugin:myinfo = 
{
	name = "ChatLogEx [L4D]",
	author = "Nephyrin (modified by muukis)",
	description = "Logs chat to SQL in a very thready manner.",
	version = "1.3.2",
	url = "http://www.sourcemod.net/"
};

new Handle:hdatabase = INVALID_HANDLE;
new Handle:sm_chatlogex_id = INVALID_HANDLE;
new Handle:sm_chatlogex_filtermode = INVALID_HANDLE;
new Handle:sm_chatlogex_srvmsgs = INVALID_HANDLE;
new Handle:sm_chatlogex_mpcoop = INVALID_HANDLE;
new Handle:sm_chatlogex_mpversus = INVALID_HANDLE;
new Handle:sm_chatlogex_mpsurvival = INVALID_HANDLE;
new Handle:mp_gamemode = INVALID_HANDLE;

public OnPluginStart()
{
	sm_chatlogex_id = CreateConVar("sm_chatlogex_id", "", "The id to use for logging this server's chat to the database. Must be set for this plugin to function.");
	sm_chatlogex_filtermode = CreateConVar("sm_chatlogex_filtermode", "1", "1 [default] causes ChatLogEx to log messages post-processing by other addons. This means chat messages will be logged as they are seen by players, and wont include @commands or censored chat. 0 means ChatLog will directly log 'say' commands, which will include admin messages, messages that are ultimately changed by other plugins, and might not include chat events generated by other plugins.");
	// Added by muukis
	sm_chatlogex_srvmsgs = CreateConVar("sm_chatlogex_srvmsgs", "1", "1 [default] causes ChatLogEx to log server messages.");

	sm_chatlogex_mpcoop = CreateConVar("sm_chatlogex_mpcoop", "4", "4 [default] max players in co-op gamemode. This value is displayed on 'players online' messages.");
	sm_chatlogex_mpversus = CreateConVar("sm_chatlogex_mpversus", "8", "8 [default] max players in versus gamemode. This value is displayed on 'players online' messages.");
	sm_chatlogex_mpsurvival = CreateConVar("sm_chatlogex_mpsurvival", "4", "4 [default] max players in survival gamemode. This value is displayed on 'players online' messages.");

	// Added by muukis
	AutoExecConfig(true, "sm_chatlogex");

	mp_gamemode = FindConVar("mp_gamemode");
	
	SQL_TConnect(sql_Connect, "default"); // Change if you don't want to use 'default'
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	if (!HookEventEx("player_say", Event_PlayerChat, EventHookMode_Post))
	{
		LogError("Failed to hook player_say, sm_chatlogex_filtermode 1 will not work");
	}
	
	// Added by muukis
	if (!HookEventEx("player_connect", Event_PlayerConnect, EventHookMode_Post))
	{
		LogError("Failed to hook player_connect!");
	}
	
	// Added by muukis
	if (!HookEventEx("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post))
	{
		LogError("Failed to hook player_disconnect!");
	}
	
	// Added by muukis
	if (!HookEventEx("player_info", Event_PlayerInfo, EventHookMode_Post))
	{
		LogError("Failed to hook player_info!");
	}
	
	SetCurrentGameMode();
	
	m_lastmaxplayercount = GetMaxPlayersForCurrentGameMode();
}

public sql_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		SetFailState("Database failure: %s", error);
	else
		hdatabase = hndl;

	InitialSQL();
}

SetCurrentGameMode()
{
	GetCurrentGameMode(m_mode, sizeof(m_mode));
}

GetCurrentGameMode(String:mode[], maxlength)
{
	if(mp_gamemode != INVALID_HANDLE)
		GetConVarString(mp_gamemode, mode, maxlength);
	else
		Format(mode, maxlength, "");
}

public Action:Event_PlayerChat(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_chatlogex_filtermode) != 0)
	{
		new String:text[257];
		GetEventString(event, "text", text, sizeof(text));
		new uid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(uid);
		logSomeTextYo(client, text, g_TeamFilter[client]);
	}

	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	decl String:command[12];
	
	GetCmdArg(0, command, sizeof(command));
	
	g_TeamFilter[client] = strcmp(command, "say_team") ? false : true;
	
	if (GetConVarInt(sm_chatlogex_filtermode) == 0)
	{
		decl String:textBuffer[128], String:textClean[128];
		
		GetCmdArgString(textBuffer, sizeof(textBuffer));
		
		new startidx = 0;
		new len = strlen(textBuffer);
		
		if ((textBuffer[0] == '"') && (textBuffer[len-1] == '"'))
		{
			startidx = 1;
			textBuffer[len-1] = '\0';
		}
		
		Format(textClean, sizeof(textClean), "%s", textBuffer[startidx]);

		logSomeTextYo(client, textClean, g_TeamFilter[client]);
	}
	
	return Plugin_Continue;
}

public Action:LogOnMapStart(Handle:timer)
{
	if(!GetConVarBool(sm_chatlogex_srvmsgs))
		return;

	decl String:srvid[255];
	
	GetConVarString(sm_chatlogex_id, srvid, sizeof(srvid));
	
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return;
	}

	decl String:mapname[255], String:text[256];
	GetCurrentMap(mapname, sizeof(mapname));
	SetCurrentGameMode();

	if(StrEqual(m_mode, ""))
		Format(text, sizeof(text), "Map started (%s)", mapname);
	else
		Format(text, sizeof(text), "Map started (%s:%s)", m_mode, mapname);

	logSomeTextYo2("", "", text, -1, srvid, -1);
	
	LogPlayerCount();
}

// Added by muukis
public OnMapStart()
{
	CreateTimer(1.0, LogOnMapStart);
}

// Added by muukis
public OnMapEnd()
{
	if(!GetConVarBool(sm_chatlogex_srvmsgs))
		return;

	decl String:srvid[255];
	
	GetConVarString(sm_chatlogex_id, srvid, sizeof(srvid));
	
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return;
	}

	decl String:mapname[255], String:text[256];
	GetCurrentMap(mapname, sizeof(mapname));

	if(StrEqual(m_mode, ""))
		Format(text, sizeof(text), "Map ended (%s)", mapname);
	else
		Format(text, sizeof(text), "Map ended (%s:%s)", m_mode, mapname);

	logSomeTextYo2("", "", text, -1, srvid, -1);
}

// Added by muukis
public Action:Event_PlayerInfo(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(sm_chatlogex_srvmsgs))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidPlayer(client))
		return Plugin_Continue;

	if (GetConVarInt(sm_chatlogex_srvmsgs) == 0)
		return Plugin_Continue;
	
	decl String:srvid[255];
	
	GetConVarString(sm_chatlogex_id, srvid, sizeof(srvid));
	
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return Plugin_Continue;
	}

	decl String:username[65], String:reason[128], String:text[256];
	
	GetEventString(event, "name", username, sizeof(username));
	GetEventString(event, "reason", reason, sizeof(reason));
	
	decl String:authid[32], String:nameBuffer[32];
	GetClientAuthString(client, authid, sizeof(authid));
	GetClientName(client, nameBuffer, sizeof(nameBuffer));

	Format(text, sizeof(text), "Player %s changed name to %s", username, nameBuffer);

	logSomeTextYo2("", authid, text, -1, srvid, -1);
	
	return Plugin_Continue;
}

// Added by muukis
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(sm_chatlogex_srvmsgs))
		return Plugin_Continue;

	decl String:text[256], String:username[65];

	GetEventString(event, "address", username, sizeof(username));
	
	if(strcmp(username, "none", false) == 0)
		return Plugin_Continue;

	decl String:srvid[255];
	
	GetConVarString(sm_chatlogex_id, srvid, sizeof(srvid));
	
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return Plugin_Continue;
	}

	GetEventString(event, "name", username, sizeof(username));
	Format(text, sizeof(text), "Player %s connected", username);

	logSomeTextYo2("", "", text, -1, srvid, -1);

	CreateTimer(1.0, LogPlayerCountTimer);

	return Plugin_Continue;
}

// Added by muukis
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(sm_chatlogex_srvmsgs))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidPlayer(client))
		return Plugin_Continue;

	if (GetConVarInt(sm_chatlogex_srvmsgs) == 0)
		return Plugin_Continue;
	
	decl String:srvid[255];
	
	GetConVarString(sm_chatlogex_id, srvid, sizeof(srvid));
	
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return Plugin_Continue;
	}

	decl String:username[65], String:reason[128], String:text[256], String:authid[32];
	
	GetEventString(event, "name", username, sizeof(username));
	GetEventString(event, "reason", reason, sizeof(reason));
	
	Format(text, sizeof(text), "Player %s disconnected (%s)", username, reason);

	GetClientAuthString(client, authid, sizeof(authid));
	
	logSomeTextYo2("", authid, text, -1, srvid, -1);

	CreateTimer(1.0, LogPlayerCountTimer);
	
	return Plugin_Continue;
}

public logSomeTextYo(client, String:text[], bool:isteam)
{
	decl String:srvid[255];
	GetConVarString(sm_chatlogex_id, srvid, 255);
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return;
	}
	
	new chattype = 0;
	decl String:authid[32], String:nameBuffer[32], teamnum;
	if (client != 0)
	{
		if (!IsPlayerAlive(client)) //ignore 'console'
			chattype += 1;
		if (isteam)
			chattype += 2;
		GetClientAuthString(client, authid, sizeof(authid));
		GetClientName(client, nameBuffer, sizeof(nameBuffer));
		teamnum = GetClientTeam(client);
	}
	else
	{
		Format(nameBuffer, sizeof(nameBuffer), "Console");
		Format(authid, sizeof(authid), "");
		teamnum = 0;
	}

	// Added by muukis
	logSomeTextYo2(nameBuffer, authid, text, teamnum, srvid, chattype);
}

// Added bu muukis
public logSomeTextYo2(String:name[], String:authid[], String:text[], teamnum, String:srvid[], chattype)
{
	if (hdatabase == INVALID_HANDLE)
	{
		LogError("ChatLogEx: Cannot log message, handle hdatabase is not set!");
		return;
	}

	decl String:nameesc[65], String:textesc[257], String:query[1024];

	SQL_EscapeString(hdatabase, text, textesc, sizeof(textesc));
	SQL_EscapeString(hdatabase, name, nameesc, sizeof(nameesc));

	Format(query, sizeof(query), "INSERT INTO chatlogs (name, steamid, text, team, srvid, type) VALUES ('%s', '%s', '%s', %i, '%s', %i)", nameesc, authid, textesc, teamnum, srvid, chattype);

	SendQuery(query);
}

PlayerCounter()
{
	new counter = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			counter++;
		}
	}
	
	return counter;
}

GetMaxPlayersForCurrentGameMode()
{
	if(StrEqual(m_mode, "coop", false))
	{
		return GetConVarInt(sm_chatlogex_mpcoop);
	}
	else if(StrEqual(m_mode, "versus", false))
	{
		return GetConVarInt(sm_chatlogex_mpversus);
	}
	
	return GetConVarInt(sm_chatlogex_mpsurvival);
}

LogPlayerCount()
{
	decl String:srvid[255];
	GetConVarString(sm_chatlogex_id, srvid, 255);
	if (!strcmp(srvid, ""))
	{
		LogError("ChatLogEx: Cannot log message, sm_chatlogex_id is not set!");
		return;
	}
	
	new playercount = PlayerCounter();
	new maxplayercount = GetMaxPlayersForCurrentGameMode();
	
	if(playercount == m_lastplayercount && m_lastmaxplayercount == maxplayercount)
		return;
	
	m_lastplayercount = playercount;
	m_lastmaxplayercount = maxplayercount;
	
	decl String:text[256];
	
	Format(text, sizeof(text), "%d/%d players online", m_lastplayercount, m_lastmaxplayercount);
	
	logSomeTextYo2("", "", text, -1, srvid, -1);
}

public Action:LogPlayerCountTimer(Handle:timer)
{
	LogPlayerCount();
}

// Added bu muukis
public IsValidClient(client)
{
	if (client > 0 && client <= GetMaxClients())
		return true;
	else
		return false;
}

// Added bu muukis
public IsValidPlayer(client)
{
	if (!IsValidClient(client))
		return false;

	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return false;

	if (!IsClientInGame(client))
		return false;

	return true;
}

public sql_Query(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data);

	if (hndl == INVALID_HANDLE)
	{
		decl String:query[255];
		ReadPackString(data, query, sizeof(query));

		LogError("Query Failed! %s", error);
		LogError("Query: %s", query);
	}

	CloseHandle(data);
	CloseHandle(hndl);
}

stock SendQuery(String:query[])
{
	new Handle:dp = CreateDataPack();
	WritePackString(dp, query);
	SQL_TQuery(hdatabase, sql_Query, query, dp);
}

InitialSQL()
{
	// Switch to utf8
	SendQuery("SET NAMES utf8;");

	decl String:query[1024];
	Format(query, sizeof(query), "%s%s%s%s%s%s%s%s%s%s%s%s%s",
		"CREATE TABLE IF NOT EXISTS `chatlogs` (",
		"  `seqid` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,",
		"  `srvid` varchar(255) NOT NULL,",
		"  `date` timestamp NOT NULL default CURRENT_TIMESTAMP,",
		"  `name` varchar(32) NOT NULL,",
		"  `steamid` varchar(32) NOT NULL,",
		"  `text` varchar(192) NOT NULL,",
		"  `team` int(1) NOT NULL,",
		"  `type` int(2) NOT NULL,",
		"  INDEX (`srvid`),",
		"  INDEX (`steamid`))",
		"  DEFAULT CHARSET=utf8",
		";"
	);

	SendQuery(query);
}

