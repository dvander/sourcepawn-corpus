#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.2"

#define MODEL "models/props_lab/monitor01a.mdl"
#define SOUND "res/drhax/Hax.mp3"

new Handle:drhax_enabled = 				INVALID_HANDLE;
new Handle:drhax_music_path = 			INVALID_HANDLE;
new Handle:drhax_monitor_weight = 		INVALID_HANDLE;
new Handle:drhax_throwing_force =			INVALID_HANDLE;
new Handle:drhax_let_users_set_weight = 	INVALID_HANDLE;
new Handle:drhax_distance_from_spawner = INVALID_HANDLE;
new Handle:drhax_only_admins =			INVALID_HANDLE;
new Handle:drhax_entity_destroy_delay =	INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Dr.Hax",
	author = "Push",
	description = "Fell yourself as Dr.Hax",
	version = VERSION,
	url = "http://css-quad.ru"
};

public OnPluginStart()
{
	drhax_enabled =					CreateConVar( "drhax_enabled", "1", "Enable the plugin?" );
	drhax_music_path =				CreateConVar( "drhax_music_path", SOUND, "Path to the sound." );
	drhax_monitor_weight =			CreateConVar( "drhax_monitor_weight", "1.0", "Default weight of monitor." );
	drhax_throwing_force =			CreateConVar( "drhax_throwing_force", "100000.0" , "Force of throwing the monitor ( More = better )." );
	drhax_let_users_set_weight =		CreateConVar( "drhax_let_users_set_weight", "1", "Do you want to let users set monitor's weight?" );
	drhax_distance_from_spawner =	CreateConVar( "drhax_distance_from_spawner", "40.0", "Distance from object's creator to a spawned object." );
	drhax_only_admins =				CreateConVar( "drhax_only_admins", "1", "Only admins can throw monitors. Disable it at your own risk :)" );
	drhax_entity_destroy_delay =		CreateConVar( "drhax_entity_destroy_delay", "3.5", "Delay before entity will be destroyed by entity dissolver" );
	
	AutoExecConfig( );
	
	RegConsoleCmd( "sm_hax", CommandHandler );
}

public OnConfigsExecuted( )
{
	new String:szBuffer[ PLATFORM_MAX_PATH ];
	
	GetConVarString( drhax_music_path, szBuffer, sizeof( szBuffer ) );
	
	PrecacheModel( MODEL );
	PrecacheSound( szBuffer, true );
	
	Format( szBuffer, sizeof( szBuffer ), "sound/%s", szBuffer );
	
	AddFileToDownloadsTable( szBuffer );
}

public Action:CommandHandler( client, args )
{
	if( GetConVarBool( drhax_enabled ) )
	{
		new Float:fMonitorWeight;
		new Float:fDefMonitorWeight;
		
		fDefMonitorWeight = GetConVarFloat( drhax_monitor_weight );
	
		if( GetConVarBool( drhax_only_admins ) )
		{
			if( GetUserAdmin( client ) == INVALID_ADMIN_ID )
			{
				PrintToChat( client, "It works only for admins." );
				return Plugin_Handled;
			}
		}
		
		if( GetCmdArgs() == 1 && GetConVarBool( drhax_let_users_set_weight ) )
		{
			new String:szMonitorWeight[16];
			
			if( GetCmdArg( 1, szMonitorWeight, sizeof( szMonitorWeight ) ) )
			{
				if( ( fMonitorWeight = StringToFloat( szMonitorWeight ) ) == 0.0 )
				{
					fMonitorWeight = fDefMonitorWeight;
				}
			}
			else
			{
				fMonitorWeight = fDefMonitorWeight;
			}
		}
		else
		{
			fMonitorWeight = fDefMonitorWeight;
		}
	
		if( IsPlayerAlive( client ) )
		{
			new Float:fPlayerPos[3];
			new Float:fPlayerAngles[3];
			new Float:fThrowingVector[3];
			new Float:fDistanceFromSpawner;
			new Float:fThrowingForce;
			
			new String:szSoundPath[ PLATFORM_MAX_PATH ];
			new String:szMonitorWeight[ PLATFORM_MAX_PATH ];
			
			Format( szMonitorWeight, sizeof( szMonitorWeight ), "%f", fMonitorWeight );
			GetConVarString( drhax_music_path, szSoundPath, sizeof( szSoundPath ) );
			
			fDistanceFromSpawner = GetConVarFloat( drhax_distance_from_spawner );
			fThrowingForce = GetConVarFloat( drhax_throwing_force );
			
			GetClientEyeAngles( client, fPlayerAngles );
			GetClientEyePosition( client, fPlayerPos );
			
			TR_TraceRayFilter( fPlayerPos, fPlayerAngles, MASK_SOLID, RayType_Infinite, DontHitSelf, client );
			
			if( TR_DidHit( ) )
			{
				new Float:fEndPosition[3];
				
				TR_GetEndPosition( fEndPosition );
				
				if( GetVectorDistance( fPlayerPos, fEndPosition ) < fDistanceFromSpawner ) // if distance from player to a target is so long...
				{
					return Plugin_Handled; // return
				}
			}
			
			EmitAmbientSound( szSoundPath, fPlayerPos, _, _, _, 5.0 ); // HAAAAAAAAAAAAAAAX
			
			new Float:fLen = fDistanceFromSpawner * Sine( DegToRad( fPlayerAngles[0] + 90.0 ) );
			
			fPlayerPos[0] = fPlayerPos[0] + fLen * Cosine( DegToRad( fPlayerAngles[1] ) );
			fPlayerPos[1] = fPlayerPos[1] + fLen * Sine( DegToRad( fPlayerAngles[1] ) );
			fPlayerPos[2] = fPlayerPos[2] + fDistanceFromSpawner * Sine( DegToRad( -1 * fPlayerAngles[0] ) ) ;
			
			new entity = CreateEntityByName( "prop_physics" );
			
			DispatchKeyValue( entity, "model", MODEL );
			DispatchKeyValue( entity, "massScale", szMonitorWeight );
			
			DispatchSpawn( entity );
			ActivateEntity( entity );

			new Float:fScal = fThrowingForce * Sine( DegToRad( fPlayerAngles[0] + 90.0 ) );
			
			fThrowingVector[0] = fScal * Cosine( DegToRad( fPlayerAngles[1] ) );
			fThrowingVector[1] = fScal * Sine( DegToRad( fPlayerAngles[1] ) );
			fThrowingVector[2] = fThrowingForce * Sine( DegToRad( -1 * fPlayerAngles[0] ) );

#define VER 1

#if VER == 1
			SDKHook( entity, SDKHook_StartTouch, OnStartTouch );
#else
			SDKHook( entity, SDKHooks_Touch, OnStartTouch );
#endif
			TeleportEntity( entity, fPlayerPos, fPlayerAngles, fThrowingVector );
			
			CreateTimer( GetConVarFloat( drhax_entity_destroy_delay ), OnTimerTick, entity );
		}
	}
	
	return Plugin_Handled;
}

public Action:OnStartTouch( entity, other )
{
	if( 1 <= other <= MaxClients )
	{
		if( IsPlayerAlive( other ) )
		{
			ForcePlayerSuicide( other );
		}
	}
	
	return Plugin_Continue;
}

public bool:DontHitSelf( entity, mask, any:data )
{
	if( entity == data )
	{
		return false;
	}
	
	return true;
}

public Action:OnTimerTick( Handle:hTimer, any:data )
{
	Dissolve( data );
	
	return Plugin_Continue;
}

stock void:Dissolve(edict)
{
	if(IsValidEntity(edict))
	{
		new String:dname[32], ent = CreateEntityByName("env_entity_dissolver");
		
		Format(dname, sizeof(dname), "dis_%d", edict);
		  
		if (ent > 0)
		{
			DispatchKeyValue(edict, "targetname", dname);
			DispatchKeyValue(ent, "dissolvetype", "3");
			DispatchKeyValue(ent, "target", dname);
			AcceptEntityInput(ent, "Dissolve");
			AcceptEntityInput(ent, "kill");
		}
	}
}
