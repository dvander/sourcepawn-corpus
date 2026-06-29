/**
 * SQL Feedback plugin by bl4nk
 *
 * Description:
 *   Take client feedback on the server/current map and store it in a SQL database.
 *
 * Commands and Examples:
 *   feedback <map | server> <feedback>
 *     - feedback map this red team has too much of an advantage
 *     - feedback server there needs to be more active admins
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.2a"

new bool:gaveFeedback[MAXPLAYERS + 1];

new Handle:feedbackTimer[MAXPLAYERS +1];
new Handle:hdatabase = INVALID_HANDLE;
new Handle:hQuery = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SQL Feedback",
	author = "bl4nk",
	description = "Take client feedback on the server/current map and store it in a SQL database.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_sqlfeedback_version", PLUGIN_VERSION, "SQL Feedback Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("feedback", Command_Feedback, "feedback <map | server> <feedback>");

	SQL_TConnect(sql_Connected);
}

public Action:Command_Feedback(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: feedback <map | server> <feedback>");
		return Plugin_Handled;
	}

	new String:arguments[255], String:type[32], argLen;
	GetCmdArgString(arguments, sizeof(arguments));

	argLen = BreakString(arguments, type, sizeof(type));

	if (strcmp(type, "map") != 0 && strcmp(type, "server") != 0)
	{
		ReplyToCommand(client, "[SM] Usage: feedback <map | server> <feedback>");
		return Plugin_Handled;
	}

	if (gaveFeedback[client])
	{
		ReplyToCommand(client, "[SM] You can only use this command every 5 seconds!");
		return Plugin_Handled;
	}

	new String:authid[32];
	GetClientAuthString(client, authid, sizeof(authid));

	new String:feedback[255];
	Format(feedback, sizeof(feedback), arguments[argLen]);

	new String:feedbackQ[255], String:clientName[32], String:clientNameQ[65];
	GetClientName(client, clientName, sizeof(clientName));
	SQL_QuoteString(hdatabase, feedback, feedbackQ, sizeof(feedbackQ));
	SQL_QuoteString(hdatabase, clientName, clientNameQ, sizeof(clientNameQ));

	decl String:query[255];
	if (strcmp(type, "map") == 0)
	{
		new String:mapName[32];
		GetCurrentMap(mapName, sizeof(mapName));
		Format(query, sizeof(query), "INSERT INTO feedback_map (name, steamid, map, feedback) VALUES ('%s', '%s', '%s', '%s')", clientNameQ, authid, mapName, feedbackQ);
	}
	else
		Format(query, sizeof(query), "INSERT INTO feedback_server (name, steamid, feedback) VALUES ('%s', '%s', '%s')", clientNameQ, authid, feedbackQ);

	hQuery = CreateDataPack();
	WritePackString(hQuery, query);

	SQL_TQuery(hdatabase, sql_Query, query, hQuery);

	LogMessage("[SQL Feedback] Added feedback from user %N (%s)", client, authid);
	ReplyToCommand(client, "[SM] Thank you for your feedback!");

	gaveFeedback[client] = true;
	feedbackTimer[client] = CreateTimer(5.0, ChangeSpam, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public sql_Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogError("Database failure: %s", error);
	else
		hdatabase = hndl;
}

public sql_Query(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:query[255];
	ResetPack(data);
	ReadPackString(data, query, sizeof(query));
	CloseHandle(data);

	if (hndl == INVALID_HANDLE)
	{
		LogError("Query Failed! %s", error);
		LogError("Query: %s", query);
		return;
	}

	CloseHandle(hndl);
}

public Action:ChangeSpam(Handle:timer, any:client)
{
	gaveFeedback[client] = false;
}