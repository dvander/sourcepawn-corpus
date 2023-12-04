
#define PLUGIN_AUTHOR "Mithat Guner & stephen473(Hardy`#3792)"
#define PLUGIN_VERSION "1.2 & syntax update and cleaned the code"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Mithat Guner | Istek Oneri PHP",
	author = PLUGIN_AUTHOR,
	description = "Mithat Guner | Istek Oneri PHP",
	version = PLUGIN_VERSION,
	url = "pluginler.com"
};

Database hDatabase;

public void OnPluginStart()
{
	char driver[32], host[32], port[32], database[32], user[32], pass[32];
	KeyValues hKv = new KeyValues("smpanel");
	
	hKv.ImportFromFile("addons/sourcemod/configs/mithat_database_smpanel.cfg");
	
	hKv.GetString("driver", driver, sizeof(driver));
	hKv.GetString("host", host, sizeof(host));
	hKv.GetString("port", port, sizeof(port));
	hKv.GetString("database", database, sizeof(database));
	hKv.GetString("user", user, sizeof(user));
	hKv.GetString("pass", pass, sizeof(pass));
	
	KeyValues hSQLKv = new KeyValues("sql");
	
	hSQLKv.SetString("driver", driver);
	hSQLKv.SetString("host", host);
	hSQLKv.SetString("port", port);
	hSQLKv.SetString("database", database);
	hSQLKv.SetString("user", user);
	hSQLKv.SetString("pass", pass);
	
	char sError[255];
	hDatabase = SQL_ConnectCustom(hSQLKv, sError, sizeof(sError), true);

	delete hKv;
	delete hSQLKv;

	if (hDatabase == INVALID_HANDLE)
	{
    	LogError("SM Panel | SQL Connection Fail: %s", sError);
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
	char sName[64];
	char sPort[10];
	char sIP[16];
	
	FindConVar("hostname").GetString(sName, sizeof(sName));  
	FindConVar("ip").GetString(sIP, sizeof(sIP));
	FindConVar("hostport").GetString(sPort, sizeof(sPort));
	
	UpdateServer(sName, sIP, sPort);
}

public void OnClientAuthorized(client, const char[] auth)
{
	char sName[32];	
	GetClientName(client, sName, 32);
	
	char sTime[30];
   	FormatTime(sTime, sizeof(sTime), "%T", GetTime()); 
   	
   	char sAuth[32];
	GetClientAuthId(client, AuthId_Steam2, sAuth, 32, true);
	
	char sIP[30];
	GetClientIP(client, sIP, sizeof(sIP));
	
	UpdateLast(sName, sAuth, sTime, sIP);
	UpdatePlayerStats("", sName, sIP, sAuth);
}

public void OnClientDisconnect(int client)
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


public Action report(int client, int args)
{
	char sTest[52];	
	char sTest1[32];	
	
	GetClientName(client, sTest, 52);
	GetCmdArgString(sTest1, 32);
	
	char sAuth[64];
	GetClientAuthId(client, AuthId_Steam2, sAuth, 32, true);
	
	if (args == 1){
		PrintToChat(client, " \x10!report <comment>");
	}
	
	AddReport("", sTest, sTest1, sAuth);
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int iCount = 0;
	int iCountTS = 0;
	int iCountCT = 0;
	
	char sString[3][21];
	char sMap[PLATFORM_MAX_PATH];

	GetCurrentMap(sMap, PLATFORM_MAX_PATH);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) 
		{
			iCount++;
			
			switch (GetClientTeam(i))
			{
				case 2:
				{
					iCountTS++;
				}
				
				case 3:
				{
					iCountCT++;			
				}
			}
		}
	}
	
	IntToString(iCount, sString[0], 21);
	IntToString(iCountTS, sString[1], 21);
	IntToString(iCountCT, sString[2], 21);
	
	UpdatePlayer(sString[0], sString[1], sString[2]);
	UpdateMap(sMap);
}

public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int iTSScore = GetTeamScore(2);	
	int iCTScore = GetTeamScore(3);

	char sTScore[16];
	char sCTScore[16];
	
	IntToString(iTSScore, sTScore, 16);
	IntToString(iCTScore, sCTScore, 16);
	
	UpdateScore(sCTScore, sTScore);
}

void AddReport(char[] id, char[] name, char[] report, char[] steamid)
{
	char Query[255];
	Format(Query, sizeof(Query), "INSERT INTO mithat_reports VALUES ('%s', '%s', '%s', '%s')",id, name, report, steamid);
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

void UpdatePlayer(char[] sCount, char[] sCountCT, char[] sCountTS)
{
	char Query[255];
	Format(Query, sizeof(Query), "UPDATE mithat_players SET count = '%s',ct = '%s',tr = '%s' WHERE 1", sCount, sCountCT, sCountTS);
	
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

void UpdateMap(char[] sMap)
{
	char Query[255];	
	Format(Query, sizeof(Query), "UPDATE mithat_map SET name = '%s' WHERE 1", sMap);
	
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

void UpdateServer(char[] sName, char[] sIP, char[] sPort)
{
	char Query[255];
	Format(Query, sizeof(Query), "UPDATE mithat_server SET servername = '%s',serverip = '%s',serverport = '%s' WHERE 1", sName, sIP, sPort);
	
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

void UpdateScore(char[] sCTScore, char[] sTSScore)
{
	char Query[255];
	Format(Query, sizeof(Query), "UPDATE mithat_score SET ctscore = '%s',tscore = '%s' WHERE 1", sCTScore, sTSScore);
	
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

void UpdateLast(char[] sName, char[] sAuth, char[] sHour, char[] sIP)
{
	char Query[255];	
	Format(Query, sizeof(Query), "UPDATE mithat_lastconnected SET name = '%s',steamid = '%s',time = '%s',ip = '%s' WHERE 1", sName, sAuth, sHour, sIP);
	
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

void UpdatePlayerStats(char[] sID, char[] sName, char[] sIP, char[] sAuth)
{
	char Query[255];
	Format(Query, sizeof(Query), "INSERT INTO mithat_playerstats VALUES ('%s', '%s', '%s', '%s')", sID, sAuth, sName, sIP);
	
	SQL_Query(hDatabase, "SET NAMES UTF8");
	SQL_TQuery(hDatabase, SQL_ErrorCheckCallBack, Query);
}

public int SQL_ErrorCheckCallBack(Handle owner, Handle hndl, const char[]error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		SetFailState("SM Panel | Query failed! %s", error);
	}
}
