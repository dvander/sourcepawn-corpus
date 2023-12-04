#define PLUGIN_VERSION	"1.0.2"
#define PLUGIN_NAME		"l4d_rock_explosion"
 
#pragma newdecls required
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#define PARTICLE_EXPLOSION	"gas_explosion_pump"

ConVar ConVarParticle;			bool bParticle;
ConVar ConVarExplosion;			int iExplosion;

native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_MolotovPrj(int client, const float vecPos[3], const float vecAng[3]);

native int L4D_DetonateProjectile(int entity);
forward void L4D_TankRock_OnDetonate(int tank, int rock);

#define isClient(%1) (1 <= %1 <= MaxClients && IsClientInGame(%1))
#define isInfected(%1) (isClient(%1) && GetClientTeam(%1) == 3)
#define isSurvivor(%1) (isClient(%1) && GetClientTeam(%1) == 2)

/**
 *  v1.0 just releases; 1-November-2022
 *  v1.0.1 less and optimize code; 1-November-2022
 *  v1.0.2 sounds like a fixes; 11-November-2022
 */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("L4D_PipeBombPrj");
	MarkNativeAsOptional("L4D_MolotovPrj");
	MarkNativeAsOptional("L4D_DetonateProjectile");
	return APLRes_Success;
}

public Plugin myinfo = {
	name = "[L4D2] Tank Rock Explosion",
	author = "NoroHime",
	description = "",
	version = PLUGIN_VERSION,
};

public void OnPluginStart() {

	CreateConVar						("rock_explosion", PLUGIN_VERSION,		"Version of 'Tank Rock Explosion'", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	ConVarParticle =		CreateConVar("rock_explosion_particle", "1",		"extra explosion particle 1=yes 0=no", FCVAR_NOTIFY);
	ConVarExplosion =		CreateConVar("rock_explosion_explosion", "1",		"method to make explosion 1=pipe bomb 2=molotov", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	ConVarParticle.AddChangeHook(OnConVarChanged);
	ConVarExplosion.AddChangeHook(OnConVarChanged);

	ApplyCvars();
}

public void OnMapStart() {
	PrecacheParticle(PARTICLE_EXPLOSION);
}

void ApplyCvars() {

	bParticle = ConVarParticle.BoolValue;
	iExplosion = ConVarExplosion.IntValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (strcmp(classname, "tank_rock") == 0) 
		SDKHook(entity, SDKHook_SpawnPost, OnRockSpawn);
}

void OnRockSpawn(int entity) {

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if (isInfected(owner) && GetEntityFlags(owner) & FL_ONFIRE)
		IgniteEntity(entity, 999.0);
}

public void L4D_TankRock_OnDetonate(int tank, int rock) {

	static float fTimeExplodedLast[MAXPLAYERS + 1];


	if (isInfected(tank) && GetEntityFlags(rock) & FL_ONFIRE) {

		float fTime = GetEngineTime();

		if (fTime - fTimeExplodedLast[tank] < 0.5)
			return;

		fTimeExplodedLast[tank] = fTime;

		float vPos[3];
		GetEntPropVector(rock, Prop_Send, "m_vecOrigin", vPos);

		// ServerCommand("sm_zedtime 0.5");

		switch (iExplosion) {
			case 1 : {

				int projectile = L4D_PipeBombPrj(tank, vPos, NULL_VECTOR);

				RequestFrame(DetonateProjectile, EntIndexToEntRef(projectile));
			}

			case 2 : {

				int projectile = L4D_MolotovPrj(tank, vPos, NULL_VECTOR);

				RequestFrame(DetonateProjectile, EntIndexToEntRef(projectile));
			}
		}

		if (bParticle) {
 
			int particle = CreateEntityByName("info_particle_system");
 
			if (particle != -1) {
 
				TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
 
				DispatchKeyValue(particle, "effect_name", PARTICLE_EXPLOSION);
				DispatchKeyValue(particle, "targetname", "particle");
 
				DispatchSpawn(particle);
				ActivateEntity(particle);
 
				AcceptEntityInput(particle, "start");
 
				SetVariantString("OnUser1 !self:Kill::3.0:-1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
			}
		}
	}
}

void DetonateProjectile(int projectile) {

	projectile = EntRefToEntIndex(projectile);

	if (projectile != INVALID_ENT_REFERENCE)
		L4D_DetonateProjectile(projectile);
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