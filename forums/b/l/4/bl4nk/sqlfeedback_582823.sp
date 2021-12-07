#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2.0"

new bool:g_bGaveFeedback[MAXPLAYERS + 1];
new Handle:g_hDatabase = INVALID_HANDLE;

new String:g_sServerInfo[3][32];

public Plugin:myinfo =
{
	name = "SQL Feedback",
	author = "bl4nk",
	description = "Take client feedback and store it in a MySQL database.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_sqlfeedback_version", PLUGIN_VERSION, "SQL Feedback Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("feedback", Command_Feedback, "feedback <text>");

	GetConVarString(FindConVar("ip"), g_sServerInfo[0], sizeof(g_sServerInfo[]));
	GetConVarString(FindConVar("hostport"), g_sServerInfo[1], sizeof(g_sServerInfo[]));
	GetGameFolderName(g_sServerInfo[2], sizeof(g_sServerInfo[]));

	SQL_TConnect(sql_Connected);
}

public OnClientPutInServer(client)
{
	g_bGaveFeedback[client] = false;
}

public Action:Command_Feedback(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: feedback <text>");
		return Plugin_Handled;
	}

	if (g_bGaveFeedback[client])
	{
		ReplyToCommand(client, "[SM] You can only use this command every 5 seconds!");
		return Plugin_Handled;
	}

	decl String:sText[255], String:sText_Escaped[255],
	     String:sClientName[32], String:sClientName_Escaped[65],
		 String:sAuth[32], String:sMapName[32];

	GetCmdArgString(sText, sizeof(sText));
	GetClientName(client, sClientName, sizeof(sClientName));

	SQL_EscapeString(g_hDatabase, sText, sText_Escaped, sizeof(sText_Escaped));
	SQL_EscapeString(g_hDatabase, sClientName, sClientName_Escaped, sizeof(sClientName_Escaped));

	GetClientAuthString(client, sAuth, sizeof(sAuth));
	GetCurrentMap(sMapName, sizeof(sMapName));

	decl String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "INSERT INTO feedback (name, steamid, map, serverip, serverport, game, feedback) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s')", sClientName_Escaped, sAuth, sMapName, g_sServerInfo[0], g_sServerInfo[1], g_sServerInfo[2], sText_Escaped);

	new Handle:hQuery = CreateDataPack();
	WritePackString(hQuery, sQuery);

	SendQuery(sQuery);

	LogMessage("[SQL Feedback] Added feedback from user %N (%s)", client, sAuth);
	ReplyToCommand(client, "[SM] Thank you for your feedback!");

	g_bGaveFeedback[client] = true;
	CreateTimer(5.0, Timer_ChangeSpam, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action:Timer_ChangeSpam(Handle:timer, any:client)
{
	g_bGaveFeedback[client] = false;
}

public sql_Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Database failure: %s", error);
	}
	else
	{
		g_hDatabase = hndl;
	}

	CreateTables();
	SendQuery("SET NAMES 'utf8'");
}

public sql_Query(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		ResetPack(data);

		decl String:query[512];
		ReadPackString(data, query, sizeof(query));


		LogError("Query Failed! %s", error);
		LogError("Query: %s", query);
	}

	CloseHandle(data);
}

SendQuery(String:query[])
{
	new Handle:dp = CreateDataPack();
	WritePackString(dp, query);
	SQL_TQuery(g_hDatabase, sql_Query, query, dp);
}

CreateTables()
{
	static String:sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `feedback` ( \
		  `id` int(11) NOT NULL AUTO_INCREMENT, \
		  `name` varchar(65) NOT NULL, \
		  `steamid` varchar(32) NOT NULL, \
		  `map` varchar(32) NOT NULL, \
		  `serverip` varchar(16) NOT NULL, \
		  `serverport` varchar(6) NOT NULL, \
		  `game` varchar(32) NOT NULL, \
		  `feedback` varchar(255) NOT NULL, \
		  `date` timestamp NOT NULL default CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`id`) \
		) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;";

	SendQuery(sQuery);
}