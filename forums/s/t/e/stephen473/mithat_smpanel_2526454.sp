#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Mithat Guner"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Mithat Guner(update by stephen473) | Istek Oneri PHP",
	author = PLUGIN_AUTHOR,
	description = "Mithat Guner | Istek Oneri PHP",
	version = PLUGIN_VERSION,
	url = "pluginler.com"
};

Handle hDatabase = INVALID_HANDLE;

public OnPluginStart()
{
	Handle kv = CreateKeyValues("sql");
	KvSetString(kv, "driver", "default");
	KvSetString(kv, "host", "pluginler.com");
	KvSetString(kv, "port", "3306");
	KvSetString(kv, "database", "");
	KvSetString(kv, "user", "");
	KvSetString(kv, "pass", "");

 	char error[255];
	hDatabase = SQL_ConnectCustom(kv, error, sizeof(error), true);
	CloseHandle(kv);

	if (hDatabase == INVALID_HANDLE)
	{
    	LogError("Failed: %s", error);
    	return;
	}
	
	else
	{
		char Query[255];
		Format(Query, sizeof(Query), "CREATE TABLE IF NOT EXISTS mithat_reports (steamid TEXT, name TEXT, report TEXT, id INT);");
		SQL_FastQuery(hDatabase, Query);
	}
		
	RegConsoleCmd("sm_report", report);
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
}


public void OnMapStart()
{
	
	Handle hHostName = FindConVar("hostname"); 
	char str[64];
	GetConVarString(hHostName, str, 64);  
	
	char server_port[10];
	char server_ip[16];

	Handle cvar_port = FindConVar("hostport");
	GetConVarString(cvar_port, server_port, sizeof(server_port));
	CloseHandle(cvar_port);

	Handle cvar_ip = FindConVar("ip");
	GetConVarString(cvar_ip, server_ip, sizeof(server_ip));
	CloseHandle(cvar_ip);

	UpdateServer(str, server_ip, server_port);
	
}

ReportADD(const String:id[52],const String:name[52], const String:report[32], const String:steamid[64])
{
	char Query[255];
	Format(Query, sizeof(Query), "INSERT INTO mithat_reports VALUES ('%s', '%s', '%s', '%s')",id, name, report, steamid);
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
	
}

public SQL_ErrorCheckCallBack(Handle owner, Handle hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("Query failed! %s", error);
	}
}

public Action report(int client, int args)
{
	char test[52];	
	char test1[32];	
	GetClientName(client, test, 52);
	GetCmdArgString(test1, 32);
	char steamid[64];
	GetClientAuthId(client, AuthIdType:1 , steamid, 64, true);
	ReportADD("",test, test1, steamid);	
}

UpdatePlayer(const String:count[21], const String:countct[21], const String:countt[21])
{
	char Query[255];
	Format(Query, sizeof(Query), "UPDATE mithat_players SET count = '%s',ct = '%s',tr = '%s' WHERE 1", count, countct, countt);
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int OyuncuSay = 0;
	int OyuncuSayct = 0;
	int OyuncuSaytt = 0;
	char Say[21];
	char SayT[21];
	char SayCT[21];
	char Mapname[64];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) 
		{
			OyuncuSay++;
		}
	}
	
	for (int t = 1; t <= MaxClients; t++) 
	{
		if(IsClientInGame(t) && (GetClientTeam(t) == 2)) 
		{
			OyuncuSaytt++;
		}
	}
	
	for (int ct = 1; ct <= MaxClients; ct++) {
		if(IsClientInGame(ct)  && (GetClientTeam(ct) == 3)) 
		{
			OyuncuSayct++;
		}
	}
	
	IntToString(OyuncuSay, Say, sizeof(Say));
	IntToString(OyuncuSaytt, SayT, sizeof(SayT));
	IntToString(OyuncuSayct, SayCT, sizeof(SayCT));
	
	GetCurrentMap(Mapname, 64);
	UpdatePlayer(Say, SayCT, SayT);
	UpdateMap(Mapname);
	
	return Plugin_Continue; 
	
}


UpdateMap(const String:map[64])
{
	char Query[255];	
	Format(Query, sizeof(Query), "UPDATE mithat_map SET name = '%s' WHERE 1", map);
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

UpdateServer(const String:servername[64],const String:serverip[16],const String:serverport[10])
{
	char Query[255];
	Format(Query, sizeof(Query), "UPDATE mithat_server SET servername = '%s',serverip = '%s',serverport = '%s' WHERE 1", servername,serverip,serverport);
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{

	int ctscore = GetTeamScore(3);
	int tscore = GetTeamScore(2);
	
	char TSCORE[16];
	char CTSCORE[16];
	IntToString(tscore, TSCORE, 16);
	IntToString(ctscore, CTSCORE, 16);
	UpdateScore(CTSCORE,TSCORE);
}

UpdateScore(const String:ctscore[16],const String:tscore[16])
{
	char Query[255];
	Format(Query, sizeof(Query), "UPDATE mithat_score SET ctscore = '%s',tscore = '%s' WHERE 1", ctscore,tscore);
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

UpdateLast(const String:name[32],const String:steamid[64], const String:hour[30],const String:ip[30])
{
	char Query[255];	
	Format(Query, sizeof(Query), "UPDATE mithat_lastconnected SET name = '%s',steamid = '%s',time = '%s',ip = '%s' WHERE 1", name,steamid,hour,ip);
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

public OnClientAuthorized(client, const String:auth[])
{
	char name[32];	
	GetClientName(client, name, 32);
	char saat[30];
   	FormatTime(saat, sizeof(saat), "%T", GetTime()); 
   	char steamid[64];
	GetClientAuthId(client, AuthIdType:1 , steamid, 64, true);
	
	char IP[30];
	GetClientIP(client, IP, sizeof(IP));
	UpdateLast(name, steamid, saat, IP);
	PlayerStats("", name, IP, steamid);
}

PlayerStats(const String:id[52],const String:name[32], const String:ip[30], const String:steamid[64])
{
	char Query[255];
	Format(Query, sizeof(Query), "INSERT INTO mithat_playerstats VALUES ('%s', '%s', '%s', '%s')",id, steamid, name, ip);
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
	
}

public OnClientDisconnect(client)
{
	char IP[30];
	GetClientIP(client, IP, sizeof(IP));
	char Query[255];
	Format(Query, sizeof(Query), "DELETE FROM mithat_playerstats WHERE '%s'", IP);
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_Query(hDatabase, "SET CHARACTER SET utf8"); 
	SQL_Query(hDatabase, "SET COLLATION_CONNECTION = 'utf8_turkish_ci'"); 
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);	
}