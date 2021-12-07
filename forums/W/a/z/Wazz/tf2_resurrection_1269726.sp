#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define TFMAXPLAYERS						34

#define RESURRECTION_SOUND_GLOBAL_1			"ambient/wind_gust1.wav"
#define RESURRECTION_SOUND_GLOBAL_2			"ambient/thunder4.wav"

#define RESURRECTION_SOUND_LOCAL_1			"weapons/debris4.wav"
#define RESURRECTION_SOUND_LOCAL_2			"weapons/demo_charge_windup1.wav"
#define RESURRECTION_SOUND_LOCAL_3			"weapons/flame_thrower_airblast_rocket_redirect.wav"

new bool:g_bClientHasDied[ TFMAXPLAYERS ];	// Used to make sure we have valid values in the pos/ang global varibles for the client
new Float:g_vecClientDeathPosition[ TFMAXPLAYERS ][ 3 ];
new Float:g_angClientDeathAngles[ TFMAXPLAYERS ][ 3 ];
new Handle:g_hClientPowerPlayTimer[ TFMAXPLAYERS ];
new Handle:g_hAutoPopup;
new Handle:g_hPowerPlayTime;
new bool:g_bAutoPopup;
new Float:g_fPowerPlayTime;

public Plugin:myinfo =
{
	name = "TF2: Resurrection",
	author = "Wazz",
	description = "Allows admins to resurrect themselves and become a wrathful god among men. An everyday activity really eh?",
	version = "9.0.0.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart( )
{
	g_hAutoPopup = CreateConVar( "sm_resurrection_autopopup", "1", "Enable ( 1 ) or disable ( 0 ) a popup that will appear to all admins with access to the resurrection commands when they die", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( g_hAutoPopup, Callback_AutoPopupChanged );
	
	g_hPowerPlayTime = CreateConVar( "sm_resurrection_powerplaytime", "30", "The durution of the powerplay effect that occurs after resurrection", FCVAR_PLUGIN, true, 0.0 );
	HookConVarChange( g_hPowerPlayTime, Callback_PowerPlayTimeChanged );
	
	HookEvent( "player_death", Event_OnPlayerDeath );
	
	RegAdminCmd( "sm_resurrect", ConCommand_Resurrection, ADMFLAG_BAN, "Resurrect yourself" );
	// A shorter command for all you lazy slags
	RegAdminCmd( "sm_res", ConCommand_Resurrection, ADMFLAG_BAN, "Resurrect yourself" );
	
	return;
}

public OnConfigsExecuted( )
{
	g_bAutoPopup = GetConVarBool( g_hAutoPopup );
	g_fPowerPlayTime = GetConVarFloat( g_hPowerPlayTime );
	
	return;
}

public Callback_AutoPopupChanged( Handle:hConvar, const String:szOldValue[], const String:szNewValue[] )
{
	g_bAutoPopup = StringToInt( szNewValue ) == 0 ? false : true;
	
	return;
}

public Callback_PowerPlayTimeChanged( Handle:hConvar, const String:szOldValue[], const String:szNewValue[] )
{
	g_fPowerPlayTime = StringToFloat( szNewValue );
	
	return;
}

public OnMapStart( )
{
	PrecacheSound( RESURRECTION_SOUND_GLOBAL_1, true );
	PrecacheSound( RESURRECTION_SOUND_GLOBAL_2, true );
	
	PrecacheSound( RESURRECTION_SOUND_LOCAL_1, true );
	PrecacheSound( RESURRECTION_SOUND_LOCAL_2, true );
	PrecacheSound( RESURRECTION_SOUND_LOCAL_3, true );
	
	return;
}

public OnClientConnected( client )
{
	g_bClientHasDied[ client ] = false;
	
	return;
}

public OnClientDisconnect( client )
{
	if ( g_hClientPowerPlayTimer[ client ] != INVALID_HANDLE )
	{
		KillTimer( g_hClientPowerPlayTimer[ client ] );
		g_hClientPowerPlayTimer[ client ] = INVALID_HANDLE;
	}
	
	return;
}

public Event_OnPlayerDeath( Handle:hEvent, const String:szName[ ], bool:bDontBroadcast )
{
	new userid = GetEventInt( hEvent, "userid" );
	new client = GetClientOfUserId( userid );
	
	if ( CheckCommandAccess( client, "sm_resurrect", ADMFLAG_BAN ) )
	{
		// Only need to set this once per client session, after that we can presume that the pos/ang variables are valid
		g_bClientHasDied[ client ] = true;
		
		if ( g_hClientPowerPlayTimer[ client ] != INVALID_HANDLE )
		{
			KillTimer( g_hClientPowerPlayTimer[ client ] );
			g_hClientPowerPlayTimer[ client ] = INVALID_HANDLE;
		}
		
		GetClientAbsOrigin( client, g_vecClientDeathPosition[ client ] );
		GetClientAbsAngles( client, g_angClientDeathAngles[ client ] );
		
		if ( g_bAutoPopup )
		{
			CreateTimer( 3.0, Timer_ShowPopupMenu, userid, TIMER_FLAG_NO_MAPCHANGE );
		}
	}
	
	return;
}

public Action:Timer_ShowPopupMenu( Handle:hTimer, any:userid )
{
	new client = GetClientOfUserId( userid );
	
	if ( client && IsClientInGame( client ) )
	{
		new Handle:hMenu = CreateMenu( MenuHandler_ResurrectionPopup );

		SetMenuTitle( hMenu, "Resurrect yourself?" );

		AddMenuItem( hMenu, "0", "No" );
		AddMenuItem( hMenu, "1", "Yes" );

		DisplayMenu( hMenu, client, 10);
	}
	
	return Plugin_Handled;
}


public MenuHandler_ResurrectionPopup(Handle:hMenu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[ 2 ];		
		GetMenuItem( hMenu, param2, info, sizeof(info) );
		
		if ( info[0] == '1' )
		{
			ResurrectClient( client );
		}
	}
	
	return;
}

public Action:ConCommand_Resurrection( client, args )
{
	if ( !client )
	{
		ReplyToCommand( client, "nope.avi" );
		
		return Plugin_Handled;
	}
	
	ResurrectClient( client );
	
	return Plugin_Handled;
}

ResurrectClient( client )
{
	if ( IsPlayerAlive( client ) || !g_bClientHasDied[ client ] || GetClientTeam( client ) < _:TFTeam_Red )
	{
		PrintToChat( client, "You cannot be resurrected" );
		
		return;
	}
	
	new ragdoll = GetEntPropEnt( client, Prop_Send, "m_hRagdoll" );
	
	if ( ragdoll != -1 )
	{
		DissolveRagdoll( ragdoll );
	}
	
	EmitSoundToAll( RESURRECTION_SOUND_GLOBAL_1, client );
	EmitSoundToAll( RESURRECTION_SOUND_GLOBAL_2, client );
	
	PrintToChat( client, "You are being resurrected..." );
	CreateTimer( 2.0, Timer_ResurrectPlayer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
	
	return;
}

public Action:Timer_ResurrectPlayer( Handle:hTimer, any:userid )
{
	new client = GetClientOfUserId( userid );
	
	if ( !client || !IsClientInGame( client ) || IsPlayerAlive( client ) || GetClientTeam( client ) < _:TFTeam_Red )
	{
		return Plugin_Handled;
	}
	
	TF2_RespawnPlayer( client );
	TeleportEntity( client, g_vecClientDeathPosition[ client ], g_angClientDeathAngles[ client ], NULL_VECTOR );

	CreateResurrectionEffects( client );
	
	new Float:vecLocalPosition[ 3 ];
	vecLocalPosition = g_vecClientDeathPosition[ client ];
	
	EmitAmbientSound( RESURRECTION_SOUND_LOCAL_1, vecLocalPosition, client );
	EmitAmbientSound( RESURRECTION_SOUND_LOCAL_2, vecLocalPosition, client );
	EmitAmbientSound( RESURRECTION_SOUND_LOCAL_3, vecLocalPosition, client );
	
	if ( g_fPowerPlayTime > 0.0 )
	{
		TF2_SetPlayerPowerPlay( client, true );
		g_hClientPowerPlayTimer[ client ] = CreateTimer( g_fPowerPlayTime, Timer_RemovePowerPlay, client, TIMER_FLAG_NO_MAPCHANGE );
	}
	
	return Plugin_Handled;
}

public Action:Timer_RemovePowerPlay( Handle:hTimer, any:client )
{
	g_hClientPowerPlayTimer[ client ] = INVALID_HANDLE;
	
	if ( !IsClientInGame( client ) )
	{
		return Plugin_Handled;
	}
	
	// psychonic: IT DOESNT MATTER IF THIS USER IS INCORRECT KK?
	TF2_SetPlayerPowerPlay( client, false );
	
	return Plugin_Handled;
}

/**
 * Makes the ragoll go away in a pretty fashion
 */
DissolveRagdoll( ragdoll )
{
	new dissolver = CreateEntityByName( "env_entity_dissolver" );
	
	if ( dissolver == -1 )
	{
		return;
	}
	
	DispatchKeyValue( dissolver, "dissolvetype", "0" );
	DispatchKeyValue( dissolver, "magnitude", "1" );
	DispatchKeyValue( dissolver, "target", "!activator" );
	
	AcceptEntityInput( dissolver, "Dissolve", ragdoll );
	AcceptEntityInput( dissolver, "Kill" );
	
	return;
}

/**
 * Some respawn effects for the admin for a DRAMATIC ZOMGWTF effect
 */
CreateResurrectionEffects( client )
{
	new particle;
	decl String:szOutput[64];
	
	Format( szOutput, sizeof(szOutput), "OnUser4 !self:Kill::5.0:1" );
		
	if ( ( particle = CreateEntityByName( "info_particle_system" ) ) != -1 )
	{
		TeleportEntity( particle, g_vecClientDeathPosition[ client ], NULL_VECTOR, NULL_VECTOR );

		if ( TFTeam:GetClientTeam( client ) == TFTeam_Blue )
		{
			DispatchKeyValue( particle, "effect_name", "teleportedin_blue" );
		}
		else
		{
			DispatchKeyValue( particle, "effect_name", "teleportedin_red" );	
		}
		
		ActivateEntity( particle );
		AcceptEntityInput( particle, "Start" );
		
		SetVariantString( szOutput );
		AcceptEntityInput( particle, "AddOutput" );
		AcceptEntityInput( particle, "FireUser4" );
	}	
	
	if ( ( particle = CreateEntityByName( "info_particle_system" ) ) != -1 )
	{
		TeleportEntity( particle, g_vecClientDeathPosition[ client ], NULL_VECTOR, NULL_VECTOR );

		DispatchKeyValue( particle, "effect_name", "ghost_appearation" );
		
		ActivateEntity( particle );
		AcceptEntityInput( particle, "Start" );
		
		SetVariantString( szOutput );
		AcceptEntityInput( particle, "AddOutput" );
		AcceptEntityInput( particle, "FireUser4" );
	}
	
	return;
}

// http://www.paulclothier.com/media/mudkip.jpg
// :3
