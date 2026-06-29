#define PLUGIN_VERSION		"1.1"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"grenadelauncher_random"
#define PLUGIN_NAME_FULL	"[L4D2] Grenade Launcher Random Projectile"
#define PLUGIN_DESCRIPTION	"random the grenadelauncher make surprise."
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://steamcommunity.com/id/NoroHime/"

/**
 *  v1.0 just releases; 4-November-2022
 *  v1.0.1 fix issue 'some grenade doesnt have owner'; 4-November-2022(2nd time)
 *  v1.0.2 doubled the double check, for safe; 4-November-2022(3rd time)
 *  v1.1 for dev, 
 *  	add forward event 'void OnGLProjectileReplaced(int before, int after, int client)'
 *  	add natives 'void DisableGLListener()', 'void EnableGLListener()'; 30-November-2022
 */
 
#pragma newdecls required

#include <sdkhooks>

forward void OnGLProjectileReplaced(int before, int after, int client);
GlobalForward GlobalOnGLProjectileReplaced;

bool bBlockForwarding = false;

#define IsEntity(%1) (2048 >= %1 > MaxClients)
#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))

native int L4D_DetonateProjectile(int entity);
native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_MolotovPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D2_SpitterPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D2_VomitJarPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_TankRockPrj(int client, const float vecPos[3], const float vecAng[3]);

native void DisableGLListener();
native void EnableGLListener();

bool bDisabledListener = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	
	MarkNativeAsOptional("L4D_DetonateProjectile");
	MarkNativeAsOptional("L4D_MolotovPrj");
	MarkNativeAsOptional("L4D_PipeBombPrj");
	MarkNativeAsOptional("L4D2_SpitterPrj");
	MarkNativeAsOptional("L4D2_VomitJarPrj");
	MarkNativeAsOptional("L4D_TankRockPrj");
	RegPluginLibrary(PLUGIN_PREFIX ... PLUGIN_NAME);
	CreateNative("DisableGLListener", ExternalDisableListener);
	CreateNative("EnableGLListener", ExternalEnableListener);

	return APLRes_Success;
}

public int ExternalDisableListener(Handle plugin, int numParams) {

	bDisabledListener = true;

	return 0;
}

public int ExternalEnableListener(Handle plugin, int numParams) {

	bDisabledListener = false;

	return 0;
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

ConVar cType;			int iType;
ConVar cFly;			int iFly;
ConVar cRandom;			int iRandom;
ConVar cTimeout;		float fTimeout;
ConVar cChance;			float fChance;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cType =			CreateConVar(PLUGIN_NAME ... "_type", "0",			"plugin default type if trigger\n0=vanilla 1=molotov 2=pipe bomb 4=spitter 8=vomit jar 16=tank rock", FCVAR_NOTIFY);
	cFly =			CreateConVar(PLUGIN_NAME ... "_fly", "131076",		"make projectile anti-gravity -1=always 0=never other=specifis key pressed 131072=shift 4=ctrl", FCVAR_NOTIFY);
	cRandom =		CreateConVar(PLUGIN_NAME ... "_rand", "-1",			"if trigger by *_chance, which projectiles random launch by Grenade Launcher\n1=molotov 2=pipe bomb 4=spitter 8=vomit jar 16=tank rock -1=All\nadd numbers together you want.", FCVAR_NOTIFY);
	cTimeout =		CreateConVar(PLUGIN_NAME ... "_timeout", "6.0",		"time(seconds) of timeout to detonate the grenade 0=dont", FCVAR_NOTIFY);
	cChance =		CreateConVar(PLUGIN_NAME ... "_chance", "0.5",		"chance to trigger random Projectiles, if not set, use *_type", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cType.AddChangeHook(OnConVarChanged);
	cFly.AddChangeHook(OnConVarChanged);
	cRandom.AddChangeHook(OnConVarChanged);
	cTimeout.AddChangeHook(OnConVarChanged);
	cChance.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	GlobalOnGLProjectileReplaced = new GlobalForward("OnGLProjectileReplaced", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

}


void ApplyCvars() {

	iType = cType.IntValue;
	iFly = cFly.IntValue;
	iRandom = cRandom.IntValue;
	fTimeout = cTimeout.FloatValue;
	fChance = cChance.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (!bDisabledListener && strcmp(classname, "grenade_launcher_projectile") == 0)
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileCreated);
}

void OnProjectileCreated(int entity) {

	if (IsValidEntity(entity)) {

		if (1 > fChance > 0) {
			if (iRandom && fChance > GetURandomFloat()) //if chance to trigger, chance to variant
				RandomProjectileType();
			else
				iType = cType.IntValue; //rollback *_type
		} else if (fChance >= 1)
			RandomProjectileType();

		switch (iType) {
			case MOLOTOV, PIPE_BOMB, SPITTER, VOMIT_JAR:
				RequestFrame(ReplaceProjectileVVel, EntIndexToEntRef(entity));
			case TANK_ROCK, 0:
				ReplaceProjectile(entity, "m_angRotation");
		}
	}
}

public void OnGLProjectileReplaced(int before, int after, int client) {

	if (bBlockForwarding)
		return;

	if (IsEntity(after))
		ReplaceProjectileVVel(EntIndexToEntRef(after));
}

void ReplaceProjectileVVel(int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE)
		ReplaceProjectile(entity, "m_vecVelocity");
}

void ReplaceProjectile(int entity, const char vAngString[32]) {

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if ( (1 <= owner <= MaxClients) && IsClientInGame(owner) ) {

		if (!iType) {
			SetProjectileMoveType(owner, entity);
			return;
		}
		
		float vPos[3], vVel[3];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(entity, Prop_Send, vAngString, vVel)

		RemoveEntity(entity);

		bBlockForwarding = true;
		Call_StartForward(GlobalOnGLProjectileReplaced);
		Call_PushCell(entity);
		

		switch (iType) {
			case MOLOTOV	: entity = L4D_MolotovPrj(owner, vPos, vVel);
			case PIPE_BOMB	: entity = L4D_PipeBombPrj(owner, vPos, vVel);
			case SPITTER	: entity = L4D2_SpitterPrj(owner, vPos, vVel);
			case VOMIT_JAR	: entity = L4D2_VomitJarPrj(owner, vPos, vVel);
			case TANK_ROCK	: entity = L4D_TankRockPrj(owner, vPos, vVel);
			default			: entity = 0;
		}

		Call_PushCell(entity);
		Call_PushCell(owner);
		Call_Finish();
		bBlockForwarding = false;

		SetProjectileMoveType(owner, entity);

		if (fTimeout > 0)
			CreateTimer(fTimeout, TimerDetonate, EntIndexToEntRef(entity));
	}

}

void SetProjectileMoveType(int owner, int entity) {
	if (iFly == -1)
		SetEntityMoveType(entity, MOVETYPE_FLY);
	else if (iFly > 0 && GetClientButtons(owner) & iFly)
		SetEntityMoveType(entity, MOVETYPE_FLY);
}

Action TimerDetonate(Handle timer, int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE)
		L4D_DetonateProjectile(entity);

	return Plugin_Stop;
}


void RandomProjectileType() {

	ArrayList types = new ArrayList();

	if (iRandom) {

		if (iRandom & MOLOTOV)
			types.Push(MOLOTOV);

		if (iRandom & PIPE_BOMB)
			types.Push(PIPE_BOMB);

		if (iRandom & SPITTER)
			types.Push(SPITTER);

		if (iRandom & VOMIT_JAR)
			types.Push(VOMIT_JAR);

		if (iRandom & TANK_ROCK)
			types.Push(TANK_ROCK);

		iType = types.Get(RoundToFloor(GetURandomFloat() * types.Length));
	}

	delete types;
}