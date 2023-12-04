/* put the line below after all of the includes!
#pragma newdecls required
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

native void ShowHealthGauge(int client, int maxBAR, int maxHP, int nowHP, char clName[64]);

public SharedPlugin __pl_l4d_infectedhp_redux = 
{
	name = "l4d_infectedhp_redux", file = "l4d_infectedhp_redux.smx",
	required = 0
};

public void __pl_l4d_infectedhp_redux_SetNTVOptional() 
{
	MarkNativeAsOptional("ShowHealthGauge");
}

#define GETVERSION "1.0.4"
#define ARRAY_SIZE 2150

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0
#define DEBUG 0

bool g_bLowWreck[ARRAY_SIZE] = { false, ... };
bool g_bMidWreck[ARRAY_SIZE] = { false, ... };
bool g_bHighWreck[ARRAY_SIZE] = { false, ... };
bool g_bCritWreck[ARRAY_SIZE] = { false, ... };
bool g_bHooked[ARRAY_SIZE] = { false, ... };
int g_iEntityDamage[ARRAY_SIZE] = { 0, ... };
int g_iParticle[ARRAY_SIZE] = { -1, ... };

bool g_bDisabled = false;
bool g_bFindCars = false;

Handle g_cvarTankMaxHealth = INVALID_HANDLE;
Handle g_cvarMaxHealth = INVALID_HANDLE;
Handle g_cvarInfected = INVALID_HANDLE;
Handle g_cvarTankDamage = INVALID_HANDLE;
Handle g_cvarUnload = INVALID_HANDLE;
Handle g_cvarExplosionDmg = INVALID_HANDLE;
Handle g_cvarSelfHurt = INVALID_HANDLE;
Handle g_cvarFireMulti = INVALID_HANDLE;
Handle g_cvarExploMulti = INVALID_HANDLE;

Handle g_tBurning[ARRAY_SIZE+1] = { INVALID_HANDLE, ... };

char DAMAGE_WHITE_SMOKE[] = 	"minigun_overheat_smoke";
char DAMAGE_BLACK_SMOKE[] = 	"smoke_burning_engine_01";
char DAMAGE_FIRE_SMALL[] = 	"burning_engine_01";
char DAMAGE_FIRE_HUGE[] = 	"fire_window_hotel2";
char FIRE_SOUND[] = 			"ambient/fire/fire_med_loop1.wav";

public Plugin myinfo = 
{
	name = "[L4D2] Cars Health",
	author = "honorcode23, edit by Eyal282",
	description = "Cars disappear after they take some damage.",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=138644"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(late)
	{
		g_bFindCars = true;
	}
	return APLRes_Success;
}


bool bHealthGaugeAvailable = false;

public void OnAllPluginsLoaded()
{
	bHealthGaugeAvailable = false;

	if(GetFeatureStatus(FeatureType_Native, "ShowHealthGauge") == FeatureStatus_Available)
	{
		bHealthGaugeAvailable = true;
	}
}
public void OnPluginStart()
{	
	//Convars
	CreateConVar("l4d2_cars_health_version", GETVERSION, "Version of the [L4D2] Cars Health plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_cvarTankMaxHealth = FindConVar("z_tank_health");
	
	g_cvarMaxHealth = CreateConVar("l4d2_cars_health_health", "-1", "Maximum health of the cars, set to 0 to disable the plugin. Set to a negative number to make the car's health a multiplier of the tank's max health.", _);
	g_cvarInfected = CreateConVar("l4d2_cars_health_infected", "1", "Should infected trigger the car explosion? (1: Yes 0: No)", _);
	g_cvarTankDamage = CreateConVar("l4d2_cars_health_cars_tank", "0", "How much damage do the tank deal to the cars? (0: Default, which is 999 from the engine)", _);
	g_cvarFireMulti = CreateConVar("l4d2_cars_health_cars_fire_multiplier", "2.42", "Multiplier of the damage received by the car from fire (Note: Normal is 8 damage per 0.5 secs)", _);
	g_cvarExploMulti = CreateConVar("l4d2_cars_health_cars_explosion_multiplier", "1.0", "Multiplier of the damage received by the car from explosions (Pipe bombs, grenade launcher, propane tanks, etc) (Note: Normal is 15-20 damage per shot)", _);
	
	AutoExecConfig(true, "l4d2_cars_health");
	
	//Events
	HookEvent("round_start_post_nav", Event_RoundStart);
	
	if(g_bFindCars)
	{
		FindMapCars();
	}
	g_bFindCars = false;
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
	PrecacheParticle(DAMAGE_WHITE_SMOKE);
	PrecacheParticle(DAMAGE_BLACK_SMOKE);
	PrecacheParticle(DAMAGE_FIRE_SMALL);
	PrecacheParticle(DAMAGE_FIRE_HUGE);
	for(int i =1 ; i <= ARRAY_SIZE; i++)
	{
		g_tBurning[i] = INVALID_HANDLE;
	}
}

public void Event_RoundStart(Handle event, char[] event_name, bool dontBroadcast)
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
		g_iParticle[i] = -1;
	}
}

//Thanks to AtomicStryker
static FindMapCars()
{
	if(g_bDisabled)
	{
		return;
	}
	int maxEnts = GetMaxEntities();
	
	for (int i = MaxClients; i < maxEnts; i++)
	{
		if (!IsValidEdict(i))
			continue;
		
		else if(!IsTankProp(i))
			continue;
		
		g_bHooked[i] = true;
		SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
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
	else if(entity <= 0 || entity >= ARRAY_SIZE)
		return;
		
	else if(g_bHooked[entity])
		return;

	SDKHook(entity, SDKHook_SpawnPost, SDKHook_OnEntitySpawned);
}

public void SDKHook_OnEntitySpawned(int entity)
{
	if(!IsTankProp(entity))
		return;

	SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	g_bHooked[entity] = true;
}

public Action timerCheckChanges(Handle timer, any entity)
{
	if(IsValidEntity(entity))
	{
		PrintToChatAll("\x05[POST] \x01Molotov Projectile Created");
		PrintToChatAll("\x05[POST] \x01Comencing Dump");
		PrintToChatAll("\x05[POST] \x01m_flDamage -> %f", GetEntPropFloat(entity, Prop_Send, "m_flDamage"));
		PrintToChatAll("\x05[POST] \x01m_DmgRadius -> %f", GetEntPropFloat(entity, Prop_Send, "m_DmgRadius"));
		PrintToChatAll("\x05[POST] \x01m_bIsLive -> %b", GetEntProp(entity, Prop_Send, "m_bIsLive"));
		PrintToChatAll("\x05[POST] \x01m_fFlags -> %i", GetEntProp(entity, Prop_Send, "m_fFlags"));
	}

	return Plugin_Continue;
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if(g_bDisabled)
	{
		return;
	}
	char class[256];
	GetEdictClassname(inflictor, class, sizeof(class));
	
	int maxHealth = GetConVarInt(g_cvarMaxHealth);

	if(maxHealth == 0)
		return;

	else if(maxHealth < 0)
	{
		maxHealth *= GetConVarInt(g_cvarTankMaxHealth);

		maxHealth *= -1;
	}
	int MaxDamageHandle = maxHealth / 5;
	
	if(StrEqual(class, "weapon_melee"))
	{
		damage = 5.0;
	}
	else if(StrEqual(class, "env_explosion") && !GetConVarBool(g_cvarExplosionDmg))
	{
		damage = 0.0;
	}
	else if((StrEqual(class, "player") && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 3) && !GetConVarBool(g_cvarInfected))
	{
		damage = 0.0;
	}
	else if(StrEqual(class, "tank_rock") || StrEqual(class, "weapon_tank_claw"))
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
	else if(StrEqual(class, "inferno") || (StrEqual(class, "trigger_hurt") && (damagetype == 8 || damagetype == 2056)))
	{
		damage*=GetConVarFloat(g_cvarFireMulti);
	}
	else if(StrEqual(class, "pipe_bomb_projectile") || StrEqual(class, "grenade_launcher_projectile"))
	{
		damage*=GetConVarFloat(g_cvarExploMulti);
	}
	
	g_iEntityDamage[victim]+= RoundToFloor(damage);
	int tdamage = g_iEntityDamage[victim];
	//PrintHintTextToAll("%i damaged by <%N>(%i) (inflictor: <%s>%d) for %f damage (Type: %d)", victim, attacker, attacker, class, inflictor, damage, damagetype);
	
	if(tdamage >= MaxDamageHandle
	&& tdamage < MaxDamageHandle*2
	&& !g_bLowWreck[victim])
	{
		g_bLowWreck[victim] = true;
		AttachParticle(victim, DAMAGE_WHITE_SMOKE);
	}
	else if(tdamage >= MaxDamageHandle*2
	&& tdamage < MaxDamageHandle*3
	&& !g_bMidWreck[victim])
	{
		g_bMidWreck[victim] = true;
		AttachParticle(victim, DAMAGE_BLACK_SMOKE);
	}
	
	else if(tdamage >= MaxDamageHandle*3
	&& tdamage < MaxDamageHandle*4
	&& !g_bHighWreck[victim])
	{
		g_bHighWreck[victim] = true;

		PrecacheSound(FIRE_SOUND);

		EmitSoundToAll(FIRE_SOUND, victim);
		AttachParticle(victim, DAMAGE_FIRE_SMALL);
		if(GetConVarBool(g_cvarSelfHurt))
		{
			if(g_tBurning[victim] == INVALID_HANDLE)
			{
				g_tBurning[victim] = CreateTimer(0.2, timerHurtCar, victim, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	else if(tdamage >= MaxDamageHandle*4
	&& tdamage < MaxDamageHandle*5
	&& !g_bCritWreck[victim])
	{
		g_bCritWreck[victim] = true;
		AttachParticle(victim, DAMAGE_FIRE_HUGE);
	}
	
	else if(tdamage > MaxDamageHandle*5)
	{
		float carPos[3];
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", carPos);
		if(attacker > MaxClients)
		{
			attacker = 0;
		}

		AcceptEntityInput(victim, "Kill");
	}

	if(bHealthGaugeAvailable)
	{
		ShowHealthGauge(attacker, 0, maxHealth, maxHealth - tdamage, "Tank Car");
	}
}

public Action timerHurtCar(Handle timer, any car)
{
	g_tBurning[car] = INVALID_HANDLE;
	if(!IsValidEntity(car))
	{
		return Plugin_Continue;
	}
	int damage = 8;
	char sDamage[11], sTarget[16];
	IntToString(damage, sDamage, sizeof(sDamage));
	IntToString(car+25, sTarget, sizeof(sTarget));
	int iDmgEntity = CreateEntityByName("point_hurt");
	DispatchKeyValue(car, "targetname", sTarget);
	DispatchKeyValue(iDmgEntity, "DamageTarget", sTarget);
	DispatchKeyValue(iDmgEntity, "Damage", sDamage);
	DispatchKeyValue(iDmgEntity, "DamageType", "8");
	DispatchSpawn(iDmgEntity);
	AcceptEntityInput(iDmgEntity, "Hurt", car);
	RemoveEdict(iDmgEntity);

	if(g_tBurning[car] == INVALID_HANDLE)
	{
		g_tBurning[car] = CreateTimer(0.2, timerHurtCar, car, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

stock void EditCar(int car)
{
	SetEntityRenderColor(car, 0, 0, 0, 255);
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

public Action timerNormalVelocity(Handle timer, any car)
{
	if(g_bDisabled)
	{
		return Plugin_Continue;
	}

	if(IsValidEntity(car))
	{
		float vel[3];
		SetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
		TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	}

	return Plugin_Continue;
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
		return Plugin_Continue;
	}

	if(IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}

	return Plugin_Continue;
}

stock void AttachParticle(int car, const char[] Particle_Name)
{
	if(g_bDisabled)
	{
		return;
	}
	float carPos[3];
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
	char sName[64];
	Format(sName, sizeof(sName), "%d", userid+25);
	DispatchKeyValue(car, "targetname", sName);
	GetEntPropString(car, Prop_Data, "m_iName", sName, sizeof(sName));
	
	char sTargetName[64];
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

stock bool IsTankProp(int entity)
{
	if(!IsValidEdict(entity))
	{
		return false;
	}
	
	char className[64];
	
	GetEdictClassname(entity, className, sizeof(className));

	if(StrEqual(className, "prop_physics"))
	{
		if(GetEntProp(entity, Prop_Send, "m_hasTankGlow"))
		{
			return true;
		}
	}
	else if(StrEqual(className, "prop_car_alarm"))
	{
		return true;
	}
	
	return false;
}