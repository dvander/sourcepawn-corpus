#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
ConVar boost_damage;
ConVar no_damage;
public Plugin myinfo = 
{
	name = "Pyro Jump",
	author = "TonyBaretta",
	description = "Pyro jump with Scorch Shot ",
	version = "1.1",
	url = "http://www.wantedgov.it"
};

public void OnClientPostAdminCheck(int client){
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public void OnPluginStart()
{
	boost_damage = CreateConVar("boost_damage", "3.6", "multiplication of damage default 3.6");
	no_damage = CreateConVar("no_damage", "0", "Enables/Disables damage(like sticky/rocket jumper) .", FCVAR_PLUGIN);
	CreateConVar("flarejump_version", PLUGIN_VERSION, "Current Flare Jump  version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	
	char classname[64];
	GetEntityClassname(inflictor, classname, sizeof(classname));
	if (victim == attacker)
	{
		if(StrEqual(classname, "tf_projectile_flare")) {
			int wIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(wIndex == 740){
				Boost(victim);
			}
			if(GetConVarBool(no_damage)){
				TF2_AddCondition(victim, view_as<TFCond>(14), 0.001);
			}
		}
	} 
	return Plugin_Continue;
} 
public int Boost(int client)
{
	float vecClient[3];
	float vecBoost[3];

	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecClient);

	vecBoost[0] = vecClient[0] * 1.0;
	vecBoost[1] = vecClient[1] * 1.0;
	if(vecClient[2] > 0)
	{
		vecBoost[2] = vecClient[2] * boost_damage.FloatValue;
	} else {
		vecBoost[2] = vecClient[2];
	}
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecBoost);
}
public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}