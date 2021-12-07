#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = {
	name        = "[ANY] Damage Modifier",
	author      = "Dr. McKay",
	description = "Modifies damage dealt by weapons",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

new Handle:cvarMultiplier;

public OnPluginStart() {
	cvarMultiplier = CreateConVar("sm_damage_multiplier", "1.0", "Percentage multiplier for damage. 1.0 = 100%, 1.5 = 150%, etc");
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(attacker > MAXPLAYERS || attacker < 0) {
		return Plugin_Continue;
	}
	new Float:multiplier = GetConVarFloat(cvarMultiplier);
	if(multiplier == 1.0) {
		return Plugin_Continue;
	} else {
		damage *= multiplier;
		return Plugin_Changed;
	}
}
