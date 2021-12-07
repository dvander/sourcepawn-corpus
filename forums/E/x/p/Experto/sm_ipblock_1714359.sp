#pragma semicolon 1
#include <sourcemod>
#include <sdktools>



#define PLUGIN_VERSION "1.0.0"



public Plugin:myinfo = 
{
    name = "IP Block",
    author = "Experto",
    description = "Blocks players with the same IP",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net"
};



new Handle:ipbEnable = INVALID_HANDLE;
new Handle:ipbMaxClient = INVALID_HANDLE;
new Handle:DB_IPBLOCK = INVALID_HANDLE;



RegisterCvars()
{
	CreateConVar("sm_ipblock_version", PLUGIN_VERSION, "IP Block", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ipbEnable = CreateConVar("sm_ipblock_enable", "1", "Enables/Disables the plugin. [0 = Disabled, 1 = Enabled]", _, true, 0.0, true, 1.0);
	ipbMaxClient = CreateConVar("sm_ipblock_maxip", "1", "MAX amount of players with the same ip", _, true, 1.0);
}



public OnPluginStart()
{
	RegisterCvars();

	RegAdminCmd("sm_ipblock_exception_add", ExceptionAdd, ADMFLAG_BAN, "Adds an IP to the exceptions list");
	RegAdminCmd("sm_ipblock_exception_del", ExceptionRemove, ADMFLAG_BAN, "Removes an IP from the exceptions list");
	RegAdminCmd("sm_ipblock_exception_list", ExceptionList, ADMFLAG_BAN, "Displays exceptions list");

	AutoExecConfig(true, "sm_ipblock");

	LoadTranslations("ipblock.phrases");

	ConnectDB();

	PrintToServer("IP Block ON");
}



public OnClientPostAdminCheck(client)
{
	decl String:ipClientConnect[16];
	decl String:ipClientInGame[16];

	GetClientIP(client, ipClientConnect, sizeof(ipClientConnect));

	if (GetConVarBool(ipbEnable))
	{
		new maxIP;
		new maxClient = GetExceptionById(client);

		if (maxClient >= 0)
		{
			maxIP = maxClient;
		}
		else
		{
			maxIP = GetConVarInt(ipbMaxClient);
		}

		new nIP = 0;

		for(new clientInGame = 1; clientInGame <= MaxClients; clientInGame++)
		{
			if (IsClientInGame(clientInGame))
			{
				GetClientIP(clientInGame, ipClientInGame, sizeof(ipClientInGame));
				if (StrEqual(ipClientConnect,ipClientInGame))
				{
					nIP++;
				}
			}
		}

		if (nIP > maxIP)
		{
			KickClient(client, "%t", "max_players_reached", maxIP);
		}
	}
}



ConnectDB()
{
	new String:error[255];

	DB_IPBLOCK = SQLite_UseDatabase("ipblock", error, sizeof(error));

	if (DB_IPBLOCK == INVALID_HANDLE)
	{
		SetFailState("SQL error: %s", error);
	}

	SQL_LockDatabase(DB_IPBLOCK);

	SQL_FastQuery(DB_IPBLOCK, "CREATE TABLE IF NOT EXISTS ipblock_exceptions (ip TEXT, maxClient NUMERIC)");

	SQL_FastQuery(DB_IPBLOCK, "CREATE UNIQUE INDEX IF NOT EXISTS pk_ipblock_ip ON ipblock_exceptions(ip ASC)");

	SQL_UnlockDatabase(DB_IPBLOCK);
}




public Action:ExceptionAdd(client, args) 
{
	if (args < 2)
	{
		ReplyToCommand(client, "[IpBlock] Usage: sm_ipblock_exception_add <ip> <maxClient>");
		return Plugin_Handled;
	}

	decl String:params[54];
	GetCmdArgString(params, sizeof(params));

	decl String:ip[16];
	decl String:argMaxClient[3];

	new len = BreakString(params, ip, sizeof(ip));
	BreakString(params[len], argMaxClient, sizeof(argMaxClient));


	new maxClient;
	maxClient = StringToInt(argMaxClient);

	if (maxClient < 0)
	{
		ReplyToCommand(client, "[IpBlock] %t", "invalid_number");
		return Plugin_Handled;
	}


	decl String:query[200];

	Format(query, sizeof(query), "INSERT INTO ipblock_exceptions(ip, maxClient) VALUES ('%s', %d);", ip, maxClient);

	if (SQL_FastQuery(DB_IPBLOCK, query))
	{
		ReplyToCommand(client, "[IpBlock] %t", "exception_add_success");
	}
	else
	{
		ReplyToCommand(client, "[IpBlock] %t", "exception_add_error");
	}

	return Plugin_Handled;
} 



public Action:ExceptionRemove(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[IpBlock] Usage: sm_ipblock_exception_del <ip>");
		return Plugin_Handled;
	}

	decl String:params[54];
	GetCmdArgString(params, sizeof(params));

	decl String:ip[16];
	BreakString(params, ip, sizeof(ip));

	decl String:query[200];
	Format(query, sizeof(query), "DELETE FROM ipblock_exceptions WHERE ip = '%s';", ip);

	if (SQL_FastQuery(DB_IPBLOCK, query))
	{
		ReplyToCommand(client, "[IpBlock] %t", "exception_del_success");
	}
	else
	{
		ReplyToCommand(client, "[IpBlock] %t", "exception_del_error");
	}

	return Plugin_Handled;
}



GetExceptionById(client)
{
	new maxClient = -1;

	if(IsClientInGame(client))
	{
		decl String:ip[16];
		GetClientIP(client, ip, sizeof(ip));

		new String:query[200];
		Format(query, sizeof(query), "SELECT maxClient FROM ipblock_exceptions WHERE ip = '%s'", ip);
	 
		new Handle:hQuery = SQL_Query(DB_IPBLOCK, query);

		if (hQuery != INVALID_HANDLE)
		{
			if  (SQL_FetchRow(hQuery))
			{
				maxClient = SQL_FetchInt(hQuery,0);
			}
			CloseHandle(hQuery);
			hQuery = INVALID_HANDLE;
		}
		else
		{
			PrintToServer("[IpBlock] ERROR: Could not perform query of exceptions...");
		}
	}

	return maxClient;
}



public Action:ExceptionList(client, args)
{
	new String:query[200];

	if (args < 1)
	{
		Format(query, sizeof(query), "SELECT ip, maxClient FROM ipblock_exceptions");
	}
	else
	{
		decl String:params[54];
		GetCmdArgString(params, sizeof(params));

		decl String:argIp[16];
		BreakString(params, argIp, sizeof(argIp));

		Format(query, sizeof(query), "SELECT ip, maxClient FROM ipblock_exceptions WHERE ip = '%s'", argIp);
	}

	new Handle:hQuery = SQL_Query(DB_IPBLOCK, query);

	if (hQuery != INVALID_HANDLE)
	{

		ReplyToCommand(client, "[IpBlock] IP / Max Client");
		ReplyToCommand(client, "-----------------------------------------------------");

		while (SQL_FetchRow(hQuery))
		{
			decl String:ip[16];
			SQL_FetchString(hQuery, 0, ip, sizeof(ip));

			new maxClient;
			maxClient = SQL_FetchInt(hQuery,1);

			ReplyToCommand(client, "[IpBlock] %s / %d", ip, maxClient);
		}

		ReplyToCommand(client, "-----------------------------------------------------");

		CloseHandle(hQuery);
		hQuery = INVALID_HANDLE;
	}
	else
	{
		PrintToServer("[IpBlock] ERROR: Could not perform query the list of immunity...");
	}

	return Plugin_Handled;
}