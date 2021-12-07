#include <sourcemod>
#include <curl>
#include <steamtools>
#include <updater>

#define PLUGIN_VERSION "1.0.0"
#define UPDATER_URL ""

#define MAX_AUTH_LENGTH 64

#define INIT_CODE "CREATE TABLE IF NOT EXISTS `friendblock` ( \
  `steam_id` varchar(20) COLLATE utf8_unicode_ci NOT NULL, \
  `date_added` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP \
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"

#define INSERT_CODE "INSERT IGNORE INTO `friendblock` ( \
`steam_id` , \
`date_added` \
) \
VALUES ( \
'%s', \
CURRENT_TIMESTAMP"

#define DELETE_CODE "DELETE FROM `friendblock` WHERE `steam_id` = '%s'"

#define SELECT_DATE_CODE "SELECT `steam_id`, `date_added` FROM  `friendblock`"

#define SELECT_CODE "SELECT `steam_id` FROM `friendblock`"

new String:g_strAPIKey[128];
new bool:g_bEnabled;

new Handle:g_hSQLDB = INVALID_HANDLE,
	Handle:g_hBanTrie = INVALID_HANDLE,
	Handle:g_hCountTrie = INVALID_HANDLE;

#define BASE_URL "http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?relationship=friend&format=vdf"

new CURL_Default_opt[][2] = {
	{_:CURLOPT_NOSIGNAL,1},
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,30},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

public Plugin:myinfo = 
{
	name = "FriendBlock",
	author = "Mini",
	description = "Block your enemies' friends!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart()
{
	new Handle:conVar = CreateConVar("friendblock_enabled", "1");
	g_bEnabled = GetConVarBool(conVar);
	HookConVarChange(conVar, OnEnableChanged);

	conVar = CreateConVar("friendblock_api", "");
	GetConVarString(conVar, g_strAPIKey, sizeof(g_strAPIKey));
	HookConVarChange(conVar, OnAPIKeyChanged);

	RegAdminCmd("sm_friendblock", Command_Block, ADMFLAG_BAN);
	RegAdminCmd("sm_friendunblock", Command_UnBlock, ADMFLAG_BAN);
	RegAdminCmd("sm_reloadfriendbans", Command_Reload, ADMFLAG_BAN);
	RegAdminCmd("sm_friendsteamblock", Command_BlockSteamId, ADMFLAG_BAN);
	RegAdminCmd("sm_listbans", Command_ListBans, ADMFLAG_BAN);

	InitDatabaseConnection();
}

public OnClientAuthorized(client, const String:auth[])
{
	if (g_bEnabled && g_hBanTrie != INVALID_HANDLE)
	{
		decl String:steamId[64];
		if (GetTrieString(g_hBanTrie, auth, steamId, sizeof(steamId)))
		{
			Steam_CSteamIDToRenderedID(steamId, steamId, sizeof(steamId));
			KickClient(client, "You have been kicked for being on the friends list of (%s).", steamId);
		}
	}
}

stock InitDatabaseConnection()
{
	SQL_TConnect(OnSQLConnected, "friendblock");
}

public OnSQLConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ((g_hSQLDB = hndl) == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	}
	else 
	{
		SQL_TQuery(g_hSQLDB, OnSQLConnectedPost, INIT_CODE);
	}
}

public OnSQLConnectedPost(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
	}
	else if (!SQL_GetAffectedRows(hndl))
	{
		ReloadBans();
	}
}

public OnPlayersSelected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
	}
	decl String:steamId[MAX_AUTH_LENGTH];
	while (SQL_FetchRow(hndl))
	{
		new DBResult:result;
		SQL_FetchString(hndl, 0, steamId, sizeof(steamId), result);
		if (result == DBVal_Data)
		{
			TrimString(steamId);
			Steam_RenderedIDToCSteamID(steamId, steamId, sizeof(steamId));
			BanFriends(steamId, -1)
		}
	}
}

stock ReloadBans()
{
	SQL_TQuery(g_hSQLDB, OnPlayersSelected, SELECT_CODE);
}

public Action:Command_ListBans(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	//Later
	return Plugin_Handled;
}

public Action:Command_Reload(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	ReloadBans();
	ReplyToCommand(client, "[SM] FriendBlock bans have been successfully reloaded!");
	return Plugin_Handled;
}

public Action:Command_UnBlock(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_friendunblock <Steam ID>");
		return Plugin_Handled;
	}
	decl String:arg[256];
	GetCmdArgString(arg, sizeof(arg));
	TrimString(arg);
	Steam_RenderedIDToCSteamID(arg, arg, sizeof(arg));
	Format(arg, sizeof(arg), DELETE_CODE, arg);
	SQL_TQuery(g_hSQLDB, OnDeleteQuery, arg, GetClientUserId(client));
	return Plugin_Handled;
}

public OnDeleteQuery(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	new client = GetClientOfUserId(userid);
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		if (client > 0)
		{
			PrintToChat(client, "[SM] Could not unban client. Please notify the server administrator.");
		}
	}
	else if (!SQL_GetAffectedRows(hndl))
	{
		if (client > 0)
		{
			PrintToChat(client, "[SM] Could not unban client. Please notify the server administrator.");
		}
	}
	if (client > 0)
	{
		PrintToChat(client, "[SM] Sucessfully unbanned the entered Steam ID.");
	}
}

public Action:Command_BlockSteamId(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_friendsteamblock <Steam ID>");
		return Plugin_Handled;
	}
	decl String:arg[1024];
	GetCmdArgString(arg, sizeof(arg));
	StripQuotes(arg);
	Steam_RenderedIDToCSteamID(arg, arg, sizeof(arg));
	BanFriends(arg, client);
	return Plugin_Handled;
}

public Action:Command_Block(client, args)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_friendblock <name|#userid>");
		return Plugin_Handled;
	}
	decl String:arg[1024];
	GetCmdArgString(arg, sizeof(arg));
	StripQuotes(arg);
	new target = FindTarget(client, arg);
	if (target != -1)
	{
		if (IsClientAuthorized(target))
		{
			decl String:cSteamId[MAX_AUTH_LENGTH];
			Steam_GetCSteamIDForClient(target, cSteamId, sizeof(cSteamId));
			BanFriends(cSteamId, client);
		}
		else
		{
			ReplyToCommand(client, "[SM] Targetted client is not authorized.");
		}
	}
	return Plugin_Handled;
}

stock BanFriends(String:cSteamId[], client = -1)
{
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/%s-friends.kv", cSteamId);
	decl String:url[1024];
	Format(url, sizeof(url), "%s&key=%s&steamid=%s", BASE_URL, g_strAPIKey, cSteamId);
	new Handle:curl = curl_easy_init();
	if (curl != INVALID_HANDLE)
	{
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, (client == -1 ? -1 : GetClientUserId(client)));
		WritePackString(pack, path);
		WritePackString(pack, cSteamId);
		ResetPack(pack);

		new Handle:file = curl_OpenFile(path, "w");
		CURL_DEFAULT_OPT(curl);
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, file);
		curl_easy_setopt_string(curl, CURLOPT_URL, url);
		curl_easy_perform_thread(curl, OnFileDownloaded, pack);
	}
}

public OnFileDownloaded(Handle:hndl, CURLcode:code, any:pack)
{
	new userId = ReadPackCell(pack);
	new client = userId == -1 ? -1 : GetClientOfUserId(userId);
	if (code != CURLE_OK)
	{
		if (client > 0)
		{
			PrintToChat(client, "[SM] Could not retrieve targetted user's friends list.");
		}
		return;
	}
	decl String:path[PLATFORM_MAX_PATH];
	ReadPackString(pack, path, sizeof(path));
	new Handle:kv = CreateKeyValues("friendslist");
	if (!FileToKeyValues(kv, path))
	{
		if (client > 0)
		{
			PrintToChat(client, "[SM] Could not retrieve targetted user's friends list.");
		}
		return;
	}
	if (!KvGotoFirstSubKey(kv))
	{
		if (client > 0)
		{
			PrintToChat(client, "[SM] No friends found for the targetted user or the targetted user has a private profile.");
		}
		return;
	}
	if (!KvGotoFirstSubKey(kv))
	{
		if (client > 0)
		{
			PrintToChat(client, "[SM] No friends found for the targetted user or the targetted user has a private profile.");
		}
		return;
	}
	decl String:owner[MAX_AUTH_LENGTH], String:buffer[MAX_AUTH_LENGTH];
	ReadPackString(pack, owner, sizeof(owner));
	Steam_CSteamIDToRenderedID(owner, owner, sizeof(owner));
	new count = 0;
	do
	{
		KvGetString(kv, "steamid", buffer, sizeof(buffer));
		Steam_CSteamIDToRenderedID(buffer, buffer, sizeof(buffer));
		AddBan(buffer, owner);
		count++;
	}
	while (KvGotoNextKey(kv));
	DeleteFile(path);
	SetTrieValue(g_hCountTrie, owner, count);
	PrintToChat(client, "[SM] Sucessfully blocked all of the targetted user's friends.");
}

stock AddBan(String:steamId[], String:owner[])
{
	SetTrieString(g_hBanTrie, steamId, owner);
}

stock InsertSQLBan(String:steamId[])
{
	if (g_hSQLDB != INVALID_HANDLE)
	{
		decl String:query[512];
		FormatEx(query, sizeof(query), INSERT_CODE, steamId);
		SQL_TQuery(g_hSQLDB, OnQueryExecuted, query);
	}
	else
	{
		LogError("Could not block Steam ID %s because server is not connected to the specified SQL database.", steamId);
	}
}

public OnQueryExecuted(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database error: %s", error);
	}
}

public OnEnableChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = bool:StringToInt(newVal);
}

public OnAPIKeyChanged(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	strcopy(g_strAPIKey, sizeof(g_strAPIKey), newVal);
}

/////////////////////////////////
// Hi McKay
// I hate those brackets
// Bye McKay
/////////////////////////////////
/*
public OnAllPluginsLoaded() 
{
		new Handle:convar;
		if (LibraryExists("updater")) 
		{
				Updater_AddPlugin(UPDATER_URL);
				new String:newVersion[10];
				Format(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
				convar = CreateConVar("friendblock_version", newVersion, "FriendBlock Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
		} 
		else
		{
				convar = CreateConVar("friendblock_version", PLUGIN_VERSION, "FriendBlock Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);   
		}
		HookConVarChange(convar, Callback_VersionConVarChanged);
}

public Callback_VersionConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
		ResetConVar(convar);
}


public Action:Updater_OnPluginDownloading() 
{
		if (!GetConVarBool(updaterCvar))
		{
				return Plugin_Handled;
		}
		return Plugin_Continue;
}

public OnLibraryAdded(const String:name[]) 
{
		if (StrEqual(name, "updater")) 
		{
				Updater_AddPlugin(UPDATER_URL);
		}
}

public Updater_OnPluginUpdated()
{
		ReloadPlugin();
}
*/