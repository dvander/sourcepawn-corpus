#include <sourcemod>
#include <sdkhooks>

public OnClientPutInServer(client){ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]) { 
	if(GetClientTeam(victim) == GetClientTeam(attacker)) {
		BanClient(attacker, 10, BANFLAG_AUTHID, "He have attack a teammate", "you can't attack a teammate");
	}
	
	return Plugin_Changed;
}
