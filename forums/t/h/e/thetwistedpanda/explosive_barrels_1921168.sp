#include <sourcemod>

#include < sdktools >
#include < sdkhooks >
#include < morecolors >

public Plugin:myinfo = 
{
	name = "Explosive Barrels",
	author = "aNNakin",
	description = "<- Description ->",
	version = "0.0.1",
	url = "<- URL ->"
}

#define MAX_ENTITIES 	2048
#define MAX_PLAYERS		32

new
	gi_Hits[ MAX_ENTITIES ],
	gi_Victims[ MAX_PLAYERS + 1 ][ MAX_ENTITIES ],
	gi_Injured[ MAX_PLAYERS + 1 ][ MAX_PLAYERS + 1 ][ MAX_ENTITIES ],
	gi_TotalInjuries[ MAX_PLAYERS + 1 ][ MAX_PLAYERS + 1 ],
	gi_TotalVictims[ MAX_PLAYERS + 1 ],
	gi_RoundCount[ MAX_PLAYERS + 1 ];

new Handle:gc_TooglePlugin = INVALID_HANDLE;
new Handle:gc_ToogleRadius = INVALID_HANDLE;
new Handle:gc_ToogleDamage = INVALID_HANDLE;
new Handle:gc_ToogleFrags = INVALID_HANDLE;
new Handle:gc_ToogleMoney = INVALID_HANDLE;
new Handle:gc_ToogleStats;

new g_FireSprite;
new g_ExplosionSprite;

// - - - - - - - - - -

#define EXPLODE_SOUND	"ambient/explosions/explode_8.wav"

new const String:gs_EntityModels[ ][ ] =
{
	"models/props_c17/oildrum001.mdl",
	"models/props/de_train/barrel.mdl"
};

// - - - - - - - - - -

public OnPluginStart()
{
	HookEvent ( "bullet_impact", HookBulletImpact );
	HookEvent ( "round_start", HookRoundRestart );
	RegConsoleCmd ( "barrel", HookBarrelStatsCmd );
	
	gc_TooglePlugin = CreateConVar ( "barrel_active", "5" );
	gc_ToogleRadius = CreateConVar ( "barrel_radius", "300" );
	gc_ToogleDamage = CreateConVar ( "barrel_damage", "100" );
	gc_ToogleFrags = CreateConVar ( "barrel_frags", "1" );
	gc_ToogleMoney = CreateConVar ( "barrel_money", "150" );
	gc_ToogleStats = CreateConVar ( "barrel_stats", "1" );
}

public OnMapStart() 
{
	g_FireSprite = PrecacheModel ( "materials/sprites/fire2.vmt", true );
	g_ExplosionSprite = PrecacheModel ( "sprites/sprite_fire01.vmt", true );
	PrecacheSound ( EXPLODE_SOUND, true );
	
	// In case you want some custom mdl or...
	for ( new i_Index; i_Index < sizeof gs_EntityModels; i_Index++ )
		PrecacheModel ( gs_EntityModels[ i_Index ], true );
}

public Action:HookBulletImpact ( Handle:event, const String:s_WeaponName[ ], bool:dontBroadcast )
{
	/* Is plugin active? */
	static i_Impacts;
	i_Impacts = GetConVarInt ( gc_TooglePlugin );
	if ( i_Impacts <= 0 )
		return;
	
	/* Client that triggerd the event */
	new i_Index = GetClientOfUserId ( GetEventInt ( event, "userid" ) );
	if ( ! ( IsClientInGame ( i_Index ) && IsPlayerAlive ( i_Index ) ) )
		return;
	
	/* Enitity wich is being aimed at */
	new i_Entity = GetClientAimTarget ( i_Index, false );
	if ( i_Entity == -1 )
		return;
	
	/* Check if we're shooting the right entity - barrel */
	decl String:s_ModelName[ 128 ];
	GetEntPropString ( i_Entity, Prop_Data, "m_ModelName", s_ModelName, sizeof ( s_ModelName ) );
	
	for ( new i_Slot = 0; i_Slot < sizeof ( gs_EntityModels );  i_Slot++ )
	{
		if ( StrEqual ( s_ModelName, gs_EntityModels[ i_Slot ] ) )
		{
			/* Did we hit enought times ? */
			if ( ++gi_Hits[ i_Entity ] >= i_Impacts )
			{
				/* Get entity's origin so we can create some stuff below */
				static Float:f_Origin[ 3 ];
				GetEntPropVector ( i_Entity, Prop_Send, "m_vecOrigin", f_Origin );
				
				/* Actual explosion effect / sound */
				EmitAmbientSound ( EXPLODE_SOUND, f_Origin, i_Entity );
				TE_SetupExplosion ( f_Origin, g_FireSprite, 10.0, 1, 0, 300, 5000 );
				TE_SendToAll ( );

				f_Origin[ 2 ] += 10;
				EmitAmbientSound ( EXPLODE_SOUND, f_Origin, i_Entity );
				TE_SetupExplosion ( f_Origin, g_ExplosionSprite, 10.0, 1, 0, 300, 5000 );
				TE_SendToAll ( );
				
				/* Remove entity, reset hits for next spawn/round */
				gi_Hits[ i_Entity ] = 0;
				AcceptEntityInput ( i_Entity, "Kill" );
	
				static
						Float:f_pOrigin[ 3 ], Float:f_Distance,
						String:s_Killer[ 32 ], String:s_Victim[ 32 ],
						i_Money, i_Ammount, i_Frags, i_Value, i_Stats, i_Player;
				
				/* Are we going to show some statistics ? */
				i_Stats = GetConVarInt ( gc_ToogleStats );
				
				/* Check for players near the explosion */
				for ( i_Player = 1; i_Player <= MaxClients; i_Player++ )
				{
					if ( IsClientInGame ( i_Player ) && IsPlayerAlive ( i_Player ) )
					{
						GetEntPropVector ( i_Player, Prop_Send, "m_vecOrigin", f_pOrigin );
						f_Distance = GetVectorDistance ( f_pOrigin, f_Origin );
				
						static i_Radius, i_Damage;
						i_Radius = GetConVarInt ( gc_ToogleRadius );
				
						if ( f_Distance <= i_Radius )
						{
							/* Calculate final damage according to radius and max damage */
							i_Damage = GetConVarInt ( gc_ToogleDamage );
							i_Damage = RoundToFloor ( i_Damage * ( i_Radius - f_Distance ) / i_Radius );
							
							/* Does the explosion killed the player? */
							if ( i_Damage >= GetClientHealth ( i_Player ) )
							{
								GetClientName ( i_Index, s_Killer, 31 );	
								GetClientName ( i_Player, s_Victim, 31 );
								
								if ( i_Index != i_Player )
								{
									i_Money = GetEntProp ( i_Index, Prop_Send, "m_iAccount" ),
									i_Frags = GetClientFrags ( i_Index );
									i_Ammount = GetConVarInt ( gc_ToogleMoney );
									i_Value = GetConVarInt ( gc_ToogleFrags );
									
									if ( GetClientTeam ( i_Index ) == GetClientTeam ( i_Player ) )
									{
										i_Money -= i_Ammount;
										i_Frags -= i_Value;
									}
									else
									{
										i_Money += i_Ammount;
										i_Frags += i_Value;
									}
									
									gi_Victims[ i_Index ][ i_Entity ]++;
									gi_TotalVictims[ i_Index ]++;
					
									if ( i_Stats )
										CPrintToChatAll ( "{red}%s was killed in the explosion caused by %s", s_Victim, s_Killer );
									
									SetEntProp ( i_Index, Prop_Data, "m_iFrags", i_Frags );
									SetEntProp ( i_Index, Prop_Send, "m_iAccount", i_Money );
									
									/* Display death message to players (including suicide) */
									new Handle:HookDeathMsg = CreateEvent ( "player_death" );
									SetEventInt ( HookDeathMsg, "userid", GetClientUserId ( i_Player ) );
									SetEventInt ( HookDeathMsg, "attacker", GetClientUserId ( i_Index ) );
									SetEventString ( HookDeathMsg, "weapon", "world" );
									FireEvent ( HookDeathMsg );
									
									
								}
								else
									if ( i_Stats )
										CPrintToChatAll ( "{red}%s was killed in his own explosion", s_Victim );
							}
							
									
							gi_Injured[ i_Index ][ i_Player ][ i_Entity ] = 1;
							gi_TotalInjuries[ i_Index ][ i_Player ] = 1;
							
							/* Inflict damage */
							SlapPlayer ( i_Player, i_Damage, false );
							
							/* Calculate aprox. distance so we can adjust fade & shake effect */
							static i_Alpha, i_Intensity, i_Duration, i_Zone1, i_Zone2, i_Zone3;
							i_Zone1  = ( i_Radius - ( 70 * i_Radius ) / 100 );
							i_Zone2  = ( i_Radius - ( 50 * i_Radius ) / 100 );
							i_Zone3  = ( i_Radius - ( 30 * i_Radius ) / 100 );
							
							// 30% from the explosion centre
							if ( f_Distance <= i_Radius && f_Distance > i_Zone3 /*f_Distance <= 300 && f_Distance > 200*/ )
							{
								i_Duration = 200;
								i_Intensity = 15;
								i_Alpha = 100;
							}
							
							// 50% from the explosion centre
							else if ( f_Distance <= i_Zone3 && f_Distance > i_Zone2 /*f_Distance <= 200 && f_Distance > 100*/ )
							{
								i_Duration = 300;
								i_Intensity = 30;
								i_Alpha = 150;
							}
							
							// 70% from the explosion centre
							else if ( f_Distance <= i_Zone2 && f_Distance > i_Zone1 /*f_Distance <= 100*/ )
							{
								i_Duration = 500;
								i_Intensity = 50;
								i_Alpha = 230;
							}
							
							// closer than 70% from the explosion centre
							else if ( f_Distance <= i_Zone1 )
							{
								i_Duration = 600;
								i_Intensity = 60;
								i_Alpha = 250;
							}
							
							ScreenFade ( i_Player, 255, 0, 0, i_Alpha, i_Duration );
							ScreenShake ( i_Player, i_Intensity );
						}
					}
				}
				
				if ( i_Stats )
				{
					new i_TotalInjured = GetInjuries ( i_Index, i_Entity );
					PrintToChat ( i_Index, "Players injured: %i; victims: %i", i_TotalInjured, gi_Victims[ i_Index ][ i_Entity ] );
				}
				gi_RoundCount[ i_Index ] = 0;
			}
			
			break;
		}
	}
}

public Action: HookBarrelStatsCmd ( client, args )
{
	if ( ! GetConVarInt ( gc_ToogleStats ) )
		return Plugin_Handled;
	
	new i_TotalInjuries = GetTotalInjuries ( client );
	
	PrintToChat ( client, "Victims made last round: %i (%i %s)", gi_TotalVictims[ client ], i_TotalInjuries, ( i_TotalInjuries == 1 ) ? "injury" : "injuries" );
	return Plugin_Handled;
}
	
public Action:HookRoundRestart ( Handle:event, const String:name[], bool:dontBroadcast )
{
	
	for ( new i_Index = 1; i_Index <= MAX_PLAYERS; i_Index++ )
	{
		if ( ++gi_RoundCount[ i_Index ] > 1 )
		{
			gi_TotalVictims[ i_Index ] = 0;
			for ( new i_Player = 1; i_Player <= MAX_PLAYERS; i_Player++ )
				gi_TotalInjuries[ i_Index ][ i_Player ] = 0;
			
			gi_RoundCount[ i_Index ] = 0;
		}
	}
}

public GetTotalInjuries ( i_Index )
{
	new i_Num;
	for ( new i_Slot = 1; i_Slot <= MAX_PLAYERS; i_Slot++ )
		if ( gi_TotalInjuries[ i_Index ][ i_Slot ] )
			i_Num++;
	
	return i_Num;
}

public GetInjuries ( i_Index, i_Entity )
{
	new i_Num;
	for ( new i_Slot = 1; i_Slot <= MAX_PLAYERS; i_Slot++ )
		if ( gi_Injured[ i_Index ][ i_Slot ][ i_Entity ] )
			i_Num++;
		
	return i_Num;
}

// thx wiki

public ScreenFade(target, red, green, blue, alpha, duration)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public ScreenShake(target, i_Intensity)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, float(i_Intensity));
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}