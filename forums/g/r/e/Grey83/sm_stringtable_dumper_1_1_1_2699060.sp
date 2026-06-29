/*=======================================================================================
	Change Log:

1.1.1 (09-May-2020)
	- Some formatting improvements (indication of the number of strings and numeration in dumps).
	- Empty stringtables will not saved to logfiles.

1.1 (02-Apr-2020)
	- Fixed armument quotation (thanks to Bacardi).

1.0 (01-Feb-2019)
	- Initial release.

=======================================================================================

	Credits:
	 - Dr. Api - for sm string table examples.

=======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sdktools_stringtables>

static const char
	PL_NAME[]	= "[DEV] String Tables Dumper",
	PL_VER[]	= "1.1.1";

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Dumps records of all string tables. For developers.",
	author		= "Alex Dragokas",
	url			= "https://github.com/dragokas/"
}

public void OnPluginStart()
{
	CreateConVar("sm_dump_st_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	RegAdminCmd("sm_dump_st",	Cmd_DumpStringtables,		ADMFLAG_ROOT,	"<Num> (optional). Dumps ALL stringtables to log files. Show list of stringtables to console. Set num to 1 - to dump user data as well");
	RegAdminCmd("sm_dump_sti",	Cmd_DumpStringtableItems,	ADMFLAG_ROOT,	"<table_name>. Show contents of this table to console and dumps it in log file.");
}

public Action Cmd_DumpStringtables(int client, int args)
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "logs/StringTables.log");

	int num = GetNumStringTables();
	File fileh = OpenFile(buffer, "w");
	if(fileh)
	{
		fileh.WriteLine("String table list (%d tables):", num);
		ReplyToCommand(client, "String table list is saved to: %s", buffer);
	}
	else ReplyToCommand(client, "Cannot open file for write access: %s", buffer);

	int i;
	ReplyToCommand(client, "Listing %d stringtables:", num);

	char name[64];
	for(; i < num; i++)
	{
		GetStringTableName(i, name, sizeof(name));
		Format(buffer, sizeof(buffer), "%2d. %s (%d/%d strings)", i, name, GetStringTableNumStrings(i), GetStringTableMaxStrings(i));
		ReplyToCommand(client, buffer);
		if(fileh) fileh.WriteLine(buffer);
	}
	if(fileh) fileh.Close();

	bool dumpUserData;
	if(args)
	{
		char arg[4];
		GetCmdArgString(arg, sizeof(arg));
		dumpUserData = StringToInt(arg) != 0;
	}

	for(i = 0; i < num; i++)
	{
		GetStringTableName(i, name, sizeof(name));
		DumpTable(client, name, dumpUserData);
	}

	return Plugin_Handled;
}

public Action Cmd_DumpStringtableItems(int client, int args)
{
	if(!args)
	{
		ReplyToCommand(client, "Using: sm_dump_sti <string table name>");
		return Plugin_Handled;
	}

	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	DumpTable(client, buffer, false, true);

	return Plugin_Handled;
}

bool DumpTable(int client, char[] name, bool showUserData, bool showCon = false)
{
	int table = FindStringTable(name);
	if(table == INVALID_STRING_TABLE)
	{
		ReplyToCommand(client, "Couldn't find %s stringtable.", name);
		return false;
	}

	int num = GetStringTableNumStrings(table);
	if(!num)
	{
		ReplyToCommand(client, "Empty %s stringtable.", name);
		return false;
	}

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "logs/StringTable_%s.log", name);

	File fileh = OpenFile(path, "w");
	if(!fileh)
	{
		ReplyToCommand(client, "Cannot open file for write access: %s", path);
		if(!showCon) return false;
	}
	else fileh.WriteLine("Contents of string table \"%s\" (%d strings):", name, num);

	char str[PLATFORM_MAX_PATH], user_data[PLATFORM_MAX_PATH], format[16];
	if(num < 10)
		format = showUserData ?  "%d. %s (%s)" :  "%d. %s";
	else if(num < 100)
		format = showUserData ? "%2d. %s (%s)" : "%2d. %s";
	else if(num < 1000)
		format = showUserData ? "%3d. %s (%s)" : "%3d. %s";
	else
		format = showUserData ? "%4d. %s (%s)" : "%4d. %s";

	for(int i; i < num;)
	{
		ReadStringTable(table, i++, str, sizeof(str));
		if(showUserData)
		{
			if(!GetStringTableData(table, i, user_data, sizeof(user_data)))
				user_data[0] = 0;

			if(showCon)	ReplyToCommand(client, format, i, str, user_data);
			if(fileh)	fileh.WriteLine(format, i, str, user_data);
		}
		else
		{
			if(showCon)	ReplyToCommand(client, format, i, str);
			if(fileh)	fileh.WriteLine(format, i, str);
		}
	}

	if(fileh)
	{
		fileh.Close();
		ReplyToCommand(client, "Dump is saved to: %s", path);
	}
	return true;
}