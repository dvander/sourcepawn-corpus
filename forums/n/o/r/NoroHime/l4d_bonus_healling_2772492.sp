#define PLUGIN_VERSION	"1.6"
#define PLUGIN_NAME		"l4d_bonus_healing"

/**
 *	v1.0 just releases; 26-2-22
 *		im not ate anything all day long, thanks kizuna ai live gave me power for hungry coding
 *		and all my needed about health well done, i may wont write more about health
 *	v1.0.1 fix issue 'bonus twice when heal self', 'specifies actions'; 26-2-22
 *	v1.0.2 fix little binary check cause not apply to HEAL; 26-2-22
 *	v1.1 optional target 'ledge grabber or ledge helper', fix issue 'wrong cvar name cause healer reward buff cant change'; 7-March-2022
 *	v1.2 add features 
 *		new 'rescue closets healing', 
 *		new 'teammates protection healing', 
 *		new 'defibrillation healing',
 *		normalized the ConVar(s) name, clean the code name, you(who reading this text) need delete config file to regenerate; 8-March-2022
 *	v1.2.1 add support '[L4D & L4D2] Heartbeat' plugin to properly set black-white screen; 26-April-2022
 *	v1.3 add health cap option, and overflow buffer health can proportionally convert to real health; 8-October-2022
 *	v1.4 new ConVar *_rate_incapped to control rate of earn health when player gets down; 31-October-2022
 *	v1.5 fix Extra Life feature work incorrect when '[L4D & L4D2] Heartbeat' plugin installed,
 *		also trigger *_protected_* and *_protector_* when save teammate from a hunter's pounce and smoker's choke; 14-November-2022
 *	v1.6 for dev, add 'forward void OnBonusHealing(int client, float amount, int action)',
 *		add 'native void BonusHealing(int client, float amount, int action = 0)',
 *		action 0=temp hp 1=hp 2=extra life 3=adrenaline
 *		
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

native int Heartbeat_GetRevives(int client);
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true); 

GlobalForward OnBonusHealing;
native void BonusHealing(int client, float amount, int action = 0);

bool isHeartbeatExists = false;

public void OnAllPluginsLoaded() {
	if( LibraryExists("l4d_heartbeat") == true ) {
		isHeartbeatExists = true;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("Heartbeat_SetRevives");
	MarkNativeAsOptional("Heartbeat_GetRevives");
	MarkNativeAsOptional("BonusHealing");
	RegPluginLibrary("l4d_bonus_healing");
	CreateNative("BonusHealing", ExternalBonusHealing);
	return APLRes_Success; 
}

enum {
	ACTION_TEMP_HEALTH = 0,
	ACTION_HEALTH,
	ACTION_EXTRALIFE,
	ACTION_ADRENALINE
}

public int ExternalBonusHealing(Handle plugin, int numParams) {

	int client = GetNativeCell(1);
	float amount = GetNativeCell(2);
	int action = GetNativeCell(3);

	switch (action) {

		case ACTION_TEMP_HEALTH :
			AddBuff(client, amount);

		case ACTION_HEALTH :
			AddHealth(client, LuckyFloat(amount));

		case ACTION_EXTRALIFE :
			AddExtraLife(client, LuckyFloat(amount));

		case ACTION_ADRENALINE :
			AddAdrenaline(client, amount);
	}

	return 0;
}

void AddAdrenaline(int client, float add) {

	float duration = Terror_GetAdrenalineTime(client);

	if (duration > 0)
		Terror_SetAdrenalineTime(client, duration + add);
	else
		Terror_SetAdrenalineTime(client, add);

	MakeForward(client, add, ACTION_ADRENALINE);
}


public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "l4d_heartbeat") == 0 ) {
		isHeartbeatExists = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "l4d_heartbeat") == 0 ) {
		isHeartbeatExists = false;
	}
}

enum {
	HEALED =			(1 << 0),
	REVIVED =			(1 << 1),
	PILLS_USED =		(1 << 2),
	ADRENALINE_USED =	(1 << 3),
	LEDGE_GRABBER = 	(1 << 4),
	LEDGE_HELPER = 		(1 << 5),
	PROTECTION = 		(1 << 6),
	RESCUE_CLOSET =		(1 << 7),
	DEFIBRILLATION =	(1 << 8),
}

ConVar Enabled;
ConVar Allow_bonuses;		int allow_bonuses;

ConVar Revived_buff;		float revived_buff;
ConVar Revived_health;		float revived_health;
ConVar Revived_1up;			float revived_1up;

ConVar Pills_buff;			float pills_buff;
ConVar Pills_health;		float pills_health;
ConVar Pills_1up;			float pills_1up;

ConVar Adrenaline_buff;		float adrenaline_buff;
ConVar Adrenaline_health;	float adrenaline_health;
ConVar Adrenaline_1up;		float adrenaline_1up;

ConVar Healed_buff;			float healed_buff;
ConVar Healed_health;		float healed_health;

ConVar Healer_buff;			float healer_buff;
ConVar Healer_health;		float healer_health;
ConVar Healer_1up;			float healer_1up;

ConVar Reviver_buff;		float reviver_buff;
ConVar Reviver_health;		float reviver_health;
ConVar Reviver_1up;			float reviver_1up;

ConVar Protector_buff;		float protector_buff;
ConVar Protector_health;	float protector_health;
ConVar Protector_1up;		float protector_1up;

ConVar Protected_buff;		float protected_buff;
ConVar Protected_health;	float protected_health;
ConVar Protected_1up;		float protected_1up;

ConVar Rescuer_buff;		float rescuer_buff;
ConVar Rescuer_health;		float rescuer_health;
ConVar Rescuer_1up;			float rescuer_1up;

ConVar Rescued_buff;		float rescued_buff;
ConVar Rescued_health;		float rescued_health;

ConVar Defiber_buff;		float defiber_buff;
ConVar Defiber_health;		float defiber_health;
ConVar Defiber_1up;			float defiber_1up;

ConVar Defibbed_buff;		float defibbed_buff;
ConVar Defibbed_health;		float defibbed_health;

ConVar Health_max;			float health_max;
ConVar Overflow_turn;		float overflow_turn;
ConVar Rate_incapped;		float rate_incapped;
ConVar Health_max_incapped;	int health_max_incapped;

public Plugin myinfo = {
	name = "[L4D & L4D2] Bonus Healing <fork>",
	author = "NoroHime",
	description = "bonus healing and chance extra life",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar						("bonus_healing_version", PLUGIN_VERSION, "Version of 'Bonus Healing'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 				CreateConVar("bonus_healing_enabled", "1", "Enabled 'Bonus Healing'", FCVAR_NOTIFY);
	Allow_bonuses =			CreateConVar("bonus_healing_allows", "-1", "which actions allow bonus healing add numbers together you want.\n-1=All 1=healed 2=revived 4=use pills 8=use adrenaline 16=ledge grabber 32=ledge helper\n64=protection 128=rescue closet 256=defib", FCVAR_NOTIFY);

	Revived_buff =			CreateConVar("bonus_healing_revived_buff", "0", "amount of got extra buff health who be revived", FCVAR_NOTIFY);
	Revived_health =		CreateConVar("bonus_healing_revived_health", "15", "amount of got extra health who be revived", FCVAR_NOTIFY);
	Revived_1up =			CreateConVar("bonus_healing_revived_1up", "0.25", "chance to get extra life who be revived", FCVAR_NOTIFY);

	Pills_buff =			CreateConVar("bonus_healing_pills_buff", "0", "amount of got extra buff health when use pills", FCVAR_NOTIFY);
	Pills_health =			CreateConVar("bonus_healing_pills_health", "15", "amount of got extra health when use pills", FCVAR_NOTIFY);
	Pills_1up =				CreateConVar("bonus_healing_pills_1up", "0.1", "chance to get extra life when use pills", FCVAR_NOTIFY);

	Adrenaline_buff =		CreateConVar("bonus_healing_adrenaline_buff", "0", "amount of got extra buff health when use adrenaline", FCVAR_NOTIFY);
	Adrenaline_health =		CreateConVar("bonus_healing_adrenaline_health", "10", "amount of got extra health when use adrenaline", FCVAR_NOTIFY);
	Adrenaline_1up =		CreateConVar("bonus_healing_adrenaline_1up", "0.1", "chance to get extra life when use adrenaline", FCVAR_NOTIFY);

	Healed_buff =			CreateConVar("bonus_healing_healed_buff", "15", "amount of got extra buff health who be healed", FCVAR_NOTIFY);
	Healed_health =			CreateConVar("bonus_healing_healed_health", "0", "amount of got extra health who be healed", FCVAR_NOTIFY);

	Healer_buff =			CreateConVar("bonus_healing_healer_buff", "10", "reward amount of buff health who healing teammate", FCVAR_NOTIFY);
	Healer_health =			CreateConVar("bonus_healing_healer_health", "10", "reward amount of health who healing teammate", FCVAR_NOTIFY);
	Healer_1up =			CreateConVar("bonus_healing_healer_1up", "0.1", "reward chance to got extra life who healing teammate", FCVAR_NOTIFY);

	Reviver_buff =			CreateConVar("bonus_healing_reviver_buff", "10", "reward amount of buff health who revive teammate", FCVAR_NOTIFY);
	Reviver_health =		CreateConVar("bonus_healing_reviver_health", "10", "reward amount of health who revive teammate", FCVAR_NOTIFY);
	Reviver_1up =			CreateConVar("bonus_healing_reviver_1up", "0.1", "reward chance to got extra life who revive teammate", FCVAR_NOTIFY);

	Protector_buff =		CreateConVar("bonus_healing_protector_buff", "2", "reward amount of buff health who protect teammate", FCVAR_NOTIFY);
	Protector_health =		CreateConVar("bonus_healing_protector_health", "2", "reward amount of health who protect teammate", FCVAR_NOTIFY);
	Protector_1up =			CreateConVar("bonus_healing_protector_1up", "0.02", "reward chance to got extra life who protect teammate", FCVAR_NOTIFY);

	Protected_buff =		CreateConVar("bonus_healing_protected_buff", "1", "reward amount of buff health who be protected", FCVAR_NOTIFY);
	Protected_health =		CreateConVar("bonus_healing_protected_health", "1", "reward amount of health who be protected", FCVAR_NOTIFY);
	Protected_1up =			CreateConVar("bonus_healing_protected_1up", "0.01", "reward chance to got extra life who be protected", FCVAR_NOTIFY);

	Rescuer_buff =			CreateConVar("bonus_healing_rescuer_buff", "10", "reward amount of buff health who revive teammate", FCVAR_NOTIFY);
	Rescuer_health =		CreateConVar("bonus_healing_rescuer_health", "10", "reward amount of health who revive teammate", FCVAR_NOTIFY);
	Rescuer_1up =			CreateConVar("bonus_healing_rescuer_1up", "0.1", "reward chance to got extra life who revive teammate", FCVAR_NOTIFY);

	Rescued_buff =			CreateConVar("bonus_healing_rescued_buff", "10", "amount of buff health who be rescued", FCVAR_NOTIFY);
	Rescued_health =		CreateConVar("bonus_healing_rescued_health", "0", "amount of health who be rescued", FCVAR_NOTIFY);

	Defiber_buff =			CreateConVar("bonus_healing_defiber_buff", "10", "reward amount of buff health who defib teammate", FCVAR_NOTIFY);
	Defiber_health =		CreateConVar("bonus_healing_defiber_health", "0", "reward amount of health who defib teammate", FCVAR_NOTIFY);
	Defiber_1up =			CreateConVar("bonus_healing_defiber_1up", "0.1", "reward chance to got extra life who defib teammate", FCVAR_NOTIFY);

	Defibbed_buff =			CreateConVar("bonus_healing_defibbed_buff", "0", "amount of got extra buff health who be defib", FCVAR_NOTIFY);
	Defibbed_health =		CreateConVar("bonus_healing_defibbed_health", "0.1", "amount of got extra health who be defib", FCVAR_NOTIFY);
	Health_max =			CreateConVar("bonus_healing_health_max", "100", "health cap, well we dont really need player actually unlimited", FCVAR_NOTIFY, true);
	Overflow_turn =			CreateConVar("bonus_healing_overflow_turn", "0.5", "rate of turn the overflow temp health to real health when reached max, 0.5: turn as half 0: disable 1: completely turn", FCVAR_NOTIFY, true, 0.0);
	Rate_incapped =			CreateConVar("bonus_healing_rate_incapped", "3.0", "rate of earn health when player gets down", FCVAR_NOTIFY, true, 0.0);
	Health_max_incapped =	FindConVar	("survivor_incap_health");

	AutoExecConfig(true, PLUGIN_NAME);

	Enabled.AddChangeHook(OnConVarChanged);
	Allow_bonuses.AddChangeHook(OnConVarChanged);

	Revived_buff.AddChangeHook(OnConVarChanged);
	Revived_health.AddChangeHook(OnConVarChanged);
	Revived_1up.AddChangeHook(OnConVarChanged);

	Pills_buff.AddChangeHook(OnConVarChanged);
	Pills_health.AddChangeHook(OnConVarChanged);
	Pills_1up.AddChangeHook(OnConVarChanged);

	Adrenaline_buff.AddChangeHook(OnConVarChanged);
	Adrenaline_health.AddChangeHook(OnConVarChanged);
	Adrenaline_1up.AddChangeHook(OnConVarChanged);

	Healed_buff.AddChangeHook(OnConVarChanged);
	Healed_health.AddChangeHook(OnConVarChanged);

	Healer_buff.AddChangeHook(OnConVarChanged);
	Healer_health.AddChangeHook(OnConVarChanged);
	Healer_1up.AddChangeHook(OnConVarChanged);

	Reviver_buff.AddChangeHook(OnConVarChanged);
	Reviver_health.AddChangeHook(OnConVarChanged);
	Reviver_1up.AddChangeHook(OnConVarChanged);

	Protector_buff.AddChangeHook(OnConVarChanged);
	Protector_health.AddChangeHook(OnConVarChanged);
	Protector_1up.AddChangeHook(OnConVarChanged);

	Protected_buff.AddChangeHook(OnConVarChanged);
	Protected_health.AddChangeHook(OnConVarChanged);
	Protected_1up.AddChangeHook(OnConVarChanged);

	Rescuer_buff.AddChangeHook(OnConVarChanged);
	Rescuer_health.AddChangeHook(OnConVarChanged);
	Rescuer_1up.AddChangeHook(OnConVarChanged);

	Rescued_buff.AddChangeHook(OnConVarChanged);
	Rescued_health.AddChangeHook(OnConVarChanged);

	Defiber_buff.AddChangeHook(OnConVarChanged);
	Defiber_health.AddChangeHook(OnConVarChanged);
	Defiber_1up.AddChangeHook(OnConVarChanged);

	Defibbed_buff.AddChangeHook(OnConVarChanged);
	Defibbed_health.AddChangeHook(OnConVarChanged);

	Health_max.AddChangeHook(OnConVarChanged);
	Overflow_turn.AddChangeHook(OnConVarChanged);
	Rate_incapped.AddChangeHook(OnConVarChanged);
	Health_max_incapped.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	OnBonusHealing = new GlobalForward("OnBonusHealing", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		HookEvent("pills_used", OnPillsUsed);
		HookEvent("heal_success", OnHealSuccess);
		HookEvent("revive_success", OnReviveSuccess);
		HookEvent("adrenaline_used", OnArenalineUsed);
		HookEvent("award_earned", OnAwardEarned);
		HookEvent("survivor_rescued", OnSurvivorRescued);
		HookEvent("defibrillator_used", OnDefibrillatorUsed);

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("pills_used", OnPillsUsed);
		UnhookEvent("heal_success", OnHealSuccess);
		UnhookEvent("revive_success", OnReviveSuccess);
		UnhookEvent("adrenaline_used", OnArenalineUsed);
		UnhookEvent("award_earned", OnAwardEarned);
		UnhookEvent("survivor_rescued", OnSurvivorRescued);
		UnhookEvent("defibrillator_used", OnDefibrillatorUsed);

		hooked = false;
	}

	allow_bonuses = Allow_bonuses.IntValue;

	revived_buff = Revived_buff.FloatValue;
	revived_health = Revived_health.FloatValue;
	revived_1up = Revived_1up.FloatValue;

	pills_buff = Pills_buff.FloatValue;
	pills_health = Pills_health.FloatValue;
	pills_1up = Pills_1up.FloatValue;


	adrenaline_buff = Adrenaline_buff.FloatValue;
	adrenaline_health = Adrenaline_health.FloatValue;
	adrenaline_1up = Adrenaline_1up.FloatValue;

	healed_buff = Healed_buff.FloatValue;
	healed_health = Healed_health.FloatValue;

	healer_buff = Healer_buff.FloatValue;
	healer_health = Healer_health.FloatValue;
	healer_1up = Healer_1up.FloatValue;

	reviver_buff = Reviver_buff.FloatValue;
	reviver_health = Reviver_health.FloatValue;
	reviver_1up = Reviver_1up.FloatValue;

	protector_buff = Protector_buff.FloatValue;
	protector_health = Protector_health.FloatValue;
	protector_1up = Protector_1up.FloatValue;

	protected_buff = Protected_buff.FloatValue;
	protected_health = Protected_health.FloatValue;
	protected_1up = Protected_1up.FloatValue;

	rescuer_buff = Rescuer_buff.FloatValue;
	rescuer_health = Rescuer_health.FloatValue;
	rescuer_1up = Rescuer_1up.FloatValue;

	rescued_buff = Rescued_buff.FloatValue;
	rescued_health = Rescued_health.FloatValue;

	defiber_buff = Defiber_buff.FloatValue;
	defiber_health = Defiber_health.FloatValue;
	defiber_1up = Defiber_1up.FloatValue;

	defibbed_buff = Defibbed_buff.FloatValue;
	defibbed_health = Defibbed_health.FloatValue;

	health_max = Health_max.FloatValue;
	overflow_turn = Overflow_turn.FloatValue;

	rate_incapped = Rate_incapped.FloatValue;
	health_max_incapped = Health_max_incapped.IntValue;
}

void AddHealthOnIncapped(int client, int health) {

	int healthy = GetClientHealth(client);

	if (healthy + health >= health_max_incapped)
		SetEntityHealth(client, health_max_incapped);
	else
		SetEntityHealth(client, healthy + health);

	MakeForward(client, float(health), ACTION_TEMP_HEALTH);
}


void AddHealth(int client, int health) {

	int healthing = GetClientHealth(client);

	if (IsPlayerDown(client)) {
		AddHealthOnIncapped(client, LuckyFloat(health * rate_incapped));
		return;
	}

	if (healthing + health > health_max)
		SetEntityHealth(client, RoundToFloor(health_max));
	else
		SetEntityHealth(client, healthing + health);

	MakeForward(client, float(health), ACTION_HEALTH);
}

void MakeForward(int client, float amount, int action) {
	Call_StartForward(OnBonusHealing);
	Call_PushCell(client);
	Call_PushCell(amount);
	Call_PushCell(action);
	Call_Finish();
}


void AddBuff(int client, float buff) {

	if (IsPlayerDown(client)) {
		AddHealthOnIncapped(client, LuckyFloat(buff * rate_incapped));
		return;
	}

	float buffing = GetTempHealth(client);
	int health = GetClientHealth(client);

	if (health + buffing + buff > health_max) {

		if (overflow_turn > 0) {

			float overflow = FloatAbs(health_max - health - buffing - buff) * overflow_turn;

			if (health + overflow > health_max) {

				SetEntityHealth(client, RoundToFloor(health_max));
				SetTempHealth(client, 0.0);

			} else {

				SetEntityHealth(client, health + RoundToFloor(overflow));
				SetTempHealth(client, health_max - health - overflow);
			}
		} else 
			SetTempHealth(client, health_max - health);
		
	} else 
		SetTempHealth(client, buffing + buff);

	MakeForward(client, buff, ACTION_TEMP_HEALTH);

}

void AddExtraLife(int client, int life) {

	if (life > 0) {

		int revived = isHeartbeatExists ? Heartbeat_GetRevives(client) : L4D_GetPlayerReviveCount(client);

		if (revived - life < 0) {

			if (isHeartbeatExists)
				Heartbeat_SetRevives(client, 0);

			L4D_SetPlayerReviveCount(client, 0);

		} else {

			if (isHeartbeatExists)
				Heartbeat_SetRevives(client, revived - life);

			L4D_SetPlayerReviveCount(client, revived - life);
			
			MakeForward(client, float(life), ACTION_EXTRALIFE);
		}

	}
}

public void OnSurvivorRescued(Event event, const char[] name, bool dontBroadcast) {

	if (allow_bonuses & RESCUE_CLOSET) {

		int	healer = GetClientOfUserId(event.GetInt("rescuer"));
		int subject = GetClientOfUserId(event.GetInt("victim"));
		
		if (IsAliveSurvivor(healer)) {

			if (rescuer_buff)
				AddBuff(healer, rescuer_buff);

			if (rescuer_health)
				AddHealth(healer, LuckyFloat(rescuer_health));

			if (rescuer_1up)
				AddExtraLife(healer, LuckyFloat(rescuer_1up));
		}

		if (IsAliveSurvivor(subject)) {

			if (rescued_buff)
				AddBuff(subject, rescued_buff);

			if (rescued_health)
				AddHealth(subject, LuckyFloat(rescued_health));
		}
	}
}

public void OnDefibrillatorUsed(Event event, const char[] name, bool dontBroadcast) {


	if (allow_bonuses & DEFIBRILLATION) {

		int	healer = GetClientOfUserId(event.GetInt("userid"));
		int subject = GetClientOfUserId(event.GetInt("subject"));

		if (IsAliveSurvivor(healer)) {

			if (defiber_buff)
				AddBuff(healer, defiber_buff);

			if (defiber_health)
				AddHealth(healer, LuckyFloat(defiber_health));

			if (defiber_1up)
				AddExtraLife(healer, LuckyFloat(defiber_1up));
		}

		if (IsAliveSurvivor(subject)) {

			if (defibbed_buff)
				AddBuff(subject, defibbed_buff);

			if (defibbed_health)
				AddHealth(subject, LuckyFloat(defibbed_health));
		}
	}
}

public void OnAwardEarned(Event event, const char[] name, bool dontBroadcast) {

	if (allow_bonuses & PROTECTION) { 

		switch (event.GetInt("award")) {
			case 67, 76 : { //67 = protect teammate 76 = save from hunter/smoker

				int	healer = GetClientOfUserId(event.GetInt("userid"));
				int subject = event.GetInt("subjectentid");

				if (IsAliveSurvivor(healer)) {

					if (protector_buff)
						AddBuff(healer, protector_buff);

					if (protector_health)
						AddHealth(healer, LuckyFloat(protector_health));

					if (protector_1up)
						AddExtraLife(healer, LuckyFloat(protector_1up));
				}

				if (IsAliveSurvivor(subject)) {

					if (protected_buff)
						AddBuff(subject, protected_buff);

					if (protected_health)
						AddHealth(subject, LuckyFloat(protected_health));

					if (protected_1up)
						AddExtraLife(subject, LuckyFloat(protected_1up));
				}
			}
		}
	}
}

public void OnArenalineUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (allow_bonuses & ADRENALINE_USED && IsAliveSurvivor(healer)) {

		if (adrenaline_1up)
			AddExtraLife(healer, LuckyFloat(adrenaline_1up));

		if (adrenaline_buff)
			AddBuff(healer, adrenaline_buff);

		if (adrenaline_health)
			AddHealth(healer, LuckyFloat(adrenaline_health));
	}
}

public void OnPillsUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (allow_bonuses & PILLS_USED && IsAliveSurvivor(healer)) {

		if (pills_1up)
			AddExtraLife(healer, LuckyFloat(pills_1up));

		if (pills_buff)
			AddBuff(healer, pills_buff);

		if (pills_health)
			AddHealth(healer, LuckyFloat(pills_health));
	}
}

public void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid")),
		subject = GetClientOfUserId(event.GetInt("subject"));

	bool ledges = event.GetBool("ledge_hang");

	if (IsAliveSurvivor(subject)) {
		
		if ( ( !ledges && allow_bonuses & REVIVED ) || allow_bonuses & LEDGE_GRABBER ) {

			if (revived_1up)
				AddExtraLife(subject, LuckyFloat(revived_1up));

			if (revived_buff)
				AddBuff(subject, revived_buff);

			if (revived_health)
				AddHealth(subject, LuckyFloat(revived_health));
		}
	}

	if (IsAliveSurvivor(healer)) {
		
		if ( ( !ledges && allow_bonuses & REVIVED ) || allow_bonuses & LEDGE_HELPER ) {

			if (reviver_1up)
				AddExtraLife(healer, LuckyFloat(reviver_1up));

			if (reviver_buff)
				AddBuff(healer, reviver_buff);

			if (reviver_health)
				AddHealth(healer, LuckyFloat(reviver_health));
		}
	}

}

public void OnHealSuccess(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid")),
		subject = GetClientOfUserId(event.GetInt("subject"));

	if (allow_bonuses & HEALED) {

		if (IsAliveSurvivor(subject)) {
			
			if (healed_buff)
				AddBuff(subject, healed_buff);

			if (healed_health)
				AddHealth(subject, LuckyFloat(healed_health));
		}

		if (IsAliveSurvivor(healer) && healer != subject) {
			
			if (healer_1up)
				AddExtraLife(healer, LuckyFloat(healer_1up));

			if (healer_buff)
				AddBuff(healer, healer_buff);

			if (healer_health)
				AddHealth(healer, LuckyFloat(healer_health));
		}
	}
}

/* Stocks below */

stock bool IsAliveSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool IsClient(int client) {
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

int LuckyFloat(float floating) {

	int floor = RoundToFloor(floating);

	int luck = (floating - floor) > GetURandomFloat();

	return floor + luck;
}

stock bool IsPlayerDown(int client) {
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || !IsPlayerAlive(client);
}

// ====================================================================================================
//										STOCKS - HEALTH (left4dhooks.sp, left4dhooks_stocks.inc)
// ====================================================================================================
float GetTempHealth(int client)
{
	static ConVar painPillsDecayCvar;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return 0.0;
		}
	}

	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * painPillsDecayCvar.FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}


/**
 * Return player current revive count.
 *
 * @param client		Client index.
 * @return				Survivor's current revive count.
 * @error				Invalid client index.
 */
stock int L4D_GetPlayerReviveCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Set player revive count.
 *
 * @param client		Client index.
 * @param count			Revive count.
 * @noreturn
 * @error				Invalid client index.
 */
stock void L4D_SetPlayerReviveCount(int client, int count)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
}

/**
 * Sets the adrenaline effect duration of a survivor.
 *
 * @param iClient		Client index of the survivor.
 * @param flDuration		Duration of the adrenaline effect.
 *
 * @error			Invalid client index.
 **/
// L4D2 only.
stock void Terror_SetAdrenalineTime(int iClient, float flDuration)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 4 = Duration
	//timerAddress + 8 = TimeStamp
	SetEntDataFloat(iClient, timerAddress + 4, flDuration);
	SetEntDataFloat(iClient, timerAddress + 8, GetGameTime() + flDuration);
	SetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", (flDuration <= 0.0 ? 0 : 1), 1);
}

/**
 * Returns the remaining duration of a survivor's adrenaline effect.
 *
 * @param iClient		Client index of the survivor.
 *
 * @return 			Remaining duration or -1.0 if there's no effect.
 * @error			Invalid client index.
 **/
// L4D2 only.
stock float Terror_GetAdrenalineTime(int iClient)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 8 = TimeStamp
	float flGameTime = GetGameTime();
	float flTime = GetEntDataFloat(iClient, timerAddress + 8);
	if(flTime <= flGameTime)
		return -1.0;


	if (!GetEntProp(iClient, Prop_Send, "m_bAdrenalineActive"))
		return -1.0;
	
	return flTime - flGameTime;
}
