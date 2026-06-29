#include <sourcemod>
#include <cbaseserver>

#define THRESHOLD 	28
#define LOGFILE		"logs/cbasereslog.txt"

new String:g_szLogPath[128];

public Plugin:myinfo = 
{
	name = "CBaseRes Log",
	author = "Nut",
	description = "Simple plugin which logs player connections to a file",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	BuildPath(Path_SM, g_szLogPath, sizeof(g_szLogPath), LOGFILE);
	if (!FileExists(g_szLogPath))
		SetFailState("Missing log file (%s)", g_szLogPath);
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	new iCount = GetClientCount(false);
	if (iCount >= THRESHOLD)
		LogToFileEx(g_szLogPath, "Client \"%s\" (%s) connected (%s) - Players %i/%i", name, authid, ip, iCount, MaxClients);
}
