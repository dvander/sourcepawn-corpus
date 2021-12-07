#include <sourcemod>
#include <sdkhooks>
#include <tf2>

public Plugin myinfo = 
{
	name = "No Self-Damage",
	author = "MrTimcakes",
	description = "Removes Self-Damage e.g. Rocket Jumping and Sticky Jumping",
	version = "1.00",
	url = "http://ducke.uk/"
};

public OnClientPostAdminCheck(client){
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]){
	if(victim == attacker){
		TF2_AddCondition(victim, TFCond:14, 0.001);
	}
	return Plugin_Continue;
}  