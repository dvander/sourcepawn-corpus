#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.1"

new Handle:Database;

public Plugin:myinfo =
{
	name = "Player's birthday",
	author = "Luki",
	description = "This plugin automaticaly runs command when player have birthday!",
	version = PLUGIN_VERSION,
	url = "none",
}

new String:TablePrefix[32];
new Handle:hTablePrefix;
new Handle:hShowInfo;
new Handle:hAdmFlag;

public OnPluginStart()
{
	RegConsoleCmd("sm_birthday", Command_Birthday, "");
	
	CreateConVar("sm_birthday_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hTablePrefix = CreateConVar("sm_birthday_tableprefix", "", "");
	if (hTablePrefix != INVALID_HANDLE)
	{
		HookConVarChange(hTablePrefix, OnTablePrefixChange);
	}
	
	hAdmFlag = CreateConVar("sm_birthday_flags", "", "");
	
	hShowInfo = CreateConVar("sm_birthday_showinfo", "120", "", _, true, 0.0);
	if (hShowInfo != INVALID_HANDLE)
	{
		PrintMsg(INVALID_HANDLE);
		HookConVarChange(hShowInfo, OnShowInfoChange);
	}
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	ConnectToDatabase();
}

public OnShowInfoChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (GetConVarInt(hShowInfo) > 0)
	{
		CreateTimer(GetConVarFloat(hShowInfo), PrintMsg);
	}
}

public Action:PrintMsg(Handle:timer)
{
	CPrintToChatAll("{green}Type {lightgreen}/birthday <day> <month> {green}in chat to set your birthday date!");
	if (GetConVarInt(hShowInfo) > 0)
	{
		CreateTimer(GetConVarFloat(hShowInfo), PrintMsg)
	}
	return Plugin_Continue;
}
	
public OnTablePrefixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(hTablePrefix, TablePrefix, sizeof(TablePrefix));
}

public OnClientPostAdminCheck(client)
{
	CheckBirthday(client, "C");
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	new UserID;
	UserID = GetEventInt(event, "userid");
	client = GetClientOfUserId(UserID);
	if (IsPlayerAlive(client))
	{
		CheckBirthday(client, "S");
	}
	return Plugin_Continue;
}

public CheckBirthday(client, String:type[])
{
	new String:qCheckBirthday[255];
	new Handle:query;
	new String:SID[128];
	GetClientAuthString(client, SID, sizeof(SID));
	new day;
	new month;
	
	Format(qCheckBirthday, sizeof(qCheckBirthday), "SELECT day, month FROM %sbirthday WHERE steamid = '%s';", TablePrefix, SID);
	query = SQL_Query(Database, qCheckBirthday);
	if(query == INVALID_HANDLE)
	{
		return;
	}
	else
	{
		SQL_FetchRow(query);
		day = SQL_FetchInt(query, 0);
		month = SQL_FetchInt(query, 1);
		CloseHandle(query);
	}
	
	new String:sNow[10];
	FormatTime(sNow, sizeof(sNow), "%d-%m", GetTime());
	new String:sBirthday[10];
	Format(sBirthday, sizeof(sBirthday), "%i-%i", day, month);
	
	if(strcmp(sNow, sBirthday) == 0)
	{
		ExecuteBirthday(client, type);
	}
	
	return;
}

public ExecuteBirthday(client, String:type[])
{
	new Handle:kv = CreateKeyValues("birthday");
	new String:sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "configs/birthday.txt");
	FileToKeyValues(kv, sFilePath);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	
	do
	{
		new String:sCommand[255];
		new String:sDelay[10];
		new String:sType[5];
		new iDelay;
		KvGetString(kv, "command", sCommand, sizeof(sCommand));
		KvGetString(kv, "delay", sDelay, sizeof(sDelay));
		KvGetString(kv, "type", sType, sizeof(sType));
		iDelay = StringToInt(sDelay);
		
		new String:tmp[255];
		
		if (StrContains(sCommand, "@") != -1)
		{
			GetClientName(client, tmp, sizeof(tmp));
			Format(tmp, sizeof(tmp), "\"%s\"", tmp);
			ReplaceString(sCommand, sizeof(sCommand), "@", tmp);
		}
		if (StrContains(sCommand, "#") != -1)
		{
			GetClientName(client, tmp, sizeof(tmp));
			ReplaceString(sCommand, sizeof(sCommand), "#", tmp);
		}		
		
		if ((StrContains(sType, "C") != -1) & ((StrContains(type, "A") != -1) | (StrContains(type, "C") != -1)))
		{
			new Handle:pack;
			CreateDataTimer(float(iDelay), ExecuteTimer, pack);
			WritePackString(pack, sCommand);
		}
		else if ((StrContains(sType, "S") != -1) & ((StrContains(type, "A") != -1) | (StrContains(type, "S") != -1)))
		{
			new Handle:pack;
			CreateDataTimer(float(iDelay), ExecuteTimer, pack);
			WritePackString(pack, sCommand);
		}
		
	} while (KvGotoNextKey(kv));

	CloseHandle(kv);
}

public Action:ExecuteTimer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new String:command[255];
	ReadPackString(pack, command, sizeof(command));
	ServerCommand(command);
}

public ConnectToDatabase()
{
	new String:error[255];
	
	Database = SQL_DefConnect(error, sizeof(error));
	
	if (Database == INVALID_HANDLE)
	{
		PrintToServer("Could not connect: %s", error)
	}
	else
	{
		CreateTables();
	}
}

public CreateTables()
{
	new String:qCreateTables[255];
	
	Format(qCreateTables, sizeof(qCreateTables), "CREATE TABLE IF NOT EXISTS %sbirthday (steamid VARCHAR(32), day INTEGER, month INTEGER);", TablePrefix);
	
	new Handle:query = SQL_Query(Database, qCreateTables)
	if(query == INVALID_HANDLE)
	{
		PrintToServer("[BIRTHDAY] Failed to create tables!");
	}
}

stock bool:IsAdmin(client, const String:flags[])
{
	new bits = GetUserFlagBits(client);	
	if (bits & ADMFLAG_ROOT)
		return true;
	new iFlags = ReadFlagString(flags);
	if (bits & iFlags)
		return true;	
	return false;
}

public Action:Command_Birthday(client, args)
{
	new String:Flags[32];
	GetConVarString(hAdmFlag, Flags, sizeof(Flags));
	
	if (!IsAdmin(client, Flags) & strcmp(Flags, "") != 0)
	{
		ReplyToCommand(client, "[SM] You do not have access to this command");
		return Plugin_Handled;
	}

	new String:arg1[32], String:arg2[32]

	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_birthday <day> <month>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	
	if (((StringToInt(arg1) > 31) | (StringToInt(arg1) < 1)) |
		((StringToInt(arg2) > 12) | (StringToInt(arg2) < 1)))
	{
		ReplyToCommand(client, "Incorrect day or month!");
		return Plugin_Handled;
	}
	
	if(CheckPlayer(client))
	{
		SetBirthDay(client, StringToInt(arg1), StringToInt(arg2));
		ReplyToCommand(client, "Done.");
	}
	else
	{
		ReplyToCommand(client, "You cannot set new birthday date!");
	}

	return Plugin_Handled;
}

bool:CheckPlayer(client)
{
	new String:qCheckPlayer[255];
	new String:SID[128];
	
	GetClientAuthString(client, SID, sizeof(SID));
	
	Format(qCheckPlayer, sizeof(qCheckPlayer), "SELECT '%s' FROM %sbirthday WHERE steamid = '%s';", SID, TablePrefix, SID);
	
	new Handle:query = SQL_Query(Database, qCheckPlayer);
	if(query == INVALID_HANDLE)
	{
		return false;
	}
	else
	{
		if (SQL_GetRowCount(query) == 0)
		{
			CloseHandle(query);
			return true;
		}
		CloseHandle(query)
	}
	
	return false;
}

public SetBirthDay(client, day, month)
{
	new String:qSetBirthDay[255];
	new String:SID[128];
	
	GetClientAuthString(client, SID, sizeof(SID));
	
	Format(qSetBirthDay, sizeof(qSetBirthDay), "INSERT INTO %sbirthday (steamid, day, month) VALUES ('%s', '%i', '%i');", TablePrefix, SID, day, month);

	SQL_FastQuery(Database, qSetBirthDay);

	return;
}