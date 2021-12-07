#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1

#define PDAYS 30

public Plugin myinfo = 
{
	name = "VPN Block",
	author = "PwnK",
	description = "Blocks VPNs",
	version = "1.1.0",
	url = "https://pelikriisi.fi/"
};

Database g_db;

ConVar gcv_KickClients;
ConVar gcv_url;
ConVar gcv_response;

public void OnPluginStart()
{
	ConnectToDatabase();
	LoadTranslations ("vpnblock.phrases");

	RegAdminCmd("sm_vbwhitelist", CommandWhiteList, ADMFLAG_ROOT, "sm_vbwhitelist \"<SteamID>\"");
	RegAdminCmd("sm_vbunwhitelist", CommandUnWhiteList, ADMFLAG_ROOT, "sm_vbunwhitelist \"<SteamID>\"");
	
	gcv_KickClients = CreateConVar("vpnblock_kickclients", "1", "1 = Kick and log client when he tries to join with a VPN 0 = only log", _, true, 0.0, true, 1.0);
	gcv_url = CreateConVar("vpnblock_url", "http://proxy.mind-media.com/block/proxycheck.php?ip={IP}", "The url used to check proxies.");
	gcv_response = CreateConVar("vpnblock_response", "Y", "If the response contains this it means the player is using a VPN.");
	AutoExecConfig(true, "VPNBlock");
}

public void ConnectToDatabase()
{
	new String:Error[256], Database:db;
	if ((db = SQLite_UseDatabase("sourcemod-local", Error, sizeof(Error))) == null)
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
			char ip[30];
			GetClientIP(client, ip, sizeof(ip));
			Format(buffer, sizeof(buffer), "SELECT `proxy` FROM `VPNBlock` WHERE `ip` = '%s'", ip);
			DBResultSet query = SQL_Query(g_db, buffer);
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
				if (gcv_KickClients.BoolValue)
					KickClient(client, "%t", "VPN Kick");
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
	gcv_url.GetString(url, sizeof(url));
	ReplaceString(url, sizeof(url), "{IP}", ip, true);
	Handle CheckIp = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	SteamWorks_SetHTTPCallbacks(CheckIp, HttpResponseCompleted, _, HttpResponseDataReceived);
	SteamWorks_SetHTTPRequestContextValue(CheckIp, pack);
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(CheckIp, 5);
	SteamWorks_SendHTTPRequest(CheckIp);
}

public int HttpRequestData(const char[] content, DataPack pack)
{
	char steamid[28], name[100], ip[30];
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
	char responsevpn[30];
	gcv_response.GetString(responsevpn, sizeof(responsevpn));
	
	if (StrContains(content, responsevpn) != -1)
	{
		VPNBlock_Log(0, client, ip);
		if (gcv_KickClients.BoolValue)
			KickClient(client, "%t", "VPN Kick");
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

public int HttpResponseDataReceived(Handle request, bool failure, int offset, int bytesReceived, DataPack pack)
{
	SteamWorks_GetHTTPResponseBodyCallback(request, HttpRequestData, pack);
	delete request;
}

public int HttpResponseCompleted(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, DataPack pack)
{
	if(failure || !requestSuccessful)
	{
		VPNBlock_Log(1);
		delete pack;
		delete request;
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