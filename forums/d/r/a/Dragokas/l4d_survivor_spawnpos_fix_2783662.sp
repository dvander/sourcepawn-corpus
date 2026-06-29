#define PLUGIN_VERSION "1.3"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define DEBUG 0

enum
{
	TELEPORT_METHOD_WARP,
	TELEPORT_METHOD_TELEPORT
}

public Plugin myinfo = 
{
	name = "[L4D] Survivor Spawn Position Fix",
	author = "Alex Dragokas",
	description = "Force teleport survivors on bugged maps when they spawn underground",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

/*
	ChangeLog:
	
	1.0 (13-Jul-2022)
	 - Initial release.
	 
	1.1 (13-Jul-2022)
	 - Better distance detection (count the minimum distance to all of spawn entities).
	 - Prevented possible teleport in mid-game.
	 
	1.2 (17-Jul-2022)
	 - Fix 5+ survivors spawned in other warp place, wrongly defined by map makers (e.g. map: l4d_garage01_alleys).
	 - Fixed code bug: "info_player_start" and "info_survivor_position" is mixed up, so entire logic was a kind broken.
	 
	1.3 (14-Aug-2022)
	 - All debug commands are now compatible with disable cvar.
*/

const float DISTANCE_TO_WARP_MAX = 150.0;
const float DISTANCE_TO_OTHER_SURVIVOR_MAX = 100.0;
const float MID_GAME_START_TIME = 60.0;

ConVar g_ConVarEnable;
bool g_bEnabled, g_bEntitiesCached, g_bSecondSpawn;
int g_iSurvivorCount, g_iInfoSurvPos[4], g_iInfoPlayerStart;

public void OnPluginStart()
{
	CreateConVar("l4d_surv_spawnpos_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD | CVAR_FLAGS);

	g_ConVarEnable = CreateConVar("l4d_surv_spawnpos_enabled", "1", "Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_surv_spawnpos");
	
	HookConVarChange(g_ConVarEnable,		ConVarChanged);
	GetCvars();
	
	#if defined DEBUG
		RegConsoleCmd("sm_spawnpos", 	CmdSpawnPos, 	"Show pre-defined spawn entity position");
		RegConsoleCmd("sm_spawnwarp", 	CmdSpawnWarp, 	"Warp to survivor position using director command");
		RegConsoleCmd("sm_spawntel", 	CmdSpawnTel, 	"Teleport to survivor position entity");
	#endif
}

stock void DistanceInfo(int client)
{
	float dist;
	GetMinimumDistanceToWarp(client, dist);
	bool bStuck = IsClientStuck(client);
	PrintToChatAll("%N distance = %f. Stuck? %b", client, dist, bStuck);
}

stock bool SurvivorEntityInfo()
{
	float pos[3];
	if( !GetSpawnPosition(pos) )
	{
		PrintToChatAll("Failed to find spawn position!");
		return false;
	}
	else {
		PrintToChatAll("survivor warp position: %f %f %f", pos[0], pos[1], pos[2]);
	}
	return true;
}

//==========================
//		COMMANDS
//=========================

Action CmdSpawnPos(int client, int args)
{
	if( !g_bEnabled )
	{
		PrintToChat(client, "Command is disabled.");
		return Plugin_Handled;
	}
	if( SurvivorEntityInfo() )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				DistanceInfo(i);
			}
		}
	}
	return Plugin_Handled;
}

Action CmdSpawnWarp(int client, int args)
{
	if( !g_bEnabled )
	{
		PrintToChat(client, "Command is disabled.");
		return Plugin_Handled;
	}
	TeleportToSafeRoom(client, TELEPORT_METHOD_WARP);
	PrintToChat(client, "%N warped to saferoom.", client);
	return Plugin_Handled;
}

Action CmdSpawnTel(int client, int args)
{
	if( !g_bEnabled )
	{
		PrintToChat(client, "Command is disabled.");
		return Plugin_Handled;
	}
	if( TeleportToSafeRoom(client, TELEPORT_METHOD_TELEPORT) )
	{
		PrintToChat(client, "%N teleported to saferoom.", client);
	}
	else {
		PrintToChat(client, "Failed to find spawn position!");
	}
	return Plugin_Handled;
}

//==========================
//		CON VARIABLES
//=========================

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_ConVarEnable.BoolValue;
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("player_first_spawn", 			Event_PlayerFirstSpawn,		EventHookMode_Post);
			HookEvent("player_left_start_area", 		Event_PlayerLeftStartArea);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("player_first_spawn", 			Event_PlayerFirstSpawn,		EventHookMode_Post);
			UnhookEvent("player_left_start_area", 		Event_PlayerLeftStartArea);
			bHooked = false;
		}
	}
}

//==========================
//		HOOKS
//==========================

public void OnMapStart()
{
	g_bSecondSpawn = false;
	g_iInfoPlayerStart = 0;
	for( int i = 0; i < sizeof(g_iInfoSurvPos); i++ )
	{
		g_iInfoSurvPos[i] = 0;
	}
	// when survivor left safe area, distance should be also measured to other survivors (not only to "info_survivor_position" entity).
	// so, we set this flag "MiddleGame" in case:
	// - 60.0 seconds elapsed since Map Started
	// - more than 4 survivors already spawned
	// - survivor left safe area event raised
	// P.S. Also, we don't care "Round_End / Round_Start" at all. I observed that bug doesn't happen on round lost.
	SetMiddleGameState(false);
	CreateTimer(MID_GAME_START_TIME, Timer_SetMiddleGame, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	g_bEntitiesCached = false;
}

Action Timer_SetMiddleGame(Handle timer)
{
	SetMiddleGameState(true);
	return Plugin_Stop;
}

bool Cache_SpawnPositionEntities() // precache indeces for optimization
{
	static bool bStatus = false;
	if( g_bEntitiesCached ) return bStatus;
	
	int count, entity = INVALID_ENT_REFERENCE;
	g_iInfoPlayerStart = FindEntityByClassname(INVALID_ENT_REFERENCE, "info_player_start");
	if( g_iInfoPlayerStart != INVALID_ENT_REFERENCE ) bStatus = true;
	
	while( INVALID_ENT_REFERENCE != (entity = FindEntityByClassname(entity, "info_survivor_position")) )
	{
		g_iInfoSurvPos[count++] = entity;
		bStatus = true;
		if( count >= sizeof(g_iInfoSurvPos) ) break;
	}
	g_bEntitiesCached = true;
	return bStatus;
}

stock bool IsValidEntity_Safe(int entity)
{
	return ( entity && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity) );
}

// for warp
// we took position of first known entity - usually, first "info_player_start" (there are 4 on the map)
bool GetSpawnPosition(float vector[3])
{
	if( !Cache_SpawnPositionEntities() ) return false;
	
	for( int i = 0; i < sizeof(g_iInfoSurvPos); i++ )
	{
		if( IsValidEntity_Safe(g_iInfoSurvPos[i]) )
		{
			GetEntPropVector(g_iInfoSurvPos[i], Prop_Data, "m_vecOrigin", vector);
			return true;
		}
	}
	if( IsValidEntity_Safe(g_iInfoPlayerStart) )
	{
		GetEntPropVector(g_iInfoPlayerStart, Prop_Data, "m_vecOrigin", vector);
		return true;
	}
	return false;
}

// for bug detection
// we testing distance to each of entities of classes:
// * info_survivor_position
// * info_player_start
bool GetMinimumDistanceToWarp(int client, float& out_distance)
{
	if( !Cache_SpawnPositionEntities() ) return false;
	
	float mindist = 9999.0, dist;
	float vMe[3], vector[3];
	GetClientAbsOrigin(client, vMe);
	
	for( int i = 0; i < sizeof(g_iInfoSurvPos); i++ )
	{
		if( IsValidEntity_Safe(g_iInfoSurvPos[i]) )
		{
			GetEntPropVector(g_iInfoSurvPos[i], Prop_Data, "m_vecOrigin", vector);
			dist = GetVectorDistance(vector, vMe);
			if( dist < mindist ) mindist = dist;
		}
	}
	if( IsValidEntity_Safe(g_iInfoPlayerStart) )
	{
		GetEntPropVector(g_iInfoPlayerStart, Prop_Data, "m_vecOrigin", vector);
		dist = GetVectorDistance(vector, vMe);
		if( dist < mindist ) mindist = dist;
	}
	out_distance = mindist;
	return true;
}

// Checks the closest distance to every survivor
// (if survivor spawned next to other survivor, we don't need to teleport him: in case, he is 5+,
// which means other 1-4 survivors already teleported in correct position.
bool IsCloseToOtherSurvivors(int client)
{
	float dist, vOrigin[3], vMe[3];
	GetClientAbsOrigin(client, vMe);
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			GetClientAbsOrigin(i, vOrigin);
			dist = GetVectorDistance(vOrigin, vMe);
			if( dist < DISTANCE_TO_OTHER_SURVIVOR_MAX )
				return true;
		}
	}
	return false;
}

void SetMiddleGameState(bool bEnable)
{
	if( bEnable )
	{
		g_iSurvivorCount = 5;
	}
	else {
		g_iSurvivorCount = 0;
	}
}

bool IsMiddleGame()
{
	return (g_iSurvivorCount > 4);
}

bool IsClientSpawnBugged(int client)
{
	float dist;
	if( GetMinimumDistanceToWarp(client, dist) )
	{
		if( dist > DISTANCE_TO_WARP_MAX )
		{
			if( IsMiddleGame() )
			{
				// in middle game, new survivor can spawn next to survivor located far from the "info_survivor_position" entity
				if( !IsCloseToOtherSurvivors(client) )
				{
					return true;
				}
			}
			else {
				return true;
			}
		}
		if( IsClientStuck(client) )
		{
			return true;
		}
	}
	return false;
}

void FixSpawnPosition(int client)
{
	if( IsClientSpawnBugged(client) )
	{
		TeleportToSafeRoom(client, TELEPORT_METHOD_WARP);
		CreateTimer(0.1, Timer_Ensure, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_Ensure(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		if( IsClientSpawnBugged(client) )
		{
			TeleportToSafeRoom(client, TELEPORT_METHOD_TELEPORT);
		}
	}
	return Plugin_Stop;
}

public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	SetMiddleGameState(true);
	
	#if DEBUG
		PrintToChatAll("Event_PlayerLeftStartArea");
	#endif
}

public void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 )
	{
		if( !g_bSecondSpawn )
		{
			g_bSecondSpawn = true;
			Fix_InfoPlayerStartEntity();
		}
		
		++ g_iSurvivorCount;
	
		FixSpawnPosition(client);
		
		#if DEBUG
			SurvivorEntityInfo();
			DistanceInfo(client);
		#endif
	}
}

// Get distance of all info_survivor_position to info_player_start, sort them,
// and teleport elapsed 5+ info_survivor_position to the one most close to info_player_start.
void Fix_InfoPlayerStartEntity()
{
	int entity = FindEntityByClassname(INVALID_ENT_REFERENCE, "info_player_start");
	if( entity == INVALID_ENT_REFERENCE ) return;
	
	int count;
	float vecSurv[3], vecStart[3], dist;
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vecSurv);
	
	ArrayList al = new ArrayList(ByteCountToCells(8)); // 4 bytes per block (int + float)
	
	const int IDX_ENTITY = 1, IDX_DIST = 0;
	
	entity = INVALID_ENT_REFERENCE;
	while( INVALID_ENT_REFERENCE != (entity = FindEntityByClassname(entity, "info_survivor_position")) )
	{
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vecStart);
		dist = GetVectorDistance(vecSurv, vecStart);
		al.Resize(count + 1);
		al.Set(count, dist, IDX_DIST);
		al.Set(count, entity, IDX_ENTITY);
		++ count;
	}
	
	if( count > 4 )
	{
		#if DEBUG
			PrintToChatAll("Found %i info_survivor_position entities.", count);
		#endif
		
		al.Sort(Sort_Ascending, Sort_Float);
		
		float vecFirst[3];
		int iEntityFirst = al.Get(0, IDX_ENTITY);
		GetEntPropVector(iEntityFirst, Prop_Data, "m_vecOrigin", vecFirst);
		
		for( int i = 4; i < count; i++ )
		{
			entity = al.Get(i, IDX_ENTITY);
			dist = al.Get(i, IDX_DIST);
			
			if( dist > DISTANCE_TO_WARP_MAX )
			{
				TeleportEntity(entity, vecFirst, NULL_VECTOR, NULL_VECTOR);
				#if DEBUG
					PrintToChatAll("info_survivor_position %i teleported to %i.", entity, iEntityFirst);
				#endif
			}
		}
	}
	delete al;
}

bool TeleportToSafeRoom(int client, int method)
{
	switch( method )
	{
		case TELEPORT_METHOD_WARP:
		{
			int warp_flags = GetCommandFlags("warp_to_start_area");
			SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
			int give_flags = GetCommandFlags("give");
			SetCommandFlags("give", give_flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "warp_to_start_area");
			SetCommandFlags("warp_to_start_area", warp_flags);
			SetCommandFlags("give", give_flags);
		}
		case TELEPORT_METHOD_TELEPORT:
		{
			float pos[3];
			if( !GetSpawnPosition(pos) )
			{
				return false;
			}
			else {
				TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	return true;
}

bool IsClientStuck(int iClient)
{
	float vMin[3], vMax[3], vOrigin[3];
	bool bHit;
	GetClientMins(iClient, vMin);
	GetClientMaxs(iClient, vMax);
	GetClientAbsOrigin(iClient, vOrigin);
	Handle hTrace = TR_TraceHullFilterEx(vOrigin, vOrigin, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers, iClient);
	if (hTrace != INVALID_HANDLE)
	{
		bHit = TR_DidHit(hTrace);
		CloseHandle(hTrace);
	}
	return bHit;
}

public bool TraceRay_NoPlayers(int entity, int mask, any data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}