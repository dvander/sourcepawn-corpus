/* todo
- drone slave animation...
*/

#include <sourcemod>
#include <sdktools>
#include <l4d2_drone>
#pragma semicolon 1
#pragma newdecls required

#define SIZE					PLATFORM_MAX_PATH

#define MDL_DUMMY				"models/props_fairgrounds/alligator.mdl"
#define MDL_BODY				"models/f18/f18.mdl"
#define MDL_ARM					"models/weapons/melee/w_golfclub.mdl"
#define MDL_HELIY				"models/c2m5_helicopter_extraction/c2m5_helicopter.mdl"
#define MDL_ROTOR				"models/props_junk/garbage_sodacan01a.mdl"

#define SND_AMMOPICKUP			"sound/items/itempickup.wav"
#define SND_TIMEOUT				"ambient/machines/steam_release_2.wav"	//<< unused

#define DRONE_HEIGHT_HOOVER		20.0		// drone bounching up and down around this height measure from initail height
#define DRONE_HEIGHT_INITIAL	60.0		// drone initial spawn height against his master
#define MAXIMUM_SPEED			1000.0		// drone max forward speed.
#define INTERVAL_LIFE			0.1			// timer interval tick rate

ConVar	g_ConVarDroneEnable;

bool	g_bIsPetEnable;
bool	g_bIsRoundStart;
bool	g_bEnable_Chat			= true;		// toggle chat announce on off

// gathling gun
float	g_fGatling_Damage		= 20.0;		// value from 0.0 to 100.0 
float	g_fGatling_Range		= 300.0;	// the name says it

// perk health and ammo
bool	g_bIsPerkEnable			= true;		// enable/disable perk
float	g_fRecharge_Heal		= 60.0;		// how long heal button to fully rechange.. 60
float	g_fRecharge_Ammo		= 40.0;		// how long ammo button to fully rechange.. 40
int		g_iHealthToAdd			= 5;		// amount of health to add per circle
int		g_iAmmoToAdd			= 30;		// amount of ammo to add per circle
float	g_fRecharge_Short		= 1.0;		// interval between recharge if button presss failed

float	g_fDrone_Life[SIZE];
float	g_fButton_Life[SIZE][2];
float	g_fDrone_Force[SIZE][ePOS_SIZE];					// force value for thruster
int		g_iDrone_Perk[SIZE][ePERK_SIZE];					// perk button
int		g_iDrone_Thrust[SIZE][ePOS_SIZE];					// entity thruster
int		g_iDrone_EnvSteam[SIZE][ePOS_SIZE];					// cosmetic
int		g_iDrone_Master[SIZE]			= { -1, ... };		// drone target to follow
int		g_iDrone_Slave[SIZE]			= { -1, ... };		// drone helicopter, follow parent.
int		g_iClient_Drone[MAXPLAYERS+1]	= { -1, ... };		// guess what.. your crush... :)

///// debigging var /////


#define PLUGIN_NAME		"l4d2_drone"
#define PLUGIN_VERSION	"0.0b"
#define PLUGIN_TAG		"\x04[DRONE]:\x01"

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "GsiX",
	description	= "Player drone.. pet.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=328417"
}

public void OnPluginStart()
{
	char plName[16];
	FormatEx( plName, sizeof( plName ), "%s_version", PLUGIN_NAME );
	
	CreateConVar( plName, PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
	//g_ConVarDroneEnable	= CreateConVar( "l4d2_drone_enabled",	"1",	"0:Off, 1:On,  Toggle plugin on/off", FCVAR_SPONLY|FCVAR_NOTIFY );
	g_ConVarDroneEnable	= CreateConVar( "l4d2_drone_enabled",	"1",	"0:Off, 1:On,  Toggle plugin on/off", FCVAR_DONTRECORD );
	//AutoExecConfig( true, PLUGIN_NAME );
	
	HookEvent( "round_start",	EVENT_RoundStartEnd );
	HookEvent( "round_end",		EVENT_RoundStartEnd );
	HookEvent( "player_spawn",	EVENT_PlayerSpawnDeath );
	HookEvent( "player_death",	EVENT_PlayerSpawnDeath );
	
	g_ConVarDroneEnable.AddChangeHook( CVAR_Changed );
	UpdateCVar();
	
	// bind f8 "say /drone_spawn 90"
	RegAdminCmd( "drone_spawn", AdminDroneSpawn, ADMFLAG_GENERIC );
	
	// bind f7 "say /drone_home"
	RegAdminCmd( "drone_home", AdminDroneCall, ADMFLAG_GENERIC );
	
	// bind KP_INS "say /pet_move 0"
	// bind KP_HOME "say /pet_move 1"
	// bind KP_UPARROW "say /pet_move 2"
	// bind KP_LEFTARROW "say /pet_move 3"
	// bind KP_5 "say /pet_move 4"
	// bind KP_END "say /pet_move 5"
	// bind KP_DOWNARROW "say /pet_move 6"
	RegAdminCmd( "pet_move", AdminModelMove, ADMFLAG_GENERIC ); //<< developer command
}

public void OnMapStart()
{
	PrecacheModel( MDL_DUMMY, true );
	PrecacheModel( MDL_BODY, true );
	PrecacheModel( MDL_ROTOR, true );
	PrecacheModel( MDL_ARM, true );
	PrecacheModel( MDL_HELIY, true );
	
	PrecacheSound( SND_AMMOPICKUP, true );
	PrecacheSound( SND_TIMEOUT, true );
}

public Action AdminModelMove( int client, any args )
{
	if ( IsSurvivorValid( client ))
	{
		if ( args < 1 )
		{
			ReplyToCommand( client, "%s Usage: pet_move 0, 1, 2, 3, 4, 5, 6(args). 1 arg at a time", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		int move = StringToInt( arg1 );
		if( move < 0 || move > 6 )
		{
			ReplyToCommand( client, "%s valid args 0 to 6", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		int drone = EntRefToEntIndex( g_iClient_Drone[client] );
		int slave = EntRefToEntIndex( g_iDrone_Slave[drone] );
		if( IsEntityValid( slave ))
		{
			float pos_start[3];
			float ang_start[3];
			GetEntOrigin( slave, pos_start, 0.0 );
			GetEntAngle( slave, ang_start, 0.0, 0 );
			if( move == 0 )
			{
				ReplyToCommand( client, "%s POS: %f | %f | %f", PLUGIN_TAG, pos_start[0], pos_start[1], pos_start[2] );
				ReplyToCommand( client, "%s ANG: %f | %f | %f", PLUGIN_TAG, ang_start[0], ang_start[1], ang_start[2] );
			}
			else if( move == 1 )
			{
				pos_start[0] += 1.0;
				TeleportEntity( slave, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 2 )
			{
				pos_start[0] -= 1.0;
				TeleportEntity( slave, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 3 )
			{
				pos_start[1] += 1.0;
				TeleportEntity( slave, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 4 )
			{
				pos_start[1] -= 1.0;
				TeleportEntity( slave, pos_start, NULL_VECTOR, NULL_VECTOR );
			}
			else if( move == 5 )
			{
				ang_start[1] += 1.0;
				TeleportEntity( slave, NULL_VECTOR, ang_start, NULL_VECTOR );
			}
			else if( move == 6 )
			{
				ang_start[1] -= 1.0;
				TeleportEntity( slave, NULL_VECTOR, ang_start, NULL_VECTOR );
			}
		}
		else
		{
			ReplyToCommand( client, "%s invalid Helicopter to move", PLUGIN_TAG );
		}
	}
	return Plugin_Handled;
}

public Action AdminDroneSpawn( int client, any args )
{
	if ( IsSurvivorValid( client ))
	{
		if ( g_iClient_Drone[client] != -1 )
		{
			ReplyToCommand( client, "%s You still have drone", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		if ( args < 1 )
		{
			ReplyToCommand( client, "%s Usage: drone_spawn 10(time in secs)", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		char arg1[8];
		GetCmdArg( 1, arg1, sizeof( arg1 ));
		float time = StringToFloat( arg1 );
		if( time < 1.0 )
		{
			ReplyToCommand( client, "%s first Args time in secs. time >= 1 sec", PLUGIN_TAG );
			return Plugin_Handled;
		}
		
		float pos_start[3];
		float ang_start[3];
		float pos_buffe[3];
		
		GetClientEyePosition( client, pos_start );
		GetClientEyeAngles( client, ang_start );
		if( TraceRayGetEndpoint( pos_start, ang_start, client, pos_buffe ))
		{
			pos_buffe[2] += DRONE_HEIGHT_INITIAL;
			ang_start[0] = 0.0;
			ang_start[2] = 0.0;
			int drone = CreateLovelyDrone( client, pos_buffe, ang_start, time );
			if( IsEntityValid( drone ))
			{
				g_iClient_Drone[client] = EntIndexToEntRef( drone );
				PrintToChatAll( "%s \x03Drone_%N \x01created", PLUGIN_TAG, client );
			}
		}
	}
	return Plugin_Handled;
}

public Action AdminDroneCall( int client, any args )
{
	if ( IsSurvivorValid( client ))
	{
		int drone = EntRefToEntIndex( g_iClient_Drone[client] );
		if( drone > 0 && IsValidEntity( drone ))
		{
			float pos[3];
			float ang[3];
			GetEntOrigin( client, pos, DRONE_HEIGHT_INITIAL );
			GetEntAngle( client, ang, 0.0, 0 );
			TeleportEntity( drone, pos, ang, NULL_VECTOR );
			ReplyToCommand( client, "%s Calling Drone home", PLUGIN_TAG );
		}
		else
		{
			ReplyToCommand( client, "%s You have no drone", PLUGIN_TAG );
		}
	}
	return Plugin_Handled;
}

public void CVAR_Changed( Handle convar, const char[] oldValue, const char[] newValue )
{
	UpdateCVar();
}

void UpdateCVar()
{
	g_bIsPetEnable = g_ConVarDroneEnable.BoolValue;
}

public Action OnPlayerRunCmd( int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon )
{
	if (( buttons & IN_USE ) && g_bIsPerkEnable )
	{
		float pos_start[3];
		float ang_start[3];
		GetClientEyePosition( client, pos_start );
		GetClientEyeAngles( client, ang_start );
		int ent = TraceRayGetEntity( pos_start, ang_start, client );
		if( IsEntityValid( ent ))
		{
			float pos_ent[3];
			GetEntOrigin( ent, pos_ent, 0.0 );
			float dist = GetVectorDistance( pos_ent, pos_start );
			if( dist < 1100.0 )	//<< this number dont make sense
			{
				int drone = GetEntityParent( ent );
				if( IsEntityValid( drone ) && GetOwner( drone ) == client )
				{
					char name[32];
					GetEntityName( ent, name );
					if( StrEqual( name, NAME_HEAL, false ) && g_fButton_Life[drone][ePERK_HEAL_BTN] == 0.0 )
					{
						int health[2];
						float buffer[2];
						GetPlayerHealth( client, health, buffer );
						if( health[0] < 100 )
						{
							SetPerkButton( drone, ePERK_HEAL_BTN, g_fRecharge_Heal );
							
							health[0] += g_iHealthToAdd;
							if( health[0] >= 100 )
							{
								health[0] = 100;
								buffer[0] = 0.0;
							}
							
							if( buffer[0] > 0.0 )
							{
								int health_new = health[0] + RoundToFloor( buffer[0] );
								if( health_new > 100.0 )
								{
									buffer[0] = 100.0 - float( health[0] );
								}
							}
							SetPlayerHealth( client, health[0], buffer[0] );
							if( g_bEnable_Chat ) { PrintToChat( client, "%s Health added: \x05%d", PLUGIN_TAG, g_iHealthToAdd ); }
						}
						else
						{
							SetPerkButton( drone, ePERK_HEAL_BTN, g_fRecharge_Short );
							if( g_bEnable_Chat ) { PrintToChat( client, "%s You still healty", PLUGIN_TAG );}
						}
					}
					else if( StrEqual( name, NAME_AMMO, false ) && g_fButton_Life[drone][ePERK_AMMO_BTN] == 0.0 )
					{
						if( GiveSurvivorAmmo( client, g_iAmmoToAdd ))
						{
							SetPerkButton( drone, ePERK_AMMO_BTN, g_fRecharge_Ammo );
							EmitSoundToClient( client, SND_AMMOPICKUP );
							if( g_bEnable_Chat ) { PrintToChat( client, "%s Ammo added: \x05%d", PLUGIN_TAG, g_iAmmoToAdd ); }
						}
						else
						{
							SetPerkButton( drone, ePERK_AMMO_BTN, g_fRecharge_Short );
							if( g_bEnable_Chat ) { PrintToChat( client, "%s Equip primary weapon first", PLUGIN_TAG ); }
						}
					}
				}
			}
		}
	}
	
	if (( buttons & IN_USE ) && ( buttons & IN_ATTACK2 ))
	{
		if( IsSurvivorValid( client ))
		{
			int pet = EntRefToEntIndex( g_iClient_Drone[client] );
			if( IsEntityValid( pet ))
			{
				float pos[3];
				float ang[3];
				GetClientEyePosition( client, pos );
				GetClientEyeAngles( client, ang );
				int target = TraceRayGetEntity( pos, ang, client );
				if( target > 0 && IsValidEdict( target ))
				{
					
					int newtarget = EntIndexToEntRef( target );
					if( g_iDrone_Master[pet] != newtarget && g_bEnable_Chat )	 // anti spam
					{
						if( target < MaxClients )
						{
							PrintToChat( client, "%s Acquiring target \x05%N", PLUGIN_TAG, target );
						}
						else
						{
							char entName[16];
							GetEntityClassname( target, entName, sizeof( entName ));
							PrintToChat( client, "%s Acquiring target \x05%s", PLUGIN_TAG, entName );
						}
					}
					g_iDrone_Master[pet] = newtarget;
				}
				else
				{
					if( g_iDrone_Master[pet] != -1 && g_bEnable_Chat ) // anti spam
					{
						PrintToChat( client, "%s Target cancled", PLUGIN_TAG );
					}
					g_iDrone_Master[pet] = -1;
				}
			}
		}
	}
	return Plugin_Continue;
}

public void EVENT_RoundStartEnd ( Event event, const char[] name, bool dontBroadcast )
{
	if( StrEqual( name, "round_start", false ))
	{
		g_bIsRoundStart = true;
	}
	else if( StrEqual( name, "round_end", false ))
	{
		g_bIsRoundStart = false;
	}
}

public void EVENT_PlayerSpawnDeath( Event event, const char[] name, bool dontBroadcast )
{
	if( !g_bIsPetEnable ) return;
	
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	if ( IsSurvivorValid( client ))
	{
		if( StrEqual( name, "player_spawn", false ))
		{
			// spawn
			g_iClient_Drone[client] = -1;
		}
		else if( StrEqual( name, "player_death", false ))
		{
			// death
		}
	}
}

int CreateLovelyDrone( int owner, float pos[3], float ang[3], float life )
{
	int drone = CreatePropPhysicsOverride( MDL_DUMMY, pos, ang, 0.01 );
	if( IsEntityValid( drone ))
	{
		g_iDrone_Master[drone] = -1;
		SetOwner( drone, owner );
		
		float pos_attch[4][3];
		float pos_origin[3]	= { 0.0, 0.0, 0.0 };
		float ang_adjust[3]	= { 0.0, 0.0, 0.0 };
		float arm_length	= 15.0;
		float ang_start		= 45.0;
		float ang_incre		= 90.0;
		
		///////////////////////////////////////
		//////////////// ROTOR ////////////////
		///////////////////////////////////////
		int temp, dummy;
		for( int i = ePOS_ROTOR_1; i <= ePOS_ROTOR_4; i++ )
		{
			// thrust to lift our drone at 4 arm pos. we build 1 by 1
			SetVector( 0.0, 0.0, 0.0, pos_attch[i] );
			GetLocalAttachmentPos( ang_start, (arm_length - 2.0), pos_attch[i] );
			
			pos_attch[i][2] = 1.0; 
			SetVector( -90.0, ang_start, 0.0, ang_adjust );
			CreatePropDynamicOverride( drone, MDL_ARM, pos_attch[i], ang_adjust, 0.65, g_iColor_White, 255 );
			
			SetVector( 0.0, 0.0, 0.0, pos_attch[i] );
			GetLocalAttachmentPos( ang_start, arm_length, pos_attch[i] );
			
			// rotor force
			SetVector( -90.0, 0.0, 0.0, ang_adjust );
			g_fDrone_Force[drone][i] = FORCE_UPWARD;
			temp = CreateThrust( drone, pos_attch[i], ang_adjust, g_fDrone_Force[drone][i] );
			SaveDroneEntity( drone, temp, g_iDrone_Thrust, i );
			
			// crocodile model, act as rotor parent
			SetVector( 0.0, 0.0, 0.0, ang_adjust );
			dummy = CreatePropDynamicOverride( drone, MDL_DUMMY, pos_attch[i], ang_adjust, 0.01, g_iColor_White, 0 );
			
			// rotor skin coke can
			SetVector( 0.0, 0.0, 1.0, pos_origin );
			SetVector( 180.0, 0.0, 0.0, ang_adjust );
			CreatePropDynamicOverride( dummy, MDL_ROTOR, pos_origin, ang_adjust, 1.0, g_iColor_Red, 255 );
			
			// rotor exaust env_steam
			SetVector( 0.0, 0.0, -3.0, pos_origin );
			SetVector( 90.0, 0.0, 0.0, ang_adjust );
			temp = CreateEnvSteam( dummy, pos_origin, ang_adjust, g_iColor_Exaust );
			SaveDroneEntity( drone, temp, g_iDrone_EnvSteam, i );
			
			ang_start += ang_incre;
		}
		
		
		///////////////////////////////////////
		///////////////// TAIL ////////////////
		///////////////////////////////////////
		// tail env_steam
		SetVector( -18.0, -2.5, -1.0, pos_origin );
		SetVector( 180.0, 0.0, 0.0, ang_adjust );
		temp = CreateEnvSteam( drone, pos_origin, ang_adjust, g_iColor_Exaust );
		SaveDroneEntity( drone, temp, g_iDrone_EnvSteam, ePOS_EXAUST_LEFT );
		
		SetVector( -18.0, 2.5, -1.0, pos_origin );
		SetVector( 180.0, 0.0, 0.0, ang_adjust );
		temp = CreateEnvSteam( drone, pos_origin, ang_adjust, g_iColor_Exaust );
		SaveDroneEntity( drone, temp, g_iDrone_EnvSteam, ePOS_EXAUST_RIGHT );
		
		
		///////////////////////////////////////
		////////////// NAVIGATION /////////////
		///////////////////////////////////////
		// thrust push forward
		SetVector( -2.0, 0.0, 0.0, pos_origin );
		SetVector( 0.0, 0.0, 0.0, ang_adjust );
		g_fDrone_Force[drone][ePOS_ENGINE] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][ePOS_ENGINE] );
		SaveDroneEntity( drone, temp, g_iDrone_Thrust, ePOS_ENGINE );
		
		// thrust to push left right, force positive move right, negative left
		SetVector( 0.0, 1.0, 0.0, pos_origin );
		SetVector( 0.0, ANGLE_EAST, 0.0, ang_adjust );
		g_fDrone_Force[drone][ePOS_SLATS] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][ePOS_SLATS] );
		SaveDroneEntity( drone, temp, g_iDrone_Thrust, ePOS_SLATS );
		
		// thrust to push against nort east
		SetVector( 1.0, 1.0, 0.0, pos_origin );
		SetVector( 0.0, ANGLE_NTEAST, 0.0, ang_adjust );
		g_fDrone_Force[drone][ePOS_NORTH_EAST] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][ePOS_NORTH_EAST] );
		SaveDroneEntity( drone, temp, g_iDrone_Thrust, ePOS_NORTH_EAST );
		
		// thrust to push against nort west
		SetVector( 1.0, -1.0, 0.0, pos_origin );
		SetVector( 0.0, ANGLE_NTWEST, 0.0, ang_adjust );
		g_fDrone_Force[drone][ePOS_NORTH_WEST] = FORCE_NONE;
		temp = CreateThrust( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][ePOS_NORTH_WEST] );
		SaveDroneEntity( drone, temp, g_iDrone_Thrust, ePOS_NORTH_WEST );
		
		// thrust to rotate left right
		SetVector( -1.0, 0.0, 0.0, pos_origin );
		SetVector( 0.0, 0.0, 0.0, ang_adjust );
		g_fDrone_Force[drone][ePOS_RUDDER] = FORCE_NONE;
		temp = CreateTorque( drone, pos_origin, ang_adjust, g_fDrone_Force[drone][ePOS_RUDDER] );
		SaveDroneEntity( drone, temp, g_iDrone_Thrust, ePOS_RUDDER );
		
		
		///////////////////////////////////////
		/////////////// COSMETIC //////////////
		///////////////////////////////////////
		// body F18 main skin what appear to player
		SetVector( -7.0, 0.0, 0.0, pos_origin );
		SetVector( 0.0, 0.0, 0.0, ang_adjust );
		CreatePropDynamicOverride( drone, MDL_BODY, pos_origin, ang_adjust, 0.05, g_iColor_White, 255 );
		
		// small small Helicopter
		SetVector( 74.0, 104.0, 10.0, pos_origin );
		SetVector( 0.0, 91.0, 0.0, ang_adjust );
		temp = CreatEntAnimation( drone, MDL_HELIY, "hover1", pos_origin, ang_adjust, 0.03 );
		g_iDrone_Slave[drone] = EntIndexToEntRef( temp );
		
		
		///////////////////////////////////////
		//////////////// BUTTON ///////////////
		///////////////////////////////////////
		if( g_bIsPerkEnable )
		{
			// button for the ammo and health keypress.. prop dynamic just wont stop ray trace //<< need fix
			SetVector( 15.0, 0.0, 0.0, pos_origin );
			SetVector( 0.0, 90.0, 170.0, ang_adjust );
			temp = CreateButton( drone, MDL_DUMMY, NAME_HEAL, pos_origin, ang_adjust, 0.25, g_iColor_Green, 0 ); // health
			g_iDrone_Perk[drone][ePERK_HEAL_BTN] = EntIndexToEntRef( temp );
			
			SetVector( 15.0, 0.0, -5.0, pos_origin );
			SetVector( 90.0, 0.0, 0.0, ang_adjust );
			temp = CreateLight( drone, pos_origin, ang_adjust, g_iColor_Green );
			g_iDrone_Perk[drone][ePERK_HEAL_LIGHT] = EntIndexToEntRef( temp );
			
			SetVector( -10.0, 0.0, -2.0, pos_origin );
			SetVector( 0.0, 90.0, 170.0, ang_adjust );
			temp = CreateButton( drone, MDL_DUMMY, NAME_AMMO, pos_origin, ang_adjust, 0.25, g_iColor_Green, 0 ); // ammo
			g_iDrone_Perk[drone][ePERK_AMMO_BTN] = EntIndexToEntRef( temp );
			
			SetVector( -10.0, 0.0, -7.0, pos_origin );
			SetVector( 90.0, 0.0, 0.0, ang_adjust );
			temp = CreateLight( drone, pos_origin, ang_adjust, g_iColor_Blue );
			g_iDrone_Perk[drone][ePERK_AMMO_LIGHT] = EntIndexToEntRef( temp );
			SetPerkButton( drone, ePERK_HEAL_BTN, g_fRecharge_Heal );
			SetPerkButton( drone, ePERK_AMMO_BTN, g_fRecharge_Ammo );
		}
		
		///////////////////////////////////////
		////////////////// GUN ////////////////
		///////////////////////////////////////
		// Gatling Gun << if the perk button model too big, it will block this gun, be mind
		SetVector( 30.0, 0.0, -10.0, pos_origin );
		CreateGatlingGun( drone, pos_origin, ang_adjust, g_fGatling_Damage, g_fGatling_Range );
		
		
		///////////////////////////////////////
		/////////////// CONSTRAIN /////////////
		///////////////////////////////////////
		// constrain our drone to always stand upward
		SetVector( 90.0, 0.0, 0.0, ang_adjust );
		CreateUprightLifting( drone, pos_origin, ang_adjust );
		
		// constrain our drone to always stand flat against world
		SetVector( 0.0, 0.0, 0.0, ang_adjust );
		CreateUprightConstrain( drone, pos_origin, ang_adjust );
		
		g_fDrone_Life[drone] = life;
		CreateTimer( INTERVAL_LIFE, Timer_DroneThink, EntIndexToEntRef( drone ), TIMER_REPEAT );
	}
	return drone;
}

public Action Timer_DroneThink( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if ( IsEntityValid( entity ))
	{
		int client = GetOwner( entity );
		if( IsSurvivorValid( client ))
		{
			if( g_fDrone_Life[entity] > 0.0 && g_bIsRoundStart )
			{
				g_fDrone_Life[entity] -= INTERVAL_LIFE;
				
				if( g_bIsPerkEnable )
				{
					if( g_fButton_Life[entity][ePERK_HEAL_BTN] > 0.0 )
					{
						g_fButton_Life[entity][ePERK_HEAL_BTN] -= INTERVAL_LIFE;
						if( g_fButton_Life[entity][ePERK_HEAL_BTN] <= 0.0 )
						{
							SetPerkButton( entity, ePERK_HEAL_BTN, 0.0 );
						}
					}
					if( g_fButton_Life[entity][ePERK_AMMO_BTN] > 0.0 )
					{
						g_fButton_Life[entity][ePERK_AMMO_BTN] -= INTERVAL_LIFE;
						if( g_fButton_Life[entity][ePERK_AMMO_BTN] <= 0.0 )
						{
							SetPerkButton( entity, ePERK_AMMO_BTN, 0.0 );
						}
					}
				}
				
				float pos_entity[3];
				float pos_target[3];
				GetEntOrigin( entity, pos_entity, 0.0 );
				GetEntOrigin( client, pos_target, DRONE_HEIGHT_INITIAL );
				
				if( g_iDrone_Master[entity] != -1 )
				{
					int target = EntRefToEntIndex( g_iDrone_Master[entity] );
					if( target > 0 && IsValidEdict( target ))
					{
						GetEntOrigin( target, pos_target, DRONE_HEIGHT_INITIAL );
					}
					else
					{
						g_iDrone_Master[entity] = -1;
						if( g_bEnable_Chat ) { PrintToChat( client, "%s Target cleared", PLUGIN_TAG );}
					}
				}
				
				Think_Lifting( entity, pos_entity, pos_target );
				Think_Direction( entity, pos_entity, pos_target );

				float ang_entity[3];
				float pos_scanner[3];
				float distance[eDIR_SIZE] = { 1000.0, ... };
				GetEntOrigin( entity, pos_scanner, 2.0 ); //<< lift the sscanner 2 unit so it not hit the perk button
				GetEntAngle( entity, ang_entity, 0.0, 0 );
				Think_Scanner( entity, pos_scanner, ang_entity, distance );
				
				Think_Forward( entity, pos_entity, pos_target, distance[eDIR_NORTH] );
				Think_Obstacle45( entity, ePOS_NORTH_EAST, distance[eDIR_NORTH_EAST] ); //<< might have a problem on narrow path.. she will not enter
				Think_Obstacle45( entity, ePOS_NORTH_WEST, distance[eDIR_NORTH_WEST] ); //<< might have a problem on narrow path.. she will not enter
				
				// only 1 side sensor active at a time for the gear animation to play
				// shorter distance win
				float direction	= -1.0;
				float walldist	= distance[eDIR_EAST];
				if( distance[eDIR_WEST] < distance[eDIR_EAST] )
				{
					direction = 1.0;
					walldist = distance[eDIR_WEST];
				}
				Think_Obstacle90( entity, ePOS_SLATS, walldist, direction );
				return Plugin_Continue;
			}
			g_iClient_Drone[client] = -1;
		}
		Entity_KillHierarchy( entity );
	}
	return Plugin_Stop;
}

void Think_Lifting( int entity, float pos_entity[3], float pos_target[3] )
{
	// positive value apply force push downward
	// negative value apply force push upward
	float tolerance = 5.0;
	float distance	= pos_entity[2] - pos_target[2];
	float direction = distance - DRONE_HEIGHT_HOOVER;
	if( direction > (tolerance * -1.0 ) && direction < tolerance )
	{
		direction = FORCE_FALL * -1.0;
	}
	
	float force = FORCE_UPWARD - direction;
	if( g_fDrone_Force[entity][ePOS_ROTOR_1] != force )
	{
		int temp;
		for( int i = ePOS_ROTOR_1; i <= ePOS_ROTOR_4; i++ )
		{
			g_fDrone_Force[entity][i] = force;
			temp = EntRefToEntIndex( g_iDrone_Thrust[entity][i] );
			if( IsEntityValid( temp ))
			{
				SetThrusterTorque( temp, force );
			}
			
			temp = EntRefToEntIndex( g_iDrone_EnvSteam[entity][i] );
			if( IsEntityValid( temp ))
			{
				if( force < 180.0 )
				{
					SetSteamLength( temp, ENVSTEAM_IDLE );
				}
				else if( force < 203.0 )
				{
					SetSteamLength( temp, ENVSTEAM_GEARONE );
				}
				else
				{
					SetSteamLength( temp, ENVSTEAM_GEARTWO );
				}
			}
		}
	}
}

void Think_Direction( int entity, float pos_entity[3], float pos_target[3] )
{
	float pos_buff[3];
	SetVector( pos_target[0], pos_target[1], pos_entity[2], pos_buff );
	
	float ang_entity[3];
	float ang_guide[3];
	GetEntAngle( entity, ang_entity, 0.0, 0 );
	MakeVectorFromPoints( pos_entity, pos_buff, ang_guide );
	NormalizeVector( ang_guide, ang_guide );
	GetVectorAngles( ang_guide, ang_guide );
	
	float tolerance = 5.0;
	float direction = AngleDifference( ang_guide[1], ang_entity[1] ) * -1.0;
	if( direction > (tolerance * -1.0 ) && direction < tolerance )
	{
		direction = 0.0;
	}
	
	// negative value turn right
	// positive value turn left
	float force = FORCE_ROTATE * direction;
	
	if( g_fDrone_Force[entity][ePOS_RUDDER] != force )
	{
		g_fDrone_Force[entity][ePOS_RUDDER] = force;
		
		int length = ENVSTEAM_IDLE;
		float ang_ang[3] = { 180.0, 0.0, 0.0 };
		if( force == FORCE_NONE )
		{
			ang_ang[AXIS_YAW] = GEAR_NONE;
		}
		else
		{
			length = ENVSTEAM_GEARONE;
			ang_ang[AXIS_YAW] = GEAR_ONE;
			
			// we not fly forward at high velocity. show aggresive tail animation.
			if( g_fDrone_Force[entity][ePOS_ENGINE] < 200.0 )
			{
				ang_ang[AXIS_YAW] = GEAR_TWO;
			}
			
			if( force > FORCE_NONE )
			{
				ang_ang[AXIS_YAW] *= -1.0;
			}
		}

		int temp1 = EntRefToEntIndex( g_iDrone_EnvSteam[entity][ePOS_EXAUST_LEFT] );
		int temp2 = EntRefToEntIndex( g_iDrone_EnvSteam[entity][ePOS_EXAUST_RIGHT] );
		if( IsEntityValid( temp1 ) && IsEntityValid( temp2 ))
		{
			TeleportEntity( temp1, NULL_VECTOR, ang_ang, NULL_VECTOR );
			TeleportEntity( temp2, NULL_VECTOR, ang_ang, NULL_VECTOR );
			SetSteamLength( temp1, length );
			SetSteamLength( temp2, length );
		}
		
		int temp = EntRefToEntIndex( g_iDrone_Thrust[entity][ePOS_RUDDER] );
		if( IsEntityValid( temp ))
		{
			SetThrusterTorque( temp, force );
		}
	}
}

void Think_Scanner( int entity, float pos_entity[3], float ang_entity[3], float distance[eDIR_SIZE] )
{
	float vec_temp[3];
	float dist_new;
	for( float i = ANGLE_EAST; i <= ANGLE_WEST; i += ANGLE_INCREMENT )
	{
		SetVector( ang_entity[0], ang_entity[1], ang_entity[2], vec_temp );
		vec_temp[AXIS_YAW] += i;
		if( TraceRayGetEndpoint( pos_entity, vec_temp, entity, vec_temp ))
		{
			dist_new = GetVectorDistance( pos_entity, vec_temp );
			if( i <= ANGLE_NTEAST )
			{
				if( dist_new < distance[eDIR_EAST] )
				{
					distance[eDIR_EAST] = dist_new;
				}
			}
			else if( i > ANGLE_NTEAST && i <= ANGLE_NORTH_R )
			{
				if( dist_new < distance[eDIR_NORTH_EAST] )
				{
					distance[eDIR_NORTH_EAST] = dist_new;
				}
			}
			else if( i > ANGLE_NORTH_R && i < ANGLE_NORTH_L )
			{
				if( dist_new < distance[eDIR_NORTH] )
				{
					distance[eDIR_NORTH] = dist_new;
				}
			}
			else if( i >= ANGLE_NORTH_L && i < ANGLE_NTWEST )
			{
				if( dist_new < distance[eDIR_NORTH_WEST] )
				{
					distance[eDIR_NORTH_WEST] = dist_new;
				}
			}
			else
			{
				if( dist_new < distance[eDIR_WEST] )
				{
					distance[eDIR_WEST] = dist_new;
				}
			}
		}
	}
}

void Think_Forward( int entity, float pos_entity[3], float pos_target[3], float dist_North )
{
	float vec_buff[3];
	SetVector( pos_target[0], pos_target[1], pos_entity[2], vec_buff );
	float dist	= GetVectorDistance( pos_entity, vec_buff );
	float force	= FORCE_NONE;
	
	// thruster go forward
	if( dist > 100.0 )
	{
		force = FORCE_FORWARD * dist;
		if( force > MAXIMUM_SPEED )
		{
			force = MAXIMUM_SPEED;
		}
	}
	
	// front have obstacle, negate engine thrust force
	if( dist_North <= SAFE_RADIUS1 )
	{
		dist = dist_North;
		float mult = (SAFE_RADIUS1 - dist_North) * SAFE_MULTIPLIER;
		if( mult < 0.0 )
		{
			mult = 0.0;
		}
		
		force = FORCE_OBSTACLE * mult * -1.0;
		//PrintToChatAll( "%s Force %f | Direction %s", PLUGIN_TAG, ( force > 0.0 ? "Forward":"Reverse"));
	}
	
	if( g_fDrone_Force[entity][ePOS_ENGINE] != force )
	{
		g_fDrone_Force[entity][ePOS_ENGINE] = force;
		SetRotorGear( entity, ePOS_ENGINE, force, dist );
		int thrust = EntRefToEntIndex( g_iDrone_Thrust[entity][ePOS_ENGINE] );
		if( IsEntityValid( thrust ))
		{
			SetThrusterTorque( thrust, force );
		}
		/*
		if( g_fDrone_Force[entity][ePOS_ENGINE] == FORCE_NONE && g_fDrone_Force[entity][ePOS_RUDDER] == FORCE_NONE )
		{
			EmitSoundToAll( SND_TIMEOUT, entity, SNDCHAN_AUTO );
		}*/
		//PrintToChatAll( "Dist: %f | Force: %f", dist, force );
	}
}

void Think_Obstacle45( int entity, int region, float distance )
{
	float force = FORCE_NONE;
	if( distance <= SAFE_RADIUS1 )
	{
		float mult = (SAFE_RADIUS1 - distance) * SAFE_MULTIPLIER;
		if( mult < FORCE_NONE )
		{
			mult = FORCE_NONE;
		}
		force = FORCE_OBSTACLE * mult * -1.0;	// thruster facing tail so negative to flip the force
	}
	
	if( g_fDrone_Force[entity][region] != force )
	{
		g_fDrone_Force[entity][region] = force;
		// has no gear animation
		int trust = EntRefToEntIndex( g_iDrone_Thrust[entity][region] );
		if( IsEntityValid( trust ))
		{
			SetThrusterTorque( trust, force );
		}
		//PrintToChatAll( "Force: %f | Region: %s", force, (region == ePOS_NORTH_EAST ? "North East":"North West"  ));
	}
}

void Think_Obstacle90( int entity, int region, float distance, float direction )
{
	float force = FORCE_NONE;
	if( distance <= SAFE_RADIUS1 )
	{
		float mult = (SAFE_RADIUS1 - distance) * SAFE_MULTIPLIER;
		if( mult < FORCE_NONE )
		{
			mult = FORCE_NONE;
		}
		force = FORCE_OBSTACLE * mult * direction;
		//PrintToChatAll( "Distance: %f | Direction %s", distance, (direction == 1.0 ? "Right":"Left"  ));
	}
	
	if( g_fDrone_Force[entity][region] != force )
	{
		g_fDrone_Force[entity][region] = force;
		SetRotorGear( entity, region, force, distance );
		int trust = EntRefToEntIndex( g_iDrone_Thrust[entity][region] );
		if( IsEntityValid( trust ))
		{
			SetThrusterTorque( trust, force );
		}
	}
}

void SetRotorGear( int entity, int region, float force, float distance )
{
	float gears, vec_buff[3];
	int exaust, rotor, leng, axis;
	for( int i = ePOS_ROTOR_1; i <= ePOS_ROTOR_4; i++ )
	{
		exaust = EntRefToEntIndex( g_iDrone_EnvSteam[entity][i] );
		if( IsEntityValid( exaust ))
		{
			gears = GEAR_NONE;
			leng = ENVSTEAM_IDLE;
			if( force != FORCE_NONE )
			{
				gears = GEAR_ONE;
				leng = ENVSTEAM_GEARONE;
				if( distance <= SAFE_RADIUS2 )
				{
					gears = GEAR_TWO;
					leng = ENVSTEAM_GEARTWO;
				}
			}
				
			if( region == ePOS_SLATS )
			{
				axis = AXIS_ROLL;
			}
			else if( region == ePOS_ENGINE )
			{
				axis = AXIS_PITCH;
				if( force > FORCE_NONE )
				{
					gears = GEAR_TWO;
				}
			}

			if( force < FORCE_NONE )
			{
				gears *= -1.0;
			}
			
			SetSteamLength( exaust, leng );
			rotor = GetEntityParent( exaust );
			if( IsEntityValid( rotor ))
			{
				GetEntAngle( rotor, vec_buff, 0.0, 0 );
				vec_buff[axis] = gears;
				TeleportEntity( rotor, NULL_VECTOR, vec_buff, NULL_VECTOR );
			}
		}
	}
}

void SetSteamLength( int entity, int length )
{ 
	AcceptEntityInput( entity, "TurnOff" );
	char len[8];
	FormatEx( len, sizeof(len), "%d", length );
	DispatchKeyValue( entity, "JetLength", len );
	AcceptEntityInput( entity, "TurnOn" );
}

void SetThrusterTorque( int entity, float force )
{
	AcceptEntityInput( entity, "Deactivate" );
	char force_scale[16];
	IntToString( RoundToCeil(force), force_scale, sizeof( force_scale ));
	DispatchKeyValue( entity, "Force", force_scale );
	AcceptEntityInput( entity, "Activate" );
}

bool SaveDroneEntity( int drone, int entity_index, int array[SIZE][ePOS_SIZE], int post )
{
	if( IsEntityValid( entity_index ))
	{
		array[drone][post] = EntIndexToEntRef( entity_index );
		return true;
	}
	return false;
}

void SetPerkButton( int entity, int type, float live_value )
{
	int btn = EntRefToEntIndex( g_iDrone_Perk[entity][type] );
	int lit = EntRefToEntIndex( g_iDrone_Perk[entity][type+2] );
	if( IsEntityValid( btn ) && IsEntityValid( lit ))
	{
		g_fButton_Life[entity][type] = live_value;
		if( live_value == 0.0 )
		{
			AcceptEntityInput( lit, "TurnOn" );
			if( type == ePERK_HEAL_BTN )
			{
				SetColor( btn, g_iColor_Green, 225 );
			}
			else if( type == ePERK_AMMO_BTN )
			{
				SetColor( btn, g_iColor_Blue, 225 );
			}
		}
		else
		{
			AcceptEntityInput( lit, "TurnOff" );
			SetColor( btn, g_iColor_Grey, 255 );
		}
	}
}





