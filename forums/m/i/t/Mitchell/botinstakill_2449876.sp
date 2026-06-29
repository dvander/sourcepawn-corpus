#include <sourcemod>
#include <sdkhooks>

public OnPluginStart(){
	for(int i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client){
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(!IsClientInGame(victim) || attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || !IsFakeClient(attacker)) {
		return Plugin_Continue;
	}
	damagetype = damagetype & (1 << 30);
	SetEntProp(victim, Prop_Send, "m_iArmor", 0);
	damage = float(GetClientHealth(victim));
	return Plugin_Changed;
}