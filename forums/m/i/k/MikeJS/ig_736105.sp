#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#include <tf2>
#include <tf2_stocks>

#include <sdkhooks>
#include <tf2items>

#define VERSION "2.0"

#define DEFAULT_FOV 120

#define AIR_ACCEL 50

#define FLAG_RETURNED 0
#define FLAG_TAKEN 1
#define FLAG_DROPPED 2

new fov[ MAXPLAYERS + 1 ];

new bool:hideSuicide[ MAXPLAYERS + 1 ];

new bool:roundEnded;

new Handle:cookie_fov;

new sprite_beam;
new sprite_halo;
new sprite_explosion;

new Handle:captureZones[ 2 ];

public Plugin:myinfo =
{
	name = "Instagib",
	author = "MikeJS",
	description = "Scouts, railjumps, instakills.",
	version = VERSION,
	url = ""
}

initCookies()
{
	cookie_fov = RegClientCookie( "instagib_fov", "FOV for instagib", CookieAccess_Protected );
}

initCvars()
{
	CreateConVar( "instagib", VERSION, "Instagib version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}

initEvents()
{
	HookEvent( "player_spawn", event_playerSpawn );
	HookEvent( "player_team", event_playerSpawn );

	HookEvent( "player_death", event_playerDeath, EventHookMode_Pre );

	HookEvent( "teamplay_round_start", event_roundStart );
	HookEvent( "teamplay_restart_round", event_roundStart );
	HookEvent( "teamplay_round_win", event_roundWin );

	HookEvent( "post_inventory_application", event_inventory );
}

initEnts()
{
	HookEntityOutput( "item_teamflag", "OnPickUp", ent_flagTake );
	HookEntityOutput( "item_teamflag", "OnCapture", ent_flagReturn );
	HookEntityOutput( "item_teamflag", "OnReturn", ent_flagReturn );
}

initCmds()
{
	RegConsoleCmd( "sm_fov", cmd_fov, "Set FOV" );
}

initArrays()
{
	captureZones[ 0 ] = CreateArray( 1 );
	captureZones[ 1 ] = CreateArray( 1 );
}

initSprites()
{
	sprite_beam = PrecacheModel( "materials/sprites/laser.vmt" );
	sprite_halo = PrecacheModel( "materials/sprites/halo01.vmt" );
	sprite_explosion = PrecacheModel( "sprites/sprite_fire01.vmt" );
}

initSounds()
{
	PrecacheSound( "vo/intel_teamreturned.wav" );
	PrecacheSound( "vo/intel_enemyreturned.wav" );
	PrecacheSound( "vo/intel_enemyreturned2.wav" );
	PrecacheSound( "vo/intel_enemyreturned3.wav" );
}

public OnPluginStart()
{
	initCookies();
	initCvars();
	initEvents();
	initEnts();
	initCmds();
	initArrays();

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame( i ) && !IsFakeClient( i ) )
		{
			OnClientPutInServer( i );
		}
	}
}

public OnConfigsExecuted()
{
	SetConVarInt( FindConVar( "sv_airaccelerate" ), AIR_ACCEL, true );
}

public OnMapStart()
{
	initSprites();
	initSounds();

	ClearArray( captureZones[ 0 ] );
	ClearArray( captureZones[ 1 ] );
}

public OnClientConnected( client )
{
	fov[ client ] = 0;

	hideSuicide[ client ] = false;
}

public OnClientPutInServer( client )
{
	SDKHook( client, SDKHook_OnTakeDamage, hook_takeDamage );
}

public OnClientCookiesCached( client )
{
	decl String:fovStr[ 4 ];

	GetClientCookie( client, cookie_fov, fovStr, sizeof( fovStr ) );

	fov[ client ] = StringToInt( fovStr );

	if( fov[ client ] == 0 )
	{
		fov[ client ] = 90;
	}

	if( IsClientInGame( client ) )
	{
		applyFov( client );
	}
}

public OnEntityCreated( ent, const String:classname[] )
{
	if( StrEqual( classname, "func_regenerate" ) )
	{
		SDKHook( ent, SDKHook_Spawn, hook_regenSpawned );
	}
}

public hook_regenSpawned( ent )
{
	AcceptEntityInput( ent, "Disable" );
}

public Action:event_playerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	TF2_SetPlayerClass( client, TFClass_Scout );
	TF2_RegeneratePlayer( client );

	if( fov[ client ] != 0 )
	{
		applyFov( client );
	}
}

public Action:event_playerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	decl String:weaponName[ 32 ];

	GetEventString( event, "weapon", weaponName, sizeof( weaponName ) );

	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	// this hides the suicide but doesn't hide things like
	// falling into dts etc

	if( !StrEqual( weaponName, "sniperrifle" ) && hideSuicide[ client ] )
	{
		hideSuicide[ client ] = false;

		return Plugin_Handled;
	}

	if( !roundEnded )
	{
		CreateTimer( 3.0, timer_respawn, client );
	}

	return Plugin_Continue;
}

public Action:event_inventory( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	TF2_RemoveAllWeapons( client );

	new Handle:railgun = TF2Items_CreateItem( OVERRIDE_ALL );

	TF2Items_SetClassname( railgun, "tf_weapon_sniperrifle" );
	TF2Items_SetItemIndex( railgun, 14 );

	TF2Items_SetLevel( railgun, 1 );
	TF2Items_SetQuality( railgun, 1 );

	TF2Items_SetNumAttributes( railgun, 1 );
	TF2Items_SetAttribute( railgun, 0, 6, 1 / 1.15 );

	new ent = TF2Items_GiveNamedItem( client, railgun );

	EquipPlayerWeapon( client, ent );

	SDKHook( ent, SDKHook_SetTransmit, hook_railgunSetTransmit );

	SetEntProp( ent, Prop_Data, "m_iClip1", 99 );

	CloseHandle( railgun );
}

setCaptureZones( team, bool:enabled )
{
	new teamIdx = teamToIdx( team );

	new size = GetArraySize( captureZones[ teamIdx ] );

	for( new i = 0; i < size; i++ )
	{
		new ent = GetArrayCell( captureZones[ teamIdx ], i );

		AcceptEntityInput( ent, enabled ? "Enable" : "Disable" );
	}
}

setFlagState( ent, flagState )
{
	if( flagState == FLAG_RETURNED || flagState == FLAG_TAKEN )
	{
		new team = GetEntProp( ent, Prop_Send, "m_iTeamNum" );

		setCaptureZones( team, flagState == FLAG_RETURNED );
	}
}

public ent_flagDrop( const String:output[], ent, activator, Float:delay )
{
	setFlagState( ent, FLAG_DROPPED );
}

public ent_flagTake( const String:output[], ent, activator, Float:delay )
{
	setFlagState( ent, FLAG_TAKEN );
}

public ent_flagReturn( const String:output[], ent, activator, Float:delay )
{
	setFlagState( ent, FLAG_RETURNED );
}

bool:isValidTeam( team )
{
	return team == 2 || team == 3;
}

teamToIdx( team )
{
	return team - 2;
}

public hook_flagTouch( ent, other )
{
	if( other > MaxClients || !IsPlayerAlive( other ) )
	{
		return;
	}

	new flagTeam = GetEntProp( ent, Prop_Send, "m_iTeamNum" );
	new clientTeam = GetClientTeam( other );

	new flagStatus = GetEntProp( ent, Prop_Send, "m_nFlagStatus" );

	if( flagTeam != clientTeam || flagStatus != FLAG_DROPPED )
	{
		return;
	}

	AcceptEntityInput( ent, "ForceReset", other, ent );
}

public Action:hook_takeDamage( victim, &attacker, &inflictor, &Float:damage, &damageType ) 
{
	if( attacker != 0 || damageType & DMG_FALL )
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action:hook_railgunSetTransmit( ent )
{
	SetEntPropFloat( ent, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.0 );
}

setupCaptureZones()
{
	new ent = MaxClients + 1;

	for( ;; )
	{
		ent = FindEntityByClassname( ent, "func_capturezone" );

		if( ent == -1 )
		{
			break;
		}

		new team = GetEntProp( ent, Prop_Send, "m_iTeamNum" );

		if( isValidTeam( team ) )
		{
			PushArrayCell( captureZones[ teamToIdx( team ) ], ent );
		}
	}
}

public Action:timer_setupFlags( Handle:timer )
{
	new ent = MaxClients + 1;

	for( ;; )
	{
		ent = FindEntityByClassname( ent, "item_teamflag" );

		if( ent == -1 )
		{
			break;
		}

		new team = GetEntProp( ent, Prop_Send, "m_iTeamNum" );

		if( isValidTeam( team ) )
		{
			// set return time to 15s
			SetVariantString( "ReturnTime 15" );
			AcceptEntityInput( ent, "AddOutput" );

			SDKHook( ent, SDKHook_Touch, hook_flagTouch );
		}
	}
}

public Action:event_roundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	roundEnded = false;

	setupCaptureZones();
	CreateTimer( 0.01, timer_setupFlags );
}

public Action:event_roundWin( Handle:event, const String:name[], bool:dontBroadcast )
{
	roundEnded = true;
}

public Action:cmd_fov( client, args )
{
	if( args == 0 )
	{
		ReplyToCommand( client, "Your FOV is %d", fov[ client ] );

		return Plugin_Handled;
	}

	decl String:arg[ 8 ];

	GetCmdArg( 1, arg, sizeof( arg ) );

	new desired = StringToInt( arg );

	if( desired < 10 || desired > 170 )
	{
		ReplyToCommand( client, "FOV must be between 10 and 170." );

		return Plugin_Handled;
	}

	fov[ client ] = desired;

	applyFov( client );

	SetClientCookie( client, cookie_fov, arg );

	return Plugin_Handled;
}

bool:IsClientOnTeam( client )
{
	new team = GetClientTeam( client );

	return team == 2 || team == 3;
}

public Action:timer_respawn( Handle:timer, any:client )
{
	if( IsClientInGame( client ) && IsClientOnTeam( client ) )
	{
		TF2_RespawnPlayer( client );
	}
}

// this is technically awful but it the effects it produces is FUN
applyKnockback( client, Float:vecExplosion[ 3 ] )
{
	decl Float:vecClient[ 3 ];
	decl Float:vecVelocity[ 3 ];

	GetClientAbsOrigin( client, vecClient );
	GetEntPropVector( client, Prop_Data, "m_vecVelocity", vecVelocity );

	vecClient[ 2 ] += 20;

	decl Float:vecDelta[ 3 ];

	SubtractVectors( vecClient, vecExplosion, vecDelta );

	new Float:sqDistance = GetVectorDotProduct( vecDelta, vecDelta );

	if( sqDistance == 0 || sqDistance > 192 * 192 )
	{
		return;
	}

	ScaleVector( vecDelta, 25000 / sqDistance );

	for( new i = 0; i < 3; i++ )
	{
		vecDelta[ i ] = vecDelta[ i ] > 800 ? 800.0 : vecDelta[ i ];
	}

	AddVectors( vecDelta, vecVelocity, vecVelocity );
	TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, vecVelocity );
}

applyFov( client )
{
	SetEntProp( client, Prop_Send, "m_iFOV", fov[ client ] );
	SetEntProp( client, Prop_Send, "m_iDefaultFOV", fov[ client ] );
}

// we can't do killing in this trace because the cb is called
// for ANYTHING along the trace regardless of whether the trace
// reaches it or not due to the arbitrary object query order
// so this is just to get the endpoint...

public bool:trace_players( ent, contentsMask )
{
	return ent > MaxClients;
}

// ... for this trace, and we now know that any object queried in
// this trace is reachable, so let's do some gibbing

public bool:trace_kill( ent, contentsMask, any:attacker )
{
	if( ent > MaxClients )
	{
		return true;
	}

	if( ent == attacker || GetClientTeam( ent ) == GetClientTeam( attacker ) )
	{
		return false;
	}

	hideSuicide[ ent ] = true;

	FakeClientCommand( ent, "explode" );

	new Handle:event = CreateEvent( "player_death", true );

	SetEventInt( event, "userid", GetClientUserId( ent ) );
	SetEventInt( event, "attacker", GetClientUserId( attacker ) );
	SetEventString( event, "weapon", "sniperrifle" );
	SetEventInt( event, "weaponid", 16 );

	FireEvent( event, false );

	return false;
}

public Action:TF2_CalcIsAttackCritical( client, weapon, String:weaponName[], &bool:result )
{
	// infinite ammo
	SetEntProp( weapon, Prop_Data, "m_iClip1", 100 );

	// draw beam/hitreg etc
	decl Float:vecStart[ 3 ];
	decl Float:vecDirection[ 3 ];

	GetClientEyePosition( client, vecStart );
	GetClientEyeAngles( client, vecDirection );

	new Handle:trace = TR_TraceRayFilterEx(
		vecStart, vecDirection,
		MASK_SHOT_HULL, RayType_Infinite,
		trace_players );

	if( TR_DidHit( trace ) )
	{
		decl Float:vecEnd[ 3 ];

		TR_GetEndPosition( vecEnd, trace );

		// move explosion up a bit so it actually draws
		// do this before railjump because old instagib did
		vecEnd[ 2 ] += 2;

		// let's kill some people
		TR_TraceRayFilter(
			vecStart, vecEnd,
			MASK_SHOT_HULL, RayType_EndPoint,
			trace_kill, client );

		// RAILJUMPS
		new team = GetClientTeam( client );

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( !IsClientInGame( i ) || !IsPlayerAlive( i )
				|| ( GetClientTeam( i ) == team && i != client ) )
			{
				continue;
			}

			applyKnockback( i, vecEnd );
		}

		// LASERS
		vecStart[ 2 ] -= 4; // move beam down a bit so it's not invisible when you're stood still

		TE_SetupBeamPoints(
			vecStart, vecEnd,
			sprite_beam, sprite_halo,
			0, 0, 0.5, 8.0, 4.0, 5, 0.0,
			team == 2 ? { 255, 19, 19, 255 } : { 19, 19, 255, 255 },
			30 );
		TE_SendToAll();

		// EXPLOSIONS
		TE_SetupExplosion(
			vecEnd,
			sprite_explosion,
			1.0, 0, 0, 192, 500 );
		TE_SendToAll();
	}

	CloseHandle( trace );
}
