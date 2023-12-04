#define PLUGIN_VERSION	"1.0"
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

/**
 *  v1.0 just releases; 1-December-2022
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

	HookEvent("ability_use", OnAbilityUse);

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

int tank_throwing;

public void OnEntityDestroyed(int entity) {

	static char classname[32];

	if ( GetEntityClassname(entity, classname, sizeof(classname)) && strcmp(classname, "tank_rock") == 0 && GetEntityFlags(entity) & FL_ONFIRE) {

		int tank = GetRockOwner(entity);
		float vPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

		ServerCommand("sm_zedtime 0.5");

		switch (iExplosion) {
			case 1 : {

				int projectile = L4D_PipeBombPrj(tank, vPos, NULL_VECTOR);

				if (projectile != -1)
					L4D_DetonateProjectile(projectile);
			}

			case 2 : {

				int projectile = L4D_MolotovPrj(tank, vPos, NULL_VECTOR);

				if (projectile != -1)
					L4D_DetonateProjectile(projectile);
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

public void OnEntityCreated(int entity, const char[] classname) {

	static char name[32];

	GetEntityNetClass(entity, name, sizeof(name));

	if (strcmp(classname, "tank_rock") == 0 && GetEntProp(entity, Prop_Data, "m_iTeamNum") >= 0) {

		if (tank_throwing && GetEntityFlags(tank_throwing) & FL_ONFIRE) {
			SetRockOwner(entity, tank_throwing);
			IgniteEntity(entity, 999.0);
			tank_throwing = 0;
		}
	}
}

void OnAbilityUse(Event event, const char[] name, bool dontBroadcast) {

	static char name_ability[32];

	event.GetString("ability", name_ability, sizeof(name_ability));

	if (strcmp(name_ability, "ability_throw") == 0) {

		tank_throwing = GetClientOfUserId(event.GetInt("userid"));
	}
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

void SetRockOwner(int rock, int tank) {
	SetEntPropEnt(rock, Prop_Data, "m_hThrower", tank);
	SetEntPropEnt(rock, Prop_Send, "m_hThrower", tank);
	SetEntPropEnt(rock, Prop_Data, "m_hOwnerEntity", tank);
	SetEntPropEnt(rock, Prop_Send, "m_hOwnerEntity", tank);
}

int GetRockOwner(int rock) {
	return GetEntPropEnt(rock, Prop_Data, "m_hThrower");
}