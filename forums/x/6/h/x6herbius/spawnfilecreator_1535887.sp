#include <sourcemod>
#include <keyvalues>
#include <sdktools>
#include <sdkhooks>
#include <tf2>

#pragma semicolon	1

#define PLUGIN_NAME 		"Deathmatch Spawn File Creator [HOTFIX]"
#define PLUGIN_AUTHOR		"[X6] Herbius"
#define PLUGIN_DESCRIPTION	"Creates and handles custom deathmatch spawns for Team Fortress 2."
#define PLUGIN_VERSION		"2.1.0.0"

#define STATE_DISABLED		2
#define STATE_NOT_IN_ROUND	1

// Teams
#define TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_RED		2
#define TEAM_BLUE		3

#define MAX_SPAWN_POINTS	128
#define MAX_FILTERS			8

#define SND_SUCCESS		"buttons/blip1.wav"
#define SND_FAIL		"buttons/button8.wav"

#define PARTICLE_BLUE	"teleporter_blue_exit"
#define PARTICLE_RED	"teleporter_red_exit"

// Variable declarations:
new g_PluginState;						// Holds the flags for the global plugin state.

new Float:Angles[MAX_SPAWN_POINTS][3];
new Float:Position[MAX_SPAWN_POINTS][3];
new TeamNum[MAX_SPAWN_POINTS];
new Entities[MAX_SPAWN_POINTS] = {-1, ...};
new NumPoints;
new String:FilePath[192];
//new Filters[MAX_FILTERS] = {-1, ...};
//new numFilters;
new Doors[32] = {-1, ...};
new numDoors;

new Handle:cv_PluginEnabled = INVALID_HANDLE;	// Enables or disables the plugin.
new Handle:cv_SpawnRadius = INVALID_HANDLE;		// Radius around spawn point in which to destroy objects/kill clients.
new Handle:cv_Particles = INVALID_HANDLE;		// Enables or disables spawn point markers.
new Handle:cv_Resupply = INVALID_HANDLE;		// If 0, resupply cabinets will be disabled.
new Handle:cv_Respawn = INVALID_HANDLE;			// If 0, respawn rooms will be disabled.
new Handle:cv_RespawnVis = INVALID_HANDLE;		// If 0, respawn room visualisers will be disabled.
new Handle:cv_Doors = INVALID_HANDLE;			// If 1, doors in the map will be forced open once a second.

new Handle:DoorTimer = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1535887"
}

public OnPluginStart()
{
	LogMessage("===== %s v%s =====", PLUGIN_NAME, PLUGIN_VERSION);
	
	CreateConVar("dmspawn_version", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	
	cv_PluginEnabled  = CreateConVar("dmspawn_enabled",
												"1",
												"Enables or disables the plugin.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_SpawnRadius  = CreateConVar("dmspawn_spawn_radius",
												"24",
												"Radius around spawn point in which to destroy objects/kill clients.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												1.0,
												true,
												128.0);
	
	cv_Particles  = CreateConVar("dmspawn_spawn_markers",
												"1",
												"Enables or disables spawn point markers.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_Resupply  = CreateConVar("dmspawn_resupply_enabled",
												"0",
												"If 0, resupply cabinets will be disabled.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_Respawn = CreateConVar("dmspawn_respawn_enabled",
												"0",
												"If 0, respawn rooms will be disabled.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_RespawnVis = CreateConVar("dmspawn_respawn_visualizers_enabled",
												"0",
												"If 0, respawn room visualisers will be disabled.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_Doors = CreateConVar("dmspawn_door_fix",
												"1",
												"If 1, doors in the map will be forced open once a second.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	AutoExecConfig(true, "dmspawn", "sourcemod/dmspawn");
	
	RegAdminCmd("dmspawn_add",		Command_AddSpawn, ADMFLAG_CONFIG,		"Adds a spawn point at the player's current position.");
	RegAdminCmd("dmspawn_remove",	Command_RemoveSpawn, ADMFLAG_CONFIG,	"Removes spawn point of the specified number; 'all' removes all points, no argument removes closest point.");
	RegAdminCmd("dmspawn_save",		Command_SaveSpawns, ADMFLAG_CONFIG,		"Saves current spawn points to scripts/dmspawn.");
	RegAdminCmd("dmspawn_reload",	Command_LoadSpawns, ADMFLAG_CONFIG,		"Reloads map's spawn points from file.");
	RegAdminCmd("dmspawn_dump",		Command_DumpAll, ADMFLAG_CONFIG,		"dmspawn_dump [min] [max]: Dumps info about spawns numbered between min and max.");
	
	// Update the plugin state to reflect the cvar after autoexec.
	PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
	CheckParticles(GetConVarBool(cv_Particles));
	
	HookConVarChange(cv_PluginEnabled, CvarChange);
	HookConVarChange(cv_Particles, CvarChange);
	HookConVarChange(cv_Resupply, CvarChange);
	HookConVarChange(cv_Respawn, CvarChange);
	HookConVarChange(cv_RespawnVis, CvarChange);
	
	HookEventEx("teamplay_round_start",		Event_RoundStart,		EventHookMode_Post);
	HookEventEx("teamplay_round_win",		Event_RoundWin,			EventHookMode_Post);
	HookEventEx("teamplay_round_stalemate",	Event_RoundStalemate,	EventHookMode_Post);
	HookEventEx("player_spawn",				Event_Spawn,			EventHookMode_Post);
	
	// Spawn points are loaded on MapStart which is called immediately after this if the plugins is loaded on an active server.
}

public OnMapStart()
{
	PrecacheSound(SND_SUCCESS, true);
	PrecacheSound(SND_FAIL, true);
	
	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	Format(FilePath, sizeof(FilePath), "scripts/dmspawn/%s_spawns.txt", MapName);
	
	LogMessage("File path for map: %s", FilePath);
	
	// Get the info and stick it into our global variables.
	RetrieveSpawnInfo(FilePath);
	
	// Find any filters.
	/*new i = -1;
	while ( (i = FindEntityByClassname(i, "filter_activator_tfteam")) != -1 )
	{
		if ( numFilters >= MAX_FILTERS )
		{
			LogMessage("Map has more than the maximum number of team filters!");
			break;
		}
		
		Filters[numFilters] = i;
		numFilters++;
		
		LogMessage("Team filter found at index %d.", i);
	}*/
	
	if ( NumPoints < 1 ) return;
	
	// Kill all entities that shouldn't exist.
	KillEntities();
	
	numDoors = 0;
	new i = -1;
	while ( (i = FindEntityByClassname(i, "func_door")) != -1 )
	{
		LogMessage("Func_door recorded at index %d", i);
		Doors[numDoors] = EntIndexToEntRef(i);
		numDoors++;
	}
	
	if ( DoorTimer == INVALID_HANDLE ) CreateTimer(1.0, OpenDoors, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	// Clear out all spawn point info.
	ClearAllIndices();
	
	FilePath[0] = '\0';
	
	for ( new i = 0; i < 32; i++ )
	{
		Doors[i] = -1;
	}
	
	numDoors = 0;
	
	if ( DoorTimer != INVALID_HANDLE )
	{
		KillTimer(DoorTimer);
		DoorTimer = INVALID_HANDLE;
	}
}

public OnPluginEnd()
{
	// Clean up entities just in case we get reloaded.
	ClearAllIndices();
}

/*	Checks which ConVar has changed and does the relevant things.	*/
public CvarChange( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	if		( convar == cv_PluginEnabled )	PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
	else if ( convar == cv_Particles )		CheckParticles(GetConVarBool(cv_Particles));
	else if ( convar == cv_Resupply )		Resupply(GetConVarBool(cv_Resupply));
	else if ( convar == cv_Respawn )		RespawnRooms(GetConVarBool(cv_Respawn));
	else if ( convar == cv_RespawnVis )		TeamVis(GetConVarBool(cv_RespawnVis));
}

/*	Sets the enabled/disabled state of the plugin and restarts the map.
	Passing true enables, false disables.	*/
stock PluginEnabledStateChanged(bool:b_state)
{
	if ( b_state )
	{
		g_PluginState &= ~STATE_DISABLED;	// Clear the disabled flag.
	}
	else
	{
		g_PluginState |= STATE_DISABLED;	// Set the disabled flag.
	}
	
	// Update the state of entities which depend on the state of the plugin.
	KillEntities();
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )	// If now disabled, kill all spawn points.
	{
		ClearAllIndices();
	}
	else	// If enabled, reload spawn points.
	{
		RetrieveSpawnInfo(FilePath);
	}
}

stock CheckParticles(enable)
{
	for ( new i = 0; i < NumPoints; i++ )
	{
		if ( g_PluginState & STATE_DISABLED != STATE_DISABLED && enable )	// Create particle effects if the plugin is not disabled.
		{
			new ent = EntRefToEntIndex(Entities[i]);
			
			if ( IsValidEntity(ent) )	// Stored entity ref is valid.
			{
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Start");
			}
			else	// Entity is invalid, create a new one.
			{
				if ( TeamNum[i] == TEAM_RED )
				{
					ent = CreateParticle(PARTICLE_RED, Position[i]);
				}
				else if ( TeamNum[i] == TEAM_BLUE )
				{
					ent = CreateParticle(PARTICLE_BLUE, Position[i]);
				}
				
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Start");
				
				Entities[i] = EntIndexToEntRef(ent);
			}
		}
		else	// Destroy particle effects
		{
			if ( Entities[i] == -1 ) continue;	// Entity is invalid, leave it.
			
			// Entity is valid, kill it
			new ent = EntRefToEntIndex(Entities[i]);
			
			if ( IsValidEntity(ent) )
			{
				AcceptEntityInput(ent, "Stop");
				AcceptEntityInput(ent, "Kill");
			}
			
			Entities[i] = -1;
		}
	}
}

/*	Called when a new round begins.	*/
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PluginState &= ~STATE_NOT_IN_ROUND;
	
	numDoors = 0;
	new i = -1;
	while ( (i = FindEntityByClassname(i, "func_door")) != -1 )
	{
		LogMessage("Func_door recorded at index %d", i);
		Doors[numDoors] = EntIndexToEntRef(i);
		numDoors++;
	}
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED ) return;
	
	if ( NumPoints < 1 ) return;
	
	KillEntities();
	CheckParticles(GetConVarBool(cv_Particles));
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PluginState |= STATE_NOT_IN_ROUND;
}

public Event_RoundStalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PluginState |= STATE_NOT_IN_ROUND;
}

/*	Called when a player spawns.	*/
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED ) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	// Choose a random spawn index to teleport the client to.
	if ( NumPoints > 0 && client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		// Build a list of points on the same team as the client.
		new Spawns[NumPoints];
		new validSpawns = 0;
		
		for ( new j = 0; j < NumPoints; j++ )
		{
			if ( TeamNum[j] == team )
			{
				Spawns[validSpawns] = j;
				validSpawns++;
			}
		}
		
		new i;
		if ( validSpawns < 1 ) i = GetRandomInt(0, NumPoints-1);	// If there are spawns on the client's team, spawn anywhere.
		else i = Spawns[GetRandomInt(0, validSpawns-1)];			// Else choose a random team spawn.
		
		// Firstly, check to see if there is any client or building within the specified radius of the spawn point.
		// NOTE: The following is hacky because the radius ignores walls/objects/etc.
		new Float:SpawnRadius = GetConVarFloat(cv_SpawnRadius);
		
		for ( new ClientSearch = 1; ClientSearch <= MaxClients; ClientSearch++ )
		{
			if ( IsClientInGame(ClientSearch) )
			{
				new Float:ClOrigin[3];
				GetClientAbsOrigin(ClientSearch, ClOrigin);
				
				// If the client is near enough:
				if ( GetVectorDistance(ClOrigin, Position[i]) <= SpawnRadius && GetClientTeam(ClientSearch) != GetClientTeam(client) && GetClientTeam(ClientSearch) > TEAM_SPECTATOR ) ForcePlayerSuicide(ClientSearch);
			}
		}
		
		new BuildingSearch = -1;
		while ( (BuildingSearch = FindEntityByClassname(BuildingSearch, "obj_sentrygun")) != -1 )
		{
			new Float:EntOrigin[3], BuildingTeam;
			GetEntPropVector(BuildingSearch, Prop_Send, "m_vecOrigin", EntOrigin);
			BuildingTeam = GetEntProp(BuildingSearch, Prop_Send, "m_iTeamNum");
			
			// If the building is near enough:
			if ( GetVectorDistance(EntOrigin, Position[i]) <= SpawnRadius && BuildingTeam != GetClientTeam(client) )
			{
				SetVariantInt( GetEntProp(BuildingSearch, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(BuildingSearch, "RemoveHealth");
				AcceptEntityInput(BuildingSearch, "Kill");
			}
		}
		
		BuildingSearch = -1;
		while ( (BuildingSearch = FindEntityByClassname(BuildingSearch, "obj_dispenser")) != -1 )
		{
			new Float:EntOrigin[3], BuildingTeam;
			GetEntPropVector(BuildingSearch, Prop_Send, "m_vecOrigin", EntOrigin);
			BuildingTeam = GetEntProp(BuildingSearch, Prop_Send, "m_iTeamNum");
			
			// If the building is near enough:
			if ( GetVectorDistance(EntOrigin, Position[i]) <= SpawnRadius && BuildingTeam != GetClientTeam(client) )
			{
				SetVariantInt( GetEntProp(BuildingSearch, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(BuildingSearch, "RemoveHealth");
				AcceptEntityInput(BuildingSearch, "Kill");
			}
		}
		
		BuildingSearch = -1;
		while ( (BuildingSearch = FindEntityByClassname(BuildingSearch, "obj_teleporter")) != -1 )
		{
			new Float:EntOrigin[3], BuildingTeam;
			GetEntPropVector(BuildingSearch, Prop_Send, "m_vecOrigin", EntOrigin);
			BuildingTeam = GetEntProp(BuildingSearch, Prop_Send, "m_iTeamNum");
			
			// If the building is near enough:
			if ( GetVectorDistance(EntOrigin, Position[i]) <= SpawnRadius && BuildingTeam != GetClientTeam(client) )
			{
				// Set up a trace to see if anything is in the way.
				SetVariantInt( GetEntProp(BuildingSearch, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(BuildingSearch, "RemoveHealth");
				AcceptEntityInput(BuildingSearch, "Kill");
			}
		}
		
		TeleportEntity(client, Position[i], Angles[i], NULL_VECTOR);
	}
}

ClearAllIndices()
{
	NumPoints = 0;
	
	for ( new i = 0; i < MAX_SPAWN_POINTS; i++ )
	{
		Angles[i][0] = 0.0;
		Angles[i][1] = 0.0;
		Angles[i][2] = 0.0;
		
		Position[i][0] = 0.0;
		Position[i][1] = 0.0;
		Position[i][2] = 0.0;
		
		TeamNum[i] = 0;
		
		new ent = EntRefToEntIndex(Entities[i]);
		if ( IsValidEntity(ent) )
		{
			AcceptEntityInput(ent, "Stop");
			AcceptEntityInput(ent, "Kill");
		}
		
		Entities[i] = -1;
	}
}

/*	Parses the spawn info file and puts the values into the global variables.
	Returns true on success, false on failure.	*/
RetrieveSpawnInfo(String:s_FilePath[])
{	
	new Handle:kv = CreateKeyValues("spawns");
	
	if ( kv == INVALID_HANDLE )
	{
		LogMessage("Could not create keyvalues tree to import spawn point information.");
		return 1;
	}
	
	if ( !FileToKeyValues(kv, s_FilePath) )
	{
		LogMessage("No spawns file %s found.", s_FilePath);
		return 2;
	}
	
	LogMessage("Spawn point file %s loaded successfully.", s_FilePath);
	
	ClearAllIndices();
	
	if ( !KvGotoFirstSubKey(kv) )	// If there are no sub-keys:
		{
			LogMessage("No first key found.");
		}
	else	// If there are sub-keys:
	{
		new Float:vAngles[3];
		new Float:vPosition[3];
		new Team;
		new SwitchNum = TEAM_RED;
		
		do
		{
			KvGetVector(kv, "angles", vAngles);
			Team = KvGetNum(kv, "TeamNum", SwitchNum);
			KvGetVector(kv, "position", vPosition);
			
			if ( (Team == TEAM_RED || Team == TEAM_BLUE) && NumPoints < MAX_SPAWN_POINTS )	// If the spawn formatting is valid:
			{
				// Put the data into the global variables.
				TeamNum[NumPoints] = Team;
				Angles[NumPoints] = vAngles;
				Position[NumPoints] = vPosition;
				
				LogMessage("Spawn point %d: team %d, pos %f %f %f, ang %f %f %f", NumPoints, TeamNum[NumPoints],
							Position[NumPoints][0], Position[NumPoints][1], Position[NumPoints][2],
							Angles[NumPoints][0], Angles[NumPoints][1], Angles[NumPoints][2]);
				
				NumPoints++;
			}
			
			vAngles[0] = 0.0;
			vAngles[1] = 0.0;
			vAngles[2] = 0.0;
			vPosition[0] = 0.0;
			vPosition[1] = 0.0;
			vPosition[2] = 0.0;
			Team = 0;
			
			if ( SwitchNum == TEAM_RED ) SwitchNum = TEAM_BLUE;
			else SwitchNum = TEAM_RED;
			
		} while ( KvGotoNextKey(kv) );	// Increment NumPoints while the next key exists.
	}
	
	// Now all data is held in the global arrays.
	CloseHandle(kv);
	kv = INVALID_HANDLE;
	
	CheckParticles(GetConVarBool(cv_Particles));
	
	LogMessage("Number of spawns in file: %d", NumPoints);
	LogMessage("All spawns are loaded.");
	
	return 0;
}

stock KillEntities()
{
	Resupply(GetConVarBool(cv_Resupply));
	RespawnRooms(GetConVarBool(cv_Respawn));
	TeamVis(GetConVarBool(cv_RespawnVis));
}

stock Resupply(bool:enable)
{
	new i = -1;
	
	while ( (i = FindEntityByClassname(i, "func_regenerate")) != -1 )
	{
		if ( g_PluginState & STATE_DISABLED == STATE_DISABLED || enable )
		{
			AcceptEntityInput(i, "Enable");
			LogMessage("Resupply locker at index %d enabled.", i);
		}
		else
		{
			AcceptEntityInput(i, "Disable");
			LogMessage("Resupply locker at index %d disabled.", i);
		}
	}
}

stock RespawnRooms(bool:enable)
{
	new i = -1;
	
	while ( (i = FindEntityByClassname(i, "func_respawnroom")) != -1 )
	{
		if ( g_PluginState & STATE_DISABLED == STATE_DISABLED || enable )
		{
			AcceptEntityInput(i, "Enable");
			LogMessage("func_respawnroom at index %d enabled.", i);
		}
		else
		{
			AcceptEntityInput(i, "Disable");
			LogMessage("func_respawnroom at index %d disabled.", i);
		}
	}
}

stock TeamVis(bool:enable)
{
	new i = -1;
	
	while ( (i = FindEntityByClassname(i, "func_respawnroomvisualizer")) != -1 )
	{
		if ( enable )
		{
			AcceptEntityInput(i, "Enable");
			LogMessage("func_respawnroomvisualizer at index %d enabled.", i);
		}
		else
		{
			AcceptEntityInput(i, "Disable");
			LogMessage("func_respawnroomvisualizer at index %d disabled.", i);
		}
	}
}

/*	Adds a spawn at the position of the specified client and for the specified team.	*/
stock AddSpawn(client, team)
{
	if ( NumPoints >= MAX_SPAWN_POINTS ) return 0;
	
	// Add a new spawn in the next index.
	new Float:pos[3], Float:ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	
	// Ignore pitch and roll
	ang[0] = 0.0;
	ang[2] = 0.0;
	
	TeamNum[NumPoints] = team;
	Position[NumPoints] = pos;
	Angles[NumPoints] = ang;
	
	NumPoints++;
	
	CheckParticles(GetConVarBool(cv_Particles));
	
	return NumPoints;
}

/*	Removes the spawn at the specified array index.	*/
stock RemoveSpawn(client, index)
{
	if ( index == -1 )	// If index == -1, remove all.
	{
		ClearAllIndices();
		
		ShowActivity(client, "All spawn points removed.");
		
		return 0;
	}
	
	if ( NumPoints < 1 ) return 1;
	
	// Find the closest spawn to us.
	new spawn = -1;
	new Float:dist = 99999.0;
	
	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	
	for ( new i = 0; i < NumPoints; i++ )
	{
		new Float:tdist = GetVectorDistance(Position[i], ClientPos);
		
		if ( tdist < dist && tdist <= 64.0 )
		{
			spawn = i;
			dist = tdist;
		}
	}
	
	if ( index >= 0 ) spawn = index;
	if ( spawn < 0 ) return 2;
	
	// Kill any particles before we remove array entries.
	new ent = EntRefToEntIndex(Entities[spawn]);
	if ( IsValidEntity(ent) )
	{
		AcceptEntityInput(ent, "Stop");
		AcceptEntityInput(ent, "Kill");
	}
	
	// Shift all the information down in the arrays.
	for ( new shift = (spawn + 1); shift < NumPoints; shift++ )
	{
		// Each time, shift will point to the information in the next index on.
		// Move this information to the index (shift - 1).
		Angles[shift-1][0] = Angles[shift][0];
		Angles[shift-1][1] = Angles[shift][1];
		Angles[shift-1][2] = Angles[shift][2];
		
		Position[shift-1][0] = Position[shift-1][0];
		Position[shift-1][1] = Position[shift-1][1];
		Position[shift-1][2] = Position[shift-1][2];
		
		TeamNum[shift-1] = TeamNum[shift];
		Entities[shift-1] = Entities[shift];
	}
	
	// We're at the last index which is now redundant.
	// Remove all the information at this index.
	Angles[NumPoints-1][0] = 0.0;
	Angles[NumPoints-1][1] = 0.0;
	Angles[NumPoints-1][2] = 0.0;
	
	Position[NumPoints-1][0] = 0.0;
	Position[NumPoints-1][1] = 0.0;
	Position[NumPoints-1][2] = 0.0;
	
	TeamNum[NumPoints-1] = 0;
	Entities[NumPoints-1] = -1;
	
	NumPoints--;	// Decrement NumPoints now we've lost a spawn.
	
	ShowActivity(client, "Spawn point %d removed. Spawns have been renumbered.", spawn+1);
	
	return 0;
}

stock bool:SaveSpawns(String:path[])
{
	new Handle:kv = CreateKeyValues("spawns");
		
	if ( kv != INVALID_HANDLE )
	{		
		// Add to the keyvalues tree.
		for ( new i = 0; i < NumPoints; i++ )
		{
			decl String:Buffer[64];
			IntToString(i, Buffer, sizeof(Buffer));
			KvJumpToKey(kv, Buffer, true);			// This will create the new section named as whatever number i currently is.
			
			new Float:KvVector[3];
			KvVector[0] = Angles[i][0];
			KvVector[1] = Angles[i][1];
			KvVector[2] = Angles[i][2];
			KvSetVector(kv, "angles", KvVector);	// This will create a new vector with this value.
			
			new KvTeamNum = TeamNum[i];
			KvSetNum(kv, "TeamNum", KvTeamNum);		// And so on.
			
			KvVector[0] = Position[i][0];
			KvVector[1] = Position[i][1];
			KvVector[2] = Position[i][2];
			KvSetVector(kv, "position", KvVector);
			
			// That's all for this section, return back.
			KvGoBack(kv);
		}
		
		LogMessage("File path to write to: %s", path);
		
		KeyValuesToFile(kv, path);
		CloseHandle(kv);
		
		LogMessage("File written, handle closed.");
		return true;
	}
	else
	{
		LogMessage("Keyvalues unable to be created.");
		return false;
	}
}

stock CreateParticle(String:name[], Float:pos[3])
{
	new entity = CreateEntityByName("info_particle_system");
	
	DispatchKeyValue(entity, "angles", "0 0 0");
	DispatchKeyValue(entity, "start_active", "0");
	DispatchKeyValue(entity, "effect_name", name);
	DispatchKeyValue(entity, "flag_as_weather", "0");
	
	DispatchSpawn(entity);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	
	return entity;
}

public Action:Command_AddSpawn(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( GetClientTeam(client) < TEAM_RED )
	{
		ShowActivity(client, "Cannot create spawn points as a spectator.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( !IsPlayerAlive(client) )
	{
		ShowActivity(client, "Cannot create spawn points while dead.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	new String:Buffer[8], rVal;
	GetCmdArg(1, Buffer, sizeof(Buffer));
	
	if ( StrEqual(Buffer, "red", false) )
	{
		rVal = AddSpawn(client, TEAM_RED);
	}
	else
	{
		rVal = AddSpawn(client, TEAM_BLUE);
	}
	
	if ( rVal < 1 )
	{
		ShowActivity(client, "Maximum number of spawn points reached.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( StrEqual(Buffer, "red", false) ) ShowActivity(client, "Spawn point %d created for team Red.", rVal);
	else ShowActivity(client, "Spawn point %d created for team Blue.", rVal);
	
	EmitSoundToClient(client, SND_SUCCESS);
	
	return Plugin_Handled;
}

public Action:Command_RemoveSpawn(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( GetClientTeam(client) < TEAM_RED )
	{
		ShowActivity(client, "Cannot remove spawn points as a spectator.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( !IsPlayerAlive(client) )
	{
		ShowActivity(client, "Cannot remove spawn points while dead.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	new rVal;
	
	if ( GetCmdArgs() > 0 )	// A spawn to remove is specified.
	{
		new String:ArgBuffer[16];
		GetCmdArg(1, ArgBuffer, sizeof(ArgBuffer));
		
		// If the command argument is "all", get rid of everything.
		if ( StrEqual(ArgBuffer, "all", false) ) rVal = RemoveSpawn(client, -1);	// Remove all.
		else
		{
			new index = StringToInt(ArgBuffer);
			index--;							// Decrement to get array index instead of spawn ID.
			
			if ( index < 0 || index >= NumPoints )
			{
				ShowActivity(client, "Spawn %d is invalid", index+1);
				EmitSoundToClient(client, SND_FAIL);
				return Plugin_Handled;
			}
			
			rVal = RemoveSpawn(client, index);	// Remove specific.
		}
	}
	else rVal = RemoveSpawn(client, -2);		// Remove closest.
	
	switch (rVal)
	{
		case 1:
		{
			ShowActivity(client, "No spawn points to remove.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		case 2:
		{
			ShowActivity(client, "No spawn points near enough to remove.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		default:
		{
			//ShowActivity(client, "Spawn point removed");
			EmitSoundToClient(client, SND_SUCCESS);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_DumpAll(client, args)
{
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	new minIndex = 0;
	new maxIndex = NumPoints-1;
	
	if ( GetCmdArgs() >= 1 )
	{
		decl String:min[8];
		GetCmdArg(1, min, sizeof(min));
		minIndex = StringToInt(min)-1;	// Decrement to get an array index.
	}
	
	if ( GetCmdArgs() >= 2 )
	{
		decl String:max[8];
		GetCmdArg(2, max, sizeof(max));
		maxIndex = StringToInt(max)-1;	// Decrement to get an array index.
	}
	
	if ( minIndex < 0 ) minIndex = 0;
	if ( maxIndex >= MAX_SPAWN_POINTS ) maxIndex = MAX_SPAWN_POINTS-1;
	if ( maxIndex < minIndex ) maxIndex = minIndex;
	
	PrintToConsole(client, "===== Active points: %d. Max points: %d =====", NumPoints, MAX_SPAWN_POINTS);
	PrintToConsole(client, "Team 2 is Red, 3 is Blue.\n");
	
	for ( new i = minIndex; i <= maxIndex; i++ )
	{
		PrintToConsole(client, "Spawn point %d (index %d):", i+1, i);
		
		PrintToConsole(client, "Position %f %f %f, Angles %f %f %f", Position[i][0], Position[i][1], Position[i][2], Angles[i][0], Angles[i][1], Angles[i][2]);
		PrintToConsole(client, "Team ID: %d\n", TeamNum[i]);
	}
	
	PrintToConsole(client, "===== Dump finished. =====");
	
	return Plugin_Handled;
}

public Action:Command_SaveSpawns(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( SaveSpawns(FilePath) )
	{
		ShowActivity(client, "Spawn file %s successfully written.", FilePath);
		EmitSoundToClient(client, SND_SUCCESS);
	}
	else
	{
		ShowActivity(client, "Spawn file %s was not able to be written.", FilePath);
		EmitSoundToClient(client, SND_FAIL);
	}
	
	return Plugin_Handled;
}

public Action:Command_LoadSpawns(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	switch(RetrieveSpawnInfo(FilePath))
	{
		case 1:
		{
			ShowActivity(client, "Error loading spawn file.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		case 2:
		{
			ShowActivity(client, "No spawn file exists for this map.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		default:
		{
			ShowActivity(client, "Spawns from %s loaded successfully.", FilePath);
			EmitSoundToClient(client, SND_SUCCESS);
		}
	}
	
	return Plugin_Handled;
}

public Action:OpenDoors(Handle:timer)
{
	if ( !GetConVarBool(cv_Doors) ) return Plugin_Continue;
	
	for ( new i = 0; i < numDoors; i++ )
	{
		new ent = EntRefToEntIndex(Doors[i]);
		//LogMessage ("ent = %d", ent);
		
		if ( IsValidEntity(ent) )
		{
			AcceptEntityInput(ent, "Open");
			AcceptEntityInput(ent, "Unlock");
			//LogMessage("Ent is valid, door opened.");
		}
	}
	
	return Plugin_Continue;
}