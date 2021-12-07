#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION 			"1.1"
#define PARTICLE_ARC_SYSTEM 	"electrical_arc_01_system"
//#define PARTICLE_ELEC			"electrical_arc_01_parent"
#define SOUND_ENERGY 			"ambient/energy/zap1.wav"

static ConVar hCvar_TankLaserAttackChance; 
static ConVar hCvar_TankLaserAttackRangeMin;
static ConVar hCvar_TankLaserAttackRangeMax;
static ConVar hCvar_TankLaserAttackDamageMin;
static ConVar hCvar_TankLaserAttackDamageMax;

static float fCvar_TankLaserAttackChance;
static float fCvar_TankLaserAttackRangeMin;
static float fCvar_TankLaserAttackRangeMax;
static float fCvar_TankLaserAttackDamageMin;
static float fCvar_TankLaserAttackDamageMax;

static int HookTankCount = 0; 
static int Sprite;

static int HookTanks[100];  
static float AttackTime[100];
static float LastTime[100];

static bool bL4D2;

public Plugin myinfo = 
{
	name 		= "[L4D1 AND L4D2] Tank's Laser Attack",
	author 		= "Ernecio (Satanael)",
	description = "Provides to Tank the ability to harm survivors laser attack",
	version 	= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/groups/American-Infernal"
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2 /* || !IsDedicatedServer() */ )
	{
		strcopy(error, err_max, "The Plugin \"Tank's Laser Attack\" only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
		return APLRes_SilentFailure;
	}
	
	bL4D2 = (engine == Engine_Left4Dead2);
	return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
 	hCvar_TankLaserAttackChance 	= CreateConVar("l4d_tank_laserattack_chance", 		"30.0", 		"Probability that the Tank gets the laser attack ability in spawn.\nIf the value is 0 = Plugin Disabled.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	hCvar_TankLaserAttackRangeMin 	= CreateConVar("l4d_tank_laserattack_range_min", 	"100.0", 		"Miinimum attack range.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	hCvar_TankLaserAttackRangeMax 	= CreateConVar("l4d_tank_laserattack_range_max", 	"300.0", 		"Maximum attack range.", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
	hCvar_TankLaserAttackDamageMin 	= CreateConVar("l4d_tank_laserattack_damage_min", 	"3.0", 			"Miinimum damage per attack.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	hCvar_TankLaserAttackDamageMax 	= CreateConVar("l4d_tank_laserattack_damage_max", 	"10.0", 		"Maximum damage per attack.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	CreateConVar(									"l4d_tank_laserattack",			PLUGIN_VERSION, 	"Tank Laser Attack Plugin Version.", FCVAR_NOTIFY|FCVAR_DONTRECORD );
	
	hCvar_TankLaserAttackChance.AddChangeHook(Event_ConVarChanged);
	hCvar_TankLaserAttackRangeMin.AddChangeHook(Event_ConVarChanged);
	hCvar_TankLaserAttackRangeMax.AddChangeHook(Event_ConVarChanged);
	hCvar_TankLaserAttackDamageMin.AddChangeHook(Event_ConVarChanged);
	hCvar_TankLaserAttackDamageMax.AddChangeHook(Event_ConVarChanged);
	
	HookEvent("tank_spawn", 	Event_TankSpawn, 	EventHookMode_Post);
	HookEvent("player_death", 	Event_PlayerDeath, 	EventHookMode_Pre);
	
	AutoExecConfig(true, "l4d_tank_laserattack");
}

/**
 * Called on configs executed.
 *
 * @noreturn
 */
public void OnConfigsExecuted()
{
	GetCvars();
}

void Event_ConVarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	fCvar_TankLaserAttackChance = hCvar_TankLaserAttackChance.FloatValue;
	fCvar_TankLaserAttackRangeMin = hCvar_TankLaserAttackRangeMin.FloatValue;
	fCvar_TankLaserAttackRangeMax = hCvar_TankLaserAttackRangeMax.FloatValue;
	fCvar_TankLaserAttackDamageMin = hCvar_TankLaserAttackDamageMin.FloatValue;
	fCvar_TankLaserAttackDamageMax = hCvar_TankLaserAttackDamageMax.FloatValue;
}

/**
 * The map is starting.
 *
 * @noreturn
 **/
public void OnMapStart()
{
	if (bL4D2)
		Sprite = PrecacheModel("materials/sprites/laserbeam.vmt"); 
	else
		Sprite = PrecacheModel("materials/sprites/laser.vmt");
	
	PrecacheParticle(PARTICLE_ARC_SYSTEM);
	PrecacheSound(SOUND_ENERGY, true);
	HookTankCount = 0;
}

/****************************************************************************************************/
/* 										<	EVENTS	>												*/
/****************************************************************************************************/

/**
 * Event callback (tank_spawn)
 * The Tank is about to spawn.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public Action Event_TankSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if( GetRandomFloat( 0.0, 100.0 ) <= fCvar_TankLaserAttackChance )
	{
		int client = GetClientOfUserId(hEvent.GetInt("userid"));
		CreateTimer(0.1, DelayHookTank, client, TIMER_FLAG_NO_MAPCHANGE );
	}
}

/**
 * Event callback (tank_killed)
 * The player is about to die.
 * 
 * @param hEvent 			The event handle.
 * @param sName	    		The name of the event.
 * @param bDontBroadcast 	If true, event is broadcasted to all clients, false if not.
 **/
public Action Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if ( client && IsClientInGame( client ) )
	{
		if ( IsTank( client ) )
			StopHookTank( client );
	}
}

/**
 * Handle delay timer to avoid possible errors.
 * 
 * @param timer 		handle for the timer
 * @param client		client id
 */
public Action DelayHookTank( Handle timer, any client )
{
	StartHookTank( client );
}

void StartHookTank( int client )
{
	StopHookTank( client );
	if ( IsTank( client ) )
	{ 
		int index = AddTank(client);
		AttackTime[index] = 0.0;
//		SDKHook( client, SDKHook_ThinkPost, SDK_ThinkTank );
		SDKHook( client, SDKHook_PreThink, SDK_ThinkTank );
	}
}

void StopHookTank( int client )
{
	if ( client > 0 )
	{	
//		SDKUnhook( client, SDKHook_ThinkPost, SDK_ThinkTank );
		SDKUnhook( client, SDKHook_PreThink, SDK_ThinkTank );
		DeleteTank( client );
	}
}

void DeleteTank( int client )
{
	int find =- 1;
	for( int i = 0; i < HookTankCount; i ++ )
	{
		if ( client == HookTanks[i] )
		{
			find = i; break;
		}
	}
	if ( find >= 0 )
	{
		HookTanks[find] = HookTanks[HookTankCount - 1]; 
		AttackTime[find] = AttackTime[HookTankCount - 1];
		LastTime[find] = LastTime[HookTankCount - 1]; 
		HookTankCount --;
	}
}

int FindTankIndex( int client )
{
	for ( int i = 0; i < HookTankCount; i ++ )
		if ( client == HookTanks[i] ) return i;
	return -1;
}

int AddTank( int client )
{
	HookTanks[HookTankCount ++] = client;
	return HookTankCount - 1;
}

public void SDK_ThinkTank( int client )
{
	if ( !IsTank( client ) )
	{
		StopHookTank(client);
		return;
	}
	
	int index = FindTankIndex( client );
	if( index < 0 )
	{
		StopHookTank(client);
		return;
	}
	
	float fTime = GetEngineTime();
	float fDuration = fTime - LastTime[index];
	if ( fDuration > 0.1 ) fDuration = 0.1;
	LastTime[index] = fTime;

	if ( fTime - AttackTime[index] > 2.0 )
	{
		float vTankAngles[3], vTankPos[3], vVictimPos[3];
		GetEntPropVector(client, Prop_Send, "m_angRotation", vTankAngles);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vTankPos);
		vTankPos[2] += 65.0;
		
		float fRange = GetRandomFloat( fCvar_TankLaserAttackRangeMin, fCvar_TankLaserAttackRangeMax );
		int EnemyClient = FindEnemy( client, vTankPos, fRange );
		if ( EnemyClient > 0 )
		{ 
			float fDamageA = 0.5; 
			float fDamageB = 0.0;
			float fDamage = 0.0;
			float fMinDamage = fCvar_TankLaserAttackDamageMin;
			float fMaxDamage = fCvar_TankLaserAttackDamageMax;
			float fDistance = 0.0;
			
			GetClientEyePosition( EnemyClient, vVictimPos );
			vVictimPos[2] -= 15.0;
			CreateEffects( client, vTankPos, vVictimPos ); 
			fDistance = GetVectorDistance(vTankPos, vVictimPos);
			
			fDamageB = fMinDamage + ( ( fRange - fDistance ) / fRange ) * ( fMaxDamage - fMinDamage );
			fDamage = fDamageA * 0.5 + fDamageB * 0.5;
			
			DoPointHurtForInfected( EnemyClient, EnemyClient, fDamage );  
		}
		AttackTime[index] = fTime;
	}
}

void CreateEffects( int client, float vPos[3], float vEndPos[3] )
{
	ShowParticle( vEndPos, NULL_VECTOR, PARTICLE_ARC_SYSTEM, 3.0 );
	EmitSoundToAll( SOUND_ENERGY, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vEndPos, NULL_VECTOR, true, 0.0 );
	EmitSoundToAll( SOUND_ENERGY, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vPos, NULL_VECTOR, true, 0.0 );
	
	int COLOR[4];
	GetEntityRenderColor( client, COLOR[0], COLOR[1], COLOR[2], COLOR[3] ); // Get the current RenderColor color from the Tank and replicate it in the laser color.
	
	TE_SetupBeamPoints( vPos, vEndPos, Sprite, 0, 0, 0, 0.5, 5.0, 5.0, 1, 0.0, COLOR, 0 );
	TE_SendToAll();
}
 
int FindEnemy( int client, float vTankPos[3], float fRange )
{ 
	client += 0;  
	if ( fRange == 0.0 ) return 0;
	
	float vMinDis = 9999.0;
	int   SelectedPlayer = 0;
	float vPlayerPos[3];
	
	for( int Count = 1; Count <= MaxClients; Count ++ )
	{
		if ( IsClientInGame( Count ) && GetClientTeam( Count ) == 2 && IsPlayerAlive( Count ) )
		{
			GetClientEyePosition( Count, vPlayerPos );
			float vDistance = GetVectorDistance( vPlayerPos, vTankPos ); 
			if( vDistance <= fRange && vDistance <= vMinDis)
			{
				if ( IfTwoPosVisible( client, vTankPos, vPlayerPos ) )
				{
					SelectedPlayer = Count;
					vMinDis = vDistance; 
				}
			}
		}
	} 
	return SelectedPlayer;	 
}

bool IfTwoPosVisible( int client, float vPosA[3], float vPosB[3] )
{
	bool bR = true;
	Handle trace = TR_TraceRayFilterEx( vPosB, vPosA, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor, client );
	if ( TR_DidHit( trace ) ) bR = false;
	
 	delete trace;
	return bR;
}

public bool DontHitSelfAndSurvivor( int entity, int mask, any data )
{
	if( entity == data ) return false;
	else if ( entity > 0 && entity <= MaxClients ) 
		if ( IsClientInGame(entity) && GetClientTeam(entity) == 2 )
			return false;
	return true;
}

void DoPointHurtForInfected( int victim, int attacker = 0, float FireDamage )
{
	char sIndex[10];
	int  PointHurt = CreatePointHurt();
	
	Format( sIndex, 20, "target%d", victim );
	DispatchKeyValue( victim, "targetname", sIndex );
	if (bL4D2) DispatchKeyValue( PointHurt, "DamageType", "-2130706422" );
	else 	   DispatchKeyValue( PointHurt, "DamageType", "8" );
	DispatchKeyValue( PointHurt, "DamageTarget", sIndex ); 
 	DispatchKeyValueFloat( PointHurt, "Damage", FireDamage );
	AcceptEntityInput( PointHurt,"Hurt",( attacker > 0) ? attacker: -1 );
	AcceptEntityInput( PointHurt,"kill" ); 
}

int CreatePointHurt()
{
	int pointHurt = CreateEntityByName("point_hurt");
	if ( pointHurt )
	{		
		DispatchKeyValue(pointHurt,"Damage","10");
		if (bL4D2) DispatchKeyValue(pointHurt,"DamageType","2");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}

/****************************************************************************************************/

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

/****************************************************************************************************/

public int ShowParticle(float vPos[3], float vAng[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename); 
		DispatchSpawn(particle);
		ActivateEntity(particle);
		TeleportEntity(particle, vPos, vAng, NULL_VECTOR);
		AcceptEntityInput(particle, "start");		
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		return particle;
	}
	return 0;
}


public Action DeleteParticles( Handle timer, any particle )
{
	if ( IsValidEntity( particle ) )
	{
		char sClassname[64];
		GetEdictClassname(particle, sClassname, sizeof(sClassname));
		if (StrEqual(sClassname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "kill");
		}
	}
}

/****************************************************************************************************/

/**
 * Validates if the current client is valid to run the plugin.
 *
 * @param client		The client index.
 * @return              False if the client is not the Tank, true otherwise.
 */
stock bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (bL4D2 ? 8 : 5 ))
			return true;
	}
	return false;
}

/****************************************************************************************************/