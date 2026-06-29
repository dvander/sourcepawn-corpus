#include <sourcemod>

#define PLUGIN_VERSION "1.3"

//Setup the handle for the database
new Handle:db = INVALID_HANDLE;

//Setup handle for ConVars
new Handle:Advert;

//Setup the custom log to easy find the reports
new String:loggi[PLATFORM_MAX_PATH];

//for the sql Check
new bool:MySQL_Usage;


public Plugin:myinfo = 
{
	name	= "Map Reporter",
	author	= "ecca",
	description	= "Allows users to report bugs on map to either MySQL or txt file",
	version	= PLUGIN_VERSION,
	url		= "http://sourcemod.net"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_reportmap", Command_Reportmap);
	
	Advert = CreateConVar("sm_mapreporter_advert", "1", "Should the plugin advert about they can report the map every round: 0 - Off, 1 - On", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_map_reporter_version", PLUGIN_VERSION,  "The version of the SourceMod plugin Mapreporter, by ecca", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig(true, "sm_mapreporter");
	
	if(SQL_CheckConfig("mapreporter"))
	{
		MySQL_Usage = true;
		PrintToServer("[Map Reporter] Using MySQL to store information!");
	} else {
		MySQL_Usage = false;
		PrintToServer("[Map Reporter] Using txt file to store information!");
	}
	
	//Lets create a timer if we want to advert the plugin
	if (GetConVarInt(Advert) == 1)
	{
		HookEvent("round_start", RoundStart);
	}
	
	//Lets connect to the database is we have set the ConVar to 1
	if (MySQL_Usage)
	{
		SQL_TConnect(SQL_OnConnect, "mapreporter");
		PrintToServer("[Map Reporter] Uses MySQL to log the reports!");
	} else {
		PrintToServer("[Map Reporter] Uses txt file to log the reports!");
	}
	
	BuildPath(Path_SM, loggi, sizeof(loggi), "logs/MapReporter.log");
}

public SQL_OnConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	//Check if the connection connected successfully
	if (hndl == INVALID_HANDLE)
	{
		//FFS is it so hard to get the mysql connection
		LogError("[Map Reporter] Unable to connect to MySQL database, error: %s", error);
		
	} else {
		//Yee we got a mysql connection so lets set the handle
		db = hndl; 
	}
}

public Action:Command_Reportmap(client, args)
{
	if(args == 0 )
	{
		PrintToChat(client, "[Map Reporter] sm_reportmap REASON");
		return Plugin_Handled;
	}
	
	decl String:szSteamid[64];		
	decl String:szName[100];
	decl String:szNameEscaped[100];
	decl String:szMapName[128];
	decl String:szComment[128];
	decl String:szCommentEscaped[128];
	decl String:szTime[64];
	
	
	GetClientName(client, szName, sizeof(szName));
	GetClientAuthString(client, szSteamid, sizeof(szSteamid));
	GetCurrentMap(szMapName, sizeof(szMapName));
	GetCmdArgString(szComment, sizeof(szComment));
	FormatTime(szTime, sizeof(szTime), "%Y-%m-%d %H:%M:%S", GetTime());

	if (MySQL_Usage)
	{	
		SQL_EscapeString(db, szName, szNameEscaped, sizeof(szNameEscaped));
		SQL_EscapeString(db, szComment, szCommentEscaped, sizeof(szCommentEscaped));
		
		decl String:insert[300];
		FormatEx(insert, sizeof(insert), "INSERT INTO map_reports (map, player, steamid, comment, date) VALUES ('%s', '%s', '%s', '%s', '%s')", szMapName, szNameEscaped, szSteamid, szCommentEscaped, szTime);
		SQL_TQuery(db,SQL_Insert,insert);

		PrintToChat(client, "[Map Reporter] Thank you for your map report!");
		
	} else {
		LogToFile(loggi, "--------------------------------------------------------");
		LogToFile(loggi, "Map: %s", szMapName);
		LogToFile(loggi, "Player: %s", szName);
		LogToFile(loggi, "Steamid: %s", szSteamid);
		LogToFile(loggi, "Comment: %s", szComment);
		LogToFile(loggi, "Date: %s", szTime);
		PrintToChat(client, "[Map Reporter] Thank you for your map report!");
	}
	return Plugin_Handled;
}

public SQL_Insert(Handle:owner, Handle:hndl, const String:error[], any:client)
{
}

public Action:RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	PrintToChatAll("[Map Reporter] You can report current map for bugs: say !reportmap REASON");
}