#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

ConVar z_pounce_damage_range_min;
ConVar z_pounce_damage_range_max;
ConVar z_hunter_max_pounce_bonus_damage;

public Plugin myinfo = 
{
	name = "[L4D2] Hunter Versus Pouncing", 
	author = "Drixevel", 
	description = "Calculates extra damage per pounce similar to Versus mode.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	z_pounce_damage_range_min = CreateConVar("z_pounce_damage_range_min", "0");
	z_pounce_damage_range_max = CreateConVar("z_pounce_damage_range_max", "1000");
	z_hunter_max_pounce_bonus_damage = CreateConVar("z_hunter_max_pounce_bonus_damage", "25");
	AutoExecConfig();

	HookEvent("lunge_pounce", Event_OnPounce);
}

public void Event_OnPounce(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	float distance = event.GetFloat("distance");

	float damage = CalculatePounceDamage(distance);
	//PrintToChatAll("damage: %.2f", damage);

	SDKHooks_TakeDamage(victim, attacker, attacker, damage);
}

float CalculatePounceDamage(float pounce_distance)
{
    float min_dist = z_pounce_damage_range_min.FloatValue;
    float max_dist = z_pounce_damage_range_max.FloatValue;
    float max_damage = z_hunter_max_pounce_bonus_damage.FloatValue;

    if (pounce_distance <= min_dist)
		return 1.0;

    if (pounce_distance >= max_dist)
		return 1.0 + max_damage;

    return 1.0 + (max_damage * (pounce_distance - min_dist) / (max_dist - min_dist));
} 