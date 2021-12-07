#include <sourcemod>
#include "dbi.inc"
#include <sdktools>

#define PLUGIN_VERSION "0.2"

public Plugin:myinfo = 
{
	name = "Registered Nicks",
	author = "Dmustanger",
	description = "Lets players register there nicknames.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=84522"
}

new Handle:Database = INVALID_HANDLE;
new Handle:CVar_rn_debug = INVALID_HANDLE;
new Handle:CVar_rn_use_ip = INVALID_HANDLE;
new String:logFile[1024];
new bool:rlogsenabled = false;
new bool:useip = false;

public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/Registered_Nicks.log");
	CreateConVar("registered_nicks_version", PLUGIN_VERSION, "Registered_Nicks version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SQL_TConnect(GotDatabase, "Registered_Nicks");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	if ( !HookEventEx("player_changename", EventNameChange) )
	{
		LogToFile(logFile, "Unable to hook player_changename");
	}
	CVar_rn_debug = CreateConVar("rn_debug_enabled", "0", "loging.");
	CVar_rn_use_ip = CreateConVar("rn_use_ip", "0", "Uses ip instead of steamid.");
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed GotDatabase Could not connect to the Database: %s", error);
	}
	else 
	{
		Database = hndl;
		InsertDB();
		LogToFile(logFile, "Connected to database");
	}	
}

InsertDB()
{
	decl String:driver[64];
	SQL_ReadDriver(Database, driver, sizeof(driver));
	decl String:query[1024];
	if(strcmp(driver, "sqlite", false) == 0)
	{
		query = "CREATE TABLE IF NOT EXISTS Registered_Nicks ( \
					ingamenick TEXT NOT NULL, \
					steam TEXT PRIMARY KEY ON CONFLICT REPLACE);";
	}
	else
	{
		query = "CREATE TABLE IF NOT EXISTS Registered_Nicks ( \
					ingamenick VARCHAR(50) NOT NULL , \
					steam VARCHAR(50) NOT NULL , \
				 PRIMARY KEY (steam) ) \
				 ENGINE = InnoDB;";
	}			
	SQL_TQuery(Database, T_Generic, query);	
}

public T_Generic(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_generic: %s", error);
	}
}

public OnMapStart()
{
	if (GetConVarInt(CVar_rn_debug) == 1)
	{
		rlogsenabled = true;
	}
	if (GetConVarInt(CVar_rn_use_ip) == 1)
	{
		useip = true;
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	decl String:name[50];
	decl String:q_name[101];
	decl String:query[256];
	GetClientName(client, name, sizeof(name));
	SQL_EscapeString(Database, name, q_name, sizeof(q_name));
	Format(query, sizeof(query), "SELECT * FROM Registered_Nicks WHERE ingamenick = '%s'", name);
	SQL_TQuery(Database, T_CheckName, query, client);
	if(rlogsenabled)
	{
		LogToFile(logFile, "Checking data base for %s", name);
	}
}

public T_CheckName(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_CheckName: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{	
		decl String:name[50];
		GetClientName(data, name, sizeof(name));
		if(rlogsenabled)
		{
			LogToFile(logFile, "The name %s was found", name);
		}
		decl String:steam[100];
		decl String:s_steam[201];
		if(useip)
		{
			GetClientIP(data, steam, sizeof(steam));
		}
		else
		{
			GetClientAuthString(data, steam, sizeof(steam));
		}
		if(rlogsenabled)
		{
			LogToFile(logFile, "Checking to make sure %s can have nick %s", steam, name);
		}
		SQL_FetchString(hndl, 1, s_steam, sizeof(s_steam));
		if (StrEqual(steam, s_steam) == false)
		{
			CreateTimer(10.0, ChangeName, data);
			if(rlogsenabled)
			{
				LogToFile(logFile, "Changing %s name in 10 sec", steam);
			}
		}
		else
		{
			if(rlogsenabled)
			{
				LogToFile(logFile, "%s has access to have the nick %s", steam, name);
			}
		}
	}
}

public Action:ChangeName(Handle:timer, any:data)
{
	//SetClientInfo(data, "name", "Registered_Name");
	ClientCommand(data, "name \"%s\"", "Registered_Name");
	if(rlogsenabled)
	{
		decl String:name[50];
		decl String:steam[100];
		GetClientName(data, name, sizeof(name));
		if(useip)
		{
			GetClientIP(data, steam, sizeof(steam));
		}
		else
		{
			GetClientAuthString(data, steam, sizeof(steam));
		}
		LogToFile(logFile, "Changing %s name from %s to Registered_Name", steam, name);
	}
}

public Action:Command_Say(client, args)
{
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	if (strcmp(text[startidx], "register", false) == 0)
	{
		C_Register(client);
	}
	return Plugin_Continue;
}

public C_Register(client)
{
	decl String:steam[100];
	decl String:q_steam[201];
	decl String:query[256];
	if(useip)
	{
		GetClientIP(client, steam, sizeof(steam));
	}
	else
	{
		GetClientAuthString(client, steam, sizeof(steam));
	}
	if(rlogsenabled)
	{
		LogToFile(logFile, "%s wants to register his nickname", steam);
	}
	SQL_EscapeString(Database, steam, q_steam, sizeof(q_steam));
	Format(query, sizeof(query), "SELECT * FROM Registered_Nicks WHERE steam = '%s'", q_steam);
	SQL_TQuery(Database, T_C_Register, query, client);
	if(rlogsenabled)
	{
		LogToFile(logFile, "Checking to see if %s has already registered", steam);
	}
}

public T_C_Register(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_C_Register: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{
		decl String:r_nick[101];
		SQL_FetchString(hndl, 0, r_nick, sizeof(r_nick));
		PrintToChat(client, "You already registered %s as a nickname", r_nick);
		if(rlogsenabled)
		{
			decl String:steam[100];
			if(useip)
			{
				GetClientIP(client, steam, sizeof(steam));
			}
			else
			{
				GetClientAuthString(client, steam, sizeof(steam));
			}
			LogToFile(logFile, "%s already registered with %s", steam, r_nick);
		}
	}
	else
	{
		RegisterNick(client);
	}
}
	
public RegisterNick(client)
{	
	decl String:name[50];
	decl String:q_name[50];
	decl String:steam[100];
	decl String:q_steam[100];
	decl String:query[256];
	GetClientName(client, name, sizeof(name));
	SQL_EscapeString(Database, name, q_name, sizeof(q_name));
	if(useip)
	{
		GetClientIP(client, steam, sizeof(steam));
	}
	else
	{
		GetClientAuthString(client, steam, sizeof(steam));
	}
	SQL_EscapeString(Database, steam, q_steam, sizeof(q_steam));
	Format(query, sizeof(query), "INSERT INTO Registered_Nicks (ingamenick, steam) VALUES ('%s', '%s')", q_name, q_steam);
	SQL_TQuery(Database, T_RegisterNick, query, client);
	if(rlogsenabled)
	{
		LogToFile(logFile, "Adding %s to the database with nickname %s", q_steam, q_name);
	}
}

public T_RegisterNick(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE) 
	{
		LogToFile(logFile, "Query Failed T_AddWatch: %s", error);
		PrintToChat(data, "Unable to register nickname: %s", error);		
	}
	PrintToChat(data, "Successfully registered nickname");
	if(rlogsenabled)
	{
		decl String:steam[100];
		decl String:name[50];
		if(useip)
		{
			GetClientIP(data, steam, sizeof(steam));
		}
		else
		{
			GetClientAuthString(data, steam, sizeof(steam));
		}
		GetClientName(data, name, sizeof(name));
		LogToFile(logFile, "%s successfully registered nickname %s", steam, name);
	}
}

public EventNameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !client || !IsClientConnected(client) || IsClientInKickQueue(client) || IsFakeClient(client) )
	{
		return;
	}
	decl String:newName[64];
	decl String:q_newName[130];
	decl String:query[256];
	GetEventString(event, "newname", newName, sizeof(newName));
	SQL_EscapeString(Database, newName, q_newName, sizeof(q_newName));
	Format(query, sizeof(query), "SELECT * FROM Registered_Nicks WHERE ingamenick = '%s'", q_newName);
	SQL_TQuery(Database, T_CheckName, query, client);
	if(rlogsenabled)
	{
		decl String:steam[100];
		if(useip)
		{
			GetClientIP(client, steam, sizeof(steam));
		}
		else
		{
			GetClientAuthString(client, steam, sizeof(steam));
		}
		LogToFile(logFile, "%s changed his name to %s and we are checking to see if it is registered", steam, q_newName);
	}
}	