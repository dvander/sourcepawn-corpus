#define PLUGIN_VERSION	"1.1"
#define PLUGIN_NAME		"l4d_limb_modifier"

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

/**
 *	v1.0 just releases; 26-April-2022
 *	v1.1 add feature: specifies damage type or ammo type to allow apply modifier; 5-May-2022
 *
 */

public Plugin myinfo = {
	name = "[L4D & L4D2] Limb-Based Damage Modifier",
	author = "NoroHime",
	description = "adjust damage modifier for per limb even tank",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

#define isEdictIndex(%1) (MaxClients < %1 <= 2048)
#define isClientIndex(%1) (1 <= %1 <= MaxClients)

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

enum {
	COMMON = 0,
	SMOKER,
	BOOMER,
	HUNTER,
	SPITTER,
	JOCKEY,
	CHARGER,
	WITCH,
	TANK,
	SURVIVOR
}

ConVar Modifier_head;				float modifier_head;
ConVar Modifier_chest;				float modifier_chest;
ConVar Modifier_stomach;			float modifier_stomach;
ConVar Modifier_arm_left;			float modifier_arm_left;
ConVar Modifier_arm_right;			float modifier_arm_right;
ConVar Modifier_leg_left;			float modifier_leg_left;
ConVar Modifier_leg_right;			float modifier_leg_right;
ConVar Modifier_targets;			int modifier_targets;
ConVar Modifier_allow_damage;		int modifier_allow_damage;
ConVar Modifier_allow_ammo;			int modifier_allow_ammo;

public void OnPluginStart() {

	CreateConVar						("limb_modifier_version", PLUGIN_VERSION,			"Version of 'Limb-Based Damage Modifier'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Modifier_head = 					CreateConVar("limb_modifier_head", "1.5",			"damage modifier for headshot", FCVAR_NOTIFY);
	Modifier_chest = 					CreateConVar("limb_modifier_chest", "1.33",			"damage modifier for chest", FCVAR_NOTIFY);
	Modifier_stomach = 					CreateConVar("limb_modifier_stomach", "1.2",		"damage modifier for stomach", FCVAR_NOTIFY);
	Modifier_arm_left = 				CreateConVar("limb_modifier_arm_left", "0.95",		"damage modifier for arm left", FCVAR_NOTIFY);
	Modifier_arm_right = 				CreateConVar("limb_modifier_arm_right", "0.95",		"damage modifier for arm right", FCVAR_NOTIFY);
	Modifier_leg_left = 				CreateConVar("limb_modifier_leg_left", "0.95",		"damage modifier for leg left", FCVAR_NOTIFY);
	Modifier_leg_right = 				CreateConVar("limb_modifier_leg_right", "0.95",		"damage modifier for leg right", FCVAR_NOTIFY);
	Modifier_targets = 					CreateConVar("limb_modifier_targets", "-1",			"apply the modifier for which targets\n1=commons 2=Smoker 4=Boomer 8=Hunter 16=Spitter 32=Jockey 32=Charger\n64=Witch 128=Tank 256=Survivor 511=All. Add numbers together.", FCVAR_NOTIFY);
	Modifier_allow_damage = 			CreateConVar("limb_modifier_allow_damage", "2",		"damage type to allow apply modifier\n2=bullet 4=slash 8=burn 64=blast 128=club 0=all. add numbers together yo want\nmore see sdkhooks.inc", FCVAR_NOTIFY);
	Modifier_allow_ammo = 				CreateConVar("limb_modifier_allow_ammo", "0",		"ammo type to allow apply modifier\n0=all. add numbers together yo want", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Modifier_head			.AddChangeHook(OnConVarChanged);
	Modifier_chest			.AddChangeHook(OnConVarChanged);
	Modifier_stomach		.AddChangeHook(OnConVarChanged);
	Modifier_arm_left		.AddChangeHook(OnConVarChanged);
	Modifier_arm_right		.AddChangeHook(OnConVarChanged);
	Modifier_leg_left		.AddChangeHook(OnConVarChanged);
	Modifier_leg_right		.AddChangeHook(OnConVarChanged);
	Modifier_targets		.AddChangeHook(OnConVarChanged);
	Modifier_allow_damage	.AddChangeHook(OnConVarChanged);
	Modifier_allow_ammo		.AddChangeHook(OnConVarChanged);
	
	ApplyCvars();
}

public void ApplyCvars() {
	
	modifier_head = Modifier_head.FloatValue;
	modifier_chest = Modifier_chest.FloatValue;
	modifier_stomach = Modifier_stomach.FloatValue;
	modifier_arm_left = Modifier_arm_left.FloatValue;
	modifier_arm_right = Modifier_arm_right.FloatValue;
	modifier_leg_left = Modifier_leg_left.FloatValue;
	modifier_leg_right = Modifier_leg_right.FloatValue;
	modifier_targets = Modifier_targets.IntValue;
	modifier_allow_damage = Modifier_allow_damage.IntValue;
	modifier_allow_ammo = Modifier_allow_ammo.IntValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

bool hookedInfected[2049];

public void OnEntityCreated(int entity, const char[] classname) {

	if (isEdictIndex(entity)) {
		
		if ( 
			( strcmp(classname, "infected") == 0 && modifier_targets & (1 << COMMON) ) ||
			( strcmp(classname, "witch") == 0 && modifier_targets & (1 << WITCH) )
		) {

			SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);

			hookedInfected[entity] = true;
		}
	}
}

public void OnEntityDestroyed(int entity) {

	if (isEdictIndex(entity) && hookedInfected[entity]) {
		
		SDKUnhook(entity, SDKHook_TraceAttack, OnTraceAttack);

		hookedInfected[entity] = false;
	}
}

public void OnClientPutInServer(int client) {

	if (isClientIndex(client))
		SDKHook(client, SDKHook_TraceAttack, OnTraceAttackClient);
}

public void OnClientDisconnect_Post(int client) {

	if (isClientIndex(client))
		SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttackClient);
}

public Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup) {


	if (modifier_allow_damage)
		if (damagetype == -1 || !(modifier_allow_damage & damagetype))
			return Plugin_Continue;

	if (modifier_allow_ammo)
		if (ammotype == -1 || !(modifier_allow_ammo & ammotype))
			return Plugin_Continue;

	switch (hitgroup) {
		case HEAD :			damage *= modifier_head;
		case CHEST :		damage *= modifier_chest;
		case STOMACH :		damage *= modifier_stomach;
		case ARM_LEFT :		damage *= modifier_arm_left;
		case ARM_RIGHT :	damage *= modifier_arm_right;
		case LEG_LEFT :		damage *= modifier_leg_left;
		case LEG_RIGHT :	damage *= modifier_leg_right;
		default : return Plugin_Continue;
	}

	return Plugin_Changed;
}

public Action OnTraceAttackClient(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup) {

	if (modifier_allow_damage)
		if (damagetype == -1 || !(modifier_allow_damage & damagetype))
			return Plugin_Continue;

	if (modifier_allow_ammo)
		if (ammotype == -1 || !(modifier_allow_ammo & ammotype))
			return Plugin_Continue;

	int team = GetClientTeam(victim);
	bool passed = false;

	switch (team) {

		case 2: {
			if (modifier_targets & (1 << SURVIVOR))
				passed = true;
		}

		case 3: {

			int class = GetEntProp(victim, Prop_Send, "m_zombieClass");

			if (modifier_targets & (1 << class))
				passed = true;
		}
	}

	if (passed) {

		switch (hitgroup) {
			case HEAD :			damage *= modifier_head;
			case CHEST :		damage *= modifier_chest;
			case STOMACH :		damage *= modifier_stomach;
			case ARM_LEFT :		damage *= modifier_arm_left;
			case ARM_RIGHT :	damage *= modifier_arm_right;
			case LEG_LEFT :		damage *= modifier_leg_left;
			case LEG_RIGHT :	damage *= modifier_leg_right;
			default : return Plugin_Continue;
		}

		return Plugin_Changed;
	} else 
		return Plugin_Continue;
}
