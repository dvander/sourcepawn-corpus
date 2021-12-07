/**
 * vim: set ts=4 :
 * =============================================================================
 * Talents Plugin by Neil
 * Incorporates Survivor classes.
 *
 * (C)2013 DeadLandRape / Neil.  All rights reserved.
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

// How long should the Class Select menu stay open?
static const Float:MENU_OPEN_TIME = 99999.0;

// What formatting string to use when printing to the chatbox
#define PRINT_PREFIX 	"\x05[DLR] \x01"


/// SOUNDS AND OTHER
/// PRECACHE DATA

#define SOUND_CLASS_SELECTED "ui/pickup_misc42.wav" /**< What sound to play when a class is selected. Do not include "sounds/" prefix. */
#define SOUND_DROP_BOMB "ui/beep22.wav"

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
	Float:LastDropTime
};

// Stores client plugin data
new ClientData[MAXPLAYERS+1][PLAYERDATA];

// Rapid fire variables
new g_iRI[MAXPLAYERS+1] = { -1 }, g_iRC, g_iEi[MAXPLAYERS+1] = { -1 }, Float:g_fNT[MAXPLAYERS+1] = { -1.0 }, g_iNPA = -1, g_oAW = -1;

// Speed vars
//new g_ioLMV;

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

new g_CollisionOffset;

// Max classes
new Handle:MAX_SOLDIER;
new Handle:MAX_ATHLETE;
new Handle:MAX_MEDIC;
new Handle:MAX_SABOTEUR;
new Handle:MAX_SNIPER;
new Handle:MAX_ENGINEER;
new Handle:MAX_BRAWLER;

// Everyone
new Handle:SOLDIER_HEALTH;
new Handle:ATHLETE_HEALTH;
new Handle:MEDIC_HEALTH;
new Handle:SABOTEUR_HEALTH;
new Handle:SNIPER_HEALTH;
new Handle:ENGINEER_HEALTH;
new Handle:BRAWLER_HEALTH;

// Soldier
new Handle:SOLDIER_FIRE_RATE;

// Athlete
//new Handle:ATHLETE_SPEED;
new Handle:ATHLETE_JUMP_VEL;

// Medic
new Handle:MEDIC_HEAL_DIST;
new Handle:MEDIC_HEALTH_VALUE;
new Handle:MEDIC_MAX_DEFIBS;
new Handle:MEDIC_HEALTH_INTERVAL;

// Saboteur
new Handle:SABOTEUR_INVISIBLE_TIME;
new Handle:SABOTEUR_BOMB_ACTIVATE;
new Handle:SABOTEUR_BOMB_RADIUS;
new Handle:SABOTEUR_MAX_BOMBS;
new Handle:SABOTEUR_BOMB_DAMAGE_SURV;
new Handle:SABOTEUR_BOMB_DAMAGE_INF;
new Handle:SABOTEUR_BOMB_POWER;

// Sniper
new Handle:SNIPER_DAMAGE;
//new Handle:SNIPER_DAMAGE_RATIO;
//new Handle:SNIPER_DAMAGE_CRITICAL_RATIO;
//new Handle:SNIPER_DAMAGE_CRITICAL_CHANCE;
new Handle:SNIPER_RELOAD_RATIO;

// Engineer
new Handle:ENGINEER_MAX_BUILDS;
new Handle:MAX_ENGINEER_BUILD_RANGE;

// Saboteur, Engineer, Medic
new Handle:MINIMUM_DROP_INTERVAL;

// Saferoom checks for saboteur
new bool:g_bInSaferoom[MAXPLAYERS+1] = false;
new Float:g_SpawnPos[MAXPLAYERS+1][3];

// Last class viewed
new LastChosenClass[MAXPLAYERS+1];

// Last class taken
new LastClassConfirmed[MAXPLAYERS+1];


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
		new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
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
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, iValue);
	
	CreateTimer(0.1, TimerSetClientTempHealth, hPack, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerSetClientTempHealth(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new client = ReadPackCell(hPack);
	new iValue = ReadPackCell(hPack);
	CloseHandle(hPack);
	
	if(!client
    || !IsValidEntity(client)
    || !IsClientInGame(client)
	|| !IsPlayerAlive(client)
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
	new Handle:sdkDetonateFire;
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
		CloseHandle(sdkDetonateFire);
		return;
	}
	new Float:vec[3];
	SDKCall(sdkDetonateFire, pos, vec, vec, vec, owner);
	CloseHandle(sdkDetonateFire);
}

stock DealDamage(iVictim, iAttacker, Float:flAmount, iType = 0)
{
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, iVictim);
	WritePackCell(hPack, iAttacker);
	WritePackFloat(hPack, flAmount);
	WritePackCell(hPack, iType);
	CreateTimer(0.1, timerHurtEntity, hPack);
}

public Action:timerHurtEntity(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	new Float:amount = ReadPackFloat(pack);
	new type = ReadPackCell(pack);
	CloseHandle(pack);
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
	new Float:power = GetConVarFloat(SABOTEUR_BOMB_POWER);
	new iDamageSurv = GetConVarInt(SABOTEUR_BOMB_DAMAGE_SURV);
	new iDamageInf = GetConVarInt(SABOTEUR_BOMB_DAMAGE_INF);
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
	
	DetonateMolotov(expPos, attacker);
	
	for(new i = 1; i <= 2; i++)
		DetonateMolotov(expPos, attacker);
	
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
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exTrace);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	WritePackCell(pack2, exHurt);
	CreateTimer(6.0, TimerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, exTrace);
	WritePackCell(pack, exHurt);
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
					DealDamage(i, attacker, iDamageSurv, 8);
				else
					DealDamage(i, attacker, iDamageInf, 8);
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

public Action:TimerStopFire(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:TimerDeleteParticles(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 7; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	CloseHandle(pack);
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
	CreateTimer(duration, TimerStopAndRemoveParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerStopAndRemoveParticle(Handle:timer, any:entity)
{
	if (entity > 0 && IsValidEntity(entity))
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
	//g_ioLMV = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue");
	g_ioPR = FindSendPropInfo("CBaseCombatWeapon", "m_flPlaybackRate");
	g_ioNA = FindSendPropInfo("CTerrorPlayer", "m_flNextAttack");
	g_ioTI = FindSendPropInfo("CTerrorGun", "m_flTimeWeaponIdle");
	g_iSSD = FindSendPropInfo("CBaseShotgun", "m_reloadStartDuration");
	g_iSID = FindSendPropInfo("CBaseShotgun", "m_reloadInsertDuration");
	g_iSED = FindSendPropInfo("CBaseShotgun", "m_reloadEndDuration");
	g_iSRS = FindSendPropInfo("CBaseShotgun", "m_reloadState");

	g_CollisionOffset = FindSendPropInfo( "CBaseEntity", "m_CollisionGroup" );
	
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

	HookEvent("chair_charged", Event_ChairCharged);
	
	// Concommands
	RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
	
	// Convars
	MAX_SOLDIER = CreateConVar("talents_soldier_max", "1", "Max number of soldiers", FCVAR_PLUGIN);
	MAX_ATHLETE = CreateConVar("talents_athelete_max", "1", "Max number of athletes", FCVAR_PLUGIN);
	MAX_MEDIC = CreateConVar("talents_medic_max", "1", "Max number of medics", FCVAR_PLUGIN);
	MAX_SABOTEUR = CreateConVar("talents_saboteur_max", "1", "Max number of saboteurs", FCVAR_PLUGIN);
	MAX_SNIPER = CreateConVar("talents_sniper_max", "1", "Max number of snipers", FCVAR_PLUGIN);
	MAX_ENGINEER = CreateConVar("talents_engineer_max", "1", "Max number of engineers", FCVAR_PLUGIN);
	MAX_BRAWLER = CreateConVar("talents_brawler_max", "1", "Max number of brawlers", FCVAR_PLUGIN);
	
	SOLDIER_HEALTH = CreateConVar("talents_soldier_health", "300", "How much health a soldier should have", FCVAR_PLUGIN);
	ATHLETE_HEALTH = CreateConVar("talents_athelete_health", "100", "How much health an athlete should have", FCVAR_PLUGIN);
	MEDIC_HEALTH = CreateConVar("talents_medic_health_start", "120", "How much health a medic should have", FCVAR_PLUGIN);
	SABOTEUR_HEALTH = CreateConVar("talents_saboteur_health", "140", "How much health a saboteur should have", FCVAR_PLUGIN);
	SNIPER_HEALTH = CreateConVar("talents_sniper_health", "300", "How much health a sniper should have", FCVAR_PLUGIN);
	ENGINEER_HEALTH = CreateConVar("talents_engineer_health", "125", "How much health a engineer should have", FCVAR_PLUGIN);
	BRAWLER_HEALTH = CreateConVar("talents_brawler_health", "500", "How much health a brawler should have", FCVAR_PLUGIN);
	
	
	SOLDIER_FIRE_RATE = CreateConVar("talents_soldier_fire_rate", "0.6666", "How fast the soldier should fire. Lower values = faster", FCVAR_PLUGIN, true, 0.2);

	//ATHLETE_SPEED = CreateConVar("talents_athlete_speed", "1.35", "How fast soldier should run. A value of 1.0 = normal speed", FCVAR_PLUGIN);
	ATHLETE_JUMP_VEL = CreateConVar("talents_athlete_jump", "450.0", "How high a soldier should be able to jump. Make this higher to make them jump higher, or 0.0 for normal height", FCVAR_PLUGIN);

	MEDIC_HEAL_DIST = CreateConVar("talents_medic_heal_dist", "256.0", "How close other survivors have to be to heal. Larger values = larger radius", FCVAR_PLUGIN);
	MEDIC_HEALTH_VALUE = CreateConVar("talents_medic_health", "10", "How much health to restore", FCVAR_PLUGIN);
	MEDIC_MAX_DEFIBS = CreateConVar("talents_medic_max_defibs", "2", "How many defibs the medic can drop", FCVAR_PLUGIN);
	MEDIC_HEALTH_INTERVAL = CreateConVar("talents_medic_health_interval", "3.0", "How often to heal players within range", FCVAR_PLUGIN);

	SABOTEUR_INVISIBLE_TIME = CreateConVar("talents_saboteur_invis_time", "15.0", "How long it takes for the saboteur to become invisible", FCVAR_PLUGIN);
	SABOTEUR_BOMB_ACTIVATE = CreateConVar("talents_saboteur_bomb_activate", "5.0", "How long before the dropped bomb becomes sensitive to motion", FCVAR_PLUGIN);
	SABOTEUR_BOMB_RADIUS = CreateConVar("talents_saboteur_bomb_radius", "128.0", "Radius of bomb motion detection", FCVAR_PLUGIN);
	SABOTEUR_MAX_BOMBS = CreateConVar("talents_saboteur_max_bombs", "4", "How many bombs a saboteur can drop per round", FCVAR_PLUGIN);
	SABOTEUR_BOMB_DAMAGE_SURV = CreateConVar("talents_saboteur_bomb_dmg_surv", "30", "How much damage a bomb does to survivors", FCVAR_PLUGIN);
	SABOTEUR_BOMB_DAMAGE_INF = CreateConVar("talents_saboteur_bomb_dmg_inf", "300", "How much damage a bomb does to infected", FCVAR_PLUGIN);
	SABOTEUR_BOMB_POWER = CreateConVar("talents_saboteur_bomb_power", "10.0", "How much blast power a bomb has. Higher values will throw survivors farther away", FCVAR_PLUGIN);

	//SNIPER_DAMAGE_RATIO = CreateConVar("talents_sniper_dmg_ratio", "1.5", "How many more times sniper class does damage", FCVAR_PLUGIN);
	//SNIPER_DAMAGE_CRITICAL_CHANCE = CreateConVar("talents_sniper_dmg_critical_chance", "25", "Percent chance that damage will be critical", FCVAR_PLUGIN);
	//SNIPER_DAMAGE_CRITICAL_RATIO = CreateConVar("talents_sniper_dmg_critical_ratio", "3.0", "Critical damage ratio", FCVAR_PLUGIN);
	SNIPER_DAMAGE = CreateConVar("talents_sniper_dmg", "5", "How much bonus damage a Sniper does", FCVAR_PLUGIN);
	SNIPER_RELOAD_RATIO = CreateConVar("talents_sniper_reload_ratio", "0.44", "Ratio for how fast a Sniper should be able to reload", FCVAR_PLUGIN);

	ENGINEER_MAX_BUILDS = CreateConVar("talents_engineer_max_builds", "4", "How many times an engineer can build per round", FCVAR_PLUGIN);
	MAX_ENGINEER_BUILD_RANGE = CreateConVar("talents_engineer_build_range", "120.0", "Maximum distance away an object can be built by the engineer", FCVAR_PLUGIN);
	
	MINIMUM_DROP_INTERVAL = CreateConVar("talents_drop_interval", "30.0", "Time before an engineer, medic, or saboteur can drop another item", FCVAR_PLUGIN);
	
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

public Event_PlayerTeam(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new team = GetEventInt(hEvent, "team");
	
	if (team == 2 && LastClassConfirmed[client] != 0)
	{
		ClientData[client][PLAYERDATA:ChosenClass] = LastClassConfirmed[client];
		PrintToChat(client, "You are currently a \x04%s", MENU_OPTIONS[LastClassConfirmed[client]]);
	}
}

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		ResetClientVariables(i);
		LastClassConfirmed[i] = 0;
	}
	
	RndSession++;
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
	
	// Particles
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(EFIRE_PARTICLE);
	PrecacheParticle(MEDIC_GLOW);
	
	// Cache
	ClearCache();
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
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
}

public Action:TimerLoadClient(Handle:hTimer, any:client)
{
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
	CreatePlayerClassMenu(client);
}

public Action:TimerThink(Handle:hTimer, any:client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return Plugin_Stop;
	
	new flags = GetEntityFlags(client);
	
	if (IsHanging(client) || IsIncapacitated(client) || FindAttacker(client) > 0 || IsClientOnLadder(client) || !(flags & FL_ONGROUND) || GetClientWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
		return Plugin_Continue;
	
	new buttons = GetClientButtons(client);
	new bool:CanDrop = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= GetConVarFloat(MINIMUM_DROP_INTERVAL);
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	switch (ClientData[client][PLAYERDATA:ChosenClass])
	{
		//case ATHLETE:
		//	SetEntDataFloat(client, g_ioLMV, GetConVarFloat(ATHLETE_SPEED), true);
		
		case SABOTEUR:
		{
			if (buttons & IN_DUCK && (GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= GetConVarFloat(SABOTEUR_INVISIBLE_TIME))
				SetEntityRenderFx(client, RENDERFX_FADE_SLOW);
			else
				SetEntityRenderFx(client, RENDERFX_NONE);
			
			if (buttons & IN_SPEED && CanDrop && ClientData[client][PLAYERDATA:ItemsBuilt] < GetConVarInt(SABOTEUR_MAX_BOMBS))
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
			if (buttons & IN_SPEED && CanDrop && ClientData[client][PLAYERDATA:ItemsBuilt] < GetConVarInt(MEDIC_MAX_DEFIBS))
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
			if (buttons & IN_SPEED && CanDrop && ClientData[client][PLAYERDATA:ItemsBuilt] < GetConVarInt(ENGINEER_MAX_BUILDS))
			{
				CreatePlayerEngineerMenu(client);
				ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
			}
		}
	}
	
	return Plugin_Continue;
}

CreatePlayerEngineerMenu(client)
{
	if (!client)
		return false;
	
	new Handle:hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerEngineerMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Engineer:");
	DrawPanelItem(hPanel, "Ammo Pile");
	DrawPanelItem(hPanel, "Machine Gun");
	DrawPanelItem(hPanel, "Laser Sights");
	DrawPanelItem(hPanel, "Frag Rounds");
	DrawPanelItem(hPanel, "Incendiary Rounds");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectEngineerItem, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

public PanelHandler_SelectEngineerItem(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 5 )
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
		CloseHandle(trace);
		
		if (GetVectorDistance(endPos, vPos) <= GetConVarFloat(MAX_ENGINEER_BUILD_RANGE))
		{
			vAng[0] = 0.0;
			vAng[2] = 0.0;
			
			switch(type) {
				case 0: {
					new ammo = CreateEntityByName("weapon_ammo_spawn");
					DispatchSpawn(ammo);
					TeleportEntity(ammo, endPos, NULL_VECTOR, NULL_VECTOR);
				}
				case 1:{
					ClientCommand(client, "sm_dlrpmkai");
					}
				case 2: {
					new upgrade = CreateEntityByName("upgrade_laser_sight");
					DispatchKeyValue( upgrade, "count", "5" );
					DispatchKeyValue( upgrade, "spawnflags", "2" );
					DispatchSpawn(upgrade);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
				}
				case 3: {
					new upgrade = CreateEntityByName("upgrade_ammo_explosive");
					DispatchKeyValue( upgrade, "count", "5" );
					DispatchKeyValue( upgrade, "spawnflags", "2" );
					DispatchSpawn(upgrade);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
				}
				case 4: {
					new upgrade = CreateEntityByName("upgrade_ammo_incendiary");
					DispatchKeyValue( upgrade, "count", "5" );
					DispatchKeyValue( upgrade, "spawnflags", "2" );
					DispatchSpawn(upgrade);
					TeleportEntity(upgrade, endPos, NULL_VECTOR, NULL_VECTOR);
				}
				default: {
					CloseHandle( trace );
					return;
				}
			}
			
			ClientData[client][PLAYERDATA:ItemsBuilt]++;
			ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
		}
		else
			PrintToChat(client, "%sCould not place the item because you were looking too far away.", PRINT_PREFIX);
	}
	else
		CloseHandle(trace);
}

SpawnMiniGun(Float:vAng[3], Float:vPos[3])
{
	new entity = CreateEntityByName("prop_minigun");
	SetEntityModel(entity, ENGINEER_MACHINE_GUN);
	DispatchKeyValueFloat(entity, "MaxPitch", 360.00);
	DispatchKeyValueFloat(entity, "MinPitch", -360.00);
	DispatchKeyValueFloat(entity, "MaxYaw", 90.00);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	SetEntData( entity, g_CollisionOffset, 1, 4, true );

	DispatchSpawn(entity);
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
		return false;
	return true;
}

public Action:SetTransmitInvisible(client, entity)
{
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:SABOTEUR && ((GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= (GetConVarFloat(SABOTEUR_INVISIBLE_TIME) + 5.0)) && client != entity)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

DropBomb(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Handle:hPack = CreateDataPack();
	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, client);
	WritePackCell(hPack, RndSession);
	CreateTimer(GetConVarFloat(SABOTEUR_BOMB_ACTIVATE), TimerActivateBomb, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	
	EmitSoundToAll(SOUND_DROP_BOMB);
	
	PrintToChat(client, "%sYou dropped a \x04bomb", PRINT_PREFIX);
}

public Action:TimerActivateBomb(Handle:hTimer, Handle:hPack)
{
	CreateTimer(0.3, TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action:TimerCheckBombSensors(Handle:hTimer, Handle:hPack)
{
	new Float:pos[3];
	decl Float:clientpos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	new owner = ReadPackCell(hPack);
	new session = ReadPackCell(hPack);
	
	if (session != RndSession)
		return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsGhost(client))
			continue;

		GetClientAbsOrigin(client, clientpos);
		
		if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
		{
			PrintToChatAll("%s\x03%N\x01's \x04bomb \x01detonated!", PRINT_PREFIX, owner);
			CreateExplosion(pos, owner, false);
			CloseHandle(hPack);
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsServerProcessing())
		return Plugin_Continue;
	
	if (victim && attacker && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
	{
		if (ClientData[attacker][PLAYERDATA:ChosenClass] == _:SNIPER && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			/*if (GetConVarInt(SNIPER_DAMAGE_CRITICAL_CHANCE) <= GetRandomInt(1, 100))
				damage *= GetConVarFloat(SNIPER_DAMAGE_CRITICAL_RATIO);
			else
				damage *= GetConVarFloat(SNIPER_DAMAGE_RATIO);*/
			damage += GetConVarInt(SNIPER_DAMAGE);
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

CreatePlayerClassMenu(client)
{
	if (!client)
		return false;
	
	new Handle:hPanel;
	decl String:buffer[256];
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Select Your Class");
	
	for (new i = 1; i < _:MAXCLASSES; i++)
	{
		if( GetMaxWithClass(i) >= 0 )
			Format(buffer, sizeof(buffer), "%i/%i %s", CountPlayersWithClass(i), GetMaxWithClass(i),  MENU_OPTIONS[i]);
		else
			Format(buffer, sizeof(buffer), "%s", MENU_OPTIONS[i]);
		DrawPanelItem(hPanel, buffer);
	}
	
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectClass, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}

DrawConfirmPanel(client, chosenClass)
{
	if (!client || chosenClass >= _:MAXCLASSES)
		return false;
	
	LastChosenClass[client] = chosenClass;
	
	new Handle:hPanel;
	decl String:buffer[256];
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreatePlayerClassMenu");
		return false;
	}
	
	Format(buffer, sizeof(buffer), "Select the %s talent?", MENU_OPTIONS[chosenClass]);
	SetPanelTitle(hPanel, buffer);
	
	
	DrawPanelItem(hPanel, "Yes");
	DrawPanelItem(hPanel, "No");
	
	SendPanelToClient(hPanel, client, PanelHandler_ConfirmClass, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
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

public PanelHandler_SelectClass(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!client || param >= _:MAXCLASSES)
				return;

			if( GetMaxWithClass( param ) >= 0 && CountPlayersWithClass( param ) >= GetMaxWithClass( param ) && ClientData[client][PLAYERDATA:ChosenClass] != param ) {
				PrintToChat( client, "%sThe \x04%s\x01 class is full, please choose another.", PRINT_PREFIX, MENU_OPTIONS[ param ] );
				CreatePlayerClassMenu( client );
			} else
				DrawConfirmPanel(client, param);
		}
	}
}

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
			MaxPossibleHP = GetConVarInt(SOLDIER_HEALTH);
		}
		
		case MEDIC:
		{
			CreateTimer(GetConVarFloat(MEDIC_HEALTH_INTERVAL), TimerDetectHealthChanges, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			MaxPossibleHP = GetConVarInt(MEDIC_HEALTH);
		}
		
		case ATHLETE:
		{
			MaxPossibleHP = GetConVarInt(ATHLETE_HEALTH);
		}
		
		case SNIPER:
		{
			MaxPossibleHP = GetConVarInt(SNIPER_HEALTH);
		}
		
		case ENGINEER:
		{
			MaxPossibleHP = GetConVarInt(ENGINEER_HEALTH);
		}
		
		case SABOTEUR:
		{
			MaxPossibleHP = GetConVarInt(SABOTEUR_HEALTH);
		}
		
		case BRAWLER:
		{
			MaxPossibleHP = GetConVarInt(BRAWLER_HEALTH);
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
	
	if (ClientData[client][PLAYERDATA:ChosenClass] != _:NONE)
	{
		PrintToChat(client, "%sYou have already chosen a class this round.", PRINT_PREFIX);
		return;
	}
	
	CreatePlayerClassMenu(client);
}

public Action:TimerDetectHealthChanges(Handle:hTimer, any:client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| GetClientTeam(client) != 2
		|| ClientData[client][PLAYERDATA:ChosenClass] != _:MEDIC)
			return Plugin_Stop;
	
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
				
				if (GetVectorDistance(pos, tpos) <= GetConVarFloat(MEDIC_HEAL_DIST))
				{
					// pre-heal set values
					new MaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
					new TempHealth = GetClientTempHealth(i);
					
					SetEntityHealth(i, GetClientHealth(i) + GetConVarInt(MEDIC_HEALTH_VALUE));
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
			fNTC = ( fNTR - fGT ) * GetConVarFloat(SOLDIER_FIRE_RATE) + fGT;
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

public Event_PlayerSpawn(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client > 0 && IsValidEntity(client) && IsClientInGame(client))
	{
		GetClientAbsOrigin(client, g_SpawnPos[client]);
		
		if (GetClientTeam(client) == 2)
		{
			CreateTimer(0.3, TimerLoadClient, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, TimerThink, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			if (LastClassConfirmed[client] != 0)
				ClientData[client][PLAYERDATA:ChosenClass] = LastClassConfirmed[client];
			else
				CreateTimer(1.0, CreatePlayerClassMenuDelay, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		CreateTimer(0.3, TimerLoadGlobal, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	RebuildCache();
}

public Event_PlayerHurt(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
}

public Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
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
	
	if (flags & FL_ONGROUND)
	{
		if (buttons & IN_JUMP && ClientData[client][PLAYERDATA:ChosenClass] == _:ATHLETE)
			PushEntity(client, Float:{-90.0,0.0,0.0}, GetConVarFloat(ATHLETE_JUMP_VEL));
	}
	
	ClientData[client][PLAYERDATA:LastButtons] = buttons;
	
	return Plugin_Continue;
}

public Event_RelSniperClass(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
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
		new Float:fRLRat = GetConVarFloat(SNIPER_RELOAD_RATIO);
		new Float:fNTC = (GetEntDataFloat(weapon, g_iNPA) - flGT) * fRLRat;
		new Float:NA = fNTC + flGT;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
		SetEntDataFloat(weapon, g_ioTI, NA, true);
		SetEntDataFloat(weapon, g_iNPA, NA, true);
		SetEntDataFloat(client, g_ioNA, NA, true);
		
		CreateTimer(fNTC, SniperRelFireEnd, weapon);
	}
	else
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);
		
		if (StrContains(bNetCl, "pumpshotgun", false) != -1)
		{
			WritePackFloat(hPack, 0.393939);
			WritePackFloat(hPack, 0.472999);
			WritePackFloat(hPack, 0.875000);
			
			CreateTimer(0.1, SniperPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "autoshotgun", false) != -1)
		{
			WritePackFloat(hPack, 0.416666);
			WritePackFloat(hPack, 0.395999);
			WritePackFloat(hPack, 1.000000);
			
			CreateTimer(0.1, SniperPumpShotReload, hPack);
		}
		else
			CloseHandle(hPack);
	}
}

public Action:SniperRelFireEnd(Handle:timer, any:weapon)
{
	if (weapon <= 0 || !IsValidEntity(weapon))
		return Plugin_Stop;
	
	SetEntDataFloat(weapon, g_ioPR, 1.0, true);
	
	return Plugin_Stop;
}

public Action:SniperPumpShotReload(Handle:timer, Handle:hOldPack)
{
	ResetPack(hOldPack);
	new weapon = ReadPackCell(hOldPack);
	new Float:fRLRat = GetConVarFloat(SNIPER_RELOAD_RATIO);
	
	SetEntDataFloat(weapon,	g_iSSD,	ReadPackFloat(hOldPack) * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSID,	ReadPackFloat(hOldPack) * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSED, ReadPackFloat(hOldPack) * fRLRat,	true);
	SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
	
	CloseHandle(hOldPack);
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, weapon);
	
	if (GetEntData(weapon, g_iSRS) != 2)
	{
		WritePackFloat(hPack, 0.2);
		CreateTimer(0.3, SniperShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		WritePackFloat(hPack, 1.0);
		CreateTimer(0.3, SniperShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action:SniperShotCalculate(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);
	new weapon = ReadPackCell(hPack);
	new Float:addMod = ReadPackFloat(hPack);
	
	if (weapon <= 0 || !IsValidEntity(weapon))
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	
	if (GetEntData(weapon, g_iSRS) == 0)
	{
		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0, true);
		SetEntDataFloat(GetEntPropEnt(weapon, Prop_Data, "m_hOwner"), g_ioNA, flNextTime, true);
		SetEntDataFloat(weapon,	g_ioTI, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNPA, flNextTime, true);
		
		CloseHandle(hPack);
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Event_EnterSaferoom(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = true;
}

public Event_LeftSaferoom(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bInSaferoom[client] = false;
}




public Plugin:myinfo =
{
	name = "Talents Plugin",
	author = "DLR / Neil",
	description = "Incorporates Survivor Classes",
	version = "v1.0",
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
			return GetConVarInt( MAX_SOLDIER );
		case ATHLETE:
			return GetConVarInt( MAX_ATHLETE );
		case MEDIC:
			return GetConVarInt( MAX_MEDIC );
		case SABOTEUR:
			return GetConVarInt( MAX_SABOTEUR );
		case SNIPER:
			return GetConVarInt( MAX_SNIPER );
		case ENGINEER:
			return GetConVarInt( MAX_ENGINEER );
		case BRAWLER:
			return GetConVarInt( MAX_BRAWLER );
		default:
			return -1;
	}

	return -1;
}

public Event_ChairCharged( Handle:hEvent, String:sName[], bool:bDontBroadcast ) {
	/*new client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );

	PrintToChatAll( "CHAIRCHARGED %i", client );

	new ent = GetEntPropEnt( client, Prop_Send, "m_hUseEntity" );

	if( ent != INVALID_ENT_REFERENCE ) {
		AcceptEntityInput( ent, "use", client );
	}*/
}