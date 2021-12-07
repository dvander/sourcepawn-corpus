#include <sdkhooks>

public void OnEntityCreated(int entity, const char[] classname) {
	if(StrContains(classname, "prop_physics", false) >= 0) {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if (damagetype == DMG_SLASH)
		return Plugin_Continue;
	return Plugin_Handled;
}
