#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define SQLSIZE_MAX 8192
new Handle:db;			/** Database connection */

public Plugin:myinfo = 
{
	name = "SQLQueries",
	author = "Timiditas",
	description = "Dispatch SQL queries via console or even chat",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sql_query", Command_SQL, ReadFlagString("z"), "dispatch sql query");
	RegAdminCmd("sql_connect_sqlite", Command_Connect, ReadFlagString("z"), "connect to local sqlite database");
	RegAdminCmd("sql_connect_section", Command_ConnectSect, ReadFlagString("z"), "connect to db listed in configs/databases.cfg");
	RegAdminCmd("sql_connect_custom", Command_ConnectCust, ReadFlagString("z"), "connect with custom settings");
	RegAdminCmd("sql_disconnect", Command_Disconnect, ReadFlagString("z"), "disconnect");
	CreateConVar("SQLQueries_version", PLUGIN_VERSION, "SQLQueries version string", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
}
public Action:Command_ConnectCust(client,args)
{
	if(args != 6)
	{
		ReplyToCommand(client, "usage: sql_connect_custom <dbtype(sqlite|mysql)> <\"hostname/ip\"> <\"database\"> <\"username\"> <\"password\"> <\"port\">");
		return Plugin_Handled;
	}
	new String:Settings[6][255];
	for(new i=0;i<6;i++)
	{
		GetCmdArg((i+1), Settings[i], 255);
	}
	if(!StrEqual(Settings[0],"sqlite",true) && !StrEqual(Settings[0],"mysql",true))
	{
		ReplyToCommand(client, "<dbtype> must be \"sqlite\" or \"mysql\" , all lowercase");
		return Plugin_Handled;
	}
	new String:error[255],Handle:h_kv = CreateKeyValues("");
	KvSetString(h_kv, "driver",Settings[0]);
	KvSetString(h_kv, "host",Settings[1]);
	KvSetString(h_kv, "database",Settings[2]);
	KvSetString(h_kv, "user",Settings[3]);
	KvSetString(h_kv, "pass",Settings[4]);
	KvSetString(h_kv, "port",Settings[5]);
	if(db != INVALID_HANDLE)
	{
		CloseHandle(db);
		db = INVALID_HANDLE;
	}
	db = SQL_ConnectCustom(h_kv, error, sizeof(error), true);
	CloseHandle(h_kv);
	if (db == INVALID_HANDLE)
	{
		ReplyToCommand(client, "Failed to connect to %s: %s", Settings[1],error);
	}
	else 
	{
		decl String:query[SQLSIZE_MAX];
		Format(query, sizeof(query), "SET NAMES 'utf8'");
		if (!SQL_FastQuery(db, query))
			ReplyToCommand(client, "Can't select character set (%s)", query);
		ReplyToCommand(client, "DatabaseInit *%s* (CONNECTED) with %s", Settings[0], Settings[1]);
		if(StrEqual(Settings[0],"sqlite",false))
		{
			Format(query, sizeof(query), "SELECT SQLITE_VERSION()");
			SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
			Format(query, sizeof(query), "SELECT name as Tables FROM sqlite_master WHERE type='table' ORDER BY name");
			SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
		}
		else
		{
			Format(query, sizeof(query), "select version()");
			SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
			Format(query, sizeof(query), "show tables");
			SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
		}
	}
	return Plugin_Handled;
}

public Action:Command_ConnectSect(client,args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "usage: sql_connect_section <\"databases.cfg section\">");
		return Plugin_Handled;
	}
	decl String:Sect[255];
	GetCmdArg(1,Sect,sizeof(Sect));
	
	if (SQL_CheckConfig(Sect))
	{
		if(db != INVALID_HANDLE)
		{
			CloseHandle(db);
			db = INVALID_HANDLE;
		}
		new String:error[255];
		db = SQL_Connect(Sect,true,error, sizeof(error));
		if (db == INVALID_HANDLE)
		{
			ReplyToCommand(client, "Failed to connect to '%s': %s", Sect, error);
		}
		else 
		{
			decl String:query[SQLSIZE_MAX];
			Format(query, sizeof(query), "SET NAMES 'utf8'");
			if (!SQL_FastQuery(db, query))
				ReplyToCommand(client, "Can't select character set (%s)", query);
			new String:ProdName[255];
			SQL_ReadDriver(db, ProdName, sizeof(ProdName));
			ReplyToCommand(client, "DatabaseInit *%s* (CONNECTED) with db config %s", ProdName, Sect);
			if(StrEqual(ProdName,"sqlite",false))
			{
				Format(query, sizeof(query), "SELECT SQLITE_VERSION()");
				SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
				Format(query, sizeof(query), "SELECT name as Tables FROM sqlite_master WHERE type='table' ORDER BY name");
				SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
			}
			else
			{
				Format(query, sizeof(query), "select version()");
				SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
				Format(query, sizeof(query), "show tables");
				SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
			}
		}
	}
	else
		ReplyToCommand(client, "db section %s not found", Sect);
	return Plugin_Handled;
}
public Action:Command_Disconnect(client,args)
{
	if(db != INVALID_HANDLE)
	{
		CloseHandle(db);
		db = INVALID_HANDLE;
	}
}
public Action:Command_SQL(client, args)
{
	if(db == INVALID_HANDLE)
		ReplyToCommand(client, "No DB connection");
	else
	{
		if(args != 1)
		{
			ReplyToCommand(client, "Encase the sql query with quotation marks");
			return Plugin_Handled;
		}
		decl String:buffer[SQLSIZE_MAX];
		buffer[0] = 0;
		GetCmdArg(1, buffer, sizeof(buffer));
		SQL_TQuery(db, query_callback, buffer, (client != 0)?GetClientUserId(client):0);
	}
	return Plugin_Handled;
}
public Action:Command_Connect(client,args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "usage: sql_connect_sqlite <\"dbname\"> <CreateIfNonExistant - 1|0 - default:0>");
		return Plugin_Handled;
	}
	
	new String:dbname[64], String:Create[64], iCreate = 0;
	GetCmdArg(1, dbname, sizeof(dbname));
	if(args == 2)
	{
		GetCmdArg(2, Create, sizeof(Create));
		iCreate = StringToInt(Create);
	}
	if(iCreate == 0)
	{
		new String:dbPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM,dbPath,sizeof(dbPath),"data/sqlite/%s.sq3",dbname);
		if(!FileExists(dbPath,false))
		{
			ReplyToCommand(client, "Database does not exist. If you want to create it, type: sqlite_connect \"%s\" 1",dbname);
			return Plugin_Handled;
		}
	}

	if(db != INVALID_HANDLE)
	{
		CloseHandle(db);
		db = INVALID_HANDLE;
	}

	new String:error[255];
	new Handle:h_kv = CreateKeyValues("");
	KvSetString(h_kv, "driver", "sqlite");
	KvSetString(h_kv, "database", dbname);
	db = SQL_ConnectCustom(h_kv, error, sizeof(error), true);
	CloseHandle(h_kv);
	if (db == INVALID_HANDLE)
		ReplyToCommand(client, "Failed to create sqlite db connection: %s", error);
	else
	{
		decl String:query[SQLSIZE_MAX];
		Format(query, sizeof(query), "SET NAMES 'utf8'");
		if (!SQL_FastQuery(db, query))
			ReplyToCommand(client, "Can't select character set (%s)", query);
		ReplyToCommand(client, "DatabaseInit SQLLITE (CONNECTED)");
		Format(query, sizeof(query), "SELECT SQLITE_VERSION()");
		SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
		Format(query, sizeof(query), "SELECT name as Tables FROM sqlite_master WHERE type='table' ORDER BY name");
		SQL_TQuery(db, query_callback, query,(client != 0)?GetClientUserId(client):0);
	}
	return Plugin_Handled;
}

public query_callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetClientOfUserId(data);
	
	if (hndl == INVALID_HANDLE)
		ReplyCust(client, "Query failed! %s", error);
	else 
	{
		if(!SQL_HasResultSet(hndl))
			ReplyCust(client,"Affected rows: %i",SQL_GetAffectedRows(db));	//why doesn't hndl work for GetAffectedRows?
		else
		{
			//if (!SQL_GetRowCount(hndl))
			//	ReplyCust(client,"Query didn't produce any matches (0 rows returned)");
			new fcount = (SQL_GetFieldCount(hndl)-1);
			decl String:Buffer[255], String:Output[1024];
			Output[0] = 0;
			for(new i=0;i<=fcount;i++)
			{
				SQL_FieldNumToName(hndl, i, Buffer, sizeof(Buffer));
				StrCat(Output, sizeof(Output), Buffer);
				if(i < fcount)
					StrCat(Output, sizeof(Output), "|");
			}
			ReplyCust(client, Output);
			new Headerlen = strlen(Output);
			for(new i=0;i<Headerlen;i++)
			{
				Output[i] = 45;
			}
			ReplyCust(client, Output);
			while(SQL_FetchRow(hndl))
			{
				Output[0] = 0;
				for(new i=0;i<=fcount;i++)
				{
					new DBResult:Result;
					SQL_FetchString(hndl, i, Buffer, sizeof(Buffer), Result);
					switch(Result)
					{
						case DBVal_Null:
							StrCat(Output, sizeof(Output), "*NULL*");
						case DBVal_Data:
							StrCat(Output, sizeof(Output), Buffer);
						case DBVal_Error:
							StrCat(Output, sizeof(Output), "*INVALID IDX*");
						case DBVal_TypeMismatch:
							StrCat(Output, sizeof(Output), "*TYPE MISMATCH*");
					}
					if(i < fcount)
						StrCat(Output, sizeof(Output), "|");
				}
				ReplyCust(client, Output);
			}
		}
	}
}

ReplyCust(client, String:Reply[], any:...)
{
	decl String:bReply[SQLSIZE_MAX];
	if(client == 0)
		SetGlobalTransTarget(LANG_SERVER);
	else
		SetGlobalTransTarget(client);
	VFormat(bReply, sizeof(bReply), Reply, 3);
	if(client == 0)
		PrintToServer(bReply);
	else
	{
		PrintToConsole(client, bReply);
		PrintToChat(client, bReply);
	}
}
