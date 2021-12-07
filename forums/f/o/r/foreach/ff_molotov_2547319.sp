#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_AUTHOR "f0re4ch"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Competitive Anti-FF",
	author = PLUGIN_AUTHOR,
	description = "Protects Players from Friendly-Fire but enable molotov damage",
	version = PLUGIN_VERSION,
	url = "http://kpservidores.com"
};

public OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	int attackerUserId = attacker;
	int victimUserId = victim;

	char WeaponCallBack[32];
	GetEdictClassname(inflictor, WeaponCallBack, sizeof(WeaponCallBack));

	if ((!IsValidEntity(victimUserId)) || (!IsValidEntity(attackerUserId)))
		return Plugin_Continue;

	if ((strlen(WeaponCallBack) <= 0) || (attackerUserId == victimUserId) || (GetClientTeam(victimUserId) != GetClientTeam(attackerUserId)) )
		return Plugin_Continue;

	if (StrEqual(WeaponCallBack, "inferno", false))
		return Plugin_Continue;

	return Plugin_Handled;
}