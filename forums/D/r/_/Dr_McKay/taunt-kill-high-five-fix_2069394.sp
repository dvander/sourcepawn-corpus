#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
	name		= "[TF2] Taunt Kill High-Five Exploit Fix",
	author		= "Dr. McKay",
	description	= "Fixes an exploit that allows you to perform a taunt kill on-demand",
	version		= "1.0.1",
	url			= "http://www.doctormckay.com"
};

public OnPluginStart() {
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)) {
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) {
	if(attacker == inflictor && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetEntProp(attacker, Prop_Send, "m_bIsReadyToHighFive")) {
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}