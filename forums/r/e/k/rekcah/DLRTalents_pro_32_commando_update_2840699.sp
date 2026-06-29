#pragma semicolon 1
#pragma tabsize 0

//#pragma newdecls required 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


/**
 * CONFIGURABLE VARIABLES
 * Feel free to change the following code-related values.
 */

/// MENU AND UI RELATED STUFF

// This is what to display on the class selection menu.
static const char MENU_OPTIONS[][] =
{
	// What should be displayed if the player does not have a class?
	"None",
	// You can change how the menus display here.
	"Soldier",
	"Scout",
	"Medic",
	"Saboteur",
	"Commando",
	"Engineer",
	"Meat-Shield",
	"Sharpshooter",
	"Psychic",
	"Warper",//
	"DeathShot",
	"Boss-Slayer",//
	"Gambler",//
	"Flash",
	"Trapper",
	"Blocker",//
	"Penatrator",
	"Pyro",	//
	"Tesla",
	"Hazmat",//
	"Piper"//
};

static const char ClassTips[][] =
{
	//"\x04%N\x01 : class changed from \x05%s\x01 to \x05%s\x01"(DO NOT USE)
	//\x05[DLR] \x01
	//\x04%N\x01 : is a \x05%s
	//04=green
	", Is a noob who didnt pick a class.",
	", He can shoot fast.",
	", He Can Jump high.",
	", He can heal his team by crouching.",
	", He is invisible while hes crouched.",
	", He does loads of damage.",
	", He can drop auto turrets.",
	", He has lots of health.",
	", He can slow time by pressing walk.",
	", He can see through walls with crouch.",
	", He can make portals.",
	", He can 1 shot tanks when hes charged.",
	", He can easily kill Tanks and witches.",
	", He gets random health and bullet damage.",
	", He can run really fast near his team.",
	", He can drop bombs by pressing shift.",
	", He cant be moved by infected.",
	", He can shoot through any wall.",
	", He has infinite fire ammo.",	
	", He pasivly zaps commons.",
	", He is immune to bile and spitter goo",
	", He can control commons,and earn pipes"
};

// How long should the Class Select menu stay open?
int MENU_OPEN_TIME = 99;

// What formatting string to use when printing to the chatbox
#define PRINT_PREFIX 	"\x05[DLR] \x01"

/// SOUNDS AND OTHER
/// PRECACHE DATA

#define SOUND_CLASS_SELECTED "ui/pickup_misc42.wav" /**< What sound to play when a class is selected. Do not include "sounds/" prefix. */
#define SOUND_DROP_BOMB "ui/beep22.wav"
#define FREEZE_SOUND "physics/glass/glass_sheet_break2.wav"

//#define CHARGEDUPSOUND	"level/startwam.wav"
#define AWPSHOT			"weapons/awp/gunfire/awp1.wav"

#define BAR_MDL  "models/props_unique/wooden_barricade.mdl"
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
	SHARPSHOOTER,
	PSYCHIC,
	WARPER,
	BIGSNIPER,
	BOSSSLAYER,
	GAMBLER,
	FLASH,
	TRAPPER,
	BLOCKER,
	PENATRATOR,
	PYRO,
	TESLA,
	HAZMAT,
	PIPER,
	MAXCLASSES
};

enum PLAYERDATA {
	BombsUsed,
	ItemsBuilt,
	Float:HideStartTime,
	LastButtons,
	ChosenClass,
	Float:LastDropTime,
	bool:Is_charging,
	bool: Charged,
	Float:FrozenTime,
	Float:ChargeStartTime,
	bool:ExplosionCreated,
	bool:Ignited
};

// Stores client plugin data
int ClientData[MAXPLAYERS+1][PLAYERDATA];

// store freeze date

bool Blocked[MAXPLAYERS+1];
float FreezeLocation[MAXPLAYERS+1][3];


// Rapid fire variables
new g_iRI[MAXPLAYERS+1] = { -1 }, g_iRC, g_iEi[MAXPLAYERS+1] = { -1 }, Float:g_fNT[MAXPLAYERS+1] = { -1.0 }, g_iNPA = -1, g_oAW = -1;

// Speed vars
int g_ioLMV;

// Sniper vars
int g_ioPR = -1;
int g_iVMStartTimeO  = -1;
int g_iViewModelO = -1;
int g_ioNA = -1;
int g_ioTI = -1;
int g_iSSD = -1;
int g_iSID = -1;
int g_iSED = -1;
int g_iSRS = -1;

// Weapon rates
const Float:g_fl_SpasS = 0.5;
const Float:g_fl_SpasI = 0.375;
const Float:g_fl_SpasE = 0.699999;

// Enums (doc'd by SMLib)
enum Water_Level
{
	WATER_LEVEL_NOT_IN_WATER = 0,
	WATER_LEVEL_FEET_IN_WATER,
	WATER_LEVEL_WAIST_IN_WATER,
	WATER_LEVEL_HEAD_IN_WATER
};

// Bomb related stuff
int g_BeamSprite = -1, g_HaloSprite = -1;
int redColor[4]		= {255, 75, 75, 255};
int greenColor[4]	= {75, 255, 75, 255};
int RndSession;

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

// Max classes
Handle MAX_SOLDIER;
Handle MAX_ATHLETE;
Handle MAX_MEDIC;
Handle MAX_SABOTEUR;
Handle MAX_SNIPER;
Handle MAX_ENGINEER;
Handle MAX_BRAWLER;
Handle MAX_SHARPSHOOTER;
Handle MAX_PSYCHIC;
Handle MAX_WARPER;
Handle MAX_BIGSNIPER;
Handle MAX_BOSSSLAYER;
Handle MAX_GAMBLER;
Handle MAX_FLASH;
Handle MAX_TRAPPER;
Handle MAX_BLOCKER;
Handle MAX_PENATRATOR;
Handle MAX_PYRO;
Handle MAX_TESLA;
Handle MAX_HAZMAT;
Handle MAX_PIPER;

// Everyone
Handle SOLDIER_HEALTH;
Handle ATHLETE_HEALTH;
Handle MEDIC_HEALTH;
Handle SABOTEUR_HEALTH;
Handle SNIPER_HEALTH;
Handle ENGINEER_HEALTH;
Handle BRAWLER_HEALTH;
Handle SHARPSHOOTER_HEALTH;
Handle PSYCHIC_HEALTH;
Handle WARPER_HEALTH;
Handle BIGSNIPER_HEALTH;
Handle BOSSSLAYER_HEALTH;
Handle FLASH_HEALTH;
Handle TRAPPER_HEALTH;
Handle BLOCKER_HEALTH;
Handle PENATRATOR_HEALTH;
Handle PYRO_HEALTH;
Handle TESLA_HEALTH;
Handle HAZMAT_HEALTH;
Handle PIPER_HEALTH;

// Soldier
Handle SOLDIER_FIRE_RATE;

// Athlete
//new Handle:ATHLETE_SPEED;
Handle ATHLETE_JUMP_VEL;


// Medic
Handle MEDIC_HEAL_DIST;
Handle MEDIC_HEALTH_VALUE;
Handle MEDIC_MAX_DEFIBS;
Handle MEDIC_HEALTH_INTERVAL;

// Saboteur
Handle SABOTEUR_INVISIBLE_TIME;
Handle SABOTEUR_BOMB_ACTIVATE;
Handle SABOTEUR_BOMB_RADIUS;
Handle SABOTEUR_MAX_BOMBS;
Handle SABOTEUR_BOMB_DAMAGE_INF;
Handle SABOTEUR_FREEZE_RANGE;
Handle SABOTEUR_FREEZE_DURATION;

// Sniper
Handle SNIPER_DAMAGE;
Handle COMMANDO_RELOAD_RATIO;

// Engineer
Handle ENGINEER_MAX_BUILDS;
Handle MAX_ENGINEER_BUILD_RANGE;

// Saboteur, Engineer, Medic
Handle MINIMUM_DROP_INTERVAL;

//psychic
Handle PSYCHIC_ABILITY_TIME;
Handle PSYCHIC_ABILITY_COOLDOWN;

// Warper
Handle MINIMUM_PORTAL_INTERVAL;

// BIG SNIPER
Handle BIGGSNIPER_CHARGE_TIME;
Handle BIGGSNIPER_SHOT_DAMAGE;

//gambler
Handle GAMBLER_MAX_HEALTH;
Handle GAMBLER_MIN_HEALTH;

//medic quick revive stuff
new Handle:g_VarFirstAidDuration = INVALID_HANDLE;
new Handle:g_VarReviveDuration = INVALID_HANDLE;

new Float:FirstAidDuration;
new Float:ReviveDuration;


#include "warper_class.sp"
#include "Tesla_Class.sp"


// Saferoom checks for saboteur
bool g_bInSaferoom[MAXPLAYERS+1] = false;
float g_SpawnPos[MAXPLAYERS+1][3];

// Last class taken
int LastClassConfirmed[MAXPLAYERS+1];

bool timer_triggered;
bool RoundStarted;
bool OutlineState;

//store last fired weapon for penatrator damage
char pentratorweapon[64];
/**
 * STOCK FUNCTIONS
 */
 
stock int GetClientTempHealth(int client)
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
	
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	
	float TempHealth;
	
	if (buffer <= 0.0)
		TempHealth = 0.0;
	else
	{
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		float constant = 1.0/decay;
		TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	TempHealth = 0.0;
	
	return RoundToFloor(TempHealth);
}

stock void SetClientTempHealth(int client, int iValue)
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
	
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, client);
	WritePackCell(hPack, iValue);
	
	CreateTimer(0.1, TimerSetClientTempHealth, hPack, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerSetClientTempHealth(Handle hTimer, Handle hPack)
{
	ResetPack(hPack);
	int client = ReadPackCell(hPack);
	int iValue = ReadPackCell(hPack);
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

stock void PushEntity(int client, float clientEyeAngle[3], float power)
{
	float forwardVector[3];
	float newVel[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", newVel);
	GetAngleVectors(clientEyeAngle, forwardVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(forwardVector, forwardVector);
	ScaleVector(forwardVector, power);
	AddVectors(forwardVector, newVel, newVel);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, newVel);
}

stock Water_Level:GetClientWaterLevel(int client)
{	
	return Water_Level:GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

stock bool IsClientOnLadder(int client)
{	
	new MoveType:movetype = GetEntityMoveType(client);
	
	if (movetype == MOVETYPE_LADDER)
		return true;
	
	return false;
}

stock void DetonateMolotov(float pos[3],int owner)
{
	pos[2]+=5.0;
	Handle sdkDetonateFire;
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
	float vec[3];
	SDKCall(sdkDetonateFire, pos, vec, vec, vec, owner);
	CloseHandle(sdkDetonateFire);
}

stock void DealDamage(int iVictim,int iAttacker, float flAmount,int iType = 0)
{
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, iVictim);
	WritePackCell(hPack, iAttacker);
	WritePackFloat(hPack, flAmount);
	WritePackCell(hPack, iType);
	CreateTimer(0.1, timerHurtEntity, hPack);
}

public Action timerHurtEntity(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	int attacker = ReadPackCell(pack);
	float amount = ReadPackFloat(pack);
	int type = ReadPackCell(pack);
	CloseHandle(pack);
	HurtEntity(client, attacker, amount, type);
}

stock void HurtEntity(int client,int attacker, float amount,int type)
{
	int damage = RoundFloat(amount);
	if (IsValidEntity(client))
	{
		decl String:sUser[256], String:sDamage[11], String:sType[11];
		IntToString(client+25, sUser, sizeof(sUser));
		IntToString(damage, sDamage, sizeof(sDamage));
		IntToString(type, sType, sizeof(sType));
		int iDmgEntity = CreateEntityByName("point_hurt");
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

stock CreateExplosion(float expPos[3],int attacker = 0, bool panic = true)
{
	decl String:sRadius[16], String:sPower[16], String:sInterval[11];
	float flMxDistance = 450.0;
	float iDamageInf = GetConVarFloat(SABOTEUR_BOMB_DAMAGE_INF);
	float flInterval = 0.1;
	FloatToString(flInterval, sInterval, sizeof(sInterval));
	IntToString(450, sRadius, sizeof(sRadius));
	IntToString(800, sPower, sizeof(sPower));
	

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
	
	//for(new i = 1; i <= 2; i++)
	//	DetonateMolotov(expPos, attacker);
	
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
	
	decl Float:survivorPos[3];//, Float:traceVec[3];//, Float:resultingFling[3], Float:currentVelVec[3];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		if (GetVectorDistance(expPos, survivorPos) <= flMxDistance)
		{
			/*MakeVectorFromPoints(expPos, survivorPos, traceVec);
			GetVectorAngles(traceVec, resultingFling);
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
		
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
			*/
			if (attacker > 0)
			{
				if (GetClientTeam(i) == 3)
				//	DealDamage(i, attacker, iDamageSurv, 8);
				//else
					DealDamage(i, attacker, iDamageInf, 8);
			}
		}
	}
	
	//*
	decl String:class[32];
	for (new i=MaxClients+1; i<=2048; i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "prop_physics")|| StrEqual(class, "prop_dynamic") || StrEqual(class, "prop_physics_multiplayer"))
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
				
				//Vector and radius distance calcs by AtomicStryker!
				if (GetVectorDistance(expPos, survivorPos) <= flMxDistance)
				{
					if(IsTankHitable(i))
					{
						AcceptEntityInput(i, "Kill"); 
						PrintToChatAll("%s KABOOM!",PRINT_PREFIX);
					}
					
					/*MakeVectorFromPoints(expPos, survivorPos, traceVec);
					GetVectorAngles(traceVec, resultingFling);
					
					resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
					resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
					resultingFling[2] = power;
					
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);
					resultingFling[0] += currentVelVec[0];
					resultingFling[1] += currentVelVec[1];
					resultingFling[2] += currentVelVec[2];
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
					*/		
					new String:modelname[128]; 
					GetEntPropString(i, Prop_Data, "m_ModelName", modelname, 128);
					if (StrContains(modelname, BAR_MDL)!=-1)
					{
						AcceptEntityInput(i, "Kill"); 
						PrintToChatAll("%sThats How You Clear A Path!!!",PRINT_PREFIX);
					}	
				}
			}
		}
	}//*/
}
public bool:IsTankHitable(entity)
{
	if(!IsValidEntity(entity))
		return false;
	char className[64]; 	
	GetEntityClassname(entity, className, 64);
	if ( StrEqual(className, "prop_physics") ) 
	{
		if (HasEntProp(entity, Prop_Send, "m_hasTankGlow") && GetEntProp(entity, Prop_Send, "m_hasTankGlow", 1)) 
		{
			return true;
		}
		
		else if ( StrEqual(className, "prop_car_alarm") ) 
		{
			return true;
		}	
	}
	return false;
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
	
	// Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_shoved", Event_PlayerShoved);
	HookEvent("entity_shoved", Event_PlayerShoved);
	HookEvent("round_end", Event_RoundChange);
	HookEvent("round_start_post_nav", Event_RoundChange);
	HookEvent("mission_lost", Event_RoundChange);
	HookEvent("weapon_reload", Event_RelCommandoClass);
	HookEvent("player_entered_checkpoint", Event_EnterSaferoom);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom);
	HookEvent("player_team", Event_PlayerTeam);
	
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("bullet_impact",BulletImpact);
	HookEvent("chair_charged", Event_ChairCharged);
	HookEvent("player_now_it", Event_PlayerVomited);
	
	//HookEvent("charger_impact", event_impact);
	HookEvent("charger_carry_start", event_Grab);
	HookEvent("charger_carry_end", event_GrabEnded);
	HookEvent("jockey_ride", event_Grab);
	HookEvent("jockey_ride_end", event_GrabEnded);
	HookEvent("tongue_grab", event_Grab);
	HookEvent("tongue_release", event_GrabEnded);
	
	HookEvent("player_left_start_area",Event_LeftStartArea);//used to start the freeze logic
	HookEvent("infected_hurt", WitchHurt_Event);
	HookEvent("heal_begin", event_HealBegin, EventHookMode_Pre);
	HookEvent("revive_begin", event_ReviveBegin, EventHookMode_Pre);
	
	// Concommands
	RegConsoleCmd("sm_class", CmdClassMenu, "Shows the class selection menu");
	RegConsoleCmd("sm_classes", CmdClasses, "Shows who is what class");
	RegConsoleCmd("sm_classinfo", CmdClassInfo, "Shows basic information what each class does");
	RegConsoleCmd("sm_start", CmdForceCampainStart, "starts map for campain");
	
	// Convars
	MAX_SOLDIER = CreateConVar("talents_soldier_max", "1", "Max number of soldiers");
	MAX_ATHLETE = CreateConVar("talents_athelete_max", "1", "Max number of athletes");
	MAX_MEDIC = CreateConVar("talents_medic_max", "1", "Max number of medics");
	MAX_SABOTEUR = CreateConVar("talents_saboteur_max", "1", "Max number of saboteurs");
	MAX_SNIPER = CreateConVar("talents_sniper_max", "1", "Max number of commandos");
	MAX_ENGINEER = CreateConVar("talents_engineer_max", "1", "Max number of engineers");
	MAX_BRAWLER = CreateConVar("talents_brawler_max", "1", "Max number of brawlers");
	
	MAX_SHARPSHOOTER = CreateConVar("talents_sharpshooter_max", "1", "Max number of sharpshooters");
	MAX_PSYCHIC = CreateConVar("talents_phychic_max", "1", "Max number of phychics");
	MAX_WARPER = CreateConVar("talents_warper_max", "1", "Max number of warpers");
	MAX_BIGSNIPER = CreateConVar("talents_bigsniper_max", "1", "Max number of snipers");
	MAX_BOSSSLAYER = CreateConVar("talents_bossslayer_max", "1", "Max number of boss slayer");
	MAX_GAMBLER = CreateConVar("talents_gambler_max", "1", "Max number of gamblers");
	MAX_FLASH = CreateConVar("talents_flash_max", "1", "Max number of flash class");
	
	MAX_TRAPPER = CreateConVar("talents_trapper_max", "1", "Max number of Trapper class");
	MAX_BLOCKER = CreateConVar("talents_blocker_max", "1", "Max number of Blocker class");
	MAX_PENATRATOR = CreateConVar("talents_penatrator_max", "1", "Max number of Penatrator class");
	MAX_PYRO = CreateConVar("talents_pyro_max", "1", "Max number of pyro class");
	MAX_PIPER = CreateConVar("talents_piper_max", "1", "Max number of piper class");
	MAX_HAZMAT = CreateConVar("talents_hazmat_max", "1", "Max number of hazmat class");
	MAX_TESLA = CreateConVar("talents_tesla_max", "1", "Max number of tesla class");
	
	SOLDIER_HEALTH = CreateConVar("talents_soldier_health", "180", "How much health a soldier should have");
	ATHLETE_HEALTH = CreateConVar("talents_athelete_health", "100", "How much health an athlete should have");
	MEDIC_HEALTH = CreateConVar("talents_medic_health_start", "150", "How much health a medic should have");
	SABOTEUR_HEALTH = CreateConVar("talents_saboteur_health", "150", "How much health a saboteur should have");
	SNIPER_HEALTH = CreateConVar("talents_sniper_health", "180", "How much health a comando should have");
	ENGINEER_HEALTH = CreateConVar("talents_engineer_health", "150", "How much health a engineer should have");
	BRAWLER_HEALTH = CreateConVar("talents_brawler_health", "300", "How much health a brawler should have");
	
	SHARPSHOOTER_HEALTH = CreateConVar("talents_sharpshooter_health", "150", "How much health a sharpshooter should have");
	PSYCHIC_HEALTH = CreateConVar("talents_phychic_health", "150", "How much health a phycic should have");
	WARPER_HEALTH = CreateConVar("talents_warper_health", "150", "How much health a warper should have");
	BIGSNIPER_HEALTH = CreateConVar("talents_bigsniper_health", "150", "How much health a sniper should have");
	BOSSSLAYER_HEALTH = CreateConVar("talents_bossslayer_health", "150", "How much health a boss slayer should have");
	FLASH_HEALTH = CreateConVar("talents_flash_health", "100", "How much health a flash should have");
	
	GAMBLER_MIN_HEALTH = CreateConVar("talents_gambler_min_health", "100", "min health a gambler could have");
	GAMBLER_MAX_HEALTH = CreateConVar("talents_gambler_max_health", "250", "max health a gambler could have");
	
	TRAPPER_HEALTH = CreateConVar("talents_trapper_health", "150", "How much health a trapper should have");
	BLOCKER_HEALTH = CreateConVar("talents_blocker_health", "150", "how much health a blocker should have");
	PENATRATOR_HEALTH = CreateConVar("talents_penatrator_health", "150", "how much health a penatrator should have");
	PYRO_HEALTH = CreateConVar("talents_pyro_health", "180", "how much health a pyro should have");
	PIPER_HEALTH = CreateConVar("talents_piper_health", "180", "how much health a piper should have");
	HAZMAT_HEALTH = CreateConVar("talents_hazmat_health", "150", "how much health a piper should have");
	TESLA_HEALTH = CreateConVar("talents_tesla_health", "150", "how much health a tesla should have");
	
	SOLDIER_FIRE_RATE = CreateConVar("talents_soldier_fire_rate", "0.6666", "How fast the soldier should fire. Lower values = faster");

	//ATHLETE_SPEED = CreateConVar("talents_athlete_speed", "1.35", "How fast soldier should run. A value of 1.0 = normal speed", FCVAR_PLUGIN);
	ATHLETE_JUMP_VEL = CreateConVar("talents_athlete_jump", "450.0", "How high a soldier should be able to jump. Make this higher to make them jump higher, or 0.0 for normal height");

	MEDIC_HEAL_DIST = CreateConVar("talents_medic_heal_dist", "600.0", "How close other survivors have to be to heal. Larger values = larger radius");
	MEDIC_HEALTH_VALUE = CreateConVar("talents_medic_health", "3", "How much health to restore");
	MEDIC_MAX_DEFIBS = CreateConVar("talents_medic_max_defibs", "4", "How many defibs the medic can drop");
	MEDIC_HEALTH_INTERVAL = CreateConVar("talents_medic_health_interval", "3.0", "How often to heal players within range");

	SABOTEUR_INVISIBLE_TIME = CreateConVar("talents_saboteur_invis_time", "1.0", "How long it takes for the saboteur to become invisible");
	SABOTEUR_BOMB_ACTIVATE = CreateConVar("talents_saboteur_bomb_activate", "5.0", "How long before the dropped bomb becomes sensitive to motion");
	SABOTEUR_BOMB_RADIUS = CreateConVar("talents_saboteur_bomb_radius", "128.0", "Radius of bomb motion detection");
	SABOTEUR_MAX_BOMBS = CreateConVar("talents_saboteur_max_bombs", "10", "How many bombs a saboteur can drop per round");
	SABOTEUR_BOMB_DAMAGE_INF = CreateConVar("talents_saboteur_bomb_dmg_inf", "2000.0", "How much damage a bomb does to infected");
	SABOTEUR_FREEZE_RANGE = CreateConVar("talents_saboteur_freez_range" , "600" , "how far the freeze effects");
	SABOTEUR_FREEZE_DURATION = CreateConVar("talents_saboteur_freez_duration" , "10.0" ,"how long the freeze lasts");
	
	SNIPER_DAMAGE = CreateConVar("talents_sniper_dmg", "5", "How much bonus damage a Sniper does");
	COMMANDO_RELOAD_RATIO = CreateConVar("talents_sniper_reload_ratio", "0.44", "Ratio for how fast a Sniper should be able to reload");

	ENGINEER_MAX_BUILDS = CreateConVar("talents_engineer_max_builds", "4", "How many times an engineer can build per round");
	MAX_ENGINEER_BUILD_RANGE = CreateConVar("talents_engineer_build_range", "120.0", "Maximum distance away an object can be built by the engineer");
	
	MINIMUM_DROP_INTERVAL = CreateConVar("talents_drop_interval", "2.0", "Time before an engineer, medic, or saboteur can drop another item");
	MINIMUM_PORTAL_INTERVAL = CreateConVar("portal_spawn_interval", "5.0", "Time between portal spawns");
	
	BIGGSNIPER_CHARGE_TIME = CreateConVar("charge_shot_duration", "10.0", "how long to hold crouch to charge the shot");
	BIGGSNIPER_SHOT_DAMAGE = CreateConVar("charge_shot_damage", "10000,0", "how much damage the charge shot does");
	
	PSYCHIC_ABILITY_TIME = CreateConVar("psychic_ability_time", "10.0", "how long psychic can wall hack for");
	PSYCHIC_ABILITY_COOLDOWN = CreateConVar("psychic_ability_cooldown", "20.0", "psychic power cooldown");

	
	ApplyHealthModifiers();
	
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
	ClientData[client][PLAYERDATA:FrozenTime] = 0.0;
	ClientData[client][PLAYERDATA:Ignited] = false;
	g_bInSaferoom[client] = false;
	
	Blocked[client] = false;
	//FreezeLocation[client][3];
}

public Event_PlayerTeam(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent,"userid"));
	new team = GetEventInt(hEvent,"team");
	
	if (team == 2 && LastClassConfirmed[client] != 0)
	{
		ClientData[client][PLAYERDATA:ChosenClass] = LastClassConfirmed[client];
		PrintToChat(client, "You are currently a \x04%s", MENU_OPTIONS[LastClassConfirmed[client]]);
	}
}

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		ResetClientVariables(i);
		LastClassConfirmed[i] = 0;
	}
	RoundStarted = false;
	OutlineState = false;
	RndSession++;
	ResetAllState();//turrets stuff
	Kill_Portals();//reset portals so they cant be exploited
}

public OnMapStart()
{
	// Sounds
	PrecacheSound(SOUND_CLASS_SELECTED);
	PrecacheSound(SOUND_DROP_BOMB);
	PrecacheSound(AWPSHOT, true);
	PrecacheSound(FREEZE_SOUND, true);
	
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
	
	PrecacheTurret();//turretstuff
	PortalMapStart();// portal stuff
	PrecacheZapStuff();// tesla stuff
	
	// freeze logic
	timer_triggered = false;
	RoundStarted = false;
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
	if(!IsValidClient(client))
		return;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
}
stock bool:IsValidClient(client)
{ 
    if (client <= 0 || client > MaxClients)
    {
        return false; 
    }
    return IsClientInGame(client); 
} 
public Action:TimerLoadClient(Handle:hTimer, any:client)
{
	if(!IsValidClient(client))
		return;
		
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
	new bool:CanPortal = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= GetConVarFloat(MINIMUM_PORTAL_INTERVAL);
	new bool:CanSee = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= GetConVarFloat(PSYCHIC_ABILITY_COOLDOWN);
	new bool:CanSlow = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= 20.0;
	new bool:CanUnvomit = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= 45.0;
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	if (GetClientTeam(client)==2 && ClientData[client][PLAYERDATA:ChosenClass] != _:FLASH)
	{
		SetEntDataFloat(client, g_ioLMV, 1.0, true);
	}
	
	switch (ClientData[client][PLAYERDATA:ChosenClass])
	{
		case FLASH:
		{	
			float SpeedBonus = GetSpeedBonus(client);
			if( SpeedBonus > 0.0)
			{				
				SetEntDataFloat(client, g_ioLMV, 1.0 + SpeedBonus , true);
			}
			else
			{
				PrintHintText(client,"stay close to your team or you lose your speed");
				SetEntDataFloat(client, g_ioLMV, 1.0, true);
			}
		}
		
		case SABOTEUR:
		{
			if (buttons & IN_DUCK || buttons & IN_SPEED)//&& (GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= GetConVarFloat(SABOTEUR_INVISIBLE_TIME))
			{	//SetEntityRenderFx(client, RENDERFX_FADE_SLOW);

				SetEntDataFloat(client, g_ioLMV, 1.4, true);
				SetEntityRenderFx(client, RENDERFX_NONE);
				
			}
			else
			{	
				SetEntDataFloat(client, g_ioLMV, 1.0, true);
			}
		}

		case TRAPPER:
		{		
			if (buttons & IN_SPEED && ClientData[client][PLAYERDATA:ItemsBuilt] < GetConVarInt(SABOTEUR_MAX_BOMBS) && CanDrop)
			{					
				DisplaybombMenu(client, 60);
		
				ClientData[client][PLAYERDATA:ItemsBuilt]++;
				ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
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
			if (buttons & IN_SPEED && RoundStarted == true && CanDrop)// && ClientData[client][PLAYERDATA:ItemsBuilt] < GetConVarInt(ENGINEER_MAX_BUILDS)) 
			{	
				if(ClientData[client][PLAYERDATA:ItemsBuilt] < GetConVarInt(ENGINEER_MAX_BUILDS))
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
					
		case PSYCHIC:
		{
			if(CanSee)
			{
				PrintHintText(client,"Wall-Hacks ready to use");
				if (buttons & IN_DUCK && CanSee )	
				{	
					ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
					WallHack();
				}	
			}	
			else
			{
				PrintHintText(client,"Wall-Hacks cooling Down");
			}

		}			
		case SHARPSHOOTER:
		{
			if(CanSlow)
			{
				PrintHintText(client,"Slow-Mo ready to use");
				if (buttons & IN_SPEED && CanSlow )	
				{
					ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
					SlowTime();
				}
			}
			else
			{
				PrintHintText(client,"Slow-Mo cooling Down");
			}
		
		}	
		case PIPER:
		{
			new bool:next = (GetGameTime() - ClientData[client][PLAYERDATA:LastDropTime]) >= 1.5; 
			
			if (buttons & IN_SPEED && next)
			{
				PrintHintText(client,"the commons are coming for you");	
				decl Float:clientpos[3];
				GetClientAbsOrigin(client, clientpos);				
				CreateChase(clientpos);
				ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
			}
			else if(buttons & IN_DUCK && next)
			{
				decl Float:vAng[3], Float:vPos[3], Float:endPos[3];
	
				GetClientEyeAngles(client, vAng);
				GetClientEyePosition(client, vPos);

				new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(endPos, trace);
					CloseHandle(trace);
					CreateChase(endPos);
					ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
				}					
			}
		}	
		case BIGSNIPER:
		{
			if (ClientData[client][PLAYERDATA:ExplosionCreated] == true)
			{
				ClientData[client][PLAYERDATA:ExplosionCreated] = false;
				ClientData[client][PLAYERDATA:Is_charging] = false;
				ClientData[client][PLAYERDATA:Charged] = false;
			}
			
			if (buttons & IN_DUCK) 
			{	
				if (ClientData[client][PLAYERDATA:Is_charging] == false)
				{
					//record the time player starts crouching
					ClientData[client][PLAYERDATA:ChargeStartTime] = GetGameTime();
					// shot is now chargeing
					ClientData[client][PLAYERDATA:Is_charging] = true;
					
					PrintCenterText(client, "CHARGING");
					chargeeffect(client);
				}
				
				if (ClientData[client][PLAYERDATA:Is_charging] == true && ClientData[client][PLAYERDATA:Charged] == false)
				{
					if(GetGameTime() > (ClientData[client][PLAYERDATA:ChargeStartTime] + GetConVarFloat(BIGGSNIPER_CHARGE_TIME)-3.0))
					{
						//chargeeffect(client);
						PrintHintTextToAll("DEATH SHOT IS CHARGEING,GET HIM!!!");
						EmitSoundToAll(SOUND_DROP_BOMB);
						if(GetGameTime() > (ClientData[client][PLAYERDATA:ChargeStartTime] + GetConVarFloat(BIGGSNIPER_CHARGE_TIME)))
						{
							ClientData[client][PLAYERDATA:Charged] = true;
							//PrintToChatAll("shot charged");
							PrintCenterText(client, "READY TO FIRE");
							EmitSoundToAll(SOUND_DROP_BOMB);
							chargeeffect(client);
							PrintHintTextToAll("HE'S CHARGED, HIDE!!");
						}
					}	
				}
			} 
			else
			{
				ClientData[client][PLAYERDATA:Is_charging] = false;
				ClientData[client][PLAYERDATA:Charged] = false;
			}
			
			if((buttons & IN_FORWARD) || (buttons & IN_MOVERIGHT) || (buttons & IN_MOVELEFT) ||(buttons & IN_BACK) || (buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
			{
				ClientData[client][PLAYERDATA:Is_charging] = false;
				ClientData[client][PLAYERDATA:Charged] = false;
			}		
		}			
		case WARPER:
		{
			if (buttons & IN_SPEED && CanPortal)
			{
				DisplayPortalMenu(client, 60);
				ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();		
			}
		}
		case HAZMAT:
		{
			if (buttons & IN_SPEED && CanUnvomit)
			{
				for(int i = 0; i < MAXPLAYERS + 1; i++)
				{
					if(GetClientTeam(client) == 2)
						UnVomit(client);
				}
				ClientData[client][PLAYERDATA:LastDropTime] = GetGameTime();
			}
		}
	}
	return Plugin_Continue;
}

chargeeffect(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Handle:hPack = CreateDataPack();
	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, client);
	WritePackCell(hPack, RndSession);
		
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
}
DisplayPortalMenu(client, time=MENU_TIME_FOREVER) 
{ 
	new Handle:menu = CreateMenu(PortalMenuHandler); 
	SetMenuTitle(menu, "Move Portal");
	AddMenuItem(menu, "1", "red");
	AddMenuItem(menu, "2", "blue"); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, time);
}
public PortalMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{ 
	if (action == MenuAction_Select) 
	{
		switch (itemNum)
		{			 
			case 0: {
				if(GetClientTeam(client) == 2)
					Red_Move(client);
			}
			case 1:{
				if(GetClientTeam(client) == 2)
					Blue_Move(client);
			}
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

DisplaybombMenu(client, time=MENU_TIME_FOREVER) 
{ 
	new Handle:menu = CreateMenu(bombMenuHandler); 
	SetMenuTitle(menu, "Drop Bomb");
	AddMenuItem(menu, "1", "Trip Mine");
	AddMenuItem(menu, "2", "Time Bomb (10sec)"); 
	AddMenuItem(menu, "3", "Proximity freeze Bomb");
	//AddMenuItem(menu, "4", "freeze Bomb"); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, time);
}
public bombMenuHandler(Handle menu, MenuAction action,int client, int itemNum) 
{ 
	if (action == MenuAction_Select) {
		switch (itemNum)
		{
			case 0: {
				if(GetClientTeam(client) == 2)
					DropBomb(client);
				}
			case 1: {
				if(GetClientTeam(client) == 2)
					DropTimeBomb(client);
				}
			case 2:{
				if(GetClientTeam(client) == 2) 
					DropFreezeMine(client);
				}
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

CreateRemoveTurretMenu(int client)
{
	if (!client)
		return false;
	
	Handle hPanel;
	
	if((hPanel = CreatePanel()) == INVALID_HANDLE)
	{
		LogError("Cannot create hPanel on CreateRemoveTurretMenu");
		return false;
	}
	
	SetPanelTitle(hPanel, "Turret:");
	DrawPanelItem(hPanel, "Remove ");
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_RemoveTurretMenu, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return 0;
}
public PanelHandler_RemoveTurretMenu(Handle menu, MenuAction action, int client,int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param == 1)
			{
				if (GetClientTeam(client) == 2)
				{
					if(removemachine(client))
						ClientData[client][PLAYERDATA:ItemsBuilt]--;
				}
			}	
		}
	}
}

CreatePlayerEngineerMenu(int client)
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
	DrawPanelItem(hPanel, "Remove Turret");/// what ive added for remove tureet
	DrawPanelText(hPanel, " ");
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, PanelHandler_SelectEngineerItem, MENU_OPEN_TIME);
	CloseHandle(hPanel);
	
	return true;
}
public PanelHandler_SelectEngineerItem(Handle menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if( param >= 1 && param <= 6 )
			{
				if(GetClientTeam(client) == 2)
				{
					CalculateEngineerPlacePos(client, param - 1);
				}
			}	
		}
	}
}

CalculateEngineerPlacePos(int client, int type)
{
	if(GetClientTeam(client) != 2)
		return;
	
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
					CloseHandle( trace );
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
		CloseHandle(trace);
}

public bool TraceFilter(int entity, int contentsMask, int client)
{
	if( entity == client )
		return false;
	return true;
}

public Action SetTransmitInvisible(int client, int entity)
{
	//if (ClientData[client][PLAYERDATA:ChosenClass] == _:SABOTEUR && ((GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= (GetConVarFloat(SABOTEUR_INVISIBLE_TIME) + 5.0)) && client != entity)
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:SABOTEUR && ((GetGameTime() - ClientData[client][PLAYERDATA:HideStartTime]) >= GetConVarFloat(SABOTEUR_INVISIBLE_TIME)) && client != entity)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

DropBomb(int client)
{
	float pos[3];
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

public Action TimerActivateBomb(Handle hTimer, Handle hPack)
{
	CreateTimer(0.3, TimerCheckBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}

public Action TimerCheckBombSensors(Handle hTimer, Handle hPack)
{
	float pos[3];
	float clientpos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	int owner = ReadPackCell(hPack);
	int session = ReadPackCell(hPack);
	
	if (session != RndSession)
		return Plugin_Stop;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsGhost(client)  )
			continue;
			
			
		GetClientAbsOrigin(client, clientpos);
		
		if(GetClientTeam(client) == 3)
		{
		
			if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
			{
				PrintToChatAll("%s\x03%N\x01's \x04bomb \x01detonated!", PRINT_PREFIX, owner);
				CreateExplosion(pos, owner, false);
				CloseHandle(hPack);
				return Plugin_Stop;
			}
		}
	
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamagePre(int victim,int &attacker,int &inflictor, &Float:damage,int &damagetype)
{	
	if (!IsServerProcessing())
		return Plugin_Continue;	
	// boss slayer stuff
	if (ClientData[victim][PLAYERDATA:ChosenClass] == _:BOSSSLAYER)
	{
		 if(IsWitch(attacker))
		{
			damage = 0.0;	
			return Plugin_Changed;
		}
		if (victim && attacker && IsValidEntity(attacker) && attacker <= MaxClients && IsValidEntity(victim) && victim <= MaxClients)
		{
			if(IsTank(attacker))
			{
				PrintHintText(attacker,"You cant hurt %N, He is a Boss-Slayer",victim);
				CreateTimer(0.1,StopFling,victim);
				damage = 0.0;
				return Plugin_Changed;
			}
		}	
	}

	if(IsValidPlayerIndex(attacker))
	{
		switch (ClientData[attacker][PLAYERDATA:ChosenClass])
		{
			case SNIPER:
			{	
				if (GetClientTeam(attacker) == 2 && IsValidSpecialInfected(victim))
				{
					damage += GetConVarInt(SNIPER_DAMAGE);
					return Plugin_Changed;
				}
			}
			case BIGSNIPER:
			{
				if (GetClientTeam(victim) == 2)
				{
					if(damagetype & 8 || damagetype & 64)
					{
					damage = 0.0;
					//PrintToChatAll("blocking damage?");
					return Plugin_Changed;
					}
				}
				if (GetClientTeam(attacker) == 2 && IsValidSpecialInfected(victim) )
				{
					if (ClientData[attacker][PLAYERDATA:Charged] == true)
					{
						if((damagetype & 2) || (damagetype & 536870912))
						{	
							DealDamage(victim, attacker, GetConVarFloat(BIGGSNIPER_SHOT_DAMAGE), 0);
							ClientData[attacker][PLAYERDATA:Is_charging] = false;
							ClientData[attacker][PLAYERDATA:Charged] = false;
						}
					}
					return Plugin_Changed;
				}
			}
			case GAMBLER:
			{	
				if ( GetClientTeam(attacker) == 2 && IsValidSpecialInfected(victim))
				{
					damage += GetRandomInt(-10, 10);
					return Plugin_Changed;
				}
			}
		}
	}
	if(IsValidPlayerIndex(victim))
	{
		switch (ClientData[victim][PLAYERDATA:ChosenClass])
		{
			case BLOCKER:
			{
				if (IsTank(attacker))
				{
					CreateTimer(0.1,StopFling,victim);
				}
			}
		
			case HAZMAT:
			{
				if(GetClientTeam(victim) == 2)
				{
					if(IsSpitter(attacker) && IsSpitterGoo(inflictor))
					{
						damage = 0.0;
						return Plugin_Changed;
					}
					if(damagetype == 8)
					{	//block fire damage
						damage = 0.0;
						return Plugin_Changed;
					}
				}
			}
			case PYRO:
			{
				if(IsValidSpecialInfected(attacker))
				{
					HurtEntity(attacker,victim,1.0,8);	
				}
				if(IsCommonInfected(attacker))
				{
					IgniteEntity(attacker,10.0,true);
				}
				if(damagetype & 8)
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}
//*/
bool IsValidPlayerIndex(int client)
{
	if(client > 0 && client < MAXPLAYERS+1)
	{	return true;}
	return false;
}

bool IsValidSpecialInfected(int infected)
{
	if( IsValidPlayerIndex(infected))
	{
		return (GetClientTeam(infected) == 3);
	}
	return false;
}

bool IsSpitterGoo(int ent)
{
	if(ent > 0 && IsValidEntity(ent))
    {
		decl String:strClassName[64];
		GetEntityClassname(ent, strClassName, sizeof(strClassName));
		if(StrContains(strClassName, "insect_swarm") != -1)
		{
			return true;
		}
	}
	return false;
}

CreatePlayerClassMenu(client)
{
	if (!(client > 0 && client <= MaxClients))
		return false;
	
	if (!client)
		return false;	
	// if client has a class already and round has started, dont give them the menu
	if (ClientData[client][PLAYERDATA:ChosenClass] != _:NONE && RoundStarted == true)
	{
		PrintToChat(client,"%s Round has started, Your class is locked, You are a \x05%s\x01",PRINT_PREFIX,MENU_OPTIONS[ClientData[client][PLAYERDATA:ChosenClass]]);
		return false;
	}
	
	new Handle:hPanel;
	decl String:buffer[256];

	hPanel = CreateMenu(PanelHandler_SelectClass);
	
	SetMenuTitle(hPanel,"Select Your Class");

	for (new i = 1; i < _:MAXCLASSES; i++)
	{
		if( GetMaxWithClass(i) >= 0 )
			Format(buffer, sizeof(buffer), "%i/%i %s", CountPlayersWithClass(i), GetMaxWithClass(i),  MENU_OPTIONS[i]);
		else
			Format(buffer, sizeof(buffer), "%s", MENU_OPTIONS[i]);
		AddMenuItem(hPanel,"",buffer);
	}
	DisplayMenu(hPanel,client,40);
	return true;
}
public PanelHandler_SelectClass(Handle:hPanel, MenuAction:action, client, param)
{
	if (!(client > 0 && client <= MaxClients))
		return;
	
	new OldClass;
	OldClass = ClientData[client][PLAYERDATA:ChosenClass];
	if (action == MenuAction_Select) 
	{
		param ++;
		
		switch(action)
		{
			case MenuAction_Select:
			{
				if (!client || param -1 >= _:MAXCLASSES || GetClientTeam(client)!=2 )
				{
					return;
				}
				if( GetMaxWithClass( param ) >= 0 && CountPlayersWithClass( param ) >= GetMaxWithClass( param ) && ClientData[client][PLAYERDATA:ChosenClass] != param ) 
				{
					//ClientData[client][PLAYERDATA:ChosenClass] = _:NONE;
					PrintToChat( client, "%sThe \x04%s\x01 class is full, please choose another.", PRINT_PREFIX, MENU_OPTIONS[ param ] );
					CreatePlayerClassMenu( client );
				}
				else
				{				
					/// this is where im trying to change things
					LastClassConfirmed[client] = param;
					ClientData[client][PLAYERDATA:ChosenClass] = param;	
					PrintToConsole(client, "Class is setting up");
			
					SetupClasses(client, param);
					EmitSoundToClient(client, SOUND_CLASS_SELECTED);
					if(OldClass == _:NONE)
					{
						//PrintToChatAll("\x04%N\x01 : is a %s",client,MENU_OPTIONS[param]);
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
	else if (action == MenuAction_End) {
		CloseHandle(hPanel);
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
			PrintHintText(client,"soldier attacks fast, try meleeing the tank to death");
			MaxPossibleHP = GetConVarInt(SOLDIER_HEALTH);
		}
		
		case MEDIC:
		{
			PrintHintText(client,"hold crtl to heal your team mates");
			CreateTimer(GetConVarFloat(MEDIC_HEALTH_INTERVAL), TimerDetectHealthChanges, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			MaxPossibleHP = GetConVarInt(MEDIC_HEALTH);
		}
		
		case ATHLETE:
		{
			PrintHintText(client,"hold jump to bunny hop");
			MaxPossibleHP = GetConVarInt(ATHLETE_HEALTH);
		}
		
		case SNIPER:
		{
			PrintHintText(client,"hope your confident, its your job to do ALL the KILLING!!");
			MaxPossibleHP = GetConVarInt(SNIPER_HEALTH);
		}
		
		case ENGINEER:
		{
			PrintHintText(client,"press shift to open the drop equipment menu, the turret is automatic");
			MaxPossibleHP = GetConVarInt(ENGINEER_HEALTH);
		}
		
		case SABOTEUR:
		{
			PrintHintText(client,"hold crtl to go invisable, the ai can still find you");
			MaxPossibleHP = GetConVarInt(SABOTEUR_HEALTH);
		}
		
		case BRAWLER:
		{
			
			PrintHintText(client,"you've got a lot of health,try not to waste it");
			MaxPossibleHP = GetConVarInt(BRAWLER_HEALTH);
		}
		
		case SHARPSHOOTER:
		{
			PrintHintText(client,"tap crtl to activate slow motion");
			MaxPossibleHP = GetConVarInt(SHARPSHOOTER_HEALTH);
		}
		
		case PSYCHIC:
		{
			PrintHintText(client,"tap crtl to activate temporary wall hacks");
			MaxPossibleHP = GetConVarInt(PSYCHIC_HEALTH);
		}
		
		case WARPER:
		{
			new String:map[64];
			GetCurrentMap(map, sizeof map);
			if(StrContains(map,"mall",false) != -1)
			{
				PrintToChat(client,"warper crashes this map so is disabled, pick another class");
				ClientData[client][PLAYERDATA:ChosenClass] = _:NONE;
				MaxPossibleHP = 100;
			}
			else
			{
				PrintHintText(client,"press shift to open the move portal menu");
				MaxPossibleHP = GetConVarInt(WARPER_HEALTH);
				Start_Portal(client);
			}			
		}
		
		case BIGSNIPER:
		{
			PrintHintText(client,"crouch and stop EVERYTHING untill your charged(10 secs)");
			MaxPossibleHP = GetConVarInt(BIGSNIPER_HEALTH);
		}
		case BOSSSLAYER:
		{	
			PrintHintText(client,"tank and witch cant hurt you");
			MaxPossibleHP = GetConVarInt(BOSSSLAYER_HEALTH);
		}
		
		case GAMBLER:
		{
			PrintHintText(client,"was it a good gamble?");
			MaxPossibleHP = GetRandomInt(GetConVarInt(GAMBLER_MIN_HEALTH),GetConVarInt(GAMBLER_MAX_HEALTH));
		}
		
		case FLASH:
		{
			PrintHintText(client,"stay close to your team or you will lose your speed");
			MaxPossibleHP = GetConVarInt(FLASH_HEALTH);
		}
		
		case TRAPPER:
		{
			MaxPossibleHP = GetConVarInt(TRAPPER_HEALTH);
			PrintHintText(client,"press shift to open the bombs menu,Be careful");
		}
		
		case BLOCKER:
		{
			PrintHintText(client,"the infected cant move you, make them fail their instant kill moves");
			MaxPossibleHP = GetConVarInt(BLOCKER_HEALTH);
		}
		
		case PENATRATOR:
		{
			MaxPossibleHP = GetConVarInt(PENATRATOR_HEALTH);
			PrintHintText(client,"PENATRATOR can shoot through any wall!");
		}
		
		case PYRO:
		{
			PrintHintText(client,"burn baby burn!, burn it all!!");
			Give_Fire_Ammo(client);
			MaxPossibleHP = GetConVarInt(PYRO_HEALTH);
		}
		
		case TESLA:
		{
			PrintHintText(client,"Zombies that get to close will get a zap");
			MaxPossibleHP = GetConVarInt(TESLA_HEALTH);
			CreateTimer(3.0, DoZap,client,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		
		case PIPER:
		{
			PrintHintText(client,"you're a human pipe bomb, hold shift");
			MaxPossibleHP = GetConVarInt(PIPER_HEALTH);
		}
		
		case HAZMAT:
		{
			PrintHintText(client,"You're safe from spit ,bile and fire!!");
			MaxPossibleHP = GetConVarInt(HAZMAT_HEALTH);
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

	CreatePlayerClassMenu(client);
}

public Action:TimerDetectHealthChanges(Handle:hTimer, any:client)
{
	if (!client
		|| !IsValidEntity(client)
		|| !IsClientInGame(client)
		//|| !IsPlayerAlive(client)
		//|| GetClientTeam(client) != 2
		|| ClientData[client][PLAYERDATA:ChosenClass] != _:MEDIC)
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
public Action:CmdClasses(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i) && GetClientTeam(i) == 2  )
			{
				PrintToChat(client,"\x04%N\x01 : is a %s",i,MENU_OPTIONS[ClientData[i][PLAYERDATA:ChosenClass]]);		
			}
		}
	}
}

public Action:CmdClassInfo(client, args)
{
	PrintToChat(client,"\x05Soldier\x01 = faster fire rate");
	PrintToChat(client,"\x05Scout\x01 = jump higher and auto bunyhophop");
	PrintToChat(client,"\x05Medic\x01 = crouch to heal team, shift to drop defibs");
	PrintToChat(client,"\x05Saboture\x01 = hold crouch for invisability");
	PrintToChat(client,"\x05Commando\x01 = extra damage, fast reload");
	PrintToChat(client,"\x05Engineer\x01 = shift to drop auto turets and stuff");
	PrintToChat(client,"\x05Meat-Shield\x01 = lots of health");
	PrintToChat(client,"\x05SharpShooter\x01 = press walk to slow time");
	PrintToChat(client,"\x05Psychic\x01 = press crouch to see through walls");
	PrintToChat(client,"\x05Warper\x01 = shift to place portals");
	PrintToChat(client,"\x05DeathShot\x01 = hold crouch and dont move to charge a massive damage shot");
	PrintToChat(client,"\x05BossSlayer\x01 = cant be damaged by tank or witch");
	PrintToChat(client,"\x05Gambler\x01 = random health and bullet damage");
	PrintToChat(client,"\x05Flash\x01 = move very fast while near team mates");
	PrintToChat(client,"\x05Trapper\x01 = shift to drop various bomb types");
	PrintToChat(client,"\x05Blocker\x01 = cant be moved by special infected");
	PrintToChat(client,"\x05Penatrator\x01 = shoot specials through any wall atny distance");
	PrintToChat(client,"\x05Pyro\x01 = light everything on fire");
	PrintToChat(client,"\x05Piper\x01 = hold shift or crtl to control some zombie behavior, 10 kills earns a pipe");	
	PrintToChat(client,"\x05Hazmat\x01 = immune to bile and spitter goo");	
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
	
	ClientData[client][PLAYERDATA:Ignited] = false;
	
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
	Blocked[client] = false;
	
}

public Event_PlayerHurt(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new type = GetEventInt(hEvent, "type");
	
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:PYRO && GetClientTeam(client) == 2)
	{
		new entity = GetEventInt(hEvent, "attackerentid");
		
		if(entity > 0 && IsValidEntity(entity) && type !=8 )// && IsValidEdict(entity))
		{	
			if(IsCommonInfected(entity))
			{
				//PrintToChat(client,"pyro hit by a common");
				HurtEntity(entity, client , 1.0, 8);
			}
		}
	}
}

public Event_PlayerDeath(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	RebuildCache();
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ResetClientVariables(client);
}

public Event_PlayerShoved(Handle:hEvent, String:sName[], bool:bDontBroadcast)
{
	new shover = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	//new shovee = GetClientOfUserId(GetEventInt(hEvent, "userid"));	
	if (ClientData[shover][PLAYERDATA:ChosenClass] == _:HAZMAT)
	{
		new target = GetClientAimTarget(shover,false);
		
		if (IsValidEntity(target) && target < MaxClients && target > 0)
		{
			if((GetClientTeam(shover) == 2) && (GetClientTeam(target) == 2))
			{		

				decl Float:pos[3];
				decl Float:tpos[3];
				GetClientAbsOrigin(shover, pos);
				GetClientAbsOrigin(target, tpos);

				new Float:dist = GetVectorDistance(pos, tpos);			
				if (  dist < 150)
				{				
					UnVomit(target);
				}
			}			
		}
	}
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
		
		if (buttons & IN_JUMP &&  flags & FL_ONGROUND )
		{
			PushEntity(client, Float:{-90.0,0.0,0.0}, GetConVarFloat(ATHLETE_JUMP_VEL));
			
			flags &= ~FL_ONGROUND;
			SetEntityFlags(client,flags);
			// fakes the jump event so my suicide stopper plugin works
			FakeJumpEvent(client);
		
		}
	}
	ClientData[client][PLAYERDATA:LastButtons] = buttons;
	return Plugin_Continue;
}
void FakeJumpEvent(int client)
{
    Event event = CreateEvent("player_jump");
    if (event == null)
    {
        return;
    }
    event.SetInt("userid", GetClientUserId(client));
    event.Fire();
}

///////////////////////////////////////////////////////////////////////////////////
	// Commando
	///////////////////////////////////////////////////////////////////////////////////

public Event_RelCommandoClass(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:PYRO)
	{
		Give_Fire_Ammo(client);
		return;
	}
	if (ClientData[client][PLAYERDATA:ChosenClass] != _:SNIPER)
		return;
	
	new weapon = GetEntDataEnt2(client, g_oAW);

	if (!IsValidEntity(weapon))
		return;
	
	new Float:flGT = GetGameTime();
	decl String:bNetCl[64];
	decl String:stClass[32];

	GetEntityNetClass(weapon, bNetCl, sizeof(bNetCl));
	GetEntityNetClass(weapon,stClass,32);

	
	if (StrContains(bNetCl, "shotgun", false) == -1)
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);

		new Float:fRLRat = GetConVarFloat(COMMANDO_RELOAD_RATIO);
		new Float:fNTC = (GetEntDataFloat(weapon, g_iNPA) - flGT) * fRLRat;
		new Float:NA = fNTC + flGT;
		new Float:flNextTime_ret = GetEntDataFloat(weapon, g_iNPA);
		new Float:flStartTime_calc = flGT - ( flNextTime_ret - flGT ) * ( 1 - fRLRat ) ;
		WritePackFloat(hPack, flStartTime_calc);
		
		if ( (fNTC - 0.4) > 0 )
			CreateTimer( fNTC - 0.4, CommandoRelFireEnd2, hPack);
		
		SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
		SetEntDataFloat(weapon, g_ioTI, NA, true);
		SetEntDataFloat(weapon, g_iNPA, NA, true);
		SetEntDataFloat(client, g_ioNA, NA, true);
		CreateTimer(fNTC, CommandoRelFireEnd, weapon);
	}
	else
	{
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, weapon);
		

		if (StrContains(bNetCl, "shotgun_spas", false) != -1)
		{
			WritePackFloat(hPack, 0.293939);
			WritePackFloat(hPack, 0.272999);
			WritePackFloat(hPack, 0.675000);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "pumpshotgun", false) != -1)
		{

			WritePackFloat(hPack, 0.393939);
			WritePackFloat(hPack, 0.472999);
			WritePackFloat(hPack, 0.875000);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else if (StrContains(bNetCl, "autoshotgun", false) != -1)
		{
			WritePackFloat(hPack, 0.416666);
			WritePackFloat(hPack, 0.395999);
			WritePackFloat(hPack, 1.000000);

			CreateTimer(0.1, CommandoPumpShotReload, hPack);
		}
		else
			CloseHandle(hPack);
	}
}


public Action:CommandoRelFireEnd(Handle:timer, any:weapon)
{
	if (weapon <= 0 || !IsValidEntity(weapon))
		return Plugin_Stop;
	
	SetEntDataFloat(weapon, g_ioPR, 1.0, true);
	KillTimer(timer);

	return Plugin_Stop;
}

public Action:CommandoRelFireEnd2(Handle:timer, Handle:hPack)
{
	KillTimer(timer);
	if (IsServerProcessing()==false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}
	ResetPack(hPack);

	new weapon = ReadPackCell(hPack);
	new iCid = GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
	if (iCid <= 0 || IsValidEntity(iCid)==false || IsClientInGame(iCid)==false)
		return Plugin_Stop;

	new Float:flStartTime_calc = ReadPackFloat(hPack);
	CloseHandle(hPack);
	new iVMid = GetEntDataEnt2(iCid,g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);
	return Plugin_Stop;
}

public Action:CommandoPumpShotReload(Handle:timer, Handle:hOldPack)
{
	ResetPack(hOldPack);
	new weapon = ReadPackCell(hOldPack);
	new Float:fRLRat = GetConVarFloat(COMMANDO_RELOAD_RATIO);
	new Float:start = ReadPackFloat(hOldPack);
	new Float:insert = ReadPackFloat(hOldPack);
	new Float:end = ReadPackFloat(hOldPack);

	SetEntDataFloat(weapon,	g_iSSD,	start * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSID,	insert * fRLRat,	true);
	SetEntDataFloat(weapon,	g_iSED, end * fRLRat,	true);
	SetEntDataFloat(weapon, g_ioPR, 1.0 / fRLRat, true);
	
	CloseHandle(hOldPack);
	if (false) {
		PrintToChatAll("\x03-spas shotgun detected, ratio \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i", fRLRat, g_iSSD, g_iSID, g_iSED);
		PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",g_fl_SpasS, g_fl_SpasI, g_fl_SpasE);
	}

	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, weapon);
	
	if (GetEntData(weapon, g_iSRS) != 2)
	{
		WritePackFloat(hPack, 0.2);
		CreateTimer(0.3, CommandoShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		WritePackFloat(hPack, 1.0);
		CreateTimer(0.3, CommandoShotCalculate, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

public Action:CommandoShotCalculate(Handle:timer, Handle:hPack)
{
	ResetPack(hPack);
	new weapon = ReadPackCell(hPack);
	new Float:addMod = ReadPackFloat(hPack);
	
	if (weapon <= 0 || !IsValidEntity(weapon))
	{
		CloseHandle(hPack);
		KillTimer(timer);
		return Plugin_Stop;
	}
	
	if (GetEntData(weapon, g_iSRS) == 0 || GetEntData(weapon, g_iSRS) == 2 )
	{
		new Float:flNextTime = GetGameTime() + addMod;
		
		SetEntDataFloat(weapon, g_ioPR, 1.0, true);
		SetEntDataFloat(GetEntPropEnt(weapon, Prop_Data, "m_hOwner"), g_ioNA, flNextTime, true);
		SetEntDataFloat(weapon,	g_ioTI, flNextTime, true);
		SetEntDataFloat(weapon,	g_iNPA, flNextTime, true);
		KillTimer(timer);

		CloseHandle(hPack);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
/*public Event_RelSniperClass(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:SNIPER)
	{	//return;
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
	
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:PYRO)
	{
		Give_Fire_Ammo(client);
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
}*/

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

stock IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost");
}

public Plugin:myinfo =
{
	name = "Talents Plugin",
	author = "DLR / Neil, modified by spirit",
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
			
		case SHARPSHOOTER:
			return GetConVarInt( MAX_SHARPSHOOTER );
		case PSYCHIC:
			return GetConVarInt( MAX_PSYCHIC );
		case WARPER:
			return GetConVarInt( MAX_WARPER );
		case BIGSNIPER:
			return GetConVarInt( MAX_BIGSNIPER );
		case BOSSSLAYER:
			return GetConVarInt( MAX_BOSSSLAYER );
		case GAMBLER:
			return GetConVarInt( MAX_GAMBLER );
		case FLASH:
			return GetConVarInt( MAX_FLASH );
		
		case TRAPPER:
			return GetConVarInt( MAX_TRAPPER );	
		case BLOCKER:
			return GetConVarInt( MAX_BLOCKER );	
		case PENATRATOR:
			return GetConVarInt( MAX_PENATRATOR );	
		case PYRO:
			return GetConVarInt( MAX_PYRO );		
		case PIPER:
			return GetConVarInt( MAX_PIPER );	
		case HAZMAT:
			return GetConVarInt( MAX_HAZMAT );	
		case TESLA:
			return GetConVarInt( MAX_TESLA );	
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
stock bool:IsCommonInfected(iEntity)
{    
	if(iEntity > 0 && IsValidEntity(iEntity))
    {
        decl String:strClassName[64];
        GetEntityClassname(iEntity, strClassName, sizeof(strClassName));
        if(StrContains(strClassName, "infected") != -1)
		{
			return true;
		}
    }
    return false;
}
stock bool:IsTank(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8) return true;
    return false;
}

stock bool:IsSmoker(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 1) return true;
    return false;
}

stock bool:IsCharger(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 6) return true;
    return false;
}

stock bool:IsJockey(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 5) return true;
    return false;
}

stock bool:IsHunter(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 3) return true;
    return false;
}
stock bool:IsSpitter(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 4) return true;
    return false;
}
stock bool:IsBoomer(client)
{
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 2) return true;
    return false;
}
stock bool:IsInfected(client)
{
	if(IsTank(client)||IsHunter(client)||IsCharger(client)||IsJockey(client)||IsSmoker(client)||IsSpitter(client)||IsBoomer(client))return true;
	return false;
}
stock bool:IsLilInfected(client)
{
	if(IsHunter(client)||IsCharger(client)||IsJockey(client)||IsSmoker(client)||IsSpitter(client)||IsBoomer(client))return true;
	return false;
}

stock SlowTime(const String:desiredTimeScale[] = "0.2", const String:re_Acceleration[] = "2.0", const String:minBlendRate[] = "1.0", const String:blendDeltaMultiplier[] = "2.0")
{
	new ent = CreateEntityByName("func_timescale");
	
	DispatchKeyValue(ent, "desiredTimescale", desiredTimeScale);
	DispatchKeyValue(ent, "acceleration", re_Acceleration);
	DispatchKeyValue(ent, "minBlendRate", minBlendRate);
	DispatchKeyValue(ent, "blendDeltaMultiplier", blendDeltaMultiplier);
	
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Start");
	
	CreateTimer(1.5, _revertTimeSlow, ent);
}

public Action:_revertTimeSlow(Handle:timer, any:ent)
{
	if(IsValidEdict(ent))
	{
		AcceptEntityInput(ent, "Stop");
	}
}
public Float:GetSpeedBonus(client)
{
	new Float:Bonus;
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	for (new i = 1; i <= MaxClients; i++)//for each client
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
		{
			decl Float:tpos[3];
			GetClientAbsOrigin(i, tpos);
			new Float:dist = GetVectorDistance(pos, tpos);
			if (  dist < 1500 )
			{
				Bonus += 0.2;
			}
		}
	}
	return Bonus;
}

public bool:close_to_team(client)
{
	new Float:largest = 0.0; 
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
		
	for (new i = 1; i <= MaxClients; i++)//for each client
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i != client)
		{
			decl Float:tpos[3];
			GetClientAbsOrigin(i, tpos);
			
			new Float:dist = GetVectorDistance(pos, tpos);
			if (  dist > largest )
			{
				largest =  dist;
			}
		}
	}
		
	if(largest > 1500) 
	{
		//PrintToChatAll("to far away");	
		return false;
	}
	else
	{
		//PrintToChatAll("close to team");	
		return true;
	}
}

public Action:event_Grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	//take away flash speed boost on being grabbbed
	if (ClientData[victim][PLAYERDATA:ChosenClass] == _:FLASH)
	{
		SetEntDataFloat(victim, g_ioLMV, 1.0, true);
	}
	if(GetClientTeam(client) == 3)	
	{
		if (ClientData[victim][PLAYERDATA:ChosenClass] == _:BLOCKER)
		{
			if (IsCharger(client))//charger seems to work fine by changing movetypes of both players
			{
				//GetClientAbsOrigin(client,FreezeLocation[client]);
				//GetClientAbsOrigin(victim,FreezeLocation[victim]);
				//Blocked[client] = true;
				//Blocked[victim] = true;
				SetEntityMoveType(client, MOVETYPE_NONE);
				SetEntityMoveType(victim, MOVETYPE_NONE);	
			}
			if (IsSmoker(client))
			{
				SetEntityMoveType(victim, MOVETYPE_NONE);
			}
			if (IsJockey(client))
			{
				//GetClientAbsOrigin(victim,FreezeLocation[victim]);
				//Blocked[victim] = true;
				//SetEntityMoveType(client, MOVETYPE_NONE);
				//SetEntityMoveType(victim, MOVETYPE_NONE);//
				SetEntDataFloat(victim, g_ioLMV, 0.0 , true);
			}
			
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityMoveType(victim, MOVETYPE_NONE);		
		}
	}
}

public Action:event_impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new charger = GetClientOfUserId(GetEventInt(event, "userid"));
	new hitguy = GetClientOfUserId(GetEventInt(event, "victim"));

	if (ClientData[hitguy][PLAYERDATA:ChosenClass] == _:BLOCKER)
	{
		new MoveType:movetype = GetEntityMoveType(charger);
		SetEntityMoveType(charger,MOVETYPE_NONE);
	
		new Handle:hPack = CreateDataPack();
		WritePackCell(hPack, charger);
		WritePackCell(hPack, movetype);
		CreateTimer(0.1,StopFling,hitguy);
	}
}
public Action:StopFling(Handle:timer, any:client)
{	
	new Float:pos[3];
	new Float:ang[3];
	new Float:vec[3];
	GetClientAbsOrigin(client,pos);
	GetClientEyeAngles(client,ang);
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", vec);
	NegateVector(vec);
	TeleportEntity(client,pos,ang,vec);
	return Plugin_Stop;
}
public Action:event_GrabEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	Blocked[client] = false;
	Blocked[victim] = false;
	
	SetEntDataFloat(victim, g_ioLMV, 1.0 , true);
	
	if(GetEntityMoveType(victim)== MOVETYPE_NONE)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityMoveType(victim, MOVETYPE_WALK);
	}
}

public Action:Event_PlayerVomited(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ClientData[client][PLAYERDATA:ChosenClass] == _:HAZMAT)
	{
		UnVomit(client);
	}
}
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", pentratorweapon, 64);
	//PrintToChat(client,"weapon shot fired");
	
	/*if (ClientData[client][PLAYERDATA:ChosenClass] == _:NONE && GetClientTeam(client) == 2)
	{
		if(client >0 && client < MAXPLAYERS + 1)
		{
			PrintHintText(client,"you should pick a class, it will help you survive the onslaught");
			CreatePlayerClassMenu(client);
		}
	}*/
	
	if(ClientData[client][PLAYERDATA:ChosenClass] == _:BIGSNIPER)
	{
		if (ClientData[client][PLAYERDATA:Charged] == true)
		{	
			if (ClientData[client][PLAYERDATA:ExplosionCreated] == true)
			{
				ClientData[client][PLAYERDATA:Charged] = false;
				ClientData[client][PLAYERDATA:Is_charging] = false;
			}
		}
	}
	
	if(ClientData[client][PLAYERDATA:ChosenClass] == _:PENATRATOR)
	{
		WallBang(client);
	}
	
	return Plugin_Continue;
}

public bool:_TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return true;
	}
	
	return false;
}

public WitchHurt_Event(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker")); 
	new victim = GetEventInt(event, "entityid"); 
	new type = GetEventInt(event, "type");

	if (attacker && attacker <= MaxClients)
	{
		if(GetClientTeam(attacker)!= 2)
			return;

		switch (ClientData[attacker][PLAYERDATA:ChosenClass])
		{
			case BIGSNIPER:
			{
				if (ClientData[attacker][PLAYERDATA:Charged] == true)
				{	
					if( IsWitch(victim))
					{	//reset the shot if hits witch
						ClientData[attacker][PLAYERDATA:Charged] = false;
						//damage the witch
						DealDamage(victim, attacker , 2000.0, 0);
						return;// Plugin_Changed;				
					}
				}	
			}
	
			case PIPER: //reenable this for piper pipe bombs
			{
				if(GetClientTeam(attacker) == 2)
				{
					ClientData[attacker][PLAYERDATA:ItemsBuilt] ++;
					if(ClientData[attacker][PLAYERDATA:ItemsBuilt] > 20)
					{
						Give_PipeBomb(attacker);
						ClientData[attacker][PLAYERDATA:ItemsBuilt] = 0;	
					}
				}
			}
	
			case PYRO:
			{
				if(IsValidEntity(victim) && type != 8) 
				{
					DealDamage(victim, attacker , 1.0, 8);
					//IgniteEntity(victim,3.0,true);
				}
			}
		}
	}
	return;
}

DropTimeBomb(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Handle:hPack = CreateDataPack();
	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, client);
	WritePackCell(hPack, RndSession);
	CreateTimer(10.0, TimeBombExplode, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	
	EmitSoundToAll(SOUND_DROP_BOMB);
	
	PrintToChat(client, "%sYou dropped a \x04Time bomb", PRINT_PREFIX);
}
public Action:TimeBombExplode(Handle:hTimer, Handle:hPack)
{
	new Float:pos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	new owner = ReadPackCell(hPack);
	new session = ReadPackCell(hPack);
	
	if (session != RndSession)
		return Plugin_Stop;
	
	PrintToChatAll("%s\x03%N\x01's \x04Time bomb \x01detonated!", PRINT_PREFIX, owner);
	CreateExplosion(pos, owner, false);
	CloseHandle(hPack);
	return Plugin_Stop;	
	
}

//----------------FREEZE MINE------------
DropFreezeMine(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	//new Handle:hPack = CreateDataPack();
	
	new Handle:hPack = CreateDataPack();
	WritePackFloat(hPack, pos[0]);
	WritePackFloat(hPack, pos[1]);
	WritePackFloat(hPack, pos[2]);
	WritePackCell(hPack, client);
	WritePackCell(hPack, RndSession);
	CreateTimer(GetConVarFloat(SABOTEUR_BOMB_ACTIVATE), TimerActivateFreezeBomb, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos, 10.0, 256.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	
	EmitSoundToAll(SOUND_DROP_BOMB);
	
	PrintToChat(client, "%sYou dropped a \x04Freeze Mine", PRINT_PREFIX);
}

public Action:TimerActivateFreezeBomb(Handle:hTimer, Handle:hPack)
{
	CreateTimer(0.3, TimerCheckFreezeBombSensors, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

public Action:TimerCheckFreezeBombSensors(Handle:hTimer, Handle:hPack)
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
		if (!IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsGhost(client)  )
			continue;
		
		GetClientAbsOrigin(client, clientpos);
		
		if(GetClientTeam(client) == 3)
		{
		
			if (GetVectorDistance(pos, clientpos) < GetConVarFloat(SABOTEUR_BOMB_RADIUS))
			{
				PrintToChatAll("%s\x03%N\x01's \x04 Freeze bomb \x01detonated!", PRINT_PREFIX, owner);
				
				TimeBombFreeze(Handle:hTimer, Handle:hPack);
				//CloseHandle(hPack);
				return Plugin_Stop;
			}
		}
	}
	
	return Plugin_Continue;
}
public Action:TimeBombFreeze(Handle:hTimer, Handle:hPack)
{
	new Float:pos[3];
	
	ResetPack(hPack);
	pos[0] = ReadPackFloat(hPack);
	pos[1] = ReadPackFloat(hPack);
	pos[2] = ReadPackFloat(hPack);
	new owner = ReadPackCell(hPack);
	new session = ReadPackCell(hPack);
	
	if (session != RndSession)
		return Plugin_Stop;
		
	EmitSoundToAll(FREEZE_SOUND);
		
	//PrintToChatAll("%s\x03%N\x01's \x04Freeze bomb \x01detonated!", PRINT_PREFIX, owner);
	//freeze logic
	for (new i = 1; i <= MaxClients; i++)//for each client
	{
		if (IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && !IsGhost(i) && GetClientTeam(i) == 3)
		{
			decl Float:tpos[3];
			GetClientAbsOrigin(i, tpos);
			new Float:dist = GetVectorDistance(pos, tpos);
			if (  dist < GetConVarInt(SABOTEUR_FREEZE_RANGE) )
			{
				ClientData[i][PLAYERDATA:FrozenTime] = (GetGameTime() + GetConVarFloat(SABOTEUR_FREEZE_DURATION));
				GetClientAbsOrigin(i,FreezeLocation[i]);
				PrintToChatAll("%N was frozen by %N", i,owner);
			}
		}
	}
	CloseHandle(hPack);
	return Plugin_Stop;	
}
public Action:FreezeLogic(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidEntity(i) || !IsClientInGame(i))
			continue;
		if(OutlineState && GetClientTeam(i) == 3)
		{	
			if(!IsGhost(i))
			{
				SetEntProp(i, Prop_Send, "m_iGlowType", 3);
				SetEntProp(i, Prop_Send, "m_glowColorOverride", 255);
			}
			else
			{
				SetEntProp(i, Prop_Send, "m_iGlowType", 3); 
				SetEntProp(i, Prop_Send, "m_glowColorOverride", 16777215); //white 61184); //green
			}	
		}
		else 
		{
			SetEntProp(i, Prop_Send, "m_iGlowType", 0);
			SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);	
		}			
	
	
	}
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (!IsValidEntity(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || IsGhost(i)  )
			continue;
		
		if((GetGameTime() < ClientData[i][PLAYERDATA:FrozenTime]) || Blocked[i] == true  )
		{
			//freeze
			TeleportEntity(i,FreezeLocation[i],NULL_VECTOR,NULL_VECTOR);
			if(GetGameTime() < ClientData[i][PLAYERDATA:FrozenTime])
			{	
				PrintHintText(i,"you are frozen");
				SetEntityRenderColor(i, 0, 0, 100, 125);
			}
		}
		else		
		{	
			//unfreeze
			SetEntityRenderColor(i, 255, 255, 255,255);
		}
	}
	return Plugin_Continue;
}

public Action:Event_LeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{	//used to start the freeze logic
	RoundStarted = true;
	PrintToChatAll("%sPlayers left safe area, classes now locked",PRINT_PREFIX);
	
	if(!timer_triggered)
	{		
		CreateTimer(0.1, FreezeLogic,0,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
		timer_triggered = true;
	}
}
public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(ClientData[client][PLAYERDATA:ChosenClass] == _:BIGSNIPER)
	{
		if (ClientData[client][PLAYERDATA:Charged] == true)
		{
			if (!ClientData[client][PLAYERDATA:ExplosionCreated] == true)
			{
				decl Float:Origin[3];	
				Origin[0] = GetEventFloat(event,"x");
				Origin[1] = GetEventFloat(event,"y");
				Origin[2] = GetEventFloat(event,"z");
				CreateExplosion(Origin,client,true);
				ClientData[client][PLAYERDATA:ExplosionCreated] = true;
				
				//destroy events code	new target;
				new target = GetClientAimTarget(client,false);
					if(IsTankHitable(target))
					{
						AcceptEntityInput(target, "Kill"); 
						PrintToChatAll("%s KABOOM!",PRINT_PREFIX);
					}
				
				if(IsValidEntity(target))
				{		
					new String:modelname[128]; 
					GetEntPropString(target, Prop_Data, "m_ModelName", modelname, 128);
					if (StrContains(modelname, BAR_MDL)!=-1)
					{
						AcceptEntityInput(target, "Kill"); 
						PrintToChatAll("%sThats How You Clear A Path!!!",PRINT_PREFIX);
					}
				}	
			}
		}
	}
}

float getdamage()
{
	if (StrContains(pentratorweapon,"rifle", false)!=-1)
	{
		return 40.0;
	}
	if (StrContains(pentratorweapon,"shotgun", false)!=-1)
	{
		return 750.0;
	}
	if (StrContains(pentratorweapon, "sniper", false)!=-1)
	{
		return 250.0;
	}
	if (StrContains(pentratorweapon, "hunting", false)!=-1)
	{
		return 120.0;
	}
	if (StrContains(pentratorweapon, "pistol", false)!=-1)
	{
		return 30.0;
	}
	if (StrContains(pentratorweapon, "smg", false)!=-1)
	{
		return 25.0;
	}
	return 0.0;
}

WallHack()
{
	OutlineState = true;
	CreateTimer(GetConVarFloat(PSYCHIC_ABILITY_TIME),UnWallHack);
}

public Action:UnWallHack(Handle:hTimer)
{
	OutlineState = false;
	return Plugin_Stop;
}

public CreateChase(Float:pos[3])
{
	new chaser = CreateEntityByName("info_goal_infected_chase");
	//decl Float:pos[3];
	//GetClientAbsOrigin(client, pos);
	
	DispatchSpawn(chaser);
	AcceptEntityInput(chaser, "Enable"); 
	
	TeleportEntity(chaser,pos,NULL_VECTOR,NULL_VECTOR);
	
	CreateTimer(2.0,KillChase, any:chaser);
	
}

public Action:KillChase(Handle:hTimer,any:ent)
{
	if(IsValidEntity(ent))
		AcceptEntityInput(ent,"kill");
	
	return Plugin_Stop;
}

public Give_Fire_Ammo(client)
{
	new String:command[] = "upgrade_add"; 
	new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT); 
    FakeClientCommand(client, "%s INCENDIARY_AMMO", command);
	SetCommandFlags(command, flags);
}

public Give_PipeBomb(client)
{
	new String:command[] = "give"; 
	new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT); 
    FakeClientCommand(client, "%s pipe_bomb", command);
	SetCommandFlags(command, flags);
}

WallBang(client)
{
	new Float:pos[3];
	new Float:ang[3];
	
	GetClientEyePosition(client,pos);
	GetClientEyeAngles(client,ang);
	
	new Handle:trace  = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite,_TraceFilter, client); 
	new Float:wPos[3];// wall position
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(wPos,trace);
	}
	CloseHandle(trace);
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if(target != client && IsValidTarget(target))
		{
			new Float:tpos[3];
			GetClientAbsOrigin(target,tpos);
			tpos[2] = (tpos[2] + 40);//adjust heigth so it triggers without looking at feet
		
			if ( GetVectorDistance(pos, tpos) > GetVectorDistance(pos, wPos))
			{
				new Float:radius = GetRadius(target);
				if(check(pos,ang,tpos,radius))
				{
					HurtEntity(target, client , getdamage(), 0);
				}
			}
		}
	}
}
bool IsValidTarget(target)
{
	if(IsClientInGame(target) && GetClientTeam(target)==3 && !IsGhost(target) && IsPlayerAlive(target))
	{
		return true;
	}
	return false;
}

bool check(Float:pos[3],Float:ang[3],Float:tpos[3], Float:radius )
{
	//line intersect sphere code
	new Float:l[3];//l = line direction
	GetAngleVectors(ang, l, NULL_VECTOR, NULL_VECTOR);
	// Get origin of line o
	
	new Float:o[3];
	o[0] = pos[0];
	o[1] = pos[1];
	o[2] = pos[2];
	new Float:o_Minus_c[3];
	
	// Sphere vectors
	//new Float:radius = 25.0;
	new Float:c[3];
	new Float:delta;
            
	c[0] = tpos[0];
	c[1] = tpos[1];
	c[2] = tpos[2];
	SubtractVectors(o,c,o_Minus_c);
            
	delta = GetVectorDotProduct(l, o_Minus_c) * GetVectorDotProduct(l, o_Minus_c) 
	- GetVectorLength(o_Minus_c, true) + radius*radius;

	if (delta >= 0.0) 
	{
		return true;
	}
	return false;
}
Float:GetRadius(int target)
{
	if(IsTank(target))
		return 70.0;
	return 40.0;
}

UnVomit(client)
{
    static Handle hUnvomit;
    if (!hUnvomit)
	{
        StartPrepSDKCall(SDKCall_Player);
        if(!PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer11OnITExpiredEv", 0))
		{ 
            SetFailState("hUnvomit A broken"); 
        }
        hUnvomit = EndPrepSDKCall();
    }
    if (!hUnvomit){ SetFailState("hUnvomit B broken"); return; }

	if( client && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		SDKCall(hUnvomit, client);
	}
} 


	public event_HealBegin(Handle:event, const String:name[], bool:Broadcast)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		UpgradeQuickHeal(client);
	}

	public event_ReviveBegin(Handle:event, const String:name[], bool:Broadcast)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		UpgradeQuickRevive(client);
	}
	
	public UpgradeQuickHeal(client)
	{
		if(ClientData[client][PLAYERDATA:ChosenClass] == _:MEDIC)
			SetConVarFloat(g_VarFirstAidDuration, FirstAidDuration * 0.2, false, false);
		else
			SetConVarFloat(g_VarFirstAidDuration, FirstAidDuration * 1.0, false, false);
	}

	public UpgradeQuickRevive(client)
	{
		if(ClientData[client][PLAYERDATA:ChosenClass] == _:MEDIC)
			SetConVarFloat(g_VarReviveDuration, ReviveDuration * 0.2, false, false);
		else
			SetConVarFloat(g_VarReviveDuration, ReviveDuration * 1.0, false, false);
	}
	
	ApplyHealthModifiers()
	{
		FirstAidDuration = GetConVarFloat(FindConVar("first_aid_kit_use_duration"));
		ReviveDuration = GetConVarFloat(FindConVar("survivor_revive_duration"));
		g_VarFirstAidDuration = FindConVar("first_aid_kit_use_duration");
		g_VarReviveDuration = FindConVar("survivor_revive_duration");
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
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#include <sdktools_functions>

#define Pai 3.14159265358979323846 
#define DEBUG false

#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"  
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
}*/
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
/*public Action:witch_harasser_set(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new witch =  GetEventInt(hEvent, "witchid") ; 
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
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);	
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
	gun=CreateEntityByName (   "prop_minigun"); 
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
	CloseHandle(trace); 
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
			HurtEntity(enemy, client, 10.0, 0);
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
	CloseHandle(trace);
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
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		return particle;
	}  
	return 0;
}

public Action:CmdForceCampainStart(client, args)
{
	RoundStarted = true;



}
