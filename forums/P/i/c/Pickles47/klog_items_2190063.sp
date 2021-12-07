#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:g_dbItems = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "TF2 Kill Log Items",
	author = "Sinclair",
	description = "Items addon for TF2 Kill Log",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() {
	CreateConVar("klog_items_v", PLUGIN_VERSION, "TF2 Kill Log Items", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("item_found", Event_item_found);
	SQL_TConnect(connectDB, "killlog");
}

public connectDB(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (hndl == INVALID_HANDLE) {
		LogError("Database failure: %s", error);
		return;
	} else {
		LogMessage("TF2 Kill Log Items Connected to Database!");
		g_dbItems = hndl;
		createDBItemLog();
	}
}

public Action:Event_item_found(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new client = GetEventInt(hEvent, "player");
	new method = GetEventInt(hEvent, "method");
	new index = GetEventInt(hEvent, "itemdef");
	new quality = GetEventInt(hEvent, "quality");

	new String:id[64];
	GetClientAuthString(client, id, sizeof(id));

	new String:query[512];
	Format(query, sizeof(query), "INSERT INTO itemlog (`auth`, `time`, `index`, `quality`, `method`) VALUES ('%s', '%i', '%i', %i, %i)", id, GetTime(), index, quality, method);
	SQL_TQuery(g_dbItems, SQLError, query);
}

public SQLError(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if (!StrEqual("", error)) {
		LogMessage("SQL Error: %s", error);
	}
}

createDBItemLog() {
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `itemlog` (");
	len += Format(query[len], sizeof(query)-len, "`auth` varchar(20) DEFAULT NULL,");
	len += Format(query[len], sizeof(query)-len, "`time` int(11) DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`index` int(11) DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`quality` tinyint(2) DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`method` tinyint(2) DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "KEY `quality` (`quality`),");
	len += Format(query[len], sizeof(query)-len, "KEY `method` (`method`),");
	len += Format(query[len], sizeof(query)-len, "KEY `auth` (`auth`,`index`,`quality`,`method`),");
	len += Format(query[len], sizeof(query)-len, "KEY `index` (`index`,`quality`,`method`))");
	len += Format(query[len], sizeof(query)-len, "ENGINE = InnoDB DEFAULT CHARSET=utf8;");
	SQL_FastQuery(g_dbItems, query);
}