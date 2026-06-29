/**
 * vim: set ts=4 :
 * =============================================================================
 * Talents Plugin by Neil
 * Incorporates Survivor classes.
 *
 * (C)2013 DeadLandRape / Neil.  All rights reserved.
 * (C)2021 Silvers.  Various fixes (client userIDs and entity references when used in timers).
 * =============================================================================
 *
 *	Developed for DeadLandRape Gaming. This plugin is DLR proprietary software.
 *	DLR claims complete rights to this plugin, including, but not limited to:
 *
 *		- The right to use this plugin in their servers
 *		- The right to modify this plugin
 *		- The right to claim ownership of this plugin
 *		- The right to re-distribute this plugin as they see fit
 */
 
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CONFIGURABLE VARIABLES
 * Feel free to change the following code-related values.
 */


/// MENU AND UI RELATED STUFF

// This is what to display on the class selection menu.
static const String:MENU_OPTIONS[][] =
{
	// What should be displayed if the player does not have a class?
	"None",
	
	// You can change how the menus display here.
	"Soldier",
	"Athlete",
	"Medic",
	"Saboteur",
	"Commando",
	"Engineer",
	"Brawler"
};

static const String:ClassTips[][] =
{
	", Is a noob who didnt pick a class.",
	", He can shoot fast.",
	", He Can Jump high.",
	", He can heal his team by crouching.",
	", He is invisible while hes crouched.",
	", He does loads of damage.",
	", He can drop auto turrets.",
	", He has lots of health."
};

// How long should the Class Select menu stay open?
new MENU_OPEN_TIME = 99999;

// What formatting string to use when printing to the chatbox
#define PRINT_PREFIX 	"\x05[DLR] \x01"


/// SOUNDS AND OTHER
/// PRECACHE DATA

#define SOUND_CLASS_SELECTED "ui/pickup_misc42.wav" /**< What sound to play when a class is selected. Do not include "sounds/" prefix. */
#define SOUND_DROP_BOMB "ui/beep22.wav"
#define AMMO_PILE "models/props/terror/ammo_stack.mdl"

/**
 * OTHER GLOBAL VARIABLES
 * Do not change these unless you know what you are doing.
 */

enum CLASSES {
	NONE = 0,
	SOLDIER,
	ATHLETE,
	MEDIC,
	SABOTEUR,
	SNIPER,
	ENGINEER,
	BRAWLER,
	MAXCLASSES
};

enum PLAYERDATA {
	BombsUsed,
	ItemsBuilt,
	Float:HideStartTime,
	LastButtons,
	ChosenClass,
	Float:LastDropTime,
	String:EquipedGun[64]
};

// Stores client plugin data
new ClientData[MAXPLAYERS+1][PLAYERDATA];

// Rapid fire variables
new g_iRI[MAXPLAYERS+1] = { -1 },
	g_iRC, g_iEi[MAXPLAYERS+1] = { -1 },
	Float:g_fNT[MAXPLAYERS+1] = { -1.0 },
	g_iNPA = -1,
	g_oAW = -1;

// Speed vars
new g_ioLMV;

// Sniper vars
new g_ioPR = -1;
new g_ioNA = -1;
new g_ioTI = -1;
new g_iSSD = -1;
new g_iSID = -1;
new g_iSED = -1;
new g_iSRS = -1;

// Enums (doc'd by SMLib)
enum Water_Level
{
	WATER_LEVEL_NOT_IN_WATER = 0,
	WATER_LEVEL_FEET_IN_WATER,
	WATER_LEVEL_WAIST_IN_WATER,
	WATER_LEVEL_HEAD_IN_WATER
};

// Bomb related stuff
new g_BeamSprite = -1, g_HaloSprite = -1;
new redColor[4]		= {255, 75, 75, 255};
new greenColor[4]	= {75, 255, 75, 255};
new RndSession;

#define PUNCH_SOUND "melee_tonfa_02.wav"
#define EXPLOSION_SOUND "weapons/hegrenade/explode5.wav"
#define EXPLOSION_SOUND2 "weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define EXPLOSION_SOUND3 "ambient/explosions/explode_3.wav"
#define EXPLOSION_PARTICLE "gas_explosion_main_fallback"
#define EXPLOSION_PARTICLE2 "weapon_grenade_explosion"
#define EXPLOSION_PARTICLE3 "explosion_huge_b"
#define EFIRE_PARTICLE "gas_explosion_ground_fire"
#define MEDIC_GLOW "fire_medium_01_glow"
#define ENGINEER_MACHINE_GUN "models/w_models/weapons/50cal.mdl"

// Convars (change these via the created cfg files)

/// CLASS RELATED STUFF

// new g_CollisionOffset;

// Max classes
ConVar MAX_SOLDIER;
ConVar MAX_ATHLETE;
ConVar MAX_MEDIC;
ConVar MAX_SABOTEUR;
ConVar MAX_SNIPER;
ConVar MAX_ENGINEER;
ConVar MAX_BRAWLER;

// Everyone
ConVar SOLDIER_HEALTH;
ConVar ATHLETE_HEALTH;
ConVar MEDIC_HEALTH;
ConVar SABOTEUR_HEALTH;
ConVar SNIPER_HEALTH;
ConVar ENGINEER_HEALTH;
ConVar BRAWLER_HEALTH;

// Soldier
ConVar SOLDIER_FIRE_RATE;

// Athlete
//new Handle:ATHLETE_SPEED;
ConVar ATHLETE_JUMP_VEL;

// Medic
ConVar MEDIC_HEAL_DIST;
ConVar MEDIC_HEALTH_VALUE;
ConVar MEDIC_MAX_DEFIBS;
ConVar MEDIC_HEALTH_INTERVAL;

// Saboteur
ConVar SABOTEUR_INVISIBLE_TIME;
ConVar SABOTEUR_BOMB_ACTIVATE;
ConVar SABOTEUR_BOMB_RADIUS;
ConVar SABOTEUR_MAX_BOMBS;
ConVar SABOTEUR_BOMB_DAMAGE_SURV;
ConVar SABOTEUR_BOMB_DAMAGE_INF;
ConVar SABOTEUR_BOMB_POWER;

// Sniper
// new Handle:SNIPER_DAMAGE;
ConVar SNIPER_RELOAD_RATIO;

// Engineer
ConVar ENGINEER_MAX_BUILDS;
ConVar MAX_ENGINEER_BUILD_RANGE;

// Saboteur, Engineer, Medic
ConVar MINIMUM_DROP_INTERVAL;

// Saferoom checks for saboteur
new bool:g_bInSaferoom[MAXPLAYERS+1] = false;
new Float:g_SpawnPos[MAXPLAYERS+1][3];

// Last class taken
new LastClassConfirmed[MAXPLAYERS+1];

new bool:RoundStarted =false;

/**
 * STOCK FUNCTIONS
 */

stock GetClientTempHealth(client)
{
	if (!client
			|| !IsValidEntity(client)
			|| !IsClientInGame(client)
			|| !IsPlayerAlive(client)
			|| IsClientObserver(client)
			|| GetClientTeam(client) != 2)
	{
		return -1;
	}
	
	new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	
	new Float:TempHealth;
	
	if (buffer <= 0.0)
		TempHealth = 0.0;
	else
	{
		new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		new Float:decay = FindConVar("pain_pills_decay_rate").FloatValue;
		new Float:constant = 1.0/decay;
		TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	TempHealth = 0.0;
	
	return RoundToFloor(TempHealth);
}

stock SetClientTempHealth(client, iValue)
{
	if (!client
			|| !IsValidEntity(client)
			|| !IsClientInGame(client)
			|| !IsPlayerAlive(client)
			|| IsClientObserver(client)
			|| GetClientTeam(client) != 2)
	return;
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	
	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteCell(iValue);
	
	CreateTimer(0.1, TimerSetClientTempHealth, hPack, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerSetClientTempHealth(Handle:hTimer, DataPack hPack)
{
	hPack.Reset();
	new client = hPack.ReadCell();
	new iValue = hPack.ReadCell();
	delete hPack;
	
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return;
	
	if(
	   !IsPlayerAlive(client)
    || IsClientObserver(client)
	|| GetClientTeam(client) != 2)
        return;
    
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", iValue*1.0);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock PushEntity(client, Float:clientEyeAngle[3], Float:power)
{
	decl Float:forwardVector[3], Float:newVel[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", newVel);
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	AddVectors(forwardVector, newVel, newVel);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, newVel);
}

stock Water_Level:GetClientWaterLevel(client)
{	
	return Water_Level:GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

stock bool:IsClientOnLadder(client)
{	
	new MoveType:movetype = GetEntityMoveType(client);
	
	if (movetype == MOVETYPE_LADDER)
		return true;
	
	return false;
}

stock DetonateMolotov(Float:pos[3], owner)
{
	pos[2]+=5.0;
	static Handle:sdkDetonateFire;
	if( sdkDetonateFire == null )
	{
		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x8B\x44**\x8B\x4C**\x53\x56\x57\x8B\x7C**\x57\x50\x51\x68****\xE8****\x8B\x5C**\xD9**\x83\xEC*\xDD***\x8B\xF0\xD9**\x8B\x44**\xDD***\xD9*\xDD***\xD9**\xDD***\xD9**\xDD***\xD9*\xDD**\x68****", 85))
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN18CMolotovProjectile6CreateERK6VectorRK6QAngleS2_S2_P20CBaseCombatCharacter", 0);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		sdkDetonateFire = EndPrepSDKCall();
		if(sdkDetonateFire == INVALID_HANDLE)
		{
			LogError("Invalid Function Call at DetonateMolotov()");
			return;
		}
	}

	if( sdkDetonateFire )
	{
		new Float:vec[3];
		SDKCall(sdkDetonateFire, pos, vec, vec, vec, owner);
		delete sdkDetonateFire;
	}
}

stock DealDamage(iVictim, iAttacker, Float:flAmount, iType = 0)
{
	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(iVictim));
	hPack.WriteCell(GetClientUserId(iAttacker));
	hPack.WriteFloat(flAmount);
	hPack.WriteCell(iType);
	CreateTimer(0.1, timerHurtEntity, hPack);
}

public Action:timerHurtEntity(Handle:timer, DataPack pack)
{
	pack.Reset();
	new client = pack.ReadCell();
	new attacker = pack.ReadCell();

	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return;
	attacker = GetClientOfUserId(attacker);
	if( !attacker || !IsClientInGame(attacker) ) return;

	new Float:amount = pack.ReadFloat();
	new type = pack.ReadCell();
	delete pack;
	HurtEntity(client, attacker, amount, type);
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
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
		DispatchKeyValue(iDmgEntity, "Damage", sDamage);
		DispatchKeyValue(iDmgEntity, "DamageType", sType);
		DispatchSpawn(iDmgEntity);
		if (IsValidEntity(iDmgEntity))
		{
			AcceptEntityInput(iDmgEntity, "Hurt", attacker);
			AcceptEntityInput(iDmgEntity, "Kill");
		}
	}
}

stock CreateExplosion(Float:expPos[3], attacker = 0, bool:panic = true)
{
	decl String:sRadius[16], String:sPower[16], String:sInterval[11];
	new Float:flMxDistance = 450.0;
	new Float:power = SABOTEUR_BOMB_POWER.FloatValue;
	new iDamageSurv = SABOTEUR_BOMB_DAMAGE_SURV.IntValue;
	new iDamageInf = SABOTEUR_BOMB_DAMAGE_INF.IntValue;
	new Float:flInterval = 0.1;
	FloatToString(flInterval, sInterval, sizeof(sInterval));
	IntToString(450, sRadius, sizeof(sRadius));
	IntToString(800, sPower, sizeof(sPower));
	
	new exParticle2 = CreateEntityByName("info_particle_system");
	new exParticle3 = CreateEntityByName("info_particle_system");
	new exTrace = CreateEntityByName("info_particle_system");
	new exPhys = CreateEntityByName("env_physexplosion");
	new exHurt = CreateEntityByName("point_hurt");
	new exParticle = CreateEntityByName("info_particle_system");
	new exEntity = CreateEntityByName("env_explosion");
	
	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, expPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, expPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, expPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exTrace, "effect_name", EFIRE_PARTICLE);
	DispatchSpawn(exTrace);
	ActivateEntity(exTrace);
	TeleportEntity(exTrace, expPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", "150");
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, expPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", sInterval);
	DispatchKeyValue(exHurt, "Damage", "1");
	DispatchKeyValue(exHurt, "DamageType", "8");
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, expPos, NULL_VECTOR, NULL_VECTOR);
	
	//DetonateMolotov(expPos, attacker);
	
	for(new i = 1; i <= 2; i++)
		//DetonateMolotov(expPos, attacker);
	
	switch(GetRandomInt(1,3))
	{
		case 1:
			EmitSoundToAll(EXPLOSION_SOUND);
		
		case 2:
			EmitSoundToAll(EXPLOSION_SOUND2);
		
		case 3:
			EmitSoundToAll(EXPLOSION_SOUND3);
	}
	
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	DataPack pack2 = new DataPack();
	pack2.WriteCell(EntIndexToEntRef(exParticle));
	pack2.WriteCell(EntIndexToEntRef(exParticle2));
	pack2.WriteCell(EntIndexToEntRef(exParticle3));
	pack2.WriteCell(EntIndexToEntRef(exTrace));
	pack2.WriteCell(EntIndexToEntRef(exEntity));
	pack2.WriteCell(EntIndexToEntRef(exPhys));
	pack2.WriteCell(EntIndexToEntRef(exHurt));
	CreateTimer(6.0, TimerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	DataPack pack = new DataPack();
	pack.WriteCell(EntIndexToEntRef(exTrace));
	pack.WriteCell(EntIndexToEntRef(exHurt));
	CreateTimer(4.5, TimerStopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	decl Float:survivorPos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		if (GetVectorDistance(expPos, survivorPos) <= flMxDistance)
		{
			MakeVectorFromPoints(expPos, survivorPos, traceVec);
			GetVectorAngles(traceVec, resultingFling);
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
			
			if (attacker > 0)
			{
				if (GetClientTeam(i) == 2)
				{
					if( iDamageSurv ) DealDamage(i, attacker, float(iDamageSurv), 8);
				}
				else
				{
					if( iDamageInf ) DealDamage(i, attacker, float(iDamageInf), 8);
				}
			}
		}
	}
	
	decl String:class[32];
	for (new i=MaxClients+1; i<=2048; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_physics") || StrEqual(class, "prop_physics_multiplayer"))
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
				
				//Vector and radius distance calcs by AtomicStryker!
				if (GetVectorDistance(expPos, survivorPos) <= flMxDistance)
				{
					MakeVectorFromPoints(expPos, survivorPos, traceVec);
					GetVectorAngles(traceVec, resultingFling);
					
					resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
					resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
					resultingFling[2] = power;
					
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
					resultingFling[0] += currentVelVec[0];
					resultingFling[1] += currentVelVec[1];
					resultingFling[2] += currentVelVec[2];
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
				}
			}
		}
	}
}

public Action:TimerStopFire(Handle:timer, DataPack pack)
{
	pack.Reset();
	new particle = pack.ReadCell();
	new hurt = pack.ReadCell();
	delete pack;
	
	if(EntRefToEntIndex(particle) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(particle, "Stop");
	}
	
	if(EntRefToEntIndex(hurt) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:TimerDeleteParticles(Handle:timer, DataPack pack)
{
	pack.Reset();
	
	new entity;
	for (new i = 1; i <= 7; i++)
	{
		entity = pack.ReadCell();
		entity = EntRefToEntIndex(entity);
		if( entity == INVALID_ENT_REFERENCE ) continue;

		if(EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	delete pack;
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
		CreateTimer(0.3, TimerRemovePrecacheParticle, EntIndexToEntRef(Particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TimerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if (EntRefToEntIndex(Particle) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(Particle, "Kill");
}

stock CreateParticle(client, String:Particle_Name[], bool:Parent, Float:duration)
{
	decl Float:pos[3], String:sName[64], String:sTargetName[64];
	new Particle = CreateEntityByName("info_particle_system");
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(Particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	
	if (Parent)
	{
		Format(sName, sizeof(sName), "%d", client+25);
		DispatchKeyValue(client, "targetname", sName);
		GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
		
		Format(sTargetName, sizeof(sTargetName), "%d", client+1000);
		DispatchKeyValue(Particle, "targetname", sTargetName);
		DispatchKeyValue(Particle, "parentname", sName);
	}
	
	DispatchSpawn(Particle);
	DispatchSpawn(Particle);
	
	if (Parent)
	{
		SetVariantString(sName);
		AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	}
	
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
	CreateTimer(duration, TimerStopAndRemoveParticle, EntIndexToEntRef(Particle), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerStopAndRemoveParticle(Handle:timer, any:entity)
{
	if (EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost");
}

stock bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock bool:IsHanging(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

stock FindAttacker(iClient)
{
	//Pummel
	new iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker");
	if (iAttacker > 0)
		return iAttacker;
	
	//Pounce
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker");
	if (iAttacker > 0)
		return iAttacker;
	
	//Jockey
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker");
	if (iAttacker > 0)
		return iAttacker;
	
	//Smoker
	iAttacker = GetEntPropEnt(iClient, Prop_Send, "m_tongueOwner");
	if (iAttacker > 0)
		return iAttacker;
	
	iAttacker = 0;
	return iAttacker;
}

stock bool:IsInEndingSaferoom(client)
{
	decl String:class[128], Float:pos[3], Float:dpos[3];
	GetClientAbsOrigin(client, pos);
	for (new i = MaxClients+1; i < 2048; i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_door_rotating_checkpoint"))
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", class, sizeof(class));
				if (StrContains(class, "checkpoint_door_02") != -1)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", dpos);
					if (GetVectorDistance(pos, dpos) <= 600.0)
						return true;
				}
			}
		}
	}
	return false;
}

stock bool:IsPlayerInSaferoom(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	return g_bInSaferoom[client] || GetVectorDistance(g_SpawnPos[client], pos) <= 600.0;
}

/**
 * PLUGIN LOGIC
 */

public OnPluginStart( )
{
	// Offsets
	g_iNPA = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_oAW = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	g_ioLMV = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_ioPR = FindSendPropInfo("CBaseCombatWeapon", "m_flPlaybackRate");
	g_ioNA = FindSendPropInfo("CTerrorPlayer", "m_flNextAttack");
	g_ioTI = FindSendPropInfo("CTerrorGun", "m_flTimeWeaponIdle");
	g_iSSD = FindSendPropInfo("CBaseShotgun", "m_reloadStartDuration");
	g_iSID = FindSendPropInfo("CBaseShotgun", "m_reloadInsertDuration");
	g_iSED = FindSendPropInfo("CBaseShotgun", "m_reloadEndDuration");
	g_iSRS = FindSendPropInfo("CBaseShotgun", "m_reloadState");

	// g_CollisionOffset = FindSendPropInfo( "CBaseEntity", "m_CollisionGroup" );
	
	// Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundChange);
	HookEvent("round_start_post_nav", Event_RoundChange);
	HookEvent("mission_lost", Event_RoundChange);
	HookEvent("weapon_reload", Event_RelSniperClass);
	HookEvent("player_entered_checkpoint", Event_EnterSaferoom);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_left_start_area",Event_LeftStartArea);
	
	HookEvent("weapon_fire", Event_WeaponFire);

	// Concommands
	RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
	RegConsoleCmd("sm_classinfo", CmdClassInfo, "Shows who is what class");
	RegConsoleCmd("sm_classes", CmdClasses, "Shows who is what class");
	
	// Convars
	MAX_SOLDIER = CreateConVar("talents_soldier_max", "1", "Max number of soldiers");
	MAX_ATHLETE = CreateConVar("talents_athelete_max", "1", "Max number of athletes");
	MAX_MEDIC = CreateConVar("talents_medic_max", "1", "Max number of medics");
	MAX_SABOTEUR = CreateConVar("talents_saboteur_max", "1", "Max number of saboteurs");
	MAX_SNIPER = CreateConVar("talents_sniper_max", "1", "Max number of snipers");
	MAX_ENGINEER = CreateConVar("talents_engineer_max", "1", "Max number of engineers");
	MAX_BRAWLER = CreateConVar("talents_brawler_max", "1", "Max number of brawlers");
	
	SOLDIER_HEALTH = CreateConVar("talents_soldier_health", "300", "How much health a soldier should have");
	ATHLETE_HEALTH = CreateConVar("talents_athelete_health", "100", "How much health an athlete should have");
	MEDIC_HEALTH = CreateConVar("talents_medic_health_start", "120", "How much health a medic should have");
	SABOTEUR_HEALTH = CreateConVar("talents_saboteur_health", "140", "How much health a saboteur should have");
	SNIPER_HEALTH = CreateConVar("talents_sniper_health", "300", "How much health a sniper should have");
	ENGINEER_HEALTH = CreateConVar("talents_engineer_health", "125", "How much health a engineer should have");
	BRAWLER_HEALTH = CreateConVar("talents_brawler_health", "500", "How much health a brawler should have");
	
	
	SOLDIER_FIRE_RATE = CreateConVar("talents_soldier_fire_rate", "0.6666", "How fast the soldier should fire. Lower values = faster", 0, true, 0.2);

	//ATHLETE_SPEED = CreateConVar("talents_athlete_speed", "1.35", "How fast soldier should run. A value of 1.0 = normal speed", FCVAR_PLUGIN);
	ATHLETE_JUMP_VEL = CreateConVar("talents_athlete_jump", "450.0", "How high a soldier should be able to jump. Make this higher to make them jump higher, or 0.0 for normal height");

	MEDIC_HEAL_DIST = CreateConVar("talents_medic_heal_dist", "256.0", "How close other survivors have to be to heal. Larger values = larger radius");
	MEDIC_HEALTH_VALUE = CreateConVar("talents_medic_health", "10", "How much health to restore");
	MEDIC_MAX_DEFIBS = CreateConVar("talents_medic_max_defibs", "2", "How many defibs the medic can drop");
	MEDIC_HEALTH_INTERVAL = CreateConVar("talents_medic_health_interval", "3.0", "How often to heal players within range");

	SABOTEUR_INVISIBLE_TIME = CreateConVar("talents_saboteur_invis_time", "15.0", "How long it takes for the saboteur to become invisible");
	SABOTEUR_BOMB_ACTIVATE = CreateConVar("talents_saboteur_bomb_activate", "5.0", "How long before the dropped bomb becomes sensitive to motion");
	SABOTEUR_BOMB_RADIUS = CreateConVar("talents_saboteur_bomb_radius", "128.0", "Radius of bomb motion detection");
	SABOTEUR_MAX_BOMBS = CreateConVar("talents_saboteur_max_bombs", "4", "How many bombs a saboteur can drop per round");
	SABOTEUR_BOMB_DAMAGE_SURV = CreateConVar("talents_saboteur_bomb_dmg_surv", "30", "How much damage a bomb does to survivors");
	SABOTEUR_BOMB_DAMAGE_INF = CreateConVar("talents_saboteur_bomb_dmg_inf", "300", "How much damage a bomb does to infected");
	SABOTEUR_BOMB_POWER = CreateConVar("talents_saboteur_bomb_power", "10.0", "How much blast power a bomb has. Higher values will throw survivors farther away");

	//SNIPER_DAMAGE_RATIO = CreateConVar("talents_sniper_dmg_ratio", "1.5", "How many more times sniper class does damage", FCVAR_PLUGIN);
	//SNIPER_DAMAGE_CRITICAL_CHANCE = CreateConVar("talents_sniper_dmg_critical_chance", "25", "Percent chance that damage will be critical", FCVAR_PLUGIN);
	//SNIPER_DAMAGE_CRITICAL_RATIO = CreateConVar("talents_sniper_dmg_critical_ratio", "3.0", "Critical damage ratio", FCVAR_PLUGIN);
	// SNIPER_DAMAGE = CreateConVar("talents_sniper_dmg", "5", "How much bonus damage a Sniper does");
	SNIPER_RELOAD_RATIO = CreateConVar("talents_sniper_reload_ratio", "0.44", "Ratio for how fast a Sniper should be able to reload");

	ENGINEER_MAX_BUILDS = CreateConVar("talents_engineer_max_builds", "4", "How many times an engineer can build per round");
	MAX_ENGINEER_BUILD_RANGE = CreateConVar("talents_engineer_build_range", "120.0", "Maximum distance away an object can be built by the engineer");
	
	MINIMUM_DROP_INTERVAL = CreateConVar("talents_drop_interval", "30.0", "Time before an engineer, medic, or saboteur can drop another item");
	
	ResetAllState();//turrets stuff
	
	AutoExecConfig(true, "talents");
}

ResetClientVariables(client)
{
	ClientData[client][PLAYERDATA:BombsUsed] = 0;
	ClientData[client][PLAYERDATA:ItemsBuilt] = 0;
	ClientData[client][PLAYERDATA:HideStartTime] = GetGameTime();
	ClientData[client][PLAYERDATA:LastButtons] = 0;
	ClientData[client][PLAYERDATA:ChosenClass] = _:NONE;
	ClientData[client][PLAYERDATA:LastDropTime] = 0.0;
	g_bInSaferoom[client] = false;
}

public Event_PlayerTeam(Event hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(hEvent.GetInt("userid"));
	new team = hEvent.GetInt("team");
	
	if (team == 2 && LastClassConfirmed[client] != 0)
	{
		ClientData[client][PLAYERDATA:ChosenClass] = LastClassConfirmed[client];
		PrintToChat(client, "You are currently a \x04%s", MENU_OPTIONS[LastClassConfirmed[client]]);
	}
}

public Event_RoundChange(Event event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		ResetClientVariables(i);
		LastClassConfirmed[i] = 0;
	}
	
	RndSession++;
	RoundStarted = false;
	ResetAllState();//turrets stuff
}

public OnMapStart()
{
	// Sounds
	PrecacheSound(SOUND_CLASS_SELECTED);
	PrecacheSound(SOUND_DROP_BOMB);
	
	// Sprites
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	PrecacheModel(ENGINEER_MACHINE_GUN);
	PrecacheModel(AMMO_PILE);
	// Particles
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(EFIRE_PARTICLE);
	PrecacheParticle(MEDIC_GLOW);
	
	// Cache
	ClearCache();
	RoundStarted = false;
	PrecacheTurret();//turretstuff
}

public OnMapEnd()
{
	// Cache
	ClearCache();
	
	RndSession = 0;
}

public OnClientPutInServer(client)
{
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	ResetClientVariables(client);
	RebuildCache();
}

public Action:TimerLoadGlobal(Handle:hTimer, any:client)
{
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return;

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
}

public Action:TimerLoadClient(Handle:hTimer, any:client)
{
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return;

	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_SetTransmit, SetTransmitInvisible);
}

public OnClientDisconnect(client)
{
	RebuildCache();
	ResetClientVariables(client);
}

public Action:CreatePlayerClassMenuDelay(Handle:hTimer, any:client)
{
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return;

	CreatePlayerClassMenu(client);
}

public Action:TimerThink(Handle:hTimer, any:client)
{
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return Plugin_Stop;

	if (IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return Plugin_Stop;
	
	new flags = GetEntityFlags(client);
	
	if (IsHanging(client) || IsIncapacitated(client) || FindAttacker(client) > 0 || IsClientOnLadder(client) || !(flags & FL_ONGROUND) || GetClientWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
		return Plugin_Continue;
	
	new buttons = GetClientButtons(client);
	new bool:CanDrop = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= MINIMUM_DROP_INTERVAL.FloatValue;
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	switch (ClientData[client][PLAYERDATA:ChosenClass])
	{
		//case ATHLETE:
		//	SetEntDataFloat(client, g_ioLMV, ATHLETE_SPEED.FloatValue, true);
		
		case SABOTEUR:
		{
			if (buttons & IN_DUCK )//&& (GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= SABOTEUR_INVISIBLE_TIME.FloatValue)
			{	//SetEntityRenderFx(client, RENDERFX_FADE_SLOW);
			//else
				SetEntityRenderFx(client, RENDERFX_NONE);
				SetEntDataFloat(client, g_ioLMV, 1.5, true);
			}
			else
			{
				SetEntDataFloat(client, g_ioLMV, 1.0, true);
			}
			
			if (buttons & IN_SPEED && CanDrop && ClientData[client][PLAYERDATA:ItemsBuilt] < SABOTEUR_MAX_BOMBS.IntValue)
			{
				if (!IsPlayerInSaferoom(client) && !IsInEndingSaferoom(client))
				{
					DropBomb(client);
					
					ClientData[client][PLAYERDATA:ItemsBuilt]++;
					ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
				}
			}
		}
		
		case MEDIC:
		{
			if (buttons & IN_SPEED && CanDrop && ClientData[client][PLAYERDATA:ItemsBuilt] < MEDIC_MAX_DEFIBS.IntValue)
			{
				ClientData[client][PLAYERDATA:ItemsBuilt]++;
				ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
				
				new entity = CreateEntityByName("weapon_defibrillator");
				DispatchKeyValue(entity, "solid", "0");
				DispatchKeyValue(entity, "disableshadows", "1");
				DispatchSpawn(entity);
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				
				PrintToChat(client, "%sYou dropped a \x04defibrillator", PRINT_PREFIX);
			}
		}
		
		case ENGINEER:
		{
			if (buttons & IN_SPEED && RoundStarted == true && CanDrop)// && ClientData[client][PLAYERDATA:ItemsBuilt] < ENGINEER_MAX_BUILDS.IntValue) 
			{	
				if(ClientData[client][PLAYERDATA:ItemsBuilt] < ENGINEER_MAX_BUILDS.IntValue)
				{
					CreatePlayerEngineerMenu(client);	
					ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
				}
				else
				{
					CreateRemoveTurretMenu(client);
					ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
				}
				
				
			}
		}
	}
	
	return Plugin_Continue;
}

CreateRemoveTurretMenu(client)
{
	if (!client)
		return false;
	
	Panel hPanel;
	
	if((hPanel = new Panel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreateRemoveTurretMenu");
		return false;
	}
	
	hPanel.SetTitle("Turret:");
	hPanel.DrawItem("Remove ");
	hPanel.DrawText(" ");
	hPanel.DrawItem("Exit");
	
	hPanel.Send(client, PanelHandler_RemoveTurretMenu, MENU_OPEN_TIME);
	delete hPanel;
	
	return true;
}
public PanelHandler_RemoveTurretMenu(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param == 1 && removemachine(client))//was 5
			{
				ClientData[client][PLAYERDATA:ItemsBuilt]--;
			}	
		}
	}
}

CreatePlayerEngineerMenu(client)
{
	if (!client)
		return false;
	
	Panel hPanel;
	
	if((hPanel = new Panel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerEngineerMenu");
		return false;
	}
	
	hPanel.SetTitle("Engineer:");
	hPanel.DrawItem("Ammo Pile");
	hPanel.DrawItem("Machine Gun");
	hPanel.DrawItem("Laser Sights");
	hPanel.DrawItem("Frag Rounds");
	hPanel.DrawItem("Incendiary Rounds");
	hPanel.DrawItem("Remove Turret");/// what ive added for remove tureet
	hPanel.DrawText(" ");
	hPanel.DrawItem("Exit");
	
	hPanel.Send(client, PanelHandler_SelectEngineerItem, MENU_OPEN_TIME);
	delete hPanel;
	
	return true;
}

public PanelHandler_SelectEngineerItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 6 )//was 5
				CalculateEngineerPlacePos(client, param - 1);
		}
	}
}

CalculateEngineerPlacePos(client, type)
{
	decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		delete trace;
		
		if (GetVectorDistance(endPos, vPos) <= MAX_ENGINEER_BUILD_RANGE.FloatValue)
		{
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			
			switch(type) {
				case 0: {
					new ammo = CreateEntityByName("weapon_ammo_spawn");
					DispatchSpawn(ammo);
					TeleportEntity(ammo, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client][PLAYERDATA:ItemsBuilt]++;
				}
				case 1:{
					//ClientCommand(client, "sm_dlrpmkai");
					if(CreateMachine(client))
					{
						ClientData[client][PLAYERDATA:ItemsBuilt]++;
					}
				}
				case 2: {
					new upgrade = CreateEntityByName("upgrade_laser_sight");
					DispatchKeyValue( upgrade, "count", "5" );
					DispatchKeyValue( upgrade, "spawnflags", "2" );
					DispatchSpawn(upgrade);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client][PLAYERDATA:ItemsBuilt]++;
				}
				case 3: {
					new upgrade = CreateEntityByName("upgrade_ammo_explosive");
					DispatchKeyValue( upgrade, "count", "5" );
					DispatchKeyValue( upgrade, "spawnflags", "2" );
					DispatchSpawn(upgrade);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client][PLAYERDATA:ItemsBuilt]++;
				}
				case 4: {
					new upgrade = CreateEntityByName("upgrade_ammo_incendiary");
					DispatchKeyValue( upgrade, "count", "5" );
					DispatchKeyValue( upgrade, "spawnflags", "2" );
					DispatchSpawn(upgrade);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
					ClientData[client][PLAYERDATA:ItemsBuilt]++;
				}
				
				case 5: {
					//ClientCommand(client, "sm_removemachine");
					if (removemachine(client))
					{
						ClientData[client][PLAYERDATA:ItemsBuilt]--;	
					}
				}
				default: {
					delete trace ;
					return;
				}
			}
			
			//ClientData[client][PLAYERDATA:ItemsBuilt]++;
			ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
		}
		else
			PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
		delete trace;
}

/*SpawnMiniGun(Float:vAng[3], Float:vPos[3])
{
	new entity = CreateEntityByName("prop_minigun");
	SetEntityModel(entity, ENGINEER_MACHINE_GUN);
	DispatchKeyValueFloat(entity, "MaxPitch", 360.00);
	DispatchKeyValueFloat(entity, "MinPitch", -360.00);
	DispatchKeyValueFloat(entity, "MaxYaw", 90.00);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	SetEntData( entity, g_CollisionOffset, 1, 4, true );

	DispatchSpawn(entity);
}*/

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
		return false;
	return true;
}

public Action:SetTransmitInvisible(client, entity)
{
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:SABOTEUR && ((GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= (SABOTEUR_INVISIBLE_TIME.FloatValue + 5.0)) && client != entity)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

DropBomb(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	DataPack hPack = new DataPack();
	hPack.WriteFloat(pos[0]);
	hPack.WriteFloat(pos[1]);
	hPack.WriteFloat(pos[2]);
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteCell(RndSession);
	CreateTimer(SABOTEUR_BOMB_ACTIVATE.FloatValue, TimerActivateBomb, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	
	EmitSoundToAll(SOUND_DROP_BOMB);
	
	PrintToChat(client, "%sYou dropped a \x04bomb", PRINT_PREFIX);
}

public Action:TimerActivateBomb(Handle:hTimer, DataPack hPack)
{
	CreateTimer(0.3, TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:TimerCheckBombSensors(Handle:hTimer, DataPack hPack)
{
	new Float:pos[3];
	decl Float:clientpos[3];
	
	hPack.Reset();
	pos[0] = hPack.ReadFloat();
	pos[1] = hPack.ReadFloat();
	pos[2] = hPack.ReadFloat();
	new owner = hPack.ReadCell();
	new session = hPack.ReadCell();

	owner = GetClientOfUserId(owner);
	if( !owner || !IsClientInGame(owner) ) return Plugin_Stop;
	
	if (session != RndSession)
		return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsGhost(client))
			continue;
		if(GetClientTeam(client) == 3)
		{
			GetClientAbsOrigin(client, clientpos);
		
			if (GetVectorDistance(pos, clientpos) < SABOTEUR_BOMB_RADIUS.FloatValue)
			{
				PrintToChatAll("%s\x03%N\x01's \x04bomb \x01detonated!", PRINT_PREFIX, owner);
				CreateExplosion(pos, owner, false);
				delete hPack;
				return Plugin_Stop;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsServerProcessing())
		return Plugin_Continue;
	
	if (victim && attacker > 0 && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
	{
		if (ClientData[attacker][PLAYERDATA:ChosenClass] == _:SNIPER && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			/*if (SNIPER_DAMAGE_CRITICAL_CHANCE.IntValue <= GetRandomInt(1, 100))
				damage *= SNIPER_DAMAGE_CRITICAL_RATIO.FloatValue;
			else
				damage *= SNIPER_DAMAGE_RATIO.FloatValue;*/
			damage = damage + getdamage(attacker);
			//PrintToChat(attacker,"%f",damage);
			//damage += SNIPER_DAMAGE.IntValue;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}
public Action:CmdClassInfo(client, args)
{
	PrintToChat(client,"\x05Soldier\x01 = faster fire rate");
	PrintToChat(client,"\x05Athlete\x01 = jump higher and auto bunyhophop");
	PrintToChat(client,"\x05Medic\x01 = crouch to heal team, shift to drop defibs");
	PrintToChat(client,"\x05Saboture\x01 = hold crouch for invisability,shift drps bombs");
	PrintToChat(client,"\x05Commando\x01 = extra damage, fast reload");
	PrintToChat(client,"\x05Engineer\x01 = shift to drop auto turets and stuff");
	PrintToChat(client,"\x05Brawler\x01 = lots of health");	
}

public Action:CmdClasses(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ClientData[i][PLAYERDATA:ChosenClass] != _:NONE)
		{
			PrintToChatAll("\x04%N\x01 : is a %s",i,MENU_OPTIONS[ClientData[i][PLAYERDATA:ChosenClass]]);
		}
	}
}

CreatePlayerClassMenu(client)
{
	if (!client)
		return false;
	
	// if client has a class already and round has started, dont give them the menu
	if (ClientData[client][PLAYERDATA:ChosenClass] != _:NONE && RoundStarted == true)
	{
		PrintToChat(client,"Round has started, your class is locked, You are a %s",MENU_OPTIONS[ClientData[client][PLAYERDATA:ChosenClass]]);
		return false;
	}
	
	Panel hPanel;
	decl String:buffer[256];
	
	if((hPanel = new Panel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	hPanel.SetTitle("Select Your Class");
	
	for (new i = 1; i < _:MAXCLASSES; i++)
	{
		if( GetMaxWithClass(i) >= 0 )
			Format(buffer, sizeof(buffer), "%i/%i %s", CountPlayersWithClass(i), GetMaxWithClass(i),  MENU_OPTIONS[i]);
		else
			Format(buffer, sizeof(buffer), "%s", MENU_OPTIONS[i]);
		hPanel.DrawItem(buffer);
	}
	
	hPanel.DrawText(" ");
	hPanel.DrawItem("Exit");
	
	hPanel.Send(client, PanelHandler_SelectClass, MENU_OPEN_TIME);
	delete hPanel;
	
	return true;
}

public PanelHandler_SelectClass(Handle:menu, MenuAction:action, client, param)
{
	new OldClass;
	OldClass = ClientData[client][PLAYERDATA:ChosenClass];
	
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!client || param >= _:MAXCLASSES || GetClientTeam(client)!=2 )
			{
				return;
			}
			
			
			
			if( GetMaxWithClass( param ) >= 0 && CountPlayersWithClass( param ) >= GetMaxWithClass( param ) && ClientData[client][PLAYERDATA:ChosenClass] != param ) 
			{
				PrintToChat( client, "%sThe \x04%s\x01 class is full, please choose another.", PRINT_PREFIX, MENU_OPTIONS[ param ] );
				CreatePlayerClassMenu( client );
			} 
			else
			{
				//DrawConfirmPanel(client, param);
				
				LastClassConfirmed[client] = param;
				ClientData[client][PLAYERDATA:ChosenClass] = param;	

				PrintToConsole(client, "Class is setting up");
				
				SetupClasses(client, param);
				EmitSoundToClient(client, SOUND_CLASS_SELECTED);
				
				if(OldClass == _:NONE)
				{
					PrintToChatAll("\x04%N\x01 : is a \x05%s\x01%s",client,MENU_OPTIONS[param],ClassTips[param]);
				}	
				else
				{
					PrintToChatAll("\x04%N\x01 : class changed from \x05%s\x01 to \x05%s\x01",client,MENU_OPTIONS[OldClass],MENU_OPTIONS[param]);
				}
			}
		}	
	}	
}
/*
DrawConfirmPanel(client, chosenClass)
{
	if (!client || chosenClass >= _:MAXCLASSES)
		return false;
	
	LastChosenClass[client] = chosenClass;
	
	new Handle:hPanel;
	decl String:buffer[256];
	
	if((hPanel = new Panel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	Format(buffer, sizeof(buffer), "Select the %s talent?", MENU_OPTIONS[chosenClass]);
	hPanel.SetTitle(buffer);
	
	
	hPanel.DrawItem("Yes");
	hPanel.DrawItem("No");
	
	hPanel.Send(client, PanelHandler_ConfirmClass, MENU_OPEN_TIME);
	delete hPanel;
	
	return true;
}

public PanelHandler_ConfirmClass(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new class = LastChosenClass[client];
			
			if( param == 1 && class < _:MAXCLASSES && ( CountPlayersWithClass( class ) < GetMaxWithClass( class ) || ClientData[client][PLAYERDATA:ChosenClass] != class || GetMaxWithClass( class ) < 0 ) )
			{
				LastClassConfirmed[client] = class;
				
				PrintToConsole(client, "Class is setting up");
				
				SetupClasses(client, class);
				EmitSoundToClient(client, SOUND_CLASS_SELECTED);
				PrintToChat(client, "%sYou are now a \x04%s", PRINT_PREFIX, MENU_OPTIONS[class]);
			}
			else
				CreatePlayerClassMenu(client);
		}
	}
}
*/


SetupClasses(client, class)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2)
			return;
	
	ClientData[client][PLAYERDATA:ChosenClass] = class;
	new MaxPossibleHP = 100;
	
	switch (class)
	{
		case SOLDIER:
		{
			PrintHintText(client,"soldier attacks fast, try meleeing the tank to death");
			MaxPossibleHP = SOLDIER_HEALTH.IntValue;
		}
		
		case MEDIC:
		{
			PrintHintText(client,"hold crtl to heal your team mates");
			CreateTimer(MEDIC_HEALTH_INTERVAL.FloatValue, TimerDetectHealthChanges, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			MaxPossibleHP = MEDIC_HEALTH.IntValue;
		}
		
		case ATHLETE:
		{
			PrintHintText(client,"hold jump to bunny hop");
			MaxPossibleHP = ATHLETE_HEALTH.IntValue;
		}
		
		case SNIPER:
		{
			PrintHintText(client,"hope your confident, its your job to do ALL the KILLING!!");
			MaxPossibleHP = SNIPER_HEALTH.IntValue;
		}
		
		case ENGINEER:
		{
			PrintHintText(client,"press shift to open the drop equipment menu, the turret is automatic");
			MaxPossibleHP = ENGINEER_HEALTH.IntValue;
		}
		
		case SABOTEUR:
		{
			PrintHintText(client,"hold crtl to go invisable, the ai can still find you");
			MaxPossibleHP = SABOTEUR_HEALTH.IntValue;
		}
		
		case BRAWLER:
		{
			
			PrintHintText(client,"you've got a lot of health,try not to waste it");
			MaxPossibleHP = BRAWLER_HEALTH.IntValue;
		}
	}
	
	// HEALTH
	new OldMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	new OldHealth = GetClientHealth(client);
	new OldTempHealth = GetClientTempHealth(client);
	
	SetEntProp(client, Prop_Send, "m_iMaxHealth", MaxPossibleHP);
	SetEntityHealth(client, MaxPossibleHP - (OldMaxHealth - OldHealth));
	SetClientTempHealth(client, OldTempHealth);
	
	if ((GetClientHealth(client) + GetClientTempHealth(client)) > MaxPossibleHP)
	{
		SetEntityHealth(client, MaxPossibleHP);
		SetClientTempHealth(client, 0);
	}
}

public Action:CmdClassMenu(client, args)
{
	if (GetClientTeam(client) != 2)
	{
		PrintToChat(client, "%sOnly Survivors can choose a class.", PRINT_PREFIX);
		return;
	}
	
	//if (ClientData[client][PLAYERDATA:ChosenClass] != _:NONE)
	//{
	//	PrintToChat(client, "%sYou have already chosen a class this round.", PRINT_PREFIX);
	//	return;
	//}
	
	CreatePlayerClassMenu(client);
}

public Action:TimerDetectHealthChanges(Handle:hTimer, any:client)
{
	client = GetClientOfUserId(client);
	if( !client || !IsClientInGame(client) ) return Plugin_Stop;

	if ( ClientData[client][PLAYERDATA:ChosenClass] != _:MEDIC)
			return Plugin_Stop;
			
	if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
	{	return Plugin_Continue; }
	
	new btns = GetClientButtons(client);
	
	if (btns & IN_DUCK)
	{
		CreateParticle(client, MEDIC_GLOW, true, 1.0);
		
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
			{
				decl Float:tpos[3];
				GetClientAbsOrigin(i, tpos);
				
				if (GetVectorDistance(pos, tpos) <= MEDIC_HEAL_DIST.FloatValue)
				{
					// pre-heal set values
					new MaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
					new TempHealth = GetClientTempHealth(i);
					
					SetEntityHealth(i, GetClientHealth(i) + MEDIC_HEALTH_VALUE.IntValue);
					SetClientTempHealth(i, TempHealth);
					
					// post-heal set values
					new newHp = GetClientHealth(i);
					new totalHp = newHp + TempHealth;
					
					if (totalHp > MaxHealth)
					{
						new diff = totalHp - MaxHealth;
						
						if (TempHealth >= diff)
						{
							SetClientTempHealth(i, TempHealth - diff);
							continue;
						}
						
						SetClientTempHealth(i, 0);
						SetEntityHealth(i, MaxHealth);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public OnGameFrame()
{
	if (!g_iRC)
		return;

	decl client;
	decl bweapon;
	decl Float:fNTC;
	decl Float:fNTR;
	new Float:fGT = GetGameTime();
	
	for (new i = 1; i <= g_iRC; i++)
	{
		client = g_iRI[i];
		
		if (!client
		|| client >= MAXPLAYERS
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2
		|| ClientData[client][PLAYERDATA:ChosenClass] != _:SOLDIER)
			continue;
		
		bweapon = GetEntDataEnt2(client, g_oAW);
		
		if(bweapon <= 0) 
			continue;
		
		fNTR = GetEntDataFloat(bweapon, g_iNPA);
		
		if (g_iEi[client] == bweapon && g_fNT[client] >= fNTR)
			continue;
		
		if (g_iEi[client] == bweapon && g_fNT[client] < fNTR)
		{
			fNTC = ( fNTR - fGT ) * SOLDIER_FIRE_RATE.FloatValue + fGT;
			g_fNT[client] = fNTC;
			SetEntDataFloat(bweapon, g_iNPA, fNTC, true);
			continue;
		}
		
		if (g_iEi[client] != bweapon)
		{
			g_iEi[client] = bweapon;
			g_fNT[client] = fNTR;
			continue;
		}
	}
}

ClearCache()
{
	g_iRC = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iRI[i]= -1;
		g_iEi[i] = -1;
		g_fNT[i]= -1.0;
	}
}

RebuildCache()
{
	ClearCache();

	if (!IsServerProcessing())
		return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && ClientData[i][PLAYERDATA:ChosenClass] == _:SOLDIER)
		{
			g_iRC++;
			g_iRI[g_iRC] = i;
		}
	}
}

public Event_PlayerSpawn(Event hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		GetClientAbsOrigin(client, g_SpawnPos[client]);
		
		if (GetClientTeam(client) == 2)
		{
			CreateTimer(0.3, TimerLoadClient, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, TimerThink, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			if (LastClassConfirmed[client] != 0)
				ClientData[client][PLAYERDATA:ChosenClass] = LastClassConfirmed[client];
			else
				CreateTimer(1.0, CreatePlayerClassMenuDelay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		CreateTimer(0.3, TimerLoadGlobal, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	RebuildCache();
}

public Event_PlayerHurt(Event hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
}

public Event_PlayerDeath(Event hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
	
	new client = GetClientOfUserId(hEvent.GetInt("userid"));
	ResetClientVariables(client);
}

public Action:OnWeaponSwitch(client, weapon)
{
	RebuildCache();
}

public Action:OnWeaponEquip(client, weapon)
{
	RebuildCache();
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;
	
	new flags = GetEntityFlags(client);
	
	if (!(buttons & IN_DUCK) || !(flags & FL_ONGROUND))
		ClientData[client][PLAYERDATA:HideStartTime] = GetGameTime();
	
	if (IsFakeClient(client) || IsHanging(client) || IsIncapacitated(client) || FindAttacker(client) > 0 || IsClientOnLadder(client) || GetClientWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
		return Plugin_Continue;
	
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:ATHLETE)
	{
		if (buttons & IN_JUMP && flags & FL_ONGROUND )
		{
			PushEntity(client, Float:{-90.0,0.0,0.0}, ATHLETE_JUMP_VEL.FloatValue);
			flags &= ~FL_ONGROUND;	
			SetEntityFlags(client,flags);
		}
	}
	
	ClientData[client][PLAYERDATA:LastButtons] = buttons;
	
	return Plugin_Continue;
}

public Event_RelSniperClass(Event event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(event.GetInt("userid"));
	
	if (ClientData[client][PLAYERDATA:ChosenClass] != _:SNIPER)
		return;
	
	new weapon = GetEntDataEnt2(client, g_oAW);
	
	if (!IsValidEntity(weapon))
		return;
	
	new Float:flGT = GetGameTime();
	decl String:bNetCl[64];
	GetEntityNetClass(weapon, bNetCl, sizeof(bNetCl));
	
	if (StrContains(bNetCl, "shotgun", false) == -1)
	{
		new Float:fRLRat = SNIPER_RELOAD_RATIO.FloatValue;
		new Float:fNTC = (GetEntDataFloat(weapon, g_iNPA) - flGT) * fRLRat;
		new Float:NA = fNTC + flGT;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
		SetEntDataFloat(weapon, g_ioTI, NA, true);
		SetEntDataFloat(weapon, g_iNPA, NA, true);
		SetEntDataFloat(client, g_ioNA, NA, true);
		
		CreateTimer(fNTC, SniperRelFireEnd, EntIndexToEntRef(weapon));
	}
	else
	{
		if (StrContains(bNetCl, "pumpshotgun", false) != -1)
		{
			DataPack hPack = new DataPack();
			hPack.WriteCell(EntIndexToEntRef(weapon));

			hPack.WriteFloat(0.393939);
			hPack.WriteFloat(0.472999);
			hPack.WriteFloat(0.875000);
			
			CreateTimer(0.1, SniperPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "autoshotgun", false) != -1)
		{
			DataPack hPack = new DataPack();
			hPack.WriteCell(EntIndexToEntRef(weapon));

			hPack.WriteFloat(0.416666);
			hPack.WriteFloat(0.395999);
			hPack.WriteFloat(1.000000);
			
			CreateTimer(0.1, SniperPumpShotReload, hPack);
		}
	}
}

public Action:SniperRelFireEnd(Handle:timer, any:weapon)
{
	weapon = EntRefToEntIndex(weapon);
	if( weapon == INVALID_ENT_REFERENCE ) return Plugin_Stop;
	
	SetEntDataFloat(weapon, g_ioPR, 1.0, true);
	
	return Plugin_Stop;
}

public Action:SniperPumpShotReload(Handle:timer, DataPack hOldPack)
{
	hOldPack.Reset();
	new weapon = hOldPack.ReadCell();
	weapon = EntRefToEntIndex(weapon);
	if( weapon == INVALID_ENT_REFERENCE ) return Plugin_Stop;

	new Float:fRLRat = SNIPER_RELOAD_RATIO.FloatValue;
	
	SetEntDataFloat(weapon,	g_iSSD,	hOldPack.ReadFloat() * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSID,	hOldPack.ReadFloat() * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSED, hOldPack.ReadFloat() * fRLRat,	true);
	SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
	
	delete hOldPack;
	
	DataPack hPack = new DataPack();
	hPack.WriteCell(EntIndexToEntRef(weapon));
	
	if (GetEntData(weapon, g_iSRS) != 2)
	{
		hPack.WriteFloat(0.2);
		CreateTimer(0.3, SniperShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		hPack.WriteFloat(1.0);
		CreateTimer(0.3, SniperShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action:SniperShotCalculate(Handle:timer, DataPack hPack)
{
	hPack.Reset();
	new weapon = hPack.ReadCell();
	weapon = EntRefToEntIndex(weapon);
	if( weapon == INVALID_ENT_REFERENCE ) return Plugin_Stop;

	new Float:addMod = hPack.ReadFloat();
	
	if (weapon <= 0 || !IsValidEntity(weapon))
	{
		delete hPack;
		return Plugin_Stop;
	}
	
	if (GetEntData(weapon, g_iSRS) == 0)
	{
		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0, true);
		SetEntDataFloat(GetEntPropEnt(weapon, Prop_Data, "m_hOwner"), g_ioNA, flNextTime, true);
		SetEntDataFloat(weapon,	g_ioTI, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNPA, flNextTime, true);
		
		delete hPack;
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Event_EnterSaferoom(Event event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(event.GetInt("userid"));
	g_bInSaferoom[client] = true;
}

public Event_LeftSaferoom(Event event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(event.GetInt("userid"));
	g_bInSaferoom[client] = false;
}




public Plugin:myinfo =
{
	name = "Talents Plugin",
	author = "DLR / Neil  & modded by spirit & panxiaohai",
	description = "Incorporates Survivor Classes,balanced commando,classinfo,fixed class exploit",
	version = "v1.0-silver",
	url = "http://deadlandrape.wordpress.com/"
};

CountPlayersWithClass( class ) {
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if(ClientData[i][PLAYERDATA:ChosenClass] == class)
			count++;
	}

	return count;
}

GetMaxWithClass( class ) {
	switch(class) {
		case SOLDIER:
			return MAX_SOLDIER .IntValue;
		case ATHLETE:
			return MAX_ATHLETE .IntValue;
		case MEDIC:
			return MAX_MEDIC .IntValue;
		case SABOTEUR:
			return MAX_SABOTEUR .IntValue;
		case SNIPER:
			return MAX_SNIPER .IntValue;
		case ENGINEER:
			return MAX_ENGINEER .IntValue;
		case BRAWLER:
			return MAX_BRAWLER .IntValue;
		default:
			return -1;
	}
}

public Action:Event_WeaponFire(Event event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(event.GetInt("userid"));
	
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:NONE && GetClientTeam(client) == 2)
	{
		if(client >0 && client < MAXPLAYERS + 1)
		{
			PrintHintText(client,"you really should pick a class, 1,5,7 are good for beginers");
			CreatePlayerClassMenu(client);
		}
	}
	
	if(ClientData[client][PLAYERDATA:ChosenClass] == _:SNIPER)
	{
		event.GetString("weapon", ClientData[client][PLAYERDATA:EquipedGun], 64);
		//PrintToChat(client,"weapon shot fired");	
	}
	return Plugin_Continue;
}

getdamage(client)
{
	if (StrContains(ClientData[client][PLAYERDATA:EquipedGun],"rifle", false)!=-1)
	{
		return 10;
	}
	if (StrContains(ClientData[client][PLAYERDATA:EquipedGun],"shotgun", false)!=-1)
	{
		return 5;
	}
	if (StrContains(ClientData[client][PLAYERDATA:EquipedGun], "sniper", false)!=-1)
	{
		return 15;
	}
	if (StrContains(ClientData[client][PLAYERDATA:EquipedGun], "hunting", false)!=-1)
	{
		return 15;
	}
	if (StrContains(ClientData[client][PLAYERDATA:EquipedGun], "pistol", false)!=-1)
	{
		return 25;
	}
	if (StrContains(ClientData[client][PLAYERDATA:EquipedGun], "smg", false)!=-1)
	{
		return 7;
	}
	return 0;
}

public Action:Event_LeftStartArea(Event event, const String:name[], bool:dontBroadcast)
{
	RoundStarted = true;
	PrintToChatAll("%sPlayers left safe area, classes now locked",PRINT_PREFIX);	
}
stock bool:IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

#include <sdktools_functions>

#define Pai 3.14159265358979323846 
#define DEBUG false

#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"  
#define PARTICLE_WEAPON_TRACER		"weapon_tracers" 
#define PARTICLE_WEAPON_TRACER2		"weapon_tracers_50cal"//weapon_tracers_50cal" //"weapon_tracers_explosive" weapon_tracers_50cal
 
#define PARTICLE_BLOOD		"blood_impact_red_01"
#define PARTICLE_BLOOD2		"blood_impact_headshot_01"

#define SOUND_IMPACT1		"physics/flesh/flesh_impact_bullet1.wav"  
#define SOUND_IMPACT2		"physics/concrete/concrete_impact_bullet1.wav"  
#define SOUND_FIRE		"weapons/50cal/50cal_shoot.wav"  
#define MODEL_GUN "models/w_models/weapons/w_minigun.mdl"

new MachineCount = 0;

#define EnemyArraySize 300
new InfectedsArray[EnemyArraySize];
new InfectedCount;

new UseCount[MAXPLAYERS+1]; 

new Float:ScanTime=0.0;

new Gun[MAXPLAYERS+1];
new GunOwner[MAXPLAYERS+1];
new GunEnemy[MAXPLAYERS+1];

new Float:GunFireStopTime[MAXPLAYERS+1];
new Float:GunFireTime[MAXPLAYERS+1];
new Float:GunFireTotolTime[MAXPLAYERS+1];
new GunScanIndex[MAXPLAYERS+1]; 
new Float:LastTime[MAXPLAYERS+1]; 


new Float:FireIntervual=0.08; 
new Float:FireOverHeatTime=10.0;
new Float:FireRange=1000.0;

GetMinigun(client )
{ 
	new ent= GetClientAimTarget(client, false);
	if(ent>0)
	{			
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);			
		if(StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1"))
		{
		}
		else ent=0;
	}  
	return ent;
}

/*
machine(client)
{
	if(ClientData[client][PLAYERDATA:ItemsBuilt]>=4)
	{
		PrintToChat(client, "You can use it more than %d times",4);
		return;
	}
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		CreateMachine(client);
	}
}
*/

bool:removemachine(client)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new gun=GetMinigun(client);
		new index=FindGunIndex(gun);
		if(index<0)
		{
			return false;
		}
		else
		{
			RemoveMachine(index);
			return true;
		}
	}
	return false;
} 
/*public Action:witch_harasser_set(Event hEvent, const String:strName[], bool:DontBroadcast)
{
	new witch =  hEvent.GetInt("witchid") ; 
	InfectedsArray[0]=witch;	
	for(new i=0; i<MachineCount; i++)
	{
		GunEnemy[i]=witch;
		GunScanIndex[i]=0;
	}
}*/
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	return true;
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}

public void PrecacheTurret()
{
	PrecacheModel(MODEL_GUN);
	 
	PrecacheSound(SOUND_FIRE);
	PrecacheSound(SOUND_IMPACT1);	
	PrecacheSound(SOUND_IMPACT2);
 
	PrecacheParticle(PARTICLE_MUZZLE_FLASH);
		
	PrecacheParticle(PARTICLE_WEAPON_TRACER2);
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_BLOOD2);

}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		decl String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
}

ShowMuzzleFlash(Float:pos[3],  Float:angle[3])
{  
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);	
}
ResetAllState()
{
	MachineCount=0;
	ScanTime=0.0;
	for(new i=1; i<=MaxClients; i++)
	{ 
		UseCount[i]=0;
	} 
	InfectedCount=0;	
} 
ScanEnemys()
{	
	if(IsWitch(InfectedsArray[0]))
	{
		InfectedCount=1;
	}
	else InfectedCount=0;
	
	for(new i=1 ; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			InfectedsArray[InfectedCount++]=i;
		}
	}
	new ent=-1;
	while ((ent = FindEntityByClassname(ent,  "infected" )) != -1 && InfectedCount<EnemyArraySize-1)
	{
		InfectedsArray[InfectedCount++]=ent;
	} 
}
bool:CreateMachine(client)
{
	if(MachineCount >= 4)
	{
		PrintToChat(client, "There are too many machine");
		return false;
	} 
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND))return false;
		Gun[MachineCount]=SpawnMiniGun(client);  
		LastTime[MachineCount]=GetEngineTime();
		
		GunScanIndex[MachineCount]=0;
		GunEnemy[MachineCount]=0;
		GunFireTime[MachineCount]=0.0;
		GunFireStopTime[MachineCount]=0.0;
		GunFireTotolTime[MachineCount]=0.0;
		GunOwner[MachineCount]=client;		
		
		SDKUnhook( Gun[MachineCount], SDKHook_Think,  PreThinkGun); 
		SDKHook( Gun[MachineCount], SDKHook_Think,  PreThinkGun); 

		UseCount[client]++;
		if(MachineCount==0)
		{
			ScanEnemys();
		} 
		MachineCount++;
		return true;
	}
	return false;
}
RemoveMachine(index)
{
	SDKUnhook( Gun[index], SDKHook_Think,  PreThinkGun);   
	if(Gun[index]>0 && IsValidEdict(Gun[index]) && IsValidEntity(Gun[index]))AcceptEntityInput((Gun[index]), "Kill");
	Gun[index]=0;
	if(MachineCount>1)
	{		
		Gun[index]=Gun[MachineCount-1];
		LastTime[index]=LastTime[MachineCount-1];
 
		GunScanIndex[index]=GunScanIndex[MachineCount-1];
		GunEnemy[index]=GunEnemy[MachineCount-1];
		GunFireTime[index]=GunFireTime[MachineCount-1];
		GunFireStopTime[index]=GunFireStopTime[MachineCount-1];
		GunFireTotolTime[index]=GunFireTotolTime[MachineCount-1];
		GunOwner[index]=GunOwner[MachineCount-1];
	}
	MachineCount--;
 
	if(MachineCount<0)MachineCount=0; 
}

SpawnMiniGun(client)
{
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3]; 
	new gun=0;
	gun=CreateEntityByName ( "prop_minigun"); 
	SetEntityModel (gun, MODEL_GUN);		
	DispatchSpawn(gun);
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(gun, "Angles", VecAngles);
	TeleportEntity(gun, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(gun, Prop_Send, "m_iTeamNum", 2);  
	SetColor(gun);
	return gun;
}
SetColor(gun)
{
	SetEntProp(gun, Prop_Send, "m_iGlowType", 3);
	SetEntProp(gun, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(gun, Prop_Send, "m_nGlowRangeMin", 1);
	new red=0;
	new gree=250;
	new blue=0;
	SetEntProp(gun, Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}

FindGunIndex(gun)
{
	new index=-1;
	for(new i=0; i<MachineCount; i++)
	{
		if(Gun[i]==gun)
		{
			index=i;
			break;
		}
	}
	return index;
}

public PreThinkGun(gun)
{	
	new index=FindGunIndex(gun);	
	if(index!=-1)
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[index];  
		LastTime[index]=time; 
		ScanAndShotEnmey(index, time, intervual); 
	}
}
ScanAndShotEnmey(index , Float:time, Float:intervual)
{
	new gun1=Gun[index]; 
	new user=GunOwner[index];
	if(user>0 && IsClientInGame(user))user=user+0;
	else user=0;
	
	if(time-ScanTime>1.0)
	{
		ScanTime=time;
		ScanEnemys(); 
	}	
	
	decl Float:gun1pos[3];
	decl Float:gun1angle[3];
	decl Float:hitpos[3];
	decl Float:temp[3];
	decl Float:shotangle[3];
	decl Float:gunDir[3];
	 
	GetEntPropVector(gun1, Prop_Send, "m_vecOrigin", gun1pos);	
	GetEntPropVector(gun1, Prop_Send, "m_angRotation", gun1angle);	
	 
	GetAngleVectors(gun1angle, gunDir, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector(gunDir, gunDir);
	CopyVector(gunDir, temp);	
	ScaleVector(temp, 50.0);
	AddVectors(gun1pos, temp ,gun1pos);
	GetAngleVectors(gun1angle, NULL_VECTOR, NULL_VECTOR, temp );
	NormalizeVector(temp, temp);
	//ShowDir(2, gun1pos, temp, 0.06);
	ScaleVector(temp, 43.0);
 
	AddVectors(gun1pos, temp ,gun1pos);
 
	new newenemy=GunEnemy[index];
	if( IsVilidEenmey(newenemy))
	{
		newenemy = IsEnemyVisible(gun1, newenemy, gun1pos, hitpos,shotangle);		
	}
	else newenemy=0;
 
	if(InfectedCount>0 && newenemy==0)
	{
		if(GunScanIndex[index]>=InfectedCount)
		{
			GunScanIndex[index]=0;
		}
		GunEnemy[index]=InfectedsArray[GunScanIndex[index]];
		GunScanIndex[index]++;
		newenemy=0;
		
	}

	if(newenemy==0)
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0);

		return;
	}
	decl Float:enemyDir[3]; 
	decl Float:newGunAngle[3]; 
	if(newenemy>0)
	{
		SubtractVectors(hitpos, gun1pos, enemyDir);				
	}
	else
	{
		CopyVector(gunDir, enemyDir); 
		enemyDir[2]=0.0; 
	}
	NormalizeVector(enemyDir,enemyDir);	 
	
	decl Float:targetAngle[3]; 
	GetVectorAngles(enemyDir, targetAngle);
	new Float:diff0=AngleDiff(targetAngle[0], gun1angle[0]);
	new Float:diff1=AngleDiff(targetAngle[1], gun1angle[1]);
	
	new Float:turn0=45.0*Sign(diff0)*intervual;
	new Float:turn1=180.0*Sign(diff1)*intervual;
	if(FloatAbs(turn0)>=FloatAbs(diff0))
	{
		turn0=diff0;
	}
	if(FloatAbs(turn1)>=FloatAbs(diff1))
	{
		turn1=diff1;
	}
	 
	newGunAngle[0]=gun1angle[0]+turn0;
	newGunAngle[1]=gun1angle[1]+turn1; 
	 
	newGunAngle[2]=0.0; 
	
	DispatchKeyValueVector(gun1, "Angles", newGunAngle);
	new overheated=GetEntProp(gun1, Prop_Send, "m_overheated");
	
	GetAngleVectors(newGunAngle, gunDir, NULL_VECTOR, NULL_VECTOR); 
	
	if(overheated==0)
	{
		if( newenemy>0 && FloatAbs(diff1)<40.0)
		{ 
			if(time>=GunFireTime[index] )
			{
				GunFireTime[index]=time+FireIntervual;  								
				Shot(user, gun1, gun1pos, newGunAngle); 
				
				GunFireStopTime[index]=time+0.05; 	
			} 
		} 
	}
	new Float:heat=GetEntPropFloat(gun1, Prop_Send, "m_heat"); 
	
	if(time<GunFireStopTime[index])
	{
		GunFireTotolTime[index]+=intervual;
		heat=GunFireTotolTime[index]/FireOverHeatTime;
		if(heat>=1.0)heat=1.0;
		SetEntProp(gun1, Prop_Send, "m_firing", 1); 		
		SetEntPropFloat(gun1, Prop_Send, "m_heat", heat);
	}
	else 
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0); 	
		heat=heat-intervual/4.0;
		if(heat<0.0)
		{
			heat=0.0;
			SetEntProp(gun1, Prop_Send, "m_overheated", 0);
			SetEntPropFloat(gun1, Prop_Send, "m_heat", 0.0 );
		}
		else SetEntPropFloat(gun1, Prop_Send, "m_heat", heat ); 
		GunFireTotolTime[index]=FireOverHeatTime*heat; 
	}

	return;
}
IsEnemyVisible( gun, ent, Float:gunpos[3], Float:hitpos[3], Float:angle[3])
{		
	if(ent<=0)return 0;
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
	hitpos[2]+=35.0; 

	SubtractVectors(hitpos, gunpos, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(gunpos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun); 	 

	new newenemy=0;
	 
	if(TR_DidHit(trace))
	{		 
		TR_GetEndPosition(hitpos, trace);
		newenemy = TR_GetEntityIndex(trace);  
		if(GetVectorDistance(gunpos, hitpos)>FireRange)newenemy=0;	 
	}
	else
	{
		newenemy=ent;
	}
	if(newenemy>0)
	{		 
		if(newenemy<=MaxClients)
		{
			if(!(IsClientInGame(newenemy) && IsPlayerAlive(newenemy) && GetClientTeam(newenemy)== 3))
				newenemy = 0;
		}
		else	
		{
			decl String:classname[32];
			GetEdictClassname(newenemy, classname,32);
			if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
			{
				newenemy=newenemy+0;
			}
			else newenemy=0;
		}
	} 
	delete trace; 
	return newenemy;
}
Shot(client, gun, Float:gunpos[3],  Float:shotangle[3])
{
	decl Float:temp[3];
	decl Float:ang[3];
	GetAngleVectors(shotangle, temp, NULL_VECTOR,NULL_VECTOR); 
	NormalizeVector(temp, temp); 
	 
	new Float:acc=0.020; // add some spread
	temp[0] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[1] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[2] += GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(temp, ang);

	new Handle:trace= TR_TraceRayFilterEx(gunpos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun); 
	new enemy=0;	
	 
	if(TR_DidHit(trace))
	{			
		decl Float:hitpos[3];		 
		TR_GetEndPosition(hitpos, trace);		
		enemy=TR_GetEntityIndex(trace); 
		
		if(enemy>0)
		{			
			decl String:classname[32];
			GetEdictClassname(enemy, classname, 32);	
			if(enemy >=1 && enemy<=MaxClients)//if enemy is a client
			{
				if(GetClientTeam(enemy)==2 ) {enemy=0;}	
			}
			else if(StrEqual(classname, "infected") || StrEqual(classname, "witch" ) )
			{

			} 	
			else enemy=0;
		} 
		if(enemy>0)
		{
			if(client>0 && IsPlayerAlive(client))client=client+0;
			else client=0;
			HurtEntity(enemy, client, 25.0, 0);
			decl Float:Direction[3];
			GetAngleVectors(ang, Direction, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(Direction, -1.0);
			GetVectorAngles(Direction,Direction);
			ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);				
			EmitSoundToAll(SOUND_IMPACT1, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}
		else
		{		
			decl Float:Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(hitpos,Direction,1,3);
			TE_SendToAll();
			EmitSoundToAll(SOUND_IMPACT2, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}
		ShowMuzzleFlash(gunpos, ang);
		EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,gunpos, NULL_VECTOR,true, 0.0);
	}
	delete trace;
}
Float:AngleDiff(Float:a, Float:b)
{
	new Float:d=0.0;
	if(a>=b)
	{
		d=a-b;
		if(d>=180.0)d=d-360.0;
	}
	else
	{
		d=a-b;
		if(d<=-180.0)d=360+d;
	}
	return d;
}
Float:Sign(Float:v)
{	// positive or negitive number returns 1, 0 ,-1
	if(v==0.0)return 0.0;
	else if(v>0.0)return 1.0;
	else return -1.0;
}
bool:IsVilidEenmey(enemy)
{	
	new bool:r=false;
	if(enemy<=0)return r;
	if( enemy<=MaxClients)
	{ //if enemy is a client
		if(IsClientInGame(enemy) && IsPlayerAlive(enemy) && GetClientTeam(enemy)== 3)
		{
			r=true;
		} 
	}
	else if( IsValidEntity(enemy) && IsValidEdict(enemy))
	{
		decl String:classname[32];
		GetEdictClassname(enemy, classname,32);
		if(StrEqual(classname, "infected", true) )
		{
			r=true;
			new flag=GetEntProp(enemy, Prop_Send, "m_bIsBurning");
			if(flag==1)
			{
				r=false; 
			}
		}
		else if (StrEqual(classname, "witch", true))
		{
			r=true;
		}
	} 
	return r;
}
public ShowParticle(Float:pos[3], Float:ang[3],String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename); 
		DispatchSpawn(particle);
		ActivateEntity(particle);
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		AcceptEntityInput(particle, "start");		
		CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		return particle;
	}  
	return 0;
}


