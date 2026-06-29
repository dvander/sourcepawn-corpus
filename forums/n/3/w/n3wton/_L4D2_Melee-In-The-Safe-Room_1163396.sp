#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:g_hEnabled;
new Handle:g_hWeapon;
new Handle:g_hAmount;

#define VERSION "1.0.2"

public Plugin:myinfo =
{
	name = "",
	author = "n3wton",
	description = "",
	version = VERSION
};

public OnPluginStart()
{
	g_hEnabled = CreateConVar( "l4d2_MITSR_Enabled", "1", "Should the plugin be enabled", FCVAR_PLUGIN );
	g_hWeapon = CreateConVar( "l4d2_MITSR_Weapon", "random", "Weapon the should be spawned ( random, baseball_bat, fireaxe, frying_pan, machete, crowbar, cricket_bat, katana, electric_guitar, golfclub, knife )", FCVAR_PLUGIN );
	g_hAmount = CreateConVar( "l4d2_MITSR_Amount", "4", "Number of melle weapons to spawn", FCVAR_PLUGIN );
	AutoExecConfig( true, "[L4D2]MelleSafeRoom" );

	HookEvent( "round_start", Event_RoundStart );
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarBool( g_hEnabled ) )
	{
		CreateTimer( 1.0, Timer_SpawnBats );
	}
}

public Action:Timer_SpawnBats(Handle:timer )
{
	new client = 0;
	for( new x = 1; x <= 8 ; x++ )
	{
		if( IsClientInGame( x ) )
		{
			if( GetClientTeam( x ) == 2 )
			{
				client = x;
				break;
			}
		}
	}
	if( client != 0 && IsClientInGame( client ) )
	{
		decl Float:Position[3];
		decl Float:Angle[3];
		GetClientAbsOrigin( client, Position );
		Position[2] += 20;
		Angle[0] = 90.0;
		for( new i = 0; i < GetConVarInt( g_hAmount ); i++ )
		{
			Position[0] += (-10+GetRandomInt(0, 20));
			Position[1] += (-10+GetRandomInt(0, 20));
			Angle[1] = GetRandomFloat(0.0, 360.0);
			decl String:WeaponClass[20];
			GetWeaponClass( WeaponClass );
			new Ent = CreateEntityByName( "weapon_melee" );
			DispatchKeyValue( Ent, "melee_script_name", WeaponClass );
			DispatchSpawn( Ent );
			TeleportEntity( Ent, Position, Angle, NULL_VECTOR );
			new String:ModelName[128];
			GetEntPropString( Ent, Prop_Data, "m_ModelName", ModelName, 128 ); 
			if( StrContains( ModelName, "hunter" ) != -1 || StrContains( ModelName, "boomer" ) != -1 )
			{
				RemoveEdict( Ent );
				i--;
				GetConVarString( g_hWeapon, WeaponClass, 20 );
				if( StrContains( WeaponClass, "random", false ) == -1 )
				{
					SetConVarString( g_hWeapon, "random" );
				}
			}
		}
	} else {
		CreateTimer( 0.1, Timer_SpawnBats, client );
	}
}

GetWeaponClass( String:Class[] )
{
	GetConVarString( g_hWeapon, Class, 20 );
	if( StrContains( Class, "random", false ) != -1 )
	{
		new Rand = GetRandomInt( 0, 8 );
		switch( Rand )
		{
			case 0:
			{
				Format( Class, 20, "fireaxe" );
			}
			case 1:
			{
				Format( Class, 20, "frying_pan" );
			}
			case 2:
			{
				Format( Class, 20, "machete" );
			}
			case 3:
			{
				Format( Class, 20, "baseball_bat" );
			}
			case 4:
			{
				Format( Class, 20, "crowbar" );
			}
			case 5:
			{
				Format( Class, 20, "cricket_bat" );
			}
			case 6:
			{
				Format( Class, 20, "katana" );
			}
			case 7:
			{
				Format( Class, 20, "electric_guitar" );
			}
			case 8:
			{
				Format( Class, 20, "golfclub" );
				//"models/weapons/melee/v_golfclub.mdl"
			}
			case 9:
			{
				Format( Class, 20, "knife" );
			}
			default:
			{
				Format( Class, 20, "fireaxe" );
			}
		}
	}
}
