#include <sourcemod>
#include <keyvalues>
#include <sdktools>
#include <sdkhooks>
#include <tf2>

#pragma semicolon	1

#define PLUGIN_NAME 		"Deathmatch Spawn File Creator [HOTFIX]"
#define PLUGIN_AUTHOR		"[X6] Herbius"
#define PLUGIN_DESCRIPTION	"Creates and handles custom deathmatch spawns for Team Fortress 2."
#define PLUGIN_VERSION		"2.0.0.0"

#define STATE_DISABLED		2
#define STATE_NOT_IN_ROUND	1

// Teams
#define TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_RED		2
#define TEAM_BLUE		3

#define MAX_SPAWN_POINTS	64

// Variable declarations:
new g_PluginState;						// Holds the flags for the global plugin state.

new Float:Angles[MAX_SPAWN_POINTS][3];
new Float:Position[MAX_SPAWN_POINTS][3];
new TeamNum[MAX_SPAWN_POINTS];
new NumPoints;
new String:FilePath[128];

new Handle:cv_PluginEnabled = INVALID_HANDLE;	// Enables or disables the plugin.
new Handle:cv_SpawnRadius = INVALID_HANDLE;		// Radius around spawn point in which to destroy objects/kill clients.

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
	
	AutoExecConfig(true, "dmspawn", "sourcemod/dmspawn");
	
	// Update the plugin state to reflect the cvar after autoexec.
	PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
	
	HookConVarChange(cv_PluginEnabled, CvarChange);
	
	HookEventEx("teamplay_round_start",		Event_RoundStart,		EventHookMode_Post);
	HookEventEx("teamplay_round_win",		Event_RoundWin,			EventHookMode_Post);
	HookEventEx("teamplay_round_stalemate",	Event_RoundStalemate,	EventHookMode_Post);
	HookEventEx("player_spawn",				Event_Spawn,			EventHookMode_Post);
	
	// Spawn points are loaded on MapStart which is called immediately after this if the plugins is loaded on an active server.
}

public OnMapStart()
{
	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	Format(FilePath, sizeof(FilePath), "scripts/dmspawn/%s_spawns.txt", MapName);
	
	LogMessage("File path for map: %s", FilePath);
	
	// Get the info and stick it into our global variables.
	RetrieveSpawnInfo(FilePath);
	
	if ( NumPoints < 1 ) return;
	
	// Kill all entities that shouldn't exist.
	KillEntities();
}

public OnMapEnd()
{
	// Clear out all spawn point info.
	ClearAllIndices();
}

/*	Checks which ConVar has changed and does the relevant things.	*/
public CvarChange( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	// If the enabled/disabled convar has changed, run PluginStateChanged
	if ( convar == cv_PluginEnabled ) PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
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
}

/*	Called when a new round begins.	*/
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PluginState &= ~STATE_NOT_IN_ROUND;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED ) return;
	
	if ( NumPoints > 0 ) KillEntities();
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
	
	// Choose a random spawn index to teleport the client to.
	if ( NumPoints > 0 && client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		new i = GetRandomInt(0, (NumPoints - 1));
		
		// Firstly, check to see if there is any client or building within the specified radius of the spawn point.
		new Float:SpawnRadius = GetConVarFloat(cv_SpawnRadius);
		
		for ( new ClientSearch = 1; ClientSearch <= MaxClients; ClientSearch++ )
		{
			if ( IsClientInGame(ClientSearch) )
			{
				new Float:ClOrigin[3];
				GetClientAbsOrigin(ClientSearch, ClOrigin);
				
				// If the client is near enough:
				if ( GetVectorDistance(ClOrigin, Position[i]) <= SpawnRadius && GetClientTeam(ClientSearch) != GetClientTeam(client) ) ForcePlayerSuicide(ClientSearch);
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
		
		//#if DEBUG == 1
		//LogMessage("Player %N was teleported to %f %f %f, angles %f %f %f", client, Position[i][0], Position[i][1], Position[i][2], Angles[i][0], Angles[i][1], Angles[i][2]);
		//#endif
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
	}
}

/*	Parses the spawn info file and puts the values into the global variables.
	Returns true on success, false on failure.	*/
bool:RetrieveSpawnInfo(String:s_FilePath[])
{	
	new Handle:kv = CreateKeyValues("spawns");
	
	if ( kv == INVALID_HANDLE )
	{
		LogMessage("Could not create keyvalues tree to import spawn point information.");
		return false;
	}
	
	if ( !FileToKeyValues(kv, s_FilePath) )
	{
		LogMessage("%t", "No spawns file %s found.", s_FilePath);
		return false;
	}
	
	LogMessage("Spawn point file %s loaded successfully.", s_FilePath);
	
	NumPoints = 0;
	
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
	
	LogMessage("Number of spawns in file: %d", NumPoints);
	LogMessage("All spawns are loaded.");
	
	return true;
}

stock KillEntities()
{
	// Find any func_regenerates that currently exist and disable them.
	new Resupply = -1;
	while ( (Resupply = FindEntityByClassname(Resupply, "func_regenerate")) != -1 )
	{
		AcceptEntityInput(Resupply, "Disable");
		LogMessage("Resupply locker at index %d disabled.", Resupply);
	}
	
	// Find any func_respawnrooms that currently exist and kill them.
	new n_Index = -1;
	while ( (n_Index = FindEntityByClassname(n_Index, "func_respawnroom")) != -1 )
	{
		AcceptEntityInput(n_Index, "Kill");
		LogMessage("Respawnroom at index %d removed.", n_Index);
	}

	// Find any func_respawnroomvisualisers that currently exist and kill them.
	n_Index = -1;
	while ( (n_Index = FindEntityByClassname(n_Index, "func_respawnroomvisualizer")) != -1 )
	{
		AcceptEntityInput(n_Index, "Kill");
		LogMessage("Respawn visualiser at index %d removed.", n_Index);
	}
	
	// Find any filters that currently exist and nullify them.
	// NOTE: for the moment we'll kill it, maybe use AddOutput if it's convenient later.
	n_Index = -1;
	while ( (n_Index = FindEntityByClassname(n_Index, "filter_activator_tfteam")) != -1 )
	{
		AcceptEntityInput(n_Index, "Kill");
		LogMessage("Filter at index %d removed.", n_Index);
	}
}