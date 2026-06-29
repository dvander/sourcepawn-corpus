#include <sourcemod>
#include <sdktools>

#define TAG							"[SM-STATS]"
// Database querys
#define QUERY_INIT_DB_CLIENTS		"CREATE TABLE IF NOT EXISTS `clients` (`clientID` int NOT NULL AUTO_INCREMENT, `steamid` varchar(45) NOT NULL, `date` varchar(10) NOT NULL, PRIMARY KEY (`clientID`))"
#define QUERY_ADD_CLIENT			"INSERT INTO `clients`(`steamid`, `date`) VALUES('%s', '%s')"
#define QUERY_GET_CLIENT			"SELECT * FROM `clients` WHERE `steamid` = '%s' AND `date` = '%s'"
#define QUERY_GET_CLIENTS_IN_MONTH	"SELECT COUNT(*) FROM `clients` WHERE `date` = '%s'"

Database db;

public Plugin myinfo =
{
	name = "Clients tracker",
	description = "Tracks clients monthly (based on SteamID32).",
	author = "ShawnCZek",
	version = "1.0",
	url = "http://steamcommunity.com/id/shawnczek"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_stats_create", CMD_Create, ADMFLAG_ROOT, "sm_stats_create - Creates a table for tracking clients");
	RegAdminCmd("sm_stats_clients", CMD_Clients, ADMFLAG_ROOT, "sm_stats_clients [month-year] - Gets clients in the month");
	
	char error[255];
	db = SQL_DefConnect(error, sizeof(error));
	if (db == null)
	{
		PrintToServer("%s Could not connect: %s", TAG, error);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		char buffer[255];
		char clientId[45];
		char date[10];
		
		// Data
		FormatTime(date, sizeof(date), "%m-%Y");
		GetClientAuthId(client, AuthId_Steam2, clientId, sizeof(clientId));
		// Query
		Format(buffer, sizeof(buffer), QUERY_GET_CLIENT, clientId, date);
		DBResultSet query = SQL_Query(db, buffer);
		if (query == null)
		{
			SQL_GetError(db, buffer, sizeof(buffer));
			PrintToServer("%s Error while getting a client: %s", TAG, buffer);
		}
		else if (query.RowCount == 0)
		{
			Format(buffer, sizeof(buffer), QUERY_ADD_CLIENT, clientId, date);
			if (!SQL_FastQuery(db, buffer))
			{
				SQL_GetError(db, buffer, sizeof(buffer));
				PrintToServer("%s Error while adding a client: %s", TAG, buffer);
			}
		}
	}
}

/**************************************************************************************************************************
													ADMIN COMMANDS
**************************************************************************************************************************/

public Action CMD_Create(int client, int args)
{
	if (SQL_FastQuery(db, QUERY_INIT_DB_CLIENTS))
	{
		ReplyToCommand(client, "%s The table was successfully created", TAG);
	}
	else
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("%s Error while creating the table: %s", TAG, error);
	}
	
	return Plugin_Handled;
}

public Action CMD_Clients(int client, int args)
{
	// Data
	char buffer[255];
	char date[10];
	if (args < 1)
	{
		FormatTime(date, sizeof(date), "%m-%Y");
	}
	else
	{
		GetCmdArg(1, date, sizeof(date));
	}
	
	// Query
	Format(buffer, sizeof(buffer), QUERY_GET_CLIENTS_IN_MONTH, date);
	DBResultSet query = SQL_Query(db, buffer);
	if (query == null)
	{
		SQL_GetError(db, buffer, sizeof(buffer));
		PrintToServer("%s Error while getting clients: %s", TAG, buffer);
	}
	else
	{
		while (SQL_FetchRow(query))
		{
			int count = SQL_FetchInt(query, 0);
			ReplyToCommand(client, "%s Number of clients in month \"%s\": %i", TAG, date, count);
		}
	}
}