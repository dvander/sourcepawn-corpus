#include <sourcemod>
#include <sdkhooks>


#define PLUGIN_VERSION "1.0"

ConVar one_hitkill_enabled;
ConVar one_hitkill_weapon;
ConVar one_hitkill_damage;
public Plugin myinfo = {
	name = "Any 1 hit kill",
	author = "-GoV-TonyBaretta",
	description = "1 hit kill",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
}; 
public OnPluginStart()
{
	CreateConVar("1hk_version", PLUGIN_VERSION, "csgo 1 hit version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	one_hitkill_enabled = CreateConVar("1hitkill_enabled", "1", "1 Hit Kill enabled (def 1)");
	one_hitkill_weapon = CreateConVar("1hitkill_weapon", "knife", "1 Hit Kill weapon (def knife)");
	one_hitkill_damage = CreateConVar("1hitkill_damage", "300.0", "weapon damage (def 300.0)");
	AutoExecConfig(true, "onehitkill_cfg");
}
public OnClientPutInServer(client)
{
	if(one_hitkill_enabled.BoolValue){
		SDKHook(client, SDKHook_OnTakeDamage, OneHitDamage);
	}
}

public Action OneHitDamage(int victim,int &attacker,int &inflictor, float &damage,int &damagetype,int &weapon, float damageForce[3], float damagePosition[3]){
	if(one_hitkill_enabled.BoolValue){
		if(IsValidClient(victim)){
			char classname[128];
			char damageweapon[128];
			if(IsValidEntity(weapon))
			{
				GetEntityClassname(weapon, classname, sizeof(classname));
				GetConVarString(one_hitkill_weapon, damageweapon, sizeof(damageweapon));
				if (StrContains(classname, damageweapon))
				{
					damage = one_hitkill_damage.FloatValue;
					return Plugin_Changed;			
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}