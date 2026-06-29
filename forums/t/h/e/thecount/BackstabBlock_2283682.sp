#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

public Plugin:myinfo = {
	name = "Backstab Block",
	author = "The Count",
	description = "",
	version = "",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

public OnClientPutInServer(client){
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client){
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){
	if(victim <= 0 && victim > MaxClients){ return Plugin_Continue; }
	if(attacker <= 0 || attacker > MaxClients){ return Plugin_Continue; }
	if(damage > 44.0){
		new String:wep[64];GetClientWeapon(attacker, wep, sizeof(wep));
		if(StrEqual(wep, "weapon_knife", false)){
			PrintToChat(attacker, "\x01[SM]\x04 Backstab blocked!");
			ClientCommand(attacker, "play *training/timer_bell.wav");
			damage = 0.0;
			CS_RespawnPlayer(attacker);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}