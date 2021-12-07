/*
* 
* VAC Status Checker
* http://forums.alliedmods.net/showthread.php?t=80942
* 
* Description:
* Looks up VAC Status of connecting clients using the Steam
* Community and takes the desired action. Useful for admins who want to
* block access to people caught cheating on another engine.
* 
* Requires Socket Extension by sfPlayer
* (http://forums.alliedmods.net/showthread.php?t=67640)
* 
* Credits:
* 	voogru - finding the relationship between SteamIDs and friendIDs
*   StrontiumDog - the fixed function that converts SteamIDs
* 	berni - the original function that converts SteamIDs
* 	Sillium - German translation
* 	jack_wade - Spanish translation
* 	Tournevis_man - French translation
* 	OziOn - Danish translation
*   danielsumi - Portuguese translation
*   Archangel_Dm - Russian translation
*   lhffan - Swedish translation
*   ZuCChiNi - Turkish translation
* 
* Changelog
* Nov 15, 2013 - v.1.3.6:
*               [*] Fixed DataPack operation out of bounds errors
* Mar 27, 2013 - v.1.3.5:
*               [*] Fixed bans firing too early
* Sep 04, 2011 - v.1.3.4:
*               [*] Fixed some race conditions
* Feb 09, 2010 - v.1.3.3:
* 				[+] Added filter for bots on client checks
* Jul 24, 2009 - v.1.3.2:
* 				[*] Fixed logging error
* Jul 18, 2009 - v.1.3.1:
* 				[*] Removed format from translations to fix odd error
* May 25, 2009 - v.1.3.0:
* 				[+] Added support for other named database configs
* Apr 13, 2009 - v.1.2.1:
* 				[*] Fixed conversion of long SteamIDs (StrontiumDog)
* Mar 26, 2009 - v.1.2.0:
* 				[+] Added whitelist support
* 				[*] Changed some messages to reflect the plugin name
* Mar 19, 2009 - v.1.1.1:
* 				[*] Fixed bans triggering before client is in-game
* 				[-] Removed dependency on the regex extension
* 				[+] Added logging to vacbans.log for all action settings
* Feb 23, 2009 - v.1.1.0:
* 				[*] Now uses DataPacks instead of files for data storage
* 				[+] Added RegEx to scan raw downloaded data
* 				[+] Verifies client against original ID after scanning profile
* 				[*] Now uses FriendID instead of SteamID for the database keys
* 				[*] Various code organization improvements
* 				[+] Added command to reset the local cache database
* Feb 19, 2009 - v.1.0.1:
* 				[*] Changed file naming to avoid conflicts
* Nov 24, 2008 - v.1.0.0:
* 				[*] Initial Release
* 
*/

#pragma semicolon 1
#include <sourcemod>
#include <socket>

#define PLUGIN_VERSION "1.3.6"

public Plugin:myinfo = 
{
	name = "VAC Status Checker",
	author = "Stevo.TVR",
	description = "Looks up VAC status of connecting clients and takes desired action",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

new Handle:hDatabase = INVALID_HANDLE;

new Handle:sm_vacbans_db = INVALID_HANDLE;
new Handle:sm_vacbans_cachetime = INVALID_HANDLE;
new Handle:sm_vacbans_action = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_vacbans_version", PLUGIN_VERSION, "VAC Ban Checker plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_vacbans_db = CreateConVar("sm_vacbans_db", "storage-local", "The named database config to use for caching");
	sm_vacbans_cachetime = CreateConVar("sm_vacbans_cachetime", "30", "How long in days before re-checking the same client for VAC status", _, true, 0.0);
	sm_vacbans_action = CreateConVar("sm_vacbans_action", "0", "Action to take on VAC banned clients (0 = ban, 1 = kick, 2 = admin message)", _, true, 0.0, true, 2.0);
	AutoExecConfig(true, "vacbans");
	
	RegConsoleCmd("sm_vacbans_reset", Command_Reset);
	RegConsoleCmd("sm_vacbans_whitelist", Command_Whitelist);
	
	LoadTranslations("vacbans.phrases");
}

public OnConfigsExecuted()
{
	decl String:db[64];
	GetConVarString(sm_vacbans_db, db, sizeof(db));
	SQL_TConnect(T_DBConnect, db);
}

public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client))
	{
		decl String:query[1024];
		decl String:steamID[64];
		decl String:friendID[32];
		
		GetClientAuthString(client, steamID, sizeof(steamID));
		
		if(GetFriendID(steamID, friendID, sizeof(friendID)))
		{
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, client);
			WritePackString(hPack, friendID);
			
			Format(query, sizeof(query), "SELECT * FROM `vacbans` WHERE `steam_id` = '%s' AND (`expire` > %d OR `expire` = 0) LIMIT 1;", friendID, GetTime());
			SQL_TQuery(hDatabase, T_PlayerLookup, query, hPack);
		}
	}
}

public OnSocketConnected(Handle:hSock, any:hPack)
{
	new String:friendID[32];
	decl String:requestStr[128];
	
	SetPackPosition(hPack, 16);
	ReadPackString(hPack, friendID, sizeof(friendID));
	
	Format(requestStr, sizeof(requestStr), "GET /profiles/%s?xml=1 HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", friendID, "steamcommunity.com");
	SocketSend(hSock, requestStr);
}

public OnSocketConnected2(Handle:hSock, any:hPack)
{
	decl String:redirURL[64];
	decl String:requestStr[512];
	
	SetPackPosition(hPack, 8);
	new Handle:hData = Handle:ReadPackCell(hPack);
	
	ResetPack(hData);
	ReadPackString(hData, redirURL, sizeof(redirURL));
	ResetPack(hData, true);
	
	Format(requestStr, sizeof(requestStr), "GET %s?xml=1 HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", redirURL, "steamcommunity.com");
	SocketSend(hSock, requestStr);
}

public OnSocketReceive(Handle:hSock, String:receiveData[], const dataSize, any:hPack)
{
	SetPackPosition(hPack, 8);
	new Handle:hData = Handle:ReadPackCell(hPack);
	
	WritePackString(hData, receiveData);
}

public OnSocketDisconnected(Handle:hSock, any:hPack)
{
	new String:XMLData[4096];
	
	CloseHandle(hSock);
	
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new Handle:hData = Handle:ReadPackCell(hPack);
	
	ResetPack(hData);
	decl String:buffer[4096];
	while(IsPackReadable(hData, 1)) {
		ReadPackString(hData, buffer, sizeof(buffer));
		StrCat(XMLData, sizeof(XMLData), buffer);
	}
	
	new pos;
	if((pos = StrContains(XMLData, "Location: http://steamcommunity.com", false)) >= 0)
	{
		decl String:redirURL[64];
		SplitString(XMLData[pos+35], "\r", redirURL, sizeof(redirURL));
		
		ResetPack(hData, true);
		WritePackString(hData, redirURL);
		
		// Create a second socket because the original is invalid for some reason
		hSock = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketSetArg(hSock, hPack);
		SocketConnect(hSock, OnSocketConnected2, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80);
	}
	else if((pos = StrContains(XMLData, "<vacBanned>")) >= 0)
	{
		decl String:friendID[32];
		ReadPackString(hPack, friendID, sizeof(friendID));
		new String:banned[2];
		strcopy(banned, sizeof(banned), XMLData[pos+11]);
		
		HandleClient(client, friendID, StrEqual(banned, "1"));
		
		CloseHandle(hData);
		CloseHandle(hPack);
	}
	else
	{
		CloseHandle(hData);
		CloseHandle(hPack);
	}
}

public OnSocketError(Handle:hSock, const errorType, const errorNum, any:hPack)
{
	LogError("Socket error %d (errno %d)", errorType, errorNum);
	
	CloseHandle(hPack);
	CloseHandle(hSock);
}

public Action:Command_Reset(client, args)
{
	if(client == 0 || ((GetUserFlagBits(client) & ADMFLAG_RCON) == ADMFLAG_RCON))
	{
		SQL_FastQuery(hDatabase, "DELETE FROM `vacbans` WHERE `expire` != 0;");
		ReplyToCommand(client, "[SM] Local VAC Status Checker cache has been reset.");
	}
	return Plugin_Handled;
}

public Action:Command_Whitelist(client, args)
{
	if(client == 0 || ((GetUserFlagBits(client) & ADMFLAG_RCON) == ADMFLAG_RCON))
	{
		if(args >= 2)
		{
			decl String:argString[72];
			decl String:action[8];
			decl String:steamID[64];
			decl String:friendID[64];
			
			GetCmdArgString(argString, sizeof(argString));
			new pos = BreakString(argString, action, sizeof(action));
			strcopy(steamID, sizeof(steamID), argString[pos]);
			
			
			if(GetFriendID(steamID, friendID, sizeof(friendID)))
			{
				decl String:query[1024];
				if(StrEqual(action, "add"))
				{
					Format(query, sizeof(query), "REPLACE INTO `vacbans` VALUES('%s', '0', '0');", friendID);
					SQL_TQuery(hDatabase, T_FastQuery, query);
					
					ReplyToCommand(client, "[SM] STEAM_%s added to the VAC Status Checker whitelist.", steamID);
					
					return Plugin_Handled;
				}
				if(StrEqual(action, "remove"))
				{
					Format(query, sizeof(query), "DELETE FROM `vacbans` WHERE `steam_id` = '%s';", friendID);
					SQL_TQuery(hDatabase, T_FastQuery, query);
					
					ReplyToCommand(client, "[SM] STEAM_%s removed from the VAC Status Checker whitelist.", steamID);
					
					return Plugin_Handled;
				}
			}
		}
		else if(args == 1)
		{
			decl String:action[8];
			
			GetCmdArg(1, action, sizeof(action));
			
			if(StrEqual(action, "clear"))
			{
				SQL_TQuery(hDatabase, T_FastQuery, "DELETE FROM `vacbans` WHERE `expire` = 0;");
				
				ReplyToCommand(client, "[SM] VAC Status Checker whitelist cleared.");
				
				return Plugin_Handled;
			}
		}
		
		ReplyToCommand(client, "Usage: sm_vacbans_whitelist <add|remove|clear> [SteamID]");
	}
	return Plugin_Handled;
}

HandleClient(client, const String:friendID[], bool:vacBanned)
{
	if(IsClientAuthorized(client))
	{
		// Check to make sure this is the same client that originally connected
		decl String:steamID[64];
		GetClientAuthString(client, steamID, sizeof(steamID));
		decl String:clientFriendID[32];
		if(!GetFriendID(steamID, clientFriendID, sizeof(clientFriendID)) || !StrEqual(friendID, clientFriendID))
		{
			return;
		}
		
		new banned = 0;
		new expire = GetTime() + (GetConVarInt(sm_vacbans_cachetime)*86400);
		new action = GetConVarInt(sm_vacbans_action);
		
		if(vacBanned)
		{
			banned = 1;
			switch(action)
			{
				case 0:
				{
					decl String:userformat[64];
					Format(userformat, sizeof(userformat), "%L", client);
					LogAction(0, client, "%s %T", userformat, "Banned_Server", LANG_SERVER);
					
					ServerCommand("sm_ban #%d 0 \"[VAC Status Checker] %T\"", GetClientUserId(client), "Banned", client);
				}
				case 1:
				{
					KickClient(client, "[VAC Bans] %t", "Kicked");
				}
				case 2:
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && !IsFakeClient(i) && CheckCommandAccess(i, "sm_listvac", ADMFLAG_BAN))
						{
							PrintToChat(i, "%s has VAC bans on record.", client);
						}
					}
				}
			}
			decl String:path[PLATFORM_MAX_PATH];
			BuildPath(PathType:Path_SM, path, sizeof(path), "logs/vacbans.log");
			LogToFile(path, "Player %L is VAC Banned", client);
		}
		
		decl String:query[1024];
		Format(query, sizeof(query), "REPLACE INTO `vacbans` VALUES('%s', '%d', '%d');", friendID, banned, expire);
		SQL_TQuery(hDatabase, T_FastQuery, query);
	}
}

bool:GetFriendID(String:AuthID[], String:FriendID[], size)
{
	ReplaceString(AuthID, strlen(AuthID), "STEAM_", "");
	if (StrEqual(AuthID, "ID_LAN"))
	{
		FriendID[0] = '\0';
		return false;
	}
	decl String:toks[3][16];
	new upper = 765611979;
	new String:temp[12], String:carry[12];

	ExplodeString(AuthID, ":", toks, sizeof(toks), sizeof(toks[]));
	new iServer = StringToInt(toks[1]);
	new iAuthID = StringToInt(toks[2]);
	new iFriendID = (iAuthID*2) + 60265728 + iServer;

	if (iFriendID >= 100000000)
	{
		Format(temp, sizeof(temp), "%d", iFriendID);
		Format(carry, 2, "%s", temp);
		new icarry = StringToInt(carry[0]);
		upper += icarry;

		Format(temp, sizeof(temp), "%d", iFriendID);
		Format(FriendID, size, "%d%s", upper, temp[1]);
	}
	else
	{
		Format(FriendID, size, "765611979%d", iFriendID);
	}

	return true;
}

// Threaded DB stuff
public T_DBConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	hDatabase = hndl;
	SQL_TQuery(hDatabase, T_FastQuery, "CREATE TABLE IF NOT EXISTS `vacbans` (`steam_id` VARCHAR(64) NOT NULL, `banned` BOOL NOT NULL, `expire` INT(11) NOT NULL, PRIMARY KEY (`steam_id`));");
}

public T_PlayerLookup(Handle:owner, Handle:hQuery, const String:error[], any:hPack)
{
	new bool:checked = false;
	
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	decl String:friendID[32];
	ReadPackString(hPack, friendID, sizeof(friendID));
	CloseHandle(hPack);
	
	if(hQuery != INVALID_HANDLE)
	{
		if(SQL_GetRowCount(hQuery) > 0)
		{
			checked = true;
			while(SQL_FetchRow(hQuery))
			{
				if(SQL_FetchInt(hQuery, 1) > 0)
				{
					HandleClient(client, friendID, true);
				}
			}
		}
	}
	
	if(!checked)
	{
		new Handle:hPack2 = CreateDataPack();
		new Handle:hData = CreateDataPack();
		new Handle:hSock = SocketCreate(SOCKET_TCP, OnSocketError);
		
		WritePackCell(hPack2, client);
		WritePackCell(hPack2, _:hData);
		WritePackString(hPack2, friendID);
		
		SocketSetArg(hSock, hPack2);
		SocketConnect(hSock, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "steamcommunity.com", 80);
	}
}

public T_FastQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Nothing to do
}

// You're crazy, man...