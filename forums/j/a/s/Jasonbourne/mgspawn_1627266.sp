// Includes
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Plugin Info
#define PLUGIN_NAME "mgspawn"
#define PLUGIN_AUTHOR "Jason Bourne"
#define PLUGIN_DESC "Respawns players killed by world/props"
#define PLUGIN_VERSION "1.1.1"
#define PLUGIN_SITE "www.immersion-networks.com"

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_SITE
}

// Handles Define
new Handle:sm_mgspawn_enable = INVALID_HANDLE;
new Handle:sm_mgspawn_delay = INVALID_HANDLE;
new Handle:sm_mgspawn_spawnpoints = INVALID_HANDLE;
new MapChecker[MAXPLAYERS+1];
new Float:respawndelaytime;

//Executed on plugin start 
public OnPluginStart()
{
	// Hooking Events 
	HookEvent("player_death", Event_Death);
	HookEvent("player_spawn", Event_Spawn);
	
	// Create Convars
	CreateConVar("sm_mgspawn_version", PLUGIN_VERSION, "mgspawn Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_mgspawn_enable = CreateConVar("sm_mgspawn_enable", "1", "Enable mgspawn. [0 = FALSE, 1 = TRUE]");
	sm_mgspawn_delay = CreateConVar("sm_mgspawn_delay", "0.1", "Set respawn delay");
	sm_mgspawn_spawnpoints= CreateConVar("sm_mgspawn_spawnpoints", "1", "Set to 0 to enable for all maps or set to 1 to only enable when there are one team spawn points set");
	
	
}

public OnMapStart()
{
// Thanks to Spawn Tools 7 
	new maxEnt = GetMaxEntities(), tsCount, ctsCount;
	decl String:sClassName[64];
	for (new i = MaxClients; i < maxEnt; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
		{
			if (StrEqual(sClassName, "info_player_terrorist"))
			{
				tsCount++;
			}
			else if (StrEqual(sClassName, "info_player_counterterrorist"))
			{
				ctsCount++;
			}
		}
	}
	
	// Activates or deactivates plugin based on map spawn condition
	if(GetConVarBool(sm_mgspawn_spawnpoints)) // if fuction is enabled 
	{
		// Enables plugin if there is only one set of spawns
		if (tsCount==0 || ctsCount==0)
		{
		SetConVarInt(sm_mgspawn_enable, 1);
		}
		else
		{
		SetConVarInt(sm_mgspawn_enable, 0);
		}
	}
}

public Event_Death( Handle:Death_Event, const String:Death_Name[], bool:Death_Broadcast )
{
	
	
	if(GetConVarBool(sm_mgspawn_enable)) // if plugin is enabled 
	{
		
		// Get event info
		new client = GetClientOfUserId( GetEventInt(Death_Event,"userid") );
		new attackerId = GetEventInt(Death_Event, "attacker");
		new attacker = GetClientOfUserId(attackerId);
		
		// Killed by world?
		if(attacker==0)
		{
			if ( client != 0 )
			{
				if (MapChecker[client]==0)
				{
					SetConVarInt(sm_mgspawn_enable, 0);
				}
				else
				{
				respawndelaytime=GetConVarFloat(sm_mgspawn_delay);
				CreateTimer(respawndelaytime, RespawnClient, any:client);
				}
								
			}
		}
		// Else bad luck your staying dead
	}
	// Else plugin not enabled
}

public Action:RespawnClient( Handle:timer, any:client )
{
	//Checks on client 
	if ( IsValidEntity(client) && IsClientInGame(client) && IsClientObserver(client) && !IsPlayerAlive(client) )
	{
		CS_RespawnPlayer(client); 
		
	}
	
}

public Event_Spawn( Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{	
	if(GetConVarBool(sm_mgspawn_enable)) // if plugin is enabled 
	{
		new client = GetClientOfUserId(GetEventInt(Spawn_Event,"userid"));
		MapChecker[client]=0;
		CreateTimer(0.05,CheckMapSlayer,any:client);
	}
	
}

public Action:CheckMapSlayer( Handle:timer, any:client )
{	
	MapChecker[client]=1;	
}
