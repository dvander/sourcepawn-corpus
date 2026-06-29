#include <sdkhooks>

public void OnEntityCreated(int entity, const char[] classname) {
	if(StrContains(classname, "prop_physics", false) >= 0) {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(attacker <= 0 || !IsClientInGame(attacker)) {
		return Plugin_Continue;
	}
	int attackerTeam = GetClientTeam(attacker);
	if(attackerTeam == 2 && damagetype != DMG_SLASH) {
		return Plugin_Handled;
	} else if(attackerTeam == 3) {
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
