#define PLUGIN_VERSION	"1.1 Beta"
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_FCVAR			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGINS_NAME			"[L4D2]Pet_Christmas"
#define MDL_GIFT				"models/items/l4d_gift.mdl"
#define SND_REWARD				"level/gnomeftw.wav"
#define MDL_JETF18				"models/f18/f18_sb.mdl"
#define DMY_MISSILE				"models/w_models/weapons/w_eq_molotov.mdl"
#define MDL_GRENADE				"models/w_models/weapons/w_he_grenade.mdl"
#define MDL_MISSILE				"models/missiles/f18_agm65maverick.mdl"
#define SRT_EXPLOTION			"sprites/flamelet1.vmt"
#define MDL_BLOOD				"sprites/blood.vmt"
#define MDL_BLOODSPRAY			"sprites/bloodspray.vmt"
#define SND_AIRSTRIKE1			"npc/soldier1/misc05.wav"
#define SND_AIRSTRIKE2			"npc/soldier1/misc06.wav"
#define SND_AIRSTRIKE3			"npc/soldier1/misc10.wav"
#define SND_JETPASS				"animation/jets/jet_by_01_lr.wav"
#define SND_GATLING				"weapons/machinegun_m60/gunfire/machinegun_fire_1_incendiary.wav"
#define SND_MISSILE1			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SND_MISSILE2			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav"
#define PARTICLE_WEAPON_TRACER	"weapon_tracers_50cal" 
#define PANEL_DEVIDER			"===================="
#define CHAT_DEFAULT			"\x04[\x05PET\x04]:\x05"

#define PET_INCR_HEIGHT			15.0	//20.0
#define PET_MINDISTANCE			50.0	//70.0
#define BODY_HEIGHT				3000.0
#define COMMON_DAMAGE			10.0
#define INFECTED_DAMAGE			20.0

new Handle:g_hPetEnable;
new Handle:g_hPetScan;
new Handle:g_hPetHeight;
new Handle:g_hPetLife;
new Handle:g_hGiftLife;
new Handle:g_hChance;
new g_explotion;
new g_enable;
new Float:g_petmaxlife;
new Float:g_gifmaxlife;
new g_giftchance;
new g_PlayerPet[MAXPLAYERS+1][3];
new g_PlayerTag[MAXPLAYERS+1][2];
new Float:g_PetLife[MAXPLAYERS+1];
new Float:g_GifLife[2000];
new g_RocketAssembly[2000][2];
new Float:g_radius;
new Float:g_petheight;
new bool:g_RocketInterval[MAXPLAYERS+1][2];
new bool:g_IsPetFollow[MAXPLAYERS+1];
new bool:g_PetDirection[MAXPLAYERS+1];
new bool:g_IsIncap[MAXPLAYERS+1];
new g_bloodmodel;
new g_spraymodel;
new g_bloodColour[4] = {255,15,15,255};
new bool:g_RoundEnd;

public Plugin:myinfo =
{
	name = PLUGINS_NAME,
	author = "GsiX",
	description = "Survivor Companion",
	version = PLUGIN_VERSION,
	url = "n/a"
}

public OnPluginStart()
{
	CreateConVar( "l4d2_pet_version", PLUGIN_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_DONTRECORD );
	g_hPetEnable	= CreateConVar( "l4d2_pet_enabled",	"1",		"0:Off, 1:On,  Toggle plugin on/of", PLUGIN_FCVAR );
	g_hPetScan		= CreateConVar( "l4d2_pet_scan",	"300.0",	"Max radius of enemy scaning from survivor location", PLUGIN_FCVAR );
	g_hPetHeight	= CreateConVar( "l4d2_pet_height",	"60.0",		"Pet initial height", PLUGIN_FCVAR );
	g_hPetLife		= CreateConVar( "l4d2_pet_petlife",	"300.0",	"MIN: 10 seconds, MAX: 600 seconds, How long the pet follow master.", PLUGIN_FCVAR );
	g_hGiftLife		= CreateConVar( "l4d2_pet_giflife",	"60.0",		"How long the gift stay on ground (seconds)", PLUGIN_FCVAR );
	g_hChance		= CreateConVar( "l4d2_pet_chance",	"50",		"Chance (%) of infected drop christmas gift.", PLUGIN_FCVAR );
	AutoExecConfig( true, PLUGINS_NAME );
	
	HookEvent( "round_start",			EVENT_RoundStart );
	HookEvent( "player_death",			EVENT_PlayerDeath );
	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "lunge_pounce",			EVENT_InfectedGrab );
	HookEvent( "choke_start",			EVENT_InfectedGrab );
	HookEvent( "jockey_ride",			EVENT_InfectedGrab );
	HookEvent( "charger_pummel_start",	EVENT_InfectedGrab );
	
	HookConVarChange( g_hPetEnable,	CVAR_Changed );
	HookConVarChange( g_hPetScan,	CVAR_Changed );
	HookConVarChange( g_hPetHeight,	CVAR_Changed );

	UpdateCvar();
}

public OnMapStart()
{
	PrecacheModel( MDL_GIFT );
	PrecacheModel( MDL_JETF18 );
	PrecacheModel( DMY_MISSILE );
	PrecacheModel( MDL_GRENADE );
	PrecacheModel( MDL_MISSILE );
	PrecacheSound( SND_AIRSTRIKE1, true );
	PrecacheSound( SND_AIRSTRIKE2, true );
	PrecacheSound( SND_AIRSTRIKE3, true );
	PrecacheSound( SND_MISSILE1, true );
	PrecacheSound( SND_MISSILE2, true );
	PrecacheSound( SND_JETPASS, true );
	PrecacheSound( SND_GATLING, true);
	PrecacheSound( SND_REWARD, true);
	g_explotion = PrecacheModel( SRT_EXPLOTION );
	g_bloodmodel = PrecacheModel( MDL_BLOOD );
	g_spraymodel = PrecacheModel( MDL_BLOODSPRAY);
	
	PrecacheParticle( PARTICLE_WEAPON_TRACER );
}

public CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateCvar();
}

UpdateCvar()
{
	g_enable		= GetConVarInt( g_hPetEnable );
	g_radius		= GetConVarFloat( g_hPetScan );
	g_petheight		= GetConVarFloat( g_hPetHeight );
	g_giftchance	= GetConVarInt( g_hChance );
	g_petmaxlife	= GetConVarFloat( g_hPetLife );
	g_gifmaxlife	= GetConVarFloat( g_hGiftLife );
	if ( g_petmaxlife < 10.0 ) g_petmaxlife = 10.0;
	else if ( g_petmaxlife > 600.0 ) g_petmaxlife = 600.0;
}

public PrecacheParticle( String:particlename[] )
{
	new ent = CreateEntityByName("info_particle_system");
	if (IsValidEntity( ent ))
	{
		DispatchKeyValue( ent, "effect_name", particlename );
		DispatchSpawn( ent );
		ActivateEntity( ent );
		AcceptEntityInput( ent, "start" );
		CreateTimer( 0.01, Timer_DeleteEntity, EntIndexToEntRef( ent ), TIMER_FLAG_NO_MAPCHANGE );
	} 
}

public EVENT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == 0 ) return;
	g_RoundEnd = false;
}

public EVENT_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ) && !IsFakeClient( client ) && GetClientTeam( client ) == 2 )
	{
		g_RocketInterval[client][0] = false;
		g_RocketInterval[client][1] = false;
		g_PlayerPet[client][0] = -1;
		g_PlayerPet[client][1] = -1;
		g_PlayerPet[client][2] = -1;
		g_PlayerTag[client][0] = -1;
		g_PlayerTag[client][1] = -1;
		g_IsIncap[client] = false;
	}
}

public EVENT_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == 0 ) return;
	g_RoundEnd = true;
	for( new i = 1; i <= MaxClients; i++ )
	{
		TerminatePet( i );
	}
}

public EVENT_InfectedGrab( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_enable == 0 ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( victim ) && IsValidClient( attacker ))
	{
		g_PlayerTag[victim][0] = attacker;
	}
}

public EVENT_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == 0 ) return;
	
	new victim		= GetClientOfUserId( GetEventInt( event, "userid" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "attacker" ));
	if ( IsValidClient( victim ) && GetClientTeam( victim ) == 3 && IsValidClient( attacker ) && GetClientTeam( attacker ) == 2 )
	{
		if ( GetRandomInt( 1, 100 ) < g_giftchance )
		{
			DropChristmasGift( victim );
		}
	}
}

public Action:Timer_Interval_0( Handle:timer, any:client )
{
	g_RocketInterval[client][0] = false;
}

public Action:Timer_Interval_1( Handle:timer, any:client )
{
	g_RocketInterval[client][1] = false;
}

public Action:Timer_FireGrenade( Handle:timer, any:data )
{
	new client = GetClientOfUserId( data );
	new myPet = g_PlayerPet[client][0];
	new myEnemy = g_PlayerTag[client][0];
	if ( myPet > 0 && IsValidEntity( myPet ) && myEnemy > 0 && IsValidEntity( myEnemy ))
	{
		FireGrenade( client );
	}
}

public Action:Timer_PetEngine( Handle:timer, any:data )
{
	new client	= GetClientOfUserId( data );
	new Pet_0	= g_PlayerPet[client][0];
	new myEnemy = g_PlayerTag[client][0];
	g_PetLife[client] += 0.2;
	
	decl Float:_clPos[3];
	decl Float:_clAng[3];
	decl Float:_jtPos[3];
	decl Float:_jtAng[3];
	decl Float:_tgPos[3];
	new Float:OurDist;
	new Float:inTimer;
	
	if ( IsValidClient( client ) && IsPlayerAlive( client ) && IsValidEntity( Pet_0 ) && g_PetLife[client] <= g_petmaxlife )
	{
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", _clPos );
		GetEntPropVector( client, Prop_Data, "m_angRotation", _clAng );
		GetEntPropVector( Pet_0, Prop_Send, "m_vecOrigin", _jtPos );
		GetEntPropVector( Pet_0, Prop_Data, "m_angRotation", _jtAng );
		_clPos[2] += g_petheight;
		_jtPos[2] -= BODY_HEIGHT;
		
		if ( myEnemy < 1 )
		{
			myEnemy = ScanEnemy( client );
			if ( myEnemy == g_PlayerTag[client][1] )
			{
				myEnemy = -1;
			}
			g_PlayerTag[client][0] = myEnemy;
		}
		
		if ( myEnemy > 0 && IsValidEntity( myEnemy ) && (( myEnemy <= MaxClients && GetEntProp( myEnemy, Prop_Data, "m_iHealth" ) > 1 ) || ( myEnemy > MaxClients && GetEntProp( myEnemy, Prop_Data, "m_iHealth" ) > 0 )))
		{
			GetEntPropVector( myEnemy, Prop_Send, "m_vecOrigin", _tgPos );
			if ( GetVectorDistance( _tgPos, _jtPos ) > g_radius )
			{
				FollowTarget( client );
			}
			else
			{
				AligntToTarget( client );
				if( TraceFireCollution( client ))
				{
					FireBullet( client );
					if ( !g_RocketInterval[client][0] && myEnemy <= MaxClients )
					{
						g_RocketInterval[client][0] = true;
						FireMissile( client );
						CreateTimer( 2.0, Timer_Interval_0, client, TIMER_FLAG_NO_MAPCHANGE );
					}
					if ( !g_RocketInterval[client][1] && myEnemy <= MaxClients && GetEntProp( myEnemy, Prop_Send, "m_zombieClass" ) == 8 )
					{
						g_RocketInterval[client][1] = true;
						inTimer = 0.0; 
						for ( new i=1; i<=3; i++ )
						{
							CreateTimer( inTimer, Timer_FireGrenade, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
							inTimer += 0.2;
						}
						CreateTimer(( 10.0 + inTimer ), Timer_Interval_1, client, TIMER_FLAG_NO_MAPCHANGE );
					}
				}
				else
				{
					g_PlayerTag[client][0] = -1;
				}
			}
			return Plugin_Continue;
		}
		else
		{
			if ( g_PlayerTag[client][0] > MaxClients )
			{
				g_PlayerTag[client][1] = g_PlayerTag[client][0];
			}
			g_PlayerTag[client][0] = -1;
		}
		
		OurDist = GetVectorDistance( _clPos, _jtPos );
		if ( g_IsPetFollow[client] )
		{
			if ( OurDist < PET_MINDISTANCE )
			{
				g_IsPetFollow[client] = false;
			}
			FollowTarget( client );
		}
		else
		{
			if ( OurDist >= 1000.0 )
			{
				TeleportEntity( Pet_0, _clPos,  _clAng , NULL_VECTOR );
				return Plugin_Continue;
			}
			else if ( OurDist > 200.0 && OurDist < 1000.0 )
			{
				g_IsPetFollow[client] = true;
			}
			else
			{
				HooveringArea( client );
			}
		}
		return Plugin_Continue;
	}
	else
	{
		TerminatePet( client );
	}
	return Plugin_Stop;
}

public Action:Timer_DeleteEntity( Handle:timer, any:data )
{
	new ent = EntRefToEntIndex( data );
	if ( IsValidEntity( ent ))
	{
		decl String:classname[32];
		GetEdictClassname( ent, classname, sizeof( classname ));
		if ( StrEqual( classname, "info_particle_system", false ) || StrEqual( classname, "info_particle_target", false ))
		{
			AcceptEntityInput( ent, "stop" );
			AcceptEntityInput( ent, "kill" );
			RemoveEdict( ent );
		}
		else
		{
			AcceptEntityInput( ent, "kill" );
		}
	}
}

public Action:Timer_GiftLife( Handle:timer, any:index )
{
	new gift = EntRefToEntIndex( index );
	if ( IsValidEntity( gift ))
	{
		g_GifLife[gift] += 0.1;
		if( g_RoundEnd || g_GifLife[gift] > g_gifmaxlife )
		{
			g_GifLife[gift] = 0.0;
			AcceptEntityInput( gift, "kill" );
			return Plugin_Stop;
		}
		
		RotateAdvance( gift, 15.0, 1 );
		
		decl Float:myPos[3];
		decl Float:gfPos[3];
		GetEntPropVector( gift, Prop_Send, "m_vecOrigin", gfPos );
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && IsPlayerAlive( i ) && !IsFakeClient( i ) && GetClientTeam( i ) == 2 && g_PlayerPet[i][0] < 1 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", myPos );
				if ( GetVectorDistance( myPos, gfPos ) < 70.0 )
				{
					if ( CallPet( i ))
					{
						PrintToChat( i, "%s Player %N's pet created..!!", CHAT_DEFAULT, i );
					}
					else
					{
						PrintToChat( i, "%s Player %N's failed to create pet..!!", CHAT_DEFAULT, i );
					}
					AcceptEntityInput( gift, "kill" );
					break;
				}
			}
		}
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public OnMissileCollide( ent, target )
{
	new m1 = g_RocketAssembly[ent][1];
	new m0 = g_RocketAssembly[ent][0];
	g_RocketAssembly[ent][1] = -1;
	g_RocketAssembly[ent][0] = -1;
	
	SetUpExplosion( ent );
	DoExplosionDamage( ent );

	SDKUnhook( ent, SDKHook_TouchPost, OnMissileCollide );
	if ( IsValidEntity( m1 )) AcceptEntityInput( m1, "kill" );
	if ( IsValidEntity( m0 )) AcceptEntityInput( m0, "kill" );
	if ( IsValidEntity( ent )) AcceptEntityInput( ent, "kill" );
}

public OnGrenadeCollide( ent, target )
{
	SetUpExplosion( ent );
	DoExplosionDamage( ent );

	SDKUnhook( ent, SDKHook_TouchPost, OnGrenadeCollide );
	if ( IsValidEntity( ent )) AcceptEntityInput( ent, "kill" );
}

DropChristmasGift( client )
{
	decl Float:gifPos[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", gifPos );
	gifPos[2] += 10.0;
	
	new gift = CreateEntityByName( "prop_dynamic_override" );
	if( gift != -1 )
	{
		DispatchKeyValue( gift, "model", MDL_GIFT );  
		DispatchKeyValueVector( gift, "origin", gifPos );
		SetEntPropFloat( gift, Prop_Send,"m_flModelScale", 1.0 );
		DispatchSpawn( gift );
		g_GifLife[gift] = 0.0;
		CreateTimer( 0.1, Timer_GiftLife, EntIndexToEntRef( gift ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

bool:CallPet( client )
{
	decl Float:petPos[3];
	decl Float:petAng[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", petPos );
	GetEntPropVector( client, Prop_Data, "m_angRotation", petAng );
	petPos[2] += BODY_HEIGHT;
	
	new body = CreateEntityByName( "molotov_projectile" );
	if( body != -1 )
	{
		DispatchKeyValue( body, "model", DMY_MISSILE );
		DispatchKeyValueVector( body, "origin", petPos );
		DispatchKeyValueVector( body, "Angles", petAng );
		SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.001 );
		SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", client );
		SetEntityGravity( body, 0.01 );
		DispatchSpawn( body );
	}

	petPos[2] -= BODY_HEIGHT;
	decl Float:flmOri[3] = { -7.0, 0.0, 0.0 };
	decl Float:flmAng[3] = { 0.0, 180.0, 0.0 };
	decl String:exaustName[128];
	flmOri[2] -= BODY_HEIGHT;
	
	Format( exaustName, sizeof( exaustName ), "target%d", body );
	new exaust = CreateEntityByName( "env_steam" );
	if ( exaust != -1 )
	{
		decl String:lg[32];
		Format( lg, sizeof( lg ), "%d.0", 20 );
		
		DispatchKeyValue( body, "targetname", exaustName );
		DispatchKeyValue( exaust, "SpawnFlags", "1" );
		DispatchKeyValue( exaust, "Type", "0" );
		DispatchKeyValue( exaust, "InitialState", "1" );
		DispatchKeyValue( exaust, "Spreadspeed", "10" );
		DispatchKeyValue( exaust, "Speed", "200" );
		DispatchKeyValue( exaust, "Startsize", "5" );
		DispatchKeyValue( exaust, "EndSize", "30" );
		DispatchKeyValue( exaust, "Rate", "555" );
		DispatchKeyValue( exaust, "RenderColor", "60 80 200" );
		DispatchKeyValue( exaust, "JetLength", lg ); 
		DispatchKeyValue( exaust, "RenderAmt", "180" );
		DispatchKeyValueVector( exaust, "origin", petPos );
		DispatchKeyValueVector( exaust, "Angles", petAng );
		DispatchSpawn( exaust );
		SetVariantString( exaustName );
		AcceptEntityInput( exaust, "SetParent", exaust, exaust, 0 );
		TeleportEntity( exaust, flmOri, flmAng, NULL_VECTOR );
		AcceptEntityInput( exaust, "TurnOn" );
	}
	
	decl Float:caPos[3] = { 0.0, 0.0, 0.0 };
	decl Float:caAng[3] = { 0.0, 0.0, 0.0 };
	caPos[2] -= BODY_HEIGHT;
	new attch = CreateEntityByName( "prop_dynamic_override" );
	if( attch != -1 )
	{
		decl String:namE[20];
		Format( namE, sizeof( namE ), "missile%d", body );
		DispatchKeyValue( body, "targetname", namE );
		DispatchKeyValue( attch, "model", MDL_JETF18 );  
		DispatchKeyValue( attch, "parentname", namE); 
		DispatchKeyValueVector( attch, "origin", petPos );
		DispatchKeyValueVector( attch, "Angles", petAng );
		SetVariantString( namE );
		AcceptEntityInput( attch, "SetParent", attch, attch, 0 );
		SetEntPropFloat( attch, Prop_Send,"m_flModelScale", 1.0 );
		DispatchSpawn( attch );
		TeleportEntity( attch, caPos, caAng, NULL_VECTOR );
	}
	petPos[2] += ( BODY_HEIGHT + 5.0 );
	TeleportEntity( body, petPos, NULL_VECTOR, NULL_VECTOR );
	
	g_PlayerPet[client][0] = body;
	g_PlayerPet[client][1] = attch;
	g_PlayerPet[client][2] = exaust;
	g_PetLife[client] = 0.0;
	switch( GetRandomInt( 1, 3 ))
	{
		case 1:
		{
			EmitSoundToClient( client, SND_AIRSTRIKE1 );
		}
		case 2:
		{
			EmitSoundToClient( client, SND_AIRSTRIKE2 );
		}
		case 3:
		{
			EmitSoundToClient( client, SND_AIRSTRIKE3 );
		}
	}
	CreateTimer( 0.2, Timer_PetEngine, GetClientUserId( client ), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	return true;
}

TerminatePet( client )
{
	new Float:tAng[3];
	new Float:tVol[3];
	new pet = g_PlayerPet[client][0];
	if ( pet > 0 && IsValidEntity( pet ))
	{
		GetEntPropVector( pet, Prop_Data, "m_angRotation", tAng );
		tAng[0] = -20.0;
		GetAngleVectors( tAng, tVol, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( tVol, tVol );
		ScaleVector( tVol, 900.0 );
		TeleportEntity( pet, NULL_VECTOR,  NULL_VECTOR , tVol );
	
		for( new i=2; i>=0; i-- )
		{
			pet = g_PlayerPet[client][i];
		
			if ( pet > 0 && IsValidEntity( pet ))
			{
				CreateTimer( 0.3, Timer_DeleteEntity, EntIndexToEntRef( pet ), TIMER_FLAG_NO_MAPCHANGE );
			}
			g_PlayerPet[client][i] = -1;
		}
	}
	if ( IsValidClient( client ))
	{
		EmitSoundToClient( client, SND_JETPASS );
	}
	g_PetLife[client] = 0.0;
	g_PlayerTag[client][0] = -1;
	g_PlayerTag[client][1] = -1;
}

CreateExaust( ent, length )
{ 
	new Float:flmOri[3] = { 0.0, 0.0, 0.0 };
	new Float:flmAng[3] = { 0.0, 180.0, 0.0 };
	
	decl String:exaustName[128];
	Format( exaustName, sizeof( exaustName ), "target%d", ent );
	
	new exaust = CreateEntityByName( "env_steam" );
	if ( exaust != -1 )
	{
		decl String:lg[32];
		Format( lg, sizeof( lg ), "%d.0", length );
		
		DispatchKeyValue( ent, "targetname", exaustName );
		DispatchKeyValue( exaust, "SpawnFlags", "1" );
		DispatchKeyValue( exaust, "Type", "0" );
		DispatchKeyValue( exaust, "InitialState", "1" );
		DispatchKeyValue( exaust, "Spreadspeed", "10" );
		DispatchKeyValue( exaust, "Speed", "200" );
		DispatchKeyValue( exaust, "Startsize", "5" );
		DispatchKeyValue( exaust, "EndSize", "30" );
		DispatchKeyValue( exaust, "Rate", "555" );
		DispatchKeyValue( exaust, "RenderColor", "60 80 200" );
		DispatchKeyValue( exaust, "JetLength", lg ); 
		DispatchKeyValue( exaust, "RenderAmt", "180" );
	
		DispatchSpawn( exaust );
		SetVariantString( exaustName );
		AcceptEntityInput( exaust, "SetParent", exaust, exaust, 0 );
		TeleportEntity( exaust, flmOri, flmAng, NULL_VECTOR );
		AcceptEntityInput( exaust, "TurnOn" );
	}
	return exaust;
}

CreateAttachment( ent, const String:Model[], Float:ScaleSize, Float:fwdPos )
{
	decl Float:athPos[3];
	decl Float:athAng[3];
	decl Float:caPos[3] = { 0.0, 0.0, 0.0 };
	GetEntPropVector( ent, Prop_Send, "m_vecOrigin", athPos );
	GetEntPropVector( ent, Prop_Data, "m_angRotation", athAng );
	new attch = CreateEntityByName( "prop_dynamic_override" );
	if( attch != -1 )
	{
		caPos[0] = fwdPos;
		decl String:namE[20];
		Format( namE, sizeof( namE ), "missile%d", ent );
		DispatchKeyValue( ent, "targetname", namE );
		DispatchKeyValue( attch, "model", Model );  
		DispatchKeyValue( attch, "parentname", namE); 
		DispatchKeyValueVector( attch, "origin", athPos );
		DispatchKeyValueVector( attch, "Angles", athAng );
		SetVariantString( namE );
		AcceptEntityInput( attch, "SetParent", attch, attch, 0 );
		DispatchKeyValueFloat( attch, "fademindist", 10000.0 );
		DispatchKeyValueFloat( attch, "fademaxdist", 20000.0 );
		DispatchKeyValueFloat( attch, "fadescale", 0.0 ); 
		SetEntPropFloat( attch, Prop_Send,"m_flModelScale", ScaleSize );
		DispatchSpawn( attch );
		TeleportEntity( attch, caPos, NULL_VECTOR, NULL_VECTOR );
	}
	return attch;
}

FollowTarget( client )
{
	new Pet_0 = g_PlayerPet[client][0];
	new target = g_PlayerTag[client][0];
	if ( target < 1 || !IsValidEntity( target ))
	{
		target = client;
	}
	
	new bool:sSwitch = false;
	decl Float:mmOrg[3];
	decl Float:mmAng[3];
	decl Float:mmVel[3];
	decl Float:mmBff[3];
	decl Float:_mmBff[3];
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", mmBff );
	GetEntPropVector( Pet_0, Prop_Send, "m_vecOrigin", mmOrg );
	GetEntPropVector( Pet_0, Prop_Data, "m_angRotation", mmAng );
	mmOrg[2] -= BODY_HEIGHT;
	mmBff[2] += g_petheight;
	
	if ( GetAngleBetweenVector( Pet_0, target ) > 30.0 )
	{
		if ( g_PetDirection[client] ) mmAng[1] += 20.0;
		else mmAng[1] -= 20.0;
		sSwitch = true;
	}
	else
	{
		if ( GetVectorDistance( mmOrg, mmBff ) > PET_MINDISTANCE )
		{
			MakeVectorFromPoints( mmOrg, mmBff, _mmBff );
			NormalizeVector( _mmBff, _mmBff );
			GetVectorAngles( _mmBff, mmAng );
		}
	}
	
	if ( mmOrg[2] < mmBff[2] )
	{
		mmAng[0] = -10.0;
		GetAngleVectors( mmAng, mmVel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( mmVel, mmVel );
		mmAng[0] = 0.0;
	}
	else if ( mmOrg[2] > ( mmBff[2] + PET_INCR_HEIGHT ))
	{
		mmAng[0] = 10.0;
		GetAngleVectors( mmAng, mmVel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( mmVel, mmVel );
		mmAng[0] = 0.0;
	}
	else
	{
		mmAng[0] = 0.0;
		GetAngleVectors( mmAng, mmVel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( mmVel, mmVel );
	}
	
	if ( sSwitch ) ScaleVector( mmVel, 120.0 );
	else ScaleVector( mmVel, 230.0 );
	
	TeleportEntity( Pet_0, NULL_VECTOR,  mmAng , mmVel );
}

HooveringArea( client )
{
	new Pet_0 = g_PlayerPet[client][0];
	decl Float:nnOrg[3];
	decl Float:nnAng[3];
	decl Float:nnVel[3];
	decl Float:nnBuf[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", nnBuf );
	GetEntPropVector( Pet_0, Prop_Send, "m_vecOrigin", nnOrg );
	GetEntPropVector( Pet_0, Prop_Data, "m_angRotation", nnAng );
	nnBuf[2] += g_petheight;
	nnOrg[2] -= BODY_HEIGHT;
	
	if ( GetAngleBetweenVector( Pet_0, client ) > 15.0 )
	{
		if ( g_PetDirection[client] ) nnAng[1] += 15.0;
		else nnAng[1] -= 15.0;
	}
	else
	{
		if (  GetVectorDistance( nnBuf, nnOrg ) > PET_MINDISTANCE )
		{
			MakeVectorFromPoints( nnOrg, nnBuf, nnVel );
			NormalizeVector( nnVel, nnVel );
			GetVectorAngles( nnVel, nnAng );
		}
		else
		{
			if ( g_PetDirection[client] ) g_PetDirection[client] = false;
			else g_PetDirection[client] = true;
			
			if ( g_PetDirection[client] ) nnAng[1] += 15.0;
			else nnAng[1] -= 15.0;
			TeleportEntity( Pet_0, NULL_VECTOR,  nnAng , NULL_VECTOR );
			if ( g_PetDirection[client] ) nnAng[1] += 15.0;
			else nnAng[1] -= 15.0;
		}
	}
	
	if ( nnOrg[2] < nnBuf[2] )
	{
		nnAng[0] = -10.0;
		GetAngleVectors( nnAng, nnVel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( nnVel, nnVel );
		nnAng[0] = 0.0;
	}
	else if ( nnOrg[2] > ( nnBuf[2] + PET_INCR_HEIGHT ))
	{
		nnAng[0] = 10.0;
		GetAngleVectors( nnAng, nnVel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( nnVel, nnVel );
		nnAng[0] = 0.0;
	}
	else
	{
		nnAng[0] = 0.0;
		GetAngleVectors( nnAng, nnVel, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( nnVel, nnVel );
	}
	ScaleVector( nnVel, 60.0 );
	TeleportEntity( Pet_0, NULL_VECTOR,  nnAng , nnVel );
}

ScanEnemy( client )
{
	new enemy = -1;
	decl Float:wgPos[3];
	decl Float:ddPos[3];
	decl String:nameType[24];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", wgPos );
	
	new eCount = GetEntityCount();
	for ( new i = 1; i <= eCount; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		
		if ( i <= MaxClients )
		{
			if ( IsValidClient( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == 3 && GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
				if ( GetVectorDistance( wgPos, ddPos ) <= g_radius )
				{
					if ( GetEntProp( i, Prop_Send, "m_zombieClass" ) == 8 )
					{
						enemy = i;
						break;
					}
					else
					{
						enemy = i;
						break;
					}
				}
			}
		}
		else
		{
			GetEntityClassname( i, nameType, sizeof( nameType ));
			if ( StrContains( nameType, "infected", false) != -1 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
				if ( GetVectorDistance( wgPos, ddPos ) <= g_radius )
				{
					enemy = i;
					break;
				}
			}
			/**
			if ( StrContains( nameType, "witch", false) != -1 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
				if ( GetVectorDistance( wgPos, ddPos ) <= g_radius )
				{
					enemy = i;
					break;
				}
			}
			**/
		}
	}
	return enemy;
}

AligntToTarget( client )
{
	new subject = g_PlayerPet[client][0];
	new target = g_PlayerTag[client][0];
	
	decl Float:subPos[3];
	decl Float:cliPos[3];
	decl Float:subAng[3];
	decl Float:tarPos[3];
	decl Float:tarVol[3];
	decl Float:buFF[3];
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", cliPos );
	GetEntPropVector( subject, Prop_Send, "m_vecOrigin", subPos );
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", tarPos );
	cliPos[2] += g_petheight;
	subPos[2] -= BODY_HEIGHT;
	
	MakeVectorFromPoints( subPos, tarPos, buFF );
	NormalizeVector( buFF, buFF );
	GetVectorAngles( buFF, subAng );
	
	
	if ( subPos[2] < cliPos[2] )
	{
		subAng[0] = -80.0;
		GetAngleVectors( subAng, tarVol, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( tarVol, tarVol );
		ScaleVector( tarVol, 10.0 );
		subAng[0] = 0.0;
	}
	else if ( subPos[2] > ( cliPos[2] + PET_INCR_HEIGHT ))
	{
		subAng[0] = 80.0;
		GetAngleVectors( subAng, tarVol, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( tarVol, tarVol );
		ScaleVector( tarVol, 10.0 );
		subAng[0] = 0.0;
	}
	else
	{
		subAng[0] = 0.0;
		GetAngleVectors( subAng, tarVol, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( tarVol, tarVol );
		ScaleVector( tarVol, 1.0 );
	}
	TeleportEntity( subject, NULL_VECTOR,  subAng , tarVol );
}
//Bimbo1
Float:GetAngleBetweenVector( subject, target )
{
	new Float:Output;
	decl Float:ang[3];
	decl Float:vec[3];
	decl Float:targetPos[3];
	GetEntPropVector( subject, Prop_Data, "m_angRotation", ang );
	GetEntPropVector( subject, Prop_Send, "m_vecOrigin", vec );
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", targetPos );
	ang[0] = 0.0;
	
	decl Float:fwd[3];
	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);
	vec[0] = targetPos[0] - vec[0];
	vec[1] = targetPos[1] - vec[1];
	vec[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(fwd, fwd);
	ScaleVector(vec, 1/SquareRoot(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]));
	Output = ArcCosine(vec[0]*fwd[0]+vec[1]*fwd[1]+vec[2]*fwd[2]);
	
	return RadToDeg( Output );
}

FireBullet( client )
{
	new subject = g_PlayerPet[client][0];
	new target = g_PlayerTag[client][0];
	
	//show particle
	decl Float:sbPos[3];
	decl Float:sbAng[3];
	decl Float:tgPos[3];
	decl Float:tgAng[3];
	GetEntPropVector( subject, Prop_Send, "m_vecOrigin", sbPos );
	GetEntPropVector( subject, Prop_Data, "m_angRotation", sbAng );
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", tgPos );
	GetEntPropVector( target, Prop_Send, "m_angRotation", tgAng );
	tgPos[2] += 40.0;
	sbPos[2] -= BODY_HEIGHT;
	
	// show blood
	TE_SetupBloodSprite( tgPos, tgAng, g_bloodColour, 3, g_spraymodel, g_bloodmodel);
	TE_SendToAll();
	
	// show muzzle flash
	TE_SetupMuzzleFlash( sbPos, sbAng, 2.0, 1 );
	TE_SendToAll();
	
	// show track
	decl String:temp[16] = "";
	new Track_1 = CreateEntityByName( "info_particle_target" );
	new Track_2 = CreateEntityByName( "info_particle_system" );
	if ( Track_1 != -1 && Track_2 != -1&& IsValidEntity( Track_1 )&& IsValidEntity( Track_2 ))
	{
		Format( temp, 64, "cptarget%d", Track_1 );
		DispatchKeyValue( Track_1, "targetname", temp );	
		TeleportEntity( Track_1, tgPos, NULL_VECTOR, NULL_VECTOR ); 
		ActivateEntity( Track_1 );
	
	
		DispatchKeyValue( Track_2, "effect_name", PARTICLE_WEAPON_TRACER );
		DispatchKeyValue( Track_2, "cpoint1", temp );
		DispatchSpawn( Track_2 );
		ActivateEntity( Track_2 ); 
		TeleportEntity( Track_2, sbPos, NULL_VECTOR, NULL_VECTOR );
		AcceptEntityInput( Track_2, "start" );	
		CreateTimer( 0.01, Timer_DeleteEntity, EntIndexToEntRef( Track_1 ), TIMER_FLAG_NO_MAPCHANGE );
		CreateTimer( 0.01, Timer_DeleteEntity, EntIndexToEntRef( Track_2 ), TIMER_FLAG_NO_MAPCHANGE );
	}
	
	DealDamage( GetEntPropEnt( subject, Prop_Data, "m_hOwnerEntity" ), COMMON_DAMAGE, target );
	EmitSoundToAll( SND_GATLING, subject, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
}

FireMissile( client )
{
	new subject = g_PlayerPet[client][0];
	new target = g_PlayerTag[client][0];
	
	decl Float:fmPos_1[3];
	decl Float:fmPos_2[3];
	decl Float:bfAng[3];
	decl Float:bfVol[3];
	GetEntPropVector( subject, Prop_Send, "m_vecOrigin", fmPos_1 );
	GetEntPropVector( subject, Prop_Data, "m_angRotation", bfAng );
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", fmPos_2 );
	fmPos_1[2] -= BODY_HEIGHT;
	fmPos_2[2] += 30.0;
	
	new body = CreateEntityByName( "molotov_projectile" );
	if( body != -1 )
	{
		DispatchKeyValue( body, "model", DMY_MISSILE );
		DispatchKeyValueVector( body, "origin", fmPos_1 );
		DispatchKeyValueVector( body, "Angles", bfAng );
		SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.001 );
		SetEntityGravity( body, 0.01 );
		SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", client );
		DispatchSpawn( body );
	}
	
	new exau = CreateExaust( body, 10 );
	new atth = CreateAttachment( body, MDL_MISSILE, 0.07, 5.0 );

	g_RocketAssembly[body][0] = exau;
	g_RocketAssembly[body][1] = atth;
	
	SDKHook( body, SDKHook_TouchPost, OnMissileCollide );
	
	fmPos_1[0] += GetRandomFloat( -20.0, 20.0 );
	fmPos_1[1] += GetRandomFloat( -20.0, 20.0 );
	fmPos_1[2] += GetRandomFloat( -10.0, 5.0 );
		
	MakeVectorFromPoints( fmPos_1, fmPos_2, bfVol );
	NormalizeVector( bfVol, bfVol );
	GetVectorAngles( bfVol, bfAng );
	ScaleVector( bfVol, 500.0 );
	TeleportEntity( body, NULL_VECTOR, bfAng, bfVol );
}

FireGrenade( client )
{
	new subject = g_PlayerPet[client][0];
	new target = g_PlayerTag[client][0];

	decl Float:fgPos[3];
	decl Float:fgPos2[3];
	decl Float:fgAng[3];
	decl Float:fgVol[3];
	decl Float:fgDis;
	GetEntPropVector( subject, Prop_Send, "m_vecOrigin", fgPos );
	GetEntPropVector( subject, Prop_Data, "m_angRotation", fgAng );
	GetEntPropVector( target, Prop_Send, "m_vecOrigin", fgPos2 );
	fgPos[2] -= BODY_HEIGHT;
	
	new ent = CreateEntityByName( "grenade_launcher_projectile" );
	if( ent != -1 )
	{
		DispatchKeyValue( ent, "model", MDL_GRENADE );  
		DispatchKeyValueVector( ent, "origin", fgPos );
		DispatchKeyValueVector( ent, "Angles", fgAng );
		SetEntityGravity( ent, 1.0 );
		SetEntPropEnt( ent, Prop_Data, "m_hOwnerEntity", client );
		DispatchSpawn( ent );
		
		SDKHook( ent, SDKHook_TouchPost, OnGrenadeCollide );
		
		fgPos[0] += GetRandomFloat( -40.0, 40.0 );
		fgPos[1] += GetRandomFloat( -40.0, 40.0 );
		fgPos[2] += GetRandomFloat( 10.0, 15.0 );
		fgPos2[0] += GetRandomFloat( -40.0, 40.0 );
		fgPos2[1] += GetRandomFloat( -40.0, 40.0 );
		fgPos2[2] += GetRandomFloat( -20.0, 15.0 );
		fgAng[0] += GetRandomFloat( -15.0, 15.0 );	// yaw angle ( for more accuracy, comment out this ).
		fgAng[1] += GetRandomFloat( -15.0, 15.0 );	// pitc angle ( for more accuracy, comment out this ).
		
		fgDis = GetVectorDistance( fgPos, fgPos2 );
		MakeVectorFromPoints( fgPos, fgPos2, fgVol );
		NormalizeVector( fgVol, fgVol );
		GetVectorAngles( fgVol, fgAng );
		fgAng[0] -= 45.0;
		GetAngleVectors( fgAng, fgVol, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( fgVol, fgVol );
		ScaleVector( fgVol, (fgDis*1.25));
		
		TeleportEntity( ent, fgPos, NULL_VECTOR, NULL_VECTOR );
		TeleportEntity( ent, NULL_VECTOR, fgAng, fgVol );
	}
}

DealDamage( attacker, Float:damage, victim )
{
	if( victim > 0 && attacker > 0 )
	{
		new String:dmg_str[16];
		FloatToString( damage, dmg_str, sizeof( dmg_str ));
		new pointHurt = CreateEntityByName( "point_hurt" );
		if ( pointHurt )
		{
			DispatchKeyValue( victim,"targetname","war3_hurtme" );
			DispatchKeyValue( pointHurt, "DamageTarget","war3_hurtme" );
			DispatchKeyValue( pointHurt, "Damage", dmg_str );
			DispatchKeyValue( pointHurt,"DamageType", "-2130706430" );
			DispatchKeyValue( pointHurt, "classname", "weapon_rifle_m60" );
			DispatchSpawn( pointHurt );
			AcceptEntityInput( pointHurt, "Hurt",( attacker > 0 ) ? attacker:-1 );
			DispatchKeyValue( pointHurt, "classname", "point_hurt" );
			DispatchKeyValue( victim, "targetname", "war3_donthurtme" );
			RemoveEdict( pointHurt );
		}
	}
}

DoExplosionDamage( entity )
{
	new count, client, i, attacker ;
	decl Float:ddPos[3];
	decl Float:dgPos[3];
	decl String:tName[24];
	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", ddPos );
	
	client = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" );
	if ( IsValidClient( client )) attacker = client;
	else attacker = entity;
	
	count = GetEntityCount();
	for ( i=1; i<=count; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		
		if ( count <= MaxClients )
		{
			if( IsValidClient( i ) && GetClientTeam( i ) == 3 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", dgPos );
				if ( GetVectorDistance( ddPos, dgPos ) <= 50.0 )
				{
					DealDamage( attacker, INFECTED_DAMAGE, i );
				}
			}
		}
		else
		{
			GetEntityClassname( i, tName, sizeof( tName ));
			if ( StrContains( tName, "infected", false) != -1 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", dgPos );
				if ( GetVectorDistance( ddPos, dgPos ) <= 50.0 )
				{
					DealDamage( attacker, INFECTED_DAMAGE, i );
				}
			}
			else if ( StrContains( tName, "witch", false) != -1 )
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", dgPos );
				if ( GetVectorDistance( ddPos, dgPos ) <= 50.0 )
				{
					DealDamage( attacker, INFECTED_DAMAGE, i );
				}
			}
		}
	}
}

SetUpExplosion( entity )
{
	new Float:pp[3];
	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", pp );
	
	TE_SetupExplosion( pp, g_explotion, 3.0, 1, 0, 10, 1000 );
	TE_SendToAll();
	switch( GetRandomInt( 1, 2 ))
	{
		case 1:	{ EmitSoundToAll( SND_MISSILE1, entity, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE)	;}
		case 2:	{ EmitSoundToAll( SND_MISSILE2, entity, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE)	;}
	}
}

RotateAdvance( index, Float:value, axis )
{
	if ( IsValidEntity( index ))
	{
		decl Float:rotate_[3];
		GetEntPropVector( index, Prop_Data, "m_angRotation", rotate_ );
		rotate_[axis] += value;
		TeleportEntity( index, NULL_VECTOR, rotate_, NULL_VECTOR);
	}
}

bool:TraceFireCollution( client )
{
	new pet = g_PlayerPet[client][0];
	new bool:Hit = false;
	decl Float:vO[3];
	decl Float:vO1[3];
	decl Float:vV[3];
	decl Float:vA[3];
	GetEntPropVector( pet, Prop_Send, "m_vecOrigin", vO );
	GetEntPropVector( pet, Prop_Send, "m_vecOrigin", vO1 );
	vO[2] -= ( BODY_HEIGHT + 10.0);
	vO1[2] += 30.0;
	MakeVectorFromPoints( vO, vO1, vV );
	NormalizeVector( vV, vV );
	GetVectorAngles( vV, vA );
	new Handle:trace = TR_TraceRayFilterEx( vO, vA, MASK_SHOT, RayType_Infinite, HitEnemyOnly, GetClientUserId( client ));
	if( TR_DidHit( trace ))
	{ 
		if( IsValidEntity( TR_GetEntityIndex( trace )))
		{
			Hit = true;
		}
	}
	CloseHandle( trace );
	return Hit;
}

public bool:HitEnemyOnly( entity, contentsMask, any:data )
{
	new client = GetClientOfUserId( data );
	new tag1 = g_PlayerPet[client][1];
	new tag2 = g_PlayerPet[client][2];
	if ( IsValidEntity( entity ))
	{
		if( IsValidClient( entity ) && GetClientTeam( entity ) == 2 ) return false;
		if ( entity == tag1 || entity == tag2 ) return false;
	}
	return true;
}

bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}

