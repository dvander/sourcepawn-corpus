#define PLUGIN_VERSION		"1.1.1"
#define PLUGIN_NAME			"charger_explosion"
#define PLUGIN_NAME_FULL	"[L4D2] Charger Impact Explosion"
#define PLUGIN_DESCRIPTION	"make explosion when Charger charging impacts something"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://steamcommunity.com/id/NoroHime/"

/**
 *  v1.0 just releases; 30-October-2022
 *  v1.0.1 fix some code entity operation issue, thanks Silvers teaching; 30-October-2022 (2nd time)
 *  v1.0.2 maybe fix some entity operation issue; 31-October-2022
 *  v1.1 new ConVar *_explosion to control method to make explosion:
 *  	 	propane / pipe bomb / molotov, if encounter crashes during use propane then use another to instead.(requires left4dhooks),
 *  	 new ConVar *_cooldown to control cooldown of explosion ability trigger,
 *  	 fix some entity operation, a lot changes from Silvers, thanks again; 31-October-2022
 *  v1.1.1 fix charger death under charging also trigger explosion; 11-November-2022
 */

#pragma newdecls required
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#define MODEL_EXPLOSIVE		"models/props_junk/propanecanister001a.mdl"
#define PARTICLE_EXPLOSION	"gas_explosion_pump"

 
native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_MolotovPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_DetonateProjectile(int entity);
native int L4D2_GrenadeLauncherPrj(int client, const float vecPos[3], const float vecAng[3]);


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	
	MarkNativeAsOptional("L4D_PipeBombPrj");
	MarkNativeAsOptional("L4D_MolotovPrj");
	MarkNativeAsOptional("L4D_DetonateProjectile");

	return APLRes_Success;
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};
 
ConVar ConVarParticle;			bool bParticle;
ConVar ConVarExplosion;			int iExplosion;
ConVar ConVarCooldown;			float fCooldown;
ConVar ConVarChargeInterval;	float fChargeInterval;

public void OnPluginStart() {

	CreateConVar						(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ConVarParticle =		CreateConVar(PLUGIN_NAME ... "_particle", "1",		"extra explosion particle 1=yes 0=no", FCVAR_NOTIFY);
	ConVarExplosion =		CreateConVar(PLUGIN_NAME ... "_explosion", "1",		"method to make explosion 1=propane 2=pipe bomb 3=molotov 4=GrenadeLauncher (2,3,4 requires left4dhooks)", FCVAR_NOTIFY);
	ConVarCooldown =		CreateConVar(PLUGIN_NAME ... "_cooldown", "-1",		"cooldown(seconds) to make explosion ability again (per charger) 0=no cd -1=same as z_charge_interval", FCVAR_NOTIFY);
	ConVarChargeInterval =	FindConVar	("z_charge_interval");

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	ConVarParticle.AddChangeHook(OnConVarChanged);
	ConVarExplosion.AddChangeHook(OnConVarChanged);
	ConVarCooldown.AddChangeHook(OnConVarChanged);
	ConVarChargeInterval.AddChangeHook(OnConVarChanged);

	HookEvent("charger_charge_end", OnChargeEnd);

	ApplyCvars();
}


public void OnMapStart() {
	PrecacheModel(MODEL_EXPLOSIVE);
	PrecacheParticle(PARTICLE_EXPLOSION);
}

void ApplyCvars() {

	bParticle = ConVarParticle.BoolValue;
	iExplosion = ConVarExplosion.IntValue;

	fChargeInterval = ConVarChargeInterval.FloatValue;

	if (ConVarCooldown.FloatValue == -1)
		fCooldown = fChargeInterval;
	else
		fCooldown = ConVarCooldown.FloatValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

void OnChargeEnd(Event event, const char[] name, bool dontBroadcast) {

	RequestFrame(OnChargeEndNextFrame, event.GetInt("userid"));
}

void OnChargeEndNextFrame(int charger) {

	charger = GetClientOfUserId(charger);

	static float fTimeExplodedLast[MAXPLAYERS + 1];

	if (charger && IsClientInGame(charger) && IsPlayerAlive(charger)) {

		float fTime = GetEngineTime();

		if (fTime - fTimeExplodedLast[charger] < fCooldown)
			return;

		fTimeExplodedLast[charger] = fTime;

		float vPos[3];
		GetEntPropVector(charger, Prop_Send, "m_vecOrigin", vPos);
		vPos[2] += 10.0;

		switch (iExplosion) {
			case 1 : {
				
				int entity = CreateEntityByName("prop_physics");
				if( entity != -1 ) {
					DispatchKeyValue(entity, "model", MODEL_EXPLOSIVE);
		 
					// Hide from view (multiple hides still show the gascan/propane tank for a split second sometimes, but works better than only using 1 of them)
					SDKHook(entity, SDKHook_SetTransmit, OnTransmitExplosive);
		 
					// Hide from view
					int flags = GetEntityFlags(entity);
					SetEntityFlags(entity, flags|FL_EDICT_DONTSEND);
		 
					// Make invisible
					SetEntityRenderMode(entity, RENDER_TRANSALPHAADD);
					SetEntityRenderColor(entity, 0, 0, 0, 0);
		 
					// Prevent collision and movement
					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1, 1);
					SetEntityMoveType(entity, MOVETYPE_NONE);
		 
					// Teleport
					TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		 
					// Spawn
					DispatchSpawn(entity);
		 
					// Set attacker
					SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", charger);
					SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());

					// Explode
					AcceptEntityInput(entity, "Break", charger);
				}
			}

			case 2 : {

				int projectile = L4D_PipeBombPrj(charger, vPos, NULL_VECTOR);

				if (projectile != -1)
					L4D_DetonateProjectile(projectile);
			}

			case 3 : {

				int projectile = L4D_MolotovPrj(charger, vPos, NULL_VECTOR);

				if (projectile != -1)
					L4D_DetonateProjectile(projectile);
			}

			case 4 : {

				int projectile = L4D2_GrenadeLauncherPrj(charger, vPos, NULL_VECTOR);

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

Action OnTransmitExplosive(int entity, int client)
{
	return Plugin_Handled;
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