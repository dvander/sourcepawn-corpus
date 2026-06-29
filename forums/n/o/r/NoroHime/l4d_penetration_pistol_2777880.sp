#define PLUGIN_VERSION	"1.0"
#define PLUGIN_NAME		"l4d_penetraction_pistol"

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

/**
 *	v1.0 just releases; 25-March-2022
 *
 */

public Plugin myinfo = {
	name = "[L4D & L4D2] Limb-Based Penetration Pistol",
	author = "NoroHime",
	description = "i decided make pistol great again",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}


#define isNetworkedEntity(%1) (MaxClients < %1 <= 2048)

enum {
	GENERIC = 0,
	HEAD,
	CHEST,
	STOMACH,
	ARM_LEFT,
	ARM_RIGHT,
	LEG_LEFT,
	LEG_RIGHT
}

ConVar Penetration_limb_full;	int penetration_limb_full;
ConVar Penetration_limb_perc;	int penetration_limb_perc;
ConVar Penetration_limb_lucky;	int penetration_limb_lucky;
ConVar Penetration_rate_perc;	float penetration_rate_perc;
ConVar Penetration_rate_lukcy;	int penetration_rate_lukcy;

public void OnPluginStart() {

	CreateConVar						("penetraction_pistol_version", PLUGIN_VERSION,			"Version of 'Limb-Based Penetration Pistol'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Penetration_limb_full = 			CreateConVar("penetraction_pistol_limb_full", "2",		"hit which limbs cause zombie die directly\n1=head 2=chest 4=stomach 8=arm left 16=arm right 32=leg left 64=leg right 127=All", FCVAR_NOTIFY);
	Penetration_limb_perc = 			CreateConVar("penetraction_pistol_limb_perc", "18",		"hit which limbs deal damage proportional to at least max health\n1=head 2=chest 4=stomach 8=arm left 16=arm right 32=leg left 64=leg right 127=All", FCVAR_NOTIFY);
	Penetration_limb_lucky = 			CreateConVar("penetraction_pistol_limb_lucky", "100",	"hit which limbs chance to cause zombie die directly\n1=head 2=chest 4=stomach 8=arm left 16=arm right 32=leg left 64=leg right 127=All", FCVAR_NOTIFY);
	Penetration_rate_perc = 			CreateConVar("penetraction_pistol_rate_perc", "0.3",	"hit 'limb_perc' selected limbs deal at least damage of max health", FCVAR_NOTIFY);
	Penetration_rate_lukcy = 			CreateConVar("penetraction_pistol_rate_lukcy", "3",		"hit 'limb_lucky' selected limbs has 1 in number chance cause zombie die directly, lower value easier to die, 1=certainly 2=half chance", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Penetration_limb_full		.AddChangeHook(OnConVarChanged);
	Penetration_limb_perc		.AddChangeHook(OnConVarChanged);
	Penetration_limb_lucky		.AddChangeHook(OnConVarChanged);
	Penetration_rate_perc		.AddChangeHook(OnConVarChanged);
	Penetration_rate_lukcy		.AddChangeHook(OnConVarChanged);
	
	ApplyCvars();
}

public void ApplyCvars() {
	
	penetration_limb_full = Penetration_limb_full.IntValue;
	penetration_limb_perc = Penetration_limb_perc.IntValue;
	penetration_limb_lucky = Penetration_limb_lucky.IntValue;
	penetration_rate_perc = Penetration_rate_perc.FloatValue;
	penetration_rate_lukcy = Penetration_rate_lukcy.IntValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

bool hookedInfected[2049];

public void OnEntityCreated(int entity, const char[] classname) {

	if (isNetworkedEntity(entity) && strcmp(classname, "infected") == 0) {

		SDKHook(entity, SDKHook_TraceAttackPost, OnTraceAttackPost);
		SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);

		hookedInfected[entity] = true;
	}
}

public void OnEntityDestroyed(int entity) {

	if (isNetworkedEntity(entity) && hookedInfected[entity]) {
		
		SDKUnhook(entity, SDKHook_TraceAttack, OnTraceAttackPost);
		SDKUnhook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);

		hookedInfected[entity] = false;
	}
}

int lastHitted;

public void OnTraceAttackPost(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup) {
	lastHitted = hitgroup;
}

public Action OnTakeDamageAlive(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {

	static char name_weapon[32];

	if (isNetworkedEntity(weapon) && GetEntityNetClass(weapon, name_weapon, sizeof(name_weapon)) && strcmp(name_weapon, "CPistol") == 0) {
		
		if (HasEntProp(victim, Prop_Data, "m_iMaxHealth")) {

			int health_max = GetEntProp(victim, Prop_Data, "m_iMaxHealth");

			if (penetration_limb_full & (1 << lastHitted - 1)) {

				damage = float(health_max) + 1;

				return Plugin_Changed;
			}

			if (penetration_limb_lucky & (1 << lastHitted - 1) && GetRandomInt(1, penetration_rate_lukcy) == 1) {

				damage = float(health_max) + 1;

				return Plugin_Changed;
			}

			if (penetration_limb_perc & (1 << lastHitted - 1) && damage < (penetration_rate_perc * health_max)) {

				damage = health_max * penetration_rate_perc + 1;

				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}