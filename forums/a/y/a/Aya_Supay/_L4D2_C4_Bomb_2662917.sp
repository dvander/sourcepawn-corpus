#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

int g_HaloSprite;
int g_BeamSprite;
Handle sdkc4Bomb = null, g_hGamedata = null;
ConVar l4d2_c4Bomb;
int g_cvarRadius = 350; 
int g_cvarPower = 60; 
int g_cvarDuration = 15;
bool g_bRing = true;
bool g_bStrike2 = false;

static char gStringTable[4][] =
{
	"FluidExplosion_fps",
	"weapon_grenade_explosion",
	"explosion_huge_b",
	"fire_small_01"
};

static char gSounds[4][] =
{
	"ambient/explosions/explode_1.wav",
	"ambient/explosions/explode_2.wav",
	"buttons/blip1.wav",
	"ui/bigreward.wav"
};

public Plugin myinfo =
{
	name = "[L4D2]C4 Bomb",
	author = "JOSHE GATITO SPARTANSKII >>>",
	description = "https://drive.google.com/file/d/1ueirtkxcD3g1CxU-GbRSgLhgzkyuEQLh/view",
	version = "1.0",
	url = "https://github.com/JosheGatitoSpartankii09"
};

public void OnPluginStart()
{
	g_hGamedata = LoadGameConfigFile("C4_Bomb");
	if(g_hGamedata == null)
	{
		SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGamedata, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkc4Bomb = EndPrepSDKCall();
	if (sdkc4Bomb == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}

	l4d2_c4Bomb = CreateConVar("l4d2_c4Bomb", "50", "chance C4 BOMB", FCVAR_NONE);
	
	HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
}

public void OnMapStart()
{
	for(int i = 0; i < 4; i++)
		PrecacheParticle(gStringTable[i]);
	for(int i = 0; i < 4; i++)
		PrecacheSound(gSounds[i], true);
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
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

public Action Event_UpgradePackUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int upgradeid = event.GetInt("upgradeid");
	if (!IsValidEnt(upgradeid))
	{
		return Plugin_Continue;
	}

	float position[3];
	GetEntPropVector(upgradeid, Prop_Send, "m_vecOrigin", position);

	if(GetRandomInt(1, 100) <= l4d2_c4Bomb.IntValue)	
	{
		TimerBaliza(client);
		RemoveEdict(upgradeid);
	}

	return Plugin_Continue;
}

public void TimerBaliza(int client)
{
	g_bRing = true;
	CreateTimer(0.2, timerRing, client, TIMER_REPEAT);
	CreateTimer(9.0, timerRingTimeout);	
	CreateTimer(7.0, timerStartStrike, client);
}

public Action timerStartStrike(Handle timer, any client)
{
	Airstrike2(client);
	return Plugin_Continue;
}

public Action timerRing(Handle timer, any client)
{
	if(!g_bRing)
	{
		return Plugin_Stop;
	}
	CreateRingEffect(client);
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	EmitAmbientSound("buttons/blip1.wav", vec, client, SNDLEVEL_RAIDSIREN);	
	return Plugin_Continue;
}

public Action timerRingTimeout(Handle timer)
{
	g_bRing = false;
}

void Airstrike2(int client)
{
	g_bStrike2 = true;
	CreateTimer(1.7, timerStrike2, client, TIMER_REPEAT);
	CreateTimer(8.8, timerStrikeTimeout2);
}

public Action timerStrikeTimeout2(Handle timer)
{
	g_bStrike2 = false;
}

public Action timerStrike2(Handle timer, any client)
{
	if(!g_bStrike2)
	{
		return Plugin_Stop;
	}
	
	if(!IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	float position[3];
	GetClientAbsOrigin(client, position);
	float radius = 200.0;
	position[0] += GetRandomFloat(radius*-1, radius);
	position[1] += GetRandomFloat(radius*-1, radius);
	EmitSoundToAll("ambient/explosions/explode_1.wav");
	ChargeCircle(client, position);
	CreateExplosion(position);
	g_bFire(position);
	return Plugin_Continue;
}

public void ChargeCircle(int client, float position[3])
{
	float client_pos[3];
	GetClientEyePosition(client, position);
	/* Emit impact sound */
	EmitAmbientSound("ui/bigreward.wav", position);
	
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		GetClientEyePosition(i, client_pos);
		if(GetVectorDistance(position, client_pos) < 200.0)
		{
			if(GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
			{
				Charge(i);
			}
		}
	}
	
	char mName[64]; 
	float entPos[3];
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", mName, sizeof(mName));
			if(StrContains(mName, "infected") != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", entPos);
				if(GetVectorDistance(position, entPos) < 300.0)
				{
					Charge(i);
				}
			}
		}
	}
}

void Charge(int client)
{
	float tpos[3], spos[3];
	float distance[3], ratio[3], addVel[3], tvec[3];
	GetClientAbsOrigin(client, tpos);
	distance[0] = (spos[0] - tpos[0]);
	distance[1] = (spos[1] - tpos[1]);
	distance[2] = (spos[2] - tpos[2]);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", tvec);
	ratio[0] =  FloatDiv(distance[0], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio x/hypo
	ratio[1] =  FloatDiv(distance[1], SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]));//Ratio y/hypo
	
	addVel[0] = FloatMul(ratio[0]*-1, 500.0);
	addVel[1] = FloatMul(ratio[1]*-1, 500.0);
	addVel[2] = 500.0;
	SDKCall(sdkc4Bomb, client, addVel, 76, client, 7.0);
}

void CreateExplosion(float position[3])
{
	char sRadius[256];
	char sPower[256];
	float flMaxDistance = g_cvarRadius * 1.0;
	float power = g_cvarPower * 1.0;
	float cvarDuration = g_cvarDuration * 1.0;
	IntToString(g_cvarRadius, sRadius, sizeof(sRadius));
	IntToString(g_cvarPower, sPower, sizeof(sPower));
	int exParticle2 = CreateEntityByName("info_particle_system");
	int exParticle3 = CreateEntityByName("info_particle_system");
	int exPhys = CreateEntityByName("env_physexplosion");
	int exParticle = CreateEntityByName("info_particle_system");
	int exEntity = CreateEntityByName("env_explosion");
	
	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", "FluidExplosion_fps");
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, position, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle2, "effect_name", "weapon_grenade_explosion");
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, position, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle3, "effect_name", "explosion_huge_b");
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, position, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", sPower);
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, position, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, position, NULL_VECTOR, NULL_VECTOR);
	
	EmitSoundToAll("ambient/explosions/explode_2.wav", exParticle);
	
	//BOOM!
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	
	Handle pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	CreateTimer(cvarDuration+1.5, timerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	float tpos[3], traceVec[3], resultingFling[3], currentVelVec[3];
	for(int i=1; i<=MaxClients; i++)
	{
		if(i == 0 || !IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		if(GetClientTeam(i) != 2)
		{
			continue;
		}
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", tpos);

		if(GetVectorDistance(position, tpos) <= flMaxDistance)
		{
			MakeVectorFromPoints(position, tpos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			FlingPlayer(i, resultingFling, i);
			
			CreateParticle(i, "fire_small_01", true, 5.0);
		}
	}
}

void CreateParticle(int client, char[] Particle_Name, bool Parent, float duration)
{
	float pos[3];
	char sName[64];
	int Particle = CreateEntityByName("info_particle_system");
	GetClientAbsOrigin(client, pos);
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	if(Parent) 
	{
		int userid = GetClientUserId(client);
		Format(sName, 64, "%d", userid); // verificar
		DispatchKeyValue(client, "targetname", sName);
	}
	DispatchSpawn(Particle);
	if(Parent) 
	{
		SetVariantString(sName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle, 0);
	}
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "Start");
	CreateTimer(duration, timerRemovePrecacheParticle, Particle);
}

public Action timerRemovePrecacheParticle(Handle timer, any Particle)
{
	if(Particle > 0 && IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
	
	return Plugin_Stop;
}

public Action timerDeleteParticles(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	int entity;
	for(int i = 1; i <= 5; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	CloseHandle(pack);
	
	return Plugin_Stop;
}

public void g_bFire(float position[3])
{
	int entity = CreateEntityByName("prop_physics");
	if(!IsValidEntity(entity)) return;
	DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
	DispatchSpawn(entity);
	SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
	TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "break");
}

public void CreateRingEffect(int client)
{ 
	int color[4]; 
	color[0] = GetRandomInt(1, 255); 
	color[1] = GetRandomInt(1, 255); 
	color[2] = GetRandomInt(1, 255); 
	color[3] = 255;

	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	position[2] += 10;
	TE_SetupBeamRingPoint(position, 10.0, 50.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.3, 2.0, 1.5, color, 300, 0);
	TE_SendToAll();
}

stock void FlingPlayer(int target, float vector[3], int attacker, float stunTime = 3.0)
{
	SDKCall(sdkc4Bomb, target, vector, 96, attacker, stunTime);
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}