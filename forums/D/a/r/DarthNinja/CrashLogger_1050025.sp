#include <sourcemod>
#define PLUGIN_VERSION "2.0.0"

new Handle:TimeOffset = INVALID_HANDLE;
new Handle:ServerName = INVALID_HANDLE;
new Handle:ServerID = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[Any] Classy Crash Logger",
	author = "DarthNinja",
	description = "Logs Server Starups to a MySQL database",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_crashlogger_version", PLUGIN_VERSION, "Crash Logger", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	TimeOffset = CreateConVar("sm_crashlogger_offset","0","Number of seconds to alter the server timestamp by");
	ServerName = CreateConVar("sm_crashlogger_servername","","Friendly name of the server, if left blank, the hostname cvar is used.");
	ServerID = CreateConVar("sm_crashlogger_serverid","1","Server id number (for filtering)");
	AutoExecConfig(true);
	
	decl String:TestFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TestFile, sizeof(TestFile), "data/Crashlogger.txt");
	
	if (FileExists(TestFile))
	{
		//Server didn't shut down gracefully
		if (SQL_CheckConfig("crashlogger"))
			SQL_TConnect(Connected, "crashlogger");
		else 
			LogError("Can't find database in config!");
	}
	else	//Server did shut down correctly, and deleted the file
	{
		new Handle:File = OpenFile(TestFile, "w");
		WriteFileLine(File, "This file is created by the [Any] Classy Crash Logger plugin in order to detect if the last server shutdown was expected");
		CloseHandle(File);
	}
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to connect! Error: %s", error);
		PrintToServer("Server startup logging failed!");
		return;
	}
	
	LogMessage("Classy Crash Logger connected to database!");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	
	new len = 0;
	decl String:query[1024];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Crashes` (");
	len += Format(query[len], sizeof(query)-len, "`indexnum` int(11) NOT NULL auto_increment,");
	len += Format(query[len], sizeof(query)-len, "`timedate` int(11) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`ServerNum` int(3) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`ServerName` varchar(250) character set utf8 collate utf8_unicode_ci NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`indexnum`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM  DEFAULT CHARSET=latin1;");
	SQL_TQuery(hndl, SQLErrorCheckCallback, query);
	
	
	len = 0;
	new time = (GetTime() + GetConVarInt(TimeOffset));
	decl String:sServerName[250];
	decl String:sServerNameEsc[250];
	GetConVarString(ServerName, sServerName, sizeof(sServerName));
	if (StrEqual(sServerName, ""))
	{
		new Handle:Hostname = INVALID_HANDLE;
		Hostname = FindConVar("hostname");
		if (Hostname != INVALID_HANDLE)
			GetConVarString(Hostname, sServerName, sizeof(sServerName));
	}
	SQL_EscapeString(hndl, sServerName, sServerNameEsc, sizeof(sServerNameEsc));
	
	len += Format(query[len], sizeof(query)-len, "INSERT INTO `Crashes` (`timedate` ,`ServerNum` ,`ServerName`) VALUES ('%i', '%i', '%s');", time, GetConVarInt(ServerID), sServerNameEsc);
	SQL_TQuery(hndl, SQLErrorCheckCallback, query);
	PrintToServer("Server startup logged!");
}

public OnPluginEnd()
{
	decl String:TestFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TestFile, sizeof(TestFile), "data/Crashlogger.txt");
	if (FileExists(TestFile))
		DeleteFile(TestFile);
}

/* SQL Error Handler */
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}