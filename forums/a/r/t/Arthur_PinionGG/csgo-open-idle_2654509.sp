#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"
#define UPDATE_URL "http://bin.pinion.gg/bin/openidle/csgo/updatefile.txt"

#include <sourcemod>
#include <cstrike>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#define DMG_GENERIC			0
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)

new Handle: hRunIdleConfig;
new Handle: hForceToTeam;
new Handle: hCustomSpawnsEnabled;
new Handle: hRespawnEnabled;
new Handle: hRespawnDelay;
new Handle: hIdleDamageEnabled;
new Handle: hIdleCheckTimeInitial;
new Handle: hIdleCheckTime;
new Handle: hIdleDamageAmount;
new Handle: hDamageTimer[MAXPLAYERS +1] = INVALID_HANDLE;

new Handle: db = INVALID_HANDLE;			/** Database connection */

new Float:fSpawnLocations[2][50][3];
new iNumSpawnLocations[2] = 0;
new Float:fPlayerSpawnOrigin[MAXPLAYERS +1][3];

public Plugin:myinfo = {
	name = "CS:GO Open Idle",
	author = "Caelan Borowiec",
	description = "Public idle plugin",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/CaelanBorowiec/csgo-idle"
};

public OnPluginStart( ) {
	CreateConVar("sm_openidle_version", PLUGIN_VERSION, "[SM] OpenIdle CSGO Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hRunIdleConfig = CreateConVar( "sm_openidle_runconfig", "1", "Run sourcemod/openidle.serverconfig.cfg at the start of rounds?" );
	hForceToTeam = CreateConVar( "sm_openidle_forceteam", "1", "Set to 0 to disable forcing players to teams." ); // TODO update to set specific team
	hRespawnEnabled = CreateConVar("sm_openidle_respawn_enabled", "1", "set to 0 to disable automatic respawn.");
	hRespawnDelay = CreateConVar("sm_openidle_respawndelay", "5.0", "The number of seconds to wait before respawning a player.");
	hIdleDamageEnabled = CreateConVar("sm_openidle_idledamage_enable", "1", "Set to 0 to disable dealing damage to idle players.");
	hIdleDamageAmount = CreateConVar("sm_openidle_idledamage_amount", "10", "The amount of damage to apply to idle players for each time they are found idle.");
	hIdleCheckTimeInitial = CreateConVar("sm_openidle_idledamage_idletime", "30", "The number of seconds a player must be stationary to be counted as idle.");
	hIdleCheckTime = CreateConVar("sm_openidle_idledamage_frequency", "1", "The number of seconds to wait before damaging an idle player again.");
	hCustomSpawnsEnabled = CreateConVar("sm_openidle_customspawns_enabled", "1", "Set to 0 to disable custom spawns.  Spawns must be placed per map using sm_setspawn.");

	AutoExecConfig(true, "openidle");

	HookEvent( "player_connect_full", Event_OnFullConnect, EventHookMode_Post );
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawned);
	HookEvent("round_start", EventRoundStart);

	RegAdminCmd("sm_setspawn", SetTeleSpawnLocation, ADMFLAG_ROOT);

	Connect();

	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

#if defined _updater_included
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}
#endif

public void OnMapEnd()
{
	iNumSpawnLocations[0] = 0;
	iNumSpawnLocations[1] = 0;
}

public Event_OnFullConnect( Handle:event, const String:name[ ], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	if( client != 0 && IsClientInGame( client ) && !IsFakeClient( client ) )
		CreateTimer( 0.5, AssignTeam, client );
}

public Action: AssignTeam( Handle: timer, any: client )
{
	if( !IsClientInGame( client ) )
		return Plugin_Continue;

	new bool: bForceToTeam = GetConVarBool( hForceToTeam );
	if (!bForceToTeam)
		return Plugin_Handled;

	new iTeamT, iTeamCT;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		new iTeam = GetClientTeam(i);
		if(iTeam == CS_TEAM_T)
			iTeamT++;
		else if(iTeam == CS_TEAM_CT)
			iTeamCT++;
	}

	if( iTeamT <= iTeamCT )	// T less than or equal to CT
		ChangeClientTeam( client, CS_TEAM_T ); // Place on T team
	else // Otherwise, more T team players
		ChangeClientTeam( client, CS_TEAM_CT ); // Put on CT

	CS_RespawnPlayer(client);

	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(hRespawnEnabled))
		CreateTimer(GetConVarFloat(hRespawnDelay), RespawnPlayer, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:RespawnPlayer(Handle:Timer, any:userid)
{
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));

	new client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return Plugin_Continue;

	new team = GetClientTeam(client);
	if(team == CS_TEAM_T || team == CS_TEAM_CT)
		CS_RespawnPlayer(client);

	return Plugin_Continue;
}

public Event_PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientConnected(client) || !IsClientInGame(client))
		return;

	if (GetConVarBool(hCustomSpawnsEnabled))
	{
		new teamindex = GetClientTeam(client);
		if (teamindex == CS_TEAM_T)
			teamindex = 0;
		else if (teamindex == CS_TEAM_CT)
			teamindex = 1;
		else
			return;

		if (iNumSpawnLocations[teamindex] > 0)
		{
			new spawn = GetRandomInt(0, iNumSpawnLocations[teamindex] -1);

			new Float:angles[3];
			angles[0] = 0.0;
			angles[1] = GetRandomFloat(0.0, 360.0);
			angles[2] = 0.0;

			//PrintToServer("Sending player to %f %f %f", fSpawnLocations[teamindex][spawn][0], fSpawnLocations[teamindex][spawn][1], fSpawnLocations[teamindex][spawn][2]);
			TeleportEntity(client, fSpawnLocations[teamindex][spawn], angles, NULL_VECTOR);
		}
	}

	if (GetConVarBool(hIdleDamageEnabled))
	{
		fPlayerSpawnOrigin[client][0] = 0.0;
		fPlayerSpawnOrigin[client][1] = 0.0;
		fPlayerSpawnOrigin[client][2] = 0.0;
		hDamageTimer[client] = CreateTimer(0.5, CheckIdle, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
	}

	return;
}

// Checks to see if a player is idle, and do damage if they are.
public Action:CheckIdle(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	//Not valid client, already dead, or bot:
	if (!GetConVarBool(hIdleDamageEnabled) || !client || !IsPlayerAlive(client) || IsFakeClient(client))
	{
		hDamageTimer[client] = CreateTimer(10.0, CheckIdle, userid, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	KillTimer(hDamageTimer[client]);

	new Float:pos[3];
	GetClientAbsOrigin(client, pos);

	if (fPlayerSpawnOrigin[client][0] == pos[0] && fPlayerSpawnOrigin[client][1] == pos[1] && fPlayerSpawnOrigin[client][2] == pos[2])
	{
		// they didn't move, lets deal damage
		new iAttackerTeam = 0;
		if (GetClientTeam(client) == CS_TEAM_T)
			iAttackerTeam = CS_TEAM_CT;
		else
			iAttackerTeam = CS_TEAM_T;

		new attacker;
		do
		{
			attacker = GetRandomInt(1, MaxClients);
		}
		while(!IsClientInGame(attacker) || GetClientTeam(attacker) != iAttackerTeam);

		DealDamage(client, GetConVarInt(hIdleDamageAmount), attacker);

		//Check again faster
		hDamageTimer[client] = CreateTimer(GetConVarFloat(hIdleCheckTime), CheckIdle, userid, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	fPlayerSpawnOrigin[client] = pos;
	hDamageTimer[client] = CreateTimer(GetConVarFloat(hIdleCheckTimeInitial), CheckIdle, userid, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

// At the start of a round, update and cache spawn locations
public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:mapname[50];
	decl String:mapname_esc[150];
	GetCurrentMap(mapname, sizeof(mapname));
	SQL_EscapeString(db, mapname, mapname_esc, sizeof(mapname_esc));

	if (GetConVarBool(hRunIdleConfig))
		ServerCommand("exec sourcemod/openidle.serverconfig.cfg");

	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `locX`, `locY`, `locZ`, `team` FROM TeleportSpawn WHERE `map` = '%s' AND `enable` = '1';", mapname_esc);
	SQL_TQuery(db, SQL_CacheSpawns, buffer);
	return Plugin_Continue;
}

// Cache existing spawn locations
public SQL_CacheSpawns(Handle:owner, Handle:query, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
	else
	{
		new iTcount = 0;
		new iCTcount = 0;
		//PrintToServer("Retrieving spawn locations");
		while (SQL_FetchRow(query))
		{
			new Float:pos[3];
			pos[0] = SQL_FetchFloat(query, 0);
			pos[1] = SQL_FetchFloat(query, 1);
			pos[2] = SQL_FetchFloat(query, 2);
			new iTeam = SQL_FetchInt(query, 3);

			if (iTeam == CS_TEAM_T)
			{
				fSpawnLocations[0][iTcount] = pos;
				iTcount++;
			}
			else
			{
				fSpawnLocations[1][iCTcount] = pos;
				iCTcount++;
			}
		}

		iNumSpawnLocations[0] = iTcount;
		iNumSpawnLocations[1] = iCTcount;
	}
}

// Create a new spawn location
public Action:SetTeleSpawnLocation(client, args)
{
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "You must be alive to do this");
		return Plugin_Handled;
	}

	decl String:teamName[50];
	GetCmdArg(1, teamName, sizeof(teamName));
	new iTeam;
	if (StrEqual(teamName, "CT", false))
		iTeam = CS_TEAM_CT;
	else
		iTeam = CS_TEAM_T;

	if(GetEntityCount() >= GetMaxEntities()-64)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkins. Change maps.");
		return Plugin_Handled;
	}

	new iChicken = CreateEntityByName("chicken");

	if(IsValidEntity(iChicken))
	{
		PrintToChat(client, "Spawn location added to database!");
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		DispatchSpawn(iChicken);
		TeleportEntity(iChicken, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(iChicken, Prop_Data, "m_CollisionGroup", 17); // COLLISION_GROUP_PUSHAWAY - non-solid, but can still be shot
		decl String:mapname[75];
		decl String:mapname_esc[150];
		GetCurrentMap(mapname, sizeof(mapname));
		SQL_EscapeString(db, mapname, mapname_esc, sizeof(mapname_esc));

		decl String:server[50];
		decl String:server_esc[100];
		GetHostName(server, sizeof(server));
		SQL_EscapeString(db, server, server_esc, sizeof(server_esc));

		new len = 0;
		decl String:buffer[2048];
		len += Format(buffer[len], sizeof(buffer)-len, "INSERT INTO `TeleportSpawn` (`locX`, `locY`, `locZ`, `team`, `map`, `server`)");
		len += Format(buffer[len], sizeof(buffer)-len, " VALUES ('%f', '%f', '%f', %d, '%s', '%s');", pos[0], pos[1], pos[2], iTeam, mapname_esc, server_esc);
		SQL_TQuery(db,SQLErrorCheckCallback, buffer);
	}
	return Plugin_Handled;
}

// Start our SQL connection
Connect()
{
	if (SQL_CheckConfig("openidle"))
		SQL_TConnect(Connected, "openidle");
	else
		SetFailState("Can't find 'openidle' entry in sourcemod/configs/databases.cfg!");
}

// Database connection complete or failed
public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error);
		SetFailState("SQL Error.  See error logs for details.");
		return;
	}

	LogMessage("OpenIdle online and connected to database!");
	db = hndl;
	SQL_CreateTables();
}

// Create SQL/SQLite table if it does not exist.
SQL_CreateTables()
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `TeleportSpawn` (");
	len += Format(query[len], sizeof(query)-len, "`locX` VARCHAR(30) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`locY` VARCHAR(30) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`locZ` VARCHAR(30) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`team` tinyint(1) NOT NULL DEFAULT '1',");
	len += Format(query[len], sizeof(query)-len, "`map` VARCHAR(60) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`server` VARCHAR(60) NOT NULL DEFAULT '0',");
	len += Format(query[len], sizeof(query)-len, "`enable` tinyint(1) NOT NULL DEFAULT '1'");
	len += Format(query[len], sizeof(query)-len, ");");
	if (SQL_FastQuery(db, query))
		LogMessage("TeleportSpawn table created if it did not exist");
	else
	{
		decl String:error[128];
		SQL_GetError(db, error, sizeof(error));
		LogError("Failed creating database table: %s", error);
	}
}

// Check and report SQL errors
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}

// Deals damage to a player on demand, with a number of extra options.
// https://forums.alliedmods.net/showthread.php?t=111684
DealDamage(victim, damage, attacker=0, dmg_type=DMG_GENERIC, String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

// Returns the name of the server
GetHostName(String:str[], size)
{
    static Handle:hHostName;
    if(hHostName == INVALID_HANDLE)
    {
        if( (hHostName = FindConVar("hostname")) == INVALID_HANDLE)
        {
            return;
        }
    }
    GetConVarString(hHostName, str, size);
}
