#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define EXPLOSION_SOUND2 "ambient/explosions/explode_2.wav"
#define EXPLOSION_SOUND3 "ambient/explosions/explode_3.wav"
#define EXPLOSION_DEBRIS "animation/plantation_exlposion.wav"
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "FluidExplosion_fps"
#define EXPLOSION_PARTICLE2 "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3 "explosion_huge_b"

static Handle sdkCallPushPlayer = null;
#define NAME_CallPushPlayer "CTerrorPlayer_Fling"
#define SIG_CallPushPlayer_LINUX "@_ZN13CTerrorPlayer5FlingERK6Vector17PlayerAnimEvent_tP20CBaseCombatCharacterf"
#define SIG_CallPushPlayer_WINDOWS "\x2A\x2A\x2A\x2A\x2A\x2A\x83\xE4\x2A\x83\xC4\x2A\x55\x8B\x6B\x2A\x89\x6C\x2A\x2A\x8B\xEC\x81\x2A\x2A\x2A\x2A\x2A\xA1\x2A\x2A\x2A\x2A\x33\xC5\x89\x45\x2A\x8B\x43\x2A\x56\x8B\x73\x2A\x57\x6A\x2A\x8B\xF9\x89\x45"

public void OnPluginStart()
{
    RegConsoleCmd("sm_explosion", CreateExplosion_Cmd);
}

public void OnMapStart()
{
	PrecacheSound(EXPLOSION_SOUND);
	PrecacheSound(EXPLOSION_SOUND2);
	PrecacheSound(EXPLOSION_SOUND3);
	PrecacheSound(EXPLOSION_DEBRIS);
}

Action CreateExplosion_Cmd(int client, int args)
{
    if(client > 0)
    {
        float pos[3];
        GetClientAbsOrigin(client, pos);
        CreateExplosion(pos);
    }
    return Plugin_Handled;
}

void CreateExplosion(float carPos[3])
{
	static char sRadius[64], sPower[64];
	float flMxDistance = 350.0, power = 350.0, g_fDuration = 15.0;
	IntToString(RoundToNearest(flMxDistance), sRadius, sizeof(sRadius));
	IntToString(RoundToNearest(power), sPower, sizeof(sPower));
	int exParticle2 = CreateEntityByName("info_particle_system");
	int exParticle3 = CreateEntityByName("info_particle_system");
	int exTrace = CreateEntityByName("info_particle_system");
	int exPhys = CreateEntityByName("env_physexplosion");
	int exHurt = CreateEntityByName("point_hurt");
	int exParticle = CreateEntityByName("info_particle_system");
	int exEntity = CreateEntityByName("env_explosion");

	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, carPos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, carPos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, carPos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
	DispatchSpawn(exTrace);
	ActivateEntity(exTrace);
	TeleportEntity(exTrace, carPos, NULL_VECTOR, NULL_VECTOR);

	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", sPower);
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, carPos, NULL_VECTOR, NULL_VECTOR);

	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, carPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", "0.5");
	DispatchKeyValue(exHurt, "Damage", "5");
	DispatchKeyValue(exHurt, "DamageType", "8");
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, carPos, NULL_VECTOR, NULL_VECTOR);
	
	switch (GetRandomInt(1,3))
	{
		case 1:
		{
			EmitAmbientGenericSound(carPos, EXPLOSION_SOUND);
		}
		case 2:
		{
			EmitAmbientGenericSound(carPos, EXPLOSION_SOUND2);
		}
		case 3:
		{
			EmitAmbientGenericSound(carPos, EXPLOSION_SOUND3);
		}
	}

	EmitAmbientGenericSound(carPos, EXPLOSION_DEBRIS);
	
	//BOOM!
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	static char temp_str[64];
	Format(temp_str, sizeof(temp_str), "OnUser1 !self:Kill::%f:1", g_fDuration + 1.5);
	
	SetVariantString(temp_str);
	AcceptEntityInput(exParticle, "AddOutput");
	AcceptEntityInput(exParticle, "FireUser1");
	SetVariantString(temp_str);
	AcceptEntityInput(exParticle2, "AddOutput");
	AcceptEntityInput(exParticle2, "FireUser1");
	SetVariantString(temp_str);
	AcceptEntityInput(exParticle3, "AddOutput");
	AcceptEntityInput(exParticle3, "FireUser1");
	SetVariantString(temp_str);
	AcceptEntityInput(exEntity, "AddOutput");
	AcceptEntityInput(exEntity, "FireUser1");
	SetVariantString(temp_str);
	AcceptEntityInput(exPhys, "AddOutput");
	AcceptEntityInput(exPhys, "FireUser1");
	SetVariantString(temp_str);
	AcceptEntityInput(exTrace, "AddOutput");
	SetVariantString(temp_str);
	AcceptEntityInput(exHurt, "AddOutput");
	
	Format(temp_str, sizeof(temp_str), "OnUser1 !self:Stop::%f:1", g_fDuration);
	SetVariantString(temp_str);
	AcceptEntityInput(exTrace, "AddOutput");
	AcceptEntityInput(exTrace, "FireUser1");
	
	Format(temp_str, sizeof(temp_str), "OnUser1 !self:TurnOff::%f:1", g_fDuration);
	SetVariantString(temp_str);
	AcceptEntityInput(exHurt, "AddOutput");
	AcceptEntityInput(exHurt, "FireUser1");
	
	float survivorPos[3], traceVec[3], resultingFling[3], currentVelVec[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
		{
			continue;
		}

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		//Vector and radius distance calcs by AtomicStryker!
		if (GetVectorDistance(carPos, survivorPos) <= flMxDistance)
		{
			MakeVectorFromPoints(carPos, survivorPos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			FlingPlayer(i, resultingFling, i);
		}
	}
}

void EmitAmbientGenericSound(float pos[3], const char[] snd_str)
{
	int snd_ent = CreateEntityByName("ambient_generic");
	
	TeleportEntity(snd_ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(snd_ent, "message", snd_str);
	DispatchKeyValue(snd_ent, "health", "10");
	DispatchKeyValue(snd_ent, "spawnflags", "48");
	DispatchSpawn(snd_ent);
	ActivateEntity(snd_ent);
	
	AcceptEntityInput(snd_ent, "PlaySound");
	
	AcceptEntityInput(snd_ent, "Kill");
}

void FlingPlayer(int client, float vector[3], int attacker, float stunTime = 3.0)
{
	if (sdkCallPushPlayer == null)
	{
		PrintToServer("Fling signature is broken!");
		return;
	}
	SDKCall(sdkCallPushPlayer, client, vector, 76, attacker, stunTime);
}
