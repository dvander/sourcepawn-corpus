#include <sourcemod>

new Handle:g_hSQL;

public Plugin:myinfo =
{
	name        = "ConnectPM",
	author      = "alongub",
	description = "Allows you to set messages for players based on their SteamID.",
	version     = "1.0.0",
	url         = "http://hl2.co.il"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_addpm", Command_AddPrivateMessage, ADMFLAG_CHAT, "Adds a private message.");
	ConnectSQL();
}

ConnectSQL()
{
	if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
	else
	{
		SetFailState("No config entry found for 'connect_pm' in databases.cfg.");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Connection to SQL database has failed, Reason: %s", error);
		return;
	}

	decl String:sDriver[16];
	SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));

	g_hSQL = CloneHandle(hndl);		

	SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `connect_pm` (`id` INTEGER PRIMARY KEY, `account_id` INTEGER NOT NULL, `message` varchar(192) NOT NULL, `sender_name` varchar(32));");
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error while trying to create tables: %s", error);
		return;
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT message, sender_name FROM connect_pm WHERE account_id = %d", GetClientAccountID(client));

	SQL_TQuery(g_hSQL, ReceiveMessagesCallback, query, client);
}

public ReceiveMessagesCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on ReceiveMessagesCallback: %s", error);
		return;
	}
	
	while (SQL_FetchRow(hndl))
	{
		decl String:message[192];
		SQL_FetchString(hndl, 0, message, sizeof(message));
		
		if (SQL_IsFieldNull(hndl, 1))
		{
			PrintToChat(client, "[PM] %s", message);
		}
		else
		{
			decl String:senderName[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 1, senderName, sizeof(senderName));
		
			PrintToChat(client, "[PM from %s] %s", senderName, message);
		}
	}
	
	decl String:query[255];
	Format(query, sizeof(query), "DELETE FROM connect_pm WHERE account_id = %d", GetClientAccountID(client));

	SQL_TQuery(g_hSQL, DeleteMessagesCallback, query);	
}

public DeleteMessagesCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on DeleteMessagesCallback: %s", error);
		return;
	}
}

public Action:Command_AddPrivateMessage(client, args)
{
	decl String:commandLine[256];
	GetCmdArgString(commandLine, sizeof(commandLine));
	
	new len;
	
	decl String:receiver[32];
	if ((len = BreakString(commandLine, receiver, sizeof(receiver))) == -1)
	{
		ReplyToCommand(client, "Usage: sm_addpm <steamid> <message>");
		return Plugin_Handled;
	}	
	
	if (strncmp(receiver, "STEAM_", 6) != 0 || receiver[7] != ':')
	{
		ReplyToCommand(client, "[SM] %t", "Invalid SteamID specified");
		return Plugin_Handled;
	}
	
	new safeMessageLen = 2 * strlen(commandLine[len]) + 1;
	
	decl String:safeMessage[safeMessageLen];
	SQL_EscapeString(g_hSQL, commandLine[len], safeMessage, safeMessageLen);
	
	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	new safeNameLen = 2 * strlen(name) + 1;
	
	decl String:safeName[safeNameLen];
	SQL_EscapeString(g_hSQL, name, safeName, safeNameLen);
	
	decl String:query[255];
	Format(query, sizeof(query), "INSERT INTO connect_pm (account_id, message, sender_name) VALUES (%d, '%s', '%s');", GetAccountIDFromAuthString(receiver), safeMessage, safeName);

	SQL_TQuery(g_hSQL, AddPrivateMessageCallback, query, client);
	return Plugin_Handled;
}

public AddPrivateMessageCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on AddPrivateMessageCallback: %s", error);
		return;
	}
	
	PrintToChat(client, "Private message sent successfully.");
}

GetAccountIDFromAuthString(String:authString[])
{
    decl String:toks[3][16];
    ExplodeString(authString, ":", toks, sizeof(toks), sizeof(toks[]));

    new odd = StringToInt(toks[1]);
    new halfAID = StringToInt(toks[2]);

    return (halfAID*2) + odd;
}

GetClientAccountID(client)
{
	decl String:buffer[32];
	GetClientAuthString(client, buffer, sizeof(buffer));
	
	return GetAccountIDFromAuthString(buffer);
}