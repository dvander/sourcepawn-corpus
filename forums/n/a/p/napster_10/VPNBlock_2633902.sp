#include <sourcemod>
#include <system2>

#pragma semicolon 1
#pragma newdecls required

#define PDAYS 30

public Plugin myinfo = 
{
	name = "VPN Block",
	author = "PwnK",
	description = "Blocks VPNs",
	version = "1.0.2",
	url = "https://pelikriisi.fi/"
};

Database g_db;
bool g_written = false;

public void OnPluginStart()
{
	LoadTranslations ("vpnblock.phrases");
	if (SQL_CheckConfig("VPNBlock"))
		Database.Connect(OnSqlConnect, "VPNBlock");
	else
		Database.Connect(OnSqlConnect, "default");
	RegAdminCmd("sm_vbwhitelist", CommandWhiteList, ADMFLAG_ROOT, "sm_vbwhitelist \"<SteamID>\"");
	RegAdminCmd("sm_vbunwhitelist", CommandUnWhiteList, ADMFLAG_ROOT, "sm_vbunwhitelist \"<SteamID>\"");
}

public void OnSqlConnect(Database db, const char[] error, any data)
{
	if (db == null)
	{
		SetFailState("Databases don't work");
	}
	else
	{
		g_db = db;
		g_db.Query(queryC, "CREATE TABLE IF NOT EXISTS `VPNBlock` (`playername` char(128) NOT NULL, `steamid` char(32) NOT NULL, `lastupdated` int(64) NOT NULL, `ip` char(32) NOT NULL, `proxy` boolean NOT NULL, PRIMARY KEY (`ip`))");
		g_db.Query(queryI, "CREATE TABLE IF NOT EXISTS `VPNBlock_wl` (`steamid` char(32) NOT NULL, PRIMARY KEY (`steamid`))");
	}
}

public void queryC(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		VPNBlock_Log(2, _, _, error);
		return;
	}
	PruneDatabase();
}

public void OnMapStart()
{
	g_written = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (!IsFakeClient(client))
	{
		char buffer[255], steamid[28];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		strcopy(steamid, sizeof(steamid), steamid[8]);
		Format(buffer, sizeof(buffer), "SELECT * FROM `VPNBlock_wl` WHERE `steamid` = '%s'", steamid);
		DBResultSet whitelist = SQL_Query(g_db, buffer);
		if (whitelist == null)
		{
			char error[255];
			SQL_GetError(g_db, error, sizeof(error));
			VPNBlock_Log(2, _, _, error);
			OnPluginStart();
		}
		else if (!SQL_FetchRow(whitelist))
		{
			char ip[30], buffer2[255];
			GetClientIP(client, ip, sizeof(ip));
			Format(buffer2, sizeof(buffer2), "SELECT `proxy` FROM `VPNBlock` WHERE `ip` = '%s'", ip);
			DBResultSet query = SQL_Query(g_db, buffer2);
			if (query == null)
			{
				char error[255];
				SQL_GetError(g_db, error, sizeof(error));
				VPNBlock_Log(2, _, _, error);
				OnPluginStart();
			}
			else if (!SQL_FetchRow(query))
			{
				CheckIpHttp(ip, client);
			}
			else if (SQL_FetchInt(query, 0) == 1)
			{
				VPNBlock_Log(0, client, ip);
				//KickClient(client, "%t", "VPN Kick");
			}
			delete query;
		}
		delete whitelist;
	}
}

void CheckIpHttp(char[] ip, int client)
{
	DataPack pack = new DataPack();
	pack.WriteString(ip);
	pack.WriteCell(client);
	char url[85];
	Format(url, sizeof(url), "http://proxy.mind-media.com/block/proxycheck.php?ip=%s", ip);
	System2HTTPRequest CheckIp = new System2HTTPRequest(HttpResponseCallback, url);
	CheckIp.Any = pack;
	CheckIp.Timeout = 5;
	CheckIp.GET();
	delete CheckIp;
}

void HttpResponseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
	if(success)
	{
		char[] content = new char[response.ContentLength + 1];
		response.GetContent(content, response.ContentLength + 1);
		char steamid[28], name[100], ip[30];
		DataPack pack = request.Any;
		pack.Reset();
		pack.ReadString(ip, sizeof(ip));
		int client = pack.ReadCell();
		delete pack;
		if (!IsClientConnected(client))
			return;
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		GetClientName(client, name, sizeof(name));
		int buffer_len = strlen(name) * 2 + 1;
		char[] newname = new char[buffer_len];
		SQL_EscapeString(g_db, name, newname, buffer_len);
		int proxy;
		
		if (StrEqual(content, "Y"))
		{
			VPNBlock_Log(0, client, ip);
			//KickClient(client, "%t", "VPN Kick");
			proxy = 1;
		}
		else
		{
			proxy = 0;
		}
		char query[300];
		Format(query, sizeof(query), "INSERT INTO `VPNBlock`(`playername`, `steamid`, `lastupdated`, `ip`, `proxy`) VALUES('%s', '%s', '%d', '%s', '%d');", newname, steamid, GetTime(), ip, proxy);
		g_db.Query(queryI, query);
	}
	else
	{
		if (!g_written)
		{
			g_written = true;
			VPNBlock_Log(1);
		}
	}
}

public void queryI(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		VPNBlock_Log(2, _, _, error);
		OnPluginStart();
	}
}

void PruneDatabase()
{
	int maxlastupdated = GetTime() - (PDAYS * 86400);
	char buffer[255];
	Format(buffer, sizeof(buffer), "DELETE FROM `VPNBlock` WHERE `lastupdated`<'%d';", maxlastupdated);
	g_db.Query(queryP, buffer);
}

public void queryP(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		VPNBlock_Log(2, _, _, error);
	}
}

public Action CommandWhiteList(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vbwhitelist \"<SteamID>\"");
		return Plugin_Handled;
	}
	
	WhiteList(true);
	return Plugin_Handled;
}

public Action CommandUnWhiteList(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vbunwhitelist \"<SteamID>\"");
		return Plugin_Handled;
	}
	
	WhiteList(false);
	return Plugin_Handled;
}

void WhiteList(bool whitelist)
{
	char steamid[28];
	GetCmdArgString(steamid, sizeof(steamid));
	StripQuotes(steamid);
	if (StrContains(steamid, "STEAM_") == 0)
		strcopy(steamid, sizeof(steamid), steamid[8]);
	
	int buffer_len = strlen(steamid) * 2 + 1;
	char[] escsteamid = new char[buffer_len];
	SQL_EscapeString(g_db, steamid, escsteamid, buffer_len);
	
	char query[100];
	if (whitelist)
		Format(query, sizeof(query), "INSERT INTO `VPNBlock_wl`(`steamid`) VALUES('%s');", escsteamid);
	else
		Format(query, sizeof(query), "DELETE FROM `VPNBlock_wl` WHERE `steamid`='%s';", escsteamid);
	g_db.Query(queryI, query);
}

void VPNBlock_Log(int logtype, int client = 0, char[] ip = "", const char[] error = "")
{
	char date[32];
	FormatTime(date, sizeof(date), "%d/%m/%Y %H:%M:%S", GetTime());
	char LogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, LogPath, sizeof(LogPath), "logs/VPNBlock_Log.txt");
	Handle logFile = OpenFile(LogPath, "a");
	if (logtype == 0)
	{
		char steamid[28];
		char name[100];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		GetClientName(client, name, sizeof(name));
		WriteFileLine(logFile, "[VPNBlock] %T", "Log VPN Kick", LANG_SERVER, date, name, steamid, ip);
	}
	else if (logtype == 1)
	{
		WriteFileLine(logFile, "[VPNBlock] %T", "Http Error", LANG_SERVER, date);
	}
	else
	{
		WriteFileLine(logFile, "[VPNBlock] %T", "Query Failure", LANG_SERVER, date, error);
	}
	delete logFile;
}