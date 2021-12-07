#pragma semicolon 1;

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

#define CLASS_SPITTER		4

new g_bLateLoad;
new g_bMapStarted;
new g_bModInProgress;

new Handle:g_iGascans;
new Handle:g_iLasthits; 

new g_bWasSpitter[ MAXPLAYERS + 1 ];

public Plugin:myinfo = 
{

    name = "L4D2 Burners Announce",
    author = "vk.com/id7558918",
    description = "Prints a chat message when molotov is thrown or someone burns a gascan",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart( )
{

	LoadTranslations( "l4d2_burners_announce.phrases" );
	
	CreateConVar( "l4d_burners_announce_version", PLUGIN_VERSION, "L4D2 Burners Announce version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	
	HookEvent( "round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent( "molotov_thrown", Event_MolotovThrown );
	HookEvent( "player_team", Event_PlayerTeam );
	HookEvent( "player_spawn", Event_PlayerSpawn );
	
	g_iGascans = CreateArray( );
	g_iLasthits = CreateArray( );

	if ( g_bLateLoad )
	{
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientAndInGame( i ) )
			{
				
				// not sure
				OnClientDisconnect_Post( i );
				OnClientPutInServer( i );
				
			}
			
		}
		
	}
	
	ModifyGascans( );
	RefreshGascans( );

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{

	g_bLateLoad = late;
	
	return APLRes_Success;
	
}

///////////////////////////////////////////////////////////
///////////////////////// MOLOTOVS ////////////////////////
///////////////////////////////////////////////////////////

public Event_MolotovThrown( Handle:event, const String:name[], bool:dontBroadcast )
{

	new attacker = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	decl String:PlayerName[ 32 ];
	GetClientName( attacker, PlayerName, sizeof( PlayerName ) );
		
	PrintToChatAll( "\x04[Fire]\x01 %t", "ThrownMolotov", PlayerName );

}

///////////////////////////////////////////////////////////
///////////////////////// GASCANS /////////////////////////
///////////////////////////////////////////////////////////

public OnClientPutInServer( client )
{

	SDKHook( client, SDKHook_WeaponEquipPost, OnWeaponEquip );

}

public OnClientDisconnect_Post( client )
{

	SDKUnhook( client, SDKHook_WeaponEquipPost, OnWeaponEquip );

}

public OnMapStart( )
{
	
	// workaround for createentitybyname. round stars before OnMapStarted :(
	g_bMapStarted = true;
	
	ModifyGascans( );
	RefreshGascans( );

}

public OnMapEnd( )
{

	g_bMapStarted = false;

}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	
	if( g_bMapStarted )
	{
	
		ModifyGascans( );
		RefreshGascans( );
		
	}

}

public Action:Event_PlayerTeam( Handle:event, const String:name[], bool:dontBroadcast )
{

	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	// prevent errors on teamchange to survivors after playing spitter
	g_bWasSpitter[ client ] = false;

}

public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	g_bWasSpitter[ client ] = false;

	// specially announce spitter to avoid misunderstanding
	if( GetClientTeam( client ) == TEAM_INFECTED )
	{

		if( GetEntProp( client, Prop_Send, "m_zombieClass" ) == CLASS_SPITTER ) 
		{

			g_bWasSpitter[ client ] = true;
		
		}
		
	}
	
}

public Action:OnWeaponEquip(client, weapon)
{
	
	// if gascan was burning or "spitting" it can be extinguished and still poured into car (c1m4_atrium) 
	// so when it will be destroyed we do not need any lasthits
	new index = -1;
	if( IsValidEdict( weapon ) )
	{
		
		index = FindValueInArray( g_iGascans, weapon );
				
		if( index > -1 )
		{
			
			SetArrayCell( g_iLasthits, index, -1 );
					
		}
		
	}

}

public OnEntityCreated( entity, const String:classname[] )
{
	
	// made for weaponspawners and auto respawning gascans (e.g. c1m4_atrium).
	if ( StrEqual( classname, "weapon_gascan" ) )
	{

		RefreshGascans();
		
	}
	
} 

public OnEntityDestroyed( entity )
{
	
	new killer = -1;
	new index = -1;
	
	if ( IsValidEdict( entity ) )
	{
		
		index = FindValueInArray( g_iGascans, entity );
				
		if( index > -1 )
		{
			
			killer = GetArrayCell( g_iLasthits, index );
			
			// they can be destroyed at mapchange and if no one touched them, killer will be -1
			// also it will be -1 if it was picked up (after spitter or inferno)
			if( IsClientAndInGame( killer ) )
			{
				
				new String:PlayerName[ 32 ];
				GetClientName( killer, PlayerName, sizeof( PlayerName ) );
				
				if( g_bWasSpitter[ killer ] )
				{
				
					PrintToChatAll( "\x04[Fire]\x01 %t", "BurnedGascanAsSpitter", PlayerName );
				
				} else {
				
					PrintToChatAll( "\x04[Fire]\x01 %t", "BurnedGascan", PlayerName );
				
				}

			}
					
			SDKUnhook( entity, SDKHook_OnTakeDamage, OnTakeDamageGascan );
						
			// set to -1 for @UnhookGascans to know that it was already unhooked
			SetArrayCell( g_iGascans, index, -1 );
			
		}
	
	}
	
}

public Action:OnTakeDamageGascan( victim, &attacker, &inflictor, &Float:damage, &damagetype )
{

	new index = -1;
	
	// save lasthit. when first inferno fired by player burns second gascan there are MANY ontakedamage calls from first inferno and player. we need only real player.
	// we need hits only from spitter or survivors.
	if ( 
		IsValidEdict( victim ) && 
		IsClientAndInGame( attacker ) && 
		( 
			( 
				GetClientTeam( attacker ) == TEAM_INFECTED && 
				GetEntProp( attacker, Prop_Send, "m_zombieClass" ) == CLASS_SPITTER
			) 
			|| 
			( 
				GetClientTeam( attacker ) == TEAM_SURVIVORS 
			)
		)
	)
	{
		
		index = FindValueInArray( g_iGascans, victim );
		
		if( index > -1 )
		{

			SetArrayCell( g_iLasthits, index, attacker );
			
		}

	}	
		
}  

public UnhookGascans( )
{

	new entity = -1;

	// unhook previous if they are still hooked
	for ( new i = 0; i < GetArraySize( g_iGascans ); i++ )
	{
		
		entity = GetArrayCell( g_iGascans, i );
		
		if( entity != -1 )
		{
			
			SDKUnhook( entity, SDKHook_OnTakeDamage, OnTakeDamageGascan );
		
		}
		
	}

}

public RefreshGascans( )
{
	
	if( g_bModInProgress )
		return;
	
	UnhookGascans( );

	// reset arrays
	ClearArray( g_iGascans );
	ClearArray( g_iLasthits );
	
	decl String:EdictClassName[ 32 ];
	
	// find and save all gascans
	for ( new i = 0; i <= GetMaxEntities( ); i++ )
	{
	
		if ( IsValidEdict( i ) )
		{
		
			GetEdictClassname( i, EdictClassName, sizeof( EdictClassName ) );
			if ( !StrEqual( EdictClassName, "weapon_gascan" ) ) 
			{
			
				continue;
			
			}

			SDKHook( i, SDKHook_OnTakeDamage, OnTakeDamageGascan );
				
			PushArrayCell( g_iGascans, i );
			PushArrayCell( g_iLasthits, -1 );

		}
		
	}

}

public ModifyGascans( )
{
	
	g_bModInProgress = true;
	
	// replaces prop_physics gascans with weapon_gascan
	
	decl String:EdictModelName[ 128 ];
	decl String:EdictClassName[ 32 ];
	
	for ( new i = 0; i <= GetMaxEntities( ); i++ )
	{
	
		if ( IsValidEdict( i ) )
		{
			
			// reset string for every next entity(there can be no model name and old will be used)
			EdictModelName[ 0 ] = '\0';
			
			GetEdictClassname( i, EdictClassName, sizeof( EdictClassName ) );
			if( StrEqual( EdictClassName, "prop_physics" ) )
			{
			
				GetEntPropString( i, Prop_Data, "m_ModelName", EdictModelName, sizeof( EdictModelName ) );
				if ( StrEqual( EdictModelName, "models/props_junk/gascan001a.mdl" ) )
				{
							
					new entity = CreateEntityByName("weapon_gascan");
					SetEntityModel( entity, EdictModelName );

					decl Float:vPos[ 3 ], Float:vAng[ 3 ];
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", vPos );
					GetEntPropVector( i, Prop_Send, "m_angRotation", vAng );
					DispatchKeyValueVector( entity, "origin", vPos );
					DispatchKeyValueVector( entity, "angles", vAng );
					
					DispatchSpawn( entity );
					
					AcceptEntityInput( i, "Kill" );
				
				}
				
			}
			
		}

	}
	
	g_bModInProgress = false;
	
}

bool:IsClientAndInGame(index)
{
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}