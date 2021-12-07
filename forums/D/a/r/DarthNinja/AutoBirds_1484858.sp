#include <sourcemod>
#include <sdktools>

#define VERSION "2.0.0"
new Handle:db = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] Auto Birds",
	author = "DarthNinja",
	description = "Auto-Spawns birds at the start of the round!",
	version = VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_birds_version", VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_layegg", LayEgg, ADMFLAG_ROOT);
	RegAdminCmd("sm_breakegg", BreakEgg, ADMFLAG_ROOT);

	Connect();
	HookEvent("teamplay_round_start", EventRoundStart);
}

public Action:LayEgg(client, args)
{

	if(GetEntityCount() >= GetMaxEntities()-64)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn any more birds. Change maps.");
		return Plugin_Handled;
	}
	
	new iDove = CreateEntityByName("entity_bird");
	
	if(IsValidEntity(iDove))
	{
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		DispatchSpawn(iDove);
		TeleportEntity(iDove, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(iDove, Prop_Data, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY - non-solid, but can still be shot
		
		decl String:mapname[150];
		GetCurrentMap(mapname, sizeof(mapname));
		SQL_EscapeString(db, mapname, mapname, sizeof(mapname));
		
		decl String:server[50];
		strcopy(server, sizeof(server), "Not Implemented");
		
		new len = 0;
		decl String:buffer[2048];
		len += Format(buffer[len], sizeof(buffer)-len, "INSERT INTO `TF2_AutoBirds` (`locX` ,`locY` ,`locZ` ,`map` ,`server`)");
		len += Format(buffer[len], sizeof(buffer)-len, " VALUES ('%f', '%f', '%f', '%s', '%s');", pos[0], pos[1], pos[2], mapname, server);
		SQL_TQuery(db,SQLErrorCheckCallback, buffer);
		PrintToChat(client, "\x04[\x03AP\x04]\x01 Dove location added to database!");
	}
	return Plugin_Handled;
}

public Action:BreakEgg(client, args)
{
	decl iEntity;
	new Float:EntLoc[3]
	iEntity = GetClientAimTarget(client, false);
	if (iEntity != -1 && iEntity != -2)
	{
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", EntLoc)
		new String:buffer[255]
		PrintToChat(client, "\x04[\x03AP\x04]\x01 Dove location disabled in database!")
		Format(buffer, sizeof(buffer), "UPDATE `TF2_AutoBirds` SET `enable` = '0' WHERE `locX` = '%f' AND `locY` = '%f' AND `locZ` = '%f';", EntLoc[0], EntLoc[1], EntLoc[2])
		SQL_FastQuery(db, buffer);
	}
	return Plugin_Handled;
}

Connect()
{
	if (SQL_CheckConfig("autobirds"))
		SQL_TConnect(Connected, "autobirds");
	else
		SetFailState("Can't find 'autobirds' entry in sourcemod/configs/databases.cfg!");
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error)
		SetFailState("SQL Error:  %s", error);
		return;
	}

	LogMessage("AutoBirds online and connected to database!");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	SQL_CreateTables();
}

SQL_CreateTables()
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `TF2_AutoBirds` (");
	len += Format(query[len], sizeof(query)-len, "`ID` INT(10) NOT NULL AUTO_INCREMENT,");
	len += Format(query[len], sizeof(query)-len, "`locX` VARCHAR(30) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`locY` VARCHAR(30) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`locZ` VARCHAR(30) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`map` VARCHAR(60) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`server` VARCHAR(60) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`enable` tinyint(1) NOT NULL DEFAULT '1',");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`ID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	if (SQL_FastQuery(db, query))
		LogMessage("[AutoBirds] DB queries run, table created");
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
		LogError("SQL Error: %s", error);
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:mapname[150];
	GetCurrentMap(mapname, sizeof(mapname));
	SQL_EscapeString(db, mapname,  mapname, sizeof(mapname));
	new String:buffer[255]
	Format(buffer, sizeof(buffer), "SELECT `locX`, `locY`, `locZ` FROM TF2_AutoBirds WHERE `map` = '%s' AND `enable` = '1';", mapname)
	SQL_TQuery(db, SQL_SpawnBirds, buffer);
	return Plugin_Continue;
}
	
public SQL_SpawnBirds(Handle:owner, Handle:query, const String:error[], any:data)
{	
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
	else 
	{
		/* Process results here!*/
		new Float:pos[3];
		while (SQL_FetchRow(query))
		{
			pos[0] = SQL_FetchFloat(query, 0)
			pos[1] = SQL_FetchFloat(query, 1)
			pos[2] = SQL_FetchFloat(query, 2)

			new Float:angles[3];
			angles[0] = 0.0;
			angles[1] = GetRandomFloat(0.0, 360.0);	//Get a random rotation so birds arent always looking north
			angles[2] = 0.0;
			
			new iDove = CreateEntityByName("entity_bird");
			if(IsValidEntity(iDove))
			{		
				DispatchSpawn(iDove);
				TeleportEntity(iDove, pos, angles, NULL_VECTOR);
			}
		}
	}
}

