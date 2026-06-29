/* EXTRA SPAWN POINTS
* 
* 	DESCRIPTION
* 		This plugins will create extra spawn points on any map that currently has spawn points.
* 
* 		It will add additional spawn points where the existing spawn points are.
* 
* 	Credits
* 		Some code taken from SpawnTools7 - https://forums.alliedmods.net/showthread.php?t=115496
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Release
* 
* 		0.0.1.1	*	Fixed No Free Edicts Error by adding a timer to create spawn entity.
* 
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define 	PLUGIN_VERSION 		"0.0.1.1"

new bool:g_bEnabled;
new bool:g_bDebug;
new g_iSpawns;

public Plugin:myinfo = 
{
	name = "Extra Spawn Points",
	author = "TnTSCS aka ClarkKent",
	description = "Adds Additional Spawn Points",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	// Create this plugins CVars
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_extraspawnpoints_version", PLUGIN_VERSION, 
	"Version of 'Extra Spawn Points'", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	HookConVarChange((hRandom = CreateConVar("sm_extraspawnpoints_enabled", "1", 
	"Plugin enabled?", _, true, 0.0, true, 1.0)), OnEnabledChanged);
	g_bEnabled = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_extraspawnpoints_debug", "0", 
	"Print helpful information to sourcemod logs?", _, true, 0.0, true, 1.0)), OnDebugChanged);
	g_bDebug = GetConVarBool(hRandom);
	
	HookConVarChange((hRandom = CreateConVar("sm_extraspawnpoints_spawns", "0", 
	"Number of spawn points to create\n0 = Double the existing spawn points on the map\n1+ = Number of extra spawn points per team, up to double existing spawn points.", _, true, 0.0)), OnSpawnsChanged);
	g_iSpawns = GetConVarInt(hRandom);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	// Execute the config file, and let it autoname it
	AutoExecConfig(true);
}

public OnConfigsExecuted()
{
	if (g_bEnabled)
	{
		AddExtraSpawns();
	}
}

AddExtraSpawns()
{
	new MaxEntities = GetMaxEntities();
	new tSpawns, ctSpawns;
	new String:g_sClassName[64];//, Float:fVec[3];
	
	for (new i = MaxClients; i < MaxEntities; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, g_sClassName, sizeof(g_sClassName)))
		{
			if (StrEqual(g_sClassName, "info_player_terrorist") && (g_iSpawns == 0 || tSpawns < g_iSpawns))
			{
				CreateTimer(0.2, Create_T_Spawn_Timer, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (StrEqual(g_sClassName, "info_player_counterterrorist") && (g_iSpawns == 0 || ctSpawns < g_iSpawns))
			{
				CreateTimer(0.2, Create_CT_Spawn_Timer, i, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:Create_T_Spawn_Timer(Handle:timer, any:edict)
{
	new Float:fVec[3];
	
	GetEntPropVector(edict, Prop_Data, "m_vecOrigin", fVec);
	
	new extraSpawn = CreateEntityByName("info_player_terrorist");
	
	if (DispatchSpawn(extraSpawn))
	{
		TeleportEntity(extraSpawn, fVec, NULL_VECTOR, NULL_VECTOR);
		
		if (g_bDebug)
		{
			LogMessage("Successfully created extra T spawn at [%.2f][%.2f][%.2f]", fVec[0], fVec[1], fVec[2]);
		}
	}
	else
	{
		if (g_bDebug)
		{
			LogMessage("Could not create extra T spawn at [%.2f][%.2f][%.2f]", fVec[0], fVec[1], fVec[2]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Create_CT_Spawn_Timer(Handle:timer, any:edict)
{
	new Float:fVec[3];
	
	GetEntPropVector(edict, Prop_Data, "m_vecOrigin", fVec);
	
	new extraSpawn = CreateEntityByName("info_player_counterterrorist");
	
	if (DispatchSpawn(extraSpawn))
	{
		TeleportEntity(extraSpawn, fVec, NULL_VECTOR, NULL_VECTOR);
		
		if (g_bDebug)
		{
			LogMessage("Successfully created extra CT spawn at [%.2f][%.2f][%.2f]", fVec[0], fVec[1], fVec[2]);
		}
	}
	else
	{
		if (g_bDebug)
		{
			LogMessage("Could not create extra CT spawn at [%.2f][%.2f][%.2f]", fVec[0], fVec[1], fVec[2]);
		}
	}
	
	return Plugin_Handled;
}

public OnVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Make sure the version number is what is set in the compiled plugin, not a config file or changed CVar
	if (!StrEqual(newVal, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

public OnEnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = GetConVarBool(cvar);
}

public OnDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDebug = GetConVarBool(cvar);
}

public OnSpawnsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iSpawns = GetConVarInt(cvar);
}