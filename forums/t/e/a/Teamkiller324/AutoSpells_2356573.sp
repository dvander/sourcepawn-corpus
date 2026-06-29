#include	<sourcemod>
#include	<sdktools>
#include	<sdkhooks>

#pragma		semicolon	1
#pragma		newdecls	required

#define		VERSION		"1.0.0"
#define		CHAT_TAG	"\x04[\x03AutoSpell\x04]\x01"
Handle		db;			/** Database connection */
ConVar		v_RespawnTime;

float g_fRespawnTime = 20.0;

Plugin myinfo = 
{
	name = "[TF2] Auto Spells",
	author = "Tk /id/Teamkiller324",
	description = "Auto-Spawns Spells at the start of the round!",
	version = VERSION,
	url = "http://steamcommunity.com/id/Teamkiller324"
}

public void OnPluginStart()
{
	CreateConVar("sm_spell_version",		VERSION, "Spell Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_RespawnTime		= CreateConVar("sm_spell_respawntime", "20.0", "How quickly spells respawn.", _, true, -1.0);
	HookConVarChange(v_RespawnTime, UpdateCvar);

	RegAdminCmd("sm_spawnspell",	SpawnSpell,		ADMFLAG_ROOT);
	RegAdminCmd("sm_deletespell",	DeleteSpell,	ADMFLAG_ROOT);

	Connect();
	HookEvent("teamplay_round_start", EventRoundStart);
}

void UpdateCvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fRespawnTime = StringToFloat(newValue);
}

Action SpawnSpell(int client, int args)
{

	if(GetEntityCount() >= GetMaxEntities()-64)
	{
		PrintToChat(client, "%s Entity limit is reached. Can't spawn anymore Spells. Change Map(s).", CHAT_TAG);
		return Plugin_Handled;
	}
	
	int iPumpkin = CreateEntityByName("tf_spell_pickup");
	
	if(IsValidEntity(iPumpkin))
	{		
		PrintToChat(client, "%s Spell location added to database!");
		float pos[3];
		GetClientAbsOrigin(client, pos);
		DispatchSpawn(iPumpkin);
		TeleportEntity(iPumpkin, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(iPumpkin, Prop_Data, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY - non-solid, but can still be shot
		SDKHook(iPumpkin, SDKHook_OnTakeDamage, SpellTakeDamage);
		char mapname[150], mapname_esc[150];
		GetCurrentMap(mapname, sizeof(mapname));
		SQL_EscapeString(db, mapname, mapname_esc, sizeof(mapname_esc));
		
		char server[50];
		strcopy(server, sizeof(server), "Not Implemented");
		
		int len = 0;
		char buffer[2048];
		len += Format(buffer[len], sizeof(buffer)-len, "INSERT INTO `TF2_AutoSpells` (`locX` ,`locY` ,`locZ` ,`map` ,`server`)");
		len += Format(buffer[len], sizeof(buffer)-len, " VALUES ('%f', '%f', '%f', '%s', '%s');", pos[0], pos[1], pos[2], mapname_esc, server);
		SQL_TQuery(db,SQLErrorCheckCallback, buffer);
	}
	return Plugin_Handled;
}


Action DeleteSpell(int client, int args)
{
	int iEntity;
	float EntLoc[3];
	iEntity = GetClientAimTarget(client, false);
	if (iEntity != -1 && iEntity != -2)
	{
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", EntLoc);
		char buffer[255];
		PrintToChat(client, "%s Spell location deleted from database!", CHAT_TAG);
		Format(buffer, sizeof(buffer), "UPDATE `TF2_AutoSpells` SET `enable` = '0' WHERE `locX` = '%f' AND `locY` = '%f' AND `locZ` = '%f';", EntLoc[0], EntLoc[1], EntLoc[2]);
		SQL_FastQuery(db, buffer);
	}
	return Plugin_Handled;
}


void Connect()
{
	if (SQL_CheckConfig("autospells"))
		SQL_TConnect(Connected, "autospells");
	else
		SetFailState("Can't find 'autospells' entry in sourcemod/configs/databases.cfg!");
}

void Connected(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error);
		SetFailState("SQL Error.  See error logs for details.");
		return;
	}

	LogMessage("Auto Spells online and connected to database!");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	SQL_CreateTables();
}
	
void SQL_CreateTables()
{
	int len = 0;
	char query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `TF2_AutoSpells` (");
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
		LogMessage("%s DB queries run, table created", CHAT_TAG);
}

void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!StrEqual("", error))
		LogMessage("SQL Error: %s", error);
}

Action EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	char mapname[50];
	GetCurrentMap(mapname, sizeof(mapname));
	
	char buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `locX`, `locY`, `locZ` FROM TF2_AutoSpells WHERE `map` = '%s' AND `enable` = '1';", mapname);
	SQL_TQuery(db, SQL_SpawnPumpkins, buffer);
	return Plugin_Continue;
}

void SQL_SpawnPumpkins(Handle owner, Handle query, const char[] error, any data)
{	
	if (!StrEqual("", error))
		LogError("SQL Error: %s", error);
	else 
	{
		/* Process results here!*/
	 
		while (SQL_FetchRow(query))
		{
			float pos[3];
			pos[0] = SQL_FetchFloat(query, 0);
			pos[1] = SQL_FetchFloat(query, 1);
			pos[2] = SQL_FetchFloat(query, 2);

			float angles[3];
			angles[0] = 0.0;
			angles[1] = GetRandomFloat(0.0, 360.0);
			angles[2] = 0.0;
			
			int iPumpkin = CreateEntityByName("tf_spell_pickup");
			if(IsValidEntity(iPumpkin))
			{		
				DispatchSpawn(iPumpkin);
				TeleportEntity(iPumpkin, pos, angles, NULL_VECTOR);
				SDKHook(iPumpkin, SDKHook_OnTakeDamage, SpellTakeDamage);
			}
		}
	}
}



//-----------------------------
// respawning code:
//-----------------------------
Action SpellTakeDamage(int pumpkin, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	char classname[64];
	GetEntityClassname(pumpkin, classname, sizeof(classname));
	if (StrEqual(classname, "tf_spell_pickup", false))	
	{
		SDKUnhook(pumpkin, SDKHook_OnTakeDamage, SpellTakeDamage);	//it's gone, remove the hook
		float pos[3];
		GetEntPropVector(pumpkin, Prop_Send, "m_vecOrigin", pos);
		//PrintToChatAll("Pumpkin damaged at: %f|%f|%f", pos[0], pos[1], pos[2])
		if (g_fRespawnTime != -1.0)
		{
			Handle pack;
			CreateDataTimer(g_fRespawnTime, RespawnSpell, pack, TIMER_FLAG_NO_MAPCHANGE);	//cvar to set timer time
			WritePackFloat(pack, pos[0]);
			WritePackFloat(pack, pos[1]);
			WritePackFloat(pack, pos[2]);
		}
	}
}

Action RespawnSpell(Handle timer, Handle pack)
{
	float pos[3];
	ResetPack(pack);
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);
	
	float angles[3];
	angles[0] = 0.0;
	angles[1] = GetRandomFloat(0.0, 360.0);
	angles[2] = 0.0;
	
	int iPumpkin = CreateEntityByName("tf_spell_pickup");
	if(IsValidEntity(iPumpkin))
	{		
		DispatchSpawn(iPumpkin);
		TeleportEntity(iPumpkin, pos, angles, NULL_VECTOR);
		SDKHook(iPumpkin, SDKHook_OnTakeDamage, SpellTakeDamage);
	}
}

