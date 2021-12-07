#include <sourcemod> 
#include <sdkhooks> 

public Plugin:myinfo =  
{ 
    name = "Tougher Survivor Bots", 
    author = "xQd", 
    description = "Makes the survivor bots deal more damage against SIs and be more resistant to damage.", 
    version = "1.0", 
    url = "http://" 
}; 

public OnPluginStart(){ 
     
} 

public OnClientPutInServer(client){ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3]){
	if(attacker > 0 && attacker <= MAXPLAYERS && IsClientConnected(attacker) && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsFakeClient(attacker))
	{
		damage *= 1.5; 
		return Plugin_Changed; 
	}
	if (victim > 0 && victim <= MAXPLAYERS && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsFakeClient(victim))
	{
		damage *= 0.5;
		return Plugin_Changed;
	}
    return Plugin_Continue; 
}  