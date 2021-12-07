#define PLUGIN_VERSION "1.0.0"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define DMG_GENERIC		0
#define DAMAGE_RADIUS	680.0

new Handle:saferoomhazard_enable;
new Handle:saferoomhazard_notify_1;
new Handle:saferoomhazard_notify_2;

new Handle:Timer_1;
new Handle:Timer_2;
new Handle:Timer_3;
new Float:InfoPos[3];
new Float:DoorPos[3];
new Float:campPos[3];
new String:maxName[128];
new bool:Start	= false;
new Info		= -1;
new Door		= -1;
new MaxEnt		= -1;

public Plugin:myinfo = 
{
	name		= "Safe Room Hazard",
	author		= " GsiX ",
	description	= "Prevent player from camp in the safe room",
	version		= PLUGIN_VERSION,
	url			= ""	
}

public OnPluginStart()
{
	CreateConVar( "saferoomhazard_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	saferoomhazard_enable		= CreateConVar( "saferoomhazard_enable",		"1",	"0:Off,  1:On,  Toggle plugin On/Off.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	saferoomhazard_notify_1		= CreateConVar( "saferoomhazard_notify_1",		"30",	"Timer first notify to player to leave safe room.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	saferoomhazard_notify_2		= CreateConVar( "saferoomhazard_notify_2",		"30",	"Timer damage to start kick in count from 'saferoomhazard_notify_1'..   >_<.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	HookEvent( "player_spawn",		EVENT_PlayerSpawn );
	HookEvent( "round_end",			EVENT_Reset );
	HookEvent( "round_start",		EVENT_Reset );
}

public EVENT_Reset( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( GetConVarInt( saferoomhazard_enable ) == 0 ) return;
	
	Start = false;
	
	if ( Timer_1 != INVALID_HANDLE )
	{
		KillTimer( Timer_1 );
		Timer_1 = INVALID_HANDLE;
	}
	
	if ( Timer_2 != INVALID_HANDLE )
	{
		KillTimer( Timer_2 );
		Timer_2 = INVALID_HANDLE;
	}
	
	if ( Timer_3 != INVALID_HANDLE )
	{
		KillTimer( Timer_3 );
		Timer_3 = INVALID_HANDLE;
	}
}

public EVENT_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( GetConVarInt( saferoomhazard_enable ) == 0 || Start ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ) && !IsFakeClient( client ))
	{
		Start	= true;
		Info	= -1;
		Door	= -1;
		MaxEnt	= GetEntityCount();
	
		for ( new i = MaxClients; i <= MaxEnt; i++ )
		{
			if ( !IsValidEntity( i )) continue;
			GetEntityClassname( i, maxName, sizeof( maxName ));
			if ( StrEqual( maxName, "info_player_start", false ))
			{
				Info = i;
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", InfoPos );
				break;
			}
		}
		
		if ( Info > 0 )
		{
			for ( new i = MaxClients; i <= MaxEnt; i++ )
			{
				if ( !IsValidEntity( i )) continue;
				
				GetEntityClassname( i, maxName, sizeof( maxName ));
				if ( StrEqual( maxName, "prop_door_rotating_checkpoint", false ))
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", DoorPos );
					if ( GetVectorDistance( InfoPos, DoorPos ) <= DAMAGE_RADIUS )
					{
						Door = i;
						break;
					}
				}
			}
		}
		
		
		if ( Info > 0 && Door > 0 )
		{
			Timer_1 = CreateTimer( GetConVarFloat( saferoomhazard_notify_1 ), Timer_Notify_1, _, TIMER_FLAG_NO_MAPCHANGE );
		}
	}
}

public Action:Timer_Notify_1( Handle:timer )
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidClient( i ) && !IsFakeClient( i ))
		{
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", campPos );
			if ( GetVectorDistance( InfoPos, campPos ) <= DAMAGE_RADIUS )
			{
				PrintToChat( i, "[WARNING]: You have %d second(s) to leave safe room!!", GetConVarInt( saferoomhazard_notify_2 ));
			}
			else
			{
				PrintToChat( i, "[WARNING]: %d second(s) untill Safe Room Hazard zone in effect!!", GetConVarInt( saferoomhazard_notify_2 ));
			}
		}
	}
	Timer_2 = CreateTimer( GetConVarFloat( saferoomhazard_notify_2 ), Timer_Notify_2, _, TIMER_FLAG_NO_MAPCHANGE );
}

public Action:Timer_Notify_2( Handle:timer )
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidClient( i ) && !IsFakeClient( i ))
		{
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", campPos );
			if ( GetVectorDistance( InfoPos, campPos ) <= DAMAGE_RADIUS )
			{
				PrintToChat( i, "[WARNING]: You inside Safe Room Hazard zone.. leave now!!" );
			}
			else
			{
				PrintToChat( i, "[WARNING]: Safe Room Hazard zone in effect!!" );
			}
		}
	}
	
	Timer_1 = INVALID_HANDLE;
	Timer_3 = CreateTimer( 1.0, Timer_Notify_3, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
}

public Action:Timer_Notify_3( Handle:timer )
{
	Timer_2 = INVALID_HANDLE;
	
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidClient( i ) && !IsFakeClient( i ))
		{
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", campPos );
			if ( GetVectorDistance( InfoPos, campPos ) <= DAMAGE_RADIUS )
			{
				DealDamage( i, 1, i, DMG_GENERIC, "" );
			}
		}
	}
}

// Because I love you.
stock DealDamage( victim, damage, attacker=0, dmg_type=DMG_GENERIC, String:weapon[]="" )
{
	if( victim > 0 && GetEntProp( victim, Prop_Data, "m_iHealth" ) > 0 && attacker > 0 && damage > 0 )
	{
		new String:dmg_str[16];
		IntToString( damage, dmg_str, 16 );
		new String:dmg_type_str[32];
		IntToString( dmg_type, dmg_type_str, 32 );
		new pointHurt = CreateEntityByName( "point_hurt" );
		if ( pointHurt )
		{
			DispatchKeyValue( victim,"targetname","war3_hurtme" );
			DispatchKeyValue( pointHurt, "DamageTarget","war3_hurtme" );
			DispatchKeyValue( pointHurt, "Damage",dmg_str );
			DispatchKeyValue( pointHurt,"DamageType", dmg_type_str );
			if ( !StrEqual( weapon, "" ))
			{
				DispatchKeyValue( pointHurt, "classname", weapon );
			}
			DispatchSpawn( pointHurt );
			AcceptEntityInput( pointHurt, "Hurt",( attacker > 0 ) ? attacker:-1 );
			DispatchKeyValue( pointHurt, "classname", "point_hurt" );
			DispatchKeyValue( victim, "targetname", "war3_donthurtme" );
			AcceptEntityInput( pointHurt, "Kill" );
		}
	}
}

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 2 ) return false;
	if ( !IsPlayerAlive( client )) return false;
	return true;
}

