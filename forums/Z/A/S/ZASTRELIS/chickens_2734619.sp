#pragma semicolon 1

#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "1.1.10"

Handle hEnabledPlugin, hMaxPlayerHP, hHealthAmount, hHealthAmountWhenKilling, hHealTimerRate, hHealDistance, hHealAtKillDistance;
int iEnabledPlugin, iMaxPlayerHP, iHealthAmount, iHealthAmountWhenKilling; 
float fhealTimerRate, fHealDistance, fHealAtKillDistance;

stock bool ClientValidator(int client, bool isBots = false) {
	if(!client || client >= MAXPLAYERS) {
		return false;
	}
	if(IsClientConnected(client)) {
		if(IsClientInGame(client)) {
			return !isBots ? !IsFakeClient(client) : IsFakeClient(client);
		}
	}
	return false;
}

public Plugin myinfo = {
	name = "Chicken buff",
	author = "Alex Deroza (KGB1st)",
	description = "emergency from chickens: this plugins adds hp per seconds for nearbies players",
	version = PLUGIN_VERSION,
	url = "https://ranks.moonsiber.org/"
};

public void OnPluginStart() {
	
	hEnabledPlugin = CreateConVar("sm_chickens_enable", "1", "enables chicken health events", FCVAR_PROTECTED, true, 0.0, true, 1.0);
	hMaxPlayerHP = CreateConVar("sm_chickens_max_players_hp", "100", "players' health limit", FCVAR_PROTECTED, true, 100.0, true, 200.0);
	hHealthAmount = CreateConVar("sm_chickens_heal_amount", "1", "how much health points will be given to each player", FCVAR_PROTECTED, true, 1.0, true, 100.0);
	hHealthAmountWhenKilling = CreateConVar("sm_chickens_heal_amount_at_killing", "10", "how much health points will be given at chicken killing", FCVAR_PROTECTED, true, 1.0, true, 100.0);
	hHealTimerRate = CreateConVar("sm_chickens_heal_timer_rate", "0.5", "the time rate of heal timer", FCVAR_PROTECTED, true, 0.1, true, 5.0);
	hHealDistance = CreateConVar("sm_chickens_heal_distance", "100", "the max disatance for allowing the heal event", FCVAR_PROTECTED, true, 100.0, true, 500.0);
	hHealAtKillDistance = CreateConVar("sm_chickens_heal_distance_at_killing", "300", "the max disatance for allowing the heal at chicken killing", FCVAR_PROTECTED, true, 100.0, true, 500.0);
	
	// how much can obtains each players from chickens health
	
	iEnabledPlugin = GetConVarInt(hEnabledPlugin);
	iMaxPlayerHP = GetConVarInt(hMaxPlayerHP);
	iHealthAmount = GetConVarInt(hHealthAmount);
	iHealthAmountWhenKilling = GetConVarInt(hHealthAmountWhenKilling);
	fhealTimerRate = GetConVarFloat(hHealTimerRate);
	fHealDistance = GetConVarFloat(hHealDistance);
	fHealAtKillDistance = GetConVarFloat(hHealAtKillDistance);
	
	HookConVarChange(hEnabledPlugin, ConvarChange_EnableedPlugin);
	HookConVarChange(hMaxPlayerHP, ConvarChange_MaxPlayerHP);
	HookConVarChange(hHealthAmount, ConvarChange_HealthAmount);
	HookConVarChange(hHealthAmountWhenKilling, ConvarChange_HealthAmountWhenKilling);
	HookConVarChange(hHealTimerRate, ConvarChange_HealTimerRate);
	HookConVarChange(hHealDistance, ConvarChange_HealDistance);
	HookConVarChange(hHealAtKillDistance, ConvarChange_HealAtKillDistance);
}


public void ConvarChange_EnableedPlugin(Handle cvar, const char[] oldVal, const char[] newVal) {
	iEnabledPlugin = GetConVarInt(hEnabledPlugin);
}

public void ConvarChange_MaxPlayerHP(Handle cvar, const char[] oldVal, const char[] newVal) {
	iMaxPlayerHP = GetConVarInt(hEnabledPlugin);
}

public void ConvarChange_HealthAmount(Handle cvar, const char[] oldVal, const char[] newVal) {
	iHealthAmount = GetConVarInt(hHealthAmount);
}

public void ConvarChange_HealthAmountWhenKilling(Handle cvar, const char[] oldVal, const char[] newVal) {
	iHealthAmountWhenKilling = GetConVarInt(hHealthAmountWhenKilling);
}

public void ConvarChange_HealTimerRate(Handle cvar, const char[] oldVal, const char[] newVal) {
	fhealTimerRate = GetConVarFloat(hEnabledPlugin);
}

public void ConvarChange_HealDistance(Handle cvar, const char[] oldVal, const char[] newVal) {
	fHealDistance = GetConVarFloat(hHealDistance);
}

public void ConvarChange_HealAtKillDistance(Handle cvar, const char[] oldVal, const char[] newVal) {
	fHealAtKillDistance = GetConVarFloat(hHealAtKillDistance);
}


public void OnEntityCreated(int entity, const char[] classname) {
	if(!iEnabledPlugin || !StrEqual(classname, "chicken", false)) return;
	SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnEntitySpawned(int entity) {
	DataPack pack;
	CreateDataTimer(fhealTimerRate, Timer_HealEvent, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(entity);
} 

public Action Timer_HealEvent(Handle timer, DataPack pack) {
	pack.Reset();
	int entity = pack.ReadCell();
	if(!IsValidEntity(entity) || !iEnabledPlugin) return Plugin_Stop;
	float entityloc[3]; GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityloc);
	for(int i = 1; i < MAXPLAYERS; ++i) {
		if(ClientValidator(i)) {
			if(IsPlayerAlive(i)) {
				float characterloc[3]; GetEntPropVector(i, Prop_Data, "m_vecOrigin", characterloc);
				if(GetVectorDistance(characterloc, entityloc) <= fHealDistance) {
					int health = GetClientHealth(i); if((health += iHealthAmount) <= iMaxPlayerHP) {
						SetEntityHealth(i, health);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if(!IsValidEntity(victim) || !(damagetype & DMG_BULLET) || !iEnabledPlugin) return;
	float entityloc[3]; GetEntPropVector(victim, Prop_Data, "m_vecOrigin", entityloc);
	if(ClientValidator(attacker)) {
		if(IsPlayerAlive(attacker)) {
			float characterloc[3]; GetEntPropVector(attacker, Prop_Data, "m_vecOrigin", characterloc);
			if(GetVectorDistance(characterloc, entityloc) <= fHealAtKillDistance) {
				int health = GetClientHealth(attacker); if((health += iHealthAmountWhenKilling) <= iMaxPlayerHP) {
					SetEntityHealth(attacker, health);
				}
			}
		}
	}
}
