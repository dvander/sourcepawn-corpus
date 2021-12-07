#include <sourcemod>

public Plugin myinfo =
{
    name = "SQL override thing!",
    author = "Miu",
    description = "",
    version = "1.0",
    url = "http://www.sourcemod.net/"
};

Database g_hDB = null;
bool g_bSQLite = true;

public void OnPluginStart()
{
	RegAdminCmd("sm_sql_add_group_override", Command_AddGroupOverride, ADMFLAG_RCON);
	g_hDB = Connect();
}

Database Connect()
{
	char error[255];
	Database db;
	
	if (SQL_CheckConfig("admins"))
	{
		db = SQL_Connect("admins", true, error, sizeof(error));
	} else {
		db = SQL_Connect("default", true, error, sizeof(error));
	}
	
	if (db == null)
	{
		LogError("Could not connect to database: %s", error);
	}
	
	char ident[16];
	db.Driver.GetIdentifier(ident, sizeof(ident));

	if (strcmp(ident, "mysql") == 0)
	{
		g_bSQLite = false;
	} else if (strcmp(ident, "sqlite") == 0) {
		g_bSQLite = true;
	}
	
	return db;
}

public Action Command_AddGroupOverride(int client, int args)
{
	if(args < 3)
	{
		ReplyToCommand(client, "Usage: sm_sql_add_group_override <group_name> <command> <access>");
		return Plugin_Handled;
	}
	
	char type[16], group_name[128], command[128], access[16];
	GetCmdArg(1, group_name, sizeof(group_name));
	GetCmdArg(2, command, sizeof(command));
	GetCmdArg(3, access, sizeof(access));
	
	if(strcmp(access, "allow") && strcmp(access, "deny"))
	{
		ReplyToCommand(client, "Invalid access");
		return Plugin_Handled;
	}
	
	if(command[0] == '@')
	{
		strcopy(type, sizeof(type), "group");
		strcopy(command, sizeof(command), command[1]);
	}
	else
	{
		strcopy(type, sizeof(type), "command");
	}
	
	char query[1024];
	FormatEx(query, sizeof(query), "SELECT id FROM sm_groups WHERE name = '%s'", group_name);
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, GetCmdReplySource());
	WritePackString(hPack, type);
	WritePackString(hPack, command);
	WritePackString(hPack, access);
	SQL_TQuery(g_hDB, SQL_FindGroup_Callback, query, hPack);
	
	return Plugin_Handled;
}

public void SQL_FindGroup_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	char type[16], command[128], access[16];
	ResetPack(data);
	int client = ReadPackCell(data);
	ReplySource src = ReadPackCell(data);
	ReadPackString(data, type, sizeof(type));
	ReadPackString(data, command, sizeof(command));
	ReadPackString(data, access, sizeof(access));
	CloseHandle(data);
	
	if(hndl == null)
	{
		LogError("SQL_FindGroup_Callback: Query failed: %s", error);
		ReplySource osrc = SetCmdReplySource(src);
		ReplyToCommand(client, "SQL_FindGroup_Callback: Query failed: %s", error);
		SetCmdReplySource(osrc);
		return;
	}
	
	if(!SQL_FetchRow(hndl))
	{
		ReplySource osrc = SetCmdReplySource(src);
		ReplyToCommand(client, "Couldn't find group!");
		SetCmdReplySource(osrc);
		return;
	}
	
	int id = SQL_FetchInt(hndl, 0);
	
	char query[1024];
	if(g_bSQLite)
	{
		FormatEx(query, sizeof(query), "INSERT OR REPLACE INTO sm_group_overrides (group_id, type, name, access) VALUES(%d, '%s', '%s', '%s')", id, type, command, access);
	}
	else
	{
		FormatEx(query, sizeof(query), "INSERT INTO sm_group_overrides (group_id, type, name, access) VALUES(%d, '%s', '%s', '%s') ON DUPLICATE KEY UPDATE access = '%s'", id, type, command, access, access);
	}
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, GetCmdReplySource());
	SQL_TQuery(g_hDB, SQL_InsertOverride_Callback, query, hPack);
}

public void SQL_InsertOverride_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	ReplySource src = ReadPackCell(data);
	CloseHandle(data);
	
	ReplySource osrc = SetCmdReplySource(src);
	
	if(hndl == null)
	{
		LogError("SQL_InsertOverride_Callback: Query failed: %s", error);
		ReplyToCommand(client, "SQL_InsertOverride_Callback: Query failed: %s", error);
		SetCmdReplySource(osrc);
		return;
	}
	
	ReplyToCommand(client, "Override added!");
	SetCmdReplySource(osrc);
}