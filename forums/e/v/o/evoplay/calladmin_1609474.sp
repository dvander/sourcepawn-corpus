#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.0.0"
#define CALLADMIN_USAGE "sm_calladmin <message> - Call admins from other servers"

new g_Port;

new Handle:g_DB;
new Handle:g_VersionCvar;


public Plugin:myinfo = 
{
	name = "Call Admin",
	author = "danfocus",
	description = "Call admins from other servers.",
	version = VERSION,
	url = "http://www.evolution-game.ru"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations ("calladmin.phrases");
	
	g_VersionCvar = CreateConVar("calladmin_version", VERSION, "", FCVAR_NOTIFY);
	//RegConsoleCmd("sm_calladmin", OnCallAdminCmd, "sm_calladmin <message>");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("team_say", Command_Say);
	
	GetCurrentPort();
	
	SQL_TConnect(OnDatabaseConnected, "calladmin");
}

public GetCurrentPort()
{
	new Handle:cvar_port = FindConVar("hostport");
	g_Port = GetConVarInt(cvar_port);
	CloseHandle(cvar_port);
}

public OnMapStart()
{
	// hax against valvefail
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_VersionCvar, VERSION);
	CreateTimer(30.0, CheckMessages, _, TIMER_REPEAT);
}

public OnClientPutInServer (client)
{
	if ((client == 0) || g_DB == INVALID_HANDLE || !IsClientConnected (client))
	    return;
	
	CreateTimer (40.0, WelcomeAdvertTimer, client);
}

public Action:WelcomeAdvertTimer (Handle:timer, any:client)
{
	if (IsClientConnected (client) && IsClientInGame (client))
	{
		PrintToChat (client, "\x04[CallAdmin]\x01 %T", "CallAdmin Command Info", client);
	}
	return Plugin_Stop;
}

public OnDatabaseConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		SetFailState("Failed to connect to calladmin db, %s", error);
	g_DB = hndl;
}

public Action:CheckMessages (Handle:timer, any:data)
{
	decl String:query[1024];
	FormatEx(query, sizeof(query), "UPDATE calls SET accepted = 2 WHERE accepted = 0 AND servers_port = %d", g_Port);
	SQL_TQuery(g_DB, OnQueryExec, query, 0, DBPrio_High);
	FormatEx(query, sizeof(query), "SELECT userName,userId,message,date,(SELECT servers.name FROM servers WHERE servers.port = calls.fromPort) FROM calls WHERE servers_port = %d AND accepted = 2", g_Port);
	SQL_TQuery(g_DB, OnCheckMessages, query, 0, DBPrio_High);
	FormatEx(query, sizeof(query), "UPDATE calls SET accepted = 1 WHERE accepted = 2 AND servers_port = %d", g_Port);
	SQL_TQuery(g_DB, OnQueryExec, query, 0, DBPrio_High);
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	if (g_DB == INVALID_HANDLE)
	{
		//ReplyToCommand(client, "Error: database not ready.");
		return Plugin_Handled;
	}
	
	new String:message[512];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	TrimString(message);
	
	new String:message2[12];
	strcopy(message2, 11, message);
	message2[11] = '\0';
	
	if (StrEqual(message2,"!calladmin",false))
	{
	    ReplaceString(message, sizeof(message), "!calladmin", "", false);
	    StripQuotes(message);
	    TrimString(message);
	    
	    ProcessCall(client, message);
	    
	    return Plugin_Handled;
	}
	return Plugin_Continue;
}

/*
public Action:OnCallAdminCmd(client, args)
{
	if (g_DB == INVALID_HANDLE)
	{
		ReplyToCommand(client, "Error: database not ready.");
		return Plugin_Handled;
	}
	
	new String:message[512];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	TrimString(message);

	ProcessCall(client,message);
	
	return Plugin_Handled;
}
*/

public ProcessCall(client, const String:message[])
{
	//if (g_DB == INVALID_HANDLE)
	//{
	//	ReplyToCommand(client, "Error: database not ready.");
	//	return false;
	//}
	
	new String:auth[32];
	new String:clientName[MAX_NAME_LENGTH];
	new String:ip[30];
	if (client != 0)
	{
		GetClientAuthString(client, auth, sizeof(auth));
		GetClientName(client, clientName, sizeof(clientName));
		GetClientIP(client, ip, sizeof(ip));
	} else {
		strcopy(auth, sizeof(auth), "NONE");
		strcopy(clientName, sizeof(clientName), "CONSOLE");
		strcopy(ip, sizeof(ip), "NONE");
	}
	
	decl String:query[1024];
	FormatEx(query, sizeof(query), "INSERT INTO calls (userName, userId, userIp, message, fromPort, servers_port) SELECT '%s','%s','%s','%s',%d,servers.port FROM servers WHERE servers.port != %d", clientName, auth, ip, message, g_Port, g_Port);
	
	SQL_TQuery(g_DB, OnQueryExec, query, DBPrio_High);
	
	//ReplyToCommand(client, "\x04[CallAdmin]\x01 Admin's called from other servers.");
	ReplyToCommand(client, "\x04[CallAdmin]\x01 %T", "Admins called", client);
	
	return true;
}

public OnQueryExec(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[CallAdmin] DB error while execute request:\n%s", error);
		return;
	}
	CloseHandle(hndl);
}

public OnCheckMessages(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[CallAdmin] DB error while retrieving calls:\n%s", error);
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 0)
	{
		//PrintToServer("[CallAdmin] No calls in this time.");
		CloseHandle(hndl);
		return;
	}
	
	while (SQL_FetchRow(hndl))
	{
		new String:auth[32];
		new String:clientName[MAX_NAME_LENGTH];
		//new String:ip[30];
		new String:message[512];
		new String:createddate[30];
		new String:serverName[30];

		SQL_FetchString(hndl, 0, clientName, sizeof(clientName));
		SQL_FetchString(hndl, 1, auth, sizeof(auth));
		//SQL_FetchString(hndl, 2, ip, sizeof(ip));
		SQL_FetchString(hndl, 2, message, sizeof(message));
		SQL_FetchString(hndl, 3, createddate, sizeof(createddate));
		//FormatTime(createddate, sizeof(createddate), "%Y-%m-%d", SQL_FetchInt(hndl, 4));
		SQL_FetchString(hndl, 4, serverName, sizeof(serverName));
		
		//PrintToServer("%s | %s | Message from %s[%s] - '%s'", createddate, serverName, clientName, auth, message);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
		{
			PrintToChat(i, "\x04[CallAdmin]\x01 %s | %s | %s[%s]: %s", createddate, serverName, clientName, auth, message);
		}
	}

	}
	CloseHandle(hndl);
}
