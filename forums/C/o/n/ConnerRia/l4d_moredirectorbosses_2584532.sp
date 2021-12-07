#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] MoreDirectorBosses",
	author = "ConnerRia",
	description = "A simple plugin that forces the director to spawn multiple witches each map alongside one tank. More witches, bitches! ",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new bool: bHasTankSpawned = false;


public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{		
		SetFailState("Plugin supports Left 4 Dead series only.");
	}
	CreateConVar("l4d_moredirectorbosses_version", PLUGIN_VERSION, "Version of MoreDirectorBosses on this server", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", OnWitchSpawn);
	HookEvent("tank_spawn", EventHook:OnTankSpawn, EventHookMode_PostNoCopy);
}

public OnMapStart()
{	
	SetConVarInt(FindConVar("director_force_tank"), 0, true, false);
	SetConVarInt(FindConVar("director_force_witch"), 1, true, false);
	bHasTankSpawned = false;
}	

public Action: Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	bHasTankSpawned = false;
	
	decl String:mapname[128]; 
	GetCurrentMap(mapname, sizeof(mapname));

	if (!StrEqual(mapname, "c5m1_waterfront"))
	{
	SetConVarInt(FindConVar("director_force_tank"), 0, true, false);
	SetConVarInt(FindConVar("director_force_witch"), 1, true, false);
	}
	else
	{
	SetConVarInt(FindConVar("director_force_tank"), 1, true, false);
	SetConVarInt(FindConVar("director_force_witch"), 0, true, false);
	}
}

public Action: Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
    new bool:safe = GetEventBool(event, "checkpoint"); 

    if (safe) 
	{
	   SetConVarInt(FindConVar("director_force_tank"), 0, true, false);
	   SetConVarInt(FindConVar("director_force_witch"), 1, true, false);
	   bHasTankSpawned = false;
	}
}

public Action: Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(FindConVar("director_force_tank"), 0, true, false);
	SetConVarInt(FindConVar("director_force_witch"), 1, true, false);
	bHasTankSpawned = false;
}

public Action:OnWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:mapname[128]; 
	GetCurrentMap(mapname, sizeof(mapname));
// To maximize witch spawns, we dont want to force tank on finale maps, maps with no tanks or maps with static tank spawns. 
	if (!StrEqual(mapname, "c7m1_docks") && !StrEqual(mapname, "c13m2_southpinestream") && !StrEqual(mapname, "c1m1_hotel") && !StrEqual(mapname, "c8m1_apartment"))
    {
        if (!IsFinalMap())
        {
            if (!bHasTankSpawned)
            {
                SetConVarInt(FindConVar("director_force_tank"), 1, true, false);
                SetConVarInt(FindConVar("director_force_witch"), 0, true, false);
            }
        }  
    }  
}

public OnTankSpawn()
{
	if (!bHasTankSpawned)
	{
		SetConVarInt(FindConVar("director_force_tank"), 0, true, false);
		SetConVarInt(FindConVar("director_force_witch"), 1, true, false);
		bHasTankSpawned = true;
	}
}

stock bool IsFinalMap()
{
    return (FindEntityByClassname(-1, "info_changelevel") == -1
                && FindEntityByClassname(-1, "trigger_changelevel") == -1);
}  
