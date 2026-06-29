#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"left4downtown.l4d2"
#define PLUGIN_VERSION 		"1.0"

ConVar cvar_mob_count;
ConVar cvar_mobit_count;

public Plugin myinfo =
{
	name = "Spawn mob and Spawn IT mob",
	author = "$atanic $pirit",
	description = "Adds a hook for mob spawns",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("mob_spawn_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_mob_count		=	CreateConVar( "count_mob", "0",		"Mob count to spawn!");
	cvar_mobit_count	=	CreateConVar( "count_mobit", "0",	"MobIT count to spawn!");

	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if( hGamedata == null ) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
		
	// ====================================================================================================
	// Detour	-	ZombieManager::SpawnMob
	// ====================================================================================================
	
	Handle hDetour_SpawnMob = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Ignore);
	if( !hDetour_SpawnMob )
		SetFailState("Failed to setup detour for hDetour_SpawnMob");
	
	// Load the address of the function from gamedata file.
	if (!DHookSetFromConf(hDetour_SpawnMob, hGamedata, SDKConf_Signature, "Zombiemanager_SpawnMob"))
		SetFailState("Failed to find \"ZombieManager::SpawnMob\" signature.");

	// Add all parameters.
	DHookAddParam(hDetour_SpawnMob, HookParamType_Int);


	// Add a pre hook on the function.
	if (!DHookEnableDetour(hDetour_SpawnMob, false, Detour_OnSpawnMob))
		SetFailState("Failed to detour OnSpawnMob.");
		
	// And a post hook.
	if (!DHookEnableDetour(hDetour_SpawnMob, true, Detour_OnSpawnMob_Post))
		SetFailState("Failed to detour OnSpawnMob post.");
		
	// ====================================================================================================
	// Detour	-	ZombieManager::SpawnITMob
	// ====================================================================================================
	
	Handle hDetour_SpawnITMob = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Ignore);
	if( !hDetour_SpawnITMob )
		SetFailState("Failed to setup detour for hDetour_SpawnITMob");
	
	// Load the address of the function from gamedata file.
	if (!DHookSetFromConf(hDetour_SpawnITMob, hGamedata, SDKConf_Signature, "Zombiemanager_SpawnITMob"))
		SetFailState("Failed to find \"ZombieManager::SpawnITMob\" signature.");

	// Add all parameters.
	DHookAddParam(hDetour_SpawnITMob, HookParamType_Int);


	// Add a pre hook on the function.
	if (!DHookEnableDetour(hDetour_SpawnITMob, false, Detour_OnSpawnITMob))
		SetFailState("Failed to detour OnSpawnITMob.");
		
	// And a post hook.
	if (!DHookEnableDetour(hDetour_SpawnITMob, true, Detour_OnSpawnITMob_Post))
		SetFailState("Failed to detour OnSpawnITMob post.");
}


// ====================================================================================================
// Function	-	ZombieManager::SpawnMob
// ====================================================================================================

public MRESReturn Detour_OnSpawnMob(Handle hParam)
{
	int param1 = DHookGetParam(hParam, 1);
	//int client = SDKCall(hGetPlayerSlot, pThis) + 1; 
	PrintToChatAll("Detour_OnSpawnMob_pre called on %d", param1);
	
	if(cvar_mob_count.IntValue)
	{
		DHookSetParam(hParam, 1, cvar_mob_count.IntValue);
		return MRES_ChangedOverride;
	}
	return MRES_Ignored;
}

public MRESReturn Detour_OnSpawnMob_Post(Handle hParam)
{
	int param1 = DHookGetParam(hParam, 1);
	PrintToChatAll("Detour_OnSpawnMob_Post called on %d", param1);
	return MRES_Ignored;
}

// ====================================================================================================
// Function	-	ZombieManager::SpawnITMob
// ====================================================================================================
	
public MRESReturn Detour_OnSpawnITMob(Handle hParam)
{
	int param1 = DHookGetParam(hParam, 1);
	PrintToChatAll("Detour_OnSpawnITMob_pre called on %d", param1);
	
	if(cvar_mobit_count.IntValue)
	{
		DHookSetParam(hParam, 1, cvar_mobit_count.IntValue);
		return MRES_ChangedOverride;
	}
	return MRES_Ignored;
}

public MRESReturn Detour_OnSpawnITMob_Post(Handle hParam)
{
	int param1 = DHookGetParam(hParam, 1);
	PrintToChatAll("Detour_OnSpawnITMob_Post called on %d", param1);
	return MRES_Ignored;
}