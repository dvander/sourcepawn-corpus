#include <sourcemod>

#define PLUGIN_NAME         "Unusual SQL Converter"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Convert unusual effects file DB to SQL DB"
#define PLUGIN_VERSION      "1.0"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define DATAFILE			"unusual_effects.txt"


new String:UnusualEffect[PLATFORM_MAX_PATH];
new String:ClientSteamID[64];

new bool:SQLite 					= false;
new bool:Started	 				= false;

new Handle:db 						= INVALID_HANDLE;

new ItemID 		= -1;
new QualityID 	= -1;
new EffectID 	= -1;
new count		= 0;

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{	
	CreateConVar("unusual_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);

	RegAdminCmd("unusual_sql_start", StartConversion, ADMFLAG_GENERIC);
	
	Connect();
	
	BuildPath(Path_SM, UnusualEffect,sizeof(UnusualEffect),"configs/%s", DATAFILE);
	
	ItemID 		= -1;
	QualityID 	= -1;
	EffectID 	= -1;
	count		= 0;
	Started	 	= false;
	ClientSteamID = "";
}


//--------------------------------------------------------------------------------------
//							DataBase SQL
//--------------------------------------------------------------------------------------


Connect()
{
	if (SQL_CheckConfig("unusual"))
	{
		SQL_TConnect(Connected, "unusual");
	}
	else
	{
		new String:error[255];
		SQLite = true;
		
		new Handle:kv;
		kv = CreateKeyValues("");
		KvSetString(kv, "driver", "sqlite");
		KvSetString(kv, "database", "unusual");
		db = SQL_ConnectCustom(kv, error, sizeof(error), false);
		CloseHandle(kv);		
		
		if (db == INVALID_HANDLE)
			LogMessage("Loading : Failed to connect: %s", error);
		else
		{
			LogMessage("Loading : Connected to SQLite Database");
			CreateDbSQLite();
		}
	}
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		LogMessage("Loading : Failed to connect! Error: %s", error);
		SetFailState("SQL Error.  See error logs for details.");
		return;
	}

	LogMessage("Loading : Connected to MySQL Database");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	SQL_CreateTables();
}

SQL_CreateTables()
{
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `unusual_data` (");
	len += Format(query[len], sizeof(query)-len, "`index` int(10) unsigned NOT NULL AUTO_INCREMENT, ");
	len += Format(query[len], sizeof(query)-len, "`user_steamID` VARCHAR(64) NOT NULL, ");
	len += Format(query[len], sizeof(query)-len, "`item_ID` int(11) NOT NULL DEFAULT '-1', ");
	len += Format(query[len], sizeof(query)-len, "`effect_ID` int(11) NOT NULL DEFAULT '-1', ");
	len += Format(query[len], sizeof(query)-len, "`quality_ID` int(11) NOT NULL DEFAULT '-1', ");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY (`index`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;");
	if (SQL_FastQuery(db, query)) 
		LogMessage("Loading : Table Created");
}

CreateDbSQLite()
{
	new len = 0;
	decl String:query[512];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `unusual_data` (");
	len += Format(query[len], sizeof(query)-len, " `index` INTEGER PRIMARY KEY,");
	len += Format(query[len], sizeof(query)-len, " `user_steamID` VARCHAR(64),");
	len += Format(query[len], sizeof(query)-len, " `item_ID` INTEGER DEFAULT -1,");
	len += Format(query[len], sizeof(query)-len, " `effect_ID` INTEGER DEFAULT -1,");
	len += Format(query[len], sizeof(query)-len, " `quality_ID` INTEGER DEFAULT -1,");	
	len += Format(query[len], sizeof(query)-len, ");");
	if(SQL_FastQuery(db, query))
		LogMessage("Loading : Table Created");
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
		if(Started)
			LogMessage("ERROR: Conversion STOPPED !");
		Started = false;
	}
}


//--------------------------------------------------------------------------------------
//							Functions
//--------------------------------------------------------------------------------------

public Action:StartConversion(iClient, Args)
{
	if(!Started)
	{
		count = 0;
		LogMessage("Conversion STARTED !");
		LogMessage("You will be notified when it will be done!");
		if(!LoadConversion())
			LogMessage("ERROR: Conversion STOPPED!");
	}
	else
		LogMessage("Conversion ALREADY STARTED!");
}

bool:LoadConversion()
{
	Started = true;
	
	new Handle:kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		Started = false;
		LogMessage("ERROR: Can't open %s file!", DATAFILE);
		CloseHandle(kv);
		return false;
	}
	
	
	if(!KvGotoFirstSubKey(kv, true)) // SteamID
	{
		Started = false;
		LogMessage("ERROR: Can't find player in %s", DATAFILE);
		CloseHandle(kv);
		return false;
	}
	
	KvGetSectionName(kv, ClientSteamID, sizeof(ClientSteamID));
	
	if(!KvGotoFirstSubKey(kv, true)) // ItemID
	{
		Started = false;
		LogMessage("ERROR: Can't find item for %s in %s", ClientSteamID, DATAFILE);
		CloseHandle(kv);
		return false;
	}
	
	decl String:str_ItemID[10];
	KvGetSectionName(kv, str_ItemID, sizeof(str_ItemID));
	ItemID = StringToInt(str_ItemID);
	
	QualityID = KvGetNum(kv, "quality", -1);
	EffectID = KvGetNum(kv, "effect", -1);
	
	if(QualityID == -1)
	{
		Started = false;
		LogMessage("ERROR: Can't find quality for item %i for %s in %s", ItemID, ClientSteamID, DATAFILE);
		CloseHandle(kv);
		return false;
	}
	
	if(EffectID == -1)
	{
		Started = false;
		LogMessage("ERROR: Can't find effect for item %i for %s in %s", ItemID, ClientSteamID, DATAFILE);
		CloseHandle(kv);
		return false;
	}
	
	if(!Started) return false;
	
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT * FROM unusual_data WHERE `user_steamID` = '%s' AND `item_ID` = '%i'", ClientSteamID, ItemID);
	SQL_TQuery(db, T_UpdateClient, buffer);
	
	CloseHandle(kv);
	return true;
}

public T_UpdateClient(Handle:owner, Handle:hndl, const String:error[],  any:data)
{
	if(!SQL_GetRowCount(hndl))
	{
		new String:buffer[256];
		if(!SQLite)
		{
			Format(buffer, sizeof(buffer), "INSERT INTO unusual_data (`user_steamID`,`item_ID`,`effect_ID`,`quality_ID`) VALUES ('%s','%i','%i','%i')", ClientSteamID, ItemID, EffectID, QualityID);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
		else
		{
			Format(buffer, sizeof(buffer), "INSERT INTO unusual_data VALUES ('%s','%i','%i','%i')", ClientSteamID, ItemID, EffectID, QualityID);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
	}
	else
	{
		new String:buffer[256];
		while (SQL_FetchRow(hndl))
		{
			Format(buffer, sizeof(buffer), "UPDATE unusual_data SET `effect_ID` = %i, `quality_ID` = %i WHERE `user_steamID` = '%s' AND `item_ID` = %i", EffectID, QualityID, ClientSteamID, ItemID);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
		}
	}
	
	count++;
	LogMessage("Unusual Effects processed: %i", count);
	ContinueConversion();

}

ContinueConversion()
{
	if(!Started) return;
		
	new Handle:kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		Started = false;
		LogMessage("ERROR: Can't open %s file!", DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	if(!KvJumpToKey(kv, ClientSteamID, false))
	{
		Started = false;
		LogMessage("ERROR: Can't find player %s in %s", ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	decl String:str_ItemID[10];
	Format(str_ItemID, sizeof(str_ItemID), "%i", ItemID);

	if(!KvJumpToKey(kv, str_ItemID, false))
	{
		Started = false;
		LogMessage("ERROR: Can't find item %i of player %s in %s", ItemID, ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	if(!KvGotoNextKey(kv, true)) // Player has not more item
	{
		CloseHandle(kv);
		GoToNextPlayer();
		return;
	}
	
	if(!Started) return;
	
	KvGetSectionName(kv, str_ItemID, sizeof(str_ItemID));
	ItemID = StringToInt(str_ItemID);
	
	QualityID = KvGetNum(kv, "quality", -1);
	EffectID = KvGetNum(kv, "effect", -1);
	
	if(QualityID == -1)
	{
		Started = false;
		LogMessage("ERROR: Can't find quality for item %i for %s in %s", ItemID, ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	if(EffectID == -1)
	{
		Started = false;
		LogMessage("ERROR: Can't find effect for item %i for %s in %s", ItemID, ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT * FROM unusual_data WHERE `user_steamID` = '%s' AND `item_ID` = '%i'", ClientSteamID, ItemID);
	SQL_TQuery(db, T_UpdateClient, buffer);
	
	CloseHandle(kv);
	return;
}

GoToNextPlayer()
{
	if(!Started) return;
	
	new Handle:kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		Started = false;
		LogMessage("ERROR: Can't open %s file!", DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	if(!KvJumpToKey(kv, ClientSteamID, false))
	{
		Started = false;
		LogMessage("ERROR: Can't find player %s in %s", ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	if(!KvGotoNextKey(kv, true)) // no more player
	{
		Started = false;
		LogMessage("Conversion FINISHED!");
		CloseHandle(kv);
		return;
	}
	
	decl String:buffer_ClientSteamID[64];
	KvGetSectionName(kv, buffer_ClientSteamID, sizeof(buffer_ClientSteamID));
	if(StrEqual(buffer_ClientSteamID, ClientSteamID))
	{
		Started = false;
		LogMessage("Conversion FINISHED!");
		CloseHandle(kv);
		return;
	}
	
	strcopy(ClientSteamID, sizeof(ClientSteamID), buffer_ClientSteamID);
	
	if(!KvGotoFirstSubKey(kv, true)) // ItemID
	{
		Started = false;
		LogMessage("ERROR: Can't find item for %s in %s", ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	decl String:str_ItemID[10];
	KvGetSectionName(kv, str_ItemID, sizeof(str_ItemID));
	ItemID = StringToInt(str_ItemID);
	
	QualityID = KvGetNum(kv, "quality", -1);
	EffectID = KvGetNum(kv, "effect", -1);
	
	if(QualityID == -1)
	{
		Started = false;
		LogMessage("ERROR: Can't find quality for item %i for %s in %s", ItemID, ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}
	
	if(EffectID == -1)
	{
		Started = false;
		LogMessage("ERROR: Can't find effect for item %i for %s in %s", ItemID, ClientSteamID, DATAFILE);
		LogMessage("ERROR: Conversion STOPPED!");
		CloseHandle(kv);
		return;
	}

	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT * FROM unusual_data WHERE `user_steamID` = '%s' AND `item_ID` = '%i'", ClientSteamID, ItemID);
	SQL_TQuery(db, T_UpdateClient, buffer);
	
	CloseHandle(kv);
	return;
}