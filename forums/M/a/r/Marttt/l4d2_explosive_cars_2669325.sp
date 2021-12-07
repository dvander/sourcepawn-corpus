#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GETVERSION "1.0.1h"
#define ARRAY_SIZE 5000

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0

static const char FIRE_PARTICLE[] = 		"gas_explosion_ground_fire";
static const char EXPLOSION_PARTICLE[] = 	"weapon_pipebomb";
static const char EXPLOSION_PARTICLE2[] = "weapon_grenade_explosion";
static const char EXPLOSION_PARTICLE3[] = "explosion_huge_b";
static const char EXPLOSION_SOUND[] = 	"ambient/explosions/explode_1.wav";
static const char EXPLOSION_SOUND2[] = 	"ambient/explosions/explode_2.wav";
static const char EXPLOSION_SOUND3[] = 	"ambient/explosions/explode_3.wav";
static const char DAMAGE_WHITE_SMOKE[] = 	"minigun_overheat_smoke";
static const char DAMAGE_BLACK_SMOKE[] = 	"smoke_burning_engine_01";
static const char DAMAGE_FIRE_SMALL[] = 	"burning_engine_01";
static const char DAMAGE_FIRE_HUGE[] = 	"fire_window_hotel2";
static const char FIRE_SOUND[] = 			"ambient/fire/fire_med_loop1.wav";

bool g_bLowWreck[ARRAY_SIZE] = false;
bool g_bMidWreck[ARRAY_SIZE] = false;
bool g_bHighWreck[ARRAY_SIZE] = false;
bool g_bCritWreck[ARRAY_SIZE] = false;
bool g_bExploded[ARRAY_SIZE] = false;
bool g_bHooked[ARRAY_SIZE] = false;
int g_iEntityDamage[ARRAY_SIZE] = 0;
int g_iParticle[ARRAY_SIZE] = -1;

bool g_bDisabled = false;

Handle g_hGameConf = INVALID_HANDLE;
Handle sdkCallPushPlayer = INVALID_HANDLE;
ConVar g_cvarMaxHealth;
ConVar g_cvarRadius;
ConVar g_cvarPower;
ConVar g_cvarTrace;
ConVar g_cvarPanic;
ConVar g_cvarPanicChance;
ConVar g_cvarInfected;
ConVar g_cvarTankDamage;
ConVar g_cvarBurnTimeout;
ConVar g_cvarUnload;
ConVar g_cvarExplosionDmg;
ConVar g_cvarFireDmgInterval;
ConVar g_cvarDamage;

public Plugin myinfo = 
{
	name = "[L4D2] Explosive Cars",
	author = "honorcode23,Fixed: kochiurun119",
	description = "Cars explode after they take some damage",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=138644"
}

public void OnPluginStart()
{
	//Left 4 dead 2 only
	char sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Explosive Cars supports Left 4 dead 2 only!");
	}
	
	//Convars
	CreateConVar("l4d2_explosive_cars_version", GETVERSION, "Version of the [L4D2] Explosive Cars plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarMaxHealth = CreateConVar("l4d2_explosive_cars_health", "5000", "Maximum health of the cars", FCVAR_NONE);
	g_cvarRadius = CreateConVar("l4d2_explosive_cars_radius", "420", "Maximum radius of the explosion", FCVAR_NONE);
	g_cvarPower = CreateConVar("l4d2_explosive_cars_power", "300", "Power of the explosion when the car explodes", FCVAR_NONE);
	g_cvarDamage = CreateConVar("l4d2_explosive_cars_damage", "100", "Damage made by the explosion", FCVAR_NONE);
	g_cvarTrace = CreateConVar("l4d2_explosive_cars_trace", "25", "Time before the fire trace left by the explosion expires", FCVAR_NONE);
	g_cvarPanic = CreateConVar("l4d2_explosive_cars_panic", "1", "Should the car explosion cause a panic event? (1: Yes 0: No)", FCVAR_NONE);
	g_cvarPanicChance = CreateConVar("l4d2_explosive_cars_panic_chance", "1", "Chance that the cars explosion might call a horde (1 / CVAR) [1: Always]", FCVAR_NONE);
	g_cvarInfected = CreateConVar("l4d2_explosive_cars_infected", "1", "Should infected trigger the car explosion? (1: Yes 0: No)", FCVAR_NONE);
	g_cvarTankDamage = CreateConVar("l4d2_explosive_cars_tank", "0", "How much damage do the tank deal to the cars? (0: Default, which is 999 from the engine)", FCVAR_NONE);
	g_cvarBurnTimeout = CreateConVar("l4d2_explosive_cars_burntime", "0", "Time to wait before stopping the fire on the exploded car (0: Don't stop)", FCVAR_NONE);
	g_cvarUnload = CreateConVar("l4d2_explosive_cars_unload", "none", "On which maps should the plugin disable itself? (Example: c5m3_cemetery, c5m5_bridge, cmdd_custom)", FCVAR_NONE);
	g_cvarExplosionDmg = CreateConVar("l4d2_explosive_cars_explosion_damage", "1", "Should cars get damaged by another car's explosion?", FCVAR_NONE);
	g_cvarFireDmgInterval = CreateConVar("l4d2_explosive_cars_trace_interval", "0.4", "How often should the fire trace left by the explosion hurt?", FCVAR_NONE);
	
	AutoExecConfig(true, "l4d2_explosive_cars");
	
	//Events
	HookEvent("round_start_post_nav", Event_RoundStart);
	
	//Signatures
	g_hGameConf = LoadGameConfigFile("l4d2explosivecars");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Unable to find the signatures file. Make sure it is on the 'gamedata' folder");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}
	FindMapCars();
}

public void OnMapStart()
{
	g_bDisabled = false;
	char sCurrentMap[64], sCvarMap[256];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	GetConVarString(g_cvarUnload, sCvarMap, sizeof(sCvarMap));
	if(StrContains(sCvarMap, sCurrentMap) >= 0)
	{
		LogMessage("[Unload] Plugin disabled for this map");
		g_bDisabled = true;
	}
	if(!IsModelPrecached("sprites/muzzleflash4.vmt"))
	{
		PrecacheModel("sprites/muzzleflash4.vmt");
	}
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(FIRE_PARTICLE);
	PrecacheParticle(DAMAGE_WHITE_SMOKE);
	PrecacheParticle(DAMAGE_BLACK_SMOKE);
	PrecacheParticle(DAMAGE_FIRE_SMALL);
	PrecacheParticle(DAMAGE_FIRE_HUGE);
}

public void Event_RoundStart(Event event, char[] event_name, bool dontBroadcast)
{
	if(g_bDisabled)
	{
		return;
	}
	for(int i=1; i<ARRAY_SIZE; i++)
	{
		g_iEntityDamage[i] = 0;
		g_bLowWreck[i] = false;
		g_bMidWreck[i] = false;
		g_bHighWreck[i] = false;
		g_bCritWreck[i] = false;
		g_bHooked[i] = false;
		g_bExploded[i] = false;
		g_iParticle[i] = -1;
	}
	FindMapCars();
}

//Thanks to AtomicStryker
static void FindMapCars()
{
	if(g_bDisabled)
		return;
	
	int maxEnts = GetMaxEntities();
	char classname[128], model[256];
	
	for (int i = MaxClients; i < maxEnts; i++)
	{
		if (!IsValidEdict(i)) continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model))
		
		if(StrEqual(classname, "prop_physics")
		|| StrEqual(classname, "prop_physics_override"))
		{
			
			if(StrContains(model, "vehicle", false) != -1 && !g_bHooked[i])
			{
				g_bHooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", i, classname);
			}
			else if (
				StrEqual(model, "models/props/cs_assault/forklift.mdl", false) ||
				StrEqual(model, "models/props_fairgrounds/bumpercar.mdl", false)
				)
			{
				g_bHooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", i, classname);
			}
		}
		else if(StrEqual(classname, "prop_car_alarm"))
		{
			if(StrContains(model, "vehicle", false) != -1 && !g_bHooked[i])
			{
				g_bHooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", i, classname);
			}
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if(g_bDisabled)
	{
		return;
	}
	if(entity > 0 && entity < ARRAY_SIZE)
	{
		g_bHooked[entity] = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(g_bDisabled)
	{
		return;
	}
	if(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") && !g_bHooked[entity])
	{
		CreateTimer(0.1, timerCheckHook, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(StrEqual(classname, "prop_car_alarm") && !g_bHooked[entity])
	{
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		g_bHooked[entity] = true;
		DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", entity, classname);
	}
}

public Action timerCheckHook(Handle timer, any entity)
{
	if(g_bDisabled)
	{
		return;
	}
	if(IsValidEntity(entity))
	{
		char model[256];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model))
		if(StrContains(model, "vehicle", false) != -1)
		{
			SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			g_bHooked[entity] = true;
			DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i", entity);
		}
	}
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if(g_bDisabled)
	{
		return;
	}
	char attackerClass[256];
	GetEdictClassname(attacker, attackerClass, sizeof(attackerClass));
	
	char inflictorClass[256];
	GetEdictClassname(inflictor, inflictorClass, sizeof(inflictorClass));
	
	int MaxDamageHandle = GetConVarInt(g_cvarMaxHealth)/5;
	
	if(StrEqual(attackerClass, "weapon_melee"))
	{
		damage = 5.0;
	}
	else if(StrEqual(attackerClass, "env_explosion") && !GetConVarBool(g_cvarExplosionDmg))
	{
		damage = 3000.0;
	}
	else if (StrEqual(attackerClass, "player", false) && StrEqual(inflictorClass, "pipe_bomb_projectile", false))
	{
		damage = 3000.0;
	}
	else if (StrEqual(attackerClass, "player", false) && (StrEqual(inflictorClass, "inferno", false) || StrEqual(inflictorClass, "fire_cracker_blast", false)))
	{
		damage = 100.0;
	}
	else if((StrEqual(attackerClass, "player") && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 3) && !GetConVarBool(g_cvarInfected))
	{
		damage = 0.0;
	}
	else if(StrEqual(attackerClass, "tank_rock") || StrEqual(attackerClass, "weapon_tank_claw"))
	{
		if(!GetConVarBool(g_cvarInfected))
		{
			damage = 0.0;
		}
		float tank_damage = GetConVarFloat(g_cvarTankDamage)
		if(tank_damage > 0.0 && GetConVarBool(g_cvarInfected))
		{
			damage = tank_damage;
		}
	}
	
	g_iEntityDamage[victim] += RoundToFloor(damage);
	int tdamage = g_iEntityDamage[victim];
	//PrintHintTextToAll("%i damaged by <%s>(%i) for %f damage [%i | %i]", victim, attackerClass, attacker, damage, tdamage, GetConVarInt(g_cvarMaxHealth)); //TEST
	
	if(tdamage >= MaxDamageHandle && tdamage < MaxDamageHandle * 2 && !g_bLowWreck[victim])
	{
		AttachParticle(victim, DAMAGE_WHITE_SMOKE);
		g_bLowWreck = true;
	}
	else if(tdamage >= MaxDamageHandle * 2 && tdamage < MaxDamageHandle * 3 && !g_bMidWreck[victim])
	{
		AttachParticle(victim, DAMAGE_BLACK_SMOKE);
		g_bMidWreck = true;
	}
	else if(tdamage >= MaxDamageHandle * 3 && tdamage < MaxDamageHandle * 4 && !g_bHighWreck[victim])
	{
		if(!IsSoundPrecached(FIRE_SOUND))
		{
			PrecacheSound(FIRE_SOUND);
		}
		EmitSoundToAll(FIRE_SOUND, victim);
		AttachParticle(victim, DAMAGE_FIRE_SMALL);
		g_bHighWreck = true;
	}
	else if(tdamage >= MaxDamageHandle * 4 && tdamage < MaxDamageHandle * 5 && !g_bCritWreck[victim])
	{
		AttachParticle(victim, DAMAGE_FIRE_HUGE);
		g_bCritWreck = true;
	}
	
	else if(tdamage > MaxDamageHandle * 5 && !g_bExploded[victim])
	{
		g_bExploded[victim] = true;
		float carPos[3];
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", carPos);
		CreateExplosion(carPos);
		EditCar(victim);
		LaunchCar(victim);
	}
}

stock void EditCar(int car)
{
	SetEntityRenderColor(car, 51, 51, 51, 255);
	char sModel[256];
	GetEntPropString(car, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if(StrEqual(sModel, "models/props_vehicles/cara_82hatchback.mdl"))
	{
		if(!IsModelPrecached("models/props_vehicles/cara_82hatchback_wrecked.mdl"))
		{
			PrecacheModel("models/props_vehicles/cara_82hatchback_wrecked.mdl");
		}
		SetEntityModel(car, "models/props_vehicles/cara_82hatchback_wrecked.mdl");
	}
	else if(StrEqual(sModel, "models/props_vehicles/cara_95sedan.mdl"))
	{
		if(!IsModelPrecached("models/props_vehicles/cara_95sedan_wrecked.mdl"))
		{
			PrecacheModel("models/props_vehicles/cara_95sedan_wrecked.mdl");
		}
		SetEntityModel(car, "models/props_vehicles/cara_95sedan_wrecked.mdl");
	}
}

stock void LaunchCar(int car)
{
	if(g_bDisabled)
	{
		return;
	}
	float vel[3];
	GetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
	vel[0] += GetRandomFloat(50.0, 300.0);
	vel[1] += GetRandomFloat(50.0, 300.0);
	vel[2] += GetRandomFloat(1000.0, 2500.0);
	
	TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	CreateTimer(4.0, timerNormalVelocity, car, TIMER_FLAG_NO_MAPCHANGE);
	float burnTime = GetConVarFloat(g_cvarBurnTimeout);
	if(burnTime > 0.0)
	{
		CreateTimer(burnTime, timerRemoveCarFire, car, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action timerNormalVelocity(Handle timer, any car)
{
	if(g_bDisabled)
	{
		return;
	}
	if(IsValidEntity(car))
	{
		float vel[3];
		SetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
		TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	}
}

public Action timerRemoveCarFire(Handle timer, any car)
{
	if(g_bDisabled)
	{
		return;
	}
	int Particle = g_iParticle[car];
	if(Particle > 0 && IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
}

void CreateExplosion(float carPos[3])
{
	if(g_bDisabled)
	{
		return;
	}
	char sRadius[16], sPower[16], sDamage[11], sInterval[11];
	float flMxDistance = GetConVarFloat(g_cvarRadius);
	float power = GetConVarFloat(g_cvarPower);
	int iDamage = GetConVarInt(g_cvarDamage);
	float flInterval = GetConVarFloat(g_cvarFireDmgInterval);
	FloatToString(flInterval, sInterval, sizeof(sInterval));
	IntToString(GetConVarInt(g_cvarRadius), sRadius, sizeof(sRadius));
	IntToString(GetConVarInt(g_cvarPower), sPower, sizeof(sPower));
	IntToString(iDamage, sDamage, sizeof(sDamage));
	int exParticle2 = CreateEntityByName("info_particle_system");
	int exParticle3 = CreateEntityByName("info_particle_system");
	int exTrace = CreateEntityByName("info_particle_system");
	int exPhys = CreateEntityByName("env_physexplosion");
	int exHurt = CreateEntityByName("point_hurt");
	int exParticle = CreateEntityByName("info_particle_system");
	int exEntity = CreateEntityByName("env_explosion");
	/*int exPush = CreateEntityByName("point_push");*/
	
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
	DispatchKeyValue(exEntity, "iMagnitude", sDamage);
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
	DispatchKeyValue(exHurt, "DamageDelay", sInterval);
	DispatchKeyValue(exHurt, "Damage", "1");
	DispatchKeyValue(exHurt, "DamageType", "8");
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, carPos, NULL_VECTOR, NULL_VECTOR);
	
	switch(GetRandomInt(1, 3))
	{
		case 1:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND))
			{
				PrecacheSound(EXPLOSION_SOUND);
			}
			EmitSoundToAll(EXPLOSION_SOUND);
		}
		case 2:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND2))
			{
				PrecacheSound(EXPLOSION_SOUND2);
			}
			EmitSoundToAll(EXPLOSION_SOUND2);
		}
		case 3:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND3))
			{
				PrecacheSound(EXPLOSION_SOUND3);
			}
			EmitSoundToAll(EXPLOSION_SOUND3);
		}
	}
	
	if(GetConVarBool(g_cvarPanic))
	{
		int luck = GetConVarInt(g_cvarPanicChance);
		switch(GetRandomInt(1, luck))
		{
			case 1:
			{
				PanicEvent();
				PrintToChatAll("\x04[SM] \x03The car exploded and the infected heard the noise!");
			}
		}
	}
	
	//BOOM!
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	Handle pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exTrace);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	WritePackCell(pack2, exHurt);
	CreateTimer(GetConVarFloat(g_cvarTrace)+1.5, timerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	Handle pack = CreateDataPack();
	WritePackCell(pack, exTrace);
	WritePackCell(pack, exHurt);
	CreateTimer(GetConVarFloat(g_cvarTrace), timerStopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	float survivorPos[3], traceVec[3], resultingFling[3], currentVelVec[3];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 2)
		{
			continue;
		}

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		//Vector and radius distance calcs by AtomicStryker!
		if(GetVectorDistance(carPos, survivorPos) <= flMxDistance)
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

public Action timerStopFire(Handle timer, Handle pack)
{
	if(g_bDisabled)
	{
		return;
	}
	ResetPack(pack);
	int particle = ReadPackCell(pack);
	int hurt = ReadPackCell(pack);
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

public Action timerDeleteParticles(Handle timer, Handle pack)
{
	if(g_bDisabled)
	{
		return;
	}
	ResetPack(pack);
	
	int entity;
	for (int i = 1; i <= 7; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	CloseHandle(pack);
}

stock void FlingPlayer(int target, float vector[3], int attacker, float stunTime = 3.0)
{
	if(g_bDisabled)
	{
		return;
	}
	SDKCall(sdkCallPushPlayer, target, vector, 76, attacker, stunTime);
}

stock void PrecacheParticle(const char[] ParticleName)
{
	if(g_bDisabled)
	{
		return;
	}
	int Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, timerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action timerRemovePrecacheParticle(Handle timer, any Particle)
{
	if(g_bDisabled)
	{
		return;
	}
	if(IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
}

stock void AttachParticle(int car, const char[] Particle_Name)
{
	if(g_bDisabled)
	{
		return;
	}
	float carPos[3];
	char sName[64], sTargetName[64];
	int Particle = CreateEntityByName("info_particle_system");
	if(g_iParticle[car] > 0 && IsValidEntity(g_iParticle[car]))
	{
		AcceptEntityInput(g_iParticle[car], "Kill");
		g_iParticle[car] = -1;
	}
	g_iParticle[car] = Particle;
	GetEntPropVector(car, Prop_Data, "m_vecOrigin", carPos);
	TeleportEntity(Particle, carPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	
	int userid = car;
	Format(sName, sizeof(sName), "%d", userid+25);
	DispatchKeyValue(car, "targetname", sName);
	GetEntPropString(car, Prop_Data, "m_iName", sName, sizeof(sName));
	
	Format(sTargetName, sizeof(sTargetName), "%d", userid+1000);
	DispatchKeyValue(Particle, "targetname", sTargetName);
	DispatchKeyValue(Particle, "parentname", sName);
	DispatchSpawn(Particle);
	DispatchSpawn(Particle);
	SetVariantString(sName);
	AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
}

stock void PanicEvent()
{
	if(g_bDisabled)
	{
		return;
	}
	int Director = CreateEntityByName("info_director");
	DispatchSpawn(Director);
	AcceptEntityInput(Director, "ForcePanicEvent");
	AcceptEntityInput(Director, "Kill");
}

stock void DebugPrintToAll(const char[] format, any ...)
{
	if(g_bDisabled)
	{
		return;
	}
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[EC] %s", buffer);
	PrintToConsole(0, "[EC] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}


#if 0
//Stops a sound from all channels - Unused right now
stock void StopSoundPerm(int client, char[] sound)
{
	if(g_bDisabled)
	{
		return;
	}
	StopSound(client, SNDCHAN_AUTO, sound);
	StopSound(client, SNDCHAN_WEAPON, sound);
	StopSound(client, SNDCHAN_VOICE, sound);
	StopSound(client, SNDCHAN_ITEM, sound);
	StopSound(client, SNDCHAN_BODY, sound);
	StopSound(client, SNDCHAN_STREAM, sound);
	StopSound(client, SNDCHAN_VOICE_BASE, sound);
	StopSound(client, SNDCHAN_USER_BASE, sound);
}
#endif