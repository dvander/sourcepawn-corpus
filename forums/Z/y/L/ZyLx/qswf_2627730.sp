#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <vphysics>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hCvarVersion;
new Handle:g_hCvarEnabled;
new Handle:g_hCvarMotion;
new Handle:g_hCvarSpeed;

new bool:g_bEnabled;
new bool:g_bMotion;
new Float:g_fSpeed;

public Plugin myinfo =
{
	name = "Quake Style Weapon Floating",
	author = "ZyLx",
	description = "Floating weapons like a Quake",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
};

public OnPluginStart()
{
	g_hCvarVersion = CreateConVar( "sm_qswf_version", PLUGIN_VERSION, "The version of the plugin", FCVAR_NOTIFY | FCVAR_DONTRECORD );
	g_hCvarEnabled = CreateConVar( "sm_qswf_enabled", "1", "Enable or disable the plugin", 0, true, 0.0, true, 1.0 );
	g_hCvarMotion = CreateConVar( "sm_qswf_motion", "1", "Enable or disable the motion of the weapon", 0, true, 0.0, true, 1.0 );
	g_hCvarSpeed = CreateConVar( "sm_qswf_speed", "30.0", "The speed of rotation of the weapon" );
	
	g_bEnabled = GetConVarBool( g_hCvarEnabled );
	g_bMotion = GetConVarBool( g_hCvarMotion );
	g_fSpeed = GetConVarFloat( g_hCvarSpeed );
	
	HookConVarChange( g_hCvarVersion, OnConVarChanged );
	HookConVarChange( g_hCvarEnabled, OnConVarChanged );
	HookConVarChange( g_hCvarMotion, OnConVarChanged );
	HookConVarChange( g_hCvarSpeed, OnConVarChanged );
	
	AutoExecConfig( true, "qswf" );
}

public OnConVarChanged( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	if ( convar == g_hCvarVersion && !StrEqual( newValue, PLUGIN_VERSION ) )
	{
		SetConVarString( g_hCvarVersion, PLUGIN_VERSION );
	}
	else if ( convar == g_hCvarEnabled )
	{
		g_bEnabled = bool:StringToInt( newValue );
	}
	else if ( convar == g_hCvarMotion )
	{
		g_bMotion = bool:StringToInt( newValue );
	}
	else if ( convar == g_hCvarSpeed )
	{
		g_fSpeed = StringToFloat( newValue );
	}
}

public Phys_OnObjectSleep( entity )
{
	if ( !g_bEnabled )
		return;
	
	decl String:classname[32];
	
	if ( GetEntityClassname( entity, classname, sizeof( classname ) ) && strncmp( classname, "weapon_", 7 ) == 0 )
	{
		Phys_EnableMotion( entity, g_bMotion );
		RequestFrame( SetEntPos, EntIndexToEntRef( entity ) );
	}
}

public SetEntPos( any:entRef )
{
	new entity = EntRefToEntIndex( entRef );
	
	if ( entity != INVALID_ENT_REFERENCE &&
		 IsValidEntity( entity ) &&
		 Phys_IsPhysicsObject( entity ) &&
		 Phys_IsAsleep( entity ) )
	{	
		decl Float:origin[3];
		GetEntPropVector( entity, Prop_Send, "m_vecOrigin", origin );
						
		origin[2] += 30.0;
						
		TeleportEntity( entity, origin, NULL_VECTOR, NULL_VECTOR );
	}
}

stock Float:fmodf( Float:x, Float:y ) 
{ 
	return x - y * RoundToFloor( x / y ); 
}  

stock Float:AngleNormalize( Float:ang )
{
	ang = fmodf( ang, 360.0 ); 
	
	if ( ang > 180.0 ) 
		ang -= 360.0;
	
	if ( ang < -180.0 ) 
		ang += 360.0;
	
	return ang;
}

public OnGameFrame()
{
	if ( !g_bEnabled )
		return;
	
	new maxEnts = GetMaxEntities();
	decl String:classname[32];
	decl Float:origin[3];	
	decl Float:angles[3];
	
	angles[0] = 0.0;
	angles[1] = AngleNormalize( GetGameTime() * g_fSpeed * 5.0 );
	angles[2] = 0.0;
	
	new Float:bob_cycle = Cosine( 5.0 * GetGameTime() ) * 20.0 * GetTickInterval();
	
	for ( new entity = MaxClients + 1; entity < maxEnts; entity++ )
	{
		if ( IsValidEntity( entity ) && 
			 Phys_IsPhysicsObject( entity ) && 
			 Phys_IsAsleep( entity ) &&
			 GetEntityClassname( entity, classname, sizeof( classname ) ) && 
			 strncmp( classname, "weapon_", 7 ) == 0 )
		{
			GetEntPropVector( entity, Prop_Send, "m_vecOrigin", origin );
		
			origin[2] += bob_cycle;
			
			TeleportEntity( entity, origin, angles, NULL_VECTOR );
		}
	}
}
