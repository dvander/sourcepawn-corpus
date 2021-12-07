#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin:myinfo=
{
	name="Spy no cloak/disguise",
	author="WildCard65",
	description="Prevents spies from disguising/cloaking",
	version="1.0.0",
};

public OnMapStart()
{
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//Is OnPluginStart manditory?

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (damagecustom == TF_CUSTOM_BACKSTAB)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (condition == TFCond_Disguised && TF2_GetPlayerClass(client) == TFClass_Spy)
		TF2_RemovePlayerDisguise(client);
	if (condition == TFCond_Cloaked && TF2_GetPlayerClass(client) == TFClass_Spy)
		TF2_RemoveCondition(client, TFCond_Cloaked);
	if (condition == TFCond_DeadRingered && TF2_GetPlayerClass(client) == TFClass_Spy)
		TF2_RemoveCondition(client, TFCond_DeadRingered);
}