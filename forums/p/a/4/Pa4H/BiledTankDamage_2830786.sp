#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle cv_BileDamage;

public Plugin myinfo = 
{
	name = "BiledTankDamage", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	HookEvent("tank_spawn", Event_OnTankSpawned);
	
	cv_BileDamage = CreateConVar("biledTankDamage", "20.0", "Amount of damage");
}

public Action Event_OnTankSpawned(Event event, char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank && IsClientInGame(tank)) {
		SDKHook(tank, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (damagetype == 128 && IsTank(victim)) {
		switch (damage)
		{
			case 2.0: // Commons continue to hit Tank after the vomit screen
			{
				damage = GetConVarFloat(cv_BileDamage);
				return Plugin_Changed;
			}
			case 20.0: // Bilejar is active (Tank's screen is vomited)
			{
				damage = GetConVarFloat(cv_BileDamage);
				return Plugin_Changed;
			}
		}
	}
	//PrintToChatAll("%N:  %i (%f) %i", victim, victim, damage, damagetype);
	return Plugin_Continue;
}

stock bool IsTank(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && GetClientTeam(client) == 3) {
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == 8) { return true; }
	}
	return false;
} 