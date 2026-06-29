#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "2.2.2"
new Handle:db = INVALID_HANDLE;			/** Database connection */
new Handle:v_RespawnTime = INVALID_HANDLE;

new Float:g_fRespawnTime = 20.0;

public Plugin:myinfo = 
{
	name = "[TF2] Auto Pumpkins",
	author = "DarthNinja",
	description = "Auto-Spawns pumpkins at the start of the round, just like harvest!",
	version = VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_pumpkin_version", VERSION, "Pumpkin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_RespawnTime = CreateConVar("sm_pumpkin_respawntime", "20.0", "How quickly pumpkins respawn.", 0, true, -1.0);
	HookConVarChange(v_RespawnTime, UpdateCvar);

	RegAdminCmd("sm_placepumpkin", SeedPumpkin, ADMFLAG_ROOT);
	RegAdminCmd("sm_createpumpkin", SeedPumpkin, ADMFLAG_ROOT);
	RegAdminCmd("sm_spawnpumpkin", SeedPumpkin, ADMFLAG_ROOT);
	RegAdminCmd("sm_seedpumpkin", SeedPumpkin, ADMFLAG_ROOT);
	RegAdminCmd("sm_deletepumpkin", DelPumpkin, ADMFLAG_ROOT);

	Connect()
	HookEvent("teamplay_round_start", EventRoundStart);
}


public UpdateCvar(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fRespawnTime = StringToFloat(newValue);
}

public Action:SeedPumpkin(client, args)
{

	if(GetEntityCount() >= GetMaxEntities()-64)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	
	if(IsValidEntity(iPumpkin))
	{		
		PrintToChat(client, "\x04[\x03AP\x04]\x01 Pumpkin location added to database!")
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		DispatchSpawn(iPumpkin);
		TeleportEntity(iPumpkin, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(iPumpkin, Prop_Data, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY - non-solid, but can still be shot
		SDKHook(iPumpkin, SDKHook_OnTakeDamage, PumpkinTakeDamage);
		decl String:mapname[150];
		decl String:mapname_esc[150];
		GetCurrentMap(mapname, sizeof(mapname));
		SQL_EscapeString(db, mapname, mapname_esc, sizeof(mapname_esc));
		
		decl String:server[50];
		strcopy(server, sizeof(server), "Not Implemented");
		
		new len = 0;
		decl String:buffer[2048];
		len += Format(buffer[len], sizeof(buffer)-len, "INSERT INTO `TF2_AutoPumpkins` (`locX` ,`locY` ,`locZ` ,`map` ,`server`)");
		len += Format(buffer[len], sizeof(buffer)-len, " VALUES ('%f', '%f', '%f', '%s', '%s');", pos[0], pos[1], pos[2], mapname_esc, server);
		SQL_TQuery(db,SQLErrorCheckCallback, buffer)
	}
	return Plugin_Handled;
}


public Action:DelPumpkin(client, args)
{
	decl iEntity;
	new Float:EntLoc[3];
	iEntity = GetClientAimTarget(client, false);
	if (iEntity != -1 && iEntity != -2)
	{
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", EntLoc)
		new String:buffer[255]
		PrintToChat(client, "\x04[\x03AP\x04]\x01 Pumpkin location deleted from database!")
		Format(buffer, sizeof(buffer), "UPDATE `TF2_AutoPumpkins` SET `enable` = '0' WHERE `locX` = '%f' AND `locY` = '%f' AND `locZ` = '%f';", EntLoc[0], EntLoc[1], EntLoc[2])
		SQL_FastQuery(db, buffer);
	}
	return Plugin_Handled;
}


Connect()
{
	if (SQL_CheckConfig("autopumpkins"))
		SQL_TConnect(Connected, "autopumpkins");
	else
		SetFailState("Can't find 'autopumpkins' entry in sourcemod/configs/databases.cfg!");
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error)
		SetFailState("SQL Error.  See error logs for details.");
		return;
	}

	LogMessage("Auto Pumpkin Spawner online and connected to database!");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	SQL_CreateTables();
}
	
SQL_CreateTables()
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `TF2_AutoPumpkins` (");
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
		LogMessage("[AutoPumpkins] DB queries run, table created");
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogMessage("SQL Error: %s", error);
	}
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	decl String:mapname[50];
	GetCurrentMap(mapname, sizeof(mapname))
	
	new String:buffer[255]
	Format(buffer, sizeof(buffer), "SELECT `locX`, `locY`, `locZ` FROM TF2_AutoPumpkins WHERE `map` = '%s' AND `enable` = '1';", mapname)
	SQL_TQuery(db, SQL_SpawnPumpkins, buffer);
	return Plugin_Continue;
}

public SQL_SpawnPumpkins(Handle:owner, Handle:query, const String:error[], any:data)
{	
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
	else 
	{
		/* Process results here!*/
	 
		while (SQL_FetchRow(query))
		{
			new Float:pos[3];
			pos[0] = SQL_FetchFloat(query, 0)
			pos[1] = SQL_FetchFloat(query, 1)
			pos[2] = SQL_FetchFloat(query, 2)

			new Float:angles[3];
			angles[0] = 0.0;
			angles[1] = GetRandomFloat(0.0, 360.0);
			angles[2] = 0.0;
			
			new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
			if(IsValidEntity(iPumpkin))
			{		
				DispatchSpawn(iPumpkin);
				TeleportEntity(iPumpkin, pos, angles, NULL_VECTOR);
				SDKHook(iPumpkin, SDKHook_OnTakeDamage, PumpkinTakeDamage);
			}
		}
	}
}



//-----------------------------
// respawning code:
//-----------------------------
public Action:PumpkinTakeDamage(pumpkin, &attacker, &inflictor, &Float:damage, &damagetype)
{
	new String:classname[64];
	GetEntityClassname(pumpkin, classname, sizeof(classname));
	if (StrEqual(classname, "tf_pumpkin_bomb", false))	// make sure it is a pumpkin
	{
		SDKUnhook(pumpkin, SDKHook_OnTakeDamage, PumpkinTakeDamage);	//it's gone, remove the hook
		new Float:pos[3];
		GetEntPropVector(pumpkin, Prop_Send, "m_vecOrigin", pos);
		//PrintToChatAll("Pumpkin damaged at: %f|%f|%f", pos[0], pos[1], pos[2])
		if (g_fRespawnTime != -1.0)
		{
			new Handle:pack
			CreateDataTimer(g_fRespawnTime, RespawnPumpkin, pack, TIMER_FLAG_NO_MAPCHANGE);	//cvar to set timer time
			WritePackFloat(pack, pos[0]);
			WritePackFloat(pack, pos[1]);
			WritePackFloat(pack, pos[2]);
		}
	}
}

public Action:RespawnPumpkin(Handle:timer, Handle:pack)
{
	new Float:pos[3];
	ResetPack(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	new Float:angles[3];
	angles[0] = 0.0;
	angles[1] = GetRandomFloat(0.0, 360.0);
	angles[2] = 0.0;
	
	new iPumpkin = CreateEntityByName("tf_pumpkin_bomb");
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		TeleportEntity(iPumpkin, pos, angles, NULL_VECTOR);
		SDKHook(iPumpkin, SDKHook_OnTakeDamage, PumpkinTakeDamage);
	}
}

