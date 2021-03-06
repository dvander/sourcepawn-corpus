/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new Handle:db = INVALID_HANDLE;			/** Database connection */

public Plugin:myinfo = 
{
	name = "Found Item Logger",
	author = "R-Hehl",
	description = "Found Item Logger",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};

public OnPluginStart()
{
	CreateConVar("sm_tf2_itemlogger_version", PLUGIN_VERSION, "TF2 Player Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	new String:error[255]
	db = SQL_Connect("itemlogger",true,error, sizeof(error))
	if (db == INVALID_HANDLE)
	{
	PrintToServer("Failed to connect: %s", error)
	}
	else 
	{
	LogMessage("DatabaseInit (CONNECTED) with db config");
	/* Set codepage to utf8 */

	decl String:query[255];
	Format(query, sizeof(query), "SET NAMES 'utf8'");
	if (!SQL_FastQuery(db, query))
	{
	LogError("Can't select character set (%s)", query);
	}
	}
	createdb()
	HookEvent("item_found", Event_item_found)
}
public Action:Event_item_found(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "player")
	new String:steamid[64];
	GetClientAuthString(userid, steamid, sizeof(steamid));
	new String:item[64]
	GetEventString(event, "item", item, sizeof(item))
	new time = GetTime()
	new String:query[512];
	
	Format(query, sizeof(query), "INSERT INTO log (`STEAMID`,`ACTUALTIME`,`ONLINEPLAYERS`,`ITEM`) VALUES ('%s','%i','%i','%s')", steamid, time, GetClientCount(true), item)
	SQL_TQuery(db,SQLErrorCheckCallback, query)
	
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
	LogMessage("SQL Error: %s", error);
	}
}

createdb()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `log`");
	len += Format(query[len], sizeof(query)-len, " (`ID` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,");
	len += Format(query[len], sizeof(query)-len, "`STEAMID` VARCHAR( 25 ) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ACTUALTIME` INT NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ONLINEPLAYERS` INT NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`ITEM` VARCHAR( 50 ) NOT NULL DEFAULT '0'");
	len += Format(query[len], sizeof(query)-len, ") ENGINE = MYISAM ;");
	SQL_FastQuery(db, query);
}