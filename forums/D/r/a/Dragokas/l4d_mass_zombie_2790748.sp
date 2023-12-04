#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dragokas>
#include <left4dhooks>

#define PLUGIN_VERSION 		"1.0"

public Plugin myinfo = 
{
	name = "[L4D] Mass Zombies",
	author = "Alex Dragokas",
	description = "Special Round: extremely lot and angry horde of zombies (Learn how to, VAAAAAALVE!)",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

/*
	Description of the logic:
	
	When !p command is executed:
	 - map is erased from useless entities, allowing to have more space for experiments and performance.
	 - some ConVars are get changed to make a game harder.
	 - infinite panic event occurs
	 - next to each spawned zombie, the location is saved and used therefore to spawn more (MULTIPLY_COUNT) zombies
	 per each MULTIPLY_INTERVAL of time.
	 - zombies continues to spawn until LIMIT_ZOMBIES is reached.
	 - chase is triggered and get changed each 1 second to point to "rusher" player (who have the most flow distance).
	 - when the number of zombies decreased under LIMIT_ZOMBIES_TO_FORWARD_SPAWN value, forward zombie trigger is raised
	 and FORWARD_ZOMBIES_COUNT is spawned (in hidden place) in the forward direction of the rusher, surely preventing him from moving forward.
	 - number of tank waves is limited to TANK_WAVES_ALLOWED value.
	 - first tank spawn is allowed to happen only after DELAY_FIRST_TANK_SPAWN sec. elapsed since the round start (except finale maps).
	 - commons doesn't touch incapped players and pinned players.
	 - once player is get incapped, hunters starting to spawn next to him (in hidden place).
	 - when final door is get used, 2 minutes timeout is started after which the "Mass Zombies" mode 
	 is automatically disabled to prevent game breaking on some maps.
	 
	 Dependencies:
	 - (private) No Vip Double Jumps
	 - (private) No Vip Long Jumps
	 - Anti Rush by SilverShot
	 - left4dragokas
	 - left4dhooks
*/

#define TEAM_SURVIVOR 2

#define MULTIPLY_INTERVAL		0.75		// delay between each duplication
#define MULTIPLY_COUNT			15			// count of zombies per each duplication
#define TANK_WAVES_ALLOWED		1			// maximum tank waves allowed per this round
#define DELAY_FIRST_TANK_SPAWN 	300			// grace time (in sec.) while tank spawn is not allowed (except finales)
#define LIMIT_ZOMBIES_TO_FORWARD_SPAWN 80	// total count of zombies where forward spawn trigger is allowed to occur
#define FORWARD_ZOMBIES_COUNT	25			// count of zombies to spawn in forward trigger

const int	LIMIT_ENTITIES = 1900;
const int	LIMIT_ZOMBIES = 90;

int CLASS_TANK;

char 	CLASS_INFECTED[] = "infected";

bool 	g_bLate, g_bLeft4dead2, g_bRoundStarted, g_bFinale, g_bSpawnMega, g_bSkipHook, g_bMapStarted;
int 	g_iCommon, g_iEntities, g_iTankCount, g_iTankWave;
float 	g_fTimeAllowTank, g_fDelaySpawn = MULTIPLY_INTERVAL;
ConVar 	g_hCvarPanicForever, g_hCvarUpdateRate, g_hCvarVipDoubleJump, g_hCvarVipLongJump, g_hCvarAntiRush, g_hCvarNoSpecials, g_hCvarCrawl;
Handle	g_hTimerChase;

#pragma unused g_bLeft4dead2

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead2 )
	{
		CLASS_TANK = 8;
		g_bLeft4dead2 = true;
	}
	else if( test == Engine_Left4Dead )
	{
		CLASS_TANK = 5;
	}
	else {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarPanicForever = FindConVar("director_panic_forever");
	g_hCvarUpdateRate = FindConVar("nb_update_frequency");
	g_hCvarVipDoubleJump = FindConVar("no_vip_jumps_enabled");
	g_hCvarVipLongJump = FindConVar("no_vip_long_jump_enabled");
	g_hCvarAntiRush = FindConVar("l4d_anti_rush_allow");
	g_hCvarNoSpecials = FindConVar("director_no_specials");
	g_hCvarCrawl = FindConVar("survivor_allow_crawling");

	HookEvent("round_start",		Event_RoundStart);
	HookEvent("round_end",			Event_RoundEnd);
	HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_Pre);
	
	RegConsoleCmd("sm_mz", CmdPanic);
	//RegConsoleCmd("sm_c", CmdClean);
	//RegConsoleCmd("sm_h", CmdHigh);
}

public Action CmdHigh(int client, int argc)
{
	float pos[3];

	if( GetForwardSpawnPosition(client, pos) )
	{
		PrintToChat(client, "find pos: %f %f %f", pos[0], pos[1], pos[2]);
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}

public Action CmdClean(int client, int argc)
{
	CleanMap();
	PrintToChat(client, "cleaned");
	return Plugin_Handled;
}

void CleanMap()
{
	char classes[][] = {
		//"fog_volume",	// invisible building in window
		//"func_areaportalwindow", 	// invisible building in window
		//"prop_physics", // can remove radio!
		//"prop_dynamic", // can remove radio!
		//"point_template", // no radio!
		
		"env_soundscape",
		"env_sprite",
		
		"func_breakable",
		"func_brush",
		"func_detail_blocker",
		"func_lod",
		
		"keyframe_rope",
		"phys_bone_follower",
		
		"point_spotlight",
		"spotlight_end",
		"func_occluder",
		"func_illusionary",
		"info_particle_system",
		
		"info_remarkable",
		"infodecal",
		"move_rope"
	};
	int ent, cnt;
	for( int i = 0; i < sizeof(classes); i++ )
	{
		ent = -1;
		while( -1 != (ent = FindEntityByClassname(ent, classes[i])) )
		{
			RemoveEntity(ent);
			cnt++;
		}
	}
	//PrintToChatAll("Removed %i ents", cnt);
}

public Action CmdPanic(int client, int argc)
{
	if( g_hCvarPanicForever.IntValue == 1 )
	{
		StopMega();
		PrintToChat(client, "Mass Zombies stopped.");
		return Plugin_Handled;
	}
	StartMega();
	PrintToChat(client, "Mass Zombies started!");
	return Plugin_Handled;
}

void StartMega()
{
	CleanMap();
	
	g_hCvarPanicForever.SetInt(1, true, true);
	g_hCvarUpdateRate.SetFloat(0.1, true, true);
	if( g_hCvarVipDoubleJump != null )
	{
		g_hCvarVipDoubleJump.SetInt(0, true, true);
	}
	if( g_hCvarVipLongJump != null )
	{
		g_hCvarVipLongJump.SetInt(0, true, true);
	}
	if( g_hCvarAntiRush != null )
	{
		g_hCvarAntiRush.SetInt(1, true, true);
	}
	g_hCvarNoSpecials.SetInt(1, true, true);
	g_hCvarCrawl.SetInt(0, true, true);
	g_bSpawnMega = true;
	
	g_hTimerChase = CreateTimer(1.0, Timer_Chase, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	int client = GetRandomAliveSurvivorNonIncap();
	if( client > 0 )
	{
		ForcePanicEvent(client);
	}
}

void StopMega()
{
	g_hCvarPanicForever.SetInt(0, true, true);
	g_hCvarUpdateRate.RestoreDefault(true, true);
	if( g_hCvarVipDoubleJump != null )
	{
		g_hCvarVipDoubleJump.RestoreDefault(true, true);
	}
	if( g_hCvarVipLongJump != null )
	{
		g_hCvarVipLongJump.RestoreDefault(true, true);
	}
	if( g_hCvarAntiRush != null )
	{
		g_hCvarAntiRush.RestoreDefault(true, true);
	}
	g_hCvarNoSpecials.RestoreDefault(true, true);
	g_hCvarCrawl.RestoreDefault(true, true);
	g_bSpawnMega = false;
	
	delete g_hTimerChase;
}

public Action Timer_Chase(Handle timer)
{
	int target = L4D_GetHighestFlowSurvivorEx();
	
	if( target == -1 || !IsClientInGame(target) )
	{
		target = GetRandomAliveSurvivorNonIncap();
	}
	if( target > 0 )
	{
		Chase(target);
	}
	return Plugin_Continue;
}

void Reset()
{
	g_bMapStarted = false;
	g_bRoundStarted = false;
	g_bSpawnMega = false;
	g_iTankCount = 0;
	g_iTankWave = 0;
	g_fTimeAllowTank = GetEngineTime() + DELAY_FIRST_TANK_SPAWN;
	delete g_hTimerChase;
}

public void OnMapEnd()
{
	Reset();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();
}

public void OnMapStart()
{
	Reset();
	g_bMapStarted = true;
	if( g_bLate )
	{
		g_bRoundStarted = true;
	}
	g_bFinale = L4D_IsMissionFinalMap();
	
	g_iCommon = GetCommonsCount();
	g_iEntities = GetEntityCountEx();
	
	//PrintToChatAll("com: %i. tot: %i", g_iCommon, g_iEntities);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
	g_bRoundStarted = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_bFinale && g_bSpawnMega )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( IsTank(client) )
		{
			if( GetEngineTime() < g_fTimeAllowTank || g_iTankWave >= TANK_WAVES_ALLOWED )
			{
				KickClient(client);
				return;
			}
			
		}
	}
}

public void OnTankCountChanged(int iCount)
{
	if( iCount == 1 && g_iTankCount == 0 )
		OnFirstTankSpawn();
	
	g_iTankCount = iCount;
}

void OnFirstTankSpawn()
{
	++ g_iTankWave;
}

public void OnEntityDestroyed(int entity)
{
	static char class[32];
	static float fLastTime;
	
	if( g_bMapStarted )
	{
		-- g_iEntities;
	
		if( entity != INVALID_ENT_REFERENCE )
		{
			GetEntityClassname(entity, class, sizeof(class));
			if( class[0] == 'i' )
			{
				if( strcmp(class, CLASS_INFECTED) == 0 )
				{
					-- g_iCommon;
					if( g_iCommon < LIMIT_ZOMBIES_TO_FORWARD_SPAWN)
					{
						if( fLastTime == 0.0 || GetEngineTime() - fLastTime > 2.0 ) // not often than 2 sec.
						{
							CreateForwardWave();
							fLastTime = GetEngineTime();
						}
					}
				}
			}
		}
	}
}

void CreateForwardWave()
{
	float pos[3];
	int target = L4D_GetHighestFlowSurvivorEx();
	if( target == -1 )
		return;
	
	if( GetForwardSpawnPosition(target, pos) )
	{
		//PrintToChatAll("Spawn forward zombies!");
		SpawnZombies(FORWARD_ZOMBIES_COUNT, pos, false);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	bool isCommon;
	
	if( g_bMapStarted )
	{
		++ g_iEntities;

		if( classname[0] == 'i' )
		{
			if( strcmp(classname, CLASS_INFECTED) == 0 )
			{
				++ g_iCommon;
				isCommon = true;
				
				if( g_iCommon > LIMIT_ZOMBIES)
				{
					SDKHook(entity, SDKHook_SpawnPost, OnSpawnKill);
				}
			}
		}
	}

	if( isCommon && g_bRoundStarted && g_bSpawnMega && !g_bSkipHook )
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnCommon);
	}
}

public void OnSpawnKill(int Ent)
{
	if( Ent && IsValidEntity(Ent) )
	{
		RemoveEntity(Ent);
	}
}

public void OnSpawnCommon(int Ent)
{
	if( g_iEntities > (LIMIT_ENTITIES-5) || g_iCommon > (LIMIT_ZOMBIES-5) )
	{
		return;
	}
	
	static float vec[3], fLastRunTime, fEngineTime;
	
	GetEntPropVector(Ent, Prop_Data, "m_vecOrigin", vec);
	
	DataPack dp = new DataPack();
	dp.WriteFloat(vec[0]);
	dp.WriteFloat(vec[1]);
	dp.WriteFloat(vec[2]);
	
	fEngineTime = GetEngineTime();
	
	if( fEngineTime - fLastRunTime < MULTIPLY_INTERVAL )
	{
		g_fDelaySpawn = MULTIPLY_INTERVAL - (fEngineTime - fLastRunTime);
		if( g_fDelaySpawn < 0.1 ) g_fDelaySpawn = 0.1;
	}
	else {
		g_fDelaySpawn = MULTIPLY_INTERVAL;
	}
	fLastRunTime = fEngineTime + g_fDelaySpawn;
	
	CreateTimer(g_fDelaySpawn, Timer_SpawnZombieMega, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
	
	//PrintToChatAll("common: %i, tot: %i. del: %f", g_iCommon, g_iEntities, g_fDelaySpawn);
}

public Action Timer_SpawnZombieMega(Handle timer, DataPack dp)
{
	float vec[3];
	dp.Reset();
	vec[0] = dp.ReadFloat();
	vec[1] = dp.ReadFloat();
	vec[2] = dp.ReadFloat();
	
	SpawnZombies(MULTIPLY_COUNT, vec);
	
	return Plugin_Continue;
}

void SpawnZombies(int count, float pos[3], bool bCheckLimit = true)
{
	g_bSkipHook = true;
	
	for( int i = 0; i < count; i++  )
	{
		if( g_iEntities < LIMIT_ENTITIES )
		{
			if( bCheckLimit && g_iCommon > LIMIT_ZOMBIES )
			{
				//PrintToChatAll("exceed limit. Z = %i, ent: %i", g_iCommon, g_iEntities);
				break;
			}
			int zombie = CreateEntityByName("infected", -1);
			if( zombie != -1 )
			{
				TeleportEntity(zombie, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(zombie);
			}
		}
	}
	//PrintToChatAll("Real z count: %i", GetZombieCount());
	
	//TeleportEntity(GetHumanSurvivor(),  pos, NULL_VECTOR, NULL_VECTOR);
	
	g_bSkipHook = false;
}





/* ==========================================================================
		Stocks (specific)
===========================================================================*/

stock int GetEntityCountEx()
{
	int ent;
	int cnt;
	for(ent = 0; ent < 2048; ent++)
	{
		if( IsValidEntity(ent) || IsValidEdict(ent) )
		{
			cnt++;
		}
	}
	return cnt;
}

stock int GetRandomAliveSurvivorNonIncap()
{
	int client;
	ArrayList al = new ArrayList(ByteCountToCells(4));
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && /*!IsFakeClient(i) &&*/ GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerIncapped(i) )
		{
			al.Push(i);
		}
	}
	if( al.Length )
	{
		client = al.Get(GetRandomInt(0, al.Length - 1));
	}
	delete al;
	return client;
}

stock int GetHumanSurvivor()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i) )
		{
			return i;
		}
	}
	return 0;
}

stock int L4D_GetHighestFlowSurvivorEx(bool bFilterCapped = true, bool bFilterPinned = true)
{
	float flow, maxflow;
	int client = -1;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) )
		{
			if( bFilterCapped && IsPlayerIncapped(i) )
			{
				continue;
			}
			if( bFilterPinned && IsPlayerPinned(i) )
			{
				continue;
			}
			flow = L4D2Direct_GetFlowDistance(i);
			if( flow && flow != -9999.0 ) // Invalid flows
			{
				if( flow > maxflow )
				{
					maxflow = flow;
					client = i;
				}
			}
		}
	}
	return client;
}

stock bool GetForwardSpawnPosition(int client, float pos[3])
{
	const float MAX_Y_DELTA = 300.0; // don't allow to spawn under me (higher is OK)
	
	int iNavArea;
	float vOrigin[3], flow, fClientFlow;
	
	fClientFlow = L4D2Direct_GetFlowDistance(client);
	if( fClientFlow == 0.0 )
		return false;
	
	GetClientAbsOrigin(client, vOrigin);
	
	for( int i = 0; i < 5; i++)
	{
		if( L4D_GetRandomPZSpawnPosition(client, CLASS_TANK, 5, pos) )
		{
			if( !TR_PointOutsideWorld(pos) )
			{
				iNavArea = L4D_GetNearestNavArea(pos);
				if( iNavArea )
				{
					flow = L4D2Direct_GetTerrorNavAreaFlow(view_as<Address>(iNavArea));
					
					if( flow != 0.0 && flow > fClientFlow && vOrigin[2] - pos[2] < MAX_Y_DELTA )
					{
						return true;
					}
				}
			}
		}
		else {
			return false;
		}
	}
	return false;
}

