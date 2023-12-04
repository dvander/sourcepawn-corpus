#define PLUGIN_VERSION		"1.1.1"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"grenadelauncher_remote"
#define PLUGIN_NAME_FULL	"[L4D2] Remote Control Grenade Launcher"
#define PLUGIN_DESCRIPTION	"hold fire key to delay the explosion of grenade and sticky to zombie"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://steamcommunity.com/id/NoroHime/"

/**
 *	v1.0 just releases; 30-November-2022
 *	v1.1 pipe bomb flashing effects will attach to projectile, make you felt really controls it; 30-November-2022 (2nd time)
 *	v1.1.1 fixes:
 *		- fix flashing particle entity leak,
 *		- fix flashing particle sometime doesnt appear; 6-December-2022
 */
 
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsEntity(%1) (2048 >= %1 > MaxClients)
#define IsHumanSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2 && !IsFakeClient(%1))

native int L4D_DetonateProjectile(int entity);

GlobalForward GlobalOnGLProjectileReplaced;
bool bBlockForwarding = false;

forward void OnGLProjectileReplaced(int before, int after, int client);

native void DisableGLListener();
native void EnableGLListener();

bool bIsGLRandomExists = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("DisableGLListener");
	MarkNativeAsOptional("EnableGLListener");
	MarkNativeAsOptional("L4D_DetonateProjectile");
	RegPluginLibrary(PLUGIN_PREFIX ... PLUGIN_NAME);
	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	if( LibraryExists("l4d2_grenadelauncher_random") == true ) {
		bIsGLRandomExists = true;
	}
}

public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "l4d2_grenadelauncher_random") == 0 ) {
		bIsGLRandomExists = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "l4d2_grenadelauncher_random") == 0 ) {
		bIsGLRandomExists = false;
	}
}


public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

enum {
	MOLOTOV =	(1 << 0),
	PIPE_BOMB =	(1 << 1),
	SPITTER =	(1 << 2),
	VOMIT_JAR =	(1 << 3),
	TANK_ROCK =	(1 << 4),
}

ConVar cTimeout;		float flTimeout;
ConVar cHoldTime;		float flHoldTime;
ConVar cGravity;		float flGravity;
ConVar cVelocity;		float flVelocity;
ConVar cRadius;			char sRadius[32];
ConVar cDamage;			char sDamage[32];
ConVar cFFScale;		float flFFScale;
ConVar cFFScaleSelf;	float flFFScaleSelf;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cTimeout =		CreateConVar(PLUGIN_NAME ... "_timeout", "6.0",		"time(seconds) of timeout to detonate the grenade 0=dont", FCVAR_NOTIFY);
	cHoldTime =		CreateConVar(PLUGIN_NAME ... "_holdtime", "0.1",	"time(seconds) of hold attack key to make a remote grenade", FCVAR_NOTIFY);
	cGravity =		CreateConVar(PLUGIN_NAME ... "_gravity", "0.75",	"projectile gravity scaler", FCVAR_NOTIFY);
	cVelocity =		CreateConVar(PLUGIN_NAME ... "_velocity", "1.0",	"projectile veloctiy scaler", FCVAR_NOTIFY);
	cRadius =		FindConVar	("grenadelauncher_radius_kill");
	cDamage =		FindConVar	("grenadelauncher_damage");
	cFFScale =		FindConVar	("grenadelauncher_ff_scale");
	cFFScaleSelf =	FindConVar	("grenadelauncher_ff_scale_self");

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cTimeout.AddChangeHook(OnConVarChanged);
	cHoldTime.AddChangeHook(OnConVarChanged);
	cGravity.AddChangeHook(OnConVarChanged);
	cVelocity.AddChangeHook(OnConVarChanged);
	cRadius.AddChangeHook(OnConVarChanged);
	cDamage.AddChangeHook(OnConVarChanged);
	cFFScale.AddChangeHook(OnConVarChanged);
	cFFScaleSelf.AddChangeHook(OnConVarChanged);

	HookEvent("weapon_fire", OnWeaponFire);

	ApplyCvars();

	GlobalOnGLProjectileReplaced = new GlobalForward("OnGLProjectileReplaced", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}


void ApplyCvars() {

	flTimeout = cTimeout.FloatValue;
	flHoldTime = cHoldTime.FloatValue;
	flGravity = cGravity.FloatValue;
	flVelocity = cVelocity.FloatValue;
	cRadius.GetString(sRadius, sizeof(sRadius));
	cDamage.GetString(sDamage, sizeof(sDamage));
	flFFScale = cFFScale.FloatValue;
	flFFScaleSelf = cFFScaleSelf.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
  
public void OnConfigsExecuted() {
	ApplyCvars();
}

int iOwnerProjectile [MAXPLAYERS + 1];
float timeCreatedProjectile [2048];
bool timeControlledProjectile [2048];
bool bBlockProjectileSpawnHook = false;
float timeHoldedAttack [MAXPLAYERS + 1];

void OnWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	
	if (event.GetInt("weaponid") == 21) {

		int client = GetClientOfUserId(event.GetInt("userid"));

		if (IsHumanSurvivor(client))
			timeHoldedAttack[client] = GetEngineTime();
	}
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (!bBlockProjectileSpawnHook && strcmp(classname, "grenade_launcher_projectile") == 0)
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileCreated);
}

public void OnEntityDestroyed(int entity) {

	if (IsEntity(entity)) {

		timeCreatedProjectile[entity] = 0.0;
		timeControlledProjectile[entity] = false;
	}
}

void OnProjectileCreated(int entity) {

	if (IsEntity(entity)) {
		RequestFrame(OnProjectileCreatedFrame, EntIndexToEntRef(entity));
	}
}

public void OnGLProjectileReplaced(int before, int after, int client) {

	if (bBlockForwarding)
		return;

	if (IsHumanSurvivor(client) && before != after) {

		iOwnerProjectile[client] = EntIndexToEntRef(after);
		timeCreatedProjectile[after] = GetEngineTime();

		float vPos[3], vAng[3], vVel[3];
		GetEntPropVector(after, Prop_Data, "m_angRotation", vAng);
		GetEntPropVector(after, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(after, Prop_Send, "m_vInitialVelocity", vVel);
		// Set origin and velocity
		float vDir[3];
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0] * 10;
		vPos[1] += vDir[1] * 10;
		vPos[2] += vDir[2] * 10;

		ScaleVector(vVel, flVelocity);

		TeleportEntity(after, vPos, NULL_VECTOR, vVel);
		SetEntPropFloat(after, Prop_Data, "m_flGravity", flGravity);

		SDKHook(after, SDKHook_Touch, OnProjectileTouch);
	}
}

void OnProjectileCreatedFrame(int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE) {

		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

		if (IsHumanSurvivor(client)) {

			float vPos[3], vAng[3], vVel[3];
			GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
			GetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vVel);

			bBlockForwarding = true;
			Call_StartForward(GlobalOnGLProjectileReplaced);
			Call_PushCell(entity);

			RemoveEntity(entity);

			bBlockProjectileSpawnHook = true;

			if (bIsGLRandomExists)
				DisableGLListener();

			int projectile = CreateEntityByName("grenade_launcher_projectile");

			bBlockProjectileSpawnHook = false;

			if (bIsGLRandomExists)
				EnableGLListener();

			if (projectile != INVALID_ENT_REFERENCE) {

				SetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity", client);
				DispatchSpawn(projectile);

				// Set origin and velocity
				float vDir[3];
				GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
				vPos[0] += vDir[0] * 10;
				vPos[1] += vDir[1] * 10;
				vPos[2] += vDir[2] * 10;

				ScaleVector(vVel, flVelocity);

				TeleportEntity(projectile, vPos, vAng, vVel);
				SetEntPropFloat(projectile, Prop_Data, "m_flGravity", flGravity);

				Call_PushCell(projectile);
				Call_PushCell(client);
				Call_Finish();

				iOwnerProjectile[client] = EntIndexToEntRef(projectile);
				timeCreatedProjectile[projectile] = GetEngineTime();

				SDKHook(projectile, SDKHook_Touch, OnProjectileTouch);

			} else {

				Call_PushCell(0);
				Call_PushCell(client);
				Call_Finish();
			}

			bBlockForwarding = false;
		}
	}
}


static const float VECTOR_VOID[3] = {0.0, 0.0, 0.0};

void OnProjectileTouch(int entity, int victim) {


	SDKUnhook(entity, SDKHook_Touch, OnProjectileTouch);

	if (!timeControlledProjectile[entity]) {

		DetonateProjectile(entity);

		return;
	}

	// sticky on Ground
	SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", VECTOR_VOID);
	SetEntityMoveType(entity, MOVETYPE_NONE);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 6);

	if (flTimeout > 0)
		CreateTimer(flTimeout, TimerDetonate, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

	if (victim) {

		/*
		 * Credits: l4d_pipebomb_shove.sp by Silvers
		 */

		int ZombieSpecie;

		if (IsEntity(victim)) {

			static char name_class[32];
			GetEntityNetClass(victim, name_class, sizeof(name_class));

			if (strcmp(name_class, "Infected") == 0)

				ZombieSpecie = 0;

			else if (strcmp(name_class, "Witch") == 0)
				
				ZombieSpecie = -1;

			else return;

		} else if (IsClient(victim)) {

			if (IsClientInGame(victim) && GetClientTeam(victim) == 3)

				ZombieSpecie = GetEntProp(victim, Prop_Send, "m_zombieClass");
		}

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", victim);

		switch (ZombieSpecie) {
			case -1 :
				SetVariantString("leye");
			case 1 :
				SetVariantString("smoker_mouth");
			case 3, 5, 6 :
				SetVariantString(GetRandomInt(0, 1) ? "rhand" : "lhand");
			default :
				SetVariantString("mouth");
		}

		AcceptEntityInput(entity, "SetParentAttachment", victim);
 	}
}

Action TimerDetonate(Handle timer, int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE)
		DetonateProjectile(entity);

	return Plugin_Stop;
}

int iButtonsLast [MAXPLAYERS + 1];

public void OnClientDisconnect_Post(int client) {
	iButtonsLast[client] = 0;
	timeHoldedAttack[client] = 0.0;
} 

#define PARTICLE_LIGHT		"weapon_pipebomb_blinking_light"

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	if (IsHumanSurvivor(client)) {


		if (iOwnerProjectile[client]) {

			int projectile = EntRefToEntIndex(iOwnerProjectile[client])

			if (projectile != INVALID_ENT_REFERENCE) {

				bool attack_released = !(buttons & IN_ATTACK) && iButtonsLast[client] & IN_ATTACK;

				float time = GetEngineTime();

				iButtonsLast[client] = buttons;

				if (buttons & IN_ATTACK && timeHoldedAttack[client] && time - timeHoldedAttack[client] > flHoldTime && !timeControlledProjectile[projectile]) {

					timeControlledProjectile[projectile] = true;

					AttachParticle(projectile, PARTICLE_LIGHT);
				}

				if (attack_released) {

					timeHoldedAttack[client] = 0.0

					if (timeControlledProjectile[projectile]) {
						
						RequestFrame(DetonateFrame, EntIndexToEntRef(projectile));

						iOwnerProjectile[client] = 0;
						timeCreatedProjectile[projectile] = 0.0;
					}

				}
			} else 
				iOwnerProjectile[client] = 0;
		}
	}
}

// Part From l4d_pipebomb_shove by Silvers
void AttachParticle(int target, const char[] name_particle) {

	int entity = CreateEntityByName("info_particle_system");

	DispatchKeyValue(entity, "effect_name", name_particle);

	DispatchSpawn(entity);
	ActivateEntity(entity);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);
	SetEntPropVector(entity, Prop_Send, "m_vecOrigin", VECTOR_VOID);
	AcceptEntityInput(entity, "Start");

	static char VariantString[32];
	Format(VariantString, sizeof(VariantString), "OnUser1 !self:Kill::%.2f:-1", flTimeout);
	SetVariantString(VariantString);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

void DetonateFrame(int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE)
		DetonateProjectile(entity);
}

void DetonateProjectile(int entity) {

	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	float vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);

	int targets [MAXPLAYERS], numClients;

	if (IsClient(owner) && GetClientTeam(owner) == 2) {

		numClients = GetClientsInRange(vPos, RangeType_Audibility, targets, MAXPLAYERS);

		if (numClients > 0)
			for (int i = 0; i < numClients; i++)
				if (GetClientTeam(targets[i]) == 2)
					SDKHook(targets[i], SDKHook_OnTakeDamage, OnTakeDamage);
	}

	L4D_DetonateProjectile(entity);

	/*
	 * Credits: l4d2_flare_gun.sp by Silvers
	 */

	entity = CreateEntityByName("env_explosion");
	DispatchKeyValue(entity, "iMagnitude", sDamage);
	DispatchKeyValue(entity, "spawnflags", "1916");
	DispatchKeyValue(entity, "iRadiusOverride", sRadius);
	DispatchSpawn(entity);
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", owner);
	AcceptEntityInput(entity, "Explode");

	if (numClients > 0)
		for (int i = 0; i < numClients; i++)
			if (GetClientTeam(targets[i]) == 2)
				SDKUnhook(targets[i], SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {


	if (victim == attacker)
		damage *= flFFScaleSelf;
	else
		damage *= flFFScale

	return Plugin_Changed;
}