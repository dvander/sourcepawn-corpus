#define PLUGIN_VERSION		"1.6"
#define PLUGIN_NAME			"leaker"
#define PLUGIN_NAME_FULL	"[L4D2] Leaker Boomer Enabler"
#define PLUGIN_DESCRIPTION	"Variant Boomer \"Leaker\" Enabler"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2768061"
/*
	v1.0 just released
	v1.1 fix leaker cannot be kill
	v1.1.1 create fake kill event and add switch leaker can be damage
	v1.1.2 leaker killing bug fix, now shold less performance usage; 19-1-22
	v1.2 code clean thanks "Dragokas", add feature: 
		1. normalize the regular boomer to male model 
		2. normal boomer chance to l4d1 model 
		3. option to set leaker movement speed multiplier; 21-1-22
	v1.2.1 Leaker spawn reset after plugin unload, suggestion from "HarryPotter"; 21-1-22
	v1.3 option to specify bot chance, thanks "HarryPotter", now "Left 4 DHooks Direct" is required; 25-1-22
	v1.3.1 improve better bot chance, thanks "HarryPotter"; 25-1-22
	v1.3.2
		1. fix issue 'some very rare cases when keep taking damage to dead leaker cause loop death',
		2. fix issue 'wrong cvar bounds cause bot chance cant set -1',
		3. fake event now support death position,
		4. optional 'restrict only survivor can take damage to leaker'; 16-2-22
	v1.3.3 now plugin can compile online, but bot chance specify feature still require 'Left 4 DHooks Direct'; 16-2-22
	v1.3.4 remove cvar listener to fixes bot chance not work; 24-2-22
	v1.4 optional set leaker causes damage scale, optional fire the fake event let game known killed the boomer; 8-October-2022
	v1.5 optional stumble or gets vomitted the survivors when leaker exploded, reference some code from '[L4D2] Stumble - Grenade Launcher'; 22-October-2022
	v1.6 
		1. new ConVar *_fire to control lifetime of fire dropped by leaker,
		2. new ConVar *_explosion to control extra explosion for leaker deathes,
		3. fix duplicate kill message thanks to Silvers; 11-November-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define CLASS_BOOMER		2

#define MODEL_BOOMETTE		"models/infected/boomette.mdl"
#define MODEL_BOOMER		"models/infected/boomer.mdl"
#define MODEL_BOOMER_L4D1	"models/infected/boomer_l4d1.mdl"
#define MODEL_LIMBS			"models/infected/limbs/exploded_boomette.mdl"

#define isClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define isSurvivor(%1) (isClient(%1) && GetClientTeam(%1) == 2)
#define isBoomer(%1) (isClient(%1) && GetClientTeam(%1) == 3 && GetEntProp(%1, Prop_Send, "m_zombieClass") == CLASS_BOOMER)
#define isLeaker(%1) (isBoomer(%1) && GetEntProp(%1, Prop_Send, "m_nVariantType") == 1)


bool block_deton = false;
bool block_event = false;

native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_MolotovPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_DetonateProjectile(int entity);
native int L4D2_GrenadeLauncherPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D2_SpitterPrj(int client, const float vecPos[3], const float vecAng[3]);

forward Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3]);
native void L4D_CTerrorPlayer_OnVomitedUpon(int client, int attacker);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	
	MarkNativeAsOptional("L4D_PipeBombPrj");
	MarkNativeAsOptional("L4D_MolotovPrj");
	MarkNativeAsOptional("L4D_DetonateProjectile");
	MarkNativeAsOptional("L4D2_GrenadeLauncherPrj");
	MarkNativeAsOptional("L4D_CTerrorPlayer_OnVomitedUpon");
	MarkNativeAsOptional("L4D2_SpitterPrj");

	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	// Require Left4DHooks
	if( LibraryExists("left4dhooks") == false ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}
}

ConVar boomer_leaker_chance;

ConVar Leaker_health;					int leaker_health;
ConVar Leaker_chance;					int leaker_chance;
ConVar Leaker_chance_bot;				int leaker_chance_bot;
ConVar Leaker_boomette;					bool leaker_boomette;
ConVar Leaker_can_damage;				bool leaker_can_damage;
ConVar Leaker_normalize_model;			bool leaker_normalize_model;
ConVar Leaker_normalize_l4d1_chance;	float leaker_normalize_l4d1_chance;
ConVar Leaker_speed;					float leaker_speed;
ConVar Leaker_restrict_survivor;		bool leaker_restrict_survivor;
ConVar Leaker_damage_scale;				float leaker_damage_scale;
ConVar Leaker_events;					bool leaker_events;
ConVar Leaker_stumble;					float leaker_stumble;
ConVar Leaker_stumble_vomit;			bool leaker_stumble_vomit;
ConVar Leaker_fire; 					float leaker_fire;
ConVar Leaker_explosion; 				int leaker_explosion;

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};
public void OnPluginStart() {
	CreateConVar								(PLUGIN_NAME ... "_version", PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Leaker_health = 				CreateConVar(PLUGIN_NAME ... "_health", "600",					"leaker boomer health, charger is 600, 0:disable feature", FCVAR_NOTIFY);
	Leaker_chance = 				CreateConVar(PLUGIN_NAME ... "_chance", "17",					"leaker boomer spawn chance, 17 is 17% mean spawn 1 in 6, cast to cvar 'boomer_leaker_chance'", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	Leaker_chance_bot = 			CreateConVar(PLUGIN_NAME ... "_chance_bot", "-1",				"required 'Left 4 DHooks Direct': specify bot chance for boomer leaker, -1: not specify, 100: bot boomer certainly as leaker", FCVAR_NOTIFY, true, -1.0, true, 100.0);
	Leaker_boomette = 				CreateConVar(PLUGIN_NAME ... "_boomette", "1",					"is leaker boomer spawn as boomette model", FCVAR_NOTIFY);
	Leaker_can_damage = 			CreateConVar(PLUGIN_NAME ... "_can_damage", "1",				"game default leaker cannot be damage, set to fix it", FCVAR_NOTIFY);
	Leaker_normalize_model = 		CreateConVar(PLUGIN_NAME ... "_normalize_model", "1",			"if boomer is not leaker, normalize it to male boomer model", FCVAR_NOTIFY);
	Leaker_normalize_l4d1_chance = 	CreateConVar(PLUGIN_NAME ... "_normalize_l4d1_chance", "50",	"if normalize model, chance to set l4d1 boomer, 0: disable l4d1 model", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	Leaker_speed = 					CreateConVar(PLUGIN_NAME ... "_speed", "-1",					"leaker movement speed multiplier, -1: game default, 0: cant move, 2: double speed, etc..", FCVAR_NOTIFY);
	boomer_leaker_chance = 			FindConVar	("boomer_leaker_chance");
	Leaker_restrict_survivor = 		CreateConVar(PLUGIN_NAME ... "_restrict_survivor", "1",			"restrict Leaker can survivor take damage only", FCVAR_NOTIFY);
	Leaker_damage_scale = 			CreateConVar(PLUGIN_NAME ... "_damage_scale", "-1",				"damage of leaker causes scale 0.5: half -1: default", FCVAR_NOTIFY);
	Leaker_events = 				CreateConVar(PLUGIN_NAME ... "_events", "1",					"fire the fake event let game known you killed a boomer 1:yes 0:no", FCVAR_NOTIFY);
	Leaker_stumble = 				CreateConVar(PLUGIN_NAME ... "_stumble", "200",					"range of stumbles when leaker exploded", FCVAR_NOTIFY);
	Leaker_stumble_vomit = 			CreateConVar(PLUGIN_NAME ... "_stumble_vomit", "0",				"when be stumbled then gets vomitted", FCVAR_NOTIFY);
	Leaker_fire = 					CreateConVar(PLUGIN_NAME ... "_fire", "15.0",					"lifetime of fire dropped by leaker, must less than inferno_flame_lifetime 0=disable fire", FCVAR_NOTIFY);
	Leaker_explosion = 				CreateConVar(PLUGIN_NAME ... "_explosion", "3",					"extra explosion effects when leaker exploded\n0=none 1=pipe bomb 2=molotov 3=GL grenade 4=spitter acid. requires left4dhooks", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_leaker_boomer");

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);

	Leaker_health.AddChangeHook(OnConVarChanged);
	Leaker_chance.AddChangeHook(OnConVarChanged);
	Leaker_boomette.AddChangeHook(OnConVarChanged);
	Leaker_can_damage.AddChangeHook(OnConVarChanged);
	Leaker_normalize_model.AddChangeHook(OnConVarChanged);
	Leaker_normalize_l4d1_chance.AddChangeHook(OnConVarChanged);
	Leaker_speed.AddChangeHook(OnConVarChanged);
	Leaker_restrict_survivor.AddChangeHook(OnConVarChanged);
	Leaker_damage_scale.AddChangeHook(OnConVarChanged);
	Leaker_events.AddChangeHook(OnConVarChanged);
	Leaker_stumble.AddChangeHook(OnConVarChanged);
	Leaker_stumble_vomit.AddChangeHook(OnConVarChanged);
	Leaker_fire.AddChangeHook(OnConVarChanged);
	Leaker_explosion.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	// Late load
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) )
			OnClientPutInServer(i);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

void ApplyCvars() {
	leaker_health = Leaker_health.IntValue;
	leaker_chance = Leaker_chance.IntValue;
	leaker_chance_bot = Leaker_chance_bot.IntValue;
	leaker_boomette = Leaker_boomette.BoolValue;
	leaker_can_damage = Leaker_can_damage.BoolValue;
	leaker_normalize_model = Leaker_normalize_model.BoolValue;
	leaker_normalize_l4d1_chance = Leaker_normalize_l4d1_chance.FloatValue;
	leaker_speed = Leaker_speed.FloatValue;
	leaker_restrict_survivor = Leaker_restrict_survivor.BoolValue;

	boomer_leaker_chance.SetInt(leaker_chance);
	leaker_damage_scale = Leaker_damage_scale.FloatValue;
	leaker_events = Leaker_events.BoolValue;
	leaker_stumble = Leaker_stumble.FloatValue;
	leaker_stumble_vomit = Leaker_stumble_vomit.BoolValue;
	leaker_fire = Leaker_fire.FloatValue;
	leaker_explosion = Leaker_explosion.IntValue;
}

public void OnMapStart() {
	PrecacheModel(MODEL_BOOMETTE);
	PrecacheModel(MODEL_LIMBS);
	PrecacheModel(MODEL_BOOMER);
	PrecacheModel(MODEL_BOOMER_L4D1);
}

public void OnPluginEnd() {
	ResetConVar(boomer_leaker_chance);
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3]) {

	if (leaker_chance_bot == -1)
		return Plugin_Continue;

	if (zombieClass == CLASS_BOOMER) {
		int luck = GetRandomInt(1, 100);

		if(leaker_chance_bot >= luck) {
			boomer_leaker_chance.SetInt(100);
			RequestFrame(PostBackChance);
		}
	}

	return Plugin_Continue;
}

void PostBackChance() {
	boomer_leaker_chance.SetInt(leaker_chance); //back chance to global
}

void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client && isBoomer(client)) {

		bool isLeaker = GetEntProp(client, Prop_Send, "m_nVariantType") == 1;

		if (isLeaker) {

			if (leaker_boomette)
				SetEntityModel(client, MODEL_BOOMETTE);

			if (leaker_health)
				SetEntityHealth(client, leaker_health);

			if (leaker_speed != -1)
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", leaker_speed);

			if (leaker_can_damage)
				SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageLeaker);

		} else {

			if (leaker_normalize_model) {

				float luck = GetRandomFloat(1.0, leaker_normalize_l4d1_chance);

				if (leaker_normalize_l4d1_chance && luck > leaker_normalize_l4d1_chance)
					SetEntityModel(client, MODEL_BOOMER_L4D1);
				else
					SetEntityModel(client, MODEL_BOOMER);
			}
		}
	}
}

Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (block_event) {
		dontBroadcast = true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action OnTakeDamageLeaker(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (leaker_can_damage && (!leaker_restrict_survivor || isSurvivor(attacker)) && isLeaker(victim)) {

		int health = GetClientHealth(victim) - RoundToFloor(damage);

		if (health > 0)

			SetEntityHealth(victim, health);

		else {

			if (leaker_events && isClient(attacker)) {

				Event event = CreateEvent("player_death");
				
				if (event) {

					event.SetInt("userid", GetClientUserId(victim));
					event.SetInt("attacker", GetClientUserId(attacker));

					float pos[3];
					GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
					event.SetFloat("victim_x", pos[0]);
					event.SetFloat("victim_y", pos[1]);
					event.SetFloat("victim_z", pos[2]);

					if (IsValidEntity(weapon)) {
						char weapon_name[32];
						GetEntityClassname(weapon, weapon_name, sizeof(weapon_name));
						ReplaceString(weapon_name, sizeof(weapon_name), "weapon_", "");
						event.SetString("weapon", weapon_name);
					}

					event.Fire();
				}
			}

			block_event = true;
			ForcePlayerSuicide(victim);
			block_event = false;

			SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamageLeaker);
		}
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageVictim);
}

Action OnTakeDamageVictim(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {

	if ( leaker_damage_scale >= 0 && isLeaker(attacker) ) {

		damage *= leaker_damage_scale;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (!block_deton && strcmp(classname, "inferno") == 0)
		SDKHook(entity, SDKHook_SpawnPost, OnInfernoSpawnPost);
}

void OnInfernoSpawnPost(int entity) {

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if (isLeaker(owner)) {

		static char command[32];
		FormatEx(command, sizeof(command), "OnUser1 !self:Kill::%.2f:-1", leaker_fire);
		SetVariantString(command);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		float vPos[3];
		GetEntPropVector(owner, Prop_Send, "m_vecOrigin", vPos);

		if (leaker_stumble > 0) {

			float vTarg[3];

			for (int client = 1; client <= MaxClients; client++) {

				if (isSurvivor(client)) {

					GetClientAbsOrigin(client, vTarg);

					if( GetVectorDistance(vPos, vTarg) <= leaker_stumble ) {

						StaggerClient(GetClientUserId(client), vPos);

						if (leaker_stumble_vomit)
							L4D_CTerrorPlayer_OnVomitedUpon(client, owner);
					}
				}
			}
		}

		if (leaker_explosion) {

			int projectile = -1;

			switch (leaker_explosion) {
				case 1: projectile = L4D_PipeBombPrj(owner, vPos, NULL_VECTOR);
				case 2: projectile = L4D_MolotovPrj(owner, vPos, NULL_VECTOR);
				case 3: projectile = L4D2_GrenadeLauncherPrj(owner, vPos, NULL_VECTOR);
				case 4: projectile = L4D2_SpitterPrj(owner, vPos, NULL_VECTOR);
			}

			block_deton = true;
			if (projectile != INVALID_ENT_REFERENCE)
				L4D_DetonateProjectile(projectile);
			block_deton = false;
		}
	}
}


// (l4d2_si_stumble.sp)
// https://forums.alliedmods.net/showthread.php?t=322063
// Credit to Timocop on VScript function 
void StaggerClient(int iUserID, const float fPos[3])
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
		{
			LogError("Could not create 'logic_script");
			return;
		}

		DispatchSpawn(iScriptLogic);
	}

	static char sBuffer[96];
	Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
	AcceptEntityInput(iScriptLogic, "Kill");
}