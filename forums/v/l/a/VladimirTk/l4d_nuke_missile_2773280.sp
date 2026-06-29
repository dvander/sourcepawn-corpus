#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar g_hNukeDamage, g_hNukeRadius, g_hNukeVelocity, g_hNukeLimit, g_hNukeTime;

float NukeDamage, NukeRadius, ProjectileVelo;

int Rocketparts[2000][2], Limit[MAXPLAYERS+1], Time;
	
bool isLaunch[MAXPLAYERS+1] = false;
	
Handle HandleTimer = null;

#define NUKE_SOUND    "nuke/explosion.mp3"
#define NUKE_LAUNCH   "nuke/missile.mp3"
#define COUNT_SOUND   "UI/Beep07.wav"

#define amg65 "models/missiles/f18_agm65maverick.mdl"
#define MOLO  "models/w_models/weapons/w_eq_molotov.mdl"

#define NUKE_EXPLOSION		"explosion_core"

public Plugin myinfo =
{
	name = "[L4D2] Nuclear Missile",
	author = "King_OXO",
	description = "Call A Nuclear Missile On Crosshair(new codes, thanks Silver)",
	version = "2.0",
	url = "https://forums.alliedmods.net/showthread.php?t=336654"
};

public void OnPluginStart()
{
	g_hNukeDamage   = CreateConVar("l4d2_nuke_damage", "500.0", "Damage when Missile explodes", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	g_hNukeLimit    = CreateConVar("l4d2_nuke_limit", "15.0", "Limit to use the nuke missile", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	g_hNukeTime     = CreateConVar("l4d2_nuke_time", "4", "time for the nuclear missile to be created", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	g_hNukeRadius   = CreateConVar("l4d2_nuke_radius", "1500.0", "Missile blast distance", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	g_hNukeVelocity = CreateConVar("l4d2_nuke_velocity", "2000.0", "Missile Velocity", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
	
	HookEvent("player_death", Event_death);
	
	RegAdminCmd("sm_nuke", Cmd_Nuke, ADMFLAG_KICK);
	RegAdminCmd("sm_nuke_reload", Cmd_NukeReload, ADMFLAG_KICK);
	
	AutoExecConfig(true, "l4d2_nuke_missile");
}

public void OnMapStart()
{
	PrecacheParticle(NUKE_EXPLOSION);
	PrecacheModel(amg65, true);
	PrecacheSound(NUKE_SOUND, true);
	PrecacheSound(NUKE_LAUNCH, true);
	PrecacheSound(COUNT_SOUND, true);
	
	AddFileToDownloadsTable("sound/nuke/missile.mp3");
	AddFileToDownloadsTable("sound/nuke/explosion.mp3");
}

public Action Event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		Limit[client] = 0;
		PrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
	}
}

public Action Cmd_NukeReload(int client, int args)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		Limit[client] = 0;
		PrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
	}
}
public Action Cmd_Nuke(int client, int args)
{
	if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2))
	{
		PrintToChat(client, "\x04[\x03NM\x04] \x05only \x03survivor \x01can use this \x04command \x01!");

		return Plugin_Handled;
	}
	
	int NukeLimit = GetConVarInt(g_hNukeLimit);
	if(!isLaunch[client])
	{
		Time = GetConVarInt(g_hNukeTime);
		if (HandleTimer == null)
		{
			HandleTimer = CreateTimer(1.0, TacticalNuke, client, TIMER_REPEAT); //do not change the time value
		}
		isLaunch[client] = true;
		Limit[client] += 1;
		PrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 %d \x01/ \x03%d", Limit[client], NukeLimit);
	}
	else
	{
		PrintToChat(client, "\x04[\x03NM\x04]\x01Have you ever called a nuclear missile");
	}
	
	return Plugin_Handled;
}

public Action TacticalNuke(Handle timer, int client)
{
	if (HandleTimer == null)
	{
		return Plugin_Stop;
	}
	
	if(Time == 0)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			NukeMissile(client);
		}
		
		if (HandleTimer != null)
		{
			KillTimer(HandleTimer);
			HandleTimer = null;
		}
		
		isLaunch[client] = false;
	}
	else if(Time > 0)
	{
		Time -= 1;
		PrintHintTextToAll("[NM]\nA NUCLEAR MISSILE IS COMING\n TIME -> %d <-", Time);
		for(int i = 1; i <= MaxClients; i++)
		{
		    if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
			{
				EmitSoundToClient(i, COUNT_SOUND);
			}
		}
	}
	
	return Plugin_Continue;
}

void NukeMissile( int client )
{
	float vAng[3];
	float vPos[3];
	
	GetClientEyePosition( client,vPos );
	GetClientEyeAngles( client, vAng );
	Handle hTrace = TR_TraceRayFilterEx( vPos, vAng, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer );
	
	if ( TR_DidHit( hTrace ) )
	{
		float vBuffer[3];
		float vStart[3];
		float vDistance = -35.0;
		
		TR_GetEndPosition( vStart, hTrace );
		GetVectorDistance( vPos, vStart, false );
		GetAngleVectors( vAng, vBuffer, NULL_VECTOR, NULL_VECTOR );
		
		vPos[0] = vStart[0] + ( vBuffer[0] * vDistance );
		vPos[1] = vStart[1] + ( vBuffer[1] * vDistance );
		vPos[2] = vStart[2] + ( vBuffer[2] * vDistance );
		
		float ClientPos[3];
		float bfAng[3];
		float bfVol[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", ClientPos );
		GetEntPropVector( client, Prop_Data, "m_angRotation", bfAng );
		
		ClientPos[2] += 800;
	
		int body = CreateEntityByName( "molotov_projectile" );
		if( body != -1 )
		{
			DispatchKeyValue( body, "model", MOLO );
			DispatchKeyValueVector( body, "origin", ClientPos );
			DispatchKeyValueVector( body, "Angles", bfAng );
			SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.00001 );
			SetEntityGravity( body, 0.001 );
			SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", client );
			DispatchSpawn( body );
		}
	
		int exau = CreateExaust( body, 90 );
		int atth = CreateAttachment( body, amg65, 0.6, 5.0 );

		Rocketparts[body][0] = exau;
		Rocketparts[body][1] = atth;
	
		SDKHook( body, SDKHook_StartTouch, OnNukeCollide );
	
		ClientPos[0] += GetRandomFloat( -20.0, 20.0 );
		ClientPos[1] += GetRandomFloat( -20.0, 20.0 );
		ClientPos[2] += GetRandomFloat( -10.0, 5.0 );
		
		MakeVectorFromPoints( ClientPos, vPos, bfVol );
		NormalizeVector( bfVol, bfVol );
		GetVectorAngles( bfVol, bfAng );
		ProjectileVelo = GetConVarFloat(g_hNukeVelocity);
		ScaleVector( bfVol, ProjectileVelo );
		TeleportEntity( body, NULL_VECTOR, bfAng, bfVol );
		
	}
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i, NUKE_LAUNCH);
		}
	}
	delete hTrace;
}

public Action OnNukeCollide( int ent, int target )
{
	int part1 = Rocketparts[ent][1];
	int part0 = Rocketparts[ent][0];
	Rocketparts[ent][1] = -1;
	Rocketparts[ent][0] = -1;
	
	NukeExplosion( ent );
	DoNukeDamage( ent );

	SDKUnhook( ent, SDKHook_TouchPost, OnNukeCollide );
	if ( IsValidEntity( part1 )) AcceptEntityInput( part1, "kill" );
	if ( IsValidEntity( part0 )) AcceptEntityInput(part0, "kill" );
	if ( IsValidEntity( ent )) AcceptEntityInput( ent, "kill" );
}

void NukeExplosion( int entity )
{
	float vPos[3];
	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", vPos );
	
	int particle = CreateEntityByName("info_particle_system");
	if( particle != -1 )
	{
		DispatchKeyValue(particle, "effect_name", NUKE_EXPLOSION);
		
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::45.0:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1"); 
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
		{
			EmitSoundToClient(i, NUKE_SOUND);
		}
	}
}

void DoNukeDamage( int entity )
{
	int count, client, attacker ;
	float MissilePos[3];
	float InfPos[3];
	char tName[24];
	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", MissilePos );
	count = GetEntityCount();
	client = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" );
	if ( IsValidClient( client )) attacker = client;
	else attacker = entity;
	NukeRadius = GetConVarFloat(g_hNukeRadius);
	NukeDamage = GetConVarFloat(g_hNukeDamage);
	for ( int i=1; i<=MaxClients; i++ )
	{
		if ( !IsValidEntity( i )) continue;
		
		if ( IsValidClient( i ) && GetClientTeam( i ) == 3 )
		{
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", InfPos );
			if ( GetVectorDistance( MissilePos, InfPos ) <= NukeRadius )
			{
				MakeDamage( attacker, NukeDamage, i );
				Fade(i, 255, 30, 0, 80, 2000, 1);
				Shake(i, 100.0);
				IgniteEntity(i, 100.0);
			}
		}
	}
	for( int ent = 1; ent <= count; ent++ )
	{
		if ( !IsValidEntity( ent )) continue;
		
		GetEntityClassname( ent, tName, sizeof( tName ));
		if ( StrContains( tName, "infected", false) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", InfPos );
			if ( GetVectorDistance( MissilePos, InfPos ) <= NukeRadius )
			{
				IgniteEntity(ent, 100.0);
			}
		}
		else if ( StrContains( tName, "witch", false) != -1 )
		{
			GetEntPropVector( ent, Prop_Send, "m_vecOrigin", InfPos );
			if ( GetVectorDistance( MissilePos, InfPos ) <= NukeRadius )
			{
				MakeDamage( attacker, NukeDamage, ent );
				IgniteEntity(ent, 100.0);
			}
		}
	}
	for( int s = 1; s <= MaxClients; s++ )
	{
		if ( !IsValidEntity( s )) continue;
		
		if(IsValidClient(s) && GetClientTeam(s) == 2)
		{
			GetEntPropVector( s, Prop_Send, "m_vecOrigin", InfPos );
			if ( GetVectorDistance( MissilePos, InfPos ) <= NukeRadius )
			{
				Fade(s, 255, 30, 0, 80, 2000, 1);
				Shake(s, 100.0);
			}
		}
	}
}

int CreateExaust( int ent, int length )
{ 
	float flmOri[3] = { 0.0, 0.0, 0.0 };
	float flmAng[3] = { 0.0, 180.0, 0.0 };
	char exaustName[128];
	Format( exaustName, sizeof( exaustName ), "target%d", ent );
	
	int exaust = CreateEntityByName( "env_steam" );
	if ( exaust != -1 )
	{
		char lg[32];
		Format( lg, sizeof( lg ), "%d.0", length );
		DispatchKeyValue( ent, "targetname", exaustName );
		DispatchKeyValue( exaust, "SpawnFlags", "1" );
		DispatchKeyValue( exaust, "Type", "0" );
		DispatchKeyValue( exaust, "InitialState", "1" );
		DispatchKeyValue( exaust, "Spreadspeed", "10" );
		DispatchKeyValue( exaust, "Speed", "200" );
		DispatchKeyValue( exaust, "Startsize", "10" );
		DispatchKeyValue( exaust, "EndSize", "30" );
		DispatchKeyValue( exaust, "Rate", "555" );
		DispatchKeyValue( exaust, "RenderColor", "255 100 0");
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

int CreateAttachment( int ent, char[] Model, float ScaleSize, float fwdPos )
{
	float athPos[3];
	float athAng[3];
	float caPos[3] = { 0.0, 0.0, 0.0 };
	GetEntPropVector( ent, Prop_Send, "m_vecOrigin", athPos );
	GetEntPropVector( ent, Prop_Data, "m_angRotation", athAng );
	int attch = CreateEntityByName( "prop_dynamic_override" );
	if( attch != -1 )
	{
		caPos[1] = fwdPos;
		char namE[20];
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

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
	return ( entity > MaxClients || !entity );
}

void MakeDamage( int attacker, float damage, int victim )
{
	if( victim > 0 && attacker > 0 )
	{
		char dmg_str[16];
		FloatToString( damage, dmg_str, sizeof( dmg_str ));
		int pointHurt = CreateEntityByName( "point_hurt" );
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

public int Fade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public void Shake(int target, float intensity)
{
	Handle msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
	BfWriteFloat(msg, intensity);
	BfWriteFloat(msg, 10.0);
	BfWriteFloat(msg, 3.0);
	EndMessage();
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

stock bool IsValidClient(int client) 
{
	return ((1 <= client <= MaxClients) && IsClientInGame(client));
}

stock bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}