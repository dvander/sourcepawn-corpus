#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MODEL_CONCRETE_CHUNK         "models/props_debris/concrete_chunk01a.mdl"
#define SOUND_IMPACT		"physics/concrete/boulder_impact_hard4.wav"

#define EXPLOSION_PARTICLE "gas_explosion_initialburst_smoke"
#define EXPLOSION_PARTICLE2 "gas_explosion_chunks_02"
#define EXPLOSION_PARTICLE3 "weapon_grenade_explosion"

Handle:MySDKCall = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Meteor Hunter",
	author = "Spirit",
	description = "high pounces cause meteor strike",
	version = "1.0",
	url = ""
}
public OnPluginStart( )
{
	HookEvent("lunge_pounce", Event_LandedPounce);
	RegAdminCmd("sm_testhit", TestHit, ADMFLAG_GENERIC, "spawn test HIt");
	
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer5FlingERK6Vector17PlayerAnimEvent_tP20CBaseCombatCharacterf", 0))
	{
		PrepSDKCall_SetSignature(SDKLibrary_Server, "\x53\x8B\xDC\x83\xEC\x2A\x83\xE4\x2A\x83\xC4\x2A\x55\x8B\x6B\x2A\x89\x6C\x2A\x2A\x8B\xEC\x81\x2A\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x33\xC5\x89\x45\x2A\x8B\x43\x2A\x56\x8B\x73\x2A\x57\x6A\x2A\x8B\xF9\x89\x45", 0);
	}

	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	MySDKCall = EndPrepSDKCall();
	if(MySDKCall == INVALID_HANDLE)
	{
		LogError("Could not prep the Fling function");
	}
	
	//SDKCall(MySDKCall, target, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2

}
public OnMapStart()
{
	PrecacheSound(SOUND_IMPACT);
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
}
CreateHit(Float:pos[3])
{	
	EmitSoundToAll(SOUND_IMPACT, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,pos, NULL_VECTOR,true, 0.0);
	pos[2] -= 20.0;
	
	CreateParticles(pos);
	
	new Handle:haPack = CreateDataPack();
	WritePackFloat(haPack, 50.0)
	WritePackFloat(haPack, pos[0]);
	WritePackFloat(haPack, pos[1]);
	WritePackFloat(haPack, pos[2]);
	
	CreateTimer(0.1,CreateRing,haPack,TIMER_FLAG_NO_MAPCHANGE);
	
	new Handle:hbPack = CreateDataPack();
	WritePackFloat(hbPack, 100.0)
	WritePackFloat(hbPack, pos[0]);
	WritePackFloat(hbPack, pos[1]);
	WritePackFloat(hbPack, pos[2]);
	CreateTimer(0.3,CreateRing,hbPack,TIMER_FLAG_NO_MAPCHANGE);
	
	new Handle:hPack = CreateDataPack();
	WritePackFloat(hPack, 150.0)
	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	CreateTimer(0.6,CreateRing,hPack,TIMER_FLAG_NO_MAPCHANGE);

}

CreateParticles(Float:pos[3])
{
	new exParticle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(exParticle, "Start");
	CreateTimer(3.0, TimerDeleteRock, exParticle, TIMER_FLAG_NO_MAPCHANGE);
		
	new exParticle2 = CreateEntityByName("info_particle_system");
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(exParticle2, "Start");
	CreateTimer(3.0, TimerDeleteRock, exParticle2, TIMER_FLAG_NO_MAPCHANGE);
	
	new exParticle3 = CreateEntityByName("info_particle_system");
	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(exParticle3, "Start");
	CreateTimer(3.0, TimerDeleteRock, exParticle3, TIMER_FLAG_NO_MAPCHANGE);
}	
public Action:CreateRing(Handle:hTimer,Handle:hPack)
{
	new Float:nPos[3];
	new Float:rad;
	
	ResetPack(hPack);
	rad = ReadPackFloat(hPack);
	nPos[0] = ReadPackFloat(hPack);
	nPos[1] = ReadPackFloat(hPack);
	nPos[2] = ReadPackFloat(hPack);

	CloseHandle(hPack);
	
	new Float:direction[3];
	new Float:Ang[3];
	new Float:rockpos[3];	
	
	for (new i = 1; i <= 36; i++)//for each client
	{
		Ang[1] = Ang[1]+(i*10);

		GetAngleVectors(Ang, direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(direction, rad);
		AddVectors(nPos, direction, rockpos);
		CreateRock(rockpos)
	}
}

CreateRock(Float:Rpos[3])
{
	new rock;
	rock = CreateEntityByName ( "prop_dynamic"); 
	SetEntityModel (rock,MODEL_CONCRETE_CHUNK);
	DispatchSpawn(rock);
	new Float:ang[3];
	ang[0] = float(GetRandomInt(0,360));
	ang[1] = float(GetRandomInt(0,360));
	ang[2] = float(GetRandomInt(0,360));
	TeleportEntity(rock, Rpos, ang, NULL_VECTOR);
	CreateTimer(5.0, TimerDeleteRock, rock, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerDeleteRock(Handle:hTimer, any:TmpEnt)
{	
	AcceptEntityInput(TmpEnt, "Kill");
}

public Action:TestHit(client, args)
{
	decl Float:vPos[3];
	decl Float:vAng[3];
	decl Float:nPos[3];
	
	GetClientEyePosition(client,vPos);
	GetClientEyeAngles(client,vAng);
	
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(nPos, trace);
		CreateHit(nPos);
		CreateForces(client);
	}
	CloseHandle(trace);
}

FlingPlayer(target,hitter)
{
	if(IsStanding(target))
	{	
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:power = 200.0;
		GetClientEyeAngles(hitter, HeadingVector);
	
		AimVector[0] =  Cosine( DegToRad(HeadingVector[1])  )* power;
		AimVector[1] =  Sine( DegToRad(HeadingVector[1])  ) * power;
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = current[0] + AimVector[0];	
		resulting[1] = current[1] + AimVector[1];
		resulting[2] = power * 1.5;
		
		SDKCall(MySDKCall, target, resulting, 76, hitter, 3.0);
		//L4D2_Fling(target, resulting, hitter);
	}
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )return false;
	return true;
}
stock bool:IsHunter(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3) return true;
    return false;
}
bool:IsStanding(client)
{
	if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge")||GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		return false;
	}
	return true;
}
public Event_LandedPounce(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new Float:distance = GetEventFloat(hEvent,"distance")
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		if(distance >500)
		{
			new Float:Ppos[3];
			GetClientAbsOrigin(client,Ppos);
			CreateHit(Ppos);
			CreateForces(client)
		}
		//PrintToChatAll("hunter pounce distance = %f", distance);
	}
}
CreateForces(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);

	for (new i = 1; i <= MaxClients; i++)//for each client
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
		{
			decl Float:tpos[3];
			GetClientAbsOrigin(i, tpos);
			
			new Float:dist = GetVectorDistance(pos, tpos);
			if (  dist < 300 )
			{
				FlingPlayer(i,client);
				HurtEntity(i, client, 20.0, 0);
			}
		}
	}
}

stock PrecacheParticle(const String:ParticleName[])
{
	new Particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, TimerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TimerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if (IsValidEdict(Particle))
		AcceptEntityInput(Particle, "Kill");
}

stock HurtEntity(client, attacker, Float:amount, type)
{
	new damage = RoundFloat(amount);
	if (IsValidEntity(client))
	{
		decl String:sUser[256], String:sDamage[11], String:sType[11];
		IntToString(client+25, sUser, sizeof(sUser));
		IntToString(damage, sDamage, sizeof(sDamage));
		IntToString(type, sType, sizeof(sType));
		new iDmgEntity = CreateEntityByName("point_hurt");
		if (IsValidEntity(iDmgEntity))
		{
			DispatchKeyValue(client, "targetname", sUser);
			DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
			DispatchKeyValue(iDmgEntity, "Damage", sDamage);
			DispatchKeyValue(iDmgEntity, "DamageType", sType);
			DispatchSpawn(iDmgEntity);

			AcceptEntityInput(iDmgEntity, "Hurt", attacker);
			AcceptEntityInput(iDmgEntity, "Kill");
		}
	}
}
